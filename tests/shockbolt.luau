--!strict
-- Sova's Shock Bolt (system 45): its numbers and where they come from, its
-- bow in hand (Q with its two charges, its equip, Q again putting it away),
-- the draw, the bounces and the loose as the Recon Bolt's (a "bolt" cast of
-- the Shock Bolt's, its charge spent, the gun back 0.7 s on), Q letting a
-- draw go, E taking the Recon Bolt's bow in its place, its burst (how much
-- it does at each distance, from where it looks, whom it reaches and what
-- hides them), and the wire carrying its draw so a replay comes back the
-- same.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local BoltSim = require("../src/shared/Abilities/BoltSim")
local ShockSim = require("../src/shared/Abilities/ShockSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Shop = require("../src/shared/Weapons/Shop")
local Sight = require("../src/shared/Combat/Sight")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local SB = AbilityConfig.ShockBolt
local RC = AbilityConfig.ReconBolt
local SHOCKBOW = WeaponConfig.Defs.shockbow
local ULT = WeaponSim.ULT
local Q, E = AbilityConfig.Q, AbilityConfig.E
local SOVA = "sova"
local FEET = vector.create(0, 0.02, 0)
local UP = vector.create(0, 1, 0)

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

-- Q tapped, and the bow's equip waited out.
local function inHand(): Player
	local p = newPlayer()
	step(p, B.AbilityQ)
	run(p, 0, ticks(SHOCKBOW.equipTime.value) + 1)
	return p
end

-- Fire held `seconds` and let go: the bolt loosed, if any.
local function loose(p: Player, seconds: number): AbilitySim.Cast?
	run(p, B.Fire, ticks(seconds))
	local _, casts = step(p, 0)
	return ofKind(casts, "bolt")[1]
end

H.section("Shock Bolt tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param in SB do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Shock Bolt number says where it's from", labelled)
	local def = AbilityConfig.Defs.shockbolt
	check(
		"Sova's Q, a basic ability: 2 charges at 150 (Patch 3.0), the bow in hand, played",
		def.slot == Q
			and def.kind == "basic"
			and def.cost ~= nil
			and def.cost.value == 150
			and def.cost.status == "confirmed"
			and def.charges ~= nil
			and def.charges.value == 2
			and def.free == nil
			and def.recharge == nil
			and def.weapon == "shockbow"
			and AbilitySim.playable("shockbolt")
	)
	check("in Team Deathmatch, a charge back every 26 s (the wiki)", AbilityConfig.TeamDeathmatch.cooldowns.shockbolt.value == 26)
	local item = Shop.item("shockbolt")
	check(
		"its charges are sold, and its bow isn't",
		item ~= nil and item.kind == "ability" and item.price == 150 and item.slot == "Q" and Shop.item("shockbow") == nil
	)
	check(
		"its bow, a weapon of the fifth slot that fires nothing and is never reloaded, drawn in 0.8 s as the Recon Bolt's",
		SHOCKBOW.category == "ability"
			and SHOCKBOW.slot == ULT
			and SHOCKBOW.ability == "shockbolt"
			and SHOCKBOW.fireMode == "none"
			and SHOCKBOW.magazine.value == 1
			and SHOCKBOW.reserve.value == 0
			and SHOCKBOW.equipTime.value == WeaponConfig.Defs.bow.equipTime.value
			and SHOCKBOW.name == "Shock Bolt"
	)
	check("the gun back in hand 0.7 s after it's loosed, as after a recon bolt", near(AbilityConfig.unequip("shockbolt"), 0.7, 1e-12))
	check(
		"Riot's: 75 at the most (Patch 4.08), down to 1 (the wiki), out to 5 m (guides), the most within 1 m (ours)",
		SB.damage.value == 75
			and SB.damage.status == "confirmed"
			and string.find(SB.damage.source, "90 >>> 75", 1, true) ~= nil
			and SB.least.value == 1
			and SB.outer.value == 5
			and SB.inner.value == 1
			and SB.inner.status == "estimate"
	)
	check("its owner and his side take all of it", SB.selfShare.value == 1 and SB.allyShare.value == 1)
	check(
		"both of Sova's bolts are loosed from his bow, and nothing else is",
		AbilitySim.bowed("shockbolt") and AbilitySim.bowed("reconbolt") and not AbilitySim.bowed("hothands") and not AbilitySim.bowed("")
	)
	check(
		"its sounds: the bow drawn, the loose, the flight and the burst",
		SoundConfig.Weapons.shockbow ~= nil
			and SoundConfig.Abilities.bolt ~= nil
			and SoundConfig.Abilities.boltflight ~= nil
			and SoundConfig.Abilities.shockburst ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.shockburst] ~= nil
	)
	check("its damage is credited to its bow, which the kill feed names", ShockSim.WEAPON == "shockbow" and SHOCKBOW.name == "Shock Bolt")
end

-- The bow in hand --------------------------------------------------------------------------------

