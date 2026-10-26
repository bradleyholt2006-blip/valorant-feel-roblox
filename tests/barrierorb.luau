--!strict
-- Sage's Barrier Orb (system 38): its numbers and where they come from, its
-- one charge, the orb in hand (C, its equip, fire raising its wall, the gun
-- back after, C again turning the targeter a quarter and back, alt fire
-- held keeping its facing as she turns, the turn kept until a new life, no
-- wall with nowhere to raise it or in the buy phase, the orb staying in
-- hand), where it goes (where the crosshair meets the floor, no further
-- than its range, this side of a wall, on the floor below where the aim
-- ends, each segment on its own floor or left out), the wall (rising out
-- of the floor, standing its time, a broken segment gone, one touching the
-- planted spike broken as it rises), what it does (nobody walks through
-- it, whoever's where it rises is lifted onto it, no bullet goes through
-- it, it's in the way of a sight), its health (fortified to 600 less what
-- it lost, decaying to nothing as its time's up), the simulation judging
-- it at the time given and replaying the same, and the wire carrying the
-- targeter's turn.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local BarrierSim = require("../src/shared/Abilities/BarrierSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Shop = require("../src/shared/Weapons/Shop")
local Penetration = require("../src/shared/Combat/Penetration")
local Sight = require("../src/shared/Combat/Sight")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local FakeLevel = require("./FakeLevel")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local BO = AbilityConfig.BarrierOrb
local ORB = WeaponConfig.Defs.wallorb
local ULT = WeaponSim.ULT
local C = AbilityConfig.C
local SAGE = "sage"
local QUARTER = math.pi / 2

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

-- One tick in `world` (the floor without), among the walls of `barriers`
-- (none without), the slot asked for as the client would; returns its
-- bullets and its casts.
local function step(
	p: Player,
	buttons: number,
	yaw: number?,
	pitch: number?,
	world: any?,
	barriers: BarrierSim.Walls?
): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	p.slot = ask(p.sim, p.slot)
	local shots, _, _, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, yaw, pitch), cfg, world or floor, DT, nil, nil, barriers)
	return shots or {}, casts or {}
end

local function run(p: Player, buttons: number, n: number): { AbilitySim.Cast }
	local casts = {}
	for _ = 1, n do
		local _, c = step(p, buttons)
		for _, cast in c do
			table.insert(casts, cast)
		end
	end
	return casts
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

-- Sage settled at `at` (the middle of the floor without) with the Vandal
-- drawn and her whole kit.
local function newPlayer(at: vector?, world: any?): Player
	local sim = PlayerSim.new(at or vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(SAGE)
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1 }
	for _ = 1, ticks(1.5) do
		step(p, 0, nil, nil, world)
	end
	return p
end

-- C tapped, and the orb's equip waited out.
local function inHand(at: vector?, world: any?): Player
	local p = newPlayer(at, world)
	step(p, B.AbilityC, nil, nil, world)
	for _ = 1, ticks(ORB.equipTime.value) + 1 do
		step(p, 0, nil, nil, world)
	end
	return p
end

-- The pitch that puts the crosshair on the floor `distance` metres ahead
-- of an eye `height` over it.
local function down(distance: number, height: number): number
	return -math.atan(height / distance)
end

