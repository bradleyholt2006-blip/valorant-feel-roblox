--!strict
-- Shields and the buy menu's rules (system 9).

local Health = require("../src/shared/Combat/Health")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local Shop = require("../src/shared/Weapons/Shop")
local H = require("./Harness")

local check, near = H.check, H.near

H.section("Shield and buy menu tests")

-- Shields -------------------------------------------------------------------------

do
	local S = WeaponConfig.Shields
	local ids = WeaponConfig.ShieldIds
	check("three shields, cheapest first: Light Armor, the Regen Shield, Heavy Armor", #ids == 3 and ids[1] == "light" and ids[2] == "regen" and ids[3] == "heavy")
	check("Light 400 for 25, Regen 650 for 25, Heavy 1000 for 50", S.light.price.value == 400 and S.light.points.value == 25 and S.regen.price.value == 650 and S.regen.points.value == 25 and S.heavy.price.value == 1000 and S.heavy.points.value == 50)
	local regen = S.regen.regen
	check(
		"the Regen Shield's numbers are Riot's (Patch 9.10): 650, 25, every point of a hit, a pool of 50",
		S.regen.price.status == "confirmed" and S.regen.points.status == "confirmed" and S.regen.absorb.value == 1 and S.regen.absorb.status == "confirmed" and regen ~= nil and regen.pool.value == 50 and regen.pool.status == "confirmed"
	)
	check("everyone wears Heavy Armor until they pick another", WeaponConfig.DefaultShield == "heavy")
end

do
	local light = Health.new(100, "light")
	Health.apply(light, 26)
	check("Light Armor takes 66% of a Classic body shot: 91.16 health and 7.84 shield left (section 3's check)", near(light.health, 91.16, 1e-9) and near(light.shield, 7.84, 1e-9))

	local none = Health.new(100, "")
	local hit = Health.apply(none, 40)
	check("no shield: health takes it all", none.kind == "" and none.shield == 0 and hit.healthDamage == 40 and none.health == 60)
end

-- However a shield splits its hits, a hit takes exactly its damage off health
-- and shield together, so the shots to kill come out as if they simply added.
do
	local mismatches = {}
	local cases = 0
	for _, group in WeaponConfig.Arsenal do
		for _, id in group.ids do
			local def = WeaponConfig.get(id)
			for _, kind in { "", "light", "regen", "heavy" } do
				for _, region in { "head", "body", "legs" } do
					for _, distance in { 5, 10, 25, 40 } do
						local points = if kind == "" then 0 else WeaponConfig.Shields[kind].points.value
						local per = WeaponConfig.shotDamage(def, region :: any, distance)
						local hp = Health.new(100, kind)
						local shots = 0
						while hp.alive and shots < 100 do
							Health.apply(hp, per)
							shots += 1
						end
						cases += 1
						local expected = WeaponConfig.shotsToKill(def, region :: any, distance, 100 + points)
						if shots ~= expected then
							table.insert(mismatches, string.format("%s %s %s %d m: %d, not %s", id, kind, region, distance, shots, tostring(expected)))
						end
					end
				end
			end
		end
	end
	check(string.format("every gun, shield, region and range kills in the shots health + shield says (%d cases)", cases), #mismatches == 0, table.concat(mismatches, "; "))
end

do
	local s = Health.new(100, "regen")
	local DT = 1 / 60
	Health.apply(s, 20, 10)
	check("the Regen Shield takes every point of a hit while it lasts", s.shield == 5 and s.health == 100)

	local t = 10
	local function run(seconds: number)
		local steps = math.floor(seconds / DT + 0.5)
		for _ = 1, steps do
			t += DT
			Health.step(s, t, DT)
		end
	end
	run(2.9)
	check("it waits 3 s after a hit before refilling", s.shield == 5 and s.pool == 50)
	run(0.1 + 0.8)
	check("then it refills at 12.5 a second", near(s.shield, 15, 0.25), string.format("%.2f", s.shield))
	run(2)
	check("up to 25, and no further", s.shield == 25)
	check("taking what it refilled out of its pool", near(s.pool, 30, 1e-9), string.format("%.4f", s.pool))

	Health.apply(s, 25, t)
	run(2)
	check("a hit stops the refill and starts the wait again", s.shield == 0)
	run(1 + 2)
	check("after the wait it refills from the pool again", s.shield == 25 and near(s.pool, 5, 1e-9), string.format("%.2f, pool %.2f", s.shield, s.pool))
	Health.apply(s, 25, t)
	run(5)
	check("once the pool is empty it stays where it is", near(s.shield, 5, 1e-9) and s.pool == 0, string.format("%.2f, pool %.2f", s.shield, s.pool))

	Health.reset(s)
	check("a new life wears a fresh Regen Shield with a full pool", s.kind == "regen" and s.shield == 25 and s.pool == 50 and s.health == 100)

	local heavy = Health.new(100, "heavy")
	Health.apply(heavy, 40, 0)
	check("Heavy Armor never refills", not Health.step(heavy, 100, 1) and near(heavy.shield, 23.6, 1e-9))

	local dead = Health.new(100, "regen")
	Health.apply(dead, 200, 0)
	check("nor does anything once dead", not Health.step(dead, 100, 1) and dead.shield == 0)
end

-- The buy menu's rules --------------------------------------------------------------

do
	local onSale, wrong = 0, {}
	for _, group in WeaponConfig.Arsenal do
		for _, id in group.ids do
			local item = Shop.item(id)
			local def = WeaponConfig.get(id)
			onSale += 1
			if not item or item.kind ~= "weapon" or item.slot ~= tostring(def.slot) or item.price ~= def.price.value then
				table.insert(wrong, id)
			end
		end
	end
	check("every gun is on sale, in its slot, at its price", onSale == 20 and #wrong == 0, table.concat(wrong, ", "))
	check("the knife isn't: everyone has one", Shop.item("knife") == nil and Shop.item("nothing") == nil)
	local heavy = Shop.item("heavy")
	check("the shields are, in the shield slot", heavy ~= nil and heavy.kind == "shield" and heavy.slot == Shop.SHIELD and heavy.price == 1000)
end

do
	local s = Shop.new()
	local phantom = Shop.item("phantom") :: Shop.Item
	local operator = Shop.item("operator") :: Shop.Item
	local vandal = Shop.item("vandal") :: Shop.Item
	local light = Shop.item("light") :: Shop.Item
	local sheriff = Shop.item("sheriff") :: Shop.Item

	check("buying what you hold does nothing", not Shop.buy(s, vandal, "vandal") and #Shop.boughtList(s) == 0)
	check("buying another gun for the slot is a purchase", Shop.buy(s, phantom, "vandal") and Shop.boughtList(s)[1] == "phantom")
	check("a gun you didn't buy this buy phase can't be sold", Shop.sell(s, vandal) == nil)
	Shop.buy(s, operator, "phantom")
	check("selling the last gun bought puts back what the slot began the phase with", Shop.sell(s, operator) == "vandal" and #Shop.boughtList(s) == 0)
	check("and then there's nothing left to sell", Shop.sell(s, operator) == nil and Shop.sell(s, phantom) == nil)

	Shop.buy(s, phantom, "vandal")
	Shop.buy(s, vandal, "phantom")
	check("buying back what it began with leaves nothing bought", #Shop.boughtList(s) == 0 and Shop.sell(s, vandal) == nil)

	Shop.buy(s, light, "heavy")
	Shop.buy(s, sheriff, "classic")
	Shop.buy(s, phantom, "vandal")
	local list = Shop.boughtList(s)
	check("the list of what's been bought: primary, sidearm, shield", #list == 3 and list[1] == "phantom" and list[2] == "sheriff" and list[3] == "light")
	check("a shield sells back to the one worn before", Shop.sell(s, light) == "heavy")
	Shop.reset(s)
	check("a new buy phase forgets what was bought: nothing to sell", #Shop.boughtList(s) == 0 and Shop.sell(s, phantom) == nil and Shop.sell(s, sheriff) == nil)
end

return nil
