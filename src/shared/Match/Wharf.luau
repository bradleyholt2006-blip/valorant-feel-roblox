--!strict
-- Wharf (system 58), a dressed spike map of our own for five a side, set on
-- a harbour: a warehouse loading yard at A, a garden plaza in mid and a
-- container yard at B, under a gantry crane. Laid out as the reference's
-- two-site maps are, three lanes and two sites ('core three-lane tactical
-- FPS map', Riot's Joey Simas on Corrode), with each site its own look, as
-- Split's are ('B Site was to be the older district in the city'), so
-- where you are reads at a glance.
--
--   * A: a lobby west from the attackers' spawn into A main, a roofed
--     warehouse hall north to a 5 m choke onto the site. The site is a wide
--     yard of crates and barrels round a container, the default plant.
--   * Mid: a street north from the attackers' door into the plaza, round a
--     tree at its heart, with planters and hedges for cover. The arcade, a
--     roofed walk, leads west onto site A, the market, another, east onto
--     site B, and top mid north, round a corner, to the defenders' door, so
--     nobody sees down mid from one spawn to the other.
--   * B: a lobby east into B main, a lane through the container yard with
--     containers parked across it, and a choke onto the site, a tighter one
--     than A's, of containers and crate stacks.
--   * The defenders: a hall from their spawn to the back of each site.
-- Running with the knife, the defenders reach each site's plant area 4.4
-- to 5.4 s before the attackers can (tests/match.luau prints the times).
--
-- Its cover is the kit's (MapKit): crates, crate stacks, containers,
-- barrels, planters, hedges and trees, each a placeholder for a model of
-- the same name.

local MapPlan = require("./MapPlan")

-- A sign on a wall, with its text facing `face`.
local function sign(name: string, text: string, face: string, x0: number, z0: number, x1: number, z1: number): MapPlan.Dressing
	return { name = name, style = "sign", x0 = x0, y0 = 1.8, z0 = z0, x1 = x1, y1 = 4.4, z1 = z1, text = text, face = face }
end

