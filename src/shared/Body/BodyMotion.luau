--!strict
-- What an agent's body is doing from frame to frame (system 63), worked
-- out from the poses the snapshots carry as they're drawn: how fast and
-- which way it's moving in its own space, how far through its stride it
-- is, whether it's in the air or just landed, reloading, planting or
-- gliding, how its gun kicks as it fires, and since when it's held what it
-- holds; standing, where each foot stands as it turns on the spot, and its
-- steps round after the turn. BodyPose turns it into the body's pose.
--
-- The stride's length and the strides a second are matched to the speed
-- (a stride's length times strides a second is the speed, as in Johansen's
-- locomotion thesis: "the speed is found by dividing the distance by the
-- duration of the motion cycle"), so a foot that's down keeps its place on
-- the ground while the body passes over it, at any speed and any way, up
-- to the longest sweep the legs reach (BodyConfig.Gait).

local BodyConfig = require("./BodyConfig")
local WeaponConfig = require("../Weapons/WeaponConfig")

export type Hold = "rifle" | "pistol" | "knife" | "spike" | "item" | "none"

-- One frame of what the snapshots say about an entity.
export type Input = {
	position: vector, -- feet, metres
	yaw: number,
	pitch: number,
	crouch: number, -- 0 standing to 1 crouched
	grounded: boolean,
	hold: Hold,
	foregrip: vector?, -- where a long gun's left hand goes, gun space (BodyView, from its look)
	reloading: boolean,
	reloadLength: number?, -- seconds the gun's reload takes (WeaponConfig), for the left hand's trip
	channel: number, -- 1 planting, 2 defusing, 3 taking an orb, 0 none
	gliding: boolean,
	sinceShot: number?, -- seconds since it last fired, if it has
}

export type State = {
	started: boolean,
	position: vector,
	yaw: number,
	pitch: number,
	crouch: number,
	grounded: boolean,
	hold: Hold,
	previous: Hold, -- what it held before
	foregrip: vector?,
	channel: number,
	time: number,
	velocity: vector, -- body space, level, m/s
	turn: number, -- radians a second, + to the left
	travel: vector, -- what the legs step at: the velocity
	direction: vector, -- body space, level, unit: the way the legs step
	backward: boolean, -- stepping backward (the hips turn the other way)
	moving: number, -- 0..1, how much the legs step
	phase: number, -- 0..1 through the stride (the left foot's; the right's is half on)
	cadence: number, -- strides a second
	stance: number, -- share of a stride each foot is down
	sweep: number, -- metres a foot travels under the body while down
	lift: number, -- metres a swinging foot comes up
	hipYaw: number, -- the hips' turn toward the way the legs step
	air: number, -- 0..1
	airTime: number,
	land: number, -- 1 just landed, to 0
	reload: number, -- 0..1
	reloadTime: number,
	reloadLength: number,
	reloadShare: number, -- 0..1 through the left hand's trip, over the reload's length
	reloading: boolean,
	kick: number, -- 0..1, the last shot's kick
	plant: number, -- 0..1 planting or defusing
	orb: number, -- 0..1 taking an orb
	glide: number, -- 0..1
	draw: number, -- seconds holding what it holds
	-- Standing, each foot's turn from the way the body faces (left, right;
	-- + to the left) and how far it's up, stepping round.
	feet: { number },
	footLift: { number },
	-- Working: the way each foot faces, world yaw; how far through a step
	-- round it is (-1 for none) and the way it faced as it set off; and the
	-- foot to follow the one that's just stepped (0 for none).
	footYaw: { number },
	footStep: { number },
	footFrom: { number },
	footFollow: number,
}

local BodyMotion = {}

-- Further than this in a frame is a respawn or a teleport, not a move.
local JUMP = 4

local function approach(current: number, target: number, dt: number, time: number): number
	if time <= 0 then
		return target
	end
	return target + (current - target) * math.exp(-dt / time)
end

