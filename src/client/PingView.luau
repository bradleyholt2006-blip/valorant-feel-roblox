--!strict
-- Pings on the client (system 52, Pings).
--   * Z tapped pings what the crosshair's on. Held past Pings.Params.hold,
--     it opens the wheel in the middle of the screen, and the mouse moves
--     its pick, not the view, towards Danger (up), Watching (right),
--     Pushing (down) or Need support (left): letting Z go pings the one
--     picked on the place the crosshair's on, and with none picked,
--     nothing. Right click puts it away with nothing pinged, as the
--     reference's map wheel does (Patch 0.50). Only the living ping with Z,
--     and not while the big map's up, which puts the wheel away as it
--     comes up (Patch 0.49 fixed 'the Z ping wheel could be opened
--     alongside the map ping wheel')
--   * with the big map up (Caps Lock held, MinimapView), the mouse moves a
--     cursor across it instead of the view, from the map's middle, held on
--     the map (Minimap.held), and left click pings the place under it,
--     dead or alive. Neither mouse button fires while it's up, nor while
--     the wheel is
--   * each ping asked for spends one of a few, as the server's count does
--     (Pings.spend): with none left nothing's asked, and the wheel's greyed
--     out
--   * the server's pings for your side: each but the map's in the world, a
--     diamond where it is with its word over it and how far away it is
--     under it, faded under the crosshair and as its time runs out
--     (Pings.transparency); each on the minimap and the big map
--     (MinimapView, PingView.shown); and each with its sound, the map's its
--     own (GameSounds.playPing). An enemy's is in the enemies' colour, the
--     spike's in the spike's, and the rest in yours or your side's
-- A gamepad's D-pad Up is Z, and its right stick moves the wheel's pick
-- and the map's cursor as the mouse does (system 68, Gamepad).
-- For scripted checks, PlayerGui's VFPings carries Shown (the markers on
-- screen, each as its word and how far away it is: "HERE 12m, ENEMY 30m"),
-- Left (the pings left, whole), Wheel ("" while it's shut, "open", or the
-- option picked) and Cursor (the map's cursor, metres, while it's up).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Minimap = require(Shared.Match.Minimap)
local Pings = require(Shared.Match.Pings)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local VisualConfig = require(Shared.Visuals.VisualConfig)

local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)
local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local Visuals = require(script.Parent.Visuals)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local PingView = {}

-- The big map's view, and the map's plan, while the big map's up to ping
-- on: MinimapView sets them each frame it draws it, but not while From the
-- Shadows' map is up (system 43). Nil without.
PingView.view = nil :: Minimap.View?
PingView.plan = nil :: Minimap.Plan?

local P = Pings.Params
local SPEED = 1 -- pixels the map's cursor and the wheel's pick move for each count of the mouse (ours)
local PICK_MOST = 64 -- pixels the wheel's pick goes from its middle at the most
local RING = 92 -- pixels from the wheel's middle to each option
local DIAMOND = 12 -- pixels across a marker's diamond

local YOURS = Color3.fromRGB(255, 236, 140) -- as your own arrow on the minimap
local SPIKE = Color3.fromRGB(255, 150, 40) -- as the spike on the minimap
local DARK = Color3.fromRGB(10, 10, 14)
local TEXT = Color3.fromRGB(235, 238, 244)
local PANEL = Color3.fromRGB(18, 20, 28)
local GREY = Color3.fromRGB(110, 114, 122)

-- A ping for your side as it came: its id, whose (their entity), when
-- (os.clock()), and its marker in the world, once it has one.
type Live = { id: number, ping: Pings.Ping, entity: number, at: number, marker: Frame? }

-- A ping as the maps show it (MinimapView): its icon's name, whether it's
-- the map's, where, its colour, how faded it is (0 solid, 1 gone), and its
-- tag for scripted checks (Pings.tag).
export type Shown = { name: string, map: boolean, position: vector, colour: Color3, fade: number, tag: string }

local live: { Live } = {}
local budget = Pings.newBudget(os.clock())
-- When Z went down (os.clock()), while it's held for a ping.
local zDown: number? = nil
local wheelOpen = false
local pickX, pickY = 0, 0
local cursorAt: vector? = nil
-- Whether InputSampler.blockMouse is set for the wheel or the map's cursor.
local taken = false

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

