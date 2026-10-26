# System 43: Omen's From the Shadows

Omen's From the Shadows is his ultimate, and the last of his kit played. Once its seven points are
full, X puts a map of wherever he plays in his hand, ready in 0.5 s, and the mouse moves a cursor
across it. A click of fire on a place he'd stand starts its 1.5 s windup, through which he's rooted
where he is, though he can look round; then he's a Shade standing there for 2.5 s, rooted again, the
world all but grey and dark past a few metres that grow as his time runs out; then he forms there,
free, his gun drawn again. X while he's a Shade, or an enemy's hit on it, sends him back to where he
cast it, unhurt. Everyone hears it fired, and an enemy's minimap goes dark until it's over. This
system adds the map and its cursor, where a place on it takes him, the windup, the Shade, his
forming and his being sent back, the server's check of the place and its judging of hits on the
Shade, and what everyone sees and hears of it.

As before, everything comes from public sources: three of Riot's patch notes and, for what Riot
doesn't give, the VALORANT Wiki's pages on From the Shadows, on Omen and on Team Deathmatch and two
guides (Boosting Ground's and esports.net's). No game files, memory or network traffic were used,
and nothing was read from the live game. Here the wiki's numbers are labelled community, though it
says some of them come from the game files. Riot gives that he's vulnerable as soon as he's out of
the Shade, how far his arrival's heard, that the ability key sends him back with his points lost all
the same, and that as a Shade he can pick up the spike and use doors; the wiki gives the map, fire
starting it, a Shade an enemy can destroy that sends him back to where he cast it, his rooting, his
grey and narrowed sight, the windup, his time as a Shade, the equip time, the cost, how far it's
heard and the enemies' minimaps obscured; the guides give the sound every enemy hears, his being
sent back unhurt, and the cost and times again. How the cursor moves, what a place on the map takes
him onto, how fast his sight comes back, how the Shade looks, what besides an enemy's bullet breaks
it and what's heard of it where are ours. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source gives how the map's cursor moves, what a place on the map takes him onto, how far he sees
as a Shade or how fast that grows, what the Shade looks like to others, whether anything but an
enemy's bullet breaks it, how far his forming or his being sent back is heard, or how an enemy's
minimap is obscured. Ours are in section 4: the cursor from where he stands, a pixel for each count
of the mouse; the floor under the place, from 2.5 m over the ground down, if he'd stand there, and
with no room there, the floor round it within 0.7 m; his sight from nothing to 10 m, growing as the
square of the time; the Shade dark and see-through; any enemy's hit breaking it, and nobody else's;
all of it heard out to 22.5 m but its firing, which is heard as far as the spike's blast; and the
minimap covered in dark.

## 1. Observable behaviour

- **In hand** (the wiki). "EQUIP a tactical map. FIRE to begin teleporting to the selected
  location." In our words, it's ready 0.5 s after X (from the game files, it says), it costs 7
  points, and his gun comes back at the normal speed after it.
- **The teleport** (the wiki and Boosting Ground). The wiki: "After a brief windup time, Omen will
  arrive at his destination as a Shade for a short amount of time." and "He will also be rooted in
  place, though he will still be able to rotate his body,"; its numbers, from the game files, it
  says: "Total duration: 4 seconds 1.5-second windup 2.5-second arrival at target location".
  Boosting Ground: "~4s Reform" and "He can start moving the moment he begins to reform."
- **As a Shade** (the wiki and Patch 0.49). The wiki: "As a Shade, Omen's vision is mostly grayscale
  and he is inflicted with a reduced vision radius." "On immediate arrival his vision radius starts
  at zero but during his time as a Shade this will gradually increase," "the rate of restoration
  getting quicker towards the end of the Shade's duration" "until the vision radius cap is
  completely removed." Patch 0.49: "Omen now immediately becomes vulnerable and no longer appears
  dark after he leaves his alternate shadow form".
- **Sent back** (the wiki, Patch 1.0 and Boosting Ground). The wiki: "While teleporting, Omen will
  appear as a Shade that can be destroyed by an enemy to cancel his teleport," "or PRESS EQUIP for
  Omen to cancel his teleport.", and "While he is a Shade, enemy agents can shoot a bullet at him to
  cancel the teleport," "returning Omen to his original position when he activated the ability."
  Patch 1.0: "From the Shadow, Omen can now cancel his teleport while in Shade form by pressing the
  ABILITY KEY again—" and "Omen still loses all of his ult points if he cancels." Boosting Ground:
  "This Shade can be destroyed by enemy fire" and "if destroyed, the teleport is canceled, and Omen
  returns unharmed to his original location."
