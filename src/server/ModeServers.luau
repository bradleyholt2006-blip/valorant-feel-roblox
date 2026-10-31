--!strict
-- A server for each mode, and the Play menu's PLAY (system 24). As on Counter
-- Blox's main screen, where picking a mode teleports you "to a new Server"
-- (Hotspawn's guide), each server plays one mode, and PLAY either drops you
-- into this server's match, if it plays the mode you picked, or sends you to
-- a server that does:
--   * a server started by Roblox's own Play button (a public server) plays
--     PlayConfig.DEFAULT, Skirmish, unless the place says otherwise; one
--     reserved for a mode plays that mode, as the teleport data of whoever
--     arrives first says
--   * every public and reserved server keeps a line of its own in a memory
--     store sorted map, PlayConfig.LIST: its mode, who's in it and how to
--     get there (ServerList), updated every PlayConfig.Rules.refresh seconds
--     and soon after someone comes, goes or joins its match, and gone a
--     little after the server stops
--   * PLAY for another mode sends you to the fullest server playing it with
--     a place free in its match (ServerList.choose), or to a new server
--     reserved for it, with your mode in the teleport data; always a new
--     one for a mode played alone (Basic Training, system 72). If the
--     teleport fails (the server filled up or closed meanwhile), a new
--     server is reserved and tried once. So does PLAY for this server's
--     mode once its match is full, rather than wait in line here; a
--     player's own private server is the exception, where friends wait
--     for each other
--   * whoever arrives with a mode in their teleport data that this server
--     plays goes straight into its match, having pressed PLAY already
--   * the menu's counts of who plays each mode come from the same lines, as
--     Workspace's PlayConfig.COUNTS
--   * a place held for a player in a listed server's match under way
--     (system 69, Arena.onHold) has an entry by their UserId in a sorted
--     map of its own, PlayConfig.HELD, taken out as it's let go. Someone
--     arriving on another server whose place is held where the list says
--     is up gets the menu's RECONNECT (PlayConfig.REJOIN), which sends them
--     back there, once, to the match
-- Players start in the menu (Arena.menuFirst) on a live server, and in
-- Studio if the place's PlayConfig.MENU says so as the server starts.
--
-- Studio can't teleport ("TeleportService doesn't support playtesting in
-- Roblox Studio", Roblox's guide to teleporting), so there PLAY for another
-- mode switches this server to it, for whoever may (Tuning.canTune), as P
-- does, and the counts are this server's own. A player's own private server
-- isn't in the list, as nobody can be sent there, and its owner's PLAY
-- switches it to the mode they pick, for everyone in it.
--
-- The Play remote: a client sends a mode's key, and is told what happened:
-- "joined" (this server's match), "switched" (this server now plays it),
-- "teleporting" (with the mode's key) or "failed" (with why).

local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local MatchConfig = require(Shared.Match.MatchConfig)
local PlayConfig = require(Shared.Match.PlayConfig)
local ServerList = require(Shared.Match.ServerList)
local Remotes = require(Shared.Net.Remotes)
local TrainingConfig = require(Shared.Training.TrainingConfig)

local Arena = require(script.Parent.Arena)
local Tuning = require(script.Parent.Tuning)

local ModeServers = {}

local R = PlayConfig.Rules

-- Whether this server can send players to others and read the list (a
-- live server), and whether it's in the list (one that isn't a player's
-- own). A reserved server joins the list once its first arrival has said
-- the mode it was reserved for.
local canSend = false
local listed = false
local private = false
local reserved = false
local claimed = false
local selfKey: string? = nil
-- A reserved server's access code, from its own line: the server that
-- reserved it wrote it there.
local accessCode: string? = nil
local map: MemoryStoreSortedMap? = nil
-- Places held in matches under way (system 69), and for each player here
-- whose place is held on another server, that server's line.
local heldMap: MemoryStoreSortedMap? = nil
local rejoinTo: { [Player]: ServerList.Line } = {}
-- Players being sent away, with the mode and how many tries so far, and
-- when each last pressed PLAY to go.
local sending: { [Player]: { key: string, tries: number } } = {}
local lastSent: { [Player]: number } = {}
-- Whether who's here or in the match has changed since this server's line
-- was last written, for an update sooner than the next.
local due = false

-- The mode this server plays now (a key of PlayConfig.ByKey), from
-- Workspace's attributes; nil on the course, with Basic Training off.
function ModeServers.current(): string?
	return PlayConfig.keyOf(
		Workspace:GetAttribute(ArenaConfig.ON),
		Workspace:GetAttribute(ArenaConfig.MODE),
		Workspace:GetAttribute(MatchConfig.FORMAT),
		Workspace:GetAttribute(TrainingConfig.ON)
	)
end

-- Has the arena play a mode, as P does: the format first, so the spike
-- rounds start once, in it. Basic Training (system 72) is the course, with
-- the arena off: on before the arena goes off, and off once the arena's
-- on, so that what's played changes once.
local function setMode(key: string)
	local mode = PlayConfig.ByKey[key]
	if not mode then
		return
	end
	local arena = mode.arena
	if not arena then
		Workspace:SetAttribute(TrainingConfig.ON, true)
		Workspace:SetAttribute(ArenaConfig.ON, false)
		return
	end
	if mode.format then
		Workspace:SetAttribute(MatchConfig.FORMAT, mode.format)
	end
	Workspace:SetAttribute(ArenaConfig.MODE, arena)
	Workspace:SetAttribute(ArenaConfig.ON, true)
	Workspace:SetAttribute(TrainingConfig.ON, false)
end

local function tell(player: Player, status: string, detail: string?)
	Remotes.get().Play:FireClient(player, status, detail)
end

-- This server's line as it stands.
local function ownLine(): ServerList.Line?
	local key = ModeServers.current()
	local mode = if key then PlayConfig.ByKey[key] else nil
	local own = selfKey
	if not key or not mode or not own or (reserved and not claimed) then
		return nil
	end
	return {
		key = own,
		mode = key,
		players = #Players:GetPlayers(),
		playing = Arena.playing(),
		cap = mode.players,
		max = Players.MaxPlayers,
		job = if string.sub(own, 1, 2) == "p:" then game.JobId else nil,
		code = accessCode,
		at = os.time(),
	}
end

-- Writes this server's line, keeping the access code its reserver wrote.
local function refresh()
	local m, line = map, ownLine()
	if not m or not line then
		return
	end
	local ok, err = pcall(function()
		m:UpdateAsync(line.key, function(old: any): any
			local was = ServerList.decode(line.key, old)
			if was and was.code and not line.code then
				accessCode = was.code
				line.code = was.code
			end
			return ServerList.encode(line)
		end, R.expiry.value)
	end)
	if not ok then
		warn("[VF] Server list: couldn't update this server's line: " .. tostring(err))
	end
end

-- Every line in the list (up to 200, the most one read returns), or nil if
-- the read failed.
local function readAll(): { ServerList.Line }?
	local m = map
	if not m then
		return nil
	end
	local ok, result = pcall(function()
		return m:GetRangeAsync(Enum.SortDirection.Ascending, 200, nil, nil)
	end)
	if not ok or typeof(result) ~= "table" then
		warn("[VF] Server list: couldn't read it: " .. tostring(result))
		return nil
	end
	local out = {}
	for _, item in result do
		local line = ServerList.decode(item.key, item.value)
		if line then
			table.insert(out, line)
		end
	end
	return out
end

local ORDER: { string } = {}
for _, mode in PlayConfig.Modes do
	table.insert(ORDER, mode.key)
end

-- The menu's counts: from the list where there is one, or this server's own.
local function publishCounts(lines: { ServerList.Line }?)
	local counts: { [string]: number }
	if lines then
		counts = ServerList.counts(lines, os.time(), R.stale.value)
	else
		counts = {}
		local key = ModeServers.current()
		if key then
			counts[key] = #Players:GetPlayers()
		end
	end
	Workspace:SetAttribute(PlayConfig.COUNTS, ServerList.formatCounts(counts, ORDER))
end

-- Sends a player to a server playing `key`'s mode: the fullest with a place
-- free, unless `fresh`, or else a new one reserved for it. Returns why not,
-- if the teleport couldn't be asked for.
local function send(player: Player, key: string, fresh: boolean): string?
	local mode = PlayConfig.ByKey[key]
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ [PlayConfig.DATA_KEY] = key })
	-- A mode for one (Basic Training, system 72) always has a new server.
	local solo = mode.players <= 1
	local target = if fresh or solo then nil else ServerList.choose(readAll() or {}, key, 1, selfKey, os.time(), R.stale.value)
	if target and target.job then
		options.ServerInstanceId = target.job
	elseif target and target.code then
		options.ReservedServerAccessCode = target.code
	else
		local ok, code, privateId = pcall(function()
			return TeleportService:ReserveServerAsync(game.PlaceId)
		end)
		if not ok or typeof(code) ~= "string" or typeof(privateId) ~= "string" then
			return "Couldn't open a new server: " .. tostring(code)
		end
		options.ReservedServerAccessCode = code
		-- Its line until it writes its own: with the code, which it can't
		-- know, and this player on their way.
		local m = map
		if m then
			local line: ServerList.Line = {
				key = ServerList.reservedKey(privateId),
				mode = key,
				players = 1,
				playing = 0,
				cap = mode.players,
				max = Players.MaxPlayers,
				code = code,
				at = os.time(),
			}
			pcall(function()
				m:SetAsync(line.key, ServerList.encode(line), R.expiry.value)
			end)
		end
	end
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	return if ok then nil else tostring(err)
end

