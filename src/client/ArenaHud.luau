--!strict
-- The arena's HUD (system 7), while the arena is on: at the top, your side's
-- score in the ally colour and the other side's in the enemy colour, with the
-- round between them, like the reference's top bar; and in the middle, the
-- buy phase's countdown and how a round and the match ended. P asks the
-- server to turn the arena on or off (Studio or the place owner).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local Remotes = require(Shared.Net.Remotes)

local Ui = require(script.Parent.Debug.Ui)
local Visuals = require(script.Parent.Visuals)

local ArenaHud = {}

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

function ArenaHud.start()
	local gui = Ui.screen("VFArenaHud", 16)
	local centre = Ui.screen("VFArenaBanner", 16, Enum.ScreenInsets.None)

	local bar = Ui.frame(gui, {
		Size = UDim2.fromOffset(240, 58),
		Position = UDim2.new(0.5, -120, 0, 8),
		Visible = false,
	})
	local ours = Ui.label(bar, {
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		TextSize = 34,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local theirs = Ui.label(bar, {
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.new(1, -76, 0, 0),
		TextSize = 34,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local round = Ui.label(bar, {
		Size = UDim2.new(1, -152, 0, 22),
		Position = UDim2.fromOffset(76, 9),
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local target = Ui.label(bar, {
		Size = UDim2.new(1, -152, 0, 16),
		Position = UDim2.fromOffset(76, 32),
		TextSize = 11,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local banner = Ui.label(centre, {
		Size = UDim2.fromOffset(600, 44),
		Position = UDim2.new(0.5, -300, 0.22, 0),
		TextSize = 34,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})
	local subtitle = Ui.label(centre, {
		Size = UDim2.fromOffset(600, 22),
		Position = UDim2.new(0.5, -300, 0.22, 46),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})

	local arena = Workspace:WaitForChild(ArenaConfig.MODEL)
	local me = Players.LocalPlayer

	RunService.RenderStepped:Connect(function()
		local on = Workspace:GetAttribute(ArenaConfig.ON) == true
		local phase = arena:GetAttribute("Phase")
		local side = me:GetAttribute(ArenaConfig.SIDE)
		if not on or typeof(phase) ~= "string" or typeof(side) ~= "number" then
			bar.Visible = false
			banner.Visible = false
			subtitle.Visible = false
			return
		end
		local other = 3 - side
		local ally = color3(VisualConfig.allyColour)
		local enemy = color3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
		local score = { arena:GetAttribute("Score1") or 0, arena:GetAttribute("Score2") or 0 }
		local winScore = arena:GetAttribute("WinScore") or 0
		bar.Visible = true
		ours.Text = tostring(score[side])
		ours.TextColor3 = ally
		theirs.Text = tostring(score[other])
		theirs.TextColor3 = enemy
		local roundNumber = arena:GetAttribute("Round") or 0
		round.Text = if roundNumber > 0 then string.format("ROUND %d", roundNumber) else "ARENA"
		target.Text = string.format("FIRST TO %d", winScore)

		local title, sub, colour = "", "", Ui.TEXT
		local endsAt = arena:GetAttribute("PhaseEndsAt")
		local left = if typeof(endsAt) == "number" then math.max(endsAt - Workspace:GetServerTimeNow(), 0) else 0
		if phase == "waiting" then
			title = "WAITING FOR AN OPPONENT"
			sub = "Anyone who joins the server plays for the other side   4-8 pick a gun"
		elseif phase == "buy" then
			title = string.format("BUY PHASE  %d", math.ceil(left))
			sub = "4-8 pick a gun"
		elseif phase == "roundOver" then
			local won = arena:GetAttribute("RoundWinner") == side
			title = if won then "ROUND WON" else "ROUND LOST"
			colour = if won then ally else enemy
		elseif phase == "matchOver" then
			local won = arena:GetAttribute("MatchWinner") == side
			title = if won then "VICTORY" else "DEFEAT"
			colour = if won then ally else enemy
			sub = string.format(
				'<font color="#%s">%d</font>  -  <font color="#%s">%d</font>   a new match starts shortly',
				Ui.hex(ally),
				score[side],
				Ui.hex(enemy),
				score[other]
			)
		end
		banner.Visible = title ~= ""
		banner.Text = title
		banner.TextColor3 = colour
		subtitle.Visible = sub ~= ""
		subtitle.Text = sub
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.P then
			Remotes.get().Arena:FireServer(Workspace:GetAttribute(ArenaConfig.ON) ~= true)
		end
	end)
end

return ArenaHud
