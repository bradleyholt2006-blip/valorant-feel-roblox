--!strict
-- Who an entity in the snapshots is, on this client: a player or a bot
-- (system 60). A bot has a stand-in in ReplicatedStorage's BotConfig.FOLDER,
-- a Configuration named the bot's name ("BOT Ash") that carries its entity
-- id and its id in the rules (BotConfig.ENTITY and ID), and whatever the
-- arena keeps on a player for clients, as attributes of the same names: its
-- side, its record and its guns. The views that name, colour, count and
-- follow who's playing ask here, so a bot is named, coloured, counted and
-- followed as a player is.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local BotConfig = require(Shared.Bots.BotConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)

local Who = {}

-- Someone who plays, a player or a bot: their id in the rules (a player's
-- UserId, or a bot's, PlayerCodec.botRuleId), their entity id, the name
-- shown for them, and what carries their attributes (the Player, or the
-- bot's stand-in).
export type Someone = { id: number, entity: number, name: string, holder: Instance, player: Player? }

-- The player whose entity it is.
function Who.player(entity: number): Player?
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == entity then
			return player
		end
	end
	return nil
end

-- The stand-ins of the bots there are.
local function standIns(): { Instance }
	local folder = ReplicatedStorage:FindFirstChild(BotConfig.FOLDER)
	return if folder then folder:GetChildren() else {}
end

-- A bot's stand-in, by its entity id.
function Who.bot(entity: number): Instance?
	if not PlayerCodec.isBot(entity) then
		return nil
	end
	for _, standIn in standIns() do
		if standIn:GetAttribute(BotConfig.ENTITY) == entity then
			return standIn
		end
	end
	return nil
end

-- What carries someone's attributes: their Player, or a bot's stand-in.
function Who.holder(entity: number): Instance?
	return Who.player(entity) or Who.bot(entity)
end

-- The name shown for someone: a player's display name, or a bot's own; nil
-- for anyone else.
function Who.name(entity: number): string?
	local player = Who.player(entity)
	if player then
		return player.DisplayName
	end
	local bot = Who.bot(entity)
	return if bot then bot.Name else nil
end

-- The side someone's on in the arena, while they're on one.
function Who.side(entity: number): number?
	local holder = Who.holder(entity)
	local side = if holder then holder:GetAttribute(ArenaConfig.SIDE) else nil
	return if typeof(side) == "number" then side else nil
end

-- Whether someone's on this client's player's side.
function Who.ally(entity: number): boolean
	local mine = Players.LocalPlayer:GetAttribute(ArenaConfig.SIDE)
	return typeof(mine) == "number" and Who.side(entity) == mine
end

-- Someone who plays, by their id in the rules.
function Who.find(id: number): Someone?
	for _, someone in Who.all() do
		if someone.id == id then
			return someone
		end
	end
	return nil
end

-- A name without the bots' "BOT " (BotConfig.PREFIX), for its first two
-- letters (Glance.badge).
function Who.plain(name: string): string
	local prefix = BotConfig.PREFIX
	return if string.sub(name, 1, #prefix) == prefix then string.sub(name, #prefix + 1) else name
end

-- Every player, and every bot.
function Who.all(): { Someone }
	local out: { Someone } = {}
	for _, player in Players:GetPlayers() do
		local id = player.UserId
		table.insert(
			out,
			{ id = id, entity = PlayerCodec.entityIdForUser(id), name = player.DisplayName, holder = player, player = player }
		)
	end
	for _, standIn in standIns() do
		local id, entity = standIn:GetAttribute(BotConfig.ID), standIn:GetAttribute(BotConfig.ENTITY)
		if typeof(id) == "number" and typeof(entity) == "number" then
			table.insert(out, { id = id, entity = entity, name = standIn.Name, holder = standIn, player = nil })
		end
	end
	return out
end

return Who
