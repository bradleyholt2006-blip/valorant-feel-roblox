--!strict
-- Deterministic first-person movement simulation.
--
-- The same step function runs on the client (prediction) and on the server
-- (authority). It is pure: all state lives in the MovementState table, all
-- world access goes through the World interface, and all units are metres and
-- seconds. Nothing here touches Roblox services, which is what lets the
-- offline tests in /tests run it with a fake world.
--
-- Model: ground movement in the style of Unreal's character movement (the
-- reference game runs on Unreal Engine 4). Letting go of the keys brakes
-- (friction plus a constant deceleration); pressing the opposite key
-- decelerates through the input instead, at the same rate. So counter-
-- strafing stops no sooner than letting go, which matches Riot's own stop
-- timings (docs/research/01-movement.md), unlike Source-engine games where
-- it stops you far sooner. In the air it borrows from Counter-Strike
-- instead: its air acceleration, so air strafing works as it does there, but
-- held to running speed, which is what Valorant players report.

export type World = {
	-- Sweep an axis-aligned box (center, halfExtents) along delta. Returns the
	-- fraction of delta travelled before contact and the contact normal, or nil.
	-- Like Roblox's Blockcast, it may not see geometry the box starts inside or
	-- within a fraction of a millimetre of, which is why the simulation keeps
	-- SKIN clear of everything.
	sweep: (self: World, center: vector, halfExtents: vector, delta: vector) -> (number?, vector?),
	-- True if a box at center would intersect level geometry.
	overlaps: (self: World, center: vector, halfExtents: vector) -> boolean,
	-- The gap from the box to the closest geometry within margin of it
	-- (negative if the box is inside it) and the unit direction away from it,
	-- or nil if there is none the world can measure.
	nearest: (self: World, center: vector, halfExtents: vector, margin: number) -> (number?, vector?),
}

-- One tick of player input. Movement reads buttons and yaw; the weapon
-- simulation also reads pitch and slot; hit registration reads viewTime.
export type Input = {
	seq: number,
	buttons: number,
	yaw: number, -- radians, 0 looks down -Z (Roblox convention)
	pitch: number, -- radians, positive looks up
	slot: number, -- weapon slot the player wants equipped (1 primary, 2 secondary, 3 melee, 4 the spike)
	viewTime: number, -- server time of the remote world the client was looking at
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
}

local Buttons = {
	Forward = 1,
	Back = 2,
	Left = 4,
	Right = 8,
	Walk = 16,
	Crouch = 32,
	Jump = 64,
	Fire = 128,
	AltFire = 256,
	Reload = 512,
	Use = 1024, -- 4 held: the spike's plant and defuse (system 12)
	Drop = 2048, -- G: drops the spike from the hand, or the gun in hand (system 15)
	-- The ability kit's keys (system 17, AbilitySim): C, Q, E and X.
	AbilityC = 4096,
	AbilityQ = 8192,
	AbilityE = 16384,
	Ultimate = 32768,
}

