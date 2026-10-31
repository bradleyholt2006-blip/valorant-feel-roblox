--!strict
-- Basic Training on the client (system 72): while the server has you in
-- it (your TrainingConfig.STEP), a panel at the top of the screen shows
-- the step under way, what to do with the buttons named as the input in
-- use has them (the keys, a gamepad's or the touch screen's,
-- TrainingRules.text), how far through it you are, and for a few seconds
-- a note on why something didn't count. It moves down under the spike's
-- light while the spike's planted, and shrinks on a small screen. A marker
-- shows where the step is: a column of light at a spot to reach or over the
-- spike to fetch, wherever it lies and gone while you carry it, a ring
-- under a target. A note given again shows again. A gun the step hands you
-- mid-life is drawn.
-- For scripted checks, PlayerGui's VFTraining carries Step (the step's
-- key, "" with none), Text (what the panel says, its lines apart by " | ")
-- and Note (the note shown, "" with none).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Spike = require(Shared.Spike.Spike)
local TrainingConfig = require(Shared.Training.TrainingConfig)
local TrainingRules = require(Shared.Training.TrainingRules)
local Units = require(Shared.Units)

local InputSampler = require(script.Parent.InputSampler)
local PlayerController = require(script.Parent.PlayerController)
local Ui = require(script.Parent.Debug.Ui)

local GOLD = Color3.fromRGB(240, 200, 90)
local WIDTH, HEIGHT = 540, 118
-- The viewport's height the panel's drawn full size for, and the least it
-- shrinks to on a smaller one, a phone's.
local FULL_AT, SMALLEST = 600, 0.6
-- Pixels the panel moves down while the spike's planted, clear of its light.
local UNDER_LIGHT = 40
-- How see-through a marker's ring and column are.
local RING_CLEAR, COLUMN_CLEAR = 0.35, 0.6

local TrainingView = {}

local function inputKind(): TrainingRules.Input
	if InputSampler.touchActive then
		return "touch"
	elseif InputSampler.padActive then
		return "pad"
	end
	return "keys"
end

-- Puts a marker at `at` (metres, on the floor): a column standing there, or
-- with `ring`, a ring flat on the floor.
local function place(part: BasePart, at: vector, ring: boolean)
	local S = Units.STUDS_PER_METRE
	local height = if ring then 0.03 else 2
	-- A cylinder's length runs along its X: stood on end, upright or flat.
	part.CFrame = CFrame.new(Vector3.new(at.x, at.y + height, at.z) * S) * CFrame.Angles(0, 0, math.rad(90))
end

-- The marker for a step: a column at a spot to reach or fetch, a ring
-- flat on the floor under a target; nil for none.
local function newMarker(step: TrainingConfig.Step): BasePart?
	local at = step.at
	if not at then
		return nil
	end
	local S = Units.STUDS_PER_METRE
	local ring = step.goal == "kill"
	local part = Instance.new("Part")
	part.Name = "VFTrainingMarker"
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = GOLD
	if ring then
		part.Size = Vector3.new(0.04, 1.6, 1.6) * S
		part.Transparency = RING_CLEAR
	else
		part.Size = Vector3.new(4, 0.7, 0.7) * S
		part.Transparency = COLUMN_CLEAR
	end
	place(part, at, ring)
	part.Parent = Workspace
	return part
end

