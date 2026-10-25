--!strict
-- Sound (system 8): who hears what, how far, how walls change it, and the
-- sounds themselves. Same status convention as ArenaLayout:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be tuned (docs/research/08-sound.md)
--   "measured"  - ours, measured from a public source (here, the waveforms
--                 of the Roblox library sounds we play)
--
-- Riot publishes the aims and rules of its sound, not its numbers. Its audio
-- director: "We optimize for making sure footsteps are heard, as opposed to
-- optimizing for portraying distance", on "an attenuation curve that is
-- somewhat flat, versus one that drops off a lot over distance" (Ask VALORANT
-- #6). And what a player does is either heard by enemies or not, which the
-- community has listed. So the rules are confirmed or community, and the
-- distances and volumes that carry them out are estimates.
--
-- The sounds are Pro Sound Effects' recordings in the Creator Store's free
-- library (Roblox added over 100,000 of them in 2022, free to use in any
-- experience), picked by name and checked by their waveforms: where each
-- one starts and how loud it peaks. None is the reference's.
--
-- Distances are metres, volumes 0-1 before each sound's own volume. No
-- requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate" | "measured"
export type Param = { value: number, status: Status, source: string }
-- Volume by distance: straight lines between { metres, volume } points, and
-- flat past the last one, as Roblox's AudioEmitter draws a custom curve.
export type Curve = { points: { { number } }, status: Status, source: string }

