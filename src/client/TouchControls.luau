--!strict
-- Touch controls (system 71): a phone or a tablet plays as TouchRules says,
-- on TouchConfig's layout, drawn over the view.
--
-- Once a frame, before the player's own render step samples the input:
--   * the buttons held and the stick become PlayerSim's flags, held for
--     each tick of the frame (InputSampler.touchSample), with the presses
--     among them latched as a key's are, so no tap is missed
--   * the look drags, and the fire buttons' touches as they move, turn the
--     view as the mouse does, in its counts (CameraController.touchCounts),
--     or move the cursor that has the mouse, a count a pixel: the ping
--     wheel's pick, the big map's cursor, From the Shadows' map's
--   * the buttons that aren't keys held do what their keys do: SPIKE and
--     SWAP draw a slot (PlayerController.selectSlot; SWAP held, the knife),
--     PING pings (PingView, held for the wheel), USE takes a gun off the
--     ground (GroundGunsView), and dead, FIRE and AIM switch who's watched
--     as the mouse buttons do and USE takes over the bot watched
--     (Spectate); with the big map up, FIRE pings on it as a left click
--     does. Down the left, BUY opens or shuts the buy menu (in Team
--     Deathmatch the loadouts), MAP the big map, SCORES the scoreboard,
--     AGENTS agent select, PLAY the Play menu and SETTINGS the settings
--   * with a menu up, CLOSE is the one button shown, and shuts it; the
--     rest of the screen is the menu's
-- A touch is the button it starts on until it's lifted. Roblox's own touch
-- controls are off (GuiService.TouchControlsEnabled), these being the
-- game's.
--
-- InputSampler.touchActive says whether the last input was a touch: the
-- buttons show only while it was, the mouse buttons and the mouse's turn
-- are left out, and the HUD's prompts name these buttons. In Studio,
-- TestAim's VFTestTouch stands in for a touch screen (TouchRules.parse),
-- and the player's VFTouch says what it's doing each frame, for checks:
-- "off" while it's not in use, else its flags (PlayerSim's), the zoom
-- predicted, its turn in the mouse's counts, whether it's crouched and
-- whether a menu's up, and the safe area's size in pixels ("flags=129
-- scoped=0 turn=12.5,0.0 crouch=0 menu=0 size=750x311").

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PadRules = require(Shared.Input.PadRules)
local PlayerSettings = require(Shared.Settings.PlayerSettings)
local Spike = require(Shared.Spike.Spike)
local SpikeSim = require(Shared.Spike.SpikeSim)
local TouchConfig = require(Shared.Input.TouchConfig)
local TouchRules = require(Shared.Input.TouchRules)

local AgentMenu = require(script.Parent.AgentMenu)
local BuyMenu = require(script.Parent.BuyMenu)
local CameraController = require(script.Parent.CameraController)
local ClientSettings = require(script.Parent.ClientSettings)
local GroundGunsView = require(script.Parent.GroundGunsView)
local InputSampler = require(script.Parent.InputSampler)
local LoadoutMenu = require(script.Parent.LoadoutMenu)
local MinimapView = require(script.Parent.MinimapView)
local PingView = require(script.Parent.PingView)
local PlayMenu = require(script.Parent.PlayMenu)
local PlayerController = require(script.Parent.PlayerController)
local Scoreboard = require(script.Parent.Scoreboard)
local SettingsMenu = require(script.Parent.SettingsMenu)
local Spectate = require(script.Parent.Spectate)
local Ui = require(script.Parent.Debug.Ui)

local P = TouchConfig.Params

local TouchControls = {}

-- A touch screen standing in for the real one (TestAim's VFTestTouch), nil
-- for the real one.
TouchControls.test = nil :: TouchRules.Test?

local KNIFE = 3 -- the knife's slot
local GOLD = Color3.fromRGB(230, 200, 120)
-- The buttons a touch that moves turns the view with.
local AIMING = { fire = true, fire2 = true }
local GAMEPADS: { [Enum.UserInputType]: boolean } = {}
for i = 1, 8 do
	GAMEPADS[(Enum.UserInputType :: any)["Gamepad" .. i]] = true
end

-- A finger on the screen: the button it started on, or the stick, or a
-- look; where it started and where it was last, in the safe area's pixels;
-- and whether it's been spent (held as a menu opened or shut), doing
-- nothing until it's lifted.
type Touch = { kind: "button" | "stick" | "look", name: string, start: Vector2, last: Vector2, spent: boolean }

local touches: { [InputObject]: Touch } = {}
local turned = Vector2.zero -- the look drags this frame, in pixels
local spots: { TouchRules.Spot } = {}
local frames: { [string]: Frame } = {}
local laidOut = ""
local wasHeld: { [string]: boolean } = {}
local swapHold = PadRules.newHold()
local crouched = false
local life = -1
local held = 0 -- this frame's flags
local mapOpen = false
local board = false -- the scoreboard opened by SCORES
local pinging = false -- PING held, as Z is
local wasMenu = false
local testing = false
local reported = ""
local unit = 4
local short = 400

local STUDIO = RunService:IsStudio()

-- What the touch screen's doing, for checks in Studio (VFTouch).
local function report(text: string)
	if text ~= reported then
		reported = text
		Players.LocalPlayer:SetAttribute("VFTouch", text)
	end
end

local function closeMenus()
	BuyMenu.setOpen(false)
	LoadoutMenu.setOpen(false)
	AgentMenu.setOpen(false)
	SettingsMenu.setOpen(false)
	PlayMenu.setOpen(false)
end

-- The column's buttons, as their keys do.
local MENUS: { [string]: () -> () } = {
	buy = function()
		BuyMenu.setOpen(not BuyMenu.open)
		LoadoutMenu.setOpen(not LoadoutMenu.open)
	end,
	map = function()
		mapOpen = not mapOpen
		MinimapView.setBig(mapOpen)
	end,
	scores = function()
		board = not board
		Scoreboard.held = board
	end,
	agents = function()
		AgentMenu.setOpen(not AgentMenu.open)
	end,
	play = function()
		PlayMenu.setOpen(not PlayMenu.open)
	end,
	settings = function()
		SettingsMenu.setOpen(not SettingsMenu.open)
	end,
}

-- Nothing from the touch screen's play: no flags, no turn, PING let go,
-- and every finger spent until it's lifted.
local function stop()
	held = 0
	turned = Vector2.zero
	CameraController.touchCounts = Vector2.zero
	if pinging then
		pinging = false
		PingView.release()
	end
	for _, touch in touches do
		touch.spent = true
	end
end

local gui: ScreenGui
local root: Frame
local probe: Frame -- the whole screen's, without the safe area's insets
local base: Frame -- the stick's
local knob: Frame

local function round(parent: Instance, name: string): Frame
	local f = Ui.frame(parent, { Name = name, BackgroundTransparency = 0.55 })
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = f
	return f
end

local function newButton(spot: TouchRules.Spot): Frame
	local f = if spot.round then round(root, spot.name) else Ui.frame(root, { Name = spot.name, BackgroundTransparency = 0.55 })
	if not spot.round then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.25, 0)
		corner.Parent = f
	end
	local stroke = Instance.new("UIStroke")
	stroke.Color = Ui.TEXT
	stroke.Transparency = 0.55
	stroke.Thickness = 1.5
	stroke.Parent = f
	local label = Ui.label(f, {
		Name = "Label",
		Text = spot.label,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.78, 0.36),
	})
	local most = Instance.new("UITextSizeConstraint")
	most.MaxTextSize = if spot.name == "fire" or spot.name == "fire2" then 20 else 14
	most.Parent = label
	return f
