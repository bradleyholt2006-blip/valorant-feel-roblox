--!strict
-- The buy menu (system 9), on B: every gun in its group and the three
-- shields, each with its price, what you have marked, and the numbers of the
-- one under the cursor beside them. Click to buy, which puts a gun in your
-- hands; right-click something bought this buy phase to sell it back.
--
-- It opens whenever buying is open: in the arena during the buy phase and
-- while waiting for an opponent, and on the course at any time, as in the
-- reference's practice range. The server checks again (ShopServer). While
-- it's open the mouse moves a cursor and its buttons are the menu's, and you
-- can still move. In the spike rounds it costs credits (system 14): yours
-- show at the top, with what the round pays, and anything you can't afford
-- is dimmed. Elsewhere everything's free, and prices show what the
-- reference charges.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local MatchConfig = require(Shared.Match.MatchConfig)
local MatchRules = require(Shared.Match.MatchRules)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Shop = require(Shared.Weapons.Shop)
local Remotes = require(Shared.Net.Remotes)
local MovementConfig = require(Shared.Movement.MovementConfig)

local PlayerController = require(script.Parent.PlayerController)
local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)
local WeaponLooks = require(script.Parent.Combat.WeaponLooks)
local Ui = require(script.Parent.Debug.Ui)

local BuyMenu = {}

