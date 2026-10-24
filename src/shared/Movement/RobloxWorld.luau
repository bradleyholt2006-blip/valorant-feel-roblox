--!strict
-- MovementSim.World backed by Roblox spatial queries. Converts metres <-> studs
-- at the boundary so the simulation never sees studs.
--
-- Characters are put in the CHARACTER_GROUP collision group, which doesn't
-- collide with itself, so the sweep ignores every player (including the one
-- moving). Player-vs-player blocking is a later decision.
--
-- Roblox's box queries only know parts' bounding boxes, which for a rotated
-- part are far bigger than the part. Block-shaped parts are measured exactly
-- here with BoxMath; other shapes keep the bounding-box answer.

local Workspace = game:GetService("Workspace")

local BoxMath = require(script.Parent.BoxMath)
local Units = require(script.Parent.Parent.Units)

local CHARACTER_GROUP = "VFCharacters"

local RobloxWorld = {}
RobloxWorld.__index = RobloxWorld
RobloxWorld.CHARACTER_GROUP = CHARACTER_GROUP

function RobloxWorld.new(): any
	local castParams = RaycastParams.new()
	castParams.FilterType = Enum.RaycastFilterType.Exclude
	castParams.CollisionGroup = CHARACTER_GROUP
	castParams.RespectCanCollide = true

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.CollisionGroup = CHARACTER_GROUP
	overlapParams.RespectCanCollide = true

	return setmetatable({ castParams = castParams, overlapParams = overlapParams }, RobloxWorld)
end

-- A block-shaped part as a BoxMath box in metres, or nil for other shapes.
local function block(part: BasePart): BoxMath.Box?
	if not (part:IsA("Part") and part.Shape == Enum.PartType.Block) then
		return nil
	end
	local cf = part.CFrame
	return {
		center = Units.toMetres(cf.Position),
		half = Units.toMetres(part.Size) * 0.5,
		axes = { Units.asVector(cf.XVector), Units.asVector(cf.YVector), Units.asVector(cf.ZVector) },
	}
end

function RobloxWorld:sweep(center: vector, half: vector, delta: vector): (number?, vector?)
	local deltaStuds = Units.toStuds(delta)
	local length = deltaStuds.Magnitude
	if length < 1e-6 then
		return nil, nil
	end
	local result = Workspace:Blockcast(CFrame.new(Units.toStuds(center)), Units.toStuds(half * 2), deltaStuds, self.castParams)
	if not result then
		return nil, nil
	end
	return math.clamp(result.Distance / length, 0, 1), Units.asVector(result.Normal)
end

function RobloxWorld:overlaps(center: vector, half: vector): boolean
	local parts = Workspace:GetPartBoundsInBox(CFrame.new(Units.toStuds(center)), Units.toStuds(half * 2), self.overlapParams)
	for _, part in parts do
		local box = block(part)
		if box == nil or BoxMath.separation(center, half, box) < 0 then
			return true
		end
	end
	return false
end

function RobloxWorld:nearest(center: vector, half: vector, margin: number): (number?, vector?)
	local reach = half + vector.create(margin, margin, margin)
	local parts = Workspace:GetPartBoundsInBox(CFrame.new(Units.toStuds(center)), Units.toStuds(reach * 2), self.overlapParams)
	local best: number?, away: vector? = nil, nil
	for _, part in parts do
		local box = block(part)
		if box then
			local gap, out = BoxMath.separation(center, half, box)
			if gap <= margin and (best == nil or gap < best) then
				best, away = gap, out
			end
		end
	end
	return best, away
end

return RobloxWorld
