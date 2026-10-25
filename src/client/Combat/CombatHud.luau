--!strict
-- Player-facing combat HUD (original layout): health and shields, ammo and
-- weapon, a reload / equip bar, server-confirmed hit markers and damage
-- numbers, a kill feed, the death notice and a scope overlay.
--
-- Hit markers and damage numbers only ever come from the server's verdict,
-- never from the client's guess, so they show what actually counted.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerController = require(script.Parent.Parent.PlayerController)
local RemoteEntities = require(script.Parent.Parent.RemoteEntities)
local ClientShots = require(script.Parent.ClientShots)
local NetSim = require(script.Parent.Parent.NetSim)
local Ui = require(script.Parent.Parent.Debug.Ui)

local DT = 1 / MovementConfig.TickRate.value
local HEAD_COLOR = Color3.fromRGB(255, 210, 90)
local KILL_COLOR = Color3.fromRGB(255, 80, 80)
local FEED_ROWS = 5
local FEED_TIME = 6

local CombatHud = {}

-- Show floating damage numbers at hit points (the reference only shows them
-- in its practice range; they are on here because this is a test bench).
CombatHud.damageNumbers = true

local function nameOf(id: number): string
	if PlayerCodec.isDummy(id) then
		return string.format("Dummy %d", id - PlayerCodec.DUMMY_BASE)
	end
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == id then
			return player.DisplayName
		end
	end
	return "?"
end

local function damageNumber(point: vector, amount: number, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.1
	anchor.CFrame = CFrame.new(Units.toStuds(point))
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(60, 24)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Text = tostring(math.floor(amount + 0.5))
	label.Parent = gui
	gui.Parent = anchor
	anchor.Parent = Workspace
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = (os.clock() - start) / 0.8
		if t >= 1 then
			conn:Disconnect()
			anchor:Destroy()
			return
		end
		gui.StudsOffset = Vector3.new(0, t * 1.5, 0)
		label.TextTransparency = t * t
		label.TextStrokeTransparency = 0.3 + 0.7 * t
	end)
end

