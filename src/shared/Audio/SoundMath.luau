--!strict
-- The sums behind the sound (system 8): volume by distance on a curve, the
-- curve in studs for Roblox's AudioEmitter, the filter for walls in the way
-- and for distance, how much of the level lies between a sound and the
-- listener, how loud each recording is played, and when a reload's parts
-- sound.
--
-- Pure (no Roblox APIs), so the offline tests check it.

local Penetration = require("../Combat/Penetration")
local SoundConfig = require("./SoundConfig")

local SoundMath = {}

-- A curve's volume at a distance: straight lines between its points, flat
-- before the first and after the last (as AudioEmitter draws one).
function SoundMath.curveAt(points: { { number } }, distance: number): number
	local first = points[1]
	if distance <= first[1] then
		return first[2]
	end
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		if distance <= b[1] then
			local span = b[1] - a[1]
			return if span <= 0 then b[2] else a[2] + (b[2] - a[2]) * (distance - a[1]) / span
		end
	end
	return points[#points][2]
end

-- Where a curve goes silent: its first point at volume 0, or nil if it
-- never does.
function SoundMath.radius(points: { { number } }): number?
	for _, point in points do
		if point[2] <= 0 then
			return point[1]
		end
	end
	return nil
end

-- The same shape stretched or squeezed so it goes silent at `radius`.
function SoundMath.scaled(points: { { number } }, radius: number): { { number } }
	local from = SoundMath.radius(points) or points[#points][1]
	local k = if from > 0 then radius / from else 1
	local out = table.create(#points)
	for i, point in points do
		out[i] = { point[1] * k, point[2] }
	end
	return out
end

-- The curve as AudioEmitter:SetDistanceAttenuation takes it: studs to volume.
function SoundMath.studsCurve(points: { { number } }, studsPerMetre: number): { [number]: number }
	local out: { [number]: number } = {}
	for _, point in points do
		out[point[1] * studsPerMetre] = point[2]
	end
	return out
end

local function logLerp(a: number, b: number, u: number): number
	return math.exp(math.log(a) + (math.log(b) - math.log(a)) * u)
end

-- How far `x` is from `lo` to `hi` on a log scale, 0 to 1.
local function logFraction(x: number, lo: number, hi: number): number
	return math.clamp((math.log(x) - math.log(lo)) / (math.log(hi) - math.log(lo)), 0, 1)
end

-- The low-pass cutoff (Hz) and volume for `thickness` metres of level in
-- the way: open with none, the thin values up to a thin wall, the thick
-- ones past a thick wall, and between by the log of the thickness.
function SoundMath.occlusion(thickness: number): (number, number)
	local o = SoundConfig.Occlusion
	if thickness <= 0 then
		return SoundConfig.OPEN_CUTOFF, 1
	end
	local u = logFraction(math.max(thickness, o.thin.value), o.thin.value, o.thick.value)
	local gain = o.thinGain.value + (o.thickGain.value - o.thinGain.value) * u
	return logLerp(o.thinCutoff.value, o.thickCutoff.value, u), gain
end

-- The low-pass cutoff (Hz) the air leaves a gunshot at `distance` metres.
function SoundMath.airCutoff(distance: number): number
	local a = SoundConfig.Air
	if distance <= a.near.value then
		return SoundConfig.OPEN_CUTOFF
	end
	return logLerp(SoundConfig.OPEN_CUTOFF, a.farCutoff.value, logFraction(distance, a.near.value, a.far.value))
end

-- Metres of level on the straight line from `from` to `to`, and how many
-- separate pieces of it, at most `maxPieces`. A piece the line ends inside
-- counts up to the end.
function SoundMath.blockage(level: Penetration.Level, from: vector, to: vector, maxPieces: number): (number, number)
	local delta = to - from
	local length = vector.magnitude(delta)
	if length < 1e-3 then
		return 0, 0
	end
	local dir = delta / length
	local skip = {}
	local thickness, pieces = 0, 0
	while pieces < maxPieces do
		local surface = level:cast(from, dir, length, skip)
		if not surface or surface.distance >= length then
			break
		end
		local exit = level:exit(from, dir, surface, length - surface.distance)
		thickness += math.min(exit or length, length) - surface.distance
		pieces += 1
		table.insert(skip, surface.key)
	end
	return thickness, pieces
end

-- Whether a draw makes its sound: always for a switch to another slot, and
-- for the slot in hand drawn again (a weapon given into it) only once the
-- last draw sound is at least SoundConfig.RedrawGap old.
function SoundMath.drawHeard(switched: boolean, sinceLastDraw: number): boolean
	return switched or sinceLastDraw >= SoundConfig.RedrawGap.value
end

-- The kill sound's playback speed for the nth kill of a life.
function SoundMath.killPitch(kills: number): number
	return 1 + SoundConfig.KillPitchStep.value * (math.clamp(kills, 1, 5) - 1)
end

-- How much an asset is turned up or down so its peak meets the level.
function SoundMath.assetGain(peak: number): number
	if peak <= 0 then
		return 1
	end
	return math.min(SoundConfig.Level.value / peak, SoundConfig.MaxGain.value)
end

-- The parts of a reload `length` seconds long that are due `elapsed`
-- seconds into it, from cue `from` on: their sounds, and the next cue
-- still to come.
function SoundMath.cuesDue(cues: { SoundConfig.Cue }, from: number, elapsed: number, length: number): ({ string }, number)
	local due = {}
	local i = from
	while i <= #cues and elapsed >= cues[i].at * length do
		table.insert(due, cues[i].sound)
		i += 1
	end
	return due, i
end

return SoundMath
