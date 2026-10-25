--!strict
-- Where a bullet goes: firing error (spread), recoil and recovery.
--
-- Pure maths on WeaponConfig values, shared by the weapon simulation (which
-- calls it once per shot) and the client's debug tools and camera kick.
-- Angles are degrees unless a name says otherwise.
--
-- The model, from Riot's patch notes (docs/research/03-spread-recoil.md):
--
--   * Each shot gets a bullet number in the current spray. The Gun Recovery
--     Time counts from the moment the gun can fire again: firing as soon as
--     it can carries the spray on, waiting part of the recovery time
--     recovers part of the spray, and tap efficiency sets how fast that
--     happens. Waiting the whole time makes the next shot a first shot again.
--   * The cone of fire is the firing error curve at that bullet number (the
--     zoomed curve when aiming down sights or scoped, times a percentage
--     crouched), plus a movement error for the movement state, plus the jump
--     landing penalty. Each bullet lands at a random point in the cone,
--     biased toward the centre when standing still ("error power"). A
--     shotgun's pellets each land at their own point in the same cone.
--   * Recoil moves the cone's centre: up by the recoil curve at the bullet
--     number, and, after the first few bullets, sideways in a drift that
--     changes direction at random.
--
-- Randomness comes from a hash of (seed, shot number), so client prediction
-- and the server draw exactly the same bullets.

local WeaponConfig = require("./WeaponConfig")

export type MoveState = "still" | "walk" | "run" | "crouch" | "air"

-- What the shooter is doing on the tick a shot fires (PlayerSim builds it).
export type Context = {
	moveState: MoveState,
	crouched: boolean,
	landing: boolean, -- within the jump landing penalty
}

-- How the cone of one shot was put together, for the debug tools.
export type Cone = {
	radius: number,
	curve: number, -- firing error at this bullet before modifiers (the zoomed curve when zoomed)
	crouchMultiplier: number,
	movement: number,
	landing: number,
	power: number, -- error power used to place the bullet in the cone
}

local Accuracy = {}

local TAU = 2 * math.pi
local MAX_PITCH = math.rad(89.9)

-- Curves ---------------------------------------------------------------------

