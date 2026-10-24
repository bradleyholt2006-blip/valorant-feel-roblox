--!strict
-- Analytic hitboxes and ray tests, shared by client and server.
--
-- Every character is three yaw-oriented boxes (head, body, legs) built from a
-- pose (feet position, yaw, crouch). Using math instead of Roblox parts means
-- the server can rebuild a target exactly as it was at any past time from a
-- recorded pose, which is what lag compensation needs, and it means the
-- client's guess and the server's verdict come from the same code.
--
-- Sizes are estimates in metres (docs/research/02-weapon-firing.md). Riot's
-- server runs animation for hitboxes; ours are unanimated boxes, like the
-- "non-animated hitbox" in Riot's 128-tick article.

export type Region = "head" | "body" | "legs"

export type Pose = {
	position: vector, -- feet, metres
	yaw: number,
	crouchAlpha: number,
}

export type Box = {
	region: Region,
	center: vector,
	half: vector,
	yaw: number,
}

export type Hit = {
	region: Region,
	distance: number, -- metres along the ray
	point: vector,
}

type Shape = { region: Region, centerY: number, half: vector }

local STAND: { Shape } = {
	{ region = "head", centerY = 1.62, half = vector.create(0.12, 0.13, 0.12) },
	{ region = "body", centerY = 1.17, half = vector.create(0.22, 0.32, 0.14) },
	{ region = "legs", centerY = 0.425, half = vector.create(0.17, 0.425, 0.13) },
}

local CROUCH: { Shape } = {
	{ region = "head", centerY = 1.10, half = vector.create(0.12, 0.13, 0.12) },
	{ region = "body", centerY = 0.76, half = vector.create(0.22, 0.22, 0.17) },
	{ region = "legs", centerY = 0.27, half = vector.create(0.19, 0.27, 0.2) },
}

local Hitboxes = {}

-- Region priority when boxes overlap at the same distance: head wins.
local PRIORITY: { [Region]: number } = { head = 3, body = 2, legs = 1 }

function Hitboxes.build(pose: Pose): { Box }
	local a = math.clamp(pose.crouchAlpha, 0, 1)
	local boxes = table.create(3)
	for i, s in STAND do
		local c = CROUCH[i]
		local y = s.centerY + (c.centerY - s.centerY) * a
		table.insert(boxes, {
			region = s.region,
			center = pose.position + vector.create(0, y, 0),
			half = s.half + (c.half - s.half) * a,
			yaw = pose.yaw,
		})
	end
	return boxes
end

-- Rotates v about +Y by -yaw (world -> box local space).
local function toLocal(v: vector, yaw: number): vector
	local c, s = math.cos(yaw), math.sin(yaw)
	return vector.create(v.x * c - v.z * s, v.y, v.x * s + v.z * c)
end

-- Ray (origin, unit dir) vs one oriented box. Returns entry distance or nil.
function Hitboxes.rayBox(origin: vector, dir: vector, box: Box, maxDistance: number): number?
	local o = toLocal(origin - box.center, box.yaw)
	local d = toLocal(dir, box.yaw)
	local tMin, tMax = 0, maxDistance
	for _, axis in { "x", "y", "z" } do
		local oa = (o :: any)[axis] :: number
		local da = (d :: any)[axis] :: number
		local h = (box.half :: any)[axis] :: number
		if math.abs(da) < 1e-12 then
			if oa < -h or oa > h then
				return nil
			end
		else
			local t1, t2 = (-h - oa) / da, (h - oa) / da
			if t1 > t2 then
				t1, t2 = t2, t1
			end
			tMin = math.max(tMin, t1)
			tMax = math.min(tMax, t2)
			if tMin > tMax then
				return nil
			end
		end
	end
	return tMin
end

-- Nearest hit on a set of boxes within maxDistance, or nil.
function Hitboxes.raycast(origin: vector, dir: vector, boxes: { Box }, maxDistance: number): Hit?
	local best: Hit? = nil
	for _, box in boxes do
		local t = Hitboxes.rayBox(origin, dir, box, maxDistance)
		if t then
			local current = best
			if current == nil or t < current.distance - 1e-6 or (math.abs(t - current.distance) <= 1e-6 and PRIORITY[box.region] > PRIORITY[current.region]) then
				best = { region = box.region, distance = t, point = origin + dir * t }
			end
		end
	end
	return best
end

-- Unit view direction from yaw/pitch (Roblox convention: yaw 0 looks down -Z).
function Hitboxes.direction(yaw: number, pitch: number): vector
	local cp = math.cos(pitch)
	return vector.create(-math.sin(yaw) * cp, math.sin(pitch), -math.cos(yaw) * cp)
end

-- Bounding radius around the feet, for cheap rejection before box tests.
Hitboxes.BOUND_RADIUS = 1.2

return Hitboxes