-- One sound: the library assets it picks from (one per play, in turn), how
-- loud, its pitch and how much that varies from play to play, and how many
-- can play at once before the oldest is cut.
export type Asset = {
	id: number,
	title: string, -- its name on the Creator Store
	-- How loud it plays straight to you (the Self and UI buses), 0-1: the
	-- loudest either channel gets (measured), which evens it out (Level). A
	-- mono take is spread over both channels, each getting 0.707 of it; a
	-- stereo one keeps its own.
	peak: number,
	start: number, -- seconds of quiet at its start that are skipped (measured)
	-- A stereo take out in the world, where it's summed to mono first: its
	-- downmix's peak, which each channel gets straight ahead (measured). A
	-- mono take plays at its `peak` there too.
	worldPeak: number?,
}
export type Sound = {
	assets: { Asset },
	volume: number,
	pitch: number, -- playback speed: below 1 is lower and heavier
	pitchJitter: number, -- each play's speed varies by +- this, at random
	voices: number,
	source: string,
}
-- A part of a reload (a magazine out, a magazine in, a bolt), played when
-- the reload is this far through, 0-1 of the weapon's reload time.
export type Cue = { at: number, sound: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local function curve(points: { { number } }, status: Status, source: string): Curve
	return { points = points, status = status, source = source }
end

local SoundConfig = {}

-- Footsteps -------------------------------------------------------------------

-- Running is heard; walking (Shift) and crouching are not (community: the
-- r/VALORANT beta breakdown by RoyGallant, via Dexerto and MeinMMO; the
-- in-game walk key's whole purpose). Footsteps play by distance covered on
-- the ground, a step each stride.
SoundConfig.Footsteps = {
	radius = p(
		20,
		"estimate",
		"Riot (Ask VALORANT #6): 'The footstep radius is set up to give players who hear enemy footsteps time to use an ability and re-equip a weapon before they are in danger'. About 1.75 s of that (a rifle's 1.0 s equip and an ability) at rifle running speed (5.40 m/s) is 9.5 m, plus a 10 m fight"
	),
	stride = p(1.8, "estimate", "Metres between steps: three a second at rifle running speed, about a runner's cadence"),
	firstStep = p(1.2, "estimate", "The least of a stride, in metres, counted as covered when a player sets off from standing, so their first step comes within 0.6 m"),
	idleTime = p(0.15, "estimate", "Seconds without moving that count as standing"),
	teleport = p(2, "estimate", "Metres between two samples that count as a respawn or a correction, not as walking"),
	-- Your own steps are quieter than others', so they don't cover anyone
	-- else's: footsteps are for hearing enemies.
	ownVolume = p(0.35, "estimate", "Your own steps against an enemy's next to you"),
}

-- Landing after a jump or a fall. Heard when you land on the level you left
-- or lower; jumping up onto a higher surface, a crate, is silent (community,
-- RoyGallant via Dexerto and MeinMMO). Jumping itself is not heard by others.
SoundConfig.Landing = {
	minFall = p(0.3, "estimate", "Metres fallen from the highest point in the air a landing needs to be heard"),
	maxRise = p(0.1, "estimate", "Metres above where it left the ground a landing can be and still be heard"),
	ownVolume = p(0.55, "estimate", "Your own landing against an enemy's next to you"),
}

-- Distance curves --------------------------------------------------------------

SoundConfig.Curves = {
	-- Flat, as Riot describes it, and cut at the radius: 'Anyone outside of
	-- this white circle can't hear you' (ONE Esports on the minimap's sound
	-- circle), faded over the last metre so it doesn't click.
	footstep = curve(
		{ { 0, 1 }, { 2, 1 }, { 10, 0.8 }, { 19, 0.5 }, { 20, 0 } },
		"estimate",
		"Riot: 'an attenuation curve that is somewhat flat' (Ask VALORANT #6); a player found 'little if any sound drop-off' to the edge of the range (Dexerto)"
	),
	-- Reloads show on the minimap's sound circle too (Patch 1.0: 'ability
	-- sounds, reloads, spike interactions and more'), so they have an edge.
	reload = curve({ { 0, 1 }, { 2, 1 }, { 8, 0.7 }, { 14, 0.45 }, { 15, 0 } }, "estimate", "Quieter and shorter than footsteps; no published radius"),
	-- Gunfire carries across a map.
	gunshot = curve(
		{ { 0, 1 }, { 5, 1 }, { 30, 0.6 }, { 80, 0.3 }, { 150, 0.15 }, { 200, 0 } },
		"estimate",
		"Heard map-wide; louder up close than footsteps' flat curve, since a shot says where it came from"
	),
	-- The Phantom's built-in suppressor: 'hard to hear' (community: MeinMMO,
	-- after RoyGallant). The Ghost and the Spectre are suppressed too.
	suppressed = curve({ { 0, 1 }, { 4, 1 }, { 20, 0.5 }, { 50, 0.2 }, { 70, 0 } }, "estimate", "A suppressed shot carries a third as far as a rifle's"),
	-- A knife's swings and strikes: heard close by, not across the map.
	melee = curve({ { 0, 1 }, { 2, 1 }, { 6, 0.6 }, { 10, 0.25 }, { 12, 0 } }, "estimate", "Shorter than a reload's; no published radius"),
	-- The spike (system 12). Planting and defusing carry a long way: heard
	-- at 60 m, measured with in-game pings (community), so the side that's
	-- not doing it hears it from across a site.
	device = curve(
		{ { 0, 1 }, { 5, 1 }, { 25, 0.6 }, { 50, 0.3 }, { 60, 0 } },
		"community",
		"note.com (yuyujan11_valo, 2023): plant and defuse sounds heard at 60 m, measured with in-game pings; the shape between is ours"
	),
	-- Its beeping carries further: it's how everyone near a site keeps
	-- track of the clock, out past the blast's 35 m.
	beep = curve({ { 0, 1 }, { 5, 1 }, { 20, 0.6 }, { 35, 0.35 }, { 50, 0 } }, "estimate", "Heard past the blast's edge, so a player who's running clear still hears it; no published radius"),
	-- And the blast, like gunfire, across the map.
	blast = curve({ { 0, 1 }, { 10, 1 }, { 40, 0.7 }, { 100, 0.4 }, { 200, 0 } }, "estimate", "Heard map-wide, as a gunshot is"),
	-- Abilities show on the minimap's sound circle too (Patch 1.0's
	-- 'ability sounds'), so they have an edge (system 17).
	ability = curve(
		{ { 0, 1 }, { 3, 1 }, { 15, 0.6 }, { 28, 0.3 }, { 30, 0 } },
		"estimate",
		"Heard about as far as footsteps, a little further; no published radius"
	),
	-- The spike dropped: heard faintly out to about 50 m.
	drop = curve(
		{ { 0, 1 }, { 3, 1 }, { 15, 0.5 }, { 35, 0.15 }, { 50, 0 } },
		"community",
		"note.com (yuyujan11_valo, 2023): the drop heard at '50 m?', very quietly there; the shape between is ours"
	),
}

