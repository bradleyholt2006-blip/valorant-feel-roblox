--!strict
-- Phoenix's Blaze (system 32): its numbers and where they come from, its
-- charge, the flame in hand (C, its equip, fire sending the wall out from
-- the feet, the flame held while fire is, bending it, the gun back once it's
-- let go or the run's over, C again putting it away unsent, and whatever
-- else is drawn letting go of it), its run (along the floor at its speed
-- for its flight, bending towards the crosshair at its turn rate and
-- straight on once let go, up what's lower than its hover and through
-- what's taller, down a ledge, ending where it finds no floor), its wall
-- (rising from his end and spreading to the far end, standing for its
-- duration, as thick, tall and deep as it is), the burn and the heal by
-- the point, and the wire carrying a wall being bent.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local BlazeSim = require("../src/shared/Abilities/BlazeSim")
local FireSim = require("../src/shared/Abilities/FireSim")
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
local BZ = AbilityConfig.Blaze
local IF = AbilityConfig.InnerFire
local FLAME = WeaponConfig.Defs.flamewall
local ULT = WeaponSim.ULT
local C, Q = AbilityConfig.C, AbilityConfig.Q
local PHOENIX = "phoenix"

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player, the slot their client asks for, and their runs under way, run
-- after each of their ticks as the server runs them (BlazeServer), with
-- those that are over.
type Player = { sim: PlayerSim.State, slot: number, runs: { BlazeSim.Run }, over: { BlazeSim.Run } }

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

-- One tick, the slot asked for as the client would, and the runs after it;
-- returns its bullets and its casts.
local function step(p: Player, buttons: number, yaw: number?, pitch: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	p.slot = ask(p.sim, p.slot)
	local i = input(buttons, p.slot, yaw, pitch)
	local shots, _, _, _, casts = PlayerSim.step(p.sim, i, cfg, floor, DT)
	for _, r in BlazeSim.tick(p.runs, 1, i, casts, p.sim.abilities.steering ~= 0, DT, floor) do
		table.insert(p.over, r)
	end
	return shots or {}, casts or {}
end

local function run(p: Player, buttons: number, n: number, yaw: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	local shots, casts = {}, {}
	for _ = 1, n do
		local s, c = step(p, buttons, yaw)
		for _, shot in s do
			table.insert(shots, shot)
		end
		for _, cast in c do
			table.insert(casts, cast)
		end
	end
	return shots, casts
end

-- A number key, as PlayerController.selectSlot takes it.
local function press(p: Player, slot: number)
	if p.sim.weapons.loadout[slot] ~= "" then
		p.slot = slot
	end
end

local function now(p: Player): number
	return p.sim.movement.tick * DT
end

-- Phoenix settled on the floor with the Vandal drawn and every charge.
local function newPlayer(): Player
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(PHOENIX)
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1, runs = {}, over = {} }
	run(p, 0, ticks(1.5))
	return p
end

-- C tapped, and the flame's equip waited out.
local function inHand(): Player
	local p = newPlayer()
	step(p, B.AbilityC)
	run(p, 0, ticks(FLAME.equipTime.value) + 1)
	return p
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

-- Level distance between two points.
local function flat(a: vector, b: vector): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

H.section("Blaze tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in BZ do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Blaze number says where it's from", labelled and #IF.blazeEvery.source > 0)
	local def = AbilityConfig.Defs.blaze
	check(
		"150 a charge (Patch 5.12), one of them, none free",
		def.cost ~= nil
			and def.cost.value == 150
			and def.cost.status == "confirmed"
			and def.charges ~= nil
			and def.charges.value == 1
			and def.free == nil
	)
	check(
		"it stands 8 s and burns 30 a second (Patch 1.0)",
		BZ.duration.value == 8 and BZ.duration.status == "confirmed" and BZ.burn.value == 30 and BZ.burn.status == "confirmed"
	)
	check(
		"Inner Fire gives its 50 from it a point every 0.16 s (Patch 1.0), half Hot Hands' pace",
		IF.blazeEvery.value == 0.16 and IF.blazeEvery.status == "confirmed" and near(IF.blazeEvery.value, 2 * IF.hotHandsEvery.value, 1e-12)
	)
	check(
		"up to 21 m in up to 0.75 s (the wiki), so 28 m a second",
		BZ.length.value == 21 and BZ.flight.value == 0.75 and near(BlazeSim.speed(), 28, 1e-9)
	)
	check(
		"0.8 s to put it in hand and 0.5 s to have the gun back (the wiki)",
		FLAME.equipTime.value == 0.8 and BZ.unequip.value == 0.5 and AbilityConfig.unequip("blaze") == 0.5
	)
	check(
		"the flame, a weapon of the fifth slot that's never reloaded, with no alt fire, and Blaze's",
		FLAME.category == "ability"
			and FLAME.slot == ULT
			and FLAME.ability == "blaze"
			and def.weapon == "flamewall"
			and FLAME.magazine.value == 1
			and FLAME.reserve.value == 0
			and FLAME.alt == nil
			and FLAME.name == "Blaze"
	)
	local item = Shop.item("blaze")
	check(
		"Blaze's charge is sold on C, the flame never",
		item ~= nil and item.price == 150 and item.slot == "C" and Shop.item("flamewall") == nil
	)
end

-- The kit --------------------------------------------------------------------------------------

do
	local k = AbilitySim.new(PHOENIX)
	check("it can be played", AbilitySim.playable("blaze"))
	check("a new kit has no Blaze", k.charges[C] == 0)
	check("one can be bought", AbilitySim.canBuy(k, "blaze") and AbilitySim.buy(k, "blaze") and k.charges[C] == 1)
	check("but not a second", not AbilitySim.buy(k, "blaze") and k.charges[C] == 1)
	check("and sold back", AbilitySim.sell(k, "blaze") and k.charges[C] == 0)
	AbilitySim.fill(k)
	check("the course fills it", k.charges[C] == 1)
end

-- In hand --------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local _, casts = step(p, B.AbilityC)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("C puts the flame in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "blaze" and cast.slot == C)
	check("from the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "flamewall" and w.back == 1)
	check("with nothing spent or sent yet", kit.charges[C] == 1 and kit.holding == C and kit.steering == 0 and #p.runs == 0)
	local waited: number? = nil
	for n = 1, ticks(2) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot)), cfg, floor, DT)
		if probed and #ofKind(probed, "flame") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be sent once its 0.8 s equip is over",
		waited ~= nil and math.abs(waited - ticks(FLAME.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

-- Sent out -------------------------------------------------------------------------------------

do
	local p = inHand()
	local yaw, pitch = 0.4, -0.3
	local shots, casts = step(p, B.Fire, yaw, pitch)
	local sent = ofKind(casts, "flame")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("fire sends the wall out", sent ~= nil and sent.ability == "blaze" and sent.slot == C)
	check(
		"from the feet, the way the crosshair faces",
		sent ~= nil
			and vector.magnitude(sent.position - p.sim.movement.position) < 1e-9
			and vector.magnitude(sent.direction - Accuracy.aim(yaw, pitch)) < 1e-6
	)
	check("as a cast, not a bullet", #shots == 0 and sent ~= nil and sent.curve == nil and sent.lob == nil)
	check("its charge spent", kit.charges[C] == 0 and kit.holding == 0)
	check("bent from then for its flight", kit.steering == C and near(kit.steerUntil - now(p), BZ.flight.value, 1e-9))
	check("the flame still in hand", w.loadout[ULT] == "flamewall" and w.equipped == ULT)
	check("the kit says so", string.find(AbilitySim.summary(kit, now(p)), "bend", 1, true) ~= nil)
	check("and its run under way", #p.runs == 1 and p.runs[1].id == sent.tick and p.runs[1].owner == 1)
	-- Fire held on: the flame stays in hand for the run's flight.
	local held, more = 0, 0
	while kit.steering ~= 0 and held < ticks(2) do
		local s, c = step(p, B.Fire, yaw, pitch)
		more += #s + #ofKind(c, "flame")
		held += 1
	end
	check(
		"held, the flame stays in hand until the run's over",
		held == ticks(BZ.flight.value) and #p.runs == 0 and #p.over == 1,
		string.format("%d ticks", held)
	)
	check("sending nothing more", more == 0)
	check("then it's gone, and the gun's back in hand", w.loadout[ULT] == "" and w.equipped == 1)
	check("ready 0.5 s after", near(w.equipEndTime - now(p), BZ.unequip.value, 1e-9), string.format("%.4f s", w.equipEndTime - now(p)))
	local _, again = step(p, B.AbilityC)
	check("and with no charge left, C does nothing", #again == 0 and kit.holding == 0 and w.equipped == 1)
end

do
	local p = inHand()
	step(p, B.Fire)
	local w, kit = p.sim.weapons, p.sim.abilities
	step(p, 0)
	check("tapped, it's let go at once", kit.steering == 0 and w.loadout[ULT] == "" and w.equipped == 1)
	check("and the gun's ready 0.5 s after", near(w.equipEndTime - now(p), BZ.unequip.value, 1e-9))
	check("its run going on by itself", #p.runs == 1)
end

do
	local p = newPlayer()
	step(p, B.AbilityC)
	local _, casts = run(p, B.Fire, ticks(FLAME.equipTime.value) + 2)
	check(
		"fire held from C on sends it as soon as it's in hand, and bends it",
		#ofKind(casts, "flame") == 1 and p.sim.abilities.steering == C
	)
end

do
	local p = inHand()
	local _, casts = step(p, B.AltFire)
	local kit = p.sim.abilities
	check("alt fire doesn't send it", #ofKind(casts, "flame") == 0 and kit.charges[C] == 1 and kit.holding == C)
	check("or zoom", p.sim.weapons.scoped == 0)
end

do
	local p = newPlayer()
	step(p, B.AbilityC)
	run(p, 0, 10)
	local _, casts = step(p, B.AbilityC)
	local w, kit = p.sim.weapons, p.sim.abilities
	check("C again puts it away unsent", #casts == 0 and kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1)
	check("its charge kept", kit.charges[C] == 1)
end

do
	local p = newPlayer()
	step(p, B.AbilityC)
	run(p, 0, 10)
	local _, toBall = step(p, B.AbilityQ)
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"Q with the flame in hand puts the fireball there instead",
		#toBall == 1 and toBall[1].ability == "hothands" and kit.holding == Q and w.loadout[ULT] == "fireball" and w.equipped == ULT
	)
	check("both charges kept", kit.charges[C] == 1 and kit.charges[Q] == 1)
end

do
	local p = inHand()
	step(p, B.Fire)
	run(p, B.Fire, 20)
	local _, toBall = step(p, B.Fire + B.AbilityQ)
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"Q while it's bent lets go of it, and puts the fireball in hand",
		#toBall == 1 and kit.steering == 0 and kit.holding == Q and w.loadout[ULT] == "fireball" and w.equipped == ULT
	)
	check("its run going on straight", #p.runs == 1 and not p.runs[1].curving)
end

do
	local p = inHand()
	step(p, B.Fire)
	run(p, B.Fire, 20)
	press(p, 2)
	step(p, B.Fire)
	step(p, B.Fire)
	local w, kit = p.sim.weapons, p.sim.abilities
	check("drawing a gun lets go of it", kit.steering == 0 and w.equipped == 2 and w.loadout[ULT] == "")
	check(
		"the gun drawn its own way",
		near(w.equipEndTime - now(p) + DT, WeaponConfig.Defs.classic.equipTime.value, 1e-9),
		string.format("%.4f s", w.equipEndTime - now(p) + DT)
	)
end

do
	local p = inHand()
	step(p, B.Fire)
	run(p, B.Fire, 20)
	AbilitySim.died(p.sim.abilities)
	check("dying lets go of it", p.sim.abilities.steering == 0 and p.sim.abilities.steerUntil == 0)
end

-- Its run ---------------------------------------------------------------------------------------

local FEET = vector.create(0, 0.02, 0)
local AHEAD = vector.create(0, 0, -1)
local LEFT = Accuracy.aim(math.rad(90), 0)

-- A run sent from `feet` the way `aim` faces, run to its end over `world`,
-- bent towards `bendTo` for its first `bendTicks` ticks and then let go.
local function runOut(world: any, feet: vector, aim: vector, bendTo: vector?, bendTicks: number?): (BlazeSim.Run, number)
	local r = BlazeSim.send(1, 1, feet, aim, world)
	local n = 0
	while not r.over and n < ticks(5) do
		n += 1
		local bent = bendTo ~= nil and n <= (bendTicks or math.huge)
		BlazeSim.step(r, bendTo or r.heading, bent, DT, world)
	end
	return r, n
end

do
	local r, n = runOut(floor, FEET, Accuracy.aim(0, -0.4))
	check("it starts on the floor under his feet", vector.magnitude(r.points[1] - vector.create(0, 0, 0)) < 1e-6)
	check(
		"and runs straight along it, level whichever way he looks, for its flight",
		r.over and n == ticks(BZ.flight.value) and near(r.age, BZ.flight.value, 1e-9) and math.abs(r.position.y) < 1e-6
	)
	check("21 m", near(-r.position.z, BZ.length.value, 1e-6) and math.abs(r.position.x) < 1e-9, string.format("%.3f m", -r.position.z))
	check(
		"a point of its path every few ticks, and its end",
		#r.points == ticks(BZ.flight.value) // BlazeSim.POINT_TICKS + 1 and r.points[#r.points] == r.position,
		tostring(#r.points)
	)
	local ok = true
	for i = 2, #r.points do
		ok = ok and near(flat(r.points[i], r.points[i - 1]), BlazeSim.speed() * DT * BlazeSim.POINT_TICKS, 1e-6)
	end
	check("evenly", ok)
end

do
	local r = runOut(floor, FEET, AHEAD, LEFT)
	-- At its turn rate it comes round a quarter turn in 0.5 s, on a circle
	-- its speed over its turn rate across, then runs on: to within a tick's
	-- run, as it turns a tick at a time.
	local radius = BlazeSim.speed() / math.rad(BZ.turnRate.value)
	local straight = BlazeSim.speed() * (BZ.flight.value - 0.5)
	local want = vector.create(-radius - straight, 0, -radius)
	check(
		"bent to the left all the way, it comes round a quarter turn and runs on",
		vector.magnitude(r.position - want) < BlazeSim.speed() * DT and vector.magnitude(r.heading - LEFT) < 1e-6,
		string.format("(%.2f, %.2f) for (%.2f, %.2f)", r.position.x, r.position.z, want.x, want.z)
	)
	print(string.format("    bent hard left from the start, it ends %.1f m left and %.1f m ahead (ours)", -r.position.x, -r.position.z))
	local length = 0
	for i = 2, #r.points do
		length += flat(r.points[i], r.points[i - 1])
	end
	check("as long a path", near(length, BZ.length.value, 0.1), string.format("%.2f m", length))
end

do
	-- Bent for its first 20 ticks, then let go: it runs straight on the way
	-- it was going, and bending it again does nothing.
	local r = BlazeSim.send(1, 1, FEET, AHEAD, floor)
	for _ = 1, 20 do
		BlazeSim.step(r, LEFT, true, DT, floor)
	end
	BlazeSim.step(r, LEFT, false, DT, floor)
	local heading = r.heading
	check("once let go, it's no longer bent", not r.curving and heading.x < -0.1)
	while not r.over do
		BlazeSim.step(r, LEFT, true, DT, floor)
	end
	check("and fire again doesn't bend it", vector.magnitude(r.heading - heading) < 1e-9)
	local turned = math.deg(math.acos(math.clamp(-heading.z, -1, 1)))
	check("20 ticks bent turned it 28 degrees", near(turned, BZ.turnRate.value * 20 * DT, 0.01), string.format("%.2f degrees", turned))
end

do
	-- Straight up and straight down it can't run: it goes ahead.
	local r = BlazeSim.send(1, 1, FEET, vector.create(0, 1, 0), floor)
	check("sent looking straight up, it goes ahead", vector.magnitude(r.heading - AHEAD) < 1e-9)
	BlazeSim.step(r, vector.create(0, -1, 0), true, DT, floor)
	check("and isn't bent by a crosshair straight down", vector.magnitude(r.heading - AHEAD) < 1e-9)
end

do
	-- A box half a metre high, 6 m to 8 m ahead.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-2, 0, -8), vector.create(2, 0.5, -6))
	local r = runOut(world, FEET, AHEAD)
	local on = 0
	for _, point in r.points do
		if point.z < -6.3 and point.z > -7.7 then
			on += if near(point.y, 0.5, 1e-6) then 1 else -100
		end
	end
	check("it runs up over a box lower than its hover", on > 0 and near(r.position.y, 0, 1e-6), tostring(on))
	check("and down off it, as far as ever", near(-r.position.z, BZ.length.value, 1e-6))
end

do
	-- A wall 2 m high and 0.5 m thick, 6 m ahead.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-2, 0, -6.5), vector.create(2, 2, -6))
	local r = runOut(world, FEET, AHEAD)
	local high = false
	for _, point in r.points do
		high = high or math.abs(point.y) > 1e-6
	end
	check("it runs through a wall taller than its hover, on the floor", not high and near(-r.position.z, BZ.length.value, 1e-6))
	check("which is under its hover", BZ.hover.value < 2 and BZ.hover.value > 0.5)
end

do
	-- On a ledge 3 m up that ends 5 m ahead.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-5, 0, -5), vector.create(5, 3, 5))
	local r = runOut(world, vector.create(0, 3.02, 0), AHEAD)
	check("it runs off a ledge, down to the floor below", near(r.position.y, 0, 1e-6) and near(-r.position.z, BZ.length.value, 1e-6))
	check("its path on the ledge first", near(r.points[1].y, 3, 1e-6) and near(r.points[2].y, 3, 1e-6))
end

do
	-- A platform with nothing under it, that ends 10 m ahead.
	local world = FakeWorld.new():addBox(vector.create(-5, -1, -10), vector.create(5, 0, 10))
	local r, n = runOut(world, FEET, AHEAD)
	check(
		"with no floor ahead it ends at the edge",
		r.over and n < ticks(BZ.flight.value) and -r.position.z <= 10 and -r.position.z > 10 - BlazeSim.speed() * DT,
		string.format("%.3f m", -r.position.z)
	)
	check("its end the last point of its path", r.points[#r.points] == r.position)
	local wall = BlazeSim.wall(1, 1, r.points, 0)
	check("and its wall that long", wall ~= nil and near(BlazeSim.length(wall), -r.position.z, 1e-6))
	local nowhere = BlazeSim.send(1, 2, FEET, AHEAD, FakeWorld.new())
	check("with no floor under him it's over at once", nowhere.over and #nowhere.points == 0)
	check("and no wall rises", BlazeSim.wall(1, 2, nowhere.points, 0) == nil)
end

do
	-- A run as the server's ticks run it: sent by a tick's cast, from the
	-- next tick on, and out of the list once it's over.
	local list: { BlazeSim.Run } = {}
	local cast = { kind = "flame", tick = 7, position = FEET, direction = AHEAD }
	local over = BlazeSim.tick(list, 3, input(0), { cast }, true, DT, floor)
	check(
		"a tick's wall sent out joins its runs",
		#over == 0 and #list == 1 and list[1].owner == 3 and list[1].id == 7 and list[1].age == 0
	)
	local n = 0
	repeat
		n += 1
		over = BlazeSim.tick(list, 3, input(0), nil, false, DT, floor)
	until #over > 0 or n > ticks(2)
	check("and leaves them over, its flight on", n == ticks(BZ.flight.value) and #list == 0 and over[1].id == 7, tostring(n))
	local none = BlazeSim.tick(list, 3, input(0), { cast }, true, DT, FakeWorld.new())
	check("one with no floor is over as it's sent", #none == 1 and #list == 0)
	local r = BlazeSim.send(1, 1, FEET, AHEAD, floor)
	local copy = BlazeSim.copy(r)
	BlazeSim.step(copy, LEFT, true, DT, floor)
	BlazeSim.step(copy, LEFT, true, DT, floor)
	BlazeSim.step(copy, LEFT, true, DT, floor)
	BlazeSim.step(copy, LEFT, true, DT, floor)
	check("a copy runs on its own", r.age == 0 and #r.points == 1 and #copy.points == 2)
	local loose = BlazeSim.send(1, 1, FEET, AHEAD, floor)
	BlazeSim.step(loose, LEFT, true, DT, floor)
	local heading = loose.heading
	while not BlazeSim.drift(loose, DT, floor) do
	end
	check("a run nobody bends runs straight on", vector.magnitude(loose.heading - heading) < 1e-9 and not loose.curving)
end

do
	-- Phoenix sends it holding fire, turning to his left slower than it
	-- turns; the server's run follows his crosshair.
	local p = inHand()
	step(p, B.Fire)
	local yaw = 0
	for _ = 1, ticks(BZ.flight.value) do
		yaw = math.min(yaw + math.rad(1), math.rad(90))
		step(p, B.Fire, yaw)
	end
	local r = p.over[1]
	check(
		"sent with fire held, it follows the crosshair",
		r ~= nil and vector.magnitude(r.heading - LEFT) < 1e-6 and r.position.x < -5 and #p.runs == 0
	)
	print(
		string.format(
			"    sent ahead, turning left a degree a tick, it ends %.1f m left and %.1f m ahead (ours)",
			-(if r then r.position.x else 0),
			-(if r then r.position.z else 0)
		)
	)
	local q = inHand()
	step(q, B.Fire)
	step(q, 0)
	run(q, 0, ticks(BZ.flight.value), math.rad(90))
	local s = q.over[1]
	check(
		"tapped, it runs straight however he turns",
		s ~= nil and math.abs(s.position.x) < 1e-6 and near(-s.position.z, BZ.length.value, 1e-6)
	)
end

-- Its wall -------------------------------------------------------------------------------------

local RISE = 100

do
	local r = runOut(floor, FEET, AHEAD)
	local wall = BlazeSim.wall(1, 1, r.points, RISE)
	assert(wall, "a wall")
	local spread = RISE + BlazeSim.length(wall) / BZ.spreadSpeed.value
	check("it's as long as its run", near(BlazeSim.length(wall), BZ.length.value, 1e-6))
	check(
		"it rises from his end and spreads along it",
		BlazeSim.reachAt(wall, RISE) == 0 and near(BlazeSim.reachAt(wall, RISE + 0.25), BZ.spreadSpeed.value * 0.25, 1e-9)
	)
	check(
		"to the far end in half a second",
		near(spread - RISE, 0.5, 1e-9) and near(BlazeSim.reachAt(wall, RISE + 2), BZ.length.value, 1e-6),
		string.format("%.3f s", spread - RISE)
	)
	check("reached there when it says", near(BlazeSim.reachedAt(wall, 21), spread, 1e-9))
	check(
		"standing 8 s from rising, then gone",
		not BlazeSim.standing(wall, RISE - 0.01)
			and BlazeSim.standing(wall, RISE)
			and BlazeSim.standing(wall, RISE + 7.99)
			and not BlazeSim.standing(wall, RISE + 8)
			and BlazeSim.ends(wall) == RISE + 8
	)
	check("standing at his end, he's in it at once", BlazeSim.inside(wall, vector.create(0, 0, 0), RISE))
	local mid = vector.create(0, 0, -10)
	check(
		"10 m along, not until it's spread there",
		not BlazeSim.inside(wall, mid, RISE + 0.1) and BlazeSim.inside(wall, mid, RISE + 10 / BZ.spreadSpeed.value + 0.01)
	)
	local t = spread
	check(
		"half its thickness each side of its path",
		BlazeSim.inside(wall, vector.create(0.49, 0, -10), t) and not BlazeSim.inside(wall, vector.create(0.51, 0, -10), t)
	)
	check(
		"and a body half in it",
		BlazeSim.inside(wall, vector.create(-0.83, 0, -10), t, cfg.halfWidth)
			and not BlazeSim.inside(wall, vector.create(-0.85, 0, -10), t, cfg.halfWidth)
	)
	check(
		"4 m up from its floor, no higher",
		BlazeSim.inside(wall, vector.create(0, 3.99, -10), t) and not BlazeSim.inside(wall, vector.create(0, 4.01, -10), t)
	)
	check(
		"and a step below it",
		BlazeSim.inside(wall, vector.create(0, -0.49, -10), t) and not BlazeSim.inside(wall, vector.create(0, -0.51, -10), t)
	)
	check(
		"rounded at its ends",
		BlazeSim.inside(wall, vector.create(0, 0, -21.4), t)
			and not BlazeSim.inside(wall, vector.create(0, 0, -21.6), t)
			and BlazeSim.inside(wall, vector.create(0, 0, 0.4), t)
			and not BlazeSim.inside(wall, vector.create(0, 0, 0.6), t)
	)
	check("not once it's gone", not BlazeSim.inside(wall, mid, RISE + 8))
	check(
		"an eye in it as well as feet, so a camera there sees fire",
		BlazeSim.inside(wall, mid + vector.create(0, cfg.standEyeHeight, 0), t)
	)
	check("and no jump takes the eye over it", cfg.jumpApexHeight + cfg.standEyeHeight < BZ.height.value)
	check(
		"its crackle's heard from the closest place it's reached",
		vector.magnitude((BlazeSim.nearest(wall, vector.create(3, 1.6, -7), t) or vector.zero) - vector.create(0, 0, -7)) < 1e-6
			and vector.magnitude(
				(BlazeSim.nearest(wall, vector.create(3, 1.6, -15), RISE + 0.1) or vector.zero) - vector.create(0, 0, -4.2)
			) < 1e-6
			and BlazeSim.nearest(wall, vector.zero, RISE - 0.1) == nil
	)
end

do
	-- Over the half-metre box, its fire stands on it.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-2, 0, -8), vector.create(2, 0.5, -6))
	local r = runOut(world, FEET, AHEAD)
	local wall = BlazeSim.wall(1, 1, r.points, RISE)
	assert(wall, "a wall")
	local t = RISE + 1
	check(
		"up a box, it stands on the box",
		BlazeSim.inside(wall, vector.create(0, 0.5, -7), t)
			and BlazeSim.inside(wall, vector.create(0, 4.4, -7), t)
			and not BlazeSim.inside(wall, vector.create(0, 4.6, -7), t)
	)
end

-- The burn and the heal -----------------------------------------------------------------------

do
	check(
		"30 a second from an enemy, a share of it from an ally",
		BlazeSim.burnRate(false) == 30 and near(BlazeSim.burnRate(true), 10, 1e-9)
	)
	-- Standing in it, a frame at a time at 60 frames a second, from when it
	-- reaches them to when it's gone; what's owed is given as it goes.
	local function burnt(from: number, to: number): number
		local o = FireSim.owed()
		local total = 0
		local frame = 1 / 60
		for n = 1, math.floor((to - from) / frame + 0.5) do
			total += FireSim.owe(o, BlazeSim.burnRate(false) * frame, from + n * frame, 0.1)
		end
		return total + FireSim.owe(o, 0, to, 0)
	end
	local r = runOut(floor, FEET, AHEAD)
	local wall = BlazeSim.wall(1, 1, r.points, 0)
	assert(wall, "a wall")
	local atHis = burnt(0, BlazeSim.ends(wall))
	local atFar = burnt(BlazeSim.reachedAt(wall, BZ.length.value), BlazeSim.ends(wall))
	check("all of it at his end takes 240", math.abs(atHis - 240) <= 1, tostring(atHis))
	check("and at the far end of the longest, 225 (the wiki's 225 to 240)", math.abs(atFar - 225) <= 1, tostring(atFar))
	-- Run straight through it, from one side to the other.
	local speed = cfg.baseRunSpeed
	local o = FireSim.owed()
	local through = 0
	local t = 2
	local x = -2
	while x < 2 do
		t += 1 / 60
		x += speed / 60
		if BlazeSim.inside(wall, vector.create(x, 0, -10), t, cfg.halfWidth) then
			through += FireSim.owe(o, BlazeSim.burnRate(false) / 60, t, 0.1)
		else
			through += FireSim.owe(o, 0, t, 0)
		end
	end
	check("run through, it takes a few", through >= 6 and through <= 9, tostring(through))
	print(string.format("    run straight through it at %.2f m/s, it takes %d (ours)", speed, through))
	check("Inner Fire from it: nothing at the first touch", FireSim.healed(0, IF.blazeEvery.value) == 0)
	check(
		"then a point every 0.16 s",
		FireSim.healed(0.16, IF.blazeEvery.value) == 1
			and FireSim.healed(0.319, IF.blazeEvery.value) == 1
			and FireSim.healed(4, IF.blazeEvery.value) == 25
	)
	check(
		"all 50 in its 8 s, and no more",
		FireSim.healed(8, IF.blazeEvery.value) == 50
			and FireSim.healed(20, IF.blazeEvery.value) == 50
			and near(FireSim.healTime(IF.blazeEvery.value), 8, 1e-9)
	)
end

-- The wire -------------------------------------------------------------------------------------

do
	local p = inHand()
	step(p, B.Fire)
	run(p, B.Fire, 20)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	check(
		"the ack carries a wall being bent",
		decoded.abilities.steering == C
			and decoded.abilities.steerUntil == p.sim.abilities.steerUntil
			and decoded.weapons.loadout[ULT] == "flamewall"
			and decoded.weapons.equipped == ULT
	)
	local copy = decoded :: PlayerSim.State
	local left: Player = { sim = copy, slot = p.slot, runs = {}, over = {} }
	local same = true
	for i = 1, 200 do
		local buttons = if i < 40 then B.Fire else 0
		step(p, buttons)
		step(left, buttons)
		local a, b = p.sim, copy
		same = same
			and a.abilities.steering == b.abilities.steering
			and a.weapons.equipped == b.weapons.equipped
			and a.weapons.equipEndTime == b.weapons.equipEndTime
	end
	check("and a replay from it lets go as it does, to the same end", same and copy.abilities.steering == 0 and copy.weapons.equipped == 1)
end

return nil
