--!strict
-- Samples held keys into MovementSim button flags. Polled once per tick so the
-- simulation sees exactly what was held at that tick.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementSim = require(ReplicatedStorage:WaitForChild("Shared").Movement.MovementSim)

local B = MovementSim.Buttons

local InputSampler = {}

InputSampler.Bindings = {
	{ flag = B.Forward, keys = { Enum.KeyCode.W } },
	{ flag = B.Back, keys = { Enum.KeyCode.S } },
	{ flag = B.Left, keys = { Enum.KeyCode.A } },
	{ flag = B.Right, keys = { Enum.KeyCode.D } },
	{ flag = B.Walk, keys = { Enum.KeyCode.LeftShift } },
	{ flag = B.Crouch, keys = { Enum.KeyCode.LeftControl, Enum.KeyCode.C } },
	{ flag = B.Jump, keys = { Enum.KeyCode.Space } },
}

function InputSampler.sample(): number
	if UserInputService:GetFocusedTextBox() then
		return 0
	end
	local buttons = 0
	for _, binding in InputSampler.Bindings do
		for _, key in binding.keys do
			if UserInputService:IsKeyDown(key) then
				buttons += binding.flag
				break
			end
		end
	end
	return buttons
end

return InputSampler
