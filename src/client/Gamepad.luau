--!strict
-- Controller support (system 68): a gamepad plays as PadRules says, on the
-- reference's console layout, and works the menus.
--
-- Once a frame, before the player's own render step samples the input:
--   * the pad last used is read (Gamepad1 to begin with), and its sticks
--     and buttons become PlayerSim's flags, held for each tick of the
--     frame (InputSampler.padSample), with the presses among them latched
--     as a key's are, so no tap is missed
--   * the right stick turns the view as the mouse does, in its counts
--     (CameraController.padCounts), at the player's look speed; or moves
--     the cursor that has the mouse: the ping wheel's pick, the big map's
--     cursor, From the Shadows' map's
--   * LT drives the zoom by pressing alt fire a tick at a time until the
--     predicted zoom is the one wanted, and letting the zoom go to come
--     down (PadRules.pulse), so a sniper's scope is held as LT is, and the
--     server sees the same presses
--   * Y, the D-pad and RS do what their keys do: draw a slot
--     (PlayerController.selectSlot), ping (PingView, held for the wheel),
--     take a gun off the ground (GroundGunsView), and dead, take over the
--     bot watched (Spectate), where RT and LT switch as the mouse buttons
--     do; with the big map up, RT pings on it as a left click does
--   * Select tapped opens or shuts the big map (MinimapView), and held,
--     shows the scoreboard; with D-pad Up, Left, Right or Down it opens or
--     shuts the Play menu (M), agent select (T), the settings (O) or the
--     combat report (N). D-pad Right alone is B: the buy menu, or in Team
--     Deathmatch the loadouts
--   * with a menu up, the pad is Roblox's gamepad cursor's instead
--     (GamepadService: the left stick moves it, A clicks), or where the
--     place has that off, the menu's buttons are picked with the D-pad
--     (GuiService:Select); B shuts the menu. A button held as a menu shuts
--     does nothing until it's let go, so the A that pressed PLAY doesn't
--     jump
-- Roblox's own use of Select, to start picking buttons
-- (GuiService.AutoSelectGuiEnabled), is off, as Select is ours here.
--
-- InputSampler.padActive says whether the last input was the pad's (a
-- stick past its dead zone, a trigger past its own, or a button): nothing
-- comes from the pad while the mouse and keys are in use, and the HUD's
-- prompts name the pad's buttons while it is. In Studio, TestAim's
-- VFTestPad stands in for a pad (PadRules.parse), and the player's VFPad
-- says what the pad's doing each frame, for checks: "off" while it's not
-- in use, else its flags (PlayerSim's), the zoom LT wants ("-" where it
-- leaves it alone) and the zoom predicted, whether it's Focus, its turn in
-- the mouse's counts, and how a menu's buttons are picked: "on" with
-- Roblox's gamepad cursor on, "pick" with one picked for the D-pad, else
-- "off" ("flags=129 zoom=- scoped=0 focus=0 turn=12.5,0.0 cursor=off").

