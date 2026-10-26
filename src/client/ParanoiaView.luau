--!strict
-- Omen's Paranoia on the client (system 41): orbs in flight, the warning,
-- and nearsights.
--   * Your own fly here at once, as you send them (PlayerController's
--     castListeners), through ParanoiaSim as the server flies them; the
--     server's word on one changes nothing, as nothing changes its path
--   * Others' come from the server (the Ability remote's "flight"): where
--     from and which way, flown here the same way as the frame on your
--     screen reaches the send
--   * An orb is a ball of shadow its radius across, with a darker core (the
--     VALORANT Wiki has the reference's look matched to what it touches in
--     v1.09; community)
--   * Standing in an orb's path as it shows, you're warned: shadow at the
--     screen's edges for a moment (Patch 1.0: 'Enemies will receive a
--     warning when the projectile is fired')
--   * Your nearsight, or the nearsight of the player you're watching
--     (Spectate), as the server keeps it (ParanoiaSim.ATTRIBUTE): all past
--     its vision dark, a ball of shadow round the camera that far out, seen
--     from inside, as the reference's nearsight has what's past it
--     'replaced with dark, opaque colors' (the VALORANT Wiki's Status
--     Effect page; community); the World and Self buses muffled
--     (SoundEngine.setDeafened), and the minimap covered (MinimapView, by
--     ParanoiaView.dark); then all of it clearing over the fade. Yours
--     starting sounds on the UI bus (GameSounds.playNearsight)
--   * Others': a wisp of shadow round the head while it lasts. The watched
--     player's is on your screen instead
-- In Workspace's VFParanoia each orb in flight is an `Orb` ball with its
-- `Core` ball, the dark round the camera is `Dark`, and each wisp a `Wisp`
-- ball with its player's name as its Player attribute; PlayerGui's
-- VFParanoia has the warning, `Warn`.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local ParanoiaSim = require(Shared.Abilities.ParanoiaSim)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Sight = require(Shared.Combat.Sight)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local Spectate = require(script.Parent.Spectate)
local GameSounds = require(script.Parent.Audio.GameSounds)
local SoundEngine = require(script.Parent.Audio.SoundEngine)
local Ui = require(script.Parent.Debug.Ui)

local ParanoiaView = {}

-- How dark the nearsight on your screen is now, 0 to 1, for the minimap.
ParanoiaView.dark = 0

local PA = AbilityConfig.Paranoia
local SHADOW = Color3.fromRGB(46, 26, 72)
local CORE = Color3.fromRGB(16, 10, 26)
local DARK = Color3.fromRGB(10, 7, 14)
local SHELL = 0.7 -- how see-through the orb is (ours)
local CORE_SEE = 0.2 -- and its core
local CORE_SIZE = 1.2 -- metres across (ours)
local WISP_SIZE = 0.45 -- metres across (ours)
local WISP_MOST = 0.75 -- how solid a wisp is at its darkest (ours)
local WARN = 0.6 -- seconds the warning shows (ours)
local WARN_MOST = 0.35 -- how see-through it is at its strongest (ours)
local KEEP = 5 -- seconds your sends are remembered, so the server's word on one doesn't send it again

-- An orb in flight: when it was sent on its clock, os.clock() for yours
-- and the render clock for others', and whether you've been warned of it.
type Shown = { orb: ParanoiaSim.Orb, start: number, own: boolean, warned: boolean, shell: Part, core: Part }

local me = Players.LocalPlayer
local orbs: { [string]: Shown } = {}
local sent: { [string]: number } = {} -- your sends, by key, at os.clock()
local wisps: { [Player]: Part } = {}
local folder: Folder? = nil
local darkPart: Part? = nil
local warnedAt = -math.huge
-- When the nearsight on your screen started, to sound yours once.
local heard: number? = nil

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFParanoia"
	made.Parent = Workspace
	folder = made
	return made
end

local function ball(name: string, across: number, colour: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = colour
	p.Transparency = 1
	p.Size = Vector3.one * across * Units.STUDS_PER_METRE
	p.Parent = holder()
	return p
end

-- The dark round the camera: a ball its vision out, turned inside out so
-- it's seen from within (a part's faces are drawn from outside only).
local function dark(): Part
	local had = darkPart
	if had and had.Parent then
		return had
	end
	local p = Instance.new("Part")
	p.Name = "Dark"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = DARK
	p.Transparency = 1
	p.Size = Vector3.one * 2 * PA.vision.value * Units.STUDS_PER_METRE
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = -Vector3.one
	mesh.Parent = p
	p.Parent = holder()
	darkPart = p
	return p
end

local function drop(key: string)
	local s = orbs[key]
	if s then
		s.shell:Destroy()
		s.core:Destroy()
		orbs[key] = nil
	end
end

local function show(key: string, orb: ParanoiaSim.Orb, start: number, own: boolean)
	drop(key)
	orbs[key] = {
		orb = orb,
		start = start,
		own = own,
		warned = false,
		shell = ball("Orb", 2 * PA.radius.value, SHADOW),
		core = ball("Core", CORE_SIZE, CORE),
	}
end

