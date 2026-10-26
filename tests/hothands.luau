--!strict
-- Phoenix's Hot Hands and Inner Fire (system 31): their numbers and where
-- they come from, Hot Hands' charge, the fireball in hand (Q, its equip,
-- fire throwing it and alt fire lobbing it, the gun back after, Q again
-- putting it away unthrown, and the flare and the fireball changing places
-- in hand), its flight (falling under its share of gravity, off walls and
-- ceilings, bursting on the floor, dropping straight down once its air time
-- is up, and drawn from its keys), its fire (spreading to its radius, no
-- further than the walls let it, burning those over it and no higher than
-- it reaches, for its duration), the burn and the heal by the point, and
-- the wire carrying the fireball in hand.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local FireballSim = require("../src/shared/Abilities/FireballSim")
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
local HH = AbilityConfig.HotHands
local IF = AbilityConfig.InnerFire
local BALL = WeaponConfig.Defs.fireball
local ULT = WeaponSim.ULT
local Q, E = AbilityConfig.Q, AbilityConfig.E
local PHOENIX = "phoenix"

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player, and the slot their client asks for.
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

-- One tick, the slot asked for as the client would; returns its bullets and
-- its casts.
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

-- Phoenix settled on the floor with the Vandal drawn and every charge.
local function newPlayer(): Player
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(PHOENIX)
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1 }
	run(p, 0, ticks(1.5))
	return p
end

-- Q tapped, and the fireball's equip waited out.
local function inHand(): Player
	local p = newPlayer()
	step(p, B.AbilityQ)
	run(p, 0, ticks(BALL.equipTime.value) + 1)
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

