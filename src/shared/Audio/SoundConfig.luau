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
	-- Omen arriving by Shrouded Step (system 42): heard out to 12.5 m.
	arrival = curve(
		{ { 0, 1 }, { 3, 1 }, { 10, 0.6 }, { 12, 0.3 }, { 12.5, 0 } },
		"community",
		"VALORANT Wiki, Shrouded Step: arrival audio cue radius 12.5 m (game files); the shape within is ours"
	),
	-- Omen arriving as a Shade by From the Shadows (system 43), forming
	-- there, or sent back: heard out to 22.5 m.
	shade = curve(
		{ { 0, 1 }, { 3, 1 }, { 15, 0.6 }, { 21, 0.3 }, { 22.5, 0 } },
		"confirmed",
		"Patch 0.49: 'The attenuation radius of the arrival sound on Omen's From the Shadows has been reduced to 2250', read as centimetres (the VALORANT Wiki: 22.5 m); the shape within is ours"
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
	-- Blade Storm (system 19): each throw the thin swish, quicker still; a
	-- knife's hit on the body the blade going in, as the knife's; and the
	-- cast a knife's draw slowed down, as the five come out.
	kunai = sound(0.7, 0.05, 4, {
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}, 1.25),
	kunaiHit = sound(0.8, 0.04, 4, {
		asset(9114487207, "Flesh Stab 9 (SFX)", 0.320, 0.12),
		asset(9114487004, "Flesh Stab 5 (SFX)", 0.355, 0.07),
	}),
	storm = sound(0.8, 0.02, 2, {
		asset(9116190959, "Knife Fast Scraping Draws Pull Out 17 (SFX)", 0.180, 0.2),
	}, 0.7),
	-- Drift (system 20): a stand-in for the glide's wind, Updraft's gust
	-- slowed right down and quiet, played over and over (SoundConfig.Drift).
	glide = sound(0.35, 0.08, 4, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.5),
	-- Curveball (system 30): the flare lit in hand is Updraft's gust, quick
	-- and quiet; its throw, Cloudburst's thin swish; and its pop, the spike
	-- blast's crack, sped right up so it snaps.
	flareEquip = sound(0.5, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 1.4),
	flareThrow = sound(0.6, 0.03, 3, {
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}, 1),
	flarePop = sound(0.7, 0.03, 3, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 1.7),
	-- Hot Hands (system 31): the fireball lit in hand is the gust again,
	-- lower than the flare's; its throw the thin swish, slowed; its burst the
	-- spike blast's crack slowed down to a thump; and its fire the gust
	-- slowed right down, quiet, again and again while it burns.
	fireballEquip = sound(0.5, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 1.15),
	fireballThrow = sound(0.6, 0.03, 3, {
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}, 0.85),
	fireBurst = sound(0.6, 0.03, 3, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 0.75),
	fireCrackle = sound(0.3, 0.1, 4, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.4),
	-- Blaze (system 32): its flame lit in hand is the gust again, lower
	-- still; the wall sent out, the dash's heavy whoosh, slowed; and its
	-- rising, the spike blast's crack slowed right down to a roar. While it
	-- stands it crackles as Hot Hands' fire does.
	wallEquip = sound(0.5, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.95),
	wallSend = sound(0.7, 0.03, 3, {
		asset(9120728815, "Whoosh Heavy Punches 1 (SFX)", 0.483, 0.11),
	}, 0.8),
	wallRise = sound(0.7, 0.03, 3, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 0.5),
	-- Run it Back (system 33): its mark lit, the gust slowed right down; his
	-- body going, the dash's heavy whoosh, slowed further than Blaze's; and
	-- his rising at the mark, the spike blast's crack, lower than the wall's.
	markLit = sound(0.6, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.7),
	fizzle = sound(0.7, 0.03, 3, {
		asset(9120728815, "Whoosh Heavy Punches 1 (SFX)", 0.483, 0.11),
	}, 0.6),
	markRise = sound(0.7, 0.03, 3, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 0.4),
	-- The Healing Orb (system 36): the orb lit in hand is the gust again,
	-- higher than the flare's; its heal, the kill's bell slowed to a soft,
	-- low chime.
	orbEquip = sound(0.45, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 1.7),
	healChime = sound(0.6, 0.02, 3, {
		asset(9126073318, "Synth Sparkle Tone High Pitch Bell Tone Ding (SFX)", 0.182, 0.09),
	}, 0.6),
	-- The Slow Orb (system 37): the orb lit in hand is the gust again, as
	-- high as the Healing Orb's but quicker; its throw, the thin swish,
	-- quick; its burst, the spike blast's crack sped up, as ice breaking;
	-- and a run or a jump through its field, a foot stomp pitched up into a
	-- crunch.
	slowEquip = sound(0.45, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 1.55),
	slowThrow = sound(0.6, 0.03, 3, {
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}, 1.15),
	slowBurst = sound(0.6, 0.03, 3, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 1.3),
	iceCrunch = sound(0.5, 0.08, 4, {
		asset(9114523345, "Foot Stomp 3 (SFX)", 0.183),
		asset(9114523629, "Foot Stomp 7 (SFX)", 0.178),
	}, 1.6),
	-- The Barrier Orb (system 38): the orb lit in hand is the gust again,
	-- between the Slow Orb's and the flare's; the wall rising, the spike
	-- blast's crack a little low, as ice forming; its fortifying, the same
	-- crack quiet and sped right up, as ice setting; and a piece breaking,
	-- the crack sped up between the two, as ice shattering.
	barrierEquip = sound(0.45, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 1.45),
	barrierRise = sound(0.7, 0.03, 3, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 0.9),
	barrierFortify = sound(0.4, 0.03, 3, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 1.9),
	barrierBreak = sound(0.7, 0.04, 4, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 1.55),
	-- The Resurrection (system 39): the orb lit in hand is the gust again,
	-- the lowest of hers; a body starting to rise, the heal's bell slowed
	-- further and louder; and the crystal bursting as they're back, the
	-- spike blast's crack sped up past the Barrier Orb's breaking.
	reviveEquip = sound(0.5, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 1.3),
	reviveChime = sound(0.8, 0.02, 3, {
		asset(9126073318, "Synth Sparkle Tone High Pitch Bell Tone Ding (SFX)", 0.182, 0.09),
	}, 0.45),
	reviveBurst = sound(0.7, 0.04, 3, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 1.75),
	-- Dark Cover (system 40): the orb in hand the thick whoosh, low; sent,
	-- the thin swish slowed right down; the smoke forming Cloudburst's
	-- burst, deeper still; and its warning, near its end, the heal's bell
	-- slowed to a low tone.
	darkEquip = sound(0.45, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.85),
	darkSend = sound(0.6, 0.03, 3, {
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}, 0.5),
	darkForm = sound(0.9, 0.03, 3, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.4),
	darkWarn = sound(0.6, 0.02, 3, {
		asset(9126073318, "Synth Sparkle Tone High Pitch Bell Tone Ding (SFX)", 0.182, 0.09),
	}, 0.3),
	-- Paranoia (system 41): the orb in hand the thick whoosh, lower than
	-- Dark Cover's; sent, the heavy whoosh slowed right down; and touched by
	-- it, the spike's defuse tone slowed, as the dark closes in.
	paranoiaEquip = sound(0.45, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.7),
	paranoiaSend = sound(0.8, 0.03, 3, {
		asset(9120728815, "Whoosh Heavy Punches 1 (SFX)", 0.483, 0.11),
	}, 0.45),
	nearsight = sound(0.6, 0.02, 2, {
		asset(9116227010, "Laser Blasts Transporter Elements 4 (SFX)", 0.677, 0.09, 0.591),
	}, 0.5),
	-- Shrouded Step (system 42): in hand the thick whoosh, lowest of his;
	-- fired, the spike's defuse tone slowed right down, as the shadow
	-- takes him; and his arrival the same tone faster, as he forms there.
	stepEquip = sound(0.45, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.6),
	stepGo = sound(0.8, 0.03, 3, {
		asset(9116227010, "Laser Blasts Transporter Elements 4 (SFX)", 0.677, 0.09, 0.591),
	}, 0.35),
	stepArrive = sound(0.8, 0.03, 3, {
		asset(9116227010, "Laser Blasts Transporter Elements 4 (SFX)", 0.677, 0.09, 0.591),
	}, 0.7),
	-- From the Shadows (system 43): its map in hand the thick whoosh, lowest
	-- of all; fired, the heavy whoosh slowed right down, heard across the
	-- map; his Shade arriving, the spike's defuse tone slowed further than
	-- Shrouded Step's; forming there, the same tone faster; and sent back,
	-- the thin swish slowed, as the Shade's torn away.
	shadowEquip = sound(0.45, 0.03, 2, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 0.5),
	shadowGo = sound(0.9, 0.03, 3, {
		asset(9120728815, "Whoosh Heavy Punches 1 (SFX)", 0.483, 0.11),
	}, 0.35),
	shadowArrive = sound(0.8, 0.03, 3, {
		asset(9116227010, "Laser Blasts Transporter Elements 4 (SFX)", 0.677, 0.09, 0.591),
	}, 0.28),
	shadowForm = sound(0.8, 0.03, 3, {
		asset(9116227010, "Laser Blasts Transporter Elements 4 (SFX)", 0.677, 0.09, 0.591),
	}, 0.55),
	shadowBreak = sound(0.8, 0.03, 3, {
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}, 0.45),
	-- The Recon Bolt (system 44): the bow in hand the rifle's draw raised,
	-- as something lighter; its string drawn back, the knife's scrape
	-- slowed right down; loosed, the thin swish, quicker than Blade Storm's
	-- knives; in the air, the thick whoosh sped right up and quiet, as it
	-- whistles; stuck, the knife's strike on a wall sped up, as the head
	-- bites; each pulse, the kill's bell slowed, as a ping; and shot to
	-- pieces, the spike blast's crack sped up past anything of Sage's.
	boltEquip = sound(0.6, 0.03, 2, {
		asset(9116362481, "Machine Gun Movement 2 (SFX)", 0.472, 0.08),
	}, 1.2),
	boltNock = sound(0.6, 0.03, 2, {
		asset(9116190984, "Knife Fast Scraping Draws Pull Out 1 (SFX)", 0.113),
	}, 0.55),
	boltLoose = sound(0.7, 0.03, 3, {
		asset(9119696677, "Swishes Thin Fast Singles Knife 4 (SFX)", 0.323, 0.22),
	}, 1.35),
	boltFlight = sound(0.4, 0.05, 4, {
		asset(9120742716, "Whoosh Thick Quick Multiple Variations 2 (SFX)", 0.737, 0.15, 0.70),
	}, 1.9),
	boltStick = sound(0.7, 0.05, 4, {
		asset(9113449513, "Blade Hits Metal Rod On Knife Impacts 9 (SFX)", 0.504),
		asset(9113449377, "Blade Hits Metal Rod On Knife Impacts 5 (SFX)", 0.498),
	}, 1.3),
	reconPulse = sound(0.9, 0.02, 4, {
		asset(9126073318, "Synth Sparkle Tone High Pitch Bell Tone Ding (SFX)", 0.182, 0.09),
	}, 0.8),
	boltBreak = sound(0.6, 0.04, 4, {
		asset(9126083958, "Synth Thunder Cracks Individual Explosion Booms 4 (SFX)", 0.414, 0.08, 0.408),
	}, 2.2),
}