local function colourOf(l: Live): Color3
	local kind = l.ping.kind
	if kind == "enemy" then
		return color3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
	elseif kind == "spike" then
		return SPIKE
	end
	return if l.entity == PlayerController.entityId then YOURS else color3(VisualConfig.allyColour)
end

-- Asks the server for a ping, if there's one left to spend.
local function ask(payload: { [string]: any })
	if Pings.spend(budget, os.clock()) then
		NetSim.fireServer(Remotes.get().Ping, payload)
	end
end

-- Whether Z may ping now, or open the wheel: alive, with no menu up, no
-- big map, and the mouse nobody else's (From the Shadows' map).
local function zFree(): boolean
	local cursor = CameraController.mapCursor
	return PlayerController.alive and not CameraController.cursorFree and PingView.view == nil and cursor == nil
end

-- A ping along the crosshair, with the wheel's option if one was picked.
local function pingLook(option: string?)
	if not PlayerController.alive then
		return
	end
	ask({
		kind = "look",
		option = option,
		yaw = CameraController.yaw,
		pitch = CameraController.pitch,
		viewTime = RemoteEntities.shownTime(),
	})
end

-- A ping on the big map, where its cursor is.
local function pingMap()
	local at = cursorAt
	if at and PingView.view and not CameraController.cursorFree then
		ask({ kind = "map", point = Units.asVector3(at) })
	end
end

local function openWheel()
	wheelOpen = true
	pickX, pickY = 0, 0
end

local function shutWheel()
	wheelOpen = false
	pickX, pickY = 0, 0
end

-- The mouse moving the wheel's pick `delta` counts, no further out than
-- PICK_MOST.
local function moveWheel(delta: Vector2)
	local x, y = pickX + delta.X * SPEED, pickY + delta.Y * SPEED
	local far = math.sqrt(x * x + y * y)
	if far > PICK_MOST then
		x, y = x * PICK_MOST / far, y * PICK_MOST / far
	end
	pickX, pickY = x, y
end

-- The mouse moving the map's cursor `delta` counts across the map.
local function moveCursor(delta: Vector2)
	local view, at, plan = PingView.view, cursorAt, PingView.plan
	if not view or not at or not plan then
		return
	end
	local moved = Minimap.fromView(view, delta.X * SPEED, delta.Y * SPEED) - Minimap.fromView(view, 0, 0)
	cursorAt = Minimap.held(plan, at + moved)
end

-- The server's ping for your side.
local function onPing(event: any)
	if typeof(event) ~= "table" or typeof(event.id) ~= "number" or typeof(event.position) ~= "Vector3" then
		return
	end
	local kind = event.kind
	if not Pings.isKind(kind) then
		return
	end
	local ping: Pings.Ping = {
		kind = kind :: Pings.Kind,
		option = if Pings.isOption(event.option) then event.option else nil,
		position = Units.asVector(event.position),
		target = if typeof(event.target) == "number" then event.target else nil,
		weapon = if typeof(event.weapon) == "string" then event.weapon else nil,
	}
	local entity = if typeof(event.entity) == "number" then event.entity else 0
	table.insert(live, { id = event.id, ping = ping, entity = entity, at = os.clock() })
	GameSounds.playPing(kind == "map")
end

local function newMarker(parent: Instance): Frame
	local holder = Ui.frame(parent, { Name = "Ping", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0) })
	local diamond = Ui.frame(holder, {
		Name = "Diamond",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(DIAMOND, DIAMOND),
		Rotation = 45,
		BackgroundTransparency = 0,
	})
	local edge = Instance.new("UIStroke")
	edge.Color = DARK
	edge.Thickness = 1.5
	edge.Parent = diamond
	local parts = {
		{ name = "Word", anchor = 1, y = -DIAMOND, font = Enum.Font.GothamBold, size = 13 },
		{ name = "Far", anchor = 0, y = DIAMOND, font = Enum.Font.GothamMedium, size = 12 },
	}
	for _, part in parts do
		Ui.label(holder, {
			Name = part.name,
			AnchorPoint = Vector2.new(0.5, part.anchor),
			Position = UDim2.fromOffset(0, part.y),
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			Font = part.font,
			TextSize = part.size,
			TextColor3 = TEXT,
			TextStrokeColor3 = DARK,
			TextStrokeTransparency = 0.35,
			TextXAlignment = Enum.TextXAlignment.Center,
			RichText = false,
		})
	end
	return holder
end

