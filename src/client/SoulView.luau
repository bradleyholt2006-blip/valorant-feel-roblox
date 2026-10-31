--!strict
-- Reyna's Soul Orbs on her client (system 73): her orbs as the server sends
-- them (SoulSim.ATTRIBUTE), drawn where they float, the one in her reach
-- brighter, each fading as its time runs out; and, with one in reach and a
-- charge to take it, the keys that would over the crosshair, named as the
-- input in use has them. It picks the orb in reach each frame from where
-- her predicted eye is, as the server does from its own, and hands it to
-- her ticks (PlayerController.soul). Through her Dismiss the screen
-- darkens, its edges glowing violet.
-- For scripted checks, PlayerGui's VFSouls carries Orbs (how many she
-- has), Reach (the number of the one in reach, -1 with none) and Prompt
-- (what the prompt says, "" with none).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local RobloxSpike = require(Shared.Spike.RobloxSpike)
local SoulSim = require(Shared.Abilities.SoulSim)
local TrainingRules = require(Shared.Training.TrainingRules)
local Units = require(Shared.Units)

local InputSampler = require(script.Parent.InputSampler)
local PlayerController = require(script.Parent.PlayerController)
local Ui = require(script.Parent.Debug.Ui)

local SOUL = Color3.fromRGB(190, 70, 255)
local SIZE, NEAR_SIZE = 0.35, 0.45 -- metres across, and the one in reach
local FADE = 0.6 -- seconds an orb fades over as its time runs out
local TINT = 0.82 -- how see-through the screen's darkening is in Dismiss
local EDGE = 48 -- pixels its glow's stroke is thick, half of it on the screen
-- Pixels above the crosshair the prompt's foot is: clear of what's under
-- it (the reload bar, a kill's banner on a short screen).
local ABOVE = 40
local DT = 1 / MovementConfig.TickRate.value

local SoulView = {}

local function inputKind(): TrainingRules.Input
	if InputSampler.touchActive then
		return "touch"
	elseif InputSampler.padActive then
		return "pad"
	end
	return "keys"
end

local function newOrb(parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = "VFSoulOrb"
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = SOUL
	part.Parent = parent
	return part
end

function SoulView.start()
	local me = Players.LocalPlayer
	local folder = Instance.new("Folder")
	folder.Name = "VFSouls"
	folder.Parent = Workspace
	local gui = Ui.screen("VFSouls", 12, Enum.ScreenInsets.None)
	gui:SetAttribute("Orbs", 0)
	gui:SetAttribute("Reach", -1)
	gui:SetAttribute("Prompt", "")
	local tint = Ui.frame(gui, {
		Name = "Dismiss",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(30, 8, 50),
		BackgroundTransparency = 1,
	})
	-- Its glow: a stroke round a frame set in from the screen's edges by
	-- half its thickness, drawn outwards over them, as one round the
	-- whole screen is drawn off it.
	local edge = Ui.frame(gui, {
		Name = "DismissEdge",
		Size = UDim2.new(1, -EDGE, 1, -EDGE),
		Position = UDim2.fromOffset(EDGE / 2, EDGE / 2),
		BackgroundTransparency = 1,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = SOUL
	stroke.Thickness = EDGE
	stroke.Transparency = 1
	stroke.Parent = edge
	local prompt = Ui.label(gui, {
		Name = "Prompt",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = SOUL,
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.5, -ABOVE),
		Size = UDim2.fromOffset(320, 20),
		Visible = false,
	})

	local orbs: { SoulSim.Orb } = {}
	local parts: { [number]: Part } = {}
	local current: number? = nil
	local function read()
		orbs = SoulSim.decode(me:GetAttribute(SoulSim.ATTRIBUTE))
		local keep: { [number]: boolean } = {}
		for _, orb in orbs do
			keep[orb.id] = true
			if not parts[orb.id] then
				parts[orb.id] = newOrb(folder)
			end
		end
		for id, part in parts do
			if not keep[id] then
				part:Destroy()
				parts[id] = nil
			end
		end
		gui:SetAttribute("Orbs", #orbs)
	end
	me:GetAttributeChangedSignal(SoulSim.ATTRIBUTE):Connect(read)
	read()

	PlayerController.soul = function(): number?
		return current
	end

	RunService.RenderStepped:Connect(function()
		local sim = PlayerController.sim
		local now = Workspace:GetServerTimeNow()
		local eye = if sim and PlayerController.alive then PlayerSim.eye(sim, PlayerController.cfg) else nil
		current = if eye and #orbs > 0 then SoulSim.pick(orbs, eye, now, RobloxSpike.sees) else nil
		gui:SetAttribute("Reach", current or -1)
		for _, orb in orbs do
			local part = parts[orb.id]
			if part then
				local near = orb.id == current
				local left = orb.ends - now
				local fade = math.clamp(1 - left / FADE, 0, 1)
				local pulse = 0.5 + 0.5 * math.sin(os.clock() * 6)
				local across = (if near then NEAR_SIZE else SIZE) * (1 + 0.08 * pulse)
				part.Size = Units.toStuds(vector.create(across, across, across))
				part.CFrame = CFrame.new(Units.toStuds(SoulSim.middle(orb)))
				part.Transparency = math.min((if near then 0 else 0.25) + 0.15 * pulse + fade, 1)
			end
		end

		-- The keys that would take it, for the abilities with a charge.
		local kit = if sim and PlayerController.alive then sim.abilities else nil
		local t = if sim then sim.movement.tick * DT else 0
		local text = ""
		if kit and current and not AbilitySim.dismissing(kit, t) then
			local words = {}
			for _, id in { "devour", "dismiss" } do
				local slot = AbilitySim.slotOf(kit, id)
				local def = if slot then AbilitySim.def(kit, slot) else nil
				if slot and def and kit.charges[slot] > 0 then
					local key = "{" .. string.lower(AbilityConfig.KEYS[slot]) .. "}"
					table.insert(words, key .. " " .. string.upper(def.name))
				end
			end
			text = TrainingRules.text(table.concat(words, "    "), inputKind())
		end
		prompt.Text = text
		prompt.Visible = text ~= ""
		if gui:GetAttribute("Prompt") ~= text then
			gui:SetAttribute("Prompt", text)
		end
		local dismissing = kit ~= nil and AbilitySim.dismissing(kit, t)
		tint.BackgroundTransparency = if dismissing then TINT else 1
		stroke.Transparency = if dismissing then 0.4 else 1
	end)
end

return SoulView
