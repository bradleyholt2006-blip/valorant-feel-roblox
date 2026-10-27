--!strict
-- One player's full deterministic simulation: movement + weapons + hit slow,
-- the spike's plant and defuse (system 12), and the ability kit (system 17),
-- whose Blade Storm puts its knives in the weapons' hand (system 19), as
-- Curveball does its flare (system 30), Hot Hands its fireball (system 31),
-- Blaze its flame (system 32), the Healing Orb its orb (system 36), the Slow
-- Orb its own (system 37), the Barrier Orb its own (system 38), the
-- Resurrection its own (system 39), Dark Cover its own (system 40),
-- Shrouded Step its own (system 42), From the Shadows its map (system 43)
-- and the Recon Bolt its bow, drawn and loosed by the kit (system 44), as
-- the Shock Bolt does (system 45), and
-- whose Run it Back holds the player through his return and puts
-- him back at its mark (system 33), as the Resurrection holds a life it
-- brings back, rising with the body and then falling to the floor (system
-- 39), Shrouded Step holds him through its windup and his time gone, and
-- puts him where it marked (system 42), and From the Shadows holds him
-- through its windup and his time as a Shade, which it puts where the map
-- marked (system 43). A Slow Orb's field slows whoever starts a tick in it
-- (SlowSim), from the fields each step's given, and a Barrier Orb's wall
-- stands in the world everything in the tick goes through
-- (BarrierSim.world), from the walls it's given.
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
local SmokeSim = require("./Abilities/SmokeSim")
local SlowSim = require("./Abilities/SlowSim")
local BarrierSim = require("./Abilities/BarrierSim")
local StepSim = require("./Abilities/StepSim")
local ShadowSim = require("./Abilities/ShadowSim")

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
local RES = AbilityConfig.Resurrection
local UP = vector.create(0, 1, 0)

-- A tick at `t` of a life the Resurrection brought back, while it's held
-- (system 39): nothing pressed counts, and the gun's away until control's
-- back. Until they burst out they rise with the body, out of harm's way,
-- at its steady speed (the server starts the life as high as the body's
-- risen by then); then they fall to the floor under them.
local function revived(s: State, input: any, cfg: any, world: any, dt: number, t: number)
	local still = table.clone(input)
	still.buttons = 0
	local kit = s.abilities
	WeaponSim.stow(s.weapons, t, kit.heldUntil - t)
	local motion: MovementSim.Motion? = nil
	if AbilitySim.floating(kit, t) then
		s.movement.position += UP * (RES.height.value / RES.rise.value * dt)
		motion = HOLD
	end
	MovementSim.step(s.movement, still, cfg, PlayerSim.maxSpeed(s, cfg), world, dt, motion)
end

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

-- Puts him standing still on the floor at `feet`, as a step or a teleport
-- leaves him (systems 42 and 43), the hit slow gone with where he was.
local function standAt(s: State, feet: vector)
	local m = MovementSim.newState(feet)
	m.tick = s.movement.tick
	m.grounded = true
	s.movement = m
	s.tagUntilTick = 0
end

-- A tick of Shrouded Step at `t` (system 42), with what started in it, if
-- anything (AbilitySim.stepThrough): nothing pressed counts but crouch, so
-- he can't move, fire or cast, and a plant or a defuse under way ends as
-- if let go of; the gun stays away. Through its windup he falls and slides
-- on as he was. As it ends ("vanish") he's standing on the floor it
-- marked, and held there, gone, until he's there.
local function stepping(
	s: State,
	input: any,
	cfg: any,
	world: any,
	dt: number,
	objective: Spike.Context?,
	t: number,
	step: AbilitySim.Cast?
)
	local still = table.clone(input)
	still.buttons = bit32.band(input.buttons, PlayerSim.Buttons.Crouch)
	local act = SpikeSim.step(s.spike, s.movement, s.weapons, still, t, s.movement.tick + 1, PlayerSim.eye(s, cfg), objective or Spike.NONE)
	WeaponSim.holster(s.weapons)
	local kit = s.abilities
	if step and step.kind == "vanish" then
		standAt(s, kit.stepTo)
	end
	local motion = if AbilitySim.shrouded(kit, t) then HOLD else nil
	MovementSim.step(s.movement, still, cfg, PlayerSim.maxSpeed(s, cfg), world, dt, motion)
	return act, if step then { step } else nil
end

