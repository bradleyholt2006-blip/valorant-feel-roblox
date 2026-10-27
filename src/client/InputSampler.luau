--!strict
-- Samples held keys and mouse buttons into PlayerSim button flags. Polled
-- once per tick so the simulation sees exactly what was held at that tick.
--
-- Ticks run in a burst at the start of each rendered frame, so a click that
-- starts and ends between two frames would never be seen as held. Presses are
-- latched: anything pressed since the last sample counts as held for one
-- tick, which is what makes a fast semi-auto tap always fire.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerSim = require(ReplicatedStorage:WaitForChild("Shared").PlayerSim)

local B = PlayerSim.Buttons

local InputSampler = {}

export type Binding = { flag: number, keys: { Enum.KeyCode }?, mouse: { Enum.UserInputType }? }

InputSampler.Bindings = {
	{ flag = B.Forward, keys = { Enum.KeyCode.W } },
	{ flag = B.Back, keys = { Enum.KeyCode.S } },
	{ flag = B.Left, keys = { Enum.KeyCode.A } },
	{ flag = B.Right, keys = { Enum.KeyCode.D } },
	{ flag = B.Walk, keys = { Enum.KeyCode.LeftShift } },
	-- Crouch is the reference's Left Ctrl; its C is an ability's.
	{ flag = B.Crouch, keys = { Enum.KeyCode.LeftControl } },
	{ flag = B.Jump, keys = { Enum.KeyCode.Space } },
	{ flag = B.Fire, mouse = { Enum.UserInputType.MouseButton1 } },
	{ flag = B.AltFire, mouse = { Enum.UserInputType.MouseButton2 } },
	{ flag = B.Reload, keys = { Enum.KeyCode.R } },
	-- The spike (system 12): 4 is the reference's "Equip Spike" and "Use
	-- Spike" both, held to plant or defuse; G its "Drop Equipped Item".
	{ flag = B.Use, keys = { Enum.KeyCode.Four } },
	{ flag = B.Drop, keys = { Enum.KeyCode.G } },
	-- F, the reference's "Use object" (system 49), held to take an Ultimate
	-- Orb or to defuse; a press of it takes a gun on the ground too
	-- (GroundGunsView).
	{ flag = B.Interact, keys = { Enum.KeyCode.F } },
	-- The ability kit (system 17), on the reference's default keys
	-- (AbilityConfig.KeySources).
	{ flag = B.AbilityC, keys = { Enum.KeyCode.C } },
	{ flag = B.AbilityQ, keys = { Enum.KeyCode.Q } },
	{ flag = B.AbilityE, keys = { Enum.KeyCode.E } },
	{ flag = B.Ultimate, keys = { Enum.KeyCode.X } },
} :: { Binding }

local latched = 0
local started = false

-- The flags any binding puts on a mouse button.
local MOUSE_FLAGS = 0
for _, binding in InputSampler.Bindings do
	if binding.mouse then
		MOUSE_FLAGS = bit32.bor(MOUSE_FLAGS, binding.flag)
	end
end

-- Buttons held on top of the real ones (TestAim's VFTestButtons, Studio only).
InputSampler.extraButtons = 0
-- While set (the buy menu is open), the mouse buttons are the menu's: they
-- neither fire nor zoom.
InputSampler.blockMouse = false
-- Flags never sent, whatever's held: G's in gun game, whose guns can't be
-- dropped (ArenaHud, system 23).
InputSampler.blockButtons = 0

local function flagFor(input: InputObject): number
	for _, binding in InputSampler.Bindings do
		if binding.keys and table.find(binding.keys, input.KeyCode) then
			return binding.flag
		end
		if binding.mouse and table.find(binding.mouse, input.UserInputType) then
			return binding.flag
		end
	end
	return 0
end

function InputSampler.start()
	if started then
		return
	end
	started = true
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed then
			latched = bit32.bor(latched, flagFor(input))
		end
	end)
end

function InputSampler.sample(): number
	if UserInputService:GetFocusedTextBox() then
		latched = 0
		return 0
	end
	local real = latched
	latched = 0
	local blocked = InputSampler.blockMouse
	if blocked then
		real = bit32.band(real, bit32.bnot(MOUSE_FLAGS))
	end
	local buttons = bit32.bor(real, InputSampler.extraButtons)
	for _, binding in InputSampler.Bindings do
		if bit32.band(buttons, binding.flag) ~= 0 then
			continue
		end
		local held = false
		local keys = binding.keys
		local mouse = if blocked then nil else binding.mouse
		if keys then
			for _, key in keys do
				held = held or UserInputService:IsKeyDown(key)
			end
		end
		if mouse then
			for _, button in mouse do
				held = held or UserInputService:IsMouseButtonPressed(button)
			end
		end
		if held then
			buttons = bit32.bor(buttons, binding.flag)
		end
	end
	return bit32.band(buttons, bit32.bnot(InputSampler.blockButtons))
end

return InputSampler
