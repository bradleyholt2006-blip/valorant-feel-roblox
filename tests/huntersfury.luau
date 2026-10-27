--!strict
-- Sova's Hunter's Fury (system 46): its numbers and where they come from,
-- its cast (X with the points full putting its bow in hand, drawn over its
-- equip), a blast's windup (fire, once it's drawn: no bullet, a "charge"
-- cast, rooted through it) and the blast as it ends (a "blast" cast from
-- the eye along the crosshair then), the knockback, its blasts no closer
-- together than its fire rate, three of them and no more, how it ends (its
-- time up, its last blast's recovery over, anything else drawn, a death),
-- whom a blast catches (FurySim), and the wire carrying it all so a replay
-- comes back the same.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local FurySim = require("../src/shared/Abilities/FurySim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Shop = require("../src/shared/Weapons/Shop")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local HF = AbilityConfig.HuntersFury
local FURYBOW = WeaponConfig.Defs.furybow
local ULT = WeaponSim.ULT
local Q, X = AbilityConfig.Q, AbilityConfig.X
local SOVA = "sova"
local FEET = vector.create(0, 0.02, 0)
local EYE = vector.create(0, 1.62, 0)
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

local function level(v: vector): vector
	return vector.create(v.x, 0, v.z)
end

-- Sova settled at FEET, the Vandal drawn, his kit full, his ultimate's
-- points too.
local function newPlayer(): Player
	local sim = PlayerSim.new(FEET, { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(SOVA)
	AbilitySim.fill(sim.abilities, true)
	local p: Player = { sim = sim, slot = 1, yaw = 0, pitch = 0, world = floor }
	run(p, 0, ticks(1.5))
	return p
end

-- X tapped, and the bow's draw waited out.
local function drawn(): Player
	local p = newPlayer()
	step(p, B.Ultimate)
	run(p, 0, ticks(HF.equip.value))
	return p
end

-- Fire tapped (the bow drawn), and the ticks waited until a blast goes, at
-- most `most` of them: the blast, and the ticks it took.
local function untilBlast(p: Player, most: number): (AbilitySim.Cast?, number)
	for n = 1, most do
		local _, casts = step(p, 0)
		local blast = ofKind(casts, "blast")[1]
		if blast then
			return blast, n
		end
	end
	return nil, most
end

H.section("Hunter's Fury tests")

-- Its numbers ------------------------------------------------------------------------------------

do
	local labelled = true
	for _, param in HF do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Hunter's Fury number says where it's from", labelled)
	local def = AbilityConfig.Defs.huntersfury
	check(
		"Sova's X, his ultimate: 8 points (Patch 3.0), its bow in hand, played",
		def.slot == X
			and def.kind == "ultimate"
			and def.points ~= nil
			and def.points.value == 8
			and def.points.status == "confirmed"
			and def.weapon == "furybow"
			and AbilitySim.playable("huntersfury")
	)
	check("in Team Deathmatch, 70 points (the wiki)", AbilityConfig.TeamDeathmatch.ultimate.huntersfury.value == 70)
	check(
		"the guides': a 1 s windup, 80 a blast, 66 m long and 2 m either side, a 1 s reveal, a 1.5 m knockback, 6 s once drawn",
		HF.windup.value == 1
			and HF.damage.value == 80
			and HF.range.value == 66
			and HF.radius.value == 2
			and HF.reveal.value == 1
			and HF.kick.value == 1.5
			and HF.duration.value == 6
			and HF.windup.status == "community"
			and HF.damage.status == "community"
	)
	check(
		"ours: its draw 0.5 s, the view turning at 15% through a windup, the knockback over 0.25 s",
		HF.equip.value == 0.5
			and HF.equip.status == "estimate"
			and HF.turn.value == 0.15
			and HF.turn.status == "estimate"
			and HF.kickTime.value == 0.25
			and HF.kickTime.status == "estimate"
	)
	check(
		"its bow, an ultimate's weapon of the fifth slot: three blasts, none to reload, a click each, 2.125 s apart",
		FURYBOW.category == "ultimate"
			and FURYBOW.slot == ULT
			and FURYBOW.ultimate == true
			and FURYBOW.ability == nil
			and FURYBOW.fireMode == "semi"
			and FURYBOW.magazine.value == 3
			and FURYBOW.reserve.value == 0
			and near(1 / FURYBOW.fireRate.value, 2.125, 1e-12)
			and FURYBOW.equipTime.value == HF.equip.value
			and FURYBOW.name == "Hunter's Fury"
	)
	check("neither it nor its bow is sold", Shop.item("huntersfury") == nil and Shop.item("furybow") == nil)
	check("its bow's wire id is the 37th", WeaponConfig.IndexOf.furybow == 37 and WeaponConfig.Ids[37] == "furybow")
	check(
		"its sounds: its bow drawn, the cast, a blast charging and going, heard across the map as the spike's blast",
		SoundConfig.Weapons.furybow ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.fury] ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.charge] ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.blast] ~= nil
			and SoundConfig.CastCurves.blast == "blast"
	)
	check("its damage is credited to its bow, which the kill feed names", FurySim.WEAPON == "furybow" and FURYBOW.name == "Hunter's Fury")
end

-- Its cast ---------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local w, kit = p.sim.weapons, p.sim.abilities
	check("his points full", kit.points == AbilitySim.pointsNeeded(kit) and kit.points == 8)
	local _, casts = step(p, B.Ultimate)
	local cast = ofKind(casts, "fury")[1]
	local t = now(p)
	check("X casts it", cast ~= nil and cast.ability == "huntersfury" and cast.slot == X)
	check("its points spent", kit.points == 0)
	check(
		"its bow in hand in the fifth slot, three blasts in it, the gun it came from remembered",
		w.equipped == ULT and w.loadout[ULT] == "furybow" and w.ammo[ULT] == 3 and w.back == 1
	)
	check(
		"drawn over 0.5 s, its 6 s from then",
		near(w.equipEndTime, t + HF.equip.value, 1e-9) and near(kit.furyUntil, t + HF.equip.value + HF.duration.value, 1e-9)
	)
	check("under way, as the kit says", AbilitySim.ultimateOn(kit) and string.find(AbilitySim.summary(kit, t), "fury", 1, true) ~= nil)
	local shots, early = run(p, B.Fire, ticks(HF.equip.value) - 2)
	check("fire through its draw starts nothing", #shots == 0 and #ofKind(early, "charge") == 0 and kit.chargeAt == 0)
	local _, again = step(p, B.Ultimate)
	check("X again does nothing", #again == 0 and kit.furyUntil > 0 and w.loadout[ULT] == "furybow")
end

do
	local p = newPlayer()
	local kit = p.sim.abilities
	kit.points = 7
	local _, casts = step(p, B.Ultimate)
	check("with a point short, X does nothing", #casts == 0 and kit.furyUntil == 0 and p.sim.weapons.loadout[ULT] == "")
end

-- A blast ----------------------------------------------------------------------------------------

do
	local p = drawn()
	local w, kit = p.sim.weapons, p.sim.abilities
	local shots, casts = step(p, B.Fire)
	local t = now(p)
	local charge = ofKind(casts, "charge")[1]
	check("fire, once it's drawn, starts a blast's windup: no bullet", #shots == 0 and charge ~= nil and charge.ability == "huntersfury")
	check("a blast spent", w.ammo[ULT] == 2)
	check(
		"its windup 1 s, from his eye along his crosshair",
		near(kit.chargeAt, t + HF.windup.value, 1e-9)
			and charge ~= nil
			and charge.origin == p.sim.movement.position + EYE
			and charge.direction == Accuracy.aim(0, 0)
	)
	check("charging, as the kit says", AbilitySim.charging(kit, t) and string.find(AbilitySim.summary(kit, t), "charge", 1, true) ~= nil)
	local from = p.sim.movement.position
	run(p, bit32.bor(B.Forward, B.Left, B.Jump), ticks(0.5))
	check(
		"rooted through it: running and jumping move him nowhere",
		vector.magnitude(p.sim.movement.position - from) < 1e-9 and p.sim.movement.grounded
	)
	-- Turned a little as it ends: it goes the way he looks then.
	p.yaw, p.pitch = 0.1, 0.05
	local blast, n = untilBlast(p, ticks(1))
	check(
		"it goes as its windup ends, 1 s on",
		blast ~= nil and near(now(p), t + HF.windup.value, 1e-9),
		string.format("%d ticks after the half second", n)
	)
	check(
		"from his eye along his crosshair then",
		blast ~= nil and blast.origin == from + EYE and blast.direction == Accuracy.aim(0.1, 0.05) and blast.slot == X
	)
	check("nothing charging now", kit.chargeAt == 0 and not AbilitySim.charging(kit, now(p)))
	-- The knockback, from the tick it went: back from the way he faced
	-- then, level.
	run(p, 0, ticks(HF.kickTime.value) - 1)
	local away = p.sim.movement.position - from
	local back = -vector.create(-math.sin(0.1), 0, -math.cos(0.1))
	run(p, 0, ticks(0.5))
	local rest = p.sim.movement.position - from
	check(
		"it knocks him 1.5 m back from the way he faced, level, over its 0.25 s",
		near(vector.magnitude(level(away)), HF.kick.value, 0.02)
			and vector.magnitude(level(rest)) < HF.kick.value + 0.03
			and near(vector.dot(vector.normalize(level(rest)), back), 1, 1e-6)
			and math.abs(rest.y) < 1e-9,
		string.format("%.3f m, then %.3f m", vector.magnitude(level(away)), vector.magnitude(level(rest)))
	)
	check("the knockback over", kit.kickFrom == 0 and kit.kickYaw == 0)
end

-- Its blasts' cadence, how many and how it ends ---------------------------------------------------

do
	local p = drawn()
	local w, kit = p.sim.weapons, p.sim.abilities
	local times = {}
	local blasts = 0
	-- Fire pressed every other tick, as fast as it'll go, for 7 s.
	for i = 1, ticks(7) do
		local _, casts = step(p, if i % 2 == 1 then B.Fire else 0)
		if ofKind(casts, "charge")[1] then
			table.insert(times, now(p))
		end
		blasts += #ofKind(casts, "blast")
	end
	local apart = #times == 3 and near(times[2] - times[1], 2.125, DT + 1e-9) and near(times[3] - times[2], 2.125, DT + 1e-9)
	check(
		"its blasts no closer together than 2.125 s, and three of them",
		apart and blasts == 3,
		string.format("%d charges, %d blasts", #times, blasts)
	)
	check(
		"then its time's up, its bow gone and the gun drawn again",
		kit.furyUntil == 0 and w.loadout[ULT] == "" and w.equipped == 1 and not AbilitySim.ultimateOn(kit)
	)
end

do
	local p = drawn()
	local w, kit = p.sim.weapons, p.sim.abilities
	local t = now(p)
	run(p, 0, ticks(HF.duration.value) - 2)
	check("held, its bow stays until its time's up", w.loadout[ULT] == "furybow" and kit.furyUntil > 0)
	run(p, 0, 3)
	check(
		"its time up 6 s after its draw, its bow gone",
		kit.furyUntil == 0 and w.loadout[ULT] == "" and w.equipped == 1 and near(now(p), t + HF.duration.value, 2 * DT)
	)
end

do
	-- Given the time, the bow goes once its last blast's recovery is over.
	local p = drawn()
	local w, kit = p.sim.weapons, p.sim.abilities
	kit.furyUntil = math.huge
	local last = 0
	for i = 1, ticks(5) do
		local _, casts = step(p, if i % 2 == 1 then B.Fire else 0)
		if ofKind(casts, "charge")[1] then
			last = now(p)
		end
	end
	local _, casts = step(p, B.Fire)
	check("a fourth fire does nothing", w.ammo[ULT] == 0 and #ofKind(casts, "charge") == 0)
	local gone: number? = nil
	for _ = 1, ticks(3) do
		step(p, 0)
		if w.loadout[ULT] == "" then
			gone = now(p)
			break
		end
	end
	check(
		"with time to spare, its bow goes as its last blast's recovery ends, 2.125 s after its fire",
		gone ~= nil and near(gone - last, 2.125, DT + 1e-9) and kit.furyUntil == 0 and w.equipped == 1,
		string.format("%s s", tostring(if gone then gone - last else nil))
	)
end

do
	local p = drawn()
	local w, kit = p.sim.weapons, p.sim.abilities
	step(p, B.Fire)
	run(p, 0, ticks(0.3))
	p.slot = 2
	local _, casts = run(p, 0, ticks(1.5))
	check(
		"the sidearm drawn in a windup ends it: no blast, the bow gone (Patch 3.0)",
		#ofKind(casts, "blast") == 0 and kit.furyUntil == 0 and kit.chargeAt == 0 and w.loadout[ULT] == "" and w.equipped == 2
	)
end

do
	local p = drawn()
	local w, kit = p.sim.weapons, p.sim.abilities
	step(p, B.Fire)
	run(p, 0, ticks(0.3))
	local _, casts = step(p, B.AbilityQ)
	local _, later = run(p, 0, ticks(1.5))
	check(
		"the Shock Bolt put in hand in a windup ends it, its bow in the fifth slot instead (Patch 3.0)",
		ofKind(casts, "equip")[1] ~= nil
			and #ofKind(later, "blast") == 0
			and kit.furyUntil == 0
			and kit.chargeAt == 0
			and kit.holding == Q
			and w.loadout[ULT] == "shockbow"
	)
end

do
	local p = drawn()
	local kit = p.sim.abilities
	step(p, B.Fire)
	run(p, 0, ticks(1))
	AbilitySim.settle(kit)
	check(
		"a death or a new round ends it all, a knockback under way too",
		kit.furyUntil == 0 and kit.chargeAt == 0 and kit.kickFrom == 0 and kit.kickYaw == 0
	)
end

-- Whom a blast catches ---------------------------------------------------------------------------

do
	local function standing(id: number, x: number, y: number, z: number): FurySim.Target
		return FurySim.target(id, { position = vector.create(x, y, z), yaw = 0, crouchAlpha = 0 })
	end
	local crouched = FurySim.target(9, { position = vector.create(0, 0, -5), yaw = 0, crouchAlpha = 1 })
	check(
		"a body, its upright line from the feet to the top of the head, its body's half width either side",
		near(standing(1, 0, 0, 0).top, 1.75, 1e-6) and near(crouched.top, 1.23, 1e-6) and crouched.width == 0.22
	)
	local hits = FurySim.caught(EYE, AHEAD, {
		standing(1, 0, 0, -30),
		standing(2, 2.1, 0, -20),
		standing(3, 2.3, 0, -20),
		standing(4, 0, 0, 5),
		standing(5, 0, 0, -66.5),
		standing(6, 0, 0, -65.5),
		standing(7, 0, -3, -10),
		standing(8, 0, -1, -10),
	})
	local ids = {}
	for _, hit in hits do
		table.insert(ids, tostring(hit.id))
	end
	local caught = table.concat(ids, ",")
	check("everyone in its way, the nearest first, however far within its range", caught == "8,2,1,6", caught)
	check("how far along it each one is", hits[1] ~= nil and near(hits[1].along, 10, 1e-6) and near(hits[3].along, 30, 1e-6))
	check("within its 2 m and their width of its line, and not past", caught:find("2", 1, true) ~= nil and caught:find("3", 1, true) == nil)
	check("nobody behind him (Patch 13.09)", FurySim.reach(EYE, AHEAD, standing(4, 0, 0, 5)) == nil)
	check(
		"nobody past its 66 m, and nobody it passes over by more than its reach",
		FurySim.reach(EYE, AHEAD, standing(5, 0, 0, -66.5)) == nil and FurySim.reach(EYE, AHEAD, standing(7, 0, -3, -10)) == nil
	)
	local down = Accuracy.aim(0, math.rad(-30))
	check(
		"aimed down, it catches who's near where it goes into the floor, not who's past it under the floor",
		FurySim.reach(EYE, down, standing(1, 0, 0, -4)) ~= nil and FurySim.reach(EYE, down, standing(2, 0, 0, -10)) == nil
	)
end

-- The wire ---------------------------------------------------------------------------------------

do
	local p = drawn()
	step(p, B.Fire)
	run(p, 0, ticks(0.5))
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a, b = p.sim.abilities, decoded.abilities
	check(
		"the ack carries its time, the blast charging and its bow",
		b.furyUntil == a.furyUntil
			and b.chargeAt == a.chargeAt
			and a.chargeAt > 0
			and decoded.weapons.loadout[ULT] == "furybow"
			and decoded.weapons.ammo[ULT] == 2
	)
	local copy: Player = { sim = decoded :: PlayerSim.State, slot = p.slot, yaw = 0, pitch = 0, world = floor }
	local same, blasts = true, 0
	-- Through the rest of its windup and into its knockback.
	for _ = 1, ticks(0.6) do
		local _, c1 = step(p, 0)
		local _, c2 = step(copy, 0)
		local x, y = ofKind(c1, "blast")[1], ofKind(c2, "blast")[1]
		blasts += if x then 1 else 0
		same = same
			and #c1 == #c2
			and (x == nil) == (y == nil)
			and (x == nil or y == nil or (x.origin == y.origin and x.direction == y.direction))
			and p.sim.movement.position == copy.sim.movement.position
	end
	check("and a replay from it sends the same blast", same and blasts == 1)
	local _, mid = PlayerCodec.decodeAck(PlayerCodec.encodeAck(10, p.sim))
	check(
		"and its knockback under way",
		mid.abilities.kickFrom == p.sim.abilities.kickFrom
			and mid.abilities.kickYaw == p.sim.abilities.kickYaw
			and p.sim.abilities.kickFrom > 0
	)
	local again: Player = { sim = mid :: PlayerSim.State, slot = p.slot, yaw = 0, pitch = 0, world = floor }
	local kicked = true
	for _ = 1, ticks(0.5) do
		step(p, 0)
		step(again, 0)
		kicked = kicked and p.sim.movement.position == again.sim.movement.position
	end
	check("which a replay from it carries on the same", kicked)
end

return nil
