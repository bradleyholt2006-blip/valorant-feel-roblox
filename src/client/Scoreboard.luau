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
-- it again during the vote for the next map that follows (system 22). The
-- Play menu, open, hides it (system 24).
--
-- In gun game (system 23) the rows go by level, not combat score: each has
-- the player's level where the ACS goes, and the gun of it, for both sides,
-- where the guns go. So MATCH MVP is whoever won, on the last level.
--
-- Deathmatch (system 26) has no sides, so one table instead, of everyone
-- playing in their places (DeathmatchConfig.PLACE, from the server), with
-- each player's place where the ACS goes, and your own gun alone. Its
-- victory screen says VICTORY to whoever won and to everyone else their
-- place (our words), with MATCH MVP on the winner.
--
-- Team Deathmatch (system 27) has no rounds, so its combat score is the
-- match's, under SCORE, and a match it ends level is a DRAW.
--
-- Competitive's victory screen (system 67) has your rank under the time
-- left, from the attributes the server keeps (RankConfig): the RR the match
-- was worth, and a promotion, a demotion, a shield used or the placement,
-- or the placements played so far. Nothing if the match didn't count for
-- you (you played too little of it).
--
-- Each row also has the player's agent, in a box in their side's colour as
-- their tile on the top bar has it (system 51, Glance.badge), and under ULT
-- their ultimate, both sides' alike, as the reference's has it: how far
-- along it is ("3/8"), or READY in gold (AbilityConfig.ULT_ATTRIBUTE).
-- Neither shows in gun game or deathmatch, where nobody plays an agent,
-- nor the ultimate on the victory screen. While it's open, its Ult
-- attribute lists each row's agent, name and ultimate, for scripted checks.
--
-- Everything comes from the player attributes the server keeps (Arena), and
-- each player's shield from what combat events have said of it. A bot
-- (system 60) has a row as a player has, from the same attributes on its
-- stand-in (Who). While either is on, Roblox's own player list, which Tab
-- would open, is off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AgentSelect = require(Shared.Abilities.AgentSelect)
local Glance = require(Shared.Abilities.Glance)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local DeathmatchConfig = require(Shared.Arena.DeathmatchConfig)
local GunGameConfig = require(Shared.Arena.GunGameConfig)
local CareerRules = require(Shared.Career.CareerRules)
local RankConfig = require(Shared.Career.RankConfig)
local RankRules = require(Shared.Career.RankRules)
local MatchConfig = require(Shared.Match.MatchConfig)
local MatchRules = require(Shared.Match.MatchRules)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

local Ui = require(script.Parent.Debug.Ui)
local PlayMenu = require(script.Parent.PlayMenu)
local RemoteEntities = require(script.Parent.RemoteEntities)
local Visuals = require(script.Parent.Visuals)
local Who = require(script.Parent.Who)

local Scoreboard = {}

-- Whether it's held open: Tab, or TestAim's VFTestBoard.
Scoreboard.held = false

local ROWS = 5 -- a side, at most
local FFA_ROWS = DeathmatchConfig.Rules.players.value -- deathmatch's one table, at most
local WIDTH = 700
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
	{ key = "agent", title = "", x = 16, width = 28, align = CENTRE },
	{ key = "name", title = "NAME", x = 52, width = 164, align = LEFT },
	{ key = "ult", title = "ULT", x = 220, width = 56, align = CENTRE },
	{ key = "k", title = "K", x = 280, width = 40, align = CENTRE },
	{ key = "d", title = "D", x = 320, width = 40, align = CENTRE },
	{ key = "a", title = "A", x = 360, width = 40, align = CENTRE },
	{ key = "acs", title = "ACS", x = 404, width = 56, align = CENTRE },
	{ key = "credits", title = "CREDITS", x = 464, width = 76, align = CENTRE },
	{ key = "loadout", title = "LOADOUT", x = 552, width = 140, align = LEFT },
}

type Row = { frame: Frame, strip: Frame, cells: { [string]: TextLabel } }

-- The victory screen's badges: for the best of the match, and the best on
-- the other side.
local MATCH_MVP, TEAM_MVP = "MATCH MVP", "TEAM MVP"

-- What a row shows of a player or a bot, and what orders the rows: the
-- combat score, or in gun game the level, or in deathmatch the place
-- (math.huge for none).
type Line = {
	who: Who.Someone,
	kills: number,
	deaths: number,
	assists: number,
	acs: number,
	level: number,
	place: number,
	rank: number,
	alive: boolean,
}

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

