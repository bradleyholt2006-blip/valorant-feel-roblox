--!strict
-- Omen's Dark Cover (system 40): its numbers and where they come from, Omen
-- and his kit, the orb in hand (E, its equip, its mark starting where the
-- crosshair meets the level, held fire sending it further and alt fire
-- bringing it closer, fire throwing nothing, E again sending it, its charge
-- spent and the gun back after, nothing sent before it's ready or with
-- nowhere for it), where its smoke goes (on the floor under the mark, where
-- the crosshair meets the floor, on a box's top, a mark inside a wall
-- brought back out of it, on through a floor too steep to stand on, nowhere
-- with no floor), its flight, the smoke growing, standing, warning and gone,
-- and the wire carrying the mark.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local AgentSelect = require("../src/shared/Abilities/AgentSelect")
local SmokeSim = require("../src/shared/Abilities/SmokeSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local DC = AbilityConfig.DarkCover
local ORB = WeaponConfig.Defs.smokeorb
local ULT = WeaponSim.ULT
local E = AbilityConfig.E
local OMEN = "omen"
local EYE = vector.create(0, 1.64, 0)
local AHEAD = vector.create(0, 0, -1) -- level, down the -Z way a yaw of 0 faces

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

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

-- One tick; returns its bullets and its casts.
local function step(p: Player, buttons: number, pitch: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	p.slot = ask(p.sim, p.slot)
	local shots, _, _, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, 0, pitch), cfg, p.world, DT)
	return shots or {}, casts or {}
end

-- `n` ticks with `buttons` held: every bullet and cast.
local function run(p: Player, buttons: number, n: number, pitch: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	local shots, casts = {}, {}
	for _ = 1, n do
		local s, c = step(p, buttons, pitch)
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

-- Omen settled at the origin in `world` (the floor without), the Vandal
-- drawn and his whole kit.
local function newPlayer(world: any?): Player
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(OMEN)
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1, world = world or floor }
	run(p, 0, ticks(1.5))
	return p
end

-- E tapped, and the orb's equip waited out.
local function inHand(world: any?, pitch: number?): Player
	local p = newPlayer(world)
	step(p, B.AbilityE, pitch)
	run(p, 0, ticks(ORB.equipTime.value) + 1, pitch)
	return p
end

H.section("Dark Cover tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in DC do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Dark Cover number says where it's from", labelled)
	local def = AbilityConfig.Defs.darkcover
	check(
		"Omen's E, his signature: two charges, the second 150 (Patch 4.04), one free, back 40 s after (Patch 11.08)",
		def.slot == E
			and def.kind == "signature"
			and def.cost ~= nil
			and def.cost.value == 150
			and def.cost.status == "confirmed"
			and def.charges ~= nil
			and def.charges.value == 2
			and def.free == 1
			and def.recharge ~= nil
			and def.recharge.kind == "cooldown"
			and def.recharge.seconds ~= nil
			and def.recharge.seconds.value == 40
			and def.recharge.seconds.status == "confirmed"
			and def.weapon == "smokeorb"
	)
	check(
		"a smoke 15 s long (Patch 0.50), the orb at 64 m/s (Patch 4.04)",
		DC.duration.value == 15 and DC.duration.status == "confirmed" and DC.speed.value == 64 and DC.speed.status == "confirmed"
	)
	check(
		"80 m of reach, 4.1 m of radius, grown in 1 s, warning 1.5 s before its end (the wiki)",
		DC.reach.value == 80 and DC.radius.value == 4.1 and DC.grow.value == 1 and DC.warn.value == 1.5
	)
	check("the gun's back 0.7 s after it's sent", AbilityConfig.unequip("darkcover") == 0.7)
	check(
		"the orb in hand: the fifth slot, ready in 0.6 s, no bullet's damage",
		ORB.slot == 5 and ORB.equipTime.value == 0.6 and ORB.ability == "darkcover" and ORB.damageSource.value == 0
	)
	check("the orb is 31st on the wire", WeaponConfig.Ids[31] == "smokeorb" and WeaponConfig.IndexOf.smokeorb == 31)
	check(
		"Team Deathmatch: back 65 s after, From the Shadows 60 points (the wiki)",
		AbilityConfig.TeamDeathmatch.cooldowns.darkcover.value == 65 and AbilityConfig.TeamDeathmatch.ultimate.fromtheshadows.value == 60
	)
	check(
		"its sounds: drawn, sent, forming and warning",
		SoundConfig.Weapons.smokeorb ~= nil
			and SoundConfig.Abilities.smoke ~= nil
			and SoundConfig.Abilities.darkcover ~= nil
			and SoundConfig.Abilities.fading ~= nil
	)
