--!strict
-- The economy (system 14): what each round pays, the loss streak, the
-- survivors of a lost round, kills, the plant, the cap, the halves and
-- overtime, Swiftplay's schedule, spending and refunds, what a purchase
-- costs in the buy menu, and the shield a survivor keeps.

local MatchConfig = require("../src/shared/Match/MatchConfig")
local MatchRules = require("../src/shared/Match/MatchRules")
local Shop = require("../src/shared/Weapons/Shop")
local Health = require("../src/shared/Combat/Health")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local H = require("./Harness")

local check = H.check

local C = MatchConfig.Credits
local STANDARD = MatchConfig.Formats.standard
local SWIFTPLAY = MatchConfig.Formats.swiftplay
local WIN, SURVIVED, KILL, PLANT, CAP = C.win.value, C.survived.value, C.kill.value, C.plant.value, C.cap.value
local LOSS = { C.loss[1].value, C.loss[2].value, C.loss[3].value }

-- A 1v1 match, player 1 on side 1 and player 2 on side 2, at round 1's buy
-- phase.
local function oneVsOne(format: string?): MatchRules.State
	local s = MatchRules.new(format)
	MatchRules.join(s, 1, 0)
	MatchRules.join(s, 2, 0)
	return s
end

local function credits(s: MatchRules.State, id: number): number
	return MatchRules.credits(s, id) or -1
end

-- Sets someone's credits, by spending, for checks that need a known amount.
local function setCredits(s: MatchRules.State, id: number, amount: number)
	MatchRules.spend(s, id, credits(s, id) - amount)
end

-- Ends the buy phase of the round under way.
local function goLive(s: MatchRules.State)
	if s.phase == "buy" then
		MatchRules.step(s, s.phaseEndsAt)
	end
end

-- Moves on from the round's end to the next round's buy phase.
local function nextRound(s: MatchRules.State)
	if s.phase == "roundOver" or s.phase == "matchOver" then
		MatchRules.step(s, s.phaseEndsAt)
	end
end

-- Plays the round under way to its end with `winner`'s player killing the
-- other's (1v1), and starts the next.
local function win(s: MatchRules.State, winner: number)
	goLive(s)
	MatchRules.died(s, 3 - winner, s.phaseEndsAt - 50, winner)
	nextRound(s)
end

H.section("Economy tests")

-- What a round pays ----------------------------------------------------------

do
	local s = MatchRules.new()
	MatchRules.join(s, 1, 0)
	check("you join with the starting credits", credits(s, 1) == C.start.value and C.start.value == 800)
	MatchRules.join(s, 2, 0)
	check("and round 1 starts everyone on them", s.round == 1 and credits(s, 1) == 800 and credits(s, 2) == 800)

	goLive(s)
	MatchRules.died(s, 2, 60, 1)
	check("a kill pays the killer as it happens", credits(s, 1) == 800 + KILL and credits(s, 2) == 800)
	nextRound(s)
	check(
		"the next round pays the winners a win and the losers a loss, as it starts",
		s.round == 2 and credits(s, 1) == 800 + KILL + WIN and credits(s, 2) == 800 + LOSS[1]
	)
	check("and the losers have lost one in a row", s.streak[1] == 0 and s.streak[2] == 1)

	setCredits(s, 2, 0)
	win(s, 1)
	check("a second loss in a row pays more", credits(s, 2) == LOSS[2] and s.streak[2] == 2)
	setCredits(s, 2, 0)
	win(s, 1)
	check("a third more again", credits(s, 2) == LOSS[3] and s.streak[2] == 3)
	setCredits(s, 2, 0)
	win(s, 1)
	check("and no more after that", credits(s, 2) == LOSS[3] and s.streak[2] == 4)
	check("nobody holds more than the cap", credits(s, 1) == CAP)

	setCredits(s, 2, 0)
	win(s, 2)
	check("a win resets the winners' streak and starts the losers'", credits(s, 2) == KILL + WIN and s.streak[2] == 0 and s.streak[1] == 1)
	setCredits(s, 2, 0)
	win(s, 1)
	check("so the next loss pays the first loss's credits again", credits(s, 2) == LOSS[1])
