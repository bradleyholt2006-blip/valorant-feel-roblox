--!strict
-- Server-authoritative player simulation (movement + weapons).
--
-- Clients send their per-tick input; the server re-runs the same PlayerSim on
-- it and owns the result. Like the reference's server move queue (Riot,
-- "Peeking into VALORANT's Netcode"), inputs are numbered, queued and run in
-- order. InputQueue's budget stops a client simulating faster than real time,
-- its cap bounds how far behind the server will ever run, and it drains a
-- backlog that would otherwise last. Shots and knife swings come out of the
-- simulation itself, so fire rates and ammo are enforced here.
--
-- Each server frame runs everyone's queued inputs a tick at a time in turn
-- (one input per player per round), so when two players' shots land in the
-- same frame the one fired on the earlier tick is resolved first, whichever
-- player's queue happens to come first.
--
-- Moves run in bunches as they arrive, so what the snapshots show of each
-- player is paced onto a steady timeline first (MovePacer).
--
-- The spike's plant and defuse run in the simulation too (SpikeSim): what a
-- player may do with it each tick comes from SpikeServer (objectiveFor), and
-- what they did goes back to it (spikeListeners).
--
-- So does the ability kit (system 17, AbilitySim), which every life keeps
-- from the last: what's cast goes to castListeners (AbilityServer), and
-- AbilityServer changes the kit between ticks. Phoenix's Run it Back
-- (system 33) puts him back at its mark in the simulation too, and the
-- snapshots start over from there; while his body's gone he's out of play
-- (inPlay), and they leave him out. So does Omen's Shrouded Step (system
-- 42) as he goes, out of play until he's there (StepServer). His From the
-- Shadows (system 43) puts him where it takes him as a Shade, and back
-- where he was if X or an enemy's hit breaks it (the hit between ticks,
-- ShadowServer, moved), and the snapshots start over from each; the place
-- on the map a move asks for it to take him is checked first (pointCheck).
-- Sage's Slow Orb (system 37) slows a
-- player's ticks in its fields (from SlowServer, PlayerSimServer.fields),
-- and her Barrier Orb's walls stand in the world their ticks go through
-- (system 38, from BarrierServer, PlayerSimServer.barriers), both judged
-- at the time their screen showed (SlowSim.judged), as their own
-- prediction judges them. Her Resurrection (system 39, ReviveServer) asks
-- for a new life where a body lies (revive): it starts as high as the body
-- has risen, out of play, on the last life's kit with no shield, and held
-- in its simulation (AbilitySim's floatUntil and heldUntil, which the
-- owner learns from CharacterRig.REVIVED) until ReviveServer has it burst
-- out. Sova's Owl Drone (system 47) flies in his simulation too: while it
-- flies, his input is the drone's, so the snapshots show his body facing
-- and looking as it did as he sent it, its gun away, and his view (view)
-- is the drone's. DroneServer shows the drone itself. A fallen player who
-- takes over a bot (system 62, BotTakeover) starts a new life in its body
-- (takeOver): where it stands, on its kit, health and shield as they are,
-- in play at once; and if the bot's gone by the time the new character's
-- there, the character's taken away again and there's no life.
--
-- Each life numbers its inputs from InputQueue.LIFE_GAP past the last one the
-- server ran, and tells the owner where (CharacterRig.FIRST_SEQ). So when a
-- life starts while the player is still alive (the arena restarts a round),
-- the moves the owner sent for the old one before it knew are dropped here,
-- instead of running on the new life.
--
-- A character's root is put where its life starts and left there: moved
-- with the player, it would tell every client where they are, which the
-- fog of war keeps from those who can't see them (system 35). Every client
-- draws everyone from the snapshots instead (RemoteEntities), and the
-- owner moves its own.
--
-- Bots (system 60) cast abilities and are reached by them as players are
-- (system 65): each is an actor here as a player is, known by its stand-in
-- (BotServer.standIn), and BotServer answers for it (PlayerSimServer.bots)
-- where a player's record would: its entity, simulation, view and life.
-- Its casts and ticks go to castListeners and tickListeners as a player's
-- do. Nothing goes to a bot's client, as there's none.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
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
local ReviveSim = require(Shared.Abilities.ReviveSim)
local BotTakeover = require(Shared.Bots.BotTakeover)
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
	freshKit: boolean, -- the next life starts on the starting kit
	kit: { string }?, -- that kit's weapons by slot (nil: WeaponConfig.DefaultLoadout)
	kitShield: string?, -- and its shield ("" for none; nil: WeaponConfig.DefaultShield)
	spawnAskedAt: number?, -- os.clock() when a new life was asked for, until it starts
	behind: number, -- seconds their screen was behind the server at their last move run
	-- The Resurrection's return asked for (system 39), until its life starts:
	-- the floor under the body, the way it faced, and when it was cast
	-- (server time).
	revive: { feet: vector, yaw: number, at: number }?,
	-- A bot's body asked for (system 62), until the new life starts: what
	-- hands it over then, or says it's gone.
	takeover: (() -> Body?)?,
}

