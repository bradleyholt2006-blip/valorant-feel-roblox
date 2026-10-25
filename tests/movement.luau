--!strict
-- Movement and counter-strafing (system 1).

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local MovementSim = require("../src/shared/Movement/MovementSim")
local StopAnalyzer = require("../src/shared/Movement/StopAnalyzer")
local JumpAnalyzer = require("../src/shared/Movement/JumpAnalyzer")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local BoxMath = require("../src/shared/Movement/BoxMath")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near, fmt = H.check, H.near, H.fmt

local B = MovementSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()

-- Run speed and deadzone of a weapon, exactly as PlayerSim derives them.
local function speedOf(id: string): number
	return cfg.baseRunSpeed * WeaponConfig.get(id).moveMultiplier.value
end
local function deadzoneOf(id: string): number
	local override = WeaponConfig.get(id).deadzoneFraction
	return if override then override.value else cfg.deadzoneFraction
end

local RIFLE = speedOf("vandal")

local function input(buttons: number, yaw: number?): MovementSim.Input
	return { seq = 0, buttons = buttons, yaw = yaw or 0, pitch = 0, slot = 1, viewTime = 0 }
end

-- Settles a fresh player on the floor of `world`.
local function spawn(world: any, pos: vector?): MovementSim.State
	local s = MovementSim.newState(pos or vector.create(0, 0.02, 0))
	for _ = 1, 16 do
		MovementSim.step(s, input(0), cfg, RIFLE, world, DT)
	end
	return s
end

local function run(s: MovementSim.State, world: any, buttons: number, ticks: number, yaw: number?, speed: number?)
	for _ = 1, ticks do
		MovementSim.step(s, input(buttons, yaw), cfg, speed or RIFLE, world, DT)
	end
end

-- Steps until predicate(state) is true; returns elapsed seconds or nil.
local function timeUntil(s: MovementSim.State, world: any, buttons: number, maxTicks: number, speed: number, pred: (MovementSim.State) -> boolean): number?
	for i = 1, maxTicks do
		MovementSim.step(s, input(buttons), cfg, speed, world, DT)
		if pred(s) then
			return i * DT
		end
	end
	return nil
end

local floor = FakeWorld.new():addFloor()

H.section("Movement metrics (tick " .. MovementConfig.TickRate.value .. " Hz)")
for _, id in { "knife", "classic", "vandal", "operator" } do
	local maxSpeed = speedOf(id)
	local frac = deadzoneOf(id)
	local threshold = maxSpeed * frac

	local s = spawn(floor)
	local tTo95 = timeUntil(s, floor, B.Right, 512, maxSpeed, function(st)
		return MovementSim.horizontalSpeed(st) >= maxSpeed * 0.95
	end)
	local tToInaccurate = timeUntil(spawn(floor), floor, B.Right, 512, maxSpeed, function(st)
		return MovementSim.horizontalSpeed(st) > threshold
	end)

	local function measureStop(buttons: number)
		local st = spawn(floor)
		run(st, floor, B.Right, 256, 0, maxSpeed)
		local analyzer = StopAnalyzer.new()
		local t = 0
		analyzer:tick(t, st.position, st.velocity, MovementSim.wishDirection(B.Right, 0), threshold)
		for _ = 1, 256 do
			MovementSim.step(st, input(buttons), cfg, maxSpeed, floor, DT)
			t += DT
			analyzer:tick(t, st.position, st.velocity, MovementSim.wishDirection(buttons, 0), threshold)
			if analyzer.history[1] then
				break
			end
		end
		return analyzer.history[1]
	end
	local release = measureStop(0)
	local counter = measureStop(B.Left)

	print(string.format("[%s] max %.2f m/s, accurate below %.3f m/s (%.1f%%)", id, maxSpeed, threshold, frac * 100))
	print("    start -> 95% speed:        " .. fmt(tTo95, "ms", 1000))
	print("    start -> inaccurate:       " .. fmt(tToInaccurate, "ms", 1000))
	if release then
		print(string.format("    release stop: accurate %s, zero %s, slide %.2f m", fmt(release.timeToAccurate, "ms", 1000), fmt(release.timeToZero, "ms", 1000), release.distance))
	end
	if counter then
		print(string.format("    counter stop: accurate %s, zero %s, slide %.2f m", fmt(counter.timeToAccurate, "ms", 1000), fmt(counter.timeToZero, "ms", 1000), counter.distance))
	end