end

do
	check(
		"1900, 2400 and 2900 for losses in a row, 3000 for a win, 1000 for a loss survived, 200 a kill, 300 a plant, 9000 at most",
		LOSS[1] == 1900
			and LOSS[2] == 2400
			and LOSS[3] == 2900
			and WIN == 3000
			and SURVIVED == 1000
			and KILL == 200
			and PLANT == 300
			and CAP == 9000
	)
	local pay = MatchRules.payout(STANDARD, 1, 0)
	check("payout tells a round's stakes: round 1, a win or a first loss", pay ~= nil and pay.won == WIN and pay.lost == LOSS[1])
	pay = MatchRules.payout(STANDARD, 5, 7)
	check("with a long streak, the most a loss pays", pay ~= nil and pay.lost == LOSS[3])
	check("the last round of each half pays nothing: the next starts over", MatchRules.payout(STANDARD, 12, 0) == nil)
	check(
		"nor does the last of regulation, or any in overtime",
		MatchRules.payout(STANDARD, 24, 0) == nil and MatchRules.payout(MatchConfig.Formats.competitive, 25, 0) == nil
	)
end

-- The survivors of a lost round -----------------------------------------------

do
	-- Round 1: player 1 attacks.
	local s = oneVsOne()
	goLive(s)
	MatchRules.step(s, s.phaseEndsAt)
	check("the clock runs out with no plant: the defenders win", s.roundWinner == 2 and s.reason == "time")
	nextRound(s)
	check("an attacker who survives it without a plant gets the survivor's credits, not a loss", credits(s, 1) == 800 + SURVIVED)
	check("which still counts as a loss in a row", s.streak[1] == 1)

	s = oneVsOne()
	goLive(s)
	MatchRules.planted(s, s.phaseEndsAt - 10)
	check("a plant pays the attackers as it happens", credits(s, 1) == 800 + PLANT and credits(s, 2) == 800)
	MatchRules.defused(s, s.phaseEndsAt - 20)
	nextRound(s)
	check("an attacker who survives a defuse, having planted, gets a full loss", credits(s, 1) == 800 + PLANT + LOSS[1])

	s = oneVsOne()
	goLive(s)
	MatchRules.planted(s, s.phaseEndsAt - 10)
	MatchRules.detonated(s, s.phaseEndsAt)
	nextRound(s)
	check(
		"a defender who survives the spike going off gets the survivor's credits; the attackers a plant and a win",
		credits(s, 2) == 800 + SURVIVED and credits(s, 1) == 800 + PLANT + WIN
	)

	s = oneVsOne()
	goLive(s)
	MatchRules.planted(s, s.phaseEndsAt - 10)
	MatchRules.detonated(s, s.phaseEndsAt)
	MatchRules.died(s, 2, s.phaseEndsAt - 1) -- the blast
	nextRound(s)
	check("one killed by the blast didn't survive it: a full loss", credits(s, 2) == 800 + LOSS[1])

	s = oneVsOne()
	goLive(s)
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.died(s, 1, s.phaseEndsAt - 1, 2)
	nextRound(s)
	check(
		"an attacker hunted down after the clock ran out didn't survive it, and the kill pays nothing",
		credits(s, 1) == 800 + LOSS[1] and credits(s, 2) == 800 + WIN
	)
end

-- Kills and the plant, 2v2 --------------------------------------------------------

