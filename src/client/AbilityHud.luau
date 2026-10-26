--!strict
-- The ability bar (system 17), at the bottom between health and ammo, as in
-- the reference: C, Q, E and X, each with its key, its name, and a pip for
-- each charge it can hold, lit for each it has; the ultimate's pips are its
-- points. A readied gust (Tailwind) shows its windup and then the seconds
-- left to dash, and an ability under way lights its slot: Blade Storm's
-- while its knives last (system 19), its note the knives left, and an
-- ability's while it's in hand (Curveball's flare, system 30; Hot Hands'
-- fireball, system 31; Blaze's flame, system 32; the Healing Orb, system
-- 36; the Resurrection's orb, system 39), its note EQUIP until it can be
-- thrown, and Blaze's while its wall's being bent; Run it Back's while it
-- runs, its note the seconds left, and through his return, BACK (system
-- 33); Shrouded Step's through its windup and his time gone, STEP (system
-- 42); and From the Shadows' while its map's in hand, EQUIP until it can
-- be fired and then MAP, through its windup the seconds left, and as a
-- Shade, SHADE (system 43). What can't be played yet is dimmed.
-- It reads the local player's predicted kit (PlayerController.sim), so a
-- cast shows on the tick it's pressed. A kit of no agent's, as deathmatch's
-- (system 26), has no bar. Where abilities recharge over time (Team
-- Deathmatch, system 28, and the Healing Orb's cooldown, system 36), a slot
-- short of a charge counts down the seconds to its next, as the server has
-- them (AbilityConfig.RECHARGE_ATTRIBUTE); and an ultimate that needs more
-- than ten points has ten pips, each a tenth of them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local WeaponSim = require(Shared.Weapons.WeaponSim)

local PlayerController = require(script.Parent.PlayerController)
local Ui = require(script.Parent.Debug.Ui)

local AbilityHud = {}

local DT = 1 / MovementConfig.TickRate.value
local SLOT_W, SLOT_H, GAP = 54, 54, 4
local PIP_H, PIP_GAP = 4, 2
local NAME_W, NAME_H = SLOT_W - 4, 18
local NAME_FONT = Enum.Font.GothamBold
local NAME_SIZES = { 9, 8, 7, 6 }
-- Where the bar's middle is, from the screen's: halfway between CombatHud's
-- health (to 130 px left of the middle) and ammo (from 110 px right).
local CENTRE = -10
local GOLD = Color3.fromRGB(230, 200, 120)
-- The most pips a slot shows.
local MAX_PIPS = 10
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
	-- The name on up to two lines, at the size nameSize picks for it.
	local name = Ui.label(frame, {
		Font = NAME_FONT,
		TextSize = NAME_SIZES[1],
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Position = UDim2.fromOffset(2, 18),
		Size = UDim2.fromOffset(NAME_W, NAME_H),
	})
	local pipRow = Ui.frame(frame, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(5, SLOT_H - PIP_H - 7),
		Size = UDim2.fromOffset(SLOT_W - 10, PIP_H),
	})
	return { frame = frame, stroke = stroke, key = key, name = name, note = note, pipRow = pipRow, pips = {} }
end

-- The largest size at which a name fits its two lines with no word split
-- across them: TextScaled would rather split one ("CLOUDBURS", "T") than go
-- smaller.
local function nameSize(text: string): number
	local free = Vector2.new(1000, 1000)
	for _, size in NAME_SIZES do
		local fits = TextService:GetTextSize(text, size, NAME_FONT, Vector2.new(NAME_W, 1000)).Y <= NAME_H
		for word in string.gmatch(text, "%S+") do
			fits = fits and TextService:GetTextSize(word, size, NAME_FONT, free).X < NAME_W
		end
		if fits then
			return size
		end
	end
	return NAME_SIZES[#NAME_SIZES]
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
		bar.Visible = s ~= nil and s.abilities.agent ~= AbilityConfig.NO_AGENT
		if not s or not bar.Visible then
			return
		end
		local kit = s.abilities
		local t = s.movement.tick * DT
		-- When each of C, Q and E next has a charge back, if they recharge over
		-- time.
		local due = Players.LocalPlayer:GetAttribute(AbilityConfig.RECHARGE_ATTRIBUTE)
		local coming = if typeof(due) == "string" then string.split(due, ",") else {}
		local serverNow = Workspace:GetServerTimeNow()
		for index, slot in slots do
			local def = AbilitySim.def(kit, index)
			local playable = def ~= nil and AbilitySim.playable(def.id)
			local text = if def then string.upper(def.name) else ""
			if slot.name.Text ~= text then
				slot.name.Text = text
				slot.name.TextSize = nameSize(text)
			end
			slot.name.TextColor3 = if playable then Ui.TEXT else Ui.DIM
			slot.frame.BackgroundTransparency = if playable then 0.25 else 0.6
			local lit = false
			local note = ""
			if index == AbilityConfig.X then
				local needed = AbilitySim.pointsNeeded(kit)
				local full = needed > 0 and kit.points >= needed
				local shown = if needed > MAX_PIPS then math.floor(kit.points * MAX_PIPS / needed) else kit.points
				setPips(slot, math.min(needed, MAX_PIPS), shown, if full then GOLD else Ui.TEXT)
				note = if needed > 0 then string.format("%d/%d", kit.points, needed) else ""
				slot.note.TextColor3 = if full then GOLD else Ui.DIM
				if kit.storm then
					lit = true
					note = string.format("x%d", s.weapons.ammo[WeaponSim.ULT])
					slot.note.TextColor3 = LIT
				elseif AbilitySim.runningBack(kit) then
					lit = true
					note = string.format("%.1f", math.max(kit.backUntil - t, 0))
					slot.note.TextColor3 = LIT
				elseif AbilitySim.returning(kit, t) then
					lit = true
					note = "BACK"
					slot.note.TextColor3 = LIT
				elseif kit.holding == index then
					lit = true
					if t < s.weapons.equipEndTime then
						note = "EQUIP"
						slot.note.TextColor3 = Ui.DIM
					elseif def and def.id == "fromtheshadows" then
						note = "MAP"
						slot.note.TextColor3 = LIT
					end
				elseif AbilitySim.gathering(kit, t) then
					lit = true
					note = string.format("%.1f", math.max(kit.shadowAt - t, 0))
					slot.note.TextColor3 = LIT
				elseif AbilitySim.shaded(kit, t) then
					lit = true
					note = "SHADE"
					slot.note.TextColor3 = LIT
				end
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
				elseif def and def.id == "shroudedstep" and AbilitySim.stepping(kit, t) then
					lit = true
					note = "STEP"
				elseif kit.holding == index then
					lit = true
					if t < s.weapons.equipEndTime then
						note = "EQUIP"
						slot.note.TextColor3 = Ui.DIM
					end
				elseif kit.steering == index then
					lit = true
				end
				local at = tonumber(coming[index] or "")
				if note == "" and at and at > serverNow then
					note = string.format("%d", math.ceil(at - serverNow))
					slot.note.TextColor3 = Ui.DIM
				end
			end
			slot.note.Text = note
			slot.stroke.Transparency = if lit then 0 else 1
			slot.stroke.Color = LIT
		end
	end)
end

return AbilityHud
