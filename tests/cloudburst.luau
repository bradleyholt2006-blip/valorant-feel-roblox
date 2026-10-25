--!strict
-- Jett's Cloudburst (system 18): its numbers and where they come from, the
-- throw as PlayerSim casts it (the charge, the aim, the gun put away), its
-- flight through CloudSim (straight, into a wall or the floor, at its
-- longest, the curve while C is held), the same flight from a copy, and
-- the cloud's size and thickness through its life.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local CloudSim = require("../src/shared/Abilities/CloudSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Shop = require("../src/shared/Weapons/Shop")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local air = FakeWorld.new() -- nothing to hit
local CB = AbilityConfig.Cloudburst
local J = AbilityConfig.Jett
local C = AbilityConfig.C
local EYE = vector.create(0, 1.62, 0)
local AHEAD = vector.create(0, 0, -1)

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player settled on the floor with `gun` drawn and a full kit.
local function newPlayer(gun: string?): PlayerSim.State
	local s = PlayerSim.new(vector.create(0, 0.02, 0), { gun or "vandal", "classic", "knife", "" })
	AbilitySim.fill(s.abilities)
	for _ = 1, ticks(1.5) do
		PlayerSim.step(s, input(0), cfg, floor, DT)
	end
	return s
end

-- One tick; returns its bullets' count and its casts.
local function step(s: PlayerSim.State, buttons: number, yaw: number?, pitch: number?): (number, { AbilitySim.Cast })
	local shots, _, _, _, casts = PlayerSim.step(s, input(buttons, yaw, pitch), cfg, floor, DT)
	return if shots then #shots else 0, casts or {}
end

-- Flies `p` until it bursts, steered at `aim` while `held`; returns where,
-- and the ticks it took (nil if it never did in `limit`).
local function fly(p: CloudSim.Projectile, world: any, aim: vector?, held: boolean?, limit: number?): (vector?, number)
	for n = 1, limit or 1000 do
		local at = CloudSim.step(p, aim or vector.normalize(p.velocity), held == true, DT, world)
		if at then
			return at, n
		end
	end
	return nil, limit or 1000
end

local function angle(a: vector, b: vector): number
	return math.acos(math.clamp(vector.dot(vector.normalize(a), vector.normalize(b)), -1, 1))
end

H.section("Cloudburst tests")

-- Its numbers --------------------------------------------------------------------------------

do
	local labelled = true
	for _, param in CB do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Cloudburst number says where it's from", labelled)
	check(
		"30 m/s, 2 s at most in the air, a 3.35 m cloud for 2.5 s",
		CB.speed.value == 30 and CB.maxFlight.value == 2 and CB.radius.value == 3.35 and CB.duration.value == 2.5
	)
	check("the cloud's 2.5 s is the patch notes'", CB.duration.status == "confirmed")
	local def = AbilityConfig.Defs.cloudburst
	check(
		"Jett's basic on C: two charges at 200 credits",
		def.slot == C
			and def.kind == "basic"
			and def.charges ~= nil
			and def.charges.value == 2
			and def.cost ~= nil
			and def.cost.value == 200
	)
	check("and it can be played now", AbilitySim.playable("cloudburst"))
end

-- The throw ----------------------------------------------------------------------------------

