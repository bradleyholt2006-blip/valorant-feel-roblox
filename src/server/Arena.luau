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
-- The round at a glance (system 16): in either, whether each player is
-- alive (MatchConfig.ALIVE) and the guns they hold (MatchConfig.LOADOUT), as
-- player attributes; in the spike rounds, their record this match too
-- (kills, deaths, assists, combat score and rounds played), which
-- MatchRules keeps from every hit between players and every death.
--
-- Abilities (system 17, AbilityServer): in the spike rounds charges are
-- bought, a new match starts everyone on a new kit, each half takes away
-- what was bought, and each round gives the signature its free charge. In
-- Skirmish every life has every charge.
--
-- Matches that never stop (system 21): a live server plays from the moment
-- it starts, Skirmish unless the place's VFArenaMode says otherwise, so
-- whoever joins drops into a match under way, and one match follows another
-- after the victory screen. Studio starts on the course, the practice range,
-- unless the place's VFArenaOn says otherwise. Who plays on which side is
-- Roster's: someone joining mid-round waits for the next round, anyone over
-- the mode's team size waits in line for a place (ArenaConfig.LINE), and
-- the sides are evened out before each round, so players move between teams
-- here as the rules move them. In either mode every player has a record
-- this match, for the scoreboard and the victory screen.
--
-- The vote for the next map (system 22): Skirmish is played on A, B or C,
-- the first match on one at random, and after each match's victory screen
-- everyone in the server votes for the next (ArenaRules, MapVote) by
-- clicking a map (the Vote remote). The maps share the hall and differ in
-- their cover, so a new map is the arena's cover built anew, as the next
-- match starts with everyone in their rooms. The arena's model says which
-- map is played, and during the vote the maps to pick from and their votes;
-- each player's own vote is their ArenaConfig.VOTE attribute.
--
-- Gun game (system 23, GunGameRules) is played in the arena too, on the
-- same maps and with the same vote between matches: each player's level
-- picks the gun they carry, given them as each life starts and, as they
-- move up mid-life, put straight in their hands. Nothing's bought, nothing
-- lies on the ground and there are no abilities (AbilityServer.off). A new
-- life can't be hurt for a moment (CombatServer.protected), until they
-- fire. Each player's level and protection go to clients as player
-- attributes (GunGameConfig), and the match's ladder of guns and who leads
-- as the arena model's Ladder and Leader.
--
-- P (Studio or the place owner) moves on through the arena, gun game, the
-- spike rounds in the standard format, the spike rounds in Swiftplay's, and
-- off. So do Workspace's attributes, set from the server, which is how
-- scripted checks do it, and which tell clients what's on: VFArenaOn,
-- VFArenaMode ("skirmish", "gungame" or "spike") and VFMatchFormat (a key of
-- MatchConfig.Formats). The phase and the score go to clients as attributes
-- on the arena's model, whichever is played.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local ArenaLayout = require(Shared.Arena.ArenaLayout)
local ArenaRules = require(Shared.Arena.ArenaRules)
local GunGameConfig = require(Shared.Arena.GunGameConfig)
local GunGameRules = require(Shared.Arena.GunGameRules)
local MapVote = require(Shared.Match.MapVote)
local MatchConfig = require(Shared.Match.MatchConfig)
local MatchMap = require(Shared.Match.MatchMap)
local MatchRules = require(Shared.Match.MatchRules)
local Roster = require(Shared.Match.Roster)
local PlayerSim = require(Shared.PlayerSim)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local WeaponSim = require(Shared.Weapons.WeaponSim)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local ShopServer = require(script.Parent.ShopServer)
local SpikeServer = require(script.Parent.SpikeServer)
local GroundGunsServer = require(script.Parent.GroundGunsServer)
local AbilityServer = require(script.Parent.AbilityServer)
local Tuning = require(script.Parent.Tuning)

local Arena = {}

