--!strict
-- Abilities (system 17): the kit every agent carries, and the agents. Same
-- status convention as MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be tuned (docs/research/17-abilities.md)
-- The VALORANT Wiki (wiki.playvalorant.com) is written by players, so what
-- only it says is "community".
--
-- A kit has four slots, each with its key: C, Q and E, and X for the
-- ultimate. C and Q are basic abilities, bought a charge at a time in the
-- buy phase. E is the signature, with a free charge every round. X is the
-- ultimate, cast once its points are full: a point for each kill, death,
-- plant, defuse and ultimate orb. An agent can also have a passive, which
-- takes no slot or key of its own: Jett's Drift (system 20). Team Deathmatch
-- has a kit of its own (system 28): abilities that recharge over time, and
-- ultimates that cost more, from kills and Ultimate Orbs. Phoenix is the
-- second agent (system 30), his Curveball the first of his abilities that
-- can be played.
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

-- What kind of ability a slot holds.
export type Kind = "basic" | "signature" | "ultimate"

-- How an ability comes back within a round, if it does: after a cooldown, or
-- after so many kills.
export type Recharge = { kind: "cooldown", seconds: Param } | { kind: "kills", kills: Param }

export type AbilityDef = {
	id: string,
	name: string,
	slot: number, -- AbilityConfig.C, Q, E or X
	kind: Kind,
	cost: Param?, -- credits a charge, when charges can be bought
	charges: Param?, -- the most it can hold (basic and signature)
	free: number?, -- charges it's given free each round (the signature)
	recharge: Recharge?,
	points: Param?, -- ultimate points it needs (the ultimate)
	weapon: string?, -- what its cast puts in hand, a WeaponConfig id (system 19)
	description: string, -- for the buy menu and the HUD, in our words
}

export type Agent = {
	id: string,
	name: string,
	role: string, -- as Riot's agent pages name it (Jett's "Duelist"), for agent select
	abilities: { string }, -- ids, by slot: C, Q, E, X
	passive: string?, -- what the agent always has, without a key (Jett's "drift")
}

local AbilityConfig = {}

-- The kit's slots, in the order the HUD shows them, and the key for each.
AbilityConfig.C = 1
AbilityConfig.Q = 2
AbilityConfig.E = 3
AbilityConfig.X = 4
AbilityConfig.SLOTS = 4
AbilityConfig.KEYS = { "C", "Q", "E", "X" }

-- The player attribute the server keeps each kit in, as AbilitySim.summary
-- writes it.
AbilityConfig.KIT_ATTRIBUTE = "VFKit"
-- And the one it keeps each kit's recharge in, where abilities recharge
-- over time (system 28): when C, Q and E each next has a charge back, in
-- server time, 0 for none coming ("0,812.5,0").
AbilityConfig.RECHARGE_ATTRIBUTE = "VFRecharge"

local SHACKNEWS = "Shacknews' default key bindings"
AbilityConfig.KeySources = {
	C = SHACKNEWS .. ": 'Use/Equip Ability: 3' on C",
	Q = SHACKNEWS .. ": 'Use/Equip Ability: 1' on Q",
	E = SHACKNEWS .. ": 'Use/Equip Ability: 2' on E",
	X = SHACKNEWS .. ": 'Use/Equip Ability: Ultimate' on X",
}

