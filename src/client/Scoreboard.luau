--!strict
-- The scoreboard (system 16), held on Tab in the arena and the spike
-- rounds, as the reference's: a table for each side, yours first, a row a
-- player, sorted by combat score. Each row has the player's kills, deaths and
-- assists, their average combat score (MatchRules.average), and in the spike
-- rounds their credits: your side's as they are, the other side's as the
-- round started. Your side's rows also show the gun each holds (their
-- primary, or their sidearm if they have no primary) and the shield they
-- wear. Your row is picked out, and the dead's names are dimmed.
--
-- And the victory screen (system 21): as a match ends, the same tables show
-- by themselves until the next match starts, under the result, with the time
-- left at their foot and the MVPs picked out, as the reference's end of match
-- had them: MATCH MVP, the best combat score of the match (a tie goes to the
-- side that won), and TEAM MVP, the best on the other side. Anyone not on a
-- side, waiting in line, sees the side that leads (or won) first. Tab shows
-- it again during the vote for the next map that follows (system 22).
--
-- Everything comes from the player attributes the server keeps (Arena), and
-- each player's shield from what combat events have said of it. While either
-- is on, Roblox's own player list, which Tab would open, is off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local MatchConfig = require(Shared.Match.MatchConfig)
local MatchRules = require(Shared.Match.MatchRules)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)

local Ui = require(script.Parent.Debug.Ui)
local RemoteEntities = require(script.Parent.RemoteEntities)
local Visuals = require(script.Parent.Visuals)

local Scoreboard = {}

-- Whether it's held open: Tab, or TestAim's VFTestBoard.
Scoreboard.held = false

local ROWS = 5 -- a side, at most
local WIDTH = 640
local ROW_H, ROW_GAP = 28, 2
local HEADER_H = 34
local SIDE_GAP = 12
local GOLD = Color3.fromRGB(230, 200, 120)
local MINE = Color3.fromRGB(58, 54, 38) -- your row's background

-- The columns: where each starts, how wide it is, and how it's aligned.
type Column = { key: string, title: string, x: number, width: number, align: Enum.TextXAlignment }
local CENTRE = Enum.TextXAlignment.Center
local LEFT = Enum.TextXAlignment.Left
local COLUMNS: { Column } = {
	{ key = "name", title = "NAME", x = 16, width = 200, align = LEFT },
	{ key = "k", title = "K", x = 220, width = 40, align = CENTRE },
	{ key = "d", title = "D", x = 260, width = 40, align = CENTRE },
	{ key = "a", title = "A", x = 300, width = 40, align = CENTRE },
	{ key = "acs", title = "ACS", x = 344, width = 56, align = CENTRE },
	{ key = "credits", title = "CREDITS", x = 404, width = 76, align = CENTRE },
	{ key = "loadout", title = "LOADOUT", x = 492, width = 140, align = LEFT },
}

type Row = { frame: Frame, strip: Frame, cells: { [string]: TextLabel } }

-- The victory screen's badges: for the best of the match, and the best on
-- the other side.
local MATCH_MVP, TEAM_MVP = "MATCH MVP", "TEAM MVP"

-- What a row shows of a player.
type Line = { player: Player, kills: number, deaths: number, assists: number, acs: number, alive: boolean }

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

local function number(player: Player, name: string): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else 0
end

-- The players on a side, best combat score first.
local function linesOf(side: number): { Line }
	local out: { Line } = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute(ArenaConfig.SIDE) == side then
			table.insert(out, {
				player = player,
				kills = number(player, MatchConfig.KILLS),
				deaths = number(player, MatchConfig.DEATHS),
				assists = number(player, MatchConfig.ASSISTS),
				acs = MatchRules.average(number(player, MatchConfig.SCORE), number(player, MatchConfig.ROUNDS)),
				alive = player:GetAttribute(MatchConfig.ALIVE) ~= false,
			})
		end
	end
	table.sort(out, function(a: Line, b: Line): boolean
		if a.acs ~= b.acs then
			return a.acs > b.acs
		elseif a.kills ~= b.kills then
			return a.kills > b.kills
		end
		return a.player.DisplayName < b.player.DisplayName
	end)
	return out
end