-- Walls -------------------------------------------------------------------------

-- Sound through walls is filtered: Riot's audio director names occlusion,
-- 'filtering change based on objects between the emitter and the listener'
-- (Ask VALORANT, Apr 12). Ours casts from your camera to the sound through
-- the level and filters by how much is in the way.
SoundConfig.Occlusion = {
	thin = p(0.2, "estimate", "Metres of wall that are 'thin'"),
	thick = p(2, "estimate", "Metres of wall that are 'thick'"),
	thinCutoff = p(1500, "estimate", "Hz: a low-pass this low through a thin wall"),
	thickCutoff = p(500, "estimate", "Hz: and this low through a thick one, in between by the log of the thickness"),
	thinGain = p(0.7, "estimate", "Volume through a thin wall"),
	thickGain = p(0.35, "estimate", "Volume through a thick wall"),
	maxPieces = p(4, "estimate", "Pieces of the level the cast passes through at most"),
}

-- Gunshots lose their top end with distance, as the air takes it.
SoundConfig.Air = {
	near = p(10, "estimate", "Metres before a gunshot starts to dull"),
	far = p(150, "estimate", "Metres by which it is at the far cutoff"),
	farCutoff = p(4000, "estimate", "Hz: a low-pass this low at the far distance, in between by the log of the distance"),
}

-- Mixing ------------------------------------------------------------------------

SoundConfig.OPEN_CUTOFF = 20000 -- Hz: the filter's frequency when nothing is in the way

-- Every asset is turned up or down to the same peak before its sound's own
-- volume, so no take is louder than the next and the volumes below compare
-- sounds, not recordings.
SoundConfig.Level = p(0.5, "estimate", "Peak every asset is evened out to, leaving room for sounds that overlap")
SoundConfig.MaxGain = p(4, "estimate", "Most an asset is turned up to reach it (12 dB), so a quiet take's noise stays down")

-- During the buy phase you can't hear the other side (community: Tracker
-- Network, 'Which sounds can your enemies hear').
SoundConfig.MuteEnemiesInBuyPhase = true

-- Kills in a life step each kill sound up in pitch, like the reference's
-- kill sounds, which change with each kill in a round.
SoundConfig.KillPitchStep = p(0.06, "estimate", "Playback speed added per kill after the first, up to the fifth")

-- A weapon given into another slot switches to it on your client at once, and
-- the give lands a moment later as a correction that draws it again: the slot
-- in hand drawn again this soon after a draw is that same draw.
SoundConfig.RedrawGap = p(0.5, "estimate", "Seconds after a draw in which the slot in hand drawn again makes no second draw sound; longer than a round trip")

-- The sounds ---------------------------------------------------------------------

local LIBRARY = "Pro Sound Effects, in the Creator Store's free library"

local function sound(volume: number, pitchJitter: number, voices: number, assets: { Asset }, pitch: number?): Sound
	return { assets = assets, volume = volume, pitch = pitch or 1, pitchJitter = pitchJitter, voices = voices, source = LIBRARY }
end

local function asset(id: number, title: string, peak: number, start: number?, worldPeak: number?): Asset
	return { id = id, title = title, peak = peak, start = start or 0, worldPeak = worldPeak }
