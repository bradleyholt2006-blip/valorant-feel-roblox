--!strict
-- Weapon firing (system 2): fire rate, ammo, reload, equip, scope, movement
-- speed by weapon and the hit slow.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local MovementSim = require("../src/shared/Movement/MovementSim")
local PlayerSim = require("../src/shared/PlayerSim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
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

-- Settles a fresh player on the floor and waits out the spawn landing's
-- accuracy penalty, so the first shot is a clean standing shot.
local function newPlayer(loadout: { string }?): PlayerSim.State
	local s = PlayerSim.new(vector.create(0, 0.02, 0), loadout)
	for _ = 1, 40 do
		PlayerSim.step(s, input(0, s.weapons.equipped), cfg, floor, DT)
	end
	return s
end

-- Steps `ticks` ticks with the same buttons; returns the shots fired.
local function run(s: PlayerSim.State, buttons: number, ticks: number, slot: number?): { WeaponSim.Shot }
	local shots = {}
	for _ = 1, ticks do
		local shot = PlayerSim.step(s, input(buttons, slot or s.weapons.equipped), cfg, floor, DT)
		if shot then
			table.insert(shots, shot)
		end
	end
	return shots
end

local function now(s: PlayerSim.State): number
	return s.movement.tick * DT
end

local function ticksFor(seconds: number): number
	return math.ceil(seconds / DT) + 1
end

H.section("Weapon metrics")
for _, id in { "vandal", "phantom", "operator", "sheriff", "classic" } do
	local def = WeaponConfig.get(id)
	local s = newPlayer({ if def.slot == 1 then id else "vandal", if def.slot == 2 then id else "classic", "knife" })
	s.weapons.equipped = def.slot
	local shots = {}
	-- Auto: hold. Semi: a perfect clicker, pressing on the first tick the
	-- weapon is ready (a press during the cooldown is not buffered).
	for _ = 1, ticksFor(def.magazine.value / def.fireRate.value + 1) do
		local ready = (s.movement.tick + 1) * DT >= s.weapons.nextFireTime - 1e-9 and not s.weapons.fireHeld
		local buttons = if def.fireMode == "auto" or ready then B.Fire else 0
		local shot = PlayerSim.step(s, input(buttons, def.slot), cfg, floor, DT)
		if shot then
			table.insert(shots, shot)
		end
		if #shots == def.magazine.value then
			break
		end
	end
	local mean = if #shots > 1 then (shots[#shots].time - shots[1].time) / (#shots - 1) else 0
	local body = WeaponConfig.shotsToKill(def, "body", 10, 150) or 0
	print(string.format(
		"[%s] %s %.2f rps -> measured %.2f rps (%.2f ticks/shot), mag of %d empties in %.2f s, reload %.2f s, TTK body x%d %.0f ms",
		id,
		def.fireMode,
		def.fireRate.value,
		if mean > 0 then 1 / mean else 0,
		mean / DT,
		#shots,
		if #shots > 0 then shots[#shots].time - shots[1].time else 0,
		def.reloadTime.value,
		body,
		(body - 1) * WeaponSim.fireInterval(def, 0) * 1000
	))
end

H.section("Weapon tests")

do
	local ok = true
	for id, def in WeaponConfig.Defs do
		for _, key in { "fireRate", "magazine", "reserve", "reloadTime", "equipTime", "moveMultiplier", "damageSource" } do
			local param = (def :: any)[key]
			if type(param) ~= "table" or type(param.value) ~= "number" or param.source == "" then
				ok = false
				print("    missing or unlabelled: " .. id .. "." .. key)
			end
		end
		local last = -1
		for _, band in def.damage do
			if band.maxRange <= last then
				ok = false
			end
			last = band.maxRange
		end
		if WeaponConfig.Ids[WeaponConfig.IndexOf[id]] ~= id then
			ok = false
		end
	end
	check("every weapon stat is labelled and damage bands ascend", ok)
end

do
	local s = newPlayer()
	local def = WeaponConfig.get("vandal")
	local interval = WeaponSim.fireInterval(def, 0)
	local shots = run(s, B.Fire, ticksFor(25 * interval))
	check("Vandal fires the whole magazine when held", #shots == 25, tostring(#shots))
	local span = shots[#shots].time - shots[1].time
	check("Vandal cadence is 9.75 rps within one tick over the magazine", span >= 24 * interval - 1e-9 and span < 24 * interval + DT, string.format("%.4f vs %.4f", span, 24 * interval))
	local gaps = {}
	for i = 2, #shots do
		gaps[math.floor((shots[i].time - shots[i - 1].time) / DT + 0.5)] = true
	end
	check("Vandal shots land 13 or 14 ticks apart (1/9.75 s = 13.13 ticks)", gaps[13] == true and gaps[14] == true and #shots > 0)
	check("shot numbers count up", shots[1].shotNumber == 1 and shots[25].shotNumber == 25)
	check("spray index counts shots in the spray", shots[1].sprayIndex == 0 and shots[25].sprayIndex == 24)
	check("magazine is empty", s.weapons.ammo[1] == 0)

	-- Holding fire on an empty magazine reloads once the last cooldown ends.
	run(s, B.Fire, ticksFor(interval))
	check("empty magazine starts a reload by itself", WeaponSim.isReloading(s.weapons))
	check("auto-reload starts when the last shot's cooldown ends", near(s.weapons.reloadEndTime - shots[25].time, interval + def.reloadTime.value, DT + 1e-9), tostring(s.weapons.reloadEndTime - shots[25].time))
	-- Hold fire until the tick before the reload ends: nothing may fire.
	local remaining = math.floor((s.weapons.reloadEndTime - now(s)) / DT + 1e-6) - 1
	local during = run(s, B.Fire, remaining)
	check("no shots while reloading", #during == 0 and WeaponSim.isReloading(s.weapons))
	run(s, 0, 2)
	check("reload refills the magazine from reserve", not WeaponSim.isReloading(s.weapons) and s.weapons.ammo[1] == 25 and s.weapons.reserve[1] == 50, string.format("%d / %d", s.weapons.ammo[1], s.weapons.reserve[1]))
end

do
	local s = newPlayer()
	run(s, B.Fire, ticksFor(9.9 / 9.75))
	local fired = 25 - s.weapons.ammo[1]
	run(s, 0, 4)
	run(s, B.Reload, 1)
	check("manual reload starts", WeaponSim.isReloading(s.weapons))
	run(s, 0, ticksFor(WeaponConfig.get("vandal").reloadTime.value))
	check("manual reload tops up only what was fired", s.weapons.ammo[1] == 25 and s.weapons.reserve[1] == 75 - fired, string.format("fired %d -> %d / %d", fired, s.weapons.ammo[1], s.weapons.reserve[1]))
end

do
	local s = newPlayer()
	run(s, B.Fire, 30)
	local ammo = s.weapons.ammo[1]
	run(s, 0, 2)
	run(s, B.Reload, 1)
	run(s, 0, 30, 2)
	check("switching weapons cancels a reload", not WeaponSim.isReloading(s.weapons) and s.weapons.ammo[1] == ammo)
	-- Back to the rifle with fire held: the first shot waits for the draw.
	local switchTime = now(s) + DT
	local shots = run(s, B.Fire, ticksFor(1.2), 1)
	local def = WeaponConfig.get("vandal")
	check("first shot after a switch waits for the equip time", #shots > 0 and shots[1].time >= switchTime + def.equipTime.value - 1e-9 and shots[1].time < switchTime + def.equipTime.value + DT, if #shots > 0 then tostring(shots[1].time - switchTime) else "no shots")
end

do
	local s = newPlayer({ "vandal", "sheriff", "knife" })
	run(s, 0, ticksFor(1.1), 2)
	local held = run(s, B.Fire, ticksFor(2), 2)
	check("semi-auto fires once per press when held", #held == 1, tostring(#held))
	run(s, 0, ticksFor(0.5), 2)
	WeaponSim.give(s.weapons, 2, "sheriff") -- full magazine again
	local spam = {}
	for i = 1, ticksFor(2) do
		local shot = PlayerSim.step(s, input(if i % 2 == 1 then B.Fire else 0, 2), cfg, floor, DT)
		if shot then
			table.insert(spam, shot)
		end
	end
	local minGap = math.huge
	for i = 2, #spam do
		minGap = math.min(minGap, spam[i].time - spam[i - 1].time)
	end
	check("semi-auto spam is capped at the fire rate (Sheriff 4 rps)", #spam >= 6 and minGap >= 0.25 - 1e-9, string.format("%d shots, min gap %.4f", #spam, minGap))
end

do
	local s = newPlayer({ "operator", "classic", "knife" })
	local w = s.weapons
	run(s, 0, ticksFor(1.6))
	local zooms = {}
	for _ = 1, 3 do
		run(s, B.AltFire, 1)
		run(s, 0, 1)
		table.insert(zooms, w.scoped)
	end
	check("Operator alt-fire cycles 2.5x, 5x, off", zooms[1] == 1 and zooms[2] == 2 and zooms[3] == 0, table.concat(zooms, ","))
	run(s, B.AltFire, 1)
	run(s, 0, 1)
	check("scoped Operator move speed = 6.75 x 76% x 72%", near(PlayerSim.maxSpeed(s, cfg), 6.75 * 0.76 * 0.72, 1e-9), tostring(PlayerSim.maxSpeed(s, cfg)))
	local shots = run(s, B.Fire, 1)
	check("Operator fires scoped", #shots == 1 and shots[1].scoped == 1)
	run(s, 0, 1)
	local again = run(s, B.Fire, ticksFor(1 / 0.6) - 3)
	check("Operator bolt cycle is 1/0.6 s", #again == 0)
	run(s, 0, 1)
	local third = run(s, B.Fire, 4)
	check("Operator can fire again after the bolt cycle", #third == 1)
end

do
	local s = newPlayer()
	local def = WeaponConfig.get("vandal")
	run(s, B.AltFire, 1)
	run(s, 0, 1)
	check("rifle alt-fire zooms 1.25x", s.weapons.scoped == 1 and def.ads ~= nil and (def.ads :: any).zoom[1] == 1.25)
	local interval = WeaponSim.fireInterval(def, 1)
	check("rifle ADS fire rate x0.9", near(1 / interval, 9.75 * 0.9, 1e-9))
	run(s, B.Fire, 1)
	run(s, 0, 1)
	run(s, B.Reload, 1)
	check("reloading drops the scope", WeaponSim.isReloading(s.weapons) and s.weapons.scoped == 0)
end

do
	local s = newPlayer()
	run(s, 0, ticksFor(1), 3)
	local shots = run(s, B.Fire + B.Reload, ticksFor(1), 3)
	check("knife never fires or reloads", #shots == 0 and not WeaponSim.isReloading(s.weapons))
end

do
	local s = newPlayer()
	s.weapons.reserve[1] = 0
	run(s, B.Fire, ticksFor(3))
	check("no reload with an empty reserve", s.weapons.ammo[1] == 0 and not WeaponSim.isReloading(s.weapons))
end

do
	local s = newPlayer()
	run(s, B.Fire, 20)
	WeaponSim.give(s.weapons, 1, "phantom", now(s))
	check("debug give fills the new weapon", s.weapons.loadout[1] == "phantom" and s.weapons.ammo[1] == 30 and s.weapons.reserve[1] == 60)
	local shots = run(s, B.Fire, ticksFor(0.9))
	check("a weapon given into the hand has to be drawn", #shots == 0)
end

do
	local speeds = {}
	for _, id in { "knife", "vandal", "operator", "classic", "sheriff" } do
		local def = WeaponConfig.get(id)
		local s = newPlayer({ if def.slot == 1 then id else "vandal", if def.slot == 2 then id else "classic", "knife" })
		run(s, 0, ticksFor(def.equipTime.value + 0.1), def.slot)
		run(s, B.Forward, 256, def.slot)
		speeds[id] = MovementSim.horizontalSpeed(s.movement)
	end
	check("run speed by weapon: knife 6.75, rifle 5.40, Operator 5.13, Classic 5.74, Sheriff 5.40",
		near(speeds.knife, 6.75, 0.01) and near(speeds.vandal, 5.40, 0.01) and near(speeds.operator, 5.13, 0.01) and near(speeds.classic, 5.7375, 0.01) and near(speeds.sheriff, 5.40, 0.01),
		string.format("%.3f %.3f %.3f %.3f %.3f", speeds.knife, speeds.vandal, speeds.operator, speeds.classic, speeds.sheriff))
end

do
	local s = newPlayer({ "operator", "classic", "knife" })
	check("Operator deadzone is 15% (patch 1.09)", near(PlayerSim.deadzoneSpeed(s, cfg), 6.75 * 0.76 * 0.15, 1e-9))
	local r = newPlayer()
	check("rifle deadzone is 27.5% of 5.40 m/s (patch 3.0)", near(PlayerSim.deadzoneSpeed(r, cfg), 1.485, 1e-9))
end

do
	local s = newPlayer()
	run(s, B.Forward, 256)
	local tagTicks = math.ceil(WeaponConfig.Health.tagDuration.value / DT)
	PlayerSim.applyTag(s, cfg, WeaponConfig.Health.tagSpeedMultiplier.value, WeaponConfig.Health.tagDuration.value, DT)
	check("tagging clamps speed at once", near(MovementSim.horizontalSpeed(s.movement), 5.40 * 0.275, 1e-6), tostring(MovementSim.horizontalSpeed(s.movement)))
	run(s, B.Forward, tagTicks - 1)
	check("tag holds for its duration", PlayerSim.isTagged(s) and MovementSim.horizontalSpeed(s.movement) <= 5.40 * 0.275 + 1e-6)
	run(s, B.Forward, 1)
	check("tag wears off after its duration", not PlayerSim.isTagged(s) and near(PlayerSim.maxSpeed(s, cfg), 5.40, 1e-9))
end

do
	local s = newPlayer()
	local shot = PlayerSim.step(s, input(B.Fire, 1, math.pi / 2, 0), cfg, floor, DT)
	check("shot leaves from the eye", shot ~= nil and near(shot.origin.y - s.movement.position.y, cfg.standEyeHeight, 1e-5), if shot then tostring(shot.origin) else "no shot")
	check("yaw pi/2 aims along -X", shot ~= nil and near(shot.aim.x, -1, 1e-6) and near(shot.aim.z, 0, 1e-6))
	-- The bullet itself leaves somewhere inside the first-shot cone (system 3).
	local off = if shot then math.deg(math.acos(math.clamp(vector.dot(shot.aim, shot.direction), -1, 1))) else 99
	check("first standing shot stays inside the 0.25 degree cone", shot ~= nil and off <= 0.25 + 1e-3, string.format("%.4f deg", off))
	local pitched = PlayerSim.step(newPlayer(), input(B.Fire, 1, 0, math.rad(30)), cfg, floor, DT)
	check("pitch 30 degrees up aims at sin(30) upward", pitched ~= nil and near(pitched.aim.y, 0.5, 1e-6))
end

do
	local function simulate(): (PlayerSim.State, number)
		local s = newPlayer()
		local count = 0
		local pattern = { B.Fire, B.Fire + B.Right, 0, B.Reload, B.Fire + B.Left, B.AltFire, B.Fire + B.Jump }
		for i = 1, 900 do
			local slot = if (i // 450) % 2 == 0 then 1 else 2
			if PlayerSim.step(s, input(pattern[(i // 23) % #pattern + 1], slot, i * 0.003, 0.01), cfg, floor, DT) then
				count += 1
			end
		end
		return s, count
	end
	local a, na = simulate()
	local b, nb = simulate()
	check("weapon simulation is deterministic", na == nb and a.weapons.shotCounter == b.weapons.shotCounter and a.movement.position == b.movement.position and na > 5, tostring(na))
end

return nil
