--!strict
-- Agent select (system 29), on T: a card for each agent you can pick, with
-- its name and role, the kit of the one selected (or under the cursor),
-- what your teammates have selected, and LOCK IN, as the reference's agent
-- select. Once a match you have a window, from the match's start or from
-- when you join it under way: click an agent and LOCK IN, and when the
-- time's up the agent selected is locked in for you. After that it's yours
-- until the match is over. The menu comes up by itself as your window
-- opens, when there's more than one agent to pick from, and goes as it
-- closes. On the course and while a mode waits for players, an agent picked
-- is yours at once, as often as you like. Nobody picks in gun game or
-- deathmatch, or between matches. It doesn't open over the Play menu
-- (system 24) or another menu, but the settings menu opens over it. While
-- it's open the mouse moves a cursor and its buttons are the menu's, and
-- you can still move.
--
-- One of each agent on a side (system 48): an agent a teammate has locked
-- in is taken, its card dimmed and tagged TAKEN, and a click on it does
-- nothing; under the cursor, the menu says so.
--
-- Everything comes from player attributes (AgentSelect's, from
-- AgentServer): your own, and your teammates' for what they've selected and
-- locked in. An agent locked in where it can't go on your kit at once
-- comes with your next life, and the menu says so.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local AgentSelect = require(Shared.Abilities.AgentSelect)
local Remotes = require(Shared.Net.Remotes)

local BuyMenu = require(script.Parent.BuyMenu)
local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)
local LoadoutMenu = require(script.Parent.LoadoutMenu)
local PlayerController = require(script.Parent.PlayerController)
local PlayMenu = require(script.Parent.PlayMenu)
local SettingsMenu = require(script.Parent.SettingsMenu)
local Ui = require(script.Parent.Debug.Ui)

local AgentMenu = {}

AgentMenu.open = false
-- Opens or closes the menu (T, and TestAim's VFTestAgents), where you can
-- pick. Set up by AgentMenu.start.
AgentMenu.setOpen = function(_open: boolean) end

-- Your last click on a card, shown as selected until the server has it.
local clicked: { agent: string, at: number }? = nil
-- How long a click is shown before the server's word on it wins (ours).
local CLICK_HOLD = 1

-- Selects an agent, as a click on its card does (and TestAim's
-- VFTestAgent).
function AgentMenu.select(agent: string)
	clicked = { agent = agent, at = os.clock() }
	Remotes.get().AgentPick:FireServer("select", agent)
end

-- Locks in what's selected, as the button does (and TestAim's VFTestAgent
-- "lock").
function AgentMenu.lock()
	Remotes.get().AgentPick:FireServer("lock")
end

local CARD_W, CARD_H = 112, 76
local PER_ROW = 6
local GAP = 10
local MARGIN = 24
local TOP = 84
local KIT_W = 470
local KIT_ROW = 50
local MATE_ROW = 34
local MATES = 4 -- teammates shown: the rest of a side of five
local BUTTON_W, BUTTON_H = 240, 48

local TILE = Color3.fromRGB(28, 30, 38)
local TILE_HOVER = Color3.fromRGB(48, 52, 64)
local GOLD = Color3.fromRGB(230, 200, 120)
local INK = Color3.fromRGB(20, 20, 24)

type Card = { agent: string, button: TextButton, stroke: UIStroke, tag: TextLabel }
type KitRow = { key: TextLabel, name: TextLabel, body: TextLabel }
type MateRow = { name: TextLabel, agent: TextLabel, state: TextLabel }

local me = Players.LocalPlayer

local function text(player: Player, name: string): string?
	local value = player:GetAttribute(name)
	return if typeof(value) == "string" then value else nil
end

-- Where a player stands for picking: AgentSelect's "free", "open" or
-- "locked", or nil where nobody picks.
local function statusOf(player: Player): string?
	return text(player, AgentSelect.STATUS)
end

-- Whether it may be open: where you can pick, and not over the Play menu.
local function allowed(): boolean
	return statusOf(me) ~= nil and not PlayMenu.open
end

local function nameOf(agent: string?): string
	local def = if agent then AbilityConfig.Agents[agent] else nil
	return if def then string.upper(def.name) else ""
end

-- Your teammates, by name: whoever's on your team but you.
local function teammates(): { Player }
	local out = {}
	if me.Team then
		for _, player in Players:GetPlayers() do
			if player ~= me and player.Team == me.Team then
				table.insert(out, player)
			end
		end
	end
	table.sort(out, function(a: Player, b: Player): boolean
		return a.DisplayName < b.DisplayName
	end)
	return out
end

