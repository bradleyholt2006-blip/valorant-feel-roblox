--!strict
-- The arena (system 7) and the spike rounds (system 13), whichever is on.
--
-- The arena: a whitebox of the reference's Skirmish A, built beside the
-- course, played by Skirmish's rules (ArenaRules). The spike rounds: a
-- two-site map of our own (MatchMap), built off the other side of the
-- course, played by the reference's standard match (MatchRules): one side
-- attacks with the spike, the other defends the sites, and they swap at the
-- half. SpikeServer runs the spike itself, by the rounds' say.
--
-- While either is on, everyone in the server is in it: split into two sides
-- on Roblox teams (so teammates show as allies and can't shoot each other),
-- spawned in their side's room facing out, held there behind barriers for
-- each buy phase, and respawned, dead or alive, when a round starts. A new
-- match puts everyone back on its starting kit. In the spike rounds so does
-- each half, and so does dying: 'If you die the previous round, you will
-- lose any purchased weapons and armor' (Hotspawn's economy guide;
-- community).
--
-- The spike rounds have the reference's economy (system 14): MatchRules
-- keeps everyone's credits, the buy menu charges them (ShopServer.pay), and
-- a survivor keeps their shield as it was into the next round, damaged or
-- not. Each player's credits go to clients as a player attribute
-- (MatchConfig.CREDITS), and each side's losses in a row as the arena
-- model's Streak1 and Streak2.
--
-- Guns on the ground (system 15, GroundGunsServer): each round of either
-- starts with the ground cleared, and in the spike rounds the dead drop
-- their gun where they fall.
--
-- P (Studio or the place owner) moves on through the arena, the spike rounds
-- in the standard format, the spike rounds in Swiftplay's, and off. So do
-- Workspace's attributes, set from the server, which is how scripted checks
-- do it, and which tell clients what's on: VFArenaOn, VFArenaMode
-- ("skirmish" or "spike") and VFMatchFormat (a key of MatchConfig.Formats).
-- The phase and the score go to clients as attributes on the arena's model,
-- whichever is played.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local ArenaLayout = require(Shared.Arena.ArenaLayout)
local ArenaRules = require(Shared.Arena.ArenaRules)
local MatchConfig = require(Shared.Match.MatchConfig)
local MatchMap = require(Shared.Match.MatchMap)
local MatchRules = require(Shared.Match.MatchRules)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local ShopServer = require(script.Parent.ShopServer)
local SpikeServer = require(script.Parent.SpikeServer)
local GroundGunsServer = require(script.Parent.GroundGunsServer)
local Tuning = require(script.Parent.Tuning)

local Arena = {}

export type Mode = "skirmish" | "spike"

-- Each side's team and colours: the arena room's floor, its barrier and the
-- team. In the spike rounds the teams go by their colours, as their spawns
-- swap at the half.
local SIDES = {
	{
		name = "North",
		colour = "Orange",
		floor = Color3.fromRGB(150, 110, 70),
		barrier = Color3.fromRGB(255, 160, 70),
		team = BrickColor.new("Neon orange"),
	},
	{
		name = "South",
		colour = "Teal",
		floor = Color3.fromRGB(70, 130, 125),
		barrier = Color3.fromRGB(70, 220, 200),
		team = BrickColor.new("Toothpaste"),
	},
}

local COLOURS: { [string]: Color3 } = {
	floor = Color3.fromRGB(70, 72, 80),
	wall = Color3.fromRGB(200, 200, 205),
	marking = Color3.fromRGB(95, 98, 108),
}
local COVER: { [string]: Color3 } = {
	CentreBlock = Color3.fromRGB(175, 175, 182),
	DoubleCrate = Color3.fromRGB(150, 152, 160),
	SideCrate = Color3.fromRGB(125, 128, 136),
	WallCrate = Color3.fromRGB(125, 128, 136),
}
-- The spike rounds' map: cover a player can see over darker than cover they
-- can't, the sites' plant areas marked on the floor, and each spawn's floor
-- and barriers in its role's colour.
local MAP_COLOURS: { [string]: Color3 } = {
	low = Color3.fromRGB(135, 138, 146),
	high = Color3.fromRGB(170, 172, 180),
	site = Color3.fromRGB(150, 128, 72),
}
local ROLE_COLOURS: { [string]: { floor: Color3, barrier: Color3 } } = {
	attack = { floor = Color3.fromRGB(140, 88, 80), barrier = Color3.fromRGB(255, 120, 90) },
	defend = { floor = Color3.fromRGB(72, 112, 135), barrier = Color3.fromRGB(90, 200, 255) },
}

