--!strict
-- The local player's shots: the client's instant guess and the server's
-- verdict, side by side.
--
-- When the local simulation fires, the shot is traced right away against the
-- level and against every target as it was drawn on screen when the trigger
-- was sampled (the input's viewTime). That guess drives the tracer and a
-- small client-side spark with no delay. The server's verdict (ShotResult)
-- arrives a round trip later and is the only thing that applies damage or
-- shows a hit confirm, as in the reference ("shot results are entirely
-- server authoritative", Riot, "The State of Hit Registration").
--
-- Each record keeps both, and what each side tested: the targets near the
-- ray, their poses and the snapshots those came from. When the two disagree
-- the record says why (Cause); the Hit Reg Lab counts the reasons.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Hitboxes = require(Shared.Combat.Hitboxes)
local ShotResolver = require(Shared.Combat.ShotResolver)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerController = require(script.Parent.Parent.PlayerController)
local RemoteEntities = require(script.Parent.Parent.RemoteEntities)
local NetSim = require(script.Parent.Parent.NetSim)

export type Outcome = {
	targetId: number?,
	region: string?,
	distance: number, -- metres from the eye to the end point
	point: vector, -- metres
	normal: vector?, -- surface normal when level geometry stopped the shot
	blockedAt: number, -- metres to the level along the shot
	damage: number?,
	killed: boolean?,
}

-- A target as one side tested it: its pose at the shot's time and the
-- snapshots that pose came from (PoseHistory.Lookup).
export type Tested = {
	pose: Hitboxes.Pose,
	from: number,
	to: number,
	held: boolean,
}

export type Verdict = {
	targetId: number?,
	region: string?,
	distance: number,
	point: vector,
	normal: vector?,
	blockedAt: number,
	damage: number?,
	killed: boolean?,
	hitPoint: vector?, -- where the shot hit the rewound target, metres
	rewind: number, -- seconds the server went back
	clamped: boolean, -- the rewind cap moved the time
	origin: vector?, -- the server's shot, to compare with ours
	direction: vector?,
	tested: { [number]: Tested },
}

-- Why a verdict differs from the client's guess:
--   capped    the shot saw an older world than the rewind cap allows
--   shooter   the server's shot started or pointed elsewhere (a correction)
--   gone      a target one side tested wasn't there on the other (dead, respawned, left)
--   snapshot  the target came from different snapshots (one was lost, late or held)
--   world     the level stopped the shot at a different distance
--   pose      same snapshots but a different pose: a bug
--   edge      none of the above: a hair's-breadth difference, also worth a report
export type Cause = "agree" | "capped" | "shooter" | "gone" | "snapshot" | "world" | "pose" | "edge"

export type Record = {
	life: number,
	shot: WeaponSim.Shot,
	input: PlayerCodec.WireInput,
	firedAt: number, -- os.clock() at the tick that fired
	predicted: Outcome,
	tested: { [number]: Tested }, -- what the client tested
	moving: boolean, -- a tested target was moving when the shot was taken
	verdict: Verdict?,
	verdictAt: number?,
	agree: boolean?, -- same target and region (or both missed)
	cause: Cause?,
}

local ClientShots = {}

ClientShots.MAX_RECORDS = 256
ClientShots.records = {} :: { Record } -- oldest first
ClientShots.firedListeners = {} :: { (Record) -> () }
ClientShots.verdictListeners = {} :: { (Record) -> () }

local MOVING_SPEED = 0.5 -- m/s; a target faster than this counts as moving

local function newStats()
	return {
		shots = 0,
		verdicts = 0,
		agreed = 0,
		unmatchedVerdicts = 0, -- server shots the client never showed (after a correction)
		moving = 0, -- verdicts for shots at moving targets
		movingAgreed = 0,
		causes = {} :: { [string]: number },
		rewindLast = 0,
		rewindSum = 0,
		rewindMax = 0,
		clamped = 0,
		confirms = 0, -- server hit confirms, and the time from shot to confirm
		confirmSum = 0,
		confirmLast = 0,
	}
end
ClientShots.stats = newStats()

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = RobloxWorld.CHARACTER_GROUP
params.RespectCanCollide = true

-- Same rules as the server's trace: level geometry first, then hitboxes.
-- Also returns the targets near the ray, as tested.
function ClientShots.trace(origin: vector, dir: vector, viewTime: number, ignoreId: number?): (Outcome, { [number]: Tested })
	local maxRange = WeaponConfig.MaxRange
	local result = Workspace:Raycast(Units.toStuds(origin), Units.toStuds(dir * maxRange), params)
	local blockedAt = if result then result.Distance * Units.METRES_PER_STUD else maxRange
	local targets: { ShotResolver.Target } = {}
	local tested: { [number]: Tested } = {}
	for _, entry in RemoteEntities.lookups(viewTime) do
		if entry.id == ignoreId then
			continue
		end
		local l = entry.lookup
		local pose: Hitboxes.Pose = { position = l.pose.position, yaw = l.pose.yaw, crouchAlpha = l.pose.crouchAlpha }
		table.insert(targets, { id = entry.id, pose = pose })
		if ShotResolver.nearRay(origin, dir, pose, blockedAt) then
			tested[entry.id] = { pose = pose, from = l.from, to = l.to, held = l.held }
		end
	end
	local hit = ShotResolver.resolve(origin, dir, targets, blockedAt, ignoreId)
	if hit then
		return { targetId = hit.targetId, region = hit.region, distance = hit.distance, point = hit.point, blockedAt = blockedAt }, tested
	end
	return {
		distance = blockedAt,
		point = origin + dir * blockedAt,
		normal = if result then Units.asVector(result.Normal) else nil,
		blockedAt = blockedAt,
	}, tested
end

local function movingAt(id: number, time: number): boolean
	local a = RemoteEntities.sample(id, time - 0.05)
	local b = RemoteEntities.sample(id, time)
	return a ~= nil and b ~= nil and vector.magnitude(b.position - a.position) / 0.05 > MOVING_SPEED
end

local function onShot(shot: WeaponSim.Shot, input: PlayerCodec.WireInput)
	local predicted, tested = ClientShots.trace(shot.origin, shot.direction, input.viewTime, PlayerController.entityId)
	local moving = false
	for id in tested do
		moving = moving or movingAt(id, input.viewTime)
	end
	local record: Record = {
		life = PlayerController.life,
		shot = shot,
		input = input,
		firedAt = os.clock(),
		predicted = predicted,
		tested = tested,
		moving = moving,
	}
	table.insert(ClientShots.records, record)
	if #ClientShots.records > ClientShots.MAX_RECORDS then
		table.remove(ClientShots.records, 1)
	end
	ClientShots.stats.shots += 1
	for _, listener in ClientShots.firedListeners do
		listener(record)
	end
end

local function find(shotNumber: number): Record?
	local records = ClientShots.records
	for i = #records, 1, -1 do
		local r = records[i]
		if r.life == PlayerController.life and r.shot.shotNumber == shotNumber then
			return r
		end
	end
	return nil
end

local function asVector(v: any): vector?
	return if typeof(v) == "Vector3" then Units.asVector(v) else nil
end

local function parseTested(list: any): { [number]: Tested }
	local out: { [number]: Tested } = {}
	if typeof(list) ~= "table" then
		return out
	end
	for _, t in list do
		if
			typeof(t) == "table"
			and typeof(t.id) == "number"
			and typeof(t.position) == "Vector3"
			and typeof(t.yaw) == "number"
			and typeof(t.crouch) == "number"
			and typeof(t.from) == "number"
			and typeof(t.to) == "number"
		then
			out[t.id] = {
				pose = { position = Units.asVector(t.position), yaw = t.yaw, crouchAlpha = t.crouch },
				from = t.from,
				to = t.to,
				held = t.held == true,
			}
		end
	end
	return out
end

-- Two poses that build the same boxes (positions from the server arrive
-- rounded to float32).
function ClientShots.samePose(a: Hitboxes.Pose, b: Hitboxes.Pose): boolean
	return vector.magnitude(a.position - b.position) <= 1e-4 and math.abs(a.yaw - b.yaw) <= 1e-6 and math.abs(a.crouchAlpha - b.crouchAlpha) <= 1e-6
end

-- How the client had a target at the shot's time: as tested if it was near
-- the ray, otherwise looked up again (the snapshots may have moved on, but
-- which ones covered that time rarely changes).
local function clientView(r: Record, id: number): Tested?
	local tested = r.tested[id]
	if tested then
		return tested
	end
	local l = RemoteEntities.lookup(id, r.input.viewTime)
	if not l then
		return nil
	end
	return { pose = { position = l.pose.position, yaw = l.pose.yaw, crouchAlpha = l.pose.crouchAlpha }, from = l.from, to = l.to, held = l.held }
end

local function classify(r: Record, v: Verdict): Cause
	if r.agree then
		return "agree"
	end
	if v.clamped then
		return "capped"
	end
	local origin, direction = v.origin, v.direction
	if (origin and vector.magnitude(origin - r.shot.origin) > 1e-3) or (direction and vector.magnitude(direction - r.shot.direction) > 1e-5) then
		return "shooter"
	end
	-- The targets that matter: whoever either side hit.
	local ids: { number } = {}
	if r.predicted.targetId then
		table.insert(ids, r.predicted.targetId)
	end
	if v.targetId and v.targetId ~= r.predicted.targetId then
		table.insert(ids, v.targetId)
	end
	for _, id in ids do
		local server = v.tested[id]
		if server == nil then
			return "gone"
		end
		local client = clientView(r, id)
		if client == nil then
			return "gone"
		end
		if client.from ~= server.from or client.to ~= server.to or client.held ~= server.held then
			return "snapshot"
		end
		if not ClientShots.samePose(client.pose, server.pose) then
			return "pose"
		end
	end
	if math.abs(v.blockedAt - r.predicted.blockedAt) > 0.01 then
		return "world"
	end
	return "edge"
end

local function onVerdict(v: any)
	if typeof(v) ~= "table" or typeof(v.shotNumber) ~= "number" or typeof(v.endPoint) ~= "Vector3" then
		return
	end
	local record = find(v.shotNumber)
	if not record then
		ClientShots.stats.unmatchedVerdicts += 1
		return
	end
	if record.verdict then
		return
	end
	local point = Units.toMetres(v.endPoint)
	local verdict: Verdict = {
		targetId = v.target,
		region = v.region,
		distance = if typeof(v.distance) == "number" then v.distance else vector.magnitude(point - record.shot.origin),
		point = point,
		blockedAt = if typeof(v.blockedAt) == "number" then v.blockedAt else record.predicted.blockedAt,
		damage = v.damage,
		killed = v.killed,
		hitPoint = asVector(v.hitPoint),
		rewind = if typeof(v.rewind) == "number" then v.rewind else 0,
		clamped = v.clamped == true,
		origin = asVector(v.origin),
		direction = asVector(v.direction),
		tested = parseTested(v.tested),
	}
	record.verdict = verdict
	record.verdictAt = os.clock()
	record.agree = record.predicted.targetId == verdict.targetId and record.predicted.region == verdict.region
	local cause: Cause = classify(record, verdict)
	record.cause = cause

	local stats = ClientShots.stats
	stats.verdicts += 1
	if record.agree then
		stats.agreed += 1
	else
		stats.causes[cause] = (stats.causes[cause] or 0) + 1
	end
	if record.moving then
		stats.moving += 1
		stats.movingAgreed += if record.agree then 1 else 0
	end
	stats.rewindLast = verdict.rewind
	stats.rewindSum += verdict.rewind
	stats.rewindMax = math.max(stats.rewindMax, verdict.rewind)
	stats.clamped += if verdict.clamped then 1 else 0
	if verdict.targetId then
		local delay = record.verdictAt :: number - record.firedAt
		stats.confirms += 1
		stats.confirmSum += delay
		stats.confirmLast = delay
	end
	for _, listener in ClientShots.verdictListeners do
		listener(record)
	end
end

function ClientShots.reset()
	table.clear(ClientShots.records)
	ClientShots.stats = newStats()
end

function ClientShots.start()
	table.insert(PlayerController.shotListeners, onShot)
	NetSim.on(Remotes.get().ShotResult, onVerdict)
end

return ClientShots