-- Called with the bullets of each round a player fires (several for a
-- shotgun), and the input's viewTime.
export type ShotHandler = (shooter: Entities.Entity, shots: { WeaponSim.Shot }, viewTime: number) -> ()
-- Called with each knife swing a player starts, and the input's viewTime.
export type SwingHandler = (attacker: Entities.Entity, swing: WeaponSim.Swing, viewTime: number) -> ()
export type SpawnPoint = { feet: vector, yaw: number }
-- A bot's body taken over (system 62), as it is: its feet in metres, the
-- way it looks, its kit (the spike's slot too) and its health and shield.
export type Body = { feet: vector, yaw: number, pitch: number, kit: BotTakeover.Kit, health: Health.State }
-- A player, or a bot's stand-in (system 65).
export type Actor = Instance
-- What BotServer answers for each bot, by its stand-in.
export type BotHooks = {
	list: () -> { Instance }, -- every bot's stand-in
	actorOf: (Entities.Entity) -> Instance?, -- a bot's entity's stand-in
	entityOf: (Instance) -> Entities.Entity?,
	getSim: (Instance) -> PlayerSim.State?,
	view: (Instance) -> (vector?, vector?),
	isAlive: (Instance) -> boolean,
	moved: (Instance) -> (),
}

local PlayerSimServer = {}

-- Where a player's next life starts, when something other than the place's
-- SpawnLocations decides (the arena): feet in metres and the way to face.
PlayerSimServer.spawnPicker = nil :: ((Player) -> SpawnPoint?)?
-- Whether a player may change weapons now, when something other than the
-- debug rule (Studio or the place owner) decides (the arena).
PlayerSimServer.loadoutRule = nil :: ((Player) -> boolean?)?
-- Called when a player dies, with the player who killed them, if one did,
-- and whoever did, if anyone else did (a bot too, system 60).
PlayerSimServer.deathListeners = {} :: { (Player, Player?, Entities.Entity?) -> () }
-- Called when a player's new life starts.
PlayerSimServer.spawnListeners = {} :: { (Player) -> () }
-- What a player may do with the spike this tick, when there's one in play
-- (SpikeServer); nothing without.
PlayerSimServer.objectiveFor = nil :: ((Player) -> Spike.Context)?
-- Called with what happened with the spike in a player's simulation: a
-- plant, a defuse, a drop, or a defuse let go of.
PlayerSimServer.spikeListeners = {} :: { (Player, SpikeSim.Act) -> () }
-- Called with the gun a player let go of with G (system 15), with their feet
-- and the way they faced as they did.
PlayerSimServer.dropListeners = {} :: { (Player, WeaponSim.Dropped, vector, number) -> () }
-- Called with each ability a player or a bot casts (system 17).
PlayerSimServer.castListeners = {} :: { (Actor, AbilitySim.Cast) -> () }
-- The Slow Orbs' fields in play (system 37, SlowServer); none without.
PlayerSimServer.fields = nil :: (() -> { SlowSim.Field })?
-- The Barrier Orbs' walls in play, judged at a server time, and whether a
-- wall can go up then (system 38, BarrierServer); none without.
PlayerSimServer.barriers = nil :: ((number) -> BarrierSim.Walls)?
-- Called after each of a player's or a bot's ticks, with its input and its
-- casts, if any (system 18 flies thrown clouds on them).
PlayerSimServer.tickListeners = {} :: { (Actor, PlayerCodec.WireInput, { AbilitySim.Cast }?) -> () }
-- The debug give of the spike: the one spike there is, handed over, not a
-- new one (SpikeServer).
PlayerSimServer.spikeGive = nil :: ((Player) -> ())?
-- Whether a place on the map a player's move asks From the Shadows to take
-- them (system 43, PlayerCodec.WireInput's point, metres) is on the map
-- they're playing, when something knows (ShadowServer): a move asking for
-- one that isn't goes as if it asked for none. Without, any is.
PlayerSimServer.pointCheck = nil :: ((Player, vector) -> boolean)?
-- The Soul Orb of Reyna's in a player's or a bot's reach from its eye
-- (system 73, SoulServer), by its number; none without.
PlayerSimServer.soulOf = nil :: ((Actor, vector) -> number?)?
-- How long a new life that's been asked for is waited for. Roblox loads a
-- character in about a third of a second in Studio (measured); one that
-- hasn't come by this is taken as not coming.
PlayerSimServer.SPAWN_WAIT = 5
-- Whether a new life that keeps the last one's kit keeps its shield as it
-- was, damaged or not, rather than a fresh one (the spike rounds: 'Even if
-- you survive, you may still have to repurchase armor if you took damage',
-- Hotspawn's economy guide; community).
PlayerSimServer.keepShields = false
-- The bots, as BotServer answers for them (system 65); none without.
PlayerSimServer.bots = nil :: BotHooks?
-- Called when a bot dies, with its stand-in and whoever killed it, if
-- anyone else did, and when its new life starts, with its stand-in (system
-- 65): what the ability servers do as a player's does.
PlayerSimServer.botDeathListeners = {} :: { (Actor, Entities.Entity?) -> () }
PlayerSimServer.botSpawnListeners = {} :: { (Actor) -> () }

local records: { [Instance]: Record } = {}
local world = RobloxWorld.new()
local onShot: ShotHandler = function() end
local onSwing: SwingHandler = function() end
-- The server time of the frame the moves are running in.
local stepNow = 0
-- Seeds each life's spray randomness. The owner learns it from the first ack,
-- so its prediction draws the same bullets the server does.
local seeds = Random.new()

-- A life keeps the last one's weapons, unless it starts on the starting kit,
-- but never the spike: a carrier drops it as they die. Nor an ultimate's
-- weapon, which a death ends (WeaponSim.newState). It keeps the last one's
-- ability kit too, with nothing under way.
local function newSim(r: Record): PlayerSim.State
	local kit = r.kit
	local loadout = if not r.freshKit then table.clone(r.sim.weapons.loadout) elseif kit then table.clone(kit) else nil
	if loadout then
		loadout[Spike.SLOT] = ""
	end
	local sim = PlayerSim.new(r.spawnFeet, loadout, seeds:NextInteger(0, 2 ^ 31 - 1))
	sim.abilities = AbilitySim.copy(r.sim.abilities)
	AbilitySim.settle(sim.abilities)
	return sim
end

-- A life in a bot's body (system 62): on its kit as it is, but for the
-- spike, which SpikeServer hands over as the life starts; and, as any
-- life, the player's own ability kit.
local function takenSim(r: Record, kit: BotTakeover.Kit): PlayerSim.State
	local loadout = table.clone(kit.loadout)
	loadout[Spike.SLOT] = ""
	local sim = PlayerSim.new(r.spawnFeet, loadout, seeds:NextInteger(0, 2 ^ 31 - 1))
	BotTakeover.arm(sim.weapons, kit)
	sim.abilities = AbilitySim.copy(r.sim.abilities)
	AbilitySim.settle(sim.abilities)
	return sim
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

-- The player's pose as the simulation has it now. While the Owl Drone
-- flies, and on the tick its flight's over, the body faces and looks as it
-- did as he sent it (system 47), not as the input does.
local function currentPose(r: Record): PlayerCodec.Pose
	local m, w, kit = r.sim.movement, r.sim.weapons, r.sim.abilities
	local t = m.tick * DT
	local body = AbilitySim.droning(kit) or math.abs(kit.landAt - t) < 1e-9
	return {
		id = r.entity.id,
		position = m.position,
		yaw = if body then kit.bodyYaw else r.yaw,
		pitch = if body then kit.bodyPitch else r.pitch,
		crouchAlpha = m.crouchAlpha,
		grounded = m.grounded,
		alive = true,
		-- A dash makes no steps (system 17).
		quiet = StepTracker.isQuiet(r.buttons, m.crouched) or AbilitySim.dashing(r.sim.abilities, m.tick * DT),
		reloading = WeaponSim.isReloading(w),
		-- Defusing, taking an Ultimate Orb (system 49) or flying the Owl
		-- Drone, the weapon is put away.
		weapon = if SpikeSim.stowed(r.sim.spike) or AbilitySim.droning(kit) then 0 else WeaponConfig.IndexOf[w.loadout[w.equipped]] or 0,
		channel = r.sim.spike.channel,
		gliding = m.gliding,
		shade = AbilitySim.shaded(r.sim.abilities, m.tick * DT),
	}
end

-- Starts the snapshots over from where the player is (spawned or moved).
local function restartPacing(r: Record)
	MovePacer.reset(r.pacer)
	r.shown = nil
end

-- Puts the character's root where the player is, as a life starts (and not
-- after: the header says why).
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
	-- The Resurrection's return (system 39) starts where the body lies, as
	-- high as it's risen by now, facing the way it does.
	local revive = r.revive
	r.revive = nil
	-- A bot's body taken over (system 62) starts where the bot is now, as
	-- it is; with the bot gone meanwhile, there's no life, and the new
	-- character's taken away again.
	local take = if revive then nil else r.takeover
	r.takeover = nil
	local body = if take then take() else nil
	if take and not body then
		r.spawnAskedAt = nil
		r.character, r.root = nil, nil
		task.defer(function()
			if r.player.Character == character then
				r.player.Character = nil
			end
			character:Destroy()
		end)
		return
	end
	local now = Workspace:GetServerTimeNow()
	local picker = PlayerSimServer.spawnPicker
	local point: SpawnPoint? = if revive
		then { feet = revive.feet + vector.create(0, ReviveSim.risen(revive.at, now), 0), yaw = revive.yaw }
		elseif body then { feet = body.feet, yaw = body.yaw }
		elseif picker then picker(r.player)
		else nil
	local feet = if point then point.feet else Units.toMetres(root.Position - Vector3.new(0, r.rootOffset, 0))
	r.spawnFeet = feet + vector.create(0, 0.05, 0)
	r.lastSeq += InputQueue.LIFE_GAP
	r.buttons = 0
	character:SetAttribute(CharacterRig.FIRST_SEQ, r.lastSeq + 1)
	if point then
		r.yaw, r.pitch = point.yaw, 0
		character:SetAttribute(CharacterRig.SPAWN_YAW, point.yaw)
	end
	if body then
		r.pitch = body.pitch
		character:SetAttribute(CharacterRig.SPAWN_PITCH, body.pitch)
		character:SetAttribute(CharacterRig.SPAWN_KIT, BotTakeover.kitText(body.kit))
	end
	-- Held as it rises until it bursts out, and then for the fall, in the
	-- life's own seconds.
	local floatFor = if revive then math.max(ReviveSim.burstAt(revive.at) - now, 0) else nil
	if floatFor then
		character:SetAttribute(CharacterRig.REVIVED, floatFor)
	end
	character:SetAttribute(CharacterRig.SPAWN_FEET, Units.asVector3(r.spawnFeet))
	r.spawnAskedAt = nil
	r.sim = if body then takenSim(r, body.kit) else newSim(r)
	if floatFor then
		r.sim.abilities.floatUntil = floatFor
		r.sim.abilities.heldUntil = floatFor + AbilityConfig.Resurrection.fall.value
	end
	r.inputs = InputQueue.new()
	r.character = character
	r.root = root
	r.ackDirty = true
	r.alive = true
	restartPacing(r)
	-- Brought back with full health 'excluding shields' (the VALORANT
	-- Wiki): the shield worn, broken. A bot's body taken over (system 62):
	-- its health and shield as they are.
	local kept = if revive
		then ReviveSim.UNSHIELDED
		elseif body then Health.keep(body.health)
		elseif PlayerSimServer.keepShields and not r.freshKit then Health.keep(r.entity.health)
		else nil
	if body then
		-- The next life keeps this one's kit, as a survivor's does, unless
		-- a death takes it back.
		Health.setShield(r.entity.health, body.health.kind)
		r.freshKit = false
	elseif r.freshKit then
		Health.setShield(r.entity.health, r.kitShield or WeaponConfig.DefaultShield)
		r.freshKit = false
	end
	Health.reset(r.entity.health)
	if kept then
		Health.restore(r.entity.health, kept)
	end
	if body then
		r.entity.health.health = body.health.health
		r.entity.health.lastHit = body.health.lastHit
	end
	-- Out of play as the body rises, until it bursts out (ReviveServer).
	if revive then
		r.entity.health.alive = false
	end
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
	local event = Entities.vitals(r.entity)
	event.kind = "spawn"
	Remotes.get().Combat:FireAllClients(event)
	for _, listener in PlayerSimServer.spawnListeners do
		listener(r.player)
	end
end

local function onPlayerAdded(player: Player)
	local hp = WeaponConfig.Health
	local r: Record
	local entity: Entities.Entity = {
		id = PlayerCodec.entityIdForUser(player.UserId),
		kind = "player",
		name = player.Name,
		player = player,
		health = Health.new(hp.maxHealth.value, WeaponConfig.DefaultShield),
		sim = nil,
		pose = function(): PlayerCodec.Pose?
			-- Out of play (Run it Back's body gone, system 33), nowhere.
			if not r.root or not r.alive or not r.entity.health.alive then
				return nil
			end
			-- Until the first move of this life has run, where it spawned.
			return r.shown or currentPose(r)
		end,
		onKilled = function(attacker: Entities.Entity?)
			r.alive = false
			InputQueue.clear(r.inputs)
			local humanoid = r.character and r.character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
			local by = if attacker and attacker.player ~= player then attacker else nil
			for _, listener in PlayerSimServer.deathListeners do
				listener(player, if by then by.player else nil, by)
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
		freshKit = false,
		kit = nil,
		kitShield = nil,
		spawnAskedAt = nil,
		behind = 0,
		revive = nil,
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

-- Debug loadout changes, 5 to 9 (Studio / place owner); in the arena, its
-- buy phase decides. The buy menu is ShopServer's. Asking for the spike
-- hands over the one there is, and in Studio asking for "ultimate" fills
-- the ultimate's points, so one can be checked in any mode.
local function onLoadout(player: Player, slot: any, id: any)
	local r = records[player]
	if not r or typeof(slot) ~= "number" or typeof(id) ~= "string" then
		return
	end
	if id == "ultimate" then
		if RunService:IsStudio() then
			AbilitySim.addPoints(r.sim.abilities, math.huge)
			PlayerSimServer.markDirty(player)
		end
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
	if id == Spike.ID then
		local spikeGive = PlayerSimServer.spikeGive
		if spikeGive then
			spikeGive(player)
		end
		return
	end
	PlayerSimServer.give(player, slot, id)
end

-- Puts a weapon in one of a player's slots with full ammo, drawn if it's the
-- slot in hand (the debug give and the buy menu), or with the rounds given (a
-- gun off the ground), or empties the primary or sidearm slot ("": a gun
-- sold back or dropped). Never the spike or an ultimate's weapon, which
-- come their own ways. Returns whether it did.
function PlayerSimServer.give(player: Player, slot: number, id: string, ammo: number?, reserve: number?): boolean
	local r = records[player]
	local def = WeaponConfig.Defs[id]
	local fits = if id == ""
		then slot == 1 or slot == 2
		else def ~= nil and def.slot == slot and not def.spike and not def.ultimate and not def.ability
	if not r or not fits then
		return false
	end
	WeaponSim.give(r.sim.weapons, slot, id, r.sim.movement.tick * DT, ammo, reserve)
	r.ackDirty = true
	return true
end

-- Where a player's eye is and the way it looks, as of their last move run
-- (the server's check of what they say they're looking at). Flying the Owl
-- Drone (system 47), the eye's the drone's middle.
function PlayerSimServer.view(player: Actor): (vector?, vector?)
	local r = records[player]
	if not r then
		local bots = PlayerSimServer.bots
		if bots then
			return bots.view(player)
		end
		return nil, nil
	end
	local kit = r.sim.abilities
	if AbilitySim.droning(kit) then
		return kit.dronePos, Accuracy.aim(r.yaw, r.pitch)
	end
	return PlayerSim.eye(r.sim, Tuning.config()), Accuracy.aim(r.yaw, r.pitch)
end

-- Gives a player the spike, in its slot and not drawn, or takes it from them
-- (SpikeServer, which keeps track of the one there is).
function PlayerSimServer.setSpike(player: Player, carry: boolean)
	local r = records[player]
	if not r then
		return
	end
	if carry then
		WeaponSim.give(r.sim.weapons, Spike.SLOT, Spike.ID)
	else
		SpikeSim.take(r.sim.spike, r.sim.weapons, r.sim.movement.tick * DT)
	end
	r.ackDirty = true
end

-- The weapon in one of a player's slots ("" for none), and the slot in hand.
function PlayerSimServer.holding(player: Player, slot: number): (string?, number?)
	local r = records[player]
	if not r then
		return nil, nil
	end
	local w = r.sim.weapons
	return w.loadout[slot], w.equipped
end

-- Reloads the gun in a living player's hand at once (deathmatch's kills and
-- health packs, system 26): `most` rounds at the most, or as many as fill
-- it (WeaponSim.reloadNow).
function PlayerSimServer.reloadInHand(player: Player, most: number?)
	local r = records[player]
	if not r or not r.alive then
		return
	end
	local w = r.sim.weapons
	WeaponSim.reloadNow(w, w.equipped, most)
	r.ackDirty = true
end

-- From the player's next life, a starting kit in place of whatever they
-- had, as a new match starts: `kit`'s weapons by slot and `shield` ("" for
-- none), or by default WeaponConfig.DefaultLoadout and DefaultShield.
function PlayerSimServer.resetKit(player: Player, kit: { string }?, shield: string?)
	local r = records[player]
	if r then
		r.freshKit = true
		r.kit = kit
		r.kitShield = shield
	end
end

-- A new life has been asked for (the arena spawns everyone as a round
-- starts); it starts when Roblox has loaded the character, and a bot's
-- body asked for before it (system 62) is forgotten.
function PlayerSimServer.expectSpawn(player: Player)
	local r = records[player]
	if r then
		r.spawnAskedAt = os.clock()
		r.takeover = nil
	end
end

-- A new life for a fallen player brought back by the Resurrection (system
-- 39), asked for at once: it starts on the floor under their body (`feet`)
-- as high as it's risen since the cast at server time `at`, facing `yaw`,
-- out of play and held until it bursts out (ReviveServer). It keeps the
-- last life's kit, whatever a death in the spike rounds took back for the
-- next round (startingKit), but with no shield.
function PlayerSimServer.revive(player: Player, feet: vector, yaw: number, at: number)
	local r = records[player]
	if not r then
		return
	end
	r.revive = { feet = feet, yaw = yaw, at = at }
	r.freshKit = false
	PlayerSimServer.expectSpawn(player)
	task.defer(function()
		if player.Parent and r.revive then
			player:LoadCharacterAsync()
		end
	end)
end

-- A return asked for that hasn't started given up (a new round): the next
-- life starts as any other.
function PlayerSimServer.forgetRevive(player: Player)
	local r = records[player]
	if r then
		r.revive = nil
	end
end

-- A new life for a fallen player in a bot's body (system 62), asked for at
-- once: as it starts, `take` hands the body over as it is then (Body) and
-- the life starts in it, in play at once; or says it's gone, and there's
-- no life. Any other life asked for before it starts (expectSpawn) is
-- that life instead.
function PlayerSimServer.takeOver(player: Player, take: () -> Body?)
	local r = records[player]
	if not r then
		return
	end
	PlayerSimServer.expectSpawn(player)
	r.takeover = take
	task.defer(function()
		if player.Parent and r.takeover == take then
			player:LoadCharacterAsync()
		elseif RunService:IsStudio() then
			print(string.format("[VF] takeover: %d's taken back, another life asked for first", player.UserId))
		end
	end)
end

-- A player taken out of play with no death (system 69, out of a match
-- while they stay in the server): the life under way, or one asked for,
-- ends, and the character goes, as before a first spawn.
function PlayerSimServer.unspawn(player: Player)
	local r = records[player]
	if not r then
		return
	end
	r.alive = false
	r.spawnAskedAt = nil
	r.revive = nil
	r.takeover = nil
	InputQueue.clear(r.inputs)
	local character = r.character
	r.character, r.root = nil, nil
	if player.Character then
		player.Character = nil
	end
	if character then
		character:Destroy()
	end
end

-- Whether a new life has been asked for and hasn't started yet.
function PlayerSimServer.spawnPending(player: Player): boolean
	local r = records[player]
	local at = if r then r.spawnAskedAt else nil
	return at ~= nil and os.clock() - at < PlayerSimServer.SPAWN_WAIT
end

-- Whether a player is alive and playing.
function PlayerSimServer.isAlive(player: Actor): boolean
	local r = records[player]
	if not r then
		local bots = PlayerSimServer.bots
		return bots ~= nil and bots.isAlive(player)
	end
	return r.alive and r.root ~= nil
end

-- Whether a player is alive, playing and in play: not out of it, as a
-- Phoenix whose body's gone in Run it Back is (system 33), still alive but
-- nowhere, who sees nothing and picks nothing up.
function PlayerSimServer.inPlay(player: Actor): boolean
	local r = records[player]
	if not r then
		local bots = PlayerSimServer.bots
		local entity = if bots and bots.isAlive(player) then bots.entityOf(player) else nil
		return entity ~= nil and entity.health.alive
	end
	return r.alive and r.root ~= nil and r.entity.health.alive
end

function PlayerSimServer.entityOf(player: Actor): Entities.Entity?
	local r = records[player]
	if not r then
		local bots = PlayerSimServer.bots
		return if bots then bots.entityOf(player) else nil
	end
	return r.entity
end

-- The actor an entity is: a player's, or a bot's stand-in (system 65); nil
-- for a dummy.
function PlayerSimServer.actorOf(entity: Entities.Entity): Actor?
	local player = entity.player
	if player then
		return player
	end
	local bots = PlayerSimServer.bots
	return if bots then bots.actorOf(entity) else nil
end

-- Every actor (system 65): each player, then each bot.
function PlayerSimServer.actors(): { Actor }
	local out: { Actor } = {}
	for _, player in Players:GetPlayers() do
		table.insert(out, player)
	end
	local bots = PlayerSimServer.bots
	if bots then
		for _, standIn in bots.list() do
			table.insert(out, standIn)
		end
	end
	return out
end

-- How many seconds a player's screen was behind the server when their last
-- move ran: the server's time then less the time their screen showed (the
-- input's viewTime). That's how long they go on moving, from where the
-- server has their eye, before their screen shows the server's present
-- (the fog of war looks from there too, FogOfWar.eyes).
function PlayerSimServer.behind(player: Player): number?
	local r = records[player]
	return if r then r.behind else nil
end

-- `objective` with the Soul Orb in `actor`'s reach from where `sim` has its
-- eye, if there's one (system 73): what a player's or a bot's tick is
-- given.
function PlayerSimServer.withSoul(actor: Actor, sim: PlayerSim.State, objective: Spike.Context?, cfg: MovementConfig.Values): Spike.Context?
	local soulOf = PlayerSimServer.soulOf
	local soul = if soulOf then soulOf(actor, PlayerSim.eye(sim, cfg)) else nil
	if soul == nil then
		return objective
	end
	local with = table.clone(objective or Spike.NONE)
	with.soul = soul
	return with
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
		r.behind = stepNow - input.viewTime
		r.buttons = input.buttons
		r.yaw = input.yaw
		r.pitch = math.clamp(input.pitch, -math.pi / 2, math.pi / 2)
		local objectiveFor = PlayerSimServer.objectiveFor
		local objective = if objectiveFor then objectiveFor(r.player) else nil
		objective = PlayerSimServer.withSoul(r.player, r.sim, objective, cfg)
		local judged = SlowSim.judged(input.viewTime, stepNow)
		local fieldsOf = PlayerSimServer.fields
		local slows = if fieldsOf then { fields = fieldsOf(), time = judged } else nil
		local wallsAt = PlayerSimServer.barriers
		local barriers = if wallsAt then wallsAt(judged) else nil
		local point, pointCheck = input.point, PlayerSimServer.pointCheck
		if point and pointCheck and not pointCheck(r.player, point) then
			input.point = nil
		end
		local shots, swing, act, dropped, casts = PlayerSim.step(r.sim, input, cfg, world, DT, objective, slows, barriers)
		-- Back at Run it Back's mark (system 33), gone to where Shrouded
		-- Step takes him (system 42), or a Shade where From the Shadows takes
		-- him or back where he was (system 43): the snapshots start over from
		-- there, so he's never shown, or hit, on the way.
		if casts then
			for _, cast in casts do
				if cast.kind == "rise" or cast.kind == "vanish" or cast.kind == "shade" or cast.kind == "home" then
					restartPacing(r)
				end
			end
		end
		MovePacer.push(r.pacer, input.seq * DT, currentPose(r))
		r.ackDirty = true
		if act then
			for _, listener in PlayerSimServer.spikeListeners do
				listener(r.player, act)
			end
		end
		if dropped then
			for _, listener in PlayerSimServer.dropListeners do
				listener(r.player, dropped, r.sim.movement.position, input.yaw)
			end
		end
		if casts then
			for _, cast in casts do
				for _, listener in PlayerSimServer.castListeners do
					listener(r.player, cast)
				end
			end
		end
		for _, listener in PlayerSimServer.tickListeners do
			listener(r.player, input, casts)
		end
		if shots then
			onShot(r.entity, shots, input.viewTime)
		end
		if swing then
			onSwing(r.entity, swing, input.viewTime)
		end
		return true
	end
	return false
end

-- One server frame: dt seconds since the last, ending at server time `now`
-- (the time this frame's snapshot carries).
function PlayerSimServer.step(dt: number, now: number)
	stepNow = now
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
		if r.ackDirty then
			r.ackDirty = false
			remotes.PlayerAck:FireClient(r.player, PlayerCodec.encodeAck(r.lastSeq, r.sim))
		end
	end
end

-- Marks a player's state as changed outside the input stream (damage slow,
-- loadout), so the owner gets a fresh ack and reconciles.
function PlayerSimServer.markDirty(player: Actor)
	local r = records[player]
	if r then
		r.ackDirty = true
	end
end

-- A player put somewhere else between their ticks (an enemy's hit breaking
-- Omen's Shade, system 43, sends him back): the snapshots start over from
-- there, and the owner gets a fresh ack.
function PlayerSimServer.moved(player: Actor)
	local r = records[player]
	if r then
		restartPacing(r)
		r.ackDirty = true
		return
	end
	local bots = PlayerSimServer.bots
	if bots then
		bots.moved(player)
	end
end

function PlayerSimServer.start(handler: ShotHandler, swingHandler: SwingHandler)
	onShot = handler
	onSwing = swingHandler
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

-- A player's ability kit, for AbilityServer to change between ticks
-- (markDirty after).
function PlayerSimServer.abilitiesOf(player: Actor): AbilitySim.State?
	local sim = PlayerSimServer.getSim(player)
	return if sim then sim.abilities else nil
end

-- The simulation time of a player's last move run.
function PlayerSimServer.timeOf(player: Actor): number?
	local sim = PlayerSimServer.getSim(player)
	return if sim then sim.movement.tick * DT else nil
end

-- Read access for other systems.
function PlayerSimServer.getSim(player: Actor): PlayerSim.State?
	local r = records[player]
	if not r then
		local bots = PlayerSimServer.bots
		return if bots then bots.getSim(player) else nil
	end
	return r.sim
end

return PlayerSimServer