BuyMenu.open = false
-- Opens or closes the menu (B, and TestAim's VFTestMenu); it only opens while
-- buying is open. Set up by BuyMenu.start.
BuyMenu.setOpen = function(_open: boolean) end

local TILE_W, TILE_H = 160, 70
local GAP = 8
local COLUMN_W = TILE_W + 14
local HEADER_H = 22
local GROUP_GAP = 14
local PANEL_W = 290
local MARGIN = 20
local TOP = 64

local TILE = Color3.fromRGB(28, 30, 38)
local TILE_HOVER = Color3.fromRGB(48, 52, 64)
local OWNED = Color3.fromRGB(235, 235, 235)
local SELLABLE = Color3.fromRGB(90, 220, 200)
local GOLD = Color3.fromRGB(230, 200, 120)
local SHORT = Color3.fromRGB(235, 90, 80) -- what you can't afford

local CATEGORY: { [string]: string } = {
	sidearm = "Sidearm",
	smg = "SMG",
	shotgun = "Shotgun",
	rifle = "Rifle",
	sniper = "Sniper",
	heavy = "Machine gun",
}

-- The menu's columns: groups of WeaponConfig.Arsenal by name, then the shields.
local COLUMNS = { { "Sidearms" }, { "SMGs", "Shotguns" }, { "Rifles" }, { "Snipers", "Machine guns" } }

type Tile = { id: string, item: Shop.Item, button: TextButton, stroke: UIStroke, tag: TextLabel, name: TextLabel, price: TextLabel }

local tiles: { Tile } = {}
local hovered: string? = nil
local me = Players.LocalPlayer

local function num(v: number): string
	return string.format("%g", v)
end

local function bought(): { [string]: boolean }
	local out = {}
	local list = me:GetAttribute(Shop.BOUGHT_ATTRIBUTE)
	if typeof(list) == "string" then
		for id in string.gmatch(list, "[^,]+") do
			out[id] = true
		end
	end
	return out
end

local function shieldWorn(): string
	local kind = me:GetAttribute(Shop.SHIELD_ATTRIBUTE)
	return if typeof(kind) == "string" then kind else ""
end

-- Our copy of what we've bought this buy phase and what it replaced, for
-- what buying something costs.
local function shopState(): Shop.State
	local bought = me:GetAttribute(Shop.BOUGHT_ATTRIBUTE)
	local before = me:GetAttribute(Shop.BEFORE_ATTRIBUTE)
	return Shop.fromLists(if typeof(bought) == "string" then bought else nil, if typeof(before) == "string" then before else nil)
end

-- Our credits, when things cost them (the spike rounds).
local function credits(): number?
	local value = me:GetAttribute(MatchConfig.CREDITS)
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true or Workspace:GetAttribute(ArenaConfig.MODE) ~= "spike" then
		return nil
	end
	return if typeof(value) == "number" then value else nil
end

-- What the round being played pays our side, won and lost, as the next
-- starts; nil when the next starts everyone over.
local function stakes(arena: Instance?): MatchRules.Payout?
	local side = me:GetAttribute(ArenaConfig.SIDE)
	local key = arena and arena:GetAttribute("Format")
	local format = if typeof(key) == "string" then MatchConfig.Formats[key] else nil
	local round = arena and arena:GetAttribute("Round")
	if not arena or not format or typeof(side) ~= "number" or typeof(round) ~= "number" or round < 1 then
		return nil
	end
	local streak = arena:GetAttribute("Streak" .. side)
	return MatchRules.payout(format, round, if typeof(streak) == "number" then streak else 0)
end

-- Whether buying is open for us now, as the server will see it.
function BuyMenu.canBuy(): boolean
	if not PlayerController.alive then
		return false
	end
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return true
	end
	local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
	local phase = arena and arena:GetAttribute("Phase")
	return typeof(me:GetAttribute(ArenaConfig.SIDE)) == "number" and (phase == "buy" or phase == "waiting")
end

-- Asks the server to buy or sell an item. A gun bought is drawn, once the
-- server has put it in its slot.
function BuyMenu.request(action: "buy" | "sell", id: string)
	Remotes.get().Buy:FireServer(action, id)
	local def = WeaponConfig.Defs[id]
	if action == "buy" and def then
		PlayerController.drawWhenGiven(def.slot, id)
	end
end

-- The numbers shown for the item under the cursor ------------------------------

local function row(name: string, value: string): string
	return string.format('<font color="#%s">%-16s</font>%s', Ui.hex(Ui.DIM), name, value)
end

local function weaponLines(def: WeaponConfig.WeaponDef): { string }
	local lines = {}
	local mode = WeaponConfig.mode(def, 0)
	local spinUp = def.spinUp
	table.insert(lines, string.format("%s, %s", CATEGORY[def.category] or def.category, if def.fireMode == "auto" then "automatic" else "semi-automatic"))
	table.insert(lines, "")
	table.insert(lines, row("Fire rate", if spinUp then string.format("%s rising to %s a second", num(mode.rate), num(spinUp.maxRate.value)) else string.format("%s a second", num(mode.rate))))
	local ads = def.ads
	if ads then
		local zoom = WeaponConfig.mode(def, 1)
		local levels = {}
		for _, level in ads.zoom do
			table.insert(levels, num(level) .. "x")
		end
		local how = if zoom.burstRounds > 1
			then string.format("%d-round bursts", zoom.burstRounds)
			elseif math.abs(zoom.rate - mode.rate) > 1e-6 then string.format("%s a second", num(math.floor(zoom.rate * 100 + 0.5) / 100))
			else ""
		table.insert(lines, row("Zoomed", table.concat(levels, ", ") .. (if how ~= "" then ", " .. how else "")))
	end
	local alt = WeaponConfig.altMode(def)
	if alt then
		table.insert(lines, row("Right click", string.format("%d bullets at once, %s a second", alt.pellets, num(alt.rate))))
	end
	table.insert(lines, row("Run speed", string.format("%.2f m/s", def.moveMultiplier.value * MovementConfig.Params.baseRunSpeed.value)))
	table.insert(lines, row("Draw", string.format("%s s", num(def.equipTime.value))))
	local perRound, oneRound = def.reloadPerRound, def.reloadOneRound
	table.insert(
		lines,
		row(
			"Reload",
			if perRound
				then string.format("%s s a round (%s s from empty)", num(perRound.value), num(def.reloadTime.value))
				elseif oneRound then string.format("%s s for one round, %s s for two", num(oneRound.value), num(def.reloadTime.value))
				else string.format("%s s", num(def.reloadTime.value))
		)
	)
	table.insert(lines, row("Magazine", string.format("%d, %d in reserve", def.magazine.value, def.reserve.value)))
	table.insert(lines, row("Walls", (def.penetration:gsub("^%l", string.upper))))
	table.insert(lines, "")
	local pellets = def.pellets
	table.insert(lines, string.format('<font color="#%s">%-16s</font>%6s %6s %6s', Ui.hex(Ui.DIM), if pellets then string.format("A pellet (of %d)", pellets.value) else "Damage", "Head", "Body", "Legs"))
	local from = 0
	for i, band in def.damage do
		local range = if #def.damage == 1 then "Any range" elseif i == #def.damage then string.format("%s m on", num(from)) else string.format("%s-%s m", num(from), num(band.maxRange))
		table.insert(lines, string.format("%-16s%6s %6s %6s", range, num(band.head), num(band.body), num(band.legs)))
		from = band.maxRange
	end
	if def.suppressed then
		table.insert(lines, "")
		table.insert(lines, "Suppressed: quieter, and the other side sees no tracers")
	end
	return lines
end

local function shieldLines(def: WeaponConfig.ShieldDef): { string }
	local lines = {}
	table.insert(lines, "Shield")
	table.insert(lines, "")
	table.insert(lines, row("Shield", string.format("%d", def.points.value)))
	local regen = def.regen
	if def.absorb.value >= 1 then
		table.insert(lines, "Takes every point of a hit until it's gone")
	else
		table.insert(lines, string.format("Takes %d%% of each hit until it's gone,", math.floor(def.absorb.value * 100 + 0.5)))
		table.insert(lines, "and health takes the rest")
	end
	if regen then
		table.insert(lines, string.format("Refills from a pool of %d, %s s after", regen.pool.value, num(regen.delay.value)))
		table.insert(lines, "you were last hit")
	end
	return lines
end

-- Building ---------------------------------------------------------------------

-- The gun side on, muzzle to the right, fitted into `area`.
local function drawSilhouette(area: Frame, id: string)
	local shape = WeaponLooks.shape(id)
	local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
	for _, piece in shape.pieces do
		local x0, x1 = -(piece.offset.z + piece.size.z / 2), -(piece.offset.z - piece.size.z / 2)
		local y0, y1 = piece.offset.y - piece.size.y / 2, piece.offset.y + piece.size.y / 2
		minX, maxX = math.min(minX, x0), math.max(maxX, x1)
		minY, maxY = math.min(minY, y0), math.max(maxY, y1)
	end
	local w, h = area.Size.X.Offset, area.Size.Y.Offset
	local scale = math.min(w / (maxX - minX), h / (maxY - minY))
	local padX = (w - (maxX - minX) * scale) / 2
	local padY = (h - (maxY - minY) * scale) / 2
	for i, piece in shape.pieces do
		local x0 = -(piece.offset.z + piece.size.z / 2)
		local y1 = piece.offset.y + piece.size.y / 2
		local colour = WeaponLooks.colour(id, piece)
		Ui.frame(area, {
			Name = "Piece" .. i,
			BackgroundColor3 = if colour == WeaponLooks.BODY then Color3.fromRGB(150, 155, 168) else colour,
			BackgroundTransparency = 0,
			Position = UDim2.fromOffset(math.floor(padX + (x0 - minX) * scale + 0.5), math.floor(padY + (maxY - y1) * scale + 0.5)),
			Size = UDim2.fromOffset(math.max(math.floor(piece.size.z * scale + 0.5), 1), math.max(math.floor(piece.size.y * scale + 0.5), 1)),
			ZIndex = 2 + i,
		})
	end
end

-- A shield's points as blocks of 25.
local function drawShield(area: Frame, def: WeaponConfig.ShieldDef)
	local blocks = math.max(math.floor(def.points.value / 25 + 0.5), 1)
	local bw = 34
	local total = blocks * bw + (blocks - 1) * 6
	for i = 1, blocks do
		Ui.frame(area, {
			BackgroundColor3 = if def.regen then SELLABLE else Color3.fromRGB(150, 180, 240),
			BackgroundTransparency = 0,
			Position = UDim2.fromOffset((area.Size.X.Offset - total) / 2 + (i - 1) * (bw + 6), area.Size.Y.Offset / 2 - 7),
			Size = UDim2.fromOffset(bw, 14),
			ZIndex = 3,
		})
	end
end

local function makeTile(parent: Frame, id: string, name: string, price: number, x: number, y: number): Tile?
	local item = Shop.item(id)
	if not item then
		return nil
	end
	local button = Instance.new("TextButton")
	button.Name = id
	button.AutoButtonColor = false
	button.Text = ""
	button.BorderSizePixel = 0
	button.BackgroundColor3 = TILE
	button.BackgroundTransparency = 0.1
	button.Position = UDim2.fromOffset(x, y)
	button.Size = UDim2.fromOffset(TILE_W, TILE_H)
	button.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = button

	local area = Ui.frame(button, {
		Name = "Look",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 16),
		Size = UDim2.fromOffset(TILE_W - 28, 30),
	})
	local shield = WeaponConfig.Shields[id]
	if shield then
		drawShield(area, shield)
	else
		drawSilhouette(area, id)
	end
	local nameLabel = Ui.label(button, {
		Text = name:upper(),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Position = UDim2.fromOffset(8, TILE_H - 20),
		Size = UDim2.fromOffset(TILE_W - 16, 16),
		ZIndex = 5,
	})
	local priceLabel = Ui.label(button, {
		Text = if price > 0 then tostring(price) else "FREE",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(8, 4),
		Size = UDim2.fromOffset(TILE_W - 16, 14),
		ZIndex = 5,
	})
	local tag = Ui.label(button, {
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		Position = UDim2.fromOffset(8, 5),
		Size = UDim2.fromOffset(TILE_W - 60, 12),
		ZIndex = 5,
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
		BuyMenu.request("buy", id)
	end)
	button.MouseButton2Click:Connect(function()
		BuyMenu.request("sell", id)
	end)
	local tile = { id = id, item = item, button = button, stroke = stroke, tag = tag, name = nameLabel, price = priceLabel }
	table.insert(tiles, tile)
	return tile
end

local function groupNamed(name: string): { ids: { string } }?
	for _, group in WeaponConfig.Arsenal do
		if group.name == name then
			return group
		end
	end
	return nil
end

local function header(parent: Frame, text: string, x: number, y: number)
	Ui.label(parent, {
		Text = text:upper(),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(TILE_W, HEADER_H - 4),
	})
end

function BuyMenu.start()
	local gui = Ui.screen("VFBuyMenu", 20)
	gui.Enabled = false
	local columns = #COLUMNS + 1
	local width = MARGIN * 2 + columns * COLUMN_W + PANEL_W
	local height = TOP + 6 * (TILE_H + GAP) + HEADER_H + 54
	local root = Ui.frame(gui, {
		Name = "Menu",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.15,
		Active = true,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = root

	Ui.label(root, {
		Text = "BUY",
		Font = Enum.Font.GothamBold,
		TextSize = 28,
		Position = UDim2.fromOffset(MARGIN, 14),
		Size = UDim2.fromOffset(120, 32),
	})
	local status = Ui.label(root, {
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = GOLD,
		Position = UDim2.fromOffset(MARGIN + 90, 24),
		Size = UDim2.fromOffset(width - 2 * MARGIN - 300, 18),
	})
	local timer = Ui.label(root, {
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(width - MARGIN - 300, 20),
		Size = UDim2.fromOffset(300, 24),
	})
	Ui.label(root, {
		Text = "Click to buy   Right-click to sell back what you bought this buy phase   B to close",
		TextSize = 13,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(MARGIN, height - 28),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 16),
	})

	-- The guns, a column of groups at a time, then the shields.
	for c, names in COLUMNS do
		local x = MARGIN + (c - 1) * COLUMN_W
		local y = TOP
		for g, name in names do
			local group = groupNamed(name)
			if group then
				if g > 1 then
					y += GROUP_GAP
				end
				header(root, name, x, y)
				y += HEADER_H
				for _, id in group.ids do
					local def = WeaponConfig.get(id)
					makeTile(root, id, def.name, def.price.value, x, y)
					y += TILE_H + GAP
				end
			end
		end
	end
	local shieldX = MARGIN + #COLUMNS * COLUMN_W
	header(root, "Shields", shieldX, TOP)
	for i, id in WeaponConfig.ShieldIds do
		local def = WeaponConfig.Shields[id]
		makeTile(root, id, def.name, def.price.value, shieldX, TOP + HEADER_H + (i - 1) * (TILE_H + GAP))
	end

	-- What the item under the cursor does.
	local panelX = MARGIN + columns * COLUMN_W
	local panel = Ui.frame(root, {
		Name = "Info",
		Position = UDim2.fromOffset(panelX, TOP),
		Size = UDim2.fromOffset(PANEL_W, height - TOP - 44),
		BackgroundColor3 = TILE,
		BackgroundTransparency = 0.1,
	})
	local title = Ui.label(panel, {
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(PANEL_W - 24, 24),
	})
	local price = Ui.label(panel, {
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(PANEL_W - 24, 20),
	})
	local body = Ui.label(panel, {
		TextSize = 12,
		LineHeight = 1.15,
		TextWrapped = true,
		Position = UDim2.fromOffset(12, 40),
		Size = UDim2.fromOffset(PANEL_W - 24, height - TOP - 44 - 80),
	})
	local hint = Ui.label(panel, {
		TextSize = 12,
		TextColor3 = SELLABLE,
		Position = UDim2.fromOffset(12, height - TOP - 44 - 30),
		Size = UDim2.fromOffset(PANEL_W - 24, 18),
	})

	local function setOpen(open: boolean)
		-- Not over the settings menu, which has the cursor already.
		open = open and BuyMenu.canBuy() and (BuyMenu.open or not CameraController.cursorFree)
		if open == BuyMenu.open then
			return
		end
		BuyMenu.open = open
		gui.Enabled = open
		CameraController.cursorFree = open
		InputSampler.blockMouse = open
		if not open then
			hovered = nil
		end
	end
	BuyMenu.setOpen = setOpen

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.B then
			return
		end
		setOpen(not BuyMenu.open)
	end)

	RunService.RenderStepped:Connect(function()
		if not BuyMenu.open then
			return
		end
		if not BuyMenu.canBuy() then
			setOpen(false)
			return
		end
		local viewport = Workspace.CurrentCamera.ViewportSize
		scale.Scale = math.min(1, (viewport.X - 40) / width, (viewport.Y - 40) / height)

		local arenaOn = Workspace:GetAttribute(ArenaConfig.ON) == true
		local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
		local wallet = credits()
		if wallet then
			local pay = stakes(arena)
			status.Text = string.format("%d CREDITS", wallet)
				.. if pay and pay.won == pay.lost
					then string.format("     THIS ROUND PAYS +%d", pay.won)
					elseif pay then string.format("     WIN +%d   LOSE +%d", pay.won, pay.lost)
					else ""
		else
			status.Text = if arenaOn then "SKIRMISH: EVERYTHING'S FREE" else "THE COURSE: EVERYTHING'S FREE"
		end
		local endsAt = arena and arena:GetAttribute("PhaseEndsAt")
		local phase = arena and arena:GetAttribute("Phase")
		timer.Text = if arenaOn and phase == "buy" and typeof(endsAt) == "number"
			then string.format("BUY PHASE  %d", math.ceil(math.max(endsAt - Workspace:GetServerTimeNow(), 0)))
			else ""

		-- What we have: the guns in our slots, the one in hand, the shield.
		local sim = PlayerController.sim
		local loadout = if sim then sim.weapons.loadout else {}
		local inHand = if sim then loadout[sim.weapons.equipped] else nil
		local shield = shieldWorn()
		local sellable = bought()
		local state = shopState()
		local short: { [string]: boolean } = {}
		for _, tile in tiles do
			local owned = tile.id == shield or tile.id == loadout[1] or tile.id == loadout[2]
			local canSell = sellable[tile.id] == true
			local cant = wallet ~= nil and not owned and Shop.cost(state, tile.item) > wallet
			short[tile.id] = cant
			tile.button.BackgroundColor3 = if hovered == tile.id then TILE_HOVER else TILE
			tile.button.BackgroundTransparency = if cant then 0.55 else 0.1
			tile.name.TextColor3 = if cant then Ui.DIM else Ui.TEXT
			tile.price.TextColor3 = if cant then SHORT else GOLD
			tile.stroke.Transparency = if owned then 0.1 else 1
			tile.stroke.Color = if canSell then SELLABLE else OWNED
			tile.tag.Text = if tile.id == inHand then "IN HAND" elseif owned then "OWNED" else ""
			tile.tag.TextColor3 = if canSell then SELLABLE else OWNED
		end

		local id = hovered
		local def = id and WeaponConfig.Defs[id]
		local shieldDef = id and WeaponConfig.Shields[id]
		if def then
			title.Text = def.name:upper()
			price.Text = tostring(def.price.value)
			body.Text = table.concat(weaponLines(def), "\n")
		elseif shieldDef then
			title.Text = shieldDef.name:upper()
			price.Text = tostring(shieldDef.price.value)
			body.Text = table.concat(shieldLines(shieldDef), "\n")
		else
			title.Text = ""
			price.Text = ""
			body.Text = "Point at a gun or a shield to see its numbers."
		end
		local item = if id then Shop.item(id) else nil
		local cost = if item then Shop.cost(state, item) else 0
		hint.TextColor3 = SELLABLE
		if not id or not item then
			hint.Text = ""
		elseif sellable[id] then
			hint.Text = if wallet
				then string.format("Bought this buy phase: right-click to sell it back for %d", Shop.refund(state, item))
				else "Bought this buy phase: right-click to sell it back"
		elseif short[id] then
			hint.Text = string.format("Not enough credits: it costs %d", cost)
			hint.TextColor3 = SHORT
		elseif wallet and state.before[item.slot] == id then
			hint.Text = string.format("Yours already: buying it back refunds %d", -cost)
		elseif wallet and cost ~= item.price then
			hint.Text = if cost < 0
				then string.format("%d back, with what you bought for its slot sold back", -cost)
				else string.format("%d, with what you bought for its slot sold back", cost)
		else
			hint.Text = ""
		end
	end)
end

return BuyMenu
