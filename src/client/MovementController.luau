--!strict
-- Client-side prediction and reconciliation for the local player.
--
-- Every fixed tick we sample input, step MovementSim immediately (so movement
-- responds on the frame you press a key), remember the input and the
-- predicted result, and send the input to the server. When an ack arrives we
-- compare our prediction for that seq with the server's state; on mismatch we
-- rewind to the server state and replay the inputs it hasn't processed yet.
-- Visual error from a correction is blended out over a few frames instead of
-- snapping the camera.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local MovementSim = require(Shared.Movement.MovementSim)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local MovementCodec = require(Shared.Net.MovementCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)

local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)

local TICK_RATE = MovementConfig.TickRate.value
local DT = 1 / TICK_RATE
local POSITION_TOLERANCE = 0.002 -- metres before we accept a server correction
local VELOCITY_TOLERANCE = 0.01 -- m/s
local CORRECTION_BLEND_TIME = 0.1 -- seconds to blend visual error out
local MAX_FRAME_TIME = 0.25

export type TickInfo = {
	time: number,
	input: MovementCodec.WireInput,
	state: MovementSim.State,
	wishDir: vector,
	maxSpeed: number,
	accurateFraction: number,
}

local MovementController = {}

MovementController.weapon = MovementConfig.DefaultWeapon
MovementController.cfg = MovementConfig.resolve()
MovementController.overrides = {} :: { [string]: number }
MovementController.state = nil :: MovementSim.State?
MovementController.serverState = nil :: MovementSim.State?
MovementController.stats = {
	pending = 0,
	corrections = 0,
	lastCorrectionError = 0,
	maxCorrectionError = 0,
	lastAckSeq = 0,
	sentInputs = 0,
}
-- Listeners called once per simulated tick (debug tools hook in here).
MovementController.tickListeners = {} :: { (TickInfo) -> () }

local localPlayer = Players.LocalPlayer
local world = RobloxWorld.new()
local remotes = Remotes.get()

local state: MovementSim.State? = nil
local prevPosition: vector = vector.create(0, 0, 0)
local prevCrouch = 0
local seq = 0
local pending: { MovementCodec.WireInput } = {}
local unsent: { MovementCodec.WireInput } = {}
local predicted: { [number]: MovementSim.State } = {}
local accumulator = 0
local simTime = 0
local visualOffset = vector.create(0, 0, 0)
local root: BasePart? = nil
local rootOffset = 3

local function profile()
	return MovementConfig.weapon(MovementController.weapon)
end

local function stepOnce(s: MovementSim.State, input: MovementCodec.WireInput)
	local p = MovementConfig.weapon(input.weapon)
	MovementSim.step(s, input :: any, MovementController.cfg, p.maxSpeed.value, world, DT)
end

local function tick()
	local s = state :: MovementSim.State
	seq += 1
	local input: MovementCodec.WireInput = {
		seq = seq,
		buttons = InputSampler.sample(),
		-- Quantise exactly as the wire does so both sides simulate the same input.
		yaw = MovementCodec.quantizeYaw(CameraController.yaw),
		pitch = MovementCodec.quantizePitch(CameraController.pitch),
		weapon = MovementController.weapon,
	}
	prevPosition = s.position
	prevCrouch = s.crouchAlpha
	stepOnce(s, input)
	simTime += DT

	table.insert(pending, input)
	table.insert(unsent, input)
	predicted[seq] = MovementSim.copy(s)

	local p = profile()
	local info: TickInfo = {
		time = simTime,
		input = input,
		state = s,
		wishDir = MovementSim.wishDirection(input.buttons, input.yaw),
		maxSpeed = p.maxSpeed.value,
		accurateFraction = p.accurateFraction.value,
	}
	for _, listener in MovementController.tickListeners do
		listener(info)
	end
end

