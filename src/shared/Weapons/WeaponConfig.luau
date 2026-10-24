--!strict
-- Weapon definitions. Same status convention as MovementConfig:
--   "confirmed" - Riot patch notes / dev blog / in-game
--   "community" - wiki or fan-site stat pages (they mirror the in-game Arsenal screen)
--   "estimate"  - ours; to be measured (docs/research/02-weapon-firing.md)
--
-- Speeds are multipliers of MovementConfig.Params.baseRunSpeed (6.75 m/s, the
-- knife speed). Damage bands are per hit, by distance in metres; beyond the
-- last band the last band applies. Angles (spread, recoil) are degrees; see
-- docs/research/03-spread-recoil.md for what each accuracy value means.
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

-- Piecewise-linear curve: { {x, y}, ... } with ascending x, flat beyond the
-- first and last points. Accuracy curves are indexed by bullet number in the
-- spray (1 = first shot) and, like the reference's, have values between
-- bullets, because a partly recovered spray sits between two bullets.
export type Curve = { { number } }
export type CurveParam = { points: Curve, status: Status, source: string }

export type AccuracyDef = {
	-- Firing error: radius of the cone of fire by bullet number.
	firingError: CurveParam,
	scopedFiringError: CurveParam?, -- replaces firingError while scoped (snipers)
	adsReduction: Param, -- taken off firingError while aiming down sights (flat, per Riot)
	crouchMultiplier: Param, -- firingError multiplier while crouched (percentage, per Riot)
	recoveryTime: Param, -- Gun Recovery Time: wait this long and the next shot is a first shot again
	tapEfficiency: Param, -- how fast a partly waited-out spray recovers; higher = taps accrue less
	-- Movement error, added on top (the reference applies movement penalties
	-- additively). Which one applies is a binary state, see Accuracy.
	runError: Param,
	walkError: Param,
	crouchMoveError: Param,
	airError: Param,
}

export type RecoilDef = {
	pitch: CurveParam, -- how far above the aim the bullet goes, by bullet number
	swayStart: Param, -- bullets after this one drift sideways
	swayStep: Param, -- sideways drift per bullet
	swayMax: Param, -- the drift reverses at this offset
	swayFlipChance: Param, -- chance per bullet that the drift reverses early
	runPitchMultiplier: Param, -- vertical recoil multiplier while running
	crouchYawMultiplier: Param, -- sideways recoil multiplier while crouched and still
	adsMultiplier: Param, -- recoil multiplier while aiming down sights or scoped
	cameraFraction: Param, -- share of the recoil the view follows, hip fire
	adsCameraFraction: Param, -- the same aiming down sights or scoped
}

export type DamageBand = { maxRange: number, head: number, body: number, legs: number }

export type AdsDef = {
	zoom: { number }, -- zoom levels cycled by alt-fire (FOV divisor)
	fireRateMultiplier: Param,
	moveMultiplier: Param,
}

export type WeaponDef = {
	id: string,
	name: string,
	slot: number, -- 1 primary, 2 secondary, 3 melee
	fireMode: "auto" | "semi" | "none",
	fireRate: Param, -- rounds per second
	magazine: Param,
	reserve: Param,
	reloadTime: Param,
	equipTime: Param,
	moveMultiplier: Param,
	deadzoneFraction: Param?, -- overrides MovementConfig deadzone
	damage: { DamageBand },
	damageSource: Param, -- status/source for the whole damage table (value unused)
	penetration: "none" | "low" | "medium" | "high",
	ads: AdsDef?,
	accuracy: AccuracyDef,
	recoil: RecoilDef,
}

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local function c(points: Curve, status: Status, source: string): CurveParam
	return { points = points, status = status, source = source }
end

local METABOT = "metabot.gg weapon page (mirrors the in-game Arsenal stats)"
local P050 = "Patch 0.50"
local P202 = "Patch 2.02"
local P30 = "Patch 3.0"
local P611 = "Patch 6.11"
local P910 = "Patch 9.10 (quoted by esports.gg and Sportskeeda)"
local CLASSICK = "Riot lead gameplay designer (Sportskeeda, Jul 2020): 'ADS provides a flat spread reduction, while crouch provides a percentage reduction'"

local WeaponConfig = {}

WeaponConfig.Slots = { Primary = 1, Secondary = 2, Melee = 3 }

