--!strict
-- The buy menu's rules (system 9): what's on sale, what goes where, and
-- selling back what was bought in the same buy phase. Plain state, like
-- ArenaRules, so the offline tests can play it; the server's ShopServer
-- applies what it decides to the player's loadout and shield.
--
-- What a purchase costs (system 14): its price, less what was bought into
-- its slot this buy phase, which goes back for its price; buying back what
-- the slot began the phase with costs nothing and refunds what replaced it.
-- Selling a purchase refunds its price and puts back what its slot held
-- when the buy phase began. Only the spike rounds charge: the course and the
-- arena's Skirmish have no economy ("full weapon selection each round",
-- Patch 12.03), so their prices are shown and not charged.
--
-- A buy phase starts everyone on a new life, but Roblox takes a moment to
-- load each character (about a third of a second in Studio, measured), and
-- the phase is open from its first moment. A request in that moment is held
-- for the new life (`hold`) and made once it starts (`takeWaiting`), so it
-- isn't lost with the dead player's old life or reset away with the living
-- one's.
--
-- Abilities (system 17) are sold a charge at a time, at their price a
-- charge, up to what the kit holds (AbilitySim decides, through the
-- server). A charge bought this buy phase can be sold back for its price,
-- and another agent's kit (system 29) sells them all back.

local WeaponConfig = require("./WeaponConfig")
local AbilityConfig = require("../Abilities/AbilityConfig")

export type Kind = "weapon" | "shield" | "ability"

-- `slot`: where it goes, "1" the primary, "2" the sidearm or "shield"; for
-- an ability, its key ("C", "Q").
export type Item = { id: string, kind: Kind, name: string, price: number, slot: string }

-- A buy or a sell held for the life on its way, asked for `at` seconds.
export type Request = { action: string, id: string, at: number }

export type State = {
	-- By slot, for each slot bought into this buy phase: what it held when
	-- the phase began, and what's been bought into it since.
	before: { [string]: string },
	bought: { [string]: string },
	-- By ability id: the charges bought this buy phase.
	charges: { [string]: number },
	waiting: { Request }, -- oldest first
}

local Shop = {}

Shop.SHIELD = "shield"

-- Requests held for one life at most: a few clicks, not a queue.
Shop.MAX_WAITING = 8

-- Player attributes the server keeps up to date for clients: the shield worn,
-- what's been bought this buy phase (ids, comma-separated), which right
-- click can sell back, and what each of those slots held when it began, in
-- the same order ("" for nothing), which buying back costs nothing.
Shop.SHIELD_ATTRIBUTE = "VFShield"
Shop.BOUGHT_ATTRIBUTE = "VFBought"
Shop.BEFORE_ATTRIBUTE = "VFBoughtOver"
-- And the ability charges bought this buy phase: an ability's id for each
-- (comma-separated, "updraft" or "cloudburst,cloudburst").
Shop.CHARGES_ATTRIBUTE = "VFBoughtCharges"

-- The item with this id, if it's on sale: any gun but not the knife, which
-- everyone has, or the spike or an ultimate's or an ability's weapon, which
-- are never sold, the shields, and the abilities sold by the charge.
function Shop.item(id: string): Item?
	local def = WeaponConfig.Defs[id]
	local sold = def and def.category ~= "melee" and def.category ~= "spike" and def.category ~= "ultimate" and def.category ~= "ability"
	if def and sold then
		return { id = id, kind = "weapon", name = def.name, price = def.price.value, slot = tostring(def.slot) }
	end
	local shield = WeaponConfig.Shields[id]
	if shield then
		return { id = id, kind = "shield", name = shield.name, price = shield.price.value, slot = Shop.SHIELD }
	end
	local ability = AbilityConfig.Defs[id]
	local cost = if ability then ability.cost else nil
	if ability and cost then
		return { id = id, kind = "ability", name = ability.name, price = cost.value, slot = AbilityConfig.KEYS[ability.slot] }
	end
	return nil
end

function Shop.new(): State
	return { before = {}, bought = {}, charges = {}, waiting = {} }
end

-- A new buy phase: nothing bought in it yet. Requests held for the life it
-- starts on are kept for `takeWaiting`.
function Shop.reset(s: State)
	table.clear(s.before)
	table.clear(s.bought)
	table.clear(s.charges)
end

-- Holds a request, made at `now`, for the life on its way.
function Shop.hold(s: State, action: string, id: string, now: number)
	if #s.waiting < Shop.MAX_WAITING then
		table.insert(s.waiting, { action = action, id = id, at = now })
	end
end

-- The requests held for the life that has just started, oldest first,
-- leaving out any older than `wait` seconds (a life that never came); none
-- are held after.
function Shop.takeWaiting(s: State, now: number, wait: number): { Request }
	local out = {}
	for _, request in s.waiting do
		if now - request.at <= wait then
			table.insert(out, request)
		end
	end
	table.clear(s.waiting)
	return out
end

-- Buys `item` into its slot, which holds `holding` now. Returns false when
-- there's nothing to do because it's there already. Buying back what the
-- slot began the phase with leaves nothing bought in it.
function Shop.buy(s: State, item: Item, holding: string): boolean
	if holding == item.id then
		return false
	end
	local slot = item.slot
	if s.before[slot] == nil then
		s.before[slot] = holding
	end
	if s.before[slot] == item.id then
		s.before[slot] = nil
		s.bought[slot] = nil
	else
		s.bought[slot] = item.id
	end
	return true
