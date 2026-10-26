--!strict
-- Sage's Slow Orb (system 37): its numbers and where they come from, its
-- two charges, the orb in hand (Q, its equip, fire throwing it, the gun
-- back after, the second charge, no alt fire, Q again putting it away
-- unthrown), its flight (faster and falling harder than the fireball, off
-- walls, bursting on the floor, never lobbed, and with no air time to run
-- out, so it comes down however high it's thrown), its field (spreading to
-- its radius, no further than the walls let it, for its duration), the
-- slow in the simulation (held to half the run at once, on the ground and
-- in the air, a lower jump and a slower dash, for whoever's in it, judged
-- at the time their screen showed, and replayed the same), and the wire
-- carrying the orb in hand and the slow.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local FireballSim = require("../src/shared/Abilities/FireballSim")
local FireSim = require("../src/shared/Abilities/FireSim")
local SlowSim = require("../src/shared/Abilities/SlowSim")
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
local SO = AbilityConfig.SlowOrb
local J = AbilityConfig.Jett
local ORB = WeaponConfig.Defs.iceorb
local ULT = WeaponSim.ULT
local Q, E = AbilityConfig.Q, AbilityConfig.E
local SAGE = "sage"

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function horizontal(v: vector): number
	return math.sqrt(v.x * v.x + v.z * v.z)
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

-- Sage settled on the floor with the Vandal drawn and both her orbs.
local function newPlayer(): Player
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(SAGE)
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

-- Someone settled on the floor at `at` with the Vandal drawn (and Jett's
-- kit, full).
local function settled(at: vector): PlayerSim.State
	local s = PlayerSim.new(at, { "vandal", "classic", "knife", "" })
	AbilitySim.fill(s.abilities)
	for _ = 1, ticks(0.5) do
		PlayerSim.step(s, input(0), cfg, floor, DT)
	end
	return s
end

-- One tick of `s` holding `buttons`, in the fields of `slows` (none
-- without).
local function move(s: PlayerSim.State, buttons: number, slows: SlowSim.Slows?): { AbilitySim.Cast }
	local _, _, _, _, casts = PlayerSim.step(s, input(buttons), cfg, floor, DT, nil, slows)
	return casts or {}
end

H.section("Slow Orb tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in SO do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Slow Orb number says where it's from", labelled)
	local def = AbilityConfig.Defs.sloworb
	check(
		"Sage's Q, a basic ability: two charges, 200 each (Patch 3.0), never free",
		def.slot == Q
			and def.kind == "basic"
			and def.cost ~= nil
			and def.cost.value == 200
			and def.cost.status == "confirmed"
			and def.charges ~= nil
			and def.charges.value == 2
			and def.free == nil
			and def.recharge == nil
	)
	check(
		"its field lasts 7 s and takes half the speed (Patch 0.50), in the air too (Patch 0.47)",
		SO.duration.value == 7 and SO.duration.status == "confirmed" and SO.slow.value == 0.5 and SO.slow.status == "confirmed"
	)
	check("and half a dash's (Patch 9.10)", SO.dash.value == 0.5 and SO.dash.status == "confirmed")
	check(
		"30% off a jump's height and 5.6 m round, from a tracker and Patch 1.07",
		SO.jump.value == 0.3 and SO.jump.status == "community" and SO.radius.value == 5.6 and SO.radius.status == "community"
	)
	check(
		"thrown at 29 m/s under 0.45 of gravity (the wiki's projectiles)",
		SO.speed.value == 29 and SO.gravity.value == 0.45 and SO.speed.status == "community"
	)
	check(
		"0.5 s to put it in hand and 0.4 s to have the gun back (the wiki)",
		ORB.equipTime.value == 0.5 and SO.unequip.value == 0.4 and AbilityConfig.unequip("sloworb") == 0.4
	)
	check(
		"the orb, a weapon of the fifth slot that's never reloaded, thrown once, with no alt fire",
		ORB.category == "ability"
			and ORB.slot == ULT
			and ORB.ability == "sloworb"
			and def.weapon == "iceorb"
			and ORB.magazine.value == 1
			and ORB.reserve.value == 0
			and ORB.alt == nil
			and ORB.name == "Slow Orb"
	)
	local item = Shop.item("sloworb")
	check(
		"its charges are sold on Q, and its orb isn't",
		item ~= nil and item.kind == "ability" and item.price == 200 and item.slot == "Q" and Shop.item("iceorb") == nil
	)
	local slow = SlowSim.SLOW
	check(
		"slowed, half the speed is kept, 0.7 of a jump's height and half a dash's speed",
		slow.speed == 0.5 and near(slow.jump * slow.jump, 0.7, 1e-12) and slow.dash == 0.5
	)
	check("the slower orb's numbers are ours", SO.spread.status == "estimate" and SO.height.status == "estimate")
