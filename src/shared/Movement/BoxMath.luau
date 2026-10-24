--!strict
-- Separating-axis maths between the player's axis-aligned box and an oriented
-- box (a rotated part), in metres. RobloxWorld uses it to test overlaps
-- exactly where Roblox only offers bounding boxes; the offline tests' fake
-- world uses it for rotated parts.

export type Box = {
	center: vector,
	half: vector, -- half its size along its own axes
	axes: { vector }, -- its unit x, y and z axes, in world space
}

local BoxMath = {}

local WORLD_AXES = { vector.create(1, 0, 0), vector.create(0, 1, 0), vector.create(0, 0, 1) }

-- Every axis that can separate an axis-aligned box from `box`: the world axes,
-- the box's own axes and their cross products, world axes first.
function BoxMath.axes(box: Box): { vector }
	local axes = table.clone(WORLD_AXES)
	for _, a in box.axes do
		table.insert(axes, a)
	end
	for _, w in WORLD_AXES do
		for _, a in box.axes do
			local x = vector.cross(w, a)
			if vector.magnitude(x) > 1e-6 then
				table.insert(axes, vector.normalize(x))
			end
		end
	end
	return axes
end

-- Half the length of `box` projected onto the unit axis.
function BoxMath.reach(box: Box, axis: vector): number
	local a = box.axes
	return box.half.x * math.abs(vector.dot(a[1], axis)) + box.half.y * math.abs(vector.dot(a[2], axis)) + box.half.z * math.abs(vector.dot(a[3], axis))
end

-- The same for an axis-aligned box with these half extents.
function BoxMath.aabbReach(half: vector, axis: vector): number
	return half.x * math.abs(axis.x) + half.y * math.abs(axis.y) + half.z * math.abs(axis.z)
end

-- How far apart the axis-aligned box (center, half) and `box` are: positive is
-- a gap at least that wide, negative is how deep they overlap. Also returns
-- the unit axis that separates them best, pointing from `box` toward the
-- other: the way out. Pass `axes` from BoxMath.axes(box) to reuse them.
function BoxMath.separation(center: vector, half: vector, box: Box, axes: { vector }?): (number, vector)
	local d = center - box.center
	local best, away = -math.huge, vector.create(0, 1, 0)
	local candidates: { vector } = axes or BoxMath.axes(box)
	for _, axis in candidates do
		local s = vector.dot(d, axis)
		local gap = math.abs(s) - BoxMath.aabbReach(half, axis) - BoxMath.reach(box, axis)
		if gap > best then
			best, away = gap, if s < 0 then -axis else axis
		end
	end
	return best, away
end

return BoxMath
