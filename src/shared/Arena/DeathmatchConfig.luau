--!strict
-- Deathmatch's rules (system 26): the reference's FFA Deathmatch, everyone
-- for themselves on the spike rounds' maps. Same status convention as
-- ArenaConfig. The victory screen, the vote for the next map and the times
-- they take are the arena's (ArenaConfig.Rules).
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local SUPPORT = "Riot Support, 'VALORANT Game Mode - FFA Deathmatch' (31 October 2024)"

local DeathmatchConfig = {}

-- What the buy menu sells in deathmatch, by Shop's kinds of item: the guns,
-- all free ('Infinite money!' and 'The ability to swap weapons at will',
-- the support page), as Heavy Armor comes with every life ('heavy armor is
-- given to you automatically', Patch 1.05) and there are no abilities.
DeathmatchConfig.FOR_SALE = { weapon = true } :: { [string]: boolean }
-- The shield every life wears.
DeathmatchConfig.SHIELD = "heavy"
-- Each player's attribute for their place in the match: 1 for whoever
-- leads.
DeathmatchConfig.PLACE = "VFPlace"

DeathmatchConfig.Rules = {
	-- Anyone over waits in line for a place (system 21).
	players = p(
		14,
		"confirmed",
		SUPPORT
			.. ": 'You can hop into an FFA Deathmatch queued with up to 14 players'; Patch 1.10: 'Increased player count 10 >>> 14"
			.. " players'"
	),
	killTarget = p(
		40,
		"confirmed",
		SUPPORT
			.. ": 'Win by being the first to 40 kills or by having the most kills in 9 minutes'; Patch 1.10: 'first to 40 kills"
			.. " (was 30)'"
	),
	timeLimit = p(
		540,
		"confirmed",
		SUPPORT
			.. ", as above, and Patch 1.10: 'time limit upped to 9 minutes (was 6)'. Another line of the support page still says"
			.. " 'a max of 6 minutes', Patch 1.05's limit"
	),
	respawnTime = p(1.5, "confirmed", "Patch 4.03, Deathmatch: 'Respawn Time Reduced: 3s >>> 1.5s'"),
	packTime = p(
		10,
		"confirmed",
		SUPPORT .. ": 'Every death drops a health pack that will last 10 seconds and heal for full health and full armor'"
	),
	packRange = p(1.0, "estimate", "Horizontal distance from the feet that counts as walking over a health pack (ours)"),
	packHeight = p(1.0, "estimate", "How far above or below the feet a health pack can be and still be walked over (ours)"),
	heavyReload = p(
		30,
		"confirmed",
		"Patch 1.10: on every kill 'an automatic, immediate full reload of their active weapon', and '(Ares & Odin get 30 bullets"
			.. " back)'"
	),
	-- Where each life starts: anywhere on the map, as the reference's
	-- respawns do, at 'ideal locations that are free of enemies but close to
	-- the action' (the support page).
	spotSpacing = p(3, "estimate", "Metres between the places a life can start, across each map's floor (ours)"),
	spotClearance = p(0.8, "estimate", "Metres each place keeps from walls and cover: the player's width and some room (ours)"),
	safeDistance = p(10, "estimate", "Metres: no living enemy nearer a new life than this, 'free of enemies' (ours)"),
	actionDistance = p(30, "estimate", "Metres: a new life with a living enemy this near is 'close to the action', and preferred (ours)"),
	deathDistance = p(
		20,
		"estimate",
		"Metres from where they died beyond which a new life is preferred (ours; Patch 4.03: 'Spawning logic will now favor respawn"
			.. " locations farther away from where you are defeated')"
	),
	openView = p(
		6,
		"estimate",
		"Metres of open floor ahead that a new life faces, as near the way to the nearest enemy as it goes (ours; Patch 4.03 placed"
			.. " spawns 'to increase the likelihood that you will be facing' the players in an encounter)"
	),
}

return DeathmatchConfig
