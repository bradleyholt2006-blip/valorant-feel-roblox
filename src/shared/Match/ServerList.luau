--!strict
-- The list of servers and the modes they play (system 24), as plain data the
-- offline tests can check: each server keeps a line of its own in a memory
-- store shared by every server of the place (ModeServers), and PLAY picks a
-- server from the lines to send someone to.
--   * a line says which mode the server plays, how many are in the server
--     and how many in its match, how many its match and the server hold,
--     how to teleport there, and when it was last updated
--   * someone is sent to a server playing the mode they picked with a place
--     free in its match, never the one they're on: the fullest first, so
--     matches fill up and start, as Roblox fills its own servers before
--     opening new ones
--   * a line not updated for a while is a server that's gone, and sends
--     nobody
--
-- No Roblox APIs here: ModeServers reads and writes the lines and teleports.

local ServerList = {}

-- A server's line. Its key is "p:" and the JobId for a public server,
-- reached by its JobId, or "r:" and the PrivateServerId for a reserved one,
-- reached by its access code, which only the server that reserved it knew
-- and wrote in the line.
export type Line = {
	key: string,
	mode: string, -- a key of PlayConfig.ByKey
	players: number, -- in the server
	playing: number, -- in its match, on a side
	cap: number, -- places in its match
	max: number, -- places in the server
	job: string?, -- a public server's JobId
	code: string?, -- a reserved server's access code
	at: number, -- os.time() of its last update
}

-- A line's key, for a public server (by its JobId) or a reserved one (by its
-- PrivateServerId).
function ServerList.publicKey(jobId: string): string
	return "p:" .. jobId
end

function ServerList.reservedKey(privateServerId: string): string
	return "r:" .. privateServerId
end

local function count(value: any): number?
	return if typeof(value) == "number" and value == value and value >= 0 then math.floor(value) else nil
end

local function text(value: any): string?
	return if typeof(value) == "string" and value ~= "" then value else nil
end

-- A line as the memory store holds it: its key apart, the rest as a table.
function ServerList.encode(line: Line): { [string]: any }
	return {
		mode = line.mode,
		players = line.players,
		playing = line.playing,
		cap = line.cap,
		max = line.max,
		job = line.job,
		code = line.code,
		at = line.at,
	}
end

-- A line back from the memory store, or nil if anything in it is missing or
-- the wrong type, as a line from another version of the place might be.
function ServerList.decode(key: any, value: any): Line?
	if typeof(key) ~= "string" or typeof(value) ~= "table" then
		return nil
	end
	local mode, at = text(value.mode), count(value.at)
	local players, playing = count(value.players), count(value.playing)
	local cap, max = count(value.cap), count(value.max)
	if not mode or not at or not players or not playing or not cap or not max then
		return nil
	end
	return {
		key = key,
		mode = mode,
		players = players,
		playing = playing,
		cap = cap,
		max = max,
		job = text(value.job),
		code = text(value.code),
		at = at,
	}
end

-- Whether a line was updated recently enough, at `now`, to be trusted.
function ServerList.fresh(line: Line, now: number, stale: number): boolean
	return now - line.at <= stale
end

-- Whether a line says how to get there: a public server's JobId, or a
-- reserved one's access code.
local function reachable(line: Line): boolean
	if string.sub(line.key, 1, 2) == "p:" then
		return line.job ~= nil
	end
	return line.code ~= nil
end

-- The server to send `group` players to who picked `mode`, at `now`: one
-- playing it, not `self` (the key of the server they're on), up to date,
-- reachable, and with places for them in its match and the server. The
-- fullest match first, then the most in the server, then by key, so every
-- server picks the same. Nil if there's none, for a new server.
function ServerList.choose(lines: { Line }, mode: string, group: number, self: string?, now: number, stale: number): Line?
	local best: Line? = nil
	for _, line in lines do
		if
			line.mode ~= mode
			or line.key == self
			or not ServerList.fresh(line, now, stale)
			or not reachable(line)
			or line.playing + group > line.cap
			or line.players + group > line.max
		then
			continue
		end
		local b = best
		if
			not b
			or line.playing > b.playing
			or (line.playing == b.playing and line.players > b.players)
			or (line.playing == b.playing and line.players == b.players and line.key < b.key)
		then
			best = line
		end
	end
	return best
end

-- How many are in servers playing each mode, by mode, from the lines up to
-- date at `now`.
function ServerList.counts(lines: { Line }, now: number, stale: number): { [string]: number }
	local out: { [string]: number } = {}
	for _, line in lines do
		if ServerList.fresh(line, now, stale) then
			out[line.mode] = (out[line.mode] or 0) + line.players
		end
	end
	return out
end

-- The counts as Workspace's PlayConfig.COUNTS has them, in the modes'
-- order: "skirmish=6,gungame=3".
function ServerList.formatCounts(counts: { [string]: number }, order: { string }): string
	local parts = {}
	for _, key in order do
		table.insert(parts, string.format("%s=%d", key, counts[key] or 0))
	end
	return table.concat(parts, ",")
end

-- And back, for the menu.
function ServerList.parseCounts(value: any): { [string]: number }
	local out: { [string]: number } = {}
	if typeof(value) == "string" then
		for key, n in string.gmatch(value, "([%w_]+)=(%d+)") do
			out[key] = tonumber(n) :: number
		end
	end
	return out
end

return ServerList
