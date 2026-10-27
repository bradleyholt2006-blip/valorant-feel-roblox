--!strict
-- Sova's Recon Bolt (system 44): its numbers and where they come from, his
-- kit, his bow in hand (E with its charge, its equip, E again putting it
-- away), the draw (fire held once it's ready, a bar each third of a second,
-- three at the most), its bounces (alt fire pressed, two at the most, then
-- none again), the loose (fire let go: its charge spent, the gun back in
-- hand 0.7 s on, a "bolt" cast with its bars and bounces), E letting a draw
-- go, the bolt's flight (as fast and falling as its bars say, off walls
-- while it has bounces, sticking to what it meets next, or given up on),
-- its pulses and whom they reveal, its shaft in the level shots are traced
-- through, a new life ending a draw, and the wire carrying it all so a
-- replay comes back the same.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local BoltSim = require("../src/shared/Abilities/BoltSim")
local FireballSim = require("../src/shared/Abilities/FireballSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Shop = require("../src/shared/Weapons/Shop")
local Penetration = require("../src/shared/Combat/Penetration")
local Sight = require("../src/shared/Combat/Sight")
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
local RC = AbilityConfig.ReconBolt
local BOW = WeaponConfig.Defs.bow
local ULT = WeaponSim.ULT
local E = AbilityConfig.E
local SOVA = "sova"
local FEET = vector.create(0, 0.02, 0)
local EYE = vector.create(0, 1.6, 0)
local AHEAD = vector.create(0, 0, -1)
local SIZE = RC.size.value

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = 0, pitch = 0, viewTime = 0 }
end

-- A player, the slot their client asks for, and the world.
type Player = { sim: PlayerSim.State, slot: number, world: any }

-- The slot the client asks for this tick, by PlayerController's rules.
local function ask(s: PlayerSim.State, slot: number): number
	local w = s.weapons
	if slot ~= ULT and w.loadout[slot] == "" then
		slot = w.equipped
	end
	if w.equipped == ULT and w.hold ~= 0 and slot == w.hold then
		slot = ULT
	end
	return slot
end

-- One tick with `buttons` held: its bullets and its casts.
local function step(p: Player, buttons: number): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	p.slot = ask(p.sim, p.slot)
	local shots, _, _, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot), cfg, p.world, DT)
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

