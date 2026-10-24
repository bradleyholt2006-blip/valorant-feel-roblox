--!strict
-- One player's full deterministic simulation: movement + weapons + hit slow.
--
-- This is the unit that client prediction and server authority both step,
-- once per 128 Hz tick, from the same input. Anything that changes a
-- player's future (equipped weapon, ammo, reload timer, tag slow) lives here
-- so reconciliation can rewind and replay all of it together.

-- Require-by-string: "./" is this module's siblings in Roblox and this file's
-- directory in the offline tests.
local MovementSim = require("./Movement/MovementSim")
local WeaponSim = require("./Weapons/WeaponSim")
local WeaponConfig = require("./Weapons/WeaponConfig")
local Accuracy = require("./Weapons/Accuracy")

export type State = {
	movement: MovementSim.State,
	weapons: WeaponSim.State,
	tagUntilTick: number,
	tagMultiplier: number,
}

local PlayerSim = {}

PlayerSim.Buttons = MovementSim.Buttons

-- Below the deadzone speed a weapon counts as standing still. The test is
-- strict, with a margin, because Patch 3.0 put the hit slow and the deadzone
-- both at 27.5%: a player running into a tag sits exactly on the line and
-- must stay inaccurate (that patch removed "tag into accuracy").
local DEADZONE_MARGIN = 1e-3 -- m/s

-- `seed` drives the random part of every shot this life (server-chosen).
function PlayerSim.new(feet: vector, loadout: { string }?, seed: number?): State
	return {
		movement = MovementSim.newState(feet),
		weapons = WeaponSim.newState(loadout, seed),
		tagUntilTick = 0,
		tagMultiplier = 1,
	}
end

function PlayerSim.copy(s: State): State
	return {
		movement = MovementSim.copy(s.movement),
		weapons = WeaponSim.copy(s.weapons),
		tagUntilTick = s.tagUntilTick,
		tagMultiplier = s.tagMultiplier,
	}
end

function PlayerSim.def(s: State): WeaponConfig.WeaponDef
	return WeaponSim.equippedDef(s.weapons)
end

-- Run speed of the equipped weapon before ADS/tag modifiers.
function PlayerSim.weaponSpeed(s: State, cfg: any): number
	return cfg.baseRunSpeed * PlayerSim.def(s).moveMultiplier.value
end

function PlayerSim.isTagged(s: State): boolean
	return s.movement.tick < s.tagUntilTick
end

function PlayerSim.maxSpeed(s: State, cfg: any): number
	local def = PlayerSim.def(s)
	local speed = PlayerSim.weaponSpeed(s, cfg)
	if s.weapons.scoped > 0 and def.ads then
		speed *= def.ads.moveMultiplier.value
	end
	if PlayerSim.isTagged(s) then
		speed *= s.tagMultiplier
	end
	return speed
end

function PlayerSim.deadzoneFraction(s: State, cfg: any): number
	local override = PlayerSim.def(s).deadzoneFraction
	return if override then override.value else cfg.deadzoneFraction
end

-- Speed below which the equipped weapon counts as stationary (m/s).
function PlayerSim.deadzoneSpeed(s: State, cfg: any): number
	return PlayerSim.weaponSpeed(s, cfg) * PlayerSim.deadzoneFraction(s, cfg)
end

function PlayerSim.isAccurate(s: State, cfg: any): boolean
	return s.movement.grounded and MovementSim.horizontalSpeed(s.movement) < PlayerSim.deadzoneSpeed(s, cfg) - DEADZONE_MARGIN
end

-- Movement state for the cone of fire. Binary, like the reference: walk
-- accuracy needs the walk key and walking speed, so slowing from a run to a
-- stop never passes through it (Patch 0.50).
function PlayerSim.moveState(s: State, buttons: number, cfg: any): Accuracy.MoveState
	local m = s.movement
	if not m.grounded then
		return "air"
	end
	local speed = MovementSim.horizontalSpeed(m)
	if speed < PlayerSim.deadzoneSpeed(s, cfg) - DEADZONE_MARGIN then
		return "still"
	elseif m.crouched then
		return "crouch"
	elseif MovementSim.has(buttons, PlayerSim.Buttons.Walk) and speed <= PlayerSim.maxSpeed(s, cfg) * cfg.walkMultiplier + DEADZONE_MARGIN then
		return "walk"
	end
	return "run"
end

function PlayerSim.accuracyContext(s: State, buttons: number, cfg: any, dt: number): Accuracy.Context
	local m = s.movement
	return {
		moveState = PlayerSim.moveState(s, buttons, cfg),
		crouched = m.crouched,
		landing = m.grounded and (m.tick - m.lastLandTick) * dt < cfg.jumpLandPenaltyTime - 1e-9,
	}
end

function PlayerSim.eye(s: State, cfg: any): vector
	return s.movement.position + vector.create(0, MovementSim.eyeHeight(s.movement, cfg), 0)
end

-- Advance one tick. Returns the shot fired this tick, if any.
function PlayerSim.step(s: State, input: any, cfg: any, world: any, dt: number): WeaponSim.Shot?
	MovementSim.step(s.movement, input, cfg, PlayerSim.maxSpeed(s, cfg), world, dt)
	local tick = s.movement.tick
	local ctx = PlayerSim.accuracyContext(s, input.buttons, cfg, dt)
	return WeaponSim.step(s.weapons, input, tick * dt, dt, PlayerSim.eye(s, cfg), tick, ctx)
end

-- Hit slow, applied by the server between ticks. Speed is clamped at once and
-- the cap holds for `duration` seconds of the victim's own ticks.
function PlayerSim.applyTag(s: State, cfg: any, multiplier: number, duration: number, dt: number)
	s.tagMultiplier = multiplier
	s.tagUntilTick = s.movement.tick + math.ceil(duration / dt)
	local v = s.movement.velocity
	local h = vector.create(v.x, 0, v.z)
	local speed = vector.magnitude(h)
	local cap = PlayerSim.maxSpeed(s, cfg)
	if speed > cap and speed > 1e-6 then
		local scaled = h * (cap / speed)
		s.movement.velocity = vector.create(scaled.x, v.y, scaled.z)
	end
end

return PlayerSim
