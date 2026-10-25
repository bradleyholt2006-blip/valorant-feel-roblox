--!strict
-- Hit registration and lag compensation (system 4): the pose history both
-- sides interpolate with, the render clock, the server's rewind, and a
-- simulated network that fires at a strafing target and counts how often the
-- client's guess and the server's verdict agree.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local PoseHistory = require("../src/shared/Net/PoseHistory")
local InterpClock = require("../src/shared/Net/InterpClock")
local MovePacer = require("../src/shared/Net/MovePacer")
local NetConfig = require("../src/shared/Net/NetConfig")
local LagCompensation = require("../src/shared/Combat/LagCompensation")
local ShotResolver = require("../src/shared/Combat/ShotResolver")
local Hitboxes = require("../src/shared/Combat/Hitboxes")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()

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

local function pose(id: number, x: number, yaw: number?, crouch: number?): PlayerCodec.Pose
	return {
		id = id,
		position = vector.create(x, 0, -10),
		yaw = yaw or 0,
		pitch = 0,
		crouchAlpha = crouch or 0,
		grounded = true,
		alive = true,
		quiet = false,
		reloading = false,
		weapon = 0,
		channel = 0,
		gliding = false,
	}
end

local function pct(n: number, d: number): string
	return if d > 0 then string.format("%.1f%%", n / d * 100) else "--"
end

H.section("Hit registration tests")

-- Pose history ------------------------------------------------------------------

