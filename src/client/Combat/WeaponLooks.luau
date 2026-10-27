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
	-- Blaze's flame (system 32): a tongue of fire standing up off the open
	-- hand, its tip on top.
	flamewall = {
		muzzle = vector.create(0, 0.08, -0.12),
		pieces = {
			{ size = vector.create(0.08, 0.1, 0.03), offset = vector.create(0, 0.06, -0.08), accent = true }, -- flame
			{ size = vector.create(0.04, 0.06, 0.02), offset = vector.create(0, 0.13, -0.08), accent = true }, -- tip
			{ size = vector.create(0.06, 0.02, 0.08), offset = vector.create(0, -0.005, -0.06) }, -- hand
		},
	},
	-- The Healing Orb (system 36): a green orb, larger than the flare's,
	-- floating over the open hand.
	healorb = {
		muzzle = vector.create(0, 0.07, -0.12),
		pieces = {
			{ size = vector.create(0.09, 0.09, 0.09), offset = vector.create(0, 0.07, -0.08), accent = true }, -- orb
			{ size = vector.create(0.06, 0.02, 0.08), offset = vector.create(0, -0.005, -0.06) }, -- hand
		},
	},
	-- The Slow Orb (system 37): a pale orb a little smaller than the
	-- Healing Orb's, a shard of ice standing up either side of it, over the
	-- open hand.
	iceorb = {
		muzzle = vector.create(0, 0.07, -0.12),
		pieces = {
			{ size = vector.create(0.08, 0.08, 0.08), offset = vector.create(0, 0.07, -0.08), accent = true }, -- orb
			{ size = vector.create(0.02, 0.06, 0.02), offset = vector.create(-0.055, 0.09, -0.08), accent = true }, -- shard
			{ size = vector.create(0.02, 0.06, 0.02), offset = vector.create(0.055, 0.09, -0.08), accent = true }, -- shard
			{ size = vector.create(0.06, 0.02, 0.08), offset = vector.create(0, -0.005, -0.06) }, -- hand
		},
	},
	-- The Barrier Orb (system 38): a pale orb the Slow Orb's size, a slab of
	-- ice standing behind it, over the open hand.
	wallorb = {
		muzzle = vector.create(0, 0.07, -0.12),
		pieces = {
			{ size = vector.create(0.08, 0.08, 0.08), offset = vector.create(0, 0.07, -0.08), accent = true }, -- orb
			{ size = vector.create(0.11, 0.07, 0.015), offset = vector.create(0, 0.08, -0.03), accent = true }, -- slab
			{ size = vector.create(0.06, 0.02, 0.08), offset = vector.create(0, -0.005, -0.06) }, -- hand
		},
	},
	-- The Resurrection's orb (system 39): a teal orb the Healing Orb's size,
	-- a ring of crystal shards round it, over the open hand.
	revive = {
		muzzle = vector.create(0, 0.07, -0.12),
		pieces = {
			{ size = vector.create(0.09, 0.09, 0.09), offset = vector.create(0, 0.07, -0.08), accent = true }, -- orb
			{ size = vector.create(0.02, 0.05, 0.02), offset = vector.create(-0.06, 0.07, -0.08), accent = true }, -- shard
			{ size = vector.create(0.02, 0.05, 0.02), offset = vector.create(0.06, 0.07, -0.08), accent = true }, -- shard
			{ size = vector.create(0.02, 0.05, 0.02), offset = vector.create(0, 0.13, -0.08), accent = true }, -- shard
			{ size = vector.create(0.06, 0.02, 0.08), offset = vector.create(0, -0.005, -0.06) }, -- hand
		},
	},
	-- Dark Cover's orb (system 40): a violet orb the Healing Orb's size, two
	-- wisps of shadow trailing up behind it, over the open hand.
	smokeorb = {
		muzzle = vector.create(0, 0.07, -0.12),
		pieces = {
			{ size = vector.create(0.09, 0.09, 0.09), offset = vector.create(0, 0.07, -0.08), accent = true }, -- orb
			{ size = vector.create(0.03, 0.07, 0.03), offset = vector.create(-0.03, 0.12, -0.04), accent = true }, -- wisp
			{ size = vector.create(0.03, 0.05, 0.03), offset = vector.create(0.03, 0.11, -0.03), accent = true }, -- wisp
			{ size = vector.create(0.06, 0.02, 0.08), offset = vector.create(0, -0.005, -0.06) }, -- hand
		},
	},
	-- Paranoia's orb (system 41): a darker orb the Healing Orb's size, a
	-- flat band of shadow through it, over the open hand.
	blindorb = {
		muzzle = vector.create(0, 0.07, -0.12),
		pieces = {
			{ size = vector.create(0.09, 0.09, 0.09), offset = vector.create(0, 0.07, -0.08), accent = true }, -- orb
			{ size = vector.create(0.16, 0.015, 0.16), offset = vector.create(0, 0.07, -0.08), accent = true }, -- band
			{ size = vector.create(0.06, 0.02, 0.08), offset = vector.create(0, -0.005, -0.06) }, -- hand
		},
	},
	-- Shrouded Step (system 42): no orb, a wisp of shadow curling up off the
	-- open hand.
	stepmark = {
		muzzle = vector.create(0, 0.07, -0.12),
		pieces = {
			{ size = vector.create(0.05, 0.05, 0.05), offset = vector.create(0, 0.035, -0.08), accent = true }, -- wisp
			{ size = vector.create(0.035, 0.06, 0.035), offset = vector.create(0.02, 0.08, -0.07), accent = true }, -- wisp
			{ size = vector.create(0.025, 0.05, 0.025), offset = vector.create(-0.005, 0.125, -0.06), accent = true }, -- wisp
			{ size = vector.create(0.06, 0.02, 0.08), offset = vector.create(0, -0.005, -0.06) }, -- hand
		},
	},
	-- From the Shadows' map (system 43): a slate of shadow over the open
	-- hand, a violet mark on it. The big map's up over it all the same.
	shadowmap = {
		muzzle = vector.create(0, 0.07, -0.12),
		pieces = {
			{ size = vector.create(0.15, 0.012, 0.11), offset = vector.create(0, 0.03, -0.09) }, -- slate
			{ size = vector.create(0.03, 0.014, 0.03), offset = vector.create(0.02, 0.038, -0.1), accent = true }, -- mark
			{ size = vector.create(0.06, 0.02, 0.08), offset = vector.create(0, -0.005, -0.06) }, -- hand
		},
	},
	-- The Recon Bolt's bow (system 44): a short bow stood upright, its
	-- limbs bending back from the grip, its string straight between their
	-- tips, and a bolt of light nocked beside the grip.
	bow = {
		muzzle = vector.create(-0.025, 0.03, -0.52),
		pieces = {
			{ size = vector.create(0.03, 0.14, 0.045), offset = vector.create(0, 0.02, -0.12) }, -- grip
			{ size = vector.create(0.02, 0.15, 0.03), offset = vector.create(0, 0.16, -0.105) }, -- upper limb
			{ size = vector.create(0.018, 0.06, 0.025), offset = vector.create(0, 0.26, -0.085) }, -- upper tip
			{ size = vector.create(0.02, 0.15, 0.03), offset = vector.create(0, -0.12, -0.105) }, -- lower limb
			{ size = vector.create(0.018, 0.06, 0.025), offset = vector.create(0, -0.22, -0.085) }, -- lower tip
			{ size = vector.create(0.004, 0.54, 0.004), offset = vector.create(0, 0.02, -0.07) }, -- string
			{ size = vector.create(0.012, 0.012, 0.42), offset = vector.create(-0.025, 0.03, -0.26), accent = true }, -- bolt
			{ size = vector.create(0.025, 0.025, 0.05), offset = vector.create(-0.025, 0.03, -0.49), accent = true }, -- head
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
	flamewall = "flamewall",
	healorb = "healorb",
	iceorb = "iceorb",
	wallorb = "wallorb",
	revive = "revive",
	smokeorb = "smokeorb",
	blindorb = "blindorb",
	stepmark = "stepmark",
	shadowmap = "shadowmap",
	bow = "bow",
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
	flamewall = Color3.fromRGB(255, 90, 20),
	healorb = Color3.fromRGB(110, 235, 150),
	iceorb = Color3.fromRGB(140, 220, 240),
	wallorb = Color3.fromRGB(185, 230, 250),
	revive = Color3.fromRGB(90, 230, 210),
	smokeorb = Color3.fromRGB(110, 70, 170),
	blindorb = Color3.fromRGB(64, 34, 102),
	stepmark = Color3.fromRGB(84, 52, 128),
	shadowmap = Color3.fromRGB(150, 110, 230),
	bow = Color3.fromRGB(110, 200, 255),
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
