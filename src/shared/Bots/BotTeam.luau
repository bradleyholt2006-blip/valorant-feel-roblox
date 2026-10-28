--!strict
-- Where a side's bots go together (system 60), as the Counter-Strike bot's
-- go: each round its side has a plan, and each bot a job in it (Booth,
-- "The Official Counter-Strike Bot", GDC 2004):
--   * attackers pick a site, and a way in or two, and gather a few metres
--     short of each way in, spread out, walking the last of it quietly.
--     Once most are there, or the clock says so, or they've been seen,
--     they push in together, through their way, and take the site, each
--     to a spot on it watching the way the defenders come back. A while
--     after that with nobody seen, they go looking
--   * defenders split over the sites, each to a spot holding one of its
--     entrances (BotSpots), and the spots of a site cover all its ways in.
--     When attackers turn up at one site, those at the other come over,
--     all but one, who stays
--   * a player on the side leads: attackers go with them to the site
--     they're making for, and in with them if they go in. With no plan to
--     keep to (the modes that respawn), bots follow a player on their
--     side, round them, as the Counter-Strike bot follows a player who
--     tells it to
--   * with no player to follow, a side goes where its enemies were last
--     seen, together, else from place to place over the map
--
-- Every bot's job is a node to walk to and a point to look at once it's
-- there: BotMove takes it there, round walls and up stairs, and BotBrain
-- looks and fights. Bots of a side never stand on the same spot: those
-- making for the same place are spread round it.
--
-- Plain state and maths in metres, in the map's own frame, as BotNav's.

local BotConfig = require("./BotConfig")
local BotNav = require("./BotNav")
local BotSpots = require("./BotSpots")

local BotTeam = {}

-- What the side plays: a spike map's attack or defence, or a side (or a
-- lone bot, in deathmatch) of the modes that respawn.
export type Side = "attack" | "defend" | "team"

export type Task = "wait" | "gather" | "push" | "take" | "hunt" | "hold" | "rotate" | "follow" | "roam"

-- Someone on the side, as the server shows it: a bot or a player.
export type Member = {
	id: number,
	bot: boolean,
	alive: boolean,
	feet: vector,
}

-- Where an enemy was seen by someone on the side, and when.
export type Sighting = { at: vector, time: number }