local GamepadService = game:GetService("GamepadService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PadConfig = require(Shared.Input.PadConfig)
local PadRules = require(Shared.Input.PadRules)
local PlayerSettings = require(Shared.Settings.PlayerSettings)
local PlayerSim = require(Shared.PlayerSim)
local Spike = require(Shared.Spike.Spike)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

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
local ReportView = require(script.Parent.ReportView)
local Scoreboard = require(script.Parent.Scoreboard)
local SettingsMenu = require(script.Parent.SettingsMenu)
local Spectate = require(script.Parent.Spectate)

local B = PlayerSim.Buttons
local P = PadConfig.Params

local Gamepad = {}

-- A pad standing in for the real one (TestAim's VFTestPad), nil for the
-- real one.
Gamepad.test = nil :: PadRules.Pad?

local KNIFE = 3 -- the knife's slot
-- Each button's key, by its name in a Pad (the triggers are read apart).
local KEYS: { [string]: Enum.KeyCode } = {
	a = Enum.KeyCode.ButtonA,
	b = Enum.KeyCode.ButtonB,
	x = Enum.KeyCode.ButtonX,
	y = Enum.KeyCode.ButtonY,
	lb = Enum.KeyCode.ButtonL1,
	rb = Enum.KeyCode.ButtonR1,
	l3 = Enum.KeyCode.ButtonL3,
	r3 = Enum.KeyCode.ButtonR3,
	up = Enum.KeyCode.DPadUp,
	down = Enum.KeyCode.DPadDown,
	left = Enum.KeyCode.DPadLeft,
	right = Enum.KeyCode.DPadRight,
	select = Enum.KeyCode.ButtonSelect,
}
local GAMEPADS: { [Enum.UserInputType]: boolean } = {}
for i = 1, 8 do
	GAMEPADS[(Enum.UserInputType :: any)["Gamepad" .. i]] = true
end
-- The menus' screens, the first open of which has its buttons picked with
-- the D-pad where the gamepad cursor is off.
local MENUS = { "VFSettingsMenu", "VFBuyMenu", "VFLoadouts", "VFAgents", "VFPlay", "VFVote" }
-- Select with the D-pad: the menu each opens or shuts, as its key does.
local SELECT_MENUS: { [string]: () -> () } = {
	up = function()
		PlayMenu.setOpen(not PlayMenu.open)
	end,
	left = function()
		AgentMenu.setOpen(not AgentMenu.open)
	end,
	right = function()
		SettingsMenu.setOpen(not SettingsMenu.open)
	end,
	down = function()
		ReportView.toggle()
	end,
}

local pad = Enum.UserInputType.Gamepad1
local last = PadRules.newPad() -- last frame's
-- Buttons held as a menu shut, or taken by Select: nothing until let go.
local stale: { [string]: boolean } = {}
local bumpers = PadRules.newBumpers()
local look = PadRules.newLook()
local aim = PadRules.newAim()
local yHold = PadRules.newHold()
local selectHold = PadRules.newHold()
local crouched = false
local life = -1
local held = 0 -- this frame's flags
local wanted: number? = nil -- the zoom LT wants, if it drives it
local pulsed = false -- alt fire pressed for the zoom last tick
local mapOpen = false
local board = false -- the scoreboard held open by Select
local pinging = false -- D-pad Up held, as Z is
local cursorOn = false
local picking = false -- a menu's buttons picked with the D-pad
local shown = "off" -- how a menu's buttons are picked, for VFPad
local wasMenu = false
local testing = false
local reported = ""

local STUDIO = RunService:IsStudio()

-- What the pad's doing, for checks in Studio (VFPad).
local function report(text: string)
	if text ~= reported then
		reported = text
		Players.LocalPlayer:SetAttribute("VFPad", text)
	end
end

-- A turn to the tenth, as the report has it: never "-0.0".
local function tenths(x: number): number
	return math.round(x * 10) / 10 + 0
end

-- The zoom predicted for the weapon in hand, for VFPad.
local function scopedText(): string
	local s = PlayerController.sim
	return if s then tostring(s.weapons.scoped) else "-"
end

local function read(): PadRules.Pad
	local test = Gamepad.test
	if test then
		local copy = table.clone(test)
		copy.buttons = table.clone(test.buttons)
		return copy
	end
	local out = PadRules.newPad()
	if not UserInputService:GetGamepadConnected(pad) then
		return out
	end
	for _, input in UserInputService:GetGamepadState(pad) do
		local at = input.Position
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			out.lx, out.ly = at.X, at.Y
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
			out.rx, out.ry = at.X, at.Y
		elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
			out.lt = at.Z
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
			out.rt = at.Z
		end
	end
	for name, key in KEYS do
		if UserInputService:IsGamepadButtonDown(pad, key) then
			out.buttons[name] = true
		end
	end
	-- A trigger that only says it's down, as some pads' do.
	if UserInputService:IsGamepadButtonDown(pad, Enum.KeyCode.ButtonL2) then
		out.lt = math.max(out.lt, 1)
	end
	if UserInputService:IsGamepadButtonDown(pad, Enum.KeyCode.ButtonR2) then
		out.rt = math.max(out.rt, 1)
	end
	return out
end

-- Whose the last input was: the pad's for a button, or a stick or a trigger
-- past its dead zone; the mouse's and the keys' for theirs.
local function onInput(input: InputObject)
	local kind = input.UserInputType
	if GAMEPADS[kind] then
		local key, at = input.KeyCode, input.Position
		if key == Enum.KeyCode.Thumbstick1 or key == Enum.KeyCode.Thumbstick2 then
			if math.sqrt(at.X * at.X + at.Y * at.Y) < P.moveDead.value then
				return
			end
		elseif key == Enum.KeyCode.ButtonL2 or key == Enum.KeyCode.ButtonR2 then
			if at.Z < P.trigger.value and input.UserInputState ~= Enum.UserInputState.Begin then
				return
			end
		end
		pad = kind
		InputSampler.padActive = true
	elseif kind == Enum.UserInputType.MouseMovement then
		if input.Delta.Magnitude > 4 then
			InputSampler.padActive = false
		end
	elseif
		kind == Enum.UserInputType.Keyboard
		or kind == Enum.UserInputType.MouseButton1
		or kind == Enum.UserInputType.MouseButton2
		or kind == Enum.UserInputType.MouseButton3
		or kind == Enum.UserInputType.MouseWheel
		or kind == Enum.UserInputType.Touch
	then
		InputSampler.padActive = false
	end
end

local function closeMenus()
	BuyMenu.setOpen(false)
	LoadoutMenu.setOpen(false)
	AgentMenu.setOpen(false)
	SettingsMenu.setOpen(false)
	PlayMenu.setOpen(false)
end

-- B's menus, as B does: the buy menu, or in Team Deathmatch the loadouts.
local function toggleBuy()
	BuyMenu.setOpen(not BuyMenu.open)
	LoadoutMenu.setOpen(not LoadoutMenu.open)
end

-- The first menu's screen that's open.
local function openScreen(): ScreenGui?
	local gui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return nil
	end
	for _, name in MENUS do
		local screen = gui:FindFirstChild(name)
		if screen and screen:IsA("ScreenGui") and screen.Enabled then
			return screen
		end
	end
	return nil
end

-- The gamepad cursor while a menu's up and the pad's in use, else none;
-- where the place has it off, the menu's buttons picked with the D-pad.
local function point(menu: boolean)
	local want = menu and InputSampler.padActive
	if want ~= cursorOn then
		cursorOn = want
		pcall(function()
			if want then
				GamepadService:EnableGamepadCursor(nil)
			else
				GamepadService:DisableGamepadCursor()
			end
		end)
	end
	local enabled = false
	pcall(function()
		enabled = GamepadService.GamepadCursorEnabled
	end)
	if want and not enabled and GuiService.SelectedObject == nil then
		local screen = openScreen()
		if screen then
			picking = true
			pcall(function()
				GuiService:Select(screen)
			end)
		end
	elseif not want and picking then
		picking = false
		GuiService.SelectedObject = nil
	end
	shown = if enabled then "on" elseif picking and GuiService.SelectedObject ~= nil then "pick" else "off"
end

-- Nothing from the pad's play: no flags, no zoom, no turn, and Z let go.
local function stop()
	held, wanted = 0, nil
	CameraController.padCounts = Vector2.zero
	look.full = 0
	if pinging then
		pinging = false
		PingView.release()
	end
end

local function frame(dt: number)
	local now = os.clock()
	if Gamepad.test then
		testing = true
		InputSampler.padActive = true
	elseif testing then
		testing = false
		InputSampler.padActive = false
	end
	local p = read()
	p.buttons.lt = p.lt > P.trigger.value
	p.buttons.rt = p.rt > P.trigger.value
	local was = last
	last = p
	for name in stale do
		if not p.buttons[name] then
			stale[name] = nil
		end
	end
	local function down(name: string): boolean
		return p.buttons[name] == true and not stale[name]
	end
	local function pressed(name: string): boolean
		return down(name) and not was.buttons[name]
	end

	local menu = CameraController.cursorFree
	point(menu)
	if not InputSampler.padActive or UserInputService:GetFocusedTextBox() then
		stop()
		if board then
			board = false
			Scoreboard.held = false
		end
		if STUDIO then
			report("off")
		end
		return
	end

	-- Select: tapped, the big map; held, the scores; with the D-pad, a menu,
	-- and then neither.
	local selecting = down("select")
	if PadRules.hold(selectHold, selecting, now) == "tap" and not menu then
		mapOpen = not mapOpen
		MinimapView.setBig(mapOpen)
	end
	for dir, open in SELECT_MENUS do
		if selecting and pressed(dir) then
			open()
			selectHold.taken, selectHold.held = true, false
			stale[dir] = true
		end
	end
	if selectHold.held ~= board then
		board = selectHold.held
		Scoreboard.held = board
	end

	if menu then
		stop()
		if pressed("b") then
			closeMenus()
		end
		wasMenu = true
		if STUDIO then
			report(string.format("flags=0 zoom=- scoped=%s focus=0 turn=0.0,0.0 cursor=%s", scopedText(), shown))
		end
		return
	end
	if wasMenu then
		-- Shut: what's held does nothing until it's let go.
		wasMenu = false
		for name, on in p.buttons do
			if on then
				stale[name] = true
			end
		end
	end

	if PlayerController.life ~= life then
		life = PlayerController.life
		crouched = false
	end
	local flags, walk = PadRules.move(p.lx, p.ly)
	if pressed("l3") then
		crouched = not crouched
	end
	if crouched then
		flags = bit32.bor(flags, B.Crouch)
	end
	if down("a") then
		flags = bit32.bor(flags, B.Jump)
	end
	if down("x") then
		flags = bit32.bor(flags, B.Reload)
	end
	if down("b") then
		flags = bit32.bor(flags, B.AbilityC)
	end
	local bumped, taps = PadRules.bumpers(bumpers, down("lb"), down("rb"), now)
	flags = bit32.bor(flags, bumped)
	if not selecting then
		if down("down") then
			flags = bit32.bor(flags, B.Use)
		end
		if pressed("down") then
			PlayerController.selectSlot(Spike.SLOT)
		end
		if down("left") then
			flags = bit32.bor(flags, B.Drop)
		end
		if pressed("right") then
			toggleBuy()
		end
		if pressed("up") then
			pinging = true
			PingView.press()
		end
	end
	if pinging and not down("up") then
		pinging = false
		PingView.release()
	end

	-- The weapon in hand: LT and RS, RT, and Y.
	local s = PlayerController.sim
	local focus = false
	wanted = nil
	if PingView.view ~= nil and pressed("rt") then
		PingView.test("map")
	end
	if s and PlayerController.alive then
		local def = PlayerSim.def(s)
		local levels = if def.ads then #def.ads.zoom else 0
		local hasAlt = WeaponConfig.altMode(def) ~= nil
		local role: PadRules.Role = PadRules.role(def.category, def.ads ~= nil, hasAlt, s.abilities.holding ~= 0)
		local zoom, alt, inFocus, taken = PadRules.aim(aim, role, def.id, levels, down("lt"), down("r3"), pressed("r3"))
		wanted, focus = zoom, inFocus
		if alt then
			flags = bit32.bor(flags, B.AltFire)
		end
		if not taken then
			if down("r3") then
				flags = bit32.bor(flags, B.Interact)
			end
			if pressed("r3") then
				GroundGunsView.take()
			end
		end
		if down("rt") then
			flags = bit32.bor(flags, B.Fire)
		end
		local y = PadRules.hold(yHold, down("y"), now)
		if y == "tap" then
			PlayerController.selectSlot(PadRules.swap(s.weapons.equipped, s.weapons.loadout))
		elseif y == "hold" then
			PlayerController.selectSlot(KNIFE)
		end
	else
		if pressed("rt") then
			Spectate.step(1)
		end
		if pressed("lt") then
			Spectate.step(-1)
		end
		if pressed("r3") then
			Spectate.takeControl()
		end
	end
	local settings = ClientSettings.current
	if walk or (focus and settings.padWalk) then
		flags = bit32.bor(flags, B.Walk)
	end
	InputSampler.padPress(bit32.bor(bit32.band(flags, bit32.bnot(held)), taps))
	held = flags

	-- The right stick: the cursor that has the mouse, else the view.
	if CameraController.mapCursor then
		local cx, cy = PadRules.curve(p.rx, p.ry, P.lookDead.value, 1)
		CameraController.padCounts = Vector2.new(cx, -cy) * (P.cursorSpeed.value * dt)
		look.full = 0
	else
		local zoomed = CameraController.zoom > 1
		local scale = if focus and not zoomed then settings.padFocus else 1
		local yaw, pitch = PadRules.look(look, p.rx, p.ry, dt, settings.padLook, scale, not focus and not zoomed, settings.padInvert)
		local perCount = PlayerSettings.degreesPerCount(CameraController.sensitivity, CameraController.scopedMultiplier, 1)
		CameraController.padCounts = Vector2.new(yaw, -pitch) / perCount
	end
	if STUDIO then
		local counts = CameraController.padCounts
		report(
			string.format(
				"flags=%d zoom=%s scoped=%s focus=%d turn=%.1f,%.1f cursor=%s",
				held,
				if wanted then tostring(wanted) else "-",
				scopedText(),
				if focus then 1 else 0,
				tenths(counts.X),
				tenths(counts.Y),
				shown
			)
		)
	end
end

-- The pad's flags for one tick: this frame's, with alt fire pressed or the
-- zoom let go when it isn't yet the one LT wants.
local function sample(): number
	local buttons = held
	local s = PlayerController.sim
	local want = wanted
	if want ~= nil and s then
		local def = PlayerSim.def(s)
		local off
		pulsed, off = PadRules.pulse(want, s.weapons.scoped, if def.ads then #def.ads.zoom else 0, pulsed)
		if pulsed then
			buttons = bit32.bor(buttons, B.AltFire)
		end
		if off then
			buttons = bit32.bor(buttons, B.Unzoom)
		end
	else
		pulsed = false
	end
	return buttons
end

function Gamepad.start()
	pcall(function()
		GuiService.AutoSelectGuiEnabled = false
	end)
	InputSampler.padSample = sample
	UserInputService.InputBegan:Connect(onInput)
	UserInputService.InputChanged:Connect(onInput)
	UserInputService.GamepadDisconnected:Connect(function(kind: Enum.UserInputType)
		if kind == pad then
			InputSampler.padActive = false
		end
	end)
	-- Before the player's own render step (Camera + 1), which samples the
	-- input, and TestAim's (Camera).
	RunService:BindToRenderStep("VFGamepad", Enum.RenderPriority.Input.Value, frame)
end

return Gamepad
