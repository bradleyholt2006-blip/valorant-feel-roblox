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
	{ flag = B.Crouch, keys = { Enum.KeyCode.LeftControl, Enum.KeyCode.C } },
	{ flag = B.Jump, keys = { Enum.KeyCode.Space } },
	{ flag = B.Fire, mouse = { Enum.UserInputType.MouseButton1 } },
	{ flag = B.AltFire, mouse = { Enum.UserInputType.MouseButton2 } },
	{ flag = B.Reload, keys = { Enum.KeyCode.R } },
} :: { Binding }

local latched = 0
local started = false

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
	local buttons = latched
	latched = 0
	for _, binding in InputSampler.Bindings do
		if bit32.band(buttons, binding.flag) ~= 0 then
			continue
		end
		local held = false
		local keys, mouse = binding.keys, binding.mouse
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
	return buttons
end

return InputSampler
