--!strict
-- Penetration.Level backed by Roblox raycasts, in metres. Client prediction
-- and the server both trace shots through it.
--
-- A part's penetration material is the VFPenetration attribute ("soft",
-- "medium", "hard" or "solid") of the part or its nearest ancestor that has
-- one, or else follows its Roblox material: wood, glass and the like are
-- soft, stone, brick and concrete medium, metal hard, and everything else
-- (plastic, neon, terrain...) solid, so geometry built before penetration
-- existed still stops every bullet.
--
-- The exit is found by casting back toward the shooter, from as deep as the
-- bullet can reach, against that part alone (and its descendants): the
-- first face that cast meets is where the bullet comes out. A ray that
-- starts inside a part doesn't hit it, so when the cast starts inside, the
-- part is thicker than the bullet can go. That is exact for convex parts
-- (blocks, wedges, cylinders); a ray that leaves a concave union or mesh and
-- enters it again counts only one stretch. RobloxLevel.selfTest checks the
-- adapter against parts of known size.

local Workspace = game:GetService("Workspace")

local Penetration = require("./Penetration")
local RobloxWorld = require("../Movement/RobloxWorld")
local Units = require("../Units")

local M = Units.METRES_PER_STUD

-- The back cast starts this far past the deepest point the bullet reaches,
-- and stops this far short of the entry face, so it never meets that face.
local EXIT_SLACK = 0.001
local ENTRY_GAP = 0.0005

local RobloxLevel = {}
RobloxLevel.__index = RobloxLevel
RobloxLevel.ATTRIBUTE = "VFPenetration"

local MATERIALS: { [string]: Penetration.Material } = {}
for _, name in { "Wood", "WoodPlanks", "Glass", "Fabric", "Cardboard", "Carpet", "Leather", "Plaster" } do
	MATERIALS[name] = "soft"
end
for _, name in
	{
		"Concrete",
		"Brick",
		"Cobblestone",
		"Granite",
		"Marble",
		"Slate",
		"Pavement",
		"Limestone",
		"Sandstone",
		"Basalt",
		"Rock",
		"Asphalt",
		"CeramicTiles",
		"ClayRoofTiles",
		"RoofShingles",
		"Pebble",
		"Salt",
	}
do
	MATERIALS[name] = "medium"
end
for _, name in { "Metal", "DiamondPlate", "CorrodedMetal", "Foil" } do
	MATERIALS[name] = "hard"
end

local function parse(value: any): Penetration.Material?
	if value == "soft" or value == "medium" or value == "hard" or value == "solid" then
		return value :: Penetration.Material
	end
	return nil
end

-- The penetration material of a part the ray met.
function RobloxLevel.materialOf(part: BasePart): Penetration.Material
	if part:IsA("Terrain") then
		return "solid"
	end
	local node: Instance? = part
	while node and node ~= Workspace do
		local set: Penetration.Material? = parse(node:GetAttribute(RobloxLevel.ATTRIBUTE))
		if set then
			return set
		end
		node = node.Parent
	end
	return MATERIALS[part.Material.Name] or "solid"
end

function RobloxLevel.new(): Penetration.Level
	local castParams = RaycastParams.new()
	castParams.FilterType = Enum.RaycastFilterType.Exclude
	castParams.CollisionGroup = RobloxWorld.CHARACTER_GROUP
	castParams.RespectCanCollide = true

	local exitParams = RaycastParams.new()
	exitParams.FilterType = Enum.RaycastFilterType.Include
	exitParams.CollisionGroup = RobloxWorld.CHARACTER_GROUP
	exitParams.RespectCanCollide = true

	return (setmetatable({ castParams = castParams, exitParams = exitParams }, RobloxLevel) :: any) :: Penetration.Level
end

