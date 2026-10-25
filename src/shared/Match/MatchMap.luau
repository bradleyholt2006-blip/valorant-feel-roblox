--!strict
-- The spike rounds' first map (system 13): Outpost, a compact two-site map
-- of our own, for 1v1 to 3v3. The reference's maps are built for 5v5 and
-- none is published at a scale we could build from, so this one follows
-- their pattern instead: the attackers' spawn at one end and the defenders'
-- at the other, site A on the attackers' left and B on their right, each
-- reached by a main from the attackers' side, by a link from mid, and from
-- the defenders' spawn, which is nearer both sites than the attackers' is.
-- Mirrored left to right, so neither site is the easy one.
--
-- Its plan is a MapPlan, as every spike map's is (system 25): rooms of
-- floor on a 1 m grid, everything else inside the outline wall, and cover,
-- doors and sites on it. Quarry and Foundry, for five a side, are the
-- others (SpikeMaps).

local MapPlan = require("./MapPlan")

return MapPlan.new({
	name = "Outpost",
	layout = "outpost",
	-- Off to the course's left (-x, seen from its spawn), well clear of the
	-- wallbang lane.
	origin = vector.create(-150, 0, 0),

	-- The rooms in the middle, each its own mirror image, then those on A's
	-- side, each with its partner on B's.
	rooms = {
		{ name = "AttackerSpawn", x0 = -7, z0 = 26, x1 = 7, z1 = 36 },
		{ name = "AttackerDoorMid", x0 = -2, z0 = 24, x1 = 2, z1 = 26 },
		{ name = "MidBottom", x0 = -6, z0 = 12, x1 = 6, z1 = 24 },
		{ name = "MidSouth", x0 = -3, z0 = 5, x1 = 3, z1 = 12 },
		{ name = "MidNorth", x0 = -3, z0 = -3, x1 = 3, z1 = 0 },
		{ name = "MidTop", x0 = -4, z0 = -18, x1 = 4, z1 = -8 },
		{ name = "DefenderDoorMid", x0 = -2, z0 = -20, x1 = 2, z1 = -18 },
		{ name = "DefenderSpawn", x0 = -7, z0 = -30, x1 = 7, z1 = -20 },

		{ name = "AttackerDoorA", x0 = -9, z0 = 28, x1 = -7, z1 = 32, mirror = "AttackerDoorB" },
		{ name = "ALobby", x0 = -30, z0 = 27, x1 = -9, z1 = 33, mirror = "BLobby" },
		{ name = "AMain", x0 = -30, z0 = 8, x1 = -24, z1 = 27, mirror = "BMain" },
		{ name = "AChoke", x0 = -30, z0 = 4, x1 = -26, z1 = 8, mirror = "BChoke" },
		{ name = "ASite", x0 = -32, z0 = -14, x1 = -14, z1 = 4, mirror = "BSite" },
		{ name = "ALink", x0 = -14, z0 = -8, x1 = -6, z1 = -3, mirror = "BLink" },
		{ name = "MidA", x0 = -6, z0 = -8, x1 = -3, z1 = 12, mirror = "MidB" },
		{ name = "MidLaneA", x0 = -3, z0 = -8, x1 = -1, z1 = -3, mirror = "MidLaneB" },
		{ name = "DefenderDoorA", x0 = -9, z0 = -27, x1 = -7, z1 = -23, mirror = "DefenderDoorB" },
		{ name = "ABackHall", x0 = -22, z0 = -28, x1 = -9, z1 = -22, mirror = "BBackHall" },
		{ name = "ABack", x0 = -22, z0 = -22, x1 = -16, z1 = -14, mirror = "BBack" },
	},

	-- Cover on A's side, each with its partner on B's. The block in the
	-- middle of mid is the space between MidNorth, MidSouth, MidA and MidB,
	-- and the pillar north of it, between the two lanes, stands where the
	-- links meet, so neither site sees into the other: both wall.
	cover = {
		{ name = "ADefault", x = -23, z = -5, sx = 2, sz = 2, height = "high", mirror = "BDefault" },
		{ name = "AFront", x = -20, z = 1.5, sx = 3, sz = 1.2, height = "low", mirror = "BFront" },
		{ name = "ABackBox", x = -29, z = -12, sx = 2, sz = 2, height = "high", mirror = "BBackBox" },
		{ name = "AStackHigh", x = -16, z = -12, sx = 2, sz = 2, height = "high", mirror = "BStackHigh" },
		{ name = "AStackLow", x = -18, z = -12, sx = 2, sz = 2, height = "low", mirror = "BStackLow" },
		{ name = "ALinkCrate", x = -16, z = -1, sx = 2, sz = 1.2, height = "low", mirror = "BLinkCrate" },
		{ name = "AMainCrate", x = -29, z = 18, sx = 2, sz = 2, height = "low", mirror = "BMainCrate" },
		{ name = "ALobbyCrate", x = -18, z = 30, sx = 2, sz = 2, height = "high", mirror = "BLobbyCrate" },
		{ name = "MidCrateA", x = -5, z = 18, sx = 2, sz = 2, height = "low", mirror = "MidCrateB" },
	},

	doors = {
		attack = { "AttackerDoorMid", "AttackerDoorA", "AttackerDoorB" },
		defend = { "DefenderDoorMid", "DefenderDoorA", "DefenderDoorB" },
	},

	-- A 12 by 10 m plant area in the middle of each site.
	sites = {
		{ site = "A", x = -23, z = -5, sx = 12, sz = 10 },
		{ site = "B", x = 23, z = -5, sx = 12, sz = 10 },
	},

	-- "Dropped in front of the Attackers" (the VALORANT Wiki, Spike;
	-- community), between their spawn spots and their door to mid.
	spikeStart = vector.create(0, 0, 29),
})
