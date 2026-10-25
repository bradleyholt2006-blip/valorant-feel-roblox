--!strict
-- Deterministic weapon state machine, stepped once per 128 Hz tick from the
-- same input stream as movement.
--
-- Putting weapons in the input stream (instead of sending "I fired" messages)
-- means the server re-runs exactly the client's trigger presses on its own
-- clock: fire rate, ammo, reload and equip times can't be cheated, and both
-- sides agree on which tick every shot happened. Shots are returned as events;
-- the caller (client effects, server hit resolution) decides what to do.
--
-- A weapon fires in the mode it's held in (WeaponConfig.mode): from the hip,
-- zoomed, or the Classic's right click. One trigger pull fires one round, or
-- in a burst mode a burst of rounds a fixed time apart that carries on by
-- itself. A round is a volley of bullets: one, or a shotgun's pellets, which
-- share the round's recoil and each take their own place in its cone.
--
-- The knife swings instead (system 10): the left button slashes and the
-- right one stabs, and each swing comes out as an event the same way, for
-- Melee to find what it caught.
--
-- Times are seconds of simulation time (tick * dt). 1/128 is exact in binary,
-- so client and server compute bit-identical times.

-- Shared simulation modules use require-by-string, which resolves the same way
-- in Roblox ("./" = siblings) and in the offline Luau tests (same directory).
local WeaponConfig = require("./WeaponConfig")
local Accuracy = require("./Accuracy")

export type State = {
	-- [slot] = weapon id, "" for empty: 1 primary, 2 secondary, 3 melee, and
	-- 4 the spike while it's carried (system 12)
	loadout: { string },
	ammo: { number }, -- [slot]
	reserve: { number }, -- [slot]
	equipped: number,
	equipEndTime: number, -- can't fire before this
	-- Can't pull the trigger again before this; recovery counts from it.
	nextFireTime: number,
	reloadEndTime: number, -- 0 when not reloading; for a round-at-a-time reload, when this round goes in
	scoped: number, -- 0 = hip, n = ads.zoom[n]
	fireHeld: boolean,
	altHeld: boolean,
	lastShotTime: number,
	sprayIndex: number, -- rounds in the current spray; fractional once partly recovered
	shotCounter: number, -- total bullets this life; picks each bullet's random numbers
	seed: number, -- per-life random seed, chosen by the server
	recoilYaw: number, -- sideways drift (degrees, + = right) the next round starts from
	swayDir: number, -- drift direction: -1, 1, or 0 before the drift starts
	burstLeft: number, -- rounds still to come in the burst under way
	burstNext: number, -- when its next round fires
	spin: number, -- 0-1: how far a spinning fire rate has risen (the Odin)
	-- The knife's last slash's place in its combo, 1-3; 0 when the next one
	-- starts it over (after a stab, a draw or a pause).
	combo: number,
}

export type Shot = {
	tick: number,
	time: number,
	slot: number,
	weapon: string,
	mode: WeaponConfig.ModeName,
	shotNumber: number,
	-- The bullets one round fires together: the first one's shot number, this
	-- bullet's place among them and how many there are.
	volley: number,
	pellet: number,
	pellets: number,
	sprayIndex: number, -- rounds before this one in the spray, after recovery
	bullet: number, -- sprayIndex + 1: the bullet number the curves are read at
	origin: vector, -- eye position, metres
	yaw: number,
	pitch: number,
	aim: vector, -- where the crosshair pointed
	direction: vector, -- where the bullet went: aim + recoil + cone offset
	recoilPitch: number, -- degrees up
	recoilYaw: number, -- degrees right
	cone: Accuracy.Cone,
	offset: number, -- degrees from the cone's centre
	offsetAngle: number, -- radians around the centre, 0 = right
	moveState: Accuracy.MoveState,
	scoped: number,
}

-- A gun let go of (G, system 15): its slot, and the rounds it takes to the
-- ground with it.
export type Dropped = { slot: number, id: string, ammo: number, reserve: number }

export type SwingKind = "slash" | "stab"

-- A knife swing, on the tick it starts.
export type Swing = {
	tick: number,
	time: number,
	weapon: string,
	kind: SwingKind,
	combo: number, -- a slash's place in its combo, 1-3; 0 for a stab
	origin: vector, -- eye position, metres
	yaw: number,
	pitch: number,
	direction: vector, -- where the crosshair pointed
}

