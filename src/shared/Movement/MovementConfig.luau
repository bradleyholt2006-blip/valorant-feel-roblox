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
	deadzoneFraction = p(0.30, "confirmed", "Patch 0.50: 'Deadzone accuracy speed threshold increased: 25% >> 30%'"),

	-- Speed multipliers relative to the equipped weapon's run speed.
	walkMultiplier = p(0.55, "estimate", "No public number found; measure walk speed over a known distance"),
	crouchMultiplier = p(0.35, "estimate", "No public number found; measure crouch-walk speed over a known distance"),

	-- Source/UE-style ground model: friction (1/s) decays speed, acceleration
	-- (1/s, scaled by wish speed) pushes toward the wish velocity.
	groundAcceleration = p(11.0, "estimate", "Tuned so 0 -> max takes ~0.2s; measure with movement-error indicator"),
	groundFriction = p(9.0, "estimate", "Tuned so release-only stop crosses the 30% deadzone in ~0.13s"),
	stopSpeed = p(2.0, "estimate", "Friction floor in m/s; makes the last part of a stop linear, like Source"),

	airAcceleration = p(1.5, "estimate", "Air control is weak in the reference; tune from strafe-jump footage"),
	airWishSpeedCap = p(0.8, "estimate", "Caps air wish speed (m/s) so air strafing can't build speed"),

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
	groundAcceleration: number,
	groundFriction: number,
	stopSpeed: number,
	airAcceleration: number,
	airWishSpeedCap: number,
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