end

local function cue(at: number, sound: string): Cue
	return { at = at, sound = sound }
end

-- Picked by title and by Pro Sound Effects' own description of each
-- recording, and measured in Studio: where the sound starts from its
-- waveform, and its peaks as it plays, on each path, from analyzers wired
-- to it (docs/research/08-sound.md, section 6). Volumes and pitches are
-- estimates, to be set by ear. All courtesy of Pro Sound Effects.
SoundConfig.Sounds = {
	-- Feet. No single footstep on a hard floor turned up, so steps are foot
	-- stomps, and a landing is the same stomps lower and heavier.
	step = sound(0.8, 0.06, 6, {
		asset(9114523345, "Foot Stomp 3 (SFX)", 0.183),
		asset(9114523358, "Foot Stomp 4 (SFX)", 0.217),
		asset(9114523612, "Foot Stomp 6 (SFX)", 0.393),
		asset(9114523629, "Foot Stomp 7 (SFX)", 0.178),
	}),
	land = sound(1, 0.04, 3, {
		asset(9114523612, "Foot Stomp 6 (SFX)", 0.393),
		asset(9114523358, "Foot Stomp 4 (SFX)", 0.217),
	}, 0.82),
	softLand = sound(0.45, 0.04, 2, {
		asset(9114523345, "Foot Stomp 3 (SFX)", 0.183),
		asset(9114523629, "Foot Stomp 7 (SFX)", 0.178),
	}, 0.9),
	jump = sound(1, 0.05, 2, {
		asset(9116199047, "Knife Wipe Fast Swipes On Trousers 4 (SFX)", 0.029),
	}),
	-- Shots. The library has an assault rifle and a big sniper rifle; the
	-- Phantom's suppressed rifle is a suppressed pistol.
	rifle = sound(1, 0.02, 10, {
		asset(9114550557, "Galil Assault Rifle 1 (SFX)", 0.784, 0, 0.776),
	}),
	suppressed = sound(0.7, 0.03, 10, {
		asset(9119135215, "Silenced Pistol 1 (SFX)", 0.770, 0, 0.73),
		asset(9119134567, "Silenced Pistol 5 (SFX)", 0.770, 0, 0.75),
		asset(9119135228, "Silenced Pistol 3 (SFX)", 0.771, 0, 0.75),
		asset(9119134978, "Silenced Pistol 7 (SFX)", 0.769, 0, 0.75),
	}),
	sniper = sound(1, 0.01, 3, {
		asset(9118174271, "Rifle Single Shots 7 (SFX)", 0.398),
		asset(9118174539, "Rifle Single Shots 8 (SFX)", 0.394),
	}),
	revolver = sound(1, 0.02, 4, {
		asset(9119296692, "Smith Wesson 357 Magnum 2 (SFX)", 0.620, 0, 0.509),
		asset(9119296944, "Smith Wesson 357 Magnum 4 (SFX)", 0.610, 0, 0.51),
		asset(9119297250, "Smith Wesson 357 Magnum 8 (SFX)", 0.614, 0, 0.53),
	}),
	-- A .45 magnum pistol, raised a little to sound lighter: the library's
	-- 9 mm pistol shots are all silenced.
	pistol = sound(0.85, 0.03, 6, {
		asset(9117400585, "Pistol Single Shots 2 (SFX)", 0.385),
	}, 1.08),
	dry = sound(0.6, 0.02, 2, {
		asset(9117029050, "Moviola Toggle Switch Single Clicks Sharp 14 (SFX)", 0.268),
		asset(9120102194, "Toggle Switch Metal Industrial Equipment 10 (SFX)", 0.239, 0.02),
	}),
	-- Reload parts (SoundConfig.Weapons puts them in order)
	magOut = sound(0.7, 0.03, 3, {
		asset(9113104176, "Ammo Magazine 1 (SFX)", 0.583, 0.04),
	}),
	magIn = sound(0.8, 0.03, 3, {
		asset(9113104517, "Ammo Magazine 2 (SFX)", 0.546, 0.22),
	}),
	rack = sound(0.8, 0.03, 3, {
		asset(9117889191, "Ppsh Burp Gun 7 (SFX)", 0.188, 1.7),
	}),
	boltOpen = sound(0.8, 0.03, 2, {
		asset(9113027869, "470 Rifle 1 (SFX)", 0.166, 0.27),
		asset(9113027964, "470 Rifle 3 (SFX)", 0.269, 0.63),
	}),
	latch = sound(0.7, 0.03, 2, {
		asset(9116722545, "Metal Latches 1 (SFX)", 0.334),
	}, 1.15),
	-- A shell or a single round going in: the magazine's click, smaller.
	shell = sound(0.6, 0.05, 3, {
		asset(9113104517, "Ammo Magazine 2 (SFX)", 0.546, 0.22),
	}, 1.35),
	-- Draws
	drawRifle = sound(0.6, 0.03, 2, {
		asset(9116362481, "Machine Gun Movement 2 (SFX)", 0.472, 0.08),
	}),
	drawPistol = sound(0.6, 0.03, 2, {
		asset(9114701864, "Gun From Holster 1 (SFX)", 0.553, 0.05),
	}),
	knife = sound(0.7, 0.03, 2, {
		asset(9116190984, "Knife Fast Scraping Draws Pull Out 1 (SFX)", 0.113),
		asset(9116190959, "Knife Fast Scraping Draws Pull Out 17 (SFX)", 0.180, 0.2),
	}),
	-- The knife's swings and strikes (system 10): sharp sword swishes for
	-- the slash, heavy arm-swing whooshes for the stab, a knife into flesh
	-- for a hit, and a blade striking a metal rod, a little lower, for a
	-- wall (the library has no blade striking stone).
	slash = sound(0.7, 0.05, 3, {
		asset(9126014013, "Swish Med High End Sharp Swords Fast Punches (SFX)", 0.468, 0.15),
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}),
	stab = sound(0.8, 0.04, 2, {
		asset(9120728815, "Whoosh Heavy Punches 1 (SFX)", 0.483, 0.11),
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}),
	knifeHit = sound(0.8, 0.04, 3, {
		asset(9114487207, "Flesh Stab 9 (SFX)", 0.320, 0.12),
		asset(9114487004, "Flesh Stab 5 (SFX)", 0.355, 0.07),
	}),
	knifeWall = sound(0.6, 0.05, 3, {
		asset(9113449513, "Blade Hits Metal Rod On Knife Impacts 9 (SFX)", 0.504),
		asset(9113449377, "Blade Hits Metal Rod On Knife Impacts 5 (SFX)", 0.498),
	}, 0.9),
	-- Hits
	hitBody = sound(0.6, 0.03, 4, {
		asset(9113518281, "Body Hits Thuds 1 (SFX)", 0.345),
		asset(9113518286, "Body Hits Thuds 2 (SFX)", 0.484),
		asset(9113518280, "Body Hits Thuds 3 (SFX)", 0.462),
		asset(9113518397, "Body Hits Thuds 4 (SFX)", 0.448),
	}),
	headshot = sound(0.8, 0.02, 3, {
		asset(9125362418, "Anvil Hits Ringing Metal Clinks Some Muted 3 (SFX)", 0.495),
	}),
	kill = sound(0.8, 0, 2, {
		asset(9126073318, "Synth Sparkle Tone High Pitch Bell Tone Ding (SFX)", 0.182, 0.09),
	}),
	-- The spike (system 12). Its beep: one short high tone, 0.15 s.
	spikeBeep = sound(0.7, 0, 6, {
		asset(9119142417, "Single Tone Single High Pitch Beep Tones 1 (SFX)", 0.271),
	}),
	-- Planting: "Arming and Setting Off, Home Alarm System, Console Beeps",
	-- from its first beep: a run of beeps 3.4 s long, inside the 4 s plant.
	spikePlant = sound(0.8, 0, 4, {
		asset(9113084401, "Alarm Beeps 8 (SFX)", 0.120, 0.65),
	}),
	-- Defusing: fast even beeps, replayed from the start as they run out
	-- (SoundConfig.Spike.defuseLoop), for as long as the defuse goes on.
	spikeDefuse = sound(0.6, 0, 4, {
		asset(9119761110, "Synth Beeps Constant Fast Tracker Scanner 1 (SFX)", 0.370, 0.21),
	}),
	-- Defused: "Metallic Tone Descending in Pitch".
	spikeDefused = sound(0.9, 0, 2, {
		asset(9116227010, "Laser Blasts Transporter Elements 4 (SFX)", 0.677, 0.09, 0.591),
	}),
	-- The blast: "Individual Explosion Booms, Long Rolling Tails, Sharp
	-- Impact, Some Rumble".
	spikeBlast = sound(1, 0, 2, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}),
	-- Dropped: "to Concrete, Solid Metal Thud, Rattle".
	spikeDrop = sound(0.7, 0.03, 2, {
		asset(9125679182, "Metal Object Drop To Concrete Solid Metal Thud 2 (SFX)", 0.710, 0.3, 0.682),
	}),
	-- Picked up: a latch, as it's stowed.
	spikePickup = sound(0.6, 0.03, 2, {
		asset(9116722545, "Metal Latches 1 (SFX)", 0.334),
	}),
	-- Abilities (system 17), from the knife's measured whooshes: Updraft's
	-- gust low and heavy, Tailwind's dash quick, and its gust readying a
	-- thin swish, slowed.
	gust = sound(0.9, 0.03, 3, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.75),
	dash = sound(0.9, 0.03, 3, {
		asset(9120728815, "Whoosh Heavy Punches 1 (SFX)", 0.483, 0.11),
	}, 1.15),
	windup = sound(0.6, 0.03, 3, {
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}, 0.6),
	-- Cloudburst (system 18): the throw the same thin swish, quick, and the
	-- burst Updraft's gust, slowed right down.
	smokeThrow = sound(0.6, 0.03, 3, {
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}, 1.1),
	smokeBurst = sound(0.8, 0.03, 3, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.55),
}