do
	local h = PoseHistory.new(8)
	check("an empty history has no pose", PoseHistory.sample(h, 1) == nil)
	PoseHistory.push(h, 1.0, pose(7, 0, 3.0))
	PoseHistory.push(h, 1.1, pose(7, 1, -3.0))
	check("older or repeated snapshots are ignored", not PoseHistory.push(h, 1.1, pose(7, 5)) and not PoseHistory.push(h, 1.05, pose(7, 5)) and #h.samples == 2)
	local mid = PoseHistory.sample(h, 1.05) :: PoseHistory.Lookup
	check("halfway between snapshots is halfway between their poses", near(mid.pose.position.x, 0.5, 1e-6) and mid.from == 1.0 and mid.to == 1.1 and not mid.held)
	check("yaw blends the short way round", near(math.abs(mid.pose.yaw), math.pi, 1e-6), tostring(mid.pose.yaw))
	local before = PoseHistory.sample(h, 0.5) :: PoseHistory.Lookup
	check("before the first snapshot its pose is used", before.pose.position.x == 0 and not before.held)
	local exact = PoseHistory.sample(h, 1.1) :: PoseHistory.Lookup
	check("at a snapshot's time its pose is used exactly", exact.pose.position.x == 1 and not exact.held)
	local after = PoseHistory.sample(h, 1.3) :: PoseHistory.Lookup
	check("past the newest snapshot its pose is held, not extrapolated", after.pose.position.x == 1 and after.held)
	PoseHistory.push(h, 1.1 + PoseHistory.MAX_GAP + 0.01, pose(7, 9))
	check("coming back after a gap drops the old poses (no slide from death to respawn)", #h.samples == 1)
	for i = 1, 20 do
		PoseHistory.push(h, 2 + i * 0.01, pose(7, i))
	end
	check("the history keeps to its capacity", #h.samples == 8)
end

-- Hit confirm placement ------------------------------------------------------------

do
	local standing: Hitboxes.Pose = { position = vector.create(0, 0, -10), yaw = 0, crouchAlpha = 0 }
	local body = Hitboxes.region(standing, "body") :: Hitboxes.Box
	local point = body.center + vector.create(0.1, 0.2, body.half.z)
	local f = Hitboxes.boxFraction(body, point)
	check("a hit point maps into its box", math.abs(f.x) <= 1 and math.abs(f.y) <= 1 and near(f.z, 1, 1e-5))
	check("and back to the same point", vector.magnitude(Hitboxes.boxPoint(body, f) - point) < 1e-5)
	local moved: Hitboxes.Pose = { position = vector.create(2, 0, -12), yaw = math.pi / 2, crouchAlpha = 1 }
	local crouched = Hitboxes.region(moved, "body") :: Hitboxes.Box
	local follow = Hitboxes.boxPoint(crouched, f)
	check("the same spot follows the character as it moves, turns and crouches", vector.magnitude(Hitboxes.boxFraction(crouched, follow) - f) < 1e-5)
end

-- Render clock -------------------------------------------------------------------

-- Feeds a clock one 60 Hz stream of snapshots, sent at k/60 and arriving
-- `latency(sent)` later, and draws 144 Hz frames for `seconds`. Each frame
-- handles what has arrived, then advances the clock. While `stalled(now)`
-- the client draws no frames, so what arrives waits for the next one.
local function driveClock(
	c: InterpClock.Clock,
	seconds: number,
	latency: (number) -> number,
	onFrame: (now: number, render: number) -> (),
	stalled: ((number) -> boolean)?
)
	local sends = {}
	local k = 0
	while k / 60 < seconds do
		local sent = k / 60
		table.insert(sends, { time = sent, at = sent + latency(sent), seq = k })
		k += 1
	end
	table.sort(sends, function(a, b)
		return a.at < b.at
	end)
	local i = 1
	local f = 0
	while true do
		f += 1
		local now = (f + 0.37) / 144
		if now > seconds then
			break
		end
		if stalled and stalled(now) then
			continue
		end
		while i <= #sends and sends[i].at <= now do
			InterpClock.onSnapshot(c, sends[i].time, now, sends[i].seq)
			i += 1
		end
		local render = InterpClock.advance(c, now)
		if render then
			onFrame(now, render)
		end
	end
end

type ClockStats = { frames: number, starved: number, delay: number, maxDelay: number, minBuffer: number, backwards: boolean }

local function clockStats(c: InterpClock.Clock, seconds: number, latency: (number) -> number, from: number, to: number, stalled: ((number) -> boolean)?): ClockStats
	local stats: ClockStats = { frames = 0, starved = 0, delay = 0, maxDelay = 0, minBuffer = math.huge, backwards = false }
	local last = -math.huge
	driveClock(c, seconds, latency, function(now, render)
		if render <= last then
			stats.backwards = true
		end
		last = render
		if now >= from and now < to then
			stats.frames += 1
			if render > c.newest then
				stats.starved += 1
			end
			stats.delay += c.delay
			stats.maxDelay = math.max(stats.maxDelay, c.delay)
			stats.minBuffer = math.min(stats.minBuffer, c.newest - render)
		end
	end, stalled)
	stats.delay /= math.max(stats.frames, 1)
	return stats
end

do
	local steady = clockStats(InterpClock.new(), 10, function()
		return 0.04
	end, 2, 10)
	print(string.format("  [interp] 40 ms, no jitter: delay %.1f ms behind the stream, starved %s of frames", steady.delay * 1000, pct(steady.starved, steady.frames)))
	check("steady latency: never runs out of snapshots", steady.starved == 0, pct(steady.starved, steady.frames))
	check("steady latency: draws within two snapshot intervals of the newest", steady.delay < 2 / 60, string.format("%.1f ms", steady.delay * 1000))

	local jr = rng(7)
	local jittery = clockStats(InterpClock.new(), 20, function()
		return 0.04 + jr() * 0.008
	end, 3, 20)
	print(string.format("  [interp] 40 ms + 0-8 ms jitter: delay %.1f ms, starved %s of frames", jittery.delay * 1000, pct(jittery.starved, jittery.frames)))
	check("8 ms of jitter: out of snapshots on under 2% of frames", jittery.starved / jittery.frames < 0.02, pct(jittery.starved, jittery.frames))

	local step = InterpClock.new()
	local after = clockStats(step, 12, function(sent)
		return if sent < 5 then 0.04 else 0.1
	end, 7, 12)
	print(string.format("  [interp] latency 40 -> 100 ms at 5 s: settled by 7 s, starved %s of frames after", pct(after.starved, after.frames)))
	check("render time only ever moves forward, even through a latency jump", not after.backwards)
	check("after a latency jump the clock settles again", after.starved == 0 and after.delay < 2 / 60, string.format("%s starved, %.1f ms", pct(after.starved, after.frames), after.delay * 1000))

	local down = clockStats(InterpClock.new(), 12, function(sent)
		return if sent < 5 then 0.1 else 0.04
	end, 8, 12)
	check("after latency drops the clock catches up without running out", not down.backwards and down.starved == 0 and down.delay < 2 / 60)

	-- Roblox holds a remote's events until a listener connects: a client
	-- that starts listening 2 s into the stream gets those 2 s at once.
	local joined = clockStats(InterpClock.new(), 6, function(sent)
		return if sent < 1.96 then 2 - sent else 0.04
	end, 2, 6)
	check(
		"a client that has just joined gets seconds of old snapshots at once, and its delay stays low",
		joined.maxDelay < 0.035 and joined.delay < 2 / 60 and joined.starved / joined.frames < 0.02,
		string.format("most %.1f ms, starved %s", joined.maxDelay * 1000, pct(joined.starved, joined.frames))
	)

	-- As measured in Studio: the 2 s held back come over 0.6 s, and the
	-- next 2 s in clumps a fifth of a second apart, catching up as they go.
	-- Entities hold their poses between the clumps; once they stop, the
	-- delay is measured.
	local function loadingLatency(sent: number): number
		if sent < 2 then
			return 2 - 0.7 * sent
		elseif sent < 4 then
			local behind = 0.3 * (4 - sent)
			return math.ceil((sent + behind) / 0.2) * 0.2 - sent + 0.04
		end
		return 0.04
	end
	local loading = clockStats(InterpClock.new(), 9, loadingLatency, 2, 9)
	local loaded = clockStats(InterpClock.new(), 9, loadingLatency, 5, 9)
	check(
		"nor does one whose snapshots come in clumps for 2 s more while it finishes loading",
		loading.maxDelay < 0.035 and loaded.delay < 2 / 60 and loaded.starved / loaded.frames < 0.02,
		string.format("most %.1f ms, then %.1f ms, starved %s", loading.maxDelay * 1000, loaded.delay * 1000, pct(loaded.starved, loaded.frames))
	)

	local stall = clockStats(InterpClock.new(), 8, function()
		return 0.04
	end, 5, 8, function(now)
		return now > 5 and now < 5.3
	end)
	check(
		"a client that stalls for 0.3 s handles the snapshots that came in meanwhile at once, and that doesn't raise its delay",
		stall.maxDelay < 2 / 60 and stall.starved == 0,
		string.format("most %.1f ms, starved %s", stall.maxDelay * 1000, pct(stall.starved, stall.frames))
	)

	local buffered = InterpClock.new()
	clockStats(buffered, 3, function()
		return 0.04
	end, 0, 0)
	local before = buffered.delay
	InterpClock.setExtra(buffered, NetConfig.Buffering[2].extra)
	check("Network Buffering 'Moderate' adds 15.6 ms, as the reference's 2 extra frames do", near(buffered.delay - before, 0.015625, 1e-9))
end

-- Server rewind ---------------------------------------------------------------------

do
	local cap = NetConfig.maxRewind.value
	check("the rewind cap is Riot's 140 ms", cap == 0.140)
	local r = LagCompensation.rewindTime(9.95, 10, cap)
	check("a recent viewTime is used as sent", r.time == 9.95 and not r.clamped and near(r.amount, 0.05, 1e-9))
	local old = LagCompensation.rewindTime(9.7, 10, cap)
	check("an older viewTime is checked at the cap", near(old.time, 10 - cap, 1e-9) and old.clamped and near(old.amount, cap, 1e-9))
	local future = LagCompensation.rewindTime(10.5, 10, cap)
	check("a viewTime from the future is checked at now", future.time == 10 and future.clamped)
end

do
	local server = LagCompensation.new()
	local client = PoseHistory.new()
	local r = rng(12345)
	for k = 0, 30 do
		local t = 100 + k / 60
		local p = PlayerCodec.quantizePose({
			id = 5,
			position = vector.create(r() * 10, r(), r() * 10),
			yaw = r() * 7,
			pitch = r() - 0.5,
			crouchAlpha = r(),
			grounded = true,
			alive = true,
			quiet = false,
			reloading = false,
			weapon = 0,
			channel = 0,
			gliding = false,
		})
		LagCompensation.record(server, t, { p })
		local _, decoded = PlayerCodec.decodeSnapshot(PlayerCodec.encodeSnapshot(t, { p }, k))
		PoseHistory.push(client, t, decoded[1])
	end
	local same = true
	for _ = 1, 200 do
		local t = 100 + r() * 0.5
		local s = LagCompensation.targets(server, t, function()
			return true
		end)[1]
		local c = PoseHistory.sample(client, t)
		same = same
			and c ~= nil
			and s.pose.position == c.pose.position
			and s.pose.yaw == c.pose.yaw
			and s.pose.crouchAlpha == c.pose.crouchAlpha
			and s.from == c.from
			and s.to == c.to
	end
	check("the server rebuilds exactly the pose the client drew from the same snapshots", same)
	check("filtered-out entities (the shooter, the dead) are not targets", #LagCompensation.targets(server, 100.2, function(id)
		return id ~= 5
	end) == 0)
	LagCompensation.record(server, 102, {})
	check("an entity missing from snapshots for a second is forgotten", next(server.histories) == nil)
end

-- Simulated network ---------------------------------------------------------------
--
-- A server at 60 Hz frames simulates a practice dummy strafing 15 m in front
-- of a still shooter (left and right every 0.6 s at rifle speed, with the
-- real movement model) and sends a snapshot every frame, showing the dummy
-- through a MovePacer as the real server does. The client draws
-- 144 Hz frames with the render clock and fires about five shots a second at
-- the target as drawn (a perfect aimer). By default each shot goes to a random
-- spot on one of its boxes, half of them close to an edge on purpose; with
-- `aim` every shot goes to the middle of one box, as a player tracking the
-- target does (and TestAim, which Studio playtests aim with). Each shot
-- carries the time of the frame the player saw. Two comparisons with the
-- server's verdict:
--   * agree: the client's own trace of the shot (what the debug tools show)
--   * faithful: the shot against the target exactly as it was drawn, i.e.
--     whether the server judged what the player saw

type NetCase = {
	up: number, -- client to server one-way latency, seconds
	down: number, -- server to client
	jitter: number, -- extra delay each way, uniform from 0 to this
	loss: number, -- share of snapshots lost
	maxRewind: number?, -- the server's rewind cap (NetConfig.maxRewind); 0 is no lag compensation
	aim: Hitboxes.Region?, -- aim at the middle of this box instead of anywhere on any box
	gap: number?, -- seconds between shots, evenly, instead of an uneven 0.17-0.23 s
	first: number?, -- when the first shot goes (1.5 s)
	fixedClock: boolean?, -- draw at (server time - 50 ms) like system 1-3, instead of the render clock
	seconds: number?,
}

type NetResult = {
	shots: number,
	agreed: number,
	faithful: number,
	moving: number, -- shots at the target while it moved, as the Hit Reg Lab counts them
	movingAgreed: number,
	clamped: number,
	rewindSum: number,
	rewindMax: number,
	frames: number,
	starved: number,
}

local TARGET_ID = PlayerCodec.DUMMY_BASE + 1
local SHOOTER_ID = 1
local STRAFE_TICKS = math.floor(0.6 * MovementConfig.TickRate.value)
local REGIONS: { Hitboxes.Region } = { "head", "body", "legs" }
local MOVING_SPEED = 0.5 -- m/s over the last 50 ms drawn, ClientShots' test for a moving target

local function boxPose(p: PlayerCodec.Pose): Hitboxes.Pose
	return { position = p.position, yaw = p.yaw, crouchAlpha = p.crouchAlpha }
end

-- Same target and region, or both missed.
local function same(a: ShotResolver.Result?, b: ShotResolver.Result?): boolean
	if a == nil or b == nil then
		return a == nil and b == nil
	end
	return a.targetId == b.targetId and a.region == b.region
end

local function simulate(case: NetCase): NetResult
	local rand = rng(0x5EED + math.floor(case.up * 1e5) + math.floor(case.jitter * 1e6) + math.floor(case.loss * 1e3))
	local target = PlayerSim.new(vector.create(0, 0.02, -15), { "vandal", "", "" }, 1)
	local ticks = 0
	local simulated = 0
	local pacer = MovePacer.new()
	local function targetPose(): PlayerCodec.Pose
		local m = target.movement
		return {
			id = TARGET_ID,
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
			gliding = false,
		}
	end
	local history = LagCompensation.new()
	local seen = PoseHistory.new()
	local clock = InterpClock.new()
	local eye = vector.create(0, cfg.standEyeHeight, 0)
	local toClient: { { at: number, time: number, seq: number, pose: PlayerCodec.Pose } } = {}
	local frame = 0
	local toServer: { { at: number, viewTime: number, dir: vector, predicted: ShotResolver.Result?, seen: ShotResolver.Result?, moving: boolean } } = {}
	local result: NetResult = {
		shots = 0,
		agreed = 0,
		faithful = 0,
		moving = 0,
		movingAgreed = 0,
		clamped = 0,
		rewindSum = 0,
		rewindMax = 0,
		frames = 0,
		starved = 0,
	}
	local duration = case.seconds or 60
	local nextServer = 0
	local nextClient = 0.0013
	local nextShot = case.first or 1.5
	local upFree = 0
	local lastRender: number? = nil
	local lastDrawn: PlayerCodec.Pose? = nil

	while math.min(nextServer, nextClient) <= duration do
		if nextServer <= nextClient then
			local now = nextServer
			nextServer += 1 / NetConfig.SNAPSHOT_RATE
			while simulated + DT <= now + 1e-9 do
				ticks += 1
				local buttons = if (ticks // STRAFE_TICKS) % 2 == 0 then B.Left else B.Right
				PlayerSim.step(target, { seq = ticks, buttons = buttons, slot = 1, yaw = math.pi, pitch = 0, viewTime = 0 }, cfg, floor, DT)
				simulated += DT
				MovePacer.push(pacer, simulated, targetPose())
			end
			-- Shots first, then the frame's snapshot, as on the real server.
			while #toServer > 0 and toServer[1].at <= now do
				local shot = table.remove(toServer, 1) :: any
				-- With a cap of 0 this is the newest pose sent, as on the real server.
				local rewind = LagCompensation.rewindTime(shot.viewTime, now, case.maxRewind or NetConfig.maxRewind.value)
				result.rewindSum += rewind.amount
				result.rewindMax = math.max(result.rewindMax, rewind.amount)
				result.clamped += if rewind.clamped then 1 else 0
				local targets = LagCompensation.shotTargets(LagCompensation.targets(history, rewind.time, function(id)
					return id ~= SHOOTER_ID
				end))
				local verdict = ShotResolver.resolve(eye, shot.dir, targets, 100, SHOOTER_ID)
				local agreed = same(verdict, shot.predicted)
				result.shots += 1
				result.agreed += if agreed then 1 else 0
				result.faithful += if same(verdict, shot.seen) then 1 else 0
				if shot.moving then
					result.moving += 1
					result.movingAgreed += if agreed then 1 else 0
				end
			end
			-- Until its first tick, where it is, as Dummies does.
			local p = PlayerCodec.quantizePose(MovePacer.advance(pacer, now) or targetPose())
			LagCompensation.record(history, now, { p })
			frame += 1
			if rand() >= case.loss then
				table.insert(toClient, { at = now + case.down + rand() * case.jitter, time = now, seq = frame, pose = p })
			end
		else
			local now = nextClient
			nextClient += 1 / 144
			local arrived = {}
			for i = #toClient, 1, -1 do
				if toClient[i].at <= now then
					table.insert(arrived, table.remove(toClient, i))
				end
			end
			table.sort(arrived, function(a, b)
				return a.at < b.at
			end)
			for _, s in arrived do
				InterpClock.onSnapshot(clock, s.time, now, s.seq)
				PoseHistory.push(seen, s.time, s.pose)
			end
			local render: number?
			if case.fixedClock then
				-- Server time now, as a perfectly synchronised client clock would read it.
				render = now - 0.05
			else
				render = InterpClock.advance(clock, now)
			end
			if render and now >= 1 then
				result.frames += 1
				local newest = PoseHistory.newest(seen)
				if newest and render > newest.time then
					result.starved += 1
				end
			end
			-- The player clicks while looking at the last frame drawn. The
			-- client traces the shot at that frame's time with the snapshots it
			-- has now, as ClientShots does.
			if lastRender and lastDrawn and now >= nextShot then
				nextShot += case.gap or 0.17 + rand() * 0.06 -- irregular, so shots land at every phase of the snapshot cycle
				local drawn = boxPose(lastDrawn)
				local aim: vector
				if case.aim then
					aim = (Hitboxes.region(drawn, case.aim) :: Hitboxes.Box).center
				else
					local box = Hitboxes.region(drawn, REGIONS[math.floor(rand() * 3) + 1]) :: Hitboxes.Box
					-- Half the shots go anywhere on the box (and a little past it),
					-- half close to a side edge, where a few millimetres decide.
					local u = if rand() < 0.5 then rand() * 2.2 - 1.1 else (0.85 + rand() * 0.3) * (if rand() < 0.5 then -1 else 1)
					aim = box.center + vector.create(u * box.half.x, (rand() * 1.8 - 0.9) * box.half.y, 0)
				end
				local dir = vector.normalize(aim - eye)
				local traced = PoseHistory.sample(seen, lastRender) :: PoseHistory.Lookup
				local before = PoseHistory.sample(seen, lastRender - 0.05)
				local moving = before ~= nil and vector.magnitude(traced.pose.position - before.pose.position) / 0.05 > MOVING_SPEED
				local predicted = ShotResolver.resolve(eye, dir, { { id = TARGET_ID, pose = boxPose(traced.pose) } }, 100, SHOOTER_ID)
				local seenResult = ShotResolver.resolve(eye, dir, { { id = TARGET_ID, pose = drawn } }, 100, SHOOTER_ID)
				local at = math.max(upFree, now + case.up + rand() * case.jitter)
				upFree = at
				table.insert(toServer, { at = at, viewTime = lastRender, dir = dir, predicted = predicted, seen = seenResult, moving = moving })
			end
			lastRender = render
			local drawnNow = if render then PoseHistory.sample(seen, render) else nil
			lastDrawn = if drawnNow then drawnNow.pose else nil
		end
	end
	return result
end

local function report(name: string, r: NetResult): number
	local agreement = r.agreed / math.max(r.shots, 1)
	print(string.format(
		"  [hitreg] %-40s agree %6s  moving %6s  as seen %6s  of %d  rewind mean %3.0f ms max %3.0f  capped %d  starved %s",
		name,
		pct(r.agreed, r.shots),
		pct(r.movingAgreed, r.moving),
		pct(r.faithful, r.shots),
		r.shots,
		r.rewindSum / math.max(r.shots, 1) * 1000,
		r.rewindMax * 1000,
		r.clamped,
		pct(r.starved, r.frames)
	))
	return agreement
end

do
	local studio = report("Studio (no latency)", simulate({ up = 0, down = 0, jitter = 0, loss = 0 }))
	check("no latency: client and server always agree", studio == 1)

	local good = simulate({ up = 0.04, down = 0.04, jitter = 0.003, loss = 0 })
	local goodAgree = report("80 ms ping, 3 ms jitter", good)
	check("80 ms ping: they agree on at least 99% of shots", goodAgree >= 0.99, pct(good.agreed, good.shots))
	check("80 ms ping: nothing hits the 140 ms cap", good.clamped == 0)

	local noRewind = report("80 ms ping, no lag compensation", simulate({ up = 0.04, down = 0.04, jitter = 0.003, loss = 0, maxRewind = 0 }))
	check("without lag compensation most shots at a strafing target disagree", noRewind < 0.6, string.format("%.0f%%", noRewind * 100))

	local lossy = simulate({ up = 0.04, down = 0.04, jitter = 0.003, loss = 0.03 })
	local lossyAgree = report("80 ms ping, 3% snapshot loss", lossy)
	check("3% snapshot loss: they still agree on at least 97% of shots", lossyAgree >= 0.97, pct(lossy.agreed, lossy.shots))

	local high = simulate({ up = 0.075, down = 0.075, jitter = 0.003, loss = 0 })
	local highAgree = report("150 ms ping (past the cap)", high)
	check("150 ms ping: every shot is checked at the 140 ms cap", high.clamped == high.shots and high.shots > 0)
	check("past the cap the shooter's view and the server's diverge", highAgree < goodAgree)

	local fixed = simulate({ up = 0.04, down = 0.04, jitter = 0.003, loss = 0, fixedClock = true })
	report("80 ms ping, old fixed 50 ms clock", fixed)
	check("the old clock drew past its newest snapshot on a third or more of frames at 40 ms one way", fixed.starved / fixed.frames > 0.33, pct(fixed.starved, fixed.frames))
	check("so the server judged shots against poses the player never saw", fixed.faithful < fixed.shots, pct(fixed.faithful, fixed.shots))
	check("with the render clock the server judges what the player saw", good.faithful == good.shots and good.starved / good.frames < 0.02, pct(good.faithful, good.shots))
end

-- The Studio checklist's H6 to H8 (docs/studio-checklist.md quotes these),
-- aimed like a player tracking the strafer: at the middle of its body, or of
-- its head. Without the cap's full rewind, whether a shot agrees depends on
-- where in the strafe it lands: near a turn the dummy has barely moved, at
-- full speed it has left the ray.
do
	local function aimed(name: string, case: NetCase): (NetResult, NetResult)
		local body, head = table.clone(case), table.clone(case)
		body.aim, head.aim = "body", "head"
		local b, h = simulate(body), simulate(head)
		report(name .. ", body", b)
		report(name .. ", head", h)
		return b, h
	end
	local function moving(r: NetResult): number
		return r.movingAgreed / math.max(r.moving, 1)
	end

	local h6b, h6h = aimed("H6 40 ms each way, jitter, loss", { up = 0.04, down = 0.04, jitter = 0.005, loss = 0.02 })
	check("H6: shots at the middle of a box agree at least 99% of the time", h6b.agreed / h6b.shots >= 0.99 and h6h.agreed / h6h.shots >= 0.99)

	local h7b, h7h = aimed("H7 the same, no lag compensation", { up = 0.04, down = 0.04, jitter = 0.005, loss = 0.02, maxRewind = 0 })
	check("H7: with the cap at 0 every shot counts as capped", h7b.clamped == h7b.shots and h7h.clamped == h7h.shots)
	check("H7: about a quarter of body shots at the moving strafer agree", moving(h7b) > 0.18 and moving(h7b) < 0.34, pct(h7b.movingAgreed, h7b.moving))
	check("H7: and about a fifth of head shots", moving(h7h) > 0.12 and moving(h7h) < 0.3, pct(h7h.movingAgreed, h7h.moving))

	local nb, nh = aimed("H7 at Studio's own ping", { up = 0, down = 0, jitter = 0, loss = 0, maxRewind = 0 })
	check(
		"at Studio's own ping, no lag compensation hardly shows on the body (the strafer moves less than its half width)",
		moving(nb) >= 0.95,
		pct(nb.movingAgreed, nb.moving)
	)
	check("but it does on the head", moving(nh) < 0.95, pct(nh.movingAgreed, nh.moving))

	local h8b, h8h = aimed("H8 80 ms each way, past the cap", { up = 0.08, down = 0.08, jitter = 0.005, loss = 0.02 })
	check("H8: every shot is checked at the cap", h8b.clamped == h8b.shots and h8h.clamped == h8h.shots)
	check("H8: a bit under half the body shots at the moving strafer agree", moving(h8b) > 0.35 and moving(h8b) < 0.55, pct(h8b.movingAgreed, h8b.moving))
	check("H8: and about a fifth of head shots", moving(h8h) > 0.15 and moving(h8h) < 0.3, pct(h8h.movingAgreed, h8h.moving))

	-- An even beat at the strafe's own period lands every shot at the same
	-- point of it, so the checklist asks for uneven gaps.
	local low, high = 1, 0
	for i = 0, 9 do
		local r = simulate({
			up = 0.04,
			down = 0.04,
			jitter = 0.005,
			loss = 0.02,
			maxRewind = 0,
			aim = "body",
			gap = STRAFE_TICKS * DT,
			first = 1.5 + i * 0.06,
			seconds = 1.5 + 20 * 0.6,
		})
		low, high = math.min(low, moving(r)), math.max(high, moving(r))
	end
	check("H7: 20 body shots on a 0.6 s beat agree on almost none or almost all, depending on when the first goes", low < 0.1 and high > 0.9, string.format("%.0f%% to %.0f%%", low * 100, high * 100))
end

return nil
