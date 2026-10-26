--!strict
-- Sage's Slow Orb on the server (system 37). Each orb thrown (a "slow"
-- cast) flies here through FireballSim at once, as the Slow Orb's
-- (SlowSim), through the level, as nothing changes its path after the
-- throw, and bursts where it lands, on the server's clock; how far its
-- field can spread each way round is worked out with it. Every client is
-- told of the throw (the Ability remote's "flight"): its keys, how long
-- after the throw it bursts, the floor its field lies on and how far that
-- reaches, so each draws it the same way, and the owner's prediction slows
-- them in it as the server does. The fields are kept here for the
-- simulation (PlayerSimServer.fields, and the practice dummies'): a
-- player's ticks are slowed in one as the server time their screen showed
-- has it, judged no further behind than SlowSim.LAG, and a dummy's as the
-- server's clock has it. A field lasts its time whoever leaves, and is kept
-- that long again after for moves that come in late. They all go with a
-- new round (Arena), which every client hears of from FireServer.clear's
-- "out". The thrower's last burst is their `VFLastSlow` attribute
-- (SlowSim.LAST_ATTRIBUTE, the floor under it, in metres), and whether
-- each player's last tick was slowed their `VFSlowed`
-- (SlowSim.SLOWED_ATTRIBUTE), which scripted checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilitySim = require(Shared.Abilities.AbilitySim)
local FireballSim = require(Shared.Abilities.FireballSim)
local FireSim = require(Shared.Abilities.FireSim)
local SlowSim = require(Shared.Abilities.SlowSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local Dummies = require(script.Parent.Dummies)

local SlowServer = {}

local DT = 1 / MovementConfig.TickRate.value
local world = RobloxWorld.new()

-- A field in play: whose, and whether its thrower's been told it burst.
type Kept = { player: Player, field: SlowSim.Field, burst: boolean }

local kept: { Kept } = {}
local fields: { SlowSim.Field } = {}
local shown: { [Player]: boolean } = {}

local function onCast(player: Player, cast: AbilitySim.Cast)
	if cast.kind ~= "slow" then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	local orb = SlowSim.throw(entity.id, cast.tick, cast.origin, cast.direction)
	local landed = FireballSim.fly(orb, DT, world)
	local now = Workspace:GetServerTimeNow()
	local keys = {}
	for _, key in orb.keys do
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
	if landed then
		local centre = SlowSim.floorUnder(orb.position)
		local reaches = SlowSim.reaches(centre, world)
		event.point = Units.asVector3(centre)
		event.reaches = reaches
		local field = SlowSim.field(entity.id, cast.tick, centre, now + landed, reaches)
		table.insert(kept, { player = player, field = field, burst = false })
		table.insert(fields, field)
	end
	Remotes.get().Ability:FireAllClients(event)
end

-- Once a server frame, at server time `now`: the bursts told of, the
-- fields long over gone, and each player's `VFSlowed` as their last tick
-- left it.
function SlowServer.step(now: number)
	local gone = false
	for i = #kept, 1, -1 do
		local k = kept[i]
		if not k.burst and now >= k.field.start then
			k.burst = true
			if k.player.Parent then
				k.player:SetAttribute(SlowSim.LAST_ATTRIBUTE, Units.asVector3(k.field.centre))
			end
		end
		if now >= FireSim.ends(k.field) + SlowSim.LAG then
			table.remove(kept, i)
			gone = true
		end
	end
	if gone then
		table.clear(fields)
		for _, k in kept do
			table.insert(fields, k.field)
		end
	end
	for _, player in Players:GetPlayers() do
		local entity = PlayerSimServer.entityOf(player)
		local sim = if entity and PlayerSimServer.isAlive(player) then entity.sim else nil
		local slowed = sim ~= nil and sim.movement.slowed == true
		if shown[player] ~= slowed then
			shown[player] = slowed
			player:SetAttribute(SlowSim.SLOWED_ATTRIBUTE, slowed)
		end
	end
end

-- Every field gone (a new round). FireServer.clear tells every client.
function SlowServer.clear()
	table.clear(kept)
	table.clear(fields)
end

function SlowServer.start()
	table.insert(PlayerSimServer.castListeners, onCast)
	PlayerSimServer.fields = function(): { SlowSim.Field }
		return fields
	end
	Dummies.fields = function(): { SlowSim.Field }
		return fields
	end
	Players.PlayerRemoving:Connect(function(player)
		shown[player] = nil
	end)
end

return SlowServer
