--!strict
-- Finds what a hitscan shot hits among a set of posed targets. Pure: the
-- caller supplies the distance to the first piece of level geometry (from a
-- Roblox raycast), so client prediction, server authority and the offline
-- tests all resolve shots with the same code.

local Hitboxes = require("./Hitboxes")

export type Target = {
	id: number,
	pose: Hitboxes.Pose,
}

export type Result = {
	targetId: number,
	region: Hitboxes.Region,
	distance: number,
	point: vector,
}

local ShotResolver = {}

local CENTER_OFFSET = vector.create(0, 0.9, 0)

-- Broad phase: whether the ray passes through a target's bounding sphere
-- before `limit` metres. Only these targets get box tests, and the debug
-- tools compare these between client and server.
function ShotResolver.nearRay(origin: vector, dir: vector, pose: Hitboxes.Pose, limit: number): boolean
	local toCenter = pose.position + CENTER_OFFSET - origin
	local along = vector.dot(toCenter, dir)
	if along < -Hitboxes.BOUND_RADIUS or along > limit + Hitboxes.BOUND_RADIUS then
		return false
	end
	return vector.magnitude(toCenter - dir * along) <= Hitboxes.BOUND_RADIUS
end

-- Nearest target hit before `blockedAt` metres (world geometry), or nil.
function ShotResolver.resolve(origin: vector, dir: vector, targets: { Target }, blockedAt: number, ignoreId: number?): Result?
	local best: Result? = nil
	local limit = blockedAt
	for _, target in targets do
		if target.id == ignoreId or not ShotResolver.nearRay(origin, dir, target.pose, limit) then
			continue
		end
		local hit = Hitboxes.raycast(origin, dir, Hitboxes.build(target.pose), limit)
		if hit and hit.distance < limit then
			limit = hit.distance
			best = { targetId = target.id, region = hit.region, distance = hit.distance, point = hit.point }
		end
	end
	return best
end

return ShotResolver
