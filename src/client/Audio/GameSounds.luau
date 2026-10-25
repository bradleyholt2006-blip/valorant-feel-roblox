--!strict
-- What makes a sound (system 8) and who hears it, by the reference's rules
-- (SoundConfig):
--
--   you      your own steps, jumps and landings, quieter than anyone else's
--            so they don't cover them, and your gunshots, reloads, draws
--            and dry fire, on the Self bus rather than out in the world
--   others   their running steps, landings, gunshots and reloads, out in the
--            world where they are, muffled through walls (a cast from your
--            camera through the level); never their walking or crouching
--            steps, their jumps, their draws or their aiming
--
-- A reload plays in parts as it goes (a magazine out, then in, then the
-- bolt), each when the reload is far enough through, and a gun that loads a
-- round at a time plays a part for each round; switching weapons cuts it
-- off.
--   hits     on the server's verdict, the shooter hears a body hit or a
--            headshot, once a round however many pellets hit, and a kill
--            sound that rises with each kill of a life
--   knives   your swings at once, and the blade striking the level where
--            your client has it strike; its hit with the server's verdict,
--            the blade going in for a body or the headshot sound for a head.
--            Others hear a swing, and what it struck, within a short way
--   spike    the beeping of a plant or a defuse from whoever is doing it,
--            yours on the Self bus and others' where they are, and a latch
--            as you pick it up; the spike's own beeps, defuse, blast and
--            drop are SpikeView's, out in the world through playWorld
--   abilities  a cast's gust or swish (system 17): yours on the Self bus,
--            others' where they cast, both through playCast (AbilityEffects
--            says when)
--
-- Your steps come from your predicted ticks, others' from their poses as
-- they are drawn (RemoteEntities), so they line up with where they're
-- drawn, and both go through the same StepTracker; whether someone is
-- walking or crouching comes in their snapshot pose. During the arena's buy
-- phase nothing from the other side is heard (community). Practice dummies'
-- steps are off until the Sound Lab turns them on.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local MovementConfig = require(Shared.Movement.MovementConfig)
local MovementSim = require(Shared.Movement.MovementSim)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local SoundConfig = require(Shared.Audio.SoundConfig)
local SoundMath = require(Shared.Audio.SoundMath)
local StepTracker = require(Shared.Audio.StepTracker)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local Spike = require(Shared.Spike.Spike)
local Units = require(Shared.Units)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

local NetSim = require(script.Parent.Parent.NetSim)
local PlayerController = require(script.Parent.Parent.PlayerController)
local RemoteEntities = require(script.Parent.Parent.RemoteEntities)
local ClientShots = require(script.Parent.Parent.Combat.ClientShots)
local ClientMelee = require(script.Parent.Parent.Combat.ClientMelee)
local SoundEngine = require(script.Parent.SoundEngine)

local GameSounds = {}

local DT = 1 / MovementConfig.TickRate.value
local F, L = SoundConfig.Footsteps, SoundConfig.Landing
local FEET = vector.create(0, 0.1, 0) -- a step sounds just above the feet
local CHEST = vector.create(0, 1.2, 0) -- a reload at the weapon
local DEVICE = vector.create(0, 0.4, 0) -- a plant or a defuse, low down at the spike
local LOG_SIZE = 14
GameSounds.FEET = FEET

GameSounds.settings = {
	dummySteps = false, -- practice dummies' steps and landings (Sound Lab, Y)
	footstepRadius = F.radius.value, -- this client's footstep curve (Sound Lab, [ ])
}

-- What each sound was and why it played as it did, newest last, for the
-- Sound Lab.
export type Entry = {
	at: number, -- os.clock()
	sound: string,
	who: string,
	loud: boolean,
	position: vector?, -- metres, for sounds out in the world
	distance: number?,
	walls: number?, -- metres of level in the way
	cutoff: number?,
	gain: number?,
	voice: SoundEngine.Voice?,
	note: string?, -- why it wasn't heard, when it wasn't
}
GameSounds.log = {} :: { Entry }
GameSounds.counts = { own = 0, world = 0, ui = 0, muted = 0 }
-- Called for each entry as it's logged (the Sound Lab's rings).
GameSounds.entryListeners = {} :: { (Entry) -> () }

