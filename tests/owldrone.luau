--!strict
-- Sova's Owl Drone (system 47): its numbers and where they come from, the
-- drone in hand (C, then fire once it's drawn: a "drone" cast, from the eye
-- the way he faces), its flight (on as it was sent through its deploy, then
-- the keys fly it: along the ground the way the view faces, up with jump
-- and down with crouch, no higher over the floor than its ceiling, sinking
-- with no floor under it, stopped by walls), Sova held still while it
-- flies, its darts (fire, once the keys fly it: a "dart" cast from its
-- middle along the crosshair, no closer together than its cooldown), how
-- its flight ends (C again, its time up, broken, a death), the box shots
-- strike (DroneSim.level), its ids in the snapshots, and the wire carrying
-- it all so a replay comes back the same.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local DroneSim = require("../src/shared/Abilities/DroneSim")
local Penetration = require("../src/shared/Combat/Penetration")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Shop = require("../src/shared/Weapons/Shop")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local FakeLevel = require("./FakeLevel")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local DR = AbilityConfig.OwlDrone
local OWL = WeaponConfig.Defs.owl
local ULT = WeaponSim.ULT
local C = AbilityConfig.C
local SOVA = "sova"
local FEET = vector.create(0, 0.02, 0)
local AHEAD = vector.create(0, 0, -1)

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number, yaw: number, pitch: number)
	return { seq = 0, buttons = buttons, slot = slot, yaw = yaw, pitch = pitch, viewTime = 0 }
end

-- A player, the slot their client asks for, the way they look, and the
-- world.
type Player = { sim: PlayerSim.State, slot: number, yaw: number, pitch: number, world: any }

-- One tick with `buttons` held: its bullets and its casts.
local function step(p: Player, buttons: number): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	local w = p.sim.weapons
	if p.slot ~= ULT and w.loadout[p.slot] == "" then
		p.slot = w.equipped
	end
	local shots, _, _, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, p.yaw, p.pitch), cfg, p.world, DT)
	return shots or {}, casts or {}
end

-- `n` ticks with `buttons` held: every bullet and cast.
local function run(p: Player, buttons: number, n: number): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	local shots, casts = {}, {}
	for _ = 1, n do
		local s, c = step(p, buttons)
		for _, shot in s do
			table.insert(shots, shot)
		end
		for _, cast in c do
			table.insert(casts, cast)
		end
	end
	return shots, casts
end

local function ofKind(casts: { AbilitySim.Cast }, kind: string): { AbilitySim.Cast }
	local out = {}
	for _, cast in casts do
		if cast.kind == kind then
			table.insert(out, cast)
		end
	end
	return out
end

local function now(p: Player): number
	return p.sim.movement.tick * DT
end

