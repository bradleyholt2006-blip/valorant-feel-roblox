--!strict
-- Omen's Paranoia (system 41): its numbers and where they come from, the
-- orb in hand (Q, its equip, fire sending it from the eye along the
-- crosshair, alt fire sending nothing, its charge spent and the gun back
-- after, Q again putting it away), its flight (appearing ahead of the eye,
-- flying its travel at its speed and no further), whom it touches (whoever
-- it comes within its radius of, ahead of Omen but not beside or behind
-- him, through anything, Omen too looking down), who's warned, the
-- nearsight (whole, clearing, run on by a second touch, on its attribute),
-- how far the nearsighted see on the minimap, and how the deafened hear.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local ParanoiaSim = require("../src/shared/Abilities/ParanoiaSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Sight = require("../src/shared/Combat/Sight")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local SoundMath = require("../src/shared/Audio/SoundMath")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local PA = AbilityConfig.Paranoia
local ORB = WeaponConfig.Defs.blindorb
local ULT = WeaponSim.ULT
local Q = AbilityConfig.Q
local OMEN = "omen"
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

-- Omen settled at the origin, the Vandal drawn and his whole kit.
local function newPlayer(): Player
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(OMEN)
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1 }
	run(p, 0, ticks(1.5))
	return p
end

-- Q tapped, and the orb's equip waited out.
local function inHand(): Player
	local p = newPlayer()
	step(p, B.AbilityQ)
	run(p, 0, ticks(ORB.equipTime.value) + 1)
	return p
end

-- The points of someone standing with their feet at `feet`.
local function body(feet: vector): { vector }
	return Sight.points({ position = feet, yaw = 0, crouchAlpha = 0 })
end

