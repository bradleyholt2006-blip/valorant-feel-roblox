--!strict
-- Wall penetration (system 5): the trace through walls, the damage left
-- after them, and shots at targets behind walls.

local Penetration = require("../src/shared/Combat/Penetration")
local ShotResolver = require("../src/shared/Combat/ShotResolver")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local FakeLevel = require("./FakeLevel")
local H = require("./Harness")

local check, near = H.check, H.near

type Class = WeaponConfig.PenetrationClass
type Material = Penetration.Material

local cfg = WeaponConfig.Penetration
local E = cfg.entryCost.value
local LOSS = cfg.damageLoss.value

local ORIGIN = vector.create(0, 1.17, 0) -- chest height
local FORWARD = vector.create(0, 0, -1)
local RANGE = WeaponConfig.MaxRange

-- Budget one wall takes when the bullet enters it from open air.
local function cost(class: Class, material: Material, thickness: number): number
	return E + (1 - E) * thickness / Penetration.limit(class, material)
end

-- One wall `thickness` deep, its face 5 m ahead.
local function single(material: Material, thickness: number, class: Class): Penetration.Trace
	local level = FakeLevel.new()
	level:wall(material, 5, thickness)
	return Penetration.trace(level, ORIGIN, FORWARD, class, RANGE)
end

local function passes(material: Material, thickness: number, class: Class): boolean
	return not single(material, thickness, class).stopped
end

H.section("Penetration tests")

do
	check(
		"Low gets through wood and glass, not stone or metal",
		passes("soft", 0.1, "low") and not passes("medium", 0.1, "low") and not passes("hard", 0.1, "low")
	)
	check(
		"Medium gets through stone, not metal",
		passes("soft", 0.1, "medium") and passes("medium", 0.1, "medium") and not passes("hard", 0.1, "medium")
	)
	check("High gets through metal", passes("soft", 0.1, "high") and passes("medium", 0.1, "high") and passes("hard", 0.1, "high"))
	check("solid surfaces stop every class", not passes("solid", 0.01, "high") and not passes("solid", 0.01, "low"))
	check("the knife class gets through nothing", not passes("soft", 0.01, "none"))
	local blocked = single("hard", 0.1, "medium")
	check(
		"a wall the class can't penetrate stops the bullet at its face",
		blocked.stopped and near(blocked.stop, 5, 1e-5) and blocked.walls[1].exit == nil
	)
	check(
		"our weapons' classes",
		WeaponConfig.get("classic").penetration == "low"
			and WeaponConfig.get("vandal").penetration == "medium"
			and WeaponConfig.get("phantom").penetration == "medium"
			and WeaponConfig.get("sheriff").penetration == "high"
			and WeaponConfig.get("operator").penetration == "high"
			and WeaponConfig.get("knife").penetration == "none"
	)
end

