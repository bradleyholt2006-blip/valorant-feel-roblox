--!strict
-- The combat report (system 53), as the reference's: what passed between a
-- player and everyone they fought. Riot's UI Settings FAQ has 'the combat
-- report that pops up when you die', and ONE Esports says what's in it: who
-- killed you, the damage you did and took, and 'where you hit your
-- opponents, and where you were shot as well'. Plain state the offline
-- tests can play: the server keeps everyone's (ReportServer) and sends each
-- player theirs, which the client draws (ReportView).
--
-- A report covers a stretch of play: in Skirmish and the spike rounds a
-- round, from its start (CombatReport.clear) to the next's, through
-- whatever Sage's Resurrection brings back (CombatReport.keep); elsewhere a
-- life, from a spawn (CombatReport.open) to the next. Only players have
-- one. Each hit that took health or shield goes in the reports of the two
-- it touched (CombatReport.hit): the attacker's, as dealt to the one hit,
-- and theirs, as taken from the attacker; one that hurts whoever made it (a
-- Shock Bolt's burst) goes in theirs once, as taken from themself. Each
-- goes by what made it, a gun's, a knife's or an ability's id
-- (WeaponConfig's), with the bullets or blades that struck counted by the
-- part each struck; a burst (a Shock Bolt's, a Hunter's Fury blast's) is a
-- hit that struck no part, and a fire's burn, which goes a few points at a
-- time, is no hit at all. Each kill (CombatReport.killed) goes in the
-- killer's report, against the one killed, and in theirs as their death:
-- by whom and with what. The spike's blast and a spawn room's burn have
-- nobody behind them: a death by either is the dead's alone, and their
-- burns go in no report.
--
-- Damage reads in whole points, rounded down (CombatReport.points), so
-- someone left alive never reads as having taken all they had: Patch 0.50
-- fixed the report showing '150 damage but the enemy player was still
-- alive'.

local Volley = require("../Combat/Volley")

export type Parts = Volley.Parts

-- A hit as CombatServer tells of it: the health and shield it took, what
-- made it, how many of its bullets or blades struck each part (none for a
-- burn or a burst), and whether it was a burst.
export type Hit = { damage: number, weapon: string, parts: Parts?, burst: boolean? }

-- What one weapon or ability did one way between two: its damage, its
-- strikes on each part, and its hits that struck no part (`other`).
export type Line = { weapon: string, damage: number, head: number, body: number, legs: number, other: number }

-- All that went one way between two, the same, and by weapon or ability in
-- the order each was first used.
export type Way = { damage: number, head: number, body: number, legs: number, other: number, lines: { Line } }

-- What passed between a report's owner and one other (themself, for what
-- they did to themself): dealt to them, taken from them, and how often the
-- owner killed them and they the owner.
export type Row = { other: number, dealt: Way, taken: Way, kills: number, deaths: number }

-- How a report's owner last died: by whom (nil for nobody: the spike's
-- blast, a spawn room's burn) and with what.
export type Death = { by: number?, weapon: string }

-- A row for everyone the owner fought, in the order they first met.
export type Report = { owner: number, rows: { Row }, death: Death? }

-- Everyone's reports, by entity id.
export type Log = { [number]: Report }

local CombatReport = {}

function CombatReport.newLog(): Log
	return {}
end

-- A fresh report for `owner`, in place of any they had: a new life.
function CombatReport.open(log: Log, owner: number): Report
	local report: Report = { owner = owner, rows = {}, death = nil }
	log[owner] = report
	return report
end

-- `owner`'s report, opened if they have none: a life in a round goes on
-- with the round's.
function CombatReport.keep(log: Log, owner: number): Report
	return log[owner] or CombatReport.open(log, owner)
end

-- Everyone's reports gone: a new round. Each is opened again as its owner
-- spawns into it.
function CombatReport.clear(log: Log)
	table.clear(log)
end

local function newWay(): Way
	return { damage = 0, head = 0, body = 0, legs = 0, other = 0, lines = {} }
end

-- `report`'s row for `other`, a new one at its end if it has none.
local function rowFor(report: Report, other: number): Row
	for _, row in report.rows do
		if row.other == other then
			return row
		end
	end
	local row: Row = { other = other, dealt = newWay(), taken = newWay(), kills = 0, deaths = 0 }
	table.insert(report.rows, row)
	return row
end

-- A hit, added to one way and to its weapon's line there.
local function add(way: Way, hit: Hit)
	local parts = hit.parts
	local head = if parts then parts.head else 0
	local body = if parts then parts.body else 0
	local legs = if parts then parts.legs else 0
	local other = if hit.burst then 1 else 0
	local line: Line? = nil
	for _, each in way.lines do
		if each.weapon == hit.weapon then
			line = each
			break
		end
	end
	local l: Line = line or { weapon = hit.weapon, damage = 0, head = 0, body = 0, legs = 0, other = 0 }
	if not line then
		table.insert(way.lines, l)
	end
	way.damage += hit.damage
	way.head += head
	way.body += body
	way.legs += legs
	way.other += other
	l.damage += hit.damage
	l.head += head
	l.body += body
	l.legs += legs
	l.other += other
end

-- A hit by `attacker` (nil for nobody) on `victim`, by entity id. Returns
-- whose reports it went in.
function CombatReport.hit(log: Log, attacker: number?, victim: number, hit: Hit): { number }
	local changed = {}
	if attacker == nil or hit.damage <= 0 then
		return changed
	end
	local theirs = log[victim]
	if attacker == victim then
		if theirs then
			add(rowFor(theirs, victim).taken, hit)
			table.insert(changed, victim)
		end
		return changed
	end
	local mine = log[attacker]
	if mine then
		add(rowFor(mine, victim).dealt, hit)
		table.insert(changed, attacker)
	end
	if theirs then
		add(rowFor(theirs, attacker).taken, hit)
		table.insert(changed, victim)
	end
	return changed
end

-- A kill of `victim` by `killer` (nil for nobody) with `weapon`, by entity
-- id. Returns whose reports it went in.
function CombatReport.killed(log: Log, killer: number?, victim: number, weapon: string): { number }
	local changed = {}
	local theirs = log[victim]
	if theirs then
		theirs.death = { by = killer, weapon = weapon }
		if killer then
			rowFor(theirs, killer).deaths += 1
		end
		table.insert(changed, victim)
	end
	local mine = if killer and killer ~= victim then log[killer] else nil
	if killer and mine then
		rowFor(mine, victim).kills += 1
		table.insert(changed, killer)
	end
	return changed
end

-- The rows in the order the report shows them: whoever killed its owner
-- last first, then the rest in the order they first met.
function CombatReport.ordered(report: Report): { Row }
	local death = report.death
	local by = if death then death.by else nil
	local out = {}
	for _, row in report.rows do
		if by ~= nil and row.other == by then
			table.insert(out, 1, row)
		else
			table.insert(out, row)
		end
	end
	return out
end

-- Damage in whole points, rounded down.
function CombatReport.points(value: number): number
	local whole = math.floor(value + 1e-6)
	return if whole > 0 then whole else 0
end

-- How many hits one way or one line counts: its strikes on every part and
-- its hits that struck none.
function CombatReport.hits(t: { head: number, body: number, legs: number, other: number }): number
	return t.head + t.body + t.legs + t.other
end

-- All the owner dealt others and all they took, themself included, in
-- whole points.
function CombatReport.totals(report: Report): (number, number)
	local dealt, taken = 0, 0
	for _, row in report.rows do
		dealt += row.dealt.damage
		taken += row.taken.damage
	end
	return CombatReport.points(dealt), CombatReport.points(taken)
end

-- One way, as scripted checks read it: its damage in whole points, and its
-- strikes by part, then its hits that struck none, where there are any
-- ("156 (1 head, 1 body)", "60 (1 other)", "23").
function CombatReport.wayText(way: Way): string
	local parts = {}
	local counts = { way.head, way.body, way.legs, way.other }
	for i, name in { "head", "body", "legs", "other" } do
		if counts[i] > 0 then
			table.insert(parts, string.format("%d %s", counts[i], name))
		end
	end
	local points = tostring(CombatReport.points(way.damage))
	return if #parts > 0 then string.format("%s (%s)", points, table.concat(parts, ", ")) else points
end

-- A row, as scripted checks read it, with `name` for whom it's with:
-- "Dummy 1: dealt 156 (1 head, 1 body), taken 0, killed".
function CombatReport.rowText(row: Row, name: string): string
	local text = string.format("%s: dealt %s, taken %s", name, CombatReport.wayText(row.dealt), CombatReport.wayText(row.taken))
	if row.kills > 0 then
		text ..= if row.kills > 1 then string.format(", killed %dx", row.kills) else ", killed"
	end
	if row.deaths > 0 then
		text ..= if row.deaths > 1 then string.format(", killed you %dx", row.deaths) else ", killed you"
	end
	return text
end

return CombatReport
