--!strict
-- Sova's Recon Bolt on the server (system 44). Each bolt loosed (a "bolt"
-- cast of the Recon Bolt's) flies here through BoltSim at once, through
-- the level, as nothing changes its path after the loose, and sticks where
-- it lands, on the server's clock. Every client is told of the loose (the
-- Ability remote's "flight"): its keys, how long after the loose it
-- sticks, where, and the way the surface there faces, so each draws it the
-- same way.
--
-- Stuck, it winds up and pulses (BoltSim.pulseAt), on through its owner's
-- death. Each pulse reveals every enemy in play within its radius it has
-- in sight (BoltSim.reveals), at the pose the snapshots show (Entities):
-- players on another side than its owner's and the practice dummies, and
-- on the course, with no sides, everyone but its owner. In the way: the
-- level, but not the spawns' barriers (FogServer.blocked), the clouds
-- standing (CloudServer), the walls of fire (BlazeServer) and the walls of
-- ice (BarrierServer), as for anyone's eye (Sight). Every client hears of
-- the pulse ("pulse"), and its owner's side, its owner alone on the
-- course, is told whom it revealed and where they stood, so their clients
-- draw their silhouettes through walls while the reveal lasts (ReconView);
-- for as long, that side's minimap shows them, and so the fog of war sends
-- them (ReconServer.revealed, MinimapServer), as it does whom Hunter's
-- Fury's blasts reveal (ReconServer.reveal, system 46).
--
-- Stuck, its shaft stands in the level shots and swings are traced
-- through, as the attacker's screen showed it (CombatServer.levelAt): a
-- bullet or a knife of its owner's enemies that strikes it takes its
-- damage off the bolt's health, and at none it breaks ("break") and pulses
-- no more; its owner's side's do nothing (Patch 5.12: 'The following
-- abilities are now immune to allied damage.'). On the course,
-- with no sides, anyone's does, its owner's too, so it can be tried alone.
-- A bolt is kept for shots that come in late until SlowSim.LAG after its
-- time's up. They all go with a new round (Arena), which every client
-- hears of from FireServer.clear's "out". Each owner's last bolt is their
-- `VFLastBolt` attribute (where it stuck, metres), the names its last pulse
-- revealed their `VFLastRecon` (in order, and "" for nobody) and the health
-- it has left their `VFBoltHealth`, which scripted checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local BoltSim = require(Shared.Abilities.BoltSim)
local SlowSim = require(Shared.Abilities.SlowSim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local Penetration = require(Shared.Combat.Penetration)
local Sight = require(Shared.Combat.Sight)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local CloudServer = require(script.Parent.CloudServer)
local BlazeServer = require(script.Parent.BlazeServer)
local BarrierServer = require(script.Parent.BarrierServer)
local FogServer = require(script.Parent.FogServer)

local ReconServer = {}

local RC = AbilityConfig.ReconBolt
local DT = 1 / MovementConfig.TickRate.value
local world = RobloxWorld.new()

-- A bolt stuck in play: whose, and their side (nil on the course), its
-- health, how many pulses it's given, and whether its owner's been told
-- it's stuck.
type Kept = {
	player: PlayerSimServer.Actor,
	side: number?,
	stuck: BoltSim.Stuck,
	health: number,
	pulsed: number,
	told: boolean,
}

local kept: { Kept } = {}
local keptOf: { [BoltSim.Stuck]: Kept } = {}
-- The bolts kept, for the shots.
local bolts: { BoltSim.Stuck } = {}
-- Whom the pulses have revealed to each side, by entity id, and until
-- when (server time).
local revealedTo: { [number]: { [number]: number } } = {}

local function onCast(player: PlayerSimServer.Actor, cast: AbilitySim.Cast)
	if cast.kind ~= "bolt" or cast.ability ~= "reconbolt" then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	local bolt = BoltSim.shoot(entity.id, cast.tick, cast.origin, cast.direction, cast.bars or 0, cast.bounces or 0)
	local landed = BoltSim.fly(bolt, DT, world)
	local now = Workspace:GetServerTimeNow()
	local keys = {}
	for _, key in bolt.keys do
		table.insert(keys, {
			age = key.age,
			position = Units.asVector3(key.position),
			velocity = Units.asVector3(key.velocity),
			gravity = key.gravity,
		})
	end
	local event: { [string]: any } = {
		entity = entity.id,
		ability = cast.ability,
		kind = "flight",
		id = cast.tick,
		at = now,
		keys = keys,
		land = landed,
	}
	local normal = bolt.normal
	if landed and normal then
		event.point = Units.asVector3(bolt.position)
		event.normal = Units.asVector3(normal)
		local side = player:GetAttribute(ArenaConfig.SIDE)
		local stuck = BoltSim.stuck(entity.id, cast.tick, bolt.position, normal, now + landed)
		local k: Kept = {
			player = player,
			side = if typeof(side) == "number" then side else nil,
			stuck = stuck,
			health = RC.health.value,
			pulsed = 0,
			told = false,
		}
		table.insert(kept, k)
		keptOf[stuck] = k
		table.insert(bolts, stuck)
	end
	Remotes.get().Ability:FireAllClients(event)
end

-- Whom a bolt of `k`'s can reveal: everyone alive and spawned, players and
-- bots in play on another side than its owner's and the dummies, on none;
-- with no sides, everyone but its owner. Each one's entity id and the points of
-- them that count, and by id the pose the snapshots show.
local function targetsFor(k: Kept): ({ BoltSim.Target }, { [number]: PlayerCodec.Pose })
	local out: { BoltSim.Target } = {}
	local poses: { [number]: PlayerCodec.Pose } = {}
	for id, entity in Entities.all() do
		if id == k.stuck.owner or not entity.health.alive then
			continue
		end
		local actor = PlayerSimServer.actorOf(entity)
		if actor then
			if not PlayerSimServer.inPlay(actor) then
				continue
			end
			if k.side ~= nil and actor:GetAttribute(ArenaConfig.SIDE) == k.side then
				continue
			end
		end
		local pose = entity.pose()
		if pose and pose.alive then
			table.insert(out, { id = id, points = Sight.points(pose) })
			poses[id] = pose
		end
	end
	return out, poses
end

-- `id` (an entity) revealed to `side` until `untilAt` (server time): by a
-- pulse, or a blast of Hunter's Fury's (system 46, FuryServer).
function ReconServer.reveal(side: number, id: number, untilAt: number)
	local to = revealedTo[side] or {}
	revealedTo[side] = to
	to[id] = math.max(to[id] or 0, untilAt)
end

-- A pulse of `k`'s bolt at `now`: whom it reveals, told to its owner's
-- side, and the pulse itself to everyone else.
local function pulse(k: Kept, now: number)
	local s = k.stuck
	k.pulsed += 1
	local o: Sight.Occluders = {
		clouds = CloudServer.standing(now),
		walls = BlazeServer.standing(now),
		barriers = BarrierServer.standing(),
		time = now,
		blocked = FogServer.blocked,
	}
	local targets, posed = targetsFor(k)
	local ids = BoltSim.reveals(s, targets, function(a: vector, b: vector): boolean
		return Sight.hidden(a, b, o)
	end)
	local names, poses = {}, {}
	for _, id in ids do
		local entity = Entities.get(id)
		if entity then
			table.insert(names, entity.name)
		end
		local pose = posed[id]
		table.insert(poses, { id = id, position = Units.asVector3(pose.position), yaw = pose.yaw, crouch = pose.crouchAlpha })
		local side = k.side
		if side ~= nil then
			ReconServer.reveal(side, id, now + RC.reveal.value)
		end
	end
	if k.player.Parent then
		table.sort(names)
		k.player:SetAttribute(BoltSim.REVEALED_ATTRIBUTE, table.concat(names, ","))
	end
	local heard: { [string]: any } = {
		entity = s.owner,
		ability = "reconbolt",
		kind = "pulse",
		id = s.id,
		at = now,
		index = k.pulsed,
		point = Units.asVector3(BoltSim.eye(s)),
	}
	local told = table.clone(heard)
	told.ids = ids
	told.poses = poses
	local remote = Remotes.get().Ability
	for _, player in Players:GetPlayers() do
		local ours = if k.side == nil then player == k.player else player:GetAttribute(ArenaConfig.SIDE) == k.side
		remote:FireClient(player, if ours then told else heard)
	end
end

-- Whether `attacker`'s bullets and knives break a bolt of `owner`'s (an
-- entity id): its owner's enemies' do, and with no sides (the course)
-- anyone's, its owner's too. One whose owner's gone breaks to anyone.
local function breaks(attacker: Entities.Entity, owner: number): boolean
	local entity = Entities.get(owner)
	return entity == nil or not CombatServer.teammates(attacker, entity)
end

-- A bullet or a knife of `attacker`'s that struck a bolt's shaft (`key`,
-- its piece), for `amount`: the bolt takes it, and at nothing breaks.
local function struck(attacker: Entities.Entity, key: any, amount: number)
	local piece = BoltSim.piece(key)
	if not piece or amount <= 0 then
		return
	end
	local s = piece.stuck
	local k = keptOf[s]
	local now = Workspace:GetServerTimeNow()
	if not k or s.broken ~= nil or now >= BoltSim.ends(s) or not breaks(attacker, s.owner) then
		return
	end
	k.health = math.max(k.health - amount, 0)
	if k.player.Parent then
		k.player:SetAttribute(BoltSim.HEALTH_ATTRIBUTE, k.health)
	end
	if k.health <= 0 then
		s.broken = now
		Remotes.get().Ability:FireAllClients({
			entity = s.owner,
			ability = "reconbolt",
			kind = "break",
			id = s.id,
			at = now,
			point = Units.asVector3(s.point),
		})
	end
end

-- Once a server frame, at server time `now`: the bolts that have stuck
-- told of, the pulses due given, the bolts long gone forgotten, and the
-- reveals that are over gone.
function ReconServer.step(now: number)
	local gone = false
	for i = #kept, 1, -1 do
		local k = kept[i]
		local s = k.stuck
		if not k.told and now >= s.stuck then
			k.told = true
			if k.player.Parent then
				k.player:SetAttribute(BoltSim.STUCK_ATTRIBUTE, Units.asVector3(s.point))
				k.player:SetAttribute(BoltSim.HEALTH_ATTRIBUTE, k.health)
			end
		end
		while s.broken == nil and k.pulsed < RC.pulses.value and now >= BoltSim.pulseAt(s, k.pulsed + 1) and now < BoltSim.ends(s) do
			pulse(k, now)
		end
		if now >= BoltSim.ends(s) + SlowSim.LAG then
			table.remove(kept, i)
			keptOf[s] = nil
			gone = true
		end
	end
	if gone then
		table.clear(bolts)
		for _, k in kept do
			table.insert(bolts, k.stuck)
		end
	end
	for side, ids in revealedTo do
		for id, untilAt in ids do
			if now >= untilAt then
				ids[id] = nil
			end
		end
		if next(ids) == nil then
			revealedTo[side] = nil
		end
	end
end

-- Whom the pulses reveal to each side at `now`, by entity id, as
-- Sight.spotted has it: on that side's minimap, and so in its snapshots
-- (MinimapServer).
function ReconServer.revealed(now: number): { [number]: { [number]: boolean } }
	local out: { [number]: { [number]: boolean } } = {}
	for side, ids in revealedTo do
		for id, untilAt in ids do
			if now < untilAt then
				local seen = out[side] or {}
				out[side] = seen
				seen[id] = true
			end
		end
	end
	return out
end

-- Every bolt gone (a new round), and every reveal. FireServer.clear tells
-- every client.
function ReconServer.clear()
	table.clear(kept)
	table.clear(keptOf)
	table.clear(bolts)
	table.clear(revealedTo)
end

-- After BarrierServer's start, whose walls are in the level shots are
-- traced through first.
function ReconServer.start()
	table.insert(PlayerSimServer.castListeners, onCast)
	local levelBefore = CombatServer.levelAt
	CombatServer.levelAt = function(base: Penetration.Level, viewTime: number): Penetration.Level
		local level = if levelBefore then levelBefore(base, viewTime) else base
		return BoltSim.level(level, bolts, SlowSim.judged(viewTime, Workspace:GetServerTimeNow()))
	end
	local struckBefore = CombatServer.struck
	CombatServer.struck = function(attacker: Entities.Entity, key: any, amount: number)
		if BoltSim.piece(key) then
			struck(attacker, key, amount)
		elseif struckBefore then
			struckBefore(attacker, key, amount)
		end
	end
end

return ReconServer