-- A bot's job this moment: where it walks to (nil to stay), where it looks
-- once there (nil for wherever it's looking), and whether it walks
-- quietly.
export type Order = {
	task: Task,
	goal: number?,
	look: vector?,
	walk: boolean,
}

type Job = {
	task: Task,
	goal: number?,
	look: vector?,
	walk: boolean,
	-- The spot it was dealt round a place, and the place: kept while it's
	-- going there, so a bot doesn't swap with another as the side changes.
	spot: number?,
	spotOf: number?,
	way: number?, -- attackers: the way in it takes, by number in the site's entrances
	through: boolean, -- attackers: through its way in, on the push
	site: string?, -- defenders: the site it holds
	hold: number?, -- and which of its holds, in the order they're dealt
}

type Phase = "gather" | "push" | "take" | "hunt"

export type Team = {
	nav: BotNav.Nav,
	plan: BotSpots.Plan?, -- a spike map's, for the spike rounds' sides
	side: Side,
	dice: BotConfig.Dice,
	places: { number }, -- nodes to go from one to another of
	enemySpawn: { number }, -- the nodes the enemy spawns on, if known
	-- This round's plan: the attackers' site, ways in and how far along
	-- they are; when it began and when the push goes at the latest.
	site: string?,
	ways: { number },
	phase: Phase,
	began: number?,
	pushAt: number,
	tookAt: number,
	jobs: { [number]: Job },
	-- When attackers were last seen at each site (defenders).
	contact: { [string]: number },
	-- Where the side's going, in the modes that respawn, since when, and
	-- the spot it was put at.
	focus: number?,
	focusAt: number,
	focusFrom: vector?,
}

local EYE = 1.62 -- standing (MovementConfig's standEyeHeight)

-- The share of the gathering bots at their spots that sends the push.
BotTeam.GATHERED = 0.7
-- When the push goes at the latest: this long into the round, give or
-- take SPREAD (estimate; a round is 100 s).
BotTeam.PUSH_BY = 32
BotTeam.PUSH_SPREAD = 8
-- The share of rounds the attackers split over two ways in, if there are
-- enough of them.
BotTeam.SPLIT = 0.35
BotTeam.SPLIT_FROM = 4
-- How near its stage a gathering bot walks, quietly.
BotTeam.QUIET = 12
-- How near its spot a bot counts as there.
BotTeam.THERE = 2.5
-- How far apart bots making for the same place stand, and how far round
-- it they spread at the most.
BotTeam.APART = 1.6
BotTeam.SPREAD = 5
-- How long after taking a site, with no one seen, the attackers go
-- looking.
BotTeam.TAKE_TIME = 20
-- How recent a sighting is to count: CS:GO's Deathmatch bots remember an
-- enemy 10 s (BotConfig's memory).
BotTeam.MEMORY = BotConfig.Params.memory.value
-- A sighting this near a gathering bot's spot, this recently, gives the
-- push away: they've been seen.
BotTeam.SPOTTED = 25
BotTeam.SPOTTED_TIME = 3
-- How far out from a site's area a sighting counts as at that site, how
-- long the others wait before coming over, and for how long it counts.
BotTeam.CONTACT = 6
BotTeam.ROTATE_DELAY = 3
BotTeam.CONTACT_TIME = 15
-- A player leads the attackers to a site once they've come this far from
-- spawn and this much nearer it than the one planned.
BotTeam.LEAD = 12
BotTeam.LEAD_BY = 10
-- Following: how far round the player the bots stand, and how far the
-- player goes before they move up.
BotTeam.FOLLOW_NEAR = 3
BotTeam.FOLLOW_FAR = 7
BotTeam.FOLLOW_MOVE = 4
-- How long a side keeps making for a place before choosing another.
BotTeam.PLACE_TIME = 25

local function feet(nav: BotNav.Nav, n: number): vector
	return BotNav.feet(nav, n)
end

-- The nodes `field` puts nearest: where it's measured from.
local function zeros(field: { number }): { number }
	local out = {}
	for n, d in field do
		if d == 0 then
			table.insert(out, n)
		end
	end
	return out
end

function BotTeam.new(nav: BotNav.Nav, plan: BotSpots.Plan?, side: Side, dice: BotConfig.Dice, places: { number }?): Team
	local enemySpawn = {}
	if plan and side == "attack" then
		enemySpawn = zeros(plan.defend)
	elseif plan and side == "defend" then
		enemySpawn = zeros(plan.attack)
	end
	return {
		nav = nav,
		plan = plan,
		side = side,
		dice = dice,
		places = places or {},
		enemySpawn = enemySpawn,
		site = nil,
		ways = {},
		phase = "gather",
		began = nil,
		pushAt = math.huge,
		tookAt = math.huge,
		jobs = {},
		contact = {},
		focus = nil,
		focusAt = -math.huge,
		focusFrom = nil,
	}
end

-- The nodes nearest each of `points` that bots can stand on, for places to
-- go between: rooms' middles, say.
function BotTeam.placesOf(nav: BotNav.Nav, points: { vector }): { number }
	local out = {}
	for _, p in points do
		local n = BotNav.nodeAt(nav, p, 4)
		if n and not nav.edges[n] then
			table.insert(out, n)
		end
	end
	return out
end

-- Up to `count` nodes round node `centre`, nearest first, each at least
-- APART from the others and SPREAD from it at the most, on its level and
-- walked to from it in a straight line: spots for bots making for the
-- same place. Fewer if there's no room; the centre itself first.
function BotTeam.spread(nav: BotNav.Nav, centre: number, count: number): { number }
	local out = { centre }
	if count <= 1 then
		return out
	end
	local C = nav.options.cell
	local r = math.ceil(BotTeam.SPREAD / C)
	local i0, j0 = nav.ci[centre], nav.cj[centre]
	local cx, cy, cz = nav.xs[centre], nav.ys[centre], nav.zs[centre]
	local near: { { n: number, d: number } } = {}
	for i = math.max(i0 - r, 1), math.min(i0 + r, nav.nx) do
		for j = math.max(j0 - r, 1), math.min(j0 + r, nav.nz) do
			for _, n in nav.at[(j - 1) * nav.nx + i] do
				local d = math.sqrt((nav.xs[n] - cx) ^ 2 + (nav.zs[n] - cz) ^ 2)
				if n ~= centre and d <= BotTeam.SPREAD and math.abs(nav.ys[n] - cy) < 1 and not nav.edges[n] then
					table.insert(near, { n = n, d = d })
				end
			end
		end
	end
	table.sort(near, function(a, b): boolean
		if a.d ~= b.d then
			return a.d < b.d
		end
		return a.n < b.n
	end)
	for _, c in near do
		if #out >= count then
			break
		end
		local p = feet(nav, c.n)
		local apart = true
		for _, other in out do
			if vector.magnitude(feet(nav, other) - p) < BotTeam.APART then
				apart = false
				break
			end
		end
		if apart and BotNav.straight(nav, centre, c.n) then
			table.insert(out, c.n)
		end
	end
	return out
end

-- A new round: the plan made again, nothing assigned. The attackers' site
-- and ways in are chosen now.
function BotTeam.round(team: Team, now: number)
	team.jobs = {}
	team.contact = {}
	team.phase = "gather"
	team.began = nil
	team.pushAt = math.huge
	team.tookAt = math.huge
	team.focus = nil
	team.focusAt = -math.huge
	team.focusFrom = nil
	team.site = nil
	team.ways = {}
	local plan = team.plan
	if team.side == "attack" and plan and #plan.sites > 0 then
		local site = plan.sites[math.floor(team.dice() * #plan.sites) + 1]
		BotTeam.aim(team, site.name)
	end
end

-- The attackers make for site `name`: its ways in chosen again, and each
-- bot's way with them.
function BotTeam.aim(team: Team, name: string)
	local plan = team.plan :: BotSpots.Plan
	local site = BotSpots.site(plan, name)
	if not site or #site.entrances == 0 then
		return
	end
	team.site = name
	local n = #site.entrances
	local first = math.floor(team.dice() * n) + 1
	team.ways = { first }
	if n >= 2 and team.dice() < BotTeam.SPLIT then
		table.insert(team.ways, first % n + 1)
	end
	for _, job in team.jobs do
		job.way = nil
		job.through = false
	end
end

-- The living bots and players, each in id order.
local function sorted(members: { Member }): ({ Member }, { Member })
	local bots, players = {}, {}
	for _, m in members do
		if m.alive then
			table.insert(if m.bot then bots else players, m)
		end
	end
	local function byId(a: Member, b: Member): boolean
		return a.id < b.id
	end
	table.sort(bots, byId)
	table.sort(players, byId)
	return bots, players
end

local function nodeOf(team: Team, p: vector): number?
	return BotNav.nodeAt(team.nav, p, 3)
end

local function near(team: Team, m: Member, n: number?, within: number): boolean
	if n == nil then
		return false
	end
	local p = feet(team.nav, n)
	return (p.x - m.feet.x) ^ 2 + (p.z - m.feet.z) ^ 2 <= within * within and math.abs(p.y - m.feet.y) < 1.5
end

-- The latest sighting within MEMORY, if any.
local function latest(sightings: { Sighting }, now: number): Sighting?
	local best: Sighting? = nil
	for _, s in sightings do
		if now - s.time <= BotTeam.MEMORY and (best == nil or s.time > best.time) then
			best = s
		end
	end
	return best
end

-- Head height over node n: where to look at, there.
local function head(nav: BotNav.Nav, n: number): vector
	return feet(nav, n) + vector.create(0, EYE, 0)
end

-- How many spots are dealt round a place at the least, so a bot keeps
-- its spot as others die or join.
local DEALT = 6

-- Spots for `bots` round node `centre`: a bot keeps the one it was dealt
-- round it before; the rest, in id order, take the nearest free. If
-- there are too few, the last is shared.
local function deal(team: Team, bots: { Member }, centre: number): { [number]: number }
	local spots = BotTeam.spread(team.nav, centre, math.max(#bots, DEALT))
	local free: { [number]: boolean } = {}
	for _, n in spots do
		free[n] = true
	end
	local out: { [number]: number } = {}
	for _, m in bots do
		local job = team.jobs[m.id]
		local had = if job and job.spotOf == centre then job.spot else nil
		if had and free[had] then
			out[m.id] = had
			free[had] = false
		end
	end
	local k = 1
	for _, m in bots do
		if out[m.id] == nil then
			while k < #spots and not free[spots[k]] do
				k += 1
			end
			out[m.id] = spots[k]
			free[spots[k]] = false
		end
		local job = team.jobs[m.id]
		if job then
			job.spot, job.spotOf = out[m.id], centre
		end
	end
	return out
end

-- The attackers: the plan, followed.
local function attack(team: Team, now: number, bots: { Member }, players: { Member }, sightings: { Sighting })
	local plan = team.plan :: BotSpots.Plan
	local nav = team.nav
	if team.site == nil then
		return
	end
	-- A player leads: in with them if they're in a site, else to the site
	-- they're making for, while the bots are still gathering.
	for _, p in players do
		local n = nodeOf(team, p.feet)
		if not n then
			continue
		end
		local planned = BotSpots.site(plan, team.site :: string) :: BotSpots.Site
		for _, s in plan.sites do
			local inside = s.field[n] <= BotSpots.AREA
			local leading = plan.attack[n] >= BotTeam.LEAD and s.field[n] + BotTeam.LEAD_BY < planned.field[n]
			if s.name ~= team.site and (inside or leading) and (team.phase == "gather" or inside) then
				BotTeam.aim(team, s.name)
				planned = s
			end
			if inside and s.name == team.site and team.phase == "gather" then
				team.phase = "push"
			end
		end
	end
	local site = BotSpots.site(plan, team.site :: string) :: BotSpots.Site
	-- Each bot's way in: the one the fewest have.
	local counts: { [number]: number } = {}
	for _, w in team.ways do
		counts[w] = 0
	end
	for _, m in bots do
		local job = team.jobs[m.id]
		if job and job.way and counts[job.way] then
			counts[job.way] += 1
		end
	end
	local byWay: { [number]: { Member } } = {}
	for _, m in bots do
		local j: Job = team.jobs[m.id] or { task = "gather", walk = false, through = false }
		team.jobs[m.id] = j
		if not j.way or not counts[j.way] then
			local best, fewest = team.ways[1], math.huge
			for _, w in team.ways do
				if counts[w] < fewest then
					best, fewest = w, counts[w]
				end
			end
			j.way = best
			counts[best] += 1
		end
		local w = j.way :: number
		byWay[w] = byWay[w] or {}
		table.insert(byWay[w], m)
	end
	-- The gather's spots, and whether enough are at them.
	local stageSpot: { [number]: number } = {}
	for w, group in byWay do
		for id, n in deal(team, group, site.entrances[w].stage) do
			stageSpot[id] = n
		end
	end
	if team.phase == "gather" then
		local there = 0
		local spotted = false
		for _, m in bots do
			if near(team, m, stageSpot[m.id], BotTeam.THERE) then
				there += 1
			end
			for _, s in sightings do
				if now - s.time <= BotTeam.SPOTTED_TIME and vector.magnitude(s.at - m.feet) <= BotTeam.SPOTTED then
					spotted = true
				end
			end
		end
		if #bots > 0 and there >= math.ceil(#bots * BotTeam.GATHERED) or now >= team.pushAt or spotted then
			team.phase = "push"
		end
	end
	local onSite = 0
	for _, m in bots do
		local n = nodeOf(team, m.feet)
		if n and site.field[n] <= BotSpots.AREA then
			onSite += 1
		end
	end
	if team.phase == "push" and #bots > 0 and onSite * 2 >= #bots then
		team.phase = "take"
		team.tookAt = now
	end
	local recent = latest(sightings, now)
	if team.phase == "take" and now - team.tookAt >= BotTeam.TAKE_TIME and (recent == nil or now - recent.time > BotTeam.MEMORY) then
		team.phase = "hunt"
	end
	-- Each bot's job in the phase.
	local siteSpot = deal(team, bots, site.centre)
	for _, m in bots do
		local job = team.jobs[m.id]
		local entrance = site.entrances[job.way :: number]
		if team.phase == "gather" then
			local spot = stageSpot[m.id]
			job.task = "gather"
			job.goal = spot
			job.look = head(nav, entrance.node)
			job.walk = near(team, m, spot, BotTeam.QUIET)
		elseif team.phase == "push" then
			-- In through its way, then to its spot on the site.
			if not job.through and near(team, m, entrance.node, BotTeam.THERE) then
				job.through = true
			end
			local n = nodeOf(team, m.feet)
			if n and site.field[n] <= BotSpots.AREA then
				job.through = true
			end
			job.task = "push"
			job.goal = if job.through then siteSpot[m.id] else entrance.node
			job.look = nil
			job.walk = false
		elseif team.phase == "take" then
			local spot = siteSpot[m.id]
			job.task = "take"
			job.goal = spot
			-- Watching the way the defenders come back from their spawn.
			job.look = head(nav, BotSpots.down(nav, plan.defend, spot, 12))
			job.walk = false
		else
			job.task = "hunt"
			local target = if recent then nodeOf(team, recent.at) else nil
			if target == nil and #team.enemySpawn > 0 then
				target = team.enemySpawn[(m.id % #team.enemySpawn) + 1]
			end
			job.goal = target
			job.look = nil
			job.walk = false
		end
	end
end

-- The defenders: a site and a hold each, and over to a site the attackers
-- turn up at.
local function defend(team: Team, now: number, bots: { Member }, sightings: { Sighting })
	local plan = team.plan :: BotSpots.Plan
	local sites = plan.sites
	if #sites == 0 then
		return
	end
	-- Where attackers have been seen.
	for _, s in sightings do
		local n = nodeOf(team, s.at)
		if n then
			for _, site in sites do
				if site.field[n] <= BotSpots.AREA + BotTeam.CONTACT then
					team.contact[site.name] = math.max(team.contact[site.name] or -math.huge, s.time)
				end
			end
		end
	end
	-- A site each, by turns, for those without one.
	local count: { [string]: number } = {}
	for _, site in sites do
		count[site.name] = 0
	end
	for _, m in bots do
		local job = team.jobs[m.id]
		if job and job.site then
			count[job.site] += 1
		end
	end
	for _, m in bots do
		if not team.jobs[m.id] then
			local best, fewest = sites[1].name, math.huge
			-- From a different start each round, so the split isn't the same.
			local start = math.floor(team.dice() * #sites)
			for k = 1, #sites do
				local site = sites[(start + k - 1) % #sites + 1]
				if count[site.name] < fewest then
					best, fewest = site.name, count[site.name]
				end
			end
			team.jobs[m.id] = { task = "hold", walk = false, through = false, site = best }
			count[best] += 1
		end
	end
	-- Over to a site with attackers at it, all but one of each other site.
	for _, site in sites do
		local at = team.contact[site.name]
		if at and now - at >= BotTeam.ROTATE_DELAY and now - at <= BotTeam.CONTACT_TIME then
			for _, m in bots do
				local job = team.jobs[m.id]
				if job.site ~= site.name and count[job.site :: string] > 1 then
					count[job.site :: string] -= 1
					count[site.name] += 1
					job.site = site.name
					job.hold = nil
					job.task = "rotate"
				end
			end
		end
	end
	-- Each site's holds, its ways in by turns, dealt to its bots in id order.
	for _, site in sites do
		local byWay: { { BotSpots.Hold } } = {}
		for _, h in site.holds do
			byWay[h.entrance] = byWay[h.entrance] or {}
			table.insert(byWay[h.entrance], h)
		end
		local order: { BotSpots.Hold } = {}
		for depth = 1, BotSpots.HOLDS do
			for w = 1, #site.entrances do
				local list = byWay[w]
				if list and list[depth] then
					table.insert(order, list[depth])
				end
			end
		end
		-- A bot keeps its hold; the rest take the first free, in id order.
		local taken: { [number]: boolean } = {}
		for _, m in bots do
			local job = team.jobs[m.id]
			if job.site == site.name and job.hold then
				taken[job.hold :: number] = true
			end
		end
		for _, m in bots do
			local job = team.jobs[m.id]
			if job.site ~= site.name then
				continue
			end
			if job.hold == nil then
				for k = 1, #order do
					if not taken[k] then
						job.hold = k
						taken[k] = true
						break
					end
				end
			end
			local hold = if job.hold then order[job.hold :: number] else nil
			if hold then
				job.goal = hold.node
				job.look = hold.aim
			else
				job.goal = site.centre
				job.look = nil
			end
			if job.task ~= "rotate" or near(team, m, job.goal, BotTeam.THERE) then
				job.task = "hold"
			end
			job.walk = false
		end
	end
end

-- The modes that respawn: round a player, else where enemies were seen,
-- else from place to place.
local function together(team: Team, now: number, bots: { Member }, players: { Member }, sightings: { Sighting })
	local nav = team.nav
	local leader = players[1]
	local task: Task = "roam"
	if leader then
		task = "follow"
		local moved = team.focusFrom == nil or vector.magnitude(leader.feet - (team.focusFrom :: vector)) > BotTeam.FOLLOW_MOVE
		if moved or team.focus == nil then
			team.focus = nodeOf(team, leader.feet)
			team.focusFrom = leader.feet
			team.focusAt = now
		end
	else
		local recent = latest(sightings, now)
		if recent and (team.focusFrom == nil or vector.magnitude(recent.at - (team.focusFrom :: vector)) > BotTeam.FOLLOW_MOVE) then
			team.focus = nodeOf(team, recent.at)
			team.focusFrom = recent.at
			team.focusAt = now
		end
		task = if recent then "hunt" else "roam"
		-- On to another place once there, or after a while.
		local there = 0
		for _, m in bots do
			if team.focus and near(team, m, team.focus, BotTeam.SPREAD) then
				there += 1
			end
		end
		local arrived = #bots > 0 and there * 2 >= #bots
		if not recent and (team.focus == nil or arrived or now - team.focusAt > BotTeam.PLACE_TIME) and #team.places > 0 then
			local pick = team.places[math.floor(team.dice() * #team.places) + 1]
			if pick == team.focus and #team.places > 1 then
				pick = team.places[(table.find(team.places, pick) :: number) % #team.places + 1]
			end
			team.focus = pick
			team.focusFrom = feet(nav, pick)
			team.focusAt = now
		end
	end
	local focus = team.focus
	if focus == nil then
		for _, m in bots do
			team.jobs[m.id] = { task = task, goal = nil, look = nil, walk = false, through = false }
		end
		return
	end
	-- Round the leader: not on them, between near and far; else spread
	-- round the place.
	local spots = deal(team, bots, focus)
	for _, m in bots do
		local goal = spots[m.id]
		if leader and goal == focus then
			local others = BotTeam.spread(nav, focus, #bots + 1)
			goal = others[#others]
		end
		local job: Job = team.jobs[m.id] or { task = task, walk = false, through = false }
		job.task = task
		job.goal = goal
		-- Round a player, each watches away from them: the side's flanks.
		job.look = nil
		if leader then
			local out = vector.create(m.feet.x - leader.feet.x, 0, m.feet.z - leader.feet.z)
			if vector.magnitude(out) > 0.5 then
				job.look = m.feet + vector.normalize(out) * 10 + vector.create(0, EYE, 0)
			end
		end
		job.walk = false
		-- Near enough to a player it follows: stays put.
		if
			leader
			and vector.magnitude(m.feet - leader.feet) <= BotTeam.FOLLOW_FAR
			and vector.magnitude(m.feet - leader.feet) >= BotTeam.FOLLOW_NEAR
		then
			job.goal = nil
		end
		team.jobs[m.id] = job
	end
end

-- What each of the side's living bots does now, by id. `live`: the round's
-- under way (else they wait in spawn, as in the buy phase); `sightings`:
-- where the side has seen its enemies lately.
function BotTeam.think(team: Team, now: number, live: boolean, members: { Member }, sightings: { Sighting }): { [number]: Order }
	local bots, players = sorted(members)
	local out: { [number]: Order } = {}
	if not live then
		team.began = nil
		for _, m in bots do
			out[m.id] = { task = "wait", goal = nil, look = nil, walk = false }
		end
		return out
	end
	if team.began == nil then
		team.began = now
		team.pushAt = now + BotTeam.PUSH_BY + (team.dice() * 2 - 1) * BotTeam.PUSH_SPREAD
	end
	if team.side == "attack" and team.plan then
		attack(team, now, bots, players, sightings)
	elseif team.side == "defend" and team.plan then
		defend(team, now, bots, sightings)
	else
		together(team, now, bots, players, sightings)
	end
	for _, m in bots do
		local job = team.jobs[m.id]
		if job then
			out[m.id] = { task = job.task, goal = job.goal, look = job.look, walk = job.walk }
		end
	end
	return out
end

return BotTeam
