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
-- second agent (system 30): his Curveball, Hot Hands (system 31), Blaze
-- (system 32) and Run it Back (system 33) can be played, and his passive,
-- Inner Fire, works. Sage is the third (system 36), with her Healing Orb,
-- her Slow Orb (system 37), her Barrier Orb (system 38) and her
-- Resurrection (system 39). Omen is the fourth (system 40), with his Dark
-- Cover, his Paranoia (system 41), his Shrouded Step (system 42) and his
-- From the Shadows (system 43). Sova is the fifth (system 44), with his
-- Recon Bolt, his Shock Bolt (system 45), his Hunter's Fury (system 46)
-- and his Owl Drone (system 47).
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
		resurrection = p(50, "community", TDM_WIKI .. "'s ultimate costs: Sage's Resurrection, 50 points"),
		fromtheshadows = p(60, "community", TDM_WIKI .. "'s ultimate costs: Omen's From the Shadows, 60 points"),
		huntersfury = p(70, "community", TDM_WIKI .. "'s ultimate costs: Sova's Hunter's Fury, 70 points"),
	},
	cooldowns = {
		cloudburst = p(29, "community", TDM_WIKI .. "'s cooldowns: Jett's Cloudburst, 29 s"),
		updraft = p(44, "community", TDM_WIKI .. "'s cooldowns: Jett's Updraft, 44 s"),
		tailwind = p(44, "community", TDM_WIKI .. "'s cooldowns: Jett's Tailwind, 44 s"),
		blaze = p(48, "community", TDM_WIKI .. "'s cooldowns: Phoenix's Blaze, 48 s"),
		hothands = p(54, "community", TDM_WIKI .. "'s cooldowns: Phoenix's Hot Hands, 54 s"),
		curveball = p(44, "community", TDM_WIKI .. "'s cooldowns: Phoenix's Curveball, 44 s"),
		barrierorb = p(94, "community", TDM_WIKI .. "'s cooldowns: Sage's Barrier Orb, 94 s"),
		sloworb = p(51, "community", TDM_WIKI .. "'s cooldowns: Sage's Slow Orb, 51 s"),
		healingorb = p(22, "community", TDM_WIKI .. "'s cooldowns: Sage's Healing Orb, 22 s"),
		shroudedstep = p(33, "community", TDM_WIKI .. "'s cooldowns: Omen's Shrouded Step, 33 s"),
		paranoia = p(73, "community", TDM_WIKI .. "'s cooldowns: Omen's Paranoia, 73 s"),
		darkcover = p(65, "community", TDM_WIKI .. "'s cooldowns: Omen's Dark Cover, 65 s"),
		owldrone = p(51, "community", TDM_WIKI .. "'s cooldowns: Sova's Owl Drone, 51 s"),
		shockbolt = p(26, "community", TDM_WIKI .. "'s cooldowns: Sova's Shock Bolt, 26 s"),
		reconbolt = p(48, "community", TDM_WIKI .. "'s cooldowns: Sova's Recon Bolt, 48 s"),
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
local P512 = "Patch 5.12"
local P910 = "Patch 9.10"
local P1100 = "Patch 11.00"
local P1302 = "Patch 13.02"
local P050 = "Patch 0.50"
local P100 = "Patch 1.0"
local PHOENIX = "VALORANT Wiki, Phoenix"
local CURVE = "VALORANT Wiki, Curveball"
local STATUS = "VALORANT Wiki, 'Status Effect'"
local HOT = "VALORANT Wiki, Hot Hands"
local PROJECTILE = "VALORANT Wiki, Projectile"
local INCENDIARY = "VALORANT Wiki, Incendiary"
local BLAZE = "VALORANT Wiki, Blaze"
local TIDE = "VALORANT Wiki, High Tide"
local SCREEN = "VALORANT Wiki, Toxic Screen"
local RUN = "VALORANT Wiki, Run it Back"
local P1300 = "Patch 13.00"
local SAGE = "VALORANT Wiki, Sage"
local ORB = "VALORANT Wiki, Healing Orb"
local SLOW = "VALORANT Wiki, Slow Orb"
local TRACKER = "valoranttracker.org, Sage"
local P047 = "Patch 0.47"
local P107 = "Patch 1.07"
local P1104 = "Patch 11.04"
local P1108 = "Patch 11.08"
local BARRIER = "VALORANT Wiki, Barrier Orb"
local DIGNITAS = "Dignitas, 'Tips and Tricks Using Sage Effectively'"
local RES = "VALORANT Wiki, Resurrection"
local ESPORTS = "esports.net's Sage guide"
local P404 = "Patch 4.04"
local OMEN = "VALORANT Wiki, Omen"
local COVER = "VALORANT Wiki, Dark Cover"
local PARANOIA = "VALORANT Wiki, Paranoia"
local STEP = "VALORANT Wiki, Shrouded Step"
local P049 = "Patch 0.49"
local SHADOWS = "VALORANT Wiki, From the Shadows"
local SOVA = "VALORANT Wiki, Sova"
local RECON = "VALORANT Wiki, Recon Bolt"
local SOVA_PAGE = "playvalorant.com's page for Sova"
local DRIVEN = "esportsdriven.com's Sova guide"
local SOVA_TRACKER = "valoranttracker.org, Sova"
local SOVA_SPIKE = "THESPIKE.GG's Sova guide"
local SOVA_ESPORTS = "esports.net's Sova guide"
local BOOSTING = "Boosting Ground's Sova guide"
local SOVA_DIGNITAS = "Dignitas' Sova guide"
local AIMLAB = "Aim Lab's Sova guide"
local SOVA_MOBALYTICS = "Mobalytics' Sova page"
local SOVA_DOTESPORTS = "Dot Esports' article on Sova's drone"

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
	-- Patch 9.10 moved Curveball to E and Hot Hands to Q. All of it can be
	-- played: Curveball, Hot Hands (system 31), Blaze (system 32) and Run it
	-- Back (system 33).
	blaze = {
		id = "blaze",
		name = "Blaze",
		slot = AbilityConfig.C,
		kind = "basic",
		cost = p(150, "confirmed", P512 .. ": 'Blaze (C) Cost decreased 200 >>> 150' (" .. PHOENIX .. ": 150 still)"),
		charges = p(1, "community", PHOENIX .. ": Blaze, 1 use"),
		weapon = "flamewall",
		description = "C readies a wall of fire. Fire sends it along the floor, held fire bends it; it blocks sight, burns enemies and heals you.",
	},
	hothands = {
		id = "hothands",
		name = "Hot Hands",
		slot = AbilityConfig.Q,
		kind = "basic",
		cost = p(200, "confirmed", P910 .. ": Hot Hands 'Changed to a non-signature ability', 'Cost 200 credits'"),
		charges = p(1, "community", PHOENIX .. ": Hot Hands, 1 use"),
		weapon = "fireball",
		description = "Q readies a fireball. Fire throws it, alt fire lobs it; it bursts into fire that burns enemies and heals you.",
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
	-- Sage's (system 36): her kit as the VALORANT Wiki lists it. All of it
	-- can be played: her Healing Orb, her Slow Orb (system 37), her Barrier
	-- Orb (system 38) and her Resurrection (system 39).
	barrierorb = {
		id = "barrierorb",
		name = "Barrier Orb",
		slot = AbilityConfig.C,
		kind = "basic",
		cost = p(300, "confirmed", P1108 .. ": Barrier Orb 'Cost reduced from 400 to 300'"),
		charges = p(1, "community", SAGE .. ": Barrier Orb, 1 use"),
		weapon = "wallorb",
		description = "C readies a barrier orb. Fire raises a wall of ice where it shows; C again or held alt fire turns it.",
	},
	sloworb = {
		id = "sloworb",
		name = "Slow Orb",
		slot = AbilityConfig.Q,
		kind = "basic",
		cost = p(200, "confirmed", P300 .. ": Slow Orb (Q) 'Cost increased 100 >>> 200' (" .. SAGE .. ": 200 still)"),
		charges = p(2, "community", SAGE .. ": Slow Orb, 2 uses"),
		weapon = "iceorb",
		description = "Q readies a slowing orb. Fire throws it; it bursts into a field of ice that slows everyone in it, you too.",
	},
	healingorb = {
		id = "healingorb",
		name = "Healing Orb",
		slot = AbilityConfig.E,
		kind = "signature",
		charges = p(1, "community", SAGE .. ": Healing Orb, 1 use, free"),
		free = 1,
		recharge = { kind = "cooldown", seconds = p(45, "confirmed", P100 .. ": 'Healing Orb cooldown increased 35 >>> 45 seconds'") },
		weapon = "healorb",
		description = "E readies a healing orb. Fire heals the hurt ally in your crosshair, alt fire heals you, 100 health over 5 s.",
	},
	resurrection = {
		id = "resurrection",
		name = "Resurrection",
		slot = AbilityConfig.X,
		kind = "ultimate",
		points = p(7, "confirmed", P910 .. ": Resurrection 'Ult Cost 8 >>> 7'"),
		weapon = "revive",
		description = "X readies it. Fire on a fallen ally's body brings them back where they lie, with full health and no shield.",
	},
	-- Omen's (system 40): his kit as the VALORANT Wiki lists it. His Dark
	-- Cover, his Paranoia (system 41), his Shrouded Step (system 42) and his
	-- From the Shadows (system 43) can be played.
	shroudedstep = {
		id = "shroudedstep",
		name = "Shrouded Step",
		slot = AbilityConfig.C,
		kind = "basic",
		cost = p(100, "confirmed", P404 .. ": Shrouded Step 'Cost decreased 150 >>> 100' (" .. OMEN .. ": 100 still)"),
		charges = p(2, "community", OMEN .. ": Shrouded Step, 2 uses"),
		weapon = "stepmark",
		description = "C readies a short teleport, its mark on the floor. Fire steps you through the shadows to it.",
	},
	paranoia = {
		id = "paranoia",
		name = "Paranoia",
		slot = AbilityConfig.Q,
		kind = "basic",
		cost = p(250, "confirmed", P512 .. ": 'Paranoia (Q) Cost decreased 300 >>> 250' (" .. OMEN .. ": 250 still)"),
		charges = p(1, "community", OMEN .. ": Paranoia, 1 use"),
		weapon = "blindorb",
		description = "Q readies a shadow orb. Fire sends it forward through walls, nearsighting and deafening everyone it touches.",
	},
	darkcover = {
		id = "darkcover",
		name = "Dark Cover",
		slot = AbilityConfig.E,
		kind = "signature",
		cost = p(150, "confirmed", P404 .. ": Dark Cover 'Cost increased 100 >>> 150'"),
		charges = p(2, "community", OMEN .. ": Dark Cover, 2 uses"),
		-- Patch 3.0: 'Granted signature charges reduced 2 >>> 1'.
		free = 1,
		recharge = { kind = "cooldown", seconds = p(40, "confirmed", P1108 .. ": Dark Cover 'Cooldown increased from 30s → 40s'") },
		weapon = "smokeorb",
		description = "E readies a shadow orb. Hold fire to send its mark further, alt fire to bring it closer, and E again to smoke there.",
	},
	fromtheshadows = {
		id = "fromtheshadows",
		name = "From the Shadows",
		slot = AbilityConfig.X,
		kind = "ultimate",
		points = p(7, "community", OMEN .. ": From the Shadows, 7 points"),
		weapon = "shadowmap",
		description = "X brings up the map. Fire on a place in it sends you there as a Shade, which an enemy's shot or X again sends back before you form.",
	},
	-- Sova's (system 44): his kit as the VALORANT Wiki lists it. His Recon
	-- Bolt, his Shock Bolt (system 45), his Hunter's Fury (system 46) and
	-- his Owl Drone (system 47) can be played.
	owldrone = {
		id = "owldrone",
		name = "Owl Drone",
		slot = AbilityConfig.C,
		kind = "basic",
		cost = p(400, "confirmed", P300 .. ": Owl Drone 'Cost increased 300 >>> 400' (" .. SOVA .. ": 400 still)"),
		charges = p(1, "community", SOVA .. ": Owl Drone, 1 use"),
		weapon = "owl",
		description = "C readies a drone, and fire sends it out for you to fly for 7 s, or until C again. Fire from it shoots darts that reveal whoever they strike.",
	},
	shockbolt = {
		id = "shockbolt",
		name = "Shock Bolt",
		slot = AbilityConfig.Q,
		kind = "basic",
		cost = p(150, "confirmed", P300 .. ": Shock Dart 'Cost increased 100 >>> 150' (" .. SOVA .. ": 150 still)"),
		charges = p(2, "community", SOVA .. ": Shock Bolt, 2 uses"),
		weapon = "shockbow",
		description = "Q readies the bow with a shock bolt. Hold fire to draw it further and alt fire to add bounces; it bursts where it lands, hurting those near it.",
	},
	reconbolt = {
		id = "reconbolt",
		name = "Recon Bolt",
		slot = AbilityConfig.E,
		kind = "signature",
		charges = p(1, "community", SOVA .. ": Recon Bolt, 1 use, free"),
		free = 1,
		recharge = {
			kind = "cooldown",
			seconds = p(
				50,
				"confirmed",
				P1300 .. ": 'The signature ability cooldown of Sova, Fade, Skye, Breach, KAY/0 have been reduced from 60s to 50s.'"
			),
		},
		weapon = "bow",
		description = "E readies the bow. Hold fire to draw it further and alt fire to add bounces; it sticks where it lands and pulses, revealing enemies it sees.",
	},
	huntersfury = {
		id = "huntersfury",
		name = "Hunter's Fury",
		slot = AbilityConfig.X,
		kind = "ultimate",
		points = p(8, "confirmed", P300 .. ": Hunter's Fury 'Ultimate points required increased 7 >>> 8' (" .. SOVA .. ": 8 still)"),
		weapon = "furybow",
		description = "X readies the bow with three energy blasts for 6 s. Fire charges one, then sends it in a long line through walls, hurting and revealing enemies in it.",
	},
} :: { [string]: AbilityDef }

-- The roles are Riot's: 'Duelist', on playvalorant.com's pages for Jett and
-- for Phoenix, Sage's in Patch 1.01: 'As a Sentinel, Sage is supposed to
-- be most effective when defending territory that she already controls.',
-- Omen's in Patch 4.04: 'We want to increase his reliability as a
-- Controller', and Sova's in Patch 13.00: 'We're reducing Signature
-- Ability cooldowns for Initiators! (Sova, Fade, Skye, Breach, and KAY/O)'.
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
	sage = {
		id = "sage",
		name = "Sage",
		role = "Sentinel",
		abilities = { "barrierorb", "sloworb", "healingorb", "resurrection" },
	},
	omen = {
		id = "omen",
		name = "Omen",
		role = "Controller",
		abilities = { "shroudedstep", "paranoia", "darkcover", "fromtheshadows" },
	},
	sova = {
		id = "sova",
		name = "Sova",
		role = "Initiator",
		abilities = { "owldrone", "shockbolt", "reconbolt", "huntersfury" },
	},
} :: { [string]: Agent }

