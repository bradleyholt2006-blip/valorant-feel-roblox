--!strict
-- The fog of war (system 35): who's always in a player's snapshots, the
-- points of a body looked at and from where, the lines the level blocks,
-- the look ahead for a target coming round a corner and for a viewer
-- peeking one, what's heard, and the bookkeeping of a look: the hold, the
-- recheck, the hidden pairs nobody's moved since, the side's spotting and
-- the union a player who's down gets.

local FogOfWar = require("../src/shared/Combat/FogOfWar")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local SoundMath = require("../src/shared/Audio/SoundMath")
local FakeLevel = require("./FakeLevel")
local H = require("./Harness")

local check, near = H.check, H.near

H.section("Fog of war tests")

local P = FogOfWar.Params
local ZERO = vector.zero
local EYE = 1.62

local function v(x: number, y: number, z: number): vector
	return vector.create(x, y, z)
end

local function pose(id: number, feet: vector, fields: { [string]: any }?): PlayerCodec.Pose
	local out: PlayerCodec.Pose = {
		id = id,
		position = feet,
		yaw = 0,
		pitch = 0,
		crouchAlpha = 0,
		grounded = true,
		alive = true,
		quiet = false,
		reloading = false,
		weapon = 0,
		channel = 0,
		gliding = false,
	}
	if fields then
		for k, value in fields do
			(out :: any)[k] = value
		end
	end
	return out
end

local function viewer(id: number, side: number?, feet: vector, velocity: vector?, behind: number?): FogOfWar.Viewer
	return { id = id, side = side, eye = feet + v(0, EYE, 0), velocity = velocity or ZERO, standEye = nil, behind = behind or 0 }
end

local function target(id: number, side: number?, feet: vector, velocity: vector?, fields: { [string]: any }?): FogOfWar.Target
	return { id = id, side = side, pose = pose(id, feet, fields), velocity = velocity or ZERO }
end

-- The level's boxes as `blocked`, counting the lines cast.
local function through(level: any): (FogOfWar.Blocked, () -> number)
	local count = 0
	return function(a: vector, b: vector): boolean
		count += 1
		local d = b - a
		local length = vector.magnitude(d)
		return length > 1e-9 and level:cast(a, d / length, length, {}) ~= nil
	end, function(): number
		return count
	end
end

local open: FogOfWar.Blocked = function()
	return false
end

-- Numbers ----------------------------------------------------------------------------

do
	local all = true
	for _, param in P do
		all = all and param.status == "estimate" and #param.source > 0
	end
	check("every number of the fog's is an estimate, with its reason", all)
	check(
		"a look every 0.05 s, an enemy held 0.5 s after the last that found them, rechecked every 0.25 s",
		P.every.value == 0.05 and P.hold.value == 0.5 and P.recheck.value == 0.25
	)
	local E = FogOfWar.Edges
	local C = SoundConfig.Curves
	check(
		string.format(
			"heard as far as the sounds go: steps %g m, a reload %g m, a plant %g m, a glide %g m",
			E.steps,
			E.reload,
			E.device,
			E.glide
		),
		E.steps == SoundMath.radius(C.footstep.points)
			and E.reload == SoundMath.radius(C.reload.points)
			and E.device == SoundMath.radius(C.device.points)
			and E.glide == SoundMath.radius(C.ability.points)
			and E.steps == 20
			and E.reload == 15
			and E.device == 60
			and E.glide == 30
	)
end

-- Who's always in ------------------------------------------------------------------------

do
	local me = { id = 1, side = 1 }
	check("you're always in your own snapshots", FogOfWar.always(me, { id = 1, side = 1 }))
	check("so is your side", FogOfWar.always(me, { id = 2, side = 1 }))
	check("so is anyone on no side (a dummy, the course)", FogOfWar.always(me, { id = 3, side = nil }))
	check("a viewer on no side has everyone (the course, waiting in line)", FogOfWar.always({ id = 4, side = nil }, { id = 5, side = 2 }))
	check("an enemy isn't always in", not FogOfWar.always(me, { id = 6, side = 2 }))
