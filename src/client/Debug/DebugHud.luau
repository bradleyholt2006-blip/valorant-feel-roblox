--!strict
-- Always-on movement HUD (toggle F3):
--   * crosshair whose arms spread with movement error, like the reference
--     game's "Movement error" crosshair option, so footage can be compared
--     side by side
--   * a circle showing the true cone of fire of the next shot, drawn where
--     that bullet would go (recoil included), like the reference's "Show
--     firing error" crosshair option
--   * stats panel: speed, % of max, accuracy state, flags, the last jump
--     (airtime, distance, how far it bent, speed leaving and landing),
--     netcode health
--   * key overlay (W A S D Shift Ctrl Space) for frame-by-frame comparison
--   * ghost box at the last authoritative server position (toggle G while the
--     HUD is on; not F7, which Studio takes for Start)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local MovementSim = require(Shared.Movement.MovementSim)
local JumpAnalyzer = require(Shared.Movement.JumpAnalyzer)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local Accuracy = require(Shared.Weapons.Accuracy)
local Units = require(Shared.Units)

local Ui = require(script.Parent.Ui)
local CameraController = require(script.Parent.Parent.CameraController)
local NetSim = require(script.Parent.Parent.NetSim)

local B = MovementSim.Buttons

local DebugHud = {}

local CROSSHAIR_MIN_GAP = 4
local CROSSHAIR_MAX_GAP = 40
local ARM_LENGTH = 8

