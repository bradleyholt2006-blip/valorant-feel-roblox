--!strict
-- Pings on the server (system 52, Pings). A client asks with the Ping
-- remote: Z's ping along the crosshair (`look`, with the wheel's option if
-- one was picked, the look it was made with and the time its screen showed,
-- its viewTime), or a place on the big map (`map`, a point in metres).
--
-- One along the crosshair is the living's alone. It's judged from where the
-- server last had the player's eye (PlayerSimServer.view), along the look it
-- came with if that's near the server's last (Pings.aimFrom), as far as the
-- level lets it go as the screen showed it, Sage's walls and all
-- (CombatServer.levelFor, as for a shot), through the spawns' barriers,
-- which are see-through, and no further than the first cloud or smoke's edge
-- (CloudServer). It marks an enemy whose body it passes close to, posed as
-- the screen showed them (CombatServer.rewound, as for a shot) and in sight
-- past the level, the clouds and the walls of fire and of ice; the spike on
-- the ground; a gun on the ground (GroundGunsServer); or the place it stops
-- (Pings.resolve). One on the map is anyone's, dead or alive, at a point on
-- the map being played (Minimap.holds), and it shows nowhere but the maps.
-- Each asked for spends one of the player's pings (Pings.spend), whatever it
-- marks, and with none left nothing's pinged.
--
-- A ping goes to the pinger's side, the pinger too: everyone with the same
-- ArenaConfig.SIDE. Without a side (the course), only to the pinger.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Accuracy = require(Shared.Weapons.Accuracy)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local GroundGuns = require(Shared.Weapons.GroundGuns)
local Minimap = require(Shared.Match.Minimap)
local PartsPlan = require(Shared.Match.PartsPlan)
local Pings = require(Shared.Match.Pings)
local Remotes = require(Shared.Net.Remotes)
local Sight = require(Shared.Combat.Sight)
local Spike = require(Shared.Spike.Spike)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local CloudServer = require(script.Parent.CloudServer)
local BlazeServer = require(script.Parent.BlazeServer)
local BarrierServer = require(script.Parent.BarrierServer)
local FogServer = require(script.Parent.FogServer)
local GroundGunsServer = require(script.Parent.GroundGunsServer)

local PingServer = {}

-- How many barriers a ping goes through at the most.
local PASSES = 4
-- How high over its spot on the floor the spike's middle is, as the
-- minimap's spotting has it (MinimapServer).
local SPIKE_LIFT = 0.15

local budgets: { [Player]: Pings.Budget } = {}
local lastId = 0

-- How far along `look` from `eye` (metres) the level is as a screen showed
-- it at `time`, Sage's walls in it as for a shot (CombatServer.levelFor),
-- through the spawns' barriers; nil for nothing within `most`.
local function levelAlong(eye: vector, look: vector, most: number, time: number): number?
	local level = CombatServer.levelFor(time)
	local skip: { any } = {}
	for _ = 1, PASSES do
		local hit = level:cast(eye, look, most, skip)
		if not hit then
			return nil
		end
		local key = hit.key
		if typeof(key) ~= "Instance" or key.Name ~= Minimap.BARRIER then
			return hit.distance
		end
		table.insert(skip, key)
	end
	return nil
end

-- The map being played, if any.
local function planNow(): Minimap.Plan?
	local model = Workspace:FindFirstChild(ArenaConfig.MODEL)
	if not model or Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return nil
	end
	-- The 1v1 map's (system 64) is drawn from its parts.
	return PartsPlan.inPlay()
end

-- What's on the ground to ping: the spike, dropped or planted, and the guns.
local function items(): { Pings.Item }
	local out: { Pings.Item } = {}
	local state = Workspace:GetAttribute(Spike.STATE)
	local at = Workspace:GetAttribute(Spike.POSITION)
	if (state == "dropped" or state == "planted") and typeof(at) == "Vector3" then
		table.insert(out, { kind = "spike", middle = Units.asVector(at) + vector.create(0, SPIKE_LIFT, 0) })
	end
	for id, gun in GroundGunsServer.guns() do
		table.insert(out, { kind = "gun", id = id, weapon = gun.weapon, middle = gun.position + GroundGuns.CENTRE })
	end
	return out
