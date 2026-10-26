--!strict
-- Phoenix's Blaze (system 32): its run along the floor, from his feet at
-- the cast to where it ends, and the wall of fire that stands on it.
-- AbilitySim says when it's sent out and PlayerSim how long it's bent;
-- this runs it, a tick at a time, from the caster's input:
--   * it starts on the floor under his feet, the way he faces, and runs
--     over the floor at its speed, through walls (Patch 9.10): from its
--     hover over the floor it last found, it looks down for the floor
--     below, so it climbs what's lower than that and goes through what's
--     taller
--   * while the wall's being bent (fire held from the cast on), it turns
--     towards the way the crosshair faces at up to its turn rate; once
--     fire's let go it runs straight on, and fire again doesn't bend it
--   * it's over once it has run its flight, or where it finds no floor
--     within its drop
-- Its path is a point every few ticks (BlazeSim.POINT_TICKS). Where the
-- run ends, the wall rises from his end of it and spreads along it to the
-- far end (BlazeSim.reachAt), and stands for its duration from rising.
-- Whoever stands in it burns (BlazeSim.inside: within half its thickness
-- of the path, no higher above its floor than its height and no further
-- below than its depth), at the same rate wherever in it, allies at a
-- share of an enemy's rate (BlazeSim.burnRate); its caster heals instead
-- (Inner Fire, FireSim.healed). The server runs each one and burns with it
-- (BlazeServer, FireServer), and the caster's client runs its own the same
-- way at once (BlazeView).
--
-- No Roblox APIs here: the world is MovementSim's, so the offline tests run
-- it through a fake one.

local AbilityConfig = require("./AbilityConfig")
local CloudSim = require("./CloudSim")
local Accuracy = require("../Weapons/Accuracy")

export type Run = {
	owner: number, -- the caster's entity id
	id: number, -- the cast's tick, which names it on both ends
	position: vector, -- its head, on the floor, metres
	heading: vector, -- the way it runs: level, a unit vector
	age: number, -- seconds it has run
	ticks: number, -- ticks it has run
	curving: boolean, -- bent since the cast
	points: { vector }, -- its path so far, from his feet: a point every few ticks
	over: boolean, -- it has run its flight, or found no floor
}

-- A wall standing on a run's path: whose, which, the path from his end to
-- the far end, how far along it each point is from his end (metres, level),
-- and when it rose, on its clock (server time on the server).
export type Wall = {
	owner: number,
	id: number,
	points: { vector },
	along: { number },
	start: number,
}

local BlazeSim = {}

local BZ = AbilityConfig.Blaze
local EPS = 1e-9
-- The box the floor is looked for with: thin, as a ray.
local THIN = vector.create(0.01, 0.01, 0.01)
local AHEAD = vector.create(0, 0, -1)

-- Ticks from one point of its path to the next (ours).
BlazeSim.POINT_TICKS = 4
-- The player attribute each caster's last wall is kept in: its far end, on
-- the floor, in metres, for scripted checks.
BlazeSim.LAST_ATTRIBUTE = "VFLastWall"
-- The weapon its burns are, for the kill feed: Blaze's flame.
BlazeSim.WEAPON = "flamewall"

-- How fast it runs: its length over its flight.
function BlazeSim.speed(): number
	return BZ.length.value / BZ.flight.value
end

-- `v` made level, as a unit vector, or nil if it points straight up or down.
local function level(v: vector): vector?
	local flat = vector.create(v.x, 0, v.z)
	local length = vector.magnitude(flat)
	return if length > 1e-6 then flat / length else nil
end

-- The floor under `at`, looked for from its hover over `from` (the floor it
-- last found) down to its drop below that; nil with none. With no world,
-- everything's level at `from`.
function BlazeSim.floorUnder(at: vector, from: number, world: any?): vector?
	if not world then
		return vector.create(at.x, from, at.z)
	end
	local top = from + BZ.hover.value
	local reach = BZ.hover.value + BZ.drop.value
	local fraction: number? = world:sweep(vector.create(at.x, top, at.z), THIN, vector.create(0, -reach, 0))
	if not fraction then
		return nil
	end
	return vector.create(at.x, top - fraction * reach - THIN.y, at.z)
