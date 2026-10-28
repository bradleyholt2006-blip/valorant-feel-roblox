--!strict
-- A spike map's plan (system 25), as plain data and maths. Every map the
-- spike rounds are played on is one: Outpost (MatchMap), Quarry and Foundry
-- (SpikeMaps has them all), built and checked the same way.
--
-- In metres, y up, from the map's centre: the floor is a list of rooms,
-- rectangles on a 1 m grid, and everything else inside the outline is wall,
-- built as a few big blocks. Cover stands on the floor; each spawn's doors
-- are rooms of their own, where its barriers stand during the buy phase; and
-- each site has a plant area marked on its floor. The attackers spawn at +z,
-- in the room named AttackerSpawn, and face -z; the defenders at -z, in
-- DefenderSpawn. The server builds map.parts() at map.origin, and the
-- offline tests check each map (every room reachable, every gap wider than
-- a player, no sightline from one spawn into the other, barriers that hold
-- each side in, the defenders at each site first).
--
-- A map can be dressed too (system 58), as Wharf is: each room's floor in
-- the look of its zone, its cover as pieces of a kit (MapKit), roofs over
-- some rooms and a lintel over some doors, and dressing built over the
-- walls, all of it out of reach overhead. None of that changes where
-- anyone can go, see or shoot, which is the rooms', the walls' and the
-- cover's boxes alone, as on every map.
--
-- And a map can have heights (system 59), as Wharf does: a room raised off
-- the ground, a deck up over a room's floor that leaves the floor open
-- under it (a heaven over its hell), a flight of stairs or a ramp from one
-- floor up to another, a railing along a raised floor's edge where the
-- floor beyond drops away, and a window through a wall. A wall near a
-- raised floor rises with it, as high over it as the others are over the
-- ground.

-- Same status convention as MovementConfig.
export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

export type Kind = "floor" | "wall" | "cover" | "barrier" | "marking" | "dressing" | "deck" | "flight" | "rail"
-- Whose spawn a barrier or a spawn's floor belongs to.
export type Role = "attack" | "defend"
-- An edge of a rectangle, by the way it faces.
export type Side = "-x" | "+x" | "-z" | "+z"

export type Part = {
	name: string,
	kind: Kind,
	center: vector,
	size: vector,
	yaw: number, -- radians about y, as ArenaLayout's
	role: Role?, -- barriers and spawn floors: whose spawn
	site: string?, -- a site's floor: its letter
	zone: string?, -- a dressed map's floor and walls: their look (MapKit.Themes)
	piece: string?, -- cover dressed as a piece of the kit (MapKit.Pieces)
	look: number?, -- and which of the piece's looks
	style: string?, -- dressing: what it is (MapKit.Styles)
	text: string?, -- a sign's
	face: string?, -- a sign's: the way its text faces, "+x", "-x", "+z" or "-z"
	-- A flight's slope: a wedge, as Roblox's WedgePart, rising toward its
	-- yaw's +z, its size across, up and along that way.
	wedge: boolean?,
	hidden: boolean?, -- built unseen: the slope walked on under a flight of stairs' steps
}

-- Where a player spawns: their feet, and the camera yaw that faces out.
export type Spot = { feet: vector, yaw: number }

-- A rectangle of floor, from (x0, z0) to (x1, z1), and the name of its
-- mirror image on the other side, if the map has one made for it. On a
-- dressed map, its zone, and whether it has a roof or (a door) a lintel.
-- How high its floor is, if it's raised, and the sides of it with a
-- railing where the floor beyond drops away.
export type Room = {
	name: string,
	x0: number,
	z0: number,
	x1: number,
	z1: number,
	mirror: string?,
	zone: string?,
	roof: boolean?,
	lintel: boolean?,
	y: number?,
	rails: { Side }?,
}

-- A deck: a floor from (x0, z0) to (x1, z1) up at y, over a room's floor,
-- which stays open under it; its look, and the sides of it with a railing
-- where the floor beyond drops away.
export type Deck = { name: string, x0: number, z0: number, x1: number, z1: number, y: number, zone: string?, rails: { Side }? }

