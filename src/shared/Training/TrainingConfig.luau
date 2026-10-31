--!strict
-- Basic Training's steps and numbers (system 72, TrainingRules): a
-- tutorial on the course, a step at a time, on a server of its own. The
-- reference's first tutorial taught, in order, moving, jumping and
-- crouching, a pistol and standing still to shoot, a rifle and aiming down
-- sights, walking silently, the buy menu, abilities, and planting the
-- spike and defending (dbltap.com's walkthrough); its Basic Training since
-- has gun use first, then the attackers' basics (buying, abilities,
-- planting) and the defenders' (Codashop's guide). These steps keep that
-- order on the course's own lanes (TestRange), so where each is, how far
-- and what it says are ours. Same status convention as MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be tuned (docs/research/72-basic-training.md)
--
-- Places are the course's, in metres: the spawn at the origin, facing
-- down -Z, the target lane ahead of it.
--
-- Its only require is the spike's, for the course's start.

local Spike = require("../Spike/Spike")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

-- What finishes a step: a spot reached, metres walked, a target downed, a
-- reload, a shield worn, abilities used, the spike planted or defused; or
-- nothing, for the last.
export type Goal = "reach" | "walk" | "kill" | "reload" | "shield" | "cast" | "plant" | "defuse" | "done"

-- A step: its key, its title and what it says, with {name}s for the
-- buttons (TrainingConfig.Keys), and what finishes it.
export type Step = {
	key: string,
	title: string,
	text: string,
	goal: Goal,
	-- Where: the spot to reach (feet), the target to down, or what to fetch;
	-- the marker's place.
	at: vector?,
	-- Metres across the floor from `at` that count.
	radius: number?,
	-- To reach `at`: feet this high at the least, and crouched.
	above: number?,
	crouched: boolean?,
	-- To walk: this many metres.
	metres: number?,
	-- The shot that downs the target: fired standing still, to the head,
	-- aiming down sights.
	still: boolean?,
	head: boolean?,
	scoped: boolean?,
	-- The kit's slots to use, once each (AbilityConfig: 1 C, 2 Q, 3 E, 4 X).
	slots: { number }?,
	-- A weapon put in its slot as the step starts, and again in each life
	-- during it.
	give: string?,
}

local TrainingConfig = {}

-- The Play menu's key for it (PlayConfig).
TrainingConfig.KEY = "training"

-- Workspace's attribute for whether it's played: true has the course play
-- it while the arena's off (ArenaConfig.ON), which is how the Play menu's
-- server for it has it (ModeServers), and scripted checks too.
TrainingConfig.ON = "VFTrainingOn"

-- Player attributes, from the server: the step under way's key, how far
-- through it they are ("2 / 3", "" for nothing to count), and a note on why
-- something didn't count, as a template with {name}s ("" for none).
TrainingConfig.STEP = "VFTrainingStep"
TrainingConfig.PROGRESS = "VFTrainingProgress"
TrainingConfig.NOTE = "VFTrainingNote"

TrainingConfig.Params = {
	walkSpeed = p(0.5, "estimate", "Metres a second at the least that count as walking, not standing (ours)"),
	tickMetres = p(0.1, "estimate", "Metres at most one tick's move counts for, so a respawn isn't a walk (ours)"),
	noteFor = p(5, "estimate", "Seconds a note shows (ours)"),
}

-- The casts that only ready an ability, which don't count as using it: one
-- put in hand, drawn again, and Run it Back's end.
TrainingConfig.Readying = table.freeze({ equip = true, draw = true, fizzle = true } :: { [string]: boolean })

-- Why a target downed didn't count, and what happened to the spike, as
-- notes.
TrainingConfig.Notes = table.freeze({
	moving = "You were moving as that shot went off: stop, then fire.",
	body = "That wasn't the head: aim a little higher.",
	hip = "Aim down sights first ({aim}).",
	wentOff = "It went off: plant it again.",
})