H.section("Barrier Orb tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in BO do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Barrier Orb number says where it's from", labelled)
	local def = AbilityConfig.Defs.barrierorb
	check(
		"Sage's C, a basic ability: one charge, 300 (Patch 11.08), never free",
		def.slot == C
			and def.kind == "basic"
			and def.cost ~= nil
			and def.cost.value == 300
			and def.cost.status == "confirmed"
			and def.charges ~= nil
			and def.charges.value == 1
			and def.free == nil
			and def.recharge == nil
	)
	check("raised up to 15 m away (Patch 11.04)", BO.range.value == 15 and BO.range.status == "confirmed")
	check(
		"forming at 400 a segment (Patch 1.07), fortified to 600 2 s after it's raised (Patch 11.08)",
		BO.health.value == 400
			and BO.health.status == "confirmed"
			and BO.fortified.value == 600
			and BO.fortified.status == "confirmed"
			and BO.fortify.value == 2
			and BO.fortify.status == "confirmed"
	)
	check(
		"four segments 2.6 m long and 1.5 m thick, risen over 1.35 s, lasting 40 s and decaying from 35 (the wiki)",
		BO.segments.value == 4
			and BO.length.value == 2.6
			and BO.thickness.value == 1.5
			and BO.rise.value == 1.35
			and BO.duration.value == 40
			and BO.decay.value == 35
			and BO.segments.status == "community"
			and BO.duration.status == "community"
	)
	check("2.5 m tall, about 140% of a player's height (Dignitas)", BO.height.value == 2.5 and BO.height.status == "community")
	check(
		"0.8 s to put it in hand and 0.7 s to have the gun back (the wiki)",
		ORB.equipTime.value == 0.8 and BO.unequip.value == 0.7 and AbilityConfig.unequip("barrierorb") == 0.7
	)
	check(
		"the orb, a weapon of the fifth slot that's never reloaded, with no alt fire",
		ORB.category == "ability"
			and ORB.slot == ULT
			and ORB.ability == "barrierorb"
			and def.weapon == "wallorb"
			and ORB.magazine.value == 1
			and ORB.reserve.value == 0
			and ORB.alt == nil
			and ORB.name == "Barrier Orb"
	)
	local item = Shop.item("barrierorb")
	check(
		"its charge is sold on C, and its orb isn't",
		item ~= nil and item.kind == "ability" and item.price == 300 and item.slot == "C" and Shop.item("wallorb") == nil
	)
	check(
		"how far it looks for a floor, and how deep a segment sits, are ours",
		BO.drop.status == "estimate" and BO.climb.status == "estimate" and BO.fall.status == "estimate" and BO.sink.status == "estimate"
	)
end

-- The kit --------------------------------------------------------------------------------------

do
	local k = AbilitySim.new(SAGE)
	check("a new kit has no Barrier Orb", k.charges[C] == 0)
	check("one can be bought", AbilitySim.buy(k, "barrierorb") and k.charges[C] == 1)
	check("but not a second", not AbilitySim.canBuy(k, "barrierorb") and not AbilitySim.buy(k, "barrierorb") and k.charges[C] == 1)
	check("and it's sold back", AbilitySim.sell(k, "barrierorb") and k.charges[C] == 0)
end

