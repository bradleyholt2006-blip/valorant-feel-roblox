--!strict
-- Weapon definitions (systems 2, 3 and 9). Same status convention as MovementConfig:
--   "confirmed" - Riot patch notes / dev blog / in-game
--   "community" - wiki or fan-site stat pages (they mirror the in-game Arsenal screen)
--   "estimate"  - ours; to be measured (docs/research/02-weapon-firing.md, 09-arsenal.md)
--
-- Speeds are multipliers of MovementConfig.Params.baseRunSpeed (6.75 m/s, the
-- knife speed). Damage bands are per hit, or per pellet for a gun that fires
-- several at once, by distance in metres; beyond the last band the last band
-- applies. Angles (spread, recoil) are degrees; see
-- docs/research/03-spread-recoil.md for what each accuracy value means.
--
-- A weapon fires in up to three modes (WeaponConfig.mode): from the hip;
-- zoomed, aiming down sights or through a scope, which some guns fire in
-- bursts; and the Classic's right click. Each mode has its own cadence,
-- bullets per shot and accuracy.
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

-- The buy menu's groups, in its order.
-- "spike" is the spike (system 12), carried in the fourth slot and never sold.
-- "ultimate" is an ultimate's weapon (system 19: Jett's Blade Storm knives),
-- in the fifth slot while the ultimate lasts, and never sold either.
-- "ability" is an ability's (system 30: Phoenix's Curveball flare; system
-- 31: his Hot Hands fireball; system 32: his Blaze flame; system 36: Sage's
-- Healing Orb; system 37: her Slow Orb), in the fifth slot while it's in
-- hand, and never sold.
export type Category = "sidearm" | "smg" | "shotgun" | "rifle" | "sniper" | "heavy" | "melee" | "spike" | "ultimate" | "ability"

