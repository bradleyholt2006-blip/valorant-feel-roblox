--!strict
-- MovementSim.World backed by Roblox spatial queries. Converts metres <-> studs
-- at the boundary so the simulation never sees studs.
--
-- Characters are put in the CHARACTER_GROUP collision group, which doesn't
-- collide with itself, so the sweep ignores every player (including the one
-- moving). Player-vs-player blocking is a later decision.

local Workspace = game:GetService("Workspace")

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
	return #parts > 0
end

return RobloxWorld
