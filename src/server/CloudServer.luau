--!strict
-- Jett's thrown clouds on the server (system 18). Each Cloudburst thrown
-- (a "throw" cast) flies here through CloudSim on its thrower's ticks, so
-- C held on their screen steers it here the same way, and the server says
-- where it burst. Every client is told (the Ability remote):
--   * "flight": where it is, as it's thrown and every few of its ticks
--     after, so others can draw it on its way
--   * "cloud": where it burst, and when
-- Each is timed from the throw in server time, plus how long it has flown.
-- A throw whose thrower dies or leaves flies straight on by itself, on the
-- server's clock. The thrower's last cloud is their `VFLastCloud`
-- attribute (metres), which scripted checks read. Each cloud is kept while
-- it stands, as nobody sees through it (CloudServer.standing, for the
-- minimap's spotting, system 34).
--
-- Omen's Dark Cover (system 40) is kept here too: each orb sent (a "smoke"
-- cast, PlayerSim having found where it goes) flies straight there,
-- unseen and through anything in its way, and its smoke forms once it
-- arrives (SmokeSim). Every client is told as it's sent ("darkcover": where
-- it forms, and when), and it stands with the clouds, as nobody sees
-- through it either. The thrower's last smoke is their `VFLastSmoke`
-- attribute (metres). A new round clears every cloud and smoke (clear,
-- from the arena), as every client does on FireServer's "out".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local CloudSim = require(Shared.Abilities.CloudSim)
local SmokeSim = require(Shared.Abilities.SmokeSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)

local CloudServer = {}

-- How often a throw's place in the air is told, in its ticks (ours).
CloudServer.KEYFRAME_TICKS = 4
CloudServer.LAST_CLOUD_ATTRIBUTE = "VFLastCloud"
CloudServer.LAST_SMOKE_ATTRIBUTE = "VFLastSmoke"

local DT = 1 / MovementConfig.TickRate.value
local world = RobloxWorld.new()

-- When a throw was thrown (server time) and how many ticks it has flown.
type Info = { thrownAt: number, ticks: number }
type Thrower = { list: { CloudSim.Projectile }, info: { [number]: Info } }

