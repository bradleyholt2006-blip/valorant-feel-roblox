--!strict
-- Hit Reg Lab (F2, third page): lag compensation and hit registration,
-- measured live next to the reference's published numbers.
--
--   * the rewind cap the server is using, next to the reference's (140 ms
--     since Patch 6.02, 200 ms before)
--   * network: the round trip from each input to its ack, which like Riot's
--     "Network RTT + Processing Delays" graph includes the server's frame,
--     and the latency, jitter and loss this client is simulating (NetSim)
--   * snapshots: how many arrive per second, how many were lost or late, the
--     render clock's delay, how often a frame had to hold a pose, and the
--     Network Buffering setting next to the reference's
--   * motion: how evenly the player or dummy nearest your crosshair moves on
--     screen over the last second (MotionMeter): its speed, slowest and
--     fastest, and the biggest jump any frame made off the frames either side
--   * rewind: how far back the server went for your shots, how many hit the
--     cap, and the round trip at which shots start to hit it
--   * agreement between the client's guess and the server's verdict, on all
--     shots and on moving targets, and why they differed when they did
--   * time from a shot to its server hit confirm, which should be about one
--     round trip ("The State of Hit Registration")
--   * the knife: swings, the server's verdicts and how many agreed with the
--     client's guess, hits and how many came from behind, and the last
--     swing: what it caught, how far off the aim and out, how many the
--     level hid, and how far back the server went
--   * peeker's advantage by Riot's formula, from this client's own numbers
--
-- Keys while the page is open: [ and ] latency -/+10 ms each way, J jitter,
-- L packet loss, U Network Buffering, K rewind cap (140 ms, 200 ms, 0: no lag
-- compensation).
-- Backspace clears the counters and the shot log.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetConfig = require(Shared.Net.NetConfig)
local InterpClock = require(Shared.Net.InterpClock)
local MotionMeter = require(Shared.Net.MotionMeter)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Units = require(Shared.Units)

local Ui = require(script.Parent.Ui)
local NetSim = require(script.Parent.Parent.NetSim)
local RemoteEntities = require(script.Parent.Parent.RemoteEntities)
local ClientShots = require(script.Parent.Parent.Combat.ClientShots)
local ClientMelee = require(script.Parent.Parent.Combat.ClientMelee)

local LATENCY_STEP_MS = 10
local MAX_LATENCY_MS = 150
local JITTERS = { 0, 0.005, 0.015 }
local LOSSES = { 0, 0.02, 0.05 }
local CAPS = { NetConfig.maxRewind.value, NetConfig.Reference.maxRewindAtLaunch.value, 0 }
local RATE_WINDOW = 2 -- seconds the snapshot rate is measured over
local REFERENCE_SNAPSHOT_RATE = 128 -- the reference sends every server frame
local CAUSES = { "capped", "shooter", "gone", "snapshot", "world", "pose", "edge" }
local MOTION_CONE = 10 -- degrees from the crosshair the motion line looks for an entity in

local HitRegLab = {}

local panelFrame: Frame? = nil

function HitRegLab.setVisible(visible: boolean)
	local p = panelFrame
	if p then
		p.Visible = visible
	end
end

local function dim(text: string): string
	return string.format('<font color="#%s">%s</font>', Ui.hex(Ui.DIM), text)
end

local function colored(color: Color3, text: string): string
	return string.format('<font color="#%s">%s</font>', Ui.hex(color), text)
end

local function ms(seconds: number): string
	return string.format("%.0f ms", seconds * 1000)
end

local function ms1(seconds: number): string
	return string.format("%.1f ms", seconds * 1000)
end

local function percent(n: number, of: number): string
	return if of > 0 then string.format("%.1f%%", n / of * 100) else "--"
end

-- The entity drawn nearest the crosshair, by the angle to its body box,
-- within MOTION_CONE.
local function aimedAt(): number?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local eye = Units.toMetres(camera.CFrame.Position)
	local look = Units.asVector(camera.CFrame.LookVector)
	local best, bestAngle = nil, math.rad(MOTION_CONE)
	for _, entry in RemoteEntities.lookups(RemoteEntities.renderTime()) do
		local pose = entry.lookup.pose
		local box = Hitboxes.region({ position = pose.position, yaw = pose.yaw, crouchAlpha = pose.crouchAlpha }, "body")
		local to = if box then box.center - eye else nil
		if to and vector.magnitude(to) > 0 then
			local angle = math.acos(math.clamp(vector.dot(vector.normalize(to), look), -1, 1))
			if angle < bestAngle then
				best, bestAngle = entry.id, angle
			end
		end
	end
	return best
