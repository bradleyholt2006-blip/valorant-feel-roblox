--!strict
-- Oscilloscope-style plot of horizontal speed, one column per tick (2.5 s at
-- 128 Hz). Green = inside the accuracy deadzone, red = moving error, blue =
-- no movement keys held. The white line is the deadzone threshold.
-- Updates one column per tick, so it costs almost nothing.

local Ui = require(script.Parent.Ui)

local SpeedGraph = {}

local COLUMNS = 320
local HEIGHT = 110
local MAX_SPEED = 7 -- m/s at the top of the graph

function SpeedGraph.start(controller: any)
	local gui = Ui.screen("VFSpeedGraph", 20)
	local panel = Ui.frame(gui, {
		Size = UDim2.fromOffset(COLUMNS + 16, HEIGHT + 34),
		Position = UDim2.new(1, -(COLUMNS + 28), 0, 12),
	})
	local title = Ui.label(panel, {
		Size = UDim2.new(1, -16, 0, 18),
		Position = UDim2.fromOffset(8, 4),
		Text = "speed (m/s), 2.5 s",
	})
	local plot = Ui.frame(panel, {
		Size = UDim2.fromOffset(COLUMNS, HEIGHT),
		Position = UDim2.fromOffset(8, 24),
		BackgroundTransparency = 0.6,
		ClipsDescendants = true,
	})
	local columns = table.create(COLUMNS)
	for i = 1, COLUMNS do
		columns[i] = Ui.frame(plot, {
			Size = UDim2.fromOffset(1, 0),
			Position = UDim2.new(0, i - 1, 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 0,
		})
	end
	local thresholdLine = Ui.frame(plot, {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Ui.TEXT,
		BackgroundTransparency = 0.3,
		ZIndex = 2,
	})
	local cursor = Ui.frame(plot, {
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Ui.TEXT,
		BackgroundTransparency = 0.5,
		ZIndex = 3,
	})

	local index = 0
	table.insert(controller.tickListeners, function(info: any)
		index = index % COLUMNS + 1
		local speed = vector.magnitude(vector.create(info.state.velocity.x, 0, info.state.velocity.z))
		local threshold = info.maxSpeed * info.accurateFraction
		local col = columns[index]
		col.Size = UDim2.fromOffset(1, math.floor(math.clamp(speed / MAX_SPEED, 0, 1) * HEIGHT + 0.5))
		local noInput = vector.magnitude(info.wishDir) < 0.5
		col.BackgroundColor3 = if speed <= threshold and info.state.grounded
			then Ui.GOOD
			elseif noInput then Ui.NEUTRAL
			else Ui.BAD
		cursor.Position = UDim2.fromOffset(index, 0)
		thresholdLine.Position = UDim2.new(0, 0, 1, -math.floor(threshold / MAX_SPEED * HEIGHT))
		title.Text = string.format("speed %.2f m/s  (max %.2f, deadzone %.2f)", speed, info.maxSpeed, threshold)
	end)

	return gui
end

return SpeedGraph