do
	local s = MatchRules.new()
	for id = 1, 4 do
		MatchRules.join(s, id, 0)
	end
	-- Players 1 and 3 on side 1, 2 and 4 on side 2.
	check(
		"2v2: two to a side",
		MatchRules.sideOf(s, 1) == 1 and MatchRules.sideOf(s, 3) == 1 and MatchRules.sideOf(s, 2) == 2 and MatchRules.sideOf(s, 4) == 2
	)
	goLive(s)
	MatchRules.died(s, 3, 50, 1)
	check("killing a teammate pays nothing", credits(s, 1) == 800)
	MatchRules.planted(s, 100)
	check(
		"a plant pays every attacker, dead or alive",
		credits(s, 1) == 800 + PLANT and credits(s, 3) == 800 + PLANT and credits(s, 2) == 800
	)
	MatchRules.died(s, 2, 51, 1)
	check(
		"killing an enemy pays the killer alone",
		credits(s, 1) == 800 + PLANT + KILL and credits(s, 3) == 800 + PLANT and credits(s, 2) == 800
	)
	MatchRules.died(s, 4, 60)
	check("a death with nobody to credit pays nobody", credits(s, 1) == 800 + PLANT + KILL and s.roundWinner == 1)

	s = oneVsOne()
	MatchRules.died(s, 2, 10, 1)
	check("a kill in the buy phase pays nothing", credits(s, 1) == 800)
end

-- Halves and overtime ----------------------------------------------------------------

do
	local s = oneVsOne()
	for _ = 1, 12 do
		win(s, if s.round % 2 == 1 then 1 else 2)
	end
	check(
		"the second half starts everyone over on the starting credits, with no streak",
		s.round == 13 and credits(s, 1) == 800 and credits(s, 2) == 800 and s.streak[1] == 0 and s.streak[2] == 0
	)
	win(s, 1)
	check("and its second round pays as the first half's did", credits(s, 1) == 800 + KILL + WIN and credits(s, 2) == 800 + LOSS[1])
	for _ = 14, 24 do
		win(s, if s.round % 2 == 1 then 1 else 2)
	end
	check("12-12: the Endgame round", s.round == 25 and s.score[1] == 12 and s.score[2] == 12)
	check("starts everyone on overtime's credits", credits(s, 1) == C.overtime.value and credits(s, 2) == 5000)
	MatchRules.join(s, 3, 0)
	check("and anyone joining in it", credits(s, 3) == 5000)

	s = oneVsOne("competitive")
	for _ = 1, 24 do
		win(s, if s.round % 2 == 1 then 1 else 2)
	end
	setCredits(s, 1, 0)
	win(s, 1)
	check(
		"Competitive's overtime starts every round on overtime's credits, whatever the last paid",
		s.round == 26 and credits(s, 1) == 5000 and credits(s, 2) == 5000
	)
end

do
	local s = oneVsOne()
	MatchRules.join(s, 3, 0)
	check("someone joining mid-match starts on the starting credits", credits(s, 3) == 800)
	win(s, 1)
	win(s, 1)
	MatchRules.leave(s, 2, 0)
	MatchRules.leave(s, 3, 0)
	check("a side emptied: waiting, the credits kept", s.phase == "waiting" and credits(s, 1) > 800)
	local before = credits(s, 1)
	MatchRules.join(s, 4, 0)
	check("the next round after a wait pays nothing for the round cut short", s.phase == "buy" and credits(s, 1) == before)
end

-- Swiftplay ----------------------------------------------------------------------------

do
	local s = oneVsOne("swiftplay")
	check("Swiftplay starts on the starting credits", credits(s, 1) == 800)
	setCredits(s, 2, 0)
	goLive(s)
	MatchRules.died(s, 2, 60, 1)
	check("its kills pay too", credits(s, 1) == 800 + KILL)
	nextRound(s)
	check(
		"its round 2 pays both sides 2400, and the side that won round 1 600 more",
		credits(s, 2) == 2400 and credits(s, 1) == 800 + KILL + 2400 + 600
	)
	setCredits(s, 1, 0)
	setCredits(s, 2, 0)
	win(s, 1)
	check("round 3 pays 4250, win or lose", credits(s, 1) == 4250 + KILL and credits(s, 2) == 4250)
	setCredits(s, 1, 0)
	setCredits(s, 2, 0)
	win(s, 1)
	check("and so does round 4, with no loss streak", credits(s, 1) == 4250 + KILL and credits(s, 2) == 4250 and s.streak[2] == 0)
	win(s, 2)
	check("its second half starts over", s.round == 5 and credits(s, 1) == 800 and credits(s, 2) == 800)
	local pay = MatchRules.payout(SWIFTPLAY, 5, 0)
	check("payout tells Swiftplay's stakes: after round 5, 3000 won and 2400 lost", pay ~= nil and pay.won == 3000 and pay.lost == 2400)
	pay = MatchRules.payout(SWIFTPLAY, 6, 3)
	check("and after round 6, 4250 either way", pay ~= nil and pay.won == 4250 and pay.lost == 4250)
	-- 3-1 so far: 4-4 after round 8.
	win(s, 1)
	win(s, 2)
	win(s, 2)
	win(s, 2)
	check(
		"4-4: its Endgame starts everyone on overtime's credits",
		s.round == 9
			and s.score[1] == 4
			and s.score[2] == 4
			and MatchRules.overtime(SWIFTPLAY, 9)
			and credits(s, 1) == 5000
			and credits(s, 2) == 5000
	)