-- What each passive does, for agent select (system 29), in our words.
-- Phoenix's Inner Fire heals him in his own fire (Patch 9.10, system 31).
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
AbilityConfig.AgentIds = { "jett", "phoenix", "sage", "omen", "sova" }
AbilityConfig.AgentIndex = { jett = 1, phoenix = 2, sage = 3, omen = 4, sova = 5 } :: { [string]: number }

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

-- Phoenix's Hot Hands (system 31): Q puts a fireball in hand (WeaponConfig's
-- fireball, in the fifth slot, as the flare is), and fire throws it, alt
-- fire lobs it underhand. It flies from the eye under a light gravity, off
-- walls and ceilings, and bursts where it meets the floor; once its air
-- time is up it stops and drops straight down, and bursts where it lands
-- (FireballSim). Its fire spreads from there to its radius, no further than
-- the walls round it let it, and burns for its duration: enemies standing
-- in it lose health every moment, allies less, and Phoenix heals instead
-- (InnerFire). Riot gives the heal and how high the fire reaches; the
-- wiki the rest (31-hot-hands.md, section 2).
AbilityConfig.HotHands = {
	-- From the throw until the gun's back in hand.
	unequip = p(0.7, "community", HOT .. ": 'Unequip time' 0.7 seconds"),
	-- Its flight: this fast thrown or lobbed, falling at this share of the
	-- world's gravity, for its air time at most.
	speed = p(18, "community", PROJECTILE .. ": Hot Hands a 'Class 2' throw, 'Speed 1800', read as centimetres a second"),
	lobSpeed = p(6.3, "community", PROJECTILE .. ": underhand throws 'Class 0.7', 'Speed 630', read as centimetres a second"),
	gravity = p(0.3, "community", PROJECTILE .. ": 'Gravity 0.3' for both, read as a share of the world's"),
	worldGravity = p(9.8, "estimate", "Ours: Unreal Engine's default, 980 cm/s^2, for that share; no source gives the reference's"),
	airTime = p(1.5, "community", HOT .. ": 'Maximum air time' 1.5 seconds, then it 'will immediately drop down vertically'"),
	-- Half the size of the box that flies, for what it meets.
	size = p(0.1, "estimate", "Ours: a ball about a hand across, as the flare's"),
	-- What's kept of its speed off a wall, and how level a surface has to be
	-- for it to burst there (the up of its normal).
	bounce = p(0.5, "estimate", "Ours; " .. INCENDIARY .. ": a grenade's bounces 'reducing its arc and velocity'"),
	floor = p(
		0.7,
		"estimate",
		"Ours, about 45 degrees; " .. HOT .. ": it 'detonates as soon as it comes into contact with horizontal terrain'"
	),
	-- The fire: this far round, grown to it over the spread, burning for its
	-- duration from the burst, and gone at once.
	radius = p(4.5, "community", HOT .. ": 'Radius' 4.5 meters ('not confirmed by game files')"),
	spread = p(0.75, "community", HOT .. ": a '0.75-second spread time' (estimated there)"),
	duration = p(4, "community", HOT .. ": 'Duration' 4 seconds"),
	-- How high over the floor it burns, and how far below it (a slope, a
	-- step down); and how high over the floor a wall stops it spreading.
	height = p(
		1.2,
		"confirmed",
		P050 .. ": 'Height required to jump out of all damaging area denial abilities 80 >> 120', read as centimetres"
	),
	depth = p(0.5, "estimate", "Ours: down a slope or a step from the burst"),
	wallHeight = p(0.5, "estimate", "Ours: so a kerb doesn't stop it spreading and a crate does"),
	-- Health a second it takes from an enemy standing in it, and an ally's
	-- share of that.
	burn = p(
		60,
		"community",
		HOT .. ": '1 per tick', '60 per second'; " .. P100 .. ": Blaze's 1 every 0.033 seconds 'half as effective as Hot Hands'"
	),
	allyShare = p(1 / 3, "estimate", "Ours: " .. HOT .. ": 'Yes (damage reduced for allies)', with no number"),
}