local function number(holder: Instance, name: string): number
	local value = holder:GetAttribute(name)
	return if typeof(value) == "number" then value else 0
end

local function lineOf(who: Who.Someone, gunGame: boolean): Line
	local player = who.holder
	local acs = MatchRules.average(number(player, MatchConfig.SCORE), number(player, MatchConfig.ROUNDS))
	local level = number(player, GunGameConfig.LEVEL)
	local place = player:GetAttribute(DeathmatchConfig.PLACE)
	return {
		who = who,
		kills = number(player, MatchConfig.KILLS),
		deaths = number(player, MatchConfig.DEATHS),
		assists = number(player, MatchConfig.ASSISTS),
		acs = acs,
		level = level,
		place = if typeof(place) == "number" then place else math.huge,
		rank = if gunGame then level else acs,
		alive = player:GetAttribute(MatchConfig.ALIVE) ~= false,
	}
end

-- The players and bots on a side, best combat score (in gun game, level,
-- and on the same level whoever leads or won, `leader`) first.
local function linesOf(side: number, gunGame: boolean, leader: any): { Line }
	local out: { Line } = {}
	for _, who in Who.all() do
		if who.holder:GetAttribute(ArenaConfig.SIDE) == side then
			table.insert(out, lineOf(who, gunGame))
		end
	end
	table.sort(out, function(a: Line, b: Line): boolean
		if a.rank ~= b.rank then
			return a.rank > b.rank
		elseif gunGame and (a.who.id == leader) ~= (b.who.id == leader) then
			return a.who.id == leader
		elseif a.kills ~= b.kills then
			return a.kills > b.kills
		end
		return a.who.name < b.who.name
	end)
	return out
end

-- Everyone playing a deathmatch, in their places.
local function placesOf(): { Line }
	local out: { Line } = {}
	for _, who in Who.all() do
		if typeof(who.holder:GetAttribute(ArenaConfig.SIDE)) == "number" then
			table.insert(out, lineOf(who, false))
		end
	end
	table.sort(out, function(a: Line, b: Line): boolean
		if a.place ~= b.place then
			return a.place < b.place
		elseif a.kills ~= b.kills then
			return a.kills > b.kills
		end
		return a.who.name < b.who.name
	end)
	return out
end

-- The gun someone holds, as the scoreboard names it, and their shield's.
local function loadoutOf(who: Who.Someone): string
	local text = who.holder:GetAttribute(MatchConfig.LOADOUT)
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
	local hp = RemoteEntities.healthOf(who.entity)
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
	-- The agent's a box, as their tile on the top bar is (system 51).
	local agent = cells.agent
	agent.Size = UDim2.new(0, agent.Size.X.Offset, 1, -8)
	agent.Position += UDim2.fromOffset(0, 4)
	agent.Font = Enum.Font.GothamBold
	agent.TextSize = 12
	return { frame = frame, strip = strip, cells = cells }
end

-- A row's agent, in a box in its side's colour, dimmed once they're dead,
-- as their tile on the top bar has it; or nothing (`badge` "").
local function showAgent(cell: TextLabel, badge: string, colour: Color3, alive: boolean)
	cell.Text = badge
	cell.BackgroundColor3 = if alive then colour else Ui.PANEL
	cell.BackgroundTransparency = if badge == "" then 1 elseif alive then 0.15 else 0.35
	cell.TextColor3 = if alive then Ui.PANEL else colour
	cell.TextTransparency = if alive then 0 else 0.5
end

