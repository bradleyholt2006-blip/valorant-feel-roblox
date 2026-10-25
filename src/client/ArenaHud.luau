--!strict
-- The arena's HUD (system 7) and the spike rounds' (system 13), while either
-- is on: at the top, your side's score in the ally colour and the other
-- side's in the enemy colour, with the round between them, like the
-- reference's top bar; and in the middle, the buy phase's countdown and how a
-- round and the match ended. In the spike rounds the top bar also has the
-- round's clock, which gives way to the spike once it's planted, and whether
-- your side attacks or defends; the buy phase says what's at stake (match
-- point, overtime) and your credits, and a round's end says how it was won
-- and when the sides swap. P asks the server for the next of: the arena, the
-- spike rounds, the spike rounds in Swiftplay's format, and off (Studio or
-- the place owner).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local MatchConfig = require(Shared.Match.MatchConfig)
local MatchRules = require(Shared.Match.MatchRules)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local Remotes = require(Shared.Net.Remotes)

local Ui = require(script.Parent.Debug.Ui)
local Visuals = require(script.Parent.Visuals)

local ArenaHud = {}

-- The spike's red, as its own HUD has it, and the buy menu's gold for credits.
local SPIKE_RED = Color3.fromRGB(235, 70, 60)
local GOLD = Color3.fromRGB(230, 200, 120)

-- How a round of the spike rounds was won, for the side that won it and the
-- side that lost it (our words).
local REASONS: { [string]: { won: string, lost: string } } = {
	eliminated = { won = "Enemies eliminated", lost = "Your side was eliminated" },
	detonated = { won = "Spike detonated", lost = "Spike detonated" },
	defused = { won = "Spike defused", lost = "Spike defused" },
	time = { won = "Time ran out before a plant", lost = "Time ran out before a plant" },
}

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

local function clock(seconds: number): string
	local whole = math.ceil(seconds)
	return string.format("%d:%02d", whole // 60, whole % 60)
end

-- What P asks for next.
local function nextMode(): string
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return "skirmish"
	elseif Workspace:GetAttribute(ArenaConfig.MODE) ~= "spike" then
		return MatchConfig.DEFAULT_FORMAT
	elseif Workspace:GetAttribute(MatchConfig.FORMAT) == MatchConfig.DEFAULT_FORMAT then
		return "swiftplay"
	end
	return "off"
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
		Size = UDim2.fromOffset(800, 44),
		Position = UDim2.new(0.5, -400, 0.22, 0),
		TextSize = 34,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})
	local subtitle = Ui.label(centre, {
		Size = UDim2.fromOffset(800, 22),
		Position = UDim2.new(0.5, -400, 0.22, 46),
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
		local roundNumber = arena:GetAttribute("Round") or 0
		local endsAt = arena:GetAttribute("PhaseEndsAt")
		local left = if typeof(endsAt) == "number" then math.max(endsAt - Workspace:GetServerTimeNow(), 0) else 0
		local formatKey = arena:GetAttribute("Format")
		local format = if typeof(formatKey) == "string" then MatchConfig.Formats[formatKey] else nil
		local attackers = arena:GetAttribute("Attackers")
		local spike = arena:GetAttribute("Mode") == "spike" and format ~= nil and typeof(attackers) == "number"

		local width = if spike then 280 else 240
		bar.Size = UDim2.fromOffset(width, 58)
		bar.Position = UDim2.new(0.5, -width / 2, 0, 8)
		bar.Visible = true
		ours.Text = tostring(score[side])
		ours.TextColor3 = ally
		theirs.Text = tostring(score[other])
		theirs.TextColor3 = enemy
		round.TextColor3 = Ui.TEXT

		local title, sub, colour = "", "", Ui.TEXT
		if spike and format then
			local attacking = attackers == side
			local role = if attacking then "ATTACK" else "DEFEND"
			-- The clock: the buy phase's and then the round's, or the spike's
			-- place once it's planted, as the reference's top bar.
			if phase == "planted" then
				round.Text = "SPIKE"
				round.TextColor3 = SPIKE_RED
			elseif phase == "buy" or phase == "live" then
				round.Text = clock(left)
			elseif phase == "waiting" then
				round.Text = "SPIKE ROUNDS"
			else
				round.Text = clock(0)
			end
			target.Text = if roundNumber > 0 then string.format("ROUND %d   %s", roundNumber, role) else format.name:upper()

			if phase == "waiting" then
				title = "WAITING FOR AN OPPONENT"
				sub = string.format("%s, first to %d. Anyone who joins plays for the other side   B buy menu", format.name, winScore)
			elseif phase == "buy" then
				title = string.format("BUY PHASE  %d", math.ceil(left))
				local stakes = {}
				local credits = me:GetAttribute(MatchConfig.CREDITS)
				if typeof(credits) == "number" then
					table.insert(stakes, string.format('<font color="#%s">%d CREDITS</font>', Ui.hex(GOLD), credits))
				end
				local point = MatchRules.matchPointOf(format, score[1], score[2])
				if MatchRules.overtime(format, roundNumber) then
					table.insert(stakes, if format.overtime == "suddenDeath" then "SUDDEN DEATH" else "OVERTIME")
				elseif point[1] or point[2] then
					table.insert(stakes, "MATCH POINT")
				end
				if roundNumber == format.halfRounds.value then
					table.insert(stakes, "LAST ROUND OF THE HALF")
				end
				table.insert(stakes, if attacking then "Attack: plant the spike at A or B" else "Defend A and B")
				table.insert(stakes, "B buy menu")
				sub = table.concat(stakes, "   ")
			elseif phase == "roundOver" then
				local won = arena:GetAttribute("RoundWinner") == side
				title = if won then "ROUND WON" else "ROUND LOST"
				colour = if won then ally else enemy
				local reason = REASONS[arena:GetAttribute("Reason") or ""]
				sub = if reason then (if won then reason.won else reason.lost) else ""
				if MatchRules.swapsAfter(format, roundNumber) then
					sub ..= "   SWITCHING SIDES"
				end
			end
		else
			round.Text = if roundNumber > 0 then string.format("ROUND %d", roundNumber) else "ARENA"
			target.Text = string.format("FIRST TO %d", winScore)
			if phase == "waiting" then
				title = "WAITING FOR AN OPPONENT"
				sub = "Anyone who joins the server plays for the other side   B buy menu"
			elseif phase == "buy" then
				title = string.format("BUY PHASE  %d", math.ceil(left))
				sub = "B buy menu"
			elseif phase == "roundOver" then
				local won = arena:GetAttribute("RoundWinner") == side
				title = if won then "ROUND WON" else "ROUND LOST"
				colour = if won then ally else enemy
			end
		end
		if phase == "matchOver" then
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
			Remotes.get().Arena:FireServer(nextMode())
		end
	end)
end

return ArenaHud
