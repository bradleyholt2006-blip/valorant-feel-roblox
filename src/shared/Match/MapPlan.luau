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

-- Same status convention as MovementConfig.
export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

export type Kind = "floor" | "wall" | "cover" | "barrier" | "marking"
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
}

-- Where a player spawns: their feet, and the camera yaw that faces out.
export type Spot = { feet: vector, yaw: number }

-- A rectangle of floor, from (x0, z0) to (x1, z1), and the name of its
-- mirror image on the other side, if the map has one made for it.
export type Room = { name: string, x0: number, z0: number, x1: number, z1: number, mirror: string? }

-- A piece of cover: its centre, its size across (x) and along (z), and how
-- tall it is.
export type Cover = { name: string, x: number, z: number, sx: number, sz: number, height: "low" | "high", mirror: string? }

-- A site's plant area: its centre on the floor and its size across and
-- along. Each of the reference's maps marks out its own.
export type Site = { site: string, x: number, z: number, sx: number, sz: number }

-- A site's plant area, the same shape as Spike.Zone.
export type Zone = { site: string, center: vector, half: vector, yaw: number }

export type Plan = { wallHeight: Param, barrierThickness: Param, spotSpacing: Param }
export type Heights = { low: Param, high: Param }

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
	rooms: () -> { Room },
	room: (name: string) -> Room?,
	cover: () -> { Cover },
	bounds: () -> (number, number, number, number),
	onFloor: (x: number, z: number) -> boolean,
	zones: () -> { Zone },
	spots: (role: Role) -> { Spot },
	parts: () -> { Part },
}

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local MapPlan = {}

-- What every map shares.
MapPlan.Plan = {
	wallHeight = p(5, "estimate", "Metres. Far above a jump (0.85 m), so nobody sees or gets over"),
	barrierThickness = p(0.2, "estimate", "Metres. Each spawn's barriers, across its doors during the buy phase"),
	spotSpacing = p(2, "estimate", "Metres between spawn spots, five a side"),
} :: Plan

-- Cover either shows your head with your eye above it, standing, and hides
-- you crouched, or hides a standing head, as in the arena.
MapPlan.Heights = {
	low = p(1.3, "estimate", "Crates you crouch behind and stand to shoot over"),
	high = p(2.0, "estimate", "Crates that hide a standing player"),
} :: Heights

function MapPlan.new(def: Def): Map
	local P = MapPlan.Plan

	-- Every room and piece of cover, the mirrored partners included.
	local allRooms: { Room } = {}
	for _, room in def.rooms do
		table.insert(allRooms, room)
		if room.mirror then
			table.insert(allRooms, { name = room.mirror :: string, x0 = -room.x1, z0 = room.z0, x1 = -room.x0, z1 = room.z1 })
		end
	end
	local allCover: { Cover } = {}
	for _, c in def.cover do
		table.insert(allCover, c)
		if c.mirror then
			table.insert(allCover, { name = c.mirror :: string, x = -c.x, z = c.z, sx = c.sx, sz = c.sz, height = c.height })
		end
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

	-- The wall: every 1 m cell of the outline that isn't floor, merged into
	-- as few blocks as a sweep finds (along x first, then as far along z as
	-- the same run goes).
	local function wallBlocks(): { { x0: number, z0: number, x1: number, z1: number } }
		local bx0, bz0, bx1, bz1 = bounds()
		local nx, nz = bx1 - bx0, bz1 - bz0
		local solid: { { boolean } } = {}
		for i = 1, nx do
			local column = {}
			for j = 1, nz do
				column[j] = not onFloor(bx0 + i - 0.5, bz0 + j - 0.5)
			end
			solid[i] = column
		end
		local blocks = {}
		for j = 1, nz do
			for i = 1, nx do
				if solid[i][j] then
					local i1 = i
					while i1 + 1 <= nx and solid[i1 + 1][j] do
						i1 += 1
					end
					local j1 = j
					local function rowFull(row: number): boolean
						for k = i, i1 do
							if not solid[k][row] then
								return false
							end
						end
						return true
					end
					while j1 + 1 <= nz and rowFull(j1 + 1) do
						j1 += 1
					end
					for k = i, i1 do
						for l = j, j1 do
							solid[k][l] = false
						end
					end
					table.insert(blocks, { x0 = bx0 + i - 1, z0 = bz0 + j - 1, x1 = bx0 + i1, z1 = bz0 + j1 })
				end
			end
		end
		return blocks
	end

	-- Every part of the map, in metres from its centre.
	local function parts(): { Part }
		local wallH = P.wallHeight.value
		local out: { Part } = {}
		local function add(name: string, kind: Kind, center: vector, size: vector, role: Role?, site: string?)
			table.insert(out, { name = name, kind = kind, center = center, size = size, yaw = 0, role = role, site = site })
		end

		local bx0, bz0, bx1, bz1 = bounds()
		add("Floor", "floor", vector.create((bx0 + bx1) / 2, -0.5, (bz0 + bz1) / 2), vector.create(bx1 - bx0, 1, bz1 - bz0))
		for _, b in wallBlocks() do
			add(
				"Wall",
				"wall",
				vector.create((b.x0 + b.x1) / 2, wallH / 2, (b.z0 + b.z1) / 2),
				vector.create(b.x1 - b.x0, wallH, b.z1 - b.z0)
			)
		end
		for _, c in allCover do
			local h = MapPlan.Heights[c.height].value
			add(c.name, "cover", vector.create(c.x, h / 2, c.z), vector.create(c.sx, h, c.sz))
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
