--!strict
-- Sova's Hunter's Fury on the server (system 46). Each blast (a "blast"
-- cast, as its windup ends in its owner's tick) is judged here at once, on
-- the server's clock: whom it catches (FurySim.caught), at the pose the
-- snapshots show (Entities), of everyone alive and in play but its owner
-- and his side, the practice dummies too, and on the course, with no
-- sides, everyone but its owner. Nothing stops it: the level, the clouds
-- and the walls all let it through. But while the spawns' barriers are up
-- (a buy phase, or Team Deathmatch's pre-game), with everyone held behind
-- them, it catches nobody (ours: one that crossed them would hurt enemies
-- before the round's begun).
--   * each one caught takes its damage, the same however far, through
--     their shield as any hit's, without slowing them, credited to its
--     owner as Hunter's Fury (CombatServer.blast); spawn protection keeps
--     it off
--   * and each one it leaves alive is revealed to its owner's side for a
--     moment, as a Recon Bolt's pulse reveals (ReconServer.reveal): their
--     minimap shows them, and so the fog of war sends them
-- Every client is told of the blast (the Ability remote's "blast"): where
-- its owner stood (studs, as any cast's), where it went from and the way it
-- went, for its beam and its sound; and its owner's side, its owner alone
-- on the course, whom it revealed and where they stood, so their clients
-- draw them through walls while it lasts (FuryView). Each owner's last
-- blast is their `VFLastFury` attribute (where it went from, metres), and
-- whom it caught their `VFFuryHits` (in the order of their names, "" for
-- nobody), which scripted checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local FurySim = require(Shared.Abilities.FurySim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local ReconServer = require(script.Parent.ReconServer)

local FuryServer = {}

local HF = AbilityConfig.HuntersFury

-- Whom a blast of `owner`'s (an entity id) can catch, with its owner on
-- `side` (nil with none): everyone alive and spawned but its owner, players
-- in play on another side and the dummies; with no sides, everyone but its
-- owner. Each one as FurySim sees them, and by id the pose the snapshots
-- show.
local function targetsFor(owner: number, side: number?): ({ FurySim.Target }, { [number]: PlayerCodec.Pose })
	local out: { FurySim.Target } = {}
	local poses: { [number]: PlayerCodec.Pose } = {}
	for id, entity in Entities.all() do
		if id == owner or not entity.health.alive then
			continue
		end
		local player = entity.player
		if player then
			if not (PlayerSimServer.inPlay(player) and PlayerSimServer.isAlive(player)) then
				continue
			end
			if side ~= nil and player:GetAttribute(ArenaConfig.SIDE) == side then
				continue
			end
		end
		local pose = entity.pose()
		if pose and pose.alive then
			table.insert(out, FurySim.target(id, pose))
			poses[id] = pose
		end
	end
	return out, poses
end

-- Whether the spawns' barriers are up: the arena's buy phase, or Team
-- Deathmatch's pre-game.
local function held(): boolean
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return false
	end
	local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
	local phase = if arena then arena:GetAttribute("Phase") else nil
	return phase == "buy" or phase == "pregame"
end

local function onCast(player: Player, cast: AbilitySim.Cast)
	if cast.kind ~= "blast" or cast.ability ~= "huntersfury" then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local sideOf = player:GetAttribute(ArenaConfig.SIDE)
	local side = if typeof(sideOf) == "number" then sideOf else nil
	local targets, posed = targetsFor(entity.id, side)
	if held() then
		targets = {}
	end
	local protected = CombatServer.protected
	local ids, poses, names = {}, {}, {}
	for _, hit in FurySim.caught(cast.origin, cast.direction, targets) do
		local victim = Entities.get(hit.id)
		if not victim or (protected and protected(victim)) then
			continue
		end
		CombatServer.blast(entity, victim, HF.damage.value, FurySim.WEAPON, cast.origin)
		table.insert(names, victim.name)
		if not victim.health.alive then
			continue
		end
		if side ~= nil then
			ReconServer.reveal(side, hit.id, now + HF.reveal.value)
		end
		local pose = posed[hit.id]
		table.insert(ids, hit.id)
		table.insert(poses, { id = hit.id, position = Units.asVector3(pose.position), yaw = pose.yaw, crouch = pose.crouchAlpha })
	end
	local heard: { [string]: any } = {
		entity = entity.id,
		ability = cast.ability,
		kind = "blast",
		id = cast.tick,
		at = now,
		position = Units.toStuds(cast.position),
		origin = Units.asVector3(cast.origin),
		direction = Units.asVector3(cast.direction),
	}
	local told = table.clone(heard)
	told.ids = ids
	told.poses = poses
	local remote = Remotes.get().Ability
	for _, other in Players:GetPlayers() do
		local ours = if side == nil then other == player else other:GetAttribute(ArenaConfig.SIDE) == side
		remote:FireClient(other, if ours then told else heard)
	end
	if player.Parent then
		table.sort(names)
		player:SetAttribute(FurySim.POINT_ATTRIBUTE, Units.asVector3(cast.origin))
		player:SetAttribute(FurySim.HITS_ATTRIBUTE, table.concat(names, ","))
	end
end

function FuryServer.start()
	table.insert(PlayerSimServer.castListeners, onCast)
end

return FuryServer
