--!strict
-- The combat report (system 53): what goes in whose report (CombatReport.hit
-- and killed), by weapon and by part, a burst's and a burn's hits, what
-- hurts yourself, kills and deaths, what nobody did, the order its rows
-- show in, the damage in whole points (Patch 0.50), a report's stretch
-- (open, keep and clear), and the text scripted checks read. And the
-- bullets of a volley counted by the part each struck (Volley.totals).

local CombatReport = require("../src/shared/Match/CombatReport")
local Volley = require("../src/shared/Combat/Volley")
local H = require("./Harness")

local check = H.check
local near = H.near

H.section("Combat report (system 53)")

local A, B, C = 1, 2, 3
local DUMMY = 4294901761

local function parts(head: number, body: number, legs: number): CombatReport.Parts
	return { head = head, body = body, legs = legs }
end

local function shot(damage: number, weapon: string, head: number, body: number, legs: number): CombatReport.Hit
	return { damage = damage, weapon = weapon, parts = parts(head, body, legs) }
end

-- The row in `report` with `other`, if there's one.
local function rowWith(report: CombatReport.Report?, other: number): CombatReport.Row?
	if not report then
		return nil
	end
	for _, row in report.rows do
		if row.other == other then
			return row
		end
	end
	return nil
end

do
	local totals = Volley.totals({
		{ target = 7, region = "body", damage = 17 },
		{ target = 9, region = "legs", damage = 14.45 },
		{ target = 7, region = "head", damage = 34 },
		{ target = 7, region = "legs", damage = 14.45 },
		{ target = 7, region = "body", damage = 17 },
	})
	local seven, nine = totals[1].parts, totals[2].parts
	check(
		"a volley counts its bullets on each target by the part each struck",
		seven.head == 1 and seven.body == 2 and seven.legs == 1 and nine.head == 0 and nine.body == 0 and nine.legs == 1
	)
end

