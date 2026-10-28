--!strict
-- A map's floors in three dimensions, for the offline tests (system 59):
-- where a player's box can stand, how they get about on foot (walking, up
-- a step or a slope, jumping up a little, dropping down), how far that is,
-- and what an eye can see. Built from solids, boxes and the wedges of
-- ramps, as the server builds the place, on a grid of columns: each column
-- holds a node for each height the box can stand at there, its footing
-- the highest top under it.

local MapKit = require("../src/shared/Match/MapKit")
local MovementConfig = require("../src/shared/Movement/MovementConfig")

local Levels = {}

-- A solid from (x0, y0, z0) to (x1, y1, z1). A wedge's top slopes from y0
-- at its foot up to y1 at its head, toward `rise`. Whether its top is
-- somewhere to stand.
export type Solid = {
	x0: number,
	y0: number,
	z0: number,
	x1: number,
	y1: number,
	z1: number,
	rise: string?,
	floor: boolean,
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

export type Node = { i: number, j: number, x: number, z: number, y: number }

export type Level = {
	options: Options,
	x0: number,
	z0: number,
	nx: number,
	nz: number,
	nodes: { Node },
	at: { { number } }, -- each column's nodes' ids, by column index
	solids: { Solid },
}

local TILE = 4

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
function Levels.heightOf(s: Solid, x: number, z: number): number
	return topOver(s, x, z, x, z)
end

-- A solid from a MapPlan part: its box, turned by its yaw if it's a wedge.
function Levels.solidOf(part: any, floor: boolean): Solid
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
		}
	end
	return {
		x0 = c.x - size.x / 2,
		y0 = c.y - size.y / 2,
		z0 = c.z - size.z / 2,
		x1 = c.x + size.x / 2,
		y1 = c.y + size.y / 2,
		z1 = c.z + size.z / 2,
		floor = floor,
	}
end

