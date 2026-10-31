--!strict
-- The Play menu (system 24), as Counter Blox's main screen has it: "the
-- game modes" (Hotspawn's guide), a card for each with how many are in
-- servers playing it, and PLAY. PLAY for the mode this server plays puts
-- you in its match; for another, the server sends you to one playing it
-- (ModeServers), and the menu says so until you go, or why you couldn't.
--
-- On a live server the menu is up as you join, and stays until you've
-- pressed PLAY, unless you arrive having pressed it on another server and
-- go straight into the match. After that M opens and closes it over the
-- match, as M always does in Studio unless the place's PlayConfig.MENU was
-- on as the server started. While it's up the mouse moves a cursor, and
-- behind it is whoever Spectate watches.
--
-- Basic Training's card (system 72) reads SOLO: a server of your own.
--
-- Each card also has your own record in its mode (system 67): matches won
-- and lost and kills a death, and on Competitive's your rank, or the
-- placements played.
--
-- With a place held for you in a match under way (system 69), here or on
-- another server, its mode is picked and PLAY reads RECONNECT: pressed, it
-- puts you back in that match, sent back to its server if it's another.
-- Taken out of a match while you're still here (for being AFK, system 70,
-- your MatchConfig.AFK_OUT, or Studio's VFTestAway), the menu opens, on a
-- server that has you pick first, and says why.
--
-- Everything comes from attributes: Workspace's PlayConfig.COUNTS and what
-- the arena plays (ArenaConfig.ON and MODE, MatchConfig.FORMAT, and on the
-- course TrainingConfig.ON), and your own PlayConfig.PLAYING,
-- PlayConfig.REJOIN, CareerRules.ATTRIBUTE and RankConfig's; and from the
-- Play remote, what came of a press.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local CareerRules = require(Shared.Career.CareerRules)
local RankConfig = require(Shared.Career.RankConfig)
local RankRules = require(Shared.Career.RankRules)
local MatchConfig = require(Shared.Match.MatchConfig)
local PlayConfig = require(Shared.Match.PlayConfig)
local ServerList = require(Shared.Match.ServerList)
local Remotes = require(Shared.Net.Remotes)
local TrainingConfig = require(Shared.Training.TrainingConfig)

local BuyMenu = require(script.Parent.BuyMenu)
local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)
local SettingsMenu = require(script.Parent.SettingsMenu)
local Ui = require(script.Parent.Debug.Ui)

local PlayMenu = {}

