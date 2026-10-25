--!strict
-- The arena's map (system 7): a whitebox of Skirmish A, the reference's
-- Skirmish layout for 1v1 and 2v2 ('a tight central corridor with side
-- peeks', thespike.gg). Riot publishes only its minimap (in Sheep Esports'
-- article on the mode, credited to Riot), so the plan is measured from that
-- image, in fractions of the hall's width and length as measured, and one
-- number, the hall's width in metres, sets the scale. The minimap has no
-- heights, so every height is ours.
--
-- Two spawn rooms face each other down the long axis of a rectangular hall,
-- and the plan is the same seen from either end (it turns onto itself about
-- the centre), so neither side is favoured: only one of each pair of
-- obstacles is listed here, and its partner is made by turning it half way
-- round the centre.
--
-- Plain data and maths in metres, y up, from the centre of the hall's floor:
-- the server builds ArenaLayout.parts() at ArenaLayout.origin, and the
-- offline tests check them (inside the walls, room to move everywhere, no
-- sightline from one spawn to the other). Side 1 spawns at -z, side 2 at +z.

-- Same status convention as MovementConfig, plus one:
--   "measured" - ours, measured from a public source (here, the minimap's pixels)
export type Status = "confirmed" | "community" | "estimate" | "measured"
export type Param = { value: number, status: Status, source: string }

export type Kind = "floor" | "wall" | "cover" | "barrier" | "marking"

export type Part = {
	name: string,
	kind: Kind,
	center: vector,
	size: vector,
	yaw: number, -- radians about y (Roblox's sense: counterclockwise seen from above)
	side: number?, -- barriers and spawn markings: whose
}

-- Where a player spawns: their feet, and the camera yaw that faces the hall.
export type Spot = { feet: vector, yaw: number }

export type Rect = { min: vector, max: vector } -- on the floor (y ignored)

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local MINIMAP = "Riot's Skirmish A minimap (Sheep Esports, 'Riot Games unveils new Skirmish game mode at Champions 2025'), measured from its pixels"

local ArenaLayout = {}

-- Where the hall's centre is in the place, in metres: off to the course's
-- right (+x, seen from its spawn), with 50 m of empty space between them.
ArenaLayout.origin = vector.create(100, 0, 0)

ArenaLayout.Plan = {
	hallWidth = p(
		19,
		"estimate",
		"Metres across the hall. The minimap has no scale bar, doors or grid: this makes its small crates (0.086 of the width) 1.6 m across, our guess at the reference's crates"
	),
	length = p(1.32, "measured", "The hall's length over its width (286 x 378 px). " .. MINIMAP),
	roomWidth = p(0.245, "measured", "Each spawn room's width, as a share of the hall's width; it opens onto the hall across all of it. " .. MINIMAP),
	roomDepth = p(0.175, "measured", "Each spawn room's depth, as a share of the hall's length. " .. MINIMAP),
	chamfer = p(0.03, "measured", "The hall's corners are cut at 45 degrees, this share of its width along each wall. " .. MINIMAP),
	wallHeight = p(5, "estimate", "Metres. Far above a jump (0.85 m), so nobody sees or gets out"),
	wallThickness = p(1, "estimate", "Metres; outside the floor plan, so it changes nothing inside"),
	barrierThickness = p(0.2, "estimate", "Metres. The spawn barrier across each room's opening during the buy phase"),
	spotSpacing = p(2, "estimate", "Metres between the two spawn spots in each room (2v2)"),
}

-- Cover is either low enough to see over standing, with your head showing
-- (the head is 1.49 to 1.75 m up and the eye 1.62 m), and to hide behind
-- crouching (1.25 m tall), or tall enough to hide a standing head. Nothing
-- in between, where your head would show over cover your eye is behind.
ArenaLayout.Heights = {
	low = p(1.3, "estimate", "Crates you crouch behind and stand to shoot over. The minimap has no heights"),
	high = p(2.0, "estimate", "Crates that hide a standing player. The minimap has no heights"),
	centre = p(3.0, "estimate", "The centre block, the biggest piece. The minimap has no heights"),
}

export type Piece = {
	name: string,
	x: number, -- centre, across the width from the left wall, as a share of it
	y: number, -- centre, down the length from side 1's wall, as a share of it
	length: number, -- along the piece, as a share of the width
	depth: number, -- across it, as a share of the width
	tilt: number, -- degrees clockwise on the minimap (side 1 at the top)
	height: "low" | "high" | "centre",
	crates: number?, -- crates side by side along the piece (1 if nil)
}

-- One of each pair; the centre block is its own partner. Where the two of a
-- pair measured differently, the mean of the two: the second double crate's
-- tilt was 20 and 17 degrees, the second wall crate at y 0.34 and 0.35.
ArenaLayout.Pieces = {
	{ name = "CentreBlock", x = 0.50, y = 0.50, length = 0.16, depth = 0.16, tilt = 0, height = "centre" },
	{ name = "SideCrate", x = 0.21, y = 0.50, length = 0.086, depth = 0.086, tilt = 0, height = "low" },
	{ name = "DoubleCrate", x = 0.31, y = 0.19, length = 0.175, depth = 0.087, tilt = -20, height = "high", crates = 2 },
	{ name = "DoubleCrate", x = 0.65, y = 0.28, length = 0.175, depth = 0.087, tilt = 18.5, height = "high", crates = 2 },
	{ name = "WallCrate", x = 0.0425, y = 0.345, length = 0.085, depth = 0.085, tilt = 0, height = "low" },
	{ name = "WallCrate", x = 0.0425, y = 0.80, length = 0.085, depth = 0.085, tilt = 0, height = "low" },
} :: { Piece }
ArenaLayout.piecesStatus = "measured" :: Status
ArenaLayout.piecesSource = MINIMAP .. ". Each piece's partner is turned half way round the centre"

local P = ArenaLayout.Plan

-- Metres: the hall's width and length, and a spawn room's width and depth.
function ArenaLayout.size(): (number, number, number, number)
	local w = P.hallWidth.value
	local l = w * P.length.value
	return w, l, w * P.roomWidth.value, l * P.roomDepth.value
end

-- The same point turned half way round the hall's centre: the other side's
-- view of it.
function ArenaLayout.turned(v: vector): vector
	return vector.create(-v.x, v.y, -v.z)
end

-- The hall's floor and each side's room, as rectangles on the floor.
function ArenaLayout.hall(): Rect
	local w, l = ArenaLayout.size()
	return { min = vector.create(-w / 2, 0, -l / 2), max = vector.create(w / 2, 0, l / 2) }
end

function ArenaLayout.room(side: number): Rect
	local _, l, rw, rd = ArenaLayout.size()
	local back, mouth = vector.create(-rw / 2, 0, -l / 2 - rd), vector.create(rw / 2, 0, -l / 2)
	if side == 2 then
		return { min = ArenaLayout.turned(mouth), max = ArenaLayout.turned(back) }
	end
	return { min = back, max = mouth }
end

-- Each side's spawn spots, the first for whoever joined that side first.
function ArenaLayout.spots(side: number): { Spot }
	local _, l, _, rd = ArenaLayout.size()
	local half = P.spotSpacing.value / 2
	local out: { Spot } = {}
	for _, x in { -half, half } do
		local feet = vector.create(x, 0, -l / 2 - rd / 2)
		-- Side 1 looks down +z (yaw pi); side 2, turned round, down -z.
		table.insert(out, if side == 1 then { feet = feet, yaw = math.pi } else { feet = ArenaLayout.turned(feet), yaw = 0 })
	end
	return out
end

local function heightOf(piece: Piece): number
	return ArenaLayout.Heights[piece.height].value
end

-- Every part of the arena, in metres from the hall's centre.
function ArenaLayout.parts(): { Part }
	local w, l, rw, rd = ArenaLayout.size()
	local wallH, wallT = P.wallHeight.value, P.wallThickness.value
	local out: { Part } = {}
	local function add(name: string, kind: Kind, center: vector, size: vector, yaw: number?, side: number?)
		table.insert(out, { name = name, kind = kind, center = center, size = size, yaw = yaw or 0, side = side })
	end
	-- A part and its partner turned half way round (a box turned half way
	-- round keeps its yaw).
	local function pair(name: string, kind: Kind, center: vector, size: vector, yaw: number?)
		add(name, kind, center, size, yaw, nil)
		add(name, kind, ArenaLayout.turned(center), size, yaw, nil)
	end
	-- From x0 to x1 along x, at z, from the floor up.
	local function wallX(name: string, x0: number, x1: number, z: number)
		pair(name, "wall", vector.create((x0 + x1) / 2, wallH / 2, z), vector.create(x1 - x0, wallH, wallT))
	end
	local function wallZ(name: string, x: number, z0: number, z1: number)
		pair(name, "wall", vector.create(x, wallH / 2, (z0 + z1) / 2), vector.create(wallT, wallH, z1 - z0))
	end

	add("Floor", "floor", vector.create(0, -0.5, 0), vector.create(w + 2 * wallT, 1, l + 2 * (rd + wallT)))

	-- The hall's long walls, and its end walls either side of each room.
	wallZ("SideWall", -w / 2 - wallT / 2, -l / 2 - wallT, l / 2 + wallT)
	wallX("EndWall", -w / 2 - wallT, -rw / 2, -l / 2 - wallT / 2)
	wallX("EndWall", rw / 2, w / 2 + wallT, -l / 2 - wallT / 2)
	-- The cut corners: a square block turned 45 degrees on each corner, its
	-- diagonal twice the cut, so it reaches the cut along each wall.
	local c = P.chamfer.value * w * math.sqrt(2)
	pair("Corner", "wall", vector.create(-w / 2, wallH / 2, -l / 2), vector.create(c, wallH, c), math.rad(45))
	pair("Corner", "wall", vector.create(w / 2, wallH / 2, -l / 2), vector.create(c, wallH, c), math.rad(45))
	-- Side 1's spawn room (side 2's is its partner).
	wallZ("RoomWall", -rw / 2 - wallT / 2, -l / 2 - rd - wallT, -l / 2 - wallT)
	wallZ("RoomWall", rw / 2 + wallT / 2, -l / 2 - rd - wallT, -l / 2 - wallT)
	wallX("RoomBack", -rw / 2 - wallT, rw / 2 + wallT, -l / 2 - rd - wallT / 2)

	-- Cover, from the minimap.
	for _, piece in ArenaLayout.Pieces do
		local center = vector.create((piece.x - 0.5) * w, 0, (piece.y - 0.5) * l)
		-- The minimap is the view from above (side 1 at the top), where a
		-- positive yaw turns counterclockwise.
		local yaw = math.rad(-piece.tilt)
		local h = heightOf(piece)
		local crates = piece.crates or 1
		local along = vector.create(math.cos(yaw), 0, -math.sin(yaw)) -- the piece's own x axis
		local each = piece.length * w / crates
		for i = 1, crates do
			local offset = (i - (crates + 1) / 2) * each
			local at = center + along * offset + vector.create(0, h / 2, 0)
			if piece.name == "CentreBlock" then
				add(piece.name, "cover", at, vector.create(each, h, piece.depth * w), yaw)
			else
				pair(piece.name, "cover", at, vector.create(each, h, piece.depth * w), yaw)
			end
		end
	end

	-- Each room's barrier, across its opening, and its floor.
	local bt = P.barrierThickness.value
	for side = 1, 2 do
		local room = ArenaLayout.room(side)
		local mouth = if side == 1 then room.max.z else room.min.z
		add("Barrier", "barrier", vector.create(0, wallH / 2, mouth), vector.create(rw, wallH, bt), 0, side)
		local mid = (room.min + room.max) / 2
		add("SpawnFloor", "marking", vector.create(mid.x, 0.005, mid.z), vector.create(rw, 0.01, rd), 0, side)
	end

	-- A 2 m grid on the hall's floor, to judge distances by.
	for x = -math.floor(w / 4) * 2, w / 2 - 0.01, 2 do
		add("GridLine", "marking", vector.create(x, 0.005, 0), vector.create(0.04, 0.01, l))
	end
	for z = -math.floor(l / 4) * 2, l / 2 - 0.01, 2 do
		add("GridLine", "marking", vector.create(0, 0.005, z), vector.create(w, 0.01, 0.04))
	end
	return out
end

return ArenaLayout
