--!strict
-- The round-end callouts on the server (system 56): each round of Skirmish
-- and the spike rounds kept (RoundCallouts) from when it goes live (Arena,
-- CalloutServer.roundLive) to its end (CalloutServer.roundOver), from what
-- PlayerSimServer tells of every death, ReviveServer of every life Sage's
-- Resurrection brings back, and Players of everyone who leaves; and its
-- callout decided as it ends, for the arena's model to carry to clients.
-- Where loadouts are bought, each one's is worth its guns' and shield's
-- prices as the round goes live.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RoundCallouts = require(Shared.Match.RoundCallouts)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local ReviveServer = require(script.Parent.ReviveServer)

local CalloutServer = {}

local round: RoundCallouts.Round? = nil -- the round under way, from when it went live

-- What a player's loadout is worth now.
local function worthOf(player: Player): number
	local entity = PlayerSimServer.entityOf(player)
	local primary = PlayerSimServer.holding(player, 1)
	local sidearm = PlayerSimServer.holding(player, 2)
	return RoundCallouts.worth({ primary or "", sidearm or "", if entity then entity.health.kind else "" })
end

-- A round has gone live with `sides` (by UserId, each one's side) playing
-- it, and with `economy` where loadouts are bought.
function CalloutServer.roundLive(sides: { [number]: number }, economy: boolean)
	local worth: { [number]: number }? = nil
	if economy then
		local each: { [number]: number } = {}
		for id in sides do
			local player = Players:GetPlayerByUserId(id)
			each[id] = if player then worthOf(player) else 0
		end
		worth = each
	end
	round = RoundCallouts.begin(sides, worth)
end

-- The round under way has ended, won by `winner`'s side: its callout, if it
-- has one.
function CalloutServer.roundOver(winner: number): RoundCallouts.Callout?
	local r = round
	round = nil
	return if r then RoundCallouts.decide(r, winner) else nil
end

-- A buy phase starting, or a mode starting or stopping: no round under way.
function CalloutServer.reset()
	round = nil
end

function CalloutServer.start()
	table.insert(PlayerSimServer.deathListeners, function(player: Player, killer: Player?)
		local r = round
		if r then
			RoundCallouts.died(r, player.UserId, if killer then killer.UserId else nil)
		end
	end)
	table.insert(ReviveServer.reviveListeners, function(owner)
		local r, player = round, owner.player
		if r and player then
			RoundCallouts.revived(r, player.UserId)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local r = round
		if r then
			RoundCallouts.left(r, player.UserId)
		end
	end)
end

return CalloutServer