do
	local limit = Penetration.limit("medium", "soft")
	check("a wall just under the limit is gone through", passes("soft", limit - 0.01, "medium"))
	local thick = single("soft", limit + 0.01, "medium")
	check("a wall just over it stops the bullet inside", thick.stopped and thick.walls[1].exit == nil)
	check("as deep as the limit", near(thick.stop, 5 + limit, 1e-4), string.format("%.4f", thick.stop))
	local trace = single("soft", 0.2, "medium")
	local wall = trace.walls[1]
	check(
		"thickness is measured entry to exit",
		near(wall.thickness, 0.2, 1e-5) and near(wall.entry, 5, 1e-5) and near(wall.exit or 0, 5.2, 1e-5)
	)
	check(
		"entry and exit faces face out",
		vector.dot(wall.normal, FORWARD) < -0.99 and wall.exitNormal ~= nil and vector.dot(wall.exitNormal :: vector, FORWARD) > 0.99
	)
	local far = FakeLevel.new()
	far:wall("soft", 5, 0.1)
	local short = Penetration.trace(far, ORIGIN, FORWARD, "high", 4)
	check("a wall beyond the range isn't reached", #short.walls == 0 and not short.stopped and short.stop == 4)
end

do
	-- The same 0.2 m stone wall square on and at 45 degrees.
	local diagonal = vector.normalize(vector.create(1, 0, -1))
	local function at(class: Class, dir: vector): Penetration.Trace
		local level = FakeLevel.new()
		level:wall("medium", 2, 0.2)
		return Penetration.trace(level, ORIGIN, dir, class, RANGE)
	end
	check("the Vandal's class gets through 0.20 m of stone square on", not at("medium", FORWARD).stopped)
	check("but not at 45 degrees", at("medium", diagonal).stopped)
	local angled = at("high", diagonal)
	check(
		"at 45 degrees the wall is 1.41x thicker",
		near(angled.walls[1].thickness, 0.2 * math.sqrt(2), 1e-4),
		string.format("%.4f", angled.walls[1].thickness)
	)
	check("and costs more damage", Penetration.multiplierAt(angled, RANGE) < Penetration.multiplierAt(at("high", FORWARD), RANGE))
	local table45 = Penetration.oneWall("high", "medium", 0.2, 45)
	check(
		"the one-wall table agrees with the trace at 45 degrees",
		table45 ~= nil and near(table45, Penetration.multiplierAt(angled, RANGE), 1e-4)
	)
	check("and says the Vandal's class stops there", Penetration.oneWall("medium", "medium", 0.2, 45) == nil)
end

do
	local agree = true
	for _, class in { "none", "low", "medium", "high" } :: { Class } do
		for _, material in { "soft", "medium", "hard", "solid" } :: { Material } do
			for _, t in { 0.05, 0.1, 0.2, 0.4, 0.8 } do
				local trace = single(material, t, class)
				local fromTable = Penetration.oneWall(class, material, t)
				local fromTrace = if trace.stopped then nil else Penetration.multiplierAt(trace, RANGE)
				if (fromTable == nil) ~= (fromTrace == nil) or (fromTable and fromTrace and not near(fromTable, fromTrace, 1e-4)) then
					agree = false
				end
			end
		end
	end
	check("the one-wall table agrees with the trace for every class, material and thickness", agree)
end

do
	local trace = single("soft", 0.2, "medium")
	local m = 1 - LOSS * cost("medium", "soft", 0.2)
	check(
		"damage left is 1 - loss * budget spent",
		near(Penetration.multiplierAt(trace, RANGE), m, 1e-5),
		string.format("%.4f vs %.4f", Penetration.multiplierAt(trace, RANGE), m)
	)
	check("before the wall, full damage", Penetration.multiplierAt(trace, 4.9) == 1)
	check("a hit inside the wall keeps the damage from before it", Penetration.multiplierAt(trace, 5.1) == 1)
	check("one wall gone through", Penetration.wallsBefore(trace, RANGE) == 1 and Penetration.wallsBefore(trace, 5.1) == 0)
	check(
		"a bullet that barely gets through keeps 1 - loss",
		near(1 - LOSS * cost("medium", "soft", Penetration.limit("medium", "soft")), 1 - LOSS, 1e-9)
	)
	check(
		"damage is rounded",
		Penetration.damage(40, 0.655) == 26 and Penetration.damage(160, 0.655) == 105 and Penetration.damage(40, 1) == 40
	)
	check("a hit that gets through does at least 1", Penetration.damage(3, 0.1) == 1)
end

do
	local level = FakeLevel.new()
	level:wall("soft", 5, 0.1)
	level:wall("medium", 8, 0.1)
	local trace = Penetration.trace(level, ORIGIN, FORWARD, "medium", RANGE)
	local c1, c2 = cost("medium", "soft", 0.1), cost("medium", "medium", 0.1)
	check("two walls: both entries paid", #trace.walls == 2 and not trace.walls[2].continues and Penetration.wallsBefore(trace, RANGE) == 2)
	check("damage between the walls is from the first only", near(Penetration.multiplierAt(trace, 7), 1 - LOSS * c1, 1e-5))
	check("past both, from both", near(Penetration.multiplierAt(trace, RANGE), 1 - LOSS * (c1 + c2), 1e-5))
end

do
	-- 0.15 m of metal takes most of the budget; what is left reaches only so far into the wood.
	local level = FakeLevel.new()
	level:wall("hard", 5, 0.15)
	level:wall("soft", 7, 1.0)
	local trace = Penetration.trace(level, ORIGIN, FORWARD, "high", RANGE)
	local left = 1 - cost("high", "hard", 0.15) - E
	local reach = left / ((1 - E) / Penetration.limit("high", "soft"))
	check(
		"the budget carries over from wall to wall",
		trace.stopped and near(trace.stop, 7 + reach, 1e-4),
		string.format("%.4f vs %.4f", trace.stop, 7 + reach)
	)
end

do
	local function multiplier(build: (any) -> ()): (number, Penetration.Trace)
		local level = FakeLevel.new()
		build(level)
		local trace = Penetration.trace(level, ORIGIN, FORWARD, "medium", RANGE)
		return Penetration.multiplierAt(trace, RANGE), trace
	end
	local one = multiplier(function(level)
		level:wall("soft", 5, 0.2)
	end)
	local flush, flushTrace = multiplier(function(level)
		level:wall("soft", 5, 0.1)
		level:wall("soft", 5.1, 0.1)
	end)
	check(
		"two touching pieces cost what one wall of both does",
		near(flush, one, 1e-5) and flushTrace.walls[2].continues and Penetration.wallsBefore(flushTrace, RANGE) == 1
	)
	local overlap = multiplier(function(level)
		level:wall("soft", 5, 0.2)
		level:wall("soft", 5.1, 0.2)
	end)
	local three = multiplier(function(level)
		level:wall("soft", 5, 0.3)
	end)
	check("an overlap is paid for once", near(overlap, three, 1e-5))
	local inside, insideTrace = multiplier(function(level)
		level:wall("soft", 5, 0.4)
		level:wall("soft", 5.1, 0.1)
	end)
	local four = multiplier(function(level)
		level:wall("soft", 5, 0.4)
	end)
	check("a piece inside another adds nothing", near(inside, four, 1e-5) and #insideTrace.walls == 1)
	local _, rebar = multiplier(function(level)
		level:wall("soft", 5, 0.4)
		level:wall("solid", 5.2, 0.05)
	end)
	check("a solid piece inside a wall stops the bullet at its face", rebar.stopped and near(rebar.stop, 5.2, 1e-5))
end

do
	-- Many touching 1 mm sheets: past maxPieces the next piece stops the bullet.
	local level = FakeLevel.new()
	for i = 0, 19 do
		level:wall("soft", 5 + i * 0.001, 0.001)
	end
	local trace = Penetration.trace(level, ORIGIN, FORWARD, "high", RANGE)
	check(
		"the trace gives up after maxPieces",
		trace.stopped and #trace.walls == cfg.maxPieces + 1 and near(trace.stop, 5 + cfg.maxPieces * 0.001, 1e-4)
	)
end

do
	-- Shots at a dummy standing 1 m behind a wall face.
	local target = { id = 1, pose = { position = vector.create(0, 0, -6.2), yaw = 0, crouchAlpha = 0 } }
	local function shoot(material: Material, thickness: number, weapon: string): (ShotResolver.Result?, number)
		local def = WeaponConfig.get(weapon)
		local level = FakeLevel.new()
		level:wall(material, 5, thickness)
		local trace = Penetration.trace(level, ORIGIN, FORWARD, def.penetration, RANGE)
		local hit = ShotResolver.resolve(ORIGIN, FORWARD, { target }, trace.stop, nil)
		if not hit then
			return nil, 0
		end
		return hit, Penetration.damage(WeaponConfig.damageAt(def, hit.region, hit.distance), Penetration.multiplierAt(trace, hit.distance))
	end
	local hit, dmg = shoot("soft", 0.1, "vandal")
	local expect = Penetration.damage(40, 1 - LOSS * cost("medium", "soft", 0.1))
	check(
		"a Vandal body shot through 0.10 m of wood hits, for less",
		hit ~= nil and hit.region == "body" and dmg == expect and dmg < 40,
		string.format("%d vs %d", dmg, expect)
	)
	check("the Classic can't hit through stone", (shoot("medium", 0.1, "classic")) == nil)
	check("the Vandal can", (shoot("medium", 0.1, "vandal")) ~= nil)
	check("nothing hits through a solid wall", (shoot("solid", 0.05, "operator")) == nil)

	-- A target whose box reaches into a wall the bullet can't get through.
	local clipped = { id = 2, pose = { position = vector.create(0, 0, -5.3), yaw = 0, crouchAlpha = 0 } }
	local level = FakeLevel.new()
	level:wall("soft", 5, 2)
	local trace = Penetration.trace(level, ORIGIN, FORWARD, "medium", RANGE)
	local inside = ShotResolver.resolve(ORIGIN, FORWARD, { clipped }, trace.stop, nil)
	check(
		"a target inside the stretch a bullet reaches takes full damage",
		trace.stopped and inside ~= nil and Penetration.multiplierAt(trace, inside.distance) == 1
	)
	local deep = { id = 3, pose = { position = vector.create(0, 0, -6.4), yaw = 0, crouchAlpha = 0 } }
	check("but not one deeper in", ShotResolver.resolve(ORIGIN, FORWARD, { deep }, trace.stop, nil) == nil)
end

-- Report -----------------------------------------------------------------------

H.section("Penetration report")
print("damage left after one wall hit square on (estimates, WeaponConfig.Penetration):")
local THICKNESSES = { 0.05, 0.1, 0.2, 0.4, 0.8 }
local header = "  class   material "
for _, t in THICKNESSES do
	header ..= string.format("  %5.2f m", t)
end
print(header)
for _, class in { "low", "medium", "high" } :: { Class } do
	for _, material in { "soft", "medium", "hard" } :: { Material } do
		local row = string.format("  %-7s %-8s ", class, material)
		for _, t in THICKNESSES do
			local trace = single(material, t, class)
			row ..= if trace.stopped then "    stops" else string.format("    x%.2f", Penetration.multiplierAt(trace, RANGE))
		end
		print(row)
	end
end
print()
print("body / head damage through one wall:")
local WALLS: { { material: Material, thickness: number, name: string } } = {
	{ material = "soft", thickness = 0.1, name = "0.10 m wood" },
	{ material = "medium", thickness = 0.2, name = "0.20 m concrete" },
	{ material = "hard", thickness = 0.1, name = "0.10 m metal" },
}
local line = "  weapon     open    "
for _, w in WALLS do
	line ..= string.format("%-18s", w.name)
end
print(line)
for _, id in { "classic", "sheriff", "vandal", "phantom", "operator" } do
	local def = WeaponConfig.get(id)
	local row = string.format("  %-9s %3d/%-3d  ", def.name, WeaponConfig.damageAt(def, "body", 10), WeaponConfig.damageAt(def, "head", 10))
	for _, w in WALLS do
		local trace = single(w.material, w.thickness, def.penetration)
		if trace.stopped then
			row ..= string.format("%-18s", "stops")
		else
			local m = Penetration.multiplierAt(trace, RANGE)
			local body = Penetration.damage(WeaponConfig.damageAt(def, "body", 10), m)
			local head = Penetration.damage(WeaponConfig.damageAt(def, "head", 10), m)
			row ..= string.format("%-18s", string.format("%d/%d", body, head))
		end
	end
	print(row)
end

return nil