-- Phoenix's Blaze (system 32): C puts a flame in hand (WeaponConfig's
-- flamewall, in the fifth slot, as the fireball is), and fire sends it out
-- from his feet along the floor the way he's facing, at its speed, for its
-- flight. While fire is held from then on it bends towards the crosshair,
-- and once it's let go it runs straight on; the gun's back a moment after
-- he lets go, or the run's over (Patch 5.01). It runs through walls (Patch
-- 9.10), up and down whatever's lower than its hover, and stops where it
-- finds no floor below (BlazeSim). Then a wall of fire rises from where he
-- cast it and spreads along the run to its end, blocking sight but not
-- bullets, and stands for its duration from rising: whoever stands in it
-- burns, allies less, and Phoenix heals instead (InnerFire). Riot gives
-- its duration and burn; the wiki its timings and length; the rest is ours
-- (32-blaze.md, section 2).
AbilityConfig.Blaze = {
	-- From the run's end, or fire let go, until the gun's back in hand.
	unequip = p(0.5, "community", BLAZE .. ": 'Unequip time' 0.5 s (estimated there)"),
	-- The run: this long at most, this far at most, so this fast; bending
	-- towards the crosshair this fast while fire's held.
	flight = p(0.75, "community", BLAZE .. ": 'Deploy time' 0.125-0.75 s 'depending on distance' (estimated there)"),
	length = p(21, "community", BLAZE .. ": 'Length' 1-21 m (estimated there)"),
	turnRate = p(
		180,
		"estimate",
		"Ours: High Tide's, the wall it's likened to in Patch 9.10 (" .. TIDE .. ": 'Maximum bend' 180 degrees/second)"
	),
	-- How far over the floor it runs, so it climbs what's lower and goes
	-- through what's taller; and how far below that it looks for floor.
	hover = p(0.9, "estimate", "Ours: over a step or a box, under a low wall; " .. BLAZE .. ": it leaves a path 'on the ground' below it"),
	drop = p(10, "estimate", "Ours: down a ledge to the floor below; past that it has no floor and stops"),
	-- The wall: spreading from his end this fast, standing for its duration
	-- from rising, then falling; this tall, this thick, and reaching this
	-- far below its floor (a step down from it).
	spreadSpeed = p(
		42,
		"estimate",
		"Ours: " .. BLAZE .. "'s '225-240' total at 30 a second has the far end of the longest (21 m) burn 0.5 s less"
	),
	duration = p(8, "confirmed", P100 .. ": 'Blaze duration increased 6 >>> 8 seconds'"),
	height = p(4, "estimate", "Ours, over a head and a jump; " .. SCREEN .. ", a wall like it: a '4-meter height' (estimated there)"),
	thickness = p(1, "estimate", "Ours: about a stride; time a run through it in a public clip"),
	depth = p(0.5, "estimate", "Ours: down a slope or a step from it, as Hot Hands' fire"),
	-- Health a second it takes from an enemy standing in it, and an ally's
	-- share of that.
	burn = p(30, "confirmed", P100 .. ": 'Blaze damage: 15 every 0.25s >>> 1 every 0.033 seconds'"),
	allyShare = p(1 / 3, "estimate", "Ours, as Hot Hands': " .. BLAZE .. ": 'Yes (damage reduced for allies)', with no number"),
}

-- Phoenix's Inner Fire (system 31), his passive: touching his own fire
-- heals him instead of burning him. Since Patch 9.10 the first touch of
-- each fire starts the heal, a point at a time, and it keeps on after he
-- leaves it. It mends health alone, up to his most. Blaze's wall (system
-- 32) gives the same, at half the pace.
AbilityConfig.InnerFire = {
	heal = p(50, "confirmed", P100 .. ": 'the total healing output of these two abilities is at parity (50 health each)'"),
	hotHandsEvery = p(0.08, "confirmed", P100 .. ": 'Hot Hands healing: 3 every 0.25s >>> 1 every 0.08s.'"),
	blazeEvery = p(0.16, "confirmed", P100 .. ": 'Blaze healing: 3 every 0.25s >>> 1 every 0.16 seconds'"),
}