-- A marker drawn `faded` see-through: its diamond in `colour`, its word in
-- it too, and how far away it is.
local function drawMarker(marker: Frame, colour: Color3, word: string, far: string, faded: number)
	local diamond = marker:FindFirstChild("Diamond") :: Frame?
	if diamond then
		diamond.BackgroundColor3 = colour
		diamond.BackgroundTransparency = faded
		local edge = diamond:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Transparency = faded
		end
	end
	local texts: { [string]: string } = { Word = word, Far = far }
	for name, text in texts do
		local label = marker:FindFirstChild(name) :: TextLabel?
		if label then
			label.Text = text
			label.TextColor3 = if name == "Word" then colour else TEXT
			label.TextTransparency = faded
			label.TextStrokeTransparency = 0.35 + 0.65 * faded
		end
	end
end

-- The wheel's options, by id, and its pick.
type Wheel = { gui: ScreenGui, options: { [string]: TextLabel }, pick: Frame }

local function newWheel(): Wheel
	local gui = Ui.screen("VFPingWheel", 17, Enum.ScreenInsets.None)
	gui.Enabled = false
	local middle = Ui.frame(gui, {
		Name = "Middle",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
	})
	local options: { [string]: TextLabel } = {}
	for i, option in Pings.OPTIONS do
		local turn = (i - 1) * 2 * math.pi / #Pings.OPTIONS
		local label = Ui.label(middle, {
			Name = option,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(math.floor(RING * math.sin(turn) + 0.5), math.floor(-RING * math.cos(turn) + 0.5)),
			Size = UDim2.fromOffset(118, 28),
			BackgroundColor3 = PANEL,
			BackgroundTransparency = 0.3,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Text = Pings.Words[option],
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			RichText = false,
		})
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = label
		options[option] = label
	end
	local pick = Ui.frame(middle, {
		Name = "Pick",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = TEXT,
		BackgroundTransparency = 0,
	})
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = pick
	return { gui = gui, options = options, pick = pick }
end

local function drawWheel(wheel: Wheel, any: boolean)
	wheel.gui.Enabled = wheelOpen
	if not wheelOpen then
		return
	end
	local picked = if any then Pings.pick(pickX, pickY) else nil
	for option, label in wheel.options do
		local lit = option == picked
		label.BackgroundColor3 = if lit then YOURS else PANEL
		label.TextColor3 = if not any then GREY elseif lit then DARK else TEXT
	end
	wheel.pick.Position = UDim2.fromOffset(pickX, pickY)
	wheel.pick.BackgroundColor3 = if any then TEXT else GREY
end

-- Each ping on the maps (MinimapView), the map's and the rest, in the order
-- they came.
function PingView.shown(): { Shown }
	local now = os.clock()
	local out: { Shown } = {}
	for _, l in live do
		local fade = Pings.transparency(now - l.at, math.huge)
		if fade < 1 then
			table.insert(out, {
				name = "Ping_" .. l.id,
				map = l.ping.kind == "map",
				position = l.ping.position,
				colour = colourOf(l),
				fade = fade,
				tag = Pings.tag(l.ping),
			})
		end
	end
	return out
end

-- Where the big map's cursor is (metres), while it's up to ping on.
function PingView.cursor(): vector?
	return cursorAt
end