-- Sends a player back to the server whose match holds their place (system
-- 69), by its line. Returns why not, if the teleport couldn't be asked for.
local function sendBack(player: Player, line: ServerList.Line): string?
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ [PlayConfig.DATA_KEY] = line.mode })
	if line.job then
		options.ServerInstanceId = line.job
	elseif line.code then
		options.ReservedServerAccessCode = line.code
	end
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	return if ok then nil else tostring(err)
end

-- One try at sending a player away, and a second to a new server if the
-- first fails.
local function attempt(player: Player)
	local job = sending[player]
	if not job then
		return
	end
	job.tries += 1
	local why = send(player, job.key, job.tries > 1)
	if why and job.tries < 2 then
		attempt(player)
	elseif why then
		sending[player] = nil
		tell(player, "failed", why)
	end
end

local function onPlay(player: Player, key: any, rejoin: any)
	local mode = if typeof(key) == "string" then PlayConfig.ByKey[key] else nil
	if not mode or sending[player] then
		return
	end
	-- RECONNECT to a match on another server that holds their place
	-- (system 69): sent back there, with one try, as it's that server or
	-- none.
	local back = if rejoin == true then rejoinTo[player] else nil
	if back and back.mode == key then
		rejoinTo[player] = nil
		player:SetAttribute(PlayConfig.REJOIN, nil)
		local job = { key = key, tries = 2 }
		sending[player] = job
		tell(player, "teleporting", key)
		task.spawn(function()
			local why = sendBack(player, back)
			if why and sending[player] == job then
				sending[player] = nil
				tell(player, "failed", why)
			end
		end)
		task.delay(R.teleportWait.value, function()
			if sending[player] == job then
				sending[player] = nil
				tell(player, "failed", "The teleport took too long")
			end
		end)
		return
	end
	local own = private and game.PrivateServerOwnerId == player.UserId
	if key == ModeServers.current() then
		-- This server's match, with a place in it or one held for them, or
		-- where nobody's sent anywhere else; once it's full, a server of
		-- the mode with one.
		if Arena.has(player) or Arena.holds(player) or not canSend or private or Arena.playing() < mode.players then
			Arena.play(player)
			due = true
			tell(player, "joined", key)
			return
		end
	elseif not canSend or own then
		-- Studio, or the owner of this private server: this server switches.
		if own or Tuning.canTune(player) then
			Arena.play(player)
			setMode(key)
			tell(player, "switched", key)
		else
			tell(player, "failed", "Studio can't send you to another server")
		end
		return
	end
	local last = lastSent[player]
	if last and os.clock() - last < R.cooldown.value then
		tell(player, "failed", "Just a moment: try again")
		return
	end
	lastSent[player] = os.clock()
	local job = { key = key, tries = 0 }
	sending[player] = job
	tell(player, "teleporting", key)
	task.spawn(attempt, player)
	-- A teleport that neither arrives nor fails is given up on.
	task.delay(R.teleportWait.value, function()
		if sending[player] == job then
			sending[player] = nil
			tell(player, "failed", "The teleport took too long")
		end
	end)