local function wrap(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

-- How a weapon's held, by its kind: sidearms in a pistol grip, the other
-- guns at the shoulder, the knife, the spike, an ability's item in the
-- right hand; nothing for none ("" or nil).
local HOLDS: { [WeaponConfig.Category]: Hold } = {
	sidearm = "pistol",
	smg = "rifle",
	shotgun = "rifle",
	rifle = "rifle",
	sniper = "rifle",
	heavy = "rifle",
	melee = "knife",
	spike = "spike",
	ultimate = "item",
	ability = "item",
}

function BodyMotion.holdOf(weapon: string?): Hold
	local def = if weapon and weapon ~= "" then WeaponConfig.Defs[weapon] else nil
	return if def then HOLDS[def.category] or "item" else "none"
end

-- World space to the body's (rotated by -yaw about +Y).
function BodyMotion.toBody(v: vector, yaw: number): vector
	local c, s = math.cos(yaw), math.sin(yaw)
	return vector.create(v.x * c - v.z * s, v.y, v.x * s + v.z * c)
end

-- The stride at a speed: strides a second, the share each foot is down,
-- how far it sweeps while down and how high it lifts. `side` is how much
-- of the way is sideways (0 to 1), `look` how far it looks up or down (0
-- to 1).
function BodyMotion.gait(speed: number, crouch: number, side: number, look: number): (number, number, number, number)
	local G = BodyConfig.Gait
	local cadence = math.min(G.cadenceBase.value + G.cadencePerSpeed.value * speed, G.cadenceMax.value)
		* (1 + (G.crouchCadence.value - 1) * crouch)
		* (1 + (G.sideCadence.value - 1) * side)
	local stance = math.clamp(G.stanceBase.value + G.stancePerSpeed.value * speed, G.stanceMin.value, G.stanceMax.value)
	local reach = (G.sweepMax.value + (G.sweepSide.value - G.sweepMax.value) * side)
		* (1 + (G.crouchSweep.value - 1) * crouch)
		* (1 - G.lookShort.value * look)
	-- Quicker steps where a stride would be longer than the legs reach, so
	-- the feet stay planted.
	cadence = math.clamp(stance * speed / reach, cadence, math.max(cadence, G.cadenceLimit.value))
	local sweep = math.min(stance * speed / cadence, reach)
	local lift = math.min(G.liftBase.value + G.liftPerSpeed.value * speed, G.liftMax.value) * (1 + (G.crouchLift.value - 1) * crouch)
	return cadence, stance, sweep, lift
end

function BodyMotion.new(): State
	return {
		started = false,
		position = vector.zero,
		yaw = 0,
		pitch = 0,
		crouch = 0,
		grounded = true,
		hold = "none",
		previous = "none",
		foregrip = nil,
		channel = 0,
		time = 0,
		velocity = vector.zero,
		turn = 0,
		travel = vector.zero,
		direction = vector.create(0, 0, -1),
		backward = false,
		moving = 0,
		phase = 0,
		cadence = 1,
		stance = 0.6,
		sweep = 0,
		lift = 0,
		hipYaw = 0,
		air = 0,
		airTime = 0,
		land = 0,
		reload = 0,
		reloadTime = 0,
		reloadLength = BodyConfig.Hold.reloadCycle.value,
		reloadShare = 0,
		reloading = false,
		kick = 0,
		plant = 0,
		orb = 0,
		glide = 0,
		draw = math.huge,
		feet = { 0, 0 },
		footLift = { 0, 0 },
		footYaw = { 0, 0 },
		footStep = { -1, -1 },
		footFrom = { 0, 0 },
		footFollow = 0,
	}
end

-- Standing, each foot stays where it stands as the body turns on the spot,
-- until the body's turned far enough from it, and then steps round after
-- it: the foot on the side it turns toward first, the other following.
-- Moving or in the air, the feet come round with the body.
local function turnFeet(s: State, yaw: number, grounded: boolean, dt: number)
	local G = BodyConfig.Gait
	local yaws, steps, from = s.footYaw, s.footStep, s.footFrom
	if s.moving > 0.5 or not grounded then
		for k = 1, 2 do
			if steps[k] >= 0 then
				yaws[k] = from[k] + wrap(yaw - from[k]) * steps[k]
				steps[k] = -1
			end
			yaws[k] = yaw - wrap(yaw - yaws[k]) * math.exp(-8 * dt)
		end
		s.footFollow = 0
	else
		for k = 1, 2 do
			if steps[k] >= 0 then
				steps[k] += dt / G.turnStepTime.value
				if steps[k] >= 1 then
					steps[k] = -1
					yaws[k] = yaw
					s.footFollow = 3 - k
				end
			end
		end
		if steps[1] < 0 and steps[2] < 0 then
			local lags = { wrap(yaw - yaws[1]), wrap(yaw - yaws[2]) }
			local first = if lags[1] + lags[2] > 0 then 1 else 2
			local follow = s.footFollow
			s.footFollow = 0
			local k = 0
			if follow > 0 and math.abs(lags[follow]) > G.turnFollow.value then
				k = follow
			elseif math.abs(lags[first]) > G.turnStepAt.value then
				k = first
			elseif math.abs(lags[3 - first]) > G.turnStepAt.value then
				k = 3 - first
			end
			if k > 0 then
				steps[k], from[k] = 0, yaws[k]
			end
		end
		-- Turned past the most, a foot turns where it stands.
		local most = G.turnMost.value
		for k = 1, 2 do
			if steps[k] < 0 then
				local lag = wrap(yaw - yaws[k])
				if math.abs(lag) > most then
					yaws[k] = yaw - math.sign(lag) * most
				end
			end
		end
	end
	for k = 1, 2 do
		local step = steps[k]
		local facing = yaws[k]
		local lift = 0
		if step >= 0 then
			local e = step * step * (3 - 2 * step)
			facing = from[k] + wrap(yaw - from[k]) * e
			lift = G.turnLift.value * math.sin(math.pi * step)
		end
		s.feet[k] = wrap(facing - yaw)
		s.footLift[k] = lift
	end
end

-- Moves the state on by dt seconds to a new frame's input.
function BodyMotion.step(s: State, input: Input, dt: number)
	local G = BodyConfig.Gait
	if not s.started or vector.magnitude(input.position - s.position) > JUMP then
		local fresh = BodyMotion.new()
		for k, v in pairs(fresh :: any) do
			(s :: any)[k] = v
		end
		s.started = true
		s.position = input.position
		s.yaw = input.yaw
		s.hold = input.hold
		s.previous = input.hold
		s.air = if input.grounded then 0 else 1
		s.footYaw = { input.yaw, input.yaw }
		dt = 0
	end
	dt = math.clamp(dt, 0, 0.1)

	-- Speed and turning, smoothed (snapshots step).
	if dt > 0 then
		local moved = BodyMotion.toBody(input.position - s.position, input.yaw) / dt
		local level = vector.create(moved.x, 0, moved.z)
		local k = 1 - math.exp(-dt / G.smoothing.value)
		s.velocity += (level - s.velocity) * k
		s.turn += (wrap(input.yaw - s.yaw) / dt - s.turn) * k
	end
	s.time += dt

	-- What the legs step at: the body's speed (turning on the spot, the feet
	-- step round after the turn, below).
	s.travel = s.velocity
	local pace = vector.magnitude(s.travel)
	if pace > 0.05 then
		s.direction = s.travel / pace
	end
	local side = math.abs(s.direction.x)
	s.cadence, s.stance, s.sweep, s.lift = BodyMotion.gait(pace, input.crouch, side, math.min(math.abs(input.pitch), 1))
	s.phase = (s.phase + s.cadence * dt) % 1
	s.moving = approach(s.moving, math.clamp((pace - 0.1) / 0.5, 0, 1), dt, G.settle.value)

	-- The hips turn toward the way the legs step; stepping backward they
	-- turn the other way (the legs step back along their own line), with a
	-- margin either side of straight sideways so they don't flip about.
	local angle = math.atan2(s.direction.x, -s.direction.z) -- 0 ahead, + to the right
	if s.backward and math.abs(angle) < math.rad(80) then
		s.backward = false
	elseif not s.backward and math.abs(angle) > math.rad(100) then
		s.backward = true
	end
	local folded = if s.backward then wrap(angle + math.pi) else angle
	turnFeet(s, input.yaw, input.grounded, dt)
	-- Standing, the hips turn part way toward the feet.
	local standing = G.hipFollow.value * (s.feet[1] + s.feet[2]) / 2
	local hipTarget = -math.clamp(folded * G.hipTurn.value, -G.hipTurnMax.value, G.hipTurnMax.value) * s.moving + standing * (1 - s.moving)
	s.hipYaw = approach(s.hipYaw, hipTarget, dt, 0.15)

	-- Off the ground and back on it.
	if input.grounded then
		if s.airTime > G.landFrom.value then
			s.land = math.clamp(s.airTime / G.landLongest.value, 0, 1)
		end
		s.airTime = 0
		s.air = approach(s.air, 0, dt, 0.05)
	else
		s.airTime += dt
		s.air = approach(s.air, 1, dt, 0.07)
	end
	s.land = math.max(0, s.land - dt / G.landTime.value)

	-- Reloading, planting, gliding, drawing.
	if input.reloading and not s.reloading then
		s.reloadTime = 0
		s.reloadShare = 0
	end
	s.reloading = input.reloading
	s.reloadLength = input.reloadLength or BodyConfig.Hold.reloadCycle.value
	if input.reloading then
		s.reloadTime += dt
		s.reloadShare = math.min(s.reloadShare + dt / math.max(s.reloadLength, 0.1), 1)
	end
	local since = input.sinceShot
	s.kick = if since and since >= 0 then math.exp(-since / BodyConfig.Hold.kickTime.value) else 0
	s.reload = approach(s.reload, if input.reloading then 1 else 0, dt, 0.1)
	s.plant = approach(s.plant, if input.channel == 1 or input.channel == 2 then 1 else 0, dt, 0.25)
	s.orb = approach(s.orb, if input.channel == 3 then 1 else 0, dt, 0.15)
	s.glide = approach(s.glide, if input.gliding and not input.grounded then 1 else 0, dt, 0.12)
	if input.hold ~= s.hold then
		s.previous = s.hold
		s.draw = 0
	else
		s.draw += dt
	end

	s.position = input.position
	s.yaw = input.yaw
	s.pitch = input.pitch
	s.crouch = math.clamp(input.crouch, 0, 1)
	s.grounded = input.grounded
	s.hold = input.hold
	s.foregrip = input.foregrip
	s.channel = input.channel
end

return BodyMotion
