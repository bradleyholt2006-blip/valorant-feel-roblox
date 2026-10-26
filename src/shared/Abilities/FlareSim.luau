--!strict
-- Phoenix's Curveball in flight (system 30): from the eye, at the throw, to
-- where it pops, and the blind it gives. PlayerSim says when it's thrown
-- and which way round; this flies it, a tick at a time:
--   * it goes the way it was thrown at its speed, with no drop
--   * after a moment it turns to that side, a quarter turn round the
--     vertical, and goes on straight
--   * it stops where it meets the level (players and dummies don't stop
--     it), and waits there
--   * it pops its windup after the throw, wherever it is
-- Its path is fixed from the throw, so the server flies each one at once
-- and tells every client where it stops and pops, and the thrower's client
-- flies its own the same way. The pop blinds whoever can see it, by how
-- they face it and how far off they are (FlareSim.strength). A blind is a
-- white screen and then its fade (FlareSim.blind), kept as a player
-- attribute in server time (FlareSim.BLIND_ATTRIBUTE).
--
-- No Roblox APIs here: the world is MovementSim's, so the offline tests fly
-- it through a fake one.

local AbilityConfig = require("./AbilityConfig")

export type Flare = {
	owner: number, -- the thrower's entity id
	id: number, -- the tick it was thrown on, which names it on both ends
	position: vector, -- metres
	velocity: vector,
	curve: number, -- -1 round to the left, 1 to the right
	turned: number, -- radians it has turned so far
	age: number, -- seconds since the throw
	stopped: number?, -- the age it met the level at, if it has
}

-- A blind, in server time: since when, until when the screen is white, and
-- until when any of it is left.
export type Blind = { from: number, full: number, gone: number }

local FlareSim = {}

local CV = AbilityConfig.Curveball
local EPS = 1e-9
-- The box a sight line to the pop is swept with: thin, as a ray.
local SIGHT = vector.create(0.01, 0.01, 0.01)

-- The player attribute each blind is kept in: its from, full and gone, in
-- server time ("812.500,814.000,815.000"), unset with none.
FlareSim.BLIND_ATTRIBUTE = "VFBlind"

-- A new throw from `origin` (the eye) the way `aim` points, curving round
-- to the left for a negative `curve` and to the right for a positive one.
function FlareSim.throw(owner: number, id: number, origin: vector, aim: vector, curve: number): Flare
	return {
		owner = owner,
		id = id,
		position = origin,
		velocity = vector.normalize(aim) * CV.speed.value,
		curve = if curve < 0 then -1 else 1,
		turned = 0,
		age = 0,
		stopped = nil,
	}
end

function FlareSim.copy(f: Flare): Flare
	return table.clone(f)
end

-- `v` turned round the vertical by `angle` radians: to the right for a
-- positive angle, seen from above (yaw 0 looks down -Z, and right is +X).
function FlareSim.turn(v: vector, angle: number): vector
	local c, s = math.cos(angle), math.sin(angle)
	return vector.create(v.x * c - v.z * s, v.y, v.x * s + v.z * c)
end

-- One tick of flight. With `world`, it stops where it meets the level;
-- with `stop` instead, it stops that many seconds after the throw, as the
-- server said it did; with neither, it flies its path alone. Returns
-- whether it has popped.
function FlareSim.step(f: Flare, dt: number, world: any?, stop: number?): boolean
	if f.stopped == nil then
		local most = math.rad(CV.turn.value)
		if f.age >= CV.straight.value - EPS and f.turned < most - EPS then
			local angle = math.min(math.rad(CV.turnRate.value) * dt, most - f.turned)
			-- Its speed set afresh, so a vector's single precision can't wear
			-- it down turn by turn.
			f.velocity = vector.normalize(FlareSim.turn(f.velocity, angle * f.curve)) * CV.speed.value
			f.turned += angle
		end
		local delta = f.velocity * dt
		local fraction: number? = nil
		if stop then
			if f.age + dt >= stop - EPS then
				fraction = math.clamp((stop - f.age) / dt, 0, 1)
			end
		elseif world then
			local half = vector.create(CV.size.value, CV.size.value, CV.size.value)
			fraction = world:sweep(f.position, half, delta)
		end
		if fraction then
			f.position += delta * fraction
			f.stopped = f.age + dt * fraction
		else
			f.position += delta
		end
	end
	f.age += dt
	return f.age >= CV.windup.value - EPS
end

