--!strict
-- The buy menu's server side (system 9). The Buy remote asks to buy or sell
-- one item, and Shop's rules decide. Buying is open in the arena while its
-- rules let a player pick weapons (the buy phase, and while waiting for an
-- opponent), and on the course at any time, as in the reference's practice
-- range; either way the player has to be alive. A gun goes into its slot
-- with full ammo and is drawn, a shield goes on full, and either stays for
-- later lives until the player picks another. Each life is a new buy phase,
-- so what was bought in the last one can't be sold back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Shop = require(Shared.Weapons.Shop)
local Remotes = require(Shared.Net.Remotes)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)

local ShopServer = {}

local states: { [Player]: Shop.State } = {}

local function stateOf(player: Player): Shop.State
	local s = states[player]
	if not s then
		s = Shop.new()
		states[player] = s
	end
	return s
end

-- Tells clients the shield worn and what can be sold back.
local function publish(player: Player)
	local entity = PlayerSimServer.entityOf(player)
	player:SetAttribute(Shop.SHIELD_ATTRIBUTE, if entity then entity.health.kind else nil)
	player:SetAttribute(Shop.BOUGHT_ATTRIBUTE, table.concat(Shop.boughtList(stateOf(player)), ","))
end

-- Whether the player may buy now. The arena's rule says in the arena; with
-- the arena off it says nothing, and the course is always open.
local function isOpen(player: Player): boolean
	if not PlayerSimServer.isAlive(player) then
		return false
	end
	local rule = PlayerSimServer.loadoutRule
	return (if rule then rule(player) else nil) ~= false
end

-- What the item's slot holds now ("" for nothing), or nil if the player
-- isn't playing.
local function holding(player: Player, item: Shop.Item): string?
	if item.kind == "shield" then
		local entity = PlayerSimServer.entityOf(player)
		return if entity then entity.health.kind else nil
	end
	return (PlayerSimServer.holding(player, tonumber(item.slot) :: number))
end

local function put(player: Player, item: Shop.Item, id: string)
	if item.kind == "shield" then
		local entity = PlayerSimServer.entityOf(player)
		if entity then
			CombatServer.setShield(entity, id)
		end
	else
		PlayerSimServer.give(player, tonumber(item.slot) :: number, id)
	end
end

local function onBuy(player: Player, action: any, id: any)
	if typeof(action) ~= "string" or typeof(id) ~= "string" or not isOpen(player) then
		return
	end
	local item = Shop.item(id)
	local current = if item then holding(player, item) else nil
	if not item or current == nil then
		return
	end
	local s = stateOf(player)
	if action == "buy" then
		local entity = PlayerSimServer.entityOf(player)
		if item.kind == "shield" and current == id and entity and entity.health.shield < entity.health.maxShield then
			-- The shield worn, bought again while it's damaged: a fresh one.
			CombatServer.setShield(entity, id)
		elseif Shop.buy(s, item, current) then
			put(player, item, id)
		end
	elseif action == "sell" then
		local back = Shop.sell(s, item)
		if back == "" and item.kind == "weapon" then
			-- A gun can't be sold back to an empty slot: keep the purchase.
			Shop.buy(s, item, "")
		elseif back then
			put(player, item, back)
		end
	end
	publish(player)
end

function ShopServer.start()
	Remotes.get().Buy.OnServerEvent:Connect(onBuy)
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		Shop.reset(stateOf(player))
		publish(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return ShopServer
