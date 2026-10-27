--!strict
-- The crosshair (system 11), drawn from the player's crosshair code
-- (ClientSettings, Crosshair): the primary crosshair, the one for aiming down
-- sights while zoomed in a little, and the sniper scope's centre dot while
-- scoped, when the scope takes the place of the rest.
--
-- Lines set to show movement error or firing error move out by that part of
-- the next shot's cone, as big as it is on screen: the movement error with
-- the landing penalty, and what the spray has added to the first shot's
-- firing error. The knife has no cone, so its crosshair stays still.
--
-- Outlines are drawn as a ring round each piece, under all of the pieces, so
-- lines that meet show one outline round the lot and a see-through line
-- isn't darkened by its own outline.
--
-- Flying the Owl Drone (system 47), the primary crosshair is green, still
-- (Patch 4.08: 'Changed crosshair color to green to better stand out
-- against the white HUD'), as its darts go exactly along it.
--
-- Hidden while a menu has the cursor, and while dead.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Crosshair = require(Shared.Settings.Crosshair)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local Accuracy = require(Shared.Weapons.Accuracy)
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)

local CameraController = require(script.Parent.CameraController)
local ClientSettings = require(script.Parent.ClientSettings)
local Ui = require(script.Parent.Debug.Ui)

local DT = 1 / MovementConfig.TickRate.value

type Piece = { fill: Frame, ring: { Frame }, last: Crosshair.Rect? }
export type Drawing = { pieces: { Piece }, color: Color3? }

local CrosshairView = {}

-- What was drawn last, for the debug HUD: "P", "A", "S" (the sniper dot) or
-- "" (nothing), and how far the errors moved the lines out.
CrosshairView.shown = ""
CrosshairView.movementDegrees = 0
CrosshairView.firingDegrees = 0
CrosshairView.movementPixels = 0
CrosshairView.firingPixels = 0

local BLACK = Color3.new(0, 0, 0)

local function color3(rgb: Crosshair.Rgb): Color3
	return Color3.fromRGB(rgb.r, rgb.g, rgb.b)
end

-- The pieces of a crosshair, centred on `parent`'s top left corner (so put
-- `parent` where the middle should be).
function CrosshairView.build(parent: GuiObject): Drawing
	local pieces: { Piece } = {}
	for _, name in Crosshair.PIECES do
		local ring = {}
		for side = 1, 4 do
			table.insert(
				ring,
				Ui.frame(parent, {
					Name = name .. "Outline" .. side,
					BackgroundColor3 = BLACK,
					Visible = false,
					ZIndex = 2,
				})
			)
		end
		local fill = Ui.frame(parent, {
			Name = name,
			Visible = false,
			ZIndex = 3,
		})
		table.insert(pieces, { fill = fill, ring = ring, last = nil })
	end
	return { pieces = pieces, color = nil }
end

local function sameRect(a: Crosshair.Rect?, b: Crosshair.Rect): boolean
	return a ~= nil
		and a.x == b.x
		and a.y == b.y
		and a.w == b.w
		and a.h == b.h
		and a.alpha == b.alpha
		and a.outline == b.outline
		and a.outlineAlpha == b.outlineAlpha
end

local function place(frame: Frame, x: number, y: number, w: number, h: number)
	frame.Position = UDim2.fromOffset(x, y)
	frame.Size = UDim2.fromOffset(w, h)
end

-- Draws a profile, moved out by the errors (in pixels) and faded (0 to 1)
-- as Crosshair.shape says.
function CrosshairView.draw(d: Drawing, p: Crosshair.Profile, movementPixels: number, firingPixels: number, fade: number)
	local color = color3(p.color)
	local recolour = d.color ~= color
	d.color = color
	local rects = Crosshair.shape(p, movementPixels, firingPixels, fade)
	for i, piece in d.pieces do
		local r = rects[i]
		if recolour then
			piece.fill.BackgroundColor3 = color
		end
		if sameRect(piece.last, r) then
			continue
		end
		piece.last = r
		local shown = r.w > 0 and r.h > 0
		piece.fill.Visible = shown
		local t = if shown then r.outline else 0
		for _, strip in piece.ring do
			strip.Visible = t > 0
			strip.BackgroundTransparency = 1 - r.outlineAlpha
		end
		if not shown then
			continue
		end
		place(piece.fill, r.x, r.y, r.w, r.h)
		piece.fill.BackgroundTransparency = 1 - r.alpha
		if t > 0 then
			local ring = piece.ring
			place(ring[1], r.x - t, r.y - t, r.w + 2 * t, t)
			place(ring[2], r.x - t, r.y + r.h, r.w + 2 * t, t)
			place(ring[3], r.x - t, r.y, t, r.h)
			place(ring[4], r.x + r.w, r.y, t, r.h)
		end
	end
