--!strict
-- Spray Lab (F2, second page): where every bullet of a spray went relative to
-- where you were aiming, next to what the model says should happen.
--
--   * plot of the current spray in degrees (right, up), measured from each
--     bullet's real direction: dots coloured from the first bullet (green)
--     to the last (red), the recoil centre each was drawn around (grey) and
--     the last bullet's cone (ring). A measured reference spray
--     (ReferenceData.sprayPattern) is drawn in blue for comparison
--   * the last shot's cone, piece by piece: firing error at its bullet
--     number, ADS, crouch, movement state, landing, error power, recoil
--   * the next shot right now: its bullet number after recovery and its cone
--   * the weapon's curves by bullet, and where tapping at a few steady
--     rhythms settles (from the same recovery maths the simulation uses)
--
-- The spray starts over whenever a shot comes out as a fresh first bullet.
-- Backspace clears it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Accuracy = require(Shared.Weapons.Accuracy)

local Ui = require(script.Parent.Ui)
local ReferenceData = require(script.Parent.ReferenceData)

local DT = 1 / MovementConfig.TickRate.value
local PLOT = 320 -- pixels
local SCALE = 32 -- pixels per degree
local ORIGIN = Vector2.new(PLOT / 2, PLOT - 2 * SCALE) -- aim point: 5 deg each side, 2 below, 8 above
local MAX_DOTS = 40
local TAP_RHYTHMS = { 0.15, 0.2, 0.25, 0.3, 0.4 }
local TABLE_BULLETS = { 1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 25 }

local SprayLab = {}

type Point = { right: number, up: number }
type Entry = { shot: WeaponSim.Shot, landed: Point, centre: Point }

local panel: Frame? = nil

function SprayLab.setVisible(visible: boolean)
	local p = panel
	if p then
		p.Visible = visible
	end
end

-- Offset of a direction from the shot's aim, in degrees right and up.
local function offsetFromAim(shot: WeaponSim.Shot, dir: vector): Point
	local forward = shot.aim
	local right = vector.create(math.cos(shot.yaw), 0, -math.sin(shot.yaw))
	local up = vector.cross(right, forward)
	local f = vector.dot(dir, forward)
	return {
		right = math.deg(math.atan2(vector.dot(dir, right), f)),
		up = math.deg(math.atan2(vector.dot(dir, up), f)),
	}
end

local function toPixels(p: Point): Vector2
	return ORIGIN + Vector2.new(p.right, -p.up) * SCALE
end

local function dotFrame(parent: Instance, size: number, color: Color3, hollow: boolean?): Frame
	local f = Ui.frame(parent, {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = color,
		BackgroundTransparency = if hollow then 1 else 0,
		Visible = false,
		ZIndex = 3,
	})
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = f
	if hollow then
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 1
		stroke.Parent = f
	end
	return f
end

local function place(f: Frame, at: Vector2, size: number)
	f.Size = UDim2.fromOffset(size, size)
	f.Position = UDim2.fromOffset(at.X - size / 2, at.Y - size / 2)
	f.Visible = at.X >= 0 and at.X <= PLOT and at.Y >= 0 and at.Y <= PLOT
end

-- Where tapping every `rhythm` seconds settles: the bullet number of the
-- tenth tap, using the simulation's own recovery maths.
local function tapSettle(def: WeaponConfig.WeaponDef, rhythm: number): number
	local interval = WeaponSim.fireInterval(def, 0)
	local elapsed = math.max(math.floor(rhythm / DT + 0.5), math.ceil(interval / DT - 1e-9)) * DT
	local factor = Accuracy.recoveryFactor(def.accuracy, interval, elapsed, DT)
	local spray = 0
	for _ = 1, 9 do
		spray = spray * factor + 1
	end
	return spray * factor + 1
end

local function status(label: string): string
	return string.format('<font color="#%s">%s</font>', Ui.hex(Ui.DIM), label)
end