end

-- What `player`'s ping along `claimed` (a look) marks, with the wheel's
-- `option`, as their screen showed things at `viewTime`.
local function along(player: Player, claimed: vector, option: string?, viewTime: number): Pings.Ping?
	local entity = PlayerSimServer.entityOf(player)
	local eye, own = PlayerSimServer.view(player)
	if not entity or not eye or not own then
		return nil
	end
	local look = Pings.aimFrom(own, claimed)
	local rewound, time = CombatServer.rewound(entity, viewTime, function(other: Entities.Entity): boolean
		return not CombatServer.teammates(entity, other)
	end)
	local enemies: { Pings.Body } = {}
	for _, t in rewound do
		table.insert(enemies, { id = t.id, pose = { position = t.pose.position, yaw = t.pose.yaw, crouchAlpha = t.pose.crouchAlpha } })
	end
	local clouds = CloudServer.standing(time)
	local o: Sight.Occluders = {
		clouds = clouds,
		walls = BlazeServer.standing(time),
		barriers = BarrierServer.standing(),
		time = time,
		blocked = FogServer.blocked,
	}
	return Pings.resolve({
		eye = eye,
		look = look,
		level = levelAlong(eye, look, Pings.Params.reach.value, time),
		clouds = clouds,
		enemies = enemies,
		items = items(),
		hidden = function(a: vector, b: vector): boolean
			return Sight.hidden(a, b, o)
		end,
		option = option,
	})
end

-- Spends one of `player`'s pings, if they have one.
local function spend(player: Player, now: number): boolean
	local budget = budgets[player]
	if not budget then
		budget = Pings.newBudget(now)
		budgets[player] = budget
	end
	return Pings.spend(budget, now)
end

-- A ping of `player`'s, to their side.
local function send(player: Player, ping: Pings.Ping)
	lastId += 1
	local entity = PlayerSimServer.entityOf(player)
	local event = {
		id = lastId,
		kind = ping.kind,
		option = ping.option,
		position = Units.asVector3(ping.position),
		entity = if entity then entity.id else 0,
		target = ping.target,
		weapon = ping.weapon,
	}
	local side = player:GetAttribute(ArenaConfig.SIDE)
	local remote = Remotes.get().Ping
	for _, other in Players:GetPlayers() do
		if other == player or (typeof(side) == "number" and other:GetAttribute(ArenaConfig.SIDE) == side) then
			remote:FireClient(other, event)
		end
	end
end

local function onPing(player: Player, payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	local now = Workspace:GetServerTimeNow()
	if payload.kind == "look" then
		local option, yaw, pitch, viewTime = payload.option, payload.yaw, payload.pitch, payload.viewTime
		if (option ~= nil and not Pings.isOption(option)) or typeof(yaw) ~= "number" or typeof(pitch) ~= "number" then
			return
		end
		if not PlayerSimServer.inPlay(player) or not spend(player, now) then
			return
		end
		local seen = if typeof(viewTime) == "number" and viewTime == viewTime then viewTime else now
		local ping = along(player, Accuracy.aim(yaw, pitch), option, seen)
		if ping then
			send(player, ping)
		end
	elseif payload.kind == "map" then
		local point = payload.point
		local plan = planNow()
		if typeof(point) ~= "Vector3" or not plan then
			return
		end
		local at = vector.create(point.X, 0, point.Z)
		if not Minimap.holds(plan, at) or not spend(player, now) then
			return
		end
		send(player, { kind = "map", position = at })
	end
end

function PingServer.start()
	Remotes.get().Ping.OnServerEvent:Connect(onPing)
	Players.PlayerRemoving:Connect(function(player)
		budgets[player] = nil
	end)
end

return PingServer
