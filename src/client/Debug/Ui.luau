--!strict
-- Tiny helpers for building debug UI in code.

local Players = game:GetService("Players")

local Ui = {}

Ui.FONT = Enum.Font.RobotoMono
Ui.GOOD = Color3.fromRGB(90, 220, 120)
Ui.BAD = Color3.fromRGB(240, 80, 80)
Ui.NEUTRAL = Color3.fromRGB(120, 160, 240)
Ui.TEXT = Color3.fromRGB(235, 235, 235)
Ui.DIM = Color3.fromRGB(150, 150, 150)
Ui.PANEL = Color3.fromRGB(12, 12, 16)

-- Panels keep clear of Roblox's top-bar buttons (the default insets). Things
-- drawn on the camera's centre, like the crosshair, pass
-- Enum.ScreenInsets.None so the middle of the gui is the middle of the view.
function Ui.screen(name: string, order: number?, insets: Enum.ScreenInsets?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ScreenInsets = insets or Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = order or 10
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

function Ui.frame(parent: Instance, props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Ui.PANEL
	f.BackgroundTransparency = 0.25
	for k, v in props do
		(f :: any)[k] = v
	end
	f.Parent = parent
	return f
end

function Ui.label(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Ui.FONT
	l.TextColor3 = Ui.TEXT
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.RichText = true
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

function Ui.ms(seconds: number?): string
	if seconds == nil then
		return "  -- "
	end
	return string.format("%4.0fms", seconds * 1000)
end

function Ui.hex(c: Color3): string
	return c:ToHex()
end

-- A place as it's said: 1st, 2nd, 3rd, 4th, ..., 11th, 12th, 13th, ..., 21st.
function Ui.ordinal(n: number): string
	local suffix = "th"
	if n % 100 < 11 or n % 100 > 13 then
		suffix = if n % 10 == 1 then "st" elseif n % 10 == 2 then "nd" elseif n % 10 == 3 then "rd" else "th"
	end
	return tostring(n) .. suffix
end

return Ui
