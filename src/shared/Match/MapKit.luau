--!strict
-- The kit a dressed spike map is built from (system 58): a few pieces used
-- over and over, as the reference's maps are dressed with the same crates,
-- containers and planters, and the look of each zone of its floor, its
-- walls and what's built over them.
--
-- A piece is cover (MapPlan): a box that's all there is to it for moving,
-- seeing and shooting ('Consistent cover is useful for combat games that
-- want to avoid ambiguity', the Level Design Book's Cover page), and how it
-- looks is for show. The server builds the box unseen and the piece's look
-- over it: the placeholder here, or a model of the same name in
-- ServerStorage's VFMapKit folder, fitted to the box, so a map's art can be
-- swapped in without touching its layout ('consider building a tool for
-- easily swapping in module types, which will make art pass and remesh
-- much faster', the book's Modular kit design page).
--
-- Plain data and maths: colours are { r, g, b } from 0 to 255 and materials
-- Roblox's names for them, which the server turns into its own. No Roblox
-- APIs here.

export type Height = "low" | "high" | "tall"
export type Shape = "block" | "cylinder" | "ball"
-- Penetration.Material, as the part's VFPenetration attribute.
export type Penetration = "soft" | "medium" | "hard" | "solid"
export type Colour = { number }

-- A piece of the kit: its cover's height (MapPlan.Heights), how many looks
-- it has, and how bullets go through it.
export type Piece = { height: Height, looks: number, penetration: Penetration, about: string }

-- One part of a piece's look, in the piece's own frame: from the middle of
-- its base, x along its longer side, y up. A cylinder stands upright: its
-- size is its diameter, height and diameter.
export type Bit = { name: string, offset: vector, size: vector, colour: Colour, material: string, shape: Shape }

-- How a zone's floor, the walls or a kind of dressing looks, and how
-- bullets go through it.
export type Look = { colour: Colour, material: string, penetration: Penetration, solid: boolean }

local MapKit = {}

-- The folder of ServerStorage the server looks in for a model to show in
-- place of each piece's placeholder, by the piece's name.
MapKit.FOLDER = "VFMapKit"
-- What each piece's box and model are called on: the piece's name.
MapKit.ATTRIBUTE = "VFKitPiece"

MapKit.Pieces = {
	Crate = {
		height = "low",
		looks = 3,
		penetration = "soft",
		about = "A wooden crate: crouch behind it, stand to shoot over it",
	},
	CrateStack = {
		height = "high",
		looks = 3,
		penetration = "soft",
		about = "Two crates, one on the other: hides a standing player",
	},
	Container = {
		height = "tall",
		looks = 5,
		penetration = "hard",
		about = "A 20 ft shipping container, 6 x 2.4 m",
	},
	Barrels = {
		height = "low",
		looks = 3,
		penetration = "hard",
		about = "Steel drums on a pallet",
	},
	Planter = {
		height = "low",
		looks = 2,
		penetration = "medium",
		about = "A stone planter with a low hedge",
	},
	Hedge = {
		height = "high",
		looks = 2,
		penetration = "medium",
		about = "A stone planter with a hedge above a standing head",
	},
	Tree = {
		height = "low",
		looks = 2,
		penetration = "medium",
		about = "A stone planter with a tree, its leaves above everyone's reach",
	},
} :: { [string]: Piece }

-- The looks of a dressed map's floor, by zone, and of its walls; of its
-- decks and its railings too (system 59).
MapKit.Themes = {
	wall = { colour = { 214, 205, 190 }, material = "Plaster", penetration = "solid", solid = true },
	plain = { colour = { 120, 122, 128 }, material = "Concrete", penetration = "solid", solid = true },
	attack = { colour = { 98, 96, 102 }, material = "Asphalt", penetration = "solid", solid = true },
	defend = { colour = { 150, 158, 170 }, material = "Slate", penetration = "solid", solid = true },
	mid = { colour = { 196, 182, 154 }, material = "Pavement", penetration = "solid", solid = true },
	a = { colour = { 182, 154, 114 }, material = "Concrete", penetration = "solid", solid = true },
	b = { colour = { 122, 146, 152 }, material = "Concrete", penetration = "solid", solid = true },
	hall = { colour = { 142, 122, 98 }, material = "WoodPlanks", penetration = "solid", solid = true },
	deck = { colour = { 104, 110, 118 }, material = "DiamondPlate", penetration = "solid", solid = true },
	rail = { colour = { 176, 166, 150 }, material = "Concrete", penetration = "solid", solid = true },
} :: { [string]: Look }

