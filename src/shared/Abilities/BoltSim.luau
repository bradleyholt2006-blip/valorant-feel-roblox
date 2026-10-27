--!strict
-- Sova's Recon Bolt (system 44): its bolt in flight, stuck where it lands,
-- and whom its pulses reveal.
--   * loosed from the eye along the crosshair, it flies as Hot Hands'
--     fireball does (FireballSim's keys), at the speed and under the share
--     of the world's gravity its draw's bars give it (AbilityConfig.ReconBolt)
--   * it goes off whatever it meets, a wall, a floor or a ceiling, while it
--     has bounces left, keeping its speed, and sticks to the next thing it
--     meets: its path stops there, with the way that surface faces. Players
--     and dummies don't stop it. One that's flown its air time having met
--     nothing is given up on
--   * stuck, it winds up and pulses, its pulses its interval apart
--     (BoltSim.pulseAt), and it's gone its duration after the first. Each
--     pulse reveals every enemy within its radius it has in sight, looking
--     from just off the surface it's stuck to (BoltSim.eye), with whatever
--     hides them from a player's eye in the way (Sight)
--   * stuck, its shaft stands out of the surface: shots and swings are
--     traced through it (BoltSim.level), and those that strike it take its
--     health
-- Its path is fixed from the loose, so the server flies each one at once
-- and tells every client its keys, as it does the Slow Orb's (SlowServer),
-- and the owner's client flies its own the same way.
--
-- No Roblox APIs here: the world is MovementSim's, so the offline tests fly
-- it through a fake one.

local AbilityConfig = require("./AbilityConfig")
local FireballSim = require("./FireballSim")
local BoxMath = require("../Movement/BoxMath")
local Penetration = require("../Combat/Penetration")

export type Bolt = {
	owner: number, -- the entity id of whoever loosed it
	id: number, -- the tick it was loosed on, which names it on both ends
	bars: number, -- the bars its draw filled, 0 to 3
	left: number, -- the bounces it has left
	position: vector, -- metres
	age: number, -- seconds since the loose
	landed: number?, -- the age it stuck at, once it has
	normal: vector?, -- and the way the surface it's stuck to faces
	keys: { FireballSim.Key },
}

-- A bolt stuck at `point` (metres), the surface there facing `normal`, from
-- `stuck` (server time on both ends), until it's broken, if it is.
export type Stuck = {
	owner: number,
	id: number,
	point: vector,
	normal: vector,
	stuck: number,
	broken: number?,
}

-- A shaft standing in the level shots are traced through.
export type Piece = { box: BoxMath.Box, stuck: Stuck, bolt: boolean }

-- Someone a pulse might reveal: their entity id, and the points of them
-- that count (Sight.points).
export type Target = { id: number, points: { vector } }

local BoltSim = {}

local RC = AbilityConfig.ReconBolt
local EPS = 1e-9
local UP = vector.create(0, 1, 0)
local ACROSS = vector.create(1, 0, 0)
-- How far off a surface it's set after a bounce (ours, as the fireball's).
local MARGIN = 0.01
-- The most it bounces in one tick (into a corner), sticking included.
local TURNS_A_TICK = 4

-- What a shot that strikes a shaft calls the surface (Penetration).
BoltSim.SURFACE = "Recon Bolt"
-- The player attributes that keep, for scripted checks, where the owner's
-- last bolt stuck (metres), the names its last pulse revealed (in order,
-- and "" for nobody) and the health it has left.
BoltSim.STUCK_ATTRIBUTE = "VFLastBolt"
BoltSim.REVEALED_ATTRIBUTE = "VFLastRecon"
BoltSim.HEALTH_ATTRIBUTE = "VFBoltHealth"

-- How fast a bolt drawn to `bars` flies, and how hard it falls (metres a
-- second, and a second).
function BoltSim.speed(bars: number): number
	return RC.speed[math.clamp(bars, 0, RC.bars.value) + 1].value
end

function BoltSim.gravity(bars: number): number
	return RC.gravity[math.clamp(bars, 0, RC.bars.value) + 1].value * RC.worldGravity.value
end

-- A bolt loosed from `origin` (the eye) the way `aim` points, drawn to
-- `bars`, given `bounces`.
function BoltSim.shoot(owner: number, id: number, origin: vector, aim: vector, bars: number, bounces: number): Bolt
	return {
		owner = owner,
		id = id,
		bars = bars,
		left = math.clamp(bounces, 0, RC.bounces.value),
		position = origin,
		age = 0,
		landed = nil,
		normal = nil,
		keys = {
			{ age = 0, position = origin, velocity = vector.normalize(aim) * BoltSim.speed(bars), gravity = BoltSim.gravity(bars) },
		},
	}
end

local function turn(b: Bolt, position: vector, velocity: vector, gravity: number)
	b.position = position
	table.insert(b.keys, { age = b.age, position = position, velocity = velocity, gravity = gravity })
end

