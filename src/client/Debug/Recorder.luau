--!strict
-- Per-tick recorder (toggle F6). On stop it prints a CSV to the Output window
-- so a run can be pasted into a spreadsheet and overlaid on frame-counted
-- reference data.
--
-- Columns: t (s), buttons (bit flags, see MovementSim.Buttons), x, z (m),
-- vx, vz, speed (m/s), grounded (0/1), accurate (0/1)

local UserInputService = game:GetService("UserInputService")

local Recorder = {}

local MAX_ROWS = 128 * 60 -- one minute

function Recorder.start(controller: any)
	local recording = false
	local rows: { string } = {}
	local startTime: number = 0

	table.insert(controller.tickListeners, function(info: any)
		if not recording then
			return
		end
		if #rows == 0 then
			startTime = info.time
		end
		local s = info.state
		local speed = vector.magnitude(vector.create(s.velocity.x, 0, s.velocity.z))
		local accurate = s.grounded and speed <= info.maxSpeed * info.accurateFraction
		table.insert(rows, string.format(
			"%.5f,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%d,%d",
			info.time - startTime,
			info.input.buttons,
			s.position.x,
			s.position.z,
			s.velocity.x,
			s.velocity.z,
			speed,
			if s.grounded then 1 else 0,
			if accurate then 1 else 0
		))
		if #rows >= MAX_ROWS then
			recording = false
			Recorder.dump(rows)
			rows = {}
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.F6 then
			return
		end
		recording = not recording
		if recording then
			rows = {}
			print("[Recorder] recording... press F6 to stop")
		else
			Recorder.dump(rows)
			rows = {}
		end
	end)
end

function Recorder.dump(rows: { string })
	print(string.format("[Recorder] %d ticks. CSV follows:", #rows))
	print("t,buttons,x,z,vx,vz,speed,grounded,accurate")
	-- Print in chunks; very long single prints get truncated in Output.
	for first = 1, #rows, 200 do
		print(table.concat(rows, "\n", first, math.min(first + 199, #rows)))
	end
	print("[Recorder] end of CSV")
end

return Recorder
