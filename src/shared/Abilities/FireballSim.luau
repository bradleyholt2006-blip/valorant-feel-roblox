--!strict
-- Phoenix's Hot Hands in flight (system 31): from the eye, at the throw, to
-- where it bursts. PlayerSim says when it's thrown and whether it was
-- lobbed; this flies it, a tick at a time:
--   * it goes the way it was thrown, at the throw's speed or the lob's,
--     falling under its share of the world's gravity
--   * it bounces off walls and ceilings, keeping a share of its speed, and
--     bursts where it meets a floor: anything level enough
--     (AbilityConfig.HotHands.floor). Players and dummies don't stop it
--   * once its air time is up it goes nowhere but down, falling under the
--     world's gravity to the floor below
-- Between bounces it falls as anything thrown does, so its path is a few
-- keys: where it was, how fast and how hard it fell from each (the throw,
-- each bounce and the drop) and where it burst. Its path is fixed from the
-- throw, so the server flies each one at once and tells every client its
-- keys, which each draws it from (FireballSim.at), and the thrower's
-- client flies its own the same way. Where it bursts, FireSim's fire
-- burns. Sage's Slow Orb (system 37) flies the same way as its own (a
-- Flight: SlowSim.FLIGHT), with no air time to run out, and where it
-- bursts its field of ice slows.
--
-- No Roblox APIs here: the world is MovementSim's, so the offline tests fly
-- it through a fake one.

local AbilityConfig = require("./AbilityConfig")

-- From `age` seconds after the throw it goes from `position` (metres) at
-- `velocity`, falling at `gravity` metres a second each second.
export type Key = { age: number, position: vector, velocity: vector, gravity: number }

type Param = AbilityConfig.Param

