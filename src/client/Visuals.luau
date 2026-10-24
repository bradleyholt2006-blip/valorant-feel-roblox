--!strict
-- The look (system 6), on this client: a lighting preset over the place's
-- own lighting, colour grading and bloom, a vignette, and the friend-or-foe
-- outline on other players and dummies. It's on from the start. V turns it
-- all off, putting the place's own values back exactly, and on again, to
-- compare. N cycles the enemy colour through the reference's accessibility
-- options.
--
-- The reference's maps are lit offline (Unreal's Lightmass) and its
-- characters have shaders of their own (VALORANT Shaders and Gameplay
-- Clarity, Riot), which Roblox can't copy. What Riot says the look aims for
-- carries over: shade that's never too dark, values close together, no haze
-- hiding a player, and a red fresnel on enemies and a blue one on allies
-- that grows with distance. A Highlight stands in for the fresnel: an
-- outline and a tint in the side's colour. docs/research/06-visuals.md has
-- the sources and what each number is.
--
-- Lighting's LightingStyle and PrioritizeLightingQuality can't be set from a
-- script; they're set in Studio (see the doc).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VisualConfig = require(Shared.Visuals.VisualConfig)
local VisualMath = require(Shared.Visuals.VisualMath)
local Units = require(Shared.Units)

local Ui = require(script.Parent.Debug.Ui)

local Visuals = {}

-- Whether the look is on, and the enemy colour (an index into
-- VisualConfig.EnemyColours).
Visuals.on = false
Visuals.enemyColour = 1

local L = VisualConfig.Lighting
local O = VisualConfig.Outline

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

-- What the preset sets on Lighting.
local PRESET: { [string]: any } = {
	Brightness = L.brightness.value,
	Ambient = color3(L.ambient),
	OutdoorAmbient = color3(L.outdoorAmbient),
	EnvironmentDiffuseScale = L.environmentDiffuse.value,
	EnvironmentSpecularScale = L.environmentSpecular.value,
	ShadowSoftness = L.shadowSoftness.value,
	ExposureCompensation = L.exposure.value,
}

-- The place's own effects of these kinds are switched off while ours run.
local REPLACED: { [string]: boolean } = { ColorCorrectionEffect = true, BloomEffect = true, DepthOfFieldEffect = true }

local lighting = Lighting :: any

-- The place's own values while ours are on, to put back.
local saved: { [string]: any } = {}
local savedHaze: { atmosphere: Atmosphere, density: number }? = nil
local switchedOff: { PostEffect } = {}

local colour = Instance.new("ColorCorrectionEffect")
colour.Name = "VFColour"
colour.Contrast = VisualConfig.Colour.contrast.value
colour.Saturation = VisualConfig.Colour.saturation.value
colour.Brightness = VisualConfig.Colour.brightness.value

local bloom = Instance.new("BloomEffect")
bloom.Name = "VFBloom"
bloom.Intensity = VisualConfig.Bloom.intensity.value
bloom.Size = VisualConfig.Bloom.size.value
bloom.Threshold = VisualConfig.Bloom.threshold.value

local vignette: ScreenGui? = nil
local outlines: { [Model]: Highlight } = {}
local playerFolder: Instance? = nil

-- Two black layers over the view and under the HUD, one darkening the sides
-- and one the top and bottom, each through a transparency gradient: Roblox
-- has no vignette effect, and radial gradients are still a Studio beta.
local function makeVignette(): ScreenGui
	local gui = Ui.screen("VFVignette", 0, Enum.ScreenInsets.None)
	local cfg = VisualConfig.Vignette
	local keypoints = {}
	for _, k in VisualMath.vignetteKeypoints(cfg.start.value, cfg.strength.value) do
		table.insert(keypoints, NumberSequenceKeypoint.new(k.time, k.value))
	end
	local transparency = NumberSequence.new(keypoints)
	for _, rotation in { 0, 90 } do
		local layer = Ui.frame(gui, {
			Name = if rotation == 0 then "Sides" else "TopAndBottom",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0,
			Interactable = false,
		})
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = rotation
		gradient.Transparency = transparency
		gradient.Parent = layer
	end
	return gui
end

-- An outline for a dummy or another player, drawn only where the model can
-- be seen: the reference's fresnel never shows through walls.
local function outline(model: Model)
	if outlines[model] then
		return
	end
	local h = Instance.new("Highlight")
	h.Name = "VFOutline"
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.FillTransparency = 1
	h.OutlineTransparency = 1
	h.Enabled = Visuals.on
	h.Adornee = model
	h.Parent = model
	outlines[model] = h
	model.Destroying:Connect(function()
		outlines[model] = nil
	end)
