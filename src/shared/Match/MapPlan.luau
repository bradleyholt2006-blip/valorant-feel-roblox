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

-- Same status convention as MovementConfig.
export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

export type Kind = "floor" | "wall" | "cover" | "barrier" | "marking" | "dressing"
-- Whose spawn a barrier or a spawn's floor belongs to.
export type Role = "attack" | "defend"

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
}

-- Where a player spawns: their feet, and the camera yaw that faces out.
export type Spot = { feet: vector, yaw: number }

-- A rectangle of floor, from (x0, z0) to (x1, z1), and the name of its
-- mirror image on the other side, if the map has one made for it. On a
-- dressed map, its zone, and whether it has a roof or (a door) a lintel.
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
}

export type Height = "low" | "high" | "tall"

-- A piece of cover: its centre, its size across (x) and along (z), and how
-- tall it is; on a dressed map, the piece of the kit it is and which of
-- its looks.
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

export type Plan = { wallHeight: Param, barrierThickness: Param, spotSpacing: Param, clearance: Param }
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
	dressed: boolean,
	rooms: () -> { Room },
	room: (name: string) -> Room?,
	cover: () -> { Cover },
	bounds: () -> (number, number, number, number),
	onFloor: (x: number, z: number) -> boolean,
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
	wallHeight = p(5, "estimate", "Metres. Far above a jump (0.85 m), so nobody sees or gets over"),
	barrierThickness = p(0.2, "estimate", "Metres. Each spawn's barriers, across its doors during the buy phase"),
	spotSpacing = p(2, "estimate", "Metres between spawn spots, five a side"),
	clearance = p(
		3.4,
		"estimate",
		"Metres: the lowest a dressed map's roofs and lintels come over the floor, above a jump (0.85 m) on a standing player (1.8 m)"
	),
} :: Plan

-- Cover either shows your head with your eye above it, standing, and hides
-- you crouched, or hides a standing head, as in the arena.
MapPlan.Heights = {
	low = p(1.3, "estimate", "Crates you crouch behind and stand to shoot over"),
	high = p(2.0, "estimate", "Crates that hide a standing player"),
	tall = p(2.6, "estimate", "Metres: a shipping container, 2.59 m high (ISO 668), on a dressed map"),
} :: Heights

