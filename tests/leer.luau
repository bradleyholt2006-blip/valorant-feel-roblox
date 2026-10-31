--!strict
-- Reyna's Leer (system 74): its numbers and where they come from, the eye
-- in hand (C, its equip, fire casting it from the eye along the crosshair,
-- alt fire casting nothing, its charge spent and the gun back after, C
-- again putting it away), its flight (along the crosshair at an even pace
-- over its windup, its travel and no further), when it's in the world and
-- open, who looks at it (within its cone of where they look, at any
-- distance), the nearsight it gives (whole while they look and its linger
-- after, run on without being sent every frame, on Paranoia's attribute
-- but not deafening), and the eye in the level shots are traced through,
-- on its own and over the Recon Bolt's.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local BoltSim = require("../src/shared/Abilities/BoltSim")
local LeerSim = require("../src/shared/Abilities/LeerSim")
local ParanoiaSim = require("../src/shared/Abilities/ParanoiaSim")
local BotUtility = require("../src/shared/Bots/BotUtility")
local Penetration = require("../src/shared/Combat/Penetration")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local FakeLevel = require("./FakeLevel")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local LE = AbilityConfig.Leer
local PA = AbilityConfig.Paranoia
local EYE_WEAPON = WeaponConfig.Defs.leereye
local ULT = WeaponSim.ULT
local C = AbilityConfig.C
local EYE = vector.create(0, 1.64, 0)
local AHEAD = vector.create(0, 0, -1) -- level, down the -Z way a yaw of 0 faces

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

type Player = { sim: PlayerSim.State, slot: number }

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

-- One tick; returns its bullets and its casts.
local function step(p: Player, buttons: number, yaw: number?, pitch: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	p.slot = ask(p.sim, p.slot)
	local shots, _, _, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, yaw, pitch), cfg, floor, DT)
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

-- Reyna settled at the origin, the Vandal drawn and her whole kit.
local function newPlayer(): Player
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new("reyna")
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1 }
	run(p, 0, ticks(1.5))
	return p
end

-- C tapped, and the eye's equip waited out.
local function inHand(): Player
	local p = newPlayer()
	step(p, B.AbilityC)
	run(p, 0, ticks(EYE_WEAPON.equipTime.value) + 1)
	return p
end

-- The way `degrees` round to the right of straight ahead, level.
local function turned(degrees: number): vector
	local r = math.rad(degrees)
	return vector.create(math.sin(r), 0, -math.cos(r))
end

H.section("Leer tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in LE do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Leer number says where it's from", labelled)
	local def = AbilityConfig.Defs.leer
	check(
		"Reyna's C: two charges at 250, put in hand",
		def.slot == C
			and def.cost ~= nil
			and def.cost.value == 250
			and def.charges ~= nil
			and def.charges.value == 2
			and def.weapon == "leereye"
	)
	check(
		"a 0.4 s windup, then 2 s open, the gun back 0.5 s after the cast (Patch 5.07)",
		LE.windup.value == 0.4
			and LE.duration.value == 2
			and LE.unequip.value == 0.5
			and LE.windup.status == "confirmed"
			and LE.duration.status == "confirmed"
			and LE.unequip.status == "confirmed"
			and AbilityConfig.unequip("leer") == 0.5
	)
	check(
		"10 m of travel and 100 health (the guides)",
		LE.travel.value == 10 and LE.travel.status == "community" and LE.health.value == 100 and LE.health.status == "community"
	)
	check(
		"its size, cone, linger and fade are ours",
		LE.size.status == "estimate" and LE.cone.status == "estimate" and LE.linger.status == "estimate" and LE.fade.status == "estimate"
	)
	check(
		"the eye in hand: the fifth slot, ready in 0.8 s, no bullet's damage, no alt fire",
		EYE_WEAPON.slot == 5
			and EYE_WEAPON.equipTime.value == 0.8
			and EYE_WEAPON.ability == "leer"
			and EYE_WEAPON.damageSource.value == 0
			and EYE_WEAPON.alt == nil
	)
	check("the eye is 39th on the wire", WeaponConfig.Ids[39] == "leereye" and WeaponConfig.IndexOf.leereye == 39)
	check("Team Deathmatch: back 44 s after (ours, as Curveball's)", AbilityConfig.TeamDeathmatch.cooldowns.leer.value == 44)
	check(
		"its sounds: drawn, cast, opening and broken",
		SoundConfig.Weapons.leereye ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.leer] ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.leeropen] ~= nil
			and SoundConfig.Sounds[SoundConfig.Abilities.leerbreak] ~= nil
	)
	check("it can be played, and bots cast it", AbilitySim.playable("leer") and BotUtility.uses("leer"))
	local kit = AbilitySim.new("reyna")
	AbilitySim.fill(kit)
	check("her kit full: C2/2", string.find(AbilitySim.summary(kit, 0), "C2/2", 1, true) ~= nil)
