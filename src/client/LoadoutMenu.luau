--!strict
-- The loadout menu (system 27), on B in Team Deathmatch: a column for each
-- of its four stages, with the loadouts it has to pick from, each a gun and
-- the shield that comes with it, as the reference's loadout select. Click
-- one to pick it for its stage; what you've picked is outlined in gold, and
-- the stage under way is marked. A pick for the stage under way is handed
-- over at once (TeamDeathmatchRules), or with your next life if you're
-- down, and the first stage's sidearm comes with every stage. It opens on a
-- side or in line for one, but not over the Play menu (system 24), and
-- during a match, as the reference's, only in your own spawn room or while
-- you're down: leaving the room closes it. While it's open the mouse moves
-- a cursor and its buttons are the menu's, and you can still move. The
-- settings menu opens over it, and gives the cursor back to it as it closes.
--
-- What you've picked comes from your TeamDeathmatchConfig.PICKS attribute,
-- the stage under way from the arena model's Stage, and the map from its
-- Map (Arena).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local TeamDeathmatchConfig = require(Shared.Arena.TeamDeathmatchConfig)
local TeamDeathmatchRules = require(Shared.Arena.TeamDeathmatchRules)
local SpikeMaps = require(Shared.Match.SpikeMaps)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Remotes = require(Shared.Net.Remotes)

local CameraController = require(script.Parent.CameraController)
local InputSampler = require(script.Parent.InputSampler)
local PlayerController = require(script.Parent.PlayerController)
local PlayMenu = require(script.Parent.PlayMenu)
local SettingsMenu = require(script.Parent.SettingsMenu)
local Ui = require(script.Parent.Debug.Ui)

local LoadoutMenu = {}

