--!strict
-- Omen's Shrouded Step (system 42): its numbers and where they come from, its
-- two charges, its mark in hand (C, its equip, C again putting it away, fire
-- with nowhere to step leaving it in hand), the step (fire spending its
-- charge and starting the windup, through which he can't move, fire, cast or
-- start a defuse though he falls on as he was, then gone and held on the
-- floor it marked, then there and free, his gun back a moment after), where
-- it takes him (where the crosshair meets the floor, no further than its
-- range, the floor below where the aim ends, this side of a wall and clear of
-- it, onto a crate, drawn back from the foot of a wall, nowhere under a low
-- ceiling, out of his sight over a tall wall or with no floor, but behind a
-- crate), a new life ending it, and the wire carrying it so a replay comes
-- back the same.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local StepSim = require("../src/shared/Abilities/StepSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Shop = require("../src/shared/Weapons/Shop")
local Spike = require("../src/shared/Spike/Spike")
local SpikeSim = require("../src/shared/Spike/SpikeSim")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local SS = AbilityConfig.ShroudedStep
local MARK = WeaponConfig.Defs.stepmark
local ULT = WeaponSim.ULT
local C = AbilityConfig.C
local OMEN = "omen"
local FEET = vector.create(0, 0.02, 0)

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player, the slot their client asks for, and the way they look.
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

-- One tick with `buttons` held and the spike as `objective` allows;
-- returns its bullets, its casts and what happened with the spike.
local function step(p: Player, buttons: number, objective: Spike.Context?): ({ WeaponSim.Shot }, { AbilitySim.Cast }, SpikeSim.Act?)
	p.slot = ask(p.sim, p.slot)
	local shots, _, act, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, p.yaw, p.pitch), cfg, p.world, DT, objective)
	return shots or {}, casts or {}, act
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

