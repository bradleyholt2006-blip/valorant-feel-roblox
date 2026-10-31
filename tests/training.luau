--!strict
-- Basic Training (system 72): a tutorial on the course, a step at a time,
-- each finished by what the server sees: a spot reached, metres walked, a
-- target downed the way the step asks, a reload, a shield, abilities used,
-- the spike planted and defused (TrainingRules, on TrainingConfig's list).

local PlayConfig = require("../src/shared/Match/PlayConfig")
local Spike = require("../src/shared/Spike/Spike")
local TrainingConfig = require("../src/shared/Training/TrainingConfig")
local TrainingRules = require("../src/shared/Training/TrainingRules")
local H = require("./Harness")

local check = H.check

local STEPS = TrainingConfig.Steps
local P = TrainingConfig.Params
local DT = 1 / 128

H.section("Basic Training tests")

local function step(key: string): TrainingConfig.Step
	return STEPS[TrainingRules.indexOf(key) :: number]
end

-- A state at the step with this key.
local function at(key: string): TrainingRules.State
	local s = TrainingRules.new()
	TrainingRules.go(s, TrainingRules.indexOf(key) :: number)
	return s
end

-- The steps ------------------------------------------------------------------

do
	local keys: { [string]: boolean } = {}
	local unique = true
	for _, s in STEPS do
		unique = unique and not keys[s.key]
		keys[s.key] = true
	end
	check("15 steps, each by a key of its own", #STEPS == 15 and unique)
	check("from moving to defusing the spike, then done", STEPS[1].key == "move" and STEPS[#STEPS].goal == "done")
	local order = {}
	for _, s in STEPS do
		table.insert(order, s.key)
	end
	check(
		"in the reference's tutorial's order: moving, shooting, the rifle, buying, abilities, the spike",
		table.concat(order, ",") == "move,crouch,jump,walk,shoot,still,head,reload,rifle,shield,abilities,ultimate,plant,defuse,done",
		table.concat(order, ",")
	)

	local whole = true
	for _, s in STEPS do
		local g = s.goal
		if g == "reach" or g == "kill" then
			whole = whole and s.at ~= nil and s.radius ~= nil and s.radius > 0
		elseif g == "walk" then
			whole = whole and s.metres ~= nil and s.metres > 0
		elseif g == "cast" then
			whole = whole and s.slots ~= nil and #s.slots > 0
		end
		whole = whole and s.title ~= "" and s.text ~= ""
	end
	check("each step has what its goal needs: a spot, metres or slots", whole)
	check("the walk says its metres", string.find(step("walk").text, string.format("%d m", step("walk").metres :: number), 1, true) ~= nil)
	check("the spike's fetched where the course has it", step("plant").at == Spike.CourseStart)

	-- Every {name} in a step or a note is a button with its three names.
	local known = true
	local function names(text: string)
		for name in string.gmatch(text, "{(%a+)}") do
			local three = TrainingConfig.Keys[name]
			known = known and three ~= nil and #three == 3
		end
	end
	for _, s in STEPS do
		names(s.text)
	end
	for _, note in TrainingConfig.Notes do
		names(note)
	end
	check("every button a step or a note names, as the keys, a gamepad and a touch screen have it", known)
end

-- On the course: the targets the shooting steps ask for are TestRange's
-- dummies, each the only one in its step's reach.
do
	local DUMMIES = {
		vector.create(0, 0, -10),
		vector.create(3, 0, -15), -- strafes
		vector.create(-2, 0, -20), -- crouches
		vector.create(0, 0, -30),
		vector.create(3, 0, -30), -- strafes
		vector.create(0, 0, -50),
		vector.create(8, 0, -22), -- behind the cover
		vector.create(0, 0, 30), -- between the sites
	}
	for x = -32, -16, 2 do
		table.insert(DUMMIES, vector.create(x, 0, -21.5)) -- the wallbang lane
	end
	local function within(spot: vector, radius: number, d: vector): boolean
		return math.sqrt((d.x - spot.x) ^ 2 + (d.z - spot.z) ^ 2) <= radius
	end
	local function reaching(s: TrainingConfig.Step): number
		local n = 0
		for _, d in DUMMIES do
			-- A strafing dummy wanders up to 3 m to one side of its spot (0.9 m
			-- to 2.9 m in BRINK), so each counts as that much further out.
			if within(s.at :: vector, (s.radius :: number) + 3, d) then
				n += 1
			end
		end
		return n
	end
	check(
		"each shooting step's target is a dummy on the course, and only it",
		reaching(step("shoot")) == 1 and reaching(step("still")) == 1 and reaching(step("head")) == 1
	)
	check("and the rifle's either of the two at 30 m", reaching(step("rifle")) == 2)
	local rifle = step("rifle")
	check(
		"the rifle's holding the strafing one wherever it's got to, 0.9 m to 2.9 m to its side",
		within(rifle.at :: vector, rifle.radius :: number, vector.create(3.91, 0, -30))
			and within(rifle.at :: vector, rifle.radius :: number, vector.create(5.91, 0, -30))
			and within(rifle.at :: vector, rifle.radius :: number, vector.create(0, 0, -30))
	)
	check(
		"the crouching one to shoot standing still, the one behind the cover in the head, the rifle's aiming down sights",
		step("still").still == true and step("head").head == true and step("rifle").scoped == true
	)
end

-- Where you are -----------------------------------------------------------------

do
	local s = TrainingRules.new()
	check("a new player starts at the first step", TrainingRules.current(s).key == "move" and s.index == 1)
	check("steps by their keys", TrainingRules.indexOf("plant") == 13 and TrainingRules.indexOf("nonsense") == nil)
	s.walked = 3
	s.note = "x"
	s.cast[1] = true
	check("onto the next, afresh", TrainingRules.advance(s) and s.index == 2 and s.walked == 0 and s.note == nil and not s.cast[1])
	TrainingRules.go(s, #STEPS)
	check("the last never ends", not TrainingRules.advance(s) and s.index == #STEPS)
	TrainingRules.go(s, 99)
	check("and a step past the last is the last", s.index == #STEPS)
end

-- Reaching a spot ------------------------------------------------------------------

do
	local move = step("move")
	local spot = move.at :: vector
	check("on the spot, on the ground: there", TrainingRules.reached(move, spot, true, false))
	check(
		"within its reach across the floor, and not past it",
		TrainingRules.reached(move, spot + vector.create(1, 0, 0.5), true, false)
			and not TrainingRules.reached(move, spot + vector.create(1.3, 0, 0), true, false)
	)
	check("in the air over it: not yet", not TrainingRules.reached(move, spot, false, false))

	local crouch = step("crouch")
	local tunnel = crouch.at :: vector
	check(
		"in the tunnel, only crouched",
		TrainingRules.reached(crouch, tunnel, true, true) and not TrainingRules.reached(crouch, tunnel, true, false)
	)

	local jump = step("jump")
	local box = jump.at :: vector
	check(
		"on the box, and not beside it on the floor",
		TrainingRules.reached(jump, box, true, false) and not TrainingRules.reached(jump, vector.create(box.x, 0, box.z), true, false)
	)
end

-- Walking ------------------------------------------------------------------------

do
	local s = at("walk")
	local feet = vector.create(0, 0, 0)
	local walkSpeed = 2.9 -- a walk's metres a second
	local done = false
	local ticks = 0
	while not done and ticks < 1000 do
		feet += vector.create(walkSpeed * DT, 0, 0)
		done = TrainingRules.walk(s, feet, DT, true, true)
		ticks += 1
	end
	check("6 m at a walk finishes the walk", done and math.abs(ticks * walkSpeed * DT - 6) < 0.05, ticks)

	local run = at("walk")
	for _ = 1, 400 do
		feet += vector.create(5.4 * DT, 0, 0)
		TrainingRules.walk(run, feet, DT, false, true)
	end
	check("running doesn't count", run.walked == 0)
	local air = at("walk")
	for _ = 1, 100 do
		feet += vector.create(2.9 * DT, 0, 0)
		TrainingRules.walk(air, feet, DT, true, false)
	end
	check("nor does the air", air.walked == 0)
	local still = at("walk")
	for i = 1, 200 do
		TrainingRules.walk(still, vector.create(0.001 * (i % 2), 0, 0), DT, true, true)
	end
	check("nor standing about with walk held", still.walked == 0)
	local jumpTo = at("walk")
	TrainingRules.walk(jumpTo, vector.create(0, 0, 0), DT, true, true)
	TrainingRules.walk(jumpTo, vector.create(30, 0, 0), DT, true, true)
	check("a respawn far away counts for no more than a tick's step", jumpTo.walked <= P.tickMetres.value)
	check("and the HUD counts the metres", TrainingRules.progress(s) == "6 / 6 m" and TrainingRules.progress(run) == "0 / 6 m")
end

-- Downing targets -------------------------------------------------------------------

do
	local fine: TrainingRules.Kill = { still = true, head = true, scoped = true }
	local s = at("shoot")
	check("the target by the marker downed: done", TrainingRules.kill(s, step("shoot").at :: vector, fine))
	local other = at("shoot")
	check("another target: nothing, and no note", not TrainingRules.kill(other, vector.create(0, 0, -50), fine) and other.note == nil)
	local walking = at("still")
	local spot = step("still").at :: vector
	check(
		"moving as the shot went off: not yet, with a note why",
		not TrainingRules.kill(walking, spot, { still = false, head = true, scoped = true }) and walking.note == TrainingConfig.Notes.moving
	)
	local before = walking.notes
	TrainingRules.kill(walking, spot, { still = false, head = true, scoped = true })
	check("the same note again counts again, to show it again", walking.notes == before + 1 and walking.note == TrainingConfig.Notes.moving)
	check("another target gives no note to count", other.notes == 0)
	check("standing still: done", TrainingRules.kill(walking, spot, { still = true, head = false, scoped = false }))
	local body = at("head")
	local cover = step("head").at :: vector
	check(
		"not the head: not yet, with a note",
		not TrainingRules.kill(body, cover, { still = true, head = false, scoped = false }) and body.note == TrainingConfig.Notes.body
	)
	local hip = at("rifle")
	local far = vector.create(3, 0, -30)
	check(
		"from the hip: not yet, with a note naming the button",
		not TrainingRules.kill(hip, far, { still = true, head = true, scoped = false })
			and hip.note == TrainingConfig.Notes.hip
			and string.find(TrainingRules.text(hip.note :: string, "pad"), "LT + RS", 1, true) ~= nil
	)
	check("aiming down sights: done", TrainingRules.kill(hip, far, { still = false, head = false, scoped = true }))
	check("a kill in a step that isn't for one: nothing", not TrainingRules.kill(at("move"), vector.create(0, 0, -10), fine))
end

-- Reloading --------------------------------------------------------------------------

do
	local s = at("reload")
	check("the first look at the gun: nothing yet", not TrainingRules.reload(s, "classic", 12))
	check("fewer rounds: not yet", not TrainingRules.reload(s, "classic", 9))
	check("the magazine full again: reloaded", TrainingRules.reload(s, "classic", 12))
	local swap = at("reload")
	TrainingRules.reload(swap, "classic", 3)
	check("another gun with more rounds isn't a reload", not TrainingRules.reload(swap, "vandal", 25))
	local bare = at("reload")
	TrainingRules.reload(bare, "", 0)
	check("nor is nothing in hand", not TrainingRules.reload(bare, "", 1))
end

-- Abilities ----------------------------------------------------------------------------

do
	local s = at("abilities")
	check("one put in hand doesn't count", not TrainingRules.cast(s, 2, "equip") and not s.cast[2])
	check("one used counts", not TrainingRules.cast(s, 1, "lift") and s.cast[1] == true)
	check("and the HUD counts them", TrainingRules.progress(s) == "1 / 3")
	check("the same again counts once", not TrainingRules.cast(s, 1, "lift") and TrainingRules.progress(s) == "1 / 3")
	check("the ultimate isn't one of these", not TrainingRules.cast(s, 4, "storm") and not s.cast[4])
	TrainingRules.cast(s, 2, "bolt")
	check("all three: done", TrainingRules.cast(s, 3, "ready"))
	local ult = at("ultimate")
	check(
		"the ultimate used: done, with nothing to count on the way",
		TrainingRules.progress(ult) == "" and TrainingRules.cast(ult, 4, "storm")
	)
end

-- The spike ----------------------------------------------------------------------------

do
	local s = at("plant")
	check("defused while planting's asked: nothing", not TrainingRules.spike(s, "defused"))
	check("planted: done", TrainingRules.spike(s, "planted"))
	local d = at("defuse")
	check("defused: done", TrainingRules.spike(d, "defused"))
	local boom = at("defuse")
	check(
		"gone off first: back to planting, with a note",
		not TrainingRules.spike(boom, "detonated")
			and TrainingRules.current(boom).key == "plant"
			and boom.note == TrainingConfig.Notes.wentOff
	)
	local elsewhere = at("abilities")
	check("gone off in another step: nothing", not TrainingRules.spike(elsewhere, "detonated") and elsewhere.index == 11)
end

-- The words ----------------------------------------------------------------------------

do
	local text = step("crouch").text
	check(
		"the buttons named as the input in use has them",
		TrainingRules.text(text, "keys") == "Crouch (hold CTRL) and get into the low tunnel by the marker."
			and TrainingRules.text(text, "pad") == "Crouch (click L3) and get into the low tunnel by the marker."
			and TrainingRules.text(text, "touch") == "Crouch (tap CROUCH) and get into the low tunnel by the marker."
	)
	check("a name it doesn't know stays as it is", TrainingRules.text("Press {nonsense}", "keys") == "Press {nonsense}")
	local mode = PlayConfig.ByKey[TrainingConfig.KEY]
	check(
		"on the Play menu, played alone on the course, its blurb counting the steps to do",
		mode ~= nil and mode.players == 1 and mode.arena == nil and string.find(mode.blurb, tostring(#STEPS - 1), 1, true) ~= nil
	)
	local names = { TrainingConfig.ON, TrainingConfig.STEP, TrainingConfig.PROGRESS, TrainingConfig.NOTE }
	local apart = true
	for i, name in names do
		for j = i + 1, #names do
			apart = apart and name ~= names[j]
		end
	end
	check("Workspace's attribute and the players' each by a name of its own", apart)
end

return nil
