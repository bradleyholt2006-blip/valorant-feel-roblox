--!strict
-- Omen's From the Shadows (system 43): where it takes him (ShadowSim.place),
-- and how far he sees as a Shade (ShadowSim.sight).
--   * a place on the map is a point across the floor, as the cursor picks
--     it, with no height: it takes him onto the first floor under it from
--     over the maps' high crates down, if it's level enough to stand on and
--     his standing body fits there (StepSim.fits). So it's a crate's top,
--     but never a wall's or the arena's block
--   * where there's no room for him (a place on a wall, against one or in
--     a corner), the floors round it are tried, the nearer ring first, each
--     its way round, so a place by a wall still takes him
--   * it needs no sight of the place: the map shows him all of it
-- With no floor there, nor room for him round it, there's nowhere.
-- PlayerSim puts him there; this only finds where.
--
-- No Roblox APIs here.

local AbilityConfig = require("./AbilityConfig")
local StepSim = require("./StepSim")
local MovementSim = require("../Movement/MovementSim")

local ShadowSim = {}

local FS = AbilityConfig.FromTheShadows
local DOWN = vector.create(0, -1, 0)
-- The maps' ground, metres: every map's is level with the course's.
ShadowSim.GROUND = 0
-- Half the size of the box that looks down for a floor (ours, as StepSim's).
local THIN = vector.create(0.05, 0.05, 0.05)
-- How many ways round a place with no room for him are tried, on each of
-- its two rings (ours).
ShadowSim.WAYS = 8

-- The floor under `x`, `z` (metres), from `top` over the ground down to
-- `depth` under it, that's level enough to stand on: where his feet would
-- be on it, or nil with none.
local function floorAt(world: MovementSim.World, x: number, z: number, cfg: any): vector?
	local from = vector.create(x, ShadowSim.GROUND + FS.top.value, z)
	local distance = FS.top.value + FS.depth.value
	local fraction, normal = world:sweep(from, THIN, DOWN * distance)
	if not fraction or not normal or normal.y < cfg.minGroundNormalY then
		return nil
	end
	return from + DOWN * (distance * fraction + THIN.y)
end

-- Where he'd stand at `x`, `z`, if he fits there.
local function standing(world: MovementSim.World, x: number, z: number, cfg: any): vector?
	local feet = floorAt(world, x, z, cfg)
	return if feet and StepSim.fits(world, feet, cfg) then feet else nil
end

-- Where a place on the map at `point` (metres; its y unused) takes him
-- through `world`, his body as `cfg` has it: the point on the floor his
-- feet would stand on, or nil with nowhere.
function ShadowSim.place(world: MovementSim.World, point: vector, cfg: any): vector?
	local feet = standing(world, point.x, point.z, cfg)
	if feet then
		return feet
	end
	local nudge = FS.nudge.value
	for _, out in { nudge / 2, nudge } do
		for i = 0, ShadowSim.WAYS - 1 do
			local a = i * 2 * math.pi / ShadowSim.WAYS
			local near = standing(world, point.x + math.cos(a) * out, point.z + math.sin(a) * out, cfg)
			if near then
				return near
			end
		end
	end
	return nil
end

-- How far he sees as a Shade `k` of the way through its time (0 to 1):
-- nothing as it starts, then more and more, faster and faster, to its
-- `sight` as it ends ('the rate of restoration getting quicker towards the
-- end', the VALORANT Wiki). Nil once it's over: he sees as far as anyone.
function ShadowSim.sight(k: number): number?
	if k >= 1 then
		return nil
	end
	local f = math.max(k, 0)
	return FS.sight.value * f * f
end

return ShadowSim
