--!strict
-- Omen's From the Shadows on the server (system 43). The map in hand, the
-- place it takes him, its windup, the Shade, X sending him back and his
-- forming there run in his simulation (ShadowSim, AbilitySim, PlayerSim),
-- as his client predicts them. This does what only the server can:
--   * a place on the map that a move asks for is taken only on the map
--     being played (PlayerSimServer.pointCheck, PartsPlan.inPlay), so no
--     client can ask to be taken off it, or onto another map
--   * as it's fired, where it takes him is his `VFLastShadow` attribute
--     (metres), which scripted checks read. Every client hears it fired
--     (AbilityServer, as far as the spike's blast), and an enemy's minimap
--     goes dark until it's over (ShadowView)
--   * an enemy's hit on the Shade breaks it (CombatServer.absorbs): it
--     takes nothing, and he's sent back to where he became one, his gun
--     drawn again, between his ticks, as X would send him (PlayerSim.home).
--     Nothing else hurts the Shade: a teammate's hit, or his own, does
--     nothing to it ('destroyed by an enemy', the VALORANT Wiki). A hit
--     from nobody (the spike's blast) hurts him as anyone
--   * clients hear of him as a Shade ("shade") and sent back ("home") as
--     they'd hear it, told only the places they'd hear or see: whoever has
--     him in their snapshots sees him go, and whoever's near enough hears
--     where he's gone, as far as the shade curve goes (Patch 0.49), so
--     nobody near where he wound up learns where he went. Sent back, every
--     client is told, those who'd hear neither place with no place at all,
--     so a minimap it darkened clears. His forming is told as other casts
--     are (AbilityServer)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilitySim = require(Shared.Abilities.AbilitySim)
local FogOfWar = require(Shared.Combat.FogOfWar)
local Minimap = require(Shared.Match.Minimap)
local PartsPlan = require(Shared.Match.PartsPlan)
local PlayerSim = require(Shared.PlayerSim)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local FogServer = require(script.Parent.FogServer)
local Tuning = require(script.Parent.Tuning)

local ShadowServer = {}

ShadowServer.LAST_SHADOW_ATTRIBUTE = "VFLastShadow"

-- A Shade told of: whose, when (server time), and, for each client told,
-- where it took him from (studs) if they see him go, and where it is if
-- they'd hear it there.
local function tellShade(player: Player, cast: AbilitySim.Cast)
	local entity = PlayerSimServer.entityOf(player)
	local to = cast.step
	if not entity or not to then
		return
	end
	local now = Workspace:GetServerTimeNow()
	for _, other in Players:GetPlayers() do
		local sees = FogServer.shows(other, entity.id)
		local hears = FogServer.hears(other, to, FogOfWar.Edges.shade, entity.id)
		if sees or hears then
			Remotes.get().Ability:FireClient(other, {
				entity = entity.id,
				ability = cast.ability,
				kind = "shade",
				at = now,
				from = if sees then Units.toStuds(cast.position) else nil,
				to = if hears then Units.toStuds(to) else nil,
			})
		end
	end
end

-- Sent back, told to every client: where the Shade was (studs) to those
-- who'd hear it there, where he's back to those who'd hear him there, and
-- whether an enemy's hit broke it, which his own client didn't predict.
local function tellHome(player: Player, cast: AbilitySim.Cast, broken: boolean)
	local entity = PlayerSimServer.entityOf(player)
	local was = cast.step
	if not entity or not was then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local edge = FogOfWar.Edges.shade
	for _, other in Players:GetPlayers() do
		Remotes.get().Ability:FireClient(other, {
			entity = entity.id,
			ability = cast.ability,
			kind = "home",
			at = now,
			from = if FogServer.hears(other, was, edge, entity.id) then Units.toStuds(was) else nil,
			to = if FogServer.hears(other, cast.position, edge, entity.id) then Units.toStuds(cast.position) else nil,
			broken = broken,
		})
	end
end

-- Whether a hit on `victim` by `attacker` leaves them unhurt
-- (CombatServer.absorbs): a hit on their Shade, which an enemy's breaks.
-- `shade`, for a shot or a swing, is whether they were a Shade where the
-- attacker's screen showed them.
local function absorbs(victim: Entities.Entity, attacker: Entities.Entity?, shade: boolean?): boolean
	local player = victim.player
	if not player or not attacker or shade == false then
		return false
	end
	local sim = PlayerSimServer.getSim(player)
	local t = PlayerSimServer.timeOf(player)
	if not sim or not t or not AbilitySim.shaded(sim.abilities, t) then
		-- The Shade that was hit is gone: broken already, or he's formed.
		return shade == true
	end
	if attacker == victim or CombatServer.teammates(attacker, victim) then
		return true
	end
	local _, aim = PlayerSimServer.view(player)
	local back = PlayerSim.home(sim, Tuning.config(), t, aim or vector.create(0, 0, -1))
	if back then
		PlayerSimServer.moved(player)
		tellHome(player, back, true)
	end
	return true
end

-- Whether a place on the map a move asks for is on the map being played.
local function onMap(_player: Player, point: vector): boolean
	local plan = PartsPlan.inPlay()
	return plan ~= nil and Minimap.holds(plan, point)
end

local function onCast(player: Player, cast: AbilitySim.Cast)
	local to = cast.step
	if cast.kind == "shadows" and to then
		player:SetAttribute(ShadowServer.LAST_SHADOW_ATTRIBUTE, Units.asVector3(to))
	elseif cast.kind == "shade" then
		tellShade(player, cast)
	elseif cast.kind == "home" then
		tellHome(player, cast, false)
	end
end

function ShadowServer.start()
	CombatServer.absorbs = absorbs
	PlayerSimServer.pointCheck = onMap
	table.insert(PlayerSimServer.castListeners, onCast)
end

return ShadowServer
