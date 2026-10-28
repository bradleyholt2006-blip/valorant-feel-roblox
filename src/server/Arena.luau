--!strict
-- The arena (system 7) and the spike rounds (system 13), whichever is on.
--
-- The arena: a whitebox of the reference's Skirmish A, built beside the
-- course, played by Skirmish's rules (ArenaRules). The spike rounds: on
-- two-site maps of our own (SpikeMaps), built off the other side of the
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
-- what was bought, and each round gives the signature its free charge and
-- sets the ultimate's points (system 50). In Skirmish every life has every
-- charge.
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
-- The spike rounds' maps (system 25): Outpost, Quarry and Foundry, each
-- built at its own origin from the start. A match is played on one of them,
-- the first at random, and after each match's victory screen everyone votes
-- for the next, as in Skirmish; a new map is where everyone spawns, which
-- barriers go up, and the spike's sites and start (SpikeServer.setMap).
-- Each round starts with the map's Ultimate Orbs all up (system 49,
-- OrbServer).
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
-- Deathmatch (system 26, DeathmatchRules) is played on the spike rounds'
-- maps, with the same vote between matches, everyone for themselves: on no
-- team, so anyone can hurt anyone, and each a side of their own in the
-- record. Each life starts wherever DeathmatchSpawns picks, which asks
-- Roblox what each living player can see (a raycast from eye to eye against
-- the map's parts), on the guns of the last life (the default kit as a
-- match starts) and always in Heavy Armor. Every gun is free while alive,
-- and nothing else is sold (ShopServer.sells); there are no abilities and
-- no glide (AbilityServer's kits are no agent's), and nothing goes on the
-- ground. Every kill reloads the gun in the killer's hands, and every death
-- leaves a health pack (a green cross in Workspace.VFHealthPacks) that heals
-- whoever walks over it first and reloads their gun. Each player's place
-- goes to clients as a player attribute (DeathmatchConfig.PLACE), and the
-- leader as the arena model's Leader.
--
-- Team Deathmatch (system 27, TeamDeathmatchRules) is played on the spike
-- rounds' maps too, with the same vote between matches: two sides of five,
-- each spawning in a room of its own (the map's attackers' spawn for one,
-- its defenders' for the other), held there behind the map's barriers for
-- each match's pre-game. Each life starts on the loadout its player picked
-- for the stage under way (the LoadoutPick remote), in that loadout's
-- shield; a new stage's is handed over a moment into it, or at once in the
-- spawn room, as is a pick changed there. Nothing's bought, and nothing a
-- player lets go of goes on the ground. A new life can't be hurt for a
-- moment (CombatServer.protected), until it fires or leaves its room, and
-- anyone staying in their own room after that, or in the other side's at
-- all, burns (CombatServer.hurt). Its pickups (system 28, PickupsServer)
-- are weapon spawners, Recovery Orbs and Ultimate Orbs: a spawner's gun is
-- lent in place of the loadout's, which comes back as soon as the lent one
-- is spent or let go of with G, which destroys it. Abilities recharge over
-- time, the kit starting over as each match starts and with each player's
-- first life in one (AbilityServer.rules and fresh). Each player's picks,
-- the stage their guns are for, when their stay in their room began and the
-- guns lent them go to clients as player attributes (TeamDeathmatchConfig),
-- and the stage under way and when it started as the arena model's Stage
-- and StageAt.
--
-- The Play menu (system 24, ModeServers): with Arena.menuFirst, as on a live
-- server, nobody joins what's played until they press PLAY for it
-- (Arena.play, and PlayConfig.PLAYING on the player); until then they're in
-- the menu, with no side and no life.
--
-- Agent select (system 29, AgentServer) asks here where each player is for
-- picking: free on the course and while a mode waits for players, once a
-- match by its key in Skirmish, the spike rounds and Team Deathmatch, each
-- side with its own (system 48), and nowhere else; and whether an agent
-- locked in goes on their kit at once: while they're down, in a buy phase,
-- Team Deathmatch's pre-game and their own spawn room there, and wherever
-- picking is free (AgentSelect).
--
-- The combat report (system 53, ReportServer) goes by the round in
-- Skirmish and the spike rounds once one's under way (ReportServer.byRound):
-- everyone's starts over as a round starts, and goes to them as it ends.
-- Anywhere else, and while a match waits for an opponent, it goes by the
-- life. So does the kill banner's count of each player's kills (system 55,
-- BannerServer).
--
-- P (Studio or the place owner) moves on through the arena, gun game, the
-- spike rounds in the standard format, the spike rounds in Swiftplay's, and
-- off. So do Workspace's attributes, set from the server, which is how
-- scripted checks do it, and which tell clients what's on: VFArenaOn,
-- VFArenaMode ("skirmish", "gungame", "deathmatch", "teamdeathmatch" or
-- "spike") and VFMatchFormat (a key of MatchConfig.Formats). The phase and
-- the score go to clients as attributes on the arena's model, whichever is
-- played.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AgentSelect = require(Shared.Abilities.AgentSelect)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local ArenaLayout = require(Shared.Arena.ArenaLayout)
local ArenaRules = require(Shared.Arena.ArenaRules)
local DeathmatchConfig = require(Shared.Arena.DeathmatchConfig)
local DeathmatchRules = require(Shared.Arena.DeathmatchRules)
local DeathmatchSpawns = require(Shared.Arena.DeathmatchSpawns)
local GunGameConfig = require(Shared.Arena.GunGameConfig)
local GunGameRules = require(Shared.Arena.GunGameRules)
local TeamDeathmatchConfig = require(Shared.Arena.TeamDeathmatchConfig)
local TeamDeathmatchRules = require(Shared.Arena.TeamDeathmatchRules)
local MapVote = require(Shared.Match.MapVote)
local MatchConfig = require(Shared.Match.MatchConfig)
local MatchRules = require(Shared.Match.MatchRules)
local PlayConfig = require(Shared.Match.PlayConfig)
local Roster = require(Shared.Match.Roster)
local SpikeMaps = require(Shared.Match.SpikeMaps)
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
local FireServer = require(script.Parent.FireServer)
local BlazeServer = require(script.Parent.BlazeServer)
local HealServer = require(script.Parent.HealServer)
local SlowServer = require(script.Parent.SlowServer)
local BarrierServer = require(script.Parent.BarrierServer)
local ReconServer = require(script.Parent.ReconServer)
local ShockServer = require(script.Parent.ShockServer)
local DroneServer = require(script.Parent.DroneServer)
local ReviveServer = require(script.Parent.ReviveServer)
local CloudServer = require(script.Parent.CloudServer)
local AbilityServer = require(script.Parent.AbilityServer)
local AgentServer = require(script.Parent.AgentServer)
local PickupsServer = require(script.Parent.PickupsServer)
local OrbServer = require(script.Parent.OrbServer)
local ReportServer = require(script.Parent.ReportServer)
local BannerServer = require(script.Parent.BannerServer)
local Tuning = require(script.Parent.Tuning)

local Arena = {}

-- Whether players join what's played only once they press PLAY for it
-- (system 24), rather than as they join the server. ModeServers sets it.
Arena.menuFirst = false

export type Mode = "skirmish" | "spike" | "gungame" | "deathmatch" | "teamdeathmatch"

-- Each side's team and colours: the arena room's floor, its barrier and the
-- team. In the spike rounds the teams go by their colours, as their spawns
-- swap at the half, and so they do in Team Deathmatch, on the same maps.
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
-- The spike rounds' maps: cover a player can see over darker than cover
-- they can't, the sites' plant areas marked on the floor, and each spawn's
-- floor and barriers in its role's colour.
local MAP_COLOURS: { [string]: Color3 } = {
	low = Color3.fromRGB(135, 138, 146),
	high = Color3.fromRGB(170, 172, 180),
	site = Color3.fromRGB(150, 128, 72),
}
local ROLE_COLOURS: { [string]: { floor: Color3, barrier: Color3 } } = {
	attack = { floor = Color3.fromRGB(140, 88, 80), barrier = Color3.fromRGB(255, 120, 90) },
	defend = { floor = Color3.fromRGB(72, 112, 135), barrier = Color3.fromRGB(90, 200, 255) },
}
-- Deathmatch's health packs.
local PACK_GREEN = Color3.fromRGB(90, 230, 120)
local PACKS = "VFHealthPacks"

local model: Model? = nil -- the arena's, which carries the state of play
local begun = 0 -- how many times a mode has started, so each match's key is its own (system 29)
local barriers: { BasePart } = {} -- the arena's
local cover: { BasePart } = {} -- the arena's, for the map built (system 22)
local builtMap: string? = nil
local mapBarriers: { [string]: { BasePart } } = {} -- each spike map's, by its key
local spikeMap: string? = nil -- the spike map SpikeServer has the sites of
local mode: Mode? = nil
local skirmish: ArenaRules.State? = nil
local match: MatchRules.State? = nil
local gun: GunGameRules.State? = nil
local dm: DeathmatchRules.State? = nil
local tdm: TeamDeathmatchRules.State? = nil
local teams: { Team } = {}
local published = -1
local queued: { [Player]: boolean } = {} -- spawns asked for and not started yet
local loadouts: { [Player]: string } = {} -- what MatchConfig.LOADOUT says of each player
local kitMatch: { [Player]: number } = {} -- the match each player last got the starting kit for
-- Gun game's: the weapon of the kill each player has just died to, until
-- their death is handled.
local killedWith: { [Player]: string } = {}
-- Who's pressed PLAY for what's played here, with Arena.menuFirst (system
-- 24).
local chosen: { [Player]: boolean } = {}
-- Deathmatch's: where each player last fell, in the map's own metres, until
-- their next life starts; each map's places a life can start, and what sees
-- what on it, once they're first asked for; and the health packs' models,
-- by their ids.
local diedAt: { [Player]: vector } = {}
local spotsOf: { [string]: { DeathmatchSpawns.Spot } } = {}
local seeingOn: { [string]: DeathmatchSpawns.Sees } = {}
local packModels: { [number]: Model } = {}
-- The round the ground was last cleared for, and in the spike rounds the
-- spike and the kits were last set for; and the last that ended, whose
-- combat reports went out.
local seenMatch, seenRound = 0, 0
local endedMatch, endedRound = 0, 0

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
-- is played on another, and each of the spike rounds' maps (SpikeMaps) in a
-- model of its own, unless the place already has them.
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

	local maps = Workspace:FindFirstChild(MatchConfig.MODEL)
	if not maps then
		local folder = Instance.new("Folder")
		folder.Name = MatchConfig.MODEL
		folder.Parent = Workspace
		maps = folder
	end
	for _, key in SpikeMaps.MAPS do
		local plan = SpikeMaps.Maps[key]
		if maps:FindFirstChild(plan.NAME) then
			continue
		end
		local root = newModel(plan.NAME)
		local raised: { BasePart } = {}
		for _, spec in plan.parts() do
			local p = newPart(spec.name, spec.size, plan.origin + spec.center, spec.yaw)
			p.Color = COLOURS[spec.kind] or COLOURS.wall
			local role = spec.role
			if spec.kind == "cover" then
				p.Color = if spec.size.y < plan.Heights.high.value then MAP_COLOURS.low else MAP_COLOURS.high
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
				table.insert(raised, p)
			end
			p.Parent = root
		end
		root.Parent = maps
		mapBarriers[key] = raised
		raise(raised, false)
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
	DeathmatchConfig.PLACE,
	TeamDeathmatchConfig.PICKS,
	TeamDeathmatchConfig.KIT_STAGE,
	TeamDeathmatchConfig.ROOM_SINCE,
	TeamDeathmatchConfig.LENT,
}

