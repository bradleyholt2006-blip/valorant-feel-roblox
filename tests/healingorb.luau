--!strict
-- Sage's Healing Orb (system 36): its numbers and where they come from,
-- Sage and her kit, the orb in hand (E, its equip, fire's and alt fire's
-- tries, a click at a time, the orb staying in hand through them, the
-- charge spent and the orb put away as the server finds one heals, E again
-- and whatever else is drawn putting it away untried), who a try heals
-- (the crosshair over a hurt ally, within its width and reach, the first
-- along it in sight), the heal by the point, its pause when its target's
-- hurt, and the wire carrying the orb in hand.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local AgentSelect = require("../src/shared/Abilities/AgentSelect")
local HealSim = require("../src/shared/Abilities/HealSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Shop = require("../src/shared/Weapons/Shop")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local HO = AbilityConfig.HealingOrb
local ORB = WeaponConfig.Defs.healorb
local ULT = WeaponSim.ULT
local C, Q, E, X = AbilityConfig.C, AbilityConfig.Q, AbilityConfig.E, AbilityConfig.X
local SAGE = "sage"

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player and the slot their client asks for.
type Player = { sim: PlayerSim.State, slot: number }

-- The slot the client asks for this tick, by PlayerController's rules (as
-- the Curveball tests have them).
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

-- One tick, the slot asked for as the client would; returns its bullets
-- and its casts.
local function step(p: Player, buttons: number, yaw: number?, pitch: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	p.slot = ask(p.sim, p.slot)
	local shots, _, _, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, yaw, pitch), cfg, floor, DT)
	return shots or {}, casts or {}
end

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

local function now(p: Player): number
	return p.sim.movement.tick * DT
end

-- The casts of kind `kind` among `casts`.
local function ofKind(casts: { AbilitySim.Cast }, kind: string): { AbilitySim.Cast }
	local out = {}
	for _, cast in casts do
		if cast.kind == kind then
			table.insert(out, cast)
		end
	end
	return out
end

-- Sage settled on the floor with the Vandal drawn and her orb's charge.
local function newPlayer(): Player
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(SAGE)
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1 }
	run(p, 0, ticks(1.5))
	return p
end

-- E tapped, and the orb's equip waited out.
local function inHand(): Player
	local p = newPlayer()
	step(p, B.AbilityE)
	run(p, 0, ticks(ORB.equipTime.value) + 1)
	return p
end

-- An ally standing (or crouched) with their feet at `feet`.
local function body(id: number, feet: vector, crouch: number?): HealSim.Body
	return { id = id, pose = { position = feet, yaw = 0, crouchAlpha = crouch or 0 } }
end

local NOTHING = function(_a: vector, _b: vector): boolean
	return false
end

H.section("Healing Orb tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in HO do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Healing Orb number says where it's from", labelled)
	local def = AbilityConfig.Defs.healingorb
	local recharge = def.recharge
	check(
		"Sage's signature, one charge, free each round, never bought",
		def.slot == E and def.kind == "signature" and def.charges ~= nil and def.charges.value == 1 and def.free == 1 and def.cost == nil
	)
	check(
		"back 45 s after it's spent (Patch 1.0)",
		recharge ~= nil and recharge.kind == "cooldown" and recharge.seconds.value == 45 and recharge.seconds.status == "confirmed"
	)
	check(
		"100 health to an ally (Patch 5.12) and 100 to herself (Patch 13.00), each over 5 s (Patch 9.10)",
		HO.allyHeal.value == 100
			and HO.allyHeal.status == "confirmed"
			and HO.selfHeal.value == 100
			and HO.selfHeal.status == "confirmed"
			and HO.duration.value == 5
			and HO.duration.status == "confirmed"
	)
	check("so 20 a second, as the wiki has it", near(HealSim.new(1, 2, HO.allyHeal.value, 0).rate, 20, 1e-12))
	check(
		"0.5 s to put it in hand and 0.7 s to have the gun back (the wiki)",
		ORB.equipTime.value == 0.5 and HO.unequip.value == 0.7 and AbilityConfig.unequip("healingorb") == 0.7
	)
	check(
		"the orb, a weapon of the fifth slot that's never reloaded, a try a click each way, and the Healing Orb's",
		ORB.category == "ability"
			and ORB.slot == ULT
			and ORB.ability == "healingorb"
			and def.weapon == "healorb"
			and ORB.fireMode == "semi"
			and ORB.magazine.value == 1
			and ORB.reserve.value == 0
			and ORB.alt ~= nil
			and ORB.alt.fireMode == "semi"
			and ORB.name == "Healing Orb"
	)
	check("neither it nor its orb is sold", Shop.item("healingorb") == nil and Shop.item("healorb") == nil)
	check(
		"how near and how far are ours",
		HO.width.status == "estimate" and HO.reach.status == "estimate" and HO.pause.status == "estimate"
	)
