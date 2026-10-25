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
-- start a few seconds after each one ends. In the arena there's none.

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

local SpikeServer = {}

local layout: string? = nil -- the sites in play; nil while there's no spike
local zones: { Spike.Zone } = {}
local startAt = Spike.CourseStart
local state: State = "none"
local carrier: Player? = nil
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
local stepOff: Player? = nil

-- What players may do with it, rebuilt whenever anything changes.
local forCarrier: Spike.Context = Spike.NONE
local forOthers: Spike.Context = Spike.NONE

local function publish()
	Workspace:SetAttribute(Spike.LAYOUT, layout or "")
	Workspace:SetAttribute(Spike.STATE, state)
	Workspace:SetAttribute(Spike.CARRIER, if carrier then carrier.UserId else 0)
	Workspace:SetAttribute(Spike.POSITION, if position then Units.asVector3(position) else nil)
	Workspace:SetAttribute(Spike.PLANTED_AT, plantedAt)
	Workspace:SetAttribute(Spike.HALF, halfSaved)
	Workspace:SetAttribute(Spike.SITE, site)
	Workspace:SetAttribute(Spike.ENDED_AT, endedAt)
	if layout == nil then
		forCarrier, forOthers = Spike.NONE, Spike.NONE
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
	}
	local mine = table.clone(forOthers)
	mine.canPlant = state == "carried"
	forCarrier = mine
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Takes the spike from whoever carries it.
local function takeBack()
	local who = carrier
	carrier = nil
	carrierFeet = nil
	if who then
		PlayerSimServer.setSpike(who, false)
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

-- Hands the spike to a player: run over, or the debug give.
local function hand(player: Player)
	if carrier == player then
		return
	end
	takeBack()
	plantedAt, detonateAt, endedAt = 0, math.huge, 0
	halfSaved = false
	site = ""
	respawnAt = nil
	blastFrom = nil
	stepOff = nil
	carrier = player
	state = "carried"
	position = nil
	local sim = PlayerSimServer.getSim(player)
	carrierFeet = if sim then sim.movement.position else nil
	PlayerSimServer.setSpike(player, true)
	publish()
end

-- Which sites are in play (a key of Spike.Layouts), or none.
local function setLayout(name: string?)
	takeBack()
	layout = if name and Spike.Layouts[name] then name else nil
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

local function onAct(player: Player, act: SpikeSim.Act)
	local time = now()
	if act.kind == "planted" then
		if state ~= "carried" or carrier ~= player then
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
	elseif act.kind == "dropped" then
		if state ~= "carried" or carrier ~= player then
			return
		end
		-- Thrown a little ahead, stopped short of a wall, landing where it falls.
		local dir = vector.create(-math.sin(act.yaw), 0, -math.cos(act.yaw))
		local from = act.position + vector.create(0, 0.5, 0)
		carrier = nil -- the simulation has let go of it already
		carrierFeet = nil
		lay(from + dir * RobloxSpike.reach(from, dir, P.dropForward.value))
		stepOff = player
	elseif act.kind == "defused" then
		-- Too late if it went off first.
		if state ~= "planted" or time >= detonateAt then
			return
		end
		state = "defused"
		endedAt = time
		detonateAt = math.huge
		respawnAt = time + P.courseRespawn.value
		publish()
	elseif act.kind == "stopped" then
		if state == "planted" and not halfSaved and act.progress >= P.defuseHalf.value - EPS then
			halfSaved = true
			publish()
		end
	end
end

local function onDeath(player: Player)
	local sim = PlayerSimServer.getSim(player)
	-- A defuse cut short by death keeps its half, as one let go of does.
	if sim and state == "planted" and not halfSaved then
		if SpikeSim.defuseProgress(sim.spike, sim.movement.tick * DT) >= P.defuseHalf.value - EPS then
			halfSaved = true
			publish()
		end
	end
	if carrier == player then
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

-- Running over a spike on the ground picks it up.
local function pickUp()
	local lying = position
	if state ~= "dropped" or not lying then
		return
	end
	for _, player in Players:GetPlayers() do
		local sim = PlayerSimServer.getSim(player)
		if not sim or not PlayerSimServer.isAlive(player) then
			continue
		end
		local over = Spike.runsOver(sim.movement.position, lying)
		if player == stepOff then
			if not over then
				stepOff = nil
			end
		elseif over then
			hand(player)
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
		local sim = who and PlayerSimServer.getSim(who)
		if who and sim and PlayerSimServer.isAlive(who) and SpikeSim.carrying(sim.weapons) then
			carrierFeet = sim.movement.position
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
		respawnAt = time + P.courseRespawn.value
		publish()
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

function SpikeServer.start()
	PlayerSimServer.objectiveFor = function(player: Player): Spike.Context
		return if player == carrier then forCarrier else forOthers
	end
	PlayerSimServer.spikeGive = function(player: Player)
		if layout ~= nil and PlayerSimServer.isAlive(player) then
			hand(player)
		end
	end
	table.insert(PlayerSimServer.spikeListeners, onAct)
	table.insert(PlayerSimServer.deathListeners, onDeath)
	Players.PlayerRemoving:Connect(function(player)
		if carrier == player then
			carrier = nil -- gone, with their simulation
			lay(carrierFeet or startAt)
		end
		if stepOff == player then
			stepOff = nil
		end
	end)

	-- The course's sites while it's played on; none in the arena.
	local function course(): string?
		local arena = Workspace:GetAttribute(ArenaConfig.ON) == true
		return if not arena and Workspace:FindFirstChild("VFTestRange") then "course" else nil
	end
	Workspace:GetAttributeChangedSignal(ArenaConfig.ON):Connect(function()
		setLayout(course())
	end)
	setLayout(course())
end

return SpikeServer
