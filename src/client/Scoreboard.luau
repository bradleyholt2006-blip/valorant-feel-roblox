--!strict
-- The scoreboard (system 16), held on Tab in the spike rounds, as the
-- reference's: a table for each side, yours first, a row a player, sorted
-- by combat score. Each row has the player's kills, deaths and assists, their
-- average combat score (MatchRules.average), and their credits: your side's
-- as they are, the other side's as the round started. Your side's rows also
-- show the gun each holds (their primary, or their sidearm if they have no
-- primary) and the shield they wear. Your row is picked out, and the dead's
-- names are dimmed.
--
-- Everything comes from the player attributes the server keeps (Arena), and
-- each player's shield from what combat events have said of it. While the
-- spike rounds are on, Roblox's own player list, which Tab would open, is
-- off.

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

local ROWS = 5 -- a side
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

-- Whether the spike rounds are on, and so the scoreboard with them.
local function spikeRounds(): boolean
	return Workspace:GetAttribute(ArenaConfig.ON) == true and Workspace:GetAttribute(ArenaConfig.MODE) == "spike"
end

function Scoreboard.start()
	local gui = Ui.screen("VFScoreboard", 20)
	local height = HEADER_H + 22 + 2 * ROWS * (ROW_H + ROW_GAP) + SIDE_GAP + 8
	local panel = Ui.frame(gui, {
		Size = UDim2.fromOffset(WIDTH, height),
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
	for _, column in COLUMNS do
		Ui.label(panel, {
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
	for i, rows in sides do
		local y = top + (i - 1) * (ROWS * (ROW_H + ROW_GAP) + SIDE_GAP)
		for r = 1, ROWS do
			table.insert(rows, newRow(panel, y + (r - 1) * (ROW_H + ROW_GAP)))
		end
	end

	local me = Players.LocalPlayer
	local listOff = false -- whether we've turned Roblox's player list off

	RunService.RenderStepped:Connect(function()
		local on = spikeRounds()
		if on ~= listOff then
			listOff = on
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not on)
		end
		local side = me:GetAttribute(ArenaConfig.SIDE)
		local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
		panel.Visible = Scoreboard.held and on and typeof(side) == "number" and arena ~= nil
		if not panel.Visible or typeof(side) ~= "number" or not arena then
			return
		end
		local other = 3 - side
		local ally = color3(VisualConfig.allyColour)
		local enemy = color3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
		local score = { arena:GetAttribute("Score1") or 0, arena:GetAttribute("Score2") or 0 }
		local round = arena:GetAttribute("Round") or 0
		local formatKey = arena:GetAttribute("Format")
		local format = if typeof(formatKey) == "string" then MatchConfig.Formats[formatKey] else nil
		header.Text = string.format(
			'<font color="#%s">%d</font>     %s%s     <font color="#%s">%d</font>',
			Ui.hex(ally),
			score[side],
			if format then string.upper(format.name) else "SPIKE ROUNDS",
			if round > 0 then string.format("   ROUND %d", round) else "",
			Ui.hex(enemy),
			score[other]
		)

		for i, rows in sides do
			local ours = i == 1
			local colour = if ours then ally else enemy
			local lines = linesOf(if ours then side else other)
			for r, row in rows do
				local line = lines[r]
				row.frame.Visible = line ~= nil
				if not line then
					continue
				end
				local player = line.player
				local cells = row.cells
				local mine = player == me
				row.frame.BackgroundColor3 = if mine then MINE else Ui.PANEL
				row.strip.BackgroundColor3 = colour
				row.strip.BackgroundTransparency = if line.alive then 0 else 0.6
				cells.name.Text = player.DisplayName
				cells.name.TextColor3 = if mine then GOLD else Ui.TEXT
				cells.name.TextTransparency = if line.alive then 0 else 0.5
				cells.k.Text = tostring(line.kills)
				cells.d.Text = tostring(line.deaths)
				cells.a.Text = tostring(line.assists)
				cells.acs.Text = tostring(line.acs)
				local credits = player:GetAttribute(if ours then MatchConfig.CREDITS else MatchConfig.START_CREDITS)
				cells.credits.Text = if typeof(credits) == "number" then tostring(credits) else ""
				cells.credits.TextColor3 = GOLD
				cells.loadout.Text = if ours then loadoutOf(player) else ""
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