local function note(entry: Entry): Entry
	local log = GameSounds.log
	table.insert(log, entry)
	while #log > LOG_SIZE do
		table.remove(log, 1)
	end
	for _, listener in GameSounds.entryListeners do
		listener(entry)
	end
	return entry
end

local function own(sound: string, volume: number?, pitch: number?): SoundEngine.Voice?
	local voice = SoundEngine.play(sound, "self", { volume = volume, pitch = pitch })
	GameSounds.counts.own += 1
	note({ at = os.clock(), sound = sound, who = "you", loud = true, voice = voice })
	return voice
end

local function ui(sound: string, pitch: number?)
	local voice = SoundEngine.play(sound, "ui", { pitch = pitch })
	GameSounds.counts.ui += 1
	note({ at = os.clock(), sound = sound, who = "you", loud = true, voice = voice })
end

export type WorldOptions = {
	volume: number?,
	pitch: number?, -- times the sound's own pitch
	follow: (() -> vector?)?,
	air: boolean?, -- gunshots dull with distance
}

-- Plays a sound out in the world at `at` (metres), filtered for the walls
-- between it and the camera, unless it's past the end of its curve.
function GameSounds.playWorld(sound: string, at: vector, who: string, opts: WorldOptions?): SoundEngine.Voice?
	local o: WorldOptions = opts or {}
	local from = SoundEngine.listenerPosition()
	local distance = vector.magnitude(at - from)
	local curve = SoundEngine.curveOf(sound)
	local radius = if curve then SoundMath.radius(curve) else nil
	if radius and distance >= radius then
		GameSounds.counts.muted += 1
		note({ at = os.clock(), sound = sound, who = who, loud = true, position = at, distance = distance, note = "out of range" })
		return nil
	end
	local walls = SoundMath.blockage(ClientShots.level, from, at, SoundConfig.Occlusion.maxPieces.value)
	local cutoff, gain = SoundMath.occlusion(walls)
	if o.air then
		cutoff = math.min(cutoff, SoundMath.airCutoff(distance))
	end
	local voice = SoundEngine.play(sound, "world", { position = at, follow = o.follow, cutoff = cutoff, volume = (o.volume or 1) * gain, pitch = o.pitch })
	GameSounds.counts.world += 1
	note({
		at = os.clock(),
		sound = sound,
		who = who,
		loud = true,
		position = at,
		distance = distance,
		walls = walls,
		cutoff = cutoff,
		gain = gain,
		voice = voice,
	})
	return voice
end

local function muted(sound: string, who: string, at: vector, why: string)
	GameSounds.counts.muted += 1
	note({ at = os.clock(), sound = sound, who = who, loud = false, position = at, note = why })
end

-- The arena -----------------------------------------------------------------------

-- Whether `id` is on the other side during the arena's buy phase, when
-- nothing they do is heard.
local function inBuyPhaseAcross(id: number): boolean
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return false
	end
	local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
	if not arena or arena:GetAttribute("Phase") ~= "buy" then
		return false
	end
	local mine = Players.LocalPlayer:GetAttribute(ArenaConfig.SIDE)
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == id then
			local theirs = player:GetAttribute(ArenaConfig.SIDE)
			return typeof(mine) == "number" and typeof(theirs) == "number" and mine ~= theirs
		end
	end
	return false
end

-- Reloads ------------------------------------------------------------------------

-- A reload under way: its parts, when it started, how long it takes, the
-- next part to play, the voice of the last one played, and whether it
-- starts over when it's done (someone else's round-at-a-time reload, whose
-- rounds we can't see go in).
type Reload = { cues: { SoundConfig.Cue }, start: number, length: number, nextCue: number, voice: SoundEngine.Voice?, repeats: boolean }

local function newReload(weapon: string, start: number, length: number, repeats: boolean?): Reload?
	local sounds = SoundConfig.Weapons[weapon]
	local cues = if sounds then sounds.reload else nil
	if not cues or length <= 0 then
		return nil
	end
	return { cues = cues, start = start, length = length, nextCue = 1, voice = nil, repeats = repeats == true }
end

