--!strict
-- Deterministic first-person movement simulation.
--
-- The same step function runs on the client (prediction) and on the server
-- (authority). It is pure: all state lives in the MovementState table, all
-- world access goes through the World interface, and all units are metres and
-- seconds. Nothing here touches Roblox services, which is what lets the
-- offline tests in /tests run it with a fake world.
--
-- Model: Source/UE-style ground friction + acceleration. That model produces
-- the counter-strafe effect for free: releasing a key only applies friction,
-- while pressing the opposite key applies friction *and* acceleration against
-- the current velocity, so speed falls under the accuracy threshold sooner.

export type World = {
	-- Sweep an axis-aligned box (center, halfExtents) along delta. Returns the
	-- fraction of delta travelled before contact and the contact normal, or nil.
	sweep: (self: World, center: vector, halfExtents: vector, delta: vector) -> (number?, vector?),
	-- True if a box at center would intersect level geometry.
	overlaps: (self: World, center: vector, halfExtents: vector) -> boolean,
}

export type Input = {
	seq: number,
	buttons: number,
	yaw: number, -- radians, 0 looks down -Z (Roblox convention)
	weapon: string,
}

export type State = {
	tick: number,
	position: vector, -- feet, centre of the box's base
	velocity: vector,
	grounded: boolean,
	groundNormal: vector,
	crouched: boolean,
	crouchAlpha: number, -- 0 standing, 1 fully crouched
	jumpLatched: boolean, -- jump must be released before the next jump
	lastJumpTick: number,
	lastLandTick: number,
	weapon: string,
}

local Buttons = {
	Forward = 1,
	Back = 2,
	Left = 4,
	Right = 8,
	Walk = 16,
	Crouch = 32,
	Jump = 64,
}

local SKIN = 0.005 -- metres kept between the box and geometry
local GROUND_PROBE = 0.04
local MAX_SLIDE_ITERATIONS = 4
local UP = vector.create(0, 1, 0)
local ZERO = vector.create(0, 0, 0)

local MovementSim = {}
MovementSim.Buttons = Buttons

local function has(buttons: number, flag: number): boolean
	return bit32.band(buttons, flag) ~= 0
end
MovementSim.has = has

local function horizontal(v: vector): vector
	return vector.create(v.x, 0, v.z)
end

function MovementSim.newState(position: vector, weapon: string?): State
	return {
		tick = 0,
		position = position,
		velocity = ZERO,
		grounded = false,
		groundNormal = UP,
		crouched = false,
		crouchAlpha = 0,
		jumpLatched = false,
		lastJumpTick = -math.huge,
		lastLandTick = -math.huge,
		weapon = weapon or "rifle",
	}
end

function MovementSim.copy(s: State): State
	return table.clone(s)
end

function MovementSim.boxHeight(s: State, cfg: any): number
	return cfg.standHeight + (cfg.crouchHeight - cfg.standHeight) * s.crouchAlpha
end

function MovementSim.eyeHeight(s: State, cfg: any): number
	return cfg.standEyeHeight + (cfg.crouchEyeHeight - cfg.standEyeHeight) * s.crouchAlpha
end

local function halfExtents(cfg: any, height: number): vector
	return vector.create(cfg.halfWidth, height * 0.5, cfg.halfWidth)
end

local function boxCenter(feet: vector, height: number): vector
	return feet + vector.create(0, height * 0.5, 0)
end

function MovementSim.horizontalSpeed(s: State): number
	return vector.magnitude(horizontal(s.velocity))
end

-- Wish direction from keys and yaw. Opposite keys cancel, exactly like the
-- reference: holding A and D together is "no input" on that axis.
function MovementSim.wishDirection(buttons: number, yaw: number): vector
	local forward = (if has(buttons, Buttons.Forward) then 1 else 0) - (if has(buttons, Buttons.Back) then 1 else 0)
	local right = (if has(buttons, Buttons.Right) then 1 else 0) - (if has(buttons, Buttons.Left) then 1 else 0)
	if forward == 0 and right == 0 then
		return ZERO
	end
	local s, c = math.sin(yaw), math.cos(yaw)
	-- Roblox: yaw 0 looks along -Z, +X is to the right.
	local fwd = vector.create(-s, 0, -c)
	local rgt = vector.create(c, 0, -s)
	return vector.normalize(fwd * forward + rgt * right)