H.section("Paranoia tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in PA do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	for _, param: any in SoundConfig.Deafen do
		if type(param) == "table" then
			labelled = labelled and param.status == "estimate" and #param.source > 0
		end
	end
	check("every Paranoia and deafening number says where it's from", labelled)
	local def = AbilityConfig.Defs.paranoia
	check(
		"Omen's Q: one charge, 250 (Patch 5.12), put in hand",
		def.slot == Q
			and def.kind == "basic"
			and def.cost ~= nil
			and def.cost.value == 250
			and def.cost.status == "confirmed"
			and def.charges ~= nil
			and def.charges.value == 1
			and def.weapon == "blindorb"
	)
	check(
		"20 m/s for 25 m (Patch 11.08)",
		PA.speed.value == 20 and PA.speed.status == "confirmed" and PA.travel.value == 25 and PA.travel.status == "confirmed"
	)
	check(
		"4.3 m of radius, 2 s of nearsight seeing 7.5 m (the wiki)",
		PA.radius.value == 4.3 and PA.duration.value == 2 and PA.vision.value == 7.5 and PA.vision.status == "community"
	)
	check("appearing 4.5 m ahead of the eye, past its radius (ours)", PA.offset.value == 4.5 and PA.offset.value > PA.radius.value)
	check("the gun's back 0.7 s after it's sent", AbilityConfig.unequip("paranoia") == 0.7)
	check(
		"the orb in hand: the fifth slot, ready in 1.1 s, no bullet's damage, no alt fire",
		ORB.slot == 5 and ORB.equipTime.value == 1.1 and ORB.ability == "paranoia" and ORB.damageSource.value == 0 and ORB.alt == nil
	)
	check("the orb is 32nd on the wire", WeaponConfig.Ids[32] == "blindorb" and WeaponConfig.IndexOf.blindorb == 32)
	check("Team Deathmatch: back 73 s after (the wiki)", AbilityConfig.TeamDeathmatch.cooldowns.paranoia.value == 73)
	check(
		"its sounds: drawn, sent, and the touch",
		SoundConfig.Weapons.blindorb ~= nil
			and SoundConfig.Abilities.paranoia ~= nil
			and SoundConfig.Sounds[SoundConfig.Deafen.sound] ~= nil
	)
	local kit = AbilitySim.new(OMEN)
	AbilitySim.fill(kit)
	check("his kit full: Q1/1", string.find(AbilitySim.summary(kit, 0), "Q1/1", 1, true) ~= nil)
end

-- Its flight ----------------------------------------------------------------------------------

do
	local orb = ParanoiaSim.send(7, 40, EYE, AHEAD * 3)
	check("sent the way the crosshair points", vector.magnitude(orb.way - AHEAD) < 1e-6 and orb.owner == 7 and orb.id == 40)
	check("appearing 4.5 m ahead of the eye", vector.magnitude(orb.start - (EYE + AHEAD * 4.5)) < 1e-6)
	check("flying 1.25 s", near(ParanoiaSim.flight(), 1.25, 1e-9))
	check(
		"20 m a second, and no further than 25 m from where it appeared",
		vector.magnitude(ParanoiaSim.at(orb, 0) - orb.start) < 1e-6
			and vector.magnitude(ParanoiaSim.at(orb, 0.5) - (orb.start + AHEAD * 10)) < 1e-5
			and vector.magnitude(ParanoiaSim.at(orb, 5) - (orb.start + AHEAD * 25)) < 1e-5
	)
	local down = Accuracy.aim(0, -math.rad(30))
	local dropped = ParanoiaSim.at(ParanoiaSim.send(7, 41, EYE, down), 1)
	check("straight, with no drop", vector.magnitude(dropped - (EYE + down * 24.5)) < 1e-4, tostring(dropped))
end

-- Whom it touches -----------------------------------------------------------------------------

do
	local orb = ParanoiaSim.send(7, 40, EYE, AHEAD)
	local start = ParanoiaSim.at(orb, 0)
	local done = ParanoiaSim.at(orb, math.huge)
	local feet = vector.create(0, 0, 0)
	check("someone 2 m in front of Omen, as it appears", ParanoiaSim.touches(start, start, body(vector.create(0, 0, -2))))
	check(
		"but nobody beside him (Patch 4.04), nor behind",
		not ParanoiaSim.touches(start, start, body(vector.create(0.6, 0, 0)))
			and not ParanoiaSim.touches(start, start, body(vector.create(-0.6, 0, 0.3)))
			and not ParanoiaSim.touches(start, done, body(vector.create(0, 0, 2)))
	)
	check("nor Omen himself, looking ahead", not ParanoiaSim.touches(start, done, body(feet)))
	local below = ParanoiaSim.send(7, 41, EYE, vector.create(0, -1, 0))
	check("but looking down, he's touched by his own", ParanoiaSim.touches(ParanoiaSim.at(below, 0), ParanoiaSim.at(below, 0), body(feet)))
	local mid = ParanoiaSim.at(orb, 0.5)
	check(
		"someone 4 m off its way, as it passes them",
		not ParanoiaSim.touches(start, start, body(vector.create(4, 0, -14.5)))
			and ParanoiaSim.touches(start, mid, body(vector.create(4, 0, -14.5)))
	)
	check("but not 5 m off it", not ParanoiaSim.touches(start, done, body(vector.create(5, 0, -14.5))))
	check(
		"out to its radius past the end of its travel, and no further",
		ParanoiaSim.touches(start, done, body(vector.create(0, 0, -33)))
			and not ParanoiaSim.touches(start, done, body(vector.create(0, 0, -34.5)))
	)
	check("through anything in the way: it's flown without the level", ParanoiaSim.touches(start, done, body(vector.create(0, 0, -12))))
	check(
		"whoever stands in its path as it's sent is warned, nobody else",
		ParanoiaSim.inPath(orb, body(vector.create(3, 0, -20)))
			and not ParanoiaSim.inPath(orb, body(vector.create(6, 0, -20)))
			and not ParanoiaSim.inPath(orb, body(vector.create(0, 0, 3)))
	)
end

-- The nearsight -------------------------------------------------------------------------------

do
	local n = ParanoiaSim.nearsight(nil, 10)
	check("a touch at 10 s: whole until 12 s, gone at 12.5 s", n.from == 10 and n.full == 12 and n.gone == 12.5)
	check(
		"dark past its vision while it's whole, clearing over the fade",
		ParanoiaSim.darkAt(n, 9.99) == 0
			and ParanoiaSim.darkAt(n, 10) == 1
			and ParanoiaSim.darkAt(n, 11.99) == 1
			and near(ParanoiaSim.darkAt(n, 12.25), 0.5, 1e-9)
			and ParanoiaSim.darkAt(n, 12.5) == 0
	)
	check(
		"seeing 7.5 m while it's whole, and as far as anyone after",
		ParanoiaSim.range(n, 11) == 7.5 and ParanoiaSim.range(n, 12) == nil and ParanoiaSim.range(nil, 11) == nil
	)
	local again = ParanoiaSim.nearsight(n, 11)
	check("a second touch while it's whole runs it on", again.from == 10 and again.full == 13 and again.gone == 13.5)
	local fading = ParanoiaSim.nearsight(n, 12.2)
	check("and while it's clearing, starts it again", near(fading.from, 12.2, 1e-9) and near(fading.full, 14.2, 1e-9))
	local after = ParanoiaSim.nearsight(n, 20)
	check("once it's gone, a new one", after.from == 20 and after.full == 22)
	local back = ParanoiaSim.decode(ParanoiaSim.encode({ from = 812.5, full = 814.5, gone = 815 }))
	check("kept as an attribute and read back", back ~= nil and back.from == 812.5 and back.full == 814.5 and back.gone == 815)
	check("and nothing from junk", ParanoiaSim.decode("x,1") == nil and ParanoiaSim.decode(nil) == nil)
	check("its attribute", ParanoiaSim.ATTRIBUTE == "VFNearsight")
end

-- The minimap's sight and the deafened ---------------------------------------------------------

do
	local open: Sight.Occluders = {
		clouds = {},
		walls = {},
		time = 0,
		blocked = function()
			return false
		end,
	}
	local near5, far10 = body(vector.create(0, 0, -5)), body(vector.create(0, 0, -10))
	local viewer: Sight.Viewer = { side = 1, eye = EYE, look = AHEAD }
	local nearsighted: Sight.Viewer = { side = 1, eye = EYE, look = AHEAD, range = PA.vision.value }
	check("someone 10 m ahead is seen", Sight.sees(viewer, far10, open))
	check("but nearsighted, only within 7.5 m", Sight.sees(nearsighted, near5, open) and not Sight.sees(nearsighted, far10, open))
	local openCutoff, whole = SoundMath.deafened(0)
	local cutoff, volume = SoundMath.deafened(1)
	local midCutoff, half = SoundMath.deafened(0.5)
	check("hearing all of it undeafened", openCutoff == SoundConfig.OPEN_CUTOFF and whole == 1)
	check(
		"deafened, muffled to 400 Hz and turned down to 0.35",
		near(cutoff, 400, 1e-6) and near(volume, 0.35, 1e-9),
		string.format("%.1f Hz %.3f", cutoff, volume)
	)
	check(
		"and half way as it clears, by pitch",
		near(midCutoff, math.sqrt(SoundConfig.OPEN_CUTOFF * 400), 1e-3) and near(half, 0.675, 1e-9)
	)
end

-- In hand -------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local _, casts = step(p, B.AbilityQ)
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"Q puts the orb in hand, from the fifth slot",
		#ofKind(casts, "equip") == 1 and kit.holding == Q and w.equipped == ULT and w.loadout[ULT] == "blindorb"
	)
	local waited: number? = nil
	for n = 1, ticks(2) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot)), cfg, floor, DT)
		if probed and #ofKind(probed, "paranoia") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be sent once its 1.1 s equip is over",
		waited ~= nil and math.abs(waited - ticks(ORB.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

do
	local p = inHand()
	local _, alt = run(p, B.AltFire, ticks(0.5))
	check("alt fire sends nothing", #ofKind(alt, "paranoia") == 0 and p.sim.abilities.holding == Q)
	local yaw, pitch = -0.3, 0.2
	local shots, casts = step(p, B.Fire, yaw, pitch)
	local sent = ofKind(casts, "paranoia")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("fire sends it", sent ~= nil and sent.ability == "paranoia" and sent.slot == Q and #shots == 0)
	check(
		"from the eye, along the crosshair",
		sent ~= nil
			and vector.magnitude(sent.origin - PlayerSim.eye(p.sim, cfg)) < 1e-6
			and vector.magnitude(sent.direction - Accuracy.aim(yaw, pitch)) < 1e-6
	)
	check(
		"its charge spent, the orb put away and the Vandal back 0.7 s later",
		kit.charges[Q] == 0
			and kit.holding == 0
			and w.loadout[ULT] == ""
			and w.equipped == 1
			and near(w.equipEndTime - now(p), PA.unequip.value, 1e-9)
	)
	run(p, 0, ticks(1))
	local _, none = step(p, B.AbilityQ)
	check("and with none left, Q does nothing", #none == 0 and kit.holding == 0)
end

do
	local p = inHand()
	local _, casts = step(p, B.AbilityQ)
	check(
		"Q again puts it away unsent",
		#ofKind(casts, "paranoia") == 0 and p.sim.abilities.holding == 0 and p.sim.abilities.charges[Q] == 1
	)
end
return nil
