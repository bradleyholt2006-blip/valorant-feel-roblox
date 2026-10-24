--!strict
-- Wire formats and reconciliation: what the server acks must be enough for
-- the client to resume the simulation bit for bit.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
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
	check("a snapshot fits an unreliable packet", 9 + 22 * PlayerCodec.MAX_POSES_PER_SNAPSHOT <= 900)
end

return nil
