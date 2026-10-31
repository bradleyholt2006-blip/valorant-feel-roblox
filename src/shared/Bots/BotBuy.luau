--!strict
-- What a bot buys as a buy phase opens in the spike rounds (system 60): a
-- plain economy, one bot at a time, each price WeaponConfig's.
--   * on the first round of a half everyone has the starting credits: a
--     Light Armor, or now and then a Ghost instead
--   * a survivor keeps the gun it holds, and buys a shield if it has none
--     (Heavy Armor if it can, else Light)
--   * with a rifle's and Heavy Armor's worth (3900 credits), a full buy:
--     a Vandal or a Phantom, and Heavy Armor; with less, but a rifle's and
--     Light Armor's worth, the rifle and Light Armor
--   * with a Spectre's and Light Armor's worth, those
--   * with less, it saves, keeping the Classic, for a full buy later
--
-- Which rounds to save and which to spend is the buyer's own here, not its
-- side's. What's left goes on its agent's abilities (system 66, toKeep):
-- all of it on a half's first round or once it holds a primary, and what's
-- past a full buy's worth while it's saving for one.

local BotConfig = require("./BotConfig")
local WeaponConfig = require("../Weapons/WeaponConfig")

local BotBuy = {}

-- What a bot has as the buy phase opens: its guns ("" for none) and the
-- shield it wears ("" for none, or one that's broken).
export type Has = { primary: string, sidearm: string, shield: string }

local function price(id: string): number
	local shield = WeaponConfig.Shields[id]
	if shield then
		return shield.price.value
	end
	return WeaponConfig.Defs[id].price.value
end
BotBuy.price = price

-- What to buy, in order, with `credits`: weapon and shield ids. `first`
-- is a half's first round.
function BotBuy.choose(credits: number, has: Has, first: boolean, dice: BotConfig.Dice): { string }
	local out: { string } = {}
	local left = credits
	local function buy(id: string): boolean
		local cost = price(id)
		if cost > left then
			return false
		end
		left -= cost
		table.insert(out, id)
		return true
	end
	local function shield()
		if has.shield ~= "heavy" and not buy("heavy") and has.shield == "" then
			buy("light")
		end
	end
	if first then
		if has.sidearm == "classic" and dice() < 0.3 then
			buy("ghost")
		elseif has.shield == "" then
			buy("light")
		end
		return out
	end
	if has.primary ~= "" then
		shield()
		return out
	end
	local rifle = if dice() < 0.5 then "vandal" else "phantom"
	if left >= price(rifle) + price("heavy") then
		buy(rifle)
		shield()
	elseif left >= price(rifle) + price("light") then
		buy(rifle)
		if has.shield == "" then
			buy("light")
		end
	elseif left >= price("spectre") + price("light") then
		buy("spectre")
		if has.shield == "" then
			buy("light")
		end
	end
	return out
end

-- The credits a bot keeps back from its abilities' charges, its guns and
-- shield bought (system 66): none on a half's first round (`first`) or
-- with a primary in hand, and a full buy's worth while it's saving.
function BotBuy.toKeep(first: boolean, primary: string): number
	if first or primary ~= "" then
		return 0
	end
	return price("vandal") + price("heavy")
end

return BotBuy