-- What an ability under way does to one tick of movement (system 17,
-- AbilitySim), in place of what the keys would:
--   * dash: the velocity this tick, level, with no gravity or braking. On the
--     ground it follows the floor and steps up stairs; off it, it flies level
--   * lift: an upward speed held this tick in place of gravity. It takes the
--     player off the ground, and the keys steer as in the air
--   * cap: the most speed along the ground kept from the last tick, before
--     anything else this one (what's left of a dash as it ends)
export type Motion = { dash: vector?, lift: number?, cap: number? }

-- Unreal's constants: a braking player under 10 cm/s stops dead, and a speed
-- counts as over the limit only beyond 1% (of its square) to absorb rounding.
local BRAKE_TO_STOP_SPEED = 0.1 -- m/s
local OVER_SPEED = 1.01

-- Metres kept between the box and geometry, measured along the surface's
-- normal. Roblox's Blockcast misses a part it starts within 0.0003 studs
-- (0.08 mm) of, so a gap allowed to wear away lets the box through.
local SKIN = 0.005
local GROUND_PROBE = 0.04
local LOOKAHEAD = 0.25 -- metres each sweep looks past the end of its move
local MIN_INTO = 1e-3 -- a move closing on a surface slower than this runs along it
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

function MovementSim.newState(position: vector): State
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

-- Brakes a horizontal velocity: friction in proportion to speed plus a
-- constant deceleration, never through zero.
local function brake(h: vector, speed: number, dt: number, cfg: any): vector
	local newSpeed = speed - (cfg.brakingFrictionFactor * cfg.groundFriction * speed + cfg.brakingDeceleration) * dt
	if newSpeed <= BRAKE_TO_STOP_SPEED then
		return ZERO
	end
	return h * (newSpeed / speed)
end

-- One tick of ground velocity:
--   * No input, or faster than the wish speed (just pressed walk or crouch,
--     or slowed by a weapon): brake. Braking while still pushing forward
--     stops at the wish speed instead of going below it.
--   * Input: friction only turns the velocity toward the input direction (it
--     does nothing while already moving that way), then the input
--     accelerates at maxAcceleration up to the wish speed.
-- A counter-strafe therefore decelerates at 2 x groundFriction x speed +
-- maxAcceleration, which with brakingFrictionFactor 2 and
-- brakingDeceleration = maxAcceleration is exactly the braking rate.
local function groundVelocity(vel: vector, wishDir: vector, wishSpeed: number, dt: number, cfg: any): vector
	local h = horizontal(vel)
	local speed = vector.magnitude(h)
	local pushing = vector.magnitude(wishDir) > 0
	local over = speed * speed > wishSpeed * wishSpeed * OVER_SPEED
	if speed > 0 and (over or not pushing) then
		local braked = brake(h, speed, dt, cfg)
		if pushing and vector.dot(wishDir, h) > 0 and vector.magnitude(braked) < wishSpeed then
			braked = h * (wishSpeed / speed)
		end
		h = braked
	elseif pushing then
		h -= (h - wishDir * speed) * math.min(dt * cfg.groundFriction, 1)
	end
	if pushing then
		local current = vector.magnitude(h)
		local limit = if current * current > wishSpeed * wishSpeed * OVER_SPEED then current else wishSpeed
		h += wishDir * (cfg.maxAcceleration * dt)
		local magnitude = vector.magnitude(h)
		if magnitude > limit then
			h *= limit / magnitude
		end
	end
	return vector.create(h.x, vel.y, h.z)
end

-- One tick of air velocity: Quake's air acceleration, as Counter-Strike
-- uses it, under Valorant's speed limit.
--   * Input adds up to airAcceleration x wishSpeed per second along the wish
--     direction, but only until the velocity's share along it reaches
--     airWishSpeedCap. So pushing the way you already move adds nothing,
--     pushing against it brakes you hard, and pushing across it adds a
--     little sideways each tick, which turns the velocity: holding A or D
--     while turning the mouse the same way keeps it following the crosshair
--     (air strafing).
--   * Input can't take the speed along the ground past airSpeedLimit x
--     wishSpeed, or past what it already was if that's faster, so strafing
--     turns you without speeding you up. Counter-Strike has no such limit,
--     which is how strafing builds speed there.
--   * Letting go keeps the velocity: nothing brakes you in the air.
local function airVelocity(vel: vector, wishDir: vector, wishSpeed: number, dt: number, cfg: any): vector
	local h = horizontal(vel)
	local add = math.min(wishSpeed, cfg.airWishSpeedCap) - vector.dot(h, wishDir)
	if add <= 0 then
		return vel
	end
	local before = vector.magnitude(h)
	h += wishDir * math.min(cfg.airAcceleration * wishSpeed * dt, add)
	local limit = math.max(wishSpeed * cfg.airSpeedLimit, before)
	local speed = vector.magnitude(h)
	if speed > limit then
		h *= limit / speed
	end
	return vector.create(h.x, vel.y, h.z)
end

local function clipVelocity(vel: vector, normal: vector): vector
	local backoff = vector.dot(vel, normal)
	if backoff >= 0 then
		return vel
	end
	return vel - normal * backoff
end

-- Moving over a floor or ramp: the same horizontal velocity, plus whatever
-- vertical speed keeps it on the surface, as Unreal's walking movement does.
local function alongFloor(vel: vector, floor: vector): vector
	return vector.create(vel.x, -(floor.x * vel.x + floor.z * vel.z) / floor.y, vel.z)
end

-- Moves the box `distance` along the unit `dir`, or halfway to whatever is in
-- the way.
local function pushOut(world: World, center: vector, half: vector, dir: vector, distance: number): vector
	local delta = dir * distance
	local fraction = world:sweep(center, half, delta)
	if fraction then
		delta *= fraction * 0.5
	end
	return center + delta
end

-- Moves the box along delta, stopping where its gap to whatever it meets is
-- SKIN along that surface's normal (a gap measured along the move would wear
-- away on glancing contacts). The sweep looks LOOKAHEAD past the move, so the
-- box can't end it closer than SKIN to a surface just beyond. Returns the new
-- centre and, if it met something, how much of the move it made (0 to 1) and
-- the surface's normal.
local function moveBox(world: World, center: vector, half: vector, delta: vector): (vector, number?, vector?)
	local dist = vector.magnitude(delta)
	local dir = delta / dist
	local reach = dist + LOOKAHEAD
	local fraction, normal = world:sweep(center, half, dir * reach)
	if fraction == nil or normal == nil then
		return center + delta, nil, nil
	end
	local contact = reach * fraction
	local into = -vector.dot(dir, normal)
	local stop = contact - SKIN / math.max(into, MIN_INTO)
	if stop >= dist then
		return center + delta, nil, nil
	elseif stop >= 0 then
		return center + dir * stop, stop / dist, normal
	end
	-- It started closer than SKIN: it stays, stepped back out to SKIN.
	return pushOut(world, center, half, normal, SKIN - contact * math.max(into, 0)), 0, normal