local ADS_RIFLE: AdsDef = {
	zoom = { 1.25 },
	fireRateMultiplier = p(0.9, "community", "PC Gamer gun guide: Vandal ADS 8.32 rps vs 9.25 hip, Phantom 9.9 vs 11"),
	moveMultiplier = p(0.76, "estimate", "Not published for rifles; measure ADS walk speed"),
}

-- Movement error is set per weapon class ("All Rifles" in the patch notes).
local RIFLE_RUN = p(6, "confirmed", P910 .. ": rifles 'Run Inaccuracy: 5 >> 6'")
local RIFLE_WALK = p(3, "confirmed", P910 .. ": rifles 'Walk Inaccuracy: 2 >>> 3'")
local RIFLE_CROUCH_MOVE = p(0.8, "confirmed", P202 .. ": rifle crouch-moving error 0.3 to 0.8 (no later change found)")
local RIFLE_AIR = p(8, "estimate", "Not published; the reference orders the penalties crouch-move < walk < run < airborne (Fandom, Weapons)")
local RIFLE_CROUCH = p(0.85, "community", "gamer.org: 0.2 deg standing, 0.17 crouched (Phantom). " .. CLASSICK)
local PISTOL_CROUCH_MOVE = p(0.5, "confirmed", P910 .. ": all pistols 'Moving while crouching Inaccuracy: .1 >>> .5'")

