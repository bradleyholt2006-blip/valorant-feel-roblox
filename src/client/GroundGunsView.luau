--!strict
-- Guns on the ground on this client (system 15). Each gun the server has put
-- down (Workspace.VFGroundGuns) is drawn lying on its side where it rests,
-- in its stand-in look (WeaponLooks). The one in view and within reach is
-- outlined, with what F does to it: "F  PICK UP VANDAL" into an empty slot,
-- or "F  SWAP FOR VANDAL" for the gun in its slot. F asks the server for it
-- (the GroundGun remote), and it's drawn once the server has put it in its
-- slot, as a purchase is. The view and reach are GroundGuns', the same ones
-- the server checks.
--
-- Everything is built here from plain parts, lives only on this client,
-- never collides and is invisible to raycasts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GroundGuns = require(Shared.Weapons.GroundGuns)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Accuracy = require(Shared.Weapons.Accuracy)
local PlayerSim = require(Shared.PlayerSim)
local SpikeSim = require(Shared.Spike.SpikeSim)
local RobloxSpike = require(Shared.Spike.RobloxSpike)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Ui = require(script.Parent.Debug.Ui)
local BuyMenu = require(script.Parent.BuyMenu)
local CameraController = require(script.Parent.CameraController)
local PlayerController = require(script.Parent.PlayerController)
local WeaponLooks = require(script.Parent.Combat.WeaponLooks)

local GroundGunsView = {}

-- The gun F would take now, if any.
GroundGunsView.aimed = nil :: GroundGuns.Gun?

local OUTLINE = Color3.fromRGB(255, 255, 255)
local ROLL = CFrame.Angles(0, 0, math.rad(90)) -- on its side: its width points up

local state = GroundGuns.new() -- this client's copy, from the server's parts
local looks: { [number]: Model } = {}

local function piecePart(parent: Instance, size: vector, color: Color3): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = Units.toStuds(size)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- The gun's look, lying on its side at `rest` (its look vector the way the
-- muzzle points), centred on where it rests.
local function build(weapon: string, rest: CFrame): Model
	local model = Instance.new("Model")
	model.Name = weapon
	local shape = WeaponLooks.shape(weapon)
	local low, high = vector.create(math.huge, math.huge, math.huge), vector.create(-math.huge, -math.huge, -math.huge)
	for _, piece in shape.pieces do
		low = vector.min(low, piece.offset - piece.size / 2)
		high = vector.max(high, piece.offset + piece.size / 2)
	end
	local middle = (low + high) / 2
	-- Lying on its side, its width is its height off the ground.
	local lift = CFrame.new(0, (high.x - low.x) / 2 * Units.STUDS_PER_METRE, 0)
	for _, piece in shape.pieces do
		local p = piecePart(model, piece.size, WeaponLooks.colour(weapon, piece))
		p.CFrame = rest * lift * ROLL * CFrame.new(Units.toStuds(piece.offset - middle))
	end
	return model
end

-- A gun the server has put down, or one it has taken away.
local function added(folder: Instance, part: Instance)
	local id = tonumber(part.Name)
	local weapon = part:GetAttribute(GroundGuns.WEAPON)
	if not id or not part:IsA("BasePart") or typeof(weapon) ~= "string" or not WeaponConfig.Defs[weapon] then
		return
	end
	local ammo = part:GetAttribute(GroundGuns.AMMO)
	local reserve = part:GetAttribute(GroundGuns.RESERVE)
	local look = part.CFrame.LookVector
	state.guns[id] = {
		id = id,
		weapon = weapon,
		ammo = if typeof(ammo) == "number" then ammo else 0,
		reserve = if typeof(reserve) == "number" then reserve else 0,
		position = Units.toMetres(part.Position),
		yaw = math.atan2(-look.X, -look.Z),
		at = 0,
	}
	state.version += 1
	local old = looks[id]
	if old then
		old:Destroy()
	end
	local model = build(weapon, part.CFrame)
	model.Parent = folder
	looks[id] = model
end

local function removed(part: Instance)
	local id = tonumber(part.Name)
	if not id then
		return
	end
	GroundGuns.remove(state, id)
	local look = looks[id]
	if look then
		look:Destroy()
		looks[id] = nil
	end
end

-- The gun in view and within reach, if F can take one now.
local function inView(): GroundGuns.Gun?
	local sim = PlayerController.sim
	if not sim or not PlayerController.alive or sim.spike.channel ~= SpikeSim.NONE then
		return nil
	end
	if BuyMenu.open or CameraController.cursorFree then
		return nil
	end
	local eye = PlayerSim.eye(sim, PlayerController.cfg)
	local gun = GroundGuns.aimedAt(state, eye, Accuracy.aim(CameraController.yaw, CameraController.pitch))
	if gun and RobloxSpike.sees(eye, gun.position, GroundGuns.CENTRE.y) then
		return gun
	end
	return nil
end

-- F: asks for the gun in view, drawn once the server has it in its slot (at
-- once if its slot holds one of the same already, as nothing will change).
function GroundGunsView.take()
	local gun = GroundGunsView.aimed or inView()
	local slot = if gun then GroundGuns.slotOf(gun.weapon) else nil
	if not gun or not slot then
		return
	end
	Remotes.get().GroundGun:FireServer(gun.id)
	local sim = PlayerController.sim
	if sim and sim.weapons.loadout[slot] == gun.weapon then
		PlayerController.selectSlot(slot)
	else
		PlayerController.drawWhenGiven(slot, gun.weapon)
	end
end

function GroundGunsView.start()
	local drawn = Instance.new("Folder")
	drawn.Name = "VFGroundGunLooks"
	drawn.Parent = Workspace

	local outline = Instance.new("Highlight")
	outline.Name = "VFGroundGunOutline"
	outline.FillTransparency = 1
	outline.OutlineColor = OUTLINE
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Enabled = false
	outline.Parent = drawn

	local gui = Ui.screen("VFGroundGunsHud", 15, Enum.ScreenInsets.None)
	local prompt = Ui.label(gui, {
		Size = UDim2.fromOffset(400, 24),
		Position = UDim2.new(0.5, -200, 0.57, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.5,
		TextColor3 = OUTLINE,
		Visible = false,
	})

	task.spawn(function()
		local folder = Workspace:WaitForChild(GroundGuns.MODEL)
		folder.ChildAdded:Connect(function(part)
			added(drawn, part)
		end)
		folder.ChildRemoved:Connect(removed)
		for _, part in folder:GetChildren() do
			added(drawn, part)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local gun = inView()
		GroundGunsView.aimed = gun
		local look = if gun then looks[gun.id] else nil
		outline.Adornee = look
		outline.Enabled = look ~= nil
		local sim = PlayerController.sim
		local slot = if gun then GroundGuns.slotOf(gun.weapon) else nil
		if gun and slot and sim then
			local name = string.upper(WeaponConfig.get(gun.weapon).name)
			prompt.Text = if sim.weapons.loadout[slot] == "" then "F  PICK UP " .. name else "F  SWAP FOR " .. name
			prompt.Visible = true
		else
			prompt.Visible = false
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.F then
			GroundGunsView.take()
		end
	end)
end

return GroundGunsView
