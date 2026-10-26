--!strict
-- Phoenix's Hot Hands fire (system 31): where its fireball burst
-- (FireballSim), fire on the floor.
--   * it spreads from the burst to its radius over its spread time, no
--     further each way round than the walls let it (FireSim.reaches: the
--     first wall at the height one stops it, so a step doesn't and a crate
--     does), and burns for its duration from the burst, then is gone at once
--   * whoever stands in it burns (FireSim.inside: their feet over it, no
--     higher above its floor than it reaches and no further below than its
--     depth), at the same rate wherever in it they stand, a point at a time
--     as the reference's does; an ally at a share of an enemy's rate
--     (FireSim.burnRate)
--   * its thrower, Phoenix, heals instead (his passive, Inner Fire): his
--     first touch of each fire starts a heal of its own, a point at a time
--     until it's all given, which goes on if he leaves the fire
--     (FireSim.healed). His Blaze's wall (system 32, BlazeSim) heals him
--     the same way, at its own pace
-- The server keeps the fires and burns with them, and tells every client of
-- each as it's thrown, which draws it the same way (FireSim.edge).
--
-- No Roblox APIs here: the world is MovementSim's, so the offline tests
-- burn through a fake one.

local AbilityConfig = require("./AbilityConfig")

export type Pool = {
	owner: number, -- the thrower's entity id
	id: number, -- the throw's tick, which names it on both ends
	centre: vector, -- the floor under the burst, metres
	start: number, -- when it burst, on its clock (server time on the server)
	reaches: { number }, -- how far it can spread each way round, metres, by sector
}

-- What a fire owes someone, kept from one server frame to the next: what's
-- not been given yet (points, and a part of one), and when some last was.
export type Owed = { points: number, given: number }

local FireSim = {}

local HH = AbilityConfig.HotHands
local IF = AbilityConfig.InnerFire
local EPS = 1e-9
local TAU = 2 * math.pi
-- The box a wall is looked for with: thin, as a ray.
local THIN = vector.create(0.01, 0.01, 0.01)

-- The ways round it spreads, each a sector of the circle: the more, the
-- closer it follows a wall (ours).
FireSim.SECTORS = 24
-- The player attribute each thrower's last fire is kept in: where it burst,
-- the floor under it, in metres, for scripted checks.
FireSim.LAST_ATTRIBUTE = "VFLastFire"
-- The weapon its burns are, for the kill feed: Hot Hands' fireball.
FireSim.WEAPON = "fireball"

-- The way out from the centre along sector i's first side (i from 1).
function FireSim.direction(i: number): vector
	local angle = (i - 1) * TAU / FireSim.SECTORS
	return vector.create(math.cos(angle), 0, math.sin(angle))
end

-- The floor under a fireball that burst at `at` (the middle of the box
-- that flew, resting on it).
function FireSim.floorUnder(at: vector): vector
	return at - vector.create(0, HH.size.value, 0)
end

-- How far a fire at `centre` can spread along each sector's first side: its
-- radius, or as far as the first wall at the height one stops it. What's
-- level enough to burst on (a ramp up) doesn't stop it.
function FireSim.reaches(centre: vector, world: any?): { number }
	local out = table.create(FireSim.SECTORS, HH.radius.value)
	if not world then
		return out
	end
	local from = centre + vector.create(0, HH.wallHeight.value, 0)
	for i = 1, FireSim.SECTORS do
		local fraction, normal = world:sweep(from, THIN, FireSim.direction(i) * HH.radius.value)
		if fraction and not (normal and normal.y >= HH.floor.value) then
			out[i] = fraction * HH.radius.value
		end
	end
	return out
end

function FireSim.new(owner: number, id: number, centre: vector, start: number, reaches: { number }): Pool
	return { owner = owner, id = id, centre = centre, start = start, reaches = reaches }
end

-- How far a fire has spread at `t`: nothing at the burst, all its radius
-- from the end of its spread time.
function FireSim.radiusAt(pool: Pool, t: number): number
	return HH.radius.value * math.clamp((t - pool.start) / HH.spread.value, 0, 1)
