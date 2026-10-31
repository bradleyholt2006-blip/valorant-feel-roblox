--!strict
-- Competitive's ranks and everyone's career (system 67): the hidden MMR,
-- placements, what a match is worth in RR by the reference's published
-- rules and bounds, promotions with their buffer and shields, demotions
-- with their protection and floor, Immortal and Radiant by RR, and ours: no
-- climbing past the MMR on bots. Then each player's part in a match, which
-- matches count for whom, leaving Competitive under way, the totals, a
-- result counted once, and what the store and clients get.

local BotConfig = require("../src/shared/Bots/BotConfig")
local CareerRules = require("../src/shared/Career/CareerRules")
local MatchRules = require("../src/shared/Match/MatchRules")
local PlayConfig = require("../src/shared/Match/PlayConfig")
local RankConfig = require("../src/shared/Career/RankConfig")
local RankRules = require("../src/shared/Career/RankRules")
local H = require("./Harness")

local check = H.check

local R = RankConfig.Rules
local GOLD_1 = 10
local GOLD_2 = 11
local GOLD_3 = 12
local PLATINUM_1 = 13
local SILVER_3 = 9

local function rank(tier: number, rr: number, mmr: number, shields: number?): RankRules.Rank
	return { mmr = mmr, games = 20, tier = tier, rr = rr, shields = shields or 0 }
end

-- A match: `outcome`, the sides' MMRs, play over the average, the margin.
local function game(outcome: RankRules.Outcome, team: number?, enemy: number?, perf: number?, margin: number?): RankRules.Match
	local default = if outcome == "won" then 2 elseif outcome == "lost" then -2 else 0
	return { outcome = outcome, team = team or 1000, enemy = enemy or 1000, perf = perf or 1, margin = margin or default, winScore = 13 }
end

-- What a match would be worth to a copy of `r`.
local function worth(r: RankRules.Rank, m: RankRules.Match): number
	return RankRules.apply(table.clone(r), m).rr
end

H.section("Competitive's ranks (system 67)")

