--!strict
-- Plays the sounds (system 8) through Roblox's audio API:
--
--   AudioPlayer -> AudioFilter -> AudioEmitter      a sound out in the world,
--                                      : heard by    on an Attachment there
--   AudioListener (on the camera) -> World -> Muffle --\
--   AudioPlayer -> Self (what you make) -> Muffle -------> Master -> Limiter -> AudioDeviceOutput
--   AudioPlayer -> Ui (hit and kill sounds) ------------/
--
-- Every sound has a pool of voices for each bus it plays on, made up front
-- with its asset loading, so a sound plays on the frame it's asked for. A
-- voice in the world has its own filter (walls in the way, the air for far
-- gunshots) and emitter with the sound's distance curve; it is moved to
-- where the sound is, or kept on the player it follows while it plays.
-- Voices take turns, so when all of a sound's are busy the oldest is cut.
-- Each voice's asset is evened out to the same peak (SoundConfig.Level) as
-- it plays on that voice's path, and a limiter after the master keeps a
-- pile-up of shots from clipping.
--
-- The emitters and the listener share their own AudioInteractionGroup, so
-- no other listener hears them (Roblox makes one on the camera for voice
-- chat when VoiceChatService.EnableDefaultVoice is on, as it is in BRINK),
-- and their acoustic simulation is off: walls are ours (GameSounds).
--
-- An AudioAnalyzer on each bus, before the master fader, measures what it
-- plays for the Sound Lab, so with VFTestMute set on the local player (for
-- scripted playtests, which shouldn't make noise) nothing is heard but the
-- meters still move. The World and Self buses each have a low-pass after
-- them, open but while you're deafened (Omen's Paranoia, system 41), when
-- it muffles them and their faders turn them down (setDeafened).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundConfig = require(Shared.Audio.SoundConfig)
local SoundMath = require(Shared.Audio.SoundMath)
local Units = require(Shared.Units)

local SoundEngine = {}

export type Bus = "world" | "self" | "ui"

export type Voice = {
	sound: string,
	bus: Bus,
	player: AudioPlayer,
	start: number, -- seconds of the asset skipped at the start
	gain: number, -- evens its asset out to the level
	filter: AudioFilter?,
	emitter: AudioEmitter?,
	attachment: Attachment?,
	follow: (() -> vector?)?, -- where to keep it while it plays
}

export type PlayOptions = {
	volume: number?, -- times the sound's own volume
	pitch: number?, -- times the sound's own playback speed, before its jitter
	position: vector?, -- metres; world voices only
	follow: (() -> vector?)?, -- world voices: where to keep it each frame
	cutoff: number?, -- Hz: the world voice's low-pass
}

type Pool = { voices: { Voice }, nextIndex: number }

local BUSES = { "world", "self", "ui" }
SoundEngine.BUSES = BUSES
local GROUP = "VFSound"
local MUTE_ATTRIBUTE = "VFTestMute"
local PEAK_HOLD = 2 -- seconds the meters hold a peak
local MAX_VOLUME = 10 -- AudioPlayer.Volume's top (in BRINK, 12 reads back as 10)
local LIMIT = -1 -- dB: the limiter's ceiling

local folder: Folder? = nil
local emitterParent: Instance? = nil
local listener: AudioListener? = nil
local master: AudioFader? = nil
local buses: { [string]: AudioFader } = {}
local analyzers: { [string]: AudioAnalyzer } = {}
local muffles: { [string]: AudioFilter } = {} -- the World and Self buses' low-pass
local pools: { [string]: Pool } = {}
local curves: { [string]: { { number } } } = {} -- world pool key -> curve in metres
local rng = Random.new()

-- Peak level each bus reached lately, for the Sound Lab.
local held: { [string]: { peak: number, at: number } } = {}

local function wire(source: Instance, target: Instance, parent: Instance)
	local w = Instance.new("Wire")
	w.SourceInstance = source
	w.TargetInstance = target
	w.Parent = parent
end

-- Turns Roblox's own acoustic simulation off where it exists (newer API).
local function noSimulation(instance: Instance)
	pcall(function()
		(instance :: any).AcousticSimulationEnabled = false
	end)
end

local function key(sound: string, bus: Bus): string
	return sound .. "/" .. bus
end

