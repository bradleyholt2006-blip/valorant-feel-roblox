--!strict
-- Each player's career (system 67): what's kept of them from one session to
-- the next (CareerServer's data store). Their Competitive rank (RankRules),
-- and for each mode on the Play menu their matches won, lost and drawn,
-- and their kills, deaths, assists, combat score and rounds in them all.
--
-- A match counts for each player in it as it ends (CareerRules.results):
-- in a mode of rounds, for those who played half its rounds or more to
-- their end, so joining a match near its end isn't a match played, and in
-- the others for everyone in it then. Leaving a Competitive match under
-- way, with a round of it played to its end, counts as a loss as it stands
-- (CareerRules.left). Bots have no career, but in Competitive each counts
-- at its MMR (RankConfig.BotMmr) in its side's.
--
-- Each result has an id, kept with the last few applied, so a result
-- written twice is counted once.
--
-- No Roblox APIs here.

local PlayConfig = require("../Match/PlayConfig")
local RankConfig = require("./RankConfig")
local RankRules = require("./RankRules")

export type Totals = {
	matches: number,
	wins: number,
	losses: number,
	draws: number,
	kills: number,
	deaths: number,
	assists: number,
	score: number, -- combat score, every round
	rounds: number,
}

export type Record = {
	rank: RankRules.Rank,
	modes: { [string]: Totals }, -- by PlayConfig key
	seen: { string }, -- the ids of the last results applied, newest last
}

-- A player's part in a match: its id, the mode (a PlayConfig key), how it
-- went, their record in it, and in Competitive what bears on their rank.
export type Result = {
	id: string,
	mode: string,
	outcome: RankRules.Outcome,
	kills: number,
	deaths: number,
	assists: number,
	score: number,
	rounds: number,
	ranked: RankRules.Match?,
}

-- Someone in a match, by the record the rules keep (Roster.Member): their
-- side (in deathmatch one of their own), and whether they're a bot.
export type Player = {
	side: number,
	kills: number,
	deaths: number,
	assists: number,
	score: number,
	rounds: number,
	bot: boolean,
}

-- A match, as it ends or as someone leaves it: its mode (a PlayConfig key),
-- the side that won (nil for a draw or while it's played), each side's
-- score, the rounds played (none in a mode without them) and the rounds
-- that win it, and everyone in it by their id in the rules.
export type Match = {
	mode: string,
	winner: number?,
	score: { number },
	rounds: number,
	winScore: number,
	players: { [number]: Player },
}

-- An MMR for each player, by their id: a bot's by its skill.
export type MmrOf = (id: number, player: Player) -> number

local CareerRules = {}

-- The mode whose matches move a rank.
CareerRules.RANKED = "competitive"
-- How many results' ids are kept.
CareerRules.SEEN = 16
-- The player attribute the server keeps each player's totals in, for
-- clients (CareerRules.toText), and how keeping their career goes:
-- "loading", "loaded", "new", "saving", "saved", or "off: " and why.
CareerRules.ATTRIBUTE = "VFCareer"
CareerRules.STATUS = "VFCareerStatus"

local FIELDS = { "matches", "wins", "losses", "draws", "kills", "deaths", "assists", "score", "rounds" }

function CareerRules.newTotals(): Totals
	return { matches = 0, wins = 0, losses = 0, draws = 0, kills = 0, deaths = 0, assists = 0, score = 0, rounds = 0 }
end

function CareerRules.new(): Record
	return { rank = RankRules.new(), modes = {}, seen = {} }
end

-- A combat score a round; none for no rounds.
local function perRound(p: Player): number
	return if p.rounds > 0 then p.score / p.rounds else 0
end

-- Someone's part in a match, `outcome` for them, with what bears on their
-- rank in Competitive.
local function resultFor(match: Match, id: number, outcome: RankRules.Outcome, mmrOf: MmrOf, newId: () -> string): Result
	local p = match.players[id]
	local ranked: RankRules.Match? = nil
	if match.mode == CareerRules.RANKED then
		local team, enemy, teamN, enemyN = 0, 0, 0, 0
		local all, allN = 0, 0
		for other, q in match.players do
			if q.side == p.side then
				team += mmrOf(other, q)
				teamN += 1
			else
				enemy += mmrOf(other, q)
				enemyN += 1
			end
			if q.rounds > 0 then
				all += perRound(q)
				allN += 1
			end
		end
		local average = if allN > 0 then all / allN else 0
		ranked = {
			outcome = outcome,
			team = team / teamN,
			enemy = if enemyN > 0 then enemy / enemyN else team / teamN,
			perf = if average > 0 then perRound(p) / average else 1,
			margin = (match.score[p.side] or 0) - (match.score[3 - p.side] or 0),
			winScore = match.winScore,
		}
	end
	return {
		id = newId(),
		mode = match.mode,
		outcome = outcome,
		kills = p.kills,
		deaths = p.deaths,
		assists = p.assists,
		score = p.score,
		rounds = p.rounds,
		ranked = ranked,
	}
end

-- Each player's part in a match just ended, by their id: for every player
-- it counts for (none for bots).
function CareerRules.results(match: Match, mmrOf: MmrOf, newId: () -> string): { [number]: Result }
	local out = {}
	for id, p in match.players do
		if p.bot or (match.rounds > 0 and p.rounds * 2 < match.rounds) then
			continue
		end
		local outcome: RankRules.Outcome = if match.winner == nil then "draw" elseif p.side == match.winner then "won" else "lost"
		out[id] = resultFor(match, id, outcome, mmrOf, newId)
	end
	return out
end

-- The part of someone leaving a match under way: a loss in Competitive,
-- once they've played a round of it to its end (the reference: 'Going AFK
-- or queue dodging in Competitive games for a prolonged period of time will
-- affect your RR', by how much it doesn't say); nothing anywhere else.
function CareerRules.left(match: Match, id: number, mmrOf: MmrOf, newId: () -> string): Result?
	local p = match.players[id]
	if match.mode ~= CareerRules.RANKED or not p or p.bot or p.rounds < 1 then
		return nil
	end
	return resultFor(match, id, "lost", mmrOf, newId)
end

-- A result added to a record, once: its mode's totals, and in Competitive
-- the rank. Changes `record`, and returns what the match did to the rank,
-- if it moved one.
function CareerRules.apply(record: Record, result: Result): RankRules.Change?
	if table.find(record.seen, result.id) then
		return nil
	end
	table.insert(record.seen, result.id)
	while #record.seen > CareerRules.SEEN do
		table.remove(record.seen, 1)
	end
	local totals = record.modes[result.mode]
	if not totals then
		totals = CareerRules.newTotals()
		record.modes[result.mode] = totals
	end
	totals.matches += 1
	if result.outcome == "won" then
		totals.wins += 1
	elseif result.outcome == "lost" then
		totals.losses += 1
	else
		totals.draws += 1
	end
	totals.kills += result.kills
	totals.deaths += result.deaths
	totals.assists += result.assists
	totals.score += result.score
	totals.rounds += result.rounds
	local ranked = result.ranked
	return if ranked then RankRules.apply(record.rank, ranked) else nil
end

-- A number from the store, if it's a whole one from `low` to `high`; else
-- `default`.
local function whole(value: any, low: number, high: number, default: number): number
	if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then
		return default
	end
	return math.clamp(value, low, high)
end

-- A record from whatever the store holds: a new one for nothing, or for
-- anything not a record; anything out of its bounds put back in them.
function CareerRules.decode(value: any): Record
	local record = CareerRules.new()
	if type(value) ~= "table" or value.v ~= 1 then
		return record
	end
	local rank = value.rank
	if type(rank) == "table" then
		local r = record.rank
		local mmr = rank.mmr
		r.mmr = if type(mmr) == "number" and mmr == mmr then math.clamp(mmr, -10000, 10000) else r.mmr
		r.games = whole(rank.games, 0, 1e9, 0)
		r.tier = whole(rank.tier, 0, RankConfig.IMMORTAL, 0)
		local most = if r.tier >= RankConfig.IMMORTAL then 1e9 else RankConfig.Rules.perTier.value - 1
		r.rr = if r.tier == 0 then 0 else whole(rank.rr, 0, most, 0)
		r.shields = whole(rank.shields, 0, RankConfig.Rules.shields.value, 0)
	end
	if type(value.modes) == "table" then
		for key, totals in value.modes do
			if type(key) ~= "string" or not PlayConfig.ByKey[key] or type(totals) ~= "table" then
				continue
			end
			local t = CareerRules.newTotals()
			for _, field in FIELDS do
				(t :: any)[field] = whole(totals[field], 0, 1e12, 0)
			end
			record.modes[key] = t
		end
	end
	if type(value.seen) == "table" then
		for _, id in value.seen do
			if type(id) == "string" and #id <= 64 and #record.seen < CareerRules.SEEN then
				table.insert(record.seen, id)
			end
		end
	end
	return record
end

-- A record as the store keeps it.
function CareerRules.encode(record: Record): { [string]: any }
	local r = record.rank
	local modes = {}
	for key, totals in record.modes do
		modes[key] = table.clone(totals)
	end
	return {
		v = 1,
		rank = { mmr = r.mmr, games = r.games, tier = r.tier, rr = r.rr, shields = r.shields },
		modes = modes,
		seen = table.clone(record.seen),
	}
end

-- Every mode's totals in a line, for clients:
-- "competitive=3,2,1,0,45,30,10,2100,25;skirmish=...", the numbers in
-- Totals' order (matches, wins, losses, draws, kills, deaths, assists,
-- score, rounds), in PlayConfig's order of the modes.
function CareerRules.toText(record: Record): string
	local parts = {}
	for _, mode in PlayConfig.Modes do
		local totals = record.modes[mode.key]
		if totals then
			local numbers = {}
			for _, field in FIELDS do
				table.insert(numbers, string.format("%d", (totals :: any)[field]))
			end
			table.insert(parts, mode.key .. "=" .. table.concat(numbers, ","))
		end
	end
	return table.concat(parts, ";")
end

-- The totals in a line from CareerRules.toText, by mode; any part broken
-- is left out.
function CareerRules.fromText(text: any): { [string]: Totals }
	local out = {}
	if type(text) ~= "string" then
		return out
	end
	for key, numbers in string.gmatch(text, "(%w+)=([%d,]+)") do
		local values = string.split(numbers :: string, ",")
		if not PlayConfig.ByKey[key] or #values ~= #FIELDS then
			continue
		end
		local t = CareerRules.newTotals()
		for i, field in FIELDS do
			(t :: any)[field] = tonumber(values[i]) or 0
		end
		out[key] = t
	end
	return out
end

-- A mode's totals in a line for the Play menu: matches won and lost (and
-- drawn, if any), and kills a death.
function CareerRules.summary(t: Totals): string
	local drawn = if t.draws > 0 then string.format(" %dD", t.draws) else ""
	return string.format("%dW %dL%s   %.2f K/D", t.wins, t.losses, drawn, t.kills / math.max(t.deaths, 1))
end

return CareerRules