H.section("Hot Hands tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	local function label(param: any)
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	for _, param in HH do
		label(param)
	end
	for _, param in IF do
		label(param)
	end
	check("every Hot Hands and Inner Fire number says where it's from", labelled)
	local def = AbilityConfig.Defs.hothands
	check(
		"200 a charge (Patch 9.10), one of them, none free",
		def.cost ~= nil
			and def.cost.value == 200
			and def.cost.status == "confirmed"
			and def.charges ~= nil
			and def.charges.value == 1
			and def.free == nil
	)
	check(
		"Inner Fire heals 50 (Patch 1.0), a point every 0.08 s (Patch 1.0)",
		IF.heal.value == 50 and IF.heal.status == "confirmed" and IF.hotHandsEvery.value == 0.08 and IF.hotHandsEvery.status == "confirmed"
	)
	check(
		"its fire reaches 1.2 m up (Patch 0.50), and burns 60 a second (the wiki, half of it Blaze's in Patch 1.0)",
		HH.height.value == 1.2 and HH.height.status == "confirmed" and HH.burn.value == 60
	)
	check(
		"4.5 m round, spreading over 0.75 s, burning for 4 s, for 1.5 s of air time at most (the wiki)",
		HH.radius.value == 4.5 and HH.spread.value == 0.75 and HH.duration.value == 4 and HH.airTime.value == 1.5
	)
	check(
		"0.8 s to put it in hand and 0.7 s to have the gun back (the wiki)",
		BALL.equipTime.value == 0.8
			and HH.unequip.value == 0.7
			and AbilityConfig.unequip("hothands") == 0.7
			and AbilityConfig.unequip("curveball") == AbilityConfig.Curveball.unequip.value
	)
	check(
		"the fireball, a weapon of the fifth slot that's never reloaded, and Hot Hands'",
		BALL.category == "ability"
			and BALL.slot == ULT
			and BALL.ability == "hothands"
			and def.weapon == "fireball"
			and BALL.magazine.value == 1
			and BALL.reserve.value == 0
			and BALL.name == "Hot Hands"
	)
	local item = Shop.item("hothands")
	check(
		"Hot Hands' charge is sold on Q, the fireball never",
		item ~= nil and item.price == 200 and item.slot == "Q" and Shop.item("fireball") == nil
	)
end

-- The kit --------------------------------------------------------------------------------------

do
	local k = AbilitySim.new(PHOENIX)
	check("a new kit has no Hot Hands", k.charges[Q] == 0)
	check("one can be bought", AbilitySim.canBuy(k, "hothands") and AbilitySim.buy(k, "hothands") and k.charges[Q] == 1)
	check("but not a second", not AbilitySim.buy(k, "hothands") and k.charges[Q] == 1)
	check("and sold back", AbilitySim.sell(k, "hothands") and k.charges[Q] == 0)
	AbilitySim.fill(k)
	check("the course fills it", k.charges[Q] == 1 and k.charges[E] == 2)
	check("Inner Fire is his", AbilitySim.hasPassive(k, "innerfire") and not AbilitySim.hasPassive(AbilitySim.new("jett"), "innerfire"))
end

-- In hand --------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local _, casts = step(p, B.AbilityQ)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("Q puts the fireball in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "hothands" and cast.slot == Q)
	check("from the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "fireball" and w.back == 1)
	check("with nothing spent yet", kit.charges[Q] == 1 and kit.holding == Q)
	check("the kit says so", string.find(AbilitySim.summary(kit, now(p)), "equip", 1, true) ~= nil)
	local waited: number? = nil
	for n = 1, ticks(2) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot)), cfg, floor, DT)
		if probed and #ofKind(probed, "fireball") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be thrown once its 0.8 s equip is over",
		waited ~= nil and math.abs(waited - ticks(BALL.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

do
	local p = inHand()
	local yaw, pitch = -0.3, 0.2
	local shots, casts = step(p, B.Fire, yaw, pitch)
	local thrown = ofKind(casts, "fireball")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("fire throws it", thrown ~= nil and thrown.ability == "hothands" and thrown.slot == Q and thrown.lob == false)
	check(
		"from the eye, along the crosshair",
		thrown ~= nil
			and vector.magnitude(thrown.origin - PlayerSim.eye(p.sim, cfg)) < 1e-6
			and vector.magnitude(thrown.direction - Accuracy.aim(yaw, pitch)) < 1e-6
	)
	check("as a throw, not a bullet", #shots == 0 and thrown ~= nil and thrown.curve == nil)
	check("its charge spent", kit.charges[Q] == 0 and kit.holding == 0)
	check("the fireball gone, and the gun back in hand", w.loadout[ULT] == "" and w.equipped == 1)
	check("ready 0.7 s after", near(w.equipEndTime - now(p), HH.unequip.value, 1e-9), string.format("%.4f s", w.equipEndTime - now(p)))
	local _, again = step(p, B.AbilityQ)
	check("and with no charge left, Q does nothing", #again == 0 and p.sim.abilities.holding == 0 and w.equipped == 1)
end

do
	local p = inHand()
	local _, casts = step(p, B.AltFire)
	local thrown = ofKind(casts, "fireball")[1]
	check("alt fire lobs it", thrown ~= nil and thrown.lob == true)
	check("and doesn't zoom the gun", p.sim.weapons.scoped == 0)
end

do
	local p = newPlayer()
	step(p, B.AbilityQ)
	run(p, 0, 10)
	local _, casts = step(p, B.AbilityQ)
	local w, kit = p.sim.weapons, p.sim.abilities
	check("Q again puts it away unthrown", #casts == 0 and kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1)
	check("its charge kept", kit.charges[Q] == 1)
end

do
	local p = newPlayer()
	step(p, B.AbilityQ)
	run(p, 0, 10)
	local _, toFlare = step(p, B.AbilityE)
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"E with the fireball in hand puts the flare there instead",
		#toFlare == 1 and toFlare[1].ability == "curveball" and kit.holding == E and w.loadout[ULT] == "flare" and w.equipped == ULT
	)
	check("the gun still remembered, and both charges kept", w.back == 1 and kit.charges[Q] == 1 and kit.charges[E] == 2)
	run(p, 0, 10)
	local _, toBall = step(p, B.AbilityQ)
	check(
		"and Q the fireball again",
		#toBall == 1 and toBall[1].ability == "hothands" and kit.holding == Q and w.loadout[ULT] == "fireball"
	)
	run(p, 0, ticks(BALL.equipTime.value) + 1)
	local _, thrown = step(p, B.Fire)
	check(
		"a full equip from the change, then thrown, and the gun's back",
		#ofKind(thrown, "fireball") == 1 and w.equipped == 1 and w.loadout[ULT] == ""
	)
end

-- Its flight ------------------------------------------------------------------------------------

local AHEAD = vector.create(0, 0, -1)
local EYE = vector.create(0, 1.6, 0)
local G = HH.gravity.value * HH.worldGravity.value

do
	local f = FireballSim.throw(1, 1, EYE, AHEAD, false)
	local landed = FireballSim.fly(f, DT, floor)
	-- It falls from the eye until the box that flies rests on the floor.
	local fall = math.sqrt(2 * (EYE.y - HH.size.value) / G)
	check(
		"thrown level, it falls to the floor and bursts",
		landed ~= nil and near(landed, fall, DT),
		string.format("%s s", tostring(landed))
	)
	check(
		"where it fell, its speed ahead kept",
		near(f.position.z, -HH.speed.value * (landed or 0), 1e-3) and near(f.position.y, HH.size.value, 1e-3)
	)
	print(string.format("    a level throw from the eye bursts %.1f m ahead after %.2f s (ours)", -f.position.z, landed or 0))
	local lob = FireballSim.throw(1, 2, EYE, AHEAD, true)
	local lobbed = FireballSim.fly(lob, DT, floor)
	check("lobbed, it goes less far", lobbed ~= nil and -lob.position.z < -f.position.z and -lob.position.z > 1)
	print(string.format("    lobbed level, %.1f m ahead after %.2f s (ours)", -lob.position.z, lobbed or 0))
	-- Drawn from its keys, it's where it flew, tick by tick.
	local g = FireballSim.throw(1, 3, EYE, AHEAD, false)
	local worst = 0
	while not g.landed do
		FireballSim.step(g, DT, floor)
		if not g.landed then
			worst = math.max(worst, vector.magnitude(FireballSim.at(g.keys, g.age) - g.position))
		end
	end
	check("its keys draw it where it flew", worst < 1e-4, string.format("%.6f m", worst))
	check("and hold it where it burst after", vector.magnitude(FireballSim.at(g.keys, (g.landed or 0) + 5) - g.position) < 1e-9)
	check("thrown from the eye", vector.magnitude(FireballSim.at(g.keys, 0) - EYE) < 1e-9)
end

do
	local up = vector.normalize(vector.create(0, 3, -1))
	local f = FireballSim.throw(1, 4, EYE, up, false)
	local airborne = FireballSim.throw(1, 4, EYE, up, false)
	for _ = 1, ticks(HH.airTime.value) do
		FireballSim.step(airborne, DT, floor)
	end
	local landed = FireballSim.fly(f, DT, floor)
	check("thrown up, it's still in the air when its air time's up", airborne.landed == nil and airborne.position.y > 3)
	check(
		"and drops straight down from there",
		landed ~= nil
			and landed > HH.airTime.value
			and near(f.position.x, airborne.position.x, 1e-4)
			and near(f.position.z, airborne.position.z, 1e-4)
	)
	check("to the floor", near(f.position.y, HH.size.value, 1e-3))
	print(string.format("    thrown up steeply, it drops from %.1f m up, %.1f m ahead (ours)", airborne.position.y, -airborne.position.z))
end

do
	-- Thrown and lobbed at every pitch, it bursts on the floor every time,
	-- never through it.
	local missed = {}
	for pitch = -80, 80, 5 do
		for _, lob in { false, true } do
			local f = FireballSim.throw(1, 9, EYE, Accuracy.aim(0, math.rad(pitch)), lob)
			if FireballSim.fly(f, DT, floor) == nil or not near(f.position.y, HH.size.value, 1e-3) then
				table.insert(missed, string.format("%d%s", pitch, if lob then " lobbed" else ""))
			end
		end
	end
	check("thrown or lobbed at any pitch, it bursts on the floor", #missed == 0, table.concat(missed, ", "))
end

do
	-- A wall 4 m ahead, its face at z = -4.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-5, 0, -5), vector.create(5, 4, -4))
	local f = FireballSim.throw(1, 5, EYE, AHEAD, false)
	local landed = FireballSim.fly(f, DT, world)
	check(
		"off a wall, it comes back",
		landed ~= nil and f.position.z > -4 and #f.keys == 3,
		string.format("z %.2f, %d keys", f.position.z, #f.keys)
	)
	local bounce = f.keys[2]
	check(
		"keeping a share of its speed",
		bounce ~= nil and bounce.velocity.z > 0 and near(bounce.velocity.z, HH.speed.value * HH.bounce.value, 1e-3)
	)
	check("and bursts on the floor this side of it", near(f.position.y, HH.size.value, 1e-3) and f.position.z > -4 + HH.size.value)
end

do
	-- A ceiling 2.5 m up.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-50, 2.5, -50), vector.create(50, 3, 50))
	local f = FireballSim.throw(1, 6, EYE, vector.normalize(vector.create(0, 1, -1)), false)
	local landed = FireballSim.fly(f, DT, world)
	local hit = f.keys[2]
	check("off a ceiling, it comes down", landed ~= nil and hit ~= nil and hit.velocity.y < 0 and hit.position.y < 2.5)
	check("and bursts on the floor", near(f.position.y, HH.size.value, 1e-3))
end

do
	local f = FireballSim.throw(1, 7, EYE, AHEAD, false)
	check(
		"with no floor under it, it's given up on",
		FireballSim.fly(f, DT, FakeWorld.new()) == nil and f.age >= FireballSim.LONGEST - 1e-6
	)
	-- A ramp of 30 degrees rising ahead of it, met before the floor.
	local ramp = FakeWorld.new():addFloor():addPart(vector.create(0, 0, -16), vector.create(10, 1, 10), math.rad(30), 0, 0)
	local r = FireballSim.throw(1, 8, EYE, AHEAD, false)
	check("a slope level enough is a floor", FireballSim.fly(r, DT, ramp) ~= nil and #r.keys == 2)
end

-- Its fire ---------------------------------------------------------------------------------------

local CENTRE = vector.create(0, 0, 0)

do
	local open = FireSim.reaches(CENTRE, floor)
	local all = #open == FireSim.SECTORS
	for _, reach in open do
		all = all and reach == HH.radius.value
	end
	check("in the open it spreads to its radius each way round", all)
	-- A crate 2 m away on +x, and a kerb 2 m away on -x.
	local world = FakeWorld.new()
		:addFloor()
		:addBox(vector.create(2, 0, -0.5), vector.create(3, 1, 0.5))
		:addBox(vector.create(-3, 0, -10), vector.create(-2, 0.3, 10))
	local reaches = FireSim.reaches(CENTRE, world)
	local half = FireSim.SECTORS // 2 + 1
	check("a crate stops it", near(reaches[1], 2 - 0.01, 1e-3), string.format("%.3f m", reaches[1]))
	check("a kerb doesn't", reaches[half] == HH.radius.value)
	local pool = FireSim.new(1, 1, CENTRE, 100, reaches)
	local t = 100 + HH.spread.value
	check(
		"it spreads from nothing",
		FireSim.radiusAt(pool, 100) == 0 and near(FireSim.radiusAt(pool, 100 + HH.spread.value / 2), HH.radius.value / 2, 1e-9)
	)
	check(
		"to its radius over its spread",
		FireSim.radiusAt(pool, t) == HH.radius.value and FireSim.radiusAt(pool, t + 1) == HH.radius.value
	)
	check(
		"burning for its duration, then out",
		FireSim.burning(pool, 100) and FireSim.burning(pool, 103.99) and not FireSim.burning(pool, 104)
	)
	check("standing on it, at once", FireSim.inside(pool, CENTRE, 100.01))
	check(
		"3 m out, not until it's spread there",
		not FireSim.inside(pool, vector.create(0, 0, 3), 100.1) and FireSim.inside(pool, vector.create(0, 0, 3), t)
	)
	check(
		"within its radius, all the way round",
		FireSim.inside(pool, vector.create(0, 0, -4.4), t)
			and FireSim.inside(pool, vector.create(-3.1, 0, 3.1), t)
			and FireSim.inside(pool, vector.create(-4.4, 0, 0), t)
	)
	check("and no further", not FireSim.inside(pool, vector.create(0, 0, -4.6), t))
	check("but a body half over its edge", FireSim.inside(pool, vector.create(0, 0, -4.6), t, cfg.halfWidth))
	check(
		"not behind the crate",
		not FireSim.inside(pool, vector.create(3.5, 0, 0), t) and FireSim.inside(pool, vector.create(1.9, 0, 0), t)
	)
	check(
		"burning up to 1.2 m over its floor, no higher",
		FireSim.inside(pool, vector.create(1, 1.15, 1), t) and not FireSim.inside(pool, vector.create(1, 1.25, 1), t)
	)
	check(
		"and a step below it",
		FireSim.inside(pool, vector.create(1, -0.4, 1), t) and not FireSim.inside(pool, vector.create(1, -HH.depth.value - 0.1, 1), t)
	)
	check("not once it's out", not FireSim.inside(pool, CENTRE, 104))
	print(
		string.format(
			"    a standing jump peaks %.2f m up, under the %.2f m it reaches, so no jump gets out of it",
			cfg.jumpApexHeight,
			HH.height.value
		)
	)
	check("no jump gets out of it", cfg.jumpApexHeight < HH.height.value)
	local edge = FireSim.edge(pool, t)
	check(
		"its edge, drawn round from the first side",
		#edge == FireSim.SECTORS and near(edge[1].x, reaches[1], 1e-6) and near(edge[half].x, -HH.radius.value, 1e-6)
	)
	check(
		"the floor it burns on is under the ball",
		vector.magnitude(FireSim.floorUnder(vector.create(1, HH.size.value, 2)) - vector.create(1, 0, 2)) < 1e-9
	)
end

-- The burn and the heal -----------------------------------------------------------------------

do
	check(
		"60 a second from an enemy, a share of it from an ally",
		FireSim.burnRate(false) == 60 and near(FireSim.burnRate(true), 60 * HH.allyShare.value, 1e-9)
	)
	-- Standing in it from the burst, a frame at a time at 60 frames a second.
	local o = FireSim.owed()
	local total, gifts, gap = 0, 0, math.huge
	local last: number? = nil
	local frame = 1 / 60
	for n = 1, math.floor(HH.duration.value / frame + 0.5) do
		local at = n * frame
		local points = FireSim.owe(o, FireSim.burnRate(false) * frame, at, 0.1)
		if points > 0 then
			total += points
			gifts += 1
			if last then
				gap = math.min(gap, at - last)
			end
			last = at
		end
	end
	-- And what's left owed, given as it's out.
	total += FireSim.owe(o, 0, HH.duration.value, 0)
	check("all of it for its duration takes 240", math.abs(total - 240) <= 1, tostring(total))
	check("given a few points at a time", gifts <= 41 and gifts >= 30 and gap >= 0.1 - 1e-9, string.format("%d gifts", gifts))
	check("the first at once", FireSim.owe(FireSim.owed(), 1, 0, 0.1) == 1)
	check("Inner Fire: nothing at the first touch", FireSim.healed(0) == 0)
	check("then a point every 0.08 s", FireSim.healed(0.08) == 1 and FireSim.healed(0.159) == 1 and FireSim.healed(2) == 25)
	check("all 50 in 4 s, and no more", FireSim.healed(4) == 50 and FireSim.healed(10) == 50 and near(FireSim.healTime(), 4, 1e-9))
end

-- The wire -------------------------------------------------------------------------------------

do
	local p = newPlayer()
	step(p, B.AbilityQ)
	run(p, 0, 20)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	check(
		"the ack carries the fireball in hand",
		decoded.abilities.holding == Q and decoded.weapons.loadout[ULT] == "fireball" and decoded.weapons.equipped == ULT
	)
	local copy = decoded :: PlayerSim.State
	local left: Player = { sim = copy, slot = p.slot }
	local same = true
	local throws = 0
	for i = 1, 200 do
		local buttons = if i == 90 then B.AltFire else 0
		local _, c1 = step(p, buttons)
		local _, c2 = step(left, buttons)
		local f1, f2 = ofKind(c1, "fireball"), ofKind(c2, "fireball")
		throws += #f1
		same = same and #f1 == #f2 and (f1[1] == nil or f1[1].lob == f2[1].lob) and p.sim.weapons.equipped == copy.weapons.equipped
	end
	check(
		"and a replay from it lobs as it does, to the same end",
		same and throws == 1 and copy.abilities.charges[Q] == 0,
		tostring(throws)
	)
end

return nil
