--!strict
-- Server-authoritative player simulation (movement + weapons).
--
-- Clients send their per-tick input; the server re-runs the same PlayerSim on
-- it and owns the result. Like the reference's server move queue (Riot,
-- "Peeking into VALORANT's Netcode"), inputs are numbered, queued and run in
-- order. InputQueue's budget stops a client simulating faster than real time,
-- its cap bounds how far behind the server will ever run, and it drains a
-- backlog that would otherwise last. Shots come out of the simulation itself,
-- so fire rate and ammo are enforced here.
--
-- Each server frame runs everyone's queued inputs a tick at a time in turn
-- (one input per player per round), so when two players' shots land in the
-- same frame the one fired on the earlier tick is resolved first, whichever
-- player's queue happens to come first.
--
-- Moves run in bunches as they arrive, so what the snapshots show of each
-- player is paced onto a steady timeline first (MovePacer).
--
-- Each life numbers its inputs from InputQueue.LIFE_GAP past the last one the
-- server ran, and tells the owner where (CharacterRig.FIRST_SEQ). So when a
-- life starts while the player is still alive (the arena restarts a round),
-- the moves the owner sent for the old one before it knew are dropped here,
-- instead of running on the new life.

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
local InputQueue = require(Shared.Net.InputQueue)
local MovePacer = require(Shared.Net.MovePacer)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)
local StepTracker = require(Shared.Audio.StepTracker)

local Entities = require(script.Parent.Entities)
local Tuning = require(script.Parent.Tuning)

local TICK_RATE = MovementConfig.TickRate.value
local DT = 1 / TICK_RATE
local KILL_HEIGHT = -150 -- metres

type Record = {
	player: Player,
	entity: Entities.Entity,
	character: Model?,
	root: BasePart?,
	rootOffset: number, -- studs from feet to HumanoidRootPart centre
	spawnFeet: vector,
	sim: PlayerSim.State,
	inputs: InputQueue.Queue<PlayerCodec.WireInput>,
	lastSeq: number,
	buttons: number, -- of the last input run, for the sound others hear
	ackDirty: boolean,
	yaw: number,
	pitch: number,
	alive: boolean,
	droppedInputs: number,
	pacer: MovePacer.Pacer, -- the pose after each move, at the move's time
	shown: PlayerCodec.Pose?, -- what this frame's snapshot shows
}

-- Called with the bullets of each round a player fires (several for a
-- shotgun), and the input's viewTime.
export type ShotHandler = (shooter: Entities.Entity, shots: { WeaponSim.Shot }, viewTime: number) -> ()
export type SpawnPoint = { feet: vector, yaw: number }

local PlayerSimServer = {}

-- Where a player's next life starts, when something other than the place's
-- SpawnLocations decides (the arena): feet in metres and the way to face.
PlayerSimServer.spawnPicker = nil :: ((Player) -> SpawnPoint?)?
-- Whether a player may change weapons now, when something other than the
-- debug rule (Studio or the place owner) decides (the arena).
PlayerSimServer.loadoutRule = nil :: ((Player) -> boolean?)?
-- Called when a player dies.
PlayerSimServer.deathListeners = {} :: { (Player) -> () }

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

-- The player's pose as the simulation has it now.
local function currentPose(r: Record): PlayerCodec.Pose
	local m, w = r.sim.movement, r.sim.weapons
	return {
		id = r.entity.id,
		position = m.position,
		yaw = r.yaw,
		pitch = r.pitch,
		crouchAlpha = m.crouchAlpha,
		grounded = m.grounded,
		alive = true,
		quiet = StepTracker.isQuiet(r.buttons, m.crouched),
		reloading = WeaponSim.isReloading(w),
		weapon = WeaponConfig.IndexOf[w.loadout[w.equipped]] or 0,
	}
end

