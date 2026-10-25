--!strict
-- Guns on the ground on the server (system 15). GroundGuns keeps them, and
-- every client sees them as a part each in Workspace.VFGroundGuns, named by
-- its id and carrying its weapon and rounds as attributes, which the client
-- draws (GroundGunsView). The parts are invisible, collide with nothing and
-- nothing hits them.
--
-- A gun let go of with G is thrown a little ahead, as the spike is: it's
-- stopped short of a wall and lands where it falls. In the spike rounds
-- (Arena sets dropOnDeath) the dead drop theirs where they fall: their
-- primary, or their sidearm if they have no primary. A gun with no ground
-- under it is lost.
--
-- Anyone alive can pick one up, on either side. Walking over it puts it in
-- its slot if that slot is empty. F (the GroundGun remote, with the gun's id)
-- takes the one in view, within reach, and swaps it for the gun in its slot,
-- which goes down where the one taken lay. The server checks F against the
-- player's own view as of their last move, with some slack for the time the
-- request took to arrive. A gun that leaves a slot takes what was bought
-- into that slot with it (ShopServer.forget).
--
-- The ground is cleared as each round of the arena or the spike rounds
-- starts (Arena), and when what's played changes.
--
-- Team Deathmatch's weapon spawners (system 28, PickupsServer) put their
-- guns here too, each where its spawner stands and marked with it (the
-- part's Spawner attribute), and they're taken the same ways; but the gun
-- one is swapped for isn't put down, as the rules give the loadout's back
-- once the spawner's is gone, and PickupsServer hears of each taken.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GroundGuns = require(Shared.Weapons.GroundGuns)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local SpikeSim = require(Shared.Spike.SpikeSim)
local RobloxSpike = require(Shared.Spike.RobloxSpike)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local ShopServer = require(script.Parent.ShopServer)

local GroundGunsServer = {}

-- Whether the dead drop their gun (the spike rounds).
GroundGunsServer.dropOnDeath = false
-- Whether a gun let go of with G goes down on the ground. In gun game
-- (system 23) it doesn't: Arena hands it straight back.
GroundGunsServer.drops = true
-- What follows a weapon spawner's gun being taken, once it's in the
-- player's hands (PickupsServer).
GroundGunsServer.spawnerTaken = nil :: ((Player, GroundGuns.Gun) -> ())?

local P = GroundGuns.Params
-- A gun let go of with no ground this far below has fallen out of the world.
local FALL_DEPTH = 50 -- metres
-- How much further and wider than a client's F reaches the server takes its
-- word for, as the view may have moved on since (estimate).
local SLACK = 0.5 -- metres
-- Where a gun is let go of from: this far above the feet, as the spike is.
local HAND = vector.create(0, 0.5, 0)

local state = GroundGuns.new()
local model: Model? = nil
local parts: { [number]: BasePart } = {}
local synced = -1
-- Each player who let go of a gun at their feet and hasn't stepped off it
-- yet, so doesn't pick it straight back up: the gun's id.
local stepOff: { [Player]: number } = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Brings the parts up to date with the state.
local function sync()
	local root = model
	if state.version == synced or not root then
		return
	end
	synced = state.version
	for id, part in parts do
		if not state.guns[id] then
			part:Destroy()
			parts[id] = nil
		end
	end
	for id, gun in state.guns do
		if parts[id] then
			continue
		end
		local part = Instance.new("Part")
		part.Name = tostring(id)
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = Vector3.new(1, 0.4, 1)
		-- Its look vector is the way its muzzle points.
		part.CFrame = CFrame.new(Units.toStuds(gun.position)) * CFrame.Angles(0, gun.yaw, 0)
		part:SetAttribute(GroundGuns.WEAPON, gun.weapon)
		part:SetAttribute(GroundGuns.AMMO, gun.ammo)
		part:SetAttribute(GroundGuns.RESERVE, gun.reserve)
		part:SetAttribute(GroundGuns.SPAWNER, gun.spawner)
		part.Parent = root
		parts[id] = part
	end
end

-- Puts a gun down on the ground under `point`; it's lost if there's none.
local function lay(weapon: string, ammo: number, reserve: number, point: vector, yaw: number): GroundGuns.Gun?
	local at = RobloxSpike.ground(point, FALL_DEPTH)
	if not at then
		return nil
	end
	return GroundGuns.add(state, weapon, ammo, reserve, at, yaw, now())
end

-- A gun taken, now in the player's hands: if it was a weapon spawner's,
-- PickupsServer hears of it.
local function taken(player: Player, gun: GroundGuns.Gun)
	local hook = GroundGunsServer.spawnerTaken
	if gun.spawner and hook then
		hook(player, gun)
	end
end

-- G: thrown a little ahead of the feet, stopped short of a wall, landing
-- where it falls.
local function onDrop(player: Player, dropped: WeaponSim.Dropped, feet: vector, yaw: number)
	if not GroundGunsServer.drops then
		return
	end
	ShopServer.forget(player, dropped.slot)
	local dir = vector.create(-math.sin(yaw), 0, -math.cos(yaw))
	local from = feet + HAND
	local gun = lay(dropped.id, dropped.ammo, dropped.reserve, from + dir * RobloxSpike.reach(from, dir, P.dropForward.value), yaw)
	if gun then
		stepOff[player] = gun.id
	end
	sync()
end

-- The dead drop their primary, or their sidearm if they have no primary,
-- where they fall.
local function onDeath(player: Player)
	local sim = PlayerSimServer.getSim(player)
	if not GroundGunsServer.dropOnDeath or not sim then
		return
	end
	local w = sim.weapons
	local slot = GroundGuns.deathSlot(w.loadout)
	if not slot then
		return
	end
	local weapon, ammo, reserve = w.loadout[slot], w.ammo[slot], w.reserve[slot]
	local _, look = PlayerSimServer.view(player)
	local yaw = if look then math.atan2(-look.x, -look.z) else 0
	-- It's on the ground now, not with them.
	PlayerSimServer.give(player, slot, "")
	ShopServer.forget(player, slot)
	lay(weapon, ammo, reserve, sim.movement.position + HAND, yaw)
	sync()
end

-- F: the gun the player says is in view, if it is, swapped for the gun in
-- its slot.
local function onTake(player: Player, id: any)
	local gun = if typeof(id) == "number" then state.guns[id] else nil
	local sim = PlayerSimServer.getSim(player)
	if not gun or not sim or not PlayerSimServer.isAlive(player) or sim.spike.channel ~= SpikeSim.NONE then
		return
	end
	local slot = GroundGuns.slotOf(gun.weapon)
	local eye, look = PlayerSimServer.view(player)
	if not slot or not eye or not look then
		return
	end
	if not GroundGuns.alongView(eye, look, gun.position, P.reach.value + SLACK, P.aimRadius.value + SLACK) then
		return
	end
	if not RobloxSpike.sees(eye, gun.position, GroundGuns.CENTRE.y) then
		return
	end
	local w = sim.weapons
	local held = w.loadout[slot]
	GroundGuns.remove(state, gun.id)
	if held ~= "" then
		-- Theirs goes down where the one they took lay, but in place of a
		-- spawner's.
		if not gun.spawner then
			GroundGuns.add(state, held, w.ammo[slot], w.reserve[slot], gun.position, gun.yaw, now())
		end
		ShopServer.forget(player, slot)
	end
	PlayerSimServer.give(player, slot, gun.weapon, gun.ammo, gun.reserve)
	taken(player, gun)
	sync()
end

-- Walking over a gun picks it up when its slot is empty.
local function walkOver()
	for _, player in Players:GetPlayers() do
		local sim = PlayerSimServer.getSim(player)
		if not sim or not PlayerSimServer.isAlive(player) then
			stepOff[player] = nil
			continue
		end
		local feet = sim.movement.position
		local skip: number? = stepOff[player]
		local left = if skip then state.guns[skip] else nil
		if skip and not (left and GroundGuns.walksOver(feet, left.position)) then
			stepOff[player] = nil
			skip = nil
		end
		local loadout = sim.weapons.loadout
		local gun = GroundGuns.walkedOver(state, feet, function(g: GroundGuns.Gun): boolean
			local slot = GroundGuns.slotOf(g.weapon)
			return g.id ~= skip and slot ~= nil and loadout[slot] == ""
		end)
		local slot = if gun then GroundGuns.slotOf(gun.weapon) else nil
		if gun and slot then
			GroundGuns.remove(state, gun.id)
			PlayerSimServer.give(player, slot, gun.weapon, gun.ammo, gun.reserve)
			taken(player, gun)
		end
	end
end

-- A weapon spawner's gun put down where it stands (`position`, metres), on
-- the spawner `spawner` (PickupsServer). Returns its id.
function GroundGunsServer.place(weapon: string, ammo: number, reserve: number, position: vector, yaw: number, spawner: number): number
	local gun = GroundGuns.add(state, weapon, ammo, reserve, position, yaw, now(), spawner)
	sync()
	return gun.id
end

-- Whether the gun `id` is still on the ground.
function GroundGunsServer.has(id: number): boolean
	return state.guns[id] ~= nil
end

-- Takes the gun `id` off the ground, if it's there: a spawner's, its stage
-- over or what's played changed.
function GroundGunsServer.remove(id: number)
	if GroundGuns.remove(state, id) then
		sync()
	end
end

-- Clears the ground: a round starts, or what's played changes.
function GroundGunsServer.clear()
	GroundGuns.clear(state)
	table.clear(stepOff)
	sync()
end

-- Once a server frame, after the players' moves.
function GroundGunsServer.step()
	walkOver()
	sync()
end

function GroundGunsServer.start()
	local root = Instance.new("Model")
	root.Name = GroundGuns.MODEL
	-- Every client has every gun, however far away it is.
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	root.Parent = Workspace
	model = root
	table.insert(PlayerSimServer.dropListeners, onDrop)
	table.insert(PlayerSimServer.deathListeners, onDeath)
	Remotes.get().GroundGun.OnServerEvent:Connect(onTake)
	Players.PlayerRemoving:Connect(function(player)
		stepOff[player] = nil
	end)
end

return GroundGunsServer
