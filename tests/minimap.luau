--!strict
-- The minimap (system 34): who sees whom (Sight: the view's width and
-- height, clouds and walls of fire in the way, the level in the way, any
-- point of a body, each side's sightings and the spike's), each map's plan
-- (every arena and spike map: floors, walls, cover, spawns, sites and the
-- names on them), the views (Rotate and Fixed, Based on Side, Keep Player
-- Centered, the zoom that keeps you centred, the big map) and where points
-- fall in them, the edge allies are held on, what's shown of the spike and
-- when the names are, vision cones (their rays, what stops them and the
-- rectangles they're drawn with), a wall of fire's path as far as it has
-- spread, and the minimap's settings.

local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local BlazeSim = require("../src/shared/Abilities/BlazeSim")
local ArenaLayout = require("../src/shared/Arena/ArenaLayout")
local TeamDeathmatchRules = require("../src/shared/Arena/TeamDeathmatchRules")
local Hitboxes = require("../src/shared/Combat/Hitboxes")
local Sight = require("../src/shared/Combat/Sight")
local Minimap = require("../src/shared/Match/Minimap")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local PlayerSettings = require("../src/shared/Settings/PlayerSettings")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local FakeLevel = require("./FakeLevel")
local H = require("./Harness")

local check, near = H.check, H.near

H.section("Minimap tests")

local BZ = AbilityConfig.Blaze
local EYE = vector.create(0, 1.6, 0)
local AHEAD = vector.create(0, 0, -1) -- yaw 0

local function v(x: number, y: number, z: number): vector
	return vector.create(x, y, z)
end

-- The way a yaw looks, level.
local function looking(yaw: number): vector
	return v(-math.sin(yaw), 0, -math.cos(yaw))
end

local open: Sight.Occluders = {
	clouds = {},
	walls = {},
	time = 0,
	blocked = function()
		return false
	end,
}

-- What's in the way, with `level`'s boxes as the level.
local function through(level: any, clouds: { Sight.Cloud }?, walls: { BlazeSim.Wall }?, t: number?): Sight.Occluders
	return {
		clouds = clouds or {},
		walls = walls or {},
		time = t or 0,
		blocked = function(a: vector, b: vector): boolean
			local d = b - a
			local length = vector.magnitude(d)
			return length > 1e-9 and level:cast(a, d / length, length, {}) ~= nil
		end,
	}
end

-- Sight: the view -------------------------------------------------------------------

do
	local SP = Sight.Params
	check(
		"the view is 103 degrees across (the reference's, community), judged on 16:9 (ours)",
		SP.fov.value == 103 and SP.fov.status == "community" and near(SP.aspect.value, 16 / 9, 1e-12) and SP.aspect.status == "estimate"
	)
	local half = math.rad(103 / 2)
	local high = math.atan(math.tan(half) * 9 / 16)
	local function at(yaw: number, pitch: number): vector
		return EYE + Accuracy.aim(yaw, pitch) * 10
	end
	check(
		"straight ahead is in view, behind isn't",
		Sight.inView(EYE, AHEAD, EYE + AHEAD * 10) and not Sight.inView(EYE, AHEAD, EYE - AHEAD * 10)
	)
	check(
		"a point just inside the view's side is in it, just outside isn't",
		Sight.inView(EYE, AHEAD, at(half - 0.01, 0))
			and not Sight.inView(EYE, AHEAD, at(half + 0.01, 0))
			and Sight.inView(EYE, AHEAD, at(-half + 0.01, 0))
	)
	check(
		string.format("the view's height is %.1f degrees above and below at 16:9", math.deg(high)),
		Sight.inView(EYE, AHEAD, at(0, high - 0.01))
			and not Sight.inView(EYE, AHEAD, at(0, high + 0.01))
			and not Sight.inView(EYE, AHEAD, at(0, -high - 0.01))
	)
	local up = v(0, 1, 0)
	check(
		"looking straight up sees what's above, and not what's level",
		Sight.inView(EYE, up, EYE + v(0.5, 10, 0)) and not Sight.inView(EYE, up, EYE + v(10, 0, 0))
	)
	check(
		"a turned view: what's ahead of it",
		Sight.inView(EYE, looking(math.rad(90)), EYE + v(-10, 0, 0)) and not Sight.inView(EYE, looking(math.rad(90)), EYE + v(0, 0, -10))
	)
end

-- Sight: clouds and walls of fire -------------------------------------------------

do
	local cloud: Sight.Cloud = { centre = v(0, 1.6, -10), radius = 3 }
	check("a line through a cloud is hidden", Sight.cloudHides(cloud, EYE, v(0, 1.6, -20)))
	check("one past its side isn't", not Sight.cloudHides(cloud, EYE, v(8, 1.6, -20)))
	check(
		"one ending in it is hidden, one stopping short isn't",
		Sight.cloudHides(cloud, EYE, v(0, 1.6, -9)) and not Sight.cloudHides(cloud, EYE, v(0, 1.6, -6))
	)
	check("from inside it, everything is", Sight.cloudHides(cloud, v(0, 1.6, -10), v(30, 1.6, 30)))
	check("a cloud with no radius (gone) hides nothing", not Sight.cloudHides({ centre = cloud.centre, radius = 0 }, EYE, v(0, 1.6, -20)))

	-- A wall across the way ahead, 10 m off, from x = -10 to x = 10.
	local wall = BlazeSim.wall(1, 1, { v(-10, 0, -10), v(0, 0, -10), v(10, 0, -10) }, 5) :: BlazeSim.Wall
	local across = BlazeSim.length(wall) / BZ.spreadSpeed.value
	local up = 5 + across + 0.1
	check("a wall standing hides what's behind it", Sight.wallHides(wall, up, EYE, v(5, 1.6, -20)))
	check(
		"not before it rises, nor once it's fallen",
		not Sight.wallHides(wall, 4.9, EYE, v(5, 1.6, -20)) and not Sight.wallHides(wall, BlazeSim.ends(wall) + 0.01, EYE, v(5, 1.6, -20))
	)
	check("not over it", not Sight.wallHides(wall, up, v(0, BZ.height.value + 1, 0), v(5, BZ.height.value + 1, -20)))
	-- 0.1 s after it rises it has spread 4.2 m, from x = -10 to -5.8.
	check(
		"not where the fire hasn't spread to yet",
		Sight.wallHides(wall, 5.1, EYE, v(-15, 1.6, -20)) and not Sight.wallHides(wall, 5.1, EYE, v(9, 1.6, -20))
	)
	check("not past its end", not Sight.wallHides(wall, up, EYE, v(30, 1.6, -12)))
	check("from in it, everything is", Sight.wallHides(wall, up, v(2, 1.6, -10), v(2, 1.6, 20)))
end

-- Sight: the level, and who's seen ----------------------------------------------

do
	local level = FakeLevel.new()
	level:add("concrete", v(-1, 0, -12), v(1, 4, -11)) -- a pillar ahead
	local o = through(level)
	check("the level in the way hides", Sight.hidden(EYE, v(0, 1.6, -20), o) and not Sight.hidden(EYE, v(5, 1.6, -20), o))
	local calls = 0
	local counting: Sight.Occluders = {
		clouds = { { centre = v(0, 1.6, -5), radius = 2 } },
		walls = {},
		time = 0,
		blocked = function()
			calls += 1
			return false
		end,
	}
	check("a cloud hides before the level's asked", Sight.hidden(EYE, v(0, 1.6, -20), counting) and calls == 0)

	local standing = Sight.points({ position = v(0, 0, -20), yaw = 0, crouchAlpha = 0 })
	local crouched = Sight.points({ position = v(0, 0, -20), yaw = 0, crouchAlpha = 1 })
	local boxes = Hitboxes.build({ position = v(0, 0, -20), yaw = 0, crouchAlpha = 0 })
	check(
		"a body's points: the middles of its head, body and legs",
		#standing == 3 and standing[1] == boxes[1].center and standing[3] == boxes[3].center
	)
	check("crouched, lower", crouched[1].y < standing[1].y)

	-- Its head shows over a low wall that hides the rest of it.
	local low = FakeLevel.new()
	low:add("concrete", v(-3, 0, -11), v(3, 1.45, -10))
	local headOnly = through(low)
	check("one point in view is enough", Sight.sees({ side = 1, eye = EYE, look = AHEAD }, standing, headOnly))
	check("and none, nothing", not Sight.sees({ side = 1, eye = EYE, look = AHEAD }, { standing[3] }, headOnly))

	local viewers: { Sight.Viewer } = {
		{ side = 1, eye = EYE, look = AHEAD },
		{ side = 1, eye = v(12, 1.6, 0), look = v(1, 0, 0) }, -- looking away
		{ side = 2, eye = v(0, 1.6, -20), look = v(0, 0, 1) },
	}
	local targets: { Sight.Target } = {
		{ id = 7, side = 2, points = Sight.points({ position = v(0, 0, -20), yaw = 0, crouchAlpha = 0 }) },
		{ id = 8, side = 2, points = Sight.points({ position = v(0, 0, 30), yaw = 0, crouchAlpha = 0 }) }, -- behind side 1
		{ id = 3, side = 1, points = Sight.points({ position = v(0, 0, 0), yaw = 0, crouchAlpha = 0 }) },
		{ id = 4, side = 1, points = Sight.points({ position = v(12, 0, 0), yaw = 0, crouchAlpha = 0 }) },
	}
	local spotted = Sight.spotted(viewers, targets, open)
	check("side 1 sees the enemy ahead and not the one behind", spotted[1] ~= nil and spotted[1][7] == true and spotted[1][8] == nil)
	check("nobody spots their own side", spotted[1][3] == nil and (spotted[2] == nil or (spotted[2][7] == nil and spotted[2][8] == nil)))
	check("side 2 sees both of side 1 ahead of it", spotted[2] ~= nil and spotted[2][3] == true and spotted[2][4] == true)
	local blocked = Sight.spotted(viewers, targets, o)
	check(
		"with the pillar between, side 1 doesn't see them, and they don't see side 1's first",
		(blocked[1] == nil or blocked[1][7] == nil) and blocked[2] ~= nil and blocked[2][3] == nil and blocked[2][4] == true
	)
	check(
		"a side sees the spike on the floor ahead",
		Sight.sideSees(viewers, 1, v(3, 0.15, -15), open) and not Sight.sideSees(viewers, 1, v(0, 0.15, 25), open)
	)
	check("and only that side's eyes count", not Sight.sideSees(viewers, 2, v(0, 0.15, -30), open))
end

-- Plans ----------------------------------------------------------------------------

do
	check(
		"modes and their maps: the arena's for Skirmish and gun game, the spike maps' for the rest",
		Minimap.familyOf("skirmish") == "arena"
			and Minimap.familyOf("gungame") == "arena"
			and Minimap.familyOf("spike") == "spike"
			and Minimap.familyOf("deathmatch") == "spike"
			and Minimap.familyOf("teamdeathmatch") == "spike"
			and Minimap.familyOf(nil) == nil
	)
	check(
		"names as the big map writes them",
		Minimap.regionName("ALobby") == "A Lobby"
			and Minimap.regionName("BMainUpper") == "B Main Upper"
			and Minimap.regionName("Mid") == "Mid"
			and Minimap.regionName("DefenderSpawn") == "Defender Spawn"
	)
	check(
		"no plan off the arena, or for a map that isn't",
		Minimap.planFor(nil, "A") == nil and Minimap.planFor("skirmish", "Z") == nil and Minimap.planFor("spike", nil) == nil
	)

	local function count(plan: Minimap.Plan, kind: string): number
		local n = 0
		for _, s in plan.shapes do
			if s.kind == kind then
				n += 1
			end
		end
		return n
	end
	local function inside(plan: Minimap.Plan, x: number, z: number): boolean
		for _, s in plan.shapes do
			if
				s.kind == "floor"
				and math.abs(x - s.center.x) <= s.size.x / 2 + 1e-6
				and math.abs(z - s.center.z) <= s.size.z / 2 + 1e-6
			then
				return true
			end
		end
		return false
	end

	for _, key in ArenaLayout.MAPS do
		local plan = Minimap.planFor("skirmish", key) :: Minimap.Plan
		local sides = {}
		for _, s in plan.shapes do
			if s.kind == "spawn" and s.side then
				sides[s.side] = true
			end
		end
		local onFloor = true
		for _, part in ArenaLayout.coverParts(key) do
			local c = part.center + ArenaLayout.origin
			onFloor = onFloor and inside(plan, c.x, c.z)
		end
		check(
			string.format(
				"arena %s: three floors, %d walls, %d cover, both sides' spawns, all its cover on the floor",
				key,
				count(plan, "wall"),
				count(plan, "cover")
			),
			plan.family == "arena"
				and count(plan, "floor") == 3
				and count(plan, "wall") > 0
				and count(plan, "cover") == #ArenaLayout.coverParts(key)
				and sides[1]
				and sides[2]
				and onFloor
				and #plan.labels == 0
		)
	end
	check("a plan is made once", Minimap.planFor("skirmish", "A") == Minimap.planFor("gungame", "A"))

	for _, key in SpikeMaps.MAPS do
		local map = SpikeMaps.Maps[key]
		local plan = Minimap.planFor("spike", key) :: Minimap.Plan
		local roles, letters, regions = {}, {}, 0
		local doorNamed = false
		for _, s in plan.shapes do
			if s.kind == "spawn" and s.role then
				roles[s.role] = true
			end
		end
		for _, label in plan.labels do
			if label.kind == "site" then
				letters[label.text] = true
			else
				regions += 1
				doorNamed = doorNamed or string.find(label.text, "Door", 1, true) ~= nil
			end
		end
		local sitesOk = count(plan, "site") == #map.Sites
		for _, site in map.Sites do
			sitesOk = sitesOk and letters[site.site] == true and inside(plan, site.x + map.origin.x, site.z + map.origin.z)
		end
		check(
			string.format(
				"%s: %d rooms, %d cover, both spawns, %d sites with their letters on the floor, %d named places, no doors named",
				key,
				count(plan, "floor"),
				count(plan, "cover"),
				#map.Sites,
				regions
			),
			plan.family == "spike"
				and count(plan, "floor") == #map.rooms()
				and count(plan, "cover") == #map.cover()
				and roles.attack
				and roles.defend
				and sitesOk
				and regions > 0
				and not doorNamed
		)
		local across = Minimap.across(plan)
		check(
			string.format("%s: %.0f m across with its margins", key, across),
			plan.x1 > plan.x0 and plan.z1 > plan.z0 and near(across, math.max(plan.x1 - plan.x0, plan.z1 - plan.z0) + 4, 1e-9)
		)
	end
end

-- Views ----------------------------------------------------------------------------

do
	local plan = Minimap.planFor("spike", "quarry") :: Minimap.Plan
	local mid = Minimap.middle(plan)
	local function settings(over: { [string]: any }): PlayerSettings.Settings
		local s = PlayerSettings.copy(PlayerSettings.DEFAULTS)
		for k, value in over do
			(s :: any)[k] = value
		end
		return s
	end

	local attack = Minimap.homeOf(plan, "spike", 1, 1)
	local defend = Minimap.homeOf(plan, "spike", 2, 1)
	check(
		"in the spike rounds, the attacking side's home is the attackers' spawn",
		attack ~= nil and attack.role == "attack" and defend ~= nil and defend.role == "defend"
	)
	check("switched sides switch homes", Minimap.homeOf(plan, "spike", 1, 2) == defend)
	local tdm = Minimap.homeOf(plan, "teamdeathmatch", 1, nil)
	check("in Team Deathmatch by TeamDeathmatchRules' roles", tdm ~= nil and tdm.role == TeamDeathmatchRules.roleOf(1))
	check(
		"none in deathmatch, or for nobody",
		Minimap.homeOf(plan, "deathmatch", 3, nil) == nil and Minimap.homeOf(plan, "spike", nil, 1) == nil
	)
	local arena = Minimap.planFor("skirmish", "A") :: Minimap.Plan
	local one = Minimap.homeOf(arena, "skirmish", 1, nil)
	check(
		"in the arena, your side's own spawn",
		one ~= nil and one.side == 1 and (Minimap.homeOf(arena, "skirmish", 2, nil) :: Minimap.Shape).side == 2
	)

	local function turnFor(home: Minimap.Shape): number
		return Minimap.homeTurn(plan, home)
	end
	local up = (attack :: Minimap.Shape).center.z < mid.z
	check(
		"a fixed map's turned half round when your spawn's at the top, so it's at the bottom",
		(if up then near(turnFor(attack :: Minimap.Shape), math.pi, 1e-12) else turnFor(attack :: Minimap.Shape) == 0)
			and (if up then turnFor(defend :: Minimap.Shape) == 0 else near(turnFor(defend :: Minimap.Shape), math.pi, 1e-12))
			and Minimap.homeTurn(plan, nil) == 0
	)

	local me: Minimap.Me = { position = mid + v(10, 1.6, 5), yaw = 0.7 }
	local box = 270
	local rotate = Minimap.miniView(plan, settings({}), me, box, math.pi)
	check(
		"by default it rotates as you look, the whole map in view",
		rotate.turn == 0.7
			and rotate.centre == mid
			and near(rotate.scale, box * 0.9 / Minimap.across(plan), 1e-12)
			and rotate.half == box / 2
	)
	check(
		"Fixed, Based on Side: your spawn at the bottom",
		Minimap.miniView(plan, settings({ mapRotate = false }), me, box, math.pi).turn == math.pi
	)
	check(
		"Fixed, Always the Same: never turned",
		Minimap.miniView(plan, settings({ mapRotate = false, mapBySide = false }), me, box, math.pi).turn == 0
	)
	check("Rotate with nobody to follow is fixed", Minimap.miniView(plan, settings({}), nil, box, math.pi).turn == math.pi)
	check(
		"Keep Player Centered: you in the middle",
		Minimap.miniView(plan, settings({ mapCentred = true }), me, box, 0).centre == me.position
	)
	check(
		"a zoom past 1 keeps you in the middle anyway (setup.gg)",
		Minimap.miniView(plan, settings({ mapZoom = 1.2 }), me, box, 0).centre == me.position
	)
	local big = Minimap.bigView(plan, settings({ mapCentred = true }), 800, math.pi)
	check(
		"the big map: the whole map, its middle in the middle, turned as a fixed one",
		big.centre == mid and near(big.scale, 800 / Minimap.across(plan), 1e-12) and big.turn == math.pi
	)
	check("Always the Same turns the big map nowhere", Minimap.bigView(plan, settings({ mapBySide = false }), 800, math.pi).turn == 0)

	local flat: Minimap.View = { centre = v(0, 0, 0), turn = 0, scale = 2, half = 100 }
	local ex, ey = Minimap.toView(flat, v(10, 0, 0))
	local nx, ny = Minimap.toView(flat, v(0, 0, -10))
	check(
		"unturned, east is right and north (-z) is up",
		near(ex, 20, 1e-12) and near(ey, 0, 1e-12) and near(nx, 0, 1e-12) and near(ny, -20, 1e-12)
	)
	local east = Minimap.yawOf(v(1, 0, 0))
	local turned: Minimap.View = { centre = v(0, 0, 0), turn = east, scale = 2, half = 100 }
	local ax, ay = Minimap.toView(turned, v(10, 0, 0))
	check("turned to someone looking east, east is up", near(ax, 0, 1e-9) and near(ay, -20, 1e-9))
	check(
		"their arrow points up on it, and right on an unturned map",
		near(Minimap.facing(turned, east), 0, 1e-12) and near(Minimap.facing(flat, east), math.pi / 2, 1e-12)
	)
	check(
		"yawOf is the yaw Accuracy.aim looks along",
		near(Minimap.yawOf(Accuracy.aim(0.9, 0)), 0.9, 1e-6) and near(Minimap.yawOf(Accuracy.aim(-2.5, 0.3)), -2.5, 1e-6)
	)
	local x, y, held = Minimap.toEdge(flat, 300, 150, 10)
	local ix, iy, kept = Minimap.toEdge(flat, 50, -20, 10)
	check("an ally off the minimap is held on its edge, the way to them", held and near(x, 90, 1e-9) and near(y, 45, 1e-9))
	check("and one on it stays where they are", not kept and ix == 50 and iy == -20)
end

-- What's shown ----------------------------------------------------------------------

do
	check("the spike planted shows to everyone", Minimap.spikeShown("planted", true, false) and Minimap.spikeShown("planted", false, false))
	check(
		"dropped, to the attackers always and the defenders while they see it",
		Minimap.spikeShown("dropped", true, false)
			and not Minimap.spikeShown("dropped", false, false)
			and Minimap.spikeShown("dropped", false, true)
	)
	check(
		"carried, to the carrier's side only (Patch 0.50)",
		Minimap.spikeShown("carried", true, false) and not Minimap.spikeShown("carried", false, true)
	)
	check("otherwise, nowhere", not Minimap.spikeShown("none", true, true) and not Minimap.spikeShown("defused", true, true))
	check(
		"region names: Always, Only in Buy Phase, Never",
		Minimap.namesShown("always", "live")
			and Minimap.namesShown("buy", "buy")
			and Minimap.namesShown("buy", "pregame")
			and not Minimap.namesShown("buy", "live")
			and not Minimap.namesShown("never", "buy")
	)
end

-- Vision cones ----------------------------------------------------------------------

do
	local fov = math.rad(103)
	local yaws = Minimap.coneYaws(0.4, fov, 20)
	check(
		"20 rays across the view, a wedge apart, either side of the look",
		#yaws == 20
			and near(yaws[1], 0.4 + fov / 2 - fov / 40, 1e-12)
			and near(yaws[1] - yaws[2], fov / 20, 1e-12)
			and near(yaws[1] + yaws[20], 0.8, 1e-12)
	)

	local o = v(0, 1.6, 0)
	check("a ray at a cloud stops at its edge", near(Minimap.rayCircle(o, AHEAD, v(0, 0, -10), 3) :: number, 7, 1e-9))
	check("from inside one, at once", Minimap.rayCircle(o, AHEAD, v(0, 0, -1), 3) == 0)
	check(
		"one going away or passing by misses",
		Minimap.rayCircle(o, AHEAD, v(0, 0, 10), 3) == nil and Minimap.rayCircle(o, AHEAD, v(5, 0, -10), 3) == nil
	)
	check("a ray crosses a stretch where it meets it", near(Minimap.raySegment(o, AHEAD, v(-5, 0, -8), v(5, 0, -8)) :: number, 8, 1e-9))
	check(
		"and misses one beside it, behind it or along it",
		Minimap.raySegment(o, AHEAD, v(1, 0, -8), v(5, 0, -8)) == nil
			and Minimap.raySegment(o, AHEAD, v(-5, 0, 8), v(5, 0, 8)) == nil
			and Minimap.raySegment(o, AHEAD, v(0, 0, -2), v(0, 0, -9)) == nil
	)
	local wall = BlazeSim.wall(1, 1, { v(-5, 0, -12), v(5, 0, -12) }, 0) :: BlazeSim.Wall
	local paths = { BlazeSim.spreadPath(wall, 10) }
	check(
		"a cone's ray: the nearest of a cloud and a wall, or as far as it goes",
		near(Minimap.reach(o, AHEAD, 40, { { centre = v(0, 0, -20), radius = 2 } }, paths), 12, 1e-9)
			and near(Minimap.reach(o, AHEAD, 40, { { centre = v(0, 0, -8), radius = 2 } }, paths), 6, 1e-9)
			and Minimap.reach(o, looking(math.pi / 2), 40, {}, paths) == 40
	)
	check("and never past where the level stopped it", Minimap.reach(o, AHEAD, 5, {}, paths) == 5)

	local wedge = fov / 20
	local rects = Minimap.coneRects(10, 20, { 0, 0.5 }, { 40, 0 }, wedge)
	local far = rects[2]
	check("two rectangles a ray, none for a ray that goes nowhere", #rects == 2)
	check(
		"the far half's middle three quarters out, as wide as the wedge at its end, turned the way the ray looks",
		near(far.x, 10, 1e-9)
			and near(far.y, 20 - 30, 1e-9)
			and near(far.w, 2 * math.tan(wedge / 2) * 40, 1e-9)
			and near(far.h, 20, 1e-9)
			and far.rotation == 0
	)
	local side = Minimap.coneRects(0, 0, { math.pi / 2 }, { 8 }, wedge)
	check(
		"a ray looking west (+90 degrees yaw) goes left, turned a quarter back",
		near(side[1].x, -2, 1e-9) and near(side[1].y, 0, 1e-9) and near(side[1].rotation, -90, 1e-9)
	)
end

-- A wall of fire's path, as far as it has spread -------------------------------------

do
	local wall = BlazeSim.wall(1, 1, { v(0, 0, 0), v(0, 0, -10), v(10, 0, -10) }, 2) :: BlazeSim.Wall
	local speed = BZ.spreadSpeed.value
	check("nothing before it rises, its start as it does", #BlazeSim.spreadPath(wall, 1.9) == 0 and #BlazeSim.spreadPath(wall, 2) == 1)
	local partWay = BlazeSim.spreadPath(wall, 2 + 5 / speed)
	check("part of the way along its first stretch", #partWay == 2 and near(partWay[2].z, -5, 1e-9))
	local round = BlazeSim.spreadPath(wall, 2 + 15 / speed)
	check("round its bend", #round == 3 and round[2] == v(0, 0, -10) and near(round[3].x, 5, 1e-9))
	check(
		"all of it once it's spread",
		#BlazeSim.spreadPath(wall, 2 + 30 / speed) == 3 and BlazeSim.spreadPath(wall, 9)[3] == v(10, 0, -10)
	)
end

-- Settings --------------------------------------------------------------------------

do
	local d = PlayerSettings.DEFAULTS
	check(
		"the map by default: rotating, by side, not centred, size 1, zoom 0.9, cones, names always",
		d.mapRotate and d.mapBySide and not d.mapCentred and d.mapSize == 1 and d.mapZoom == 0.9 and d.mapCones and d.mapNames == "always"
	)
	local s = PlayerSettings.sanitize({
		mapRotate = "0",
		mapBySide = "off",
		mapCentred = true,
		mapSize = 5,
		mapZoom = "0.1",
		mapCones = "false",
		mapNames = "buy",
	})
	check(
		"switches from text, sizes held to their limits",
		not s.mapRotate
			and not s.mapBySide
			and s.mapCentred
			and s.mapSize == 1.2
			and s.mapZoom == 0.6
			and not s.mapCones
			and s.mapNames == "buy"
	)
	local text = PlayerSettings.toText(s)
	check(
		"kept as text and read back",
		string.find(text, "mapRotate=0\nmapBySide=0\nmapCentred=1\nmapSize=1.2\nmapZoom=0.6\nmapCones=0\nmapNames=buy", 1, true) ~= nil
			and PlayerSettings.equal(PlayerSettings.fromText(text), s)
	)
	local junk = PlayerSettings.sanitize({ mapRotate = "maybe", mapNames = "sometimes", mapZoom = 0 / 0 })
	check("what isn't a choice takes the default", junk.mapRotate == true and junk.mapNames == "always" and junk.mapZoom == 0.9)
	check("settings kept before the map's take its defaults", PlayerSettings.fromText("sensitivity=0.5").mapZoom == 0.9)
	check(
		"switchOf: on and off, nothing for junk",
		PlayerSettings.switchOf("on") == true
			and PlayerSettings.switchOf("1") == true
			and PlayerSettings.switchOf(false) == false
			and PlayerSettings.switchOf("off") == false
			and PlayerSettings.switchOf("yes") == nil
	)
end

-- Numbers ---------------------------------------------------------------------------

do
	local P = Minimap.Params
	local shares = 0
	for _, param in P do
		if param.status == "estimate" and param.source ~= "" then
			shares += 1
		end
	end
	check("the minimap's numbers are ours, each with its reason", shares == 13)
	check(
		"the server looks 20 times a second; cones are cast 15",
		near(1 / P.sightEvery.value, 20, 1e-9) and near(1 / P.coneEvery.value, 15, 1e-9)
	)
	check("a sound's circle is drawn out to 60 m (the spike's plant and defuse, heard at 60 m)", P.ringMost.value == 60)
end

return nil
