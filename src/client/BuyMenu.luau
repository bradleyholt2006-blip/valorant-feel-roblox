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
--
-- Under the shields are the abilities sold by the charge (system 17), each
-- with a pip for every charge it holds, lit for each you have: click buys a
-- charge, right-click sells back one bought this buy phase. One that can't
-- be played yet is shown, dimmed, and can't be bought. They're your agent's
-- (system 29), as your kit is.
--
-- In deathmatch (system 26) it opens whenever you're alive, and sells the
-- guns alone, free (DeathmatchConfig.FOR_SALE): every life wears Heavy
-- Armor, and there are no abilities, so the rest is dimmed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local DeathmatchConfig = require(Shared.Arena.DeathmatchConfig)
local MatchConfig = require(Shared.Match.MatchConfig)
local MatchRules = require(Shared.Match.MatchRules)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Shop = require(Shared.Weapons.Shop)
local Remotes = require(Shared.Net.Remotes)
local MovementConfig = require(Shared.Movement.MovementConfig)
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local AgentSelect = require(Shared.Abilities.AgentSelect)

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
-- An ability's tile has a pip for each charge it can hold, and is shown
-- for its agent's kit.
type AbilityTile = Tile & { pips: { Frame }, agent: string }

local tiles: { Tile } = {}
local abilityTiles: { AbilityTile } = {}
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

-- Whether deathmatch is played (system 26).
local function deathmatch(): boolean
	return Workspace:GetAttribute(ArenaConfig.ON) == true and Workspace:GetAttribute(ArenaConfig.MODE) == "deathmatch"
end

-- Whether the mode played sells this: deathmatch, its guns alone.
local function sold(item: Shop.Item): boolean
	return not deathmatch() or DeathmatchConfig.FOR_SALE[item.kind] == true
end

-- Whether buying is open for us now, as the server will see it: never in
-- gun game, whose guns come with its levels (system 23), nor in Team
-- Deathmatch, whose come with its stages (system 27: B is the loadout menu
-- there, LoadoutMenu), and all match long in deathmatch.
function BuyMenu.canBuy(): boolean
	if not PlayerController.alive then
		return false
	end
	local mode = Workspace:GetAttribute(ArenaConfig.MODE)
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return true
	elseif mode == "gungame" or mode == "teamdeathmatch" then
		return false
	end
	local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
	local phase = arena and arena:GetAttribute("Phase")
	local open = phase == "buy" or phase == "waiting" or (phase == "live" and deathmatch())
	return typeof(me:GetAttribute(ArenaConfig.SIDE)) == "number" and open
end

-- Asks the server to buy or sell an item, if the mode sells it. A gun
-- bought is drawn, once the server has put it in its slot.
function BuyMenu.request(action: "buy" | "sell", id: string)
	local item = Shop.item(id)
	if item and not sold(item) then
		return
	end
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

local function abilityLines(def: AbilityConfig.AbilityDef): { string }
	local lines = {}
	local max = if def.charges then def.charges.value else 0
	table.insert(lines, string.format("Ability, on %s", AbilityConfig.KEYS[def.slot]))
	table.insert(lines, "")
	table.insert(lines, def.description)
	table.insert(lines, "")
	table.insert(lines, row("Charges", string.format("up to %d", max)))
	if def.cost then
		table.insert(lines, row("A charge", string.format("%d credits", def.cost.value)))
	end
	if def.id == "updraft" then
		local J = AbilityConfig.Jett
		table.insert(lines, row("Lift", string.format("%s m, in %s s", num(J.updraftApex.value), num(J.updraftTime.value))))
	elseif def.id == "cloudburst" then
		local CB = AbilityConfig.Cloudburst
		table.insert(lines, row("Cloud", string.format("%s m across, for %s s", num(2 * CB.radius.value), num(CB.duration.value))))
		table.insert(lines, row("Flight", string.format("%s m/s, at most %s s", num(CB.speed.value), num(CB.maxFlight.value))))
	elseif def.id == "curveball" then
		local CV = AbilityConfig.Curveball
		table.insert(lines, row("Pop", string.format("%s s after the throw", num(CV.windup.value))))
		table.insert(lines, row("Blind", string.format("up to %s s, then %s s clearing", num(CV.maxBlind.value), num(CV.fade.value))))
	elseif def.id == "hothands" then
		local HH, IF = AbilityConfig.HotHands, AbilityConfig.InnerFire
		table.insert(lines, row("Fire", string.format("%s m across, for %s s", num(2 * HH.radius.value), num(HH.duration.value))))
		table.insert(lines, row("Burn", string.format("%s a second", num(HH.burn.value))))
		local healTime = IF.heal.value * IF.hotHandsEvery.value
		table.insert(lines, row("Heals you", string.format("%s over %s s, Inner Fire", num(IF.heal.value), num(healTime))))
	elseif def.id == "blaze" then
		local BZ, IF = AbilityConfig.Blaze, AbilityConfig.InnerFire
		table.insert(lines, row("Wall", string.format("up to %s m, for %s s", num(BZ.length.value), num(BZ.duration.value))))
		table.insert(lines, row("Burn", string.format("%s a second", num(BZ.burn.value))))
		local healTime = IF.heal.value * IF.blazeEvery.value
		table.insert(lines, row("Heals you", string.format("%s over %s s, Inner Fire", num(IF.heal.value), num(healTime))))
	elseif def.id == "shockbolt" then
		local SB = AbilityConfig.ShockBolt
		local reach =
			string.format("%s within %s m, %s at %s m", num(SB.damage.value), num(SB.inner.value), num(SB.least.value), num(SB.outer.value))
		table.insert(lines, row("Burst", reach))
	elseif def.id == "owldrone" then
		local OD = AbilityConfig.OwlDrone
		table.insert(lines, row("Flight", string.format("%s s, %s health", num(OD.duration.value), num(OD.health.value))))
		table.insert(lines, row("A dart", string.format("every %s s, %s pings", num(OD.dartCooldown.value), num(OD.pings.value))))
	end
	local recharge = def.recharge
	if recharge and recharge.kind == "kills" then
		table.insert(lines, row("A charge back", string.format("every %d kills", recharge.kills.value)))
	end
	table.insert(lines, "")
	table.insert(lines, "Unused charges carry into the next round, and through a death; a new half takes them away.")
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