-- Omen settled at `at` (FEET without) in `world` (the floor without), the
-- Vandal drawn and his whole kit.
local function newPlayer(at: vector?, world: any?, loadout: { string }?): Player
	local sim = PlayerSim.new(at or FEET, loadout or { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(OMEN)
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1, yaw = 0, pitch = 0, world = world or floor }
	run(p, 0, ticks(1.5))
	return p
end

-- C tapped, and its equip waited out.
local function inHand(at: vector?, world: any?): Player
	local p = newPlayer(at, world)
	step(p, B.AbilityC)
	run(p, 0, ticks(MARK.equipTime.value) + 1)
	return p
end

-- The pitch that puts the crosshair on the floor `distance` metres ahead
-- of an eye `height` over it.
local function down(distance: number, height: number): number
	return -math.atan(height / distance)
end

-- Fired at the floor `distance` metres ahead: the step's cast, if any.
local function fire(p: Player, distance: number): AbilitySim.Cast?
	p.pitch = down(distance, PlayerSim.eye(p.sim, cfg).y)
	local _, casts = step(p, B.Fire)
	return ofKind(casts, "step")[1]
end

H.section("Shrouded Step tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in SS do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Shrouded Step number says where it's from", labelled)
	local def = AbilityConfig.Defs.shroudedstep
	check(
		"Omen's C, a basic ability: two charges at 100 (Patch 4.04), never free",
		def.slot == C
			and def.kind == "basic"
			and def.cost ~= nil
			and def.cost.value == 100
			and def.cost.status == "confirmed"
			and def.charges ~= nil
			and def.charges.value == 2
			and def.free == nil
			and def.recharge == nil
			and AbilitySim.playable("shroudedstep")
	)
	check("a windup of 0.7 s (Patch 4.04)", SS.windup.value == 0.7 and SS.windup.status == "confirmed")
	check(
		"15 m at most, gone 0.5 s, 0.5 s to put in hand and 0.7 s to have the gun back (the wiki)",
		SS.range.value == 15
			and SS.range.status == "community"
			and SS.away.value == 0.5
			and SS.away.status == "community"
			and MARK.equipTime.value == 0.5
			and SS.unequip.value == 0.7
	)
	check(
		"the gun back 1.9 s after it's fired: the windup, his time gone and the draw",
		near(AbilityConfig.unequip("shroudedstep"), 1.9, 1e-12)
	)
	check(
		"its mark, a weapon of the fifth slot that's never reloaded, with no alt fire",
		MARK.category == "ability"
			and MARK.slot == ULT
			and MARK.ability == "shroudedstep"
			and def.weapon == "stepmark"
			and MARK.magazine.value == 1
			and MARK.reserve.value == 0
			and MARK.alt == nil
			and MARK.name == "Shrouded Step"
	)
	local item = Shop.item("shroudedstep")
	check(
		"its charges are sold on C, and its mark isn't",
		item ~= nil and item.kind == "ability" and item.price == 100 and item.slot == "C" and Shop.item("stepmark") == nil
	)
	check(
		"how far below the aim it looks for a floor, how high it can put him, and the server's grace, are ours",
		SS.drop.status == "estimate" and SS.above.status == "estimate" and SS.grace.status == "estimate"
	)
end

-- The kit --------------------------------------------------------------------------------------

do
	local k = AbilitySim.new(OMEN)
	check("a new kit has no Shrouded Step", k.charges[C] == 0)
	check("two can be bought", AbilitySim.buy(k, "shroudedstep") and AbilitySim.buy(k, "shroudedstep") and k.charges[C] == 2)
	check("but not a third", not AbilitySim.canBuy(k, "shroudedstep") and k.charges[C] == 2)
	check("and they're sold back", AbilitySim.sell(k, "shroudedstep") and k.charges[C] == 1)
end

-- In hand --------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local _, casts = step(p, B.AbilityC)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("C puts its mark in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "shroudedstep" and cast.slot == C)
	check("from the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "stepmark" and w.back == 1)
	check("with both charges still there", kit.charges[C] == 2 and kit.holding == C)
	local pitch = down(5, PlayerSim.eye(p.sim, cfg).y)
	local waited: number? = nil
	for n = 1, ticks(1.5) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot), 0, pitch), cfg, floor, DT)
		if probed and #ofKind(probed, "step") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be fired once its 0.5 s equip is over",
		waited ~= nil and math.abs(waited - ticks(MARK.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	step(p, B.AbilityC)
	run(p, 0, ticks(1))
	check("C again puts it away, nothing spent", kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1 and kit.charges[C] == 2)
end

-- The step -------------------------------------------------------------------------------------

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	local from = p.sim.movement.position
	local eye = PlayerSim.eye(p.sim, cfg)
	p.pitch = down(5, eye.y)
	local shots, casts = step(p, B.Fire)
	local fired = now(p)
	local cast = ofKind(casts, "step")[1]
	local to = if cast then cast.step else nil
	check("fire steps", cast ~= nil and cast.ability == "shroudedstep" and cast.slot == C)
	check("as a cast, not a bullet", #shots == 0)
	check(
		"to where the crosshair meets the floor",
		to ~= nil and vector.magnitude(to - vector.create(eye.x, 0, eye.z - 5)) < 1e-3,
		if to then string.format("%.4f, %.4f, %.4f", to.x, to.y, to.z) else "none"
	)
	check("from where he stood", cast ~= nil and cast.position == from)
	check("a charge spent, and its mark gone", kit.charges[C] == 1 and kit.holding == 0 and w.loadout[ULT] == "")
	check("the gun's put away until 1.9 s after", near(w.equipEndTime - fired, 1.9, 1e-9), string.format("%.4f s", w.equipEndTime - fired))
	check(
		"its windup's under way, which the kit says",
		AbilitySim.stepping(kit, fired + DT)
			and AbilitySim.shrouding(kit, fired + DT)
			and AbilitySim.busy(kit, fired + DT)
			and string.find(AbilitySim.summary(kit, fired + DT), "step", 1, true) ~= nil
	)

	-- Through the windup: forward held, fire, and every ability key.
	local held = true
	local still = true
	local nothing = true
	local vanished: AbilitySim.Cast? = nil
	local vanishedAt = 0
	local keys = { B.Forward + B.Fire, B.Forward + B.AbilityQ, B.Forward + B.AbilityE, B.Forward + B.AbilityC, B.Forward + B.Jump }
	local n = 0
	while not vanished and n < ticks(2) do
		n += 1
		local s, c = step(p, keys[n % #keys + 1])
		vanished = ofKind(c, "vanish")[1]
		if vanished then
			vanishedAt = now(p)
			nothing = nothing and #s == 0 and #c == 1
		else
			nothing = nothing and #s == 0 and #c == 0
			still = still and vector.magnitude(p.sim.movement.position - from) < 1e-6
			held = held and AbilitySim.shrouding(kit, now(p))
		end
	end
	check("through its windup he doesn't move", still)
	check("nor fire, nor cast anything", nothing and held and kit.charges[C] == 1)
	check(
		"and once its 0.7 s are up he's gone",
		vanished ~= nil and vanishedAt - fired >= SS.windup.value - 1e-9 and vanishedAt - fired < SS.windup.value + DT,
		string.format("%.4f s", vanishedAt - fired)
	)
	check("from where he was, to where it marked", vanished ~= nil and vanished.position == from and vanished.step == to)
	check(
		"standing on that floor at once",
		to ~= nil and p.sim.movement.position == to and p.sim.movement.grounded and p.sim.movement.velocity == vector.zero
	)
	check(
		"gone, which the kit says",
		AbilitySim.shrouded(kit, vanishedAt)
			and not AbilitySim.shrouding(kit, vanishedAt)
			and string.find(AbilitySim.summary(kit, vanishedAt), "shroud", 1, true) ~= nil
	)

	-- Gone: held where it took him.
	local arrived: AbilitySim.Cast? = nil
	local arrivedAt = 0
	local stayed = true
	n = 0
	while not arrived and n < ticks(2) do
		n += 1
		local _, c = step(p, B.Forward + B.Jump)
		arrived = ofKind(c, "arrive")[1]
		if arrived then
			arrivedAt = now(p)
		else
			stayed = stayed and to ~= nil and p.sim.movement.position == to
		end
	end
	check("gone, he's held there, nothing he presses moving him", stayed)
	check(
		"and 0.5 s later he's there",
		arrived ~= nil and arrivedAt - vanishedAt >= SS.away.value - DT and arrivedAt - vanishedAt <= SS.away.value + DT,
		string.format("%.4f s", arrivedAt - vanishedAt)
	)
	check(
		"the step over, and him free from that tick",
		arrived ~= nil
			and to ~= nil
			and arrived.position == to
			and not AbilitySim.stepping(kit, arrivedAt)
			and kit.stepAt == 0
			and vector.magnitude(p.sim.movement.position - to) > 0
	)
	check("the gun not yet back", w.equipped == 1 and now(p) < w.equipEndTime)
	run(p, 0, ticks(SS.unequip.value) + 1)
	check("and back in hand 0.7 s after he's there", now(p) >= w.equipEndTime and w.equipped == 1)
end

do
	-- Fired with a step left: the second.
	local p = inHand()
	fire(p, 5)
	run(p, 0, ticks(1.3))
	step(p, B.AbilityC)
	run(p, 0, ticks(MARK.equipTime.value) + 1)
	local second = fire(p, 4)
	check("the second charge steps again", second ~= nil and p.sim.abilities.charges[C] == 0)
	run(p, 0, ticks(1.3))
	local _, none = step(p, B.AbilityC)
	check("and with none left, C does nothing", #none == 0 and p.sim.abilities.holding == 0)
end

do
	-- Jumped, and fired as he rises: he goes up and comes down on as he was.
	local p = inHand()
	step(p, B.Jump)
	run(p, 0, 3)
	local before = p.sim.movement.position.y
	local cast = fire(p, 5)
	run(p, 0, ticks(0.2))
	check(
		"fired in the air, through its windup he rises and falls on as he was",
		cast ~= nil and p.sim.movement.position.y ~= before and AbilitySim.shrouding(p.sim.abilities, now(p))
	)
end

do
	-- Nothing but a platform under his feet: no floor below where the aim
	-- ends.
	local platform = FakeWorld.new():addBox(vector.create(-1, -1, -1), vector.create(1, 0, 1))
	local p = inHand(nil, platform)
	local w, kit = p.sim.weapons, p.sim.abilities
	local cast = fire(p, 5)
	check(
		"with nowhere to step, nothing happens, and its mark stays in hand",
		cast == nil and kit.holding == C and kit.charges[C] == 2 and w.loadout[ULT] == "stepmark" and w.ammo[ULT] == 1 and kit.stepAt == 0
	)
	run(p, 0, ticks(0.2))
	p.world = floor
	check("so it can try again where there's one", fire(p, 5) ~= nil and kit.charges[C] == 1)
end

do
	-- The spike planted a metre ahead: no defuse starts through its windup.
	local ctx: Spike.Context = {
		zones = Spike.CourseSites,
		canPlant = false,
		canDefuse = true,
		planted = vector.create(0, 0, -1),
		halfSaved = false,
	}
	local p = inHand()
	local probe = PlayerSim.copy(p.sim)
	PlayerSim.step(probe, input(B.Use, ask(p.sim, p.slot)), cfg, floor, DT, ctx)
	check("standing there, Use would start a defuse", probe.spike.channel == SpikeSim.DEFUSING)
	fire(p, 3)
	local defusing = false
	for _ = 1, ticks(0.5) do
		step(p, B.Use, ctx)
		defusing = defusing or p.sim.spike.channel ~= SpikeSim.NONE
	end
	check("but through its windup none starts", not defusing and AbilitySim.shrouding(p.sim.abilities, now(p)))
end

-- Where it takes him ------------------------------------------------------------------------------

local EYE = vector.create(0, 1.6, 0)
local GAP = cfg.halfWidth

-- The aim from EYE, `yaw` round, at the floor `distance` metres ahead.
local function aimAt(distance: number, yaw: number?): vector
	return Accuracy.aim(yaw or 0, down(distance, EYE.y))
end

-- How far along the floor `to` is from under EYE.
local function along(to: vector): number
	return vector.magnitude(vector.create(to.x - EYE.x, 0, to.z - EYE.z))
end

do
	local to = StepSim.place(floor, EYE, aimAt(5), cfg)
	check(
		"aimed at the floor, he steps where the crosshair meets it",
		to ~= nil and vector.magnitude(to - vector.create(0, 0, -5)) < 1e-4,
		if to then string.format("%.4f, %.4f, %.4f", to.x, to.y, to.z) else "none"
	)
	local turned = StepSim.place(floor, EYE, aimAt(5, 1), cfg)
	check(
		"whichever way he looks",
		turned ~= nil and vector.magnitude(turned - vector.create(-5 * math.sin(1), 0, -5 * math.cos(1))) < 1e-4
	)
	local far = StepSim.place(floor, EYE, aimAt(30), cfg)
	local reach = if far then along(far) else 0
	check(
		"aimed further than its 15 m, onto the floor under where the aim's 15 m end",
		far ~= nil and reach > SS.range.value - 0.3 and reach <= SS.range.value and near(far.y, 0, 1e-4),
		string.format("%.2f m", reach)
	)
	print(string.format("    aimed at the floor 30 m away, he steps %.2f m", reach))
	local sky = StepSim.place(floor, EYE, Accuracy.aim(0, math.rad(40)), cfg)
	local high = if sky then along(sky) else 0
	check(
		"aimed into the sky, onto the floor below where the aim ends",
		sky ~= nil and near(sky.y, 0, 1e-4) and math.abs(high - SS.range.value * math.cos(math.rad(40))) < 0.2,
		string.format("%.2f m", high)
	)
	check(
		"where the aim ends, for the targeter: its 15 m along it",
		vector.magnitude(StepSim.ends(floor, EYE, Accuracy.aim(0, 0)) - vector.create(0, EYE.y, -15)) < 1e-6
	)
end

do
	-- A wall across the way, 5 m ahead and 3 m tall.
	local walled = FakeWorld.new():addFloor():addBox(vector.create(-6, 0, -5.5), vector.create(6, 3, -5))
	local level = StepSim.place(walled, EYE, Accuracy.aim(0, 0), cfg)
	check(
		"aimed at a wall, onto the floor this side of it, his body clear of it",
		level ~= nil and near(level.y, 0, 1e-4) and level.z > -5 + GAP - 1e-6 and level.z < -4,
		if level then string.format("%.3f m from it", level.z + 5) else "none"
	)
	check("where he fits", level ~= nil and StepSim.fits(walled, level, cfg))
	local past = StepSim.place(walled, EYE, aimAt(8), cfg)
	check("aimed at the floor past it, never through it", past ~= nil and past.z > -5)
	local foot = StepSim.place(walled, EYE, aimAt(4.9), cfg)
	check(
		"aimed at its foot, drawn back until he fits",
		foot ~= nil and foot.z > -5 + GAP - 1e-6 and foot.z < -4.5 and StepSim.fits(walled, foot, cfg),
		if foot then string.format("%.3f m from it", foot.z + 5) else "none"
	)
	check("where he wouldn't fit, he isn't put", not StepSim.fits(walled, vector.create(0, 0, -4.9), cfg))
end

do
	-- A crate a metre tall, 4 to 6 m ahead.
	local crated = FakeWorld.new():addFloor():addBox(vector.create(-1, 0, -6), vector.create(1, 1, -4))
	local pitch = -math.atan((EYE.y - 1) / 5)
	local top = StepSim.place(crated, EYE, Accuracy.aim(0, pitch), cfg)
	check(
		"aimed at a crate's top, onto it",
		top ~= nil and near(top.y, 1, 1e-4) and math.abs(top.z + 5) < 1e-3,
		if top then string.format("%.4f, %.4f, %.4f", top.x, top.y, top.z) else "none"
	)
	-- A ledge lower than a step, beside where he'd stand.
	local ledge = FakeWorld.new():addFloor():addBox(vector.create(0.1, 0, -1), vector.create(2, cfg.stepHeight - 0.05, 1))
	check("a ledge lower than a step's in nobody's way", StepSim.fits(ledge, vector.zero, cfg))
end

do
	-- A wall 5 m tall a metre ahead, as the spike maps' walls and the buy
	-- phase's barriers are.
	local tall = FakeWorld.new():addFloor():addBox(vector.create(-6, 0, -1.5), vector.create(6, 5, -1))
	local up = Accuracy.aim(0, math.rad(75))
	local ends = StepSim.ends(tall, EYE, up)
	local below = vector.create(ends.x, 0, ends.z)
	check(
		"aimed steeply up, the aim ends over the wall, with room for him on the floor below",
		ends.z < -1.5 and ends.y > 5 and StepSim.fits(tall, below, cfg)
	)
	check(
		"but he'd be out of sight there, so there's nowhere",
		not StepSim.sees(tall, EYE, below, cfg) and StepSim.place(tall, EYE, up, cfg) == nil
	)
	-- The crate again, the aim over it into the sky.
	local crated = FakeWorld.new():addFloor():addBox(vector.create(-1, 0, -6), vector.create(1, 1, -4))
	local behind = StepSim.place(crated, EYE, Accuracy.aim(0, math.rad(40)), cfg)
	local hidden = behind ~= nil and crated:sweep(EYE, vector.create(0.01, 0.01, 0.01), behind + vector.create(0, 0.05, 0) - EYE) ~= nil
	check(
		"the floor behind a crate out of sight, but he'd be in sight standing there: he steps there",
		behind ~= nil and behind.z < -6 and hidden and StepSim.sees(crated, EYE, behind, cfg)
	)
	-- A barrier 5 m tall and 0.2 m thick, 2.5 m ahead, as the buy phase's.
	local barred = FakeWorld.new():addFloor():addBox(vector.create(-2, 0, -2.7), vector.create(2, 5, -2.5))
	local steep = Accuracy.aim(0, math.rad(80))
	local over = StepSim.ends(barred, EYE, steep)
	local top = vector.create(over.x, 5, over.z)
	check(
		"aimed up so steeply the aim ends over its top, with room for him on it and in sight there",
		over.z < -2.5 and over.z > -2.7 and StepSim.fits(barred, top, cfg) and StepSim.sees(barred, EYE, top, cfg)
	)
	check(
		"but no floor more than 1 m over his eye: nowhere",
		SS.above.value == 1 and top.y > EYE.y + SS.above.value and StepSim.place(barred, EYE, steep, cfg) == nil
	)
	-- A crate 2.0 m tall, as the maps' high crates, 4 to 6 m ahead.
	local high = FakeWorld.new():addFloor():addBox(vector.create(-1, 0, -6), vector.create(1, 2, -4))
	local onto = StepSim.place(high, EYE, Accuracy.aim(0, math.rad(70)), cfg)
	check(
		"aimed up over a crate 2.0 m tall, onto its top",
		onto ~= nil and near(onto.y, 2, 1e-4),
		if onto then string.format("%.3f, %.3f, %.3f", onto.x, onto.y, onto.z) else "none"
	)
end

do
	-- A slab 1.2 m over the floor, from 3 to 8 m ahead: too low to stand
	-- under.
	local low = FakeWorld.new():addFloor():addBox(vector.create(-6, 1.2, -8), vector.create(6, 1.5, -3))
	check("under a ceiling lower than he stands there's nowhere", StepSim.place(low, EYE, aimAt(5), cfg) == nil)
	local platform = FakeWorld.new():addBox(vector.create(-1, -1, -1), vector.create(1, 0, 1))
	check("nor with no floor below where the aim ends", StepSim.place(platform, EYE, aimAt(5), cfg) == nil)
	local deep = FakeWorld.new():addBox(vector.create(-30, -30, -30), vector.create(30, -25, 30))
	check(
		"nor where the floor's further below than it looks",
		StepSim.place(deep, EYE, Accuracy.aim(0, 0), cfg) == nil and SS.drop.value < 25
	)
end

-- A new life ----------------------------------------------------------------------------------

do
	local p = inHand()
	fire(p, 5)
	local kit = p.sim.abilities
	run(p, 0, ticks(0.9))
	AbilitySim.settle(kit)
	check("a new life or round ends it", kit.stepAt == 0 and kit.stepTo == vector.zero and not AbilitySim.stepping(kit, now(p)))
end

-- The wire -------------------------------------------------------------------------------------

do
	local p = inHand(vector.create(1, 0.02, 4))
	p.yaw = -0.7
	fire(p, 6)
	run(p, B.Forward, ticks(0.3))
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a, b = p.sim.abilities, decoded.abilities
	check("the ack carries its windup and where it takes him", b.stepAt == a.stepAt and b.stepTo == a.stepTo and a.stepAt > 0)
	local copy: Player = { sim = decoded :: PlayerSim.State, slot = p.slot, yaw = p.yaw, pitch = p.pitch, world = floor }
	local same, steps = true, 0
	for i = 1, ticks(2.5) do
		local buttons = if i % 40 < 20 then B.Forward else B.Left + B.Fire
		local _, c1 = step(p, buttons)
		local _, c2 = step(copy, buttons)
		steps += #ofKind(c1, "vanish") + #ofKind(c1, "arrive")
		same = same
			and #c1 == #c2
			and p.sim.movement.position == copy.sim.movement.position
			and p.sim.weapons.equipEndTime == copy.sim.weapons.equipEndTime
	end
	check("and a replay from it goes and arrives as it does", same and steps == 2)

	local q = inHand()
	fire(q, 5)
	run(q, 0, ticks(SS.windup.value + 0.2))
	local _, gone = PlayerCodec.decodeAck(PlayerCodec.encodeAck(10, q.sim))
	check("the ack carries him gone", AbilitySim.shrouded(gone.abilities, now(q)) and gone.movement.position == q.sim.movement.position)
	local left: Player = { sim = gone :: PlayerSim.State, slot = q.slot, yaw = q.yaw, pitch = q.pitch, world = floor }
	local alike = true
	for _ = 1, ticks(1) do
		local _, c1 = step(q, B.Forward)
		local _, c2 = step(left, B.Forward)
		alike = alike and #c1 == #c2 and q.sim.movement.position == left.sim.movement.position
	end
	check("and a replay from it arrives where it does", alike)
end

return nil