function MapPlan.new(def: Def): Map
	local P = MapPlan.Plan
	local dressing: { Dressing } = def.dressing or {}

	-- Every room and piece of cover, the mirrored partners included.
	local allRooms: { Room } = {}
	for _, room in def.rooms do
		table.insert(allRooms, room)
		if room.mirror then
			table.insert(allRooms, {
				name = room.mirror :: string,
				x0 = -room.x1,
				z0 = room.z0,
				x1 = -room.x0,
				z1 = room.z1,
				zone = room.zone,
				roof = room.roof,
				lintel = room.lintel,
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

	-- Whether any room has a zone: a dressed map.
	local dressed = false
	for _, r in allRooms do
		dressed = dressed or r.zone ~= nil
	end

	local function room(name: string): Room?
		for _, r in allRooms do
			if r.name == name then
				return r
			end
		end
		return nil
	end

	-- The outline everything is inside: the rooms' extent and a 1 m wall
	-- round it.
	local function bounds(): (number, number, number, number)
		local x0, z0, x1, z1 = math.huge, math.huge, -math.huge, -math.huge
		for _, r in allRooms do
			x0, z0 = math.min(x0, r.x0), math.min(z0, r.z0)
			x1, z1 = math.max(x1, r.x1), math.max(z1, r.z1)
		end
		return x0 - 1, z0 - 1, x1 + 1, z1 + 1
	end

	-- Whether the point (x, z) is on the floor of some room.
	local function onFloor(x: number, z: number): boolean
		for _, r in allRooms do
			if x >= r.x0 and x <= r.x1 and z >= r.z0 and z <= r.z1 then
				return true
			end
		end
		return false
	end

	-- The sites' plant areas in the map's own metres, from the floor to 2 m
	-- up (zones adds the origin).
	local function localZones(): { Zone }
		local out: { Zone } = {}
		for _, s in def.sites do
			table.insert(out, { site = s.site, center = vector.create(s.x, 1, s.z), half = vector.create(s.sx / 2, 1, s.sz / 2), yaw = 0 })
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
			table.insert(out, { feet = vector.create(x + k * spacing, 0, z), yaw = if role == "attack" then 0 else math.pi })
		end
		return out
	end

	-- The zone of the floor at (x, z) on a dressed map: the first room's
	-- there.
	local function zoneAt(x: number, z: number): string?
		for _, r in allRooms do
			if x >= r.x0 and x <= r.x1 and z >= r.z0 and z <= r.z1 then
				return r.zone or "plain"
			end
		end
		return nil
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

	-- The wall: every cell that isn't floor.
	local function wallBlocks(): { Block }
		return sweep(function(x: number, z: number): string?
			return if onFloor(x, z) then nil else "wall"
		end)
	end

	-- Every part of the map, in metres from its centre.
	local function parts(): { Part }
		local wallH = P.wallHeight.value
		local out: { Part } = {}
		local function add(name: string, kind: Kind, center: vector, size: vector, role: Role?, site: string?): Part
			local part: Part = { name = name, kind = kind, center = center, size = size, yaw = 0, role = role, site = site }
			table.insert(out, part)
			return part
		end

		if dressed then
			-- A dressed map's floor is each zone's own.
			for _, b in sweep(zoneAt) do
				local floor = add(
					"Floor",
					"floor",
					vector.create((b.x0 + b.x1) / 2, -0.5, (b.z0 + b.z1) / 2),
					vector.create(b.x1 - b.x0, 1, b.z1 - b.z0)
				)
				floor.zone = b.key
			end
		else
			local bx0, bz0, bx1, bz1 = bounds()
			add("Floor", "floor", vector.create((bx0 + bx1) / 2, -0.5, (bz0 + bz1) / 2), vector.create(bx1 - bx0, 1, bz1 - bz0))
		end
		for _, b in wallBlocks() do
			local wall = add(
				"Wall",
				"wall",
				vector.create((b.x0 + b.x1) / 2, wallH / 2, (b.z0 + b.z1) / 2),
				vector.create(b.x1 - b.x0, wallH, b.z1 - b.z0)
			)
			wall.zone = if dressed then "wall" else nil
		end
		for _, c in allCover do
			local h = MapPlan.Heights[c.height].value
			local part = add(c.name, "cover", vector.create(c.x, h / 2, c.z), vector.create(c.sx, h, c.sz))
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
				add("Barrier", "barrier", vector.create(cx, wallH / 2, cz), size, role)
			end
			local spawn = room(if role == "attack" then "AttackerSpawn" else "DefenderSpawn") :: Room
			add(
				"SpawnFloor",
				"marking",
				vector.create((spawn.x0 + spawn.x1) / 2, 0.005, (spawn.z0 + spawn.z1) / 2),
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
				vector.create(zone.center.x, 0.006, zone.center.z),
				vector.create(zone.half.x * 2, 0.01, zone.half.z * 2),
				nil,
				zone.site
			)
		end

		-- A dressed map's roofs, each with a light under it, its lintels and
		-- the rest of its dressing.
		local function box(name: string, style: string, x0: number, y0: number, z0: number, x1: number, y1: number, z1: number): Part
			local part =
				add(name, "dressing", vector.create((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), vector.create(x1 - x0, y1 - y0, z1 - z0))
			part.style = style
			return part
		end
		for _, r in allRooms do
			if r.roof then
				box(r.name .. "Roof", "roof", r.x0 - 0.5, wallH, r.z0 - 0.5, r.x1 + 0.5, wallH + 0.4, r.z1 + 0.5)
				local cx, cz = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
				local along = r.x1 - r.x0 >= r.z1 - r.z0
				local reach = math.max(1, (if along then r.x1 - r.x0 else r.z1 - r.z0) - 2) / 2
				local wx, wz = if along then reach else 0.15, if along then 0.15 else reach
				box(r.name .. "Light", "light", cx - wx, wallH - 0.15, cz - wz, cx + wx, wallH, cz + wz)
			elseif r.lintel then
				box(r.name .. "Lintel", "lintel", r.x0, P.clearance.value, r.z0, r.x1, wallH, r.z1)
			end
		end
		for _, d in dressing do
			local part = box(d.name, d.style, d.x0, d.y0, d.z0, d.x1, d.y1, d.z1)
			part.text, part.face = d.text, d.face
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
		dressed = dressed,
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
		zones = zones,
		spots = spots,
		parts = parts,
	}
end

return MapPlan
