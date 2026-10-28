--!strict
-- Team Deathmatch's rules (system 27): the reference's 5v5 Team Deathmatch,
-- on the spike rounds' maps, each side in a spawn room of its own, and its
-- pickups (system 28): the weapon spawners, the Recovery Orbs and the
-- Ultimate Orbs. Same status convention as ArenaConfig. The victory screen,
-- the vote for the next map and the times they take are the arena's
-- (ArenaConfig.Rules).
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
-- The guns weapon spawners have lent each player, by slot ("stinger,": a
-- primary, then a sidearm, "" for none in a slot), unset with none (system
-- 28). G destroys a lent gun in hand.
TeamDeathmatchConfig.LENT = "VFLent"
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

-- A weapon spawner's gun (system 28): a WeaponConfig id, with the rounds in
-- its magazine and in reserve.
export type SpawnerGun = { gun: string, ammo: number, reserve: number }

-- The guns each stage's spawners hold, one of the stage's at random on each.
-- The wiki's table has the Judge's magazine at 7, as it was until the
-- wiki's Judge page has it 'Reduced max mag size from 7 >>> 5' (v7.09): ours
-- holds 5, with the table's reserve.
TeamDeathmatchConfig.SpawnerGuns = {
	{
		{ gun = "shorty", ammo = 2, reserve = 6 },
		{ gun = "sheriff", ammo = 6, reserve = 12 },
		{ gun = "stinger", ammo = 20, reserve = 60 },
	},
	{
		{ gun = "bucky", ammo = 5, reserve = 5 },
		{ gun = "spectre", ammo = 30, reserve = 60 },
		{ gun = "bulldog", ammo = 24, reserve = 24 },
		{ gun = "marshal", ammo = 5, reserve = 5 },
	},
	{
		{ gun = "judge", ammo = 5, reserve = 7 },
		{ gun = "phantom", ammo = 30, reserve = 20 },
		{ gun = "vandal", ammo = 25, reserve = 25 },
		{ gun = "outlaw", ammo = 2, reserve = 6 },
	},
	{
		{ gun = "judge", ammo = 5, reserve = 7 },
		{ gun = "operator", ammo = 5, reserve = 3 },
		{ gun = "odin", ammo = 100, reserve = 0 },
	},
} :: { { SpawnerGun } }
TeamDeathmatchConfig.SpawnerGunsStatus = "community" :: Status
TeamDeathmatchConfig.SpawnerGunsSource = WIKI
	.. ": 'The guns available at these spawners change depending on the current stage', with each gun's rounds ('most of"
	.. " these guns have standard ammo (with the exception of Odin), but lesser reserves than usual'). That each has one at"
	.. " random is ours, from "
	.. TDM
	.. ": 'Weapons from the Weapon Spawner can potentially be different each match.' Patch 8.01: 'Fixed a bug where, if the"
	.. " Outlaw was picked up from a weapon spawner, it had no reserve ammunition'"

-- Where a spike map has its pickups (system 28), in the map's own metres on
-- its floor: its weapon spawners, its Recovery Orbs and its Ultimate Orbs.
export type Pickups = { spawners: { vector }, recovery: { vector }, ultimate: { vector } }

local function at(x: number, z: number): vector
	return vector.create(x, 0, z)
end

-- Out on the floor, clear of cover and walls by a metre, out of the spawn
-- rooms and their doors, and each as quick a run from one side's spawn as
-- the other's, or the map's set of them evened out between the sides (the
-- offline tests check).
TeamDeathmatchConfig.Pickups = {
	outpost = {
		spawners = { at(-28, 5), at(28, 5), at(-4.5, 3), at(4.5, 3) },
		recovery = { at(-25, 1), at(25, 1) },
		ultimate = { at(-27.5, 10), at(27.5, 10) },
	},
	quarry = {
		spawners = { at(-39, -7), at(-13, -5), at(9, -5), at(37, -11) },
		recovery = { at(-11, -11), at(7, -11) },
		ultimate = { at(-43, -3), at(37, -5) },
	},
	foundry = {
		spawners = { at(-43, -5), at(-9, -7), at(9, -7), at(31, -7) },
		recovery = { at(-23, -12), at(17, -7) },
		ultimate = { at(-43, 1), at(35, -3) },
	},
	wharf = {
		spawners = { at(-32, -2), at(-10, 2), at(10, 2), at(35, 6) },
		recovery = { at(-19, -7), at(0, 0) },
		ultimate = { at(-30.5, 3), at(31, 10) },
	},
} :: { [string]: Pickups }
TeamDeathmatchConfig.PickupsStatus = "estimate" :: Status
TeamDeathmatchConfig.PickupsSource = "Ours, for our maps: "
	.. TDM
	.. " has 'Weapon Spawners in fixed locations' and Recovery Orbs and Ultimate Orbs 'in certain sections of each map',"
	.. " and "
	.. WIKI
	.. " that 'Each map contains several orbs'; neither says how many, or where on maps of our own"

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
	-- The pickups (system 28), up from each match's start to its end.
	spawnerWait = p(
		30,
		"estimate",
		"Seconds a weapon spawner stands empty once its gun is taken, before it has another of the stage's (ours: not"
			.. " published, so the Recovery Orbs' respawn)"
	),
	recoveryTime = p(6, "confirmed", TDM .. ": 'Recovery Orbs grant a buff that restores Health and Shield over 6s.'"),
	recoveryShare = p(
		1,
		"estimate",
		"How much of the most health and shield a player has the buff restores over its time, at an even rate (ours: not"
			.. " published). "
			.. TDM
			.. ": 'The maximum Shield restored is determined by your selected loadout'; "
			.. WIKI
			.. ": '(not including the regeneration pool from Regen Shield)'"
	),
	recoveryWait = p(
		30,
		"confirmed",
		TDM .. ": the Recovery Orbs' 'Respawn duration: 30s'; " .. WIKI .. ": 'Each Recovery Orb respawns every 30 seconds'"
	),
	zoneRadius = p(
		3,
		"estimate",
		"Metres round a Recovery Orb taken that its zone reaches (ours: not published; "
			.. WIKI
			.. ": orbs leave 'a zone that allies can enter to also receive its effects')"
	),
	zoneTime = p(6, "estimate", "Seconds a Recovery Orb's zone lasts once the orb's taken (ours, its buff's: not published)"),
	ultimateFirst = p(
		30,
		"estimate",
		"Seconds into a match the Ultimate Orbs first come up (ours: not published; "
			.. WIKI
			.. ": 'All Ultimate Orbs spawn onto the map together periodically')"
	),
	ultimateEvery = p(60, "estimate", "Seconds between the Ultimate Orbs coming up again, all together (ours: not published)"),
	orbRange = p(
		1.0,
		"estimate",
		"Horizontal distance from the feet that counts as running over an orb (ours, as deathmatch's health packs; "
			.. WIKI
			.. ": players 'run over' them)"
	),
	orbHeight = p(1.0, "estimate", "How far above or below the feet an orb can be and still be run over (ours)"),
}

return TeamDeathmatchConfig
