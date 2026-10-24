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

-- Nearest target hit before `blockedAt` metres (world geometry), or nil.
function ShotResolver.resolve(origin: vector, dir: vector, targets: { Target }, blockedAt: number, ignoreId: number?): Result?
	local best: Result? = nil
	local limit = blockedAt
	for _, target in targets do
		if target.id == ignoreId then
			continue
		end
		-- Broad phase: skip targets whose bounding sphere the ray misses.
		local toCenter = target.pose.position + CENTER_OFFSET - origin
		local along = vector.dot(toCenter, dir)
		if along < -Hitboxes.BOUND_RADIUS or along > limit + Hitboxes.BOUND_RADIUS then
			continue
		end
		local closest = toCenter - dir * along
		if vector.magnitude(closest) > Hitboxes.BOUND_RADIUS then
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
