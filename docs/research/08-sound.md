# System 8: Sound

This covers what the game sounds like and, more importantly, what it tells you: footsteps you
hear running and never walking or crouching, landings, gunshots that say where they came from,
reloads, weapon draws, and the hit, headshot and kill sounds a shooter hears. Agent voices,
abilities, the spike, music and the menus are separate work.

As before, everything comes from Riot's posts and patch notes and from community write-ups. Riot
has said a good deal about what its sound is for, and almost nothing in numbers. No game files,
memory, network traffic or audio from the game were used, and none of the reference's sounds is
in the project: every sound is one of Pro Sound Effects' recordings in Roblox's free library on
the Creator Store, played by asset id.
Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Measured** | Ours, measured from a public source: here, the waveforms of the library sounds we play |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- Running makes footsteps that anyone near enough hears, enemies and teammates alike. Walking
  (Shift) and crouching make none. That's the walk key's whole purpose.
- Footsteps are loud and even right out to the edge of their range, then stop. Riot built them to
  be heard rather than to tell you how far away someone is.
- Jumping makes no sound for others. Landing does, on the level you left or lower. Jumping up
  onto a crate is silent.
- Gunshots carry across the map. The suppressed weapons, the Phantom among them, are much harder
  to hear.
- Reloading can be heard. Switching weapons, aiming down sights and picking a weapon up can't.
- Sound through a wall is muffled.
- During the buy phase you hear nothing from the other side.
- The shooter hears each hit confirmed: a body hit, a distinct headshot sound, and a kill sound.

## 2. Publicly documented details

From Riot:

