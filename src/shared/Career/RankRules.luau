--!strict
-- What a Competitive match does to a player's rank (system 67), by the
-- reference's published rules (RankConfig):
--   * a hidden MMR, Elo's rating on the ranks' own scale, moves with every
--     match by how far it went from what the two sides' MMRs expected
--   * the first 5 matches place the player: after the fifth, at the tier
--     their MMR stands at (Ascendant 3 at most) with 50 RR
--   * after that a win gains RR and a loss loses it: more for a win and
--     less for a loss the further the MMR is over the rank, and the other
--     way under it, then a little for their own play (below Immortal), how
--     much the match was won or lost by, and being the underdog; held to
--     10 to 50 for a win and 0 to 30 for a loss, 5 to 50 and 0 to 50 from
--     Diamond up. A draw gains up to 20 on play alone, below Immortal
--   * 100 RR promotes, with what's over and 10 RR at the least; a loss at
--     0 RR demotes, to 70 RR at the least, and a loss short of 0 stops
--     there. Entering a rank's Tier 1 by either gives 2 shields, each of
--     which takes a loss at 0 RR in it instead of the rank
--   * from Immortal RR goes on past 100, and Immortal 2, Immortal 3 and
--     Radiant are RR thresholds
--   * and ours: a win can't take the rank more than a tier over its MMR,
--     as bots fill matches here and nothing evens the sides
--
-- No Roblox APIs here.

local RankConfig = require("./RankConfig")

local R = RankConfig.Rules

export type Outcome = "won" | "lost" | "draw"

-- A player's rank as it's kept: the hidden MMR, the Competitive matches
-- played, the tier (0 while placing, Immortal 1 at most: RankRules.shown
-- is the tier shown), its RR, and the shields left.
export type Rank = { mmr: number, games: number, tier: number, rr: number, shields: number }

