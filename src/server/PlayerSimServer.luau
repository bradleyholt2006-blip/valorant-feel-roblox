--!strict
-- Server-authoritative player simulation (movement + weapons).
--
-- Clients send their per-tick input; the server re-runs the same PlayerSim on
-- it and owns the result. Like the reference's server move queue (Riot,
-- "Peeking into VALORANT's Netcode"), inputs are numbered, queued and run in
-- order. A token bucket stops a client simulating faster than real time, the
-- queue cap bounds how far behind the server will ever run, and shots come
-- out of the simulation itself, so fire rate and ammo are enforced here.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Health = require(Shared.Combat.Health)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)

local Entities = require(script.Parent.Entities)
local Tuning = require(script.Parent.Tuning)

local TICK_RATE = MovementConfig.TickRate.value
local DT = 1 / TICK_RATE
local MAX_BURST_TICKS = 16 -- real-time slack a client may bank (125 ms)
local MAX_QUEUE = 24 -- inputs; beyond this the oldest are dropped (~190 ms)
local KILL_HEIGHT = -150 -- metres

type Record = {
	player: Player,
	entity: Entities.Entity,
	character: Model?,
	root: BasePart?,
	rootOffset: number, -- studs from feet to HumanoidRootPart centre
	spawnFeet: vector,
	sim: PlayerSim.State,
	queue: { PlayerCodec.WireInput },
	tokens: number,
	lastSeq: number,
	ackDirty: boolean,
	yaw: number,
	pitch: number,
	alive: boolean,
	droppedInputs: number,
}

export type ShotHandler = (shooter: Entities.Entity, shot: WeaponSim.Shot, viewTime: number) -> ()

local PlayerSimServer = {}

local records: { [Player]: Record } = {}
local world = RobloxWorld.new()
local onShot: ShotHandler = function() end
-- Seeds each life's spray randomness. The owner learns it from the first ack,
-- so its prediction draws the same bullets the server does.
local seeds = Random.new()

local function newSim(r: Record): PlayerSim.State
	return PlayerSim.new(r.spawnFeet, table.clone(r.sim.weapons.loadout), seeds:NextInteger(0, 2 ^ 31 - 1))
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
	local feet = Units.toStuds(r.sim.movement.position)
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
	r.sim = newSim(r)
	r.queue = {}
	r.tokens = 0
	r.character = character
	r.root = root
	r.ackDirty = true
	r.alive = true
	Health.reset(r.entity.health)
	r.entity.sim = r.sim

	-- The simulation moves the character; Roblox physics must not, and our
	-- Health module, not the Humanoid's, decides when a player dies.
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.UseJumpPower = true
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	root.Anchored = true
	placeRoot(r)
	Remotes.get().Combat:FireAllClients({ kind = "spawn", target = r.entity.id, health = r.entity.health.health, shield = r.entity.health.shield })
end

local function onPlayerAdded(player: Player)
	local hp = WeaponConfig.Health
	local r: Record
	local entity: Entities.Entity = {
		id = PlayerCodec.entityIdForUser(player.UserId),
		kind = "player",
		name = player.Name,
		player = player,
		health = Health.new(hp.maxHealth.value, hp.heavyShield.value),
		sim = nil,
		pose = function(): PlayerCodec.Pose?
			if not r.root or not r.alive then
				return nil
			end
			local m = r.sim.movement
			return {
				id = r.entity.id,
				position = m.position,
				yaw = r.yaw,
				pitch = r.pitch,
				crouchAlpha = m.crouchAlpha,
				grounded = m.grounded,
				alive = true,
			}
		end,
		onKilled = function()
			r.alive = false
			table.clear(r.queue)
			local humanoid = r.character and r.character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end,
	}
	r = {
		player = player,
		entity = entity,
		character = nil,
		root = nil,
		rootOffset = 3,
		spawnFeet = vector.create(0, 5, 0),
		sim = PlayerSim.new(vector.create(0, 5, 0)),
		queue = {},
		tokens = 0,
		lastSeq = 0,
		ackDirty = false,
		yaw = 0,
		pitch = 0,
		alive = false,
		droppedInputs = 0,
	}
	records[player] = r
	Entities.add(entity)
	player.CharacterAdded:Connect(function(character)
		onCharacter(r, character)
	end)
	if player.Character then
		task.spawn(onCharacter, r, player.Character)
	end
end

local function onInput(player: Player, payload: any)
	local r = records[player]
	if not r or not r.root or not r.alive then
		return
	end
	local inputs = PlayerCodec.decodeInputs(payload)
	if not inputs then
		return
	end
	for _, input in inputs do
		if input.seq > r.lastSeq then
			table.insert(r.queue, input)
		end
	end
	while #r.queue > MAX_QUEUE do
		local dropped = table.remove(r.queue, 1) :: PlayerCodec.WireInput
		r.lastSeq = math.max(r.lastSeq, dropped.seq)
		r.droppedInputs += 1
		r.ackDirty = true
	end
end

-- Debug loadout changes (Studio / place owner), until there is a buy phase.
local function onLoadout(player: Player, slot: any, id: any)
	local r = records[player]
	if not r or not Tuning.canTune(player) or typeof(slot) ~= "number" or typeof(id) ~= "string" then
		return
	end
	local def = WeaponConfig.Defs[id]
	if not def or def.slot ~= slot then
		return
	end
	WeaponSim.give(r.sim.weapons, slot, id, r.sim.movement.tick * DT)
	r.ackDirty = true
end

local function simulate(r: Record, dt: number)
	local cfg = Tuning.config()
	r.tokens = math.min(r.tokens + dt * TICK_RATE, MAX_BURST_TICKS)
	while r.alive and r.tokens >= 1 and #r.queue > 0 do
		local input = table.remove(r.queue, 1) :: PlayerCodec.WireInput
		r.tokens -= 1
		if input.seq <= r.lastSeq then
			continue
		end
		r.lastSeq = input.seq
		r.yaw = input.yaw
		r.pitch = math.clamp(input.pitch, -math.pi / 2, math.pi / 2)
		local shot = PlayerSim.step(r.sim, input, cfg, world, DT)
		r.ackDirty = true
		if shot then
			onShot(r.entity, shot, input.viewTime)
		end
	end
	if r.sim.movement.position.y < KILL_HEIGHT then
		r.sim = newSim(r)
		r.entity.sim = r.sim
		r.ackDirty = true
	end
	placeRoot(r)
end

function PlayerSimServer.step(dt: number)
	local remotes = Remotes.get()
	for _, r in records do
		if not r.root then
			continue
		end
		simulate(r, dt)
		if r.ackDirty then
			r.ackDirty = false
			remotes.PlayerAck:FireClient(r.player, PlayerCodec.encodeAck(r.lastSeq, r.sim))
		end
	end
end

-- Marks a player's state as changed outside the input stream (damage slow,
-- loadout), so the owner gets a fresh ack and reconciles.
function PlayerSimServer.markDirty(player: Player)
	local r = records[player]
	if r then
		r.ackDirty = true
	end
end

function PlayerSimServer.start(handler: ShotHandler)
	onShot = handler
	setupCollisionGroup()
	Players.RespawnTime = 3
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local r = records[player]
		if r then
			Entities.remove(r.entity.id)
		end
		records[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	local remotes = Remotes.get()
	remotes.PlayerInput.OnServerEvent:Connect(onInput)
	remotes.Loadout.OnServerEvent:Connect(onLoadout)
end

-- Read access for other systems.
function PlayerSimServer.getSim(player: Player): PlayerSim.State?
	local r = records[player]
	return r and r.sim
end

return PlayerSimServer