-- Sova settled at FEET in `world` (the floor without), the Vandal drawn,
-- his kit full.
local function newPlayer(world: any?): Player
	local sim = PlayerSim.new(FEET, { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(SOVA)
	AbilitySim.fill(sim.abilities)
	local p: Player = { sim = sim, slot = 1, yaw = 0, pitch = 0, world = world or floor }
	run(p, 0, ticks(1.5))
	return p
end

-- C tapped, its draw waited out, and fire tapped: the drone sent out, and
-- its "drone" cast.
local function sent(world: any?): (Player, AbilitySim.Cast?)
	local p = newPlayer(world)
	step(p, B.AbilityC)
	run(p, 0, ticks(OWL.equipTime.value))
	local _, casts = step(p, B.Fire)
	return p, ofKind(casts, "drone")[1]
end

-- Sent out, and its deploy waited out: the keys fly it.
local function flying(world: any?): Player
	local p = sent(world)
	run(p, 0, ticks(DR.deploy.value))
	return p
end

H.section("Owl Drone tests")

-- Its numbers ------------------------------------------------------------------------------------

do
	local labelled = true
	for _, param in DR do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Owl Drone number says where it's from", labelled)
	local def = AbilityConfig.Defs.owldrone
	check(
		"Sova's C: 400 credits (Patch 3.0), one charge, the drone in hand, played",
		def.slot == C
			and def.kind == "basic"
			and def.cost ~= nil
			and def.cost.value == 400
			and def.charges ~= nil
			and def.charges.value == 1
			and def.weapon == "owl"
			and AbilitySim.playable("owldrone")
	)
	check(
		"Riot's: 7 s, 100 health, two pings, the first 1.6 s after a dart strikes and the next 1.2 s on, '[Target Hit]' for 2 s",
		DR.duration.value == 7
			and DR.health.value == 100
			and DR.pings.value == 2
			and DR.firstPing.value == 1.6
			and DR.pingEvery.value == 1.2
			and DR.hitText.value == 2
			and DR.duration.status == "confirmed"
			and DR.health.status == "confirmed"
			and DR.pings.status == "confirmed"
			and DR.firstPing.status == "confirmed"
			and DR.pingEvery.status == "confirmed"
			and DR.hitText.status == "confirmed"
	)
	check(
		"the wiki's and the guides': its deploy 0.25 s, the gun back 0.7 s after, a dart every 5 s, each ping's reveal 0.6 s",
		DR.deploy.value == 0.25
			and DR.unequip.value == 0.7
			and DR.dartCooldown.value == 5
			and DR.reveal.value == 0.6
			and DR.deploy.status == "community"
			and DR.unequip.status == "community"
			and DR.dartCooldown.status == "community"
			and DR.reveal.status == "community"
			and near(AbilityConfig.unequip("owldrone"), 0.7, 1e-12)
	)
	check(
		"ours: 5 m/s along, 3 m/s up or down, a 0.4 m by 0.25 m box, 3 m over the floor at most, darts 40 m, heard 15 m off",
		DR.speed.value == 5
			and DR.climb.value == 3
			and DR.accel.value == 20
			and DR.width.value == 0.4
			and DR.height.value == 0.25
			and DR.ceiling.value == 3
			and DR.depth.value == 20
			and DR.dartRange.value == 40
			and DR.heard.value == 15
			and DR.speed.status == "estimate"
			and DR.dartRange.status == "estimate"
			and DR.heard.status == "estimate"
	)
	check(
		"the drone in hand, an ability's weapon of the fifth slot: one drone, drawn over 0.9 s (the guides)",
		OWL.category == "ability"
			and OWL.slot == ULT
			and OWL.ability == "owldrone"
			and OWL.fireMode == "semi"
			and OWL.magazine.value == 1
			and OWL.reserve.value == 0
			and OWL.equipTime.value == 0.9
			and OWL.equipTime.status == "community"
			and OWL.name == "Owl Drone"
	)
	local item = Shop.item("owldrone")
	check(
		"its charge is sold, on C for 400; the drone in hand isn't",
		item ~= nil and item.kind == "ability" and item.price == 400 and item.slot == "C" and Shop.item("owl") == nil
	)
	check(
		"its sounds: in hand, sent out, its hum, a dart, one striking, a ping, broken",
		SoundConfig.Weapons.owl ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.drone] ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.dronehum] ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.dartshot] ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.darthit] ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.dartping] ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.dronebreak] ~= nil
	)
	check(
		"a dart and a landing make no sound of their own as casts: its view plays the dart's where the drone is",
		SoundConfig.Abilities.dart == nil and SoundConfig.Abilities.land == nil
	)
end

-- In hand, and sent out ---------------------------------------------------------------------------

