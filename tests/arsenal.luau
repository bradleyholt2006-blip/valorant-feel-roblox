--!strict
-- The full arsenal (system 9): every gun's place in the buy menu, shotgun
-- pellets, the Classic's right click, zoomed bursts, the Odin's rising fire
-- rate, reloads that load a round at a time, the Outlaw's one-round reload
-- and double tap, recovery counted from when the gun can fire again, and
-- the ack carrying all of it.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local MovementSim = require("../src/shared/Movement/MovementSim")
local PlayerSim = require("../src/shared/PlayerSim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Volley = require("../src/shared/Combat/Volley")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()

local function input(buttons: number, slot: number, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

local function loadoutFor(id: string): { string }
	local def = WeaponConfig.get(id)
	return { if def.slot == 1 then id else "vandal", if def.slot == 2 then id else "classic", "knife" }
end

-- A player holding `id`, drawn and settled on the floor.
local function holding(id: string, seed: number?): PlayerSim.State
	local def = WeaponConfig.get(id)
	local s = PlayerSim.new(vector.create(0, 0.02, 0), loadoutFor(id), seed or 1)
	s.weapons.equipped = def.slot
	for _ = 1, math.max(40, math.ceil(def.equipTime.value / DT) + 2) do
		PlayerSim.step(s, input(0, def.slot), cfg, floor, DT)
	end
	return s
end

-- Steps `ticks` ticks with the same buttons; returns the rounds fired, each
-- a list of its bullets.
local function run(s: PlayerSim.State, buttons: number, ticks: number): { { WeaponSim.Shot } }
	local rounds = {}
	for _ = 1, ticks do
		local fired = PlayerSim.step(s, input(buttons, s.weapons.equipped), cfg, floor, DT)
		if fired then
			table.insert(rounds, fired)
		end
	end
	return rounds
end

local function ticksFor(seconds: number): number
	return math.ceil(seconds / DT) + 1
end

local function now(s: PlayerSim.State): number
	return s.movement.tick * DT
end

-- Presses alt-fire for a tick to zoom.
local function zoom(s: PlayerSim.State)
	run(s, B.AltFire, 1)
	run(s, 0, 1)
end

local function angle(a: vector, b: vector): number
	return math.deg(math.atan2(vector.magnitude(vector.cross(a, b)), vector.dot(a, b)))
end

H.section("Arsenal tests")

-- The buy menu's groups -------------------------------------------------------------

do
	local seen: { [string]: number } = {}
	local ok = true
	local slots = { sidearm = 2, melee = 3 }
	for _, group in WeaponConfig.Arsenal do
		for _, id in group.ids do
			local def = WeaponConfig.Defs[id]
			seen[id] = (seen[id] or 0) + 1
			if not def or def.category ~= group.category or def.slot ~= (slots[def.category] or 1) then
				ok = false
				print("    misplaced: " .. id)
			end
		end
	end
	local guns = 0
	for id, def in WeaponConfig.Defs do
		if def.category ~= "melee" and def.category ~= "spike" and def.category ~= "ultimate" and def.category ~= "ability" then
			guns += 1
			ok = ok and seen[id] == 1
		end
		ok = ok and WeaponConfig.IndexOf[id] ~= nil
	end
	check("the buy menu lists all 20 guns once each, in their slots", ok and guns == 20, tostring(guns))
	local ids = WeaponConfig.Ids
	check(
		"wire ids: the first six as they always were, then the rest, the spike, Blade Storm's knives, Curveball's flare, Hot Hands' fireball,"
			.. " Blaze's flame, the Healing Orb, the Slow Orb, the Barrier Orb, the Resurrection's orb, Dark Cover's, Paranoia's,"
			.. " Shrouded Step's, From the Shadows' map, then the Recon Bolt's bow",
		#ids == 35
			and ids[1] == "classic"
			and ids[2] == "knife"
			and ids[3] == "operator"
			and ids[4] == "phantom"
			and ids[5] == "sheriff"
			and ids[6] == "vandal"
			and ids[22] == "spike"
			and ids[23] == "kunai"
			and ids[24] == "flare"
			and ids[25] == "fireball"
			and ids[26] == "flamewall"
			and ids[27] == "healorb"
			and ids[28] == "iceorb"
			and ids[29] == "wallorb"
			and ids[30] == "revive"
			and ids[31] == "smokeorb"
			and ids[32] == "blindorb"
			and ids[33] == "stepmark"
			and ids[34] == "shadowmap"
			and ids[35] == "bow"
	)
	local quiet = {}
	for _, id in ids do
		if WeaponConfig.get(id).suppressed then
			table.insert(quiet, id)
		end
	end
	table.sort(quiet)
	check("the Ghost, Spectre and Phantom are the suppressed guns", table.concat(quiet, ",") == "ghost,phantom,spectre", table.concat(quiet, ","))
	check("prices: Classic free, Sheriff 800, Vandal and Phantom 2900, Operator 4700, Bandit 600 (Patch 12.00), Warden 2900 (Patch 13.06)",
		WeaponConfig.get("classic").price.value == 0
			and WeaponConfig.get("sheriff").price.value == 800
			and WeaponConfig.get("vandal").price.value == 2900
			and WeaponConfig.get("phantom").price.value == 2900
			and WeaponConfig.get("operator").price.value == 4700
			and WeaponConfig.get("bandit").price.value == 600
			and WeaponConfig.get("warden").price.value == 2900)
end

-- Run speed by weapon ------------------------------------------------------------------

do
	local expect = { bucky = 5.0625, judge = 5.0625, odin = 5.13, ares = 5.13, stinger = 5.7375, spectre = 5.7375, guardian = 5.40, marshal = 5.40, shorty = 5.40, frenzy = 5.7375 }
	local bad = {}
	for id, speed in expect do
		local s = holding(id)
		run(s, B.Forward, 256)
		local v = MovementSim.horizontalSpeed(s.movement)
		if not near(v, speed, 0.01) then
			table.insert(bad, string.format("%s %.3f", id, v))
		end
	end
	check("run speed by weapon: shotguns 5.06, machine guns 5.13, SMGs 5.74, the Guardian and Marshal 5.40", #bad == 0, table.concat(bad, ", "))
end

-- Shotgun pellets -------------------------------------------------------------------

do
	local s = holding("bucky", 5)
	local rounds = run(s, B.Fire, 1)
	local volley = rounds[1]
	local same, inside, distinct = true, true, true
	if volley then
		local first = volley[1]
		local centre = Accuracy.direction(first.yaw, first.pitch, first.recoilPitch, first.recoilYaw, 0, 0)
		for i, shot in volley do
			same = same and shot.volley == first.shotNumber and shot.pellet == i and shot.pellets == 15 and shot.recoilPitch == first.recoilPitch and shot.bullet == 1
			inside = inside and angle(centre, shot.direction) <= shot.cone.radius + 1e-3
			if i > 1 then
				distinct = distinct and shot.direction ~= volley[i - 1].direction
			end
		end
	end
	check("the Bucky fires 15 pellets a shot, one round, numbered as one volley", volley ~= nil and #volley == 15 and same and s.weapons.ammo[1] == 4, if volley then tostring(#volley) else "no shot")
	check("each pellet lands at its own place inside the same cone (3 deg)", volley ~= nil and inside and distinct and near(volley[1].cone.radius, 3, 1e-9))
	check("the next shot's pellets continue the shot numbers", s.weapons.shotCounter == 15)

	local judge = holding("judge")
	local held = run(judge, B.Fire, ticksFor(5 / 3.5))
	check("the Judge is automatic: 12 pellets a shot, its 5 shells held through", #held == 5 and #held[1] == 12, tostring(#held))
	local shorty = holding("shorty")
	local both = run(shorty, B.Fire, ticksFor(1))
	check("the Shorty is semi-automatic: 15 pellets, one shot per press", #both == 1 and #both[1] == 15)

	local bucky = WeaponConfig.get("bucky")
	check("a whole Bucky shot at 5 m does 15 x 17 = 255 to the body", WeaponConfig.shotDamage(bucky, "body", 5) == 255)
	check("so all its pellets kill 150 HP in one shot up close, and take two past 12 m", WeaponConfig.shotsToKill(bucky, "body", 5, 150) == 1 and WeaponConfig.shotsToKill(bucky, "body", 20, 150) == 2)
	check("a Shorty pellet does 11 to 7 m and 6 to 15 m (Patch 6.11)", WeaponConfig.damageAt(WeaponConfig.get("shorty"), "body", 7) == 11 and WeaponConfig.damageAt(WeaponConfig.get("shorty"), "body", 10) == 6)
end

do
	local totals = Volley.totals({
		{ target = 7, region = "body", damage = 17 },
		{ target = 9, region = "legs", damage = 14.45 },
		{ target = 7, region = "head", damage = 34 },
		{ target = 7, region = "legs", damage = 14.45 },
	})
	check(
		"a volley adds up by target, in the order each was first hit, and counts its best region",
		#totals == 2 and totals[1].target == 7 and near(totals[1].damage, 65.45, 1e-9) and totals[1].region == "head" and totals[1].pellets == 3 and totals[2].target == 9 and totals[2].region == "legs"
	)
end

-- The Classic's right click ------------------------------------------------------------

do
	local s = holding("classic")
	local clicks = run(s, B.AltFire, ticksFor(1))
	local click = clicks[1]
	check("the Classic's right click fires 3 bullets at once from 3 rounds", #clicks == 1 and click ~= nil and #click == 3 and click[1].mode == "alt" and s.weapons.ammo[2] == 9)
	check("in its own cone: 1.9 deg (the wiki)", click ~= nil and near(click[1].cone.radius, 1.9, 1e-9))
	check("each bullet does a left click's damage", WeaponConfig.damageAt(WeaponConfig.get("classic"), "body", 10) == 26)
	check("and it doesn't zoom", s.weapons.scoped == 0)

	local cadence = holding("classic")
	local times = {}
	for i = 1, ticksFor(3) do
		local w = cadence.weapons
		local ready = (cadence.movement.tick + 1) * DT >= w.nextFireTime - 1e-9 and not w.altHeld
		local fired = PlayerSim.step(cadence, input(if ready then B.AltFire else 0, 2), cfg, floor, DT)
		if fired then
			table.insert(times, fired[1].time)
		end
	end
	local gap = if #times > 1 then times[2] - times[1] else 0
	check("as fast as you can click, 2.22 a second", #times == 4 and gap >= 1 / 2.22 - 1e-9 and gap < 1 / 2.22 + DT, string.format("%d clicks, %.4f s apart", #times, gap))
	check("with 12 rounds that's four clicks, and an empty gun reloads", cadence.weapons.ammo[2] == 0 and WeaponSim.isReloading(cadence.weapons) or cadence.weapons.reserve[2] < 36)

	local short = holding("classic")
	short.weapons.ammo[2] = 2
	local last = run(short, B.AltFire, 1)[1]
	check("with 2 rounds left it fires 2 bullets", last ~= nil and #last == 2 and short.weapons.ammo[2] == 0)
end

-- Zoomed bursts ---------------------------------------------------------------------------

do
	local s = holding("bulldog")
	zoom(s)
	-- Bursts start 0.475 s apart, so 1.2 s holds three whole bursts and no fourth.
	local rounds = run(s, B.Fire, ticksFor(1.2))
	local inBurst, between = math.huge, 0
	for i = 2, #rounds do
		local gap = rounds[i][1].time - rounds[i - 1][1].time
		if i % 3 == 1 then
			between = math.max(between, rounds[i][1].time - rounds[i - 3][1].time)
		else
			inBurst = math.min(inBurst, gap)
		end
	end
	check("the Bulldog zoomed fires 3-round bursts while held", #rounds == 9 and rounds[1][1].mode == "zoom", tostring(#rounds))
	check("its rounds 1/13.33 s apart within a burst (to the tick)", inBurst >= 1 / 13.333 - DT and inBurst <= 1 / 13.333 + DT, string.format("%.4f", inBurst))
	check("and 2.105 bursts a second", between >= 1 / 2.105 - DT and between <= 1 / 2.105 + DT, string.format("%.4f", between))
	check("holding through bursts carries the spray on: the second burst starts at bullet 4", rounds[4] ~= nil and rounds[4][1].bullet == 4, if rounds[4] then tostring(rounds[4][1].bullet) else "")

	local tap = holding("bulldog")
	zoom(tap)
	local one = run(tap, B.Fire, 1)
	local rest = run(tap, 0, ticksFor(0.3))
	check("one click fires the whole burst", #one == 1 and #rest == 2 and tap.weapons.ammo[1] == 21)
	local cone = Accuracy.cone(WeaponConfig.mode(WeaponConfig.get("bulldog"), 1).accuracy, { moveState = "still", crouched = false, landing = false }, 1)
	check("a zoomed burst's first bullet: 0.1 deg (the wiki)", near(one[1][1].cone.radius, 0.1, 1e-9) and near(cone.radius, 0.1, 1e-9))
	-- Wait until the next burst is ready, then the burst recovery time.
	run(tap, 0, ticksFor(1 / 2.105 + 0.35))
	local fresh = run(tap, B.Fire, 1)
	check("waiting the burst recovery (0.35 s) once it can fire again starts a fresh burst", fresh[1] ~= nil and fresh[1][1].bullet == 1, if fresh[1] then tostring(fresh[1][1].bullet) else "")

	local cut = holding("bulldog")
	zoom(cut)
	run(cut, B.Fire, 1)
	run(cut, B.AltFire, 1)
	local after = run(cut, 0, ticksFor(0.3))
	check("unzooming stops a burst", #after == 0 and cut.weapons.burstLeft == 0 and cut.weapons.ammo[1] == 23)

	local stinger = holding("stinger")
	zoom(stinger)
	local s4 = run(stinger, B.Fire, ticksFor(0.4))
	check("the Stinger zoomed fires 4-round bursts at 18 a second", #s4 >= 4 and s4[2][1].time - s4[1][1].time <= 1 / 18 + DT and s4[2][1].time - s4[1][1].time >= 1 / 18 - DT, tostring(#s4))
	local hip = holding("bulldog")
	local auto = run(hip, B.Fire, ticksFor(1))
	check("from the hip the Bulldog is a plain automatic, 10 a second", #auto == 10 or #auto == 11, tostring(#auto))
end

-- The Odin's rising fire rate -------------------------------------------------------------

do
	local s = holding("odin")
	local rounds = run(s, B.Fire, ticksFor(2))
	local first = rounds[2][1].time - rounds[1][1].time
	local late = rounds[#rounds][1].time - rounds[#rounds - 1][1].time
	check("the Odin starts at 12 a second", first >= 1 / 12 - DT and first <= 1 / 12 + DT, string.format("%.4f", first))
	check("and holding the trigger for its spin-up time takes it to 15.6", late >= 1 / 15.6 - DT and late <= 1 / 15.6 + DT and s.weapons.spin == 1, string.format("%.4f", late))
	run(s, 0, 1)
	check("letting go spins it down at once", s.weapons.spin == 0)
	local zoomed = holding("odin")
	zoom(zoomed)
	local z = run(zoomed, B.Fire, ticksFor(0.5))
	local gap = z[2][1].time - z[1][1].time
	check("zoomed it fires at 15.6 straight away", gap >= 1 / 15.6 - DT and gap <= 1 / 15.6 + DT, string.format("%.4f", gap))
	local ares = holding("ares")
	local a = run(ares, B.Fire, ticksFor(2))
	local aLate = a[#a][1].time - a[#a - 1][1].time
	check("the Ares has no spin-up any more (13 a second throughout)", aLate >= 1 / 13 - DT and aLate <= 1 / 13 + DT and ares.weapons.spin == 0, string.format("%.4f", aLate))
end

-- Reloads that load a round at a time -------------------------------------------------------

do
	local s = holding("bucky")
	local w = s.weapons
	-- Two shots, then reload.
	run(s, B.Fire, 1)
	run(s, 0, ticksFor(1 / 1.1))
	run(s, B.Fire, 1)
	run(s, 0, 2)
	run(s, B.Reload, 1)
	local start = now(s) - DT
	local ammo = { w.ammo[1] }
	local doneAt = nil
	for _ = 1, ticksFor(2) do
		run(s, 0, 1)
		if w.ammo[1] ~= ammo[#ammo] then
			table.insert(ammo, w.ammo[1])
		end
		if not doneAt and not WeaponSim.isReloading(w) then
			doneAt = now(s)
		end
	end
	check("the Bucky reloads a shell at a time: 3, 4, 5", table.concat(ammo, ",") == "3,4,5", table.concat(ammo, ","))
	check("0.5 s a shell, so two shells take 1 s", doneAt ~= nil and near(doneAt - start, 1.0, DT + 1e-9), if doneAt then string.format("%.4f", doneAt - start) else "")
	check("and the reserve gives up two shells", w.reserve[1] == 8)

	local empty = holding("bucky")
	local ew = empty.weapons
	ew.ammo[1] = 0
	run(empty, B.Reload, 1)
	local t0 = now(empty) - DT
	run(empty, 0, ticksFor(2.5))
	check("a full reload from empty takes 5 x 0.5 = 2.5 s (the wiki's full reload)", ew.ammo[1] == 5 and not WeaponSim.isReloading(ew) and near(now(empty) - t0, 2.5 + 2 * DT, 2 * DT))

	local cut = holding("bucky")
	local cw = cut.weapons
	cw.ammo[1] = 0
	run(cut, B.Reload, 1)
	run(cut, 0, ticksFor(1.1))
	local loaded = cw.ammo[1]
	local fired = run(cut, B.Fire, 1)
	check("firing during it stops the reload and keeps the shells already in", loaded == 2 and #fired == 1 and cw.ammo[1] == 1 and not WeaponSim.isReloading(cw), string.format("%d loaded", loaded))

	local short = holding("marshal")
	local sw = short.weapons
	sw.ammo[1] = 1
	sw.reserve[1] = 2
	run(short, B.Reload, 1)
	run(short, 0, ticksFor(1.5))
	check("the Marshal loads a round at a time too, and stops when the reserve runs out", sw.ammo[1] == 3 and sw.reserve[1] == 0 and not WeaponSim.isReloading(sw))
	check("a gun that reloads a magazine still takes its whole reload", WeaponSim.reloadStep(WeaponConfig.get("vandal"), 10, 50) == 2.5)
end

-- The Outlaw ---------------------------------------------------------------------------------

do
	local def = WeaponConfig.get("outlaw")
	check("the Outlaw reloads one round in 2.3 s and two in 3.8 s (the wiki)", WeaponSim.reloadStep(def, 1, 10) == 2.3 and WeaponSim.reloadStep(def, 0, 10) == 3.8 and WeaponSim.reloadStep(def, 0, 1) == 2.3)

	local s = holding("outlaw")
	zoom(s)
	local first = run(s, B.Fire, 1)[1]
	-- The double tap: the second shot as soon as it can fire.
	local second: { WeaponSim.Shot }? = nil
	for _ = 1, ticksFor(1) do
		local w = s.weapons
		local ready = (s.movement.tick + 1) * DT >= w.nextFireTime - 1e-9
		local fired = PlayerSim.step(s, input(if ready and not w.fireHeld then B.Fire else 0, 1), cfg, floor, DT)
		if fired then
			second = fired
			break
		end
	end
	check("scoped, its first shot goes exactly where you aim", first ~= nil and first[1].cone.radius == 0 and first[1].recoilPitch == 0)
	check(
		"a double tap's second shot has 2.25 spread and 4.0 recoil (Patch 13.01)",
		second ~= nil and second[1].bullet == 2 and near(second[1].cone.radius, 2.25, 1e-9) and near(second[1].recoilPitch, 4.0, 1e-9),
		if second then string.format("bullet %.2f cone %.2f up %.2f", second[1].bullet, second[1].cone.radius, second[1].recoilPitch) else "no shot"
	)

	local patient = holding("outlaw")
	patient.weapons.reserve[1] = 10
	zoom(patient)
	run(patient, B.Fire, 1)
	run(patient, 0, ticksFor(1 / 2.75 + 0.15))
	local calm = run(patient, B.Fire, 1)[1]
	check("waiting its 0.15 s recovery once it can fire again makes the second shot a first shot", calm ~= nil and calm[1].bullet == 1 and calm[1].cone.radius == 0, if calm then string.format("bullet %.3f", calm[1].bullet) else "no shot")
end

-- Zooms and scopes ---------------------------------------------------------------------------

do
	local sheriff = holding("sheriff")
	zoom(sheriff)
	check("the Sheriff has no zoom", sheriff.weapons.scoped == 0)
	local warden = holding("warden")
	zoom(warden)
	local wdef = WeaponConfig.get("warden")
	check("the Warden has a 2x scope (Patch 13.06)", warden.weapons.scoped == 1 and wdef.ads ~= nil and (wdef.ads :: any).zoom[1] == 2)
	local guardian = holding("guardian")
	zoom(guardian)
	local shot = run(guardian, B.Fire, 1)[1]
	check("the Guardian zoomed: a first shot with no spread (the wiki)", shot ~= nil and shot[1].cone.radius == 0)
	local marshal = holding("marshal")
	zoom(marshal)
	check("the Marshal's scope: 3.5x, 90% speed", marshal.weapons.scoped == 1 and near(PlayerSim.maxSpeed(marshal, cfg), 6.75 * 0.8 * 0.9, 1e-9))
	local view = WeaponConfig.mode(WeaponConfig.get("operator"), 1).recoil.viewKick
	check("a sniper's shot kicks the view though its bullets don't climb", view ~= nil and view.value > 0 and WeaponConfig.get("operator").recoil.pitch.points[1][2] == 0)
end

-- Recovery from readiness, against a fast gun --------------------------------------------------

do
	-- A fast gun's recovery outlasts its cooldown: tapping the Vandal 0.1 s
	-- after it's ready keeps a fifth of the spray.
	local acc = WeaponConfig.get("vandal").accuracy
	local left = Accuracy.recoveryFactor(acc, 0.1, DT)
	check("Vandal: 0.1 s after it can fire again, (1 - 0.1/0.375)^6 of the spray is left", near(left, (1 - 0.1 / 0.375) ^ 6, 1 / 65536), string.format("%.4f", left))
end

-- The ack carries a burst and a spin -------------------------------------------------------------

do
	local function resumes(id: string, zoomIn: boolean, ticks: number): boolean
		local s = holding(id, 99)
		if zoomIn then
			zoom(s)
		end
		run(s, B.Fire, ticks)
		local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(1, s))
		local a, b = s, decoded :: PlayerSim.State
		local same = a.weapons.burstLeft == b.weapons.burstLeft and a.weapons.burstNext == b.weapons.burstNext and a.weapons.spin == b.weapons.spin
		for i = 1, 300 do
			local buttons = if i < 200 then B.Fire else 0
			local ra = PlayerSim.step(a, input(buttons, a.weapons.equipped), cfg, floor, DT)
			local rb = PlayerSim.step(b, input(buttons, b.weapons.equipped), cfg, floor, DT)
			if (ra == nil) ~= (rb == nil) or (ra and rb and (#ra ~= #rb or ra[1].direction ~= rb[1].direction or ra[1].time ~= rb[1].time)) then
				same = false
			end
		end
		return same and a.weapons.shotCounter == b.weapons.shotCounter
	end
	check("an ack taken mid-burst resumes the burst exactly", resumes("bulldog", true, 3))
	check("an ack taken mid-spin resumes the Odin's rate exactly", resumes("odin", false, 60))
	check("an ack taken mid-reload of a shotgun resumes it exactly", resumes("bucky", false, 1))
end

-- Determinism with pellets -------------------------------------------------------------------------

do
	local function pattern(seed: number): { vector }
		local out = {}
		for _, shot in run(holding("judge", seed), B.Fire, 1)[1] or {} do
			table.insert(out, shot.direction)
		end
		return out
	end
	local a, b, c = pattern(4), pattern(4), pattern(5)
	local same, differ = #a == 12, false
	for i = 1, #a do
		same = same and a[i] == b[i]
		differ = differ or a[i] ~= c[i]
	end
	check("the same seed fires the same pellet pattern, another seed another", same and differ)
end

-- Every gun's sounds -----------------------------------------------------------------------------

do
	local missing = {}
	for _, id in WeaponConfig.Ids do
		local sounds = SoundConfig.Weapons[id]
		local def = WeaponConfig.get(id)
		if not sounds then
			table.insert(missing, id)
		elseif def.fireMode ~= "none" and not def.ability and not (sounds.shot and sounds.pitch and sounds.pitch > 0) then
			table.insert(missing, id .. " shot")
		elseif def.suppressed ~= (sounds.curve == "suppressed") then
			table.insert(missing, id .. " curve")
		end
	end
	check("every gun has a shot sound and pitch, and the suppressed ones carry less far", #missing == 0, table.concat(missing, ", "))
	local perRound = SoundConfig.Weapons.bucky.reload :: { SoundConfig.Cue }
	check("a gun that loads a round at a time sounds each round going in", #perRound == 1 and SoundConfig.Sounds[perRound[1].sound] ~= nil)
end

return nil
