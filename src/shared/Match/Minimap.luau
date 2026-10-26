--!strict
-- The minimap (system 34) as plain data and maths: each map drawn from its
-- own plan, where a point falls on a view of it, and the reference's rules
-- for what shows. Same status convention as MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be tuned (docs/research/34-minimap.md)
--
-- A plan is the floor seen from above: every room you can stand in, the
-- walls over it, the cover on it, each spawn's floor and each site's plant
-- area, all in metres in the place, and the words written on it: each
-- site's letter, and the names of the places, for the big map (Riot: Show
-- Map Region Names "only affects the megamap", the UI Settings FAQ). The
-- arena's maps (ArenaLayout) and the spike maps (SpikeMaps) are both drawn
-- from their plans, so a map's minimap is always the map.
--
-- A view is how a box on the screen shows the plan: the point at its
-- centre, how far the map is turned (clockwise, radians) and how many
-- pixels a metre is. Rotate turns it as you turn, so you always look up
-- it; Fixed keeps it still, the same way round always or with your own
-- spawn at the bottom (Based on Side); Keep Player Centered keeps you in
-- the middle, and otherwise the map's middle is (the settings, thespike.gg
-- and setup.gg; community). A zoom of 1 fits the whole map across the box,
-- so past 1 you're kept in the middle, as the reference's console version
-- does (setup.gg).
--
-- No Roblox APIs here, so the offline tests check every map's plan and the
-- maths.

local ArenaLayout = require("../Arena/ArenaLayout")
local PlayerSettings = require("../Settings/PlayerSettings")
local SpikeMaps = require("./SpikeMaps")
local TeamDeathmatchRules = require("../Arena/TeamDeathmatchRules")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

export type Kind = "floor" | "wall" | "cover" | "spawn" | "site"

-- Something drawn: its middle and size across the floor (x along its own
-- x, z along its own z; y unused), and how far it's turned about the
-- vertical, as ArenaLayout's parts are.
export type Shape = {
	kind: Kind,
	center: vector,
	size: vector,
	yaw: number,
	high: boolean?, -- cover: tall enough to hide someone standing
	role: string?, -- a spike map's spawn: "attack" or "defend"
	side: number?, -- an arena spawn: its side
	site: string?, -- a plant area: its letter
}

export type Label = { text: string, at: vector, kind: "site" | "region" }

export type Plan = {
	key: string, -- "arena:A", "spike:quarry"
	family: "arena" | "spike",
	shapes: { Shape },
	labels: { Label },
	-- The floor's extent in the place, metres.
	x0: number,
	z0: number,
	x1: number,
	z1: number,
}

-- How a box shows a plan: the point at its middle, how far the map's
-- turned (clockwise on the screen, radians), pixels a metre, and half the
-- box's side in pixels.
export type View = { centre: vector, turn: number, scale: number, half: number }

-- Where someone the minimap is for stands and which way they look.
export type Me = { position: vector, yaw: number }

-- A rectangle on an unturned map, in pixels: its middle, its width and
-- length, and how far it's turned (the GUI's Rotation, degrees clockwise).
export type Rect = { x: number, y: number, w: number, h: number, rotation: number }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local Minimap = {}

-- The name of the spawns' barriers' parts (ArenaLayout, MapPlan): sight
-- goes through them, as they're see-through.
Minimap.BARRIER = "Barrier"

local EPS = 1e-9
local PATCH_508 = "Patch 5.08"