-- An ability's tile, of `agent`'s kit: its key large where a gun's look
-- goes, and a pip for each charge it can hold.
local function makeAbilityTile(parent: Frame, def: AbilityConfig.AbilityDef, agent: string, x: number, y: number): AbilityTile?
	local item = Shop.item(def.id)
	if not item then
		return nil
	end
	local id = def.id
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
	Ui.label(button, {
		Text = AbilityConfig.KEYS[def.slot],
		Font = Enum.Font.GothamBold,
		TextSize = 24,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(12, 18),
		Size = UDim2.fromOffset(30, 28),
		ZIndex = 5,
	})
	local max = if def.charges then def.charges.value else 0
	local pips: { Frame } = {}
	for i = 1, max do
		table.insert(
			pips,
			Ui.frame(button, {
				BackgroundTransparency = 0,
				Position = UDim2.fromOffset(48 + (i - 1) * 22, 28),
				Size = UDim2.fromOffset(18, 6),
				ZIndex = 5,
			})
		)
	end
	local nameLabel = Ui.label(button, {
		Text = def.name:upper(),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Position = UDim2.fromOffset(8, TILE_H - 20),
		Size = UDim2.fromOffset(TILE_W - 16, 16),
		ZIndex = 5,
	})
	local priceLabel = Ui.label(button, {
		Text = tostring(item.price),
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
	local tile: AbilityTile = {
		id = id,
		item = item,
		button = button,
		stroke = stroke,
		tag = tag,
		name = nameLabel,
		price = priceLabel,
		pips = pips,
		agent = agent,
	}
	table.insert(abilityTiles, tile)
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
	-- Tall enough for the longest column: the sidearms, or the shields over
	-- the most abilities an agent has for sale (Phoenix's three, system 30).
	local most = 0
	for _, agent in AbilityConfig.AgentIds do
		local sold = 0
		for slot = AbilityConfig.C, AbilityConfig.E do
			local def = AbilityConfig.abilityOf(agent, slot)
			if def and def.cost and Shop.item(def.id) then
				sold += 1
			end
		end
		most = math.max(most, sold)
	end
	local guns = HEADER_H + 6 * (TILE_H + GAP)
	local shields = 2 * HEADER_H + (#WeaponConfig.ShieldIds + most) * (TILE_H + GAP) + GROUP_GAP
	local height = TOP + math.max(guns, shields) + 54
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
	-- The abilities sold by the charge: each agent's in the same places, shown
	-- for the agent of your kit.
	local abilityY = TOP + HEADER_H + #WeaponConfig.ShieldIds * (TILE_H + GAP) + GROUP_GAP
	header(root, "Abilities", shieldX, abilityY)
	abilityY += HEADER_H
	for _, agent in AbilityConfig.AgentIds do
		local y = abilityY
		for slot = AbilityConfig.C, AbilityConfig.E do
			local def = AbilityConfig.abilityOf(agent, slot)
			if def and def.cost and makeAbilityTile(root, def, agent, shieldX, y) then
				y += TILE_H + GAP
			end
		end
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
			status.Text = if deathmatch()
				then "DEATHMATCH: EVERY GUN'S FREE"
				elseif arenaOn then "SKIRMISH: EVERYTHING'S FREE"
				else "THE COURSE: EVERYTHING'S FREE"
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
			local unsold = not owned and not sold(tile.item)
			short[tile.id] = cant
			tile.button.BackgroundColor3 = if hovered == tile.id then TILE_HOVER else TILE
			tile.button.BackgroundTransparency = if cant or unsold then 0.55 else 0.1
			tile.name.TextColor3 = if cant or unsold then Ui.DIM else Ui.TEXT
			tile.price.TextColor3 = if cant then SHORT elseif unsold then Ui.DIM else GOLD
			tile.stroke.Transparency = if owned then 0.1 else 1
			tile.stroke.Color = if canSell then SELLABLE else OWNED
			tile.tag.Text = if tile.id == inHand then "IN HAND" elseif owned then "OWNED" elseif unsold then "NOT SOLD" else ""
			tile.tag.TextColor3 = if canSell then SELLABLE elseif unsold then Ui.DIM else OWNED
		end
		-- The abilities: the charges in our kit, as predicted, of its agent's;
		-- with a kit of no agent's (deathmatch), those of the agent we play.
		local kit = if sim then sim.abilities else nil
		local picked = me:GetAttribute(AgentSelect.AGENT)
		local agent = if kit and kit.agent ~= AbilityConfig.NO_AGENT
			then kit.agent
			elseif typeof(picked) == "string" then picked
			else AbilityConfig.DEFAULT_AGENT
		local chargesBought = Shop.chargesFrom(me:GetAttribute(Shop.CHARGES_ATTRIBUTE) :: string?)
		for _, tile in abilityTiles do
			tile.button.Visible = tile.agent == agent
			local slot = if kit then AbilitySim.slotOf(kit, tile.id) else nil
			local have = if kit and slot then kit.charges[slot] else 0
			local max = if kit and slot then AbilitySim.maxCharges(kit, slot) else 0
			local playable = AbilitySim.playable(tile.id)
			local unsold = not sold(tile.item)
			local canSell = (chargesBought[tile.id] or 0) > 0
			local cant = not playable or have >= max or (wallet ~= nil and tile.item.price > wallet)
			short[tile.id] = wallet ~= nil and playable and have < max and tile.item.price > wallet
			tile.button.BackgroundColor3 = if hovered == tile.id then TILE_HOVER else TILE
			tile.button.BackgroundTransparency = if unsold or (cant and have < max) then 0.55 else 0.1
			tile.name.TextColor3 = if unsold or not playable then Ui.DIM else Ui.TEXT
			tile.price.TextColor3 = if short[tile.id] then SHORT elseif unsold then Ui.DIM else GOLD
			tile.stroke.Transparency = if have > 0 then 0.1 else 1
			tile.stroke.Color = if canSell then SELLABLE else OWNED
			tile.tag.Text = if unsold then "NOT SOLD" elseif not playable then "NOT YET" elseif have >= max then "FULL" else ""
			tile.tag.TextColor3 = if canSell then SELLABLE elseif unsold then Ui.DIM else OWNED
			for i, pip in tile.pips do
				pip.BackgroundColor3 = if i <= have then OWNED else Color3.fromRGB(70, 72, 80)
			end
		end

		local id = hovered
		local def = id and WeaponConfig.Defs[id]
		local shieldDef = id and WeaponConfig.Shields[id]
		local abilityDef = id and AbilityConfig.Defs[id]
		if abilityDef then
			title.Text = abilityDef.name:upper()
			price.Text = if abilityDef.cost then tostring(abilityDef.cost.value) else ""
			body.Text = table.concat(abilityLines(abilityDef), "\n")
		elseif def then
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
			body.Text = "Point at a gun, a shield or an ability to see its numbers."
		end
		local item = if id then Shop.item(id) else nil
		local cost = if item then Shop.cost(state, item) else 0
		hint.TextColor3 = SELLABLE
		local slot = if kit and abilityDef then AbilitySim.slotOf(kit, abilityDef.id) else nil
		if not id or not item then
			hint.Text = ""
		elseif not sold(item) then
			hint.Text = if abilityDef then "No abilities in deathmatch" else "Deathmatch sells guns alone: every life wears Heavy Armor"
			hint.TextColor3 = Ui.DIM
		elseif abilityDef then
			local have = if kit and slot then kit.charges[slot] else 0
			local max = if kit and slot then AbilitySim.maxCharges(kit, slot) else 0
			if not AbilitySim.playable(id) then
				hint.Text = "Not playable yet: it comes with a later system"
				hint.TextColor3 = Ui.DIM
			elseif (chargesBought[id] or 0) > 0 then
				hint.Text = if wallet
					then string.format("Right-click to sell a charge bought this buy phase back for %d", item.price)
					else "Right-click to sell back a charge bought this buy phase"
			elseif have >= max then
				hint.Text = string.format("Full: you have its %d", max)
				hint.TextColor3 = OWNED
			elseif short[id] then
				hint.Text = string.format("Not enough credits: a charge costs %d", item.price)
				hint.TextColor3 = SHORT
			else
				hint.Text = ""
			end
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
