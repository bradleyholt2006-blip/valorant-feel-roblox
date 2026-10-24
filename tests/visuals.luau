--!strict
-- The look (system 6): the vignette's curve and the gradient that draws it,
-- the outline's tint by distance, and every number labelled.

local VisualConfig = require("../src/shared/Visuals/VisualConfig")
local VisualMath = require("../src/shared/Visuals/VisualMath")
local H = require("./Harness")

local check, near = H.check, H.near

local vig = VisualConfig.Vignette
local START, STRENGTH = vig.start.value, vig.strength.value
local O = VisualConfig.Outline

-- A UIGradient's transparency at `time`: straight between keypoints.
local function sample(points: { VisualMath.Keypoint }, time: number): number
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		if time <= b.time then
			local span = b.time - a.time
			return if span <= 0 then b.value else a.value + (b.value - a.value) * (time - a.time) / span
		end
	end
	return points[#points].value
end

local function enemyFill(distance: number): number
	return VisualMath.fillTransparency(distance, O.fillNear.value, O.fillFar.value, O.nearDistance.value, O.farDistance.value)
end

local function allyFill(distance: number): number
	return VisualMath.fillTransparency(distance, O.allyFillNear.value, O.allyFillFar.value, O.nearDistance.value, O.farDistance.value)
end

H.section("Visuals tests")

do
	local points = VisualMath.vignetteKeypoints(START, STRENGTH)
	local ordered = points[1].time == 0 and points[#points].time == 1
	for i = 2, #points do
		ordered = ordered and points[i].time > points[i - 1].time
	end
	check("the vignette fits in one NumberSequence (at most 20 keypoints)", #points <= VisualMath.MAX_KEYPOINTS, tostring(#points))
	check("its keypoints run from time 0 to 1, each after the last", ordered)
	check(
		"each edge is as dark as the strength, and the middle is clear",
		near(points[1].value, 1 - STRENGTH, 1e-12) and near(points[#points].value, 1 - STRENGTH, 1e-12) and sample(points, 0.5) == 1
	)
	local inner = (1 - START) / 2
	check("the clear middle spans the start on each side", sample(points, inner) == 1 and sample(points, 1 - inner) == 1 and sample(points, inner * 0.98) < 1)
	local worst = 0
	for i = 0, 2000 do
		local time = i / 2000
		local exact = 1 - VisualMath.vignetteAlpha(2 * time - 1, START, STRENGTH)
		worst = math.max(worst, math.abs(sample(points, time) - exact))
	end
	check("the gradient follows the curve to within 1% of the strength", worst <= 0.01 * STRENGTH, string.format("%.5f", worst))
	local rising = true
	for i = 1, 100 do
		rising = rising and VisualMath.vignetteAlpha(i / 100, START, STRENGTH) >= VisualMath.vignetteAlpha((i - 1) / 100, START, STRENGTH)
	end
	check("it only gets darker towards the edge", rising)
	check(
		"light: all of it in the middle, 1 - strength at an edge, both layers in a corner",
		VisualMath.vignetteLight(0, 0, START, STRENGTH) == 1
			and near(VisualMath.vignetteLight(1, 0, START, STRENGTH), 1 - STRENGTH, 1e-12)
			and near(VisualMath.vignetteLight(0, -1, START, STRENGTH), 1 - STRENGTH, 1e-12)
			and near(VisualMath.vignetteLight(-1, 1, START, STRENGTH), (1 - STRENGTH) ^ 2, 1e-12)
	)
	check("subtle: the corners keep at least 70% of their light", VisualMath.vignetteLight(1, 1, START, STRENGTH) >= 0.7)
	local clamped = VisualMath.vignetteKeypoints(0, STRENGTH)
	local clampedOrdered = true
	for i = 2, #clamped do
		clampedOrdered = clampedOrdered and clamped[i].time > clamped[i - 1].time
	end
	check("a start of 0 still gives keypoints in order", clampedOrdered and clamped[#clamped].time == 1)
end

do
	check(
		"the enemy tint is lightest up close and strongest far away",
		enemyFill(0) == O.fillNear.value
			and enemyFill(O.nearDistance.value) == O.fillNear.value
			and near(enemyFill(O.farDistance.value), O.fillFar.value, 1e-12)
			and enemyFill(500) == O.fillFar.value
	)
	local growing = true
	for d = 1, 80 do
		growing = growing and enemyFill(d) <= enemyFill(d - 1) and allyFill(d) <= allyFill(d - 1)
	end
	check("the tint only grows with distance", growing)
	local stronger = O.outline.value < O.allyOutline.value
	for d = 0, 80, 5 do
		stronger = stronger and enemyFill(d) < allyFill(d)
	end
	check("enemies stand out more than allies at every distance", stronger)
	check("the tint never hides the target", O.fillFar.value >= 0.5 and O.allyFillFar.value >= 0.5)
end

do
	local ok = true
	local function bad(name: string)
		ok = false
		print("    missing or unlabelled: " .. name)
	end
	local statuses = { confirmed = true, community = true, estimate = true }
	local function param(name: string, v: any)
		if type(v) ~= "table" or type(v.value) ~= "number" or not statuses[v.status] or type(v.source) ~= "string" or v.source == "" then
			bad(name)
		end
	end
	local function colour(name: string, v: any)
		local channels = type(v) == "table" and v.rgb
		if type(channels) ~= "table" or #channels ~= 3 or not statuses[v.status] or type(v.source) ~= "string" or v.source == "" then
			bad(name)
			return
		end
		for _, c in channels do
			if type(c) ~= "number" or c < 0 or c > 255 or c % 1 ~= 0 then
				bad(name)
			end
		end
	end
	local groups: { [string]: any } = {
		Lighting = VisualConfig.Lighting,
		Colour = VisualConfig.Colour,
		Bloom = VisualConfig.Bloom,
		Vignette = VisualConfig.Vignette,
		Outline = VisualConfig.Outline,
	}
	for group, entries in groups do
		for key, v in entries do
			if type(v) == "table" and v.rgb then
				colour(group .. "." .. key, v)
			else
				param(group .. "." .. key, v)
			end
		end
	end
	colour("allyColour", VisualConfig.allyColour)
	for i, option in VisualConfig.EnemyColours do
		colour("EnemyColours[" .. i .. "]", option.colour)
	end
	check("every number has a status and a source", ok)
	local names = {}
	for _, option in VisualConfig.EnemyColours do
		table.insert(names, option.name)
	end
	check(
		"the four enemy colours, in the reference's order",
		table.concat(names, ", ") == "Red (Default), Purple (Tritanopia), Yellow (Deuteranopia), Yellow (Protanopia)",
		table.concat(names, ", ")
	)
end

H.section("Visuals report")
print(string.format("vignette (estimates): clear to %.0f%% of the way out, %.0f%% darker at each edge", START * 100, STRENGTH * 100))
print("  darkening across the screen, middle to edge:")
local row = "   "
for _, t in { 0, 0.45, 0.6, 0.7, 0.8, 0.9, 1 } do
	row ..= string.format("  %.2f %4.1f%%", t, VisualMath.vignetteAlpha(t, START, STRENGTH) * 100)
end
print(row)
print(string.format("  corner %.1f%%", (1 - VisualMath.vignetteLight(1, 1, START, STRENGTH)) * 100))
print("outline tint by distance (estimates; opacity, enemy / ally):")
row = "   "
for _, d in { 5, 10, 20, 30, 40, 50 } do
	row ..= string.format("  %2d m %2.0f%% / %2.0f%%", d, (1 - enemyFill(d)) * 100, (1 - allyFill(d)) * 100)
end
print(row)

return nil
