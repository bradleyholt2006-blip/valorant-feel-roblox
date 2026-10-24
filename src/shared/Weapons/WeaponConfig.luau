--!strict
-- Weapon definitions. Same status convention as MovementConfig:
--   "confirmed" - Riot patch notes / dev blog / in-game
--   "community" - wiki or fan-site stat pages (they mirror the in-game Arsenal screen)
--   "estimate"  - ours; to be measured (docs/research/02-weapon-firing.md)
--
-- Speeds are multipliers of MovementConfig.Params.baseRunSpeed (6.75 m/s, the
-- knife speed). Damage bands are per hit, by distance in metres; beyond the
-- last band the last band applies.
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

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
}

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local METABOT = "metabot.gg weapon page (mirrors the in-game Arsenal stats)"

local WeaponConfig = {}

WeaponConfig.Slots = { Primary = 1, Secondary = 2, Melee = 3 }

local ADS_RIFLE: AdsDef = {
	zoom = { 1.25 },
	fireRateMultiplier = p(0.9, "community", "PC Gamer gun guide: Vandal ADS 8.32 rps vs 9.25 hip, Phantom 9.9 vs 11"),
	moveMultiplier = p(0.76, "estimate", "Not published for rifles; measure ADS walk speed"),
}

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
		damageSource = p(0, "community", METABOT),
		penetration = "medium",
		ads = ADS_RIFLE,
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
	-- victim; the amount is a wiki figure and the duration is ours.
	tagSpeedMultiplier = p(0.275, "community", "Fandom Weapons: 'tagged with a 72.5% slow'"),
	tagDuration = p(0.15, "estimate", "Not published; measure from footage of a tagged player"),
}

WeaponConfig.MaxRange = 250 -- metres; bullets are hitscan

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
