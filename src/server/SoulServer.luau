--!strict
-- Reyna's Soul Orbs on the server (system 73). Each enemy a Reyna kills,
-- or who dies within AbilityConfig.Reyna's `damaged` of her last hurting
-- them, whoever killed them, leaves her an orb where they fell, for its
-- time (SoulSim), if she's alive and her kit's abilities are on: hers
-- alone, sent to her as a player attribute (SoulSim.ATTRIBUTE) for her
-- client to draw and pick from, as this does for her ticks
-- (PlayerSimServer.soulOf). Dummies on the course leave them too, to
-- practise on.
--
-- Her Devour and her Dismiss each take the orb in her reach in her own
-- simulation (AbilitySim), and the cast says which: it goes here too.
-- Devour's heal then gives its health a few points at a time (as Sage's
-- do, FireServer.EVERY), past her most up to the overheal's
-- (CombatServer.overheal); what's past her most goes its `overhealTime`
-- after the last of her heals is given (CombatServer.trim), unless another
-- is under way by then. Through her Dismiss she's intangible
-- (CombatServer.intangible): from the cast until it's over in her
-- simulation, and never past its time on the server's clock, however her
-- moves come in.
--
-- Her orbs and her heals go as she dies or a new life starts, and
-- everyone's with a new round (SoulServer.clear, from the arena). Bots play
-- her as players do (system 65), each known by its stand-in
-- (PlayerSimServer.Actor).
--
-- In Studio, the server's Output has a `[VF] soul:` line as each orb's
-- earned, each is taken and each overheal goes, for scripted checks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local SoulSim = require(Shared.Abilities.SoulSim)
local RobloxSpike = require(Shared.Spike.RobloxSpike)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local AbilityServer = require(script.Parent.AbilityServer)
local FireServer = require(script.Parent.FireServer)

type Actor = PlayerSimServer.Actor

local RY = AbilityConfig.Reyna

local SoulServer = {}

-- Each Reyna's orbs, and what her attribute last said of them.
local orbs: { [Actor]: { SoulSim.Orb } } = {}
local told: { [Actor]: string } = {}
-- When each Reyna last hurt each entity, by its id.
local hurt: { [number]: { [Actor]: number } } = {}
-- Each Reyna's Devour heals under way, each with when it last gave.
local heals: { [Actor]: { { heal: SoulSim.Heal, lot: number } } } = {}
-- When each Reyna's Dismiss is over on the server's clock, at the latest.
local dismissed: { [Actor]: number } = {}
-- When what's past each Reyna's most goes.
local overUntil: { [Actor]: number } = {}
local nextId = 0

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function trace(text: string)
	if RunService:IsStudio() then
		print("[VF] soul: " .. text)
	end
end

-- Whether an actor plays Reyna's kit.
local function isReyna(actor: Actor?): boolean
	local kit = if actor then PlayerSimServer.abilitiesOf(actor) else nil
	return kit ~= nil and kit.agent == "reyna"
end

local function publish(actor: Actor)
	local text = SoulSim.encode(orbs[actor] or {})
	if told[actor] ~= text then
		told[actor] = text
		if actor.Parent then
			actor:SetAttribute(SoulSim.ATTRIBUTE, if text == "" then nil else text)
		end
	end
end

-- Every orb and heal of a Reyna's gone, and her Dismiss with them.
local function forget(actor: Actor)
	orbs[actor] = nil
	heals[actor] = nil
	dismissed[actor] = nil
	overUntil[actor] = nil
	if told[actor] then
		publish(actor)
		told[actor] = nil
	end
end

-- The orb a Reyna's eye has in reach now, by its number.
local function soulFor(actor: Actor, eye: vector): number?
	local list = orbs[actor]
	if not list or #list == 0 then
		return nil
	end
	return SoulSim.pick(list, eye, now(), RobloxSpike.sees)
end
SoulServer.soulFor = soulFor

-- Takes a Reyna's orb by its number; whether it was there.
local function take(actor: Actor, id: number?): boolean
	local list = orbs[actor]
	if not list or id == nil then
		return false
	end
	for i, orb in list do
		if orb.id == id then
			table.remove(list, i)
			publish(actor)
			return true
		end
	end
	return false
end

-- Whether an entity is a Reyna in her Dismiss now.
local function intangible(entity: Entities.Entity): boolean
	local actor = PlayerSimServer.actorOf(entity)
	local ends = if actor then dismissed[actor] else nil
	if not actor or not ends then
		return false
	end
	local kit = PlayerSimServer.abilitiesOf(actor)
	return now() < ends and kit ~= nil and kit.dismissUntil > 0
end

local function onDamage(attacker: Entities.Entity?, victim: Entities.Entity)
	local actor = if attacker then PlayerSimServer.actorOf(attacker) else nil
	if not actor or not attacker or not isReyna(actor) or CombatServer.teammates(attacker, victim) then
		return
	end
	local by: { [Actor]: number } = hurt[victim.id] or {}
	hurt[victim.id] = by
	by[actor] = now()
