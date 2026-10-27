--!strict
-- Ultimate Orbs in the spike rounds (system 49): two on each map, both up
-- as each round starts, and each taken once a round by whoever holds F at
-- it for collectTime, for a point of their ultimate
-- (AbilityConfig.Points.orb). Holding F roots the taker and puts the gun
-- away, as a defuse does, and letting go ends it with nothing gained. It's
-- stepped in each player's simulation beside the plant and the defuse
-- (SpikeSim's third channel), which is told which orbs are up
-- (Spike.Context.orbs). This keeps the numbers, where each map's orbs
-- stand, which are up, and whose feet are close enough to take one.
--
-- They stand where Team Deathmatch's do (system 28, its Pickups'
-- ultimate): one down each site's main (A long on Foundry), 6 to 10 m less
-- of a run from the attackers' spawn than from the defenders' (the offline
-- tests check, and print the runs), as the reference's are 'usually near
-- attacker side spawn' (valorantinfo.gg) and Ascent's and Split's are in A
-- main and B main (Sportskeeda).
--
-- Same status convention as Spike. Its requires are plain data, so it runs
-- in Studio and in the offline tests.

local SpikeMaps = require("../Match/SpikeMaps")
local TeamDeathmatchConfig = require("../Arena/TeamDeathmatchConfig")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local UltimateOrbs = {}

-- Which orbs are up, as Workspace's attribute has it: their numbers, "1,2".
UltimateOrbs.UP = "VFOrbs"

UltimateOrbs.Params = {
	perMap = p(
		2,
		"confirmed",
		"Patch 8.0: Icebox's B orb removed 'to bring it more in line with our other maps (with Fracture being the exception with 4)'"
	),
	collectTime = p(
		2,
		"estimate",
		"Seconds F is held to take one. Dexerto's Spike Rush guide: its orbs are 'acquired in the same way as an Ultimate orb',"
			.. " interacting with one 'for a few seconds'; no source gives the number"
	),
	reach = p(1.5, "estimate", "Metres across the floor from an orb's mark the feet may be to take it; not published"),
	height = p(1.2, "estimate", "Metres above or below an orb's mark the feet may be, as a defuser's from the spike"),
}

-- Each map's places, worked out once.
local placesByLayout: { [string]: { vector } } = {}

-- Where each of the map `layout`'s orbs stands, by number, in metres on its
-- floor: none where the spike rounds aren't played (the course).
function UltimateOrbs.placesOf(layout: string): { vector }
	local known = placesByLayout[layout]
	if known then
		return known
	end
	local places = {}
	local map = SpikeMaps.Maps[layout]
	local plan = TeamDeathmatchConfig.Pickups[layout]
	if map and plan then
		for i, at in plan.ultimate do
			places[i] = map.origin + at
		end
	end
	placesByLayout[layout] = places
	return places
end

-- A map's orbs, and which are up.
export type State = { layout: string, places: { vector }, up: { boolean } }

-- The orbs of the map `layout`, none up yet.
function UltimateOrbs.new(layout: string): State
	local places = UltimateOrbs.placesOf(layout)
	return { layout = layout, places = places, up = table.create(#places, false) }
end

-- Every orb up, as a round starts.
function UltimateOrbs.roundStarted(s: State)
	for i in s.places do
		s.up[i] = true
	end
end

-- Orb `orb` taken, if it's up: whether it was.
function UltimateOrbs.take(s: State, orb: number): boolean
	if s.up[orb] ~= true then
		return false
	end
	s.up[orb] = false
	return true
end

-- The orbs up, by number, where each stands (Spike.Context.orbs).
function UltimateOrbs.upOf(s: State): { [number]: vector }
	local orbs = {}
	for i, at in s.places do
		if s.up[i] then
			orbs[i] = at
		end
	end
	return orbs
end

-- Which are up, as UltimateOrbs.UP has it.
function UltimateOrbs.encode(s: State): string
	local numbers = {}
	for i in s.places do
		if s.up[i] then
			table.insert(numbers, tostring(i))
		end
	end
	return table.concat(numbers, ",")
end

-- The orbs up of the map `layout`, from UltimateOrbs.UP's text.
function UltimateOrbs.decode(layout: string, text: any): { [number]: vector }
	local orbs = {}
	if typeof(text) ~= "string" then
		return orbs
	end
	local places = UltimateOrbs.placesOf(layout)
	for number in string.gmatch(text, "%d+") do
		local i = tonumber(number) :: number
		local at = places[i]
		if at then
			orbs[i] = at
		end
	end
	return orbs
end

-- Whether feet at `feet` can take an orb whose mark is at `at`: near enough
-- across the floor, and not too far above or below it.
function UltimateOrbs.reaches(feet: vector, at: vector): boolean
	local P = UltimateOrbs.Params
	local dx, dz = feet.x - at.x, feet.z - at.z
	return dx * dx + dz * dz <= P.reach.value * P.reach.value and math.abs(feet.y - at.y) <= P.height.value
end

-- The orb among `orbs` that feet at `feet` can take, the nearest if more
-- than one can be (the lower number if they're as near); nil for none.
function UltimateOrbs.inReach(orbs: { [number]: vector }, feet: vector): number?
	local best: number? = nil
	local bestDistance = math.huge
	for i, at in orbs do
		if UltimateOrbs.reaches(feet, at) then
			local d = vector.magnitude(feet - at)
			if d < bestDistance or (d == bestDistance and best ~= nil and i < best) then
				best, bestDistance = i, d
			end
		end
	end
	return best
end

return UltimateOrbs