local function playerFor(id: number): Player?
	return Players:GetPlayerByUserId(id)
end

-- From the player's next life, the starting kit of what's played: Skirmish's
-- (WeaponConfig's default), the spike rounds' (the Classic and the knife,
-- no shield) or deathmatch's (Skirmish's, in Heavy Armor).
local function startingKit(player: Player)
	if mode == "spike" then
		PlayerSimServer.resetKit(player, MatchConfig.StartingKit, "")
	elseif mode == "deathmatch" then
		PlayerSimServer.resetKit(player, nil, DeathmatchConfig.SHIELD)
	else
		PlayerSimServer.resetKit(player)
	end
end

-- Once whatever event this is has been handled, and once each however many
-- times they're asked for meanwhile. Each player's first life in a match
-- starts on the starting kit, whatever they bought in the last match or on
-- the course; in gun game every life on the gun of its level, and in Team
-- Deathmatch on the loadout picked for the stage under way, its abilities
-- starting over as the rules say. Roblox takes a moment to load the
-- character, and what they buy meanwhile is held for the new life
-- (ShopServer).
local function spawn(ids: { number })
	local s, m, g, d, t = skirmish, match, gun, dm, tdm
	local matchNumber = if s then s.match elseif m then m.match elseif d then d.match else nil
	for _, id in ids do
		local player = playerFor(id)
		if not player then
			continue
		end
		local kit: { string }?, shield: string? = nil, nil
		if g then
			kit = GunGameRules.kitOf(g, id)
		elseif t then
			kit, shield = TeamDeathmatchRules.kitOf(t, id)
			TeamDeathmatchRules.armed(t, id)
			if TeamDeathmatchRules.startsOver(t, id) then
				AbilityServer.fresh(player, now())
			end
		end
		if kit then
			PlayerSimServer.resetKit(player, kit, shield)
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

