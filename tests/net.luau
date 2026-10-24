--!strict
-- Wire formats and reconciliation: what the server acks must be enough for
-- the client to resume the simulation bit for bit.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local InputQueue = require("../src/shared/Net/InputQueue")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor():addBox(vector.create(3, 0, -20), vector.create(4, 0.3, 20))

H.section("Network tests")

do
	local inputs: { PlayerCodec.WireInput } = {
		{ seq = 1, buttons = B.Forward + B.Fire, slot = 1, yaw = 1.0, pitch = 0.2, viewTime = 1234.5678 },
		{ seq = 2, buttons = B.AltFire + B.Reload + B.Crouch, slot = 3, yaw = -2.5, pitch = -1.4, viewTime = 1234.6 },
	}
	local decoded = PlayerCodec.decodeInputs(PlayerCodec.encodeInputs(inputs, 1, 2))
	local ok = decoded ~= nil and #decoded == 2
	if decoded then
		for i, d in decoded do
			local src = inputs[i]
			ok = ok
				and d.seq == src.seq
				and d.buttons == src.buttons
				and d.slot == src.slot
				and d.viewTime == src.viewTime
				and d.yaw == PlayerCodec.quantizeYaw(src.yaw)
				and d.pitch == PlayerCodec.quantizePitch(src.pitch)
		end
	end
	check("inputs round-trip (buttons, slot, quantised aim, viewTime)", ok)

	local function bad(input: PlayerCodec.WireInput): boolean
		return PlayerCodec.decodeInputs(PlayerCodec.encodeInputs({ input }, 1, 1)) == nil
	end
	check("slot 0 is rejected", bad({ seq = 1, buttons = 0, slot = 0, yaw = 0, pitch = 0, viewTime = 0 }))
	check("slot 4 is rejected", bad({ seq = 1, buttons = 0, slot = 4, yaw = 0, pitch = 0, viewTime = 0 }))
	check("NaN viewTime is rejected", bad({ seq = 1, buttons = 0, slot = 1, yaw = 0, pitch = 0, viewTime = 0 / 0 }))
	check("truncated packets are rejected", PlayerCodec.decodeInputs(buffer.create(18)) == nil)
	check("non-buffers are rejected", PlayerCodec.decodeInputs("hello") == nil)
end

