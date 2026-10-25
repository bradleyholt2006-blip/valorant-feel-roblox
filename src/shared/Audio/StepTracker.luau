--!strict
-- Turns a player's poses over time into the sounds their feet make: a step
-- each stride on the ground, a jump when they leave the ground going up,
-- and a landing when they come down. The same tracker runs on the local
-- player's predicted ticks and on every other player's drawn frames, so all
-- of them follow the same rules (SoundConfig.Footsteps and Landing):
--
--   * a step is loud unless the player is walking or crouching (`quiet`)
--   * a landing is loud when it falls far enough and comes down no higher
--     than where it left the ground, so a jump up onto a crate is silent
--   * a jump is never loud: enemies hear the landing, not the jump
--
-- Samples may come at any rate. A jump in position too big to have been
-- walked (a respawn, a correction) starts the tracker over from there.
--
-- Pure (no Roblox APIs), so the offline tests drive it.

local MovementSim = require("../Movement/MovementSim")
local SoundConfig = require("./SoundConfig")

export type Sample = {
	time: number,
	position: vector, -- feet, metres
	grounded: boolean,
	quiet: boolean, -- walking or crouching: steps make no sound
}

export type Kind = "step" | "jump" | "land"
export type Event = { kind: Kind, time: number, position: vector, loud: boolean }

export type Tracker = {
	last: Sample?,
	travelled: number, -- metres along the ground since the last step
	movedAt: number, -- time it last moved along the ground
	takeoff: number, -- height it left the ground at
	apex: number, -- highest it has been since
}

local Buttons = MovementSim.Buttons
local F, L = SoundConfig.Footsteps, SoundConfig.Landing
local MOVING = 1e-4 -- metres in a sample that count as moving

local StepTracker = {}

function StepTracker.new(): Tracker
	return { last = nil, travelled = 0, movedAt = -math.huge, takeoff = 0, apex = 0 }
end

-- Forgets everything, so the next sample starts it over (a new life).
function StepTracker.reset(t: Tracker)
	t.last = nil
	t.travelled = 0
	t.movedAt = -math.huge
end

-- Walking or crouching: the buttons a tick ran with, and whether the
-- simulation has the player crouched (it stays crouched under a low ceiling).
function StepTracker.isQuiet(buttons: number, crouched: boolean): boolean
	return MovementSim.has(buttons, Buttons.Walk) or MovementSim.has(buttons, Buttons.Crouch) or crouched
end

local function horizontal(v: vector): number
	return math.sqrt(v.x * v.x + v.z * v.z)
end

-- Whether a landing is heard, from how far it fell and how high it came
-- down compared with where it left the ground.
function StepTracker.landingIsLoud(fall: number, rise: number): boolean
	return fall >= L.minFall.value and rise <= L.maxRise.value
end

-- Takes the next sample and returns the events since the last one, in order.
function StepTracker.push(t: Tracker, s: Sample): { Event }
	local events: { Event } = {}
	local last = t.last
	t.last = s
	local y = s.position.y
	if last == nil or vector.magnitude(s.position - last.position) > F.teleport.value then
		t.travelled = F.firstStep.value
		t.movedAt = -math.huge
		t.takeoff, t.apex = y, y
		return events
	end

	if last.grounded and not s.grounded then
		t.takeoff = last.position.y
		t.apex = math.max(last.position.y, y)
		if y > last.position.y then
			table.insert(events, { kind = "jump", time = s.time, position = s.position, loud = false })
		end
	elseif not last.grounded then
		t.apex = math.max(t.apex, y)
	end

	if not last.grounded and s.grounded then
		local loud = StepTracker.landingIsLoud(t.apex - y, y - t.takeoff)
		table.insert(events, { kind = "land", time = s.time, position = s.position, loud = loud })
		-- The landing is a step: the next one is a stride on.
		t.travelled = 0
		t.movedAt = s.time
	elseif last.grounded and s.grounded then
		local moved = horizontal(s.position - last.position)
		if moved > MOVING then
			if s.time - t.movedAt > F.idleTime.value then
				t.travelled = math.max(t.travelled, F.firstStep.value)
			end
			t.movedAt = s.time
			t.travelled += moved
			if t.travelled >= F.stride.value then
				-- One step however long the gap was, and the stride starts over.
				t.travelled = math.min(t.travelled - F.stride.value, F.stride.value)
				table.insert(events, { kind = "step", time = s.time, position = s.position, loud = not s.quiet })
			end
		end
	end
	return events
end

return StepTracker