do
	local log = CombatReport.newLog()
	CombatReport.open(log, A)
	CombatReport.open(log, B)
	local changed = CombatReport.hit(log, A, B, shot(40, "vandal", 0, 1, 0))
	local mine, theirs = rowWith(log[A], B), rowWith(log[B], A)
	check("a hit goes in both reports it touched", #changed == 2 and mine ~= nil and theirs ~= nil)
	check(
		"as dealt in the attacker's and taken in the one hit's",
		mine ~= nil
			and theirs ~= nil
			and mine.dealt.damage == 40
			and mine.taken.damage == 0
			and theirs.taken.damage == 40
			and theirs.dealt.damage == 0
	)
	check(
		"with the part it struck",
		mine ~= nil and mine.dealt.body == 1 and mine.dealt.head == 0 and theirs ~= nil and theirs.taken.body == 1
	)

	CombatReport.hit(log, A, B, shot(110, "vandal", 1, 0, 0))
	CombatReport.hit(log, B, A, shot(18, "classic", 0, 0, 1))
	CombatReport.hit(log, B, A, { damage = 60, weapon = "shockbow", burst = true })
	CombatReport.hit(log, B, A, { damage = 4.5, weapon = "fireball" })
	CombatReport.hit(log, B, A, { damage = 3.5, weapon = "fireball" })
	mine, theirs = rowWith(log[A], B), rowWith(log[B], A)
	check(
		"damage adds up each way, the parts too",
		mine ~= nil
			and mine.dealt.damage == 150
			and mine.dealt.head == 1
			and mine.dealt.body == 1
			and near(mine.taken.damage, 86, 1e-9)
			and mine.taken.legs == 1
	)
	local lines = if mine then mine.taken.lines else {}
	check(
		"and by weapon or ability, in the order each was first used",
		#lines == 3 and lines[1].weapon == "classic" and lines[2].weapon == "shockbow" and lines[3].weapon == "fireball"
	)
	check(
		"a burst is a hit that struck no part",
		#lines == 3 and lines[2].other == 1 and CombatReport.hits(lines[2]) == 1 and lines[2].head + lines[2].body + lines[2].legs == 0
	)
	check(
		"a burn, a few points at a time, is no hit at all",
		#lines == 3 and near(lines[3].damage, 8, 1e-9) and CombatReport.hits(lines[3]) == 0
	)
	check(
		"so the way's hits are its strikes and its bursts",
		mine ~= nil and CombatReport.hits(mine.taken) == 2 and CombatReport.hits(mine.dealt) == 2
	)
	check("the two still have one row each", log[A] ~= nil and #log[A].rows == 1 and log[B] ~= nil and #log[B].rows == 1)

	CombatReport.hit(log, B, A, { damage = 0, weapon = "vandal", parts = parts(1, 0, 0) })
	check("a hit that took nothing goes nowhere", mine ~= nil and CombatReport.hits(mine.taken) == 2)
end

do
	local log = CombatReport.newLog()
	CombatReport.open(log, A)
	CombatReport.open(log, B)
	CombatReport.open(log, C)
	CombatReport.hit(log, A, DUMMY, shot(156, "vandal", 1, 1, 0))
	CombatReport.hit(log, B, C, shot(40, "vandal", 0, 1, 0))
	local dummy = rowWith(log[A], DUMMY)
	check("a dummy's hits go in your report, though it has none", dummy ~= nil and dummy.dealt.damage == 156 and log[DUMMY] == nil)
	check(
		"and nobody's report has anyone they didn't fight",
		log[A] ~= nil and #log[A].rows == 1 and rowWith(log[A], B) == nil and rowWith(log[A], C) == nil
	)
	local changed = CombatReport.hit(log, nil, A, { damage = 25, weapon = "spawnroom" })
	check("what nobody did goes in no report", #changed == 0 and log[A] ~= nil and #log[A].rows == 1)
	CombatReport.hit(log, C, A, shot(30, "spectre", 0, 1, 0))
	CombatReport.hit(log, B, A, shot(26, "classic", 0, 1, 0))
	check(
		"rows come in the order they first met",
		log[A] ~= nil and log[A].rows[1].other == DUMMY and log[A].rows[2].other == C and log[A].rows[3].other == B
	)
	local killed = CombatReport.killed(log, B, A, "classic")
	local death = if log[A] then log[A].death else nil
	check("a kill goes in the killer's report and the dead's", #killed == 2)
	check("the dead's says who killed them and with what", death ~= nil and death.by == B and death.weapon == "classic")
	local theirs, mine = rowWith(log[B], A), rowWith(log[A], B)
	check("the killer's row for the dead counts the kill", theirs ~= nil and theirs.kills == 1 and theirs.deaths == 0)
	check("and the dead's row for the killer their death", mine ~= nil and mine.deaths == 1 and mine.kills == 0)
	local ordered = if log[A] then CombatReport.ordered(log[A]) else {}
	check(
		"whoever killed you shows first, the rest as you met them",
		#ordered == 3 and ordered[1].other == B and ordered[2].other == DUMMY and ordered[3].other == C
	)
	CombatReport.killed(log, A, DUMMY, "vandal")
	CombatReport.killed(log, A, DUMMY, "vandal")
	dummy = rowWith(log[A], DUMMY)
	check("a dummy killed twice counts twice", dummy ~= nil and dummy.kills == 2)
	local dealt, taken = CombatReport.totals(log[A] :: CombatReport.Report)
	check("the totals: all you dealt and all you took", dealt == 156 and taken == 56, string.format("%d, %d", dealt, taken))
end

do
	local log = CombatReport.newLog()
	CombatReport.open(log, A)
	CombatReport.open(log, B)
	CombatReport.hit(log, A, A, { damage = 25, weapon = "shockbow", burst = true })
	local own = rowWith(log[A], A)
	check(
		"what you do to yourself goes in a row for yourself, once, as taken",
		own ~= nil and own.taken.damage == 25 and own.dealt.damage == 0
	)
	check("and nobody else's report", log[B] ~= nil and #log[B].rows == 0)
	CombatReport.killed(log, A, A, "shockbow")
	own = rowWith(log[A], A)
	local death = if log[A] then log[A].death else nil
	check(
		"killing yourself is a death by yourself, and no kill",
		own ~= nil and own.kills == 0 and own.deaths == 1 and death ~= nil and death.by == A
	)
	local dealt, taken = CombatReport.totals(log[A] :: CombatReport.Report)
	check("and it's in what you took, not in what you dealt", dealt == 0 and taken == 25)

	CombatReport.killed(log, nil, B, "spike")
	local spiked = if log[B] then log[B].death else nil
	check("the spike's blast kills with nobody behind it", spiked ~= nil and spiked.by == nil and spiked.weapon == "spike")
	check("and no row for it", log[B] ~= nil and #log[B].rows == 0)
	local ordered = if log[B] then CombatReport.ordered(log[B]) else {}
	check("so nobody shows first", #ordered == 0)
end

do
	check("damage reads in whole points", CombatReport.points(150) == 150 and CombatReport.points(86.7) == 86)
	check("rounded down: someone left on 0.4 never reads as having taken all 150 (Patch 0.50)", CombatReport.points(149.6) == 149)
	check("a split hit's rounding error doesn't cost a point", CombatReport.points(149.9999999) == 150)
	check("and nothing never reads below 0", CombatReport.points(0) == 0 and CombatReport.points(-1) == 0)
end

do
	local log = CombatReport.newLog()
	local first = CombatReport.open(log, A)
	CombatReport.hit(log, A, B, shot(40, "vandal", 0, 1, 0))
	local kept = CombatReport.keep(log, A)
	check("a life in a round goes on with the round's report (keep)", kept == first and #kept.rows == 1)
	local fresh = CombatReport.open(log, A)
	check("a new life starts a fresh one (open)", fresh ~= first and #fresh.rows == 0 and log[A] == fresh)
	CombatReport.clear(log)
	check("a new round clears everyone's", log[A] == nil)
	check("and a hit then goes nowhere till they're opened again", #CombatReport.hit(log, A, B, shot(40, "vandal", 0, 1, 0)) == 0)
	check("keep opens one for someone without", #CombatReport.keep(log, B).rows == 0 and log[B] ~= nil)
end

do
	local log = CombatReport.newLog()
	CombatReport.open(log, A)
	CombatReport.hit(log, A, DUMMY, shot(156, "vandal", 1, 1, 0))
	CombatReport.killed(log, A, DUMMY, "vandal")
	local row = rowWith(log[A], DUMMY)
	check(
		"a row as scripted checks read it",
		row ~= nil and CombatReport.rowText(row, "Dummy 1") == "Dummy 1: dealt 156 (1 head, 1 body), taken 0, killed",
		if row then CombatReport.rowText(row, "Dummy 1") else "no row"
	)
	CombatReport.open(log, B)
	CombatReport.hit(log, B, A, { damage = 60, weapon = "shockbow", burst = true })
	CombatReport.hit(log, B, A, { damage = 23.5, weapon = "fireball" })
	CombatReport.killed(log, B, A, "fireball")
	local theirs = rowWith(log[A], B)
	check(
		"a burst reads as other, a burn as damage alone, and a death as killed you",
		theirs ~= nil and CombatReport.rowText(theirs, "Player2") == "Player2: dealt 0, taken 83 (1 other), killed you",
		if theirs then CombatReport.rowText(theirs, "Player2") else "no row"
	)
	CombatReport.killed(log, A, DUMMY, "vandal")
	row = rowWith(log[A], DUMMY)
	check("two kills read as killed 2x", row ~= nil and string.find(CombatReport.rowText(row, "Dummy 1"), "killed 2x", 1, true) ~= nil)
end

return nil
