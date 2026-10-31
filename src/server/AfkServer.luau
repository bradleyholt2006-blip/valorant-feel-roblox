--!strict
-- AFK in a match (system 70), on the server: each player's clock
-- (AfkRules), started over by every input that plays at something
-- (PlayerSimServer's ticks), by a buy and by a ping, and moved on each
-- frame as the arena says their time counts (`AfkServer.state`). Warned,
-- their MatchConfig.AFK_AT has the server time they'll be taken out at
-- while their time counts; due out, the arena takes them out of the match
-- (`AfkServer.takeOut`), their place held for them as for anyone who left
-- (system 69), and their MatchConfig.AFK_OUT says why until they're back.
--
-- In Studio AFK's off unless Workspace's MatchConfig.TEST_AFK has the
-- seconds to warn after: a check's players often stand idle.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AfkRules = require(Shared.Match.AfkRules)
local MatchConfig = require(Shared.Match.MatchConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)

local PlayerSimServer = require(script.Parent.PlayerSimServer)

local A = MatchConfig.Afk

local AfkServer = {}

-- Set by the arena: whether a player's time counts now, and taking them
-- out of the match.
AfkServer.state = nil :: ((player: Player) -> AfkRules.State)?
AfkServer.takeOut = nil :: ((player: Player) -> ())?

type Record = {
	clock: AfkRules.Clock,
	shownAt: number?, -- the MatchConfig.AFK_AT last set, if it is
	told: boolean, -- the warning printed, until the clock's no longer warned
}

local records: { [Player]: Record } = {}

-- Seconds without playing before a warning, or nil with AFK off (Studio,
-- but for a check).
function AfkServer.warnAfter(): number?
	if not RunService:IsStudio() then
		return A.warnAfter.value
	end
	local test = Workspace:GetAttribute(MatchConfig.TEST_AFK)
	return if typeof(test) == "number" and test > 0 then test else nil
end

-- Whether AFK is on for a check in Studio, where it counts with nobody
-- else playing too.
function AfkServer.testing(): boolean
	return RunService:IsStudio() and AfkServer.warnAfter() ~= nil
end

local function show(player: Player, r: Record, at: number?)
	if r.shownAt ~= at then
		r.shownAt = at
		player:SetAttribute(MatchConfig.AFK_AT, at)
	end
end

-- Something played that the ticks don't carry (a buy, a ping).
function AfkServer.played(player: Player)
	local r = records[player]
	if r then
		AfkRules.played(r.clock)
		show(player, r, nil)
	end
end

-- Moves everyone's clock on a frame of `dt` seconds, ending at server time
-- `now`.
function AfkServer.step(now: number, dt: number)
	local state, takeOut = AfkServer.state, AfkServer.takeOut
	local warnAfter = AfkServer.warnAfter()
	local outAfter = A.outAfter.value
	for player, r in records do
		local s: AfkRules.State = if state and warnAfter then state(player) else "off"
		local due = AfkRules.step(r.clock, dt, s, warnAfter or 0, outAfter)
		if not r.clock.warned then
			r.told = false
		end
		if due == "out" then
			show(player, r, nil)
			player:SetAttribute(MatchConfig.AFK_OUT, true)
			print(string.format("[VF] AFK: %d taken out of the match", player.UserId))
			if takeOut then
				takeOut(player)
			end
		elseif r.clock.warned and s == "count" then
			-- Once a warning: not again as it shows afresh after a round's
			-- break.
			if not r.told then
				r.told = true
				print(string.format("[VF] AFK: %d warned", player.UserId))
			end
			show(player, r, r.shownAt or now + AfkRules.left(r.clock, warnAfter or 0, outAfter))
		else
			show(player, r, nil)
		end
	end
end

-- Back in a match: what said they were taken out goes.
function AfkServer.back(player: Player)
	player:SetAttribute(MatchConfig.AFK_OUT, nil)
end

function AfkServer.start()
	local function added(player: Player)
		records[player] = { clock = AfkRules.new(), shownAt = nil, told = false }
	end
	Players.PlayerAdded:Connect(added)
	for _, player in Players:GetPlayers() do
		added(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		records[player] = nil
	end)
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		local r = records[player]
		if r then
			AfkRules.spawned(r.clock)
		end
	end)
	table.insert(PlayerSimServer.tickListeners, function(actor: PlayerSimServer.Actor, input: PlayerCodec.WireInput)
		local r = if actor:IsA("Player") then records[actor :: Player] else nil
		if r and AfkRules.input(r.clock, input.buttons, input.yaw, input.pitch, input.slot) then
			show(actor :: Player, r, nil)
		end
	end)
	Remotes.get().Buy.OnServerEvent:Connect(AfkServer.played)
	Remotes.get().Ping.OnServerEvent:Connect(AfkServer.played)
end

return AfkServer
