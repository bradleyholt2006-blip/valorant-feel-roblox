--!strict
-- How a bot walks where it's going (system 60): a path across the map's
-- nav (BotNav), followed as Left 4 Dead's bots follow theirs, steering at
-- a point further along it rather than going from node to node, which
-- looks robotic (Booth, "The AI Systems of Left 4 Dead", 2009). Here the
-- point is the furthest node ahead it can walk straight to. A jump on the
-- way is jumped as its edge comes near.
--
-- Getting stuck is noticed as the Counter-Strike bot notices it, by its
-- speed over the last moment, and got out of as it gets out, with a random
-- step aside and a jump (Booth, GDC 2004); if that doesn't free it, the
-- way is planned again with the spot it stuck at made dear, so the new
-- way goes round it.
--
-- What comes out is a direction across the floor, which the server turns
-- into the movement keys for the way the bot's looking (BotMove.keys), as
-- its view goes apart from its walk.
--
-- Plain state and maths in metres, in the map's own frame.

local BotConfig = require("./BotConfig")
local BotNav = require("./BotNav")

local BotMove = {}

export type Mover = {
	nav: BotNav.Nav,
	dice: BotConfig.Dice,
	goal: number?, -- the node it's going to
	path: { number }?,
	index: number, -- the path's next node to reach
	-- Recent places and when it was at them, to tell when it's stuck, and
	-- when the stall began.
	trail: { vector },
	trailTimes: { number },
	stuckSince: number?,
	-- The step aside under way, and until when.
	aside: vector?,
	asideUntil: number,
	-- Spots it's stuck at lately, made dear for the next plan, and until
	-- when.
	sore: { { at: vector, untilTime: number } },
	planned: number, -- when the path was last planned
	jumped: boolean, -- whether the last tick pressed jump
	stuck: number, -- how often it's been stuck long enough to plan its way again, for checks
}

-- What a bot does to go on this tick.
export type Step = {
	direction: vector?, -- across the floor, unit length; nil to stand
	jump: boolean, -- press jump: a press a tick, let go the next, as the movement jumps again only once it's let go
	arrived: boolean,
}

-- How near a node counts as reached, across and up (metres).
BotMove.REACH = 0.45
-- How far ahead the steering point can be (metres).
BotMove.AHEAD = 4
-- How far up the next node may be from the feet and still be walked to by
-- the steering point's cut; higher, it's a step up or a jump, walked
-- straight at, and only counted reached once the feet are up there too.
BotMove.RISE = 0.2
-- How near the edge of a jump the jump's made (metres), and the most it
-- gains: from lower down, on a slope, it falls short, so it walks on up to
-- where the jump's made from.
BotMove.JUMP_AT = 0.9
BotMove.JUMP_GAIN = 0.8
-- Stuck: slower than this (metres a second) on average over the trail's
-- moment, for this long, while it means to move.
BotMove.STALL_SPEED = 0.8
BotMove.STALL_TIME = 0.5
-- The trail's moment (seconds).
BotMove.TRAIL = 0.25
-- How many of the path's nodes past the next one it looks through for the
-- nearest, having gone by those before it.
BotMove.CATCH_UP = 12
-- The step aside: how long; and stuck this long, it plans again.
BotMove.ASIDE = 0.35
BotMove.REPLAN = 1.2
-- How far round a sore spot the next plan keeps off, how dear each node
-- there is, and how long it's remembered.
BotMove.SORE_RADIUS = 1.2
BotMove.SORE_COST = 6
BotMove.SORE_TIME = 10
-- A path's planned again this often anyway, and when it's this far off it.
BotMove.REPLAN_EVERY = 4
BotMove.OFF_PATH = 2.5

function BotMove.new(nav: BotNav.Nav, dice: BotConfig.Dice): Mover
	return {
		nav = nav,
		dice = dice,
		goal = nil,
		path = nil,
		index = 1,
		trail = {},
		trailTimes = {},
		stuckSince = nil,
		aside = nil,
		asideUntil = 0,
		sore = {},
		planned = -math.huge,
		jumped = false,
		stuck = 0,
	}
end

-- Forgets the way: a new life, or somewhere else to go.
function BotMove.reset(m: Mover)
	m.goal = nil
	m.path = nil
	m.index = 1
	table.clear(m.trail)
	table.clear(m.trailTimes)
	m.stuckSince = nil
	m.aside = nil
end

-- What a node's worth more to go through now: the sore spots round it.
local function soreCost(m: Mover, now: number): ((number) -> number)?
	local live = {}
	for _, s in m.sore do
		if s.untilTime > now then
			table.insert(live, s)
		end
	end
	m.sore = live
	if #live == 0 then
		return nil
	end
	local nav = m.nav
	return function(n: number): number
		local x, y, z = nav.xs[n], nav.ys[n], nav.zs[n]
		for _, s in live do
			local d = s.at
			if math.abs(d.y - y) < 1.5 and (d.x - x) ^ 2 + (d.z - z) ^ 2 < BotMove.SORE_RADIUS ^ 2 then
				return BotMove.SORE_COST
			end
		end
		return 0
	end
