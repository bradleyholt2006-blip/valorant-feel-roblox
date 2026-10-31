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
-- And the spike (system 61), as the Counter-Strike bot plays for the bomb
-- ('I'm going to plant the bomb', 'They dropped the bomb', 'I'm going to
-- guard bombsite B', its radio lines, Booth):
--   * a bot carrying it goes with the plan, and once through its way onto
--     the site, plants it at the spot planned (BotSpots)
--   * one lying on the ground is fetched by the bot nearest it: at once
--     with no player on the side, else once it's lain there DEFER, the
--     bots leaving it to a player first, as 'By default, bots defer key
--     scenario objective to human Players' (Booth)
--   * once it's planted, the attackers watch it, each from a spot with
--     cover that sees it, and each gets out of the blast once there's only
--     just time to on foot from where it is
--   * the defenders retake: they gather at the site's ways back in, push
--     in together, and the one nearest the spike defuses it while the rest
--     stand round, watching the spots it's watched from. If even the
--     nearest couldn't get there and defuse it in time, they get out of
--     the blast instead, keeping their guns
--
-- And for its agent's abilities (system 66, BotUtility): where each bot is
-- in the plan (placeOf), going in through its way, holding one, or
-- guarding the spike, and where its enemies would be.
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
local Spike = require("../Spike/Spike")

local BotTeam = {}

-- What the side plays: a spike map's attack or defence, or a side (or a
-- lone bot, in deathmatch) of the modes that respawn.
export type Side = "attack" | "defend" | "team"

export type Task =
	"wait"
	| "gather"
	| "push"
	| "take"
	| "hunt"
	| "hold"
	| "rotate"
	| "follow"
	| "roam"
	| "fetch"
	| "plant"
	| "guard"
	| "retake"
	| "defuse"
	| "clear"

-- Someone on the side, as the server shows it: a bot or a player.
export type Member = {
	id: number,
	bot: boolean,
	alive: boolean,
	feet: vector,
	defusing: number?, -- a defuse under way: how far it's got, seconds of the 7 (system 61)
}

-- The spike as a side knows it (system 61), in the map's frame: lying on
-- the ground, carried (by whom: an entity id), or planted (at which site,
-- when it goes off, and whether a defuse has passed its half).
export type Spike = {
	state: "dropped" | "carried" | "planted",
	at: vector?, -- where it lies, or was planted
	carrier: number?,
	site: string?,
	detonateAt: number,
	halfSaved: boolean,
}

-- Where an enemy was seen by someone on the side, and when.
export type Sighting = { at: vector, time: number }