-- Ultimate points, each worth one (Gfinity: "Every kill you get will get you
-- one Ultimate Point", and so on for each).
local GFINITY = "Gfinity's ultimate points guide"
AbilityConfig.Points = {
	kill = p(1, "community", GFINITY .. ": 'Every kill you get will get you one Ultimate Point'"),
	death = p(1, "community", GFINITY .. ": 'Every death will get you one Ultimate Point'"),
	plant = p(1, "community", GFINITY .. ": 'Planting the spike will get you one Ultimate Point'"),
	defuse = p(1, "community", GFINITY .. ": 'Defusing the spike will get you one Ultimate Point'"),
	orb = p(1, "community", GFINITY .. ": 'Collecting an Ultimate Orb will get you one Ultimate Point'"),
}

-- A mode's own kit (system 28): what a kill, a death and an Ultimate Orb are
-- worth in ultimate points, what each ultimate needs, by its id, and how
-- long each ability takes to bring a spent charge back, by its id; and what
-- each match starts with: the signature's full charges, and every charge
-- short of its most that far towards coming back, a share of its time.
export type ModeKit = {
	kill: Param,
	death: Param,
	orb: Param,
	ultimate: { [string]: Param },
	cooldowns: { [string]: Param },
	signatureStart: Param,
	headStart: Param,
}

local TDM_WIKI = "VALORANT Wiki (Weird Gloop), 'Team Deathmatch'"

-- Team Deathmatch's, as the VALORANT Wiki has it: 'After casting abilities,
-- they will recharge over time, with recharge rates varying depending on
-- the type of ability.' A charge at a time, and charges kept through a
-- death, are ours: the wiki and Riot ('Abilities will recharge over time
-- once depleted') say neither.
AbilityConfig.TeamDeathmatch = {
	kill = p(3, "community", TDM_WIKI .. ": 'points gained from kills (3 points)'"),
	death = p(0, "estimate", "Ours: " .. TDM_WIKI .. " has a mode's points come from kills and Ultimate Orbs alone"),
	orb = p(10, "community", TDM_WIKI .. ": an Ultimate Orb 'Grants 10 points towards the player's ultimate charge'"),
	ultimate = {
		bladestorm = p(60, "community", TDM_WIKI .. "'s ultimate costs: Jett's Blade Storm, 60 points"),
		runitback = p(70, "community", TDM_WIKI .. "'s ultimate costs: Phoenix's Run it Back, 70 points"),
	},
	cooldowns = {
		cloudburst = p(29, "community", TDM_WIKI .. "'s cooldowns: Jett's Cloudburst, 29 s"),
		updraft = p(44, "community", TDM_WIKI .. "'s cooldowns: Jett's Updraft, 44 s"),
		tailwind = p(44, "community", TDM_WIKI .. "'s cooldowns: Jett's Tailwind, 44 s"),
		blaze = p(48, "community", TDM_WIKI .. "'s cooldowns: Phoenix's Blaze, 48 s"),
		hothands = p(54, "community", TDM_WIKI .. "'s cooldowns: Phoenix's Hot Hands, 54 s"),
		curveball = p(44, "community", TDM_WIKI .. "'s cooldowns: Phoenix's Curveball, 44 s"),
	},
	signatureStart = p(1, "community", TDM_WIKI .. ": 'Most agents start the match with one full charge of their signature ability'"),
	headStart = p(
		0.5,
		"community",
		TDM_WIKI
			.. ": '(plus 50% progress on the next charge if their signature has more than one charge available) and 50%"
			.. " progress towards the first charge of their basic abilities.'"
	),
} :: ModeKit

local P704 = "Patch 7.04"
local P300 = "Patch 3.0"
local P408 = "Patch 4.08"
local WIKI = "VALORANT Wiki, Jett"
local FANDOM = "Fandom wiki, Cloudburst"
local MOBALYTICS = "Mobalytics, Jett"
local BLADE = "VALORANT Wiki, Blade Storm"
local P501 = "Patch 5.01"
local P910 = "Patch 9.10"
local P1100 = "Patch 11.00"
local P1302 = "Patch 13.02"
local PHOENIX = "VALORANT Wiki, Phoenix"
local CURVE = "VALORANT Wiki, Curveball"
local STATUS = "VALORANT Wiki, 'Status Effect'"

AbilityConfig.Defs = {
	cloudburst = {
		id = "cloudburst",
		name = "Cloudburst",
		slot = AbilityConfig.C,
		kind = "basic",
		cost = p(200, "confirmed", P300 .. ": 'Cost increased 100 >>> 200'"),
		charges = p(2, "community", WIKI .. ": 2 charges (v3.06: 3 to 2)"),
		description = "Throw a cloud that blocks sight where it lands. Hold C to curve it towards your aim.",
	},
	updraft = {
		id = "updraft",
		name = "Updraft",
		slot = AbilityConfig.Q,
		kind = "basic",
		cost = p(150, "confirmed", P300 .. ": 'Cost increased 100 >>> 150'"),
		charges = p(1, "confirmed", P704 .. ": charges reduced from 2 to 1"),
		description = "Thrown high into the air at once.",
	},
	tailwind = {
		id = "tailwind",
		name = "Tailwind",
		slot = AbilityConfig.E,
		kind = "signature",
		charges = p(1, "community", WIKI .. ": 1 charge, free"),
		free = 1,
		recharge = { kind = "kills", kills = p(2, "confirmed", P408 .. ": 'Jett's Tailwind charge can still be regained with 2 kills'") },
		description = "E readies a gust; E again within its window dashes the way you're moving.",
	},
	bladestorm = {
		id = "bladestorm",
		name = "Blade Storm",
		slot = AbilityConfig.X,
		kind = "ultimate",
		points = p(8, "confirmed", P704 .. ": ultimate points increased from 7 to 8"),
		weapon = "kunai",
		description = "Five throwing knives. Fire throws one, and a kill brings them all back; alt fire throws all that are left.",
	},
	-- Phoenix's (system 30): his kit as the VALORANT Wiki lists it since
	-- Patch 9.10 moved Curveball to E and Hot Hands to Q. Curveball is the
	-- one that can be played.
	blaze = {
		id = "blaze",
		name = "Blaze",
		slot = AbilityConfig.C,
		kind = "basic",
		cost = p(150, "community", PHOENIX .. ": Blaze, 150"),
		charges = p(1, "community", PHOENIX .. ": Blaze, 1 use"),
		description = "A wall of fire that blocks sight and burns whoever walks through it.",
	},
	hothands = {
		id = "hothands",
		name = "Hot Hands",
		slot = AbilityConfig.Q,
		kind = "basic",
		cost = p(200, "confirmed", P910 .. ": Hot Hands 'Changed to a non-signature ability', 'Cost 200 credits'"),
		charges = p(1, "community", PHOENIX .. ": Hot Hands, 1 use"),
		description = "A fireball that bursts into a pool of fire where it lands.",
	},
	curveball = {
		id = "curveball",
		name = "Curveball",
		slot = AbilityConfig.E,
		kind = "signature",
		cost = p(250, "confirmed", P300 .. ": Curveball 'Cost increased 200 >>> 250' (" .. PHOENIX .. ": 250 still)"),
		charges = p(2, "community", PHOENIX .. ": Curveball, 2 uses"),
		-- Patch 9.10: 'Grants a free charge on round start'.
		free = 1,
		recharge = { kind = "kills", kills = p(2, "confirmed", P910 .. ": '2 kill reset to generate an additional charge'") },
		weapon = "flare",
		description = "E readies a flare. Fire throws it curving left, alt fire curving right; it soon pops, blinding all who see it.",
	},
	runitback = {
		id = "runitback",
		name = "Run it Back",
		slot = AbilityConfig.X,
		kind = "ultimate",
		points = p(7, "confirmed", P1302 .. ": 'Ultimate points increased from 6 to 7.'"),
		description = "Marks where you stand. Die before it's over, or let it run out, and you're back at the mark with full health.",
	},
} :: { [string]: AbilityDef }

-- The roles are Riot's: 'Duelist', on playvalorant.com's pages for Jett and
-- for Phoenix.
AbilityConfig.Agents = {
	jett = {
		id = "jett",
		name = "Jett",
		role = "Duelist",
		abilities = { "cloudburst", "updraft", "tailwind", "bladestorm" },
		passive = "drift",
	},
	phoenix = {
		id = "phoenix",
		name = "Phoenix",
		role = "Duelist",
		abilities = { "blaze", "hothands", "curveball", "runitback" },
		passive = "innerfire",
	},
} :: { [string]: Agent }

-- What each passive does, for agent select (system 29), in our words.
-- Phoenix's Inner Fire heals him in his own fire (Patch 9.10), which isn't
-- here yet.
AbilityConfig.Passives = {
	drift = { name = "Drift", description = "Hold jump while you fall to glide." },
	innerfire = { name = "Inner Fire", description = "His own fire heals him, where it would burn anyone else." },
} :: { [string]: { name: string, description: string } }

-- The agent each player plays until they pick another (agent select,
-- system 29).
AbilityConfig.DEFAULT_AGENT = "jett"
-- A kit of no agent's: no abilities, and no passive (deathmatch, system 26:
-- 'No abilities (yes, that means Jett can't glide...)', Riot Support).
AbilityConfig.NO_AGENT = ""

-- The agents' ids by index, and each id's index, for the wire (0 for no
-- agent's kit).
AbilityConfig.AgentIds = { "jett", "phoenix" }
AbilityConfig.AgentIndex = { jett = 1, phoenix = 2 } :: { [string]: number }

-- The ability an agent has in a slot, if any.
function AbilityConfig.abilityOf(agent: string, slot: number): AbilityDef?
	local a = AbilityConfig.Agents[agent]
	local id = a and a.abilities[slot]
	return if id then AbilityConfig.Defs[id] else nil
end

-- Agent select (system 29): how long each player has to lock an agent in,
-- once a match, from its start or from when they join it under way.
AbilityConfig.Select = {
	time = p(
		10,
		"estimate",
		"Ours, inside every mode's first phase, Skirmish's 15 s first buy phase the shortest; the reference's lobby takes 90 s"
			.. " (VALORANT Wiki, 'Unrated': 'Agent Select, which lasts for 90 seconds')"
	),
}

-- Jett's movement (system 17). The timings come from Riot's patch notes and
-- the VALORANT Wiki; nothing public gives the distances or speeds as
-- numbers, so those are ours, to be measured from public footage
-- (17-abilities.md, section 3).
AbilityConfig.Jett = {
	-- Tailwind: E spends the charge, and after the windup a window opens in
	-- which E again dashes.
	windup = p(1, "confirmed", P704 .. ": the activation windup increased from 0.75 s to 1 s"),
	window = p(7.5, "confirmed", P704 .. ": the dash window reduced from 12 s to 7.5 s"),
	dashTime = p(0.45, "community", WIKI .. ": 0.45 s (dash)"),
	dashDistance = p(7, "estimate", "About a doorway and a half; measure against a map's floor grid"),
	-- What's left of the dash's speed when it ends, at most the run speed.
	dashExit = p(1, "estimate", "Times the run speed; measure the slide after a dash"),
	-- Updraft: lifted straight up at a steady speed for its time, then falls
	-- as from a jump, the speed set so the feet top out this high.
	updraftTime = p(0.6, "community", "VALORANT Wiki, Updraft: duration 0.6 s"),
	updraftApex = p(4, "estimate", "Feet's rise at the top; measure against crates of known height"),
}

-- Jett's Cloudburst (system 18): C throws it from the eye at once, and it
-- flies straight while C is let go of; held, it turns towards the
-- crosshair. It bursts into a cloud where it hits the level, or in the air
-- once it has flown its longest. The cloud blocks sight, not bullets.
AbilityConfig.Cloudburst = {
	speed = p(30, "community", FANDOM .. ": 'Travel Rate 30 meters/s'"),
	maxFlight = p(2, "community", MOBALYTICS .. ": 'Maximum travel time in air: 2 seconds'"),
	-- Degrees a second the throw turns towards the crosshair while C is held.
	turnRate = p(240, "estimate", "Ours; measure a curved throw's arc in a public video"),
	-- Half the size of the box that flies, for what it hits.
	size = p(0.1, "estimate", "Ours: a ball about a hand across"),
	radius = p(3.35, "community", MOBALYTICS .. ": 'Radius: 3.35 meters' (the Fandom wiki's '5 meters wide' and GameRiv's 4.5 m disagree)"),
	duration = p(2.5, "confirmed", P704 .. ": its duration reduced from 4.5 s to 2.5 s"),
	-- From the burst to its full size, part of the duration.
	grow = p(0.6, "community", MOBALYTICS .. ": 'includes 0.6-second deployment time' (the Fandom wiki: 0.5 s to full size)"),
	-- Its last moments, thinning out before it goes.
	fade = p(0.3, "estimate", "Ours; frame-count a cloud's end in a public video"),
	-- The gun is put away to throw, and back in hand this long after.
	stow = p(0.25, "community", MOBALYTICS .. ": 'Unequip time: 0.25 seconds' (" .. P704 .. ": the re-equip slightly longer)"),
}

-- Jett's Blade Storm (system 19): X with the points full spends them and
-- puts five knives in hand, a weapon of their own in the fifth slot
-- (WeaponConfig's kunai, which has their throws and damage). She can draw
-- her guns and use her other abilities meanwhile, and X draws the knives
-- again. They're gone once they're all thrown with no kill to bring them
-- back, when she dies, and with the round.
AbilityConfig.BladeStorm = {
	-- From the cast until the first knife can go.
	windup = p(1.02, "community", BLADE .. ": 'Initial windup time' 1.02 s"),
}

-- Jett's Drift (system 20), her passive: holding jump while she falls holds
-- her fall to a glide. The rise isn't slowed, and her movement along the
-- ground and her aim in the air are as in any fall. Nothing public gives
-- the glide's speed; it's ours, to be measured from public footage
-- (20-drift.md, section 3).
AbilityConfig.Drift = {
	-- The fastest she falls while gliding, metres a second.
	fallSpeed = p(2, "estimate", "Not published; ours. Time a glide from Updraft's top to the floor in a public clip"),
	-- How quickly a faster fall slows to the glide when jump is held mid-fall.
	brake = p(60, "estimate", "Ours, metres a second each second. Frame-count a press mid-fall in a public clip"),
}

-- Phoenix's Curveball (system 30): E puts a flare in hand (WeaponConfig's
-- flare, in the fifth slot, as Blade Storm's knives are), and fire throws it
-- curving left, alt fire right. It flies a fixed path from the eye, ahead
-- and then round to the side, stops where it meets the level, and pops its
-- windup after the throw (FlareSim). The pop blinds whoever can see it, the
-- thrower and their side too: all of the longest blind for those looking
-- at it from near enough, less the further it is off their view and the
-- further away they are. A blind is a white screen for its share of the
-- longest, then clears over that share of the fade. Nothing public gives
-- the flight's speed or shape, or the falloff's angles and distances:
-- those are ours, to be measured from public footage (30-curveball.md,
-- section 3).
AbilityConfig.Curveball = {
	-- From the throw until the gun's back in hand.
	unequip = p(0.48, "community", CURVE .. ": 'Unequip' 0.48 seconds"),
	-- From the throw to the pop.
	windup = p(0.6, "confirmed", P1100 .. ": 'Curveball Windup increased 0.5s >>> 0.6s'"),
	-- The longest a blind is white for, looking straight at the pop.
	maxBlind = p(1.5, "confirmed", P501 .. ": 'Flash Max duration increased 1.1s >>> 1.5s'"),
	-- And how long the longest takes to clear after.
	fade = p(1, "community", STATUS .. ": 'its effects will gradually disappear from the player's screen over 1 second'"),
	-- Its flight: this fast, straight this long, then turning this fast round
	-- to the side this far, and straight again.
	speed = p(12, "estimate", "Ours, metres a second. Measure a throw's path against a map's floor grid in a public clip"),
	straight = p(0.1, "estimate", "Ours, seconds; the same clip"),
	turnRate = p(300, "estimate", "Ours, degrees a second; the same clip"),
	turn = p(90, "estimate", "Ours: a quarter turn, round a corner (Riot's agent page: it 'takes a curving path')"),
	-- Half the size of the box that flies, for what it meets.
	size = p(0.1, "estimate", "Ours: an orb about a hand across, as Cloudburst's"),
	-- The falloff: all of the longest blind within `fullAngle` of the view,
	-- falling to the `away` share at `edgeAngle` and behind; all of it out
	-- to `near`, falling to none at `far`; and less than `least` is none.
	fullAngle = p(
		50,
		"estimate",
		"Ours, degrees: about the view's sides (103 degrees across, CameraController); "
			.. STATUS
			.. ": 'Players looking directly at the flash on detonation will be blinded for the full duration'"
	),
	edgeAngle = p(
		90,
		"estimate",
		"Ours, degrees: off the screen. Patch 11.08: Yoru's flashes 'that were slightly offscreen were more effective than intended',"
			.. " and now follow 'the standard flash falloff curves'"
	),
	away = p(
		0.15,
		"estimate",
		"Ours; " .. STATUS .. ": those who 'have their backs to it' 'only be slightly blinded for a very brief time'"
	),
	near = p(
		25,
		"estimate",
		"Ours, metres; " .. STATUS .. ": 'the further away from the flash the player is, the less time they will be blinded for'"
	),
	far = p(
		60,
		"estimate",
		"Ours, metres; " .. STATUS .. ": 'At especially large distances it is possible for a player to not be blinded at all'"
	),
	least = p(0.05, "estimate", "Ours: a blind under a tenth of a second is none"),
}

return AbilityConfig