-- The buttons by name, as the keys, a gamepad (system 68) and a touch
-- screen (system 71) have them.
TrainingConfig.Keys = table.freeze({
	move = { "W A S D", "LEFT STICK", "THE STICK ON THE LEFT" },
	crouch = { "hold CTRL", "click L3", "tap CROUCH" },
	jump = { "SPACE", "A", "JUMP" },
	walk = { "hold SHIFT as you move", "tilt LEFT STICK only partway", "push the stick only lightly" },
	fire = { "LEFT CLICK", "RT", "FIRE" },
	aim = { "RIGHT CLICK", "LT + RS", "AIM" },
	reload = { "R", "X", "RELOAD" },
	buy = { "B", "D-PAD RIGHT", "BUY" },
	c = { "C", "B", "C" },
	q = { "Q", "LB", "Q" },
	e = { "E", "RB", "E" },
	x = { "X", "LB + RB", "X" },
	spike = { "4", "D-PAD DOWN", "SPIKE" },
	defuse = { "4", "D-PAD DOWN", "USE" },
	play = { "M", "SELECT + D-PAD UP", "PLAY" },
} :: { [string]: { string } })

-- The steps, in order.
TrainingConfig.Steps = table.freeze({
	{
		key = "move",
		title = "MOVE",
		text = "Move with {move} to the marker at the end of the lane.",
		goal = "reach",
		at = vector.create(20, 0, -6), -- the sprint lane's 20 m post
		radius = 1.2,
	},
	{
		key = "crouch",
		title = "CROUCH",
		text = "Crouch ({crouch}) and get into the low tunnel by the marker.",
		goal = "reach",
		at = vector.create(8, 0, 8), -- the middle of the 1.5 m tunnel
		radius = 1,
		crouched = true,
	},
	{
		key = "jump",
		title = "JUMP",
		text = "Jump ({jump}) onto the box by the marker.",
		goal = "reach",
		at = vector.create(-6, 0.5, -10), -- the 0.50 m jump box
		radius = 0.9,
		above = 0.4,
	},
	{
		key = "walk",
		title = "WALK",
		text = "Walk ({walk}) for 6 m. It's slower than running, and your steps make no sound.",
		goal = "walk",
		metres = 6,
	},
	{
		key = "shoot",
		title = "SHOOT",
		text = "Shoot ({fire}) the target by the marker, 10 m down the range, until it falls.",
		goal = "kill",
		at = vector.create(0, 0, -10),
		radius = 2,
	},
	{
		key = "still",
		title = "STAND STILL",
		text = "Moving throws your shots wide, so stop before you fire. Down the crouching target, standing still as you shoot.",
		goal = "kill",
		at = vector.create(-2, 0, -20),
		radius = 2,
		still = true,
	},
	{
		key = "head",
		title = "HEADSHOT",
		text = "A shot to the head does the most damage. Only the head of the target behind the cover shows: down it with a headshot.",
		goal = "kill",
		at = vector.create(8, 0, -22),
		radius = 2,
		head = true,
	},
	{
		key = "reload",
		title = "RELOAD",
		text = "Reload ({reload}) before your magazine runs dry. If it's full, fire a few rounds first.",
		goal = "reload",
	},
	{
		key = "rifle",
		title = "AIM DOWN SIGHTS",
		text = "Here's a Vandal. Aim down its sights ({aim}) for a closer look and a steadier shot, and down a target 30 m away.",
		goal = "kill",
		at = vector.create(1.5, 0, -30), -- between the two targets at 30 m
		radius = 3,
		scoped = true,
		give = "vandal",
	},
	{
		key = "shield",
		title = "BUY",
		text = "Open the buy menu ({buy}) and buy a shield. It takes damage before your health does.",
		goal = "shield",
	},
	{
		key = "abilities",
		title = "ABILITIES",
		text = "Your agent's abilities are on {c}, {q} and {e}. Use each once: some go in your hand first, and {fire} throws or fires them.",
		goal = "cast",
		slots = { 1, 2, 3 },
	},
	{
		key = "ultimate",
		title = "ULTIMATE",
		text = "Your ultimate ({x}) charges with kills, deaths, orbs and the spike. Here it's charged: use it.",
		goal = "cast",
		slots = { 4 },
	},
	{
		key = "plant",
		title = "PLANT",
		text = "Pick up the spike by the marker behind the spawn, carry it onto site A or B, and hold {spike} there to plant it.",
		goal = "plant",
		at = Spike.CourseStart,
	},
	{
		key = "defuse",
		title = "DEFUSE",
		text = "Now defuse it before it goes off: hold {defuse} by it until the bar fills.",
		goal = "defuse",
	},
	{
		key = "done",
		title = "DONE",
		text = "That's the basics. Open the Play menu ({play}) for a match: Skirmish to warm up, then Unrated.",
		goal = "done",
	},
} :: { Step })

return TrainingConfig
