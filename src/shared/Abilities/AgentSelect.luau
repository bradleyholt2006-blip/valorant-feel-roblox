--!strict
-- Agent select (system 29): each player's agent, picked as the reference's
-- agent select has it, for matches that never stop. Plain state, like
-- ArenaRules, so the offline tests can play it; the server's AgentServer
-- hears the picks and puts each on the player's kit (AbilityServer).
--
-- The reference picks before each match, in its lobby: 'Agent Select,
-- which lasts for 90 seconds'; 'The player's choice is only confirmed when
-- they "Lock In" their agent choice', and when time's up 'the game will
-- automatically lock in the last agent that the player had selected'. 'Once
-- locked in, a player cannot change their chosen agent' (VALORANT Wiki,
-- 'Unrated'; community). Our matches have no lobby: one follows another,
-- and players drop into them under way. So each player has a window once a
-- match, from its start or from when they join it under way, for
-- AbilityConfig.Select.time, inside every mode's first phase. What they've
-- selected is locked in as it closes, if they haven't locked it in before,
-- and from then the agent is theirs until the match is over. A window
-- starts with the agent they last played selected, so whoever doesn't pick
-- plays on as before (the reference's match is cancelled instead). Where
-- nothing's at stake (the course, a mode waiting for players), an agent
-- locked in is theirs at once, as often as they like.
--
-- One of each agent on a side (system 48), as the same page has it: 'Each
-- player within a team must select a unique agent'. An agent a teammate
-- has locked in is taken: it can't be selected or locked in, and a
-- selection it's taken from moves back to the agent the player plays, or
-- else to the first that's free, so the time running out never locks in a
-- taken one. First come, first served, as the reference's locking in is:
-- of windows closing at once on one agent, the first player on the server
-- keeps it. The two sides can both play an agent, as the reference's can.
-- A window is for a side of a match, so someone moved across to even the
-- sides has another for their new side, and so does someone back in a
-- match to find their agent taken meanwhile. With fewer agents than a side
-- has players, once every agent is taken none is, and any can be played
-- twice.
--
-- Where a player is, for picking: FREE, a key for their side of a match
-- (any string that's that side's alone, from the server), or nil where
-- nobody picks (gun game and deathmatch, which have no abilities, between
-- matches, and outside what's played).
--
-- No Roblox APIs here.

local AbilityConfig = require("./AbilityConfig")
local AbilitySim = require("./AbilitySim")

-- Where a player stands: "free" (an agent locked in is theirs at once),
-- "open" (their window's open), "locked" (theirs until the match is over)
-- or "none" (nobody picks where they are).
export type Status = "free" | "open" | "locked" | "none"

export type Pick = {
	agent: string, -- the agent they play: their kit's, or from their next life
	selected: string, -- what locking in would make theirs, which teammates see
	status: Status,
	closesAt: number, -- while open: when the window closes, in server time
	match: string?, -- the side of a match their last window was for
}

export type State = {
	picks: { [number]: Pick }, -- by player id
	agents: { string }, -- the agents to pick from, in the order they're shown
}

local AgentSelect = {}

AgentSelect.FREE = "free"

-- Each player's attributes, as the server keeps them: the agent they play,
-- what they've selected (while they can pick), their Status (unset for
-- "none"), and while their window's open, when it closes (server time).
AgentSelect.AGENT = "VFAgent"
AgentSelect.SELECTED = "VFAgentSelected"
AgentSelect.STATUS = "VFAgentPick"
AgentSelect.CLOSES = "VFAgentCloses"

-- Whether an agent has an ability that can be played.
local function playable(id: string): boolean
	local agent = AbilityConfig.Agents[id]
	if agent then
		for _, ability in agent.abilities do
			if AbilitySim.playable(ability) then
				return true
			end
		end
	end
	return false
end

-- The agents that can be picked: each with an ability that can be played,
-- in AbilityConfig.AgentIds' order. An agent whose kit is being made comes
-- in with its first ability.
function AgentSelect.pickable(): { string }
	local out = {}
	for _, id in AbilityConfig.AgentIds do
		if playable(id) then
			table.insert(out, id)
		end
	end
	return out
end

-- With `agents` to pick from, or every agent that can be picked.
function AgentSelect.new(agents: { string }?): State
	return { picks = {}, agents = agents or AgentSelect.pickable() }
end

function AgentSelect.canPick(s: State, agent: string): boolean
	return table.find(s.agents, agent) ~= nil
end

-- A player's pick: as they're first seen, the default agent, and nothing to
-- pick.
function AgentSelect.pickOf(s: State, id: number): Pick
	local pick = s.picks[id]
	if not pick then
		local agent = AbilityConfig.DEFAULT_AGENT
		pick = { agent = agent, selected = agent, status = "none", closesAt = 0, match = nil }
		s.picks[id] = pick
	end
	return pick
end

-- The agent a player plays.
function AgentSelect.agentOf(s: State, id: number): string
	return AgentSelect.pickOf(s, id).agent
end

-- Of `agents`, those taken by `locked`, the agents a player's teammates
-- have locked in; but once every one of `agents` is taken none is, as with
-- fewer agents than a side has players some must be played twice. The
-- server's rule (AgentSelect.taken), and the menu's from attributes.
function AgentSelect.takenOf(agents: { string }, locked: { string }): { [string]: boolean }
	local taken = {}
	for _, agent in locked do
		taken[agent] = true
	end
	for _, agent in agents do
		if not taken[agent] then
			return taken
		end
	end
	return {}
end

-- The agents taken from a player while they're in a match (their window
-- open, or locked in): those their teammates have locked in, a teammate
-- being anyone else locked in on the same side of the same match now.
function AgentSelect.taken(s: State, id: number): { [string]: boolean }
	local pick = s.picks[id]
	local locked = {}
	if pick and (pick.status == "open" or pick.status == "locked") then
		for other, mate in s.picks do
			if other ~= id and mate.status == "locked" and mate.match == pick.match then
				table.insert(locked, mate.agent)
			end
		end
	end
	return AgentSelect.takenOf(s.agents, locked)
end

-- What a player has selected in place of a taken agent: the one they play
-- if it's free, or else the first that's free.
local function fallback(s: State, pick: Pick, taken: { [string]: boolean }): string
	if not taken[pick.agent] and AgentSelect.canPick(s, pick.agent) then
		return pick.agent
	end
	for _, agent in s.agents do
		if not taken[agent] then
			return agent
		end
	end
	return pick.agent
end

-- What's selected becomes theirs.
local function lockIn(pick: Pick)
	pick.agent = pick.selected
	pick.closesAt = 0
end

-- A window opens, with `agent` selected.
local function open(pick: Pick, agent: string, now: number)
	pick.status = "open"
	pick.selected = agent
	pick.closesAt = now + AbilityConfig.Select.time.value
end

-- A pick moves on to where its player is (FREE, a key for their side of a
-- match, or nil): a window that's open closes once they're out of its side
-- of the match, what's selected locked in, and one opens the first time
-- they're on another. Returns whether they're back on the side of a match
-- they've had their window in, which waits until every pick has moved on.
local function move(pick: Pick, moment: string?, now: number): boolean
	if pick.status == "open" and moment ~= pick.match then
		lockIn(pick)
		pick.status = "locked"
	end
	if moment == AgentSelect.FREE then
		if pick.status ~= "free" then
			pick.status = "free"
			pick.selected = pick.agent
		end
	elseif moment == nil then
		pick.status = "none"
	elseif moment ~= pick.match then
		pick.match = moment
		open(pick, pick.agent, now)
	elseif pick.status == "none" or pick.status == "free" then
		return true
	end
	return false
end

-- Back on the side of a match they've had their window in: the agent they
-- play is theirs again, unless a teammate has locked it in meanwhile, when
-- they've another window, on one that's free.
local function comeBack(s: State, id: number, now: number)
	local pick = s.picks[id]
	pick.status = "locked"
	local taken = AgentSelect.taken(s, id)
	if taken[pick.agent] then
		open(pick, fallback(s, pick, taken), now)
	end
end

-- A window that's open keeps what's selected free, and closes once its
-- time is up, what's selected locked in.
local function settle(s: State, id: number, now: number)
	local pick = s.picks[id]
	if pick.status ~= "open" then
		return
	end
	local taken = AgentSelect.taken(s, id)
	if taken[pick.selected] then
		pick.selected = fallback(s, pick, taken)
	end
	if now >= pick.closesAt then
		lockIn(pick)
		pick.status = "locked"
	end
end

-- Every player's pick moved on at `now`, once a server frame: `ids` are the
-- players, in the server's order, and `moments` where each is for picking
-- (FREE, a key for their side of a match, or nil). First every pick moves
-- on; then, in order, whoever's back in a match keeps their agent if it
-- isn't taken; then each window that's open keeps what's selected free and
-- closes once its time is up, so of windows closing at once on one agent,
-- the first player keeps it. Returns the agents they play now, by id, for
-- those that changed.
function AgentSelect.step(s: State, ids: { number }, moments: { [number]: string? }, now: number): { [number]: string }
	local before: { [number]: string } = {}
	local back: { number } = {}
	for _, id in ids do
		local pick = AgentSelect.pickOf(s, id)
		before[id] = pick.agent
		if move(pick, moments[id], now) then
			table.insert(back, id)
		end
	end
	for _, id in back do
		comeBack(s, id, now)
	end
	for _, id in ids do
		settle(s, id, now)
	end
	local changed: { [number]: string } = {}
	for _, id in ids do
		local agent = s.picks[id].agent
		if agent ~= before[id] then
			changed[id] = agent
		end
	end
	return changed
end

-- One player's pick moved on at `now`, as `step` moves everyone's. Returns
-- the agent they play, if that's changed.
function AgentSelect.update(s: State, id: number, moment: string?, now: number): string?
	local moments: { [number]: string? } = {}
	moments[id] = moment
	return AgentSelect.step(s, { id }, moments, now)[id]
end

-- A player selects `agent`, where they can pick: in their window, or where
-- it's free; not one that's taken from them. Returns whether it's selected.
function AgentSelect.select(s: State, id: number, agent: string): boolean
	local pick = AgentSelect.pickOf(s, id)
	if not AgentSelect.canPick(s, agent) or (pick.status ~= "open" and pick.status ~= "free") then
		return false
	end
	if AgentSelect.taken(s, id)[agent] then
		return false
	end
	pick.selected = agent
	return true
end

-- A player locks in what they've selected: in their window, theirs until
-- the match is over, and the window closes, unless a teammate has locked
-- it in first, when it stays open; where it's free, theirs at once, and
-- they can pick again. Returns the agent they play, if that's changed.
function AgentSelect.lock(s: State, id: number): string?
	local pick = AgentSelect.pickOf(s, id)
	local before = pick.agent
	if pick.status == "open" and not AgentSelect.taken(s, id)[pick.selected] then
		lockIn(pick)
		pick.status = "locked"
	elseif pick.status == "free" then
		lockIn(pick)
	end
	return if pick.agent ~= before then pick.agent else nil
end

-- Whether someone's agent is theirs for the side of a match they're on
-- (`moment`): locked in, in a window for that side. Not before that
-- window has opened, as on the frame a match starts, when their pick still
-- holds the last match's.
function AgentSelect.settled(s: State, id: number, moment: string?): boolean
	local pick = s.picks[id]
	return pick ~= nil and moment ~= nil and pick.status == "locked" and pick.match == moment
end

-- Someone leaves the server: their pick goes with them.
function AgentSelect.leave(s: State, id: number)
	s.picks[id] = nil
end

-- Where a player is for picking, from what's played: `mode` (an Arena mode,
-- nil on the course), its phase, the match's number, the server's count of
-- modes started (so a match's key is its own after the mode starts over),
-- and the side they're on, if any. Free on the course and while a mode
-- waits for players; once a match in Skirmish, the spike rounds and Team
-- Deathmatch, each side of a match with its own key (halftime swaps which
-- side attacks, not who's on it); and nobody picks in gun game or
-- deathmatch, between matches, or off a side.
function AgentSelect.moment(mode: string?, phase: string, match: number, run: number, side: number?): string?
	if mode == nil then
		return AgentSelect.FREE
	elseif mode == "gungame" or mode == "deathmatch" or side == nil or phase == "matchOver" or phase == "vote" then
		return nil
	elseif phase == "waiting" then
		return AgentSelect.FREE
	end
	return string.format("%s:%d:%d:%d", mode, run, match, side)
end

-- Whether an agent locked in goes on the kit at once, or with the next
-- life: at once on the course (no `phase`), while they're down, while a
-- mode waits for players, in a buy phase or Team Deathmatch's pre-game,
-- and in their own spawn room there (`ownRoom`).
function AgentSelect.swapsNow(phase: string?, alive: boolean, ownRoom: boolean): boolean
	return phase == nil or not alive or phase == "waiting" or phase == "buy" or phase == "pregame" or ownRoom
end

return AgentSelect
