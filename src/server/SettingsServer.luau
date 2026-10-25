--!strict
-- Keeps each player's settings (system 11) from one session to the next, in
-- a data store. They only change what that player's own screen does (how
-- fast the view turns, the crosshair), so the server checks them and keeps
-- them and does nothing else with them.
--
-- On joining, what was kept goes in the player's PlayerSettings.ATTRIBUTE,
-- once, and PlayerSettings.STATUS_ATTRIBUTE says how that went. The Settings
-- remote brings each change, held to its limits by PlayerSettings.fromText
-- (a broken crosshair code is the default). A change is written at most once
-- every WRITE_GAP seconds, the data store's limit for one key, and when the
-- player leaves.
--
-- A place that can't use data stores (Studio, unless the place's own game
-- settings let it) still works: the settings last the session, and the
-- status says why they aren't kept.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerSettings = require(Shared.Settings.PlayerSettings)
local Remotes = require(Shared.Net.Remotes)

local SettingsServer = {}

SettingsServer.STORE = "VFSettings1"
SettingsServer.WRITE_GAP = 6

type Record = {
	player: Player,
	loaded: boolean, -- the read has come back (or there's nothing to read from)
	pending: string?, -- the newest settings, not yet written
	written: string?, -- what the store holds
	lastWrite: number,
	writing: boolean,
	scheduled: boolean,
	off: string?, -- why this player's settings can't be kept
}

local records: { [Player]: Record } = {}
-- Players who left with a change still to write.
local leaving: { [Record]: boolean } = {}
local store: DataStore? = nil
local storeOff: string? = nil

-- Why the store can't be used, in words for the settings menu.
local function reason(err: any): string
	warn("[VF] settings: " .. tostring(err))
	if RunService:IsStudio() then
		return "Studio can't use data stores in this place (the switch is in Game Settings, Security)"
	end
	return "the data store didn't answer"
end

local function getStore(): DataStore?
	if store or storeOff then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(SettingsServer.STORE)
	end)
	if ok then
		store = result
	else
		storeOff = reason(result)
	end
	return store
end

local function keyOf(player: Player): string
	return "player_" .. player.UserId
end

local function setStatus(r: Record, status: string)
	r.player:SetAttribute(PlayerSettings.STATUS_ATTRIBUTE, status)
end

local function turnOff(r: Record, why: string)
	r.off = why
	setStatus(r, "off: " .. why)
end

-- Writes the newest settings if they're new, waiting out WRITE_GAP unless
-- `now` (the server is closing).
local function write(r: Record, now: boolean?)
	local text = r.pending
	if r.off or r.writing or not r.loaded or text == nil or text == r.written then
		return
	end
	local wait = r.lastWrite + SettingsServer.WRITE_GAP - os.clock()
	if wait > 0 and not now then
		if not r.scheduled then
			r.scheduled = true
			task.delay(wait, function()
				r.scheduled = false
				write(r)
			end)
		end
		return
	end
	local ds = getStore()
	if not ds then
		turnOff(r, storeOff or "no data store")
		return
	end
	r.writing = true
	r.lastWrite = os.clock()
	setStatus(r, "saving")
	local ok, err = pcall(function()
		ds:SetAsync(keyOf(r.player), text, { r.player.UserId })
	end)
	r.writing = false
	if not ok then
		turnOff(r, reason(err))
		return
	end
	r.written = text
	setStatus(r, "saved")
	-- A change that came in while this one was being written.
	if r.pending ~= text then
		write(r, now)
	elseif not records[r.player] then
		leaving[r] = nil
	end
end

-- Whether a record still has a change to write.
local function unwritten(r: Record): boolean
	return r.off == nil and r.loaded and r.pending ~= nil and r.pending ~= r.written
end

local function load(r: Record)
	setStatus(r, "loading")
	local ds = getStore()
	if not ds then
		r.loaded = true
		turnOff(r, storeOff or "no data store")
		return
	end
	local ok, value = pcall(function()
		return ds:GetAsync(keyOf(r.player))
	end)
	r.loaded = true
	if not ok then
		turnOff(r, reason(value))
		return
	end
	if type(value) == "string" then
		local text = PlayerSettings.toText(PlayerSettings.fromText(value))
		r.written = text
		r.player:SetAttribute(PlayerSettings.ATTRIBUTE, text)
		setStatus(r, "loaded")
	else
		setStatus(r, "new")
	end
	-- Changed while the read was out.
	write(r)
end

local function added(player: Player)
	if records[player] then
		return
	end
	local r: Record = {
		player = player,
		loaded = false,
		pending = nil,
		written = nil,
		lastWrite = -math.huge,
		writing = false,
		scheduled = false,
		off = nil,
	}
	records[player] = r
	task.spawn(load, r)
end

function SettingsServer.start()
	Remotes.get().Settings.OnServerEvent:Connect(function(player: Player, text: any)
		local r = records[player]
		if not r or typeof(text) ~= "string" or #text > PlayerSettings.MAX_TEXT then
			return
		end
		r.pending = PlayerSettings.toText(PlayerSettings.fromText(text))
		write(r)
	end)
	Players.PlayerAdded:Connect(added)
	for _, player in Players:GetPlayers() do
		added(player)
	end
	-- Leaving: the last change is written once the gap allows.
	Players.PlayerRemoving:Connect(function(player)
		local r = records[player]
		records[player] = nil
		if r and unwritten(r) then
			leaving[r] = true
			write(r)
		end
	end)
	-- Closing: everything still to write, now, for up to 20 seconds.
	game:BindToClose(function()
		local all: { Record } = {}
		for _, r in records do
			table.insert(all, r)
		end
		for r in leaving do
			table.insert(all, r)
		end
		local deadline = os.clock() + 20
		while os.clock() < deadline do
			local busy = false
			for _, r in all do
				if r.writing then
					busy = true
				elseif unwritten(r) then
					busy = true
					task.spawn(write, r, true)
				end
			end
			if not busy then
				break
			end
			task.wait(0.1)
		end
	end)
end

return SettingsServer
