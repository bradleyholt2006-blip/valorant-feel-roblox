--!strict
-- AFK on the client (system 70): while the server has you warned for not
-- playing (your MatchConfig.AFK_AT, the server time you'll be taken out of
-- the match at), a red line across the top of the screen says so,
-- counting down; anything played takes it away. Taken out, the Play menu
-- says why (PlayMenu).
-- For scripted checks, PlayerGui's VFAfk carries Line, the line shown ("" with
-- none).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MatchConfig = require(Shared.Match.MatchConfig)

local Ui = require(script.Parent.Debug.Ui)

local AfkView = {}

function AfkView.start()
	local me = Players.LocalPlayer
	local gui = Ui.screen("VFAfk", 16)
	gui:SetAttribute("Line", "")
	local line = Ui.label(gui, {
		Size = UDim2.fromOffset(760, 30),
		Position = UDim2.new(0.5, -380, 0, 150),
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		TextColor3 = Ui.BAD,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.4,
		Visible = false,
	})
	RunService.RenderStepped:Connect(function()
		local at = me:GetAttribute(MatchConfig.AFK_AT)
		local text = ""
		if typeof(at) == "number" then
			local left = math.max(math.ceil(at - Workspace:GetServerTimeNow()), 0)
			text = string.format("INACTIVE: PLAY, OR YOU'RE TAKEN OUT OF THE MATCH IN %d", left)
		end
		if text ~= line.Text or line.Visible ~= (text ~= "") then
			line.Text = text
			line.Visible = text ~= ""
			gui:SetAttribute("Line", text)
		end
	end)
end

return AfkView