export type AccuracyDef = {
	-- Firing error: radius of the cone of fire by bullet number.
	firingError: CurveParam,
	crouchMultiplier: Param, -- firingError multiplier while crouched (percentage, per Riot)
	-- Gun Recovery Time: once the gun can fire again, waiting this long more
	-- makes the next shot a first shot again.
	recoveryTime: Param,
	tapEfficiency: Param, -- how fast a partly waited-out spray recovers; higher = taps accrue less
	-- Movement error, added on top (the reference applies movement penalties
	-- additively). Which one applies is a binary state, see Accuracy.
	runError: Param,
	walkError: Param,
	crouchMoveError: Param,
	airError: Param,
	-- The jump landing penalty, when it isn't WeaponConfig.Accuracy's (Blade
	-- Storm's knives are exact even then).
	landError: Param?,
}

export type RecoilDef = {
	pitch: CurveParam, -- how far above the aim the bullet goes, by bullet number
	swayStart: Param, -- bullets after this one drift sideways
	swayStep: Param, -- sideways drift per bullet
	swayMax: Param, -- the drift reverses at this offset
	swayFlipChance: Param, -- chance per bullet that the drift reverses early
	runPitchMultiplier: Param, -- vertical recoil multiplier while running
	crouchYawMultiplier: Param, -- sideways recoil multiplier while crouched and still
	adsMultiplier: Param, -- recoil multiplier while zoomed
	cameraFraction: Param, -- share of the recoil the view follows, hip fire
	adsCameraFraction: Param, -- the same zoomed
	-- How far the view jumps on each shot and settles back, on top of the
	-- recoil: visual only, for guns whose bullets don't climb (snipers).
	viewKick: Param?,
}

export type DamageBand = { maxRange: number, head: number, body: number, legs: number }

-- Wall penetration class, as the Arsenal lists it (Low / Medium / High).
export type PenetrationClass = "none" | "low" | "medium" | "high"

-- A burst: one trigger pull fires `rounds` rounds `rate` a second apart, and
-- holding the trigger fires `perSecond` bursts a second.
export type BurstDef = { rounds: Param, rate: Param, perSecond: Param }

export type AdsDef = {
	zoom: { number }, -- zoom levels cycled by alt-fire (FOV divisor)
	fireRateMultiplier: Param,
	moveMultiplier: Param,
	accuracy: AccuracyDef, -- replaces the hip accuracy while zoomed
	burst: BurstDef?, -- zoomed, the gun fires bursts (Stinger, Bulldog)
}

-- A right click that fires instead of zooming (the Classic's three bullets).
export type AltDef = {
	fireMode: "auto" | "semi",
	fireRate: Param, -- clicks per second
	pellets: Param, -- bullets per click
	ammo: Param, -- rounds a click uses; with fewer left it fires one bullet per round
	accuracy: AccuracyDef,
	recoil: RecoilDef,
}

-- A fire rate that rises while the trigger is held (the Odin), from fireRate
-- to maxRate over `time` seconds. Hip fire only.
export type SpinDef = { maxRate: Param, time: Param }

-- A knife attack (system 10): how often it comes, how far and how wide it
-- catches a target (Melee), and what it does from in front and from behind,
-- to any region.
export type SwingDef = {
	rate: Param, -- swings a second, held or clicked
	reach: Param, -- metres straight ahead of the eye
	radius: Param, -- metres either side of the aim
	front: Param, -- damage
	back: Param, -- damage to a target struck from behind
}

-- The knife's left click slashes, round a combo of three swings that loops,
-- and its right click stabs.
export type MeleeDef = {
	slash: SwingDef,
	stab: SwingDef,
	-- Seconds after the next slash could have come past which a slash starts
	-- the combo over.
	comboReset: Param,
}

export type WeaponDef = {
	id: string,
	name: string,
	category: Category,
	slot: number, -- 1 primary, 2 secondary, 3 melee, 4 the spike, 5 an ultimate's or an ability's weapon
	price: Param, -- credits
	fireMode: "auto" | "semi" | "none",
	fireRate: Param, -- rounds per second
	pellets: Param?, -- bullets per shot (shotguns), each with its own damage
	spinUp: SpinDef?,
	magazine: Param,
	reserve: Param,
	reloadTime: Param,
	reloadPerRound: Param?, -- loads one round at a time, this long each (Bucky, Marshal)
	reloadOneRound: Param?, -- a reload for a single missing round takes this long (Outlaw)
	equipTime: Param,
	moveMultiplier: Param,
	deadzoneFraction: Param?, -- overrides MovementConfig deadzone
	damage: { DamageBand },
	damageSource: Param, -- status/source for the whole damage table (value unused)
	penetration: PenetrationClass,
	suppressed: boolean, -- quiet, and its tracers aren't shown to anyone else
	ads: AdsDef?,
	alt: AltDef?,
	melee: MeleeDef?, -- swings instead of firing (the knife)
	spike: boolean?, -- the spike (system 12): planted, not fired (SpikeSim)
	-- An ultimate's weapon (system 19): put in hand by its cast, and never
	-- bought, dropped or reloaded (WeaponSim.arm).
	ultimate: boolean?,
	-- An ability's weapon (system 30: Curveball's flare; system 31: Hot Hands'
	-- fireball; system 32: Blaze's flame; system 36: the Healing Orb; system
	-- 37: the Slow Orb): the AbilityConfig id whose cast puts it in hand in
	-- the fifth slot. Like an ultimate's, never bought, dropped or reloaded,
	-- and gone once it's out of hand.
	ability: string?,
	accuracy: AccuracyDef,
	recoil: RecoilDef,
}

-- One way a weapon fires, put together from its definition (WeaponConfig.mode).
export type ModeName = "hip" | "zoom" | "alt"
export type Mode = {
	name: ModeName,
	fireMode: "auto" | "semi" | "none",
	rate: number, -- rounds per second (within a burst, for a burst)
	interval: number, -- seconds between rounds (within a burst)
	burstRounds: number, -- rounds one trigger pull fires: 1 unless the mode fires bursts
	burstInterval: number, -- seconds from a burst's first round to the next burst's
	pellets: number, -- bullets per round
	ammo: number, -- rounds one trigger pull uses
	spin: SpinDef?,
	accuracy: AccuracyDef,
	recoil: RecoilDef,
	zoomed: boolean,
}

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local function c(points: Curve, status: Status, source: string): CurveParam
	return { points = points, status = status, source = source }
end

local WIKI = "VALORANT Wiki (wiki.playvalorant.com, Weird Gloop)"
local METABOT = "metabot.gg weapon page (mirrors the in-game Arsenal stats)"
local BOTH = WIKI .. " and " .. METABOT
local P050 = "Patch 0.50"
local P109 = "Patch 1.09"
local P202 = "Patch 2.02"
local P30 = "Patch 3.0"
local P611 = "Patch 6.11"
local P910 = "Patch 9.10"
local P1200 = "Patch 12.00"
local P1301 = "Patch 13.01"
local P1306 = "Patch 13.06"
local P401 = "Patch 4.01"
local NAMU = "NamuWiki, VALORANT equipment page (the tactical knife's table)"
-- Changes the wiki lists in each gun's history, from patch notes we have not read ourselves.
local HISTORY = WIKI .. ", the gun's patch history"

-- A community value from the wiki's weapon page, checked against metabot.
local function wiki(value: number, what: string?): Param
	return p(value, "community", if what then BOTH .. ": " .. what else BOTH)
end

local function band(maxRange: number, head: number, body: number, legs: number): DamageBand
	return { maxRange = maxRange, head = head, body = body, legs = legs }
end

-- Our firing-error shape: tight for the first bullets, a jump around bullets
-- 4 and 5 (gamer.org on the Vandal), then levelling off. Each point is a
-- fraction of the way to the bullet where the maximum is reached, and of
-- the way from the first shot's cone to the maximum's.
local SPREAD_SHAPE = { { 0, 0 }, { 1 / 12, 0.026 }, { 1 / 8, 0.154 }, { 1 / 6, 0.333 }, { 1 / 4, 0.538 }, { 3 / 8, 0.744 }, { 7 / 12, 0.897 }, { 1, 1 } }

-- A firing-error curve from `first` at bullet 1 to `max` at bullet `maxAt`,
-- along our shape. `source` says where the two ends come from.
local function spread(first: number, max: number, maxAt: number, source: string): CurveParam
	if first == max or maxAt <= 1 then
		return c({ { 1, first } }, "community", source)
	end
	local points = {}
	for _, point in SPREAD_SHAPE do
		table.insert(points, { 1 + point[1] * (maxAt - 1), first + point[2] * (max - first) })
	end
	return c(points, "estimate", source .. "; the shape between them is ours")
end

-- Movement error by state: crouch-walking, walking, running, in the air.
type Moving = { crouch: Param, walk: Param, run: Param, air: Param }

local function accuracy(firingError: CurveParam, crouch: Param, recovery: Param, tap: Param, moving: Moving): AccuracyDef
	return {
		firingError = firingError,
		crouchMultiplier = crouch,
		recoveryTime = recovery,
		tapEfficiency = tap,
		runError = moving.run,
		walkError = moving.walk,
		crouchMoveError = moving.crouch,
		airError = moving.air,
	}
end

-- The same accuracy zoomed: another curve, and sometimes another crouch
-- multiplier or recovery. Moving costs the same either way (no source gives
-- zoomed movement errors).
local function zoomed(hip: AccuracyDef, firingError: CurveParam, crouch: Param?, recovery: Param?): AccuracyDef
	local out = table.clone(hip)
	out.firingError = firingError
	if crouch then
		out.crouchMultiplier = crouch
	end
	if recovery then
		out.recoveryTime = recovery
	end
	return out
end

type Sway = { start: Param, step: Param, max: Param, flip: Param }
type RecoilMods = { run: Param, crouchYaw: Param, ads: Param, camera: Param, adsCamera: Param, viewKick: Param? }

local function recoil(pitch: CurveParam, sway: Sway, mods: RecoilMods): RecoilDef
	return {
		pitch = pitch,
		swayStart = sway.start,
		swayStep = sway.step,
		swayMax = sway.max,
		swayFlipChance = sway.flip,
		runPitchMultiplier = mods.run,
		crouchYawMultiplier = mods.crouchYaw,
		adsMultiplier = mods.ads,
		cameraFraction = mods.camera,
		adsCameraFraction = mods.adsCamera,
		viewKick = mods.viewKick,
	}
end

local function sway(start: number, step: number, max: number, flip: number, why: string?): Sway
	local source = why or "Measure from a spray against a wall"
	return {
		start = p(start, "estimate", source),
		step = p(step, "estimate", source),
		max = p(max, "estimate", source),
		flip = p(flip, "estimate", source),
	}
end

local NO_SWAY: Sway = {
	start = p(99, "estimate", "No sideways drift"),
	step = p(0, "estimate", "No sideways drift"),
	max = p(0, "estimate", "No sideways drift"),
	flip = p(0, "estimate", "No sideways drift"),
}

-- Recoil shapes are ours throughout: no source publishes one.
local function climb(points: Curve, why: string?): CurveParam
	return c(points, "estimate", why or "Shape only; measure from a spray against a wall (09-arsenal.md section 3)")
end

-- Shared values -------------------------------------------------------------

local CLASSICK = "Riot lead gameplay designer (Sportskeeda, Jul 2020): 'ADS provides a flat spread reduction, while crouch provides a percentage reduction'"

-- Movement error is set per weapon class ("All Rifles" in the patch notes).
local RIFLE_MOVING: Moving = {
	crouch = p(0.8, "confirmed", P202 .. ": rifle crouch-moving error 0.3 to 0.8 (no later change found)"),
	walk = p(3, "confirmed", P910 .. ": rifles 'Walk Inaccuracy: 2 >>> 3'"),
	run = p(6, "confirmed", P910 .. ": rifles 'Run Inaccuracy: 5 >> 6'"),
	air = wiki(10, "rifles' jumping error"),
}
local SMG_MOVING: Moving = { crouch = wiki(0.15), walk = wiki(1), run = wiki(2.5), air = wiki(10) }
local SHOTGUN_MOVING: Moving = { crouch = wiki(0.5), walk = wiki(1), run = wiki(2), air = wiki(4) }
local SNIPER_MOVING: Moving = { crouch = wiki(7.5), walk = wiki(10), run = wiki(15), air = wiki(20) }
local HEAVY_MOVING: Moving = {
	crouch = wiki(0.4),
	walk = p(3, "confirmed", P910 .. ": machine guns 'Walk Inaccuracy: 2.4 >>> 3'"),
	run = p(6.5, "confirmed", P910 .. ": machine guns 'Run Inaccuracy: 6 >>> 6.5'"),
	air = wiki(10),
}
local PISTOL_CROUCH_MOVE = p(0.5, "confirmed", P910 .. ": all pistols 'Moving while crouching Inaccuracy: .1 >>> .5'")

local RIFLE_CROUCH = wiki(0.85, "rifles' crouch multiplier. " .. CLASSICK)
local SMG_CROUCH = wiki(0.85)
local SHOTGUN_CROUCH = wiki(0.85, "from its spread table (the page's x0.75 disagrees with that table)")
local SNIPER_CROUCH = wiki(0.9)
local HEAVY_CROUCH = wiki(0.6, "Patch 9.05 in the gun's history: crouching 'spread/recoil benefit' 40%")
local BURST_CROUCH = wiki(0.75, "zoomed burst fire")

local RUN_RIFLE = p(1.8, "confirmed", P611 .. ": 'Vertical Recoil Multiplier While Running', Vandal and Phantom 1.5 >>> 1.8")
local RUN_UNLISTED = p(1.5, "estimate", P611 .. " doesn't list this gun; 1.5 was the Vandal's, Phantom's and Spectre's value before it")
local RUN_NONE = p(1, "estimate", "Not published; " .. P611 .. " lists rifles, the Spectre and the Frenzy only")
local CROUCH_YAW = p(0.85, "confirmed", P050 .. ": the Vandal's crouched yaw reduction 'matches the crouch benefits of other rifles'")
local CROUCH_YAW_ESTIMATE = p(0.85, "estimate", "Assumed like rifles")
local ADS_RECOIL = p(0.9, "estimate", "Fandom (Phantom): zooming 'further reduces recoil and spread'; the amount is not published")
local NO_ADS_RECOIL = p(1, "estimate", "No zoom, or not published")
local AIM_MOVE = wiki(0.76, "zoomed run speed 76%")

local function camera(hip: number, ads: number?): (Param, Param)
	return p(hip, "estimate", "Share of the recoil the view shows; measure crosshair travel against impact travel"),
		p(ads or hip, "estimate", "The same zoomed; zooming 'amplifies screen movement' (esports.net)")
end

local WeaponConfig = {}

WeaponConfig.Slots = { Primary = 1, Secondary = 2, Melee = 3, Ultimate = 5 }

-- Pistols ---------------------------------------------------------------------

local classicHip = accuracy(
	spread(0.4, 1.8, 6, WIKI .. ": first shot 0.4, maximum 1.8; maximum at bullet 6 is ours"),
	wiki(0.75),
	p(0.3, "estimate", "Not published"),
	p(2, "estimate", "Not published"),
	{
		crouch = PISTOL_CROUCH_MOVE,
		walk = p(1.1, "confirmed", P910 .. ": Classic 'Walking Inaccuracy: 0.84 >>> 1.1'"),
		run = p(2.3, "confirmed", P910 .. ": Classic 'Run Inaccuracy: 2 >>> 2.3'"),
		air = wiki(7),
	}
)
local classicCamera, classicAdsCamera = camera(0.3)

local classicAlt: AltDef = {
	fireMode = "semi",
	fireRate = wiki(2.22, "right click"),
	pellets = p(3, "community", "Inven Global: the right click 'shoots a burst of three bullets at the same time', each doing 'as much damage as a bullet fired using the Classic's primary fire'"),
	ammo = p(3, "estimate", "Not published: a round per bullet assumed; count the clicks a magazine gives (09-arsenal.md section 3)"),
	accuracy = accuracy(
		spread(1.9, 5.78, 4, WIKI .. ": right click first 1.9, maximum 5.78; maximum at click 4 is ours"),
		wiki(0.9, "right click"),
		p(0.4, "estimate", "Not published"),
		p(2, "estimate", "Not published"),
		{
			crouch = wiki(0, "right click"),
			walk = wiki(0.6, "right click"),
			run = p(1.5, "confirmed", P910 .. ": Classic right click running 1.3 >>> 1.5"),
			air = p(2.25, "confirmed", P910 .. ": Classic right click jumping 2.1 >>> 2.25"),
		}
	),
	recoil = recoil(climb({ { 1, 0 }, { 2, 1.5 }, { 3, 2.6 }, { 5, 3.5 } }), sway(2, 0.6, 1.5, 0.4), {
		run = RUN_NONE,
		crouchYaw = CROUCH_YAW_ESTIMATE,
		ads = NO_ADS_RECOIL,
		camera = p(0.4, "estimate", "Measure"),
		adsCamera = p(0.4, "estimate", "No zoom"),
	}),
}

local shortyHip = accuracy(
	c({ { 1, 4 } }, "community", WIKI .. ": 4 for every shot"),
	SHOTGUN_CROUCH,
	p(0.3, "estimate", "Not published"),
	p(1, "estimate", "Not published"),
	SHOTGUN_MOVING
)
local frenzyHip = accuracy(
	spread(0.65, 1.7, 5, WIKI .. ": first 0.65 (" .. P611 .. ": 'Min spread increased from .45 >>> .65'), maximum 1.7, 'reached in 5 bullets instead of 6' (" .. P611 .. ")"),
	wiki(0.85),
	p(0.3, "estimate", "Not published"),
	p(2, "estimate", "Not published"),
	{ crouch = PISTOL_CROUCH_MOVE, walk = wiki(0.8), run = wiki(2), air = wiki(7) }
)
local ghostHip = accuracy(
	spread(0.3, 1.65, 6, WIKI .. ": first 0.3, maximum 1.65; maximum at bullet 6 is ours"),
	wiki(0.75),
	p(0.3, "estimate", "Not published"),
	p(2, "estimate", "Not published"),
	{ crouch = PISTOL_CROUCH_MOVE, walk = wiki(1.1), run = wiki(2.3), air = wiki(7) }
)
local banditHip = accuracy(
	spread(0.275, 1.97, 5, WIKI .. ": first 0.275, maximum 1.97; maximum at bullet 5 is ours"),
	wiki(0.75),
	p(0.4, "community", HISTORY .. ": Patch 13.00 recovery 0.45 >>> 0.4"),
	p(4, "community", HISTORY .. ": Patch 13.00 tap efficiency 3 >>> 4"),
	{ crouch = wiki(0.5), walk = wiki(1.2), run = wiki(2.7), air = wiki(7) }
)
local sheriffHip = accuracy(
	spread(0.25, 2.75, 4, WIKI .. ": first 0.25, maximum 2.75; maximum at bullet 4 is ours, spamming is meant to be wild"),
	wiki(0.75),
	p(0.25, "estimate", "Not published"),
	p(1.5, "estimate", "Not published"),
	{
		crouch = PISTOL_CROUCH_MOVE,
		walk = p(1.2, "confirmed", P30 .. ": Sheriff 'Walking inaccuracy changed from .25 >>> 1.2'"),
		run = p(3, "confirmed", P30 .. ": Sheriff 'Running inaccuracy changed from 2.0 >>> 3.0' (Patch 9.10 did not list the Sheriff)"),
		air = wiki(7),
	}
)

-- SMGs ------------------------------------------------------------------------

local stingerHip = accuracy(
	spread(0.65, 1.5, 6, WIKI .. ": first 0.65, maximum 1.5, 'reached at 6 bullets instead of 7' (Patch 11.08 in its history)"),
	SMG_CROUCH,
	p(0.35, "estimate", "Not published"),
	p(2, "estimate", "Not published"),
	SMG_MOVING
)
local spectreHip = accuracy(
	spread(0.4, 1.4, 10, WIKI .. ": first 0.4, maximum 1.4; maximum at bullet 10 is ours"),
	SMG_CROUCH,
	p(0.35, "estimate", "Not published"),
	p(3, "community", HISTORY .. ": Patch 11.08 tap efficiency 2 >>> 3"),
	SMG_MOVING
)

-- Shotguns --------------------------------------------------------------------

local buckyHip = accuracy(c({ { 1, 3 } }, "community", WIKI .. ": 3 for every shot"), SHOTGUN_CROUCH, p(0.4, "estimate", "Not published"), p(1, "estimate", "Not published"), SHOTGUN_MOVING)
local judgeHip = accuracy(
	spread(2.5, 4, 4, WIKI .. ": first 2.5, maximum 4; maximum at shot 4 is ours"),
	SHOTGUN_CROUCH,
	p(0.4, "estimate", "Not published"),
	p(1.5, "estimate", "Not published"),
	SHOTGUN_MOVING
)

-- Rifles ----------------------------------------------------------------------

local RIFLE_SPRAY_AT = 25 -- the bullet our rifle curves reach their maximum at

local bulldogHip = accuracy(
	spread(0.3, 1.25, RIFLE_SPRAY_AT, WIKI .. ": first 0.3, maximum 1.25"),
	RIFLE_CROUCH,
	p(0.35, "estimate", "Not published"),
	p(3, "estimate", "Not published"),
	RIFLE_MOVING
)
local guardianHip = accuracy(
	spread(0.1, 1.58, 5, WIKI .. ": first 0.1, maximum 1.58; maximum at bullet 5 is ours"),
	RIFLE_CROUCH,
	p(0.3, "estimate", "Not published"),
	p(3, "estimate", "Not published"),
	RIFLE_MOVING
)
local phantomHip = accuracy(
	spread(0.2, 0.9, RIFLE_SPRAY_AT, WIKI .. ": first 0.2, maximum 0.9"),
	RIFLE_CROUCH,
	p(0.35, "confirmed", P050 .. ": Phantom 'Gun Recovery Time: .55s >> .35s'"),
	p(4, "confirmed", P050 .. ": Phantom 'Tap Efficiency: 3 >> 4'"),
	RIFLE_MOVING
)
local vandalHip = accuracy(
	spread(0.25, 1.0, RIFLE_SPRAY_AT, WIKI .. ": first 0.25, maximum 1.0"),
	RIFLE_CROUCH,
	p(0.375, "confirmed", P050 .. ": Vandal 'Gun Recovery Time: .4s >> .375s'"),
	p(6, "confirmed", P050 .. ": Vandal 'Tap Efficiency: 4 >> 6'"),
	RIFLE_MOVING
)
local wardenHip = accuracy(
	spread(0.15, 1.0, 8, METABOT .. ": first 0.15 (Beebom: the best first shot of any rifle); the maximum 1.0 and bullet 8 are ours, not published"),
	p(0.85, "estimate", "Not published; assumed like rifles"),
	p(0.35, "estimate", "Not published"),
	p(4, "estimate", "Not published"),
	{
		crouch = p(0.8, "estimate", "Not published; assumed like rifles"),
		walk = p(3, "estimate", "Not published; assumed like rifles"),
		run = p(6, "estimate", "Not published; assumed like rifles"),
		air = p(10, "estimate", "Not published; assumed like rifles"),
	}
)

-- Snipers ---------------------------------------------------------------------

local marshalHip = accuracy(c({ { 1, 1 } }, "community", WIKI .. ": 1 unscoped"), SNIPER_CROUCH, p(0.1, "estimate", "Not published; every shot is a first shot"), p(1, "estimate", "Not used: a flat curve"), SNIPER_MOVING)
local outlawHip = accuracy(
	c({ { 1, 3.5 } }, "community", WIKI .. ": 3.5 unscoped"),
	SNIPER_CROUCH,
	p(0.15, "confirmed", P1301 .. ": Outlaw recovery after the first shot 0.1 >>> 0.15"),
	p(1, "estimate", "Not published"),
	SNIPER_MOVING
)
local operatorHip = accuracy(
	c({ { 1, 5 } }, "community", WIKI .. ": 5 unscoped (gamer.org: '5 deg deviation')"),
	SNIPER_CROUCH,
	p(0.1, "estimate", "Not published; every shot is a first shot"),
	p(1, "estimate", "Not used: a flat curve"),
	{ crouch = wiki(7.5), walk = wiki(10), run = wiki(15), air = wiki(15) }
)

-- Machine guns ----------------------------------------------------------------

local aresHip = accuracy(
	c({ { 1, 1.0 }, { 13, 0.7 } }, "community", WIKI .. ": Patch 4.01 changed its spread 'from .8 to .7 after 10 bullets to 1.0 to .7 after 13 bullets'"),
	HEAVY_CROUCH,
	p(0.4, "estimate", "Not published"),
	p(2, "estimate", "Not published"),
	HEAVY_MOVING
)
local odinHip = accuracy(
	spread(0.8, 1.3, 10, WIKI .. ": first 0.8, maximum 1.3; maximum at bullet 10 is ours"),
	wiki(0.6),
	p(0.4, "estimate", "Not published"),
	p(2, "estimate", "Not published"),
	HEAVY_MOVING
)

local KNIFE_NA = p(0, "estimate", "n/a")

-- Jett's Blade Storm (system 19): one knife at a time, exact wherever she is,
-- or all that are left at once, in a spread.
local BLADE = "VALORANT Wiki, Blade Storm"
local EXACT = BLADE .. ": Single Fire 'has 100% accuracy at all times (even when Jett is running or in the air)'"
local SPREAD = BLADE .. ": Burst Fire 'throws all of Blade Storm's remaining knives, though this can be inaccurate'"
local kunaiExact = accuracy(
	c({ { 1, 0 } }, "community", EXACT),
	p(1, "community", EXACT),
	p(0.1, "estimate", "n/a: there's no spread to recover"),
	p(1, "estimate", "n/a"),
	{
		crouch = p(0, "community", EXACT),
		walk = p(0, "community", EXACT),
		run = p(0, "community", EXACT),
		air = p(0, "community", EXACT),
	}
)
kunaiExact.landError = p(0, "community", EXACT)
local STILL_SPREAD = p(0, "estimate", "Not published; ours: the spread is the same however she moves")
local kunaiSpread = accuracy(
	c({ { 1, 2 } }, "estimate", SPREAD .. "; how far isn't published, and 2 is ours (Patch 1.09: it was 'frequently getting frags at over 20 meters')"),
	p(1, "estimate", "Not published; ours: crouching changes nothing"),
	p(0.1, "estimate", "n/a: all the knives go at once"),
	p(1, "estimate", "n/a"),
	{ crouch = STILL_SPREAD, walk = STILL_SPREAD, run = STILL_SPREAD, air = STILL_SPREAD }
)
kunaiSpread.landError = STILL_SPREAD
local NO_KICK = recoil(c({ { 1, 0 } }, "estimate", "None: a thrown knife doesn't kick"), NO_SWAY, {
	run = p(1, "estimate", "n/a"),
	crouchYaw = p(1, "estimate", "n/a"),
	ads = p(1, "estimate", "n/a"),
	camera = KNIFE_NA,
	adsCamera = KNIFE_NA,
})
local kunaiBurst: AltDef = {
	fireMode = "semi",
	fireRate = p(1 / 0.45, "confirmed", P109 .. ": 'The time between consecutive Burst Fire use has increased from 0.33 seconds >>> 0.45 seconds'"),
	pellets = p(5, "community", SPREAD),
	ammo = p(5, "community", SPREAD .. ": a knife each"),
	accuracy = kunaiSpread,
	recoil = NO_KICK,
}

-- Phoenix's Curveball flare (system 30): thrown along the crosshair and
-- flown by FlareSim, so no spread or kick moves it. Alt fire throws it the
-- other way round.
local CURVE = "VALORANT Wiki, Curveball"
local FLOWN = "n/a: FlareSim flies it from the crosshair"
local FLARE_NA = p(0, "estimate", FLOWN)
local flareExact = accuracy(
	c({ { 1, 0 } }, "estimate", FLOWN),
	p(1, "estimate", FLOWN),
	p(0.1, "estimate", FLOWN),
	p(1, "estimate", FLOWN),
	{ crouch = FLARE_NA, walk = FLARE_NA, run = FLARE_NA, air = FLARE_NA }
)
flareExact.landError = FLARE_NA
local FLARE_KICK = recoil(c({ { 1, 0 } }, "estimate", "None: a thrown flare doesn't kick"), NO_SWAY, {
	run = p(1, "estimate", "n/a"),
	crouchYaw = p(1, "estimate", "n/a"),
	ads = p(1, "estimate", "n/a"),
	camera = FLARE_NA,
	adsCamera = FLARE_NA,
})
local ONE_THROW = p(1, "estimate", "n/a: one throw, and it's gone")
local flareRight: AltDef = {
	fireMode = "auto",
	fireRate = ONE_THROW,
	pellets = p(1, "community", CURVE .. ": 'ALT FIRE to curve the flare orb to the right'"),
	ammo = p(1, "community", CURVE .. ": 2 uses, a flare each"),
	accuracy = flareExact,
	recoil = FLARE_KICK,
}

-- Phoenix's Hot Hands fireball (system 31): thrown along the crosshair and
-- flown by FireballSim, as the flare is by FlareSim, so no spread or kick
-- moves it either. Alt fire lobs it.
local HOT = "VALORANT Wiki, Hot Hands"
local BALL_FLOWN = "n/a: FireballSim flies it from the crosshair"
local BALL_NA = p(0, "estimate", BALL_FLOWN)
local fireballExact = accuracy(
	c({ { 1, 0 } }, "estimate", BALL_FLOWN),
	p(1, "estimate", BALL_FLOWN),
	p(0.1, "estimate", BALL_FLOWN),
	p(1, "estimate", BALL_FLOWN),
	{ crouch = BALL_NA, walk = BALL_NA, run = BALL_NA, air = BALL_NA }
)
fireballExact.landError = BALL_NA
local FIREBALL_KICK = recoil(c({ { 1, 0 } }, "estimate", "None: a thrown fireball doesn't kick"), NO_SWAY, {
	run = p(1, "estimate", "n/a"),
	crouchYaw = p(1, "estimate", "n/a"),
	ads = p(1, "estimate", "n/a"),
	camera = BALL_NA,
	adsCamera = BALL_NA,
})
local fireballLob: AltDef = {
	fireMode = "auto",
	fireRate = ONE_THROW,
	pellets = p(1, "community", HOT .. ": 'ALT FIRE to lob'"),
	ammo = p(1, "community", HOT .. ": 1 use, a fireball"),
	accuracy = fireballExact,
	recoil = FIREBALL_KICK,
}

-- Phoenix's Blaze flame (system 32): sent out along the floor from his feet
-- and run by BlazeSim, as the fireball is flown by FireballSim, so no spread
-- or kick moves it either. It has no alt fire.
local BLAZE = "VALORANT Wiki, Blaze"
local RUN = "n/a: BlazeSim runs it from where he faces"
local WALL_NA = p(0, "estimate", RUN)
local flameExact = accuracy(
	c({ { 1, 0 } }, "estimate", RUN),
	p(1, "estimate", RUN),
	p(0.1, "estimate", RUN),
	p(1, "estimate", RUN),
	{ crouch = WALL_NA, walk = WALL_NA, run = WALL_NA, air = WALL_NA }
)
flameExact.landError = WALL_NA
local FLAME_KICK = recoil(c({ { 1, 0 } }, "estimate", "None: a wall sent out doesn't kick"), NO_SWAY, {
	run = p(1, "estimate", "n/a"),
	crouchYaw = p(1, "estimate", "n/a"),
	ads = p(1, "estimate", "n/a"),
	camera = WALL_NA,
	adsCamera = WALL_NA,
})

-- Sage's Healing Orb (system 36): not thrown, but tried on the ally under
-- the crosshair, or with alt fire on herself, so no spread or kick moves
-- the crosshair. A try that heals nobody leaves it in hand for the next.
local ORB = "VALORANT Wiki, Healing Orb"
local TRIED = "n/a: the server looks along the crosshair for the ally it's over"
local ORB_NA = p(0, "estimate", TRIED)
local orbExact = accuracy(
	c({ { 1, 0 } }, "estimate", TRIED),
	p(1, "estimate", TRIED),
	p(0.1, "estimate", TRIED),
	p(1, "estimate", TRIED),
	{ crouch = ORB_NA, walk = ORB_NA, run = ORB_NA, air = ORB_NA }
)
orbExact.landError = ORB_NA
local ORB_KICK = recoil(c({ { 1, 0 } }, "estimate", "None: a heal doesn't kick"), NO_SWAY, {
	run = p(1, "estimate", "n/a"),
	crouchYaw = p(1, "estimate", "n/a"),
	ads = p(1, "estimate", "n/a"),
	camera = ORB_NA,
	adsCamera = ORB_NA,
})
-- A try a click, as quickly as clicks come (ours: no source says).
local ORB_TRIES = p(10, "estimate", "Ours: a try a click, ten a second at most")
local orbSelf: AltDef = {
	fireMode = "semi",
	fireRate = ORB_TRIES,
	pellets = p(1, "community", ORB .. ": 'ALT FIRE while Sage is damaged to activate a self Heal-Over-Time'"),
	ammo = p(1, "community", ORB .. ": 1 use"),
	accuracy = orbExact,
	recoil = ORB_KICK,
}

-- Sage's Slow Orb (system 37): thrown along the crosshair and flown by
-- FireballSim as the Slow Orb's (SlowSim), as the fireball is, so no spread
-- or kick moves it either. It has no alt fire.
local SLOW = "VALORANT Wiki, Slow Orb"
local SLOW_FLOWN = "n/a: SlowSim flies it from the crosshair"
local SLOW_NA = p(0, "estimate", SLOW_FLOWN)
local slowExact = accuracy(
	c({ { 1, 0 } }, "estimate", SLOW_FLOWN),
	p(1, "estimate", SLOW_FLOWN),
	p(0.1, "estimate", SLOW_FLOWN),
	p(1, "estimate", SLOW_FLOWN),
	{ crouch = SLOW_NA, walk = SLOW_NA, run = SLOW_NA, air = SLOW_NA }
)
slowExact.landError = SLOW_NA
local SLOW_KICK = recoil(c({ { 1, 0 } }, "estimate", "None: a thrown orb doesn't kick"), NO_SWAY, {
	run = p(1, "estimate", "n/a"),
	crouchYaw = p(1, "estimate", "n/a"),
	ads = p(1, "estimate", "n/a"),
	camera = SLOW_NA,
	adsCamera = SLOW_NA,
})

-- Sage's Barrier Orb (system 38): not thrown, but raised where its
-- targeter shows (BarrierSim), so no spread or kick moves the crosshair. A
-- try with nowhere to raise it leaves it in hand for the next. Its alt
-- fire turns the targeter (AbilitySim), and fires nothing.
local BARRIER = "VALORANT Wiki, Barrier Orb"
local PLACED = "n/a: BarrierSim places its wall from the crosshair"
local BARRIER_NA = p(0, "estimate", PLACED)
local barrierExact = accuracy(
	c({ { 1, 0 } }, "estimate", PLACED),
	p(1, "estimate", PLACED),
	p(0.1, "estimate", PLACED),
	p(1, "estimate", PLACED),
	{ crouch = BARRIER_NA, walk = BARRIER_NA, run = BARRIER_NA, air = BARRIER_NA }
)
barrierExact.landError = BARRIER_NA
local BARRIER_KICK = recoil(c({ { 1, 0 } }, "estimate", "None: a wall raised doesn't kick"), NO_SWAY, {
	run = p(1, "estimate", "n/a"),
	crouchYaw = p(1, "estimate", "n/a"),
	ads = p(1, "estimate", "n/a"),
	camera = BARRIER_NA,
	adsCamera = BARRIER_NA,
})
-- A try a click, as the Healing Orb's (ours: no source says).
local WALL_TRIES = p(10, "estimate", "Ours: ten tries a second while fire's held, until there's somewhere for its wall")

-- Sage's Resurrection (system 39): not thrown, but tried on the fallen ally
-- whose body is under the crosshair (ReviveSim), as the Healing Orb is on a
-- standing one, so it takes the orb's no spread, no kick and try a click. A
-- try over nobody leaves it in hand for the next.
local RESURRECTION = "VALORANT Wiki, Resurrection"
-- Omen's Dark Cover (system 40): neither fired nor tried. Fire and alt
-- fire move its mark (AbilitySim) and E again sends it, so what fire would
-- shoot is dropped; it takes the orb's no spread and no kick.
local DARK_COVER = "VALORANT Wiki, Dark Cover"

WeaponConfig.Defs = {
	classic = {
		id = "classic",
		name = "Classic",
		category = "sidearm",
		slot = 2,
		price = wiki(0, "free, and everyone has one"),
		fireMode = "semi",
		fireRate = wiki(6.75),
		magazine = wiki(12),
		reserve = wiki(36),
		reloadTime = wiki(1.75),
		equipTime = wiki(0.75),
		moveMultiplier = wiki(0.85, "5.73 m/s"),
		damage = { band(30, 78, 26, 22.1), band(50, 66, 22, 18.7) },
		damageSource = wiki(0, "26 body x3 head x0.85 legs, 22 past 30 m"),
		penetration = "low",
		suppressed = false,
		alt = classicAlt,
		accuracy = classicHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 0.4 }, { 3, 0.9 }, { 5, 1.8 }, { 8, 2.6 } }), sway(2, 0.3, 1.0, 0.3, "Pistols kick sideways from the start; measure"), {
			run = RUN_NONE,
			crouchYaw = CROUCH_YAW_ESTIMATE,
			ads = NO_ADS_RECOIL,
			camera = classicCamera,
			adsCamera = classicAdsCamera,
		}),
	},
	shorty = {
		id = "shorty",
		name = "Shorty",
		category = "sidearm",
		slot = 2,
		price = p(300, "confirmed", P611 .. ": Shorty 'Price adjusted from $150 >>> $300'"),
		fireMode = "semi",
		fireRate = wiki(3.0),
		pellets = wiki(15),
		magazine = wiki(2),
		reserve = p(6, "confirmed", P611 .. ": Shorty 'Reserve ammo adjusted from 10 >>> 6'"),
		reloadTime = wiki(1.75),
		equipTime = wiki(0.75),
		moveMultiplier = wiki(0.8, "5.4 m/s"),
		damage = { band(7, 22, 11, 9.35), band(15, 12, 6, 5.1), band(50, 6, 3, 2.55) },
		damageSource = p(0, "confirmed", P611 .. ": body 11 to 7 m and 6 to 15 m ('12 >>> 11', '8 >>> 6'); 3 beyond, head x2 and legs x0.85 from " .. WIKI),
		penetration = "low",
		suppressed = false,
		accuracy = shortyHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 1.5 } }), NO_SWAY, {
			run = RUN_NONE,
			crouchYaw = CROUCH_YAW_ESTIMATE,
			ads = NO_ADS_RECOIL,
			camera = p(0.4, "estimate", "Measure"),
			adsCamera = p(0.4, "estimate", "No zoom"),
		}),
	},
	frenzy = {
		id = "frenzy",
		name = "Frenzy",
		category = "sidearm",
		slot = 2,
		price = wiki(450),
		fireMode = "auto",
		fireRate = wiki(10),
		magazine = p(15, "confirmed", P910 .. ": Frenzy magazine 13 >>> 15"),
		reserve = wiki(45),
		reloadTime = wiki(1.5),
		equipTime = wiki(1.0, "its fast and instant draws, 0.45 and 0.15, match the 0.75 s sidearms"),
		moveMultiplier = wiki(0.85, "5.73 m/s"),
		damage = { band(20, 78, 26, 22.1), band(50, 63, 21, 17.85) },
		damageSource = wiki(0, "26 body to 20 m, 21 beyond; head x3, legs x0.85"),
		penetration = "low",
		suppressed = false,
		accuracy = frenzyHip,
		recoil = recoil(
			climb({ { 1, 0 }, { 2, 0.4 }, { 3, 0.9 }, { 5, 1.6 }, { 15, 2.0 } }, P611 .. ": 'Maximum recoil will be reached in 5 bullets instead of 6'; the heights are ours"),
			sway(3, 0.35, 1.4, 0.25),
			{
				run = p(1.5, "confirmed", P611 .. ": 'Vertical Recoil Multiplier While Running', Frenzy 1.25 >>> 1.5"),
				crouchYaw = CROUCH_YAW_ESTIMATE,
				ads = NO_ADS_RECOIL,
				camera = p(0.3, "estimate", "Measure"),
				adsCamera = p(0.3, "estimate", "No zoom"),
			}
		),
	},
	ghost = {
		id = "ghost",
		name = "Ghost",
		category = "sidearm",
		slot = 2,
		price = wiki(500),
		fireMode = "semi",
		fireRate = wiki(6.75),
		magazine = p(13, "confirmed", P910 .. ": Ghost magazine 15 >>> 13"),
		reserve = wiki(39),
		reloadTime = wiki(1.5),
		equipTime = wiki(0.75),
		moveMultiplier = wiki(0.85, "5.73 m/s"),
		damage = { band(30, 105, 30, 25.5), band(50, 87.5, 25, 21.25) },
		damageSource = wiki(0, "30 body to 30 m, 25 beyond; head x3.5, legs x0.85"),
		penetration = "medium",
		suppressed = true,
		accuracy = ghostHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 0.35 }, { 3, 0.8 }, { 5, 1.6 }, { 8, 2.3 } }), sway(2, 0.25, 0.9, 0.3), {
			run = RUN_NONE,
			crouchYaw = CROUCH_YAW_ESTIMATE,
			ads = NO_ADS_RECOIL,
			camera = p(0.3, "estimate", "Measure"),
			adsCamera = p(0.3, "estimate", "No zoom"),
		}),
	},
	bandit = {
		id = "bandit",
		name = "Bandit",
		category = "sidearm",
		slot = 2,
		price = p(600, "confirmed", P1200 .. ": 'a precision sidearm with 1-tap headshot power', 600 credits"),
		fireMode = "semi",
		fireRate = wiki(5.1),
		magazine = p(8, "confirmed", P1200 .. ": 8 rounds"),
		reserve = p(24, "confirmed", P1200 .. ": 24 in reserve"),
		reloadTime = p(1.5, "confirmed", P1200 .. ": reload 1.5 s"),
		equipTime = p(0.75, "confirmed", P1200 .. ": equip 0.75 s"),
		moveMultiplier = p(0.85, "community", METABOT .. ": 85% (the wiki says 5.4 m/s, 80%)"),
		damage = { band(10, 152.1, 39, 33.15), band(30, 128.7, 39, 33.15), band(50, 112.2, 34, 28.9) },
		damageSource = wiki(0, "39 body to 30 m and 34 beyond; head x3.9 to 10 m, then x3.3; legs x0.85"),
		penetration = "medium",
		suppressed = false,
		accuracy = banditHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 1.2 }, { 3, 2.2 }, { 5, 3.2 } }), sway(2, 0.4, 1.2, 0.3), {
			run = RUN_NONE,
			crouchYaw = CROUCH_YAW_ESTIMATE,
			ads = NO_ADS_RECOIL,
			camera = p(0.35, "estimate", "Measure"),
			adsCamera = p(0.35, "estimate", "No zoom"),
		}),
	},
	sheriff = {
		id = "sheriff",
		name = "Sheriff",
		category = "sidearm",
		slot = 2,
		price = wiki(800),
		fireMode = "semi",
		fireRate = wiki(4),
		magazine = wiki(6),
		reserve = wiki(24),
		reloadTime = wiki(2.25),
		equipTime = wiki(1.0),
		moveMultiplier = wiki(0.8, "5.4 m/s"),
		damage = { band(30, 159.5, 55, 46.75), band(50, 145, 50, 42.5) },
		damageSource = wiki(0, "55 body to 30 m, 50 beyond; head x2.9, legs x0.85 (the wiki rounds 159.5 down, metabot up)"),
		penetration = "high",
		suppressed = false,
		accuracy = sheriffHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 1.6 }, { 3, 3.0 }, { 4, 4.0 }, { 6, 4.8 } }, "A big kick per shot; measure"), sway(2, 0.6, 1.5, 0.35), {
			run = RUN_NONE,
			crouchYaw = CROUCH_YAW_ESTIMATE,
			ads = NO_ADS_RECOIL,
			camera = p(0.35, "estimate", "Measure"),
			adsCamera = p(0.35, "estimate", "No zoom"),
		}),
	},
	stinger = {
		id = "stinger",
		name = "Stinger",
		category = "smg",
		slot = 1,
		price = wiki(1100),
		fireMode = "auto",
		fireRate = wiki(16),
		magazine = wiki(20),
		reserve = wiki(60),
		reloadTime = wiki(2.25),
		equipTime = wiki(0.75),
		moveMultiplier = wiki(0.85, "5.73 m/s"),
		damage = { band(15, 67.5, 27, 22.95), band(50, 57.5, 23, 19.55) },
		damageSource = wiki(0, "27 body to 15 m, 23 beyond; head x2.5, legs x0.85"),
		penetration = "low",
		suppressed = false,
		ads = {
			zoom = { 1.15 },
			fireRateMultiplier = p(1, "community", "n/a: zoomed it fires bursts"),
			moveMultiplier = AIM_MOVE,
			accuracy = zoomed(
				stingerHip,
				spread(0.35, 2.74, 8, WIKI .. ": zoomed burst first 0.35, maximum 2.74; maximum at bullet 8 is ours"),
				BURST_CROUCH,
				p(0.4, "community", HISTORY .. ": Patch 2.03 burst recovery 0.4")
			),
			burst = {
				rounds = wiki(4, "zoomed: 4-round bursts"),
				rate = wiki(18, "18 rounds a second within a burst"),
				perSecond = wiki(2.118, "2.118 bursts a second"),
			},
		},
		accuracy = stingerHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 0.25 }, { 4, 0.9 }, { 6, 1.6 }, { 10, 2.4 }, { 20, 3.0 } }), sway(4, 0.35, 1.6, 0.15), {
			run = RUN_UNLISTED,
			crouchYaw = CROUCH_YAW_ESTIMATE,
			ads = ADS_RECOIL,
			camera = p(0.3, "estimate", "Measure"),
			adsCamera = p(0.8, "estimate", "Measure"),
		}),
	},
	spectre = {
		id = "spectre",
		name = "Spectre",
		category = "smg",
		slot = 1,
		price = wiki(1600),
		fireMode = "auto",
		fireRate = wiki(13.33),
		magazine = wiki(30),
		reserve = wiki(90),
		reloadTime = wiki(2.25),
		equipTime = wiki(0.75),
		moveMultiplier = wiki(0.85, "5.73 m/s"),
		damage = { band(15, 78, 26, 22.1), band(30, 66, 22, 18.7), band(50, 60, 20, 17) },
		damageSource = wiki(0, "26 body to 15 m, 22 to 30 m, 20 beyond; head x3, legs x0.85"),
		penetration = "low",
		suppressed = true,
		ads = {
			zoom = { 1.15 },
			fireRateMultiplier = wiki(0.9, "zoomed 90% (12 rps)"),
			moveMultiplier = AIM_MOVE,
			accuracy = zoomed(spectreHip, spread(0.25, 1.25, 10, WIKI .. ": zoomed first 0.25, maximum 1.25")),
		},
		accuracy = spectreHip,
		recoil = recoil(
			climb({ { 1, 0 }, { 2, 0.2 }, { 4, 0.7 }, { 6, 1.3 }, { 10, 2.2 }, { 16, 2.8 }, { 30, 3.1 } }),
			{
				start = p(5, "community", HISTORY .. ": Patch 11.08 protected bullets, which never drift, 4 >>> 5"),
				step = p(0.3, "estimate", "Measure"),
				max = p(1.4, "estimate", "Measure"),
				flip = p(0.12, "estimate", "Measure; Patch 11.08 moved its switch time 0.18 >>> 0.28 s, which we don't model"),
			},
			{
				run = p(1.8, "confirmed", P611 .. ": 'Vertical Recoil Multiplier While Running', Spectre 1.5 >>> 1.8"),
				crouchYaw = CROUCH_YAW_ESTIMATE,
				ads = ADS_RECOIL,
				camera = p(0.3, "estimate", "Measure"),
				adsCamera = p(0.8, "estimate", "Measure"),
			}
		),
	},
	bucky = {
		id = "bucky",
		name = "Bucky",
		category = "shotgun",
		slot = 1,
		price = wiki(850),
		fireMode = "semi",
		fireRate = wiki(1.1),
		pellets = wiki(15),
		magazine = wiki(5),
		reserve = wiki(10),
		reloadTime = wiki(2.5, "a full magazine"),
		reloadPerRound = wiki(0.5, "a shell at a time"),
		equipTime = wiki(1.0),
		moveMultiplier = wiki(0.75, "5.06 m/s"),
		damage = { band(8, 34, 17, 14.45), band(12, 26, 13, 11.05), band(50, 18, 9, 7.65) },
		damageSource = wiki(0, "per pellet: 17 body to 8 m, 13 to 12 m, 9 beyond; head x2, legs x0.85"),
		penetration = "low",
		suppressed = false,
		accuracy = buckyHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 1.4 }, { 5, 2.6 } }), NO_SWAY, {
			run = RUN_NONE,
			crouchYaw = CROUCH_YAW_ESTIMATE,
			ads = NO_ADS_RECOIL,
			camera = p(0.5, "estimate", "Measure"),
			adsCamera = p(0.5, "estimate", "No zoom"),
		}),
	},
	judge = {
		id = "judge",
		name = "Judge",
		category = "shotgun",
		slot = 1,
		price = wiki(1850),
		fireMode = "auto",
		fireRate = wiki(3.5),
		pellets = wiki(12),
		magazine = wiki(5),
		reserve = wiki(15),
		reloadTime = wiki(2.2),
		equipTime = wiki(1.0),
		moveMultiplier = wiki(0.75, "5.06 m/s"),
		damage = { band(10, 34, 17, 14.45), band(15, 20, 10, 8.5), band(50, 14, 7, 5.95) },
		damageSource = wiki(0, "per pellet: 17 body to 10 m, 10 to 15 m, 7 beyond; head x2, legs x0.85"),
		penetration = "low",
		suppressed = false,
		accuracy = judgeHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 1.0 }, { 3, 1.8 }, { 5, 2.8 } }), sway(2, 0.5, 1.5, 0.3), {
			run = RUN_NONE,
			crouchYaw = CROUCH_YAW_ESTIMATE,
			ads = NO_ADS_RECOIL,
			camera = p(0.4, "estimate", "Measure"),
			adsCamera = p(0.4, "estimate", "No zoom"),
		}),
	},
	bulldog = {
		id = "bulldog",
		name = "Bulldog",
		category = "rifle",
		slot = 1,
		price = wiki(2050),
		fireMode = "auto",
		fireRate = wiki(10),
		magazine = wiki(24),
		reserve = wiki(72),
		reloadTime = wiki(2.5),
		equipTime = wiki(1.0),
		moveMultiplier = wiki(0.8, "5.4 m/s"),
		damage = { band(50, 115.5, 35, 29.75) },
		damageSource = wiki(0, "35 body, head x3.3, legs x0.85, no falloff"),
		penetration = "medium",
		suppressed = false,
		ads = {
			zoom = { 1.25 },
			fireRateMultiplier = p(1, "community", "n/a: zoomed it fires bursts"),
			moveMultiplier = AIM_MOVE,
			accuracy = zoomed(
				bulldogHip,
				spread(0.1, 1.5, 6, WIKI .. ": zoomed burst first 0.1, maximum 1.5; maximum at bullet 6 is ours"),
				BURST_CROUCH,
				p(0.35, "community", HISTORY .. ": Patch 4.0 burst recovery 0.4 >>> 0.35")
			),
			burst = {
				rounds = wiki(3, "zoomed: 3-round bursts"),
				rate = wiki(13.333, "13.33 rounds a second within a burst"),
				perSecond = wiki(2.105, "2.105 bursts a second"),
			},
		},
		accuracy = bulldogHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 0.25 }, { 3, 0.65 }, { 4, 1.2 }, { 6, 2.2 }, { 9, 3.4 }, { 12, 4.1 }, { 16, 4.5 }, { 24, 4.7 } }), sway(6, 0.4, 2.0, 0.12), {
			run = RUN_UNLISTED,
			crouchYaw = CROUCH_YAW,
			ads = ADS_RECOIL,
			camera = p(0.25, "estimate", "As the Vandal"),
			adsCamera = p(0.9, "estimate", "As the Vandal"),
		}),
	},
	guardian = {
		id = "guardian",
		name = "Guardian",
		category = "rifle",
		slot = 1,
		price = wiki(2250),
		fireMode = "semi",
		fireRate = wiki(5.25),
		magazine = wiki(12),
		reserve = wiki(36),
		reloadTime = wiki(2.5),
		equipTime = wiki(1.0),
		moveMultiplier = wiki(0.8, "5.4 m/s"),
		damage = { band(50, 195, 65, 48.75) },
		damageSource = wiki(0, "65 body, head x3, legs x0.75, no falloff"),
		penetration = "high",
		suppressed = false,
		ads = {
			zoom = { 1.5 },
			fireRateMultiplier = wiki(1, "zoomed 100%"),
			moveMultiplier = AIM_MOVE,
			accuracy = zoomed(guardianHip, spread(0, 1.48, 5, WIKI .. ": zoomed first 0, maximum 1.48")),
		},
		accuracy = guardianHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 0.9 }, { 3, 1.7 }, { 5, 2.6 }, { 8, 3.1 } }), sway(3, 0.3, 1.0, 0.3), {
			run = RUN_UNLISTED,
			crouchYaw = CROUCH_YAW,
			ads = ADS_RECOIL,
			camera = p(0.3, "estimate", "Measure"),
			adsCamera = p(0.9, "estimate", "Measure"),
		}),
	},
	phantom = {
		id = "phantom",
		name = "Phantom",
		category = "rifle",
		slot = 1,
		price = wiki(2900),
		fireMode = "auto",
		fireRate = wiki(11),
		magazine = wiki(30),
		reserve = p(60, "confirmed", P611 .. ": 'Phantom Reserve ammo adjusted from 90 >>> 60'"),
		reloadTime = wiki(2.5),
		equipTime = wiki(1.0),
		moveMultiplier = wiki(0.8, "5.4 m/s"),
		damage = { band(20, 156, 39, 33.15), band(50, 140, 35, 29.75) },
		damageSource = p(0, "community", "Body and the 20 m boundary are " .. P910 .. ": 'Now does 39 damage per bullet from 0-20m and 35 damage per bullet 20m+'; head x4 and legs x0.85 from " .. WIKI),
		penetration = "medium",
		suppressed = true,
		ads = {
			zoom = { 1.25 },
			fireRateMultiplier = wiki(0.9, "zoomed 90% (9.9 rps)"),
			moveMultiplier = AIM_MOVE,
			accuracy = zoomed(phantomHip, spread(0.11, 0.91, RIFLE_SPRAY_AT, WIKI .. ": zoomed first 0.11, maximum 0.91 (Sportskeeda, 2020: 0.20 hip, 0.11 zoomed)")),
		},
		accuracy = phantomHip,
		recoil = recoil(
			climb(
				{ { 1, 0 }, { 2, 0.25 }, { 3, 0.6 }, { 4, 1.15 }, { 6, 2.3 }, { 9, 3.9 }, { 12, 4.8 }, { 16, 5.2 }, { 30, 5.5 } },
				"The Vandal's T, a little lower (pull down 'head to waist' against 'head to thigh', gamer.org)"
			),
			{
				start = p(8, "community", HISTORY .. ": Patch 11.08 protected bullets, which never drift, 6 >>> 8"),
				step = p(0.45, "estimate", "Sideways drift per bullet; measure"),
				max = p(2.2, "estimate", "Half the width of the top of the T; measure"),
				flip = p(0.10, "community", HISTORY .. ": Patch 11.08 switch chance 6% >>> 10% (its switch time, 0.6 s, we don't model)"),
			},
			{
				run = RUN_RIFLE,
				crouchYaw = CROUCH_YAW,
				ads = ADS_RECOIL,
				camera = p(0.25, "estimate", "As the Vandal"),
				adsCamera = p(0.9, "estimate", "As the Vandal"),
			}
		),
	},
	vandal = {
		id = "vandal",
		name = "Vandal",
		category = "rifle",
		slot = 1,
		price = wiki(2900),
		fireMode = "auto",
		fireRate = wiki(9.75),
		magazine = wiki(25),
		reserve = p(50, "confirmed", P611 .. ": 'Vandal Reserve ammo adjusted from 75 >>> 50'"),
		reloadTime = wiki(2.5),
		equipTime = wiki(1.0),
		moveMultiplier = wiki(0.8, "5.4 m/s"),
		damage = { band(50, 160, 40, 34) },
		damageSource = wiki(0, "40 body, head x4, legs x0.85, no falloff"),
		penetration = "medium",
		suppressed = false,
		ads = {
			zoom = { 1.25 },
			fireRateMultiplier = wiki(0.9, "zoomed 90% (8.775 rps); PC Gamer: 8.32 rps against 9.25 from the hip"),
			moveMultiplier = AIM_MOVE,
			accuracy = zoomed(vandalHip, spread(0.157, 1.02, RIFLE_SPRAY_AT, WIKI .. ": zoomed first 0.157, maximum 1.02 (Sportskeeda, 2020: 0.25 hip, 0.157 zoomed)")),
		},
		accuracy = vandalHip,
		recoil = recoil(
			climb(
				{ { 1, 0 }, { 2, 0.3 }, { 3, 0.75 }, { 4, 1.4 }, { 6, 2.8 }, { 9, 4.6 }, { 12, 5.6 }, { 16, 6.1 }, { 25, 6.4 } },
				"Shape only: the spray always climbs, then levels off into a T (esports.net spray guide). Measure from a spray against a wall"
			),
			{
				start = p(6, "community", HISTORY .. ": Patch 11.08 protected bullets, which never drift, 4 >>> 6"),
				step = p(0.55, "estimate", "Sideways drift per bullet; measure"),
				max = p(2.6, "estimate", "Half the width of the top of the T; measure"),
				flip = p(0.10, "community", HISTORY .. ": Patch 11.08 switch chance 6% >>> 10% (its switch time, 0.6 s, we don't model)"),
			},
			{
				run = RUN_RIFLE,
				crouchYaw = p(0.85, "confirmed", P050 .. ": Vandal 'Horizontal (Yaw) Recoil reduced by 15% while crouched and stationary'"),
				ads = ADS_RECOIL,
				camera = p(0.25, "estimate", "In hip fire the bullets climb away from the crosshair (esports.net); measure crosshair travel against impact travel"),
				adsCamera = p(0.9, "estimate", "Zooming 'keeps shots on target' and 'amplifies screen movement' (esports.net)"),
			}
		),
	},
	warden = {
		id = "warden",
		name = "Warden",
		category = "rifle",
		slot = 1,
		price = p(2900, "confirmed", P1306 .. ": 'the latest automatic Rifle to join the Vandal and Phantom in the 2900 credits tier'"),
		fireMode = "auto",
		fireRate = p(6.5, "confirmed", P1306 .. ": fire rate 6.5"),
		magazine = p(18, "confirmed", P1306 .. ": 18 rounds"),
		reserve = p(36, "confirmed", P1306 .. ": 36 in reserve"),
		reloadTime = p(2.5, "confirmed", P1306 .. ": reload 2.5"),
		equipTime = p(1.0, "confirmed", P1306 .. ": equip 'Normal: 1.0'"),
		moveMultiplier = p(0.8, "community", METABOT .. ": 80%"),
		damage = { band(50, 200, 50, 42) },
		damageSource = p(0, "confirmed", P1306 .. ": '50 at all ranges', '200 headshot', '42 leg'"),
		penetration = "medium",
		suppressed = false,
		ads = {
			zoom = { 2 },
			fireRateMultiplier = p(1, "estimate", "Not published; assumed unchanged, like the Guardian's"),
			moveMultiplier = p(0.76, "estimate", "Not published; assumed like the other rifles"),
			accuracy = zoomed(wardenHip, spread(0, 1.0, 8, "Not published: zoomed first 0 (like the Guardian) and maximum 1.0 are ours")),
		},
		accuracy = wardenHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 0.7 }, { 3, 1.4 }, { 5, 2.4 }, { 8, 3.2 }, { 12, 3.6 }, { 18, 3.8 } }), sway(6, 0.4, 1.6, 0.12), {
			run = RUN_UNLISTED,
			crouchYaw = CROUCH_YAW,
			ads = ADS_RECOIL,
			camera = p(0.3, "estimate", "Measure"),
			adsCamera = p(1, "estimate", "A 2x scope kicks with the shot; measure"),
		}),
	},
	marshal = {
		id = "marshal",
		name = "Marshal",
		category = "sniper",
		slot = 1,
		price = wiki(950),
		fireMode = "semi",
		fireRate = wiki(1.5),
		magazine = wiki(5),
		reserve = wiki(15),
		reloadTime = wiki(2.5, "a full magazine"),
		reloadPerRound = wiki(0.5, "a round at a time"),
		equipTime = wiki(1.25),
		moveMultiplier = wiki(0.8, "5.4 m/s"),
		damage = { band(50, 202, 101, 85.85) },
		damageSource = wiki(0, "101 body, head x2, legs x0.85, no falloff"),
		penetration = "medium",
		suppressed = false,
		ads = {
			zoom = { 3.5 },
			fireRateMultiplier = wiki(0.8, "scoped 80% (1.2 rps)"),
			moveMultiplier = wiki(0.9, "scoped run speed 90%"),
			accuracy = zoomed(marshalHip, c({ { 1, 0 } }, "community", WIKI .. ": 0 scoped")),
		},
		accuracy = marshalHip,
		recoil = recoil(climb({ { 1, 0 } }, "A bolt action: every shot is a first shot, so the bullets don't climb"), NO_SWAY, {
			run = RUN_NONE,
			crouchYaw = p(1, "estimate", "No sideways recoil"),
			ads = p(1, "estimate", "Not published"),
			camera = p(0.5, "estimate", "Measure"),
			adsCamera = p(1, "estimate", "The scope kicks with the shot; measure"),
			viewKick = p(1.2, "estimate", "The kick each shot shows; measure"),
		}),
	},
	outlaw = {
		id = "outlaw",
		name = "Outlaw",
		category = "sniper",
		slot = 1,
		price = wiki(2400),
		fireMode = "semi",
		fireRate = wiki(2.75),
		magazine = wiki(2),
		reserve = wiki(10),
		reloadTime = wiki(3.8, "both rounds"),
		reloadOneRound = wiki(2.3, "one round"),
		equipTime = wiki(1.25),
		moveMultiplier = wiki(0.8, "5.4 m/s"),
		damage = { band(50, 238, 140, 119) },
		damageSource = wiki(0, "140 body, head x1.7, legs x0.85, no falloff"),
		penetration = "high",
		suppressed = false,
		ads = {
			zoom = { 3.5 },
			fireRateMultiplier = wiki(1, "scoped 100%"),
			moveMultiplier = wiki(0.8, "scoped run speed 80%"),
			accuracy = zoomed(outlawHip, c({ { 1, 0 }, { 2, 2.25 } }, "confirmed", P1301 .. ": Outlaw spread after the first shot 0 >>> 2.25 (0 for a first shot, " .. WIKI .. ")")),
		},
		accuracy = outlawHip,
		recoil = recoil(climb({ { 1, 0 }, { 2, 4.0 } }, P1301 .. ": Outlaw recoil after the first shot 0 >>> 4.0 (confirmed); the curve's shape is ours"), NO_SWAY, {
			run = RUN_NONE,
			crouchYaw = p(1, "estimate", "No sideways recoil"),
			ads = p(1, "estimate", "Not published"),
			camera = p(0.5, "estimate", "Measure"),
			adsCamera = p(1, "estimate", "The scope kicks with the shot; measure"),
			viewKick = p(1.5, "estimate", "The kick each shot shows; measure"),
		}),
	},
	operator = {
		id = "operator",
		name = "Operator",
		category = "sniper",
		slot = 1,
		price = wiki(4700),
		fireMode = "semi",
		fireRate = p(0.6, "confirmed", P109 .. ": 'Firing rate reduced from .75 >>> .6'"),
		magazine = wiki(5),
		reserve = wiki(10),
		reloadTime = wiki(3.7),
		equipTime = wiki(1.5),
		moveMultiplier = wiki(0.76, "5.13 m/s"),
		deadzoneFraction = p(0.15, "confirmed", P109 .. ": deadzone 30% >>> 15%"),
		damage = { band(50, 255, 150, 120) },
		damageSource = p(0, "confirmed", P109 .. " leg 127 >>> 120; head and body from " .. WIKI),
		penetration = "high",
		suppressed = false,
		ads = {
			zoom = { 2.5, 5 },
			fireRateMultiplier = wiki(1, "scoped 100%"),
			moveMultiplier = p(0.72, "confirmed", P109 .. ": scoped movement speed 76% >>> 72%"),
			accuracy = zoomed(operatorHip, c({ { 1, 0 } }, "community", WIKI .. ": 0 scoped")),
		},
		accuracy = operatorHip,
		recoil = recoil(climb({ { 1, 0 } }, "A bolt action: every shot is a first shot, so the bullets don't climb"), NO_SWAY, {
			run = RUN_NONE,
			crouchYaw = p(1, "estimate", "No sideways recoil"),
			ads = p(1, "estimate", "Not published"),
			camera = p(0.5, "estimate", "Measure"),
			adsCamera = p(1, "estimate", "The scope kicks with the shot; measure"),
			viewKick = p(1.8, "estimate", "The kick each shot shows; measure"),
		}),
	},
	ares = {
		id = "ares",
		name = "Ares",
		category = "heavy",
		slot = 1,
		price = wiki(1600),
		fireMode = "auto",
		fireRate = wiki(13, "no spin-up since Patch 4.0"),
		magazine = wiki(50),
		reserve = wiki(100),
		reloadTime = wiki(3.25),
		equipTime = wiki(1.25),
		moveMultiplier = wiki(0.76, "5.13 m/s"),
		damage = { band(30, 75, 30, 25.5), band(50, 70, 28, 23.8) },
		damageSource = wiki(0, "30 body to 30 m, 28 beyond; head x2.5, legs x0.85"),
		penetration = "high",
		suppressed = false,
		ads = {
			zoom = { 1.15 },
			fireRateMultiplier = wiki(1, "zoomed 100%"),
			moveMultiplier = AIM_MOVE,
			accuracy = zoomed(aresHip, c({ { 1, 0.9 }, { 13, 0.55 } }, "community", WIKI .. ": zoomed 0.9, tightening to 0.55")),
		},
		accuracy = aresHip,
		recoil = recoil(
			climb({ { 1, 0 }, { 2, 0.2 }, { 5, 0.8 }, { 10, 1.6 }, { 20, 2.4 }, { 50, 2.8 } }),
			sway(8, 0.25, 1.6, 0.08, "The Ares and Odin notes count yaw recoil 'after the first 8 bullets'; the rest is ours"),
			{
				run = RUN_UNLISTED,
				crouchYaw = p(0.6, "community", HISTORY .. ": Patch 9.05 crouching 'spread/recoil benefit' 40%"),
				ads = ADS_RECOIL,
				camera = p(0.3, "estimate", "Measure"),
				adsCamera = p(0.8, "estimate", "Measure"),
			}
		),
	},
	odin = {
		id = "odin",
		name = "Odin",
		category = "heavy",
		slot = 1,
		price = wiki(3200),
		fireMode = "auto",
		fireRate = wiki(12),
		spinUp = {
			maxRate = p(15.6, "community", "dodge.gg: '12 rounds/sec, spinning up to 15.6 rounds/sec with sustained fire'"),
			time = p(1.0, "estimate", "Not published; count the shots in each tenth of a second of a held spray (09-arsenal.md section 3)"),
		},
		magazine = wiki(100),
		reserve = wiki(200),
		reloadTime = wiki(5.0),
		equipTime = wiki(1.25),
		moveMultiplier = wiki(0.76, "5.13 m/s"),
		damage = { band(30, 95, 38, 32.3), band(50, 77.5, 31, 26.35) },
		damageSource = wiki(0, "38 body to 30 m, 31 beyond; head x2.5, legs x0.85"),
		penetration = "high",
		suppressed = false,
		ads = {
			zoom = { 1.15 },
			fireRateMultiplier = wiki(1.3, "zoomed it fires at 15.6 straight away, with no spin-up"),
			moveMultiplier = AIM_MOVE,
			accuracy = zoomed(odinHip, spread(0.79, 1.36, 10, WIKI .. ": zoomed first 0.79, maximum 1.36")),
		},
		accuracy = odinHip,
		recoil = recoil(
			climb({ { 1, 0 }, { 2, 0.25 }, { 5, 1.0 }, { 10, 2.0 }, { 20, 3.0 }, { 100, 3.4 } }),
			sway(8, 0.3, 2.0, 0.08, "The Ares and Odin notes count yaw recoil 'after the first 8 bullets'; the rest is ours"),
			{
				run = RUN_UNLISTED,
				crouchYaw = p(0.6, "estimate", "Assumed like the Ares (its crouch spread is x0.6 too)"),
				ads = ADS_RECOIL,
				camera = p(0.3, "estimate", "Measure"),
				adsCamera = p(0.8, "estimate", "Measure"),
			}
		),
	},
	knife = {
		id = "knife",
		name = "Knife",
		category = "melee",
		slot = 3,
		price = wiki(0, "everyone has one"),
		fireMode = "none", -- no bullets: it swings (melee)
		fireRate = p(0, "estimate", "No bullets; its swings' rates are in melee"),
		magazine = KNIFE_NA,
		reserve = KNIFE_NA,
		reloadTime = KNIFE_NA,
		equipTime = wiki(0.6),
		moveMultiplier = p(1.0, "community", "Fandom Melee: 'standard run speed of 6.75 m/s'"),
		damage = { band(0, 0, 0, 0) }, -- a swing's damage is in melee
		damageSource = KNIFE_NA,
		penetration = "none",
		suppressed = false,
		-- Reach and width aren't published: the estimates keep the reference's
		-- order, the slash wider and a little longer than the stab (Patch 4.01).
		melee = {
			slash = {
				rate = p(2, "community", NAMU .. ": the main attack '2 times a second'"),
				reach = p(2.0, "estimate", P401 .. ": left click hitboxes have 'a slightly longer range' than the right click's; how far isn't published"),
				radius = p(0.4, "estimate", P401 .. ": 'Left click hitboxes are now larger than a right click'"),
				front = p(50, "community", WIKI .. ": 'Front - 50/75 (Primary/Alt)'"),
				back = p(100, "community", WIKI .. ": 'Back - 100/150 (Primary/Alt)'"),
			},
			stab = {
				rate = p(0.8, "community", NAMU .. ": the secondary attack '0.8 times a second', with 'a longer recovery' (" .. WIKI .. ")"),
				reach = p(1.8, "estimate", WIKI .. ": the stab has 'slightly smaller range and hitbox'"),
				radius = p(0.3, "estimate", P401 .. ": 'Right click hitboxes are now 1.5x larger'; the size isn't published"),
				front = p(75, "community", WIKI .. ": 'Front - 50/75 (Primary/Alt)'"),
				back = p(150, "community", WIKI .. ": 'Back - 100/150 (Primary/Alt)', which 'allows a one-shot from behind'"),
			},
			comboReset = p(0.5, "estimate", WIKI .. ": 'a three swing combo that loops'; when it starts over isn't published"),
		},
		accuracy = accuracy(c({ { 1, 0 } }, "estimate", "n/a"), p(1, "estimate", "n/a"), p(0.1, "estimate", "n/a"), p(1, "estimate", "n/a"), {
			crouch = KNIFE_NA,
			walk = KNIFE_NA,
			run = KNIFE_NA,
			air = KNIFE_NA,
		}),
		recoil = recoil(c({ { 1, 0 } }, "estimate", "n/a"), NO_SWAY, {
			run = p(1, "estimate", "n/a"),
			crouchYaw = p(1, "estimate", "n/a"),
			ads = p(1, "estimate", "n/a"),
			camera = KNIFE_NA,
			adsCamera = KNIFE_NA,
		}),
	},
	-- The spike (system 12): held in hand to plant it; fires nothing.
	spike = {
		id = "spike",
		name = "Spike",
		category = "spike",
		slot = 4,
		price = p(0, "community", "Not bought: the attackers are given it each round (VALORANT Wiki, Spike)"),
		fireMode = "none",
		fireRate = KNIFE_NA,
		magazine = KNIFE_NA,
		reserve = KNIFE_NA,
		reloadTime = KNIFE_NA,
		equipTime = p(0.5, "estimate", "Drawing the spike (4); not published"),
		moveMultiplier = p(1.0, "estimate", "Run speed with the spike in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(0, 0, 0, 0) },
		damageSource = KNIFE_NA,
		penetration = "none",
		suppressed = false,
		spike = true,
		accuracy = accuracy(c({ { 1, 0 } }, "estimate", "n/a"), p(1, "estimate", "n/a"), p(0.1, "estimate", "n/a"), p(1, "estimate", "n/a"), {
			crouch = KNIFE_NA,
			walk = KNIFE_NA,
			run = KNIFE_NA,
			air = KNIFE_NA,
		}),
		recoil = recoil(c({ { 1, 0 } }, "estimate", "n/a"), NO_SWAY, {
			run = p(1, "estimate", "n/a"),
			crouchYaw = p(1, "estimate", "n/a"),
			ads = p(1, "estimate", "n/a"),
			camera = KNIFE_NA,
			adsCamera = KNIFE_NA,
		}),
	},
	-- Jett's Blade Storm knives (system 19): put in hand in the fifth slot by
	-- her ultimate's cast (AbilityConfig.BladeStorm), and gone once they're
	-- all thrown. Fire throws one; alt fire throws all that are left.
	kunai = {
		id = "kunai",
		name = "Blade Storm",
		category = "ultimate",
		slot = 5,
		price = p(0, "community", "Not bought: Blade Storm's 8 ultimate points put them in hand (" .. BLADE .. ")"),
		-- A click a knife (ours: no source says whether holding fire throws on).
		fireMode = "semi",
		fireRate = p(6, "community", BLADE .. ": Single Fire 'one every 0.167 s', timed by the wiki (not published)"),
		magazine = p(5, "community", BLADE .. ": 5 knives; the Fandom wiki: 'a set of 5 highly accurate throwing knives'"),
		reserve = p(0, "community", BLADE .. ": none to reload; Single Fire 'fully recharges knives on a kill'"),
		reloadTime = KNIFE_NA,
		equipTime = p(0.5, "community", BLADE .. ": 'Reequip time' 0.5 s; the first draw is the cast's windup"),
		moveMultiplier = p(1.0, "estimate", "Run speed with the knives in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(50, 150, 50, 42.5) },
		damageSource = p(
			0,
			"community",
			BLADE .. ": 50 a knife on the range's bot, head x3, legs x0.85 (Patch 5.03: 'from 1.0 >>> 0.85'); Patch 3.06: the burst's 'damage and multipliers will mirror the left-click'"
		),
		-- Knives don't go through walls (ours; on vlr.gg players take it that
		-- they can't: "I thought this wasn't possible?").
		penetration = "none",
		suppressed = false,
		ultimate = true,
		alt = kunaiBurst,
		accuracy = kunaiExact,
		recoil = NO_KICK,
	},
	-- Phoenix's Curveball flare (system 30): put in hand in the fifth slot by
	-- E (AbilityConfig.Curveball), with a charge to throw. Fire throws it
	-- curving left and alt fire curving right; PlayerSim turns the throw into
	-- the ability's cast, which FlareSim flies, so it fires no bullet. Its
	-- pop blinds, and it does no damage.
	flare = {
		id = "flare",
		name = "Curveball",
		category = "ability",
		slot = 5,
		price = p(0, "community", "Not bought: E puts it in hand, a charge of Curveball (" .. CURVE .. ")"),
		-- Held, it goes as soon as it's in hand (ours: no source says).
		fireMode = "auto",
		fireRate = ONE_THROW,
		magazine = p(1, "community", CURVE .. ": 2 uses, a flare each"),
		reserve = p(0, "community", "None: another throw is another charge (" .. CURVE .. ": 2 uses)"),
		reloadTime = FLARE_NA,
		equipTime = p(0.8, "community", CURVE .. ": 'Equip' 0.8 seconds"),
		moveMultiplier = p(1.0, "estimate", "Run speed with it in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(50, 0, 0, 0) },
		damageSource = p(0, "estimate", "None: its pop blinds (" .. CURVE .. "), and nothing has it hurt"),
		penetration = "none",
		suppressed = false,
		ability = "curveball",
		alt = flareRight,
		accuracy = flareExact,
		recoil = FLARE_KICK,
	},
	-- Phoenix's Hot Hands fireball (system 31): put in hand in the fifth slot
	-- by Q (AbilityConfig.HotHands), as the flare is by E. Fire throws it and
	-- alt fire lobs it; PlayerSim turns the throw into the ability's cast,
	-- which FireballSim flies, so it fires no bullet. Where it bursts, its
	-- fire burns (FireSim), as this weapon for the kill feed; the ball itself
	-- hurts nobody.
	fireball = {
		id = "fireball",
		name = "Hot Hands",
		category = "ability",
		slot = 5,
		price = p(0, "community", "Not bought: Q puts it in hand, the charge of Hot Hands (" .. HOT .. ")"),
		-- Held, it goes as soon as it's in hand (ours, as the flare).
		fireMode = "auto",
		fireRate = ONE_THROW,
		magazine = p(1, "community", HOT .. ": 1 use, a fireball"),
		reserve = p(0, "community", "None: another throw is another charge (" .. HOT .. ": 1 use)"),
		reloadTime = BALL_NA,
		equipTime = p(0.8, "community", HOT .. ": 'Equip' 0.8 seconds"),
		moveMultiplier = p(1.0, "estimate", "Run speed with it in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(50, 0, 0, 0) },
		damageSource = p(0, "estimate", "None: its fire burns (" .. HOT .. "), and the ball itself hurts nobody"),
		penetration = "none",
		suppressed = false,
		ability = "hothands",
		alt = fireballLob,
		accuracy = fireballExact,
		recoil = FIREBALL_KICK,
	},
	-- Phoenix's Blaze flame (system 32): put in hand in the fifth slot by C
	-- (AbilityConfig.Blaze), as the fireball is by Q. Fire sends the wall out;
	-- PlayerSim turns it into the ability's cast, which BlazeSim runs over
	-- the floor, and keeps the flame in hand while fire's held, bending it.
	-- Where the wall stands it burns (BlazeSim), as this weapon for the kill
	-- feed; the flame itself hurts nobody.
	flamewall = {
		id = "flamewall",
		name = "Blaze",
		category = "ability",
		slot = 5,
		price = p(0, "community", "Not bought: C puts it in hand, the charge of Blaze (" .. BLAZE .. ")"),
		-- Held, it goes as soon as it's in hand (ours, as the flare).
		fireMode = "auto",
		fireRate = ONE_THROW,
		magazine = p(1, "community", BLAZE .. ": 1 use, a wall"),
		reserve = p(0, "community", "None: another wall is another charge (" .. BLAZE .. ": 1 use)"),
		reloadTime = WALL_NA,
		equipTime = p(0.8, "community", BLAZE .. ": 'Equip time' 0.8 s (game files)"),
		moveMultiplier = p(1.0, "estimate", "Run speed with it in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(50, 0, 0, 0) },
		damageSource = p(0, "estimate", "None: its wall burns (" .. BLAZE .. "), and the flame in hand hurts nobody"),
		penetration = "none",
		suppressed = false,
		ability = "blaze",
		accuracy = flameExact,
		recoil = FLAME_KICK,
	},
	-- Sage's Healing Orb (system 36): put in hand in the fifth slot by E
	-- (AbilityConfig.HealingOrb), as the flare is by Phoenix's E. Fire tries
	-- it on the ally under the crosshair and alt fire on herself; PlayerSim
	-- turns each try into the ability's cast, so it fires no bullet, and
	-- keeps it in hand, a try at a time, until the server finds one heals
	-- (HealServer) and puts it away.
	healorb = {
		id = "healorb",
		name = "Healing Orb",
		category = "ability",
		slot = 5,
		price = p(0, "community", "Not bought: E puts it in hand, the free charge of the Healing Orb (" .. ORB .. ")"),
		fireMode = "semi",
		fireRate = ORB_TRIES,
		magazine = p(1, "community", ORB .. ": 1 use, a heal"),
		reserve = p(0, "community", "None: another heal is another charge (" .. ORB .. ": 1 use)"),
		reloadTime = ORB_NA,
		equipTime = p(0.5, "community", ORB .. ": 'Equip' 0.5 seconds"),
		moveMultiplier = p(1.0, "estimate", "Run speed with it in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(50, 0, 0, 0) },
		damageSource = p(0, "estimate", "None: it heals (" .. ORB .. "), and hurts nobody"),
		penetration = "none",
		suppressed = false,
		ability = "healingorb",
		alt = orbSelf,
		accuracy = orbExact,
		recoil = ORB_KICK,
	},
	-- Sage's Slow Orb (system 37): put in hand in the fifth slot by Q
	-- (AbilityConfig.SlowOrb), as the fireball is by Phoenix's Q. Fire throws
	-- it; PlayerSim turns the throw into the ability's cast, which SlowSim
	-- flies, so it fires no bullet. Where it bursts, its field slows; the
	-- orb itself hurts nobody.
	iceorb = {
		id = "iceorb",
		name = "Slow Orb",
		category = "ability",
		slot = 5,
		price = p(0, "community", "Not bought here: Q puts it in hand, a charge of the Slow Orb (" .. SLOW .. ")"),
		-- Held, it goes as soon as it's in hand (ours, as the flare).
		fireMode = "auto",
		fireRate = ONE_THROW,
		magazine = p(1, "community", SLOW .. ": 2 uses, an orb each"),
		reserve = p(0, "community", "None: another throw is another charge (" .. SLOW .. ": 2 uses)"),
		reloadTime = SLOW_NA,
		equipTime = p(0.5, "community", SLOW .. ": 'Equip' 0.5 seconds (game files)"),
		moveMultiplier = p(1.0, "estimate", "Run speed with it in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(50, 0, 0, 0) },
		damageSource = p(0, "estimate", "None: its field slows (" .. SLOW .. "), and the orb itself hurts nobody"),
		penetration = "none",
		suppressed = false,
		ability = "sloworb",
		accuracy = slowExact,
		recoil = SLOW_KICK,
	},
	-- Sage's Barrier Orb (system 38): put in hand in the fifth slot by C
	-- (AbilityConfig.BarrierOrb), as the Slow Orb is by Q. Fire raises its
	-- wall where the targeter shows it; PlayerSim turns that into the
	-- ability's cast, so it fires no bullet, and keeps it in hand while
	-- there's nowhere to raise it. The wall stands in the way (BarrierSim);
	-- the orb itself hurts nobody.
	wallorb = {
		id = "wallorb",
		name = "Barrier Orb",
		category = "ability",
		slot = 5,
		price = p(0, "community", "Not bought here: C puts it in hand, the charge of the Barrier Orb (" .. BARRIER .. ")"),
		-- Held, it goes up as soon as it's in hand and there's somewhere for
		-- it (ours, as the Slow Orb's throw).
		fireMode = "auto",
		fireRate = WALL_TRIES,
		magazine = p(1, "community", BARRIER .. ": 1 use, a wall"),
		reserve = p(0, "community", "None: another wall is another charge (" .. BARRIER .. ": 1 use)"),
		reloadTime = BARRIER_NA,
		equipTime = p(0.8, "community", BARRIER .. ": equip 0.8 s (estimated)"),
		moveMultiplier = p(1.0, "estimate", "Run speed with it in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(50, 0, 0, 0) },
		damageSource = p(0, "estimate", "None: its wall stands in the way (" .. BARRIER .. "), and the orb itself hurts nobody"),
		penetration = "none",
		suppressed = false,
		ability = "barrierorb",
		accuracy = barrierExact,
		recoil = BARRIER_KICK,
	},
	-- Sage's Resurrection (system 39): put in hand in the fifth slot by X
	-- once its points are full (AbilityConfig.Resurrection), as the Healing
	-- Orb is by E. Fire tries it on the fallen ally whose body is under the
	-- crosshair; PlayerSim turns each try into the ability's cast, so it
	-- fires no bullet, and keeps it in hand, a try at a time, until the
	-- server finds one brings someone back (ReviveServer) and puts it away.
	revive = {
		id = "revive",
		name = "Resurrection",
		category = "ability",
		slot = 5,
		price = p(0, "community", "Not bought: X puts it in hand once the ultimate's points are full (" .. RESURRECTION .. ")"),
		fireMode = "semi",
		fireRate = ORB_TRIES,
		magazine = p(1, "community", RESURRECTION .. ": a revive"),
		reserve = p(0, "community", "None: another revive is another ultimate (" .. RESURRECTION .. ")"),
		reloadTime = ORB_NA,
		equipTime = p(0.8, "community", RESURRECTION .. ": equip time 0.8 s (game files)"),
		moveMultiplier = p(1.0, "estimate", "Run speed with it in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(50, 0, 0, 0) },
		damageSource = p(0, "estimate", "None: it brings back (" .. RESURRECTION .. "), and hurts nobody"),
		penetration = "none",
		suppressed = false,
		ability = "resurrection",
		accuracy = orbExact,
		recoil = ORB_KICK,
	},
	smokeorb = {
		id = "smokeorb",
		name = "Dark Cover",
		category = "ability",
		slot = 5,
		price = p(0, "community", "Not bought here: its charges are bought as an ability's (" .. DARK_COVER .. ")"),
		fireMode = "semi",
		fireRate = ORB_TRIES,
		magazine = p(1, "community", DARK_COVER .. ": a shadow orb"),
		reserve = p(0, "community", "None: another smoke is another charge (" .. DARK_COVER .. ")"),
		reloadTime = ORB_NA,
		equipTime = p(0.6, "community", DARK_COVER .. ": equip time 0.6 s (its estimate)"),
		moveMultiplier = p(1.0, "estimate", "Run speed with it in hand, assumed the knife's 6.75 m/s; not published"),
		damage = { band(50, 0, 0, 0) },
		damageSource = p(0, "estimate", "None: it smokes (" .. DARK_COVER .. "), and hurts nobody"),
		penetration = "none",
		suppressed = false,
		ability = "darkcover",
		accuracy = orbExact,
		recoil = ORB_KICK,
	},
} :: { [string]: WeaponDef }

-- Stable byte ids for the wire format (0 = empty slot): the first six as
-- they always were, the rest in alphabetical order after them, the spike
-- after those, then Blade Storm's knives (system 19), Curveball's flare
-- (system 30), Hot Hands' fireball (system 31), Blaze's flame (system 32),
-- the Healing Orb (system 36), the Slow Orb (system 37), the Barrier Orb
-- (system 38), the Resurrection (system 39) and Dark Cover (system 40)
-- last.
WeaponConfig.Ids = {
	"classic",
	"knife",
	"operator",
	"phantom",
	"sheriff",
	"vandal",
	"ares",
	"bandit",
	"bucky",
	"bulldog",
	"frenzy",
	"ghost",
	"guardian",
	"judge",
	"marshal",
	"odin",
	"outlaw",
	"shorty",
	"spectre",
	"stinger",
	"warden",
	"spike",
	"kunai",
	"flare",
	"fireball",
	"flamewall",
	"healorb",
	"iceorb",
	"wallorb",
	"revive",
	"smokeorb",
}
WeaponConfig.IndexOf = {} :: { [string]: number }
for i, id in WeaponConfig.Ids do
	WeaponConfig.IndexOf[id] = i
end

-- The buy menu's groups and the guns in each, in the reference's order.
WeaponConfig.Arsenal = {
	{ category = "sidearm" :: Category, name = "Sidearms", ids = { "classic", "shorty", "frenzy", "ghost", "bandit", "sheriff" } },
	{ category = "smg" :: Category, name = "SMGs", ids = { "stinger", "spectre" } },
	{ category = "shotgun" :: Category, name = "Shotguns", ids = { "bucky", "judge" } },
	{ category = "rifle" :: Category, name = "Rifles", ids = { "bulldog", "guardian", "phantom", "vandal", "warden" } },
	{ category = "sniper" :: Category, name = "Snipers", ids = { "marshal", "outlaw", "operator" } },
	{ category = "heavy" :: Category, name = "Machine guns", ids = { "ares", "odin" } },
}

WeaponConfig.DefaultLoadout = { "vandal", "classic", "knife" }

-- Player survivability: health, and a shield on top (WeaponConfig.Shields).
WeaponConfig.Health = {
	maxHealth = p(100, "community", "Standard agent health"),
	-- Hit slow ("tagging"). Riot's netcode blog confirms hits briefly slow the
	-- victim and Patch 3.0 gives the amount; the duration is ours.
	tagSpeedMultiplier = p(0.275, "confirmed", P30 .. ": 'Bullet tagging changed from 75% slow >>> 72.5% slow'"),
	tagDuration = p(0.15, "estimate", "Not published; measure from footage of a tagged player"),
}

-- Shields (system 9, Combat/Health). While a shield lasts it takes its share
-- of every hit (`absorb`) and the rest goes to health. A shield with `regen`
-- refills itself from a pool of its own, `rate` points a second, once it
-- hasn't been hit for `delay` seconds.
export type RegenDef = { pool: Param, delay: Param, rate: Param }
export type ShieldDef = { id: string, name: string, price: Param, points: Param, absorb: Param, regen: RegenDef? }

local ARMOR_SOURCES = "Sportskeeda's armor guide, Digital Trends and Dot Esports"
local ARMOR_ABSORB = p(
	0.66,
	"community",
	"Sportskeeda: 'shields offer 66% of damage mitigation'; Beebom: 'the other armors absorb 66% of incoming damage'. Patch 9.10 gives the Regen Shield's 100% as what sets it apart"
)

WeaponConfig.Shields = {
	light = {
		id = "light",
		name = "Light Armor",
		price = p(400, "community", ARMOR_SOURCES .. ": 400 credits"),
		points = p(25, "community", ARMOR_SOURCES .. ": 25"),
		absorb = ARMOR_ABSORB,
	},
	regen = {
		id = "regen",
		name = "Regen Shield",
		price = p(650, "confirmed", P910 .. ": 650 credits"),
		points = p(25, "confirmed", P910 .. ": 'Damage Absorption: 25 HP'"),
		absorb = p(1, "confirmed", P910 .. ": 'Absorbs 100% of incoming damage taken before damage to health occurs'"),
		regen = {
			pool = p(50, "confirmed", P910 .. ": 'Regeneration Pool: 50 HP'"),
			delay = p(
				3,
				"community",
				"Beebom: '3 seconds after your active armor depletes'; talkesport: 'if the player is out of combat for three seconds'. Counting from the last hit is ours"
			),
			rate = p(12.5, "estimate", P910 .. " says only 'after a brief delay, the shield regenerates'; 25 in 2 s is ours. Time a refill (09-arsenal.md section 3)"),
		},
	},
	heavy = {
		id = "heavy",
		name = "Heavy Armor",
		price = p(1000, "community", ARMOR_SOURCES .. ": 1000 credits"),
		points = p(50, "community", ARMOR_SOURCES .. ": 50"),
		absorb = ARMOR_ABSORB,
	},
} :: { [string]: ShieldDef }

-- The buy menu's order, cheapest first.
WeaponConfig.ShieldIds = { "light", "regen", "heavy" }

-- What everyone wears until they pick another: Skirmish starts every round in
-- Heavy Armor (community, docs/research/07-arena.md), and so does the course.
WeaponConfig.DefaultShield = "heavy"

WeaponConfig.MaxRange = 250 -- metres; bullets are hitscan

-- Wall penetration (Combat/Penetration, docs/research/05-wall-penetration.md).
-- Each weapon has a class; each surface a material: soft (wood, glass),
-- medium (stone, brick, concrete), hard (metal) or solid (never penetrable).
-- A bullet carries a budget of 1. A wall costs entryCost when the bullet
-- enters it from open air, plus thickness along the ray / limit of the rest,
-- so a single wall exactly `limit` thick, hit square on, takes the whole
-- budget. Hits past the walls take damage x (1 - damageLoss * budget spent).
WeaponConfig.Penetration = {
	classSource = p(
		0,
		"community",
		"Weapon classes (WeaponDef.penetration): the VALORANT Wiki's weapon pages, Shacknews (Apr 2020) and Codashop (Oct 2020) stat tables, Liquipedia Vandal 'Medium'. Riot names the classes in Patch 1.03 (Guardian 'Medium >>> Heavy') and gives the Bandit's and the Warden's (Medium) in Patches 12.00 and 13.06"
	),
	-- Thickest single wall of each material a class gets through, hit square on (metres).
	limits = {
		none = { soft = 0, medium = 0, hard = 0 },
		low = { soft = 0.25, medium = 0, hard = 0 },
		medium = { soft = 0.5, medium = 0.25, hard = 0 },
		high = { soft = 1.0, medium = 0.5, hard = 0.2 },
	} :: { [string]: { [string]: number } },
	limitsSource = p(
		0,
		"estimate",
		"Which class gets through which material is community (quarkez's tests via Dexerto, Jun 2020: glass and wood need low penetration, stone or brick medium, metal high); the thicknesses are ours"
	),
	entryCost = p(0.1, "estimate", "Not published; fit from the same wall at two angles (docs/research/05-wall-penetration.md)"),
	damageLoss = p(0.75, "estimate", "Not published; a bullet that barely gets through keeps a quarter of its damage. Fit from wallbang damage"),
	-- Pieces of geometry one shot is traced through, at most (bounds the raycasts).
	maxPieces = 16,
}

-- Accuracy rules shared by every weapon.
WeaponConfig.Accuracy = {
	-- Added to the cone for MovementConfig.jumpLandPenaltyTime after landing.
	landError = p(7, "confirmed", P109 .. ", all weapons: 'Jump land inaccuracy value increased from 5.0 >>> 7.0 (more inaccurate for .225s after a land)', a binary state"),
	-- Error power ("center biasing" at Riot) decides where in the cone a
	-- bullet lands: its distance from the centre is radius * u ^ power for a
	-- uniform random u. 0.5 spreads bullets evenly over the cone, 1 piles them
	-- toward the centre, and higher piles them more.
	errorPower = p(1, "estimate", P611 .. ": centre biasing works 'as intended for stationary firing'; the amount is not published"),
	moveErrorPower = p(0.6, "estimate", P611 .. ": shots fired while moving 'are now almost uniformly random within their spread cone'"),
	-- Seconds the view takes to settle after a viewKick (RecoilDef).
	viewKickTime = p(0.35, "estimate", "Measure from footage: how long a sniper's view takes to settle after a shot"),
}

function WeaponConfig.get(id: string): WeaponDef
	return WeaponConfig.Defs[id] or WeaponConfig.Defs.knife
end

-- Modes -------------------------------------------------------------------------

local function makeMode(
	name: ModeName,
	fireMode: "auto" | "semi" | "none",
	rate: number,
	pellets: number,
	ammo: number,
	acc: AccuracyDef,
	rec: RecoilDef,
	isZoomed: boolean,
	burst: BurstDef?,
	spin: SpinDef?
): Mode
	local interval = if rate > 0 then 1 / rate else math.huge
	local rounds, burstInterval = 1, interval
	if burst then
		rate = burst.rate.value
		interval = 1 / rate
		rounds = burst.rounds.value
		burstInterval = 1 / burst.perSecond.value
	end
	return {
		name = name,
		fireMode = fireMode,
		rate = rate,
		interval = interval,
		burstRounds = rounds,
		burstInterval = burstInterval,
		pellets = pellets,
		ammo = ammo,
		spin = spin,
		accuracy = acc,
		recoil = rec,
		zoomed = isZoomed,
	}
end

type Modes = { hip: Mode, zoom: Mode?, alt: Mode? }
local modes: { [string]: Modes } = {}
for id, def in WeaponConfig.Defs do
	local pellets = if def.pellets then def.pellets.value else 1
	local set: Modes = {
		hip = makeMode("hip", def.fireMode, def.fireRate.value, pellets, 1, def.accuracy, def.recoil, false, nil, def.spinUp),
	}
	local ads = def.ads
	if ads then
		set.zoom = makeMode("zoom", def.fireMode, def.fireRate.value * ads.fireRateMultiplier.value, pellets, 1, ads.accuracy, def.recoil, true, ads.burst, nil)
	end
	local alt = def.alt
	if alt then
		set.alt = makeMode("alt", alt.fireMode, alt.fireRate.value, alt.pellets.value, alt.ammo.value, alt.accuracy, alt.recoil, false, nil, nil)
	end
	modes[id] = set
end

-- How the weapon fires now: from the hip, zoomed (`scoped` > 0, for a weapon
-- that zooms) or, with `alt`, its right click if it fires one.
function WeaponConfig.mode(def: WeaponDef, scoped: number, alt: boolean?): Mode
	local set = modes[def.id] or modes.knife
	if alt and set.alt then
		return set.alt
	end
	if scoped > 0 and set.zoom then
		return set.zoom
	end
	return set.hip
end

-- The right click's mode, for a weapon whose right click fires.
function WeaponConfig.altMode(def: WeaponDef): Mode?
	local set = modes[def.id]
	return set and set.alt
end

-- Damage ------------------------------------------------------------------------

-- Damage for one hit (one pellet) at a distance (metres) on a region.
function WeaponConfig.damageAt(def: WeaponDef, region: "head" | "body" | "legs", distance: number): number
	local bands = def.damage
	for _, b in bands do
		if distance <= b.maxRange then
			return b[region]
		end
	end
	return bands[#bands][region]
end

-- Damage of a whole shot that lands every pellet on one region.
function WeaponConfig.shotDamage(def: WeaponDef, region: "head" | "body" | "legs", distance: number): number
	return WeaponConfig.damageAt(def, region, distance) * (if def.pellets then def.pellets.value else 1)
end

-- Shots to kill a target with `hp` total (health + shields) on one region,
-- every pellet hitting.
function WeaponConfig.shotsToKill(def: WeaponDef, region: "head" | "body" | "legs", distance: number, hp: number): number?
	local dmg = WeaponConfig.shotDamage(def, region, distance)
	if dmg <= 0 then
		return nil
	end
	return math.ceil(hp / dmg - 1e-9)
end

return WeaponConfig
