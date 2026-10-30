--!strict
-- The 1v1 map (system 64): built by hand in the place, not in code as the
-- arena's maps and the spike maps are. It's Workspace's 1v1Map, a folder or
-- model of parts, with each side's spawn room a model named Spawn1 or Spawn2
-- whose floor is a part named Floor (or failing that its widest part).
-- Side 1 spawns in Spawn1. Everything else is read from the parts as they
-- stand, so the map can be moved, rebuilt or redressed with no change here:
--   * each side's spawn spots, in the middle of its room's floor, facing
--     its door
--   * each room's door, the gap in the wall along the room's edge nearest
--     the other room, where its barrier stands for each buy phase
--   * the parts the bots find their way by (BotNav.ofParts, as the arena's)
--   * the floor's height, which the minimap's plan of the map is drawn from
--     (PartsPlan)
-- Spots, parts and heights are in metres in the place, as the map has no
-- origin of its own.
--
-- The client only reads the floor's height; the rest is the server's.

local Workspace = game:GetService("Workspace")

local Units = require(script.Parent.Parent.Units)

local DuelMap = {}

-- Workspace's child the map is in, the mode's name (ArenaConfig.MODE) and
-- its map's (the arena model's Map attribute), what the HUD and the log
-- call it, and the name of the barriers the server puts in its doors (as
-- Minimap.BARRIER, which sight goes through).
DuelMap.ROOT = "1v1Map"
DuelMap.KEY = "duel"
DuelMap.NAME = "1v1"
DuelMap.BARRIER = "Barrier"
DuelMap.ROOMS = { "Spawn1", "Spawn2" }

export type Spot = { feet: vector, yaw: number } -- as ArenaLayout.Spot
export type Door = { cframe: CFrame, size: Vector3 } -- studs: the barrier's part
export type Part = { name: string, kind: string, center: vector, size: vector, yaw: number } -- as ArenaLayout.Part
export type Rect = { x0: number, z0: number, x1: number, z1: number }
export type Info = {
	root: Instance,
	ground: number, -- the top of the spawn rooms' floors
	spots: { [number]: { Spot } }, -- by side
	doors: { [number]: { Door } }, -- by side
	parts: { Part },
	hall: Rect, -- the widest floor, where the fights are
	bounds: Rect, -- every part
}