-- A tick of From the Shadows at `t` (system 43), with what started in it,
-- if anything (AbilitySim.shadowThrough): nothing pressed counts but
-- crouch, so he can't move, fire or cast, and a plant or a defuse under way
-- ends as if let go of, though he looks round as he likes ('he will still
-- be able to rotate his body', the VALORANT Wiki); the gun stays away.
-- Through its windup he comes to rest where he is. As it ends ("shade")
-- he's standing on the floor it marked, a Shade held there; sent back
-- ("home"), he's standing where he became one, his gun drawn again.
local function shadowing(
	s: State,
	input: any,
	cfg: any,
	world: any,
	dt: number,
	objective: Spike.Context?,
	t: number,
	shadow: AbilitySim.Cast?
)
	local still = table.clone(input)
	still.buttons = bit32.band(input.buttons, PlayerSim.Buttons.Crouch)
	local act = SpikeSim.step(s.spike, s.movement, s.weapons, still, t, s.movement.tick + 1, PlayerSim.eye(s, cfg), objective or Spike.NONE)
	WeaponSim.holster(s.weapons)
	local kit = s.abilities
	if shadow and shadow.kind == "shade" then
		standAt(s, kit.shadowTo)
	elseif shadow and shadow.kind == "home" then
		standAt(s, shadow.position)
		WeaponSim.redraw(s.weapons, t)
	end
	local motion = if AbilitySim.shaded(kit, t) then HOLD else nil
	MovementSim.step(s.movement, still, cfg, PlayerSim.maxSpeed(s, cfg), world, dt, motion)
	return act, if shadow then { shadow } else nil
end

-- Advance one tick. Returns the bullets fired this tick, if any (one round's:
-- several for a shotgun), the knife swing that started, if one did, what
-- happened with the spike, if anything, the gun G let go of, if it did
-- (system 15), and the abilities cast, if any (system 17). `objective` is
-- what this player can do with the spike now (Spike.NONE when nothing),
-- `slows` the Slow Orbs' fields in play and the time they're judged at
-- (system 37), and `barriers` the Barrier Orbs' walls and theirs (system
-- 38): none without.
function PlayerSim.step(
	s: State,
	input: any,
	cfg: any,
	world: any,
	dt: number,
	objective: Spike.Context?,
	slows: SlowSim.Slows?,
	barriers: BarrierSim.Walls?
): ({ WeaponSim.Shot }?, WeaponSim.Swing?, SpikeSim.Act?, WeaponSim.Dropped?, { AbilitySim.Cast }?)
	-- The walls standing in the world everything this tick goes through.
	if barriers then
		world = BarrierSim.world(world, barriers.walls, barriers.time)
	end
	-- A life the Resurrection brought back is held first (system 39), and
	-- Run it Back's return goes before anything else (system 33): through it
	-- the player's held. Then the plant and the defuse: the tick they start
	-- on, they root, and nothing's cast. G lets go of the spike if it's in
	-- hand (SpikeSim), and otherwise of the gun in hand, once nothing is
	-- under way.
	local t = (s.movement.tick + 1) * dt
	local kit = s.abilities
	if AbilitySim.reviving(kit, t) then
		revived(s, input, cfg, world, dt, t)
		return nil, nil, nil, nil, nil
	end
	local holding, back = AbilitySim.comeBack(kit, t, dt, s.movement.tick + 1, s.movement.position, PlayerSim.eye(s, cfg))
	if holding then
		local heldAct, heldCasts = held(s, input, cfg, world, dt, objective, t, back)
		return nil, nil, heldAct, nil, heldCasts
	end
	-- Shrouded Step's windup and his time gone hold him too (system 42); he's
	-- free the tick he's there, which it tells of with the tick's casts.
	local look = Accuracy.aim(input.yaw, input.pitch)
	local shrouded, step = AbilitySim.stepThrough(kit, t, dt, s.movement.tick + 1, s.movement.position, PlayerSim.eye(s, cfg), look)
	if shrouded then
		local stepAct, stepCasts = stepping(s, input, cfg, world, dt, objective, t, step)
		return nil, nil, stepAct, nil, stepCasts
	end
	-- So do From the Shadows' windup and his time as a Shade (system 43); he's
	-- free the tick he's there for good, which it tells of with the tick's
	-- casts, his gun drawn again at the normal speed (the VALORANT Wiki).
	local shading, shadow =
		AbilitySim.shadowThrough(kit, t, dt, s.movement.tick + 1, s.movement.position, PlayerSim.eye(s, cfg), look, input.buttons)
	if shading then
		local shadowAct, shadowCasts = shadowing(s, input, cfg, world, dt, objective, t, shadow)
		return nil, nil, shadowAct, nil, shadowCasts
	end
	if shadow then
		WeaponSim.redraw(s.weapons, t)
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
	-- He's there (Shrouded Step), or there for good (From the Shadows): never
	-- both, as neither starts while the other's under way.
	local over = step or shadow
	if over then
		local list = casts or {}
		table.insert(list, 1, over)
		casts = list
	end
	-- Standing in a Slow Orb's field as the tick starts, they're slowed
	-- through it (system 37).
	if slows and SlowSim.slowed(slows.fields, feet, slows.time, cfg.halfWidth) then
		motion.slow = SlowSim.SLOW
	end
	MovementSim.step(s.movement, moveInput, cfg, PlayerSim.maxSpeed(s, cfg), world, dt, motion)
	-- Dark Cover's orb sent (system 40): once it's ready in hand, to the
	-- floor under its mark, where its smoke goes, spending its charge and
	-- putting it away; with no floor there, or before it's ready, nothing's
	-- sent and it stays in hand.
	if casts then
		local sent = {}
		for _, cast in casts do
			if cast.kind ~= "smoke" then
				table.insert(sent, cast)
				continue
			end
			local w = s.weapons
			local ready = w.equipped == WeaponSim.ULT and t >= w.equipEndTime - 1e-9 and kit.charges[cast.slot] > 0
			local centre = if ready then SmokeSim.place(world, cast.origin, cast.direction, cast.reach or 0) else nil
			if centre then
				cast.smoke = centre
				AbilitySim.used(kit, cast.slot)
				WeaponSim.putAway(w, t, AbilityConfig.unequip(cast.ability))
				table.insert(sent, cast)
			end
		end
		casts = if #sent > 0 then sent else nil
	end
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
				-- Dark Cover's mark starts where the crosshair meets the level.
				if cast.ability == "darkcover" then
					kit.reach = SmokeSim.start(world, cast.origin, cast.direction)
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
	-- Sova's bow in hand (the Recon Bolt's, system 44, or the Shock Bolt's,
	-- system 45) fires nothing: fire held draws its bolt once it's ready,
	-- alt fire adds bounces, and fire let go looses it, which puts it away
	-- (AbilitySim.bow).
	local inHand = AbilitySim.def(kit, kit.holding)
	local w = s.weapons
	if inHand and AbilitySim.bowed(inHand.id) and w.equipped == WeaponSim.ULT and w.loadout[WeaponSim.ULT] ~= "" then
		local ready = t >= w.equipEndTime - 1e-9
		local bolt = AbilitySim.bow(kit, t, input.buttons, ready, tick, s.movement.position, PlayerSim.eye(s, cfg), look)
		if bolt then
			local list = casts or {}
			table.insert(list, bolt)
			casts = list
			WeaponSim.putAway(w, t, AbilityConfig.unequip(bolt.ability))
		end
	end
	-- An ability in hand (system 30): what it fires is its throw, the
	-- ability's cast and no bullet, and the gun's back in hand a moment
	-- after, or once the wall it sent out is let go (Blaze, system 32). The
	-- Healing Orb's is a try (system 36), and it stays in hand for the next,
	-- until the server finds one heals and puts it away, as the
	-- Resurrection's is until one brings someone back (system 39). The
	-- Barrier Orb's
	-- wall goes where its targeter shows it, turned as the kit has it, and
	-- with nowhere to go, or in the buy phase, the orb stays in hand (system
	-- 38). Shrouded Step's starts its windup to where its mark shows, and
	-- with nowhere to step it stays in hand (system 42). From the Shadows'
	-- starts its windup to where the place picked on the map (the input's
	-- point) takes him, and with nowhere there, none picked, or in the buy
	-- phase, its map stays in hand (system 43). Anything else drawn puts it
	-- away unthrown.
	if kit.holding ~= 0 then
		local held = s.weapons.loadout[WeaponSim.ULT]
		local shot = if shots and held ~= "" and shots[1].weapon == held then shots[1] else nil
		if shot then
			shots = nil
			local def = AbilitySim.def(kit, kit.holding)
			local raising = def ~= nil and def.id == "barrierorb"
			-- Dark Cover's fire moves its mark (AbilitySim) and sends nothing.
			local smoking = def ~= nil and def.id == "darkcover"
			local open = not (barriers and barriers.closed)
			local placed = if raising and open
				then BarrierSim.place(world, shot.origin, shot.aim, BarrierSim.angle(input.yaw, kit.turn))
				else nil
			local stepper = def ~= nil and def.id == "shroudedstep"
			local to = if stepper then StepSim.place(world, shot.origin, shot.aim, cfg) else nil
			local shadower = def ~= nil and def.id == "fromtheshadows"
			local point: vector? = input.point
			local there = if shadower and open and point then ShadowSim.place(world, point, cfg) else nil
			local cast = if (raising and not placed)
					or smoking
					or (stepper and not to)
					or (shadower and not there)
				then nil
				else AbilitySim.thrown(kit, tick, t, s.movement.position, shot.origin, shot.aim, shot.mode == "alt")
			if cast then
				cast.wall = placed
				if to then
					cast.step = to
					AbilitySim.shroud(kit, t, to)
				end
				if there then
					cast.step = there
					AbilitySim.shadow(kit, t, there)
				end
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

-- A Shade sent back where he became one, applied by the server between
-- ticks as an enemy's hit breaks it (system 43), as X does in his own tick
-- (AbilitySim.home): he's standing there, his gun drawn again, as of `t`,
-- his last tick's time, looking along `look`. Returns its "home" cast, or
-- nil if he isn't a Shade.
function PlayerSim.home(s: State, cfg: any, t: number, look: vector): AbilitySim.Cast?
	local back = AbilitySim.home(s.abilities, t, s.movement.tick, s.movement.position, PlayerSim.eye(s, cfg), look)
	if back then
		standAt(s, back.position)
		WeaponSim.redraw(s.weapons, t)
	end
	return back
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
