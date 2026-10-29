--!strict
-- Rotations for the agents' bodies (system 63), as unit quaternions: a
-- vector part and a number. The pose is worked out in plain Luau so the
-- offline tests run it as the game does; BodyView turns each rotation into
-- a CFrame for the rig's bones.

export type Quat = { v: vector, w: number }

local Quat = {}

local X = vector.create(1, 0, 0)
local Y = vector.create(0, 1, 0)
local Z = vector.create(0, 0, 1)

local function q(v: vector, w: number): Quat
	return { v = v, w = w }
end

Quat.new = q

Quat.IDENTITY = table.freeze(q(vector.zero, 1))

-- A turn of `angle` radians about a unit axis (right-handed).
function Quat.axisAngle(axis: vector, angle: number): Quat
	local h = angle * 0.5
	return q(axis * math.sin(h), math.cos(h))
end

function Quat.aboutX(angle: number): Quat
	return Quat.axisAngle(X, angle)
end

function Quat.aboutY(angle: number): Quat
	return Quat.axisAngle(Y, angle)
end

function Quat.aboutZ(angle: number): Quat
	return Quat.axisAngle(Z, angle)
end

-- b, then a: the order CFrames multiply in.
function Quat.mul(a: Quat, b: Quat): Quat
	return q(b.v * a.w + a.v * b.w + vector.cross(a.v, b.v), a.w * b.w - vector.dot(a.v, b.v))
end

function Quat.conj(a: Quat): Quat
	return q(-a.v, a.w)
end

function Quat.rotate(a: Quat, p: vector): vector
	local t = vector.cross(a.v, p) * 2
	return p + t * a.w + vector.cross(a.v, t)
end

function Quat.normalize(a: Quat): Quat
	local n = math.sqrt(vector.dot(a.v, a.v) + a.w * a.w)
	if n < 1e-9 then
		return Quat.IDENTITY
	end
	return q(a.v / n, a.w / n)
end

-- The shortest turn taking unit vector a onto unit vector b.
function Quat.fromTo(a: vector, b: vector): Quat
	local d = vector.dot(a, b)
	if d < -0.999999 then
		local axis = vector.cross(X, a)
		if vector.magnitude(axis) < 1e-6 then
			axis = vector.cross(Y, a)
		end
		return Quat.axisAngle(vector.normalize(axis), math.pi)
	end
	return Quat.normalize(q(vector.cross(a, b), 1 + d))
end

-- The turn taking the axes X, Y and Z onto x, y and z, an orthonormal
-- right-handed set.
function Quat.fromAxes(x: vector, y: vector, z: vector): Quat
	local trace = x.x + y.y + z.z
	if trace > 0 then
		local s = math.sqrt(trace + 1) * 2
		return Quat.normalize(q(vector.create(y.z - z.y, z.x - x.z, x.y - y.x) / s, 0.25 * s))
	elseif x.x > y.y and x.x > z.z then
		local s = math.sqrt(1 + x.x - y.y - z.z) * 2
		return Quat.normalize(q(vector.create(0.25 * s, (y.x + x.y) / s, (z.x + x.z) / s), (y.z - z.y) / s))
	elseif y.y > z.z then
		local s = math.sqrt(1 + y.y - x.x - z.z) * 2
		return Quat.normalize(q(vector.create((y.x + x.y) / s, 0.25 * s, (z.y + y.z) / s), (z.x - x.z) / s))
	end
	local s = math.sqrt(1 + z.z - x.x - y.y) * 2
	return Quat.normalize(q(vector.create((z.x + x.z) / s, (z.y + y.z) / s, 0.25 * s), (x.y - y.x) / s))
end

-- The turn taking one frame onto another, each given as a unit vector and
-- a second vector (made square to the first).
function Quat.between(fromA: vector, fromB: vector, toA: vector, toB: vector): Quat
	local fb = vector.normalize(fromB - fromA * vector.dot(fromB, fromA))
	local tb = vector.normalize(toB - toA * vector.dot(toB, toA))
	local from = Quat.fromAxes(fromA, fb, vector.cross(fromA, fb))
	local to = Quat.fromAxes(toA, tb, vector.cross(toA, tb))
	return Quat.mul(to, Quat.conj(from))
end

-- Part way from a to b, the shorter way round (normalised lerp).
function Quat.nlerp(a: Quat, b: Quat, t: number): Quat
	local sign = if vector.dot(a.v, b.v) + a.w * b.w < 0 then -1 else 1
	return Quat.normalize(q(a.v * (1 - t) + b.v * (t * sign), a.w * (1 - t) + b.w * (t * sign)))
end

-- A fraction of a turn, about the same axis (the shorter way round).
function Quat.scale(a: Quat, t: number): Quat
	local sign = if a.w < 0 then -1 else 1
	local half = math.acos(math.clamp(a.w * sign, -1, 1))
	local s = math.sin(half)
	if s < 1e-7 then
		return Quat.IDENTITY
	end
	return Quat.axisAngle(a.v * (sign / s), 2 * half * t)
end

-- The part of a turn that is about a unit axis (its twist; the rest is
-- the swing that tips the axis).
function Quat.twist(a: Quat, axis: vector): Quat
	local p = axis * vector.dot(a.v, axis)
	local n = math.sqrt(vector.dot(p, p) + a.w * a.w)
	if n < 1e-9 then
		return Quat.IDENTITY
	end
	return q(p / n, a.w / n)
end

-- How far a turn turns, radians (0 to pi).
function Quat.angle(a: Quat): number
	return 2 * math.atan2(vector.magnitude(a.v), math.abs(a.w))
end

return Quat
