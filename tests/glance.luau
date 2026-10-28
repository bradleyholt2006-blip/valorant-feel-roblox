--!strict
-- Each player's agent and ultimate at a glance (system 51): the ultimate as
-- the attribute every client reads carries it (Glance.ultimate), what the
-- scoreboard's ULT shows of it (Glance.cell) and whether the top bar's
-- diamond is lit (Glance.ready), each tile's and row's agent (Glance.badge),
-- how full a health bar is, and the tiles as scripted checks read them.

local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local Glance = require("../src/shared/Abilities/Glance")
local H = require("./Harness")

local check = H.check

H.section("Agents and ultimates at a glance (system 51)")

-- The ultimate, as the attribute carries it -----------------------------------

do
	local k = AbilitySim.new("jett")
	check("a kit with none of its points: 0/8", Glance.ultimate(k) == "0/8", Glance.ultimate(k))
	k.points = 3
	check("three of Blade Storm's eight: 3/8", Glance.ultimate(k) == "3/8", Glance.ultimate(k))
	k.points = 8
	check("every point: 8/8", Glance.ultimate(k) == "8/8", Glance.ultimate(k))
	k.points = 11
	check("never more than it needs", Glance.ultimate(k) == "8/8", Glance.ultimate(k))
	local sage = AbilitySim.new("sage")
	check("Resurrection needs 7 (Patch 9.10)", Glance.ultimate(sage) == "0/7", Glance.ultimate(sage))
	-- A mode's own cost (Team Deathmatch's, system 28).
	local sova = AbilitySim.new("sova")
	sova.need = AbilityConfig.TeamDeathmatch.ultimate.huntersfury.value
	sova.points = 30
	check("Team Deathmatch's own costs: 30/70 for Hunter's Fury", Glance.ultimate(sova) == "30/70", Glance.ultimate(sova))
	local none = AbilitySim.new(AbilityConfig.NO_AGENT)
	check("no agent's kit (deathmatch) has nothing to show", Glance.ultimate(none) == "", Glance.ultimate(none))
end

-- What's read back from it -------------------------------------------------------

do
	local points, needed = Glance.read("3/8")
	check("3/8 reads as 3 of 8", points == 3 and needed == 8)
	points, needed = Glance.read("")
	check("nothing reads as none of none", points == 0 and needed == 0)
	points, needed = Glance.read(nil)
	check("no attribute at all reads the same", points == 0 and needed == 0)
	points, needed = Glance.read("X3/8")
	check("nor does anything that isn't the attribute's", points == 0 and needed == 0)
	points, needed = Glance.read(38)
	check("nor a number", points == 0 and needed == 0)

	check("ready with every point: 8/8", Glance.ready("8/8"))
	check("not one short: 7/8", not Glance.ready("7/8"))
	check("not with nothing to charge", not Glance.ready("") and not Glance.ready(nil))
	check("the scoreboard's ULT shows how far along it is: 3/8", Glance.cell("3/8") == "3/8")
	check("and READY once it's full", Glance.cell("7/7") == Glance.READY and Glance.READY == "READY")
	check("and nothing for a kit with no ultimate", Glance.cell("") == "" and Glance.cell(nil) == "")
end

-- A kit charging, as the scoreboard and the top bar follow it ----------------------

do
	local k = AbilitySim.new("phoenix")
	local cells, lit = {}, {}
	for points = 0, 8 do
		k.points = points
		local text = Glance.ultimate(k)
		table.insert(cells, Glance.cell(text))
		table.insert(lit, if Glance.ready(text) then "1" else "0")
	end
	local shown = table.concat(cells, " ")
	check("Run it Back charging: 0/7 to 6/7, then READY", shown == "0/7 1/7 2/7 3/7 4/7 5/7 6/7 READY READY", shown)
	check("the diamond lit from the seventh point", table.concat(lit) == "000000011", table.concat(lit))
end

-- Who's who ----------------------------------------------------------------------

do
	local badges, seen, unique = {}, {}, true
	for _, id in AbilityConfig.AgentIds do
		local badge = Glance.badge(id, "Player1")
		if seen[badge] or #badge ~= 2 then
			unique = false
		end
		seen[badge] = true
		table.insert(badges, badge)
	end
	local shown = table.concat(badges, " ")
	check("each agent's two letters, all different: JE PH SA OM SO", unique and shown == "JE PH SA OM SO", shown)
	check("where nobody plays an agent (gun game), the name's: FE", Glance.badge(nil, "fearbrad") == "FE")
	check("and the same for no agent's kit", Glance.badge(AbilityConfig.NO_AGENT, "Player2") == "PL")
	check("and for an agent that isn't one of ours", Glance.badge("reyna", "Player2") == "PL")
	check("a name of one letter", Glance.badge(nil, "x") == "X")
end

-- A health bar ---------------------------------------------------------------------

check("full health fills the bar", Glance.share(100, 100) == 1)
check("half of it, half", Glance.share(50, 100) == 0.5)
check("never past full", Glance.share(150, 100) == 1)
check("nor under empty", Glance.share(-5, 100) == 0)
check("nothing for a bar of nothing", Glance.share(10, 0) == 0)

-- The tiles, for scripted checks ------------------------------------------------

check("a teammate alive at full health", Glance.describe("JE", 100, true, false) == "JE 100")
check("health rounded up, as over players' heads, with the ultimate ready", Glance.describe("SA", 42.3, true, true) == "SA 43 ready")
check("a dead teammate", Glance.describe("OM", 0, false, false) == "OM 0 dead")
check("an enemy shows no health, only if they're dead and ready", Glance.describe("SO", nil, false, true) == "SO dead ready")

return nil