end

function CrosshairView.hide(d: Drawing)
	for _, piece in d.pieces do
		piece.last = nil
		piece.fill.Visible = false
		for _, strip in piece.ring do
			strip.Visible = false
		end
	end
end

-- The zoom the weapon in hand is at: 1 unzoomed.
local function zoomOf(sim: PlayerSim.State): number
	local w = sim.weapons
	local def = PlayerSim.def(sim)
	if w.scoped > 0 and def.ads then
		return def.ads.zoom[w.scoped] or 1
	end
	return 1
end

-- The next shot's movement error and the firing error the spray has added,
-- in degrees.
local function errors(sim: PlayerSim.State, buttons: number, cfg: any): (number, number)
	local def = PlayerSim.def(sim)
	if def.fireMode == "none" then
		return 0, 0
	end
	local w = sim.weapons
	local now = sim.movement.tick * DT
	local bullet, _, mode = Accuracy.next(def, w, now, DT)
	local ctx = PlayerSim.accuracyContext(sim, buttons, cfg, DT)
	local cone = Accuracy.cone(mode.accuracy, ctx, bullet)
	local first = Accuracy.cone(mode.accuracy, ctx, 1)
	return cone.movement + cone.landing, math.max((cone.curve - first.curve) * cone.crouchMultiplier, 0)
end

function CrosshairView.start(controller: any)
	local gui = Ui.screen("VFPlayerCrosshair", 17, Enum.ScreenInsets.None)
	local centre = Ui.frame(gui, {
		Name = "Centre",
		Size = UDim2.fromOffset(0, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	})
	local drawing = CrosshairView.build(centre)
	local sniper = Ui.frame(centre, {
		Name = "SniperDot",
		Visible = false,
		ZIndex = 3,
	})
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = sniper

	local primary: Crosshair.Profile, ads: Crosshair.Profile, sniperDot: Crosshair.SniperDot, adsOwn: boolean
	local flying: Crosshair.Profile
	local function read()
		local code = ClientSettings.code
		primary = Crosshair.profile(code, "P")
		flying = table.clone(primary)
		flying.color = Crosshair.COLORS[1].rgb
		flying.colorName = Crosshair.COLORS[1].name
		ads = Crosshair.adsProfile(code)
		adsOwn = Crosshair.advanced(code) and Crosshair.hasSection(code, "A")
		sniperDot = Crosshair.sniperDot(code)
	end
	read()
	table.insert(ClientSettings.listeners, read)

	local buttons = 0
	table.insert(controller.tickListeners, function(info: any)
		buttons = info.input.buttons
	end)

	RunService.RenderStepped:Connect(function()
		local sim: PlayerSim.State? = controller.sim
		if not sim or not controller.alive or CameraController.cursorFree then
			CrosshairView.shown = ""
			CrosshairView.hide(drawing)
			sniper.Visible = false
			return
		end
		local zoom = zoomOf(sim)
		if zoom >= 2 then
			-- The scope (CombatHud) is up: its centre dot only.
			CrosshairView.shown = if sniperDot.show then "S" else ""
			CrosshairView.hide(drawing)
			local size = math.max(math.floor(sniperDot.thickness * Crosshair.SNIPER_DOT_PIXELS + 0.5), 1)
			sniper.Visible = sniperDot.show and sniperDot.opacity > 0
			sniper.BackgroundColor3 = color3(sniperDot.color)
			sniper.BackgroundTransparency = 1 - sniperDot.opacity
			sniper.Size = UDim2.fromOffset(size, size)
			sniper.Position = UDim2.fromOffset(-math.floor(size / 2), -math.floor(size / 2))
			return
		end
		sniper.Visible = false
		local droning = AbilitySim.droning(sim.abilities)
		local profile = if droning then flying elseif zoom > 1 then ads else primary
		CrosshairView.shown = if zoom > 1 and adsOwn then "A" else "P"

		local movement, firing = 0, 0
		if not droning then
			movement, firing = errors(sim, buttons, controller.cfg)
		end
		local viewport = Workspace.CurrentCamera.ViewportSize
		local pixelsPerTan = viewport.X / 2 / math.tan(math.rad(CameraController.zoomedFov(zoom)) / 2)
		local movementPixels = math.tan(math.rad(movement)) * pixelsPerTan
		local firingPixels = math.tan(math.rad(firing)) * pixelsPerTan
		CrosshairView.movementDegrees, CrosshairView.firingDegrees = movement, firing
		CrosshairView.movementPixels, CrosshairView.firingPixels = movementPixels, firingPixels
		CrosshairView.draw(drawing, profile, movementPixels, firingPixels, Crosshair.fadeFor(firing))
	end)
end

return CrosshairView
