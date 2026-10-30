--!strict
-- The Play menu's modes, and the servers that play them (system 24): as
-- Counter Blox's main screen has it, each mode is played on servers of its
-- own, and PLAY drops you into the match on this server if it plays the mode
-- you picked, or sends you to one that does with a place free. Same status
-- convention as ArenaConfig.
--
-- No Roblox APIs here, so it runs in Studio and in the offline tests.

local ArenaConfig = require("../Arena/ArenaConfig")
local DeathmatchConfig = require("../Arena/DeathmatchConfig")
local GunGameConfig = require("../Arena/GunGameConfig")
local TeamDeathmatchConfig = require("../Arena/TeamDeathmatchConfig")
local MatchConfig = require("./MatchConfig")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

-- A mode on the menu: what the arena plays for it (Workspace's
-- ArenaConfig.MODE, and for the spike rounds MatchConfig.FORMAT), and how
-- many play its match at once: two sides of its side size, or in a free for
-- all everyone it has room for. More can be on its server, waiting in line
-- or in the menu.
export type Mode = {
	key: string, -- the menu's and the server list's name for it
	name: string,
	blurb: string, -- how it's won, in a line
	arena: string,
	format: string?,
	players: number,
	freeForAll: boolean?, -- everyone for themselves, with no sides
}

local PlayConfig = {}

local SKIRMISH = ArenaConfig.Rules.sideSize.value
local GUN_GAME = GunGameConfig.Rules.sideSize.value
local TEAM_DEATHMATCH = TeamDeathmatchConfig.Rules.sideSize.value
local SPIKE = MatchConfig.Rules.sideSize.value
local F = MatchConfig.Formats

-- In the menu's order. The spike rounds' formats are the reference's own
-- queues, by its names for them: Standard is Unrated. Each blurb is from
-- the rules it names, so it stays true to them.
PlayConfig.Modes = {
	{
		key = "skirmish",
		name = "Skirmish",
		blurb = string.format("Rounds of one life each: first to %d wins", ArenaConfig.Rules.winScore.value),
		arena = "skirmish",
		players = 2 * SKIRMISH,
	},
	{
		key = "duel",
		name = "Duel",
		blurb = string.format("One on one, a life a round: first to %d wins", ArenaConfig.Duel.winScore.value),
		arena = "duel",
		players = 2 * ArenaConfig.Duel.sideSize.value,
	},
	{
		key = "gungame",
		name = "Gun Game",
		blurb = string.format("A new gun with each kill, %d in all: a kill with the knife wins", #GunGameConfig.Tiers),
		arena = "gungame",
		players = 2 * GUN_GAME,
	},
	{
		key = "deathmatch",
		name = "Deathmatch",
		blurb = string.format(
			"Everyone for themselves: first to %d kills, or the most in %d minutes",
			DeathmatchConfig.Rules.killTarget.value,
			DeathmatchConfig.Rules.timeLimit.value // 60
		),
		arena = "deathmatch",
		players = DeathmatchConfig.Rules.players.value,
		freeForAll = true,
	},
	{
		key = "teamdeathmatch",
		name = "Team Deathmatch",
		blurb = string.format(
			"Two sides, a new loadout each stage: the first to %d kills wins",
			TeamDeathmatchConfig.Rules.killTarget.value
		),
		arena = "teamdeathmatch",
		players = 2 * TEAM_DEATHMATCH,
	},
	{
		key = "standard",
		name = "Unrated",
		blurb = string.format("Plant the spike or defuse it: first to %d rounds", F.standard.winScore.value),
		arena = "spike",
		format = "standard",
		players = 2 * SPIKE,
	},
	{
		key = "competitive",
		name = "Competitive",
		blurb = string.format(
			"First to %d rounds, and from %d-%d, won by two",
			F.competitive.winScore.value,
			F.competitive.winScore.value - 1,
			F.competitive.winScore.value - 1
		),
		arena = "spike",
		format = "competitive",
		players = 2 * SPIKE,
	},
	{
		key = "swiftplay",
		name = "Swiftplay",
		blurb = string.format("Plant the spike or defuse it: first to %d rounds", F.swiftplay.winScore.value),
		arena = "spike",
		format = "swiftplay",
		players = 2 * SPIKE,
	},
} :: { Mode }

PlayConfig.ByKey = {} :: { [string]: Mode }
for _, mode in PlayConfig.Modes do
	PlayConfig.ByKey[mode.key] = mode
end

-- What a server started by Roblox's own Play button plays (ours: Skirmish,
-- as the arena has from system 21).
PlayConfig.DEFAULT = "skirmish"

-- The mode Workspace's attributes ask the arena for, as given (the arena
-- on, its mode and the spike rounds' format); nil with the arena off.
function PlayConfig.keyOf(on: any, arenaMode: any, format: any): string?
	if on ~= true then
		return nil
	elseif arenaMode == "spike" then
		return if typeof(format) == "string" and PlayConfig.ByKey[format] then format else MatchConfig.DEFAULT_FORMAT
	elseif arenaMode == "duel" or arenaMode == "gungame" or arenaMode == "deathmatch" or arenaMode == "teamdeathmatch" then
		return arenaMode
	end
	return "skirmish"
end

-- Workspace's attribute for whether players start in the menu, joining a
-- match only once they press PLAY (on from the start on a live server, in
-- Studio as the place has it as the server starts), and for how many are
-- in servers playing each mode ("skirmish=6,gungame=3"), for the menu.
PlayConfig.MENU = "VFPlayMenu"
PlayConfig.COUNTS = "VFModeCounts"
-- A player's attribute: true once they've pressed PLAY for what this server
-- plays, or arrived having pressed it elsewhere, so they're in it or will be
-- as it starts.
PlayConfig.PLAYING = "VFPlaying"
-- The teleport data's key for the mode a server is reserved for.
PlayConfig.DATA_KEY = "vfMode"
-- The memory store sorted map that lists the servers.
PlayConfig.LIST = "VFModeServers"

PlayConfig.Rules = {
	refresh = p(15, "estimate", "Seconds between each server's updates of its line in the list (ours)"),
	soonest = p(
		2,
		"estimate",
		"Seconds at the least between a server's updates of its line, when someone has come, gone or joined its match (ours)"
	),
	expiry = p(
		60,
		"estimate",
		"Seconds a line lasts without an update, so a server gone without a word drops out (ours; a memory store item can last"
			.. " up to 3,888,000 s, 45 days: Roblox, 'Memory stores')"
	),
	stale = p(45, "estimate", "Seconds after which a line not updated isn't trusted to send anyone to (ours)"),
	listEvery = p(20, "estimate", "Seconds between reads of the whole list, for the menu's counts (ours)"),
	cooldown = p(3, "estimate", "Seconds a player waits between presses of PLAY that send them away (ours)"),
	teleportWait = p(30, "estimate", "Seconds a teleport asked for is waited on before it's given up (ours)"),
}

return PlayConfig
