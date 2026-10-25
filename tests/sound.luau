--!strict
-- Sound (system 8): footsteps, jumps and landings from a simulated player,
-- the distance curves, the filters for walls and distance, how much level
-- lies between two points, and every number labelled.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local MovementSim = require("../src/shared/Movement/MovementSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local SoundMath = require("../src/shared/Audio/SoundMath")
local StepTracker = require("../src/shared/Audio/StepTracker")
local FakeWorld = require("./FakeWorld")
local FakeLevel = require("./FakeLevel")
local H = require("./Harness")

local check, near = H.check, H.near

local B = MovementSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local F, L, C = SoundConfig.Footsteps, SoundConfig.Landing, SoundConfig.Curves

local function speedOf(id: string): number
	return cfg.baseRunSpeed * WeaponConfig.get(id).moveMultiplier.value
end
local RIFLE = speedOf("vandal")

type Run = { events: { StepTracker.Event }, state: MovementSim.State }

-- Runs a player in `world` for `seconds`, pressing `buttons(t, state)` each
-- tick, and gives the sound events its ticks make. Settles on the floor first.
local function run(world: any, seconds: number, buttons: (number, MovementSim.State) -> number, start: vector?, speed: number?): Run
	local s = MovementSim.newState(start or vector.create(0, 0.02, 0))
	local function input(b: number): MovementSim.Input
		return { seq = 0, buttons = b, yaw = 0, pitch = 0, slot = 1, viewTime = 0 }
	end
	for _ = 1, 16 do
		MovementSim.step(s, input(0), cfg, speed or RIFLE, world, DT)
	end
	local tracker = StepTracker.new()
	local events: { StepTracker.Event } = {}
	local t = 0
	StepTracker.push(tracker, { time = t, position = s.position, grounded = s.grounded, quiet = false })
	for _ = 1, math.floor(seconds / DT + 0.5) do
		t += DT
		local b = buttons(t, s)
		MovementSim.step(s, input(b), cfg, speed or RIFLE, world, DT)
		local sample = { time = t, position = s.position, grounded = s.grounded, quiet = StepTracker.isQuiet(b, s.crouched) }
		for _, e in StepTracker.push(tracker, sample) do
			table.insert(events, e)
		end
	end
	return { events = events, state = s }
end

local function only(events: { StepTracker.Event }, kind: StepTracker.Kind): { StepTracker.Event }
	local out = {}
	for _, e in events do
		if e.kind == kind then
			table.insert(out, e)
		end
	end
	return out
end

local function hold(b: number): (number, MovementSim.State) -> number
	return function()
		return b
	end
end

local floor = FakeWorld.new():addFloor()

H.section("Sound report")

do
	local points = C.footstep.points
	local parts = {}
	for _, d in { 0, 5, 10, 15, 19, 19.5, 20, 25 } do
		table.insert(parts, string.format("%g m %.2f", d, SoundMath.curveAt(points, d)))
	end
	print(string.format("footsteps heard within %.0f m (%s): %s", F.radius.value, F.radius.status, table.concat(parts, ", ")))
	for _, id in { "knife", "classic", "vandal", "operator" } do
		local r = run(floor, 3, hold(B.Forward), nil, speedOf(id))
		local steps = only(r.events, "step")
		local last = steps[#steps]
		local before = steps[#steps - 1]
		print(string.format(
			"  %-8s running %.2f m/s: a step every %.2f s, the first after %.2f s",
			id,
			speedOf(id),
			if last and before then last.time - before.time else 0,
			if steps[1] then steps[1].time else 0
		))
	end
	local occ = {}
	for _, t in { 0, 0.1, 0.3, 1, 2, 4 } do
		local cutoff, gain = SoundMath.occlusion(t)
		table.insert(occ, string.format("%g m %.0f Hz x%.2f", t, cutoff, gain))
	end
	print("through walls: " .. table.concat(occ, ", "))
	local air = {}
	for _, d in { 10, 30, 80, 150 } do
		table.insert(air, string.format("%g m %.0f Hz", d, SoundMath.airCutoff(d)))
	end
	print("gunshots in the air: " .. table.concat(air, ", "))
end

H.section("Sound tests")

-- Footsteps ----------------------------------------------------------------------

do
	local r = run(floor, 3, hold(B.Forward))
	local steps = only(r.events, "step")
	local loud = true
	for _, e in steps do
		loud = loud and e.loud
	end
	check("running makes footsteps, and every one is heard", #steps >= 8 and loud, tostring(#steps))
	local gap = steps[#steps].time - steps[#steps - 1].time
	check("at full rifle speed a step comes every stride", near(gap, F.stride.value / RIFLE, DT * 1.5), string.format("%.3f s", gap))
	check(
		"the first step comes soon after setting off (within 0.3 s)",
		steps[1].time <= 0.3,
		string.format("%.3f s", steps[1].time)
	)
	check("no jumps or landings while running on the flat", #only(r.events, "jump") == 0 and #only(r.events, "land") == 0)
end

do
	local walk = run(floor, 3, hold(B.Forward + B.Walk))
	local crouch = run(floor, 3, hold(B.Forward + B.Crouch))
	local function silent(events: { StepTracker.Event }): boolean
		for _, e in events do
			if e.loud then
				return false
			end
		end
		return true
	end
	check("walking makes no footstep anyone hears", #only(walk.events, "step") > 0 and silent(walk.events))
	check("nor does crouching", #only(crouch.events, "step") > 0 and silent(crouch.events))
	check("standing still makes no steps", #run(floor, 2, hold(0)).events == 0)
	-- Shift pressed mid-run: silent from that tick, while still moving fast.
	local mixed = run(floor, 3, function(t)
		return if t < 1.5 then B.Forward else B.Forward + B.Walk
	end)
	local ok = true
	for _, e in only(mixed.events, "step") do
		ok = ok and e.loud == (e.time < 1.5)
	end
	check("pressing walk mid-run silences the very next steps", ok)
end

-- Jumps and landings ------------------------------------------------------------

do
	local r = run(floor, 1.5, function(t)
		return if t < 0.05 then B.Jump else 0
	end)
	local jumps, lands = only(r.events, "jump"), only(r.events, "land")
	check("a jump on the spot is one jump and one landing", #jumps == 1 and #lands == 1)
	check("the jump itself is never heard", jumps[1] ~= nil and not jumps[1].loud)
	check("landing back on the same level is heard", lands[1] ~= nil and lands[1].loud)
end

do
	-- A crate 0.6 m high, 3 m ahead and 3 m deep: run at it, jump a metre
	-- short of it, and stop on top.
	local crate = FakeWorld.new():addFloor():addBox(vector.create(-2, 0, -6), vector.create(2, 0.6, -3))
	local jumped = false
	local r = run(crate, 1.6, function(_, s)
		if s.position.z < -4.5 then
			return 0
		end
		local jump = not jumped and s.position.z < -2
		jumped = jumped or jump
		return B.Forward + (if jump then B.Jump else 0)
	end)
	local lands = only(r.events, "land")
	check("jumping up onto a crate lands on it", #lands == 1 and r.state.position.y > 0.55, string.format("y %.2f", r.state.position.y))
	check("and that landing is silent", lands[1] ~= nil and not lands[1].loud)
	-- Then off the far side, down 0.6 m: a fall onto lower ground is heard.
	local off = run(crate, 2, hold(B.Forward), vector.create(0, 0.62, -5))
	local down = only(off.events, "land")
	check("running off it onto the floor is heard", #down == 1 and down[1].loud)
end

do
	local loudFlat = StepTracker.landingIsLoud(cfg.jumpApexHeight, 0)
	local stepUp = StepTracker.landingIsLoud(cfg.jumpApexHeight - 0.2, 0.2)
	local tinyDrop = StepTracker.landingIsLoud(0.2, -0.2)
	check("the landing rule: flat jump heard, onto a 20 cm ledge not, a 20 cm drop not", loudFlat and not stepUp and not tinyDrop)
end

do
	-- A respawn or a correction moves the player far in one sample: no step.
	local t = StepTracker.new()
	local events = {}
	local function push(time: number, x: number, grounded: boolean)
		for _, e in StepTracker.push(t, { time = time, position = vector.create(x, 0, 0), grounded = grounded, quiet = false }) do
			table.insert(events, e)
		end
	end
	push(0, 0, true)
	push(0.1, 0.5, true)
	push(0.2, 30, true)
	push(0.3, 30.5, true)
	check("a teleport is not walked: no step for it", #events == 0, tostring(#events))
	StepTracker.reset(t)
	push(1, 100, true)
	push(1.1, 100.5, true)
	check("after a reset the first sample only starts it over", #events == 0, tostring(#events))
end

do
	-- Started over in the air: touching down is settling, unless it fell far.
	local t = StepTracker.new()
	local function lands(y: number): number
		StepTracker.reset(t)
		StepTracker.push(t, { time = 0, position = vector.create(0, y, 0), grounded = false, quiet = false })
		StepTracker.push(t, { time = 0.1, position = vector.create(0, y / 2, 0), grounded = false, quiet = false })
		return #StepTracker.push(t, { time = 0.2, position = vector.zero, grounded = true, quiet = false })
	end
	check("starting over 5 cm up and settling is not a landing", lands(0.05) == 0)
	check("starting over high up and falling is one", lands(L.minFall.value + 0.1) == 1)
	StepTracker.push(t, { time = 0.3, position = vector.zero, grounded = false, quiet = false })
	StepTracker.push(t, { time = 0.4, position = vector.create(0, 0.5, 0), grounded = false, quiet = false })
	local after = StepTracker.push(t, { time = 0.5, position = vector.zero, grounded = true, quiet = false })
	check("and the next landing counts as usual", #after == 1 and after[1].loud)

	-- A new life on the real movement code, at the spawn's 5 cm up
	-- (PlayerSimServer), settles onto the floor without a sound.
	local s = MovementSim.newState(vector.create(0, 0.05, 0))
	local tracker = StepTracker.new()
	local events = {}
	local time = 0
	for _ = 1, 40 do
		for _, e in StepTracker.push(tracker, { time = time, position = s.position, grounded = s.grounded, quiet = false }) do
			table.insert(events, e)
		end
		MovementSim.step(s, { seq = 0, buttons = 0, yaw = 0, pitch = 0, slot = 1, viewTime = 0 }, cfg, RIFLE, floor, DT)
		time += DT
	end
	check("a new life settles onto the floor without a landing", s.grounded and #events == 0, tostring(#events))
end

-- Curves ---------------------------------------------------------------------------

do
	local ok = true
	for name, curve in C do
		local pts = curve.points
		local falling = true
		for i = 2, #pts do
			falling = falling and pts[i][1] > pts[i - 1][1] and pts[i][2] <= pts[i - 1][2]
		end
		local radius = SoundMath.radius(pts)
		ok = ok and falling and pts[1][1] == 0 and pts[1][2] == 1 and radius ~= nil and SoundMath.curveAt(pts, (radius :: number) + 1) == 0
		if not ok then
			print("    " .. name .. " is not a falling curve from full volume to silence")
			break
		end
	end
	check("every distance curve starts at full volume, falls and ends in silence", ok)
	local fp = C.footstep.points
	check("footsteps are flat: still half volume a metre from the edge", SoundMath.curveAt(fp, F.radius.value - 1) >= 0.5)
	check("the footstep curve goes silent at the footstep radius", SoundMath.radius(fp) == F.radius.value)
	check("a gunshot carries further than a suppressed one, which carries further than footsteps", (SoundMath.radius(C.gunshot.points) :: number) > (SoundMath.radius(C.suppressed.points) :: number) and (SoundMath.radius(C.suppressed.points) :: number) > F.radius.value)
	local scaled = SoundMath.scaled(fp, 30)
	check("a curve stretched to 30 m goes silent at 30 m with the same shape", SoundMath.radius(scaled) == 30 and near(SoundMath.curveAt(scaled, 15), SoundMath.curveAt(fp, 10), 1e-9))
	local studs = SoundMath.studsCurve(fp, 1 / 0.28)
	check("the curve in studs puts the radius at 20 m in studs", studs[20 / 0.28] == 0 and studs[0] == 1)
end

-- Filters ---------------------------------------------------------------------------

do
	local open, gain0 = SoundMath.occlusion(0)
	check("nothing in the way leaves a sound open", open == SoundConfig.OPEN_CUTOFF and gain0 == 1)
	local thin, gThin = SoundMath.occlusion(0.05)
	local mid, gMid = SoundMath.occlusion(0.6)
	local thick, gThick = SoundMath.occlusion(5)
	local O = SoundConfig.Occlusion
	check("a thin wall muffles to the thin cutoff", near(thin, O.thinCutoff.value, 1e-6) and near(gThin, O.thinGain.value, 1e-9))
	check("thicker walls muffle more, down to the thick cutoff", mid < thin and thick < mid and near(thick, O.thickCutoff.value, 1e-6) and gMid < gThin and near(gThick, O.thickGain.value, 1e-9))
	check(
		"the air dulls far gunshots only",
		SoundMath.airCutoff(5) == SoundConfig.OPEN_CUTOFF
			and SoundMath.airCutoff(50) < SoundConfig.OPEN_CUTOFF
			and near(SoundMath.airCutoff(500), SoundConfig.Air.farCutoff.value, 1e-6)
	)
end

do
	local level = FakeLevel.new()
	level:wall("medium", 4, 0.3)
	level:wall("hard", 8, 0.5)
	local from = vector.create(0, 1, 0)
	local t0, n0 = SoundMath.blockage(level, from, vector.create(0, 1, -3), 4)
	local t1, n1 = SoundMath.blockage(level, from, vector.create(0, 1, -6), 4)
	local t2, n2 = SoundMath.blockage(level, from, vector.create(0, 1, -12), 4)
	local t3, n3 = SoundMath.blockage(level, from, vector.create(0, 1, -8.2), 4)
	check("no wall between two points: nothing in the way", t0 == 0 and n0 == 0)
	check("one 0.3 m wall between: 0.3 m in the way", near(t1, 0.3, 1e-6) and n1 == 1, string.format("%.3f", t1))
	check("two walls between: their thicknesses add up", near(t2, 0.8, 1e-6) and n2 == 2, string.format("%.3f", t2))
	check("a sound inside a wall counts the wall up to it", near(t3, 0.5, 1e-6) and n3 == 2, string.format("%.3f", t3))
	check("the cast stops after the most pieces it may count", select(2, SoundMath.blockage(level, from, vector.create(0, 1, -12), 1)) == 1)
end

do
	check("each kill of a life raises the kill sound, up to the fifth", SoundMath.killPitch(1) == 1 and SoundMath.killPitch(2) > 1 and SoundMath.killPitch(5) == SoundMath.killPitch(9))
end

do
	local gap = SoundConfig.RedrawGap.value
	check("a switch always makes its draw sound, however soon", SoundMath.drawHeard(true, 0))
	check("the slot in hand drawn again just after a draw is the same draw", not SoundMath.drawHeard(false, 0.02))
	check("a weapon given into the hand later is drawn with a sound", SoundMath.drawHeard(false, gap) and SoundMath.drawHeard(false, math.huge))
end

do
	local level, most = SoundConfig.Level.value, SoundConfig.MaxGain.value
	check(
		"a loud take is turned down to the level and a quiet one up, by no more than the most gain",
		near(SoundMath.assetGain(1) * 1, level, 1e-9) and near(SoundMath.assetGain(0.25) * 0.25, level, 1e-9) and SoundMath.assetGain(0.01) == most
	)
end

do
	local cues = SoundConfig.Weapons.vandal.reload :: { SoundConfig.Cue }
	local length = WeaponConfig.get("vandal").reloadTime.value
	local none, n0 = SoundMath.cuesDue(cues, 1, 0, length)
	local first, n1 = SoundMath.cuesDue(cues, 1, cues[1].at * length, length)
	local rest, n2 = SoundMath.cuesDue(cues, n1, length, length)
	local again = SoundMath.cuesDue(cues, n2, length + 1, length)
	check("a reload's first part waits for its time", #none == 0 and n0 == 1)
	check("each part plays once, when its time comes", #first == 1 and first[1] == cues[1].sound and #rest == #cues - 1 and #again == 0)
end

-- Labels and sounds ------------------------------------------------------------------

do
	local statuses = { confirmed = true, community = true, estimate = true, measured = true }
	local ok = true
	local function param(name: string, p: any)
		if typeof(p) == "table" and p.status ~= nil then
			ok = ok and statuses[p.status] == true and typeof(p.source) == "string" and #p.source > 0
			if not ok then
				print("    unlabelled: " .. name)
			end
		end
	end
	for _, group in { "Footsteps", "Landing", "Occlusion", "Air" } do
		for name, p in (SoundConfig :: any)[group] do
			param(group .. "." .. name, p)
		end
	end
	for name, curve in C do
		param("Curves." .. name, curve)
	end
	param("KillPitchStep", SoundConfig.KillPitchStep)
	param("RedrawGap", SoundConfig.RedrawGap)
	param("Level", SoundConfig.Level)
	param("MaxGain", SoundConfig.MaxGain)
	check("every sound number carries a status and a source", ok)

	local missing = {}
	for id, sounds in SoundConfig.Weapons do
		local names = { sounds.shot, sounds.draw }
		local last = 0
		for _, c in sounds.reload or {} do
			table.insert(names, c.sound)
			if c.at < last or c.at >= 1 then
				table.insert(missing, id .. ": reload part " .. c.sound .. " out of order or past the end")
			end
			last = c.at
		end
		for _, name in names do
			if name and not SoundConfig.Sounds[name] then
				table.insert(missing, id .. ": " .. name)
			end
		end
		if not (C :: any)[sounds.curve] then
			table.insert(missing, id .. ": curve " .. sounds.curve)
		end
		if (id == "knife") ~= (sounds.reload == nil) then
			table.insert(missing, id .. ": " .. (if sounds.reload then "a knife doesn't reload" else "no reload"))
		end
	end
	for _, id in WeaponConfig.Ids do
		if not SoundConfig.Weapons[id] then
			table.insert(missing, id .. " has no sounds")
		end
	end
	check("every weapon's sounds and curve exist", #missing == 0, table.concat(missing, ", "))

	local bad = {}
	for name, sound in SoundConfig.Sounds do
		local fine = #sound.assets > 0 and sound.voices >= 1 and sound.volume > 0 and sound.pitchJitter >= 0 and sound.pitchJitter < 0.2
		for _, a in sound.assets do
			fine = fine and a.id > 0 and a.id % 1 == 0 and #a.title > 0 and a.peak > 0 and a.peak <= 1 and a.start >= 0
		end
		if not fine then
			table.insert(bad, name)
		end
	end
	table.sort(bad)
	check("every sound has a library asset with its measured peak, voices and a volume", #bad == 0, table.concat(bad, ", "))
end

return nil