-- Plays the parts of `r` that are due at `now` with `play`.
local function playDue(r: Reload, now: number, play: (string) -> SoundEngine.Voice?)
	while r.repeats and now - r.start >= r.length do
		local due = SoundMath.cuesDue(r.cues, r.nextCue, r.length, r.length)
		for _, sound in due do
			r.voice = play(sound) or r.voice
		end
		r.start += r.length
		r.nextCue = 1
	end
	local due, nextCue = SoundMath.cuesDue(r.cues, r.nextCue, now - r.start, r.length)
	r.nextCue = nextCue
	for _, sound in due do
		r.voice = play(sound) or r.voice
	end
end

local function cancelReload(r: Reload?)
	if r then
		SoundEngine.stop(r.voice)
	end
end

-- The spike -------------------------------------------------------------------------

-- A plant or a defuse under way, as heard: which (SpikeSim's channel: 1 a
-- plant, 2 a defuse), when it started, whether it's a defuse from the half,
-- and its beeping: the voice playing it and when that started.
type Channel = { kind: number, start: number, half: boolean, voice: SoundEngine.Voice?, playedAt: number? }

local function newChannel(kind: number, start: number, half: boolean): Channel
	return { kind = kind, start = start, half = half, voice = nil, playedAt = nil }
end

-- The plant's beeping, or the defuse's, higher from the half.
local function cueOf(c: Channel): (string, number?)
	if c.kind == 1 then
		return SoundConfig.Spike.plant, nil
	end
	return SoundConfig.Spike.defuse, if c.half then SoundConfig.Spike.halfPitch.value else nil
end

-- Whether `c`'s beeping should start (again) at `now`: as it starts, and for
-- a defuse each time its run of beeps comes to an end.
local function cueDue(c: Channel, now: number): boolean
	local at = c.playedAt
	if at == nil then
		return true
	end
	if c.kind ~= 2 then
		return false
	end
	local def = SoundConfig.Sounds[SoundConfig.Spike.defuse]
	local run = SoundConfig.Spike.defuseLoop.value - def.assets[1].start
	local _, pitch = cueOf(c)
	return now - at >= run / (def.pitch * (pitch or 1))
end

local function stopCue(c: Channel?)
	if c then
		SoundEngine.stop(c.voice)
	end
end

-- You -----------------------------------------------------------------------------

local ownSteps = StepTracker.new()
type WeaponState = { equipped: number, equipEndTime: number, reloadEndTime: number, ammo: number, fire: boolean }
local lastWeapons: WeaponState? = nil
local ownReload: Reload? = nil
local lastDrawAt = -math.huge -- simulation time of the last draw sound
local kills = 0
local ownChannel: Channel? = nil
local carried = false -- the spike, as of the last tick

