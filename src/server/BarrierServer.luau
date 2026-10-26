--!strict
-- Sage's Barrier Orb on the server (system 38). Each wall raised (a
-- "barrier" cast) goes up here where the caster's simulation placed it as
-- the cast's tick ran, from the server's time then (BarrierSim.raise); a
-- segment that would touch the planted spike breaks as it rises. Every
-- client is told of it (the Ability remote's "barrier": its segments, when
-- it rises, and where, for its sound), and of each segment that breaks
-- ("break"). The walls are kept here for the simulation
-- (PlayerSimServer.barriers, and the practice dummies'): everyone moves
-- through them as the server time their screen showed has them
-- (SlowSim.judged), as their own prediction does, and none goes up in the
-- buy phase (Patch 1.14). Shots and swings are traced through them as the
-- attacker's screen showed them (CombatServer.levelAt), and nobody sees
-- through them (BarrierServer.standing, for the minimap's spotting and the
-- Healing Orb's aim).
--
-- Each segment's health is kept here: 400 as it forms, fortified to 600
-- less what it's lost 2 s after it's raised, and decaying to nothing over
-- the wall's last 5 s (BarrierSim). A bullet or a knife of the owner's
-- enemies that strikes a segment takes its damage off it, and at nothing
-- it breaks; on the course, with no sides, anyone's does, the owner's
-- too, so it can be tried alone. A wall is kept for moves that come in
-- late until SlowSim.LAG after its time's up. They all go with a new round
-- (Arena), which every client hears of from FireServer.clear's "out". Each
-- owner's last wall is their `VFWall` attribute (BarrierSim.HEALTH_ATTRIBUTE:
-- each segment's health, "x" for one broken or gone and "-" for one left
-- out), which scripted checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local BarrierSim = require(Shared.Abilities.BarrierSim)
local SlowSim = require(Shared.Abilities.SlowSim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local Penetration = require(Shared.Combat.Penetration)
local Spike = require(Shared.Spike.Spike)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local Dummies = require(script.Parent.Dummies)
local CombatServer = require(script.Parent.CombatServer)

local BarrierServer = {}

local BO = AbilityConfig.BarrierOrb

-- A wall in play: its segments' health (by their place in its segments),
-- whether it's fortified yet, and the server time its health was last
-- brought up to.
type Kept = { wall: BarrierSim.Wall, health: { number }, fortified: boolean, at: number }

local kept: { Kept } = {}
local keptOf: { [BarrierSim.Wall]: Kept } = {}
-- The walls kept, for the simulation and the shots.
local walls: { BarrierSim.Wall } = {}
-- Each owner's last wall, and the attribute it was last shown as.
local latest: { [Player]: Kept } = {}
local shown: { [Player]: string } = {}

-- Whether no wall goes up now: the arena's buy phase.
local function closed(): boolean
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return false
	end
	local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
	return arena ~= nil and arena:GetAttribute("Phase") == "buy"
end

-- The floor under the planted spike (metres), if it's planted.
local function plantedSpike(): vector?
	local at = Workspace:GetAttribute(Spike.POSITION)
	if Workspace:GetAttribute(Spike.STATE) ~= "planted" or typeof(at) ~= "Vector3" then
		return nil
	end
	return Units.asVector(at)
end

-- The walls as everyone moves through them at server time `time`.
local function wallsAt(time: number): BarrierSim.Walls
	return { walls = walls, time = time, closed = closed() }
end

-- A wall's health brought up to `now`: fortified once its time comes, and
-- decayed since it was last brought up.
local function bring(k: Kept, now: number)
	local wall = k.wall
	if now <= k.at then
		return
	end
	if not k.fortified and now >= BarrierSim.fortifies(wall) then
		k.fortified = true
		for i, segment in wall.segments do
			if segment.broken == nil then
				k.health[i] = BarrierSim.fortify(k.health[i])
			end
		end
	end
	for i in wall.segments do
		k.health[i] = BarrierSim.decay(wall, k.health[i], k.at, now)
	end
	k.at = now
end

-- Each owner's last wall as their attribute, when it's changed.
local function show(now: number)
	for player, k in latest do
		if not player.Parent then
			latest[player] = nil
			shown[player] = nil
			continue
		end
		local text = BarrierSim.summary(k.wall, k.health, now)
		if shown[player] ~= text then
			shown[player] = text
			player:SetAttribute(BarrierSim.HEALTH_ATTRIBUTE, text)
		end
	end
end

local function onCast(player: Player, cast: AbilitySim.Cast)
	local placed = cast.wall
	if cast.kind ~= "barrier" or not placed then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local wall = BarrierSim.raise(entity.id, cast.tick, now, placed, plantedSpike())
	local k: Kept = { wall = wall, health = table.create(#wall.segments, BO.health.value), fortified = false, at = now }
	table.insert(kept, k)
	keptOf[wall] = k
	table.insert(walls, wall)
	latest[player] = k
	local segments = {}
	for _, segment in wall.segments do
		table.insert(segments, { index = segment.index, base = Units.asVector3(segment.base), broken = segment.broken })
	end
	Remotes.get().Ability:FireAllClients({
		entity = entity.id,
		ability = cast.ability,
		kind = "barrier",
		id = cast.tick,
		at = now,
		-- Where it rises, and up, for its sound (AbilityEffects).
		position = Units.toStuds(wall.centre),
		direction = Vector3.yAxis,
		centre = Units.asVector3(wall.centre),
		angle = wall.angle,
		segments = segments,
	})
	show(now)
end

-- Whether `attacker`'s bullets and knives break a wall of `owner`'s (an
-- entity id): its owner's enemies' do, and with no sides (the course)
-- anyone's, its owner's too. One whose owner's gone breaks to anyone.
local function breaks(attacker: Entities.Entity, owner: number): boolean
	local entity = Entities.get(owner)
	return entity == nil or not CombatServer.teammates(attacker, entity)
end

-- A bullet or a knife of `attacker`'s that struck `key` (a surface's), for
-- `amount`: a segment of a wall takes it, and at nothing breaks.
local function struck(attacker: Entities.Entity, key: any, amount: number)
	local piece = BarrierSim.piece(key)
	if not piece or amount <= 0 then
		return
	end
	local wall, segment = piece.wall, piece.segment
	local k = keptOf[wall]
	local now = Workspace:GetServerTimeNow()
	if not k or segment.broken ~= nil or now >= BarrierSim.ends(wall) or not breaks(attacker, wall.owner) then
		return
	end
	bring(k, now)
	local i = table.find(wall.segments, segment)
	if not i then
		return
	end
	k.health[i] = math.max(k.health[i] - amount, 0)
	if k.health[i] <= 0 then
		segment.broken = now
		Remotes.get().Ability:FireAllClients({
			entity = wall.owner,
			ability = "barrierorb",
			kind = "break",
			id = wall.id,
			index = segment.index,
			at = now,
		})
	end
	show(now)
end

-- Once a server frame, at server time `now`: each wall's health brought up
-- to it, and the walls long gone forgotten.
function BarrierServer.step(now: number)
	local gone = false
	for i = #kept, 1, -1 do
		local k = kept[i]
		bring(k, now)
		if now >= BarrierSim.ends(k.wall) + SlowSim.LAG then
			table.remove(kept, i)
			keptOf[k.wall] = nil
			gone = true
		end
	end
	if gone then
		table.clear(walls)
		for _, k in kept do
			table.insert(walls, k.wall)
		end
	end
	show(now)
end

-- Every wall gone (a new round), and with them the owners' attributes.
-- FireServer.clear tells every client.
function BarrierServer.clear()
	table.clear(kept)
	table.clear(keptOf)
	table.clear(walls)
	for player in latest do
		if player.Parent then
			player:SetAttribute(BarrierSim.HEALTH_ATTRIBUTE, nil)
		end
	end
	table.clear(latest)
	table.clear(shown)
end

-- The walls that have risen or will, until they're forgotten:
-- BarrierSim.standing says which segments stand at a time.
function BarrierServer.standing(): { BarrierSim.Wall }
	return walls
end

function BarrierServer.start()
	table.insert(PlayerSimServer.castListeners, onCast)
	PlayerSimServer.barriers = wallsAt
	Dummies.barriers = wallsAt
	CombatServer.levelAt = function(base: Penetration.Level, viewTime: number): Penetration.Level
		return BarrierSim.level(base, walls, SlowSim.judged(viewTime, Workspace:GetServerTimeNow()))
	end
	CombatServer.struck = struck
	Players.PlayerRemoving:Connect(function(player)
		latest[player] = nil
		shown[player] = nil
	end)
end

return BarrierServer