end

-- Stops for a moment without forgetting the way (a fight): nothing to
-- count as stuck when it goes on.
function BotMove.hold(m: Mover)
	table.clear(m.trail)
	table.clear(m.trailTimes)
	m.stuckSince = nil
	m.aside = nil
end

-- Plans the way from feet at `from` to node `goal`. Returns whether there
-- is one.
local function plan(m: Mover, now: number, from: vector, goal: number): boolean
	local nav = m.nav
	m.planned = now
	local start = BotNav.nodeAt(nav, from, 3)
	if not start then
		m.path = nil
		return false
	end
	local path = BotNav.path(nav, start, goal, soreCost(m, now))
	m.path = path
	m.index = if path and #path > 1 then 2 else 1
	return path ~= nil
end

-- The furthest node of the path ahead, at most AHEAD away, that the bot
-- walks straight to from the node it's at, with no jump between.
local function steerPoint(m: Mover, here: number): number
	local nav = m.nav
	local path = m.path :: { number }
	local best = path[m.index]
	local hx, hz = nav.xs[here], nav.zs[here]
	for k = m.index, #path do
		local n = path[k]
		if (nav.xs[n] - hx) ^ 2 + (nav.zs[n] - hz) ^ 2 > BotMove.AHEAD ^ 2 then
			break
		end
		-- A jump's taken from where it is on the path, not cut across.
		if k > m.index and nav.ys[n] - nav.ys[path[k - 1]] > nav.options.step then
			break
		end
		if BotNav.straight(nav, here, n) then
			best = n
		end
	end
	return best
end

-- Whether the move from node a to node b on the path is a jump up.
local function isJump(nav: BotNav.Nav, a: number, b: number): boolean
	return nav.ys[b] - nav.ys[a] > nav.options.step
end