end

-- The mode someone's teleport data says they pressed PLAY for, if any.
local function arrivedFor(player: Player): string?
	local data = player:GetJoinData().TeleportData
	local key = if typeof(data) == "table" then (data :: any)[PlayConfig.DATA_KEY] else nil
	return if typeof(key) == "string" and PlayConfig.ByKey[key] then key else nil
end

-- Whether a place is held for someone arriving in a match on another
-- server that's still up (system 69), for the menu's RECONNECT.
local function checkHeld(player: Player)
	local held, list = heldMap, map
	if not held or not list then
		return
	end
	local ok, value = pcall(function()
		return held:GetAsync(tostring(player.UserId))
	end)
	local entry = if ok then ServerList.decodeHeld(value) else nil
	if not entry or entry.server == selfKey then
		return
	end
	local okLine, raw = pcall(function()
		return list:GetAsync(entry.server)
	end)
	local line = if okLine then ServerList.decode(entry.server, raw) else nil
	if line and ServerList.canRejoin(line, entry, os.time(), R.stale.value) and player.Parent then
		rejoinTo[player] = line
		player:SetAttribute(PlayConfig.REJOIN, entry.mode)
	end
end

-- A place held for a player in this server's match (system 69), as they
-- leave it: its entry, for another server they come back to.
local function holdHere(id: number, key: string)
	local held, own = heldMap, selfKey
	if not held or not own or id <= 0 then
		return
	end
	task.spawn(function()
		local ok, err = pcall(function()
			held:SetAsync(tostring(id), ServerList.encodeHeld({ server = own, mode = key }), R.heldFor.value)
		end)
		if not ok then
			warn("[VF] Held places: couldn't write one: " .. tostring(err))
		end
	end)