function CombatHud.start()
	-- The hit marker, reload bar and scope sit on the camera's centre; the kill
	-- feed keeps clear of the top bar.
	local gui = Ui.screen("VFCombatHud", 15, Enum.ScreenInsets.None)
	local feedGui = Ui.screen("VFKillFeed", 15)

	-- Health / shield (left of centre) and ammo (right of centre) ------------
	local vitals = Ui.frame(gui, {
		Size = UDim2.fromOffset(170, 54),
		Position = UDim2.new(0.5, -300, 1, -70),
	})
	local healthText = Ui.label(vitals, {
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		TextSize = 32,
		Font = Enum.Font.GothamBold,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local shieldText = Ui.label(vitals, {
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.fromOffset(84, 0),
		TextSize = 18,
		TextColor3 = Ui.NEUTRAL,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	local ammoBox = Ui.frame(gui, {
		Size = UDim2.fromOffset(190, 54),
		Position = UDim2.new(0.5, 110, 1, -70),
	})
	local ammoText = Ui.label(ammoBox, {
		Size = UDim2.new(1, -20, 0, 34),
		Position = UDim2.fromOffset(10, 2),
		TextSize = 28,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local weaponText = Ui.label(ammoBox, {
		Size = UDim2.new(1, -20, 0, 16),
		Position = UDim2.fromOffset(10, 34),
		TextSize = 13,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- Reload / equip progress under the crosshair -----------------------------
	local barBack = Ui.frame(gui, {
		Size = UDim2.fromOffset(120, 4),
		Position = UDim2.new(0.5, -60, 0.5, 46),
		Visible = false,
	})
	local barFill = Ui.frame(barBack, {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Ui.TEXT,
		BackgroundTransparency = 0,
	})
	local barLabel = Ui.label(barBack, {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(0, 6),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- Hit marker: four short diagonal ticks around the crosshair --------------
	local marker = Ui.frame(gui, {
		Size = UDim2.fromOffset(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	})
	local ticks: { Frame } = {}
	for i = 0, 3 do
		local angle = math.rad(45 + 90 * i)
		local tick = Ui.frame(marker, {
			Size = UDim2.fromOffset(10, 2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(math.cos(angle) * 12, math.sin(angle) * 12),
			Rotation = 45 + 90 * i,
			BackgroundColor3 = Ui.TEXT,
			BackgroundTransparency = 1,
		})
		table.insert(ticks, tick)
	end
	local markerStart = -math.huge
	local markerColor = Ui.TEXT

	-- Kill feed ---------------------------------------------------------------
	local feed = Ui.label(feedGui, {
		Size = UDim2.fromOffset(320, FEED_ROWS * 18),
		Position = UDim2.new(1, -332, 0, 12),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextStrokeTransparency = 0.5,
	})
	local feedRows: { { text: string, at: number } } = {}

	-- Death notice --------------------------------------------------------------
	local dead = Ui.label(gui, {
		Size = UDim2.fromOffset(400, 40),
		Position = UDim2.new(0.5, -200, 0.35, 0),
		TextSize = 24,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = KILL_COLOR,
		Text = "ELIMINATED - respawning",
		Visible = false,
	})

	-- Scope overlay: black sides around a square view and thin lines ---------
	local scope = Instance.new("Frame")
	scope.Size = UDim2.fromScale(1, 1)
	scope.BackgroundTransparency = 1
	scope.Visible = false
	scope.Parent = gui
	local function black(props: { [string]: any }): Frame
		props.BackgroundColor3 = Color3.new(0, 0, 0)
		props.BackgroundTransparency = 0
		return Ui.frame(scope, props)
	end
	local leftSide = black({ Size = UDim2.fromScale(0, 1), Position = UDim2.fromScale(0, 0) })
	local rightSide = black({ Size = UDim2.fromScale(0, 1), Position = UDim2.fromScale(1, 0), AnchorPoint = Vector2.new(1, 0) })
	black({ Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, 0.5) })
	black({ Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromScale(0.5, 0) })

	-- Events ------------------------------------------------------------------
	-- One marker and number per round and target: a shotgun's pellets add up.
	table.insert(ClientShots.volleyListeners, function(volley: ClientShots.Volley)
		for _, hit in volley.hits do
			markerStart = os.clock()
			markerColor = if hit.killed then KILL_COLOR elseif hit.region == "head" then HEAD_COLOR else Ui.TEXT
			if CombatHud.damageNumbers then
				damageNumber(hit.point, hit.damage, markerColor)
			end
		end
	end)

	NetSim.on(Remotes.get().Combat, function(event: any)
		if typeof(event) ~= "table" or event.kind ~= "damage" or not event.killed then
			return
		end
		local text = string.format("%s  >  %s%s", nameOf(event.attacker), nameOf(event.target), if event.region == "head" then "  (head)" else "")
		table.insert(feedRows, { text = text, at = os.clock() })
		if #feedRows > FEED_ROWS then
			table.remove(feedRows, 1)
		end
	end)

	-- Per frame ---------------------------------------------------------------
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local sim = PlayerController.sim
		local alive = PlayerController.alive

		local hp = RemoteEntities.healthOf(PlayerController.entityId)
		-- Whole points, rounded up: a player on 0.4 is still alive.
		healthText.Text = tostring(math.ceil(hp.health - 1e-9))
		shieldText.Text = if hp.shield > 0 then string.format("+%d", math.ceil(hp.shield - 1e-9)) else ""
		dead.Visible = not alive and sim ~= nil

		local zoom = 1
		if sim then
			local w = sim.weapons
			local def = PlayerSim.def(sim)
			local slot = w.equipped
			ammoText.Text = if def.fireMode == "none" then "" else string.format("%d <font size=\"18\" color=\"#%s\">/ %d</font>", w.ammo[slot], Ui.hex(Ui.DIM), w.reserve[slot])
			weaponText.Text = string.format("%s   [%d]", def.name, slot)
			if w.scoped > 0 and def.ads then
				zoom = def.ads.zoom[w.scoped]
			end

			local t = sim.movement.tick * DT
			local fill, label = nil, ""
			if w.reloadEndTime > 0 then
				-- This step of the reload: the whole of it, or one round.
				local step = WeaponSim.reloadStep(def, w.ammo[slot], w.reserve[slot])
				fill = 1 - math.clamp((w.reloadEndTime - t) / math.max(step, 1e-3), 0, 1)
				label = "reloading"
			elseif t < w.equipEndTime then
				fill = 1 - math.clamp((w.equipEndTime - t) / math.max(def.equipTime.value, 1e-3), 0, 1)
				label = "drawing"
			end
			barBack.Visible = fill ~= nil and alive
			if fill then
				barFill.Size = UDim2.fromScale(fill, 1)
				barLabel.Text = label
			end
		end

		-- Scope: square view in the middle of the screen.
		local scoped = zoom >= 2 and alive
		scope.Visible = scoped
		if scoped then
			local viewport = Workspace.CurrentCamera.ViewportSize
			local side = math.max((viewport.X - viewport.Y) / 2, 0)
			leftSide.Size = UDim2.new(0, side, 1, 0)
			rightSide.Size = UDim2.new(0, side, 1, 0)
		end

		-- Hit marker fades over 0.18 s.
		local mt = (now - markerStart) / 0.18
		for _, tick in ticks do
			tick.BackgroundTransparency = if mt < 1 then mt else 1
			tick.BackgroundColor3 = markerColor
		end

		local lines = {}
		for _, row in feedRows do
			if now - row.at < FEED_TIME then
				table.insert(lines, row.text)
			end
		end
		feed.Text = table.concat(lines, "\n")
	end)
end

return CombatHud
