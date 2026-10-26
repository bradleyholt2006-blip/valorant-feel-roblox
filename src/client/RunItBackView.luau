--!strict
-- Phoenix's Run it Back on the client (system 33). Ours, not the
-- reference's art: plain parts and the engine's own fire.
--   * Its mark: a small flame on the floor where it was cast (Player
--     Assist's guide: 'a small flame on the ground where you will be
--     respawning'; community), for everyone, while it runs and while his
--     body's gone, until he rises there. Your own is drawn from your
--     predicted kit (PlayerController.sim) from the tick you cast it;
--     others' come from the server (the Ability remote's "mark") and show
--     as the frame on your screen reaches them
--   * His body going ("fizzle"): for others, a burst of flame where he
--     was, as the frame on your screen reaches it. He's gone with it, as
--     the snapshots leave him out
--   * His rising at the mark ("rise"): for others, a column of flame that
--     thins away through his rise, him inside it
--   * For you, the screen is flame while your body's gone, clearing through
--     your rise, and your view's put back the way you faced as you cast it
--     (PlayerController). Your body going as the server spared you a hit
--     is heard here as the server's word comes, as your client couldn't see
--     it coming; the rest is heard as AbilityEffects hears every cast
-- In Workspace's VFRunItBack each mark is a `Mark` model while it's drawn,
-- its `Entity` attribute whose it is. Others' go when the server says every
-- fire's out (a new round, "out"), and any left longer than one can last go
-- anyway.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local RunItBackView = {}

local RB = AbilityConfig.RunItBack
local DT = 1 / MovementConfig.TickRate.value
local S = Units.STUDS_PER_METRE
local FLAME = Color3.fromRGB(255, 120, 40)
local CORE = Color3.fromRGB(255, 200, 90)
local MARK = 0.7 -- metres across the mark's glow on the floor (ours)
local LIFT = 0.02 -- metres that glow sits over the floor
local CHEST = 1 -- metres over the feet a body's burst is
local BURST = 0.45 -- seconds a body's burst takes (ours)
local COLUMN = 0.9 -- metres across the column he rises in (ours)
local TALL = 2.2 -- metres tall
local AWAY = 0.12 -- how clear your screen's flame is while your body's gone (ours)
local STALE = 1 -- seconds: a body's going the screen is this far past isn't shown
-- Seconds a mark can be drawn at most: its time, his body's, and the grace
-- the server gives that.
local LONGEST = RB.duration.value + RB.away.value + RB.grace.value
-- Seconds from your body going to your next Run it Back at the soonest:
-- any word of it going again before then is the same return.
local RETURN = RB.away.value + RB.rise.value

-- Another's mark: when (server time) and where (metres) it was cast, and
-- its model once it's drawn.
type Marked = { at: number, position: vector, model: Model? }
-- Another's body going or rising, for the frame on your screen to reach.
type Due = { kind: string, at: number, position: vector, entity: number }

local folder: Folder? = nil
local marks: { [number]: Marked } = {}
local due: { Due } = {}
local own: Model? = nil
local ownAt: vector? = nil
-- When (os.clock()) your body's going was last heard.
local heard = -math.huge

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFRunItBack"
	made.Parent = Workspace
	folder = made
	return made
end

local function part(parent: Instance, name: string, shape: Enum.PartType): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Shape = shape
	p.Material = Enum.Material.Neon
	p.Color = FLAME
	p.Transparency = 1
	p.Size = Vector3.one * 0.2
	p.Parent = parent
	return p
end

local function light(parent: Instance, brightness: number, range: number): PointLight
	local l = Instance.new("PointLight")
	l.Color = FLAME
	l.Brightness = brightness
	l.Range = range * S
	l.Shadows = false
	l.Parent = parent
	return l
end

-- The engine's fire on an unseen part at `feet` (metres) in `parent`.
local function flame(parent: Instance, feet: vector, size: number, heat: number): Part
	local p = part(parent, "Flame", Enum.PartType.Block)
	p.CFrame = CFrame.new(Units.toStuds(feet + vector.create(0, 0.1, 0)))
	local f = Instance.new("Fire")
	f.Color = FLAME
	f.SecondaryColor = CORE
	f.Size = size
	f.Heat = heat
	f.Parent = p
	return p
end

-- `entity`'s mark at `feet` (metres): a glow on the floor, and a small
-- flame and its light over it.
local function newMark(feet: vector, entity: number): Model
	local model = Instance.new("Model")
	model.Name = "Mark"
	model:SetAttribute("Entity", entity)
	local glow = part(model, "Glow", Enum.PartType.Cylinder)
	-- A cylinder's axis is its X: turned up, it lies flat.
	glow.Size = Vector3.new(LIFT * S, MARK * S, MARK * S)
	glow.CFrame = CFrame.new(Units.toStuds(feet + vector.create(0, LIFT / 2, 0))) * CFrame.Angles(0, 0, math.pi / 2)
	glow.Transparency = 0.35
	light(flame(model, feet, 2, 4), 1.5, 5)
	model.Parent = holder()
	return model
end

local function forgetMark(entity: number)
	local m = marks[entity]
	if m and m.model then
		m.model:Destroy()
	end
	marks[entity] = nil
end

-- Runs `update` with how far through `duration` it is (0 to 1) each frame,
-- then removes `instance`.
local function animate(instance: Instance, duration: number, update: (number) -> ())
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / duration
		if k >= 1 or instance.Parent == nil then
			conn:Disconnect()
			instance:Destroy()
			return
		end
		update(k)
	end)
