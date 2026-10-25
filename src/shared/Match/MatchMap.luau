--!strict
-- The map the spike rounds are played on (system 13): Outpost, a compact
-- two-site map of our own, for 1v1 to 3v3. The reference's maps are built
-- for 5v5 and none is published at a scale we could build from, so this one
-- follows their pattern instead: the attackers' spawn at one end and the
-- defenders' at the other, site A on the attackers' left and B on their
-- right, each reached by a main from the attackers' side, by a link from
-- mid, and from the defenders' spawn, which is nearer both sites than the
-- attackers' is. Mirrored left to right, so neither site is the easy one.
--
-- Plain data and maths in metres, y up, from the map's centre: the floor is
-- a list of rooms, rectangles on a 1 m grid, and everything else inside the
-- outline is wall, built as a few big blocks. The server builds
-- MatchMap.parts() at MatchMap.origin, and the offline tests check it (every
-- room reachable, every gap wider than a player, no sightline from one spawn
-- into the other, barriers that hold each side in). The attackers spawn at
-- +z and face -z, the defenders at -z.

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
-- mirror image on the other side, if it isn't its own.
export type Room = { name: string, x0: number, z0: number, x1: number, z1: number, mirror: string? }

-- A piece of cover: its centre, its size across (x) and along (z), and how
-- tall it is.
export type Cover = { name: string, x: number, z: number, sx: number, sz: number, height: "low" | "high", mirror: string? }

-- A site's plant area, the same shape as Spike.Zone.
export type Zone = { site: string, center: vector, half: vector, yaw: number }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local MatchMap = {}

MatchMap.NAME = "Outpost"
-- The key of its sites in Spike.Layouts.
MatchMap.LAYOUT = "outpost"

-- Where the map's centre is in the place, in metres: off to the course's
-- left (-x, seen from its spawn), well clear of the wallbang lane.
MatchMap.origin = vector.create(-150, 0, 0)

MatchMap.Plan = {
	wallHeight = p(5, "estimate", "Metres. Far above a jump (0.85 m), so nobody sees or gets over"),
	barrierThickness = p(0.2, "estimate", "Metres. Each spawn's barriers, across its doors during the buy phase"),
	spotSpacing = p(2, "estimate", "Metres between spawn spots, five a side"),
	siteWidth = p(12, "estimate", "Metres across each site's plant area; each of the reference's maps marks out its own"),
	siteDepth = p(10, "estimate", "Metres along each site's plant area"),
}

-- Cover either shows your head with your eye above it, standing, and hides
-- you crouched, or hides a standing head, as in the arena.
MatchMap.Heights = {
	low = p(1.3, "estimate", "Crates you crouch behind and stand to shoot over"),
	high = p(2.0, "estimate", "Crates that hide a standing player"),
}

-- The rooms in the middle, each its own mirror image, then those on A's side,
-- each with its partner on B's.
MatchMap.Rooms = {
	{ name = "AttackerSpawn", x0 = -7, z0 = 26, x1 = 7, z1 = 36 },
	{ name = "AttackerDoorMid", x0 = -2, z0 = 24, x1 = 2, z1 = 26 },
	{ name = "MidBottom", x0 = -6, z0 = 12, x1 = 6, z1 = 24 },
	{ name = "MidSouth", x0 = -3, z0 = 5, x1 = 3, z1 = 12 },
	{ name = "MidNorth", x0 = -3, z0 = -3, x1 = 3, z1 = 0 },
	{ name = "MidTop", x0 = -4, z0 = -18, x1 = 4, z1 = -8 },
	{ name = "DefenderDoorMid", x0 = -2, z0 = -20, x1 = 2, z1 = -18 },
	{ name = "DefenderSpawn", x0 = -7, z0 = -30, x1 = 7, z1 = -20 },

	{ name = "AttackerDoorA", x0 = -9, z0 = 28, x1 = -7, z1 = 32, mirror = "AttackerDoorB" },
	{ name = "ALobby", x0 = -30, z0 = 27, x1 = -9, z1 = 33, mirror = "BLobby" },
	{ name = "AMain", x0 = -30, z0 = 8, x1 = -24, z1 = 27, mirror = "BMain" },
	{ name = "AChoke", x0 = -30, z0 = 4, x1 = -26, z1 = 8, mirror = "BChoke" },
	{ name = "ASite", x0 = -32, z0 = -14, x1 = -14, z1 = 4, mirror = "BSite" },
	{ name = "ALink", x0 = -14, z0 = -8, x1 = -6, z1 = -3, mirror = "BLink" },
	{ name = "MidA", x0 = -6, z0 = -8, x1 = -3, z1 = 12, mirror = "MidB" },
	{ name = "MidLaneA", x0 = -3, z0 = -8, x1 = -1, z1 = -3, mirror = "MidLaneB" },
	{ name = "DefenderDoorA", x0 = -9, z0 = -27, x1 = -7, z1 = -23, mirror = "DefenderDoorB" },
	{ name = "ABackHall", x0 = -22, z0 = -28, x1 = -9, z1 = -22, mirror = "BBackHall" },
	{ name = "ABack", x0 = -22, z0 = -22, x1 = -16, z1 = -14, mirror = "BBack" },
} :: { Room }

