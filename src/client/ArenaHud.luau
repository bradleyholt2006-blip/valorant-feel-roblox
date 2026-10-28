--!strict
-- The arena's HUD (system 7) and the spike rounds' (system 13), while either
-- is on: at the top, your side's score in the ally colour and the other
-- side's in the enemy colour, with the round between them, like the
-- reference's top bar; and in the middle, the buy phase's countdown and how a
-- round ended (the match's end is the victory screen's, Scoreboard's, and the
-- vote for the next map VoteScreen's), and as a match starts, which of its
-- mode's maps it's on (systems 22 and 25). In the spike rounds the top bar also
-- has the round's clock, which gives way to the spike once it's planted, and
-- whether your side attacks or defends; the buy phase says what's at stake
-- (match point, overtime) and your credits, and a round's end says how it was
-- won and when the sides swap. In gun game (system 23) the top bar has each
-- side's highest level either side of the match's clock, your level under
-- it, and under the bar the gun you're on and the next; moving up or being
-- knifed down shows in the middle for a moment, as does your spawn
-- protection, the gun you move up to is drawn as it's handed over, and G
-- does nothing, as the guns can't be dropped. In deathmatch (system 26) the
-- top bar has your kills and the most anyone else has either side of the
-- match's clock, with the kills that win under it, and under the bar your
-- place and who leads; there are no tiles, as there are no sides, and G does
-- nothing there either. In Team Deathmatch (system 27) the top bar has each
-- side's kills either side of the clock (the pre-game's, then the match's),
-- with the stage under way under it, and under the bar when the next comes.
-- A new stage shows in the middle for a moment with the loadout it brings,
-- and then how long until it's handed over; so do your spawn protection and
-- a warning while a spawn room burns you, or soon will. A primary handed
-- over mid-life is drawn, and G does nothing, but with a gun a weapon
-- spawner lent you in hand (system 28), which it destroys for your
-- loadout's, as the line under the bar says. P asks the server for the
-- next of: the arena, gun game, the spike rounds, the spike rounds in
-- Swiftplay's format, and off (Studio or the place owner).
--
-- Either side of the top bar, who's alive (system 16): a tile for each
-- player, yours on the left and theirs on the right, as the reference's
-- agent portraits, dimmed once they're dead (MatchConfig.ALIVE). Each has
-- the first letters of their agent's name, or in gun game, where nobody
-- plays one, of their own (system 51, Glance.badge). Under your side's is
-- each one's health, and under anyone's a gold diamond while their
-- ultimate's ready (AbilityConfig.ULT_ATTRIBUTE). The HUD's Yours and
-- Theirs attributes list the tiles as Glance.describe has them, for
-- scripted checks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local ArenaLayout = require(Shared.Arena.ArenaLayout)
local DeathmatchConfig = require(Shared.Arena.DeathmatchConfig)
local GunGameConfig = require(Shared.Arena.GunGameConfig)
local TeamDeathmatchConfig = require(Shared.Arena.TeamDeathmatchConfig)
local TeamDeathmatchRules = require(Shared.Arena.TeamDeathmatchRules)
local MatchConfig = require(Shared.Match.MatchConfig)
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AgentSelect = require(Shared.Abilities.AgentSelect)
local Glance = require(Shared.Abilities.Glance)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local MatchRules = require(Shared.Match.MatchRules)
local SpikeMaps = require(Shared.Match.SpikeMaps)
local PlayerSim = require(Shared.PlayerSim)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Remotes = require(Shared.Net.Remotes)

local Ui = require(script.Parent.Debug.Ui)
local InputSampler = require(script.Parent.InputSampler)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local Visuals = require(script.Parent.Visuals)

local ArenaHud = {}

-- The spike's red, as its own HUD has it, and the buy menu's gold for credits.
local SPIKE_RED = Color3.fromRGB(235, 70, 60)
local GOLD = Color3.fromRGB(230, 200, 120)

-- How a round of the spike rounds was won, for the side that won it and the
-- side that lost it (our words).
local REASONS: { [string]: { won: string, lost: string } } = {
	eliminated = { won = "Enemies eliminated", lost = "Your side was eliminated" },
	detonated = { won = "Spike detonated", lost = "Spike detonated" },
	defused = { won = "Spike defused", lost = "Spike defused" },
	time = { won = "Time ran out before a plant", lost = "Time ran out before a plant" },
}

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

-- The players' tiles beside the top bar, with the health bar and the
-- ultimate's diamond under them (system 51).
local TILE_W, TILE_H, TILE_GAP = 30, 38, 4
local MAX_TILES = 5 -- a side
local HEALTH_H, DIAMOND = 3, 7
local MAX_HEALTH = WeaponConfig.Health.maxHealth.value

type Tile = { frame: Frame, label: TextLabel, health: Frame, fill: Frame, ready: Frame }

local function newTile(gui: ScreenGui): Tile
	local frame = Ui.frame(gui, { Size = UDim2.fromOffset(TILE_W, TILE_H), Visible = false })
	local label = Ui.label(frame, {
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local health = Ui.frame(frame, {
		Size = UDim2.new(1, 0, 0, HEALTH_H),
		Position = UDim2.new(0, 0, 1, 3),
		BackgroundTransparency = 0.2,
	})
	local fill = Ui.frame(health, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Ui.TEXT, BackgroundTransparency = 0 })
	local ready = Ui.frame(frame, {
		Size = UDim2.fromOffset(DIAMOND, DIAMOND),
		Position = UDim2.new(0.5, -DIAMOND / 2, 1, 3 + HEALTH_H + 4),
		Rotation = 45,
		BackgroundColor3 = GOLD,
		BackgroundTransparency = 0,
		Visible = false,
	})
	return { frame = frame, label = label, health = health, fill = fill, ready = ready }
end

-- The players on a side, in the order their tiles go.
local function sideOf(side: number): { Player }
	local out = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute(ArenaConfig.SIDE) == side then
			table.insert(out, player)
		end
	end
	table.sort(out, function(a: Player, b: Player): boolean
		return a.DisplayName < b.DisplayName
	end)
	return out
end

-- Puts a side's tiles beside a bar `width` wide: to its left (`left`) or
-- its right, nearest first, alive in the side's colour or dimmed, each with
-- its agent (where `agents` are played) and its ultimate's diamond, and on
-- your side (`yours`) its health. Returns them as Glance.describe lists them.
local function placeTiles(
	tiles: { Tile },
	players: { Player },
	colour: Color3,
	width: number,
	left: boolean,
	yours: boolean,
	agents: boolean
): string
	local listed = {}
	for i, tile in tiles do
		local player: Player? = players[i]
		if not player then
			tile.frame.Visible = false
			continue
		end
		tile.frame.Visible = true
		local step = (i - 1) * (TILE_W + TILE_GAP) + TILE_GAP
		local x = if left then -width / 2 - step - TILE_W else width / 2 + step
		tile.frame.Position = UDim2.new(0.5, x, 0, 8 + (58 - TILE_H) / 2)
		local alive = player:GetAttribute(MatchConfig.ALIVE) ~= false
		tile.frame.BackgroundColor3 = if alive then colour else Ui.PANEL
		tile.frame.BackgroundTransparency = if alive then 0.15 else 0.35
		local badge = Glance.badge(if agents then player:GetAttribute(AgentSelect.AGENT) else nil, player.DisplayName)
		tile.label.Text = badge
		tile.label.TextColor3 = if alive then Ui.PANEL else colour
		tile.label.TextTransparency = if alive then 0 else 0.5
		local health: number? = nil
		if yours then
			local hp = RemoteEntities.healthOf(PlayerCodec.entityIdForUser(player.UserId))
			health = if alive then hp.health else 0
		end
		tile.health.Visible = health ~= nil
		tile.fill.Size = UDim2.fromScale(Glance.share(health or 0, MAX_HEALTH), 1)
		local ready = agents and Glance.ready(player:GetAttribute(AbilityConfig.ULT_ATTRIBUTE))
		tile.ready.Visible = ready
		tile.ready.BackgroundTransparency = if alive then 0 else 0.5
		table.insert(listed, Glance.describe(badge, health, alive, ready))
	end
	return table.concat(listed, ", ")
end

local function clock(seconds: number): string
	local whole = math.ceil(seconds)
	return string.format("%d:%02d", whole // 60, whole % 60)
end

-- What P asks for next.
local function nextMode(): string
	local mode = Workspace:GetAttribute(ArenaConfig.MODE)
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return "skirmish"
	elseif mode == "gungame" then
		return MatchConfig.DEFAULT_FORMAT
	elseif mode ~= "spike" then
		return "gungame"
	elseif Workspace:GetAttribute(MatchConfig.FORMAT) == MatchConfig.DEFAULT_FORMAT then
		return "swiftplay"
	end
	return "off"
end

local function split(text: any): { string }
	local out = {}
	if typeof(text) == "string" then
		for item in string.gmatch(text, "[^,]+") do
			table.insert(out, item)
		end
	end
	return out
end

local function killsOf(player: Player): number
	local value = player:GetAttribute(MatchConfig.KILLS)
	return if typeof(value) == "number" then value else 0
end

-- A gun's name as the HUD has it.
local function gunName(id: string?): string
	local def = if id then WeaponConfig.Defs[id] else nil
	return if def then string.upper(def.name) else ""
end

-- A shield's name as the HUD has it.
local function shieldName(id: string): string
	local def = WeaponConfig.Shields[id]
	return if def then string.upper(def.name) else "NO SHIELD"
end

-- Seconds a level's change shows in the middle, and a stage's (ours).
local FLASH_TIME = 1.5
local STAGE_FLASH = 2.5

local TDM = TeamDeathmatchConfig.Rules
local STAGES = TeamDeathmatchConfig.Stages

-- Draws the gun `id` from its slot: at once if it's there already, or once
-- the server's handed it over.
local function draw(id: string)
	local def = WeaponConfig.Defs[id]
	local sim = PlayerController.sim
	if not def then
		return
	elseif sim and sim.weapons.loadout[def.slot] == id then
		PlayerController.selectSlot(def.slot)
	else
		PlayerController.drawWhenGiven(def.slot, id)
	end
end

function ArenaHud.start()
	local gui = Ui.screen("VFArenaHud", 16)
	local centre = Ui.screen("VFArenaBanner", 16, Enum.ScreenInsets.None)

	local bar = Ui.frame(gui, {
		Size = UDim2.fromOffset(240, 58),
		Position = UDim2.new(0.5, -120, 0, 8),
		Visible = false,
	})
	local ours = Ui.label(bar, {
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		TextSize = 34,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local theirs = Ui.label(bar, {
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.new(1, -76, 0, 0),
		TextSize = 34,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local round = Ui.label(bar, {
		Size = UDim2.new(1, -152, 0, 22),
		Position = UDim2.fromOffset(76, 9),
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local target = Ui.label(bar, {
		Size = UDim2.new(1, -152, 0, 16),
		Position = UDim2.fromOffset(76, 32),
		TextSize = 11,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- Gun game's: the gun you're on and the next, under the bar.
	local guns = Ui.label(gui, {
		Size = UDim2.fromOffset(480, 18),
		Position = UDim2.new(0.5, -240, 0, 70),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})

	local banner = Ui.label(centre, {
		Size = UDim2.fromOffset(800, 44),
		Position = UDim2.new(0.5, -400, 0.22, 0),
		TextSize = 34,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})
	local subtitle = Ui.label(centre, {
		Size = UDim2.fromOffset(800, 22),
		Position = UDim2.new(0.5, -400, 0.22, 46),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})

	local tiles: { { Tile } } = { {}, {} } -- yours, theirs
	for _, row in tiles do
		for _ = 1, MAX_TILES do
			table.insert(row, newTile(gui))
		end
	end
	local function hideTiles()
		for _, row in tiles do
			for _, tile in row do
				tile.frame.Visible = false
			end
		end
	end

	local arena = Workspace:WaitForChild(ArenaConfig.MODEL)
	local me = Players.LocalPlayer
	-- Whether the gun in your hand is one a Team Deathmatch spawner lent
	-- you (system 28): its attribute has the lent guns by slot.
	local function lentInHand(): boolean
		local lent = me:GetAttribute(TeamDeathmatchConfig.LENT)
		local sim = PlayerController.sim
		if typeof(lent) ~= "string" or not sim or not PlayerController.alive then
			return false
		end
		local slot = sim.weapons.equipped
		local gun = string.split(lent, ",")[slot]
		return (slot == 1 or slot == 2) and gun ~= nil and gun ~= "" and sim.weapons.loadout[slot] == gun
	end
	-- Gun game: your level as last seen, in which phase, and what its last
	-- change shows until when.
	local seenLevel: number? = nil
	local seenPhase: any = nil
	local flash = { title = "", sub = "", colour = Ui.TEXT, untilTime = 0 }
	-- Team Deathmatch: the stage under way as last seen, and your life as
	-- last seen, with the primary it held.
	local seenStage: number? = nil
	local seenLife = -1
	local seenPrimary: string? = nil

	RunService.RenderStepped:Connect(function()
		local on = Workspace:GetAttribute(ArenaConfig.ON) == true
		-- Gun game's guns can't be dropped, as in Arms Race, nor either
		-- deathmatch's (ours): G does nothing, but destroy a gun a Team
		-- Deathmatch spawner lent.
		local wanted = Workspace:GetAttribute(ArenaConfig.MODE)
		local undroppable = wanted == "gungame" or wanted == "deathmatch" or (wanted == "teamdeathmatch" and not lentInHand())
		InputSampler.blockButtons = if on and undroppable then PlayerSim.Buttons.Drop else 0
		local phase = arena:GetAttribute("Phase")
		local side = me:GetAttribute(ArenaConfig.SIDE)
		if not on or typeof(phase) ~= "string" or typeof(side) ~= "number" then
			bar.Visible = false
			guns.Visible = false
			banner.Visible = false
			subtitle.Visible = false
			seenLevel, seenPhase = nil, nil
			hideTiles()
			gui:SetAttribute("Yours", nil)
			gui:SetAttribute("Theirs", nil)
			return
		end
		local other = 3 - side
		local ally = color3(VisualConfig.allyColour)
		local enemy = color3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
		local score = { arena:GetAttribute("Score1") or 0, arena:GetAttribute("Score2") or 0 }
		local winScore = arena:GetAttribute("WinScore") or 0
		local roundNumber = arena:GetAttribute("Round") or 0
		local endsAt = arena:GetAttribute("PhaseEndsAt")
		local left = if typeof(endsAt) == "number" then math.max(endsAt - Workspace:GetServerTimeNow(), 0) else 0
		local formatKey = arena:GetAttribute("Format")
		local format = if typeof(formatKey) == "string" then MatchConfig.Formats[formatKey] else nil
		local attackers = arena:GetAttribute("Attackers")
		local spike = arena:GetAttribute("Mode") == "spike" and format ~= nil and typeof(attackers) == "number"
		local gunGame = arena:GetAttribute("Mode") == "gungame"
		local deathmatch = arena:GetAttribute("Mode") == "deathmatch"
		local teamDeathmatch = arena:GetAttribute("Mode") == "teamdeathmatch"
		guns.Visible = false
		if not gunGame then
			seenLevel, seenPhase = nil, nil
		end
		if not teamDeathmatch then
			seenStage = nil
		end

		local width = if spike then 280 else 240
		bar.Size = UDim2.fromOffset(width, 58)
		bar.Position = UDim2.new(0.5, -width / 2, 0, 8)
		bar.Visible = true
		if deathmatch then
			hideTiles()
			gui:SetAttribute("Yours", nil)
			gui:SetAttribute("Theirs", nil)
		else
			gui:SetAttribute("Yours", placeTiles(tiles[1], sideOf(side), ally, width, true, true, not gunGame))
			gui:SetAttribute("Theirs", placeTiles(tiles[2], sideOf(other), enemy, width, false, false, not gunGame))
			ours.Text = tostring(score[side])
			theirs.Text = tostring(score[other])
		end
		ours.TextColor3 = ally
		theirs.TextColor3 = enemy
		round.TextColor3 = Ui.TEXT

		local title, sub, colour = "", "", Ui.TEXT
		if spike and format then
			local attacking = attackers == side
			local role = if attacking then "ATTACK" else "DEFEND"
			-- The clock: the buy phase's and then the round's, or the spike's
			-- place once it's planted, as the reference's top bar.
			if phase == "planted" then
				round.Text = "SPIKE"
				round.TextColor3 = SPIKE_RED
			elseif phase == "buy" or phase == "live" then
				round.Text = clock(left)
			elseif phase == "waiting" then
				round.Text = "SPIKE ROUNDS"
			else
				round.Text = clock(0)
			end
			target.Text = if roundNumber > 0 then string.format("ROUND %d   %s", roundNumber, role) else format.name:upper()

			if phase == "waiting" then
				title = "WAITING FOR AN OPPONENT"
				sub = string.format("%s, first to %d. Anyone who joins plays for the other side   B buy menu", format.name, winScore)
			elseif phase == "buy" then
				title = string.format("BUY PHASE  %d", math.ceil(left))
				local stakes = {}
				local map = SpikeMaps.Maps[arena:GetAttribute("Map") or ""]
				if roundNumber == 1 and map then
					table.insert(stakes, string.upper(map.NAME))
				end
				local credits = me:GetAttribute(MatchConfig.CREDITS)
				if typeof(credits) == "number" then
					table.insert(stakes, string.format('<font color="#%s">%d CREDITS</font>', Ui.hex(GOLD), credits))
				end
				local point = MatchRules.matchPointOf(format, score[1], score[2])
				if MatchRules.overtime(format, roundNumber) then
					table.insert(stakes, if format.overtime == "suddenDeath" then "SUDDEN DEATH" else "OVERTIME")
				elseif point[1] or point[2] then
					table.insert(stakes, "MATCH POINT")
				end
				if roundNumber == format.halfRounds.value then
					table.insert(stakes, "LAST ROUND OF THE HALF")
				end
				table.insert(stakes, if attacking then "Attack: plant the spike at A or B" else "Defend A and B")
				table.insert(stakes, "B buy menu")
				sub = table.concat(stakes, "   ")
			elseif phase == "roundOver" then
				local won = arena:GetAttribute("RoundWinner") == side
				title = if won then "ROUND WON" else "ROUND LOST"
				colour = if won then ally else enemy
				local reason = REASONS[arena:GetAttribute("Reason") or ""]
				sub = if reason then (if won then reason.won else reason.lost) else ""
				if MatchRules.swapsAfter(format, roundNumber) then
					sub ..= "   SWITCHING SIDES"
				end
			end
		elseif gunGame then
			local ladder = split(arena:GetAttribute("Ladder"))
			local level = me:GetAttribute(GunGameConfig.LEVEL)
			local levelNow: number? = if typeof(level) == "number" then level else nil
			local playing = phase == "live" or phase == "waiting"
			round.Text = if phase == "live" then clock(left) else "GUN GAME"
			target.Text = if levelNow then string.format("LEVEL %d OF %d", levelNow, #ladder) else string.format("%d LEVELS", #ladder)
			if levelNow and playing then
				local gun, nextGun = ladder[levelNow], ladder[levelNow + 1]
				guns.Visible = true
				guns.Text = string.format('<font color="#%s">%s</font>', Ui.hex(GOLD), gunName(gun))
					.. (if nextGun then "   NEXT  " .. gunName(nextGun) else "   A KILL WINS")
			end
			-- A change of level in a match under way: up, with the next gun
			-- drawn as it comes, or down to a knife.
			local before = seenLevel
			if levelNow and before and levelNow ~= before and phase == "live" and seenPhase == "live" then
				if levelNow > before then
					local gun = ladder[levelNow]
					flash.title = string.format("LEVEL %d", levelNow)
					flash.sub = if levelNow == #ladder then "THE KNIFE: A KILL WINS THE MATCH" else gunName(gun)
					flash.colour = ally
					if gun and PlayerController.alive then
						draw(gun)
					end
				else
					flash.title = "KNIFED"
					flash.sub = string.format("Down to level %d", levelNow)
					flash.colour = enemy
				end
				flash.untilTime = os.clock() + FLASH_TIME
			end
			seenLevel, seenPhase = levelNow, phase
			if phase == "waiting" then
				title = "WAITING FOR AN OPPONENT"
				sub = "Gun game: a kill with each gun moves you on to the next, and a knife kill on the last level wins"
			elseif phase == "live" and os.clock() < flash.untilTime then
				title, sub, colour = flash.title, flash.sub, flash.colour
			elseif phase == "live" and me:GetAttribute(GunGameConfig.PROTECTED) == true then
				sub = "SPAWN PROTECTION   until you fire"
			end
		elseif deathmatch then
			-- Your kills against the most anyone else has, and under the bar
			-- your place among everyone playing, and who leads if it isn't you.
			local rivals, playing = 0, 0
			for _, player in Players:GetPlayers() do
				if typeof(player:GetAttribute(ArenaConfig.SIDE)) == "number" then
					playing += 1
					if player ~= me then
						rivals = math.max(rivals, killsOf(player))
					end
				end
			end
			ours.Text = tostring(killsOf(me))
			theirs.Text = tostring(rivals)
			round.Text = if phase == "live" then clock(left) else "DEATHMATCH"
			target.Text = string.format("FIRST TO %d", winScore)
			local place = me:GetAttribute(DeathmatchConfig.PLACE)
			if typeof(place) == "number" and phase == "live" then
				local id = arena:GetAttribute("Leader")
				local leader = if typeof(id) == "number" and id ~= me.UserId then Players:GetPlayerByUserId(id) else nil
				guns.Visible = true
				guns.Text = string.format('<font color="#%s">%s</font> OF %d', Ui.hex(GOLD), string.upper(Ui.ordinal(place)), playing)
					.. (if leader and killsOf(leader) > 0 then "   LEADER  " .. string.upper(leader.DisplayName) else "")
					.. "   B buy menu"
			end
			if phase == "waiting" then
				title = "WAITING FOR AN OPPONENT"
				sub = string.format(
					"Deathmatch: everyone for themselves, first to %d kills or the most in %d minutes   B buy menu",
					winScore,
					DeathmatchConfig.Rules.timeLimit.value // 60
				)
			end
		elseif teamDeathmatch then
			local stage = arena:GetAttribute("Stage")
			local stageNow: number = if typeof(stage) == "number" then stage else 1
			local stageAt = arena:GetAttribute("StageAt")
			local time = Workspace:GetServerTimeNow()
			local mapKey = arena:GetAttribute("Map")
			local map = SpikeMaps.Maps[if typeof(mapKey) == "string" then mapKey else ""]
			round.Text = if phase == "live" or phase == "pregame" then clock(left) else "TDM"
			target.Text = if phase == "live"
				then string.format("STAGE %d OF %d", stageNow, #STAGES)
				else string.format("FIRST TO %d", winScore)
			-- A primary handed over mid-life, a new stage's or a pick's in the
			-- room, is drawn.
			local life = PlayerController.life
			local sim = PlayerController.sim
			local primary = if sim then sim.weapons.loadout[1] else nil
			if life == seenLife and PlayerController.alive and primary and primary ~= "" and primary ~= seenPrimary then
				PlayerController.selectSlot(1)
			end
			seenLife, seenPrimary = life, primary
			-- A new stage: for a moment, the loadout you've picked for it.
			local before = seenStage
			if phase == "live" and before and stageNow > before then
				local picks = split(me:GetAttribute(TeamDeathmatchConfig.PICKS))
				local list = STAGES[stageNow] or STAGES[1]
				local pick = list[tonumber(picks[stageNow]) or 1] or list[1]
				flash.title = string.format("STAGE %d", stageNow)
				flash.sub = gunName(pick.gun) .. "   " .. shieldName(pick.shield)
				flash.colour = GOLD
				flash.untilTime = os.clock() + STAGE_FLASH
			end
			seenStage = if phase == "live" then stageNow else nil
			local room = if map and sim and PlayerController.alive
				then TeamDeathmatchRules.roomAt(mapKey, side, sim.movement.position - map.origin)
				else nil
			if phase == "live" then
				-- Each stage but the last lasts the stage time. The loadout menu
				-- opens in your spawn room, or while you're down.
				local nextAt = if typeof(stageAt) == "number" and stageNow < #STAGES then stageAt + TDM.stageTime.value else nil
				guns.Visible = true
				guns.Text = string.format("FIRST TO %d", winScore)
					.. (if nextAt then "   NEXT STAGE IN " .. clock(math.max(nextAt - time, 0)) else "   LAST STAGE")
					.. (if room == "own" or not PlayerController.alive then "   B loadouts" else "")
					.. (if lentInHand() then "   G back to your loadout" else "")
			end
			if phase == "waiting" then
				title = "WAITING FOR AN OPPONENT"
				sub = string.format(
					"Team Deathmatch: the first side to %d kills wins, or the side with more in %s   B loadouts",
					winScore,
					clock(TDM.timeLimit.value)
				)
			elseif phase == "pregame" then
				title = string.format("MATCH STARTS IN %d", math.ceil(left))
				sub = (if map then string.upper(map.NAME) .. "   " else "") .. "Pick a loadout for each stage: B"
			elseif phase == "live" then
				-- Your own room burns you its stay time after your life started, or
				-- the match did.
				local since = me:GetAttribute(TeamDeathmatchConfig.ROOM_SINCE)
				local burnsAt = if typeof(since) == "number" then since + TDM.stayTime.value else math.huge
				local burning = room == "enemy" or (room == "own" and time >= burnsAt)
				if burning then
					title = if room == "enemy" then "ENEMY SPAWN ROOM" else "LEAVE THE SPAWN ROOM"
					colour = SPIKE_RED
				elseif os.clock() < flash.untilTime then
					title, sub, colour = flash.title, flash.sub, flash.colour
				end
				-- Under it: the new stage's loadout to come, the protection, or the
				-- burn to come.
				local kitStage = me:GetAttribute(TeamDeathmatchConfig.KIT_STAGE)
				local due = if typeof(stageAt) == "number" then stageAt + TDM.swapDelay.value - time else 0
				local unsaid = PlayerController.alive and sub == ""
				if unsaid and typeof(kitStage) == "number" and kitStage < stageNow and due > 0 then
					sub = string.format("NEW LOADOUT IN %d", math.ceil(due))
				elseif unsaid and me:GetAttribute(GunGameConfig.PROTECTED) == true then
					sub = "SPAWN PROTECTION   until you fire or leave the spawn room"
				elseif unsaid and room == "own" and not burning and burnsAt < math.huge then
					sub = string.format("The spawn room burns you in %d: move out", math.ceil(burnsAt - time))
				end
			end
		else
			round.Text = if roundNumber > 0 then string.format("ROUND %d", roundNumber) else "ARENA"
			target.Text = string.format("FIRST TO %d", winScore)
			if phase == "waiting" then
				title = "WAITING FOR AN OPPONENT"
				sub = "Anyone who joins the server plays for the other side   B buy menu"
			elseif phase == "buy" then
				title = string.format("BUY PHASE  %d", math.ceil(left))
				local map = ArenaLayout.Maps[arena:GetAttribute("Map") or ""]
				sub = (if roundNumber == 1 and map then string.upper(map.name) .. "   " else "") .. "B buy menu"
			elseif phase == "roundOver" then
				local won = arena:GetAttribute("RoundWinner") == side
				title = if won then "ROUND WON" else "ROUND LOST"
				colour = if won then ally else enemy
			end
		end
		if phase == "matchOver" or phase == "vote" then
			-- The victory screen (Scoreboard) has it, and then the vote.
			title, sub = "", ""
		end
		banner.Visible = title ~= ""
		banner.Text = title
		banner.TextColor3 = colour
		subtitle.Visible = sub ~= ""
		subtitle.Text = sub
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.P then
			Remotes.get().Arena:FireServer(nextMode())
		end
	end)
end

return ArenaHud
