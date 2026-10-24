--!strict
-- Measurements of the reference game, entered by hand from frame-counted
-- footage (see the "Measurement protocol" sections in docs/research).
-- Leave a value nil until it has been measured. `n` is the number of trials
-- averaged, `source` says where it came from (clip name, date, fps).
--
-- Keyed by weapon id. The Counter-Strafe Lab reads the movement fields and
-- the Weapon Lab reads the weapon fields, and both show our numbers next to
-- these with the difference.

export type Measurement = { value: number, n: number, source: string }

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