-- Flies a throw to its pop (`world` and `stop` as for step): where it is
-- at each of its ticks, from the throw's to the pop's, for FlareSim.at.
function FlareSim.fly(f: Flare, dt: number, world: any?, stop: number?): { vector }
	local path = { f.position }
	local popped = false
	while not popped do
		popped = FlareSim.step(f, dt, world, stop)
		table.insert(path, f.position)
	end
	return path
end

-- Where a flown throw is `age` seconds after it was thrown, between its
-- ticks (its path from FlareSim.fly); at the pop's place from then on.
function FlareSim.at(path: { vector }, age: number, dt: number): vector
	local k = math.clamp(age / dt, 0, #path - 1)
	local i = math.floor(k)
	local a = path[i + 1]
	local b = path[math.min(i + 2, #path)]
	return a + (b - a) * (k - i)
end

-- The seconds from the throw to the pop: the windup, on the tick it ends.
function FlareSim.popTime(dt: number): number
	return math.ceil(CV.windup.value / dt - 1e-6) * dt
end

-- Whether an eye at `eye` can see a pop at `pop`: nothing of the level in
-- between. Clouds don't hide it, and nor does anyone in the way (ours).
function FlareSim.seen(pop: vector, eye: vector, world: any): boolean
	local delta = pop - eye
	if vector.magnitude(delta) < 1e-6 then
		return true
	end
	return world:sweep(eye, SIGHT, delta) == nil
end

-- The share of the longest blind for a pop `angle` degrees off the view:
-- all of it within fullAngle, falling to the away share at edgeAngle, and
-- that share behind.
function FlareSim.facing(angle: number): number
	local full, edge, away = CV.fullAngle.value, CV.edgeAngle.value, CV.away.value
	if angle <= full then
		return 1
	elseif angle >= edge then
		return away
	end
	return 1 - (1 - away) * (angle - full) / (edge - full)
end

-- The share of it for a pop `distance` metres away: all of it out to near,
-- falling to none at far.
function FlareSim.falloff(distance: number): number
	local near, far = CV.near.value, CV.far.value
	if distance <= near then
		return 1
	elseif distance >= far then
		return 0
	end
	return 1 - (distance - near) / (far - near)
end

-- How much a pop at `pop` blinds an eye at `eye` that can see it, looking
-- along `look` (a unit vector): 0 to 1 of the longest blind, by how far
-- the pop is off the view and how far away; under the least, none.
function FlareSim.strength(pop: vector, eye: vector, look: vector): number
	local to = pop - eye
	local distance = vector.magnitude(to)
	local facing = 1
	if distance > 1e-6 then
		local angle = math.deg(math.acos(math.clamp(vector.dot(look, to / distance), -1, 1)))
		facing = FlareSim.facing(angle)
	end
	local strength = facing * FlareSim.falloff(distance)
	return if strength < CV.least.value then 0 else strength
end

-- A blind of `strength` (0 to 1) given at `now`, over `old` if any of that
-- is left: white for its share of the longest, then clearing over that
-- share of the fade. The later white and the later clear win.
function FlareSim.blind(old: Blind?, now: number, strength: number): Blind
	local full = now + strength * CV.maxBlind.value
	local gone = full + strength * CV.fade.value
	if old and old.gone > now then
		if old.full >= full then
			return { from = old.from, full = old.full, gone = math.max(old.gone, gone) }
		end
		return { from = now, full = full, gone = math.max(old.gone, gone) }
	end
	return { from = now, full = full, gone = gone }
end

-- How white a blind leaves the screen at `t` (server time), 0 to 1: all of
-- it until its white is over, then less and less until it's gone.
function FlareSim.whiteAt(b: Blind, t: number): number
	if t >= b.gone then
		return 0
	elseif t < b.full then
		return 1
	end
	return 1 - (t - b.full) / math.max(b.gone - b.full, EPS)
end

-- A blind as its attribute keeps it, and back.
function FlareSim.encode(b: Blind): string
	return string.format("%.3f,%.3f,%.3f", b.from, b.full, b.gone)
end

function FlareSim.decode(text: any): Blind?
	if type(text) ~= "string" then
		return nil
	end
	local a, b, c = string.match(text, "^([^,]+),([^,]+),([^,]+)$")
	local from, full, gone = tonumber(a), tonumber(b), tonumber(c)
	if not from or not full or not gone then
		return nil
	end
	return { from = from, full = full, gone = gone }
end

return FlareSim