local function onTick(info: any)
	local s = info.sim
	local m = s.movement
	local buttons: number = info.input.buttons
	-- A dash makes no steps, and a lift is no jump (system 17): each has
	-- its own sound.
	local t = m.tick * DT
	local quiet = StepTracker.isQuiet(buttons, m.crouched) or AbilitySim.dashing(s.abilities, t)
	for _, e in StepTracker.push(ownSteps, { time = info.time, position = m.position, grounded = m.grounded, quiet = quiet }) do
		if e.kind == "step" and e.loud then
			own("step", F.ownVolume.value)
		elseif e.kind == "jump" then
			if not AbilitySim.lifting(s.abilities, t) then
				own("jump")
			end
		elseif e.kind == "land" then
			if e.loud then
				own("land", L.ownVolume.value)
			else
				own("softLand")
			end
		end
	end

	local w = s.weapons
	local id = w.loadout[w.equipped]
	local sounds = SoundConfig.Weapons[id]
	local now = m.tick * DT
	local fire = MovementSim.has(buttons, MovementSim.Buttons.Fire)
	local was = lastWeapons
	if was then
		local switched = w.equipped ~= was.equipped
		if switched or w.equipEndTime > was.equipEndTime then
			-- Switching cancels a reload, and its sound with it.
			cancelReload(ownReload)
			ownReload = nil
			if sounds and SoundMath.drawHeard(switched, now - lastDrawAt) then
				own(sounds.draw)
				lastDrawAt = now
			end
		elseif w.reloadEndTime > 0 and w.reloadEndTime ~= was.reloadEndTime then
			-- A reload starts, or one that loads a round at a time starts
			-- the next round.
			ownReload = newReload(id, now, w.reloadEndTime - now)
		end
		local def = WeaponConfig.get(id)
		local ready = def.fireMode ~= "none" and w.reloadEndTime == 0 and now >= w.equipEndTime
		if SoundMath.dryHeard(fire and not was.fire, info.shots ~= nil, w.ammo[w.equipped], ready) then
			own("dry")
		end
	end
	lastWeapons = { equipped = w.equipped, equipEndTime = w.equipEndTime, reloadEndTime = w.reloadEndTime, ammo = w.ammo[w.equipped], fire = fire }
	local r = ownReload
	if r then
		playDue(r, now, function(sound)
			return own(sound)
		end)
		if w.reloadEndTime == 0 then
			ownReload = nil -- done: its last part rings out
		end
	end

	local shots = info.shots
	if shots then
		local shotSounds = SoundConfig.Weapons[shots[1].weapon]
		if shotSounds and shotSounds.shot then
			own(shotSounds.shot, nil, shotSounds.pitch) -- one sound a round, however many pellets
		end
	end

	-- The spike: picked up, and planted or defused.
	local carrying = w.loadout[4] == "spike"
	if carrying and not carried then
		own(SoundConfig.Spike.pickup)
	end
	carried = carrying
	local spike = s.spike
	if spike.channel ~= 0 then
		local old = ownChannel
		local c: Channel = if old and old.kind == spike.channel and old.start == spike.channelStart
			then old
			else newChannel(spike.channel, spike.channelStart, spike.halfStart)
		if c ~= old then
			stopCue(old)
		end
		ownChannel = c
		if cueDue(c, now) then
			SoundEngine.stop(c.voice)
			local sound, pitch = cueOf(c)
			c.voice = own(sound, nil, pitch)
			c.playedAt = now
		end
	else
		-- Let go of, done or cut short: its beeping stops.
		stopCue(ownChannel)
		ownChannel = nil
	end
end

-- Your knife swings: the whoosh, and the blade striking the level where your
-- client has it strike. A hit is heard with the server's confirm (onVolley).
local function onOwnSwing(record: ClientMelee.Record)
	local sounds = SoundConfig.Weapons[record.swing.weapon]
	if not sounds then
		return
	end
	local swing = if record.swing.kind == "stab" then sounds.stab else sounds.slash
	if swing then
		own(swing)
	end
	if record.predicted.wall and sounds.wall then
		own(sounds.wall)
	end
end

local function onSpawn()
	StepTracker.reset(ownSteps)
	lastWeapons = nil
	cancelReload(ownReload)
	ownReload = nil
	lastDrawAt = -math.huge
	kills = 0
	stopCue(ownChannel)
	ownChannel = nil
	carried = false
end

local function onVolley(volley: ClientShots.Volley)
	if #volley.hits == 0 then
		return
	end
	local head = false
	for _, hit in volley.hits do
		head = head or hit.region == "head"
	end
	-- A knife's hit on the body is its blade going in.
	local sounds = SoundConfig.Weapons[volley.weapon]
	local body = if sounds and sounds.hit then sounds.hit else "hitBody"
	ui(if head then "headshot" else body)
	for _, hit in volley.hits do
		if hit.killed then
			kills += 1
			ui("kill", SoundMath.killPitch(kills))
		end
	end
end

-- Everyone else -----------------------------------------------------------------

type Remote = {
	steps: StepTracker.Tracker,
	reloading: boolean,
	weapon: number,
	reload: Reload?,
	channel: Channel?, -- a plant or a defuse under way
}
local remotes: { [number]: Remote } = {}

local function drawnAt(id: number): vector?
	local pose = RemoteEntities.sample(id, RemoteEntities.renderTime())
	return if pose then pose.position + CHEST else nil
end