-- The looks of dressing (MapPlan.Dressing), by its style. What's solid
-- blocks movement, sight and shots, and is all out of reach overhead; signs,
-- lights and the steps over a flight of stairs' slope are for show.
MapKit.Styles = {
	roof = { colour = { 112, 108, 106 }, material = "Metal", penetration = "solid", solid = true },
	lintel = { colour = { 168, 156, 140 }, material = "Concrete", penetration = "solid", solid = true },
	building = { colour = { 188, 176, 160 }, material = "Plaster", penetration = "solid", solid = true },
	tower = { colour = { 92, 110, 128 }, material = "Concrete", penetration = "solid", solid = true },
	crane = { colour = { 232, 174, 36 }, material = "Metal", penetration = "solid", solid = true },
	sign = { colour = { 40, 44, 54 }, material = "SmoothPlastic", penetration = "solid", solid = false },
	light = { colour = { 255, 238, 206 }, material = "Neon", penetration = "solid", solid = false },
	step = { colour = { 160, 152, 142 }, material = "Concrete", penetration = "solid", solid = false },
} :: { [string]: Look }

-- How high the middle of a tree's leaves is, their underside above a
-- jumping player's head (0.85 m on 1.8 m), and how far out from its trunk
-- they reach.
MapKit.CANOPY = 4.6
MapKit.CANOPY_RADIUS = 2.1

-- Each piece's looks, by number.
local WOOD: { Colour } = { { 178, 134, 84 }, { 150, 112, 72 }, { 198, 162, 106 } }
local STEEL: { Colour } = { { 170, 66, 48 }, { 52, 98, 152 }, { 66, 126, 92 }, { 214, 126, 44 }, { 126, 130, 140 } }
local DRUMS: { Colour } = { { 52, 92, 162 }, { 174, 56, 44 }, { 216, 172, 44 } }
local STONE: { Colour } = { { 190, 182, 166 }, { 168, 160, 150 } }
local LEAVES: { Colour } = { { 82, 132, 64 }, { 104, 142, 58 } }

local function scaled(c: Colour, by: number): Colour
	return { math.floor(c[1] * by + 0.5), math.floor(c[2] * by + 0.5), math.floor(c[3] * by + 0.5) }
end

-- Which of a piece's looks a piece of cover takes: its own, or else one
-- that follows from its name, so the same map always looks the same.
function MapKit.lookOf(piece: string, name: string, look: number?): number
	local info = MapKit.Pieces[piece]
	local count = if info then info.looks else 1
	if look then
		return (look - 1) % count + 1
	end
	local sum = 0
	for i = 1, #name do
		sum += string.byte(name, i) * i
	end
	return sum % count + 1
end

