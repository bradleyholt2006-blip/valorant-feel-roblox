--!strict
-- Gun game (system 23): a ladder of guns a level each, a kill with each to
-- move up, and the first to a kill on the last level, the knife, wins; or
-- whoever's furthest up when the time's up. A knife kill knocks the one
-- killed down a level. The dead come back in a moment, untouchable until
-- they fire or the protection runs out. Then the victory screen and the
-- vote for the next map, as in Skirmish.

local ArenaConfig = require("../src/shared/Arena/ArenaConfig")
local ArenaLayout = require("../src/shared/Arena/ArenaLayout")
local GunGameConfig = require("../src/shared/Arena/GunGameConfig")
local GunGameRules = require("../src/shared/Arena/GunGameRules")
local MapVote = require("../src/shared/Match/MapVote")
local Roster = require("../src/shared/Match/Roster")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local H = require("./Harness")

local check = H.check

local A = ArenaConfig.Rules
local G = GunGameConfig.Rules

-- Dice that roll what they're told, in turn, then 1s, and never more than
-- the number of sides.
local function dice(...: number): MapVote.Roll
	local rolls = { ... }
	local i = 0
	return function(n: number): number
		i += 1
		local r = rolls[i] or 1
		assert(r >= 1 and r <= n, "a roll off the dice")
		return r
	end
end

