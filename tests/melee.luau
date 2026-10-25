--!strict
-- The knife (system 10): when it swings, what a swing catches and what it
-- does.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local Health = require("../src/shared/Combat/Health")
local Melee = require("../src/shared/Combat/Melee")
local LagCompensation = require("../src/shared/Combat/LagCompensation")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local FakeLevel = require("./FakeLevel")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local knife = WeaponConfig.get("knife")
local melee = knife.melee :: WeaponConfig.MeleeDef
local slash, stab = melee.slash, melee.stab

local function input(buttons: number, slot: number, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player settled on the floor with the Vandal, the Classic and the knife,
-- holding the Vandal.
local function newPlayer(): PlayerSim.State
	local s = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife" })
	for _ = 1, 40 do
		PlayerSim.step(s, input(0, 1), cfg, floor, DT)
	end
	return s
end

local function now(s: PlayerSim.State): number
	return s.movement.tick * DT
end

-- Steps `ticks` ticks with the same buttons and slot; returns the swings
-- and the bullets.
local function run(s: PlayerSim.State, buttons: number, ticks: number, slot: number): ({ WeaponSim.Swing }, number)
	local swings, bullets = {}, 0
	for _ = 1, ticks do
		local shots, swing = PlayerSim.step(s, input(buttons, slot), cfg, floor, DT)
		bullets += if shots then #shots else 0
		if swing then
			table.insert(swings, swing)
		end
	end
	return swings, bullets
end

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

H.section("Knife tests")

-- The numbers --------------------------------------------------------------------

do
	local ok = true
	for _, attack in { slash, stab } do
		for _, key in { "rate", "reach", "radius", "front", "back" } do
			local param = (attack :: any)[key]
			ok = ok and type(param) == "table" and type(param.value) == "number" and type(param.status) == "string" and param.source ~= ""
		end
	end
	ok = ok and melee.comboReset.status ~= nil and melee.comboReset.source ~= ""
	check("every knife number carries a status and a source", ok)
	check("the slash comes twice a second and the stab 0.8 times (community)", slash.rate.value == 2 and stab.rate.value == 0.8)
	check(
		"a slash does 50 from in front and 100 from behind, a stab 75 and 150",
		slash.front.value == 50 and slash.back.value == 100 and stab.front.value == 75 and stab.back.value == 150
	)
	check(
		"the slash reaches further and wider than the stab, as Patch 4.01 has them",
		slash.reach.value > stab.reach.value and slash.radius.value > stab.radius.value
	)
	local only = true
	for id, def in WeaponConfig.Defs do
		only = only and ((def.melee ~= nil) == (id == "knife")) and (def.melee == nil or def.fireMode == "none")
	end
	check("only the knife swings, and it fires nothing", only)
end

-- When it swings --------------------------------------------------------------------

do
	local s = newPlayer()
	local drawnAt = now(s) + DT
	local swings, bullets = run(s, B.Fire, ticks(2.2), 3)
	local times, combos = {}, {}
	for _, swing in swings do
		table.insert(times, swing.time - drawnAt)
		table.insert(combos, swing.combo)
	end
	check("the first slash comes once the knife is drawn, 0.6 s after the switch", #swings > 0 and near(times[1], 0.6, DT + 1e-9), string.format("%.4f s", times[1] or -1))
	local even = #swings == 4
	for i = 2, #swings do
		even = even and near(swings[i].time - swings[i - 1].time, 0.5, 1e-9)
	end
	check("held, it slashes every 0.5 s exactly", even, string.format("%d slashes", #swings))
	check("held slashes go round the three-swing combo and start it again", table.concat(combos, ",") == "1,2,3,1", table.concat(combos, ","))
	check("a slash is a swing, not a bullet", bullets == 0 and swings[1].kind == "slash" and swings[1].weapon == "knife")
end

do
	local s = newPlayer()
	run(s, 0, ticks(0.7), 3)
	local swings = run(s, B.AltFire, ticks(2.6) + 1, 3)
	check(
		"held, the right button stabs every 1.25 s",
		#swings == 3 and near(swings[2].time - swings[1].time, 1.25, 1e-9) and near(swings[3].time - swings[2].time, 1.25, 1e-9),
		string.format("%d stabs", #swings)
	)
	check("a stab isn't part of the combo", swings[1].kind == "stab" and swings[1].combo == 0 and s.weapons.combo == 0)
end

do
	local s = newPlayer()
	run(s, 0, ticks(0.7), 3)
	local first = run(s, B.Fire, 1, 3)[1]
	local stabs = run(s, B.AltFire, ticks(1), 3)
	check("a stab waits out the slash before it", #stabs == 1 and near(stabs[1].time - first.time, 0.5, 1e-9))
	local slashes = run(s, B.Fire, ticks(1.3), 3)
	check("and a slash waits out the stab, starting the combo over", #slashes >= 1 and near(slashes[1].time - stabs[1].time, 1.25, 1e-9) and slashes[1].combo == 1)
	local both = newPlayer()
	run(both, 0, ticks(0.7), 3)
	local swung = run(both, B.Fire + B.AltFire, 1, 3)
	check("with both buttons down it slashes", #swung == 1 and swung[1].kind == "slash")
end

do
	local s = newPlayer()
	run(s, 0, ticks(0.7), 3)
	run(s, B.Fire, 1, 3)
	run(s, 0, ticks(0.55), 3)
	local soon = run(s, B.Fire, 1, 3)
	check("a slash clicked again soon after it can come goes on round the combo", #soon == 1 and soon[1].combo == 2)
	run(s, 0, ticks(1.2), 3)
	local late = run(s, B.Fire, 1, 3)
	check("after a pause the combo starts over", #late == 1 and late[1].combo == 1)
end

do
	local s = newPlayer()
	run(s, 0, ticks(0.7), 3)
	local first = run(s, B.AltFire, 1, 3)[1]
	run(s, 0, 2, 1)
	local again = run(s, B.AltFire, ticks(1.25), 3)
	local gap = if #again > 0 then again[1].time - first.time else math.huge
	check(
		"switching away and back cuts the stab's recovery short: the next comes after the knife's draw",
		near(gap, (3 + math.ceil(0.6 / DT - 1e-9)) * DT, 1e-9) and gap < 1.25,
		string.format("%.3f s", gap)
	)
end

do
	local s = newPlayer()
	run(s, 0, ticks(0.7), 3)
	local yaw, pitch = 0.7, -0.2
	local _, swing = PlayerSim.step(s, input(B.Fire, 3, yaw, pitch), cfg, floor, DT)
	local eye = PlayerSim.eye(s, cfg)
	local aim = vector.create(-math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch))
	check(
		"a swing starts at the eye and goes where the crosshair points",
		swing ~= nil and vector.magnitude(swing.origin - eye) < 1e-6 and vector.magnitude(swing.direction - aim) < 1e-6
	)
	local gun = newPlayer()
	run(gun, 0, ticks(1.1), 1)
	local _, none = run(gun, B.Fire, 3, 1)
	local gunSwings = run(gun, B.Fire, 3, 1)
	check("a gun never swings", #gunSwings == 0 and none > 0)
end

do
	local s = newPlayer()
	run(s, 0, ticks(0.7), 3)
	run(s, B.Fire, 1, 3)
	run(s, 0, ticks(0.55), 3)
	run(s, B.Fire, 1, 3)
	local _, back = PlayerCodec.decodeAck(PlayerCodec.encodeAck(7, s))
	check("the combo goes in the server's ack, so a correction keeps it", s.weapons.combo == 2 and back.weapons.combo == 2)
end

-- What a swing catches ----------------------------------------------------------------

-- The one swinging stands at the origin with their eye at chest height,
-- looking down -Z. Targets face back towards them (yaw pi) unless a test
-- turns them.
local EYE = vector.create(0, 1.17, 0)
local AHEAD = vector.create(0, 0, -1)
local empty = FakeLevel.new()

local function at(id: number, x: number, z: number, yaw: number?): Melee.Target
	return { id = id, pose = { position = vector.create(x, 0, z), yaw = yaw or math.pi, crouchAlpha = 0 } }
end

local function swingAt(targets: { Melee.Target }, attack: WeaponConfig.SwingDef?, level: any?, origin: vector?, dir: vector?): Melee.Result
	return Melee.resolve(level or empty, origin or EYE, dir or AHEAD, attack or slash, targets, 99)
end

do
	local r = swingAt({ at(1, 0, -1.2) })
	check(
		"a target straight ahead is caught on the face of its body",
		r.hit ~= nil and r.hit.targetId == 1 and r.hit.region == "body" and r.hit.offset == 0 and near(r.hit.distance, 1.2 - 0.14, 1e-5)
	)
	check("from in front a slash does 50", r.damage == 50 and not r.back)
	local s = swingAt({ at(1, 0, -1.2) }, stab)
	check("and a stab 75", s.hit ~= nil and s.damage == 75)

	-- The body's face 1.95 m ahead: in the slash's reach, past the stab's.
	local far = at(2, 0, -(1.95 + 0.14))
	local reached = swingAt({ far })
	local short = swingAt({ far }, stab)
	check("a slash reaches 2.0 m straight ahead and a stab 1.8", reached.hit ~= nil and short.hit == nil)
	check("nothing past that", swingAt({ at(3, 0, -(2.05 + 0.14)) }).hit == nil)

	-- A body whose near side is 0.35 m off the aim, 1 m ahead.
	local side = at(4, 0.22 + 0.35, -1, 0)
	local wide = swingAt({ side })
	local narrow = swingAt({ side }, stab)
	check(
		"a slash catches 0.4 m either side of the aim and a stab 0.3",
		wide.hit ~= nil and near(wide.hit.offset, 0.35, 1e-5) and narrow.hit == nil,
		if wide.hit then string.format("%.4f m off", wide.hit.offset) else "missed"
	)
	check("nothing behind the one swinging", swingAt({ at(5, 0, 1.0) }).hit == nil)
	check("nor the one swinging", Melee.resolve(empty, EYE, AHEAD, slash, { at(99, 0, -0.5) }, 99).hit == nil)
end

do
	-- One a little off the aim further away; one well off it, nearer.
	local onAim = at(1, 0.05, -1.5)
	local offAim = at(2, 0.22 + 0.3, -0.8)
	local r = swingAt({ offAim, onAim })
	check(
		"of two in reach, the one nearer the aim takes it, though further away",
		r.hit ~= nil and r.hit.targetId == 1 and #r.contacts == 2 and r.contacts[2].targetId == 2
	)
	local nearer = swingAt({ at(3, 0, -1.6), at(4, 0, -0.9) })
	check("of two on the aim, the nearer one does", nearer.hit ~= nil and nearer.hit.targetId == 4)

	local head = Melee.resolve(empty, vector.create(0, 1.62, 0), AHEAD, slash, { at(5, 0, -1.2) }, 99)
	check("at eye height it catches the head, for the same 50", head.hit ~= nil and head.hit.region == "head" and head.damage == 50)
end

do
	-- Facing away (yaw 0 looks down -Z, away from the origin).
	local r = swingAt({ at(1, 0, -1.2, 0) })
	local s = swingAt({ at(1, 0, -1.2, 0) }, stab)
	check("from behind a slash does 100 and a stab 150", r.back and r.damage == 100 and s.back and s.damage == 150)
	-- Side on: facing +X or -X, square to the one swinging.
	local justBehind = swingAt({ at(2, 0, -1.2, math.pi / 2 - 0.05) })
	local justInFront = swingAt({ at(2, 0, -1.2, math.pi / 2 + 0.05) })
	check(
		"behind is anywhere past the line through the shoulders, a 180-degree arc",
		justBehind.back and justBehind.damage == 100 and not justInFront.back and justInFront.damage == 50
	)
	check(
		"the line is square to the way the target faces",
		Melee.isBehind(vector.create(1, 0, -1.2), at(3, 0, -1.2, math.pi / 2).pose)
			and not Melee.isBehind(vector.create(-1, 0, -1.2), at(3, 0, -1.2, math.pi / 2).pose)
	)
end

do
	local walled = FakeLevel.new()
	walled:wall("solid", 0.5, 0.1)
	local r = swingAt({ at(1, 0, -1.2) }, slash, walled)
	check("a wall in between hides the target", r.hit == nil and r.hidden[1] == 1)
	check("and the blade strikes the wall instead", r.wall ~= nil and near(r.wall.distance, 0.5, 1e-5))

	-- A post on the aim: the target straight ahead behind it, hidden; one
	-- off to the side of it, in view.
	local post = FakeLevel.new()
	post:add("solid", vector.create(-0.2, -1, -0.6), vector.create(0.1, 4, -0.5))
	local around = swingAt({ at(2, 0, -1.2), at(3, 0.22 + 0.3, -0.8) }, slash, post)
	check(
		"when the level hides the one nearest the aim, the next nearest takes it",
		around.hit ~= nil and around.hit.targetId == 3 and #around.hidden == 1 and around.hidden[1] == 2,
		if around.hit then tostring(around.hit.targetId) else "none"
	)

	-- Waist-high cover 0.5 m ahead, its top 8 cm above the eye: the body
	-- behind it is hidden, but the head shows over it.
	local cover = FakeLevel.new()
	cover:add("solid", vector.create(-1, -1, -0.6), vector.create(1, 1.25, -0.5))
	local over = swingAt({ at(5, 0, -1.2) }, slash, cover)
	check(
		"behind waist-high cover the head that shows over it is struck",
		over.hit ~= nil and over.hit.targetId == 5 and over.hit.region == "head" and #over.hidden == 0 and over.damage == 50,
		if over.hit then over.hit.region else "missed"
	)
	local low = FakeLevel.new()
	low:add("solid", vector.create(-1, -1, -0.6), vector.create(1, 1.9, -0.5))
	check("but a wall above its head hides all of it", swingAt({ at(5, 0, -1.2) }, slash, low).hit == nil)

	local open = FakeLevel.new()
	open:wall("solid", 1.2, 0.2)
	local struck = swingAt({}, slash, open)
	check("with no one in reach the blade strikes the wall ahead within reach", struck.wall ~= nil and near(struck.wall.distance, 1.2, 1e-5))
	local distant = FakeLevel.new()
	distant:wall("solid", 2.3, 0.2)
	check("but not one past it", swingAt({}, slash, distant).wall == nil)
	check("a hit strikes no wall", swingAt({ at(4, 0, -1.0) }, slash, open).wall == nil)
end

do
	-- Lag compensation: the target crosses in front, and the server checks
	-- the swing where the one swinging saw it.
	local history = LagCompensation.new()
	for k = 0, 30 do
		local t = k / 60
		LagCompensation.record(history, t, {
			{
				id = 1,
				position = vector.create(-2 + 6 * t, 0, -1.2),
				yaw = math.pi,
				pitch = 0,
				crouchAlpha = 0,
				grounded = true,
				alive = true,
				quiet = false,
				reloading = false,
				weapon = 0,
				channel = 0,
			},
		})
	end
	local function targetsAt(time: number): { Melee.Target }
		return LagCompensation.shotTargets(LagCompensation.targets(history, time, function()
			return true
		end))
	end
	-- At 1/3 s the target is at x = 0, straight ahead; by 1/2 s it's 1 m past.
	check("a swing is checked against the targets as the one swinging saw them", swingAt(targetsAt(1 / 3)).hit ~= nil and swingAt(targetsAt(0.5)).hit == nil)
end

do
	-- Health: 100 and a full 50 Heavy Armor, which takes 66% of each hit.
	local function after(amount: number, kind: string): Health.State
		local h = Health.new(100, kind)
		Health.apply(h, amount)
		return h
	end
	check("a stab in the back kills through Heavy Armor", not after(150, "heavy").alive)
	check("one from in front leaves 74.5 and the shield's last 0.5", near(after(75, "heavy").health, 74.5, 1e-9) and near(after(75, "heavy").shield, 0.5, 1e-9))
	check("a slash in the back leaves 50 and no shield", near(after(100, "heavy").health, 50, 1e-9) and after(100, "heavy").shield == 0)
	check("a stab in the back kills through the Regen Shield too", not after(150, "regen").alive)
end

return nil
