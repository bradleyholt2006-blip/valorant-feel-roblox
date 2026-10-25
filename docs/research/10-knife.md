# System 10: The knife

Everyone carries the knife in slot 3. System 9 gave it its run speed and its draw; this system
makes it attack. The left button slashes, round a three-swing combo, and the right button stabs,
harder and slower. Either does double damage from behind, so a stab in the back kills anyone. A
swing catches one target, the one nearest the centre of the screen, never through a wall, and
leaves a cut where it strikes the level. Abilities, destructible objects and knife skins are
separate work.

As before, everything comes from Riot's patch notes and developers' public comments and from
community wikis and guides. No game files, memory, network traffic or protected assets were used.
Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source: here, the waveforms of the Roblox library sounds we play |

## 1. Observable behaviour

- Press 3 to draw the knife. You run at full speed with it, faster than with any gun.
- Hold the left button and it slashes again and again, twice a second. The slashes go round a
  combo of three swings, each a different way across the screen, and then start again.
- The right button stabs: one heavier thrust, with a longer recovery before the next.
- From in front, a slash does 50 and a stab 75. From behind they do double, 100 and 150, so a stab
  in the back kills through any shield. "Behind" is wide: anywhere past the line through the
  target's shoulders, so a stab from the side can kill too.
- A knife to the head does no more than one to the body. It still counts as a headshot.
- The reach is short, about an arm and a blade. The slash reaches a little further and wider
  than the stab.
- A swing hits one target. When two are in reach, the one nearer the centre of the screen takes
  it.
- A swing doesn't go through walls. When it hits no one, it leaves a cut where it strikes a wall,
  at once.
- Switching away and back cuts a stab's recovery short.

## 2. Publicly documented details

### From Riot