local Buttons = {
	Fire = 128,
	AltFire = 256,
	Reload = 512,
}

local WeaponSim = {}

-- Slots a player has: the three weapons and the spike's.
local SLOTS = 4
WeaponSim.SLOTS = SLOTS

local EPS = 1e-9

local STILL: Accuracy.Context = { moveState = "still", crouched = false, landing = false }

local function has(buttons: number, flag: number): boolean
	return bit32.band(buttons, flag) ~= 0
end

function WeaponSim.newState(loadout: { string }?, seed: number?): State
	local ids = loadout or WeaponConfig.DefaultLoadout
	local s: State = {
		loadout = { ids[1] or "", ids[2] or "", ids[3] or "", ids[4] or "" },
		ammo = { 0, 0, 0, 0 },
		reserve = { 0, 0, 0, 0 },
		equipped = 1,
		equipEndTime = 0,
		nextFireTime = 0,
		reloadEndTime = 0,
		scoped = 0,
		fireHeld = false,
		altHeld = false,
		lastShotTime = -math.huge,
		sprayIndex = 0,
		shotCounter = 0,
		seed = (seed or 0) % 2 ^ 32,
		recoilYaw = 0,
		swayDir = 0,
		burstLeft = 0,
		burstNext = 0,
		spin = 0,
		combo = 0,
	}
	for slot = 1, SLOTS do
		WeaponSim.give(s, slot, s.loadout[slot])
	end
	-- Equip the first non-empty slot.
	for slot = 1, SLOTS do
		if s.loadout[slot] ~= "" then
			s.equipped = slot
			break
		end
	end
	return s
end

-- Starts drawing the weapon in the equipped slot: nothing can fire, reload or
-- scope until its equip time has passed, and the spray starts over.
local function draw(s: State, t: number)
	s.equipEndTime = t + WeaponConfig.get(s.loadout[s.equipped]).equipTime.value
	s.reloadEndTime = 0 -- switching cancels a reload
	s.scoped = 0
	s.sprayIndex = 0
	s.recoilYaw = 0
	s.swayDir = 0
	s.lastShotTime = -math.huge
	s.nextFireTime = 0
	s.burstLeft = 0
	s.burstNext = 0
	s.spin = 0
	s.combo = 0
end

-- Puts a weapon in a slot with full ammo (server-side loadout changes), or
-- with the rounds given (a gun picked up off the ground keeps what it had).
-- When the slot is the one in hand, pass the simulation time `t` so the new
-- weapon has to be drawn like any other switch.
function WeaponSim.give(s: State, slot: number, id: string, t: number?, ammo: number?, reserve: number?)
	s.loadout[slot] = id
	if id == "" then
		s.ammo[slot], s.reserve[slot] = 0, 0
		if slot == s.equipped then
			-- Nothing left in hand: the first slot with something in it.
			for other = 1, SLOTS do
				if s.loadout[other] ~= "" then
					s.equipped = other
					if t then
						draw(s, t)
					end
					break
				end
			end
		end
		return
	end
	local def = WeaponConfig.get(id)
	s.ammo[slot] = ammo or def.magazine.value
	s.reserve[slot] = reserve or def.reserve.value
	if t and slot == s.equipped then
		draw(s, t)
	end
end

-- Lets go of the gun in hand (G, system 15): a primary or a sidearm, never
-- the knife, and never the spike, which SpikeSim lets go of. The next weapon
-- is drawn, as when any slot in hand empties. Returns what was let go of,
-- with its rounds, if anything was.
function WeaponSim.takeInHand(s: State, t: number): Dropped?
	local slot = s.equipped
	local id = s.loadout[slot]
	if (slot ~= 1 and slot ~= 2) or id == "" then
		return nil
	end
	local def = WeaponConfig.get(id)
	if def.melee or def.spike then
		return nil
	end
	local dropped = { slot = slot, id = id, ammo = s.ammo[slot], reserve = s.reserve[slot] }
	WeaponSim.give(s, slot, "", t)
	return dropped
end

-- Draws the weapon in hand again, as after a switch (once the spike has
-- left the hand, or a defuse ends).
function WeaponSim.redraw(s: State, t: number)
	draw(s, t)
	s.fireHeld = false
	s.altHeld = false
