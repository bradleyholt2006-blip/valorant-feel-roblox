--!strict
-- The settings menu (system 11), on O: the mouse sensitivity and the
-- crosshair, set the way the reference sets them, so a player can bring
-- theirs over. Type the sensitivity and the scoped multiplier from the
-- reference's settings, and paste a crosshair code exported there (the
-- arrow next to Crosshair Profile). The DPI is only for the cm/360 shown.
-- And the minimap's (system 34), the reference's Map settings: Rotate or
-- Fixed, a fixed map's orientation, Keep Player Centered, Minimap Size and
-- Zoom, Vision Cones, and Show Map Region Names for the big map.
--
-- Each change applies at once and is kept for next time (ClientSettings,
-- SettingsServer). The code box always holds the crosshair in use, so it can
-- be copied back out. While the menu is open the mouse moves a cursor, as in
-- the buy menu.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Crosshair = require(Shared.Settings.Crosshair)
local PlayerSettings = require(Shared.Settings.PlayerSettings)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

local BuyMenu = require(script.Parent.BuyMenu)
local CameraController = require(script.Parent.CameraController)
local ClientSettings = require(script.Parent.ClientSettings)
local CrosshairView = require(script.Parent.CrosshairView)
local InputSampler = require(script.Parent.InputSampler)
local Ui = require(script.Parent.Debug.Ui)

local SettingsMenu = {}

SettingsMenu.open = false
-- Set up by SettingsMenu.start.
SettingsMenu.setOpen = function(_open: boolean) end
-- Uses a crosshair code as the code box does, or sets "sensitivity",
-- "scoped", "dpi", "mapSize" or "mapZoom" as their boxes do, or one of the
-- map's choices as its buttons do ("mapRotate=0", "mapNames=buy"); the menu
-- says what happened. For TestAim's VFTestSetting.
SettingsMenu.enter = function(_key: string, _text: string) end

local WIDTH, HEIGHT = 640, 724
local MARGIN = 20
local LABEL_W = 170
local BOX_W = 110
local ROW_H = 30
local MAP_LABEL_W = 128 -- the map's rows are two to a line
local MAP_COLUMN = 300

local BOX = Color3.fromRGB(28, 30, 38)
local GOLD = Color3.fromRGB(230, 200, 120)
local PREVIEWS = {
	{ name = "Dark", color = Color3.fromRGB(32, 34, 40) },
	{ name = "Grey", color = Color3.fromRGB(120, 124, 130) },
	{ name = "Light", color = Color3.fromRGB(215, 215, 210) },
}

local STATUS: { [string]: string } = {
	loading = "Waiting for the server...",
	new = "Nothing kept yet: what you set here is kept for next time.",
	loaded = "Your settings from last time.",
	saving = "Keeping your settings...",
	saved = "Kept for next time.",
}

local function statusText(status: string): string
	local why = string.match(status, "^off: (.*)$")
	if why then
		return "Not kept between sessions here: " .. why
	end
	return STATUS[status] or status
end

-- cm/360 zoomed, for a rifle, a rifle with more zoom and the Operator's two
-- levels.
local ZOOMED = { "vandal", "guardian", "operator" }

local function zoomLines(s: PlayerSettings.Settings): string
	local parts = {}
	for _, id in ZOOMED do
		local def = WeaponConfig.Defs[id]
		local ads = def and def.ads
		if def and ads then
			local each = {}
			for _, zoom in ads.zoom do
				local cm = PlayerSettings.cmPer360(PlayerSettings.degreesPerCount(s.sensitivity, s.scoped, zoom), s.dpi)
				table.insert(each, if cm then string.format("%.1f", cm) else "--")
			end
			table.insert(parts, string.format("%s %s cm", def.name, table.concat(each, " / ")))
		end
	end
	return table.concat(parts, ", ")
end