-- Phoenix's Run it Back (system 33), his ultimate: X with the points full
-- spends them and marks where he stands, and the way he faces, at once. Its
-- activation puts his gun away, and nothing else is cast meanwhile. For its
-- duration from the cast, a hit that would kill him doesn't: his body's
-- gone at once, out of play, as it is when it runs out. Once his body's
-- been gone its time he's back at the mark, rising there, in play but held,
-- and then free, with full health and the shield he had as he cast it,
-- every gun reloaded and the one in hand drawn (Patches 1.0, 5.01 and
-- 5.07), facing the way he did. The wiki gives the times, from the game's
-- files (33-run-it-back.md, section 2).
AbilityConfig.RunItBack = {
	-- From the cast until it runs out, its activation first.
	duration = p(10, "community", RUN .. ": 'Duration' '10 seconds (Includes 1-second activation animation)'"),
	activation = p(1, "community", RUN .. ": the duration's '1-second activation animation'"),
	-- His return: his body gone this long, then rising at the mark this
	-- long, his gun in hand ready as it ends.
	away = p(1, "community", RUN .. ": 'Revive duration' 'Total 2.4 seconds', a '1-second dissipate'"),
	rise = p(1.4, "community", RUN .. ": and a '1.4-second respawn'"),
	-- How much longer than his body's time, on the server's clock, it stays
	-- out of play when his moves haven't brought him back (they've stopped
	-- coming): then it's back in play where it is.
	grace = p(1, "estimate", "Ours: so moves held back can't keep him out of play for long"),
}

-- Sage's Healing Orb (system 36): E puts the orb in hand (WeaponConfig's
-- healorb, in the fifth slot, as the flare is). Fire with the crosshair over
-- a hurt ally heals them, and alt fire heals her, if she's hurt; a try that
-- finds nobody to heal leaves it in hand. The server judges each try from
-- what her screen showed (HealServer), and as one takes, spends the charge
-- and puts the orb away. The heal gives health alone, a little at a time up
-- to the most, over its duration, and stops for a moment each time they're
-- hurt. Riot gives the heals, their time and the cooldown, the wiki the
-- rest it gives; how near the crosshair has to be is ours (36-healing-orb.md,
-- section 2).
AbilityConfig.HealingOrb = {
	-- From the heal until the gun's back in hand.
	unequip = p(0.7, "community", ORB .. ": 'Unequip' 0.7 seconds"),
	-- The health each heal gives in all, over its duration.
	allyHeal = p(100, "confirmed", P512 .. ": 'Ally heal total amount increased 60HP>>> 100HP'"),
	selfHeal = p(100, "confirmed", P1300 .. ": 'Self Heal-Over-Time has increased from 50 to 100.'"),
	duration = p(
		5,
		"confirmed",
		P910 .. ": the self heal's 'Heal time matched to ally heal at around 5 seconds' (" .. ORB .. ": 'Duration' 5 seconds)"
	),
	-- How long a heal stops for each time its target's hurt, its time
	-- stopping with it, so it still gives all it has.
	pause = p(1, "estimate", "Ours: " .. ORB .. ": 'The healing effect is briefly paused if the target takes damage', with no number"),
	-- How far off a body the crosshair can be and still be over it, and how
	-- far away an ally can be.
	width = p(0.4, "estimate", "Ours, metres: the body's half width (Hitboxes, 0.22 m) and a little more, so it needn't be on it exactly"),
	reach = p(60, "estimate", "Ours, metres: about a map's longest sightline; " .. ORB .. ": an ally 'must be in Sage's line of sight'"),
}

-- Sage's Slow Orb (system 37): Q puts the orb in hand (WeaponConfig's
-- iceorb, in the fifth slot, as the fireball is), and fire throws it. It
-- flies from the eye as Hot Hands' fireball does (FireballSim), faster and
-- falling harder, off walls and ceilings, with no air time to run out, and
-- bursts where it meets a floor into a field of ice (SlowSim). The field
-- spreads to its radius, no further than the walls round it let it, and
-- lasts its duration from the burst. Everyone standing in it, allies and
-- Sage too, is slowed: their speed along the ground and in the air held to
-- a share of their run's at once, their jumps lower and a dash slower.
-- Riot gives the slow, its time, the air's and the dash's; the wiki and a
-- tracker the rest they give (37-slow-orb.md, section 2).
AbilityConfig.SlowOrb = {
	-- From the throw until the gun's back in hand.
	unequip = p(0.4, "community", SLOW .. ": 'Unequip' 0.4 seconds (game files)"),
	-- Its flight: this fast, falling at this share of the world's gravity.
	speed = p(29, "community", PROJECTILE .. ": the Slow Orb a 'Class 3' throw, 'Speed 2900', read as centimetres a second"),
	gravity = p(0.45, "community", PROJECTILE .. ": 'Gravity 0.45', read as a share of the world's"),
	worldGravity = p(9.8, "estimate", "Ours, as Hot Hands': Unreal Engine's default, 980 cm/s^2; no source gives the reference's"),
	-- Half the size of the box that flies, for what it meets.
	size = p(0.1, "estimate", "Ours: an orb about a hand across, as the fireball"),
	-- What's kept of its speed off a wall, and how level a surface has to be
	-- for it to burst there (the up of its normal).
	bounce = p(0.5, "estimate", "Ours, as Hot Hands'"),
	floor = p(0.7, "estimate", "Ours, about 45 degrees; " .. SLOW .. ": it detonates on contact with horizontal terrain"),
	-- The field: this far round, grown to it over the spread, lasting its
	-- duration from the burst, and gone at once.
	radius = p(5.6, "community", TRACKER .. ": 'Radius 8m' (mid-2020), less " .. P107 .. "'s 'Size reduced by 30%', read as the radius"),
	spread = p(0.3, "estimate", "Ours: the ice bursts out over a moment"),
	duration = p(7, "confirmed", P050 .. ": 'Slow Orb zone duration decreased from 9 seconds to 7 seconds'"),
	-- How high over its floor it slows, and how far below it; and how high
	-- over the floor a wall stops it spreading.
	height = p(
		1.2,
		"estimate",
		"Ours: over a jump's top (0.85 m), so a jump in it stays slowed; " .. P050 .. " has 1.2 m to jump out of a damaging field"
	),
	depth = p(0.5, "estimate", "Ours, as Hot Hands' fire: down a slope or a step from the burst"),
	wallHeight = p(0.5, "estimate", "Ours, as Hot Hands' fire: so a kerb doesn't stop it spreading and a crate does"),
	-- What it takes from whoever's in it: the share of their speed, along
	-- the ground and in the air; of a jump's height; and of a dash's speed.
	slow = p(
		0.5,
		"confirmed",
		P050
			.. ": 'Slow Orb slowing amount decreased from 65% to 50%'; "
			.. P047
			.. ": it 'now also slows the air speed of players in the zone'"
	),
	jump = p(0.3, "community", TRACKER .. ": its jump height reduction, 30% (mid-2020)"),
	dash = p(0.5, "confirmed", P910 .. ": 'reduce the dash speed of enemies caught inside the slowing zone by 50%'"),
}