local function newVoice(sound: string, bus: Bus, asset: SoundConfig.Asset, parent: Instance): Voice
	local def = SoundConfig.Sounds[sound]
	local player = Instance.new("AudioPlayer")
	player.Name = sound
	player.AutoLoad = true
	player.Looping = false
	player.Asset = "rbxassetid://" .. asset.id
	-- Out in the world a stereo take is summed to mono, and peaks lower.
	local peak = if bus == "world" then asset.worldPeak or asset.peak else asset.peak
	local voice: Voice = { sound = sound, bus = bus, player = player, start = asset.start, gain = SoundMath.assetGain(peak) }
	player.Volume = math.min(def.volume * voice.gain, MAX_VOLUME)
	if bus == "world" then
		local attachment = Instance.new("Attachment")
		attachment.Name = "VFSound_" .. sound
		local filter = Instance.new("AudioFilter")
		filter.FilterType = Enum.AudioFilterType.Lowpass12dB
		filter.Frequency = SoundConfig.OPEN_CUTOFF
		filter.Bypass = true
		local emitter = Instance.new("AudioEmitter")
		emitter.AudioInteractionGroup = GROUP
		emitter.DistanceAttenuationMode = Enum.DistanceAttenuationMode.Custom
		noSimulation(emitter)
		player.Parent = attachment
		filter.Parent = attachment
		emitter.Parent = attachment
		wire(player, filter, attachment)
		wire(filter, emitter, attachment)
		attachment.Parent = parent
		voice.attachment, voice.filter, voice.emitter = attachment, filter, emitter
	else
		player.Parent = parent
		wire(player, buses[bus], player)
	end
	return voice
end

