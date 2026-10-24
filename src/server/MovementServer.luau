--!strict
-- Server-authoritative movement.
--
-- Clients send their per-tick input; the server re-runs the same MovementSim
-- on it and owns the result. The owner receives acks (seq + authoritative
-- state) for reconciliation, everyone receives pose snapshots for
-- interpolation. A token bucket stops a client simulating faster than real
-- time (speed hacks), and the queue cap bounds how far behind a client's
-- input stream the server will ever be.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local MovementSim = require(Shared.Movement.MovementSim)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local MovementCodec = require(Shared.Net.MovementCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)

local TICK_RATE = MovementConfig.TickRate.value
local DT = 1 / TICK_RATE
local MAX_BURST_TICKS = 16 -- real-time slack a client may bank (125 ms)
local MAX_QUEUE = 24 -- inputs; beyond this the oldest are dropped (~190 ms)
local SNAPSHOT_RATE = 60
local KILL_HEIGHT = -150 -- metres

type Record = {
	player: Player,
	character: Model?,
	root: BasePart?,
	rootOffset: number, -- studs from feet to HumanoidRootPart centre
	spawnFeet: vector,
	state: MovementSim.State,
	queue: { MovementCodec.WireInput },
	tokens: number,
	lastSeq: number,
	ackDirty: boolean,
	yaw: number,
	pitch: number,
	droppedInputs: number,
}

local MovementServer = {}

local records: { [Player]: Record } = {}
local world = RobloxWorld.new()
local overrides: { [string]: number } = {}
local cfg = MovementConfig.resolve()
local remotes = Remotes.get()

local function canTune(player: Player): boolean
	return RunService:IsStudio() or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId)
end

local function setupCollisionGroup()
	local group = RobloxWorld.CHARACTER_GROUP
	if not PhysicsService:IsCollisionGroupRegistered(group) then
		PhysicsService:RegisterCollisionGroup(group)
	end
	PhysicsService:CollisionGroupSetCollidable(group, group, false)
end

local function tagPart(part: Instance)
	if part:IsA("BasePart") then
		part.CollisionGroup = RobloxWorld.CHARACTER_GROUP
	end
end

local function placeRoot(r: Record)
	local root = r.root
	if not root then
		return
	end
	local feet = Units.toStuds(r.state.position)
	root.CFrame = CFrame.new(feet + Vector3.new(0, r.rootOffset, 0)) * CFrame.Angles(0, r.yaw, 0)
end