-- Starts the snapshots over from where the player is (spawned or moved).
local function restartPacing(r: Record)
	MovePacer.reset(r.pacer)
	r.shown = nil
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
	local picker = PlayerSimServer.spawnPicker
	local point = if picker then picker(r.player) else nil
	local feet = if point then point.feet else Units.toMetres(root.Position - Vector3.new(0, r.rootOffset, 0))
	r.spawnFeet = feet + vector.create(0, 0.05, 0)
	r.lastSeq += InputQueue.LIFE_GAP
	r.buttons = 0
	character:SetAttribute(CharacterRig.FIRST_SEQ, r.lastSeq + 1)
	if point then
		r.yaw, r.pitch = point.yaw, 0
		character:SetAttribute(CharacterRig.SPAWN_YAW, point.yaw)
	end
	character:SetAttribute(CharacterRig.SPAWN_FEET, Units.asVector3(r.spawnFeet))
	r.sim = newSim(r)
	r.inputs = InputQueue.new()
	r.character = character
	r.root = root
	r.ackDirty = true
	r.alive = true
	restartPacing(r)
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
			-- Until the first move of this life has run, where it spawned.
			return r.shown or currentPose(r)
		end,
		onKilled = function()
			r.alive = false
			InputQueue.clear(r.inputs)
			local humanoid = r.character and r.character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
			for _, listener in PlayerSimServer.deathListeners do
				listener(player)
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
		inputs = InputQueue.new(),
		lastSeq = 0,
		buttons = 0,
		ackDirty = false,
		yaw = 0,
		pitch = 0,
		alive = false,
		droppedInputs = 0,
		pacer = MovePacer.new(),
		shown = nil,
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
			local dropped = InputQueue.push(r.inputs, input)
			if dropped then
				r.lastSeq = math.max(r.lastSeq, dropped.seq)
				r.droppedInputs += 1
				r.ackDirty = true
			end
		end
	end
end

-- Debug loadout changes (Studio / place owner), until there is a buy menu;
-- in the arena, its buy phase decides.
local function onLoadout(player: Player, slot: any, id: any)
	local r = records[player]
	if not r or typeof(slot) ~= "number" or typeof(id) ~= "string" then
		return
	end
	local rule = PlayerSimServer.loadoutRule
	local allowed = if rule then rule(player) else nil
	if allowed == nil then
		allowed = Tuning.canTune(player)
	end
	if not allowed then
		return
	end
	local def = WeaponConfig.Defs[id]
	if not def or def.slot ~= slot then
		return
	end
	WeaponSim.give(r.sim.weapons, slot, id, r.sim.movement.tick * DT)
	r.ackDirty = true
end

-- Runs the player's next queued input, if the budget allows one. Returns
-- whether there may be more to run this frame.
local function stepOne(r: Record, cfg: MovementConfig.Values): boolean
	while r.alive do
		local input = InputQueue.take(r.inputs)
		if not input then
			return false
		end
		if input.seq <= r.lastSeq then
			continue
		end
		r.lastSeq = input.seq
		r.buttons = input.buttons
		r.yaw = input.yaw
		r.pitch = math.clamp(input.pitch, -math.pi / 2, math.pi / 2)
		local shots = PlayerSim.step(r.sim, input, cfg, world, DT)
		MovePacer.push(r.pacer, input.seq * DT, currentPose(r))
		r.ackDirty = true
		if shots then
			onShot(r.entity, shots, input.viewTime)
		end
		return true
	end
	return false
end

-- One server frame: dt seconds since the last, ending at server time `now`
-- (the time this frame's snapshot carries).
function PlayerSimServer.step(dt: number, now: number)
	local cfg = Tuning.config()
	for _, r in records do
		if r.root then
			InputQueue.refill(r.inputs, dt)
		end
	end
	local more = true
	while more do
		more = false
		for _, r in records do
			if r.root and stepOne(r, cfg) then
				more = true
			end
		end
	end
	local remotes = Remotes.get()
	for _, r in records do
		if not r.root then
			continue
		end
		InputQueue.endFrame(r.inputs, dt)
		if r.sim.movement.position.y < KILL_HEIGHT then
			r.sim = newSim(r)
			r.entity.sim = r.sim
			r.ackDirty = true
			restartPacing(r)
		end
		r.shown = if r.alive then MovePacer.advance(r.pacer, now) else nil
		placeRoot(r)
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
