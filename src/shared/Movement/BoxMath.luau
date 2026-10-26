--!strict
-- Separating-axis maths between the player's axis-aligned box and an oriented
-- box (a rotated part), in metres. RobloxWorld uses it to test overlaps
-- exactly where Roblox only offers bounding boxes; the offline tests' fake
-- world uses it for rotated parts. Sage's walls (system 38, BarrierSim) are
-- boxes like these that are in no level at all, so it also sweeps a box
-- against one, as Roblox's Blockcast would, and casts a ray at one.

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

-- Swept separating-axis test: how far along `delta` (0 to 1) the
-- axis-aligned box (center, half) moves before it touches `box`, and the way
-- the face it meets looks, or nil if it doesn't within the move. Along each
-- axis the two overlap over a stretch of the move; they touch where the last
-- of those starts. Like Roblox's Blockcast, it doesn't see a box it starts
-- inside or within `tolerance` of. Pass `axes` from BoxMath.axes(box) to
-- reuse them.
function BoxMath.sweep(center: vector, half: vector, delta: vector, box: Box, axes: { vector }?, tolerance: number): (number?, vector?)
	local tEnter, tExit = -math.huge, math.huge
	local enterAxis: vector? = nil
	local enterSpeed = 0
	local gap = -math.huge
	local d = center - box.center
	local candidates: { vector } = axes or BoxMath.axes(box)
	for _, axis in candidates do
		local reach = BoxMath.aabbReach(half, axis) + BoxMath.reach(box, axis)
		local s = vector.dot(d, axis)
		local v = vector.dot(delta, axis)
		gap = math.max(gap, math.abs(s) - reach)
		if math.abs(v) < 1e-12 then
			if math.abs(s) >= reach then
				return nil, nil
			end
		else
			local t1, t2 = (-reach - s) / v, (reach - s) / v
			if t1 > t2 then
				t1, t2 = t2, t1
			end
			if t1 > tEnter then
				tEnter, enterAxis, enterSpeed = t1, axis, v
			end
			tExit = math.min(tExit, t2)
			if tEnter > tExit then
				return nil, nil
			end
		end
	end
	-- The blind spot: a box the sweep starts inside, or within the
	-- tolerance of, is missed.
	if not enterAxis or gap < tolerance or tEnter < 0 or tEnter > 1 then
		return nil, nil
	end
	-- The normal points against the move on the axis it met.
	return tEnter, if enterSpeed > 0 then -enterAxis else enterAxis
end

-- Half the size of `box` along its own axis `i` (1, 2 or 3).
local function halfAlong(box: Box, i: number): number
	return if i == 1 then box.half.x elseif i == 2 then box.half.y else box.half.z
end

-- Whether `point` is inside `box` (its faces count).
function BoxMath.inside(point: vector, box: Box): boolean
	local d = point - box.center
	for i, axis in box.axes do
		if math.abs(vector.dot(d, axis)) > halfAlong(box, i) then
			return false
		end
	end
	return true
end

-- Where a ray from `origin` along the unit `dir` enters `box`, in metres,
-- within `maxDistance`, and the way that face looks; nil if it doesn't, or
-- if the ray starts inside it (as a raycast doesn't see a part it starts
-- in). The slab method, on the box's own axes.
function BoxMath.ray(origin: vector, dir: vector, maxDistance: number, box: Box): (number?, vector?)
	local d = origin - box.center
	local tEnter, tExit = -math.huge, math.huge
	local normal: vector? = nil
	for i, axis in box.axes do
		local h = halfAlong(box, i)
		local s = vector.dot(d, axis)
		local v = vector.dot(dir, axis)
		if math.abs(v) < 1e-12 then
			if math.abs(s) > h then
				return nil, nil
			end
		else
			local t1, t2 = (-h - s) / v, (h - s) / v
			-- Going up the axis it comes in through the face looking down it.
			local face = if v > 0 then -axis else axis
			if t1 > t2 then
				t1, t2 = t2, t1
			end
			if t1 > tEnter then
				tEnter, normal = t1, face
			end
			tExit = math.min(tExit, t2)
		end
	end
	if not normal or tEnter > tExit or tEnter < 0 or tEnter > maxDistance then
		return nil, nil
	end
	return tEnter, normal
end

return BoxMath
