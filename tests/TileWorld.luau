--!strict
-- A map's solids as a world to walk in, for offline tests (system 60): the
-- same World interface FakeWorld has (sweep, overlaps, nearest and
-- clearance, in metres), its boxes filed in 4 m tiles so a query looks
-- only at those near it. A wedge's slope is built as stairs of boxes
-- rising no more than STAIR each, which the movement steps up as it does
-- the slope.

local BoxMath = require("../src/shared/Movement/BoxMath")
local BotNav = require("../src/shared/Bots/BotNav")

type Box = BoxMath.Box & { separating: { vector } }

local TileWorld = {}
TileWorld.__index = TileWorld

local TILE = 4
-- Metres each stair of a slope rises, under a step up (0.35 m).
TileWorld.STAIR = 0.15

local AXES = { vector.create(1, 0, 0), vector.create(0, 1, 0), vector.create(0, 0, 1) }

local function newBox(min: vector, max: vector): Box
	local box: any = { center = (min + max) * 0.5, half = (max - min) * 0.5, axes = AXES }
	box.separating = BoxMath.axes(box)
	return box
end

-- The boxes of a solid: itself, or a slope's stairs, each from where it
-- rises to the slope's head.
local function boxesOf(s: BotNav.Solid): { Box }
	local rise = s.rise
	if rise == nil then
		return { newBox(vector.create(s.x0, s.y0, s.z0), vector.create(s.x1, s.y1, s.z1)) }
	end
	local out = {}
	local n = math.max(math.ceil((s.y1 - s.y0) / TileWorld.STAIR), 1)
	for k = 1, n do
		local top = s.y0 + (s.y1 - s.y0) * k / n
		-- The share of the run, from the foot, where this stair begins.
		local from = (k - 1) / n
		local x0, z0, x1, z1 = s.x0, s.z0, s.x1, s.z1
		if rise == "+x" then
			x0 = s.x0 + (s.x1 - s.x0) * from
		elseif rise == "-x" then
			x1 = s.x1 - (s.x1 - s.x0) * from
		elseif rise == "+z" then
			z0 = s.z0 + (s.z1 - s.z0) * from
		else
			z1 = s.z1 - (s.z1 - s.z0) * from
		end
		table.insert(out, newBox(vector.create(x0, s.y0, z0), vector.create(x1, top, z1)))
	end
	return out
end

-- A world of the body solids (BotNav's) from (x0, z0) to (x1, z1).
function TileWorld.new(solids: { BotNav.Solid }, x0: number, z0: number, x1: number, z1: number)
	local tx, tz = math.ceil((x1 - x0) / TILE) + 1, math.ceil((z1 - z0) / TILE) + 1
	local tiles: { { Box } } = {}
	for k = 1, tx * tz do
		tiles[k] = {}
	end
	local self = setmetatable({ x0 = x0, z0 = z0, tx = tx, tz = tz, tiles = tiles, startTolerance = 0.001 }, TileWorld)
	for _, s in solids do
		if not s.body then
			continue
		end
		for _, box in boxesOf(s) do
			local lo, hi = box.center - box.half, box.center + box.half
			local a0, b0 = self:tileOf(lo.x, lo.z)
			local a1, b1 = self:tileOf(hi.x, hi.z)
			for a = a0, a1 do
				for b = b0, b1 do
					table.insert(tiles[b * tx + a + 1], box)
				end
			end
		end
	end
	return self
end

function TileWorld:tileOf(x: number, z: number): (number, number)
	return math.clamp(math.floor((x - self.x0) / TILE), 0, self.tx - 1), math.clamp(math.floor((z - self.z0) / TILE), 0, self.tz - 1)
end

-- The boxes in the tiles the rectangle round (lo, hi) reaches, each once.
function TileWorld:near(lo: vector, hi: vector): { Box }
	local out = {}
	local seen: { [Box]: boolean } = {}
	local a0, b0 = self:tileOf(lo.x, lo.z)
	local a1, b1 = self:tileOf(hi.x, hi.z)
	for a = a0, a1 do
		for b = b0, b1 do
			for _, box in self.tiles[b * self.tx + a + 1] do
				if not seen[box] then
					seen[box] = true
					table.insert(out, box)
				end
			end
		end
	end
	return out
end

function TileWorld:sweep(center: vector, half: vector, delta: vector): (number?, vector?)
	local reach = half + vector.create(math.abs(delta.x), math.abs(delta.y), math.abs(delta.z)) + vector.one * 0.1
	local best: number? = nil
	local bestNormal: vector? = nil
	for _, box in self:near(center - reach, center + reach) do
		local t, normal = BoxMath.sweep(center, half, delta, box, box.separating, self.startTolerance)
		if t and (best == nil or t < best) then
			best, bestNormal = t, normal
		end
	end
	return best, bestNormal
end

function TileWorld:overlaps(center: vector, half: vector): boolean
	for _, box in self:near(center - half, center + half) do
		if BoxMath.separation(center, half, box, box.separating) < 0 then
			return true
		end
	end
	return false
end

function TileWorld:nearest(center: vector, half: vector, margin: number): (number?, vector?)
	local reach = half + vector.one * (margin + 0.1)
	local best: number?, away: vector? = nil, nil
	for _, box in self:near(center - reach, center + reach) do
		local gap, out = BoxMath.separation(center, half, box, box.separating)
		if gap <= margin and (best == nil or gap < best) then
			best, away = gap, out
		end
	end
	return best, away
end

function TileWorld:clearance(center: vector, half: vector): number
	local reach = half + vector.one * 2
	local best = math.huge
	for _, box in self:near(center - reach, center + reach) do
		best = math.min(best, (BoxMath.separation(center, half, box, box.separating)))
	end
	return best
end

return TileWorld
