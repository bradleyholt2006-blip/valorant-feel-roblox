--!strict
-- Jett's Drift (system 20): its numbers and where they come from, the glide
-- as PlayerSim steps it (from a jump, off a ledge, up an Updraft, pressed in
-- a fall and let go of, and a landing with jump held), what it leaves alone
-- (the rise, the speed along the ground, a dash, a lift, an agent without
-- it, the aim), and the wire carrying it.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local PoseHistory = require("../src/shared/Net/PoseHistory")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local JumpAnalyzer = require("../src/shared/Movement/JumpAnalyzer")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
-- A ledge 6 m up, its edge along z = 0 and the drop towards -Z, the way
-- Forward goes.
local LEDGE = 6
local ledge = FakeWorld.new():addFloor():addBox(vector.create(-20, 0, 0), vector.create(20, LEDGE, 40))
local D = AbilityConfig.Drift
local J = AbilityConfig.Jett
local GLIDE, BRAKE = D.fallSpeed.value, D.brake.value

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function horizontal(v: vector): vector
	return vector.create(v.x, 0, v.z)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

local function step(s: PlayerSim.State, buttons: number, world: any?, slot: number?, yaw: number?, pitch: number?)
	return PlayerSim.step(s, input(buttons, slot, yaw, pitch), cfg, world or floor, DT)
end

local function run(s: PlayerSim.State, buttons: number, n: number, world: any?)
	for _ = 1, n do
		step(s, buttons, world)
	end
end

-- A player settled with the Vandal in hand and a full kit, on the floor or,
-- with `world` the ledge, on top of it a metre from the edge.
local function newPlayer(world: any?): PlayerSim.State
	local y = if world == ledge then LEDGE + 0.02 else 0.02
	local s = PlayerSim.new(vector.create(0, y, if world == ledge then 1 else 0), { "vandal", "classic", "knife", "" })
	AbilitySim.fill(s.abilities, true)
	run(s, 0, 40, world)
	return s
end

-- Walks forward off the ledge, until the feet leave it.
local function walkOff(s: PlayerSim.State)
	for _ = 1, 200 do
		step(s, B.Forward, ledge)
		if not s.movement.grounded then
			return
		end
	end
end

