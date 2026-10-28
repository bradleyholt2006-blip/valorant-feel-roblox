--!strict
-- Heights on a spike map (system 59): rooms raised off the ground, decks
-- over a room's floor, stairs and ramps between floors, railings and
-- windows, as MapPlan builds them; and Wharf, rebuilt with them, walked
-- and looked across in three dimensions (Levels): every floor reached and
-- left, each side's runs to each site, what its raised places see, and how
-- open its sites are, against what Counter-Strike's maps measure
-- (docs/research/59-wharf-heights.md).

local MapKit = require("../src/shared/Match/MapKit")
local MapPlan = require("../src/shared/Match/MapPlan")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local H = require("./Harness")
local Levels = require("./Levels")

local check = H.check

H.section("Heights, and Wharf rebuilt with them (system 59)")

local cfg = MovementConfig.resolve()
local P = MapPlan.Plan
local EPS = 1e-6

local function near(a: number?, b: number, tolerance: number?): boolean
	return a ~= nil and math.abs(a - b) <= (tolerance or EPS)
end

-- A part's box, from corner to corner.
local function box(part: MapPlan.Part): (number, number, number, number, number, number)
	local c, h = part.center, part.size / 2
	return c.x - h.x, c.y - h.y, c.z - h.z, c.x + h.x, c.y + h.y, c.z + h.z
end

local function named(parts: { MapPlan.Part }, name: string): { MapPlan.Part }
	local out = {}
	for _, part in parts do
		if part.name == name then
			table.insert(out, part)
		end
	end
	return out
end

-- The parts of a kind whose footprint holds (x, z).
local function under(parts: { MapPlan.Part }, kind: string, x: number, z: number): { MapPlan.Part }
	local out = {}
	for _, part in parts do
		local x0, _, z0, x1, _, z1 = box(part)
		if part.kind == kind and x > x0 and x < x1 and z > z0 and z < z1 then
			table.insert(out, part)
		end
	end
	return out
end

local function wallTop(parts: { MapPlan.Part }, x: number, z: number): number
	local top = -math.huge
	for _, part in under(parts, "wall", x, z) do
		local _, _, _, _, y1 = box(part)
		top = math.max(top, y1)
	end
	return top
end

-- A small map with one of everything --------------------------------------------------------

-- A yard with a loft raised 2 m in its north-west corner, mirrored across
-- it, up stairs from the yard and railed where it drops away, a bridge
-- between the two lofts over the yard's floor, a dais up a ramp, and a shed
-- through a window in the wall.
local LOFT_RAILS: { MapPlan.Side } = { "+x", "+z" }
local BRIDGE_RAILS: { MapPlan.Side } = { "+z" }
local decks: { MapPlan.Deck } = { { name = "Bridge", x0 = -6, z0 = -10, x1 = 6, z1 = -8, y = 2, rails = BRIDGE_RAILS } }
local flights: { MapPlan.Flight } = {
	{ name = "LoftStairs", x0 = -10, z0 = -6, x1 = -6, z1 = 2, up = "-z", y0 = 0, y1 = 2, stairs = true },
	{ name = "Ramp", x0 = 0, z0 = 6, x1 = 4, z1 = 10, up = "+x", y0 = 0, y1 = 1 },
}
local windows: { MapPlan.Window } = { { name = "ShedWindow", x0 = 10, z0 = -1, x1 = 11, z1 = 1, sill = 1, top = 2.2 } }
local yard = MapPlan.new({
	name = "Yard",
	layout = "yard",
	origin = vector.zero,
	rooms = {
		{ name = "AttackerSpawn", x0 = -4, z0 = 10, x1 = 4, z1 = 16 },
		{ name = "DefenderSpawn", x0 = -4, z0 = -16, x1 = 4, z1 = -10 },
		{ name = "Yard", x0 = -10, z0 = -10, x1 = 10, z1 = 10 },
		{ name = "Loft", x0 = -10, z0 = -10, x1 = -6, z1 = -6, y = 2, rails = LOFT_RAILS, mirror = "LoftEast" },
		{ name = "Dais", x0 = 4, z0 = 6, x1 = 10, z1 = 10, y = 1 },
		{ name = "Shed", x0 = 11, z0 = -4, x1 = 15, z1 = 4 },
	},
	decks = decks,
	flights = flights,
	windows = windows,
	cover = { { name = "LoftCrate", x = -8, z = -8, sx = 1, sz = 1, height = "low" } },
	doors = { attack = {}, defend = {} },
	sites = { { site = "A", x = 0, z = 0, sx = 4, sz = 4 } },
	spikeStart = vector.create(0, 0, 13),
})
local parts = yard.parts()

