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
--   * the ultimate's points: one for a kill (a dummy's too), a death, a
--     plant and a defuse; and kills bring the signature's charge back
--     (Jett's: two). A kill with a single Blade Storm knife brings all its
--     knives back (PlayerSim.killedWith, system 19)
--   * in gun game (system 23) there are none: every life starts with an
--     empty kit, and nothing fills it. Nor in deathmatch (system 26), where
--     the kit is no agent's at all, so Jett's glide is gone too
--   * each player's kit is their own agent's, as they pick it (system 29,
--     AgentServer): at once where they can have it (AbilityServer.choose),
--     the kit starting over as the mode starts one, or with their next life
-- Each cast is told to every client (the Ability remote) for its sound and
-- look, when the frame on their screen reaches it, but Blade Storm's knives
-- drawn again and Curveball's flare put in hand (system 30), which others see
-- in hand. The caster's own client has predicted it already. Each kit is a
-- player attribute (AbilityConfig.KIT_ATTRIBUTE, as AbilitySim.summary
-- writes it), which scripted checks read.

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

-- Since when each kit has been short of a charge with nothing under way.
local shortSince: { [Player]: number } = {}
local shown: { [Player]: string } = {}
-- With a mode's own kit: when each kit's C, Q and E next have a charge back
-- (server time, 0 for none coming), and what its attribute says of them.
local due: { [Player]: { number } } = {}
local shownDue: { [Player]: string? } = {}
-- Each player's own agent, as they last picked it (system 29).
local chosen: { [Player]: string } = {}

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
-- mode played, if it recharges over time there.
local function cooldownOf(kit: AbilitySim.State, slot: number): number?
	local rules = AbilityServer.rules
	local def = AbilitySim.def(kit, slot)
	local seconds = if rules and def and AbilitySim.playable(def.id) then rules.cooldowns[def.id] else nil
	return if seconds then seconds.value else nil
end

-- As a round of the spike rounds starts: "match" for the first of a match,
-- "half" for the first of the second half, "round" for any other.
function AbilityServer.roundStarted(player: Player, kind: "match" | "half" | "round")
	change(player, if kind == "match" then AbilitySim.reset elseif kind == "half" then AbilitySim.newHalf else AbilitySim.newRound)
end

-- A new kit, as the spike rounds or the course start: the agent's.
function AbilityServer.reset(player: Player)
	due[player] = nil
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
	startOver(player, kit, now)
	if AbilityServer.off then
		AbilitySim.empty(kit)
	elseif not AbilityServer.economy and not AbilityServer.rules then
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

-- A mode's abilities recharging at `now`: each slot short of its most has a
-- charge back once its time's up, and its next on the way.
local function recharge(player: Player, kit: AbilitySim.State, now: number)
	local coming = due[player]
	if not coming then
		coming = { 0, 0, 0 }
		due[player] = coming
	end
	local changed = false
	for slot = AbilityConfig.C, AbilityConfig.E do
		local cooldown = cooldownOf(kit, slot)
		local most = AbilitySim.maxCharges(kit, slot)
		if not cooldown or kit.charges[slot] >= most then
			coming[slot] = 0
		elseif coming[slot] == 0 then
			coming[slot] = now + cooldown
		elseif now >= coming[slot] then
			kit.charges[slot] += 1
			changed = true
			coming[slot] = if kit.charges[slot] < most then now + cooldown else 0
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
-- them, a mode's recharge, and each kit told to clients, with Drift's glide
-- and when its charges come back.
function AbilityServer.step(now: number)
	for _, player in Players:GetPlayers() do
		local kit = PlayerSimServer.abilitiesOf(player)
		if not kit then
			continue
		end
		local recharging: string? = nil
		if AbilityServer.rules then
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
		if not entity or cast.kind == "draw" or cast.kind == "equip" then
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
	table.insert(PlayerSimServer.deathListeners, function(player: Player)
		local rules = AbilityServer.rules
		change(player, function(kit)
			if AbilityServer.off then
				AbilitySim.empty(kit)
			else
				AbilitySim.died(kit, if rules then rules.death.value else nil)
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
	end)
end

return AbilityServer