| Fact | Status | Source |
| --- | --- | --- |
| "The footstep radius is set up to give players who hear enemy footsteps time to use an ability and re-equip a weapon before they are in danger" | Confirmed | Peter Zinda, Audio Director, [Ask VALORANT #6](https://playvalorant.com/en-gb/news/game-updates/ask-valorant-6/) |
| "We optimize for making sure footsteps are heard, as opposed to optimizing for portraying distance"; "What this looks like is an attenuation curve that is somewhat flat, versus one that drops off a lot over distance" | Confirmed | The same answer |
| Why: "it is essential that you don't miss a footstep"; "not hearing a footstep and getting killed by someone you knew had to run to get to you is very tilting"; "If the game designers want you to have the information, we want you to clearly have the information" | Confirmed | The same answer |
| "HRTF does not affect attenuations (volume change over distance) or occlusion (filtering change based on objects between the emitter and the listener)": both exist, and occlusion is a filter | Confirmed | Zinda, [Ask VALORANT, April 12](https://playvalorant.com/en-gb/news/dev/ask-valorant-apr-12) |
| Sounds "that display their audio distance on the mini-map via the white circle. This includes ability sounds, reloads, spike interactions and more", so "players [can] understand when their noise can be heard by enemies" | Confirmed | [Patch 1.0](https://playvalorant.com/news/game-updates/valorant-patch-notes-1-0/) |
| "Effect pooling added for impacts, gunshots and footsteps" | Confirmed | The same notes |
| Haven: "Updated several floor sections so that they now have appropriate material sounds": footsteps change with the floor | Confirmed | Patch 0.50 (via [thespike.gg](https://www.thespike.gg/valorant/news/patch-notes-0-50-cypher-glitch-fixed-weapon-balances-and-credit-changes/87)) |
| "Currently, only footsteps, reloads, and Deathmatch respawns will be rendered in 3D with HRTF enabled" | Confirmed | [Patch 2.06](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-2-06) |

From the community:

| Fact | Status | Source |
| --- | --- | --- |
| Heard by enemies: running, jumping on the same level or down to a lower one, reloading, dropping a weapon, knife swings. Not heard: walking, jumping up onto a higher surface such as a crate, picking things up, aiming down sights or scoping, switching weapons | Community | RoyGallant's beta breakdown on r/VALORANT, via [Dexerto](https://www.dexerto.com/valorant/what-valorant-sounds-enemy-team-hear-1355454/) and [MeinMMO](https://mein-mmo.de/en/valorant-what-can-the-opposing-team-hear-and-what-cant-they,495584) |
| The Ghost, Spectre and Phantom "have built-in suppressors and are hard to hear" | Community | MeinMMO, after RoyGallant |
| The minimap's white circle around you while you move is your sound radius: "Anyone outside of this white circle can't hear you" | Community | [ONE Esports' minimap guide](https://www.oneesports.gg/valorant/valorant-minimap-guide-radar) |
| You can't hear enemies during the buy phase | Community | [Tracker Network](https://tracker.gg/valorant/articles/which-sounds-can-your-enemies-hear) |
| A player found "little if any sound drop-off from footsteps next to a player and footsteps at the very edge of the audible range" | Community | [Dexerto](https://www.dexerto.com/valorant/valorant-players-call-for-fix-to-footstep-audio-giving-unfair-advantage-1406614/) |

Nobody has published the footstep radius, or any range, in metres.

## 3. What can be measured, and how

All from your own play or your own recordings: a custom game, with a friend where it needs two.

| Measurement | Method | Gives us |
| --- | --- | --- |
| The footstep radius | Run while watching your minimap's white circle, and measure its radius against the minimap's scale. The Skirmish minimap's scale is known from system 7 ([07-arena](07-arena.md)): the hall is 19 m wide on our estimate, 286 px on Riot's image. Or stand still while a friend runs straight at you from 50 m, and note where you first hear them | `Footsteps.radius` |
| The curve | Record a friend running past you at known distances (the arena's 2 m grid), and compare the recording's peak level for each step | `Curves.footstep` |
| Step rate | Count the steps in a recording of running for a known time, per weapon | `Footsteps.stride` |
| Which landings are heard | Jump up onto crates of each height, and drop off ledges of each height, with a friend listening | `Landing.minFall`, `Landing.maxRise` |
| Walking off a ledge | Hold Shift and walk off a high ledge, with a friend listening | Whether walking keeps a landing quiet (ours: it doesn't) |
| The reload radius | The minimap circle again, while reloading | `Curves.reload` |
| How far a gunshot carries, suppressed or not | A friend fires a Vandal and then a Phantom from further and further away | `Curves.gunshot`, `Curves.suppressed` |
| Walls | Record a friend running behind a thin wall and then a thick one, at the same distance | `Occlusion` |

## 4. Confirmed vs estimated, as implemented

The rules are confirmed or community, and the numbers that carry them out are ours:

| Parameter | Value | Status |
| --- | --- | --- |
| What enemies hear | Running steps, landings on your level or lower, gunshots, reloads. Never walking or crouching steps, jumps, draws or aiming | Community |
| Walking and crouching | Silent from the tick you press the key, whatever your speed | Community (silent); estimate (from the tick) |
| The footstep curve | Flat, and cut off at its radius | Confirmed (flat); community (the cut-off) |
| The footstep radius | 20 m: about 1.75 s of warning at rifle running speed (5.40 m/s) is 9.5 m, plus a 10 m fight | Estimate |
| The curve's shape | Full volume to 2 m, 0.8 at 10 m, 0.5 at 19 m, silent at 20 m | Estimate |
| Steps | One every 1.8 m: every 0.33 s running with a rifle, 0.27 s with the knife | Estimate |
| The first step | Within 0.6 m of setting off, sooner if a stride was nearly done when they stopped | Estimate |
| A draw | One sound for each, so the slot in hand drawn again within 0.5 s of a draw makes none | Estimate |
| Your own steps | 0.35 of an enemy's beside you, and not placed in the world | Estimate |
| A landing that's heard | Falling at least 0.3 m, coming down no more than 0.1 m above where you left the ground | Community (the rule); estimate (the numbers) |
| Walking or crouching as you land | Doesn't make it quiet | Estimate |
| Reloads | Heard to 15 m, cut short if you switch weapons | Confirmed (they have a radius); estimate (15 m) |
| Reload parts | The Vandal, Phantom and Classic: the magazine out at 12% of the reload, in at 55%, the bolt or slide at 82%. The Operator: its bolt opens at 8%, the magazine goes in at 50% and the bolt shuts at 82%. The Sheriff: the cylinder out at 10%, the rounds in at 50% and the cylinder back at 82% | Estimate (Riot publishes reload times, not when their parts sound) |
| Gunshots | Full volume to 5 m, 0.3 at 80 m, silent at 200 m, and duller with distance: a low-pass from 20 kHz at 10 m to 4 kHz at 150 m | Estimate |
| The Phantom | Silent at 70 m, and a third as loud as a Vandal at 20 m | Community (hard to hear); estimate (how much) |
| Through walls | A low-pass at 1.5 kHz and 0.7 of the volume through 0.2 m of wall, down to 500 Hz and 0.35 through 2 m, by the log of the thickness | Confirmed (it's a filter); estimate (the numbers) |
| The buy phase | Nothing from the other side | Community |
| Hit sounds | The shooter hears a body hit or a headshot when the server confirms the hit, and a kill sound that rises a little with each kill of a life | Estimate |
| Floors | One footstep sound everywhere | Estimate (the reference's change with the floor) |
| Each recording's level | Its peak, read from its waveform | Measured |
| The level they're evened to | Every recording turned to a peak of 0.5 before its sound's volume, turned up by at most 4 times (12 dB) | Estimate |

The report row (`luau tests/run.luau` prints it):

| Footsteps heard within | Step, running with a rifle | Step with the knife | Through 0.3 m of wall | A gunshot at 80 m |
| --- | --- | --- | --- | --- |
| 20 m (0.5 at 19 m) | every 0.33 s | every 0.27 s | 1236 Hz, x0.64 | low-passed at 5.8 kHz, 0.3 of full volume |

## 5. Design

```
 your predicted ticks ──► StepTracker ──► your steps, jumps, landings ──┐
 your ticks' weapons ──► draws, reloads, dry fire, gunshots ───────────┼──► Self bus ──┐
 the server's verdicts ──► body hit, headshot, kill ──────────────────── Ui bus ───────┤
 others' drawn poses ──► StepTracker ──► loud steps and landings ──┐                   ├─► Master ─► limiter ─► output
 their poses' reloading flag ──► reloads (following them) ─────────┼─► in the world:   │
 ShotFx (their shots) ──► gunshots where they fired ───────────────┘   filter ─► emitter
                                                                         ⋮ heard by
                                                       the listener on your camera ─► World bus
```

- **One set of rules for everyone.** `StepTracker` takes a player's poses over time and gives
  the sounds their feet make. The same code runs on your predicted ticks and on every other
  player's frames as they're drawn, so the rules are the same for all of them, and the offline
  tests run it on the real movement code: running, walking, crouching, jumping on the spot,
  jumping up onto a crate and dropping off it.
- **Steps by distance.** A step comes each 1.8 m covered on the ground, so faster weapons step
  faster, and someone slowing down steps more slowly. After standing still, the first step
  comes within 0.6 m: sooner if a stride was nearly done when they stopped.
- **Walking travels in the snapshots.** Whether someone is walking or crouching is in their
  input, which only their client and the server know. So each snapshot pose now carries it
  (`quiet`), with whether they're reloading and the weapon in their hands, in one more byte and
  two spare bits of the flags byte. Their steps play where they're drawn, in time with the blocks
  you see.
- **Landings by height.** A landing is heard when it fell at least 0.3 m from its highest point
  and came down no higher than 0.1 m above where it left the ground. Jumping up onto a crate
  falls only a little and lands higher, so it's silent. Dropping off a ledge is heard. Our
  movement keeps you on the ground down steps up to 0.35 m, so a drop smaller than that is never
  a landing at all. A new life starts 5 cm up, and settling onto the ground from there isn't a
  landing either, so spawning makes no sound.
- **Flat and cut off.** Every sound in the world has a distance curve, straight lines between a
  few points, which Roblox's `AudioEmitter` takes as is. The footstep curve barely falls and then
  stops at its radius, faded over the last metre so it doesn't click.
- **Walls are ours.** When a sound starts, a cast from your camera to it through the level
  (the same level code bullets use) measures how much wall is in the way. That sets a low-pass
  filter and the volume. Roblox's own acoustic simulation stays off.
- **Gunshots dull with distance.** Past 10 m, a gunshot's low-pass falls with the log of the
  distance, to 4 kHz at 150 m.
- **Your own sounds aren't out in the world.** Your steps, shots and reloads play straight to
  you, so they never move about as you turn. Your steps are quieter than anyone else's: they're
  there to feel right, and they must never cover an enemy's.
- **Reloads in parts.** A reload is a few sounds, each played when the reload is far enough
  through: a magazine out, a magazine in, then the bolt or slide, timed as fractions of the
  weapon's reload time so they keep up if a reload time changes. Others' reloads start from when
  their snapshot pose starts reloading, and play where they're drawn. Switching weapons cuts the
  reload off; a finished reload lets its last part ring out.
- **One draw, one sound.** A weapon given into another slot (the debug keys now, a buy menu
  later) switches to it on your client at once, and the give lands a moment later as a
  correction that draws it again. In BRINK that played the Sheriff's draw twice, 20 ms apart
  (measured). Now the slot in hand drawn again within 0.5 s of a draw is that same draw.
- **Hit sounds wait for the server.** Like the hit confirm (system 4), they play on the server's
  verdict, not the client's guess.
- **Every recording at the same level.** Library recordings come at all levels: the quietest we
  play peaks at 0.03 of full scale and the loudest at 0.77. Each recording's peak was read from its
  waveform (section 6), and it's turned up or down to the same peak before its sound's own volume,
  so the volumes in `SoundConfig.Sounds` compare sounds, not recordings. A limiter after the master
  keeps a pile-up of shots from clipping.
- **Voices made up front.** Each sound has a few voices, each its own `AudioPlayer` with the
  asset loaded, made when the game starts, so nothing waits on loading when it plays. The voices
  take turns, and when all are busy the oldest is cut. A spray's shots overlap, so rifles have
  ten.
- **Only our listener hears our sounds.** The emitters and the listener have their own
  `AudioInteractionGroup`. BRINK has `VoiceChatService.EnableDefaultVoice` on, which puts
  Roblox's own listener on the camera for voice chat, and without the group it would hear every
  sound a second time. That listener is wired straight into our `Output`, with no device output
  of its own (measured in BRINK), so voice skips our master and limiter, and `VFTestMute` doesn't
  silence it. That suits voice, which has its own volume in Roblox's menu.
- **The buy phase.** While the arena's phase is `buy`, nothing a player on the other side does
  plays. A dummy has no side, so this never applies to dummies.
- **Dummies are quiet.** Practice dummies are real simulated players, and the strafing ones run,
  so they would make steps all the time on the course. Their steps are off until the Sound Lab
  turns them on.

### Roblox differences that matter

- **Roblox's audio objects.** The reference mixes its own way. Ours is `AudioPlayer` to
  `AudioFilter` to `AudioEmitter`, heard by an `AudioListener` on the camera, then faders to an
  `AudioDeviceOutput`. Roblox now discourages the older `Sound` object.
- **Roblox's own character sounds are off.** Roblox adds a script, `RbxCharacterSounds`, that
  plays its own sounds for every character: running, jumping, falling, landing and dying. Most
  never fire on our characters, which the simulation moves, but in BRINK its falling sound played
  on every jump (measured), and its death sound plays whenever a Humanoid dies, as ours do on each
  death. The long-standing way to stop Roblox adding it, an empty script of the same name in
  StarterPlayerScripts (community), no longer works: in BRINK, Play replaced ours with the
  default (measured). So the client switches the script off as it appears and removes the sounds
  it already made on each character's root.
- **Stereo, not HRTF.** Roblox places sounds left and right as it does; there's no HRTF option
  like the reference's. Riot mixed in stereo too until Patch 2.06.
- **No sounds of our own.** The reference's sounds are its own recordings. Ours are Pro Sound
  Effects' recordings from Roblox's free library, so they sound different, however close in kind.
  Where the library has no recording of the right gun, a recording of a close one stands in, and
  section 6 says which.

## 6. Sounds

Every sound is one of Pro Sound Effects' recordings on Roblox's Creator Store: the 100,000+ sound
effects Roblox added with Pro Sound Effects in 2022 ([Mogura VR](https://www.moguravr.com/?p=163858)),
part of the Store's "free-to-use audio assets made by Roblox and the Roblox community"
([Roblox docs](https://create.roblox.com/docs/en-us/audio/assets)). Each listing ends "Courtesy of
Pro Sound Effects."

How they were found, all from inside Studio in BRINK, without playing anything:

1. `AssetService:SearchAudioAsync` for each kind of sound, with a few phrasings each. Nothing in the
   results is uploaded by Roblox itself (creator id 1): the library's uploader is
   "ProSoundEffects" (7462895450), with the artist name "Pro Sound Effects".
2. Searching by keyword alone ranks other uploads first, and Pro Sound Effects' best matches often
   aren't in the first 30. With `AudioSearchParams.Artist` set to "Pro Sound Effects" (an exact
   match), every result is theirs: "assault rifle", "footsteps" and "ding" gave 30 of 30, against
   24, 13 and 3 of 30 without it. Set `AudioSubType` to `SoundEffect` too: it defaults to `Music`,
   and then "knife" finds only songs and the artist filter finds almost nothing.
3. Each listing's description is Pro Sound Effects' own note on the recording (the gun, the
   surface, close or distant, "Very Good"), read with `MarketplaceService:GetProductInfo`. That
   caught two mistakes a title wouldn't: the "Pistol Single Shots" are two guns, a silenced 9 mm and
   a .45 magnum, and ".470 Rifle" is shells being ejected, not a shot.
4. `AudioPlayer:GetWaveformAsync` read each recording in 10 ms windows, keeping each window's
   loudest sample. The **peak** is the loudest window. A recording **starts** at the first window
   that reaches a quarter of its peak, and when that's 30 ms or more in, we skip to 10 ms before
   it. The reload's last part instead skips to just before its main click, so the click comes on
   its time, before the reload ends. The players had to be parented to load, so this ran in a
   server-only Run-mode session with them in a temporary folder, unwired.

| Sound | Plays for | Recording (asset id) | Pro Sound Effects' description | Peak | Skips |
| --- | --- | --- | --- | --- | --- |
| `step` | running steps, yours and others' | Foot Stomp 3, 4, 6, 7 (9114523345, 9114523358, 9114523612, 9114523629) | "Foot Stomp, Hard Carpeted Floor" | 0.26, 0.30, 0.55, 0.21 | - |
| `land` | a landing that's heard, at 0.82 speed | Foot Stomp 6, 4 | as above | 0.55, 0.30 | - |
| `softLand` | your landing up onto something higher, at 0.9 speed | Foot Stomp 3, 7 | as above | 0.26, 0.21 | - |
| `jump` | your jump | Knife Wipe Fast Swipes On Trousers 4 (9116199047) | "Fast Swipes on Trousers, Short Zipping Movements" | 0.03 | - |
| `rifle` | Vandal | Galil Assault Rifle 1 (9114550557) | ".223, Single Shots, Exterior, CU, ... Very Powerful, Echo" | 0.77 | - |
| `suppressed` | Phantom | Silenced Pistol 1, 3, 5, 7 (9119135215, 9119135228, 9119134567, 9119134978) | "H&K SOCOM Mk 23, Semi Auto .45, Suppressed, Single Shots" | 0.73 to 0.75 | - |
| `sniper` | Operator | Rifle Single Shots 7, 8 (9118174271, 9118174539) | "Barrett M82 .50 Cal, Single Shots, Metal Clinks" | 0.54, 0.53 | - |
| `revolver` | Sheriff | Smith Wesson 357 Magnum 2, 4, 8 (9119296692, 9119296944, 9119297250) | "Smith & Wesson .357 Magnum, Single Gunshots, Big Crack, Handling Clicks" | 0.47, 0.51, 0.53 | - |
| `pistol` | Classic, at 1.08 speed | Pistol Single Shots 2 (9117400585) | "L.A.R. Grizzly Win Mag .45, Single Shots" | 0.54 | - |
| `dry` | the trigger on an empty magazine | Moviola Toggle Switch Single Clicks Sharp 14 (9117029050), Toggle Switch Metal Industrial Equipment 10 (9120102194) | "Single Clicks, Sharp"; "Sharp Single Clicks" | 0.38, 0.31 | -, 0.02 s |
| `magOut` | reloads: the magazine out | Ammo Magazine 1 (9113104176) | "Spring Release, Fast Insert, Eject, ... Pistol Gun, Click, Metal, Clip" | 0.68 | 0.04 s |
| `magIn` | reloads: the magazine in, or the Sheriff's rounds | Ammo Magazine 2 (9113104517) | "Remove, Insert, Eject, Handle, Slide, Pistol Gun, Click" | 0.72 | 0.22 s |
| `rack` | reloads: the bolt or slide at the end | Ppsh Burp Gun 7 (9117889191) | "PPSH Burp Gun, Cocking and Loading, Dull Metal Movements, Clicks" | 0.23 | 1.70 s, to just before its cocking click at 1.81 s |
| `boltOpen` | the Operator's reload: the bolt opens | 470 Rifle 1, 3 (9113027869, 9113027964) | ".470 Rifle, Ejecting Empty Shell, Quiet" | 0.14, 0.33 | 0.27 s, 0.63 s |
| `latch` | the Sheriff's reload: the cylinder out and back, at 1.15 speed | Metal Latches 1 (9116722545) | "Metal Latches, Snapping Impacts" (door hardware) | 0.47 | - |
| `drawRifle` | drawing the Vandal, Phantom or Operator | Machine Gun Movement 2 (9116362481) | "Machine Gun Movement, Handling" | 0.60 | 0.08 s |
| `drawPistol` | drawing the Sheriff or Classic | Gun From Holster 1 (9114701864) | "Gun From Holster, Pistol Grab" | 0.72 | 0.05 s |
| `knife` | drawing the knife | Knife Fast Scraping Draws Pull Out 1, 17 (9116190984, 9116190959) | "Fast Scraping Draws, Pull Out, Some Metallic Ring" | 0.10, 0.19 | -, 0.20 s |
| `hitBody` | your hit on a body | Body Hits Thuds 1 to 4 (9113518281, 9113518286, 9113518280, 9113518397) | "Body Hits, Impacts with Rubber Glove, Thuds" | 0.48, 0.68, 0.51, 0.63 | - |
| `headshot` | your headshot | Anvil Hits Ringing Metal Clinks Some Muted 3 (9125362418) | "CU Ringing Metal Clink, Blacksmith, Sharp Dinging Impact" | 0.42 | - |
| `kill` | your kill, higher with each kill of a life | Synth Sparkle Tone High Pitch Bell Tone Ding (9126073318) | "High Pitch Bell Tone, Ding, Ring, UI" | 0.13 | 0.09 s |

The knife's swings and strikes are in [10-knife](10-knife.md) section 5.

Stand-ins, where the library had nothing closer: the steps are foot stomps on a hard carpeted
floor, not single running footsteps on concrete; the Phantom is a suppressed pistol; the Classic is
a .45 magnum pistol raised a little, since every 9 mm pistol shot in the library is silenced; the
rifle reload is pistol magazine sounds and a PPSh's cocking; the Sheriff's cylinder is a door
latch; and the hit sounds are a gloved punch, an anvil and a UI chime. Most uploads are cut down
from the recording their description times (Galil Assault Rifle 1 is 4.17 s of a 4.2 s file, but
M16 Machine Gun 4 is 1.74 s of 3.5 s), so we went by what each upload holds, from its waveform.

Searched for and not found among the first 30 of any phrasing: a single footstep on a hard floor,
an assault rifle's magazine or charging handle, a sniper's bolt, and a revolver's cylinder. Bullets
hitting walls stay silent for now; Bullet Impact 3, 5 and 10 (9113632114, 9113632257, 9113632506)
are candidates for them.

## 7. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Audio/SoundConfig.luau` | The rules' numbers and curves, with status and source, and every sound's assets, volume and voices |
| `src/shared/Audio/StepTracker.luau` | Steps, jumps and landings from a player's poses, and whether they're walking or crouching |
| `src/shared/Audio/SoundMath.luau` | Volume on a curve, curves in studs, the filters for walls and the air, how much level lies between two points, each recording's gain, which reload parts are due, whether a draw makes its sound |
| `src/client/Audio/SoundEngine.luau` | The buses, the listener, every sound's voices, playing and stopping them, the meters |
| `src/client/Audio/GameSounds.luau` | What makes a sound, who hears it, and where |
| `src/client/Debug/SoundLab.luau` | The Sound Lab (F2, fourth page) |
| `src/client/Audio/DefaultSounds.luau` | Switches Roblox's default character sounds off |
| `src/shared/Net/PlayerCodec.luau`, `src/shared/Net/PoseHistory.luau` | `quiet`, `reloading` and `weapon` in each snapshot pose |
| `src/server/PlayerSimServer.luau`, `src/server/Dummies.luau` | Fill them in from each tick's input and weapons |
| `tests/sound.luau` | The rules on the real movement code, the curves and filters, the levels and reload parts, and the report above |
| `tests/net.luau` | The new pose fields survive a snapshot |

## 8. Debug tools

| Where | Tool |
| --- | --- |
| F2, fourth page | The Sound Lab: the footstep radius, whether your steps can be heard right now, each bus's level, the voices playing and loading, and the last 14 sounds with whose, how far, how much wall and the filter it made, how loud it is where you stand, or why it wasn't heard |
| In the Sound Lab | `[` and `]` the footstep radius -/+2 m on this client, Y the dummies' steps, H rings, Backspace clears |
| The floor, with the Sound Lab open | Each step or landing draws its range around where it was made: white for yours, blue for others' that you heard, grey for ones you didn't |
| The local player's attributes | `VFTestMute` mutes the output for scripted playtests; the meters still read |
| Explorer, while playing | `SoundService.VFSound` (buses, meters, your own voices), the `VFSound_*` Attachments on the Terrain (voices in the world), `VFListener` on the camera |

## 9. Refinement loop

1. Take the measurements in section 3, starting with the minimap circle.
2. Set `Footsteps.radius` and the curves, the step length, and the landing rule in `SoundConfig`.
3. Listen to each sound in Studio, and swap any that don't fit for another from the library: a
   new asset id, title and peak in `SoundConfig.Sounds` (section 6 has the waveform readings and
   how they were taken). Then set each sound's volume against the others.
4. Re-run `luau tests/run.luau`. It checks the rules still hold on the movement code (running is
   heard, walking and crouching aren't, a crate landing is silent, a drop isn't) and that every
   number is labelled. Update section 4.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). The sounds
were picked by title, description and waveform, not by ear. Only a Studio session can confirm:

- Every sound loads and plays, from the right place, at a sensible volume next to the others, and
  sounds like what it stands for.
- Others' steps sound where they're drawn and stop at 20 m, walking and crouching are silent, and
  a crate landing is too.
- Walls muffle, and the filter doesn't click when a sound starts.
- Nothing is heard twice with voice chat on.
- Your own steps don't cover anyone else's.
- The buy phase is silent from the other side.

The [Studio test session](../studio-checklist.md) walks through these, with what to expect.

### Checked in BRINK

A solo playtest, muted with `VFTestMute`, on main at 1e6308f (measured):

- All 131 voices loaded, and the audio graph was as built: 55 voices in the world and 76 of
  your own and for hits, the limiter after the master, the listener on the camera.
- Running stepped every 0.33 s and drew a 20 m ring each step. Walking, crouching and standing
  were silent. A jump on the spot gave a jump and a landing; jumping onto the 0.50 m box gave
  the soft landing, and stepping off it the heard one. Spawning was silent.
- Every gun's shot and every draw played. The reload parts came within 0.01 s of their times,
  and a switch cut a reload off after its first part.
- The strafing dummy's steps were heard at 16 m at 0.60 of full volume, which is the curve's
  value there, and the one at 30 m wasn't.
- Not played: hit sounds, the kill sound's rise and dry fire, which need mouse input the check
  left out. Nothing was listened to, so how it all sounds is still to check by ear.

A second check, on main at 6f2e51e: giving yourself the Sheriff (7) while holding the Vandal
played one draw, where the first check heard two. The same-named `RbxCharacterSounds` script
did nothing: Play put Roblox's default in its place, with the same nine sounds on the root.
