--!strict
-- Buying for teammates (system 57), in the spike rounds, where guns cost
-- credits. Right-click a gun in the buy menu and your team sees you asking
-- for it ('right-click on a weapon in the buy menu, and then your character
-- will request it', TechSpot), on your card in the team panel beside the
-- menu, with the credits each of them has. A teammate with enough buys it
-- for you from there ('Clicking on it automatically buys the weapon for
-- them and the price will be deducted from your credits', GamersDecide),
-- and it's yours as if you'd bought it: drawn, and sold back for their
-- refund (Shop). Each can tell the team their plan for the round on their
-- card too ('you can indicate if you'd like to save, buy, or offer to spend
-- your extra credits', Dignitas).
--
-- Ours: one request a player at a time, for a gun that costs something and
-- isn't theirs already or theirs to buy back for nothing; asking for the
-- same one again takes it back. A request lasts until it's bought, by
-- anyone, or the player's next life (the next round), as a plan does. Two
-- teammates buying the same request at once buy it once (the reference
-- fixed a bug 'after multiple players would fulfill a weapon buy request
-- at the same time', Patch 0.50): the second finds it gone.
--
-- Plain rules the offline tests can play: the server keeps each player's
-- request and plan (ShopServer) and puts them on the player as attributes,
-- which their team's buy menus show (BuyMenu). No Roblox APIs here.

local Shop = require("./Shop")

export type Plan = "save" | "buy" | "extra"

local TeamBuy = {}

-- Player attributes the server keeps up to date for clients: the gun a
-- player's asking their team for, and their plan for the round.
TeamBuy.REQUEST_ATTRIBUTE = "VFRequest"
TeamBuy.PLAN_ATTRIBUTE = "VFPlan"

-- The plans, in the order the panel's buttons show them, and what a card
-- says for each.
TeamBuy.PLANS = { "save", "buy", "extra" } :: { Plan }
TeamBuy.TITLES = {
	save = "SAVING",
	buy = "BUYING",
	extra = "EXTRA CREDITS",
} :: { [string]: string }

-- Whether `id` is a gun a player can ask their team for: one for sale that
-- costs something (the sources ask for guns alone; and not the free
-- Classic, ours).
function TeamBuy.askable(id: string): boolean
	local item = Shop.item(id)
	return item ~= nil and item.kind == "weapon" and item.price > 0
end

-- Whether a player can ask for (or be bought) `id` while its slot holds
-- `holding` (nil: they're not playing), the slot having begun the buy phase
-- with `before` if anything's been bought into it since: not a gun they
-- have, or can buy back for nothing.
function TeamBuy.canAsk(id: string, holding: string?, before: string?): boolean
	return TeamBuy.askable(id) and holding ~= nil and holding ~= id and before ~= id
end

-- A player's request once they ask for `id`, `current` being what they'd
-- asked for: `id`, or none if they'd asked for it already or it's "" (to
-- take it back).
function TeamBuy.ask(current: string?, id: string): string?
	if id == "" or id == current then
		return nil
	end
	return id
end

-- A player's plan once they pick `plan`, `current` being the one they'd
-- picked: it, or none if they'd picked it already or it's "", and
-- `current` still for anything that isn't a plan.
function TeamBuy.plan(current: string?, plan: string): string?
	if plan == "" or plan == current then
		return nil
	end
	return if TeamBuy.TITLES[plan] then plan else current
end

-- A teammate's request, as someone means to buy it for them.
export type Offer = {
	id: string, -- the gun the buyer means to buy
	asked: string?, -- what the teammate's asking for now
	same: boolean, -- whether the buyer is the one asking
	buyerSide: number?, -- the buyer's side, where teammates buy for each other
	askerSide: number?, -- the teammate's
	holding: string?, -- what the teammate's slot for it holds (nil: not playing)
	before: string?, -- what that slot began the buy phase with, if it's been bought into since
	credits: number?, -- the buyer's, where it's for the caller to check them
}

export type Refusal = "team" | "asked" | "has" | "short"

-- Why the request can't be bought for them now, or nil when it can: not a
-- teammate, not what they're asking for (any more), a gun they have now, or
-- more than the buyer's credits.
function TeamBuy.refusal(o: Offer): Refusal?
	if o.same or o.buyerSide == nil or o.buyerSide ~= o.askerSide then
		return "team"
	elseif o.asked == nil or o.asked ~= o.id or not TeamBuy.askable(o.id) then
		return "asked"
	elseif not TeamBuy.canAsk(o.id, o.holding, o.before) then
		return "has"
	end
	local item = Shop.item(o.id)
	if o.credits and item and o.credits < item.price then
		return "short"
	end
	return nil
end

return TeamBuy
