--!strict
-- Jett's Cloudburst on the client (system 18): throws in the air, and the
-- clouds they burst into.
--   * Your own throws fly here at once, on your predicted ticks
--     (PlayerController.tickListeners), through CloudSim as the server flies
--     them, and burst where the server's will. When the server says where
--     one burst (the Ability remote's "cloud"), the cloud moves there if it
--     isn't there already
--   * Others' come from the server: where each is every few ticks
--     ("flight"), drawn between them as the frame on your screen reaches
--     them, then the cloud
--   * A cloud is a ball of smoke, solid to its radius so nothing behind it
--     shows, the outlines (Highlights) included, with a softer edge round
--     it. From inside one, the screen is smoke
-- In Workspace's VFClouds each throw in the air is a `Throw` ball, and each
-- cloud a `Cloud` ball with its edge: the cloud's `Centre` attribute is
-- where it is (metres), and `Moved` is set on one of yours that the
-- server's word moved.
-- Omen's Dark Cover (system 40) is drawn here too:
--   * With its orb in hand, its mark: a small glowing ball along your
--     crosshair, its reach away (the kit's, as your simulation has it), and
--     the ball its smoke would be on the floor under it (SmokeSim), both
--     seen through walls; the mark red, and no ball, with nowhere for it
--   * Every smoke comes from the server (the Ability remote's "darkcover":
--     where, and when it forms), yours too: a ball of dark smoke, solid,
--     growing as it forms; from inside one, the screen is dark smoke. Its
--     last 1.5 s it flickers lighter, with a low tone, and then it's gone
--     at once. Others' form with the sound AbilityEffects plays; yours with
--     this view's
-- In VFClouds a smoke is a `Smoke` ball with its `SmokeEdge`, and the mark
-- a `SmokeMark` part with its `Mark` and `Ghost` adornments.
-- Every cloud and smoke goes when the server says every fire's out (a new
-- round, "out").
-- Nothing here is in anyone's way: shots, moves and throws go through
-- clouds and smokes, as their parts can't be hit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local CloudSim = require(Shared.Abilities.CloudSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local SoundConfig = require(Shared.Audio.SoundConfig)
local SmokeSim = require(Shared.Abilities.SmokeSim)
local Units = require(Shared.Units)
local WeaponSim = require(Shared.Weapons.WeaponSim)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local CloudView = {}

local CB = AbilityConfig.Cloudburst
local DC = AbilityConfig.DarkCover
local DARK = Color3.fromRGB(34, 26, 52) -- Dark Cover's smoke
local MARKED = Color3.fromRGB(160, 120, 240) -- its mark, and the smoke it would be
local REFUSED = Color3.fromRGB(230, 70, 70) -- its mark with nowhere for it
local MARK = 0.15 -- metres across: the mark
local FLICKER = 6 -- times a second a smoke flickers as it warns it's going
local DT = 1 / MovementConfig.TickRate.value
local SMOKE = Color3.fromRGB(196, 214, 228)
local GLOW = Color3.fromRGB(150, 230, 255)
local EDGE = 1.12 -- the soft edge's size, times the cloud's
local ORB = 0.3 -- metres across: a throw in the air
local MOVE = 0.25 -- metres: the server's burst this far from ours moves our cloud
local STALE = 1 -- seconds a throw is drawn past the last word on it
local LIVE = 0.1 -- seconds without a predicted tick before your throws fly on by themselves

type Cloud = {
	centre: vector,
	start: number,
	entity: number,
	core: Part,
	edge: Part,
	smoke: boolean, -- Dark Cover's smoke, not Cloudburst's cloud
	formed: boolean, -- heard forming (yours)
	warned: boolean, -- heard warning that it's going
}
type Frame = { at: number, position: vector }
type Flight = { frames: { Frame }, orb: Part, burstAt: number? }

local world = RobloxWorld.new()
local own: { CloudSim.Projectile } = {}
local ownOrbs: { [number]: Part } = {}
local clouds: { [string]: Cloud } = {}
local flights: { [string]: Flight } = {}
local lastLive = 0
local loose = 0 -- seconds your throws haven't flown since your ticks stopped
local folder: Folder? = nil
type Marker = { part: Part, mark: SphereHandleAdornment, ghost: SphereHandleAdornment }
local marker: Marker? = nil

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFClouds"
	made.Parent = Workspace
	folder = made
	return made
end

local function ball(colour: Color3, transparency: number, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material
	p.Color = colour
	p.Transparency = transparency
	p.Size = Vector3.one * 0.05
	p.Parent = holder()
	return p
end

local function orb(): Part
	local p = ball(GLOW, 0.1, Enum.Material.Neon)
	p.Name = "Throw"
	p.Size = Vector3.one * ORB * Units.STUDS_PER_METRE
	return p
end

-- A cloud named `key` at `centre` (metres), burst at `start` on the render
-- clock (RemoteEntities.renderTime), thrown by `entity`; or with `smoke`,
-- Dark Cover's smoke, formed then.
local function makeCloud(key: string, centre: vector, start: number, entity: number, smoke: boolean?)
	if clouds[key] then
		return
	end
	local colour = if smoke then DARK else SMOKE
	local core = ball(colour, 1, Enum.Material.SmoothPlastic)
	core.Name = if smoke then "Smoke" else "Cloud"
	core:SetAttribute("Centre", Units.asVector3(centre))
	local edge = ball(colour, 1, Enum.Material.SmoothPlastic)
	edge.Name = if smoke then "SmokeEdge" else "CloudEdge"
	clouds[key] = {
		centre = centre,
		start = start,
		entity = entity,
		core = core,
		edge = edge,
		smoke = smoke == true,
		formed = false,
		warned = false,
	}
end

local function removeCloud(key: string)
	local c = clouds[key]
	if c then
		c.core:Destroy()
		c.edge:Destroy()
		clouds[key] = nil
	end
end

-- Another's throw in the air, named `key`: hidden until it's placed.
local function flightOf(key: string): Flight
	local f = flights[key]
	if f then
		return f
	end
	local made: Flight = { frames = {}, orb = orb() }
	made.orb.Transparency = 1
	flights[key] = made
	return made
end

local function formOwn(id: number, centre: vector)
	makeCloud("own:" .. id, centre, RemoteEntities.renderTime(), PlayerController.entityId)
	GameSounds.playWorld(SoundConfig.Abilities.cloud, centre, "you")
end

-- Each of your predicted ticks: your throws fly on with its input, and its
-- throws join them.
local function onTick(info: any)
	lastLive = os.clock()
	loose = 0
	if #own == 0 and not info.casts then
		return
	end
	for _, b in CloudSim.tick(own, PlayerController.entityId, info.input, info.casts, DT, world) do
		formOwn(b.id, b.position)
	end
end

-- The server's word on where one of your throws burst.
local function onOwnBurst(id: number, centre: vector)
	local cloud = clouds["own:" .. id]
	if cloud then
		if vector.magnitude(cloud.centre - centre) > MOVE then
			cloud.centre = centre
			cloud.core:SetAttribute("Centre", Units.asVector3(centre))
			cloud.core:SetAttribute("Moved", true)
		end
		return
	end
	-- It hasn't burst here (or wasn't thrown here): the server's goes.
	for i, p in own do
		if p.id == id then
			table.remove(own, i)
			break
		end
	end
	formOwn(id, centre)
end

local function onEvent(event: any)
	if typeof(event) ~= "table" then
		return
	end
	if event.kind == "out" then
		for key in clouds do
			removeCloud(key)
		end
		return
	end
	if event.ability == "darkcover" and event.kind == "darkcover" then
		if typeof(event.entity) == "number" and typeof(event.id) == "number" and typeof(event.at) == "number" then
			if typeof(event.position) == "Vector3" then
				local key = "smoke:" .. event.entity .. ":" .. event.id
				makeCloud(key, Units.toMetres(event.position), event.at, event.entity, true)
			end
		end
		return
	end
	if event.ability ~= "cloudburst" then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.id) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	if typeof(event.position) ~= "Vector3" then
		return
	end
	local position = Units.toMetres(event.position)
	if event.entity == PlayerController.entityId then
		if event.kind == "cloud" then
			onOwnBurst(event.id, position)
		end
		return
	end
	local key = event.entity .. ":" .. event.id
	if event.kind == "flight" then
		table.insert(flightOf(key).frames, { at = event.at, position = position })
	elseif event.kind == "cloud" then
		makeCloud(key, position, event.at, event.entity)
		local f = flights[key]
		if f then
			f.burstAt = event.at
		end
	end