return MapPlan.new({
	name = "Wharf",
	layout = "wharf",
	-- Past Foundry, off the course's left.
	origin = vector.create(-600, 0, 0),

	rooms = {
		-- The attackers' side, on the dock road.
		{ name = "AttackerSpawn", x0 = -9, z0 = 40, x1 = 9, z1 = 52, zone = "attack" },
		{ name = "AttackerDoorMid", x0 = -2, z0 = 38, x1 = 2, z1 = 40, zone = "attack", lintel = true },
		{ name = "AttackerDoorA", x0 = -11, z0 = 43, x1 = -9, z1 = 47, zone = "attack", lintel = true },
		{ name = "AttackerDoorB", x0 = 9, z0 = 43, x1 = 11, z1 = 47, zone = "attack", lintel = true },
		{ name = "ALobby", x0 = -34, z0 = 34, x1 = -11, z1 = 48, zone = "attack" },
		{ name = "BLobby", x0 = 11, z0 = 34, x1 = 34, z1 = 48, zone = "attack" },
		{ name = "MidBottom", x0 = -6, z0 = 22, x1 = 6, z1 = 38, zone = "attack" },

		-- A: the warehouse hall and the loading yard.
		{ name = "AMain", x0 = -34, z0 = 6, x1 = -26, z1 = 34, zone = "hall", roof = true },
		{ name = "AChoke", x0 = -33, z0 = 0, x1 = -28, z1 = 6, zone = "a", lintel = true },
		{ name = "ASite", x0 = -52, z0 = -28, x1 = -24, z1 = 0, zone = "a" },

		-- Mid: the plaza, the arcade to A, the market to B and top mid.
		{ name = "Plaza", x0 = -15, z0 = -10, x1 = 15, z1 = 22, zone = "mid" },
		{ name = "Arcade", x0 = -24, z0 = -10, x1 = -15, z1 = -4, zone = "hall", roof = true },
		{ name = "Market", x0 = 12, z0 = -20, x1 = 22, z1 = -14, zone = "hall", roof = true },
		{ name = "TopMid", x0 = 4, z0 = -26, x1 = 12, z1 = -10, zone = "mid" },
		{ name = "MidCorner", x0 = -2, z0 = -32, x1 = 12, z1 = -26, zone = "defend" },

		-- B: the container lane and the container yard.
		{ name = "BMain", x0 = 28, z0 = 4, x1 = 38, z1 = 34, zone = "b" },
		{ name = "BChoke", x0 = 33, z0 = -2, x1 = 38, z1 = 4, zone = "b", lintel = true },
		{ name = "BSite", x0 = 22, z0 = -28, x1 = 48, z1 = -2, zone = "b" },

		-- The defenders' side.
		{ name = "DefenderSpawn", x0 = -9, z0 = -46, x1 = 9, z1 = -34, zone = "defend" },
		{ name = "DefenderDoorMid", x0 = -2, z0 = -34, x1 = 2, z1 = -32, zone = "defend", lintel = true },
		{ name = "DefenderDoorA", x0 = -11, z0 = -44, x1 = -9, z1 = -40, zone = "defend", lintel = true },
		{ name = "DefenderDoorB", x0 = 9, z0 = -44, x1 = 11, z1 = -40, zone = "defend", lintel = true },
		{ name = "AHall", x0 = -30, z0 = -46, x1 = -11, z1 = -38, zone = "defend" },
		{ name = "ABack", x0 = -30, z0 = -38, x1 = -24, z1 = -28, zone = "a" },
		{ name = "BHall", x0 = 11, z0 = -46, x1 = 30, z1 = -38, zone = "defend" },
		{ name = "BBack", x0 = 24, z0 = -38, x1 = 30, z1 = -28, zone = "b" },
	},

	cover = {
		-- The attackers' spawn and lobbies.
		{ name = "SpawnBarrelsA", x = -7.4, z = 50.4, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels" },
		{ name = "SpawnCrateB", x = 7.3, z = 50.3, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "ALobbyContainer", x = -22, z = 46.8, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 2 },
		{ name = "ALobbyStack", x = -30.5, z = 38, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack" },
		{ name = "BLobbyContainer", x = 22, z = 35.6, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 4 },
		{ name = "BLobbyBarrels", x = 31.5, z = 46, sx = 1.2, sz = 1.8, height = "low", piece = "Barrels", look = 3 },
		{ name = "MidBottomCrate", x = -4, z = 31, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "MidBottomBarrels", x = 4.4, z = 25, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels", look = 2 },

		-- A main and A.
		{ name = "AMainCrate", x = -32.3, z = 27, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 2 },
		{ name = "AMainStack", x = -27.7, z = 16, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack", look = 3 },
		{ name = "AMainBarrels", x = -32.4, z = 9, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels" },
		{ name = "ADefault", x = -39, z = -16, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 1 },
		{ name = "AChokeStack", x = -26, z = -4, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack" },
		{ name = "ASiteCrate", x = -33, z = -10.5, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 3 },
		{ name = "ASiteBarrels", x = -47, z = -5, sx = 1.8, sz = 1.2, height = "low", piece = "Barrels", look = 3 },
		{ name = "ABackContainer", x = -50.2, z = -21, sx = 2.4, sz = 6, height = "tall", piece = "Container", look = 5 },
		{ name = "ABackStack", x = -33, z = -24.5, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack", look = 2 },
		{ name = "ASiteCrateBack", x = -44, z = -25, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "ArcadePlanter", x = -26.5, z = -12.5, sx = 1.2, sz = 2.4, height = "low", piece = "Planter" },

		-- The plaza.
		{ name = "PlazaTree", x = 0, z = 6, sx = 3, sz = 3, height = "low", piece = "Tree" },
		{ name = "PlazaHedgeWest", x = -9, z = 0, sx = 5, sz = 1.2, height = "high", piece = "Hedge" },
		{ name = "PlazaHedgeEast", x = 9, z = 13, sx = 5, sz = 1.2, height = "high", piece = "Hedge", look = 2 },
		{ name = "PlazaPlanterWest", x = -9, z = 15, sx = 3, sz = 1.2, height = "low", piece = "Planter" },
		{ name = "PlazaPlanterEast", x = 8.5, z = -5, sx = 3, sz = 1.2, height = "low", piece = "Planter", look = 2 },
		{ name = "PlazaTreeWest", x = -12, z = 19, sx = 1.6, sz = 1.6, height = "low", piece = "Tree", look = 2 },
		{ name = "PlazaTreeEast", x = 12, z = 19, sx = 1.6, sz = 1.6, height = "low", piece = "Tree" },
		{ name = "TopMidStack", x = 10.2, z = -18, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack" },

		-- B main and B.
		{ name = "BMainContainerWest", x = 31, z = 25.2, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 3 },
		{ name = "BMainContainerEast", x = 35, z = 13.2, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 1 },
		{ name = "BMainCrate", x = 29.5, z = 7, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "BChokeStack", x = 39.8, z = -4, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack", look = 2 },
		{ name = "BDefault", x = 35, z = -14, sx = 2, sz = 2, height = "high", piece = "CrateStack", look = 3 },
		{ name = "BSiteContainer", x = 34, z = -24.2, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 2 },
		{ name = "BBackContainer", x = 46.2, z = -11, sx = 2.4, sz = 6, height = "tall", piece = "Container", look = 4 },
		{ name = "BSiteBarrels", x = 25.5, z = -17, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels" },
		{ name = "BSiteCrate", x = 41, z = -19, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 2 },
		{ name = "BSiteCrateFront", x = 24.5, z = -3.5, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 3 },

		-- The defenders' halls.
		{ name = "AHallCrate", x = -20, z = -44.5, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "BHallBarrels", x = 20, z = -39.5, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels", look = 2 },
	},

	doors = {
		attack = { "AttackerDoorMid", "AttackerDoorA", "AttackerDoorB" },
		defend = { "DefenderDoorMid", "DefenderDoorA", "DefenderDoorB" },
	},

	-- A, the open yard, has the bigger plant area.
	sites = {
		{ site = "A", x = -39, z = -14, sx = 14, sz = 12 },
		{ site = "B", x = 35, z = -14, sx = 12, sz = 12 },
	},

	-- In front of the attackers, between their spawn spots and their door to
	-- mid, as on the others.
	spikeStart = vector.create(0, 0, 42.5),

	-- Over the walls, out of everyone's reach: the buildings between the
	-- lanes, the harbour master's tower by the defenders' spawn, the gantry
	-- crane over B, and a sign for each site.
	dressing = {
		{ name = "Warehouse", style = "building", x0 = -25, y0 = 5, z0 = 7, x1 = -16, y1 = 9.5, z1 = 33 },
		{ name = "Terminal", style = "building", x0 = 7, y0 = 5, z0 = 23, x1 = 27, y1 = 8, z1 = 33 },
		{ name = "Sheds", style = "building", x0 = 16, y0 = 5, z0 = 0, x1 = 27, y1 = 7.5, z1 = 21 },
		{ name = "Customs", style = "building", x0 = -23, y0 = 5, z0 = -37, x1 = -10, y1 = 8, z1 = -12 },
		{ name = "Tower", style = "tower", x0 = 14, y0 = 5, z0 = -30, x1 = 20, y1 = 15, z1 = -22 },
		{ name = "TowerCap", style = "tower", x0 = 13.5, y0 = 15, z0 = -30.5, x1 = 20.5, y1 = 15.6, z1 = -21.5 },
		{ name = "CraneLegWest", style = "crane", x0 = 20, y0 = 5, z0 = -17, x1 = 21, y1 = 16, z1 = -16 },
		{ name = "CraneLegEast", style = "crane", x0 = 48, y0 = 5, z0 = -17, x1 = 49, y1 = 16, z1 = -16 },
		{ name = "CraneBeam", style = "crane", x0 = 19.5, y0 = 16, z0 = -17.6, x1 = 49.5, y1 = 17.2, z1 = -15.4 },
		{ name = "CraneTrolley", style = "crane", x0 = 32.5, y0 = 14.6, z0 = -18, x1 = 35.5, y1 = 16, z1 = -15 },
		sign("SignA", "A", "+z", -46, -28, -42, -27.95),
		sign("SignB", "B", "+z", 40, -28, 44, -27.95),
	},
})
