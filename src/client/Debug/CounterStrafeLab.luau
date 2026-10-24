--!strict
-- Counter-Strafe Lab (toggle F4).
--
-- Logs every stop (release vs counter-strafe), shows our averages next to the
-- reference measurements in ReferenceData, and coaches timing: "overhold" is
-- how long the opposite key stayed down after you had already stopped (which
-- starts accelerating you the other way).
--
-- Also hosts the live tuning box (Studio / place owner): type
-- "groundFriction 10" and press Enter; "reset" clears overrides. Changes are
-- applied by the server and pushed to every client so prediction stays in sync.
--
-- And the cm/360 check: F8 zeroes a mouse-count counter. Turn exactly 360
-- degrees and compare counts with the expected value for your sensitivity.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local StopAnalyzer = require(Shared.Movement.StopAnalyzer)

local Ui = require(script.Parent.Ui)
local ReferenceData = require(script.Parent.ReferenceData)
local CameraController = require(script.Parent.Parent.CameraController)

local CounterStrafeLab = {}

local ROWS = 8

type Entry = StopAnalyzer.StopResult & { overhold: number? }

local function compare(ours: number?, ref: any, unit: string, scale: number): string
	if ours == nil then
		return "--"
	end
	local text = string.format("%.0f%s", ours * scale, unit)
	if ref == nil then
		return text .. " (ref: not measured)"
	end
	local delta = (ours - ref.value) * scale
	local color = if math.abs(delta) <= math.max(math.abs(ref.value * scale) * 0.1, 1) then Ui.GOOD else Ui.BAD
	return string.format('%s (ref %.0f%s, <font color="#%s">%+.0f</font>, n=%d)', text, ref.value * scale, unit, Ui.hex(color), delta, ref.n)
end

function CounterStrafeLab.start(controller: any)
	local gui = Ui.screen("VFCounterStrafeLab", 21)
	local panel = Ui.frame(gui, {
		Size = UDim2.fromOffset(520, 372),
		Position = UDim2.new(0, 12, 1, -384),
		Visible = false,
	})
	local body = Ui.label(panel, {
		Size = UDim2.new(1, -16, 1, -48),
		Position = UDim2.fromOffset(8, 6),
	})
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -16, 0, 26)
	box.Position = UDim2.new(0, 8, 1, -34)
	box.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	box.BorderSizePixel = 0
	box.Font = Ui.FONT
	box.TextSize = 14
	box.TextColor3 = Ui.TEXT
	box.PlaceholderText = "tune: <param> <value>   |   reset   (Studio / owner only)"
	box.Text = ""
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = panel

	local analyzer = StopAnalyzer.new(ROWS * 4)
	local overholdFor: Entry? = nil
	local overholdStart = 0
	local overholdDir = vector.create(0, 0, 0)

	analyzer.onStop = function(result)
		local entry = result :: Entry
		overholdFor = nil
		if result.method ~= "release" then
			overholdFor = entry
			entry.overhold = 0
			overholdStart = -1
		end
	end

	table.insert(controller.tickListeners, function(info: any)
		local s = info.state
		local threshold = info.maxSpeed * info.accurateFraction
		analyzer:tick(info.time, s.position, s.velocity, info.wishDir, threshold)

		-- Overhold: time the counter key stays down after the stop completed.
		local entry = overholdFor
		if entry then
			if overholdStart < 0 then
				overholdStart = info.time
				overholdDir = info.wishDir
			end
			if vector.dot(info.wishDir, overholdDir) > 0.5 then
				entry.overhold = info.time - overholdStart
			else
				overholdFor = nil
			end
		end
	end)

	local function render()
		local profile = controller.profile()
		local ref: any = ReferenceData[profile.id] or {}
		local lines = {
			string.format("<b>Counter-Strafe Lab</b>  %s  (deadzone %.1f%% of %.2f m/s)", profile.name, profile.accurateFraction * 100, profile.maxSpeed),
			"",
			"method   to-accurate  to-zero   slide   overhold",
		}
		local history = analyzer.history
		for i = #history, math.max(#history - ROWS + 1, 1), -1 do
			local r = history[i] :: Entry
			local overhold = r.overhold
			local coach = ""
			if overhold ~= nil then
				coach = if overhold > 0.03
					then string.format('<font color="#%s">%3.0fms late</font>', Ui.hex(Ui.BAD), overhold * 1000)
					else string.format('<font color="#%s">clean</font>', Ui.hex(Ui.GOOD))
			end
			table.insert(lines, string.format("%-8s %s    %s   %4.2fm   %s", r.method, Ui.ms(r.timeToAccurate), Ui.ms(r.timeToZero), r.distance, coach))
		end
		for _ = #history, ROWS - 1 do
			table.insert(lines, "")
		end
		local relAcc, relN = analyzer:average("release", "timeToAccurate")
		local cntAcc, cntN = analyzer:average("counter", "timeToAccurate")
		local relSlide = analyzer:average("release", "distance")
		local cntSlide = analyzer:average("counter", "distance")
		table.insert(lines, "")
		table.insert(lines, string.format("<b>release</b> x%d  accurate %s", relN, compare(relAcc, ref.releaseTimeToAccurate, "ms", 1000)))
		table.insert(lines, string.format("          slide %s", compare(relSlide, ref.releaseSlide, "cm", 100)))
		table.insert(lines, string.format("<b>counter</b> x%d  accurate %s", cntN, compare(cntAcc, ref.counterTimeToAccurate, "ms", 1000)))
		table.insert(lines, string.format("          slide %s", compare(cntSlide, ref.counterSlide, "cm", 100)))
		local degPerCount = CameraController.YAW_DEGREES_PER_COUNT * CameraController.sensitivity
		table.insert(lines, "")
		table.insert(lines, string.format(
			"cm/360 check (F8 zero): %.0f counts = %.1f deg   expect %.0f counts per 360",
			math.abs(CameraController.countsX),
			math.abs(CameraController.countsX) * degPerCount,
			360 / degPerCount
		))
		local overrides = {}
		for k, v in controller.overrides do
			table.insert(overrides, string.format("%s=%s", k, tostring(v)))
		end
		table.insert(lines, string.format('<font color="#%s">overrides: %s</font>', Ui.hex(Ui.DIM), if #overrides > 0 then table.concat(overrides, " ") else "none"))
		body.Text = table.concat(lines, "\n")
	end

	box.FocusLost:Connect(function(enter)
		if not enter then
			return
		end
		local text = string.lower(box.Text)
		box.Text = ""
		if text == "reset" then
			controller.requestTuning("__reset", nil)
			return
		end
		local key, value = string.match(text, "^%s*(%S+)%s+(%S+)%s*$")
		-- Param names are camelCase; match case-insensitively.
		if key then
			for name in MovementConfig.Params :: any do
				if string.lower(name) == key then
					controller.requestTuning(name, tonumber(value))
					return
				end
			end
		end
		warn("[Lab] unknown command; try e.g. 'groundFriction 10'")
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F4 then
			panel.Visible = not panel.Visible
		elseif input.KeyCode == Enum.KeyCode.F8 then
			CameraController.countsX = 0
		end
	end)

	task.spawn(function()
		while true do
			if panel.Visible then
				render()
			end
			task.wait(0.1)
		end
	end)
end

return CounterStrafeLab
