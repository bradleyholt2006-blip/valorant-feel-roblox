--!strict
-- The arena's rules (system 7): those of Skirmish, the reference's mode for
-- small fights, which its 2v2 queue plays. Same status convention as
-- MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be tuned (docs/research/07-arena.md)
--
-- What Skirmish leaves out needs no number here: it has 'Unlimited round
-- timer', 'No economy system' and 'No abilities by default' (Patch 11.07b).
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local ArenaConfig = {}

-- The model the server builds the arena in, Workspace's attribute that says
-- whether the arena is on, and each player's attribute for their side.
ArenaConfig.MODEL = "VFArena"
ArenaConfig.ON = "VFArenaOn"
ArenaConfig.SIDE = "VFArenaSide"
-- Workspace's attribute for what's played while it's on: "skirmish", here on
-- Skirmish A, or "spike", the rounds played for the spike (system 13) on
-- their own map, in the format Workspace's MatchConfig.FORMAT names. Either
-- way the arena's model carries the state of play.
ArenaConfig.MODE = "VFArenaMode"
-- Each player's attribute for where they stand in line, while both sides
-- are full: 1 for the next to play (system 21).
ArenaConfig.LINE = "VFInLine"

ArenaConfig.Rules = {
	winScore = p(10, "confirmed", "Patch 11.07b (Oct 2025), Skirmish in custom games: 'First to 10 wins'; Patch 12.03, the 2v2 queue: 'First to 10 rounds wins'"),
	-- Anyone over waits in line for a place (system 21).
	sideSize = p(2, "confirmed", "Patch 12.03: Skirmish is the 2v2 queue, two a side"),
	-- Each round starts with everyone held in their spawn behind a barrier,
	-- choosing weapons: Skirmish has 'Full weapon selection each round (no
	-- economy)' (Patch 12.03).
	firstBuyTime = p(15, "community", "Valorant Fandom wiki, Skirmish: the first round's buy phase is 15 seconds"),
	buyTime = p(3, "community", "Valorant Fandom wiki, Skirmish: later buy phases are 3 seconds"),
	roundOverTime = p(3, "estimate", "Seconds from a round's last kill to everyone spawning for the next"),
	matchOverTime = p(
		10,
		"estimate",
		"Seconds the match's result, the victory screen (system 21), shows before the next match starts at 0-0, as the spike rounds'"
	),
	respawnTime = p(
		3,
		"estimate",
		"Seconds before someone who dies with nobody to play against comes back (the same as the course's Players.RespawnTime)"
	),
}

return ArenaConfig
