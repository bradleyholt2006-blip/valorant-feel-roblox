--!strict
-- Phoenix's Blaze on the server (system 32). Each wall sent out (a "flame"
-- cast) runs here through BlazeSim on its caster's ticks, so fire held on
-- their screen bends it here the same way, and the wall rises where the
-- server's run ends. Every client is told (the Ability remote):
--   * "flight": where its head is, as it's sent out and every few of its
--     ticks after (each a point of its path), so others can draw it on its
--     way
--   * "wall": its path, and when it rises
-- Each is timed from the cast in server time, plus how long it has run. A
-- run whose caster dies runs straight on by itself, on the server's clock;
-- one whose caster leaves goes with them. As it rises its fire is lit
-- (FireServer.light): it burns as Blaze (BlazeSim.WEAPON) at its own rate,
-- and heals its caster at its own pace (Inner Fire), and the caster's
-- `VFLastWall` attribute (BlazeSim.LAST_ATTRIBUTE) is its far end, in
-- metres, which scripted checks read. Each wall is kept while it stands,
-- as nobody sees through it (BlazeServer.standing, for the minimap's
-- spotting, system 34). Runs and walls go with a new round, as fires do
-- (Arena).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local BlazeSim = require(Shared.Abilities.BlazeSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local FireServer = require(script.Parent.FireServer)

local BlazeServer = {}

-- How often a run's head is told, in its ticks: at each point of its path.
BlazeServer.KEYFRAME_TICKS = BlazeSim.POINT_TICKS

local DT = 1 / MovementConfig.TickRate.value
local BZ = AbilityConfig.Blaze
local world = RobloxWorld.new()

-- Each player's runs under way, flown on their ticks, and when each was
-- sent out (server time), by its id.
type Caster = { list: { BlazeSim.Run }, sentAt: { [number]: number } }

local casters: { [Player]: Caster } = {}
-- Runs whose caster is dead, run on the server's clock.
local loose: { { run: BlazeSim.Run, sentAt: number, player: Player } } = {}
local carry = 0 -- server seconds the loose runs haven't run yet
local lastNow: number? = nil
-- The walls risen, until they fall.
local walls: { BlazeSim.Wall } = {}

local function keyframe(run: BlazeSim.Run, sentAt: number)
	Remotes.get().Ability:FireAllClients({
		entity = run.owner,
		ability = "blaze",
		kind = "flight",
		id = run.id,
		at = sentAt + run.age,
		point = Units.asVector3(run.position),
	})
end

-- A run that's over: its wall rises where it ran, told to every client and
-- lit, unless it ran nowhere.
local function rise(player: Player, run: BlazeSim.Run, sentAt: number)
	local start = sentAt + run.age
	local wall = BlazeSim.wall(run.owner, run.id, run.points, start)
	if not wall then
		return
	end
	table.insert(walls, wall)
	local points = {}
	for _, point in wall.points do
		table.insert(points, Units.asVector3(point))
	end
	Remotes.get().Ability:FireAllClients({
		entity = run.owner,
		ability = "blaze",
		kind = "wall",
		id = run.id,
		at = start,
		-- Where it rises from, and up, for its sound (AbilityEffects).
		position = Units.toStuds(wall.points[1]),
		direction = Vector3.yAxis,
		points = points,
	})
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	FireServer.light(player, entity, {
		start = start,
		ends = BlazeSim.ends(wall),
		inside = function(feet: vector, at: number, pad: number): boolean
			return BlazeSim.inside(wall, feet, at, pad)
		end,
		burn = BZ.burn.value,
		allyShare = BZ.allyShare.value,
		weapon = BlazeSim.WEAPON,
		every = AbilityConfig.InnerFire.blazeEvery.value,
		attribute = BlazeSim.LAST_ATTRIBUTE,
		point = wall.points[#wall.points],
	})
end

local function sends(casts: { any }?): boolean
	if casts then
		for _, cast in casts do
			if cast.kind == "flame" then
				return true
			end
		end
	end
	return false
end

-- After each of a player's ticks: their runs go on with its input, bent
-- while their wall's still being bent after it, and its walls sent out
-- join them.
local function onTick(player: Player, input: any, casts: { any }?)
	local had: Caster? = casters[player]
	if not had and not sends(casts) then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	local sim = if entity then entity.sim else nil
	if not entity or not sim then
		return
	end
	local c: Caster = had or { list = {}, sentAt = {} }
	casters[player] = c
	local now = Workspace:GetServerTimeNow()
	for _, run in BlazeSim.tick(c.list, entity.id, input, casts, sim.abilities.steering ~= 0, DT, world) do
		local sentAt = c.sentAt[run.id] or now
		c.sentAt[run.id] = nil
		rise(player, run, sentAt)
	end
	for _, run in c.list do
		local sentAt = c.sentAt[run.id]
		if not sentAt then
			c.sentAt[run.id] = now
			keyframe(run, now)
		elseif run.ticks % BlazeServer.KEYFRAME_TICKS == 0 then
			keyframe(run, sentAt)
		end
	end
	if #c.list == 0 then
		casters[player] = nil
	end
end

-- A caster's runs go on by themselves (they died).
local function letGo(player: Player)
	local c = casters[player]
	casters[player] = nil
	if not c then
		return
	end
	for _, run in c.list do
		local sentAt = c.sentAt[run.id] or Workspace:GetServerTimeNow() - run.age
		table.insert(loose, { run = run, sentAt = sentAt, player = player })
	end
end

-- Once a server frame, at server time `now`: the loose runs go on.
function BlazeServer.step(now: number)
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
			if BlazeSim.drift(l.run, DT, world) then
				table.remove(loose, i)
				rise(l.player, l.run, l.sentAt)
			else
				if l.run.ticks % BlazeServer.KEYFRAME_TICKS == 0 then
					keyframe(l.run, l.sentAt)
				end
				i += 1
			end
		end
	end
end

-- Every run gone (a new round): its wall never rises. And every wall.
function BlazeServer.clear()
	table.clear(casters)
	table.clear(loose)
	table.clear(walls)
	carry = 0
end

-- The walls at `now` (server time) that have risen or will, until they
-- fall: BlazeSim.standing says which stand then. Those fallen are
-- forgotten.
function BlazeServer.standing(now: number): { BlazeSim.Wall }
	local i = 1
	while i <= #walls do
		if now >= BlazeSim.ends(walls[i]) then
			table.remove(walls, i)
		else
			i += 1
		end
	end
	return walls
end

function BlazeServer.start()
	table.insert(PlayerSimServer.tickListeners, onTick)
	table.insert(PlayerSimServer.deathListeners, letGo)
	Players.PlayerRemoving:Connect(function(player)
		casters[player] = nil
		for i = #loose, 1, -1 do
			if loose[i].player == player then
				table.remove(loose, i)
			end
		end
	end)
end

return BlazeServer