end
-- Riot timed these on the Phantom (same 5.40 m/s as the Vandal) in 2020,
-- when the deadzone was 25%.
local RIOT = {
	counter = { quarter = 0.104, zero = 0.160 },
	walkStop = { quarter = 0.110, zero = 0.170 }, -- no counter-strafe, walk bound to fire
}
-- Time to 25% speed and to a stop from a full rifle run (ticks of the new
-- input until the speed is below the line, as footage times it from the key).
local function rifleStop(buttons: number): (number?, number?)
	local s = spawn(floor)
	run(s, floor, B.Right, 256)
	local quarter, zero
	for i = 1, 256 do
		MovementSim.step(s, input(buttons), cfg, RIFLE, floor, DT)
		local along = s.velocity.x
		if quarter == nil and along <= RIFLE * 0.25 then
			quarter = i * DT
		end
		if along <= 0.05 then
			zero = i * DT
			break
		end
	end
	return quarter, zero
end
local counterQuarter, counterZero = rifleStop(B.Left)
local releaseQuarter, releaseZero = rifleStop(0)
print(string.format(
	"[riot] Phantom 2020, to 25%% speed / stopped: counter-strafe %s / %s (ours %s / %s), no counter-strafe %s / %s (ours, letting go: %s / %s)",
	fmt(RIOT.counter.quarter, "ms", 1000),
	fmt(RIOT.counter.zero, "ms", 1000),
	fmt(counterQuarter, "ms", 1000),
	fmt(counterZero, "ms", 1000),
	fmt(RIOT.walkStop.quarter, "ms", 1000),
	fmt(RIOT.walkStop.zero, "ms", 1000),
	fmt(releaseQuarter, "ms", 1000),
	fmt(releaseZero, "ms", 1000)
))
do
	local s = spawn(floor)
	local startY = s.position.y
	local apex = startY
	local air = timeUntil(s, floor, B.Jump, 1024, RIFLE, function(st)
		apex = math.max(apex, st.position.y)
		return st.grounded and st.tick > 20
	end)
	print(string.format("[jump] apex %.2f m, airtime %s", apex - startY, fmt(air, "ms", 1000)))
end

H.section("Movement tests")

do
	local s = spawn(floor)
	check("spawn settles onto the floor", s.grounded and near(s.position.y, 0, 0.01), tostring(s.position))
end

do
	local s = spawn(floor)
	run(s, floor, B.Forward, 256)
	check("rifle run speed caps at 5.40 m/s", near(MovementSim.horizontalSpeed(s), 5.40, 0.01), tostring(MovementSim.horizontalSpeed(s)))
	check("forward with yaw 0 moves along -Z", s.velocity.z < -5)
end

do
	local s = spawn(floor)
	run(s, floor, B.Forward, 256, 0, speedOf("knife"))
	check("knife run speed caps at 6.75 m/s", near(MovementSim.horizontalSpeed(s), 6.75, 0.01))
end

do
	local s = spawn(floor)
	run(s, floor, B.Forward + B.Walk, 256)
	check("walk speed = run * walkMultiplier", near(MovementSim.horizontalSpeed(s), 5.40 * cfg.walkMultiplier, 0.01))
	local c = spawn(floor)
	run(c, floor, B.Forward + B.Crouch, 256)
	check("crouch speed = run * crouchMultiplier", near(MovementSim.horizontalSpeed(c), 5.40 * cfg.crouchMultiplier, 0.01))
	check("crouch lowers the eye", near(MovementSim.eyeHeight(c, cfg), cfg.crouchEyeHeight, 1e-6))
end

do
	local s = spawn(floor)
	run(s, floor, B.Left + B.Right, 128)
	check("holding A and D together cancels input", MovementSim.horizontalSpeed(s) < 1e-6)
end

do
	local s = spawn(floor)
	run(s, floor, B.Forward + B.Right, 256)
	check("diagonal is not faster than straight", MovementSim.horizontalSpeed(s) <= 5.40 + 1e-3)
end

do
	-- Riot's numbers are only good to a few ms ("inconsistent frame rates and
	-- human input"), and ours move in 7.8 ms ticks: allow one tick.
	local function within(ours: number?, riot: number): boolean
		return ours ~= nil and math.abs(ours - riot) <= DT + 1e-9
	end
	local detail = string.format("%s / %s", fmt(counterQuarter, "ms", 1000), fmt(counterZero, "ms", 1000))
	check("counter-strafe reaches 25% speed in 0.104 s (Riot, Phantom)", within(counterQuarter, RIOT.counter.quarter), detail)
	check("counter-strafe stops in 0.160 s (Riot, Phantom)", within(counterZero, RIOT.counter.zero), detail)
	-- Riot timed the stop without counter-strafing with walk bound to fire,
	-- 6-10 ms slower, and said letting go of the keys is at least as fast.
	check(
		"letting go stops as fast as counter-strafing, within a tick",
		releaseQuarter ~= nil and counterQuarter ~= nil and releaseZero ~= nil and counterZero ~= nil
			and math.abs(releaseQuarter - counterQuarter) <= DT + 1e-9
			and math.abs(releaseZero - counterZero) <= DT + 1e-9,
		string.format("%s / %s", fmt(releaseQuarter, "ms", 1000), fmt(releaseZero, "ms", 1000))
	)
	check("and no slower than Riot's walk-key stop", releaseQuarter ~= nil and releaseZero ~= nil and releaseQuarter <= RIOT.walkStop.quarter + DT and releaseZero <= RIOT.walkStop.zero + DT)