-- Moves the path's next node on past those the bot has reached or gone
-- by. The steering point cuts corners, so a node can be gone by without
-- being reached: the next is the one after the nearest of the next few it
-- can walk straight to, else it would turn back for it.
local function advance(m: Mover, here: number, feet: vector)
	local nav = m.nav
	local path = m.path :: { number }
	local best, bestScore = m.index, math.huge
	for k = m.index, math.min(m.index + BotMove.CATCH_UP, #path) do
		local n = path[k]
		local dx, dy, dz = nav.xs[n] - feet.x, nav.ys[n] - feet.y, nav.zs[n] - feet.z
		local score = dx * dx + dz * dz + 4 * dy * dy
		if score < bestScore and (k == m.index or BotNav.straight(nav, here, n)) then
			best, bestScore = k, score
		end
	end
	m.index = best
	while m.index < #path do
		local n, after = path[m.index], path[m.index + 1]
		local x, y, z = nav.xs[n], nav.ys[n], nav.zs[n]
		-- Up there with it, not below a step or a jump still to make, nor
		-- far above, falling.
		local level = y - feet.y <= BotMove.RISE and feet.y - y < 1.5
		local reached = (x - feet.x) ^ 2 + (z - feet.z) ^ 2 <= BotMove.REACH ^ 2
		-- Gone by: beyond it, toward the node after; but a jump's made from
		-- the node it's made from, so that's reached, not gone by.
		local past = not isJump(nav, n, after) and (feet.x - x) * (nav.xs[after] - x) + (feet.z - z) * (nav.zs[after] - z) > 0
		if level and (reached or past) then
			m.index += 1
		else
			break
		end
	end
end

-- Whether it's stuck: slow over the trail's moment while meaning to move
-- (nil until the trail's that long). Keeps the trail.
local function stalled(m: Mover, now: number, feet: vector): boolean?
	local trail, times = m.trail, m.trailTimes
	table.insert(trail, feet)
	table.insert(times, now)
	while #times > 2 and now - times[2] >= BotMove.TRAIL do
		table.remove(trail, 1)
		table.remove(times, 1)
	end
	local span = now - times[1]
	if span < BotMove.TRAIL then
		return nil
	end
	return vector.magnitude(feet - trail[1]) / span < BotMove.STALL_SPEED
end

-- Stands still: no way to go, and nothing to count as stuck.
local function stand(m: Mover): Step
	table.clear(m.trail)
	table.clear(m.trailTimes)
	m.stuckSince = nil
	m.aside = nil
	return { direction = nil, jump = false, arrived = true }
end

-- One tick toward node `goal` (nil to stand), from feet at `feet`: the way
-- to go, and whether to jump. Ticks needn't come at a steady rate.
function BotMove.step(m: Mover, now: number, feet: vector, goal: number?): Step
	local nav = m.nav
	if goal == nil then
		m.goal = nil
		m.path = nil
		return stand(m)
	end
	local g = goal :: number
	local gp = BotNav.feet(nav, g)
	if (gp.x - feet.x) ^ 2 + (gp.z - feet.z) ^ 2 <= BotMove.REACH ^ 2 and math.abs(gp.y - feet.y) < 1 then
		return stand(m)
	end
	if m.goal ~= g or m.path == nil or now - m.planned > BotMove.REPLAN_EVERY then
		m.goal = g
		if not plan(m, now, feet, g) then
			-- Nowhere to walk to: straight at it, for what that's worth.
			local flat = vector.create(gp.x - feet.x, 0, gp.z - feet.z)
			return { direction = if vector.magnitude(flat) > 1e-6 then vector.normalize(flat) else nil, jump = false, arrived = false }
		end
	end
	local here = BotNav.nodeAt(nav, feet, 2)
	if not here then
		plan(m, now, feet, g)
		return { direction = nil, jump = false, arrived = false }
	end
	advance(m, here, feet)
	local path = m.path :: { number }
	-- Off the path (pushed, or fallen off a ledge): plan again.
	local next = path[m.index]
	if vector.magnitude(BotNav.feet(nav, next) - feet) > BotMove.OFF_PATH + BotMove.AHEAD then
		plan(m, now, feet, g)
		path = m.path :: { number }
		if not path then
			return { direction = nil, jump = false, arrived = false }
		end
		next = path[m.index]
	end
	local toward = steerPoint(m, here)
	local tp = BotNav.feet(nav, toward)
	local flat = vector.create(tp.x - feet.x, 0, tp.z - feet.z)
	local direction: vector? = if vector.magnitude(flat) > 1e-6 then vector.normalize(flat) else nil
	-- Up onto the next node: walked straight at, not along the cut the
	-- steering point makes; and a jump, once near its edge, if one gets up
	-- there from here, else on up to where it's made from.
	local jump = false
	local rise = nav.ys[next] - feet.y
	if rise > BotMove.RISE then
		local at = next
		if rise > nav.options.step then
			local nx, nz = nav.xs[next] - feet.x, nav.zs[next] - feet.z
			if rise > BotMove.JUMP_GAIN then
				at = path[math.max(m.index - 1, 1)]
			elseif nx * nx + nz * nz <= BotMove.JUMP_AT ^ 2 then
				jump = true
			end
		end
		local edge = vector.create(nav.xs[at] - feet.x, 0, nav.zs[at] - feet.z)
		if vector.magnitude(edge) > 1e-6 then
			direction = vector.normalize(edge)
		end
	end
	local slow = stalled(m, now, feet)
	if slow then
		m.stuckSince = m.stuckSince or now
	elseif slow == false then
		m.stuckSince = nil
	end
	local since = m.stuckSince
	if since and now - since >= BotMove.STALL_TIME then
		if now - since >= BotMove.REPLAN then
			-- Still stuck: the spot's dear, and the way's planned anew.
			m.stuck += 1
			table.insert(m.sore, { at = feet, untilTime = now + BotMove.SORE_TIME })
			plan(m, now, feet, g)
			m.stuckSince = nil
			table.clear(m.trail)
			table.clear(m.trailTimes)
		elseif m.aside == nil or now >= m.asideUntil then
			-- A step aside, square to the way, and a jump.
			local d = direction or vector.create(1, 0, 0)
			local side = if m.dice() < 0.5 then 1 else -1
			m.aside = vector.create(-d.z * side, 0, d.x * side)
			m.asideUntil = now + BotMove.ASIDE
			jump = true
		end
	end
	if m.aside and now < m.asideUntil then
		direction = m.aside
	else
		m.aside = nil
	end
	jump = jump and not m.jumped
	m.jumped = jump
	return { direction = direction, jump = jump, arrived = false }
end

-- The path's nodes still ahead, for drawing or telling where it's headed.
function BotMove.ahead(m: Mover): { number }
	local out = {}
	local path = m.path
	if path then
		for k = m.index, #path do
			table.insert(out, path[k])
		end
	end
	return out
end

local KEYS = {
	{ forward = 1, right = 0 },
	{ forward = 1, right = 1 },
	{ forward = 0, right = 1 },
	{ forward = -1, right = 1 },
	{ forward = -1, right = 0 },
	{ forward = -1, right = -1 },
	{ forward = 0, right = -1 },
	{ forward = 1, right = -1 },
}

-- The movement keys that go most nearly in `direction` (across the floor)
-- for a view at `yaw`: one of the eight ways WASD goes, as MovementSim's
-- wish direction has them. Returns forward (1, -1 or 0) and right.
function BotMove.keys(direction: vector, yaw: number): (number, number)
	local s, c = math.sin(yaw), math.cos(yaw)
	local fwd = vector.create(-s, 0, -c)
	local rgt = vector.create(c, 0, -s)
	local f, r = vector.dot(direction, fwd), vector.dot(direction, rgt)
	local best, bestDot = KEYS[1], -math.huge
	for _, k in KEYS do
		local len = math.sqrt(k.forward * k.forward + k.right * k.right)
		local dot = (k.forward * f + k.right * r) / len
		if dot > bestDot then
			best, bestDot = k, dot
		end
	end
	return best.forward, best.right
end

return BotMove