end

function MovementSim.wishSpeed(s: State, buttons: number, cfg: any, maxSpeed: number): number
	if s.crouched then
		return maxSpeed * cfg.crouchMultiplier
	elseif has(buttons, Buttons.Walk) then
		return maxSpeed * cfg.walkMultiplier
	end
	return maxSpeed
end

local function applyFriction(vel: vector, dt: number, cfg: any): vector
	local h = horizontal(vel)
	local speed = vector.magnitude(h)
	if speed < 1e-4 then
		return vector.create(0, vel.y, 0)
	end
	local control = math.max(speed, cfg.stopSpeed)
	local newSpeed = math.max(speed - control * cfg.groundFriction * dt, 0)
	local scaled = h * (newSpeed / speed)
	return vector.create(scaled.x, vel.y, scaled.z)
end

local function accelerate(vel: vector, wishDir: vector, wishSpeed: number, accel: number, dt: number): vector
	local current = vector.dot(vel, wishDir)
	local add = wishSpeed - current
	if add <= 0 then
		return vel
	end
	local accelSpeed = math.min(accel * wishSpeed * dt, add)
	return vel + wishDir * accelSpeed
end

local function clipVelocity(vel: vector, normal: vector): vector
	local backoff = vector.dot(vel, normal)
	if backoff >= 0 then
		return vel
	end
	return vel - normal * backoff
end