local function same(a: { any }, b: { any }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

H.section("Gun game tests")

-- The ladder ----------------------------------------------------------------------

do
	local tiersOk = true
	for i, tier in GunGameConfig.Tiers do
		for _, id in tier do
			local def = WeaponConfig.Defs[id]
			local last = i == #GunGameConfig.Tiers
			if not def or (last and id ~= "knife") or (not last and def.slot ~= 1 and def.slot ~= 2) then
				tiersOk = false
			end
		end
	end
	check("every tier's guns are the arsenal's, a primary or a sidearm, and the last tier is the knife", tiersOk)

	-- Dice: the Phantom first, so the Vandal second, then the Warden, the
	-- Marshal and the Odin, and the first of each tier after.
	local ladder = GunGameRules.rollLadder(dice(2, 1, 3, 1, 2))
	check(
		"twelve levels, one gun of each tier, as the dice have it",
		same(ladder, {
			"phantom",
			"vandal",
			"warden",
			"marshal",
			"odin",
			"stinger",
			"sheriff",
			"ghost",
			"classic",
			"bucky",
			"shorty",
			"knife",
		}),
		table.concat(ladder, ",")
	)

	math.randomseed(23)
	local fine = true
	for _ = 1, 200 do
		local l = GunGameRules.rollLadder(math.random)
		local seen: { [string]: boolean } = {}
		for _, id in l do
			fine = fine and not seen[id]
			seen[id] = true
		end
		local rifles = (l[1] == "vandal" and l[2] == "phantom") or (l[1] == "phantom" and l[2] == "vandal")
		fine = fine and #l == 12 and rifles and l[12] == "knife"
	end
	check("at random: never a gun twice, the Vandal and the Phantom first, the knife last", fine)
end

-- A match ----------------------------------------------------------------------

-- Dice of 1s: Skirmish A, and the first gun of each tier (the Vandal, the
-- Phantom, the Bulldog and so on).
local function game(): GunGameRules.State
	return GunGameRules.new(nil, dice())
end

do
	local s = game()
	check("on one of the arena's maps", s.map == "A" and same(s.maps, ArenaLayout.MAPS))
	local first = GunGameRules.join(s, 1, 0)
	check("alone, waiting for an opponent, spawning at once", s.phase == "waiting" and same(first, { 1 }))
	local both = GunGameRules.join(s, 2, 0)
	check(
		"a second player starts the match: everyone spawns, on the first gun, for the time limit",
		s.phase == "live" and same(both, { 1, 2 }) and s.phaseEndsAt == G.timeLimit.value and GunGameRules.levelOf(s, 1) == 1
	)
	local kit = GunGameRules.kitOf(s, 1)
	check("the first gun, and the knife", kit ~= nil and same(kit, { "vandal", "", "knife" }))
	check("one a side", GunGameRules.sideOf(s, 1) == 1 and GunGameRules.sideOf(s, 2) == 2)

	GunGameRules.died(s, 2, 10, 1, "vandal")
	check("a kill moves the killer up to the next gun", GunGameRules.levelOf(s, 1) == 2 and GunGameRules.gunOf(s, 1) == "phantom")
	check("and the one killed stays on theirs", GunGameRules.levelOf(s, 2) == 1)
	check("both in the record", s.members[1].kills == 1 and s.members[2].deaths == 1)
	check("each side's best level, for the top bar", same(s.score, { 2, 1 }))
	check("the dead come back after the respawn time", #GunGameRules.step(s, 10 + G.respawnTime.value - 0.01) == 0)
	local back = GunGameRules.step(s, 10 + G.respawnTime.value)
	check("in their room, on their gun", same(back, { 2 }) and s.members[2].alive)

	GunGameRules.spawned(s, 2, 12)
	check(
		"untouchable for a moment after they spawn",
		GunGameRules.safe(s, 2, 12 + G.protectTime.value - 0.01) and not GunGameRules.safe(s, 2, 12 + G.protectTime.value)
	)
	check("until they fire", GunGameRules.fired(s, 2) and not GunGameRules.safe(s, 2, 13) and not GunGameRules.fired(s, 2))

	GunGameRules.died(s, 1, 20, 2, "knife")
	check(
		"a knife kill knocks the one killed down a level, and moves the killer up",
		GunGameRules.levelOf(s, 1) == 1 and GunGameRules.levelOf(s, 2) == 2
	)
	GunGameRules.step(s, 30)
	GunGameRules.died(s, 1, 31, 2, "knife")
	check("but never below the first", GunGameRules.levelOf(s, 1) == 1 and GunGameRules.levelOf(s, 2) == 3)
	GunGameRules.step(s, 40)
	GunGameRules.died(s, 1, 41, nil, nil)
	check("a death with nobody to credit moves nobody", GunGameRules.levelOf(s, 1) == 1 and GunGameRules.levelOf(s, 2) == 3)
	check("but is a death", s.members[1].deaths == 3)

	-- Player 2 climbs to the knife.
	local t = 50
	while (GunGameRules.levelOf(s, 2) or 0) < #s.ladder do
		t += 2
		GunGameRules.step(s, t)
		GunGameRules.died(s, 1, t, 2, GunGameRules.gunOf(s, 2))
	end
	local last = GunGameRules.kitOf(s, 2)
	check("the last level is the knife alone", last ~= nil and same(last, { "", "", "knife" }) and s.phase == "live")
	t += 2
	GunGameRules.step(s, t)
	GunGameRules.died(s, 1, t, 2, "knife")
	check(
		"a kill on the last level wins the match, for the killer and their side",
		s.phase == "matchOver" and s.winner == 2 and s.matchWinner == 2 and s.phaseEndsAt == t + A.matchOverTime.value
	)
	check("nobody comes back during the victory screen", #GunGameRules.step(s, t + 5) == 0 and not s.members[1].alive)
	GunGameRules.died(s, 2, t + 6, 1, "vandal")
	check("and nothing moves anyone then", GunGameRules.levelOf(s, 1) == 1 and s.members[1].kills == 1)

	local ladder = table.clone(s.ladder)
	GunGameRules.step(s, s.phaseEndsAt)
	local vote = s.vote
	check("then the vote for the next map", s.phase == "vote" and vote ~= nil and #vote.options == A.voteChoices.value)
	GunGameRules.vote(s, 1, 3)
	GunGameRules.vote(s, 2, 3)
	local again = GunGameRules.step(s, s.phaseEndsAt)
	check(
		"then the next match on the map voted for, at the bottom of a new ladder, everyone spawning",
		s.phase == "live" and s.map == "C" and s.match == 2 and same(again, { 1, 2 }) and GunGameRules.levelOf(s, 2) == 1
	)
	check("with the record cleared", s.members[1].kills == 0 and s.members[2].kills == 0 and s.winner == nil)
	check("a ladder rolled again", #s.ladder == #ladder)
end

do
	local s = game()
	GunGameRules.join(s, 1, 0)
	GunGameRules.join(s, 2, 0)
	GunGameRules.died(s, 1, 1, 2, "vandal")
	GunGameRules.died(s, 2, 2, 1, "vandal")
	GunGameRules.step(s, 5)
	GunGameRules.died(s, 1, 6, 2, "phantom")
	check("level 3 against level 2", GunGameRules.levelOf(s, 2) == 3 and GunGameRules.levelOf(s, 1) == 2)
	GunGameRules.step(s, G.timeLimit.value)
	check("when the time's up, whoever's furthest up wins", s.phase == "matchOver" and s.winner == 2)

	local tie = game()
	GunGameRules.join(tie, 1, 0)
	GunGameRules.join(tie, 2, 0)
	GunGameRules.died(tie, 2, 1, 1, "vandal")
	GunGameRules.died(tie, 1, 2, 2, "vandal")
	GunGameRules.step(tie, G.timeLimit.value)
	check("on a tie, the first to get there", tie.winner == 1)

	local skip = game()
	GunGameRules.join(skip, 1, 0)
	GunGameRules.join(skip, 2, 0)
	GunGameRules.skip(skip, 3)
	GunGameRules.step(skip, 3)
	check("skipping ends the match as if the time were up (for testing)", skip.phase == "matchOver")
	GunGameRules.skip(skip, 4)
	GunGameRules.step(skip, 4)
	GunGameRules.skip(skip, 5)
	check("and the victory screen and the vote", skip.phase == "vote" and #GunGameRules.step(skip, 5) == 2 and skip.phase == "live")
end

-- Who plays ------------------------------------------------------------------------

do
	local s = game()
	for id = 1, 2 do
		GunGameRules.join(s, id, 0)
	end
	GunGameRules.died(s, 2, 1, 1, "vandal")
	local late = GunGameRules.join(s, 3, 2)
	check(
		"joining a match under way: spawning at once, on the first gun, on the side with fewer",
		same(late, { 3 }) and GunGameRules.levelOf(s, 3) == 1 and GunGameRules.sideOf(s, 3) == 1 and s.members[3].alive
	)
	for id = 4, 9 do
		GunGameRules.join(s, id, 2)
	end
	check(
		"four a side, and anyone over waits in line",
		Roster.count(s, 1, false) == G.sideSize.value and Roster.count(s, 2, false) == G.sideSize.value and Roster.placeInLine(s, 9) == 1
	)
	local level = GunGameRules.levelOf(s, 1)
	local came = GunGameRules.leave(s, 2, 3)
	check("someone leaving: the first in line takes the place, at once", same(came, { 9 }) and s.members[9] ~= nil and s.members[9].alive)
	check("and the match plays on", s.phase == "live" and GunGameRules.levelOf(s, 1) == level)
end

do
	-- Two against one: players 1 and 3 on side 1, 2 on side 2.
	local s = game()
	for id = 1, 3 do
		GunGameRules.join(s, id, 0)
	end
	GunGameRules.died(s, 2, 1, 3, "vandal")
	local moved = GunGameRules.leave(s, 2, 2)
	check(
		"the last on a side leaving: the last to join the other moves across and spawns there, on their level",
		same(moved, { 3 }) and GunGameRules.sideOf(s, 3) == 2 and GunGameRules.levelOf(s, 3) == 2 and s.phase == "live"
	)

	local duel = game()
	GunGameRules.join(duel, 1, 0)
	GunGameRules.join(duel, 2, 0)
	GunGameRules.died(duel, 2, 1, 1, "vandal")
	GunGameRules.leave(duel, 2, 2)
	check(
		"the only opponent leaving: waiting again, the match given up, back on the first gun",
		duel.phase == "waiting" and GunGameRules.levelOf(duel, 1) == 1 and duel.match == 2 and duel.members[1].kills == 0
	)
	GunGameRules.died(duel, 1, 3, nil, nil)
	check("while waiting, the dead come back in a moment", same(GunGameRules.step(duel, 3 + G.respawnTime.value), { 1 }))
	local fresh = GunGameRules.join(duel, 4, 5)
	check("and a newcomer starts a match afresh", duel.phase == "live" and same(fresh, { 1, 4 }))

	local vote = game()
	GunGameRules.join(vote, 1, 0)
	GunGameRules.join(vote, 2, 0)
	GunGameRules.skip(vote, 1)
	GunGameRules.step(vote, 1)
	GunGameRules.skip(vote, 2)
	GunGameRules.step(vote, 2)
	local during = GunGameRules.join(vote, 3, 3)
	check(
		"joining during the vote: down until the next match, with a vote",
		#during == 0 and not vote.members[3].alive and GunGameRules.vote(vote, 3, 2)
	)
	GunGameRules.leave(vote, 2, 4)
	check(
		"someone leaving during the vote: the sides evened out, and the vote goes on",
		vote.phase == "vote" and GunGameRules.sideOf(vote, 3) == 2 and vote.vote ~= nil
	)
	GunGameRules.leave(vote, 3, 5)
	check(
		"a side emptying during the vote ends it there: waiting, on the same map",
		vote.phase == "waiting" and vote.vote == nil and vote.map == "A"
	)
end

do
	local s = game()
	GunGameRules.join(s, 1, 0)
	GunGameRules.died(s, 1, 1, 2, "vandal")
	check("nothing moves anyone up while waiting for an opponent", GunGameRules.levelOf(s, 1) == 1 and s.members[1].deaths == 0)
	GunGameRules.join(s, 2, 2)
	GunGameRules.join(s, 3, 2)
	GunGameRules.died(s, 1, 3, 3, "vandal")
	check(
		"a kill by a teammate (there are none, but the rules check) moves nobody",
		GunGameRules.sideOf(s, 3) == GunGameRules.sideOf(s, 1) and GunGameRules.levelOf(s, 3) == 1 and s.members[3].kills == 0
	)
	check("nobody's a level without playing", GunGameRules.levelOf(s, 99) == nil and GunGameRules.kitOf(s, 99) == nil)
	check("everyone's protection off until they spawn", not GunGameRules.safe(s, 1, 3))
end

return nil
