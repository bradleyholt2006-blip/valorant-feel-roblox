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
-- The reference's 'Each player within a team must select a unique agent'
-- (the same page) isn't ours yet: with fewer agents than a side has
-- players, some couldn't pick at all (29-agent-select.md).
--
-- Where a player is, for picking: FREE, a match's key (any string that's
-- the match's alone, from the server), or nil where nobody picks (gun game
-- and deathmatch, which have no abilities, between matches, and outside
-- what's played).
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
	match: string?, -- the match their last window was for
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

-- What's selected becomes theirs.
local function lockIn(pick: Pick)
	pick.agent = pick.selected
	pick.closesAt = 0
end

-- Where a player is for picking at `now` (FREE, a match's key, or nil),
-- once a server frame: a window opens the first time they're in a match,
-- and closes once its time is up or once they're out of that match, what's
-- selected locked in. Returns the agent they play, if that's changed.
function AgentSelect.update(s: State, id: number, moment: string?, now: number): string?
	local pick = AgentSelect.pickOf(s, id)
	local before = pick.agent
	if pick.status == "open" and (moment ~= pick.match or now >= pick.closesAt) then
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
		pick.status = "open"
		pick.selected = pick.agent
		pick.closesAt = now + AbilityConfig.Select.time.value
	elseif pick.status ~= "open" then
		-- Back in a match they've had their window in.
		pick.status = "locked"
	end
	return if pick.agent ~= before then pick.agent else nil
end

-- A player selects `agent`, where they can pick: in their window, or where
-- it's free. Returns whether it's selected.
function AgentSelect.select(s: State, id: number, agent: string): boolean
	local pick = AgentSelect.pickOf(s, id)
	if not AgentSelect.canPick(s, agent) or (pick.status ~= "open" and pick.status ~= "free") then
		return false
	end
	pick.selected = agent
	return true
end

-- A player locks in what they've selected: in their window, theirs until
-- the match is over, and the window closes; where it's free, theirs at
-- once, and they can pick again. Returns the agent they play, if that's
-- changed.
function AgentSelect.lock(s: State, id: number): string?
	local pick = AgentSelect.pickOf(s, id)
	local before = pick.agent
	if pick.status == "open" then
		lockIn(pick)
		pick.status = "locked"
	elseif pick.status == "free" then
		lockIn(pick)
	end
	return if pick.agent ~= before then pick.agent else nil
end

-- Someone leaves the server: their pick goes with them.
function AgentSelect.leave(s: State, id: number)
	s.picks[id] = nil
end

-- Where a player is for picking, from what's played: `mode` (an Arena mode,
-- nil on the course), its phase, the match's number, the server's count of
-- modes started (so a match's key is its own after the mode starts over),
-- and whether they're on a side. Free on the course and while a mode waits
-- for players; once a match in Skirmish, the spike rounds and Team
-- Deathmatch; and nobody picks in gun game or deathmatch, between matches,
-- or off a side.
function AgentSelect.moment(mode: string?, phase: string, match: number, run: number, onSide: boolean): string?
	if mode == nil then
		return AgentSelect.FREE
	elseif mode == "gungame" or mode == "deathmatch" or not onSide or phase == "matchOver" or phase == "vote" then
		return nil
	elseif phase == "waiting" then
		return AgentSelect.FREE
	end
	return string.format("%s:%d:%d", mode, run, match)
end

-- Whether an agent locked in goes on the kit at once, or with the next
-- life: at once on the course (no `phase`), while they're down, while a
-- mode waits for players, in a buy phase or Team Deathmatch's pre-game,
-- and in their own spawn room there (`ownRoom`).
function AgentSelect.swapsNow(phase: string?, alive: boolean, ownRoom: boolean): boolean
	return phase == nil or not alive or phase == "waiting" or phase == "buy" or phase == "pregame" or ownRoom
end

return AgentSelect