-- A piece's look: its parts as they show, for a box `size` across its
-- longer side (x), up (y) and across its shorter side (z), and the `look`th
-- of its looks. Everything stays inside the box, but a tree's trunk and
-- leaves, which are over it.
function MapKit.bits(piece: string, size: vector, look: number): { Bit }
	local L, H, W = size.x, size.y, size.z
	local out: { Bit } = {}
	local function bit(
		name: string,
		x: number,
		y: number,
		z: number,
		sx: number,
		sy: number,
		sz: number,
		colour: Colour,
		material: string,
		shape: Shape?
	)
		table.insert(out, {
			name = name,
			offset = vector.create(x, y, z),
			size = vector.create(sx, sy, sz),
			colour = colour,
			material = material,
			shape = shape or "block",
		})
	end

	-- A crate from y0 to y0 + h: planks, a post at each corner, a band
	-- round its middle and a lid.
	local function crate(prefix: string, y0: number, h: number, wood: Colour)
		local dark = scaled(wood, 0.62)
		bit(prefix .. "Body", 0, y0 + h / 2, 0, L - 0.08, h - 0.04, W - 0.08, wood, "WoodPlanks")
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				bit(prefix .. "Post", sx * (L / 2 - 0.07), y0 + h / 2, sz * (W / 2 - 0.07), 0.14, h, 0.14, dark, "Wood")
			end
		end
		bit(prefix .. "Band", 0, y0 + h / 2, 0, L, 0.12, W, dark, "Wood")
		bit(prefix .. "Lid", 0, y0 + h - 0.03, 0, L - 0.02, 0.06, W - 0.02, dark, "Wood")
	end

	-- A stone planter's box and the cap round its top, to `top` metres.
	local function planter(top: number, stone: Colour)
		bit("Box", 0, (top - 0.1) / 2, 0, L - 0.04, top - 0.1, W - 0.04, stone, "Concrete")
		bit("Cap", 0, top - 0.05, 0, L, 0.1, W, scaled(stone, 1.08), "Concrete")
	end

	if piece == "Crate" then
		crate("", 0, H, WOOD[look] or WOOD[1])
	elseif piece == "CrateStack" then
		local wood = WOOD[look] or WOOD[1]
		crate("Lower", 0, H / 2, wood)
		crate("Upper", H / 2, H / 2, scaled(wood, 1.1))
	elseif piece == "Container" then
		local steel = STEEL[look] or STEEL[1]
		local shade, dark = scaled(steel, 0.84), scaled(steel, 0.55)
		bit("Body", 0, H / 2, 0, L - 0.1, H - 0.1, W - 0.1, steel, "Metal")
		-- The corrugation down both long sides.
		local n = math.max(1, math.floor((L - 0.8) / 0.5))
		local step = (L - 0.8) / n
		for k = 0, n do
			for _, s in { -1, 1 } do
				bit("Rib", -L / 2 + 0.4 + k * step, H / 2, s * (W / 2 - 0.04), 0.12, H - 0.36, 0.06, shade, "Metal")
			end
		end
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				bit("Corner", sx * (L / 2 - 0.08), H / 2, sz * (W / 2 - 0.08), 0.16, H, 0.16, dark, "Metal")
			end
		end
		for _, y in { 0.08, H - 0.08 } do
			for _, s in { -1, 1 } do
				bit("Rail", 0, y, s * (W / 2 - 0.06), L, 0.16, 0.12, dark, "Metal")
			end
		end
		-- The doors at one end, with their locking bars.
		for _, s in { -1, 1 } do
			bit("Door", L / 2 - 0.06, H / 2, s * W / 4, 0.06, H - 0.36, W / 2 - 0.2, shade, "Metal")
			for _, k in { -1, 1 } do
				bit("Bar", L / 2 - 0.03, H / 2, s * W / 4 + k * W / 10, 0.05, H - 0.5, 0.05, dark, "Metal")
			end
		end
	elseif piece == "Barrels" then
		local drum = DRUMS[look] or DRUMS[1]
		bit("Pallet", 0, 0.07, 0, L, 0.14, W, WOOD[2], "WoodPlanks")
		local cols, rows = math.max(1, math.floor(L / 0.6)), math.max(1, math.floor(W / 0.6))
		local dx, dz = L / cols, W / rows
		local d = math.min(dx, dz) - 0.04
		local h = H - 0.14
		for i = 1, cols do
			for j = 1, rows do
				local x, z = -L / 2 + (i - 0.5) * dx, -W / 2 + (j - 0.5) * dz
				bit("Drum", x, 0.14 + h / 2, z, d, h, d, drum, "Metal", "cylinder")
				for _, at in { 0.3, 0.7 } do
					bit("Hoop", x, 0.14 + h * at, z, d + 0.02, 0.05, d + 0.02, scaled(drum, 0.6), "Metal", "cylinder")
				end
			end
		end
	elseif piece == "Planter" or piece == "Hedge" then
		local stone = STONE[look] or STONE[1]
		planter(0.95, stone)
		bit("Hedge", 0, 0.95 + (H - 0.95) / 2, 0, L - 0.12, H - 0.95, W - 0.12, LEAVES[look] or LEAVES[1], "LeafyGrass")
	elseif piece == "Tree" then
		local stone = STONE[look] or STONE[1]
		local leaves = LEAVES[look] or LEAVES[1]
		planter(H - 0.02, stone)
		bit("Soil", 0, H - 0.025, 0, L - 0.4, 0.05, W - 0.4, { 92, 70, 52 }, "Ground")
		bit("Trunk", 0, H + 1.1, 0, 0.36, 2.2, 0.36, { 104, 78, 58 }, "Wood", "cylinder")
		bit("Leaves", 0, MapKit.CANOPY, 0, 3.4, 3.4, 3.4, leaves, "LeafyGrass", "ball")
		bit("Leaves", 0.7, MapKit.CANOPY + 0.9, -0.5, 2.4, 2.4, 2.4, scaled(leaves, 1.12), "LeafyGrass", "ball")
	end
	return out
end

return MapKit
