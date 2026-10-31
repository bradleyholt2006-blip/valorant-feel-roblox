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
--     its vision dark, a shell of shadow round the camera that far out,
--     seen from inside, as the reference's nearsight has what's past it
--     'replaced with dark, opaque colors' (the VALORANT Wiki's Status
--     Effect page; community), and the minimap covered (MinimapView, by
--     ParanoiaView.dark); then all of it clearing over the fade, the dark
--     drawing back and thinning away. Yours starting sounds on the UI bus
--     (GameSounds.playNearsight). Reyna's Leer's (system 74) is drawn the
--     same way
--   * Your deafening, or the watched player's, the same way
--     (ParanoiaSim.DEAF_ATTRIBUTE): the World and Self buses muffled
--     (SoundEngine.setDeafened), clearing as it clears
--   * Others': a wisp of shadow round the head while it lasts. The watched
--     player's is on your screen instead
--   * How far you see as a Shade in From the Shadows (system 43,
--     ShadowView, ParanoiaView.cap): the same dark, whole, that far out,
--     wherever a nearsight's is further
-- In Workspace's VFParanoia each orb in flight is an `Orb` ball with its
-- `Core` ball, the dark round the camera is `Dark`, a model of `Slab`s,
-- and each wisp a `Wisp` ball with its player's name as its Player
-- attribute; PlayerGui's VFParanoia has the warning, `Warn`.

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
-- How far you see, metres, while something else keeps you from seeing
-- further (Omen's Shade, system 43, ShadowView): the dark's whole past it.
-- Nil without.
ParanoiaView.cap = nil :: number?

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
-- The dark's shell: how many slabs it has, how far each reaches from its
-- middle, as an angle from the camera, and how thick it is (ours). The
-- slabs lie on directions spread evenly round the camera, each wide
-- enough to meet those round it.
local SLABS = 120
local SLAB_REACH = 1.5 * math.acos(1 - 2 / SLABS)
local SLAB_THICK = 0.05 -- metres
-- As the dark clears, how far it's drawn back at the most, and how much
-- of it's left as it starts to thin away too (ours).
local FAR = 150 -- metres
local THIN_FROM = 0.2

-- An orb in flight: when it was sent on its clock, os.clock() for yours
-- and the render clock for others', and whether you've been warned of it.
type Shown = { orb: ParanoiaSim.Orb, start: number, own: boolean, warned: boolean, shell: Part, core: Part }

local me = Players.LocalPlayer
local orbs: { [string]: Shown } = {}
local sent: { [string]: number } = {} -- your sends, by key, at os.clock()
local wisps: { [Player]: Part } = {}
local folder: Folder? = nil
-- The dark's shell: its slabs, the way out from the camera to each and
-- each one's turn, and how far out and how see-through they were last.
local darkModel: Model? = nil
local slabs: { BasePart } = {}
local slabWays: { Vector3 } = {}
local slabTurns: { CFrame } = {}
local darkRadius = -1
local darkClear = -1
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

-- The dark round the camera, seen from inside: a shell of thin slabs, each
-- square to the way out to it, that closes all round it. A part's faces
-- are drawn from outside only, and Roblox draws a sphere mesh scaled by -1
-- as it does one scaled by 1, so a ball turned inside out isn't seen from
-- within (the Studio checklist's PA5 found it never drawn); a slab's face
-- towards the camera is. Spread evenly (a Fibonacci sphere), the nearest
-- slab whichever way the camera looks is no more than about 14 degrees off
-- it, so its face is no more than 3% further out than the vision. They're
-- neon, so they're as dark whichever way the light falls on them.
local function dark(): Model
	local had = darkModel
	if had and had.Parent then
		return had
	end
	local model = Instance.new("Model")
	model.Name = "Dark"
	table.clear(slabs)
	table.clear(slabWays)
	table.clear(slabTurns)
	local golden = math.pi * (3 - math.sqrt(5))
	for i = 0, SLABS - 1 do
		local y = 1 - (i + 0.5) * 2 / SLABS
		local across = math.sqrt(1 - y * y)
		local way = Vector3.new(math.cos(golden * i) * across, y, math.sin(golden * i) * across)
		-- Its back faces out, so its front faces the camera.
		local helper = if math.abs(way.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis
		local right = helper:Cross(way).Unit
		local turn = CFrame.fromMatrix(Vector3.zero, right, way:Cross(right), way)
		local p = Instance.new("Part")
		p.Name = "Slab"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = DARK
		p.Transparency = 1
		p.Parent = model
		table.insert(slabs, p)
		table.insert(slabWays, way)
		table.insert(slabTurns, turn)
	end
	model.Parent = holder()
	darkModel = model
	darkRadius, darkClear = -1, -1
	return model
end

-- The dark round the camera at `at` (studs), `amount` of it (0 to 1, as
-- ParanoiaSim.darkAt has it): whole, its vision out; clearing, drawn back
-- further and further, and thinning away once little's left. With a cap on
-- how far you see (metres) nearer than that, whole at the cap.
local function placeDark(at: Vector3?, amount: number, cap: number?)
	dark()
	local vision = PA.vision.value
	local out = if amount > 0 then math.min(vision / amount, FAR) else math.huge
	local capped = cap ~= nil and cap < out
	local clear = if not at then 1 elseif capped then 0 elseif amount > 0 then 1 - math.min(amount / THIN_FROM, 1) else 1
	if clear ~= darkClear then
		darkClear = clear
		for _, p in slabs do
			p.Transparency = clear
		end
	end
	if not at or clear >= 1 then
		return
	end
	local radius = (if cap and capped then cap else out) * Units.STUDS_PER_METRE
	if radius ~= darkRadius then
		darkRadius = radius
		local side = 2 * radius * math.tan(SLAB_REACH)
		local size = Vector3.new(side, side, SLAB_THICK * Units.STUDS_PER_METRE)
		for _, p in slabs do
			p.Size = size
		end
	end
	local cframes = table.create(#slabs)
	for i, way in slabWays do
		cframes[i] = CFrame.new(at + way * radius) * slabTurns[i]
	end
	Workspace:BulkMoveTo(slabs, cframes, Enum.BulkMoveMode.FireCFrameChanged)
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
		local screen = if watched then watched.holder else me
		local n = ParanoiaSim.decode(screen:GetAttribute(ParanoiaSim.ATTRIBUTE))
		local deaf = ParanoiaSim.decode(screen:GetAttribute(ParanoiaSim.DEAF_ATTRIBUTE))
		local t = if watched then render else Workspace:GetServerTimeNow()
		local amount = if n then ParanoiaSim.darkAt(n, t) else 0
		if n and not watched and amount > 0 and heard ~= n.from then
			heard = n.from
			GameSounds.playNearsight()
		end
		ParanoiaView.dark = amount
		SoundEngine.setDeafened(if deaf then ParanoiaSim.darkAt(deaf, t) else 0)
		local camera = Workspace.CurrentCamera
		placeDark(if camera then camera.CFrame.Position else nil, amount, ParanoiaView.cap)

		for _, player in Players:GetPlayers() do
			if player ~= me then
				placeWisp(player, render)
			end
		end
	end)
end

return ParanoiaView