-- The panel's height with `rows` rows in each of its `tables` (two, a side,
-- unless said).
local function heightFor(rows: number, tables: number?): number
	local count = tables or 2
	return HEADER_H + 22 + count * rows * (ROW_H + ROW_GAP) + (count - 1) * SIDE_GAP + 8
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
	-- Your rank, under that, in Competitive.
	local rankLine = Ui.label(panel, {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, 32),
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
	local ffa: { Row } = {}
	for _ = 1, FFA_ROWS do
		table.insert(ffa, newRow(panel, 0))
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
		panel.Visible = on and arena ~= nil and not PlayMenu.open and (Scoreboard.held or phase == "matchOver")
		footer.Visible = panel.Visible and over
		if not panel.Visible or not arena then
			gui:SetAttribute("Ult", nil)
			return
		end
		local spike = arena:GetAttribute("Mode") == "spike"
		local gunGame = arena:GetAttribute("Mode") == "gungame"
		local deathmatch = arena:GetAttribute("Mode") == "deathmatch"
		local teamDeathmatch = arena:GetAttribute("Mode") == "teamdeathmatch"
		-- Whether everyone plays an agent (system 51).
		local agents = not gunGame and not deathmatch
		local ladder = {}
		if gunGame then
			local text = arena:GetAttribute("Ladder")
			for id in string.gmatch(if typeof(text) == "string" then text else "", "[^,]+") do
				table.insert(ladder, id)
			end
		end
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
			local drawn = teamDeathmatch and winner == nil
			local place = me:GetAttribute(DeathmatchConfig.PLACE)
			title = if drawn
				then "DRAW"
				elseif not playing then "MATCH OVER"
				elseif won then "VICTORY"
				elseif deathmatch and typeof(place) == "number" then string.upper(Ui.ordinal(place)) .. " PLACE"
				else "DEFEAT"
			local colour = if drawn or not playing then Ui.TEXT elseif won then ally else enemy
			title = string.format('<font color="#%s">%s</font>', Ui.hex(colour), title)
			local endsAt = arena:GetAttribute("PhaseEndsAt")
			local left = if typeof(endsAt) == "number" then math.max(endsAt - Workspace:GetServerTimeNow(), 0) else 0
			-- What follows: the vote for the next map, where the mode has one,
			-- then the next match.
			local coming = if phase == "matchOver" and arena:GetAttribute("MapVote") == true then "MAP VOTE" else "NEXT MATCH"
			footer.Text = string.format("%s IN %d", coming, math.ceil(left))
			local tier, last = me:GetAttribute(RankConfig.TIER), me:GetAttribute(RankConfig.LAST)
			rankLine.Visible = playing and formatKey == CareerRules.RANKED and typeof(tier) == "number" and typeof(last) == "number"
			if rankLine.Visible then
				local note = me:GetAttribute(RankConfig.NOTE)
				rankLine.Text = RankRules.verdict(
					tier,
					me:GetAttribute(RankConfig.RR) or 0,
					me:GetAttribute(RankConfig.GAMES) or 0,
					me:GetAttribute(RankConfig.SHIELDS) or 0,
					last,
					if typeof(note) == "string" then note else nil
				)
				rankLine.TextColor3 = if note == "promoted" or note == "placed"
					then Ui.GOOD
					elseif note == "demoted" then Ui.BAD
					else Ui.TEXT
			end
		else
			rankLine.Visible = false
			local name = if gunGame
				then "GUN GAME"
				elseif deathmatch then string.format("DEATHMATCH   FIRST TO %d", arena:GetAttribute("WinScore") or 0)
				elseif teamDeathmatch then string.format("TEAM DEATHMATCH   FIRST TO %d", arena:GetAttribute("WinScore") or 0)
				elseif not spike then "SKIRMISH"
				elseif format then string.upper(format.name)
				else "SPIKE ROUNDS"
			title = name .. (if round > 0 then string.format("   ROUND %d", round) else "")
		end
		-- Deathmatch's has no sides' scores either side.
		header.Text = if deathmatch
			then title
			else string.format(
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
		titles.ult.Visible = agents and not over
		titles.acs.Text = if gunGame then "LEVEL" elseif deathmatch then "PLACE" elseif teamDeathmatch then "SCORE" else "ACS"
		titles.loadout.Text = if gunGame then "GUN" else "LOADOUT"

		local leader = arena:GetAttribute("Leader")
		if deathmatch then
			for _, rows in sides do
				for _, row in rows do
					row.frame.Visible = false
				end
			end
			local lines = placesOf()
			panel.Size = UDim2.fromOffset(WIDTH, heightFor(math.clamp(#lines, 1, FFA_ROWS), 1))
			for r, row in ffa do
				local line = lines[r]
				row.frame.Visible = line ~= nil
				if not line then
					continue
				end
				row.frame.Position = UDim2.fromOffset(8, top + (r - 1) * (ROW_H + ROW_GAP))
				local who = line.who
				local cells = row.cells
				local mine = who.player == me
				local alive = line.alive or over
				row.frame.BackgroundColor3 = if mine then MINE else Ui.PANEL
				row.strip.BackgroundColor3 = if mine then ally else enemy
				row.strip.BackgroundTransparency = if alive then 0 else 0.6
				showAgent(cells.agent, "", enemy, alive)
				cells.ult.Text = ""
				cells.name.Text = who.name
				cells.name.TextColor3 = if mine then GOLD else Ui.TEXT
				cells.name.TextTransparency = if alive then 0 else 0.5
				cells.k.Text = tostring(line.kills)
				cells.d.Text = tostring(line.deaths)
				cells.a.Text = tostring(line.assists)
				cells.acs.Text = if line.place < math.huge then Ui.ordinal(line.place) else ""
				cells.credits.Text = ""
				if over then
					-- Whoever won, if anyone scored.
					local mvp = who.id == leader and line.kills > 0
					cells.loadout.Text = if mvp then "<b>" .. MATCH_MVP .. "</b>" else ""
					cells.loadout.TextColor3 = GOLD
				else
					cells.loadout.Text = if mine then loadoutOf(who) else ""
					cells.loadout.TextColor3 = Ui.TEXT
				end
			end
			gui:SetAttribute("Ult", nil)
			return
		end
		for _, row in ffa do
			row.frame.Visible = false
		end
		local lines = { linesOf(side, gunGame, leader), linesOf(other, gunGame, leader) }
		local shown = math.clamp(math.max(#lines[1], #lines[2]), 1, ROWS)
		-- Which table has the match's MVP: the best of the two sides' best.
		local first, second = lines[1][1], lines[2][1]
		local mvpTable = 1
		if second and (not first or second.rank > first.rank or (second.rank == first.rank and other == winner)) then
			mvpTable = 2
		end
		panel.Size = UDim2.fromOffset(WIDTH, heightFor(shown))
		local listed = {}
		for i, rows in sides do
			local ours = i == 1 and playing
			local colour = if i == 1 then ally else enemy
			local sideLines = lines[i]
			local y = top + (i - 1) * (shown * (ROW_H + ROW_GAP) + SIDE_GAP)
			-- The side's best, if they scored at all.
			local best = sideLines[1]
			local mvp = if over and best and best.rank > 0 then best.who.id else nil
			local badge = if i == mvpTable then MATCH_MVP else TEAM_MVP
			for r, row in rows do
				local line = sideLines[r]
				row.frame.Visible = line ~= nil
				if not line then
					continue
				end
				row.frame.Position = UDim2.fromOffset(8, y + (r - 1) * (ROW_H + ROW_GAP))
				local who = line.who
				local player = who.holder
				local cells = row.cells
				local mine = who.player == me
				-- Nobody's dimmed once the match is over.
				local alive = line.alive or over
				row.frame.BackgroundColor3 = if mine then MINE else Ui.PANEL
				row.strip.BackgroundColor3 = colour
				row.strip.BackgroundTransparency = if alive then 0 else 0.6
				-- Their agent, and while the match is on their ultimate.
				local letters = if agents then Glance.badge(player:GetAttribute(AgentSelect.AGENT), Who.plain(who.name)) else ""
				showAgent(cells.agent, letters, colour, alive)
				local ult = if agents and not over then Glance.cell(player:GetAttribute(AbilityConfig.ULT_ATTRIBUTE)) else ""
				cells.ult.Text = ult
				cells.ult.TextColor3 = if ult == Glance.READY then GOLD else Ui.TEXT
				cells.ult.TextTransparency = if alive then 0 else 0.5
				if agents and not over then
					table.insert(listed, letters .. " " .. who.name .. (if ult ~= "" then " " .. ult else ""))
				end
				cells.name.Text = who.name
				cells.name.TextColor3 = if mine then GOLD else Ui.TEXT
				cells.name.TextTransparency = if alive then 0 else 0.5
				cells.k.Text = tostring(line.kills)
				cells.d.Text = tostring(line.deaths)
				cells.a.Text = tostring(line.assists)
				cells.acs.Text = tostring(if gunGame then line.level else line.acs)
				local credits = player:GetAttribute(if ours then MatchConfig.CREDITS else MatchConfig.START_CREDITS)
				cells.credits.Text = if spike and not over and typeof(credits) == "number" then tostring(credits) else ""
				cells.credits.TextColor3 = GOLD
				if over then
					cells.loadout.Text = if who.id == mvp then "<b>" .. badge .. "</b>" else ""
					cells.loadout.TextColor3 = if badge == MATCH_MVP then GOLD else Ui.TEXT
				elseif gunGame then
					-- Everyone's gun is their level's, so both sides show.
					local def = WeaponConfig.Defs[ladder[line.level] or ""]
					cells.loadout.Text = if def then string.upper(def.name) else ""
					cells.loadout.TextColor3 = Ui.TEXT
				else
					cells.loadout.Text = if ours then loadoutOf(who) else ""
					cells.loadout.TextColor3 = Ui.TEXT
				end
			end
		end
		gui:SetAttribute("Ult", if agents and not over then table.concat(listed, ", ") else nil)
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
