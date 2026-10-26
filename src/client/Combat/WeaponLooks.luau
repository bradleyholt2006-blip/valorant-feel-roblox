--!strict
-- Every weapon's stand-in look (original placeholder art): a shape made of a
-- few plain boxes, and an accent colour of its own so the guns can be told
-- apart. WeaponEffects builds it as the viewmodel; the buy menu draws it
-- side on.

export type Piece = { size: vector, offset: vector, accent: boolean? } -- metres, relative to the grip
export type Shape = { muzzle: vector, pieces: { Piece } }

local WeaponLooks = {}

local SHAPES: { [string]: Shape } = {
	rifle = {
		muzzle = vector.create(0, 0.03, -0.56),
		pieces = {
			{ size = vector.create(0.06, 0.09, 0.42), offset = vector.create(0, 0.02, -0.13) }, -- receiver
			{ size = vector.create(0.028, 0.028, 0.2), offset = vector.create(0, 0.03, -0.44) }, -- barrel
			{ size = vector.create(0.04, 0.14, 0.07), offset = vector.create(0, -0.09, -0.13), accent = true }, -- magazine
			{ size = vector.create(0.05, 0.08, 0.18), offset = vector.create(0, 0, 0.17) }, -- stock
			{ size = vector.create(0.035, 0.1, 0.04), offset = vector.create(0, -0.07, 0.03) }, -- grip
			{ size = vector.create(0.02, 0.03, 0.05), offset = vector.create(0, 0.08, -0.05), accent = true }, -- sight
		},
	},
	sniper = {
		muzzle = vector.create(0, 0.03, -0.78),
		pieces = {
			{ size = vector.create(0.065, 0.09, 0.5), offset = vector.create(0, 0.02, -0.15) },
			{ size = vector.create(0.03, 0.03, 0.36), offset = vector.create(0, 0.03, -0.58) },
			{ size = vector.create(0.05, 0.05, 0.26), offset = vector.create(0, 0.1, -0.12), accent = true }, -- scope
			{ size = vector.create(0.05, 0.09, 0.2), offset = vector.create(0, 0, 0.2) },
			{ size = vector.create(0.035, 0.1, 0.04), offset = vector.create(0, -0.07, 0.03) },
		},
	},
	pistol = {
		muzzle = vector.create(0, 0.03, -0.2),
		pieces = {
			{ size = vector.create(0.035, 0.05, 0.19), offset = vector.create(0, 0.03, -0.08) }, -- slide
			{ size = vector.create(0.032, 0.11, 0.05), offset = vector.create(0, -0.04, 0.0), accent = true }, -- grip
		},
	},
	knife = {
		muzzle = vector.create(0, 0, -0.25),
		pieces = {
			{ size = vector.create(0.012, 0.035, 0.2), offset = vector.create(0, 0, -0.15), accent = true }, -- blade
			{ size = vector.create(0.028, 0.03, 0.1), offset = vector.create(0, 0, 0) }, -- handle
		},
	},
	quietPistol = {
		muzzle = vector.create(0, 0.03, -0.33),
		pieces = {
			{ size = vector.create(0.035, 0.05, 0.19), offset = vector.create(0, 0.03, -0.08) }, -- slide
			{ size = vector.create(0.032, 0.11, 0.05), offset = vector.create(0, -0.04, 0.0), accent = true }, -- grip
			{ size = vector.create(0.03, 0.03, 0.13), offset = vector.create(0, 0.03, -0.24) }, -- suppressor
		},
	},
	sawnOff = {
		muzzle = vector.create(0, 0.03, -0.27),
		pieces = {
			{ size = vector.create(0.05, 0.07, 0.16), offset = vector.create(0, 0.025, -0.06) }, -- action
			{ size = vector.create(0.045, 0.035, 0.14), offset = vector.create(0, 0.035, -0.19) }, -- two barrels
			{ size = vector.create(0.032, 0.11, 0.05), offset = vector.create(0, -0.04, 0.02), accent = true }, -- grip
		},
	},
	smg = {
		muzzle = vector.create(0, 0.03, -0.42),
		pieces = {
			{ size = vector.create(0.055, 0.085, 0.3), offset = vector.create(0, 0.02, -0.1) }, -- receiver
			{ size = vector.create(0.026, 0.026, 0.12), offset = vector.create(0, 0.03, -0.31) }, -- barrel
			{ size = vector.create(0.035, 0.15, 0.05), offset = vector.create(0, -0.1, -0.08), accent = true }, -- magazine
			{ size = vector.create(0.03, 0.05, 0.14), offset = vector.create(0, 0, 0.12) }, -- stock
			{ size = vector.create(0.035, 0.1, 0.04), offset = vector.create(0, -0.07, 0.03) }, -- grip
		},
	},
	shotgun = {
		muzzle = vector.create(0, 0.035, -0.66),
		pieces = {
			{ size = vector.create(0.065, 0.09, 0.36), offset = vector.create(0, 0.02, -0.08) }, -- receiver
			{ size = vector.create(0.04, 0.04, 0.36), offset = vector.create(0, 0.035, -0.45) }, -- barrel
			{ size = vector.create(0.045, 0.045, 0.22), offset = vector.create(0, -0.02, -0.38), accent = true }, -- pump
			{ size = vector.create(0.05, 0.09, 0.2), offset = vector.create(0, -0.01, 0.2) }, -- stock
			{ size = vector.create(0.035, 0.1, 0.04), offset = vector.create(0, -0.07, 0.03) }, -- grip
		},
	},
	heavy = {
		muzzle = vector.create(0, 0.03, -0.7),
		pieces = {
			{ size = vector.create(0.08, 0.11, 0.48), offset = vector.create(0, 0.02, -0.12) }, -- receiver
			{ size = vector.create(0.035, 0.035, 0.3), offset = vector.create(0, 0.03, -0.52) }, -- barrel
			{ size = vector.create(0.09, 0.1, 0.12), offset = vector.create(0, -0.1, -0.12), accent = true }, -- box magazine
			{ size = vector.create(0.05, 0.09, 0.18), offset = vector.create(0, 0, 0.2) }, -- stock
			{ size = vector.create(0.035, 0.1, 0.04), offset = vector.create(0, -0.07, 0.03) }, -- grip
			{ size = vector.create(0.06, 0.02, 0.2), offset = vector.create(0, 0.085, -0.15) }, -- top cover
		},
	},
	-- The spike (system 12), held out in front: a squat case with a band of
	-- light round it (original stand-in, as the rest).
	spike = {
		muzzle = vector.create(0, 0.1, -0.14),
		pieces = {
			{ size = vector.create(0.16, 0.2, 0.16), offset = vector.create(0, 0.02, -0.14) }, -- case
			{ size = vector.create(0.17, 0.035, 0.17), offset = vector.create(0, 0.07, -0.14), accent = true }, -- light band
			{ size = vector.create(0.09, 0.03, 0.09), offset = vector.create(0, 0.135, -0.14) }, -- cap
		},
	},
	-- Blade Storm's knives (system 19): three thin blades held fanned out,
	-- their hilts together.
	kunai = {
		muzzle = vector.create(0, 0.015, -0.22),
		pieces = {
			{ size = vector.create(0.008, 0.028, 0.18), offset = vector.create(-0.035, 0, -0.1), accent = true },
			{ size = vector.create(0.008, 0.028, 0.2), offset = vector.create(0, 0.015, -0.11), accent = true },
			{ size = vector.create(0.008, 0.028, 0.18), offset = vector.create(0.035, 0, -0.1), accent = true },
			{ size = vector.create(0.09, 0.022, 0.03), offset = vector.create(0, 0, 0) }, -- hilts
		},
	},
	-- Curveball's flare (system 30): an orb of light held up in the hand.
	flare = {
		muzzle = vector.create(0, 0.05, -0.12),
		pieces = {
			{ size = vector.create(0.07, 0.07, 0.07), offset = vector.create(0, 0.05, -0.08), accent = true }, -- orb
			{ size = vector.create(0.045, 0.06, 0.07), offset = vector.create(0, -0.01, -0.03) }, -- hand
		},
	},
	-- Hot Hands' fireball (system 31): a ball of fire held up in the hand, a
	-- flame on top.
	fireball = {
		muzzle = vector.create(0, 0.06, -0.12),
		pieces = {
			{ size = vector.create(0.09, 0.09, 0.09), offset = vector.create(0, 0.06, -0.08), accent = true }, -- ball
			{ size = vector.create(0.05, 0.05, 0.05), offset = vector.create(0, 0.12, -0.08), accent = true }, -- flame
			{ size = vector.create(0.045, 0.06, 0.07), offset = vector.create(0, -0.01, -0.03) }, -- hand
		},
	},
}

