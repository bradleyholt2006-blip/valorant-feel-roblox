--!strict
-- Buying for teammates (system 57): what can be asked for, asking and
-- taking it back, plans, when a request can be bought and by whom, and
-- whose credits go where as a gun bought for a teammate is sold back,
-- replaced or dropped.

local Shop = require("../src/shared/Weapons/Shop")
local TeamBuy = require("../src/shared/Weapons/TeamBuy")
local H = require("./Harness")

local check = H.check

H.section("Buying for teammates (system 57)")

do
	local askable = TeamBuy.askable
	check("any gun that costs something can be asked for", askable("vandal") and askable("sheriff") and askable("operator"))
	check("not the free Classic", not askable("classic"))
	check("nor a shield or an ability", not askable("heavy") and not askable("light") and not askable("updraft"))
	check("nor what isn't sold", not askable("knife") and not askable("spike") and not askable(""))

	local canAsk = TeamBuy.canAsk
	check("a gun they don't have can be asked for", canAsk("vandal", "", nil) and canAsk("phantom", "spectre", ""))
	check("not one they have", not canAsk("vandal", "vandal", nil))
	check("nor one their slot began the buy phase with, theirs to buy back for nothing", not canAsk("vandal", "spectre", "vandal"))
	check("nor by someone not playing", not canAsk("vandal", nil, nil))
end