end

-- Where a throw is at `now` from what the server said, if it's been
-- thrown by then.
local function placeAt(frames: { Frame }, now: number): vector?
	local first = frames[1]
	if not first or now < first.at then
		return nil
	end
	for i = #frames, 1, -1 do
		local a = frames[i]
		if a.at <= now then
			local b = frames[i + 1]
			if b then
				local k = (now - a.at) / math.max(b.at - a.at, 1e-6)
				return a.position + (b.position - a.position) * k
			end
			-- Past the last word: on the way it was going.
			local before = frames[i - 1]
			if before and a.at > before.at then
				return a.position + (a.position - before.position) * ((now - a.at) / (a.at - before.at))
			end
			return a.position
		end
	end
	return nil
end

local function stepOwnLoose(frameDt: number)
	if #own == 0 or os.clock() - lastLive < LIVE then
		return
	end
	-- Your ticks have stopped (you died): your throws fly straight on.
	loose = math.min(loose + frameDt, 0.25)
	while loose >= DT do
		loose -= DT
		local i = 1
		while i <= #own do
			local p = own[i]
			local at = CloudSim.drift(p, DT, world)
			if at then
				table.remove(own, i)
				formOwn(p.id, at)
			else
				i += 1
			end
		end
	end
end

-- How wide a cloud or smoke is `age` seconds after it formed.
local function radiusOf(c: Cloud, age: number): number
	return if c.smoke then SmokeSim.radiusAt(age) else CloudSim.radiusAt(age)