function RobloxLevel:cast(origin: vector, dir: vector, maxDistance: number, skip: { any }): Penetration.Surface?
	local params = self.castParams
	params.FilterDescendantsInstances = skip
	local result = Workspace:Raycast(Units.toStuds(origin), Units.toStuds(dir * maxDistance), params)
	if not result then
		return nil
	end
	local part = result.Instance
	return {
		distance = result.Distance * M,
		normal = Units.asVector(result.Normal),
		material = RobloxLevel.materialOf(part),
		name = result.Material.Name,
		key = part,
	}
end

function RobloxLevel:exit(origin: vector, dir: vector, surface: Penetration.Surface, depth: number): (number?, vector?)
	if depth <= 0 then
		return nil, nil
	end
	local params = self.exitParams
	params.FilterDescendantsInstances = { surface.key }
	local back = depth + EXIT_SLACK
	local from = origin + dir * (surface.distance + back)
	local result = Workspace:Raycast(Units.toStuds(from), Units.toStuds(-dir * (back - ENTRY_GAP)), params)
	if not result then
		return nil, nil
	end
	return surface.distance + back - result.Distance * M, Units.asVector(result.Normal)
end

-- Traces through parts of known size somewhere out of the way and checks the
-- adapter measures them: how thick a slab is, how deep a bullet gets into
-- one it can't go through, and that plastic stops it. Yields a frame.
-- Returns whether every check passed and a one-line report.
function RobloxLevel.selfTest(): (boolean, string)
	local folder = Instance.new("Folder")
	folder.Name = "VFPenetrationSelfTest"
	local function slab(material: Enum.Material, thickness: number, x: number): BasePart
		local p = Instance.new("Part")
		p.Anchored = true
		p.Material = material
		p.Size = Vector3.new(2, 2, thickness) * Units.STUDS_PER_METRE
		p.CFrame = CFrame.new(Vector3.new(x, 600, -(1 + thickness / 2)) * Units.STUDS_PER_METRE)
		p.Parent = folder
		return p
	end
	slab(Enum.Material.Wood, 0.2, 0)
	slab(Enum.Material.Concrete, 1.0, 5)
	slab(Enum.Material.SmoothPlastic, 0.1, 10)
	folder.Parent = Workspace
	task.wait() -- let the new parts reach the spatial index

	local level = RobloxLevel.new()
	local forward = vector.create(0, 0, -1)
	local function run(x: number): Penetration.Trace
		return Penetration.trace(level, vector.create(x, 600, 0), forward, "medium", 4)
	end
	local problems = {}
	local wood = run(0)
	local w = wood.walls[1]
	local woodThickness = if w then w.thickness else 0
	if not w or wood.stopped or w.material ~= "soft" or math.abs(w.entry - 1) > 0.002 or math.abs(woodThickness - 0.2) > 0.002 then
		table.insert(
			problems,
			string.format("0.20 m wood: %d walls, stopped %s, thickness %.3f m", #wood.walls, tostring(wood.stopped), woodThickness)
		)
	elseif not w.exitNormal or vector.dot(w.exitNormal, forward) < 0.99 then
		table.insert(problems, "0.20 m wood: the exit normal doesn't face out")
	end
	local concrete = run(5)
	local expected = 1 + Penetration.limit("medium", "medium")
	if not concrete.stopped or math.abs(concrete.stop - expected) > 0.002 then
		table.insert(
			problems,
			string.format(
				"1 m concrete: stopped %s at %.3f m, expected inside at %.3f m",
				tostring(concrete.stopped),
				concrete.stop,
				expected
			)
		)
	end
	local plastic = run(10)
	if not plastic.stopped or math.abs(plastic.stop - 1) > 0.002 then
		table.insert(
			problems,
			string.format("plastic: stopped %s at %.3f m, expected at its face", tostring(plastic.stopped), plastic.stop)
		)
	end
	folder:Destroy()
	if #problems > 0 then
		return false, "penetration self-test FAILED: " .. table.concat(problems, "; ")
	end
	return true,
		string.format(
			"penetration self-test passed: wood measured %.3f m, concrete stopped %.3f m in, plastic stops",
			woodThickness,
			concrete.stop - 1
		)
end

return RobloxLevel