Minimap.Params = {
	-- The server's look at who sees whom, for each side.
	sightEvery = p(0.05, "estimate", "Seconds between the server's looks at who each side sees: 20 a second"),
	blindSees = p(
		0.5,
		"estimate",
		"A blind (Curveball, system 30) whiter than this sees nobody: a screen 'replaced with an opaque, colored screen' (the VALORANT Wiki, Status Effect)"
	),
	lastSeen = p(
		3,
		"estimate",
		"Seconds an enemy's 'Recently Seen Enemy' icon stays where they were last seen (" .. PATCH_508 .. " names it; how long is ours)"
	),
	pulse = p(
		3,
		"estimate",
		"Seconds Deathmatch's pulse on respawning shows 'the location of all enemy players' (the VALORANT Wiki, Deathmatch; how long is ours)"
	),
	ring = p(0.6, "estimate", "Seconds the white circle of a sound you make takes to fade"),
	ringMost = p(
		60,
		"estimate",
		"Metres: a sound heard further than this draws no circle. Footsteps, reloads, abilities and the spike's plant and defuse do (Patch 1.0); gunfire, heard across the map, doesn't"
	),
	coneLength = p(40, "estimate", "Metres a vision cone reaches where nothing stops it"),
	coneRays = p(20, "estimate", "Rays a vision cone is drawn with, across the view"),
	coneEvery = p(1 / 15, "estimate", "Seconds between the cones' casts"),
	size = p(0.25, "estimate", "The minimap's side, as a share of the screen's height, at Minimap Size 1"),
	bigSize = p(0.82, "estimate", "The big map's side, as a share of the screen's height"),
	margin = p(2, "estimate", "Metres round the floor that a whole map's view leaves"),
	smallRoom = p(30, "estimate", "Square metres: a room smaller than this has no name on the big map"),
}

-- Which family of maps a mode is played on (Workspace's ArenaConfig.MODE):
-- the arena's (Skirmish and gun game) or the spike maps (the spike rounds
-- and both deathmatches). Nil for none.
function Minimap.familyOf(mode: any): ("arena" | "spike")?
	if mode == "skirmish" or mode == "gungame" then
		return "arena"
	elseif mode == "spike" or mode == "deathmatch" or mode == "teamdeathmatch" then
		return "spike"
	end
	return nil
end

-- A room's name as the big map writes it: "ALobby" is "A Lobby",
-- "BMainUpper" is "B Main Upper".
function Minimap.regionName(name: string): string
	local spaced = string.gsub(name, "(%l)(%u)", "%1 %2")
	spaced = string.gsub(spaced, "(%u)(%u%l)", "%1 %2")
	return spaced
end

local function rect(kind: Kind, x0: number, z0: number, x1: number, z1: number): Shape
	return { kind = kind, center = vector.create((x0 + x1) / 2, 0, (z0 + z1) / 2), size = vector.create(x1 - x0, 0, z1 - z0), yaw = 0 }
end

-- The extent of a list of rectangles' floors.
local function extent(floors: { Shape }): (number, number, number, number)
	local x0, z0, x1, z1 = math.huge, math.huge, -math.huge, -math.huge
	for _, s in floors do
		x0 = math.min(x0, s.center.x - s.size.x / 2)
		x1 = math.max(x1, s.center.x + s.size.x / 2)
		z0 = math.min(z0, s.center.z - s.size.z / 2)
		z1 = math.max(z1, s.center.z + s.size.z / 2)
	end
	return x0, z0, x1, z1
end

local function moved(s: Shape, by: vector): Shape
	local out = table.clone(s)
	out.center = s.center + vector.create(by.x, 0, by.z)
	return out
end

