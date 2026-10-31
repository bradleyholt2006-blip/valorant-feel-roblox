--!strict
-- Sova's Owl Drone on the server (system 47). The drone flies in its
-- owner's simulation (AbilitySim.droneThrough, DroneSim), so the server's
-- run of his moves flies it too; this shows it to everyone else, takes its
-- health and judges its darts.
--   * from the tick it's sent out to the one its flight's over, the drone
--     is in the snapshots as no entity's (PlayerCodec.DRONE_BASE + n,
--     Replication.extras), its middle paced as a player's is (MovePacer),
--     looking the way he looks. His side has it, and on the course everyone
--     does; an enemy in play has it while it's near enough their eye to
--     hear (heard; SOVA_TRACKER: 'Makes noise because of engine rotors.')
--     or the level's not in the way, for the fog of war's hold after
--     (FogServer.others), and one who's down has what their side in play
--     has. Every one of them hears it, where they have it (DroneView)
--   * it stands in the level shots and swings are traced through, as the
--     attacker's screen showed it (CombatServer.levelAt and posed), and
--     stops every bullet: an enemy's bullet or knife that strikes it takes
--     its damage off its health, and at none it breaks, its flight over
--     (PlayerSim.downed), which everyone who has it hears of ("dronedown");
--     his side's do nothing (Patch 5.12: 'The following abilities are now
--     immune to allied damage.'), and on the course anyone's does
--   * a dart (a "dart" cast in his tick) goes at once from its middle
--     along his crosshair, as far as its range, through nothing, at whoever
--     his screen showed there (CombatServer.rewound, as for a bullet): an
--     enemy in play, a dummy, and on the course anyone but him. While the
--     spawns' barriers are up it strikes nobody, as for Hunter's Fury's
--     blasts. He and whoever it struck are told of it ("dart"), as are
--     those who'd hear it or have the drone
--   * whoever it struck is revealed to his side by each of its pings, the
--     first at firstPing after it struck and the rest pingEvery apart
--     (ReconServer.reveal, as for a Recon Bolt's pulse), even once the
--     drone's gone: his side is told whom and where ("dartping"), he alone
--     on the course, and whoever it struck hears each one
-- A new round ends every flight and every dart's pings (Arena). While his
-- drone flies its id in the snapshots is his `VFDroneId` attribute, and
-- the health it has left his `VFDroneHealth`; where his last dart ended is
-- his `VFLastDart` (metres) and whom it struck his `VFDartHit` (a name, ""
-- for nobody), which scripted checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local DroneSim = require(Shared.Abilities.DroneSim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local FogOfWar = require(Shared.Combat.FogOfWar)
local LagCompensation = require(Shared.Combat.LagCompensation)
local Penetration = require(Shared.Combat.Penetration)
local ShotResolver = require(Shared.Combat.ShotResolver)
local MovementConfig = require(Shared.Movement.MovementConfig)
local MovePacer = require(Shared.Net.MovePacer)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local PlayerSim = require(Shared.PlayerSim)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local FogServer = require(script.Parent.FogServer)
local ReconServer = require(script.Parent.ReconServer)
local Replication = require(script.Parent.Replication)
local Tuning = require(script.Parent.Tuning)

local DroneServer = {}

local DR = AbilityConfig.OwlDrone
local DT = 1 / MovementConfig.TickRate.value
local P = FogOfWar.Params

-- A drone in flight: whose (the player, their entity id and their side,
-- nil on the course), its id in the snapshots, when it was sent out (the
-- kit's droneFrom), its poses after each tick and the one this frame's
-- snapshot shows, the health it has left, and until when (server time)
-- each enemy has it.
type Flight = {
	player: Player,
	owner: number,
	side: number?,
	id: number,
	from: number,
	pacer: MovePacer.Pacer,
	shown: PlayerCodec.Pose?,
	health: number,
	seenBy: { [Player]: number },
}

-- A dart that struck someone: whose (as for a flight), its id (the tick it
-- went in), whom it struck, when (server time) and how many pings it's
-- given.
type Tag = {
	player: Player,
	owner: number,
	side: number?,
	id: number,
	target: number,
	at: number,
	pinged: number,
}

local flights: { [Player]: Flight } = {}
local byId: { [number]: Flight } = {}
local tags: { Tag } = {}
local numbered = 0
local frameNow = 0
local lookAt = 0
-- The drone a dart's going from, left out of the level it's traced
-- through (where his screen showed it, it may be in the dart's way).
local skipping: number? = nil

local function sideOf(player: Player): number?
	local side = player:GetAttribute(ArenaConfig.SIDE)
	return if typeof(side) == "number" then side else nil
end

-- Whether the spawns' barriers are up: the arena's buy phase, or Team
-- Deathmatch's pre-game.
local function held(): boolean
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return false
	end
	local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
	local phase = if arena then arena:GetAttribute("Phase") else nil
	return phase == "buy" or phase == "pregame"
end

-- The flight of `player`'s drone (`owner` is their entity id), sent out at
-- `from`, with its health whole.
local function begin(player: Player, owner: number, from: number): Flight
	numbered = numbered % PlayerCodec.DRONE_LIMIT + 1
	local f: Flight = {
		player = player,
		owner = owner,
		side = sideOf(player),
		id = PlayerCodec.DRONE_BASE + numbered,
		from = from,
		pacer = MovePacer.new(),
		shown = nil,
		health = DR.health.value,
		seenBy = {},
	}
	flights[player] = f
	byId[f.id] = f
	player:SetAttribute(DroneSim.ID_ATTRIBUTE, f.id)
	player:SetAttribute(DroneSim.HEALTH_ATTRIBUTE, f.health)
	return f
end

-- `f`'s flight over: it's no longer shown, flown or struck.
local function drop(f: Flight)
	if flights[f.player] == f then
		flights[f.player] = nil
	end
	byId[f.id] = nil
	if f.player.Parent then
		f.player:SetAttribute(DroneSim.ID_ATTRIBUTE, nil)
	end
end

-- The drone's pose after a tick of `input`'s: its middle, and the way he
-- looks.
local function poseOf(f: Flight, kit: AbilitySim.State, input: PlayerCodec.WireInput): PlayerCodec.Pose
	return {
		id = f.id,
		position = kit.dronePos,
		yaw = input.yaw,
		pitch = math.clamp(input.pitch, -math.pi / 2, math.pi / 2),
		crouchAlpha = 0,
		grounded = false,
		alive = true,
		quiet = true,
		reloading = false,
		weapon = 0,
		channel = 0,
		gliding = false,
	}
end

-- Whom a dart of `f`'s can strike: enemies in play, the dummies, and on
-- the course anyone; never anyone spawn protection keeps it off.
local function strikes(f: Flight): (Entities.Entity) -> boolean
	return function(entity: Entities.Entity): boolean
		local protected = CombatServer.protected
		if protected and protected(entity) then
			return false
		end
		local player = entity.player
		if not player then
			return true
		end
		return PlayerSimServer.inPlay(player) and (f.side == nil or sideOf(player) ~= f.side)
	end
end

-- A dart of `f`'s ("dart", in his tick of `viewTime`), at once: whom it
-- struck, as his screen showed them, tagged for its pings, and who's told.
local function dart(f: Flight, cast: AbilitySim.Cast, viewTime: number)
	local entity = Entities.get(f.owner)
	if not entity then
		return
	end
	local now = Workspace:GetServerTimeNow()
	skipping = f.id
	local level = CombatServer.levelFor(viewTime)
	skipping = nil
	local trace = Penetration.trace(level, cast.origin, cast.direction, "none", DR.dartRange.value)
	local rewound = CombatServer.rewound(entity, viewTime, strikes(f))
	local hit = if held()
		then nil
		else ShotResolver.resolve(cast.origin, cast.direction, LagCompensation.shotTargets(rewound), trace.stop, entity.id)
	local victim = if hit then Entities.get(hit.targetId) else nil
	local to = if hit then hit.point else cast.origin + cast.direction * trace.stop
	if victim then
		table.insert(tags, {
			player = f.player,
			owner = f.owner,
			side = f.side,
			id = cast.tick,
			target = victim.id,
			at = now,
			pinged = 0,
		})
	end
	if f.player.Parent then
		f.player:SetAttribute(DroneSim.DART_ATTRIBUTE, Units.asVector3(to))
		f.player:SetAttribute(DroneSim.HIT_ATTRIBUTE, if victim then victim.name else "")
	end
	local event: { [string]: any } = {
		entity = f.owner,
		ability = "owldrone",
		kind = "dart",
		id = cast.tick,
		at = now,
		drone = f.id,
		origin = Units.asVector3(cast.origin),
		to = Units.asVector3(to),
		hit = victim ~= nil,
		struck = if victim then victim.id else nil,
	}
	local remote = Remotes.get().Ability
	for _, other in Players:GetPlayers() do
		local theirs = victim ~= nil and victim.player == other
		if other == f.player or theirs or FogServer.hears(other, cast.origin, FogOfWar.Edges.cast, f.id) then
			remote:FireClient(other, event)
		end
	end
end

-- A ping of `tag`'s at `now`: whoever its dart struck, while they're alive
-- and in play, revealed to its owner's side for the reveal's time.
local function ping(tag: Tag, now: number)
	tag.pinged += 1
	local victim = Entities.get(tag.target)
	local pose = if victim then victim.pose() else nil
	if not victim or not pose or not victim.health.alive then
		return
	end
	local player = victim.player
	if player and not PlayerSimServer.inPlay(player) then
		return
	end
	if tag.side ~= nil then
		ReconServer.reveal(tag.side, tag.target, now + DR.reveal.value)
	end
	local heard: { [string]: any } = {
		entity = tag.owner,
		ability = "owldrone",
		kind = "dartping",
		id = tag.id,
		at = now,
		index = tag.pinged,
		target = tag.target,
	}
	local told = table.clone(heard)
	told.ids = { tag.target }
	told.poses = { { id = tag.target, position = Units.asVector3(pose.position), yaw = pose.yaw, crouch = pose.crouchAlpha } }
	local remote = Remotes.get().Ability
	for _, other in Players:GetPlayers() do
		local ours = if tag.side == nil then other == tag.player else sideOf(other) == tag.side
		if ours then
			remote:FireClient(other, told)
		elseif other == player then
			remote:FireClient(other, heard)
		end
	end
end

-- After each tick of a player's: their drone's flight begun, flown or
-- over, and its darts.
local function onTick(player: Player, input: PlayerCodec.WireInput, casts: { AbilitySim.Cast }?)
	local sim = PlayerSimServer.getSim(player)
	local entity = PlayerSimServer.entityOf(player)
	if not sim or not entity then
		return
	end
	local kit = sim.abilities
	local had = flights[player]
	if had and kit.droneFrom ~= had.from then
		drop(had)
	end
	if not AbilitySim.droning(kit) then
		return
	end
	local f = flights[player] or begin(player, entity.id, kit.droneFrom)
	MovePacer.push(f.pacer, input.seq * DT, poseOf(f, kit, input))
	if not casts then
		return
	end
	for _, cast in casts do
		if cast.kind == "dart" and cast.ability == "owldrone" then
			dart(f, cast, input.viewTime)
		end
	end
end

-- A bullet or a knife of `attacker`'s that struck a drone (`key`, its
-- piece), for `amount`: the drone takes it, but from its owner's side, and
-- at nothing breaks where the attacker's screen showed it. Until then he's
-- told where it came from, as for a hit on him (system 54; Patch 12.02:
-- 'new UI damage indicators that display for objects that take damage
-- while controlled by a player').
local function struck(attacker: Entities.Entity, key: any, amount: number)
	local piece = DroneSim.piece(key)
	local f = if piece then byId[piece.id] else nil
	if not piece or not f or amount <= 0 then
		return
	end
	local owner = Entities.get(f.owner)
	if owner and CombatServer.teammates(attacker, owner) then
		return
	end
	f.health = math.max(f.health - amount, 0)
	if f.player.Parent then
		f.player:SetAttribute(DroneSim.HEALTH_ATTRIBUTE, f.health)
	end
	if f.health > 0 then
		if attacker.sim and f.player.Parent then
			CombatServer.tellHurt(f.player, PlayerSim.eye(attacker.sim, Tuning.config()), piece.box.center)
		end
		return
	end
	local sim = PlayerSimServer.getSim(f.player)
	local t = PlayerSimServer.timeOf(f.player)
	if sim and t then
		PlayerSim.downed(sim, t)
		PlayerSimServer.markDirty(f.player)
	end
	local at = piece.box.center
	local event = {
		entity = f.owner,
		ability = "owldrone",
		kind = "dronedown",
		id = f.id,
		at = Workspace:GetServerTimeNow(),
		point = Units.asVector3(at),
	}
	local remote = Remotes.get().Ability
	for _, other in Players:GetPlayers() do
		if other == f.player or FogServer.hears(other, at, FogOfWar.Edges.cast, f.id) then
			remote:FireClient(other, event)
		end
	end
	drop(f)
end

-- Whether `player`'s snapshots carry `id`, if it's a drone's (nil if it
-- isn't): its owner's side's, its owner's alone on the course, and an
-- enemy's while they have it.
local function carries(player: Player, id: number): boolean?
	if not PlayerCodec.isDrone(id) then
		return nil
	end
	local f = byId[id]
	if not f then
		return false
	end
	if player == f.player or f.side == nil then
		return true
	end
	local side = sideOf(player)
	if side == f.side then
		return true
	end
	if PlayerSimServer.inPlay(player) then
		return (f.seenBy[player] or 0) > frameNow
	end
	for mate, untilAt in f.seenBy do
		if untilAt > frameNow and mate.Parent and sideOf(mate) == side and PlayerSimServer.inPlay(mate) then
			return true
		end
	end
	return false
end

-- Each enemy in play's look at the drones, every look of the fog of war's:
-- one near enough their eye to hear, or with the level not in the way, is
-- theirs for its hold.
local function look(now: number)
	local eyes: { { player: Player, side: number, eye: vector } } = {}
	for _, player in Players:GetPlayers() do
		local side = sideOf(player)
		local eye = if side ~= nil and PlayerSimServer.inPlay(player) then PlayerSimServer.view(player) else nil
		if side ~= nil and eye then
			table.insert(eyes, { player = player, side = side, eye = eye })
		end
	end
	for _, f in flights do
		local shown = f.shown
		if not shown or f.side == nil then
			continue
		end
		for _, e in eyes do
			if e.side == f.side then
				continue
			end
			if vector.magnitude(e.eye - shown.position) <= DR.heard.value or not FogServer.blocked(e.eye, shown.position) then
				f.seenBy[e.player] = now + P.hold.value
			end
		end
	end
end

-- Once a server frame, at server time `now`, after the moves: the flights
-- whose owner's gone, died or ended it dropped, the rest paced, the drones
-- looked at when a look's due, and the pings due given.
function DroneServer.step(now: number)
	frameNow = now
	for player, f in flights do
		local sim = PlayerSimServer.getSim(player)
		if not player.Parent or not sim or not PlayerSimServer.isAlive(player) or sim.abilities.droneFrom ~= f.from then
			drop(f)
		else
			f.shown = MovePacer.advance(f.pacer, now)
		end
	end
	if now >= lookAt and next(flights) ~= nil then
		lookAt = now + P.every.value
		look(now)
	end
	for i = #tags, 1, -1 do
		local tag = tags[i]
		while tag.pinged < DR.pings.value and now >= tag.at + DR.firstPing.value + tag.pinged * DR.pingEvery.value do
			ping(tag, now)
		end
		if tag.pinged >= DR.pings.value then
			table.remove(tags, i)
		end
	end
end

-- Every flight over (a new round), as if broken, and every dart's pings.
function DroneServer.clear()
	for player, f in flights do
		local sim = PlayerSimServer.getSim(player)
		local t = PlayerSimServer.timeOf(player)
		if sim and t and sim.abilities.droneFrom == f.from then
			PlayerSim.downed(sim, t)
			PlayerSimServer.markDirty(player)
		end
		drop(f)
	end
	table.clear(tags)
end

-- After ReconServer's start, whose shafts are in the level shots are
-- traced through before the drones.
function DroneServer.start()
	-- Bots don't play the Owl Drone yet (system 65).
	table.insert(PlayerSimServer.tickListeners, function(actor: PlayerSimServer.Actor, input: any, casts: { AbilitySim.Cast }?)
		if actor:IsA("Player") then
			onTick(actor, input, casts)
		end
	end)
	local levelBefore = CombatServer.levelAt
	CombatServer.levelAt = function(base: Penetration.Level, viewTime: number): Penetration.Level
		local level = if levelBefore then levelBefore(base, viewTime) else base
		if next(byId) == nil then
			return level
		end
		local posed = CombatServer.posed(viewTime, function(id: number): boolean
			return byId[id] ~= nil
		end)
		local drones: { DroneSim.Posed } = {}
		for _, target in posed do
			table.insert(drones, { id = target.id, position = target.pose.position })
		end
		return DroneSim.level(level, drones, skipping)
	end
	local struckBefore = CombatServer.struck
	CombatServer.struck = function(attacker: Entities.Entity, key: any, amount: number)
		if DroneSim.piece(key) then
			struck(attacker, key, amount)
		elseif struckBefore then
			struckBefore(attacker, key, amount)
		end
	end
	table.insert(Replication.extras, function(): { PlayerCodec.Pose }
		local out: { PlayerCodec.Pose } = {}
		for _, f in flights do
			local shown = f.shown
			if shown then
				table.insert(out, shown)
			end
		end
		return out
	end)
	FogServer.others = carries
end

return DroneServer
