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
-- A player who leaves a match under way with their place held (system 69)
-- keeps their pick: the agent stays theirs, taken from their teammates,
-- and goes back on their kit as they're back.
-- Bots pick too (system 65), after every player, on their stand-ins: each
-- selects an agent nobody on its side has locked in or selected yet, at
-- random, and selects again if a teammate takes it, and what it's
-- selected is locked in as its window closes, a player's first where
-- they close at once on one agent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AgentSelect = require(Shared.Abilities.AgentSelect)
local Remotes = require(Shared.Net.Remotes)

local AbilityServer = require(script.Parent.AbilityServer)
local BotServer = require(script.Parent.BotServer)
local ShopServer = require(script.Parent.ShopServer)

local AgentServer = {}

-- Where a player or a bot is for picking (AgentSelect.moment), as Arena has
-- it, by what carries their attributes and their id in the rules; until
-- it's set, everywhere is free.
AgentServer.momentOf = nil :: ((holder: Instance, id: number) -> string?)?
-- Whether an agent locked in now goes on a player's or a bot's kit at once
-- (AgentSelect.swapsNow), as Arena has it, or with their next life; until
-- it's set, at once.
AgentServer.swapsNow = nil :: ((holder: Instance, id: number) -> boolean)?
-- Whether a player leaving keeps their pick, their place held in a match
-- under way (system 69), as Arena has it; until it's set, nobody does.
AgentServer.keeps = nil :: ((id: number) -> boolean)?
-- Whether a player's place is held while they're away from the match
-- (system 69): in the server again, or taken out in Studio, their pick
-- waits as it was, still theirs, until they're back in it.
AgentServer.away = nil :: ((id: number) -> boolean)?

local state = AgentSelect.new()
-- What each player's attributes say, all in one.
local shown: { [Instance]: string } = {}
-- The agent last put on each player's kit.
local onKit: { [Instance]: string } = {}
-- The bots picking last step, and the side of a match each one last
-- picked at random for.
local botIds: { [number]: Instance } = {}
local botPicked: { [number]: string } = {}
local dice = Random.new()

-- The agent a player now plays, on their kit: at once where it can go on,
-- what they'd bought into the last agent's this buy phase sold back, or
-- with their next life.
local function apply(player: Instance, id: number, agent: string, time: number)
	onKit[player] = agent
	local swaps = AgentServer.swapsNow
	if AbilityServer.choose(player, agent, time, swaps == nil or swaps(player, id)) and player:IsA("Player") then
		ShopServer.refundCharges(player)
	end
end

-- A bot's selection while it can pick (system 65): kept while no teammate
-- has the agent, locked in or selected (a player picking before it, or a
-- bot), and otherwise one nobody on its side has, at random, as it is
-- the first time it picks for a side of a match. Where an agent locked in
-- is theirs at once, it's locked in at once. Returns the agent it plays,
-- if that's changed.
local function botSelect(id: number): string?
	local pick = AgentSelect.pickOf(state, id)
	if pick.status ~= "open" and pick.status ~= "free" then
		return nil
	end
	local claimed = AgentSelect.taken(state, id)
	for other, mate in state.picks do
		if other ~= id and mate.match == pick.match and (mate.status == "open" or mate.status == "locked") then
			claimed[mate.selected] = true
		end
	end
	local key = pick.match or AgentSelect.FREE
	if botPicked[id] ~= key or claimed[pick.selected] then
		local free: { string } = {}
		for _, agent in state.agents do
			if not claimed[agent] then
				table.insert(free, agent)
			end
		end
		if #free > 0 then
			AgentSelect.select(state, id, free[dice:NextInteger(1, #free)])
		end
		botPicked[id] = key
	end
	return if pick.status == "free" then AgentSelect.lock(state, id) else nil
end

-- Whether a player's or a bot's agent is locked in for the side of the
-- match they're on (AgentSelect.settled): a bot's charges wait for it
-- (Arena), so none are bought into a kit it's about to leave.
function AgentServer.settled(holder: Instance, id: number): boolean
	local momentOf = AgentServer.momentOf
	return momentOf ~= nil and AgentSelect.settled(state, id, momentOf(holder, id))
end

-- Tells clients a player's pick, when it's changed.
local function publish(player: Instance, id: number)
	local pick = AgentSelect.pickOf(state, id)
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
			apply(player, player.UserId, changed, Workspace:GetServerTimeNow())
		end
	end
	publish(player, player.UserId)
end

-- Once a server frame, after the arena's rounds have moved on: every pick
-- as where its player is says, all together and in the server's order of
-- players (AgentSelect.step), a window opening or closing, and an agent
-- locked in as one closes put on their kit.
function AgentServer.step(time: number)
	local momentOf = AgentServer.momentOf
	local away = AgentServer.away
	local ids: { number } = {}
	local holders: { [number]: Instance } = {}
	for _, player in Players:GetPlayers() do
		if away and away(player.UserId) then
			continue
		end
		table.insert(ids, player.UserId)
		holders[player.UserId] = player
	end
	-- The bots after every player (system 65), and the picks of those gone
	-- with them.
	local bots: { [number]: Instance } = {}
	for _, id in BotServer.ids() do
		local standIn = BotServer.standIn(id)
		if standIn then
			table.insert(ids, id)
			holders[id] = standIn
			bots[id] = standIn
		end
	end
	for id, standIn in botIds do
		if bots[id] ~= standIn then
			AgentSelect.leave(state, id)
			botPicked[id] = nil
			shown[standIn] = nil
		end
	end
	botIds = bots
	local moments: { [number]: string? } = {}
	for _, id in ids do
		moments[id] = if momentOf then momentOf(holders[id], id) else AgentSelect.FREE
	end
	local changed = AgentSelect.step(state, ids, moments, time)
	for _, id in ids do
		if bots[id] then
			changed[id] = botSelect(id) or changed[id]
		end
		-- Back in a match with their pick kept (system 69): the agent they
		-- locked in before they went, on the kit they're back with.
		local pick = AgentSelect.pickOf(state, id)
		if not bots[id] and pick.status == "locked" and onKit[holders[id]] ~= pick.agent then
			changed[id] = changed[id] or pick.agent
		end
		local agent = changed[id]
		if agent then
			apply(holders[id], id, agent, time)
		end
		publish(holders[id], id)
	end
end

-- A pick kept for a player who left (system 69) let go, their place no
-- longer held, unless they're back.
function AgentServer.forget(id: number)
	if not Players:GetPlayerByUserId(id) then
		AgentSelect.leave(state, id)
	end
end

function AgentServer.start()
	Remotes.get().AgentPick.OnServerEvent:Connect(onPick)
	Players.PlayerRemoving:Connect(function(player: Player)
		local keeps = AgentServer.keeps
		if not (keeps and keeps(player.UserId)) then
			AgentSelect.leave(state, player.UserId)
		end
		shown[player] = nil
		onKit[player] = nil
	end)
end

return AgentServer
