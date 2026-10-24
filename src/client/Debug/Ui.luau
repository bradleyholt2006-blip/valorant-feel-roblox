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

function Ui.screen(name: string, order: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
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

return Ui
