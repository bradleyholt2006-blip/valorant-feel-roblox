--!strict
-- Weapon Lab (F2, first page): measures our weapon timing and hit
-- registration so they can be checked against the reference.
--
--   * stats of the equipped weapon (every number labelled by its source in
--     WeaponConfig) and its live timers
--   * fire rate measured from the simulation's own shot times over the last
--     burst, next to the configured rate and any footage measurement
--   * reload and draw-to-first-shot times, measured the same way
--   * shot log: what the client predicted each shot hit vs what the server
--     decided, with the round trip, how far the server rewound and an
--     agreement rate. The server rewinds targets to what you saw, so they
--     should agree on moving targets too; when they don't, the log says why
--     (the Hit Reg Lab, F2 third page, counts the reasons)
--   * time-to-kill table against 150 HP (100 health + heavy shields)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)

local Ui = require(script.Parent.Ui)
local ReferenceData = require(script.Parent.ReferenceData)
local ClientShots = require(script.Parent.Parent.Combat.ClientShots)

local DT = 1 / MovementConfig.TickRate.value
local LOG_ROWS = 10
local TARGET_HP = 150

local WeaponLab = {}

local panelFrame: Frame? = nil

function WeaponLab.setVisible(visible: boolean)
	local p = panelFrame
	if p then
		p.Visible = visible
	end
end

type Burst = { weapon: string, intervals: { number } }

local function shortName(id: number?): string
	if id == nil then
		return "-"
	end
	if id >= PlayerCodec.DUMMY_BASE then
		return string.format("D%d", id - PlayerCodec.DUMMY_BASE)
	end
	return string.format("P%d", id % 1000)
end

local function describe(o: { targetId: number?, region: string?, distance: number }?): string
	if not o then
		return "..."
	end
	if not o.targetId then
		return string.format("miss %4.1fm", o.distance)
	end
	return string.format("%s %s", shortName(o.targetId), o.region or "?")
end

local function refText(entry: any, value: number?, unit: string, scale: number): string
	local measured = entry
	if measured == nil then
		return string.format('<font color="#%s">ref: not measured</font>', Ui.hex(Ui.DIM))
	end
	local delta = if value then string.format(" (%+.0f%s)", (value - measured.value) * scale, unit) else ""
	return string.format("ref %.0f%s n=%d%s", measured.value * scale, unit, measured.n, delta)
end

