--!strict
-- The vote for the next map (system 22): after a match's victory screen, a
-- card for each map to pick from, with its plan seen from above (side 1 at
-- the top, lighter for taller cover; a spike map's as its attackers face it,
-- system 25) and the votes it has so far. Click a
-- card to vote for it, or another to change your vote; yours is outlined,
-- and the most voted for has its count in gold. Everyone in the match
-- votes, waiting in line or not, but not anyone in the Play menu yet to
-- press PLAY (system 24), and the Play menu, open, hides the vote. While
-- it's up the mouse moves a cursor and its buttons are the cards', and you
-- can still move.
--
-- Everything comes from the arena model's attributes (Arena): Phase "vote",
-- VoteMaps ("A,B,C", keys of ArenaLayout.Maps, or in the spike rounds and
-- deathmatch of SpikeMaps.Maps), Votes ("2,0,1"), Map (the one just
-- played), Mode and PhaseEndsAt, and your own vote, ArenaConfig.VOTE.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local ArenaLayout = require(Shared.Arena.ArenaLayout)
local MapPlan = require(Shared.Match.MapPlan)
local SpikeMaps = require(Shared.Match.SpikeMaps)
local Remotes = require(Shared.Net.Remotes)

local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)
local PlayMenu = require(script.Parent.PlayMenu)
local SettingsMenu = require(script.Parent.SettingsMenu)
local Ui = require(script.Parent.Debug.Ui)

local VoteScreen = {}

-- Votes for a map by its number on the screen, as a click on its card does
-- (and TestAim's VFTestVote).
function VoteScreen.vote(option: number)
	Remotes.get().Vote:FireServer(option)
end

local CARD_W, CARD_H = 180, 316
local GAP = 16
local MARGIN = 24
local TOP = 64
local PLAN_W = 120 -- the hall's width on a card, in pixels
-- The most room a spike map's plan takes on a card, in pixels.
local SPIKE_PLAN_W, SPIKE_PLAN_H = 156, 212

local TILE = Color3.fromRGB(28, 30, 38)
local TILE_HOVER = Color3.fromRGB(48, 52, 64)
local GOLD = Color3.fromRGB(230, 200, 120)
local FLOOR = Color3.fromRGB(58, 61, 70)
-- Cover by its height, lighter for taller, as a minimap shows it.
local COVER = {
	low = Color3.fromRGB(140, 143, 152),
	high = Color3.fromRGB(190, 192, 200),
	centre = Color3.fromRGB(230, 230, 236),
}
-- A spike map's sites and each spawn's floor, as the map has them.
local SITE = Color3.fromRGB(150, 128, 72)
local SPAWN = {
	AttackerSpawn = Color3.fromRGB(140, 88, 80),
	DefenderSpawn = Color3.fromRGB(72, 112, 135),
}

type Card = { key: string, button: TextButton, stroke: UIStroke, votes: TextLabel, played: TextLabel }

-- A rectangle on the plan, from metres on the floor (x across, z down the
-- length, from the hall's centre), turned clockwise by `degrees`.
local function rect(plan: Frame, scale: number, x: number, z: number, w: number, d: number, degrees: number, colour: Color3)
	Ui.frame(plan, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, x * scale, 0.5, z * scale),
		Size = UDim2.fromOffset(math.max(w * scale, 1), math.max(d * scale, 1)),
		Rotation = degrees,
		BackgroundColor3 = colour,
		BackgroundTransparency = 0,
	})
end

-- A map's plan, seen from above with side 1 at the top: the hall, its two
-- spawn rooms, and its cover.
local function drawPlan(parent: Instance, key: string, y: number)
	local w, l, rw, rd = ArenaLayout.size()
	local scale = PLAN_W / w
	local plan = Ui.frame(parent, {
		Name = "Plan",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset((CARD_W - PLAN_W) / 2, y),
		Size = UDim2.fromOffset(PLAN_W, (l + 2 * rd) * scale),
	})
	rect(plan, scale, 0, 0, w, l, 0, FLOOR)
	for _, z in { -(l + rd) / 2, (l + rd) / 2 } do
		rect(plan, scale, 0, z, rw, rd, 0, FLOOR)
	end
	local H = ArenaLayout.Heights
	for _, part in ArenaLayout.coverParts(key) do
		local tall = part.size.y
		local colour = if tall < H.high.value then COVER.low elseif tall < H.centre.value then COVER.high else COVER.centre
		rect(plan, scale, part.center.x, part.center.z, part.size.x, part.size.z, -math.deg(part.yaw), colour)
	end
