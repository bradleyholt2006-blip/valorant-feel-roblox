--!strict
-- The spike on the server (system 12): the one spike there is, kept in
-- Workspace attributes for every client (Spike.STATE and the rest).
--
-- It lies on the ground until someone runs over it, then rides in their
-- fourth slot until it's planted, dropped with G, or dropped where its
-- carrier dies. The plant and the defuse themselves run in each player's
-- simulation (SpikeSim, through PlayerSimServer), which says here what
-- happened. A planted spike counts down its 45 seconds and, unless it's
-- defused first, detonates: a sphere grows from it and kills everyone it
-- reaches, through walls.
--
-- On the course anyone can plant it and anyone can defuse it, at the two
-- sites behind the spawn (Spike.CourseSites), and a new one waits at the
-- start a few seconds after each one ends. In Skirmish there's none.
--
-- In the spike rounds (system 13; Arena runs them) it's played for, on their
-- map's sites: only the attacking side picks it up, its carrier can plant
-- it only while a round is live, only the defending side can defuse it, and
-- the rounds hear when it's planted, defused or goes off. A new one waits in
-- front of the attackers as each round starts, and none before. Each match
-- is on one of the rounds' maps (system 25), and Arena says which. Every
-- player's context carries the Ultimate Orbs up too (system 49), as
-- OrbServer says, for their simulation to take.
--
-- Bots play for it as players do (system 61): each is told what it may do
-- with it each tick and plants and defuses it in its own simulation
-- (BotServer, which says here what happened), and dies with it as a player
-- does. Who carries it goes by their id in the rules, a player's UserId or
-- a bot's. A bot picks it up only when it means to (its job is to fetch
-- it, BotTeam), so it never takes it from under a player who's going for
-- it. A bot a fallen player takes over (system 62) hands them the spike it
-- carries as their life in its body starts (botTaken).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local MovementConfig = require(Shared.Movement.MovementConfig)
local Spike = require(Shared.Spike.Spike)
local SpikeSim = require(Shared.Spike.SpikeSim)
local RobloxSpike = require(Shared.Spike.RobloxSpike)
local Units = require(Shared.Units)

local PlayerCodec = require(Shared.Net.PlayerCodec)
local PlayerSim = require(Shared.PlayerSim)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)

local DT = 1 / MovementConfig.TickRate.value
local P = Spike.Params
-- A spike let go of with no ground this far below has fallen out of the
-- world, and goes back to the start.
local FALL_DEPTH = 50 -- metres
-- How tall a player is, for whether the blast touches them: it reaches the
-- nearest point between their feet and the top of their head.
local BODY_HEIGHT = 1.8 -- metres (estimate)
local EPS = 1e-9

export type State = "none" | "carried" | "dropped" | "planted" | "defused" | "detonated"

-- What the spike rounds hear of the spike, at server time.
export type Events = {
	planted: (detonateAt: number) -> (),
	defused: (time: number) -> (),
	detonated: (time: number) -> (),
}

local SpikeServer = {}

