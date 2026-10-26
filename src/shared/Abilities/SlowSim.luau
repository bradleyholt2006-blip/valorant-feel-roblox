--!strict
-- Sage's Slow Orb (system 37): its orb in flight, its field of ice, and
-- whom that slows.
--   * the orb flies as Hot Hands' fireball does (FireballSim), as its own
--     (SlowSim.FLIGHT): at its speed, under its share of the world's
--     gravity, off walls and ceilings, bursting where it meets a floor.
--     It's never lobbed, and has no air time to run out
--   * where it bursts, a field of ice (FireSim's floor of fire, its own
--     shape): it spreads to its radius over its spread time, no further
--     each way round than the walls let it, and lasts its duration from
--     the burst, then is gone at once
--   * everyone standing in it is slowed (SlowSim.slowed: their feet over
--     it, their body half over its edge counting, no higher above its floor
--     than it reaches and no further below than its depth), allies and its
--     thrower too. Slowed, a player's speed along the ground and in the air
--     is held to a share of their run's at once, a jump goes a share lower,
--     and a dash at a share of its speed (SlowSim.SLOW, which MovementSim
--     applies), each tick they start in it and no longer
-- Whether someone's in a field is judged at the server time their screen
-- showed (the input's viewTime), from the same fields on both ends, so the
-- owner's prediction slows them just as the server's simulation does, and
-- a field's in play for a player from when the frame on their screen
-- reaches its burst. The server keeps the fields and tells every client of
-- each as it's thrown (SlowServer), and judges a screen no further behind
-- it than SlowSim.LAG.
--
-- No Roblox APIs here.

local AbilityConfig = require("./AbilityConfig")
local FireballSim = require("./FireballSim")
local FireSim = require("./FireSim")
local MovementSim = require("../Movement/MovementSim")

export type Field = FireSim.Pool

-- The fields in play, and the server time they're judged at.
export type Slows = { fields: { Field }, time: number }

local SlowSim = {}

local SO = AbilityConfig.SlowOrb

-- How the orb flies: never lobbed, with no air time to run out.
SlowSim.FLIGHT = {
	speed = SO.speed,
	gravity = SO.gravity,
	worldGravity = SO.worldGravity,
	size = SO.size,
	bounce = SO.bounce,
	floor = SO.floor,
} :: FireballSim.Flight
-- And the shape of its field.
SlowSim.SHAPE = {
	radius = SO.radius,
	spread = SO.spread,
	duration = SO.duration,
	height = SO.height,
	depth = SO.depth,
	wallHeight = SO.wallHeight,
	floor = SO.floor,
	size = SO.size,
} :: FireSim.Shape
-- What a tick in a field does to movement: the share of speed kept, of a
-- jump's speed (its height goes as the square of it) and of a dash's.
SlowSim.SLOW = {
	speed = 1 - SO.slow.value,
	jump = math.sqrt(1 - SO.jump.value),
	dash = 1 - SO.dash.value,
} :: MovementSim.Slow
-- The furthest behind the server a screen is judged for the slow, in
-- seconds: one further behind is judged as if it were this far (ours,
-- against a screen claiming an old frame to walk through a field; the
-- shots' rewind has its own, tighter limit).
SlowSim.LAG = 1
-- The player attribute each thrower's last field is kept in, as it bursts:
-- the floor under it, in metres, for scripted checks.
SlowSim.LAST_ATTRIBUTE = "VFLastSlow"
-- The player attribute that says whether a player's last tick was slowed,
-- for scripted checks.
SlowSim.SLOWED_ATTRIBUTE = "VFSlowed"

-- A thrown orb, from `origin` (the eye) the way `aim` points.
function SlowSim.throw(owner: number, id: number, origin: vector, aim: vector): FireballSim.Fireball
	return FireballSim.throw(owner, id, origin, aim, false, SlowSim.FLIGHT)
end

-- The floor under an orb that burst at `at`, and how far its field can
-- spread each way round from there, through `world`.
function SlowSim.floorUnder(at: vector): vector
	return FireSim.floorUnder(at, SlowSim.SHAPE)
end

function SlowSim.reaches(centre: vector, world: any?): { number }
	return FireSim.reaches(centre, world, SlowSim.SHAPE)
end

-- The field of an orb `owner` threw on tick `id`, on the floor at `centre`,
-- bursting at `start` (server time on both ends).
function SlowSim.field(owner: number, id: number, centre: vector, start: number, reaches: { number }): Field
	return FireSim.new(owner, id, centre, start, reaches, SlowSim.SHAPE)
end

-- Whether feet at `feet` stand in any of `fields` at `t`, their edges
-- pushed out by `pad` (the body's half width).
function SlowSim.slowed(fields: { Field }, feet: vector, t: number, pad: number?): boolean
	for _, field in fields do
		if FireSim.inside(field, feet, t, pad) then
			return true
		end
	end
	return false
end

-- The time a server judges a screen that showed `viewTime` at, at its own
-- time `now`: no further behind than SlowSim.LAG, and never ahead of it.
function SlowSim.judged(viewTime: number, now: number): number
	return math.clamp(viewTime, now - SlowSim.LAG, now)
end

return SlowSim