-- Sage's Barrier Orb (system 38): C puts the orb in hand (WeaponConfig's
-- wallorb, in the fifth slot), and a targeter shows where its wall would
-- go (BarrierSim): on the floor where the crosshair meets it, no further
-- than its range, across the way she looks. C again turns it a quarter,
-- and alt fire held turns it as she turns. Fire raises the wall there, if
-- there's a floor for it: its segments in a row, each standing on the
-- floor under its middle and left out where there's none near enough. It
-- rises out of the floor over its deploy time, lifting anyone standing
-- where it rises onto its top, and stands its duration from the cast, in
-- everyone's way: their steps', their bullets' and their sight's. Each
-- segment has health of its own, which enemies' bullets and knives take,
-- and breaks at none. It fortifies its time after the cast, each segment
-- gaining what fortifying adds, so what it's lost stays lost, and in its
-- last moments it decays, each segment losing its share of what it has
-- left, until they all go together. It can't be raised in the buy phase.
-- Riot gives the health, the fortify, the range and the buy phase; the
-- wiki and a guide the rest they give (38-barrier-orb.md, section 2).
AbilityConfig.BarrierOrb = {
	-- From the wall raised until the gun's back in hand.
	unequip = p(0.7, "community", BARRIER .. ": unequip 0.7 s (game files)"),
	-- Where it can go: this far from the eye at most, on a floor this level
	-- (the up of its normal).
	range = p(15, "confirmed", P1104 .. ": 'Sage wall cast range has increased from 10m >>> 15m'"),
	floor = p(0.7, "estimate", "Ours, about 45 degrees, as the Slow Orb's; " .. BARRIER .. ": it places a wall on horizontal terrain"),
	-- How far below where the aim ends it looks for a floor, and how far
	-- over and under the targeter's floor each segment looks for its own.
	drop = p(20, "estimate", "Ours: aimed into the sky at the range's end, down to the floor below"),
	climb = p(1, "estimate", "Ours: a segment stands on a crate or a step up to a metre over the targeter's floor"),
	fall = p(1, "estimate", "Ours: or on a floor down to a metre under it; past either it's left out"),
	-- The wall: this many segments in a row, each this long, this thick and
	-- this tall over its floor, reaching this far under it, so a slope or a
	-- step under its ends leaves no gap.
	segments = p(4, "community", BARRIER .. ": size, 4 segments (game files)"),
	length = p(2.6, "community", BARRIER .. ": '2.6 x 1.5 meters each', '10.4 x 1.5 meters total' (game files): 2.6 along it"),
	thickness = p(
		1.5,
		"community",
		BARRIER .. ": and 1.5 through it (our reading: as its height, it wouldn't hide a standing agent's eye)"
	),
	height = p(2.5, "community", DIGNITAS .. ": 'It seems to be about 140% of the player's height', of our 1.8 m player"),
	sink = p(0.5, "estimate", "Ours: under its floor, so it meets a slope or a step under its ends"),
	-- Its time from the cast: rising over the first of it, fortified once
	-- this long's gone, decaying from this long, and gone at the end.
	rise = p(1.35, "community", BARRIER .. ": deploy time 1.35 s (estimated), read as the time it rises over"),
	fortify = p(2, "confirmed", P1108 .. ": 'Fortification delay reduced from 3.3 seconds to 2 seconds'"),
	decay = p(35, "community", BARRIER .. ": decay begins after 35 s (game files)"),
	duration = p(40, "community", BARRIER .. ": duration 40 s in all, the deploy time included (game files)"),
	-- Each segment's health as it rises, and once it's fortified.
	health = p(400, "confirmed", P107 .. ": 'Wall forms at 400 HP'"),
	fortified = p(600, "confirmed", P1108 .. ": 'Health of Barrier segments decreased from 800 to 600'"),
}

-- Sage's Resurrection (system 39), her ultimate: X with the points full
-- puts it in hand (WeaponConfig's revive, in the fifth slot, as the Healing
-- Orb is). Fire with the crosshair over a dead ally's body, within its
-- reach, brings them back: the points are spent and it's put away at once.
-- A try that finds no body leaves it in hand. The server judges each try
-- from what her screen showed (ReviveServer). The body rises in its
-- crystals over the rise, out of harm's way, and then they burst out at
-- its top, with full health and no shield, and fall to the floor, held,
-- in harm's way, until control's back at the end of the fall. A wall of
-- ice they'd come back inside breaks (Patch 3.0). Riot gives the reach;
-- the wiki the times (39-resurrection.md, section 2).
AbilityConfig.Resurrection = {
	-- From the cast until the gun's back in hand.
	unequip = p(1, "community", RES .. ": unequip time 1 s (game files)"),
	-- How far away a body can be along the crosshair, and how far off its
	-- length the crosshair can be and still be over it.
	reach = p(12, "confirmed", P1104 .. ": 'Sage resurrection range has increased from 6m >>> 12m'"),
	width = p(
		0.5,
		"estimate",
		"Ours, metres: about the body's width, so the crosshair needn't be on it exactly (Patch 11.10 has its indicator snap to allies)"
	),
	-- The return: the body rising this long, out of harm's way, then they
	-- fall, held and in harm's way, this long.
	rise = p(2, "community", RES .. ": windup time 2 s (game files); " .. ESPORTS .. ": '2s invulnerability'"),
	fall = p(1.3, "community", RES .. ": revive duration 1.3 s (game files); " .. ESPORTS .. ": '1.3s vulnerability'"),
	-- How high over its floor the body rises, where they burst out.
	height = p(0.5, "estimate", "Ours: " .. RES .. " has the body rise up and them fall down to the ground, with no height"),
}

