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
-- does nothing, as the guns can't be dropped. P asks the server for the next
-- of: the arena, gun game, the spike rounds, the spike rounds in Swiftplay's
-- format, and off (Studio or the place owner).
--
-- Either side of the top bar, who's alive (system 16): a tile for each
-- player, yours on the left and theirs on the right, as the reference's
-- agent portraits, with the first letters of their name, dimmed once
-- they're dead (MatchConfig.ALIVE).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local ArenaLayout = require(Shared.Arena.ArenaLayout)
local GunGameConfig = require(Shared.Arena.GunGameConfig)
local MatchConfig = require(Shared.Match.MatchConfig)
local MatchRules = require(Shared.Match.MatchRules)
local SpikeMaps = require(Shared.Match.SpikeMaps)
local PlayerSim = require(Shared.PlayerSim)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Remotes = require(Shared.Net.Remotes)

local Ui = require(script.Parent.Debug.Ui)
local InputSampler = require(script.Parent.InputSampler)
local PlayerController = require(script.Parent.PlayerController)
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

-- The players' tiles beside the top bar.
local TILE_W, TILE_H, TILE_GAP = 30, 38, 4
local MAX_TILES = 5 -- a side

type Tile = { frame: Frame, label: TextLabel }

local function newTile(gui: ScreenGui): Tile
	local frame = Ui.frame(gui, { Size = UDim2.fromOffset(TILE_W, TILE_H), Visible = false })
	local label = Ui.label(frame, {
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	return { frame = frame, label = label }
end

-- A name's first two letters, for its tile.
local function initials(player: Player): string
	return string.upper(string.sub(player.DisplayName, 1, 2))
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
-- its right, nearest first, alive in the side's colour or dimmed.
local function placeTiles(tiles: { Tile }, players: { Player }, colour: Color3, width: number, left: boolean)
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
		tile.label.Text = initials(player)
		tile.label.TextColor3 = if alive then Ui.PANEL else colour
		tile.label.TextTransparency = if alive then 0 else 0.5
	end
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

-- A gun's name as the HUD has it.
local function gunName(id: string?): string
	local def = if id then WeaponConfig.Defs[id] else nil
	return if def then string.upper(def.name) else ""
end

-- Seconds a level's change shows in the middle (ours).
local FLASH_TIME = 1.5

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

	local arena = Workspace:WaitForChild(ArenaConfig.MODEL)
	local me = Players.LocalPlayer
	-- Gun game: your level as last seen, in which phase, and what its last
	-- change shows until when.
	local seenLevel: number? = nil
	local seenPhase: any = nil
	local flash = { title = "", sub = "", colour = Ui.TEXT, untilTime = 0 }

	RunService.RenderStepped:Connect(function()
		local on = Workspace:GetAttribute(ArenaConfig.ON) == true
		-- Gun game's guns can't be dropped, as in Arms Race: G does nothing.
		InputSampler.blockButtons = if on and Workspace:GetAttribute(ArenaConfig.MODE) == "gungame" then PlayerSim.Buttons.Drop else 0
		local phase = arena:GetAttribute("Phase")
		local side = me:GetAttribute(ArenaConfig.SIDE)
		if not on or typeof(phase) ~= "string" or typeof(side) ~= "number" then
			bar.Visible = false
			guns.Visible = false
			banner.Visible = false
			subtitle.Visible = false
			seenLevel, seenPhase = nil, nil
			for _, row in tiles do
				for _, tile in row do
					tile.frame.Visible = false
				end
			end
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
		guns.Visible = false
		if not gunGame then
			seenLevel, seenPhase = nil, nil
		end

		local width = if spike then 280 else 240
		bar.Size = UDim2.fromOffset(width, 58)
		bar.Position = UDim2.new(0.5, -width / 2, 0, 8)
		bar.Visible = true
		placeTiles(tiles[1], sideOf(side), ally, width, true)
		placeTiles(tiles[2], sideOf(other), enemy, width, false)
		ours.Text = tostring(score[side])
		ours.TextColor3 = ally
		theirs.Text = tostring(score[other])
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