WeaponConfig.Defs = {
	vandal = {
		id = "vandal",
		name = "Vandal",
		slot = 1,
		fireMode = "auto",
		fireRate = p(9.75, "community", METABOT),
		magazine = p(25, "community", METABOT),
		reserve = p(75, "community", "Liquipedia Vandal: ammo capacity 75"),
		reloadTime = p(2.5, "community", METABOT),
		equipTime = p(1.0, "community", METABOT),
		moveMultiplier = p(0.80, "community", METABOT .. " (80% = 5.40 m/s)"),
		damage = { { maxRange = 50, head = 160, body = 40, legs = 34 } },
		damageSource = p(0, "community", "Liquipedia / metabot: 160/40/34, no falloff"),
		penetration = "medium",
		ads = ADS_RIFLE,
		accuracy = {
			firingError = c(
				{ { 1, 0.25 }, { 3, 0.3 }, { 4, 0.55 }, { 5, 0.9 }, { 7, 1.3 }, { 10, 1.7 }, { 15, 2.0 }, { 25, 2.2 } },
				"estimate",
				"Bullet 1 is the community 0.25 deg (metabot). The rest is our shape: tight for three bullets, jumping at bullets 4 to 5 (gamer.org), then levelling off"
			),
			adsReduction = p(0.093, "community", "Sportskeeda, 2020: first bullet 0.25 hip, 0.157 ADS. " .. CLASSICK),
			crouchMultiplier = RIFLE_CROUCH,
			recoveryTime = p(0.375, "confirmed", P050 .. ": Vandal 'Gun Recovery Time: .4s >> .375s'"),
			tapEfficiency = p(6, "confirmed", P050 .. ": Vandal 'Tap Efficiency: 4 >> 6'"),
			runError = RIFLE_RUN,
			walkError = RIFLE_WALK,
			crouchMoveError = RIFLE_CROUCH_MOVE,
			airError = RIFLE_AIR,
		},
		recoil = {
			pitch = c(
				{ { 1, 0 }, { 2, 0.3 }, { 3, 0.75 }, { 4, 1.4 }, { 6, 2.8 }, { 9, 4.6 }, { 12, 5.6 }, { 16, 6.1 }, { 25, 6.4 } },
				"estimate",
				"Shape only: the spray always climbs, then levels off into a T (esports.net spray guide). Measure from a spray against a wall"
			),
			swayStart = p(8, "estimate", "Riot: 'the first several bullets have fully deterministic recoil' (Riot_Classick, quoted by turbosmurfs.gg); the Ares and Odin notes count yaw recoil 'after the first 8 bullets'"),
			swayStep = p(0.55, "estimate", "Sideways drift per bullet; measure"),
			swayMax = p(2.6, "estimate", "Half the width of the top of the T; measure"),
			swayFlipChance = p(0.12, "estimate", "The drift direction is random and can switch (esports.net); measure how often"),
			runPitchMultiplier = p(1.8, "confirmed", P611 .. ": 'Vertical Recoil Multiplier While Running', Vandal 1.5 >>> 1.8"),
			crouchYawMultiplier = p(0.85, "confirmed", P050 .. ": Vandal 'Horizontal (Yaw) Recoil reduced by 15% while crouched and stationary'"),
			adsMultiplier = p(0.9, "estimate", "Fandom (Phantom): ADS reduces recoil and spread; the amount is not published"),
			cameraFraction = p(0.25, "estimate", "In hip fire the bullets climb away from the crosshair (esports.net); measure crosshair travel against impact travel"),
			adsCameraFraction = p(0.9, "estimate", "ADS 'keeps shots on target' and 'amplifies screen movement' (esports.net)"),
		},
	},
	phantom = {
		id = "phantom",
		name = "Phantom",
		slot = 1,
		fireMode = "auto",
		fireRate = p(11, "community", METABOT),
		magazine = p(30, "community", METABOT),
		reserve = p(60, "estimate", "Two magazines assumed"),
		reloadTime = p(2.5, "community", METABOT),
		equipTime = p(1.0, "community", METABOT),
		moveMultiplier = p(0.80, "community", METABOT),
		damage = {
			{ maxRange = 20, head = 156, body = 39, legs = 33 },
			{ maxRange = 50, head = 140, body = 35, legs = 30 },
		},
		damageSource = p(0, "community", "Body and the 20 m boundary are Patch 9.10 (quoted by Sportskeeda): 'Now does 39 damage per bullet from 0-20m and 35 damage per bullet 20m+'; head 156 / 140 and legs 33 / 30 from metabot"),
		penetration = "medium",
		ads = ADS_RIFLE,
		accuracy = {
			firingError = c(
				{ { 1, 0.2 }, { 3, 0.24 }, { 4, 0.42 }, { 5, 0.7 }, { 7, 1.05 }, { 10, 1.4 }, { 15, 1.65 }, { 30, 1.8 } },
				"estimate",
				"Bullet 1 is the community 0.2 deg (metabot). The rest is our shape, the Vandal's but tighter (Fandom: 'low spread')"
			),
			adsReduction = p(0.09, "community", "Sportskeeda, 2020: first bullet 0.20 hip, 0.11 ADS. " .. CLASSICK),
			crouchMultiplier = RIFLE_CROUCH,
			recoveryTime = p(0.35, "confirmed", P050 .. ": Phantom 'Gun Recovery Time: .55s >> .35s'"),
			tapEfficiency = p(4, "confirmed", P050 .. ": Phantom 'Tap Efficiency: 3 >> 4'"),
			runError = RIFLE_RUN,
			walkError = RIFLE_WALK,
			crouchMoveError = RIFLE_CROUCH_MOVE,
			airError = RIFLE_AIR,
		},
		recoil = {
			pitch = c(
				{ { 1, 0 }, { 2, 0.25 }, { 3, 0.6 }, { 4, 1.15 }, { 6, 2.3 }, { 9, 3.9 }, { 12, 4.8 }, { 16, 5.2 }, { 30, 5.5 } },
				"estimate",
				"The same T, a little lower than the Vandal's (pull down 'head to waist' against 'head to thigh', gamer.org)"
			),
			swayStart = p(9, "estimate", "See the Vandal; the Phantom is described as easier to control"),
			swayStep = p(0.45, "estimate", "Sideways drift per bullet; measure"),
			swayMax = p(2.2, "estimate", "Half the width of the top of the T; measure"),
			swayFlipChance = p(0.12, "estimate", "The drift direction is random and can switch (esports.net); measure how often"),
			runPitchMultiplier = p(1.8, "confirmed", P611 .. ": 'Vertical Recoil Multiplier While Running', Phantom 1.5 >>> 1.8"),
			crouchYawMultiplier = p(0.85, "confirmed", P050 .. ": the Vandal's crouched yaw reduction 'matches the crouch benefits of other rifles'"),
			adsMultiplier = p(0.9, "estimate", "Fandom: ADS 'further reduces recoil and spread'; the amount is not published"),
			cameraFraction = p(0.25, "estimate", "As the Vandal"),
			adsCameraFraction = p(0.9, "estimate", "As the Vandal"),
		},
	},
	operator = {
		id = "operator",
		name = "Operator",
		slot = 1,
		fireMode = "semi",
		fireRate = p(0.6, "confirmed", "Patch 1.09: 'Firing rate reduced from .75 >>> .6'"),
		magazine = p(5, "community", METABOT),
		reserve = p(10, "estimate", "Two magazines assumed"),
		reloadTime = p(3.7, "community", METABOT),
		equipTime = p(1.5, "community", METABOT),
		moveMultiplier = p(0.76, "community", METABOT .. " (76% = 5.13 m/s)"),
		deadzoneFraction = p(0.15, "confirmed", "Patch 1.09: deadzone 30% >>> 15%"),
		damage = { { maxRange = 50, head = 255, body = 150, legs = 120 } },
		damageSource = p(0, "confirmed", "Patch 1.09 leg 127 >>> 120; head/body from metabot"),
		penetration = "high",
		ads = {
			zoom = { 2.5, 5 },
			fireRateMultiplier = p(1.0, "estimate", "Bolt action; scoping assumed not to change cadence"),
			moveMultiplier = p(0.72, "confirmed", "Patch 1.09: scoped movement speed 76% >>> 72%"),
		},
		accuracy = {
			firingError = c({ { 1, 5 } }, "community", "metabot: first bullet accuracy 5 deg (gamer.org: '5 deg deviation' unscoped)"),
			scopedFiringError = c({ { 1, 0 } }, "community", "Fandom, Weapons: snipers have no first-shot spread when scoped"),
			adsReduction = p(0, "estimate", "Unused: the scoped curve replaces the hip one"),
			crouchMultiplier = p(0.85, "estimate", "Assumed like rifles"),
			recoveryTime = p(1.0, "estimate", "Not published; shorter than the 1.67 s bolt cycle, so every shot is a first shot"),
			tapEfficiency = p(1, "estimate", "Not used by a bolt action"),
			runError = p(9, "estimate", "Not published for snipers; worse than rifles to match the 15% deadzone"),
			walkError = p(4.5, "estimate", "Not published for snipers"),
			crouchMoveError = p(2, "estimate", "Not published for snipers"),
			airError = p(12, "estimate", "Not published for snipers"),
		},
		recoil = {
			pitch = c({ { 1, 0 }, { 2, 2.5 } }, "estimate", "The kick after a shot, recovered before the bolt is back"),
			swayStart = p(99, "estimate", "No sideways drift"),
			swayStep = p(0, "estimate", "No sideways drift"),
			swayMax = p(0, "estimate", "No sideways drift"),
			swayFlipChance = p(0, "estimate", "No sideways drift"),
			runPitchMultiplier = p(1, "estimate", "Not published"),
			crouchYawMultiplier = p(1, "estimate", "No sideways recoil"),
			adsMultiplier = p(1, "estimate", "Not published"),
			cameraFraction = p(0.5, "estimate", "Measure"),
			adsCameraFraction = p(1, "estimate", "The scope kicks with the shot; measure"),
		},
	},
	classic = {
		id = "classic",
		name = "Classic",
		slot = 2,
		fireMode = "semi",
		fireRate = p(6.75, "community", METABOT),
		magazine = p(12, "community", METABOT),
		reserve = p(36, "estimate", "Three magazines assumed"),
		reloadTime = p(1.75, "community", METABOT),
		equipTime = p(0.75, "community", METABOT),
		moveMultiplier = p(0.85, "community", METABOT),
		damage = {
			{ maxRange = 30, head = 78, body = 26, legs = 22 },
			{ maxRange = 50, head = 66, body = 22, legs = 19 },
		},
		damageSource = p(0, "community", METABOT),
		penetration = "low",
		ads = nil, -- the reference's alt-fire is a 3-round burst; not implemented yet
		accuracy = {
			firingError = c({ { 1, 0.4 }, { 2, 0.55 }, { 3, 0.9 }, { 5, 1.6 }, { 8, 2.2 } }, "estimate", "Bullet 1 is the community 0.4 deg (metabot); the rest is ours"),
			adsReduction = p(0, "estimate", "No ADS"),
			crouchMultiplier = p(0.85, "estimate", "Assumed like rifles"),
			recoveryTime = p(0.3, "estimate", "Not published"),
			tapEfficiency = p(2, "estimate", "Not published"),
			runError = p(2.3, "confirmed", P910 .. ": Classic 'Run Inaccuracy: 2 >>> 2.3'"),
			walkError = p(1.1, "confirmed", P910 .. ": Classic 'Walking Inaccuracy: 0.84 >>> 1.1'"),
			crouchMoveError = PISTOL_CROUCH_MOVE,
			airError = p(3.5, "estimate", "Not published for the left click (the right-click burst's jumping value is 2.25, Patch 9.10)"),
		},
		recoil = {
			pitch = c({ { 1, 0 }, { 2, 0.4 }, { 3, 0.9 }, { 5, 1.8 }, { 8, 2.6 } }, "estimate", "Measure"),
			swayStart = p(2, "estimate", "Pistols kick sideways from the start; measure"),
			swayStep = p(0.3, "estimate", "Measure"),
			swayMax = p(1.0, "estimate", "Measure"),
			swayFlipChance = p(0.3, "estimate", "Measure"),
			runPitchMultiplier = p(1, "estimate", "Patch 6.11 lists rifles, the Spectre and the Frenzy only"),
			crouchYawMultiplier = p(0.85, "estimate", "Assumed like rifles"),
			adsMultiplier = p(1, "estimate", "No ADS"),
			cameraFraction = p(0.3, "estimate", "Measure"),
			adsCameraFraction = p(0.3, "estimate", "No ADS"),
		},
	},
	sheriff = {
		id = "sheriff",
		name = "Sheriff",
		slot = 2,
		fireMode = "semi",
		fireRate = p(4, "community", METABOT),
		magazine = p(6, "community", METABOT),
		reserve = p(24, "estimate", "Four magazines assumed"),
		reloadTime = p(2.25, "community", METABOT),
		equipTime = p(1.0, "community", METABOT),
		moveMultiplier = p(0.80, "community", METABOT),
		damage = {
			{ maxRange = 30, head = 160, body = 55, legs = 47 },
			{ maxRange = 50, head = 145, body = 50, legs = 43 },
		},
		damageSource = p(0, "community", METABOT),
		penetration = "high",
		ads = {
			zoom = { 1.25 },
			fireRateMultiplier = p(1.0, "estimate", "Assumed unchanged"),
			moveMultiplier = p(0.76, "estimate", "Assumed same as rifles"),
		},
		accuracy = {
			firingError = c({ { 1, 0.25 }, { 2, 1.0 }, { 3, 2.0 }, { 4, 3.0 }, { 6, 3.6 } }, "estimate", "Bullet 1 is the community 0.25 deg (metabot); the follow-ups are ours, spamming is meant to be wild"),
			adsReduction = p(0.1, "estimate", "Fandom: ADS modes have lower spread; the amount is not published"),
			crouchMultiplier = p(0.85, "estimate", "Assumed like rifles"),
			recoveryTime = p(0.45, "estimate", "Not published; longer than the 0.25 s fire interval"),
			tapEfficiency = p(1.5, "estimate", "Not published"),
			runError = p(3, "confirmed", P30 .. ": Sheriff 'Running inaccuracy changed from 2.0 >>> 3.0' (Patch 9.10 did not list the Sheriff)"),
			walkError = p(1.2, "confirmed", P30 .. ": Sheriff 'Walking inaccuracy changed from .25 >>> 1.2'"),
			crouchMoveError = PISTOL_CROUCH_MOVE,
			airError = p(4.5, "estimate", "Not published"),
		},
		recoil = {
			pitch = c({ { 1, 0 }, { 2, 1.6 }, { 3, 3.0 }, { 4, 4.0 }, { 6, 4.8 } }, "estimate", "A big kick per shot; measure"),
			swayStart = p(2, "estimate", "Measure"),
			swayStep = p(0.6, "estimate", "Measure"),
			swayMax = p(1.5, "estimate", "Measure"),
			swayFlipChance = p(0.35, "estimate", "Measure"),
			runPitchMultiplier = p(1, "estimate", "Patch 6.11 lists rifles, the Spectre and the Frenzy only"),
			crouchYawMultiplier = p(0.85, "estimate", "Assumed like rifles"),
			adsMultiplier = p(0.9, "estimate", "Assumed like rifles"),
			cameraFraction = p(0.35, "estimate", "Measure"),
			adsCameraFraction = p(0.8, "estimate", "Measure"),
		},
	},
	knife = {
		id = "knife",
		name = "Knife",
		slot = 3,
		fireMode = "none", -- melee attacks are a later system
		fireRate = p(0, "estimate", "Not implemented"),
		magazine = p(0, "estimate", "n/a"),
		reserve = p(0, "estimate", "n/a"),
		reloadTime = p(0, "estimate", "n/a"),
		equipTime = p(0.75, "estimate", "Not published"),
		moveMultiplier = p(1.0, "community", "Fandom Melee: 'standard run speed of 6.75 m/s'"),
		damage = { { maxRange = 0, head = 0, body = 0, legs = 0 } },
		damageSource = p(0, "estimate", "n/a"),
		penetration = "none",
		ads = nil,
		accuracy = {
			firingError = c({ { 1, 0 } }, "estimate", "n/a"),
			adsReduction = p(0, "estimate", "n/a"),
			crouchMultiplier = p(1, "estimate", "n/a"),
			recoveryTime = p(0.1, "estimate", "n/a"),
			tapEfficiency = p(1, "estimate", "n/a"),
			runError = p(0, "estimate", "n/a"),
			walkError = p(0, "estimate", "n/a"),
			crouchMoveError = p(0, "estimate", "n/a"),
			airError = p(0, "estimate", "n/a"),
		},
		recoil = {
			pitch = c({ { 1, 0 } }, "estimate", "n/a"),
			swayStart = p(99, "estimate", "n/a"),
			swayStep = p(0, "estimate", "n/a"),
			swayMax = p(0, "estimate", "n/a"),
			swayFlipChance = p(0, "estimate", "n/a"),
			runPitchMultiplier = p(1, "estimate", "n/a"),
			crouchYawMultiplier = p(1, "estimate", "n/a"),
			adsMultiplier = p(1, "estimate", "n/a"),
			cameraFraction = p(0, "estimate", "n/a"),
			adsCameraFraction = p(0, "estimate", "n/a"),
		},
	},
} :: { [string]: WeaponDef }