-- A match as it bears on someone's rank: how it went for them; their
-- side's MMR and the other's (each its players' average); their combat
-- score a round over the match's average (1 for average); and the rounds
-- their side won less the other's, with the rounds a match is won by.
export type Match = { outcome: Outcome, team: number, enemy: number, perf: number, margin: number, winScore: number }

-- What came of a match besides its RR.
export type Note = "placed" | "promoted" | "demoted" | "shielded"
-- What a match did: the RR it was worth (less than 0 for a loss, 0 while
-- placing), and anything else that came of it.
export type Change = { rr: number, note: Note? }

local RankRules = {}

function RankRules.new(): Rank
	return { mmr = R.mmrStart.value, games = 0, tier = 0, rr = 0, shields = 0 }
end

-- The chance a side of MMR `team` beats one of MMR `enemy` (Elo's).
function RankRules.expected(team: number, enemy: number): number
	return 1 / (1 + 10 ^ ((enemy - team) / R.spread.value))
end

-- Where a rank stands on the MMR's scale: 100 a tier from Iron 1 at 0,
-- and its RR.
function RankRules.position(rank: Rank): number
	return (rank.tier - 1) * R.perTier.value + rank.rr
end

-- The tier shown: as kept, but in Immortal its second and third tiers and
-- Radiant, by the RR.
function RankRules.shown(rank: Rank): number
	local shown = rank.tier
	if shown >= RankConfig.IMMORTAL then
		for i, threshold in RankConfig.Immortal do
			if rank.rr >= threshold.value then
				shown = RankConfig.IMMORTAL + i
			end
		end
	end
	return shown
end

-- A rank's Tier 1, from Bronze to Ascendant, where shields keep the rank.
local function firstTier(tier: number): boolean
	return tier % 3 == 1 and tier > 1 and tier < RankConfig.IMMORTAL
end

-- Into another tier by a promotion or a demotion: 2 shields in a Tier 1,
-- none to use anywhere else.
local function enter(rank: Rank, tier: number)
	rank.tier = tier
	rank.shields = if firstTier(tier) then R.shields.value else 0
end

-- What a match is worth in RR to a rank placed, by the MMR moved for it,
-- with `expected` the chance its side had of winning.
local function worth(rank: Rank, match: Match, expected: number): number
	local upper = rank.tier >= RankConfig.IMMORTAL
	local diamond = rank.tier >= RankConfig.DIAMOND
	local position = RankRules.position(rank)
	local shift = (rank.mmr - position) * R.gapRR.value
	local play = if upper then 0 else math.clamp((match.perf - 1) * R.perfScale.value, -R.perfMax.value, R.perfMax.value)
	local margin = R.marginMax.value * math.min(math.abs(match.margin), match.winScore) / math.max(match.winScore, 1)
	local underdog = R.underdogMax.value * (1 - 2 * expected)
	local gain: number
	if match.outcome == "won" then
		gain = math.clamp(
			R.base.value + shift + play + margin + underdog,
			if diamond then R.diamondWinMin.value else R.winMin.value,
			R.winMax.value
		)
	elseif match.outcome == "lost" then
		local loss = R.base.value - shift - play + margin - underdog
		return -math.clamp(loss, 0, if diamond then R.diamondLossMax.value else R.lossMax.value)
	elseif upper then
		return 0
	else
		gain = math.clamp(R.drawMax.value / 2 * (1 + play / R.perfMax.value), 0, R.drawMax.value)
	end
	-- Not more than a tier over the MMR.
	return math.min(gain, math.max(rank.mmr + R.overMmr.value - position, 0))
end

-- A match played: the MMR moved, and the placement it finishes or the RR it
-- was worth. Changes `rank`, and returns what changed.
function RankRules.apply(rank: Rank, match: Match): Change
	local expected = RankRules.expected(match.team, match.enemy)
	local result = if match.outcome == "won" then 1 elseif match.outcome == "lost" then 0 else 0.5
	local placing = rank.tier == 0
	rank.mmr += (if placing then R.kPlacing.value else R.k.value) * (result - expected)
	rank.games += 1
	if placing then
		if rank.games < R.placements.value then
			return { rr = 0, note = nil }
		end
		-- Placed: no shields, as they come with a promotion or a demotion.
		rank.tier = math.clamp(math.floor(rank.mmr / R.perTier.value) + 1, 1, R.topPlacement.value)
		rank.rr = R.placedRR.value
		rank.shields = 0
		return { rr = 0, note = "placed" }
	end
	local rr = math.round(worth(rank, match, expected))
	if rr > 0 then
		rank.rr += rr
		if rank.tier < RankConfig.IMMORTAL and rank.rr >= R.perTier.value then
			enter(rank, rank.tier + 1)
			rank.rr = math.max(rank.rr - R.perTier.value, R.promoteBuffer.value)
			return { rr = rr, note = "promoted" }
		end
	elseif rr < 0 then
		if rank.rr > 0 then
			rank.rr = math.max(rank.rr + rr, 0)
		elseif firstTier(rank.tier) and rank.shields > 0 then
			rank.shields -= 1
			return { rr = rr, note = "shielded" }
		elseif rank.tier > 1 then
			enter(rank, rank.tier - 1)
			rank.rr = math.max(R.perTier.value + rr, R.demoteFloor.value)
			return { rr = rr, note = "demoted" }
		end
	end
	return { rr = rr, note = nil }
end

-- The placements left to play: none once placed.
function RankRules.placementsLeft(rank: Rank): number
	return if rank.tier == 0 then math.max(R.placements.value - rank.games, 0) else 0
end

-- A rank in a line, from what clients have of it (RankConfig's player
-- attributes): the tier shown and its RR, or the placements played.
function RankRules.line(tier: number, rr: number, games: number): string
	if tier == 0 then
		return string.format("PLACEMENTS %d/%d", math.min(games, R.placements.value), R.placements.value)
	end
	return string.format("%s   %d RR", string.upper(RankConfig.name(tier)), rr)
end

-- What the last match did to a rank, in a line for the victory screen:
-- with the rank after it, the RR it was worth (`last`) and what else came
-- of it (`note`, a Note or nil).
function RankRules.verdict(tier: number, rr: number, games: number, shields: number, last: number, note: string?): string
	if tier == 0 then
		return string.format("PLACEMENT %d OF %d", math.min(games, R.placements.value), R.placements.value)
	end
	local line = RankRules.line(tier, rr, games)
	local amount = string.format("%s%d", if last < 0 then "-" else "+", math.abs(last))
	if note == "placed" then
		return "PLACED   " .. line
	elseif note == "promoted" then
		return string.format("PROMOTED   %s   (%s)", line, amount)
	elseif note == "demoted" then
		return string.format("DEMOTED   %s   (%s)", line, amount)
	elseif note == "shielded" then
		return string.format("%s   (%s, A SHIELD KEPT THE RANK: %d LEFT)", line, amount, shields)
	end
	return string.format("%s   (%s)", line, amount)
end

return RankRules