end

-- Spending -------------------------------------------------------------------------------

do
	local s = oneVsOne()
	local version = s.version
	check("you can spend what you have", MatchRules.spend(s, 1, 500) and credits(s, 1) == 300 and s.version > version)
	check("not more", not MatchRules.spend(s, 1, 400) and credits(s, 1) == 300)
	check("a refund gives it back", MatchRules.spend(s, 1, -500) and credits(s, 1) == 800)
	check("and something free costs nothing", MatchRules.spend(s, 1, 0) and credits(s, 1) == 800)
	check("someone not playing has nothing to spend", not MatchRules.spend(s, 9, 0) and MatchRules.credits(s, 9) == nil)
end

-- What a purchase costs ---------------------------------------------------------------

do
	local s = Shop.new()
	local spectre = Shop.item("spectre") :: Shop.Item
	local vandal = Shop.item("vandal") :: Shop.Item
	local operator = Shop.item("operator") :: Shop.Item
	local sheriff = Shop.item("sheriff") :: Shop.Item
	local classic = Shop.item("classic") :: Shop.Item
	local light = Shop.item("light") :: Shop.Item
	local heavy = Shop.item("heavy") :: Shop.Item

	check("a gun for an empty slot costs its price", Shop.cost(s, spectre) == 1600)
	Shop.buy(s, spectre, "")
	check("another for the slot costs the difference: the first goes back", Shop.cost(s, vandal) == 2900 - 1600)
	Shop.buy(s, vandal, "spectre")
	check("selling it back refunds its price, for what the slot began with", Shop.refund(s, vandal) == 2900 and Shop.sell(s, vandal) == "")
	check("what wasn't bought this buy phase refunds nothing", Shop.refund(s, operator) == 0)

	Shop.reset(s)
	Shop.buy(s, spectre, "operator") -- an Operator kept from the last round
	check("buying back what the slot began with refunds what replaced it", Shop.cost(s, operator) == -1600)
	Shop.buy(s, operator, "spectre")
	check("and leaves nothing bought", #Shop.boughtList(s) == 0)

	Shop.reset(s)
	check("the Classic is free", Shop.cost(s, classic) == 0)
	Shop.buy(s, classic, "sheriff") -- a Sheriff kept from the last round
	check(
		"and sells back for the Sheriff it replaced, refunding nothing",
		Shop.refund(s, classic) == 0 and Shop.sell(s, classic) == "sheriff"
	)
	Shop.buy(s, sheriff, "classic")
	check("a cheaper gun over a dearer one bought this phase is a refund", Shop.cost(s, Shop.item("ghost") :: Shop.Item) == 500 - 800)

	Shop.reset(s)
	check("a damaged shield bought again: a fresh one, at its price", Shop.cost(s, light) == 400 and Shop.renew(s, light))
	check("which sells back for the damaged one, refunding its price", Shop.refund(s, light) == 400)
	check("another shield over it costs the difference", Shop.cost(s, heavy) == 1000 - 400)
	check("and only once a buy phase", not Shop.renew(s, light))
	Shop.buy(s, heavy, "light")
	check("going back to the damaged one refunds what replaced it", Shop.cost(s, light) == -1000)
	check("and sells back to it", Shop.sell(s, heavy) == "light")
end

do
	local s = Shop.new()
	Shop.buy(s, Shop.item("vandal") :: Shop.Item, "")
	Shop.buy(s, Shop.item("heavy") :: Shop.Item, "light")
	local bought = table.concat(Shop.boughtList(s), ",")
	local before = table.concat(Shop.beforeList(s), ",")
	check(
		"clients are told what was bought and what it replaced, an empty slot as nothing",
		bought == "vandal,heavy" and before == ",light"
	)
	local copy = Shop.fromLists(bought, before)
	local same = true
	for id in WeaponConfig.Defs do
		local item = Shop.item(id)
		if item and Shop.cost(copy, item) ~= Shop.cost(s, item) then
			same = false
		end
	end
	for _, id in WeaponConfig.ShieldIds do
		local item = Shop.item(id) :: Shop.Item
		same = same and Shop.cost(copy, item) == Shop.cost(s, item) and Shop.refund(copy, item) == Shop.refund(s, item)
	end
	check("and their copy prices everything as the server does", same)
	check(
		"nothing bought, nothing to copy",
		#Shop.boughtList(Shop.fromLists("", "")) == 0 and #Shop.boughtList(Shop.fromLists(nil, nil)) == 0
	)
end

-- The shield a survivor keeps -------------------------------------------------------

do
	local h = Health.new(100, "light")
	Health.apply(h, 30, 1) -- about two thirds to the shield
	local kept = Health.keep(h)
	Health.reset(h)
	check("a new life puts on a fresh shield", h.shield == 25)
	Health.restore(h, kept)
	check(
		"a survivor's goes back as it was, with full health",
		h.shield == kept.shield and h.shield > 0 and h.shield < 10 and h.health == 100 and h.kind == "light"
	)

	local r = Health.new(100, "regen")
	Health.apply(r, 25, 1)
	Health.step(r, 10, 1) -- 3 s on: 12.5 back from the pool
	local keptRegen = Health.keep(r)
	Health.reset(r)
	Health.restore(r, keptRegen)
	check("a Regen Shield's pool carries over, as drained as it was", H.near(r.pool, 50 - 12.5, 1e-6) and H.near(r.shield, 12.5, 1e-6))
	Health.setShield(r, "regen")
	Health.restore(r, { shield = 80, pool = 99 })
	check("never above what a fresh one holds", r.shield == 25 and r.pool == 50)
end

-- A gun sold back to an empty slot ------------------------------------------------------

do
	local w = WeaponSim.newState({ "vandal", "classic", "knife", "" })
	check("the primary in hand", w.equipped == 1)
	WeaponSim.give(w, 1, "", 5)
	check(
		"emptied, the hand moves to the next slot with something in it, drawn",
		w.loadout[1] == "" and w.equipped == 2 and w.equipEndTime > 5
	)
	WeaponSim.give(w, 1, "spectre", 6)
	check("a gun put in another slot leaves the one in hand", w.equipped == 2)
end

do
	local okLabels = true
	local statuses = { confirmed = true, community = true, estimate = true }
	local function param(name: string, v: any)
		if type(v) ~= "table" or type(v.value) ~= "number" or not statuses[v.status] or type(v.source) ~= "string" or v.source == "" then
			okLabels = false
			print("    missing or unlabelled: " .. name)
		end
	end
	for key, v in (C :: any) :: { [string]: any } do
		if key == "loss" then
			for i, step in v do
				param("Credits.loss[" .. i .. "]", step)
			end
		else
			param("Credits." .. key, v)
		end
	end
	for round, step in MatchConfig.Swiftplay do
		param("Swiftplay[" .. round .. "].all", step.all)
		if step.won then
			param("Swiftplay[" .. round .. "].won", step.won)
		end
	end
	check("every credit has a status and a source", okLabels)
	local economies = true
	for _, format in MatchConfig.Formats do
		economies = economies and (format.economy == "standard" or format.economy == "swiftplay")
	end
	check("every format says how it pays", economies and SWIFTPLAY.economy == "swiftplay" and STANDARD.economy == "standard")
end

return nil