local model: Model? = nil -- the arena's, which carries the state of play
local barriers: { BasePart } = {} -- the arena's
local mapBarriers: { BasePart } = {} -- the spike rounds' map's
local mode: Mode? = nil
local skirmish: ArenaRules.State? = nil
local match: MatchRules.State? = nil
local teams: { Team } = {}
local published = -1
local queued: { [Player]: boolean } = {} -- spawns asked for and not started yet
local kitMatch: { [Player]: number } = {} -- the match each player last got the starting kit for
-- The round the ground was last cleared for, and in the spike rounds the
-- spike and the kits were last set for.
local seenMatch, seenRound = 0, 0

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function sign(target: BasePart, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.PixelsPerStud = 20
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextTransparency = 0.4
	label.Text = text
	label.Parent = gui
	gui.Parent = target
end

local function raise(parts: { BasePart }, up: boolean)
	for _, barrier in parts do
		barrier.CanCollide = up
		barrier.CanQuery = up
		barrier.Transparency = if up then 0.35 else 1
	end
end

local function newPart(name: string, size: vector, center: vector, yaw: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = Units.toStuds(size)
	p.CFrame = CFrame.new(Units.toStuds(center)) * CFrame.Angles(0, yaw, 0)
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function marking(p: Part)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

local function newModel(name: string): Model
	local root = Instance.new("Model")
	root.Name = name
	-- Always on every client, wherever its player is, if the place streams.
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	return root
end

-- Builds the arena from ArenaLayout and the spike rounds' map from MatchMap,
-- unless the place already has them.
function Arena.buildIfMissing()
	if not Workspace:FindFirstChild(ArenaConfig.MODEL) then
		local root = newModel(ArenaConfig.MODEL)
		for _, spec in ArenaLayout.parts() do
			local p = newPart(spec.name, spec.size, ArenaLayout.origin + spec.center, spec.yaw)
			p.Color = COVER[spec.name] or COLOURS[spec.kind] or COLOURS.wall
			local side = spec.side
			if spec.kind == "marking" then
				marking(p)
				if side then
					p.Color = SIDES[side].floor
					sign(p, SIDES[side].name:upper())
				end
			elseif spec.kind == "barrier" and side then
				p.Material = Enum.Material.ForceField
				p.Color = SIDES[side].barrier
				p.CastShadow = false
				table.insert(barriers, p)
			end
			p.Parent = root
		end
		root.Parent = Workspace
		model = root
		raise(barriers, false)
	end

	if not Workspace:FindFirstChild(MatchConfig.MODEL) then
		local root = newModel(MatchConfig.MODEL)
		for _, spec in MatchMap.parts() do
			local p = newPart(spec.name, spec.size, MatchMap.origin + spec.center, spec.yaw)
			p.Color = COLOURS[spec.kind] or COLOURS.wall
			local role = spec.role
			if spec.kind == "cover" then
				p.Color = if spec.size.y < MatchMap.Heights.high.value then MAP_COLOURS.low else MAP_COLOURS.high
			elseif spec.kind == "marking" then
				marking(p)
				if role then
					p.Color = ROLE_COLOURS[role].floor
					sign(p, if role == "attack" then "ATTACKERS" else "DEFENDERS")
				elseif spec.site then
					p.Color = MAP_COLOURS.site
					sign(p, spec.site)
				end
			elseif spec.kind == "barrier" and role then
				p.Material = Enum.Material.ForceField
				p.Color = ROLE_COLOURS[role].barrier
				p.CastShadow = false
				table.insert(mapBarriers, p)
			end
			p.Parent = root
		end
		root.Parent = Workspace
		raise(mapBarriers, false)
	end
end

local function playerFor(id: number): Player?
	return Players:GetPlayerByUserId(id)
end

-- From the player's next life, the starting kit of what's played: Skirmish's
-- (WeaponConfig's default) or the spike rounds' (the Classic and the knife,
-- no shield).
local function startingKit(player: Player)
	if mode == "spike" then
		PlayerSimServer.resetKit(player, MatchConfig.StartingKit, "")
	else
		PlayerSimServer.resetKit(player)
	end
end

-- Once whatever event this is has been handled, and once each however many
-- times they're asked for meanwhile. Each player's first life in a match
-- starts on the starting kit, whatever they bought in the last match or on
-- the course. Roblox takes a moment to load the character, and what they buy
-- meanwhile is held for the new life (ShopServer).
local function spawn(ids: { number })
	local s, m = skirmish, match
	local matchNumber = if s then s.match elseif m then m.match else nil
	for _, id in ids do
		local player = playerFor(id)
		if not player then
			continue
		end
		if matchNumber and kitMatch[player] ~= matchNumber then
			kitMatch[player] = matchNumber
			startingKit(player)
		end
		PlayerSimServer.expectSpawn(player)
		if not queued[player] then
			queued[player] = true
			task.defer(function()
				queued[player] = nil
				if player.Parent then
					player:LoadCharacterAsync()
				end
			end)
		end
	end
end

-- Tells clients the phase and the score, moves the barriers, and tells the
-- spike who attacks and whether it can be planted, when they've changed.
local function publish()
	local s, m = skirmish, match
	local version = if s then s.version elseif m then m.version else -1
	if version == published then
		return
	end
	published = version
	local root = model
	if root then
		local state = s or m
		root:SetAttribute("Mode", mode)
		root:SetAttribute("Phase", if state then state.phase else nil)
		root:SetAttribute("Round", if state then state.round else nil)
		root:SetAttribute("Score1", if state then state.score[1] else nil)
		root:SetAttribute("Score2", if state then state.score[2] else nil)
		root:SetAttribute("RoundWinner", if state then state.roundWinner else nil)
		root:SetAttribute("MatchWinner", if state then state.matchWinner else nil)
		root:SetAttribute("PhaseEndsAt", if state then state.phaseEndsAt else nil)
		root:SetAttribute("WinScore", if m then m.format.winScore.value elseif s then ArenaConfig.Rules.winScore.value else nil)
		-- The spike rounds' own: the format (a key of MatchConfig.Formats), the
		-- side attacking, and how the round just played was won.
		root:SetAttribute("Format", if m then m.formatKey else nil)
		root:SetAttribute("Attackers", if m then m.attackers else nil)
		root:SetAttribute("Reason", if m then m.reason else nil)
		root:SetAttribute("Streak1", if m then m.streak[1] else nil)
		root:SetAttribute("Streak2", if m then m.streak[2] else nil)
	end
	if m then
		for id, member in m.members do
			local player = playerFor(id)
			if player then
				player:SetAttribute(MatchConfig.CREDITS, member.credits)
			end
		end
	end
	raise(barriers, s ~= nil and ArenaRules.barriersUp(s))
	raise(mapBarriers, m ~= nil and MatchRules.barriersUp(m))
	if m then
		SpikeServer.setRound(m.attackers, MatchRules.canPlant(m))
	end
end

-- A round has started since this last looked: the ground cleared, and in
-- the spike rounds a new spike in front of the attackers and, at the start
-- of each half, everyone back on the starting kit.
local function roundStarted()
	local s, m = skirmish, match
	local phase = if s then s.phase elseif m then m.phase else nil
	local matchNumber = if s then s.match elseif m then m.match else 0
	local round = if s then s.round elseif m then m.round else 0
	if phase ~= "buy" or (matchNumber == seenMatch and round == seenRound) then
		return
	end
	seenMatch, seenRound = matchNumber, round
	GroundGunsServer.clear()
	if not m then
		return
	end
	SpikeServer.reset()
	if MatchRules.startsHalf(m) then
		for id in m.members do
			local player = playerFor(id)
			if player then
				kitMatch[player] = m.match
				startingKit(player)
			end
		end
	end
end

local function join(player: Player)
	local id = player.UserId
	local ids: { number }
	local side: number?
	local s, m = skirmish, match
	if s then
		ids = ArenaRules.join(s, id, now())
		side = ArenaRules.sideOf(s, id)
	elseif m then
		ids = MatchRules.join(m, id, now())
		side = MatchRules.sideOf(m, id)
	else
		return
	end
	if side then
		player.Team = teams[side]
		player.Neutral = false
		player:SetAttribute(ArenaConfig.SIDE, side)
	end
	publish()
	roundStarted()
	spawn(ids)
end

-- What the spike rounds hear of the spike.
local spikeEvents: SpikeServer.Events = {
	planted = function(detonateAt: number)
		local m = match
		if m then
			MatchRules.planted(m, detonateAt)
			publish()
		end
	end,
	defused = function(time: number)
		local m = match
		if m then
			MatchRules.defused(m, time)
			publish()
		end
	end,
	detonated = function(time: number)
		local m = match
		if m then
			MatchRules.detonated(m, time)
			publish()
		end
	end,
}

-- Ends whatever's played: no sides, no teams.
local function stop()
	local was = mode
	if was == nil then
		return
	end
	mode, skirmish, match = nil, nil, nil
	if was == "spike" then
		SpikeServer.stopRounds()
	end
	PlayerSimServer.keepShields = false
	GroundGunsServer.dropOnDeath = false
	GroundGunsServer.clear()
	for _, player in Players:GetPlayers() do
		player.Team = nil
		player.Neutral = true
		player:SetAttribute(ArenaConfig.SIDE, nil)
		player:SetAttribute(MatchConfig.CREDITS, nil)
	end
	for _, team in teams do
		team:Destroy()
	end
	table.clear(teams)
end

-- Starts `wanted`, with everyone in it; the spike rounds in the format
-- `format` names.
local function begin(wanted: Mode, format: string)
	mode = wanted
	if wanted == "skirmish" then
		skirmish = ArenaRules.new()
	else
		match = MatchRules.new(format)
	end
	table.clear(kitMatch)
	seenMatch, seenRound = 0, 0
	GroundGunsServer.clear()
	for side, info in SIDES do
		local team = Instance.new("Team")
		team.Name = if wanted == "skirmish" then info.name else info.colour
		team.TeamColor = info.team
		team.AutoAssignable = false
		team.Parent = Teams
		teams[side] = team
	end
	if wanted == "spike" then
		SpikeServer.startRounds(spikeEvents)
		PlayerSimServer.keepShields = true
		GroundGunsServer.dropOnDeath = true
	end
	-- The rounds decide when everyone spawns.
	Players.CharacterAutoLoads = false
	published = -2
	for _, player in Players:GetPlayers() do
		join(player)
	end
	publish()
end

-- Plays what Workspace's attributes ask for, if it isn't already.
local function apply()
	local wanted: Mode? = nil
	if Workspace:GetAttribute(ArenaConfig.ON) == true then
		wanted = if Workspace:GetAttribute(ArenaConfig.MODE) == "spike" then "spike" else "skirmish"
	end
	local asked = Workspace:GetAttribute(MatchConfig.FORMAT)
	local format = if typeof(asked) == "string" and MatchConfig.Formats[asked] then asked else MatchConfig.DEFAULT_FORMAT
	local m = match
	if wanted == mode and (wanted ~= "spike" or (m ~= nil and m.formatKey == format)) then
		return
	end
	stop()
	if wanted then
		begin(wanted, format)
		local m2 = match
		print(string.format("[VF] Arena on: %s", if m2 then "the spike rounds, " .. m2.format.name else "Skirmish"))
	else
		Players.CharacterAutoLoads = true
		published = -2
		publish()
		-- Back to the course.
		for _, player in Players:GetPlayers() do
			spawn({ player.UserId })
		end
		print("[VF] Arena off")
	end
end

-- The rounds' clock, once a server frame.
function Arena.step(time: number)
	local ids: { number }
	local s, m = skirmish, match
	if s then
		ids = ArenaRules.step(s, time)
	elseif m then
		ids = MatchRules.step(m, time)
	else
		return
	end
	publish()
	roundStarted()
	spawn(ids)
end

function Arena.start()
	Workspace:SetAttribute(ArenaConfig.ON, false)
	if Workspace:GetAttribute(ArenaConfig.MODE) == nil then
		Workspace:SetAttribute(ArenaConfig.MODE, "skirmish")
	end
	if Workspace:GetAttribute(MatchConfig.FORMAT) == nil then
		Workspace:SetAttribute(MatchConfig.FORMAT, MatchConfig.DEFAULT_FORMAT)
	end
	for _, name in { ArenaConfig.ON, ArenaConfig.MODE, MatchConfig.FORMAT } do
		Workspace:GetAttributeChangedSignal(name):Connect(apply)
	end
	Workspace:GetAttributeChangedSignal(MatchConfig.SKIP):Connect(function()
		if Workspace:GetAttribute(MatchConfig.SKIP) ~= true then
			return
		end
		Workspace:SetAttribute(MatchConfig.SKIP, nil)
		local m = match
		if m then
			MatchRules.skip(m, now())
			publish()
		end
	end)
	-- P asks for the next of: "skirmish", a format of the spike rounds, or
	-- "off" (true and false are the arena on and off).
	Remotes.get().Arena.OnServerEvent:Connect(function(player, asked)
		if not Tuning.canTune(player) then
			return
		end
		if asked == false or asked == "off" then
			Workspace:SetAttribute(ArenaConfig.ON, false)
		elseif asked == true or asked == "skirmish" then
			Workspace:SetAttribute(ArenaConfig.MODE, "skirmish")
			Workspace:SetAttribute(ArenaConfig.ON, true)
		elseif typeof(asked) == "string" and MatchConfig.Formats[asked] then
			Workspace:SetAttribute(MatchConfig.FORMAT, asked)
			Workspace:SetAttribute(ArenaConfig.MODE, "spike")
			Workspace:SetAttribute(ArenaConfig.ON, true)
		end
	end)

	PlayerSimServer.spawnPicker = function(player: Player): PlayerSimServer.SpawnPoint?
		local id = player.UserId
		local s, m = skirmish, match
		if s then
			local side, spot = ArenaRules.sideOf(s, id), ArenaRules.spotOf(s, id)
			if not side or not spot then
				return nil
			end
			local spots = ArenaLayout.spots(side)
			local chosen = spots[(spot - 1) % #spots + 1]
			return { feet = ArenaLayout.origin + chosen.feet, yaw = chosen.yaw }
		elseif m then
			-- The spawn of the side's role this round.
			local spot = MatchRules.spotOf(m, id)
			if not spot then
				return nil
			end
			local spots = MatchMap.spots(if MatchRules.attacking(m, id) then "attack" else "defend")
			local chosen = spots[(spot - 1) % #spots + 1]
			return { feet = MatchMap.origin + chosen.feet, yaw = chosen.yaw }
		end
		return nil
	end
	PlayerSimServer.loadoutRule = function(player: Player): boolean?
		local s, m = skirmish, match
		if s then
			return ArenaRules.canPick(s, player.UserId)
		elseif m then
			return MatchRules.canPick(m, player.UserId)
		end
		return nil
	end
	-- What a purchase costs, in the spike rounds.
	ShopServer.pay = function(player: Player, amount: number): boolean
		local m = match
		if not m then
			return true
		end
		local paid = MatchRules.spend(m, player.UserId, amount)
		publish()
		return paid
	end
	table.insert(PlayerSimServer.deathListeners, function(player: Player, killer: Player?)
		local s, m = skirmish, match
		if s then
			ArenaRules.died(s, player.UserId, now())
			publish()
		elseif m then
			MatchRules.died(m, player.UserId, now(), if killer then killer.UserId else nil)
			-- What they bought is lost with them.
			startingKit(player)
			publish()
		end
	end)

	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player)
		queued[player] = nil
		kitMatch[player] = nil
		local s, m = skirmish, match
		if s then
			ArenaRules.leave(s, player.UserId, now())
			publish()
		elseif m then
			MatchRules.leave(m, player.UserId, now())
			publish()
		end
	end)
end

return Arena
