--!strict
-- Sova's Shock Bolt on the server (system 45). Each bolt loosed (a "bolt"
-- cast of the Shock Bolt's) flies here through BoltSim at once, through the
-- level, as nothing changes its path after the loose, and bursts where it
-- lands, on the server's clock. Every client is told of the loose (the
-- Ability remote's "flight"): its keys, how long after the loose it bursts,
-- where, and the way the surface there faces, so each draws it and its
-- burst the same way.
--
-- It bursts on through its owner's death. The burst hurts everyone alive
-- and in play it has in sight within its outer radius (ShockSim.hits), at
-- the pose the snapshots show (Entities): enemies, the practice dummies,
-- its owner's side and its owner, the last two by their shares of it
-- (AbilityConfig.ShockBolt). In the way: the level, but not the spawns'
-- barriers (FogServer.blocked), and the walls of ice (BarrierServer); the
-- clouds and the walls of fire hide but stop nothing. Each one's damage
-- goes through their shield as any hit's, without slowing them, credited
-- to its owner as the Shock Bolt (CombatServer.blast), and spawn
-- protection keeps it off. A bolt still to burst goes with a new round
-- (Arena), which every client hears of from FireServer.clear's "out". Each
-- owner's last burst is their `VFLastShock` attribute (where, metres), and
-- whom it hurt, with how much, their `VFShockHits`, which scripted checks
-- read.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local BoltSim = require(Shared.Abilities.BoltSim)
local ShockSim = require(Shared.Abilities.ShockSim)
local Sight = require(Shared.Combat.Sight)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local BarrierServer = require(script.Parent.BarrierServer)
local FogServer = require(script.Parent.FogServer)

local ShockServer = {}

local SB = AbilityConfig.ShockBolt
local DT = 1 / MovementConfig.TickRate.value
local world = RobloxWorld.new()

-- A bolt in the air: whose (their player and entity id), the tick it was
-- loosed on, where it bursts, the way the surface there faces, and when
-- (server time).
type Due = {
	player: PlayerSimServer.Actor,
	owner: number,
	id: number,
	point: vector,
	normal: vector,
	at: number,
}

local due: { Due } = {}

local function onCast(player: PlayerSimServer.Actor, cast: AbilitySim.Cast)
	if cast.kind ~= "bolt" or cast.ability ~= "shockbolt" then
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
		table.insert(due, {
			player = player,
			owner = entity.id,
			id = cast.tick,
			point = bolt.position,
			normal = normal,
			at = now + landed,
		})
	end
	Remotes.get().Ability:FireAllClients(event)
end

-- Whom a burst can hurt: everyone alive, spawned and in play, its owner
-- too, each one's entity id and the points of them that count, at the
-- pose the snapshots show.
local function targets(): { ShockSim.Target }
	local out: { ShockSim.Target } = {}
	for id, entity in Entities.all() do
		if not entity.health.alive then
			continue
		end
		local player = entity.player
		if player and not (PlayerSimServer.inPlay(player) and PlayerSimServer.isAlive(player)) then
			continue
		end
		local pose = entity.pose()
		if pose and pose.alive then
			table.insert(out, { id = id, points = Sight.points(pose) })
		end
	end
	return out
end

-- A bolt bursting at `now`: everyone it hurts takes their share of it.
local function burst(d: Due, now: number)
	local o: Sight.Occluders = {
		clouds = {},
		walls = {},
		barriers = BarrierServer.standing(),
		time = now,
		blocked = FogServer.blocked,
	}
	local hits = ShockSim.hits(d.point, d.normal, targets(), function(a: vector, b: vector): boolean
		return Sight.hidden(a, b, o)
	end)
	local owner = Entities.get(d.owner)
	local protected = CombatServer.protected
	local told = {}
	for _, hit in hits do
		local victim = Entities.get(hit.id)
		if not victim or (protected and protected(victim)) then
			continue
		end
		local share = if victim == owner
			then SB.selfShare.value
			elseif owner and CombatServer.teammates(owner, victim) then SB.allyShare.value
			else 1
		local amount = math.floor(hit.damage * share + 0.5)
		if amount <= 0 then
			continue
		end
		CombatServer.blast(owner, victim, amount, ShockSim.WEAPON, d.point)
		table.insert(told, { name = victim.name, amount = amount })
	end
	if d.player.Parent then
		table.sort(told, function(a, b)
			return a.name < b.name
		end)
		local parts = {}
		for _, each in told do
			table.insert(parts, string.format("%s %d", each.name, each.amount))
		end
		d.player:SetAttribute(ShockSim.POINT_ATTRIBUTE, Units.asVector3(d.point))
		d.player:SetAttribute(ShockSim.HITS_ATTRIBUTE, table.concat(parts, ","))
	end
end

-- Once a server frame, at server time `now`: the bolts due burst.
function ShockServer.step(now: number)
	local i = 1
	while i <= #due do
		local d = due[i]
		if now >= d.at then
			table.remove(due, i)
			burst(d, now)
		else
			i += 1
		end
	end
end

-- Every bolt still to burst gone (a new round). FireServer.clear tells
-- every client.
function ShockServer.clear()
	table.clear(due)
end

function ShockServer.start()
	table.insert(PlayerSimServer.castListeners, onCast)
end

return ShockServer
