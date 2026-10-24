--!strict
-- Penetration.Level made of axis-aligned boxes with materials, for offline
-- tests. Same rules as the Roblox adapter: a box the ray starts inside is
-- never hit, and the exit is only reported within the depth asked for (and
-- Penetration.EXIT_TOLERANCE).

local Penetration = require("../src/shared/Combat/Penetration")

export type Box = { min: vector, max: vector, material: Penetration.Material }

local FakeLevel = {}
FakeLevel.__index = FakeLevel

function FakeLevel.new()
	return setmetatable({ boxes = {} :: { Box } }, FakeLevel)
end

function FakeLevel:add(material: Penetration.Material, min: vector, max: vector): Box
	local box: Box = { min = min, max = max, material = material }
	table.insert(self.boxes, box)
	return box
end

-- A wall across a ray fired down -Z from z = 0: its near face `near` metres
-- away, `thickness` deep, 10 m wide and 5 m tall.
function FakeLevel:wall(material: Penetration.Material, near: number, thickness: number): Box
	return self:add(material, vector.create(-5, -1, -(near + thickness)), vector.create(5, 4, -near))
end

local AXES = { "x", "y", "z" }

-- Slab method: where the ray enters and leaves the box, and on which axes.
local function slab(origin: vector, dir: vector, box: Box): (number, number, number, number)
	local tEnter, tExit = -math.huge, math.huge
	local enterAxis, exitAxis = 0, 0
	for i, axis in AXES do
		local o = (origin :: any)[axis]
		local d = (dir :: any)[axis]
		local lo = (box.min :: any)[axis]
		local hi = (box.max :: any)[axis]
		if math.abs(d) < 1e-12 then
			if o < lo or o > hi then
				return math.huge, -math.huge, 0, 0
			end
		else
			local t1, t2 = (lo - o) / d, (hi - o) / d
			if t1 > t2 then
				t1, t2 = t2, t1
			end
			if t1 > tEnter then
				tEnter, enterAxis = t1, i
			end
			if t2 < tExit then
				tExit, exitAxis = t2, i
			end
		end
	end
	return tEnter, tExit, enterAxis, exitAxis
end

local function axisNormal(axis: number, sign: number): vector
	local n = { 0, 0, 0 }
	n[axis] = sign
	return vector.create(n[1], n[2], n[3])
end

local function sign(v: number): number
	return if v > 0 then 1 else -1
end

function FakeLevel:cast(origin: vector, dir: vector, maxDistance: number, skip: { any }): Penetration.Surface?
	local best: Penetration.Surface? = nil
	for _, box in self.boxes do
		if table.find(skip, box) then
			continue
		end
		local tEnter, tExit, enterAxis = slab(origin, dir, box)
		if enterAxis == 0 or tEnter < 0 or tEnter > tExit or tEnter > maxDistance then
			continue
		end
		if best == nil or tEnter < best.distance then
			local d = (dir :: any)[AXES[enterAxis]]
			best = { distance = tEnter, normal = axisNormal(enterAxis, -sign(d)), material = box.material, key = box }
		end
	end
	return best
end

function FakeLevel:exit(origin: vector, dir: vector, surface: Penetration.Surface, depth: number): (number?, vector?)
	local box = surface.key :: Box
	local _, tExit, _, exitAxis = slab(origin, dir, box)
	if exitAxis == 0 or tExit - surface.distance > depth + Penetration.EXIT_TOLERANCE then
		return nil, nil
	end
	local d = (dir :: any)[AXES[exitAxis]]
	return tExit, axisNormal(exitAxis, sign(d))
end

return FakeLevel
