--!strict
-- Spread and recoil (system 3): firing error, recovery and tap efficiency,
-- movement error by state, crouch and ADS, error power, the recoil climb and
-- sideways drift, and determinism of the per-shot randomness.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player settled on the floor, past the spawn landing penalty.
local function newPlayer(loadout: { string }?, seed: number?, buttons: number?): PlayerSim.State
	local s = PlayerSim.new(vector.create(0, 0.02, 0), loadout, seed or 1)
	for _ = 1, 40 do
		PlayerSim.step(s, input(buttons or 0, s.weapons.equipped), cfg, floor, DT)
	end
	return s
end

local function loadoutFor(id: string): { string }
	local def = WeaponConfig.get(id)
	return { if def.slot == 1 then id else "vandal", if def.slot == 2 then id else "classic", "knife" }
end

local function run(s: PlayerSim.State, buttons: number, ticks: number): { WeaponSim.Shot }
	local shots = {}
	for _ = 1, ticks do
		local shot = PlayerSim.step(s, input(buttons, s.weapons.equipped), cfg, floor, DT)
		if shot then
			table.insert(shots, shot)
		end
	end
	return shots
end

local function ticksFor(seconds: number): number
	return math.ceil(seconds / DT) + 1
end

-- Fires `count` shots as fast as the weapon allows: auto weapons hold the
-- trigger, semi-autos are a perfect clicker. `buttons` are held throughout.
local function spray(s: PlayerSim.State, count: number, buttons: number?): { WeaponSim.Shot }
	local shots = {}
	local def = PlayerSim.def(s)
	local held = buttons or 0
	for _ = 1, ticksFor(count / def.fireRate.value + 1) do
		local w = s.weapons
		local ready = (s.movement.tick + 1) * DT >= w.nextFireTime - 1e-9 and not w.fireHeld
		local fire = if def.fireMode == "auto" or ready then B.Fire else 0
		local shot = PlayerSim.step(s, input(held + fire, w.equipped), cfg, floor, DT)
		if shot then
			table.insert(shots, shot)
			if #shots == count then
				break
			end
		end
	end
	return shots
end

-- Taps one shot every `interval` seconds, `count` times.
local function taps(s: PlayerSim.State, interval: number, count: number): { WeaponSim.Shot }
	local shots = {}
	local every = math.max(math.floor(interval / DT + 0.5), 2)
	for i = 0, every * count - 1 do
		local shot = PlayerSim.step(s, input(if i % every == 0 then B.Fire else 0, s.weapons.equipped), cfg, floor, DT)
		if shot then
			table.insert(shots, shot)
		end
	end
	return shots
end

-- Angle between two unit vectors, degrees. atan2 rather than acos: vector
-- components are 32-bit floats, and acos near 1 would turn their rounding
-- into hundredths of a degree.
local function angle(a: vector, b: vector): number
	return math.deg(math.atan2(vector.magnitude(vector.cross(a, b)), vector.dot(a, b)))
end