-- Of `agents`, those taken from you while you're in a match: what your
-- teammates have locked in, as the server has it (AgentSelect.taken).
local function takenFrom(team: { Player }, agents: { string }): { [string]: boolean }
	local status = statusOf(me)
	local locked = {}
	if status == "open" or status == "locked" then
		for _, mate in team do
			local agent = text(mate, AgentSelect.AGENT)
			if agent and statusOf(mate) == "locked" then
				table.insert(locked, agent)
			end
		end
	end
	return AgentSelect.takenOf(agents, locked)
end

function AgentMenu.start()
	local agents = AgentSelect.pickable()
	-- Under the settings menu, which can open over it.
	local gui = Ui.screen("VFAgents", 20)
	gui.Enabled = false
	local rows = math.max(math.ceil(#agents / PER_ROW), 1)
	local width = 2 * MARGIN + PER_ROW * CARD_W + (PER_ROW - 1) * GAP
	local kitTop = TOP + rows * (CARD_H + GAP) + 8
	local kitH = 30 + (AbilityConfig.SLOTS + 1) * KIT_ROW
	local height = kitTop + kitH + 16 + BUTTON_H + 40
	local root = Ui.frame(gui, {
		Name = "Agents",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.15,
		Active = true,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = root
	Ui.label(root, {
		Text = "AGENT SELECT",
		Font = Enum.Font.GothamBold,
		TextSize = 28,
		Position = UDim2.fromOffset(MARGIN, 16),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 32),
	})
	local clock = Ui.label(root, {
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(MARGIN, 24),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 20),
	})
	local hint = Ui.label(root, {
		TextSize = 13,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(MARGIN, 56),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 18),
	})
	Ui.label(root, {
		Text = "T to close",
		TextSize = 13,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(MARGIN, height - 30),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 18),
	})

	-- A card for each agent.
	local cards: { Card } = {}
	local hovered: string? = nil
	-- What your teammates have taken, as the menu last showed it.
	local taken: { [string]: boolean } = {}
	for i, id in agents do
		local agent = AbilityConfig.Agents[id]
		local column, row = (i - 1) % PER_ROW, (i - 1) // PER_ROW
		local button = Instance.new("TextButton")
		button.Name = id
		button.AutoButtonColor = false
		button.Text = ""
		button.BorderSizePixel = 0
		button.BackgroundColor3 = TILE
		button.BackgroundTransparency = 0.1
		button.Position = UDim2.fromOffset(MARGIN + column * (CARD_W + GAP), TOP + row * (CARD_H + GAP))
		button.Size = UDim2.fromOffset(CARD_W, CARD_H)
		button.Parent = root
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Thickness = 3
		stroke.Color = GOLD
		stroke.Transparency = 1
		stroke.Parent = button
		Ui.label(button, {
			Text = string.upper(agent.name),
			Font = Enum.Font.GothamBold,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(6, 18),
			Size = UDim2.fromOffset(CARD_W - 12, 22),
		})
		Ui.label(button, {
			Text = string.upper(agent.role),
			TextSize = 11,
			TextColor3 = Ui.DIM,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(6, 42),
			Size = UDim2.fromOffset(CARD_W - 12, 14),
		})
		local tag = Ui.label(button, {
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = GOLD,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(6, 4),
			Size = UDim2.fromOffset(CARD_W - 12, 12),
		})
		button.MouseEnter:Connect(function()
			hovered = id
		end)
		button.MouseLeave:Connect(function()
			if hovered == id then
				hovered = nil
			end
		end)
		button.MouseButton1Click:Connect(function()
			if not taken[id] then
				AgentMenu.select(id)
			end
		end)
		table.insert(cards, { agent = id, button = button, stroke = stroke, tag = tag })
	end

	-- The kit of the agent shown: its four abilities, each with its key,
	-- and its passive.
	local kit = Ui.frame(root, {
		Name = "Kit",
		Position = UDim2.fromOffset(MARGIN, kitTop),
		Size = UDim2.fromOffset(KIT_W, kitH),
		BackgroundColor3 = TILE,
		BackgroundTransparency = 0.1,
	})
	local kitHead = Ui.label(kit, {
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.fromOffset(KIT_W - 24, 22),
	})
	local kitRows: { KitRow } = {}
	for i = 1, AbilityConfig.SLOTS + 1 do
		local y = 30 + (i - 1) * KIT_ROW
		table.insert(kitRows, {
			key = Ui.label(kit, {
				Font = Enum.Font.GothamBold,
				TextSize = 22,
				TextColor3 = Ui.DIM,
				Position = UDim2.fromOffset(12, y + 6),
				Size = UDim2.fromOffset(30, 26),
			}),
			name = Ui.label(kit, {
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				Position = UDim2.fromOffset(48, y + 4),
				Size = UDim2.fromOffset(KIT_W - 60, 16),
			}),
			body = Ui.label(kit, {
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Ui.DIM,
				TextWrapped = true,
				Position = UDim2.fromOffset(48, y + 20),
				Size = UDim2.fromOffset(KIT_W - 60, 30),
			}),
		})
	end

	-- Your teammates, and what each has selected.
	local mateX = MARGIN + KIT_W + GAP
	local mateW = width - MARGIN - mateX
	local mates = Ui.frame(root, {
		Name = "Team",
		Position = UDim2.fromOffset(mateX, kitTop),
		Size = UDim2.fromOffset(mateW, kitH),
		BackgroundColor3 = TILE,
		BackgroundTransparency = 0.1,
	})
	Ui.label(mates, {
		Text = "YOUR TEAM",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(mateW - 24, 16),
	})
	local nobody = Ui.label(mates, {
		Text = "Nobody else on your side",
		TextSize = 12,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(12, 34),
		Size = UDim2.fromOffset(mateW - 24, 16),
	})
	local mateRows: { MateRow } = {}
	for i = 1, MATES do
		local y = 34 + (i - 1) * MATE_ROW
		table.insert(mateRows, {
			name = Ui.label(mates, {
				TextSize = 12,
				Position = UDim2.fromOffset(12, y),
				Size = UDim2.fromOffset(mateW - 24, 14),
			}),
			agent = Ui.label(mates, {
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				Position = UDim2.fromOffset(12, y + 15),
				Size = UDim2.fromOffset(mateW - 24, 16),
			}),
			state = Ui.label(mates, {
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.fromOffset(12, y + 17),
				Size = UDim2.fromOffset(mateW - 24, 12),
			}),
		})
	end

	local lockButton = Instance.new("TextButton")
	lockButton.Name = "LockIn"
	lockButton.AutoButtonColor = false
	lockButton.BorderSizePixel = 0
	lockButton.BackgroundColor3 = GOLD
	lockButton.Font = Enum.Font.GothamBold
	lockButton.TextSize = 20
	lockButton.TextColor3 = INK
	lockButton.Position = UDim2.fromOffset((width - BUTTON_W) / 2, kitTop + kitH + 16)
	lockButton.Size = UDim2.fromOffset(BUTTON_W, BUTTON_H)
	lockButton.Parent = root
	lockButton.MouseButton1Click:Connect(function()
		AgentMenu.lock()
	end)
	local note = Ui.label(root, {
		TextSize = 13,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(MARGIN, kitTop + kitH + 16 + BUTTON_H + 10),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 18),
	})

	local function setOpen(open: boolean)
		-- Not over the settings menu, the buy menu or the loadout menu, which
		-- have the cursor.
		open = open and allowed() and (AgentMenu.open or not CameraController.cursorFree)
		if open == AgentMenu.open then
			return
		end
		AgentMenu.open = open
		gui.Enabled = open
		if open or not SettingsMenu.open then
			CameraController.cursorFree = open
			InputSampler.blockMouse = open
		end
		if not open then
			hovered = nil
		end
	end
	AgentMenu.setOpen = setOpen

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.T then
			return
		end
		setOpen(not AgentMenu.open)
	end)

	-- The kit shown: the agent's name and role, its abilities by slot, and
	-- its passive; what can't be played yet dimmed.
	local function showKit(id: string)
		local agent = AbilityConfig.Agents[id]
		kitHead.Text = if agent
			then string.format('%s   <font color="#%s">%s</font>', string.upper(agent.name), Ui.hex(Ui.DIM), string.upper(agent.role))
			else ""
		for i, row in kitRows do
			if i <= AbilityConfig.SLOTS then
				local def = AbilityConfig.abilityOf(id, i)
				local playable = def ~= nil and AbilitySim.playable(def.id)
				row.key.Text = AbilityConfig.KEYS[i]
				row.name.Text = if def then string.upper(def.name) .. (if playable then "" else "   NOT YET") else ""
				row.name.TextColor3 = if playable then Ui.TEXT else Ui.DIM
				row.body.Text = if def then def.description else ""
			else
				local passive = if agent and agent.passive then AbilityConfig.Passives[agent.passive] else nil
				local works = agent ~= nil and agent.passive ~= nil and AbilitySim.playable(agent.passive)
				local tag = if works then "PASSIVE" else "PASSIVE   NOT YET"
				row.key.Text = ""
				row.name.Text = if passive
					then string.format('%s   <font color="#%s">%s</font>', string.upper(passive.name), Ui.hex(Ui.DIM), tag)
					else ""
				row.name.TextColor3 = if works then Ui.TEXT else Ui.DIM
				row.body.Text = if passive then passive.description else ""
			end
		end
	end

	-- When your window closes, while it's open; it comes up by itself as a
	-- new one opens.
	local seenWindow: number? = nil
	RunService.RenderStepped:Connect(function()
		local status = statusOf(me)
		local closes = me:GetAttribute(AgentSelect.CLOSES)
		local window = if status == "open" and typeof(closes) == "number" then closes else nil
		if window ~= seenWindow then
			if window and #agents > 1 then
				BuyMenu.setOpen(false)
				LoadoutMenu.setOpen(false)
				setOpen(true)
			elseif not window and seenWindow then
				setOpen(false)
			end
			seenWindow = window
		end
		if not AgentMenu.open then
			return
		end
		if not allowed() then
			setOpen(false)
			return
		end
		-- Every frame, as the vote does: the cursor stays the menu's while
		-- the settings menu opens and closes over it.
		CameraController.cursorFree = true
		InputSampler.blockMouse = true
		local viewport = Workspace.CurrentCamera.ViewportSize
		scale.Scale = math.min(1, (viewport.X - 40) / width, (viewport.Y - 40) / height)

		local yours = text(me, AgentSelect.AGENT) or AbilityConfig.DEFAULT_AGENT
		local picking = status == "open" or status == "free"
		local selected = if picking then text(me, AgentSelect.SELECTED) or yours else yours
		local team = teammates()
		taken = takenFrom(team, agents)
		-- Taken, as a card shows it: not the one you've locked in.
		local function gone(agent: string): boolean
			return taken[agent] == true and not (agent == yours and status == "locked")
		end
		local click = clicked
		if click and picking and os.clock() - click.at < CLICK_HOLD and not taken[click.agent] then
			selected = click.agent
		end
		local left = if window then math.max(window - Workspace:GetServerTimeNow(), 0) else 0
		if status == "open" then
			hint.Text = "Click an agent and LOCK IN; when time's up, the one selected is locked in for the match."
			clock.Text = string.format("LOCK IN WITHIN %d", math.ceil(left))
		elseif status == "free" then
			hint.Text = "Nothing's at stake here: an agent picked is yours at once, as often as you like."
			clock.Text = "PICK ANY TIME"
		else
			hint.Text = "Locked in until the match is over; you pick again as the next one starts."
			clock.Text = "LOCKED IN"
		end
		for _, card in cards do
			local mine = card.agent == selected
			local out = gone(card.agent)
			card.stroke.Transparency = if mine then 0 else 1
			card.button.BackgroundColor3 = if (card.agent == hovered and not out) or mine then TILE_HOVER else TILE
			card.button.BackgroundTransparency = if not out and (picking or card.agent == yours) then 0.1 else 0.55
			card.tag.Text = if out then "TAKEN" elseif card.agent == yours then (if status == "locked" then "LOCKED IN" else "YOURS") else ""
			card.tag.TextColor3 = if out then Ui.DIM else GOLD
		end
		showKit(hovered or selected)

		nobody.Visible = #team == 0
		for i, row in mateRows do
			local mate = team[i]
			local mateStatus = if mate then statusOf(mate) else nil
			local shown = if mate and mateStatus == "open" then text(mate, AgentSelect.SELECTED) else nil
			row.name.Text = if mate then string.upper(mate.DisplayName) else ""
			row.agent.Text = if mate then nameOf(shown or text(mate, AgentSelect.AGENT)) else ""
			row.agent.TextColor3 = if mateStatus == "open" then Ui.DIM else Ui.TEXT
			row.state.Text = if mateStatus == "open" then "SELECTING" elseif mateStatus == "locked" then "LOCKED IN" else ""
			row.state.TextColor3 = if mateStatus == "locked" then GOLD else Ui.DIM
		end

		if status == "open" then
			lockButton.Text = "LOCK IN"
		elseif status == "free" then
			lockButton.Text = if selected == yours then "PLAYING " .. nameOf(yours) else "PICK " .. nameOf(selected)
		else
			lockButton.Text = "LOCKED IN"
		end
		local live = status == "open" or (status == "free" and selected ~= yours)
		lockButton.BackgroundTransparency = if live then 0 else 0.6
		-- An agent locked in where it couldn't go on your kit at once.
		local sim = PlayerController.sim
		local kitAgent = if sim then sim.abilities.agent else nil
		local later = PlayerController.alive and kitAgent ~= nil and kitAgent ~= yours
		local over = hovered
		if over and gone(over) then
			note.Text = string.format("%s is taken: a teammate has locked it in", nameOf(over))
		else
			note.Text = if later then string.format("%s from your next life", nameOf(yours)) else ""
		end
	end)
end

return AgentMenu