-- Scripted inputs that exercise movement and every weapon path.
local function inputAt(i: number): PlayerCodec.WireInput
	local pattern = { B.Fire + B.Right, B.Fire, B.Left, 0, B.Reload, B.Forward + B.Jump, B.AltFire, B.Fire + B.Crouch, B.Back + B.Walk }
	local slot = if (i // 300) % 3 == 2 then 2 else 1
	return {
		seq = i,
		buttons = pattern[(i // 17) % #pattern + 1],
		slot = slot,
		yaw = PlayerCodec.quantizeYaw(i * 0.004),
		pitch = PlayerCodec.quantizePitch(math.sin(i * 0.01) * 0.3),
		viewTime = i * DT,
	}
end

local function sameWeapons(a: WeaponSim.State, b: WeaponSim.State): boolean
	for slot = 1, 3 do
		if a.loadout[slot] ~= b.loadout[slot] or a.ammo[slot] ~= b.ammo[slot] or a.reserve[slot] ~= b.reserve[slot] then
			return false
		end
	end
	return a.equipped == b.equipped
		and a.equipEndTime == b.equipEndTime
		and a.nextFireTime == b.nextFireTime
		and a.reloadEndTime == b.reloadEndTime
		and a.scoped == b.scoped
		and a.fireHeld == b.fireHeld
		and a.altHeld == b.altHeld
		and a.lastShotTime == b.lastShotTime
		and a.sprayIndex == b.sprayIndex
		and a.shotCounter == b.shotCounter
		and a.seed == b.seed
		and a.recoilYaw == b.recoilYaw
		and a.swayDir == b.swayDir
end

do
	local s = PlayerSim.new(vector.create(0, 0.02, 0), nil, 3141592653)
	for i = 1, 400 do
		PlayerSim.step(s, inputAt(i), cfg, floor, DT)
	end
	PlayerSim.applyTag(s, cfg, 0.275, 0.15, DT)
	local seq, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(400, s))
	check("ack carries the seq", seq == 400)
	check("ack carries movement exactly", decoded.movement.position == s.movement.position and decoded.movement.velocity == s.movement.velocity and decoded.movement.tick == s.movement.tick)
	check("ack carries weapon state exactly", sameWeapons(decoded.weapons, s.weapons))
	check("ack carries the spray seed and drift (system 3)", decoded.weapons.seed == 3141592653 and decoded.weapons.recoilYaw == s.weapons.recoilYaw and decoded.weapons.swayDir == s.weapons.swayDir)
	check("ack carries the hit slow", decoded.tagUntilTick == s.tagUntilTick and decoded.tagMultiplier == s.tagMultiplier)

	-- Resume both from here: the original and the decoded copy must stay identical.
	local a, b = s, decoded :: PlayerSim.State
	local shotsA, shotsB = 0, 0
	local identical = true
	for i = 401, 1400 do
		local input = inputAt(i)
		local sa = PlayerSim.step(a, input, cfg, floor, DT)
		local sb = PlayerSim.step(b, input, cfg, floor, DT)
		shotsA += if sa then 1 else 0
		shotsB += if sb then 1 else 0
		if (sa == nil) ~= (sb == nil) or (sa and sb and (sa.origin ~= sb.origin or sa.direction ~= sb.direction or sa.time ~= sb.time)) then
			identical = false
		end
	end
	check("resuming from a decoded ack replays bit for bit", identical
		and a.movement.position == b.movement.position
		and a.movement.velocity == b.movement.velocity
		and sameWeapons(a.weapons, b.weapons)
		and shotsA == shotsB
		and shotsA > 5, string.format("%d vs %d shots", shotsA, shotsB))
end

do
	-- On a slope the ground move follows the floor's normal, so the ack must
	-- carry it or a client corrected on a ramp would replay on flat ground.
	local ramp = FakeWorld.new():addFloor():addPart(vector.create(18, math.sin(math.rad(30)) * 2.5, 6), vector.create(5, 0.2, 2), 0, 0, math.rad(30))
	local function uphill(i: number, buttons: number): PlayerCodec.WireInput
		return { seq = i, buttons = buttons, slot = 3, yaw = PlayerCodec.quantizeYaw(-math.pi / 2), pitch = 0, viewTime = i * DT }
	end
	local s = PlayerSim.new(vector.create(14, 0.02, 6), nil, 1)
	for i = 1, 60 do
		PlayerSim.step(s, uphill(i, B.Forward), cfg, ramp, DT)
	end
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(60, s))
	check("ack carries the ground normal exactly", s.movement.grounded and s.movement.groundNormal.y < 0.9 and decoded.movement.groundNormal == s.movement.groundNormal)
	-- Turning across the slope is what shows a wrong normal straight away.
	local a, b = s, decoded :: PlayerSim.State
	local identical = true
	for i = 61, 120 do
		PlayerSim.step(a, uphill(i, B.Forward + B.Left), cfg, ramp, DT)
		PlayerSim.step(b, uphill(i, B.Forward + B.Left), cfg, ramp, DT)
		identical = identical and a.movement.position == b.movement.position and a.movement.velocity == b.movement.velocity
	end
	check("resuming from an ack on a ramp replays bit for bit", identical and a.movement.position.y > 1)
end

do
	local poses: { PlayerCodec.Pose } = {
		{ id = PlayerCodec.DUMMY_BASE + 3, position = vector.create(1.23456, 0.5, -30.987), yaw = math.pi, pitch = -0.3, crouchAlpha = 0.37, grounded = true, alive = true },
		{ id = PlayerCodec.entityIdForUser(123456789012), position = vector.create(-5, 2, 7), yaw = 7.5, pitch = 0.1, crouchAlpha = 1, grounded = false, alive = true },
	}
	local time, decoded = PlayerCodec.decodeSnapshot(PlayerCodec.encodeSnapshot(987.25, poses))
	local ok = time == 987.25 and #decoded == 2
	for i, d in decoded do
		local q = PlayerCodec.quantizePose(poses[i])
		ok = ok and d.id == poses[i].id and d.position == q.position and d.yaw == q.yaw and d.pitch == q.pitch and d.crouchAlpha == q.crouchAlpha and d.grounded == q.grounded
	end
	check("snapshots decode to exactly the quantised poses the server keeps", ok)
	check("snapshot rounding stays under a millimetre", near(decoded[1].position.x, 1.23456, 1e-3) and near(decoded[1].position.z, -30.987, 1e-3))
	check("a snapshot fits an unreliable packet", PlayerCodec.SNAPSHOT_HEADER + PlayerCodec.SNAPSHOT_ENTRY * PlayerCodec.MAX_POSES_PER_SNAPSHOT <= 900)
end

do
	-- The server's input queue, fed by a client that samples 128 inputs a
	-- second and sends them in 60 Hz packets over an ordered network, and run
	-- by 60 Hz server frames.
	type Options = {
		rate: number?, -- inputs the client makes a second
		delay: ((number) -> number)?, -- network delay of a packet sent at this time
		stall: { number }?, -- the server runs no frames between these times
		hold: { number }?, -- packets sent between these times arrive at the second
		freeze: { number }?, -- the client runs no frames between these times
		frameCap: number?, -- the most seconds the client simulates in one frame
	}
	type Frame = { time: number, ran: number, waiting: number }
	type Result = { sent: number, ran: number, dropped: number, frames: { Frame }, queue: InputQueue.Queue<{ seq: number }> }

	-- The most the client simulates in one frame: the server's bank, as in
	-- PlayerController (MAX_FRAME_TIME). The rest of a longer frame is lost.
	local FRAME_CAP = InputQueue.MAX_BURST / MovementConfig.TickRate.value

	local function serve(seconds: number, opts: Options): Result
		local rate = opts.rate or MovementConfig.TickRate.value
		local cap = opts.frameCap or FRAME_CAP
		local packets: { { at: number, inputs: { { seq: number } } } } = {}
		local sent, lastArrival, lastFrame, lost = 0, 0, 0, 0
		for frame = 1, math.floor(seconds * 60) do
			local t = frame / 60
			if opts.freeze and t > opts.freeze[1] and t < opts.freeze[2] then
				continue
			end
			lost += math.max(t - lastFrame - cap, 0)
			lastFrame = t
			local batch = {}
			while sent < math.floor((t - lost) * rate) do
				sent += 1
				table.insert(batch, { seq = sent })
			end
			local arrival = t + (if opts.delay then opts.delay(t) else 0.03)
			if opts.hold and t >= opts.hold[1] and t < opts.hold[2] then
				arrival = math.max(arrival, opts.hold[2])
			end
			lastArrival = math.max(lastArrival, arrival) -- reliable events arrive in order
			table.insert(packets, { at = lastArrival, inputs = batch })
		end

		local q = InputQueue.new()
		local result: Result = { sent = sent, ran = 0, dropped = 0, frames = {}, queue = q }
		local nextPacket, last = 1, 0
		for frame = 1, math.floor(seconds * 60) do
			local t = frame / 60 + 0.004
			if opts.stall and t >= opts.stall[1] and t < opts.stall[2] then
				continue
			end
			while packets[nextPacket] and packets[nextPacket].at <= t do
				for _, input in packets[nextPacket].inputs do
					if InputQueue.push(q, input) then
						result.dropped += 1
					end
				end
				nextPacket += 1
			end
			InputQueue.refill(q, t - last)
			local ran = 0
			while InputQueue.take(q) do
				ran += 1
			end
			InputQueue.endFrame(q, t - last)
			last = t
			result.ran += ran
			table.insert(result.frames, { time = t, ran = ran, waiting = #q.inputs })
		end
		return result
	end

	-- The most inputs left waiting at the end of a frame after `from` seconds.
	local function backlog(r: Result, from: number): number
		local most = 0
		for _, f in r.frames do
			if f.time >= from then
				most = math.max(most, f.waiting)
			end
		end
		return most
	end

	local steady = serve(10, {})
	check(
		"a steady client's inputs run as they arrive",
		steady.dropped == 0 and steady.ran >= steady.sent - 6 and backlog(steady, 1) <= 1 and steady.queue.catchUp == InputQueue.CATCH_UP_MAX,
		string.format("ran %d of %d, backlog %d", steady.ran, steady.sent, backlog(steady, 1))
	)

	local seed = 7
	local jittery = serve(10, {
		delay = function()
			seed = (seed * 1103515245 + 12345) % 2 ^ 31
			return 0.02 + 0.1 * seed / 2 ^ 31
		end,
	})
	check(
		"network jitter up to 100 ms is absorbed without a catch-up",
		jittery.dropped == 0 and jittery.ran >= jittery.sent - 20 and jittery.queue.catchUp == InputQueue.CATCH_UP_MAX,
		string.format("ran %d of %d, catch-up left %.1f", jittery.ran, jittery.sent, jittery.queue.catchUp)
	)

	-- A half-second server stall (a script hogging the server, a screen
	-- capture in Studio) leaves more inputs queued than the bank covers.
	local stalled = serve(6, { stall = { 2, 2.5 } })
	check(
		"a backlog after a server stall drains within half a second",
		backlog(stalled, 3) <= InputQueue.DRAIN_TARGET and stalled.ran >= stalled.sent - stalled.dropped - 6,
		string.format("backlog %d after 3 s", backlog(stalled, 3))
	)
	local catchUp = InputQueue.CATCH_UP_MAX
	InputQueue.CATCH_UP_MAX = 0
	local undrained = serve(6, { stall = { 2, 2.5 } })
	InputQueue.CATCH_UP_MAX = catchUp
	check(
		"without the catch-up the same stall leaves the backlog for good",
		backlog(undrained, 3) >= 6,
		string.format("backlog %d after 3 s", backlog(undrained, 3))
	)

	local fast = serve(20, { rate = 1.1 * MovementConfig.TickRate.value })
	local allowed = 20 * MovementConfig.TickRate.value + InputQueue.MAX_BURST + InputQueue.CATCH_UP_MAX + 20 * InputQueue.CATCH_UP_RATE
	check(
		"a client sending 10% too many inputs still runs at real time",
		fast.ran <= allowed and fast.dropped > 0,
		string.format("ran %d, allowed %d, dropped %d", fast.ran, allowed, fast.dropped)
	)

	local held = serve(6, { hold = { 2, 2.5 } })
	local most = 0
	for _, f in held.frames do
		most = math.max(most, f.ran)
	end
	check(
		"held-back packets run at most a bank's worth in one frame",
		most <= InputQueue.MAX_BURST + 1 and backlog(held, 3.5) <= InputQueue.DRAIN_TARGET,
		string.format("%d in one frame", most)
	)

	-- A quarter-second client frame (a hitch while something loads). The
	-- client simulates only a bank's worth of it, so the server runs it all
	-- the moment it arrives.
	local hitch = serve(6, { freeze = { 2, 2.25 } })
	check(
		"a long client frame sends no more inputs than the server runs at once",
		hitch.dropped == 0 and backlog(hitch, 2.3) <= InputQueue.DRAIN_TARGET,
		string.format("dropped %d, backlog %d", hitch.dropped, backlog(hitch, 2.3))
	)
	-- In a Studio play test the server freezes with it (one process), and the
	-- inputs already on their way spend some of the bank, so a few wait and
	-- drain.
	local studioHitch = serve(6, { freeze = { 2, 2.25 }, stall = { 2, 2.25 } })
	check(
		"the same frame with the server frozen too drops nothing and drains",
		studioHitch.dropped == 0 and backlog(studioHitch, 2.75) <= InputQueue.DRAIN_TARGET,
		string.format("dropped %d, backlog %d after 2.75 s", studioHitch.dropped, backlog(studioHitch, 2.75))
	)
	-- Simulating the whole frame, as the client did with a 0.25 s cap, sends
	-- 27 inputs from a 217 ms frame: more than the queue keeps.
	local uncapped = serve(6, { freeze = { 2, 2.21 }, frameCap = 0.25 })
	check("simulating all of a 217 ms frame drops inputs", uncapped.dropped >= 3, string.format("dropped %d", uncapped.dropped))
end

do
	-- Studio's local test players (UserIds -1, -2, ...) must not read as dummies.
	local studioPlayers = PlayerCodec.isDummy(PlayerCodec.entityIdForUser(-1)) or PlayerCodec.isDummy(PlayerCodec.entityIdForUser(-2))
	check(
		"dummies and Studio's test players get separate entity ids",
		PlayerCodec.isDummy(PlayerCodec.DUMMY_BASE + 1)
			and PlayerCodec.isDummy(PlayerCodec.DUMMY_BASE + 17)
			and not studioPlayers
			and not PlayerCodec.isDummy(PlayerCodec.entityIdForUser(123456789))
	)
end

return nil
