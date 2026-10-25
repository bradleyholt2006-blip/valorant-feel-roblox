--!strict
-- Sound Lab (F2, fourth page): what the sound system (system 8) is doing and
-- why, next to the reference's rules.
--
--   * the rules in force: how far footsteps carry (this client's radius),
--     and what is never heard
--   * your noise right now: whether your steps can be heard, and from how
--     far, like the reference's minimap circle
--   * each bus's level (others in the world, your own, the hit sounds) and
--     the loudest it got lately, how many voices are playing, and how many
--     sounds are still loading. VFTestMute on the local player mutes the
--     output, and the meters still read
--   * the last sounds: what, whose, how far, how much wall was in the way and
--     the filter that made, how loud it is where you stand, or why it wasn't
--     heard (out of range, the other side in the buy phase)
--   * rings on the floor, while the page is open: each sound in the world
--     draws its range around where it was made, and each of your running
--     steps draws yours
--
-- Keys while the page is open: [ and ] footstep radius -/+2 m (this client
-- only), Y practice dummies' steps on/off, H rings on/off. Backspace clears
-- the log.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundConfig = require(Shared.Audio.SoundConfig)
local SoundMath = require(Shared.Audio.SoundMath)
local StepTracker = require(Shared.Audio.StepTracker)
local Units = require(Shared.Units)

local Ui = require(script.Parent.Ui)
local SoundEngine = require(script.Parent.Parent.Audio.SoundEngine)
local GameSounds = require(script.Parent.Parent.Audio.GameSounds)

local RADIUS_STEP = 2
local MIN_RADIUS, MAX_RADIUS = 4, 60
local RING_TIME = 0.6 -- seconds a ring takes to fade
local RING_WIDTH = 0.08 -- metres

local SoundLab = {}

local panelFrame: Frame? = nil

function SoundLab.setVisible(visible: boolean)
	local p = panelFrame
	if p then
		p.Visible = visible
	end
end

local function dim(text: string): string
	return string.format('<font color="#%s">%s</font>', Ui.hex(Ui.DIM), text)
end

local function colored(color: Color3, text: string): string
	return string.format('<font color="#%s">%s</font>', Ui.hex(color), text)
end

-- A level as a bar of ten blocks, and its number.
local function meter(level: number): string
	local n = math.clamp(math.round(level * 10), 0, 10)
	return string.rep("#", n) .. dim(string.rep(".", 10 - n)) .. string.format(" %.2f", level)
end

function SoundLab.start(controller: any)
	local gui = Ui.screen("VFSoundLab", 22)
	local panel = Ui.frame(gui, {
		Size = UDim2.fromOffset(660, 520),
		Position = UDim2.new(1, -672, 0, 120),
		Visible = false,
	})
	panelFrame = panel
	local body = Ui.label(panel, {
		Size = UDim2.new(1, -16, 1, -12),
		Position = UDim2.fromOffset(8, 6),
		TextSize = 13,
	})

	-- Rings -----------------------------------------------------------------------
	local ringsOn = true
	local ringFolder = Instance.new("Folder")
	ringFolder.Name = "VFSoundRings"
	ringFolder.Parent = Workspace
	type Ring = { adornment: CylinderHandleAdornment, born: number }
	local rings: { Ring } = {}

	local function ring(at: vector, radius: number, color: Color3)
		local r = Instance.new("CylinderHandleAdornment")
		r.Adornee = Workspace.Terrain
		-- A cylinder adornment runs along its Z axis: turned to stand on Y.
		r.CFrame = CFrame.new(Units.toStuds(at + vector.create(0, 0.02, 0))) * CFrame.Angles(math.rad(90), 0, 0)
		r.Radius = radius * Units.STUDS_PER_METRE
		r.InnerRadius = math.max(radius - RING_WIDTH, 0) * Units.STUDS_PER_METRE
		r.Height = 0.02 * Units.STUDS_PER_METRE
		r.Color3 = color
		r.Transparency = 0.2
		r.AlwaysOnTop = false
		r.ZIndex = 0
		r.Parent = ringFolder
		table.insert(rings, { adornment = r, born = os.clock() })
	end

	-- Steps and landings only: they are the sounds with a range worth seeing.
	table.insert(GameSounds.entryListeners, function(entry: GameSounds.Entry)
		if not panel.Visible or not ringsOn or (entry.sound ~= "step" and entry.sound ~= "land") then
			return
		end
		if entry.who == "you" then
			local s = controller.sim
			if s then
				ring(s.movement.position, GameSounds.settings.footstepRadius, Color3.new(1, 1, 1))
			end
			return
		end
		local at = entry.position
		local curve = SoundEngine.curveOf(entry.sound)
		local radius = if curve then SoundMath.radius(curve) else nil
		if at and radius then
			ring(at - GameSounds.FEET, radius, if entry.note == nil then Ui.NEUTRAL else Ui.DIM)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for i = #rings, 1, -1 do
			local r = rings[i]
			local t = (now - r.born) / RING_TIME
			if t >= 1 then
				r.adornment:Destroy()
				table.remove(rings, i)
			else
				r.adornment.Transparency = 0.2 + 0.8 * t
			end
		end
	end)

	-- Page ------------------------------------------------------------------------
	local function render()
		local lines = {}
		local radius = GameSounds.settings.footstepRadius
		local reference = SoundConfig.Footsteps.radius.value
		table.insert(lines, string.format(
			"<b>Sound Lab</b>  footsteps heard within %s m%s",
			colored(Ui.NEUTRAL, string.format("%.0f", radius)),
			if radius ~= reference then dim(string.format("  (default %.0f m, an estimate)", reference)) else dim("  (an estimate)")
		))
		table.insert(lines, dim("a flat curve, cut at the radius (Riot: 'somewhat flat'); never heard: walking, crouching, jumps, draws, aiming"))
		table.insert(lines, "")

		-- Your noise ------------------------------------------------------------
		local s = controller.sim
		local noise = "--"
		if s and controller.alive then
			local m = s.movement
			local quiet = StepTracker.isQuiet(controller.buttons, m.crouched)
			local speed = math.sqrt(m.velocity.x ^ 2 + m.velocity.z ^ 2)
			if not m.grounded then
				noise = "in the air: a landing on your level or lower is heard, one up on a crate isn't"
			elseif quiet then
				noise = colored(Ui.GOOD, "silent") .. dim(" (walking or crouching)")
			elseif speed > 0.1 then
				noise = colored(Ui.BAD, string.format("heard within %.0f m", radius)) .. dim(string.format("  running %.2f m/s", speed))
			else
				noise = colored(Ui.GOOD, "silent") .. dim(" (standing)")
			end
		end
		table.insert(lines, "<b>your steps</b>  " .. noise)
		table.insert(lines, "")

		-- Buses --------------------------------------------------------------------
		table.insert(lines, "<b>output</b>" .. (if SoundEngine.isMuted() then "  " .. colored(Ui.BAD, "MUTED (VFTestMute)") else ""))
		local levels = SoundEngine.levels()
		for _, bus in SoundEngine.BUSES do
			local level = levels[bus]
			if level then
				table.insert(lines, string.format(
					"  %-6s %s  %s",
					bus,
					meter(level.peak),
					dim(string.format("peak in the last 2 s %.2f, rms %.3f", level.held, level.rms))
				))
			end
		end
		local waiting, total = SoundEngine.loading()
		table.insert(lines, string.format(
			"  voices playing %d, loaded %d of %d%s",
			SoundEngine.playing(),
			total - waiting,
			total,
			if waiting > 0 then "  " .. colored(Ui.BAD, string.format("(%d still loading)", waiting)) else ""
		))
		local c = GameSounds.counts
		table.insert(lines, dim(string.format("  played: yours %d, in the world %d, hits %d; not heard %d", c.own, c.world, c.ui, c.muted)))
		table.insert(lines, "")

		-- Log ---------------------------------------------------------------------
		table.insert(lines, "<b>last sounds</b>  " .. dim("newest first"))
		local now = os.clock()
		local log = GameSounds.log
		for i = #log, 1, -1 do
			local e = log[i]
			local ago = string.format("%5.1fs", now - e.at)
			if e.note then
				table.insert(lines, string.format(
					"  %s  %-12s %-14s %s  %s",
					ago,
					e.sound,
					string.sub(e.who, 1, 14),
					if e.distance then string.format("%5.1f m", e.distance) else "       ",
					colored(Ui.DIM, "not heard: " .. e.note)
				))
			elseif e.distance then
				local voice = e.voice
				local audible = if voice and voice.player.IsPlaying then SoundEngine.audibility(voice) else nil
				local walls = e.walls or 0
				table.insert(lines, string.format(
					"  %s  %-12s %-14s %5.1f m  %s  %s",
					ago,
					e.sound,
					string.sub(e.who, 1, 14),
					e.distance,
					if walls > 0
						then colored(Ui.BAD, string.format("walls %.2f m, %4.0f Hz x%.2f", walls, e.cutoff or 0, e.gain or 1))
						elseif (e.cutoff or SoundConfig.OPEN_CUTOFF) < SoundConfig.OPEN_CUTOFF then string.format("air %4.0f Hz", e.cutoff or 0)
						else dim("open"),
					if audible then string.format("level %.2f", audible) else ""
				))
			else
				table.insert(lines, string.format("  %s  %-12s %s", ago, e.sound, dim("yours")))
			end
		end
		table.insert(lines, "")
		table.insert(lines, dim(string.format(
			"[ ] footstep radius -/+%d m (this client)   Y dummies' steps %s   H rings %s",
			RADIUS_STEP,
			if GameSounds.settings.dummySteps then "on" else "off",
			if ringsOn then "on" else "off"
		)))
		table.insert(lines, dim("Backspace clear   F2 next page"))
		body.Text = table.concat(lines, "\n")
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not panel.Visible then
			return
		end
		local key = input.KeyCode
		local radius = GameSounds.settings.footstepRadius
		if key == Enum.KeyCode.LeftBracket then
			GameSounds.setFootstepRadius(math.max(radius - RADIUS_STEP, MIN_RADIUS))
		elseif key == Enum.KeyCode.RightBracket then
			GameSounds.setFootstepRadius(math.min(radius + RADIUS_STEP, MAX_RADIUS))
		elseif key == Enum.KeyCode.Y then
			GameSounds.settings.dummySteps = not GameSounds.settings.dummySteps
		elseif key == Enum.KeyCode.H then
			ringsOn = not ringsOn
		elseif key == Enum.KeyCode.Backspace then
			table.clear(GameSounds.log)
			local c = GameSounds.counts
			c.own, c.world, c.ui, c.muted = 0, 0, 0, 0
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

return SoundLab