do
	local s = newPlayer()
	check("a full kit holds two", s.abilities.charges[C] == 2)
	local eye = PlayerSim.eye(s, cfg)
	local yaw, pitch = math.rad(90), math.rad(30)
	local _, casts = step(s, B.AbilityC, yaw, pitch)
	local cast = casts[1]
	check("C throws it at once, and spends a charge", cast ~= nil and cast.kind == "throw" and s.abilities.charges[C] == 1)
	if cast then
		check("named by the tick it's thrown on", cast.ability == "cloudburst" and cast.tick == s.movement.tick)
		check("from the eye", vector.magnitude(cast.origin - eye) < 1e-9)
		local aim = Accuracy.aim(yaw, pitch)
		check("the way you look, up and down as well as round", vector.magnitude(cast.direction - aim) < 1e-9 and cast.direction.y > 0.49)
	end
	local more = 0
	for _ = 1, 20 do
		local _, held = step(s, B.AbilityC, yaw, pitch)
		more += #held
	end
	check("held, it throws once", more == 0 and s.abilities.charges[C] == 1)
	step(s, 0)
	local _, again = step(s, B.AbilityC)
	check("let go and pressed again, the second goes", #again == 1 and again[1].kind == "throw" and s.abilities.charges[C] == 0)
	step(s, 0)
	local _, none = step(s, B.AbilityC)
	check("with none left, C does nothing", #none == 0 and s.abilities.charges[C] == 0)
end

do
	-- A throw puts the gun away for a moment.
	local s = newPlayer()
	step(s, B.AbilityC)
	local blocked = 0
	for _ = 1, ticks(CB.stow.value) - 1 do
		local fired = step(s, B.Fire)
		blocked += fired
	end
	check("the gun can't fire for a moment after a throw", blocked == 0)
	local fired = 0
	for _ = 1, 3 do
		fired += step(s, B.Fire)
	end
	check(string.format("and fires again %s s after it", CB.stow.value), fired > 0)

	local r = newPlayer()
	for _ = 1, 3 do
		step(r, B.Fire)
	end
	step(r, 0)
	step(r, B.Reload)
	step(r, 0)
	check("reloading", r.weapons.reloadEndTime > 0)
	step(r, B.AbilityC)
	check("a throw stops a reload", r.weapons.reloadEndTime == 0)

	local o = newPlayer("operator")
	step(o, B.AltFire)
	for _ = 1, 2 do
		step(o, 0)
	end
	check("zoomed in", o.weapons.scoped == 1)
	step(o, B.AbilityC)
	check("and takes the zoom off", o.weapons.scoped == 0)
end

do
	-- Nothing throws in a dash, or while a plant roots you.
	local s = newPlayer()
	step(s, B.AbilityE)
	for _ = 1, ticks(J.windup.value) + 1 do
		step(s, 0)
	end
	local _, dash = step(s, B.AbilityE)
	check("dashing", #dash == 1 and dash[1].kind == "dash")
	step(s, 0)
	local _, during = step(s, B.AbilityC)
	check("C does nothing in a dash", #during == 0 and s.abilities.charges[C] == 2)

	local k = AbilitySim.new()
	AbilitySim.fill(k)
	local _, casts = AbilitySim.step(k, input(B.AbilityC), 1, DT, 128, vector.create(0, 0, 0), EYE, true, cfg)
	check("nor while a plant or a defuse roots you", casts == nil and k.charges[C] == 2)
end

-- Its flight ---------------------------------------------------------------------------------

do
	local p = CloudSim.throw(1, 7, EYE, AHEAD * 2)
	check("thrown at its speed, whatever the aim's length", near(vector.magnitude(p.velocity), CB.speed.value, 1e-9))
	check("named for its thrower and its tick, from the eye", p.owner == 1 and p.id == 7 and p.position == EYE and p.age == 0)
	CloudSim.step(p, AHEAD, false, DT, air)
	check("a tick takes it 30 m/s on", near(p.position.z, -CB.speed.value * DT, 1e-12) and near(p.position.y, EYE.y, 1e-12))
	local at, n = fly(p, air)
	check("in the open it flies straight, with no drop", at ~= nil and near(at.y, EYE.y, 1e-9) and near(at.x, 0, 1e-9))
	check(
		"and bursts at its longest: 2 s and 60 m out",
		at ~= nil and n + 1 == ticks(CB.maxFlight.value) and near(p.age, 2, 1e-9) and near(-at.z, 60, 1e-6),
		string.format("%d ticks, %.4f s, %.3f m", n + 1, p.age, if at then -at.z else 0)
	)
end

do
	local wall = FakeWorld.new():addFloor():addBox(vector.create(-10, 0, -11), vector.create(10, 6, -10))
	local p = CloudSim.throw(1, 1, EYE, AHEAD)
	local at, n = fly(p, wall)
	check(
		"it bursts where it hits a wall, a ball's width off it",
		at ~= nil and near(at.z, -10 + CB.size.value, 1e-6) and near(at.y, EYE.y, 1e-9),
		if at then string.format("z %.4f", at.z) else nil
	)
	check(
		"part-way through the tick it hits on",
		at ~= nil and near(p.age, (10 - CB.size.value) / CB.speed.value, 1e-9) and n == math.ceil(p.age / DT)
	)

	local down = CloudSim.throw(1, 2, EYE, vector.create(0, -1, -1))
	local ground = fly(down, floor)
	check(
		"thrown at the floor, it bursts on it",
		ground ~= nil and near(ground.y, CB.size.value, 1e-6) and near(ground.z, -(EYE.y - CB.size.value), 1e-6)
	)
end

do
	-- Held C curves it towards the crosshair; let go, it's straight from
	-- then on.
	local right = vector.create(1, 0, 0)
	check("aimed at +X, the crosshair points there", vector.magnitude(Accuracy.aim(math.rad(-90), 0) - right) < 1e-9)
	local p = CloudSim.throw(1, 1, EYE, AHEAD)
	local before = p.velocity
	CloudSim.step(p, right, true, DT, air)
	local turned = angle(before, p.velocity)
	check(
		string.format("held, it turns towards it at %s degrees a second", CB.turnRate.value),
		near(turned, math.rad(CB.turnRate.value) * DT, 1e-5),
		string.format("%.4f degrees in a tick", math.deg(turned))
	)
	-- (A vector holds single precision, so a thousandth of a millimetre a
	-- second is as close as its length comes.)
	check("keeping its speed", near(vector.magnitude(p.velocity), CB.speed.value, 1e-5))
	check("in the plane between the two", math.abs(p.velocity.y) < 1e-9 and p.velocity.x > 0)
	-- A quarter turn takes 90 / 240 of a second, and a tick more for the
	-- single precision's rounding.
	local quarter = math.ceil(math.rad(90) / (math.rad(CB.turnRate.value) * DT)) + 1
	for _ = 2, quarter do
		CloudSim.step(p, right, true, DT, air)
	end
	check("and once it points there, it flies there", vector.magnitude(vector.normalize(p.velocity) - right) < 1e-6)

	local q = CloudSim.throw(1, 2, EYE, AHEAD)
	CloudSim.step(q, right, true, DT, air)
	CloudSim.step(q, right, false, DT, air)
	local let = vector.normalize(q.velocity)
	CloudSim.step(q, right, true, DT, air)
	check(
		"let go, it flies straight on, and C held again doesn't steer it",
		not q.curving and vector.magnitude(vector.normalize(q.velocity) - let) < 1e-12
	)

	local behind = CloudSim.turn(AHEAD, -AHEAD, 0.1)
	check("with the crosshair straight behind, it keeps on (no way round is shorter)", behind == AHEAD)
	local close = vector.normalize(vector.create(0.001, 0, -1))
	check("and within a tick's turn of the crosshair, it's on it", CloudSim.turn(AHEAD, close, 0.1) == close)
end

do
	-- CloudSim.tick: the thrower's ticks, as the server and their own
	-- screen both fly them.
	local s = newPlayer()
	local list: { CloudSim.Projectile } = {}
	local _, casts = step(s, B.AbilityC)
	local bursts = CloudSim.tick(list, 5, input(B.AbilityC), casts, DT, floor)
	check(
		"a throw joins the list on its tick, unflown",
		#bursts == 0 and #list == 1 and list[1].age == 0 and list[1].position == casts[1].origin
	)
	check("named for its thrower and its tick", list[1].owner == 5 and list[1].id == casts[1].tick)
	CloudSim.tick(list, 5, input(B.AbilityC), nil, DT, floor)
	check("and flies from the next", near(list[1].age, DT, 1e-12) and list[1].curving)
	CloudSim.tick(list, 5, input(0), nil, DT, floor)
	check("C let go on a tick lets it go", not list[1].curving)

	step(s, 0)
	local _, second = step(s, B.AbilityC)
	CloudSim.tick(list, 5, input(B.AbilityC), second, DT, floor)
	check("two in the air at once", #list == 2)
	local got: { CloudSim.Burst } = {}
	for _ = 1, ticks(CB.maxFlight.value) + 2 do
		for _, b in CloudSim.tick(list, 5, input(0), nil, DT, floor) do
			table.insert(got, b)
		end
	end
	check(
		"each bursts on its own tick, the first first, and leaves the list",
		#got == 2 and got[1].id == casts[1].tick and got[2].id == second[1].tick and #list == 0
	)
	check("each with where it burst, and how long it flew", near(got[1].age, CB.maxFlight.value, 1e-9) and got[1].owner == 5)
end

do
	-- The same inputs fly it the same way: a copy flown on, as the server
	-- flies its own from the same ticks.
	local list = { CloudSim.throw(1, 1, EYE, AHEAD) }
	local copy: { CloudSim.Projectile } = {}
	local burstA: vector?, burstB: vector? = nil, nil
	local yaw = 0
	for n = 1, ticks(3) do
		yaw += math.rad(1.3)
		local now = input(if n < 60 then B.AbilityC else 0, yaw, math.rad(5))
		if n == 30 then
			copy = { CloudSim.copy(list[1]) }
		end
		for _, b in CloudSim.tick(list, 1, now, nil, DT, floor) do
			burstA = b.position
		end
		if n >= 30 then
			for _, b in CloudSim.tick(copy, 1, now, nil, DT, floor) do
				burstB = b.position
			end
		end
	end
	check("a copy flies on as the original does, to the same burst", burstA ~= nil and burstA == burstB)

	local p = CloudSim.throw(1, 1, EYE, AHEAD)
	local q = CloudSim.copy(p)
	CloudSim.step(q, AHEAD, false, DT, air)
	check("and flying the copy doesn't move the original", p.position == EYE and p.age == 0)
end

do
	-- A throw nobody steers (its thrower is dead or gone).
	local p = CloudSim.throw(1, 1, EYE, vector.create(1, 0, -1))
	local way = vector.normalize(p.velocity)
	local at
	for _ = 1, ticks(3) do
		at = CloudSim.drift(p, DT, air)
		if at then
			break
		end
	end
	check(
		"left alone, it flies straight on and bursts at its longest",
		at ~= nil and vector.magnitude(vector.normalize(p.velocity) - way) < 1e-12 and near(p.age, CB.maxFlight.value, 1e-9)
	)
end

-- The cloud ----------------------------------------------------------------------------------

do
	local R, grow = CB.radius.value, CB.grow.value
	check("nothing before it bursts", CloudSim.radiusAt(-0.01) == 0 and CloudSim.thicknessAt(-0.01) == 0)
	check("it starts from nothing", CloudSim.radiusAt(0) == 0)
	check(
		string.format("and grows to its full %s m over %s s, fastest at first", R, grow),
		near(CloudSim.radiusAt(grow / 2), 0.75 * R, 1e-9)
			and CloudSim.radiusAt(grow) == R
			and CloudSim.radiusAt(0.1) - CloudSim.radiusAt(0) > CloudSim.radiusAt(grow) - CloudSim.radiusAt(grow - 0.1)
	)
	check("full until it goes", CloudSim.radiusAt(CB.duration.value - 0.01) == R)
	check(
		string.format("gone at %s s", CB.duration.value),
		CloudSim.radiusAt(CB.duration.value) == 0 and CloudSim.thicknessAt(CB.duration.value) == 0
	)
	local fade = CB.fade.value
	check(
		string.format("thick until its last %s s, then thinning to nothing", fade),
		CloudSim.thicknessAt(0) == 1
			and near(CloudSim.thicknessAt(CB.duration.value - fade), 1, 1e-9)
			and CloudSim.thicknessAt(CB.duration.value - fade - 0.01) == 1
			and near(CloudSim.thicknessAt(CB.duration.value - fade / 2), 0.5, 1e-9)
	)
	local centre = vector.create(4, 1, -20)
	check(
		"inside it: within its radius while it lasts",
		CloudSim.inside(centre, 1, centre + vector.create(R - 0.05, 0, 0))
			and not CloudSim.inside(centre, 1, centre + vector.create(R + 0.05, 0, 0))
			and not CloudSim.inside(centre, CB.duration.value + 0.1, centre)
	)
	check("not yet a metre out at first, as it's still growing", not CloudSim.inside(centre, 0.05, centre + vector.create(0, 0, 1)))
end

-- The shop -----------------------------------------------------------------------------------

do
	local item = Shop.item("cloudburst")
	check(
		"Cloudburst is on sale on its key, 200 a charge",
		item ~= nil and item.kind == "ability" and item.price == 200 and item.slot == "C"
	)
	local k = AbilitySim.new()
	check(
		"two can be bought, but not a third",
		AbilitySim.buy(k, "cloudburst") and AbilitySim.buy(k, "cloudburst") and not AbilitySim.buy(k, "cloudburst") and k.charges[C] == 2
	)
	check("the kit reads them", string.sub(AbilitySim.summary(k, 0), 1, 4) == "C2/2")
end

return nil
