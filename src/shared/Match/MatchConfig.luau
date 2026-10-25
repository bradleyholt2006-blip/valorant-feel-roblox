--!strict
-- Rounds played for the spike (system 13): the rules of the reference's
-- standard match, which its Unrated and Competitive queues play, and of
-- Swiftplay, its shorter match. Same status convention as MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be tuned (docs/research/13-rounds.md)
-- The VALORANT Wiki (wiki.playvalorant.com) is written by players, so what
-- only it says is "community".
--
-- There's no economy yet: the buy menu costs nothing, as in Skirmish.
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local MatchConfig = {}

-- The model the server builds the map in, and Workspace's attribute for the
-- format the next match is played in (a key of MatchConfig.Formats).
MatchConfig.MODEL = "VFSpikeMap"
MatchConfig.FORMAT = "VFMatchFormat"
-- Workspace's attribute that, set true from the server, ends the phase being
-- played now and clears itself (MatchRules.skip): for scripted checks, which
-- would otherwise wait out every buy phase and round.
MatchConfig.SKIP = "VFMatchSkip"

-- How a match goes past a tie at the end of regulation: one more round
-- whose winner takes it, or rounds on alternate sides until a side leads by
-- two.
export type Overtime = "suddenDeath" | "winByTwo"

export type Format = {
	name: string,
	halfRounds: Param, -- rounds before the sides swap
	winScore: Param, -- rounds to win in regulation
	overtime: Overtime,
	overtimeSource: string,
}

MatchConfig.Formats = {
	standard = {
		name = "Standard",
		halfRounds = p(
			12,
			"confirmed",
			"Patch 1.11: with its custom-game option on, a match goes on 'until both teams have played a full half of 12 rounds on each side'"
		),
		winScore = p(13, "confirmed", "Patch 1.11: with that option on, 'the game will no longer end when a team reaches 13 wins'"),
		overtime = "suddenDeath",
		overtimeSource = "Patch 1.03: 'Unrated will still use the original Sudden Death format'; the VALORANT Wiki: 'a final Endgame round played should the game reach a 12-12 scoreline' (community)",
	},
	competitive = {
		name = "Competitive",
		halfRounds = p(12, "confirmed", "As standard (Patch 1.11)"),
		winScore = p(13, "confirmed", "As standard (Patch 1.11)"),
		overtime = "winByTwo",
		overtimeSource = "Patch 1.03: 'teams will alternate playing rounds on attack and defense until a team claims victory by being up by 2 rounds'",
	},
	swiftplay = {
		name = "Swiftplay",
		halfRounds = p(
			4,
			"community",
			"ONE Esports on Swiftplay: 'Halftime is after the fourth round, after which teams will switch sides'"
		),
		winScore = p(5, "community", "ONE Esports: 'the objective is to win five rounds'; the VALORANT Wiki: 'a 5v5 best-of-nine mode'"),
		overtime = "suddenDeath",
		overtimeSource = "ONE Esports: the mode has 'sudden death overtime' (community)",
	},
} :: { [string]: Format }

MatchConfig.DEFAULT_FORMAT = "standard"

MatchConfig.Rules = {
	-- Everyone is held in their spawn behind barriers while they buy.
	buyTime = p(30, "community", "Valorant Fandom wiki, Unrated: the Buy Phase lasts 30 seconds"),
	firstBuyTime = p(
		45,
		"community",
		"Valorant Fandom wiki, Unrated: the first Buy Phase of each half, and the Endgame's, last 45 seconds (the same here for every overtime round)"
	),
	roundTime = p(
		100,
		"community",
		"Wikipedia's Valorant article, on Game Informer's preview (March 2020): 'the 100-second round timer'; Valorant Fandom wiki, Unrated: a round lasts up to 100 seconds"
	),
	postRoundTime = p(7, "community", "Valorant Fandom wiki, Unrated: the Post-Round Phase lasts 7 seconds"),
	matchOverTime = p(10, "estimate", "Seconds the match's result is shown before a new match starts at 0-0"),
	respawnTime = p(3, "estimate", "Seconds before someone who dies with nobody to play against comes back (as the arena)"),
}

-- Each side's starting kit, at the start of each half: the Classic and the
-- knife, no shield (WeaponConfig ids; slot 1 empty).
MatchConfig.StartingKit = { "", "classic", "knife" }
MatchConfig.startingKitSource =
	"The Classic costs nothing and everyone has one, as the knife (the VALORANT Wiki's weapon prices, docs/research/09-arsenal.md; community)"

return MatchConfig