PlayMenu.open = false
-- Opens or closes the menu (M, and TestAim's VFTestPlayMenu); it doesn't
-- close while you've yet to press PLAY. Set up by PlayMenu.start.
PlayMenu.setOpen = function(_open: boolean) end
-- Presses PLAY for a mode by its key, as the button does with that mode's
-- card picked (and TestAim's VFTestPlay). Set up by PlayMenu.start.
PlayMenu.play = function(_key: string) end

local CARD_W, CARD_H = 168, 214
local GAP = 12
local MARGIN = 24
local TOP = 84
local BUTTON_W, BUTTON_H = 260, 52

-- Seconds the menu waits to come up, on arriving from another server's
-- PLAY, for this server to put you in its match (ours).
local ARRIVAL_WAIT = 5
-- Seconds after which a press the server never answered is given up on:
-- a little longer than the server waits on a teleport (ours).
local LOST = PlayConfig.Rules.teleportWait.value + 5

local TILE = Color3.fromRGB(28, 30, 38)
local TILE_HOVER = Color3.fromRGB(48, 52, 64)
local GOLD = Color3.fromRGB(230, 200, 120)
local INK = Color3.fromRGB(20, 20, 24)

type Card = { key: string, button: TextButton, stroke: UIStroke, here: TextLabel, count: TextLabel, you: TextLabel }

local me = Players.LocalPlayer

-- The mode this server plays, by its key; nil on the course, with Basic
-- Training off.
local function current(): string?
	return PlayConfig.keyOf(
		Workspace:GetAttribute(ArenaConfig.ON),
		Workspace:GetAttribute(ArenaConfig.MODE),
		Workspace:GetAttribute(MatchConfig.FORMAT),
		Workspace:GetAttribute(TrainingConfig.ON)
	)
end

-- The mode your teleport here was for, if it was for one: the teleport
-- data the server that sent you set.
local function arrivedFor(): string?
	local ok, data = pcall(function()
		return TeleportService:GetLocalPlayerTeleportData()
	end)
	local key = if ok and typeof(data) == "table" then (data :: any)[PlayConfig.DATA_KEY] else nil
	return if typeof(key) == "string" and PlayConfig.ByKey[key] then key else nil
end

-- The mode of a match under way that holds a place for you (system 69).
local function heldFor(): string?
	local key = me:GetAttribute(PlayConfig.REJOIN)
	return if typeof(key) == "string" and PlayConfig.ByKey[key] then key else nil
end

function PlayMenu.start()
	local gui = Ui.screen("VFPlay", 20, Enum.ScreenInsets.None)
	gui.Enabled = false
	-- The match behind, dimmed.
	Ui.frame(gui, {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Active = true,
	})
	local count = #PlayConfig.Modes
	local width = 2 * MARGIN + count * CARD_W + (count - 1) * GAP
	local height = TOP + CARD_H + 24 + BUTTON_H + 48
	local root = Ui.frame(gui, {
		Name = "Play",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.15,
		Active = true,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = root
	Ui.label(root, {
		Text = "PLAY",
		Font = Enum.Font.GothamBold,
		TextSize = 30,
		Position = UDim2.fromOffset(MARGIN, 16),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 36),
	})
	local hint = Ui.label(root, {
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(MARGIN, 26),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 18),
	})
	local here = Ui.label(root, {
		TextSize = 13,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(MARGIN, 56),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 18),
	})

	local cards: { Card } = {}
	local selected = PlayConfig.DEFAULT
	local hovered: string? = nil
	for i, mode in PlayConfig.Modes do
		local side = math.floor(mode.players / 2)
		local button = Instance.new("TextButton")
		button.Name = mode.key
		button.AutoButtonColor = false
		button.Text = ""
		button.BorderSizePixel = 0
		button.BackgroundColor3 = TILE
		button.BackgroundTransparency = 0.1
		button.Position = UDim2.fromOffset(MARGIN + (i - 1) * (CARD_W + GAP), TOP)
		button.Size = UDim2.fromOffset(CARD_W, CARD_H)
		button.Parent = root
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Thickness = 3
		stroke.Color = GOLD
		stroke.Transparency = 1
		stroke.Parent = button
		-- A long name (TEAM DEATHMATCH) shrinks to fit.
		local name = Ui.label(button, {
			Text = string.upper(mode.name),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(8, 14),
			Size = UDim2.fromOffset(CARD_W - 16, 22),
		})
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = 18
		fit.Parent = name
		local tag = Ui.label(button, {
			Text = "THIS SERVER",
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = GOLD,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(8, 38),
			Size = UDim2.fromOffset(CARD_W - 16, 14),
		})
		Ui.label(button, {
			Text = if mode.freeForAll then "FFA" elseif mode.players == 1 then "SOLO" else string.format("%dv%d", side, side),
			Font = Enum.Font.GothamBold,
			TextSize = 30,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(8, 60),
			Size = UDim2.fromOffset(CARD_W - 16, 34),
		})
		Ui.label(button, {
			Text = mode.blurb,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Ui.DIM,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(12, 102),
			Size = UDim2.fromOffset(CARD_W - 24, 60),
		})
		-- Your record in the mode, or your rank, shrinking to fit.
		local you = Ui.label(button, {
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(8, CARD_H - 48),
			Size = UDim2.fromOffset(CARD_W - 16, 16),
		})
		local small = Instance.new("UITextSizeConstraint")
		small.MaxTextSize = 12
		small.Parent = you
		local players = Ui.label(button, {
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(8, CARD_H - 28),
			Size = UDim2.fromOffset(CARD_W - 16, 18),
		})
		button.MouseEnter:Connect(function()
			hovered = mode.key
		end)
		button.MouseLeave:Connect(function()
			if hovered == mode.key then
				hovered = nil
			end
		end)
		button.MouseButton1Click:Connect(function()
			selected = mode.key
		end)
		table.insert(cards, { key = mode.key, button = button, stroke = stroke, here = tag, count = players, you = you })
	end

	local playButton = Instance.new("TextButton")
	playButton.Name = "PlayButton"
	playButton.AutoButtonColor = false
	playButton.BorderSizePixel = 0
	playButton.BackgroundColor3 = GOLD
	playButton.Font = Enum.Font.GothamBold
	playButton.TextSize = 22
	playButton.TextColor3 = INK
	playButton.Position = UDim2.fromOffset((width - BUTTON_W) / 2, TOP + CARD_H + 24)
	playButton.Size = UDim2.fromOffset(BUTTON_W, BUTTON_H)
	playButton.Parent = root
	-- What came of the last press. Plain text: a failure is Roblox's words.
	local status = Ui.label(root, {
		RichText = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(MARGIN, TOP + CARD_H + 24 + BUTTON_H + 14),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 18),
	})

	-- A press the server hasn't answered yet, or a teleport under way, and
	-- what the status line says of it.
	local busy = false
	local busySince = 0
	local note, noteColour = "", Ui.TEXT
	-- Whether the server has put you in what's played here, by its answer
	-- (your PlayConfig.PLAYING says so too, but may arrive after it).
	local played = false
	local holdUntil = if arrivedFor() then os.clock() + ARRIVAL_WAIT else 0
	-- Your totals, as last read from your CareerRules.ATTRIBUTE.
	local careerText: any = nil
	local career: { [string]: CareerRules.Totals } = {}
	-- The held place's mode last seen, so it's picked once as it comes.
	local offered: string? = nil

	-- Whether you've yet to press PLAY on a server that has you pick first.
	local function mustPick(): boolean
		return Workspace:GetAttribute(PlayConfig.MENU) == true
			and not played
			and me:GetAttribute(PlayConfig.PLAYING) ~= true
			and os.clock() >= holdUntil
	end

	local function setOpen(open: boolean)
		if open == PlayMenu.open or (not open and mustPick()) then
			return
		end
		PlayMenu.open = open
		gui.Enabled = open
		hovered = nil
		if open then
			BuyMenu.setOpen(false)
			selected = heldFor() or current() or PlayConfig.DEFAULT
		elseif not SettingsMenu.open then
			CameraController.cursorFree = false
			InputSampler.blockMouse = false
		end
	end
	PlayMenu.setOpen = setOpen

	-- PLAY for the mode of a place held for you is RECONNECT (system 69).
	local function press(key: string)
		if busy or not PlayConfig.ByKey[key] then
			return
		end
		busy = true
		busySince = os.clock()
		note = ""
		Remotes.get().Play:FireServer(key, heldFor() == key)
	end
	PlayMenu.play = press
	playButton.MouseButton1Click:Connect(function()
		press(selected)
	end)

	-- Taken out of what's played here, while still here: pick again.
	local wasPlaying = me:GetAttribute(PlayConfig.PLAYING) == true
	me:GetAttributeChangedSignal(PlayConfig.PLAYING):Connect(function()
		local playing = me:GetAttribute(PlayConfig.PLAYING) == true
		if wasPlaying and not playing then
			played = false
		end
		wasPlaying = playing
	end)

	Remotes.get().Play.OnClientEvent:Connect(function(answer: any, detail: any)
		local mode = if typeof(detail) == "string" then PlayConfig.ByKey[detail] else nil
		if answer == "joined" or answer == "switched" then
			busy = false
			played = true
			note = ""
			setOpen(false)
		elseif answer == "teleporting" then
			note = string.format("TELEPORTING TO %s...", if mode then string.upper(mode.name) else "ANOTHER SERVER")
			noteColour = GOLD
		elseif answer == "failed" then
			busy = false
			note = if typeof(detail) == "string" and detail ~= "" then detail else "Couldn't get you there"
			noteColour = Ui.BAD
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			setOpen(not PlayMenu.open)
		end
	end)

	RunService.RenderStepped:Connect(function()
		if busy and os.clock() - busySince > LOST then
			busy = false
		end
		if mustPick() then
			setOpen(true)
		end
		if not PlayMenu.open then
			return
		end
		-- Every frame, as the vote does: the cursor stays the menu's while
		-- the settings menu opens and closes over it.
		CameraController.cursorFree = true
		InputSampler.blockMouse = true
		local viewport = Workspace.CurrentCamera.ViewportSize
		scale.Scale = math.min(1, (viewport.X - 40) / width, (viewport.Y - 40) / height)

		local playing = current()
		local mode = if playing then PlayConfig.ByKey[playing] else nil
		local where = if mode then string.format("This server plays %s.", string.upper(mode.name)) else "This server is on the course."
		here.Text = where
			.. if RunService:IsStudio()
				then "   In Studio, PLAY another mode and this server switches to it"
				else "   PLAY another mode and you go to a server playing it"
		hint.Text = if mustPick() then "" else "M  close"
		local held = heldFor()
		if held ~= offered then
			offered = held
			if held then
				selected = held
			end
		end
		local counts = ServerList.parseCounts(Workspace:GetAttribute(PlayConfig.COUNTS))
		local text = me:GetAttribute(CareerRules.ATTRIBUTE)
		if text ~= careerText then
			careerText = text
			career = CareerRules.fromText(text)
		end
		local tier = me:GetAttribute(RankConfig.TIER)
		for _, card in cards do
			local totals = career[card.key]
			if card.key == CareerRules.RANKED and typeof(tier) == "number" then
				card.you.Text = RankRules.line(tier, me:GetAttribute(RankConfig.RR) or 0, me:GetAttribute(RankConfig.GAMES) or 0)
				card.you.TextColor3 = if tier > 0 then GOLD else Ui.DIM
			else
				card.you.Text = if totals then CareerRules.summary(totals) else ""
				card.you.TextColor3 = Ui.DIM
			end
			local n = counts[card.key] or 0
			card.count.Text = if n > 0 then string.format("%d PLAYING", n) else "NOBODY YET"
			card.count.TextColor3 = if n > 0 then GOLD else Ui.DIM
			card.here.Visible = card.key == playing
			card.stroke.Transparency = if card.key == selected then 0 else 1
			card.button.BackgroundColor3 = if card.key == hovered or card.key == selected then TILE_HOVER else TILE
		end
		local picked = PlayConfig.ByKey[selected]
		local back = held ~= nil and held == selected
		playButton.Text = if busy then "..." elseif back then "RECONNECT" elseif picked then "PLAY " .. string.upper(picked.name) else "PLAY"
		playButton.BackgroundTransparency = if busy then 0.5 else 0
		local heldMode = if held then PlayConfig.ByKey[held] else nil
		if note == "" and heldMode and not busy then
			status.Text = if me:GetAttribute(MatchConfig.AFK_OUT) == true
				then "TAKEN OUT FOR BEING INACTIVE: RECONNECT TO GET BACK IN"
				else string.format("YOUR %s MATCH IS STILL ON: RECONNECT TO GET BACK IN", string.upper(heldMode.name))
			status.TextColor3 = GOLD
		else
			status.Text = note
			status.TextColor3 = noteColour
		end
	end)
end

return PlayMenu
