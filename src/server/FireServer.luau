--!strict
-- Phoenix's Hot Hands on the server (system 31). Each fireball thrown (a
-- "fireball" cast) flies here through FireballSim at once, through the
-- level, as nothing changes its path after the throw, and bursts where it
-- lands, on the server's clock; how far its fire can spread each way round
-- is worked out with it (FireSim.reaches). Every client is told of the
-- throw (the Ability remote's "flight"): its keys, how long after the throw
-- it bursts, the floor its fire burns on and how far that fire reaches, so
-- each draws it the same way.
-- From the burst, its fire burns everyone alive standing in it
-- (FireSim.inside, from where the server's simulation has them), as Hot
-- Hands (FireSim.WEAPON, the fireball, for the kill feed), credited to its
-- thrower: allies at their share of an enemy's rate, nobody spawn
-- protection keeps shots off, and never its thrower, who heals instead
-- (Inner Fire): his first touch of each fire starts a heal of its own,
-- which goes on if he leaves it, until it's all given or he dies
-- (CombatServer.mend). Burns and heals go a few points at a time
-- (FireServer.EVERY), and what a burn's owed goes at once as its victim
-- leaves the fire or it goes out. Fire doesn't slow: the reference's
-- tagging is its bullets' ("Bullet tagging", Patch 3.0). A thrower's fires
-- go as they leave, and every fire with a new round (Arena). The thrower's
-- last burst is their `VFLastFire` attribute (FireSim.LAST_ATTRIBUTE, the
-- floor under it, in metres), which scripted checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local FireballSim = require(Shared.Abilities.FireballSim)
local FireSim = require(Shared.Abilities.FireSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local Tuning = require(script.Parent.Tuning)

local FireServer = {}

-- Seconds between one lot of a burn's or a heal's points and the next
-- (ours: the reference gives a point at a time, which here would be an
-- event for each).
FireServer.EVERY = 0.1

local DT = 1 / MovementConfig.TickRate.value
local HEAL = AbilityConfig.InnerFire.heal.value
local world = RobloxWorld.new()

-- A fire, from its throw: whose (their entity, for the credit), the fire
-- itself, what it owes each entity standing in it by id, and whether its
-- thrower has touched it yet.
type Fire = {
	player: Player,
	entity: Entities.Entity,
	pool: FireSim.Pool,
	owed: { [number]: FireSim.Owed },
	touched: boolean,
	burst: boolean,
}

-- A heal Inner Fire has under way: whose, since when, and what's given.
type Heal = { player: Player, entity: Entities.Entity, from: number, given: number, last: number }

local fires: { Fire } = {}
local heals: { Heal } = {}

local function onCast(player: Player, cast: AbilitySim.Cast)
	if cast.kind ~= "fireball" then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	local ball = FireballSim.throw(entity.id, cast.tick, cast.origin, cast.direction, cast.lob == true)
	local landed = FireballSim.fly(ball, DT, world)
	local now = Workspace:GetServerTimeNow()
	local keys = {}
	for _, key in ball.keys do
		table.insert(keys, {
			age = key.age,
			position = Units.asVector3(key.position),
			velocity = Units.asVector3(key.velocity),
			gravity = key.gravity,
		})
	end
	local event: { [string]: any } = {
		entity = entity.id,
		ability = cast.ability,
		kind = "flight",
		id = cast.tick,
		at = now,
		lob = ball.lob,
		keys = keys,
		land = landed,
	}
	if landed then
		local centre = FireSim.floorUnder(ball.position)
		local reaches = FireSim.reaches(centre, world)
		event.point = Units.asVector3(centre)
		event.reaches = reaches
		table.insert(fires, {
			player = player,
			entity = entity,
			pool = FireSim.new(entity.id, cast.tick, centre, now + landed, reaches),
			owed = {},
			touched = false,
			burst = false,
		})
	end
	Remotes.get().Ability:FireAllClients(event)
end

-- Where an entity stands, if it's alive and spawned.
local function feetOf(entity: Entities.Entity): vector?
	if not entity.health.alive or not entity.sim then
		return nil
	end
	local player = entity.player
	if player and not PlayerSimServer.isAlive(player) then
		return nil
	end
	return entity.sim.movement.position
end

-- Inner Fire: the thrower's first touch of one of his fires starts a heal.
local function touched(fire: Fire, now: number)
	fire.touched = true
	local sim = fire.entity.sim
	if sim and AbilitySim.hasPassive(sim.abilities, "innerfire") then
		table.insert(heals, { player = fire.player, entity = fire.entity, from = now, given = 0, last = -math.huge })
	end
end

-- What a fire owes someone given them now, if it's a point or more.
local function give(fire: Fire, victim: Entities.Entity, o: FireSim.Owed, now: number, every: number)
	local points = FireSim.owe(o, 0, now, every)
	if points > 0 then
		CombatServer.burn(fire.entity, victim, points, FireSim.WEAPON)
	end
end

-- One fire's frame, `dt` seconds after the last, at server time `now`.
local function burn(fire: Fire, now: number, dt: number)
	local pool = fire.pool
	if not fire.burst and now >= pool.start then
		fire.burst = true
		if fire.player.Parent then
			fire.player:SetAttribute(FireSim.LAST_ATTRIBUTE, Units.asVector3(pool.centre))
		end
	end
	local span = math.min(dt, now - pool.start)
	local protected = CombatServer.protected
	local pad = Tuning.config().halfWidth
	for id, entity in Entities.all() do
		local feet = feetOf(entity)
		local o = fire.owed[id]
		if not feet or not FireSim.inside(pool, feet, now, pad) then
			-- Out of it: what it owes them goes now.
			if o then
				give(fire, entity, o, now, 0)
				fire.owed[id] = nil
			end
			continue
		end
		if entity == fire.entity then
			if not fire.touched then
				touched(fire, now)
			end
			continue
		end
		if protected and protected(entity) then
			continue
		end
		if not o then
			o = FireSim.owed()
			fire.owed[id] = o
		end
		local rate = FireSim.burnRate(CombatServer.teammates(fire.entity, entity))
		local points = FireSim.owe(o, rate * math.max(span, 0), now, FireServer.EVERY)
		if points > 0 then
			CombatServer.burn(fire.entity, entity, points, FireSim.WEAPON)
		end
	end
end

-- Once a server frame, at server time `now`, `dt` seconds after the last:
-- the fires that have burst burn, those that are out go, and Inner Fire's
-- heals give what they've come to.
function FireServer.step(now: number, dt: number)
	local i = 1
	while i <= #fires do
		local fire = fires[i]
		if now >= FireSim.ends(fire.pool) then
			table.remove(fires, i)
			for id, o in fire.owed do
				local entity = Entities.get(id)
				if entity then
					give(fire, entity, o, now, 0)
				end
			end
		else
			if now >= fire.pool.start then
				burn(fire, now, dt)
			end
			i += 1
		end
	end
	i = 1
	while i <= #heals do
		local heal = heals[i]
		local due = FireSim.healed(now - heal.from)
		if due > heal.given and (due >= HEAL or now - heal.last >= FireServer.EVERY) then
			CombatServer.mend(heal.entity, due - heal.given, 0)
			heal.given = due
			heal.last = now
		end
		if heal.given >= HEAL then
			table.remove(heals, i)
		else
			i += 1
		end
	end
end

-- Every fire out, and every heal over (a new round).
function FireServer.clear()
	table.clear(fires)
	table.clear(heals)
end

-- A player's heals over (a death or a new life).
local function stopHeals(player: Player)
	for i = #heals, 1, -1 do
		if heals[i].player == player then
			table.remove(heals, i)
		end
	end
end

function FireServer.start()
	table.insert(PlayerSimServer.castListeners, onCast)
	table.insert(PlayerSimServer.deathListeners, stopHeals)
	table.insert(PlayerSimServer.spawnListeners, stopHeals)
	Players.PlayerRemoving:Connect(function(player)
		stopHeals(player)
		for i = #fires, 1, -1 do
			if fires[i].player == player then
				table.remove(fires, i)
			end
		end
	end)
end

return FireServer