end

-- A spike map's plan (system 25), seen from above as its attackers face it:
-- their spawn at the bottom, the defenders' at the top and A on the left.
-- The floor, each spawn's in its colour, each site's plant area, and the
-- cover.
local function drawSpikePlan(parent: Instance, map: MapPlan.Map, y: number)
	local x0, z0, x1, z1 = map.bounds()
	local w, d = x1 - x0, z1 - z0
	local scale = math.min(SPIKE_PLAN_W / w, SPIKE_PLAN_H / d)
	local plan = Ui.frame(parent, {
		Name = "Plan",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset((CARD_W - w * scale) / 2, y),
		Size = UDim2.fromOffset(w * scale, d * scale),
	})
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local function box(x: number, z: number, sx: number, sz: number, colour: Color3)
		rect(plan, scale, x - cx, z - cz, sx, sz, 0, colour)
	end
	local rooms = map.rooms()
	for _, room in rooms do
		box((room.x0 + room.x1) / 2, (room.z0 + room.z1) / 2, room.x1 - room.x0, room.z1 - room.z0, FLOOR)
	end
	for _, room in rooms do
		local colour = SPAWN[room.name]
		if colour then
			box((room.x0 + room.x1) / 2, (room.z0 + room.z1) / 2, room.x1 - room.x0, room.z1 - room.z0, colour)
		end
	end
	for _, site in map.Sites do
		box(site.x, site.z, site.sx, site.sz, SITE)
	end
	for _, c in map.cover() do
		box(c.x, c.z, c.sx, c.sz, if c.height == "low" then COVER.low else COVER.high)
	end
end

local function split(text: any): { string }
	local out = {}
	if typeof(text) == "string" then
		for item in string.gmatch(text, "[^,]+") do
			table.insert(out, item)
		end
	end
	return out
end

