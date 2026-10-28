--!strict
-- The kill banner on the server (system 55): each kill counted for the
-- player who made it (KillBanner), from what CombatServer tells of every
-- kill, and its banner sent to them alone with the Banner remote as the kill
-- lands: which kill of theirs it is, who was killed, and whether it was a
-- headshot. Nobody else is told: it's theirs, as the kill sound with it is.
--
-- The count goes by the round in Skirmish and the spike rounds, started
-- over as one starts (Arena, BannerServer.roundStarted) and kept through
-- the life Sage's Resurrection starts; elsewhere, and while a match waits
-- for an opponent, by the life, started over at each spawn. A kill of a
-- teammate or of yourself counts for nothing and has no banner; a practice
-- dummy's counts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KillBanner = require(Shared.Combat.KillBanner)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)

local BannerServer = {}

-- Whether counts go by the round now, not by the life: as the combat
-- report's (Arena). By the life without.
BannerServer.byRound = nil :: (() -> boolean)?

local log = KillBanner.newLog()

-- A round has started: nobody's killed anyone in it.
function BannerServer.roundStarted()
	KillBanner.clear(log)
end

-- A mode starting or stopping: everyone's count starts over.
function BannerServer.reset()
	KillBanner.clear(log)
end

function BannerServer.start()
	table.insert(CombatServer.killListeners, function(attacker, victim, _, _, region: string)
		local player = if attacker then attacker.player else nil
		if not attacker or not player then
			return
		end
		local banner = KillBanner.killed(log, attacker.id, victim.id, CombatServer.teammates(attacker, victim), region)
		if banner and player.Parent then
			Remotes.get().Banner:FireClient(player, banner)
		end
	end)
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		local byRound = BannerServer.byRound
		if not (byRound and byRound()) then
			KillBanner.open(log, PlayerCodec.entityIdForUser(player.UserId))
		end
	end)
end

return BannerServer