function DebugHud.start(controller: any)
	local gui = Ui.screen("VFDebugHud", 20)
	local centre = Ui.screen("VFCrosshair", 20, Enum.ScreenInsets.None)

	-- Crosshair ------------------------------------------------------------
	local crosshair = Ui.frame(centre, {
		Size = UDim2.fromOffset(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	})
	local dot = Ui.frame(crosshair, {
		Size = UDim2.fromOffset(2, 2),
		Position = UDim2.fromOffset(-1, -1),
		BackgroundColor3 = Ui.TEXT,
		BackgroundTransparency = 0,
	})
	local arms = {}
	for _, dir in { Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1) } do
		local arm = Ui.frame(crosshair, {
			Size = if dir.X ~= 0 then UDim2.fromOffset(ARM_LENGTH, 2) else UDim2.fromOffset(2, ARM_LENGTH),
			BackgroundColor3 = Ui.GOOD,
			BackgroundTransparency = 0,
		})
		table.insert(arms, { frame = arm, dir = dir })
	end
	local cone = Ui.frame(crosshair, {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(8, 8),
	})
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = cone
	local ring = Instance.new("UIStroke")
	ring.Thickness = 1
	ring.Transparency = 0.2
	ring.Color = Ui.GOOD
	ring.Parent = cone

	-- Stats panel ------------------------------------------------------------
	local panel = Ui.frame(gui, {
		Size = UDim2.fromOffset(330, 320),
		Position = UDim2.fromOffset(12, 12),
	})
	local stats = Ui.label(panel, {
		Size = UDim2.new(1, -16, 1, -12),
		Position = UDim2.fromOffset(8, 6),
	})

	-- Key overlay ------------------------------------------------------------
	local keys = Ui.frame(gui, {
		Size = UDim2.fromOffset(166, 112),
		Position = UDim2.new(0.5, -83, 1, -132),
		BackgroundTransparency = 1,
	})
	local keyCells: { { frame: Frame, flag: number } } = {}
	local function key(text: string, flag: number, x: number, y: number, w: number?)
		local cell = Ui.frame(keys, {
			Size = UDim2.fromOffset(w or 38, 30),
			Position = UDim2.fromOffset(x, y),
		})
		Ui.label(cell, {
			Size = UDim2.fromScale(1, 1),
			Text = text,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		table.insert(keyCells, { frame = cell, flag = flag })
	end
	key("W", B.Forward, 64, 0)
	key("A", B.Left, 22, 34)
	key("S", B.Back, 64, 34)
	key("D", B.Right, 106, 34)
	key("Shift", B.Walk, 0, 68, 52)
	key("Ctrl", B.Crouch, 56, 68, 46)
	key("Space", B.Jump, 106, 68, 60)

	-- Ghost ------------------------------------------------------------------
	local ghost = Instance.new("Part")
	ghost.Name = "VFServerGhost"
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.CanTouch = false
	ghost.Transparency = 0.7
	ghost.Color = Ui.NEUTRAL
	ghost.Material = Enum.Material.ForceField
	ghost.Parent = nil

	local visible = true
	local ghostVisible = false
	local lastInput = 0
	local lastState: MovementSim.State? = nil
	local lastInfo: any = nil
	local jumps = JumpAnalyzer.new(1)
	local lastJump: JumpAnalyzer.Jump? = nil

	table.insert(controller.tickListeners, function(info: any)
		lastInput = info.input.buttons
		lastState = info.state
		lastInfo = info
		local m = info.state
		lastJump = JumpAnalyzer.tick(jumps, info.time, m.position, m.velocity, m.grounded, info.input.yaw) or lastJump
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F3 then
			visible = not visible
			panel.Visible = visible
			keys.Visible = visible
		elseif input.KeyCode == Enum.KeyCode.G and visible then
			ghostVisible = not ghostVisible
			ghost.Parent = if ghostVisible then Workspace else nil
		end
	end)

	local fps = 60
	RunService.RenderStepped:Connect(function(dt)
		fps += (1 / math.max(dt, 1e-4) - fps) * 0.05
		local s = lastState
		local info = lastInfo
		if not s or not info then
			return
		end
		local cfg = controller.cfg
		local speed = MovementSim.horizontalSpeed(s)
		local threshold = info.maxSpeed * info.accurateFraction
		local accurate = MovementSim.isAccurate(s, info.maxSpeed, info.accurateFraction)
		local landPenalty = (s.tick - s.lastLandTick) / MovementConfig.TickRate.value < cfg.jumpLandPenaltyTime

		-- Crosshair spread: 0 inside the deadzone, then linear up to max speed.
		local errorFraction = 0
		if not s.grounded then
			errorFraction = 1
		elseif speed > threshold then
			errorFraction = math.clamp((speed - threshold) / math.max(info.maxSpeed - threshold, 1e-3), 0, 1)
		end
		local gap = CROSSHAIR_MIN_GAP + (CROSSHAIR_MAX_GAP - CROSSHAIR_MIN_GAP) * errorFraction
		for _, arm in arms do
			local d = arm.dir
			arm.frame.Position = UDim2.fromOffset(
				if d.X > 0 then gap elseif d.X < 0 then -gap - ARM_LENGTH else -1,
				if d.Y > 0 then gap elseif d.Y < 0 then -gap - ARM_LENGTH else -1
			)
			arm.frame.BackgroundColor3 = if accurate and not landPenalty then Ui.GOOD else Ui.BAD
		end
		dot.BackgroundColor3 = if accurate then Ui.GOOD else Ui.BAD

		-- Cone of the next shot, centred where its bullet would go: the recoil
		-- minus the part the camera already shows.
		local sim: PlayerSim.State? = controller.sim
		local coneText = ""
		cone.Visible = visible and sim ~= nil
		if sim then
			local def = PlayerSim.def(sim)
			local w = sim.weapons
			local scoped = w.scoped > 0 and def.ads ~= nil
			local now = sim.movement.tick / MovementConfig.TickRate.value
			local bullet, sway = Accuracy.next(def, w, now, 1 / MovementConfig.TickRate.value, WeaponSim.fireInterval(def, w.scoped))
			local ctx = PlayerSim.accuracyContext(sim, lastInput, cfg, 1 / MovementConfig.TickRate.value)
			local nextCone = Accuracy.cone(def, ctx, bullet, scoped)
			local up, right = Accuracy.recoil(def, ctx, bullet, sway, scoped)
			local viewport = Workspace.CurrentCamera.ViewportSize
			local pixelsPerTan = viewport.X / 2 / math.tan(math.rad(CameraController.zoomedFov(CameraController.zoom)) / 2)
			local cx = math.tan(math.rad(right) + CameraController.kickYaw) * pixelsPerTan
			local cy = -math.tan(math.rad(up) - CameraController.kickPitch) * pixelsPerTan
			local r = math.max(math.tan(math.rad(nextCone.radius)) * pixelsPerTan, 1)
			cone.Size = UDim2.fromOffset(r * 2, r * 2)
			cone.Position = UDim2.fromOffset(cx - r, cy - r)
			local firstShot = Accuracy.cone(def, ctx, 1, scoped).radius - nextCone.movement - nextCone.landing
			ring.Color = if nextCone.radius <= firstShot + 1e-6 then Ui.GOOD elseif nextCone.movement + nextCone.landing > 0 then Ui.BAD else Ui.NEUTRAL
			coneText = string.format("cone    %5.2f deg  bullet %.2f  %s%s", nextCone.radius, bullet, ctx.moveState, if ctx.landing then " +land" else "")
		end

		for _, cell in keyCells do
			local down = bit32.band(lastInput, cell.flag) ~= 0
			cell.frame.BackgroundColor3 = if down then Ui.NEUTRAL else Ui.PANEL
			cell.frame.BackgroundTransparency = if down then 0.1 else 0.45
		end

		if not visible then
			return
		end
		local net = controller.stats
		local ping = Players.LocalPlayer:GetNetworkPing() * 1000
		-- Round trip from our own acks (includes the server's frame), and the
		-- latency the Hit Reg Lab is adding, if any.
		local simText = if NetSim.active()
			then string.format('  <font color="#%s">sim +%.0f ms</font>', Ui.hex(Ui.BAD), NetSim.settings.latency * 1000)
			else ""
		local stateText = if accurate
			then string.format('<font color="#%s">ACCURATE</font>', Ui.hex(Ui.GOOD))
			else string.format('<font color="#%s">MOVING ERROR</font>', Ui.hex(Ui.BAD))
		local flags = table.concat({
			if s.grounded then "ground" else "air",
			if s.crouched then "crouch" else "",
			if bit32.band(lastInput, B.Walk) ~= 0 then "walk" else "",
			if landPenalty then "LAND" else "",
		}, " ")
		-- The last time in the air: sideways is from where you faced when you
		-- left the ground, and the speeds are along the ground.
		local jumpLines = { "jump    --", "", "" }
		local j = lastJump
		if j then
			-- How far and which way, with no way when it rounds to nothing, so
			-- a straight jump doesn't read "0.00 m left" from float noise.
			local function across(x: number, format: string): string
				local text = string.format(format, math.abs(x))
				local shown = tonumber(string.match(text, "^[%d.]+"))
				return if shown == 0 then text elseif x > 0 then text .. " right" else text .. " left"
			end
			jumpLines = {
				string.format("jump    %.2f s  %.2f m  %s", j.airtime, j.distance, across(j.side, "%.2f m")),
				string.format("        path bent %s", across(j.bend, "%.0f\u{B0}")),
				string.format("        speed %.2f > %.2f m/s, top %.2f", j.takeoffSpeed, j.landingSpeed, j.peakSpeed),
			}
		end
		stats.Text = table.concat({
			string.format("<b>%s</b>  %s", controller.profile().name, stateText),
			string.format("speed   %5.2f m/s  %5.1f st/s", speed, speed * Units.STUDS_PER_METRE),
			string.format("of max  %5.1f%%   deadzone %.1f%% (%.2f m/s)", speed / info.maxSpeed * 100, info.accurateFraction * 100, threshold),
			string.format("vert    %5.2f m/s", s.velocity.y),
			string.format("state   %s", flags),
			string.format("pos     %.2f %.2f %.2f m", s.position.x, s.position.y, s.position.z),
			coneText,
			jumpLines[1],
			jumpLines[2],
			jumpLines[3],
			"",
			string.format("tick    %d Hz   fps %.0f", MovementConfig.TickRate.value, fps),
			string.format("rtt     %.0f ms   ping %.0f ms%s", net.rttSmooth * 1000, ping, simText),
			string.format("pending %d   sent %d   ack %d", net.pending, net.sentInputs, net.lastAckSeq),
			string.format("corrections %d   last %.1f mm   max %.1f mm", net.corrections, net.lastCorrectionError * 1000, net.maxCorrectionError * 1000),
			string.format('<font color="#%s">F2 labs  F3 hud  G ghost  F4 lab  F6 record  F10 hitboxes</font>', Ui.hex(Ui.DIM)),
		}, "\n")

		local serverSim = controller.serverSim
		local server = serverSim and serverSim.movement
		if ghostVisible and server then
			local h = MovementSim.boxHeight(server, cfg)
			local size = Vector3.new(cfg.halfWidth * 2, h, cfg.halfWidth * 2) * Units.STUDS_PER_METRE
			ghost.Size = size
			ghost.CFrame = CFrame.new(Units.toStuds(server.position) + Vector3.new(0, size.Y / 2, 0))
		end
	end)
end

return DebugHud
