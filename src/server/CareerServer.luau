--!strict
-- Keeps each player's career (system 67) from one session to the next, in
-- a data store: their Competitive rank and their totals in each mode
-- (CareerRules). The arena says when a match ends (CareerServer.finished),
-- whose places in it are held while they're away (CareerServer.hold,
-- system 69), and as the server closes, who's away from a Competitive
-- match still under way (CareerServer.left). Each player's part is added
-- at once to the career their screen shows, and to the store's through
-- UpdateAsync, so it's added to whatever's there, from however many
-- servers they've played on, and only once, by its id.
--
-- On joining, what's kept is read, and the player's attributes say it:
-- RankConfig's for the rank (and in Studio the hidden MMR, for checks;
-- never on a live server) and CareerRules.ATTRIBUTE for the totals, with
-- CareerRules.STATUS for how keeping them goes. In Studio each result
-- prints what it did, for checks. A read that fails keeps this session's
-- results out of the store, as what it holds is unknown. A write goes at
-- most once every WRITE_GAP seconds, the data store's limit for one key,
-- and one that fails is tried again, TRIES times in all. A player who
-- leaves is kept LINGER seconds, or while their place in a match is held,
-- and until what's theirs is written; the server closing writes
-- everything still to write.
--
-- A place that can't use data stores (Studio, unless the place's own game
-- settings let it) still works: the career lasts the session, and the
-- status says why it isn't kept. So does a Local Server's test player in
-- Studio (a UserId under 1), whose career would otherwise come back for
-- the next test.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BotConfig = require(Shared.Bots.BotConfig)
local CareerRules = require(Shared.Career.CareerRules)
local RankConfig = require(Shared.Career.RankConfig)
local RankRules = require(Shared.Career.RankRules)

local CareerServer = {}

CareerServer.STORE = "VFCareer1"
CareerServer.WRITE_GAP = 6
CareerServer.TRIES = 3
CareerServer.LINGER = 10

type Record = {
	userId: number,
	player: Player?, -- nil once they've left
	goneAt: number?,
	loaded: boolean, -- the read has come back (or there's nothing to read from)
	career: CareerRules.Record, -- the store's, as read or last written, with every result since
	pending: { CareerRules.Result }, -- results not yet written
	lastWrite: number,
	writing: boolean,
	scheduled: boolean,
	failures: number,
	status: string,
	off: string?, -- why this player's career can't be kept
	held: boolean, -- their place in a match under way is held while they're away (system 69)
}

-- By UserId, players who've left included, until they're forgotten.
local records: { [number]: Record } = {}
local store: DataStore? = nil
local storeOff: string? = nil

-- Why the store can't be used, in words for the status.
local function reason(err: any): string
	warn("[VF] career: " .. tostring(err))
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
		return DataStoreService:GetDataStore(CareerServer.STORE)
	end)
	if ok then
		store = result
	else
		storeOff = reason(result)
	end
	return store
end

local function keyOf(userId: number): string
	return "player_" .. userId
end

local function setStatus(r: Record, status: string)
	r.status = status
	local player = r.player
	if player then
		player:SetAttribute(CareerRules.STATUS, status)
	end
end

local function turnOff(r: Record, why: string)
	r.off = why
	setStatus(r, "off: " .. why)
end

-- The career on the player, for their screen and everyone's scoreboard.
local function publish(r: Record)
	local player = r.player
	if not player then
		return
	end
	local rank = r.career.rank
	player:SetAttribute(RankConfig.TIER, RankRules.shown(rank))
	player:SetAttribute(RankConfig.RR, rank.rr)
	player:SetAttribute(RankConfig.GAMES, rank.games)
	player:SetAttribute(RankConfig.SHIELDS, rank.shields)
	player:SetAttribute(CareerRules.ATTRIBUTE, CareerRules.toText(r.career))
	if RunService:IsStudio() then
		player:SetAttribute(RankConfig.MMR, math.round(rank.mmr))
	end
end

