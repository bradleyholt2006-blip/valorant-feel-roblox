--!strict
-- The local player's knife swings (system 10): the client's instant guess and
-- the server's verdict, as ClientShots keeps them for bullets.
--
-- A swing is decided on the tick it starts, the same way on both sides
-- (Melee): here against the targets as they were drawn when the button was
-- sampled (the input's viewTime), on the server against them rewound to that
-- time. The guess shows at once, as the reference's knife does since Patch
-- 4.01 ("Knifing walls now has instant feedback when slicing up walls"): the
-- blade's mark where it strikes the level and a small spark where it meets a
-- target. Damage, the hit confirm, the hit marker and the hit sound come only
-- with the server's verdict (SwingResult). A hit is also told to ClientShots'
-- volley listeners as a round that hit one target, so the HUD and the hit
-- sounds take it as they take a bullet's.
--
-- Each record keeps both sides and what each tested, for the debug tools
-- (the Hit Reg Lab's knife lines and the F10 overlay).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Melee = require(Shared.Combat.Melee)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerController = require(script.Parent.Parent.PlayerController)
local RemoteEntities = require(script.Parent.Parent.RemoteEntities)
local NetSim = require(script.Parent.Parent.NetSim)
local ClientShots = require(script.Parent.ClientShots)

-- What the server decided about one swing.
export type Verdict = {
	targetId: number?,
	region: string?,
	point: vector?, -- where the swing met the target's boxes, metres
	offset: number?, -- metres off the aim
	distance: number?, -- metres along it from the eye
	back: boolean, -- struck from behind
	damage: number, -- what the swing did, before the target's health caps it; 0 with no hit
	killed: boolean,
	hidden: { number }, -- targets in reach that the level hid
	wall: vector?, -- where the blade struck the level, when it caught no one
	normal: vector?,
	rewind: number, -- seconds the server went back
	clamped: boolean, -- the rewind cap moved the time
	origin: vector?, -- the server's swing, to compare with ours
	direction: vector?,
	tested: { [number]: ClientShots.Tested }, -- the rewound targets in reach
}

export type Record = {
	life: number,
	swing: WeaponSim.Swing,
	input: PlayerCodec.WireInput,
	attack: WeaponConfig.SwingDef,
	firedAt: number, -- os.clock() at the tick that swung
	predicted: Melee.Result,
	tested: { [number]: ClientShots.Tested }, -- the targets in reach, as the client had them
	verdict: Verdict?,
	verdictAt: number?,
	agree: boolean?, -- same target and region (or both caught no one)
}

local ClientMelee = {}

ClientMelee.MAX_RECORDS = 64
ClientMelee.records = {} :: { Record } -- oldest first
ClientMelee.firedListeners = {} :: { (Record) -> () }
ClientMelee.verdictListeners = {} :: { (Record) -> () }

local function newStats()
	return {
		swings = 0,
		verdicts = 0,
		agreed = 0,
		hits = 0, -- the server's
		backs = 0, -- of those, struck from behind
		unmatchedVerdicts = 0, -- server swings the client never showed (after a correction)
	}
end
ClientMelee.stats = newStats()

-- The attack a swing made: the knife's slash or its stab.
function ClientMelee.attackOf(swing: WeaponSim.Swing): WeaponConfig.SwingDef?
	local melee = WeaponConfig.get(swing.weapon).melee
	if not melee then
		return nil
	end
	return if swing.kind == "stab" then melee.stab else melee.slash
end

-- Another player on our side, whom the server's swing passes by, as its
-- bullets do.
local function isTeammate(id: number): boolean
	local me = Players.LocalPlayer
	if me.Neutral or me.Team == nil then
		return false
	end
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == id then
			return player ~= me and not player.Neutral and player.Team == me.Team
		end
	end
	return false
end

-- What a swing catches with everyone as this client drew them at
-- `viewTime`, and the targets in reach, as tested.
function ClientMelee.predict(swing: WeaponSim.Swing, attack: WeaponConfig.SwingDef, viewTime: number): (Melee.Result, { [number]: ClientShots.Tested })
	local me = PlayerController.entityId
	local targets: { Melee.Target } = {}
	local tested: { [number]: ClientShots.Tested } = {}
	for _, entry in RemoteEntities.lookups(viewTime) do
		if entry.id == me or isTeammate(entry.id) then
			continue
		end
		local l = entry.lookup
		local pose: Hitboxes.Pose = { position = l.pose.position, yaw = l.pose.yaw, crouchAlpha = l.pose.crouchAlpha }
		table.insert(targets, { id = entry.id, pose = pose })
		if Melee.nearby(swing.origin, attack, pose) then
			tested[entry.id] = { pose = pose, from = l.from, to = l.to, held = l.held }
		end
	end
	return Melee.resolve(ClientShots.levelAt(viewTime), swing.origin, swing.direction, attack, targets, me), tested
end

local function onSwing(swing: WeaponSim.Swing, input: PlayerCodec.WireInput)
	local attack = ClientMelee.attackOf(swing)
	if not attack then
		return
	end
	local predicted, tested = ClientMelee.predict(swing, attack, input.viewTime)
	local record: Record = {
		life = PlayerController.life,
		swing = swing,
		input = input,
		attack = attack,
		firedAt = os.clock(),
		predicted = predicted,
		tested = tested,
	}
	table.insert(ClientMelee.records, record)
	if #ClientMelee.records > ClientMelee.MAX_RECORDS then
		table.remove(ClientMelee.records, 1)
	end
	ClientMelee.stats.swings += 1
	for _, listener in ClientMelee.firedListeners do
		listener(record)
	end
end

-- This life's swing on `tick`: a life swings at most once a tick.
local function find(tick: number): Record?
	local records = ClientMelee.records
	for i = #records, 1, -1 do
		local r = records[i]
		if r.life == PlayerController.life and r.swing.tick == tick then
			return r
		end
	end
	return nil
end

local function asVector(v: any): vector?
	return if typeof(v) == "Vector3" then Units.asVector(v) else nil
end

local function number(v: any): number?
	return if typeof(v) == "number" then v else nil
end

local function ids(list: any): { number }
	local out: { number } = {}
	if typeof(list) == "table" then
		for _, id in list do
			if typeof(id) == "number" then
				table.insert(out, id)
			end
		end
	end
	return out
end

local function onVerdict(v: any)
	if typeof(v) ~= "table" or typeof(v.tick) ~= "number" then
		return
	end
	local stats = ClientMelee.stats
	local record = find(v.tick)
	if not record then
		stats.unmatchedVerdicts += 1
		return
	end
	if record.verdict then
		return
	end
	local target = number(v.target)
	local verdict: Verdict = {
		targetId = target,
		region = if target and typeof(v.region) == "string" then v.region else nil,
		point = asVector(v.point),
		offset = number(v.offset),
		distance = number(v.distance),
		back = v.back == true,
		damage = number(v.damage) or 0,
		killed = v.killed == true,
		hidden = ids(v.hidden),
		wall = asVector(v.wall),
		normal = asVector(v.normal),
		rewind = number(v.rewind) or 0,
		clamped = v.clamped == true,
		origin = asVector(v.origin),
		direction = asVector(v.direction),
		tested = ClientShots.parseTested(v.tested),
	}
	record.verdict = verdict
	record.verdictAt = os.clock()
	local guess = record.predicted.hit
	local guessTarget = if guess then guess.targetId else nil
	local guessRegion = if guess then guess.region else nil
	record.agree = guessTarget == verdict.targetId and guessRegion == verdict.region
	stats.verdicts += 1
	stats.agreed += if record.agree then 1 else 0
	if target then
		stats.hits += 1
		stats.backs += if verdict.back then 1 else 0
	end
	for _, listener in ClientMelee.verdictListeners do
		listener(record)
	end
	if target then
		local volley: ClientShots.Volley = {
			weapon = record.swing.weapon,
			records = {},
			hits = {
				{
					targetId = target,
					region = verdict.region or "body",
					damage = verdict.damage,
					pellets = 1,
					killed = verdict.killed,
					point = verdict.point or record.swing.origin,
				},
			},
		}
		for _, listener in ClientShots.volleyListeners do
			listener(volley)
		end
	end
end

function ClientMelee.reset()
	table.clear(ClientMelee.records)
	ClientMelee.stats = newStats()
end

function ClientMelee.start()
	table.insert(PlayerController.swingListeners, onSwing)
	NetSim.on(Remotes.get().SwingResult, onVerdict)
end

return ClientMelee