-- In hand --------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local _, casts = step(p, B.AbilityC)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("C puts the orb in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "barrierorb" and cast.slot == C)
	check("from the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "wallorb" and w.back == 1)
	check("with its charge still there, and the targeter across her view", kit.charges[C] == 1 and kit.holding == C and kit.turn == 0)
	local pitch = down(5, PlayerSim.eye(p.sim, cfg).y)
	local waited: number? = nil
	for n = 1, ticks(2) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot), 0, pitch), cfg, floor, DT)
		if probed and #ofKind(probed, "barrier") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"its wall can be raised once its 0.8 s equip is over",
		waited ~= nil and math.abs(waited - ticks(ORB.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

do
	local p = inHand()
	local eye = PlayerSim.eye(p.sim, cfg)
	local shots, casts = step(p, B.Fire, 0, down(5, eye.y))
	local raised = ofKind(casts, "barrier")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	local wall = if raised then raised.wall else nil
	check("fire raises its wall", raised ~= nil and raised.ability == "barrierorb" and raised.slot == C and wall ~= nil)
	check("as a cast, not a bullet", #shots == 0)
	check(
		"where the crosshair meets the floor",
		wall ~= nil and vector.magnitude(wall.centre - vector.create(eye.x, 0, eye.z - 5)) < 1e-3,
		if wall then string.format("%.4f, %.4f, %.4f", wall.centre.x, wall.centre.y, wall.centre.z) else "none"
	)
	check("across her view", wall ~= nil and wall.angle == 0)
	check("its charge spent", kit.charges[C] == 0 and kit.holding == 0)
	check("the orb gone, and the gun back in hand", w.loadout[ULT] == "" and w.equipped == 1)
	check("ready 0.7 s after", near(w.equipEndTime - now(p), BO.unequip.value, 1e-9), string.format("%.4f s", w.equipEndTime - now(p)))
	run(p, 0, ticks(1))
	local _, none = step(p, B.AbilityC)
	check("and with none left, C does nothing", #none == 0 and kit.holding == 0 and w.equipped == 1)
end

do
	local p = newPlayer()
	step(p, B.AbilityC)
	local held = run(p, B.Fire, ticks(1))
	check("fire held as it comes into hand raises it as soon as it can", #ofKind(held, "barrier") == 1)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	local _, turned = step(p, B.AbilityC)
	check(
		"C again turns the targeter a quarter, and keeps the orb in hand",
		#turned == 0 and near(kit.turn, QUARTER, 1e-12) and kit.holding == C and w.loadout[ULT] == "wallorb" and kit.charges[C] == 1
	)
	check("which the kit says", string.find(AbilitySim.summary(kit, now(p)), "turn", 1, true) ~= nil)
	step(p, 0)
	local _, casts = step(p, B.Fire, 0.4, down(5, PlayerSim.eye(p.sim, cfg).y))
	local raised = ofKind(casts, "barrier")[1]
	local wall = if raised then raised.wall else nil
	check("so the wall runs the way she looks", wall ~= nil and near(wall.angle, 0.4 + QUARTER, 1e-12))
	if wall then
		local along = BarrierSim.axes(wall.angle)
		check("its length along her view", vector.magnitude(along - Accuracy.aim(0.4, 0)) < 1e-6)
	end
end

do
	local p = inHand()
	local kit = p.sim.abilities
	step(p, B.AbilityC)
	step(p, 0)
	step(p, B.AbilityC)
	check("and a third time back across it", kit.turn == 0 and kit.holding == C)
end

do
	local p = inHand()
	local kit = p.sim.abilities
	step(p, B.AltFire, 0)
	step(p, B.AltFire, 0.5)
	step(p, B.AltFire, 0.9)
	check(
		"alt fire held keeps the targeter facing as it did as she turns",
		kit.turning and near(BarrierSim.angle(0.9, kit.turn), 0, 1e-12) and kit.holding == C and kit.charges[C] == 1,
		string.format("%.4f", BarrierSim.angle(0.9, kit.turn))
	)
	check("and doesn't zoom", p.sim.weapons.scoped == 0)
	step(p, 0, 0.9)
	step(p, 0, 1.2)
	check("let go, the turn it's left at is kept", not kit.turning and near(kit.turn, -0.9, 1e-12))
	local _, casts = step(p, B.Fire, 1.2, down(5, PlayerSim.eye(p.sim, cfg).y))
	local raised = ofKind(casts, "barrier")[1]
	check("and the wall faces with it", raised ~= nil and raised.wall ~= nil and near(raised.wall.angle, 1.2 - 0.9, 1e-12))
	local q = inHand()
	step(q, B.AltFire, 0)
	step(q, B.AltFire, 0.3)
	step(q, B.AltFire + B.AbilityC, 0.3)
	check("C after alt fire puts it across her view again", q.sim.abilities.turn == 0, string.format("%.4f", q.sim.abilities.turn))
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	step(p, B.AbilityC)
	step(p, 0)
	p.slot = 1
	run(p, 0, ticks(1))
	check("drawing the gun puts it away unthrown", kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1 and kit.charges[C] == 1)
	step(p, B.AbilityC)
	check("and in hand again it's turned as it was", kit.holding == C and near(kit.turn, QUARTER, 1e-12))
	AbilitySim.settle(kit)
	check("until a new life or round", kit.turn == 0 and not kit.turning)
end

do
	-- Nothing but a platform under her feet: no floor for the wall.
	local platform = FakeWorld.new():addBox(vector.create(-1, -1, -1), vector.create(1, 0, 1))
	local p = inHand(nil, platform)
	local w, kit = p.sim.weapons, p.sim.abilities
	local _, casts = step(p, B.Fire, 0, down(5, PlayerSim.eye(p.sim, cfg).y), platform)
	check(
		"with no floor for it, no wall goes up, and the orb stays in hand",
		#ofKind(casts, "barrier") == 0 and kit.holding == C and kit.charges[C] == 1 and w.loadout[ULT] == "wallorb" and w.ammo[ULT] == 1
	)
	step(p, 0, 0, nil, platform)
	run(p, 0, ticks(0.2))
	local _, again = step(p, B.Fire, 0, down(5, PlayerSim.eye(p.sim, cfg).y))
	check("so it can try again where there's one", #ofKind(again, "barrier") == 1 and kit.charges[C] == 0)
end

do
	local p = inHand()
	local kit = p.sim.abilities
	local closed: BarrierSim.Walls = { walls = {}, time = 0, closed = true }
	local _, casts = step(p, B.Fire, 0, down(5, PlayerSim.eye(p.sim, cfg).y), nil, closed)
	check(
		"in the buy phase no wall goes up (Patch 1.14), and the orb stays in hand",
		#ofKind(casts, "barrier") == 0 and kit.holding == C and kit.charges[C] == 1
	)
	step(p, 0, 0, nil, nil, closed)
	run(p, 0, ticks(0.2))
	local open: BarrierSim.Walls = { walls = {}, time = 0 }
	local _, again = step(p, B.Fire, 0, down(5, PlayerSim.eye(p.sim, cfg).y), nil, open)
	check("and once it's over, it does", #ofKind(again, "barrier") == 1)
end

-- Where it goes ----------------------------------------------------------------------------------

local EYE = vector.create(0, 1.6, 0)

-- The aim from EYE, `yaw` round, at the floor `distance` metres ahead.
local function aimAt(distance: number, yaw: number?): vector
	return Accuracy.aim(yaw or 0, down(distance, EYE.y))
end

do
	local placed = BarrierSim.place(floor, EYE, aimAt(5), 0)
	check(
		"aimed at the floor, it goes where the crosshair meets it",
		placed ~= nil and vector.magnitude(placed.centre - vector.create(0, 0, -5)) < 1e-4
	)
	local xs = {}
	local fine = placed ~= nil and #placed.segments == 4
	if placed then
		for i, segment in placed.segments do
			table.insert(xs, string.format("%.2f", segment.base.x))
			fine = fine
				and segment.index == i
				and near(segment.base.x, (i - 2.5) * BO.length.value, 1e-4)
				and near(segment.base.y, 0, 1e-4)
				and near(segment.base.z, -5, 1e-4)
				and segment.broken == nil
		end
	end
	check("four segments in a row across the aim, each on the floor", fine, table.concat(xs, ", "))
	local far = BarrierSim.place(floor, EYE, aimAt(30), 0)
	local reach = if far then vector.magnitude(far.centre - vector.create(EYE.x, 0, EYE.z)) else 0
	check(
		"aimed further than its 15 m, it goes on the floor under where the aim's 15 m end",
		far ~= nil and reach > BO.range.value - 0.3 and reach <= BO.range.value and near(far.centre.y, 0, 1e-4),
		string.format("%.2f m", reach)
	)
	print(string.format("    aimed at the floor 30 m away, it goes %.2f m away", reach))
	local sky = BarrierSim.place(floor, EYE, Accuracy.aim(0, math.rad(40)), 0)
	check(
		"aimed at the sky, the same: under where the aim ends",
		sky ~= nil and near(-sky.centre.z, (BO.range.value - 0.1) * math.cos(math.rad(40)), 0.05) and near(sky.centre.y, 0, 1e-4)
	)
	check("with no floor anywhere, it goes nowhere", BarrierSim.place(FakeWorld.new(), EYE, aimAt(5), 0) == nil)
end

do
	-- A wall 4 m ahead, its face at z = -4.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-10, 0, -5), vector.create(10, 4, -4))
	local placed = BarrierSim.place(world, EYE, Accuracy.aim(0, 0), 0)
	check(
		"aimed at a wall, it goes on the floor this side of it",
		placed ~= nil and placed.centre.z > -4 and placed.centre.z < -3.8 and near(placed.centre.y, 0, 1e-4),
		if placed then string.format("z %.3f", placed.centre.z) else "none"
	)
end

do
	-- The floor stops at x = 1: past it, a drop too deep for a segment.
	local world = FakeWorld.new():addBox(vector.create(-20, -1, -20), vector.create(1, 0, 20))
	local placed = BarrierSim.place(world, EYE, aimAt(5), 0)
	local kept = {}
	if placed then
		for _, segment in placed.segments do
			table.insert(kept, tostring(segment.index))
		end
	end
	check(
		"a segment with no floor under it is left out (Patch 0.49)",
		placed ~= nil and table.concat(kept, ",") == "1,2",
		table.concat(kept, ",")
	)
	-- And a step 0.6 m up from x = 0.1, and a floor 0.8 m down past x = 2.6.
	local steps = FakeWorld.new()
		:addBox(vector.create(-20, -1, -20), vector.create(0.1, 0, 20))
		:addBox(vector.create(0.1, -1, -20), vector.create(2.6, 0.6, 20))
		:addBox(vector.create(2.6, -2, -20), vector.create(20, -0.8, 20))
	local stepped = BarrierSim.place(steps, EYE, aimAt(5), 0)
	local heights = {}
	if stepped then
		for _, segment in stepped.segments do
			table.insert(heights, string.format("%.1f", segment.base.y))
		end
	end
	check(
		"and each stands on the floor under it, a step up or down",
		table.concat(heights, ",") == "0.0,0.0,0.6,-0.8",
		table.concat(heights, ",")
	)
	-- And a crate as high as the most a segment climbs, under the fourth.
	local crate = FakeWorld.new():addFloor():addBox(vector.create(3.2, 0, -6), vector.create(4.6, BO.climb.value, -4))
	local onCrate = BarrierSim.place(crate, EYE, aimAt(5), 0)
	local top = if onCrate and #onCrate.segments == 4 then onCrate.segments[4].base.y else nil
	check(
		"one stands on a crate as high as the most it climbs, 1 m",
		top ~= nil and near(top, BO.climb.value, 1e-4),
		if top then string.format("%.2f", top) else "none"
	)
end

-- The wall ----------------------------------------------------------------------------------------

local function wallAt(distance: number, start: number, angle: number?): BarrierSim.Wall
	local placed = BarrierSim.place(floor, EYE, aimAt(distance), angle or 0)
	assert(placed, "placed")
	return BarrierSim.raise(7, 100, start, placed)
end

do
	local wall = wallAt(5, 10)
	check(
		"it rises out of the floor over 1.35 s",
		BarrierSim.risen(wall, 10) == 0
			and near(BarrierSim.risen(wall, 10 + BO.rise.value / 2), 0.5, 1e-9)
			and BarrierSim.risen(wall, 12) == 1
	)
	local box = BarrierSim.box(wall, wall.segments[2], 12)
	check(
		"each segment then a block 2.6 m by 1.5 m, from its depth under the floor up to 2.5 m",
		near(box.center.y - box.half.y, -BO.sink.value, 1e-5)
			and near(box.center.y + box.half.y, BO.height.value, 1e-5)
			and near(box.half.x, 1.3, 1e-6)
			and near(box.half.z, 0.75, 1e-6)
	)
	local segment = wall.segments[1]
	check(
		"standing from when it's raised until its 40 s are up",
		not BarrierSim.standing(wall, segment, 9.99)
			and BarrierSim.standing(wall, segment, 10)
			and BarrierSim.standing(wall, segment, 49.99)
			and not BarrierSim.standing(wall, segment, 50)
	)
	segment.broken = 20
	check(
		"or until it breaks",
		BarrierSim.standing(wall, segment, 19.99) and not BarrierSim.standing(wall, segment, 20) and #BarrierSim.pieces({ wall }, 21) == 3
	)
end

do
	local placed = BarrierSim.place(floor, EYE, aimAt(5), 0)
	assert(placed, "placed")
	-- The spike planted on the floor under the second segment's middle.
	local wall = BarrierSim.raise(7, 1, 10, placed, vector.create(-1.3, 0, -5.2))
	check(
		"a segment that would touch the planted spike breaks as it rises",
		wall.segments[2].broken == 10
			and wall.segments[1].broken == nil
			and wall.segments[3].broken == nil
			and wall.segments[4].broken == nil
	)
	local clear = BarrierSim.raise(7, 2, 10, placed, vector.create(-1.3, 0, -6.2))
	local none = true
	for _, segment in clear.segments do
		none = none and segment.broken == nil
	end
	check("and none does with the spike clear of it", none)
end

-- What it does ------------------------------------------------------------------------------------

do
	-- A wall 3 m ahead, risen: its near face at z = -2.25.
	local wall = wallAt(3, 0)
	local walls: BarrierSim.Walls = { walls = { wall }, time = 5 }
	local p = newPlayer()
	for _ = 1, ticks(2) do
		step(p, B.Forward, 0, 0, nil, walls)
	end
	local z = p.sim.movement.position.z
	check("nobody walks through it", z > -2.25 + cfg.halfWidth - 0.01 and z < -2.25 + cfg.halfWidth + 0.02, string.format("z %.3f", z))
	local q = newPlayer()
	local before: BarrierSim.Walls = { walls = { wall }, time = -1 }
	for _ = 1, ticks(2) do
		step(q, B.Forward, 0, 0, nil, before)
	end
	check("judged before it's raised, it isn't there", q.sim.movement.position.z < -6)
	local world = BarrierSim.world(floor, { wall }, 5)
	local inside = BarrierSim.box(wall, wall.segments[2], 5).center
	check(
		"a sweep from inside a segment doesn't see it, as Roblox's Blockcast doesn't see a part",
		world:sweep(inside, vector.create(0.1, 0.1, 0.1), vector.create(0, 0, 0.5)) == nil
			and world:overlaps(inside, vector.create(0.1, 0.1, 0.1))
	)
	check("and with none standing, the world's the level's alone", BarrierSim.world(floor, { wall }, 60) == floor)
end

do
	-- Standing where it's raised under her.
	local p = newPlayer(vector.create(0, 0.02, -3))
	local wall = wallAt(3, 0)
	local grounded = true
	for n = 1, ticks(BO.rise.value + 0.5) do
		step(p, 0, 0, 0, nil, { walls = { wall }, time = n * DT })
		grounded = grounded and p.sim.movement.grounded
	end
	local feet = p.sim.movement.position
	check(
		"whoever stands where it rises is lifted onto its top",
		near(feet.y, BO.height.value, 0.02) and near(feet.z, -3, 0.05) and p.sim.movement.grounded,
		string.format("%.3f, %.3f", feet.y, feet.z)
	)
	check("standing on it all the way up", grounded)
end

do
	local wall = wallAt(3, 0)
	local level = BarrierSim.level(FakeLevel.new(), { wall }, 5)
	local from = vector.create(0, 1.5, 0)
	local ahead = vector.create(0, 0, -1)
	local trace = Penetration.trace(level, from, ahead, "high", WeaponConfig.MaxRange)
	local first = trace.walls[1]
	check(
		"no bullet goes through it",
		trace.stopped and near(trace.stop, 2.25, 1e-4) and first ~= nil and first.material == "solid" and first.name == BarrierSim.SURFACE,
		string.format("%.4f m", trace.stop)
	)
	local side = Penetration.trace(level, vector.create(0.5, 1.5, 0), ahead, "high", WeaponConfig.MaxRange).walls[1]
	local piece = if side then BarrierSim.piece(side.key) else nil
	check("and what it struck is the segment in front", piece ~= nil and piece.segment == wall.segments[3] and piece.wall == wall)
	local over = Penetration.trace(level, vector.create(0, 3, 0), ahead, "high", WeaponConfig.MaxRange)
	check("over it they go on", not over.stopped)
	local soft = FakeLevel.new()
	soft:wall("soft", 1, 0.2)
	local through = Penetration.trace(BarrierSim.level(soft, { wall }, 5), from, ahead, "high", WeaponConfig.MaxRange)
	check(
		"through a thin wall in front of it, it stops them still",
		through.stopped and #through.walls == 2 and through.walls[1].material == "soft" and BarrierSim.piece(through.walls[2].key) ~= nil
	)
	check("and the level's own walls are its own", BarrierSim.piece(through.walls[1].key) == nil)
	check("with none standing, the level's the level alone", BarrierSim.level(soft, { wall }, 60) == soft)
end

do
	local wall = wallAt(3, 0)
	local a, b = vector.create(0, 1.6, 0), vector.create(0, 1.6, -6)
	check("it's in the way of a sight through it", BarrierSim.hides({ wall }, 5, a, b))
	check("but not of one that doesn't cross it", not BarrierSim.hides({ wall }, 5, a, vector.create(0, 1.6, -1.5)))
	check("nor over it", not BarrierSim.hides({ wall }, 5, vector.create(0, 3, 0), vector.create(0, 3, -6)))
	check("nor before it's raised", not BarrierSim.hides({ wall }, -1, a, b))
	local open = function(): boolean
		return false
	end
	check(
		"so nobody's seen through it (Sight)",
		Sight.hidden(a, b, { clouds = {}, walls = {}, barriers = { wall }, time = 5, blocked = open })
			and not Sight.hidden(a, b, { clouds = {}, walls = {}, barriers = { wall }, time = -1, blocked = open })
	)
end

-- Its health ----------------------------------------------------------------------------------------

do
	check("fortified, a segment has 600", BarrierSim.fortify(BO.health.value) == 600)
	check("less what it lost before (Patch 6.04)", BarrierSim.fortify(300) == 500)
	local wall = wallAt(5, 0)
	check("it decays only from 35 s", BarrierSim.decay(wall, 600, 0, 35) == 600 and BarrierSim.decay(wall, 600, 10, 20) == 600)
	check(
		"then loses its share of what's left, to nothing as its time's up",
		near(BarrierSim.decay(wall, 600, 35, 37.5), 300, 1e-9)
			and near(BarrierSim.decay(wall, 500, 36, 38), 250, 1e-9)
			and BarrierSim.decay(wall, 600, 0, 40) == 0
	)
	-- Halfway through the decay in steps, the same as at once.
	local stepped = 600
	for t = 35.5, 37.5, 0.5 do
		stepped = BarrierSim.decay(wall, stepped, t - 0.5, t)
	end
	check("in steps or at once", near(stepped, 300, 1e-9), string.format("%.6f", stepped))
	local ledge = FakeWorld.new()
		:addBox(vector.create(-20, -1, -20), vector.create(1, 0, 20))
		:addBox(vector.create(3, -1, -20), vector.create(20, 0, 20))
	local placed = BarrierSim.place(ledge, EYE, aimAt(5), 0)
	assert(placed, "placed")
	local three = BarrierSim.raise(7, 3, 0, placed)
	three.segments[2].broken = 4
	check(
		"each segment's health as scripted checks read it",
		BarrierSim.summary(three, { 600, 0, 412.4 }, 5) == "600,x,-,412",
		BarrierSim.summary(three, { 600, 0, 412.4 }, 5)
	)
	check("and all gone as its time's up", BarrierSim.summary(three, { 1, 1, 1 }, 40) == "x,x,-,x")
end

-- The wire ------------------------------------------------------------------------------------------

do
	local p = inHand()
	step(p, B.AbilityC)
	step(p, 0)
	step(p, B.AltFire, 0.25)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a = p.sim.abilities
	check(
		"the ack carries the targeter's turn",
		decoded.abilities.turn == a.turn and decoded.abilities.turning == true and decoded.abilities.fixed == a.fixed and a.turning
	)
	local copy = decoded :: PlayerSim.State
	-- On, alt fire held as she turns, then let go, then fire, with a wall
	-- ahead rising: the replay turns it, raises it and walks into the wall
	-- as the first run did.
	local wall = wallAt(3, now(p))
	local same, raised = true, 0
	for i = 1, ticks(2) do
		local buttons = if i < 40 then B.AltFire elseif i == 60 then B.Fire elseif i > 100 then B.Forward else 0
		local yaw = 0.25 + math.min(i, 50) * 0.002
		local walls: BarrierSim.Walls = { walls = { wall }, time = wall.start + i * DT }
		local _, casts = step(p, buttons, yaw, -0.3, nil, walls)
		local _, _, _, _, again = PlayerSim.step(copy, input(buttons, p.slot, yaw, -0.3), cfg, floor, DT, nil, nil, walls)
		raised += #ofKind(casts, "barrier")
		same = same
			and copy.abilities.turn == p.sim.abilities.turn
			and #ofKind(again or {}, "barrier") == #ofKind(casts, "barrier")
			and copy.movement.position == p.sim.movement.position
	end
	check("and a replay from it goes as it did, to the bit", same and raised == 1)
end

return nil