local function onCharacter(r: Record, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not root or not humanoid or character.Parent == nil then
		return
	end
	for _, d in character:GetDescendants() do
		tagPart(d)
	end
	character.DescendantAdded:Connect(tagPart)

	r.rootOffset = CharacterRig.rootOffset(character, root)
	local feet = Units.toMetres(root.Position - Vector3.new(0, r.rootOffset, 0))
	r.spawnFeet = feet + vector.create(0, 0.05, 0)
	r.state = MovementSim.newState(r.spawnFeet, MovementConfig.DefaultWeapon)
	r.queue = {}
	r.tokens = 0
	r.character = character
	r.root = root
	r.ackDirty = true

	-- The simulation moves the character; Roblox physics must not.
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.UseJumpPower = true
	root.Anchored = true
	placeRoot(r)
end

local function onPlayerAdded(player: Player)
	local r: Record = {
		player = player,
		character = nil,
		root = nil,
		rootOffset = 3,
		spawnFeet = vector.create(0, 5, 0),
		state = MovementSim.newState(vector.create(0, 5, 0)),
		queue = {},
		tokens = 0,
		lastSeq = 0,
		ackDirty = false,
		yaw = 0,
		pitch = 0,
		droppedInputs = 0,
	}
	records[player] = r
	player.CharacterAdded:Connect(function(character)
		onCharacter(r, character)
	end)
	if player.Character then
		task.spawn(onCharacter, r, player.Character)
	end
	remotes.MovementTuning:FireClient(player, overrides)
end

local function onInput(player: Player, payload: any)
	local r = records[player]
	if not r or not r.root then
		return
	end
	local inputs = MovementCodec.decodeInputs(payload)
	if not inputs then
		return
	end
	for _, input in inputs do
		if input.seq > r.lastSeq then
			table.insert(r.queue, input)
		end
	end
	while #r.queue > MAX_QUEUE do
		local dropped = table.remove(r.queue, 1) :: MovementCodec.WireInput
		r.lastSeq = math.max(r.lastSeq, dropped.seq)
		r.droppedInputs += 1
		r.ackDirty = true
	end
end

local function simulate(r: Record, dt: number)
	r.tokens = math.min(r.tokens + dt * TICK_RATE, MAX_BURST_TICKS)
	while r.tokens >= 1 and #r.queue > 0 do
		local input = table.remove(r.queue, 1) :: MovementCodec.WireInput
		r.tokens -= 1
		if input.seq <= r.lastSeq then
			continue
		end
		r.lastSeq = input.seq
		r.yaw = input.yaw
		r.pitch = math.clamp(input.pitch, -math.pi / 2, math.pi / 2)
		local profile = MovementConfig.weapon(input.weapon)
		MovementSim.step(r.state, input :: any, cfg, profile.maxSpeed.value, world, DT)
		r.ackDirty = true
	end
	if r.state.position.y < KILL_HEIGHT then
		r.state = MovementSim.newState(r.spawnFeet, r.state.weapon)
		r.ackDirty = true
	end
	placeRoot(r)
end

local snapshotAccumulator = 0

local function onHeartbeat(dt: number)
	local poses: { MovementCodec.Pose } = {}
	for _, r in records do
		if not r.root then
			continue
		end
		simulate(r, dt)
		if r.ackDirty then
			r.ackDirty = false
			remotes.MovementAck:FireClient(r.player, MovementCodec.encodeAck(r.lastSeq, r.state))
		end
		table.insert(poses, {
			userId = r.player.UserId,
			position = r.state.position,
			yaw = r.yaw,
			pitch = r.pitch,
			crouchAlpha = r.state.crouchAlpha,
			grounded = r.state.grounded,
		})
	end

	snapshotAccumulator += dt
	if snapshotAccumulator < 1 / SNAPSHOT_RATE then
		return
	end
	snapshotAccumulator = 0
	local now = Workspace:GetServerTimeNow()
	local chunk = MovementCodec.MAX_POSES_PER_SNAPSHOT
	for first = 1, #poses, chunk do
		local slice = table.move(poses, first, math.min(first + chunk - 1, #poses), 1, {})
		remotes.MovementSnapshot:FireAllClients(MovementCodec.encodeSnapshot(now, slice))
	end
end

local function onTuning(player: Player, key: any, value: any)
	if not canTune(player) or typeof(key) ~= "string" then
		return
	end
	if key == "__reset" then
		table.clear(overrides)
	elseif (MovementConfig.Params :: any)[key] ~= nil and typeof(value) == "number" and value == value and math.abs(value) < 1e4 then
		overrides[key] = value
	else
		return
	end
	cfg = MovementConfig.resolve(overrides)
	remotes.MovementTuning:FireAllClients(overrides)
	print(string.format("[Movement] %s set %s = %s", player.Name, key, tostring(value)))
end

function MovementServer.start()
	setupCollisionGroup()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		records[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	remotes.MovementInput.OnServerEvent:Connect(onInput)
	remotes.MovementTuning.OnServerEvent:Connect(onTuning)
	RunService.Heartbeat:Connect(onHeartbeat)
end

-- Read access for later systems (weapons, hit registration).
function MovementServer.getState(player: Player): MovementSim.State?
	local r = records[player]
	return r and r.state
end

function MovementServer.getAim(player: Player): (number, number)
	local r = records[player]
	if not r then
		return 0, 0
	end
	return r.yaw, r.pitch
end

return MovementServer
