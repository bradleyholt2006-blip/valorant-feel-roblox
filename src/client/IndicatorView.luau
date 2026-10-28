--!strict
-- Damage and danger indicators on the client (system 54, Indicators), round
-- the crosshair:
--   * a hit you take, or the Owl Drone you're flying takes, shows a red arc
--     on the ring the side it came from, as the server says (the Hurt
--     remote): a bullet's or a blade's from whoever fired or swung, a
--     burst's from where it burst. It goes on pointing at that place as
--     you turn and move, whole and then fading, and a hit from much the
--     same way renews it (Indicators.add)
--   * a fire or a wall of fire that isn't yours (FireView.pools,
--     BlazeView.walls) shows a yellow chevron out past the ring on its side
--     while it's near you, pulsing, and once it reaches you a red diamond
--     under the crosshair, the critical (Indicators.fireThreat and
--     wallThreat)
-- Only the living see them (Patch 1.10: 'Observer player no longer see
-- player-specific hud indicators (e.g. taking damage indicator) when in
-- freecam'), and each life starts with none.
-- For scripted checks, PlayerGui's VFIndicators carries Hurt (the arcs
-- shown, each as where on the ring it is: degrees clockwise from the top,
-- "-90, 180"), LastHurt (where the latest hit's arc is, or would be once
-- it's gone, "" before one this life), Danger (the yellow chevrons, the
-- same way) and Critical (whether the red diamond's up).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Indicators = require(Shared.Combat.Indicators)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local FireView = require(script.Parent.FireView)
local BlazeView = require(script.Parent.BlazeView)
local Ui = require(script.Parent.Debug.Ui)

local IndicatorView = {}

local RED = Color3.fromRGB(255, 60, 60)
local YELLOW = Color3.fromRGB(255, 205, 60)
local RADIUS = 100 -- pixels from the crosshair to a red arc (ours)
local SPAN = 40 -- degrees an arc spans (ours)
local SEGMENTS = 7 -- pieces an arc is drawn with
local OUTER = 132 -- pixels from the crosshair to a chevron's middle (ours)
local CHEVRONS = 6 -- yellow chevrons shown at once at the most
local OPAQUE = 0.9 -- how solid a mark is at its strongest

-- One piece of a mark drawn round the crosshair: `ox`, `oy` pixels from the
-- crosshair as for a mark at the top, turned `bearing` degrees clockwise.
local function place(piece: Frame, ox: number, oy: number, turn: number, bearing: number)
	local r = math.rad(bearing)
	local c, s = math.cos(r), math.sin(r)
	piece.Position = UDim2.fromOffset(ox * c - oy * s, ox * s + oy * c)
	piece.Rotation = turn + bearing
end

-- The camera's yaw (as Indicators.yawOf's) and where it is, metres.
local function view(): (number, vector)
	local cf = Workspace.CurrentCamera.CFrame
	local right = cf.RightVector
	return math.deg(math.atan2(-right.Z, right.X)), Units.toMetres(cf.Position)
end