-- What each kind of cast sounds like (AbilitySim.Cast's kind, a thrown
-- cloud's burst, a flare's pop, a fireball's burst and its fire, Blaze's
-- wall rising, a Phoenix's body going in Run it Back, a heal of the
-- Healing Orb's starting, a Slow Orb's burst, a run or a jump through its
-- field, Sage's wall rising, fortifying and a piece of it breaking, a body
-- she brings back rising and bursting out, Omen's orb sent, its smoke
-- forming and warning that it's going, his Paranoia sent, his Shrouded
-- Step fired and his arrival, which is heard only as far as the arrival
-- curve says, and his From the Shadows fired, heard across the map, and
-- his Shade arriving, forming and sent back, heard only as far as the
-- shade curve says, and Sova's Recon Bolt's string drawn back, which only
-- the one drawing it hears, and its bolt in the air, stuck, pulsing and
-- shot to pieces), heard as the ability curve says (systems 17 to 19,
-- 30 to 33 and 36 to 44). Blade Storm's knives drawn again sound as their
-- draw does, and so does an ability put in hand (Curveball's flare, Hot
-- Hands' fireball, Blaze's flame, the Healing Orb, the Slow Orb, the
-- Barrier Orb, the Resurrection's orb), which only the one drawing it
-- hears. The orbs' tries make no sound: only a heal or a return does.
SoundConfig.Abilities = {
	lift = "gust",
	dash = "dash",
	ready = "windup",
	throw = "smokeThrow",
	cloud = "smokeBurst",
	storm = "storm",
	flare = "flareThrow",
	pop = "flarePop",
	fireball = "fireballThrow",
	fire = "fireBurst",
	burning = "fireCrackle",
	flame = "wallSend",
	wall = "wallRise",
	mark = "markLit",
	fizzle = "fizzle",
	rise = "markRise",
	healing = "healChime",
	slow = "slowThrow",
	ice = "slowBurst",
	crunch = "iceCrunch",
	barrier = "barrierRise",
	fortify = "barrierFortify",
	shatter = "barrierBreak",
	reviving = "reviveChime",
	revived = "reviveBurst",
	smoke = "darkSend",
	darkcover = "darkForm",
	fading = "darkWarn",
	paranoia = "paranoiaSend",
	step = "stepGo",
	arrive = "stepArrive",
	shadows = "shadowGo",
	shade = "shadowArrive",
	form = "shadowForm",
	home = "shadowBreak",
	bolt = "boltLoose",
	nock = "boltNock",
	boltflight = "boltFlight",
	boltstick = "boltStick",
	pulse = "reconPulse",
	boltbreak = "boltBreak",
} :: { [string]: string }

-- The casts heard on a curve of their own, by AbilitySim.Cast's kind, and
-- the curve (SoundConfig.Curves): Shrouded Step's arrival (system 42), and
-- From the Shadows fired, as far as the spike's blast, and its Shade
-- arriving, forming and sent back (system 43).
SoundConfig.CastCurves = {
	arrive = "arrival",
	shadows = "blast",
	shade = "shade",
	form = "shade",
	home = "shade",
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

-- Jett's glide (Drift, system 20). The reference's has a sound of its own,
-- which others hear: 'Fixed a bug where Drift's passive gliding SFX was
-- audible from the other side of Astra's Cosmic Divide' (Patch 12.04). No
-- wind that runs on turned up in the library yet, so ours is its gust again
-- and again for as long as the glide lasts: yours on the Self bus, and
-- others' on them, out to the ability curve's edge.
SoundConfig.Drift = {
	sound = "glide",
	every = p(0.3, "estimate", "Seconds from one gust of a glide to the next, so they run together"),
	ownVolume = p(0.6, "estimate", "Your own glide against someone else's next to you, so it doesn't cover their steps"),
}

-- Deafened (system 41): while Omen's Paranoia has someone nearsighted,
-- what they hear in the world and what they make themselves is muffled and
-- quieter, clearing as the nearsight clears. The VALORANT Wiki's Status
-- Effect page has a deafened player's audio 'severely dampened'
-- (community), with no numbers. The touch itself sounds on the UI bus,
-- which isn't muffled, so it's heard as the dark closes in.
SoundConfig.Deafen = {
	sound = "nearsight",
	cutoff = p(400, "estimate", "Hz: the World and Self buses' low-pass, deafened, so little but the low end gets through"),
	volume = p(0.35, "estimate", "Their level deafened, about 9 dB down"),
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
	-- and striking the level. Blade Storm's knives have a hit too, for a
	-- body hit, which the thrower hears with the confirm (system 19).
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
	-- Blade Storm's knives (system 19): thrown, heard as far as an
	-- ability, and never reloaded.
	kunai = { shot = "kunai", pitch = 1, draw = "knife", curve = "ability", hit = "kunaiHit" },
	-- Curveball's flare (system 30): only its draw; its throw and pop are
	-- the ability's (SoundConfig.Abilities).
	flare = { draw = "flareEquip", curve = "ability" },
	-- Hot Hands' fireball (system 31): the same, its throw, burst and fire
	-- the ability's.
	fireball = { draw = "fireballEquip", curve = "ability" },
	-- Blaze's flame (system 32): the same, the wall sent out and rising the
	-- ability's.
	flamewall = { draw = "wallEquip", curve = "ability" },
	-- The Healing Orb (system 36): the same, its heal the ability's.
	healorb = { draw = "orbEquip", curve = "ability" },
	-- The Slow Orb (system 37): the same, its throw, burst and crunch the
	-- ability's.
	iceorb = { draw = "slowEquip", curve = "ability" },
	-- The Barrier Orb (system 38): the same, its wall rising, fortifying
	-- and breaking the ability's.
	wallorb = { draw = "barrierEquip", curve = "ability" },
	-- The Resurrection's orb (system 39): the same, a body rising and
	-- bursting out the ability's.
	revive = { draw = "reviveEquip", curve = "ability" },
	-- Dark Cover's orb (system 40): the same, the orb sent, its smoke
	-- forming and warning the ability's.
	smokeorb = { draw = "darkEquip", curve = "ability" },
	-- Paranoia's orb (system 41): the same, the orb sent the ability's.
	blindorb = { draw = "paranoiaEquip", curve = "ability" },
	-- Shrouded Step (system 42): the same, its firing and his arrival the
	-- ability's.
	stepmark = { draw = "stepEquip", curve = "ability" },
	-- From the Shadows' map (system 43): the same, its firing, his Shade's
	-- arrival, its forming and its going back the ability's.
	shadowmap = { draw = "shadowEquip", curve = "ability" },
	-- The Recon Bolt's bow (system 44): the same, its string drawn back,
	-- the bolt loosed, in the air, stuck, pulsing and broken the ability's.
	bow = { draw = "boltEquip", curve = "ability" },
} :: { [string]: WeaponSounds }

return SoundConfig
