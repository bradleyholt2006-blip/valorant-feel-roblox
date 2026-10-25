--!strict
-- Jett's Cloudburst in flight (system 18): from the eye, at the throw, to
-- where it bursts into a cloud. AbilitySim says when it's thrown; this flies
-- it, a tick at a time, from the thrower's input:
--   * it goes straight at its speed, with no drop
--   * while C is held from the throw on, it turns towards the crosshair at
--     up to its turn rate. Once C is let go, it flies straight on, and
--     holding C again doesn't steer it
--   * it bursts where it hits the level (players and dummies don't stop
--     it), or where it is once it has flown its longest
-- The server flies each throw and says where it burst; the thrower's
-- client flies its own the same way at once, from the same inputs, so its
-- cloud forms where the server's will. A throw whose thrower is dead or
-- gone flies straight on by itself.
--
-- No Roblox APIs here: the world is MovementSim's, so the offline tests fly
-- it through a fake one.

local AbilityConfig = require("./AbilityConfig")
local MovementSim = require("../Movement/MovementSim")
local Accuracy = require("../Weapons/Accuracy")

export type Projectile = {
	owner: number, -- the thrower's entity id
	id: number, -- the tick it was thrown on, which names it on both ends
	position: vector, -- metres
	velocity: vector,
	age: number, -- seconds it has flown
	curving: boolean, -- C held since the throw
}

-- A throw that burst: where, and after how long in the air.
export type Burst = { owner: number, id: number, position: vector, age: number }

local CloudSim = {}

local CB = AbilityConfig.Cloudburst
local EPS = 1e-9

-- A new throw from `origin` (the eye) the way `aim` points.
function CloudSim.throw(owner: number, id: number, origin: vector, aim: vector): Projectile
	return {
		owner = owner,
		id = id,
		position = origin,
		velocity = vector.normalize(aim) * CB.speed.value,
		age = 0,
		curving = true,
	}
end

function CloudSim.copy(p: Projectile): Projectile
	return table.clone(p)
end

-- `dir` turned towards `aim` (both unit vectors) by at most `angle`
-- radians, along the shortest way.
function CloudSim.turn(dir: vector, aim: vector, angle: number): vector
	local between = math.acos(math.clamp(vector.dot(dir, aim), -1, 1))
	if between <= angle then
		return aim
	end
	local s = math.sin(between)
	if s < 1e-6 then
		return dir -- straight behind: no way is shorter
	end
	return (dir * math.sin(between - angle) + aim * math.sin(angle)) / s
end

-- One tick of flight, steered towards `aim` if `held` keeps it curving.
-- Returns where it burst, if it did on this tick.
function CloudSim.step(p: Projectile, aim: vector, held: boolean, dt: number, world: any): vector?
	if not held then
		p.curving = false
	end
	if p.curving then
		-- Its speed set afresh, so a vector's single precision can't wear
		-- it down turn by turn.
		p.velocity = CloudSim.turn(vector.normalize(p.velocity), aim, math.rad(CB.turnRate.value) * dt) * CB.speed.value
	end
	local delta = p.velocity * dt
	local half = vector.create(CB.size.value, CB.size.value, CB.size.value)
	local fraction: number? = world:sweep(p.position, half, delta)
	if fraction then
		p.position += delta * fraction
		p.age += dt * fraction
		return p.position
	end
	p.position += delta
	p.age += dt
	if p.age >= CB.maxFlight.value - EPS then
		return p.position
	end
	return nil
end

-- One of the thrower's ticks: each throw in `list` flies on with the tick's
-- input, those that burst leave the list, and the tick's throws (its
-- casts) join it, to fly from the next tick. Returns the bursts.
function CloudSim.tick(list: { Projectile }, owner: number, input: any, casts: { any }?, dt: number, world: any): { Burst }
	local aim = Accuracy.aim(input.yaw, input.pitch)
	local held = MovementSim.has(input.buttons, MovementSim.Buttons.AbilityC)
	local bursts: { Burst } = {}
	local i = 1
	while i <= #list do
		local p = list[i]
		local at = CloudSim.step(p, aim, held, dt, world)
		if at then
			table.remove(list, i)
			table.insert(bursts, { owner = p.owner, id = p.id, position = at, age = p.age })
		else
			i += 1
		end
	end
	if casts then
		for _, cast in casts do
			if cast.kind == "throw" then
				table.insert(list, CloudSim.throw(owner, cast.tick, cast.origin, cast.direction))
			end
		end
	end
	return bursts
end

-- One tick for a throw nobody steers (its thrower dead or gone): straight
-- on. Returns where it burst, if it did.
function CloudSim.drift(p: Projectile, dt: number, world: any): vector?
	return CloudSim.step(p, vector.normalize(p.velocity), false, dt, world)
end

-- The cloud's radius `age` seconds after it burst: growing to its full size
-- over its first moments, eased, then full until it goes. 0 once it's gone.
function CloudSim.radiusAt(age: number): number
	if age < 0 or age >= CB.duration.value then
		return 0
	end
	local grow = CB.grow.value
	if age >= grow then
		return CB.radius.value
	end
	local k = 1 - age / grow
	return CB.radius.value * (1 - k * k)
end

-- How thick the cloud is `age` seconds after it burst, 0 to 1: whole
-- until its last moments, then thinning to nothing.
function CloudSim.thicknessAt(age: number): number
	local duration, fade = CB.duration.value, CB.fade.value
	if age < 0 or age >= duration then
		return 0
	end
	return math.clamp((duration - age) / fade, 0, 1)
end

-- Whether `point` is inside a cloud at `centre` that's `age` seconds old.
function CloudSim.inside(centre: vector, age: number, point: vector): boolean
	local r = CloudSim.radiusAt(age)
	return r > 0 and vector.magnitude(point - centre) < r
end

return CloudSim
