--!strict
-- Where bots stand and look on a spike map (system 60), worked out once
-- from its nav (BotNav), as the Counter-Strike bot's map is analysed for
-- its 'Hiding Spots' and 'Approach Points' as it's learned (Booth, "The
-- Official Counter-Strike Bot", GDC 2004):
--   * each site's area: what's within a walk of its plant area
--   * its entrances: where the attackers' shortest ways in from their
--     spawn cross into that area, each the place on its edge they reach
--     first, and a little further out, the head height they'd appear at
--   * the spots to hold each entrance from: in the site's area or just
--     behind it, seeing the entrance from a fight's distance, with cover
--     beside them ('All Hiding Spots provide good cover', Booth), and seen
--     from as few of the other entrances as can be, so a holder takes one
--     fight at a time, and best of all behind low cover that shows the
--     entrance only their head. The attackers check the same spots as they
--     come in, as a player pre-aims the angles they know are held
--   * each entrance's staging spot: on the attackers' way to it, a few
--     metres short of it, where they gather before they push
--
-- How far each node is from each side's spawn is kept too: the time the
-- enemy can first be somewhere, as the NAV format keeps each area's
-- 'Earliest occupy times for teams' (the Valve Developer Community).
--
-- Plain data and maths in metres, in the map's own frame, as BotNav's.

local BotNav = require("./BotNav")

local BotSpots = {}

export type Entrance = {
	site: string,
	node: number, -- where the attackers' way crosses into the site's area
	outside: number, -- where they come from, a few metres further out
	aim: vector, -- head height where they'd appear: what's held
	stage: number, -- where they gather before pushing in
}

export type Hold = {
	node: number,
	entrance: number, -- the entrance held, by its number in the site's
	aim: vector,
	low: boolean, -- behind low cover, which hides all but the head from it
	distance: number,
}

export type Site = {
	name: string,
	centre: number, -- the node at the middle of its plant area
	field: { number }, -- how far each node is from the centre on foot
	entrances: { Entrance },
	holds: { Hold },
	area: { number }, -- the nodes of its area
}

export type Plan = {
	nav: BotNav.Nav,
	attack: { number }, -- how far each node is from the attackers' spawn
	defend: { number }, -- and from the defenders'
	sites: { Site },
}

-- How far from a site's plant area its area reaches, on foot (estimate):
-- a 12 m by 10 m plant area's corners are about 8 m from its middle, and
-- the area takes in a few metres round them.
BotSpots.AREA = 14
-- How much further out than an entrance's edge the attackers come from.
BotSpots.OUT = 3
-- How far short of an entrance the attackers gather, on their way.
BotSpots.STAGE = 9
-- How far from what it holds a spot is, at the nearest and furthest
-- (estimate): far enough that whoever comes through doesn't walk onto
-- the holder, near enough to hit them with a rifle's first shots.
BotSpots.NEAREST = 6
BotSpots.FURTHEST = 26
-- The distance a holder likes best: a typical engagement on a site.
BotSpots.BEST = 13
-- How many ways in are looked for at most; how much further each metre
-- near a way already found counts, for the next; how long a stretch of
-- it before the area, and how wide; how far apart two ways' entries are
-- to be different ways in; and how much longer than the shortest a way
-- may be and still count (estimates).
BotSpots.WAYS = 4
BotSpots.DETOUR = 4
BotSpots.STRETCH = 25
BotSpots.WIDTH = 4
BotSpots.DISTINCT = 7
BotSpots.LONGER = 1.6
-- How many spots are kept to hold each entrance from, at least this far
-- apart.
BotSpots.HOLDS = 4
BotSpots.APART = 3