end

-- A wall sent out from `feet` the way `aim` faces, named by the cast's
-- tick `id`. It's over at once with no floor under him.
function BlazeSim.send(owner: number, id: number, feet: vector, aim: vector, world: any?): Run
	local start = BlazeSim.floorUnder(feet, feet.y, world)
	return {
		owner = owner,
		id = id,
		position = start or feet,
		heading = level(aim) or AHEAD,
		age = 0,
		ticks = 0,
		curving = true,
		points = if start then { start } else {},
		over = start == nil,
	}
end

function BlazeSim.copy(r: Run): Run
	local out = table.clone(r)
	out.points = table.clone(r.points)
	return out
end

-- One tick of its run, bent towards `aim` if `bent` keeps it bending.
-- Returns whether it's over.
function BlazeSim.step(r: Run, aim: vector, bent: boolean, dt: number, world: any?): boolean
	if r.over then
		return true
	end
	if not bent then
		r.curving = false
	end
	local want = level(aim)
	if r.curving and want then
		r.heading = level(CloudSim.turn(r.heading, want, math.rad(BZ.turnRate.value) * dt)) or r.heading
	end
	local floor = BlazeSim.floorUnder(r.position + r.heading * (BlazeSim.speed() * dt), r.position.y, world)
	r.ticks += 1
	if not floor then
		-- Nothing below to run on: it ends where it is.
		r.over = true
		local last = r.points[#r.points]
		if last and vector.magnitude(last - r.position) > EPS then
			table.insert(r.points, r.position)
		end
		return true
	end
	r.position = floor
	r.age += dt
	r.over = r.age >= BZ.flight.value - EPS
	if r.over or r.ticks % BlazeSim.POINT_TICKS == 0 then
		table.insert(r.points, floor)
	end
	return r.over
end

-- One of the caster's ticks: each run in `list` goes on with the tick's
-- input, bent if `bent` (the caster's wall still being bent after it),
-- those that are over leave the list, and the tick's walls sent out (its
-- casts) join it, to run from the next tick. Returns those that are over.
function BlazeSim.tick(list: { Run }, owner: number, input: any, casts: { any }?, bent: boolean, dt: number, world: any): { Run }
	local aim = Accuracy.aim(input.yaw, 0)
	local over: { Run } = {}
	local i = 1
	while i <= #list do
		local r = list[i]
		if BlazeSim.step(r, aim, bent, dt, world) then
			table.remove(list, i)
			table.insert(over, r)
		else
			i += 1
		end
	end
	if casts then
		for _, cast in casts do
			if cast.kind == "flame" then
				local r = BlazeSim.send(owner, cast.tick, cast.position, cast.direction, world)
				table.insert(if r.over then over else list, r)
			end
		end
	end
	return over
end

-- One tick for a run nobody bends (its caster dead or gone): straight on.
-- Returns whether it's over.
function BlazeSim.drift(r: Run, dt: number, world: any?): boolean
	return BlazeSim.step(r, r.heading, false, dt, world)
end

-- The wall on a path of `points`, rising at `start`; nil for a path with no
-- length to stand on.
function BlazeSim.wall(owner: number, id: number, points: { vector }, start: number): Wall?
	if #points < 2 then
		return nil
	end
	local along = { 0 }
	for i = 2, #points do
		local d = points[i] - points[i - 1]
		table.insert(along, along[i - 1] + math.sqrt(d.x * d.x + d.z * d.z))
	end
	return { owner = owner, id = id, points = points, along = along, start = start }
end

-- How long it is along its path, level.
function BlazeSim.length(wall: Wall): number
	return wall.along[#wall.along]
end

-- How far along its path from his end it has spread at `t`.
function BlazeSim.reachAt(wall: Wall, t: number): number
	return math.clamp((t - wall.start) * BZ.spreadSpeed.value, 0, BlazeSim.length(wall))
end

-- When the fire reaches `distance` along its path.
function BlazeSim.reachedAt(wall: Wall, distance: number): number
	return wall.start + distance / BZ.spreadSpeed.value
end

-- When it falls.
function BlazeSim.ends(wall: Wall): number
	return wall.start + BZ.duration.value
end

-- Whether it stands at `t`: from rising for its duration.
function BlazeSim.standing(wall: Wall, t: number): boolean
	return t >= wall.start - EPS and t < BlazeSim.ends(wall) - EPS
end

-- Its path as far as the fire has spread at `t`: from his end, the points
-- it has passed, and where it has got to on the stretch it's on (the
-- minimap draws it, system 34). Only his end as it rises; nothing before.
function BlazeSim.spreadPath(wall: Wall, t: number): { vector }
	if t < wall.start - EPS then
		return {}
	end
	local reach = BlazeSim.reachAt(wall, t)
	local out = { wall.points[1] }
	for i = 2, #wall.points do
		local from, to = wall.along[i - 1], wall.along[i]
		if reach >= to - EPS then
			table.insert(out, wall.points[i])
		else
			if reach > from + EPS then
				local a, b = wall.points[i - 1], wall.points[i]
				table.insert(out, a + (b - a) * ((reach - from) / (to - from)))
			end
			break
		end
	end
	return out
end

-- Along segment i (from point i - 1 to point i) as far as the fire has
-- spread, `reach`: the share of it to the closest place to `point`, level,
-- and how far that is, squared. Nil if the fire hasn't reached it.
local function closest(wall: Wall, i: number, reach: number, point: vector): (number?, number)
	local from = wall.along[i - 1]
	if from > reach + EPS then
		return nil, math.huge
	end
	local a, b = wall.points[i - 1], wall.points[i]
	local span = wall.along[i] - from
	local upto = if span > EPS then math.clamp((reach - from) / span, 0, 1) else 1
	local dx, dz = b.x - a.x, b.z - a.z
	local px, pz = point.x - a.x, point.z - a.z
	local length2 = dx * dx + dz * dz
	local u = if length2 > EPS then math.clamp((px * dx + pz * dz) / length2, 0, upto) else 0
	local cx, cz = px - dx * u, pz - dz * u
	return u, cx * cx + cz * cz
end

-- Whether `point` (feet, or an eye) is in the wall at `t`: within half its
-- thickness of its path, pushed out by `pad` (the body's half width, so a
-- body half in it counts), as far as it has spread, no higher above its
-- floor there than its height and no further below than its depth.
function BlazeSim.inside(wall: Wall, point: vector, t: number, pad: number?): boolean
	if not BlazeSim.standing(wall, t) then
		return false
	end
	local reach = BlazeSim.reachAt(wall, t)
	local half = BZ.thickness.value / 2 + (pad or 0)
	for i = 2, #wall.points do
		local u, d2 = closest(wall, i, reach, point)
		if not u then
			break
		end
		if d2 <= half * half + EPS then
			local a, b = wall.points[i - 1], wall.points[i]
			local up = point.y - (a.y + (b.y - a.y) * u)
			if up <= BZ.height.value + EPS and up >= -BZ.depth.value - EPS then
				return true
			end
		end
	end
	return false
end

-- The place on its path closest to `point`, level, as far as it has spread
-- at `t`, on its floor (where its crackle's heard from); nil before it
-- rises.
function BlazeSim.nearest(wall: Wall, point: vector, t: number): vector?
	if t < wall.start - EPS then
		return nil
	end
	local reach = BlazeSim.reachAt(wall, t)
	local best: vector? = nil
	local bestD2 = math.huge
	for i = 2, #wall.points do
		local u, d2 = closest(wall, i, reach, point)
		if not u then
			break
		end
		if d2 < bestD2 then
			local a, b = wall.points[i - 1], wall.points[i]
			best, bestD2 = a + (b - a) * u, d2
		end
	end
	return best
end

-- Health a second it takes from someone standing in it: an enemy's rate,
-- or an ally's share of it.
function BlazeSim.burnRate(ally: boolean): number
	return BZ.burn.value * (if ally then BZ.allyShare.value else 1)
end

return BlazeSim