function WeaponLab.start(controller: any)
	local gui = Ui.screen("VFWeaponLab", 22)
	local panel = Ui.frame(gui, {
		Size = UDim2.fromOffset(660, 470),
		Position = UDim2.new(1, -672, 0, 120),
		Visible = false,
	})
	panelFrame = panel
	local body = Ui.label(panel, {
		Size = UDim2.new(1, -16, 1, -12),
		Position = UDim2.fromOffset(8, 6),
		TextSize = 13,
	})

	-- Burst timing from the simulation's shot times (exact tick times).
	local current: Burst? = nil
	local lastBurst: Burst? = nil
	local lastShot: WeaponSim.Shot? = nil

	-- Reload and draw timing from the weapon state each tick.
	local reloadStart: number? = nil
	local lastReload: number? = nil
	local drawStart: number? = nil
	local lastDrawToShot: number? = nil
	local prevEquipped = 0
	local prevEquipEnd = 0
	local prevReloadEnd = 0

	table.insert(controller.shotListeners, function(shot: WeaponSim.Shot)
		local prev = lastShot
		local def = WeaponConfig.get(shot.weapon)
		local interval = WeaponSim.fireInterval(def, shot.scoped)
		if prev and prev.weapon == shot.weapon and shot.time - prev.time < interval * 1.5 and shot.time > prev.time then
			local burst = current
			if not burst or burst.weapon ~= shot.weapon then
				burst = { weapon = shot.weapon, intervals = {} }
				current = burst
			end
			table.insert((burst :: Burst).intervals, shot.time - prev.time)
		else
			if current and #current.intervals > 0 then
				lastBurst = current
			end
			current = { weapon = shot.weapon, intervals = {} }
		end
		lastShot = shot
		if drawStart then
			lastDrawToShot = shot.time - drawStart
			drawStart = nil
		end
	end)

	table.insert(controller.tickListeners, function(info: any)
		local w = info.sim.weapons
		local t = info.sim.movement.tick * DT
		if w.reloadEndTime > 0 and prevReloadEnd == 0 then
			reloadStart = t
		elseif w.reloadEndTime == 0 and prevReloadEnd > 0 and reloadStart then
			-- Finished (not cancelled) if we reached the end time.
			if t >= prevReloadEnd - 1e-9 then
				lastReload = t - reloadStart
			end
			reloadStart = nil
		end
		if w.equipped ~= prevEquipped or w.equipEndTime > prevEquipEnd then
			drawStart = t
		end
		prevEquipped, prevEquipEnd, prevReloadEnd = w.equipped, w.equipEndTime, w.reloadEndTime
	end)

	local function burstStats(burst: Burst?): (number?, number)
		if not burst or #burst.intervals == 0 then
			return nil, 0
		end
		local sum = 0
		for _, v in burst.intervals do
			sum += v
		end
		return sum / #burst.intervals, #burst.intervals
	end

	local function render()
		local sim: PlayerSim.State? = controller.sim
		if not sim then
			body.Text = "Weapon Lab: waiting for spawn"
			return
		end
		local cfg = controller.cfg
		local w = sim.weapons
		local def = PlayerSim.def(sim)
		local slot = w.equipped
		local t = sim.movement.tick * DT
		local ref: any = ReferenceData[def.id] or {}
		local lines = {}

		local interval = WeaponSim.fireInterval(def, w.scoped)
		table.insert(lines, string.format(
			"<b>Weapon Lab</b>  %s  %s  %.2f rps (%.1f ms)  mag %d  reload %.2fs  equip %.2fs  run %.2f m/s",
			def.name,
			def.fireMode,
			def.fireRate.value,
			interval * 1000,
			def.magazine.value,
			def.reloadTime.value,
			def.equipTime.value,
			PlayerSim.weaponSpeed(sim, cfg)
		))
		local states = {}
		if t < w.equipEndTime then
			table.insert(states, string.format("drawing %.2fs", w.equipEndTime - t))
		end
		if w.reloadEndTime > 0 then
			table.insert(states, string.format("reloading %.2fs", w.reloadEndTime - t))
		end
		if w.scoped > 0 and def.ads then
			table.insert(states, string.format("scoped %.2fx (move %.0f%%, rate x%.2f)", def.ads.zoom[w.scoped], def.ads.moveMultiplier.value * 100, def.ads.fireRateMultiplier.value))
		end
		if w.nextFireTime > t then
			table.insert(states, string.format("cooldown %.0fms", (w.nextFireTime - t) * 1000))
		end
		if PlayerSim.isTagged(sim) then
			table.insert(states, string.format('<font color="#%s">TAGGED x%.3f</font>', Ui.hex(Ui.BAD), sim.tagMultiplier))
		end
		table.insert(lines, string.format("state  %s   ammo %d / %d   spray %.2f", if #states > 0 then table.concat(states, ", ") else "ready", w.ammo[slot], w.reserve[slot], w.sprayIndex))
		table.insert(lines, string.format(
			'<font color="#%s">sources: rate %s | damage %s | move %s</font>',
			Ui.hex(Ui.DIM),
			def.fireRate.status,
			def.damageSource.status,
			def.moveMultiplier.status
		))
		table.insert(lines, "")

		-- Timing ---------------------------------------------------------------
		local mean, n = burstStats(if current and #current.intervals > 0 then current else lastBurst)
		if mean then
			local ok = math.abs(mean - interval) <= DT
			table.insert(lines, string.format(
				'fire rate  %.2f rps (%.1f ms, n=%d)  expect %.2f  <font color="#%s">%s</font>  %s',
				1 / mean,
				mean * 1000,
				n,
				1 / interval,
				Ui.hex(if ok then Ui.GOOD else Ui.BAD),
				if ok then "within 1 tick" else "OFF",
				refText(ref.fireInterval, mean, "ms", 1000)
			))
		else
			table.insert(lines, "fire rate  -- (hold fire, or tap as fast as you can)")
		end
		table.insert(lines, string.format(
			"reload     %s  expect %.0fms  %s",
			if lastReload then string.format("%.0fms", lastReload * 1000) else "--",
			def.reloadTime.value * 1000,
			refText(ref.reloadTime, lastReload, "ms", 1000)
		))
		table.insert(lines, string.format(
			"draw->shot %s  expect >= %.0fms  %s",
			if lastDrawToShot then string.format("%.0fms", lastDrawToShot * 1000) else "--",
			def.equipTime.value * 1000,
			refText(ref.equipTime, lastDrawToShot, "ms", 1000)
		))
		table.insert(lines, "")

		-- Shot log ---------------------------------------------------------------
		local stats = ClientShots.stats
		local pending = 0
		for _, r in ClientShots.records do
			if not r.verdict and os.clock() - r.firedAt < 2 then
				pending += 1
			end
		end
		table.insert(lines, string.format(
			"<b>shots</b>  fired %d  verdicts %d  agree %d (%s)  pending %d  server-only %d",
			stats.shots,
			stats.verdicts,
			stats.agreed,
			if stats.verdicts > 0 then string.format("%.1f%%", stats.agreed / stats.verdicts * 100) else "--",
			pending,
			stats.unmatchedVerdicts
		))
		table.insert(lines, "   #  weapon    client         server          dmg   rtt  rewind")
		local records = ClientShots.records
		for i = #records, math.max(#records - LOG_ROWS + 1, 1), -1 do
			local r = records[i]
			local v = r.verdict
			local mark = ""
			if v then
				mark = if r.agree
					then string.format('<font color="#%s">ok</font>', Ui.hex(Ui.GOOD))
					else string.format('<font color="#%s">DIFF %s</font>', Ui.hex(Ui.BAD), r.cause or "")
			end
			table.insert(lines, string.format(
				"%4d  %-8s  %-13s  %-14s  %3s  %5s  %6s  %s",
				r.shot.shotNumber,
				r.shot.weapon,
				describe(r.predicted),
				describe(v),
				if v and v.damage then tostring(v.damage) else "",
				if r.verdictAt then string.format("%.0fms", (r.verdictAt - r.firedAt) * 1000) else "",
				if v then string.format("%.0fms%s", v.rewind * 1000, if v.clamped then "!" else "") else "",
				mark
			))
		end
		for _ = #records, LOG_ROWS - 1 do
			table.insert(lines, "")
		end
		table.insert(lines, "")

		-- Time to kill -------------------------------------------------------------
		if def.fireMode ~= "none" then
			table.insert(lines, string.format("<b>TTK vs %d HP</b> (100 + heavy shields), hip fire: hits / time", TARGET_HP))
			local from = 0
			for _, band in def.damage do
				local cells = {}
				for _, region in { "head", "body", "legs" } do
					local hits = WeaponConfig.shotsToKill(def, region :: any, band.maxRange, TARGET_HP)
					cells[#cells + 1] = if hits then string.format("%-2d %4.0fms", hits, (hits - 1) * WeaponSim.fireInterval(def, 0) * 1000) else "--"
				end
				table.insert(lines, string.format("  %2d-%-3dm  head %s   body %s   legs %s", from, band.maxRange, cells[1], cells[2], cells[3]))
				from = band.maxRange
			end
		end
		table.insert(lines, "")
		table.insert(lines, string.format('<font color="#%s">F2 next page  F10 hitboxes  R reload  RMB scope  1/2/3 slot  4 Vandal 5 Phantom 6 Operator 7 Sheriff 8 Classic  Backspace clear marks + log</font>', Ui.hex(Ui.DIM)))
		body.Text = table.concat(lines, "\n")
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Backspace then
			ClientShots.reset()
			current, lastBurst, lastShot = nil, nil, nil
			lastReload, lastDrawToShot = nil, nil
		end
	end)

	task.spawn(function()
		while true do
			if panel.Visible then
				render()
			end
			task.wait(0.1)
		end
	end)
end

return WeaponLab