-- Omen's Dark Cover (system 40), his signature: E puts a shadow orb in
-- hand (WeaponConfig's smokeorb, in the fifth slot), with a mark along the
-- crosshair, through walls, where it would go: held fire sends the mark
-- further and held alt fire brings it closer (Patch 1.0), and E again sends
-- the orb there, unseen, through anything in its way, to burst into a ball
-- of smoke on the floor under the mark. The smoke stands its duration and
-- goes at once, after a warning. Riot gives the cost, the recharge, the
-- free charge, the duration and the orb's speed; the wiki the reach, the
-- radius and the times (40-dark-cover.md, section 2).
AbilityConfig.DarkCover = {
	-- From the throw until the gun's back in hand.
	unequip = p(0.7, "community", COVER .. ": unequip time 0.7 s (game files)"),
	-- How far along the crosshair the mark can go, and how near.
	reach = p(80, "community", COVER .. ": max deploy distance 80 m (game files)"),
	near = p(2, "estimate", "Ours, metres: not published; enough to smoke at your feet"),
	-- Where the mark starts as the orb comes into hand: where the crosshair
	-- meets the level, but no further than this.
	start = p(15, "estimate", "Ours, metres: not published"),
	-- How fast held fire or alt fire moves the mark (metres a second).
	push = p(15, "estimate", "Ours: not published; the length of a site in about 2 s"),
	-- The orb's flight, straight to the smoke (metres a second).
	speed = p(64, "confirmed", P404 .. ": 'Projectile Speed increased 2800 >>> 6400' (" .. COVER .. ": 64 m/s)"),
	-- The smoke: its radius, how long it takes to grow to it once the orb
	-- is there, how long it stands from then, and how long before its end
	-- it warns that it's going.
	radius = p(4.1, "community", COVER .. ": radius 4.1 m (game files)"),
	grow = p(1, "community", COVER .. ": deploy time 1 s (game files), read as the smoke growing"),
	duration = p(15, "confirmed", P050 .. ": 'Dark Cover smoke duration increased 12 >> 15 seconds'"),
	warn = p(1.5, "community", COVER .. ": a warning at 13.5 s (v7.08), 1.5 s before it goes"),
	-- How far below the mark it looks for a floor to stand on.
	depth = p(50, "estimate", "Ours, metres: below that, nowhere"),
}

-- Omen's Paranoia (system 41): Q puts the orb in hand (WeaponConfig's
-- blindorb, in the fifth slot, as the Slow Orb is), and fire sends it. It
-- appears a little ahead of his eye (Patch 4.04's forward spawn offset)
-- and flies straight along the crosshair at its speed for its travel,
-- through walls and anyone in its way (ParanoiaSim). Everyone it touches
-- on the way, allies too, is nearsighted and deafened: for its time they
-- see nothing past its vision but darkness, hear little, and their
-- minimap is covered, and then it clears over its fade. Riot gives the
-- speed and the travel; the wiki the radius and the times
-- (41-paranoia.md, section 2).
AbilityConfig.Paranoia = {
	-- From the throw until the gun's back in hand.
	unequip = p(0.7, "community", PARANOIA .. ": unequip 0.7 s (game files)"),
	-- Its flight: appearing this far ahead of the eye, then flying this
	-- fast, this far from there.
	offset = p(
		4.5,
		"estimate",
		"Ours, metres: "
			.. P404
			.. ": 'Added forward spawn offset, so players adjacent to Omen are not hit', with no number; its radius and a little"
	),
	speed = p(20, "confirmed", P1108 .. ": 'Projectile speed increased from 16 meters per second → 20 meters per second'"),
	travel = p(25, "confirmed", P1108 .. ": 'Travel distance reduced from 32.5m → 25m', read as from where it appears"),
	-- How far from its middle it touches someone.
	radius = p(4.3, "community", PARANOIA .. ": projectile radius 4.3 m (game files)"),
	-- The nearsight: whole for its duration, seeing no further than its
	-- vision, then clearing over the fade.
	duration = p(2, "community", PARANOIA .. ": nearsight duration 2 s (game files)"),
	vision = p(7.5, "community", PARANOIA .. ": nearsighted vision radius 7.5 m (game files)"),
	fade = p(0.5, "estimate", "Ours: " .. PARANOIA .. " gives no fade time; the dark clears over a moment"),
}

-- Omen's Shrouded Step (system 42): C puts it in hand (WeaponConfig's
-- stepmark, in the fifth slot), with a mark where it would take him: along
-- the crosshair no further than its range, on the floor below where the
-- aim ends, if he'd stand there (StepSim). Fire there spends its charge
-- and starts its windup, through which he can't move or fire, though he
-- falls and slides on as he was; as it ends he's gone, out of play, and
-- once he's been gone its time he's there, free to move, his gun back in
-- hand a moment after. Riot gives the cost and the windup; the wiki the
-- range and the times (42-shrouded-step.md, section 2).
AbilityConfig.ShroudedStep = {
	-- From his arrival until the gun's back in hand.
	unequip = p(0.7, "community", STEP .. ": unequip 0.7 s (game files)"),
	-- How far along the crosshair the aim can end, and how far below where
	-- it ends it looks for a floor.
	range = p(15, "community", STEP .. ": max cast distance 15 m (game files)"),
	drop = p(20, "estimate", "Ours, as the Barrier Orb's: aimed into the sky at the range's end, down to the floor below"),
	-- How far over his eye the floor it puts him on can be: onto the maps'
	-- high crates (2.0 m), never onto a wall (5 m), even from a crate.
	above = p(1, "estimate", "Ours: the maps have no ceiling over their walls to keep him off them"),
	-- From the fire until he's gone, then gone this long until he's there.
	windup = p(0.7, "confirmed", P404 .. ": 'Pre teleport delay decreased 1s >>> 0.7s'"),
	away = p(0.5, "community", STEP .. ": arrival delay 0.5 s (its estimate, tested by hand)"),
	-- How much longer than his time gone, on the server's clock, he stays
	-- out of play when his moves haven't brought him there (they've stopped
	-- coming): then he's back in play where it took him.
	grace = p(1, "estimate", "Ours, as Run it Back's: so moves held back can't keep him out of play for long"),
}