end

-- Whether a fire burns at `t`: from the burst for its duration.
function FireSim.burning(pool: Pool, t: number): boolean
	return t >= pool.start - EPS and t < pool.start + HH.duration.value - EPS
end

-- When a fire's out.
function FireSim.ends(pool: Pool): number
	return pool.start + HH.duration.value
end

-- How far it reaches along sector i's first side, spread out to `r`.
local function reachAt(pool: Pool, i: number, r: number): number
	return math.min(pool.reaches[i] or r, r)
end

-- The fire's edge at `t`, for drawing it: a point along each sector's first
-- side, from the first, as far out as it has spread there (metres).
function FireSim.edge(pool: Pool, t: number): { vector }
	local r = FireSim.radiusAt(pool, t)
	local out = table.create(FireSim.SECTORS)
	for i = 1, FireSim.SECTORS do
		out[i] = pool.centre + FireSim.direction(i) * reachAt(pool, i, r)
	end
	return out
end

-- Whether feet at `feet` stand in a fire at `t`: over it, its edge pushed
-- out by `pad` all round (the body's half width, so a body half over it
-- counts), no higher above its floor than it reaches and no further below
-- than its depth. Between two sides, its edge runs straight from one to
-- the next.
function FireSim.inside(pool: Pool, feet: vector, t: number, pad: number?): boolean
	if not FireSim.burning(pool, t) then
		return false
	end
	local d = feet - pool.centre
	if d.y > HH.height.value + EPS or d.y < -HH.depth.value - EPS then
		return false
	end
	local grow = pad or 0
	local r = FireSim.radiusAt(pool, t)
	local x, z = d.x, d.z
	local distance = math.sqrt(x * x + z * z)
	if distance > r + grow + EPS then
		return false
	elseif distance < EPS then
		return r + grow > 0
	end
	local i = math.floor((math.atan2(z, x) % TAU) / TAU * FireSim.SECTORS) % FireSim.SECTORS + 1
	local j = i % FireSim.SECTORS + 1
	local a = FireSim.direction(i) * (reachAt(pool, i, r) + grow)
	local b = FireSim.direction(j) * (reachAt(pool, j, r) + grow)
	-- (x, z) as s of a and u of b: in the triangle from the centre to the two
	-- when neither is less than none and together they're no more than one.
	local det = a.x * b.z - a.z * b.x
	if math.abs(det) < EPS then
		return false
	end
	local s = (x * b.z - z * b.x) / det
	local u = (a.x * z - a.z * x) / det
	return s >= -EPS and u >= -EPS and s + u <= 1 + EPS
end

-- Health a second a fire takes from someone standing in it: an enemy's
-- rate, or an ally's share of it.
function FireSim.burnRate(ally: boolean): number
	return HH.burn.value * (if ally then HH.allyShare.value else 1)
end

-- The points Inner Fire has given `elapsed` seconds after Phoenix first
-- touched a fire: one at the end of each of its intervals (`every`
-- seconds, Hot Hands' by default), all of them by the end of the last.
function FireSim.healed(elapsed: number, every: number?): number
	return math.clamp(math.floor(elapsed / (every or IF.hotHandsEvery.value) + 1e-6), 0, IF.heal.value)
end

-- How long a heal takes to give all of it, a point every `every` seconds
-- (Hot Hands' by default).
function FireSim.healTime(every: number?): number
	return IF.heal.value * (every or IF.hotHandsEvery.value)
end

function FireSim.owed(): Owed
	return { points = 0, given = -math.huge }
end

-- `amount` more owed at `now`, and the whole points to give now, if any:
-- none until `every` seconds after the last were given, so they go a few
-- at a time.
function FireSim.owe(o: Owed, amount: number, now: number, every: number): number
	o.points += amount
	if now - o.given < every - EPS then
		return 0
	end
	local whole = math.floor(o.points + 1e-6)
	if whole <= 0 then
		return 0
	end
	o.points -= whole
	o.given = now
	return whole
end

return FireSim
