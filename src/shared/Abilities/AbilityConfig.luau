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
-- plant, defuse and ultimate orb.
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
	description: string, -- for the buy menu and the HUD, in our words
}

export type Agent = {
	id: string,
	name: string,
	abilities: { string }, -- ids, by slot: C, Q, E, X
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

local P704 = "Patch 7.04"
local P300 = "Patch 3.0"
local P408 = "Patch 4.08"
local WIKI = "VALORANT Wiki, Jett"

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
		description = "Throwing knives that come back with each kill.",
	},
} :: { [string]: AbilityDef }

AbilityConfig.Agents = {
	jett = { id = "jett", name = "Jett", abilities = { "cloudburst", "updraft", "tailwind", "bladestorm" } },
} :: { [string]: Agent }

-- Everyone plays this agent until there's an agent select.
AbilityConfig.DEFAULT_AGENT = "jett"

-- The agents' ids by index, and each id's index, for the wire.
AbilityConfig.AgentIds = { "jett" }
AbilityConfig.AgentIndex = { jett = 1 } :: { [string]: number }

-- The ability an agent has in a slot, if any.
function AbilityConfig.abilityOf(agent: string, slot: number): AbilityDef?
	local a = AbilityConfig.Agents[agent]
	local id = a and a.abilities[slot]
	return if id then AbilityConfig.Defs[id] else nil
end

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

return AbilityConfig
