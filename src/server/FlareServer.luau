--!strict
-- Phoenix's Curveball on the server (system 30). Each flare thrown (a
-- "flare" cast) flies here through FlareSim at once, through the level, as
-- nothing changes its path after the throw, and pops its windup after the
-- throw, on the server's clock. Every client is told of the throw (the
-- Ability remote's "flight"): where from and which way round, when in
-- server time, how long after the throw it met the level if it did, and
-- where it pops, so each flies it the same way.
-- At the pop, everyone alive who can see it is blinded by how far it is off
-- their view and how far away (FlareSim.strength), the thrower and their
-- side too, as the reference's blinds 'allies/self' (the VALORANT Wiki's
-- Curveball page; community). Each is judged from where the server last had
-- their eye and their view (PlayerSimServer.view), and nobody out of play
-- is (a Phoenix whose body's gone in Run it Back, system 33), and nor is
-- anyone nearsighted by Omen's Paranoia (system 41) with the pop further
-- away than they see (the VALORANT Wiki's Status Effect page; community).
-- A blind is the player's `VFBlind` attribute (FlareSim.BLIND_ATTRIBUTE)
-- until it's gone, and goes with a death or a new life, as do a thrower's
-- flares still in the air as they start a new life, and with that body
-- (FlareServer.clear). The thrower's last pop is their `VFLastFlare`
-- attribute (metres), which scripted checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilitySim = require(Shared.Abilities.AbilitySim)
local FlareSim = require(Shared.Abilities.FlareSim)
local ParanoiaSim = require(Shared.Abilities.ParanoiaSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)

local FlareServer = {}

FlareServer.LAST_FLARE_ATTRIBUTE = "VFLastFlare"

local DT = 1 / MovementConfig.TickRate.value
local world = RobloxWorld.new()

-- A flare in the air: whose, and when (server time) and where it pops.
type Pending = { player: Player, at: number, position: vector }

local pending: { Pending } = {}
-- Each player's blind, while any of it is left.
local blinds: { [Player]: FlareSim.Blind } = {}

local function setBlind(player: Player, b: FlareSim.Blind?)
	if b then
		blinds[player] = b
		player:SetAttribute(FlareSim.BLIND_ATTRIBUTE, FlareSim.encode(b))
	else
		blinds[player] = nil
		player:SetAttribute(FlareSim.BLIND_ATTRIBUTE, nil)
	end
end

local function onCast(player: Player, cast: AbilitySim.Cast)
	if cast.kind ~= "flare" then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	local flare = FlareSim.throw(entity.id, cast.tick, cast.origin, cast.direction, cast.curve or 1)
	local path = FlareSim.fly(flare, DT, world)
	local pop = path[#path]
	local now = Workspace:GetServerTimeNow()
	Remotes.get().Ability:FireAllClients({
		entity = entity.id,
		ability = cast.ability,
		kind = "flight",
		id = cast.tick,
		at = now,
		position = Units.toStuds(cast.origin),
		direction = Units.asVector3(cast.direction),
		curve = flare.curve,
		stop = flare.stopped,
		pop = Units.toStuds(pop),
	})
	table.insert(pending, { player = player, at = now + FlareSim.popTime(DT), position = pop })
end

-- A flare's pop: everyone alive and in play who can see it, blinded by it.
local function popped(p: Pending)
	if p.player.Parent then
		p.player:SetAttribute(FlareServer.LAST_FLARE_ATTRIBUTE, Units.asVector3(p.position))
	end
	for _, player in Players:GetPlayers() do
		if not PlayerSimServer.inPlay(player) then
			continue
		end
		local eye, look = PlayerSimServer.view(player)
		if not eye or not look or not FlareSim.seen(p.position, eye, world) then
			continue
		end
		local range = ParanoiaSim.range(ParanoiaSim.decode(player:GetAttribute(ParanoiaSim.ATTRIBUTE)), p.at)
		if range and vector.magnitude(p.position - eye) > range then
			continue
		end
		local strength = FlareSim.strength(p.position, eye, look)
		if strength > 0 then
			setBlind(player, FlareSim.blind(blinds[player], p.at, strength))
		end
	end
end

-- A player's blind gone, if they have one: with a death, a new life, and
-- a Phoenix's body gone in Run it Back (system 33; Patch 12.01 fixed a
-- debuff staying on him through it).
local function clear(player: Player)
	if blinds[player] then
		setBlind(player, nil)
	end
end
FlareServer.clear = clear

-- Once a server frame, at server time `now`: the flares due pop, and the
-- blinds that are over go.
function FlareServer.step(now: number)
	local i = 1
	while i <= #pending do
		local p = pending[i]
		if now >= p.at then
			table.remove(pending, i)
			popped(p)
		else
			i += 1
		end
	end
	for player, b in blinds do
		if now >= b.gone then
			setBlind(player, nil)
		end
	end
end

function FlareServer.start()
	table.insert(PlayerSimServer.castListeners, onCast)
	table.insert(PlayerSimServer.deathListeners, clear)
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		clear(player)
		for i = #pending, 1, -1 do
			if pending[i].player == player then
				table.remove(pending, i)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		blinds[player] = nil
	end)
end

return FlareServer
