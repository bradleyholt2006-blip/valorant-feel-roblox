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
-- Nothing here is in anyone's way: shots, moves and throws go through
-- clouds, as their parts can't be hit.

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
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local CloudView = {}

local CB = AbilityConfig.Cloudburst
local DT = 1 / MovementConfig.TickRate.value
local SMOKE = Color3.fromRGB(196, 214, 228)
local GLOW = Color3.fromRGB(150, 230, 255)
local EDGE = 1.12 -- the soft edge's size, times the cloud's
local ORB = 0.3 -- metres across: a throw in the air
local MOVE = 0.25 -- metres: the server's burst this far from ours moves our cloud
local STALE = 1 -- seconds a throw is drawn past the last word on it
local LIVE = 0.1 -- seconds without a predicted tick before your throws fly on by themselves

type Cloud = { centre: vector, start: number, core: Part, edge: Part }
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
-- clock (RemoteEntities.renderTime).
local function makeCloud(key: string, centre: vector, start: number)
	if clouds[key] then
		return
	end
	local core = ball(SMOKE, 0, Enum.Material.SmoothPlastic)
	core.Name = "Cloud"
	core:SetAttribute("Centre", Units.asVector3(centre))
	local edge = ball(SMOKE, 1, Enum.Material.SmoothPlastic)
	edge.Name = "CloudEdge"
	clouds[key] = { centre = centre, start = start, core = core, edge = edge }
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
	makeCloud("own:" .. id, centre, RemoteEntities.renderTime())
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
	if typeof(event) ~= "table" or event.ability ~= "cloudburst" then
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
		makeCloud(key, position, event.at)
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
		local inside = false
		for key, c in clouds do
			local age = now - c.start
			if age >= CB.duration.value then
				removeCloud(key)
				continue
			end
			local r = CloudSim.radiusAt(age)
			local thick = CloudSim.thicknessAt(age)
			local across = math.max(2 * r * Units.STUDS_PER_METRE, 0.05)
			local where = CFrame.new(Units.toStuds(c.centre))
			c.core.Size = Vector3.one * across
			c.core.CFrame = where
			c.core.Transparency = if r > 0 then 1 - thick else 1
			c.edge.Size = Vector3.one * across * EDGE
			c.edge.CFrame = where
			c.edge.Transparency = if r > 0 then 1 - 0.45 * thick else 1
			if eye and CloudSim.inside(c.centre, age, eye) then
				inside = true
			end
		end
		screen.Visible = inside
	end)
end

return CloudView