-- Stable byte ids for the wire format (0 = empty slot).
WeaponConfig.Ids = { "classic", "knife", "operator", "phantom", "sheriff", "vandal" }
WeaponConfig.IndexOf = {} :: { [string]: number }
for i, id in WeaponConfig.Ids do
	WeaponConfig.IndexOf[id] = i
end

WeaponConfig.DefaultLoadout = { "vandal", "classic", "knife" }

-- Player survivability (shields add to health and absorb damage first).
WeaponConfig.Health = {
	maxHealth = p(100, "community", "Standard agent health"),
	heavyShield = p(50, "community", "Heavy Shields: 50"),
	lightShield = p(25, "community", "Light Shields: 25"),
	-- Hit slow ("tagging"). Riot's netcode blog confirms hits briefly slow the
	-- victim and Patch 3.0 gives the amount; the duration is ours.
	tagSpeedMultiplier = p(0.275, "confirmed", P30 .. ": 'Bullet tagging changed from 75% slow >>> 72.5% slow'"),
	tagDuration = p(0.15, "estimate", "Not published; measure from footage of a tagged player"),
}

WeaponConfig.MaxRange = 250 -- metres; bullets are hitscan

-- Accuracy rules shared by every weapon.
WeaponConfig.Accuracy = {
	-- Added to the cone for MovementConfig.jumpLandPenaltyTime after landing.
	landError = p(7, "confirmed", "Patch 1.09, all weapons: 'Jump land inaccuracy value increased from 5.0 >>> 7.0 (more inaccurate for .225s after a land)', a binary state"),
	-- Error power ("center biasing" at Riot) decides where in the cone a
	-- bullet lands: its distance from the centre is radius * u ^ power for a
	-- uniform random u. 0.5 spreads bullets evenly over the cone, 1 piles them
	-- toward the centre, and higher piles them more.
	errorPower = p(1, "estimate", P611 .. ": centre biasing works 'as intended for stationary firing'; the amount is not published"),
	moveErrorPower = p(0.6, "estimate", P611 .. ": shots fired while moving 'are now almost uniformly random within their spread cone'"),
}

function WeaponConfig.get(id: string): WeaponDef
	return WeaponConfig.Defs[id] or WeaponConfig.Defs.knife
end

-- Damage for one hit at a distance (metres) on a region.
function WeaponConfig.damageAt(def: WeaponDef, region: "head" | "body" | "legs", distance: number): number
	local bands = def.damage
	for _, band in bands do
		if distance <= band.maxRange then
			return band[region]
		end
	end
	return bands[#bands][region]
end

-- Hits to kill a target with `hp` total (health + shields) on one region.
function WeaponConfig.shotsToKill(def: WeaponDef, region: "head" | "body" | "legs", distance: number, hp: number): number?
	local dmg = WeaponConfig.damageAt(def, region, distance)
	if dmg <= 0 then
		return nil
	end
	return math.ceil(hp / dmg)
end

return WeaponConfig
