--!strict
-- Omen's Paranoia on the server (system 41). Each orb sent (a "paranoia"
-- cast) flies here through ParanoiaSim on the server's clock, from when
-- it's told of, as nothing changes its path after the send. Every client is
-- told of the send (the Ability remote's "flight"): where from, which way
-- and when, in server time, so each draws it the same way and warns its
-- player if they stand in its path. Each server frame, everyone the orb's
-- middle has come within its radius of since the last is touched, once
-- each, at the pose the snapshots show (Entities): players in play, the
-- thrower and their side too, as the VALORANT Wiki's Paranoia page has it
-- (community), and the practice dummies, which have no sight to take.
-- A touched player is nearsighted and deafened (ParanoiaSim.nearsight),
-- their `VFNearsight` and `VFDeafened` attributes (ParanoiaSim.ATTRIBUTE
-- and DEAF_ATTRIBUTE) until each is gone. Reyna's Leer (system 74,
-- LeerServer) nearsights through here too (ParanoiaServer.nearsee), with
-- no deafening. Both go with a death or a new life, and with a Phoenix's
-- body gone in Run it Back (ParanoiaServer.clear), as a blind does; and a
-- thrower's orbs still in flight go as they start a new life. While it's whole, the minimap
-- sees for them no further than its vision and tells them nothing
-- (MinimapServer), and a flash popping further away doesn't blind them
-- (FlareServer). Whom the thrower's last orb touched is their
-- `VFLastParanoia` attribute once it's flown (their names, in the order it
-- touched them, "" for nobody), which scripted checks read. Bots send orbs
-- and are nearsighted by them as players are (system 65), each known by
-- its stand-in (PlayerSimServer.Actor), which carries its `VFNearsight`.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilitySim = require(Shared.Abilities.AbilitySim)
local ParanoiaSim = require(Shared.Abilities.ParanoiaSim)
local Sight = require(Shared.Combat.Sight)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local Entities = require(script.Parent.Entities)

local ParanoiaServer = {}

ParanoiaServer.LAST_ATTRIBUTE = "VFLastParanoia"

type Actor = PlayerSimServer.Actor

-- An orb in flight: whose, sent when (server time), how far into its
-- flight it's been looked along (seconds), and whom it's touched, by
-- entity id, and their names in order.
type Flying = {
	player: Actor,
	orb: ParanoiaSim.Orb,
	at: number,
	looked: number,
	touched: { [number]: boolean },
	names: { string },
}

local flying: { Flying } = {}
-- Each player's nearsight, and their deafening, while any of each is
-- left.
local nearsights: { [Actor]: ParanoiaSim.Nearsight } = {}
local deafenings: { [Actor]: ParanoiaSim.Nearsight } = {}

local function setNearsight(player: Actor, n: ParanoiaSim.Nearsight?)
	if n then
		nearsights[player] = n
		player:SetAttribute(ParanoiaSim.ATTRIBUTE, ParanoiaSim.encode(n))
	else
		nearsights[player] = nil
		player:SetAttribute(ParanoiaSim.ATTRIBUTE, nil)
	end
end

local function setDeafened(player: Actor, n: ParanoiaSim.Nearsight?)
	if n then
		deafenings[player] = n
		player:SetAttribute(ParanoiaSim.DEAF_ATTRIBUTE, ParanoiaSim.encode(n))
	else
		deafenings[player] = nil
		player:SetAttribute(ParanoiaSim.DEAF_ATTRIBUTE, nil)
	end
end

-- A player's nearsight, if any of it's left: what Reyna's Leer runs on
-- (system 74, LeerServer).
function ParanoiaServer.nearsightOf(player: Actor): ParanoiaSim.Nearsight?
	return nearsights[player]
end

-- A player's nearsight as Reyna's Leer gives it (system 74, LeerServer),
-- what was left of theirs already in it: on their attribute until it's
-- gone, but not deafening them.
ParanoiaServer.nearsee = setNearsight

local function onCast(player: Actor, cast: AbilitySim.Cast)
	if cast.kind ~= "paranoia" then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	local orb = ParanoiaSim.send(entity.id, cast.tick, cast.origin, cast.direction)
	local now = Workspace:GetServerTimeNow()
	Remotes.get().Ability:FireAllClients({
		entity = entity.id,
		ability = cast.ability,
		kind = "flight",
		id = cast.tick,
		at = now,
		position = Units.toStuds(cast.origin),
		direction = Units.asVector3(orb.way),
	})
	table.insert(flying, { player = player, orb = orb, at = now, looked = 0, touched = {}, names = {} })
end

-- The points of an entity an orb can touch, if it can be touched: alive,
-- spawned, and a player in play.
local function pointsOf(entity: Entities.Entity): { vector }?
	local player = entity.player
	if not entity.health.alive or (player and not PlayerSimServer.inPlay(player)) then
		return nil
	end
	local pose = entity.pose()
	return if pose and pose.alive then Sight.points(pose) else nil
end

-- An orb's frame, at server time `now`: whom it's touched since the last.
local function fly(f: Flying, now: number)
	local age = math.clamp(now - f.at, f.looked, ParanoiaSim.flight())
	local a, b = ParanoiaSim.at(f.orb, f.looked), ParanoiaSim.at(f.orb, age)
	f.looked = age
	for id, entity in Entities.all() do
		if f.touched[id] then
			continue
		end
		local points = pointsOf(entity)
		if not points or not ParanoiaSim.touches(a, b, points) then
			continue
		end
		f.touched[id] = true
		table.insert(f.names, entity.name)
		local actor = PlayerSimServer.actorOf(entity)
		if actor then
			setNearsight(actor, ParanoiaSim.nearsight(nearsights[actor], now))
			setDeafened(actor, ParanoiaSim.nearsight(deafenings[actor], now))
		end
	end
end

-- A player's nearsight and deafening gone, if they have them: with a
-- death, a new life, and a Phoenix's body gone in Run it Back (system 33).
local function clear(player: Actor)
	if nearsights[player] then
		setNearsight(player, nil)
	end
	if deafenings[player] then
		setDeafened(player, nil)
	end
end
ParanoiaServer.clear = clear

-- Once a server frame, at server time `now`: the orbs in flight touch
-- whom they've come to, those that have flown go, and the nearsights and
-- deafenings that are over go.
function ParanoiaServer.step(now: number)
	local flight = ParanoiaSim.flight()
	for i = #flying, 1, -1 do
		local f = flying[i]
		fly(f, now)
		if f.looked >= flight then
			table.remove(flying, i)
			if f.player.Parent then
				f.player:SetAttribute(ParanoiaServer.LAST_ATTRIBUTE, table.concat(f.names, ","))
			end
		end
	end
	for player, n in nearsights do
		if now >= n.gone then
			setNearsight(player, nil)
		end
	end
	for player, n in deafenings do
		if now >= n.gone then
			setDeafened(player, nil)
		end
	end
end

function ParanoiaServer.start()
	table.insert(PlayerSimServer.castListeners, onCast)
	table.insert(PlayerSimServer.deathListeners, clear)
	local function newLife(player: Actor)
		clear(player)
		for i = #flying, 1, -1 do
			if flying[i].player == player then
				table.remove(flying, i)
			end
		end
	end
	table.insert(PlayerSimServer.spawnListeners, newLife)
	table.insert(PlayerSimServer.botDeathListeners, clear)
	table.insert(PlayerSimServer.botSpawnListeners, newLife)
	Players.PlayerRemoving:Connect(function(player)
		nearsights[player] = nil
		deafenings[player] = nil
	end)
end

return ParanoiaServer
