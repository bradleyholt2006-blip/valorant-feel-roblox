--!strict
-- One player's full deterministic simulation: movement + weapons + hit slow,
-- the spike's plant and defuse (system 12), and the ability kit (system 17),
-- whose Blade Storm puts its knives in the weapons' hand (system 19), as
-- Curveball does its flare (system 30), Hot Hands its fireball (system 31),
-- Blaze its flame (system 32) and the Healing Orb its orb (system 36), and
-- whose Run it Back holds the player through his return and puts him back
-- at its mark (system 33).
--
-- This is the unit that client prediction and server authority both step,
-- once per 128 Hz tick, from the same input. Anything that changes a
-- player's future (equipped weapon, ammo, reload timer, tag slow, a plant
-- under way) lives here so reconciliation can rewind and replay all of it
-- together.

-- Require-by-string: "./" is this module's siblings in Roblox and this file's
-- directory in the offline tests.
local MovementSim = require("./Movement/MovementSim")
local WeaponSim = require("./Weapons/WeaponSim")
local WeaponConfig = require("./Weapons/WeaponConfig")
local Accuracy = require("./Weapons/Accuracy")
local Spike = require("./Spike/Spike")
local SpikeSim = require("./Spike/SpikeSim")
local AbilitySim = require("./Abilities/AbilitySim")
local AbilityConfig = require("./Abilities/AbilityConfig")

export type State = {
	movement: MovementSim.State,
	weapons: WeaponSim.State,
	spike: SpikeSim.State,
	abilities: AbilitySim.State,
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
		spike = SpikeSim.new(),
		abilities = AbilitySim.new(),
		tagUntilTick = 0,
		tagMultiplier = 1,
	}
end