-- Puts the big map's cursor nearest `point` (metres), as the mouse could
-- (TestAim's VFTestMapPoint). Returns whether the map was up to take it.
function PingView.setCursor(point: vector): boolean
	local plan = PingView.plan
	if not PingView.view or not plan then
		return false
	end
	cursorAt = Minimap.held(plan, point)
	return true
end

-- Pings as Z and the map do, for scripted checks (TestAim's VFTestPing):
-- "tap" as Z tapped, an option's id as Z let go with it picked, "wheel"
-- opening the wheel as Z held, "shut" putting it away as right click does,
-- and "map" as a left click on the big map.
function PingView.test(what: string)
	if what == "tap" then
		if zFree() then
			pingLook(nil)
		end
	elseif Pings.isOption(what) then
		if wheelOpen or zFree() then
			shutWheel()
			pingLook(what)
		end
	elseif what == "wheel" then
		if zFree() then
			openWheel()
		end
	elseif what == "shut" then
		shutWheel()
	elseif what == "map" then
		pingMap()
	end
end

-- Z pressed, or a gamepad's D-pad Up (system 68, Gamepad): a ping as it's
-- let go, or held long enough, the wheel.
function PingView.press()
	zDown = if zFree() then os.clock() else nil
end

-- Z let go: the option picked on the wheel pinged, if there's a ping left,
-- or a tap's ping along the crosshair.
function PingView.release()
	local down = zDown
	zDown = nil
	if wheelOpen then
		local picked = if Pings.left(budget, os.clock()) >= 1 then Pings.pick(pickX, pickY) else nil
		shutWheel()
		if picked then
			pingLook(picked)
		end
	elseif down and os.clock() - down < P.hold.value then
		pingLook(nil)
	end
end

function PingView.start()
	local gui = Ui.screen("VFPings", 13, Enum.ScreenInsets.None)
	local wheel = newWheel()
	NetSim.on(Remotes.get().Ping, onPing)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Z then
			PingView.press()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 and wheelOpen then
			-- Put away with nothing pinged.
			shutWheel()
			zDown = nil
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and CameraController.mapCursor == moveCursor then
			pingMap()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Z then
			PingView.release()
		end
	end)

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local alive = PlayerController.alive

		-- The wheel: open once Z's been held long enough; shut with nothing
		-- pinged as you die, or as the big map, a menu or another's cursor
		-- takes the mouse (one wheel at a time: Patch 0.49).
		local down = zDown
		local mouse = CameraController.mapCursor
		if not wheelOpen and down and now - down >= P.hold.value and zFree() then
			openWheel()
		elseif
			wheelOpen and (not alive or CameraController.cursorFree or PingView.view ~= nil or (mouse ~= nil and mouse ~= moveWheel))
		then
			shutWheel()
			zDown = nil
		end
		-- The map's cursor: from the map's middle as it comes up.
		local plan = PingView.plan
		local mapUp = PingView.view ~= nil and plan ~= nil
		if mapUp and plan and not cursorAt then
			cursorAt = Minimap.middle(plan)
		elseif not mapUp then
			cursorAt = nil
		end
		-- The mouse is the wheel's or the cursor's while either is up, but
		-- never taken from another's (From the Shadows' map).
		local want = if wheelOpen then moveWheel elseif mapUp then moveCursor else nil
		local current = CameraController.mapCursor
		local ours = current == moveWheel or current == moveCursor
		if want and (current == nil or ours) then
			CameraController.mapCursor = want
		elseif not want and ours then
			CameraController.mapCursor = nil
		end
		local block = CameraController.mapCursor == moveWheel or CameraController.mapCursor == moveCursor
		if block and not taken and not CameraController.cursorFree then
			InputSampler.blockMouse = true
			taken = true
		elseif not block and taken then
			if not CameraController.cursorFree then
				InputSampler.blockMouse = false
			end
			taken = false
		end
		local any = Pings.left(budget, now) >= 1
		drawWheel(wheel, any)

		-- The markers in the world, where they are on screen.
		local camera = Workspace.CurrentCamera
		local shown = {}
		local i = 1
		while i <= #live do
			local l = live[i]
			local age = now - l.at
			if age >= P.duration.value then
				local marker = l.marker
				if marker then
					marker:Destroy()
				end
				table.remove(live, i)
				continue
			end
			i += 1
			if l.ping.kind == "map" or not camera then
				continue
			end
			local marker = l.marker or newMarker(gui)
			l.marker = marker
			local at, inFront = camera:WorldToViewportPoint(Units.toStuds(l.ping.position))
			marker.Visible = inFront and at.Z > 0
			if not marker.Visible then
				continue
			end
			marker.Position = UDim2.fromOffset(at.X, at.Y)
			local off = (Vector2.new(at.X, at.Y) - camera.ViewportSize / 2).Magnitude
			local metres = math.floor(vector.magnitude(Units.toMetres(camera.CFrame.Position) - l.ping.position) + 0.5)
			local word = Pings.word(l.ping)
			drawMarker(marker, colourOf(l), word, tostring(metres) .. "m", Pings.transparency(age, off))
			table.insert(shown, string.format("%s %dm", word, metres))
		end

		gui:SetAttribute("Shown", table.concat(shown, ", "))
		gui:SetAttribute("Left", math.floor(Pings.left(budget, now) + 1e-9))
		local picked = if wheelOpen and any then Pings.pick(pickX, pickY) else nil
		gui:SetAttribute("Wheel", if not wheelOpen then "" elseif picked then picked else "open")
		local at = PingView.cursor()
		gui:SetAttribute("Cursor", if at then Units.asVector3(at) else nil)
	end)
end

return PingView
