--!strict
-- The local player's shots: the client's instant guess and the server's
-- verdict, side by side.
--
-- When the local simulation fires, the shot is traced right away against the
-- level and against every target as it was drawn on screen when the trigger
-- was sampled (the input's viewTime). That guess drives tracers and impacts
-- with no delay. The server's verdict (ShotResult) arrives a round trip later
-- and is the only thing that applies damage. Each record keeps both, so the
-- weapon lab can measure how often they agree.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local ShotResolver = require(Shared.Combat.ShotResolver)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerController = require(script.Parent.Parent.PlayerController)
local RemoteEntities = require(script.Parent.Parent.RemoteEntities)

export type Outcome = {
	targetId: number?,
	region: string?,
	distance: number, -- metres from the eye to the end point
	point: vector, -- metres
	normal: vector?, -- surface normal when level geometry stopped the shot
	damage: number?,
	killed: boolean?,
}

export type Record = {
	life: number,
	shot: WeaponSim.Shot,
	input: PlayerCodec.WireInput,
	firedAt: number, -- os.clock() at the tick that fired
	predicted: Outcome,
	verdict: Outcome?,
	verdictAt: number?,
	agree: boolean?, -- same target and region (or both missed)
}

local ClientShots = {}

ClientShots.MAX_RECORDS = 256
ClientShots.records = {} :: { Record } -- oldest first
ClientShots.firedListeners = {} :: { (Record) -> () }
ClientShots.verdictListeners = {} :: { (Record) -> () }
ClientShots.stats = {
	shots = 0,
	verdicts = 0,
	agreed = 0,
	unmatchedVerdicts = 0, -- server shots the client never showed (after a correction)
}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = RobloxWorld.CHARACTER_GROUP
params.RespectCanCollide = true

-- Same rules as the server's trace: level geometry first, then hitboxes.
function ClientShots.trace(origin: vector, dir: vector, viewTime: number, ignoreId: number?): Outcome
	local maxRange = WeaponConfig.MaxRange
	local result = Workspace:Raycast(Units.toStuds(origin), Units.toStuds(dir * maxRange), params)
	local blockedAt = if result then result.Distance * Units.METRES_PER_STUD else maxRange
	local hit = ShotResolver.resolve(origin, dir, RemoteEntities.targets(viewTime), blockedAt, ignoreId)
	if hit then
		return { targetId = hit.targetId, region = hit.region, distance = hit.distance, point = hit.point }
	end
	return {
		distance = blockedAt,
		point = origin + dir * blockedAt,
		normal = if result then Units.asVector(result.Normal) else nil,
	}
end

local function onShot(shot: WeaponSim.Shot, input: PlayerCodec.WireInput)
	local record: Record = {
		life = PlayerController.life,
		shot = shot,
		input = input,
		firedAt = os.clock(),
		predicted = ClientShots.trace(shot.origin, shot.direction, input.viewTime, PlayerController.entityId),
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
	local verdict: Outcome = {
		targetId = v.target,
		region = v.region,
		distance = if typeof(v.distance) == "number" then v.distance else vector.magnitude(point - record.shot.origin),
		point = point,
		damage = v.damage,
		killed = v.killed,
	}
	record.verdict = verdict
	record.verdictAt = os.clock()
	record.agree = record.predicted.targetId == verdict.targetId and record.predicted.region == verdict.region
	local stats = ClientShots.stats
	stats.verdicts += 1
	if record.agree then
		stats.agreed += 1
	end
	for _, listener in ClientShots.verdictListeners do
		listener(record)
	end
end

function ClientShots.reset()
	table.clear(ClientShots.records)
	ClientShots.stats.shots = 0
	ClientShots.stats.verdicts = 0
	ClientShots.stats.agreed = 0
	ClientShots.stats.unmatchedVerdicts = 0
end

function ClientShots.start()
	table.insert(PlayerController.shotListeners, onShot)
	Remotes.get().ShotResult.OnClientEvent:Connect(onVerdict)
end

return ClientShots
