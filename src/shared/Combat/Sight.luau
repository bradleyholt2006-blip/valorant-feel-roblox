--!strict
-- Who sees whom (system 34), for the minimap: an enemy shows on it while
-- anyone on your side has them in view, "visible to you or a teammate"
-- (ludo.guide), detected as they appear "in their vision cone"
-- (Sportskeeda), the cone each teammate's view draws on the minimap. And
-- what's out of sight isn't: Riot fixed "teleport abilities can reveal an
-- Agent's out-of-sight minimap location" (Patch 6.07).
--
-- A viewer sees a point when it's on their screen, in the reference's view
-- 103 degrees across at 16:9, and nothing is in the way: the level (what
-- `blocked` says, which sees through the spawns' barriers), a cloud (Jett's
-- Cloudburst, "a brief vision-blocking cloud", system 18), a wall of fire
-- (Phoenix's Blaze, "a wall of fire that blocks vision", system 32) or a
-- wall of ice (Sage's Barrier Orb, system 38, BarrierSim.hides). A body is
-- seen when any of three points of it is: the middle of its head, its body
-- and its legs (Hitboxes). Nobody else is in the way of anyone: the level,
-- clouds and walls are. A viewer who's nearsighted (Omen's Paranoia,
-- system 41) sees nothing further away than their vision's range.
--
-- No Roblox APIs here: the server passes its level in as `blocked`, so the
-- offline tests run it on a fake one.

local BlazeSim = require("../Abilities/BlazeSim")
local BarrierSim = require("../Abilities/BarrierSim")
local AbilityConfig = require("../Abilities/AbilityConfig")
local Hitboxes = require("./Hitboxes")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

-- Someone looking: their side, their eye and the way it looks (a unit
-- vector), all in metres, and how far they see, if not forever.
export type Viewer = { side: number, eye: vector, look: vector, range: number? }
-- Someone who can be seen: their entity id, their side and the points of
-- them that count.
export type Target = { id: number, side: number, points: { vector } }
export type Cloud = { centre: vector, radius: number }
-- What's in the way at `time`: clouds standing, walls of fire, walls of
-- ice (none without), and the level, as `blocked`, true when something of
-- it is between two points.
export type Occluders = {
	clouds: { Cloud },
	walls: { BlazeSim.Wall },
	barriers: { BarrierSim.Wall }?,
	time: number,
	blocked: (from: vector, to: vector) -> boolean,
}

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local Sight = {}

local EPS = 1e-9
local UP = vector.create(0, 1, 0)
local BZ = AbilityConfig.Blaze

Sight.Params = {
	fov = p(103, "community", "Degrees across the view: the reference's fixed horizontal FOV (CameraController)"),
	aspect = p(16 / 9, "estimate", "The screen the view's height is judged on: the reference's 103 degrees are across a 16:9 screen"),
}

-- tan of half the view's width and height.
local function halfTans(): (number, number)
	local across = math.tan(math.rad(Sight.Params.fov.value) / 2)
	return across, across / Sight.Params.aspect.value
end

-- Whether `point` is on the screen of an eye at `eye` looking along
-- `look` (a unit vector): ahead of it, within half the view's width to
-- either side and half its height above and below, as the camera has it
-- (yawed, then pitched).
function Sight.inView(eye: vector, look: vector, point: vector): boolean
	local d = point - eye
	local ahead = vector.dot(d, look)
	if ahead <= EPS then
		return false
	end
	local side = vector.cross(look, UP)
	local length = vector.magnitude(side)
	if length < 1e-6 then
		-- Straight up or down: the right is anywhere level.
		side = vector.create(1, 0, 0)
	else
		side = side / length
	end
	local up = vector.cross(side, look)
	local across, high = halfTans()
	return math.abs(vector.dot(d, side)) <= ahead * across + EPS and math.abs(vector.dot(d, up)) <= ahead * high + EPS
end

-- Whether a cloud is in the way from `a` to `b`: the line between them
-- passes inside it, or either end is in it.
function Sight.cloudHides(cloud: Cloud, a: vector, b: vector): boolean
	if cloud.radius <= 0 then
		return false
	end
	local ab = b - a
	local length2 = vector.dot(ab, ab)
	local u = if length2 > EPS then math.clamp(vector.dot(cloud.centre - a, ab) / length2, 0, 1) else 0
	local closest = a + ab * u
	return vector.magnitude(cloud.centre - closest) < cloud.radius
end

-- Whether a wall of fire standing at `t` is in the way from `a` to `b`:
-- the line between them crosses its path, as far as the fire has spread,
-- between its depth under the floor and its height over it, or either end
-- is in it.
function Sight.wallHides(wall: BlazeSim.Wall, t: number, a: vector, b: vector): boolean
	if not BlazeSim.standing(wall, t) then
		return false
	end
	if BlazeSim.inside(wall, a, t) or BlazeSim.inside(wall, b, t) then
		return true
	end
	local reach = BlazeSim.reachAt(wall, t)
	local rx, rz = b.x - a.x, b.z - a.z
	for i = 2, #wall.points do
		local from = wall.along[i - 1]
		if from > reach + EPS then
			break
		end
		local span = wall.along[i] - from
		local upto = if span > EPS then math.clamp((reach - from) / span, 0, 1) else 1
		local p0, p1 = wall.points[i - 1], wall.points[i]
		local sx, sz = (p1.x - p0.x) * upto, (p1.z - p0.z) * upto
		-- Where the two cross, seen from above: s along the sight line, u
		-- along the wall's stretch.
		local cross = rx * sz - rz * sx
		if math.abs(cross) > EPS then
			local qx, qz = p0.x - a.x, p0.z - a.z
			local s = (qx * sz - qz * sx) / cross
			local u = (qx * rz - qz * rx) / cross
			if s >= 0 and s <= 1 and u >= 0 and u <= 1 then
				local y = a.y + (b.y - a.y) * s
				local floor = p0.y + (p1.y - p0.y) * u * upto
				if y <= floor + BZ.height.value + EPS and y >= floor - BZ.depth.value - EPS then
					return true
				end
			end
		end
	end
	return false
end

-- Whether anything is in the way from `a` to `b`: a cloud or a wall first,
-- which is only maths, then the level.
function Sight.hidden(a: vector, b: vector, o: Occluders): boolean
	for _, cloud in o.clouds do
		if Sight.cloudHides(cloud, a, b) then
			return true
		end
	end
	for _, wall in o.walls do
		if Sight.wallHides(wall, o.time, a, b) then
			return true
		end
	end
	local barriers = o.barriers
	if barriers and BarrierSim.hides(barriers, o.time, a, b) then
		return true
	end
	return o.blocked(a, b)
end

-- Whether a viewer sees any of `points`.
function Sight.sees(viewer: Viewer, points: { vector }, o: Occluders): boolean
	local range = viewer.range
	for _, point in points do
		if range and vector.magnitude(point - viewer.eye) > range then
			continue
		end
		if Sight.inView(viewer.eye, viewer.look, point) and not Sight.hidden(viewer.eye, point, o) then
			return true
		end
	end
	return false
end

-- The points of a body that count: the middles of its head, its body and
-- its legs, standing or crouched as it is.
function Sight.points(pose: Hitboxes.Pose): { vector }
	local out = {}
	for _, box in Hitboxes.build(pose) do
		table.insert(out, box.center)
	end
	return out
end

-- Who each side sees: by side, the ids of the targets on other sides that
-- anyone on it sees. A side that sees nobody has no entry.
function Sight.spotted(viewers: { Viewer }, targets: { Target }, o: Occluders): { [number]: { [number]: boolean } }
	local out: { [number]: { [number]: boolean } } = {}
	for _, target in targets do
		for _, viewer in viewers do
			if viewer.side == target.side then
				continue
			end
			local seen: { [number]: boolean } = out[viewer.side] or {}
			if not seen[target.id] and Sight.sees(viewer, target.points, o) then
				seen[target.id] = true
				out[viewer.side] = seen
			end
		end
	end
	return out
end

-- Whether anyone on `side` sees `point` (the spike on the ground).
function Sight.sideSees(viewers: { Viewer }, side: number, point: vector, o: Occluders): boolean
	for _, viewer in viewers do
		if viewer.side == side and Sight.sees(viewer, { point }, o) then
			return true
		end
	end
	return false
end

return Sight
