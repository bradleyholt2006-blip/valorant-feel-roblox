--!strict
-- Taking over a bot after dying (system 62): when the rules let it (in a
-- round, in the formats that have it, a fallen player and a living
-- teammate), what it changes (alive in its place, it down with no death,
-- each side as many alive, the hurts and the assists, the round played,
-- the round's end), the callouts, when the client offers it, and the kit a
-- body's taken over on, from the bot's simulation to the text its new
-- character carries and the new life's weapons, the same on the server
-- and the client.

local ArenaRules = require("../src/shared/Arena/ArenaRules")
local BotTakeover = require("../src/shared/Bots/BotTakeover")
local MatchConfig = require("../src/shared/Match/MatchConfig")
local MatchRules = require("../src/shared/Match/MatchRules")
local Roster = require("../src/shared/Match/Roster")
local RoundCallouts = require("../src/shared/Match/RoundCallouts")
local PlayerSim = require("../src/shared/PlayerSim")
local Spike = require("../src/shared/Spike/Spike")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local H = require("./Harness")

local check = H.check

H.section("Taking over a bot (system 62)")

-- The formats ------------------------------------------------------------------------------------

do
	local F = MatchConfig.Formats
	check(
		"the standard format and Swiftplay's have it, Competitive's doesn't",
		F.standard.takeOver and F.swiftplay.takeOver and not F.competitive.takeOver
	)
end

-- The spike rounds' rules ----------------------------------------------------------------------

-- A match with 1, 3 and 5 on side 1 and 2, 4 and 6 on side 2 (each joins
-- the side with fewer), its round live.
local function live(format: string?): MatchRules.State
	local s = MatchRules.new(format)
	for id = 1, 6 do
		MatchRules.join(s, id, 0)
	end
	MatchRules.step(s, s.phaseEndsAt)
	return s
end

do
	local s = MatchRules.new()
	for id = 1, 6 do
		MatchRules.join(s, id, 0)
	end
	MatchRules.died(s, 1, 1)
	check("nobody takes over in the buy phase", not MatchRules.canTakeOver(s, 1, 3))
end

do
	local s = live()
	check("in the round, nobody alive takes over", not MatchRules.canTakeOver(s, 1, 3))
	MatchRules.died(s, 1, 50, 2)
	check("a fallen player can take over a teammate", MatchRules.canTakeOver(s, 1, 3))
	check(
		"not an enemy, not themselves, and nobody alive the fallen",
		not MatchRules.canTakeOver(s, 1, 2) and not MatchRules.canTakeOver(s, 1, 1) and not MatchRules.canTakeOver(s, 3, 1)
	)
	local before = s.version
	local alive = Roster.count(s, 1, true)
	check("taking over says so", MatchRules.tookOver(s, 1, 3))
	check("they're alive in its place, and it's down", s.members[1].alive and not s.members[3].alive)
	check("their side has as many alive as before", Roster.count(s, 1, true) == alive)
	check("no death for it, and theirs as it was", s.members[3].deaths == 0 and s.members[1].deaths == 1)
	check("the round goes on, and clients are told", s.phase == "live" and s.version > before)
	check("it can't be taken twice", not MatchRules.tookOver(s, 1, 3) and not MatchRules.canTakeOver(s, 5, 3))
	MatchRules.died(s, 1, 60, 2)
	MatchRules.died(s, 5, 61, 2)
	check("with the rest down, the round's over: the one taken over holds nothing open", s.phase == "roundOver" and s.roundWinner == 2)
	check("the round over, nobody takes over", not MatchRules.canTakeOver(s, 1, 3))
end

do
	-- The hurts of the life taken over: an enemy who damaged it assists in
	-- the kill of whoever took it over.
	local s = live()
	MatchRules.damaged(s, 2, 3, 60)
	MatchRules.died(s, 1, 50, 4)
	MatchRules.tookOver(s, 1, 3)
	MatchRules.died(s, 1, 55, 4)
	check(
		"an enemy who hurt the body assists in its taker's death",
		s.members[2].assists == 1 and s.members[4].kills == 2 and s.members[1].deaths == 2
	)
	check("and the body's own hurts are gone with it", s.hurt[3] == nil)
end

do
	local s = live()
	MatchRules.died(s, 1, 50, 2)
	MatchRules.planted(s, 100)
	check("with the spike planted, still", MatchRules.canTakeOver(s, 1, 3) and MatchRules.tookOver(s, 1, 3))
end

do
	local s = live("competitive")
	MatchRules.died(s, 1, 50, 2)
	check("not in Competitive", not MatchRules.canTakeOver(s, 1, 3) and not MatchRules.tookOver(s, 1, 3))
	local t = live("swiftplay")
	MatchRules.died(t, 1, 50, 2)
	check("but in Swiftplay", MatchRules.tookOver(t, 1, 3))
end

do
	-- Someone who joined the round under way waits for the next, but can
	-- take over a teammate now, and has played in it then.
	local s = live()
	MatchRules.join(s, 7, 30)
	local joiner = s.members[7]
	check("a joiner under way is down, and not in the round", joiner ~= nil and not joiner.alive and not joiner.played)
	local mate = if joiner and joiner.side == 1 then 3 else 4
	check("they take over a teammate, and have played in it", MatchRules.tookOver(s, 7, mate) and joiner.alive and joiner.played)
end

-- Skirmish's rules -------------------------------------------------------------------------------

do
	local s = ArenaRules.new()
	for id = 1, 4 do
		ArenaRules.join(s, id, 0)
	end
	ArenaRules.died(s, 1, 1)
	check("Skirmish: not in the buy phase", not ArenaRules.canTakeOver(s, 1, 3))
	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.died(s, 1, 30, 2)
	check(
		"but a fallen player takes over a teammate in the round",
		not ArenaRules.canTakeOver(s, 1, 2) and ArenaRules.tookOver(s, 1, 3) and s.members[1].alive and not s.members[3].alive
	)
	ArenaRules.died(s, 1, 40, 2)
	check("and with them down, the round's over", s.phase == "roundOver" and s.roundWinner == 2)
end

-- The callouts ---------------------------------------------------------------------------------

do
	-- A and the bot on side 1, X and Y on side 2.
	local A, BOT, X, Y = 1, -5, 11, 12
	local r = RoundCallouts.begin({ [A] = 1, [BOT] = 1, [X] = 2, [Y] = 2 }, nil)
	RoundCallouts.died(r, A, X)
	RoundCallouts.tookOver(r, A, BOT)
	check("a taker's alive in the round in its place, and it's out", r.alive[A] and r.sides[BOT] == nil)
	RoundCallouts.died(r, X, A)
	RoundCallouts.died(r, Y, A)
	check("the taker's kills are theirs: every enemy, an ace", RoundCallouts.decide(r, 1) == "ace")
	RoundCallouts.tookOver(r, Y, X)
	check("nobody alive takes over, nor anyone a fallen one", r.alive[Y] == false and r.sides[X] == 2)
end

do
	local J, BOT, X = 7, -5, 11
	local r = RoundCallouts.begin({ [BOT] = 1, [X] = 2 }, { [BOT] = 3900, [X] = 800 })
	RoundCallouts.tookOver(r, J, BOT)
	local worth = r.worth or {}
	check("a joiner taking over is in the round on its side, at its worth", r.sides[J] == 1 and r.alive[J] and worth[J] == 3900)
end

-- What the client offers ------------------------------------------------------------------------

do
	local open = BotTakeover.open
	check("Skirmish, while its round's played", open("skirmish", nil, "live") and not open("skirmish", nil, "buy"))
	check(
		"the spike rounds while one's played, planted too",
		open("spike", "standard", "live") and open("spike", "standard", "planted") and open("spike", "swiftplay", "live")
	)
	check(
		"not in a buy phase or after, nor in Competitive",
		not open("spike", "standard", "buy") and not open("spike", "standard", "roundOver") and not open("spike", "competitive", "live")
	)
	check(
		"nor in the modes that respawn, or none",
		not open("gungame", nil, "live")
			and not open("deathmatch", nil, "live")
			and not open("teamdeathmatch", nil, "live")
			and not open(nil, nil, nil)
			and not open("spike", "nonsense", "live")
	)
end

-- The kit --------------------------------------------------------------------------------------

do
	-- A bot's guns as it's taken over: some rounds fired from the Vandal,
	-- the Sheriff in hand, the spike carried.
	local w = WeaponSim.newState({ "vandal", "sheriff", "knife", Spike.ID })
	w.ammo[1], w.reserve[1] = 7, 40
	w.ammo[2] = 3
	w.equipped = 2
	local kit = BotTakeover.kitOf(w)
	local text = BotTakeover.kitText(kit)
	check("its kit as text", text == "vandal:7:40,sheriff:3:24,knife:0:0,spike:0:0;2", text)
	local back = BotTakeover.readKit(text)
	local same = back ~= nil and back.equipped == 2
	for slot = 1, BotTakeover.SLOTS do
		same = same
			and back ~= nil
			and back.loadout[slot] == kit.loadout[slot]
			and back.ammo[slot] == kit.ammo[slot]
			and back.reserve[slot] == kit.reserve[slot]
	end
	check("and back, the same", same)
	check(
		"an empty slot's nothing",
		BotTakeover.kitText({ loadout = { "", "classic", "knife", "" }, ammo = { 0, 12, 0, 0 }, reserve = { 0, 36, 0, 0 }, equipped = 2 })
			== ",classic:12:36,knife:0:0,;2"
	)
	local bad = { "", ";1", ",,,", "vandal:1:2,,,;", ",,;1", ",,,,;1", "ak47:1:2,,,;1", "vandal:-1:2,,,;1", "vandal:1,,,;1" }
	local none = BotTakeover.readKit(nil) == nil and BotTakeover.readKit(5) == nil
	for _, t in bad do
		none = none and BotTakeover.readKit(t) == nil
	end
	check("anything else isn't a kit", none)

	-- The new life's weapons: the server's, the spike left out and then
	-- handed over by SpikeServer, and the client's, from the text.
	local strip = table.clone(kit.loadout)
	strip[Spike.SLOT] = ""
	local server = PlayerSim.new(vector.zero, strip, 1).weapons
	BotTakeover.arm(server, kit)
	WeaponSim.give(server, Spike.SLOT, Spike.ID)
	local told = BotTakeover.readKit(text) :: BotTakeover.Kit
	local client = PlayerSim.new(vector.zero, told.loadout).weapons
	BotTakeover.arm(client, told)
	local alike = server.equipped == 2 and client.equipped == 2 and server.equipEndTime == 0 and client.equipEndTime == 0
	for slot = 1, WeaponSim.SLOTS do
		alike = alike
			and server.loadout[slot] == client.loadout[slot]
			and server.ammo[slot] == client.ammo[slot]
			and server.reserve[slot] == client.reserve[slot]
	end
	check("on the bot's rounds, its gun in hand and drawn, the same on the server and the client", alike and server.ammo[1] == 7)

	-- The spike in hand (a plant under way) is the primary in hand instead.
	local planting = BotTakeover.kitOf(WeaponSim.newState({ "vandal", "classic", "knife", Spike.ID }))
	planting.equipped = Spike.SLOT
	local hands = PlayerSim.new(vector.zero, planting.loadout).weapons
	BotTakeover.arm(hands, planting)
	check("the spike in its hand, the primary's in the new one's", hands.equipped == 1)
end

return nil
