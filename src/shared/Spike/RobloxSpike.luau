--!strict
-- The spike's questions for the Roblox world (system 12), asked the same way
-- on the server and the client so both simulations agree: whether a
-- defuser's eye can see the planted spike, and where something let go of
-- comes to rest. Characters and anything that doesn't collide are looked
-- through, as RobloxWorld's movement queries do. Metres in and out.

local Workspace = game:GetService("Workspace")

local RobloxWorld = require(script.Parent.Parent.Movement.RobloxWorld)
local Units = require(script.Parent.Parent.Units)

local RobloxSpike = {}

-- The spike's height off the ground, which the eye looks at.
local CENTRE = 0.15 -- metres (estimate: the model is about 0.3 m tall)
-- How far short of the spike a wall must be to hide it.
local SHORT = 0.05 -- metres

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = RobloxWorld.CHARACTER_GROUP
params.RespectCanCollide = true

-- Whether nothing solid is between the eye and the spike lying at `spike`.
function RobloxSpike.sees(eye: vector, spike: vector): boolean
	local target = spike + vector.create(0, CENTRE, 0)
	local offset = target - eye
	local distance = vector.magnitude(offset)
	if distance <= SHORT then
		return true
	end
	local reach = offset * ((distance - SHORT) / distance)
	return Workspace:Raycast(Units.toStuds(eye), Units.toStuds(reach), params) == nil
end

-- The ground under `point`, within `depth` metres below it (and from a
-- little above, so a point just inside a floor still finds its top), or nil
-- when there's none: the spike fell out of the world.
function RobloxSpike.ground(point: vector, depth: number): vector?
	local lift = 0.5
	local from = point + vector.create(0, lift, 0)
	local hit = Workspace:Raycast(Units.toStuds(from), Units.toStuds(vector.create(0, -(depth + lift), 0)), params)
	if not hit then
		return nil
	end
	return Units.toMetres(hit.Position)
end

-- How far a spike thrown from `from` along the flat direction `dir` gets
-- before a wall stops it, up to `distance` metres, keeping clear of the wall.
function RobloxSpike.reach(from: vector, dir: vector, distance: number): number
	local hit = Workspace:Raycast(Units.toStuds(from), Units.toStuds(dir * distance), params)
	if not hit then
		return distance
	end
	return math.max(0, hit.Distance * Units.METRES_PER_STUD - 0.2)
end

return RobloxSpike