end

do
	-- Holding a key holds the wish speed exactly, however slow: a slowed
	-- player must not drift down into the deadzone (Patch 3.0's "tag into
	-- accuracy"). 1.2 m/s is below anything friction alone could sustain in
	-- a Source-style model.
	local s = spawn(floor)
	run(s, floor, B.Right, 256, 0, 1.2)
	local lowest, highest = math.huge, 0
	for _ = 1, 128 do
		run(s, floor, B.Right, 1, 0, 1.2)
		local speed = MovementSim.horizontalSpeed(s)
		lowest, highest = math.min(lowest, speed), math.max(highest, speed)
	end
	check("a held key holds a slow wish speed exactly", near(lowest, 1.2, 1e-5) and near(highest, 1.2, 1e-5), string.format("%.5f .. %.5f", lowest, highest))
end

do
	-- Pressing walk while running brakes down to walking speed and stops there.
	local s = spawn(floor)
	run(s, floor, B.Right, 256)
	local walkSpeed = RIFLE * cfg.walkMultiplier
	local reached = timeUntil(s, floor, B.Right + B.Walk, 128, RIFLE, function(st)
		return MovementSim.horizontalSpeed(st) <= walkSpeed + 1e-6
	end)
	run(s, floor, B.Right + B.Walk, 64)
	check("walking from a run brakes to walk speed, not below it", reached ~= nil and reached < 0.1 and near(MovementSim.horizontalSpeed(s), walkSpeed, 1e-5), fmt(reached, "ms", 1000))
end

do
	-- Wall at x = 2 .. 3, running diagonally into it should slide along Z.
	local world = FakeWorld.new():addFloor():addBox(vector.create(2, 0, -50), vector.create(3, 3, 50))
	local s = spawn(world)
	run(s, world, B.Forward + B.Right, 256)
	check("wall stops penetration", s.position.x + cfg.halfWidth <= 2 + 1e-3, tostring(s.position))
	check("wall slide keeps tangential speed", math.abs(s.velocity.z) > 3, tostring(s.velocity))
end

do
	-- 0.3 m step should be walked up, 0.6 m wall should not.
	local world = FakeWorld.new():addFloor():addBox(vector.create(1, 0, -5), vector.create(10, 0.3, 5))
	local s = spawn(world)
	run(s, world, B.Right, 128)
	check("walks up a 0.3 m step", s.position.x > 2 and near(s.position.y, 0.3, 0.02) and s.grounded, tostring(s.position))

	local wall = FakeWorld.new():addFloor():addBox(vector.create(1, 0, -5), vector.create(10, 0.6, 5))
	local w = spawn(wall)
	run(w, wall, B.Right, 128)
	check("blocked by a 0.6 m ledge", w.position.x < 1, tostring(w.position))
end

do
	local s = spawn(floor)
	local startY = s.position.y
	local apex = startY
	run(s, floor, B.Jump, 1)
	check("jump leaves the ground", not s.grounded and s.velocity.y > 0)
	for _ = 1, 256 do
		run(s, floor, B.Jump, 1)
		apex = math.max(apex, s.position.y)
	end
	check("jump apex matches jumpApexHeight", near(apex - startY, cfg.jumpApexHeight, 0.03), tostring(apex - startY))
	check("holding jump does not auto-bhop", s.grounded and s.lastLandTick > s.lastJumpTick)
end

do
	-- Ceiling at 1.5 m: crouch under it, release crouch, must stay crouched.
	local world = FakeWorld.new():addFloor():addBox(vector.create(1, 1.5, -5), vector.create(10, 3, 5))
	local s = spawn(world)
	run(s, world, B.Crouch, 32)
	run(s, world, B.Crouch + B.Right, 256)
	check("crouched under the ceiling", s.position.x > 1.5, tostring(s.position))
	run(s, world, 0, 64)
	check("cannot stand up under a low ceiling", s.crouched)
end

H.section("Collision with the course's ramps, angled wall and jump boxes")

-- The course's movement pieces, as src/server/TestRange.luau builds them.
-- `turn` adds degrees to every rotated part's angle, as replication rounding
-- does (Studio showed the client 0.002 degrees off the server).
local function course(turn: number?): any
	local w = FakeWorld.new():addFloor()
	for i, h in { 0.50, 0.70, 0.85, 1.00 } do
		local x = -6 - (i - 1) * 2.5
		w:addBox(vector.create(x - 0.75, 0, -10.75), vector.create(x + 0.75, h, -9.25))
	end
	for i, deg in { 30, 45, 50 } do
		w:addPart(vector.create(18, math.sin(math.rad(deg)) * 2.5, 6 + (i - 1) * 3), vector.create(5, 0.2, 2), 0, 0, math.rad(deg + (turn or 0)))
	end
	w:addPart(vector.create(14, 1.5, -14), vector.create(8, 3, 0.3), 0, math.rad(30 + (turn or 0)), 0)
	return w
end

local EAST = -math.pi / 2 -- yaw that walks toward +X
local NORTH = 0 -- toward -Z

type Leg = { buttons: number, yaw: number, ticks: number }

-- Plays legs of input on a fresh player at the knife's run speed. Returns
-- the final state, the smallest clearance kept to anything (negative means it
-- got inside), the ticks spent in the air and every tick's position.
local function walk(world: any, start: vector, legs: { Leg }): (MovementSim.State, number, number, { vector })
	local s = MovementSim.newState(start)
	local clearance, air = math.huge, 0
	local path: { vector } = {}
	for _, leg in legs do
		for _ = 1, leg.ticks do
			MovementSim.step(s, input(leg.buttons, leg.yaw), cfg, cfg.baseRunSpeed, world, DT)
			local height = MovementSim.boxHeight(s, cfg)
			local half = vector.create(cfg.halfWidth, height / 2, cfg.halfWidth)
			clearance = math.min(clearance, world:clearance(s.position + vector.create(0, height / 2, 0), half))
			air += if s.grounded then 0 else 1
			table.insert(path, s.position)
		end
	end
	return s, clearance, air, path
end

-- The box must always stay outside the fake world's blind spot (1 mm, over
-- three times Roblox's), or a sweep could miss what it's next to.
local CLEAR = FakeWorld.START_TOLERANCE

do
	local world = course()
	for i, deg in { 30, 45 } do
		local z = 6 + (i - 1) * 3
		local up, upClear, upAir = walk(world, vector.create(14, 0.02, z), { { buttons = B.Forward, yaw = EAST, ticks = 100 } })
		check(
			string.format("walks up the %d degree ramp on the ground, clear of it", deg),
			upAir == 0 and upClear >= CLEAR and up.position.y > 1 and up.groundNormal.y < 0.9,
			string.format("air %d ticks, clearance %.4f m, at %s", upAir, upClear, tostring(up.position))
		)
		check(string.format("keeps its horizontal speed up the %d degree ramp", deg), near(MovementSim.horizontalSpeed(up), cfg.baseRunSpeed, 1e-3), tostring(up.velocity))
		local down, downClear, downAir = walk(world, vector.create(14, 0.02, z), {
			{ buttons = B.Forward, yaw = EAST, ticks = 100 },
			{ buttons = B.Back, yaw = EAST, ticks = 160 },
		})
		check(
			string.format("walks back down the %d degree ramp onto the floor", deg),
			downAir == 0 and downClear >= CLEAR and down.position.x < 15 and near(down.position.y, 0.005, 1e-4),
			string.format("air %d ticks, clearance %.4f m, at %s", downAir, downClear, tostring(down.position))
		)
	end

	local steep, steepClear, steepAir, path = walk(world, vector.create(14, 0.02, 12), { { buttons = B.Forward, yaw = EAST, ticks = 160 } })
	check(
		"the 50 degree ramp blocks without letting you creep up it",
		steepAir == 0 and steepClear >= CLEAR and steep.position.x < 16 and near(steep.position.y, 0.005, 1e-4) and steep.position == path[100],
		string.format("air %d ticks, clearance %.4f m, at %s", steepAir, steepClear, tostring(steep.position))
	)
end

do
	-- The angled wall: run +X into it at 30 degrees, and along it at a
	-- glancing 1 and 0.05 degrees, which wear a gap measured along the move
	-- down to nothing.
	local world = course()
	local n = vector.create(0.5, 0, math.sqrt(3) / 2) -- its face normal; we start on the -n side
	local t = vector.create(math.sqrt(3) / 2, 0, -0.5) -- along it
	local wallCenter = vector.create(14, 0, -14)
	-- The furthest the player's centre got to the wall's far side while level with it.
	local function side(path: { vector }): number
		local worst = -math.huge
		for _, p in path do
			if math.abs(vector.dot(p - wallCenter, t)) < 4 then
				worst = math.max(worst, vector.dot(p - wallCenter, n))
			end
		end
		return worst
	end
	local s, clear, _, path = walk(world, vector.create(10, 0.02, -12.94), { { buttons = B.Forward, yaw = EAST, ticks = 256 } })
	check(
		"slides along the angled wall and off its end instead of through it",
		clear >= CLEAR and side(path) < 0 and s.position.x > 18,
		string.format("clearance %.4f m, at %s", clear, tostring(s.position))
	)
	for _, degrees in { 1, 0.05 } do
		local a = math.rad(degrees)
		local wish = t * math.cos(a) + n * math.sin(a)
		local start = wallCenter - n * (0.15 + cfg.halfWidth * (n.x + n.z) + 0.005) - t * 3.5 + vector.create(0, 0.02, 0)
		local g, gClear, _, gPath = walk(world, start, { { buttons = B.Forward, yaw = math.atan2(-wish.x, -wish.z), ticks = 110 } })
		check(
			string.format("keeps clear of the angled wall on a %.2f degree glancing run", degrees),
			gClear >= CLEAR and side(gPath) < 0,
			string.format("clearance %.4f m, at %s", gClear, tostring(g.position))
		)
	end
end

do
	-- Press against a box's side, jump with forward held and slide down it
	-- (Studio sank the player into the 0.85 and 1.00 m boxes doing this).
	-- The 0.70 m box is low enough to climb onto.
	local world = course()
	for i, h in { 0.70, 0.85, 1.00 } do
		local x = -6 - i * 2.5
		local s, clear = walk(world, vector.create(x, 0.02, -8.5), {
			{ buttons = B.Forward, yaw = NORTH, ticks = 40 },
			{ buttons = B.Forward + B.Jump, yaw = NORTH, ticks = 5 },
			{ buttons = B.Forward, yaw = NORTH, ticks = 40 },
			{ buttons = 0, yaw = NORTH, ticks = 80 },
		})
		local onTop = s.grounded and near(s.position.y, h + 0.005, 1e-4)
		local beside = s.grounded and near(s.position.y, 0.005, 1e-4) and s.position.z > -9.25 + cfg.halfWidth
		check(
			string.format("a jump against the %.2f m box %s", h, if h < 0.83 then "lands on top" else "slides back down its side"),
			clear >= CLEAR and (if h < 0.83 then onTop else beside),
			string.format("clearance %.4f m, at %s", clear, tostring(s.position))
		)
	end
end

do
	-- Dropped onto the 30 degree ramp: lands on it and stays put.
	local s, clear, _, path = walk(course(), vector.create(18, 3, 6), { { buttons = 0, yaw = 0, ticks = 128 } })
	check(
		"lands on a ramp and stands on it without sliding",
		s.grounded and clear >= CLEAR and s.groundNormal.y < 0.9 and s.position == path[100],
		string.format("clearance %.4f m, at %s", clear, tostring(s.position))
	)
end

do
	-- Replication rounds rotated parts by about 0.002 degrees: the client's
	-- prediction must stay inside its correction tolerance of the server's
	-- (PlayerController: 2 mm and 0.01 m/s).
	local legs = {
		{ buttons = B.Forward, yaw = EAST, ticks = 100 },
		{ buttons = B.Back, yaw = EAST, ticks = 100 },
	}
	local worst, worstSpeed = 0, 0
	for _, start in { vector.create(14, 0.02, 6), vector.create(14, 0.02, 9), vector.create(14, 0.02, 12), vector.create(10, 0.02, -12.94) } do
		local server, client = MovementSim.newState(start), MovementSim.newState(start)
		local serverWorld, clientWorld = course(), course(0.002)
		for _, leg in legs do
			for _ = 1, leg.ticks do
				MovementSim.step(server, input(leg.buttons, leg.yaw), cfg, cfg.baseRunSpeed, serverWorld, DT)
				MovementSim.step(client, input(leg.buttons, leg.yaw), cfg, cfg.baseRunSpeed, clientWorld, DT)
				worst = math.max(worst, vector.magnitude(server.position - client.position))
				worstSpeed = math.max(worstSpeed, vector.magnitude(server.velocity - client.velocity))
			end
		end
	end
	check(
		"rotated parts rounded by replication stay within the client's correction tolerance",
		worst < 0.002 and worstSpeed < 0.01,
		string.format("%.5f m, %.5f m/s", worst, worstSpeed)
	)
end

do
	-- Exact overlap tests where Roblox only gives bounding boxes: a box beside
	-- a 45 degree ramp sits inside the ramp's bounding box but clear of it.
	local ramp: BoxMath.Box = {
		center = vector.create(0, 0, 0),
		half = vector.create(2.5, 0.1, 1),
		axes = { vector.create(math.sqrt(0.5), math.sqrt(0.5), 0), vector.create(-math.sqrt(0.5), math.sqrt(0.5), 0), vector.create(0, 0, 1) },
	}
	local half = vector.create(0.34, 0.9, 0.34)
	local clearGap = BoxMath.separation(vector.create(1.2, -0.6, 0), half, ramp)
	local insideGap, away = BoxMath.separation(vector.create(0, 0.3, 0), half, ramp)
	check(
		"exact box overlap test against a rotated part",
		clearGap > 0.1 and insideGap < 0 and vector.dot(away, ramp.axes[2]) > 0.99,
		string.format("%.3f m clear, %.3f m inside", clearGap, insideGap)
	)
end

do
	local function simulate(): vector
		local s = spawn(floor)
		local pattern = { B.Right, B.Left, B.Forward + B.Right, 0, B.Jump + B.Forward, B.Crouch + B.Left }
		for i = 1, 600 do
			run(s, floor, pattern[(i // 37) % #pattern + 1], 1, i * 0.01)
		end
		return s.position
	end
	local a, b = simulate(), simulate()
	check("simulation is deterministic", a == b)
end

do
	local analyzer = StopAnalyzer.new()
	local s = spawn(floor)
	local t = 0
	local function tickWith(buttons: number, n: number)
		for _ = 1, n do
			MovementSim.step(s, input(buttons), cfg, 5.40, floor, DT)
			t += DT
			analyzer:tick(t, s.position, s.velocity, MovementSim.wishDirection(buttons, 0), 5.40 * 0.3)
		end
	end
	tickWith(B.Right, 200)
	tickWith(0, 200)
	tickWith(B.Left, 200)
	tickWith(B.Right, 32)
	tickWith(0, 40)
	check("analyzer logs a release stop", analyzer.history[1] ~= nil and analyzer.history[1].method == "release")
	check("analyzer logs a counter stop", analyzer.history[2] ~= nil and analyzer.history[2].method == "counter")
end

do
	-- The reference times are for stops from a full run, so a release before
	-- reaching full speed is logged but left out of the averages.
	local analyzer = StopAnalyzer.new()
	local s = spawn(floor)
	local t = 0
	local function tickWith(buttons: number, n: number)
		for _ = 1, n do
			MovementSim.step(s, input(buttons), cfg, 5.40, floor, DT)
			t += DT
			analyzer:tick(t, s.position, s.velocity, MovementSim.wishDirection(buttons, 0), 5.40 * 0.275, 5.40 * 0.95)
		end
	end
	tickWith(B.Right, 200)
	tickWith(0, 100)
	tickWith(B.Right, 20) -- about half speed
	tickWith(0, 100)
	local full, part = analyzer.history[1], analyzer.history[2]
	local _, averaged = analyzer:average("release", "distance")
	check("a stop from a full run counts toward the averages", full ~= nil and full.fromFullSpeed)
	check(
		"a stop from part speed is logged but not averaged",
		part ~= nil and not part.fromFullSpeed and averaged == 1,
		if part then string.format("began at %.2f m/s", part.startSpeed) else "no second stop"
	)
	analyzer:clear()
	local _, after = analyzer:average("release", "distance")
	check("clearing the analyzer forgets every stop (the lab's Backspace)", #analyzer.history == 0 and after == 0)
end

H.section("Air movement")

-- One jump on the flat floor, measured the way the HUD measures it: run at
-- full speed first if `running`, take off, then hold `keys` in the air while
-- the mouse turns right at `turn` degrees a second (left if negative), until
-- the player lands. Also returns the fastest speed along the ground on the
-- way and how long holding `keys` took to stop the run, if it did.
local function airJump(keys: number, turn: number, running: boolean, c: any?): (JumpAnalyzer.Jump, number, number?)
	local tuning = c or cfg
	local s = spawn(floor)
	local analyzer = JumpAnalyzer.new()
	local yaw, t = 0, 0
	local function step(buttons: number): JumpAnalyzer.Jump?
		MovementSim.step(s, input(buttons, yaw), tuning, RIFLE, floor, DT)
		t += DT
		return JumpAnalyzer.tick(analyzer, t, s.position, s.velocity, s.grounded, yaw)
	end
	local runKeys = if running then B.Forward else 0
	for _ = 1, if running then 256 else 1 do
		step(runKeys)
	end
	step(runKeys + B.Jump)
	local fastest, stopped = 0, nil
	for i = 1, 512 do
		yaw -= math.rad(turn) * DT
		local jump = step(keys)
		fastest = math.max(fastest, MovementSim.horizontalSpeed(s))
		if stopped == nil and running and -s.velocity.z <= 0 then
			stopped = i * DT
		end
		if jump then
			return jump, fastest, stopped
		end
	end
	error("never landed")
end

-- A run and then `count` strafe hops in a row: each one holds D and turns
-- right, the next A and left, and jumps again on the tick it lands. Returns
-- the fastest speed along the ground on the way.
local STRAFE_TURN = 180 -- degrees a second
local function strafeHops(count: number, c: any?): number
	local tuning = c or cfg
	local s = spawn(floor)
	local yaw = 0
	run(s, floor, B.Forward, 256)
	local fastest = 0
	for hop = 1, count do
		local keys, sign = if hop % 2 == 1 then B.Right else B.Left, if hop % 2 == 1 then 1 else -1
		MovementSim.step(s, input(keys + B.Jump, yaw), tuning, RIFLE, floor, DT)
		repeat
			yaw -= sign * math.rad(STRAFE_TURN) * DT
			MovementSim.step(s, input(keys, yaw), tuning, RIFLE, floor, DT)
			fastest = math.max(fastest, MovementSim.horizontalSpeed(s))
		until s.grounded
	end
	return fastest
end

local CS = MovementConfig.resolve({ airSpeedLimit = 1e6 }) -- Counter-Strike: no limit on the speed strafing builds

local drift = airJump(B.Right, 0, false)
local coast = airJump(0, 0, true)
local braked, _, airStop = airJump(B.Back, 0, true)
local forwardTurn = airJump(B.Forward, 90, true)
print(string.format("[air] standing jump holding D: lands %.2f m to the side, drifting at %.2f m/s", drift.side, drift.landingSpeed))
print(string.format("[air] running jump (%.2f m/s), letting go: %.2f m in %s, lands at %.2f m/s", RIFLE, coast.distance, fmt(coast.airtime, "ms", 1000), coast.landingSpeed))
print(string.format("[air] running jump holding S: stopped in the air after %s, lands %+.2f m along the run from take-off", fmt(airStop, "ms", 1000), braked.forward))
for _, rate in { 90, 180, 360, 720 } do
	local jump = airJump(B.Right, rate, true)
	print(string.format("[air] running jump holding D, mouse turning right %d deg/s: path bends %.0f deg (the crosshair turns %.0f), lands at %.2f m/s", rate, jump.bend, rate * (jump.airtime - DT), jump.landingSpeed))
end
print(string.format("[air] running jump holding W, mouse turning right 90 deg/s: path bends %.0f deg", forwardTurn.bend))
print(string.format("[air] 10 strafe hops, mouse %d deg/s: fastest %.2f m/s (Counter-Strike's model, without the limit: %.2f m/s)", STRAFE_TURN, strafeHops(10), strafeHops(10, CS)))

do
	check(
		"standing jump holding D drifts at the wish-speed cap",
		near(drift.landingSpeed, cfg.airWishSpeedCap, 1e-3) and near(drift.side, cfg.airWishSpeedCap * drift.airtime, 0.02) and math.abs(drift.forward) < 1e-3,
		string.format("side %.3f m, forward %.3f m, %.3f m/s", drift.side, drift.forward, drift.landingSpeed)
	)
	check(
		"letting go in the air keeps the speed and the line",
		near(coast.landingSpeed, RIFLE, 1e-3) and near(coast.distance, RIFLE * coast.airtime, 0.02) and math.abs(coast.side) < 1e-3 and math.abs(coast.bend) < 1e-3,
		string.format("%.3f m/s, %.3f m, side %.3f, bend %.3f", coast.landingSpeed, coast.distance, coast.side, coast.bend)
	)
	check("holding the opposite key stops a run in the air within 0.1 s", airStop ~= nil and airStop <= 0.1, fmt(airStop, "ms", 1000))
	check(
		"and lands about where it jumped, drifting back at the cap, which the analyzer doesn't count as a bend",
		math.abs(braked.forward) < 0.3 and near(braked.landingSpeed, cfg.airWishSpeedCap, 1e-3) and math.abs(braked.bend) < 1e-3,
		string.format("%.3f m, %.3f m/s, bend %.1f deg", braked.forward, braked.landingSpeed, braked.bend)
	)

	-- Air strafing: the path keeps following the crosshair, a few degrees to
	-- the strafe side of it, without losing speed, until the mouse turns
	-- faster than about 680 degrees a second.
	for _, rate in { 90, 180, 360 } do
		local jump = airJump(B.Right, rate, true)
		local crosshair = rate * (jump.airtime - DT)
		check(
			string.format("holding D with the mouse turning %d deg/s bends the path with the crosshair, at full speed", rate),
			math.abs(jump.bend - crosshair) < 10 and near(jump.landingSpeed, RIFLE, 1e-3),
			string.format("bend %.1f deg, crosshair %.1f deg, %.3f m/s", jump.bend, crosshair, jump.landingSpeed)
		)
	end
	local left = airJump(B.Left, -180, true)
	local right = airJump(B.Right, 180, true)
	check("strafing left bends the path left as far", near(left.bend, -right.bend, 1e-3), string.format("%.2f / %.2f deg", left.bend, right.bend))
	check("holding W doesn't steer while you look where you're going", math.abs(forwardTurn.bend) < 1, string.format("%.2f deg", forwardTurn.bend))

	-- A respawn: the HUD clears the analyzer, and the new life starts 5 cm up,
	-- far from where the last one ended. Settling onto the floor isn't a jump.
	do
		local a = JumpAnalyzer.new()
		local zero = vector.create(0, 0, 0)
		JumpAnalyzer.tick(a, 0, vector.create(99, 0, -15), zero, true, 0)
		JumpAnalyzer.clear(a)
		local settled = nil
		for i = 1, 20 do
			settled = JumpAnalyzer.tick(a, i * DT, vector.create(0, if i < 10 then 0.05 else 0, 0), zero, i >= 10, 0) or settled
		end
		check("after a respawn, settling onto the floor isn't measured as a jump", settled == nil and #a.history == 0)
	end

	local fastest = strafeHops(10)
	check("strafe hops never beat running speed", fastest <= RIFLE + 1e-3, string.format("%.3f m/s", fastest))
	local gained = strafeHops(10, CS)
	check("raising airSpeedLimit lets strafing build speed, as in Counter-Strike", gained > RIFLE * 1.15, string.format("%.3f m/s", gained))
end

do
	-- Crouching in the air doesn't weaken air control.
	local crouched = airJump(B.Right + B.Crouch, 180, true)
	local standing = airJump(B.Right, 180, true)
	check("crouching in the air strafes as well as standing", near(crouched.bend, standing.bend, 0.01) and near(crouched.landingSpeed, standing.landingSpeed, 1e-3), string.format("%.2f / %.2f deg", crouched.bend, standing.bend))
end

do
	-- Already faster than running (as a dash would make you): strafing turns
	-- the path but neither speeds it up nor slows it down.
	local s = MovementSim.newState(vector.create(0, 20, 0))
	s.velocity = vector.create(0, 0, -8)
	local yaw = 0
	for _ = 1, 64 do
		yaw -= math.rad(180) * DT
		MovementSim.step(s, input(B.Right, yaw), cfg, RIFLE, floor, DT)
	end
	local h = vector.create(s.velocity.x, 0, s.velocity.z)
	local bend = math.deg(math.atan2(h.x, -h.z))
	check(
		"faster than running, strafing turns you without changing your speed",
		near(vector.magnitude(h), 8, 1e-3) and bend > 60 and not s.grounded,
		string.format("%.3f m/s, bend %.1f deg", vector.magnitude(h), bend)
	)
end

do
	-- The analyzer counts a step off a ledge as time in the air, and
	-- measures sideways from where you faced, not where you moved.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-1, 0, -1), vector.create(1, 1, 1))
	local s = spawn(world, vector.create(0, 1.02, 0))
	local analyzer = JumpAnalyzer.new()
	local t, landed = 0, nil
	for _ = 1, 256 do
		MovementSim.step(s, input(B.Right, 0), cfg, RIFLE, world, DT)
		t += DT
		landed = JumpAnalyzer.tick(analyzer, t, s.position, s.velocity, s.grounded, 0) or landed
	end
	check(
		"stepping off a ledge counts as time in the air, measured to the side of where you faced",
		landed ~= nil and landed.side > 1 and math.abs(landed.forward) < 1e-3 and math.abs(landed.bend) < 1e-3 and #analyzer.history == 1,
		if landed then string.format("side %.2f m, forward %.3f m, %.2f s", landed.side, landed.forward, landed.airtime) else "never landed"
	)
	JumpAnalyzer.clear(analyzer)
	check("clearing the jump analyzer forgets every jump", #analyzer.history == 0)
end

return nil