end

-- The buttons laid out afresh for the safe area as it is now, where it's
-- changed: its size, the unit, the minimap's bottom, or the HUD's band.
local function layOut()
	local camera = Workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	short = math.max(math.min(viewport.X, viewport.Y), 1)
	unit = short / 100
	local size, at = root.AbsoluteSize, root.AbsolutePosition - probe.AbsolutePosition
	local whole = probe.AbsoluteSize
	local top = MinimapView.bottom()
	local key = string.format("%d %d %d %d %d %d %d %d", size.X, size.Y, at.X, at.Y, whole.X, whole.Y, short, top)
	if key == laidOut then
		return
	end
	laidOut = key
	spots = TouchRules.layout(size.X, size.Y, unit, top, TouchRules.band(whole.X, whole.Y, at.X, at.Y))
	for _, spot in spots do
		local f = frames[spot.name]
		if not f then
			f = newButton(spot)
			frames[spot.name] = f
		end
		f.Size = UDim2.fromOffset(spot.w, spot.h)
		f.Position = UDim2.fromOffset(spot.x - spot.w / 2, spot.y - spot.h / 2)
	end
	local across = 2 * P.stickRadius.value * unit
	base.Size = UDim2.fromOffset(across, across)
	knob.Size = UDim2.fromOffset(2 * P.knob.value * unit, 2 * P.knob.value * unit)
end

