--!strict
-- Wharf (system 58), a dressed spike map of our own for five a side, set on
-- a harbour, and rebuilt (system 59) to the measurements of the
-- reference's maps and Counter-Strike's: two levels, sites their size,
-- chokes and lanes their widths and cover as close-set, with each part
-- built as a well-known one is, not copied from it
-- (docs/research/59-wharf-heights.md):
--
--   * A, a loading yard: A main west from the attackers' lobby, a roofed
--     hall that bends twice to a 3 m door onto the site, and a link from
--     mid through a short. The site, 24 by 22 m round a container, the
--     default plant, has heaven at its back, a roofed room 3.2 m up,
--     reached by stairs from the defenders' side and others from the
--     site, its deck railed but for a gap to drop through, and hell
--     under it (Ascent's A).
--   * Mid: north from the attackers' door, jogging so nobody sees down it
--     from one spawn to the other, to a courtyard overlooked by a window
--     room 3 m up on the defenders' side, reached by stairs from their mid
--     (Mirage's window), its tree off to one side, out of the window's
--     view down the lane. The market, a roofed walk, leads east to hookah,
--     a room with a door onto B and a window to vault through (Bind's B).
--   * B, the container yard: B long from the attackers' lobby through
--     doors and down a long lane (Dust II's long A), onto a site with a
--     platform 1.6 m up at its back, a ramp to it from the site and
--     another from the defenders' hall.
--   * The defenders: a hall from their spawn to the back of each site.
--
-- Its cover is the kit's (MapKit): crates, crate stacks, containers,
-- barrels, planters, hedges and trees, each a placeholder for a model of
-- the same name.

local MapPlan = require("./MapPlan")

-- A sign on a wall, from y0 up, with its text facing `face`.
local function sign(name: string, text: string, face: string, x0: number, y0: number, z0: number, x1: number, z1: number): MapPlan.Dressing
	return { name = name, style = "sign", x0 = x0, y0 = y0, z0 = z0, x1 = x1, y1 = y0 + 2.6, z1 = z1, text = text, face = face }
end

-- How high heaven, the window room and B's platform stand.
local HEAVEN = 3.2
local WINDOW = 3
local PLATFORM = 1.6

local FRONT: { MapPlan.Side } = { "+z" }
local END: { MapPlan.Side } = { "+x" }

-- Heaven's deck: railed along its front but for its east end, a gap to
-- drop through into the site.
local decks: { MapPlan.Deck } = {
	{ name = "HeavenDeck", x0 = -52, z0 = -30, x1 = -40, z1 = -26, y = HEAVEN, rails = FRONT },
	{ name = "HeavenDrop", x0 = -40, z0 = -30, x1 = -36, z1 = -26, y = HEAVEN, rails = END },
}

local flights: { MapPlan.Flight } = {
	{ name = "HeavenStairs", x0 = -42, z0 = -34, x1 = -34, z1 = -30, up = "-x", y0 = 0, y1 = HEAVEN, stairs = true },
	{ name = "SiteStairs", x0 = -52, z0 = -26, x1 = -49, z1 = -18, up = "-z", y0 = 0, y1 = HEAVEN, stairs = true },
	{ name = "WindowStairs", x0 = -3, z0 = -34, x1 = 3, z1 = -26, up = "+z", y0 = 0, y1 = WINDOW, stairs = true },
	{ name = "BRamp", x0 = 32, z0 = -30, x1 = 38, z1 = -26, up = "+x", y0 = 0, y1 = PLATFORM },
	{ name = "BElbowRamp", x0 = 40, z0 = -42, x1 = 46, z1 = -36, up = "+z", y0 = 0, y1 = PLATFORM },
}

local windows: { MapPlan.Window } = {
	{ name = "MidWindowFrame", x0 = -2, z0 = -13, x1 = 2, z1 = -12, sill = WINDOW + 1.3, top = WINDOW + 2.6 },
	{ name = "BWindow", x0 = 27, z0 = -15, x1 = 28, z1 = -12, sill = 0.75, top = 2.7 },
}

return MapPlan.new({
	name = "Wharf",
	layout = "wharf",
	origin = vector.create(-600, 0, 0),

	rooms = {
		-- The attackers' side.
		{ name = "AttackerSpawn", x0 = -9, z0 = 44, x1 = 9, z1 = 56, zone = "attack" },
		{ name = "AttackerDoorMid", x0 = -2, z0 = 42, x1 = 2, z1 = 44, zone = "attack", lintel = true },
		{ name = "AttackerDoorA", x0 = -11, z0 = 47, x1 = -9, z1 = 51, zone = "attack", lintel = true },
		{ name = "AttackerDoorB", x0 = 9, z0 = 47, x1 = 11, z1 = 51, zone = "attack", lintel = true },
		{ name = "ALobby", x0 = -32, z0 = 42, x1 = -11, z1 = 54, zone = "attack" },
		{ name = "BLobby", x0 = 11, z0 = 42, x1 = 30, z1 = 54, zone = "attack" },
		{ name = "MidBottom", x0 = -6, z0 = 32, x1 = 10, z1 = 42, zone = "attack" },
		{ name = "MidLower", x0 = 3, z0 = 22, x1 = 10, z1 = 32, zone = "mid" },
		{ name = "MidJog", x0 = -3, z0 = 18, x1 = 10, z1 = 22, zone = "mid" },

		-- A main.
		{ name = "AMain", x0 = -38, z0 = 20, x1 = -32, z1 = 48, zone = "hall", roof = true },
		{ name = "AMainBend", x0 = -50, z0 = 14, x1 = -32, z1 = 20, zone = "a" },
		{ name = "AMainHall", x0 = -50, z0 = -4, x1 = -44, z1 = 14, zone = "a" },
		{ name = "AMainDoor", x0 = -49, z0 = -8, x1 = -46, z1 = -4, zone = "a", lintel = true },

		-- A.
		{ name = "ASite", x0 = -52, z0 = -30, x1 = -28, z1 = -8, zone = "a" },
		{ name = "AHeaven", x0 = -48, z0 = -36, x1 = -42, z1 = -30, zone = "hall", y = HEAVEN, roof = true },
		{ name = "ABack", x0 = -34, z0 = -42, x1 = -28, z1 = -30, zone = "a" },
		{ name = "AShort", x0 = -28, z0 = -14, x1 = -25, z1 = -11, zone = "a", lintel = true },
		{ name = "ALink", x0 = -25, z0 = -14, x1 = -10, z1 = -8, zone = "hall", roof = true },

		-- Mid.
		{ name = "Mid", x0 = -3, z0 = 2, x1 = 4, z1 = 18, zone = "mid" },
		{ name = "MidCourt", x0 = -10, z0 = -12, x1 = 13, z1 = 2, zone = "mid" },
		{ name = "MidWindow", x0 = -6, z0 = -26, x1 = 6, z1 = -13, zone = "hall", y = WINDOW, roof = true },
		{ name = "TopMid", x0 = 8, z0 = -34, x1 = 13, z1 = -12, zone = "defend" },
		{ name = "Market", x0 = 13, z0 = -12, x1 = 27, z1 = -4, zone = "hall", roof = true },
		{ name = "BHookah", x0 = 22, z0 = -20, x1 = 27, z1 = -12, zone = "hall", roof = true },
		{ name = "BShort", x0 = 27, z0 = -20, x1 = 28, z1 = -17, zone = "b", lintel = true },

		-- B.
		{ name = "BLongDoors", x0 = 30, z0 = 44, x1 = 33, z1 = 48, zone = "b", lintel = true },
		{ name = "BLongCorner", x0 = 33, z0 = 40, x1 = 52, z1 = 50, zone = "b" },
		{ name = "BLong", x0 = 44, z0 = -8, x1 = 52, z1 = 40, zone = "b" },
		{ name = "BSite", x0 = 28, z0 = -30, x1 = 52, z1 = -8, zone = "b" },
		{ name = "BPlatform", x0 = 38, z0 = -30, x1 = 52, z1 = -24, zone = "b", y = PLATFORM },
		{ name = "BElbow", x0 = 40, z0 = -36, x1 = 46, z1 = -30, zone = "b", y = PLATFORM },
		{ name = "BBack", x0 = 28, z0 = -42, x1 = 32, z1 = -30, zone = "b" },

		-- The defenders' side.
		{ name = "DefenderSpawn", x0 = -9, z0 = -52, x1 = 9, z1 = -40, zone = "defend" },
		{ name = "DefenderDoorMid", x0 = -2, z0 = -40, x1 = 2, z1 = -38, zone = "defend", lintel = true },
		{ name = "DefenderDoorA", x0 = -11, z0 = -48, x1 = -9, z1 = -44, zone = "defend", lintel = true },
		{ name = "DefenderDoorB", x0 = 9, z0 = -48, x1 = 11, z1 = -44, zone = "defend", lintel = true },
		{ name = "DefenderMid", x0 = -8, z0 = -38, x1 = 13, z1 = -34, zone = "defend" },
		{ name = "AHall", x0 = -34, z0 = -48, x1 = -11, z1 = -42, zone = "defend" },
		{ name = "BHall", x0 = 11, z0 = -48, x1 = 46, z1 = -42, zone = "defend" },
	},

	decks = decks,
	flights = flights,
	windows = windows,

	cover = {
		-- The attackers' spawn, lobbies and mid bottom.
		{ name = "SpawnBarrels", x = -7.4, z = 54.4, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels" },
		{ name = "SpawnCrate", x = 7.3, z = 54.3, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "ALobbyContainer", x = -22, z = 52.8, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 2 },
		{ name = "ALobbyStack", x = -27, z = 44.6, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack" },
		{ name = "ALobbyCrate", x = -16, z = 45, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 2 },
		{ name = "ALobbyBarrels", x = -30.4, z = 52.4, sx = 1.2, sz = 1.8, height = "low", piece = "Barrels", look = 3 },
		{ name = "BLobbyContainer", x = 20, z = 43.2, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 4 },
		{ name = "BLobbyCrate", x = 14, z = 52.5, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "BLobbyStack", x = 26.5, z = 51, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack", look = 2 },
		{ name = "MidBottomContainer", x = -2, z = 33.2, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 3 },
		{ name = "MidBottomCrate", x = 8.4, z = 40.4, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 3 },
		{ name = "MidLowerStack", x = 8.9, z = 26, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack", look = 2 },

		-- A main.
		{ name = "AMainCrate", x = -36.6, z = 44.4, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 2 },
		{ name = "AMainBarrels", x = -32.7, z = 33, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels" },
		{ name = "AMainStack", x = -36.7, z = 24, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack", look = 3 },
		{ name = "AMainBendContainer", x = -41, z = 15.2, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 5 },
		{ name = "AMainBendCrate", x = -48.5, z = 18.6, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "AMainHallCrate", x = -45.3, z = 8, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 3 },
		{ name = "AMainHallBarrels", x = -48.8, z = 0, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels", look = 2 },

		-- A.
		{ name = "ADefault", x = -41, z = -18.2, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 1 },
		{ name = "ASiteMainStack", x = -44.2, z = -11.2, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack" },
		{ name = "ASiteMainCrate", x = -42.7, z = -11.1, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "AShortBarrels", x = -31, z = -15.5, sx = 1.2, sz = 1.8, height = "low", piece = "Barrels", look = 3 },
		{ name = "ASiteStack", x = -33, z = -21, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack", look = 2 },
		{ name = "AHellCrate", x = -40, z = -28.3, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 2 },
		{ name = "ABackCrate", x = -30.5, z = -27.5, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 3 },
		{ name = "AStairsCrate", x = -47.4, z = -16, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "ATruck", x = -33, z = -9.2, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 4 },
		{ name = "AHeavenCrate", x = -46.5, z = -34.5, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 2 },
		{ name = "ALinkCrate", x = -17, z = -12.6, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },

		-- Mid.
		{ name = "MidPlanterWest", x = -2.4, z = 15, sx = 1.2, sz = 3, height = "low", piece = "Planter" },
		{ name = "MidPlanterEast", x = 3.4, z = 9, sx = 1.2, sz = 3, height = "low", piece = "Planter", look = 2 },
		{ name = "MidStack", x = -2.2, z = 6, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack" },
		{ name = "MidTree", x = 8, z = -7, sx = 3, sz = 3, height = "low", piece = "Tree" },
		{ name = "MidHedge", x = -6.5, z = -3, sx = 4, sz = 1.2, height = "high", piece = "Hedge" },
		{ name = "MidCourtCrate", x = 9.5, z = -1, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 2 },
		{ name = "MidCourtBarrels", x = -8.4, z = -10.6, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels", look = 2 },
		{ name = "WindowCrate", x = -4.5, z = -24.5, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "WindowStack", x = 4.3, z = -15, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack", look = 2 },
		{ name = "TopMidCrate", x = 11.5, z = -20, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 3 },
		{ name = "DefenderMidBarrels", x = -6.5, z = -36, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels" },
		{ name = "MarketStack", x = 17, z = -10.4, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack", look = 3 },
		{ name = "MarketCrate", x = 21.5, z = -5.4, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "HookahBarrels", x = 23.4, z = -18.6, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels", look = 3 },

		-- B long and B.
		{ name = "BLongCornerBarrels", x = 35, z = 48.5, sx = 1.2, sz = 1.8, height = "low", piece = "Barrels" },
		{ name = "BLongCornerStack", x = 50, z = 41.8, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack" },
		{ name = "BLongContainer", x = 45.2, z = 18, sx = 2.4, sz = 6, height = "tall", piece = "Container", look = 2 },
		{ name = "BLongCrate", x = 50.5, z = -3, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 2 },
		{ name = "BDefault", x = 39, z = -17, sx = 2, sz = 2, height = "high", piece = "CrateStack", look = 3 },
		{ name = "BDefaultCrate", x = 37.3, z = -17.2, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "BPlatformCrate", x = 48, z = -26, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 3 },
		{ name = "BCar", x = 48, z = -11.2, sx = 6, sz = 2.4, height = "tall", piece = "Container", look = 5 },
		{ name = "BShortBarrels", x = 30, z = -22.5, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels", look = 2 },
		{ name = "BWindowCrate", x = 31, z = -10.8, sx = 1.4, sz = 1.4, height = "low", piece = "Crate", look = 2 },
		{ name = "BSiteStack", x = 44, z = -19, sx = 1.6, sz = 1.6, height = "high", piece = "CrateStack" },

		-- The defenders' halls.
		{ name = "AHallCrate", x = -20, z = -46.5, sx = 1.4, sz = 1.4, height = "low", piece = "Crate" },
		{ name = "BHallBarrels", x = 24, z = -43.4, sx = 1.2, sz = 1.2, height = "low", piece = "Barrels", look = 2 },
	},

	doors = {
		attack = { "AttackerDoorMid", "AttackerDoorA", "AttackerDoorB" },
		defend = { "DefenderDoorMid", "DefenderDoorA", "DefenderDoorB" },
	},

	sites = {
		{ site = "A", x = -41, z = -19, sx = 12, sz = 10 },
		{ site = "B", x = 38, z = -17, sx = 12, sz = 10 },
	},

	spikeStart = vector.create(0, 0, 46.5),

	-- Over the walls, the yard's buildings, the harbour's control tower,
	-- and the gantry crane over B; each site's sign high on the wall at its
	-- back, facing the attackers' way in.
	dressing = {
		{ name = "Warehouse", style = "building", x0 = -30, y0 = 5, z0 = 6, x1 = -8, y1 = 10.5, z1 = 28 },
		{ name = "Sheds", style = "building", x0 = -42, y0 = 5, z0 = -5, x1 = -30, y1 = 8, z1 = 11 },
		{ name = "Customs", style = "building", x0 = -26, y0 = 5, z0 = -38, x1 = -12, y1 = 8, z1 = -18 },
		{ name = "Terminal", style = "building", x0 = 14, y0 = 5, z0 = 24, x1 = 40, y1 = 8.5, z1 = 38 },
		{ name = "Offices", style = "building", x0 = 16, y0 = 5, z0 = 2, x1 = 30, y1 = 9, z1 = 18 },
		{ name = "Tower", style = "tower", x0 = 15, y0 = 5, z0 = -34, x1 = 21, y1 = 15, z1 = -24 },
		{ name = "TowerCap", style = "tower", x0 = 14.5, y0 = 15, z0 = -34.5, x1 = 21.5, y1 = 15.6, z1 = -23.5 },
		{ name = "CraneLegWest", style = "crane", x0 = 20, y0 = 5, z0 = -17, x1 = 21, y1 = 16, z1 = -16 },
		{ name = "CraneLegEast", style = "crane", x0 = 52, y0 = 5, z0 = -17, x1 = 53, y1 = 16, z1 = -16 },
		{ name = "CraneBeam", style = "crane", x0 = 19.5, y0 = 16, z0 = -17.6, x1 = 53.5, y1 = 17.2, z1 = -15.4 },
		{ name = "CraneTrolley", style = "crane", x0 = 37, y0 = 14.6, z0 = -18, x1 = 40, y1 = 16, z1 = -15 },
		sign("SignA", "A", "+z", -51.5, 5.2, -30, -48.5, -29.95),
		sign("SignB", "B", "+z", 47, 3.6, -30, 51, -29.95),
	},
})