function VoteScreen.start()
	local gui = Ui.screen("VFVote", 19)
	gui.Enabled = false
	local width = 2 * MARGIN + 3 * CARD_W + 2 * GAP
	local height = TOP + CARD_H + 48
	local root = Ui.frame(gui, {
		Name = "Vote",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.15,
		Active = true,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = root
	Ui.label(root, {
		Text = "VOTE FOR THE NEXT MAP",
		Font = Enum.Font.GothamBold,
		TextSize = 26,
		Position = UDim2.fromOffset(MARGIN, 18),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 32),
	})
	local timer = Ui.label(root, {
		Font = Enum.Font.GothamBold,
		TextSize = 26,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(MARGIN, 18),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 32),
	})
	Ui.label(root, {
		Text = "Click a map to vote for it.   The most votes wins; a tie is settled at random",
		TextSize = 13,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(MARGIN, height - 34),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 18),
	})

	local cards: { Card } = {}
	local built = "" -- the VoteMaps the cards are for, and whether they're the spike rounds'
	local hovered: number? = nil

	-- The cards for `keys`: the spike rounds' maps if `spike`, else the
	-- arena's.
	local function build(keys: { string }, spike: boolean)
		for _, card in cards do
			card.button:Destroy()
		end
		table.clear(cards)
		hovered = nil
		local x0 = (width - #keys * CARD_W - (#keys - 1) * GAP) / 2
		for i, key in keys do
			local map = if spike then nil else ArenaLayout.Maps[key]
			local spikeMap = if spike then SpikeMaps.Maps[key] else nil
			local button = Instance.new("TextButton")
			button.Name = key
			button.AutoButtonColor = false
			button.Text = ""
			button.BorderSizePixel = 0
			button.BackgroundColor3 = TILE
			button.BackgroundTransparency = 0.1
			button.Position = UDim2.fromOffset(x0 + (i - 1) * (CARD_W + GAP), TOP)
			button.Size = UDim2.fromOffset(CARD_W, CARD_H)
			button.Parent = root
			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Thickness = 3
			stroke.Color = GOLD
			stroke.Transparency = 1
			stroke.Parent = button
			Ui.label(button, {
				Text = string.upper(if map then map.name elseif spikeMap then spikeMap.NAME else key),
				Font = Enum.Font.GothamBold,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(8, 12),
				Size = UDim2.fromOffset(CARD_W - 16, 22),
			})
			local played = Ui.label(button, {
				Text = "JUST PLAYED",
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextColor3 = Ui.DIM,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(8, 36),
				Size = UDim2.fromOffset(CARD_W - 16, 14),
			})
			if map then
				drawPlan(button, key, 56)
			elseif spikeMap then
				drawSpikePlan(button, spikeMap, 60)
			end
			local votes = Ui.label(button, {
				Font = Enum.Font.GothamBold,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(8, CARD_H - 32),
				Size = UDim2.fromOffset(CARD_W - 16, 20),
			})
			button.MouseEnter:Connect(function()
				hovered = i
			end)
			button.MouseLeave:Connect(function()
				if hovered == i then
					hovered = nil
				end
			end)
			button.MouseButton1Click:Connect(function()
				VoteScreen.vote(i)
			end)
			table.insert(cards, { key = key, button = button, stroke = stroke, votes = votes, played = played })
		end
	end

	-- Whether this screen has the cursor, to give it back as the vote ends
	-- (unless the settings menu, open over it, still wants it).
	local holding = false
	local function hold(want: boolean)
		if want then
			holding = true
			CameraController.cursorFree = true
			InputSampler.blockMouse = true
		elseif holding then
			holding = false
			if not SettingsMenu.open then
				CameraController.cursorFree = false
				InputSampler.blockMouse = false
			end
		end
	end

	local me = Players.LocalPlayer
	RunService.RenderStepped:Connect(function()
		local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
		local keys = split(arena and arena:GetAttribute("VoteMaps"))
		local inMatch = typeof(me:GetAttribute(ArenaConfig.SIDE)) == "number"
			or typeof(me:GetAttribute(ArenaConfig.LINE)) == "number"
		local shown = Workspace:GetAttribute(ArenaConfig.ON) == true
			and arena ~= nil
			and arena:GetAttribute("Phase") == "vote"
			and #keys > 0
			and inMatch
			and not PlayMenu.open
		gui.Enabled = shown
		hold(shown)
		if not shown or not arena then
			return
		end
		local viewport = Workspace.CurrentCamera.ViewportSize
		scale.Scale = math.min(1, (viewport.X - 40) / width, (viewport.Y - 40) / height)
		-- Deathmatch is played on the spike rounds' maps (system 26).
		local mode = arena:GetAttribute("Mode")
		local spike = mode == "spike" or mode == "deathmatch"
		local text = (if spike then "spike:" else "") .. table.concat(keys, ",")
		if text ~= built then
			built = text
			build(keys, spike)
		end
		local endsAt = arena:GetAttribute("PhaseEndsAt")
		local left = if typeof(endsAt) == "number" then math.max(endsAt - Workspace:GetServerTimeNow(), 0) else 0
		timer.Text = tostring(math.ceil(left))

		local counts = split(arena:GetAttribute("Votes"))
		local most = 0
		for i = 1, #cards do
			most = math.max(most, tonumber(counts[i]) or 0)
		end
		local mine = me:GetAttribute(ArenaConfig.VOTE)
		local justPlayed = arena:GetAttribute("Map")
		for i, card in cards do
			local n = tonumber(counts[i]) or 0
			card.votes.Text = if n == 1 then "1 VOTE" elseif n > 0 then string.format("%d VOTES", n) else "NO VOTES"
			card.votes.TextColor3 = if n > 0 and n == most then GOLD else Ui.DIM
			card.stroke.Transparency = if mine == i then 0 else 1
			card.button.BackgroundColor3 = if hovered == i then TILE_HOVER else TILE
			card.played.Visible = card.key == justPlayed
		end
	end)
end

return VoteScreen