-- Whether a button shows now: with a menu up only CLOSE, else all but
-- CLOSE, and SPIKE only while you carry the spike.
local function showing(name: string, menu: boolean): boolean
	if menu or name == "close" then
		return menu and name == "close"
	elseif name == "spike" then
		local s = PlayerController.sim
		return s ~= nil and SpikeSim.carrying(s.weapons)
	end
	return true
end

-- Where a touch is in the safe area, in pixels.
local function at(input: InputObject): Vector2
	return Vector2.new(input.Position.X, input.Position.Y) - root.AbsolutePosition
end

local function began(input: InputObject, processed: boolean)
	if processed or UserInputService:GetFocusedTextBox() then
		return
	end
	local where = at(input)
	local menu = CameraController.cursorFree
	local spot = TouchRules.hit(spots, where.X, where.Y, function(name)
		return showing(name, menu)
	end)
	if menu then
		if spot and spot.name == "close" then
			closeMenus()
		end
		return
	end
	local kind: "button" | "stick" | "look" = "look"
	if spot then
		kind = "button"
	elseif TouchRules.zone(root.AbsoluteSize.X, where.X) == "stick" then
		kind = "stick"
		for _, touch in touches do
			if touch.kind == "stick" then
				kind = "look"
			end
		end
	end
	touches[input] = { kind = kind, name = if spot then spot.name else "", start = where, last = where, spent = false }
end

-- Whose the last input was: a touch's, else the keys', the mouse's or a
-- gamepad's, which take the touch screen's place.
local function onInput(input: InputObject, processed: boolean)
	local kind = input.UserInputType
	if kind == Enum.UserInputType.Touch then
		InputSampler.touchActive = true
		if input.UserInputState == Enum.UserInputState.Begin then
			began(input, processed)
		elseif input.UserInputState == Enum.UserInputState.Change then
			local touch = touches[input]
			if touch then
				local where = at(input)
				if not touch.spent and (touch.kind == "look" or AIMING[touch.name]) then
					turned += where - touch.last
				end
				touch.last = where
			end
		end
	elseif kind == Enum.UserInputType.Keyboard or GAMEPADS[kind] then
		InputSampler.touchActive = false
	elseif kind == Enum.UserInputType.MouseMovement and UserInputService.MouseEnabled then
		if input.Delta.Magnitude > 4 then
			InputSampler.touchActive = false
		end
	end
end

