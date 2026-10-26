--!strict
-- The fog of war on the server (system 35): what each player's snapshots
-- carry (Replication), and so what their client draws and hears. The
-- reference's server "withholds information about the positions of enemies
-- until a client needs to display it" (Riot); FogOfWar has the rules.
--
-- Twenty times a second each player in play on a side takes a look
-- (FogOfWar.look), the looks spread over the frames between: from where the
-- server last had their eye (PlayerSimServer.view), moving as their
-- simulation is, at every other entity as the snapshots show it (Entities).
-- In the way is what bodies don't go through, but not the spawns'
-- barriers, which are see-through. What their side spots (MinimapServer)
-- is in too, so their minimap can show it. A player who's down has what
-- their side in play has, so whoever they watch (Spectate) is drawn with
-- what that teammate sees and hears; a player on no side (the course,
-- waiting in line) has everyone; and one coming back to life in deathmatch
-- has everyone for a moment, for the minimap's pulse.
--
-- Events that say where someone is go only to those who'd hear them or
-- have that someone in their snapshots (FogServer.hears): a gunshot, a
-- knife's swing, an ability's cast. And a shot's or a swing's verdict lists
-- only the targets near it the shooter has (FogServer.shows), so a miss
-- past someone behind a wall says nothing of where they are.
--
-- Workspace's `VFFogOff` attribute, true, turns it off (everyone has
-- everyone), to compare. What its looks cost goes on Workspace once a
-- second: `VFFogLines`, the lines they cast in it, and `VFFogMs`, the
-- milliseconds of server time they took.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local FogOfWar = require(Shared.Combat.FogOfWar)
local Minimap = require(Shared.Match.Minimap)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local Tuning = require(script.Parent.Tuning)

local FogServer = {}

FogServer.OFF = "VFFogOff"
FogServer.LINES = "VFFogLines"
FogServer.MS = "VFFogMs"

local P = FogOfWar.Params
-- How many barriers one line goes through at the most.
local PASSES = 4

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = RobloxWorld.CHARACTER_GROUP
params.RespectCanCollide = true

local state = FogOfWar.new()
local spreads = Random.new()
local nextAt: { [Player]: number } = {}
local revealUntil: { [Player]: number } = {}
-- What each side spots, by side, from the minimap's last look.
local spotted: { [number]: { [number]: boolean } } = {}

-- This frame's, from FogServer.step: each player's side by entity id, those
-- on each side in play and their eyes, and whether it's off.
local frameNow = 0
local off = false
-- The looks' cost since the second began: lines cast and seconds taken.
local costFrom = 0
local costLines = 0
local costTime = 0
local sideOf: { [number]: number } = {}
local inPlayBySide: { [number]: { FogOfWar.Who } } = {}
local earsBySide: { [number]: { vector } } = {}

-- Whether the level is in the way from `a` to `b` (metres): what bodies go
-- through is, and the barriers aren't. Sage's Healing Orb looks for an
-- ally in sight past it too (system 36).
local function blocked(a: vector, b: vector): boolean
	local from = Units.toStuds(a)
	local along = Units.toStuds(b) - from
	for _ = 1, PASSES do
		local hit = Workspace:Raycast(from, along, params)
		if not hit then
			return false
		end
		if hit.Instance.Name ~= Minimap.BARRIER then
			return true
		end
		params:AddToFilter(hit.Instance)
	end
	return true
end
FogServer.blocked = blocked

-- Every entity the snapshots show, where they show it, with its side and
-- velocity.
local function gather(): { FogOfWar.Target }
	local out: { FogOfWar.Target } = {}
	for id, entity in Entities.all() do
		local pose = entity.pose()
		if pose then
			local sim = entity.sim
			table.insert(out, { id = id, side = sideOf[id], pose = pose, velocity = if sim then sim.movement.velocity else vector.zero })
		end
	end
	return out
end

-- A player in play as a viewer: their eye, its velocity and their eye stood
-- up, and how far behind the server their screen is.
local function viewerOf(player: Player, id: number, side: number): FogOfWar.Viewer?
	local eye = PlayerSimServer.view(player)
	local sim = PlayerSimServer.getSim(player)
	if not eye or not sim then
		return nil
	end
	local m = sim.movement
	return {
		id = id,
		side = side,
		eye = eye,
		velocity = m.velocity,
		standEye = m.position + vector.create(0, Tuning.config().standEyeHeight, 0),
		behind = PlayerSimServer.behind(player) or 0,
	}
end

-- What each side spots, from the minimap's look (MinimapServer).
function FogServer.spotted(bySide: { [number]: { [number]: boolean } })
	spotted = bySide
