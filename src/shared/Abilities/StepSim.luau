--!strict
-- Omen's Shrouded Step (system 42): where it takes him (StepSim.place).
--   * where the aim ends: along the crosshair from his eye, no further than
--     its range, short of whatever it meets first. On a floor it's where
--     the crosshair's line meets it; on a wall, a ceiling or nothing at
--     all, it's the floor below where the aim ended, off the wall by his
--     body's half width, so he'd stand clear of it
--   * he steps there if his standing body fits there, from a step's height
--     over the floor up (StepSim.fits): onto a crate's top, a ledge or a
--     stair, but not under a ceiling lower than he stands or into a gap
--     narrower than he is. Where it doesn't, the point's drawn back towards
--     him a little at a time, over the floor there, until it does, so a
--     mark at the foot of a wall or in a corner still takes him
--   * and only if he'd be in sight there: the line from his eye to where
--     his eye would be clear (StepSim.sees, ours for the guides' line of
--     sight), so the aim over a wall too tall to see past, the buy phase's
--     barriers too, takes him nowhere. The floor itself needn't be in
--     sight: Riot's Patch 1.0 gave him an in-world indicator of where he's
--     targeting 'when his vision of the point is obstructed'
--   * and never onto a floor higher over his eye than `above`: the maps'
--     crates, but no wall's top
-- Past the range, through a wall, out of sight, too high or with no floor
-- below, there's nowhere. PlayerSim steps him there; this only finds where.
--
-- No Roblox APIs here.

local AbilityConfig = require("./AbilityConfig")
local BoxMath = require("../Movement/BoxMath")
local MovementSim = require("../Movement/MovementSim")

local StepSim = {}

local SS = AbilityConfig.ShroudedStep
local EPS = 1e-9
local UP = vector.create(0, 1, 0)
local DOWN = vector.create(0, -1, 0)
-- Half the size of the box that looks along the aim and down for a floor:
-- about a crosshair's line (ours, as the Barrier Orb's).
local THIN = vector.create(0.05, 0.05, 0.05)
-- How far short of what the aim meets the floor below is looked for, so
-- it's on this side of a wall the aim meets (ours).
local BACK = 0.1
-- How far in from its sides his body's looked for room, so a wall it only
-- touches isn't in the way (metres, ours).
local GAP = 0.005
-- How far each try draws the point back towards him, and how many tries
-- there are: back as far as he's wide (ours).
StepSim.NUDGE = 0.1
StepSim.TRIES = 7

-- The floor under `from`, within `distance` below it, that's level enough
-- to stand on (`level`, the up of its normal at the least): the point on
-- it, or nil if there's none.
local function floorBelow(world: MovementSim.World, from: vector, distance: number, level: number): vector?
	local fraction, normal = world:sweep(from, THIN, DOWN * distance)
	if not fraction or not normal or normal.y < level then
		return nil
	end
	return from + DOWN * (distance * fraction + THIN.y)
end

-- Whether his standing body, as `cfg` has it, fits with its feet at
-- `feet` (metres), from a step's height over them up: anything lower he'd
-- step onto as he moves.
function StepSim.fits(world: MovementSim.World, feet: vector, cfg: any): boolean
	local low = cfg.stepHeight
	local tall = cfg.standHeight - low
	local half = vector.create(cfg.halfWidth - GAP, tall / 2, cfg.halfWidth - GAP)
	return not world:overlaps(feet + UP * (low + tall / 2), half)
end

-- Whether he'd be in sight from `eye` standing with his feet at `feet`,
-- as `cfg` has him: the line from it to his eye there clear.
function StepSim.sees(world: MovementSim.World, eye: vector, feet: vector, cfg: any): boolean
	local delta = feet + UP * cfg.standEyeHeight - eye
	return vector.magnitude(delta) < EPS or world:sweep(eye, THIN, delta) == nil
end

-- Where the aim ends, from `eye` along the unit `dir` through `world`: the
-- point on the floor under it, or nil with no floor there.
local function aimed(world: MovementSim.World, eye: vector, dir: vector, cfg: any): vector?
	local range = SS.range.value
	local level = cfg.minGroundNormalY
	local fraction, normal = world:sweep(eye, THIN, dir * range)
	local reach = if fraction then range * fraction else range
	if fraction and normal and normal.y >= level then
		-- The aim meets a floor: where the crosshair's line meets the
		-- floor's face, rather than where the box that looked for it
		-- touched it, short of that.
		local face = vector.dot(normal, eye + dir * reach) - BoxMath.aabbReach(THIN, normal)
		local towards = vector.dot(normal, dir)
		local at = if towards < -EPS then (face - vector.dot(normal, eye)) / towards else reach
		return eye + dir * math.max(at, 0)
	end
	local ends = eye + dir * math.max(reach - BACK, 0)
	if fraction and normal then
		-- Off what it met, level, by his half width.
		local off = vector.create(normal.x, 0, normal.z)
		if vector.magnitude(off) > EPS then
			ends += vector.normalize(off) * cfg.halfWidth
		end
	end
	return floorBelow(world, ends, SS.drop.value, level)
end

-- Where the aim from `eye` (metres) along `aim` ends through `world`: no
-- further than the range, short of whatever it meets first. The targeter
-- shows it there with nowhere to step.
function StepSim.ends(world: MovementSim.World, eye: vector, aim: vector): vector
	local dir = vector.normalize(aim)
	local range = SS.range.value
	local fraction = world:sweep(eye, THIN, dir * range)
	return eye + dir * (if fraction then range * fraction else range)
end

-- Whether his feet at `feet` are somewhere a step from `eye` puts him:
-- not too high, with room for him, and in sight.
local function stands(world: MovementSim.World, eye: vector, feet: vector, cfg: any): boolean
	return feet.y <= eye.y + SS.above.value and StepSim.fits(world, feet, cfg) and StepSim.sees(world, eye, feet, cfg)
end

-- Where a step from `eye` (metres) along `aim` takes him through `world`,
-- his body as `cfg` has it: the point on the floor his feet would stand
-- on, or nil with nowhere.
function StepSim.place(world: MovementSim.World, eye: vector, aim: vector, cfg: any): vector?
	local dir = vector.normalize(aim)
	local feet = aimed(world, eye, dir, cfg)
	if not feet then
		return nil
	end
	if stands(world, eye, feet, cfg) then
		return feet
	end
	local flat = vector.create(dir.x, 0, dir.z)
	if vector.magnitude(flat) < EPS then
		return nil
	end
	-- Drawn back towards him, over the floor there: a step's height over or
	-- under where it was.
	local back = -vector.normalize(flat)
	local rise = cfg.stepHeight
	for i = 1, StepSim.TRIES do
		local over = feet + back * (i * StepSim.NUDGE) + UP * rise
		local floor = floorBelow(world, over, rise * 2, cfg.minGroundNormalY)
		if floor and stands(world, eye, floor, cfg) then
			return floor
		end
	end
	return nil
end

return StepSim