-- Called with each plant and defuse that counts, and who made it (system
-- 17: the ultimate's points): a player, or a bot's stand-in (system 65).
SpikeServer.objectiveListeners = {} :: { (Instance, "planted" | "defused") -> () }

-- The bots (system 61, BotServer): their ids in the rules, whether one's
-- still there, its stand-in, its simulation, life and side, whether it
-- means to pick the spike up, and putting the spike in its fourth slot or
-- taking it out.
export type Bots = {
	ids: () -> { number },
	has: (id: number) -> boolean,
	standIn: (id: number) -> Configuration?,
	sim: (id: number) -> PlayerSim.State?,
	alive: (id: number) -> boolean,
	side: (id: number) -> number?,
	fetching: (id: number) -> boolean,
	setSpike: (id: number, carry: boolean) -> (),
}
SpikeServer.bots = nil :: Bots?

-- The spike as the bots' plans know it (system 61): what it's doing, where
-- it lies or was planted (metres, in the place), who carries it (their id
-- in the rules), the site it's planted at, when it goes off and whether a
-- defuse has passed its half.
export type View = {
	state: State,
	position: vector?,
	carrier: number?,
	site: string,
	detonateAt: number,
	halfSaved: boolean,
}

local layout: string? = nil -- the sites in play; nil while there's no spike
local zones: { Spike.Zone } = {}
local startAt = Spike.CourseStart
local state: State = "none"
local carrier: number? = nil -- who carries it, by their id in the rules
local carrierFeet: vector? = nil -- where the carrier was last frame
local position: vector? = nil -- metres: lying, planted, or where it ended
local plantedAt = 0
local detonateAt = math.huge
local halfSaved = false
local site = ""
local endedAt = 0
local respawnAt: number? = nil
local blastFrom: number? = nil -- while the blast grows: when it started
-- Dropped it and hasn't stepped off it yet, so doesn't pick it straight up.
local stepOff: number? = nil
-- The spike rounds, while they're played: who hears of the spike, the side
-- attacking (0 on the course: anyone may carry and defuse it) and whether a
-- plant is open.
local events: Events? = nil
local roundsLayout: string? = nil -- their map's sites
local attackers = 0
local plantOpen = true

-- The Ultimate Orbs up (system 49, OrbServer), which anyone may take.
local orbs: { [number]: vector }? = nil

-- What players may do with it, rebuilt whenever anything changes: its
-- carrier, those who may defuse it, and those who may not.
local forCarrier: Spike.Context = Spike.NONE
local forOthers: Spike.Context = Spike.NONE
local forBystanders: Spike.Context = Spike.NONE

local function publish()
	Workspace:SetAttribute(Spike.LAYOUT, layout or "")
	Workspace:SetAttribute(Spike.STATE, state)
	Workspace:SetAttribute(Spike.CARRIER, carrier or 0)
	Workspace:SetAttribute(Spike.POSITION, if position then Units.asVector3(position) else nil)
	Workspace:SetAttribute(Spike.PLANTED_AT, plantedAt)
	Workspace:SetAttribute(Spike.HALF, halfSaved)
	Workspace:SetAttribute(Spike.SITE, site)
	Workspace:SetAttribute(Spike.ENDED_AT, endedAt)
	Workspace:SetAttribute(Spike.PLANT_OPEN, plantOpen)
	Workspace:SetAttribute(Spike.DEFUSERS, if attackers == 0 then 0 else 3 - attackers)
	if layout == nil then
		forCarrier, forOthers, forBystanders = Spike.NONE, Spike.NONE, Spike.NONE
		return
	end
	local planted = if state == "planted" then position else nil
	forOthers = {
		zones = zones,
		canPlant = false,
		canDefuse = planted ~= nil,
		planted = planted,
		halfSaved = halfSaved,
		sees = RobloxSpike.sees,
		orbs = orbs,
	}
	local mine = table.clone(forOthers)
	mine.canPlant = state == "carried" and plantOpen
	forCarrier = mine
	local theirs = table.clone(forOthers)
	theirs.canDefuse = false
	forBystanders = theirs
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Players and bots alike, by their ids in the rules: a player, if it's
-- one, and anyone's simulation, life and side.
local function playerOf(id: number): Player?
	return if PlayerCodec.isBotRule(id) then nil else Players:GetPlayerByUserId(id)
end

local function simOf(id: number): PlayerSim.State?
	local player = playerOf(id)
	local bots = SpikeServer.bots
	if player then
		return PlayerSimServer.getSim(player)
	end
	return if bots then bots.sim(id) else nil
end

local function isAlive(id: number): boolean
	local player = playerOf(id)
	local bots = SpikeServer.bots
	if player then
		return PlayerSimServer.isAlive(player)
	end
	return bots ~= nil and bots.alive(id)
end

local function sideOf(id: number): number?
	local player = playerOf(id)
	local bots = SpikeServer.bots
	if not player then
		return if bots then bots.side(id) else nil
	end
	local side = player:GetAttribute(ArenaConfig.SIDE)
	return if typeof(side) == "number" then side else nil
end

-- Whether someone may pick the spike up: the attackers in the spike
-- rounds, anyone on the course.
local function mayCarry(id: number): boolean
	return attackers == 0 or sideOf(id) == attackers
end

-- Whether someone may defuse it: the defenders in the spike rounds, anyone
-- on the course.
local function mayDefuse(id: number): boolean
	return attackers == 0 or sideOf(id) == 3 - attackers
end

-- Puts the spike in someone's fourth slot, or takes it out.
local function setSpike(id: number, carry: boolean)
	local player = playerOf(id)
	local bots = SpikeServer.bots
	if player then
		PlayerSimServer.setSpike(player, carry)
	elseif bots then
		bots.setSpike(id, carry)
	end
end

-- Takes the spike from whoever carries it.
local function takeBack()
	local who = carrier
	carrier = nil
	carrierFeet = nil
	if who then
		setSpike(who, false)
	end
end

-- Puts the spike down at `point`, on the ground under it, or back where it
-- starts if there's none.
local function lay(point: vector)
	takeBack()
	state = "dropped"
	position = RobloxSpike.ground(point, FALL_DEPTH) or startAt
	publish()
end

-- A new spike, waiting at the start.
local function fresh()
	plantedAt, detonateAt, endedAt = 0, math.huge, 0
	halfSaved = false
	site = ""
	respawnAt = nil
	blastFrom = nil
	stepOff = nil
	lay(startAt)
end

-- Hands the spike to someone: run over, or the debug give.
local function hand(id: number)
	if carrier == id then
		return
	end
	takeBack()
	plantedAt, detonateAt, endedAt = 0, math.huge, 0
	halfSaved = false
	site = ""
	respawnAt = nil
	blastFrom = nil
	stepOff = nil
	carrier = id
	state = "carried"
	position = nil
	local sim = simOf(id)
	carrierFeet = if sim then sim.movement.position else nil
	setSpike(id, true)
	publish()
end

-- Which sites are in play (a key of Spike.Layouts), or none. A new spike
-- if they change.
local function setLayout(name: string?)
	local wanted = if name and Spike.Layouts[name] then name else nil
	if wanted == layout then
		return
	end
	takeBack()
	layout = wanted
	zones = if layout then Spike.Layouts[layout] else {}
	if layout then
		fresh()
	else
		state = "none"
		position = nil
		respawnAt = nil
		blastFrom = nil
		publish()
	end
end

-- The plant or the defuse that counts, to whoever hears of who made it: a
-- player, or a bot's stand-in (system 65).
local function made(id: number, kind: "planted" | "defused")
	local bots = SpikeServer.bots
	local player: Instance? = playerOf(id) or (if bots then bots.standIn(id) else nil)
	if player then
		for _, listener in SpikeServer.objectiveListeners do
			listener(player, kind)
		end
	end
end

local function onAct(id: number, act: SpikeSim.Act)
	local time = now()
	if act.kind == "planted" then
		if state ~= "carried" or carrier ~= id then
			return
		end
		carrier = nil
		carrierFeet = nil
		state = "planted"
		position = act.position
		site = act.site or ""
		plantedAt = time
		detonateAt = time + P.detonateTime.value
		halfSaved = false
		publish()
		made(id, "planted")
		if events then
			events.planted(detonateAt)
		end
	elseif act.kind == "dropped" then
		if state ~= "carried" or carrier ~= id then
			return
		end
		-- Thrown a little ahead, stopped short of a wall, landing where it falls.
		local dir = vector.create(-math.sin(act.yaw), 0, -math.cos(act.yaw))
		local from = act.position + vector.create(0, 0.5, 0)
		carrier = nil -- the simulation has let go of it already
		carrierFeet = nil
		lay(from + dir * RobloxSpike.reach(from, dir, P.dropForward.value))
		stepOff = id
	elseif act.kind == "defused" then
		-- Too late if it went off first.
		if state ~= "planted" or time >= detonateAt then
			return
		end
		state = "defused"
		endedAt = time
		detonateAt = math.huge
		-- The spike rounds put a new one down as the next round starts.
		respawnAt = if events then nil else time + P.courseRespawn.value
		publish()
		made(id, "defused")
		if events then
			events.defused(time)
		end
	elseif act.kind == "stopped" then
		if state == "planted" and not halfSaved and act.progress >= P.defuseHalf.value - EPS then
			halfSaved = true
			publish()
		end
	end
end

-- A defuse cut short keeps its half, as one let go of does: by a death, or
-- by its bot's body taken over (system 62).
local function keepHalf(sim: PlayerSim.State?)
	if sim and state == "planted" and not halfSaved then
		if SpikeSim.defuseProgress(sim.spike, sim.movement.tick * DT) >= P.defuseHalf.value - EPS then
			halfSaved = true
			publish()
		end
	end
end

local function onDeath(id: number)
	local sim = simOf(id)
	keepHalf(sim)
	if carrier == id then
		lay(if sim then sim.movement.position else carrierFeet or startAt)
	end
end

-- The nearest point of someone standing at `feet` to `point`.
local function nearestOf(feet: vector, point: vector): vector
	return vector.create(feet.x, math.clamp(point.y, feet.y, feet.y + BODY_HEIGHT), feet.z)
end

-- The blast, while it grows: everyone it has reached dies.
local function blast(time: number, from: number)
	local centre = position
	if not centre then
		blastFrom = nil
		return
	end
	local grown = (time - from) / P.blastGrowTime.value
	local radius = P.blastRadius.value * math.min(grown, 1)
	for _, entity in Entities.all() do
		if not entity.health.alive then
			continue
		end
		local feet: vector?
		if entity.sim then
			feet = entity.sim.movement.position
		else
			local pose = entity.pose()
			feet = if pose then pose.position else nil
		end
		if feet and vector.magnitude(nearestOf(feet, centre) - centre) <= radius then
			CombatServer.kill(entity, Spike.ID)
		end
	end
	if grown >= 1 then
		blastFrom = nil
	end
end

-- Running over a spike on the ground picks it up, for anyone in play: a
-- player, or a bot that means to.
local function pickUp()
	local lying = position
	if state ~= "dropped" or not lying then
		return
	end
	local function over(id: number, sim: PlayerSim.State): boolean
		local on = Spike.runsOver(sim.movement.position, lying)
		if id == stepOff then
			if not on then
				stepOff = nil
			end
			return false
		end
		return on and mayCarry(id)
	end
	for _, player in Players:GetPlayers() do
		local sim = PlayerSimServer.getSim(player)
		if sim and PlayerSimServer.inPlay(player) and over(player.UserId, sim) then
			hand(player.UserId)
			return
		end
	end
	local bots = SpikeServer.bots
	if not bots then
		return
	end
	for _, id in bots.ids() do
		local sim = bots.sim(id)
		if sim and bots.alive(id) and bots.fetching(id) and over(id, sim) then
			hand(id)
			return
		end
	end
end

-- Once a server frame, after the players' moves, at server time `time`.
function SpikeServer.step(time: number)
	if layout == nil then
		return
	end
	if state == "carried" then
		local who = carrier
		local sim = if who then simOf(who) else nil
		if who and sim and isAlive(who) and SpikeSim.carrying(sim.weapons) then
			carrierFeet = sim.movement.position
		elseif who and PlayerCodec.isBotRule(who) and not (SpikeServer.bots and SpikeServer.bots.has(who)) then
			-- A bot gone, with its simulation: where it was.
			carrier = nil
			lay(carrierFeet or startAt)
		else
			-- Lost some other way (a fall out of the world starts a new
			-- life): back to the start.
			lay(startAt)
		end
	end
	pickUp()
	if state == "planted" and time >= detonateAt then
		state = "detonated"
		endedAt = time
		detonateAt = math.huge
		blastFrom = time
		respawnAt = if events then nil else time + P.courseRespawn.value
		publish()
		-- The round is the attackers' before the blast kills anyone.
		if events then
			events.detonated(time)
		end
	end
	local from = blastFrom
	if from then
		blast(time, from)
	end
	local again = respawnAt
	if again and time >= again and blastFrom == nil then
		fresh()
	end
end

-- The sites in play: the spike rounds' map's while they're played; the
-- course's while it's played on; none in Skirmish.
local function wanted(): string?
	if events then
		return roundsLayout
	end
	local arena = Workspace:GetAttribute(ArenaConfig.ON) == true
	return if not arena and Workspace:FindFirstChild("VFTestRange") then "course" else nil
end

-- The spike rounds start (Arena) on the map whose sites are `sites` (a key
-- of Spike.Layouts), with the spike starting at `start`, telling `e` what
-- happens to it.
function SpikeServer.startRounds(e: Events, sites: string, start: vector)
	events = e
	roundsLayout = sites
	startAt = start
	setLayout(wanted())
end

-- The spike rounds' next match is on another map (system 25): its sites,
-- and a new spike at its start.
function SpikeServer.setMap(sites: string, start: vector)
	if events == nil then
		return
	end
	roundsLayout = sites
	startAt = start
	setLayout(wanted())
end

-- The spike rounds are over: back to the course's spike, or none.
function SpikeServer.stopRounds()
	events = nil
	roundsLayout = nil
	attackers = 0
	plantOpen = true
	startAt = Spike.CourseStart
	setLayout(wanted())
	publish()
end

-- The spike rounds' side attacking this round, and whether a plant is open.
function SpikeServer.setRound(attacking: number, open: boolean)
	if attacking == attackers and open == plantOpen then
		return
	end
	attackers = attacking
	plantOpen = open
	publish()
end

-- The Ultimate Orbs up, by number, where each stands (system 49), for
-- everyone's simulation to take; nil for none.
function SpikeServer.setOrbs(up: { [number]: vector }?)
	orbs = up
	publish()
end

-- A new spike at the start, as a round of the spike rounds starts.
function SpikeServer.reset()
	if layout ~= nil then
		fresh()
	end
end

-- What someone may do with the spike this tick, by their id in the rules:
-- a player's simulation is told (PlayerSimServer), and a bot's (system 61,
-- BotServer).
function SpikeServer.objectiveOf(id: number): Spike.Context
	if id == carrier then
		return forCarrier
	end
	return if mayDefuse(id) then forOthers else forBystanders
end

-- What happened with the spike in a bot's simulation (system 61): a plant,
-- a defuse, or a defuse let go of.
function SpikeServer.botActed(id: number, act: SpikeSim.Act)
	onAct(id, act)
end

-- A bot's death (system 61), as a player's: the half of a defuse it cut
-- short is kept, and the spike it carried lies where it fell.
function SpikeServer.botDied(id: number)
	onDeath(id)
end

-- A bot a fallen player has taken over (system 62), as their life in its
-- body starts: the half of a defuse it reached is kept, as at a death, and
-- the spike it carried is theirs (`to`, their id in the rules).
function SpikeServer.botTaken(id: number, to: number)
	keepHalf(simOf(id))
	if carrier == id then
		hand(to)
	end
end

-- Someone out of play with no death: gone from the server (`left`, with
-- their simulation), or taken out of the match while they stay in it
-- (system 69). The spike they carried lies where they were, and the half
-- of a defuse they reached is kept.
function SpikeServer.gone(id: number, left: boolean)
	local sim = if left then nil else simOf(id)
	keepHalf(sim)
	if carrier == id then
		if left then
			carrier = nil -- gone, with their simulation
		end
		lay(if sim then sim.movement.position else carrierFeet or startAt)
	end
	if stepOff == id then
		stepOff = nil
	end
end

-- The spike as the bots' plans know it, in the spike rounds; nil else.
function SpikeServer.view(): View?
	if layout == nil or events == nil then
		return nil
	end
	return {
		state = state,
		position = position,
		carrier = carrier,
		site = site,
		detonateAt = detonateAt,
		halfSaved = halfSaved,
	}
end

function SpikeServer.start()
	PlayerSimServer.objectiveFor = function(player: Player): Spike.Context
		return SpikeServer.objectiveOf(player.UserId)
	end
	PlayerSimServer.spikeGive = function(player: Player)
		-- In the spike rounds, never one that's planted or has gone off.
		local free = events == nil or state == "dropped" or state == "carried"
		if layout ~= nil and free and PlayerSimServer.isAlive(player) and mayCarry(player.UserId) then
			hand(player.UserId)
		end
	end
	table.insert(PlayerSimServer.spikeListeners, function(player: Player, act: SpikeSim.Act)
		onAct(player.UserId, act)
	end)
	table.insert(PlayerSimServer.deathListeners, function(player: Player)
		onDeath(player.UserId)
	end)
	Players.PlayerRemoving:Connect(function(player)
		SpikeServer.gone(player.UserId, true)
	end)

	Workspace:GetAttributeChangedSignal(ArenaConfig.ON):Connect(function()
		setLayout(wanted())
	end)
	setLayout(wanted())
	publish()
end

return SpikeServer