local function onFrame()
	local renderTime = RemoteEntities.renderTime()
	local seen: { [number]: boolean } = {}
	for _, id in RemoteEntities.ids() do
		seen[id] = true
		local r = remotes[id]
		if not r then
			r = { steps = StepTracker.new(), reloading = false, weapon = 0, reload = nil }
			remotes[id] = r
		end
		local pose = if RemoteEntities.isPresent(id) then RemoteEntities.sample(id, renderTime) else nil
		if not pose or not pose.alive then
			StepTracker.reset(r.steps)
			cancelReload(r.reload)
			r.reload, r.reloading = nil, false
			stopCue(r.channel)
			r.channel = nil
			continue
		end
		local who = RemoteEntities.nameOf(id)
		local dummy = PlayerCodec.isDummy(id)
		local silenced = inBuyPhaseAcross(id)
		local events = StepTracker.push(r.steps, { time = renderTime, position = pose.position, grounded = pose.grounded, quiet = pose.quiet })
		for _, e in events do
			if e.kind == "jump" or not e.loud or (dummy and not GameSounds.settings.dummySteps) then
				continue
			end
			local at = e.position + FEET
			if silenced then
				muted(e.kind, who, at, "buy phase")
			else
				GameSounds.playWorld(e.kind, at, who)
			end
		end

		if pose.reloading and not r.reloading then
			local weapon = WeaponConfig.Ids[pose.weapon]
			if weapon then
				local def = WeaponConfig.get(weapon)
				local perRound = def.reloadPerRound
				r.reload = newReload(weapon, renderTime, if perRound then perRound.value else def.reloadTime.value, perRound ~= nil)
			else
				r.reload = nil
			end
		elseif r.reloading and pose.weapon ~= r.weapon then
			-- Switched weapons mid-reload.
			cancelReload(r.reload)
			r.reload = nil
		end
		local reload = r.reload
		if reload then
			local at = pose.position + CHEST
			playDue(reload, renderTime, function(sound)
				if silenced then
					muted(sound, who, at, "buy phase")
					return nil
				end
				return GameSounds.playWorld(sound, at, who, {
					follow = function()
						return drawnAt(id)
					end,
				})
			end)
			if not pose.reloading then
				r.reload = nil -- done: its last part rings out
			end
		end
		r.reloading, r.weapon = pose.reloading, pose.weapon

		-- Planting or defusing: its beeping, low down where they are. A defuse
		-- from the half is one that starts with the half saved.
		if pose.channel ~= 0 then
			local old = r.channel
			local c: Channel = if old and old.kind == pose.channel
				then old
				else newChannel(pose.channel, renderTime, Workspace:GetAttribute(Spike.HALF) == true)
			if c ~= old then
				stopCue(old)
			end
			r.channel = c
			if cueDue(c, renderTime) then
				SoundEngine.stop(c.voice)
				c.playedAt = renderTime
				local at = pose.position + DEVICE
				local sound, pitch = cueOf(c)
				if silenced then
					c.voice = nil
					muted(sound, who, at, "buy phase")
				else
					c.voice = GameSounds.playWorld(sound, at, who, { pitch = pitch })
				end
			end
		else
			stopCue(r.channel)
			r.channel = nil
		end
	end
	for id, r in remotes do
		if not seen[id] then
			cancelReload(r.reload)
			stopCue(r.channel)
			remotes[id] = nil
		end
	end
end

local function onShotFx(fx: any)
	if typeof(fx) ~= "table" or typeof(fx.from) ~= "Vector3" or typeof(fx.shooter) ~= "number" then
		return
	end
	local sounds = SoundConfig.Weapons[if typeof(fx.weapon) == "string" then fx.weapon else ""]
	if not sounds or not sounds.shot then
		return
	end
	local at = Units.toMetres(fx.from)
	local who = RemoteEntities.nameOf(fx.shooter)
	if inBuyPhaseAcross(fx.shooter) then
		muted(sounds.shot, who, at, "buy phase")
		return
	end
	GameSounds.playWorld(sounds.shot, at, who, { air = true, pitch = sounds.pitch })
end

-- Someone else's knife swing: its whoosh where they are, then the blade going
-- in or striking the level, all heard only close by.
local function onSwingFx(fx: any)
	if typeof(fx) ~= "table" or typeof(fx.from) ~= "Vector3" or typeof(fx.attacker) ~= "number" then
		return
	end
	local sounds = SoundConfig.Weapons[if typeof(fx.weapon) == "string" then fx.weapon else ""]
	local swing = if not sounds then nil elseif fx.kind == "stab" then sounds.stab else sounds.slash
	if not sounds or not swing then
		return
	end
	local at = Units.toMetres(fx.from)
	local who = RemoteEntities.nameOf(fx.attacker)
	if inBuyPhaseAcross(fx.attacker) then
		muted(swing, who, at, "buy phase")
		return
	end
	GameSounds.playWorld(swing, at, who)
	if fx.hit == true and sounds.hit then
		GameSounds.playWorld(sounds.hit, at, who)
	elseif typeof(fx.wall) == "Vector3" and sounds.wall then
		GameSounds.playWorld(sounds.wall, Units.toMetres(fx.wall), who)
	end
