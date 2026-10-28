--!strict
-- The combat report on screen (system 53), as the reference's: on the right
-- as you die ('a combat report notification will pop up on the right side
-- of your screen', ONE Esports), N showing or hiding it (Riot's UI Settings
-- FAQ). In Skirmish and the spike rounds the round's report shows again
-- through the next buy phase, until the round goes live, N still showing or
-- hiding it (Patch 9.02: 'visible during the Buy Phase by default'). Any
-- other goes as you come back (Patch 9.04 fixed reports 'flickering after
-- respawning in Team Deathmatch'), and every one as a match ends, for its
-- victory screen (Patch 9.04 fixed reports 'overlapping with the
-- Victory/Defeat ceremony'). On the course, N asks the server for yours so
-- far at any time.
--
-- Its head says who killed you and with what, or the spike or a spawn
-- room. Then a row for everyone you fought, whoever killed you first and
-- the rest as you met them: their agent, their name in their side's colour
-- (yours for yourself, SELF), whether you killed them or they you, and
-- under DEALT and TAKEN the damage each way in whole points, each with a
-- figure lit where the bullets and blades struck, the head, the body and
-- the legs, and how many there. At its foot all you dealt and took. Mouse 3
-- opens its details beside it (Patch 9.04), each row's weapons and
-- abilities each way, under 'Weapon / Ability', 'Damage' and 'Hits' (Patch
-- 9.02); a fire's burn has no hits.
--
-- Its gui's attributes say what it holds, for scripted checks: Shown,
-- Details, Final, Round, Killer, Rows (CombatReport.rowText's, in its
-- order) and Totals.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AgentSelect = require(Shared.Abilities.AgentSelect)
local Glance = require(Shared.Abilities.Glance)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local TeamDeathmatchConfig = require(Shared.Arena.TeamDeathmatchConfig)
local CombatReport = require(Shared.Match.CombatReport)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

local Ui = require(script.Parent.Debug.Ui)
local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local Visuals = require(script.Parent.Visuals)
local Who = require(script.Parent.Who)

local ReportView = {}

local WIDTH = 360
local TOP = 196 -- under the kill feed's rows
local HEADER_H = 30
local KILLER_H = 34
local ROW_H, ROW_GAP = 50, 2
local MORE_H = 18
local EMPTY_H = 26
local FOOT_H = 26
local ROWS = 8 -- at most, then how many more
local DETAILS_W = 300
local DETAIL_LINES = 24 -- at most
local REFRESH = 0.5 -- seconds between redraws while up, for names and agents
local GOLD = Color3.fromRGB(230, 200, 120)
local RED = Color3.fromRGB(240, 80, 80)
local SPIKE_RED = Color3.fromRGB(235, 70, 60)

type Figure = { parts: { Frame }, counts: { TextLabel } }
type Column = { caption: TextLabel, number: TextLabel, figure: Figure }
type RowUi = { frame: Frame, badge: TextLabel, name: TextLabel, tag: TextLabel, dealt: Column, taken: Column }

local report: CombatReport.Report? = nil
local final = false -- the round's last, kept through the next buy phase
local round: number? = nil
local shown = false
local details = false
local version = 0

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

local function playerOf(id: number): Player?
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == id then
			return player
		end
	end
	return nil
end

-- A dummy's name, a player's or a bot's (system 60).
local function nameOf(id: number): string
	if PlayerCodec.isDummy(id) then
		return string.format("Dummy %d", id - PlayerCodec.DUMMY_BASE)
	end
	return Who.name(id) or "?"
end

-- The ally colour for you and your side, the enemy colour for anyone else.
local function colourOf(id: number): Color3
	if id == PlayerCodec.entityIdForUser(Players.LocalPlayer.UserId) or Who.ally(id) then
		return color3(VisualConfig.allyColour)
	end
	return color3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
end

local function badgeOf(id: number): string
	local player = playerOf(id)
	return Glance.badge(if player then player:GetAttribute(AgentSelect.AGENT) else nil, nameOf(id))
end

local function weaponName(weapon: string): string
	local def = WeaponConfig.Defs[weapon]
	if def then
		return def.name
	end
	return if weapon == TeamDeathmatchConfig.BURN then "Spawn room" else weapon
end

local function onCourse(): boolean
	return Workspace:GetAttribute(ArenaConfig.ON) ~= true
end

local function drop()
	report, final, round = nil, false, nil
	shown, details = false, false
	version += 1
end

local function ask(what: string)
	NetSim.fireServer(Remotes.get().Report, what)
end

-- N: shows or hides the report, if there's one to show; on the course,
-- asks for yours so far, which shows as it comes.
function ReportView.toggle()
	if shown then
		shown, details = false, false
	elseif onCourse() then
		ask("now")
	elseif report then
		shown = true
	end
	version += 1
end

-- Mouse 3: the details, while the report's up.
function ReportView.more()
	if shown then
		details = not details
		version += 1
	end
end

-- What a scripted check asks for (TestAim's VFTestReport): "toggle" as N,
-- "details" as mouse 3.
function ReportView.test(what: string)
	if what == "toggle" then
		ReportView.toggle()
	elseif what == "details" then
		ReportView.more()
	end
end

-- The phase of what's played, nil on the course.
local function phaseNow(): any
	local arena = if onCourse() then nil else Workspace:FindFirstChild(ArenaConfig.MODEL)
	return if arena then arena:GetAttribute("Phase") else nil
end

local function onReport(event: any)
	if typeof(event) ~= "table" or typeof(event.report) ~= "table" or typeof(event.report.rows) ~= "table" then
		return
	end
	-- Never over a match's victory screen, nor the vote after it.
	local phase = phaseNow()
	if phase == "matchOver" or phase == "vote" then
		return
	end
	report = event.report
	final = event.final == true
	round = if typeof(event.round) == "number" then event.round else nil
	if event.kind == "death" or event.kind == "now" or (final and phase == "buy") then
		shown = true
	end
	version += 1
end

local function figure(parent: Instance, x: number): Figure
	local parts = {
		Ui.frame(parent, { Position = UDim2.fromOffset(x + 3, 6), Size = UDim2.fromOffset(7, 7) }),
		Ui.frame(parent, { Position = UDim2.fromOffset(x + 1, 15), Size = UDim2.fromOffset(11, 14) }),
		Ui.frame(parent, { Position = UDim2.fromOffset(x + 1, 31), Size = UDim2.fromOffset(11, 13) }),
	}
	local head = Instance.new("UICorner")
	head.CornerRadius = UDim.new(0.5, 0)
	head.Parent = parts[1]
	local counts = {}
	for i, y in { 3, 15, 31 } do
		counts[i] = Ui.label(parent, {
			Position = UDim2.fromOffset(x + 16, y),
			Size = UDim2.fromOffset(20, 13),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
	end
	return { parts = parts, counts = counts }
end

local function column(parent: Instance, x: number, caption: string): Column
	local c = Ui.label(parent, {
		Position = UDim2.fromOffset(x, 5),
		Size = UDim2.fromOffset(46, 12),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = Ui.DIM,
		Text = caption,
	})
	local number = Ui.label(parent, {
		Position = UDim2.fromOffset(x, 18),
		Size = UDim2.fromOffset(46, 24),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	return { caption = c, number = number, figure = figure(parent, x + 48) }
end

local function newRow(parent: Instance): RowUi
	local frame = Ui.frame(parent, { Size = UDim2.new(1, -12, 0, ROW_H), BackgroundTransparency = 0.5, Visible = false })
	local badge = Ui.label(frame, {
		Position = UDim2.fromOffset(8, (ROW_H - 28) / 2),
		Size = UDim2.fromOffset(28, 28),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundTransparency = 0.15,
		TextColor3 = Ui.PANEL,
	})
	local name = Ui.label(frame, {
		Position = UDim2.fromOffset(44, 8),
		Size = UDim2.fromOffset(124, 18),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local tag = Ui.label(frame, {
		Position = UDim2.fromOffset(44, 28),
		Size = UDim2.fromOffset(124, 14),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
	})
	return {
		frame = frame,
		badge = badge,
		name = name,
		tag = tag,
		dealt = column(frame, 172, "DEALT"),
		taken = column(frame, 260, "TAKEN"),
	}
end

-- One way into a column: its damage, and the figure lit where it struck.
local function showWay(c: Column, way: CombatReport.Way?)
	c.caption.Visible = way ~= nil
	c.number.Visible = way ~= nil
	local counts = if way then { way.head, way.body, way.legs } else { 0, 0, 0 }
	for i, part in c.figure.parts do
		local lit = counts[i] > 0
		part.Visible = way ~= nil
		part.BackgroundColor3 = if lit then Ui.TEXT else Ui.DIM
		part.BackgroundTransparency = if lit then 0 else 0.65
		local count = c.figure.counts[i]
		count.Visible = way ~= nil
		count.Text = tostring(counts[i])
		count.TextColor3 = if lit then Ui.TEXT else Ui.DIM
	end
	if way then
		c.number.Text = tostring(CombatReport.points(way.damage))
	end
end

-- The details, a line each: whom a row's with and which way, then its
-- weapons and abilities with their damage and hits ('-' for a burn's).
local function detailText(rows: { CombatReport.Row }, me: number): string
	local lines = { string.format("%-20s %6s %5s", "WEAPON / ABILITY", "DAMAGE", "HITS") }
	local function group(title: string, way: CombatReport.Way)
		if #way.lines == 0 then
			return
		end
		table.insert(lines, title)
		for _, line in way.lines do
			local hits = CombatReport.hits(line)
			table.insert(
				lines,
				string.format(
					"  %-18s %6d %5s",
					string.sub(weaponName(line.weapon), 1, 18),
					CombatReport.points(line.damage),
					if hits > 0 then tostring(hits) else "-"
				)
			)
		end
	end
	for _, row in rows do
		if row.other == me then
			group("SELF", row.taken)
		else
			local name = string.sub(nameOf(row.other), 1, 16)
			group("TO " .. name, row.dealt)
			group("FROM " .. name, row.taken)
		end
	end
	if #lines > DETAIL_LINES then
		local cut = #lines - (DETAIL_LINES - 1)
		while #lines > DETAIL_LINES - 1 do
			table.remove(lines)
		end
		table.insert(lines, string.format("  and %d more", cut))
	end
	return table.concat(lines, "\n")
end

function ReportView.start()
	local gui = Ui.screen("VFCombatReport", 15)
	local panel = Ui.frame(gui, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, TOP),
		Size = UDim2.fromOffset(WIDTH, 100),
		BackgroundTransparency = 0.2,
		Visible = false,
	})
	Ui.label(panel, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 0, HEADER_H),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "COMBAT REPORT",
	})
	local roundLabel = Ui.label(panel, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 0, HEADER_H),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local killer = Ui.frame(panel, {
		Position = UDim2.fromOffset(6, HEADER_H),
		Size = UDim2.new(1, -12, 0, KILLER_H - 4),
		BackgroundTransparency = 0.5,
	})
	Ui.label(killer, {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.fromOffset(70, KILLER_H - 4),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Ui.DIM,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "KILLED BY",
	})
	local killerBadge = Ui.label(killer, {
		Position = UDim2.fromOffset(78, 3),
		Size = UDim2.fromOffset(24, 24),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundTransparency = 0.15,
		TextColor3 = Ui.PANEL,
	})
	local killerText = Ui.label(killer, {
		Position = UDim2.fromOffset(110, 0),
		Size = UDim2.new(1, -118, 1, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local rows: { RowUi } = {}
	for _ = 1, ROWS do
		table.insert(rows, newRow(panel))
	end
	local more = Ui.label(panel, {
		Size = UDim2.new(1, -24, 0, MORE_H),
		TextSize = 12,
		TextColor3 = Ui.DIM,
	})
	local empty = Ui.label(panel, {
		Size = UDim2.new(1, -24, 0, EMPTY_H),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Ui.DIM,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "NOTHING DEALT OR TAKEN",
	})
	local foot = Ui.label(panel, {
		Size = UDim2.new(1, -24, 0, FOOT_H),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local hint = Ui.label(panel, {
		Size = UDim2.new(1, -24, 0, FOOT_H),
		TextSize = 11,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "N hide   M3 details",
	})
	local detailPanel = Ui.frame(gui, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12 - WIDTH - 8, 0, TOP),
		Size = UDim2.fromOffset(DETAILS_W, 100),
		BackgroundTransparency = 0.2,
		Visible = false,
	})
	local detailLabel = Ui.label(detailPanel, {
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 1, -16),
		TextSize = 12,
		RichText = false,
	})

	local function render()
		local r = report
		local me = PlayerCodec.entityIdForUser(Players.LocalPlayer.UserId)
		gui:SetAttribute("Shown", shown and r ~= nil)
		gui:SetAttribute("Details", shown and r ~= nil and details)
		gui:SetAttribute("Final", if r then final else nil)
		gui:SetAttribute("Round", if r then round else nil)
		panel.Visible = shown and r ~= nil
		detailPanel.Visible = panel.Visible and details
		if not r then
			gui:SetAttribute("Killer", nil)
			gui:SetAttribute("Rows", nil)
			gui:SetAttribute("Totals", nil)
			return
		end
		local ordered = CombatReport.ordered(r)
		roundLabel.Text = if round then string.format("ROUND %d", round) else ""
		-- Who killed you, if anyone did.
		local y = HEADER_H
		local death = r.death
		killer.Visible = death ~= nil
		if death then
			local by = death.by
			local with = weaponName(death.weapon)
			killerBadge.Visible = by ~= nil
			if by == me then
				killerBadge.Text = badgeOf(me)
				killerBadge.BackgroundColor3 = colourOf(me)
				killerText.Text = "YOURSELF   " .. with
				killerText.TextColor3 = colourOf(me)
				gui:SetAttribute("Killer", "yourself, " .. with)
			elseif by then
				killerBadge.Text = badgeOf(by)
				killerBadge.BackgroundColor3 = colourOf(by)
				killerText.Text = nameOf(by) .. "   " .. with
				killerText.TextColor3 = colourOf(by)
				gui:SetAttribute("Killer", nameOf(by) .. ", " .. with)
			else
				killerText.Position = UDim2.fromOffset(78, 0)
				killerText.Text = "THE " .. string.upper(with)
				killerText.TextColor3 = SPIKE_RED
				gui:SetAttribute("Killer", "the " .. string.lower(with))
			end
			if by then
				killerText.Position = UDim2.fromOffset(110, 0)
			end
			y += KILLER_H
		else
			gui:SetAttribute("Killer", "")
		end
		-- A row for everyone you fought.
		local texts = {}
		for i, ui in rows do
			local row = ordered[i]
			ui.frame.Visible = row ~= nil
			if not row then
				continue
			end
			ui.frame.Position = UDim2.fromOffset(6, y)
			y += ROW_H + ROW_GAP
			local own = row.other == me
			local colour = colourOf(row.other)
			ui.badge.Text = badgeOf(row.other)
			ui.badge.BackgroundColor3 = colour
			ui.name.Text = nameOf(row.other)
			ui.name.TextColor3 = colour
			local tags = {}
			if own then
				table.insert(tags, "SELF")
			end
			if row.kills > 0 then
				table.insert(
					tags,
					string.format(
						'<font color="#%s">%s</font>',
						Ui.hex(GOLD),
						if row.kills > 1 then string.format("KILLED x%d", row.kills) else "KILLED"
					)
				)
			end
			if row.deaths > 0 and not own then
				table.insert(tags, string.format('<font color="#%s">%s</font>', Ui.hex(RED), "KILLED YOU"))
			end
			ui.tag.Text = table.concat(tags, "   ")
			ui.tag.TextColor3 = Ui.DIM
			-- What you did to yourself, you took.
			showWay(ui.dealt, if own then nil else row.dealt)
			showWay(ui.taken, row.taken)
		end
		for _, row in ordered do
			table.insert(texts, CombatReport.rowText(row, if row.other == me then "Self" else nameOf(row.other)))
		end
		more.Visible = #ordered > ROWS
		if more.Visible then
			more.Position = UDim2.fromOffset(12, y)
			more.Text = string.format("and %d more", #ordered - ROWS)
			y += MORE_H
		end
		empty.Visible = #ordered == 0
		if empty.Visible then
			empty.Position = UDim2.fromOffset(12, y)
			y += EMPTY_H
		end
		local dealt, taken = CombatReport.totals(r)
		foot.Position = UDim2.fromOffset(12, y)
		foot.Text = string.format("DEALT %d   TAKEN %d", dealt, taken)
		hint.Position = UDim2.fromOffset(12, y)
		y += FOOT_H + 4
		panel.Size = UDim2.fromOffset(WIDTH, y)
		gui:SetAttribute("Rows", table.concat(texts, "; "))
		gui:SetAttribute("Totals", string.format("dealt %d, taken %d", dealt, taken))
		if detailPanel.Visible then
			detailLabel.Text = detailText(ordered, me)
			local lines = #string.split(detailLabel.Text, "\n")
			detailPanel.Size = UDim2.fromOffset(DETAILS_W, 16 + lines * 15)
		end
	end

	NetSim.on(Remotes.get().Report, onReport)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.N then
			ReportView.toggle()
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			ReportView.more()
		end
	end)
	-- Yours, if you died in what's being played before you joined it.
	ask("back")

	local wasAlive = PlayerController.alive
	local lastPhase: any = nil
	local lastOn: any = Workspace:GetAttribute(ArenaConfig.ON)
	local drawn, drawnAt = -1, -math.huge
	RunService.RenderStepped:Connect(function()
		local alive = PlayerController.alive
		-- Back in play: the report goes, unless it's the round's last.
		if alive and not wasAlive and report and not final then
			drop()
		end
		wasAlive = alive
		local on = Workspace:GetAttribute(ArenaConfig.ON)
		local phase = phaseNow()
		if on ~= lastOn then
			lastOn = on
			drop()
		elseif phase ~= lastPhase then
			if phase == "buy" and report and final then
				shown = true
				version += 1
			elseif (phase == "live" or phase == "matchOver" or phase == "vote") and report then
				drop()
			end
		end
		lastPhase = phase
		local now = os.clock()
		if version ~= drawn or (shown and now - drawnAt >= REFRESH) then
			drawn, drawnAt = version, now
			render()
		end
	end)
end

return ReportView