end

-- Omen ----------------------------------------------------------------------------------------

do
	local omen = AbilityConfig.Agents[OMEN]
	check(
		"Omen, a Controller (Patch 4.04): Shrouded Step, Paranoia, Dark Cover and From the Shadows",
		omen ~= nil
			and omen.name == "Omen"
			and omen.role == "Controller"
			and omen.passive == nil
			and omen.abilities[1] == "shroudedstep"
			and omen.abilities[2] == "paranoia"
			and omen.abilities[3] == "darkcover"
			and omen.abilities[4] == "fromtheshadows"
	)
	check(
		"Dark Cover, Paranoia (system 41) and Shrouded Step (system 42) can be played; From the Shadows not yet",
		AbilitySim.playable("darkcover")
			and AbilitySim.playable("paranoia")
			and AbilitySim.playable("shroudedstep")
			and not AbilitySim.playable("fromtheshadows")
	)
	check("he's fourth on the wire", AbilityConfig.AgentIds[4] == OMEN and AbilityConfig.AgentIndex[OMEN] == 4)
	check("so he can be picked, after Jett, Phoenix and Sage", AgentSelect.pickable()[4] == OMEN)
	local kit = AbilitySim.new(OMEN)
	AbilitySim.fill(kit)
	check("his kit full: E2/2", string.find(AbilitySim.summary(kit, 0), "E2/2", 1, true) ~= nil)
end

-- Where its smoke goes ------------------------------------------------------------------------

do
	check("the mark starts 15 m out with nothing in the way", near(SmokeSim.start(floor, EYE, AHEAD), 15, 1e-9))
	local walled = FakeWorld.new():addFloor():addBox(vector.create(-10, 0, -6), vector.create(10, 10, -5))
	check("or at a wall 5 m out", near(SmokeSim.start(walled, EYE, AHEAD), 4.95, 1e-6), tostring(SmokeSim.start(walled, EYE, AHEAD)))
	local steep = Accuracy.aim(0, -math.rad(60))
	check("and never nearer than 2 m", SmokeSim.start(floor, EYE, steep) == 2)
	check(
		"held fire sends it 15 m a second further, alt fire brings it back, within 2 to 80 m",
		near(SmokeSim.moved(15, true, 1), 30, 1e-9)
			and near(SmokeSim.moved(15, false, 0.5), 7.5, 1e-9)
			and SmokeSim.moved(79, true, 1) == 80
			and SmokeSim.moved(3, false, 1) == 2
	)
	local open = SmokeSim.place(floor, EYE, AHEAD, 10)
	check(
		"a mark 10 m out in the air: its smoke on the floor under it",
		open ~= nil and near(open.x, 0, 1e-6) and near(open.y, 0, 1e-5) and near(open.z, -10, 1e-6)
	)
	local down = Accuracy.aim(0, -math.rad(30))
	local looked = SmokeSim.place(floor, EYE, down, SmokeSim.start(floor, EYE, down))
	check(
		"looking down at the floor: its smoke where the crosshair meets it",
		looked ~= nil and near(looked.y, 0, 1e-5) and near(looked.z, -(1.64 - 0.05) / math.tan(math.rad(30)), 1e-4),
		if looked then tostring(looked) else "nil"
	)
	local boxed = FakeWorld.new():addFloor():addBox(vector.create(-1, 0, -11), vector.create(1, 1, -9))
	local top = SmokeSim.place(boxed, EYE, AHEAD, 10)
	check("over a box, on its top", top ~= nil and near(top.y, 1, 1e-5) and near(top.z, -10, 1e-6))
	local thick = FakeWorld.new():addFloor():addBox(vector.create(-10, 0, -11), vector.create(10, 5, -9))
	local out = SmokeSim.place(thick, EYE, AHEAD, 10)
	check(
		"a mark inside a wall: brought back along the crosshair out of it, to the floor this side",
		out ~= nil and near(out.z, -8.75, 1e-6) and near(out.y, 0, 1e-5),
		if out then tostring(out) else "nil"
	)
	local ledge = FakeWorld.new():addBox(vector.create(-3, -1, -3), vector.create(3, 0, 3))
	check("over nothing: nowhere", SmokeSim.place(ledge, EYE, AHEAD, 10) == nil)
	local slope = FakeWorld.new():addPart(vector.create(0, 0, -10), vector.create(8, 1, 8), math.rad(60))
	check("over a floor too steep to stand on, with nothing under it: nowhere", SmokeSim.place(slope, EYE, AHEAD, 10) == nil)
	local roof = FakeWorld.new():addFloor():addPart(vector.create(0, 1.5, -10), vector.create(8, 1, 8), math.rad(60))
	local under = SmokeSim.place(roof, vector.create(0, 5, 0), AHEAD, 10)
	check(
		"over a floor too steep to stand on, with one under it: on through to that one",
		under ~= nil and near(under.y, 0, 1e-5) and near(under.z, -10, 1e-6),
		if under then tostring(under) else "nil"
	)
	check("the orb flies there at 64 m/s", near(SmokeSim.flight(EYE, vector.create(0, 0, -10)), math.sqrt(1.64 ^ 2 + 100) / 64, 1e-6))
	check(
		"the smoke grows over 1 s, quickly at first, and stands until 15 s",
		SmokeSim.radiusAt(-0.1) == 0
			and SmokeSim.radiusAt(0) == 0
			and near(SmokeSim.radiusAt(0.5), 4.1 * 0.75, 1e-9)
			and SmokeSim.radiusAt(1) == 4.1
			and SmokeSim.radiusAt(14.99) == 4.1
			and SmokeSim.radiusAt(15) == 0
	)
	check(
		"warning it's going from 13.5 s",
		not SmokeSim.warning(13.4) and SmokeSim.warning(13.5) and SmokeSim.warning(14.9) and not SmokeSim.warning(15)
	)