end

-- Puts the weapon in hand away (for a defuse): a reload, a zoom or a burst
-- under way stops.
function WeaponSim.holster(s: State)
	s.reloadEndTime = 0
	s.scoped = 0
	s.burstLeft = 0
	s.spin = 0
end

function WeaponSim.copy(s: State): State
	local c = table.clone(s)
	c.loadout = table.clone(s.loadout)
	c.ammo = table.clone(s.ammo)
	c.reserve = table.clone(s.reserve)
	return c
end

function WeaponSim.equippedDef(s: State): WeaponConfig.WeaponDef
	return WeaponConfig.get(s.loadout[s.equipped])
end

function WeaponSim.isReloading(s: State): boolean
	return s.reloadEndTime > 0
end

-- Seconds between rounds as the weapon is held (`scoped` as in State), within
-- a burst for a burst mode.
function WeaponSim.fireInterval(def: WeaponConfig.WeaponDef, scoped: number): number
	return WeaponConfig.mode(def, scoped).interval
end

-- Seconds between rounds in `mode` once a spinning fire rate has risen by `spin`.
function WeaponSim.spinInterval(mode: WeaponConfig.Mode, spin: number): number
	local spinUp = mode.spin
	if not spinUp or spin <= 0 then
		return mode.interval
	end
	return 1 / (mode.rate + (spinUp.maxRate.value - mode.rate) * spin)
end

-- How long the reload step that starts now takes, with `ammo` in the
-- magazine and `reserve` left: one round for a gun that loads a round at a
-- time, the one-round time when a single round goes in (the Outlaw), or the
-- whole reload.
function WeaponSim.reloadStep(def: WeaponConfig.WeaponDef, ammo: number, reserve: number): number
	local perRound = def.reloadPerRound
	if perRound then
		return perRound.value
	end
	local oneRound = def.reloadOneRound
	if oneRound and math.min(def.magazine.value - ammo, reserve) == 1 then
		return oneRound.value
	end
	return def.reloadTime.value
end

-- Rounds a reload step puts in at its end.
local function reloadAmount(def: WeaponConfig.WeaponDef, ammo: number, reserve: number): number
	local take = math.min(def.magazine.value - ammo, reserve)
	return if def.reloadPerRound then math.min(take, 1) else take
end

local function startReload(s: State, def: WeaponConfig.WeaponDef, t: number)
	local slot = s.equipped
	s.reloadEndTime = t + WeaponSim.reloadStep(def, s.ammo[slot], s.reserve[slot])
	s.scoped = 0
	s.burstLeft = 0
end

local function canReload(s: State, def: WeaponConfig.WeaponDef): boolean
	local slot = s.equipped
	return def.fireMode ~= "none" and s.reloadEndTime == 0 and s.ammo[slot] < def.magazine.value and s.reserve[slot] > 0
end

-- Whether the trigger (or right click) in `held` fires `mode` this tick:
-- automatic modes while held, semi-automatic ones on a fresh press.
local function pulled(mode: WeaponConfig.Mode, held: boolean, wasHeld: boolean): boolean
	return held and (mode.fireMode == "auto" or (mode.fireMode == "semi" and not wasHeld))
end