-- What each kind of cast sounds like (AbilitySim.Cast's kind, and a
-- thrown cloud's burst), heard as the ability curve says (systems 17 and
-- 18).
SoundConfig.Abilities = {
	lift = "gust",
	dash = "dash",
	ready = "windup",
	throw = "smokeThrow",
	cloud = "smokeBurst",
} :: { [string]: string }

-- The spike's sounds (system 12): its beeps, its defuse, its blast and its
-- drop from where it is, and the plant's or the defuse's beeping from
-- whoever is doing it, theirs on the Self bus and others' out in the world.
SoundConfig.Spike = {
	beep = "spikeBeep",
	plant = "spikePlant",
	defuse = "spikeDefuse",
	defused = "spikeDefused",
	blast = "spikeBlast",
	drop = "spikeDrop",
	pickup = "spikePickup",
	-- Where spikeDefuse's run of beeps ends (seconds into the take), to play
	-- it again from its start.
	defuseLoop = p(4.38, "measured", "Synth Beeps Constant Fast Tracker Scanner 1: its beeps run from 0.22 s to 4.38 s"),
	-- Once its half is saved, a defuse sounds higher: 'the audio cue given
	-- when defusing changes to a higher pitch' (the VALORANT Wiki).
	halfPitch = p(1.25, "estimate", "A defuse from the half, times its pitch before"),
}