end

-- Its flight ----------------------------------------------------------------------------------

do
	local start = EYE
	local e = LeerSim.cast(7, 40, 100, start, AHEAD * 3)
	check("cast the way the crosshair points", vector.magnitude(e.way - AHEAD) < 1e-6 and e.owner == 7 and e.id == 40 and e.at == 100)
	check("from her eye", vector.magnitude(LeerSim.at(e, 0) - start) < 1e-6)
	check("at an even pace over its windup: halfway there at 0.2 s", vector.magnitude(LeerSim.at(e, 0.2) - (start + AHEAD * 5)) < 1e-6)
	check(
		"there, 10 m on, as it opens, and no further",
		vector.magnitude(LeerSim.at(e, 0.4) - (start + AHEAD * 10)) < 1e-6 and vector.magnitude(LeerSim.rest(e) - LeerSim.at(e, 30)) < 1e-6
	)
	local down = LeerSim.cast(7, 41, 100, start, vector.create(0, -1, -1))
	check(
		"along the crosshair up or down, with no drop",
		vector.magnitude(LeerSim.rest(down) - (start + vector.normalize(vector.create(0, -1, -1)) * 10)) < 1e-6
	)
	check("open 0.4 s after the cast, gone 2.4 s after", near(LeerSim.opens(e), 100.4, 1e-9) and near(LeerSim.ends(e), 102.4, 1e-9))
	check(
		"in the world from the cast until it's gone",
		not LeerSim.standing(e, 99.9) and LeerSim.standing(e, 100) and LeerSim.standing(e, 102.3) and not LeerSim.standing(e, 102.4)
	)
	check(
		"open only from its windup's end",
		not LeerSim.open(e, 100.39) and LeerSim.open(e, 100.4) and LeerSim.open(e, 102.3) and not LeerSim.open(e, 102.4)
	)
	e.broken = 101
	check("broken, it's gone", LeerSim.standing(e, 100.9) and not LeerSim.standing(e, 101) and not LeerSim.open(e, 101.5))
end

-- Where it comes to rest ----------------------------------------------------------------------

do
	local half = LE.size.value / 2
	local world = FakeWorld.new():addFloor()
	local function rest(aim: vector, from: vector?): (number, vector)
		local start = from or EYE
		local travel = LeerSim.reach(world, start, aim)
		return travel, LeerSim.rest(LeerSim.cast(7, 42, 0, start, aim, travel))
	end
	check("over an open floor, level: its whole 10 m", near((rest(AHEAD)), 10, 1e-9))
	local short = LeerSim.cast(7, 43, 0, EYE, AHEAD, 4)
	check(
		"cast to go 4 m: at the same pace, there at 0.16 s, and no further",
		near(LeerSim.at(short, 0.08).z, -2, 1e-6) and near(LeerSim.at(short, 0.16).z, -4, 1e-6) and near(LeerSim.rest(short).z, -4, 1e-6)
	)
	check(
		"cast to go further than its travel, or not told, it goes its 10 m",
		LeerSim.cast(7, 44, 0, EYE, AHEAD, 25).travel == 10 and LeerSim.cast(7, 45, 0, EYE, AHEAD).travel == 10
	)
	local down = vector.normalize(vector.create(0, -1, -1))
	local travel, at = rest(down)
	check(
		"aimed down at the floor, it stops on it, its size clear of it",
		near(at.y, half, 1e-3) and near(travel, (EYE.y - half) * math.sqrt(2), 1e-3),
		string.format("%.3f m up, %.3f m on", at.y, travel)
	)
	-- A wall 3 m ahead, 0.5 m thick and 4 m high, standing on the floor.
	world:addBox(vector.create(-5, 0, -3.5), vector.create(5, 4, -3))
	check("on through a wall in its way: its whole 10 m", near((rest(AHEAD)), 10, 1e-9))
	check("pressed up against the wall, still on through it", near((rest(AHEAD, vector.create(0, 1.64, -2.8))), 10, 1e-9))
	-- Aimed down so its middle comes to the floor's height inside the wall:
	-- it went into the floor there, under the wall's foot, so it rests on
	-- the floor where it reached it, not under the ground.
	local foot = vector.normalize(vector.create(0, -0.42, -1))
	travel, at = rest(foot)
	check(
		"into the floor inside a wall's foot, it rests on the floor, not under it",
		near(at.y, half, 1e-3) and near(at.z, -(EYE.y - half) / 0.42, 1e-3),
		string.format("%.3f m up at %.3f m", at.y, at.z)
	)
	-- A ceiling over it, 0.4 m thick at 3 m up.
	world:addBox(vector.create(-5, 3, -8), vector.create(5, 3.4, 2))
	local up = vector.normalize(vector.create(0, 1, -1))
	travel, at = rest(up)
	check("on up through a ceiling: its whole 10 m", near(travel, 10, 1e-9) and at.y > 3.4)
