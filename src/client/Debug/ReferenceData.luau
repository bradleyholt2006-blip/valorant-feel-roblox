--!strict
-- Measurements of the reference game, entered by hand from frame-counted
-- footage (see the "Measurement protocol" sections in docs/research).
-- Leave a value nil until it has been measured. `n` is the number of trials
-- averaged, `source` says where it came from (clip name, date, fps).
--
-- Keyed by weapon id. The Counter-Strafe Lab reads the movement fields, the
-- Weapon Lab the weapon fields and the Spray Lab the spread and recoil
-- fields, and each shows our numbers next to these.

export type Measurement = { value: number, n: number, source: string }

-- A spray's bullets as {right, up} degrees from the aim, bullet 1 first.
export type SprayPattern = { points: { { number } }, n: number, source: string }

export type Entry = {
	-- Movement (seconds / metres)
	timeTo95: Measurement?, -- standing -> 95% of run speed
	releaseTimeToAccurate: Measurement?, -- key release -> movement error indicator collapses
	releaseTimeToZero: Measurement?, -- key release -> fully stopped
	releaseSlide: Measurement?, -- distance travelled after release
	counterTimeToAccurate: Measurement?, -- opposite key press -> indicator collapses
	counterSlide: Measurement?,
	-- Weapons (seconds)
	fireInterval: Measurement?, -- muzzle flash to muzzle flash while holding fire
	reloadTime: Measurement?, -- reload start -> ammo counter refills
	equipTime: Measurement?, -- switch key -> first shot with fire held
	-- Spread and recoil (degrees)
	firstShotError: Measurement?, -- radius holding most single taps at a wall from a fixed distance
	sprayPattern: SprayPattern?, -- full spray at a wall, mouse untouched, averaged over sprays
}

local ReferenceData: { [string]: Entry } = {
	vandal = {},
	phantom = {},
	operator = {},
	classic = {},
	sheriff = {},
	knife = {},
}

return ReferenceData