-- A bot's job this moment: where it walks to (nil to stay), where it looks
-- once there (nil for wherever it's looking), and whether it walks
-- quietly. With the spike (system 61): a point to step right onto once
-- near (the spike, to run over it), and whether a plant or a defuse goes
-- on even under fire, there being no time to fight first.
export type Order = {
	task: Task,
	goal: number?,
	look: vector?,
	walk: boolean,
	onto: vector?,
	commit: boolean?,
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
	entrance: number?, -- and the entrance that hold holds, by number in the site's
	onto: vector?,
	commit: boolean?,
	back: number?, -- defenders: the way back in it takes, by number, after a plant
	post: number?, -- the spot it was given to watch the spike from
}

type Phase = "gather" | "push" | "take" | "hunt"

export type Team = {
	nav: BotNav.Nav,
	plan: BotSpots.Plan?, -- a spike map's, for the spike rounds' sides
	side: Side,
	dice: BotConfig.Dice,
	places: { number }, -- nodes to go from one to another of
	enemySpawn: { number }, -- the nodes the enemy spawns on, if known
	-- This round's plan: the attackers' site (the defenders', once it's
	-- planted: the site they retake), ways in and how far along they are;
	-- when it began and when the push goes at the latest.
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
	-- The spike (system 61): where the side's carrier plants this round,
	-- by number in the site's places to plant; where it's been lying
	-- and since when, and who's fetching it; once it's planted, when the
	-- side first knew, where it is and the watch spots that see it; and
	-- the defenders' retake, how far along, and who defuses.
	plantPick: number,
	lyingAt: vector?,
	lyingSince: number,
	fetcher: number?,
	plantedSeen: number?,
	plantedAt: vector?,
	watching: { number },
	retake: "gather" | "push",
	defuser: number?,
}

-- Where a bot is in its side's plan (system 66), for its agent's abilities
-- (BotUtility), in the map's frame: going in through a way (an attacker
-- before the plant, a defender on the retake), holding one (a defender
-- before it) or guarding the spike (an attacker after it). `phase` is how
-- far its side has got: the attack's gather, push, take or hunt, the
-- retake's gather or push, "hold" or "guard"; `there`, whether it's at the
-- spot its job sends it to; `way`, head height where its way in is
-- crossed, a few metres out, `heading` the way it goes in there, level,
-- and `door` the floor where it comes into the site; `from`, a holder's:
-- where the attackers gather for that way; `threats`, head
-- height where its enemies would be, the spots that hold its way in or
-- watch the spike; and `spike`, where it's planted.
export type Place = {
	role: "entry" | "hold" | "guard",
	phase: string,
	there: boolean,
	way: vector?,
	heading: vector?,
	door: vector?,
	from: vector?,
	threats: { vector },
	spike: vector?,
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
-- The spike (system 61). With a player on the side alive, the bots leave
-- it on the ground to them this long, of a live round, before the nearest
-- goes for it (estimate: long enough for a player by it to pick it up),
-- as the Counter-Strike bot doesn't 'get scenario items' when 'there is a
-- human on the team' (bot_defer_to_human_items, on by default).
BotTeam.DEFER = 5
-- Out of the blast: this far from the spike, its radius and a margin;
-- each attacker goes once what's left on it is no more than its way out
-- at RUN and this to spare (estimates).
BotTeam.BLAST = Spike.Params.blastRadius.value + 3
BotTeam.CLEAR = 1.5
-- The defenders' retake (estimates): they push this long after the plant
-- at the latest, or with this much more time left than a defuse takes;
-- the defuse goes on under fire once there's no more than COMMIT to
-- spare; and they go for it only if it can be done in time at a run of
-- RUN (metres a second: under a rifle's 5.4, for the turns on the way).
BotTeam.RETAKE_BY = 12
BotTeam.RETAKE_LATE = 14
BotTeam.COMMIT = 2
BotTeam.RUN = 5
-- How many nodes of the ways out of a planted spike's blast and to it are
-- worked out each time a side's plan is gone over (BotNav.extend): a few
-- milliseconds at most, and each is done in 2 s on the maps there are,
-- long before it's needed.
BotTeam.OUT_STEPS = 2000

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
		plantPick = 1,
		lyingAt = nil,
		lyingSince = 0,
		fetcher = nil,
		plantedSeen = nil,
		plantedAt = nil,
		watching = {},
		retake = "gather",
		defuser = nil,
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
	team.lyingAt = nil
	team.fetcher = nil
	team.plantedSeen = nil
	team.plantedAt = nil
	team.watching = {}
	team.retake = "gather"
	team.defuser = nil
	local plan = team.plan
	if team.side == "attack" and plan and #plan.sites > 0 then
		local site = plan.sites[math.floor(team.dice() * #plan.sites) + 1]
		BotTeam.aim(team, site.name)
		-- Which of its places to plant, if the spike's planted there.
		team.plantPick = math.floor(team.dice() * BotSpots.PLANTS) + 1
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

local function close(team: Team, at: vector, n: number?, within: number): boolean
	if n == nil then
		return false
	end
	local p = feet(team.nav, n)
	return (p.x - at.x) ^ 2 + (p.z - at.z) ^ 2 <= within * within and math.abs(p.y - at.y) < 1.5
end

local function near(team: Team, m: Member, n: number?, within: number): boolean
	return close(team, m.feet, n, within)
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

-- The way an entrance is crossed going in, level, if it can be told.
local function headingOf(nav: BotNav.Nav, e: BotSpots.Entrance): vector?
	local d = feet(nav, e.node) - feet(nav, e.outside)
	local level = vector.create(d.x, 0, d.z)
	return if vector.magnitude(level) > 1e-3 then vector.normalize(level) else nil
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

-- The spike (system 61) ------------------------------------------------------------------

-- A bot's job, a new one if it has none.
local function jobOf(team: Team, m: Member): Job
	local job = team.jobs[m.id]
	if not job then
		job = { task = "wait", walk = false, through = false }
		team.jobs[m.id] = job
	end
	return job :: Job
end

-- Spots from `spots` for `bots`: each keeps the one it had, the rest take
-- the first free, in id order; any left over get none.
local function post(team: Team, bots: { Member }, spots: { number }): { [number]: number }
	local free: { [number]: boolean } = {}
	for _, n in spots do
		free[n] = true
	end
	local out: { [number]: number } = {}
	for _, m in bots do
		local had = jobOf(team, m).post
		if had and free[had] then
			out[m.id] = had
			free[had] = false
		end
	end
	for _, m in bots do
		if out[m.id] == nil then
			for _, n in spots do
				if free[n] then
					out[m.id] = n
					free[n] = false
					break
				end
			end
		end
		jobOf(team, m).post = out[m.id]
	end
	return out
end

-- The way out of the blast of a spike planted at `at`, on a map: a field
-- of distances on foot to every node further than BLAST from it, worked
-- out a little each time a side's plan is gone over, and shared by both
-- sides.
local outs: { [BotNav.Nav]: { at: vector, field: BotNav.Field } } = setmetatable({}, { __mode = "k" }) :: any

local function outOf(nav: BotNav.Nav, at: vector): BotNav.Field
	local known = outs[nav]
	if known and vector.magnitude(known.at - at) < 0.1 then
		return known.field
	end
	local from = {}
	for n = 1, #nav.xs do
		local dx, dz = nav.xs[n] - at.x, nav.zs[n] - at.z
		if dx * dx + dz * dz > BotTeam.BLAST * BotTeam.BLAST then
			table.insert(from, n)
		end
	end
	local field = BotNav.begin(nav, from, true)
	outs[nav] = { at = at, field = field }
	return field
end

-- The way to a spike planted at `at`, on a map: a field of distances on
-- foot to node `by`, where its defuser goes, worked out as the way out
-- is.
local tos: { [BotNav.Nav]: { at: vector, field: BotNav.Field } } = setmetatable({}, { __mode = "k" }) :: any

local function toward(nav: BotNav.Nav, at: vector, by: number): BotNav.Field
	local known = tos[nav]
	if known and vector.magnitude(known.at - at) < 0.1 then
		return known.field
	end
	local field = BotNav.begin(nav, { by }, true)
	tos[nav] = { at = at, field = field }
	return field
end

-- How far it is from node n on `field`: as far as that's been worked
-- out, at least.
local function along(field: BotNav.Field, n: number?): number
	if n == nil then
		return 0
	end
	local d = field.dist[n]
	return if field.done or d < field.reach then d else field.reach
end

-- Out of the blast of the spike at `at`, the nearest way: the way's worked
-- out once.
local function clear(team: Team, m: Member, at: vector)
	local job = jobOf(team, m)
	if job.task ~= "clear" or job.goal == nil then
		local nav = team.nav
		local field = outOf(nav, at)
		if not field.done then
			-- Needed now: the rest of it at once.
			BotNav.extend(nav, field, math.huge)
		end
		local n = nodeOf(team, m.feet)
		job.goal = if n then BotSpots.down(nav, field.dist, n, math.huge) else nil
	end
	job.task = "clear"
	job.look = nil
	job.walk = false
end

-- The site the spike's planted at: the one it says, else the nearest.
local function plantedSite(team: Team, spike: Spike): BotSpots.Site?
	local plan = team.plan :: BotSpots.Plan
	local named = if spike.site then BotSpots.site(plan, spike.site) else nil
	if named then
		return named
	end
	local n = if spike.at then nodeOf(team, spike.at) else nil
	local nearest: BotSpots.Site? = plan.sites[1]
	local bestField = math.huge
	for _, s in plan.sites do
		local d = if n then s.field[n] else math.huge
		if d < bestField then
			nearest, bestField = s, d
		end
	end
	return nearest
end

-- The site's watch spots that see the spike where it's planted, worked out
-- once a plant.
local function watching(team: Team, site: BotSpots.Site, at: vector): { number }
	local known = team.plantedAt
	if known and vector.magnitude(known - at) < 0.1 then
		return team.watching
	end
	local out = {}
	local low = at + vector.create(0, BotSpots.LOW, 0)
	for _, n in site.watches do
		if BotNav.sees(team.nav, head(team.nav, n), low) then
			table.insert(out, n)
		end
	end
	team.plantedAt = at
	team.watching = out
	return out
end

-- The attackers' spike before it's planted: lying on the ground, the bot
-- nearest goes for it (at once with no player on the side alive, else once
-- it's lain there DEFER of a live round); carried by a bot, that bot
-- plants it at the spot planned, once through its way onto the site.
local function carry(team: Team, now: number, bots: { Member }, players: { Member }, spike: Spike, site: BotSpots.Site)
	local nav = team.nav
	local plan = team.plan :: BotSpots.Plan
	local lying = if spike.state == "dropped" then spike.at else nil
	if lying then
		local seen = team.lyingAt
		if seen == nil or vector.magnitude(seen - lying) > 0.5 then
			team.lyingAt = lying
			team.lyingSince = now
			team.fetcher = nil
		end
	else
		team.lyingAt = nil
		team.fetcher = nil
	end
	if lying and (#players == 0 or now - math.max(team.lyingSince, team.began or now) >= BotTeam.DEFER) then
		local fetcher: Member? = nil
		local nearest = math.huge
		for _, m in bots do
			local d = vector.magnitude(m.feet - lying)
			if m.id == team.fetcher then
				fetcher, nearest = m, -1
			elseif d < nearest then
				fetcher, nearest = m, d
			end
		end
		if fetcher then
			team.fetcher = fetcher.id
			local job = jobOf(team, fetcher)
			job.task = "fetch"
			job.goal = BotSpots.reachableNear(nav, plan.attack, lying, 2) or nodeOf(team, lying)
			job.look = nil
			job.walk = false
			job.onto = lying
		end
	end
	if #site.plants == 0 then
		return
	end
	for _, m in bots do
		local job = jobOf(team, m)
		if m.id == spike.carrier and team.phase ~= "gather" and (job.through or team.phase ~= "push") then
			local n = site.plants[(team.plantPick - 1) % #site.plants + 1]
			job.task = "plant"
			job.goal = n
			-- Watching the way the defenders come back from their spawn.
			job.look = head(nav, BotSpots.down(nav, plan.defend, n, 12))
			job.walk = false
			job.onto = feet(nav, n)
		end
	end
end

-- Whether attacker `m` must be on its way out of the blast now, with
-- `left` on the spike: its way out from where it is, or from where it's
-- going, takes all but CLEAR of that at RUN. Once on its way, it keeps on.
local function leaving(team: Team, m: Member, out: BotNav.Field, left: number): boolean
	local job = team.jobs[m.id]
	if job and job.task == "clear" then
		return true
	end
	local way = math.max(along(out, nodeOf(team, m.feet)), along(out, if job then job.goal else nil))
	return left <= way / BotTeam.RUN + BotTeam.CLEAR
end

-- The attackers once it's planted: each to a spot that sees it, the
-- site's best first (BotSpots' watches), the rest round it, all watching
-- where a defuser would be; each out of the blast once there's only just
-- time to get out.
local function guard(team: Team, now: number, bots: { Member }, spike: Spike)
	local nav = team.nav
	local plan = team.plan :: BotSpots.Plan
	local at = spike.at :: vector
	local out = outOf(nav, at)
	BotNav.extend(nav, out, BotTeam.OUT_STEPS)
	local left = spike.detonateAt - now
	local staying: { Member } = {}
	for _, m in bots do
		if leaving(team, m, out, left) then
			clear(team, m, at)
		else
			table.insert(staying, m)
		end
	end
	if #staying == 0 then
		return
	end
	local site = plantedSite(team, spike)
	local posts = post(team, staying, if site then watching(team, site, at) else {})
	local rest: { Member } = {}
	for _, m in staying do
		if posts[m.id] == nil then
			table.insert(rest, m)
		end
	end
	local centre = BotSpots.reachableNear(nav, plan.attack, at, 3) or nodeOf(team, at)
	local round: { [number]: number } = if #rest > 0 and centre then deal(team, rest, centre) else {}
	for _, m in staying do
		local job = jobOf(team, m)
		job.task = "guard"
		job.goal = posts[m.id] or round[m.id]
		job.look = at + vector.create(0, 1, 0)
		job.walk = false
	end
end

-- The defenders once it's planted: the retake. They gather at the site's
-- ways back in from their spawn (any on the site already stay where they
-- are), push in together once most are there or the clock says so, and
-- the one nearest the spike defuses it, unless a player's at it, while the
-- rest stand round it, each watching one of the spots it's watched from.
-- If even the nearest couldn't get there and defuse it in time, they get
-- out of the blast.
local function retake(team: Team, now: number, bots: { Member }, players: { Member }, spike: Spike)
	local nav = team.nav
	local plan = team.plan :: BotSpots.Plan
	local at = spike.at :: vector
	local site = plantedSite(team, spike)
	if not site then
		return
	end
	local s = site :: BotSpots.Site
	team.site = s.name
	team.plantedSeen = team.plantedSeen or now
	BotNav.extend(nav, outOf(nav, at), BotTeam.OUT_STEPS)
	local left = spike.detonateAt - now
	local full = Spike.Params.defuseTime.value
	local need = Spike.defuseTime(spike.halfSaved)
	local target = BotSpots.reachableNear(nav, plan.defend, at, 2) or nodeOf(team, at)
	local to = if target then toward(nav, at, target) else nil
	if to then
		BotNav.extend(nav, to, BotTeam.OUT_STEPS)
	end
	-- Who defuses: the one who has been while alive, else the nearest.
	local defuser: Member? = nil
	local nearest = math.huge
	for _, m in bots do
		local d = vector.magnitude(m.feet - at)
		if m.id == team.defuser then
			defuser, nearest = m, -1
		elseif d < nearest then
			defuser, nearest = m, d
		end
	end
	local player = false
	for _, p in players do
		player = player or p.defusing ~= nil
	end
	if player then
		defuser = nil
	end
	team.defuser = if defuser then defuser.id else nil
	-- Too late for it: out of the blast. A defuse under way needs only
	-- what's left of it; else the defuser's way there on foot, and the
	-- defuse.
	if defuser then
		local d = defuser :: Member
		local way = vector.magnitude(d.feet - at)
		if to then
			way = math.max(way, along(to, nodeOf(team, d.feet)))
		end
		local still = if d.defusing then full - d.defusing else need + way / BotTeam.RUN
		if left < still then
			for _, m in bots do
				clear(team, m, at)
			end
			return
		end
	end
	-- Each bot's way back in: the one it has, else the one the fewest have.
	local ways = if #s.retakes > 0 then s.retakes else s.entrances
	local counts: { number } = {}
	for k = 1, #ways do
		counts[k] = 0
	end
	for _, m in bots do
		local b = jobOf(team, m).back
		if b and counts[b] then
			counts[b] += 1
		end
	end
	local byWay: { [number]: { Member } } = {}
	for _, m in bots do
		local job = jobOf(team, m)
		if #ways > 0 and (job.back == nil or counts[job.back :: number] == nil) then
			local best, fewest = 1, math.huge
			for k = 1, #ways do
				if counts[k] < fewest then
					best, fewest = k, counts[k]
				end
			end
			job.back = best
			job.through = false
			counts[best] += 1
		end
		if job.back then
			byWay[job.back :: number] = byWay[job.back :: number] or {}
			table.insert(byWay[job.back :: number], m)
		end
	end
	local function inside(m: Member): boolean
		local n = nodeOf(team, m.feet)
		return n ~= nil and s.field[n] <= BotSpots.AREA
	end
	local stage: { [number]: number } = {}
	for b, group in byWay do
		for id, n in deal(team, group, ways[b].stage) do
			stage[id] = n
		end
	end
	if team.retake == "gather" then
		local there = 0
		for _, m in bots do
			if inside(m) or near(team, m, stage[m.id], BotTeam.THERE) then
				there += 1
			end
		end
		local late = now >= (team.plantedSeen :: number) + BotTeam.RETAKE_BY or left <= need + BotTeam.RETAKE_LATE
		if #ways == 0 or #bots > 0 and there >= math.ceil(#bots * BotTeam.GATHERED) or late then
			team.retake = "push"
		end
	end
	-- Those round the spike, and the spots each watches.
	local covering: { Member } = {}
	for _, m in bots do
		if m ~= defuser then
			table.insert(covering, m)
		end
	end
	local round: { [number]: number } = if target and #covering > 0 then deal(team, covering, target) else {}
	local spots = watching(team, s, at)
	for k, m in bots do
		local job = jobOf(team, m)
		local way = if job.back then ways[job.back :: number] else nil
		job.task = "retake"
		job.walk = false
		if team.retake == "gather" then
			if inside(m) or not way then
				job.goal = nil
				job.look = at + vector.create(0, 1, 0)
			else
				local w = way :: BotSpots.Entrance
				job.goal = stage[m.id]
				job.look = head(nav, w.node)
				job.walk = near(team, m, stage[m.id], BotTeam.QUIET)
			end
			continue
		end
		-- In through its way, then to the spike or round it.
		if way and not job.through and (near(team, m, way.node, BotTeam.THERE) or inside(m)) then
			job.through = true
		end
		local entry = if way and not job.through then way.node else nil
		if m == defuser then
			job.task = "defuse"
			job.goal = entry or target
			job.look = at + vector.create(0, BotSpots.LOW, 0)
			local d = defuser :: Member
			local still = if d.defusing then full - d.defusing else need
			job.commit = left < still + BotTeam.COMMIT
		else
			job.goal = entry or round[m.id]
			job.look = if #spots > 0 then head(nav, spots[(k - 1) % #spots + 1]) else at + vector.create(0, 1, 0)
		end
	end
end

-- The attackers: the plan, followed.
local function attack(team: Team, now: number, bots: { Member }, players: { Member }, sightings: { Sighting }, spike: Spike?)
	local plan = team.plan :: BotSpots.Plan
	local nav = team.nav
	if spike and spike.state == "planted" and spike.at then
		guard(team, now, bots, spike)
		return
	end
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
	if spike then
		carry(team, now, bots, players, spike, site)
	end
end

-- The defenders: a site and a hold each, and over to a site the attackers
-- turn up at.
local function defend(team: Team, now: number, bots: { Member }, players: { Member }, sightings: { Sighting }, spike: Spike?)
	local plan = team.plan :: BotSpots.Plan
	local sites = plan.sites
	if #sites == 0 then
		return
	end
	if spike and spike.state == "planted" and spike.at then
		retake(team, now, bots, players, spike)
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
			job.entrance = if hold then hold.entrance else nil
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

-- Where bot `id`, its feet at `at`, is in its side's plan (system 66), as
-- Place has it: nil with no job in a spike round's plan, or one that has it
-- fetch, plant or defuse the spike, or get out of its blast.
function BotTeam.placeOf(team: Team, id: number, at: vector): Place?
	local job = team.jobs[id]
	local plan = team.plan
	if not job or not plan or team.side == "team" then
		return nil
	end
	local task = job.task
	if task == "fetch" or task == "plant" or task == "defuse" or task == "clear" then
		return nil
	end
	local nav = team.nav
	local there = close(team, at, job.goal, BotTeam.THERE)
	local spike = team.plantedAt
	local threats: { vector } = {}
	if team.side == "attack" then
		if spike then
			return { role = "guard", phase = "guard", there = there, threats = threats, spike = spike }
		end
		local site = if team.site then BotSpots.site(plan, team.site :: string) else nil
		local entrance = if site and job.way then site.entrances[job.way :: number] else nil
		if not site or not entrance then
			return nil
		end
		for _, h in site.holds do
			if h.entrance == job.way then
				table.insert(threats, head(nav, h.node))
			end
		end
		return {
			role = "entry",
			phase = team.phase :: string,
			there = there,
			way = entrance.aim,
			heading = headingOf(nav, entrance),
			door = feet(nav, entrance.node),
			threats = threats,
		}
	end
	if spike then
		-- The retake: in through its way back, at those watching the spike.
		local site = if team.site then BotSpots.site(plan, team.site :: string) else nil
		local ways = if site and #site.retakes > 0 then site.retakes elseif site then site.entrances else {}
		local entrance = if job.back then ways[job.back :: number] else nil
		for _, n in team.watching do
			table.insert(threats, head(nav, n))
		end
		return {
			role = "entry",
			phase = team.retake :: string,
			there = there,
			way = if entrance then entrance.aim else nil,
			heading = if entrance then headingOf(nav, entrance) else nil,
			door = if entrance then feet(nav, entrance.node) else nil,
			threats = threats,
			spike = spike,
		}
	end
	local site = if job.site then BotSpots.site(plan, job.site :: string) else nil
	local entrance = if site and job.entrance then site.entrances[job.entrance :: number] else nil
	return {
		role = "hold",
		phase = "hold",
		there = there and task == "hold",
		way = if entrance then entrance.aim else nil,
		heading = if entrance then headingOf(nav, entrance) else nil,
		door = if entrance then feet(nav, entrance.node) else nil,
		from = if entrance then head(nav, entrance.stage) else nil,
		threats = threats,
	}
end

-- What each of the side's living bots does now, by id. `live`: the round's
-- under way (else they wait in spawn, as in the buy phase); `sightings`:
-- where the side has seen its enemies lately; `spike`: the spike, in the
-- spike rounds, as the side knows it (system 61).
function BotTeam.think(
	team: Team,
	now: number,
	live: boolean,
	members: { Member },
	sightings: { Sighting },
	spike: Spike?
): { [number]: Order }
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
	for _, job in team.jobs do
		job.onto = nil
		job.commit = nil
	end
	if team.side == "attack" and team.plan then
		attack(team, now, bots, players, sightings, spike)
	elseif team.side == "defend" and team.plan then
		defend(team, now, bots, players, sightings, spike)
	else
		together(team, now, bots, players, sightings)
	end
	for _, m in bots do
		local job = team.jobs[m.id]
		if job then
			out[m.id] = { task = job.task, goal = job.goal, look = job.look, walk = job.walk, onto = job.onto, commit = job.commit }
		end
	end
	return out
end

return BotTeam