local function frame(dt: number)
	local now = os.clock()
	local test = TouchControls.test
	if test then
		testing = true
		InputSampler.touchActive = true
	elseif testing then
		testing = false
		InputSampler.touchActive = false
	end
	if not InputSampler.touchActive or UserInputService:GetFocusedTextBox() then
		stop()
		table.clear(touches)
		table.clear(wasHeld)
		if board then
			board = false
			Scoreboard.held = false
		end
		gui.Enabled = false
		if STUDIO then
			report("off")
		end
		return
	end
	gui.Enabled = true
	layOut()

	local menu = CameraController.cursorFree
	for name, f in frames do
		f.Visible = showing(name, menu)
	end
	if menu ~= wasMenu then
		-- Opened or shut: what's held does nothing until it's lifted.
		wasMenu = menu
		stop()
	end

	-- What's held: the buttons, the stick's tilt and the look drag.
	local holding: { [string]: boolean } = {}
	local sx, sy = 0, 0
	local drag = turned
	turned = Vector2.zero
	local stickAt: Touch? = nil
	if test then
		for name in test.buttons do
			holding[name] = true
		end
		sx, sy = test.x, test.y
		drag = Vector2.new(test.lx, -test.ly) * (short * dt)
	else
		for _, touch in touches do
			if touch.spent then
				continue
			elseif touch.kind == "button" then
				holding[touch.name] = true
			elseif touch.kind == "stick" then
				stickAt = touch
				local d = touch.last - touch.start
				sx, sy = TouchRules.stick(d.X, d.Y, P.stickRadius.value * unit)
			end
		end
	end
	local function pressed(name: string): boolean
		return holding[name] == true and not wasHeld[name]
	end
	if menu then
		-- A scripted check's CLOSE (a real one's is taken as it starts).
		if pressed("close") then
			closeMenus()
		end
		wasHeld = holding
		holding = {}
		sx, sy, drag = 0, 0, Vector2.zero
	end

	if PlayerController.life ~= life then
		life = PlayerController.life
		crouched = false
	end
	if pressed("crouch") then
		crouched = not crouched
	end
	for name, open in MENUS do
		if pressed(name) then
			open()
		end
	end
	if pressed("ping") then
		pinging = true
		PingView.press()
	elseif pinging and not holding.ping then
		pinging = false
		PingView.release()
	end
	if pressed("spike") then
		PlayerController.selectSlot(Spike.SLOT)
	end
	local firing = pressed("fire") or pressed("fire2")
	if PingView.view ~= nil and firing then
		PingView.test("map")
	end
	local s = PlayerController.sim
	local alive = s ~= nil and PlayerController.alive
	if s and alive then
		if pressed("use") then
			GroundGunsView.take()
		end
		local swap = PadRules.hold(swapHold, holding.swap == true, now)
		if swap == "tap" then
			PlayerController.selectSlot(PadRules.swap(s.weapons.equipped, s.weapons.loadout))
		elseif swap == "hold" then
			PlayerController.selectSlot(KNIFE)
		end
	else
		if firing then
			Spectate.step(1)
		end
		if pressed("aim") then
			Spectate.step(-1)
		end
		if pressed("use") then
			Spectate.takeControl()
		end
	end
	if not menu then
		wasHeld = holding
	end
	local flags = if menu then 0 else TouchRules.flags(holding, sx, sy, crouched, alive)
	InputSampler.touchPress(bit32.band(flags, bit32.bnot(held)))
	held = flags

	-- The look drag: the cursor that has the mouse, else the view.
	if CameraController.mapCursor then
		CameraController.touchCounts = drag
	else
		local settings = ClientSettings.current
		local perCount = PlayerSettings.degreesPerCount(CameraController.sensitivity, CameraController.scopedMultiplier, 1)
		local cx, cy = TouchRules.look(drag.X, drag.Y, short, settings.touchLook, perCount)
		CameraController.touchCounts = Vector2.new(cx, cy)
	end

	-- How it looks: what's held pressed in, what's on lit.
	for name, f in frames do
		local down = holding[name] == true
		local lit = (name == "crouch" and crouched) or (name == "map" and mapOpen) or (name == "scores" and board)
		f.BackgroundTransparency = if down then 0.25 else 0.55
		local stroke = f:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if lit then GOLD else Ui.TEXT
			stroke.Transparency = if down or lit then 0.1 else 0.55
		end
	end
	base.Visible = stickAt ~= nil
	knob.Visible = stickAt ~= nil
	if stickAt then
		local radius = P.stickRadius.value * unit
		base.Position = UDim2.fromOffset(stickAt.start.X - radius, stickAt.start.Y - radius)
		local k = stickAt.start + Vector2.new(sx, -sy) * radius
		knob.Position = UDim2.fromOffset(k.X - knob.Size.X.Offset / 2, k.Y - knob.Size.Y.Offset / 2)
	end

	if STUDIO then
		local counts = CameraController.touchCounts
		local size = root.AbsoluteSize
		report(
			string.format(
				"flags=%d scoped=%s turn=%.1f,%.1f crouch=%d menu=%d size=%dx%d",
				held,
				if s then tostring(s.weapons.scoped) else "-",
				counts.X,
				counts.Y,
				if crouched then 1 else 0,
				if menu then 1 else 0,
				size.X,
				size.Y
			)
		)
	end
end

-- The touch screen's flags for one tick: this frame's.
local function sample(): number
	return held
end

function TouchControls.start()
	if not UserInputService.TouchEnabled and not STUDIO then
		return
	end
	if UserInputService.TouchEnabled then
		pcall(function()
			GuiService.TouchControlsEnabled = false
		end)
		-- A phone or a tablet with nothing else to play with starts on
		-- touch; anything else waits for a touch.
		InputSampler.touchActive = not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
	end
	-- Under the HUD and the menus, which a touch on them is for.
	gui = Ui.screen("VFTouch", 14)
	gui.Enabled = false
	root = Ui.frame(gui, { Name = "Safe", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	local whole = Ui.screen("VFTouchScreen", 0, Enum.ScreenInsets.None)
	probe = Ui.frame(whole, { Name = "Screen", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	base = round(root, "Stick")
	base.BackgroundTransparency = 0.75
	base.Visible = false
	knob = round(root, "Knob")
	knob.BackgroundColor3 = Ui.TEXT
	knob.BackgroundTransparency = 0.6
	knob.Visible = false

	InputSampler.touchSample = sample
	UserInputService.InputBegan:Connect(onInput)
	UserInputService.InputChanged:Connect(onInput)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		touches[input] = nil
	end)
	-- Before the player's own render step (Camera + 1), which samples the
	-- input, as the gamepad's is.
	RunService:BindToRenderStep("VFTouch", Enum.RenderPriority.Input.Value, frame)
end

return TouchControls