end

-- Dark Cover's mark, and the smoke it would be, seen through walls.
local function makeMarker(): Marker
	local part = Instance.new("Part")
	part.Name = "SmokeMark"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one * 0.05
	part.Parent = holder()
	local function adornment(name: string, radius: number, transparency: number): SphereHandleAdornment
		local a = Instance.new("SphereHandleAdornment")
		a.Name = name
		a.Adornee = part
		a.AlwaysOnTop = true
		a.ZIndex = 1
		a.Radius = radius * Units.STUDS_PER_METRE
		a.Transparency = transparency
		a.Visible = false
		a.Parent = part
		return a
	end
	return { part = part, mark = adornment("Mark", MARK / 2, 0.1), ghost = adornment("Ghost", DC.radius.value, 0.8) }
end

-- With Dark Cover's orb in hand, its mark and where its smoke would be.
local function markFrame()
	local had = marker
	local m: Marker = if had and had.part.Parent then had else makeMarker()
	marker = m
	local s = PlayerController.sim
	local w = if s then s.weapons else nil
	local kit = if s then s.abilities else nil
	local camera = Workspace.CurrentCamera
	if
		not (s and w and kit and camera and PlayerController.alive)
		or w.equipped ~= WeaponSim.ULT
		or w.loadout[WeaponSim.ULT] ~= "smokeorb"
		or kit.holding == 0
	then
		m.mark.Visible = false
		m.ghost.Visible = false
		return
	end
	local eye = Units.toMetres(camera.CFrame.Position)
	local aim = Units.asVector(camera.CFrame.LookVector)
	local at = SmokeSim.mark(eye, aim, kit.reach)
	local centre = SmokeSim.place(world, eye, aim, kit.reach)
	local base = centre or at
	m.part.CFrame = CFrame.new(Units.toStuds(base))
	m.mark.CFrame = CFrame.new(Units.toStuds(at - base))
	m.mark.Color3 = if centre then MARKED else REFUSED
	m.mark.Visible = true
	m.ghost.Color3 = MARKED
	m.ghost.Visible = centre ~= nil
