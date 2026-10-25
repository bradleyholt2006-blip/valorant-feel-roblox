--!strict
-- The buy menu's rules (system 9): what's on sale, what goes where, and
-- selling back what was bought in the same buy phase. Plain state, like
-- ArenaRules, so the offline tests can play it; the server's ShopServer
-- applies what it decides to the player's loadout and shield.
--
-- Nothing costs anything yet: the course and the arena's Skirmish have no
-- economy ("full weapon selection each round", Patch 12.03), so prices are
-- shown and not charged. Selling a purchase puts back what its slot held
-- when the buy phase began, as a refund would in the reference.

local WeaponConfig = require("./WeaponConfig")

export type Kind = "weapon" | "shield"

-- `slot`: where it goes, "1" the primary, "2" the sidearm or "shield".
export type Item = { id: string, kind: Kind, name: string, price: number, slot: string }

export type State = {
	-- By slot, for each slot bought into this buy phase: what it held when
	-- the phase began, and what's been bought into it since.
	before: { [string]: string },
	bought: { [string]: string },
}

local Shop = {}

Shop.SHIELD = "shield"

-- Player attributes the server keeps up to date for clients: the shield worn,
-- and what's been bought this buy phase (ids, comma-separated), which right
-- click can sell back.
Shop.SHIELD_ATTRIBUTE = "VFShield"
Shop.BOUGHT_ATTRIBUTE = "VFBought"

-- The item with this id, if it's on sale: any gun but not the knife, which
-- everyone has, and the shields.
function Shop.item(id: string): Item?
	local def = WeaponConfig.Defs[id]
	if def and def.category ~= "melee" then
		return { id = id, kind = "weapon", name = def.name, price = def.price.value, slot = tostring(def.slot) }
	end
	local shield = WeaponConfig.Shields[id]
	if shield then
		return { id = id, kind = "shield", name = shield.name, price = shield.price.value, slot = Shop.SHIELD }
	end
	return nil
end

function Shop.new(): State
	return { before = {}, bought = {} }
end

-- A new buy phase: nothing bought in it yet.
function Shop.reset(s: State)
	table.clear(s.before)
	table.clear(s.bought)
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

-- What's been bought this buy phase, primary first.
function Shop.boughtList(s: State): { string }
	local out = {}
	for _, slot in { "1", "2", Shop.SHIELD } do
		local id = s.bought[slot]
		if id then
			table.insert(out, id)
		end
	end
	return out
end

return Shop