end

-- The last knife swing: what it was, what the server says it caught, and
-- whether the client guessed the same.
local function swingText(r: ClientMelee.Record): string
	local swing = r.swing
	local what = if swing.kind == "stab" then "stab" else string.format("slash %d", swing.combo)
	local v = r.verdict
	if not v then
		return what .. dim("   waiting for the server")
	end
	local caught
	local target = v.targetId
	if target then
		caught = string.format(
			"%s %s%s, %.0f   %.2f m off the aim, %.2f m out",
			RemoteEntities.nameOf(target),
			v.region or "?",
			if v.back then " from behind" else "",
			v.damage,
			v.offset or 0,
			v.distance or 0
		)
	else
		caught = if v.wall then "struck the level" else "caught no one"
	end
	local hidden = if #v.hidden > 0 then string.format("   %d hidden by the level", #v.hidden) else ""
	local guess = r.predicted.hit
	local agreement = if r.agree
		then colored(Ui.GOOD, "client agrees")
		else colored(Ui.BAD, "client: " .. (if guess then RemoteEntities.nameOf(guess.targetId) .. " " .. guess.region else "none"))
	return string.format("%s -> %s%s   rewind %s   %s", what, caught, hidden, ms(v.rewind), agreement)
end

-- The value after `current` in a list, going round (the first if it isn't there).
local function nextIn(list: { number }, current: number): number
	for i, v in list do
		if math.abs(v - current) < 1e-9 then
			return list[i % #list + 1]
		end
	end
	return list[1]
end

function HitRegLab.start(controller: any)
	local gui = Ui.screen("VFHitRegLab", 22)
	local panel = Ui.frame(gui, {
		Size = UDim2.fromOffset(660, 730),
		Position = UDim2.new(1, -672, 0, 120),
		Visible = false,
	})
	panelFrame = panel
	local body = Ui.label(panel, {
		Size = UDim2.new(1, -16, 1, -12),
		Position = UDim2.fromOffset(8, 6),
		TextSize = 13,
	})

	local fps = 60
	RunService.RenderStepped:Connect(function(dt)
		fps += (1 / math.max(dt, 1e-4) - fps) * 0.05
	end)

	-- Snapshot counts over the last couple of seconds, for the rate.
	local samples: { { at: number, count: number } } = {}

	-- How much longer a rewind is than the round trip (mostly the render
	-- delay), smoothed over recent shots that weren't capped.
	local overhead: number? = nil
	table.insert(ClientShots.verdictListeners, function(record: ClientShots.Record)
		local v = record.verdict
		local rtt = controller.stats.rttSmooth
		if v and not v.clamped and rtt > 0 then
			local o = overhead
			overhead = if o then o + (v.rewind - rtt - o) * 0.2 else v.rewind - rtt
		end
	end)

	local function cap(): number
		return controller.overrides.maxRewind or NetConfig.maxRewind.value
	end

	local function render()
		local now = os.clock()
		local snap = RemoteEntities.stats
		table.insert(samples, { at = now, count = snap.snapshots })
		while #samples > 1 and samples[1].at < now - RATE_WINDOW do
			table.remove(samples, 1)
		end
		local first = samples[1]
		local rate = if now > first.at then (snap.snapshots - first.count) / (now - first.at) else 0

		local net = controller.stats
		local rtt: number = net.rttSmooth
		local clock = RemoteEntities.clock
		local shots = ClientShots.stats
		local sim = NetSim.settings
		local ref = NetConfig.Reference
		local maxRewind = cap()
		local lines = {}

		-- Cap ------------------------------------------------------------------
		table.insert(lines, string.format(
			"<b>Hit Reg Lab</b>  rewind cap %s   reference %s (Patch 6.02), %s at launch",
			if maxRewind > 0 then ms(maxRewind) else colored(Ui.BAD, "0 ms (no lag compensation)"),
			ms(NetConfig.maxRewind.value),
			ms(ref.maxRewindAtLaunch.value)
		))
		table.insert(lines, dim("the server rewinds targets to what your screen showed when you fired, up to the cap"))
		table.insert(lines, "")

		-- Network ----------------------------------------------------------------
		table.insert(lines, "<b>network</b>")
		table.insert(lines, string.format(
			"  round trip   %s (last %s)   input to ack, the server's frame included",
			if rtt > 0 then ms(rtt) else "--",
			if net.rtt > 0 then ms(net.rtt) else "--"
		))
		table.insert(lines, dim('  reference    "Network RTT + Processing Delays" runs 20-30 ms over network RTT'))
		if NetSim.active() then
			table.insert(lines, string.format(
				"  simulated    %s, jitter 0-%s, loss %.0f%%   (%d delayed, %d lost)",
				colored(Ui.BAD, "+" .. ms(sim.latency) .. " each way"),
				ms(sim.jitter),
				sim.loss * 100,
				NetSim.stats.delayed,
				NetSim.stats.dropped
			))
		else
			table.insert(lines, "  simulated    off (ping in Studio is close to zero: press ] to add latency)")
		end
		table.insert(lines, "")

		-- Snapshots ----------------------------------------------------------------
		local buffering = NetConfig.Buffering[RemoteEntities.buffering]
		local references = {}
		for _, b in NetConfig.Buffering do
			table.insert(references, string.format("%.1f", b.reference * 1000))
		end
		table.insert(lines, string.format(
			"<b>snapshots</b>  %.1f/s   the server sends %d/s, the reference %d/s",
			rate,
			NetConfig.SNAPSHOT_RATE,
			REFERENCE_SNAPSHOT_RATE
		))
		table.insert(lines, string.format(
			"  received %d   lost %d (%s)   late %d",
			snap.snapshots,
			snap.lost,
			percent(snap.lost, snap.snapshots + snap.lost),
			snap.late
		))
		table.insert(lines, string.format(
			"  render delay %s   buffered %s   held a pose on %s of frames",
			ms1(clock.delay),
			ms1(InterpClock.buffer(clock)),
			percent(clock.starved, clock.frames)
		))
		table.insert(lines, dim(string.format(
			"  reference    %s at Minimum (one 128 Hz frame); ours covers 60 Hz plus jitter",
			ms1(ref.interpDelay.value)
		)))
		table.insert(lines, string.format(
			"  buffering    %s +%s   %s",
			buffering.name,
			ms1(buffering.extra),
			dim("reference " .. table.concat(references, " / ") .. " ms (Min / Mod / Max)")
		))
		table.insert(lines, "")

		-- Motion -----------------------------------------------------------------------
		local aimed = aimedAt()
		local motion = if aimed then RemoteEntities.motion(aimed) else nil
		if aimed and motion then
			table.insert(lines, string.format("<b>motion</b>  %s, nearest your crosshair", RemoteEntities.nameOf(aimed)))
			table.insert(lines, string.format(
				"  speed %.2f m/s   last second %.2f-%.2f   biggest jump %s",
				motion.speed,
				motion.low,
				motion.high,
				colored(if motion.jump < MotionMeter.SMOOTH then Ui.GOOD else Ui.BAD, string.format("%.2f m/s", motion.jump))
			))
		else
			table.insert(lines, string.format("<b>motion</b>  aim within %d degrees of a player or dummy to measure it", MOTION_CONE))
			table.insert(lines, "  speed --")
		end
		table.insert(lines, dim(string.format("  jump: a frame moving more or less than the ones beside it; smooth is under %.1f", MotionMeter.SMOOTH)))
		table.insert(lines, dim('  reference    "The other nine players continue to see smooth movement" (Riot)'))
		table.insert(lines, "")

		-- Rewind ---------------------------------------------------------------------
		table.insert(lines, string.format(
			"<b>rewind</b>  last %s   mean %s   max %s   capped %d of %d (%s)",
			ms(shots.rewindLast),
			if shots.verdicts > 0 then ms(shots.rewindSum / shots.verdicts) else "--",
			ms(shots.rewindMax),
			shots.clamped,
			shots.verdicts,
			percent(shots.clamped, shots.verdicts)
		))
		if maxRewind > 0 then
			local extra = overhead or clock.delay
			table.insert(lines, string.format(
				"  shots reach the cap at a round trip of about %s%s",
				ms(math.max(maxRewind - extra, 0)),
				if overhead then "" else dim(" (estimate until you fire)")
			))
			table.insert(lines, dim(string.format(
				"  reference    about %s of ping (estimate: cap - interp delay - server frame)",
				ms(maxRewind - ref.interpDelay.value - ref.serverFrame.value)
			)))
		else
			table.insert(lines, colored(Ui.BAD, "  cap 0: no lag compensation, the server tests targets where they are now,"))
			table.insert(lines, colored(Ui.BAD, "  so every shot counts as capped"))
		end
		table.insert(lines, "")

		-- Agreement ----------------------------------------------------------------------
		local causes = {}
		for _, cause in CAUSES do
			local n = shots.causes[cause]
			if n then
				table.insert(causes, string.format("%s %d", cause, n))
			end
		end
		local agreeColor = if shots.agreed == shots.verdicts then Ui.GOOD else Ui.BAD
		table.insert(lines, "<b>agreement</b>  the client's guess vs the server's verdict (same target and region)")
		table.insert(lines, string.format(
			"  all shots      %d / %d   %s",
			shots.agreed,
			shots.verdicts,
			colored(agreeColor, percent(shots.agreed, shots.verdicts))
		))
		table.insert(lines, string.format(
			"  moving target  %d / %d   %s",
			shots.movingAgreed,
			shots.moving,
			percent(shots.movingAgreed, shots.moving)
		))
		table.insert(lines, string.format(
			"  differences    %s   %s",
			if #causes > 0 then colored(Ui.BAD, table.concat(causes, "  ")) else "none",
			dim(string.format("server-only %d", shots.unmatchedVerdicts))
		))
		table.insert(lines, "")

		-- Hit confirm --------------------------------------------------------------------
		table.insert(lines, string.format(
			"<b>hit confirm</b>  shot to server confirm: mean %s   last %s   n=%d",
			if shots.confirms > 0 then ms(shots.confirmSum / shots.confirms) else "--",
			if shots.confirms > 0 then ms(shots.confirmLast) else "--",
			shots.confirms
		))
		table.insert(lines, dim('  reference    a round trip plus processing ("The State of Hit Registration")'))
		table.insert(lines, "")

		-- Knife ----------------------------------------------------------------------------
		local knife = ClientMelee.stats
		local last = ClientMelee.records[#ClientMelee.records]
		table.insert(lines, string.format(
			"<b>knife</b>  swings %d   verdicts %d   agree %d (%s)   hits %d, %d from behind   %s",
			knife.swings,
			knife.verdicts,
			knife.agreed,
			percent(knife.agreed, knife.verdicts),
			knife.hits,
			knife.backs,
			dim(string.format("server-only %d", knife.unmatchedVerdicts))
		))
		table.insert(lines, "  last  " .. (if last then swingText(last) else dim("-- (3 draws the knife: left click slashes, right click stabs)")))
		table.insert(lines, "")

		-- Peeker's advantage ------------------------------------------------------------
		local frame = 1 / math.max(fps, 1)
		local low, high = ref.peekersAdvantageLow.value, ref.peekersAdvantageHigh.value
		table.insert(lines, string.format(
			"<b>peeker's advantage</b>  about %s   %s",
			ms(frame + rtt + clock.delay),
			dim(string.format("reference average %.0f-%.0f ms", low * 1000, high * 1000))
		))
		table.insert(lines, string.format(
			"  Riot's formula: frame %s + round trip %s + render delay %s",
			ms(frame),
			ms(rtt),
			ms(clock.delay)
		))
		table.insert(lines, dim("  the round trip stands in for both one-way lags and the server frame"))
		table.insert(lines, "")
		table.insert(lines, dim("[ ] latency -/+10 ms each way   J jitter   L loss   U buffering"))
		table.insert(lines, dim("K rewind cap 140 / 200 / 0 ms   Backspace clear   F2 next page"))
		body.Text = table.concat(lines, "\n")
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not panel.Visible then
			return
		end
		local key = input.KeyCode
		local s = NetSim.settings
		local latencyMs = math.round(s.latency * 1000)
		if key == Enum.KeyCode.LeftBracket then
			s.latency = math.max(latencyMs - LATENCY_STEP_MS, 0) / 1000
		elseif key == Enum.KeyCode.RightBracket then
			s.latency = math.min(latencyMs + LATENCY_STEP_MS, MAX_LATENCY_MS) / 1000
		elseif key == Enum.KeyCode.J then
			s.jitter = nextIn(JITTERS, s.jitter)
		elseif key == Enum.KeyCode.L then
			s.loss = nextIn(LOSSES, s.loss)
		elseif key == Enum.KeyCode.U then
			RemoteEntities.setBuffering(RemoteEntities.buffering % #NetConfig.Buffering + 1)
		elseif key == Enum.KeyCode.K then
			controller.requestTuning("maxRewind", nextIn(CAPS, cap()))
		elseif key == Enum.KeyCode.Backspace then
			RemoteEntities.resetStats()
			NetSim.stats.delayed, NetSim.stats.dropped = 0, 0
			table.clear(samples)
			overhead = nil
		end
	end)

	task.spawn(function()
		while true do
			if panel.Visible then
				render()
			end
			task.wait(0.1)
		end
	end)
end

return HitRegLab
