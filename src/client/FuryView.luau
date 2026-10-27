--!strict
-- Sova's Hunter's Fury on the client (system 46): its bow's time and its
-- blasts' windups, your view slowed while one charges, the blasts, whom
-- they reveal, and the flash of being caught by one.
--   * its bow in hand shows under the crosshair a bar for the time it has
--     left, emptying as it runs, and under it a second, filling through a
--     blast's windup to when it goes; the blasts left are the ammo the HUD
--     shows (CombatHud; Patch 4.08: 'Hunter's Fury will now show how much
--     ammo they have left when equipped')
--   * through a blast's windup your view turns at the windup's share of
--     its usual speed (CameraController.turnScale)
--   * a blast is a band of light as wide as it reaches either side, from
--     where it went along its way as far as its range, through walls,
--     flashing and fading out, in your side's colour or the enemies'
--     (Patch 0.50: 'Added foe coloring for Sova's Hunter's Fury'). Yours
--     shows at once, as it goes in your tick (PlayerController's
--     castListeners), from your bow under your eye; others' come from the
--     server (the Ability remote's "blast") as the frame on your screen
--     reaches them
--   * a blast of someone else's charging (the Ability remote's "charge")
--     is a ball of light growing at their bow through its windup
--   * whom a blast of your side's revealed, the server tells your side
--     with it, and their silhouettes show for the reveal's time
--     (ReconView.reveal)
--   * caught by a blast, your screen flashes for a moment (ours, for Patch
--     9.04's 'minimum blind effect on opponents when the damage lands')
-- Its sounds are its casts' (AbilityEffects). In Workspace's VFFury each
-- blast is a `Blast` part and each charge a `Charge` ball; they all go
-- when the server says every fire's out (a new round, "out"). The `VFFury`
-- gui's attributes say whether its bow's in hand (`Bow`), the seconds it
-- has left (`Left`), whether a blast is charging (`Charging`), how fast
-- the view turns (`Turn`, a share of its usual) and the blasts drawn
-- (`Blasts`), which scripted checks read. Where a blast would go is the
-- minimap's too (FuryView.aimed, MinimapView).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local FurySim = require(Shared.Abilities.FurySim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local Hitboxes = require(Shared.Combat.Hitboxes)
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local CameraController = require(script.Parent.CameraController)
local ReconView = require(script.Parent.ReconView)
local Visuals = require(script.Parent.Visuals)
local Ui = require(script.Parent.Debug.Ui)

local FuryView = {}

local HF = AbilityConfig.HuntersFury
local DT = 1 / MovementConfig.TickRate.value
local S = Units.STUDS_PER_METRE
local LIGHT = Color3.fromRGB(80, 235, 255)
local DIM = Color3.fromRGB(70, 72, 80)
local CORE = 0.15 -- metres across a blast's bright middle (ours)
local FADE = 0.6 -- seconds a blast takes to flash and fade out (ours)
local FLASH = 0.3 -- seconds your screen's flash takes to fade, caught by one (ours)
local BOW = vector.create(0, -0.25, 0) -- from your eye to where your blasts are drawn from, metres (ours)
local CHEST = 1.3 -- metres above the feet a charge's ball is drawn at
local AHEAD = 0.5 -- metres in front of them
local GROW = 0.5 -- metres across a charge's ball as its windup ends (ours)
local STALE = 1 -- seconds: a blast or a charge the screen is this far past isn't shown
local BAR_W, BAR_H, BAR_GAP = 80, 4, 4 -- pixels
local BELOW = 30 -- pixels under the crosshair

-- A blast or a charge the server told of, until the frame on your screen
-- reaches it: whose, and for a blast where it went from, the way it went,
-- and whom it revealed to your side, with where the server said they
-- stood.
type Due = {
	kind: string,
	at: number,
	entity: number,
	origin: vector,
	direction: vector,
	ids: { number },
	poses: { [number]: Hitboxes.Pose },
}

-- A blast drawn: its part, its two bands, and when it went (os.clock()).
type Shown = { part: Part, bands: { Beam }, start: number }

-- Someone's blast charging: its ball, and when its windup started (the
-- render clock).
type Charge = { part: Part, start: number }

local folder: Folder? = nil
local due: { Due } = {}
local shown: { Shown } = {}
local charges: { [number]: Charge } = {}
local flashUntil = 0

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFFury"
	made.Parent = Workspace
	folder = made
	return made
end

local function plain(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

local function colour(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

-- Whether `entity` is you or on your side.
local function friendly(entity: number): boolean
	if entity == PlayerController.entityId then
		return true
	end
	local side = Players.LocalPlayer:GetAttribute(ArenaConfig.SIDE)
	if side == nil then
		return false
	end
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == entity then
			return player:GetAttribute(ArenaConfig.SIDE) == side
		end
	end
	return false
end

-- A blast of `entity`'s: your side's colour, or the enemies'.
local function tint(entity: number): Color3
	if friendly(entity) then
		return colour(VisualConfig.allyColour)
	end
	local option = VisualConfig.EnemyColours[Visuals.enemyColour] or VisualConfig.EnemyColours[1]
	return colour(option.colour)
end

-- A blast from `from` to `to` in `light`: a band as wide as it reaches
-- either side, and a bright one down its middle, both turned to face you.
local function blast(from: vector, to: vector, light: Color3)
	local p = Instance.new("Part")
	p.Name = "Blast"
	plain(p)
	p.Transparency = 1
	p.Size = Vector3.one * 0.2
	p.CFrame = CFrame.new(Units.toStuds(from))
	local a0 = Instance.new("Attachment")
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Units.toStuds(to - from)
	a1.Parent = p
	local bands: { Beam } = {}
	for _, width in { 2 * HF.radius.value, CORE } do
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.FaceCamera = true
		b.Segments = 1
		b.Width0 = width * S
		b.Width1 = width * S
		b.Color = ColorSequence.new(light)
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Parent = p
		table.insert(bands, b)
	end
	p.Parent = holder()
	table.insert(shown, { part = p, bands = bands, start = os.clock() })
end

local function onOwnCast(cast: AbilitySim.Cast)
	if cast.ability ~= "huntersfury" or cast.kind ~= "blast" then
		return
	end
	blast(cast.origin + BOW, cast.origin + cast.direction * HF.range.value, tint(PlayerController.entityId))
end

local function onEvent(event: any)
	if typeof(event) == "table" and event.kind == "out" then
		for _, s in shown do
			s.part:Destroy()
		end
		table.clear(shown)
		for id, c in charges do
			c.part:Destroy()
			charges[id] = nil
		end
		table.clear(due)
		return
	end
	if typeof(event) ~= "table" or event.ability ~= "huntersfury" or (event.kind ~= "blast" and event.kind ~= "charge") then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	if event.kind == "charge" then
		-- Yours shows under your crosshair.
		if event.entity ~= PlayerController.entityId then
			table.insert(due, {
				kind = "charge",
				at = event.at,
				entity = event.entity,
				origin = vector.zero,
				direction = vector.zero,
				ids = {},
				poses = {},
			})
		end
		return
	end
	if typeof(event.origin) ~= "Vector3" or typeof(event.direction) ~= "Vector3" then
		return
	end
	local ids: { number } = {}
	local poses: { [number]: Hitboxes.Pose } = {}
	if typeof(event.ids) == "table" and typeof(event.poses) == "table" then
		for _, sent in event.poses do
			local pose = ReconView.poseOf(sent)
			if pose and typeof(sent.id) == "number" then
				poses[sent.id] = pose
			end
		end
		for _, id in event.ids do
			if typeof(id) == "number" and poses[id] then
				table.insert(ids, id)
			end
		end
	end
	table.insert(due, {
		kind = "blast",
		at = event.at,
		entity = event.entity,
		origin = Units.asVector(event.origin),
		direction = Units.asVector(event.direction),
		ids = ids,
		poses = poses,
	})
end

-- A blast or a charge, as the frame on your screen reaches it.
local function happen(d: Due)
	local had = charges[d.entity]
	if had then
		had.part:Destroy()
		charges[d.entity] = nil
	end
	if d.kind == "charge" then
		local p = Instance.new("Part")
		p.Name = "Charge"
		p.Shape = Enum.PartType.Ball
		plain(p)
		p.Material = Enum.Material.Neon
		p.Color = tint(d.entity)
		p.Transparency = 1
		p.Size = Vector3.one * 0.1
		p.Parent = holder()
		charges[d.entity] = { part = p, start = d.at }
		return
	end
	-- Yours was drawn as it went.
	if d.entity ~= PlayerController.entityId then
		blast(d.origin, d.origin + d.direction * HF.range.value, tint(d.entity))
	end
	for _, id in d.ids do
		ReconView.reveal(id, d.poses[id], d.at + HF.reveal.value)
	end
end

-- Whether your bow's in hand, and the kit's time.
local function bowInHand(): (boolean, number)
	local s = PlayerController.sim
	if not s or not PlayerController.alive then
		return false, 0
	end
	local w = s.weapons
	local inHand = s.abilities.furyUntil > 0 and w.equipped == WeaponSim.ULT and w.loadout[WeaponSim.ULT] == FurySim.WEAPON
	return inHand, s.movement.tick * DT
end

-- Where a blast of yours would go while its bow's in hand: from your eye
-- along your crosshair (the minimap's range bar, MinimapView).
function FuryView.aimed(): { origin: vector, direction: vector }?
	local inHand = bowInHand()
	local camera = Workspace.CurrentCamera
	if not inHand or not camera then
		return nil
	end
	local cf = camera.CFrame
	return { origin = Units.toMetres(cf.Position), direction = Units.asVector(cf.LookVector) }
end

function FuryView.start()
	-- Under the crosshair, its time left and a blast's windup; and over the
	-- whole screen, the flash of being caught by one.
	local gui = Ui.screen("VFFury", 16, Enum.ScreenInsets.None)
	local panel = Ui.frame(gui, {
		Name = "Bow",
		Size = UDim2.fromOffset(BAR_W, 2 * BAR_H + BAR_GAP),
		Position = UDim2.new(0.5, -BAR_W / 2, 0.5, BELOW),
		BackgroundTransparency = 1,
		Visible = false,
	})
	local time = Ui.frame(panel, { Name = "Time", Size = UDim2.fromOffset(BAR_W, BAR_H), BackgroundColor3 = DIM })
	local timeFill = Ui.frame(time, { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = LIGHT, BackgroundTransparency = 0 })
	local charge = Ui.frame(panel, {
		Name = "Charge",
		Size = UDim2.fromOffset(BAR_W, BAR_H),
		Position = UDim2.fromOffset(0, BAR_H + BAR_GAP),
		BackgroundColor3 = DIM,
	})
	local chargeFill =
		Ui.frame(charge, { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = LIGHT, BackgroundTransparency = 0 })
	local flash = Ui.frame(gui, {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		ZIndex = 5,
	})

	table.insert(PlayerController.castListeners, onOwnCast)
	local remotes = Remotes.get()
	NetSim.on(remotes.Ability, onEvent)
	NetSim.on(remotes.Combat, function(event: any)
		if typeof(event) ~= "table" or event.kind ~= "damage" or event.target ~= PlayerController.entityId then
			return
		end
		if event.weapon == FurySim.WEAPON then
			flashUntil = os.clock() + FLASH
		end
	end)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()

		-- Your bow: its time left once it's drawn, a blast's windup, and
		-- your view slowed through it.
		local inHand, t = bowInHand()
		local s = PlayerController.sim
		local kit = if s then s.abilities else nil
		local charging = inHand and kit ~= nil and AbilitySim.charging(kit, t)
		local drawn = inHand and s ~= nil and t >= s.weapons.equipEndTime
		local left = if inHand and kit then math.max(kit.furyUntil - t, 0) else 0
		panel.Visible = inHand
		timeFill.Size = UDim2.fromScale(if drawn then math.clamp(left / HF.duration.value, 0, 1) else 1, 1)
		timeFill.BackgroundColor3 = if drawn then LIGHT else LIGHT:Lerp(DIM, 0.6)
		local wound = if charging and kit then math.clamp(1 - (kit.chargeAt - t) / HF.windup.value, 0, 1) else 0
		chargeFill.Size = UDim2.fromScale(wound, 1)
		CameraController.turnScale = if charging then HF.turn.value else 1

		-- Blasts and charges, as the frame on your screen reaches them.
		local i = 1
		while i <= #due do
			local d = due[i]
			if render < d.at then
				i += 1
				continue
			end
			table.remove(due, i)
			if render - d.at < STALE then
				happen(d)
			end
		end
		for j = #shown, 1, -1 do
			local b = shown[j]
			local k = (clock - b.start) / FADE
			if k >= 1 or b.part.Parent == nil then
				b.part:Destroy()
				table.remove(shown, j)
				continue
			end
			b.bands[1].Transparency = NumberSequence.new(0.5 + 0.5 * k)
			b.bands[2].Transparency = NumberSequence.new(k)
		end
		for id, c in charges do
			local k = (render - c.start) / HF.windup.value
			local pose = if RemoteEntities.isPresent(id) then RemoteEntities.sample(id, render) else nil
			if k >= 1 or not pose or not pose.alive then
				c.part:Destroy()
				charges[id] = nil
				continue
			end
			local look = vector.create(-math.sin(pose.yaw), 0, -math.cos(pose.yaw))
			c.part.CFrame = CFrame.new(Units.toStuds(pose.position + vector.create(0, CHEST, 0) + look * AHEAD))
			c.part.Size = Vector3.one * math.max(GROW * k, 0.05) * S
			c.part.Transparency = 0.2
		end

		local flashLeft = flashUntil - clock
		flash.BackgroundTransparency = if flashLeft > 0 then 1 - 0.45 * flashLeft / FLASH else 1

		gui:SetAttribute("Bow", inHand)
		gui:SetAttribute("Left", math.floor(left * 10 + 0.5) / 10)
		gui:SetAttribute("Charging", charging)
		gui:SetAttribute("Turn", CameraController.turnScale)
		gui:SetAttribute("Blasts", #shown)
	end)
end

return FuryView