do
	local p = newPlayer()
	local w, kit = p.sim.weapons, p.sim.abilities
	check("his kit filled: both Shock Bolt charges", kit.charges[Q] == 2)
	local _, casts = step(p, B.AbilityQ)
	local cast = casts[1]
	check("Q puts the bow in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "shockbolt" and cast.slot == Q)
	check("in the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "shockbow" and w.back == 1)
	check("its charges still there", kit.charges[Q] == 2 and kit.holding == Q)
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
		started ~= nil and math.abs(started - ticks(SHOCKBOW.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(started))
	)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	step(p, B.AbilityQ)
	run(p, 0, ticks(1))
	check("Q again puts it away, nothing spent", kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1 and kit.charges[Q] == 2)
end

-- The draw and the loose -----------------------------------------------------------------------

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	run(p, B.Fire, ticks(0.7))
	check(
		"fire held draws it, a bar each third of a second, as the Recon Bolt's",
		AbilitySim.bars(kit, now(p)) == 2 and string.find(AbilitySim.summary(kit, now(p)), "draw 2", 1, true) ~= nil,
		AbilitySim.summary(kit, now(p))
	)
	step(p, B.Fire + B.AltFire)
	check("and alt fire adds a bounce", kit.bounces == 1 and string.find(AbilitySim.summary(kit, now(p)), "bounce 1", 1, true) ~= nil)
	local shots, casts = step(p, 0)
	local loosed = now(p)
	local cast = ofKind(casts, "bolt")[1]
	check("fire let go looses it, a bolt of the Shock Bolt's", cast ~= nil and cast.ability == "shockbolt" and cast.slot == Q)
	check("as a cast, not a bullet", #shots == 0)
	check("with the bars it was drawn and the bounce added", cast ~= nil and cast.bars == 2 and cast.bounces == 1)
	check("a charge spent, one left, and the bow gone", kit.charges[Q] == 1 and kit.holding == 0 and w.loadout[ULT] == "")
	check(
		"the gun's put away until 0.7 s after",
		near(w.equipEndTime - loosed, 0.7, 1e-9),
		string.format("%.4f s", w.equipEndTime - loosed)
	)
	run(p, 0, ticks(1))
	step(p, B.AbilityQ)
	run(p, 0, ticks(SHOCKBOW.equipTime.value) + 1)
	local second = loose(p, 1.2)
	check(
		"the second charge looses another, fully drawn",
		second ~= nil and second.bars == 3 and second.bounces == 0 and kit.charges[Q] == 0
	)
	run(p, 0, ticks(1))
	local _, none = step(p, B.AbilityQ)
	check("then Q does nothing", #none == 0 and kit.holding == 0 and w.loadout[ULT] == "")
end

-- Q letting a draw go, and E in its place ----------------------------------------------------

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	run(p, B.Fire, ticks(0.5))
	local _, c1 = step(p, B.Fire + B.AbilityQ)
	check(
		"Q while it's drawn lets the draw go, the bow still in hand",
		#c1 == 0 and kit.drawFrom == 0 and kit.holding == Q and w.loadout[ULT] == "shockbow"
	)
	local _, c2 = run(p, B.Fire, ticks(0.3))
	local _, c3 = step(p, 0)
	check("and fire let go then looses nothing", #c2 == 0 and #c3 == 0 and kit.charges[Q] == 2)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	step(p, B.AltFire)
	step(p, 0)
	run(p, B.Fire, ticks(0.5))
	local _, casts = step(p, B.Fire + B.AbilityE)
	run(p, 0, 2)
	check(
		"E while it's drawn puts the Recon Bolt's bow in hand in its place, nothing loosed or spent",
		#ofKind(casts, "bolt") == 0
			and kit.holding == E
			and w.loadout[ULT] == "bow"
			and kit.drawFrom == 0
			and kit.bounces == 0
			and kit.charges[Q] == 2
			and kit.charges[E] == 1
	)
	run(p, 0, ticks(1))
	local cast = loose(p, 0.4)
	check("and what it looses is a recon bolt", cast ~= nil and cast.ability == "reconbolt" and cast.slot == E)
end

-- Its flight -------------------------------------------------------------------------------------

do
	local eye = vector.create(0, 1.62, 0)
	local aim = vector.create(0, 0, -1)
	local b = BoltSim.shoot(1, 1, eye, aim, 0, 0)
	local land = BoltSim.fly(b, DT, floor)
	check(
		"it flies as a recon bolt does: tapped level from a standing eye, it comes down 18.6 m ahead",
		land ~= nil and b.normal == UP and near(b.position.z, -18.6, 0.05) and near(b.position.y, RC.size.value, 1e-3),
		string.format("%.3f m", b.position.z)
	)
end

-- Its burst -------------------------------------------------------------------------------------

do
	check("75 within 1 m of it", ShockSim.damageAt(0) == 75 and ShockSim.damageAt(0.5) == 75 and ShockSim.damageAt(1) == 75)
	check(
		"less further out, in a straight line to 1 at 5 m, in whole points",
		ShockSim.damageAt(3) == 38 and ShockSim.damageAt(2) == 57 and ShockSim.damageAt(4) == 20 and ShockSim.damageAt(5) == 1,
		string.format("%d %d %d %d", ShockSim.damageAt(2), ShockSim.damageAt(3), ShockSim.damageAt(4), ShockSim.damageAt(5))
	)
	check("and none past 5 m", ShockSim.damageAt(5.01) == 0 and ShockSim.damageAt(30) == 0)
	local falling, whole = true, true
	local last = math.huge
	for i = 0, 60 do
		local d = ShockSim.damageAt(i / 10)
		falling = falling and d <= last
		whole = whole and d % 1 == 0
		last = d
	end
	check("never more further out", falling and whole)
	check(
		"it looks from just off the surface it met",
		vector.magnitude(ShockSim.eye(vector.create(0, 0, -10), UP) - vector.create(0, 0.1, -10)) < 1e-6
			and vector.magnitude(ShockSim.eye(vector.create(0, 1, -10), vector.create(0, 0, 1)) - vector.create(0, 1, -9.9)) < 1e-6
	)
end

do
	local point, normal = vector.create(0, 0, 0), UP
	local eye = ShockSim.eye(point, normal)
	local function at(x: number): { vector }
		return { eye + vector.create(x, 0, 0) }
	end
	local targets = {
		{ id = 2, points = at(0.5) },
		{ id = 3, points = at(3) },
		{ id = 4, points = at(5.5) },
		{ id = 5, points = { eye + vector.create(9, 0, 0), eye + vector.create(0, 0, 2) } },
		{ id = 6, points = at(-4) },
	}
	local from: vector? = nil
	local open = function(a: vector, _b: vector): boolean
		from = a
		return false
	end
	local hits = ShockSim.hits(point, normal, targets, open)
	local seen = {}
	for _, hit in hits do
		table.insert(seen, string.format("%d:%d", hit.id, hit.damage))
	end
	check(
		"a burst hurts whoever it has in sight within 5 m, by how far they are",
		table.concat(seen, ",") == "2:75,3:38,5:57,6:20",
		table.concat(seen, ",")
	)
	check("looking from its eye", from ~= nil and vector.magnitude((from :: vector) - eye) < 1e-6)
	local behind = function(_a: vector, b: vector): boolean
		return b.x < 0
	end
	local hidden = ShockSim.hits(point, normal, targets, behind)
	check("but nobody it doesn't", #hidden == 3 and hidden[3].id == 5)
	local near2 = ShockSim.hits(point, normal, {
		{ id = 7, points = { eye + vector.create(-0.5, 0, 0), eye + vector.create(2, 0, 0), eye + vector.create(4, 0, 0) } },
	}, behind)
	check(
		"by the nearest point of them it sees",
		#near2 == 1 and near(near2[1].distance, 2, 1e-6) and near2[1].damage == 57,
		if near2[1] then string.format("%.3f m", near2[1].distance) else "none"
	)
	local walled = function(_a: vector, _b: vector): boolean
		return true
	end
	local o: Sight.Occluders = { clouds = {}, walls = {}, barriers = {}, time = 0, blocked = walled }
	check("the level in the way shelters them (Sight)", #ShockSim.hits(point, normal, targets, function(a: vector, b: vector): boolean
		return Sight.hidden(a, b, o)
	end) == 0)
	local cloudy: Sight.Occluders = {
		clouds = { { centre = eye + vector.create(2, 0, 0), radius = 0.8 } },
		walls = {},
		barriers = {},
		time = 0,
		blocked = function(_a: vector, _b: vector): boolean
			return false
		end,
	}
	local noClouds = table.clone(cloudy)
	noClouds.clouds = {}
	check("a cloud the server leaves out stops nothing", #ShockSim.hits(point, normal, targets, function(a: vector, b: vector): boolean
		return Sight.hidden(a, b, noClouds)
	end) == 4 and #ShockSim.hits(point, normal, targets, function(a: vector, b: vector): boolean
		return Sight.hidden(a, b, cloudy)
	end) == 3)
end

-- The wire ---------------------------------------------------------------------------------------

do
	local p = inHand()
	step(p, B.AltFire)
	step(p, 0)
	run(p, B.Fire, ticks(0.5))
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a, b = p.sim.abilities, decoded.abilities
	check(
		"the ack carries the bow in hand, the draw and its bounces",
		b.holding == Q
			and decoded.weapons.loadout[ULT] == "shockbow"
			and b.drawFrom == a.drawFrom
			and b.bounces == a.bounces
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
			and (x == nil or y == nil or (x.ability == y.ability and x.bars == y.bars and x.bounces == y.bounces and x.origin == y.origin))
			and p.sim.weapons.equipEndTime == copy.sim.weapons.equipEndTime
	end
	check("and a replay from it looses the same bolt", same and bolts == 1)
end

return nil