LoadoutMenu.open = false
-- Opens or closes the menu (B, and TestAim's VFTestLoadouts), when it may
-- open. Set up by LoadoutMenu.start.
LoadoutMenu.setOpen = function(_open: boolean) end

-- Picks the loadout `index` of `stage`'s list, as a click on it does (and
-- TestAim's VFTestPick).
function LoadoutMenu.pick(stage: number, index: number)
	Remotes.get().LoadoutPick:FireServer(stage, index)
end

local STAGES = TeamDeathmatchConfig.Stages
local T = TeamDeathmatchConfig.Rules

local COLUMN_W, TILE_H = 196, 58
local GAP = 12
local MARGIN = 24
local TOP = 64
local HEAD_H = 46

local TILE = Color3.fromRGB(28, 30, 38)
local TILE_HOVER = Color3.fromRGB(48, 52, 64)
local GOLD = Color3.fromRGB(230, 200, 120)

type Tile = { stage: number, index: number, button: TextButton, stroke: UIStroke }

-- Whether it may be open: Team Deathmatch played, with you in it, on a side
-- or in line, and the Play menu shut; and during a match, while you're
-- alive, only in your own spawn room (TeamDeathmatchRules.canPick).
local function allowed(): boolean
	local me = Players.LocalPlayer
	local side = me:GetAttribute(ArenaConfig.SIDE)
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true or Workspace:GetAttribute(ArenaConfig.MODE) ~= "teamdeathmatch" or PlayMenu.open then
		return false
	elseif typeof(side) ~= "number" then
		return typeof(me:GetAttribute(ArenaConfig.LINE)) == "number"
	end
	local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
	if not arena or arena:GetAttribute("Phase") ~= "live" or not PlayerController.alive then
		return true
	end
	local key = arena:GetAttribute("Map")
	local map = SpikeMaps.Maps[if typeof(key) == "string" then key else ""]
	local sim = PlayerController.sim
	return map ~= nil and sim ~= nil and TeamDeathmatchRules.roomAt(key, side, sim.movement.position - map.origin) == "own"
end

-- What you've picked, by stage, as the server has it: the first of each
-- until it says otherwise.
local function picks(): { number }
	local out = {}
	local text = Players.LocalPlayer:GetAttribute(TeamDeathmatchConfig.PICKS)
	for item in string.gmatch(if typeof(text) == "string" then text else "", "[^,]+") do
		table.insert(out, tonumber(item) or 1)
	end
	return out
end

local function clock(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- When in the match a stage is under way ("1:15 - 2:30").
local function span(stage: number): string
	local from = TeamDeathmatchRules.stageStart(stage)
	local to = if stage < #STAGES then TeamDeathmatchRules.stageStart(stage + 1) else T.timeLimit.value
	return clock(from) .. " - " .. clock(to)
end

function LoadoutMenu.start()
	local gui = Ui.screen("VFLoadouts", 19)
	gui.Enabled = false
	local most = 0
	for _, list in STAGES do
		most = math.max(most, #list)
	end
	local width = 2 * MARGIN + #STAGES * COLUMN_W + (#STAGES - 1) * GAP
	local height = TOP + HEAD_H + most * (TILE_H + GAP) + 40
	local root = Ui.frame(gui, {
		Name = "Loadouts",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.15,
		Active = true,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = root
	Ui.label(root, {
		Text = "LOADOUTS",
		Font = Enum.Font.GothamBold,
		TextSize = 26,
		Position = UDim2.fromOffset(MARGIN, 18),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 32),
	})
	Ui.label(root, {
		Text = "B to close",
		TextSize = 13,
		TextColor3 = Ui.DIM,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(MARGIN, 26),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 18),
	})
	Ui.label(root, {
		Text = "Click a loadout to pick it for its stage, yours at once for the stage under way. Pick before the match or in your"
			.. " spawn room; the first stage's sidearm comes with every stage",
		TextSize = 13,
		TextColor3 = Ui.DIM,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(MARGIN, height - 40),
		Size = UDim2.fromOffset(width - 2 * MARGIN, 32),
	})

	local tiles: { Tile } = {}
	local heads: { TextLabel } = {}
	local hovered: Tile? = nil
	for stage, list in STAGES do
		local x = MARGIN + (stage - 1) * (COLUMN_W + GAP)
		heads[stage] = Ui.label(root, {
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			Position = UDim2.fromOffset(x, TOP),
			Size = UDim2.fromOffset(COLUMN_W, 20),
		})
		Ui.label(root, {
			Text = span(stage),
			TextSize = 12,
			TextColor3 = Ui.DIM,
			Position = UDim2.fromOffset(x, TOP + 22),
			Size = UDim2.fromOffset(COLUMN_W, 16),
		})
		for index, loadout in list do
			local button = Instance.new("TextButton")
			button.Name = string.format("%d_%d", stage, index)
			button.AutoButtonColor = false
			button.Text = ""
			button.BorderSizePixel = 0
			button.BackgroundColor3 = TILE
			button.BackgroundTransparency = 0.1
			button.Position = UDim2.fromOffset(x, TOP + HEAD_H + (index - 1) * (TILE_H + GAP))
			button.Size = UDim2.fromOffset(COLUMN_W, TILE_H)
			button.Parent = root
			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Thickness = 2
			stroke.Color = GOLD
			stroke.Transparency = 1
			stroke.Parent = button
			local gun = WeaponConfig.Defs[loadout.gun]
			local shield = WeaponConfig.Shields[loadout.shield]
			Ui.label(button, {
				Text = string.upper(if gun then gun.name else loadout.gun),
				Font = Enum.Font.GothamBold,
				TextSize = 17,
				Position = UDim2.fromOffset(12, 9),
				Size = UDim2.fromOffset(COLUMN_W - 24, 22),
			})
			Ui.label(button, {
				Text = string.upper(if shield then shield.name else "No shield"),
				TextSize = 12,
				TextColor3 = if shield then Ui.NEUTRAL else Ui.DIM,
				Position = UDim2.fromOffset(12, 33),
				Size = UDim2.fromOffset(COLUMN_W - 24, 16),
			})
			local tile: Tile = { stage = stage, index = index, button = button, stroke = stroke }
			button.MouseEnter:Connect(function()
				hovered = tile
			end)
			button.MouseLeave:Connect(function()
				if hovered == tile then
					hovered = nil
				end
			end)
			button.MouseButton1Click:Connect(function()
				LoadoutMenu.pick(stage, index)
			end)
			table.insert(tiles, tile)
		end
	end

	local function setOpen(open: boolean)
		-- Not over the settings menu or the buy menu, which have the cursor.
		open = open and allowed() and (LoadoutMenu.open or not CameraController.cursorFree)
		if open == LoadoutMenu.open then
			return
		end
		LoadoutMenu.open = open
		gui.Enabled = open
		if open or not SettingsMenu.open then
			CameraController.cursorFree = open
			InputSampler.blockMouse = open
		end
		if not open then
			hovered = nil
		end
	end
	LoadoutMenu.setOpen = setOpen

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.B then
			return
		end
		setOpen(not LoadoutMenu.open)
	end)

	RunService.RenderStepped:Connect(function()
		if not LoadoutMenu.open then
			return
		end
		if not allowed() then
			setOpen(false)
			return
		end
		-- Every frame, as agent select does: the cursor stays the menu's
		-- while the settings menu opens and closes over it.
		CameraController.cursorFree = true
		InputSampler.blockMouse = true
		local viewport = Workspace.CurrentCamera.ViewportSize
		scale.Scale = math.min(1, (viewport.X - 40) / width, (viewport.Y - 40) / height)
		local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
		local stage = if arena then arena:GetAttribute("Stage") else nil
		local live = arena ~= nil and arena:GetAttribute("Phase") == "live"
		for n, head in heads do
			local now = live and stage == n
			head.Text = string.format("STAGE %d", n) .. (if now then "   NOW" else "")
			head.TextColor3 = if now then GOLD else Ui.TEXT
		end
		local mine = picks()
		for _, tile in tiles do
			local picked = (mine[tile.stage] or 1) == tile.index
			tile.stroke.Transparency = if picked then 0 else 1
			tile.button.BackgroundColor3 = if tile == hovered or picked then TILE_HOVER else TILE
		end
	end)
end

return LoadoutMenu