end

-- A fresh one of the shield worn, damaged, bought: it can be sold back for
-- the damaged one. Returns false if something's been bought into its slot
-- this buy phase already.
function Shop.renew(s: State, item: Item): boolean
	local slot = item.slot
	if s.bought[slot] ~= nil then
		return false
	end
	s.before[slot] = item.id
	s.bought[slot] = item.id
	return true
end

local function priceOf(id: string?): number
	local item = if id then Shop.item(id) else nil
	return if item then item.price else 0
end

-- What buying `item` costs now, a refund if negative: its price, less the
-- price of what's been bought into its slot this buy phase, which goes back;
-- and only that refund when it's what the slot began the phase with. An
-- ability's charge costs its price.
function Shop.cost(s: State, item: Item): number
	if item.kind == "ability" then
		return item.price
	end
	local slot = item.slot
	local refund = priceOf(s.bought[slot])
	if s.bought[slot] ~= nil and s.before[slot] == item.id and s.bought[slot] ~= item.id then
		return -refund
	end
	return item.price - refund
end

-- What selling `item` back refunds: its price, if it was bought this buy
-- phase (for an ability, a charge of it).
function Shop.refund(s: State, item: Item): number
	if item.kind == "ability" then
		return if (s.charges[item.id] or 0) > 0 then item.price else 0
	end
	return if s.bought[item.slot] == item.id then item.price else 0
end

-- A charge of the ability `item` bought this buy phase.
function Shop.buyCharge(s: State, item: Item)
	s.charges[item.id] = (s.charges[item.id] or 0) + 1
end

-- A charge of the ability `item` sold back; false if none was bought this
-- buy phase.
function Shop.sellCharge(s: State, item: Item): boolean
	local n = s.charges[item.id] or 0
	if n <= 0 then
		return false
	end
	if n > 1 then
		s.charges[item.id] = n - 1
	else
		s.charges[item.id] = nil
	end
	return true
end

-- Every ability charge bought this buy phase sold back at once, as the kit
-- they were bought into gives way to another agent's (system 29): what
-- they refund.
function Shop.sellCharges(s: State): number
	local refund = 0
	for id, n in s.charges do
		local item = Shop.item(id)
		if item then
			refund += item.price * n
		end
	end
	table.clear(s.charges)
	return refund
end

-- Sells `item` back, if it was bought this buy phase: returns what its slot
-- goes back to, or nil when there's nothing to sell.
function Shop.sell(s: State, item: Item): string?
	local slot = item.slot
	if s.bought[slot] ~= item.id then
		return nil
	end
	local back = s.before[slot]
	s.before[slot] = nil
	s.bought[slot] = nil
	return back
end

-- Forgets what was bought into a gun's slot this buy phase, once the gun
-- has left it (system 15: dropped, or swapped for one off the ground):
-- there's nothing left there to sell back, and what the slot began the phase
-- with doesn't come back for nothing (ours: a refund for a gun someone else
-- has picked up would be a gun for free).
function Shop.forget(s: State, slot: string)
	s.before[slot] = nil
	s.bought[slot] = nil
end

local SLOTS = { "1", "2", Shop.SHIELD }

-- What's been bought this buy phase, primary first.
function Shop.boughtList(s: State): { string }
	local out = {}
	for _, slot in SLOTS do
		local id = s.bought[slot]
		if id then
			table.insert(out, id)
		end
	end
	return out
end

-- The ability charges bought this buy phase: an id for each, by slot.
function Shop.chargeList(s: State): { string }
	local ids = {}
	for id in s.charges do
		table.insert(ids, id)
	end
	table.sort(ids, function(a: string, b: string): boolean
		return AbilityConfig.Defs[a].slot < AbilityConfig.Defs[b].slot
	end)
	local out = {}
	for _, id in ids do
		for _ = 1, s.charges[id] do
			table.insert(out, id)
		end
	end
	return out
end

-- The charges bought this buy phase by ability id, from chargeList's
-- attribute (a client's copy).
function Shop.chargesFrom(text: string?): { [string]: number }
	local out: { [string]: number } = {}
	for id in string.gmatch(text or "", "[^,]+") do
		out[id] = (out[id] or 0) + 1
	end
	return out
end

-- What each slot in boughtList held when the buy phase began, in its order.
function Shop.beforeList(s: State): { string }
	local out = {}
	for _, slot in SLOTS do
		if s.bought[slot] then
			table.insert(out, s.before[slot] or "")
		end
	end
	return out
end

local function split(text: string): { string }
	local out = {}
	local from = 1
	while true do
		local comma = string.find(text, ",", from, true)
		table.insert(out, string.sub(text, from, if comma then comma - 1 else #text))
		if not comma then
			return out
		end
		from = comma + 1
	end
end

-- A client's copy, from the two lists' attributes (boughtList and
-- beforeList, comma-separated), for Shop.cost.
function Shop.fromLists(bought: string?, before: string?): State
	local s = Shop.new()
	if not bought or bought == "" then
		return s
	end
	local was = split(before or "")
	for i, id in split(bought) do
		local item = Shop.item(id)
		if item then
			s.bought[item.slot] = id
			s.before[item.slot] = was[i] or ""
		end
	end
	return s
end

return Shop
