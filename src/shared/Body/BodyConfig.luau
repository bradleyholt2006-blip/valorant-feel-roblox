--!strict
-- Tuning for the agents' bodies (system 63): how big the body is drawn,
-- how it stands, steps, crouches and leans, and where its hands hold each
-- kind of weapon. Metres, seconds and radians, in the body's own space:
-- feet at the origin, +Y up, facing -Z, its right along +X.
--
-- Each number carries a status, as MovementConfig's do:
--   "confirmed" - stated by the developer (patch notes / dev blog) or shown in-game
--   "community" - published by a wiki or community measurement, not by the developer
--   "estimate"  - our own guess; must be measured and tuned (see docs/research)
--
-- Nothing here changes what can be hit: the hitboxes stay the analytic
-- boxes (Hitboxes), and the body is posed so its head stays in the head box.

export type Status = "confirmed" | "community" | "estimate"

export type Param = {
	value: number,
	status: Status,
	source: string,
}

export type Point = {
	value: vector,
	status: Status,
	source: string,
}

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local function at(x: number, y: number, z: number, status: Status, source: string): Point
	return { value = vector.create(x, y, z), status = status, source = source }
end

local BodyConfig = {}

-- The body ------------------------------------------------------------------------------------

BodyConfig.Body = {
	-- How tall the body is drawn, its soles to the top of its head: the top
	-- of the standing head box (Hitboxes: 1.62 + 0.13).
	height = p(1.75, "estimate", "The standing head box's top, so the head fills it as the reference's hitbox follows its head"),
	-- Where the middle of the head is, in front of its joint with the neck.
	headForward = p(0.012, "estimate", "Measured off the kit's head: the skull's middle is a little ahead of the joint"),
	-- How far the head may move from the head box's middle with the step
	-- (up and down, side to side).
	bob = p(0.012, "estimate", "Small enough that the head never leaves its box (the tests check it)"),
	sway = p(0.008, "estimate", "As bob"),
	-- How far the head, and with it the hips, dips landing a long fall (a
	-- jump's landing dips less), bending the knees.
	landDip = p(0.06, "estimate", "The head's middle stays inside its box, which reaches 0.13 m below it"),
}

-- Standing and stepping -------------------------------------------------------------------------

BodyConfig.Gait = {
	-- Steps a second, two to a cycle: cadence = base + perSpeed x speed, up
	-- to max, quicker crouched.
	cadenceBase = p(1.0, "estimate", "Cycles a second at a standstill's edge; tune against how the reference's run looks"),
	cadencePerSpeed = p(0.2, "estimate", "So a rifle's 5.4 m/s run is about 2.1 cycles a second, a quick combat jog"),
	cadenceMax = p(2.3, "estimate", "About 4.6 steps a second at the knife's 6.75 m/s"),
	crouchCadence = p(1.4, "estimate", "Crouched steps are shorter and quicker"),
	sideCadence = p(1.35, "estimate", "Stepping sideways the steps are shorter and quicker, so the feet don't cross"),
	-- The share of a cycle each foot is down: stance = base + perSpeed x
	-- speed, clamped; under 0.5 both feet leave the ground between steps.
	stanceBase = p(0.62, "estimate", "Walking keeps a foot down (over half a cycle each)"),
	stancePerSpeed = p(-0.065, "estimate", "Running has a moment with both feet up"),
	stanceMin = p(0.26, "estimate", "A fast run's foot is down about a quarter of a cycle"),
	stanceMax = p(0.6, "estimate", "A slow walk"),
	-- How far a foot sweeps under the body while it's down; a step longer
	-- than this slides the foot a little rather than stretch the leg past
	-- what keeps the head in its box.
	sweepMax = p(0.65, "estimate", "The longest sweep the legs reach with the head held in its box (the tests check it)"),
	sweepSide = p(0.42, "estimate", "Stepping sideways, so the feet don't cross much"),
	crouchSweep = p(0.75, "estimate", "Crouched sweeps are shorter"),
	lookShort = p(
		0.35,
		"estimate",
		"Looking up or down a radian, strides are this much shorter: the head drops as it tips, and the hips can't rise further"
	),
	cadenceLimit = p(2.8, "estimate", "Strides a second shortened strides quicken to, at most; past it a foot slides"),
	sweepFront = p(0.35, "estimate", "Of the sweep, the share ahead of the hip: feet land under the body and push off behind"),
	sweepBack = p(0.6, "estimate", "Stepping backward, the share behind the hip, where the foot lands toes first"),
	-- How high a swinging foot lifts: base + perSpeed x speed, up to max.
	liftBase = p(0.05, "estimate", "A walk's foot clears the ground"),
	liftPerSpeed = p(0.025, "estimate", "Higher running"),
	liftMax = p(0.2, "estimate", "A sprint's heel comes up high"),
	crouchLift = p(0.6, "estimate", "Crouched steps stay low"),
	-- The heel comes up as a foot goes behind the body (it rolls onto the
	-- ball), and the toes bend to stay on the ground.
	heelLift = p(0.65, "estimate", "About 37 degrees at the back of a run's stride"),
	heelReach = p(0.3, "estimate", "How far behind the hip the heel is fully up"),
	-- A foot the leg can't reach rises onto its ball, up to this far,
	-- before the hips come down (which would take the head out of its box).
	tiptoe = p(0.5, "estimate", "Radians; landing a long stride on the forefoot, or up on the toes looking down"),
	-- Half the distance between the feet, standing, crouched and the extra
	-- stepping sideways.
	width = p(0.12, "estimate", "About hip width, as the kit's hips are"),
	crouchWidth = p(0.17, "estimate", "Knees and feet out, crouched"),
	sideWidth = p(0.05, "estimate", "Wider stepping sideways"),
	-- How the feet stand with a long gun: the left ahead and the right
	-- behind, turned out (a bladed stance), more so crouched.
	stagger = p(0.07, "estimate", "Left foot ahead, right behind, standing"),
	crouchStagger = p(0.14, "estimate", "Crouched, one foot well ahead of the other"),
	turnOut = p(0.18, "estimate", "Each foot turned out a little"),
	bladeTurn = p(0.22, "estimate", "The back foot turned out more with a long gun (half that crouched)"),
	-- The feet stand under the hips this much (the hips go back as the body
	-- leans, the head staying over the middle).
	underHips = p(0.5, "estimate", "Halfway between under the head and under the hips, so the weight looks carried"),
	underHipsMoving = p(1, "estimate", "Stepping, the stride is under the hips, so the legs reach both ends of it"),
	-- The hips turn toward the way the body moves (up to this much) while
	-- the chest keeps facing where it aims.
	hipTurn = p(0.45, "estimate", "Share of the angle between facing and moving"),
	hipTurnMax = p(0.5, "estimate", "About 29 degrees"),
	-- The hips swing with the stride, and roll.
	hipSwing = p(0.09, "estimate", "Radians each way, at a run"),
	hipRoll = p(0.05, "estimate", "Radians each way, at a run"),
	-- How quickly the body's speed and the step's weight follow the motion.
	smoothing = p(0.08, "estimate", "Seconds; snapshots arrive about every 17 ms"),
	settle = p(0.12, "estimate", "Seconds for the legs to come to a stop or get going"),
	-- Turning on the spot, a foot that's down stays where it stands until
	-- the body's turned this far from it, then steps round after it: the
	-- foot on the side it turns toward first, the other following once it's
	-- this far out. Past the most, a foot turns where it stands.
	turnStepAt = p(0.6, "estimate", "About 34 degrees: a small turn of the aim leaves the feet be"),
	turnFollow = p(0.2, "estimate", "Radians: the second foot squares up to the first"),
	turnMost = p(1.2, "estimate", "About 69 degrees: a flick turns the feet with it, and they step after"),
	turnStepTime = p(0.25, "estimate", "Seconds a step round takes"),
	turnLift = p(0.06, "estimate", "Metres a foot comes up stepping round"),
	-- Standing, the hips turn this share of the way from the aim toward the
	-- feet, the back twisting the rest.
	hipFollow = p(0.5, "estimate", "Halfway, so neither the hips nor the back twist far"),
	-- In the air the legs tuck, one higher than the other.
	tuck = p(0.22, "estimate", "How far the feet come up in a jump"),
	-- Landing from a fall bends the knees a moment: after this long in the
	-- air, more the longer it was, all of it after the longest.
	landTime = p(0.3, "estimate", "Seconds to come back up"),
	landFrom = p(0.15, "estimate", "Seconds in the air: a hop off a step doesn't"),
	landLongest = p(0.6, "estimate", "Seconds in the air: about a 1.5 m drop"),
}

-- Leaning, crouching and aiming ------------------------------------------------------------------

BodyConfig.Spine = {
	-- Crouched, the body leans forward this far (the pelvis takes `pelvisShare`
	-- of it), and the hips go down and back to keep the head in its box.
	crouchLean = p(0.5, "estimate", "About 29 degrees; the reference's crouch is deep, its head box at 1.10 m"),
	pelvisShare = p(0.55, "estimate", "Most of the lean is at the hips"),
	-- Leaning into running (radians per m/s) and away from the side it moves to.
	runLean = p(0.025, "estimate", "About 8 degrees at a rifle's 5.4 m/s"),
	runLeanMax = p(0.22, "estimate", "About 13 degrees"),
	sideLean = p(0.025, "estimate", "Radians per m/s of sideways speed"),
	-- Of the aim's pitch, the share the chest takes (the head the rest, so
	-- the eyes look along the aim).
	aimChest = p(0.3, "estimate", "Looking up bends the upper back as well as the neck"),
	aimChestDown = p(0.1, "estimate", "Looking down the neck does most of it: bending the back would drop the head out of its box"),
	aimNeck = p(0.4, "estimate", "Of what's left after the chest, the share the neck takes"),
	-- A long gun's chest turns left foot forward (a bladed stance), the head
	-- turning back to look along the aim.
	blade = p(-0.5, "estimate", "About 29 degrees, so the left hand reaches the foregrip"),
	pistolBlade = p(-0.12, "estimate", "Square to the aim, nearly"),
	-- The head tips toward the stock of a long gun.
	cheek = p(-0.1, "estimate", "Radians of roll toward the right shoulder"),
	-- Breathing: how far the chest rises, and how often.
	breathe = p(0.015, "estimate", "Radians"),
	breatheRate = p(0.25, "estimate", "Breaths a second"),
}

