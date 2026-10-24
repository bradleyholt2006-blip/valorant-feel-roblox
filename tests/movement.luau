--!strict
-- Movement and counter-strafing (system 1).

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local MovementSim = require("../src/shared/Movement/MovementSim")
local StopAnalyzer = require("../src/shared/Movement/StopAnalyzer")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
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

return nil