function PlayerSim.copy(s: State): State
	return {
		movement = MovementSim.copy(s.movement),
		weapons = WeaponSim.copy(s.weapons),
		spike = SpikeSim.copy(s.spike),
		abilities = AbilitySim.copy(s.abilities),
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

-- Whether a plant or a defuse has the player rooted.
function PlayerSim.rooted(s: State): boolean
	return s.spike.channel ~= SpikeSim.NONE
end

-- Buttons that start a plant or a defuse, which a dash doesn't.
local SPIKE_KEYS = bit32.bor(PlayerSim.Buttons.Use, PlayerSim.Buttons.Fire)

local HOLD: MovementSim.Motion = { hold = true }

-- A tick of Run it Back's return at `t` (system 33), with what started in
-- it, if anything (AbilitySim.comeBack): nothing pressed counts, so a plant
-- or a defuse under way ends as if let go of (Patches 1.04 and 1.05 fixed
-- one carrying on), nothing moves him, and what's in the fifth slot goes
-- with his body. Back at the mark ("rise") he stands as he did as he cast
-- it, his guns reloaded (Patch 1.0) and the one in hand drawn again, ready
-- as he's risen (Patch 5.07). The way he faces is the input's: the client
-- turns him back to the mark's as he rises.
local function held(s: State, input: any, cfg: any, world: any, dt: number, objective: Spike.Context?, t: number, back: AbilitySim.Cast?)
	local still = table.clone(input)
	still.buttons = 0
	local act = SpikeSim.step(s.spike, s.movement, s.weapons, still, t, s.movement.tick + 1, PlayerSim.eye(s, cfg), objective or Spike.NONE)
	local kit, w = s.abilities, s.weapons
	if w.loadout[WeaponSim.ULT] ~= "" and w.loadout[WeaponSim.ULT] ~= AbilitySim.carried(kit) then
		WeaponSim.putAway(w, t)
	end
	WeaponSim.holster(w)
	if back and back.kind == "rise" then
		local m = MovementSim.newState(kit.mark)
		m.tick = s.movement.tick
		m.grounded = kit.markGrounded
		m.crouched = kit.markCrouched
		m.crouchAlpha = if kit.markCrouched then 1 else 0
		s.movement = m
		s.tagUntilTick = 0
		for slot = 1, 2 do
			WeaponSim.reloadNow(w, slot)
		end
		WeaponSim.redraw(w, t)
		w.equipEndTime = math.max(w.equipEndTime, AbilitySim.risen(kit))
	end
	MovementSim.step(s.movement, still, cfg, PlayerSim.maxSpeed(s, cfg), world, dt, HOLD)
	return act, if back then { back } else nil
end

-- Advance one tick. Returns the bullets fired this tick, if any (one round's:
-- several for a shotgun), the knife swing that started, if one did, what
-- happened with the spike, if anything, the gun G let go of, if it did
-- (system 15), and the abilities cast, if any (system 17). `objective` is
-- what this player can do with the spike now (Spike.NONE when nothing).
function PlayerSim.step(
	s: State,
	input: any,
	cfg: any,
	world: any,
	dt: number,
	objective: Spike.Context?
): ({ WeaponSim.Shot }?, WeaponSim.Swing?, SpikeSim.Act?, WeaponSim.Dropped?, { AbilitySim.Cast }?)
	-- Run it Back's return goes before anything (system 33): through it the
	-- player's held. Then the plant and the defuse: the tick they start on,
	-- they root, and nothing's cast. G lets go of the spike if it's in hand
	-- (SpikeSim), and otherwise of the gun in hand, once nothing is under
	-- way.
	local t = (s.movement.tick + 1) * dt
	local kit = s.abilities
	local holding, back = AbilitySim.comeBack(kit, t, dt, s.movement.tick + 1, s.movement.position, PlayerSim.eye(s, cfg))
	if holding then
		local heldAct, heldCasts = held(s, input, cfg, world, dt, objective, t, back)
		return nil, nil, heldAct, nil, heldCasts
	end
	local dropPressed = MovementSim.has(input.buttons, PlayerSim.Buttons.Drop) and not s.spike.dropHeld
	local spikeInput = input
	if AbilitySim.dashing(s.abilities, t) then
		spikeInput = table.clone(input)
		spikeInput.buttons = bit32.band(input.buttons, bit32.bnot(SPIKE_KEYS))
	end
	local act =
		SpikeSim.step(s.spike, s.movement, s.weapons, spikeInput, t, s.movement.tick + 1, PlayerSim.eye(s, cfg), objective or Spike.NONE)
	local moveInput = input
	if PlayerSim.rooted(s) then
		moveInput = table.clone(input)
		moveInput.buttons = SpikeSim.movementButtons(s.spike, input.buttons)
	end
	local feet, eye = s.movement.position, PlayerSim.eye(s, cfg)
	local grounded, crouched = s.movement.grounded, s.movement.crouched
	local motion, casts = AbilitySim.step(kit, input, t, dt, s.movement.tick + 1, feet, eye, PlayerSim.rooted(s), cfg)
	MovementSim.step(s.movement, moveInput, cfg, PlayerSim.maxSpeed(s, cfg), world, dt, motion)
	-- A throw puts the gun away for a moment (system 18). Blade Storm's cast
	-- puts its knives in hand, and X draws them again (system 19). An
	-- ability's key puts what it throws in hand: Curveball's flare (system
	-- 30), Hot Hands' fireball (system 31), Blaze's flame (system 32). Run
	-- it Back's cast puts away what's in the fifth slot, and the gun through
	-- its activation, and its mark keeps how he stood (system 33).
	if casts then
		for _, cast in casts do
			if cast.kind == "throw" then
				WeaponSim.stow(s.weapons, t, AbilityConfig.Cloudburst.stow.value)
			elseif cast.kind == "storm" then
				local weapon = AbilityConfig.Defs[cast.ability].weapon
				if weapon then
					WeaponSim.arm(s.weapons, weapon, t, AbilityConfig.BladeStorm.windup.value, input.slot)
				end
			elseif cast.kind == "draw" then
				WeaponSim.takeUp(s.weapons, t, input.slot)
			elseif cast.kind == "equip" then
				local weapon = AbilityConfig.Defs[cast.ability].weapon
				if weapon then
					WeaponSim.arm(s.weapons, weapon, t, WeaponConfig.get(weapon).equipTime.value, input.slot)
				end
			elseif cast.kind == "mark" then
				kit.markGrounded, kit.markCrouched = grounded, crouched
				if s.weapons.loadout[WeaponSim.ULT] ~= "" then
					WeaponSim.putAway(s.weapons, t)
				end
				WeaponSim.stow(s.weapons, t, AbilityConfig.RunItBack.activation.value)
			end
		end
	end
	-- A plant or a defuse puts an ability in hand away, and lets go of a
	-- wall being bent.
	if PlayerSim.rooted(s) then
		kit.holding = 0
		kit.steering, kit.steerUntil = 0, 0
	end
	-- What's in the fifth slot goes once what put it there is over: Blade
	-- Storm's knives as the server ends it between ticks (a death, a new
	-- round or a new kit), and an ability's once it's put away.
	local carried = s.weapons.loadout[WeaponSim.ULT]
	if carried ~= "" and carried ~= AbilitySim.carried(kit) then
		WeaponSim.putAway(s.weapons, t)
	end
	-- A wall being bent (Blaze, system 32): its flame stays in hand while
	-- fire's held, until its run's over, and the gun's back a moment after
	-- it's let go (Patch 5.01). Anything else drawn lets go of it too.
	if kit.steering ~= 0 then
		if s.weapons.loadout[WeaponSim.ULT] == "" or s.weapons.equipped ~= WeaponSim.ULT then
			kit.steering, kit.steerUntil = 0, 0
			WeaponSim.putAway(s.weapons, t)
		elseif not MovementSim.has(input.buttons, PlayerSim.Buttons.Fire) or t >= kit.steerUntil - 1e-9 then
			local def = AbilitySim.def(kit, kit.steering)
			kit.steering, kit.steerUntil = 0, 0
			WeaponSim.putAway(s.weapons, t, AbilityConfig.unequip(if def then def.id else ""))
		end
	end
	local tick = s.movement.tick
	-- A defuse has the weapon put away.
	if s.spike.channel == SpikeSim.DEFUSING then
		return nil, nil, act, nil, casts
	end
	-- Nothing fires in a dash, which takes the zoom off and stops a burst
	-- (ours).
	if motion.dash then
		s.weapons.scoped = 0
		s.weapons.burstLeft = 0
		return nil, nil, act, nil, casts
	end
	local dropped: WeaponSim.Dropped? = nil
	if dropPressed and act == nil and s.spike.channel == SpikeSim.NONE then
		dropped = WeaponSim.takeInHand(s.weapons, t)
	end
	local ctx = PlayerSim.accuracyContext(s, input.buttons, cfg, dt)
	local shots, swing = WeaponSim.step(s.weapons, input, tick * dt, dt, PlayerSim.eye(s, cfg), tick, ctx)
	-- And Blade Storm is over once its knives are gone.
	if s.abilities.storm and s.weapons.loadout[WeaponSim.ULT] == "" then
		s.abilities.storm = false
	end
	-- An ability in hand (system 30): what it fires is its throw, the
	-- ability's cast and no bullet, and the gun's back in hand a moment
	-- after, or once the wall it sent out is let go (Blaze, system 32). The
	-- Healing Orb's is a try (system 36), and it stays in hand for the next,
	-- until the server finds one heals and puts it away. Anything else drawn
	-- puts it away unthrown.
	if kit.holding ~= 0 then
		local held = s.weapons.loadout[WeaponSim.ULT]
		local shot = if shots and held ~= "" and shots[1].weapon == held then shots[1] else nil
		if shot then
			shots = nil
			local def = AbilitySim.def(kit, kit.holding)
			local cast = AbilitySim.thrown(kit, tick, t, s.movement.position, shot.origin, shot.aim, shot.mode == "alt")
			if cast then
				local list = casts or {}
				table.insert(list, cast)
				casts = list
			end
			if kit.holding ~= 0 then
				WeaponSim.refill(s.weapons, WeaponSim.ULT)
			elseif kit.steering ~= 0 then
				WeaponSim.keep(s.weapons, kit.steerUntil)
			else
				WeaponSim.putAway(s.weapons, t, AbilityConfig.unequip(if def then def.id else ""))
			end
		elseif held == "" or s.weapons.equipped ~= WeaponSim.ULT then
			kit.holding = 0
			WeaponSim.putAway(s.weapons, t)
		end
	end
	return shots, swing, act, dropped, casts
end

-- What a single Blade Storm knife does with a kill this player made with
-- `weapon`, fired in `mode` (a shot's, nil for a swing), applied by the
-- server between ticks: all the knives back (system 19), as they come back
-- for a Phoenix it would have killed in his Run it Back, though nobody's
-- killed him (Patch 1.02: it 'now refreshes when used to kill Phoenix
-- during Run It Back', system 33). Its burst's kills bring none back
-- (Patch 3.06).
function PlayerSim.knivesBack(s: State, weapon: string, mode: string?)
	if mode == "hip" and weapon ~= "" and s.weapons.loadout[WeaponSim.ULT] == weapon then
		WeaponSim.refill(s.weapons, WeaponSim.ULT)
	end
end

-- A kill this player made with `weapon`, fired in `mode`, applied by the
-- server between ticks: the kit's point, or the mode's `points`, and the
-- signature's count (AbilitySim.killed), and a Blade Storm knife's all
-- back (knivesBack).
function PlayerSim.killedWith(s: State, weapon: string, mode: string?, points: number?)
	AbilitySim.killed(s.abilities, points)
	PlayerSim.knivesBack(s, weapon, mode)
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
