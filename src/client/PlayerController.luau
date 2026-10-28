--!strict
-- Client-side prediction and reconciliation for the local player's PlayerSim
-- (movement + weapons, and the spike's plant and defuse).
--
-- Every fixed 128 Hz tick we sample input, step PlayerSim immediately (so
-- movement and shots respond on the frame you press), remember the input and
-- the predicted result, and send the input to the server. When an ack arrives
-- we compare our prediction for that seq with the server's state; on mismatch
-- we rewind to the server state and replay the inputs it hasn't processed
-- yet. Shots and knife swings re-simulated during a replay are not re-fired:
-- effects only play for the live tick. Visual position error from a correction is blended out
-- over a few frames instead of snapping the camera.
--
-- The spike rides in slot 4: its key draws it while it's carried, and held
-- plants or defuses it (InputSampler's Use). What the player may do with it
-- each tick is the `objective` hook's (ClientSpike), the server's state of
-- it as last heard.
--
-- The ability kit (system 17) is predicted with the rest: a cast moves you
-- the tick you press it, and the server's changes to the kit between ticks
-- (charges bought, points for kills) come back in the ack like a loadout.
-- Blade Storm's knives ride in slot 5 (system 19): their cast and X draw
-- them, and a kill that brings them all back comes in the ack too. Run it
-- Back's return (system 33) puts the view at its mark at once, turned the
-- way it was cast, and while it's under way a correction isn't blended. A
-- Slow Orb's field (system 37) slows you here as it does on the server, and
-- a Barrier Orb's wall (system 38) stands in your way and lifts you as it
-- does there: both judge them, as the server told of them (SlowView,
-- BarrierView), at the time each input's frame showed. From the Shadows
-- (system 43) takes the place its map's cursor is on (mapPoint) with each
-- input that fires, puts the view where the Shade is at once, and where
-- he's sent back, and while it's under way, or as the server sends him back
-- (an enemy's hit on the Shade), a correction isn't blended either. Sova's
-- Owl Drone (system 47) flies in the simulation too, so it answers the keys
-- at once: while it flies, the view's from its middle, moving as it does
-- between ticks, and the body stands facing the way it did as he sent it;
-- as its flight's over, the view's back in the body, turned that way again,
-- and so it is as the server ends it (an enemy's shots taking the last of
-- its health). A life in a bot's body taken over (system 62) starts where the
-- server says on the bot's kit as it was (CharacterRig.SPAWN_KIT), looking
-- the way it did, so the first shots are the right gun's.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local MovementSim = require(Shared.Movement.MovementSim)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Accuracy = require(Shared.Weapons.Accuracy)
local Spike = require(Shared.Spike.Spike)
local SpikeSim = require(Shared.Spike.SpikeSim)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local SlowSim = require(Shared.Abilities.SlowSim)
local BarrierSim = require(Shared.Abilities.BarrierSim)
local BotTakeover = require(Shared.Bots.BotTakeover)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local InputQueue = require(Shared.Net.InputQueue)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)

local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)
local RemoteEntities = require(script.Parent.RemoteEntities)
local NetSim = require(script.Parent.NetSim)

local TICK_RATE = MovementConfig.TickRate.value
local DT = 1 / TICK_RATE
local POSITION_TOLERANCE = 0.002 -- metres before we accept a server correction
local VELOCITY_TOLERANCE = 0.01 -- m/s
local CORRECTION_BLEND_TIME = 0.1 -- seconds to blend visual error out
-- The most one frame simulates: as many ticks as the server runs at once
-- (its bank, 125 ms), so a long frame never sends more inputs than the
-- server keeps. A longer frame loses the rest, as Unreal's servers cut a
-- move to 0.125 s by default. At 0.25 s, two hitches in Studio sent more
-- than the server's queue holds, and the client was pulled back exactly 3
-- and 5 ticks of running.
local MAX_FRAME_TIME = InputQueue.MAX_BURST * DT
local KICK_RATE = 30 -- 1/s: how fast the view catches up with the recoil (estimate)
local SPRAY_TOLERANCE = 1e-6 -- spray position and drift (see mismatch)

export type TickInfo = {
	time: number,
	input: PlayerCodec.WireInput,
	sim: PlayerSim.State,
	state: MovementSim.State, -- sim.movement, kept for the movement debug tools
	wishDir: vector,
	maxSpeed: number, -- run speed of the equipped weapon
	accurateFraction: number, -- deadzone fraction of that speed
	shots: { WeaponSim.Shot }?, -- the bullets fired this tick: one round's
	swing: WeaponSim.Swing?, -- the knife swing that started this tick
	act: SpikeSim.Act?, -- what happened with the spike this tick
	casts: { AbilitySim.Cast }?, -- the abilities cast this tick
}

export type Profile = {
	id: string,
	name: string,
	maxSpeed: number,
	accurateFraction: number,
}

local PlayerController = {}

PlayerController.cfg = MovementConfig.resolve()
PlayerController.overrides = {} :: { [string]: number }
PlayerController.sim = nil :: PlayerSim.State?
PlayerController.serverSim = nil :: PlayerSim.State?
PlayerController.desiredSlot = 1
PlayerController.alive = false
PlayerController.entityId = PlayerCodec.entityIdForUser(Players.LocalPlayer.UserId)
PlayerController.stats = {
	pending = 0,
	corrections = 0,
	lastCorrectionError = 0,
	maxCorrectionError = 0,
	lastAckSeq = 0,
	sentInputs = 0,
	-- Input sent to its ack back: network round trip plus the server's queue
	-- and frame, like Riot's "Network RTT + Processing Delays" graph.
	rtt = 0,
	rttSmooth = 0,
}
-- Called once per live simulated tick (debug tools hook in here).
PlayerController.tickListeners = {} :: { (TickInfo) -> () }
-- Called for each bullet the local player fires (each pellet of a shotgun
-- round), with the input that fired it (live ticks only; replays after a
-- correction don't re-fire).
PlayerController.shotListeners = {} :: { (WeaponSim.Shot, PlayerCodec.WireInput) -> () }
-- Called for each knife swing the local player starts, with its input (live
-- ticks only, like shots).
PlayerController.swingListeners = {} :: { (WeaponSim.Swing, PlayerCodec.WireInput) -> () }
-- Called with what happened with the spike in the local player's
-- simulation (live ticks only, like shots).
PlayerController.spikeListeners = {} :: { (SpikeSim.Act, PlayerCodec.WireInput) -> () }
-- Called with each ability the local player casts (live ticks only, like
-- shots).
PlayerController.castListeners = {} :: { (AbilitySim.Cast, PlayerCodec.WireInput) -> () }
-- What the local player may do with the spike now (ClientSpike); nothing
-- without.
PlayerController.objective = nil :: (() -> Spike.Context)?
-- The Slow Orbs' fields in play (system 37, SlowView); none without.
PlayerController.fields = nil :: (() -> { SlowSim.Field })?
-- The Barrier Orbs' walls in play, judged at a server time, and whether a
-- wall can go up then (system 38, BarrierView); none without.
PlayerController.barriers = nil :: ((number) -> BarrierSim.Walls)?
-- The place on the map From the Shadows' cursor is on (system 43,
-- ShadowView), metres, while its map's up: sent with each input that fires.
-- Nil without.
PlayerController.mapPoint = nil :: (() -> vector?)?
-- Called when the local player (re)spawns with a fresh simulation.
PlayerController.spawnListeners = {} :: { (PlayerSim.State) -> () }
-- Increments on every spawn; shot numbers restart each life.
PlayerController.life = 0
-- Buttons of the latest simulated tick (the debug tools read the accuracy
-- state with them).
PlayerController.buttons = 0

local localPlayer = Players.LocalPlayer
local world = RobloxWorld.new()
local remotes = Remotes.get()

local sim: PlayerSim.State? = nil
local prevPosition: vector = vector.create(0, 0, 0)
local prevCrouch = 0
local prevDrone: vector = vector.create(0, 0, 0) -- the Owl Drone's middle before the last tick (system 47)
local seq = 0
local pending: { PlayerCodec.WireInput } = {}
local unsent: { PlayerCodec.WireInput } = {}
local predicted: { [number]: PlayerSim.State } = {}
local sentAt: { [number]: number } = {}
local accumulator = 0
local simTime = 0
local visualOffset = vector.create(0, 0, 0)
local root: BasePart? = nil
local rootOffset = 3

function PlayerController.profile(): Profile
	local s = sim
	if not s then
		local def = WeaponConfig.get(WeaponConfig.DefaultLoadout[1])
		return { id = def.id, name = def.name, maxSpeed = 5.4, accurateFraction = 0.3 }
	end
	local def = PlayerSim.def(s)
	return {
		id = def.id,
		name = def.name,
		maxSpeed = PlayerSim.weaponSpeed(s, PlayerController.cfg),
		accurateFraction = PlayerSim.deadzoneFraction(s, PlayerController.cfg),
	}
end

local function objective(): Spike.Context?
	local hook = PlayerController.objective
	return if hook then hook() else nil
end

-- The Slow Orbs' fields, judged at the time `input`'s frame showed.
local function slows(input: PlayerCodec.WireInput): SlowSim.Slows?
	local hook = PlayerController.fields
	return if hook then { fields = hook(), time = input.viewTime } else nil
end

-- The Barrier Orbs' walls, judged at the time `input`'s frame showed.
local function barriers(input: PlayerCodec.WireInput): BarrierSim.Walls?
	local hook = PlayerController.barriers
	return if hook then hook(input.viewTime) else nil
end

local function tick()
	local s = sim :: PlayerSim.State
	seq += 1
	-- A slot emptied (the spike planted or dropped) stops being asked for,
	-- but for the ultimate's: a kill may have brought Blade Storm's knives
	-- back on the server before this client put them away (system 19).
	local w = s.weapons
	if PlayerController.desiredSlot ~= WeaponSim.ULT and w.loadout[PlayerController.desiredSlot] == "" then
		PlayerController.desiredSlot = w.equipped
	end
	-- The knives came into hand by themselves (their cast, or X again): from
	-- now on they're asked for, so they stay.
	if w.equipped == WeaponSim.ULT and w.hold ~= 0 and PlayerController.desiredSlot == w.hold then
		PlayerController.desiredSlot = WeaponSim.ULT
	end
	local input: PlayerCodec.WireInput = {
		seq = seq,
		buttons = InputSampler.sample(),
		slot = PlayerController.desiredSlot,
		-- Quantise exactly as the wire does so both sides simulate the same input.
		yaw = PlayerCodec.quantizeYaw(CameraController.yaw),
		pitch = PlayerCodec.quantizePitch(CameraController.pitch),
		-- What the player was looking at: the frame on screen.
		viewTime = RemoteEntities.shownTime(),
	}
	local mapPoint = PlayerController.mapPoint
	local point = if mapPoint and bit32.band(input.buttons, PlayerSim.Buttons.Fire) ~= 0 then mapPoint() else nil
	if point then
		input.point = PlayerCodec.quantizePoint(point)
	end
	prevPosition = s.movement.position
	prevCrouch = s.movement.crouchAlpha
	prevDrone = s.abilities.dronePos
	local shots, swing, act, _, casts =
		PlayerSim.step(s, input, PlayerController.cfg, world, DT, objective(), slows(input), barriers(input))
	simTime += DT
	PlayerController.buttons = input.buttons
	-- Back at Run it Back's mark (system 33): the view's there at once,
	-- turned the way he faced as he cast it. Gone by Shrouded Step (system
	-- 42), it's where he's going at once, turned as it was, and so it is
	-- as a Shade, and sent back, in From the Shadows (system 43). The Owl
	-- Drone sent out, it's from the drone's middle at once, and as its
	-- flight's over, back in the body, turned the way he faced as he sent
	-- it (system 47).
	if casts then
		for _, cast in casts do
			if cast.kind == "rise" then
				prevPosition = s.movement.position
				visualOffset = vector.create(0, 0, 0)
				CameraController.yaw = s.abilities.markYaw
				CameraController.pitch = 0
			elseif cast.kind == "vanish" or cast.kind == "shade" or cast.kind == "home" then
				prevPosition = s.movement.position
				visualOffset = vector.create(0, 0, 0)
			elseif cast.kind == "drone" then
				prevDrone = s.abilities.dronePos
			elseif cast.kind == "land" then
				CameraController.yaw = s.abilities.bodyYaw
				CameraController.pitch = s.abilities.bodyPitch
			end
		end
	end

	table.insert(pending, input)
	table.insert(unsent, input)
	predicted[seq] = PlayerSim.copy(s)

	if shots then
		for _, shot in shots do
			for _, listener in PlayerController.shotListeners do
				listener(shot, input)
			end
		end
	end
	if swing then
		for _, listener in PlayerController.swingListeners do
			listener(swing, input)
		end
	end
	if act then
		for _, listener in PlayerController.spikeListeners do
			listener(act, input)
		end
	end
	if casts then
		for _, cast in casts do
			for _, listener in PlayerController.castListeners do
				listener(cast, input)
			end
		end
	end

	local profile = PlayerController.profile()
	local info: TickInfo = {
		time = simTime,
		input = input,
		sim = s,
		state = s.movement,
		wishDir = MovementSim.wishDirection(input.buttons, input.yaw),
		maxSpeed = profile.maxSpeed,
		accurateFraction = profile.accurateFraction,
		shots = shots,
		swing = swing,
		act = act,
		casts = casts,
	}
	for _, listener in PlayerController.tickListeners do
		listener(info)
	end
end

local function flushInputs()
	if #unsent == 0 then
		return
	end
	local chunk = PlayerCodec.MAX_INPUTS_PER_PACKET
	for first = 1, #unsent, chunk do
		local last = math.min(first + chunk - 1, #unsent)
		NetSim.fireServer(remotes.PlayerInput, PlayerCodec.encodeInputs(unsent, first, last))
	end
	local now = os.clock()
	for _, input in unsent do
		sentAt[input.seq] = now
	end
	PlayerController.stats.sentInputs += #unsent
	table.clear(unsent)
end

local function mismatch(guess: PlayerSim.State, server: PlayerSim.State): (boolean, number)
	local gm, sm = guess.movement, server.movement
	local posErr = vector.magnitude(gm.position - sm.position)
	local velErr = vector.magnitude(gm.velocity - sm.velocity)
	if posErr > POSITION_TOLERANCE or velErr > VELOCITY_TOLERANCE then
		return true, posErr
	end
	if gm.grounded ~= sm.grounded or gm.crouched ~= sm.crouched then
		return true, posErr
	end
	-- Weapon state is exact on both sides (same ticks, same float maths), so
	-- any difference at all means the server saw something we didn't. The
	-- spray position and drift go through `^` and could in principle round
	-- differently on another machine's maths library, so they get a tolerance.
	local gw, sw = guess.weapons, server.weapons
	for slot = 1, WeaponSim.SLOTS do
		if gw.loadout[slot] ~= sw.loadout[slot] or gw.ammo[slot] ~= sw.ammo[slot] or gw.reserve[slot] ~= sw.reserve[slot] then
			return true, posErr
		end
	end
	if
		gw.equipped ~= sw.equipped
		or gw.equipEndTime ~= sw.equipEndTime
		or gw.nextFireTime ~= sw.nextFireTime
		or gw.reloadEndTime ~= sw.reloadEndTime
		or gw.scoped ~= sw.scoped
		or gw.fireHeld ~= sw.fireHeld
		or gw.altHeld ~= sw.altHeld
		or gw.lastShotTime ~= sw.lastShotTime
		or math.abs(gw.sprayIndex - sw.sprayIndex) > SPRAY_TOLERANCE
		or math.abs(gw.recoilYaw - sw.recoilYaw) > SPRAY_TOLERANCE
		or gw.swayDir ~= sw.swayDir
		or gw.shotCounter ~= sw.shotCounter
		or gw.seed ~= sw.seed
		or gw.burstLeft ~= sw.burstLeft
		or gw.burstNext ~= sw.burstNext
		or gw.spin ~= sw.spin
		or gw.combo ~= sw.combo
		or gw.back ~= sw.back
		or gw.hold ~= sw.hold
	then
		return true, posErr
	end
	if guess.tagUntilTick ~= server.tagUntilTick or guess.tagMultiplier ~= server.tagMultiplier then
		return true, posErr
	end
	local gs, ss = guess.spike, server.spike
	if
		gs.channel ~= ss.channel
		or gs.channelStart ~= ss.channelStart
		or gs.channelEnd ~= ss.channelEnd
		or gs.halfStart ~= ss.halfStart
		or gs.lastSlot ~= ss.lastSlot
		or gs.dropHeld ~= ss.dropHeld
		or gs.holdOver ~= ss.holdOver
		or gs.orb ~= ss.orb
	then
		return true, posErr
	end
	local ga, sa = guess.abilities, server.abilities
	for slot = 1, #sa.charges do
		if ga.charges[slot] ~= sa.charges[slot] then
			return true, posErr
		end
	end
	if
		ga.agent ~= sa.agent
		or ga.regained ~= sa.regained
		or ga.kills ~= sa.kills
		or ga.points ~= sa.points
		or ga.need ~= sa.need
		or ga.held ~= sa.held
		or ga.readyFrom ~= sa.readyFrom
		or ga.readyUntil ~= sa.readyUntil
		or ga.liftUntil ~= sa.liftUntil
		or ga.dashUntil ~= sa.dashUntil
		or ga.dashX ~= sa.dashX
		or ga.dashZ ~= sa.dashZ
		or ga.storm ~= sa.storm
		or ga.holding ~= sa.holding
		or ga.steering ~= sa.steering
		or ga.steerUntil ~= sa.steerUntil
		or ga.backUntil ~= sa.backUntil
		or ga.returnAt ~= sa.returnAt
		or ga.mark ~= sa.mark
		or ga.markYaw ~= sa.markYaw
		or ga.markGrounded ~= sa.markGrounded
		or ga.markCrouched ~= sa.markCrouched
		or ga.shadowAt ~= sa.shadowAt
		or ga.shadowFrom ~= sa.shadowFrom
		or ga.shadowTo ~= sa.shadowTo
		or ga.drawFrom ~= sa.drawFrom
		or ga.letDown ~= sa.letDown
		or ga.altDown ~= sa.altDown
		or ga.bounces ~= sa.bounces
		or ga.furyUntil ~= sa.furyUntil
		or ga.chargeAt ~= sa.chargeAt
		or ga.kickFrom ~= sa.kickFrom
		or ga.kickYaw ~= sa.kickYaw
		or ga.droneFrom ~= sa.droneFrom
		or ga.landAt ~= sa.landAt
		or ga.dronePos ~= sa.dronePos
		or ga.droneVel ~= sa.droneVel
		or ga.dartAt ~= sa.dartAt
		or ga.bodyYaw ~= sa.bodyYaw
		or ga.bodyPitch ~= sa.bodyPitch
	then
		return true, posErr
	end
	return false, posErr
end

-- A weapon asked for (the debug give, the buy menu) is drawn once the server
-- has put it in its slot, so a request it refuses doesn't act as a slot key.
local awaitedWeapon: { slot: number, id: string, expires: number }? = nil
local AWAIT_WEAPON_TIME = 2 -- seconds

local function onAck(payload: buffer)
	local s = sim
	if not s or typeof(payload) ~= "buffer" or not PlayerController.alive then
		return
	end
	local ackSeq, serverSim = PlayerCodec.decodeAck(payload)
	local stats = PlayerController.stats
	if ackSeq < stats.lastAckSeq then
		return -- out of order (unreliable channel), or from an earlier life
	end
	if ackSeq > seq then
		return -- from a life the server has started and our new character hasn't reached us yet
	end
	stats.lastAckSeq = ackSeq
	PlayerController.serverSim = serverSim
	local awaited = awaitedWeapon
	if awaited then
		if serverSim.weapons.loadout[awaited.slot] == awaited.id then
			PlayerController.desiredSlot = awaited.slot
			awaitedWeapon = nil
		elseif os.clock() > awaited.expires then
			awaitedWeapon = nil
		end
	end
	local sent = sentAt[ackSeq]
	if sent then
		stats.rtt = os.clock() - sent
		stats.rttSmooth = if stats.rttSmooth == 0 then stats.rtt else stats.rttSmooth + (stats.rtt - stats.rttSmooth) * 0.05
	end
	for k in sentAt do
		if k <= ackSeq then
			sentAt[k] = nil
		end
	end

	while #pending > 0 and pending[1].seq <= ackSeq do
		table.remove(pending, 1)
	end

	local guess = predicted[ackSeq]
	local needsCorrection = true
	if guess then
		local wrong, posErr = mismatch(guess, serverSim)
		needsCorrection = wrong
		if wrong then
			stats.lastCorrectionError = posErr
			stats.maxCorrectionError = math.max(stats.maxCorrectionError, posErr)
		end
	end
	for k in predicted do
		if k <= ackSeq then
			predicted[k] = nil
		end
	end

	if needsCorrection then
		stats.corrections += 1
		local before = s.movement.position
		local droneBefore = s.abilities.dronePos
		local flew = AbilitySim.droning(s.abilities)
		local corrected = serverSim :: PlayerSim.State
		local now = objective()
		for _, input in pending do
			PlayerSim.step(corrected, input, PlayerController.cfg, world, DT, now, slows(input), barriers(input))
			predicted[input.seq] = PlayerSim.copy(corrected)
		end
		visualOffset += before - corrected.movement.position
		prevPosition += corrected.movement.position - before
		prevDrone += corrected.abilities.dronePos - droneBefore
		-- The Owl Drone's flight ended by the server (system 47): the view's
		-- back in the body, turned the way he faced as he sent it.
		local kit = corrected.abilities
		if flew and not AbilitySim.droning(kit) and kit.landAt > 0 then
			CameraController.yaw = kit.bodyYaw
			CameraController.pitch = kit.bodyPitch
		end
		-- Held through Run it Back's return (system 33), gone by Shrouded
		-- Step (system 42), or in From the Shadows or just sent back from it
		-- (system 43), he's where the server has him at once, the blend
		-- left out.
		local last = corrected.movement.tick * DT
		if
			AbilitySim.returning(corrected.abilities, last)
			or AbilitySim.shrouded(corrected.abilities, last)
			or AbilitySim.shadowing(corrected.abilities, last)
			or AbilitySim.shadowing(s.abilities, s.movement.tick * DT)
		then
			visualOffset = vector.create(0, 0, 0)
			prevPosition = corrected.movement.position
		end
		sim = corrected
		PlayerController.sim = corrected
	end
	stats.pending = #pending
end

-- The view follows a share of the recoil (the weapon's camera fraction) of
-- the bullet that would fire next, so it climbs with a spray and settles as
-- the spray recovers. A sniper's bullets don't climb, so each of its shots
-- also kicks the view up by its view kick, settling over viewKickTime.
-- Eased so each shot reads as a kick, not a snap. Visual only: the aim sent
-- to the server never includes it.
local function updateKick(s: PlayerSim.State, frameDt: number)
	local def = PlayerSim.def(s)
	local w = s.weapons
	local t = (s.movement.tick + accumulator / DT) * DT
	local bullet, sway, mode = Accuracy.next(def, w, t, DT)
	local ctx = PlayerSim.accuracyContext(s, PlayerController.buttons, PlayerController.cfg, DT)
	local up, right = Accuracy.recoil(mode.recoil, ctx, bullet, sway, mode.zoomed)
	local fraction = Accuracy.cameraFraction(mode.recoil, mode.zoomed)
	local kick = 0
	local viewKick = mode.recoil.viewKick
	local settle = WeaponConfig.Accuracy.viewKickTime.value
	local since = t - w.lastShotTime
	if viewKick and since >= 0 and since < settle then
		local left = 1 - since / settle
		kick = viewKick.value * left * left
	end
	local k = 1 - math.exp(-frameDt * KICK_RATE)
	CameraController.kickPitch += (math.rad(up * fraction + kick) - CameraController.kickPitch) * k
	-- Positive camera yaw turns left; positive recoil yaw is to the right.
	CameraController.kickYaw += (-math.rad(right * fraction) - CameraController.kickYaw) * k
end

local function onRender(frameDt: number)
	CameraController.updateLook()
	local s = sim
	if not s then
		return
	end
	if PlayerController.alive then
		accumulator = math.min(accumulator + frameDt, MAX_FRAME_TIME)
		while accumulator >= DT do
			tick()
			accumulator -= DT
		end
		flushInputs()
	end

	s = sim :: PlayerSim.State
	local m = s.movement
	local alpha = accumulator / DT
	visualOffset *= math.exp(-frameDt / (CORRECTION_BLEND_TIME / 3))
	local feet = prevPosition + (m.position - prevPosition) * alpha + visualOffset
	local crouch = prevCrouch + (m.crouchAlpha - prevCrouch) * alpha
	local cfg = PlayerController.cfg
	local eye = cfg.standEyeHeight + (cfg.crouchEyeHeight - cfg.standEyeHeight) * crouch
	local feetStuds = Units.toStuds(feet)
	-- Flying the Owl Drone (system 47), the view's from its middle, and
	-- the body faces the way it did as he sent it.
	local kit = s.abilities
	local flying = PlayerController.alive and AbilitySim.droning(kit)

	if root and root.Parent then
		local facing = if flying then kit.bodyYaw else CameraController.yaw
		root.CFrame = CFrame.new(feetStuds + Vector3.new(0, rootOffset, 0)) * CFrame.Angles(0, facing, 0)
	end
	local def = PlayerSim.def(s)
	local zoom = if s.weapons.scoped > 0 and def.ads then def.ads.zoom[s.weapons.scoped] else 1
	updateKick(s, frameDt)
	if flying then
		CameraController.render(Units.toStuds(prevDrone + (kit.dronePos - prevDrone) * alpha), 1)
		return
	end
	CameraController.render(feetStuds + Vector3.new(0, eye * Units.STUDS_PER_METRE, 0), zoom)
end

-- Where the server's simulation starts this life, from the new character.
-- Reading our own copy of the character instead gave a different spawn (76 mm
-- out in the first Studio run), depending on when each side looked, and the
-- first ack then counted that as a misprediction.
-- Nil for a character taken away again before its life started (a bot
-- that was to be taken over fell first, system 62).
local function spawnFeet(character: Model, r: BasePart): vector?
	local value = character:GetAttribute(CharacterRig.SPAWN_FEET)
	local deadline = os.clock() + 2
	while typeof(value) ~= "Vector3" and os.clock() < deadline do
		task.wait()
		if character.Parent == nil then
			return nil
		end
		value = character:GetAttribute(CharacterRig.SPAWN_FEET)
	end
	if typeof(value) == "Vector3" then
		return Units.asVector(value)
	end
	warn("[VF] The server sent no spawn point, so the client starts from its own reading")
	return Units.toMetres(r.Position - Vector3.new(0, rootOffset, 0)) + vector.create(0, 0.05, 0)
end

local function onCharacter(character: Model)
	local r = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not r then
		return
	end
	root = r
	rootOffset = CharacterRig.rootOffset(character, r)
	local feet = spawnFeet(character, r)
	if not feet or localPlayer.Character ~= character then
		return -- a newer character arrived while we waited, or none's left
	end
	-- This life's inputs start where the server says, past anything sent for
	-- the last one, so acks from before it are old.
	local firstSeq = character:GetAttribute(CharacterRig.FIRST_SEQ)
	if typeof(firstSeq) == "number" then
		seq = firstSeq - 1
		PlayerController.stats.lastAckSeq = firstSeq - 1
	end
	local yaw = character:GetAttribute(CharacterRig.SPAWN_YAW)
	if typeof(yaw) == "number" then
		CameraController.yaw = yaw
		CameraController.pitch = 0
	end
	-- A bot's body taken over (system 62) looks on as it did.
	local pitch = character:GetAttribute(CharacterRig.SPAWN_PITCH)
	if typeof(pitch) == "number" then
		CameraController.pitch = pitch
	end
	-- The last life's weapons, as the server keeps them, but not the spike,
	-- and its ability kit, with nothing under way; in a bot's body, its kit
	-- as it is, the spike too if it carries it.
	local last = sim
	local kit = BotTakeover.readKit(character:GetAttribute(CharacterRig.SPAWN_KIT))
	local loadout = if kit then table.clone(kit.loadout) elseif last then table.clone(last.weapons.loadout) else nil
	if loadout and not kit then
		loadout[Spike.SLOT] = ""
	end
	local fresh = PlayerSim.new(feet, loadout)
	if kit then
		BotTakeover.arm(fresh.weapons, kit)
	end
	if last then
		fresh.abilities = AbilitySim.copy(last.abilities)
		AbilitySim.settle(fresh.abilities)
	end
	-- A life the Resurrection brought back starts held, rising with the body
	-- and then falling, as the server has it (system 39).
	local floatFor = character:GetAttribute(CharacterRig.REVIVED)
	if typeof(floatFor) == "number" then
		fresh.abilities.floatUntil = floatFor
		fresh.abilities.heldUntil = floatFor + AbilityConfig.Resurrection.fall.value
	end
	sim = fresh
	PlayerController.sim = sim
	PlayerController.desiredSlot = (sim :: PlayerSim.State).weapons.equipped
	PlayerController.alive = true
	PlayerController.life += 1
	prevPosition = feet
	visualOffset = vector.create(0, 0, 0)
	table.clear(pending)
	table.clear(predicted)
	table.clear(sentAt)
	for _, listener in PlayerController.spawnListeners do
		listener(sim :: PlayerSim.State)
	end
	-- Hide our own body in first person, and its shadow: the reference casts
	-- shadows only from first-person objects, your hands and weapon.
	local function hide(d: Instance)
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
			d.CastShadow = false
		elseif d:IsA("Decal") then
			d.LocalTransparencyModifier = 1
		end
	end
	-- And keep it hidden: Roblox's camera scripts set LocalTransparencyModifier
	-- on the character the camera follows too, and in Studio the first
	-- character after joining came back with all of it at 0 (a respawned one
	-- stayed hidden).
	local function keepHidden(d: Instance)
		if d:IsA("BasePart") or d:IsA("Decal") then
			hide(d)
			d:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
				hide(d)
			end)
		end
	end
	for _, d in character:GetDescendants() do
		keepHidden(d)
	end
	character.DescendantAdded:Connect(keepHidden)
end

-- Asks for the weapon in a slot to be drawn, as its number key does: one
-- that's empty (the spike's, unless it's carried) is not asked for.
function PlayerController.selectSlot(slot: number)
	local s = sim
	if s and slot == math.floor(slot) and slot >= 1 and slot <= WeaponSim.SLOTS and s.weapons.loadout[slot] ~= "" then
		PlayerController.desiredSlot = slot
	end
end

-- Asks the server to change a tuning parameter (Studio / place owner only).
function PlayerController.requestTuning(key: string, value: number?)
	remotes.Tuning:FireServer(key, value)
end

-- Draws the weapon `id` from `slot` once the server has put it there. A
-- slot that holds it already changes nothing, so nothing is drawn.
function PlayerController.drawWhenGiven(slot: number, id: string)
	local s = sim
	if s and s.weapons.loadout[slot] == id then
		awaitedWeapon = nil
		return
	end
	awaitedWeapon = { slot = slot, id = id, expires = os.clock() + AWAIT_WEAPON_TIME }
end

-- Debug weapon give (Studio / place owner only, and anyone in the arena's
-- buy phase); drawn once the server has given it, or at once if its slot
-- holds it already (the server refills it).
function PlayerController.requestWeapon(id: string)
	local def = WeaponConfig.Defs[id]
	if def then
		remotes.Loadout:FireServer(def.slot, id)
		local s = sim
		if s and s.weapons.loadout[def.slot] == id then
			awaitedWeapon = nil
			PlayerController.selectSlot(def.slot)
		else
			PlayerController.drawWhenGiven(def.slot, id)
		end
	end
end

-- Roblox's default controls would also drive the character, so they are
-- switched off. Their PlayerModule is in PlayerScripts with the legacy player
-- scripts, and in StarterPlayer with the ones built on the Input Action
-- System (Workspace.PlayerScriptsUseInputActionSystem: opt-in since July
-- 2026, every place's default from 2027), which may not have GetControls.
-- The anchored root and zero WalkSpeed already keep the defaults from moving
-- the character, so this is best effort and never holds up the start.
local function disableDefaultControls()
	local playerScripts = localPlayer:WaitForChild("PlayerScripts")
	local deadline = os.clock() + 10
	local found: Instance? = nil
	repeat
		found = playerScripts:FindFirstChild("PlayerModule") or StarterPlayer:FindFirstChild("PlayerModule")
		if found == nil then
			task.wait(0.1)
		end
	until found ~= nil or os.clock() > deadline
	if found == nil or not found:IsA("ModuleScript") then
		return
	end
	local playerModule = found :: ModuleScript
	local ok, problem = pcall(function()
		local controls = (require(playerModule) :: any):GetControls()
		controls:Disable()
	end)
	if not ok then
		warn("[VF] Roblox's default controls are still on: " .. tostring(problem))
	end
end

function PlayerController.start()
	task.spawn(disableDefaultControls)

	CameraController.start()
	InputSampler.start()
	NetSim.on(remotes.PlayerAck, onAck)
	remotes.Tuning.OnClientEvent:Connect(function(overrides)
		PlayerController.overrides = overrides
		PlayerController.cfg = MovementConfig.resolve(overrides)
	end)
	NetSim.on(remotes.Combat, function(event: any)
		if typeof(event) == "table" and event.target == PlayerController.entityId and event.killed then
			PlayerController.alive = false
		end
	end)
	localPlayer.CharacterAdded:Connect(onCharacter)
	if localPlayer.Character then
		task.spawn(onCharacter, localPlayer.Character)
	end

	-- 4 draws the spike, while it's carried.
	local slotKeys = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = Spike.SLOT }
	UserInputService.InputBegan:Connect(function(input, processed)
		local slot = slotKeys[input.KeyCode]
		if slot and not processed then
			PlayerController.selectSlot(slot)
		end
	end)

	RunService:BindToRenderStep("VFPlayer", Enum.RenderPriority.Camera.Value + 1, onRender)
end

return PlayerController