-- Drops a record once its player's been gone LINGER seconds with nothing
-- left to write that can be.
local function forget(r: Record)
	local goneAt = r.goneAt
	if
		r.player == nil
		and goneAt
		and os.clock() - goneAt >= CareerServer.LINGER
		and not r.held
		and not r.writing
		and (r.off or #r.pending == 0)
		and records[r.userId] == r
	then
		records[r.userId] = nil
	end
end

-- Writes the results not yet written, waiting out WRITE_GAP unless `now`
-- (the server is closing).
local function write(r: Record, now: boolean?)
	if r.off or r.writing or not r.loaded or #r.pending == 0 then
		return
	end
	local wait = r.lastWrite + CareerServer.WRITE_GAP - os.clock()
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
	local batch = table.clone(r.pending)
	r.writing = true
	r.lastWrite = os.clock()
	setStatus(r, "saving")
	local ok, value = pcall(function()
		return ds:UpdateAsync(keyOf(r.userId), function(old: any)
			local career = CareerRules.decode(old)
			for _, result in batch do
				CareerRules.apply(career, result)
			end
			return CareerRules.encode(career), { r.userId }
		end)
	end)
	r.writing = false
	if not ok then
		r.failures += 1
		if r.failures >= CareerServer.TRIES then
			turnOff(r, reason(value))
		else
			warn("[VF] career: " .. tostring(value))
			write(r, now)
		end
		forget(r)
		return
	end
	r.failures = 0
	for _, result in batch do
		local i = table.find(r.pending, result)
		if i then
			table.remove(r.pending, i)
		end
	end
	-- What the store holds now, with anything that's come in since.
	local career = CareerRules.decode(value)
	for _, result in r.pending do
		CareerRules.apply(career, result)
	end
	r.career = career
	publish(r)
	setStatus(r, "saved")
	write(r, now)
	forget(r)
end

local function load(r: Record)
	setStatus(r, "loading")
	if r.userId <= 0 then
		-- A Local Server's test player in Studio: what's kept under its id
		-- would come back for the next test's, so nothing is.
		r.loaded = true
		turnOff(r, "a test player")
		publish(r)
		return
	end
	local ds = getStore()
	if not ds then
		r.loaded = true
		turnOff(r, storeOff or "no data store")
		publish(r)
		return
	end
	local ok, value = pcall(function()
		return ds:GetAsync(keyOf(r.userId))
	end)
	r.loaded = true
	if not ok then
		turnOff(r, reason(value))
		publish(r)
		return
	end
	-- What's kept, with whatever's come in while the read was out.
	local career = CareerRules.decode(value)
	for _, result in r.pending do
		CareerRules.apply(career, result)
	end
	r.career = career
	publish(r)
	setStatus(r, if value == nil then "new" else "loaded")
	write(r)
end

local function added(player: Player)
	local r = records[player.UserId]
	if r then
		-- Back before they were forgotten: as they were.
		r.player = player
		r.goneAt = nil
		setStatus(r, r.status)
		if r.loaded then
			publish(r)
		end
		return
	end
	local new: Record = {
		userId = player.UserId,
		player = player,
		goneAt = nil,
		loaded = false,
		career = CareerRules.new(),
		pending = {},
		lastWrite = -math.huge,
		writing = false,
		scheduled = false,
		failures = 0,
		status = "loading",
		off = nil,
		held = false,
	}
	records[player.UserId] = new
	task.spawn(load, new)
end

-- An MMR for each player in a match: a player's own, or a new player's
-- until it's read; a bot's by the skill bots play at.
local function mmrOf(id: number, p: CareerRules.Player): number
	if p.bot then
		return RankConfig.botMmr(Workspace:GetAttribute(BotConfig.SKILL))
	end
	local r = records[id]
	return if r then r.career.rank.mmr else RankConfig.Rules.mmrStart.value
end

local function newId(): string
	return HttpService:GenerateGUID(false)
end

-- A result added to a player's career at once and written when it can be.
-- Returns what it did to their rank, if it moved it.
local function add(r: Record, result: CareerRules.Result): RankRules.Change?
	local change = CareerRules.apply(r.career, result)
	table.insert(r.pending, result)
	publish(r)
	-- Written on its own, so what the result did to the rank goes out with
	-- the rank, not after the store's answer (half a second and more), and
	-- the next player's waits for nothing.
	task.spawn(write, r)
	if RunService:IsStudio() then
		-- For checks: what each result did.
		local rank = r.career.rank
		local moved = if change then string.format(" %s%d RR %s", if change.rr < 0 then "" else "+", change.rr, change.note or "") else ""
		print(
			string.format(
				"[VF] career: %d %s %s%s; %s, MMR %d",
				r.userId,
				result.mode,
				result.outcome,
				moved,
				RankRules.line(RankRules.shown(rank), rank.rr, rank.games),
				math.round(rank.mmr)
			)
		)
	end
	return change
end

-- A match has ended: each player's part in it. Anyone in it it doesn't
-- count for has the last match's change to their rank cleared, so their
-- victory screen shows none.
function CareerServer.finished(match: CareerRules.Match)
	local results = CareerRules.results(match, mmrOf, newId)
	for id, p in match.players do
		local r = records[id]
		if p.bot or not r then
			continue
		end
		local result = results[id]
		local change = if result then add(r, result) else nil
		local player = r.player
		if player then
			player:SetAttribute(RankConfig.LAST, if change then change.rr else nil)
			player:SetAttribute(RankConfig.NOTE, if change then change.note else nil)
		end
	end
end

-- Someone, by their UserId, has left a match under way and isn't back as
-- the server closes (`match` as it stands, with them in it): their part,
-- if leaving counts (CareerRules.left).
function CareerServer.left(match: CareerRules.Match, id: number)
	local r = records[id]
	local result = if r then CareerRules.left(match, id, mmrOf, newId) else nil
	if r and result then
		add(r, result)
	end
end

-- A player's place in a match is held while they're away from it (system
-- 69), or let go (they're back, or it's over): their record is kept for
-- what the match's end counts for them.
function CareerServer.hold(id: number, on: boolean)
	local r = records[id]
	if not r then
		return
	end
	r.held = on
	if not on then
		forget(r)
	end
end

-- Called as the server closes, before what's left is written: the arena's
-- word on matches still under way (system 69). The arena sets it.
CareerServer.beforeClose = nil :: (() -> ())?

function CareerServer.start()
	Players.PlayerAdded:Connect(added)
	for _, player in Players:GetPlayers() do
		added(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		local r = records[player.UserId]
		if not r or r.player ~= player then
			return
		end
		r.player = nil
		r.goneAt = os.clock()
		write(r)
		task.delay(CareerServer.LINGER, forget, r)
	end)
	-- Closing: the arena's word on matches under way, then everything
	-- still to write, now, for up to 20 seconds.
	game:BindToClose(function()
		local before = CareerServer.beforeClose
		if before then
			before()
		end
		local deadline = os.clock() + 20
		while os.clock() < deadline do
			local busy = false
			for _, r in records do
				if r.writing then
					busy = true
				elseif not r.off and r.loaded and #r.pending > 0 then
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

return CareerServer