-- Holding ------------------------------------------------------------------------------------------

-- Where the held thing's grip is, from the top of the chest (the kit's
-- spine05), in the aim's frame (pitched with the aim by `follow`), and
-- where the elbows point. The left hand holds a long gun at its foregrip
-- (BodyView finds it from the gun's look).
BodyConfig.Hold = {
	rifle = at(0.06, -0.16, -0.28, "estimate", "Stock at the right shoulder, the gun at chest height"),
	pistol = at(0.03, -0.15, -0.43, "estimate", "Both arms nearly straight out, the gun under the eyes"),
	knife = at(0.17, -0.42, -0.27, "estimate", "Blade low and forward in the right hand"),
	spike = at(0, -0.4, -0.3, "estimate", "The spike held out in front in both hands"),
	item = at(0.15, -0.18, -0.33, "estimate", "An ability's item held up and forward in the right hand"),
	-- How much the grip follows the aim up and down (the gun points along
	-- the aim whatever this is).
	follow = p(0.55, "estimate", "Aiming up or down raises or lowers the hands as well as the barrel"),
	-- Where a long gun's foregrip is when its look doesn't say, gun space.
	foregrip = at(0, -0.05, -0.22, "estimate", "Under the receiver, ahead of the magazine"),
	-- Where the wrist is from the middle of the grip, along the hand and out
	-- of the palm (fractions of the wrist to knuckles length, and metres).
	gripAlong = p(0.72, "estimate", "The handle sits across the palm, short of the knuckles"),
	gripPalm = p(0.03, "estimate", "The handle's middle is in front of the palm"),
	-- The elbows: which way they point holding a long gun, and relaxed.
	rightElbow = at(0.45, -1, 0.1, "estimate", "Right elbow down and a little out"),
	leftElbow = at(-0.25, -1, 0, "estimate", "Left elbow down under the gun"),
	relaxedElbow = at(0.2, 0, 1, "estimate", "Arms hanging, elbows back and a little out (x is outward, either side)"),
	-- Hanging arms swing with the stride, metres each way at a run.
	armSwing = p(0.16, "estimate", "Opposite the leg on the same side"),
	-- Fingers closed round a grip (radians at each knuckle) and the trigger
	-- finger's lighter curl.
	curl = p(0.85, "estimate", "About 50 degrees at each knuckle"),
	triggerCurl = p(0.35, "estimate", "Resting on the trigger"),
	relaxedCurl = p(0.25, "estimate", "Hanging hands"),
	-- Drawing: the gun comes up from low over this long.
	drawTime = p(0.35, "estimate", "About as long as the quickest equip"),
	switchTime = p(0.2, "estimate", "The hands going from the old hold to the new"),
	-- Reloading: the gun tips, the left hand goes to the magazine, takes it
	-- out, puts the next in and goes back, once over the gun's reload.
	reloadTilt = p(0.45, "estimate", "Radians the gun rolls"),
	reloadDip = p(0.35, "estimate", "Radians the gun points down"),
	reloadCycle = p(1.6, "estimate", "Seconds for the left hand's trip when the gun's reload time isn't known"),
	-- Firing: the muzzle kicks up and the gun back into the shoulder with
	-- each shot, and settles.
	kick = p(0.1, "estimate", "Radians the muzzle rises"),
	kickBack = p(0.025, "estimate", "Metres the gun comes back"),
	kickTime = p(0.07, "estimate", "Seconds for the kick to settle to a third"),
	-- Planting or defusing, both hands press down in front: standing, at
	-- the waist; crouched, on the spike on the ground (x is outward, either
	-- side).
	press = at(0.09, 0.95, -0.3, "estimate", "Waist height, the head kept in the standing head box"),
	pressCrouched = at(
		0.05,
		0.42,
		-0.26,
		"estimate",
		"On the spike's raised cap (its top about 0.475 m up, radius 0.07 m, SpikeView; the casing's near edge about 0.23 m ahead of the feet), as far forward and down as the arms reach with the head in the crouched head box; at -0.22 the palms stopped 2 to 3 cm short of it, and at 0.09 either side and 0.41 up the knuckles were 0.11 to 0.13 m from the spike's middle, level with the cap's top but beside it (measured in Studio); 0.05 either side, and a centimetre up so the arms still reach, puts them on its rim"
	),
}

return BodyConfig
