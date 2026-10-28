--!strict
-- Each player's agent and ultimate at a glance (system 51), as the
-- reference's top bar and scoreboard show them. The top bar has everyone's
-- agent either side of the score, with who's alive ('Each agent will be
-- shown on the bar and reflects who is still alive in the round', ONE
-- Esports), your side's health under theirs (Patch 11.10: 'The top HUD
-- health bar now shows when you or an ally are healing'), and anyone's
-- ultimate once it's ready, an enemy's too (a VLR.gg thread: 'we can see
-- enemy's ULT status from the top bar'). The scoreboard has everyone's
-- ultimate, allies' and enemies' alike, as how far along it is: 'both ult
-- availability and the progress to it for allies and enemies are shown
-- pretty plainly on the scoreboard' (Joseph Edwards, 2020), as '5/6 or
-- 6/7'. There are no portraits, so a player's agent is the first two
-- letters of its name (ours).
--
-- The server keeps each player's ultimate as a player attribute
-- (AbilityConfig.ULT_ATTRIBUTE, Glance.ultimate's text), which every
-- client reads, and their agent as AgentSelect.AGENT.
--
-- No Roblox APIs here.

local AbilityConfig = require("./AbilityConfig")
local AbilitySim = require("./AbilitySim")
local Health = require("../Combat/Health")

local Glance = {}

-- The scoreboard's word for an ultimate with every point it needs (ours).
Glance.READY = "READY"

-- A kit's ultimate as the attribute carries it: its points and what it
-- needs ("3/8"), or "" for a kit with no ultimate to charge.
function Glance.ultimate(s: AbilitySim.State): string
	local needed = AbilitySim.pointsNeeded(s)
	if needed <= 0 then
		return ""
	end
	return string.format("%d/%d", math.min(s.points, needed), needed)
end

-- The points and what they need, from the attribute's text: none of
-- either for "", or for anything that isn't the attribute's.
function Glance.read(text: any): (number, number)
	if type(text) ~= "string" then
		return 0, 0
	end
	local points, needed = string.match(text, "^(%d+)/(%d+)$")
	if not points or not needed then
		return 0, 0
	end
	return tonumber(points) :: number, tonumber(needed) :: number
end

-- Whether an ultimate is ready: every point it needs.
function Glance.ready(text: any): boolean
	local points, needed = Glance.read(text)
	return needed > 0 and points >= needed
end

-- The scoreboard's ULT: READY once it is, else how far along it is
-- ("3/8"), or nothing for a kit with no ultimate.
function Glance.cell(text: any): string
	local points, needed = Glance.read(text)
	if needed <= 0 then
		return ""
	elseif points >= needed then
		return Glance.READY
	end
	return string.format("%d/%d", points, needed)
end

-- A player's tile on the top bar, and their badge on the scoreboard: the
-- first two letters of their agent's name, or of their own for no agent's
-- kit (and where nobody plays an agent, `agent` nil).
function Glance.badge(agent: any, name: string): string
	local def = if type(agent) == "string" then AbilityConfig.Agents[agent] else nil
	return string.upper(string.sub(if def then def.name else name, 1, 2))
end

-- How full a health bar is, 0 to 1.
function Glance.share(health: number, most: number): number
	if most <= 0 then
		return 0
	end
	return math.clamp(health / most, 0, 1)
end

-- A tile as the top bar's lists describe it, for scripted checks: its
-- badge, then its health where it's shown (in whole points, as the labels
-- over players have it, Health.points), "dead" and "ready".
function Glance.describe(badge: string, health: number?, alive: boolean, ready: boolean): string
	local parts = { badge }
	if health then
		table.insert(parts, tostring(Health.points(health)))
	end
	if not alive then
		table.insert(parts, "dead")
	end
	if ready then
		table.insert(parts, "ready")
	end
	return table.concat(parts, " ")
end

return Glance