do
	local p = newPlayer()
	local w, kit = p.sim.weapons, p.sim.abilities
	check("his C charge there", kit.charges[C] == 1)
	step(p, B.AbilityC)
	check("C puts the drone in hand", kit.holding == C and w.equipped == ULT and w.loadout[ULT] == "owl")
	local shots, early = run(p, B.Fire, ticks(OWL.equipTime.value) - 2)
	check("fire through its draw sends nothing", #shots == 0 and #ofKind(early, "drone") == 0 and kit.droneFrom == 0)
	run(p, 0, 4)
	local eye = PlayerSim.eye(p.sim, cfg)
	p.yaw, p.pitch = 0.5, -0.2
	local fired, casts = step(p, B.Fire)
	local cast = ofKind(casts, "drone")[1]
	local t = now(p)
	check('fire once it\'s drawn sends it out: a "drone" cast, no bullet', cast ~= nil and cast.ability == "owldrone" and #fired == 0)
	check("its charge spent, and nothing in hand", kit.charges[C] == 0 and kit.holding == 0 and w.loadout[ULT] == "")
	check(
		"from his eye, level, the way he faces, at its speed",
		AbilitySim.droning(kit)
			and kit.droneFrom == t
			and kit.dronePos == eye
			and near(kit.droneVel.x, -math.sin(0.5) * DR.speed.value, 1e-5)
			and kit.droneVel.y == 0
			and near(kit.droneVel.z, -math.cos(0.5) * DR.speed.value, 1e-5)
	)
	check("his body keeps the way he faced and looked", kit.bodyYaw == 0.5 and kit.bodyPitch == -0.2)
	check(
		"under way, as the kit says, with its seconds left",
		AbilitySim.busy(kit, t) and string.find(AbilitySim.summary(kit, t), "drone 7.0", 1, true) ~= nil,
		AbilitySim.summary(kit, t)
	)
	check("its first dart can go once its deploy's over", near(kit.dartAt, t + DR.deploy.value, 1e-9))
end

-- Its flight -------------------------------------------------------------------------------------

do
	local p = sent()
	local kit = p.sim.abilities
	local from = kit.dronePos
	-- Back and up through its deploy: the keys don't fly it yet.
	run(p, B.Back + B.Jump, ticks(DR.deploy.value) - 1)
	local t = now(p)
	check(
		"through its deploy it flies on as it was sent",
		not AbilitySim.piloting(kit, t) and kit.droneVel == vector.create(0, 0, -DR.speed.value)
	)
	check(
		"level, ahead, at its speed",
		near(kit.dronePos.y, from.y, 1e-5) and near(from.z - kit.dronePos.z, (ticks(DR.deploy.value) - 1) * DT * DR.speed.value, 1e-4),
		string.format("%.4f m", from.z - kit.dronePos.z)
	)
	step(p, 0)
	check("then the keys fly it", AbilitySim.piloting(kit, now(p)))
	run(p, 0, ticks(0.5))
	check("with none held it comes to a stop", kit.droneVel == vector.zero)
	local before = kit.dronePos
	p.yaw = math.pi / 2
	run(p, B.Forward, ticks(1))
	local moved = kit.dronePos - before
	check(
		"forward goes the way the view faces, at its speed once it's got there",
		near(kit.droneVel.x, -DR.speed.value, 1e-4) and math.abs(kit.droneVel.z) < 1e-4 and moved.x < -4 and math.abs(moved.z) < 1e-3,
		string.format("%.3f, %.3f", moved.x, moved.z)
	)
	run(p, 0, ticks(0.5))
	local low = kit.dronePos.y
	run(p, B.Jump, ticks(0.25))
	check("jump flies it up", kit.dronePos.y > low + 0.3 and near(kit.droneVel.y, DR.climb.value, 1e-4))
	run(p, B.Jump, ticks(1.5))
	check(
		"no higher over the floor than its ceiling",
		near(kit.dronePos.y, DR.ceiling.value, 0.01) and DroneSim.over(floor, kit.dronePos) <= DR.ceiling.value + 0.01,
		string.format("%.3f m", kit.dronePos.y)
	)
	run(p, B.Crouch, ticks(0.5))
	check("crouch flies it down", kit.dronePos.y < DR.ceiling.value - 0.8 and near(kit.droneVel.y, -DR.climb.value, 1e-4))
	run(p, B.Crouch, ticks(2))
	check("down to the floor and no further", kit.dronePos.y >= DroneSim.half().y - 1e-3 and kit.dronePos.y < 0.2)
end

do
	-- A wall 4 m ahead, 5 m high.
	local walled = FakeWorld.new():addFloor():addBox(vector.create(-5, 0, -4.5), vector.create(5, 5, -4))
	local p = flying(walled)
	local kit = p.sim.abilities
	run(p, B.Forward, ticks(2))
	check(
		"a wall stops it, its box against it",
		kit.dronePos.z > -4 + DroneSim.half().z - 0.01 and kit.dronePos.z < -4 + DroneSim.half().z + 0.05,
		string.format("%.4f m", kit.dronePos.z)
	)
	run(p, B.Forward + B.Left, ticks(1))
	check("and along it, it slides", kit.dronePos.x < -2 and kit.dronePos.z > -4, string.format("%.3f m", kit.dronePos.x))
end

do
	-- A floor that ends 5 m ahead, with nothing under past it.
	local edge = FakeWorld.new():addBox(vector.create(-50, -1, -5), vector.create(50, 0, 50))
	local p = flying(edge)
	local kit = p.sim.abilities
	local high = kit.dronePos.y
	run(p, B.Forward, ticks(0.5))
	check("over the floor it holds its height", near(kit.dronePos.y, high, 1e-4))
	run(p, B.Forward + B.Jump, ticks(1.5))
	check(
		"past where it ends, with no floor within its depth, it sinks at its climb, jump or not",
		kit.dronePos.z < -5 and near(kit.droneVel.y, -DR.climb.value, 1e-4) and kit.dronePos.y < high,
		string.format("%.3f m", kit.dronePos.y)
	)
end

-- Sova while it flies ----------------------------------------------------------------------------

do
	local p = flying()
	local m, w, kit = p.sim.movement, p.sim.weapons, p.sim.abilities
	local feet = m.position
	local shots = run(p, B.Forward + B.Crouch + B.Fire, ticks(1))
	check("the keys move him nowhere, and fire shoots no gun", m.position == feet and #shots == 0)
	check("he doesn't crouch, as he wasn't", not m.crouched)
	local t = now(p)
	check("his gun's away until its unequip after the flight", w.equipEndTime >= t + DR.unequip.value - 1e-9)
	local _, casts = run(p, B.AbilityQ, 2)
	check("Q starts nothing while it flies", #casts == 0 and kit.charges[AbilityConfig.Q] == 2 and kit.holding == 0)
end

do
	local p = newPlayer()
	run(p, B.Crouch, ticks(0.5))
	step(p, B.Crouch + B.AbilityC)
	run(p, B.Crouch, ticks(OWL.equipTime.value))
	step(p, B.Crouch + B.Fire)
	run(p, 0, ticks(1))
	check("crouched as he sent it, he stays crouched", p.sim.movement.crouched and AbilitySim.droning(p.sim.abilities))
end

-- Its darts --------------------------------------------------------------------------------------

do
	local p = sent()
	local kit = p.sim.abilities
	local _, early = run(p, 0, 2)
	local _, pressed = step(p, B.Fire)
	check("fire through its deploy shoots nothing", #ofKind(early, "dart") == 0 and #ofKind(pressed, "dart") == 0)
	run(p, 0, ticks(DR.deploy.value))
	p.yaw, p.pitch = -0.3, -0.4
	local _, casts = step(p, B.Fire)
	local dart = ofKind(casts, "dart")[1]
	local t = now(p)
	check(
		"fire, once the keys fly it, shoots a dart from its middle along the crosshair",
		dart ~= nil and dart.ability == "owldrone" and dart.origin == kit.dronePos and dart.direction == Accuracy.aim(-0.3, -0.4)
	)
	check("the next can go its cooldown on", near(kit.dartAt, t + DR.dartCooldown.value, 1e-9))
	local _, held = run(p, B.Fire, ticks(1))
	local _, again = run(p, 0, 1)
	local _, soon = step(p, B.Fire)
	check("held, or pressed again too soon, nothing", #ofKind(held, "dart") == 0 and #again == 0 and #ofKind(soon, "dart") == 0)
	run(p, 0, ticks(DR.dartCooldown.value - 1))
	local _, later = step(p, B.Fire)
	check("pressed once its cooldown's over, another", #ofKind(later, "dart") == 1)
end

-- How its flight ends ----------------------------------------------------------------------------

do
	local p = flying()
	local w, kit = p.sim.weapons, p.sim.abilities
	run(p, B.Forward, ticks(1))
	local last = kit.dronePos
	p.yaw = 2
	local _, casts = step(p, B.AbilityC)
	local land = ofKind(casts, "land")[1]
	local t = now(p)
	check(
		'C again ends it: a "land" cast from where it was, the way his body faces',
		land ~= nil
			and land.ability == "owldrone"
			and land.origin == last
			and near(land.direction.x, 0, 1e-6)
			and near(land.direction.z, -1, 1e-6)
	)
	check("its flight over as of then", not AbilitySim.droning(kit) and kit.landAt == t and kit.droneVel == vector.zero)
	check("the gun back its unequip after", near(w.equipEndTime, t + DR.unequip.value, 1e-9) and w.equipped == 1)
	check("just over, as the kit says", AbilitySim.landing(kit, t) and not AbilitySim.landing(kit, t + DR.unequip.value))
	local _, after = run(p, B.AbilityC, 3)
	check("C still held casts nothing, and with no charge left, C again does nothing", #after == 0 and kit.holding == 0)
end

do
	local p = sent()
	local kit = p.sim.abilities
	local from = kit.droneFrom
	local _, casts = run(p, B.Forward, ticks(DR.duration.value) + 2)
	local land = ofKind(casts, "land")[1]
	check(
		"its time up, its flight's over: 7 s from when it was sent",
		land ~= nil and #ofKind(casts, "land") == 1 and near(land.time, from + DR.duration.value, 1e-9),
		if land then string.format("%.4f s", land.time - from) else "none"
	)
end

do
	local p = newPlayer()
	p.sim.abilities.charges[AbilityConfig.Q] = 2
	step(p, B.AbilityC)
	run(p, 0, ticks(OWL.equipTime.value))
	step(p, B.Fire)
	run(p, B.AbilityQ, ticks(DR.deploy.value))
	local _, casts = run(p, B.AbilityQ + B.AbilityC, 1)
	local _, after = run(p, B.AbilityQ, 3)
	check(
		"a key held as it ends doesn't cast: Q, held from while it flew",
		#ofKind(casts, "land") == 1 and #after == 0 and p.sim.abilities.holding == 0
	)
end

do
	local p = flying()
	local w, kit = p.sim.weapons, p.sim.abilities
	run(p, B.Jump, ticks(0.5))
	local at = kit.dronePos
	local t = now(p)
	local land = PlayerSim.downed(p.sim, t)
	check(
		"broken between ticks (the server's), its flight's over as of his last tick, from where it was",
		land ~= nil and land.kind == "land" and land.origin == at and kit.landAt == t and not AbilitySim.droning(kit)
	)
	check("and the gun's back its unequip after", near(w.equipEndTime, t + DR.unequip.value, 1e-9))
	check("broken again, nothing", PlayerSim.downed(p.sim, t) == nil)
	local feet = p.sim.movement.position
	run(p, B.Forward, ticks(0.5))
	check("after, the keys move him again", p.sim.movement.position ~= feet)
end

do
	local p = flying()
	local kit = p.sim.abilities
	AbilitySim.settle(kit)
	check(
		"a death or a new round ends it all",
		kit.droneFrom == 0 and kit.landAt == 0 and kit.dartAt == 0 and kit.dronePos == vector.zero and kit.droneVel == vector.zero
	)
end

-- The box shots strike ---------------------------------------------------------------------------

do
	local base = FakeLevel.new()
	local drones: { DroneSim.Posed } = { { id = PlayerCodec.DRONE_BASE + 1, position = vector.create(0, 1.5, -10) } }
	local level = DroneSim.level(base, drones)
	local trace = Penetration.trace(level, vector.create(0, 1.5, 0), AHEAD, "high", WeaponConfig.MaxRange)
	local first = trace.walls[1]
	check(
		"a drone stops a bullet at its box, 0.2 m short of its middle",
		trace.stopped and near(trace.stop, 9.8, 1e-4) and first ~= nil and first.material == "solid" and first.name == DroneSim.SURFACE,
		string.format("%.4f m", trace.stop)
	)
	local piece = if first then DroneSim.piece(first.key) else nil
	check("and what it struck is that drone", piece ~= nil and piece.id == PlayerCodec.DRONE_BASE + 1)
	local over = Penetration.trace(level, vector.create(0, 1.7, 0), AHEAD, "high", WeaponConfig.MaxRange)
	local under = Penetration.trace(level, vector.create(0, 1.36, 0), AHEAD, "high", WeaponConfig.MaxRange)
	check("0.25 m high: one over it or under it goes on", not over.stopped and not under.stopped)
	check(
		"one of its own darts, from inside it, doesn't strike it, nor with it left out",
		not Penetration.trace(level, vector.create(0, 1.5, -10), AHEAD, "none", 40).stopped
			and DroneSim.level(base, drones, PlayerCodec.DRONE_BASE + 1) == base
	)
	check("with none, the level's the level alone", DroneSim.level(base, {}) == base)
	check("nothing else is a drone's", DroneSim.piece(nil) == nil and DroneSim.piece({ drone = false }) == nil)
	check(
		"its box square to the world, its middle where it is",
		DroneSim.box(vector.create(1, 2, 3)).center == vector.create(1, 2, 3) and DroneSim.half() == vector.create(0.2, 0.125, 0.2)
	)
end

-- Its ids ----------------------------------------------------------------------------------------

do
	local first, last = PlayerCodec.DRONE_BASE + 1, PlayerCodec.DRONE_BASE + PlayerCodec.DRONE_LIMIT
	check(
		"a drone's id in the snapshots is its own, below the dummies' and above anyone's but Studio's test players",
		PlayerCodec.isDrone(first)
			and PlayerCodec.isDrone(last)
			and not PlayerCodec.isDrone(PlayerCodec.DRONE_BASE)
			and not PlayerCodec.isDrone(last + 1)
			and not PlayerCodec.isDummy(first)
			and not PlayerCodec.isDummy(last)
			and last < PlayerCodec.DUMMY_BASE
			and not PlayerCodec.isDrone(PlayerCodec.entityIdForUser(-1))
	)
	local pose: PlayerCodec.Pose = {
		id = first,
		position = vector.create(3.25, 2.5, -7.75),
		yaw = 1,
		pitch = -0.5,
		crouchAlpha = 0,
		grounded = false,
		alive = true,
		quiet = true,
		reloading = false,
		weapon = 0,
		channel = 0,
		gliding = false,
	}
	local _, poses = PlayerCodec.decodeSnapshot(PlayerCodec.encodeSnapshot(10, { pose }))
	local back = poses[1]
	check(
		"and the snapshots carry it with its middle and the way it looks",
		back ~= nil
			and back.id == first
			and vector.magnitude(back.position - pose.position) < 0.01
			and near(back.yaw, 1, 0.01)
			and near(back.pitch, -0.5, 0.01)
	)
end

-- The wire ---------------------------------------------------------------------------------------

do
	local p = flying()
	run(p, B.Forward + B.Jump, ticks(0.5))
	step(p, B.Fire)
	run(p, B.Forward, 5)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a, b = p.sim.abilities, decoded.abilities
	check(
		"the ack carries its flight: when it was sent, where it is, how it's moving, its next dart and his body's look",
		b.droneFrom == a.droneFrom
			and b.landAt == a.landAt
			and b.dronePos == a.dronePos
			and b.droneVel == a.droneVel
			and b.dartAt == a.dartAt
			and b.bodyYaw == a.bodyYaw
			and b.bodyPitch == a.bodyPitch
			and a.droneFrom > 0
			and a.dartAt > now(p)
	)
	local copy: Player = { sim = decoded :: PlayerSim.State, slot = p.slot, yaw = 0, pitch = 0, world = floor }
	local same = true
	local keys = { B.Forward, B.Forward + B.Right, B.Jump, 0, B.Crouch + B.Left, B.Back }
	for i = 1, ticks(2) do
		local buttons = keys[i % #keys + 1]
		local _, c1 = step(p, buttons)
		local _, c2 = step(copy, buttons)
		same = same and #c1 == #c2 and p.sim.abilities.dronePos == copy.sim.abilities.dronePos
	end
	check("and a replay from it flies the drone the same", same)
	local _, c1 = run(p, B.AbilityC, 1)
	local _, c2 = run(copy, B.AbilityC, 1)
	local x, y = ofKind(c1, "land")[1], ofKind(c2, "land")[1]
	check("and ends it the same", x ~= nil and y ~= nil and x.origin == y.origin and p.sim.abilities.landAt == copy.sim.abilities.landAt)
	local _, landed = PlayerCodec.decodeAck(PlayerCodec.encodeAck(10, p.sim))
	check(
		"the ack carries its end, for the gun's return",
		landed.abilities.landAt == p.sim.abilities.landAt and landed.abilities.landAt > 0
	)
end

return nil