end

-- Restores SKIN between the box and anything it has got closer to: sweeps
-- can't see what the box starts on top of, so this runs before them.
local function keepClear(world: World, center: vector, half: vector): vector
	for _ = 1, 2 do
		local gap, away = world:nearest(center, half, SKIN)
		if gap == nil or away == nil or gap >= SKIN * 0.5 then
			break
		end
		center += away * (SKIN - gap)
	end
	return center
end

-- Quake-style collide-and-slide. Surfaces flat enough to stand on are
-- followed at the same horizontal velocity. In the air, steeper ones deflect
-- the velocity. On the ground (floor is the ground's normal) they block like
-- vertical walls instead, so they can't be climbed. Returns the new centre and
-- velocity, and the last walkable surface it met, if any.
local function slideMove(world: World, center: vector, vel: vector, half: vector, dt: number, cfg: any, floor: vector?): (vector, vector, vector?)
	local timeLeft = dt
	local planes: { vector } = {}
	local original = vel
	local landed: vector? = nil
	for _ = 1, MAX_SLIDE_ITERATIONS do
		local delta = vel * timeLeft
		if vector.magnitude(delta) < 1e-6 then
			break
		end
		local fraction, normal
		center, fraction, normal = moveBox(world, center, half, delta)
		if fraction == nil or normal == nil then
			break
		end
		timeLeft *= 1 - fraction

		if normal.y >= cfg.minGroundNormalY then
			landed = normal
			if floor then
				floor = normal
			end
			vel = alongFloor(vel, normal)
		else
			local plane = normal
			if floor then
				plane = horizontal(normal)
				if vector.magnitude(plane) < 1e-4 then
					return center, ZERO, landed
				end
				plane = vector.normalize(plane)
			end
			table.insert(planes, plane)
			vel = clipVelocity(vel, plane)
			-- Two planes: slide along their crease so we don't jitter into a corner.
			if #planes >= 2 then
				local a, b = planes[#planes - 1], planes[#planes]
				if vector.dot(vel, a) < -1e-4 then
					local crease = vector.cross(a, b)
					if vector.magnitude(crease) < 1e-4 then
						return center, ZERO, landed
					end
					crease = vector.normalize(crease)
					vel = crease * vector.dot(vel, crease)
				end
			end
			if floor then
				vel = alongFloor(vel, floor)
			end
		end
		-- Never let a bounce reverse the original direction (stops corner pops).
		if vector.dot(vel, original) <= 0 then
			return center, ZERO, landed
		end
	end
	return center, vel, landed
end

-- Ground move with stair stepping: move along the floor; if something stops
-- that short, try the move lifted by stepHeight and set back down, and keep
-- whichever travelled further. The lifted move reaches at least 2 x SKIN
-- past where the plain one stopped, so a box held SKIN off a low edge can
-- still get over it. A step must really go up or down: one that lands back
-- at the same height has only reached past what stopped the plain move,
-- such as the foot of a slope too steep to climb. The velocity stays
-- horizontal.
local function groundMove(world: World, center: vector, vel: vector, half: vector, dt: number, cfg: any, floor: vector): (vector, vector)
	local plainCenter, plainVel = slideMove(world, center, alongFloor(vel, floor), half, dt, cfg, floor)
	local plainDist = vector.magnitude(horizontal(plainCenter - center))
	local wanted = vector.magnitude(horizontal(vel)) * dt
	if plainDist >= wanted - 1e-4 or wanted < 1e-6 then
		return plainCenter, horizontal(plainVel)
	end

	local lifted = moveBox(world, center, half, UP * cfg.stepHeight)
	local lift = lifted.y - center.y
	local reach = math.max(wanted, plainDist + SKIN * 2) / wanted
	local stepCenter, stepVel = slideMove(world, lifted, horizontal(vel) * reach, half, dt, cfg, UP)
	local downCenter, downFraction, downNormal = moveBox(world, stepCenter, half, UP * -(lift + GROUND_PROBE))
	if downFraction == nil or downNormal == nil or downNormal.y < cfg.minGroundNormalY then
		return plainCenter, horizontal(plainVel)
	end
	if math.abs(downCenter.y - center.y) < SKIN * 0.5 or vector.magnitude(horizontal(downCenter - center)) <= plainDist then
		return plainCenter, horizontal(plainVel)
	end
	return downCenter, horizontal(stepVel) / reach
end

-- Looks for ground to stand on within `distance` below the box. Returns
-- whether there is some, its normal, and the centre settled SKIN above it
-- (along its normal).
local function probeGround(world: World, center: vector, half: vector, distance: number, cfg: any): (boolean, vector, vector)
	local fraction, normal = world:sweep(center, half, UP * -distance)
	if fraction == nil or normal == nil or normal.y < cfg.minGroundNormalY then
		return false, UP, center
	end
	local drop = distance * fraction - SKIN / normal.y
	if drop >= 0 then
		return true, normal, center - UP * drop
	end
	return true, normal, pushOut(world, center, half, UP, -drop)
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

-- Advance the state by one fixed tick, with what an ability under way does
-- to it, if anything. Mutates and returns s.
function MovementSim.step(s: State, input: Input, cfg: any, weaponMaxSpeed: number, world: World, dt: number, motion: Motion?): State
	s.tick += 1
	local buttons = input.buttons

	updateCrouch(s, world, buttons, dt, cfg)

	local wishDir = MovementSim.wishDirection(buttons, input.yaw)
	local wishSpeed = MovementSim.wishSpeed(s, buttons, cfg, weaponMaxSpeed)
	local vel = s.velocity
	local dash = if motion then motion.dash else nil
	local lift = if motion then motion.lift else nil
	local cap = if motion then motion.cap else nil
	if cap then
		local h = horizontal(vel)
		local speed = vector.magnitude(h)
		if speed > cap then
			h *= cap / speed
			vel = vector.create(h.x, vel.y, h.z)
		end
	end

	local jumpHeld = has(buttons, Buttons.Jump)
	if not jumpHeld then
		s.jumpLatched = false
	end

	if dash then
		vel = vector.create(dash.x, 0, dash.z)
	elseif lift then
		s.grounded = false
		local airWishSpeed = if has(buttons, Buttons.Walk) then weaponMaxSpeed * cfg.walkMultiplier else weaponMaxSpeed
		vel = airVelocity(vel, wishDir, airWishSpeed, dt, cfg)
		vel = vector.create(vel.x, lift, vel.z)
	elseif s.grounded and jumpHeld and not s.jumpLatched then
		s.grounded = false
		s.jumpLatched = true
		s.lastJumpTick = s.tick
		vel = groundVelocity(vel, wishDir, wishSpeed, dt, cfg)
		vel = vector.create(vel.x, cfg.jumpVelocity, vel.z)
	elseif s.grounded then
		vel = groundVelocity(vel, wishDir, wishSpeed, dt, cfg)
		vel = vector.create(vel.x, 0, vel.z)
	else
		-- Crouching doesn't slow input in the air, as in Source and Unreal.
		local airWishSpeed = if has(buttons, Buttons.Walk) then weaponMaxSpeed * cfg.walkMultiplier else weaponMaxSpeed
		vel = airVelocity(vel, wishDir, airWishSpeed, dt, cfg)
	end

	if not s.grounded and not dash and not lift then
		vel -= UP * (cfg.gravity * dt)
	end

	local height = MovementSim.boxHeight(s, cfg)
	local half = halfExtents(cfg, height)
	local center = keepClear(world, boxCenter(s.position, height), half)

	local landed: vector? = nil
	if s.grounded then
		center, vel = groundMove(world, center, vel, half, dt, cfg, s.groundNormal)
	else
		center, vel, landed = slideMove(world, center, vel, half, dt, cfg, nil)
	end

	-- Ground check. On the ground (unless we just jumped), probe as far as a
	-- step so we stick to stairs and ramps instead of flying off them; in the
	-- air, only when falling or after touching something to stand on.
	local wasGrounded = s.grounded
	local probe = if wasGrounded then cfg.stepHeight + GROUND_PROBE else GROUND_PROBE
	local onGround, normal = false, UP
	if s.lastJumpTick ~= s.tick and (wasGrounded or landed or vel.y <= 1e-3) then
		onGround, normal, center = probeGround(world, center, half, probe, cfg)
	end
	if onGround then
		vel = horizontal(vel)
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

-- Accuracy deadzone check for the debug tools; the same strict test as
-- PlayerSim.isAccurate, which the weapons use.
function MovementSim.isAccurate(s: State, weaponMaxSpeed: number, accurateFraction: number): boolean
	return s.grounded and MovementSim.horizontalSpeed(s) < weaponMaxSpeed * accurateFraction - 1e-3
end

return MovementSim
