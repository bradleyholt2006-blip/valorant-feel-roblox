--!strict
-- Analytic world of axis-aligned boxes for offline tests. Implements the same
-- World interface the Roblox adapter does (sweep + overlaps), in metres.

type Box = { min: vector, max: vector }

local FakeWorld = {}
FakeWorld.__index = FakeWorld

function FakeWorld.new()
	local self = setmetatable({ boxes = {} :: { Box } }, FakeWorld)
	return self
end

function FakeWorld:addBox(min: vector, max: vector)
	table.insert(self.boxes, { min = min, max = max })
	return self
end

-- A large floor whose top surface sits at y = 0.
function FakeWorld:addFloor()
	return self:addBox(vector.create(-1000, -1, -1000), vector.create(1000, 0, 1000))
end

local AXES = { "x", "y", "z" }

-- Swept AABB vs AABB via the slab method on the Minkowski-expanded box.
function FakeWorld:sweep(center: vector, half: vector, delta: vector): (number?, vector?)
	local best: number? = nil
	local bestNormal: vector? = nil
	for _, box in self.boxes do
		local tEnter, tExit = -math.huge, math.huge
		local enterAxis = 0
		local miss = false
		for i, axis in AXES do
			local o = (center :: any)[axis]
			local d = (delta :: any)[axis]
			local lo = (box.min :: any)[axis] - (half :: any)[axis]
			local hi = (box.max :: any)[axis] + (half :: any)[axis]
			if math.abs(d) < 1e-9 then
				if o <= lo or o >= hi then
					miss = true
					break
				end
			else
				local t1, t2 = (lo - o) / d, (hi - o) / d
				if t1 > t2 then
					t1, t2 = t2, t1
				end
				if t1 > tEnter then
					tEnter, enterAxis = t1, i
				end
				tExit = math.min(tExit, t2)
				if tEnter > tExit then
					miss = true
					break
				end
			end
		end
		-- Start-overlapping boxes are ignored, matching Roblox Blockcast.
		if not miss and tEnter >= 0 and tEnter <= 1 and enterAxis ~= 0 then
			if best == nil or tEnter < best then
				best = tEnter
				local n = { 0, 0, 0 }
				-- Normal points against the direction of travel on the hit axis.
				n[enterAxis] = if (delta :: any)[AXES[enterAxis]] > 0 then -1 else 1
				bestNormal = vector.create(n[1], n[2], n[3])
			end
		end
	end
	return best, bestNormal
end

function FakeWorld:overlaps(center: vector, half: vector): boolean
	for _, box in self.boxes do
		local inside = true
		for _, axis in AXES do
			local c = (center :: any)[axis]
			local h = (half :: any)[axis]
			if c + h <= (box.min :: any)[axis] or c - h >= (box.max :: any)[axis] then
				inside = false
				break
			end
		end
		if inside then
			return true
		end
	end
	return false
end

return FakeWorld