-- A health pack where it lies (deathmatch): a green cross a little above
-- the floor, lit, that nothing collides with, hits or queries, on every
-- client wherever they are (a character's root stays where its life
-- started, system 35, so a streaming place streams around that).
local function newPack(feet: vector): Model
	local root = newModel("HealthPack")
	local centre = feet + vector.create(0, 0.45, 0)
	for i, size in { vector.create(0.5, 0.14, 0.14), vector.create(0.14, 0.5, 0.14), vector.create(0.14, 0.14, 0.5) } do
		local p = newPart("Cross", size, centre, 0)
		marking(p)
		p.Material = Enum.Material.Neon
		p.Color = PACK_GREEN
		p.Parent = root
		if i == 1 then
			local light = Instance.new("PointLight")
			light.Color = PACK_GREEN
			light.Range = 8
			light.Brightness = 1.5
			light.Parent = p
		end
	end
	return root
end

-- The health packs' models as deathmatch has the packs: one for each on the
-- floor, and none once it's gone.
local function syncPacks()
	local d = dm
	local lying: { [number]: boolean } = {}
	if d then
		local origin = SpikeMaps.Maps[d.map].origin
		for _, pack in d.packs do
			lying[pack.id] = true
			if not packModels[pack.id] then
				local folder = Workspace:FindFirstChild(PACKS)
				if not folder then
					folder = Instance.new("Folder")
					folder.Name = PACKS
					folder.Parent = Workspace
				end
				local made = newPack(origin + pack.position)
				made.Parent = folder
				packModels[pack.id] = made
			end
		end
	end
	for id, made in packModels do
		if not lying[id] then
			made:Destroy()
			packModels[id] = nil
		end
	end
end

