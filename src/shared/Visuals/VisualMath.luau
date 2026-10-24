--!strict
-- The look's maths (system 6), shared by the client and the offline tests:
-- the vignette's curve and the gradient keypoints that draw it, and the
-- outline's tint by distance.

local VisualMath = {}

-- Roblox's limit on keypoints in a NumberSequence.
VisualMath.MAX_KEYPOINTS = 20

export type Keypoint = { time: number, value: number }

local function smoothstep(edge0: number, edge1: number, x: number): number
	local t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

-- How dark one vignette layer is (0 clear, 1 black) at t, the position
-- across the screen from -1 (one edge) through 0 (the middle) to 1 (the
-- other edge): clear out to `start`, then easing in to `strength` at the edge.
function VisualMath.vignetteAlpha(t: number, start: number, strength: number): number
	return strength * smoothstep(start, 1, math.abs(t))
end

-- The share of light the two layers (sides, and top and bottom) let through
-- at screen position x, y (each -1 to 1).
function VisualMath.vignetteLight(x: number, y: number, start: number, strength: number): number
	return (1 - VisualMath.vignetteAlpha(x, start, strength)) * (1 - VisualMath.vignetteAlpha(y, start, strength))
end

-- One layer as UIGradient transparency keypoints across the screen (time 0
-- to 1): `perSide` points on each side, evenly spaced from the edge to where
-- the darkening begins, and nothing between, where the layer is clear. A
-- gradient blends straight between keypoints, which follows the curve to
-- under 1% of `strength` with the default 10 a side.
function VisualMath.vignetteKeypoints(start: number, strength: number, perSide: number?): { Keypoint }
	local n = perSide or VisualMath.MAX_KEYPOINTS // 2
	start = math.clamp(start, 0.05, 0.95)
	-- Gradient time where the left side's darkening ends (t = -start).
	local inner = (1 - start) / 2
	local points: { Keypoint } = {}
	for i = 0, n - 1 do
		local time = inner * i / (n - 1)
		table.insert(points, { time = time, value = 1 - VisualMath.vignetteAlpha(2 * time - 1, start, strength) })
	end
	for i = n - 1, 0, -1 do
		local time = 1 - inner * i / (n - 1)
		table.insert(points, { time = time, value = 1 - VisualMath.vignetteAlpha(2 * time - 1, start, strength) })
	end
	return points
end

-- The outline's tint transparency at a distance in metres: `near` out to
-- `nearDistance`, `far` from `farDistance`, straight between.
function VisualMath.fillTransparency(distance: number, near: number, far: number, nearDistance: number, farDistance: number): number
	local t = math.clamp((distance - nearDistance) / math.max(farDistance - nearDistance, 1e-6), 0, 1)
	return near + (far - near) * t
end

return VisualMath
