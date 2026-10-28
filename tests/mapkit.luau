--!strict
-- The kit a dressed spike map is built from, and Wharf, the first dressed
-- map (system 58): each piece's placeholder inside its box, the looks, the
-- zones of Wharf's floor, its dressing out of reach overhead, and the other
-- maps as they were. Over Wharf's raised floors (system 59), out of reach
-- is over the highest floor there.

local MapKit = require("../src/shared/Match/MapKit")
local MapPlan = require("../src/shared/Match/MapPlan")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local H = require("./Harness")

local check = H.check

H.section("The map kit and Wharf (system 58)")

local cfg = MovementConfig.resolve()
local EPS = 1e-6
-- Roblox's materials the kit uses, by name.
local MATERIALS = {
	Asphalt = true,
	Concrete = true,
	DiamondPlate = true,
	Ground = true,
	LeafyGrass = true,
	Metal = true,
	Neon = true,
	Pavement = true,
	Plaster = true,
	Slate = true,
	SmoothPlastic = true,
	Wood = true,
	WoodPlanks = true,
}
local PENETRATION = { soft = true, medium = true, hard = true, solid = true }

local function colourOk(c: MapKit.Colour): boolean
	if #c ~= 3 then
		return false
	end
	for _, v in c do
		if v ~= math.floor(v) or v < 0 or v > 255 then
			return false
		end
	end
	return true
end

-- A size for each piece as maps use it: across its long side, up, across.
local function sizeOf(piece: string): vector
	local h = MapPlan.Heights[MapKit.Pieces[piece].height].value
	if piece == "Container" then
		return vector.create(6, h, 2.4)
	elseif piece == "Hedge" or piece == "Planter" then
		return vector.create(5, h, 1.2)
	end
	return vector.create(1.8, h, 1.2)
end

do
	local known, inside, looks, overhead = true, true, true, true
	local reach, under = 0, math.huge
	for name, piece in MapKit.Pieces do
		known = known and MapPlan.Heights[piece.height] ~= nil and piece.looks >= 1 and PENETRATION[piece.penetration] == true
		local size = sizeOf(name)
		for look = 1, piece.looks do
			local bits = MapKit.bits(name, size, look)
			looks = looks and #bits > 0
			for _, bit in bits do
				looks = looks and colourOk(bit.colour) and MATERIALS[bit.material] == true
				local lo, hi = bit.offset - bit.size / 2, bit.offset + bit.size / 2
				if name == "Tree" and (bit.name == "Trunk" or bit.name == "Leaves") then
					-- Over the box: the trunk from its top up, and the leaves.
					overhead = overhead and lo.y >= size.y - EPS
					if bit.name == "Leaves" then
						reach = math.max(reach, math.sqrt(bit.offset.x ^ 2 + bit.offset.z ^ 2) + bit.size.x / 2)
						under = math.min(under, lo.y)
					end
				else
					local half = size / 2
					local ok = lo.x >= -half.x - EPS
						and hi.x <= half.x + EPS
						and lo.z >= -half.z - EPS
						and hi.z <= half.z + EPS
						and lo.y >= -EPS
						and hi.y <= size.y + EPS
					inside = inside and ok
					if not ok then
						print("    outside its box: " .. name .. "." .. bit.name)
					end
				end
			end
		end
	end
	check("every piece of the kit is cover of a height the maps know, with its looks and how bullets go through it", known)
	check("each piece's placeholder stays inside its box, as the box is all that's solid", inside)
	check("every look is a colour and one of Roblox's materials", looks)
	check("but a tree's trunk and leaves, which are over its planter", overhead)
	check(
		"the leaves above a jumping player's head, and no further out from the trunk than the kit says",
		under > cfg.jumpApexHeight + cfg.standHeight and reach <= MapKit.CANOPY_RADIUS + EPS,
		string.format("%.2f m up, %.2f m out", under, reach)
	)

	local same = MapKit.lookOf("Container", "ADefault") == MapKit.lookOf("Container", "ADefault")
	local inRange = true
	for _, name in { "A", "BLobbyContainer", "PlazaTree", "x" } do
		local look = MapKit.lookOf("Container", name)
		inRange = inRange and look >= 1 and look <= MapKit.Pieces.Container.looks
	end
	check("a piece's look follows from its name, the same every time", same and inRange)
	check("or is the map's own", MapKit.lookOf("Container", "ADefault", 4) == 4 and MapKit.lookOf("Crate", "x", 5) == 2)

	local themed = true
	for _, list in { MapKit.Themes, MapKit.Styles } do
		for _, look in list do
			themed = themed and colourOk(look.colour) and MATERIALS[look.material] == true and PENETRATION[look.penetration] == true
		end
	end
	for _, look in MapKit.Themes do
		themed = themed and look.solid and look.penetration == "solid"
	end
	check("every zone's floor, the walls and every kind of dressing has its look, the floors and walls stopping every bullet", themed)
end

-- Wharf ----------------------------------------------------------------------------------

local wharf = SpikeMaps.Maps.wharf
local parts = wharf.parts()
local clearance = MapPlan.Plan.clearance.value
local wallH = MapPlan.Plan.wallHeight.value

-- The 1 m cells under a box, by their middles.
local function cells(x0: number, z0: number, x1: number, z1: number): { vector }
	local out = {}
	for x = math.floor(x0) + 0.5, x1, 1 do
		for z = math.floor(z0) + 0.5, z1, 1 do
			if x > x0 and z > z0 then
				table.insert(out, vector.create(x, 0, z))
			end
		end
	end
	return out
end

local function footprint(part: MapPlan.Part): (number, number, number, number)
	return part.center.x - part.size.x / 2,
		part.center.z - part.size.z / 2,
		part.center.x + part.size.x / 2,
		part.center.z + part.size.z / 2