-- A flight: stairs, or else a ramp, from (x0, z0) to (x1, z1), climbing
-- toward `up` from y0 at its foot to y1 at its head; and its look.
export type Flight = {
	name: string,
	x0: number,
	z0: number,
	x1: number,
	z1: number,
	up: Side,
	y0: number,
	y1: number,
	stairs: boolean?,
	zone: string?,
}

-- A window: an opening through the wall's 1 m cells from (x0, z0) to
-- (x1, z1), from `sill` up to `top`.
export type Window = { name: string, x0: number, z0: number, x1: number, z1: number, sill: number, top: number }

export type Height = "low" | "high" | "tall"

-- A piece of cover: its centre, its size across (x) and along (z), and how
-- tall it is; on a dressed map, the piece of the kit it is and which of
-- its looks. It stands on the floor under its middle.
export type Cover = {
	name: string,
	x: number,
	z: number,
	sx: number,
	sz: number,
	height: Height,
	mirror: string?,
	piece: string?,
	look: number?,
}

-- A box of a dressed map's dressing, from (x0, y0, z0) to (x1, y1, z1), and
-- its style (MapKit.Styles); a sign's text and the way it faces.
export type Dressing = {
	name: string,
	style: string,
	x0: number,
	y0: number,
	z0: number,
	x1: number,
	y1: number,
	z1: number,
	text: string?,
	face: string?,
}

-- A site's plant area: its centre on the floor and its size across and
-- along. Each of the reference's maps marks out its own.
export type Site = { site: string, x: number, z: number, sx: number, sz: number }

-- A site's plant area, the same shape as Spike.Zone.
export type Zone = { site: string, center: vector, half: vector, yaw: number }

export type Plan = {
	wallHeight: Param,
	barrierThickness: Param,
	spotSpacing: Param,
	clearance: Param,
	wallReach: Param,
	slab: Param,
	railHeight: Param,
	railThickness: Param,
	drop: Param,
	stepRise: Param,
}
export type Heights = { low: Param, high: Param, tall: Param }

-- A map as it's written down. A room or a piece of cover with a `mirror`
-- has a partner of that name across x = 0, which the plan adds.
export type Def = {
	name: string,
	layout: string, -- the key of its sites in Spike.Layouts, and of the map in SpikeMaps
	origin: vector, -- where the map's centre is in the place, in metres
	rooms: { Room },
	cover: { Cover },
	doors: { [Role]: { string } }, -- each spawn's doors: rooms above
	sites: { Site },
	spikeStart: vector, -- where the spike lies at the start of each round
	dressing: { Dressing }?, -- a dressed map's, as well as its roofs and lintels
	decks: { Deck }?, -- and its heights (system 59)
	flights: { Flight }?,
	windows: { Window }?,
}

export type Map = {
	NAME: string,
	LAYOUT: string,
	origin: vector,
	Plan: Plan,
	Heights: Heights,
	Rooms: { Room },
	Cover: { Cover },
	Doors: { [Role]: { string } },
	Sites: { Site },
	spikeStart: vector,
	Dressing: { Dressing },
	Decks: { Deck },
	Flights: { Flight },
	Windows: { Window },
	dressed: boolean,
	raised: boolean,
	rooms: () -> { Room },
	room: (name: string) -> Room?,
	cover: () -> { Cover },
	bounds: () -> (number, number, number, number),
	onFloor: (x: number, z: number) -> boolean,
	floorAt: (x: number, z: number) -> number?,
	levelsAt: (x: number, z: number) -> { number },
	zones: () -> { Zone },
	spots: (role: Role) -> { Spot },
	parts: () -> { Part },
}