function SprayLab.start(controller: any)
	local gui = Ui.screen("VFSprayLab", 22)
	local root = Ui.frame(gui, {
		Size = UDim2.fromOffset(700, 520),
		Position = UDim2.new(1, -712, 0, 120),
		Visible = false,
	})
	panel = root

	local plot = Ui.frame(root, {
		Size = UDim2.fromOffset(PLOT, PLOT),
		Position = UDim2.fromOffset(8, 30),
		BackgroundColor3 = Color3.fromRGB(4, 4, 6),
		BackgroundTransparency = 0.1,
		ClipsDescendants = true,
	})
	-- Grid: one line per degree, axes brighter.
	for d = -5, 5 do
		Ui.frame(plot, {
			Size = UDim2.fromOffset(1, PLOT),
			Position = UDim2.fromOffset(ORIGIN.X + d * SCALE, 0),
			BackgroundColor3 = Ui.DIM,
			BackgroundTransparency = if d == 0 then 0.4 else 0.85,
		})
	end
	for d = -2, 8 do
		Ui.frame(plot, {
			Size = UDim2.fromOffset(PLOT, 1),
			Position = UDim2.fromOffset(0, ORIGIN.Y - d * SCALE),
			BackgroundColor3 = Ui.DIM,
			BackgroundTransparency = if d == 0 then 0.4 else 0.85,
		})
	end
	local caption = Ui.label(root, {
		Size = UDim2.fromOffset(PLOT, 20),
		Position = UDim2.fromOffset(8, 6),
		TextSize = 13,
	})
	local legend = Ui.label(root, {
		Size = UDim2.fromOffset(PLOT, 150),
		Position = UDim2.fromOffset(8, 36 + PLOT),
		TextSize = 12,
	})
	local body = Ui.label(root, {
		Size = UDim2.new(1, -PLOT - 28, 1, -12),
		Position = UDim2.fromOffset(PLOT + 20, 6),
		TextSize = 13,
	})

	local bulletDots, centreDots, refDots = {}, {}, {}
	for _ = 1, MAX_DOTS do
		table.insert(centreDots, dotFrame(plot, 3, Ui.DIM))
		table.insert(bulletDots, dotFrame(plot, 5, Ui.GOOD))
		table.insert(refDots, dotFrame(plot, 7, Ui.NEUTRAL, true))
	end
	local ring = dotFrame(plot, 10, Ui.TEXT, true)

	local spray: { Entry } = {}

	table.insert(controller.shotListeners, function(shot: WeaponSim.Shot)
		if shot.bullet <= 1 + 1e-9 or (spray[1] and spray[1].shot.weapon ~= shot.weapon) then
			table.clear(spray)
		end
		if #spray < MAX_DOTS then
			table.insert(spray, {
				shot = shot,
				landed = offsetFromAim(shot, shot.direction),
				centre = offsetFromAim(shot, Accuracy.direction(shot.yaw, shot.pitch, shot.recoilPitch, shot.recoilYaw, 0, 0)),
			})
		end
	end)

	local function render()
		local sim: PlayerSim.State? = controller.sim
		if not sim then
			body.Text = "Spray Lab: waiting for spawn"
			return
		end
		local def = PlayerSim.def(sim)
		local w = sim.weapons
		local acc, rec = def.accuracy, def.recoil
		local scoped = w.scoped > 0 and def.ads ~= nil
		local ref: any = ReferenceData[def.id] or {}

		-- Plot ------------------------------------------------------------------
		for i, f in bulletDots do
			local e = spray[i]
			if e then
				local t = math.clamp((e.shot.bullet - 1) / 24, 0, 1)
				f.BackgroundColor3 = Ui.GOOD:Lerp(Ui.BAD, t)
				place(f, toPixels(e.landed), 5)
				place(centreDots[i], toPixels(e.centre), 3)
			else
				f.Visible = false
				centreDots[i].Visible = false
			end
		end
		local last = spray[#spray]
		if last then
			local r = math.max(last.shot.cone.radius * SCALE * 2, 2)
			place(ring, toPixels(last.centre), r)
			ring.Visible = true
		else
			ring.Visible = false
		end
		local pattern = ref.sprayPattern
		for i, f in refDots do
			local pt = pattern and pattern.points[i]
			if pt then
				place(f, toPixels({ right = pt[1], up = pt[2] }), 7)
			else
				f.Visible = false
			end
		end
		caption.Text = string.format("<b>Spray Lab</b>  %s  %s  %d bullets  (1 square = 1 deg)", def.name, if scoped then "ADS" else "hip", #spray)
		legend.Text = table.concat({
			string.format('<font color="#%s">dots</font> where each bullet went, from your aim at that moment', Ui.hex(Ui.GOOD)),
			string.format('<font color="#%s">grey</font> recoil centre   <font color="#%s">ring</font> last cone', Ui.hex(Ui.DIM), Ui.hex(Ui.TEXT)),
			if pattern
				then string.format('<font color="#%s">blue</font> reference spray n=%d (%s)', Ui.hex(Ui.NEUTRAL), pattern.n, pattern.source)
				else string.format('<font color="#%s">reference spray: not measured (ReferenceData.sprayPattern)</font>', Ui.hex(Ui.DIM)),
			"",
			string.format('<font color="#%s">F2 next page  Backspace clear  RMB ADS  Ctrl crouch  Shift walk</font>', Ui.hex(Ui.DIM)),
		}, "\n")

		-- Text --------------------------------------------------------------------
		local lines = {}
		if last then
			local shot = last.shot
			local cone = shot.cone
			table.insert(lines, string.format("<b>last shot</b>  #%d  bullet %.2f  %s%s", shot.shotNumber, shot.bullet, shot.moveState, if shot.scoped > 0 then "  ADS" else ""))
			table.insert(lines, string.format("  firing error   %5.2f   curve at bullet %.2f", cone.curve, shot.bullet))
			table.insert(lines, string.format("  ADS            %+5.2f", -cone.adsReduction))
			table.insert(lines, string.format("  crouch         x%4.2f", cone.crouchMultiplier))
			table.insert(lines, string.format("  movement       %+5.2f   %s", cone.movement, shot.moveState))
			table.insert(lines, string.format("  landing        %+5.2f", cone.landing))
			table.insert(lines, string.format("  <b>cone           %5.2f deg</b>  error power %.2f", cone.radius, cone.power))
			table.insert(lines, string.format("  landed         %5.2f from the centre at %.0f deg", shot.offset, math.deg(shot.offsetAngle)))
			table.insert(lines, string.format("  recoil         up %.2f  right %+.2f", shot.recoilPitch, shot.recoilYaw))
		else
			table.insert(lines, "<b>last shot</b>  -- (fire at a wall)")
			for _ = 1, 8 do
				table.insert(lines, "")
			end
		end
		table.insert(lines, "")

		local now = sim.movement.tick * DT
		local interval = WeaponSim.fireInterval(def, w.scoped)
		local bullet = Accuracy.next(def, w, now, DT, interval)
		local ctx = PlayerSim.accuracyContext(sim, controller.buttons, controller.cfg, DT)
		local nextCone = Accuracy.cone(def, ctx, bullet, scoped)
		local left = if w.sprayIndex > 0 then (bullet - 1) / w.sprayIndex else 0
		table.insert(lines, string.format("<b>next shot now</b>  bullet %.2f (%.0f%% of the spray left)  cone %.2f  %s", bullet, left * 100, nextCone.radius, ctx.moveState))
		local tan = math.tan(math.rad(nextCone.radius))
		table.insert(lines, string.format("  cone radius at 10 / 20 / 30 m: %.1f / %.1f / %.1f cm (a head is ~24 cm wide)", tan * 1000, tan * 2000, tan * 3000))
		table.insert(lines, string.format("  recovery %.3f s %s   tap efficiency %g %s", acc.recoveryTime.value, status(acc.recoveryTime.status), acc.tapEfficiency.value, status(acc.tapEfficiency.status)))
		table.insert(lines, string.format(
			"  movement: run %g  walk %g  crouch-walk %g  air %g   land +%g",
			acc.runError.value,
			acc.walkError.value,
			acc.crouchMoveError.value,
			acc.airError.value,
			WeaponConfig.Accuracy.landError.value
		))
		table.insert(lines, "")

		local head, errors, climbs = { "bullet" }, { "error " }, { "climb " }
		for _, b in TABLE_BULLETS do
			table.insert(head, string.format("%5d", b))
			table.insert(errors, string.format("%5.2f", Accuracy.curve(acc.firingError.points, b)))
			table.insert(climbs, string.format("%5.2f", Accuracy.curve(rec.pitch.points, b)))
		end
		table.insert(lines, table.concat(head, ""))
		table.insert(lines, table.concat(errors, "") .. "  " .. status(acc.firingError.status))
		table.insert(lines, table.concat(climbs, "") .. "  " .. status(rec.pitch.status))
		table.insert(lines, string.format(
			"drift from bullet %g: %.2f per bullet, max %.2f, flip %.0f%%   %s",
			rec.swayStart.value,
			rec.swayStep.value,
			rec.swayMax.value,
			rec.swayFlipChance.value * 100,
			status(rec.swayStep.status)
		))
		table.insert(lines, string.format(
			"running climb x%g %s   crouched drift x%g %s   ADS x%g",
			rec.runPitchMultiplier.value,
			status(rec.runPitchMultiplier.status),
			rec.crouchYawMultiplier.value,
			status(rec.crouchYawMultiplier.status),
			rec.adsMultiplier.value
		))
		table.insert(lines, string.format("camera follows %.0f%% of the recoil (ADS %.0f%%)", rec.cameraFraction.value * 100, rec.adsCameraFraction.value * 100))
		table.insert(lines, "")

		local taps = {}
		for _, rhythm in TAP_RHYTHMS do
			table.insert(taps, string.format("%.2fs b%.2f", rhythm, tapSettle(def, rhythm)))
		end
		table.insert(lines, "<b>tapping</b>, where the 10th tap lands in the spray:")
		table.insert(lines, "  " .. table.concat(taps, "   "))
		local measured = ref.firstShotError
		table.insert(lines, if measured
			then string.format("reference first-shot cone %.2f deg n=%d (ours %.2f)", measured.value, measured.n, Accuracy.curve(acc.firingError.points, 1))
			else string.format('<font color="#%s">reference first-shot cone: not measured</font>', Ui.hex(Ui.DIM)))
		body.Text = table.concat(lines, "\n")
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Backspace then
			table.clear(spray)
		end
	end)

	task.spawn(function()
		while true do
			if root.Visible then
				render()
			end
			task.wait(0.1)
		end
	end)
end

return SprayLab
