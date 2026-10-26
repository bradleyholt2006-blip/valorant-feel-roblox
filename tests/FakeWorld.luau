--!strict
-- Analytic world of boxes, axis-aligned or rotated, for offline tests.
-- Implements the same World interface the Roblox adapter does (sweep +
-- overlaps), in metres, and copies Roblox Blockcast's blind spot: a sweep
-- ignores any box it starts inside or too close to.

local BoxMath = require("../src/shared/Movement/BoxMath")

type Box = BoxMath.Box & { separating: { vector } }

local FakeWorld = {}
FakeWorld.__index = FakeWorld

-- Measured in Studio: Blockcast misses a part when it starts 0.0003 studs
-- (0.08 mm) from it or closer, at any angle and for rotated parts alike, and
-- hits it from 0.001 studs (0.28 mm). 1 mm here is a cautious stand-in.
FakeWorld.START_TOLERANCE = 0.001

function FakeWorld.new()
	local self = setmetatable({ boxes = {} :: { Box }, startTolerance = FakeWorld.START_TOLERANCE }, FakeWorld)
	return self
end

local function add(self: any, center: vector, half: vector, axes: { vector })
	local box: any = { center = center, half = half, axes = axes }
	box.separating = BoxMath.axes(box)
	table.insert(self.boxes, box)
	return self
end

function FakeWorld:addBox(min: vector, max: vector)
	return add(self, (min + max) * 0.5, (max - min) * 0.5, { vector.create(1, 0, 0), vector.create(0, 1, 0), vector.create(0, 0, 1) })
end

-- A part like Roblox's CFrame.new(center) * CFrame.Angles(rx, ry, rz): it
-- turns by rz about Z, then ry about Y, then rx about X (radians).
function FakeWorld:addPart(center: vector, size: vector, rx: number?, ry: number?, rz: number?)
	local function turn(v: vector): vector
		local a, b, c = rz or 0, ry or 0, rx or 0
		v = vector.create(v.x * math.cos(a) - v.y * math.sin(a), v.x * math.sin(a) + v.y * math.cos(a), v.z)
		v = vector.create(v.x * math.cos(b) + v.z * math.sin(b), v.y, -v.x * math.sin(b) + v.z * math.cos(b))
		return vector.create(v.x, v.y * math.cos(c) - v.z * math.sin(c), v.y * math.sin(c) + v.z * math.cos(c))
	end
	return add(self, center, size * 0.5, { turn(vector.create(1, 0, 0)), turn(vector.create(0, 1, 0)), turn(vector.create(0, 0, 1)) })
end

-- A large floor whose top surface sits at y = 0.
function FakeWorld:addFloor()
	return self:addBox(vector.create(-1000, -1, -1000), vector.create(1000, 0, 1000))
end

-- Swept separating-axis test against each box (BoxMath.sweep): the nearest
-- it touches, with the blind spot of Roblox's Blockcast.
function FakeWorld:sweep(center: vector, half: vector, delta: vector): (number?, vector?)
	local best: number? = nil
	local bestNormal: vector? = nil
	for _, box in self.boxes do
		local t, normal = BoxMath.sweep(center, half, delta, box, box.separating, self.startTolerance)
		if t and (best == nil or t < best) then
			best, bestNormal = t, normal
		end
	end
	return best, bestNormal
end

function FakeWorld:overlaps(center: vector, half: vector): boolean
	for _, box in self.boxes do
		if BoxMath.separation(center, half, box, box.separating) < 0 then
			return true
		end
	end
	return false
end

function FakeWorld:nearest(center: vector, half: vector, margin: number): (number?, vector?)
	local best: number?, away: vector? = nil, nil
	for _, box in self.boxes do
		local gap, out = BoxMath.separation(center, half, box, box.separating)
		if gap <= margin and (best == nil or gap < best) then
			best, away = gap, out
		end
	end
	return best, away
end

-- How close the box is to the nearest obstacle (negative when inside one).
function FakeWorld:clearance(center: vector, half: vector): number
	local best = math.huge
	for _, box in self.boxes do
		best = math.min(best, (BoxMath.separation(center, half, box, box.separating)))
	end
	return best
end

return FakeWorld