-- How a throw flies (Hot Hands' by default, AbilityConfig.HotHands): this
-- fast thrown, and lobbed if it can be; falling at this share of the
-- world's gravity, for its air time if it has one; the box that flies this
-- big, keeping this much of its speed off a wall; and a surface this level
-- a floor (the up of its normal).
export type Flight = {
	speed: Param,
	lobSpeed: Param?,
	gravity: Param,
	worldGravity: Param,
	airTime: Param?,
	size: Param,
	bounce: Param,
	floor: Param,
}

export type Fireball = {
	owner: number, -- the thrower's entity id
	id: number, -- the tick it was thrown on, which names it on both ends
	lob: boolean, -- thrown underhand (alt fire)
	flight: Flight,
	position: vector, -- metres
	age: number, -- seconds since the throw
	dropping: boolean, -- its air time's up
	landed: number?, -- the age it burst at, once it has
	keys: { Key },
}

local FireballSim = {}

local HH: Flight = AbilityConfig.HotHands
local EPS = 1e-9
local DOWN = vector.create(0, -1, 0)
-- How far off a wall it's set after a bounce, and how far back along its
-- way each sweep starts, so that one ending a tick just short of the floor
-- still finds it the next: Roblox's Blockcast, and the offline tests'
-- world, miss what a sweep starts against (ours).
local MARGIN = 0.01
local BACK = 0.02
-- The most it bounces in one tick (into a corner).
local BOUNCES_A_TICK = 4
-- The longest it flies before it's given up on, having met no floor: fallen
-- out of the level (ours).
FireballSim.LONGEST = 5

-- The longest a throw flying as `flight` says flies before it's given up
-- on: FireballSim.LONGEST, and with no air time to run out (the Slow
-- Orb's), as long again as one thrown straight up takes to come back down
-- to where it was thrown from.
function FireballSim.longest(flight: Flight): number
	if flight.airTime then
		return FireballSim.LONGEST
	end
	return FireballSim.LONGEST + 2 * flight.speed.value / (flight.gravity.value * flight.worldGravity.value)
end

-- A new throw from `origin` (the eye) the way `aim` points, flying as
-- `flight` says (Hot Hands' fireball's by default): lobbed, if `lob` and
-- it can be, underhand at the lob's speed.
function FireballSim.throw(owner: number, id: number, origin: vector, aim: vector, lob: boolean, flight: Flight?): Fireball
	local f = flight or HH
	local lobSpeed = f.lobSpeed
	local lobbed = lob and lobSpeed ~= nil
	local speed = if lobbed and lobSpeed then lobSpeed.value else f.speed.value
	return {
		owner = owner,
		id = id,
		lob = lobbed,
		flight = f,
		position = origin,
		age = 0,
		dropping = false,
		landed = nil,
		keys = {
			{
				age = 0,
				position = origin,
				velocity = vector.normalize(aim) * speed,
				gravity = f.gravity.value * f.worldGravity.value,
			},
		},
	}
end

-- Where a key's fall has it at `age` (seconds after the throw), and how fast
-- it's going there.
function FireballSim.along(key: Key, age: number): vector
	local t = math.max(age - key.age, 0)
	return key.position + key.velocity * t + DOWN * (0.5 * key.gravity * t * t)
end

function FireballSim.velocityAt(key: Key, age: number): vector
	return key.velocity + DOWN * (key.gravity * math.max(age - key.age, 0))
end

-- Where a flown throw is `age` seconds after it was thrown (its keys, from
-- FireballSim.fly or the server); where it burst from then on.
function FireballSim.at(keys: { Key }, age: number): vector
	local key = keys[1]
	for i = 2, #keys do
		if keys[i].age > age then
			break
		end
		key = keys[i]
	end
	return FireballSim.along(key, age)
end

-- The share of `delta` a box `half` its half size goes from `from` before
-- it meets the world, and the way what it meets faces, if it meets
-- anything (the Recon Bolt's too, BoltSim).
function FireballSim.sweep(world: any, from: vector, half: vector, delta: vector): (number?, vector?)
	local length = vector.magnitude(delta)
	if length < EPS then
		return nil, nil
	end
	local way = delta / length
	local fraction, normal = world:sweep(from - way * BACK, half, delta + way * BACK)
	if not fraction then
		return nil, nil
	end
	return math.max(fraction * (length + BACK) - BACK, 0) / length, normal
end

local function turn(f: Fireball, position: vector, velocity: vector, gravity: number)
	f.position = position
	table.insert(f.keys, { age = f.age, position = position, velocity = velocity, gravity = gravity })
end

-- One tick of flight through `world`, or with none along its path alone.
-- Returns whether it has burst.
function FireballSim.step(f: Fireball, dt: number, world: any?): boolean
	if f.landed then
		return true
	end
	-- Its air time up, if it has one: it stops going anywhere but down,
	-- under the world's gravity.
	local flight = f.flight
	local airTime = flight.airTime
	if airTime and not f.dropping and f.age >= airTime.value - EPS then
		f.dropping = true
		local v = FireballSim.velocityAt(f.keys[#f.keys], f.age)
		turn(f, f.position, vector.create(0, math.min(v.y, 0), 0), flight.worldGravity.value)
	end
	local size = flight.size.value
	local half = vector.create(size, size, size)
	local left = dt
	local bounces = 0
	while left > EPS do
		local key = f.keys[#f.keys]
		local to = FireballSim.along(key, f.age + left)
		local delta = to - f.position
		local fraction: number?, normal: vector? = nil, nil
		if world and bounces < BOUNCES_A_TICK then
			fraction, normal = FireballSim.sweep(world, f.position, half, delta)
		end
		if not fraction or not normal then
			f.position = to
			f.age += left
			break
		end
		local span = left * fraction
		f.age += span
		left -= span
		local at = f.position + delta * fraction
		if normal.y >= flight.floor.value then
			-- A floor: it bursts there.
			f.landed = f.age
			turn(f, at, vector.zero, 0)
			return true
		end
		local v = FireballSim.velocityAt(key, f.age)
		local into = vector.dot(v, normal)
		if into < 0 then
			if f.dropping then
				-- Dropping, it slides down whatever's too steep to burst on.
				v -= normal * into
			else
				-- Off a wall or a ceiling, it keeps a share of its speed.
				v = (v - normal * (2 * into)) * flight.bounce.value
			end
		end
		turn(f, at + normal * MARGIN, v, key.gravity)
		bounces += 1
	end
	return false
end

-- Flies a throw until it bursts, through `world` (or along its path alone
-- with none), or until it's flown the longest it may. Returns the age it
-- burst at, nil if it never did; its keys are then its path.
function FireballSim.fly(f: Fireball, dt: number, world: any?): number?
	local longest = FireballSim.longest(f.flight)
	while not f.landed and f.age < longest - EPS do
		FireballSim.step(f, dt, world)
	end
	return f.landed
end

return FireballSim
