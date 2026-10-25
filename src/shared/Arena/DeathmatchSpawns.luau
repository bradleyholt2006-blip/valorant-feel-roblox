--!strict
-- Where each life starts in deathmatch (system 26), as plain maths the
-- offline tests can check: anywhere on the map, at 'ideal locations that
-- are free of enemies but close to the action' (the reference's support
-- page), farther from where the player fell (Patch 4.03), and facing the
-- way the fight is (DeathmatchConfig):
--   * the places a life can start are a grid across each map's floor, every
--     spotSpacing metres, each with spotClearance metres clear of walls and
--     cover, and with how far the floor runs open ahead of it each of eight
--     ways
--   * a new life goes where no living enemy can see it and none is within
--     safeDistance, preferring, in turn: one with an enemy within
--     actionDistance (close to the action) that's deathDistance or more from
--     where the player fell; one that far from there; one close to the
--     action; then any, at random among the best. If every such place is
--     seen, or none is far enough from everyone, the farthest from every
--     enemy that nobody sees, and if every place is seen, the farthest
--   * it faces whichever of the eight ways with openView metres of open
--     floor ahead is nearest the way to the nearest enemy (to the middle of
--     the map with nobody else alive), or else the most open way
--
-- What sees what is the caller's: the server asks Roblox (a raycast from
-- eye to eye against the map's parts), the tests a plain test against the
-- map's walls and tall cover. Everything here is in the map's own metres.

local DeathmatchConfig = require("./DeathmatchConfig")
local MapPlan = require("../Match/MapPlan")

local D = DeathmatchConfig.Rules

