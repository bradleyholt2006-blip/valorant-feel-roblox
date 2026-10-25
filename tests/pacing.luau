--!strict
-- Pacing (system 4): how evenly other players and practice dummies move on
-- screen. First MovePacer's and MotionMeter's own rules, then a simulated
-- network: a player runs back and forth through the real server path (their
-- client's frames, the input queue, the simulation), a dummy ticks on the
-- server's clock, and another client draws both with the render clock. Each
-- goes into the snapshots two ways, as the newest pose every frame (what the
-- server used to send) and paced, and how each is drawn is compared frame to
-- frame.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local PoseHistory = require("../src/shared/Net/PoseHistory")
local InterpClock = require("../src/shared/Net/InterpClock")
local InputQueue = require("../src/shared/Net/InputQueue")
local MovePacer = require("../src/shared/Net/MovePacer")
local MotionMeter = require("../src/shared/Net/MotionMeter")
local NetConfig = require("../src/shared/Net/NetConfig")
local LagCompensation = require("../src/shared/Combat/LagCompensation")
local ShotResolver = require("../src/shared/Combat/ShotResolver")
local Hitboxes = require("../src/shared/Combat/Hitboxes")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check = H.check

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local MARGIN = NetConfig.Pacing.margin.value
local SMOOTH_JUMP = MotionMeter.SMOOTH -- m/s: the Hit Reg Lab's line between smooth and not

-- Deterministic random numbers in [0, 1) (xorshift32), so every run repeats.
local function rng(seed: number): () -> number
	local x = bit32.band(seed, 0xFFFFFFFF)
	if x == 0 then
		x = 0x9E3779B9
	end
	return function(): number
		x = bit32.bxor(x, bit32.lshift(x, 13))
		x = bit32.bxor(x, bit32.rshift(x, 17))
		x = bit32.bxor(x, bit32.lshift(x, 5))
		return x / 4294967296
	end
end

local function pct(n: number, d: number): string
	return if d > 0 then string.format("%.1f%%", n / d * 100) else "--"
end

H.section("Pacing tests")

-- MovePacer ---------------------------------------------------------------------

-- An entity moving at 5.4 m/s along x: its pose at a time on its timeline.
local function poseAt(time: number): PlayerCodec.Pose
	return {
		id = 9,
		position = vector.create(time * 5.4, 0, -10),
		yaw = 0,
		pitch = 0,
		crouchAlpha = 0,
		grounded = true,
		alive = true,
		quiet = false,
		reloading = false,
		weapon = 0,
		channel = 0,
	}
end

type Frame = { now: number, shown: number, newest: number, x: number }

-- Runs a pacer through 60 Hz server frames for `seconds`. Tick k (time k/128
-- on the entity's timeline) has run by server time `ready(k)`.
local function feed(p: MovePacer.Pacer, seconds: number, ready: (number) -> number): { Frame }
	local out: { Frame } = {}
	local k = 0
	local f = 0
	while (f + 1) / 60 <= seconds do
		f += 1
		local now = f / 60
		while ready(k + 1) <= now do
			k += 1
			MovePacer.push(p, k * DT, poseAt(k * DT))
		end
		local pose = MovePacer.advance(p, now)
		if pose then
			local newest = PoseHistory.newest(p.history) :: PoseHistory.Sample
			table.insert(out, { now = now, shown = p.time :: number, newest = newest.time, x = pose.position.x })
		end
	end
	return out
end

-- The largest gap between a frame's step in shown time and one 60 Hz frame,
-- from `from` seconds on.
local function unevenness(frames: { Frame }, from: number): number
	local worst = 0
	for i = 2, #frames do
		if frames[i].now >= from then
			worst = math.max(worst, math.abs(frames[i].shown - frames[i - 1].shown - 1 / 60))
		end
	end
	return worst
end

local function neverPastNewest(frames: { Frame }): boolean
	for _, f in frames do
		if f.shown > f.newest then
			return false
		end
	end
	return true
end

local function neverBack(frames: { Frame }): boolean
	for i = 2, #frames do
		if frames[i].shown < frames[i - 1].shown then
			return false
		end
	end
	return true
end

do
	-- A dummy: each tick runs on the server's clock at its own time, two or
	-- three in each 60 Hz frame.
	local p = MovePacer.new()
	local frames = feed(p, 5, function(k)
		return k * DT
	end)
	check("a dummy's ticks, two or three a frame, are shown at an even pace", unevenness(frames, 2.5) < 1e-9, string.format("%.4f ms off", unevenness(frames, 2.5) * 1000))
	local behind = 0
	for _, f in frames do
		if f.now >= 2.5 then
			behind = math.max(behind, f.now - f.shown)
		end
	end
	check(
		string.format("a dummy is shown at most a tick and %.0f ms behind its simulation", MARGIN * 1000),
		behind <= DT + MARGIN + 1e-9,
		string.format("%.2f ms", behind * 1000)
	)

	-- A player at 60 fps: their moves come two or three to a packet, and the
	-- server runs each packet on the frame after it arrives.
	local client = MovePacer.new()
	local bunched = feed(client, 5, function(k)
		local generated = 0.0031 + math.ceil((k * DT - 0.0031) * 60) / 60
		return generated + 0.002
	end)
	check("a player's moves, two or three a packet, are shown at an even pace", unevenness(bunched, 2.5) < 1e-9, string.format("%.4f ms off", unevenness(bunched, 2.5) * 1000))
	check("and never ahead of the newest move run", neverPastNewest(bunched))

	-- Moves arriving 0 to 12 ms late at random: every frame shows a move that
	-- has run, and the shown time only goes forward.
	local r = rng(31)
	local lateness = {}
	local jittery = MovePacer.new()
	local frames2 = feed(jittery, 20, function(k)
		local late = lateness[k]
		if not late then
			late = r() * 0.012
			lateness[k] = late
		end
		return k * DT + late
	end)
	check("late moves: never shows a move that hasn't run", neverPastNewest(frames2))
	check("late moves: the shown time never goes back", neverBack(frames2))
	check(
		"late moves: held on the newest move on under 2% of frames",
		jittery.stats.held / jittery.stats.frames < 0.02,
		pct(jittery.stats.held, jittery.stats.frames)
	)

	-- A client that freezes for 0.3 s: its move numbers carry on afterwards,
	-- 0.3 s later than before.
	local frozen = MovePacer.new()
	local frames3 = feed(frozen, 6, function(k)
		return k * DT + (if k * DT >= 2 then 0.3 else 0) + 0.002
	end)
	check("a frozen client: its last move is held, never passed, and nothing goes back", neverPastNewest(frames3) and neverBack(frames3))
	check("and a second later it moves at an even pace again", unevenness(frames3, 4.5) < 1e-6, string.format("%.4f ms off", unevenness(frames3, 4.5) * 1000))

	-- A respawn: reset, then a new timeline far from the old one.
	local again = MovePacer.new()
	feed(again, 1, function(k)
		return k * DT
	end)
	MovePacer.reset(again)
	MovePacer.push(again, 50, poseAt(50))
	local first = MovePacer.advance(again, 3) :: PlayerCodec.Pose
	check("after a reset the first pose is the new one, not a blend with the old", first.position.x == poseAt(50).position.x)
end

-- MotionMeter -------------------------------------------------------------------

do
	-- Frames 14 to 19 ms apart at random, so the meter has to use each one's
	-- time. Positions are 32-bit, so "none" is under a millimetre a second.
	local r = rng(7)
	local function run(position: (number) -> vector, frames: number): MotionMeter.Meter
		local m = MotionMeter.new(1)
		local t = 0
		for _ = 1, frames do
			t += 0.014 + r() * 0.005
			MotionMeter.push(m, t, position(t))
		end
		return m
	end
	local steady = MotionMeter.read(run(function(t)
		return vector.create(5.4 * t, 0, 0)
	end, 120)) :: MotionMeter.Reading
	check(
		"a steady run on uneven frames reads its speed and no jumps",
		math.abs(steady.low - 5.4) < 0.001 and math.abs(steady.high - 5.4) < 0.001 and steady.jump < 0.001,
		string.format("%.3f-%.3f m/s, jumps %.4f", steady.low, steady.high, steady.jump)
	)
	check("and keeps only the last second of frames", steady.frames <= 72, string.format("%d frames", steady.frames))
	local speeding = MotionMeter.read(run(function(t)
		return vector.create(10 * t * t, 0, 0)
	end, 30)) :: MotionMeter.Reading
	check("speeding up at a steady 20 m/s^2 is no jump", speeding.jump < 0.001, string.format("%.4f m/s", speeding.jump))
	local turning = MotionMeter.read(run(function(t)
		return vector.create(3 * math.cos(t * 1.8), 0, 3 * math.sin(t * 1.8))
	end, 60)) :: MotionMeter.Reading
	check("running round a 3 m circle at 5.4 m/s is no jump to speak of", turning.jump < 0.01, string.format("%.4f m/s", turning.jump))

	local m = MotionMeter.new(1)
	local x = 0
	for i = 1, 30 do
		x += if i == 20 then 0.135 else 0.09 -- one frame 50% farther, at 60 fps and 5.4 m/s
		MotionMeter.push(m, i / 60, vector.create(x, 0, 0))
	end
	local lurch = MotionMeter.read(m) :: MotionMeter.Reading
	check("one frame drawn 50% farther jumps by about half the speed", math.abs(lurch.jump - 2.7) < 0.01, string.format("%.2f m/s", lurch.jump))
	MotionMeter.push(m, 31 / 60, vector.create(x + 20, 0, 0))
	check("a respawn or teleport starts the record over", MotionMeter.read(m) == nil)
end

-- Simulated network -------------------------------------------------------------
--
-- A player 15 m in front of a still observer runs left and right, 2 s each
-- way, at rifle speed. Their client draws `fps` frames, runs its 128 Hz moves
-- on each and sends them in one packet. The server's 60 Hz frames queue and
-- run the moves as PlayerSimServer does, run a dummy strafing the same way
-- on the server's clock, and send a snapshot with each of them twice: as the
-- newest pose and paced. The observer draws frames at the same rate with
-- the render clock and fires at the paced player's body about five times a
-- second.

type Case = {
	fps: number, -- both clients' frame rate, the running player's and the observer's
	frameJitter: number?, -- each of their frames up to this share longer
	up: number, -- one-way latency, client to server
	down: number, -- server to client
	jitter: number, -- extra delay each way, uniform from 0 to this
	serverLate: number?, -- each server frame starts up to this late
	seconds: number?,
}

type Motion = {
	frames: number, -- steady frames measured
	within: number, -- of those, frames drawn within 1% of full speed
	low: number, -- 5th and 95th percentile of the drawn speed, m/s
	high: number,
	change: number, -- 99th percentile of the change in drawn speed from one frame to the next
	jump: number, -- MotionMeter's jumps over every frame, turns included: 99th percentile and the most, m/s
	jumpMax: number,
	delay: number, -- mean seconds from the entity being somewhere to it being drawn there
}

type Watch = {
	player: Motion,
	pacedPlayer: Motion,
	dummy: Motion,
	pacedDummy: Motion,
	held: number, -- server frames the player's pacer held its newest move
	frames: number,
	shots: number,
	agreed: number,
	vmax: number,
}

local HALF = 2 -- seconds each way
local PLAYER, PACED_PLAYER, DUMMY, PACED_DUMMY = 1, 2, 3, 4

local function pose(id: number, m: any): PlayerCodec.Pose
	return {
		id = id,
		position = m.position,
		yaw = math.pi,
		pitch = 0,
		crouchAlpha = m.crouchAlpha,
		grounded = m.grounded,
		alive = true,
		quiet = false,
		reloading = false,
		weapon = 0,
		channel = 0,
	}
end

local function watch(case: Case): Watch
	local rand = rng(0xFACE + case.fps + math.floor(case.up * 1e4))
	local seconds = case.seconds or 20
	local eye = vector.create(0, cfg.standEyeHeight, 0)
	local vmax = 0

	-- The running player's client.
	local c0 = 0.0031
	local cSim = PlayerSim.new(vector.create(0, 0.02, -15), { "vandal", "", "" }, 1)
	local cLast = c0
	local cAcc = 0
	local cSeq = 0
	local cTrue: { { t: number, x: number } } = {} -- where they were, by time
	local toServer: { { at: number, inputs: { PlayerCodec.WireInput } } } = {}
	local lastUp = 0

	-- The server.
	local s0 = 0.0007
	local sFrame = 0
	local sLast = s0
	local sSim = PlayerSim.new(vector.create(0, 0.02, -15), { "vandal", "", "" }, 1)
	local queue = InputQueue.new()
	local lastSeq = 0
	local pacer = MovePacer.new()
	local dSim = PlayerSim.new(vector.create(0, 0.02, -20), { "vandal", "", "" }, 2)
	local dPacer = MovePacer.new()
	local dLast: number? = nil
	local dStart = 0
	local dTicks = 0
	local dTrue: { { t: number, x: number } } = {}
	local history = LagCompensation.new()
	local toClient: { { at: number, time: number, seq: number, poses: { PlayerCodec.Pose } } } = {}
	local shotsIn: { { at: number, viewTime: number, dir: vector, predicted: ShotResolver.Result? } } = {}

	-- The observer.
	local clock = InterpClock.new()
	local seen: { [number]: PoseHistory.History } = {}
	local drawn: { [number]: { MotionMeter.Sample } } = { {}, {}, {}, {} }
	local nextShot = 2.5
	local shots, agreed = 0, 0
	local lastUpShot = 0

	local nextC = c0 + 1 / case.fps
	local nextS = s0 + 1 / 60
	local nextA = 0.0019
	while math.min(nextC, nextS, nextA) <= seconds do
		if nextC <= nextS and nextC <= nextA then
			local now = nextC
			nextC = now + (1 / case.fps) * (1 + (case.frameJitter or 0) * rand())
			cAcc += now - cLast
			cLast = now
			local inputs: { PlayerCodec.WireInput } = {}
			while cAcc >= DT do
				cAcc -= DT
				cSeq += 1
				local buttons = if ((cSeq * DT) // HALF) % 2 == 0 then B.Left else B.Right
				local input = { seq = cSeq, buttons = buttons, slot = 1, yaw = math.pi, pitch = 0, viewTime = 0 }
				PlayerSim.step(cSim, input, cfg, floor, DT)
				table.insert(cTrue, { t = c0 + cSeq * DT, x = cSim.movement.position.x })
				table.insert(inputs, input)
			end
			if #inputs > 0 then
				-- A reliable channel: in order.
				local at = math.max(lastUp, now + case.up + rand() * case.jitter)
				lastUp = at
				table.insert(toServer, { at = at, inputs = inputs })
			end
		elseif nextS <= nextA then
			local now = nextS
			sFrame += 1
			nextS = s0 + (sFrame + 1) / 60 + (case.serverLate or 0) * rand()
			local dt = now - sLast
			sLast = now
			-- The dummy, as Dummies.step.
			local last = dLast or now
			if dLast == nil then
				dStart = now
			end
			while last + DT <= now do
				last += DT
				dTicks += 1
				local buttons = if ((dTicks * DT) // HALF) % 2 == 0 then B.Left else B.Right
				PlayerSim.step(dSim, { seq = dTicks, buttons = buttons, slot = 1, yaw = math.pi, pitch = 0, viewTime = 0 }, cfg, floor, DT)
				MovePacer.push(dPacer, last, pose(PACED_DUMMY, dSim.movement))
				table.insert(dTrue, { t = last, x = dSim.movement.position.x })
			end
			dLast = last
			-- The player's moves, as PlayerSimServer.step.
			while #toServer > 0 and toServer[1].at <= now do
				local packet = table.remove(toServer, 1) :: any
				for _, input in packet.inputs do
					if input.seq > lastSeq then
						InputQueue.push(queue, input)
					end
				end
			end
			InputQueue.refill(queue, dt)
			while true do
				local input = InputQueue.take(queue)
				if not input then
					break
				end
				if input.seq > lastSeq then
					lastSeq = input.seq
					PlayerSim.step(sSim, input, cfg, floor, DT)
					MovePacer.push(pacer, input.seq * DT, pose(PACED_PLAYER, sSim.movement))
				end
			end
			InputQueue.endFrame(queue, dt)
			-- Shots that have arrived, against the snapshots sent so far.
			while #shotsIn > 0 and shotsIn[1].at <= now do
				local shot = table.remove(shotsIn, 1) :: any
				local rewind = LagCompensation.rewindTime(shot.viewTime, now, NetConfig.maxRewind.value)
				local targets = LagCompensation.shotTargets(LagCompensation.targets(history, rewind.time, function(id)
					return id == PACED_PLAYER
				end))
				local verdict = ShotResolver.resolve(eye, shot.dir, targets, 100, 0)
				local p = shot.predicted
				shots += 1
				if (verdict == nil and p == nil) or (verdict and p and verdict.targetId == p.targetId and verdict.region == p.region) then
					agreed += 1
				end
			end
			-- The snapshot.
			local poses = {}
			if lastSeq > 0 then
				table.insert(poses, PlayerCodec.quantizePose(pose(PLAYER, sSim.movement)))
				table.insert(poses, PlayerCodec.quantizePose(MovePacer.advance(pacer, now) or pose(PACED_PLAYER, sSim.movement)))
			end
			table.insert(poses, PlayerCodec.quantizePose(pose(DUMMY, dSim.movement)))
			table.insert(poses, PlayerCodec.quantizePose(MovePacer.advance(dPacer, now) or pose(PACED_DUMMY, dSim.movement)))
			LagCompensation.record(history, now, poses)
			table.insert(toClient, { at = now + case.down + rand() * case.jitter, time = now, seq = sFrame, poses = poses })
		else
			local now = nextA
			nextA += (1 / case.fps) * (1 + (case.frameJitter or 0) * rand())
			local arrived = {}
			for i = #toClient, 1, -1 do
				if toClient[i].at <= now then
					table.insert(arrived, table.remove(toClient, i))
				end
			end
			table.sort(arrived, function(a, b)
				return a.at < b.at
			end)
			for _, snapshot in arrived do
				InterpClock.onSnapshot(clock, snapshot.time, now, snapshot.seq)
				for _, p in snapshot.poses do
					local h = seen[p.id]
					if not h then
						h = PoseHistory.new()
						seen[p.id] = h
					end
					PoseHistory.push(h, snapshot.time, p)
				end
			end
			local render = InterpClock.advance(clock, now)
			if render then
				for id, h in seen do
					local lookup = PoseHistory.sample(h, render)
					if lookup and now > 2 then
						table.insert(drawn[id], { at = now, position = lookup.pose.position })
					end
				end
				-- Fire at the paced player as drawn, with this frame's time.
				local target = seen[PACED_PLAYER]
				local lookup = if target then PoseHistory.sample(target, render) else nil
				if lookup and now >= nextShot then
					nextShot += 0.17 + rand() * 0.06
					local box: Hitboxes.Pose = { position = lookup.pose.position, yaw = lookup.pose.yaw, crouchAlpha = lookup.pose.crouchAlpha }
					local dir = vector.normalize((Hitboxes.region(box, "body") :: Hitboxes.Box).center - eye)
					local predicted = ShotResolver.resolve(eye, dir, { { id = PACED_PLAYER, pose = box } }, 100, 0)
					local at = math.max(lastUpShot, now + case.up + rand() * case.jitter)
					lastUpShot = at
					table.insert(shotsIn, { at = at, viewTime = render, dir = dir, predicted = predicted })
				end
			end
		end
	end
	vmax = PlayerSim.weaponSpeed(cSim, cfg)

	-- When the entity was at x, near time `before` (steady motion, so x
	-- moves one way only around then).
	local function whenAt(path: { { t: number, x: number } }, x: number, before: number): number?
		local found: number? = nil
		for i = 2, #path do
			local a, b = path[i - 1], path[i]
			if b.t > before then
				break
			end
			if a.x ~= b.x and (x - a.x) * (x - b.x) <= 0 then
				found = a.t + (b.t - a.t) * (x - a.x) / (b.x - a.x)
			end
		end
		return found
	end

	local function motion(id: number): Motion
		local frames = drawn[id]
		local origin = if id <= PACED_PLAYER then c0 else dStart
		local path = if id <= PACED_PLAYER then cTrue else dTrue
		local speeds, changes = {}, {}
		local within = 0
		local delaySum, delayN = 0, 0
		local lastSpeed: number? = nil
		for i = 2, #frames do
			local f, prev = frames[i], frames[i - 1]
			local v = math.abs(f.position.x - prev.position.x) / (f.at - prev.at)
			-- Full speed: 0.6 s or more into a run, before it turns.
			if (f.at - origin) % HALF > 0.6 then
				table.insert(speeds, v)
				if math.abs(v - vmax) <= vmax * 0.01 then
					within += 1
				end
				if lastSpeed then
					table.insert(changes, math.abs(v - lastSpeed))
				end
				lastSpeed = v
				if i % 9 == 0 then
					local t = whenAt(path, f.position.x, f.at)
					if t then
						delaySum += f.at - t
						delayN += 1
					end
				end
			else
				lastSpeed = nil
			end
		end
		local jumps = MotionMeter.jumps(frames)
		table.sort(speeds)
		table.sort(changes)
		table.sort(jumps)
		local function q(list: { number }, share: number): number
			return list[math.clamp(math.floor(#list * share) + 1, 1, #list)]
		end
		return {
			frames = #speeds,
			within = within,
			low = q(speeds, 0.05),
			high = q(speeds, 0.95),
			change = q(changes, 0.99),
			jump = q(jumps, 0.99),
			jumpMax = jumps[#jumps],
			delay = delaySum / math.max(delayN, 1),
		}
	end

	return {
		player = motion(PLAYER),
		pacedPlayer = motion(PACED_PLAYER),
		dummy = motion(DUMMY),
		pacedDummy = motion(PACED_DUMMY),
		held = pacer.stats.held,
		frames = pacer.stats.frames,
		shots = shots,
		agreed = agreed,
		vmax = vmax,
	}
end

local function line(name: string, m: Motion)
	print(string.format(
		"  [pacing]   %-18s at full speed %5.2f-%5.2f m/s (5th-95th), within 1%% on %6s, frame to frame up to %4.2f, jumps %4.2f (most %4.2f), delay %5.1f ms",
		name,
		m.low,
		m.high,
		pct(m.within, m.frames),
		m.change,
		m.jump,
		m.jumpMax,
		m.delay * 1000
	))
end

local function report(name: string, w: Watch)
	print(string.format(
		"  [pacing] %s: player paced with %s of frames held; shots at them agree %s of %d",
		name,
		pct(w.held, w.frames),
		pct(w.agreed, w.shots),
		w.shots
	))
	line("player, newest", w.player)
	line("player, paced", w.pacedPlayer)
	line("dummy, newest", w.dummy)
	line("dummy, paced", w.pacedDummy)
end

do
	local studio60 = watch({ fps = 60, up = 0.0005, down = 0.0005, jitter = 0.001 })
	report("Studio at 60 fps", studio60)
	local studio144 = watch({ fps = 144, up = 0.0005, down = 0.0005, jitter = 0.001 })
	report("Studio at 144 fps", studio144)
	local rough = watch({ fps = 60, frameJitter = 0.2, up = 0.0005, down = 0.0005, jitter = 0.001, serverLate = 0.002 })
	report("Studio, uneven frames at 60 fps", rough)
	local far = watch({ fps = 144, up = 0.04, down = 0.04, jitter = 0.005 })
	report("40 ms each way, 0-5 ms jitter, 144 fps", far)

	local function smooth(m: Motion): boolean
		return m.within / m.frames >= 0.95
	end
	check("unpaced, a player at 60 fps lurches by a third of their speed", studio60.player.high - studio60.player.low > studio60.vmax / 3, string.format("%.2f-%.2f m/s", studio60.player.low, studio60.player.high))
	check("unpaced, a dummy lurches too", studio60.dummy.high - studio60.dummy.low > studio60.vmax / 3, string.format("%.2f-%.2f m/s", studio60.dummy.low, studio60.dummy.high))
	check(
		string.format("unpaced, frames of a steady run jump over %.1f m/s off their neighbours", SMOOTH_JUMP * 2),
		studio60.player.jump > SMOOTH_JUMP * 2 and studio60.dummy.jump > SMOOTH_JUMP * 2,
		string.format("player %.2f, dummy %.2f (99th percentile)", studio60.player.jump, studio60.dummy.jump)
	)
	for _, entry in { { "Studio at 60 fps", studio60 }, { "Studio at 144 fps", studio144 }, { "uneven frames", rough }, { "40 ms each way", far } } :: { { any } } do
		local name, w = entry[1] :: string, entry[2] :: Watch
		check(
			string.format("paced, %s: the player is drawn within 1%% of full speed on 95%% of frames", name),
			smooth(w.pacedPlayer),
			pct(w.pacedPlayer.within, w.pacedPlayer.frames)
		)
		check(string.format("paced, %s: and so is the dummy", name), smooth(w.pacedDummy), pct(w.pacedDummy.within, w.pacedDummy.frames))
		check(
			string.format("paced, %s: no frame of either jumps %.1f m/s off its neighbours, turns included", name, SMOOTH_JUMP),
			w.pacedPlayer.jumpMax < SMOOTH_JUMP and w.pacedDummy.jumpMax < SMOOTH_JUMP,
			string.format("player %.2f, dummy %.2f", w.pacedPlayer.jumpMax, w.pacedDummy.jumpMax)
		)
		check(
			string.format("paced, %s: the player is seen under 15 ms later than unpaced", name),
			w.pacedPlayer.delay - w.player.delay < 0.015,
			string.format("%+.1f ms", (w.pacedPlayer.delay - w.player.delay) * 1000)
		)
		check(string.format("paced, %s: held on the newest move on under 2%% of frames", name), w.held / w.frames < 0.02, pct(w.held, w.frames))
		check(string.format("paced, %s: shots at the paced player agree with the server", name), w.agreed == w.shots and w.shots > 0, pct(w.agreed, w.shots))
	end
	local dummyCost = studio60.pacedDummy.delay - studio60.dummy.delay
	check(
		string.format("a paced dummy is seen about half a tick and %.0f ms later", MARGIN * 1000),
		math.abs(dummyCost - (DT / 2 + MARGIN)) < 0.002,
		string.format("%+.1f ms", dummyCost * 1000)
	)
end

return nil