check("25 tiers, from Iron 1 to Radiant", #RankConfig.Tiers == 25 and RankConfig.Tiers[1] == "Iron 1" and RankConfig.Tiers[25] == "Radiant")
check(
	"the tiers named by number are Diamond 1, Immortal 1 and, as the highest placement, Ascendant 3",
	RankConfig.name(RankConfig.DIAMOND) == "Diamond 1"
		and RankConfig.name(RankConfig.IMMORTAL) == "Immortal 1"
		and RankConfig.name(R.topPlacement.value) == "Ascendant 3"
		and RankConfig.name(0) == "Unranked"
)
local everySkill = true
for _, skill in BotConfig.SKILLS do
	everySkill = everySkill and RankConfig.BotMmr[skill] ~= nil and RankConfig.botMmr(skill) == RankConfig.BotMmr[skill].value
end
check(
	"every bot skill has an MMR, and anything else is Normal's",
	everySkill and RankConfig.botMmr("nope") == RankConfig.BotMmr.normal.value
)
local fresh = RankRules.new()
check("a new player is unplaced, at the starting MMR", fresh.tier == 0 and fresh.games == 0 and fresh.mmr == R.mmrStart.value)
check(
	"Elo's expectation: even sides 1 in 2, and the side 400 MMR up 10 in 11",
	RankRules.expected(1000, 1000) == 0.5 and H.near(RankRules.expected(1400, 1000), 10 / 11, 1e-9)
)

H.section("Placements")

local placing = RankRules.new()
local placingOk = true
for i = 1, R.placements.value - 1 do
	local change = RankRules.apply(placing, game("won", placing.mmr, placing.mmr))
	placingOk = placingOk and change.rr == 0 and change.note == nil and placing.tier == 0 and placing.games == i
end
check("the first 4 matches show no rank and move no RR", placingOk)
check("an even win in placements moves the MMR half of kPlacing", H.near(placing.mmr, R.mmrStart.value + 4 * R.kPlacing.value / 2, 1e-9))
check("4 placements played, 1 left", RankRules.placementsLeft(placing) == 1)
local placed = RankRules.apply(placing, game("won", placing.mmr, placing.mmr))
check(
	"the 5th places the player at their MMR's tier with 50 RR and no shields",
	placed.note == "placed"
		and placing.tier == math.floor(placing.mmr / 100) + 1
		and placing.rr == 50
		and placing.shields == 0
		and RankRules.placementsLeft(placing) == 0
)
local high = { mmr = 5000, games = 4, tier = 0, rr = 0, shields = 0 }
RankRules.apply(high, game("won"))
local low = { mmr = -900, games = 4, tier = 0, rr = 0, shields = 0 }
RankRules.apply(low, game("lost"))
check("placed no higher than Ascendant 3, nor lower than Iron 1", high.tier == R.topPlacement.value and low.tier == 1)

H.section("What a match is worth")

local level = rank(GOLD_1, 50, 950)
local closeWin = worth(level, game("won", 1000, 1000, 1, 2))
local closeLoss = worth(level, game("lost", 1000, 1000, 1, -2))
check(
	"with the MMR level with the rank, a close win gains what a close loss loses",
	closeWin == -closeLoss and closeWin == 22,
	string.format("%d, %d", closeWin, closeLoss)
)
local over = rank(GOLD_1, 50, 1250)
local under = rank(GOLD_1, 50, 750)
check(
	"'If your MMR is higher than your rank, you'll gain more RR on wins than you lose on losses'",
	worth(over, game("won")) > -worth(over, game("lost"))
)
check(
	"'If your MMR is lower than your rank, you'll gain less RR on wins and lose more on losses'",
	worth(under, game("won")) < -worth(under, game("lost"))
)

-- Every mix of MMR, play, margin and sides, against the bounds.
local function sweep(tier: number, lowest: number): (number, number, number, number)
	local winLow, winHigh, lossLow, lossHigh = math.huge, -math.huge, math.huge, -math.huge
	local position = (tier - 1) * 100 + 50
	for mmr = lowest, position + 1500, 50 do
		for _, perf in { 0, 0.5, 1, 2, 4 } do
			for _, margin in { 1, 6, 13 } do
				for _, diff in { -800, 0, 800 } do
					local r = rank(tier, 50, mmr)
					local win = worth(r, game("won", 1000 + diff, 1000, perf, margin))
					local loss = -worth(r, game("lost", 1000 + diff, 1000, perf, -margin))
					winLow, winHigh = math.min(winLow, win), math.max(winHigh, win)
					lossLow, lossHigh = math.min(lossLow, loss), math.max(lossHigh, loss)
				end
			end
		end
	end
	return winLow, winHigh, lossLow, lossHigh
end
local wl, wh, ll, lh = sweep(GOLD_1, 900)
check(
	"below Diamond: a win gains 10 to 50 RR and a loss loses 0 to 30, both ends reached",
	wl == 10 and wh == 50 and ll == 0 and lh == 30,
	string.format("win %d to %d, loss %d to %d", wl, wh, ll, lh)
)
wl, wh, ll, lh = sweep(RankConfig.DIAMOND, 1500)
check(
	"from Diamond: a win gains 5 to 50 RR and a loss loses 0 to 50",
	wl >= 5 and wh == 50 and ll == 0 and lh <= 50 and wl < 10 and lh > 30,
	string.format("win %d to %d, loss %d to %d", wl, wh, ll, lh)
)
check(
	"winning by more gains more, and losing by more loses more",
	worth(level, game("won", 1000, 1000, 1, 13)) > worth(level, game("won", 1000, 1000, 1, 2))
		and worth(level, game("lost", 1000, 1000, 1, -13)) < worth(level, game("lost", 1000, 1000, 1, -2))
)
check(
	"the underdog winning gains more than the favourite, and loses less",
	worth(level, game("won", 800, 1200)) > worth(level, game("won", 1200, 800))
		and worth(level, game("lost", 800, 1200)) > worth(level, game("lost", 1200, 800))
)
check(
	"below Immortal your own play counts: a better game gains more and loses less",
	worth(level, game("won", 1000, 1000, 1.5)) > worth(level, game("won", 1000, 1000, 0.5))
		and worth(level, game("lost", 1000, 1000, 1.5)) > worth(level, game("lost", 1000, 1000, 0.5))
)
local immortal = rank(RankConfig.IMMORTAL, 40, 2140)
check(
	"in Immortal only the match counts, not your own play",
	worth(immortal, game("won", 2000, 2000, 3)) == worth(immortal, game("won", 2000, 2000, 0.2))
		and worth(immortal, game("lost", 2000, 2000, 3)) == worth(immortal, game("lost", 2000, 2000, 0.2))
)
local drawLow = worth(level, game("draw", 1000, 1000, 0))
local drawMid = worth(level, game("draw", 1000, 1000, 1))
local drawHigh = worth(level, game("draw", 1000, 1000, 3))
check(
	"a draw gains 0 to 20 RR on play alone, never losing any",
	drawLow == 0 and drawMid == 10 and drawHigh == 20,
	string.format("%d, %d, %d", drawLow, drawMid, drawHigh)
)
check("a draw in Immortal gains nothing", worth(immortal, game("draw", 2000, 2000, 3)) == 0)

H.section("Promotions, demotions and shields")

-- Gains 10 exactly: the favourite, playing badly, by a round.
local function smallWin(): RankRules.Match
	return game("won", 1800, 700, 0.2, 1)
end
local r = rank(GOLD_1, 92, 960)
local change = RankRules.apply(r, smallWin())
check(
	"100 RR promotes, starting the next tier on 10 RR at the least",
	change.note == "promoted" and change.rr == 10 and r.tier == GOLD_2 and r.rr == 10 and r.shields == 0,
	string.format("%s %d: tier %d, %d RR", tostring(change.note), change.rr, r.tier, r.rr)
)
r = rank(GOLD_1, 95, 1100)
change = RankRules.apply(r, game("won", 1000, 1000, 1, 2))
check("RR over 100 is carried into the next tier", change.note == "promoted" and r.tier == GOLD_2 and r.rr == 95 + change.rr - 100)
r = rank(GOLD_3, 95, 1300)
RankRules.apply(r, game("won"))
check("promoted into a rank's Tier 1, 2 shields", r.tier == PLATINUM_1 and r.shields == R.shields.value)
r = rank(GOLD_2, 5, 1050)
change = RankRules.apply(r, game("lost"))
check("a loss bigger than the RR left stops at 0 RR, in the tier", change.note == nil and change.rr < -5 and r.tier == GOLD_2 and r.rr == 0)
change = RankRules.apply(r, game("lost", 1000, 1000, 1, -2))
check(
	"a loss at 0 RR demotes, to 100 less the loss, and 2 shields entering a Tier 1",
	change.note == "demoted" and r.tier == GOLD_1 and r.rr == math.max(100 + change.rr, R.demoteFloor.value) and r.shields == 2,
	string.format("%s %d: tier %d, %d RR", tostring(change.note), change.rr, r.tier, r.rr)
)
r = rank(GOLD_2, 0, 600)
change = RankRules.apply(r, game("lost", 1000, 1000, 0, -13))
check("a demotion lands on 70 RR at the least", change.note == "demoted" and change.rr <= -30 and r.rr == R.demoteFloor.value)
r = rank(GOLD_1, 0, 1000, 2)
local first = RankRules.apply(r, game("lost"))
local firstShields = r.shields
local second = RankRules.apply(r, game("lost"))
local third = RankRules.apply(r, game("lost"))
check(
	"a loss at 0 RR in a Tier 1 takes a shield instead of the rank, till they're gone",
	first.note == "shielded"
		and firstShields == 1
		and second.note == "shielded"
		and third.note == "demoted"
		and r.tier == SILVER_3
		and r.rr >= R.demoteFloor.value
		and r.shields == 0
)
r = rank(1, 0, -500)
change = RankRules.apply(r, game("lost"))
check("Iron 1 at 0 RR stays there", change.note == nil and r.tier == 1 and r.rr == 0)
r = rank(R.topPlacement.value, 95, 2100)
RankRules.apply(r, game("won"))
check("Ascendant 3 promotes into Immortal 1, with no shields there", r.tier == RankConfig.IMMORTAL and r.shields == 0)
r = rank(RankConfig.IMMORTAL, 0, 2000, 2)
change = RankRules.apply(r, game("lost"))
check("Immortal 1 at 0 RR demotes on a loss", change.note == "demoted" and r.tier == R.topPlacement.value)

H.section("Immortal and Radiant")

r = rank(RankConfig.IMMORTAL, 95, 2300)
change = RankRules.apply(r, game("won"))
check("in Immortal RR goes on past 100", change.note == nil and r.tier == RankConfig.IMMORTAL and r.rr == 95 + change.rr)
local shownOk = true
for _, case in { { 0, 22 }, { 89, 22 }, { 90, 23 }, { 199, 23 }, { 200, 24 }, { 449, 24 }, { 450, 25 }, { 900, 25 } } do
	shownOk = shownOk and RankRules.shown(rank(RankConfig.IMMORTAL, case[1], 2500)) == case[2]
end
check("Immortal 2 from 90 RR, Immortal 3 from 200, Radiant from 450 (North America's)", shownOk)
check(
	"below Immortal the tier shown is the tier",
	RankRules.shown(rank(GOLD_2, 99, 1000)) == GOLD_2 and RankRules.shown(RankRules.new()) == 0
)

H.section("Bots can't lift a rank past its MMR (ours)")

local farmer = rank(SILVER_3, 50, 850)
for _ = 1, 400 do
	RankRules.apply(farmer, game("won", farmer.mmr, RankConfig.botMmr("easy"), 2, 13))
end
check(
	"400 wins over Easy bots end no more than a tier over the MMR they've earned",
	RankRules.position(farmer) <= farmer.mmr + R.overMmr.value,
	string.format("rank at %d, MMR %d", RankRules.position(farmer), math.round(farmer.mmr))
)
check("a win over the MMR by more than a tier gains nothing", worth(rank(GOLD_1, 50, 800), game("won", 1000, 1000, 1, 13)) == 0)
local climber = rank(SILVER_3, 50, 850)
for _ = 1, 20 do
	RankRules.apply(climber, game("won", climber.mmr, climber.mmr, 1, 4))
end
check(
	"20 wins over sides as good climb several tiers",
	climber.tier >= SILVER_3 + 3,
	string.format("tier %d, MMR %d", climber.tier, math.round(climber.mmr))
)

H.section("A rank in words")

check("placements played", RankRules.line(0, 0, 2) == "PLACEMENTS 2/5")
check("a tier and its RR", RankRules.line(GOLD_2, 64, 9) == "GOLD 2   64 RR")
check("a placement on the victory screen", RankRules.verdict(0, 0, 3, 0, 0, nil) == "PLACEMENT 3 OF 5")
check("placed", RankRules.verdict(GOLD_1, 50, 5, 0, 0, "placed") == "PLACED   GOLD 1   50 RR")
check("a win", RankRules.verdict(GOLD_2, 64, 9, 0, 18, nil) == "GOLD 2   64 RR   (+18)")
check("a promotion", RankRules.verdict(GOLD_3, 12, 9, 0, 20, "promoted") == "PROMOTED   GOLD 3   12 RR   (+20)")
check("a demotion", RankRules.verdict(GOLD_1, 80, 9, 2, -20, "demoted") == "DEMOTED   GOLD 1   80 RR   (-20)")
check("a shield used", RankRules.verdict(GOLD_1, 0, 9, 1, -21, "shielded") == "GOLD 1   0 RR   (-21, A SHIELD KEPT THE RANK: 1 LEFT)")

H.section("Each player's part in a match (system 67)")

local function player(side: number, rounds: number, bot: boolean?, kills: number?, score: number?): CareerRules.Player
	return { side = side, kills = kills or 0, deaths = 3, assists = 1, score = score or 200 * rounds, rounds = rounds, bot = bot == true }
end
local nextId = 0
local function newId(): string
	nextId += 1
	return "r" .. nextId
end
local MMR = { [1] = 1200, [2] = 1000, [3] = 900 }
local function mmrOf(id: number, p: CareerRules.Player): number
	return if p.bot then RankConfig.botMmr("normal") else MMR[id] or R.mmrStart.value
end
local comp: CareerRules.Match = {
	mode = "competitive",
	winner = 1,
	score = { 13, 9 },
	rounds = 22,
	winScore = 13,
	players = {
		[1] = player(1, 22, false, 20, 22 * 300),
		[2] = player(1, 10),
		[3] = player(2, 22),
		[101] = player(1, 22, true),
		[102] = player(2, 22, true),
	},
}
local results = CareerRules.results(comp, mmrOf, newId)
local one = results[1]
local ranked = one and one.ranked
check(
	"a match won counts as a win, with the record kept",
	one ~= nil and one.outcome == "won" and one.mode == "competitive" and one.kills == 20 and one.rounds == 22
)
check(
	"in Competitive, each side's MMR is its players' and bots' average",
	ranked ~= nil and H.near(ranked.team, (1200 + 1000 + 800) / 3, 1e-9) and H.near(ranked.enemy, (900 + 800) / 2, 1e-9)
)
check(
	"and play is the combat score a round over the match's average, with the margin by side",
	ranked ~= nil and H.near(ranked.perf, 300 / ((300 + 200 + 200 + 200 + 200) / 5), 1e-9) and ranked.margin == 4 and ranked.winScore == 13
)
check("too little of a match played counts for nothing", results[2] == nil)
check(
	"a match lost counts as a loss, the margin the other way",
	results[3] ~= nil and results[3].outcome == "lost" and (results[3].ranked :: RankRules.Match).margin == -4
)
check("bots have no part", results[101] == nil and results[102] == nil)
local gun = CareerRules.results({
	mode = "gungame",
	winner = 2,
	score = { 5, 18 },
	rounds = 0,
	winScore = 0,
	players = { [1] = player(1, 0), [3] = player(2, 0) },
}, mmrOf, newId)
check(
	"without rounds, everyone in it counts, and only Competitive moves a rank",
	gun[1] ~= nil and gun[1].outcome == "lost" and gun[3].outcome == "won" and gun[1].ranked == nil
)
local tdm = CareerRules.results(
	{ mode = "teamdeathmatch", winner = nil, score = { 100, 100 }, rounds = 0, winScore = 0, players = { [1] = player(1, 0) } },
	mmrOf,
	newId
)
check("a match ended level is a draw", tdm[1] ~= nil and tdm[1].outcome == "draw")
local standing: CareerRules.Match = table.clone(comp)
standing.winner = nil
standing.players = table.clone(comp.players)
standing.players[4] = player(2, 0)
local leaver = CareerRules.left(standing, 1, mmrOf, newId)
check(
	"leaving Competitive under way, a round played, is a loss as it stands",
	leaver ~= nil and leaver.outcome == "lost" and leaver.ranked ~= nil and (leaver.ranked :: RankRules.Match).outcome == "lost"
)
check("leaving before a round's played is nothing", CareerRules.left(standing, 4, mmrOf, newId) == nil)
local unrated = table.clone(standing)
unrated.mode = "standard"
check(
	"leaving anything but Competitive is nothing",
	CareerRules.left(unrated, 1, mmrOf, newId) == nil and CareerRules.left(standing, 101, mmrOf, newId) == nil
)

H.section("The career kept")

local record = CareerRules.new()
local before = record.rank.mmr
local moved = CareerRules.apply(record, one :: CareerRules.Result)
local totals = record.modes.competitive
check(
	"a result adds to its mode's totals",
	totals ~= nil and totals.matches == 1 and totals.wins == 1 and totals.kills == 20 and totals.score == 22 * 300 and totals.rounds == 22
)
check("and a Competitive one to the rank", moved ~= nil and record.rank.games == 1 and record.rank.mmr > before)
local again = CareerRules.apply(record, one :: CareerRules.Result)
check("the same result twice counts once", again == nil and totals.matches == 1 and record.rank.games == 1)
for i = 1, 20 do
	CareerRules.apply(
		record,
		{ id = "x" .. i, mode = "skirmish", outcome = "lost", kills = 1, deaths = 2, assists = 0, score = 100, rounds = 5 }
	)
end
check(
	"only the last 16 results' ids are kept",
	#record.seen == CareerRules.SEEN and record.seen[1] == "x5" and record.seen[16] == "x20" and record.modes.skirmish.losses == 20
)
local copy = CareerRules.decode(CareerRules.encode(record))
local same = copy.rank.mmr == record.rank.mmr
	and copy.rank.games == record.rank.games
	and copy.rank.tier == record.rank.tier
	and #copy.seen == #record.seen
	and copy.modes.skirmish.kills == 20
	and copy.modes.competitive.wins == 1
check("what the store keeps comes back as it was", same)
check("nothing kept is a new career", CareerRules.decode(nil).rank.tier == 0 and next(CareerRules.decode("junk").modes) == nil)
check("a record of another version is a new career", CareerRules.decode({ v = 2, rank = { tier = 5 } }).rank.tier == 0)
local broken = CareerRules.decode({
	v = 1,
	rank = { mmr = 0 / 0, games = 1.5, tier = 99, rr = 4000, shields = 7 },
	modes = { skirmish = { matches = -3, wins = "x", kills = 4 }, nope = { matches = 9 } },
	seen = { "a", 5, "b" },
})
check(
	"anything out of bounds is put back in them",
	broken.rank.mmr == R.mmrStart.value
		and broken.rank.games == 0
		and broken.rank.tier == RankConfig.IMMORTAL
		and broken.rank.rr == 4000
		and broken.rank.shields == 2
		and broken.modes.skirmish.matches == 0
		and broken.modes.skirmish.wins == 0
		and broken.modes.skirmish.kills == 4
		and broken.modes.nope == nil
		and #broken.seen == 2
)
check(
	"RR in a tier below Immortal is under 100",
	CareerRules.decode({ v = 1, rank = { tier = GOLD_1, rr = 150 } }).rank.rr == 99
		and CareerRules.decode({ v = 1, rank = { tier = 0, rr = 40 } }).rank.rr == 0
)

H.section("What clients get")

local text = CareerRules.toText(record)
local back = CareerRules.fromText(text)
check("the totals go to clients in a line, mode by mode", back.competitive ~= nil and back.skirmish ~= nil and back.skirmish.losses == 20)
check("in the Play menu's order", string.find(text, "^skirmish=") ~= nil and string.find(text, ";competitive=") ~= nil)
local parsed = CareerRules.fromText("skirmish=1,2;nope=1,1,1,1,1,1,1,1,1;duel=3,2,1,0,9,8,7,600,30")
check(
	"a broken part or a mode not played is left out",
	parsed.skirmish == nil and parsed.nope == nil and parsed.duel ~= nil and parsed.duel.score == 600
)
check("nothing for no text", next(CareerRules.fromText(nil)) == nil)
check(
	"a mode's line: won, lost and drawn, and kills a death",
	CareerRules.summary({ matches = 12, wins = 7, losses = 4, draws = 1, kills = 140, deaths = 100, assists = 0, score = 0, rounds = 0 })
			== "7W 4L 1D   1.40 K/D"
		and CareerRules.summary(CareerRules.newTotals()) == "0W 0L   0.00 K/D"
)
local keysKnown = true
for key in CareerRules.fromText(CareerRules.toText(record)) do
	keysKnown = keysKnown and PlayConfig.ByKey[key] ~= nil
end
check("every mode in the line is on the Play menu", keysKnown and PlayConfig.ByKey[CareerRules.RANKED] ~= nil)

H.section("Deciding rounds, for checks (system 67)")

local decided = MatchRules.new("competitive", { "outpost" })
MatchRules.join(decided, 1, 0)
MatchRules.join(decided, 2, 0)
local inBuy = decided.phase == "buy"
MatchRules.decide(decided, 2, 1)
check(
	"a round decided ends at once, its buy phase too, won by the side named",
	inBuy and decided.phase == "roundOver" and decided.score[2] == 1 and decided.roundWinner == 2 and decided.reason == "eliminated"
)
MatchRules.decide(decided, 1, 2)
check("between rounds there's nothing to decide", decided.score[1] == 0 and decided.score[2] == 1)
-- Turn about to 13-13, in overtime, then side 1 twice.
local clock = 2
local rounds = 1
while decided.phase ~= "matchOver" and rounds < 40 do
	clock += 60
	MatchRules.step(decided, clock)
	if decided.phase == "buy" then
		local n = rounds + 1
		MatchRules.decide(decided, if n > 26 or n % 2 == 0 then 1 else 2, clock)
		rounds = n
	end
end
check(
	"deciding rounds plays a Competitive match to its end, through overtime",
	decided.phase == "matchOver"
		and decided.matchWinner == 1
		and decided.score[1] == 15
		and decided.score[2] == 13
		and decided.members[1].rounds == 28,
	string.format("%d-%d after %d rounds", decided.score[1], decided.score[2], rounds)
)

return nil