function IndicatorView.start()
	local gui = Ui.screen("VFIndicators", 16, Enum.ScreenInsets.None)
	local centre = Ui.frame(gui, {
		Size = UDim2.fromOffset(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	})

	-- The red arcs, each in pieces along the ring, thinner to its ends.
	local arcs: { { Frame } } = {}
	for _ = 1, Indicators.Params.most.value do
		local pieces = {}
		for i = 1, SEGMENTS do
			local k = math.abs((i - 1) / (SEGMENTS - 1) * 2 - 1)
			table.insert(
				pieces,
				Ui.frame(centre, {
					Size = UDim2.fromOffset(2 * math.pi * RADIUS * SPAN / 360 / (SEGMENTS - 1) + 2, 6 - 3 * k),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = RED,
					BackgroundTransparency = 1,
				})
			)
		end
		table.insert(arcs, pieces)
	end

	-- The yellow chevrons, each two bars meeting at a point out from the
	-- crosshair.
	local chevrons: { { Frame } } = {}
	for _ = 1, CHEVRONS do
		local bars = {}
		for _ = 1, 2 do
			table.insert(
				bars,
				Ui.frame(centre, {
					Size = UDim2.fromOffset(14, 4),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = YELLOW,
					BackgroundTransparency = 1,
				})
			)
		end
		table.insert(chevrons, bars)
	end

	-- The critical: a red diamond under the crosshair, with its mark.
	local diamond = Ui.frame(centre, {
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(0, 70),
		Rotation = 45,
		BackgroundColor3 = RED,
		Visible = false,
	})
	local bang = Ui.label(centre, {
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(0, 70),
		Text = "!",
		TextSize = 16,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Visible = false,
	})

	local marks: { Indicators.Mark } = {}
	local last: Indicators.Mark? = nil

	local function clear()
		table.clear(marks)
		last = nil
	end
	table.insert(PlayerController.spawnListeners, clear)

	NetSim.on(Remotes.get().Hurt, function(event: any)
		if not PlayerController.alive or typeof(event) ~= "table" then
			return
		end
		local from, at = event.from, event.at
		if typeof(from) ~= "Vector3" or typeof(at) ~= "Vector3" then
			return
		end
		local mark = Indicators.add(marks, { from = Units.toMetres(from), at = Units.toMetres(at), time = os.clock() })
		if mark then
			last = mark
		end
	end)

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local sim = PlayerController.sim
		local alive = PlayerController.alive and sim ~= nil
		if not alive then
			table.clear(marks)
		end
		Indicators.prune(marks, now)
		local yaw, eye = view()

		local shown = {}
		for i, pieces in arcs do
			local mark = marks[i]
			local bearing = if mark then Indicators.bearing(yaw, Indicators.wayTo(mark, eye)) else 0
			local fade = if mark then 1 - Indicators.alpha(now - mark.time) * OPAQUE else 1
			if mark then
				table.insert(shown, bearing)
			end
			for j, piece in pieces do
				local angle = (j - 1) / (SEGMENTS - 1) * SPAN - SPAN / 2
				place(piece, 0, -RADIUS, 0, bearing + angle)
				piece.BackgroundTransparency = fade
			end
		end
		local newest = last
		gui:SetAttribute("Hurt", Indicators.text(shown))
		gui:SetAttribute(
			"LastHurt",
			if newest and alive then Indicators.text({ Indicators.bearing(yaw, Indicators.wayTo(newest, eye)) }) else ""
		)

		-- What's near: the yellow chevrons on their sides, and whether
		-- anything reaches you.
		local danger = {}
		local critical = false
		if alive and sim then
			local feet = sim.movement.position
			local half = PlayerController.cfg.halfWidth
			local mine = PlayerController.entityId
			local threats: { Indicators.Threat } = {}
			for _, f in FireView.pools() do
				local threat = if f.entity ~= mine then Indicators.fireThreat(f.pool, feet, f.t, half) else nil
				if threat then
					table.insert(threats, threat)
				end
			end
			for _, w in BlazeView.walls() do
				local threat = if w.entity ~= mine then Indicators.wallThreat(w.wall, feet, w.t, half) else nil
				if threat then
					table.insert(threats, threat)
				end
			end
			for _, threat in threats do
				if threat.level == "critical" then
					critical = true
				else
					local heading = Indicators.yawOf(threat.to - eye)
					if heading and #danger < CHEVRONS then
						table.insert(danger, Indicators.bearing(yaw, heading))
					end
				end
			end
		end
		local beat = 1 - Indicators.pulse(now) * OPAQUE
		for i, bars in chevrons do
			local bearing = danger[i]
			for j, bar in bars do
				local side = if j == 1 then -1 else 1
				place(bar, side * 5, -OUTER, side * 45, bearing or 0)
				bar.BackgroundTransparency = if bearing then beat else 1
			end
		end
		diamond.Visible = critical
		bang.Visible = critical
		diamond.BackgroundTransparency = beat
		gui:SetAttribute("Danger", Indicators.text(danger))
		gui:SetAttribute("Critical", critical)
	end)
end

return IndicatorView
