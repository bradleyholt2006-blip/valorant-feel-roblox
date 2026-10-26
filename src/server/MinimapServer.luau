--!strict
-- The minimap's spotting on the server (system 34). Twenty times a second
-- (Minimap.Params.sightEvery) it looks at who each side sees: an enemy is on
-- your minimap while anyone on your side has them in view (Sight.spotted),
-- and a dropped spike is on the defenders' while any of them has it in view
-- (Minimap.spikeShown). Each player on a side is told what theirs sees as
-- it changes (the Sight remote: the entity ids of the enemies seen, and
-- whether the spike on the ground is), dead or alive, so a minimap goes on
-- showing it while they spectate.
--
-- Everyone in play looks from where the server last had their eye and view
-- (PlayerSimServer.view) and is seen at the pose the snapshots show
-- (Entities). Nobody out of play sees or is seen (a Phoenix whose body's
-- gone in Run it Back, system 33), and nobody blinded white by a Curveball
-- (system 30) sees. In the way: the level, but not the spawns' barriers,
-- which are see-through, nor anyone's body; the clouds standing
-- (CloudServer) and the walls of fire (BlazeServer).
--
-- The snapshots still carry every pose to every client; keeping from each
-- what its side can't see (the reference's fog of war) is work of its own.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local FlareSim = require(Shared.Abilities.FlareSim)
local Minimap = require(Shared.Match.Minimap)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local Sight = require(Shared.Combat.Sight)
local Spike = require(Shared.Spike.Spike)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CloudServer = require(script.Parent.CloudServer)
local BlazeServer = require(script.Parent.BlazeServer)

local MinimapServer = {}

-- How many barriers one line of sight goes through at the most.
local PASSES = 4
-- How high over the spike's spot on the floor it's looked at, metres.
local SPIKE_LIFT = 0.15

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = RobloxWorld.CHARACTER_GROUP
params.RespectCanCollide = true

local nextAt = 0
-- What each player was last told, as a key: the ids, and the spike.
local sent: { [Player]: string } = {}

-- Whether the level is in the way from `a` to `b` (metres): what bodies go
-- through is, and the barriers aren't.
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

-- Whether a player is white enough with a blind at `now` to see nobody.
local function blinded(player: Player, now: number): boolean
	local blind = FlareSim.decode(player:GetAttribute(FlareSim.BLIND_ATTRIBUTE))
	return blind ~= nil and FlareSim.whiteAt(blind, now) >= Minimap.Params.blindSees.value
end

local function tell(player: Player, ids: { number }, spike: boolean)
	table.sort(ids)
	local key = table.concat(ids, ",") .. (if spike then ";spike" else "")
	if sent[player] == key then
		return
	end
	sent[player] = key
	Remotes.get().Sight:FireClient(player, { ids = ids, spike = spike })
end

-- Who each side sees now, and whether the defenders see the spike on the
-- ground; then each player is told what changed for them.
local function look(now: number)
	local viewers: { Sight.Viewer } = {}
	local targets: { Sight.Target } = {}
	local sides: { [Player]: number } = {}
	for _, player in Players:GetPlayers() do
		local side = player:GetAttribute(ArenaConfig.SIDE)
		if typeof(side) ~= "number" then
			continue
		end
		sides[player] = side
		if not PlayerSimServer.inPlay(player) then
			continue
		end
		local entity = PlayerSimServer.entityOf(player)
		local pose = if entity then entity.pose() else nil
		if entity and pose then
			table.insert(targets, { id = entity.id, side = side, points = Sight.points(pose) })
		end
		local eye, aim = PlayerSimServer.view(player)
		if eye and aim and not blinded(player, now) then
			table.insert(viewers, { side = side, eye = eye, look = aim })
		end
	end
	local o: Sight.Occluders = {
		clouds = CloudServer.standing(now),
		walls = BlazeServer.standing(now),
		time = now,
		blocked = blocked,
	}
	local spotted = Sight.spotted(viewers, targets, o)
	-- A dropped spike, for the spike rounds' defenders (a side's number;
	-- on the course anyone defuses, 0, and nobody's told).
	local defenders = Workspace:GetAttribute(Spike.DEFUSERS)
	local at = Workspace:GetAttribute(Spike.POSITION)
	local spikeSeen = false
	if
		Workspace:GetAttribute(Spike.STATE) == "dropped"
		and typeof(defenders) == "number"
		and defenders ~= 0
		and typeof(at) == "Vector3"
	then
		spikeSeen = Sight.sideSees(viewers, defenders, Units.asVector(at) + vector.create(0, SPIKE_LIFT, 0), o)
	end
	for _, player in Players:GetPlayers() do
		local side = sides[player]
		if side == nil then
			if sent[player] ~= nil and sent[player] ~= "" then
				tell(player, {}, false)
			end
			continue
		end
		local ids = {}
		local seen = spotted[side]
		if seen then
			for id in seen do
				table.insert(ids, id)
			end
		end
		tell(player, ids, side == defenders and spikeSeen)
	end
end

function MinimapServer.step(now: number)
	if now < nextAt then
		return
	end
	local every = Minimap.Params.sightEvery.value
	-- On from this look, or from now after a stall.
	nextAt += every
	if nextAt <= now then
		nextAt = now + every
	end
	look(now)
end

function MinimapServer.start()
	Players.PlayerRemoving:Connect(function(player)
		sent[player] = nil
	end)
end

return MinimapServer