end

-- Who looks at it -----------------------------------------------------------------------------

do
	local at = EYE + AHEAD * 20
	check("someone looking straight at it", LeerSim.looks(at, EYE, AHEAD))
	check("or 45 degrees off it", LeerSim.looks(at, EYE, turned(45)))
	check("but not 55 degrees off it, past its cone", not LeerSim.looks(at, EYE, turned(55)))
	check("nor with their back to it", not LeerSim.looks(at, EYE, turned(180)))
	check("at any distance: 200 m off", LeerSim.looks(EYE + AHEAD * 200, EYE, AHEAD))
	check("and with it in their face, whichever way they look", LeerSim.looks(EYE, EYE, turned(180)))
	check("45 degrees above where they look, as well as to the side", LeerSim.looks(EYE + vector.create(0, 10, -10), EYE, AHEAD))
end

-- The nearsight -------------------------------------------------------------------------------

do
	local first = LeerSim.nearsight(nil, 10)
	check(
		"a look at 10 s: whole until 10.2 s, gone at 10.7 s",
		first ~= nil and first.from == 10 and near(first.full, 10.2, 1e-9) and near(first.gone, 10.7, 1e-9)
	)
	local n = first :: ParanoiaSim.Nearsight
	check("looking on, nothing new to send while it's whole for half its linger yet", LeerSim.nearsight(n, 10.05) == nil)
	local on = LeerSim.nearsight(n, 10.12)
	check(
		"then it runs on from where it started",
		on ~= nil and on.from == 10 and near(on.full, 10.32, 1e-9) and near(on.gone, 10.82, 1e-9)
	)
	local cleared = LeerSim.nearsight(n, 10.5)
	check("looked at again as it clears, whole again from then", cleared ~= nil and cleared.from == 10.5 and near(cleared.full, 10.7, 1e-9))
	local paranoia = ParanoiaSim.nearsight(nil, 10)
	check("Paranoia's alone: whole 2 s, clearing over 0.5 s, as it was", paranoia.full == 12 and paranoia.gone == 12.5)
	check("over Paranoia's, still whole for longer, nothing new", LeerSim.nearsight(paranoia, 10.5) == nil)
	check("and whole, they see as far as Paranoia's leave them: 7.5 m", ParanoiaSim.range(n, 10.1) == PA.vision.value)
	check(
		"kept on Paranoia's attribute, its deafening on another",
		ParanoiaSim.ATTRIBUTE == "VFNearsight" and ParanoiaSim.DEAF_ATTRIBUTE == "VFDeafened"
	)
end

-- In the level --------------------------------------------------------------------------------

