--!strict
-- The round at a glance (system 16): the match's record the scoreboard
-- shows. Damage and kills scored as the reference's combat score, kills by
-- the enemies alive, the multikill bonus, assists, deaths with nobody to
-- credit, what isn't recorded (teammates, waiting for an opponent, a match
-- already won), the rounds played and the average, a new match starting
-- everyone over, and the credits the other side sees.

local MatchConfig = require("../src/shared/Match/MatchConfig")
local MatchRules = require("../src/shared/Match/MatchRules")
local H = require("./Harness")

local check = H.check

local S = MatchConfig.Score
local KILL = { S.kill[1].value, S.kill[2].value, S.kill[3].value, S.kill[4].value, S.kill[5].value }
local MULTI = S.multiKill.value

-- A 3v3 at round 1's buy phase: players 1, 3 and 5 on side 1, and 2, 4 and
-- 6 on side 2.
local function threeVsThree(format: string?): MatchRules.State
	local s = MatchRules.new(format)
	for id = 1, 6 do
		MatchRules.join(s, id, 0)
	end
	return s
end

local function member(s: MatchRules.State, id: number): MatchRules.Member
	return s.members[id]
end

-- Ends the buy phase of the round under way.
local function goLive(s: MatchRules.State)
	if s.phase == "buy" then
		MatchRules.step(s, s.phaseEndsAt)
	end
end

-- Moves on from the round's end to the next round's buy phase.
local function nextRound(s: MatchRules.State)
	if s.phase == "roundOver" or s.phase == "matchOver" then
		MatchRules.step(s, s.phaseEndsAt)
	end
end

-- Plays a 1v1's round to its end with `winner` killing the other, and
-- starts the next.
local function win(s: MatchRules.State, winner: number)
	goLive(s)
	MatchRules.died(s, 3 - winner, s.phaseEndsAt - 50, winner)
	nextRound(s)
end

H.section("Scoreboard tests")

-- The combat score's numbers --------------------------------------------------

check(
	"the combat score's numbers are the community's: a point a point of damage, 150 to 70 a kill, 50 a multikill",
	S.damage.value == 1 and KILL[5] == 150 and KILL[4] == 130 and KILL[3] == 110 and KILL[2] == 90 and KILL[1] == 70 and MULTI == 50
)
check(
	"a kill's worth by the enemies alive, the one killed among them, held to one to five",
	MatchRules.killScore(5) == 150
		and MatchRules.killScore(3) == 110
		and MatchRules.killScore(1) == 70
		and MatchRules.killScore(0) == 70
		and MatchRules.killScore(9) == 150
)
check(
	"the average is the score over the rounds played, to the nearest point",
	MatchRules.average(301, 2) == 151 and MatchRules.average(299, 2) == 150 and MatchRules.average(450, 3) == 150
)
check("with no round played yet, it's the score so far", MatchRules.average(0, 0) == 0 and MatchRules.average(250, 0) == 250)

-- Damage, kills, multikills and assists ------------------------------------

do
	local s = threeVsThree()
	check(
		"the sides alternate as players join",
		member(s, 1).side == 1 and member(s, 2).side == 2 and member(s, 3).side == 1 and member(s, 6).side == 2
	)
	local clean = true
	for _, m in s.members do
		clean = clean and m.kills == 0 and m.deaths == 0 and m.assists == 0 and m.score == 0 and m.rounds == 0
	end
	check("everyone starts the match with nothing on the record", clean)

	goLive(s)
	local version = s.version
	MatchRules.damaged(s, 1, 2, 40)
	check("damage to an enemy scores a point a point", member(s, 1).score == 40)
	check("and the server hears of the change", s.version > version)
	MatchRules.damaged(s, 1, 3, 40)
	check("damage to a teammate scores nothing", member(s, 1).score == 40)
	MatchRules.damaged(s, 1, 99, 40)
	MatchRules.damaged(s, 99, 2, 40)
	MatchRules.damaged(s, 1, 2, 0)
	check("nor does damage to or from someone not playing, or none at all", member(s, 1).score == 40)

	MatchRules.damaged(s, 5, 2, 10)
	MatchRules.died(s, 2, 10, 1)
	check(
		"a kill with all three enemies alive is worth 110",
		member(s, 1).kills == 1 and member(s, 1).score == 40 + KILL[3],
		tostring(member(s, 1).score)
	)
	check("and the one killed has a death", member(s, 2).deaths == 1 and member(s, 2).kills == 0)
	check(
		"a teammate who damaged that life has an assist; the killer, and a teammate who didn't, not",
		member(s, 5).assists == 1 and member(s, 1).assists == 0 and member(s, 3).assists == 0
	)

	MatchRules.damaged(s, 3, 4, 25)
	MatchRules.damaged(s, 5, 4, 30)
	MatchRules.damaged(s, 1, 4, 95)
	MatchRules.died(s, 4, 20, 1)
	local score = 40 + KILL[3] + 95 + KILL[2] + MULTI
	check(
		"a second kill in the round, with two left, is worth 90 and the multikill's 50",
		member(s, 1).kills == 2 and member(s, 1).score == score,
		tostring(member(s, 1).score)
	)
	check("every teammate who damaged that life has an assist", member(s, 3).assists == 1 and member(s, 5).assists == 2)
	check("and their damage scored for them", member(s, 3).score == 25 and member(s, 5).score == 40)

	MatchRules.died(s, 6, 30, 1)
	score += KILL[1] + MULTI
	check(
		"a third kill, the last enemy, is worth 70 and another 50",
		member(s, 1).kills == 3 and member(s, 1).score == score,
		tostring(member(s, 1).score)
	)
	check("which ends the round", s.phase == "roundOver" and s.roundWinner == 1)

	local played = true
	for _, m in s.members do
		played = played and m.rounds == 1
	end
	check("everyone has played a round, the dead too", played)

	nextRound(s)
	goLive(s)
	MatchRules.died(s, 2, s.phaseEndsAt - 50, 1)
	check("damage to someone's last life is no assist on their next", member(s, 5).assists == 2)
	check(
		"a new round starts the multikill count again: a first kill with three alive",
		member(s, 1).kills == 4 and member(s, 1).score == score + KILL[3],
		tostring(member(s, 1).score)
	)