-- Cover on A's side, each with its partner on B's. The block in the middle
-- of mid is the space between MidNorth, MidSouth, MidA and MidB, and the
-- pillar north of it, between the two lanes, stands where the links meet,
-- so neither site sees into the other: both wall.
MatchMap.Cover = {
	{ name = "ADefault", x = -23, z = -5, sx = 2, sz = 2, height = "high", mirror = "BDefault" },
	{ name = "AFront", x = -20, z = 1.5, sx = 3, sz = 1.2, height = "low", mirror = "BFront" },
	{ name = "ABackBox", x = -29, z = -12, sx = 2, sz = 2, height = "high", mirror = "BBackBox" },
	{ name = "AStackHigh", x = -16, z = -12, sx = 2, sz = 2, height = "high", mirror = "BStackHigh" },
	{ name = "AStackLow", x = -18, z = -12, sx = 2, sz = 2, height = "low", mirror = "BStackLow" },
	{ name = "ALinkCrate", x = -16, z = -1, sx = 2, sz = 1.2, height = "low", mirror = "BLinkCrate" },
	{ name = "AMainCrate", x = -29, z = 18, sx = 2, sz = 2, height = "low", mirror = "BMainCrate" },
	{ name = "ALobbyCrate", x = -18, z = 30, sx = 2, sz = 2, height = "high", mirror = "BLobbyCrate" },
	{ name = "MidCrateA", x = -5, z = 18, sx = 2, sz = 2, height = "low", mirror = "MidCrateB" },
} :: { Cover }

-- Each spawn's doors, where its barriers stand: the door rooms above.
MatchMap.Doors = {
	attack = { "AttackerDoorMid", "AttackerDoorA", "AttackerDoorB" },
	defend = { "DefenderDoorMid", "DefenderDoorA", "DefenderDoorB" },
} :: { [Role]: { string } }

-- Where the spike lies at the start of each round: "dropped in front of the
-- Attackers" (the VALORANT Wiki, Spike; community), between their spawn
-- spots and their door to mid.
MatchMap.spikeStart = vector.create(0, 0, 29)

local function mirrored(room: Room): Room
	return { name = room.mirror :: string, x0 = -room.x1, z0 = room.z0, x1 = -room.x0, z1 = room.z1 }
end

-- Every room, B's side included.
function MatchMap.rooms(): { Room }
	local out: { Room } = {}
	for _, room in MatchMap.Rooms do
		table.insert(out, room)
		if room.mirror then
			table.insert(out, mirrored(room))
		end
	end
	return out
end

function MatchMap.room(name: string): Room?
	for _, room in MatchMap.rooms() do
		if room.name == name then
			return room
		end
	end
	return nil
end

-- Every piece of cover, B's side included.
function MatchMap.cover(): { Cover }
	local out: { Cover } = {}
	for _, c in MatchMap.Cover do
		table.insert(out, c)
		if c.mirror then
			table.insert(out, { name = c.mirror :: string, x = -c.x, z = c.z, sx = c.sx, sz = c.sz, height = c.height })
		end
	end
	return out
end

-- The outline everything is inside: the rooms' extent and a 1 m wall round
-- it.
function MatchMap.bounds(): (number, number, number, number)
	local x0, z0, x1, z1 = math.huge, math.huge, -math.huge, -math.huge
	for _, room in MatchMap.rooms() do
		x0, z0 = math.min(x0, room.x0), math.min(z0, room.z0)
		x1, z1 = math.max(x1, room.x1), math.max(z1, room.z1)
	end
	return x0 - 1, z0 - 1, x1 + 1, z1 + 1
end

