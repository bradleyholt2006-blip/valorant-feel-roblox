--!strict
-- The ability kit on the server (system 17). Each player's kit is part of
-- their simulation (AbilitySim, through PlayerSimServer), which casts what
-- they press; this changes it between ticks, and the ack takes the change
-- to its owner:
--   * in the spike rounds (Arena says when), a new match starts everyone on
--     a new kit, each half takes away what was bought, and each round gives
--     the signature its free charge and takes back the charges kills brought
--     back. Charges are bought in the buy menu (ShopServer), one at a time.
--     Each round's start sets the ultimate's points too (system 50,
--     AbilitySim.roundPoints): each half starts them over (Swiftplay's with
--     two), each overtime round puts them three short of full, and any other
--     pays a point for a death in the last
--   * on the course and in Skirmish, where nothing is bought, every life
--     starts with every charge, and on the course a spent charge comes back
--     a moment after, so it can be practised (ours). So does the ultimate on
--     the course: every life starts with its points full, and they fill
--     again a moment after it's over (system 19)
--   * in Team Deathmatch (system 28, AbilityServer.rules), each match starts
--     the kit over (Arena says when): the signature's charge, and the basic
--     abilities half way to their first. Spent charges come back over time,
--     each ability at its own rate, a charge at a time, dead or alive, and
--     the kit's kept from one life to the next. Its ultimate costs more,
--     with points from kills and Ultimate Orbs alone. When each slot's next
--     charge comes is a player attribute (AbilityConfig.RECHARGE_ATTRIBUTE),
--     for the ability bar's count
--   * everywhere else an ability with a cooldown of its own (Sage's Healing
--     Orb, system 36) brings a spent charge back once it's run, the same
--     way
--   * the ultimate's points: one for a kill (a dummy's too), a death, a
--     plant and a defuse. In the spike rounds a death's comes as the next
--     round starts, and a death nobody else caused (the spike's blast, or
--     one's own hand) has none (system 50). And kills bring the signature's
--     charge back
--     (Jett's: two). A kill with a single Blade Storm knife brings all its
--     knives back (PlayerSim.killedWith, system 19)
--   * in gun game (system 23) there are none: every life starts with an
--     empty kit, and nothing fills it. Nor in deathmatch (system 26), where
--     the kit is no agent's at all, so Jett's glide is gone too
--   * each player's kit is their own agent's, as they pick it (system 29,
--     AgentServer): at once where they can have it (AbilityServer.choose),
--     the kit starting over as the mode starts one, or with their next life
-- Each cast is told to clients (the Ability remote) for its sound and look,
-- when the frame on their screen reaches it, but Blade Storm's knives drawn
-- again and an ability put in hand (Curveball's flare, system 30; Hot
-- Hands' fireball, system 31; Blaze's flame, system 32), which others see
-- in hand, the Healing Orb's tries (system 36), which HealServer judges and
-- tells of as one heals, the Barrier Orb's wall (system 38), which
-- BarrierServer tells of as it rises, Omen going in his Shrouded Step
-- (system 42), which StepServer tells of with where he's going, his Shade
-- and his being sent back in From the Shadows (system 43), which
-- ShadowServer tells of with the places each client would hear, and a blast
-- of Sova's Hunter's Fury (system 46), which FuryServer tells of with the
-- way it went and whom it revealed: Run it Back's mark and rising to every
-- client, as the mark's drawn for everyone, and From the Shadows fired,
-- heard across the map, Dark Cover's orb sent (system 40) to the caster's
-- side alone (Patch 11.00: 'Dark Cover no longer plays audio in third
-- person within 12.5 meters for opponents. This audio will still play for
-- Allies.'), and any other to those who'd hear it or have the caster in
-- their snapshots (the fog of war, system 35), Omen's arrival and his
-- forming from a Shade as far as their own curves go.
-- The caster's own client has predicted it already. Each kit
-- is a player attribute (AbilityConfig.KIT_ATTRIBUTE, as AbilitySim.summary
-- writes it), which scripted checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local FogOfWar = require(Shared.Combat.FogOfWar)
local PlayerSim = require(Shared.PlayerSim)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local SpikeServer = require(script.Parent.SpikeServer)
local FogServer = require(script.Parent.FogServer)

local AbilityServer = {}

-- Whether charges are bought (the spike rounds). Without, every life
-- starts with every charge.
AbilityServer.economy = false
-- Whether a spent charge comes back by itself, and the ultimate's points
-- fill (the course).
AbilityServer.refill = true
-- Whether there are no abilities at all (gun game, as the reference's
-- Escalation has 'No Agent-specific abilities').
AbilityServer.off = false
-- The agent whose kit every life has, where the mode has one for everyone:
-- none at all in deathmatch (AbilityConfig.NO_AGENT), with no passive
-- either. Nil where each player plays their own (system 29).
AbilityServer.agent = nil :: string?
-- How long the course waits, once nothing's under way, before it fills a
-- kit again (ours).
AbilityServer.REFILL_DELAY = 1.5
-- A mode's own kit (Team Deathmatch's, system 28), or nil for the usual:
-- its ultimate points and costs, and abilities that recharge over time.
AbilityServer.rules = nil :: AbilityConfig.ModeKit?

-- What a cast tells clients.
export type CastEvent = {
	entity: number,
	ability: string,
	kind: string,
	at: number, -- server time
	position: Vector3, -- studs: the caster's feet
	direction: Vector3, -- a unit vector
}

-- The casts every client is told of: Run it Back's mark, a flame on the
-- floor for everyone (system 33), and his rising at it, and From the
-- Shadows fired, which darkens every enemy's minimap (system 43).
local EVERYONE: { [string]: boolean } = { mark = true, rise = true, shadows = true }

-- Since when each kit has been short of a charge with nothing under way.
local shortSince: { [Player]: number } = {}
local shown: { [Player]: string } = {}
-- With a mode's own kit: when each kit's C, Q and E next have a charge back
-- (server time, 0 for none coming), and what its attribute says of them.
local due: { [Player]: { number } } = {}
local shownDue: { [Player]: string? } = {}
-- Each player's own agent, as they last picked it (system 29).
local chosen: { [Player]: string } = {}
-- In the spike rounds, the points each player's deaths this round have
-- earned, paid as the next starts (system 50).
local owed: { [Player]: number } = {}

-- Changes a player's kit, if they're playing, and sends them the change.
local function change(player: Player, apply: (AbilitySim.State) -> ())
	local kit = PlayerSimServer.abilitiesOf(player)
	if kit then
		apply(kit)
		PlayerSimServer.markDirty(player)
	end
end

-- What the ultimate of `agent`'s kit needs in the mode played: the mode's
-- own cost, if it has one, or 0 for the ultimate's.
local function needOf(agent: string): number
	local rules = AbilityServer.rules
	local def = AbilityConfig.abilityOf(agent, AbilityConfig.X)
	local cost = if rules and def then rules.ultimate[def.id] else nil
	return if cost then cost.value else 0
end

-- The agent whose kit a player's lives have: the mode's, or their own.
function AbilityServer.agentOf(player: Player): string
	return AbilityServer.agent or chosen[player] or AbilityConfig.DEFAULT_AGENT
end

-- How long a kit's ability in `slot` takes to bring a charge back in the
-- mode played, if it recharges over time there: the mode's time for it,
-- where the mode has its own kit, and otherwise its own cooldown, if it has
-- one (the Healing Orb's, system 36).
local function cooldownOf(kit: AbilitySim.State, slot: number): number?
	local rules = AbilityServer.rules
	local def = AbilitySim.def(kit, slot)
	if AbilityServer.off or not def or not AbilitySim.playable(def.id) then
		return nil
	end
	local recharge = def.recharge
	local seconds = if rules then rules.cooldowns[def.id] elseif recharge and recharge.kind == "cooldown" then recharge.seconds else nil
	return if seconds then seconds.value else nil
end

-- Whether any of a kit's abilities recharges over time in the mode played.
local function recharges(kit: AbilitySim.State): boolean
	for slot = AbilityConfig.C, AbilityConfig.E do
		if cooldownOf(kit, slot) then
			return true
		end
	end
	return false
end

-- As a round of the spike rounds starts, of the kind MatchRules.roundKind
-- says, in Swiftplay or not: the kit's round, and the ultimate's points for
-- it, with what last round's deaths are owed (system 50).
function AbilityServer.roundStarted(player: Player, kind: AbilitySim.RoundKind, swiftplay: boolean)
	local debt = owed[player] or 0
	owed[player] = nil
	change(player, function(kit)
		if kind == "match" then
			AbilitySim.reset(kit)
		elseif kind == "half" then
			AbilitySim.newHalf(kit)
		else
			AbilitySim.newRound(kit)
		end
		AbilitySim.roundPoints(kit, kind, debt, swiftplay)
	end)
end

-- A new kit, as the spike rounds or the course start: the agent's.
function AbilityServer.reset(player: Player)
	due[player] = nil
	owed[player] = nil
	change(player, function(kit)
		kit.agent = AbilityServer.agentOf(player)
		kit.need = needOf(kit.agent)
		AbilitySim.reset(kit)
	end)
end

-- A kit of the player's agent starting over at `now`, as a match of the
-- mode played starts: with a mode's own kit (Team Deathmatch's), no points,
-- the signature's full charges, and every charge short of its most that far
-- towards coming back.
local function startOver(player: Player, kit: AbilitySim.State, now: number)
	local rules = AbilityServer.rules
	kit.agent = AbilityServer.agentOf(player)
	kit.need = needOf(kit.agent)
	AbilitySim.reset(kit)
	if not rules then
		return
	end
	local coming = { 0, 0, 0 }
	for slot = AbilityConfig.C, AbilityConfig.E do
		local def = AbilitySim.def(kit, slot)
		local most = AbilitySim.maxCharges(kit, slot)
		local signature = def ~= nil and def.kind == "signature" and AbilitySim.playable(def.id)
		kit.charges[slot] = if signature then math.min(rules.signatureStart.value, most) else 0
		-- Nothing's bought here: every charge comes back.
		kit.owned[slot] = most
		local cooldown = cooldownOf(kit, slot)
		if cooldown and kit.charges[slot] < most then
			coming[slot] = now + cooldown * (1 - rules.headStart.value)
		end
	end
	due[player] = coming
end

-- A mode's own kit starting over at `now`, as a match of it starts (Team
-- Deathmatch's).
function AbilityServer.fresh(player: Player, now: number)
	change(player, function(kit)
		startOver(player, kit, now)
	end)
end

-- Another agent's kit (system 29), as the mode played starts one, with
-- nothing of the last agent's: in Team Deathmatch as a match of it starts,
-- in gun game none, and elsewhere as a new match does, with every charge
-- where nothing's bought (and on the course the ultimate's points too).
local function newAgent(player: Player, kit: AbilitySim.State, now: number)
	due[player] = nil
	local points = kit.points
	startOver(player, kit, now)
	if AbilityServer.off then
		AbilitySim.empty(kit)
	elseif AbilityServer.economy then
		-- The spike rounds' points are the match's (system 50): Swiftplay's
		-- first two outlast the pick in its first buy phase.
		AbilitySim.addPoints(kit, points)
	elseif not AbilityServer.rules then
		AbilitySim.fill(kit, AbilityServer.refill)
	end
end

-- A player's own agent, picked (AgentServer): their kit's from their next
-- life, or with `atOnce` now. Returns whether their kit has changed now.
function AbilityServer.choose(player: Player, agent: string, now: number, atOnce: boolean): boolean
	chosen[player] = agent
	local kit = PlayerSimServer.abilitiesOf(player)
	if not atOnce or not kit or kit.agent == AbilityServer.agentOf(player) then
		return false
	end
	newAgent(player, kit, now)
	PlayerSimServer.markDirty(player)
	return true
end

-- Ultimate points for a player (Team Deathmatch's Ultimate Orbs, system 28).
function AbilityServer.addPoints(player: Player, amount: number)
	change(player, function(kit)
		AbilitySim.addPoints(kit, amount)
	end)
end

-- A kit's abilities recharging at `now`: each slot short of what it's had
-- this round (AbilitySim.rechargeTo: never a charge that wasn't bought) has
-- a charge back once its time's up, and its next on the way.
local function recharge(player: Player, kit: AbilitySim.State, now: number)
	local coming = due[player]
	if not coming then
		coming = { 0, 0, 0 }
		due[player] = coming
	end
	local changed = false
	for slot = AbilityConfig.C, AbilityConfig.E do
		local cooldown = cooldownOf(kit, slot)
		local upTo = AbilitySim.rechargeTo(kit, slot)
		if not cooldown or kit.charges[slot] >= upTo then
			coming[slot] = 0
		elseif coming[slot] == 0 then
			coming[slot] = now + cooldown
		elseif now >= coming[slot] then
			kit.charges[slot] += 1
			changed = true
			coming[slot] = if kit.charges[slot] < upTo then now + cooldown else 0
		end
	end
	if changed then
		PlayerSimServer.markDirty(player)
	end
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
-- them, the recharge, and each kit told to clients, with Drift's glide and
-- when its charges come back.
function AbilityServer.step(now: number)
	for _, player in Players:GetPlayers() do
		local kit = PlayerSimServer.abilitiesOf(player)
		if not kit then
			continue
		end
		local recharging: string? = nil
		if AbilityServer.rules or recharges(kit) then
			recharge(player, kit, now)
			local coming = due[player]
			recharging = string.format("%.2f,%.2f,%.2f", coming[1], coming[2], coming[3])
		end
		if shownDue[player] ~= recharging then
			shownDue[player] = recharging
			player:SetAttribute(AbilityConfig.RECHARGE_ATTRIBUTE, recharging)
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
		if
			not entity
			or cast.kind == "draw"
			or cast.kind == "equip"
			or cast.kind == "heal"
			or cast.kind == "selfheal"
			or cast.kind == "barrier"
			or cast.kind == "vanish"
			or cast.kind == "shade"
			or cast.kind == "home"
			or cast.kind == "blast"
			or cast.kind == "dart"
			or cast.kind == "land"
		then
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
		local remote = Remotes.get().Ability
		if EVERYONE[cast.kind] then
			remote:FireAllClients(event)
			return
		end
		if cast.kind == "smoke" then
			local side = player:GetAttribute(ArenaConfig.SIDE)
			for _, other in Players:GetPlayers() do
				if other == player or (side ~= nil and other:GetAttribute(ArenaConfig.SIDE) == side) then
					remote:FireClient(other, event)
				end
			end
			return
		end
		local edge = if cast.kind == "arrive"
			then FogOfWar.Edges.arrive
			elseif cast.kind == "form" then FogOfWar.Edges.shade
			else FogOfWar.Edges.cast
		for _, other in Players:GetPlayers() do
			if FogServer.hears(other, cast.position, edge, entity.id) then
				remote:FireClient(other, event)
			end
		end
	end)
	-- Every life is the agent's, another agent's kit starting over (one
	-- picked while it couldn't be had at once), and on the course and in
	-- Skirmish starts with every charge, and on the course with the
	-- ultimate's points full; in gun game and deathmatch, with none. A mode's
	-- own kit carries on from the last life.
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		change(player, function(kit)
			if kit.agent ~= AbilityServer.agentOf(player) then
				newAgent(player, kit, Workspace:GetServerTimeNow())
			end
			kit.need = needOf(kit.agent)
			if AbilityServer.off then
				AbilitySim.empty(kit)
			elseif not AbilityServer.economy and not AbilityServer.rules then
				AbilitySim.fill(kit, AbilityServer.refill)
			end
		end)
	end)
	table.insert(CombatServer.killListeners, function(attacker, victim, weapon, mode)
		local by = if attacker then attacker.player else nil
		local sim = if by and by ~= victim.player then PlayerSimServer.getSim(by) else nil
		local rules = AbilityServer.rules
		if by and sim and not AbilityServer.off then
			PlayerSim.killedWith(sim, weapon, mode, if rules then rules.kill.value else nil)
			PlayerSimServer.markDirty(by)
		end
	end)
	-- In the spike rounds a death's point waits for the next round, and only
	-- someone else's doing earns one (system 50).
	table.insert(PlayerSimServer.deathListeners, function(player: Player, killer: Player?)
		local rules = AbilityServer.rules
		local later = AbilityServer.economy
		if later and killer and not AbilityServer.off then
			owed[player] = (owed[player] or 0) + AbilityConfig.Points.death.value
		end
		change(player, function(kit)
			if AbilityServer.off then
				AbilitySim.empty(kit)
			else
				AbilitySim.died(kit, if later then 0 elseif rules then rules.death.value else nil)
			end
		end)
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
		due[player] = nil
		shownDue[player] = nil
		chosen[player] = nil
		owed[player] = nil
	end)
end

return AbilityServer