-- Tells clients the phase and the score, moves the barriers, and tells the
-- spike who attacks and whether it can be planted, when they've changed.
local function publish()
	local s, m, g, d, t = skirmish, match, gun, dm, tdm
	local version = if s
		then s.version
		elseif m then m.version
		elseif g then g.version
		elseif d then d.version
		elseif t then t.version
		else -1
	if version == published then
		return
	end
	published = version
	local state = s or m
	-- The maps (systems 22 and 25): the arena's in Skirmish and gun game, and
	-- the spike rounds' own in the spike rounds and both deathmatches.
	local map = if s then s.map elseif g then g.map elseif m then m.map elseif d then d.map elseif t then t.map else nil
	local maps = if s then s.maps elseif g then g.maps elseif m then m.maps elseif d then d.maps elseif t then t.maps else nil
	local vote = if s then s.vote elseif g then g.vote elseif m then m.vote elseif d then d.vote elseif t then t.vote else nil
	local root = model
	if root then
		root:SetAttribute("Mode", mode)
		root:SetAttribute("Phase", if state then state.phase elseif g then g.phase elseif d then d.phase elseif t then t.phase else nil)
		root:SetAttribute("Round", if state then state.round else nil)
		-- In gun game, each side's highest level, and in Team Deathmatch its
		-- kills; nothing in deathmatch.
		root:SetAttribute("Score1", if state then state.score[1] elseif g then g.score[1] elseif t then t.score[1] else nil)
		root:SetAttribute("Score2", if state then state.score[2] elseif g then g.score[2] elseif t then t.score[2] else nil)
		root:SetAttribute("RoundWinner", if state then state.roundWinner else nil)
		-- In deathmatch, the side of whoever won: theirs alone. A Team
		-- Deathmatch drawn has none.
		root:SetAttribute(
			"MatchWinner",
			if state
				then state.matchWinner
				elseif g then g.matchWinner
				elseif d and d.winner then DeathmatchRules.sideOf(d, d.winner)
				elseif t then t.matchWinner
				else nil
		)
		root:SetAttribute(
			"PhaseEndsAt",
			if state then state.phaseEndsAt elseif g then g.phaseEndsAt elseif d then d.phaseEndsAt elseif t then t.phaseEndsAt else nil
		)
		root:SetAttribute(
			"WinScore",
			if m
				then m.format.winScore.value
				elseif s then ArenaConfig.Rules.winScore.value
				elseif g then #g.ladder
				elseif d then DeathmatchConfig.Rules.killTarget.value
				elseif t then TeamDeathmatchConfig.Rules.killTarget.value
				else nil
		)
		-- The spike rounds' own: the format (a key of MatchConfig.Formats), the
		-- side attacking, and how the round just played was won.
		root:SetAttribute("Format", if m then m.formatKey else nil)
		root:SetAttribute("Attackers", if m then m.attackers else nil)
		root:SetAttribute("Reason", if m then m.reason else nil)
		root:SetAttribute("Streak1", if m then m.streak[1] else nil)
		root:SetAttribute("Streak2", if m then m.streak[2] else nil)
		-- The map played (systems 22 and 25: a key of ArenaLayout.Maps, or in
		-- the spike rounds of SpikeMaps.Maps), whether a vote for the next
		-- follows each match, and during it the maps to pick from ("A,B,C")
		-- and the votes for each ("2,0,1").
		root:SetAttribute("Map", map)
		root:SetAttribute("MapVote", if maps then #maps > 1 else nil)
		root:SetAttribute("VoteMaps", if vote then table.concat(vote.options, ",") else nil)
		root:SetAttribute("Votes", if vote then table.concat(MapVote.tally(vote), ",") else nil)
		-- Gun game's own (system 23): the match's guns, a level each
		-- ("vandal,phantom,..."), and whoever's furthest up, or won; in
		-- deathmatch whoever leads, or won.
		root:SetAttribute("Ladder", if g then table.concat(g.ladder, ",") else nil)
		root:SetAttribute(
			"Leader",
			if g then g.winner or GunGameRules.leader(g) elseif d then d.winner or DeathmatchRules.leader(d) else nil
		)
		-- Team Deathmatch's own (system 27): the stage under way, and when it
		-- started (server time).
		root:SetAttribute("Stage", if t then t.stage else nil)
		root:SetAttribute("StageAt", if t then t.stageAt else nil)
	end
	if map and (s or g) then
		showMap(map)
	end
	-- Everyone's team and vote, and the record of everyone playing.
	local sides: Roster.Sides? = if state then state elseif g then g elseif d then d elseif t then t else nil
	seat(sides, vote)
	local members: { [number]: Roster.Member }? = if s
		then s.members
		elseif m then m.members
		elseif g then g.members
		elseif d then d.members
		elseif t then t.members
		else nil
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
			elseif d then
				player:SetAttribute(DeathmatchConfig.PLACE, DeathmatchRules.placeOf(d, id))
			elseif t then
				player:SetAttribute(TeamDeathmatchConfig.KIT_STAGE, t.kitStage[id])
				local primary, sidearm = TeamDeathmatchRules.lentOf(t, id, 1), TeamDeathmatchRules.lentOf(t, id, 2)
				player:SetAttribute(
					TeamDeathmatchConfig.LENT,
					if primary or sidearm then (primary or "") .. "," .. (sidearm or "") else nil
				)
			end
		end
	end
	-- Team Deathmatch's picks, for everyone playing or in line ("1,2,1,1").
	if t then
		local ids = table.clone(t.queue)
		for id in t.members do
			table.insert(ids, id)
		end
		for _, id in ids do
			local player = playerFor(id)
			if player then
				player:SetAttribute(TeamDeathmatchConfig.PICKS, table.concat(TeamDeathmatchRules.picksOf(t, id), ","))
			end
		end
	end
	syncPacks()
	raise(barriers, s ~= nil and ArenaRules.barriersUp(s))
	-- The spike maps' barriers: the spike rounds' buy phase, and Team
	-- Deathmatch's pre-game.
	for key, raised in mapBarriers do
		local up = (m ~= nil and m.map == key and MatchRules.barriersUp(m)) or (t ~= nil and t.map == key and t.phase == "pregame")
		raise(raised, up)
	end
	if m then
		-- A match on another map: the spike's sites and start are its.
		if m.map ~= spikeMap then
			spikeMap = m.map
			local plan = SpikeMaps.Maps[m.map]
			SpikeServer.setMap(plan.LAYOUT, plan.origin + plan.spikeStart)
		end
		SpikeServer.setRound(m.attackers, MatchRules.canPlant(m))
	end
end

-- A round has started since this last looked: the ground cleared of guns,
-- fire (systems 31 and 32), ice (system 37), walls of ice (system 38),
-- recon bolts (system 44) and shock bolts in the air (system 45), every
-- heal over (system 36), every Owl Drone's flight and its darts' pings
-- (system 47), everyone's combat report (system 53) and count of kills
-- for the kill banner (system 55), and in the spike rounds a new spike in
-- front of the attackers, the map's Ultimate Orbs all up (system 49), each
-- kit's round (system 17) with its ultimate's points (system 50) and, at
-- the start of each half, everyone back on the starting kit.
local function roundStarted()
	local s, m = skirmish, match
	local phase = if s then s.phase elseif m then m.phase else nil
	local matchNumber = if s then s.match elseif m then m.match else 0
	local round = if s then s.round elseif m then m.round else 0
	if phase ~= "buy" or (matchNumber == seenMatch and round == seenRound) then
		return
	end
	seenMatch, seenRound = matchNumber, round
	ReportServer.roundStarted(round)
	BannerServer.roundStarted()
	GroundGunsServer.clear()
	FireServer.clear()
	BlazeServer.clear()
	HealServer.clear()
	SlowServer.clear()
	BarrierServer.clear()
	ReconServer.clear()
	ShockServer.clear()
	DroneServer.clear()
	ReviveServer.clear()
	CloudServer.clear()
	if not m then
		return
	end
	SpikeServer.reset()
	OrbServer.roundStarted(m.map)
	local half = MatchRules.startsHalf(m)
	local kind: MatchRules.RoundKind = MatchRules.roundKind(m.format, m.round)
	local swiftplay = m.formatKey == "swiftplay"
	for id in m.members do
		local player = playerFor(id)
		if not player then
			continue
		end
		if half then
			kitMatch[player] = m.match
			startingKit(player)
		end
		AbilityServer.roundStarted(player, kind, swiftplay)
	end
end

-- A round has ended since this last looked, and with it not the match:
-- everyone's combat report for it goes to them, for the next buy phase
-- (system 53). The match's last has its victory screen instead.
local function roundEnded()
	local s, m = skirmish, match
	local phase = if s then s.phase elseif m then m.phase else nil
	local matchNumber = if s then s.match elseif m then m.match else 0
	local round = if s then s.round elseif m then m.round else 0
	if phase ~= "roundOver" or (matchNumber == endedMatch and round == endedRound) then
		return
	end
	endedMatch, endedRound = matchNumber, round
	ReportServer.roundOver(round)
end

-- Someone joins what's played, or leaves it: their team, and whoever spawns.
local function join(player: Player)
	local id = player.UserId
	local ids: { number }
	local s, m, g, d, t = skirmish, match, gun, dm, tdm
	if s then
		ids = ArenaRules.join(s, id, now())
	elseif m then
		ids = MatchRules.join(m, id, now())
	elseif g then
		ids = GunGameRules.join(g, id, now())
	elseif d then
		ids = DeathmatchRules.join(d, id, now())
	elseif t then
		ids = TeamDeathmatchRules.join(t, id, now())
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
	local s, m, g, d, t = skirmish, match, gun, dm, tdm
	if s then
		ids = ArenaRules.leave(s, id, now())
	elseif m then
		ids = MatchRules.leave(m, id, now())
	elseif g then
		ids = GunGameRules.leave(g, id, now())
	elseif d then
		ids = DeathmatchRules.leave(d, id, now())
	elseif t then
		ids = TeamDeathmatchRules.leave(t, id, now())
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
	mode, skirmish, match, gun, dm, tdm = nil, nil, nil, nil, nil, nil
	if was == "spike" then
		spikeMap = nil
		SpikeServer.stopRounds()
	elseif was == "gungame" or was == "teamdeathmatch" then
		-- Off a level's gun or a stage's, back on the default kit from the next
		-- life.
		for _, player in Players:GetPlayers() do
			PlayerSimServer.resetKit(player)
		end
	end
	PlayerSimServer.keepShields = false
	PickupsServer.stop()
	OrbServer.stop()
	ReportServer.reset()
	BannerServer.reset()
	GroundGunsServer.dropOnDeath = false
	GroundGunsServer.drops = true
	GroundGunsServer.clear()
	FireServer.clear()
	BlazeServer.clear()
	HealServer.clear()
	SlowServer.clear()
	BarrierServer.clear()
	ReconServer.clear()
	ShockServer.clear()
	DroneServer.clear()
	ReviveServer.clear()
	CloudServer.clear()
	AbilityServer.economy = false
	AbilityServer.refill = true
	AbilityServer.off = false
	AbilityServer.agent = nil
	AbilityServer.rules = nil
	table.clear(killedWith)
	table.clear(diedAt)
	syncPacks()
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
	begun += 1
	if wanted == "skirmish" then
		skirmish = ArenaRules.new()
	elseif wanted == "gungame" then
		gun = GunGameRules.new()
	elseif wanted == "deathmatch" then
		dm = DeathmatchRules.new()
	elseif wanted == "teamdeathmatch" then
		tdm = TeamDeathmatchRules.new()
	else
		match = MatchRules.new(format)
	end
	table.clear(kitMatch)
	seenMatch, seenRound = 0, 0
	endedMatch, endedRound = 0, 0
	ReportServer.reset()
	BannerServer.reset()
	GroundGunsServer.clear()
	FireServer.clear()
	BlazeServer.clear()
	HealServer.clear()
	SlowServer.clear()
	BarrierServer.clear()
	ReconServer.clear()
	ShockServer.clear()
	DroneServer.clear()
	ReviveServer.clear()
	CloudServer.clear()
	-- Deathmatch has no teams: everyone can hurt everyone.
	if wanted ~= "deathmatch" then
		for side, info in SIDES do
			local team = Instance.new("Team")
			team.Name = if wanted == "spike" or wanted == "teamdeathmatch" then info.colour else info.name
			team.TeamColor = info.team
			team.AutoAssignable = false
			team.Parent = Teams
			teams[side] = team
		end
	end
	if wanted == "spike" then
		local first = (match :: MatchRules.State).map
		local plan = SpikeMaps.Maps[first]
		spikeMap = first
		SpikeServer.startRounds(spikeEvents, plan.LAYOUT, plan.origin + plan.spikeStart)
		PlayerSimServer.keepShields = true
		GroundGunsServer.dropOnDeath = true
	end
	AbilityServer.economy = wanted == "spike"
	AbilityServer.refill = false
	AbilityServer.off = wanted == "gungame" or wanted == "deathmatch"
	AbilityServer.agent = if wanted == "deathmatch" then AbilityConfig.NO_AGENT else nil
	AbilityServer.rules = if wanted == "teamdeathmatch" then AbilityConfig.TeamDeathmatch else nil
	GroundGunsServer.drops = wanted ~= "gungame" and wanted ~= "deathmatch" and wanted ~= "teamdeathmatch"
	-- The rounds decide when everyone spawns.
	Players.CharacterAutoLoads = false
	published = -2
	for _, player in Players:GetPlayers() do
		if not Arena.menuFirst or chosen[player] then
			join(player)
		end
	end
	publish()
end

-- Plays what Workspace's attributes ask for, if it isn't already.
local function apply()
	local wanted: Mode? = nil
	if Workspace:GetAttribute(ArenaConfig.ON) == true then
		local named = Workspace:GetAttribute(ArenaConfig.MODE)
		local known = named == "spike" or named == "gungame" or named == "deathmatch" or named == "teamdeathmatch"
		wanted = if known then named else "skirmish"
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
		local m2, s2, g2, d2, t2 = match, skirmish, gun, dm, tdm
		local what = if m2
			then string.format("the spike rounds, %s, on %s", m2.format.name, SpikeMaps.Maps[m2.map].NAME)
			elseif s2 then ArenaLayout.Maps[s2.map].name
			elseif g2 then "gun game, " .. ArenaLayout.Maps[g2.map].name
			elseif d2 then "deathmatch, on " .. SpikeMaps.Maps[d2.map].NAME
			elseif t2 then "Team Deathmatch, on " .. SpikeMaps.Maps[t2.map].NAME
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

-- Tells clients whose spawn protection is on in gun game and Team
-- Deathmatch, as it starts and ends, and in Team Deathmatch when each life's
-- stay in its spawn room began, for the HUD's warning of the burn.
local function publishProtection(time: number)
	local g, t = gun, tdm
	local members: { [number]: Roster.Member }? = if g then g.members elseif t then t.members else nil
	if not members then
		return
	end
	for id in members do
		local player = playerFor(id)
		local safe = if g then GunGameRules.safe(g, id, time) elseif t then TeamDeathmatchRules.safe(t, id, time) else false
		local on = if safe then true else nil
		if player and player:GetAttribute(GunGameConfig.PROTECTED) ~= on then
			player:SetAttribute(GunGameConfig.PROTECTED, on)
		end
		local since = if t then t.spawnedAt[id] else nil
		if player and t and player:GetAttribute(TeamDeathmatchConfig.ROOM_SINCE) ~= since then
			player:SetAttribute(TeamDeathmatchConfig.ROOM_SINCE, since)
		end
	end
end

-- Puts a kit's guns in a living player's hands now, in place of what they
-- hold (gun game's next level, Team Deathmatch's stage): the new guns first,
-- so the hand goes to one as the old one's slot empties. A gun they hold
-- already stays as it is, but in a slot of `renew`, which has it afresh.
local function arm(player: Player, kit: { string }?, renew: { [number]: boolean }?)
	if not kit or not PlayerSimServer.isAlive(player) then
		return
	end
	for slot = 1, 2 do
		local afresh = renew ~= nil and renew[slot] == true
		if kit[slot] ~= "" and (afresh or PlayerSimServer.holding(player, slot) ~= kit[slot]) then
			PlayerSimServer.give(player, slot, kit[slot])
		end
	end
	for slot = 1, 2 do
		if kit[slot] == "" and PlayerSimServer.holding(player, slot) ~= "" then
			PlayerSimServer.give(player, slot, "")
		end
	end
end

-- Team Deathmatch's spawn rooms, once a server frame, for everyone alive
-- and not about to spawn again: out of their own, their protection's over; a
-- gun a spawner lent that's spent, or no longer in its slot, is gone; a new
-- kit is handed over when the rules say (a new stage's, a pick changed in
-- the room, or the loadout's gun in place of a lent one gone), its guns, a
-- fresh one for a lent one, and, if it's another kind, its shield; and
-- staying in their room after its time, or in the other side's at all,
-- burns.
local function spawnRooms(t: TeamDeathmatchRules.State, time: number)
	local origin = SpikeMaps.Maps[t.map].origin
	for id, member in t.members do
		local player = if member.alive then playerFor(id) else nil
		local sim = if player and PlayerSimServer.isAlive(player) then PlayerSimServer.getSim(player) else nil
		local entity = if player then PlayerSimServer.entityOf(player) else nil
		if not player or not sim or not entity or PlayerSimServer.spawnPending(player) then
			continue
		end
		local room: TeamDeathmatchRules.Room? = TeamDeathmatchRules.roomOf(t, id, sim.movement.position - origin)
		if room ~= "own" then
			TeamDeathmatchRules.unprotect(t, id)
		end
		-- A lent gun in hand that the kit no longer lends (spent, or the last
		-- stage's) gives way to the loadout's afresh, even the same gun: a
		-- Vandal lent in the third stage isn't the fourth's Vandal.
		local w = sim.weapons
		local renew: { [number]: boolean } = {}
		for slot = 1, 2 do
			local lent = TeamDeathmatchRules.lentOf(t, id, slot)
			local inHand = lent ~= nil and w.loadout[slot] == lent
			if lent and (not inHand or (w.ammo[slot] <= 0 and w.reserve[slot] <= 0)) then
				TeamDeathmatchRules.returned(t, id, slot)
			end
			renew[slot] = inHand and not TeamDeathmatchRules.lends(t, id, slot)
		end
		if TeamDeathmatchRules.rearms(t, id, time, room == "own") then
			local kit, shield = TeamDeathmatchRules.kitOf(t, id)
			arm(player, kit, renew)
			if entity.health.kind ~= shield then
				CombatServer.setShield(entity, shield)
			end
			TeamDeathmatchRules.armed(t, id)
		end
		if TeamDeathmatchRules.burns(t, id, time, room) then
			CombatServer.hurt(entity, TeamDeathmatchConfig.Rules.burnDamage.value, TeamDeathmatchConfig.BURN)
		end
	end
end

-- Reloads the gun in a player's hands at once, as deathmatch does with
-- each kill and each health pack: the Ares and the Odin 30 rounds at the
-- most.
local function reload(player: Player)
	local _, slot = PlayerSimServer.holding(player, 1)
	local id = if slot then PlayerSimServer.holding(player, slot) else nil
	PlayerSimServer.reloadInHand(player, DeathmatchRules.reloadFor(id))
end

-- Whoever alive stands over a health pack takes it (deathmatch): full health
-- and a fresh Heavy Armor, and their gun reloaded.
local function pickUps(d: DeathmatchRules.State, time: number)
	if #d.packs == 0 then
		return
	end
	local origin = SpikeMaps.Maps[d.map].origin
	for id, member in d.members do
		local player = if member.alive then playerFor(id) else nil
		local sim = if player and PlayerSimServer.isAlive(player) then PlayerSimServer.getSim(player) else nil
		if player and sim and DeathmatchRules.pickUp(d, id, sim.movement.position - origin, time) then
			local entity = PlayerSimServer.entityOf(player)
			if entity then
				CombatServer.heal(entity)
			end
			reload(player)
		end
	end
end

-- A spike map's places a life can start in deathmatch, worked out the first
-- time they're asked for.
local function spotsFor(key: string): { DeathmatchSpawns.Spot }
	local spots = spotsOf[key]
	if not spots then
		spots = DeathmatchSpawns.spots(SpikeMaps.Maps[key])
		spotsOf[key] = spots
	end
	return spots
end

-- What sees what on a spike map, for deathmatch's spawns: whether the eye of
-- someone standing at one place (in the map's own metres) has a clear line
-- to the eye of someone standing at another, past the map's walls and
-- cover. Only the map's parts are in the way: nobody's body, and none of
-- what queries go through (its markings, its lowered barriers).
local function seesFor(key: string): DeathmatchSpawns.Sees
	local sees = seeingOn[key]
	if sees then
		return sees
	end
	local plan = SpikeMaps.Maps[key]
	local folder = Workspace:FindFirstChild(MatchConfig.MODEL)
	local built = if folder then folder:FindFirstChild(plan.NAME) else nil
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = if built then { built } else {}
	local function clear(a: vector, b: vector): boolean
		local eye = vector.create(0, Tuning.config().standEyeHeight, 0)
		local from = Units.toStuds(plan.origin + a + eye)
		local to = Units.toStuds(plan.origin + b + eye)
		return Workspace:Raycast(from, to - from, params) == nil
	end
	seeingOn[key] = clear
	return clear
end

-- Someone has pressed PLAY for what's played here (system 24): they join
-- it, now if it's on, or as it starts.
function Arena.play(player: Player)
	chosen[player] = true
	player:SetAttribute(PlayConfig.PLAYING, true)
	join(player)
end

-- Whether someone is in what's played: on a side, or waiting in line.
function Arena.has(player: Player): boolean
	local s, m, g, d, t = skirmish, match, gun, dm, tdm
	local sides: Roster.Sides? = if s then s elseif m then m elseif g then g elseif d then d elseif t then t else nil
	return sides ~= nil and (sides.members[player.UserId] ~= nil or Roster.placeInLine(sides, player.UserId) ~= nil)
end

-- How many are in what's played, on a side (not waiting in line).
function Arena.playing(): number
	local s, m, g, d, t = skirmish, match, gun, dm, tdm
	local members: { [number]: Roster.Member }? = if s
		then s.members
		elseif m then m.members
		elseif g then g.members
		elseif d then d.members
		elseif t then t.members
		else nil
	local n = 0
	if members then
		for _ in members do
			n += 1
		end
	end
	return n
end

-- The rounds' clock, once a server frame.
function Arena.step(time: number)
	local ids: { number }
	local s, m, g, d, t = skirmish, match, gun, dm, tdm
	if s then
		ids = ArenaRules.step(s, time)
		publishLoadouts(s.members)
	elseif m then
		ids = MatchRules.step(m, time)
		publishLoadouts(m.members)
	elseif g then
		ids = GunGameRules.step(g, time)
		publishLoadouts(g.members)
		publishProtection(time)
	elseif d then
		local before = d.match
		ids = DeathmatchRules.step(d, time)
		if d.match ~= before then
			-- Where anyone fell last match is no matter now.
			table.clear(diedAt)
		end
		pickUps(d, time)
		publishLoadouts(d.members)
	elseif t then
		ids = TeamDeathmatchRules.step(t, time)
		spawnRooms(t, time)
		PickupsServer.step(t, time)
		publishLoadouts(t.members)
		publishProtection(time)
	else
		return
	end
	publish()
	roundStarted()
	roundEnded()
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
		local s, m, g, d, t = skirmish, match, gun, dm, tdm
		if s then
			ArenaRules.skip(s, now())
		elseif m then
			MatchRules.skip(m, now())
		elseif g then
			GunGameRules.skip(g, now())
		elseif d then
			DeathmatchRules.skip(d, now())
		elseif t then
			TeamDeathmatchRules.skip(t, now())
		end
		publish()
	end)
	-- A vote for the next map, by its number in the list.
	Remotes.get().Vote.OnServerEvent:Connect(function(player, option)
		local s, m, g, d, t = skirmish, match, gun, dm, tdm
		if typeof(option) ~= "number" then
			return
		end
		local counted = if s
			then ArenaRules.vote(s, player.UserId, option)
			elseif g then GunGameRules.vote(g, player.UserId, option)
			elseif m then MatchRules.vote(m, player.UserId, option)
			elseif d then DeathmatchRules.vote(d, player.UserId, option)
			elseif t then TeamDeathmatchRules.vote(t, player.UserId, option)
			else false
		if counted then
			publish()
		end
	end)
	-- A loadout picked for a stage of Team Deathmatch, by the stage's number
	-- and the loadout's in its list, where the rules let it be (in the spawn
	-- room, during a match); handed over as they say (spawnRooms).
	Remotes.get().LoadoutPick.OnServerEvent:Connect(function(player, stage, index)
		local t = tdm
		if not t or typeof(stage) ~= "number" or typeof(index) ~= "number" then
			return
		end
		local sim = if PlayerSimServer.isAlive(player) then PlayerSimServer.getSim(player) else nil
		local feet = if sim then sim.movement.position - SpikeMaps.Maps[t.map].origin else nil
		local inRoom = feet ~= nil and TeamDeathmatchRules.roomOf(t, player.UserId, feet) == "own"
		if TeamDeathmatchRules.pick(t, player.UserId, stage, index, inRoom) then
			publish()
		end
	end)
	-- P asks for the next of: "skirmish", "gungame", a format of the spike
	-- rounds, or "off" (true and false are the arena on and off). It takes
	-- "deathmatch" and "teamdeathmatch" too, which P never asks for: the Play
	-- menu has them.
	Remotes.get().Arena.OnServerEvent:Connect(function(player, asked)
		if not Tuning.canTune(player) then
			return
		end
		if asked == false or asked == "off" then
			Workspace:SetAttribute(ArenaConfig.ON, false)
		elseif asked == true or asked == "skirmish" then
			Workspace:SetAttribute(ArenaConfig.MODE, "skirmish")
			Workspace:SetAttribute(ArenaConfig.ON, true)
		elseif asked == "gungame" or asked == "deathmatch" or asked == "teamdeathmatch" then
			Workspace:SetAttribute(ArenaConfig.MODE, asked)
			Workspace:SetAttribute(ArenaConfig.ON, true)
		elseif typeof(asked) == "string" and MatchConfig.Formats[asked] then
			Workspace:SetAttribute(MatchConfig.FORMAT, asked)
			Workspace:SetAttribute(ArenaConfig.MODE, "spike")
			Workspace:SetAttribute(ArenaConfig.ON, true)
		end
	end)

	PlayerSimServer.spawnPicker = function(player: Player): PlayerSimServer.SpawnPoint?
		local id = player.UserId
		local s, m, g, d, t = skirmish, match, gun, dm, tdm
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
			-- The spawn of the side's role this round, on the match's map.
			local spot = MatchRules.spotOf(m, id)
			if not spot then
				return nil
			end
			local plan = SpikeMaps.Maps[m.map]
			local spots = plan.spots(if MatchRules.attacking(m, id) then "attack" else "defend")
			local chosen = spots[(spot - 1) % #spots + 1]
			return { feet = plan.origin + chosen.feet, yaw = chosen.yaw }
		elseif d and d.members[id] then
			-- Anywhere on the map nobody alive sees (DeathmatchSpawns).
			local plan = SpikeMaps.Maps[d.map]
			local enemies = {}
			for other, member in d.members do
				local them = if other ~= id and member.alive then playerFor(other) else nil
				local sim = if them and PlayerSimServer.isAlive(them) then PlayerSimServer.getSim(them) else nil
				if sim then
					table.insert(enemies, sim.movement.position - plan.origin)
				end
			end
			local chosen = DeathmatchSpawns.choose(spotsFor(d.map), enemies, diedAt[player], seesFor(d.map), math.random)
			diedAt[player] = nil
			return { feet = plan.origin + chosen.feet, yaw = chosen.yaw }
		elseif t then
			-- Their side's spawn room, on the match's map.
			local side, spot = TeamDeathmatchRules.sideOf(t, id), TeamDeathmatchRules.spotOf(t, id)
			if not side or not spot then
				return nil
			end
			local plan = SpikeMaps.Maps[t.map]
			local spots = plan.spots(TeamDeathmatchRules.roleOf(side))
			local chosen = spots[(spot - 1) % #spots + 1]
			return { feet = plan.origin + chosen.feet, yaw = chosen.yaw }
		end
		return nil
	end
	PlayerSimServer.loadoutRule = function(player: Player): boolean?
		local s, m, g, d, t = skirmish, match, gun, dm, tdm
		if s then
			return ArenaRules.canPick(s, player.UserId)
		elseif m then
			return MatchRules.canPick(m, player.UserId)
		elseif g or t then
			-- Gun game's guns come with its levels, and Team Deathmatch's with its
			-- stages.
			return false
		elseif d then
			return DeathmatchRules.canPick(d, player.UserId)
		end
		return nil
	end
	-- Where each player is for picking an agent, by the side they're on
	-- (system 48), and whether one locked in goes on their kit at once
	-- (system 29).
	AgentServer.momentOf = function(player: Player): string?
		local s, m, t = skirmish, match, tdm
		local sides: Roster.Sides? = if s then s elseif m then m elseif t then t else nil
		local phase: string = if s then s.phase elseif m then m.phase elseif t then t.phase else ""
		local number = if s then s.match elseif m then m.match elseif t then t.match else 0
		local side = if sides then Roster.sideOf(sides, player.UserId) else nil
		return AgentSelect.moment(mode, phase, number, begun, side)
	end
	AgentServer.swapsNow = function(player: Player): boolean
		local s, m, t = skirmish, match, tdm
		local phase: string? = if s then s.phase elseif m then m.phase elseif t then t.phase elseif mode then "" else nil
		local sim = if PlayerSimServer.isAlive(player) then PlayerSimServer.getSim(player) else nil
		local feet = if t and sim then sim.movement.position - SpikeMaps.Maps[t.map].origin else nil
		local ownRoom = t ~= nil and feet ~= nil and TeamDeathmatchRules.roomOf(t, player.UserId, feet) == "own"
		return AgentSelect.swapsNow(phase, sim ~= nil, ownRoom)
	end
	-- Deathmatch sells its guns alone.
	ShopServer.sells = function(kind: string): boolean
		return dm == nil or DeathmatchConfig.FOR_SALE[kind] == true
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
		local s, m, g, d, t = skirmish, match, gun, dm, tdm
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
		elseif d then
			DeathmatchRules.damaged(d, by.UserId, hurt.UserId, amount)
		elseif t then
			TeamDeathmatchRules.damaged(t, by.UserId, hurt.UserId, amount)
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
	-- Sage's Resurrection (system 39): in Skirmish and the spike rounds,
	-- whoever's on the caster's side and down, while the round's played,
	-- and alive again as they burst out; in the other modes, nobody.
	ReviveServer.canRevive = function(by, owner): boolean?
		local a, b = by.player, owner.player
		local s, m = skirmish, match
		if mode == nil then
			return nil
		elseif not a or not b then
			return false
		elseif s then
			return ArenaRules.canRevive(s, a.UserId, b.UserId)
		elseif m then
			return MatchRules.canRevive(m, a.UserId, b.UserId)
		end
		return false
	end
	-- The combat report goes by the round in Skirmish and the spike rounds,
	-- once one's under way (system 53), and so does the kill banner's count
	-- (system 55).
	local function byRound(): boolean
		local s, m = skirmish, match
		local phase: string? = if s then s.phase elseif m then m.phase else nil
		return phase ~= nil and phase ~= "waiting"
	end
	ReportServer.byRound = byRound
	BannerServer.byRound = byRound
	table.insert(ReviveServer.reviveListeners, function(owner)
		local player = owner.player
		local s, m = skirmish, match
		if not player then
			return
		end
		if s then
			ArenaRules.revived(s, player.UserId)
			publish()
		elseif m then
			MatchRules.revived(m, player.UserId)
			publish()
		end
	end)
	table.insert(PlayerSimServer.deathListeners, function(player: Player, killer: Player?)
		local s, m, g, d, t = skirmish, match, gun, dm, tdm
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
				arm(killer, GunGameRules.kitOf(g, killer.UserId))
			end
			publish()
		elseif d then
			-- A health pack where they fell, on the floor, and the next life
			-- away from here.
			local sim = PlayerSimServer.getSim(player)
			local origin = SpikeMaps.Maps[d.map].origin
			local feet = if sim then sim.movement.position - origin else nil
			local floor = if feet then vector.create(feet.x, 0, feet.z) else nil
			if floor then
				diedAt[player] = floor
			end
			DeathmatchRules.died(d, player.UserId, now(), if killer then killer.UserId else nil, floor)
			-- Every kill reloads the gun in the killer's hands.
			if killer then
				reload(killer)
			end
			publish()
		elseif t then
			TeamDeathmatchRules.died(t, player.UserId, now(), if killer then killer.UserId else nil)
			publish()
		end
	end)
	-- G does nothing in gun game and both deathmatches, as their clients don't
	-- send it (ArenaHud); should a drop come anyway, the gun goes straight back
	-- where it was, as it was (GroundGunsServer leaves it off the ground). But
	-- in Team Deathmatch G destroys a gun a spawner lent, and the loadout's
	-- comes back (spawnRooms).
	table.insert(PlayerSimServer.dropListeners, function(player: Player, dropped: WeaponSim.Dropped)
		local t = tdm
		if t and TeamDeathmatchRules.lentOf(t, player.UserId, dropped.slot) == dropped.id then
			TeamDeathmatchRules.returned(t, player.UserId, dropped.slot)
			publish()
		elseif gun or dm or tdm then
			PlayerSimServer.give(player, dropped.slot, dropped.id, dropped.ammo, dropped.reserve)
		end
	end)
	-- Each new life in gun game and Team Deathmatch can't be hurt for a
	-- moment, until it fires, swings or scopes (or in Team Deathmatch leaves
	-- its room, spawnRooms).
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		local g, t = gun, tdm
		if g then
			GunGameRules.spawned(g, player.UserId, now())
		elseif t then
			TeamDeathmatchRules.spawned(t, player.UserId, now())
		end
		publishProtection(now())
	end)
	local ATTACK = bit32.bor(PlayerSim.Buttons.Fire, PlayerSim.Buttons.AltFire)
	table.insert(PlayerSimServer.tickListeners, function(player: Player, input: PlayerCodec.WireInput)
		local g, t = gun, tdm
		if not bit32.btest(input.buttons, ATTACK) then
			return
		end
		if (g and GunGameRules.fired(g, player.UserId)) or (t and TeamDeathmatchRules.unprotect(t, player.UserId)) then
			publishProtection(now())
		end
	end)
	CombatServer.protected = function(entity): boolean
		local g, t = gun, tdm
		local player = entity.player
		if not player then
			return false
		end
		return (g ~= nil and GunGameRules.safe(g, player.UserId, now())) or (t ~= nil and TeamDeathmatchRules.safe(t, player.UserId, now()))
	end

	Players.PlayerAdded:Connect(function(player)
		if not Arena.menuFirst then
			join(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		queued[player] = nil
		kitMatch[player] = nil
		loadouts[player] = nil
		killedWith[player] = nil
		chosen[player] = nil
		diedAt[player] = nil
		leave(player)
	end)

	Workspace:SetAttribute(ArenaConfig.ON, on)
end

return Arena