end

-- The clouds and smokes standing at `now` on the render clock, for the
-- minimap (system 34) and sight: each one's centre and radius then, and
-- its thrower.
function CloudView.standing(now: number): { { centre: vector, radius: number, entity: number } }
	local out = {}
	for _, c in clouds do
		local r = radiusOf(c, now - c.start)
		if r > 0 then
			table.insert(out, { centre = c.centre, radius = r, entity = c.entity })
		end
	end
	return out
end

function CloudView.start()
	-- From inside a cloud, the screen is smoke (under the HUD).
	local gui = Ui.screen("VFSmoke", 1, Enum.ScreenInsets.None)
	local screen = Ui.frame(gui, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = SMOKE,
		BackgroundTransparency = 0.08,
		Visible = false,
	})

	table.insert(PlayerController.tickListeners, onTick)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function(frameDt)
		local now = RemoteEntities.renderTime()
		stepOwnLoose(frameDt)

		local flying: { [number]: boolean } = {}
		for _, p in own do
			flying[p.id] = true
			local o = ownOrbs[p.id]
			if not o then
				o = orb()
				ownOrbs[p.id] = o
			end
			o.CFrame = CFrame.new(Units.toStuds(p.position))
		end
		for id, o in ownOrbs do
			if not flying[id] then
				o:Destroy()
				ownOrbs[id] = nil
			end
		end

		for key, f in flights do
			local last = f.frames[#f.frames]
			local burstAt = f.burstAt
			if (burstAt and now >= burstAt) or (not burstAt and now - last.at > STALE) then
				f.orb:Destroy()
				flights[key] = nil
			else
				local at = placeAt(f.frames, now)
				f.orb.Transparency = if at then 0.1 else 1
				if at then
					f.orb.CFrame = CFrame.new(Units.toStuds(at))
				end
			end
		end

		local camera = Workspace.CurrentCamera
		local eye = if camera then Units.toMetres(camera.CFrame.Position) else nil
		local inside: Color3? = nil
		for key, c in clouds do
			local age = now - c.start
			if age >= (if c.smoke then DC.duration.value else CB.duration.value) then
				removeCloud(key)
				continue
			end
			local r = radiusOf(c, age)
			local thick = if c.smoke then 1 else CloudSim.thicknessAt(age)
			if c.smoke and age >= 0 then
				-- Dark Cover's: yours heard forming, and everyone's warning that
				-- it's going, flickering until it's gone.
				if not c.formed then
					c.formed = true
					if c.entity == PlayerController.entityId then
						GameSounds.playCast("darkcover", c.centre, c.entity)
					end
				end
				-- It flickers lighter, never thinner: nobody sees through it
				-- until it's gone.
				local glow = 0
				if SmokeSim.warning(age) then
					if not c.warned then
						c.warned = true
						GameSounds.playCast("fading", c.centre, c.entity)
					end
					local since = age - (DC.duration.value - DC.warn.value)
					glow = 0.5 - 0.5 * math.cos(since * FLICKER * 2 * math.pi)
				end
				c.core.Color = DARK:Lerp(MARKED, 0.3 * glow)
			end
			local across = math.max(2 * r * Units.STUDS_PER_METRE, 0.05)
			local where = CFrame.new(Units.toStuds(c.centre))
			c.core.Size = Vector3.one * across
			c.core.CFrame = where
			c.core.Transparency = if r > 0 then 1 - thick else 1
			c.edge.Size = Vector3.one * across * EDGE
			c.edge.CFrame = where
			c.edge.Transparency = if r > 0 then 1 - 0.45 * thick else 1
			if eye and r > 0 then
				local within = if c.smoke then vector.magnitude(eye - c.centre) < r else CloudSim.inside(c.centre, age, eye)
				if within then
					inside = if c.smoke then DARK else (inside or SMOKE)
				end
			end
		end
		screen.Visible = inside ~= nil
		screen.BackgroundColor3 = inside or SMOKE
		markFrame()
	end)
end

return CloudView