local EYE = 1.62 -- standing (MovementConfig's standEyeHeight)
local WAIST = 0.9
local HEAD = 1.62 -- a standing head's middle (Hitboxes)

local function feet(nav: BotNav.Nav, n: number): vector
	return BotNav.feet(nav, n)
end

-- The node `metres` further down the field from node n (toward lower
-- values): each step to the neighbour lowest in it, so along a shortest
-- way to wherever the field is measured from.
function BotSpots.down(nav: BotNav.Nav, field: { number }, n: number, metres: number): number
	local at = n
	local start = field[n]
	while field[at] > 0 and start - field[at] < metres do
		local best, bestValue = at, field[at]
		for k = nav.first[at], nav.first[at + 1] - 1 do
			local other = nav.links[k]
			if field[other] < bestValue then
				best, bestValue = other, field[other]
			end
		end
		if best == at then
			break
		end
		at = best
	end
	return at
end

-- How many solids an eye can't see through are beside node n, within a
-- metre round the box: a holder's cover. Low cover counts as much as a
-- wall: a crouch behind it, or a head over it, is all that shows.
local function coverAt(nav: BotNav.Nav, n: number): number
	local p = feet(nav, n)
	local count = 0
	local dirs = { vector.create(1, 0, 0), vector.create(-1, 0, 0), vector.create(0, 0, 1), vector.create(0, 0, -1) }
	for _, d in dirs do
		-- Something solid between the waist and the eye, a metre that way.
		local from = p + vector.create(0, 0.9, 0)
		if not BotNav.sees(nav, from, from + d * 1.0) then
			count += 1
		end
	end
	return count
end

-- The nodes within `radius` metres of node n, across the floor and near
-- its height: the columns round it.
local function around(nav: BotNav.Nav, n: number, radius: number, visit: (number) -> ())
	local C = nav.options.cell
	local r = math.ceil(radius / C)
	local i0, j0 = nav.ci[n], nav.cj[n]
	local x, y, z = nav.xs[n], nav.ys[n], nav.zs[n]
	for i = math.max(i0 - r, 1), math.min(i0 + r, nav.nx) do
		for j = math.max(j0 - r, 1), math.min(j0 + r, nav.nz) do
			for _, other in nav.at[(j - 1) * nav.nx + i] do
				if math.abs(nav.ys[other] - y) < 2 and (nav.xs[other] - x) ^ 2 + (nav.zs[other] - z) ^ 2 <= radius * radius then
					visit(other)
				end
			end
		end
	end
end

-- A site's entrances: the ways the attackers come into its area, each the
-- first node of its area on a shortest way in from their spawn. The first
-- is the shortest way of all; each next keeps away from the last stretch
-- of the ways found before it, as a second way round would, and counts if
-- it comes in somewhere else and isn't much longer.
local function entrancesOf(nav: BotNav.Nav, attack: { number }, starts: { number }, site: Site): { Entrance }
	local inArea: { [number]: boolean } = {}
	for _, n in site.area do
		inArea[n] = true
	end
	-- The spawn's node nearest the site to start from: any of them, as
	-- the field from all of them has it.
	local start = starts[1]
	for _, n in starts do
		if site.field[n] < site.field[start] then
			start = n
		end
	end
	local avoid: { [number]: boolean } = {}
	local out: { Entrance } = {}
	local shortest = math.huge
	for _ = 1, BotSpots.WAYS do
		local path = BotNav.path(nav, start, site.centre, function(n: number): number
			return if avoid[n] then BotSpots.DETOUR else 0
		end)
		if not path then
			break
		end
		local entry: number? = nil
		local index = 0
		for k, n in path do
			if inArea[n] then
				entry, index = n, k
				break
			end
		end
		if not entry then
			break
		end
		local length = attack[entry]
		-- The way's length on foot to the entry, detours and all.
		local walked = 0
		for k = 2, index do
			walked += vector.magnitude(BotNav.feet(nav, path[k]) - BotNav.feet(nav, path[k - 1]))
		end
		shortest = math.min(shortest, walked)
		local apart = true
		for _, e in out do
			if vector.magnitude(BotNav.feet(nav, e.node) - BotNav.feet(nav, entry)) < BotSpots.DISTINCT then
				apart = false
			end
		end
		if apart and walked <= shortest * BotSpots.LONGER and length < math.huge then
			-- Where they come from: a few metres back along this way.
			local back = math.max(index - math.ceil(BotSpots.OUT / nav.options.cell), 1)
			local stage = math.max(index - math.ceil(BotSpots.STAGE / nav.options.cell), 1)
			local outside = path[back]
			table.insert(out, {
				site = site.name,
				node = entry,
				outside = outside,
				aim = feet(nav, outside) + vector.create(0, HEAD, 0),
				stage = path[stage],
			})
		end
		-- The next way keeps off this one's last stretch before the area.
		local from = math.max(index - math.ceil(BotSpots.STRETCH / nav.options.cell), 1)
		for k = from, index do
			around(nav, path[k], BotSpots.WIDTH, function(other: number)
				avoid[other] = true
			end)
		end
	end
	return out
end

-- The spots to hold each of a site's entrances from: in its area, seeing
-- the entrance from between NEAREST and FURTHEST, scored by how near the
-- best distance, how much cover is beside them and how few other
-- entrances see them, the best few at least APART apart.
local function holdsOf(nav: BotNav.Nav, defend: { number }, site: Site): { Hold }
	local out: { Hold } = {}
	for index, entrance in site.entrances do
		local scored: { { node: number, score: number, low: boolean, distance: number } } = {}
		for _, n in site.area do
			-- Somewhere the defenders get to: not on top of cover.
			if defend[n] == math.huge then
				continue
			end
			local p = feet(nav, n)
			local distance = vector.magnitude(entrance.aim - (p + vector.create(0, EYE, 0)))
			if distance < BotSpots.NEAREST or distance > BotSpots.FURTHEST then
				continue
			end
			local eye = p + vector.create(0, EYE, 0)
			if not BotNav.sees(nav, eye, entrance.aim) then
				continue
			end
			local low = not BotNav.sees(nav, p + vector.create(0, WAIST, 0), entrance.aim)
			-- Seen from the other entrances: open to more than one fight.
			local open = 0
			for other, e in site.entrances do
				if other ~= index and BotNav.sees(nav, e.aim, eye) then
					open += 1
				end
			end
			local cover = coverAt(nav, n)
			local score = -math.abs(distance - BotSpots.BEST) / 3 + math.min(cover, 2) * 1.5 - open * 2.5 + (if low then 2 else 0)
			table.insert(scored, { node = n, score = score, low = low, distance = distance })
		end
		table.sort(scored, function(a, b): boolean
			if a.score ~= b.score then
				return a.score > b.score
			end
			return a.node < b.node
		end)
		local kept = 0
		local chosen: { vector } = {}
		for _, s in scored do
			if kept >= BotSpots.HOLDS then
				break
			end
			local p = feet(nav, s.node)
			local apart = true
			for _, q in chosen do
				if vector.magnitude(p - q) < BotSpots.APART then
					apart = false
					break
				end
			end
			-- Not one already held, from another entrance.
			for _, h in out do
				if h.node == s.node then
					apart = false
				end
			end
			if apart then
				table.insert(chosen, p)
				table.insert(out, { node = s.node, entrance = index, aim = entrance.aim, low = s.low, distance = s.distance })
				kept += 1
			end
		end
	end
	return out
end

-- The node nearest p across the floor, within `radius`, that the field
-- reaches: somewhere to get to, not the top of a crate in the middle of a
-- site.
local function reachableNear(nav: BotNav.Nav, field: { number }, p: vector, radius: number): number?
	local best: number? = nil
	local bestScore = math.huge
	local i0, j0 = BotNav.columnOf(nav, p.x, p.z)
	local r = math.ceil(radius / nav.options.cell)
	for i = math.max(i0 - r, 1), math.min(i0 + r, nav.nx) do
		for j = math.max(j0 - r, 1), math.min(j0 + r, nav.nz) do
			for _, n in nav.at[(j - 1) * nav.nx + i] do
				if field[n] < math.huge then
					local score = (nav.xs[n] - p.x) ^ 2 + (nav.zs[n] - p.z) ^ 2 + 4 * (nav.ys[n] - p.y) ^ 2
					if score < bestScore then
						best, bestScore = n, score
					end
				end
			end
		end
	end
	return best
end
BotSpots.reachableNear = reachableNear

-- The nodes the spots of each side's spawn stand on, as `spots` has them.
local function spawnNodes(nav: BotNav.Nav, spots: { { feet: vector, yaw: number } }): { number }
	local out = {}
	for _, spot in spots do
		local n = BotNav.nodeAt(nav, spot.feet)
		if n then
			table.insert(out, n)
		end
	end
	return out
end

local planned: { [any]: Plan } = {}

-- A spike map's plan, worked out once.
function BotSpots.ofMap(map: any, pause: (() -> ())?): Plan
	local known = planned[map]
	if known then
		return known
	end
	local nav = BotNav.ofMap(map, pause)
	local attackers = spawnNodes(nav, map.spots("attack"))
	local attack = BotNav.distances(nav, attackers)
	if pause then
		pause()
	end
	local defend = BotNav.distances(nav, spawnNodes(nav, map.spots("defend")))
	if pause then
		pause()
	end
	local sites: { Site } = {}
	for _, s in map.Sites do
		local y = map.floorAt(s.x, s.z) or 0
		local centre = reachableNear(nav, attack, vector.create(s.x, y, s.z), 6)
		if not centre then
			continue
		end
		local field = BotNav.distances(nav, { centre })
		local area = {}
		for n, d in field do
			if d <= BotSpots.AREA then
				table.insert(area, n)
			end
		end
		local site: Site = { name = s.site, centre = centre, field = field, entrances = {}, holds = {}, area = area }
		site.entrances = entrancesOf(nav, attack, attackers, site)
		site.holds = holdsOf(nav, defend, site)
		table.insert(sites, site)
		if pause then
			pause()
		end
	end
	local plan: Plan = { nav = nav, attack = attack, defend = defend, sites = sites }
	planned[map] = plan
	return plan
end

-- A site of a plan, by its letter.
function BotSpots.site(plan: Plan, name: string): Site?
	for _, s in plan.sites do
		if s.name == name then
			return s
		end
	end
	return nil
end

return BotSpots
