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

	print(string.format("[%s] max %.2f m/s, accurate below %.2f m/s (%.0f%%)", id, maxSpeed, threshold, frac * 100))
	print("    start -> 95% speed:        " .. fmt(tTo95, "ms", 1000))
	print("    start -> inaccurate:       " .. fmt(tToInaccurate, "ms", 1000))
	if release then
		print(string.format("    release stop: accurate %s, zero %s, slide %.2f m", fmt(release.timeToAccurate, "ms", 1000), fmt(release.timeToZero, "ms", 1000), release.distance))
	end
	if counter then
		print(string.format("    counter stop: accurate %s, zero %s, slide %.2f m", fmt(counter.timeToAccurate, "ms", 1000), fmt(counter.timeToZero, "ms", 1000), counter.distance))
	end
end
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
	local threshold = 5.40 * 0.30
	local function stopTime(buttons: number): number?
		local s = spawn(floor)
		run(s, floor, B.Right, 256)
		return timeUntil(s, floor, buttons, 256, RIFLE, function(st)
			return MovementSim.horizontalSpeed(st) <= threshold
		end)
	end
	local release, counter = stopTime(0), stopTime(B.Left)
	check("counter-strafe reaches accuracy faster than release", release ~= nil and counter ~= nil and counter < release, string.format("%s vs %s", tostring(counter), tostring(release)))
	check("release stop becomes accurate within 250ms", release ~= nil and release <= 0.25)
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
	tickWith(B.Right, 12)
	tickWith(B.Left, 40)
	check("analyzer logs a release stop", analyzer.history[1] ~= nil and analyzer.history[1].method == "release")
	check("analyzer logs a counter stop", analyzer.history[2] ~= nil and analyzer.history[2].method == "counter")
end

return nil