do
	local base = FakeLevel.new()
	-- Cast from 4 m behind the gun down -Z: at rest 6 m ahead of it.
	local e = LeerSim.cast(1, 7, 0, vector.create(0, 1.5, 4), AHEAD)
	local level = LeerSim.level(base, { e }, 1)
	local trace = Penetration.trace(level, vector.create(0, 1.5, 0), AHEAD, "high", WeaponConfig.MaxRange)
	local first = trace.walls[1]
	check(
		"in the world, it stops a bullet at its face, 0.25 m short of its middle",
		trace.stopped and near(trace.stop, 5.75, 1e-4) and first ~= nil and first.material == "solid" and first.name == LeerSim.SURFACE,
		string.format("%.4f m", trace.stop)
	)
	local piece = if first then LeerSim.piece(first.key) else nil
	check("and what it struck is the eye", piece ~= nil and piece.eye == e)
	local beside = Penetration.trace(level, vector.create(0.3, 1.5, 0), AHEAD, "high", WeaponConfig.MaxRange)
	check("one past its side goes on", not beside.stopped)
	local flying = Penetration.trace(LeerSim.level(base, { e }, 0.2), vector.create(0, 1.5, 0), AHEAD, "high", WeaponConfig.MaxRange)
	check(
		"flying, it's where it's got to: 1 m ahead at 0.2 s",
		flying.stopped and near(flying.stop, 0.75, 1e-4),
		string.format("%.4f m", flying.stop)
	)
	check(
		"before the cast and once it's gone, the level's the level alone",
		LeerSim.level(base, { e }, -0.1) == base and LeerSim.level(base, { e }, 2.4) == base
	)
	-- Over the Recon Bolt's level: the nearer of the two stops it.
	local bolt = BoltSim.stuck(2, 8, vector.create(0, 1.5, -10), vector.create(0, 0, 1), 0)
	local both = LeerSim.level(BoltSim.level(base, { bolt }, 1), { e }, 1)
	local nearer = Penetration.trace(both, vector.create(0, 1.5, 0), AHEAD, "high", WeaponConfig.MaxRange)
	check("over the Recon Bolt's level, the eye in front stops it", nearer.stopped and near(nearer.stop, 5.75, 1e-4))
	local behind = LeerSim.cast(1, 9, 0, vector.create(0, 1.5, -2), AHEAD)
	local past = Penetration.trace(
		LeerSim.level(BoltSim.level(base, { bolt }, 1), { behind }, 1),
		vector.create(0, 1.5, 0),
		AHEAD,
		"high",
		WeaponConfig.MaxRange
	)
	local struck = past.walls[1]
	check(
		"and a bolt in front of the eye stops it first",
		past.stopped and near(past.stop, 9.5, 1e-4) and struck ~= nil and BoltSim.piece(struck.key) ~= nil,
		string.format("%.4f m", past.stop)
	)
	check("nothing else is an eye's", LeerSim.piece(nil) == nil and LeerSim.piece({ leer = false }) == nil)
	check("nor is a bolt", LeerSim.piece({ bolt = true }) == nil and BoltSim.piece({ leer = true }) == nil)
end

-- In hand -------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local _, casts = step(p, B.AbilityC)
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"C puts the eye in hand, from the fifth slot",
		#ofKind(casts, "equip") == 1 and kit.holding == C and w.equipped == ULT and w.loadout[ULT] == "leereye"
	)
	local waited: number? = nil
	for n = 1, ticks(2) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot)), cfg, floor, DT)
		if probed and #ofKind(probed, "leer") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be cast once its 0.8 s equip is over",
		waited ~= nil and math.abs(waited - ticks(EYE_WEAPON.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

do
	local p = inHand()
	local _, alt = run(p, B.AltFire, ticks(0.5))
	check("alt fire casts nothing", #ofKind(alt, "leer") == 0 and p.sim.abilities.holding == C)
	local yaw, pitch = -0.3, 0.2
	local shots, casts = step(p, B.Fire, yaw, pitch)
	local cast = ofKind(casts, "leer")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("fire casts it", cast ~= nil and cast.ability == "leer" and cast.slot == C and #shots == 0)
	check(
		"from the eye, along the crosshair",
		cast ~= nil
			and vector.magnitude(cast.origin - PlayerSim.eye(p.sim, cfg)) < 1e-6
			and vector.magnitude(cast.direction - Accuracy.aim(yaw, pitch)) < 1e-6
	)
	check(
		"a charge spent, the eye put away and the Vandal back 0.5 s later",
		kit.charges[C] == 1
			and kit.holding == 0
			and w.loadout[ULT] == ""
			and w.equipped == 1
			and near(w.equipEndTime - now(p), LE.unequip.value, 1e-9)
	)
end

do
	local p = inHand()
	local _, casts = step(p, B.AbilityC)
	check("C again puts it away uncast", #ofKind(casts, "leer") == 0 and p.sim.abilities.holding == 0 and p.sim.abilities.charges[C] == 2)
end
return nil
