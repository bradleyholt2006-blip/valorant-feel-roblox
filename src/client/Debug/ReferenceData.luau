--!strict
-- Measurements of the reference game, entered by hand from frame-counted
-- footage (see the "Measurement protocol" sections in docs/research).
-- Leave a value nil until it has been measured. `n` is the number of trials
-- averaged, `source` says where it came from (clip name, date, fps).
--
-- Keyed by weapon id. The Counter-Strafe Lab reads the movement fields, the
-- Weapon Lab the weapon and wallbang fields and the Spray Lab the spread and
-- recoil fields, and each shows our numbers next to these.

export type Measurement = { value: number, n: number, source: string }

-- A spray's bullets as {right, up} degrees from the aim, bullet 1 first.
export type SprayPattern = { points: { { number } }, n: number, source: string }

-- Damage through one wall as a share of the same hit in the open (same
-- dummy, region and range). `material` is the wall's class here ("soft",
-- "medium" or "hard"), `thickness` our best guess at the wall in metres and
-- `angle` how far off square on the shot was, in degrees. Leave `fraction`
-- nil for a wall the weapon doesn't get through.
export type Wallbang = { wall: string, material: string, thickness: number, angle: number, fraction: number?, n: number, source: string }

export type Entry = {
	-- Movement (seconds / metres)
	timeTo95: Measurement?, -- standing -> 95% of run speed
	releaseTimeToAccurate: Measurement?, -- key release -> movement error indicator collapses
	releaseTimeToZero: Measurement?, -- key release -> fully stopped
	releaseSlide: Measurement?, -- distance travelled after release
	counterTimeToAccurate: Measurement?, -- opposite key press -> indicator collapses
	counterTimeToZero: Measurement?, -- opposite key press -> fully stopped
	counterSlide: Measurement?,
	-- Weapons (seconds)
	fireInterval: Measurement?, -- muzzle flash to muzzle flash while holding fire
	reloadTime: Measurement?, -- reload start -> ammo counter refills
	equipTime: Measurement?, -- switch key -> first shot with fire held
	-- Spread and recoil (degrees)
	firstShotError: Measurement?, -- radius holding most single taps at a wall from a fixed distance
	sprayPattern: SprayPattern?, -- full spray at a wall, mouse untouched, averaged over sprays
	-- Wall penetration
	wallbangs: { Wallbang }?, -- docs/research/05-wall-penetration.md, "Measurement protocol"
}

-- Riot timed stops from a full run on the Phantom (Riot_Classick on
-- r/VALORANT, 2020, tests by the designer Excal; "approximate because of
-- inconsistent frame rates and human input"). Times to the deadzone were taken
-- at the beta's 25%, so only the times to a full stop are entered here; the
-- offline tests check the 25% times (0.104 s counter-strafing, 0.110 s
-- without). The Vandal runs at the same 5.40 m/s, so it shares them.
local RIOT_2020 = "Riot_Classick, r/VALORANT 2020 (Excal's Phantom test)"
local RIFLE_STOPS: Entry = {
	counterTimeToZero = { value = 0.160, n = 1, source = RIOT_2020 .. ": standard counter-strafing, 'Run -> Stop (0%): 0.160s'" },
	releaseTimeToZero = {
		value = 0.170,
		n = 1,
		source = RIOT_2020 .. ": no counter-strafe with walk bound to fire, 0.170s; Riot says letting go of the keys is at least as fast",
	},
}

local ReferenceData: { [string]: Entry } = {
	vandal = table.clone(RIFLE_STOPS),
	phantom = table.clone(RIFLE_STOPS),
	operator = {},
	classic = {},
	sheriff = {},
	knife = {},
}

return ReferenceData
