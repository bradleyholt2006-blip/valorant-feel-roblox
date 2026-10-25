--!strict
-- Team Deathmatch's rules (system 27): the reference's 5v5 Team Deathmatch,
-- on the spike rounds' maps, each side in a spawn room of its own. Same
-- status convention as ArenaConfig. The victory screen, the vote for the
-- next map and the times they take are the arena's (ArenaConfig.Rules).
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local TDM = "Riot, 'VALORANT Team Deathmatch 101'"
local WIKI = "VALORANT Wiki (Weird Gloop), 'Team Deathmatch'"

local TeamDeathmatchConfig = {}

-- A loadout a stage has to pick from: its gun (a WeaponConfig id), and the
-- shield that comes with it (a WeaponConfig.Shields id, "" for none).
export type Loadout = { gun: string, shield: string }

-- Each player's attributes: the loadout they've picked for each stage, by
-- its number in the stage's list ("1,2,1,1"), the stage the guns they hold
-- are for, and when (the server's time) their life started or the match
-- did, from which their spawn room burns them after its stay time.
TeamDeathmatchConfig.PICKS = "VFStagePicks"
TeamDeathmatchConfig.KIT_STAGE = "VFKitStage"
TeamDeathmatchConfig.ROOM_SINCE = "VFRoomSince"
-- What a spawn room's burn is to the kill feed: the weapon of its damage.
TeamDeathmatchConfig.BURN = "spawnroom"

-- The stages' loadouts, as the loadout menu lists them; the first of each is
-- carried until another is picked. Each stage's gun is carried with the
-- first stage's, a sidearm, unless it's a sidearm itself.
TeamDeathmatchConfig.Stages = {
	{
		{ gun = "classic", shield = "regen" },
		{ gun = "frenzy", shield = "" },
		{ gun = "ghost", shield = "" },
		{ gun = "bandit", shield = "" },
	},
	{
		{ gun = "sheriff", shield = "light" },
		{ gun = "stinger", shield = "heavy" },
		{ gun = "ares", shield = "light" },
	},
	{
		{ gun = "spectre", shield = "heavy" },
		{ gun = "ares", shield = "heavy" },
		{ gun = "bulldog", shield = "heavy" },
		{ gun = "guardian", shield = "light" },
	},
	{
		{ gun = "phantom", shield = "heavy" },
		{ gun = "vandal", shield = "heavy" },
	},
} :: { { Loadout } }
TeamDeathmatchConfig.StagesStatus = "community" :: Status
TeamDeathmatchConfig.StagesSource = WIKI
	.. "'s loadouts, and that players 'carry both their primary weapon of choice for that stage as well as their sidearm of"
	.. " choice for Stage 1'. Patch 8.0: 'Stage 2 - Sheriff Loadout' 'Heavy Shield >>> Light Shield'; Patch 9.11: 'When using"
	.. " the Classic in Stage 1 you will now have the Regen Shield instead of Light Armor'"

TeamDeathmatchConfig.Rules = {
	-- Anyone over waits in line for a place (system 21).
	sideSize = p(5, "confirmed", TDM .. ": 'the newest 5v5 VALORANT game mode'"),
	killTarget = p(100, "confirmed", TDM .. ": 'Plain and simple: the team that gets 100 kills first wins.'"),
	timeLimit = p(
		570,
		"confirmed",
		TDM .. ": 'Match duration: 9m 30s, split into four stages'; 'Score tied when the match ends? The match will end in a draw.'"
	),
	stageTime = p(75, "community", WIKI .. ": the first three stages last 75 s each, and the fourth the rest, 345 s"),
	preGame = p(20, "community", WIKI .. ": 'Team Deathmatch has a 20-second pre-game phase'"),
	swapDelay = p(
		5,
		"estimate",
		"Seconds into a stage its loadout is handed over, outside the spawn room (ours; "
			.. WIKI
			.. ": players 'will be forced to equip it after a short duration')"
	),
	respawnTime = p(1.5, "confirmed", TDM .. ": 'Respawn every 1.5 seconds.'"),
	protectTime = p(
		15,
		"confirmed",
		TDM
			.. ": 'When you respawn, you gain a buff that protects you from damage and abilities for 15 seconds.' That leaving the"
			.. " spawn room ends it is "
			.. WIKI
			.. "'s 'Whilst remaining in the spawn room, they will be kept invulnerable for 15 seconds'; that firing does is ours,"
			.. " as gun game's"
	),
	stayTime = p(15, "confirmed", TDM .. ": 'After 15 seconds, you'll start to take damage from staying in spawn, so move quickly!'"),
	burnDamage = p(
		15,
		"estimate",
		"Damage each burn does to someone staying in their spawn room, or in the other side's at all (ours; "
			.. TDM
			.. ": 'the safety of your team's Spawn Room')"
	),
	burnInterval = p(0.5, "estimate", "Seconds between burns (ours): the tenth kills from full health in Heavy Armor, 4.5 s in"),
}

return TeamDeathmatchConfig