end

-- Deaths nobody's credited with ---------------------------------------------

do
	local s = threeVsThree()
	goLive(s)
	MatchRules.damaged(s, 1, 2, 60)
	MatchRules.died(s, 2, 10, nil)
	check("a death nobody caused (the spike's blast) is a death", member(s, 2).deaths == 1)
	check("and nobody's kill or assist", member(s, 1).kills == 0 and member(s, 1).assists == 0 and member(s, 1).score == 60)
	MatchRules.died(s, 3, 20, 1)
	check("a teammate's kill is a death, not a kill", member(s, 3).deaths == 1 and member(s, 1).kills == 0 and member(s, 1).score == 60)
end

-- What isn't recorded ----------------------------------------------------------

do
	local s = MatchRules.new()
	MatchRules.join(s, 1, 0)
	check("alone, you wait for an opponent", s.phase == "waiting")
	MatchRules.died(s, 1, 1, nil)
	check("dying while waiting for an opponent isn't recorded", member(s, 1).deaths == 0)
end

do
	-- Swiftplay: first to 5.
	local s = MatchRules.new("swiftplay")
	MatchRules.join(s, 1, 0)
	MatchRules.join(s, 2, 0)
	for _ = 1, 4 do
		win(s, 1)
	end
	goLive(s)
	MatchRules.damaged(s, 1, 2, 50)
	MatchRules.died(s, 2, s.phaseEndsAt - 50, 1)
	check("the match is won", s.phase == "matchOver" and s.matchWinner == 1)
	local m1, m2 = member(s, 1), member(s, 2)
	check("the winner has every kill", m1.kills == 5 and m2.deaths == 5 and m1.rounds == 5 and m2.rounds == 5)
	check("and a score of 70 a kill, the last enemy, and their damage", m1.score == 5 * KILL[1] + 50, tostring(m1.score))
	check("an ACS of their score over the five rounds", MatchRules.average(m1.score, m1.rounds) == 80)

	MatchRules.damaged(s, 2, 1, 30)
	check("once the match is won, damage isn't recorded", m2.score == 0)

	nextRound(s)
	check("a new match starts", s.match == 2 and s.round == 1 and s.phase == "buy")
	m1, m2 = member(s, 1), member(s, 2)
	check("with everyone's record wiped", m1.kills == 0 and m1.score == 0 and m1.rounds == 0 and m2.deaths == 0 and m2.rounds == 0)
end

do
	-- The round's end, before the next: still recorded.
	local s = threeVsThree()
	goLive(s)
	MatchRules.died(s, 2, 1, 1)
	MatchRules.died(s, 4, 2, 1)
	MatchRules.died(s, 6, 3, 1)
	check("the round is over", s.phase == "roundOver")
	MatchRules.damaged(s, 3, 1, 10)
	MatchRules.died(s, 3, 4, nil)
	check("a death after the round's end still counts", member(s, 3).deaths == 1)
	check("but nobody's rounds count twice", member(s, 1).rounds == 1 and member(s, 3).rounds == 1)
end

do
	local s = threeVsThree()
	goLive(s)
	MatchRules.damaged(s, 1, 2, 40)
	MatchRules.leave(s, 1, 5)
	MatchRules.died(s, 2, 6, 3)
	check("someone who left gets no assist", s.members[1] == nil and member(s, 3).kills == 1 and member(s, 3).assists == 0)
end

-- The credits the other side sees --------------------------------------------

do
	local s = threeVsThree()
	local m = member(s, 1)
	check("someone who joins has their credits as the round started", m.startCredits == m.credits)
	MatchRules.spend(s, 1, 500)
	check("spending changes their credits, not what the other side sees", m.credits == m.startCredits - 500)
	goLive(s)
	MatchRules.died(s, 2, 10, 1)
	check("nor does a kill's pay", m.credits == m.startCredits - 500 + MatchConfig.Credits.kill.value)
	MatchRules.died(s, 4, 20, 1)
	MatchRules.died(s, 6, 30, 1)
	nextRound(s)
	check("the next round shows what it started them on, after its pay", m.startCredits == m.credits and s.round == 2)
end

return nil