function TrainingView.start()
	local me = Players.LocalPlayer
	local gui = Ui.screen("VFTraining", 13)
	gui:SetAttribute("Step", "")
	gui:SetAttribute("Text", "")
	gui:SetAttribute("Note", "")
	local panel = Ui.frame(gui, {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundTransparency = 0.3,
		Visible = false,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	local header = Ui.label(panel, {
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = GOLD,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 14),
	})
	local title = Ui.label(panel, {
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		Position = UDim2.fromOffset(14, 24),
		Size = UDim2.new(1, -28, 0, 26),
	})
	local body = Ui.label(panel, {
		Font = Enum.Font.Gotham,
		TextSize = 15,
		TextWrapped = true,
		Position = UDim2.fromOffset(14, 52),
		Size = UDim2.new(1, -28, 0, 40),
	})
	local footer = Ui.label(panel, {
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = GOLD,
		Position = UDim2.fromOffset(14, 96),
		Size = UDim2.new(1, -28, 0, 16),
	})

	local marker: BasePart? = nil
	local markedStep: string? = nil
	local noteSeen: string? = nil
	local notedSeen: any = nil
	local noteUntil = 0
	local drawn: string? = nil -- the step and life a gun handed over was drawn in
	local shown = ""

	RunService.RenderStepped:Connect(function()
		local key = me:GetAttribute(TrainingConfig.STEP)
		local index = TrainingRules.indexOf(key)
		local step = if index then TrainingConfig.Steps[index] else nil
		panel.Visible = step ~= nil
		if markedStep ~= (if step then step.key else nil) then
			if marker then
				marker:Destroy()
			end
			marker = if step then newMarker(step) else nil
			markedStep = if step then step.key else nil
		end
		if not step or not index then
			if shown ~= "" then
				shown = ""
				gui:SetAttribute("Step", "")
				gui:SetAttribute("Text", "")
				gui:SetAttribute("Note", "")
			end
			return
		end

		-- A note shows for a while from when it changed, or was given again.
		local note = me:GetAttribute(TrainingConfig.NOTE)
		note = if typeof(note) == "string" then note else ""
		local noted = me:GetAttribute(TrainingConfig.NOTED)
		if note ~= noteSeen or noted ~= notedSeen then
			noteSeen, notedSeen = note, noted
			noteUntil = os.clock() + TrainingConfig.Params.noteFor.value
		end
		local input: TrainingRules.Input = inputKind()
		local noteText = if note ~= "" and os.clock() < noteUntil then TrainingRules.text(note, input) else ""
		local progress = me:GetAttribute(TrainingConfig.PROGRESS)
		progress = if typeof(progress) == "string" then TrainingRules.text(progress, input) else ""

		local count = #TrainingConfig.Steps
		local top = if step.goal == "done" then "BASIC TRAINING COMPLETE" else string.format("BASIC TRAINING  %d / %d", index, count - 1)
		local text = TrainingRules.text(step.text, input)
		local bottom = if noteText ~= "" then noteText else progress
		local all = table.concat({ top, step.title, text, bottom }, " | ")
		if all ~= shown then
			shown = all
			header.Text = top
			title.Text = step.title
			body.Text = text
			footer.Text = bottom
			footer.TextColor3 = if noteText ~= "" then Ui.BAD else GOLD
			gui:SetAttribute("Step", step.key)
			gui:SetAttribute("Text", all)
			gui:SetAttribute("Note", noteText)
		end
		-- The spike to fetch: marked wherever it lies, and not while it's
		-- carried.
		if marker and step.goal == "plant" then
			local carried = Workspace:GetAttribute(Spike.STATE) == "carried"
			local lying = Workspace:GetAttribute(Spike.POSITION)
			marker.Transparency = if carried then 1 else COLUMN_CLEAR
			if not carried and typeof(lying) == "Vector3" then
				place(marker, Units.asVector(lying), false)
			end
		end
		local planted = Workspace:GetAttribute(Spike.STATE) == "planted"
		panel.Position = UDim2.new(0.5, 0, 0, if planted then 8 + UNDER_LIGHT else 8)
		local viewport = Workspace.CurrentCamera.ViewportSize
		scale.Scale = math.clamp(math.min((viewport.X - 40) / WIDTH, viewport.Y / FULL_AT), SMALLEST, 1)

		-- A primary the step hands over is drawn, once in each life.
		local sim = PlayerController.sim
		local primary = if sim then sim.weapons.loadout[1] else nil
		local here = string.format("%s:%d", step.key, PlayerController.life)
		if PlayerController.alive and step.give and primary == step.give and drawn ~= here then
			drawn = here
			PlayerController.selectSlot(1)
		end
	end)
end

return TrainingView