-- A place a life can start: its feet, and the metres of open floor ahead of
-- it each of the eight ways (WAYS), up to openView.
export type Spot = { feet: vector, open: { number } }
-- Whether someone standing with their feet at `a` sees someone standing at `b`.
export type Sees = (a: vector, b: vector) -> boolean
-- Where a new life starts: its feet, and the camera yaw it faces (as a
-- MapPlan.Spot's: 0 faces -z).
export type Choice = { feet: vector, yaw: number }

local DeathmatchSpawns = {}

-- The eight ways, as camera yaws: 0 faces -z, and pi/2 faces -x.
local WAYS: { number } = {}
for k = 0, 7 do
	table.insert(WAYS, k * math.pi / 4)
end
DeathmatchSpawns.WAYS = WAYS

-- The way a yaw faces, along the floor.
local function facing(yaw: number): vector
	return vector.create(-math.sin(yaw), 0, -math.cos(yaw))
end

-- The yaw that faces from `a` toward `b`.
function DeathmatchSpawns.yawToward(a: vector, b: vector): number
	local d = b - a
	return math.atan2(-d.x, -d.z)
end

-- How far apart two yaws are, from 0 to pi.
local function turn(a: number, b: number): number
	local d = (a - b) % (2 * math.pi)
	return if d > math.pi then 2 * math.pi - d else d
end

-- How far apart two places are along the floor.
local function apart(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

-- Every place on `map` a life can start.
function DeathmatchSpawns.spots(map: MapPlan.Map): { Spot }
	local spacing, clear, view = D.spotSpacing.value, D.spotClearance.value, D.openView.value
	local covers = map.cover()
	local function inCover(x: number, z: number, margin: number): boolean
		for _, c in covers do
			if math.abs(x - c.x) < c.sx / 2 + margin and math.abs(z - c.z) < c.sz / 2 + margin then
				return true
			end
		end
		return false
	end
	-- Floor under the whole square, sampled closer than the 1 m rooms are
	-- laid on, so no corner of wall can come between the samples.
	local function clearAt(x: number, z: number): boolean
		for _, dx in { -clear, 0, clear } do
			for _, dz in { -clear, 0, clear } do
				if not map.onFloor(x + dx, z + dz) then
					return false
				end
			end
		end
		return not inCover(x, z, clear)
	end
	-- Open floor ahead, in half-metre steps, up to the view's length.
	local function openAhead(x: number, z: number, yaw: number): number
		local dir = facing(yaw)
		local d = 0
		while d < view do
			local ahead = d + 0.5
			local px, pz = x + dir.x * ahead, z + dir.z * ahead
			if not map.onFloor(px, pz) or inCover(px, pz, 0) then
				break
			end
			d = ahead
		end
		return d
	end
	local x0, z0, x1, z1 = map.bounds()
	local out: { Spot } = {}
	local x = x0 + spacing / 2
	while x < x1 do
		local z = z0 + spacing / 2
		while z < z1 do
			if clearAt(x, z) then
				local open = {}
				for _, yaw in WAYS do
					table.insert(open, openAhead(x, z, yaw))
				end
				table.insert(out, { feet = vector.create(x, 0, z), open = open })
			end
			z += spacing
		end
		x += spacing
	end
	return out
end

-- The way a new life at `spot` faces, toward `toward`.
local function face(spot: Spot, toward: vector): Choice
	local want = DeathmatchSpawns.yawToward(spot.feet, toward)
	local best, bestOpen, bestTurn = 1, -1, math.huge
	local enough = D.openView.value - 1e-9
	for k, yaw in WAYS do
		local open = math.min(spot.open[k], enough)
		local t = turn(yaw, want)
		if open > bestOpen + 1e-9 or (math.abs(open - bestOpen) <= 1e-9 and t < bestTurn) then
			best, bestOpen, bestTurn = k, open, t
		end
	end
	return { feet = spot.feet, yaw = WAYS[best] }
end

-- Where a new life starts, of `spots`: `enemies` are the living enemies'
-- feet and `died` where the player fell, if they did; `sees` says what sees
-- what, and `roll` is the dice (MapVote.Roll's: a whole number from 1 to n).
function DeathmatchSpawns.choose(spots: { Spot }, enemies: { vector }, died: vector?, sees: Sees, roll: (number) -> number): Choice
	if #spots == 0 then
		return { feet = vector.zero, yaw = 0 }
	end
	local safe, action, away = D.safeDistance.value, D.actionDistance.value, D.deathDistance.value
	local nearest: { [Spot]: number } = {}
	local tiers: { { Spot } } = { {}, {}, {}, {} }
	for _, spot in spots do
		local near = math.huge
		for _, enemy in enemies do
			near = math.min(near, apart(spot.feet, enemy))
		end
		nearest[spot] = near
		if near >= safe then
			local close = near <= action
			local far = died == nil or apart(spot.feet, died) >= away
			table.insert(tiers[if close and far then 1 elseif far then 2 elseif close then 3 else 4], spot)
		end
	end
	local function seen(spot: Spot): boolean
		for _, enemy in enemies do
			if sees(enemy, spot.feet) then
				return true
			end
		end
		return false
	end
	-- Faced toward the nearest enemy, or the map's middle.
	local function chosen(spot: Spot): Choice
		local toward, best = vector.zero, math.huge
		for _, enemy in enemies do
			local d = apart(spot.feet, enemy)
			if d < best then
				toward, best = enemy, d
			end
		end
		return face(spot, toward)
	end
	for _, tier in tiers do
		-- At random among them, the first nobody sees.
		local left = table.clone(tier)
		while #left > 0 do
			local i = roll(#left)
			local spot = left[i]
			left[i] = left[#left]
			left[#left] = nil
			if not seen(spot) then
				return chosen(spot)
			end
		end
	end
	-- Nowhere both safe and unseen: the farthest from everyone that's unseen,
	-- or failing that the farthest.
	local order = table.clone(spots)
	table.sort(order, function(a: Spot, b: Spot): boolean
		return nearest[a] > nearest[b]
	end)
	for _, spot in order do
		if not seen(spot) then
			return chosen(spot)
		end
	end
	return chosen(order[1])
end

return DeathmatchSpawns