end

-- Each player in play on a side whose look is due takes it.
function FogServer.step(now: number)
	frameNow = now
	off = Workspace:GetAttribute(FogServer.OFF) == true
	table.clear(sideOf)
	table.clear(inPlayBySide)
	table.clear(earsBySide)
	local due: { { player: Player, viewer: FogOfWar.Viewer } } = {}
	for _, player in Players:GetPlayers() do
		local side = player:GetAttribute(ArenaConfig.SIDE)
		local entity = PlayerSimServer.entityOf(player)
		if not entity or typeof(side) ~= "number" then
			continue
		end
		sideOf[entity.id] = side
		local viewer = if PlayerSimServer.inPlay(player) then viewerOf(player, entity.id, side) else nil
		if not viewer then
			continue
		end
		local mates = inPlayBySide[side] or {}
		inPlayBySide[side] = mates
		table.insert(mates, { id = entity.id, side = side })
		local ears = earsBySide[side] or {}
		earsBySide[side] = ears
		table.insert(ears, viewer.eye)
		-- Each player's looks start somewhere in the first interval, so
		-- they're spread over its frames.
		local at = nextAt[player] or now + spreads:NextNumber() * P.every.value
		if now >= at then
			at += P.every.value
			if at <= now then
				at = now + P.every.value
			end
			table.insert(due, { player = player, viewer = viewer })
		end
		nextAt[player] = at
	end
	if not off and #due > 0 then
		local began = os.clock()
		local targets = gather()
		for _, look in due do
			costLines += FogOfWar.look(state, now, look.viewer, targets, blocked, spotted[look.viewer.side :: number])
		end
		costTime += os.clock() - began
	end
	if now - costFrom >= 1 then
		Workspace:SetAttribute(FogServer.LINES, costLines)
		Workspace:SetAttribute(FogServer.MS, math.round(costTime * 1e4) / 10)
		costFrom = now
		costLines = 0
		costTime = 0
	end
end

-- What `player`'s snapshot carries now: nil for everyone, or a test of
-- each entity id.
function FogServer.sendsTo(player: Player): ((id: number) -> boolean)?
	if off then
		return nil
	end
	local entity = PlayerSimServer.entityOf(player)
	local side = player:GetAttribute(ArenaConfig.SIDE)
	if not entity or typeof(side) ~= "number" or (revealUntil[player] or -math.huge) > frameNow then
		return nil
	end
	local me: FogOfWar.Who = { id = entity.id, side = side }
	local inPlay = PlayerSimServer.inPlay(player)
	local mates = inPlayBySide[side] or {}
	local seen = spotted[side]
	return function(id: number): boolean
		local them: FogOfWar.Who = { id = id, side = sideOf[id] }
		if FogOfWar.always(me, them) or (seen ~= nil and seen[id] == true) then
			return true
		end
		return if inPlay then FogOfWar.shows(state, frameNow, me, them) else FogOfWar.anyShows(state, frameNow, mates, them)
	end
end

-- Whether `id` is in `player`'s snapshots.
function FogServer.shows(player: Player, id: number): boolean
	local test = FogServer.sendsTo(player)
	return test == nil or test(id)
end

-- Whether `player` is told of a sound of entity `source`'s at `at`
-- (metres), heard out to `radius`: always, unless the source is an enemy
-- they don't have in their snapshots; then if they're near enough to hear
-- it, or, while they're down, anyone on their side in play is.
function FogServer.hears(player: Player, at: vector, radius: number, source: number): boolean
	local test = FogServer.sendsTo(player)
	if test == nil or test(source) then
		return true
	end
	local reach = radius + P.hearing.value
	local ears: { vector } = {}
	if PlayerSimServer.inPlay(player) then
		local eye = PlayerSimServer.view(player)
		if eye then
			table.insert(ears, eye)
		end
	else
		local side = player:GetAttribute(ArenaConfig.SIDE)
		ears = if typeof(side) == "number" then earsBySide[side] or {} else {}
	end
	for _, ear in ears do
		if vector.magnitude(ear - at) <= reach then
			return true
		end
	end
	return false
end

function FogServer.start()
	-- Deathmatch's pulse as you come back to life: everyone, for a moment.
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		if Workspace:GetAttribute(ArenaConfig.MODE) == "deathmatch" then
			revealUntil[player] = Workspace:GetServerTimeNow() + P.reveal.value
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		nextAt[player] = nil
		revealUntil[player] = nil
		FogOfWar.forget(state, PlayerCodec.entityIdForUser(player.UserId))
	end)
end

return FogServer