local M = Units.METRES_PER_STUD
-- Studs, ours: how finely a room's edge is looked along for its door, how
-- far either side of the edge the wall is looked for, from how high off the
-- floor to how high a gap is a way through (a crouch fits under 1.25 m), and
-- how tall a door is with nothing over it.
local STEP = 0.5
local SEARCH = 3
local LOW, HIGH = 1, 6
local OPEN_DOOR = 12
local HIGHEST = 30
-- Metres, ours, for the bots' parts: a part whose bottom is this far over
-- the floor is overhead (a door's lintel); one whose top is this near the
-- floor and wider than this is floor; one this tall and long is a wall.
local OVERHEAD = 2
local FLAT, WIDE = 0.05, 4
local TALL, LONG = 2.5, 3

-- The map, if the place has one.
function DuelMap.root(): Instance?
	return Workspace:FindFirstChild(DuelMap.ROOT)
end

-- A spawn room's floor: its part named Floor, or its widest part.
local function floorOf(room: Instance): BasePart?
	local best: BasePart?, most = nil, -1
	for _, d in room:GetDescendants() do
		if d:IsA("BasePart") then
			local area = d.Size.X * d.Size.Z + (if d.Name == "Floor" then 1e9 else 0)
			if area > most then
				best, most = d, area
			end
		end
	end
	return best
end

local function topOf(part: BasePart): number
	return part.Position.Y + part.Size.Y / 2
end

-- The spawn rooms' floors, by side, or nil without both.
local function floors(root: Instance): { BasePart }?
	local out: { BasePart } = {}
	for side, name in DuelMap.ROOMS do
		local room = root:FindFirstChild(name, true)
		local floor = if room then floorOf(room) else nil
		if not floor then
			return nil
		end
		out[side] = floor
	end
	return out
end

-- The height of the map's floor (metres), as the spawn rooms have it, or nil
-- without them. The client's minimap plan is drawn from here.
function DuelMap.ground(root: Instance): number?
	local f = floors(root)
	return if f then topOf(f[1]) * M else nil
end

-- How far a part reaches from its middle along each of the world's axes
-- (studs), however it's turned.
local function reachOf(cf: CFrame, size: Vector3): Vector3
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local h = size / 2
	return Vector3.new(
		math.abs(r.X) * h.X + math.abs(u.X) * h.Y + math.abs(l.X) * h.Z,
		math.abs(r.Y) * h.X + math.abs(u.Y) * h.Y + math.abs(l.Y) * h.Z,
		math.abs(r.Z) * h.X + math.abs(u.Z) * h.Y + math.abs(l.Z) * h.Z
	)
end

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-6 then f.Unit else Vector3.zero
end

-- The doors of the room whose floor is `floor` (studs): along whichever of
-- the floor's edges faces `toward`, the wall standing nearest that edge,
-- and in it each gap a player fits through, as tall as it's open over its
-- middle. With no wall there, the whole edge.
local function doorsOf(floor: BasePart, toward: Vector3, params: OverlapParams): { Door }
	local cf, size = floor.CFrame, floor.Size
	local top = topOf(floor)
	local centre = Vector3.new(cf.Position.X, top, cf.Position.Z)
	local aim = flat(toward - centre)
	local out, across, depth, width = Vector3.xAxis, Vector3.zAxis, 0, 0
	local best = -math.huge
	local edges = {
		{ axis = cf.RightVector, extent = size.X, side = cf.LookVector, sideExtent = size.Z },
		{ axis = cf.LookVector, extent = size.Z, side = cf.RightVector, sideExtent = size.X },
	}
	for _, e in edges do
		for _, sign in { 1, -1 } do
			local axis = flat(e.axis) * sign
			local d = axis:Dot(aim)
			if d > best then
				best, out, depth, across, width = d, axis, e.extent / 2, flat(e.side), e.sideExtent / 2
			end
		end
	end

	-- A barrier already up is no wall.
	local probe = Vector3.new(0.2, 0.2, 0.2)
	local function blocked(at: Vector3): boolean
		for _, part in Workspace:GetPartBoundsInBox(CFrame.new(at), probe, params) do
			if part.Name ~= DuelMap.BARRIER then
				return true
			end
		end
		return false
	end
	local function point(t: number, u: number, y: number): Vector3
		return centre + out * t + across * u + Vector3.yAxis * y
	end

	-- The wall: the plane across the edge that's most solid.
	local plane, solid = depth, 0
	for t = depth - SEARCH, depth + SEARCH + 1e-6, STEP do
		local n = 0
		for u = -width + STEP / 2, width - STEP / 2 + 1e-6, STEP do
			for y = LOW, HIGH + 1e-6, 1.5 do
				if blocked(point(t, u, y)) then
					n += 1
				end
			end
		end
		if n > solid or (n == solid and n > 0 and math.abs(t - depth) < math.abs(plane - depth)) then
			plane, solid = t, n
		end
	end

	-- The gaps in it, as runs of open columns.
	local runs: { { number } } = {}
	local start: number? = nil
	local last = -width
	for u = -width + STEP / 2, width - STEP / 2 + 1e-6, STEP do
		local open = true
		for y = LOW, HIGH + 1e-6, 1 do
			if blocked(point(plane, u, y)) then
				open = false
				break
			end
		end
		if open then
			start = start or u
			last = u
		elseif start then
			table.insert(runs, { start, last })
			start = nil
		end
	end
	if start then
		table.insert(runs, { start, last })
	end

	local doors: { Door } = {}
	for _, run in runs do
		local u0, u1 = run[1] - STEP / 2, run[2] + STEP / 2
		if u1 - u0 < 2 then
			continue -- too narrow to walk through
		end
		local mid = (u0 + u1) / 2
		local height = OPEN_DOOR
		for y = LOW, HIGHEST, STEP do
			if blocked(point(plane, mid, y)) then
				height = y - STEP / 2
				break
			end
		end
		local at = point(plane, mid, height / 2)
		table.insert(doors, {
			cframe = CFrame.fromMatrix(at, across, Vector3.yAxis),
			size = Vector3.new(u1 - u0, height, 1),
		})
	end
	return doors
end

-- A part as the bots know it (metres), or nil for one over their heads.
local function partOf(d: BasePart, ground: number): Part?
	local cf, size = d.CFrame, d.Size
	local upright = math.abs(cf.UpVector.Y) >= 0.999
	local box, yaw = size, 0
	if upright then
		local _, y = cf:ToEulerAnglesYXZ()
		yaw = y
	else
		box = reachOf(cf, size) * 2
	end
	local bottom, top = (cf.Position.Y - box.Y / 2) * M, (cf.Position.Y + box.Y / 2) * M
	if bottom >= ground + OVERHEAD then
		return nil
	end
	local w, l = box.X * M, box.Z * M
	local kind = "cover"
	if math.abs(top - ground) <= FLAT and w * l >= WIDE then
		kind = "floor"
	elseif top - ground >= TALL and math.max(w, l) >= LONG then
		kind = "wall"
	end
	return { name = d.Name, kind = kind, center = Units.toMetres(cf.Position), size = Units.toMetres(box), yaw = yaw }
end

local cached: Info? = nil

-- Everything the server plays the map by, read once from its parts as they
-- stand, before any barrier's in them. Nil without the map, or without
-- both spawn rooms.
function DuelMap.read(): Info?
	local root = DuelMap.root()
	if not root then
		return nil
	end
	local known = cached
	if known and known.root == root then
		return known
	end
	local f = floors(root)
	if not f then
		return nil
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { root }
	params.RespectCanCollide = true

	local ground = topOf(f[1]) * M
	local spots: { [number]: { Spot } } = {}
	local doors: { [number]: { Door } } = {}
	for side, floor in f do
		local other = f[3 - side]
		local found = doorsOf(floor, other.Position, params)
		doors[side] = found
		local top = topOf(floor)
		local centre = Vector3.new(floor.Position.X, top, floor.Position.Z)
		-- Facing the door, or the other room without one.
		local facing = if #found > 0 then found[1].cframe.Position else other.Position
		local look = flat(facing - centre)
		local yaw = math.atan2(-look.X, -look.Z)
		local across = Vector3.new(-look.Z, 0, look.X)
		local list: { Spot } = {}
		-- The middle first: the 1v1's one spot. More in case of more a side.
		for _, offset in { Vector3.zero, across * 3.5, -across * 3.5, -look * 4.5 } do
			table.insert(list, { feet = Units.toMetres(centre + offset), yaw = yaw })
		end
		spots[side] = list
	end

	local parts: { Part } = {}
	local hall: Rect = { x0 = 0, z0 = 0, x1 = 0, z1 = 0 }
	local bounds: Rect = { x0 = math.huge, z0 = math.huge, x1 = -math.huge, z1 = -math.huge }
	local widest = -1
	for _, d in root:GetDescendants() do
		local part = if d:IsA("BasePart") and d.CanCollide and d.Name ~= DuelMap.BARRIER then partOf(d, ground) else nil
		if not part then
			continue
		end
		table.insert(parts, part)
		local c, s = part.center, part.size
		local hx = (math.abs(math.cos(part.yaw)) * s.x + math.abs(math.sin(part.yaw)) * s.z) / 2
		local hz = (math.abs(math.sin(part.yaw)) * s.x + math.abs(math.cos(part.yaw)) * s.z) / 2
		bounds.x0, bounds.x1 = math.min(bounds.x0, c.x - hx), math.max(bounds.x1, c.x + hx)
		bounds.z0, bounds.z1 = math.min(bounds.z0, c.z - hz), math.max(bounds.z1, c.z + hz)
		if part.kind == "floor" and 4 * hx * hz > widest then
			widest = 4 * hx * hz
			hall = { x0 = c.x - hx, z0 = c.z - hz, x1 = c.x + hx, z1 = c.z + hz }
		end
	end

	local info: Info = { root = root, ground = ground, spots = spots, doors = doors, parts = parts, hall = hall, bounds = bounds }
	cached = info
	return info
end

-- Each side's spawn spots, or none without the map.
function DuelMap.spots(side: number): { Spot }
	local info = DuelMap.read()
	return if info then info.spots[side] or {} else {}
end

return DuelMap
