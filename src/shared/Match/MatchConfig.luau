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
-- And the economy (system 14): the credits each side has to buy with, from
-- the reference's own rules (docs/research/14-economy.md). And the match's
-- record (system 16): kills, deaths, assists and the combat score
-- (docs/research/16-scoreboard.md).
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
-- The player attribute the server keeps each player's credits in, while the
-- spike rounds are on.
MatchConfig.CREDITS = "VFCredits"
-- And what they had as the round started, after its pay, which is what the
-- other side's scoreboard shows of them (system 16).
MatchConfig.START_CREDITS = "VFStartCredits"
-- And each player's record this match (system 16): kills, deaths, assists,
-- the combat score, and the rounds played for its average; and whether
-- they're alive, while either the arena or the spike rounds are on.
MatchConfig.KILLS = "VFKills"
MatchConfig.DEATHS = "VFDeaths"
MatchConfig.ASSISTS = "VFAssists"
MatchConfig.SCORE = "VFScore"
MatchConfig.ROUNDS = "VFRounds"
MatchConfig.ALIVE = "VFAlive"
-- And the guns each player holds, primary and sidearm ("vandal,classic"; ""
-- for an empty slot), for the scoreboard.
MatchConfig.LOADOUT = "VFLoadout"

-- How a match goes past a tie at the end of regulation: one more round
-- whose winner takes it, or rounds on alternate sides until a side leads by
-- two.
export type Overtime = "suddenDeath" | "winByTwo"
-- How a round's result is paid: the standard match's win, loss streak and
-- survivors, or Swiftplay's schedule, the same whatever the result.
export type Economy = "standard" | "swiftplay"

export type Format = {
	name: string,
	halfRounds: Param, -- rounds before the sides swap
	winScore: Param, -- rounds to win in regulation
	overtime: Overtime,
	overtimeSource: string,
	economy: Economy,
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
		economy = "standard",
	},
	competitive = {
		name = "Competitive",
		halfRounds = p(12, "confirmed", "As standard (Patch 1.11)"),
		winScore = p(13, "confirmed", "As standard (Patch 1.11)"),
		overtime = "winByTwo",
		overtimeSource = "Patch 1.03: 'teams will alternate playing rounds on attack and defense until a team claims victory by being up by 2 rounds'",
		economy = "standard",
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
		economy = "swiftplay",
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

-- The economy (system 14). Everyone's credits start each half over, and are
-- paid as the next round starts for how the last one went (a win, a loss,
-- or a loss survived); kills and the plant are paid as they happen.
local MOBALYTICS = "Mobalytics' economy guide"
MatchConfig.Credits = {
	start = p(800, "confirmed", "Patch 1.0: 'the 800 you receive on side swap rounds'; and at the start of the match"),
	win = p(3000, "community", MOBALYTICS .. ": 'a round win will always give $3000'"),
	-- A side's first loss in a row, its second, and its third and on: "it
	-- resets to 1,900 the moment you win a round" (Turbosmurfs).
	loss = {
		p(1900, "community", MOBALYTICS .. ", ONE Esports, Turbosmurfs: 1900 for a loss"),
		p(2400, "community", MOBALYTICS .. ", ONE Esports, Turbosmurfs: 2400 for two in a row"),
		p(2900, "community", MOBALYTICS .. ", ONE Esports, Turbosmurfs: 2900 for three in a row and more"),
	},
	survived = p(
		1000,
		"confirmed",
		"Patch 1.11: 'Attackers who lose but survive the entire round without planting the Spike receive a reduced number of credits (1,000)'; 'Defenders who lose but survive the entire round after the Spike has detonated also receive reduced credits (1,000)'"
	),
	kill = p(200, "community", MOBALYTICS .. ": '$200 is given for a kill'"),
	plant = p(300, "community", MOBALYTICS .. ": 'the entire attacking team will gain $300 for planting the spike'"),
	cap = p(9000, "community", MOBALYTICS .. ": 'the credit cap of $9000'; Patch 1.0 mentions 'the credit cap'"),
	overtime = p(
		5000,
		"confirmed",
		"Patch 1.03: in overtime 'each round will have a full reset, setting all players at 5000 credits'; the Valorant Fandom wiki: Unrated's Endgame round, 5000; the VALORANT Wiki's Swiftplay page: its Endgame, 5000 (community)"
	),
}

-- Swiftplay pays every round the same, whatever the result, except the
-- second of each half, where the side that won the first gets a bonus: by
-- round of the half, what everyone gets as it starts (the first starts over
-- at Credits.start). "No credit bonuses for loss streaks" (the VALORANT
-- Wiki's Swiftplay page).
local SWIFTPLAY = "The VALORANT Wiki's Swiftplay page"
MatchConfig.Swiftplay = {
	[2] = {
		all = p(2400, "community", SWIFTPLAY .. ": Round 2, '+2400'"),
		won = p(600, "community", SWIFTPLAY .. ": Round 2, '+600 bonus if team won previous round'"),
	},
	[3] = { all = p(4250, "community", SWIFTPLAY .. ": Round 3, '+4250'") },
	[4] = { all = p(4250, "community", SWIFTPLAY .. ": Round 4, '+4250'") },
} :: { [number]: { all: Param, won: Param? } }

-- The combat score (system 16), each round's, which the scoreboard shows
-- averaged over the rounds played (ACS): a point for each point of damage
-- dealt to an enemy, a kill's worth by how many enemies were alive for it,
-- and more for each kill after the first in a round.
local ESPORTS_NET = "esports.net's ACS guide"
MatchConfig.Score = {
	damage = p(1, "community", ESPORTS_NET .. ": 'Each point of damage dealt adds 1 point'"),
	-- A kill, by the enemies alive as it's made, the one killed among them:
	-- five, four, three, two, or the last.
	kill = {
		p(70, "community", ESPORTS_NET .. ": 70 for the final enemy"),
		p(90, "community", ESPORTS_NET .. ": 90 with 2 alive"),
		p(110, "community", ESPORTS_NET .. ": 110 with 3 alive"),
		p(130, "community", ESPORTS_NET .. ": 130 with 4 alive"),
		p(150, "community", ESPORTS_NET .. ": 150 with 5 alive"),
	},
	multiKill = p(
		50,
		"community",
		ESPORTS_NET .. ": '2 kills add 50, 3 kills add 100, and 4 kills add 150'; tracker.gg: 'For every addition kill, you can receive 50 points'"
	),
}

return MatchConfig