-- Which sounds each weapon makes, by WeaponConfig id. The library has five
-- gunshots (a rifle, a suppressed pistol, a big rifle, a revolver and a
-- pistol), so each gun takes the nearest and its own pitch (playback
-- speed): higher for a lighter gun, lower for a heavier one, so no two
-- sound the same. Reloads play in parts as they go, at fractions of the
-- reload's time (estimates: Riot publishes how long a reload takes, not
-- when its parts sound); a gun that loads a round at a time plays its parts
-- for each round. The last part's recording is skipped to just before its
-- click, so the click comes on its time, before the reload ends.
local MAGAZINE = { cue(0.12, "magOut"), cue(0.55, "magIn"), cue(0.82, "rack") }
local BOLT = { cue(0.08, "boltOpen"), cue(0.5, "magIn"), cue(0.82, "rack") }
local CYLINDER = { cue(0.1, "latch"), cue(0.5, "magIn"), cue(0.82, "latch") }
local ROUND = { cue(0.6, "shell") } -- each round of a round-at-a-time reload
local BREAK = { cue(0.12, "latch"), cue(0.5, "shell"), cue(0.85, "latch") } -- open, load, close
local BOX = { cue(0.08, "latch"), cue(0.3, "magOut"), cue(0.6, "magIn"), cue(0.8, "latch"), cue(0.9, "rack") } -- a machine gun's cover and box