local function flushInputs()
	if #unsent == 0 then
		return
	end
	-- Large batches (after a hitch) go out in chunks the decoder accepts.
	for first = 1, #unsent, 200 do
		local last = math.min(first + 199, #unsent)
		remotes.MovementInput:FireServer(MovementCodec.encodeInputs(unsent, first, last))
	end
	MovementController.stats.sentInputs += #unsent
	table.clear(unsent)
end

local function onAck(payload: buffer)
	local s = state
	if not s or typeof(payload) ~= "buffer" then
		return
	end
	local ackSeq, serverState = MovementCodec.decodeAck(payload)
	local stats = MovementController.stats
	if ackSeq < stats.lastAckSeq then
		return -- out of order (unreliable channel)
	end
	stats.lastAckSeq = ackSeq
	MovementController.serverState = serverState

	while #pending > 0 and pending[1].seq <= ackSeq do
		table.remove(pending, 1)
	end

	local guess = predicted[ackSeq]
	local needsCorrection = true
	if guess then
		local posErr = vector.magnitude(guess.position - serverState.position)
		local velErr = vector.magnitude(guess.velocity - serverState.velocity)
		needsCorrection = posErr > POSITION_TOLERANCE
			or velErr > VELOCITY_TOLERANCE
			or guess.grounded ~= serverState.grounded
			or guess.crouched ~= serverState.crouched
		if needsCorrection then
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
		local before = s.position
		local corrected = serverState :: MovementSim.State
		for _, input in pending do
			stepOnce(corrected, input)
			predicted[input.seq] = MovementSim.copy(corrected)
		end
		visualOffset += before - corrected.position
		prevPosition += corrected.position - before
		state = corrected
		MovementController.state = corrected
	end
	stats.pending = #pending
end

local function onRender(frameDt: number)
	CameraController.updateLook()
	local s = state
	if not s then
		return
	end
	accumulator = math.min(accumulator + frameDt, MAX_FRAME_TIME)
	while accumulator >= DT do
		tick()
		accumulator -= DT
	end
	flushInputs()

	s = state :: MovementSim.State
	local alpha = accumulator / DT
	visualOffset *= math.exp(-frameDt / (CORRECTION_BLEND_TIME / 3))
	local feet = prevPosition + (s.position - prevPosition) * alpha + visualOffset
	local crouch = prevCrouch + (s.crouchAlpha - prevCrouch) * alpha
	local cfg = MovementController.cfg
	local eye = cfg.standEyeHeight + (cfg.crouchEyeHeight - cfg.standEyeHeight) * crouch
	local feetStuds = Units.toStuds(feet)

	if root and root.Parent then
		root.CFrame = CFrame.new(feetStuds + Vector3.new(0, rootOffset, 0)) * CFrame.Angles(0, CameraController.yaw, 0)
	end
	CameraController.render(feetStuds + Vector3.new(0, eye * Units.STUDS_PER_METRE, 0))
end

local function onCharacter(character: Model)
	local r = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not r then
		return
	end
	root = r
	rootOffset = CharacterRig.rootOffset(character, r)
	local feet = Units.toMetres(r.Position - Vector3.new(0, rootOffset, 0)) + vector.create(0, 0.05, 0)
	state = MovementSim.newState(feet, MovementController.weapon)
	MovementController.state = state
	prevPosition = feet
	visualOffset = vector.create(0, 0, 0)
	table.clear(pending)
	table.clear(predicted)
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

function MovementController.setWeapon(id: string)
	if MovementConfig.Weapons[id] then
		MovementController.weapon = id
	end
end

-- Asks the server to change a tuning parameter (Studio / place owner only).
function MovementController.requestTuning(key: string, value: number?)
	remotes.MovementTuning:FireServer(key, value)
end

function MovementController.profile()
	return profile()
end

function MovementController.start()
	local playerModule = require(localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: ModuleScript) :: any
	playerModule:GetControls():Disable()

	CameraController.start()
	remotes.MovementAck.OnClientEvent:Connect(onAck)
	remotes.MovementTuning.OnClientEvent:Connect(function(overrides)
		MovementController.overrides = overrides
		MovementController.cfg = MovementConfig.resolve(overrides)
	end)
	localPlayer.CharacterAdded:Connect(onCharacter)
	if localPlayer.Character then
		task.spawn(onCharacter, localPlayer.Character)
	end
	RunService:BindToRenderStep("VFMovement", Enum.RenderPriority.Camera.Value + 1, onRender)
end

return MovementController