end

-- A death: an orb where they fell for each Reyna it earns one.
local function onKill(attacker: Entities.Entity?, victim: Entities.Entity)
	local by: { [Actor]: number } = hurt[victim.id] or {}
	hurt[victim.id] = nil
	local killer = if attacker then PlayerSimServer.actorOf(attacker) else nil
	if killer and attacker and not CombatServer.teammates(attacker, victim) then
		by[killer] = by[killer] or -math.huge
	end
	local pose = victim.pose()
	local at = if victim.sim then victim.sim.movement.position elseif pose then pose.position else nil
	if not at or AbilityServer.off then
		return
	end
	local t = now()
	for actor, hurtAt in by do
		local earned = SoulSim.earns(actor == killer, if hurtAt > -math.huge then hurtAt else nil, t)
		if earned and isReyna(actor) and PlayerSimServer.isAlive(actor) and actor.Parent then
			nextId += 1
			local list = orbs[actor] or {}
			orbs[actor] = list
			local orb = SoulSim.orb(nextId, at, t)
			table.insert(list, orb)
			publish(actor)
			local why = if actor == killer then "her kill" else string.format("hurt %.1f s before", t - hurtAt)
			trace(string.format("%s earns %d at %.2f, %.2f, %.2f (%s)", actor.Name, orb.id, orb.at.x, orb.at.y, orb.at.z, why))
		end
	end
end

-- A Reyna's casts: an orb taken, Devour's heal started, her Dismiss's
-- time on the server's clock, and its end.
local function onCast(actor: Actor, cast: any)
	if cast.kind == "devour" or cast.kind == "dismiss" then
		local taken = take(actor, cast.soul)
		trace(string.format("%s %s takes %s (%s)", actor.Name, cast.kind, tostring(cast.soul), if taken then "there" else "gone"))
	end
	if cast.kind == "devour" then
		local list = heals[actor] or {}
		heals[actor] = list
		local t = now()
		table.insert(list, { heal = SoulSim.heal(t), lot = t })
	elseif cast.kind == "dismiss" then
		dismissed[actor] = now() + RY.dismissTime.value
	elseif cast.kind == "solid" then
		dismissed[actor] = nil
	end
end

-- Once a server frame, at server time `t`: orbs whose time is up go, each
-- heal gives what it's come to, and an overheal whose time is up goes.
function SoulServer.step(t: number)
	for actor, list in orbs do
		local lasting = SoulSim.lasting(list, t)
		if #lasting ~= #list then
			orbs[actor] = lasting
			publish(actor)
		end
	end
	for actor, list in heals do
		local entity = PlayerSimServer.entityOf(actor)
		if not entity or not entity.health.alive then
			heals[actor] = nil
			continue
		end
		local i = 1
		while i <= #list do
			local r = list[i]
			local done = false
			if SoulSim.over(r.heal, t) or t - r.lot >= FireServer.EVERY then
				r.lot = t
				local owed
				owed, done = SoulSim.take(r.heal, t)
				CombatServer.overheal(entity, owed, RY.overheal.value)
			end
			if done then
				table.remove(list, i)
				overUntil[actor] = t + RY.overhealTime.value
			else
				i += 1
			end
		end
		if #list == 0 then
			heals[actor] = nil
		end
	end
	for actor, ends in dismissed do
		if t >= ends then
			dismissed[actor] = nil
		end
	end
	for actor, ends in overUntil do
		if t >= ends and not heals[actor] then
			overUntil[actor] = nil
			local entity = PlayerSimServer.entityOf(actor)
			if entity and entity.health.alive and entity.health.health > entity.health.maxHealth then
				CombatServer.trim(entity)
				trace(actor.Name .. " overheal over")
			end
		end
	end
end

-- Every orb, heal and hurt gone (a new round).
function SoulServer.clear()
	local had = {}
	for actor in told do
		table.insert(had, actor)
	end
	for _, actor in had do
		forget(actor)
	end
	table.clear(orbs)
	table.clear(heals)
	table.clear(dismissed)
	table.clear(overUntil)
	table.clear(hurt)
end

function SoulServer.start()
	Players.PlayerRemoving:Connect(forget)
	PlayerSimServer.soulOf = soulFor
	CombatServer.intangible = intangible
	table.insert(CombatServer.damageListeners, function(attacker, victim)
		onDamage(attacker, victim)
	end)
	table.insert(CombatServer.killListeners, function(attacker, victim)
		onKill(attacker, victim)
	end)
	table.insert(PlayerSimServer.castListeners, onCast)
	table.insert(PlayerSimServer.deathListeners, forget)
	table.insert(PlayerSimServer.spawnListeners, forget)
	table.insert(PlayerSimServer.botDeathListeners, forget)
	table.insert(PlayerSimServer.botSpawnListeners, forget)
end

return SoulServer
