--!strict
-- Foundry (system 25), a spike map of our own for five a side, laid out as
-- the reference's two-site maps are: three lanes and two sites, the
-- attackers' spawn at one end (+z) with a door into each lane, and the
-- defenders' at the other, nearer both sites. Where Quarry's lanes turn,
-- Foundry's run straight, for longer fights.
--
--   * A: a lobby west from the attackers' spawn to A long, a corridor 46 m
--     straight down the map's west side, which turns at a corner onto the
--     site. A short, a hall west from mid bottom, turns north onto the
--     attackers' side of the site.
--   * Mid: a wide mid bottom, then a hall round a block that stops anyone
--     seeing down mid from one end to the other, and top mid north to the
--     defenders' door. B link leads east from the hall onto site B.
--   * B: a lobby east to B main, straight north to a choke into the site.
--   * The defenders: a back hall from their spawn to each site.
-- Running with the knife, the defenders reach each site's plant area 4 to 5
-- s before the attackers can (tests/match.luau prints the times).

local MapPlan = require("./MapPlan")

return MapPlan.new({
	name = "Foundry",
	layout = "foundry",
	-- Past Quarry, off the course's left.
	origin = vector.create(-450, 0, 0),

	rooms = {
		{ name = "AttackerSpawn", x0 = -8, z0 = 30, x1 = 8, z1 = 42 },
		{ name = "AttackerDoorA", x0 = -10, z0 = 32, x1 = -8, z1 = 36 },
		{ name = "AttackerDoorMid", x0 = -2, z0 = 28, x1 = 2, z1 = 30 },
		{ name = "AttackerDoorB", x0 = 8, z0 = 32, x1 = 10, z1 = 36 },

		{ name = "ALobby", x0 = -46, z0 = 30, x1 = -10, z1 = 38 },
		{ name = "ALong", x0 = -46, z0 = -16, x1 = -40, z1 = 30 },
		{ name = "ALongCorner", x0 = -46, z0 = -22, x1 = -34, z1 = -16 },
		{ name = "ASite", x0 = -40, z0 = -38, x1 = -18, z1 = -18 },
		{ name = "AShortHall", x0 = -26, z0 = 8, x1 = -7, z1 = 14 },
		{ name = "AShortDown", x0 = -26, z0 = -18, x1 = -20, z1 = 8 },

		{ name = "MidBottom", x0 = -7, z0 = 4, x1 = 7, z1 = 28 },
		{ name = "MidHallSouth", x0 = -12, z0 = -2, x1 = 12, z1 = 4 },
		{ name = "MidHallWest", x0 = -12, z0 = -16, x1 = -6, z1 = -2 },
		{ name = "MidHallEast", x0 = 6, z0 = -16, x1 = 12, z1 = -2 },
		{ name = "MidHallNorth", x0 = -12, z0 = -20, x1 = 12, z1 = -16 },
		{ name = "TopMid", x0 = -3, z0 = -40, x1 = 3, z1 = -20 },
		{ name = "BLink", x0 = 12, z0 = -12, x1 = 22, z1 = -6 },

		{ name = "BSite", x0 = 22, z0 = -30, x1 = 40, z1 = -10 },
		{ name = "BChoke", x0 = 30, z0 = -10, x1 = 35, z1 = -6 },
		{ name = "BMain", x0 = 28, z0 = -6, x1 = 36, z1 = 30 },
		{ name = "BLobby", x0 = 10, z0 = 30, x1 = 36, z1 = 38 },

		{ name = "DefenderSpawn", x0 = -8, z0 = -54, x1 = 8, z1 = -42 },
		{ name = "DefenderDoorA", x0 = -10, z0 = -52, x1 = -8, z1 = -48 },
		{ name = "DefenderDoorMid", x0 = -2, z0 = -42, x1 = 2, z1 = -40 },
		{ name = "DefenderDoorB", x0 = 8, z0 = -52, x1 = 10, z1 = -48 },
		{ name = "AHall", x0 = -34, z0 = -54, x1 = -10, z1 = -46 },
		{ name = "ABack", x0 = -34, z0 = -46, x1 = -26, z1 = -38 },
		{ name = "BHall", x0 = 10, z0 = -54, x1 = 30, z1 = -46 },
		{ name = "BBack", x0 = 24, z0 = -46, x1 = 30, z1 = -30 },
	},

	cover = {
		{ name = "ADefault", x = -29, z = -26, sx = 2, sz = 2, height = "high" },
		{ name = "AFront", x = -24, z = -20.5, sx = 3, sz = 1.2, height = "low" },
		{ name = "ABackBox", x = -37, z = -35, sx = 2, sz = 2, height = "high" },
		{ name = "AStack", x = -21, z = -33, sx = 2, sz = 2, height = "high" },
		{ name = "AStackLow", x = -21, z = -30.5, sx = 2, sz = 2, height = "low" },
		{ name = "ACornerBox", x = -37, z = -19, sx = 2, sz = 2, height = "low" },
		{ name = "ALongCrate", x = -43, z = 10, sx = 2, sz = 2, height = "low" },
		{ name = "ALongHigh", x = -45, z = -6, sx = 2, sz = 2, height = "high" },
		{ name = "ALobbyCrate", x = -30, z = 34, sx = 2, sz = 2, height = "high" },
		{ name = "AShortCrate", x = -23, z = -4, sx = 1.2, sz = 2, height = "low" },
		{ name = "MidBottomCrate", x = -4, z = 16, sx = 2, sz = 2, height = "low" },
		{ name = "MidBox", x = 4, z = 22, sx = 2, sz = 2, height = "high" },
		{ name = "MidHallCrate", x = 0, z = 1, sx = 3, sz = 1.2, height = "low" },
		{ name = "BDefault", x = 31, z = -23, sx = 2, sz = 2, height = "high" },
		{ name = "BFront", x = 33, z = -12.5, sx = 3, sz = 1.2, height = "low" },
		{ name = "BBackBox", x = 25, z = -27, sx = 2, sz = 2, height = "high" },
		{ name = "BStack", x = 38, z = -27, sx = 2, sz = 2, height = "low" },
		{ name = "BLinkCrate", x = 20, z = -9, sx = 1.2, sz = 2, height = "low" },
		{ name = "BMainCrate", x = 33, z = 12, sx = 2, sz = 2, height = "low" },
		{ name = "BLobbyCrate", x = 20, z = 34, sx = 2, sz = 2, height = "high" },
	},

	doors = {
		attack = { "AttackerDoorMid", "AttackerDoorA", "AttackerDoorB" },
		defend = { "DefenderDoorMid", "DefenderDoorA", "DefenderDoorB" },
	},

	-- A, the bigger site, has the bigger plant area.
	sites = {
		{ site = "A", x = -29, z = -26, sx = 14, sz = 12 },
		{ site = "B", x = 31, z = -23, sx = 12, sz = 10 },
	},

	-- In front of the attackers, between their spawn spots and their door to
	-- mid, as on Outpost.
	spikeStart = vector.create(0, 0, 34),
})
