--!strict
-- Bots (system 60): players the server plays itself, so a match fills up
-- without waiting for anyone to join (BotFill has how many). Each bot is a
-- real simulated player, as a practice dummy is (Dummies): the same
-- PlayerSim on the server's clock at 128 Hz, its shots and swings resolved
-- as a player's are (CombatServer), so it speeds up, stops, sprays,
-- reloads and dies as a player does, and the snapshots show it a tick
-- behind through a MovePacer, as they show everyone.
--
-- Its mind is the shared modules' (BotBrain, BotMove, BotTeam), plain state
-- and maths; what's here is what they're told and what comes of it:
--   * twenty times a second each bot looks at every enemy alive: one near
--     its view that neither the level nor a cloud or a wall hides (Sight,
--     as the minimap's spotting has it) is in sight, at the snapshots'
--     pose
--   * four times a second, which of the spots an enemy might be in are in
--     its sight (each site's entrances and the spots that hold them,
--     BotSpots), for it to glance at as it goes
--   * twice a second, each side's plan (BotTeam), with each bot on it, every
--     player on it alive, and where its bots have lately seen enemies: each
--     bot's job, a node to walk to and a point to look at
--   * each tick, its eyes and trigger (BotBrain) and its walk (BotMove) made
--     the buttons and angles of its simulation's input: the movement keys
--     for the way it's going as it looks where it looks, walk (Shift) when
--     its job says go quietly, and while it fights nothing but a step
--     aside, so it stands still to shoot. A knife in hand runs at whoever
--     it fights and slashes once they're in reach, and a sniper rifle is
--     scoped for a fight
--   * in the spike rounds (system 61), each side's plan has the spike in
--     it: SpikeServer says what a bot may do with it each tick, as it
--     does for a player, and hears what it did and when it dies; the bot's
--     hands (BotSpike) draw it and hold Use to plant it, or hold Use by it
--     to defuse it, and a bot sent to fetch it steps right onto it at the
--     end
--
-- Each map's nav is built the first time it's played on, a few
-- milliseconds a frame (BotNav's pause); until it's there, the bots on it
-- stand and fight where they are.
--
-- Who plays where, and when, is the arena's (Arena): it asks for a bot
-- (add) and lets one go (remove), puts it on a side (setSide), gives it its
-- kit as it would a player (resetKit, give), asks for each life (spawn),
-- says where it starts (spawnPicker), hears of each death (deathListeners),
-- and takes a bot out of play for a fallen player on its side who takes it
-- over, its body theirs (takeOut, system 62). Each bot has a stand-in in
-- ReplicatedStorage's BotConfig.FOLDER for clients: a Configuration named
-- the bot's name, with its entity id and its id in the rules, and whatever
-- the arena keeps on a player. They see and are seen as players are by the
-- fog of war (FogServer.bots) and the minimap (MinimapServer.bots).
-- Workspace's VFBotSkill attribute names the skill they play at
-- (BotConfig.Skills), from each one's next life.
--
-- Each plays an agent's kit as a player does (system 65): its stand-in is
-- an actor to PlayerSimServer and the ability servers as a player is, and
-- this answers for it there (PlayerSimServer.bots). Its kit carries from
-- one life to the next, what it casts goes to castListeners and
-- tickListeners, its deaths and lives to the ability servers too, and a
-- flash's blind or a nearsight on it, Paranoia's or Leer's (its
-- stand-in's attributes), hides from its looks what it hides from a
-- player's eyes: everything, at a blind's whitest, and anyone past the
-- nearsight's range. A Reyna in a Dismiss in her Empress's frenzy is
-- hidden from its looks too, as from her enemies' eyes (system 75).
--
-- And it casts them as a player would (system 66, BotUtility): each time
-- its side's plan is gone over, a bot that isn't fighting or casting is
-- told the moment, where it is in the plan (BotTeam.placeOf), what its
-- side has seen, its teammates and any defuse it hears, and given what
-- that calls for, a throw tried through the level first, a few
-- milliseconds of each think at most; then each tick its hands play the
-- cast, its view on its aim, the gun left alone, standing still for a
-- throw found from where it stands. A fight, or its hands going to the
-- spike, puts it away.
--
-- For checks in Studio, and only there, as it would tell an enemy's plan:
-- each stand-in carries its bot's task in its side's plan
-- (BotConfig.TASK) and the last ability it cast, for what (BotConfig.CAST),
-- and the Output has a line each time a bot's been stuck long enough to
-- plan its way again, and where. Workspace's
-- BotConfig.COST has how long the bots take of each server frame.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local ArenaLayout = require(Shared.Arena.ArenaLayout)
local DuelMap = require(Shared.Arena.DuelMap)
local TeamDeathmatchRules = require(Shared.Arena.TeamDeathmatchRules)
local StepTracker = require(Shared.Audio.StepTracker)
local BotBrain = require(Shared.Bots.BotBrain)
local BotConfig = require(Shared.Bots.BotConfig)
local BotMove = require(Shared.Bots.BotMove)
local BotNav = require(Shared.Bots.BotNav)
local BotSpike = require(Shared.Bots.BotSpike)
local BotSpots = require(Shared.Bots.BotSpots)
local BotTakeover = require(Shared.Bots.BotTakeover)
local BotTeam = require(Shared.Bots.BotTeam)
local BotUtility = require(Shared.Bots.BotUtility)
local FogOfWar = require(Shared.Combat.FogOfWar)
local Health = require(Shared.Combat.Health)
local Sight = require(Shared.Combat.Sight)
local Minimap = require(Shared.Match.Minimap)
local SpikeMaps = require(Shared.Match.SpikeMaps)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local MovePacer = require(Shared.Net.MovePacer)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local PlayerSim = require(Shared.PlayerSim)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local FlareSim = require(Shared.Abilities.FlareSim)
local ParanoiaSim = require(Shared.Abilities.ParanoiaSim)
local Spike = require(Shared.Spike.Spike)
local SpikeSim = require(Shared.Spike.SpikeSim)
local Accuracy = require(Shared.Weapons.Accuracy)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local WeaponSim = require(Shared.Weapons.WeaponSim)

local BarrierServer = require(script.Parent.BarrierServer)
local BlazeServer = require(script.Parent.BlazeServer)
local CloudServer = require(script.Parent.CloudServer)
local CombatServer = require(script.Parent.CombatServer)
local Entities = require(script.Parent.Entities)
local FlareServer = require(script.Parent.FlareServer)
local FogServer = require(script.Parent.FogServer)
local GroundGunsServer = require(script.Parent.GroundGunsServer)
local MinimapServer = require(script.Parent.MinimapServer)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local SpikeServer = require(script.Parent.SpikeServer)
local Tuning = require(script.Parent.Tuning)

local TICK_RATE = MovementConfig.TickRate.value
local DT = 1 / TICK_RATE
local MAX_CATCH_UP = 0.25 -- seconds of ticks a frame will run after a stall; older ones are skipped
local KILL_HEIGHT = -150 -- metres, as for a player
local BUILD_SLICE = 0.004 -- seconds of a frame a map's nav takes while it's built
local LOOK_AHEAD = 6 -- metres along its way a bot looks as it walks
local NEAR_VIEW = math.rad(75) -- radians either side of its view an enemy's looked for in the level
local SLASH_EXTRA = 0.3 -- metres past a slash's reach a bot with a knife starts it
local SCOPE_FROM = 8 -- metres: a sniper rifle's scoped for a fight further than this
-- Seconds of a think its bots' casts may take (system 66): no more bots are
-- told the moment once this is spent, as trying a throw flies it.
local CAST_BUDGET = 0.002
local CHEST = vector.create(0, 1.2, 0) -- metres over the feet
-- Metres: how near the spot its job sends it to a bot is there, for a plant;
-- and how near the point it's to step onto it walks straight at it, and
-- how near that's on it.
local THERE = 1
local ONTO = 1.5
local ON = 0.15
local EYE = vector.create(0, 1.62, 0) -- standing (MovementConfig's standEyeHeight)
local STUDIO = RunService:IsStudio()

local B = PlayerSim.Buttons
local P = BotConfig.Params
local U = BotConfig.Utility

export type SpawnPoint = { feet: vector, yaw: number }

-- What's played, as the arena tells it, for the bots' plans: the map (a
-- spike map's key, or the arena's map's), whether a round's under way,
-- which (any number that changes as one starts), what each side plays
-- (BotTeam's attack or defend in the spike rounds; any side it doesn't
-- name plays as a side of the modes that respawn), and each side's spawn
-- spots, in metres in the map's own frame.
export type Situation = {
	spikeMap: string?,
	arenaMap: string?,
	live: boolean,
	round: number,
	roles: { [number]: BotTeam.Side },
	spawns: { [number]: { vector } },
}

-- A map as the bots know it: its nav and, on a spike map, its plan; where
-- it's built in the place; places to go between; and the spots an enemy
-- might be in, by key, in its own frame.
type World = {
	nav: BotNav.Nav,
	plan: BotSpots.Plan?,
	origin: vector,
	places: { number },
	glances: { [string]: vector },
}

type Bot = {
	n: number, -- its number: entity id BOT_BASE + n
	id: number, -- its id in the rules
	name: string,
	entity: Entities.Entity,
	standIn: Configuration,
	sim: PlayerSim.State,
	alive: boolean,
	asked: boolean, -- a new life's been asked for, to start next frame
	spawnFeet: vector,
	-- The next life starts on this kit (nil: WeaponConfig's default) and
	-- shield, as a player's does (PlayerSimServer.resetKit).
	freshKit: boolean,
	kit: { string }?,
	kitShield: string?,
	side: number?,
	brain: BotBrain.Brain,
	mover: BotMove.Mover?,
	order: BotTeam.Order?,
	yaw: number,
	pitch: number,
	buttons: number, -- of the last input, for the sound others hear
	slot: number, -- the slot it asks to have in hand
	scoping: boolean, -- pressed AltFire last tick
	seq: number,
	pacer: MovePacer.Pacer, -- the pose after each tick, at the tick's server time
	shown: PlayerCodec.Pose?, -- what this frame's snapshot shows
	lookAt: number, -- when its next look is
	glanceAt: number,
	glances: { [string]: vector }, -- spots in sight now, in the place
	dice: BotConfig.Dice,
	stuckSeen: number, -- how often its walk's been stuck, as last told
	-- Its agent's abilities (system 66): the cast under way, and what it's
	-- cast this life.
	cast: BotUtility.Cast?,
	memo: BotUtility.Memo,
}

-- Someone alive on a side, as this frame's looks see them, and whether
-- they're unseen by their enemies (Reyna's Dismiss in her Empress's frenzy,
-- system 75).
type Seen = { id: number, side: number, points: { vector }, velocity: vector, hidden: boolean }

-- Someone alive on a side, for its bots' casts (system 66): their entity
-- id, eye, chest and health, and whether they're defusing the spike.
type Mate = { id: number, eye: vector, chest: vector, health: number, defusing: boolean }

local BotServer = {}

-- Where a bot's next life starts, by its id in the rules (the arena's).
BotServer.spawnPicker = nil :: ((id: number) -> SpawnPoint?)?
-- Called when a bot dies, with whoever killed it, if anyone else did.
BotServer.deathListeners = {} :: { (id: number, killer: Entities.Entity?) -> () }
-- Called when a bot's new life starts.
BotServer.spawnListeners = {} :: { (id: number) -> () }
-- Called on each tick a bot fires, swings or scopes (spawn protection's end).
BotServer.fireListeners = {} :: { (id: number) -> () }
-- What's played, when anything is (the arena's).
BotServer.situation = nil :: (() -> Situation?)?

local bots: { [number]: Bot } = {} -- by id in the rules
local byEntity: { [number]: Bot } = {}
local byStandIn: { [Instance]: Bot } = {}
local order: { Bot } = {} -- by number, the order their ticks run in
local world = RobloxWorld.new()
local seeds = Random.new()
local folder: Folder? = nil
local lastTick: number? = nil
local clock = 0 -- server time of the last frame
-- Each map's, by key, once built, and those being built.
local worlds: { [string]: World } = {}
local building: { [string]: boolean } = {}
-- Each side's plan, and the round and the map it's for.
local teams: { [number]: BotTeam.Team } = {}
local teamRound: { [number]: number } = {}
local thinkAt = 0
-- The bot (by its place in order) the next think's casts start from.
local castFrom = 1
-- In Studio, the time the bots have taken of the server's frames since
-- spentSince, over how many.
local spent, frames, spentSince = 0, 0, 0

local function diceOf(seed: number): BotConfig.Dice
	local r = Random.new(seed)
	return function(): number
		return r:NextNumber()
	end
end

local function skill(): BotConfig.Skill
	return BotConfig.skill(Workspace:GetAttribute(BotConfig.SKILL))
end

local function sortOrder()
	table.clear(order)
	for _, bot in bots do
		table.insert(order, bot)
	end
	table.sort(order, function(a: Bot, b: Bot): boolean
		return a.n < b.n
	end)
end

local function folderOf(): Folder
	local known = folder
	if known and known.Parent then
		return known
	end
	local made = Instance.new("Folder")
	made.Name = BotConfig.FOLDER
	made.Parent = ReplicatedStorage
	folder = made
	return made
end

-- A name nobody has: one of the list, starting anywhere in it, else one of
-- them with a number.
local function freeName(): string
	local taken: { [string]: boolean } = {}
	for _, bot in bots do
		taken[bot.name] = true
	end
	local names = BotConfig.NAMES
	local start = seeds:NextInteger(1, #names)
	local round = 1
	while true do
		for k = 0, #names - 1 do
			local word = names[(start + k - 1) % #names + 1]
			local name = BotConfig.PREFIX .. word .. (if round > 1 then " " .. round else "")
			if not taken[name] then
				return name
			end
		end
		round += 1
	end
end

-- The bot's pose as the simulation has it now.
local function currentPose(bot: Bot): PlayerCodec.Pose
	local m, w = bot.sim.movement, bot.sim.weapons
	-- Planting, defusing and its weapon put away for a defuse, through
	-- Dismiss or through Empress's activation, as a player's
	-- (PlayerSimServer), so it's drawn doing them.
	local kit, t = bot.sim.abilities, m.tick * DT
	local away = SpikeSim.stowed(bot.sim.spike) or AbilitySim.dismissing(kit, t) or AbilitySim.crowning(kit, t)
	return {
		id = bot.entity.id,
		position = m.position,
		yaw = bot.yaw,
		pitch = bot.pitch,
		crouchAlpha = m.crouchAlpha,
		grounded = m.grounded,
		alive = true,
		-- A dash makes no steps (system 17).
		quiet = StepTracker.isQuiet(bot.buttons, m.crouched) or AbilitySim.dashing(bot.sim.abilities, m.tick * DT),
		reloading = WeaponSim.isReloading(w),
		weapon = if away then 0 else WeaponConfig.IndexOf[w.loadout[w.equipped]] or 0,
		channel = bot.sim.spike.channel,
		gliding = m.gliding,
		shade = AbilitySim.shaded(bot.sim.abilities, m.tick * DT),
	}
end

-- The slot a bot fights with: its primary, else its sidearm, else its knife.
local function mainSlot(w: WeaponSim.State): number
	if w.loadout[1] ~= "" then
		return 1
	end
	return if w.loadout[2] ~= "" then 2 else 3
end

-- Whether a slot's gun has a round in it or in reserve.
local function loaded(w: WeaponSim.State, slot: number): boolean
	return w.loadout[slot] ~= "" and (w.ammo[slot] > 0 or w.reserve[slot] > 0)
end

local function died(bot: Bot, attacker: Entities.Entity?)
	bot.alive = false
	bot.shown = nil
	bot.cast = nil
	-- In the spike rounds its gun drops where it falls, as a player's does.
	GroundGunsServer.botDied(bot.sim, bot.yaw)
	local killer = if attacker and attacker ~= bot.entity then attacker else nil
	for _, listener in BotServer.deathListeners do
		listener(bot.id, killer)
	end
	for _, listener in PlayerSimServer.botDeathListeners do
		listener(bot.standIn, killer)
	end
	-- And the spike it carried, or the half of a defuse it reached.
	SpikeServer.botDied(bot.id)
end

-- Puts a bot where its life starts, on its kit: a new life, or one fallen
-- out of the world started over.
local function place(bot: Bot, feet: vector, yaw: number, loadout: { string }?)
	bot.spawnFeet = feet
	local kit = bot.sim.abilities
	bot.sim = PlayerSim.new(feet, loadout, seeds:NextInteger(0, 2 ^ 31 - 1))
	-- Its ability kit is kept from one life to the next, as a player's is.
	bot.sim.abilities = AbilitySim.copy(kit)
	AbilitySim.settle(bot.sim.abilities)
	bot.entity.sim = bot.sim
	bot.yaw, bot.pitch = yaw, 0
	bot.buttons = 0
	bot.slot = mainSlot(bot.sim.weapons)
	bot.scoping = false
	BotBrain.reset(bot.brain, yaw)
	local mover = bot.mover
	if mover then
		BotMove.reset(mover)
	end
	MovePacer.reset(bot.pacer)
	bot.shown = nil
end

-- A new life, where the arena says, on the kit it's to start on: the last
-- life's guns unless it starts afresh, but never the spike, with its
-- shield kept if a player's would be (PlayerSimServer.keepShields).
local function startLife(bot: Bot)
	bot.asked = false
	local picker = BotServer.spawnPicker
	local point = if picker then picker(bot.id) else nil
	if not point then
		return
	end
	local kit = bot.kit
	local loadout = if not bot.freshKit then table.clone(bot.sim.weapons.loadout) elseif kit then table.clone(kit) else nil
	if loadout then
		loadout[Spike.SLOT] = ""
	end
	local health = bot.entity.health
	local kept = if PlayerSimServer.keepShields and not bot.freshKit then Health.keep(health) else nil
	if bot.freshKit then
		Health.setShield(health, bot.kitShield or WeaponConfig.DefaultShield)
		bot.freshKit = false
	end
	Health.reset(health)
	if kept then
		Health.restore(health, kept)
	end
	bot.brain.skill = skill()
	bot.order = nil
	bot.cast = nil
	bot.memo = BotUtility.memo()
	place(bot, point.feet + vector.create(0, 0.05, 0), point.yaw, loadout)
	bot.alive = true
	local event = Entities.vitals(bot.entity)
	event.kind = "spawn"
	Remotes.get().Combat:FireAllClients(event)
	for _, listener in BotServer.spawnListeners do
		listener(bot.id)
	end
	for _, listener in PlayerSimServer.botSpawnListeners do
		listener(bot.standIn)
	end
end

-- Maps ------------------------------------------------------------------------------

-- Yields now and then while a map's nav is built, a few milliseconds a frame.
local function pauser(): () -> ()
	local began = os.clock()
	return function()
		if os.clock() - began > BUILD_SLICE then
			task.wait()
			began = os.clock()
		end
	end
end

-- Builds a map's world, a little each frame, from now.
local function build(key: string, spikeMap: string?, arenaMap: string?)
	building[key] = true
	task.spawn(function()
		local pause = pauser()
		local made: World
		if spikeMap then
			local map = SpikeMaps.Maps[spikeMap]
			local plan = BotSpots.ofMap(map, pause)
			-- Its rooms that are named on the big map: the places to go
			-- between, but for the spawn rooms, which Team Deathmatch burns
			-- anyone staying in (TeamDeathmatchRules.ROOMS).
			local points: { vector } = {}
			for _, r in map.rooms() do
				local x, z = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
				local named = (r.x1 - r.x0) * (r.z1 - r.z0) >= Minimap.Params.smallRoom.value
				local spawnRoom = table.find(TeamDeathmatchRules.ROOMS, r.name) ~= nil
				if named and not spawnRoom and not string.find(r.name, "Door", 1, true) then
					table.insert(points, vector.create(x, map.floorAt(x, z) or 0, z))
				end
			end
			local glances: { [string]: vector } = {}
			for _, site in plan.sites do
				for k, e in site.entrances do
					glances[site.name .. ":in" .. k] = e.aim
				end
				for k, h in site.holds do
					glances[site.name .. ":hold" .. k] = BotNav.feet(plan.nav, h.node) + EYE
				end
			end
			made = { nav = plan.nav, plan = plan, origin = map.origin, places = BotTeam.placesOf(plan.nav, points), glances = glances }
		elseif arenaMap == DuelMap.KEY then
			-- The 1v1's map (system 64), from the place's own parts, in metres in
			-- the place: a grid of places over its widest floor.
			local info = DuelMap.read()
			local parts: { any } = if info then info.parts else {}
			local b = if info then info.bounds else { x0 = 0, z0 = 0, x1 = 1, z1 = 1 }
			local nav = BotNav.ofParts("arena" .. DuelMap.KEY, parts, b.x0 - 1, b.z0 - 1, b.x1 + 1, b.z1 + 1, pause)
			local points: { vector } = {}
			if info then
				local h = info.hall
				for _, fx in { 1 / 6, 1 / 2, 5 / 6 } do
					for _, fz in { 1 / 6, 1 / 2, 5 / 6 } do
						table.insert(points, vector.create(h.x0 + fx * (h.x1 - h.x0), info.ground, h.z0 + fz * (h.z1 - h.z0)))
					end
				end
			end
			made = { nav = nav, plan = nil, origin = vector.create(0, 0, 0), places = BotTeam.placesOf(nav, points), glances = {} }
		else
			local name = arenaMap :: string
			local w, l, _, rd = ArenaLayout.size()
			local nav =
				BotNav.ofParts("arena" .. name, ArenaLayout.parts(name), -w / 2 - 1, -l / 2 - rd - 1, w / 2 + 1, l / 2 + rd + 1, pause)
			-- A grid of places over the hall.
			local points: { vector } = {}
			for _, fx in { -1 / 3, 0, 1 / 3 } do
				for _, fz in { -1 / 3, 0, 1 / 3 } do
					table.insert(points, vector.create(fx * w, 0, fz * l))
				end
			end
			made = { nav = nav, plan = nil, origin = ArenaLayout.origin, places = BotTeam.placesOf(nav, points), glances = {} }
		end
		worlds[key] = made
		building[key] = nil
	end)
end

-- The world of what's played, once it's built.
local function worldOf(s: Situation): World?
	local key = if s.spikeMap then s.spikeMap elseif s.arenaMap then "arena" .. s.arenaMap else nil
	if not key then
		return nil
	end
	local known = worlds[key]
	if known then
		return known
	end
	if not building[key] then
		build(key, s.spikeMap, s.arenaMap)
	end
	return nil
end

-- Looking ------------------------------------------------------------------------------

-- What's in the way of an eye: the level (but not the spawns' barriers), the
-- clouds, the walls of fire and the walls of ice.
local function occluders(now: number): Sight.Occluders
	return {
		clouds = CloudServer.standing(now),
		walls = BlazeServer.standing(now),
		barriers = BarrierServer.standing(),
		time = now,
		blocked = FogServer.blocked,
	}
end

-- The side someone's on: a player's attribute, a bot's own; nil for anyone
-- on none (the course, the Play menu, a dummy).
local function sideOf(entity: Entities.Entity): number?
	local player = entity.player
	if player then
		local side = player:GetAttribute(ArenaConfig.SIDE)
		return if typeof(side) == "number" then side else nil
	end
	local bot = byEntity[entity.id]
	return if bot then bot.side else nil
end

-- Everyone alive on a side, where the snapshots show them.
local function everyone(): { Seen }
	local out: { Seen } = {}
	for id, entity in Entities.all() do
		local side = if entity.health.alive then sideOf(entity) else nil
		local pose = if side then entity.pose() else nil
		if side and pose then
			local sim = entity.sim
			table.insert(out, {
				id = id,
				side = side,
				points = Sight.points(pose),
				velocity = if sim then sim.movement.velocity else vector.zero,
				hidden = sim ~= nil and AbilitySim.unseen(sim.abilities, sim.movement.tick * DT),
			})
		end
	end
	return out
end

-- A look at every enemy: those near its view are looked for in the level,
-- but none while a flash has it blinded, none past the nearsight's range
-- while it's nearsighted, by Paranoia or Leer (systems 65 and 74), and
-- never a Reyna in a Dismiss in her Empress's frenzy (system 75).
local function look(bot: Bot, now: number, seen: { Seen }, o: Sight.Occluders, cfg: MovementConfig.Values)
	local eye = PlayerSim.eye(bot.sim, cfg)
	local blind = FlareSim.decode(bot.standIn:GetAttribute(FlareSim.BLIND_ATTRIBUTE))
	local blinded = blind ~= nil and FlareSim.whiteAt(blind, now) >= P.blindFrom.value
	local range = ParanoiaSim.range(ParanoiaSim.decode(bot.standIn:GetAttribute(ParanoiaSim.ATTRIBUTE)), now)
	local targets: { BotBrain.Target } = {}
	for _, s in seen do
		if s.side == bot.side or s.id == bot.entity.id then
			continue
		end
		local chest = s.points[2] or s.points[1]
		local yaw = BotBrain.anglesTo(eye, chest)
		local visible = false
		local near = range == nil or vector.magnitude(chest - eye) <= range
		if not blinded and near and not s.hidden and math.abs(BotBrain.wrap(yaw - bot.yaw)) <= NEAR_VIEW then
			for _, point in s.points do
				if not Sight.hidden(eye, point, o) then
					visible = true
					break
				end
			end
		end
		table.insert(targets, { id = s.id, head = s.points[1], chest = chest, velocity = s.velocity, visible = visible })
	end
	BotBrain.look(bot.brain, now, eye, targets)
end

-- Which of the map's spots an enemy might be in are in the bot's sight.
local function glance(bot: Bot, w: World, cfg: MovementConfig.Values)
	table.clear(bot.glances)
	local from = PlayerSim.eye(bot.sim, cfg) - w.origin
	local range = P.checkRange.value
	for key, spot in w.glances do
		if vector.magnitude(spot - from) <= range and BotNav.sees(w.nav, from, spot) then
			bot.glances[key] = spot + w.origin
		end
	end
end

-- Plans ---------------------------------------------------------------------------------

-- The nodes nearest a side's spawn spots.
local function spawnNodes(w: World, spots: { vector }?): { number }
	return if spots then BotTeam.placesOf(w.nav, spots) else {}
end

-- How far a defuse under way has got (seconds of the 7), if one is.
local function defusing(sim: PlayerSim.State): number?
	local s = sim.spike
	return if s.channel == SpikeSim.DEFUSING then SpikeSim.defuseProgress(s, sim.movement.tick * DT) else nil
end

-- The spike as the plans know it, in the map's frame (system 61): in play
-- only while it's on the ground, carried or planted.
local function spikeIn(w: World): BotTeam.Spike?
	local now = SpikeServer.view()
	if not now then
		return nil
	end
	local state = now.state
	if state ~= "dropped" and state ~= "carried" and state ~= "planted" then
		return nil
	end
	local position = now.position
	return {
		state = state :: any,
		at = if position then position - w.origin else nil,
		carrier = if now.carrier then PlayerCodec.entityIdForUser(now.carrier) else nil,
		site = if now.site ~= "" then now.site else nil,
		detonateAt = now.detonateAt,
		halfSaved = now.halfSaved,
	}
end

-- Someone alive on a side, for its bots' casts.
local function mateOf(entity: Entities.Entity, sim: PlayerSim.State, cfg: MovementConfig.Values, defusing: boolean): Mate
	return {
		id = entity.id,
		eye = PlayerSim.eye(sim, cfg),
		chest = sim.movement.position + CHEST,
		health = entity.health.health,
		defusing = defusing,
	}
end

-- What a bot on `side` knows for its casts (system 66), in the place's
-- frame: where it is in its side's plan, how long the round's been live,
-- what its side has seen lately (`sightings`, in the map's frame), its
-- teammates (`crew`, every side's), and the spike being defused by an
-- enemy, if it's planted and is.
local function momentOf(
	bot: Bot,
	now: number,
	w: World,
	side: number,
	crew: { [number]: { Mate } },
	sightings: { [number]: { BotTeam.Sighting } },
	spike: BotTeam.Spike?,
	cfg: MovementConfig.Values
): BotUtility.Moment
	local sim = bot.sim
	local feet = sim.movement.position
	local team = teams[side]
	local place = if team then BotTeam.placeOf(team, bot.entity.id, feet - w.origin) else nil
	local brain = bot.brain
	local last = brain.hurtAt
	for _, k in brain.known do
		last = math.max(last, k.seen)
	end
	local allies: { BotUtility.Ally } = {}
	local mates: { vector } = {}
	local defuse: vector? = nil
	local planted = if spike and spike.state == "planted" then spike.at else nil
	for other, list in crew do
		for _, mate in list do
			if other ~= side then
				if mate.defusing and planted then
					defuse = planted + w.origin
				end
			elseif mate.id ~= bot.entity.id then
				table.insert(mates, mate.eye)
				table.insert(allies, { id = mate.id, chest = mate.chest, health = mate.health })
			end
		end
	end
	local seen: { BotTeam.Sighting } = {}
	local known: { BotTeam.Sighting } = sightings[side] or {}
	for _, sighting in known do
		table.insert(seen, { at = sighting.at + w.origin, time = sighting.time })
	end
	local began = if team then team.began else nil
	return {
		now = now,
		clock = (sim.movement.tick + 1) * DT,
		place = if place then BotUtility.moved(place, w.origin) else nil,
		live = if began then now - began else 0,
		feet = feet,
		eye = PlayerSim.eye(sim, cfg),
		health = bot.entity.health.health,
		fighting = BotBrain.fighting(brain),
		quiet = now - last,
		sightings = seen,
		defuse = defuse,
		allies = allies,
		mates = mates,
	}
end

-- Their agents' abilities (system 66): each bot alive that isn't casting,
-- in turn from where the last think left off, is told the moment and given
-- what it calls for, until this think has spent CAST_BUDGET on them (a bot
-- that runs past it tries the rest of its throws the next).
local function casts(
	now: number,
	s: Situation,
	w: World,
	crew: { [number]: { Mate } },
	sightings: { [number]: { BotTeam.Sighting } },
	spike: BotTeam.Spike?
)
	local count = #order
	if not s.live or count == 0 then
		return
	end
	local started = os.clock()
	local cfg = Tuning.config()
	for k = 0, count - 1 do
		local index = (castFrom + k - 1) % count + 1
		local bot = order[index]
		local side = bot.side
		if bot.alive and side ~= nil and bot.cast == nil and now >= bot.memo.nextAt then
			local m = momentOf(bot, now, w, side, crew, sightings, spike, cfg)
			local cast = BotUtility.choose(m, bot.sim.abilities, bot.memo, bot.brain.skill, bot.dice, world, started + CAST_BUDGET)
			if cast then
				bot.cast = cast
				if STUDIO then
					bot.standIn:SetAttribute(BotConfig.CAST, cast.ability .. " " .. cast.key)
				end
			end
		end
		if os.clock() - started > CAST_BUDGET then
			castFrom = index % count + 1
			return
		end
	end
	castFrom = castFrom % count + 1
end

-- Each side's plan, gone over: its bots' jobs, and what they cast.
local function think(now: number, s: Situation, w: World)
	local members: { [number]: { BotTeam.Member } } = {}
	local sightings: { [number]: { BotTeam.Sighting } } = {}
	local crew: { [number]: { Mate } } = {}
	local cfg = Tuning.config()
	local spike = spikeIn(w)
	for _, bot in order do
		local side = bot.side
		if side == nil then
			continue
		end
		local list = members[side] or {}
		members[side] = list
		if not bot.alive then
			continue
		end
		local sim = bot.sim
		local progress = defusing(sim)
		table.insert(list, { id = bot.entity.id, bot = true, alive = true, feet = sim.movement.position - w.origin, defusing = progress })
		crew[side] = crew[side] or {}
		table.insert(crew[side], mateOf(bot.entity, sim, cfg, progress ~= nil))
		local seen = sightings[side] or {}
		sightings[side] = seen
		for _, k in bot.brain.known do
			if now - k.seen <= BotTeam.MEMORY then
				table.insert(seen, { at = k.at - w.origin, time = k.seen })
			end
		end
	end
	for _, player in Players:GetPlayers() do
		local side = player:GetAttribute(ArenaConfig.SIDE)
		local list = if typeof(side) == "number" then members[side] else nil
		local sim = if list and PlayerSimServer.inPlay(player) then PlayerSimServer.getSim(player) else nil
		local entity = PlayerSimServer.entityOf(player)
		if list and sim and entity then
			local progress = defusing(sim)
			table.insert(list, { id = entity.id, bot = false, alive = true, feet = sim.movement.position - w.origin, defusing = progress })
			local mates = crew[side :: number] or {}
			crew[side :: number] = mates
			table.insert(mates, mateOf(entity, sim, cfg, progress ~= nil))
		end
	end
	for side in teams do
		if not members[side] then
			teams[side] = nil
			teamRound[side] = nil
		end
	end
	for side, list in members do
		local role: BotTeam.Side = s.roles[side] or "team"
		local team = teams[side]
		if not team or team.nav ~= w.nav or team.side ~= role then
			-- A side of the modes that respawn goes between the map's places
			-- and the enemy's spawns.
			local places = table.clone(w.places)
			if role == "team" then
				for other, spots in s.spawns do
					if other ~= side then
						for _, n in spawnNodes(w, spots) do
							table.insert(places, n)
						end
					end
				end
			end
			local made = BotTeam.new(w.nav, if role ~= "team" then w.plan else nil, role, diceOf(seeds:NextInteger(1, 2 ^ 31 - 2)), places)
			teams[side] = made
			teamRound[side] = nil
			team = made
		end
		local t = team :: BotTeam.Team
		if teamRound[side] ~= s.round then
			teamRound[side] = s.round
			BotTeam.round(t, now)
		end
		local orders = BotTeam.think(t, now, s.live, list, sightings[side] or {}, if role ~= "team" then spike else nil)
		for _, m in list do
			local bot = if m.bot then byEntity[m.id] else nil
			if bot then
				local order = orders[m.id]
				bot.order = order
				local doing = if order then order.task else nil
				if STUDIO and bot.standIn:GetAttribute(BotConfig.TASK) ~= doing then
					bot.standIn:SetAttribute(BotConfig.TASK, doing)
				end
			end
		end
	end
	casts(now, s, w, crew, sightings, spike)
end

-- Ticks -----------------------------------------------------------------------------------

-- How far up the gun's next round goes, in degrees: the recoil's climb at
-- the bullet the spray's on, or the first's once it's settled. `t` is the
-- simulation's own time, which its shots are timed by (PlayerSim counts it
-- in ticks from the life's start), not the server's.
local function climbOf(def: WeaponConfig.WeaponDef, w: WeaponSim.State, t: number): number
	local settled = t - w.lastShotTime > def.accuracy.recoveryTime.value
	return Accuracy.curve(def.recoil.pitch.points, if settled then 1 else w.sprayIndex + 1)
end

-- Where a bot looks when it's not fighting: along its way as it walks, a
-- few metres on; at what its job has it watch once it's nearly there;
-- else wherever it's looking.
local function lookPoint(bot: Bot, w: World?): vector?
	local job = bot.order
	if not w or not job then
		return nil
	end
	local mover = bot.mover
	local path = if mover and job.goal then mover.path else nil
	if mover and path then
		local feet = bot.sim.movement.position - w.origin
		for k = mover.index, #path do
			local p = BotNav.feet(w.nav, path[k])
			if vector.magnitude(p - feet) >= LOOK_AHEAD then
				return p + EYE + w.origin
			end
		end
	end
	return if job.look then job.look + w.origin else nil
end

-- The movement keys that go most nearly along `direction` for a view at `yaw`.
local function keysFor(direction: vector, yaw: number): number
	local forward, right = BotMove.keys(direction, yaw)
	local buttons = 0
	if forward > 0 then
		buttons += B.Forward
	elseif forward < 0 then
		buttons += B.Back
	end
	if right > 0 then
		buttons += B.Right
	elseif right < 0 then
		buttons += B.Left
	end
	return buttons
end

-- Where a flare its own side threw pops, if one in the air will pop in
-- the bot's sight from `eye` (system 66): it looks away from it, as a
-- player told of it does.
local function flashAt(bot: Bot, eye: vector): vector?
	for _, p in FlareServer.coming() do
		local thrower = PlayerSimServer.entityOf(p.player)
		local ours = p.player == bot.standIn or (thrower ~= nil and bot.side ~= nil and sideOf(thrower) == bot.side)
		if ours and FlareSim.seen(p.position, eye, world) then
			return p.position
		end
	end
	return nil
end

-- One tick of a bot's life at server time `t`, in a frame ending at `now`.
local function drive(bot: Bot, t: number, now: number, cfg: MovementConfig.Values, w: World?)
	local sim = bot.sim
	local wpn = sim.weapons
	local slot = wpn.equipped
	local def = WeaponSim.equippedDef(wpn)
	local mode = WeaponConfig.mode(def, wpn.scoped)
	local main = mainSlot(wpn)
	local body: BotBrain.Body = {
		now = t,
		eye = PlayerSim.eye(sim, cfg),
		accurate = PlayerSim.isAccurate(sim, cfg),
		weapon = def.id,
		category = def.category,
		semi = mode.fireMode == "semi",
		interval = mode.interval,
		recovery = def.accuracy.recoveryTime.value,
		ammo = wpn.ammo[slot],
		magazine = def.magazine.value,
		reloading = WeaponSim.isReloading(wpn),
		climb = climbOf(def, wpn, (sim.movement.tick + 1) * DT),
		sidearm = main == 1 and loaded(wpn, 2),
		equipped = if slot == main then 1 else slot,
	}
	local brain = bot.brain
	-- The view before its mind's tick, which a cast's aim eases on from.
	local viewYaw, viewPitch = brain.yaw, brain.pitch
	local act = BotBrain.tick(brain, body, DT, lookPoint(bot, w), bot.glances)
	local feet = sim.movement.position
	local mover = bot.mover
	local job = bot.order
	local target = if brain.target then brain.known[brain.target] else nil
	-- The spike in its hands (system 61): a plant or a defuse, as its job
	-- says, once it's there.
	local objective = SpikeServer.objectiveOf(bot.id)
	local soulful = PlayerSimServer.withSoul(bot.standIn, sim, objective, cfg)
	local hands = BotSpike.NONE
	if job then
		local there = true
		if w and job.goal then
			local spot = BotNav.feet(w.nav, job.goal) + w.origin
			there = vector.magnitude(vector.create(spot.x - feet.x, 0, spot.z - feet.z)) <= THERE and math.abs(spot.y - feet.y) < 1
		end
		hands = BotSpike.hands(job, there, sim, objective, (sim.movement.tick + 1) * DT, body.eye, BotBrain.fighting(brain))
	end
	-- Its agent's ability being cast (system 66): given up as a fight starts
	-- or its hands go to the spike, else its hands for it, its view on the
	-- cast's aim.
	local casting: BotUtility.Hands? = nil
	local current = bot.cast
	if current then
		if (BotBrain.fighting(brain) and current.step ~= "after") or hands.quiet then
			bot.cast = nil
			bot.memo.nextAt = now + U.between.value
		else
			local h = BotUtility.hands(current, sim.abilities, wpn, (sim.movement.tick + 1) * DT, body.eye, viewYaw, viewPitch, DT)
			brain.yaw, brain.pitch = h.yaw, h.pitch
			act.yaw, act.pitch = h.yaw, h.pitch
			casting = h
			if h.done then
				bot.cast = nil
				bot.memo.nextAt = now + U.between.value
			end
		end
	end
	-- Its side's flash about to pop where it would see it: out of a fight
	-- and a cast, it turns its back on it until it has, as fast as it
	-- turns, so it's no more than a moment's white (FlareSim's `away`).
	local flash = if casting or BotBrain.fighting(brain) then nil else flashAt(bot, body.eye)
	if flash then
		local away = BotBrain.anglesTo(body.eye, body.eye * 2 - flash)
		local most = math.rad(P.lookSpeed.value) * DT
		local yaw = viewYaw + math.clamp(BotBrain.wrap(away - viewYaw), -most, most)
		local pitch = viewPitch + math.clamp(-viewPitch, -most, most)
		brain.yaw, brain.pitch = yaw, pitch
		act.yaw, act.pitch = yaw, pitch
	end
	local onto = if job and job.onto and w then job.onto + w.origin else nil
	local toward = if onto then vector.create(onto.x - feet.x, 0, onto.z - feet.z) else nil
	local buttons = 0
	if def.melee and target then
		-- A knife: straight at them, and a slash once they're in reach.
		local flat = vector.create(target.at.x - feet.x, 0, target.at.z - feet.z)
		local distance = vector.magnitude(flat)
		if distance > 1e-3 then
			buttons += keysFor(flat / distance, act.yaw)
		end
		act.fire = distance <= def.melee.slash.reach.value + SLASH_EXTRA
		if mover then
			BotMove.hold(mover)
		end
	elseif act.stop then
		-- It stands still to shoot, but for a step aside between bursts.
		if act.dodge > 0 then
			buttons += B.Right
		elseif act.dodge < 0 then
			buttons += B.Left
		end
		if mover then
			BotMove.hold(mover)
		end
	elseif hands.still then
		-- Planting or defusing: it stands where it is.
		if mover then
			BotMove.hold(mover)
		end
	elseif casting and casting.still then
		-- A throw found from where it stands, thrown from there.
		if mover then
			BotMove.hold(mover)
		end
	elseif onto and toward and vector.magnitude(toward) <= ONTO and math.abs(onto.y - feet.y) < 1 then
		-- Right onto the point its job says: the spike, to run over it.
		local d = vector.magnitude(toward)
		if d > ON then
			buttons += keysFor(toward / d, act.yaw)
		end
		if mover then
			BotMove.hold(mover)
		end
	elseif mover and w then
		local step = BotMove.step(mover, t, feet - w.origin, if job then job.goal else nil)
		local direction = step.direction
		if direction then
			buttons += keysFor(direction, act.yaw)
			if job and job.walk then
				buttons += B.Walk
			end
		end
		if step.jump then
			buttons += B.Jump
		end
		if STUDIO and mover.stuck ~= bot.stuckSeen then
			bot.stuckSeen = mover.stuck
			local at = feet - w.origin
			print(string.format("[VF] %s stuck at (%.1f, %.1f, %.1f), going another way", bot.name, at.x, at.y, at.z))
		end
	end
	-- With the spike in hand or a plant or a defuse under way, the gun's
	-- left alone: fire with the spike in hand would plant it. So it is
	-- while a cast's hands have the buttons.
	local quiet = hands.quiet or casting ~= nil
	if hands.use then
		buttons += B.Use
	end
	if casting then
		buttons += casting.buttons
	end
	if act.crouch and not quiet then
		buttons += B.Crouch
	end
	-- Reyna's Devour (system 73): hurt, with a Soul Orb in reach and a
	-- charge, it takes the orb, a press as soon as it's there, but for in
	-- Empress's frenzy, which casts it for it (system 75). It leaves Dismiss
	-- alone, as a fight would want its gun.
	local kit = sim.abilities
	local devour = AbilitySim.slotOf(kit, "devour")
	local h = bot.entity.health
	local hurt = h.health < h.maxHealth and not AbilitySim.frenzied(kit, sim.movement.tick * DT)
	if soulful and soulful.soul and devour and kit.charges[devour] > 0 and hurt and not hands.quiet then
		buttons += AbilitySim.BUTTONS[devour]
	end
	if act.fire and not quiet then
		buttons += B.Fire
	end
	if act.reload and not quiet then
		buttons += B.Reload
	end
	-- The gun to have in hand: the one it fights with, or its sidearm when
	-- it says; one that's empty for good gives way to one that isn't.
	if act.slot == 1 then
		bot.slot = main
	elseif act.slot == 2 and wpn.loadout[2] ~= "" then
		bot.slot = 2
	end
	if not loaded(wpn, bot.slot) and bot.slot ~= 3 then
		bot.slot = if loaded(wpn, main) then main elseif loaded(wpn, 2) then 2 else 3
	end
	if hands.slot then
		bot.slot = hands.slot
	end
	-- A sniper rifle's scoped for a fight at range, and not otherwise: a
	-- press, then let go.
	local scope = false
	if def.category == "sniper" and not quiet then
		local far = target ~= nil and vector.magnitude(target.at - feet) > SCOPE_FROM
		scope = (far and wpn.scoped == 0) or (not target and wpn.scoped ~= 0)
	end
	if scope and not bot.scoping then
		buttons += B.AltFire
	end
	bot.scoping = scope and not bot.scoping
	bot.buttons = buttons
	bot.yaw, bot.pitch = act.yaw, act.pitch
	bot.seq += 1
	local input: PlayerCodec.WireInput = {
		seq = bot.seq,
		buttons = buttons,
		yaw = act.yaw,
		pitch = act.pitch,
		slot = if casting and casting.slot then casting.slot else bot.slot,
		viewTime = now,
	}
	local fieldsOf = PlayerSimServer.fields
	local wallsAt = PlayerSimServer.barriers
	local shots, swing, spikeAct, _, casts = PlayerSim.step(
		sim,
		input,
		cfg,
		world,
		DT,
		soulful,
		if fieldsOf then { fields = fieldsOf(), time = t } else nil,
		if wallsAt then wallsAt(t) else nil
	)
	if sim.movement.position.y < KILL_HEIGHT then
		place(bot, bot.spawnFeet, bot.yaw, table.clone(wpn.loadout))
	end
	MovePacer.push(bot.pacer, t, currentPose(bot))
	if bit32.btest(buttons, B.Fire + B.AltFire) then
		for _, listener in BotServer.fireListeners do
			listener(bot.id)
		end
	end
	-- What it cast, to the ability servers, as a player's casts go (system
	-- 65), and the tick, for those that fly what it threw on its ticks.
	if casts then
		for _, cast in casts do
			for _, listener in PlayerSimServer.castListeners do
				listener(bot.standIn, cast)
			end
		end
	end
	for _, listener in PlayerSimServer.tickListeners do
		listener(bot.standIn, input, casts)
	end
	if shots then
		CombatServer.onVolley(bot.entity, shots, now)
	end
	if swing then
		CombatServer.onSwing(bot.entity, swing, now)
	end
	if spikeAct then
		SpikeServer.botActed(bot.id, spikeAct)
	end
end

-- The arena's side of it ----------------------------------------------------------------

local function botOf(id: number): Bot?
	return bots[id]
end

-- A new bot, on no side and not yet alive: its id in the rules.
function BotServer.add(): number
	local n = 1
	while bots[PlayerCodec.botRuleId(n)] do
		n += 1
	end
	local id = PlayerCodec.botRuleId(n)
	local name = freeName()
	local hp = WeaponConfig.Health
	local bot: Bot
	local entity: Entities.Entity = {
		id = PlayerCodec.BOT_BASE + n,
		kind = "bot",
		name = name,
		player = nil,
		health = Health.new(hp.maxHealth.value, WeaponConfig.DefaultShield),
		sim = nil,
		pose = function(): PlayerCodec.Pose?
			if not bot.alive or not bot.entity.health.alive then
				return nil
			end
			-- Until its first tick, where it spawned.
			return bot.shown or currentPose(bot)
		end,
		onKilled = function(attacker: Entities.Entity?)
			died(bot, attacker)
		end,
	}
	local standIn = Instance.new("Configuration")
	standIn.Name = name
	standIn:SetAttribute(BotConfig.ENTITY, entity.id)
	standIn:SetAttribute(BotConfig.ID, id)
	standIn.Parent = folderOf()
	local dice = diceOf(seeds:NextInteger(1, 2 ^ 31 - 2))
	local sim = PlayerSim.new(vector.zero)
	bot = {
		n = n,
		id = id,
		name = name,
		entity = entity,
		standIn = standIn,
		sim = sim,
		alive = false,
		asked = false,
		spawnFeet = vector.zero,
		freshKit = true,
		kit = nil,
		kitShield = nil,
		side = nil,
		brain = BotBrain.new(skill(), dice),
		mover = nil,
		order = nil,
		yaw = 0,
		pitch = 0,
		buttons = 0,
		slot = 1,
		scoping = false,
		seq = 0,
		pacer = MovePacer.new(),
		shown = nil,
		lookAt = 0,
		glanceAt = 0,
		glances = {},
		dice = dice,
		stuckSeen = 0,
		cast = nil,
		memo = BotUtility.memo(),
	}
	bots[id] = bot
	byEntity[entity.id] = bot
	byStandIn[standIn] = bot
	Entities.add(entity)
	sortOrder()
	return id
end

-- A bot gone: out of everything, its stand-in too.
function BotServer.remove(id: number)
	local bot = bots[id]
	if not bot then
		return
	end
	bots[id] = nil
	byEntity[bot.entity.id] = nil
	byStandIn[bot.standIn] = nil
	Entities.remove(bot.entity.id)
	FogServer.forget(bot.entity.id)
	bot.standIn:Destroy()
	sortOrder()
end

-- Every bot's id in the rules, in the order they were made.
function BotServer.ids(): { number }
	local out = {}
	for _, bot in order do
		table.insert(out, bot.id)
	end
	return out
end

-- Whether an id in the rules is a bot's that's here.
function BotServer.has(id: number): boolean
	return bots[id] ~= nil
end

-- What carries a bot's attributes for clients.
function BotServer.standIn(id: number): Configuration?
	local bot = botOf(id)
	return if bot then bot.standIn else nil
end

-- The side a bot's on, if any.
function BotServer.side(id: number): number?
	local bot = botOf(id)
	return if bot then bot.side else nil
end

-- Puts a bot on a side, or on none.
function BotServer.setSide(id: number, side: number?)
	local bot = botOf(id)
	if not bot then
		return
	end
	bot.side = side
	if bot.standIn:GetAttribute(ArenaConfig.SIDE) ~= side then
		bot.standIn:SetAttribute(ArenaConfig.SIDE, side)
	end
end

-- A new life asked for, to start next frame (a round starting, or one
-- coming back).
function BotServer.spawn(id: number)
	local bot = botOf(id)
	if bot then
		bot.asked = true
	end
end

-- Whether a new life's been asked for and hasn't started.
function BotServer.spawnPending(id: number): boolean
	local bot = botOf(id)
	return bot ~= nil and bot.asked
end

function BotServer.isAlive(id: number): boolean
	local bot = botOf(id)
	return bot ~= nil and bot.alive
end

function BotServer.getSim(id: number): PlayerSim.State?
	local bot = botOf(id)
	return if bot then bot.sim else nil
end

function BotServer.entityOf(id: number): Entities.Entity?
	local bot = botOf(id)
	return if bot then bot.entity else nil
end

-- From a bot's next life, a starting kit, as PlayerSimServer.resetKit.
function BotServer.resetKit(id: number, kit: { string }?, shield: string?)
	local bot = botOf(id)
	if bot then
		bot.freshKit = true
		bot.kit = kit
		bot.kitShield = shield
	end
end

-- Puts a weapon in one of a bot's slots, or empties one, as
-- PlayerSimServer.give. Returns whether it did.
function BotServer.give(id: number, slot: number, weapon: string, ammo: number?, reserve: number?): boolean
	local bot = botOf(id)
	local def = WeaponConfig.Defs[weapon]
	local fits = if weapon == ""
		then slot == 1 or slot == 2
		else def ~= nil and def.slot == slot and not def.spike and not def.ultimate and not def.ability
	if not bot or not fits then
		return false
	end
	local w = bot.sim.weapons
	WeaponSim.give(w, slot, weapon, bot.sim.movement.tick * DT, ammo, reserve)
	-- A gun given is the one to fight with.
	bot.slot = mainSlot(w)
	return true
end

-- The weapon in one of a bot's slots ("" for none), and the slot in hand.
function BotServer.holding(id: number, slot: number): (string?, number?)
	local bot = botOf(id)
	if not bot then
		return nil, nil
	end
	local w = bot.sim.weapons
	return w.loadout[slot], w.equipped
end

-- Gives a bot the spike, in its slot and not drawn, or takes it from it,
-- as PlayerSimServer.setSpike (system 61, SpikeServer).
function BotServer.setSpike(id: number, carry: boolean)
	local bot = botOf(id)
	if not bot then
		return
	end
	local sim = bot.sim
	if carry then
		WeaponSim.give(sim.weapons, Spike.SLOT, Spike.ID)
	else
		SpikeSim.take(sim.spike, sim.weapons, sim.movement.tick * DT)
	end
end

-- Whether a bot means to pick the spike up: its job's to fetch it (system
-- 61). Only then does running over it pick it up.
function BotServer.fetching(id: number): boolean
	local bot = botOf(id)
	local job = if bot then bot.order else nil
	return job ~= nil and job.task == "fetch"
end

-- A bot a fallen player takes over (system 62): out of play from now, with
-- no death, its body the player's as it is (PlayerSimServer.Body): where it
-- stands and looks, its kit, the spike's slot too, and its health and
-- shield. Its guns go with it, and the arena says what its next life's on.
-- Nil if it isn't alive and in play.
function BotServer.takeOut(id: number): PlayerSimServer.Body?
	local bot = botOf(id)
	if not bot or not bot.alive or not bot.entity.health.alive then
		return nil
	end
	local sim = bot.sim
	local body: PlayerSimServer.Body = {
		feet = sim.movement.position,
		yaw = bot.yaw,
		pitch = bot.pitch,
		kit = BotTakeover.kitOf(sim.weapons),
		health = table.clone(bot.entity.health),
	}
	bot.alive = false
	bot.shown = nil
	bot.order = nil
	bot.cast = nil
	-- Nothing hurts, heals or counts it until its next life.
	bot.entity.health.alive = false
	for slot = 1, 2 do
		WeaponSim.give(sim.weapons, slot, "")
	end
	return body
end

-- Reloads the gun in a living bot's hand at once, as
-- PlayerSimServer.reloadInHand.
function BotServer.reloadInHand(id: number, most: number?)
	local bot = botOf(id)
	if bot and bot.alive then
		local w = bot.sim.weapons
		WeaponSim.reloadNow(w, w.equipped, most)
	end
end

-- One server frame, ending at server time `now` (the time this frame's
-- snapshot carries): lives started, looks taken, plans gone over and every
-- tick due by then run.
function BotServer.step(now: number)
	local started = os.clock()
	clock = now
	local asked = BotServer.situation
	local s = if asked then asked() else nil
	local w = if s then worldOf(s) else nil
	local cfg = Tuning.config()
	for _, bot in order do
		if bot.asked then
			startLife(bot)
		end
		if w and (bot.mover == nil or (bot.mover :: BotMove.Mover).nav ~= w.nav) then
			bot.mover = BotMove.new(w.nav, bot.dice)
			bot.stuckSeen = 0
		end
	end
	local seen: { Seen }? = nil
	local o: Sight.Occluders? = nil
	for _, bot in order do
		if not bot.alive then
			continue
		end
		if now >= bot.lookAt then
			seen = seen or everyone()
			o = o or occluders(now)
			look(bot, now, seen :: { Seen }, o :: Sight.Occluders, cfg)
			-- Each one's looks start somewhere in the first interval, so
			-- they're spread over its frames.
			local every = P.lookEvery.value
			bot.lookAt = if bot.lookAt == 0 then now + seeds:NextNumber() * every else bot.lookAt + every
			if bot.lookAt <= now then
				bot.lookAt = now + every
			end
		end
		if w and now >= bot.glanceAt then
			glance(bot, w, cfg)
			bot.glanceAt = now + P.glanceEvery.value
		end
	end
	if s and w and now >= thinkAt then
		thinkAt = now + P.think.value
		think(now, s, w)
	end
	local last = lastTick or now
	if now - last > MAX_CATCH_UP then
		last = now - MAX_CATCH_UP
	end
	while last + DT <= now do
		last += DT
		for _, bot in order do
			if bot.alive then
				drive(bot, last, now, cfg, w)
			end
		end
	end
	lastTick = last
	for _, bot in order do
		bot.shown = if bot.alive then MovePacer.advance(bot.pacer, now) else nil
	end
	if STUDIO then
		spent += os.clock() - started
		frames += 1
		if now - spentSince >= 1 then
			Workspace:SetAttribute(BotConfig.COST, math.floor(spent / frames * 1e5 + 0.5) / 100)
			spent, frames, spentSince = 0, 0, now
		end
	end
end

function BotServer.start()
	-- A hit from someone it didn't see turns it that way.
	table.insert(CombatServer.damageListeners, function(attacker, victim, _, how)
		local bot = byEntity[victim.id]
		local from = if attacker and attacker ~= victim then how.from else nil
		if bot and from then
			BotBrain.hurt(bot.brain, clock, from)
		end
	end)
	-- Bots see and hear as players do, and are seen.
	FogServer.bots = function(): { FogServer.Bot }
		local cfg = Tuning.config()
		local out: { FogServer.Bot } = {}
		for _, bot in order do
			local side = bot.side
			if side == nil then
				continue
			end
			local viewer: FogOfWar.Viewer? = nil
			if bot.alive and bot.entity.health.alive then
				local m = bot.sim.movement
				viewer = {
					id = bot.entity.id,
					side = side,
					eye = PlayerSim.eye(bot.sim, cfg),
					velocity = m.velocity,
					standEye = m.position + vector.create(0, cfg.standEyeHeight, 0),
					behind = 0,
				}
			end
			table.insert(out, { id = bot.entity.id, side = side, viewer = viewer })
		end
		return out
	end
	MinimapServer.bots = function(): ({ Sight.Viewer }, { Sight.Target })
		local cfg = Tuning.config()
		local viewers: { Sight.Viewer } = {}
		local targets: { Sight.Target } = {}
		for _, bot in order do
			local side = bot.side
			local pose = if side and bot.alive then bot.entity.pose() else nil
			if side and pose then
				table.insert(targets, { id = bot.entity.id, side = side, points = Sight.points(pose) })
				table.insert(viewers, { side = side, eye = PlayerSim.eye(bot.sim, cfg), look = Accuracy.aim(bot.yaw, bot.pitch) })
			end
		end
		return viewers, targets
	end
	-- Bots on no Roblox team: the sides the arena put them on.
	CombatServer.sideOf = sideOf
	-- And they cast abilities and are reached by them as players are (system
	-- 65), each known by its stand-in.
	PlayerSimServer.bots = {
		list = function(): { Instance }
			local out: { Instance } = {}
			for _, bot in order do
				table.insert(out, bot.standIn)
			end
			return out
		end,
		actorOf = function(entity: Entities.Entity): Instance?
			local bot = byEntity[entity.id]
			return if bot then bot.standIn else nil
		end,
		entityOf = function(standIn: Instance): Entities.Entity?
			local bot = byStandIn[standIn]
			return if bot then bot.entity else nil
		end,
		getSim = function(standIn: Instance): PlayerSim.State?
			local bot = byStandIn[standIn]
			return if bot then bot.sim else nil
		end,
		view = function(standIn: Instance): (vector?, vector?)
			local bot = byStandIn[standIn]
			if not bot or not bot.alive then
				return nil, nil
			end
			return PlayerSim.eye(bot.sim, Tuning.config()), Accuracy.aim(bot.yaw, bot.pitch)
		end,
		isAlive = function(standIn: Instance): boolean
			local bot = byStandIn[standIn]
			return bot ~= nil and bot.alive
		end,
		moved = function(standIn: Instance)
			local bot = byStandIn[standIn]
			if bot then
				MovePacer.reset(bot.pacer)
				bot.shown = nil
			end
		end,
	}
	-- And they play for the spike (system 61).
	SpikeServer.bots = {
		ids = BotServer.ids,
		has = BotServer.has,
		standIn = BotServer.standIn,
		sim = BotServer.getSim,
		alive = BotServer.isAlive,
		side = BotServer.side,
		fetching = BotServer.fetching,
		setSpike = BotServer.setSpike,
	}
end

return BotServer