-- A flight as the HUD's jump line measures it, holding `buttons` from the
-- tick it starts (`first` that tick, if given) until the feet are down
-- again: how long, how high the feet rose, the fastest fall, the ticks the
-- movement says it was gliding, and the ticks run (for a flight that was
-- under way already, which the jump line doesn't see start).
type Flight = { airtime: number, rise: number, fastest: number, glided: number, landed: boolean, steps: number }

local function fly(s: PlayerSim.State, buttons: number, world: any?, first: number?): Flight
	local analyzer = JumpAnalyzer.new()
	local function measure(): JumpAnalyzer.Jump?
		local m = s.movement
		return JumpAnalyzer.tick(analyzer, m.tick * DT, m.position, m.velocity, m.grounded, 0)
	end
	measure()
	step(s, first or buttons, world)
	measure()
	local fastest, glided, jump, steps = 0, 0, nil, 1
	for _ = 1, ticks(10) do
		step(s, buttons, world)
		steps += 1
		jump = measure() or jump
		fastest = math.min(fastest, s.movement.velocity.y)
		if s.movement.gliding then
			glided += 1
		end
		if s.movement.grounded then
			break
		end
	end
	return {
		airtime = if jump then jump.airtime else 0,
		rise = if jump then jump.rise else 0,
		fastest = fastest,
		glided = glided,
		landed = s.movement.grounded,
		steps = steps,
	}
end

-- A fall from `height` held to the glide: speeding up to it, then at it.
local function glideTime(height: number): number
	local reach = GLIDE / cfg.gravity
	return reach + (height - GLIDE * reach / 2) / GLIDE
end

H.section("Drift tests")

-- Its numbers -------------------------------------------------------------------------------

do
	check("Jett's passive is Drift", AbilityConfig.Agents.jett.passive == "drift")
	check("which her kit has", AbilitySim.hasPassive(AbilitySim.new(), "drift") and not AbilitySim.hasPassive(AbilitySim.new(), "other"))
	check("the glide's fall speed is 2 m/s, ours", GLIDE == 2 and D.fallSpeed.status == "estimate" and #D.fallSpeed.source > 0)
	check("and its brake 60 m/s each second, ours", BRAKE == 60 and D.brake.status == "estimate" and #D.brake.source > 0)
	local S = SoundConfig.Drift
	check(
		"its sound is a library sound, its timings labelled",
		SoundConfig.Sounds[S.sound] ~= nil
			and S.every.status == "estimate"
			and #S.every.source > 0
			and S.ownVolume.status == "estimate"
			and #S.ownVolume.source > 0
	)
	check("a gust comes before the last has faded, so they run together", S.every.value > 0 and S.every.value < 0.5)
end

-- From a jump ----------------------------------------------------------------------------------

do
	local plain = fly(newPlayer(), 0, nil, B.Jump)
	local s = newPlayer()
	local held = fly(s, B.Jump)
	check(
		"held, a jump rises as any jump does",
		near(held.rise, plain.rise, 1e-9) and held.rise > 0.8,
		string.format("%.3f m against %.3f m", held.rise, plain.rise)
	)
	check("and falls no faster than the glide", held.fastest == -GLIDE and plain.fastest < -4, string.format("%.3f m/s", held.fastest))
	local down = math.sqrt(2 * plain.rise / cfg.gravity)
	local want = plain.airtime - down + glideTime(plain.rise)
	check(
		"so it's in the air longer: about 0.81 s against 0.66 s",
		near(held.airtime, want, 0.02) and near(plain.airtime, 2 * down, 0.02),
		string.format("%.3f s against %.3f s (%.3f s wanted)", held.airtime, plain.airtime, want)
	)
	check("gliding most of the way down, and not rising", held.glided > ticks(0.3) and plain.glided == 0, tostring(held.glided))
	check("down, it isn't gliding", s.movement.grounded and not s.movement.gliding)
	run(s, B.Jump, 30)
	check("holding jump still, it doesn't jump again", s.movement.grounded and s.movement.velocity.y == 0)
	step(s, 0)
	step(s, B.Jump)
	check("letting go and pressing again jumps", not s.movement.grounded and s.movement.velocity.y > 0)
end

do
	-- Pressed only once it's up, it glides all the same.
	local s = newPlayer()
	step(s, B.Jump)
	run(s, 0, ticks(0.2))
	local f = fly(s, B.Jump)
	check("pressed in the air, a jump glides too", f.fastest == -GLIDE and f.glided > 0)
	check("and holding it as the feet land doesn't hop", f.landed and s.movement.velocity.y == 0)
	run(s, B.Jump, 30)
	check("however long it's held", s.movement.grounded)
end

do
	-- The speed along the ground is a fall's: the glide only slows the fall,
	-- so a running jump held carries further.
	local a, b = newPlayer(), newPlayer()
	run(a, B.Forward, ticks(1))
	run(b, B.Forward, ticks(1))
	step(a, B.Forward + B.Jump)
	step(b, B.Forward + B.Jump)
	local same = true
	while not a.movement.grounded do
		step(a, B.Forward)
		step(b, B.Forward + B.Jump)
		same = same and horizontal(a.movement.velocity) == horizontal(b.movement.velocity)
	end
	local start = b.movement.position
	run(b, B.Forward + B.Jump, ticks(2))
	check("the glide leaves the speed along the ground alone", same and b.movement.gliding == false)
	check(
		"so a running jump held lands further on",
		b.movement.grounded and b.movement.position.z < a.movement.position.z and vector.magnitude(b.movement.position - start) > 0
	)
end

-- Off a ledge ---------------------------------------------------------------------------------

do
	local plain = newPlayer(ledge)
	walkOff(plain)
	local fell = fly(plain, B.Forward, ledge)
	local s = newPlayer(ledge)
	walkOff(s)
	local f = fly(s, B.Forward + B.Jump, ledge)
	check("walking off a ledge with jump held glides down", f.fastest == -GLIDE and f.glided > ticks(2.5))
	local glided, dropped = f.steps * DT, fell.steps * DT
	check(
		"6 m in about 3.07 s, against 0.89 s",
		near(glided, glideTime(LEDGE), 0.03) and near(dropped, math.sqrt(2 * LEDGE / cfg.gravity), 0.03),
		string.format("%.3f s against %.3f s", glided, dropped)
	)
	check("landing on the floor below", f.landed and near(s.movement.position.y, 0, 0.01))
	run(s, B.Jump, 30)
	check("with jump still held, it doesn't hop", s.movement.grounded)
	step(s, 0)
	step(s, B.Jump)
	check("a fresh press jumps", not s.movement.grounded and s.movement.velocity.y > 0)
end

do
	-- Pressed in a fast fall, it brakes to the glide; let go, it falls again.
	local s = newPlayer(ledge)
	walkOff(s)
	run(s, 0, ticks(0.5), ledge)
	local v0 = s.movement.velocity.y
	step(s, B.Jump, ledge)
	local v1 = s.movement.velocity.y
	check(
		"pressed in a fall, the glide brakes it at 60 m/s each second",
		v0 < -6 and near(v1 - v0, BRAKE * DT, 1e-9),
		string.format("%.4f > %.4f", v0, v1)
	)
	check("gliding as it does", s.movement.gliding)
	local n = 1
	while s.movement.velocity.y < -GLIDE and n < 200 do
		step(s, B.Jump, ledge)
		n += 1
	end
	check(
		"down to the glide's speed, in the ticks the brake says",
		s.movement.velocity.y == -GLIDE and n == math.ceil((-v0 - GLIDE) / (BRAKE * DT)),
		string.format("%d ticks", n)
	)
	run(s, B.Jump, 10, ledge)
	check("and held there", s.movement.velocity.y == -GLIDE and s.movement.gliding)
	step(s, 0, ledge)
	check(
		"let go, it falls as before",
		near(s.movement.velocity.y, -GLIDE - cfg.gravity * DT, 1e-9) and not s.movement.gliding,
		string.format("%.4f m/s", s.movement.velocity.y)
	)
	step(s, B.Jump, ledge)
	check("held again, it glides again", s.movement.velocity.y == -GLIDE and s.movement.gliding)
end

-- Up an Updraft --------------------------------------------------------------------------------

do
	local plain = newPlayer()
	local lifted = fly(plain, 0, nil, B.AbilityQ)
	local s = newPlayer()
	local q = newPlayer()
	step(s, B.AbilityQ)
	step(q, B.AbilityQ)
	local same = true
	while AbilitySim.lifting(s.abilities, (s.movement.tick + 1) * DT) do
		step(s, B.Jump)
		step(q, 0)
		same = same and s.movement.position == q.movement.position and s.movement.velocity == q.movement.velocity
	end
	check("held through an Updraft, the lift is as it was", same and not s.movement.gliding)
	local f = fly(newPlayer(), B.Jump, nil, B.AbilityQ)
	check("and its top too", near(f.rise, J.updraftApex.value, 0.01) and near(f.rise, lifted.rise, 1e-9), string.format("%.3f m", f.rise))
	local want = lifted.airtime - math.sqrt(2 * J.updraftApex.value / cfg.gravity) + glideTime(J.updraftApex.value)
	check(
		"then it glides down from it: about 3 s in the air against 1.68 s",
		f.fastest == -GLIDE and near(f.airtime, want, 0.03) and near(lifted.airtime, 1.68, 0.02),
		string.format("%.3f s against %.3f s", f.airtime, lifted.airtime)
	)
	-- Q and jump down on the same tick, as VFTestButtons 8256 sets them.
	local both = fly(newPlayer(), B.AbilityQ + B.Jump)
	check(
		"Q and jump together lift rather than jump, then glide the same",
		near(both.rise, f.rise, 1e-9) and both.fastest == -GLIDE and near(both.airtime, f.airtime, 1e-9),
		string.format("%.3f m, %.3f s", both.rise, both.airtime)
	)
end

-- A dash, and Blade Storm ---------------------------------------------------------------------------

do
	local s = newPlayer()
	step(s, B.AbilityE)
	run(s, 0, ticks(J.windup.value) + 1)
	step(s, B.Jump)
	while not s.movement.gliding and not s.movement.grounded do
		step(s, B.Jump)
	end
	check("ready to dash, gliding", s.movement.gliding)
	local y = s.movement.position.y
	step(s, B.Jump + B.AbilityE)
	local level = true
	while AbilitySim.dashing(s.abilities, (s.movement.tick + 1) * DT) do
		step(s, B.Jump)
		level = level and s.movement.position.y == y and not s.movement.gliding
	end
	check("a dash in a glide flies level, not gliding", level and s.movement.velocity.y == 0)
	local again = false
	for _ = 1, ticks(0.5) do
		step(s, B.Jump)
		again = again or (s.movement.gliding and s.movement.velocity.y == -GLIDE)
	end
	check("and with jump held the glide takes up again after it", again)
end

do
	-- Guns are as inaccurate in a glide as in any fall; the knives are exact.
	local s = newPlayer()
	step(s, B.Jump)
	while not s.movement.gliding and not s.movement.grounded do
		step(s, B.Jump)
	end
	check("gliding, a gun's cone is the air's", PlayerSim.accuracyContext(s, B.Jump, cfg, DT).moveState == "air")

	local k = newPlayer()
	step(k, B.Ultimate)
	run(k, 0, ticks(AbilityConfig.BladeStorm.windup.value) + 1)
	check("Blade Storm's knives in hand", k.weapons.equipped == WeaponSim.ULT)
	step(k, B.Jump, nil, WeaponSim.ULT)
	while not k.movement.gliding and not k.movement.grounded do
		step(k, B.Jump, nil, WeaponSim.ULT)
	end
	local yaw, pitch = math.rad(-25), math.rad(-15)
	local shots = step(k, B.Jump + B.Fire, nil, WeaponSim.ULT, yaw, pitch)
	check(
		"a knife thrown in a glide is exact",
		k.movement.gliding and shots ~= nil and #shots == 1 and vector.magnitude(shots[1].direction - Accuracy.aim(yaw, pitch)) < 1e-5
	)
end

-- Without it -------------------------------------------------------------------------------------

do
	AbilityConfig.Agents.drifter = { id = "drifter", name = "Test", abilities = AbilityConfig.Agents.jett.abilities }
	local s = newPlayer()
	s.abilities.agent = "drifter"
	local f = fly(s, B.Jump)
	check("an agent without Drift falls as anyone does, jump held or not", f.fastest < -4 and f.glided == 0)
	AbilityConfig.Agents.drifter = nil
end

-- The wire -----------------------------------------------------------------------------------------

do
	local s = newPlayer(ledge)
	walkOff(s)
	run(s, B.Jump + B.Forward, ticks(0.5), ledge)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(3, s))
	check(
		"the ack carries the glide, and the jump held in the air",
		decoded.movement.gliding == true and decoded.movement.jumpLatched == true and s.movement.gliding
	)
	local copy = decoded :: PlayerSim.State
	local same = true
	for i = 1, ticks(5) do
		local buttons = if i < 200 or (i > 210 and i < 400) then B.Jump + B.Forward elseif i > 450 and i < 460 then B.Jump else 0
		step(s, buttons, ledge)
		step(copy, buttons, ledge)
		same = same
			and s.movement.position == copy.movement.position
			and s.movement.velocity == copy.movement.velocity
			and s.movement.gliding == copy.movement.gliding
	end
	check("and a replay from it glides bit for bit, through a landing and a jump", same and s.movement.grounded)
	local _, still = PlayerCodec.decodeAck(PlayerCodec.encodeAck(4, s))
	check("on the ground, the ack says it isn't gliding", still.movement.gliding == false)
end

do
	local function pose(gliding: boolean, channel: number): PlayerCodec.Pose
		return {
			id = 7,
			position = vector.create(1, 4, -2),
			yaw = 0.5,
			pitch = 0,
			crouchAlpha = 0,
			grounded = false,
			alive = true,
			quiet = true,
			reloading = true,
			weapon = 1,
			channel = channel,
			gliding = gliding,
		}
	end
	local _, decoded = PlayerCodec.decodeSnapshot(PlayerCodec.encodeSnapshot(5, { pose(true, 0), pose(false, 3), pose(true, 3) }))
	check(
		"a snapshot carries the glide, apart from the spike's channel beside it",
		decoded[1].gliding
			and decoded[1].channel == 0
			and not decoded[2].gliding
			and decoded[2].channel == 3
			and decoded[3].gliding
			and decoded[3].channel == 3
	)
	check("and the rest of the flags", decoded[3].quiet and decoded[3].reloading and decoded[3].alive and not decoded[3].grounded)
	check("as the server keeps it", PlayerCodec.quantizePose(pose(true, 1)).gliding == true)
	local h = PoseHistory.new()
	PoseHistory.push(h, 1, pose(false, 0))
	PoseHistory.push(h, 1.05, pose(true, 0))
	local between = PoseHistory.sample(h, 1.03)
	local before = PoseHistory.sample(h, 1)
	check(
		"drawn between snapshots, it's the newer one's",
		between ~= nil and between.pose.gliding and before ~= nil and not before.pose.gliding
	)
end

do
	local k = AbilitySim.new()
	AbilitySim.fill(k)
	check("the kit says so while gliding", AbilitySim.summary(k, 0, true) == "C2/2 Q1/1 E1/1 X0/8 glide", AbilitySim.summary(k, 0, true))
	check(
		"and not otherwise",
		AbilitySim.summary(k, 0, false) == "C2/2 Q1/1 E1/1 X0/8" and AbilitySim.summary(k, 0) == "C2/2 Q1/1 E1/1 X0/8"
	)
end

return nil