-- Makes a sound's voices for a bus (once), and sets the distance curve of
-- the world ones.
function SoundEngine.prepare(sound: string, bus: Bus, curve: { { number } }?)
	local k = key(sound, bus)
	if pools[k] then
		return
	end
	local def = SoundConfig.Sounds[sound]
	if not def or #def.assets == 0 then
		return
	end
	local parent = if bus == "world" then emitterParent else folder
	assert(parent, "SoundEngine.start first")
	local voices = table.create(def.voices)
	for i = 1, def.voices do
		voices[i] = newVoice(sound, bus, def.assets[(i - 1) % #def.assets + 1], parent)
	end
	pools[k] = { voices = voices, nextIndex = 1 }
	if bus == "world" then
		SoundEngine.setCurve(sound, curve or SoundConfig.Curves.footstep.points)
	end
end

-- Changes the distance curve of a sound's world voices (the Sound Lab's
-- footstep radius).
function SoundEngine.setCurve(sound: string, curve: { { number } })
	local k = key(sound, "world")
	curves[k] = curve
	local pool = pools[k]
	if not pool then
		return
	end
	local studs = SoundMath.studsCurve(curve, Units.STUDS_PER_METRE)
	for _, voice in pool.voices do
		(voice.emitter :: AudioEmitter):SetDistanceAttenuation(studs)
	end
end

function SoundEngine.curveOf(sound: string): { { number } }?
	return curves[key(sound, "world")]
end

function SoundEngine.isReady(sound: string, bus: Bus): boolean
	local pool = pools[key(sound, bus)]
	if not pool then
		return false
	end
	for _, voice in pool.voices do
		if not voice.player.IsReady then
			return false
		end
	end
	return true
end

-- Plays a sound on a bus and returns its voice, or nil if the sound has no
-- voices there (not prepared, or no assets).
function SoundEngine.play(sound: string, bus: Bus, opts: PlayOptions?): Voice?
	local pool = pools[key(sound, bus)]
	if not pool then
		return nil
	end
	local o: PlayOptions = opts or {}
	local voice = pool.voices[pool.nextIndex]
	pool.nextIndex = pool.nextIndex % #pool.voices + 1
	local def = SoundConfig.Sounds[sound]
	local player = voice.player
	if player.IsPlaying then
		player:Stop()
	end
	player.Volume = math.clamp(def.volume * voice.gain * (o.volume or 1), 0, MAX_VOLUME)
	player.PlaybackSpeed = def.pitch * (o.pitch or 1) * (1 + (rng:NextNumber() * 2 - 1) * def.pitchJitter)
	player.TimePosition = voice.start
	voice.follow = o.follow
	local attachment = voice.attachment
	if attachment then
		local at = o.position or (if o.follow then o.follow() else nil)
		if at then
			attachment.WorldPosition = Units.toStuds(at)
		end
		local filter = voice.filter :: AudioFilter
		local cutoff = o.cutoff or SoundConfig.OPEN_CUTOFF
		filter.Bypass = cutoff >= SoundConfig.OPEN_CUTOFF
		filter.Frequency = math.clamp(cutoff, 20, SoundConfig.OPEN_CUTOFF)
	end
	player:Play()
	return voice
end

function SoundEngine.stop(voice: Voice?)
	if voice and voice.player.IsPlaying then
		voice.player:Stop()
	end
end

-- How loud a playing world voice is for the listener, 0 to 1 (its distance
-- curve where the camera is), or nil.
function SoundEngine.audibility(voice: Voice): number?
	local emitter, l = voice.emitter, listener
	if not emitter or not l then
		return nil
	end
	local ok, value = pcall(function()
		return emitter:GetAudibilityFor(l)
	end)
	return if ok then value else nil
end

-- Where the listener is, in metres.
function SoundEngine.listenerPosition(): vector
	local camera = Workspace.CurrentCamera
	return if camera then Units.toMetres(camera.CFrame.Position) else vector.create(0, 0, 0)
end

-- Each bus's level now and its peak over the last couple of seconds, and
-- how many voices are playing.
function SoundEngine.levels(): { [string]: { rms: number, peak: number, held: number } }
	local out: { [string]: { rms: number, peak: number, held: number } } = {}
	for _, bus in BUSES do
		local analyzer = analyzers[bus]
		local h = held[bus]
		if analyzer then
			out[bus] = { rms = analyzer.RmsLevel, peak = analyzer.PeakLevel, held = if h then h.peak else 0 }
		end
	end
	return out
end

function SoundEngine.playing(): number
	local n = 0
	for _, pool in pools do
		for _, voice in pool.voices do
			if voice.player.IsPlaying then
				n += 1
			end
		end
	end
	return n
end

-- Voices whose asset hasn't loaded, and how many there are in all.
function SoundEngine.loading(): (number, number)
	local waiting, total = 0, 0
	for _, pool in pools do
		for _, voice in pool.voices do
			total += 1
			if not voice.player.IsReady then
				waiting += 1
			end
		end
	end
	return waiting, total
end

function SoundEngine.isMuted(): boolean
	return Players.LocalPlayer:GetAttribute(MUTE_ATTRIBUTE) == true
end

-- How deafened you are, 0 to 1 (Omen's Paranoia, system 41): the World and
-- Self buses muffled and turned down by that much (SoundMath.deafened).
function SoundEngine.setDeafened(amount: number)
	local cutoff, volume = SoundMath.deafened(amount)
	for bus, muffle in muffles do
		muffle.Bypass = cutoff >= SoundConfig.OPEN_CUTOFF
		muffle.Frequency = math.clamp(cutoff, 20, SoundConfig.OPEN_CUTOFF)
		buses[bus].Volume = volume
	end
end

local function placeListener()
	local l = listener
	local camera = Workspace.CurrentCamera
	if l and camera and l.Parent ~= camera then
		l.Parent = camera
	end
end

local function onFrame()
	placeListener()
	local m = master
	if m then
		m.Volume = if SoundEngine.isMuted() then 0 else 1
	end
	for _, pool in pools do
		for _, voice in pool.voices do
			local follow, attachment = voice.follow, voice.attachment
			if follow and attachment and voice.player.IsPlaying then
				local at = follow()
				if at then
					attachment.WorldPosition = Units.toStuds(at)
				end
			end
		end
	end
	local now = os.clock()
	for _, bus in BUSES do
		local analyzer = analyzers[bus]
		local h = held[bus]
		if analyzer and (not h or analyzer.PeakLevel >= h.peak or now - h.at > PEAK_HOLD) then
			held[bus] = { peak = analyzer.PeakLevel, at = now }
		end
	end
end

function SoundEngine.start()
	local f = Instance.new("Folder")
	f.Name = "VFSound"
	f.Parent = SoundService
	folder = f
	-- An Attachment has a world position only on a part: the Terrain is one.
	emitterParent = Workspace.Terrain

	local output = Instance.new("AudioDeviceOutput")
	output.Name = "Output"
	output.Parent = f
	local limiter = Instance.new("AudioLimiter")
	limiter.Name = "Limiter"
	limiter.MaxLevel = LIMIT
	limiter.Parent = f
	wire(limiter, output, limiter)
	local m = Instance.new("AudioFader")
	m.Name = "Master"
	m.Parent = f
	wire(m, limiter, m)
	master = m
	for _, bus in BUSES do
		local fader = Instance.new("AudioFader")
		fader.Name = bus
		fader.Parent = f
		if bus == "ui" then
			wire(fader, m, fader)
		else
			local muffle = Instance.new("AudioFilter")
			muffle.Name = bus .. "Muffle"
			muffle.FilterType = Enum.AudioFilterType.Lowpass24dB
			muffle.Frequency = SoundConfig.OPEN_CUTOFF
			muffle.Bypass = true
			muffle.Parent = fader
			wire(fader, muffle, muffle)
			wire(muffle, m, muffle)
			muffles[bus] = muffle
		end
		local analyzer = Instance.new("AudioAnalyzer")
		analyzer.Name = bus .. "Meter"
		analyzer.Parent = fader
		wire(fader, analyzer, analyzer)
		buses[bus] = fader
		analyzers[bus] = analyzer
	end

	local l = Instance.new("AudioListener")
	l.Name = "VFListener"
	l.AudioInteractionGroup = GROUP
	noSimulation(l)
	wire(l, buses.world, l)
	listener = l
	placeListener()
	RunService:BindToRenderStep("VFSound", Enum.RenderPriority.Camera.Value + 4, onFrame)
end

return SoundEngine