end

-- A body going from `feet` (metres): a ball of flame spreading from the
-- chest as it fades, and embers rising out of it.
local function burst(feet: vector)
	local centre = feet + vector.create(0, CHEST, 0)
	local ball = part(holder(), "Burst", Enum.PartType.Ball)
	ball.CFrame = CFrame.new(Units.toStuds(centre))
	local glow = light(ball, 6, 10)
	animate(ball, BURST, function(k)
		ball.Size = Vector3.one * (0.6 + 1.6 * math.sqrt(k)) * S
		ball.Transparency = 0.2 + 0.8 * k
		glow.Brightness = 6 * (1 - k)
	end)
	for i = 1, 6 do
		local angle = i / 6 * 2 * math.pi
		local out = vector.create(math.cos(angle), 0, math.sin(angle))
		local ember = part(holder(), "Ember", Enum.PartType.Ball)
		ember.Color = CORE
		ember.Size = Vector3.one * 0.08 * S
		animate(ember, 2 * BURST, function(k)
			ember.CFrame = CFrame.new(Units.toStuds(centre + out * (0.3 + 0.4 * k) + vector.create(0, 1.5 * k, 0)))
			ember.Transparency = k
		end)
	end
end

-- His rising at the mark `feet` (metres): a column of flame thinning away
-- through his rise.
local function column(feet: vector)
	local model = Instance.new("Model")
	model.Name = "Rise"
	local sheet = part(model, "Column", Enum.PartType.Cylinder)
	-- A cylinder's axis is its X: turned up, it stands.
	local middle = CFrame.new(Units.toStuds(feet + vector.create(0, TALL / 2, 0))) * CFrame.Angles(0, 0, math.pi / 2)
	local glow = light(flame(model, feet, 6, 12), 4, 8)
	model.Parent = holder()
	animate(model, RB.rise.value, function(k)
		local across = COLUMN * (1 - 0.5 * k)
		sheet.Size = Vector3.new(TALL * S, across * S, across * S)
		sheet.CFrame = middle
		sheet.Transparency = 0.3 + 0.7 * k
		glow.Brightness = 4 * (1 - k)
	end)
end

local function onOwnCast(cast: AbilitySim.Cast)
	if cast.kind == "fizzle" then
		heard = os.clock()
	end
end

local function onEvent(event: any)
	if typeof(event) ~= "table" then
		return
	end
	if event.kind == "out" then
		for entity in marks do
			forgetMark(entity)
		end
		table.clear(due)
		return
	end
	if event.ability ~= "runitback" or typeof(event.entity) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	if typeof(event.kind) ~= "string" or typeof(event.position) ~= "Vector3" then
		return
	end
	local feet = Units.toMetres(event.position)
	if event.entity == PlayerController.entityId then
		-- Yours is drawn from your kit; but your body going as the server
		-- spared you a hit is heard as its word comes.
		if event.kind == "fizzle" and event.spared == true and os.clock() - heard >= RETURN then
			heard = os.clock()
			GameSounds.playCast("fizzle", feet)
		end
		return
	end
	if event.kind == "mark" then
		forgetMark(event.entity)
		marks[event.entity] = { at = event.at, position = feet, model = nil }
	elseif event.kind == "fizzle" or event.kind == "rise" then
		local d: Due = { kind = event.kind, at = event.at, position = feet, entity = event.entity }
		table.insert(due, d)
	end
end

function RunItBackView.start()
	-- While your body's gone the screen is flame (under the HUD).
	local gui = Ui.screen("VFRunItBack", 3, Enum.ScreenInsets.None)
	local screen = Ui.frame(gui, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	})
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, FLAME),
		ColorSequenceKeypoint.new(0.5, CORE),
		ColorSequenceKeypoint.new(1, FLAME),
	})
	gradient.Rotation = 90
	gradient.Parent = screen

	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		-- Others' bodies going and rising, as the frame on your screen
		-- reaches them, and their marks.
		local render = RemoteEntities.renderTime()
		local i = 1
		while i <= #due do
			local d = due[i]
			if render >= d.at then
				table.remove(due, i)
				if d.kind == "rise" then
					forgetMark(d.entity)
					if render - d.at < RB.rise.value then
						column(d.position)
					end
				elseif render - d.at < STALE then
					burst(d.position)
				end
			else
				i += 1
			end
		end
		for entity, m in marks do
			if render - m.at >= LONGEST then
				forgetMark(entity)
			elseif render >= m.at and not m.model then
				m.model = newMark(m.position, entity)
			end
		end

		-- Yours, from your kit: its mark, and the screen while your body's
		-- gone and as you rise.
		local s = PlayerController.sim
		local kit = if s then s.abilities else nil
		local t = if s then s.movement.tick * DT else 0
		local marked = if kit and (AbilitySim.runningBack(kit) or AbilitySim.away(kit, t)) then kit.mark else nil
		if marked ~= ownAt then
			if own then
				own:Destroy()
			end
			own = if marked then newMark(marked, PlayerController.entityId) else nil
			ownAt = marked
		end
		local clear = 1
		if kit and AbilitySim.returning(kit, t) then
			local back = kit.returnAt + RB.away.value
			clear = AWAY + (1 - AWAY) * math.clamp((t - back) / RB.rise.value, 0, 1)
		end
		screen.Visible = clear < 1
		screen.BackgroundTransparency = clear
	end)
end

return RunItBackView