end

-- A place held here let go (system 69): its entry out, unless it's since
-- been written for another server's.
local function letGo(id: number)
	local held, own = heldMap, selfKey
	if not held or not own or id <= 0 then
		return
	end
	task.spawn(function()
		pcall(function()
			local key = tostring(id)
			local entry = ServerList.decodeHeld(held:GetAsync(key))
			if entry and entry.server == own then
				held:RemoveAsync(key)
			end
		end)
	end)
end

-- Someone arriving: a reserved server takes on the mode its first arrival
-- says it was reserved for, and whoever pressed PLAY for this server's mode
-- joins its match. Anyone else may have a place held elsewhere (system
-- 69).
local function arrive(player: Player)
	due = true
	local key = arrivedFor(player)
	if not key then
		task.spawn(checkHeld, player)
		return
	end
	if reserved and not claimed then
		claimed = true
		if key ~= ModeServers.current() then
			setMode(key)
		end
	end
	if key == ModeServers.current() then
		Arena.play(player)
	end
end

-- Before Arena.start, so that menuFirst holds from the first player.
function ModeServers.start()
	local studio = RunService:IsStudio()
	local menu = Workspace:GetAttribute(PlayConfig.MENU) == true or not studio
	Workspace:SetAttribute(PlayConfig.MENU, menu)
	Arena.menuFirst = menu
	reserved = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
	private = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
	canSend = not studio
	listed = canSend and not private
	if canSend then
		map = MemoryStoreService:GetSortedMap(PlayConfig.LIST)
		heldMap = MemoryStoreService:GetSortedMap(PlayConfig.HELD)
	end
	if listed then
		selfKey = if reserved then ServerList.reservedKey(game.PrivateServerId) else ServerList.publicKey(game.JobId)
	end
	if canSend and not reserved and Workspace:GetAttribute(ArenaConfig.MODE) == nil then
		setMode(PlayConfig.DEFAULT)
	end
	-- Only a listed server can be sent back to, so only its holds are
	-- written (system 69).
	if listed then
		Arena.onHold = holdHere
		Arena.onRelease = letGo
	end

	Remotes.get().Play.OnServerEvent:Connect(onPlay)
	-- A teleport asked for can still fail on its way (Roblox: it "can still
	-- fail at the last moment without throwing an error"): once more, to a
	-- new server.
	TeleportService.TeleportInitFailed:Connect(function(player: Player, result: Enum.TeleportResult, message: string)
		local job = sending[player]
		if not job then
			return
		elseif job.tries < 2 and result ~= Enum.TeleportResult.Flooded then
			task.spawn(attempt, player)
		else
			sending[player] = nil
			tell(
				player,
				"failed",
				if result == Enum.TeleportResult.Flooded then "Too many teleports just now: try again in a moment" else message
			)
		end
	end)
	Players.PlayerAdded:Connect(arrive)
	for _, player in Players:GetPlayers() do
		arrive(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		sending[player] = nil
		lastSent[player] = nil
		rejoinTo[player] = nil
		due = true
	end)

	if listed then
		game:BindToClose(function()
			local m, own = map, selfKey
			if m and own then
				pcall(function()
					m:RemoveAsync(own)
				end)
			end
		end)
	end
	-- Studio's counts are its own, so they cost nothing to keep up to date.
	local countEvery = if canSend then R.listEvery.value else 1
	task.spawn(function()
		local refreshedAt, countedAt = -math.huge, -math.huge
		while true do
			local t = os.clock()
			local since = t - refreshedAt
			if listed and (since >= R.refresh.value or (due and since >= R.soonest.value)) then
				refreshedAt = t
				due = false
				refresh()
			end
			if t - countedAt >= countEvery then
				countedAt = t
				publishCounts(if canSend then readAll() else nil)
			end
			task.wait(1)
		end
	end)
end

return ModeServers