-- The nodes of the solids over the rectangle from (x0, z0) to (x1, z1).
function Levels.new(solids: { Solid }, x0: number, z0: number, x1: number, z1: number, options: Options): Level
	local C, h, m = options.cell, options.half, options.margin
	local nx, nz = math.ceil((x1 - x0) / C), math.ceil((z1 - z0) / C)

	-- Each 4 m tile's solids.
	local tx, tz = math.ceil((x1 - x0) / TILE), math.ceil((z1 - z0) / TILE)
	local tiles: { { number } } = {}
	for k = 1, tx * tz do
		tiles[k] = {}
	end
	for id, s in solids do
		local a0 = math.clamp(math.floor((s.x0 - x0) / TILE), 0, tx - 1)
		local a1 = math.clamp(math.floor((s.x1 - x0) / TILE), 0, tx - 1)
		local b0 = math.clamp(math.floor((s.z0 - z0) / TILE), 0, tz - 1)
		local b1 = math.clamp(math.floor((s.z1 - z0) / TILE), 0, tz - 1)
		for a = a0, a1 do
			for b = b0, b1 do
				table.insert(tiles[b * tx + a + 1], id)
			end
		end
	end
	local seen: { number } = table.create(#solids, 0)
	local stamp = 0
	-- The solids over the rectangle, each once.
	local function near(ax: number, az: number, bx: number, bz: number): { Solid }
		stamp += 1
		local out = {}
		local a0 = math.clamp(math.floor((ax - x0) / TILE), 0, tx - 1)
		local a1 = math.clamp(math.floor((bx - x0) / TILE), 0, tx - 1)
		local b0 = math.clamp(math.floor((az - z0) / TILE), 0, tz - 1)
		local b1 = math.clamp(math.floor((bz - z0) / TILE), 0, tz - 1)
		for a = a0, a1 do
			for b = b0, b1 do
				for _, id in tiles[b * tx + a + 1] do
					if seen[id] ~= stamp then
						seen[id] = stamp
						local s = solids[id]
						if s.x0 < bx and s.x1 > ax and s.z0 < bz and s.z1 > az then
							table.insert(out, s)
						end
					end
				end
			end
		end
		return out
	end

	local nodes: { Node } = {}
	local at: { { number } } = table.create(nx * nz)
	for i = 1, nx do
		for j = 1, nz do
			local x, z = x0 + (i - 0.5) * C, z0 + (j - 0.5) * C
			local here: { number } = {}
			at[(j - 1) * nx + i] = here
			if not options.columns(x, z) then
				continue
			end
			-- What the box could stand on: the tops under it.
			local tops: { number } = {}
			for _, s in near(x - h, z - h, x + h, z + h) do
				if s.floor then
					table.insert(tops, topOver(s, x - h, z - h, x + h, z + h))
				end
			end
			table.sort(tops, function(a: number, b: number): boolean
				return a > b
			end)
			local around = near(x - h - m, z - h - m, x + h + m, z + h + m)
			local last = math.huge
			for _, y in tops do
				if last - y <= options.step then
					continue
				end
				-- Nothing in the way of the box, from a step over its footing
				-- to its head, with the margin round it; but in the margin,
				-- something low enough to jump onto is only a ledge beside it.
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
					table.insert(nodes, { i = i, j = j, x = x, z = z, y = y })
					table.insert(here, #nodes)
					last = y
				end
			end
		end
	end
	return { options = options, x0 = x0, z0 = z0, nx = nx, nz = nz, nodes = nodes, at = at, solids = solids }
end

-- The column (i, j) holding the point (x, z).
function Levels.columnOf(level: Level, x: number, z: number): (number, number)
	local C = level.options.cell
	return math.floor((x - level.x0) / C) + 1, math.floor((z - level.z0) / C) + 1
end

-- The node in the column holding (x, z) nearest the height y, if any.
function Levels.nodeAt(level: Level, x: number, z: number, y: number): number?
	local i, j = Levels.columnOf(level, x, z)
	if i < 1 or i > level.nx or j < 1 or j > level.nz then
		return nil
	end
	local best: number? = nil
	local bestGap = math.huge
	for _, id in level.at[(j - 1) * level.nx + i] do
		local gap = math.abs(level.nodes[id].y - y)
		if gap < bestGap then
			best, bestGap = id, gap
		end
	end
	return best
end

-- How the box gets from node a to the node b beside it on foot, if it can:
-- "walk" (level, or up or down a step), "jump" (up a little) or "drop".
function Levels.move(level: Level, a: Node, b: Node): string?
	local dy = b.y - a.y
	local o = level.options
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

-- The nodes beside node `id` it can move to (or, backward, that can move
-- to it), with how far: a step across, diagonally only where both columns
-- beside the way have footing near enough, and a jump a metre more.
local function neighbours(level: Level, id: number, backward: boolean, visit: (other: number, cost: number) -> ())
	local a = level.nodes[id]
	local C = level.options.cell
	local nx, nz = level.nx, level.nz
	local function footing(i: number, j: number, y: number): boolean
		if i < 1 or i > nx or j < 1 or j > nz then
			return false
		end
		for _, other in level.at[(j - 1) * nx + i] do
			if math.abs(level.nodes[other].y - y) <= level.options.step then
				return true
			end
		end
		return false
	end
	for _, d in WAYS do
		local i, j = a.i + d[1], a.j + d[2]
		if i < 1 or i > nx or j < 1 or j > nz then
			continue
		end
		local diagonal = d[1] ~= 0 and d[2] ~= 0
		for _, other in level.at[(j - 1) * nx + i] do
			local b = level.nodes[other]
			local how = if backward then Levels.move(level, b, a) else Levels.move(level, a, b)
			if how == nil then
				continue
			end
			if diagonal then
				local y = if backward then b.y else a.y
				if not (footing(a.i + d[1], a.j, y) and footing(a.i, a.j + d[2], y)) then
					continue
				end
			end
			visit(other, (if diagonal then C * math.sqrt(2) else C) + (if how == "jump" then 1 else 0))
		end
	end
end

-- How far each node is on foot from the nodes `from` (or, backward, to
-- them), in metres along the floor; math.huge for out of reach.
function Levels.distances(level: Level, from: { number }, backward: boolean?): { number }
	local dist: { number } = table.create(#level.nodes, math.huge)
	local heap: { { number } } = {}
	local function push(d: number, id: number)
		table.insert(heap, { d, id })
		local k = #heap
		while k > 1 do
			local parent = k // 2
			if heap[parent][1] <= heap[k][1] then
				break
			end
			heap[parent], heap[k] = heap[k], heap[parent]
			k = parent
		end
	end
	local function pop(): { number }
		local top = heap[1]
		local last = table.remove(heap) :: { number }
		if #heap > 0 then
			heap[1] = last
			local k = 1
			while true do
				local l, r = 2 * k, 2 * k + 1
				local smallest = k
				if l <= #heap and heap[l][1] < heap[smallest][1] then
					smallest = l
				end
				if r <= #heap and heap[r][1] < heap[smallest][1] then
					smallest = r
				end
				if smallest == k then
					break
				end
				heap[smallest], heap[k] = heap[k], heap[smallest]
				k = smallest
			end
		end
		return top
	end
	for _, id in from do
		dist[id] = 0
		push(0, id)
	end
	while #heap > 0 do
		local top = pop()
		local d, id = top[1], top[2]
		if d <= dist[id] then
			neighbours(level, id, backward == true, function(other: number, cost: number)
				local nd = d + cost
				if nd < dist[other] then
					dist[other] = nd
					push(nd, other)
				end
			end)
		end
	end
	return dist
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
function Levels.hits(s: Solid, a: vector, b: vector): boolean
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
	return Levels.heightOf(s, p.x, p.z) > p.y or Levels.heightOf(s, q.x, q.z) > q.y
end

-- Whether an eye at a sees b: no solid among `solids` between them.
function Levels.sees(solids: { Solid }, a: vector, b: vector): boolean
	for _, s in solids do
		if Levels.hits(s, a, b) then
			return false
		end
	end
	return true
end

-- A spike map's -------------------------------------------------------------------------

-- How high the box jumps up onto something (estimate): a little under the
-- jump's apex, 0.85 m, as it has to clear the edge on its way over.
Levels.CLIMB = 0.8
-- How high a wall's top is somewhere to stand: a window's sill.
local SILL = 2.5

local built: { [any]: Level } = {}
local runs: { [any]: { attack: { number }, defend: { number } } } = {}

-- A spike map's level, built once: its parts as the server builds them,
-- with the spawn barriers down, for the player's box standing. Its floors,
-- decks, flights, cover and railings are somewhere to stand, a wall only
-- low down, and solid dressing is in the way overhead.
function Levels.ofMap(map: any): Level
	local known = built[map]
	if known then
		return known
	end
	local cfg = MovementConfig.resolve()
	local solids: { Solid } = {}
	for _, part in map.parts() do
		local kind = part.kind
		if kind == "floor" or kind == "deck" or kind == "flight" or kind == "cover" or kind == "rail" then
			table.insert(solids, Levels.solidOf(part, true))
		elseif kind == "wall" then
			table.insert(solids, Levels.solidOf(part, part.center.y + part.size.y / 2 < SILL))
		elseif kind == "dressing" then
			local style = MapKit.Styles[part.style or ""]
			if style and style.solid then
				table.insert(solids, Levels.solidOf(part, false))
			end
		end
	end
	-- Footing on the map's floor, and in its windows to climb through.
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
	local level = Levels.new(solids, x0, z0, x1, z1, {
		cell = 0.25,
		half = cfg.halfWidth,
		margin = 0.1,
		height = cfg.standHeight,
		step = cfg.stepHeight,
		climb = Levels.CLIMB,
		columns = columns,
	})
	built[map] = level
	return level
end

-- How far a run it is on foot from each side's spawn to each node of a
-- spike map's level, in metres, worked out once: from where the side's
-- first player stands.
function Levels.runsOf(map: any): { attack: { number }, defend: { number } }
	local known = runs[map]
	if known then
		return known
	end
	local level = Levels.ofMap(map)
	local function from(role: string): { number }
		local feet = map.spots(role)[1].feet
		local id = Levels.nodeAt(level, feet.x, feet.z, feet.y)
		return if id then Levels.distances(level, { id }) else table.create(#level.nodes, math.huge)
	end
	local out = { attack = from("attack"), defend = from("defend") }
	runs[map] = out
	return out
end

return Levels
