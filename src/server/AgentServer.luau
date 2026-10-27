--!strict
-- Agent select on the server (system 29). AgentSelect keeps each player's
-- pick; this hears what they select and lock in (the AgentPick remote),
-- moves each pick on as where they are says (Arena: AgentServer.momentOf),
-- and puts the agent they play on their kit (AbilityServer.choose):
--   * once a match in Skirmish, the spike rounds and Team Deathmatch: a
--     window from the match's start or from when they join it under way,
--     what's selected locked in as it closes, and the agent theirs until
--     the match is over
--   * one of each agent on a side (system 48): an agent a teammate has
--     locked in is taken, first come first served in the server's order
--     of players, and each side of a match has windows of its own, so
--     someone moved across to even the sides picks again
--   * on the course and while a mode waits for players, an agent locked in
--     is theirs at once, as often as they like
--   * nobody picks in gun game or deathmatch, which have no abilities
-- An agent locked in goes on the kit at once where it can (Arena:
-- AgentServer.swapsNow), the kit starting over as the mode starts one, or
-- else with the next life; in the spike rounds, what was bought into the
-- last agent's kit this buy phase is sold back (ShopServer.refundCharges).
-- Each player's pick goes to clients as player attributes (AgentSelect's),
-- so teammates see what they select.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AgentSelect = require(Shared.Abilities.AgentSelect)
local Remotes = require(Shared.Net.Remotes)

local AbilityServer = require(script.Parent.AbilityServer)
local ShopServer = require(script.Parent.ShopServer)

local AgentServer = {}

-- Where a player is for picking (AgentSelect.moment), as Arena has it; until
-- it's set, everywhere is free.
AgentServer.momentOf = nil :: ((player: Player) -> string?)?
-- Whether an agent locked in now goes on a player's kit at once
-- (AgentSelect.swapsNow), as Arena has it, or with their next life; until
-- it's set, at once.
AgentServer.swapsNow = nil :: ((player: Player) -> boolean)?

local state = AgentSelect.new()
-- What each player's attributes say, all in one.
local shown: { [Player]: string } = {}

-- The agent a player now plays, on their kit: at once where it can go on,
-- what they'd bought into the last agent's this buy phase sold back, or
-- with their next life.
local function apply(player: Player, agent: string, time: number)
	local swaps = AgentServer.swapsNow
	if AbilityServer.choose(player, agent, time, swaps == nil or swaps(player)) then
		ShopServer.refundCharges(player)
	end
end

-- Tells clients a player's pick, when it's changed.
local function publish(player: Player)
	local pick = AgentSelect.pickOf(state, player.UserId)
	local open = pick.status == "open"
	local picking = open or pick.status == "free"
	local text = string.format(
		"%s,%s,%s,%s",
		pick.agent,
		if picking then pick.selected else "",
		pick.status,
		if open then tostring(pick.closesAt) else ""
	)
	if shown[player] == text then
		return
	end
	shown[player] = text
	player:SetAttribute(AgentSelect.AGENT, pick.agent)
	player:SetAttribute(AgentSelect.SELECTED, if picking then pick.selected else nil)
	player:SetAttribute(AgentSelect.STATUS, if pick.status == "none" then nil else pick.status)
	player:SetAttribute(AgentSelect.CLOSES, if open then pick.closesAt else nil)
end

-- "select" with an agent's id, or "lock".
local function onPick(player: Player, action: any, agent: any)
	if action == "select" and typeof(agent) == "string" then
		AgentSelect.select(state, player.UserId, agent)
	elseif action == "lock" then
		local changed = AgentSelect.lock(state, player.UserId)
		if changed then
			apply(player, changed, Workspace:GetServerTimeNow())
		end
	end
	publish(player)
end

-- Once a server frame, after the arena's rounds have moved on: every pick
-- as where its player is says, all together and in the server's order of
-- players (AgentSelect.step), a window opening or closing, and an agent
-- locked in as one closes put on their kit.
function AgentServer.step(time: number)
	local momentOf = AgentServer.momentOf
	local players = Players:GetPlayers()
	local ids: { number } = {}
	local moments: { [number]: string? } = {}
	for _, player in players do
		table.insert(ids, player.UserId)
		moments[player.UserId] = if momentOf then momentOf(player) else AgentSelect.FREE
	end
	local changed = AgentSelect.step(state, ids, moments, time)
	for _, player in players do
		local agent = changed[player.UserId]
		if agent then
			apply(player, agent, time)
		end
		publish(player)
	end
end

function AgentServer.start()
	Remotes.get().AgentPick.OnServerEvent:Connect(onPick)
	Players.PlayerRemoving:Connect(function(player)
		AgentSelect.leave(state, player.UserId)
		shown[player] = nil
	end)
end

return AgentServer