end

do
	local zoned = wharf.dressed
	for _, room in wharf.rooms() do
		zoned = zoned and room.zone ~= nil and MapKit.Themes[room.zone :: string] ~= nil
	end
	local pieced = true
	for _, c in wharf.cover() do
		local piece = if c.piece then MapKit.Pieces[c.piece :: string] else nil
		pieced = pieced and piece ~= nil and piece.height == c.height
		if piece == nil or piece.height ~= c.height then
			print("    not a piece of the kit as tall as it: " .. c.name)
		end
	end
	local styled = #wharf.Dressing > 0
	for _, part in parts do
		if part.kind == "dressing" then
			styled = styled and MapKit.Styles[part.style or ""] ~= nil
		end
	end
	check("Wharf is dressed: every room in a zone with a look", zoned)
	check("every piece of its cover a piece of the kit, as tall as the kit has it", pieced)
	check("and every piece of its dressing in a style", styled)

	-- Its floor, each zone's own, covers each cell of its rooms once.
	local x0, z0, x1, z1 = wharf.bounds()
	local floorCells = 0
	for _, at in cells(x0, z0, x1, z1) do
		if wharf.onFloor(at.x, at.z) then
			floorCells += 1
		end
	end
	local area, onRooms, walls = 0, true, true
	for _, part in parts do
		if part.kind == "floor" then
			local a, b, c, d = footprint(part)
			area += (c - a) * (d - b)
			for _, at in cells(a, b, c, d) do
				onRooms = onRooms and wharf.onFloor(at.x, at.z)
			end
			onRooms = onRooms and MapKit.Themes[part.zone or ""] ~= nil
		elseif part.kind == "wall" then
			walls = walls and part.zone == "wall"
		end
	end
	check(
		"its floor is its zones', every cell of its rooms once and nothing else",
		onRooms and math.abs(area - floorCells) < EPS,
		string.format("%d m2 of %d", area, floorCells)
	)
	check("its walls in the walls' look", walls)
end

do
	local reach, stands, roofs, lights, lintels = true, true, 0, 0, true
	for _, part in parts do
		local style = MapKit.Styles[part.style or ""]
		if part.kind == "dressing" and style then
			local a, b, c, d = footprint(part)
			local bottom = part.center.y - part.size.y / 2
			local overFloor, floorTop = false, -math.huge
			for _, at in cells(a, b, c, d) do
				overFloor = overFloor or wharf.onFloor(at.x, at.z)
				for _, y in wharf.levelsAt(at.x, at.z) do
					floorTop = math.max(floorTop, y)
				end
			end
			if style.solid and overFloor and bottom < floorTop + clearance - EPS then
				reach = false
				print("    in reach over the floor: " .. part.name)
			end
			if (part.style == "building" or part.style == "tower") and (overFloor or bottom < wallH - EPS) then
				stands = false
				print("    not standing on the walls: " .. part.name)
			end
			if part.style == "roof" then
				roofs += 1
			elseif part.style == "light" then
				lights += 1
			elseif part.style == "lintel" then
				local room = wharf.room(string.sub(part.name, 1, -#"Lintel" - 1))
				lintels = lintels
					and room ~= nil
					and math.abs(a - room.x0) < EPS
					and math.abs(c - room.x1) < EPS
					and math.abs(b - room.z0) < EPS
					and math.abs(d - room.z1) < EPS
					and math.abs(bottom - (room.y or 0) - clearance) < EPS
			end
		end
	end
	local roofed = 0
	for _, room in wharf.rooms() do
		if room.roof then
			roofed += 1
		end
	end
	check("everything solid over its floor is out of reach overhead, 3.4 m over the highest floor there", reach)
	check("its buildings and its tower stand on the walls, over no floor", stands)
	check("each roofed room has its roof, with a light under it", roofed >= 3 and roofs == roofed and lights == roofed)
	check("and each lintel spans its door, from 3.4 m up", lintels)

	local leaves = true
	for _, c in wharf.cover() do
		if c.piece == "Tree" then
			local r = MapKit.CANOPY_RADIUS
			for k = 0, 7 do
				local angle = k * math.pi / 4
				leaves = leaves and wharf.onFloor(c.x + r * math.cos(angle), c.z + r * math.sin(angle))
			end
		end
	end
	check("its trees' leaves are over its floor, clear of the walls", leaves)

	local signs, facing = 0, true
	for _, part in parts do
		if part.style == "sign" then
			signs += 1
			-- A metre out in front of its face is floor, and just behind it wall.
			local ahead = if part.face == "+z" then 1 elseif part.face == "-z" then -1 else 0
			local back = part.center.z - ahead * (part.size.z / 2 + 0.1)
			local front = part.center.z + ahead
			facing = facing and ahead ~= 0 and wharf.onFloor(part.center.x, front) and not wharf.onFloor(part.center.x, back)
		end
	end
	check("a sign for each site, on a wall, facing into it", signs == 2 and facing)
end

do
	-- The other maps aren't dressed: one floor, no dressing, plain cover.
	local plain = true
	for _, key in SpikeMaps.MAPS do
		local map = SpikeMaps.Maps[key]
		if key ~= "wharf" then
			local floors, extra = 0, 0
			for _, part in map.parts() do
				if part.kind == "floor" then
					floors += 1
				end
				if part.kind == "dressing" or part.zone or part.piece then
					extra += 1
				end
			end
			plain = plain and not map.dressed and floors == 1 and extra == 0 and #map.Dressing == 0
		end
	end
	check("the other maps are as they were: one floor, plain cover and no dressing", plain)
end

return nil