| Fact | Status | Source |
| --- | --- | --- |
| "The melee's been too tricky to aim with, making it tough to rely on. So we've updated both left and right click melee attacks for more reliable Agent-whacking action." | Confirmed | [Patch 4.01](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-4-01/) |
| "Right click hitboxes are now 1.5x larger." | Confirmed | The same notes |
| "Left click hitboxes are now larger than a right click and have a slightly longer range too." | Confirmed | The same notes |
| "Targets closer to the center of your knife attacks will get hit first, so you still have precision if you need it." | Confirmed | The same notes |
| "Knifing walls now have instant feedback when slicing up walls (predicted on the client side)" | Confirmed | The same notes |
| Before that: "The hitbox is static, unintuitive, and only active for a very brief period of time", with "visuals that imply the knife does damage during the entire slash motion" | Confirmed (quoted by the press) | Riot's weapons and modes designers, quoted by [THESPIKE](https://www.thespike.gg/valorant/news/better-knives-hit-detection-is-in-the-works-and-queue-dodge-punishments-explained/849) and [Twinfinite](https://twinfinite.net/news/riot-is-planning-to-buff-valorants-knife-hit-box-detection/) |
| "We don't think it should ever be the best choice in a fight, but we would like to make it feel better to use" | Confirmed (quoted by the press) | The same |
| "Melee attacks now inflict double the damage per hit to destructibles" | Confirmed | Patch 0.47, via the [VALORANT Wiki](https://wiki.playvalorant.com/en-us/Melee) |

### From the community

The VALORANT Wiki at wiki.playvalorant.com is run by Weird Gloop, not by Riot.

| Fact | Status | Source |
| --- | --- | --- |
| "Front - 50/75 (Primary/Alt)", "Back - 100/150 (Primary/Alt)"; double damage "when striking the target's back", which "allows a one-shot from behind" with the alternate attack | Community | [VALORANT Wiki, Melee](https://wiki.playvalorant.com/en-us/Melee); the same numbers on [PlayerAssist](https://playerassist.com/valorant-knife-damage/) and [THESPIKE](https://www.thespike.gg/valorant/news/a-deep-dive-into-the-pros-and-cons-of-valorant-s-knifing-system/301) |
| "The primary slash has a three swing combo that loops"; the alternate "deals more damage in a single strike but with a longer recovery and slightly smaller range and hitbox" | Community | The VALORANT Wiki, and the [Fandom wiki](https://valorant.fandom.com/wiki/Melee) word for word |
| Run speed 6.75 m/s; equip 0.6 s (Normal), 0.3 s (Fast), 0 s (Instant); length 46.59 cm | Community | The VALORANT Wiki |
| Its damage band is listed as "0 - 8m", the stat box's range column; no reach is given | Community | The VALORANT Wiki |
| Melee weapons are "fully-automatic, and have an extremely short range" | Community | [Fandom, Weapons](https://valorant.fandom.com/wiki/Weapons) |
| The main attack "twice per second", the secondary "0.8 times per second" | Community | NamuWiki's VALORANT equipment page; the same on thewiki.kr ("초당 2회", "초당 0.8회") |
| "The rear attack range is wide at 180 degrees, so even if you shoot from the side, you can kill with one shot" | Community | NamuWiki; thewiki.kr ("후면 공격 가능 범위는 180도로") |
| A knife to the head "shows a headshot animation and log entry but adds no extra damage"; "additional damage will not be applied if you hit the head" | Community | thewiki.kr; NamuWiki |
| The stab's recovery is longer than the swap to a gun and back, so stab, swap and swap back is faster than holding the knife | Community | thewiki.kr |
| Three slashes kill fastest through a 25 shield | Community | NamuWiki ("most effective to swing it three times with just a left click") |
| "The left click animation takes about 50 milliseconds", the right click's "about 150"; "it takes about 20 milliseconds after a start of swing sound cue for a hit to get registered"; "only one frame, maybe two, where the knife's hit is registered" | Community (a writer's measurement, before Patch 4.01) | [THESPIKE](https://www.thespike.gg/valorant/news/a-deep-dive-into-the-pros-and-cons-of-valorant-s-knifing-system/301) |

Nobody publishes the reach or the size of the hit volumes in metres, how the back is judged
beyond the 180-degree arc, or when the combo starts over.

## 3. What can be measured, and how

From your own copy of the game in The Range, played normally, with a video (Windows' Game Bar or
your graphics driver's recorder) and the bots. Never use any tool that reads the game's memory,
files or network traffic.

| Measurement | Method | Gives us |
| --- | --- | --- |
| Swing rates | Hold each button against a wall for 10 s and count the cuts, or the swing sounds in the video | `melee.slash.rate`, `melee.stab.rate` |
| Reach | Walk backwards from a standing bot a step at a time, slashing at its chest, and note where it stops taking damage; the floor's grid gives the distance. Again with the stab | `reach` |
| Width | At half the reach, aim further and further to the side of the bot until it stops taking damage; measure the angle from a video frame | `radius` |
| The back arc | Stand at the bot's side and step round it, stabbing, and note where the hit turns from 75 to 150 | Whether the 180° line is square to the way it faces |
| The combo's reset | Slash, wait, slash again, waiting longer each time, and note when the second slash is the combo's first again | `comboReset` |
| The swap | Stab, press 1 and then 3, stab again; count the frames between the stabs | That the draw, not the recovery, sets the gap |

## 4. Confirmed vs estimated, as implemented

Every value lives in `src/shared/Weapons/WeaponConfig.luau` (`melee`) with its status and source.

| Parameter | Value | Status |
| --- | --- | --- |
| Damage | Slash 50, stab 75; from behind 100 and 150 | Community |
| Any region | The same damage to the head, body or legs; a head hit still counts as a headshot (the headshot sound, `(head)` in the kill feed) | Community |
| Behind | A 180° arc: the attacker's eye past the line through the target's shoulders, square to the way it faces | Community (the arc); estimate (judged from the eye, at the swing's tick) |
| Rates | Slash twice a second (every 0.5 s), stab 0.8 a second (every 1.25 s), held or clicked | Community |
| Held | Swings again and again while held, as an automatic gun fires | Community |
| Both buttons | The left wins; each waits out the other's recovery | Estimate |
| The combo | Slashes go 1, 2, 3, 1, ...; a stab, a draw, or a slash coming more than 0.5 s after it could have starts it over | Community (the loop); estimate (when it starts over) |
| The combo's slashes | Do the same damage, reach and width; only the animation and the cut's angle differ | Estimate |
| Reach | Slash 2.0 m, stab 1.8 m, straight ahead of the eye | Estimate (the slash's longer: Patch 4.01) |
| Width | Slash 0.4 m, stab 0.3 m either side of the aim | Estimate (the slash's wider: Patch 4.01) |
| The volume | A capsule along the aim from the eye, `radius` round, reaching `reach` straight ahead | Estimate |
| One target | Of those it reaches, the one nearest the aim, then the nearer, then head before body before legs | Confirmed (nearest the centre first); estimate (the ties) |
| Walls | A target is hidden when the level is between the eye and each of its boxes the capsule reaches, at the point it reaches it; the next nearest then takes the swing | Estimate |
| When it hits | On the tick the button is sampled, with no windup | Estimate; the reference registers about 20 ms after the swing starts (community) |
| A cut in the wall | When it hits no one: where the aim meets the level within reach, at once on your screen, as the server has it on others' | Confirmed (instant, predicted); estimate (the look) |
| Draw | 0.6 s, and switching away and back cuts a recovery short | Community |
| Run speed | 6.75 m/s | Community |
| Lag compensation | The same as a bullet's: the server checks the swing against the targets as your screen showed them, up to 140 ms back | Estimate (that melee is rewound like guns) |
| Sounds | A sword's swish for each slash, a heavy whoosh for the stab, a knife into flesh for a hit, a blade striking metal for a wall, heard by others out to 12 m | Measured (each recording's peak and start, below); estimate (the picks, volumes, pitches and the 12 m) |
| The swing's look | Each slash of the combo sweeps across the view its own way (right to left, left to right, down from the top right) and the stab thrusts forward, out in 0.1 s and back by 0.35 s | Estimate (placeholder animation) |

The time to kill from the front, from the tests:

| Shield | Slashes | Stabs |
| --- | --- | --- |
| None (100) | 2, 0.5 s | 2, 1.25 s |
| Light Armor (125) | 3, 1.0 s | 2, 1.25 s |
| Heavy Armor (150) | 3, 1.0 s | 2, 1.25 s |
| Regen Shield (125) | 3, 1.0 s | 2, 1.25 s |

From behind, two slashes or one stab kill through any of them.

## 5. Design

### The swing

`WeaponSim` treats the knife as a weapon that swings instead of firing. On a tick when a button is
down, the knife is drawn and the last swing's recovery is over, it starts a swing: the left button
a slash, the right a stab. Held through the recovery, the next swing comes on the exact cadence, as
a held trigger does. The slash moves the combo on, or starts it over after a pause; the stab
starts it over. The swing comes out of `PlayerSim.step` like a round of bullets, with the eye and
the aim of that tick, so the client and the server step it the same way from the same input, and
the combo travels in the server's ack so a correction keeps it.

Riot's own complaint before Patch 4.01 was a hitbox "only active for a very brief period". We
resolve each swing once, on its first tick, like a hitscan shot. That keeps it simple and makes
it deterministic on both sides. The cost is the reference's 20 ms or so between the swing
starting and the hit, which we don't have.

### What a swing catches

`Melee` is pure, like `ShotResolver`: given the targets and the level, it decides a swing the same
way on the server and the client.

1. The volume is a capsule along the aim from the eye: a segment `reach - radius` long, `radius`
   round, so it reaches `reach` straight ahead. A target is in reach where any of its three boxes
   comes within `radius` of the segment. The nearest approach of a segment to a box is a convex
   function along the segment, so a golden-section search finds it; a segment that goes into the
   box meets it where it goes in, at no offset.
2. The targets in reach are ordered by how far each comes from the aim at its nearest box, as
   Patch 4.01 orders them, then by how far along the aim, then head before body before legs.
3. Walking that order, a target is struck at the first of its boxes, nearest the aim first, that
   the eye can see: a cast from the eye to the point the capsule reaches it, stopping 1 cm short so
   a box touching a wall still shows. A target with every box hidden is skipped, and the next takes
   the swing. So you can't knife through a wall, but a head over waist-high cover can be struck.
4. It does `front` damage, or `back` if the eye is behind the line through the target's
   shoulders.
5. With no one struck, the level straight ahead within reach is what the blade strikes, for the cut
   and its sound.

### Server and client

The server resolves each swing in `CombatServer.onSwing` against the targets rewound to the
swing's view time, exactly as it does a round of bullets, and applies the damage through the same
path: shields, the hit slow, the kill and the event every client gets, which now names the weapon
for the kill feed. It sends the attacker a verdict with what it tested (the rewound targets in
reach, the point struck, how far off the aim and out, from behind or not, the targets the level
hid, the rewind) and everyone else the swing, for its sound and its cut.

The client guesses the same swing at once in `ClientMelee`, against the targets as it drew them:
the cut and a spark where the blade strikes the level, or a small spark where it meets a target.
As for bullets, the hit marker, the damage number, the hit confirm pinned to the body part and the
hit sound wait for the server's verdict.

### Sounds

Picked from Pro Sound Effects' recordings in the Creator Store's free library, as in
[08-sound](08-sound.md) section 6: about 2,000 results of 47 searches, and 192 of them read in
10 ms windows with `AudioPlayer:GetWaveformAsync`, in a server-only Run session with nothing
played. One catch: `AudioSearchParams.AudioSubType` defaults to `Music`, so until it is set to
`SoundEffect` a search for "knife" finds only songs.

| Sound | Plays for | Recording (asset id) | Pro Sound Effects' description | Peak | Skips |
| --- | --- | --- | --- | --- | --- |
| `slash` | a slash, yours and others' | Swish Med High End Sharp Swords Fast Punches (9126014013), Swishes Thin Fast Singles Knife 4 (9119696677) | "Swish, Medium High End, Sharp, Swords, Fast Punches"; "Swishes, Thin and Fast, Singles, Knife" | 0.66, 0.42 | 0.15 s, 0.22 s |
| `stab` | a stab | Whoosh Heavy Punches 1 (9120728815), Whoosh Thick Quick Multiple Variations 2 (9120742716) | "Whoosh, Tennis Racket, Heavy Punches, Arm Swings, Midrange"; "Whoosh, Thick, Quick, Dreamy Flash" | 0.63, 0.70 | 0.11 s, 0.15 s |
| `knifeHit` | your knife's hit on a body, and others' | Flesh Stab 9, 5 (9114487207, 9114487004) | "Flesh Stab, Wet, With Knife" | 0.19, 0.15 | 0.12 s, 0.07 s |
| `knifeWall` | the blade striking the level, at 0.9 speed | Blade Hits Metal Rod On Knife Impacts 9, 5 (9113449513, 9113449377) | "Blade Hit, Metal Rod on Knife Impact, Some With Short Slide or Scrape, Sharpen, Sword" | 0.56, 0.54 | - |

Each swish is a burst of 50 to 160 ms with a near-silent tail. The Flesh Stabs are quiet takes,
turned up 2.6 and 3.3 times to the level, inside `MaxGain`; the library's other ten Flesh Stabs
peak at 0.10 or less. No blade striking stone or tile turned up, only metal on metal, so the
walls' strike plays a little lower. A head hit plays the headshot sound instead of `knifeHit`, as
a gun's does.

Passed over: "Sever Metal Hit 2" (9119028721, strong but gory), "Knife Stab 1" (9116197520, two
parts and past `MaxGain`), "Swish Big Fat Short 1" (9119690853, a 400 ms body), "Baseball Bat
Swing 5" (9113305619), and the "Sword Whip" takes, which are all layered with growls.

### Roblox differences that matter

- The reference sweeps its hit volumes through a skeleton's hitboxes; ours are three boxes per
  character, the same ones bullets use.
- The reference's swing has an animation and a hit frame; ours has a stand-in sweep of the
  viewmodel and resolves on the click's tick.
- Nothing in the arena is destructible yet, so the double damage to destructibles has nowhere to
  go.

## 6. Implementation map

| Piece | Where |
| --- | --- |
| The knife's numbers | `src/shared/Weapons/WeaponConfig.luau` (`melee`, `SwingDef`, `MeleeDef`) |
| When it swings, the combo | `src/shared/Weapons/WeaponSim.luau` (`swing`, `Swing`, `combo`) |
| The swing out of a tick | `src/shared/PlayerSim.luau` (`step` returns it) |
| The combo in the ack | `src/shared/Net/PlayerCodec.luau` |
| What a swing catches | `src/shared/Combat/Melee.luau` |
| Swings on the server | `src/server/PlayerSimServer.luau` (`SwingHandler`), `src/server/CombatServer.luau` (`onSwing`) |
| The remotes | `src/shared/Net/Remotes.luau` (`SwingResult`, `SwingFx`) |
| The client's guess and the verdict | `src/client/Combat/ClientMelee.luau` |
| The sweep, cuts, sparks and confirms | `src/client/Combat/WeaponEffects.luau` |
| Sounds | `src/shared/Audio/SoundConfig.luau` (`slash`, `stab`, `knifeHit`, `knifeWall`, the `melee` curve), `src/client/Audio/GameSounds.luau` |
| The kill feed's weapon | `src/client/Combat/CombatHud.luau` |
| Tests | `tests/melee.luau` |

## 7. Debug tools

- **Weapon Lab (F2):** with the knife out, both attacks' rate, reach, width and damage, where the
  combo is, and the last swing with the time since the one before.
- **Hit Reg Lab (F2, third page):** the knife's swings, verdicts, agreement with the client's
  guess and hits from behind, and the last swing: what it caught, how far off the aim and out, how
  many the level hid, the rewind, and what the client guessed when it differed.
- **Hitbox overlay (F10):** each swing's reach, drawn from the eye: its aim out to `reach -
  radius`, its sides `radius` either way and a disc at its end; the point where the client had it
  strike (yellow) and the boxes in reach as the client tested them; with the verdict, the server's
  point (blue), its boxes (white where they match the client's), and a label with the swing, the
  rewind, what it caught, how far off the aim and the damage, red if the client guessed otherwise.
- **`VFTestSlot`:** 1, 2 or 3 draws that slot from an attribute, for scripted checks, with
  `VFTestButtons` 128 (slash) and 256 (stab) to swing.

## 8. Refinement loop

1. Measure the reach and the width in The Range (section 3) and set `reach` and `radius`.
2. Time the combo's reset and set `comboReset`.
3. Check the back arc from the side of a bot.
4. Set the sounds' volumes and pitches by ear against the guns, and swap the walls' strike for a
   blade on stone if the library gets one (section 5, Sounds).
5. Play it: if a knife that lands on the click feels too quick next to the reference's 20 ms,
   delay the hit by a tick or two.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). The sounds
were picked by title, description and waveform, not by ear. Only a Studio session can confirm:

- The slash and the stab come at their rates, round the combo, and the swap cuts a stab short.
- Each does its damage from in front and from behind, through the shields, and kills as the
  tests have it.
- A swing never reaches through a wall, a barrier or a teammate, but reaches a head over cover.
- The cut appears at once on a wall, on the right face, and others see their opponent's cuts.
- The sweep reads as a swing in each direction, and the sounds are heard where they should be,
  none of them louder than a gunshot.
- The overlay's reach matches where hits stop landing.

The [Studio test session](../studio-checklist.md), section 14, walks through these, with what to
expect.

### Checked in BRINK

Playtests in BRINK on main at 54f655b solo and at ffd966c with two players, swings made through
`VFTestButtons` and read from the labs, the HUD and the overlay (measured):

- Rates and the combo (K1): slashes 500.0 ms apart, going 1, 2, 3, 1; stabs 1250.0 ms apart;
  with both buttons held, slashes. After 1.5 s without a swing the next slash was slash 1 again.
- Damage (K2, K3): from 1.16 m a slash struck Dummy_1's body 0.00 m off the aim and 1.09 m out,
  rewound 57 ms, with the client agreeing: `83 + 17`, then `50 + 0`, and the third killed. A stab
  read `75 + 1` and the second killed. To the head a slash did 50, and the kill feed read
  `Bradley  [Knife]  Dummy 1  (head)`. From behind one stab killed, and two slashes did. From
  the side, just behind the line of the shoulders, a stab did 150; just in front of it, 75.
- Reach (K4): the last slash to land was 0.39 m off the aim and 1.60 m out, the last stab 0.30 m
  off and 1.50 m out, the ends of their capsules; 2 to 3 cm further back, both missed.
- The cut (K5): from 1 m, each slash left a cut on the wall's face with a spark and the strike's
  sound, the first two level and the third tilted about 30°; a stab's cut was shorter. From
  2.2 m, nothing. Backspace cleared them.
- Cover (K6): standing, a slash struck a dummy's head over waist-high cover (`83 + 17`, the
  headshot sound); crouched, the same slash struck the cover, with a cut there and no damage.
- The overlay (K7): three lines 1.60 m long, 0.4 m apart, and a 0.80 m disc; the client's and the
  server's points together; the label `slash 1  rewind 47 ms  Dummy_1 body 0.00 m off  50`, white.
- The swap (K8): stab, then 1 and 3 and the right button held: the next stab came 0.61 s after 3
  was pressed, as the knife finished drawing.
- Two players (K9): a slash from in front read `83 | +17` on the other's HUD; a stab from behind
  did 150 and killed, the HUD reading `0`, and both kill feeds read `Player2  [Knife]  Player1`.
  The one struck heard each swing and hit from where the other stood, and saw the other's cut on
  a wall at the same place to the centimetre, with its spark and sound.
- The guns after the knife: Vandal 9.73 rounds a second, Phantom 10.97, Sheriff 3.72, Classic
  5.46, Operator 0.59; 17 of 17 shots at the 15 m strafer agreed, rewound 50 ms on average; the
  Bucky at 10 m read 126; 159 of 159 sounds loaded, the knife's 8 among them.