end

-- Another player on our team. Dummies, and everyone while there are no
-- teams, are enemies.
local function isAlly(model: Model): boolean
	if model.Parent ~= playerFolder then
		return false
	end
	local me = Players.LocalPlayer
	local other = Players:FindFirstChild(model.Name)
	return other ~= nil and other:IsA("Player") and not other.Neutral and not me.Neutral and me.Team ~= nil and other.Team == me.Team
end

-- Where a model is, for its distance: our blocks' body, or a model's
-- primary part.
local function centreOf(model: Model): Vector3?
	local body = model:FindFirstChild("body")
	if body and body:IsA("BasePart") then
		return body.Position
	end
	local primary = model.PrimaryPart
	return if primary then primary.Position else nil
end

local function update()
	if not Visuals.on then
		return
	end
	local eye = Workspace.CurrentCamera.CFrame.Position
	local enemy = color3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
	local ally = color3(VisualConfig.allyColour)
	for model, h in outlines do
		if model.Parent == nil then
			continue
		end
		local centre = centreOf(model)
		local distance = if centre then (centre - eye).Magnitude * Units.METRES_PER_STUD else 0
		if isAlly(model) then
			h.OutlineColor, h.FillColor = ally, ally
			h.OutlineTransparency = O.allyOutline.value
			h.FillTransparency = VisualMath.fillTransparency(distance, O.allyFillNear.value, O.allyFillFar.value, O.nearDistance.value, O.farDistance.value)
		else
			h.OutlineColor, h.FillColor = enemy, enemy
			h.OutlineTransparency = O.outline.value
			h.FillTransparency = VisualMath.fillTransparency(distance, O.fillNear.value, O.fillFar.value, O.nearDistance.value, O.farDistance.value)
		end
	end
end

-- Turns the look on or off. Off puts back exactly what the place had.
function Visuals.setOn(on: boolean)
	if on == Visuals.on then
		return
	end
	Visuals.on = on
	if on then
		for name, value in PRESET do
			saved[name] = lighting[name]
			lighting[name] = value
		end
		local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmosphere and atmosphere.Density > L.maxHaze.value then
			savedHaze = { atmosphere = atmosphere, density = atmosphere.Density }
			atmosphere.Density = L.maxHaze.value
		end
		for _, child in Lighting:GetChildren() do
			if child:IsA("PostEffect") and REPLACED[child.ClassName] and child.Enabled then
				child.Enabled = false
				table.insert(switchedOff, child)
			end
		end
		colour.Parent = Lighting
		bloom.Parent = Lighting
	else
		for name, value in saved do
			lighting[name] = value
		end
		table.clear(saved)
		local haze = savedHaze
		if haze then
			haze.atmosphere.Density = haze.density
			savedHaze = nil
		end
		for _, effect in switchedOff do
			effect.Enabled = true
		end
		table.clear(switchedOff)
		colour.Parent = nil
		bloom.Parent = nil
	end
	if vignette then
		vignette.Enabled = on
	end
	for _, h in outlines do
		h.Enabled = on
	end
end

function Visuals.enemyColourName(): string
	return VisualConfig.EnemyColours[Visuals.enemyColour].name
end

function Visuals.start()
	local gui = makeVignette()
	gui.Enabled = false
	vignette = gui
	local dummies = Workspace:WaitForChild("VFDummies")
	local players = Workspace:WaitForChild("VFPlayers")
	playerFolder = players
	for _, folder in { dummies, players } do
		folder.ChildAdded:Connect(function(child)
			if child:IsA("Model") then
				outline(child)
			end
		end)
		for _, child in folder:GetChildren() do
			if child:IsA("Model") then
				outline(child)
			end
		end
	end
	Visuals.setOn(true)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.V then
			Visuals.setOn(not Visuals.on)
		elseif input.KeyCode == Enum.KeyCode.N then
			Visuals.enemyColour = Visuals.enemyColour % #VisualConfig.EnemyColours + 1
		end
	end)
	-- After remote entities are placed for the frame (Camera + 2).
	RunService:BindToRenderStep("VFVisuals", Enum.RenderPriority.Camera.Value + 3, update)
end

return Visuals