end

-- Points, eyes and bodies --------------------------------------------------------------------

do
	local eye = v(0, EYE, 10)
	local points = FogOfWar.points(eye, ZERO, 0)
	check("seven points of a body are looked at", #points == 7)
	local top, body, legs = points[1], points[2], points[3]
	check(
		string.format(
			"in the middle: near the head's top (%.2f m), the body's middle (%.2f m) and the legs' (%.3f m)",
			top.y,
			body.y,
			legs.y
		),
		near(top.y, 1.62 + 0.13 * 0.8, 1e-5) and near(body.y, 1.17, 1e-5) and near(legs.y, 0.425, 1e-5) and top.x == 0 and top.z == 0
	)
	-- Level, `width` out either way, and square to the line from the eye
	-- (which runs along z here).
	local edgeOk = true
	for _, pair in { { 4, 1, 1 }, { 5, 1, -1 }, { 6, 2, 1 }, { 7, 2, -1 } } do
		local off = points[pair[1]] - points[pair[2]]
		edgeOk = edgeOk and near(off.x, pair[3] * P.width.value, 1e-5) and near(off.y, 0, 1e-5) and near(off.z, 0, 1e-5)
	end
	check(
		string.format("and the head and the body out at their edges, %.2f m either side, level and square to the line", P.width.value),
		edgeOk
	)
	local crouched = FogOfWar.points(eye, ZERO, 1)
	check(
		string.format("crouched, they're lower: the head's top at %.2f m", crouched[1].y),
		near(crouched[1].y, 1.10 + 0.13 * 0.8, 1e-5) and crouched[2].y < body.y
	)
	local above = FogOfWar.points(v(0, 10, 0), ZERO, 0)
	check("from straight above, the edges still go out level", near(vector.magnitude(above[4] - above[1]), P.width.value, 1e-5))

	local still = viewer(1, 1, ZERO)
	check("a viewer standing still is looked from their eye alone", #FogOfWar.eyes(still) == 1)
	local runner = viewer(1, 1, ZERO, v(5.4, 0, 0), 0.1)
	local eyes = FogOfWar.eyes(runner)
	local t = 0.1 + P.every.value + P.ahead.value
	check(
		string.format(
			"one running is looked from where their velocity takes their eye too: %.2f s on (behind 0.1 s, the next look and %.2f s)",
			t,
			P.ahead.value
		),
		#eyes == 2 and near(eyes[2].x, 5.4 * t, 1e-5) and near(eyes[2].y, EYE, 1e-5)
	)
	local lagging = FogOfWar.eyes(viewer(1, 1, ZERO, v(5.4, 0, 0), 2))
	check(
		string.format("no further behind than %.2f s counts, for a lagging player", P.behindMost.value),
		near(lagging[2].x, 5.4 * (P.behindMost.value + P.every.value + P.ahead.value), 1e-5)
	)
	local crouching = viewer(1, 1, ZERO)
	crouching.eye = v(0, 1.10, 0)
	crouching.standEye = v(0, EYE, 0)
	local up = FogOfWar.eyes(crouching)
	check(
		"a crouched viewer is looked from their eye stood up as well",
		#up == 2 and near(up[2].y, EYE, 1e-5) and near(up[1].y, 1.10, 1e-5)
	)

	check("a target standing still is looked at where it is", #FogOfWar.bodies(target(2, 2, ZERO)) == 1)
	local bodies = FogOfWar.bodies(target(2, 2, ZERO, v(0, 0, -5.4)))
	check(
		string.format("one moving, where its velocity takes it by the next look too (%.2f s on)", P.every.value + P.ahead.value),
		#bodies == 2 and near(bodies[2].z, -5.4 * (P.every.value + P.ahead.value), 1e-5)
	)
end

-- Lines --------------------------------------------------------------------------------------

do
	local me = viewer(1, 1, ZERO)
	local them = target(2, 2, v(0, 0, -10))
	local line, cast = FogOfWar.sees(me, them, open)
	check("with nothing in the way, the first line sees", line == 1 and cast == 1)

	local level = FakeLevel.new()
	level:add("hard", v(-5, 0, -6), v(5, 4, -5)) -- a wall between
	local blocked, count = through(level)
	local none, n = FogOfWar.sees(me, them, blocked)
	check("behind a wall nothing sees, and all seven lines are cast", none == nil and n == 7 and count() == 7)
	local _, both = FogOfWar.sees(viewer(1, 1, ZERO, v(5, 0, 0)), target(2, 2, v(0, 0, -10), v(-5, 0, 0)), blocked)
	check("both moving, 28: two eyes, two bodies, seven points", both == 28)

	-- A pillar hides the middle of the body, not its edges (the reference's
	-- first try looked at an actor's middle alone: 'there are times where
	-- players can't see an actor's center point, but can still see the actor').
	local pillar = FakeLevel.new()
	pillar:add("hard", v(-0.15, 0, -6), v(0.15, 4, -5.8))
	local pillarBlocked = through(pillar)
	local edge = FogOfWar.sees(me, them, pillarBlocked)
	check("behind a thin pillar, an edge of the body is seen", edge ~= nil and edge >= 4)

	-- The line that saw last is tried first.
	local corner = FakeLevel.new()
	corner:add("hard", v(-0.6, 0, -6), v(0.1, 4, -5.8))
	local cornerBlocked, cornerCount = through(corner)
	local seen = FogOfWar.sees(me, them, cornerBlocked)
	local before = cornerCount()
	local again, tried = FogOfWar.sees(me, them, cornerBlocked, seen)
	check(
		string.format("the line that saw last time (line %s) is tried first", tostring(seen)),
		seen ~= nil and seen > 1 and again == seen and tried == 1 and cornerCount() == before + 1
	)

	-- A crouched viewer behind a box to their chin sees over it: they could
	-- stand up.
	local box = FakeLevel.new()
	box:add("hard", v(-2, 0, -2), v(2, 1.3, -1.5))
	local boxBlocked = through(box)
	local low = viewer(1, 1, ZERO)
	low.eye = v(0, 1.10, 0)
	local lowTarget = target(2, 2, v(0, 0, -10), nil, { crouchAlpha = 1 })
	check("a crouched viewer behind a box doesn't see a crouched target past it", FogOfWar.sees(low, lowTarget, boxBlocked) == nil)
	low.standEye = v(0, EYE, 0)
	check("but could stand up and see over it, so they're sent it", FogOfWar.sees(low, lowTarget, boxBlocked) ~= nil)
end

-- Coming round a corner -----------------------------------------------------------------------

-- Whether the target is in sight now, where both are: the same points, no
-- velocities.
local function inSight(me: FogOfWar.Viewer, them: FogOfWar.Target, blocked: FogOfWar.Blocked): boolean
	local still = table.clone(me)
	still.velocity = ZERO
	still.standEye = nil
	local stood = table.clone(them)
	stood.velocity = ZERO
	return FogOfWar.sees(still, stood, blocked) ~= nil
end

do
	-- A block to the viewer's left, a target behind it coming out at a
	-- rifle's running speed, 5.4 m/s, but quiet, so it isn't heard; the
	-- viewer holds still, looking at it.
	local level = FakeLevel.new()
	level:add("hard", v(-6, 0, -12), v(-1, 4, -8))
	local blocked = through(level)
	local worst = math.huge
	for offset = 0, 4 do
		local state = FogOfWar.new()
		local me = viewer(1, 1, ZERO)
		local shownAt, seenAt = math.huge, math.huge
		local nextLook = offset * 0.01
		for frame = 0, 120 do
			local t = frame / 120
			local them = target(2, 2, v(-4 + 5.4 * t, 0, -14), v(5.4, 0, 0), { quiet = true })
			if t >= nextLook - 1e-9 then
				FogOfWar.look(state, t, me, { them }, blocked)
				nextLook += P.every.value
			end
			if shownAt == math.huge and FogOfWar.shows(state, t, me, them) then
				shownAt = t
			end
			if seenAt == math.huge and inSight(me, them, blocked) then
				seenAt = t
			end
		end
		worst = math.min(worst, seenAt - shownAt)
	end
	check(
		string.format("a target running out round a corner is sent before any of it is in sight, %.0f ms before at the least", worst * 1000),
		worst > 0 and worst < 0.2
	)
end

do
	-- The viewer runs out past the end of a wall to a target holding still;
	-- their screen is 0.1 s behind the server, so the target has to be on
	-- its way to them at least that long before the server's eye sees it.
	local level = FakeLevel.new()
	level:add("hard", v(-1, 0, -2), v(6, 4, -1))
	local blocked = through(level)
	local behind = 0.1
	local state = FogOfWar.new()
	local them = target(2, 2, v(-5, 0, -10))
	local shownAt, seenAt = math.huge, math.huge
	local nextLook = 0
	for frame = 0, 120 do
		local t = frame / 120
		local me = viewer(1, 1, v(1.5 - 5.4 * t, 0, 0), v(-5.4, 0, 0), behind)
		if t >= nextLook - 1e-9 then
			FogOfWar.look(state, t, me, { them }, blocked)
			nextLook += P.every.value
		end
		if shownAt == math.huge and FogOfWar.shows(state, t, me, them) then
			shownAt = t
		end
		if seenAt == math.huge and inSight(me, them, blocked) then
			seenAt = t
		end
	end
	check(
		string.format(
			"peeking a held angle, the target's sent %.0f ms before the server's eye sees it (its screen is %.0f ms behind)",
			(seenAt - shownAt) * 1000,
			behind * 1000
		),
		seenAt < math.huge and seenAt - shownAt >= behind
	)
end

-- Hearing --------------------------------------------------------------------------------------

do
	local ear = v(0, EYE, 0)
	local function at(z: number, velocity: vector?, fields: { [string]: any }?): FogOfWar.Target
		return target(2, 2, v(0, 0, -z), velocity, fields)
	end
	local run = v(0, 0, 5.4)
	-- The ear is 0.62 m over the chest the sounds come from.
	local function reach(edge: number): number
		return math.sqrt((edge + P.hearing.value) ^ 2 - 0.62 ^ 2)
	end
	local steps = reach(FogOfWar.Edges.steps)
	check(
		string.format("running steps are heard to %.1f m (the footstep's %g m and %g m more)", steps, FogOfWar.Edges.steps, P.hearing.value),
		FogOfWar.hears(ear, at(steps - 0.01, run)) and not FogOfWar.hears(ear, at(steps + 0.01, run))
	)
	check("walking or crouching (quiet), they aren't", not FogOfWar.hears(ear, at(5, run, { quiet = true })))
	check("nor standing still", not FogOfWar.hears(ear, at(5)))
	check(
		string.format("nor moving slower than %.1f m/s", P.moving.value),
		not FogOfWar.hears(ear, at(5, v(0, 0, P.moving.value * 0.9))) and FogOfWar.hears(ear, at(5, v(0, 0, P.moving.value * 1.1)))
	)
	check("in the air, a landing's to come, as far as steps go", FogOfWar.hears(ear, at(steps - 0.01, nil, { grounded = false })))
	local reload = reach(FogOfWar.Edges.reload)
	check(
		string.format("a reload to %.1f m", reload),
		FogOfWar.hears(ear, at(reload - 0.01, nil, { reloading = true }))
			and not FogOfWar.hears(ear, at(reload + 0.01, nil, { reloading = true }))
	)
	local device = reach(FogOfWar.Edges.device)
	check(
		string.format("a plant or a defuse to %.1f m", device),
		FogOfWar.hears(ear, at(device - 0.01, nil, { channel = 1 })) and not FogOfWar.hears(ear, at(device + 0.01, nil, { channel = 2 }))
	)
	local glide = reach(FogOfWar.Edges.glide)
	check(
		string.format("a glide to %.1f m", glide),
		FogOfWar.hears(ear, at(glide - 0.01, nil, { gliding = true, grounded = false }))
			and not FogOfWar.hears(ear, at(glide + 0.01, nil, { gliding = true, grounded = false }))
	)
	check("the dead make no sound", not FogOfWar.hears(ear, at(2, run, { alive = false })))
end

-- Looks ----------------------------------------------------------------------------------------

do
	local level = FakeLevel.new()
	local wall = level:add("hard", v(-5, 0, -6), v(5, 4, -5))
	local blocked = through(level)
	local state = FogOfWar.new()
	local me = viewer(1, 1, ZERO)
	local hidden = target(2, 2, v(0, 0, -10))
	local cast = FogOfWar.look(state, 0, me, { hidden }, blocked)
	check("a look at an enemy behind a wall casts its lines and leaves them out", cast == 7 and not FogOfWar.shows(state, 0, me, hidden))
	cast = FogOfWar.look(state, 0.05, me, { hidden }, blocked)
	check("while neither moves, the next look casts nothing", cast == 0 and not FogOfWar.shows(state, 0.05, me, hidden))
	local stepped = target(2, 2, v(0.1, 0, -10))
	cast = FogOfWar.look(state, 0.1, me, { stepped }, blocked)
	check("once one has moved, the lines are cast again", cast == 7)

	check(
		string.format("and while neither moves, they're cast again every %.0f s, in case the level has changed", P.stale.value),
		FogOfWar.look(state, 0.1 + P.stale.value - 0.01, me, { stepped }, blocked) == 0
			and FogOfWar.look(state, 0.1 + P.stale.value, me, { stepped }, blocked) == 7
	)

	-- The wall goes, and they step out: in sight.
	state = FogOfWar.new()
	FogOfWar.look(state, 0.1, me, { stepped }, blocked)
	table.remove(level.boxes, table.find(level.boxes, wall))
	stepped = target(2, 2, v(0.2, 0, -10))
	cast = FogOfWar.look(state, 0.15, me, { stepped }, blocked)
	check("one in sight is in at once", cast == 1 and FogOfWar.shows(state, 0.15, me, stepped))
	cast = FogOfWar.look(state, 0.2, me, { stepped }, blocked)
	check(string.format("and isn't looked at again until %.2f s on", P.recheck.value), cast == 0)
	-- The wall's back: out of sight, but held.
	table.insert(level.boxes, wall)
	cast = FogOfWar.look(state, 0.4, me, { stepped }, blocked)
	check("rechecked out of sight, they're still in for the hold", cast == 7 and FogOfWar.shows(state, 0.4, me, stepped))
	check(
		string.format("until %.1f s after the look that last found them", P.hold.value),
		FogOfWar.shows(state, 0.15 + P.hold.value - 0.001, me, stepped) and not FogOfWar.shows(state, 0.15 + P.hold.value, me, stepped)
	)

	local spotted = target(3, 2, v(0, 0, -12))
	cast = FogOfWar.look(state, 1, me, { spotted }, blocked, { [3] = true })
	check("one their side spots is in, with no lines cast", cast == 0 and FogOfWar.shows(state, 1, me, spotted))
	local running = target(4, 2, v(0, 0, -10), v(5.4, 0, 0))
	cast = FogOfWar.look(state, 1, me, { running }, blocked)
	check("one heard behind the wall is in, with no lines cast", cast == 0 and FogOfWar.shows(state, 1, me, running))
	local mate = target(5, 1, v(0, 0, -10))
	cast = FogOfWar.look(state, 1, me, { mate }, blocked)
	check("a teammate is never looked at, and always in", cast == 0 and FogOfWar.shows(state, 1, me, mate))

	local down = { id = 9, side = 1 }
	check(
		"a player who's down has whatever their side in play has",
		FogOfWar.anyShows(state, 1, { me }, spotted) and not FogOfWar.shows(state, 1, down, spotted)
	)
	check("and their own side, always", FogOfWar.shows(state, 1, down, mate))
	FogOfWar.forget(state, 3)
	check("a player who leaves is forgotten as a target", not FogOfWar.shows(state, 1, me, spotted))
	FogOfWar.forget(state, 1)
	check("and as a viewer", state.pairs[1] == nil)
end

return nil
