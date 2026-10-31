--!strict
-- Basic Training on the server (system 72): while Workspace's
-- TrainingConfig.ON has the course play it, with the arena off (Arena.apply
-- says so), a server of its own for each player who picks it on the Play
-- menu, each player goes through TrainingRules' steps: starting on the spike
-- rounds' kit (the Classic and the knife, no shield), their way through
-- fed by what the server sees (each tick's movement and gun in hand, each
-- ability cast, each kill, the spike planted, defused or gone off) and
-- published on them as TrainingConfig's attributes for TrainingView. A
-- step that gives a weapon puts it in its slot as it starts, and again in
-- each life during it, and a gun that runs dry is given again full.
--
-- In Studio, the Training remote moves a player to a step by its key, for
-- checks (TestAim's VFTestTraining), and the Output has a line each time a
-- player's step changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilitySim = require(Shared.Abilities.AbilitySim)
local MatchConfig = require(Shared.Match.MatchConfig)
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local Remotes = require(Shared.Net.Remotes)
local Spike = require(Shared.Spike.Spike)
local TrainingConfig = require(Shared.Training.TrainingConfig)
local TrainingRules = require(Shared.Training.TrainingRules)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local SpikeServer = require(script.Parent.SpikeServer)
local Tuning = require(script.Parent.Tuning)

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value

local TrainingServer = {}

-- Whether Basic Training is played (Arena.apply sets it, with setOn).
TrainingServer.on = false

local states: { [Player]: TrainingRules.State } = {}

-- Publishes where a player is, as TrainingConfig's attributes.
local function publish(player: Player)
	local s = states[player]
	local step = if s then TrainingRules.current(s).key else nil
	local progress = if s then TrainingRules.progress(s) else nil
	local note = if s then s.note or "" else nil
	if player:GetAttribute(TrainingConfig.STEP) ~= step then
		player:SetAttribute(TrainingConfig.STEP, step)
		if step and RunService:IsStudio() then
			-- For checks.
			print(string.format("[VF] training: %d at %s", player.UserId, step))
		end
	end
	local noted = if s then s.notes else nil
	if player:GetAttribute(TrainingConfig.NOTED) ~= noted then
		player:SetAttribute(TrainingConfig.NOTED, noted)
	end
	if player:GetAttribute(TrainingConfig.PROGRESS) ~= progress then
		player:SetAttribute(TrainingConfig.PROGRESS, progress)
	end
	if player:GetAttribute(TrainingConfig.NOTE) ~= note then
		player:SetAttribute(TrainingConfig.NOTE, note)
	end
end

-- The weapon the step under way gives, put in its slot.
local function arm(player: Player)
	local s = states[player]
	local give = if s then TrainingRules.current(s).give else nil
	local def = if give then WeaponConfig.Defs[give] else nil
	if give and def then
		local held = PlayerSimServer.holding(player, def.slot)
		if held ~= give then
			PlayerSimServer.give(player, def.slot, give)
		end
	end
end

-- A player onto step `index`, afresh.
local function go(player: Player, index: number)
	local s = states[player]
	if not s then
		return
	end
	TrainingRules.go(s, index)
	arm(player)
	publish(player)
end

-- The step under way finished: onto the next.
local function finished(player: Player)
	local s = states[player]
	if s and s.index < #TrainingConfig.Steps then
		go(player, s.index + 1)
	end
end

-- A player starts at the first step, on the spike rounds' kit from their
-- next life (the arena spawns everyone on the course as it starts): now,
-- and again once PlayerSimServer surely has them, for someone who's only
-- just joined.
local function begin(player: Player)
	if states[player] or not player.Parent then
		return
	end
	local s = TrainingRules.new()
	states[player] = s
	PlayerSimServer.resetKit(player, MatchConfig.StartingKit, "")
	task.defer(function()
		if states[player] == s then
			PlayerSimServer.resetKit(player, MatchConfig.StartingKit, "")
		end
	end)
	publish(player)
end

local function finish(player: Player)
	if not states[player] then
		return
	end
	states[player] = nil
	PlayerSimServer.resetKit(player)
	publish(player)
end

-- Basic Training played or not: everyone in the server starts it, or
-- leaves it, back on the course's own kit from their next life.
function TrainingServer.setOn(on: boolean)
	if on == TrainingServer.on then
		return
	end
	TrainingServer.on = on
	for _, player in Players:GetPlayers() do
		if on then
			begin(player)
		else
			finish(player)
		end
	end
end

-- Whether a player is going through it.
function TrainingServer.has(player: Player): boolean
	return states[player] ~= nil
end

-- How many are.
function TrainingServer.playing(): number
	local n = 0
	for _ in states do
		n += 1
	end
	return n
end

-- Each tick a player plays: the spot, the walk, the reload and the shield.
local function onTick(actor: Instance, input: any)
	local player = if actor:IsA("Player") then actor else nil
	local s = if player then states[player] else nil
	local sim = if player and s then PlayerSimServer.getSim(player) else nil
	if not player or not s or not sim then
		return
	end
	local step = TrainingRules.current(s)
	local m, w = sim.movement, sim.weapons
	-- A gun run dry, magazine and all, is given again full, so nobody's
	-- held up for rounds.
	for slot = 1, 2 do
		local id = w.loadout[slot]
		if id ~= "" and w.ammo[slot] <= 0 and w.reserve[slot] <= 0 then
			PlayerSimServer.give(player, slot, id)
		end
	end
	local done = false
	if step.goal == "reach" then
		done = TrainingRules.reached(step, m.position, m.grounded, m.crouched)
	elseif step.goal == "walk" then
		local before = TrainingRules.progress(s)
		done = TrainingRules.walk(s, m.position, DT, bit32.band(input.buttons, B.Walk) ~= 0, m.grounded)
		if not done and TrainingRules.progress(s) ~= before then
			publish(player)
		end
	elseif step.goal == "reload" then
		done = TrainingRules.reload(s, w.loadout[w.equipped] or "", w.ammo[w.equipped] or 0)
	elseif step.goal == "shield" then
		local entity = PlayerSimServer.entityOf(player)
		done = entity ~= nil and entity.health.kind ~= ""
	elseif step.goal == "cast" then
		-- A slot whose ability can't be played yet counts as used, and
		-- Reyna's Devour and Dismiss, still to use, have the hint on Soul
		-- Orbs (system 73).
		local before = TrainingRules.progress(s)
		local kit = sim.abilities
		local hint: string? = nil
		local slots: { number } = step.slots or {}
		for _, slot in slots do
			local def = AbilitySim.def(kit, slot)
			if not def or not AbilitySim.playable(def.id) then
				TrainingRules.skip(s, slot)
			elseif (def.id == "devour" or def.id == "dismiss") and not s.cast[slot] then
				hint = TrainingConfig.Notes.soul
			end
		end
		s.hint = hint
		done = TrainingRules.used(s)
		if not done and TrainingRules.progress(s) ~= before then
			publish(player)
		end
	end
	if done then
		finished(player)
	end
end

-- Each ability cast.
local function onCast(actor: Instance, cast: any)
	local player = if actor:IsA("Player") then actor else nil
	local s = if player then states[player] else nil
	if not player or not s then
		return
	end
	if TrainingRules.cast(s, cast.slot, cast.kind) then
		finished(player)
	else
		publish(player)
	end
end

-- Each kill: a target downed by a player going through, how it was.
local function onKill(attacker: any, victim: any, _weapon: string, _mode: string?, region: string)
	local player: Player? = if attacker then attacker.player else nil
	local s = if player then states[player] else nil
	local sim = if player and s then PlayerSimServer.getSim(player) else nil
	local at = if victim.sim then victim.sim.movement.position else nil
	if not player or not s or not sim or not at or victim.kind ~= "dummy" then
		return
	end
	local how = {
		still = PlayerSim.isAccurate(sim, Tuning.config()),
		head = region == "head",
		scoped = sim.weapons.scoped > 0,
	}
	if TrainingRules.kill(s, at, how) then
		finished(player)
	else
		publish(player)
	end
end

local function onSpike(event: "planted" | "defused" | "detonated", by: Instance?)
	for player, s in states do
		if event == "detonated" or by == player then
			if TrainingRules.spike(s, event) then
				finished(player)
			else
				publish(player)
			end
		end
	end
end

function TrainingServer.start()
	table.insert(PlayerSimServer.tickListeners, onTick)
	table.insert(PlayerSimServer.castListeners, onCast)
	table.insert(CombatServer.killListeners, onKill)
	table.insert(SpikeServer.objectiveListeners, function(who: Instance, what: "planted" | "defused")
		onSpike(what, who)
	end)
	Workspace:GetAttributeChangedSignal(Spike.STATE):Connect(function()
		if Workspace:GetAttribute(Spike.STATE) == "detonated" then
			onSpike("detonated", nil)
		end
	end)
	-- A life during a step that gives a weapon has it.
	table.insert(PlayerSimServer.spawnListeners, arm)
	Players.PlayerAdded:Connect(function(player)
		if TrainingServer.on then
			-- Once PlayerSimServer has them, before their first life.
			task.defer(begin, player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	Remotes.get().Training.OnServerEvent:Connect(function(player: Player, key: any)
		local index = TrainingRules.indexOf(key)
		if RunService:IsStudio() and Tuning.canTune(player) and index and states[player] then
			go(player, index)
		end
	end)
end

return TrainingServer
