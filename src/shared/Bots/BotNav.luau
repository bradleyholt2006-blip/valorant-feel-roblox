--!strict
-- Where a bot can go on a map, and what it can see from where (system 60):
-- the map's floors in three dimensions on a grid of columns, each holding a
-- node for each height a player's box can stand at there, joined to the
-- nodes beside it that the box can get to on foot: walking (level, or up
-- or down a step or a slope), jumping up a little, or dropping down.
--
-- It stands in for the Counter-Strike bot's navigation mesh, whose
-- 'Navigation Areas represent 2D "walkable" areas' and 'Paths can pass
-- through the area anywhere' (Booth, "The Official Counter-Strike Bot",
-- GDC 2004), and which is 'generated automatically when bots are played'
-- (the Valve Developer Community's page on the NAV file format). Ours is
-- worked out from the plan the server builds the map from, in squares of
-- one size rather than merged rectangles, and its paths are A*'s, with an
-- 'Increased cost for crossing Jump and/or Crouch areas and Ladders'
-- (Booth): a jump costs JUMP_COST metres more here.
--
-- The rules are the offline tests' (tests/Levels.luau, system 59), on a
-- coarser grid and with each node's moves worked out once, so a search is
-- quick enough to run in a server frame. What an eye sees goes by the same
-- solids, through the 4 m tiles they're filed in.
--
-- Plain data and maths in metres, in the map's own frame (from its centre):
-- the server adds the map's origin.

local MapKit = require("../Match/MapKit")
local MovementConfig = require("../Movement/MovementConfig")

local BotNav = {}

-- A solid from (x0, y0, z0) to (x1, y1, z1). A wedge's top slopes from y0
-- at its foot up to y1 at its head, toward `rise`. Whether its top is
-- somewhere to stand, whether it's in a body's way, and whether an eye
-- sees through it: a tree's leaves are in an eye's way and no body's.
export type Solid = {
	x0: number,
	y0: number,
	z0: number,
	x1: number,
	y1: number,
	z1: number,
	rise: string?,
	floor: boolean,
	body: boolean,
	sight: boolean,
}

export type Options = {
	cell: number, -- metres between columns
	half: number, -- half the player's width
	margin: number, -- clear round the box, more than its own width
	height: number, -- the box standing
	step: number, -- walked up without a jump
	climb: number, -- jumped up onto
	columns: (x: number, z: number) -> boolean, -- where to look for footing at all
}

-- The nodes by number: each one's feet (xs, ys, zs) and column (ci, cj),
-- and whether it's on an edge, its footing only under the side of the box,
-- not its middle; each column's nodes; and each node's moves, those of
-- node n being links[first[n]] to links[first[n + 1] - 1], with what each
-- costs (metres along the floor, a jump's JUMP_COST more, an edge's
-- EDGE_COST) and whether it's a jump.
export type Nav = {
	options: Options,
	x0: number,
	z0: number,
	nx: number,
	nz: number,
	xs: { number },
	ys: { number },
	zs: { number },
	ci: { number },
	cj: { number },
	edges: { boolean },
	at: { { number } },
	first: { number },
	links: { number },
	costs: { number },
	jumps: { boolean },
	solids: { Solid },
	-- The solids by 4 m tile, from (x0, z0), tx across and tz along.
	tx: number,
	tz: number,
	tiles: { { number } },
	-- A search's scratch, reused: the best cost to each node, the node it
	-- came from, and the search that last set them; and the sight test that
	-- last looked at each solid.
	best: { number },
	from: { number },
	stamp: { number },
	marks: { number },
	searches: number,
}

local TILE = 4
local EMPTY: { number } = {}
-- How many columns or nodes are worked through between pauses.
local BATCH = 2048

-- How high a path jumps up onto something: under the jump's apex, 0.85 m,
-- as the box has to clear the edge on its way over (tests/Levels.luau has
-- 0.8), and a little more, for a jump made from a slope or a stair a
-- little below the node it's made from.
BotNav.CLIMB = 0.75
-- What a jump up costs more than the walk, in metres: enough that a path
-- takes a ramp or stairs a few metres further on rather than jump up
-- beside them, as a player does, a jump being slower and less sure.
BotNav.JUMP_COST = 4
-- What going onto an edge node costs more, in metres: a box can stand with
-- its side on a crate's or a ramp's edge, but a path along one is a sliver
-- a step off which leaves it beside, below, so a path keeps to the middle
-- where there's one.
BotNav.EDGE_COST = 1
-- Metres between columns: a door's 1.5 m leaves the box's middle 0.62 m to
-- be in, so a column's middle always lands in it.
BotNav.CELL = 0.5
-- How high a wall's top is somewhere to stand: a window's sill.
local SILL = 2.5

-- The highest a solid's top comes over the part of the rectangle from
-- (ax, az) to (bx, bz) that it covers.
local function topOver(s: Solid, ax: number, az: number, bx: number, bz: number): number
	local rise = s.rise
	if rise == nil then
		return s.y1
	end
	local t
	if rise == "+x" then
		t = (math.min(bx, s.x1) - s.x0) / (s.x1 - s.x0)
	elseif rise == "-x" then
		t = (s.x1 - math.max(ax, s.x0)) / (s.x1 - s.x0)
	elseif rise == "+z" then
		t = (math.min(bz, s.z1) - s.z0) / (s.z1 - s.z0)
	else
		t = (s.z1 - math.max(az, s.z0)) / (s.z1 - s.z0)
	end
	return s.y0 + (s.y1 - s.y0) * math.clamp(t, 0, 1)
end

-- How high a wedge's top is over the point (x, z), or a box's.
function BotNav.heightOf(s: Solid, x: number, z: number): number
	return topOver(s, x, z, x, z)
end

-- A solid from a plan's part: its box, turned by its yaw if it's a wedge.
function BotNav.solidOf(part: any, floor: boolean, body: boolean, sight: boolean): Solid
	local c, size = part.center, part.size
	if part.wedge then
		local sideways = math.abs(math.sin(part.yaw)) > 0.5
		local sx, sz = if sideways then size.z else size.x, if sideways then size.x else size.z
		local rise
		if sideways then
			rise = if math.sin(part.yaw) > 0 then "+x" else "-x"
		else
			rise = if math.cos(part.yaw) > 0 then "+z" else "-z"
		end
		return {
			x0 = c.x - sx / 2,
			y0 = c.y - size.y / 2,
			z0 = c.z - sz / 2,
			x1 = c.x + sx / 2,
			y1 = c.y + size.y / 2,
			z1 = c.z + sz / 2,
			rise = rise,
			floor = floor,
			body = body,
			sight = sight,
		}
	end
	-- A box turned about y: the box round its turned footprint.
	local cos, sin = math.abs(math.cos(part.yaw)), math.abs(math.sin(part.yaw))
	local hx = (cos * size.x + sin * size.z) / 2
	local hz = (sin * size.x + cos * size.z) / 2
	return {
		x0 = c.x - hx,
		y0 = c.y - size.y / 2,
		z0 = c.z - hz,
		x1 = c.x + hx,
		y1 = c.y + size.y / 2,
		z1 = c.z + hz,
		floor = floor,
		body = body,
		sight = sight,
	}
end

-- The tile (a, b), from 0, holding the point (x, z), kept on the grid.
local function tileOf(nav: Nav, x: number, z: number): (number, number)
	return math.clamp(math.floor((x - nav.x0) / TILE), 0, nav.tx - 1), math.clamp(math.floor((z - nav.z0) / TILE), 0, nav.tz - 1)
end

-- Each solid in the tiles it reaches over.
local function fileSolids(nav: Nav)
	for id, s in nav.solids do
		local a0, b0 = tileOf(nav, s.x0, s.z0)
		local a1, b1 = tileOf(nav, s.x1, s.z1)
		for a = a0, a1 do
			for b = b0, b1 do
				table.insert(nav.tiles[b * nav.tx + a + 1], id)
			end
		end
	end
end

-- The body solids over the rectangle from (ax, az) to (bx, bz), each once.
local function near(nav: Nav, seen: { number }, stamp: number, ax: number, az: number, bx: number, bz: number): { Solid }
	local out = {}
	local a0, b0 = tileOf(nav, ax, az)
	local a1, b1 = tileOf(nav, bx, bz)
	for a = a0, a1 do
		for b = b0, b1 do
			for _, id in nav.tiles[b * nav.tx + a + 1] do
				if seen[id] ~= stamp then
					seen[id] = stamp
					local s = nav.solids[id]
					if s.body and s.x0 < bx and s.x1 > ax and s.z0 < bz and s.z1 > az then
						table.insert(out, s)
					end
				end
			end
		end
	end
	return out
end

-- How the box gets from a node at height ay to one beside it at by, if it
-- can: "walk" (level, or up or down a step), "jump" (up a little) or
-- "drop".
local function move(o: Options, ay: number, by: number): string?
	local dy = by - ay
	if math.abs(dy) <= o.step then
		return "walk"
	elseif dy > 0 and dy <= o.climb then
		return "jump"
	elseif dy < 0 then
		return "drop"
	end
	return nil
end

local WAYS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

-- The nodes of the solids over the rectangle from (x0, z0) to (x1, z1),
-- and their moves. `pause`, if given, is called every so often, so a
-- server can spread the work over frames.
function BotNav.new(solids: { Solid }, x0: number, z0: number, x1: number, z1: number, options: Options, pause: (() -> ())?): Nav
	local C, h, m = options.cell, options.half, options.margin
	local nx, nz = math.ceil((x1 - x0) / C), math.ceil((z1 - z0) / C)
	local tx, tz = math.max(math.ceil((x1 - x0) / TILE), 1), math.max(math.ceil((z1 - z0) / TILE), 1)
	local tiles: { { number } } = table.create(tx * tz)
	for k = 1, tx * tz do
		tiles[k] = {}
	end
	local nav: Nav = {
		options = options,
		x0 = x0,
		z0 = z0,
		nx = nx,
		nz = nz,
		xs = {},
		ys = {},
		zs = {},
		ci = {},
		cj = {},
		edges = {},
		at = table.create(nx * nz, EMPTY),
		first = {},
		links = {},
		costs = {},
		jumps = {},
		solids = solids,
		tx = tx,
		tz = tz,
		tiles = tiles,
		best = {},
		from = {},
		stamp = {},
		marks = table.create(#solids, 0),
		searches = 0,
	}
	fileSolids(nav)
	local seen: { number } = table.create(#solids, 0)
	local stamp = 0
	local done = 0

	-- Each column's nodes: the tops under the box it could stand on, each
	-- with nothing in the way from a step over its footing to its head, the
	-- margin round it included; but in the margin, something low enough to
	-- jump onto is only a ledge beside it.
	local xs, ys, zs, ci, cj = nav.xs, nav.ys, nav.zs, nav.ci, nav.cj
	for i = 1, nx do
		for j = 1, nz do
			done += 1
			if pause and done % BATCH == 0 then
				pause()
			end
			local x, z = x0 + (i - 0.5) * C, z0 + (j - 0.5) * C
			if not options.columns(x, z) then
				continue
			end
			stamp += 1
			local tops: { number } = {}
			local floors: { Solid } = {}
			for _, s in near(nav, seen, stamp, x - h, z - h, x + h, z + h) do
				if s.floor then
					table.insert(tops, topOver(s, x - h, z - h, x + h, z + h))
					table.insert(floors, s)
				end
			end
			if #tops == 0 then
				continue
			end
			table.sort(tops, function(a: number, b: number): boolean
				return a > b
			end)
			stamp += 1
			local around = near(nav, seen, stamp, x - h - m, z - h - m, x + h + m, z + h + m)
			local here: { number }? = nil
			local last = math.huge
			for _, y in tops do
				if last - y <= options.step then
					continue
				end
				local free = true
				for _, s in around do
					local top = topOver(s, x - h - m, z - h - m, x + h + m, z + h + m)
					if s.y0 < y + options.height and top > y + options.step then
						local ledge = s.floor
							and top <= y + options.climb
							and (s.x1 <= x - h or s.x0 >= x + h or s.z1 <= z - h or s.z0 >= z + h)
						if not ledge then
							free = false
							break
						end
					end
				end
				if free then
					-- An edge: nothing under the box's middle a step below its
					-- footing.
					local edge = true
					for _, s in floors do
						if s.x0 <= x and s.x1 >= x and s.z0 <= z and s.z1 >= z and topOver(s, x, z, x, z) >= y - options.step then
							edge = false
							break
						end
					end
					table.insert(xs, x)
					table.insert(ys, y)
					table.insert(zs, z)
					table.insert(ci, i)
					table.insert(cj, j)
					table.insert(nav.edges, edge)
					local list = here or {}
					if not here then
						nav.at[(j - 1) * nx + i] = list
						here = list
					end
					table.insert(list, #xs)
					last = y
				end
			end
		end
	end

	-- Each node's moves: a step across, diagonally only where both columns
	-- beside the way have footing near enough, a jump a metre more, and a
	-- drop only where nothing's in the way over the edge and down, a rail or
	-- the floor of a deck above where it would land.
	local function footing(i: number, j: number, y: number): boolean
		if i < 1 or i > nx or j < 1 or j > nz then
			return false
		end
		for _, other in nav.at[(j - 1) * nx + i] do
			if math.abs(ys[other] - y) <= options.step then
				return true
			end
		end
		return false
	end
	local function clearDrop(i: number, j: number, from: number, to: number): boolean
		local x, z = x0 + (i - 0.5) * C, z0 + (j - 0.5) * C
		stamp += 1
		for _, s in near(nav, seen, stamp, x - h, z - h, x + h, z + h) do
			if s.y0 < from + options.height and topOver(s, x - h, z - h, x + h, z + h) > to + options.step then
				return false
			end
		end
		return true
	end
	local first, links, costs, jumps = nav.first, nav.links, nav.costs, nav.jumps
	local diagonalCost = C * math.sqrt(2)
	for id = 1, #xs do
		if pause and id % BATCH == 0 then
			pause()
		end
		first[id] = #links + 1
		local ai, aj, ay = ci[id], cj[id], ys[id]
		for _, d in WAYS do
			local i, j = ai + d[1], aj + d[2]
			if i < 1 or i > nx or j < 1 or j > nz then
				continue
			end
			local diagonal = d[1] ~= 0 and d[2] ~= 0
			for _, other in nav.at[(j - 1) * nx + i] do
				local how = move(options, ay, ys[other])
				if how == nil then
					continue
				end
				if diagonal and not (footing(ai + d[1], aj, ay) and footing(ai, aj + d[2], ay)) then
					continue
				end
				if how == "drop" and not clearDrop(i, j, ay, ys[other]) then
					continue
				end
				table.insert(links, other)
				table.insert(
					costs,
					(if diagonal then diagonalCost else C)
						+ (if how == "jump" then BotNav.JUMP_COST else 0)
						+ (if nav.edges[other] then BotNav.EDGE_COST else 0)
				)
				table.insert(jumps, how == "jump")
			end
		end
	end
	first[#xs + 1] = #links + 1
	local n = #xs
	nav.best = table.create(n, math.huge)
	nav.from = table.create(n, 0)
	nav.stamp = table.create(n, 0)
	return nav
end

function BotNav.count(nav: Nav): number
	return #nav.xs
end

-- Node n's feet.
function BotNav.feet(nav: Nav, n: number): vector
	return vector.create(nav.xs[n], nav.ys[n], nav.zs[n])
end

-- The column (i, j) holding the point (x, z).
function BotNav.columnOf(nav: Nav, x: number, z: number): (number, number)
	local C = nav.options.cell
	return math.floor((x - nav.x0) / C) + 1, math.floor((z - nav.z0) / C) + 1
end

-- The node nearest feet at p: in the column holding it if it has one near
-- its height, else in the columns round it out to `reach` columns away (2
-- if not given), weighing height twice; nil if there's none.
function BotNav.nodeAt(nav: Nav, p: vector, reach: number?): number?
	local ci, cj = BotNav.columnOf(nav, p.x, p.z)
	local best: number? = nil
	local bestScore = math.huge
	local r = reach or 2
	for ring = 0, r do
		for i = ci - ring, ci + ring do
			for j = cj - ring, cj + ring do
				if math.max(math.abs(i - ci), math.abs(j - cj)) ~= ring then
					continue
				end
				if i < 1 or i > nav.nx or j < 1 or j > nav.nz then
					continue
				end
				for _, id in nav.at[(j - 1) * nav.nx + i] do
					local dx, dy, dz = nav.xs[id] - p.x, nav.ys[id] - p.y, nav.zs[id] - p.z
					if math.abs(dy) > 2 then
						continue
					end
					local score = dx * dx + dz * dz + 4 * dy * dy
					if score < bestScore then
						best, bestScore = id, score
					end
				end
			end
		end
		-- A node in a nearer ring is nearer than any further out, near enough.
		if best and ring >= 1 then
			break
		end
	end
	return best
end

-- A binary heap of nodes by key, in two arrays.
type Heap = { keys: { number }, ids: { number }, n: number }

local function push(heap: Heap, key: number, id: number)
	local keys, ids = heap.keys, heap.ids
	local k = heap.n + 1
	heap.n = k
	while k > 1 do
		local parent = k // 2
		if keys[parent] <= key then
			break
		end
		keys[k], ids[k] = keys[parent], ids[parent]
		k = parent
	end
	keys[k], ids[k] = key, id
end

local function pop(heap: Heap): (number, number)
	local keys, ids = heap.keys, heap.ids
	local topKey, topId = keys[1], ids[1]
	local n = heap.n
	local lastKey, lastId = keys[n], ids[n]
	n -= 1
	heap.n = n
	if n > 0 then
		local k = 1
		while true do
			local l = 2 * k
			if l > n then
				break
			end
			local r = l + 1
			local c = if r <= n and keys[r] < keys[l] then r else l
			if keys[c] >= lastKey then
				break
			end
			keys[k], ids[k] = keys[c], ids[c]
			k = c
		end
		keys[k], ids[k] = lastKey, lastId
	end
	return topKey, topId
end

-- The way on foot from node `start` to node `goal`, the nodes in order
-- from start to goal, by A*: the shortest, with each node's `extra` cost
-- of going through it added if given (danger, a wish to keep away from
-- somewhere). Nil if the goal is out of reach, or if more than `budget`
-- nodes (all of them if not given) are looked at first.
function BotNav.path(nav: Nav, start: number, goal: number, extra: ((number) -> number)?, budget: number?): { number }?
	nav.searches += 1
	local search = nav.searches
	local best, from, stamp = nav.best, nav.from, nav.stamp
	local xs, zs = nav.xs, nav.zs
	local gx, gz = xs[goal], zs[goal]
	local first, links, costs = nav.first, nav.links, nav.costs
	local heap: Heap = { keys = {}, ids = {}, n = 0 }
	best[start], from[start], stamp[start] = 0, 0, search
	push(heap, math.sqrt((xs[start] - gx) ^ 2 + (zs[start] - gz) ^ 2), start)
	local looked = 0
	local most = budget or math.huge
	while heap.n > 0 do
		local key, id = pop(heap)
		if id == goal then
			local out = {}
			local at = goal
			while at ~= 0 do
				table.insert(out, at)
				at = from[at]
			end
			-- Reversed, start first.
			local n = #out
			for k = 1, n // 2 do
				out[k], out[n - k + 1] = out[n - k + 1], out[k]
			end
			return out
		end
		local g = best[id]
		-- A stale entry: this node's been reached more cheaply since.
		if key - math.sqrt((xs[id] - gx) ^ 2 + (zs[id] - gz) ^ 2) > g + 1e-9 then
			continue
		end
		looked += 1
		if looked > most then
			return nil
		end
		for k = first[id], first[id + 1] - 1 do
			local other = links[k]
			local cost = g + costs[k] + (if extra then extra(other) else 0)
			if stamp[other] ~= search or cost < best[other] then
				stamp[other] = search
				best[other] = cost
				from[other] = id
				push(heap, cost + math.sqrt((xs[other] - gx) ^ 2 + (zs[other] - gz) ^ 2), other)
			end
		end
	end
	return nil
end

-- How far each node is on foot from the nodes `from` (or, backward, to
-- them), in metres along the floor; math.huge for out of reach.
function BotNav.distances(nav: Nav, from: { number }, backward: boolean?): { number }
	local n = #nav.xs
	local dist: { number } = table.create(n, math.huge)
	local first, links, costs = nav.first, nav.links, nav.costs
	-- Backward, the moves into each node.
	local inFirst: { number }, inLinks: { number }, inCosts: { number } = first, links, costs
	if backward then
		local counts = table.create(n + 1, 0)
		for id = 1, n do
			for k = first[id], first[id + 1] - 1 do
				counts[links[k]] += 1
			end
		end
		inFirst = table.create(n + 1, 0)
		local total = 1
		for id = 1, n do
			inFirst[id] = total
			total += counts[id]
		end
		inFirst[n + 1] = total
		inLinks = table.create(total - 1, 0)
		inCosts = table.create(total - 1, 0)
		local fill = table.clone(inFirst)
		for id = 1, n do
			for k = first[id], first[id + 1] - 1 do
				local to = links[k]
				inLinks[fill[to]] = id
				inCosts[fill[to]] = costs[k]
				fill[to] += 1
			end
		end
	end
	local heap: Heap = { keys = {}, ids = {}, n = 0 }
	for _, id in from do
		dist[id] = 0
		push(heap, 0, id)
	end
	while heap.n > 0 do
		local d, id = pop(heap)
		if d > dist[id] then
			continue
		end
		for k = inFirst[id], inFirst[id + 1] - 1 do
			local other = inLinks[k]
			local nd = d + inCosts[k]
			if nd < dist[other] then
				dist[other] = nd
				push(heap, nd, other)
			end
		end
	end
	return dist
end

-- Whether the box walks straight from node a to node b with its feet on
-- the floor all the way: each column the line crosses has footing within
-- a step of the last, and no jump on the way.
function BotNav.straight(nav: Nav, a: number, b: number): boolean
	local ax, az, bx, bz = nav.xs[a], nav.zs[a], nav.xs[b], nav.zs[b]
	local length = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
	local C = nav.options.cell
	local steps = math.max(math.ceil(length / (C * 0.5)), 1)
	local y = nav.ys[a]
	local step = nav.options.step
	for k = 1, steps do
		local t = k / steps
		local x, z = ax + (bx - ax) * t, az + (bz - az) * t
		local i, j = BotNav.columnOf(nav, x, z)
		if i < 1 or i > nav.nx or j < 1 or j > nav.nz then
			return false
		end
		local found: number? = nil
		for _, id in nav.at[(j - 1) * nav.nx + i] do
			if math.abs(nav.ys[id] - y) <= step then
				found = id
				break
			end
		end
		if not found then
			return false
		end
		y = nav.ys[found]
	end
	return math.abs(y - nav.ys[b]) <= step
end

-- The part [t0, t1] of a segment, from p along v, inside the slab from lo
-- to hi along one axis, narrowed from what it was; nil once it's empty.
local function clip(p: number, v: number, lo: number, hi: number, t0: number, t1: number): (number?, number)
	if math.abs(v) < 1e-12 then
		if p <= lo or p >= hi then
			return nil, t1
		end
		return t0, t1
	end
	local ta, tb = (lo - p) / v, (hi - p) / v
	if ta > tb then
		ta, tb = tb, ta
	end
	t0, t1 = math.max(t0, ta), math.min(t1, tb)
	if t0 >= t1 then
		return nil, t1
	end
	return t0, t1
end

-- Whether the segment from a to b passes through a solid: a box's, or the
-- part of a wedge's box under its slope.
function BotNav.hits(s: Solid, a: vector, b: vector): boolean
	local d = b - a
	local t0: number?, t1 = clip(a.x, d.x, s.x0, s.x1, 0, 1)
	if t0 == nil then
		return false
	end
	t0, t1 = clip(a.z, d.z, s.z0, s.z1, t0, t1)
	if t0 == nil then
		return false
	end
	t0, t1 = clip(a.y, d.y, s.y0, s.y1, t0, t1)
	if t0 == nil then
		return false
	end
	local rise = s.rise
	if rise == nil then
		return true
	end
	-- Under the slope: y less than its height there, which is linear along
	-- the segment, so it clips the span to one side of where they meet.
	local p, q = a + d * t0, a + d * t1
	return BotNav.heightOf(s, p.x, p.z) > p.y or BotNav.heightOf(s, q.x, q.z) > q.y
end

-- Whether an eye at a sees the point b: no solid an eye can't see through
-- between them, looked for in the tiles the line crosses, in order.
function BotNav.sees(nav: Nav, a: vector, b: vector): boolean
	nav.searches += 1
	local search = nav.searches
	local marks = nav.marks
	local solids = nav.solids
	local dx, dz = b.x - a.x, b.z - a.z
	local a0, b0 = tileOf(nav, a.x, a.z)
	local a1, b1 = tileOf(nav, b.x, b.z)
	local stepA = if dx > 0 then 1 elseif dx < 0 then -1 else 0
	local stepB = if dz > 0 then 1 elseif dz < 0 then -1 else 0
	-- Grid traversal (Amanatides and Woo): how far along the line the next
	-- tile edge each way is, and how far between edges.
	local function edge(p: number, origin: number, tile: number, s: number): number
		return origin + (tile + (if s > 0 then 1 else 0)) * TILE - p
	end
	local tMaxA = if stepA ~= 0 then edge(a.x, nav.x0, a0, stepA) / dx else math.huge
	local tMaxB = if stepB ~= 0 then edge(a.z, nav.z0, b0, stepB) / dz else math.huge
	local tDeltaA = if stepA ~= 0 then TILE / math.abs(dx) else math.huge
	local tDeltaB = if stepB ~= 0 then TILE / math.abs(dz) else math.huge
	local ta, tb = a0, b0
	while true do
		for _, id in nav.tiles[tb * nav.tx + ta + 1] do
			if marks[id] ~= search then
				marks[id] = search
				local s = solids[id]
				if s.sight and BotNav.hits(s, a, b) then
					return false
				end
			end
		end
		if ta == a1 and tb == b1 then
			break
		end
		if tMaxA < tMaxB then
			if tMaxA > 1 then
				break
			end
			ta += stepA
			tMaxA += tDeltaA
		else
			if tMaxB > 1 then
				break
			end
			tb += stepB
			tMaxB += tDeltaB
		end
		if ta < 0 or ta >= nav.tx or tb < 0 or tb >= nav.tz then
			break
		end
	end
	return true
end

-- A spike map's ------------------------------------------------------------------------

local built: { [any]: Nav } = {}

-- The solids of a spike map's parts, as the server builds them with the
-- spawn barriers down: floors, decks, flights, cover and railings are
-- somewhere to stand, a wall only low down, and solid dressing is in the
-- way overhead. A tree's leaves are in an eye's way, and nothing else's.
function BotNav.mapSolids(map: any): { Solid }
	local solids: { Solid } = {}
	for _, part in map.parts() do
		local kind = part.kind
		if kind == "floor" or kind == "deck" or kind == "flight" or kind == "cover" or kind == "rail" then
			table.insert(solids, BotNav.solidOf(part, true, true, true))
		elseif kind == "wall" then
			table.insert(solids, BotNav.solidOf(part, part.center.y + part.size.y / 2 < SILL, true, true))
		elseif kind == "dressing" then
			local style = MapKit.Styles[part.style or ""]
			if style and style.solid then
				table.insert(solids, BotNav.solidOf(part, false, true, true))
			end
		end
	end
	for _, c in map.cover() do
		if c.piece ~= "Tree" then
			continue
		end
		local size = vector.create(c.sx, map.Heights[c.height].value, c.sz)
		local reach, y0, y1 = 0, math.huge, -math.huge
		for _, bit in MapKit.bits("Tree", size, MapKit.lookOf("Tree", c.name, c.look)) do
			if bit.name == "Leaves" then
				reach = math.max(reach, math.sqrt(bit.offset.x ^ 2 + bit.offset.z ^ 2) + bit.size.x / 2)
				y0 = math.min(y0, bit.offset.y - bit.size.y / 2)
				y1 = math.max(y1, bit.offset.y + bit.size.y / 2)
			end
		end
		if reach > 0 then
			local planted = map.floorAt(c.x, c.z) or 0
			table.insert(solids, {
				x0 = c.x - reach,
				y0 = planted + y0,
				z0 = c.z - reach,
				x1 = c.x + reach,
				y1 = planted + y1,
				z1 = c.z + reach,
				floor = false,
				body = false,
				sight = true,
			})
		end
	end
	return solids
end

-- The options every map's built with: the player's box standing, and the
-- grid's cell.
function BotNav.options(columns: (x: number, z: number) -> boolean): Options
	local cfg = MovementConfig.resolve()
	return {
		cell = BotNav.CELL,
		half = cfg.halfWidth,
		margin = 0.1,
		height = cfg.standHeight,
		step = cfg.stepHeight,
		climb = BotNav.CLIMB,
		columns = columns,
	}
end

-- A spike map's nav, built once: footing on the map's floor, and in its
-- windows to climb through.
function BotNav.ofMap(map: any, pause: (() -> ())?): Nav
	local known = built[map]
	if known then
		return known
	end
	local windows = map.Windows or {}
	local function columns(x: number, z: number): boolean
		if map.onFloor(x, z) then
			return true
		end
		for _, w in windows do
			if x >= w.x0 and x <= w.x1 and z >= w.z0 and z <= w.z1 then
				return true
			end
		end
		return false
	end
	local x0, z0, x1, z1 = map.bounds()
	local nav = BotNav.new(BotNav.mapSolids(map), x0, z0, x1, z1, BotNav.options(columns), pause)
	built[map] = nav
	return nav
end

-- Whether a spike map's nav has been built.
function BotNav.isBuilt(map: any): boolean
	return built[map] ~= nil
end

-- The arena's (Skirmish and gun game) -------------------------------------------------

-- The solids of the arena's parts (ArenaLayout's): its floors and cover
-- somewhere to stand, its walls in the way, and its barriers down.
function BotNav.arenaSolids(parts: { any }): { Solid }
	local solids: { Solid } = {}
	for _, part in parts do
		local kind = part.kind
		if kind == "floor" or kind == "cover" then
			table.insert(solids, BotNav.solidOf(part, true, true, true))
		elseif kind == "wall" then
			table.insert(solids, BotNav.solidOf(part, part.center.y + part.size.y / 2 < SILL, true, true))
		end
	end
	return solids
end

-- An arena map's nav, from its parts and the rectangle they're in, built
-- once under `key`.
function BotNav.ofParts(key: string, parts: { any }, x0: number, z0: number, x1: number, z1: number, pause: (() -> ())?): Nav
	local known = built[key]
	if known then
		return known
	end
	local nav = BotNav.new(
		BotNav.arenaSolids(parts),
		x0,
		z0,
		x1,
		z1,
		BotNav.options(function()
			return true
		end),
		pause
	)
	built[key] = nav
	return nav
end

return BotNav