do
	local ask = TeamBuy.ask
	check("asking for a gun is a request for it", ask(nil, "vandal") == "vandal")
	check("asking for another changes it", ask("vandal", "phantom") == "phantom")
	check("asking for it again takes it back", ask("vandal", "vandal") == nil)
	check("and so does nothing", ask("vandal", "") == nil and ask(nil, "") == nil)

	local plan = TeamBuy.plan
	check("a plan's picked", plan(nil, "save") == "save" and plan("save", "extra") == "extra")
	check("and picked again it's gone", plan("save", "save") == nil and plan("buy", "") == nil)
	check("what isn't a plan changes nothing", plan("buy", "rush") == "buy" and plan(nil, "rush") == nil)
	local all = true
	for _, key in TeamBuy.PLANS do
		all = all and TeamBuy.TITLES[key] ~= nil
	end
	check("three plans, each with its title", #TeamBuy.PLANS == 3 and all and TeamBuy.TITLES.extra == "EXTRA CREDITS")
end

do
	-- A teammate on side 1 asking for a Vandal, with an empty slot, and a
	-- buyer with 4000 credits; then as `edit` changes it.
	local function offer(edit: ((TeamBuy.Offer) -> ())?): TeamBuy.Offer
		local o: TeamBuy.Offer = {
			id = "vandal",
			asked = "vandal",
			same = false,
			buyerSide = 1,
			askerSide = 1,
			holding = "",
			before = nil,
			credits = 4000,
		}
		if edit then
			edit(o)
		end
		return o
	end
	local refusal = TeamBuy.refusal
	check("a teammate's request can be bought for them", refusal(offer()) == nil)
	check("not by them", refusal(offer(function(o)
		o.same = true
	end)) == "team")
	check("nor by the other side", refusal(offer(function(o)
		o.askerSide = 2
	end)) == "team")
	check("nor where teammates don't buy for each other", refusal(offer(function(o)
		o.buyerSide, o.askerSide = nil, nil
	end)) == "team")
	check("nor once they've stopped asking for it", refusal(offer(function(o)
		o.asked = nil
	end)) == "asked")
	check("nor once they're asking for something else", refusal(offer(function(o)
		o.asked = "phantom"
	end)) == "asked")
	check("nor once they have it", refusal(offer(function(o)
		o.holding = "vandal"
	end)) == "has")
	check("or can buy it back for nothing", refusal(offer(function(o)
		o.holding, o.before = "spectre", "vandal"
	end)) == "has")
	check("nor for more than the buyer's credits", refusal(offer(function(o)
		o.credits = 2899
	end)) == "short")
	check("which can be all of them", refusal(offer(function(o)
		o.credits = 2900
	end)) == nil)
	check("and where the caller checks them, not here", refusal(offer(function(o)
		o.credits = nil
	end)) == nil)
end

-- The money, as the server moves it: A asks, B and C are teammates who buy.
type World = { credits: { [number]: number }, shop: Shop.State, slots: { [string]: string }, asked: string? }
local A, B, C = 1, 2, 3

local function world(a: number, b: number, primary: string?): World
	return { credits = { [A] = a, [B] = b, [C] = 4000 }, shop = Shop.new(), slots = { ["1"] = primary or "", ["2"] = "classic" } }
end

local function pay(w: World, id: number, amount: number): boolean
	if amount > w.credits[id] then
		return false
	end
	w.credits[id] -= amount
	return true
end

-- A buys `id` themselves.
local function buy(w: World, id: string): boolean
	local item = Shop.item(id) :: Shop.Item
	local current = w.slots[item.slot]
	if current == id or not pay(w, A, Shop.cost(w.shop, item)) then
		return false
	end
	local owed, by = Shop.payback(w.shop, item.slot)
	Shop.buy(w.shop, item, current)
	w.slots[item.slot] = id
	if by then
		w.credits[by] += owed
	end
	return true
end

-- A sells `id` back.
local function sell(w: World, id: string): boolean
	local item = Shop.item(id) :: Shop.Item
	local refund = Shop.refund(w.shop, item)
	local _, by = Shop.payback(w.shop, item.slot)
	local back = Shop.sell(w.shop, item)
	if not back then
		return false
	end
	w.credits[by or A] += refund
	w.slots[item.slot] = back
	return true
end

-- `buyer` buys A the gun they're asking for, if they can.
local function give(w: World, buyer: number, id: string): boolean
	local item = Shop.item(id) :: Shop.Item
	local current = w.slots[item.slot]
	local why = TeamBuy.refusal({
		id = id,
		asked = w.asked,
		same = buyer == A,
		buyerSide = 1,
		askerSide = 1,
		holding = current,
		before = w.shop.before[item.slot],
		credits = w.credits[buyer],
	})
	if why then
		return false
	end
	local owed, by = Shop.payback(w.shop, item.slot)
	pay(w, buyer, item.price)
	Shop.give(w.shop, item, current, buyer)
	w.slots[item.slot] = id
	w.credits[by or A] += owed
	w.asked = nil
	return true
end

do
	local w = world(800, 4000)
	w.asked = "vandal"
	check("a teammate buys it: they pay its price", give(w, B, "vandal") and w.credits[B] == 1100)
	check("and it's in the asker's slot, theirs for nothing", w.slots["1"] == "vandal" and w.credits[A] == 800)
	check(
		"bought this buy phase, by the teammate",
		table.concat(Shop.boughtList(w.shop), ",") == "vandal" and table.concat(Shop.paidList(w.shop), ",") == tostring(B)
	)
	check("bought once: the next to try finds the request gone", not give(w, C, "vandal") and w.credits[C] == 4000)
	check("sold back, its price goes to the teammate", sell(w, "vandal") and w.credits[B] == 4000 and w.credits[A] == 800)
	check("and the slot's as it began", w.slots["1"] == "" and #Shop.boughtList(w.shop) == 0 and next(w.shop.paid) == nil)
end

do
	local w = world(800, 4000)
	w.asked = "spectre"
	give(w, B, "spectre")
	local phantom = Shop.item("phantom") :: Shop.Item
	check("another gun over it costs the asker its full price", Shop.cost(w.shop, phantom) == 2900)
	check("which they can't pay with less", not buy(w, "phantom") and w.slots["1"] == "spectre" and w.credits[B] == 2400)
	w.credits[A] = 3000
	check("and with enough, pay", buy(w, "phantom") and w.credits[A] == 100 and w.slots["1"] == "phantom")
	check("while the teammate gets the Spectre's price back", w.credits[B] == 4000)
	check("the Phantom's theirs, bought by them", table.concat(Shop.paidList(w.shop), ",") == "")
end

do
	local w = world(3000, 4000)
	buy(w, "spectre")
	w.asked = "vandal"
	check(
		"a gun bought for them over one they bought sells theirs back to them",
		give(w, B, "vandal") and w.credits[A] == 3000 and w.credits[B] == 1100
	)
	check("and goes back to what the slot began with when sold", sell(w, "vandal") and w.slots["1"] == "" and w.credits[B] == 4000)
end

do
	local w = world(800, 4000)
	w.asked = "spectre"
	give(w, B, "spectre")
	w.asked = "vandal"
	check(
		"a gun bought over one another teammate bought sells that back to them",
		give(w, C, "vandal") and w.credits[B] == 4000 and w.credits[C] == 1100
	)
	check("and it's the second teammate's now", table.concat(Shop.paidList(w.shop), ",") == tostring(C))
end

do
	local w = world(800, 4000, "operator") -- an Operator kept from the last round
	w.asked = "vandal"
	give(w, B, "vandal")
	w.asked = "operator"
	check("nobody can buy them what they can buy back for nothing", not give(w, C, "operator") and w.credits[C] == 4000)
	local operator = Shop.item("operator") :: Shop.Item
	check("buying it back costs them nothing", Shop.cost(w.shop, operator) == 0)
	check("and gives the teammate their credits back", buy(w, "operator") and w.credits[A] == 800 and w.credits[B] == 4000)
end

do
	local w = world(800, 4000)
	w.asked = "vandal"
	give(w, B, "vandal")
	Shop.forget(w.shop, "1") -- dropped
	local owed = Shop.payback(w.shop, "1")
	check(
		"dropped, it's gone: nothing to sell back, and nothing back for anyone",
		owed == 0 and not sell(w, "vandal") and w.credits[B] == 1100
	)
end

do
	local w = world(800, 4000)
	w.asked = "vandal"
	give(w, B, "vandal")
	w.asked = "operator"
	check("not for more than the buyer has left", not give(w, B, "operator") and w.credits[B] == 1100 and w.slots["1"] == "vandal")
	Shop.reset(w.shop)
	check("a new buy phase forgets who paid", next(w.shop.paid) == nil)
end

do
	local s = Shop.new()
	local vandal, spectre = Shop.item("vandal") :: Shop.Item, Shop.item("spectre") :: Shop.Item
	check("a gun bought for someone who has it is nothing to do", not Shop.give(s, vandal, "vandal", B) and next(s.paid) == nil)
	Shop.buy(s, spectre, "vandal")
	check(
		"and one their slot began with goes back with nobody paying",
		Shop.give(s, vandal, "spectre", B) and next(s.paid) == nil and #Shop.boughtList(s) == 0
	)
end

do
	local copy = Shop.fromLists("vandal,heavy", ",light", tostring(B) .. ",")
	local phantom = Shop.item("phantom") :: Shop.Item
	check("a client's copy knows who paid for what", copy.paid["1"] == B and copy.paid.shield == nil)
	check("and so what another gun costs", Shop.cost(copy, phantom) == 2900)
	local old = Shop.fromLists("vandal", "")
	check("an older copy, without who paid, is all the player's own", next(old.paid) == nil and Shop.cost(old, phantom) == 0)
end

return nil
