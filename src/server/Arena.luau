--!strict
-- The arena (system 7): a whitebox of the reference's Skirmish A, built beside
-- the course, played by Skirmish's rules (ArenaRules). While it's on,
-- everyone in the server is in it: split into two sides on Roblox teams (so
-- teammates show as allies and can't shoot each other), spawned in their
-- side's room facing the hall, held there behind a barrier for each buy
-- phase, and respawned, dead or alive, when a round starts. A new match puts
-- everyone back on the starting kit.
--
-- P (Studio or the place owner) turns it on and off. So does Workspace's
-- VFArenaOn attribute, set from the server, which is how scripted checks do
-- it, and which tells clients whether it's on. The phase and the score go to
-- clients as attributes on the arena's model.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local ArenaLayout = require(Shared.Arena.ArenaLayout)
local ArenaRules = require(Shared.Arena.ArenaRules)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local Tuning = require(script.Parent.Tuning)

local Arena = {}

-- Each side's team and colours: the room's floor, its barrier and the team.
local SIDES = {
	{ name = "North", floor = Color3.fromRGB(150, 110, 70), barrier = Color3.fromRGB(255, 160, 70), team = BrickColor.new("Neon orange") },
	{ name = "South", floor = Color3.fromRGB(70, 130, 125), barrier = Color3.fromRGB(70, 220, 200), team = BrickColor.new("Toothpaste") },
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

local model: Model? = nil
local barriers: { [number]: BasePart } = {}
local rules: ArenaRules.State? = nil
local teams: { Team } = {}
local published = -1
local queued: { [Player]: boolean } = {} -- spawns asked for and not started yet
local kitMatch: { [Player]: number } = {} -- the match each player last got the starting kit for

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

local function setBarriers(up: boolean)
	for _, barrier in barriers do
		barrier.CanCollide = up
		barrier.CanQuery = up
		barrier.Transparency = if up then 0.35 else 1
	end
end

-- Builds the arena from ArenaLayout, unless the place already has one.
function Arena.buildIfMissing()
	if Workspace:FindFirstChild(ArenaConfig.MODEL) then
		return
	end
	local root = Instance.new("Model")
	root.Name = ArenaConfig.MODEL
	-- Always on every client, wherever its player is, if the place streams.
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	for _, spec in ArenaLayout.parts() do
		local p = Instance.new("Part")
		p.Name = spec.name
		p.Anchored = true
		p.Size = Units.toStuds(spec.size)
		p.CFrame = CFrame.new(Units.toStuds(ArenaLayout.origin + spec.center)) * CFrame.Angles(0, spec.yaw, 0)
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Color = COVER[spec.name] or COLOURS[spec.kind] or COLOURS.wall
		local side = spec.side
		if spec.kind == "marking" then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			if side then
				p.Color = SIDES[side].floor
				sign(p, SIDES[side].name:upper())
			end
		elseif spec.kind == "barrier" and side then
			p.Material = Enum.Material.ForceField
			p.Color = SIDES[side].barrier
			p.CastShadow = false
			barriers[side] = p
		end
		p.Parent = root
	end
	root.Parent = Workspace
	model = root
	setBarriers(false)
end

local function playerFor(id: number): Player?
	return Players:GetPlayerByUserId(id)
end

-- Once whatever event this is has been handled, and once each however many
-- times they're asked for meanwhile. Each player's first life in a match
-- starts on the starting kit, whatever they bought in the last match or on
-- the course. Roblox takes a moment to load the character, and what they buy
-- meanwhile is held for the new life (ShopServer).
local function spawn(ids: { number })
	local s = rules
	for _, id in ids do
		local player = playerFor(id)
		if player and s and kitMatch[player] ~= s.match then
			kitMatch[player] = s.match
			PlayerSimServer.resetKit(player)
		end
		if player then
			PlayerSimServer.expectSpawn(player)
		end
		if player and not queued[player] then
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

-- Tells clients the phase and the score, and moves the barriers, when they've changed.
local function publish()
	local s = rules
	local version = if s then s.version else -1
	if version == published then
		return
	end
	published = version
	local root = model
	if root then
		root:SetAttribute("Phase", if s then s.phase else nil)
		root:SetAttribute("Round", if s then s.round else nil)
		root:SetAttribute("Score1", if s then s.score[1] else nil)
		root:SetAttribute("Score2", if s then s.score[2] else nil)
		root:SetAttribute("RoundWinner", if s then s.roundWinner else nil)
		root:SetAttribute("MatchWinner", if s then s.matchWinner else nil)
		root:SetAttribute("PhaseEndsAt", if s then s.phaseEndsAt else nil)
		root:SetAttribute("WinScore", ArenaConfig.Rules.winScore.value)
	end
	setBarriers(s ~= nil and ArenaRules.barriersUp(s))
end

local function join(player: Player)
	local s = rules
	if not s then
		return
	end
	local ids = ArenaRules.join(s, player.UserId, now())
	local side = ArenaRules.sideOf(s, player.UserId)
	if side then
		player.Team = teams[side]
		player.Neutral = false
		player:SetAttribute(ArenaConfig.SIDE, side)
	end
	publish()
	spawn(ids)
end

local function setActive(on: boolean)
	if on == (rules ~= nil) then
		return
	end
	if on then
		rules = ArenaRules.new()
		table.clear(kitMatch)
		for side, info in SIDES do
			local team = Instance.new("Team")
			team.Name = info.name
			team.TeamColor = info.team
			team.AutoAssignable = false
			team.Parent = Teams
			teams[side] = team
		end
		-- The rounds decide when everyone spawns.
		Players.CharacterAutoLoads = false
		for _, player in Players:GetPlayers() do
			join(player)
		end
	else
		rules = nil
		Players.CharacterAutoLoads = true
		for _, player in Players:GetPlayers() do
			player.Team = nil
			player.Neutral = true
			player:SetAttribute(ArenaConfig.SIDE, nil)
			-- Back to the course.
			spawn({ player.UserId })
		end
		for _, team in teams do
			team:Destroy()
		end
		table.clear(teams)
		publish()
	end
	print(string.format("[VF] Arena %s", if on then "on" else "off"))
end

-- The rounds' clock, once a server frame.
function Arena.step(time: number)
	local s = rules
	if not s then
		return
	end
	local ids = ArenaRules.step(s, time)
	publish()
	spawn(ids)
end

function Arena.start()
	Workspace:SetAttribute(ArenaConfig.ON, false)
	Workspace:GetAttributeChangedSignal(ArenaConfig.ON):Connect(function()
		setActive(Workspace:GetAttribute(ArenaConfig.ON) == true)
	end)
	Remotes.get().Arena.OnServerEvent:Connect(function(player, on)
		if Tuning.canTune(player) and typeof(on) == "boolean" then
			Workspace:SetAttribute(ArenaConfig.ON, on)
		end
	end)

	PlayerSimServer.spawnPicker = function(player: Player): PlayerSimServer.SpawnPoint?
		local s = rules
		local side = s and ArenaRules.sideOf(s, player.UserId)
		local spot = s and ArenaRules.spotOf(s, player.UserId)
		if not side or not spot then
			return nil
		end
		local spots = ArenaLayout.spots(side)
		local chosen = spots[(spot - 1) % #spots + 1]
		return { feet = ArenaLayout.origin + chosen.feet, yaw = chosen.yaw }
	end
	PlayerSimServer.loadoutRule = function(player: Player): boolean?
		local s = rules
		return if s then ArenaRules.canPick(s, player.UserId) else nil
	end
	table.insert(PlayerSimServer.deathListeners, function(player: Player)
		local s = rules
		if s then
			ArenaRules.died(s, player.UserId, now())
			publish()
		end
	end)

	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player)
		queued[player] = nil
		kitMatch[player] = nil
		local s = rules
		if s then
			ArenaRules.leave(s, player.UserId, now())
			publish()
		end
	end)
end

return Arena
