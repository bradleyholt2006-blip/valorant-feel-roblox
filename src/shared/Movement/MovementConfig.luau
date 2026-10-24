--!strict
-- Movement tuning. Every number is in SI units (metres, seconds) so it can be
-- compared directly with measurements taken in the reference game. Conversion
-- to studs happens only at the Roblox boundary (see Units).
--
-- Each parameter carries a status:
--   "confirmed" - stated by the developer (patch notes / dev blog) or shown in-game
--   "community" - published by a wiki or community measurement, not by the developer
--   "estimate"  - our own guess; must be measured and tuned (see docs/research)
--
-- This module has no requires so it runs unchanged in Studio and the offline tests.

export type Status = "confirmed" | "community" | "estimate"

export type Param = {
	value: number,
	status: Status,
	source: string,
}

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local MovementConfig = {}

MovementConfig.TickRate = p(128, "confirmed", "Riot tech blog 'VALORANT's 128-Tick Servers'")

MovementConfig.Params = {
	-- Run speed with the knife; every weapon's speed is a multiplier of this
	-- (WeaponConfig.moveMultiplier), e.g. rifles 80% = 5.40 m/s.
	baseRunSpeed = p(6.75, "community", "Fandom wiki Melee page: 'standard run speed of 6.75 m/s'"),
	-- Below this fraction of max speed a weapon counts as stationary.
	deadzoneFraction = p(0.275, "confirmed", "Patch 3.0: 'Weapon Deadzones changed from 30% >>> 27.5%' (Patch 0.50 had raised it from 25% to 30%)"),

	-- Speed multipliers relative to the equipped weapon's run speed.
	walkMultiplier = p(
		0.61,
		"estimate",
		"Riot's 2020 stop timings (Riot_Classick, r/VALORANT) give 'Run -> Walk (61%)' as the point a stopping player reached walk accuracy, which suggests walking is 61% of run speed; measure walk speed over a known distance"
	),
	crouchMultiplier = p(0.35, "estimate", "No public number found; measure crouch-walk speed over a known distance"),

	-- Unreal-style ground model (see MovementSim): input accelerates at
	-- maxAcceleration, and letting go brakes at
	-- brakingFrictionFactor x groundFriction x speed + brakingDeceleration.
	-- Riot timed stops on the Phantom (Riot_Classick, r/VALORANT, 2020):
	-- counter-strafing reached 25% speed in 0.104 s and a full stop in 0.160 s,
	-- a stop without counter-strafing 0.110 s and 0.170 s.
	maxAcceleration = p(
		20.48,
		"estimate",
		"Unreal's default (2048 cm/s^2); with groundFriction it reproduces Riot's counter-strafe timings. Start-up (0 to full rifle speed in about 0.26 s) still needs measuring"
	),
	groundFriction = p(2.75, "estimate", "Fitted to Riot's counter-strafe timings at 128 Hz: 25% speed at 0.104 s, stopped at 0.160 s"),
	brakingFrictionFactor = p(
		2,
		"estimate",
		"Unreal's default. With brakingDeceleration = maxAcceleration, letting go brakes like counter-strafing, which is what Riot's timings show"
	),
	brakingDeceleration = p(20.48, "estimate", "Unreal's default (equal to maxAcceleration)"),

	-- Air movement (see MovementSim): Counter-Strike's air acceleration, so
	-- holding A or D while turning the mouse bends the path the way it does
	-- there, under the limit Valorant players report, that strafing and
	-- bunny hopping never beat running.
	airAcceleration = p(
		12,
		"estimate",
		"Counter-Strike's sv_airaccelerate (12 in CS:GO and CS2): input adds up to 12 x the wish speed per second. Check against footage of air stops and strafes"
	),
	airWishSpeedCap = p(
		0.57,
		"estimate",
		"Quake's and Source's cap of 30 units/s on the speed input adds along itself (Valve: maps are about 16 units to the foot, so 1.9 cm a unit). A standing jump drifts at this speed"
	),
	airSpeedLimit = p(
		1,
		"community",
		"Times the wish speed. Input in the air can't push the speed past it, or past what it already was: Valorant players report air strafing and bunny hopping don't beat running (Unreal forum, guides). Counter-Strike has no such limit"
	),

	gravity = p(15.0, "estimate", "Derive from airtime + apex: g = 8*h / t^2"),
	jumpApexHeight = p(0.85, "estimate", "Feet rise when jumping in place; measure against crates of known height"),

	stepHeight = p(0.35, "estimate", "Highest ledge walked up without jumping"),
	maxGroundAngle = p(46, "estimate", "Steepest walkable slope in degrees"),

	-- Collision box (axis aligned, like UE/Source capsules approximated by an AABB).
	halfWidth = p(0.34, "estimate", "Half the agent's collision width"),
	standHeight = p(1.80, "estimate", "Standing collision height"),
	crouchHeight = p(1.25, "estimate", "Crouched collision height"),
	standEyeHeight = p(1.62, "estimate", "Camera height above the feet when standing"),
	crouchEyeHeight = p(1.10, "estimate", "Camera height above the feet when crouched"),
	crouchTransitionTime = p(0.12, "estimate", "Seconds to go fully down or up"),

	-- Jump landing inaccuracy is a weapon value but the movement sim reports
	-- landings, so its timing lives here for the debug HUD.
	jumpLandPenaltyTime = p(0.225, "confirmed", "Patch 1.09: 'Jump land inaccuracy duration increased from .2 >>> .225'"),
}

export type Values = {
	baseRunSpeed: number,
	deadzoneFraction: number,
	walkMultiplier: number,
	crouchMultiplier: number,
	maxAcceleration: number,
	groundFriction: number,
	brakingFrictionFactor: number,
	brakingDeceleration: number,
	airAcceleration: number,
	airWishSpeedCap: number,
	airSpeedLimit: number,
	gravity: number,
	jumpApexHeight: number,
	stepHeight: number,
	maxGroundAngle: number,
	halfWidth: number,
	standHeight: number,
	crouchHeight: number,
	standEyeHeight: number,
	crouchEyeHeight: number,
	crouchTransitionTime: number,
	jumpLandPenaltyTime: number,
	-- derived
	jumpVelocity: number,
	minGroundNormalY: number,
}

-- Flattens Params into plain numbers. Pass overrides (e.g. from the debug
-- tuning panel) to experiment without editing this file.
function MovementConfig.resolve(overrides: { [string]: number }?): Values
	local out: { [string]: number } = {}
	for key, param in MovementConfig.Params :: { [string]: Param } do
		out[key] = param.value
	end
	if overrides then
		for key, value in overrides do
			out[key] = value
		end
	end
	out.jumpVelocity = math.sqrt(2 * out.gravity * out.jumpApexHeight)
	out.minGroundNormalY = math.cos(math.rad(out.maxGroundAngle))
	return (out :: any) :: Values
end

return MovementConfig