end

-- In hand -------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local _, casts = step(p, B.AbilityE)
	local kit, w = p.sim.abilities, p.sim.weapons
	check(
		"E puts the orb in hand, its mark where the crosshair meets the level, 15 m out at most",
		#ofKind(casts, "equip") == 1 and kit.holding == E and w.loadout[ULT] == "smokeorb" and near(kit.reach, 15, 1e-9)
	)
	check("the kit says so", string.find(AbilitySim.summary(kit, now(p)), "equip mark 15.0", 1, true) ~= nil)
	run(p, 0, ticks(ORB.equipTime.value) + 1)
	local shots, fired = run(p, B.Fire, ticks(1))
	check(
		"held fire for 1 s sends the mark 15 m further, throws nothing and shoots nothing",
		near(kit.reach, 30, 1e-6) and #shots == 0 and #fired == 0 and kit.holding == E,
		tostring(kit.reach)
	)
	run(p, B.AltFire, ticks(0.5))
	check("held alt fire brings it back", near(kit.reach, 22.5, 1e-6), tostring(kit.reach))
	run(p, bit32.bor(B.Fire, B.AltFire), ticks(0.5))
	check("both held, it stays", near(kit.reach, 22.5, 1e-6))
	run(p, B.AltFire, ticks(2))
	check("no nearer than 2 m", kit.reach == 2)
	local _, sent = step(p, B.AbilityE)
	local smoke = ofKind(sent, "smoke")[1]
	local t = now(p)
	check(
		"E again sends it: its smoke on the floor under the mark",
		smoke ~= nil and smoke.smoke ~= nil and near(smoke.smoke.z, -2, 1e-3) and near(smoke.smoke.y, 0, 1e-3),
		if smoke and smoke.smoke then tostring(smoke.smoke) else "nil"
	)
	check(
		"a charge spent, the orb put away and the Vandal back 0.7 s later",
		kit.charges[E] == 1 and kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1 and near(w.equipEndTime, t + 0.7, 1e-9)
	)
end

do
	local p = newPlayer()
	step(p, B.AbilityE)
	local _, early = run(p, B.AbilityE, 1)
	check(
		"E again before it's ready sends nothing, and it stays in hand",
		#ofKind(early, "smoke") == 0 and p.sim.abilities.holding == E and p.sim.abilities.charges[E] == 2
	)
end

do
	local ledge = FakeWorld.new():addBox(vector.create(-3, -1, -3), vector.create(3, 0, 3))
	local p = inHand(ledge)
	local _, sent = run(p, B.AbilityE, 1)
	check(
		"with nothing under the mark, nothing's sent, and it stays in hand",
		#ofKind(sent, "smoke") == 0 and p.sim.abilities.holding == E and p.sim.abilities.charges[E] == 2
	)
	AbilitySim.settle(p.sim.abilities)
	check("a new life or round forgets the mark", p.sim.abilities.reach == 0)
end

-- The wire ------------------------------------------------------------------------------------

do
	local p = inHand()
	run(p, B.Fire, ticks(0.3))
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	check("the ack carries the mark", decoded.abilities.reach == p.sim.abilities.reach and p.sim.abilities.reach > 15)
end
return nil
