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
-- Times are seconds of simulation time (tick * dt). 1/128 is exact in binary,
-- so client and server compute bit-identical times.

-- Shared simulation modules use require-by-string, which resolves the same way
-- in Roblox ("./" = siblings) and in the offline Luau tests (same directory).
local WeaponConfig = require("./WeaponConfig")
local Accuracy = require("./Accuracy")

export type State = {
	loadout: { string }, -- [slot] = weapon id, "" for empty
	ammo: { number }, -- [slot]
	reserve: { number }, -- [slot]
	equipped: number,
	equipEndTime: number, -- can't fire before this
	nextFireTime: number,
	reloadEndTime: number, -- 0 when not reloading
	scoped: number, -- 0 = hip, n = ads.zoom[n]
	fireHeld: boolean,
	altHeld: boolean,
	lastShotTime: number,
	sprayIndex: number, -- shots in the current spray; fractional once partly recovered
	shotCounter: number, -- total shots this life; picks each shot's random numbers
	seed: number, -- per-life random seed, chosen by the server
	recoilYaw: number, -- sideways drift (degrees, + = right) the next bullet starts from
	swayDir: number, -- drift direction: -1, 1, or 0 before the drift starts
}

export type Shot = {
	tick: number,
	time: number,
	slot: number,
	weapon: string,
	shotNumber: number,
	sprayIndex: number, -- bullets before this one in the spray, after recovery
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

local Buttons = {
	Fire = 128,
	AltFire = 256,
	Reload = 512,
}

local EPS = 1e-9

local STILL: Accuracy.Context = { moveState = "still", crouched = false, landing = false }

local WeaponSim = {}

local function has(buttons: number, flag: number): boolean
	return bit32.band(buttons, flag) ~= 0
end

function WeaponSim.newState(loadout: { string }?, seed: number?): State
	local ids = loadout or WeaponConfig.DefaultLoadout
	local s: State = {
		loadout = { ids[1] or "", ids[2] or "", ids[3] or "" },
		ammo = { 0, 0, 0 },
		reserve = { 0, 0, 0 },
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
	}
	for slot = 1, 3 do
		WeaponSim.give(s, slot, s.loadout[slot])
	end
	-- Equip the first non-empty slot.
	for slot = 1, 3 do
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
end

-- Puts a weapon in a slot with full ammo (server-side loadout changes). When
-- the slot is the one in hand, pass the simulation time `t` so the new weapon
-- has to be drawn like any other switch.
function WeaponSim.give(s: State, slot: number, id: string, t: number?)
	s.loadout[slot] = id
	if id == "" then
		s.ammo[slot], s.reserve[slot] = 0, 0
		return
	end
	local def = WeaponConfig.get(id)
	s.ammo[slot] = def.magazine.value
	s.reserve[slot] = def.reserve.value
	if t and slot == s.equipped then
		draw(s, t)
	end
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

function WeaponSim.fireInterval(def: WeaponConfig.WeaponDef, scoped: number): number
	local rate = def.fireRate.value
	if scoped > 0 and def.ads then
		rate *= def.ads.fireRateMultiplier.value
	end
	return if rate > 0 then 1 / rate else math.huge
end

local function startReload(s: State, def: WeaponConfig.WeaponDef, t: number)
	s.reloadEndTime = t + def.reloadTime.value
	s.scoped = 0
end

local function canReload(s: State, def: WeaponConfig.WeaponDef): boolean
	local slot = s.equipped
	return def.fireMode ~= "none" and s.reloadEndTime == 0 and s.ammo[slot] < def.magazine.value and s.reserve[slot] > 0
end

-- Advance one tick. `t` is the simulation time of this tick, `origin` the eye
-- position after this tick's movement and `ctx` what the shooter is doing
-- (for the cone and recoil). Returns the shot fired this tick, if any.
function WeaponSim.step(s: State, input: any, t: number, dt: number, origin: vector, tick: number, ctx: Accuracy.Context?): Shot?
	local buttons: number = input.buttons
	local fire = has(buttons, Buttons.Fire)
	local alt = has(buttons, Buttons.AltFire)
	local reload = has(buttons, Buttons.Reload)

	-- 1. Weapon switch: requested slot differs and holds a weapon.
	local want: number = input.slot
	if want ~= s.equipped and want >= 1 and want <= 3 and s.loadout[want] ~= "" then
		s.equipped = want
		draw(s, t)
	end

	local slot = s.equipped
	local def = WeaponConfig.get(s.loadout[slot])

	-- 2. Reload completes: the whole magazine is refilled at the end.
	if s.reloadEndTime > 0 and t >= s.reloadEndTime - EPS then
		local take = math.min(def.magazine.value - s.ammo[slot], s.reserve[slot])
		s.ammo[slot] += take
		s.reserve[slot] -= take
		s.reloadEndTime = 0
	end

	local equipping = t < s.equipEndTime - EPS

	-- 3. Alt-fire cycles zoom levels (rifle ADS, Operator 2.5x -> 5x -> off).
	if alt and not s.altHeld and def.ads and not equipping and s.reloadEndTime == 0 then
		s.scoped = (s.scoped + 1) % (#def.ads.zoom + 1)
	end

	-- 4. Manual reload.
	if reload and not equipping and canReload(s, def) then
		startReload(s, def, t)
	end

	-- 5. Fire. Auto weapons fire while held; semi-auto needs a fresh press.
	local shot: Shot? = nil
	local trigger = fire and (def.fireMode == "auto" or (def.fireMode == "semi" and not s.fireHeld))
	if trigger and not equipping and s.reloadEndTime == 0 and s.ammo[slot] > 0 and t >= s.nextFireTime - EPS then
		local interval = WeaponSim.fireInterval(def, s.scoped)
		-- How much of the spray recovered since the last shot decides which
		-- bullet of the spray this is.
		local factor = Accuracy.recoveryFactor(def.accuracy, interval, t - s.lastShotTime, dt)
		local spray = s.sprayIndex * factor
		local sway = s.recoilYaw * factor
		if factor == 0 then
			s.swayDir = 0 -- a fresh spray drifts whichever way it likes
		end
		-- Holding the trigger through the cooldown keeps the exact cadence
		-- (shots land on ticks, the remainder carries over); otherwise the
		-- cooldown restarts from now.
		if t - s.nextFireTime < dt - EPS then
			s.nextFireTime += interval
		else
			s.nextFireTime = t + interval
		end
		s.ammo[slot] -= 1
		s.shotCounter += 1
		s.lastShotTime = t

		local context = ctx or STILL
		local scoped = s.scoped > 0 and def.ads ~= nil
		local bullet = spray + 1
		local cone = Accuracy.cone(def, context, bullet, scoped)
		local recoilPitch, recoilYaw = Accuracy.recoil(def, context, bullet, sway, scoped)
		local offset, angle = Accuracy.offset(s.seed, s.shotCounter, cone.radius, cone.power)
		shot = {
			tick = tick,
			time = t,
			slot = slot,
			weapon = def.id,
			shotNumber = s.shotCounter,
			sprayIndex = spray,
			bullet = bullet,
			origin = origin,
			yaw = input.yaw,
			pitch = input.pitch,
			aim = Accuracy.aim(input.yaw, input.pitch),
			direction = Accuracy.direction(input.yaw, input.pitch, recoilPitch, recoilYaw, offset, angle),
			recoilPitch = recoilPitch,
			recoilYaw = recoilYaw,
			cone = cone,
			offset = offset,
			offsetAngle = angle,
			moveState = context.moveState,
			scoped = s.scoped,
		}
		s.sprayIndex = bullet
		s.recoilYaw, s.swayDir = Accuracy.advanceSway(def.recoil, bullet, sway, s.swayDir, s.seed, s.shotCounter)
	end

	-- 6. Auto-reload once the magazine is empty and the last shot's cooldown is over.
	if s.ammo[slot] == 0 and not equipping and t >= s.nextFireTime - EPS and canReload(s, def) then
		startReload(s, def, t)
	end

	s.fireHeld = fire
	s.altHeld = alt
	return shot
end

return WeaponSim