-- One tick of flight through `world`, or with none along its path alone.
-- Returns whether it has stuck.
function BoltSim.step(b: Bolt, dt: number, world: any?): boolean
	if b.landed then
		return true
	end
	local size = RC.size.value
	local half = vector.create(size, size, size)
	local left = dt
	local turns = 0
	while left > EPS do
		local key = b.keys[#b.keys]
		local to = FireballSim.along(key, b.age + left)
		local delta = to - b.position
		local fraction: number?, normal: vector? = nil, nil
		if world and turns < TURNS_A_TICK then
			fraction, normal = FireballSim.sweep(world, b.position, half, delta)
		end
		if not fraction or not normal then
			b.position = to
			b.age += left
			break
		end
		local span = left * fraction
		b.age += span
		left -= span
		local at = b.position + delta * fraction
		if b.left <= 0 then
			-- No bounce left: it sticks there.
			b.landed = b.age
			b.normal = normal
			turn(b, at, vector.zero, 0)
			return true
		end
		local v = FireballSim.velocityAt(key, b.age)
		local into = vector.dot(v, normal)
		if into < 0 then
			-- Off the surface as off a mirror, a bounce spent.
			v = (v - normal * (2 * into)) * RC.bounce.value
			b.left -= 1
		end
		turn(b, at + normal * MARGIN, v, key.gravity)
		turns += 1
	end
	return false
end

-- Flies a bolt until it sticks, through `world` (or along its path alone
-- with none), or until it's flown its air time. Returns the age it stuck
-- at, nil if it never did; its keys are then its path.
function BoltSim.fly(b: Bolt, dt: number, world: any?): number?
	local longest = RC.airTime.value
	while not b.landed and b.age < longest - EPS do
		BoltSim.step(b, dt, world)
	end
	return b.landed
end

-- Where a flown bolt is `age` seconds after it was loosed (its keys, from
-- BoltSim.fly or the server); where it stuck from then on.
function BoltSim.at(keys: { FireballSim.Key }, age: number): vector
	return FireballSim.at(keys, age)
end

-- A bolt `owner` loosed on tick `id`, stuck at `point` facing `normal` from
-- server time `stuck`.
function BoltSim.stuck(owner: number, id: number, point: vector, normal: vector, stuck: number): Stuck
	return { owner = owner, id = id, point = point, normal = normal, stuck = stuck, broken = nil }
end

-- When a stuck bolt's `i`th pulse goes, and when it's gone.
function BoltSim.pulseAt(s: Stuck, i: number): number
	return s.stuck + RC.windup.value + (i - 1) * RC.interval.value
end

function BoltSim.ends(s: Stuck): number
	return s.stuck + RC.windup.value + RC.duration.value
end

-- Whether a stuck bolt stands at `t`: stuck by then, not gone, and not
-- broken.
function BoltSim.standing(s: Stuck, t: number): boolean
	local broken = s.broken
	return t >= s.stuck and t < BoltSim.ends(s) and (broken == nil or t < broken)
end

-- Where a stuck bolt looks from: just off the surface it's stuck to.
function BoltSim.eye(s: Stuck): vector
	return s.point + s.normal * RC.lift.value
end

-- Whom a pulse from a bolt stuck as `s` reveals, of `targets`: those with
-- a point within its radius of its eye that `hidden` says nothing hides.
function BoltSim.reveals(s: Stuck, targets: { Target }, hidden: (vector, vector) -> boolean): { number }
	local eye = BoltSim.eye(s)
	local radius = RC.radius.value
	local out = {}
	for _, target in targets do
		for _, point in target.points do
			if vector.magnitude(point - eye) <= radius and not hidden(eye, point) then
				table.insert(out, target.id)
				break
			end
		end
	end
	return out
end

-- The shaft of a stuck bolt: from the surface out along its normal, its
-- length long and its width across.
function BoltSim.box(s: Stuck): BoxMath.Box
	local along = s.normal
	local helper = if math.abs(along.y) < 0.9 then UP else ACROSS
	local side = vector.normalize(vector.cross(along, helper))
	local other = vector.cross(along, side)
	local length, width = RC.length.value, RC.width.value
	return {
		center = s.point + along * (length / 2),
		half = vector.create(length / 2, width / 2, width / 2),
		axes = { along, side, other },
	}
end

-- The piece a shot's surface is on, if it's a shaft's.
function BoltSim.piece(key: any): Piece?
	if type(key) == "table" and key.bolt == true then
		return key :: Piece
	end
	return nil
end

-- The level with shafts in it ------------------------------------------------

local Shot = {}
Shot.__index = Shot

-- `base` with the shafts of `bolts` standing at `t` in it, which shots and
-- swings are traced through: each a "solid" surface, so no bullet gets
-- through one, keyed by its piece. `base` itself when none stand.
function BoltSim.level(base: Penetration.Level, bolts: { Stuck }, t: number): Penetration.Level
	local pieces: { Piece } = {}
	for _, s in bolts do
		if BoltSim.standing(s, t) then
			table.insert(pieces, { box = BoltSim.box(s), stuck = s, bolt = true })
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
		if BoltSim.piece(key) then
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
			best = { distance = distance, normal = normal, material = "solid", name = BoltSim.SURFACE, key = piece }
		end
	end
	return best
end

function Shot:exit(origin: vector, dir: vector, surface: Penetration.Surface, depth: number): (number?, vector?)
	if BoltSim.piece(surface.key) then
		return nil, nil
	end
	return self.base:exit(origin, dir, surface, depth)
end

return BoltSim
