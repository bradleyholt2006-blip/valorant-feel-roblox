--!strict
-- The ability bar (system 17), at the bottom between health and ammo, as in
-- the reference: C, Q, E and X, each with its key, its name, and a pip for
-- each charge it can hold, lit for each it has; the ultimate's pips are its
-- points. A readied gust (Tailwind) shows its windup and then the seconds
-- left to dash, and an ability under way lights its slot. What can't be
-- played yet is dimmed. It reads the local player's predicted kit
-- (PlayerController.sim), so a cast shows on the tick it's pressed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local MovementConfig = require(Shared.Movement.MovementConfig)

local PlayerController = require(script.Parent.PlayerController)
local Ui = require(script.Parent.Debug.Ui)

local AbilityHud = {}

local DT = 1 / MovementConfig.TickRate.value
local SLOT_W, SLOT_H, GAP = 54, 54, 4
local PIP_H, PIP_GAP = 4, 2
-- Where the bar's middle is, from the screen's: halfway between CombatHud's
-- health (to 130 px left of the middle) and ammo (from 110 px right).
local CENTRE = -10
local GOLD = Color3.fromRGB(230, 200, 120)
local LIT = Color3.fromRGB(90, 220, 200)
local EMPTY = Color3.fromRGB(70, 72, 80)

type Slot = { frame: Frame, stroke: UIStroke, key: TextLabel, name: TextLabel, note: TextLabel, pipRow: Frame, pips: { Frame } }

local function newSlot(parent: Frame, index: number): Slot
	local frame = Ui.frame(parent, {
		Size = UDim2.fromOffset(SLOT_W, SLOT_H),
		Position = UDim2.fromOffset((index - 1) * (SLOT_W + GAP), 0),
	})
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = frame
	local key = Ui.label(frame, {
		Text = AbilityConfig.KEYS[index],
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Ui.DIM,
		Position = UDim2.fromOffset(5, 3),
		Size = UDim2.fromOffset(14, 12),
	})
	local note = Ui.label(frame, {
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(18, 4),
		Size = UDim2.fromOffset(SLOT_W - 23, 12),
	})
	-- The name on up to two lines, made smaller if a word is too long for
	-- the slot ("CLOUDBURST").
	local name = Ui.label(frame, {
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Position = UDim2.fromOffset(2, 18),
		Size = UDim2.fromOffset(SLOT_W - 4, 18),
	})
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 9
	fit.MinTextSize = 6
	fit.Parent = name
	local pipRow = Ui.frame(frame, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(5, SLOT_H - PIP_H - 7),
		Size = UDim2.fromOffset(SLOT_W - 10, PIP_H),
	})
	return { frame = frame, stroke = stroke, key = key, name = name, note = note, pipRow = pipRow, pips = {} }
end

-- Sets a slot's pips: `count` of them, the first `lit` lit.
local function setPips(slot: Slot, count: number, lit: number, colour: Color3)
	if #slot.pips ~= count then
		for _, pip in slot.pips do
			pip:Destroy()
		end
		table.clear(slot.pips)
		local width = SLOT_W - 10
		local each = if count > 0 then (width - (count - 1) * PIP_GAP) / count else 0
		for i = 1, count do
			table.insert(
				slot.pips,
				Ui.frame(slot.pipRow, {
					BackgroundTransparency = 0,
					Position = UDim2.fromOffset(math.floor((i - 1) * (each + PIP_GAP) + 0.5), 0),
					Size = UDim2.fromOffset(math.max(math.floor(each + 0.5), 1), PIP_H),
				})
			)
		end
	end
	for i, pip in slot.pips do
		pip.BackgroundColor3 = if i <= lit then colour else EMPTY
	end
end

function AbilityHud.start()
	local gui = Ui.screen("VFAbilityHud", 15, Enum.ScreenInsets.None)
	local width = AbilityConfig.SLOTS * SLOT_W + (AbilityConfig.SLOTS - 1) * GAP
	local bar = Ui.frame(gui, {
		Size = UDim2.fromOffset(width, SLOT_H),
		Position = UDim2.new(0.5, CENTRE - width / 2, 1, -70),
		BackgroundTransparency = 1,
		Visible = false,
	})
	local slots: { Slot } = {}
	for i = 1, AbilityConfig.SLOTS do
		table.insert(slots, newSlot(bar, i))
	end

	RunService.RenderStepped:Connect(function()
		local s = PlayerController.sim
		bar.Visible = s ~= nil
		if not s then
			return
		end
		local kit = s.abilities
		local t = s.movement.tick * DT
		for index, slot in slots do
			local def = AbilitySim.def(kit, index)
			local playable = def ~= nil and AbilitySim.playable(def.id)
			slot.name.Text = if def then string.upper(def.name) else ""
			slot.name.TextColor3 = if playable then Ui.TEXT else Ui.DIM
			slot.frame.BackgroundTransparency = if playable then 0.25 else 0.6
			local lit = false
			local note = ""
			if index == AbilityConfig.X then
				local needed = AbilitySim.pointsNeeded(kit)
				local full = needed > 0 and kit.points >= needed
				setPips(slot, needed, kit.points, if full then GOLD else Ui.TEXT)
				note = if needed > 0 then string.format("%d/%d", kit.points, needed) else ""
				slot.note.TextColor3 = if full then GOLD else Ui.DIM
			else
				setPips(slot, AbilitySim.maxCharges(kit, index), kit.charges[index], Ui.TEXT)
				slot.note.TextColor3 = LIT
				if def and def.id == "tailwind" then
					if AbilitySim.dashing(kit, t) then
						lit = true
					elseif AbilitySim.ready(kit, t) then
						lit = true
						note = string.format("%.1f", math.max(kit.readyUntil - t, 0))
					elseif t < kit.readyUntil then
						note = "WINDUP"
						slot.note.TextColor3 = Ui.DIM
					end
				elseif def and def.id == "updraft" then
					lit = AbilitySim.lifting(kit, t)
				end
			end
			slot.note.Text = note
			slot.stroke.Transparency = if lit then 0 else 1
			slot.stroke.Color = LIT
		end
	end)
end

return AbilityHud