export type Mode = "skirmish" | "spike" | "gungame"

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
-- The arena's cover by its height: what a player can see over darkest, then
-- what hides them, and the centre block lightest.
local COVER: { [string]: Color3 } = {
	centre = Color3.fromRGB(175, 175, 182),
	high = Color3.fromRGB(150, 152, 160),
	low = Color3.fromRGB(125, 128, 136),
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
local cover: { BasePart } = {} -- the arena's, for the map built (system 22)
local builtMap: string? = nil
local mapBarriers: { BasePart } = {} -- the spike rounds' map's
local mode: Mode? = nil
local skirmish: ArenaRules.State? = nil
local match: MatchRules.State? = nil
local gun: GunGameRules.State? = nil
local teams: { Team } = {}
local published = -1
local queued: { [Player]: boolean } = {} -- spawns asked for and not started yet
local loadouts: { [Player]: string } = {} -- what MatchConfig.LOADOUT says of each player
local kitMatch: { [Player]: number } = {} -- the match each player last got the starting kit for
-- Gun game's: the weapon of the kill each player has just died to, until
-- their death is handled.
local killedWith: { [Player]: string } = {}
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

-- Builds a map's cover into the arena in place of the last map's, if it's
-- another: the maps differ only in their cover.
local function showMap(key: string)
	local root = model
	if not root or key == builtMap or not ArenaLayout.Maps[key] then
		return
	end
	builtMap = key
	for _, part in cover do
		part:Destroy()
	end
	table.clear(cover)
	local H = ArenaLayout.Heights
	for _, spec in ArenaLayout.coverParts(key) do
		local p = newPart(spec.name, spec.size, ArenaLayout.origin + spec.center, spec.yaw)
		local height = spec.size.y
		p.Color = if height < H.high.value then COVER.low elseif height < H.centre.value then COVER.high else COVER.centre
		p.Parent = root
		table.insert(cover, p)
	end
end

-- Builds the arena from ArenaLayout, with Skirmish A's cover until a match
-- is played on another, and the spike rounds' map from MatchMap, unless the
-- place already has them.
function Arena.buildIfMissing()
	if not Workspace:FindFirstChild(ArenaConfig.MODEL) then
		local root = newModel(ArenaConfig.MODEL)
		for _, spec in ArenaLayout.hallParts() do
			local p = newPart(spec.name, spec.size, ArenaLayout.origin + spec.center, spec.yaw)
			p.Color = COLOURS[spec.kind] or COLOURS.wall
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
		showMap(ArenaLayout.MAPS[1])
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

-- The player attributes what's played keeps up to date, cleared as it ends.
local RECORD = {
	MatchConfig.CREDITS,
	MatchConfig.START_CREDITS,
	MatchConfig.KILLS,
	MatchConfig.DEATHS,
	MatchConfig.ASSISTS,
	MatchConfig.SCORE,
	MatchConfig.ROUNDS,
	MatchConfig.ALIVE,
	MatchConfig.LOADOUT,
	ArenaConfig.LINE,
	ArenaConfig.VOTE,
	GunGameConfig.LEVEL,
	GunGameConfig.PROTECTED,
}

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
-- the course, and in gun game every life on the gun of its level. Roblox
-- takes a moment to load the character, and what they buy meanwhile is held
-- for the new life (ShopServer).
local function spawn(ids: { number })
	local s, m, g = skirmish, match, gun
	local matchNumber = if s then s.match elseif m then m.match else nil
	for _, id in ids do
		local player = playerFor(id)
		if not player then
			continue
		end
		local kit = if g then GunGameRules.kitOf(g, id) else nil
		if kit then
			PlayerSimServer.resetKit(player, kit)
		elseif matchNumber and kitMatch[player] ~= matchNumber then
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

-- Puts each player on their side's team, or on none while they wait in line
-- or nothing is played, as the rules have them now: the sides are evened
-- out between rounds, and a place in line opens when someone leaves. And
-- during a vote for the next map, the one each has voted for.
local function seat(sides: Roster.Sides?, vote: MapVote.Vote?)
	for _, player in Players:GetPlayers() do
		local id = player.UserId
		local side = if sides then Roster.sideOf(sides, id) else nil
		local team = if side then teams[side] else nil
		if player.Team ~= team then
			player.Team = team
		end
		player.Neutral = team == nil
		player:SetAttribute(ArenaConfig.SIDE, side)
		player:SetAttribute(ArenaConfig.LINE, if sides then Roster.placeInLine(sides, id) else nil)
		player:SetAttribute(ArenaConfig.VOTE, if vote then vote.picks[id] else nil)
	end
end

-- Tells clients the phase and the score, moves the barriers, and tells the
-- spike who attacks and whether it can be planted, when they've changed.
local function publish()
	local s, m, g = skirmish, match, gun
	local version = if s then s.version elseif m then m.version elseif g then g.version else -1
	if version == published then
		return
	end
	published = version
	local state = s or m
	-- The arena's maps (system 22), Skirmish's and gun game's.
	local map = if s then s.map elseif g then g.map else nil
	local maps = if s then s.maps elseif g then g.maps else nil
	local vote = if s then s.vote elseif g then g.vote else nil
	local root = model
	if root then
		root:SetAttribute("Mode", mode)
		root:SetAttribute("Phase", if state then state.phase elseif g then g.phase else nil)
		root:SetAttribute("Round", if state then state.round else nil)
		-- In gun game, each side's highest level.
		root:SetAttribute("Score1", if state then state.score[1] elseif g then g.score[1] else nil)
		root:SetAttribute("Score2", if state then state.score[2] elseif g then g.score[2] else nil)
		root:SetAttribute("RoundWinner", if state then state.roundWinner else nil)
		root:SetAttribute("MatchWinner", if state then state.matchWinner elseif g then g.matchWinner else nil)
		root:SetAttribute("PhaseEndsAt", if state then state.phaseEndsAt elseif g then g.phaseEndsAt else nil)
		root:SetAttribute(
			"WinScore",
			if m then m.format.winScore.value elseif s then ArenaConfig.Rules.winScore.value elseif g then #g.ladder else nil
		)
		-- The spike rounds' own: the format (a key of MatchConfig.Formats), the
		-- side attacking, and how the round just played was won.
		root:SetAttribute("Format", if m then m.formatKey else nil)
		root:SetAttribute("Attackers", if m then m.attackers else nil)
		root:SetAttribute("Reason", if m then m.reason else nil)
		root:SetAttribute("Streak1", if m then m.streak[1] else nil)
		root:SetAttribute("Streak2", if m then m.streak[2] else nil)
		-- The arena's own (system 22): the map played (a key of
		-- ArenaLayout.Maps), whether a vote for the next follows each match,
		-- and during it the maps to pick from ("A,B,C") and the votes for
		-- each ("2,0,1").
		root:SetAttribute("Map", map)
		root:SetAttribute("MapVote", if maps then #maps > 1 else nil)
		root:SetAttribute("VoteMaps", if vote then table.concat(vote.options, ",") else nil)
		root:SetAttribute("Votes", if vote then table.concat(MapVote.tally(vote), ",") else nil)
		-- Gun game's own (system 23): the match's guns, a level each
		-- ("vandal,phantom,..."), and whoever's furthest up, or won.
		root:SetAttribute("Ladder", if g then table.concat(g.ladder, ",") else nil)
		root:SetAttribute("Leader", if g then g.winner or GunGameRules.leader(g) else nil)
	end
	if map then
		showMap(map)
	end
	-- Everyone's team and vote, and the record of everyone playing.
	local sides: Roster.Sides? = if state then state elseif g then g else nil
	seat(sides, vote)
	local members: { [number]: Roster.Member }? = if s then s.members elseif m then m.members elseif g then g.members else nil
	if members then
		for id, member in members do
			local player = playerFor(id)
			if not player then
				continue
			end
			player:SetAttribute(MatchConfig.ALIVE, member.alive)
			player:SetAttribute(MatchConfig.KILLS, member.kills)
			player:SetAttribute(MatchConfig.DEATHS, member.deaths)
			player:SetAttribute(MatchConfig.ASSISTS, member.assists)
			player:SetAttribute(MatchConfig.SCORE, member.score)
			player:SetAttribute(MatchConfig.ROUNDS, member.rounds)
			if m then
				player:SetAttribute(MatchConfig.CREDITS, member.credits)
				player:SetAttribute(MatchConfig.START_CREDITS, member.startCredits)
			elseif g then
				player:SetAttribute(GunGameConfig.LEVEL, GunGameRules.levelOf(g, id))
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
-- the spike rounds a new spike in front of the attackers, each kit's round
-- (system 17) and, at the start of each half, everyone back on the starting
-- kit.
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
	local half = MatchRules.startsHalf(m)
	for id in m.members do
		local player = playerFor(id)
		if not player then
			continue
		end
		if half then
			kitMatch[player] = m.match
			startingKit(player)
		end
		AbilityServer.roundStarted(player, if m.round == 1 then "match" elseif half then "half" else "round")
	end
end

-- Someone joins what's played, or leaves it: their team, and whoever spawns.
local function join(player: Player)
	local id = player.UserId
	local ids: { number }
	local s, m, g = skirmish, match, gun
	if s then
		ids = ArenaRules.join(s, id, now())
	elseif m then
		ids = MatchRules.join(m, id, now())
	elseif g then
		ids = GunGameRules.join(g, id, now())
	else
		return
	end
	publish()
	roundStarted()
	spawn(ids)
end

local function leave(player: Player)
	local id = player.UserId
	local ids: { number }
	local s, m, g = skirmish, match, gun
	if s then
		ids = ArenaRules.leave(s, id, now())
	elseif m then
		ids = MatchRules.leave(m, id, now())
	elseif g then
		ids = GunGameRules.leave(g, id, now())
	else
		return
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
	mode, skirmish, match, gun = nil, nil, nil, nil
	if was == "spike" then
		SpikeServer.stopRounds()
	elseif was == "gungame" then
		-- Off a level's gun, back on the default kit from the next life.
		for _, player in Players:GetPlayers() do
			PlayerSimServer.resetKit(player)
		end
	end
	PlayerSimServer.keepShields = false
	GroundGunsServer.dropOnDeath = false
	GroundGunsServer.drops = true
	GroundGunsServer.clear()
	AbilityServer.economy = false
	AbilityServer.refill = true
	AbilityServer.off = false
	table.clear(killedWith)
	for _, player in Players:GetPlayers() do
		AbilityServer.reset(player)
		player.Team = nil
		player.Neutral = true
		player:SetAttribute(ArenaConfig.SIDE, nil)
		for _, name in RECORD do
			player:SetAttribute(name, nil)
		end
	end
	table.clear(loadouts)
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
	elseif wanted == "gungame" then
		gun = GunGameRules.new()
	else
		match = MatchRules.new(format)
	end
	table.clear(kitMatch)
	seenMatch, seenRound = 0, 0
	GroundGunsServer.clear()
	for side, info in SIDES do
		local team = Instance.new("Team")
		team.Name = if wanted == "spike" then info.colour else info.name
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
	AbilityServer.economy = wanted == "spike"
	AbilityServer.refill = false
	AbilityServer.off = wanted == "gungame"
	GroundGunsServer.drops = wanted ~= "gungame"
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
		local named = Workspace:GetAttribute(ArenaConfig.MODE)
		wanted = if named == "spike" then "spike" elseif named == "gungame" then "gungame" else "skirmish"
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
		local m2, s2, g2 = match, skirmish, gun
		local what = if m2
			then "the spike rounds, " .. m2.format.name
			elseif s2 then ArenaLayout.Maps[s2.map].name
			elseif g2 then "gun game, " .. ArenaLayout.Maps[g2.map].name
			else "Skirmish"
		print(string.format("[VF] Arena on: %s", what))
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

-- Tells clients the guns each player holds, when they've changed.
local function publishLoadouts(members: { [number]: any })
	for id in members do
		local player = playerFor(id)
		if not player then
			continue
		end
		local primary = PlayerSimServer.holding(player, 1)
		local sidearm = PlayerSimServer.holding(player, 2)
		local text = (primary or "") .. "," .. (sidearm or "")
		if loadouts[player] ~= text then
			loadouts[player] = text
			player:SetAttribute(MatchConfig.LOADOUT, text)
		end
	end
end

-- Tells clients whose spawn protection is on in gun game, as it starts and
-- ends.
local function publishProtection(g: GunGameRules.State, time: number)
	for id in g.members do
		local player = playerFor(id)
		local on = if GunGameRules.safe(g, id, time) then true else nil
		if player and player:GetAttribute(GunGameConfig.PROTECTED) ~= on then
			player:SetAttribute(GunGameConfig.PROTECTED, on)
		end
	end
end

-- Puts the gun of a player's level in their hands now, in place of the last
-- level's, if they're alive (gun game): the new gun first, so the hand goes
-- to it as the old one's slot empties.
local function arm(player: Player)
	local g = gun
	local kit = if g then GunGameRules.kitOf(g, player.UserId) else nil
	if not kit or not PlayerSimServer.isAlive(player) then
		return
	end
	for slot = 1, 2 do
		if kit[slot] ~= "" and PlayerSimServer.holding(player, slot) ~= kit[slot] then
			PlayerSimServer.give(player, slot, kit[slot])
		end
	end
	for slot = 1, 2 do
		if kit[slot] == "" and PlayerSimServer.holding(player, slot) ~= "" then
			PlayerSimServer.give(player, slot, "")
		end
	end
end

-- The rounds' clock, once a server frame.
function Arena.step(time: number)
	local ids: { number }
	local s, m, g = skirmish, match, gun
	if s then
		ids = ArenaRules.step(s, time)
		publishLoadouts(s.members)
	elseif m then
		ids = MatchRules.step(m, time)
		publishLoadouts(m.members)
	elseif g then
		ids = GunGameRules.step(g, time)
		publishLoadouts(g.members)
		publishProtection(g, time)
	else
		return
	end
	publish()
	roundStarted()
	spawn(ids)
end

function Arena.start()
	-- On from the start on a live server; in Studio as the place has it, off
	-- unless it says otherwise. It starts once everything below is set up.
	local on = Workspace:GetAttribute(ArenaConfig.ON) == true or not RunService:IsStudio()
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
		local s, m, g = skirmish, match, gun
		if s then
			ArenaRules.skip(s, now())
		elseif m then
			MatchRules.skip(m, now())
		elseif g then
			GunGameRules.skip(g, now())
		end
		publish()
	end)
	-- A vote for the next map, by its number in the list.
	Remotes.get().Vote.OnServerEvent:Connect(function(player, option)
		local s, g = skirmish, gun
		if typeof(option) ~= "number" then
			return
		end
		local counted = if s
			then ArenaRules.vote(s, player.UserId, option)
			elseif g then GunGameRules.vote(g, player.UserId, option)
			else false
		if counted then
			publish()
		end
	end)
	-- P asks for the next of: "skirmish", "gungame", a format of the spike
	-- rounds, or "off" (true and false are the arena on and off).
	Remotes.get().Arena.OnServerEvent:Connect(function(player, asked)
		if not Tuning.canTune(player) then
			return
		end
		if asked == false or asked == "off" then
			Workspace:SetAttribute(ArenaConfig.ON, false)
		elseif asked == true or asked == "skirmish" then
			Workspace:SetAttribute(ArenaConfig.MODE, "skirmish")
			Workspace:SetAttribute(ArenaConfig.ON, true)
		elseif asked == "gungame" then
			Workspace:SetAttribute(ArenaConfig.MODE, "gungame")
			Workspace:SetAttribute(ArenaConfig.ON, true)
		elseif typeof(asked) == "string" and MatchConfig.Formats[asked] then
			Workspace:SetAttribute(MatchConfig.FORMAT, asked)
			Workspace:SetAttribute(ArenaConfig.MODE, "spike")
			Workspace:SetAttribute(ArenaConfig.ON, true)
		end
	end)

	PlayerSimServer.spawnPicker = function(player: Player): PlayerSimServer.SpawnPoint?
		local id = player.UserId
		local s, m, g = skirmish, match, gun
		-- The arena's rooms, in Skirmish and gun game.
		local sides: Roster.Sides? = if s then s elseif g then g else nil
		if sides then
			local side, spot = Roster.sideOf(sides, id), Roster.spotOf(sides, id)
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
		local s, m, g = skirmish, match, gun
		if s then
			return ArenaRules.canPick(s, player.UserId)
		elseif m then
			return MatchRules.canPick(m, player.UserId)
		elseif g then
			-- Gun game's guns come with its levels.
			return false
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
	-- Every hit between players goes in the record.
	table.insert(CombatServer.damageListeners, function(attacker, victim, amount: number)
		local s, m, g = skirmish, match, gun
		local by = if attacker then attacker.player else nil
		local hurt = victim.player
		if not by or not hurt then
			return
		end
		if s then
			ArenaRules.damaged(s, by.UserId, hurt.UserId, amount)
		elseif m then
			MatchRules.damaged(m, by.UserId, hurt.UserId, amount)
		elseif g then
			GunGameRules.damaged(g, by.UserId, hurt.UserId, amount)
		end
	end)
	-- What each kill was made with, for gun game's knife kills; the kill
	-- comes before the death.
	table.insert(CombatServer.killListeners, function(_, victim, weapon: string)
		local player = victim.player
		if player and gun then
			killedWith[player] = weapon
		end
	end)
	table.insert(PlayerSimServer.deathListeners, function(player: Player, killer: Player?)
		local s, m, g = skirmish, match, gun
		local weapon = killedWith[player]
		killedWith[player] = nil
		if s then
			ArenaRules.died(s, player.UserId, now(), if killer then killer.UserId else nil)
			publish()
		elseif m then
			MatchRules.died(m, player.UserId, now(), if killer then killer.UserId else nil)
			-- What they bought is lost with them.
			startingKit(player)
			publish()
		elseif g then
			GunGameRules.died(g, player.UserId, now(), if killer then killer.UserId else nil, weapon)
			-- The killer's next gun, in their hands at once.
			if killer then
				arm(killer)
			end
			publish()
		end
	end)
	-- G does nothing in gun game, as its client doesn't send it (ArenaHud);
	-- should a drop come anyway, the gun goes straight back where it was, as
	-- it was (GroundGunsServer leaves it off the ground).
	table.insert(PlayerSimServer.dropListeners, function(player: Player, dropped: WeaponSim.Dropped)
		if gun then
			PlayerSimServer.give(player, dropped.slot, dropped.id, dropped.ammo, dropped.reserve)
		end
	end)
	-- Each new life in gun game can't be hurt for a moment, until it fires,
	-- swings or scopes.
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		local g = gun
		if g then
			GunGameRules.spawned(g, player.UserId, now())
			publishProtection(g, now())
		end
	end)
	local ATTACK = bit32.bor(PlayerSim.Buttons.Fire, PlayerSim.Buttons.AltFire)
	table.insert(PlayerSimServer.tickListeners, function(player: Player, input: PlayerCodec.WireInput)
		local g = gun
		if g and bit32.btest(input.buttons, ATTACK) and GunGameRules.fired(g, player.UserId) then
			publishProtection(g, now())
		end
	end)
	CombatServer.protected = function(entity): boolean
		local g = gun
		local player = entity.player
		return g ~= nil and player ~= nil and GunGameRules.safe(g, player.UserId, now())
	end

	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player)
		queued[player] = nil
		kitMatch[player] = nil
		loadouts[player] = nil
		killedWith[player] = nil
		leave(player)
	end)

	Workspace:SetAttribute(ArenaConfig.ON, on)
end

return Arena
