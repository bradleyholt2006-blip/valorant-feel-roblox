--!strict
-- Phoenix's Run it Back on the server (system 33). Its cast, its time and
-- his return run in his simulation (AbilitySim, PlayerSim), as his client
-- predicts them, and clients hear of each (the Ability remote's "mark",
-- "fizzle" and "rise", from AbilityServer: the mark and the rising, every
-- client, as the mark's drawn for everyone; his body going, those who'd
-- hear it or have him in their snapshots, the fog of war, system 35). This
-- does what only the server can:
--   * as it's cast, keeps the shield he has then, for his return. Where it
--     was cast is his `VFLastMark` attribute (metres), which scripted checks
--     read
--   * while it runs, a hit that would kill him spares him
--     (CombatServer.spares): he's taken it, and his body's gone at once, out
--     of play, as his return starts in his simulation from his last tick.
--     Nobody's killed him, so there's no kill and no death, and no points
--     or kill feed for either (the kill doesn't count: Player Assist's
--     guide; community), but a single Blade Storm knife that did it brings
--     the knives back all the same (Patch 1.02). Clients hear of his body
--     going as they would a cast ("fizzle", `spared`, which his own client
--     didn't predict)
--   * as it runs out, his body's gone the same, with no hit
--   * out of play nothing hurts or heals him, shots go through him, the
--     snapshots leave him out, nothing blinds him and he picks nothing up
--     (PlayerSimServer.inPlay); a blind or a nearsight he had goes (Patch
--     12.01 fixed a debuff staying)
--   * as he rises at the mark he's back in play, with full health and the
--     shield he had as he cast it (Patch 5.01)
--   * a body that's been gone longer than its time and the grace, on the
--     server's clock, is back in play where it is: his moves have stopped
--     coming, and moves held back mustn't keep him out of play

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local PlayerSim = require(Shared.PlayerSim)
local FogOfWar = require(Shared.Combat.FogOfWar)
local Health = require(Shared.Combat.Health)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local FlareServer = require(script.Parent.FlareServer)
local ParanoiaServer = require(script.Parent.ParanoiaServer)
local FogServer = require(script.Parent.FogServer)

local RunItBackServer = {}

RunItBackServer.LAST_MARK_ATTRIBUTE = "VFLastMark"

local RB = AbilityConfig.RunItBack

-- Each player's shield as they cast it, until they've risen.
local kept: { [Player]: Health.Kept } = {}
-- When each player's body went (server time), while it's out of play.
local goneAt: { [Player]: number } = {}

-- A body gone at `now`, and the blind on it with it, and a nearsight
-- (Omen's Paranoia, system 41).
local function gone(player: Player, now: number)
	goneAt[player] = now
	FlareServer.clear(player)
	ParanoiaServer.clear(player)
end

-- Back in play: full health and the shield it was cast with.
local function back(player: Player)
	goneAt[player] = nil
	local entity = PlayerSimServer.entityOf(player)
	if entity then
		CombatServer.back(entity, kept[player])
	end
end

-- A hit that would kill a player whose Run it Back is running.
local function spares(victim: Entities.Entity, attacker: Entities.Entity?, weapon: string, mode: string?): boolean
	local player = victim.player
	local sim = if player then PlayerSimServer.getSim(player) else nil
	local t = if player then PlayerSimServer.timeOf(player) else nil
	if not player or not sim or not t or not AbilitySim.runningBack(sim.abilities) then
		return false
	end
	local kit = sim.abilities
	AbilitySim.fizzle(kit, t)
	PlayerSimServer.markDirty(player)
	local by = if attacker then attacker.player else nil
	local theirs = if by and by ~= player then PlayerSimServer.getSim(by) else nil
	if by and theirs then
		PlayerSim.knivesBack(theirs, weapon, mode)
		PlayerSimServer.markDirty(by)
	end
	local now = Workspace:GetServerTimeNow()
	gone(player, now)
	local event = {
		entity = victim.id,
		ability = "runitback",
		kind = "fizzle",
		at = now,
		position = Units.toStuds(sim.movement.position),
		direction = Units.asVector3(vector.create(-math.sin(kit.markYaw), 0, -math.cos(kit.markYaw))),
		spared = true,
	}
	for _, other in Players:GetPlayers() do
		if FogServer.hears(other, sim.movement.position, FogOfWar.Edges.cast, victim.id) then
			Remotes.get().Ability:FireClient(other, event)
		end
	end
	return true
end

local function onCast(player: Player, cast: AbilitySim.Cast)
	if cast.kind == "mark" then
		local entity = PlayerSimServer.entityOf(player)
		if entity then
			kept[player] = Health.keep(entity.health)
		end
		player:SetAttribute(RunItBackServer.LAST_MARK_ATTRIBUTE, Units.asVector3(cast.position))
	elseif cast.kind == "fizzle" then
		local entity = PlayerSimServer.entityOf(player)
		if entity then
			CombatServer.withdraw(entity)
		end
		gone(player, Workspace:GetServerTimeNow())
	elseif cast.kind == "rise" then
		back(player)
		kept[player] = nil
	end
end

local function forget(player: Player)
	kept[player] = nil
	goneAt[player] = nil
end

-- Once a server frame, at server time `now`, after the moves: bodies gone
-- too long back in play.
function RunItBackServer.step(now: number)
	for player, at in goneAt do
		if now - at >= RB.away.value + RB.grace.value then
			back(player)
		end
	end
end

function RunItBackServer.start()
	CombatServer.spares = spares
	table.insert(PlayerSimServer.castListeners, onCast)
	table.insert(PlayerSimServer.deathListeners, forget)
	table.insert(PlayerSimServer.spawnListeners, forget)
	Players.PlayerRemoving:Connect(forget)
end

return RunItBackServer
