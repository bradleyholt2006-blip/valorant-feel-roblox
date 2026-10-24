--!strict
-- Client-side prediction and reconciliation for the local player's PlayerSim
-- (movement + weapons).
--
-- Every fixed 128 Hz tick we sample input, step PlayerSim immediately (so
-- movement and shots respond on the frame you press), remember the input and
-- the predicted result, and send the input to the server. When an ack arrives
-- we compare our prediction for that seq with the server's state; on mismatch
-- we rewind to the server state and replay the inputs it hasn't processed
-- yet. Shots re-simulated during a replay are not re-fired: effects only play
-- for the live tick. Visual position error from a correction is blended out
-- over a few frames instead of snapping the camera.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local MovementSim = require(Shared.Movement.MovementSim)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)

local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)
local RemoteEntities = require(script.Parent.RemoteEntities)

local TICK_RATE = MovementConfig.TickRate.value
local DT = 1 / TICK_RATE
local POSITION_TOLERANCE = 0.002 -- metres before we accept a server correction
local VELOCITY_TOLERANCE = 0.01 -- m/s
local CORRECTION_BLEND_TIME = 0.1 -- seconds to blend visual error out
local MAX_FRAME_TIME = 0.25

export type TickInfo = {
	time: number,
	input: PlayerCodec.WireInput,
	sim: PlayerSim.State,
	state: MovementSim.State, -- sim.movement, kept for the movement debug tools
	wishDir: vector,
	maxSpeed: number, -- run speed of the equipped weapon
	accurateFraction: number, -- deadzone fraction of that speed
	shot: WeaponSim.Shot?,
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
}
-- Called once per live simulated tick (debug tools hook in here).
PlayerController.tickListeners = {} :: { (TickInfo) -> () }
-- Called for each shot the local player fires, with the input that fired it
-- (live ticks only; replays after a correction don't re-fire).
PlayerController.shotListeners = {} :: { (WeaponSim.Shot, PlayerCodec.WireInput) -> () }
-- Called when the local player (re)spawns with a fresh simulation.
PlayerController.spawnListeners = {} :: { (PlayerSim.State) -> () }
-- Increments on every spawn; shot numbers restart each life.
PlayerController.life = 0

local localPlayer = Players.LocalPlayer
local world = RobloxWorld.new()
local remotes = Remotes.get()

local sim: PlayerSim.State? = nil
local prevPosition: vector = vector.create(0, 0, 0)
local prevCrouch = 0
local seq = 0
local pending: { PlayerCodec.WireInput } = {}
local unsent: { PlayerCodec.WireInput } = {}
local predicted: { [number]: PlayerSim.State } = {}
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

local function tick()
	local s = sim :: PlayerSim.State
	seq += 1
	local input: PlayerCodec.WireInput = {
		seq = seq,
		buttons = InputSampler.sample(),
		slot = PlayerController.desiredSlot,
		-- Quantise exactly as the wire does so both sides simulate the same input.
		yaw = PlayerCodec.quantizeYaw(CameraController.yaw),
		pitch = PlayerCodec.quantizePitch(CameraController.pitch),
		viewTime = RemoteEntities.renderTime(),
	}
	prevPosition = s.movement.position
	prevCrouch = s.movement.crouchAlpha
	local shot = PlayerSim.step(s, input, PlayerController.cfg, world, DT)
	simTime += DT

	table.insert(pending, input)
	table.insert(unsent, input)
	predicted[seq] = PlayerSim.copy(s)

	if shot then
		for _, listener in PlayerController.shotListeners do
			listener(shot, input)
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
		shot = shot,
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
		remotes.PlayerInput:FireServer(PlayerCodec.encodeInputs(unsent, first, last))
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
	-- any difference at all means the server saw something we didn't.
	local gw, sw = guess.weapons, server.weapons
	for slot = 1, 3 do
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
		or gw.sprayIndex ~= sw.sprayIndex
		or gw.shotCounter ~= sw.shotCounter
	then
		return true, posErr
	end
	if guess.tagUntilTick ~= server.tagUntilTick or guess.tagMultiplier ~= server.tagMultiplier then
		return true, posErr
	end
	return false, posErr
end

local function onAck(payload: buffer)
	local s = sim
	if not s or typeof(payload) ~= "buffer" or not PlayerController.alive then
		return
	end
	local ackSeq, serverSim = PlayerCodec.decodeAck(payload)
	local stats = PlayerController.stats
	if ackSeq < stats.lastAckSeq then
		return -- out of order (unreliable channel)
	end
	stats.lastAckSeq = ackSeq
	PlayerController.serverSim = serverSim

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
		local corrected = serverSim :: PlayerSim.State
		for _, input in pending do
			PlayerSim.step(corrected, input, PlayerController.cfg, world, DT)
			predicted[input.seq] = PlayerSim.copy(corrected)
		end
		visualOffset += before - corrected.movement.position
		prevPosition += corrected.movement.position - before
		sim = corrected
		PlayerController.sim = corrected
	end
	stats.pending = #pending
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

	if root and root.Parent then
		root.CFrame = CFrame.new(feetStuds + Vector3.new(0, rootOffset, 0)) * CFrame.Angles(0, CameraController.yaw, 0)
	end
	local def = PlayerSim.def(s)
	local zoom = if s.weapons.scoped > 0 and def.ads then def.ads.zoom[s.weapons.scoped] else 1
	CameraController.render(feetStuds + Vector3.new(0, eye * Units.STUDS_PER_METRE, 0), zoom)
end

local function onCharacter(character: Model)
	local r = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not r then
		return
	end
	root = r
	rootOffset = CharacterRig.rootOffset(character, r)
	local feet = Units.toMetres(r.Position - Vector3.new(0, rootOffset, 0)) + vector.create(0, 0.05, 0)
	local loadout = if sim then table.clone(sim.weapons.loadout) else nil
	sim = PlayerSim.new(feet, loadout)
	PlayerController.sim = sim
	PlayerController.desiredSlot = (sim :: PlayerSim.State).weapons.equipped
	PlayerController.alive = true
	PlayerController.life += 1
	prevPosition = feet
	visualOffset = vector.create(0, 0, 0)
	table.clear(pending)
	table.clear(predicted)
	for _, listener in PlayerController.spawnListeners do
		listener(sim :: PlayerSim.State)
	end
	-- Hide our own body in first person.
	local function hide(d: Instance)
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
		elseif d:IsA("Decal") then
			d.LocalTransparencyModifier = 1
		end
	end
	for _, d in character:GetDescendants() do
		hide(d)
	end
	character.DescendantAdded:Connect(hide)
end

-- Asks the server to change a tuning parameter (Studio / place owner only).
function PlayerController.requestTuning(key: string, value: number?)
	remotes.Tuning:FireServer(key, value)
end

-- Debug weapon give (Studio / place owner only); equips it too.
function PlayerController.requestWeapon(id: string)
	local def = WeaponConfig.Defs[id]
	if def then
		remotes.Loadout:FireServer(def.slot, id)
		PlayerController.desiredSlot = def.slot
	end
end

function PlayerController.start()
	local playerModule = require(localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: ModuleScript) :: any
	playerModule:GetControls():Disable()

	CameraController.start()
	InputSampler.start()
	remotes.PlayerAck.OnClientEvent:Connect(onAck)
	remotes.Tuning.OnClientEvent:Connect(function(overrides)
		PlayerController.overrides = overrides
		PlayerController.cfg = MovementConfig.resolve(overrides)
	end)
	remotes.Combat.OnClientEvent:Connect(function(event)
		if event.target == PlayerController.entityId and event.killed then
			PlayerController.alive = false
		end
	end)
	localPlayer.CharacterAdded:Connect(onCharacter)
	if localPlayer.Character then
		task.spawn(onCharacter, localPlayer.Character)
	end

	local slotKeys = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3 }
	UserInputService.InputBegan:Connect(function(input, processed)
		local slot = slotKeys[input.KeyCode]
		if slot and not processed then
			PlayerController.desiredSlot = slot
		end
	end)

	RunService:BindToRenderStep("VFPlayer", Enum.RenderPriority.Camera.Value + 1, onRender)
end

return PlayerController