-- Text the player typed, safe in a rich text label.
local function plain(text: string): string
	return (string.gsub(text, "[<>&]", { ["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;" }))
end

local function mouseLines(s: PlayerSettings.Settings): string
	local hip = PlayerSettings.degreesPerCount(s.sensitivity, s.scoped, 1)
	local cm = PlayerSettings.cmPer360(hip, s.dpi)
	return table.concat({
		string.format(
			"%.4f degrees a count   %.0f counts a turn   %s   eDPI %s",
			hip,
			PlayerSettings.countsPer360(hip),
			if cm then string.format("<b>%.1f cm/360</b>", cm) else "set the DPI for cm/360",
			Crosshair.number(PlayerSettings.edpi(s))
		),
		string.format('<font color="#%s">Zoomed:</font> %s', Ui.hex(Ui.DIM), zoomLines(s)),
	}, "\n")
end

local function textBox(parent: Instance, props: { [string]: any }): TextBox
	local box = Instance.new("TextBox")
	box.BorderSizePixel = 0
	box.BackgroundColor3 = BOX
	box.BackgroundTransparency = 0
	box.Font = Ui.FONT
	box.TextSize = 15
	box.TextColor3 = Ui.TEXT
	box.PlaceholderColor3 = Ui.DIM
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	for k, v in props do
		(box :: any)[k] = v
	end
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = box
	box.Parent = parent
	return box
end

local function button(parent: Instance, text: string, x: number, y: number, w: number): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	b.BackgroundColor3 = Color3.fromRGB(48, 52, 64)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = Ui.TEXT
	b.Text = text
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(w, 28)
	b.Parent = parent
	return b
end

local function header(parent: Instance, text: string, y: number)
	Ui.label(parent, {
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(MARGIN, y),
		Size = UDim2.fromOffset(WIDTH - 2 * MARGIN, 18),
	})
end

function SettingsMenu.start()
	local gui = Ui.screen("VFSettingsMenu", 21)
	gui.Enabled = false
	local root = Ui.frame(gui, {
		Name = "Menu",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundTransparency = 0.12,
		Active = true,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = root

	Ui.label(root, {
		Text = "SETTINGS",
		Font = Enum.Font.GothamBold,
		TextSize = 28,
		Position = UDim2.fromOffset(MARGIN, 14),
		Size = UDim2.fromOffset(240, 32),
	})
	Ui.label(root, {
		Text = "O to close",
		TextSize = 13,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(WIDTH - MARGIN - 200, 24),
		Size = UDim2.fromOffset(200, 16),
	})

	-- Mouse ----------------------------------------------------------------------
	header(root, "MOUSE", 64)
	local boxes: { [string]: TextBox } = {}
	local fields = {
		{ key = "sensitivity", name = "Sensitivity", hint = "as in the reference's settings" },
		{ key = "scoped", name = "Scoped multiplier", hint = "the reference's scoped sensitivity multiplier" },
		{ key = "dpi", name = "Mouse DPI", hint = "your mouse's, for the cm/360 below" },
	}
	for i, field in fields do
		local y = 86 + (i - 1) * (ROW_H + 6)
		Ui.label(root, {
			Text = field.name,
			TextSize = 15,
			TextYAlignment = Enum.TextYAlignment.Center,
			Position = UDim2.fromOffset(MARGIN, y),
			Size = UDim2.fromOffset(LABEL_W, ROW_H),
		})
		boxes[field.key] = textBox(root, {
			Name = field.key,
			Position = UDim2.fromOffset(MARGIN + LABEL_W, y),
			Size = UDim2.fromOffset(BOX_W, ROW_H),
		})
		Ui.label(root, {
			Text = field.hint,
			TextSize = 12,
			TextColor3 = Ui.DIM,
			TextYAlignment = Enum.TextYAlignment.Center,
			Position = UDim2.fromOffset(MARGIN + LABEL_W + BOX_W + 12, y),
			Size = UDim2.fromOffset(WIDTH - 2 * MARGIN - LABEL_W - BOX_W - 12, ROW_H),
		})
	end
	local mouseInfo = Ui.label(root, {
		Name = "MouseInfo",
		TextSize = 13,
		LineHeight = 1.2,
		Position = UDim2.fromOffset(MARGIN, 196),
		Size = UDim2.fromOffset(WIDTH - 2 * MARGIN, 36),
	})

	-- Crosshair ------------------------------------------------------------------
	header(root, "CROSSHAIR", 248)
	local codeBox = textBox(root, {
		Name = "Code",
		PlaceholderText = "Paste a crosshair code, then Enter",
		TextSize = 13,
		Position = UDim2.fromOffset(MARGIN, 270),
		Size = UDim2.fromOffset(WIDTH - 2 * MARGIN - 110, ROW_H),
	})
	local default = button(root, "DEFAULT", WIDTH - MARGIN - 100, 271, 100)
	Ui.label(root, {
		Text = "Enter uses the code. The box holds the crosshair in use: select it and press Ctrl+C to copy it out.",
		TextSize = 12,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(MARGIN, 306),
		Size = UDim2.fromOffset(WIDTH - 2 * MARGIN, 16),
	})
	local codeInfo = Ui.label(root, {
		Name = "CodeInfo",
		TextSize = 13,
		LineHeight = 1.15,
		TextWrapped = true,
		Position = UDim2.fromOffset(MARGIN, 328),
		Size = UDim2.fromOffset(WIDTH - 2 * MARGIN, 52),
	})

	-- The crosshair on three backgrounds, at its real size.
	local previewW = math.floor((WIDTH - 2 * MARGIN - 2 * 12) / 3)
	local drawings: { CrosshairView.Drawing } = {}
	for i, look in PREVIEWS do
		local box = Ui.frame(root, {
			Name = "Preview" .. look.name,
			BackgroundColor3 = look.color,
			BackgroundTransparency = 0,
			ClipsDescendants = true,
			Position = UDim2.fromOffset(MARGIN + (i - 1) * (previewW + 12), 388),
			Size = UDim2.fromOffset(previewW, 100),
		})
		local middle = Ui.frame(box, {
			Name = "Centre",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(0, 0),
		})
		table.insert(drawings, CrosshairView.build(middle))
	end
	local extraInfo = Ui.label(root, {
		Name = "ScopeInfo",
		TextSize = 12,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(MARGIN, 494),
		Size = UDim2.fromOffset(WIDTH - 2 * MARGIN, 16),
	})

	-- Map ------------------------------------------------------------------------
	-- Each choice a row of buttons, the one in use lit; switches are "1" and
	-- "0" (PlayerSettings.switchOf).
	header(root, "MAP", 520)
	local function mapLabel(name: string, x: number, y: number)
		Ui.label(root, {
			Text = name,
			TextSize = 14,
			TextYAlignment = Enum.TextYAlignment.Center,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(MAP_LABEL_W, ROW_H),
		})
	end
	local choices: { { key: string, values: { string }, buttons: { TextButton } } } = {}
	local function choice(key: string, name: string, x: number, y: number, w: number, options: { { string } })
		mapLabel(name, x, y)
		local entry = { key = key, values = {}, buttons = {} }
		for i, option in options do
			local b = button(root, option[2], x + MAP_LABEL_W + (i - 1) * (w + 4), y + 1, w)
			b.Name = key .. "_" .. option[1]
			b.TextSize = 11
			table.insert(entry.values, option[1])
			table.insert(entry.buttons, b)
		end
		table.insert(choices, entry)
	end
	local left, right = MARGIN, MARGIN + MAP_COLUMN
	choice("mapRotate", "Rotate", left, 542, 76, { { "1", "ROTATE" }, { "0", "FIXED" } })
	choice("mapBySide", "Fixed orientation", right, 542, 76, { { "0", "SAME WAY" }, { "1", "BY SIDE" } })
	choice("mapCentred", "Keep me centred", left, 578, 76, { { "1", "ON" }, { "0", "OFF" } })
	choice("mapCones", "Vision cones", right, 578, 76, { { "1", "ON" }, { "0", "OFF" } })
	local sizes = {
		{ key = "mapSize", name = "Minimap size", hint = "0.8 to 1.2" },
		{ key = "mapZoom", name = "Minimap zoom", hint = "0.6 to 1.4" },
	}
	for i, field in sizes do
		local x = if i == 1 then left else right
		mapLabel(field.name, x, 614)
		boxes[field.key] = textBox(root, {
			Name = field.key,
			Position = UDim2.fromOffset(x + MAP_LABEL_W, 614),
			Size = UDim2.fromOffset(76, ROW_H),
		})
		Ui.label(root, {
			Text = field.hint,
			TextSize = 12,
			TextColor3 = Ui.DIM,
			TextYAlignment = Enum.TextYAlignment.Center,
			Position = UDim2.fromOffset(x + MAP_LABEL_W + 84, 614),
			Size = UDim2.fromOffset(MAP_COLUMN - MAP_LABEL_W - 84, ROW_H),
		})
	end
	choice("mapNames", "Region names", left, 650, 88, { { "always", "ALWAYS" }, { "buy", "IN BUY PHASE" }, { "never", "NEVER" } })
	Ui.label(root, {
		Text = "on the big map (hold Caps Lock)",
		TextSize = 12,
		TextColor3 = Ui.DIM,
		TextYAlignment = Enum.TextYAlignment.Center,
		Position = UDim2.fromOffset(left + MAP_LABEL_W + 3 * 92 + 4, 650),
		Size = UDim2.fromOffset(WIDTH - 2 * MARGIN - MAP_LABEL_W - 3 * 92 - 4, ROW_H),
	})
	local status = Ui.label(root, {
		Name = "Status",
		TextSize = 13,
		TextColor3 = GOLD,
		Position = UDim2.fromOffset(MARGIN, HEIGHT - 30),
		Size = UDim2.fromOffset(WIDTH - 2 * MARGIN, 16),
	})

	-- What the last import said, until the next change.
	local codeNote = ""

	local function refresh()
		local s = ClientSettings.current
		for key, box in boxes do
			if not box:IsFocused() then
				box.Text = if key == "dpi" then tostring(s.dpi) else Crosshair.number((s :: any)[key])
			end
		end
		for _, entry in choices do
			local value = (s :: any)[entry.key]
			local current = if typeof(value) == "boolean" then (if value then "1" else "0") else tostring(value)
			for i, b in entry.buttons do
				local on = entry.values[i] == current
				b.BackgroundColor3 = if on then GOLD else Color3.fromRGB(48, 52, 64)
				b.TextColor3 = if on then Ui.PANEL else Ui.TEXT
			end
		end
		if not codeBox:IsFocused() then
			codeBox.Text = s.crosshair
		end
		mouseInfo.Text = mouseLines(s)
		local code = ClientSettings.code
		local primary = Crosshair.profile(code, "P")
		codeInfo.Text = Crosshair.describe(primary) .. (if codeNote ~= "" then "\n" .. codeNote else "")
		for _, drawing in drawings do
			CrosshairView.draw(drawing, primary, 0, 0, 0)
		end
		local dot = Crosshair.sniperDot(code)
		local adsOwn = Crosshair.advanced(code) and Crosshair.hasSection(code, "A")
		extraInfo.Text = string.format(
			"Aiming down sights: %s.   Sniper scope: %s.",
			if adsOwn then "its own crosshair, " .. Crosshair.adsProfile(code).colorName else "the same crosshair",
			if dot.show
				then string.format(
					"a %s centre dot, %s thick at %s",
					dot.colorName,
					Crosshair.number(dot.thickness),
					Crosshair.number(dot.opacity)
				)
				else "no centre dot"
		)
	end
	table.insert(ClientSettings.listeners, refresh)

	local function enter(key: string, text: string)
		if key == "crosshair" then
			local code, err = Crosshair.parse(text)
			if not code then
				codeNote = string.format('<font color="#%s">Not a crosshair code: %s.</font>', Ui.hex(Ui.BAD), err or "?")
				refresh()
				return
			end
			local warnings = code.warnings
			codeNote = if #warnings > 0
				then string.format('<font color="#%s">Using it, but: %s.</font>', Ui.hex(GOLD), plain(table.concat(warnings, "; ")))
				else string.format('<font color="#%s">Using it.</font>', Ui.hex(Ui.GOOD))
			ClientSettings.setOne("crosshair", text)
			refresh()
			return
		end
		-- A number that isn't one puts the box back.
		ClientSettings.setOne(key, text)
		refresh()
	end
	SettingsMenu.enter = enter

	for key, box in boxes do
		box.FocusLost:Connect(function()
			enter(key, box.Text)
		end)
	end
	for _, entry in choices do
		for i, b in entry.buttons do
			b.MouseButton1Click:Connect(function()
				enter(entry.key, entry.values[i])
			end)
		end
	end
	codeBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			enter("crosshair", codeBox.Text)
		else
			refresh()
		end
	end)
	default.MouseButton1Click:Connect(function()
		enter("crosshair", Crosshair.DEFAULT)
	end)

	local function setOpen(open: boolean)
		if open == SettingsMenu.open then
			return
		end
		if open and BuyMenu.open then
			BuyMenu.setOpen(false)
		end
		SettingsMenu.open = open
		gui.Enabled = open
		CameraController.cursorFree = open
		InputSampler.blockMouse = open
		if open then
			codeNote = ""
			refresh()
		else
			for _, box in boxes do
				box:ReleaseFocus()
			end
			codeBox:ReleaseFocus()
		end
	end
	SettingsMenu.setOpen = setOpen

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.O then
			return
		end
		setOpen(not SettingsMenu.open)
	end)

	RunService.RenderStepped:Connect(function()
		if not SettingsMenu.open then
			return
		end
		local viewport = Workspace.CurrentCamera.ViewportSize
		scale.Scale = math.min(1, (viewport.X - 40) / WIDTH, (viewport.Y - 40) / HEIGHT)
		status.Text = statusText(ClientSettings.status())
	end)
	refresh()
end

return SettingsMenu
