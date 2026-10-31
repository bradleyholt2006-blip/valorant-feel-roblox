--!strict
-- Bots' numbers (system 60): how fast each skill notices an enemy, turns
-- onto them, settles its aim and opens fire, what it looks at, how long it
-- remembers, how many fill each mode, and what they're called.
--
-- The four skills are the Counter-Strike bot's, and what each is like is
-- its slides': Easy has 'Poor reaction times' and 'Terrible aim', Normal
-- 'Medium reaction times' and 'Medium aim', Hard 'Good reaction times'
-- and 'Good aim', Expert 'Very good (but still human) reaction times' and
-- 'Excellent aim', with a substantial added delay before Easy opens fire,
-- a minor one for Normal and none above (Booth, "The Official
-- Counter-Strike Bot", GDC 2004). Valve publishes no numbers for them, and
-- CS:GO's bot settings are named on the Valve Developer Community without
-- their values, so each number here is ours, put against what people do:
--   * noticing an enemy is a recognition reaction: 'simple reaction times
--     averaged 0.220sec: recognition reaction times averaged 0.384sec'
--     (Laming, 1968, in Kosinski's review; BioNumbers 110799). Normal
--     notices in that average person's time, Expert in a simple
--     reaction's, the fastest a person is
--   * turning onto them is a pointing movement, which takes longer the
--     further and the smaller the target, by Fitts's law, MT = a + b ID,
--     ID = log2(D / W + 1): MacKenzie, Sellen and Buxton (CHI 1991) fit
--     'MT = -107 + 223 ID' (ms) for the mouse. In first-person targeting
--     at a 103 degree field of view, players found and clicked a target 7
--     to 25 degrees off and 0.57 to 9.15 degrees across (ID 0.83 to 5.50)
--     in 'typically 0.4 - 0.8 s', a reaction included (Boudaoud, Spjut and
--     Kim, IEEE Conference on Games 2022). A skill's a and b are the
--     intercept and slope of its own law: Normal's turns take what theirs
--     did less a simple reaction, Easy's nearer the office mouse's
--   * once on the target, the aim wanders round it, an offset made anew
--     every so often, 'Periodically generate new random Aim Offset based
--     on bot's "skill"' (Booth), wide after the turn and settling as the
--     bot focuses in. The bot fires where it means to aim, not knowing the
--     wander, so the wander is what misses
--
-- The default is Normal: good enough to punish a player who walks into
-- its angle, slow enough that one who checks their corners wins.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

-- A number from 0 up to 1, at random: a Random's NextNumber on the server,
-- seeded dice in a test.
export type Dice = () -> number

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

export type Skill = {
	name: string,
	reaction: Param, -- seconds from an enemy coming into view, in the middle of it, to noticing them
	attackDelay: Param, -- seconds more before the first shot
	fittsA: Param, -- seconds: the turn's law's intercept
	fittsB: Param, -- seconds a bit: its slope
	trackError: Param, -- degrees: how far the aim wanders round the target once settled (standard deviation)
	turnError: Param, -- times trackError, just after the turn
	focus: Param, -- seconds the wander takes to settle, as a time constant
	lag: Param, -- seconds before a change in how a target moves shows in the aim
	recoil: Param, -- the share of the gun's climb pulled back down
	head: Param, -- the chance, each fight, of aiming at the head rather than the chest
	dodge: boolean, -- steps aside between bursts, and stops again to fire
	-- The chance a moment that calls for one of its agent's abilities gets
	-- it (system 66), rolled once for each moment.
	utility: Param,
}

local BotConfig = {}

local BOOTH = "Booth, 'The Official Counter-Strike Bot' (GDC 2004)"
local LAMING = "Laming (1968) in Kosinski's review (BioNumbers 110799)"
local FITTS = "MacKenzie, Sellen and Buxton (CHI 1991): 'MT = -107 + 223 ID' ms for the mouse"
local AIMING = "Boudaoud, Spjut and Kim (IEEE CoG 2022): 'typically 0.4 - 0.8 s' to find and click a target at ID 0.83 to 5.50"

BotConfig.Skills = {
	easy = {
		name = "Easy",
		reaction = p(0.55, "estimate", BOOTH .. ": Easy has 'Poor reaction times'; slower than " .. LAMING .. "'s 0.384 s"),
		attackDelay = p(0.25, "estimate", BOOTH .. ": a substantial added delay before Easy opens fire"),
		fittsA = p(0.12, "estimate", FITTS .. "; ours, slower than Normal's"),
		fittsB = p(0.18, "estimate", FITTS .. "; nearer the office mouse's 0.223 s a bit than Normal's"),
		trackError = p(1.3, "estimate", BOOTH .. ": Easy's 'Terrible aim'; ours, about a chest's width at 20 m"),
		turnError = p(3, "estimate", "Ours: the turn lands wide and settles"),
		focus = p(0.6, "estimate", "Ours"),
		lag = p(0.25, "estimate", "Ours: a slow reaction to a strafe the other way"),
		recoil = p(0, "estimate", "Ours: no pull-down"),
		head = p(0, "estimate", "Ours: the chest, always"),
		dodge = false,
		utility = p(0.4, "estimate", "Ours: " .. BOOTH .. "'s Easy bot has 'Poor weapon proficiency'"),
	},
	normal = {
		name = "Normal",
		reaction = p(0.4, "estimate", BOOTH .. ": Normal has 'Medium reaction times'; about " .. LAMING .. "'s 0.384 s"),
		attackDelay = p(0.1, "estimate", BOOTH .. ": a minor added delay before Normal opens fire"),
		fittsA = p(0.08, "estimate", AIMING .. ", less a simple reaction (0.22 s): 0.16 to 0.63 s"),
		fittsB = p(0.1, "estimate", AIMING .. ", less a simple reaction (0.22 s): 0.16 to 0.63 s"),
		trackError = p(0.8, "estimate", BOOTH .. ": Normal's 'Medium aim'; ours, about a head's width at 17 m"),
		turnError = p(2.5, "estimate", "Ours"),
		focus = p(0.45, "estimate", "Ours"),
		lag = p(0.2, "estimate", "Ours: about a reaction to a strafe the other way"),
		recoil = p(0.3, "estimate", "Ours"),
		head = p(0.3, "estimate", "Ours: the head now and then"),
		dodge = false,
		utility = p(0.7, "estimate", "Ours: " .. BOOTH .. "'s Normal bot has a 'Mix of weapon proficiencies'"),
	},
	hard = {
		name = "Hard",
		reaction = p(0.3, "estimate", BOOTH .. ": Hard has 'Good reaction times'"),
		attackDelay = p(0, "estimate", BOOTH .. ": no added delay before Hard opens fire"),
		fittsA = p(0.06, "estimate", "Ours: faster than Normal's"),
		fittsB = p(0.08, "estimate", "Ours: faster than Normal's"),
		trackError = p(0.5, "estimate", BOOTH .. ": Hard's 'Good aim'"),
		turnError = p(2, "estimate", "Ours"),
		focus = p(0.3, "estimate", "Ours"),
		lag = p(0.15, "estimate", "Ours"),
		recoil = p(0.6, "estimate", "Ours"),
		head = p(0.7, "estimate", "Ours"),
		dodge = true,
		utility = p(0.9, "estimate", "Ours: " .. BOOTH .. "'s Hard bot has 'Complete weapon proficiency'"),
	},
	expert = {
		name = "Expert",
		reaction = p(
			0.24,
			"estimate",
			BOOTH .. ": Expert's 'Very good (but still human) reaction times'; about " .. LAMING .. "'s 0.220 s"
		),
		attackDelay = p(0, "estimate", BOOTH .. ": no added delay before Expert opens fire"),
		fittsA = p(0.05, "estimate", "Ours: faster than Hard's"),
		fittsB = p(0.065, "estimate", "Ours: faster than Hard's"),
		trackError = p(0.3, "estimate", BOOTH .. ": Expert's 'Excellent aim'"),
		turnError = p(1.8, "estimate", "Ours"),
		focus = p(0.2, "estimate", "Ours"),
		lag = p(0.12, "estimate", "Ours"),
		recoil = p(0.85, "estimate", "Ours"),
		head = p(0.9, "estimate", "Ours"),
		dodge = true,
		utility = p(1, "estimate", "Ours: every moment"),
	},
} :: { [string]: Skill }

BotConfig.SKILLS = { "easy", "normal", "hard", "expert" }
BotConfig.DEFAULT_SKILL = "normal"

-- Workspace's attributes: VFBots false keeps bots out of everything, and
-- VFBotSkill names the skill they play at (a key of Skills).
BotConfig.ON = "VFBots"
BotConfig.SKILL = "VFBotSkill"

BotConfig.Params = {
	-- What a bot sees: only what's in its field of view, as the
	-- Counter-Strike bot does (Booth).
	fov = p(
		103,
		"community",
		"Degrees across: the game's fixed horizontal field of view (CameraController), the one Boudaoud, Spjut and Kim's first-person targeting study renders at (IEEE CoG 2022)"
	),
	-- Someone at the edge of view takes longer to notice than someone in the
	-- middle of it.
	edgeReaction = p(1.6, "estimate", "Times the reaction, for someone at the edge of view; in between, in proportion"),
	-- How much each notice varies, as a person's reactions do.
	reactionSpread = p(0.15, "estimate", "Standard deviation, as a share of the reaction"),
	-- What's remembered of an enemy once out of sight: CS:GO's Deathmatch
	-- tree lets its ShortTermAttackMemory go after 0.7 s, its
	-- LongTermMemory after 10 s and its ShortTermInvestigateMemory after
	-- 3 s ('time = 0.7', 'time = 10' and 'time = 3', the Valve Developer
	-- Community's page on bot behaviour trees). The page doesn't say what
	-- each holds; here, as their names have it, they're the enemy it
	-- fights, any enemy, and where one was, which it watches.
	attackMemory = p(
		0.7,
		"confirmed",
		"Valve Developer Community, Mp_bot_ai_bt: the Deathmatch tree's ShortTermAttackMemory, 'time = 0.7'"
	),
	memory = p(10, "confirmed", "Valve Developer Community, Mp_bot_ai_bt: the Deathmatch tree's LongTermMemory, 'time = 10'"),
	investigate = p(
		3,
		"confirmed",
		"Valve Developer Community, Mp_bot_ai_bt: the Deathmatch tree's ShortTermInvestigateMemory, 'time = 3'"
	),
	-- How often a bot looks for enemies: as often as the fog of war's looks
	-- (FogOfWar).
	lookEvery = p(0.05, "estimate", "Seconds between looks"),
	-- How often the aim's wander is made anew.
	wanderEvery = p(0.3, "estimate", "Seconds"),
	-- The range bands a rifle is fired in: tapped past `tapRange`, in bursts
	-- down to `sprayRange`, sprayed inside it, as the Counter-Strike bot
	-- bursts a rifle at long range (Booth).
	tapRange = p(22, "estimate", "Metres"),
	sprayRange = p(10, "estimate", "Metres"),
	burst = p(3, "estimate", "Rounds in a burst"),
	-- The longest a spray runs before a pause.
	spray = p(8, "estimate", "Rounds"),
	-- How far the view may be from where the bot means to aim, as a share
	-- of the target's half width, and the shot still taken.
	tolerance = p(1.2, "estimate", "Times the target's half width"),
	-- How fast a bot turns its view when not fighting, and how quickly it
	-- eases onto where it's looking.
	lookSpeed = p(360, "estimate", "Degrees a second at the most"),
	lookEase = p(0.12, "estimate", "Seconds, a time constant"),
	-- How long a glance at a spot an enemy might be in lasts, as a bot
	-- checks its corners.
	glance = p(0.6, "estimate", "Seconds"),
	-- Glances go to spots at most this far, and which are in sight is
	-- looked at this often.
	checkRange = p(35, "estimate", "Metres"),
	glanceEvery = p(0.25, "estimate", "Seconds"),
	-- How often each side's plan is gone over (BotTeam.think).
	think = p(0.5, "estimate", "Seconds"),
	-- A flash's blind hides everything from a bot while a player's screen
	-- would be at least this white with it (FlareSim.whiteAt): past the
	-- white, a flashed player starts to see again as it fades (system 65).
	blindFrom = p(0.5, "estimate", "White, 0 to 1"),
}

-- When and how a bot uses its agent's abilities (system 66, BotUtility).
BotConfig.Utility = {
	-- The least time between one bot's casts, so two follow one another
	-- as a player's hands can; and how long before a cast whose throw wasn't
	-- found is tried again, from wherever it's got to.
	between = p(1.2, "estimate", "Seconds"),
	retry = p(1.5, "estimate", "Seconds"),
	-- The longest a cast may take from its key to its throw before it's
	-- given up (its equip, the aim and the throw), and Hunter's Fury's.
	longest = p(3, "estimate", "Seconds"),
	furyLongest = p(7, "estimate", "Seconds: its equip and three blasts' windups"),
	-- How long a Healing Orb in hand is tried before it's put away.
	healTry = p(1, "estimate", "Seconds"),
	-- Hurt and out of a fight: the health under which it heals, an ally's
	-- under which it heals them, how near they are, and how long since an
	-- enemy was in its sight or hurt it.
	healFrom = p(60, "estimate", "Health, of 100"),
	allyFrom = p(50, "estimate", "Health, of 100"),
	allyReach = p(15, "estimate", "Metres"),
	quiet = p(3, "estimate", "Seconds"),
	-- Holding a way in: attackers seen this near it this recently call for
	-- a stall.
	stallNear = p(14, "estimate", "Metres from the way in"),
	stallRecent = p(2.5, "estimate", "Seconds"),
	-- Going in: how near the way in a flash, Paranoia and Blade Storm go.
	flashNear = p(9, "estimate", "Metres: the flare pops about 6 m from where it's thrown (AbilityConfig.Curveball)"),
	paranoiaNear = p(20, "estimate", "Metres: inside its 25 m travel (AbilityConfig.Paranoia)"),
	stormNear = p(12, "estimate", "Metres"),
	-- The Recon Bolt over the way in, not yet cast as the push goes (it
	-- hadn't got to where its side gathers, or fetched the spike): cast on
	-- the way, while it's this far or further from the way in, tried again
	-- this soon, and only where it sees its way in.
	reconFar = p(
		2.5,
		"estimate",
		"Metres from the way in: just short of it, as on some ways a throw's only found from 7 m in (Outpost's A, the second way, 6.5 m): 4 m to walk, more than a think's at a run"
	),
	reconRetry = p(
		0.25,
		"estimate",
		"Seconds: under a think (Params.think), so each on the way tries again; only in sight of the way in, as a try that finds no throw costs about a millisecond"
	),
	-- Holding: the Recon Bolt toward where attackers gather, this long into
	-- the round, as defenders look for them early.
	reconFrom = p(8, "estimate", "Seconds after the round goes live"),
	reconTo = p(30, "estimate", "Seconds after the round goes live"),
	-- Hunter's Fury on sightings this recent.
	furyRecent = p(2, "estimate", "Seconds"),
	-- How far from where it's meant to go a throw may land and still be
	-- thrown: a smoke, a cloud, a molly or a slow, a Shock Bolt, a wall.
	smokeMiss = p(3, "estimate", "Metres, across"),
	cloudMiss = p(4, "estimate", "Metres"),
	throwMiss = p(3, "estimate", "Metres"),
	wallMiss = p(3, "estimate", "Metres"),
	-- A flash worth throwing blinds those holding the way in at least this
	-- much in all (FlareSim.strength, summed), and a teammate no more than
	-- this.
	flashWorth = p(0.6, "estimate", "Of the longest blind, summed over those holding"),
	flashMate = p(0.2, "estimate", "Of the longest blind"),
	-- How far a molly or a Shock Bolt keeps from teammates, past its radius.
	clear = p(1.5, "estimate", "Metres"),
	-- How finely throws are tried: the pitches, from and to, a step apart,
	-- then a finer step round the best; and the flight's tick.
	pitchFrom = p(-30, "estimate", "Degrees"),
	pitchTo = p(60, "estimate", "Degrees"),
	pitchStep = p(6, "estimate", "Degrees"),
	fineStep = p(1.5, "estimate", "Degrees"),
	-- A throw's flight, tried: a tick of it, which bends an arc no more than
	-- a few millimetres from the straight sweep over it; Curveball's, finer
	-- for its turn; and the longest it's flown for, as one that lands later
	-- is no use.
	flightTick = p(1 / 16, "estimate", "Seconds: eight of the game's ticks"),
	flareTick = p(1 / 64, "estimate", "Seconds: two of the game's ticks"),
	flight = p(3, "estimate", "Seconds"),
	-- Aimed: the view this near the cast's aim.
	aimed = p(1, "estimate", "Degrees"),
}

-- How many players each mode is filled to with bots, while anyone plays
-- it: 'The server is filled with bots until there are at least bot_quota
-- players on the server (humans + bots)' (bot_quota_mode fill, the Valve
-- Developer Community). Its own sides' sizes, but deathmatch's, as each
-- bot costs the server a player's simulation.
BotConfig.Quotas = {
	skirmish = p(4, "estimate", "Skirmish's two a side (ArenaConfig.sideSize)"),
	duel = p(2, "estimate", "The 1v1's one a side (ArenaConfig.Duel.sideSize): a bot to play whoever's alone"),
	spike = p(10, "estimate", "The spike rounds' five a side (MatchConfig.sideSize)"),
	gungame = p(8, "estimate", "Gun game's four a side (GunGameConfig.sideSize)"),
	deathmatch = p(8, "estimate", "Fewer than deathmatch's 14 (DeathmatchConfig.players): ours, for the server's sake"),
	teamdeathmatch = p(10, "estimate", "Team Deathmatch's five a side (TeamDeathmatchConfig.sideSize)"),
} :: { [string]: Param }

-- What bots are called: plain words of ours, never a player's name, as a
-- Roblox name has no space and each of these is shown after "BOT ".
BotConfig.NAMES = {
	"Ash",
	"Birch",
	"Cedar",
	"Dune",
	"Ember",
	"Flint",
	"Gale",
	"Haze",
	"Iris",
	"Juniper",
	"Kestrel",
	"Lark",
	"Moss",
	"Nova",
	"Onyx",
	"Pike",
	"Quill",
	"Reed",
	"Slate",
	"Thorn",
}
BotConfig.PREFIX = "BOT "

-- Each bot's stand-in for clients (system 60): a Configuration in
-- ReplicatedStorage's VFBots folder, named the bot's name, with its entity
-- id and its id in the rules as attributes, and the attributes the arena
-- keeps on a player (its side, its record and so on).
BotConfig.FOLDER = "VFBots"
BotConfig.ENTITY = "Entity"
BotConfig.ID = "Id"
-- And what the bot's doing for its side, for checks in Studio, and only
-- there, as it would tell an enemy's plan: its job's task in its side's
-- plan (BotTeam: hold, push, follow and so on).
BotConfig.TASK = "VFBotTask"
-- And the last of its agent's abilities it cast (system 66), and for what:
-- the ability and the moment ("darkcover push:darkcover:1"), as BotUtility
-- names them.
BotConfig.CAST = "VFBotCast"
-- Workspace's attribute, in Studio, for checks: the milliseconds the bots
-- take of each server frame, on average over the last second.
BotConfig.COST = "VFBotMs"

-- The skill named, or the default.
function BotConfig.skill(name: any): Skill
	return BotConfig.Skills[if typeof(name) == "string" then name else ""] or BotConfig.Skills[BotConfig.DEFAULT_SKILL]
end

return BotConfig
