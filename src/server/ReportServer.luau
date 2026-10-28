--!strict
-- The combat report on the server (system 53): each player's report
-- (CombatReport), kept from what CombatServer tells of every hit and kill,
-- and sent to them alone with the Report remote. Nobody's report says
-- anything of anyone they didn't fight.
--
-- A report covers a round in Skirmish and the spike rounds, cleared as one
-- starts (Arena, ReportServer.roundStarted) and kept through the lives
-- Sage's Resurrection starts; elsewhere, and while a match waits for an
-- opponent, a life, opened at each spawn. It goes to its owner:
--   * as they die ("death"), and again as it changes while they're down,
--     every EVERY seconds at most (a fire of theirs still burning)
--   * as a round ends, to everyone with one (an "update"), marked as the
--     round's last (`final`), to show through the next buy phase; again as
--     it changes before the next round starts
--   * on the course, as they ask for it ("now"), as N does there
--   * as they join, if they died in the stretch it covers ("death").
--     Reports go by entity id, which comes from the UserId, so leaving and
--     coming back keeps one: Patch 9.04 fixed reports 'not showing up after
--     force closing the game and reconnecting to the match'.
-- Each event carries the round's number, in the rounds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local CombatReport = require(Shared.Match.CombatReport)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)

local ReportServer = {}

-- Whether reports go by the round now, not by the life: in Skirmish and
-- the spike rounds once a round's under way (Arena). By the life without.
ReportServer.byRound = nil :: (() -> boolean)?

-- Seconds between one sending of a report that's changed and the next
-- (ours).
ReportServer.EVERY = 0.25

local log = CombatReport.newLog()
-- Whose reports go to them again as they change: the dead's, and once a
-- round's over everyone's. And when each last went.
local following: { [number]: boolean } = {}
local changed: { [number]: boolean } = {}
local sentAt: { [number]: number } = {}
-- Whether the round's over (its reports are its last), and its number.
local over = false
local round: number? = nil

local function idOf(player: Player): number
	return PlayerCodec.entityIdForUser(player.UserId)
end

-- Sends `id`'s report to them, as `kind` says.
local function send(id: number, kind: string, now: number)
	changed[id] = nil
	local entity = Entities.get(id)
	local player = if entity then entity.player else nil
	local report = log[id]
	if not player or not report then
		return
	end
	sentAt[id] = now
	Remotes.get().Report:FireClient(player, { kind = kind, final = over, round = round, report = report })
end

local function mark(ids: { number })
	for _, id in ids do
		if following[id] then
			changed[id] = true
		end
	end
end

-- A round has started (`number`, nil out of the rounds): everyone's
-- reports gone.
function ReportServer.roundStarted(number: number?)
	CombatReport.clear(log)
	table.clear(following)
	table.clear(changed)
	over = false
	round = number
end

-- A round has ended: everyone's report goes to them as the round's last.
function ReportServer.roundOver(number: number?)
	over = true
	round = number
	local now = Workspace:GetServerTimeNow()
	for id in log do
		following[id] = true
		send(id, "update", now)
	end
end

-- A mode starting or stopping: everyone's reports start over, the
-- living's at once and the others' at their next spawn.
function ReportServer.reset()
	ReportServer.roundStarted(nil)
	for _, player in Players:GetPlayers() do
		if PlayerSimServer.isAlive(player) then
			CombatReport.open(log, idOf(player))
		end
	end
end

-- Once a server frame: reports that have changed go again, each no more
-- often than EVERY.
function ReportServer.step(now: number)
	for id in changed do
		if now - (sentAt[id] or -math.huge) >= ReportServer.EVERY then
			send(id, "update", now)
		end
	end
end

local function onAsk(player: Player, what: any)
	local id = idOf(player)
	local now = Workspace:GetServerTimeNow()
	if what == "now" then
		-- The course's alone.
		if Workspace:GetAttribute(ArenaConfig.ON) == true then
			return
		end
		CombatReport.keep(log, id)
		send(id, "now", now)
	elseif what == "back" then
		local report = log[id]
		if report and report.death and not PlayerSimServer.isAlive(player) then
			following[id] = true
			send(id, "death", now)
		end
	end
end

function ReportServer.start()
	table.insert(CombatServer.damageListeners, function(attacker, victim, amount: number, how: CombatServer.Hit)
		local hit: CombatReport.Hit = { damage = amount, weapon = how.weapon, parts = how.parts, burst = how.burst }
		mark(CombatReport.hit(log, if attacker then attacker.id else nil, victim.id, hit))
	end)
	table.insert(CombatServer.killListeners, function(attacker, victim, weapon: string)
		mark(CombatReport.killed(log, if attacker then attacker.id else nil, victim.id, weapon))
	end)
	table.insert(PlayerSimServer.deathListeners, function(player: Player)
		local id = idOf(player)
		following[id] = true
		send(id, "death", Workspace:GetServerTimeNow())
	end)
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		local id = idOf(player)
		local byRound = ReportServer.byRound
		if over then
			following[id] = true
		else
			following[id] = nil
		end
		changed[id] = nil
		if byRound and byRound() then
			CombatReport.keep(log, id)
		else
			CombatReport.open(log, id)
		end
	end)
	Remotes.get().Report.OnServerEvent:Connect(onAsk)
	Players.PlayerRemoving:Connect(function(player)
		local id = idOf(player)
		following[id] = nil
		changed[id] = nil
		sentAt[id] = nil
	end)
end

return ReportServer