-- The gun a player holds, as the scoreboard names it, and their shield's.
local function loadoutOf(player: Player): string
	local text = player:GetAttribute(MatchConfig.LOADOUT)
	local primary, sidearm = "", ""
	if typeof(text) == "string" then
		local a, b = string.match(text, "^([^,]*),?(.*)$")
		primary, sidearm = a or "", b or ""
	end
	local gun = if primary ~= "" then primary else sidearm
	local def = if gun ~= "" then WeaponConfig.Defs[gun] else nil
	local parts = {}
	if def then
		table.insert(parts, string.upper(def.name))
	end
	local hp = RemoteEntities.healthOf(PlayerCodec.entityIdForUser(player.UserId))
	local shield = WeaponConfig.Shields[hp.armor]
	if shield and (hp.shield > 0 or (shield.regen ~= nil and hp.pool > 0)) then
		local word = string.match(shield.name, "^%a+") or shield.name
		table.insert(parts, string.format('<font color="#%s">%s</font>', Ui.hex(Ui.NEUTRAL), string.upper(word)))
	end
	return table.concat(parts, "  ")
end

local function newRow(parent: Instance, y: number): Row
	local frame = Ui.frame(parent, {
		Size = UDim2.new(1, -16, 0, ROW_H),
		Position = UDim2.fromOffset(8, y),
		BackgroundTransparency = 0.2,
		Visible = false,
	})
	local strip = Ui.frame(frame, { Size = UDim2.new(0, 4, 1, 0), BackgroundTransparency = 0 })
	local cells: { [string]: TextLabel } = {}
	for _, column in COLUMNS do
		cells[column.key] = Ui.label(frame, {
			Size = UDim2.new(0, column.width, 1, 0),
			Position = UDim2.fromOffset(column.x - 8, 0),
			Font = if column.key == "name" then Enum.Font.GothamBold else Ui.FONT,
			TextSize = 14,
			TextXAlignment = column.align,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end
	return { frame = frame, strip = strip, cells = cells }
end

-- The panel's height with `rows` rows a side.
local function heightFor(rows: number): number
	return HEADER_H + 22 + 2 * rows * (ROW_H + ROW_GAP) + SIDE_GAP + 8
end

function Scoreboard.start()
	local gui = Ui.screen("VFScoreboard", 20)
	local panel = Ui.frame(gui, {
		Size = UDim2.fromOffset(WIDTH, heightFor(ROWS)),
		Position = UDim2.new(0.5, -WIDTH / 2, 0, 84),
		BackgroundTransparency = 0.15,
		Visible = false,
	})
	local header = Ui.label(panel, {
		Size = UDim2.new(1, 0, 0, HEADER_H),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	-- The time left on the victory screen, under the tables.
	local footer = Ui.label(panel, {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 1, 6),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})
	local titles: { [string]: TextLabel } = {}
	for _, column in COLUMNS do
		titles[column.key] = Ui.label(panel, {
			Size = UDim2.fromOffset(column.width, 18),
			Position = UDim2.fromOffset(column.x, HEADER_H),
			TextSize = 11,
			TextColor3 = Ui.DIM,
			TextXAlignment = column.align,
			Text = column.title,
		})
	end
	local top = HEADER_H + 22
	local sides: { { Row } } = { {}, {} } -- yours, theirs
	for _, rows in sides do
		for _ = 1, ROWS do
			table.insert(rows, newRow(panel, 0))
		end
	end

	local me = Players.LocalPlayer
	local listOff = false -- whether we've turned Roblox's player list off

	RunService.RenderStepped:Connect(function()
		local on = Workspace:GetAttribute(ArenaConfig.ON) == true
		if on ~= listOff then
			listOff = on
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not on)
		end
		local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
		local phase = if arena then arena:GetAttribute("Phase") else nil
		local over = phase == "matchOver" or phase == "vote"
		panel.Visible = on and arena ~= nil and (Scoreboard.held or phase == "matchOver")
		footer.Visible = panel.Visible and over
		if not panel.Visible or not arena then
			return
		end
		local spike = arena:GetAttribute("Mode") == "spike"
		local score = { arena:GetAttribute("Score1") or 0, arena:GetAttribute("Score2") or 0 }
		local winner = arena:GetAttribute("MatchWinner")
		local mySide = me:GetAttribute(ArenaConfig.SIDE)
		local playing = typeof(mySide) == "number"
		local side: number = if typeof(mySide) == "number"
			then mySide
			elseif winner == 2 or (winner == nil and score[2] > score[1]) then 2
			else 1
		local other = 3 - side
		local ally = color3(VisualConfig.allyColour)
		local enemy = color3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
		local round = arena:GetAttribute("Round") or 0
		local formatKey = arena:GetAttribute("Format")
		local format = if typeof(formatKey) == "string" then MatchConfig.Formats[formatKey] else nil
		local title: string
		if over then
			local won = winner == side
			title = if not playing then "MATCH OVER" elseif won then "VICTORY" else "DEFEAT"
			title = string.format('<font color="#%s">%s</font>', Ui.hex(if not playing then Ui.TEXT elseif won then ally else enemy), title)
			local endsAt = arena:GetAttribute("PhaseEndsAt")
			local left = if typeof(endsAt) == "number" then math.max(endsAt - Workspace:GetServerTimeNow(), 0) else 0
			-- What follows: the vote for the next map, where the mode has one,
			-- then the next match.
			local coming = if phase == "matchOver" and arena:GetAttribute("MapVote") == true then "MAP VOTE" else "NEXT MATCH"
			footer.Text = string.format("%s IN %d", coming, math.ceil(left))
		else
			local name = if not spike then "SKIRMISH" elseif format then string.upper(format.name) else "SPIKE ROUNDS"
			title = name .. (if round > 0 then string.format("   ROUND %d", round) else "")
		end
		header.Text = string.format(
			'<font color="#%s">%d</font>     %s     <font color="#%s">%d</font>',
			Ui.hex(ally),
			score[side],
			title,
			Ui.hex(enemy),
			score[other]
		)
		-- Credits only in the spike rounds, and on the victory screen the
		-- MVPs where the guns go.
		titles.credits.Visible = spike and not over
		titles.loadout.Visible = not over

		local lines = { linesOf(side), linesOf(other) }
		local shown = math.clamp(math.max(#lines[1], #lines[2]), 1, ROWS)
		-- Which table has the match's MVP: the best of the two sides' best.
		local first, second = lines[1][1], lines[2][1]
		local mvpTable = 1
		if second and (not first or second.acs > first.acs or (second.acs == first.acs and other == winner)) then
			mvpTable = 2
		end
		panel.Size = UDim2.fromOffset(WIDTH, heightFor(shown))
		for i, rows in sides do
			local ours = i == 1 and playing
			local colour = if i == 1 then ally else enemy
			local sideLines = lines[i]
			local y = top + (i - 1) * (shown * (ROW_H + ROW_GAP) + SIDE_GAP)
			-- The side's best, if they scored at all.
			local best = sideLines[1]
			local mvp = if over and best and best.acs > 0 then best.player else nil
			local badge = if i == mvpTable then MATCH_MVP else TEAM_MVP
			for r, row in rows do
				local line = sideLines[r]
				row.frame.Visible = line ~= nil
				if not line then
					continue
				end
				row.frame.Position = UDim2.fromOffset(8, y + (r - 1) * (ROW_H + ROW_GAP))
				local player = line.player
				local cells = row.cells
				local mine = player == me
				-- Nobody's dimmed once the match is over.
				local alive = line.alive or over
				row.frame.BackgroundColor3 = if mine then MINE else Ui.PANEL
				row.strip.BackgroundColor3 = colour
				row.strip.BackgroundTransparency = if alive then 0 else 0.6
				cells.name.Text = player.DisplayName
				cells.name.TextColor3 = if mine then GOLD else Ui.TEXT
				cells.name.TextTransparency = if alive then 0 else 0.5
				cells.k.Text = tostring(line.kills)
				cells.d.Text = tostring(line.deaths)
				cells.a.Text = tostring(line.assists)
				cells.acs.Text = tostring(line.acs)
				local credits = player:GetAttribute(if ours then MatchConfig.CREDITS else MatchConfig.START_CREDITS)
				cells.credits.Text = if spike and not over and typeof(credits) == "number" then tostring(credits) else ""
				cells.credits.TextColor3 = GOLD
				if over then
					cells.loadout.Text = if player == mvp then "<b>" .. badge .. "</b>" else ""
					cells.loadout.TextColor3 = if badge == MATCH_MVP then GOLD else Ui.TEXT
				else
					cells.loadout.Text = if ours then loadoutOf(player) else ""
					cells.loadout.TextColor3 = Ui.TEXT
				end
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Tab then
			Scoreboard.held = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Tab then
			Scoreboard.held = false
		end
	end)
end

return Scoreboard
