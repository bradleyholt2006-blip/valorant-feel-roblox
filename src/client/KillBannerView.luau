--!strict
-- The kill banner on the client (system 55, KillBanner): each kill of yours
-- the server counts (the Banner remote, to you alone) brings up a banner low
-- in the middle of the screen, above the ability bar, with the kill sound
-- (GameSounds.playKill), higher with each kill:
--   * a diamond with the kill's number in it: which kill of the round it is,
--     or of the life out of the rounds; gold from the ace's on
--   * under it a mark lit for each kill so far, up to the ace's, and all of
--     them past it
--   * a little red X off the diamond's corner for a headshot
--   * under the marks, the name of whoever was killed, in the enemy colour
-- It comes up a little bigger and settles, shows whole, then fades
-- (KillBanner.scale and alpha), and the next kill's takes its place, the
-- same size. The reference's banners are Riot's art (a skull or an X, and a
-- skin's own); ours is drawn from plain frames.
-- For scripted checks, PlayerGui's VFKillBanner carries Count (the latest
-- banner's number, 0 before one), Marks (the marks it lit), Headshot,
-- Victim (whose kill it was), Pitch (its kill sound's playback speed) and
-- Shown (whether a banner's up).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KillBanner = require(Shared.Combat.KillBanner)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local VisualConfig = require(Shared.Visuals.VisualConfig)

local NetSim = require(script.Parent.NetSim)
local Visuals = require(script.Parent.Visuals)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)
local Who = require(script.Parent.Who)

local KillBannerView = {}

local GOLD = Color3.fromRGB(230, 200, 120)
local RED = Color3.fromRGB(255, 60, 60)
local SIZE = 40 -- pixels a side of the diamond, before it's turned (ours)
local CENTRE = 28 -- pixels down the banner to the diamond's middle
local MARK_W, MARK_GAP = 12, 4 -- pixels (ours)
local SOLID = 0.75 -- how solid the diamond's fill is at its strongest
local UNLIT = 0.3 -- how solid a mark not lit is at its strongest

-- Whoever was killed: a dummy, a player or a bot (system 60).
local function nameOf(id: number): string
	if PlayerCodec.isDummy(id) then
		return string.format("Dummy %d", id - PlayerCodec.DUMMY_BASE)
	end
	return Who.name(id) or "?"
end

local function enemyColour(): Color3
	local c = VisualConfig.EnemyColours[Visuals.enemyColour].colour
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

function KillBannerView.start()
	local gui = Ui.screen("VFKillBanner", 15, Enum.ScreenInsets.None)
	gui:SetAttribute("Count", 0)
	gui:SetAttribute("Shown", false)
	local holder = Ui.frame(gui, {
		Size = UDim2.fromOffset(240, 92),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, -240),
		BackgroundTransparency = 1,
		Visible = false,
	})
	local grow = Instance.new("UIScale")
	grow.Parent = holder

	local diamond = Ui.frame(holder, {
		Size = UDim2.fromOffset(SIZE, SIZE),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, CENTRE),
		Rotation = 45,
	})
	local edge = Instance.new("UIStroke")
	edge.Thickness = 2
	edge.Parent = diamond
	local number = Ui.label(holder, {
		Size = UDim2.fromOffset(SIZE, SIZE),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, CENTRE),
		TextSize = 22,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	-- The headshot's little red X, off the diamond's top right edge.
	local cross: { Frame } = {}
	for i = 1, 2 do
		table.insert(
			cross,
			Ui.frame(holder, {
				Size = UDim2.fromOffset(16, 4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 26, 0, CENTRE - 22),
				Rotation = if i == 1 then 45 else -45,
				BackgroundColor3 = RED,
			})
		)
	end
	local most = KillBanner.Params.marks.value
	local marks: { Frame } = {}
	for i = 1, most do
		table.insert(
			marks,
			Ui.frame(holder, {
				Size = UDim2.fromOffset(MARK_W, 4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, (i - (most + 1) / 2) * (MARK_W + MARK_GAP), 0, 64),
			})
		)
	end
	local plate = Ui.label(holder, {
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 72),
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	local at = -math.huge -- when the banner up came, on os.clock()
	local count = 0
	local head = false

	NetSim.on(Remotes.get().Banner, function(event: any)
		if typeof(event) ~= "table" or typeof(event.count) ~= "number" or typeof(event.target) ~= "number" then
			return
		end
		at = os.clock()
		count = event.count
		head = event.head == true
		local lit = KillBanner.marks(count)
		local colour = if KillBanner.top(count) then GOLD else Ui.TEXT
		number.Text = tostring(count)
		number.TextColor3 = colour
		edge.Color = colour
		for i, mark in marks do
			mark.BackgroundColor3 = if i <= lit then colour else Ui.PANEL
		end
		plate.Text = nameOf(event.target)
		plate.TextColor3 = enemyColour()
		local pitch = GameSounds.playKill(count)
		gui:SetAttribute("Count", count)
		gui:SetAttribute("Marks", lit)
		gui:SetAttribute("Headshot", head)
		gui:SetAttribute("Victim", plate.Text)
		gui:SetAttribute("Pitch", pitch)
	end)

	local shown = false
	RunService.RenderStepped:Connect(function()
		local age = os.clock() - at
		local a = KillBanner.alpha(age)
		holder.Visible = a > 0
		if a > 0 then
			local clear = 1 - a
			grow.Scale = KillBanner.scale(age)
			diamond.BackgroundTransparency = 1 - SOLID * a
			edge.Transparency = clear
			number.TextTransparency = clear
			for _, bar in cross do
				bar.BackgroundTransparency = if head then clear else 1
			end
			local lit = KillBanner.marks(count)
			for i, mark in marks do
				mark.BackgroundTransparency = if i <= lit then clear else 1 - UNLIT * a
			end
			plate.TextTransparency = clear
			plate.TextStrokeTransparency = 1 - 0.5 * a
		end
		if shown ~= (a > 0) then
			shown = a > 0
			gui:SetAttribute("Shown", shown)
		end
	end)
end

return KillBannerView
