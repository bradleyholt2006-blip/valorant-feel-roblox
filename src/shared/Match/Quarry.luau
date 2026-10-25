--!strict
-- Quarry (system 25), a spike map of our own for five a side, laid out as
-- the reference's two-site maps are: three lanes and two sites, the
-- attackers' spawn at one end (+z) with a door into each lane, and the
-- defenders' at the other, nearer both sites.
--
--   * A: a lobby west from the attackers' spawn to A main, a long corridor
--     north, and a choke into the site. Window, a passage from A main across
--     to mid bottom, joins the two lanes on the attackers' side.
--   * Mid: a lane north from mid bottom into a courtyard, a ring round a
--     block that stops anyone seeing down mid from one end to the other.
--     From it A link leads west onto site A, market east onto site B, and
--     top mid north to the defenders' door.
--   * B: a lobby east to B main, which turns at an elbow and comes down
--     onto the site through a choke.
--   * The defenders: a back hall from their spawn to each site.
-- Running with the knife, the defenders reach each site's plant area about
-- 4 s before the attackers can (tests/match.luau prints the times).

local MapPlan = require("./MapPlan")

return MapPlan.new({
	name = "Quarry",
	layout = "quarry",
	-- Past Outpost, off the course's left.
	origin = vector.create(-300, 0, 0),

	rooms = {
		{ name = "AttackerSpawn", x0 = -8, z0 = 26, x1 = 8, z1 = 38 },
		{ name = "AttackerDoorA", x0 = -10, z0 = 28, x1 = -8, z1 = 32 },
		{ name = "AttackerDoorMid", x0 = -2, z0 = 24, x1 = 2, z1 = 26 },
		{ name = "AttackerDoorB", x0 = 8, z0 = 28, x1 = 10, z1 = 32 },

		{ name = "ALobby", x0 = -44, z0 = 24, x1 = -10, z1 = 32 },
		{ name = "AMain", x0 = -44, z0 = -8, x1 = -36, z1 = 24 },
		{ name = "AChoke", x0 = -42, z0 = -12, x1 = -37, z1 = -8 },
		{ name = "ASite", x0 = -46, z0 = -34, x1 = -22, z1 = -12 },
		{ name = "Window", x0 = -36, z0 = 14, x1 = -7, z1 = 18 },

		{ name = "MidBottom", x0 = -7, z0 = 12, x1 = 7, z1 = 24 },
		{ name = "MidLane", x0 = -3, z0 = -4, x1 = 3, z1 = 12 },
		{ name = "CourtSouth", x0 = -14, z0 = -8, x1 = 10, z1 = -4 },
		{ name = "CourtWest", x0 = -14, z0 = -16, x1 = -8, z1 = -8 },
		{ name = "CourtEast", x0 = 4, z0 = -16, x1 = 10, z1 = -8 },
		{ name = "CourtNorth", x0 = -14, z0 = -20, x1 = 10, z1 = -16 },
		{ name = "TopMid", x0 = -3, z0 = -40, x1 = 3, z1 = -20 },
		{ name = "ALink", x0 = -22, z0 = -18, x1 = -14, z1 = -12 },
		{ name = "Market", x0 = 10, z0 = -16, x1 = 24, z1 = -8 },

		{ name = "BSite", x0 = 24, z0 = -32, x1 = 42, z1 = -14 },
		{ name = "BChoke", x0 = 36, z0 = -14, x1 = 41, z1 = -10 },
		{ name = "BMainLower", x0 = 34, z0 = -10, x1 = 42, z1 = 2 },
		{ name = "BElbow", x0 = 22, z0 = 2, x1 = 42, z1 = 8 },
		{ name = "BMainUpper", x0 = 22, z0 = 8, x1 = 30, z1 = 24 },
		{ name = "BLobby", x0 = 10, z0 = 24, x1 = 30, z1 = 32 },

		{ name = "DefenderSpawn", x0 = -8, z0 = -52, x1 = 8, z1 = -42 },
		{ name = "DefenderDoorA", x0 = -10, z0 = -50, x1 = -8, z1 = -46 },
		{ name = "DefenderDoorMid", x0 = -2, z0 = -42, x1 = 2, z1 = -40 },
		{ name = "DefenderDoorB", x0 = 8, z0 = -50, x1 = 10, z1 = -46 },
		{ name = "ABackHall", x0 = -34, z0 = -52, x1 = -10, z1 = -44 },
		{ name = "ABack", x0 = -34, z0 = -44, x1 = -26, z1 = -34 },
		{ name = "BBackHall", x0 = 10, z0 = -52, x1 = 36, z1 = -44 },
		{ name = "BBack", x0 = 28, z0 = -44, x1 = 36, z1 = -32 },
	},

	cover = {
		{ name = "ADefault", x = -34, z = -23, sx = 2, sz = 2, height = "high" },
		{ name = "AFront", x = -31, z = -14.5, sx = 3, sz = 1.2, height = "low" },
		{ name = "ABackBox", x = -42, z = -30, sx = 2, sz = 2, height = "high" },
		{ name = "ABackCrate", x = -29, z = -31, sx = 2, sz = 2, height = "low" },
		{ name = "ALinkCrate", x = -24.5, z = -15, sx = 1.2, sz = 2, height = "low" },
		{ name = "AMainCrate", x = -42, z = 10, sx = 2, sz = 2, height = "low" },
		{ name = "AMainHigh", x = -38, z = -2, sx = 2, sz = 2, height = "high" },
		{ name = "ALobbyCrate", x = -28, z = 28, sx = 2, sz = 2, height = "high" },
		{ name = "MidBottomCrate", x = -4, z = 18, sx = 2, sz = 2, height = "low" },
		{ name = "CourtCrate", x = 6, z = -6, sx = 3, sz = 1.2, height = "low" },
		{ name = "MarketBox", x = 16, z = -12, sx = 2, sz = 2, height = "high" },
		{ name = "BDefault", x = 33, z = -23, sx = 2, sz = 2, height = "high" },
		{ name = "BFront", x = 38, z = -16, sx = 3, sz = 1.2, height = "low" },
		{ name = "BBackBox", x = 26, z = -30, sx = 2, sz = 2, height = "high" },
		{ name = "BStack", x = 40, z = -29, sx = 2, sz = 2, height = "low" },
		{ name = "ElbowCrate", x = 32, z = 5, sx = 2, sz = 2, height = "low" },
		{ name = "BLobbyCrate", x = 18, z = 28, sx = 2, sz = 2, height = "high" },
	},

	doors = {
		attack = { "AttackerDoorMid", "AttackerDoorA", "AttackerDoorB" },
		defend = { "DefenderDoorMid", "DefenderDoorA", "DefenderDoorB" },
	},

	-- A, the bigger site, has the bigger plant area.
	sites = {
		{ site = "A", x = -34, z = -23, sx = 14, sz = 12 },
		{ site = "B", x = 33, z = -23, sx = 12, sz = 10 },
	},

	-- In front of the attackers, between their spawn spots and their door to
	-- mid, as on Outpost.
	spikeStart = vector.create(0, 0, 30),
})