-- An arena map's plan: the hall and the two spawn rooms, the walls (the
-- hall's cut corners show over its floor), the map's cover and each side's
-- spawn floor. No sites, and no names.
local function arenaPlan(key: string): Plan?
	if not ArenaLayout.Maps[key] then
		return nil
	end
	local origin = ArenaLayout.origin
	local floors: { Shape } = {}
	for _, r in { ArenaLayout.hall(), ArenaLayout.room(1), ArenaLayout.room(2) } do
		table.insert(floors, rect("floor", r.min.x, r.min.z, r.max.x, r.max.z))
	end
	local shapes: { Shape } = {}
	for _, f in floors do
		table.insert(shapes, moved(f, origin))
	end
	local walls: { Shape }, spawns: { Shape } = {}, {}
	for _, part in ArenaLayout.hallParts() do
		if part.kind == "wall" then
			table.insert(walls, { kind = "wall", center = part.center + origin, size = part.size, yaw = part.yaw })
		elseif part.kind == "marking" and part.name == "SpawnFloor" then
			table.insert(spawns, { kind = "spawn", center = part.center + origin, size = part.size, yaw = part.yaw, side = part.side })
		end
	end
	table.move(walls, 1, #walls, #shapes + 1, shapes)
	table.move(spawns, 1, #spawns, #shapes + 1, shapes)
	local high = ArenaLayout.Heights.high.value
	for _, part in ArenaLayout.coverParts(key) do
		table.insert(
			shapes,
			{ kind = "cover", center = part.center + origin, size = part.size, yaw = part.yaw, high = part.size.y >= high - EPS }
		)
	end
	local x0, z0, x1, z1 = extent(floors)
	return {
		key = "arena:" .. key,
		family = "arena",
		shapes = shapes,
		labels = {},
		x0 = x0 + origin.x,
		z0 = z0 + origin.z,
		x1 = x1 + origin.x,
		z1 = z1 + origin.z,
	}
end

-- A spike map's plan: its rooms, which are its floor, each spawn's floor,
-- each site's plant area and letter, its cover, and the names of its rooms
-- that aren't doors and aren't small.
local function spikePlan(key: string): Plan?
	local map = SpikeMaps.Maps[key]
	if not map then
		return nil
	end
	local origin = map.origin
	local floors: { Shape } = {}
	local shapes: { Shape } = {}
	local labels: { Label } = {}
	local small = Minimap.Params.smallRoom.value
	for _, r in map.rooms() do
		local f = rect("floor", r.x0, r.z0, r.x1, r.z1)
		table.insert(floors, f)
		table.insert(shapes, moved(f, origin))
		local area = (r.x1 - r.x0) * (r.z1 - r.z0)
		if not string.find(r.name, "Door", 1, true) and area >= small - EPS then
			table.insert(labels, { text = Minimap.regionName(r.name), at = f.center + origin, kind = "region" })
		end
	end
	for _, spawn in { { role = "attack", room = "AttackerSpawn" }, { role = "defend", room = "DefenderSpawn" } } do
		local r = map.room(spawn.room)
		if r then
			local s = rect("spawn", r.x0, r.z0, r.x1, r.z1)
			s.role = spawn.role
			table.insert(shapes, moved(s, origin))
		end
	end
	for _, site in map.Sites do
		local s = rect("site", site.x - site.sx / 2, site.z - site.sz / 2, site.x + site.sx / 2, site.z + site.sz / 2)
		s.site = site.site
		table.insert(shapes, moved(s, origin))
		table.insert(labels, { text = site.site, at = vector.create(site.x, 0, site.z) + origin, kind = "site" })
	end
	for _, c in map.cover() do
		table.insert(shapes, {
			kind = "cover",
			center = vector.create(c.x, 0, c.z) + origin,
			size = vector.create(c.sx, 0, c.sz),
			yaw = 0,
			high = c.height == "high",
		})
	end
	local x0, z0, x1, z1 = extent(floors)
	return {
		key = "spike:" .. key,
		family = "spike",
		shapes = shapes,
		labels = labels,
		x0 = x0 + origin.x,
		z0 = z0 + origin.z,
		x1 = x1 + origin.x,
		z1 = z1 + origin.z,
	}
end

local plans: { [string]: Plan } = {}

-- The plan of the map a mode is played on (Workspace's ArenaConfig.MODE
-- and the arena's Map attribute), or nil for none, as on the course.
function Minimap.planFor(mode: any, map: any): Plan?
	local family = Minimap.familyOf(mode)
	if not family or typeof(map) ~= "string" then
		return nil
	end
	local key = family .. ":" .. map
	local plan = plans[key]
	if not plan then
		local made = if family == "arena" then arenaPlan(map) else spikePlan(map)
		if not made then
			return nil
		end
		plans[key] = made
		plan = made
	end
	return plan
end

-- The middle of a plan's floor, and the longer side of it with the margin
-- round it, in metres.
function Minimap.middle(plan: Plan): vector
	return vector.create((plan.x0 + plan.x1) / 2, 0, (plan.z0 + plan.z1) / 2)
end

function Minimap.across(plan: Plan): number
	return math.max(plan.x1 - plan.x0, plan.z1 - plan.z0) + 2 * Minimap.Params.margin.value
end

-- The spawn floor of the side someone's on, in a mode: in the arena, their
-- side's; in the spike rounds, the attackers' for the side that attacks
-- (`attackers`) and the defenders' for the other; in Team Deathmatch, the
-- attackers' for side 1 (TeamDeathmatchRules.roleOf). Nil in deathmatch,
-- where nobody's spawn is their own, and for nobody.
function Minimap.homeOf(plan: Plan, mode: any, side: any, attackers: any): Shape?
	if typeof(side) ~= "number" then
		return nil
	end
	local role: string? = nil
	if mode == "spike" then
		role = if typeof(attackers) ~= "number" then nil elseif side == attackers then "attack" else "defend"
	elseif mode == "teamdeathmatch" then
		role = TeamDeathmatchRules.roleOf(side)
	end
	for _, s in plan.shapes do
		if s.kind == "spawn" and ((plan.family == "arena" and s.side == side) or (role ~= nil and s.role == role)) then
			return s
		end
	end
	return nil
end

-- How far a fixed map's turned to put a spawn at the bottom of the box: not
-- at all if it's already in the half nearer the bottom (+z on the screen),
-- or half way round. Not at all without one.
function Minimap.homeTurn(plan: Plan, home: Shape?): number
	if not home or home.center.z >= Minimap.middle(plan).z then
		return 0
	end
	return math.pi
end

-- The minimap's view, a box `box` pixels across, for `me` (nil when there's
-- nobody to follow), with these settings and the turn that puts their
-- spawn at the bottom (`home`).
function Minimap.miniView(plan: Plan, s: PlayerSettings.Settings, me: Me?, box: number, home: number): View
	local zoom = s.mapZoom
	local turn = if s.mapRotate and me then me.yaw elseif s.mapBySide then home else 0
	local follow = me ~= nil and (s.mapCentred or zoom > 1 + EPS)
	return {
		centre = if follow and me then me.position else Minimap.middle(plan),
		turn = turn,
		scale = box * zoom / Minimap.across(plan),
		half = box / 2,
	}
end

-- The big map's view: the whole map across a box `box` pixels across, its
-- middle in the middle, the same way round as a fixed minimap.
function Minimap.bigView(plan: Plan, s: PlayerSettings.Settings, box: number, home: number): View
	return {
		centre = Minimap.middle(plan),
		turn = if s.mapBySide then home else 0,
		scale = box / Minimap.across(plan),
		half = box / 2,
	}
end

-- Where a point falls in a view: pixels right and down from the box's
-- middle. Looking down on the map with -z up, x is right and z is down;
-- then it's turned.
function Minimap.toView(view: View, point: vector): (number, number)
	local dx, dz = (point.x - view.centre.x) * view.scale, (point.z - view.centre.z) * view.scale
	local c, sn = math.cos(view.turn), math.sin(view.turn)
	return dx * c - dz * sn, dx * sn + dz * c
end

-- Which way someone looking along `yaw` faces in a view: radians clockwise
-- from up. Yaw 0 looks down -z, up an unturned map.
function Minimap.facing(view: View, yaw: number): number
	return view.turn - yaw
end

-- The yaw of the way a direction on the floor points: the inverse of
-- facing for an unturned view, as Accuracy.aim has yaw.
function Minimap.yawOf(direction: vector): number
	return math.atan2(-direction.x, -direction.z)
end

-- A point in a view held inside its box, `margin` pixels in from the edge:
-- an ally out of the box is shown on its edge, the way to them ("Ally
-- position indicators would persist on the edge of minimap", Patch 5.08).
-- Returns where, and whether it was held.
function Minimap.toEdge(view: View, x: number, y: number, margin: number): (number, number, boolean)
	local most = view.half - margin
	local far = math.max(math.abs(x), math.abs(y))
	if far <= most or far < EPS then
		return x, y, false
	end
	local k = most / far
	return x * k, y * k, true
end

-- The yaws a vision cone's rays look along, from the left of a view
-- `fov` radians across to its right: the middles of `rays` equal wedges of
-- it.
function Minimap.coneYaws(yaw: number, fov: number, rays: number): { number }
	local out = table.create(rays)
	for i = 1, rays do
		out[i] = yaw + fov / 2 - (i - 0.5) * fov / rays
	end
	return out
end

-- Where a ray along the floor from `origin`, the way `dir` points (level,
-- a unit vector), first meets a circle round `centre`, seen from above:
-- how far along, 0 from inside it, or nil if it misses.
function Minimap.rayCircle(origin: vector, dir: vector, centre: vector, radius: number): number?
	local ox, oz = origin.x - centre.x, origin.z - centre.z
	local c = ox * ox + oz * oz - radius * radius
	if c <= 0 then
		return 0
	end
	local b = ox * dir.x + oz * dir.z
	if b >= 0 then
		return nil
	end
	local disc = b * b - c
	if disc < 0 then
		return nil
	end
	return -b - math.sqrt(disc)
end

-- Where such a ray crosses the stretch from `a` to `b`, seen from above:
-- how far along, or nil if it doesn't.
function Minimap.raySegment(origin: vector, dir: vector, a: vector, b: vector): number?
	local sx, sz = b.x - a.x, b.z - a.z
	local cross = dir.x * sz - dir.z * sx
	if math.abs(cross) < EPS then
		return nil
	end
	local qx, qz = a.x - origin.x, a.z - origin.z
	local t = (qx * sz - qz * sx) / cross
	local u = (qx * dir.z - qz * dir.x) / cross
	if t >= 0 and u >= -EPS and u <= 1 + EPS then
		return t
	end
	return nil
end

-- How far a vision cone's ray goes before a cloud or a wall of fire stops
-- it, `most` at the most: the clouds as their centres and radii, the walls
-- as their paths as far as the fire has spread (BlazeSim.spreadPath).
function Minimap.reach(
	origin: vector,
	dir: vector,
	most: number,
	clouds: { { centre: vector, radius: number } },
	walls: { { vector } }
): number
	local best = most
	for _, cloud in clouds do
		local d = Minimap.rayCircle(origin, dir, cloud.centre, cloud.radius)
		if d and d < best then
			best = d
		end
	end
	for _, path in walls do
		for i = 2, #path do
			local d = Minimap.raySegment(origin, dir, path[i - 1], path[i])
			if d and d < best then
				best = d
			end
		end
	end
	return best
end

-- The rectangles a vision cone is drawn with on an unturned map, from its
-- tip at (x, y) in pixels: for each ray, along `yaws` as far as `reaches`
-- (pixels), its wedge `wedge` radians wide, as two rectangles, the near
-- half of it and the far half, each as wide as the wedge at its far end.
-- Painted solid together and shown faint, they're the cone.
function Minimap.coneRects(x: number, y: number, yaws: { number }, reaches: { number }, wedge: number): { Rect }
	local out: { Rect } = {}
	local spread = 2 * math.tan(wedge / 2)
	for i, yaw in yaws do
		local d = reaches[i] or 0
		if d <= EPS then
			continue
		end
		local dx, dy = -math.sin(yaw), -math.cos(yaw)
		local rotation = -math.deg(yaw)
		for k = 1, 2 do
			local mid = d * (k - 0.5) / 2
			table.insert(out, { x = x + dx * mid, y = y + dy * mid, w = spread * d * k / 2, h = d / 2, rotation = rotation })
		end
	end
	return out
end

-- Whether the minimap shows the spike: planted, to everyone; on the
-- ground, to the side that carries it always and to the other side while
-- it sees it ("A dropped spike is visible on the minimap to Attackers, and
-- to Defenders while they have sight of it", the VALORANT Wiki, Spike);
-- carried, to the carrier's side only, as a mark on the carrier (Patch
-- 0.50: "Removed Spike icon from being visible on enemy player minimap
-- icons").
function Minimap.spikeShown(state: string, ours: boolean, seen: boolean): boolean
	if state == "planted" then
		return true
	elseif state == "dropped" then
		return ours or seen
	elseif state == "carried" then
		return ours
	end
	return false
end

-- Whether the big map writes the names of places, by the setting
-- ("always", "buy" for Only in Buy Phase, or "never") and the phase of
-- play: the buy phase, or Team Deathmatch's before it starts.
function Minimap.namesShown(setting: string, phase: any): boolean
	return setting == "always" or (setting == "buy" and (phase == "buy" or phase == "pregame"))
end

return Minimap
