--!strict
-- Measurements of the reference game, entered by hand from frame-counted
-- footage (see docs/research/01-movement.md, "Measurement protocol").
-- Leave a value nil until it has been measured. `n` is the number of trials
-- averaged, `source` says where it came from (clip name, date, fps).
--
-- The Counter-Strafe Lab shows our numbers next to these and the difference.

export type Measurement = { value: number, n: number, source: string }

local ReferenceData: { [string]: { [string]: Measurement? } } = {
	rifle = {
		timeTo95 = nil, -- s, standing -> 95% of run speed
		releaseTimeToAccurate = nil, -- s, key release -> movement error indicator collapses
		releaseTimeToZero = nil, -- s, key release -> fully stopped
		releaseSlide = nil, -- m, distance travelled after release
		counterTimeToAccurate = nil, -- s, opposite key press -> indicator collapses
		counterSlide = nil, -- m
	},
	sniper = {},
	knife = {},
}

return ReferenceData
