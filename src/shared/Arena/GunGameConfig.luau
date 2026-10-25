--!strict
-- Gun game's rules (system 23): Counter-Strike's Arms Race, the gun game
-- Counter Blox's players know, played with the reference's guns in the
-- arena's hall, with the reference's own take on it, Escalation, for its
-- numbers. Same status convention as ArenaConfig. The victory screen, the
-- vote for the next map and the times they take are the arena's
-- (ArenaConfig.Rules).
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local ESCALATION = "Riot, 'New VALORANT mode: Escalation'"
local TDM = "Riot, 'VALORANT Team Deathmatch 101'"

local GunGameConfig = {}

-- Each player's attribute for their level (1 for the ladder's first gun),
-- and for whether their spawn protection is on.
GunGameConfig.LEVEL = "VFGunLevel"
GunGameConfig.PROTECTED = "VFProtected"

-- The ladder: a tier a level, and for each match one gun from each tier at
-- random, never the same gun twice, so the first two levels are the Vandal
-- and the Phantom in either order. The last level is the knife.
GunGameConfig.Tiers = {
	{ "vandal", "phantom" },
	{ "vandal", "phantom" },
	{ "bulldog", "guardian", "warden" },
	{ "marshal", "outlaw", "operator" },
	{ "ares", "odin" },
	{ "stinger", "spectre" },
	{ "sheriff" },
	{ "ghost", "bandit" },
	{ "classic", "frenzy" },
	{ "bucky", "judge" },
	{ "shorty" },
	{ "knife" },
}
GunGameConfig.TiersStatus = "estimate" :: Status
GunGameConfig.TiersSource = "Ours, from both: Escalation has 12 levels, 'Level 2: Always Vandal or Phantom' and a knife"
	.. " among its last level's ("
	.. ESCALATION
	.. "); after those, the order of Arms Race's kinds of gun since 21 September 2021, rifles, a machine gun, SMGs,"
	.. " a heavy pistol, pistols and shotguns, then the knife, each a gun of that kind at random (Counter-Strike Wiki)"

GunGameConfig.Rules = {
	killsPerLevel = p(
		1,
		"estimate",
		"Kills a level takes. Ours: one, as gun game's own rules have it (Wikipedia: 'Defeating an enemy causes the player's"
			.. " gun to increase in tier'). Arms Race takes 2 (mp_ggprogressive_random_weapon_kills_needed, Valve Developer"
			.. " Community), and Escalation 'at least 1 kill' of each player"
	),
	-- Anyone over waits in line for a place (system 21).
	sideSize = p(
		4,
		"estimate",
		"Players a side. Arms Race is 6 a side (Counter-Strike Wiki) and Escalation a '5v5 game mode' ("
			.. ESCALATION
			.. "); the arena's hall is Skirmish's, made for two a side"
	),
	timeLimit = p(600, "confirmed", ESCALATION .. ": 'First team to 12, or furthest along in 10 minutes, wins'"),
	respawnTime = p(1.5, "confirmed", TDM .. ": 'Respawn every 1.5 seconds'; Escalation's are 'Fast respawns'"),
	protectTime = p(
		5,
		"confirmed",
		ESCALATION
			.. ": 'Fast respawns (invulnerable for first 5 seconds)'. Firing ends it sooner (ours), as Arms Race's ends once the"
			.. " player moves (Counter-Strike Wiki)"
	),
}

return GunGameConfig