end

-- Sage -----------------------------------------------------------------------------------------

do
	local sage = AbilityConfig.Agents[SAGE]
	check(
		"Sage, a Sentinel (Patch 1.01), with no passive",
		sage ~= nil and sage.name == "Sage" and sage.role == "Sentinel" and sage.passive == nil
	)
	check(
		"her kit as the wiki has it: Barrier Orb, Slow Orb, Healing Orb, Resurrection",
		sage.abilities[C] == "barrierorb"
			and sage.abilities[Q] == "sloworb"
			and sage.abilities[E] == "healingorb"
			and sage.abilities[X] == "resurrection"
	)
	local d = AbilityConfig.Defs
	check(
		"Barrier Orb 300 a charge and one, Slow Orb 200 and two, Resurrection 7 points (Patch 9.10)",
		d.barrierorb.cost ~= nil
			and d.barrierorb.cost.value == 300
			and d.barrierorb.charges ~= nil
			and d.barrierorb.charges.value == 1
			and d.sloworb.cost ~= nil
			and d.sloworb.cost.value == 200
			and d.sloworb.charges ~= nil
			and d.sloworb.charges.value == 2
			and d.resurrection.points ~= nil
			and d.resurrection.points.value == 7
			and d.resurrection.points.status == "confirmed"
	)
	check(
		"her Healing Orb can be played, her Slow Orb (system 37), her Barrier Orb (system 38) and her Resurrection (system 39)",
		AbilitySim.playable("healingorb")
			and AbilitySim.playable("sloworb")
			and AbilitySim.playable("barrierorb")
			and AbilitySim.playable("resurrection")
	)
	local pickable = AgentSelect.pickable()
	check("so she can be picked, after Jett and Phoenix", pickable[3] == SAGE and #pickable >= 3)
	check("and she's third on the wire", AbilityConfig.AgentIds[3] == SAGE and AbilityConfig.AgentIndex[SAGE] == 3)
	local TDM = AbilityConfig.TeamDeathmatch
	check(
		"Team Deathmatch's numbers for her, the wiki's: the Healing Orb back in 22 s, Resurrection 50 points",
		TDM.cooldowns.healingorb.value == 22
			and TDM.cooldowns.barrierorb.value == 94
			and TDM.cooldowns.sloworb.value == 51
			and TDM.ultimate.resurrection.value == 50
	)
end

-- The kit --------------------------------------------------------------------------------------

do
	local k = AbilitySim.new(SAGE)
	check("a new kit has the orb's free charge", k.charges[E] == 1 and k.charges[C] == 0 and k.charges[Q] == 0)
	check("the Barrier Orb can be bought, and the Slow Orb", AbilitySim.canBuy(k, "barrierorb") and AbilitySim.canBuy(k, "sloworb"))
	AbilitySim.fill(k, true)
	check(
		"the course fills the orb, the Slow Orb, the Barrier Orb and Resurrection's points",
		k.charges[E] == 1 and k.charges[C] == 1 and k.charges[Q] == 2 and k.points == 7
	)
	check("the kit says so", AbilitySim.summary(k, 0) == "C1/1 Q2/2 E1/1 X7/7", AbilitySim.summary(k, 0))
	k.charges[E] = 0
	AbilitySim.newRound(k)
	check("each round gives it back", k.charges[E] == 1)
end

-- In hand --------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local _, casts = step(p, B.AbilityE)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("E puts the orb in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "healingorb" and cast.slot == E)
	check("from the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "healorb" and w.back == 1)
	check("with its charge still there", kit.charges[E] == 1 and kit.holding == E)
	local waited: number? = nil
	for n = 1, ticks(2) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot)), cfg, floor, DT)
		if probed and #ofKind(probed, "heal") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be tried once its 0.5 s equip is over",
		waited ~= nil and math.abs(waited - ticks(ORB.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

do
	local p = inHand()
	local yaw, pitch = 0.4, -0.2
	local shots, casts = step(p, B.Fire, yaw, pitch)
	local try = ofKind(casts, "heal")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("fire tries it on an ally", try ~= nil and try.ability == "healingorb" and try.slot == E)
	check(
		"from the eye, along the crosshair",
		try ~= nil
			and vector.magnitude(try.origin - PlayerSim.eye(p.sim, cfg)) < 1e-6
			and vector.magnitude(try.direction - Accuracy.aim(yaw, pitch)) < 1e-6
	)
	check("as a cast, not a bullet", #shots == 0)
	check(
		"its charge kept, and the orb still in hand",
		kit.charges[E] == 1 and kit.holding == E and w.equipped == ULT and w.loadout[ULT] == "healorb"
	)
	check("ready for the next try", w.ammo[ULT] == 1)
	check("the kit says it's in hand", string.find(AbilitySim.summary(kit, now(p)), "equip", 1, true) ~= nil)
	local _, held = run(p, B.Fire, ticks(1))
	check("held, it tries no more", #ofKind(held, "heal") == 0 and kit.holding == E)
	step(p, 0)
	local _, again = step(p, B.Fire)
	check("a click tries it again", #ofKind(again, "heal") == 1 and kit.charges[E] == 1)
	run(p, 0, 2)
	local _, quick = step(p, B.Fire)
	check("but no sooner than a tenth of a second after the last", #ofKind(quick, "heal") == 0)
	run(p, 0, ticks(0.1))
	local _, later = step(p, B.Fire)
	check("and then it can", #ofKind(later, "heal") == 1)
end

do
	local p = inHand()
	local _, casts = step(p, B.AltFire)
	local try = ofKind(casts, "selfheal")[1]
	local kit = p.sim.abilities
	check("alt fire tries it on herself", try ~= nil and try.ability == "healingorb" and #ofKind(casts, "heal") == 0)
	check("its charge kept, the orb in hand", kit.charges[E] == 1 and kit.holding == E)
	check("and alt fire doesn't zoom", p.sim.weapons.scoped == 0)
end

do
	local p = inHand()
	local _, casts = step(p, B.Fire)
	local try = ofKind(casts, "heal")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	-- The server finds it heals (HealServer), between ticks.
	AbilitySim.used(kit, try.slot)
	WeaponSim.putAway(w, try.time, AbilityConfig.unequip(try.ability))
	check("a try that heals spends the charge", kit.charges[E] == 0 and kit.holding == 0)
	check(
		"and the gun's back in hand 0.7 s after it",
		w.loadout[ULT] == "" and w.equipped == 1 and near(w.equipEndTime - try.time, 0.7, 1e-9)
	)
	local _, more = run(p, B.Fire, ticks(1))
	check("nothing more is tried", #ofKind(more, "heal") == 0)
	local _, again = step(p, B.AbilityE)
	check("and with no charge left, E does nothing", #again == 0 and kit.holding == 0 and w.equipped == 1)
	local k = AbilitySim.new(SAGE)
	AbilitySim.used(k, E)
	check("spent while it's not in hand, only its charge goes", k.charges[E] == 0 and k.holding == 0)
end

do
	local p = newPlayer()
	step(p, B.AbilityE)
	run(p, 0, 10)
	local _, casts = step(p, B.AbilityE)
	local w, kit = p.sim.weapons, p.sim.abilities
	check("E again puts it away untried", #casts == 0 and kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1)
	check("its charge kept", kit.charges[E] == 1)
end

do
	local p = inHand()
	p.slot = 2
	step(p, 0)
	local w, kit = p.sim.weapons, p.sim.abilities
	check("drawing a gun puts it away", kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 2 and kit.charges[E] == 1)
end

do
	local p = newPlayer()
	step(p, B.AbilityE)
	local _, casts = run(p, B.Fire, ticks(ORB.equipTime.value) + 2)
	check("fire held from E on doesn't try it: a try's a click once it's in hand", #ofKind(casts, "heal") == 0)
	step(p, 0)
	local _, clicked = step(p, B.Fire)
	check("and the click does", #ofKind(clicked, "heal") == 1)
end

-- Who a try heals ------------------------------------------------------------------------------

do
	local eye = vector.create(0, 1.6, 0)
	local ahead = vector.create(0, 0, -1)
	local chest = vector.normalize(vector.create(0, 1.2 - 1.6, -10))
	local ally = body(7, vector.create(0, 0, -10))
	check("the crosshair on an ally heals them", HealSim.aimedAt(eye, chest, { ally }, NOTHING) == 7)
	local function off(x: number): vector
		return vector.normalize(vector.create(x, 1.2 - 1.6, -10))
	end
	check(
		"within its width of their middle it's still over them, past it not",
		HealSim.aimedAt(eye, off(0.35), { ally }, NOTHING) == 7 and HealSim.aimedAt(eye, off(0.5), { ally }, NOTHING) == nil
	)
	check("level at the eye, it's over their head", HealSim.aimedAt(eye, ahead, { ally }, NOTHING) == 7)
	local high = vector.normalize(vector.create(0, 2.3 - 1.6, -10))
	check("well over their head, it isn't", HealSim.aimedAt(eye, high, { ally }, NOTHING) == nil)
	check("nor away from them", HealSim.aimedAt(eye, -chest, { ally }, NOTHING) == nil)
	local crouched = body(8, vector.create(0, 0, -5), 1)
	local over = vector.normalize(vector.create(0, 1.7 - 1.6, -5))
	check(
		"crouched, they're shorter: the crosshair 1.7 m up over them misses, where one standing would be in it",
		HealSim.aimedAt(eye, over, { crouched }, NOTHING) == nil
			and HealSim.aimedAt(eye, over, { body(8, vector.create(0, 0, -5)) }, NOTHING) == 8
	)
	local nearRange = body(9, vector.create(0, 0, -(HO.reach.value - 1)))
	local farRange = body(9, vector.create(0, 0, -(HO.reach.value + 2)))
	check(
		"within its reach, and not past it",
		HealSim.aimedAt(eye, ahead, { nearRange }, NOTHING) == 9 and HealSim.aimedAt(eye, ahead, { farRange }, NOTHING) == nil
	)
	local front = body(1, vector.create(0, 0, -6))
	local back = body(2, vector.create(0, 0, -12))
	check("of two in line, the nearer", HealSim.aimedAt(eye, ahead, { back, front }, NOTHING) == 1)
	-- A wall between the eye and the nearer one alone.
	local hidesFront = function(_a: vector, b: vector): boolean
		return b.z > -8
	end
	check("the nearer hidden, the one behind", HealSim.aimedAt(eye, ahead, { back, front }, hidesFront) == 2)
	local hidesAll = function(_a: vector, _b: vector): boolean
		return true
	end
	check("nobody in sight, nobody", HealSim.aimedAt(eye, ahead, { back, front }, hidesAll) == nil)
	-- Only their head over a crate: one point of three in sight is enough.
	local headOnly = function(_a: vector, b: vector): boolean
		return b.y < 1.5
	end
	check("an ally whose head shows over cover is in sight", HealSim.aimedAt(eye, chest, { ally }, headOnly) == 7)
	check("and nobody to heal, nobody", HealSim.aimedAt(eye, chest, {}, NOTHING) == nil)
end

do
	check(
		"hurt is short of the most as the HUD shows it",
		HealSim.hurt(99, 100) and not HealSim.hurt(99.6, 100) and not HealSim.hurt(100, 100) and HealSim.hurt(1, 100)
	)
end

-- The heal -------------------------------------------------------------------------------------

do
	local h = HealSim.new(3, 4, HO.allyHeal.value, 10)
	check("a heal on its target by its healer", h.target == 3 and h.healer == 4 and h.total == 100)
	HealSim.step(h, 10.07, -math.huge)
	check("a point at a time", HealSim.take(h) == 1)
	HealSim.step(h, 11, -math.huge)
	check("20 a second", HealSim.take(h) == 19 and h.given == 20)
	check("taken once", HealSim.take(h) == 0)
	HealSim.step(h, 15, -math.huge)
	check("all 100 over its 5 s, and then it's over", HealSim.take(h) == 80 and h.given == 100 and HealSim.done(h))
	HealSim.step(h, 20, -math.huge)
	check("and gives no more", HealSim.take(h) == 0 and h.given == 100)
end

do
	local h = HealSim.new(3, 4, HO.allyHeal.value, 0)
	HealSim.step(h, 2, -math.huge)
	HealSim.take(h)
	HealSim.step(h, 2.9, 2)
	check("hurt, it stops for its pause", HealSim.take(h) == 0 and near(h.ran, 2, 1e-9))
	HealSim.step(h, 3.5, 2)
	check("and goes on after it", HealSim.take(h) == 10 and near(h.ran, 2.5, 1e-9))
	local h2 = HealSim.new(3, 4, HO.allyHeal.value, 0)
	local total = 0
	local t = 0
	local finished: number? = nil
	while t < 10 and not finished do
		t += 1 / 60
		local hit = if t >= 2 then 2 else -math.huge
		HealSim.step(h2, t, hit)
		total += HealSim.take(h2)
		if HealSim.done(h2) then
			finished = t
		end
	end
	check(
		"and goes on after, its clock stopped with it, so it all comes a pause later",
		total == 100 and finished ~= nil and near(finished, HO.duration.value + HO.pause.value, 1 / 60 + 1e-9),
		string.format("%d at %.3f s", total, finished or -1)
	)
	local h3 = HealSim.new(3, 4, HO.allyHeal.value, 0)
	HealSim.step(h3, 1, -math.huge)
	HealSim.step(h3, 1.5, 1.2)
	check("hurt between two steps, it runs up to the hurt and stops", near(h3.ran, 1.2, 1e-9))
	HealSim.step(h3, 2.5, 1.2)
	check("and runs again once the pause is over", near(h3.ran, 1.2 + (2.5 - 2.2), 1e-9))
end

-- The wire -------------------------------------------------------------------------------------

do
	local p = inHand()
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	check(
		"the ack carries Sage's kit, the orb in hand",
		decoded.abilities.agent == SAGE
			and decoded.abilities.holding == E
			and decoded.abilities.charges[E] == 1
			and decoded.weapons.loadout[ULT] == "healorb"
			and decoded.weapons.equipped == ULT
	)
end

return nil
