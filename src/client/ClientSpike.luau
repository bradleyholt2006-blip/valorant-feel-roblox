--!strict
-- The spike as this client knows it (system 12): the server's state of it,
-- from Workspace's attributes (Spike.STATE and the rest), for the HUD and
-- the spike's model and sounds, and what the local player may do with it,
-- for PlayerController's prediction of the plant and the defuse: in the
-- spike rounds (system 13), plant it only while a round is live, and defuse
-- it only on the defending side. With it, the spike rounds' Ultimate Orbs
-- up (system 49, Workspace's UltimateOrbs.UP), for the prediction of their
-- taking, the HUD and the minimap.
--
-- A defuse of ours let go of past the half is saved straight away here, as
-- the server saves it when it runs the same tick, so the next defuse is
-- predicted from the half without waiting a round trip to hear of it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local Spike = require(Shared.Spike.Spike)
local SpikeSim = require(Shared.Spike.SpikeSim)
local RobloxSpike = require(Shared.Spike.RobloxSpike)
local UltimateOrbs = require(Shared.Spike.UltimateOrbs)
local Units = require(Shared.Units)

export type View = {
	layout: string, -- "" while there's no spike
	state: string, -- Spike.STATE's values
	carrier: number, -- id in the rules (a UserId, or a bot's), 0 for none
	position: vector?, -- metres: lying, planted, or where it ended
	plantedAt: number, -- server time
	halfSaved: boolean,
	site: string,
	endedAt: number, -- server time
}

local ClientSpike = {}

local ATTRIBUTES = {
	Spike.LAYOUT,
	Spike.STATE,
	Spike.CARRIER,
	Spike.POSITION,
	Spike.PLANTED_AT,
	Spike.HALF,
	Spike.SITE,
	Spike.ENDED_AT,
	Spike.PLANT_OPEN,
	Spike.DEFUSERS,
	UltimateOrbs.UP,
}

local view: View = { layout = "", state = "none", carrier = 0, position = nil, plantedAt = 0, halfSaved = false, site = "", endedAt = 0 }
local context: Spike.Context = Spike.NONE
local orbs: { [number]: vector } = {}
-- Our own defuse let go of past the half, for the plant at this time.
local halfOf: number? = nil

local function rebuild()
	local position = Workspace:GetAttribute(Spike.POSITION)
	local layout = Workspace:GetAttribute(Spike.LAYOUT)
	local state = Workspace:GetAttribute(Spike.STATE)
	local site = Workspace:GetAttribute(Spike.SITE)
	view = {
		layout = if typeof(layout) == "string" then layout else "",
		state = if typeof(state) == "string" then state else "none",
		carrier = tonumber(Workspace:GetAttribute(Spike.CARRIER)) or 0,
		position = if typeof(position) == "Vector3" then Units.asVector(position) else nil,
		plantedAt = tonumber(Workspace:GetAttribute(Spike.PLANTED_AT)) or 0,
		halfSaved = Workspace:GetAttribute(Spike.HALF) == true,
		site = if typeof(site) == "string" then site else "",
		endedAt = tonumber(Workspace:GetAttribute(Spike.ENDED_AT)) or 0,
	}
	orbs = UltimateOrbs.decode(view.layout, Workspace:GetAttribute(UltimateOrbs.UP))
	local zones = Spike.Layouts[view.layout]
	if not zones then
		context = Spike.NONE
		return
	end
	local planted = if view.state == "planted" then view.position else nil
	local me = Players.LocalPlayer
	local defusers = tonumber(Workspace:GetAttribute(Spike.DEFUSERS)) or 0
	context = {
		zones = zones,
		canPlant = view.state == "carried" and view.carrier == me.UserId and Workspace:GetAttribute(Spike.PLANT_OPEN) ~= false,
		canDefuse = planted ~= nil and (defusers == 0 or me:GetAttribute(ArenaConfig.SIDE) == defusers),
		planted = planted,
		halfSaved = view.halfSaved or (halfOf ~= nil and halfOf == view.plantedAt),
		sees = RobloxSpike.sees,
		orbs = if next(orbs) then orbs else nil,
	}
end

-- The server's spike, as last heard.
function ClientSpike.view(): View
	return view
end

-- What the local player may do with the spike now (PlayerController.objective).
function ClientSpike.context(): Spike.Context
	return context
end

-- The Ultimate Orbs up, by number, where each stands (system 49).
function ClientSpike.orbs(): { [number]: vector }
	return orbs
end

-- Whether the local player's side carries the spike: anyone's on the course,
-- the attackers' in the spike rounds (the side that doesn't defuse it).
function ClientSpike.ours(): boolean
	local defusers = tonumber(Workspace:GetAttribute(Spike.DEFUSERS)) or 0
	return defusers == 0 or Players.LocalPlayer:GetAttribute(ArenaConfig.SIDE) ~= defusers
end

-- What happened with the spike in the local player's simulation, on a live
-- tick.
function ClientSpike.onAct(act: SpikeSim.Act)
	if act.kind == "stopped" and view.state == "planted" and act.progress >= Spike.Params.defuseHalf.value - 1e-9 then
		halfOf = view.plantedAt
		rebuild()
	end
end

function ClientSpike.start()
	for _, name in ATTRIBUTES do
		Workspace:GetAttributeChangedSignal(name):Connect(rebuild)
	end
	Players.LocalPlayer:GetAttributeChangedSignal(ArenaConfig.SIDE):Connect(rebuild)
	rebuild()
end

return ClientSpike
