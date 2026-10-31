--!strict
-- Competitive's ranks (system 67), as the reference's: Iron to Ascendant,
-- three tiers each of 100 RR (Rank Rating), then Immortal, where RR goes on
-- counting and reaches Immortal's second and third tiers and Radiant. What
-- a match is worth in RR, and the hidden matchmaking rating (MMR) that
-- goes by, are RankRules'. Same status convention as ArenaConfig.
--
-- No Roblox APIs here, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local RankConfig = {}

local LOWER = "Riot, 'Rank Rating (RR) for Iron through Ascendant Ranks' (support article)"
local UPPER = "Riot, 'Rank Rating (RR) for Immortal and Radiant Ranks' (support article)"
local EP2 = "Riot, 'VALORANT Episode 2 Act I Competitive Changes' (playvalorant.com)"

-- The tiers in order: Tiers[1] is Iron 1, Tiers[22] Immortal 1 and
-- Tiers[25] Radiant.
RankConfig.RANKS = { "Iron", "Bronze", "Silver", "Gold", "Platinum", "Diamond", "Ascendant", "Immortal" }
RankConfig.Tiers = {} :: { string }
for _, rank in RankConfig.RANKS do
	for tier = 1, 3 do
		table.insert(RankConfig.Tiers, rank .. " " .. tier)
	end
end
table.insert(RankConfig.Tiers, "Radiant")

-- Tiers by their numbers: Diamond 1, from which a win gains less at the
-- least and a loss can lose more, and Immortal 1, from which RR goes on
-- past 100.
RankConfig.DIAMOND = 16
RankConfig.IMMORTAL = 22

