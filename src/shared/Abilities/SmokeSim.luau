--!strict
-- Omen's Dark Cover (system 40): its mark, where its smoke goes, the orb's
-- flight there, and the smoke.
--
-- With the orb in hand, its mark lies along the crosshair from the eye, its
-- reach away, through walls (Patch 1.0: he 'can see through walls to place
-- his smokes'). The kit keeps the reach (AbilitySim): as the orb comes into
-- hand, where the crosshair meets the level, but no further than its start;
-- then held fire sends it further and held alt fire brings it closer,
-- within its reach.
--
-- The smoke goes on the floor under the mark, looked for straight down
-- within its depth. A mark inside the level is first brought back along the
-- crosshair until it's out, and the smoke falls on through a floor too steep
-- to stand on to one it can stand on (the VALORANT Wiki: one placed inside
-- walls falls to the ground nearby, and one falls until it's over standable
-- ground). With no floor there, it goes nowhere.
--
-- Sent, the orb flies straight from the eye to the smoke at its speed,
-- unseen and through anything in its way, and the smoke grows there to its
-- radius, stands its duration from then, warns that it's going near its
-- end, and goes at once.
--
-- No Roblox APIs here: the world is MovementSim's, so the offline tests
-- place smokes in a fake one.

local AbilityConfig = require("./AbilityConfig")
local MovementSim = require("../Movement/MovementSim")

-- A smoke: its thrower's entity id, the tick it was thrown on (which names
-- it on both ends), the middle of the floor it stands on (metres), and
-- when it formed, the orb there (server time).
export type Smoke = { owner: number, id: number, centre: vector, at: number }

local SmokeSim = {}

local DC = AbilityConfig.DarkCover
local EPS = 1e-9
-- Half of the little box the level's looked for with (metres).
local PROBE = vector.create(0.05, 0.05, 0.05)
-- How far back along the crosshair a mark inside the level is brought at a
-- time (metres, ours).
local STEP = 0.25
-- The least up a floor that holds a smoke has, about 45 degrees, as the
-- Barrier Orb's (ours).
local STANDABLE = 0.7
-- How far above the mark the floor's looked for from, so a mark touching a
-- floor (as it starts where the crosshair meets one) finds it: Roblox's
-- casts pass through anything they start touching (metres).
local LIFT = 2 * PROBE.y
-- How far into a floor too steep to hold it the smoke's looked for again
-- from: the box's height and a little more, so the next look starts inside
-- it or past it, and passes through it as Roblox's casts do (metres).
local SINK = 2 * PROBE.y + 0.01

-- The reach kept within its nearest and furthest.
function SmokeSim.clamp(reach: number): number
	return math.clamp(reach, DC.near.value, DC.reach.value)
end

-- Where the mark starts as the orb comes into hand, from `eye` the way
-- `aim` (a unit vector) points: where the crosshair meets the level, no
-- further than its start.
function SmokeSim.start(world: MovementSim.World, eye: vector, aim: vector): number
	local most = DC.start.value
	local fraction = world:sweep(eye, PROBE, aim * most)
	return SmokeSim.clamp(if fraction then most * fraction else most)
end

-- The reach after `dt` seconds of held fire (`further`) or alt fire.
function SmokeSim.moved(reach: number, further: boolean, dt: number): number
	local step = DC.push.value * dt
	return SmokeSim.clamp(reach + (if further then step else -step))
end

-- The mark: `reach` along the crosshair from the eye.
function SmokeSim.mark(eye: vector, aim: vector, reach: number): vector
	return eye + aim * SmokeSim.clamp(reach)
end

-- Where a smoke from a mark `reach` along the crosshair goes: the middle of
-- the floor it stands on, or nil for nowhere.
function SmokeSim.place(world: MovementSim.World, eye: vector, aim: vector, reach: number): vector?
	local along = SmokeSim.clamp(reach)
	local point = eye + aim * along
	while world:overlaps(point, PROBE) do
		along -= STEP
		if along <= 0 then
			return nil
		end
		point = eye + aim * along
	end
	point += vector.create(0, LIFT, 0)
	local left = DC.depth.value + LIFT
	while left > 0 do
		local fraction, normal = world:sweep(point, PROBE, vector.create(0, -left, 0))
		if not fraction or not normal then
			return nil
		end
		local fell = left * fraction
		if normal.y >= STANDABLE then
			return vector.create(point.x, point.y - fell - PROBE.y, point.z)
		end
		point -= vector.create(0, fell + SINK, 0)
		left -= fell + SINK
	end
	return nil
end

-- How long the orb flies from `eye` to a smoke at `centre` (seconds).
function SmokeSim.flight(eye: vector, centre: vector): number
	return vector.magnitude(centre - eye) / DC.speed.value
end

-- How wide a smoke is `age` seconds after it formed: growing over its grow
-- time, quickly at first, then whole, and nothing once it's gone.
function SmokeSim.radiusAt(age: number): number
	if age < 0 or age >= DC.duration.value then
		return 0
	end
	local grow = DC.grow.value
	if age >= grow then
		return DC.radius.value
	end
	local k = 1 - age / grow
	return DC.radius.value * (1 - k * k)
end

-- Whether a smoke `age` seconds after it formed is warning that it's going.
function SmokeSim.warning(age: number): boolean
	return age >= DC.duration.value - DC.warn.value - EPS and age < DC.duration.value
end

return SmokeSim