-- Each weapon's shape and accent colour.
local SHAPE_OF: { [string]: string } = {
	classic = "pistol",
	shorty = "sawnOff",
	frenzy = "pistol",
	ghost = "quietPistol",
	bandit = "pistol",
	sheriff = "pistol",
	stinger = "smg",
	spectre = "smg",
	bucky = "shotgun",
	judge = "shotgun",
	bulldog = "rifle",
	guardian = "rifle",
	phantom = "rifle",
	vandal = "rifle",
	warden = "rifle",
	marshal = "sniper",
	outlaw = "sniper",
	operator = "sniper",
	ares = "heavy",
	odin = "heavy",
	knife = "knife",
	spike = "spike",
	kunai = "kunai",
	flare = "flare",
	fireball = "fireball",
}

local ACCENT: { [string]: Color3 } = {
	classic = Color3.fromRGB(150, 150, 160),
	shorty = Color3.fromRGB(170, 120, 80),
	frenzy = Color3.fromRGB(230, 120, 40),
	ghost = Color3.fromRGB(110, 140, 190),
	bandit = Color3.fromRGB(190, 80, 140),
	sheriff = Color3.fromRGB(210, 170, 70),
	stinger = Color3.fromRGB(230, 200, 60),
	spectre = Color3.fromRGB(80, 110, 200),
	bucky = Color3.fromRGB(150, 100, 60),
	judge = Color3.fromRGB(120, 160, 90),
	bulldog = Color3.fromRGB(160, 130, 90),
	guardian = Color3.fromRGB(90, 140, 110),
	phantom = Color3.fromRGB(60, 170, 170),
	vandal = Color3.fromRGB(200, 70, 60),
	warden = Color3.fromRGB(200, 200, 210),
	marshal = Color3.fromRGB(100, 170, 80),
	outlaw = Color3.fromRGB(180, 60, 60),
	operator = Color3.fromRGB(140, 90, 200),
	ares = Color3.fromRGB(110, 120, 70),
	odin = Color3.fromRGB(80, 80, 90),
	knife = Color3.fromRGB(190, 195, 205),
	spike = Color3.fromRGB(235, 70, 60),
	kunai = Color3.fromRGB(150, 230, 255),
	flare = Color3.fromRGB(255, 176, 80),
	fireball = Color3.fromRGB(255, 110, 30),
}
WeaponLooks.BODY = Color3.fromRGB(38, 40, 46)

function WeaponLooks.shape(id: string): Shape
	return SHAPES[SHAPE_OF[id] or "rifle"]
end

-- The colour of one of the weapon's pieces.
function WeaponLooks.colour(id: string, piece: Piece): Color3
	return if piece.accent then ACCENT[id] or WeaponLooks.BODY else WeaponLooks.BODY
end

function WeaponLooks.accent(id: string): Color3
	return ACCENT[id] or WeaponLooks.BODY
end

return WeaponLooks
