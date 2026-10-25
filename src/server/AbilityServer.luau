--!strict
-- The ability kit on the server (system 17). Each player's kit is part of
-- their simulation (AbilitySim, through PlayerSimServer), which casts what
-- they press; this changes it between ticks, and the ack takes the change
-- to its owner:
--   * in the spike rounds (Arena says when), a new match starts everyone on
--     a new kit, each half takes away what was bought, and each round gives
--     the signature its free charge and takes back the charges kills brought
--     back. Charges are bought in the buy menu (ShopServer), one at a time
--   * on the course and in Skirmish, where nothing is bought, every life
--     starts with every charge, and on the course a spent charge comes back
--     a moment after, so it can be practised (ours). So does the ultimate
--     on the course: every life starts with its points full, and they fill
--     again a moment after it's over (system 19)
--   * the ultimate's points: one for a kill (a dummy's too), a death, a
--     plant and a defuse; and kills bring the signature's charge back
--     (Jett's: two). A kill with a single Blade Storm knife brings all its
--     knives back (PlayerSim.killedWith, system 19)
-- Each cast is told to every client (the Ability remote) for its sound and
-- look, when the frame on their screen reaches it, but Blade Storm's knives
-- drawn again, which others see in hand. The caster's own client has
-- predicted it already. Each kit is a player attribute
-- (AbilityConfig.KIT_ATTRIBUTE, as AbilitySim.summary writes it), which
-- scripted checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local PlayerSim = require(Shared.PlayerSim)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local SpikeServer = require(script.Parent.SpikeServer)

local AbilityServer = {}

-- Whether charges are bought (the spike rounds). Without, every life
-- starts with every charge.
AbilityServer.economy = false
-- Whether a spent charge comes back by itself, and the ultimate's points
-- fill (the course).
AbilityServer.refill = true
-- How long the course waits, once nothing's under way, before it fills a
-- kit again (ours).
AbilityServer.REFILL_DELAY = 1.5

-- What a cast tells clients.
export type CastEvent = {
	entity: number,
	ability: string,
	kind: string,
	at: number, -- server time
	position: Vector3, -- studs: the caster's feet
	direction: Vector3, -- a unit vector
}

-- Since when each kit has been short of a charge with nothing under way.
local shortSince: { [Player]: number } = {}
local shown: { [Player]: string } = {}

-- Changes a player's kit, if they're playing, and sends them the change.
local function change(player: Player, apply: (AbilitySim.State) -> ())
	local kit = PlayerSimServer.abilitiesOf(player)
	if kit then
		apply(kit)
		PlayerSimServer.markDirty(player)
	end
end

-- As a round of the spike rounds starts: "match" for the first of a match,
-- "half" for the first of the second half, "round" for any other.
function AbilityServer.roundStarted(player: Player, kind: "match" | "half" | "round")
	change(player, if kind == "match" then AbilitySim.reset elseif kind == "half" then AbilitySim.newHalf else AbilitySim.newRound)
end

-- A new kit, as the spike rounds or the course start.
function AbilityServer.reset(player: Player)
	change(player, AbilitySim.reset)
end

-- Whether a charge of the ability `id` can be bought into a player's kit.
function AbilityServer.canBuy(player: Player, id: string): boolean
	local kit = PlayerSimServer.abilitiesOf(player)
	return kit ~= nil and AbilitySim.canBuy(kit, id)
end

-- A charge of the ability `id` bought into a player's kit, or sold back
-- out of it; false if it can't be.
function AbilityServer.buy(player: Player, id: string): boolean
	local kit = PlayerSimServer.abilitiesOf(player)
	if not kit or not AbilitySim.buy(kit, id) then
		return false
	end
	PlayerSimServer.markDirty(player)
	return true
end

function AbilityServer.sell(player: Player, id: string): boolean
	local kit = PlayerSimServer.abilitiesOf(player)
	if not kit or not AbilitySim.sell(kit, id) then
		return false
	end
	PlayerSimServer.markDirty(player)
	return true
end

-- Once a server frame: the course's refills, the ultimate's points with
-- them, and each kit told to clients, with Drift's glide.
function AbilityServer.step(now: number)
	for _, player in Players:GetPlayers() do
		local kit = PlayerSimServer.abilitiesOf(player)
		if not kit then
			continue
		end
		local t = PlayerSimServer.timeOf(player) or 0
		if not AbilityServer.refill or not PlayerSimServer.isAlive(player) or AbilitySim.full(kit, true) or AbilitySim.busy(kit, t) then
			shortSince[player] = nil
		else
			local since = shortSince[player]
			if not since then
				shortSince[player] = now
			elseif now - since >= AbilityServer.REFILL_DELAY then
				shortSince[player] = nil
				AbilitySim.fill(kit, true)
				PlayerSimServer.markDirty(player)
			end
		end
		local sim = PlayerSimServer.getSim(player)
		local text = AbilitySim.summary(kit, t, sim ~= nil and sim.movement.gliding)
		if shown[player] ~= text then
			shown[player] = text
			player:SetAttribute(AbilityConfig.KIT_ATTRIBUTE, text)
		end
	end
end

function AbilityServer.start()
	table.insert(PlayerSimServer.castListeners, function(player: Player, cast: AbilitySim.Cast)
		local entity = PlayerSimServer.entityOf(player)
		if not entity or cast.kind == "draw" then
			return
		end
		local event: CastEvent = {
			entity = entity.id,
			ability = cast.ability,
			kind = cast.kind,
			at = Workspace:GetServerTimeNow(),
			position = Units.toStuds(cast.position),
			direction = Units.asVector3(cast.direction),
		}
		Remotes.get().Ability:FireAllClients(event)
	end)
	-- Every life on the course and in Skirmish starts with every charge,
	-- and on the course with the ultimate's points full.
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		if not AbilityServer.economy then
			change(player, function(kit)
				AbilitySim.fill(kit, AbilityServer.refill)
			end)
		end
	end)
	table.insert(CombatServer.killListeners, function(attacker, victim, weapon, mode)
		local by = if attacker then attacker.player else nil
		local sim = if by and by ~= victim.player then PlayerSimServer.getSim(by) else nil
		if by and sim then
			PlayerSim.killedWith(sim, weapon, mode)
			PlayerSimServer.markDirty(by)
		end
	end)
	table.insert(PlayerSimServer.deathListeners, function(player: Player)
		change(player, AbilitySim.died)
	end)
	table.insert(SpikeServer.objectiveListeners, function(player: Player, kind: "planted" | "defused")
		local points = AbilityConfig.Points
		change(player, function(kit)
			AbilitySim.addPoints(kit, if kind == "planted" then points.plant.value else points.defuse.value)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		shortSince[player] = nil
		shown[player] = nil
	end)
end

return AbilityServer
