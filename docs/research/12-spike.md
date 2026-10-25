# System 12: The spike

The spike is what the reference's rounds are played for. One attacker carries it; planted at a
site, it goes off 45 seconds later unless a defender defuses it, and its blast kills everyone near
it. This system builds the spike itself: carrying it, dropping it and picking it up, the plant and
the defuse in the predicted simulation, the countdown with its beeps and visual tells, and the
blast. On the course there are two sites behind the spawn where anyone can plant it and anyone can
defuse it, and a new spike waits at the start after each one ends. The rules of a round played for
it (who carries it, who may defuse it and winning by it) are system 13's
([13-rounds.md](13-rounds.md)), and the credits for a plant system 14's.

As before, everything comes from Riot's patch notes and from community wikis, guides and
measurements. No game files, memory, network traffic or protected assets were used, and nothing
reads the game while it runs. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

The VALORANT Wiki at wiki.playvalorant.com is written by players. Riot backs it and pays its
running costs, but running it, from moderation to content, is left to the fans
([TalkEsport](https://www.talkesport.com/news/valorant/riot-games-partners-valorant-wiki-leaves-fandom/)),
so what only the wiki says is Community here, as in [10-knife.md](10-knife.md). Its patch history
quotes Riot's notes, and where we've read those notes ourselves they're cited as Riot's.

## 1. Observable behaviour

- One attacker carries the spike. 4 draws it ("Equip Spike"), and G drops it. Dropped, it lies on
  the ground until an attacker runs over it, or presses F by it ("Use Object"). A spike dropped
  up high falls to the ground.
- Inside a site's plant area, holding 4 with the spike in hand plants it in 4 seconds. The planter
  is rooted but can turn, so the spike can be placed precisely, and can let go at any moment: a
  plant let go of starts over next time. It goes down in front of the planter, and always inside
  the site's outline.
- Planted, it counts down 45 seconds and beeps: once a second, then faster with 20, 10 and 5
  seconds left, eight times a second at the end. A white circle on the ground round it marks how
  close a defender must be.
- A defender inside that circle who can see the spike holds 4 to defuse it: 7 seconds, rooted,
  with the weapon put away. A defuse let go of past 3.5 seconds keeps that half, and the next one
  takes the other 3.5. Pulled out of range, or losing sight of the spike, the defuse stops.
- The spike's lights are light blue, and red while it's being defused, when its casing rises to
  the top. A defuse let go of past the half leaves the casing halfway, and the next defuse's sound
  is higher. With 7 seconds left, too few for a whole defuse, a white sphere closes in round it and
  stays.
- At 0 a black sphere grows fast from it and kills every player it touches, out to about 35 m.
- The plant and the defuse can be heard a long way off, about 60 m.

## 2. Publicly documented details

### From Riot

| Fact | Status | Source |
| --- | --- | --- |
| "Line of sight is no longer required to pick up the spike when overlapped by a player"; "Fixed issue where the spike would sometimes become unretrievable" | Confirmed | [Patch 0.49](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-49/) |
| "Fixed issue where canceling a plant or orb pickup could sometimes play the wrong (slower) re-equip animation": the weapon is drawn again after a plant is let go of | Confirmed | The same notes |
| "Fixed a rare bug where either team could win a round by elimination on the same frame that the spike was defused" | Confirmed | The same notes |
| "The defuse range circle indicator that shows after planting the Spike again displays properly." | Confirmed | [Patch 2.05](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-2-05/) |
| Astra's Gravity Well "Now pulls Agents that are defusing the Spike"; "If they are pulled out of defuse range, the defuse will be interrupted" | Confirmed | [Patch 2.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-2-07/) |
| "Fixed an issue where under certain conditions, you can continue to defuse the Spike out of line of sight." | Confirmed | [Patch 6.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-6-10/) |
| "Fixed a bug where players could plant the spike outside or float partially above the site's designated area." "The spike will now stay within the outlined site area no matter where you are facing in game." | Confirmed | [Patch 11.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-10/) |
| The Spike "Will now automatically fall from elevated boost positions" and "Can no longer be planted partially in map geometry" | Confirmed (quoted by the wiki) | Patch 0.50, in the [VALORANT Wiki](https://wiki.playvalorant.com/en-us/Spike)'s history |
| "Fixed a bug where the Spike could automatically plant when you walked onto a plant site" | Confirmed (quoted by the wiki) | Patch 1.02, the same |
| "Fixed a bug where agents were able to drop both primary and secondary weapons while planting or defusing" | Confirmed (quoted by the wiki) | Patch 6.06, the same |
| "Fixed a bug where some weapon equip animations would play at the wrong speed after canceling or completing a plant" | Confirmed (quoted by the wiki) | Patch 5.0, the same |

Riot's notes describe fixes, not the numbers: none of them gives the plant time, the defuse time,
the countdown or the blast's size.

### From the community

| Fact | Status | Source |
| --- | --- | --- |
| "Planting takes 4 seconds, with an audio cue being given to all players in range"; "The carrier is rooted during planting, but can cancel at any time."; "Attackers can rotate their body during planting to position and plant the spike in very specific locations on the site." | Community | [VALORANT Wiki, Spike](https://wiki.playvalorant.com/en-us/Spike) |
| "Defusing takes 7 seconds"; "Once a Defender has spent 3.5 seconds defusing a spike, this progress will be saved"; then "the defuse time is only reset to 3.5 seconds, the outer casing will only fall to halfway" and "the audio cue given when defusing changes to a higher pitch"; "The Defender is rooted during defusing, but can cancel at any time"; "Reattempting a defuse requires another 7 seconds" (short of the half) | Community | The same |
| "The Spike has a 45 second detonation timer"; it "will start double beeping with 20 seconds left, triple beeping with 10 seconds left" | Community | The same |
| "The spike's lights, usually light blue during countdown, turn red" while defused, and "the spike's outer casing begins to rise up from the floor to the top of the spike"; "with 7 seconds to go, a white sphere less transparent than others" will "close in on the spike and surround it until detonation" | Community | The same |
| "a destructive black sphere that rapidly expands from the spike's location", "instantly killing any players it comes into contact with"; "The maximum radius of the explosion is about the same as the player's audio range." | Community | The same |
| It "can be run over to be collected (it can also be collected by pressing F or any keybind set by the player)"; "it can be collected only by other Attackers"; dropped on a structure, "it will proceed to automatically bounce off of the structure until it falls onto the ground" | Community | The same |
| "Planting the Spike will take you a full four seconds"; "It takes 7 seconds to defuse the Spike entirely, but there is a checkpoint halfway", reached after "3.5 seconds"; "defend it for 45 seconds, at which point the Spike will explode"; "To pick up the Spike, you simply just run over it" | Community | [Red Bull](https://redbull.com/ca-en/spike-guide-valorant) |
| "It takes 4 seconds to plant the spike and it will explode after 45 seconds."; "To fully defuse the spike, it takes 7 seconds."; "The first 25 seconds = 1 beep per second", "Between 25-35 seconds = 2 beeps per second", "Between 35-40 seconds = 4 beeps per second", "From 40 to explosion = 8 beeps per second" | Community | [Mobalytics](https://mobalytics.gg/blog/valorant/valorant-spike-guide/) |
| The same four beep rates; "the bomb's countdown does not pause while you are defusing"; the defuse saves "At the halfway point of defusing (three-and-a-half seconds)" | Community | [TRN Checkpoint](https://tracker.gg/valorant/articles/how-to-defuse) |
| Four seconds to plant, seven to defuse, "goes off exactly after 45 seconds"; plant "by pressing and holding '4'", "press 'G' to throw it on the ground", "the defusing key (which again is '4')" | Community | [Sportskeeda](https://sportskeeda.com/esports/valorant-a-short-guide-planting-dropping-defusing-spike) |
| Default keys: Equip Spike "4", Use Spike (Plant or Defuse) "4", Use Object "F", Drop Equipped Weapon "G" | Community | [Shacknews](https://www.shacknews.com/article/117434/valorant-pc-controls-and-keybindings) |
| Drop: 4 to bring it to your hand, then "the G key"; on a plant site 4 would start a plant, so "jump and, while in the air, press 4", then G; pick it up: "you just have to walk over it" | Community | [Dot Esports](https://dotesports.com/valorant/news/how-to-drop-the-spike-in-valorant) |
| Blast radius "35 m", plant and defuse sounds heard at "60 m", the drop's sound at "50 m?" (very quiet there), all measured with in-game pings; the beeping and flashing speed up with 20, 10 and 5 seconds left (February 2023) | Community | [note.com, yuyujan11_valo](https://note.com/yuyujan11_valo/n/n5021ca2dddd0) |
| The blast's reach, mapped on each map by planting at the corners of each plant area, about ten plants a site | Community | [Dignitas](https://www.dignitas.gg/articles/escape-with-style-valorant-spike-detonation-range) |

The two ways of describing the beeps agree: speeding up with 20, 10 and 5 seconds left is 25, 35
and 40 seconds after the plant. Nobody publishes how big a plant area is (each map's are its own),
the defuse circle's radius, how far above or below the spike a defender can be, how close is
running over it, how far a dropped spike goes, how fast the black sphere grows, how the sounds
fall off with distance, or the spike's draw time and the run speed with it in hand.

## 3. What can be measured, and how

From your own copy of the game, in a custom game, played normally, with a video (Windows' Game Bar
or your graphics driver's recorder) and the in-game ping, which reads distances in metres. Never
use any tool that reads the game's memory, files or network traffic.

| Measurement | Method | Gives us |
| --- | --- | --- |
| The defuse circle | Plant, step back until the defuse prompt goes, and ping the spike from there | `defuseRange` |
| Its height | Plant at the foot of a box and try to defuse from on top of it, at a few heights | `defuseHeight` |
| Running over it | Drop it and walk at it slowly; in the video, the frame it's picked up, against the model's size | `pickupRange`, `pickupHeight` |
| The drop | Drop it standing on flat ground and ping where it lands | `dropForward` |
| The plant point | Plant, step back and ping where you stood and where the spike is | `plantAhead` (0.35 m) |
| The blast's growth | Video the detonation from 10 m and from 34 m: frames from the flash to the sphere reaching you | `blastGrowTime` |
| The blast's edge | A teammate at pinged distances (33, 35, 37 m): who dies | `blastRadius` (35, community) |
| How the sounds fall off | As note.com did: listen at pinged distances, and compare with a gunshot | the `device` and `beep` curves |
| The plant's and the defuse's sounds | Record a plant and a defuse from beside them and from 30 m: how long each runs, and how they change past the half | which recordings, and the `device` curve |
| The casing and the white sphere | Step through a video of a defuse and of the last 7 seconds | `CASING_RISE`, `CLOSE_TIME` |
| The draw | Frames from pressing 4 to the spike in hand | the spike's `equipTime` (0.5) |
| The run speed | Time a run along a pinged distance with the spike in hand | its `moveMultiplier` |
| Fire plants | Hold the left button with the spike in hand in a site | whether fire plants, as here |

## 4. Confirmed vs estimated, as implemented

The numbers and the rules are in `src/shared/Spike/Spike.luau`; the plant, the defuse and the drop
in `src/shared/Spike/SpikeSim.luau`.

| Parameter | Value | Status |
| --- | --- | --- |
| Plant | 4 s, holding 4 or fire with the spike in hand, on the ground in a site's plant area | Community (4 s, holding 4); estimate (fire planting too) |
| Defuse | 7 s, holding 4 within range, seeing the spike, with the weapon put away | Community (7 s, 4) |
| The saved half | Let go of at 3.5 s or later (or killed then), the next defuse starts from 3.5 s and takes 3.5 s | Community (3.5 s); estimate (that a death keeps it too) |
| Countdown | 45 s from the plant, on the server's clock | Community |
| Rooted | Neither can move or jump; both can turn and crouch | Community (rooted, can turn); estimate (crouching) |
| Let go | A plant stops, the spike still in hand, and starts over next time; a defuse stops, keeping its half if past it, and the weapon is drawn again | Community (cancel at any time) |
| Done | After a plant the weapon the spike replaced is drawn, with its own draw time, as after a defuse; nothing more starts until 4 is let go | Confirmed (an equip follows a plant, Patch 5.0); estimate (its draw time; waiting for 4 is ours, so on the course a planter doesn't go straight on to defuse their own spike) |
| Where it goes down | 0.35 m in front of the planter if that's still in the site, otherwise at their feet | Confirmed (always inside the site, Patch 11.10); estimate (0.35 m) |
| Defuse range | Feet within 1.6 m of it across and 1.2 m above or below | Confirmed (a range, Patch 2.07); estimate (the sizes) |
| Sight | From the eye to 0.15 m above where it rests, through characters and anything that doesn't collide, checked every tick of a defuse | Confirmed (needed throughout, Patch 6.10); estimate (the point looked at) |
| The beeps | Once a second for 25 s, twice a second to 35 s, four times to 40 s, eight times to the end: 105 beeps, the first at the plant, each faster stretch starting with one | Community (the rates); estimate (where the beeps fall) |
| The blast | A sphere from the spike growing to 35 m in 0.5 s, killing everyone whose body it reaches (the nearest point between their feet and 1.8 m up), through walls | Community (35 m, kills whoever it touches); estimate (the growth, the body's height, and that walls don't stop it) |
| Picking it up | Running over it: feet within 0.7 m of it across and 1 m above or below; no sight needed; whoever dropped it must step off it first | Confirmed (no sight, Patch 0.49); community (run over it); estimate (the sizes, stepping off) |
| Dropping it | G with it in hand, never while planting or defusing; thrown 1.2 m ahead, stopped 0.2 m short of a wall, coming to rest on the ground under there, through characters | Community (G); confirmed (no drops while planting or defusing, Patch 6.06; falling from up high, Patch 0.50); estimate (the throw) |
| A carrier killed | It drops where they die | Estimate |
| A spike lost | Fallen out of the world (no ground within 50 m below), or its carrier gone some other way: back at the start | Estimate |
| Its tells | Lights light blue, red while defused; the casing up 0.12 m while defused, half that once the half is saved; with 7 s left a white sphere closing from 8 m across to 2.4 m in 1 s | Community (what they do); estimate (the sizes and times) |
| Its sounds | A plant's run of beeps, a defuse's steady beeping, 1.25 times higher for a defuse from the half, heard by others to 60 m; its drop heard to 50 m | Community (a cue for each, the higher defuse, 60 m and 50 m); estimate (the recordings, the curves' shapes, the pitch) |
| The draw and the run speed | 0.5 s; the knife's run speed, 6.75 m/s | Estimate |
| On the course | Two sites 6 m square, 10 m apart, 26 m behind the spawn; anyone can plant and defuse; a new spike at the start 5 s after one ends | Estimate (ours, for testing) |

The sounds are in section 5.

## 5. Design

### One spike, kept by the server

`SpikeServer` keeps the one spike and its state: none (no sites here), carried, dropped, planted,
defused or detonated. It puts that state in Workspace attributes (`VFSpike`, `VFSpikeCarrier`,
`VFSpikePosition`, `VFSpikePlantedAt`, `VFSpikeHalf`, `VFSpikeSite`, `VFSpikeEndedAt` and
`VFSpikeLayout`), which every client reads, and from it works out what each player may do with
the spike this tick: the sites, whether they may plant (its carrier) and defuse (anyone, once it's
planted), where it's planted and whether a half is saved. On the course that's anyone; with sides,
the same context is where attackers-only rules go.

### The plant and the defuse are predicted

The plant and the defuse root the player, put the weapon away and bring it back, so they change
the player's future exactly as movement and weapons do. They run inside `PlayerSim`, through
`SpikeSim`, from the same input, on the client to predict them and on the server to decide them.
The client never says it planted: the server's own run of the player's input does, and hands
what happened (`planted`, `defused`, a defuse `stopped` with how far it got, `dropped`) to
`SpikeServer`, which checks it against its state (only the carrier plants, only a planted spike
that hasn't gone off is defused). The ack carries the plant or defuse under way, so a correction
replays it, and the pose carries which one is under way, for the sounds others hear.

The client's copy of the context comes from the attributes (`ClientSpike`), one round trip behind
the server's. Where that would make the two simulations disagree, the rules keep them together:
a defuse let go of past the half is saved on the client at once, as the server saves it on the
same tick; and after a plant or a defuse, nothing more starts until 4 is let go, so a planter
doesn't start defusing on one side before the other has heard it's planted.

### The countdown and the blast

The plant is stamped with the server's time, and it goes off 45 seconds after that. Each client
counts its beeps from the same stamp on its server clock (`GetServerTimeNow`), so everyone hears
them together; a beep heard of late by more than a quarter of a second is skipped, not played
late. At 0 the server grows the blast for half a second, killing each player and dummy it reaches
outright, shield and all, through walls, with nobody credited: the kill feed has the spike for
the killer (`SPIKE   name` since system 16). A defuse that finishes after the blast has gone off counts for nothing.

### Picking it up and dropping it

A spike on the ground is picked up by the first living player to run over it, without needing to
see it, as the reference's has been since Patch 0.49. Whoever dropped it has to step off it first,
so it isn't picked straight back up. G throws it a little ahead, stopped short of a wall, and it
comes to rest on the ground below that point, looking through characters, so a spike let go of on
a box lands on the box and one let go of over someone's head lands at their feet. Its carrier
killed, it lies where they died. With no ground under it, it goes back to the start.

### What you see

`SpikeView` draws the spike from plain parts: a squat dark case with a band of light, and a marker
over it through walls. Planted, it adds the circle a defender must stand in, flashes its band and
beeps faster as the end nears, turns red and raises its casing while defused, and with 7 seconds
left shows the white sphere. At the end it grows the blast's black sphere, and darkens the view
of anyone it passes. `SpikeHud` shows what you can do where you
stand (`HOLD 4 TO PLANT`, `HOLD 4 TO DEFUSE`), a bar while you do it with the defuse's half
marked, `SPIKE  [4]` while you carry it, a light at the top flashing with the beeps, and a banner
as it's planted, defused or goes off. In hand it's held low and tipped toward the ground while
planting, and the weapon is gone while defusing.

### Sounds

Picked from Pro Sound Effects' recordings in the Creator Store's free library, as in
[08-sound](08-sound.md) section 6: 75 searches with the artist filter, 65 recordings shortlisted
by their descriptions, and each measured as it plays, straight to you and in the world, in muted
playtests and a server-only Run session with nothing heard. Picked by title, description and the
measurements, not yet by ear.

| Sound | Plays for | Recording (asset id) | Pro Sound Effects' description | Peak | Skips |
| --- | --- | --- | --- | --- | --- |
| `spikeBeep` | each beep, from the spike, heard to 50 m | Single Tone Single High Pitch Beep Tones 1 (9119142417) | "Single Tone, Single High Pitch Beep Tone, Switch, UI" | 0.27 | - |
| `spikePlant` | a plant, from the planter, heard by others to 60 m | Alarm Beeps 8 (9113084401) | "Alarm Beeps, Arming and Setting Off, Home Alarm System, Console Beeps" | 0.12 | 0.65 s |
| `spikeDefuse` | a defuse, from the defuser, to 60 m, over and over | Synth Beeps Constant Fast Tracker Scanner 1 (9119761110) | "Synth Beeps, Constant, Fast, Tracker, Scanner" | 0.37 | 0.21 s |
| `spikeDefused` | defused, from the spike | Laser Blasts Transporter Elements 4 (9116227010) | "Laser Blast, Transporter Elements, Metallic Tone Descending in Pitch" | 0.68 (stereo; 0.59 in the world) | 0.09 s |
| `spikeBlast` | the blast, from the spike, to 200 m | Synth Thunder Cracks Individual Explosion Booms 4 (9126083958) | "Individual Explosion Booms, Long Rolling Tails, Sharp Impact, Some Rumble" | 0.41 (stereo; 0.41 in the world) | 0.08 s |
| `spikeDrop` | dropped, where it lands, to 50 m | Metal Object Drop To Concrete Solid Metal Thud 2 (9125679182) | "to Concrete, Solid Metal Thud, Rattle" | 0.71 (stereo; 0.68 in the world) | 0.30 s |
| `spikePickup` | your pickup | Metal Latches 1 (9116722545), the Sheriff's latch | "Metal Latches, Snapping Impacts" | 0.33 | - |

The plant's beeps run 3.4 s from its first, inside the 4 s plant, and stop if it's let go of.
The defuse's run of even beeps, one every 80 ms, lasts 4.2 s, so it plays again from its start
each time it comes to an end, until the defuse ends; a defuse from the half plays it 1.25 times
higher. The beep's tone is 0.15 s, so at eight a second the last beeps run together. The plant's
recording peaks at 0.12, turned up to `MaxGain` (4 times), a little under the level.

### Keys

4 is both "Equip Spike" and "Use Spike", as in the reference: pressed with the spike carried, it
draws it, and held, it plants (once drawn) or defuses. G drops it. The debug gives that were on 4
to 8 are now on 5 to 9.

### Roblox differences that matter

- G was already the debug HUD's ghost box. With the spike in hand, G drops it instead.
- The server steps players at 128 Hz inside Roblox's 60 Hz frames, so a plant or a defuse
  completes on a tick, and the server acts on it in the same frame.
- The spike's state reaches clients through attributes, which arrive a little after the acks
  that carry each player's own simulation; the rules above keep that from showing.
- Everything the spike draws on a client is built there, never collides and is invisible to
  raycasts, so it can't block a shot or a defuser's sight.

## 6. Implementation map

| Piece | Where |
| --- | --- |
| The numbers, the sites, where it can be planted and defused, the beeps, the blast's reach | `src/shared/Spike/Spike.luau` |
| The plant, the defuse and the drop, predicted | `src/shared/Spike/SpikeSim.luau`, stepped by `src/shared/PlayerSim.luau` |
| Sight of it, the ground under it and walls in the way, in the Roblox world | `src/shared/Spike/RobloxSpike.luau` |
| The one spike: its states, pickup, the countdown and the blast | `src/server/SpikeServer.luau` |
| Each player's context and what happened, handing the spike over | `src/server/PlayerSimServer.luau` |
| A death nobody caused | `src/server/CombatServer.luau` (`kill`) |
| The client's copy of the spike | `src/client/ClientSpike.luau` |
| Predicting and reconciling it | `src/client/PlayerController.luau` |
| 4 held and G | `src/client/InputSampler.luau` |
| The spike in the world | `src/client/SpikeView.luau` |
| The HUD | `src/client/SpikeHud.luau` |
| The arming beeps, the defuse's beeping, the drop and the pickup; the sounds and their curves | `src/client/Audio/GameSounds.luau`, `src/shared/Audio/SoundConfig.luau` |
| In hand | `src/client/Combat/WeaponEffects.luau`, `src/client/Combat/WeaponLooks.luau`, `src/shared/Weapons/WeaponConfig.luau` |
| The ack and the pose | `src/shared/Net/PlayerCodec.luau` |
| The course's sites | `src/server/TestRange.luau` |
| Tests | `tests/spike.luau` |

## 7. Debug tools

- **HUD (F3):** a `spike` line: `none here`, `carried by you` (or by whom), `on the ground at x z
  m`, or `planted at A  31.4 s left`, with `half saved` once it is, and how far your own plant or
  defuse has got (`planting 50%`).
- **The attributes:** Workspace's `VFSpike` attributes are the server's whole state of it, and can
  be read in the Explorer's Properties.
- **Scripted checks:** `VFTestGive` set to `spike` hands you the course's spike, `VFTestSlot` 4
  draws it, and `VFTestButtons` 1024 holds 4 and 2048 presses G, with no keys pressed.
- **The course:** the sites are amber tiles with their letters 26 m behind the spawn, with a
  low wall (0.8 m) across site A for a defuse that loses sight of the spike, the spike waits on a
  tile marked `SPIKE` 4 m behind the spawn, and dummy 18 stands between the sites for the blast.

## 8. Refinement loop

1. Measure the defuse circle, its height, running over it, the drop and where it goes down, as
   in section 3, and set the estimates.
2. Time the blast's growth from a video and check its edge against 35 m with a teammate.
3. Check each sound against the reference by ear: the beeps, the arming beeps, the defuse's
   beeping, the blast, and a draw of its own (it borrows the rifle's for now).
4. Check whether fire plants in the reference, and the draw time and run speed with the spike.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- The spike can be found, picked up by running over it, drawn with 4 and dropped with G, and a
  dropped spike lands on the ground, short of walls and on top of a box it's let go of over.
- Holding 4 plants it in a site and defuses it, with the bar and the prompts, rooted, without the
  view or the bar jumping from a correction.
- The beeps keep time, faster at 25, 35 and 40 seconds, and come from the spike.
- A defuse stops when its defuser crouches out of sight of the spike.
- The blast kills everyone within 35 m, through walls, and no one further.
- Another player sees the spike, its tells and the blast, and hears the arming beeps and the
  defuse's beeping from where the planter or defuser is.
- The sounds are at sensible levels next to the others.

The [Studio test session](../studio-checklist.md), section 16, walks through these, with what to
expect.
