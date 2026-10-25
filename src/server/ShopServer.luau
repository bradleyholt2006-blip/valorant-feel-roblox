--!strict
-- The buy menu's server side (system 9). The Buy remote asks to buy or sell
-- one item, and Shop's rules decide. Buying is open in the arena while its
-- rules let a player pick weapons (the buy phase, and while waiting for an
-- opponent), and on the course at any time, as in the reference's practice
-- range; either way the player has to be alive. A gun goes into its slot
-- with full ammo and is drawn, a shield goes on full, and either stays for
-- later lives until the player picks another. Each life is a new buy phase,
-- so what was bought in the last one can't be sold back.
--
-- In the spike rounds it costs credits (system 14): each purchase is paid
-- for, less the refund of what it replaces from this buy phase, and selling
-- back refunds. A shield goes back to what the slot began the phase with as
-- it was then, damaged or not, so buying another and selling it back can't
-- mend it; buying the damaged one's kind again is a fresh one for its full
-- price, which can be sold back for the damaged one.
--
-- A request that comes while a new life is on its way (the arena respawns
-- everyone as a buy phase opens, and Roblox takes a moment to load each
-- character) is held and made as soon as that life starts.
--
-- Abilities (system 17) are bought a charge at a time into the kit
-- (AbilityServer), and a charge bought this buy phase sells back for its
-- price. Another agent's kit (system 29) sells back every one bought into
-- the last one's (ShopServer.refundCharges).
--
-- Deathmatch (system 26) sells its guns alone (ShopServer.sells), all free.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Shop = require(Shared.Weapons.Shop)
local Health = require(Shared.Combat.Health)
local Remotes = require(Shared.Net.Remotes)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local AbilityServer = require(script.Parent.AbilityServer)

local ShopServer = {}

-- Pays `amount` of a player's credits for a purchase, or refunds them if it's
-- negative, when something charges (the spike rounds' economy), and returns
-- whether they had them. Nil while everything's free.
ShopServer.pay = nil :: ((player: Player, amount: number) -> boolean)?
-- Whether items of a kind (Shop's: "weapon", "shield" or "ability") are for
-- sale, when not everything is (deathmatch). Nil while everything is.
ShopServer.sells = nil :: ((kind: string) -> boolean)?

local states: { [Player]: Shop.State } = {}
-- The shield each player wore when this buy phase first changed it.
local worn: { [Player]: Health.Kept } = {}

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
	local s = stateOf(player)
	player:SetAttribute(Shop.BOUGHT_ATTRIBUTE, table.concat(Shop.boughtList(s), ","))
	player:SetAttribute(Shop.BEFORE_ATTRIBUTE, table.concat(Shop.beforeList(s), ","))
	player:SetAttribute(Shop.CHARGES_ATTRIBUTE, table.concat(Shop.chargeList(s), ","))
end

local function charge(player: Player, amount: number): boolean
	local pay = ShopServer.pay
	return pay == nil or pay(player, amount)
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

-- Puts `id` in the item's slot: for a shield, as it was when this buy phase
-- first changed it if it's going `back` to that, or else a fresh one.
local function put(player: Player, item: Shop.Item, id: string, back: boolean)
	if item.kind == "shield" then
		local entity = PlayerSimServer.entityOf(player)
		if entity then
			CombatServer.setShield(entity, id, if back then worn[player] else nil)
		end
	else
		PlayerSimServer.give(player, tonumber(item.slot) :: number, id)
	end
end

-- Remembers the shield worn before this buy phase first changes it.
local function keepWorn(player: Player, s: Shop.State, item: Shop.Item)
	local entity = PlayerSimServer.entityOf(player)
	if item.kind == "shield" and s.bought[item.slot] == nil and entity then
		worn[player] = Health.keep(entity.health)
	end
end

-- A charge of an ability bought, if the kit has room and they can pay, or
-- one bought this buy phase sold back.
local function handleCharge(player: Player, s: Shop.State, action: string, item: Shop.Item)
	if action == "buy" then
		if AbilityServer.canBuy(player, item.id) and charge(player, Shop.cost(s, item)) then
			AbilityServer.buy(player, item.id)
			Shop.buyCharge(s, item)
		end
	elseif action == "sell" then
		local refund = Shop.refund(s, item)
		if refund > 0 and AbilityServer.sell(player, item.id) then
			Shop.sellCharge(s, item)
			charge(player, -refund)
		end
	end
end

-- Makes one request, if buying is open, the item's for sale and they can
-- pay; publish after.
local function handle(player: Player, action: string, id: string)
	local item = Shop.item(id)
	local sells = ShopServer.sells
	if not isOpen(player) or (item and sells and not sells(item.kind)) then
		return
	end
	if item and item.kind == "ability" then
		handleCharge(player, stateOf(player), action, item)
		return
	end
	local current = if item then holding(player, item) else nil
	if not item or current == nil then
		return
	end
	local s = stateOf(player)
	if action == "buy" then
		local entity = PlayerSimServer.entityOf(player)
		if item.kind == "shield" and current == id and entity and entity.health.shield < entity.health.maxShield then
			-- The shield worn, bought again while it's damaged: a fresh one.
			if s.bought[item.slot] == nil and charge(player, item.price) then
				keepWorn(player, s, item)
				Shop.renew(s, item)
				CombatServer.setShield(entity, id)
			end
		elseif current ~= id and charge(player, Shop.cost(s, item)) then
			local back = s.before[item.slot] == id
			keepWorn(player, s, item)
			Shop.buy(s, item, current)
			put(player, item, id, back)
		end
	elseif action == "sell" then
		local refund = Shop.refund(s, item)
		local back = Shop.sell(s, item)
		if back then
			charge(player, -refund)
			put(player, item, back, true)
		end
	end
end

local function onBuy(player: Player, action: any, id: any)
	if typeof(action) ~= "string" or typeof(id) ~= "string" then
		return
	end
	if PlayerSimServer.spawnPending(player) then
		Shop.hold(stateOf(player), action, id, os.clock())
		return
	end
	handle(player, action, id)
	publish(player)
end

-- Forgets what was bought into one of a player's gun slots this buy phase,
-- once its gun has left it (system 15: dropped, or swapped for one off the
-- ground), so it can't be sold back (Shop.forget).
function ShopServer.forget(player: Player, slot: number)
	local s = states[player]
	if s then
		Shop.forget(s, tostring(slot))
		publish(player)
	end
end

-- Every ability charge bought this buy phase sold back, as the kit they
-- were bought into gives way to another agent's (system 29, AgentServer).
function ShopServer.refundCharges(player: Player)
	local s = states[player]
	if not s then
		return
	end
	local refund = Shop.sellCharges(s)
	if refund > 0 then
		charge(player, -refund)
	end
	publish(player)
end

function ShopServer.start()
	Remotes.get().Buy.OnServerEvent:Connect(onBuy)
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		local s = stateOf(player)
		Shop.reset(s)
		worn[player] = nil
		for _, request in Shop.takeWaiting(s, os.clock(), PlayerSimServer.SPAWN_WAIT) do
			handle(player, request.action, request.id)
		end
		publish(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		worn[player] = nil
	end)
end

return ShopServer