-- Whether the point (x, z) is on the floor of some room.
function MatchMap.onFloor(x: number, z: number): boolean
	for _, room in MatchMap.rooms() do
		if x >= room.x0 and x <= room.x1 and z >= room.z0 and z <= room.z1 then
			return true
		end
	end
	return false
end

-- The sites' plant areas, in the map's own metres (MatchMap.zones adds the
-- origin).
local function localZones(): { Zone }
	local P = MatchMap.Plan
	local half = vector.create(P.siteWidth.value / 2, 1, P.siteDepth.value / 2)
	local a = MatchMap.room("ASite") :: Room
	local center = vector.create((a.x0 + a.x1) / 2, 1, (a.z0 + a.z1) / 2)
	return {
		{ site = "A", center = center, half = half, yaw = 0 },
		{ site = "B", center = vector.create(-center.x, center.y, center.z), half = half, yaw = 0 },
	}
end

-- The sites' plant areas where the map stands in the place, for the spike.
function MatchMap.zones(): { Zone }
	local out: { Zone } = {}
	for _, zone in localZones() do
		table.insert(out, { site = zone.site, center = zone.center + MatchMap.origin, half = zone.half, yaw = zone.yaw })
	end
	return out
end

-- Each spawn's spots, five in a row facing out: the first for whoever joined
-- that side first.
function MatchMap.spots(role: Role): { Spot }
	local spacing = MatchMap.Plan.spotSpacing.value
	local room = MatchMap.room(if role == "attack" then "AttackerSpawn" else "DefenderSpawn") :: Room
	-- Three quarters of the way to the back wall, away from the doors.
	local z = if role == "attack" then room.z0 + (room.z1 - room.z0) * 0.7 else room.z1 - (room.z1 - room.z0) * 0.7
	local out: { Spot } = {}
	for _, k in { 0, -1, 1, -2, 2 } do
		table.insert(out, { feet = vector.create(k * spacing, 0, z), yaw = if role == "attack" then 0 else math.pi })
	end
	return out
end

-- The wall: every 1 m cell of the outline that isn't floor, merged into as
-- few blocks as a sweep finds (along x first, then as far along z as the
-- same run goes).
local function wallBlocks(): { { x0: number, z0: number, x1: number, z1: number } }
	local bx0, bz0, bx1, bz1 = MatchMap.bounds()
	local nx, nz = bx1 - bx0, bz1 - bz0
	local solid: { { boolean } } = {}
	for i = 1, nx do
		local column = {}
		for j = 1, nz do
			column[j] = not MatchMap.onFloor(bx0 + i - 0.5, bz0 + j - 0.5)
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
function MatchMap.parts(): { Part }
	local P = MatchMap.Plan
	local wallH = P.wallHeight.value
	local out: { Part } = {}
	local function add(name: string, kind: Kind, center: vector, size: vector, role: Role?, site: string?)
		table.insert(out, { name = name, kind = kind, center = center, size = size, yaw = 0, role = role, site = site })
	end

	local bx0, bz0, bx1, bz1 = MatchMap.bounds()
	add("Floor", "floor", vector.create((bx0 + bx1) / 2, -0.5, (bz0 + bz1) / 2), vector.create(bx1 - bx0, 1, bz1 - bz0))
	for _, b in wallBlocks() do
		add("Wall", "wall", vector.create((b.x0 + b.x1) / 2, wallH / 2, (b.z0 + b.z1) / 2), vector.create(b.x1 - b.x0, wallH, b.z1 - b.z0))
	end
	for _, c in MatchMap.cover() do
		local h = MatchMap.Heights[c.height].value
		add(c.name, "cover", vector.create(c.x, h / 2, c.z), vector.create(c.sx, h, c.sz))
	end

	-- Each spawn's barriers, across the middle of each door, and its floor.
	local bt = P.barrierThickness.value
	local function spawnParts(role: Role)
		for _, name in MatchMap.Doors[role] do
			local door = MatchMap.room(name) :: Room
			local cx, cz = (door.x0 + door.x1) / 2, (door.z0 + door.z1) / 2
			local w, d = door.x1 - door.x0, door.z1 - door.z0
			-- A door is wider than it is deep: the barrier runs across it.
			local size = if w >= d then vector.create(w, wallH, bt) else vector.create(bt, wallH, d)
			add("Barrier", "barrier", vector.create(cx, wallH / 2, cz), size, role)
		end
		local spawn = MatchMap.room(if role == "attack" then "AttackerSpawn" else "DefenderSpawn") :: Room
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

return MatchMap
