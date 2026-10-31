--!strict
-- Reyna's Leer (system 74): the eye's flight, when it nearsights, whom it
-- nearsights, and the eye in the level shots are traced through.
--
-- Cast, the eye flies from her eye along the crosshair, through the walls
-- and ceilings in its way (SteelSeries' guide: 'It can travel through
-- walls (like Omen) for a short distance'), at the pace that takes its
-- travel over its windup, and hangs where it gets to. A floor in its way
-- stops it short, and it rests on that (LeerSim.reach; valoranttracker.org:
-- 'it will travel a fixed distance of ten meters away unless thrown on the
-- ground'), so its path is known from the cast. From its windup's end it's
-- open (LeerSim.open): for its duration, any enemy who looks at it is
-- nearsighted (Liquipedia: 'The eye will nearsight all enemies who look at
-- it'), and then it goes.
--
-- Looking at it is having it within the cone of where they look, at any
-- distance (Patch 5.07: 'Range Restriction on Leer removed'), with nothing
-- between that hides it from them, which the server asks Sight. Each look
-- runs their nearsight on (LeerSim.nearsight): whole while they look and
-- its linger after, then clearing over its fade, kept on the same
-- attribute as Paranoia's (ParanoiaSim.ATTRIBUTE), so they see as little,
-- but without Paranoia's deafening.
--
-- In the world, from the cast, the eye stands in the level shots and
-- swings are traced through (LeerSim.level): a box its size across round
-- its middle, a "solid" surface, so no bullet gets through it, and those
-- that strike it take its health until it breaks.
--
-- No Roblox APIs here: the world is MovementSim's, so the offline tests
-- cast it through a map's own solids.

local AbilityConfig = require("./AbilityConfig")
local ParanoiaSim = require("./ParanoiaSim")
local BoxMath = require("../Movement/BoxMath")
local MovementConfig = require("../Movement/MovementConfig")
local MovementSim = require("../Movement/MovementSim")
local Penetration = require("../Combat/Penetration")

-- An eye cast: its caster's entity id, the tick it was cast on (which
-- names it on both ends), when (server time), where it starts (her eye,
-- metres), the way it goes (a unit vector) and how far (metres); and when
-- it was broken, if it was.
export type Eye = { owner: number, id: number, at: number, start: vector, way: vector, travel: number, broken: number? }

-- An eye standing in the level shots are traced through.
export type Piece = { box: BoxMath.Box, eye: Eye, leer: boolean }

local LeerSim = {}

local LE = AbilityConfig.Leer
local EPS = 1e-9
local AXES = { vector.create(1, 0, 0), vector.create(0, 1, 0), vector.create(0, 0, 1) }
-- What stops it: a surface facing up no steeper than can be walked
-- (MovementConfig's maxGroundAngle), met from above.
local FLOOR = math.cos(math.rad(MovementConfig.Params.maxGroundAngle.value))
local STEP = 0.05 -- metres it's moved on at a time through what it's in

-- What a shot that strikes an eye calls the surface (Penetration).
LeerSim.SURFACE = "Leer"
-- The player attributes that keep, for scripted checks, where the caster's
-- last eye came to rest (metres), the health it has left, and the names of
-- those it nearsighted, in the order it did ("" for nobody), once it's
-- gone.
LeerSim.LAST_ATTRIBUTE = "VFLastLeer"
LeerSim.HEALTH_ATTRIBUTE = "VFLeerHealth"
LeerSim.LEERED_ATTRIBUTE = "VFLastLeered"

-- An eye cast at server time `at` from `eye` the way `aim` points, to fly
-- `travel` metres (LeerSim.reach), its whole travel if that's not given.
function LeerSim.cast(owner: number, id: number, at: number, eye: vector, aim: vector, travel: number?): Eye
	local most = LE.travel.value
	return {
		owner = owner,
		id = id,
		at = at,
		start = eye,
		way = vector.normalize(aim),
		travel = math.clamp(travel or most, 0, most),
		broken = nil,
	}
end

-- How far an eye cast from `eye` the way `aim` points flies through
-- `world`: its travel, on through every wall and ceiling, but no further
-- than the first floor it meets from above, where it comes to rest on it,
-- its size clear of it.
function LeerSim.reach(world: MovementSim.World, eye: vector, aim: vector): number
	local way = vector.normalize(aim)
	local most = LE.travel.value
	local half = LE.size.value / 2
	local box = vector.create(half, half, half)
	local along = 0
	while along < most do
		-- On through whatever it's in, until it's clear of it: a sweep may
		-- not see what it starts inside.
		local entered = along
		while along < most and world:overlaps(eye + way * along, box) do
			along += STEP
		end
		if along > entered and way.y < -EPS then
			-- Come out lower than it went in: if there's a floor over where
			-- it came out, it went into it from inside what it went through
			-- (a wall's foot), and rests on it where it reached it.
			local a, b = eye + way * entered, eye + way * math.min(along, most)
			local over = vector.create(b.x, a.y, b.z)
			if not world:overlaps(over, box) then
				local fraction, normal = world:sweep(over, box, vector.create(0, b.y - a.y, 0))
				if fraction and normal and normal.y >= FLOOR then
					local middle = a.y + (b.y - a.y) * fraction
					return math.clamp((eye.y - middle) / -way.y, entered, along)
				end
			end
		end
		if along >= most then
			break
		end
		local fraction, normal = world:sweep(eye + way * along, box, way * (most - along))
		if not fraction then
			break
		end
		local met = along + (most - along) * fraction
		if normal and normal.y >= FLOOR then
			return met
		end
		along = met + STEP
	end
	return most
end

-- Where an eye's middle is `age` seconds after it was cast: its start
-- then, flying on at the pace that takes its travel over its windup until
-- it's flown as far as it goes, and there from then on.
function LeerSim.at(e: Eye, age: number): vector
	local k = math.clamp(age / LE.windup.value, 0, 1)
	return e.start + e.way * math.min(LE.travel.value * k, e.travel)
end

-- Where an eye comes to rest.
function LeerSim.rest(e: Eye): vector
	return LeerSim.at(e, math.huge)
end

-- When an eye opens, starting to nearsight, and when it goes (server
-- time).
function LeerSim.opens(e: Eye): number
	return e.at + LE.windup.value
end

function LeerSim.ends(e: Eye): number
	return LeerSim.opens(e) + LE.duration.value
end

-- Whether an eye is in the world at `t`: cast by then, not gone, and not
-- broken.
function LeerSim.standing(e: Eye, t: number): boolean
	local broken = e.broken
	return t >= e.at and t < LeerSim.ends(e) and (broken == nil or t < broken)
end

-- Whether an eye nearsights at `t`: in the world, and open.
function LeerSim.open(e: Eye, t: number): boolean
	return LeerSim.standing(e, t) and t >= LeerSim.opens(e)
end

-- Whether someone whose eye is at `from`, looking the way `look` points (a
-- unit vector), has an eye whose middle is at `at` in their cone, however
-- far: what hides it from them is the server's to ask.
function LeerSim.looks(at: vector, from: vector, look: vector): boolean
	local to = at - from
	local d = vector.magnitude(to)
	if d < EPS then
		return true
	end
	return vector.dot(to / d, look) >= math.cos(math.rad(LE.cone.value)) - EPS
end

-- The nearsight of someone looking at an open eye at `now`, over `old`,
-- what's left of theirs: whole from now for its linger, then clearing over
-- its fade. Nil while `old` is whole for at least half its linger yet, so
-- it isn't sent again every frame.
function LeerSim.nearsight(old: ParanoiaSim.Nearsight?, now: number): ParanoiaSim.Nearsight?
	if old and old.from <= now and old.full - now >= LE.linger.value / 2 then
		return nil
	end
	return ParanoiaSim.nearsight(old, now, LE.linger.value, LE.fade.value)
end

-- An eye as it stands in the level at `t`: its size across, round where its
-- middle is then.
function LeerSim.box(e: Eye, t: number): BoxMath.Box
	local half = LE.size.value / 2
	return { center = LeerSim.at(e, t - e.at), half = vector.create(half, half, half), axes = AXES }
end

-- The piece a shot's surface is on, if it's an eye's.
function LeerSim.piece(key: any): Piece?
	if type(key) == "table" and key.leer == true then
		return key :: Piece
	end
	return nil
end

-- The level with eyes in it --------------------------------------------------

local Shot = {}
Shot.__index = Shot

-- `base` with the eyes of `eyes` standing at `t` in it, which shots and
-- swings are traced through: each a "solid" surface, so no bullet gets
-- through one, keyed by its piece. `base` itself when none stand.
function LeerSim.level(base: Penetration.Level, eyes: { Eye }, t: number): Penetration.Level
	local pieces: { Piece } = {}
	for _, e in eyes do
		if LeerSim.standing(e, t) then
			table.insert(pieces, { box = LeerSim.box(e, t), eye = e, leer = true })
		end
	end
	if #pieces == 0 then
		return base
	end
	return (setmetatable({ base = base, pieces = pieces }, Shot) :: any) :: Penetration.Level
end

function Shot:cast(origin: vector, dir: vector, maxDistance: number, skip: { any }): Penetration.Surface?
	-- The level's own pieces go to it; it knows nothing of these.
	local rest: { any } = {}
	local passed: { [any]: boolean } = {}
	for _, key in skip do
		if LeerSim.piece(key) then
			passed[key] = true
		else
			table.insert(rest, key)
		end
	end
	local best: Penetration.Surface? = self.base:cast(origin, dir, maxDistance, rest)
	for _, piece in self.pieces do
		if passed[piece] then
			continue
		end
		local distance, normal = BoxMath.ray(origin, dir, maxDistance, piece.box)
		if distance and normal and (best == nil or distance < best.distance) then
			best = { distance = distance, normal = normal, material = "solid", name = LeerSim.SURFACE, key = piece }
		end
	end
	return best
end

function Shot:exit(origin: vector, dir: vector, surface: Penetration.Surface, depth: number): (number?, vector?)
	if LeerSim.piece(surface.key) then
		return nil, nil
	end
	return self.base:exit(origin, dir, surface, depth)
end

return LeerSim