end

-- Abilities -----------------------------------------------------------------------

-- A cast's sound (system 17): yours, or with `id` someone else's at `at`
-- (metres, their feet), unheard from the other side in the buy phase.
function GameSounds.playCast(kind: string, at: vector, id: number?)
	local sound = SoundConfig.Abilities[kind]
	if not sound then
		return
	end
	if id == nil then
		own(sound)
		return
	end
	local who = RemoteEntities.nameOf(id)
	local where = at + CHEST
	if inBuyPhaseAcross(id) then
		muted(sound, who, where, "buy phase")
		return
	end
	GameSounds.playWorld(sound, where, who)
end

-- Settings ------------------------------------------------------------------------

-- This client's footstep radius: the footstep curve stretched to it.
function GameSounds.setFootstepRadius(radius: number)
	GameSounds.settings.footstepRadius = radius
	local curve = SoundMath.scaled(SoundConfig.Curves.footstep.points, radius)
	SoundEngine.setCurve("step", curve)
	SoundEngine.setCurve("land", curve)
end

function GameSounds.start()
	SoundEngine.start()
	local C = SoundConfig.Curves
	SoundEngine.prepare("step", "world", C.footstep.points)
	SoundEngine.prepare("land", "world", C.footstep.points)
	for _, sounds in SoundConfig.Weapons do
		if sounds.shot then
			SoundEngine.prepare(sounds.shot, "world", (C :: any)[sounds.curve].points)
			SoundEngine.prepare(sounds.shot, "self")
		end
		if sounds.reload then
			for _, c in sounds.reload do
				SoundEngine.prepare(c.sound, "world", C.reload.points)
				SoundEngine.prepare(c.sound, "self")
			end
		end
		SoundEngine.prepare(sounds.draw, "self")
		-- A knife's: yours, and others' out in the world.
		for _, sound in { sounds.slash, sounds.stab, sounds.wall } do
			if sound then
				SoundEngine.prepare(sound, "world", (C :: any)[sounds.curve].points)
				SoundEngine.prepare(sound, "self")
			end
		end
		if sounds.hit then
			SoundEngine.prepare(sounds.hit, "world", (C :: any)[sounds.curve].points)
			SoundEngine.prepare(sounds.hit, "ui")
		end
	end
	for _, sound in { "step", "land", "softLand", "jump", "dry" } do
		SoundEngine.prepare(sound, "self")
	end
	for _, sound in { "hitBody", "headshot", "kill" } do
		SoundEngine.prepare(sound, "ui")
	end
	local spike = SoundConfig.Spike
	for _, sound in { spike.plant, spike.defuse } do
		SoundEngine.prepare(sound, "world", C.device.points)
		SoundEngine.prepare(sound, "self")
	end
	SoundEngine.prepare(spike.pickup, "self")
	SoundEngine.prepare(spike.beep, "world", C.beep.points)
	SoundEngine.prepare(spike.defused, "world", C.beep.points)
	SoundEngine.prepare(spike.blast, "world", C.blast.points)
	SoundEngine.prepare(spike.drop, "world", C.drop.points)
	for _, sound in SoundConfig.Abilities do
		SoundEngine.prepare(sound, "world", C.ability.points)
		SoundEngine.prepare(sound, "self")
	end

	table.insert(PlayerController.tickListeners, onTick)
	table.insert(PlayerController.spawnListeners, onSpawn)
	table.insert(ClientShots.volleyListeners, onVolley)
	table.insert(ClientMelee.firedListeners, onOwnSwing)
	NetSim.on(Remotes.get().ShotFx, onShotFx)
	NetSim.on(Remotes.get().SwingFx, onSwingFx)
	RunService:BindToRenderStep("VFGameSounds", Enum.RenderPriority.Camera.Value + 3, onFrame)
end

return GameSounds