-- A block of cells, from (x0, z0) to (x1, z1), and what they share.
type Block = { x0: number, z0: number, x1: number, z1: number, key: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local MapPlan = {}

-- What every map shares.
MapPlan.Plan = {
	wallHeight = p(5, "estimate", "Metres over the floor near it. Far above a jump (0.85 m), so nobody sees or gets over"),
	barrierThickness = p(0.2, "estimate", "Metres. Each spawn's barriers, across its doors during the buy phase"),
	spotSpacing = p(2, "estimate", "Metres between spawn spots, five a side"),
	clearance = p(
		3.4,
		"estimate",
		"Metres: the lowest a dressed map's roofs and lintels come over the floor, above a jump (0.85 m) on a standing player (1.8 m)"
	),
	wallReach = p(4, "estimate", "Metres: a wall stands its height over the highest floor this near it, so a raised floor's walls rise"),
	slab = p(0.3, "estimate", "Metres: how thick a deck is"),
	railHeight = p(
		1.3,
		"estimate",
		"Metres: a railing's, as high as low cover, so a standing player shoots over it and a crouching one is hidden"
	),
	railThickness = p(0.2, "estimate", "Metres: a railing's, along the edge of the floor it stands on"),
	drop = p(0.5, "estimate", "Metres: a floor this far below the one beside it is a drop, more than a step (0.35 m) down"),
	stepRise = p(
		0.2,
		"estimate",
		"Metres: the most a step of stairs rises, under the movement's step up (0.35 m); its slope is what's walked on"
	),
} :: Plan

-- Cover either shows your head with your eye above it, standing, and hides
-- you crouched, or hides a standing head, as in the arena.
MapPlan.Heights = {
	low = p(1.3, "estimate", "Crates you crouch behind and stand to shoot over"),
	high = p(2.0, "estimate", "Crates that hide a standing player"),
	tall = p(2.6, "estimate", "Metres: a shipping container, 2.59 m high (ISO 668), on a dressed map"),
} :: Heights

local function inside(r: { x0: number, z0: number, x1: number, z1: number }, x: number, z: number): boolean
	return x >= r.x0 and x <= r.x1 and z >= r.z0 and z <= r.z1
end

-- How far up a flight (x, z) is: from 0 at its foot to 1 at its head.
local function climbed(f: Flight, x: number, z: number): number
	if f.up == "+x" then
		return (x - f.x0) / (f.x1 - f.x0)
	elseif f.up == "-x" then
		return (f.x1 - x) / (f.x1 - f.x0)
	elseif f.up == "+z" then
		return (z - f.z0) / (f.z1 - f.z0)
	end
	return (f.z1 - z) / (f.z1 - f.z0)
end

-- The yaw that turns a wedge's rise, along its +z, toward `side`.
local function yawOf(side: Side): number
	if side == "+x" then
		return math.pi / 2
	elseif side == "-x" then
		return -math.pi / 2
	elseif side == "-z" then
		return math.pi
	end
	return 0
end

-- The side a mirrored partner has where its own is `side`.
local function mirrored(side: Side): Side
	if side == "-x" then
		return "+x"
	elseif side == "+x" then
		return "-x"
	end
	return side
end

function MapPlan.new(def: Def): Map
	local P = MapPlan.Plan
	local dressing: { Dressing } = def.dressing or {}
	local decks: { Deck } = def.decks or {}
	local flights: { Flight } = def.flights or {}
	local windows: { Window } = def.windows or {}

	-- Every room and piece of cover, the mirrored partners included.
	local allRooms: { Room } = {}
	for _, room in def.rooms do
		table.insert(allRooms, room)
		if room.mirror then
			local rails: { Side }? = nil
			local sides = room.rails
			if sides then
				local flipped: { Side } = {}
				for _, side: Side in sides do
					table.insert(flipped, mirrored(side))
				end
				rails = flipped
			end
			table.insert(allRooms, {
				name = room.mirror :: string,
				x0 = -room.x1,
				z0 = room.z0,
				x1 = -room.x0,
				z1 = room.z1,
				zone = room.zone,
				roof = room.roof,
				lintel = room.lintel,
				y = room.y,
				rails = rails,
			})
		end
	end
	local allCover: { Cover } = {}
	for _, c in def.cover do
		table.insert(allCover, c)
		if c.mirror then
			table.insert(allCover, {
				name = c.mirror :: string,
				x = -c.x,
				z = c.z,
				sx = c.sx,
				sz = c.sz,
				height = c.height,
				piece = c.piece,
				look = c.look,
			})
		end
	end

	-- Whether any room has a zone: a dressed map. And whether it has any
	-- heights.
	local dressed = false
	local raised = #decks > 0 or #flights > 0 or #windows > 0
	for _, r in allRooms do
		dressed = dressed or r.zone ~= nil
		raised = raised or (r.y or 0) ~= 0
	end

	local function room(name: string): Room?
		for _, r in allRooms do
			if r.name == name then
				return r
			end
		end
		return nil
	end

	-- The outline everything is inside: the rooms' and the flights' extent
	-- and a 1 m wall round it.
	local function bounds(): (number, number, number, number)
		local x0, z0, x1, z1 = math.huge, math.huge, -math.huge, -math.huge
		for _, r in allRooms do
			x0, z0 = math.min(x0, r.x0), math.min(z0, r.z0)
			x1, z1 = math.max(x1, r.x1), math.max(z1, r.z1)
		end
		for _, f in flights do
			x0, z0 = math.min(x0, f.x0), math.min(z0, f.z0)
			x1, z1 = math.max(x1, f.x1), math.max(z1, f.z1)
		end
		return x0 - 1, z0 - 1, x1 + 1, z1 + 1
	end

	-- The room whose floor is at (x, z): of the rooms there, the one raised
	-- highest, as a platform stands in a bigger room; the first of them if
	-- they're as high. Nil off every room.
	local function roomAt(x: number, z: number): Room?
		local found: Room? = nil
		for _, r in allRooms do
			if inside(r, x, z) and (found == nil or (r.y or 0) > (found.y or 0)) then
				found = r
			end
		end
		return found
	end

	-- Whether the point (x, z) is on the floor of some room or flight.
	local function onFloor(x: number, z: number): boolean
		for _, r in allRooms do
			if inside(r, x, z) then
				return true
			end
		end
		for _, f in flights do
			if inside(f, x, z) then
				return true
			end
		end
		return false
	end

	-- How high the floor is at (x, z): a flight's slope there, or else its
	-- room's floor; nil off the floor.
	local function floorAt(x: number, z: number): number?
		for _, f in flights do
			if inside(f, x, z) then
				return f.y0 + (f.y1 - f.y0) * climbed(f, x, z)
			end
		end
		local r = roomAt(x, z)
		return if r then r.y or 0 else nil
	end

	-- Every height someone can stand at over (x, z), lowest first: the
	-- floor's, and any deck's over it.
	local function levelsAt(x: number, z: number): { number }
		local out: { number } = {}
		local ground = floorAt(x, z)
		if ground then
			table.insert(out, ground)
		end
		for _, d in decks do
			if inside(d, x, z) then
				table.insert(out, d.y)
			end
		end
		table.sort(out)
		return out
	end

	-- The highest of them, or nil off the floor.
	local function topAt(x: number, z: number): number?
		local levels = levelsAt(x, z)
		return levels[#levels]
	end

	-- The sites' plant areas in the map's own metres, from the floor to 2 m
	-- up (zones adds the origin).
	local function localZones(): { Zone }
		local out: { Zone } = {}
		for _, s in def.sites do
			local y = floorAt(s.x, s.z) or 0
			table.insert(
				out,
				{ site = s.site, center = vector.create(s.x, y + 1, s.z), half = vector.create(s.sx / 2, 1, s.sz / 2), yaw = 0 }
			)
		end
		return out
	end

	-- The sites' plant areas where the map stands in the place, for the
	-- spike.
	local function zones(): { Zone }
		local out: { Zone } = {}
		for _, zone in localZones() do
			table.insert(out, { site = zone.site, center = zone.center + def.origin, half = zone.half, yaw = zone.yaw })
		end
		return out
	end

	-- Each spawn's spots, five in a row across its middle, facing out: the
	-- first for whoever joined that side first.
	local function spots(role: Role): { Spot }
		local spacing = P.spotSpacing.value
		local spawn = room(if role == "attack" then "AttackerSpawn" else "DefenderSpawn") :: Room
		-- Three quarters of the way to the back wall, away from the doors.
		local z = if role == "attack" then spawn.z0 + (spawn.z1 - spawn.z0) * 0.7 else spawn.z1 - (spawn.z1 - spawn.z0) * 0.7
		local x = (spawn.x0 + spawn.x1) / 2
		local out: { Spot } = {}
		for _, k in { 0, -1, 1, -2, 2 } do
			table.insert(out, { feet = vector.create(x + k * spacing, spawn.y or 0, z), yaw = if role == "attack" then 0 else math.pi })
		end
		return out
	end

	-- The zone of the floor at (x, z) on a dressed map: a flight's, or else
	-- its room's there.
	local function zoneAt(x: number, z: number): string?
		local r = roomAt(x, z)
		local under: string? = if r then r.zone or "plain" else nil
		for _, f in flights do
			if inside(f, x, z) then
				return f.zone or under or "plain"
			end
		end
		return under
	end

	-- The 1 m cells of the outline, merged into as few blocks as a sweep
	-- finds (along x first, then as far along z as the same run goes), each
	-- of cells with the same key: `key` gives a cell's, by its middle, or
	-- nil for none.
	local function sweep(key: (x: number, z: number) -> string?): { Block }
		local bx0, bz0, bx1, bz1 = bounds()
		local nx, nz = bx1 - bx0, bz1 - bz0
		local keys: { { string | false } } = {}
		for i = 1, nx do
			local column: { string | false } = {}
			for j = 1, nz do
				column[j] = key(bx0 + i - 0.5, bz0 + j - 0.5) or false
			end
			keys[i] = column
		end
		local blocks: { Block } = {}
		for j = 1, nz do
			for i = 1, nx do
				local k = keys[i][j]
				if k ~= false then
					local i1 = i
					while i1 + 1 <= nx and keys[i1 + 1][j] == k do
						i1 += 1
					end
					local j1 = j
					local function rowFull(row: number): boolean
						for c = i, i1 do
							if keys[c][row] ~= k then
								return false
							end
						end
						return true
					end
					while j1 + 1 <= nz and rowFull(j1 + 1) do
						j1 += 1
					end
					for c = i, i1 do
						for l = j, j1 do
							keys[c][l] = false
						end
					end
					table.insert(blocks, { x0 = bx0 + i - 1, z0 = bz0 + j - 1, x1 = bx0 + i1, z1 = bz0 + j1, key = k :: string })
				end
			end
		end
		return blocks
	end

	-- How high the wall is in the 1 m cell whose middle is (x, z): the
	-- walls' height over the highest floor within wallReach of it, and so
	-- never lower than over the ground.
	local function wallHeights(): (x: number, z: number) -> number
		local wallH = P.wallHeight.value
		if not raised then
			return function(_x: number, _z: number): number
				return wallH
			end
		end
		local bx0, bz0, bx1, bz1 = bounds()
		local nx, nz = bx1 - bx0, bz1 - bz0
		local tops: { { number } } = {}
		for i = 1, nx do
			local column = {}
			for j = 1, nz do
				column[j] = topAt(bx0 + i - 0.5, bz0 + j - 0.5) or 0
			end
			tops[i] = column
		end
		local reach = math.floor(P.wallReach.value)
		local heights: { { number } } = {}
		for i = 1, nx do
			local column = {}
			for j = 1, nz do
				local top = 0
				for a = math.max(1, i - reach), math.min(nx, i + reach) do
					local near = tops[a]
					for b = math.max(1, j - reach), math.min(nz, j + reach) do
						top = math.max(top, near[b])
					end
				end
				column[j] = top + wallH
			end
			heights[i] = column
		end
		return function(x: number, z: number): number
			local i = math.clamp(math.floor(x - bx0) + 1, 1, nx)
			local j = math.clamp(math.floor(z - bz0) + 1, 1, nz)
			return heights[i][j]
		end
	end

	-- Every part of the map, in metres from its centre.
	local function parts(): { Part }
		local wallH = P.wallHeight.value
		local heightAt = wallHeights()
		local out: { Part } = {}
		local function add(name: string, kind: Kind, center: vector, size: vector, role: Role?, site: string?): Part
			local part: Part = { name = name, kind = kind, center = center, size = size, yaw = 0, role = role, site = site }
			table.insert(out, part)
			return part
		end
		-- A part from one corner to the other.
		local function block(name: string, kind: Kind, x0: number, y0: number, z0: number, x1: number, y1: number, z1: number): Part
			return add(name, kind, vector.create((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), vector.create(x1 - x0, y1 - y0, z1 - z0))
		end

		if dressed or raised then
			-- Each zone's own floor at each height, from a metre under the
			-- ground up: a raised room's stands on the ground.
			local looks: { [string]: { zone: string?, y: number } } = {}
			local function floorKey(x: number, z: number): string?
				local y: number? = nil
				for _, f in flights do
					if inside(f, x, z) then
						y = f.y0
						break
					end
				end
				if y == nil then
					local r = roomAt(x, z)
					y = if r then r.y or 0 else nil
				end
				if y == nil then
					return nil
				end
				local zone = if dressed then zoneAt(x, z) else nil
				local key = (zone or "") .. "@" .. tostring(y)
				looks[key] = { zone = zone, y = y }
				return key
			end
			for _, b in sweep(floorKey) do
				local look = looks[b.key]
				local floor = block("Floor", "floor", b.x0, -1, b.z0, b.x1, look.y, b.z1)
				floor.zone = look.zone
			end
		else
			local bx0, bz0, bx1, bz1 = bounds()
			add("Floor", "floor", vector.create((bx0 + bx1) / 2, -0.5, (bz0 + bz1) / 2), vector.create(bx1 - bx0, 1, bz1 - bz0))
		end

		-- The walls, each cell as high as the floor near it asks, and a
		-- window's cells built below its sill and above its top.
		local walls: { [string]: { height: number, window: Window? } } = {}
		local function wallKey(x: number, z: number): string?
			if onFloor(x, z) then
				return nil
			end
			local height = heightAt(x, z)
			local window: Window? = nil
			for _, w in windows do
				if inside(w, x, z) then
					window = w
					break
				end
			end
			local key = (if window then window.name else "") .. "@" .. tostring(height)
			walls[key] = { height = height, window = window }
			return key
		end
		local function wallPart(name: string, b: Block, y0: number, y1: number)
			local wall = block(name, "wall", b.x0, y0, b.z0, b.x1, y1, b.z1)
			wall.zone = if dressed then "wall" else nil
		end
		for _, b in sweep(wallKey) do
			local wall = walls[b.key]
			local window = wall.window
			if window then
				wallPart(window.name .. "Sill", b, 0, window.sill)
				wallPart(window.name .. "Head", b, window.top, wall.height)
			else
				wallPart("Wall", b, 0, wall.height)
			end
		end

		for _, c in allCover do
			local h = MapPlan.Heights[c.height].value
			local base = floorAt(c.x, c.z) or 0
			local part = add(c.name, "cover", vector.create(c.x, base + h / 2, c.z), vector.create(c.sx, h, c.sz))
			part.piece, part.look = c.piece, c.look
		end

		-- Each spawn's barriers, across the middle of each door, and its floor.
		local bt = P.barrierThickness.value
		local function spawnParts(role: Role)
			for _, name in def.doors[role] do
				local door = room(name) :: Room
				local cx, cz = (door.x0 + door.x1) / 2, (door.z0 + door.z1) / 2
				local w, d = door.x1 - door.x0, door.z1 - door.z0
				-- A door is wider than it is deep: the barrier runs across it.
				local size = if w >= d then vector.create(w, wallH, bt) else vector.create(bt, wallH, d)
				add("Barrier", "barrier", vector.create(cx, (door.y or 0) + wallH / 2, cz), size, role)
			end
			local spawn = room(if role == "attack" then "AttackerSpawn" else "DefenderSpawn") :: Room
			add(
				"SpawnFloor",
				"marking",
				vector.create((spawn.x0 + spawn.x1) / 2, (spawn.y or 0) + 0.005, (spawn.z0 + spawn.z1) / 2),
				vector.create(spawn.x1 - spawn.x0, 0.01, spawn.z1 - spawn.z0),
				role
			)
		end
		spawnParts("attack")
		spawnParts("defend")

		-- Each site's plant area, marked on the floor with its letter.
		for _, zone in localZones() do
			add(
				"Site" .. zone.site,
				"marking",
				vector.create(zone.center.x, zone.center.y - zone.half.y + 0.006, zone.center.z),
				vector.create(zone.half.x * 2, 0.01, zone.half.z * 2),
				nil,
				zone.site
			)
		end

		-- A dressed map's roofs, each with a light under it, its lintels and
		-- the rest of its dressing. A roof stands on the walls round its
		-- room and a lintel meets those beside its door.
		local function box(name: string, style: string, x0: number, y0: number, z0: number, x1: number, y1: number, z1: number): Part
			local part = block(name, "dressing", x0, y0, z0, x1, y1, z1)
			part.style = style
			return part
		end
		local function ringTop(r: Room): number
			local top = (r.y or 0) + wallH
			for x = r.x0 - 0.5, r.x1 + 0.5, 1 do
				for _, z in { r.z0 - 0.5, r.z1 + 0.5 } do
					if not onFloor(x, z) then
						top = math.max(top, heightAt(x, z))
					end
				end
			end
			for z = r.z0 + 0.5, r.z1 - 0.5, 1 do
				for _, x in { r.x0 - 0.5, r.x1 + 0.5 } do
					if not onFloor(x, z) then
						top = math.max(top, heightAt(x, z))
					end
				end
			end
			return top
		end
		for _, r in allRooms do
			if r.roof then
				local top = ringTop(r)
				box(r.name .. "Roof", "roof", r.x0 - 0.5, top, r.z0 - 0.5, r.x1 + 0.5, top + 0.4, r.z1 + 0.5)
				local cx, cz = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
				local along = r.x1 - r.x0 >= r.z1 - r.z0
				local reach = math.max(1, (if along then r.x1 - r.x0 else r.z1 - r.z0) - 2) / 2
				local wx, wz = if along then reach else 0.15, if along then 0.15 else reach
				box(r.name .. "Light", "light", cx - wx, top - 0.15, cz - wz, cx + wx, top, cz + wz)
			elseif r.lintel then
				box(r.name .. "Lintel", "lintel", r.x0, (r.y or 0) + P.clearance.value, r.z0, r.x1, ringTop(r), r.z1)
			end
		end
		for _, d in dressing do
			local part = box(d.name, d.style, d.x0, d.y0, d.z0, d.x1, d.y1, d.z1)
			part.text, part.face = d.text, d.face
		end

		-- The heights: each deck, each flight's slope, its steps if it's
		-- stairs, and the railings.
		for _, d in decks do
			local deck = block(d.name, "deck", d.x0, d.y - P.slab.value, d.z0, d.x1, d.y, d.z1)
			deck.zone = if dressed then d.zone or "deck" else nil
		end
		for _, f in flights do
			local alongX = f.up == "+x" or f.up == "-x"
			local across, run = if alongX then f.z1 - f.z0 else f.x1 - f.x0, if alongX then f.x1 - f.x0 else f.z1 - f.z0
			local slope = add(
				f.name,
				"flight",
				vector.create((f.x0 + f.x1) / 2, (f.y0 + f.y1) / 2, (f.z0 + f.z1) / 2),
				vector.create(across, f.y1 - f.y0, run)
			)
			slope.yaw = yawOf(f.up)
			slope.wedge = true
			slope.zone = if dressed then zoneAt((f.x0 + f.x1) / 2, (f.z0 + f.z1) / 2) else nil
			if f.stairs then
				slope.hidden = true
				-- Each step stands from the foot's floor up to its tread.
				local n = math.ceil((f.y1 - f.y0) / P.stepRise.value - 1e-9)
				local rise, tread = (f.y1 - f.y0) / n, run / n
				for k = 1, n do
					local a, b, top = (k - 1) * tread, k * tread, f.y0 + k * rise
					if f.up == "+x" then
						box(f.name .. "Step", "step", f.x0 + a, f.y0, f.z0, f.x0 + b, top, f.z1)
					elseif f.up == "-x" then
						box(f.name .. "Step", "step", f.x1 - b, f.y0, f.z0, f.x1 - a, top, f.z1)
					elseif f.up == "+z" then
						box(f.name .. "Step", "step", f.x0, f.y0, f.z0 + a, f.x1, top, f.z0 + b)
					else
						box(f.name .. "Step", "step", f.x0, f.y0, f.z1 - b, f.x1, top, f.z1 - a)
					end
				end
			end
		end

		-- A railing along each side a raised floor asks for, wherever the
		-- floor just beyond that side is a drop below it.
		local rh, rt, drop = P.railHeight.value, P.railThickness.value, P.drop.value
		local function railings(name: string, x0: number, z0: number, x1: number, z1: number, y: number, sides: { Side })
			for _, side in sides do
				local alongX = side == "-z" or side == "+z"
				local from, to = if alongX then x0 else z0, if alongX then x1 else z1
				local beyond = if side == "-x" then x0 - 0.5 elseif side == "+x" then x1 + 0.5 elseif side == "-z" then z0 - 0.5 else z1 + 0.5
				local start: number? = nil
				local function close(at: number)
					local s = start
					if s == nil then
						return
					end
					start = nil
					local rail
					if side == "-x" then
						rail = block(name .. "Rail", "rail", x0, y, s, x0 + rt, y + rh, at)
					elseif side == "+x" then
						rail = block(name .. "Rail", "rail", x1 - rt, y, s, x1, y + rh, at)
					elseif side == "-z" then
						rail = block(name .. "Rail", "rail", s, y, z0, at, y + rh, z0 + rt)
					else
						rail = block(name .. "Rail", "rail", s, y, z1 - rt, at, y + rh, z1)
					end
					rail.zone = if dressed then "rail" else nil
				end
				for k = from, to - 1 do
					local x, z = if alongX then k + 0.5 else beyond, if alongX then beyond else k + 0.5
					local top = topAt(x, z)
					if top ~= nil and top < y - drop then
						start = start or k
					else
						close(k)
					end
				end
				close(to)
			end
		end
		for _, r in allRooms do
			local sides = r.rails
			if sides then
				railings(r.name, r.x0, r.z0, r.x1, r.z1, r.y or 0, sides)
			end
		end
		for _, d in decks do
			local sides = d.rails
			if sides then
				railings(d.name, d.x0, d.z0, d.x1, d.z1, d.y, sides)
			end
		end
		return out
	end

	return {
		NAME = def.name,
		LAYOUT = def.layout,
		origin = def.origin,
		Plan = P,
		Heights = MapPlan.Heights,
		Rooms = def.rooms,
		Cover = def.cover,
		Doors = def.doors,
		Sites = def.sites,
		spikeStart = def.spikeStart,
		Dressing = dressing,
		Decks = decks,
		Flights = flights,
		Windows = windows,
		dressed = dressed,
		raised = raised,
		-- Every room, mirrored partners included.
		rooms = function(): { Room }
			return table.clone(allRooms)
		end,
		room = room,
		-- Every piece of cover, mirrored partners included.
		cover = function(): { Cover }
			return table.clone(allCover)
		end,
		bounds = bounds,
		onFloor = onFloor,
		floorAt = floorAt,
		levelsAt = levelsAt,
		zones = zones,
		spots = spots,
		parts = parts,
	}
end

return MapPlan
