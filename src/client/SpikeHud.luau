--!strict
-- The spike on the HUD (system 12): what you can do with it where you
-- stand ("HOLD 4 TO PLANT", "HOLD 4 TO DEFUSE"), a bar while you plant or
-- defuse it, with the defuse's saved half marked, the spike next to your
-- weapons while you carry it, a light at the top flashing with the planted
-- spike's beeps, and a banner as it's planted, defused or detonates. And an
-- Ultimate Orb (system 49): "HOLD F FOR THE ULTIMATE ORB" within reach of
-- one, and a gold bar while you take it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local Spike = require(Shared.Spike.Spike)
local SpikeSim = require(Shared.Spike.SpikeSim)
local UltimateOrbs = require(Shared.Spike.UltimateOrbs)

local Ui = require(script.Parent.Debug.Ui)
local ClientSpike = require(script.Parent.ClientSpike)
local PlayerController = require(script.Parent.PlayerController)
local SpikeView = require(script.Parent.SpikeView)

local SpikeHud = {}

local DT = 1 / MovementConfig.TickRate.value
local RED = Color3.fromRGB(235, 70, 60)
local CYAN = Color3.fromRGB(90, 220, 230)
local GOLD = Color3.fromRGB(230, 200, 120) -- an Ultimate Orb's (OrbServer)
local ORB_PROMPT = "HOLD F FOR THE ULTIMATE ORB"
local BAR_W = 320
local BANNER_TIME = 2.5 -- seconds a banner stays up (estimate)

function SpikeHud.start()
	local gui = Ui.screen("VFSpikeHud", 15, Enum.ScreenInsets.None)

	local prompt = Ui.label(gui, {
		Size = UDim2.fromOffset(400, 24),
		Position = UDim2.new(0.5, -200, 0.62, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})

	-- The bar, with a mark at the defuse's half.
	local bar = Ui.frame(gui, {
		Size = UDim2.fromOffset(BAR_W, 12),
		Position = UDim2.new(0.5, -BAR_W / 2, 0.62, 28),
		Visible = false,
	})
	local fill = Ui.frame(bar, {
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 0,
		BackgroundColor3 = RED,
	})
	local half = Ui.frame(bar, {
		Size = UDim2.new(0, 2, 1, 6),
		Position = UDim2.new(Spike.Params.defuseHalf.value / Spike.Params.defuseTime.value, -1, 0, -3),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
	})
	local barLabel = Ui.label(bar, {
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 14),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- Carried: the spike, by your weapons.
	local carried = Ui.label(gui, {
		Size = UDim2.fromOffset(160, 20),
		Position = UDim2.new(1, -180, 1, -150),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = RED,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextStrokeTransparency = 0.5,
		Text = "SPIKE  [4]",
		Visible = false,
	})

	-- Planted: a light at the top that flashes as it beeps.
	local planted = Ui.label(gui, {
		Size = UDim2.fromOffset(200, 20),
		Position = UDim2.new(0.5, -100, 0, 74),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})

	local banner = Ui.label(gui, {
		Size = UDim2.fromOffset(600, 44),
		Position = UDim2.new(0.5, -300, 0.22, 0),
		TextSize = 34,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		Visible = false,
	})
	local bannerUntil = 0
	local lastState = ClientSpike.view().state

	RunService.RenderStepped:Connect(function()
		local view = ClientSpike.view()
		local sim: PlayerSim.State? = PlayerController.sim
		local alive = PlayerController.alive and sim ~= nil

		-- A banner as it's planted, defused or goes off; in the spike rounds
		-- the round's end says how it ended instead (ArenaHud).
		if view.state ~= lastState then
			local text, colour = "", Ui.TEXT
			local course = view.layout == "course"
			if view.state == "planted" then
				text, colour = "SPIKE PLANTED", RED
			elseif view.state == "defused" and course then
				text, colour = "SPIKE DEFUSED", CYAN
			elseif view.state == "detonated" and course then
				text, colour = "SPIKE DETONATED", RED
			end
			if text ~= "" then
				banner.Text = text
				banner.TextColor3 = colour
				bannerUntil = os.clock() + BANNER_TIME
			end
			lastState = view.state
		end
		banner.Visible = os.clock() < bannerUntil

		planted.Visible = view.state == "planted"
		planted.Text = if view.site ~= "" then "SPIKE  " .. view.site else "SPIKE"
		planted.TextColor3 = if SpikeView.lit then RED else Color3.fromRGB(120, 50, 46)

		if not alive or not sim then
			prompt.Visible = false
			bar.Visible = false
			carried.Visible = false
			return
		end
		local s = sim :: PlayerSim.State
		local w = s.weapons
		carried.Visible = SpikeSim.carrying(w)

		-- Under way: how far, and for a defuse, where its half is saved.
		local channel = s.spike.channel
		if channel ~= SpikeSim.NONE then
			local t = s.movement.tick * DT
			local f = SpikeSim.fraction(s.spike, t)
			bar.Visible = true
			fill.Size = UDim2.fromScale(f, 1)
			fill.BackgroundColor3 = if channel == SpikeSim.PLANTING then RED elseif channel == SpikeSim.COLLECTING then GOLD else CYAN
			half.Visible = channel == SpikeSim.DEFUSING
			barLabel.Text = if channel == SpikeSim.PLANTING
				then "PLANTING"
				elseif channel == SpikeSim.COLLECTING then "TAKING THE ULTIMATE ORB"
				else (if s.spike.halfStart then "DEFUSING  from the half" else "DEFUSING")
			prompt.Visible = false
			return
		end
		bar.Visible = false

		-- What you could start here.
		local ctx = ClientSpike.context()
		local feet = s.movement.position
		local text = ""
		if SpikeSim.carrying(w) and ctx.canPlant and Spike.siteAt(ctx.zones, feet) then
			text = "HOLD 4 TO PLANT"
		elseif ctx.canDefuse and ctx.planted and not SpikeSim.inHand(w) and Spike.inDefuseRange(feet, ctx.planted) then
			text = if ctx.halfSaved then "HOLD 4 TO DEFUSE  (half saved)" else "HOLD 4 TO DEFUSE"
		elseif ctx.orbs and UltimateOrbs.inReach(ctx.orbs, feet) then
			text = ORB_PROMPT
		end
		prompt.Visible = text ~= ""
		prompt.Text = text
		prompt.TextColor3 = if text == "HOLD 4 TO PLANT" then RED elseif text == ORB_PROMPT then GOLD else CYAN
	end)

	-- Back to nothing to show as a life starts.
	table.insert(PlayerController.spawnListeners, function()
		bar.Visible = false
		prompt.Visible = false
	end)
end

return SpikeHud