-- The points of you an orb can touch, while you're alive.
local function myPoints(): { vector }?
	local sim = PlayerController.sim
	if not PlayerController.alive or not sim then
		return nil
	end
	return Sight.points({ position = sim.movement.position, yaw = 0, crouchAlpha = sim.movement.crouchAlpha })
end

local function onOwnCast(cast: AbilitySim.Cast)
	if cast.kind ~= "paranoia" then
		return
	end
	local key = "own:" .. cast.tick
	sent[key] = os.clock()
	show(key, ParanoiaSim.send(PlayerController.entityId, cast.tick, cast.origin, cast.direction), os.clock(), true)
end

local function onEvent(event: any)
	if typeof(event) ~= "table" or event.ability ~= "paranoia" or event.kind ~= "flight" then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.id) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	if typeof(event.position) ~= "Vector3" or typeof(event.direction) ~= "Vector3" then
		return
	end
	local orb = ParanoiaSim.send(event.entity, event.id, Units.toMetres(event.position), Units.asVector(event.direction))
	if event.entity ~= PlayerController.entityId then
		show(event.entity .. ":" .. event.id, orb, event.at, false)
		return
	end
	-- Yours: sent here already, or the server's goes, on your clock.
	local key = "own:" .. event.id
	if sent[key] then
		return
	end
	sent[key] = os.clock()
	show(key, orb, os.clock() - (Workspace:GetServerTimeNow() - event.at), true)
end

local function wispFor(player: Player): Part
	local had = wisps[player]
	if had and had.Parent then
		return had
	end
	local p = ball("Wisp", WISP_SIZE, CORE)
	p:SetAttribute("Player", player.Name)
	wisps[player] = p
	return p
end

local function dropWisp(player: Player)
	local had = wisps[player]
	if had then
		had:Destroy()
		wisps[player] = nil
	end
end

-- Another player's wisp at render time `now`, round their head where
-- they're drawn, while any of their nearsight is left.
local function placeWisp(player: Player, now: number)
	local n = ParanoiaSim.decode(player:GetAttribute(ParanoiaSim.ATTRIBUTE))
	local id = PlayerCodec.entityIdForUser(player.UserId)
	local amount = if n and id ~= RemoteEntities.viewing then ParanoiaSim.darkAt(n, now) else 0
	local pose = if amount > 0 and RemoteEntities.isPresent(id) then RemoteEntities.sample(id, now) else nil
	local head = if pose and pose.alive
		then Hitboxes.region({ position = pose.position, yaw = pose.yaw, crouchAlpha = pose.crouchAlpha }, "head")
		else nil
	if not head then
		dropWisp(player)
		return
	end
	local wisp = wispFor(player)
	wisp.CFrame = CFrame.new(Units.toStuds(head.center))
	wisp.Transparency = 1 - WISP_MOST * amount
end

function ParanoiaView.start()
	local gui = Ui.screen("VFParanoia", 3, Enum.ScreenInsets.None)
	local edge = Ui.frame(gui, {
		Name = "Warn",
		Size = UDim2.new(1, -60, 1, -60),
		Position = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 1,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = SHADOW
	stroke.Thickness = 60
	stroke.Transparency = 1
	stroke.Parent = edge

	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	Players.PlayerRemoving:Connect(dropWisp)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		local flight = ParanoiaSim.flight()
		for key, s in orbs do
			local age = (if s.own then clock else render) - s.start
			if age >= flight then
				drop(key)
				continue
			end
			if age < 0 then
				continue
			end
			-- As it shows, you're warned if you stand in its path.
			if not s.warned then
				s.warned = true
				local points = myPoints()
				if points and ParanoiaSim.inPath(s.orb, points) then
					warnedAt = clock
				end
			end
			local at = CFrame.new(Units.toStuds(ParanoiaSim.at(s.orb, age)))
			s.shell.CFrame = at
			s.core.CFrame = at
			s.shell.Transparency = SHELL
			s.core.Transparency = CORE_SEE
		end
		for key, at in sent do
			if clock - at > KEEP then
				sent[key] = nil
			end
		end
		local k = (clock - warnedAt) / WARN
		stroke.Transparency = if k < 1 then WARN_MOST + (1 - WARN_MOST) * k else 1

		-- Whose screen this is: yours, or the watched player's, as they're
		-- drawn.
		local watched = Spectate.watching
		local n = ParanoiaSim.decode((watched or me):GetAttribute(ParanoiaSim.ATTRIBUTE))
		local t = if watched then render else Workspace:GetServerTimeNow()
		local amount = if n then ParanoiaSim.darkAt(n, t) else 0
		if n and not watched and amount > 0 and heard ~= n.from then
			heard = n.from
			GameSounds.playNearsight()
		end
		ParanoiaView.dark = amount
		SoundEngine.setDeafened(amount)
		local d = dark()
		local camera = Workspace.CurrentCamera
		if amount > 0 and camera then
			d.CFrame = CFrame.new(camera.CFrame.Position)
			d.Transparency = 1 - amount
		else
			d.Transparency = 1
		end

		for _, player in Players:GetPlayers() do
			if player ~= me then
				placeWisp(player, render)
			end
		end
	end)
end

return ParanoiaView