-- Omen's From the Shadows (system 43): X, once its points are full, puts
-- its map in hand (WeaponConfig's shadowmap, in the fifth slot): the whole
-- map, with a cursor on it the mouse moves, and X again puts it away. Fire
-- with the cursor on a place he'd stand (ShadowSim) spends the points and
-- starts its windup, through which he's rooted where he stands, though he
-- can look round; as it ends he's there as a Shade, rooted there, until
-- its time's up and he's there for good, his gun drawn again. X while he's
-- a Shade, or an enemy's hit on it, sends him back where he cast it, the
-- points spent all the same (Patch 1.0: 'Omen still loses all of his ult
-- points if he cancels'). From the cast, the enemies' minimaps are covered
-- for its time. Riot gives the points spent and how far his arrival's
-- heard; the wiki the times and the rest (43-from-the-shadows.md, section
-- 2).
AbilityConfig.FromTheShadows = {
	-- From the fire until he's a Shade, then a Shade this long.
	windup = p(1.5, "community", SHADOWS .. ": '1.5-second windup' (game files)"),
	shade = p(2.5, "community", SHADOWS .. ": '2.5-second arrival at target location' (game files)"),
	-- How far his arrival's heard.
	heard = p(
		22.5,
		"confirmed",
		P049
			.. ": 'The attenuation radius of the arrival sound on Omen's From the Shadows has been reduced to 2250', read as centimetres ("
			.. SHADOWS
			.. ": 22.5 m)"
	),
	-- How high over the ground a floor can put him, and how far under it
	-- one's looked for: onto the maps' high crates (2.0 m), but not onto a
	-- wall (5 m) or the arena's block (3.0 m).
	top = p(2.5, "estimate", "Ours, metres: the maps have no ceiling over their walls to keep him off them"),
	depth = p(2, "estimate", "Ours, metres: the maps' ground is level"),
	-- How far round a place with no room for him there's looked for some.
	nudge = p(0.7, "estimate", "Ours, metres: about twice his width"),
	-- How far he sees as a Shade's time ends, from nothing as it starts.
	sight = p(
		10,
		"estimate",
		"Ours, metres: " .. SHADOWS .. " has it grow, 'the rate of restoration getting quicker towards the end', with no number"
	),
}

-- Sova's Recon Bolt (system 44), his signature: E puts his bow in hand
-- (WeaponConfig's bow, in the fifth slot), and once it's drawn, fire held
-- draws the bolt back, a bar filling each third of a second, three at the
-- most; alt fire adds a bounce, two at the most, and once more takes them
-- off again. Fire let go looses it from his eye along the crosshair, at
-- the speed and under the gravity its bars give it, and E while it's drawn
-- lets the draw go, the bow staying in hand. It goes off whatever it meets
-- while it has bounces left, keeping its speed, and sticks to the next
-- thing it meets (BoltSim). Stuck, it winds up and pulses, its pulses a
-- while apart: each reveals every enemy within its radius it has in sight,
-- their silhouettes seen by his side through walls for a moment, and on
-- their minimap. Enemies' bullets and knives take its health, and it
-- breaks at none; allies' do nothing (Patch 5.12: 'The following abilities
-- are now immune to allied damage.'). Riot gives the cooldown, the
-- bounces, the pulses and the health; the wiki the rest it gives
-- (44-recon-bolt.md, section 2).
AbilityConfig.ReconBolt = {
	-- From the loose until the gun's back in hand.
	unequip = p(0.7, "community", RECON .. ": unequip 0.7 s (game files)"),
	-- How long fire's held for each bar, and how many bars there are.
	bar = p(1 / 3, "community", RECON .. ": '0.333 seconds/1st bar filled for Class 3 Projectile' (its estimate)"),
	bars = p(3, "community", RECON .. ": 'reaching its longest trajectory once all three bars are filled'"),
	-- Its flight with no bar filled, then one, two and all three: this
	-- fast, falling at this share of the world's gravity.
	speed = {
		p(18, "community", RECON .. ": 'Immediately cast as a Class 2 Projectile'; " .. PROJECTILE .. ": class 2 at 1800, read as cm/s"),
		p(29, "community", RECON .. ": '0.333 seconds/1st bar filled for Class 3 Projectile'; " .. PROJECTILE .. ": class 3 at 2900"),
		p(41.25, "community", RECON .. ": '0.667 seconds/2nd bar filled for Class 4 Projectile'; " .. PROJECTILE .. ": class 4 at 4125"),
		p(41.25, "community", RECON .. ": '1.000 second/3rd bar filled for Class 5 Projectile'; " .. PROJECTILE .. ": class 5 at 4125"),
	},
	gravity = {
		p(0.3, "community", PROJECTILE .. ": class 2's gravity 0.3, read as a share of the world's"),
		p(0.45, "community", PROJECTILE .. ": class 3's gravity 0.45, read as a share of the world's"),
		p(0.3, "community", PROJECTILE .. ": class 4's gravity 0.3, read as a share of the world's"),
		p(0.15, "community", PROJECTILE .. ": class 5's gravity 0.15, read as a share of the world's"),
	},
	worldGravity = p(9.8, "estimate", "Ours, as Hot Hands': Unreal Engine's default, 980 cm/s^2; no source gives the reference's"),
	-- The most bounces alt fire adds, and what's kept of its speed off a
	-- surface.
	bounces = p(2, "confirmed", SOVA_PAGE .. ": 'ALT FIRE to add up to two bounces to this arrow.'"),
	bounce = p(1, "estimate", "Ours: as off a mirror, its speed kept; nothing public says what a bounce keeps"),
	-- Half the size of the box that flies, for what it meets, and the
	-- longest it flies before it's given up on, having met nothing.
	size = p(0.05, "estimate", "Ours, metres: small, as the wiki's history has its collision made smaller in v0.50"),
	airTime = p(10, "estimate", "Ours: past any shot across a map; nothing public says"),
	-- Stuck: its windup, then its pulses this far apart, each reaching this
	-- far and revealing whom it sees for a moment; and it's gone its time
	-- after the first.
	windup = p(0.667, "community", RECON .. ": windup 0.667 s (its estimate)"),
	pulses = p(2, "confirmed", P704 .. ": Recon Bolt (E) 'Total number of scans reduced 3>>>2'"),
	interval = p(1.6, "community", RECON .. ": a pulse every 1.6 s (game files)"),
	radius = p(30, "community", RECON .. ": pulse radius 30 m (game files)"),
	reveal = p(0.75, "community", RECON .. ": each reveal 0.75 s (measured from footage)"),
	duration = p(3.2, "community", SOVA .. ": Recon Bolt 3.2 s, read as from its first pulse to its end, its two 1.6 s apart"),
	-- Where it looks from, off the surface it's stuck to, metres.
	lift = p(0.1, "estimate", "Ours: so the surface it's stuck in isn't in its way"),
	-- Its health, and the shaft standing out of the surface, which bullets
	-- and knives hit: its length and width, metres.
	health = p(20, "confirmed", P512 .. ": 'Recon Bolt (E) Health increased 1 >>> 20'"),
	length = p(0.5, "estimate", "Ours: about an arrow's length out of what it's stuck in"),
	width = p(0.2, "estimate", "Ours: wider than the shaft, so it can be hit"),
}

-- Sova's Shock Bolt (system 45), a basic ability: Q puts his bow in hand
-- with a shock bolt (WeaponConfig's shockbow, in the fifth slot), drawn,
-- given bounces and loosed as the Recon Bolt is (AbilitySim.bow), and it
-- flies as the Recon Bolt does, the wiki having the two in the same
-- projectile classes (BoltSim). Where it would stick it bursts: everyone
-- it has in sight within its outer radius, from just off the surface it
-- met, takes its damage, the most within its inner radius and less further
-- out, in a straight line to the least at the outer (ShockSim). Its owner
-- and his side take it as his enemies do, and it doesn't slow. Riot gives
-- the most it does and its cost; the wiki and the guides the rest they
-- give (45-shock-bolt.md, section 2).
AbilityConfig.ShockBolt = {
	-- From the loose until the gun's back in hand.
	unequip = p(0.7, "estimate", "Ours, as the Recon Bolt's bow (" .. RECON .. ": unequip 0.7 s); nothing public found gives its own"),
	-- The most it does, within its inner radius, and the least, at its
	-- outer (metres); none past it.
	damage = p(75, "confirmed", P408 .. ": Shock Dart 'Max Damage decreased 90 >>> 75'"),
	least = p(1, "community", SOVA .. ": Shock Bolt's damage 1-75, the least at its outer radius and the most at its inner"),
	inner = p(1, "estimate", "Ours, metres: the wiki's damage runs out from an inner radius, with no number we could read"),
	outer = p(5, "community", DRIVEN .. ": 'it deals damage within a radius of 5 meters'; " .. SOVA_TRACKER .. ": 'Radius | 5m'"),
	-- Where it bursts from, off the surface it met, metres.
	lift = p(0.1, "estimate", "Ours, as the Recon Bolt's: so the surface it met isn't in the way"),
	-- What its owner and his side take of it, as shares of an enemy's.
	selfShare = p(1, "estimate", "Ours: all of it; nothing public we could read says less"),
	allyShare = p(1, "estimate", "Ours: all of it; nothing public we could read says less"),
}

-- Sova's Hunter's Fury (system 46), his ultimate: X, once its points are
-- full, spends them and puts its bow in hand (WeaponConfig's furybow, in
-- the fifth slot) with its three blasts, its time running from once it's
-- drawn. Fire, once it's drawn, charges a blast: through its windup he's
-- rooted where he is, his view turning only slowly, and as it ends the
-- blast goes from his eye along the crosshair, through everything, as far
-- as its range, and he's knocked back from the way he faces. Everyone but
-- his side within its radius of its line, ahead of him, takes its damage,
-- the same however far, and is revealed to his side for a moment, as the
-- Recon Bolt's pulses reveal (FurySim). The blasts come no closer
-- together than its fire rate (WeaponConfig). It's over, the gun back in
-- hand, once its time's up, its last blast's recovery is over, or
-- anything else is drawn, a weapon, an ability or the spike, and a blast
-- charging goes with it (Patch 3.0 fixed 'cancelling Sova's Hunter's Fury
-- while charging the shot' by 'equipping a weapon, ability, or Spike').
-- Riot gives the points; the wiki and the guides the rest they give
-- (46-hunters-fury.md, section 2).
AbilityConfig.HuntersFury = {
	-- From the cast until its bow's drawn, and its time from then.
	equip = p(
		0.5,
		"estimate",
		"Ours: the gap between the 6.5 s "
			.. BOOSTING
			.. " and "
			.. SOVA_ESPORTS
			.. " give it and "
			.. DRIVEN
			.. "'s 'Max duration: 6 seconds (Not including equip time)'"
	),
	duration = p(6, "community", SOVA .. ": Hunter's Fury 6 s; " .. DRIVEN .. ": 'Max duration: 6 seconds (Not including equip time)'"),
	-- A blast's windup, from fire until it goes, and how fast the view
	-- turns meanwhile, as a share of its usual.
	windup = p(1, "community", DRIVEN .. ": 'Windup time per charge: 1 second'"),
	turn = p(
		0.15,
		"estimate",
		"Ours: " .. SOVA_DIGNITAS .. ", once a shot's charging: 'you can only move your crosshair around ever so slightly'"
	),
	-- What a blast does to everyone it catches, the same however far.
	damage = p(80, "community", SOVA .. ": 80 a blast; " .. BOOSTING .. ": 'There is no damage falloff based on distance.'"),
	-- How far its line goes from his eye, and how far either side of it
	-- (metres), ahead of him alone (Patch 13.09: 'Fixed an issue where
	-- Sova's Hunter's Fury could affect players positioned behind him').
	range = p(
		66,
		"community",
		SOVA_ESPORTS .. ": 'Range: 66m'; " .. DRIVEN .. ": '66 meters in length'; " .. SOVA_TRACKER .. ": 'Range | 66m'"
	),
	radius = p(
		2,
		"community",
		DRIVEN .. ": 'a 2-meter radius' (EarlyGame's Sova guide's '2 by 66-meter range' may mean 2 m across, half as wide)"
	),
	-- How long each one it catches is revealed for.
	reveal = p(1, "community", SOVA .. ": a 1 s real-time Reveal (" .. SOVA_ESPORTS .. " and " .. SOVA_TRACKER .. ": 1.2 s)"),
	-- How far a blast knocks him back, and over how long (seconds), its
	-- speed falling to nothing.
	kick = p(1.5, "community", SOVA_SPIKE .. ": 'Self-knockback distance: 1.5 meters' (" .. DRIVEN .. " the same)"),
	kickTime = p(0.25, "estimate", "Ours: nothing public says how long the knockback takes"),
}

-- Sova's Owl Drone (system 47), a basic ability: C puts it in hand
-- (WeaponConfig's owl, in the fifth slot), and fire, once it's ready,
-- spends its charge and sends it out from his eye the way he faces. The
-- view's the drone's while it flies, and he stands where he was, his gun
-- away: for its deploy it flies on as it was sent, and then the keys fly
-- it, along the way the view faces, jump taking it up and crouch down
-- (Patch 2.05's keys for 'flying up and down'), never higher over the
-- floor below it than its ceiling (DroneSim). Fire, once the keys fly it,
-- shoots a dart along the crosshair, no sooner after the last than its
-- cooldown: whoever it strikes, but for his side, is revealed to his side
-- for a moment at each of its pings. Enemies' bullets and knives take its
-- health, and it breaks at none; allies' do nothing (Patch 5.12: 'The
-- following abilities are now immune to allied damage.'). It's over once
-- its time's up, C's pressed again or it breaks, and the gun's back in
-- hand its unequip after. Riot gives its time, health, pings and cost;
-- the wiki and the guides the rest they give (47-owl-drone.md, section
-- 2).
AbilityConfig.OwlDrone = {
	-- From the fire until the keys fly it, and its time, from the fire.
	deploy = p(0.25, "community", BOOSTING .. ": 'deploy time is 0.25 seconds'"),
	duration = p(7, "confirmed", P408 .. ": Owl Drone 'Duration reduced 10s >>> 7s'"),
	-- From its end until the gun's back in hand.
	unequip = p(0.7, "community", BOOSTING .. ": 'unequip time is 0.7 seconds'"),
	health = p(100, "confirmed", P408 .. ": Owl Drone 'Health reduced 125 >>> 100'"),
	-- How fast the keys fly it along the ground and up or down (metres a
	-- second), and how quickly it gets there (metres a second, each
	-- second).
	speed = p(
		5,
		"estimate",
		"Ours, under a run's 6.75 m/s: no source we could read gives it; "
			.. SOVA_DOTESPORTS
			.. ": it 'feels very slow and is clunky to control at first'"
	),
	climb = p(3, "estimate", "Ours: " .. AIMLAB .. ": 'Use your jump key bind to raise the drone's elevation', with no speed"),
	accel = p(20, "estimate", "Ours: up to its speed in a quarter of a second, from a stop"),
	-- The highest its middle goes over the floor below it, and how far
	-- under it a floor's looked for (metres): with none there, it sinks.
	ceiling = p(3, "estimate", "Ours: " .. BOOSTING .. " has its greatest height depend on the ground beneath it, with no number"),
	depth = p(20, "estimate", "Ours: deeper than any drop on the maps"),
	-- Its box, across and high (metres), which the world stops and
	-- bullets hit.
	width = p(0.4, "estimate", "Ours: about a hand's span across its wings"),
	height = p(0.25, "estimate", "Ours"),
	-- A dart: how long after one until the next, and how far it reaches
	-- (metres), at once along the crosshair.
	dartCooldown = p(
		5,
		"community",
		SOVA_SPIKE .. ": 'Dart cooldown: 5 seconds'; " .. BOOSTING .. ": 'The dart itself has a 5-second cooldown after firing.'"
	),
	dartRange = p(40, "estimate", "Ours: no source we could read says how far a dart goes, or how fast"),
	-- Whom a dart strikes: its pings, the first this long after it, the
	-- rest this far apart, each revealing them this long.
	pings = p(2, "confirmed", P408 .. ": Owl Drone 'Number of reveal pings reduced 3 >>> 2'"),
	firstPing = p(1.6, "confirmed", P408 .. ": 'Initial delay before first ping reveals increased 1.2s >>> 1.6s*'"),
	pingEvery = p(1.2, "confirmed", P408 .. ": '*Delay between the first and second ping remains 1.2s'"),
	reveal = p(
		0.6,
		"community",
		SOVA .. ": a 0.6 s real-time Reveal (" .. BOOSTING .. " the same; " .. SOVA_ESPORTS .. " and " .. SOVA_MOBALYTICS .. ": 0.8 s)"
	),
	-- How long its owner's '[Target Hit]' stays on screen.
	hitText = p(2, "confirmed", P408 .. ": '[Target Hit] confirmation text now remains on screen for 2s, previously 1s'"),
	-- How far its rotors are heard (metres).
	heard = p(15, "estimate", "Ours: " .. SOVA_TRACKER .. ": 'Makes noise because of engine rotors.', with no distance"),
}

-- How long after a throw the gun's back in hand, by the ability thrown (and
-- for Blaze, after its run's let go, for the Healing Orb, after its heal,
-- for the Barrier Orb, after its wall's raised, for the Resurrection,
-- after it's cast, for Shrouded Step, after it's fired: its windup, his
-- time gone and the draw, and for From the Shadows, after it's fired: its
-- windup and his time as a Shade, when the gun's drawn again, for the
-- Recon Bolt and the Shock Bolt, after it's loosed, and for the Owl Drone,
-- after its flight's over).
function AbilityConfig.unequip(id: string): number
	if id == "hothands" then
		return AbilityConfig.HotHands.unequip.value
	elseif id == "blaze" then
		return AbilityConfig.Blaze.unequip.value
	elseif id == "healingorb" then
		return AbilityConfig.HealingOrb.unequip.value
	elseif id == "sloworb" then
		return AbilityConfig.SlowOrb.unequip.value
	elseif id == "barrierorb" then
		return AbilityConfig.BarrierOrb.unequip.value
	elseif id == "resurrection" then
		return AbilityConfig.Resurrection.unequip.value
	elseif id == "darkcover" then
		return AbilityConfig.DarkCover.unequip.value
	elseif id == "paranoia" then
		return AbilityConfig.Paranoia.unequip.value
	elseif id == "shroudedstep" then
		local SS = AbilityConfig.ShroudedStep
		return SS.windup.value + SS.away.value + SS.unequip.value
	elseif id == "fromtheshadows" then
		local FS = AbilityConfig.FromTheShadows
		return FS.windup.value + FS.shade.value
	elseif id == "reconbolt" then
		return AbilityConfig.ReconBolt.unequip.value
	elseif id == "shockbolt" then
		return AbilityConfig.ShockBolt.unequip.value
	elseif id == "owldrone" then
		return AbilityConfig.OwlDrone.unequip.value
	end
	return AbilityConfig.Curveball.unequip.value
end

return AbilityConfig