-- Quake-style collide-and-slide. Returns the new centre and velocity.
local function slideMove(world: World, center: vector, vel: vector, half: vector, dt: number): (vector, vector)
	local timeLeft = dt
	local planes: { vector } = {}
	local original = vel
	for _ = 1, MAX_SLIDE_ITERATIONS do
		local delta = vel * timeLeft
		local dist = vector.magnitude(delta)
		if dist < 1e-6 then
			break
		end
		local fraction, normal = world:sweep(center, half, delta)
		if fraction == nil or normal == nil then
			center += delta
			break
		end
		local safe = math.max(dist * fraction - SKIN, 0) / dist
		center += delta * safe
		timeLeft *= 1 - fraction

		table.insert(planes, normal)
		vel = clipVelocity(vel, normal)
		-- Two planes: slide along their crease so we don't jitter into a corner.
		if #planes >= 2 then
			local a, b = planes[#planes - 1], planes[#planes]
			if vector.dot(vel, a) < -1e-4 then
				local crease = vector.cross(a, b)
				if vector.magnitude(crease) < 1e-4 then
					return center, ZERO
				end
				crease = vector.normalize(crease)
				vel = crease * vector.dot(vel, crease)
			end
		end
		-- Never let a bounce reverse the original direction (stops corner pops).
		if vector.dot(vel, original) <= 0 then
			return center, ZERO
		end
	end
	return center, vel
end

-- Ground move with stair stepping: try the plain move, then the move lifted by
-- stepHeight and set back down; keep whichever travelled further.
local function groundMove(world: World, center: vector, vel: vector, half: vector, dt: number, cfg: any): (vector, vector)
	local plainCenter, plainVel = slideMove(world, center, vel, half, dt)
	local plainDist = vector.magnitude(horizontal(plainCenter - center))
	local wanted = vector.magnitude(horizontal(vel)) * dt
	if plainDist >= wanted - 1e-4 then
		return plainCenter, plainVel
	end

	local upFraction = world:sweep(center, half, UP * cfg.stepHeight)
	local lift = cfg.stepHeight * (if upFraction then math.max(upFraction - 0.01, 0) else 1)
	local lifted = center + UP * lift
	local stepCenter, stepVel = slideMove(world, lifted, horizontal(vel), half, dt)
	local downDelta = UP * -(lift + GROUND_PROBE)
	local downFraction, downNormal = world:sweep(stepCenter, half, downDelta)
	if downFraction == nil or downNormal == nil or downNormal.y < cfg.minGroundNormalY then
		return plainCenter, plainVel
	end
	local dropDist = vector.magnitude(downDelta) * downFraction - SKIN
	stepCenter += UP * -math.max(dropDist, 0)
	if vector.magnitude(horizontal(stepCenter - center)) <= plainDist then
		return plainCenter, plainVel
	end
	return stepCenter, vector.create(stepVel.x, plainVel.y, stepVel.z)
end

local function probeGround(world: World, center: vector, half: vector, distance: number, cfg: any): (boolean, vector, number)
	local fraction, normal = world:sweep(center, half, UP * -distance)
	if fraction == nil or normal == nil or normal.y < cfg.minGroundNormalY then
		return false, UP, 0
	end
	return true, normal, math.max(distance * fraction - SKIN, 0)
end

local function updateCrouch(s: State, world: World, buttons: number, dt: number, cfg: any)
	local wantCrouch = has(buttons, Buttons.Crouch)
	if wantCrouch then
		s.crouched = true
	elseif s.crouched then
		-- Only stand up if there is headroom for the full standing box.
		local standCenter = boxCenter(s.position, cfg.standHeight) + UP * SKIN
		if not world:overlaps(standCenter, halfExtents(cfg, cfg.standHeight - SKIN * 2)) then
			s.crouched = false
		end
	end
	local target = if s.crouched then 1 else 0
	local rate = dt / math.max(cfg.crouchTransitionTime, 1e-3)
	if s.crouchAlpha < target then
		s.crouchAlpha = math.min(s.crouchAlpha + rate, target)
	elseif s.crouchAlpha > target then
		s.crouchAlpha = math.max(s.crouchAlpha - rate, target)
	end
end

-- Advance the state by one fixed tick. Mutates and returns s.
function MovementSim.step(s: State, input: Input, cfg: any, weaponMaxSpeed: number, world: World, dt: number): State
	s.tick += 1
	s.weapon = input.weapon
	local buttons = input.buttons

	updateCrouch(s, world, buttons, dt, cfg)

	local wishDir = MovementSim.wishDirection(buttons, input.yaw)
	local wishSpeed = MovementSim.wishSpeed(s, buttons, cfg, weaponMaxSpeed)
	local vel = s.velocity

	local jumpHeld = has(buttons, Buttons.Jump)
	if not jumpHeld then
		s.jumpLatched = false
	end

	if s.grounded and jumpHeld and not s.jumpLatched then
		s.grounded = false
		s.jumpLatched = true
		s.lastJumpTick = s.tick
		vel = applyFriction(vel, dt, cfg)
		vel = vector.create(vel.x, cfg.jumpVelocity, vel.z)
	elseif s.grounded then
		vel = applyFriction(vel, dt, cfg)
		vel = accelerate(vel, wishDir, wishSpeed, cfg.groundAcceleration, dt)
		vel = vector.create(vel.x, 0, vel.z)
	else
		vel = accelerate(vel, wishDir, math.min(wishSpeed, cfg.airWishSpeedCap), cfg.airAcceleration, dt)
	end

	if not s.grounded then
		vel -= UP * (cfg.gravity * dt)
	end

	local height = MovementSim.boxHeight(s, cfg)
	local half = halfExtents(cfg, height)
	local center = boxCenter(s.position, height)

	if s.grounded then
		center, vel = groundMove(world, center, vel, half, dt, cfg)
	else
		center, vel = slideMove(world, center, vel, half, dt)
	end

	-- Ground check. While already grounded, probe as far as a step so we stick
	-- to stairs and slopes instead of flying off them.
	local wasGrounded = s.grounded
	local probe = if wasGrounded then cfg.stepHeight + GROUND_PROBE else GROUND_PROBE
	local onGround, normal, drop = false, UP, 0
	if vel.y <= 1e-3 then
		onGround, normal, drop = probeGround(world, center, half, probe, cfg)
	end
	if onGround then
		center -= UP * drop
		vel = vector.create(vel.x, 0, vel.z)
		if not wasGrounded then
			s.lastLandTick = s.tick
		end
	end
	s.grounded = onGround
	s.groundNormal = normal

	s.position = center - UP * (height * 0.5)
	s.velocity = vel
	return s
end

-- Accuracy deadzone check used by the debug HUD and, later, the weapon system.
function MovementSim.isAccurate(s: State, weaponMaxSpeed: number, accurateFraction: number): boolean
	return s.grounded and MovementSim.horizontalSpeed(s) <= weaponMaxSpeed * accurateFraction + 1e-6
end

return MovementSim