-- Each player's throws in the air, flown on their ticks.
local throwers: { [Player]: Thrower } = {}
-- Throws whose thrower is dead or gone, flown on the server's clock.
local loose: { { p: CloudSim.Projectile, info: Info, player: Player? } } = {}
local carry = 0 -- server seconds the loose throws haven't flown yet
local lastNow: number? = nil
-- The clouds burst and the smokes sent: where, when they formed (server
-- time), and whether it's a smoke (Dark Cover's) or a cloud (Cloudburst's).
local clouds: { { centre: vector, at: number, smoke: boolean } } = {}

local function tell(kind: string, owner: number, id: number, at: number, position: vector, direction: vector)
	Remotes.get().Ability:FireAllClients({
		entity = owner,
		ability = "cloudburst",
		kind = kind,
		id = id,
		at = at,
		position = Units.toStuds(position),
		direction = Units.asVector3(direction),
	})
end

local function keyframe(p: CloudSim.Projectile, info: Info)
	tell("flight", p.owner, p.id, info.thrownAt + p.age, p.position, vector.normalize(p.velocity))
end

local function burst(player: Player?, owner: number, id: number, position: vector, age: number, info: Info?)
	local thrownAt = if info then info.thrownAt else Workspace:GetServerTimeNow() - age
	tell("cloud", owner, id, thrownAt + age, position, vector.create(0, 1, 0))
	table.insert(clouds, { centre = position, at = thrownAt + age, smoke = false })
	if player and player.Parent then
		player:SetAttribute(CloudServer.LAST_CLOUD_ATTRIBUTE, Units.asVector3(position))
	end
end

local function hasThrow(casts: { any }?): boolean
	if casts then
		for _, cast in casts do
			if cast.kind == "throw" then
				return true
			end
		end
	end
	return false
end

-- Dark Cover's orb sent by `player` (entity `owner`) from `eye` to a smoke
-- at `centre`: it forms once it's flown there.
local function sendSmoke(player: Player, owner: number, id: number, eye: vector, centre: vector)
	local at = Workspace:GetServerTimeNow() + SmokeSim.flight(eye, centre)
	table.insert(clouds, { centre = centre, at = at, smoke = true })
	Remotes.get().Ability:FireAllClients({
		entity = owner,
		ability = "darkcover",
		kind = "darkcover",
		id = id,
		at = at,
		position = Units.toStuds(centre),
		direction = Units.asVector3(vector.create(0, 1, 0)),
	})
	player:SetAttribute(CloudServer.LAST_SMOKE_ATTRIBUTE, Units.asVector3(centre))
end

-- After each of a player's ticks: their throws fly on with its input, and
-- its throws join them; the orbs it sent go to their smokes.
local function onTick(player: Player, input: any, casts: { any }?)
	if casts then
		for _, cast in casts do
			if cast.kind == "smoke" and cast.smoke then
				local entity = PlayerSimServer.entityOf(player)
				if entity then
					sendSmoke(player, entity.id, cast.tick, cast.origin, cast.smoke)
				end
			end
		end
	end
	local had: Thrower? = throwers[player]
	if not had and not hasThrow(casts) then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	local t: Thrower = had or { list = {}, info = {} }
	throwers[player] = t
	for _, b in CloudSim.tick(t.list, entity.id, input, casts, DT, world) do
		burst(player, b.owner, b.id, b.position, b.age, t.info[b.id])
		t.info[b.id] = nil
	end
	local now = Workspace:GetServerTimeNow()
	for _, p in t.list do
		local info: Info? = t.info[p.id]
		if info then
			info.ticks += 1
			if info.ticks % CloudServer.KEYFRAME_TICKS == 0 then
				keyframe(p, info)
			end
		else
			local thrown = { thrownAt = now, ticks = 0 }
			t.info[p.id] = thrown
			keyframe(p, thrown)
		end
	end
	if #t.list == 0 then
		throwers[player] = nil
	end
end

-- A thrower's throws go on by themselves (they died, or left).
local function letGo(player: Player)
	local t = throwers[player]
	throwers[player] = nil
	if not t then
		return
	end
	for _, p in t.list do
		local info = t.info[p.id] or { thrownAt = Workspace:GetServerTimeNow() - p.age, ticks = 0 }
		table.insert(loose, { p = p, info = info, player = player })
	end
end

-- Once a server frame, at server time `now`: the loose throws fly on.
function CloudServer.step(now: number)
	local last = lastNow
	lastNow = now
	if #loose == 0 then
		carry = 0
		return
	end
	if last then
		carry = math.min(carry + now - last, 0.25)
	end
	while carry >= DT do
		carry -= DT
		local i = 1
		while i <= #loose do
			local l = loose[i]
			local at = CloudSim.drift(l.p, DT, world)
			if at then
				table.remove(loose, i)
				burst(l.player, l.p.owner, l.p.id, at, l.p.age, l.info)
			else
				l.info.ticks += 1
				if l.info.ticks % CloudServer.KEYFRAME_TICKS == 0 then
					keyframe(l.p, l.info)
				end
				i += 1
			end
		end
	end
end

-- The clouds and smokes standing at `now` (server time): each one's centre
-- and its radius then (CloudSim.radiusAt, SmokeSim.radiusAt). Those gone
-- are forgotten.
function CloudServer.standing(now: number): { { centre: vector, radius: number } }
	local out = {}
	local i = 1
	while i <= #clouds do
		local c = clouds[i]
		local age = now - c.at
		local life = if c.smoke then AbilityConfig.DarkCover.duration.value else AbilityConfig.Cloudburst.duration.value
		if age >= life then
			table.remove(clouds, i)
		else
			local radius = if c.smoke then SmokeSim.radiusAt(age) else CloudSim.radiusAt(age)
			if radius > 0 then
				table.insert(out, { centre = c.centre, radius = radius })
			end
			i += 1
		end
	end
	return out
end

-- Every cloud and smoke gone (a new round).
function CloudServer.clear()
	table.clear(clouds)
end

function CloudServer.start()
	table.insert(PlayerSimServer.tickListeners, onTick)
	table.insert(PlayerSimServer.deathListeners, letGo)
	Players.PlayerRemoving:Connect(letGo)
end

return CloudServer