-- Sova settled at FEET, the Vandal drawn, his kit full.
local function newPlayer(): Player
	local sim = PlayerSim.new(FEET, { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(SOVA)
	AbilitySim.fill(sim.abilities, true)
	local p: Player = { sim = sim, slot = 1, world = floor }
	run(p, 0, ticks(1.5))
	return p
end

-- E tapped, and the bow's equip waited out.
local function inHand(): Player
	local p = newPlayer()
	step(p, B.AbilityE)
	run(p, 0, ticks(BOW.equipTime.value) + 1)
	return p
end

-- Fire held `seconds` and let go: the bolt loosed, if any.
local function loose(p: Player, seconds: number): AbilitySim.Cast?
	run(p, B.Fire, ticks(seconds))
	local _, casts = step(p, 0)
	return ofKind(casts, "bolt")[1]
end

-- Walls across the way ahead and behind, their faces `far` metres off,
-- 10 m tall, on a floor.
local function hall(far: number): any
	return FakeWorld.new()
		:addFloor()
		:addBox(vector.create(-10, 0, -far - 1), vector.create(10, 10, -far))
		:addBox(vector.create(-10, 0, far), vector.create(10, 10, far + 1))
end

H.section("Recon Bolt tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	local function label(param: any)
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	for _, param: any in RC do
		if param.value ~= nil then
			label(param)
		else
			for _, each in param do
				label(each)
			end
		end
	end
	check("every Recon Bolt number says where it's from", labelled)
	local def = AbilityConfig.Defs.reconbolt
	local recharge = def.recharge
	check(
		"Sova's E, his signature: 1 charge, free each round, back 50 s after it's used (Patch 13.00), the bow in hand, played",
		def.slot == E
			and def.kind == "signature"
			and def.charges ~= nil
			and def.charges.value == 1
			and def.free == 1
			and recharge ~= nil
			and recharge.kind == "cooldown"
			and recharge.seconds.value == 50
			and recharge.seconds.status == "confirmed"
			and string.find(recharge.seconds.source, "60s to 50s", 1, true) ~= nil
			and def.weapon == "bow"
			and AbilitySim.playable("reconbolt")
	)
	check("in Team Deathmatch, back 48 s after it's used (the wiki)", AbilityConfig.TeamDeathmatch.cooldowns.reconbolt.value == 48)
	local sova = AbilityConfig.Agents.sova
	check(
		"Sova, an Initiator (Riot): his Owl Drone, Shock Bolt, Recon Bolt and Hunter's Fury, the fifth agent on the wire",
		sova ~= nil
			and sova.role == "Initiator"
			and table.concat(sova.abilities, ",") == "owldrone,shockbolt,reconbolt,huntersfury"
			and AbilityConfig.AgentIds[5] == "sova"
			and AbilityConfig.AgentIndex.sova == 5
	)
	check("his Owl Drone and Hunter's Fury don't play yet", not AbilitySim.playable("owldrone") and not AbilitySim.playable("huntersfury"))
	local owl, shock, fury = AbilityConfig.Defs.owldrone, AbilityConfig.Defs.shockbolt, AbilityConfig.Defs.huntersfury
	check(
		"the rest of his kit as Patch 3.0 has it: the Owl Drone 400, the Shock Bolt 150, Hunter's Fury 8 points",
		owl.cost ~= nil
			and owl.cost.value == 400
			and shock.cost ~= nil
			and shock.cost.value == 150
			and fury.points ~= nil
			and fury.points.value == 8
			and owl.weapon == nil
			and fury.weapon == nil
	)
	check(
		"its bow, a weapon of the fifth slot that fires nothing and is never reloaded, drawn in 0.8 s (the wiki's game files)",
		BOW.category == "ability"
			and BOW.slot == ULT
			and BOW.ability == "reconbolt"
			and BOW.fireMode == "none"
			and BOW.magazine.value == 1
			and BOW.reserve.value == 0
			and BOW.equipTime.value == 0.8
			and BOW.name == "Recon Bolt"
	)
	check("neither it nor its bow is sold", Shop.item("reconbolt") == nil and Shop.item("bow") == nil)
	check("the gun back in hand 0.7 s after it's loosed (the wiki's game files)", near(AbilityConfig.unequip("reconbolt"), 0.7, 1e-12))
	check(
		"Riot's: up to two bounces (its page for Sova), two pulses (Patch 7.04) and 20 health (Patch 5.12)",
		RC.bounces.value == 2
			and RC.bounces.status == "confirmed"
			and RC.pulses.value == 2
			and RC.pulses.status == "confirmed"
			and RC.health.value == 20
			and RC.health.status == "confirmed"
	)
	check(
		"the wiki's: a bar each third of a second, three of them, a 0.667 s windup, a pulse every 1.6 s out to 30 m, each"
			.. " reveal 0.75 s, and 3.2 s from the first pulse",
		near(RC.bar.value, 1 / 3, 1e-12)
			and RC.bars.value == 3
			and RC.windup.value == 0.667
			and RC.interval.value == 1.6
			and RC.radius.value == 30
			and RC.reveal.value == 0.75
			and RC.duration.value == 3.2
	)
	local speeds, gravities = {}, {}
	for i = 1, 4 do
		table.insert(speeds, tostring(RC.speed[i].value))
		table.insert(gravities, tostring(RC.gravity[i].value))
	end
	check(
		"its flights, the wiki's projectile classes 2 to 5: 18, 29, 41.25 and 41.25 m/s, at 0.3, 0.45, 0.3 and 0.15 of the"
			.. " world's gravity",
		table.concat(speeds, ",") == "18,29,41.25,41.25" and table.concat(gravities, ",") == "0.3,0.45,0.3,0.15",
		table.concat(speeds, ",") .. "; " .. table.concat(gravities, ",")
	)
	check(
		"both its pulses before its time's up",
		RC.windup.value + (RC.pulses.value - 1) * RC.interval.value < RC.windup.value + RC.duration.value
	)
	check(
		"its sounds: the bow drawn, its string drawn back, the loose, the flight, sticking, each pulse and breaking",
		SoundConfig.Weapons.bow ~= nil
			and SoundConfig.Abilities.bolt ~= nil
			and SoundConfig.Abilities.nock ~= nil
			and SoundConfig.Abilities.boltflight ~= nil
			and SoundConfig.Abilities.boltstick ~= nil
			and SoundConfig.Abilities.pulse ~= nil
			and SoundConfig.Abilities.boltbreak ~= nil
	)
end

-- The bow in hand -----------------------------------------------------------------------------

do
	local p = newPlayer()
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"his kit filled: the Recon Bolt's charge, and nothing of what doesn't play yet",
		kit.charges[E] == 1 and kit.charges[1] == 0 and kit.points == 0
	)
	local _, casts = step(p, B.AbilityE)
	local cast = casts[1]
	check("E puts the bow in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "reconbolt" and cast.slot == E)
	check("in the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "bow" and w.back == 1)
	check("its charge still there", kit.charges[E] == 1 and kit.holding == E)
	local started: number? = nil
	for n = 1, ticks(1.5) do
		step(p, B.Fire)
		if kit.drawFrom > 0 then
			started = n
			break
		end
	end
	check(
		"fire held from the start draws once its 0.8 s equip is over",
		started ~= nil and math.abs(started - ticks(BOW.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(started))
	)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	local shots = run(p, B.Fire, 3)
	check("fire draws it and fires nothing", #shots == 0 and kit.drawFrom > 0 and w.ammo[ULT] == 1)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	step(p, B.AbilityE)
	run(p, 0, ticks(1))
	check("E again puts it away, nothing spent", kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1 and kit.charges[E] == 1)
end

do
	local p = newPlayer()
	p.sim.abilities.charges[E] = 0
	local _, casts = step(p, B.AbilityE)
	check("with no charge, E does nothing", #casts == 0 and p.sim.abilities.holding == 0 and p.sim.weapons.loadout[ULT] == "")
end

-- The draw and the loose -----------------------------------------------------------------------

do
	local p = inHand()
	local kit = p.sim.abilities
	step(p, B.Fire)
	local from = now(p)
	check("fire held draws it from that tick", near(kit.drawFrom, from, 1e-9) and AbilitySim.bars(kit, from) == 0)
	check(
		"a bar for each third of a second it's held, three at the most",
		AbilitySim.bars(kit, from + 0.3) == 0
			and AbilitySim.bars(kit, from + 1 / 3) == 1
			and AbilitySim.bars(kit, from + 0.6) == 1
			and AbilitySim.bars(kit, from + 2 / 3) == 2
			and AbilitySim.bars(kit, from + 1) == 3
			and AbilitySim.bars(kit, from + 5) == 3
	)
	run(p, B.Fire, ticks(0.7))
	check(
		"the debug line shows the bars drawn",
		string.find(AbilitySim.summary(kit, now(p)), "draw 2", 1, true) ~= nil,
		AbilitySim.summary(kit, now(p))
	)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	local eye = PlayerSim.eye(p.sim, cfg)
	run(p, B.Fire, ticks(0.7))
	local shots, casts = step(p, 0)
	local loosed = now(p)
	local cast = ofKind(casts, "bolt")[1]
	check("fire let go looses it", cast ~= nil and cast.ability == "reconbolt" and cast.slot == E)
	check("as a cast, not a bullet", #shots == 0)
	check("drawn 0.7 s, with two bars, and no bounce added", cast ~= nil and cast.bars == 2 and cast.bounces == 0)
	check(
		"from the eye, the way the crosshair points",
		cast ~= nil
			and cast.origin == eye
			and vector.magnitude(cast.direction - Accuracy.aim(0, 0)) < 1e-6
			and cast.position == p.sim.movement.position
	)
	check("its charge spent, and the bow gone", kit.charges[E] == 0 and kit.holding == 0 and w.loadout[ULT] == "" and kit.drawFrom == 0)
	check(
		"the gun's put away until 0.7 s after",
		near(w.equipEndTime - loosed, 0.7, 1e-9),
		string.format("%.4f s", w.equipEndTime - loosed)
	)
	run(p, 0, ticks(1))
	local _, again = step(p, B.AbilityE)
	check("then the gun's back, and E does nothing", w.equipped == 1 and #again == 0 and kit.holding == 0)
end

do
	local p = inHand()
	local cast = loose(p, DT)
	check("fire tapped for a tick looses it at once, with no bar", cast ~= nil and cast.bars == 0)
	local q = inHand()
	local full = loose(q, 3)
	check("held long past its last bar, it has three", full ~= nil and full.bars == 3)
end

-- Its bounces --------------------------------------------------------------------------------------

do
	local p = inHand()
	local kit = p.sim.abilities
	local counts = {}
	for _ = 1, 4 do
		run(p, B.AltFire, 5)
		step(p, 0)
		table.insert(counts, tostring(kit.bounces))
	end
	check(
		"each alt fire pressed adds a bounce, two at the most, then none again",
		table.concat(counts, ",") == "1,2,0,1",
		table.concat(counts, ",")
	)
	check("the debug line shows them", string.find(AbilitySim.summary(kit, now(p)), "bounce 1", 1, true) ~= nil)
	run(p, B.Fire, ticks(0.2))
	step(p, B.Fire + B.AltFire)
	check("alt fire adds one while it's drawn too, the draw going on", kit.bounces == 2 and kit.drawFrom > 0)
	local cast = loose(p, 1)
	check("loosed with them", cast ~= nil and cast.bounces == 2 and cast.bars == 3)
	check("and they go with it", kit.bounces == 0)
end

do
	local p = newPlayer()
	local kit = p.sim.abilities
	run(p, B.AltFire, 3)
	step(p, 0)
	check("alt fire with the gun in hand adds nothing", kit.bounces == 0)
	step(p, B.AbilityE + B.AltFire)
	run(p, B.AltFire, 3)
	check("nor alt fire held as the bow comes into hand", kit.bounces == 0 and kit.holding == E)
	step(p, B.AltFire)
	step(p, B.AbilityE)
	run(p, 0, ticks(1))
	step(p, B.AbilityE)
	check("the bow put away and drawn again has none", kit.bounces == 0 and kit.holding == E)
end

-- E letting a draw go --------------------------------------------------------------------------------

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	run(p, B.Fire, ticks(0.5))
	local _, c1 = step(p, B.Fire + B.AbilityE)
	check(
		"E while it's drawn lets the draw go, the bow still in hand",
		#c1 == 0 and kit.drawFrom == 0 and kit.holding == E and w.loadout[ULT] == "bow"
	)
	local _, c2 = run(p, B.Fire, ticks(0.5))
	check("fire still held draws nothing", #c2 == 0 and kit.drawFrom == 0)
	local _, c3 = step(p, 0)
	check("and let go, looses nothing (the wiki)", #c3 == 0 and kit.charges[E] == 1 and kit.holding == E)
	local cast = loose(p, 0.4)
	check("the next draw starts afresh", cast ~= nil and cast.bars == 1)
end

do
	local p = inHand()
	local kit = p.sim.abilities
	step(p, B.AltFire)
	run(p, B.Fire, ticks(0.5))
	AbilitySim.settle(kit)
	check("a new life or round ends a draw and its bounces", kit.drawFrom == 0 and kit.bounces == 0 and not kit.letDown)
end

-- Its flight ------------------------------------------------------------------------------------------

do
	check(
		"drawn to no bar, one, two and three, it flies at 18, 29, 41.25 and 41.25 m/s",
		BoltSim.speed(0) == 18
			and BoltSim.speed(1) == 29
			and BoltSim.speed(2) == 41.25
			and BoltSim.speed(3) == 41.25
			and BoltSim.speed(9) == 41.25
	)
	check(
		"falling at that share of 9.8 m/s/s",
		near(BoltSim.gravity(0), 0.3 * 9.8, 1e-12)
			and near(BoltSim.gravity(1), 0.45 * 9.8, 1e-12)
			and near(BoltSim.gravity(3), 0.15 * 9.8, 1e-12)
	)
	check(
		"given two bounces at the most",
		BoltSim.shoot(1, 1, EYE, AHEAD, 3, 9).left == 2 and BoltSim.shoot(1, 1, EYE, AHEAD, 3, -1).left == 0
	)
end

do
	local b = BoltSim.shoot(1, 1, EYE, AHEAD, 3, 0)
	local land = BoltSim.fly(b, DT, hall(20))
	local point = b.position
	local expected = (20 - SIZE) / BoltSim.speed(3)
	check(
		"fully drawn, it reaches a wall 20 m ahead as fast as it flies",
		land ~= nil and near(land, expected, 1e-4),
		string.format("%s s", tostring(land))
	)
	check(
		"and sticks there, facing back",
		b.normal == vector.create(0, 0, 1) and near(point.z, -20 + SIZE, 1e-3) and near(point.x, 0, 1e-6),
		string.format("%.4f", point.z)
	)
	check(
		"having fallen as its gravity says",
		land ~= nil and near(point.y, 1.6 - 0.5 * BoltSim.gravity(3) * land * land, 1e-3),
		string.format("%.4f m", point.y)
	)
	check("its path stops there", land ~= nil and BoltSim.at(b.keys, land + 3) == point and b.keys[#b.keys].velocity == vector.zero)
	local again = BoltSim.shoot(1, 1, EYE, AHEAD, 3, 0)
	check(
		"flown again, it goes the same way",
		BoltSim.fly(again, DT, hall(20)) == land and again.position == point and #again.keys == #b.keys
	)
end

do
	local weak = BoltSim.shoot(1, 1, EYE, AHEAD, 0, 0)
	BoltSim.fly(weak, DT, hall(20))
	local fall = math.sqrt(2 * (1.6 - SIZE) / BoltSim.gravity(0))
	check(
		"loosed at once, it falls to the floor short of it, as far as it flies before it's down",
		weak.normal == vector.create(0, 1, 0)
			and near(weak.position.z, -BoltSim.speed(0) * fall, 0.01)
			and near(weak.position.y, SIZE, 1e-3),
		string.format("%.3f, %.3f", weak.position.y, weak.position.z)
	)
end

do
	local b = BoltSim.shoot(1, 1, EYE, AHEAD, 3, 1)
	local land = BoltSim.fly(b, DT, hall(10))
	local off = b.keys[2]
	local before = FireballSim.velocityAt(b.keys[1], off.age)
	check(
		"with a bounce, it goes off the wall and sticks to the one behind",
		land ~= nil and b.normal == vector.create(0, 0, -1) and near(b.position.z, 10 - SIZE, 1e-3) and b.left == 0,
		string.format("%.4f", b.position.z)
	)
	check(
		"off the wall as off a mirror, its speed kept",
		near(off.velocity.z, -before.z, 1e-4)
			and near(off.velocity.y, before.y, 1e-4)
			and near(vector.magnitude(off.velocity), vector.magnitude(before), 1e-4)
	)
	local twice = BoltSim.shoot(1, 1, EYE, AHEAD, 3, 2)
	BoltSim.fly(twice, DT, hall(10))
	check(
		"with two, off both, and stuck to the first",
		twice.normal == vector.create(0, 0, 1) and near(twice.position.z, -10 + SIZE, 1e-3) and #twice.keys == 4
	)
end

do
	local b = BoltSim.shoot(1, 1, EYE, vector.normalize(vector.create(0, -1, -1)), 1, 0)
	BoltSim.fly(b, DT, floor)
	check(
		"loosed at the floor, it sticks in it, facing up",
		b.landed ~= nil and b.normal == vector.create(0, 1, 0) and near(b.position.y, SIZE, 1e-3)
	)
	local up = BoltSim.shoot(1, 1, EYE, vector.create(0, 1, 0), 3, 0)
	check(
		"one that meets nothing is given up on, its air time flown",
		BoltSim.fly(up, DT, nil) == nil and up.age >= RC.airTime.value - 1e-6
	)
end

-- Its pulses ---------------------------------------------------------------------------------------

do
	local s = BoltSim.stuck(1, 7, vector.create(0, 2, -10), vector.create(0, 0, 1), 100)
	check(
		"its first pulse 0.667 s after it sticks, the second 1.6 s after that, and gone 3.2 s after the first",
		near(BoltSim.pulseAt(s, 1), 100.667, 1e-9) and near(BoltSim.pulseAt(s, 2), 102.267, 1e-9) and near(BoltSim.ends(s), 103.867, 1e-9)
	)
	check(
		"standing from when it sticks until it's gone",
		not BoltSim.standing(s, 99.99) and BoltSim.standing(s, 100) and BoltSim.standing(s, 103.8) and not BoltSim.standing(s, 103.9)
	)
	s.broken = 101
	check("or until it's broken", BoltSim.standing(s, 100.5) and not BoltSim.standing(s, 101))
	check("it looks from just off the surface", vector.magnitude(BoltSim.eye(s) - vector.create(0, 2, -9.9)) < 1e-5)
end

do
	local s = BoltSim.stuck(1, 7, vector.create(0, 1, 0), vector.create(0, 1, 0), 0)
	local function at(x: number): { vector }
		return { vector.create(x, 1.1, 0) }
	end
	local targets = {
		{ id = 2, points = at(10) },
		{ id = 3, points = at(29.9) },
		{ id = 4, points = at(30.5) },
		{ id = 5, points = { vector.create(40, 1.1, 0), vector.create(0, 1.1, 20) } },
		{ id = 6, points = at(-5) },
	}
	local from: vector? = nil
	local open = function(a: vector, _b: vector): boolean
		from = a
		return false
	end
	check("a pulse reveals whoever it has in sight within 30 m", table.concat(BoltSim.reveals(s, targets, open), ",") == "2,3,5,6")
	check("looking from its eye", from ~= nil and vector.magnitude((from :: vector) - BoltSim.eye(s)) < 1e-6)
	local behind = function(_a: vector, b: vector): boolean
		return b.x < 0
	end
	check("but nobody it doesn't", table.concat(BoltSim.reveals(s, targets, behind), ",") == "2,3,5")
	local walled = function(_a: vector, _b: vector): boolean
		return true
	end
	local o: Sight.Occluders = { clouds = {}, walls = {}, barriers = {}, time = 0, blocked = walled }
	check(
		"the level in the way hides them from it, as from anyone's eye (Sight)",
		#BoltSim.reveals(s, targets, function(a: vector, b: vector): boolean
			return Sight.hidden(a, b, o)
		end) == 0
	)
end

-- Its shaft in the level ----------------------------------------------------------------------------

do
	local s = BoltSim.stuck(1, 7, vector.create(0, 1.5, -10), vector.create(0, 0, 1), 0)
	local base = FakeLevel.new()
	local level = BoltSim.level(base, { s }, 1)
	local trace = Penetration.trace(level, vector.create(0, 1.5, 0), AHEAD, "high", WeaponConfig.MaxRange)
	local first = trace.walls[1]
	check(
		"stuck, its shaft stops a bullet, standing out 0.5 m",
		trace.stopped and near(trace.stop, 9.5, 1e-4) and first ~= nil and first.material == "solid" and first.name == BoltSim.SURFACE,
		string.format("%.4f m", trace.stop)
	)
	local piece = if first then BoltSim.piece(first.key) else nil
	check("and what it struck is the bolt", piece ~= nil and piece.stuck == s)
	local beside = Penetration.trace(level, vector.create(0.3, 1.5, 0), AHEAD, "high", WeaponConfig.MaxRange)
	check("one past its side goes on", not beside.stopped)
	local across = Penetration.trace(level, vector.create(-5, 1.5, -9.8), vector.create(1, 0, 0), "high", WeaponConfig.MaxRange)
	check("it's 0.2 m across", across.stopped and near(across.stop, 4.9, 1e-4), string.format("%.4f m", across.stop))
	check(
		"with none standing, the level's the level alone",
		BoltSim.level(base, { s }, 10) == base and BoltSim.level(base, { s }, -1) == base
	)
	local flat = BoltSim.stuck(1, 8, vector.create(0, 0, -4), vector.create(0, 1, 0), 0)
	local down =
		Penetration.trace(BoltSim.level(base, { flat }, 1), vector.create(0, 3, -4), vector.create(0, -1, 0), "high", WeaponConfig.MaxRange)
	check("stuck in the floor, it stands up out of it", down.stopped and near(down.stop, 2.5, 1e-4), string.format("%.4f m", down.stop))
	check("nothing else is a bolt's", BoltSim.piece(nil) == nil and BoltSim.piece({ bolt = false }) == nil)
end

-- The wire -------------------------------------------------------------------------------------------

do
	local p = inHand()
	step(p, B.AltFire)
	step(p, 0)
	run(p, B.Fire, ticks(0.5))
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a, b = p.sim.abilities, decoded.abilities
	check(
		"the ack carries the draw and its bounces",
		b.drawFrom == a.drawFrom
			and b.bounces == a.bounces
			and b.letDown == a.letDown
			and b.altDown == a.altDown
			and a.drawFrom > 0
			and a.bounces == 1
	)
	local copy: Player = { sim = decoded :: PlayerSim.State, slot = p.slot, world = floor }
	local same, bolts = true, 0
	for i = 1, ticks(1) do
		local buttons = if i < 40 then B.Fire elseif i == 60 then B.AltFire else 0
		local _, c1 = step(p, buttons)
		local _, c2 = step(copy, buttons)
		local x, y = ofKind(c1, "bolt")[1], ofKind(c2, "bolt")[1]
		bolts += if x then 1 else 0
		same = same
			and #c1 == #c2
			and (x == nil) == (y == nil)
			and (x == nil or y == nil or (x.bars == y.bars and x.bounces == y.bounces and x.origin == y.origin))
			and p.sim.weapons.equipEndTime == copy.sim.weapons.equipEndTime
	end
	check("and a replay from it looses the same bolt", same and bolts == 1)

	local q = inHand()
	run(q, B.Fire + B.AltFire, ticks(0.3))
	step(q, B.Fire + B.AltFire + B.AbilityE)
	local _, held = PlayerCodec.decodeAck(PlayerCodec.encodeAck(10, q.sim))
	check(
		"and a draw let go with fire still held, and alt fire held",
		held.abilities.letDown == true and held.abilities.altDown == true and q.sim.abilities.letDown and q.sim.abilities.altDown
	)
end

return nil