H.section("Spread and recoil metrics")
for _, id in { "vandal", "phantom", "classic", "sheriff", "operator" } do
	local def = WeaponConfig.get(id)
	local s = newPlayer(loadoutFor(id))
	s.weapons.equipped = def.slot
	local count = math.min(def.magazine.value, 16)
	local shots = spray(s, count)
	local cells = {}
	for _, shot in shots do
		table.insert(cells, string.format("%.3g:%.2f/%.1f%+.1f", shot.bullet, shot.cone.radius, shot.recoilPitch, shot.recoilYaw))
	end
	print(string.format("[%s] spray, bullet:cone/up+right (deg): %s", id, table.concat(cells, " ")))

	local tapCells = {}
	for _, interval in { 0.15, 0.2, 0.25, 0.3, 0.4 } do
		local t = newPlayer(loadoutFor(id))
		t.weapons.equipped = def.slot
		local tapped = taps(t, math.max(interval, 1 / def.fireRate.value), 10)
		local last = tapped[#tapped]
		if last then
			table.insert(tapCells, string.format("%.2fs -> bullet %.2f (%.2f deg)", interval, last.bullet, last.cone.radius))
		end
	end
	print("    tapping, 10th tap: " .. table.concat(tapCells, ", "))

	local first = Accuracy.cone(def, { moveState = "still", crouched = false, landing = false }, 1, false).radius
	print(string.format(
		"    first shot %.2f deg: %.1f cm radius at 10 m, %.1f at 20 m, %.1f at 30 m (a head is about 24 cm wide)",
		first,
		math.tan(math.rad(first)) * 1000,
		math.tan(math.rad(first)) * 2000,
		math.tan(math.rad(first)) * 3000
	))
end

H.section("Spread and recoil tests")

do
	local ok = true
	local function param(id: string, key: string, v: any)
		if type(v) ~= "table" or type(v.value) ~= "number" or type(v.status) ~= "string" or v.source == "" then
			ok = false
			print("    missing or unlabelled: " .. id .. "." .. key)
		end
	end
	local function curve(id: string, key: string, v: any)
		if type(v) ~= "table" or type(v.points) ~= "table" or #v.points == 0 or v.source == "" then
			ok = false
			print("    missing or unlabelled curve: " .. id .. "." .. key)
			return
		end
		for i = 2, #v.points do
			if v.points[i][1] <= v.points[i - 1][1] then
				ok = false
				print("    curve x not ascending: " .. id .. "." .. key)
			end
		end
	end
	for id, def in WeaponConfig.Defs do
		for key, v in def.accuracy :: any do
			if key == "firingError" or key == "scopedFiringError" then
				curve(id, key, v)
			else
				param(id, key, v)
			end
		end
		for key, v in def.recoil :: any do
			if key == "pitch" then
				curve(id, key, v)
			else
				param(id, key, v)
			end
		end
	end
	for key, v in WeaponConfig.Accuracy :: any do
		param("Accuracy", key, v)
	end
	check("every accuracy and recoil value is labelled and every curve ascends", ok)
end

do
	local pts = { { 1, 0 }, { 3, 2 }, { 5, 2.5 } }
	check("curves interpolate between points", near(Accuracy.curve(pts, 2), 1, 1e-12) and near(Accuracy.curve(pts, 4), 2.25, 1e-12))
	check("curves are flat beyond their ends", Accuracy.curve(pts, 0) == 0 and Accuracy.curve(pts, 99) == 2.5)
end

do
	local same = Accuracy.random(7, 3, 1) == Accuracy.random(7, 3, 1)
	local sum, lo, hi = 0, 1, 0
	local n = 20000
	for i = 1, n do
		local u = Accuracy.random(12345, i, 1)
		sum += u
		lo, hi = math.min(lo, u), math.max(hi, u)
	end
	check("per-shot random numbers repeat for the same seed and shot", same)
	check("per-shot random numbers are uniform in [0, 1)", lo >= 0 and hi < 1 and near(sum / n, 0.5, 0.01), string.format("mean %.4f, range %.4f..%.4f", sum / n, lo, hi))
	check("seeds and streams give different numbers", Accuracy.random(1, 5, 1) ~= Accuracy.random(2, 5, 1) and Accuracy.random(1, 5, 1) ~= Accuracy.random(1, 5, 2))
end

do
	local vandal = WeaponConfig.get("vandal")
	local acc = vandal.accuracy
	local interval = WeaponSim.fireInterval(vandal, 0)
	local f = function(e: number): number
		return Accuracy.recoveryFactor(acc, interval, e, DT)
	end
	check("a held trigger does not recover (up to one tick late)", f(interval + DT) == 1 and f(interval - DT) == 1)
	check("waiting the recovery time recovers the whole spray (Vandal 0.375 s)", f(0.375) == 0 and f(10) == 0 and f(math.huge) == 0)
	local monotonic = true
	local prev = 1
	for e = interval, 0.375, 0.005 do
		local v = f(e)
		monotonic = monotonic and v <= prev
		prev = v
	end
	check("recovery only ever goes one way", monotonic)
	local low = table.clone(acc)
	low.tapEfficiency = { value = 4, status = "estimate", source = "test" } :: any
	check("higher tap efficiency recovers faster when re-firing early", f(0.2) < Accuracy.recoveryFactor(low, interval, 0.2, DT))
end

do
	local s = newPlayer()
	local shot = run(s, B.Fire, 1)[1]
	check("first standing Vandal shot: bullet 1, cone 0.25 deg", shot ~= nil and shot.bullet == 1 and near(shot.cone.radius, 0.25, 1e-12) and shot.moveState == "still", if shot then string.format("bullet %.3f cone %.3f %s", shot.bullet, shot.cone.radius, shot.moveState) else "no shot")
	check("the bullet lands at its drawn offset inside the cone", shot ~= nil and shot.offset <= 0.25 and near(angle(shot.aim, shot.direction), shot.offset, 1e-3), if shot then string.format("%.4f vs %.4f", angle(shot.aim, shot.direction), shot.offset) else "")
end

do
	local s = newPlayer()
	local def = WeaponConfig.get("vandal")
	local shots = spray(s, 25)
	local wholeBullets, conesMatch, pitchMatch, noEarlyYaw, yawBounded, inside = true, true, true, true, true, true
	for i, shot in shots do
		wholeBullets = wholeBullets and shot.bullet == i
		conesMatch = conesMatch and near(shot.cone.radius, Accuracy.curve(def.accuracy.firingError.points, i), 1e-12)
		pitchMatch = pitchMatch and near(shot.recoilPitch, Accuracy.curve(def.recoil.pitch.points, i), 1e-12)
		if i <= def.recoil.swayStart.value then
			noEarlyYaw = noEarlyYaw and shot.recoilYaw == 0
		end
		yawBounded = yawBounded and math.abs(shot.recoilYaw) <= def.recoil.swayMax.value + 1e-9
		local centre = Accuracy.direction(shot.yaw, shot.pitch, shot.recoilPitch, shot.recoilYaw, 0, 0)
		inside = inside and angle(centre, shot.direction) <= shot.cone.radius + 1e-3
	end
	check("a held spray numbers its bullets 1..25 without recovering", #shots == 25 and wholeBullets)
	check("each bullet's cone follows the firing error curve", conesMatch)
	check("each bullet climbs by the recoil curve (Vandal bullet 9: 4.6 deg)", pitchMatch and near(shots[9].recoilPitch, 4.6, 1e-12))
	check("no sideways drift for the first 8 bullets, then it starts", noEarlyYaw and shots[9].recoilYaw ~= 0)
	check("sideways drift stays within its limit", yawBounded)
	check("every bullet lands inside its cone around the recoiled aim", inside)
end

do
	local def = WeaponConfig.get("vandal")
	local s = newPlayer()
	spray(s, 10)
	run(s, 0, ticksFor(def.accuracy.recoveryTime.value))
	local fresh = run(s, B.Fire, 1)[1]
	check("waiting out the recovery time makes the next shot a first shot", fresh ~= nil and fresh.bullet == 1 and fresh.recoilPitch == 0 and fresh.recoilYaw == 0 and near(fresh.cone.radius, 0.25, 1e-12))

	local p = newPlayer()
	spray(p, 10)
	run(p, 0, ticksFor(0.2))
	local partial = run(p, B.Fire, 1)[1]
	check("waiting part of it recovers part of the spray", partial ~= nil and partial.bullet > 1 and partial.bullet < 11, if partial then string.format("bullet %.3f", partial.bullet) else "no shot")
end

do
	local vandal = taps(newPlayer(), 0.2, 10)
	local phantomPlayer = newPlayer({ "phantom", "classic", "knife" })
	local phantom = taps(phantomPlayer, 0.2, 10)
	local v, ph = vandal[#vandal], phantom[#phantom]
	check("tapping every 0.2 s keeps the Vandal near a first shot", #vandal == 10 and v.bullet < 1.2, if v then string.format("bullet %.3f", v.bullet) else "")
	check("the Phantom (tap efficiency 4) accrues more than the Vandal (6) at the same taps", #phantom == 10 and ph.bullet > v.bullet, if ph then string.format("%.3f vs %.3f", ph.bullet, v.bullet) else "")
	local sheriff = newPlayer({ "vandal", "sheriff", "knife" }, 1)
	sheriff.weapons.equipped = 2
	local spam = spray(sheriff, 6)
	check("spamming the Sheriff at its fire rate builds up error", #spam == 6 and spam[6].bullet > 3 and spam[6].cone.radius > 2, string.format("bullet %.2f, cone %.2f", spam[6].bullet, spam[6].cone.radius))
end

do
	local function firstShot(buttons: number, settle: number, loadout: { string }?): WeaponSim.Shot?
		local s = newPlayer(loadout)
		run(s, buttons, settle)
		return run(s, buttons + B.Fire, 1)[1]
	end
	local runShot = firstShot(B.Forward, 256)
	local walkShot = firstShot(B.Forward + B.Walk, 256)
	local crouchMove = firstShot(B.Forward + B.Crouch, 256)
	local crouchStill = firstShot(B.Crouch, 64)
	check("running: run error 6 added (Patch 9.10)", runShot ~= nil and runShot.moveState == "run" and near(runShot.cone.radius, 6.25, 1e-9), if runShot then string.format("%s %.3f", runShot.moveState, runShot.cone.radius) else "")
	check("walking: walk error 3 added (Patch 9.10)", walkShot ~= nil and walkShot.moveState == "walk" and near(walkShot.cone.radius, 3.25, 1e-9), if walkShot then string.format("%s %.3f", walkShot.moveState, walkShot.cone.radius) else "")
	check("crouch-walking: 0.85 x first shot + 0.8 (Patch 2.02)", crouchMove ~= nil and crouchMove.moveState == "crouch" and near(crouchMove.cone.radius, 0.25 * 0.85 + 0.8, 1e-9), if crouchMove then string.format("%s %.3f", crouchMove.moveState, crouchMove.cone.radius) else "")
	check("crouched and still: first shot x 0.85", crouchStill ~= nil and crouchStill.moveState == "still" and near(crouchStill.cone.radius, 0.25 * 0.85, 1e-9), if crouchStill then string.format("%s %.4f", crouchStill.moveState, crouchStill.cone.radius) else "")

	local air = newPlayer()
	run(air, B.Jump, 10)
	local airShot = run(air, B.Fire, 1)[1]
	check("airborne: air error added", airShot ~= nil and airShot.moveState == "air" and near(airShot.cone.radius, 0.25 + 8, 1e-9), if airShot then string.format("%s %.3f", airShot.moveState, airShot.cone.radius) else "")

	-- Land, then shoot inside and after the 0.225 s landing penalty.
	local landed = newPlayer()
	run(landed, B.Jump, 1)
	for _ = 1, 400 do
		PlayerSim.step(landed, input(0), cfg, floor, DT)
		if landed.movement.grounded then
			break
		end
	end
	local landShot = run(landed, B.Fire, 1)[1]
	run(landed, 0, ticksFor(0.5))
	local later = run(landed, B.Fire, 1)[1]
	check("landing adds 7 deg for 0.225 s (Patch 1.09)", landShot ~= nil and near(landShot.cone.radius, 0.25 + 7, 1e-9), if landShot then string.format("%.3f", landShot.cone.radius) else "")
	check("and is gone after it", later ~= nil and near(later.cone.radius, 0.25, 1e-9), if later then string.format("%.3f", later.cone.radius) else "")
end

do
	-- Patch 3.0's "tag into accuracy": the hit slow (to 27.5% speed) and the
	-- deadzone (27.5%) meet exactly, and a slowed runner must stay inaccurate.
	-- Checked at the moment of the tag: the friction model then lets the speed
	-- sag below the cap over the next ticks, which the movement refinement
	-- (after this system) has to fix.
	local s = newPlayer()
	run(s, B.Forward, 256)
	PlayerSim.applyTag(s, cfg, WeaponConfig.Health.tagSpeedMultiplier.value, 1, DT)
	check("a runner slowed to the tag cap is not inside the deadzone", PlayerSim.moveState(s, B.Forward, cfg) == "run" and not PlayerSim.isAccurate(s, cfg))

	local stop = newPlayer()
	run(stop, B.Right, 256)
	local states: { [string]: boolean } = {}
	for _ = 1, 64 do
		PlayerSim.step(stop, input(0), cfg, floor, DT)
		states[PlayerSim.moveState(stop, 0, cfg)] = true
	end
	check("stopping from a run never passes through walk accuracy (Patch 0.50)", states.run == true and states.still == true and states.walk == nil)
end

do
	local s = newPlayer()
	run(s, B.AltFire, 1)
	run(s, 0, 1)
	local ads = run(s, B.Fire, 1)[1]
	check("ADS takes a flat 0.093 off the Vandal's first shot (0.25 -> 0.157)", ads ~= nil and near(ads.cone.radius, 0.157, 1e-9), if ads then string.format("%.4f", ads.cone.radius) else "")

	local c = newPlayer(nil, 1, B.Crouch)
	run(c, B.Crouch + B.AltFire, 1)
	run(c, B.Crouch, 1)
	local both = run(c, B.Crouch + B.Fire, 1)[1]
	check("crouched and ADS: the reduction, then the percentage", both ~= nil and near(both.cone.radius, 0.157 * 0.85, 1e-9), if both then string.format("%.4f", both.cone.radius) else "")
end

do
	local op = newPlayer({ "operator", "classic", "knife" })
	local hip = run(op, B.Fire, 1)[1]
	check("unscoped Operator: 5 deg cone", hip ~= nil and near(hip.cone.radius, 5, 1e-9))
	local scoped = newPlayer({ "operator", "classic", "knife" })
	run(scoped, B.AltFire, 1)
	run(scoped, 0, 1)
	local shot = run(scoped, B.Fire, 1)[1]
	check("scoped Operator: no first-shot spread, the bullet goes exactly where you aim", shot ~= nil and shot.cone.radius == 0 and angle(shot.aim, shot.direction) < 1e-4, if shot then string.format("%.6f deg", angle(shot.aim, shot.direction)) else "")
end

do
	-- Same seed, same bullets: crouching scales only the sideways output.
	local stand = spray(newPlayer(nil, 9), 14)
	local crouch = spray(newPlayer(nil, 9, B.Crouch), 14, B.Crouch)
	local a, b = stand[14], crouch[14]
	check("crouched and still: sideways recoil x 0.85 (Patch 0.50)", a ~= nil and b ~= nil and a.recoilYaw ~= 0 and near(b.recoilYaw, a.recoilYaw * 0.85, 1e-9), if a and b then string.format("%.4f vs %.4f", b.recoilYaw, a.recoilYaw) else "")
	check("crouching leaves the climb alone", a ~= nil and b ~= nil and a.recoilPitch == b.recoilPitch)

	local running = newPlayer(nil, 9)
	run(running, B.Forward, 256)
	local moving = spray(running, 6, B.Forward)
	check("running: vertical recoil x 1.8 (Patch 6.11)", moving[6] ~= nil and moving[6].moveState == "run" and near(moving[6].recoilPitch, stand[6].recoilPitch * 1.8, 1e-9), if moving[6] then string.format("%.3f vs %.3f", moving[6].recoilPitch, stand[6].recoilPitch) else "")
end

do
	local flips, sprays = 0, 0
	for seed = 1, 40 do
		local shots = spray(newPlayer(nil, seed), 25)
		local lastSign = 0
		for _, shot in shots do
			local sign = if shot.recoilYaw > 1e-9 then 1 elseif shot.recoilYaw < -1e-9 then -1 else 0
			if sign ~= 0 and lastSign ~= 0 and sign ~= lastSign then
				flips += 1
			end
			if sign ~= 0 then
				lastSign = sign
			end
		end
		sprays += 1
	end
	check("the sideways drift starts either way and crosses over", flips > 0, string.format("%d crossings in %d sprays", flips, sprays))

	local function directions(seed: number): { vector }
		local out = {}
		for _, shot in spray(newPlayer(nil, seed), 12) do
			table.insert(out, shot.direction)
		end
		return out
	end
	local a, b, c = directions(77), directions(77), directions(78)
	local same, differ = #a == 12, false
	for i = 1, #a do
		same = same and a[i] == b[i]
		differ = differ or a[i] ~= c[i]
	end
	check("the same seed fires the same bullets", same)
	check("another seed fires different ones", differ)
end

do
	local n = 4000
	local still, moving = 0, 0
	for i = 1, n do
		still += Accuracy.offset(5, i, 1, WeaponConfig.Accuracy.errorPower.value)
		moving += Accuracy.offset(5, i, 1, WeaponConfig.Accuracy.moveErrorPower.value)
	end
	-- E[u^k] = 1 / (k + 1) for a uniform u.
	check("standing shots are centre-biased (error power 1: mean 0.5 of the radius)", near(still / n, 0.5, 0.02), string.format("%.3f", still / n))
	check("moving shots spread nearly evenly (error power 0.6: mean 0.625)", near(moving / n, 1 / 1.6, 0.02), string.format("%.3f", moving / n))
end

do
	local base = Accuracy.aim(0, 0)
	local up = Accuracy.direction(0, 0, 10, 0, 0, 0)
	local right = Accuracy.direction(0, 0, 0, 10, 0, 0)
	check("recoil up raises the bullet", near(math.deg(math.asin(up.y)), 10, 1e-4))
	check("recoil right moves it to +X when facing -Z", right.x > 0 and near(angle(base, right), 10, 1e-4))
	local o = Accuracy.direction(0.3, -0.2, 2, 1, 1.5, 0.7)
	local centre = Accuracy.direction(0.3, -0.2, 2, 1, 0, 0)
	check("the cone offset is exactly its angle from the centre", near(angle(centre, o), 1.5, 1e-4))
	check("offset angle 0 is right and 90 degrees is up", Accuracy.direction(0, 0, 0, 0, 1, 0).x > 0 and Accuracy.direction(0, 0, 0, 0, 1, math.pi / 2).y > 0)
end

do
	local def = WeaponConfig.get("vandal")
	local s = newPlayer()
	spray(s, 8)
	local w = s.weapons
	local t = s.movement.tick * DT
	local interval = WeaponSim.fireInterval(def, 0)
	local nowBullet = Accuracy.next(def, w, t, DT, interval)
	local laterBullet = Accuracy.next(def, w, w.lastShotTime + def.accuracy.recoveryTime.value, DT, interval)
	check("right after a spray the next bullet carries on from it", nowBullet == 9, tostring(nowBullet))
	check("once recovered the view kick is gone (next bullet is a first shot)", laterBullet == 1)

	-- Switching draws the weapon again, which starts the spray over.
	spray(s, 6)
	PlayerSim.step(s, input(0, 2), cfg, floor, DT)
	check("switching weapons starts the spray over", w.sprayIndex == 0 and w.recoilYaw == 0 and w.swayDir == 0 and w.equipped == 2)
end

return nil