do
	local others = true
	for _, key in SpikeMaps.MAPS do
		if key ~= "wharf" then
			others = others and not SpikeMaps.Maps[key].raised
		end
	end
	check("a map with a raised room, a deck, a flight or a window has heights, as Wharf does", yard.raised and SpikeMaps.Maps.wharf.raised)
	check("and the other maps have none", others)

	check(
		"the floor's height: a room's own, the highest of those there, and none off the floor",
		yard.floorAt(0, 0) == 0
			and yard.floorAt(-8, -8) == 2
			and yard.floorAt(7, 8) == 1
			and yard.floorAt(13, 0) == 0
			and yard.floorAt(10.5, 0) == nil
	)
	check(
		"on a flight, its slope's, from its foot's floor up to its head's",
		near(yard.floorAt(-8, 2), 0) and near(yard.floorAt(-8, -2), 1) and near(yard.floorAt(-8, -6), 2) and near(yard.floorAt(2, 8), 0.5)
	)
	local bridge, open = yard.levelsAt(0, -9), yard.levelsAt(0, 0)
	check(
		"over a deck's room, two floors to stand on: the room's, and the deck's over it",
		#bridge == 2 and bridge[1] == 0 and bridge[2] == 2
	)
	check("elsewhere one", #open == 1 and open[1] == 0 and #yard.levelsAt(-8, -8) == 1)

	local wallH = P.wallHeight.value
	check(
		"a wall stands 5 m over the highest floor within 4 m of it: over the loft, the dais or the ground",
		near(wallTop(parts, -10.5, -8), 2 + wallH) and near(wallTop(parts, 10.5, 8), 1 + wallH) and near(wallTop(parts, -6.5, 14.5), wallH)
	)

	local sills, heads = named(parts, "ShedWindowSill"), named(parts, "ShedWindowHead")
	local split = #sills == 1 and #heads == 1 and #under(parts, "wall", 10.5, 0) == 2
	if split then
		local _, s0, _, _, s1 = box(sills[1])
		local _, h0, _, _, h1 = box(heads[1])
		split = near(s0, 0) and near(s1, 1) and near(h0, 2.2) and near(h1, wallTop(parts, 10.5, 1.5))
	end
	check("a window's cells are wall up to its sill and from its top up, open between", split)

	local stairs, ramp = named(parts, "LoftStairs")[1], named(parts, "Ramp")[1]
	check(
		"a flight is a wedge rising its way, across, up and along it, from its foot's floor",
		stairs ~= nil
			and ramp ~= nil
			and stairs.kind == "flight"
			and stairs.wedge == true
			and near(stairs.yaw, math.pi)
			and stairs.size == vector.create(4, 2, 8)
			and near(stairs.center.y, 1)
			and ramp.wedge == true
			and near(ramp.yaw, math.pi / 2)
			and ramp.size == vector.create(4, 1, 4)
	)
	local steps = named(parts, "LoftStairsStep")
	local risers = #steps > 0
	local top, first, last = 0, math.huge, -math.huge
	for k, step in steps do
		local _, y0, z0, _, y1, z1 = box(step)
		risers = risers and step.style == "step" and near(y0, 0) and y1 - top <= P.stepRise.value + EPS and y1 > top
		top = y1
		first, last = math.min(first, z0), math.max(last, z1)
		-- Each further toward its head, as high as its slope at its far end.
		risers = risers and near(z0, 2 - 8 * k / #steps)
	end
	check(
		"stairs: the wedge walked on, hidden under steps none higher than 0.2 m over the last, up to the head",
		stairs ~= nil and stairs.hidden == true and risers and near(top, 2) and near(first, -6) and near(last, 2)
	)
	check("a ramp is the wedge alone, seen", ramp ~= nil and not ramp.hidden and #named(parts, "RampStep") == 0)

	local slab = named(parts, "Bridge")[1]
	local deck = slab ~= nil and slab.kind == "deck"
	if deck then
		local x0, y0, z0, x1, y1, z1 = box(slab)
		deck = near(x0, -6) and near(x1, 6) and near(z0, -10) and near(z1, -8) and near(y1, 2) and near(y1 - y0, P.slab.value)
	end
	check("a deck is a slab 0.3 m thick, its top the deck's floor", deck)

	-- Railings, as boxes from corner to corner.
	local function rails(name: string): { string }
		local out = {}
		for _, part in named(parts, name) do
			local x0, y0, z0, x1, y1, z1 = box(part)
			table.insert(out, string.format("%g %g %g %g %g %g", x0, y0, z0, x1, y1, z1))
		end
		table.sort(out)
		return out
	end
	local rh, rt = P.railHeight.value, P.railThickness.value
	local function railAt(x0: number, z0: number, x1: number, z1: number): string
		return string.format("%g %g %g %g %g %g", x0, 2, z0, x1, 2 + rh, z1)
	end
	local loft, east, across = rails("LoftRail"), rails("LoftEastRail"), rails("BridgeRail")
	local eastWant = { railAt(6, -8, 6 + rt, -6), railAt(6, -6 - rt, 10, -6) }
	table.sort(eastWant)
	check(
		"a railing along each side asked for, where the floor beyond drops away: not over the stairs' head, nor where the deck goes on",
		#loft == 1 and loft[1] == railAt(-6 - rt, -8, -6, -6) and #across == 1 and across[1] == railAt(-6, -8 - rt, 6, -8)
	)
	check(
		"a mirrored room keeps its height, its railings turned with it",
		yard.floorAt(8, -8) == 2 and #east == 2 and east[1] == eastWant[1] and east[2] == eastWant[2]
	)

	local crate = named(parts, "LoftCrate")[1]
	local h = MapPlan.Heights.low.value
	check("cover stands on the floor under it, raised or not", crate ~= nil and near(crate.center.y, 2 + h / 2))

	local loftFloor, stairFloor = under(parts, "floor", -8, -8), under(parts, "floor", -8, -2)
	local standing = #loftFloor == 1 and #stairFloor == 1
	if standing then
		local _, y0, _, _, y1 = box(loftFloor[1])
		local _, f0, _, _, f1 = box(stairFloor[1])
		standing = near(y0, -1) and near(y1, 2) and near(f0, -1) and near(f1, 0)
	end
	check("a raised room's floor stands on the ground, and a flight's is its foot's, under its wedge", standing)
end

-- Wharf, in three dimensions --------------------------------------------------------------

local wharf = SpikeMaps.Maps.wharf
local level = Levels.ofMap(wharf)
local runs = Levels.runsOf(wharf)
local nodes = level.nodes
local speed = MovementConfig.Params.baseRunSpeed.value

-- Whether a node stands on a floor of the plan's there, not on cover.
local function onLevel(n: Levels.Node): boolean
	for _, y in wharf.levelsAt(n.x, n.z) do
		if math.abs(n.y - y) <= cfg.stepHeight then
			return true
		end
	end
	return false
end

do
	local feet = wharf.spots("attack")[1].feet
	local back = Levels.distances(level, { Levels.nodeAt(level, feet.x, feet.z, feet.y) :: number }, true)
	local floors, lost, stuck = 0, 0, 0
	for id, n in nodes do
		if onLevel(n) then
			floors += 1
			if runs.attack[id] == math.huge then
				lost += 1
			end
			if back[id] == math.huge then
				stuck += 1
			end
		end
	end
	check(
		"every floor of Wharf is reached on foot from the attackers' spawn, and has a way back: nowhere to get stuck",
		floors > 50000 and lost == 0 and stuck == 0,
		string.format("%d places to stand, %d out of reach, %d stuck", floors, lost, stuck)
	)

	-- Its raised places, each reached from both spawns at its height.
	local places: { { name: string, x0: number, z0: number, x1: number, z1: number, y: number } } = {}
	for _, r in wharf.rooms() do
		if (r.y or 0) > 0 then
			table.insert(places, { name = r.name, x0 = r.x0, z0 = r.z0, x1 = r.x1, z1 = r.z1, y = r.y :: number })
		end
	end
	for _, d in wharf.Decks do
		table.insert(places, { name = d.name, x0 = d.x0, z0 = d.z0, x1 = d.x1, z1 = d.z1, y = d.y })
	end
	local reached, names = #places >= 6, {}
	for _, place in places do
		local found = false
		for id, n in nodes do
			if n.x > place.x0 and n.x < place.x1 and n.z > place.z0 and n.z < place.z1 and math.abs(n.y - place.y) <= cfg.stepHeight then
				found = found or (runs.attack[id] < math.huge and runs.defend[id] < math.huge)
			end
		end
		reached = reached and found
		table.insert(names, place.name)
	end
	check("its raised places each reached from either spawn: " .. table.concat(names, ", "), reached)
end

-- What Counter-Strike's maps measure (docs/research/59-wharf-heights.md), and
-- the band of it we aim for.
local HEAVEN_UP = { 2.6, 3.3 } -- m over its site: Inferno's balcony to Mirage's scaffolding
local HEAVEN_OFF = { 9, 14 } -- m from the site's middle
local ATTACKERS = { 12, 17 } -- s to a site, running with the knife
local DEFENDERS = { 6, 9 }
local GAP = { 5, 9 }
local OPEN_CIRCLE = 5 -- m: the widest circle clear of everything on a site
local OPEN_SHARE = 0.1 -- of a site's floor more than 4 m from anything

local function within(v: number, range: { number }): boolean
	return v >= range[1] - EPS and v <= range[2] + EPS
end

do
	-- Heaven: its room and its decks, where they are on the whole.
	local area, sx, sz, y = 0, 0, 0, 0
	for _, r in wharf.rooms() do
		if r.name == "AHeaven" then
			local a = (r.x1 - r.x0) * (r.z1 - r.z0)
			area, sx, sz, y = area + a, sx + a * (r.x0 + r.x1) / 2, sz + a * (r.z0 + r.z1) / 2, r.y :: number
		end
	end
	for _, d in wharf.Decks do
		local a = (d.x1 - d.x0) * (d.z1 - d.z0)
		area, sx, sz = area + a, sx + a * (d.x0 + d.x1) / 2, sz + a * (d.z0 + d.z1) / 2
	end
	local site = wharf.Sites[1]
	local off = math.sqrt((sx / area - site.x) ^ 2 + (sz / area - site.z) ^ 2)
	local up = y - (wharf.floorAt(site.x, site.z) or 0)
	check(
		"A's heaven stands over its site as Counter-Strike's heavens and balconies do: 2.6 to 3.3 m up, 9 to 14 m from its middle",
		within(up, HEAVEN_UP) and within(off, HEAVEN_OFF),
		string.format("%.1f m up, %.1f m off", up, off)
	)

	-- Each side's run to each plant area, from its first spawn spot.
	local inBand, lines = true, {}
	for _, zone in wharf.zones() do
		local c = zone.center - wharf.origin
		local floor = c.y - zone.half.y
		local a, d = math.huge, math.huge
		for id, n in nodes do
			if math.abs(n.x - c.x) <= zone.half.x and math.abs(n.z - c.z) <= zone.half.z and math.abs(n.y - floor) <= cfg.stepHeight then
				a, d = math.min(a, runs.attack[id]), math.min(d, runs.defend[id])
			end
		end
		a, d = a / speed, d / speed
		inBand = inBand and within(a, ATTACKERS) and within(d, DEFENDERS) and within(a - d, GAP)
		table.insert(lines, string.format("%s %.1f s against %.1f s (%+.1f s)", zone.site, d, a, a - d))
	end
	print("  Wharf, the defenders' and the attackers' runs to each plant area: " .. table.concat(lines, "; "))
	check("running with the knife, the defenders reach each plant area 5 to 9 s first, in 6 to 9 s against the attackers' 12 to 17", inBand)

	-- Each plant area flat, under nothing to stand on.
	local flat = true
	for _, s in wharf.Sites do
		local ground = wharf.floorAt(s.x, s.z)
		for x = s.x - s.sx / 2 + 0.25, s.x + s.sx / 2, 0.5 do
			for z = s.z - s.sz / 2 + 0.25, s.z + s.sz / 2, 0.5 do
				local levels = wharf.levelsAt(x, z)
				flat = flat and #levels == 1 and levels[1] == ground
			end
		end
	end
	check("each site's plant area is level ground, with no deck over it", flat)

	-- Room under each deck.
	local headroom = math.huge
	for _, d in wharf.Decks do
		for x = d.x0 + 0.5, d.x1, 1 do
			for z = d.z0 + 0.5, d.z1, 1 do
				local floor = wharf.floorAt(x, z)
				if floor and floor < d.y - P.drop.value then
					headroom = math.min(headroom, d.y - P.slab.value - floor)
				end
			end
		end
	end
	check(
		"under each deck there's room to stand and jump",
		headroom >= cfg.standHeight + cfg.jumpApexHeight and headroom < math.huge,
		string.format("%.2f m", headroom)
	)

	local slopes = #wharf.Flights > 0
	local steepest = 0
	for _, f in wharf.Flights do
		local run = if f.up == "+x" or f.up == "-x" then f.x1 - f.x0 else f.z1 - f.z0
		steepest = math.max(steepest, math.deg(math.atan((f.y1 - f.y0) / run)))
		-- The foot's and the head's floors meet it.
		local foot = if f.up == "+x"
			then vector.create(f.x0 - 0.5, 0, (f.z0 + f.z1) / 2)
			elseif f.up == "-x" then vector.create(f.x1 + 0.5, 0, (f.z0 + f.z1) / 2)
			elseif f.up == "+z" then vector.create((f.x0 + f.x1) / 2, 0, f.z0 - 0.5)
			else vector.create((f.x0 + f.x1) / 2, 0, f.z1 + 0.5)
		local head = if f.up == "+x"
			then vector.create(f.x1 + 0.5, 0, (f.z0 + f.z1) / 2)
			elseif f.up == "-x" then vector.create(f.x0 - 0.5, 0, (f.z0 + f.z1) / 2)
			elseif f.up == "+z" then vector.create((f.x0 + f.x1) / 2, 0, f.z1 + 0.5)
			else vector.create((f.x0 + f.x1) / 2, 0, f.z0 - 0.5)
		local function meets(at: vector, y: number): boolean
			for _, level in wharf.levelsAt(at.x, at.z) do
				if math.abs(level - y) <= EPS then
					return true
				end
			end
			return false
		end
		slopes = slopes and meets(foot, f.y0) and meets(head, f.y1)
	end
	check(
		"every stair and ramp meets the floor at its foot and at its head, no steeper than the book's 30 to 35 degree stairs",
		slopes and steepest <= 30 and steepest < cfg.maxGroundAngle,
		string.format("%.1f degrees at the steepest", steepest)
	)
end

-- What its raised places and windows see ----------------------------------------------------

-- The solids an eye can't see through, the biggest first, as they're the
-- likeliest in the way: the level's, and a box round each tree's leaves,
-- which shots and steps go through but an eye doesn't.
local sight = table.clone(level.solids)
for _, c in wharf.cover() do
	if c.piece == "Tree" then
		local size = vector.create(c.sx, MapPlan.Heights[c.height].value, c.sz)
		local reach, y0, y1 = 0, math.huge, -math.huge
		for _, bit in MapKit.bits("Tree", size, MapKit.lookOf("Tree", c.name, c.look)) do
			if bit.name == "Leaves" then
				reach = math.max(reach, math.sqrt(bit.offset.x ^ 2 + bit.offset.z ^ 2) + bit.size.x / 2)
				y0 = math.min(y0, bit.offset.y - bit.size.y / 2)
				y1 = math.max(y1, bit.offset.y + bit.size.y / 2)
			end
		end
		local planted = wharf.floorAt(c.x, c.z) or 0
		table.insert(sight, {
			x0 = c.x - reach,
			y0 = planted + y0,
			z0 = c.z - reach,
			x1 = c.x + reach,
			y1 = planted + y1,
			z1 = c.z + reach,
			floor = false,
		})
	end
end
local function volume(s: Levels.Solid): number
	return (s.x1 - s.x0) * (s.y1 - s.y0) * (s.z1 - s.z0)
end
table.sort(sight, function(a: Levels.Solid, b: Levels.Solid): boolean
	return volume(a) > volume(b)
end)

do
	-- The window room: its frame too high to climb, its opening at a
	-- standing eye, which sees down mid.
	local frame = wharf.Windows[1]
	local room = wharf.room("MidWindow") :: MapPlan.Room
	local floor = room.y or 0
	local eye = floor + cfg.standEyeHeight
	check(
		"the window room's frame is too high to climb through, its opening at a standing eye",
		frame.name == "MidWindowFrame" and frame.sill - floor > Levels.CLIMB and frame.sill < eye and frame.top > eye
	)
	local seen, total = 0, 0
	for z = 4.5, 16.5, 2 do
		total += 1
		if Levels.sees(sight, vector.create(0, eye, room.z1 - 0.5), vector.create(0.5, 1.6, z)) then
			seen += 1
		end
	end
	check("from it, standing at the frame, mid's lane in sight", seen == total, string.format("%d of %d", seen, total))

	-- Hookah's window: a vault onto B, quicker than the way round.
	local bw = wharf.Windows[2]
	local inside = Levels.nodeAt(level, bw.x0 - 2.5, (bw.z0 + bw.z1) / 2, 0)
	local outside = Levels.nodeAt(level, bw.x1 + 2.5, (bw.z0 + bw.z1) / 2, 0)
	local through = math.huge
	if inside and outside then
		through = Levels.distances(level, { inside })[outside]
	end
	check(
		"hookah's window to B, its sill a jump up from either side: a few metres through, not round by the door",
		bw.name == "BWindow" and bw.sill <= Levels.CLIMB and bw.top - bw.sill >= cfg.standHeight and through < 8,
		string.format("%.1f m", through)
	)

	-- From each raised place, jumping, no sight into the attackers' spawn,
	-- where a defender up there could catch them on the way out.
	local function grid(x0: number, z0: number, x1: number, z1: number, y: number, step: number): { vector }
		local out = {}
		for x = x0 + step / 2, x1, step do
			for z = z0 + step / 2, z1, step do
				table.insert(out, vector.create(x, y, z))
			end
		end
		return out
	end
	local eyes: { vector } = {}
	local jump = cfg.standEyeHeight + cfg.jumpApexHeight
	for _, r in wharf.rooms() do
		if (r.y or 0) > 0 then
			for _, at in grid(r.x0, r.z0, r.x1, r.z1, (r.y :: number) + jump, 1) do
				table.insert(eyes, at)
			end
		end
	end
	for _, d in wharf.Decks do
		for _, at in grid(d.x0, d.z0, d.x1, d.z1, d.y + jump, 1) do
			table.insert(eyes, at)
		end
	end
	local open, lines = 0, 0
	local spawn = wharf.room("AttackerSpawn") :: MapPlan.Room
	for _, b in grid(spawn.x0, spawn.z0, spawn.x1, spawn.z1, (spawn.y or 0) + 1.6, 1) do
		for _, a in eyes do
			lines += 1
			if Levels.sees(sight, a, b) then
				open += 1
			end
		end
	end
	check(
		"from no raised place, even jumping, can anyone see into the attackers' spawn",
		open == 0 and lines > 10000,
		string.format("%d of %d lines open", open, lines)
	)
end

-- How open its sites are --------------------------------------------------------------------

do
	-- On each site's floor, every free column's way to the nearest column
	-- with no footing at that floor: cover, a wall, a step up or down.
	local C = level.options.cell
	local ok, lines = true, {}
	for _, s in { "A", "B" } do
		local room = wharf.room(s .. "Site") :: MapPlan.Room
		local y = room.y or 0
		local R = 6
		local function standing(i: number, j: number): boolean
			if i < 1 or i > level.nx or j < 1 or j > level.nz then
				return false
			end
			for _, id in level.at[(j - 1) * level.nx + i] do
				if math.abs(nodes[id].y - y) <= cfg.stepHeight then
					return true
				end
			end
			return false
		end
		local free, far, widest = 0, 0, 0
		local i0, j0 = Levels.columnOf(level, room.x0, room.z0)
		local i1, j1 = Levels.columnOf(level, room.x1, room.z1)
		local reach = math.ceil(R / C)
		for i = i0, i1 - 1 do
			for j = j0, j1 - 1 do
				if standing(i, j) then
					free += 1
					local best = R * R
					for a = i - reach, i + reach do
						for b = j - reach, j + reach do
							local d2 = ((a - i) * C) ^ 2 + ((b - j) * C) ^ 2
							if d2 < best and not standing(a, b) then
								best = d2
							end
						end
					end
					local d = math.sqrt(best)
					widest = math.max(widest, d)
					if d > 4 then
						far += 1
					end
				end
			end
		end
		local share = far / math.max(free, 1)
		ok = ok and widest <= OPEN_CIRCLE and share <= OPEN_SHARE
		table.insert(lines, string.format("%s %.1f m and %.0f%%", s, widest, share * 100))
	end
	check(
		"no wide open ground on a site: nowhere on it more than 5 m from something, and under a tenth of it more than 4 m",
		ok,
		table.concat(lines, ", ")
	)
end

return nil