end

-- The kit --------------------------------------------------------------------------------------

do
	local k = AbilitySim.new(SAGE)
	check("a new kit has no Slow Orb", k.charges[Q] == 0)
	check("one can be bought", AbilitySim.buy(k, "sloworb") and k.charges[Q] == 1)
	check("and a second", AbilitySim.buy(k, "sloworb") and k.charges[Q] == 2)
	check("but not a third", not AbilitySim.canBuy(k, "sloworb") and not AbilitySim.buy(k, "sloworb") and k.charges[Q] == 2)
	check("and one sold back", AbilitySim.sell(k, "sloworb") and k.charges[Q] == 1)
	local full = AbilitySim.new(SAGE)
	AbilitySim.fill(full)
	check("the course fills both", full.charges[Q] == 2)
end

-- In hand --------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local _, casts = step(p, B.AbilityQ)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("Q puts the orb in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "sloworb" and cast.slot == Q)
	check("from the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "iceorb" and w.back == 1)
	check("with nothing spent yet", kit.charges[Q] == 2 and kit.holding == Q)
	local waited: number? = nil
	for n = 1, ticks(2) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot)), cfg, floor, DT)
		if probed and #ofKind(probed, "slow") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be thrown once its 0.5 s equip is over",
		waited ~= nil and math.abs(waited - ticks(ORB.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

do
	local p = inHand()
	local yaw, pitch = -0.3, 0.2
	local shots, casts = step(p, B.Fire, yaw, pitch)
	local thrown = ofKind(casts, "slow")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("fire throws it", thrown ~= nil and thrown.ability == "sloworb" and thrown.slot == Q)
	check(
		"from the eye, along the crosshair",
		thrown ~= nil
			and vector.magnitude(thrown.origin - PlayerSim.eye(p.sim, cfg)) < 1e-6
			and vector.magnitude(thrown.direction - Accuracy.aim(yaw, pitch)) < 1e-6
	)
	check("as a throw, not a bullet", #shots == 0 and thrown ~= nil and thrown.curve == nil)
	check("one charge spent, one left", kit.charges[Q] == 1 and kit.holding == 0)
	check("the orb gone, and the gun back in hand", w.loadout[ULT] == "" and w.equipped == 1)
	check("ready 0.4 s after", near(w.equipEndTime - now(p), SO.unequip.value, 1e-9), string.format("%.4f s", w.equipEndTime - now(p)))
	run(p, 0, ticks(1))
	step(p, B.AbilityQ)
	run(p, 0, ticks(ORB.equipTime.value) + 1)
	local _, second = step(p, B.Fire)
	check("Q and fire again throw the second", #ofKind(second, "slow") == 1 and kit.charges[Q] == 0 and w.equipped == 1)
	run(p, 0, ticks(1))
	local _, none = step(p, B.AbilityQ)
	check("and with none left, Q does nothing", #none == 0 and kit.holding == 0 and w.equipped == 1)
end

do
	local p = newPlayer()
	step(p, B.AbilityQ)
	local _, held = run(p, B.Fire, ticks(1))
	check("fire held as it comes into hand throws it as soon as it can", #ofKind(held, "slow") == 1)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	local _, casts = run(p, B.AltFire, 10)
	check(
		"alt fire throws nothing",
		#ofKind(casts, "slow") == 0 and kit.charges[Q] == 2 and kit.holding == Q and w.loadout[ULT] == "iceorb"
	)
	check("and doesn't zoom", w.scoped == 0)
	step(p, 0)
	local _, again = step(p, B.AbilityQ)
	check("Q again puts it away unthrown", #again == 0 and kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1)
	check("both charges kept", kit.charges[Q] == 2)
end

do
	local p = newPlayer()
	step(p, B.AbilityQ)
	run(p, 0, 10)
	local _, toHeal = step(p, B.AbilityE)
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"E with it in hand puts the Healing Orb there instead",
		#toHeal == 1 and toHeal[1].ability == "healingorb" and kit.holding == E and w.loadout[ULT] == "healorb"
	)
	check("with every charge kept", kit.charges[Q] == 2 and kit.charges[E] == 1 and w.back == 1)
end

-- Its flight ------------------------------------------------------------------------------------

local AHEAD = vector.create(0, 0, -1)
local EYE = vector.create(0, 1.6, 0)
local G = SO.gravity.value * SO.worldGravity.value

do
	local f = SlowSim.throw(1, 1, EYE, AHEAD)
	local landed = FireballSim.fly(f, DT, floor)
	-- It falls from the eye until the box that flies rests on the floor.
	local fall = math.sqrt(2 * (EYE.y - SO.size.value) / G)
	check(
		"thrown level, it falls to the floor and bursts",
		landed ~= nil and near(landed, fall, DT),
		string.format("%s s", tostring(landed))
	)
	check(
		"where it fell, its speed ahead kept",
		near(f.position.z, -SO.speed.value * (landed or 0), 1e-3) and near(f.position.y, SO.size.value, 1e-3)
	)
	print(string.format("    a level throw from the eye bursts %.1f m ahead after %.2f s (ours)", -f.position.z, landed or 0))
	local ball = FireballSim.throw(1, 2, EYE, AHEAD, false)
	FireballSim.fly(ball, DT, floor)
	check("further than Hot Hands' fireball goes", -f.position.z > -ball.position.z + 5)
	check("never lobbed", not f.lob and not FireballSim.throw(1, 3, EYE, AHEAD, true, SlowSim.FLIGHT).lob and f.flight == SlowSim.FLIGHT)
	local g = SlowSim.throw(1, 4, EYE, AHEAD)
	local worst = 0
	while not g.landed do
		FireballSim.step(g, DT, floor)
		if not g.landed then
			worst = math.max(worst, vector.magnitude(FireballSim.at(g.keys, g.age) - g.position))
		end
	end
	check("its keys draw it where it flew", worst < 1e-4, string.format("%.6f m", worst))
end

do
	local up = vector.normalize(vector.create(0, 3, -1))
	local f = SlowSim.throw(1, 5, EYE, up)
	local landed = FireballSim.fly(f, DT, floor)
	-- Its arc, up and back down to the floor, under its own gravity alone.
	local rise = SO.speed.value * up.y
	local arc = (rise + math.sqrt(rise * rise + 2 * G * (EYE.y - SO.size.value))) / G
	check(
		"thrown up steeply, it has no air time to run out: it flies its whole arc",
		landed ~= nil and not f.dropping and #f.keys == 2 and near(landed, arc, DT),
		string.format("%s s, %d keys", tostring(landed), #f.keys)
	)
	check("and bursts where the arc meets the floor", near(f.position.z, SO.speed.value * up.z * (landed or 0), 1e-3))
	print(string.format("    thrown up steeply, it bursts %.0f m ahead after %.1f s (ours)", -f.position.z, landed or 0))
	check(
		"so it's given as long as the highest throw takes to come down, and Hot Hands' fireball no more than before",
		near(FireballSim.longest(SlowSim.FLIGHT), FireballSim.LONGEST + 2 * SO.speed.value / G, 1e-9)
			and FireballSim.longest(AbilityConfig.HotHands) == FireballSim.LONGEST
	)
end

do
	-- Thrown at every pitch, it bursts on the floor every time, never
	-- through it, straight up as well.
	local missed = {}
	for pitch = -85, 85, 5 do
		local f = SlowSim.throw(1, 9, EYE, Accuracy.aim(0, math.rad(pitch)))
		if FireballSim.fly(f, DT, floor) == nil or not near(f.position.y, SO.size.value, 1e-3) then
			table.insert(missed, tostring(pitch))
		end
	end
	check("thrown at any pitch, it bursts on the floor", #missed == 0, table.concat(missed, ", "))
	local f = SlowSim.throw(1, 10, EYE, AHEAD)
	check("with no floor under it, it's given up on", FireballSim.fly(f, DT, FakeWorld.new()) == nil)
end

do
	-- A wall 4 m ahead, its face at z = -4.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-5, 0, -5), vector.create(5, 4, -4))
	local f = SlowSim.throw(1, 11, EYE, AHEAD)
	local landed = FireballSim.fly(f, DT, world)
	check(
		"off a wall, it comes back",
		landed ~= nil and f.position.z > -4 and #f.keys == 3,
		string.format("z %.2f, %d keys", f.position.z, #f.keys)
	)
	local bounce = f.keys[2]
	check(
		"keeping half its speed",
		bounce ~= nil and bounce.velocity.z > 0 and near(bounce.velocity.z, SO.speed.value * SO.bounce.value, 1e-3)
	)
	check("and bursts on the floor this side of it", near(f.position.y, SO.size.value, 1e-3) and f.position.z > -4 + SO.size.value)
end

-- Its field -------------------------------------------------------------------------------------

local CENTRE = vector.create(0, 0, 0)

do
	local open = SlowSim.reaches(CENTRE, floor)
	local all = #open == FireSim.SECTORS
	for _, reach in open do
		all = all and reach == SO.radius.value
	end
	check("in the open it spreads 5.6 m each way round", all)
	-- A crate 2 m away on +x, and a kerb 2 m away on -x.
	local world = FakeWorld.new()
		:addFloor()
		:addBox(vector.create(2, 0, -0.5), vector.create(3, 1, 0.5))
		:addBox(vector.create(-3, 0, -10), vector.create(-2, 0.3, 10))
	local reaches = SlowSim.reaches(CENTRE, world)
	local half = FireSim.SECTORS // 2 + 1
	check("a crate stops it", near(reaches[1], 2 - 0.01, 1e-3), string.format("%.3f m", reaches[1]))
	check("a kerb doesn't", reaches[half] == SO.radius.value)
	local field = SlowSim.field(1, 1, CENTRE, 100, reaches)
	local t = 100 + SO.spread.value
	local function at(x: number, y: number, z: number, when: number, pad: number?): boolean
		return SlowSim.slowed({ field }, vector.create(x, y, z), when, pad)
	end
	check(
		"it spreads from nothing to its radius over its spread",
		FireSim.radiusAt(field, 100) == 0 and near(FireSim.radiusAt(field, t), SO.radius.value, 1e-9)
	)
	check("lasting 7 s from the burst, then gone", FireSim.ends(field) == 107 and at(0, 0, 0, 106.99) and not at(0, 0, 0, 107))
	check("slowing whoever stands on it at once", at(0, 0, 0, 100.01) and not at(0, 0, 0, 99.99))
	check("4 m out, not until it's spread there", not at(0, 0, 4, 100.1) and at(0, 0, 4, t))
	check("5.5 m out, all the way round", at(0, 0, -5.5, t) and at(-3.88, 0, 3.88, t) and at(-5.5, 0, 0, t) and at(0, 0, 5.5, t))
	check("and no further", not at(0, 0, -5.7, t))
	check("but a body half over its edge", at(0, 0, -5.7, t, cfg.halfWidth))
	check("not behind the crate", not at(3.5, 0, 0, t) and at(1.9, 0, 0, t))
	check("up to 1.2 m over its floor, no higher", at(1, 1.15, 1, t) and not at(1, 1.25, 1, t))
	check("so no jump in it gets out of it", cfg.jumpApexHeight < SO.height.value)
	check("and a step below it", at(1, -0.4, 1, t) and not at(1, -SO.depth.value - 0.1, 1, t))
	local other = SlowSim.field(2, 1, vector.create(20, 0, 0), 100, SlowSim.reaches(vector.create(20, 0, 0), floor))
	check("in either of two", SlowSim.slowed({ field, other }, vector.create(20, 0, 3), t) and not at(20, 0, 3, t))
	check(
		"the floor it lies on is under the orb",
		vector.magnitude(SlowSim.floorUnder(vector.create(1, SO.size.value, 2)) - vector.create(1, 0, 2)) < 1e-9
	)
end

-- The slow --------------------------------------------------------------------------------------

-- A field in the open at the centre, burst at 0, and judged a second on.
local FIELD = SlowSim.field(9, 1, CENTRE, 0, SlowSim.reaches(CENTRE, floor))
local SLOWS: SlowSim.Slows = { fields = { FIELD }, time = 1 }

do
	-- Running in from 14 m out.
	local s = settled(vector.create(0, 0.02, 14))
	local full = PlayerSim.maxSpeed(s, cfg)
	local before, first = 0, nil :: number?
	local entered: number? = nil
	for n = 1, ticks(3) do
		local speed = horizontal(s.movement.velocity)
		move(s, B.Forward, SLOWS)
		if s.movement.slowed and not first then
			before, first, entered = speed, horizontal(s.movement.velocity), s.movement.position.z
		end
	end
	check("running in at the Vandal's 5.4 m/s", near(before, full, 1e-6) and near(full, 5.4, 1e-9), string.format("%.3f m/s", before))
	check(
		"they're held to half of it at once, 2.7 m/s",
		first ~= nil and near(first, full * 0.5, 1e-6),
		string.format("%s m/s", tostring(first))
	)
	check(
		"from where their body's half over its edge",
		entered ~= nil and entered < SO.radius.value + cfg.halfWidth and entered > SO.radius.value + cfg.halfWidth - full * DT * 2
	)
	check("and go on at that through it", s.movement.slowed and near(horizontal(s.movement.velocity), full * 0.5, 1e-6))
	local out: number? = nil
	for n = 1, ticks(6) do
		move(s, B.Forward, SLOWS)
		if not s.movement.slowed and not out then
			out = n
		end
	end
	check("out the other side, they're not slowed", out ~= nil and not s.movement.slowed)
	check("and back at their run", near(horizontal(s.movement.velocity), full, 1e-6))
end

do
	local s = settled(vector.create(0, 0.02, 0))
	local full = PlayerSim.maxSpeed(s, cfg)
	for _ = 1, ticks(1) do
		move(s, B.Forward + B.Walk, SLOWS)
	end
	check(
		"walking in it, half a walk",
		near(horizontal(s.movement.velocity), full * 0.5 * cfg.walkMultiplier, 1e-6),
		string.format("%.3f m/s", horizontal(s.movement.velocity))
	)
	for _ = 1, ticks(1) do
		move(s, B.Forward, SLOWS)
	end
	check("running, half a run", near(horizontal(s.movement.velocity), full * 0.5, 1e-6))
end

do
	-- Running at it, and jumping 7 m out, to come down in it.
	local s = settled(vector.create(0, 0.02, 14))
	local full = PlayerSim.maxSpeed(s, cfg)
	while s.movement.position.z > 7 do
		move(s, B.Forward, SLOWS)
	end
	move(s, B.Forward + B.Jump, SLOWS)
	local air: number? = nil
	local grounded = true
	for _ = 1, ticks(1) do
		move(s, B.Forward, SLOWS)
		if s.movement.slowed and not air then
			air, grounded = horizontal(s.movement.velocity), s.movement.grounded
		end
	end
	check(
		"jumping in, they're slowed in the air (Patch 0.47), held to half at once",
		air ~= nil and not grounded and near(air, full * 0.5, 1e-6),
		string.format("%s m/s", tostring(air))
	)
end

-- How high a jump from standing at `at` goes, in `slows`.
local function apex(at: vector, slows: SlowSim.Slows?): number
	local s = settled(at)
	local base = s.movement.position.y
	local top = base
	move(s, B.Jump, slows)
	for _ = 1, ticks(1.5) do
		move(s, 0, slows)
		top = math.max(top, s.movement.position.y)
	end
	return top - base
end

do
	local free = apex(vector.create(0, 0.02, 20), SLOWS)
	local slowed = apex(vector.create(0, 0.02, 0), SLOWS)
	check(
		"a jump in it goes 30% less high",
		near(slowed / free, 1 - SO.jump.value, 0.02),
		string.format("%.3f m of %.3f m, %.3f", slowed, free, slowed / free)
	)
	print(string.format("    a standing jump peaks %.2f m up, slowed %.2f m", free, slowed))
end

do
	-- Jett readies Tailwind and dashes forward from the centre.
	local s = settled(vector.create(0, 0.02, 0))
	move(s, B.AbilityE, SLOWS)
	for _ = 1, ticks(J.windup.value) + 1 do
		move(s, 0, SLOWS)
	end
	local before = s.movement.position
	local casts = move(s, B.AbilityE, SLOWS)
	for _ = 2, AbilitySim.ticks(J.dashTime.value, DT) do
		move(s, 0, SLOWS)
	end
	local moved = s.movement.position - before
	check(
		"a dash in it goes at half its speed, so half as far (Patch 9.10)",
		#ofKind(casts, "dash") == 1 and near(moved.z, -J.dashDistance.value * SO.dash.value, 0.01),
		string.format("%.3f m", -moved.z)
	)
	move(s, 0, SLOWS)
	check(
		"and leaves them no faster than the slow lets them go",
		horizontal(s.movement.velocity) <= PlayerSim.maxSpeed(s, cfg) * 0.5 + 1e-6
	)
end

do
	local function slowedAt(time: number, at: vector?): boolean
		local s = settled(at or vector.create(0, 0.02, 0))
		move(s, B.Forward, { fields = { FIELD }, time = time })
		return s.movement.slowed
	end
	check(
		"judged at the time their screen showed: not before the burst, then for 7 s",
		not slowedAt(-0.01) and slowedAt(0.01) and slowedAt(6.99) and not slowedAt(7)
	)
	check(
		"as far as it had spread on their screen",
		not slowedAt(0.1, vector.create(0, 0.02, 4)) and slowedAt(SO.spread.value, vector.create(0, 0.02, 4))
	)
	local s = settled(vector.create(0, 0.02, 0))
	move(s, B.Forward, nil)
	check("with no fields given, nothing slows", not s.movement.slowed)
	check(
		"the server judges a screen no further behind it than a second, and never ahead",
		SlowSim.judged(5, 10) == 9 and SlowSim.judged(9.5, 10) == 9.5 and SlowSim.judged(11, 10) == 10
	)
end

do
	-- Whoever threw it: a field's thrower is nobody special to it.
	local mine = SlowSim.field(1, 1, CENTRE, 0, SlowSim.reaches(CENTRE, floor))
	local a, b = settled(vector.create(0, 0.02, 1)), settled(vector.create(1, 0.02, 0))
	move(a, B.Forward, { fields = { mine }, time = 1 })
	move(b, B.Forward, { fields = { mine }, time = 1 })
	check("it slows everyone in it, its thrower, allies and enemies alike", a.movement.slowed and b.movement.slowed)
end

-- The wire -------------------------------------------------------------------------------------

do
	local p = newPlayer()
	step(p, B.AbilityQ)
	run(p, 0, 20)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	check(
		"the ack carries the orb in hand",
		decoded.abilities.holding == Q and decoded.weapons.loadout[ULT] == "iceorb" and decoded.weapons.equipped == ULT
	)
end

do
	-- Running through a field, an ack halfway, and a replay from it.
	local s = settled(vector.create(0, 0.02, 9))
	for _ = 1, ticks(1) do
		move(s, B.Forward, SLOWS)
	end
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, s))
	check("the ack carries the slow", s.movement.slowed and decoded.movement.slowed == true)
	local copy = decoded :: PlayerSim.State
	local same = true
	for i = 1, ticks(3) do
		local buttons = B.Forward + (if i == 100 then B.Jump else 0)
		move(s, buttons, SLOWS)
		move(copy, buttons, SLOWS)
		same = same
			and s.movement.position == copy.movement.position
			and s.movement.velocity == copy.movement.velocity
			and s.movement.slowed == copy.movement.slowed
	end
	check("and a replay from it goes as it does, to the bit", same)
	local free = settled(vector.create(0, 0.02, 30))
	move(free, B.Forward, SLOWS)
	local _, plain = PlayerCodec.decodeAck(PlayerCodec.encodeAck(10, free))
	check("as it does no slow", plain.movement.slowed == false)
end

return nil
