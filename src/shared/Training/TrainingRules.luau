--!strict
-- Basic Training (system 72), a step at a time on TrainingConfig's list:
-- where a player is in it, and what moves them on. Each step's goal is
-- checked from what the server sees:
--   * reach: their feet within the step's radius of its spot across the
--     floor, on the ground, high enough and crouched where it says
--   * walk: its metres moved with walk held, on the ground, at a walk
--   * kill: the target by its spot downed, by a shot fired standing still,
--     to the head or aiming down sights where it says; a target downed
--     another way leaves a note why it didn't count
--   * reload: the gun in hand's magazine filling again
--   * shield: a shield worn
--   * cast: each of its slots used once, readying one aside
--   * plant and defuse: the spike planted, and defused; gone off first,
--     it's back to planting
-- TrainingServer feeds it and publishes where each player is.
--
-- No Roblox APIs here.

local TrainingConfig = require("./TrainingConfig")

local P = TrainingConfig.Params
local STEPS = TrainingConfig.Steps

local TrainingRules = {}

-- A player's way through: the step under way (an index into the steps),
-- what counts toward it so far, and a note on why something didn't count.
export type State = {
	index: number,
	walked: number, -- metres
	from: vector?, -- where the last tick that counted toward the walk ended
	cast: { [number]: boolean }, -- the kit's slots used
	weapon: string?, -- the gun in hand last tick, and its magazine
	ammo: number?,
	note: string?, -- a template with {name}s
}

-- How a downed target was downed: by a shot fired standing still, to the
-- head, aiming down sights.
export type Kill = { still: boolean, head: boolean, scoped: boolean }
-- The input in use, for the buttons' names: the keys, a gamepad's, a touch
-- screen's.
export type Input = "keys" | "pad" | "touch"

function TrainingRules.new(): State
	return { index = 1, walked = 0, from = nil, cast = {}, weapon = nil, ammo = nil, note = nil }
end

function TrainingRules.current(s: State): TrainingConfig.Step
	return STEPS[s.index]
end

-- The index of the step with this key, if there is one.
function TrainingRules.indexOf(key: any): number?
	for i, step in STEPS do
		if step.key == key then
			return i
		end
	end
	return nil
end

-- Onto step `index`, starting it afresh.
function TrainingRules.go(s: State, index: number)
	s.index = math.clamp(index, 1, #STEPS)
	s.walked = 0
	s.from = nil
	table.clear(s.cast)
	s.weapon, s.ammo = nil, nil
	s.note = nil
end

-- Onto the next step; false at the last, which never ends.
function TrainingRules.advance(s: State): boolean
	if s.index >= #STEPS then
		return false
	end
	TrainingRules.go(s, s.index + 1)
	return true
end

local function across(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

-- Whether feet at `feet`, on the ground or not and crouched or not, are
-- where `step` asks.
function TrainingRules.reached(step: TrainingConfig.Step, feet: vector, grounded: boolean, crouched: boolean): boolean
	local at = step.at
	if not at or not grounded or across(feet, at) > (step.radius or 1) then
		return false
	end
	if step.above and feet.y < step.above then
		return false
	end
	return not step.crouched or crouched
end

-- A tick that ended at `feet`, `seconds` long, with walk held or not and
-- on the ground or not: adds what it moved at a walk to the walk. Whether
-- the step's metres are walked.
function TrainingRules.walk(s: State, feet: vector, seconds: number, walking: boolean, grounded: boolean): boolean
	local from = s.from
	s.from = feet
	if from and walking and grounded and seconds > 0 then
		local moved = across(feet, from)
		if moved / seconds >= P.walkSpeed.value then
			s.walked += math.min(moved, P.tickMetres.value)
		end
	end
	local step = TrainingRules.current(s)
	return step.goal == "walk" and s.walked >= (step.metres or 0)
end

-- A target downed at `at`, as `how` says: whether it's the step's, leaving
-- a note if it's the target but not the way the step asks.
function TrainingRules.kill(s: State, at: vector, how: Kill): boolean
	local step = TrainingRules.current(s)
	local spot = step.at
	if step.goal ~= "kill" or not spot or across(at, spot) > (step.radius or 1) then
		return false
	end
	local N = TrainingConfig.Notes
	if step.still and not how.still then
		s.note = N.moving
	elseif step.head and not how.head then
		s.note = N.body
	elseif step.scoped and not how.scoped then
		s.note = N.hip
	else
		return true
	end
	return false
end

-- A tick that ended with `weapon` in hand and `ammo` rounds in its
-- magazine: whether it's reloaded, its magazine fuller than last tick's
-- for the same gun.
function TrainingRules.reload(s: State, weapon: string, ammo: number): boolean
	local was, before = s.weapon, s.ammo
	s.weapon, s.ammo = weapon, ammo
	return weapon ~= "" and was == weapon and before ~= nil and ammo > before
end

-- An ability in the kit's `slot` cast, as `kind`: whether every slot the
-- step asks for has been used.
function TrainingRules.cast(s: State, slot: number, kind: string): boolean
	local step = TrainingRules.current(s)
	local slots = step.slots
	if step.goal ~= "cast" or not slots or TrainingConfig.Readying[kind] then
		return false
	end
	if table.find(slots, slot) then
		s.cast[slot] = true
	end
	for _, wanted in slots do
		if not s.cast[wanted] then
			return false
		end
	end
	return true
end

-- The spike planted or defused by the player, or gone off: whether that
-- finishes the step. Gone off while it's to be defused, it's back to
-- planting, with a note.
function TrainingRules.spike(s: State, event: "planted" | "defused" | "detonated"): boolean
	local goal = TrainingRules.current(s).goal
	if event == "detonated" then
		if goal == "defuse" then
			local plant = TrainingRules.indexOf("plant") :: number
			TrainingRules.go(s, plant)
			s.note = TrainingConfig.Notes.wentOff
		end
		return false
	end
	return (event == "planted" and goal == "plant") or (event == "defused" and goal == "defuse")
end

-- How far through the step under way: the metres walked, or the slots
-- used, as the HUD shows it; "" for nothing to count.
function TrainingRules.progress(s: State): string
	local step = TrainingRules.current(s)
	if step.goal == "walk" then
		local metres = step.metres or 0
		return string.format("%d / %d m", math.min(math.floor(s.walked), metres), metres)
	elseif step.goal == "cast" and step.slots and #step.slots > 1 then
		local used = 0
		for _, slot in step.slots do
			if s.cast[slot] then
				used += 1
			end
		end
		return string.format("%d / %d", used, #step.slots)
	end
	return ""
end

-- `template` with each {name} the button it names, as the input in use
-- has it: "keys", "pad" or "touch". A name it doesn't know stays as it
-- is.
function TrainingRules.text(template: string, input: Input): string
	local column = if input == "pad" then 2 elseif input == "touch" then 3 else 1
	local text = string.gsub(template, "{(%a+)}", function(name: string): string
		local names = TrainingConfig.Keys[name]
		return if names then names[column] else "{" .. name .. "}"
	end)
	return text
end

return TrainingRules
