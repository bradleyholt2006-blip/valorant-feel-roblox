--!strict
-- Blinds on the client (system 30): Phoenix's Curveball's, as the server
-- keeps each player's (FlareSim.BLIND_ATTRIBUTE, in server time).
--   * Yours, or the blind of the player you're watching (Spectate): the
--     screen white under the HUD, as the reference's flash has 'their
--     vision replaced with an opaque, colored screen' (the VALORANT Wiki's
--     Status Effect page; community), with a brighter core that shrinks as
--     the white runs out, as Patch 5.07's '1P visuals when fully flashed now
--     shrink overtime to give a better indication of when the full flash
--     will end'; then all of it clearing evenly over the fade
--   * Others': a glow in front of the face while their screen is white,
--     and behind the head as it clears, as Patch 5.07's '3P visuals for
--     flashed enemies and allies now render behind the player's head the
--     moment that the flash starts to fade'. The watched player's is on
--     your screen instead
-- In PlayerGui's VFBlind, `White` is the screen and `Core` its core; in
-- Workspace's VFBlinds each glow is a `Blind` ball named for its player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Accuracy = require(Shared.Weapons.Accuracy)
local FlareSim = require(Shared.Abilities.FlareSim)
local Hitboxes = require(Shared.Combat.Hitboxes)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Units = require(Shared.Units)

local RemoteEntities = require(script.Parent.RemoteEntities)
local Spectate = require(script.Parent.Spectate)
local Ui = require(script.Parent.Debug.Ui)

local BlindView = {}

local WARM = Color3.fromRGB(255, 241, 222)
local WHITE = Color3.new(1, 1, 1)
local GLOW = Color3.fromRGB(255, 226, 180)
-- The core's size across, times the screen's longer side, as the white
-- starts and as it runs out (ours).
local CORE_FROM, CORE_TO = 1.5, 0.3
local GLOW_SIZE = 0.24 -- metres across (ours)
local GLOW_AHEAD = 0.2 -- metres in front of the head's centre, or behind it

local me = Players.LocalPlayer
local glows: { [Player]: Part } = {}
local folder: Folder? = nil

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFBlinds"
	made.Parent = Workspace
	folder = made
	return made
end

local function blindOf(player: Instance): FlareSim.Blind?
	return FlareSim.decode(player:GetAttribute(FlareSim.BLIND_ATTRIBUTE))
end

local function glowFor(player: Player): Part
	local had = glows[player]
	if had and had.Parent then
		return had
	end
	local p = Instance.new("Part")
	p.Name = "Blind"
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = GLOW
	p.Size = Vector3.one * GLOW_SIZE * Units.STUDS_PER_METRE
	p:SetAttribute("Player", player.Name)
	p.Parent = holder()
	glows[player] = p
	return p
end

local function dropGlow(player: Player)
	local had = glows[player]
	if had then
		had:Destroy()
		glows[player] = nil
	end
end

-- Another player's glow at render time `now`, where they're drawn, while
-- any of their blind is left.
local function placeGlow(player: Player, now: number)
	local b = blindOf(player)
	local id = PlayerCodec.entityIdForUser(player.UserId)
	local white = if b and id ~= RemoteEntities.viewing then FlareSim.whiteAt(b, now) else 0
	local pose = if b and white > 0 and RemoteEntities.isPresent(id) then RemoteEntities.sample(id, now) else nil
	if not b or not pose or not pose.alive then
		dropGlow(player)
		return
	end
	local head = Hitboxes.region({ position = pose.position, yaw = pose.yaw, crouchAlpha = pose.crouchAlpha }, "head")
	if not head then
		dropGlow(player)
		return
	end
	local ahead = Accuracy.aim(pose.yaw, 0) * (if now < b.full then GLOW_AHEAD else -GLOW_AHEAD)
	local glow = glowFor(player)
	glow.CFrame = CFrame.new(Units.toStuds(head.center + ahead))
	glow.Transparency = 1 - 0.85 * white
end

function BlindView.start()
	local gui = Ui.screen("VFBlind", 2, Enum.ScreenInsets.None)
	local screen = Ui.frame(gui, {
		Name = "White",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WARM,
		Visible = false,
	})
	local core = Ui.frame(screen, {
		Name = "Core",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = WHITE,
	})
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = core

	Players.PlayerRemoving:Connect(dropGlow)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		-- Whose screen this is: yours, or the watched player's, as they're
		-- drawn.
		local watched = Spectate.watching
		local b = blindOf(if watched then watched.holder else me)
		local t = if watched then render else Workspace:GetServerTimeNow()
		local white = if b then FlareSim.whiteAt(b, t) else 0
		screen.Visible = b ~= nil and white > 0
		if b and white > 0 then
			screen.BackgroundTransparency = 1 - white
			core.BackgroundTransparency = 1 - white
			local camera = Workspace.CurrentCamera
			local size = if camera then camera.ViewportSize else Vector2.new(1280, 720)
			local k = math.clamp((t - b.from) / math.max(b.full - b.from, 1e-6), 0, 1)
			local across = math.max(size.X, size.Y) * (CORE_FROM + (CORE_TO - CORE_FROM) * k)
			core.Size = UDim2.fromOffset(across, across)
		end

		for _, player in Players:GetPlayers() do
			if player ~= me then
				placeGlow(player, render)
			end
		end
	end)
end

return BlindView