export type WeaponSounds = {
	shot: string?,
	pitch: number?, -- times the shot sound's own pitch
	reload: { Cue }?,
	draw: string,
	curve: string,
	-- A knife's: its two swings, the blade going in (the one swinging hears
	-- it when the server confirms the hit, and the others where it happens)
	-- and striking the level.
	slash: string?,
	stab: string?,
	hit: string?,
	wall: string?,
}

local function gun(shot: string, pitch: number, reload: { Cue }, draw: string, curve: string?): WeaponSounds
	return { shot = shot, pitch = pitch, reload = reload, draw = draw, curve = curve or "gunshot" }
end

SoundConfig.Weapons = {
	classic = gun("pistol", 1, MAGAZINE, "drawPistol"),
	shorty = gun("sniper", 0.8, BREAK, "drawPistol"),
	frenzy = gun("pistol", 1.15, MAGAZINE, "drawPistol"),
	ghost = gun("suppressed", 1.12, MAGAZINE, "drawPistol", "suppressed"),
	bandit = gun("revolver", 1.12, MAGAZINE, "drawPistol"),
	sheriff = gun("revolver", 1, CYLINDER, "drawPistol"),
	stinger = gun("rifle", 1.2, MAGAZINE, "drawRifle"),
	spectre = gun("suppressed", 1.05, MAGAZINE, "drawRifle", "suppressed"),
	bucky = gun("sniper", 0.72, ROUND, "drawRifle"),
	judge = gun("sniper", 0.85, MAGAZINE, "drawRifle"),
	bulldog = gun("rifle", 1.06, MAGAZINE, "drawRifle"),
	guardian = gun("rifle", 0.92, MAGAZINE, "drawRifle"),
	phantom = gun("suppressed", 1, MAGAZINE, "drawRifle", "suppressed"),
	vandal = gun("rifle", 1, MAGAZINE, "drawRifle"),
	warden = gun("rifle", 0.88, MAGAZINE, "drawRifle"),
	marshal = gun("sniper", 1.12, ROUND, "drawRifle"),
	outlaw = gun("sniper", 0.92, BREAK, "drawRifle"),
	operator = gun("sniper", 1, BOLT, "drawRifle"),
	ares = gun("rifle", 0.94, BOX, "drawRifle"),
	odin = gun("rifle", 0.86, BOX, "drawRifle"),
	knife = { draw = "knife", curve = "melee", slash = "slash", stab = "stab", hit = "knifeHit", wall = "knifeWall" },
	-- The spike in hand (system 12): only its draw; its plant, defuse and
	-- beeps are SoundConfig.Spike's.
	spike = { draw = "drawRifle", curve = "melee" },
} :: { [string]: WeaponSounds }

return SoundConfig