RankConfig.Rules = {
	placements = p(5, "confirmed", LOWER .. ": 'all players need to play 5 placement matches to be placed'"),
	topPlacement = p(21, "confirmed", LOWER .. ": 'with Ascendant 3 being the highest initial placement' (tier 21)"),
	placedRR = p(50, "confirmed", LOWER .. ": 'After being placed, you'll start off with 50 RR in your determined rank'"),
	perTier = p(100, "confirmed", LOWER .. ": 'and will need 100 RR to promote'"),
	promoteBuffer = p(10, "confirmed", LOWER .. ": 'you'll start the next rank with a minimum 10 RR buffer'"),
	demoteFloor = p(70, "confirmed", LOWER .. ": 'The lowest you can start in the next tier down after being demoted is 70 RR'"),
	shields = p(
		2,
		"confirmed",
		LOWER
			.. ": 'Whenever you enter Tier 1 of a rank (i.e. Bronze 1, Silver 1, etc.) through either promotion or demotion', '2 Rank Shields'"
	),
	winMin = p(10, "confirmed", EP2 .. ": 'On a win, you will gain between 10 and 50 RR'"),
	winMax = p(50, "confirmed", EP2 .. ": 'On a win, you will gain between 10 and 50 RR'"),
	lossMax = p(30, "confirmed", EP2 .. ": 'On a loss you will lose between 0 and 30 RR'"),
	diamondWinMin = p(5, "confirmed", EP2 .. ": 'Min 5 RR gain for Diamond+'"),
	diamondLossMax = p(50, "confirmed", EP2 .. ": 'Max drop of 50 RR on a loss for Diamond+'"),
	drawMax = p(20, "confirmed", EP2 .. ": 'On a draw you will gain a max of 20 RR (performance-based)'"),
	-- How much a match is worth inside those bounds: what moves it is
	-- public (LOWER: 'How much RR you gain or lose is affected by how close
	-- your rank is to your MMR'; 'How much you win by, extraordinary plays,
	-- and whether or not you're the underdog in a match can all have an
	-- effect'), by how much isn't.
	base = p(20, "estimate", "RR a win gains and a loss loses with the rank level with its MMR, before the rest (ours)"),
	gapRR = p(
		0.05,
		"estimate",
		"RR more a win gains, and less a loss loses, for each point of MMR above the rank (ours: 5 a tier, so a win's 10 to 50 spans MMR two tiers under the rank to six over)"
	),
	perfMax = p(
		5,
		"estimate",
		"Most RR the player's own play adds to a win or takes off a loss, below Immortal (ours; LOWER: 'it'll be your performance under review', and in Immortal and Radiant RR is 'completely reliant on the outcome of the match': UPPER)"
	),
	perfScale = p(10, "estimate", "RR for a combat score a round as far again over the match's average as the average itself (ours)"),
	marginMax = p(5, "estimate", "Most RR how much a match is won or lost by adds to it: a whole match's rounds to none (ours)"),
	underdogMax = p(5, "estimate", "Most RR being the underdog adds to a win or takes off a loss, with no chance at all of winning (ours)"),
	-- The hidden MMR: Elo's rating, on the ranks' scale, a tier 100 from Iron
	-- 1's 0 (ours: the reference keeps its own to itself).
	mmrStart = p(800, "estimate", "A new player's MMR: Silver 3 with no RR, about the middle of the ranks (ours)"),
	spread = p(
		400,
		"estimate",
		"MMR between two sides for the higher to be expected to win 10 times in 11: Elo's 400, so four tiers (ours)"
	),
	k = p(40, "estimate", "MMR a match moves, times how far it went from what was expected (ours)"),
	kPlacing = p(80, "estimate", "The same in placements, to find a new player's level sooner (ours)"),
	overMmr = p(
		100,
		"estimate",
		"Most a win takes the rank over its MMR: bots fill matches here and nothing evens the sides, so beating weaker bots over and over can't climb past a player's level (ours)"
	),
}

-- The RR in Immortal that reaches Immortal 2, Immortal 3 and Radiant: the
-- reference's thresholds for North America, one region of five. Radiant
-- there is also 'one of the top 500 players in your region' (UPPER), which
-- a server of ours has no leaderboard for.
RankConfig.Immortal = {
	p(90, "confirmed", UPPER .. ": NA's Immortal 2 threshold"),
	p(200, "confirmed", UPPER .. ": NA's Immortal 3 threshold"),
	p(450, "confirmed", UPPER .. ": NA's Radiant threshold"),
}

-- A bot's MMR, by its skill (BotConfig.Skills), for its side's MMR (ours:
-- five tiers apart, Normal at a new player's).
RankConfig.BotMmr = {
	easy = p(300, "estimate", "Bronze 1 (ours)"),
	normal = p(800, "estimate", "Silver 3, a new player's MMR (ours)"),
	hard = p(1300, "estimate", "Platinum 2 (ours)"),
	expert = p(1800, "estimate", "Ascendant 1 (ours)"),
} :: { [string]: Param }

-- The player attributes the server keeps (CareerServer), for clients: the
-- tier shown (RankRules.shown: 0 while placing), its RR, the Competitive
-- matches counted (for placements), the shields left, and what the last
-- match did, if it counted: the RR it was worth and a RankRules.Note.
RankConfig.TIER = "VFRankTier"
RankConfig.RR = "VFRankRR"
RankConfig.GAMES = "VFRankGames"
RankConfig.SHIELDS = "VFRankShields"
RankConfig.LAST = "VFRankLast"
RankConfig.NOTE = "VFRankNote"
-- And the hidden MMR, in Studio alone, for checks.
RankConfig.MMR = "VFRankMmr"

-- A tier's name, by its number; "Unranked" for none.
function RankConfig.name(tier: number): string
	return RankConfig.Tiers[tier] or "Unranked"
end

-- A bot's MMR at a skill by its key; Normal's for any other.
function RankConfig.botMmr(skill: any): number
	local param = if typeof(skill) == "string" then RankConfig.BotMmr[skill] else nil
	return (param or RankConfig.BotMmr.normal).value
end

return RankConfig