-- Fires one round in `mode`: its bullets, its ammo and its place in the
-- spray. `factor` is how much of the spray is left (Accuracy.recoveryFactor).
local function fireRound(s: State, def: WeaponConfig.WeaponDef, mode: WeaponConfig.Mode, factor: number, t: number, origin: vector, tick: number, input: any, ctx: Accuracy.Context?): { Shot }
	local slot = s.equipped
	-- A mode that takes a round per bullet (the Classic's right click) fires
	-- a bullet for each round left when there are fewer than it takes.
	local rounds = math.min(mode.ammo, s.ammo[slot])
	local bullets = if mode.ammo > 1 then math.max(mode.pellets * rounds // mode.ammo, 1) else mode.pellets
	s.ammo[slot] -= rounds

	local spray = s.sprayIndex * factor
	local sway = s.recoilYaw * factor
	if factor == 0 then
		s.swayDir = 0 -- a fresh spray drifts whichever way it likes
	end
	s.lastShotTime = t

	local context = ctx or STILL
	local bullet = spray + 1
	local cone = Accuracy.cone(mode.accuracy, context, bullet)
	local recoilPitch, recoilYaw = Accuracy.recoil(mode.recoil, context, bullet, sway, mode.zoomed)
	local aim = Accuracy.aim(input.yaw, input.pitch)
	local volley = s.shotCounter + 1
	local shots: { Shot } = table.create(bullets)
	for pellet = 1, bullets do
		s.shotCounter += 1
		local offset, angle = Accuracy.offset(s.seed, s.shotCounter, cone.radius, cone.power)
		shots[pellet] = {
			tick = tick,
			time = t,
			slot = slot,
			weapon = def.id,
			mode = mode.name,
			shotNumber = s.shotCounter,
			volley = volley,
			pellet = pellet,
			pellets = bullets,
			sprayIndex = spray,
			bullet = bullet,
			origin = origin,
			yaw = input.yaw,
			pitch = input.pitch,
			aim = aim,
			direction = Accuracy.direction(input.yaw, input.pitch, recoilPitch, recoilYaw, offset, angle),
			recoilPitch = recoilPitch,
			recoilYaw = recoilYaw,
			cone = cone,
			offset = offset,
			offsetAngle = angle,
			moveState = context.moveState,
			scoped = s.scoped,
		}
	end
	s.sprayIndex = bullet
	s.recoilYaw, s.swayDir = Accuracy.advanceSway(mode.recoil, bullet, sway, s.swayDir, s.seed, volley)
	return shots
end

-- A knife's swing this tick, if one starts. The left button slashes and the
-- right one stabs, again and again while held (the reference's melee is
-- automatic), each once the knife is drawn and the last swing's recovery is
-- over, the left first when both are down. Slashes one after another go
-- round the three-swing combo; one that comes more than comboReset after it
-- could have starts it over.
local function swing(s: State, def: WeaponConfig.WeaponDef, melee: WeaponConfig.MeleeDef, fire: boolean, alt: boolean, t: number, dt: number, origin: vector, tick: number, input: any): Swing?
	if not (fire or alt) or t < s.equipEndTime - EPS or t < s.nextFireTime - EPS then
		return nil
	end
	local kind: SwingKind = if fire then "slash" else "stab"
	local attack = if fire then melee.slash else melee.stab
	-- Held through the recovery keeps the exact cadence, as a trigger does.
	local late = t - s.nextFireTime
	local nominal = if late < dt - EPS then s.nextFireTime else t
	if kind == "slash" then
		s.combo = if s.combo == 0 or late > melee.comboReset.value + EPS then 1 else s.combo % 3 + 1
	else
		s.combo = 0
	end
	s.lastShotTime = t
	s.nextFireTime = nominal + 1 / attack.rate.value
	return {
		tick = tick,
		time = t,
		weapon = def.id,
		kind = kind,
		combo = s.combo,
		origin = origin,
		yaw = input.yaw,
		pitch = input.pitch,
		direction = Accuracy.aim(input.yaw, input.pitch),
	}
end

-- Advance one tick. `t` is the simulation time of this tick, `origin` the eye
-- position after this tick's movement and `ctx` what the shooter is doing
-- (for the cone and recoil). Returns the bullets fired this tick, if any
-- (one round's, at most), and the knife swing that started, if one did.
function WeaponSim.step(s: State, input: any, t: number, dt: number, origin: vector, tick: number, ctx: Accuracy.Context?): ({ Shot }?, Swing?)
	local buttons: number = input.buttons
	local fire = has(buttons, Buttons.Fire)
	local alt = has(buttons, Buttons.AltFire)
	local reload = has(buttons, Buttons.Reload)

	-- 1. Weapon switch: requested slot differs and holds a weapon.
	local want: number = input.slot
	if want ~= s.equipped and want >= 1 and want <= SLOTS and s.loadout[want] ~= "" then
		s.equipped = want
		draw(s, t)
	end

	local slot = s.equipped
	local def = WeaponConfig.get(s.loadout[slot])

	-- The spike in hand does nothing here: its plant is SpikeSim's.
	if def.spike then
		s.fireHeld = fire
		s.altHeld = alt
		return nil, nil
	end

	-- A knife swings, and has nothing to reload, zoom or fire.
	local melee = def.melee
	if melee then
		local swung = swing(s, def, melee, fire, alt, t, dt, origin, tick, input)
		s.fireHeld = fire
		s.altHeld = alt
		return nil, swung
	end

	-- 2. A reload step completes: the whole magazine at the end, or one
	-- round, then the next, until it's full or the reserve runs out.
	if s.reloadEndTime > 0 and t >= s.reloadEndTime - EPS then
		local take = reloadAmount(def, s.ammo[slot], s.reserve[slot])
		s.ammo[slot] += take
		s.reserve[slot] -= take
		local perRound = def.reloadPerRound
		if perRound and s.ammo[slot] < def.magazine.value and s.reserve[slot] > 0 then
			s.reloadEndTime += perRound.value
		else
			s.reloadEndTime = 0
		end
	end

	local equipping = t < s.equipEndTime - EPS

	-- 3. Alt-fire cycles zoom levels (rifle ADS, Operator 2.5x -> 5x -> off).
	-- A burst under way stops.
	if alt and not s.altHeld and def.ads and not equipping and s.reloadEndTime == 0 then
		s.scoped = (s.scoped + 1) % (#def.ads.zoom + 1)
		s.burstLeft = 0
	end

	-- 4. Manual reload.
	if reload and not equipping and canReload(s, def) then
		startReload(s, def, t)
	end

	local mode = WeaponConfig.mode(def, s.scoped)
	local altMode = WeaponConfig.altMode(def)
	local primary = pulled(mode, fire, s.fireHeld)
	local secondary = altMode ~= nil and pulled(altMode, alt, s.altHeld)

	-- 5. A reload that loads a round at a time stops when the trigger is
	-- pulled with a round in the magazine, keeping the rounds already in.
	if s.reloadEndTime > 0 and def.reloadPerRound and (primary or secondary) and s.ammo[slot] > 0 then
		s.reloadEndTime = 0
	end

	-- 6. Fire. A burst under way fires its next round on time by itself;
	-- otherwise the trigger fires a round, the left button before the right.
	local shots: { Shot }? = nil
	local ready = not equipping and s.reloadEndTime == 0
	if s.burstLeft > 0 then
		if t >= s.burstNext - EPS then
			if ready and s.ammo[slot] > 0 then
				shots = fireRound(s, def, mode, 1, t, origin, tick, input, ctx)
				s.burstLeft -= 1
				s.burstNext += mode.interval
			else
				s.burstLeft = 0
			end
		end
	else
		local fired = if primary then mode elseif secondary then altMode else nil
		if fired and ready and s.ammo[slot] > 0 and t >= s.nextFireTime - EPS then
			-- How much of the spray recovered since the gun could fire again
			-- decides which bullet of the spray this is.
			local factor = Accuracy.recoveryFactor(fired.accuracy, t - s.nextFireTime, dt)
			-- Holding the trigger through the cooldown keeps the exact cadence
			-- (shots land on ticks, the remainder carries over); otherwise the
			-- cooldown restarts from now.
			local nominal = if t - s.nextFireTime < dt - EPS then s.nextFireTime else t
			shots = fireRound(s, def, fired, factor, t, origin, tick, input, ctx)
			if fired.burstRounds > 1 then
				s.burstLeft = fired.burstRounds - 1
				s.burstNext = nominal + fired.interval
				s.nextFireTime = nominal + fired.burstInterval
			else
				s.nextFireTime = nominal + WeaponSim.spinInterval(fired, s.spin)
			end
		end
	end

	-- 7. A spinning fire rate rises while the trigger is held on a gun that
	-- can fire, and falls back at once when it can't or isn't.
	local spinUp = mode.spin
	if spinUp and fire and ready and s.ammo[slot] > 0 then
		s.spin = math.min(s.spin + dt / spinUp.time.value, 1)
	else
		s.spin = 0
	end

	-- 8. Auto-reload once the magazine is empty and the last shot's cooldown is over.
	if s.ammo[slot] == 0 and not equipping and s.burstLeft == 0 and t >= s.nextFireTime - EPS and canReload(s, def) then
		startReload(s, def, t)
	end

	s.fireHeld = fire
	s.altHeld = alt
	return shots, nil
end

return WeaponSim