-- Piecewise-linear lookup, flat beyond the ends.
function Accuracy.curve(points: WeaponConfig.Curve, x: number): number
	local first = points[1]
	if x <= first[1] then
		return first[2]
	end
	for i = 2, #points do
		local b = points[i]
		if x <= b[1] then
			local a = points[i - 1]
			return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1])
		end
	end
	return points[#points][2]
end

-- Recovery -------------------------------------------------------------------

-- Share of the spray left when a shot fires `sinceReady` seconds after the
-- gun could fire again (1 = all of it, 0 = fully recovered). A trigger that
-- keeps up with the gun (held, or a click on the first tick it's ready)
-- recovers nothing; after that the spray falls away over the recovery time,
-- faster the higher the tap efficiency.
--
-- Counting from readiness rather than from the last shot is what makes a
-- slow gun's recovery mean anything: the Outlaw fires every 0.36 s, so a
-- recovery of 0.15 s counted from the shot would always be over before it
-- could fire again, and Patch 13.01's change to it (0.1 >>> 0.15, with
-- spread and recoil after the first shot) would do nothing.
--
-- The result is rounded to 1/65536: `^` comes from the C maths library,
-- which may differ in the last bit between the client's and the server's
-- machines, and this value feeds simulation state that both must agree on.
function Accuracy.recoveryFactor(acc: WeaponConfig.AccuracyDef, sinceReady: number, dt: number): number
	if sinceReady < dt - 1e-9 then
		return 1
	end
	local recovery = acc.recoveryTime.value
	if sinceReady >= recovery then
		return 0
	end
	local left = (1 - sinceReady / recovery) ^ acc.tapEfficiency.value
	return math.floor(left * 65536 + 0.5) / 65536
end

-- Cone of fire ----------------------------------------------------------------

function Accuracy.movementError(acc: WeaponConfig.AccuracyDef, state: MoveState): number
	if state == "run" then
		return acc.runError.value
	elseif state == "walk" then
		return acc.walkError.value
	elseif state == "crouch" then
		return acc.crouchMoveError.value
	elseif state == "air" then
		return acc.airError.value
	end
	return 0
end

-- The cone for a shot with this bullet number, from the accuracy of the
-- mode it fires in (WeaponConfig.mode), with its own landing penalty if it
-- has one.
function Accuracy.cone(acc: WeaponConfig.AccuracyDef, ctx: Context, bullet: number): Cone
	local raw = Accuracy.curve(acc.firingError.points, bullet)
	local crouch = if ctx.crouched and ctx.moveState ~= "air" then acc.crouchMultiplier.value else 1
	local movement = Accuracy.movementError(acc, ctx.moveState)
	local land = acc.landError or WeaponConfig.Accuracy.landError
	local landing = if ctx.landing then land.value else 0
	local power = if ctx.moveState == "still" then WeaponConfig.Accuracy.errorPower.value else WeaponConfig.Accuracy.moveErrorPower.value
	return {
		radius = raw * crouch + movement + landing,
		curve = raw,
		crouchMultiplier = crouch,
		movement = movement,
		landing = landing,
		power = power,
	}
end

-- Recoil -----------------------------------------------------------------------

-- Recoil offset of a bullet: degrees up, and degrees right given the current
-- sideways drift `sway` (already recovered).
function Accuracy.recoil(rec: WeaponConfig.RecoilDef, ctx: Context, bullet: number, sway: number, zoomed: boolean): (number, number)
	local pitch = Accuracy.curve(rec.pitch.points, bullet)
	local yaw = sway
	if ctx.moveState == "run" then
		pitch *= rec.runPitchMultiplier.value
	end
	if ctx.crouched and ctx.moveState == "still" then
		yaw *= rec.crouchYawMultiplier.value
	end
	if zoomed then
		pitch *= rec.adsMultiplier.value
		yaw *= rec.adsMultiplier.value
	end
	return pitch, yaw
end

-- Advances the sideways drift after a bullet has been fired. `direction` is
-- -1, 0 (not drifting yet) or 1. Returns the new drift and direction.
function Accuracy.advanceSway(rec: WeaponConfig.RecoilDef, bullet: number, sway: number, direction: number, seed: number, shotNumber: number): (number, number)
	if bullet < rec.swayStart.value - 1e-9 then
		return sway, direction
	end
	local step, limit = rec.swayStep.value, rec.swayMax.value
	if step <= 0 or limit <= 0 then
		return sway, direction
	end
	if direction == 0 then
		direction = if Accuracy.random(seed, shotNumber, 3) < 0.5 then -1 else 1
	elseif Accuracy.random(seed, shotNumber, 4) < rec.swayFlipChance.value then
		direction = -direction
	end
	if math.abs(sway + direction * step) > limit then
		direction = -direction
	end
	return math.clamp(sway + direction * step, -limit, limit), direction
end

-- Which share of the recoil the camera shows.
function Accuracy.cameraFraction(rec: WeaponConfig.RecoilDef, zoomed: boolean): number
	return if zoomed then rec.adsCameraFraction.value else rec.cameraFraction.value
end

-- Randomness --------------------------------------------------------------------

-- 32-bit multiply modulo 2^32 (doubles only hold 53 bits, so split one side).
local function mul32(a: number, b: number): number
	local high = bit32.band(bit32.rshift(a, 16) * b, 0xFFFF)
	return bit32.band(bit32.lshift(high, 16) + bit32.band(a, 0xFFFF) * b, 0xFFFFFFFF)
end

-- "lowbias32" integer hash (Chris Wellons): every input bit affects every
-- output bit, which is all a per-shot random number needs.
local function hash(x: number): number
	x = bit32.bxor(x, bit32.rshift(x, 16))
	x = mul32(x, 0x7FEB352D)
	x = bit32.bxor(x, bit32.rshift(x, 15))
	x = mul32(x, 0x846CA68B)
	return bit32.bxor(x, bit32.rshift(x, 16))
end

-- Uniform number in [0, 1) for a shot. `salt` picks independent streams.
function Accuracy.random(seed: number, shotNumber: number, salt: number): number
	local x = hash(bit32.bxor(seed, mul32(salt + 1, 0x9E3779B9)))
	return hash(bit32.bxor(x, shotNumber)) / 4294967296
end

-- Where in the cone a bullet lands: distance from the centre (degrees) and
-- the angle around it (radians, 0 = right, counter-clockwise).
function Accuracy.offset(seed: number, shotNumber: number, radius: number, power: number): (number, number)
	local r = radius * Accuracy.random(seed, shotNumber, 1) ^ power
	return r, Accuracy.random(seed, shotNumber, 2) * TAU
end

-- Directions -------------------------------------------------------------------

-- Unit view direction (Roblox: yaw 0 looks down -Z, positive yaw turns left).
function Accuracy.aim(yaw: number, pitch: number): vector
	local cp = math.cos(pitch)
	return vector.create(-math.sin(yaw) * cp, math.sin(pitch), -math.cos(yaw) * cp)
end

-- Final bullet direction: the aim moved by recoil (degrees up and right),
-- then by the cone offset (degrees from the centre, at `angle`).
function Accuracy.direction(yaw: number, pitch: number, recoilPitch: number, recoilYaw: number, offset: number, angle: number): vector
	local y = yaw - math.rad(recoilYaw)
	local p = math.clamp(pitch + math.rad(recoilPitch), -MAX_PITCH, MAX_PITCH)
	local forward = Accuracy.aim(y, p)
	if offset <= 0 then
		return forward
	end
	local right = vector.create(math.cos(y), 0, -math.sin(y))
	local up = vector.cross(right, forward)
	local t = math.tan(math.rad(offset))
	return vector.normalize(forward + (right * math.cos(angle) + up * math.sin(angle)) * t)
end

-- Live state ---------------------------------------------------------------------

-- Bullet number and drift the next shot would get if fired at time `t`
-- (WeaponSim state), and the mode it would fire in: hip or zoomed, as the
-- weapon is held now. The rest of a burst under way doesn't recover.
function Accuracy.next(def: WeaponConfig.WeaponDef, weapons: any, t: number, dt: number): (number, number, WeaponConfig.Mode)
	local mode = WeaponConfig.mode(def, weapons.scoped)
	local factor = if weapons.burstLeft > 0 then 1 else Accuracy.recoveryFactor(mode.accuracy, t - weapons.nextFireTime, dt)
	return weapons.sprayIndex * factor + 1, weapons.recoilYaw * factor, mode
end

return Accuracy