- **What others hear** (Patch 0.49, the wiki and Boosting Ground). Patch 0.49: "The attenuation
  radius of the arrival sound on Omen's From the Shadows has been reduced to 2250" and "Attenuation
  is a big word, but the short of it is you have to be closer to Omen to echolocate where he’s
  teleporting to." The wiki has "Audio cue radius" "22.5 meters" (from the game files, it says), so
  Riot's 2250 reads as centimetres. Boosting Ground: "a loud, globally audible sound cue alerts all
  enemies". In our words, the wiki has a line he says as it's cast for allies and another for
  enemies.
- **The enemies' minimaps** (the wiki). "This activation will also cause the minimaps of enemy
  agents to become obscured for the ability's duration."
- **The spike and doors** (Patch 8.07 and the wiki). Patch 8.07's Russian edition has that, using
  it, Omen "теперь может подбирать Spike" "и взаимодействовать с другими объектами (например,
  дверями)." and "Теперь для этого ему не нужно отменять действие умения."; in our translation, he
  can now pick up the spike and use other things, doors for example, still a Shade, and no longer
  has to cancel it to. The wiki, of his rooting: "as well as being able to pick up the Spike and
  interact with any map useables (such as Lotus's rotating doors)" "if any of these are within
  range."
- **Its limits** (the wiki's history). Since v2.09, "Omen can no longer drop the Spike or weapons
  while casting From the Shadows". In our words: since v7.0 a suppression in Shade form stops it,
  and since v7.02 KAY/O's ZERO/point or Deadlock's Annihilation in the windup; v3.05 fixed him being
  stuck in something that blocked the place he was sent back to.
- **Its cost** (the wiki, Boosting Ground and esports.net). 7 points; in Team Deathmatch, 60 (the
  wiki).

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Omen now immediately becomes vulnerable and no longer appears dark after he leaves his alternate shadow form"; "If you were to find enemy Omen teleporting in, it was often confusing"; "The attenuation radius of the arrival sound on Omen's From the Shadows has been reduced to 2250"; "Attenuation is a big word, but the short of it is you have to be closer to Omen to echolocate where he’s teleporting to." | [VALORANT Patch Notes 0.49](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-49/), 28 April 2020 |
| "From the Shadow, Omen can now cancel his teleport while in Shade form by pressing the ABILITY KEY again—"; "Omen still loses all of his ult points if he cancels."; "We want Omen to attempt plays and create fear for his opponents with his ultimate." | [VALORANT Patch Notes 1.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-0/), 1 June 2020 |
| Omen, using From the Shadows, "теперь может подбирать Spike" "и взаимодействовать с другими объектами (например, дверями)."; "Теперь для этого ему не нужно отменять действие умения." In our translation: he can now pick up the spike and use other things, doors for example, still a Shade, and no longer has to cancel it to | [VALORANT Patch Notes 8.07](https://playvalorant.com/ru-ru/news/game-updates/valorant-patch-notes-8-07/) (the Russian edition), 16 April 2024 |

### From the community

| What | Source |
| --- | --- |
| "EQUIP a tactical map. FIRE to begin teleporting to the selected location."; "While teleporting, Omen will appear as a Shade that can be destroyed by an enemy to cancel his teleport," "or PRESS EQUIP for Omen to cancel his teleport."; "This activation will also cause the minimaps of enemy agents to become obscured for the ability's duration."; "He will also be rooted in place, though he will still be able to rotate his body," "as well as being able to pick up the Spike and interact with any map useables (such as Lotus's rotating doors)" "if any of these are within range."; "As a Shade, Omen's vision is mostly grayscale and he is inflicted with a reduced vision radius."; "On immediate arrival his vision radius starts at zero but during his time as a Shade this will gradually increase," "the rate of restoration getting quicker towards the end of the Shade's duration" "until the vision radius cap is completely removed."; "After a brief windup time, Omen will arrive at his destination as a Shade for a short amount of time."; "While he is a Shade, enemy agents can shoot a bullet at him to cancel the teleport," "returning Omen to his original position when he activated the ability."; "Total duration: 4 seconds 1.5-second windup 2.5-second arrival at target location"; "Audio cue radius" "22.5 meters". In our words: an ultimate of 7 points, on X; an equip of 0.5 s (from the game files, it says); the gun back at the normal speed; a line spoken as it's cast for allies and another for enemies | [VALORANT Wiki, From the Shadows](https://wiki.playvalorant.com/en-us/From_the_Shadows) (Weird Gloop) |
| History: v2.09 "Omen can no longer drop the Spike or weapons while casting From the Shadows". In our words: v0.49 vulnerable at once out of the Shade, and its arrival heard less far; v1.0 sent back by the ability key; v2.01 no gun in his hand as he forms; v2.02 no swapping to something else just after picking a place; v3.05 not stuck in something blocking the place he's sent back to; v6.08 the targeting's look; v6.10 the mouse cursor no longer shown on it; v6.11 its line spoken sooner; v7.0 stopped by a suppression in Shade form; v7.02 stopped by ZERO/point or Annihilation in the windup; v8.07 the spike and doors as a Shade; v9.03 pings and more icons on its map | The same |
| In our words: From the Shadows, 7 points and 4 s | [VALORANT Wiki, Omen](https://wiki.playvalorant.com/en-us/Omen) |
| In our words: From the Shadows, 60 points in Team Deathmatch | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) |
| "a loud, globally audible sound cue alerts all enemies"; "~4s Reform"; "This Shade can be destroyed by enemy fire"; "if destroyed, the teleport is canceled, and Omen returns unharmed to his original location."; "Omen can also manually cancel the teleport before it completes"; "He can start moving the moment he begins to reform."; "Requiring 7 ultimate points" | [Boosting Ground, Omen guide](https://boosting-ground.com/Valorant/guides/agent-guides/omen-guide) |
| In our words: 7 points, 4 s in all and 2.5 s of it a Shade, the ability key again cancelling it, and the spike picked up while it's cast | [esports.net, Omen guide](https://www.esports.net/wiki/guides/valorant-omen-guide/) |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| His sight as a Shade | Clips of a teleport to a floor marked every metre, stepped through his time as a Shade, noting the furthest mark he sees |
| What a place takes him onto | A custom game: places picked on crates, ledges and walls of known heights, noting where he stands |
| How far each sound is heard | A second player standing further from the Shade each time, until its arrival, its forming or its going back isn't heard |
| Its firing heard | A second player across the map, noting whether it's heard |
| What breaks the Shade | A second player trying a knife, their abilities, and a teammate's shot on it |
| An enemy's minimap | Clips from an enemy's view, stepped through from its firing to its end |
| The cursor | Clips of the map with the mouse moved a known distance |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| His kit | From the Shadows lit on Omen's card and the bar with the rest of his kit: nothing of his reads NOT YET now | Community (the kit: the wiki) |
| Its points | 7, from kills, deaths, plants and defuses, as every ultimate's; on the course full every life and full again 1.5 s after it's over; in Team Deathmatch 60, from kills and Ultimate Orbs alone | Community (7: the wiki, Boosting Ground and esports.net; 60: the wiki) |
| In hand | X with the points full puts its map in the fifth slot, ready 0.5 s later; X again or a number key puts it away, nothing spent. Alt fire does nothing. With it in hand you run at the knife's speed | Community (0.5 s: the wiki); estimate (the speed) |
| The map | With it in hand the big map's up wherever he plays: the arena's map or the spike map being played, and on the course a map drawn from its parts. The mouse moves a cursor across it, a pixel for each count, and not the view; it starts where he stands and stops 2 m past the floor's edge | Community (a map: the wiki); estimate (the rest) |
| The cursor | A ring, violet where fire would take him and red where it wouldn't, and red everywhere in the buy phase; once it's fired, a violet disc on the minimap where it's taking him, until he's formed | Estimate |
| Where it takes him | The floor under the place, looked for from 2.5 m over the ground down to 2 m under it, if it's level enough to stand on and he'd stand there, his body clear of everything from a step's height up: so onto a crate 2.0 m tall, but never onto a wall (5 m) or the arena's block (3.0 m). With no room there, the floor round it is tried, 0.35 m out and then 0.7 m, eight ways round each, the nearer first. Anywhere on the map, in his sight or not. With nowhere, fire does nothing and the map stays in hand | Community (the place picked on the map: the wiki); estimate (the rest) |
| Fire | Once it's ready, a click of fire on a place he'd stand starts its windup: the points are spent and the map's put away. The server takes a place only on the map being played, and a move asking for another goes as if it asked for none. Nothing in the buy phase | Community (fire: the wiki); estimate (the server's check, and the buy phase) |
| The windup | 1.5 s rooted where he is, coming to rest if he was moving, though he looks round as he likes: nothing pressed counts but crouch, so no moving, jumping, firing, casting, dropping, planting or defusing, and a plant or a defuse under way ends. X does nothing. He can be hurt and killed, which ends it | Community (1.5 s, rooted, turning: the wiki; no dropping: its v2.09); estimate (the rest) |
| The Shade | Then he's a Shade where it took him for 2.5 s, rooted again, looking round as he likes | Community (the wiki) |
| Hits on the Shade | An enemy's hit, a bullet, a knife or their fire, does it no harm and breaks it. A teammate's or his own does nothing, and a hit from nobody (the spike's blast, a spawn room's burn) hurts him as anyone. A shot or a swing goes by what the attacker's screen showed: one at him in the windup that lands once he's a Shade hurts him, and one at the Shade that lands once it's gone does nothing | Confirmed (vulnerable as soon as he's out of it: Patch 0.49); community (destroyed by an enemy: the wiki; unharmed: Boosting Ground); estimate (the knife, fire and the rest) |
| Sent back | X while he's a Shade, or an enemy's hit on it, sends him back at once to where he became one, his gun drawn again; the points are spent all the same | Confirmed (the ability key, the points: Patch 1.0); community (his original position: the wiki) |
| Formed | Once he's been a Shade 2.5 s he's there for good, free from that tick, his gun drawn again (the Vandal's ready 1 s later) | Community (4 s in all and the gun at the normal speed: the wiki; moving the moment he reforms: Boosting Ground) |
| What ends it | Its time, X, an enemy's hit, a death, a new life or a new round | Estimate |
| His own screen | Through the windup, shadow closing in from the edges, as Shrouded Step's. As a Shade, the world nearly grey (its colour down 85%), and dark past how far he sees: nothing (0.2 m) as he arrives, growing as the square of the time to 10 m as his time ends, and everything as he forms | Community (grey, his sight from zero and faster towards the end: the wiki); estimate (10 m, the square, the rest) |
| An enemy's minimap | Covered in dark, and the big map too, from its firing until he's formed, or sooner if he's sent back or killed | Community (the wiki); estimate (its look) |
| What others see | Through the windup, shadow swirling up round him, as Shrouded Step's; as he becomes a Shade, a puff of shadow where he was, for those who see him go, and shadow drawn in round the Shade, for those near enough to hear it; the Shade itself dark and see-through; as he forms, shadow drawn in round him; sent back, a puff where the Shade was and shadow drawn in where he's back | Confirmed (no longer dark once out of it: Patch 0.49); estimate (the rest) |
| Who hears it | Fired: everyone, as far as the spike's blast (200 m). As a Shade, forming and sent back: out to 22.5 m from where each is. Each client's told only the places it would see or hear | Confirmed (22.5 m: Patch 0.49, its 2250 read as centimetres, as the wiki has it); community (heard by every enemy: Boosting Ground); estimate (as far as the blast, forming and sent back) |
| Its look | In hand, a slate of shadow over an open hand with a violet mark on it | Estimate (ours) |
| Its sounds | A thick whoosh, the lowest of all, as the map comes into hand; a heavy whoosh slowed right down as it's fired; the spike's defuse tone slowed further than Shrouded Step's as the Shade arrives, and faster as he forms; a thin swish slowed as he's sent back | Estimate (ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** makes From the Shadows played: its points, its weapon and its line on Omen's
  card, and `FromTheShadows` (the windup, his time as a Shade, how far his arrival's heard, how high
  a floor can put him and how far under it one's looked for, how far round a place with no room it
  looks, and how far he sees as its time ends), each with its status and source. `unequip` gives the
  gun back once he's formed.
- **`WeaponConfig`** adds `shadowmap`, its map in hand, 34th of the weapons' wire ids.
- **`ShadowSim`** is new: where a place on the map takes him (`place`), and how far he sees as a
  Shade (`sight`).
- **`AbilitySim`** plays it as it plays the Resurrection: X with the points full puts its map in
  hand, and fire on a place he'd stand is a `shadows` cast, the points spent. The kit keeps when its
  windup ends, where he became a Shade and where it takes him (`shadowAt`, `shadowFrom`,
  `shadowTo`), and each tick of it (`shadowThrough`) tells of the Shade (`shade`), his forming
  (`form`) and X sending him back (`home`); `shadowing`, `gathering`, `shaded` and `formsAt` say how
  far along it is, and `busy` counts it.
- **`PlayerSim`** takes the input's place on the map as it's fired, holds him through the windup and
  as a Shade, puts him on the floor it found as he becomes one and back as he's sent back, and draws
  his gun again as he forms or is sent back; `PlayerSim.home` sends a Shade back between ticks.
  **`PlayerCodec`** carries the place in the input (the slot byte's top bit and two floats after
  it), the kit's new fields in the ack and a Shade in the pose, and **`PoseHistory`** never blends a
  Shade with where he was.
- **`Minimap`** draws a plan from shapes (`planOf`), says whether a place is on a plan's map
  (`holds`), holds one there (`held`), and finds the place a point on the screen shows (`fromView`).
  **`PartsPlan`** is new: the course's plan from its parts, and the plan of the map in play
  (`inPlay`).
- **`SoundConfig`** and **`FogOfWar`** add its sounds and the Shade's own curve, heard out to 22.5 m
  (`CastCurves`, `Edges.shade`).

### The server

- **`ShadowServer`** is new. It checks each place a move asks for against the map in play
  (`PlayerSimServer.pointCheck`), sets `VFLastShadow` as it's fired, judges hits on the Shade
  (`CombatServer.absorbs`), sending him back on an enemy's, and tells clients of the Shade and of
  his being sent back, each only the places it would see or hear.
- **`CombatServer`** asks `absorbs` before any hit hurts, with whether the attacker's screen showed
  a Shade; **`PlayerSimServer`** has the Shade in the pose, starts the snapshots over as he becomes
  one and as he's sent back, between ticks too (`moved`); **`AbilityServer`** tells every client of
  its firing, leaves the Shade and its going back to `ShadowServer`, and tells of his forming as far
  as it's heard.

### The client

- **`ShadowView`** is new: the map's cursor, your screen through it, others' windups, Shades,
  forming and going back, and the dark over your minimap while an enemy's runs.
- **`MinimapView`** shows the big map with the map in hand, the course's too, the cursor and where
  it's taking you, and its dark; **`CameraController`** gives the mouse to the cursor while the
  map's up (`mapCursor`); **`PlayerController`** sends the cursor's place with each input that
  fires, puts the view where the Shade is at once and where he's back, and leaves the blend out of a
  correction through it.
- **`RemoteEntities`** draws a Shade dark and see-through; **`StepView`** draws the swirl, the puff
  and the forming for it too; **`ParanoiaView`** draws the dark past how far a Shade sees (`cap`);
  **`AbilityHud`** lights X with `EQUIP`, `MAP`, the windup's seconds left and `SHADE`, and with the
  Resurrection's orb in hand too; **`AbilityEffects`**, **`WeaponLooks`**, **`GameSounds`** and
  **`SoundConfig`** give the map in hand its look and the sounds.

### Not here yet

- **Its voice lines.** Nothing's said as it's cast, to allies or to enemies.
- **The spike and doors as a Shade** (Patch 8.07). Nothing pressed counts but crouch, so a Shade
  can't pick up the spike, and there are no doors.
- **Cut short.** Nothing here suppresses or captures, so only a death, X or an enemy's hit stops it.
- **Sent back into something.** Where he's sent back to isn't checked: a wall raised there meanwhile
  has him inside it (v3.05 fixed this in the reference).
- **Pings on its map** (v9.03). Its map shows what the big map shows.
- **Spectating.** Whoever watches him isn't shown his map or his grey screen.
- **A client that stops.** A Shade whose moves stop coming stays one, rooted, until they come again
  or an enemy's hit sends it back; it's in play throughout, so the server needs no grace for it, as
  it does for Shrouded Step.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | From the Shadows played; `FromTheShadows`'s numbers, each with its status and source; `unequip` |
| `src/shared/Weapons/WeaponConfig.luau` | `shadowmap`, its map in hand, and its wire id |
| `src/shared/Abilities/ShadowSim.luau` | New: where a place on the map takes him, and how far he sees as a Shade |
| `src/shared/Abilities/AbilitySim.luau` | From the Shadows played: its `shadows`, `shade`, `form` and `home` casts, its windup and the Shade |
| `src/shared/PlayerSim.luau`, `src/shared/Net/PlayerCodec.luau`, `src/shared/Net/PoseHistory.luau` | The place taken, the hold, the Shade put there and sent back, and the gun drawn again; the input, the ack and the pose carrying them; a Shade never blended |
| `src/shared/Match/Minimap.luau`, `src/shared/Match/PartsPlan.luau` | A plan from shapes, and a place held on a map; new: the course's plan from its parts, and the plan in play |
| `src/shared/Audio/SoundConfig.luau`, `src/shared/Combat/FogOfWar.luau` | Its sounds, and the Shade's curve and edge |
| `src/server/ShadowServer.luau` | New: the place checked, `VFLastShadow`, hits on the Shade judged and an enemy's sending him back, and who's told what |
| `src/server/CombatServer.luau`, `src/server/PlayerSimServer.luau`, `src/server/AbilityServer.luau`, `src/server/init.server.luau` | `absorbs`; the Shade in the pose, the place checked first, the snapshots started over, and `moved`; its firing told to everyone and its forming as far as it's heard; `ShadowServer` started |
| `src/client/ShadowView.luau` | New: the cursor, your screen, others' Shades, and the dark over an enemy's minimap |
| `src/client/MinimapView.luau`, `src/client/CameraController.luau`, `src/client/PlayerController.luau` | The big map with it in hand, the course's too, the cursor, where it's taking you and the dark; the mouse moving the cursor; the place sent, and the view moved at once |
| `src/client/RemoteEntities.luau`, `src/client/StepView.luau`, `src/client/ParanoiaView.luau`, `src/client/AbilityHud.luau` | A Shade's look; the swirl, the puff and the forming shared; the dark past a Shade's sight; X on the bar |
| `src/client/Combat/WeaponLooks.luau`, `src/client/AbilityEffects.luau`, `src/client/Debug/TestAim.luau`, `src/client/init.client.luau` | Its map in hand; its sounds; `VFTestMapPoint`; the view started |
| `tests/fromtheshadows.luau` | New: its numbers, its map in hand, the teleport, sent back, where it takes him, a new life, the course's map, and the wire |
| `tests/arsenal.luau`, `tests/darkcover.luau` | The weapons' ids, and Omen's whole kit played |

## 7. Debug tools

- A player's `VFLastShadow` is where their last From the Shadows takes them, set as it's fired: the
  floor, in metres.
- `VFKit` reads `X7/7` with the points full, and ends in `equip` while its map's in hand, `shadows`
  through the windup and `shade` while they're a Shade.
- PlayerGui's `VFShadow` carries `Map` (whether its map's up), `Cursor` (the cursor's place, in
  metres), `Placeable` (whether fire would take you there), `Grey` (whether you're a Shade's grey),
  `Sight` (how far you see as one, in metres, or -1) and `Dark` (how covered your minimap is by an
  enemy's, 0 to 1); its `Edge` frame's stroke is the windup's shadow. The grey is a `VFShade`
  ColorCorrectionEffect under the camera.
- The minimap's ScreenGui, `VFMinimap`, reads `course` as its `Plan` while the course's map is up,
  and its `Dark` is how covered it is. The big map's, `VFMegamap`, has the cursor as `Shadow` among
  its icons, and the minimap has where it's taking you as `Shade`.
- `VFTestMapPoint`, a Vector3 in metres, puts the cursor on the map nearest that place once its
  map's up, then clears itself. `VFTestButtons` 32768 presses X, 128 the left button and 1 W, so it
  can be readied, fired and sent back without a key or a mouse button; `VFTestYaw` and `VFTestPitch`
  turn the view. In Studio, `VFTestGive` set to `ultimate` fills the ultimate's points.

## 8. Refinement loop

1. Step through clips of a Shade's arrival on a marked floor, and change `sight` and the curve it
   grows by.
2. Pick places on crates, ledges and walls of known heights, and change `top`, `depth` and `nudge`.
3. Walk away from a Shade until its arrival isn't heard, and from one forming and one sent back, and
   change the shade curve.
4. Try what breaks a Shade, and change `ShadowServer`'s `absorbs`.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- From the Shadows lit on Omen's card and the bar, `X7/7` on the course, and its map up 0.5 s after
  X, the course's drawn from its parts, with the cursor on you.
- The cursor held on the map, red off the floor, and fire there doing nothing.
- The teleport: the windup, then a Shade 25 m down the lane, grey, the dark drawing back, then
  formed, the gun back 1 s after, and `VFLastShadow`.
- Held through it, the view still turning.
- X as a Shade sending you back, and doing nothing in the windup.
- Onto the 1.00 m jump box and the crouch tunnel's roof, and beside a wall the cursor's on.
- With other players: the swirl, the puff, the Shade dark and see-through, its arrival heard within
  22.5 m; an enemy's shot sending it back unhurt; an enemy's minimap dark while it runs, and cleared
  as it's sent back; and the cursor red in the buy phase.

Section 47 of the [Studio checklist](../studio-checklist.md) covers these.
