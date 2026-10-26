# System 40: Omen's Dark Cover

Omen joins agent select, a Controller with his whole kit on the bar, and his Dark Cover is the first
of it played. E puts a shadow orb in hand, ready in 0.6 s, with a mark along the crosshair, seen
through walls, where its smoke would go: held fire sends the mark further and held alt fire brings
it closer, and E again sends the orb there, unseen and through anything in its way, to burst into a
ball of dark smoke 4.1 m round on the floor under the mark. It stands for 15 s, warns that it's
going for its last 1.5 s, and goes at once. This system adds the mark and its moves, where a smoke
goes, the orb's flight, the smoke in the minimap's spotting and the heal's and the return's aim, who
hears it sent, and how it looks and sounds.

As before, everything comes from public sources: six of Riot's patch notes and, for what Riot
doesn't give, the VALORANT Wiki's pages on Dark Cover, on Omen and on Team Deathmatch. No game
files, memory or network traffic were used, and nothing was read from the live game. Here the wiki's
numbers are labelled community, though it says some of them come from the game files. Riot gives the
controls, the cost, the free charge, the cooldown, the duration, the orb's speed and who hears it
sent; the wiki gives the equip and unequip times, the reach, the radius, the time it takes to form
and the warning; where the mark starts, how fast it moves, how near it comes and how far down a
floor is looked for are ours. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source gives where the mark starts as the orb comes into hand, how fast held fire moves it, how
near it can come, whether anything stops the orb on its way, or whether the cooldown brings back one
charge or both. Ours are in section 4: where the crosshair meets the level, 15 m out at most; 15 m a
second; 2 m; nothing stops it; and a charge at a time, up to two.

## 1. Observable behaviour

- **In hand** (the wiki). "EQUIP a shadow orb, entering a phased world to place and target the
  orbs." It's ready 0.6 s after E (the wiki's estimate), and the gun is back 0.7 s after the orb's
  sent (from the game files, it says).
- **The phased world** (Patch 1.0). "Omen now enters a “phaser” world where he can see through walls
  to place his smokes"; "pressing RELOAD toggles between phased and normal targeting." The wiki
  adds, in our words, that the phased world mirrors the map with the view centred on the smoke's
  indicator, that allies, walls and roofs aren't shown in it and enemies in view are outlined red,
  and that his body still moves as the fire keys move the indicator; "Omen will still be able to
  hear everything happening around him clearly while in the phased world." Reload's normal view
  still moves the indicator.
- **The controls** (Patch 1.0). "Dark Cover controls have been updated where Omen can now increase
  smoke distance with PRIMARY FIRE," "decrease it with SECONDARY FIRE, and throw smoke with the
  ABILITY KEY." "We wanted to provide Omen with a more precise way to place his smokes, especially
  when verticality is at play."
- **Its reach and flight** (the wiki and Patch 4.04). Up to 80 m away (from the game files, the wiki
  says), at any position and height in range; the orb is unseen on its way, and the smoke forms as
  it arrives, in our words. "Projectile Speed increased 2800 >>> 6400": 64 m/s, the wiki has it.
- **Where it settles** (the wiki, in our words). A smoke whose centre isn't over a level surface it
  could stand on sinks until it is: since v6.0 one placed inside walls falls to the ground nearby,
  and since v9.10 it always falls to level geometry it can stand on. A fix in v3.04 stopped smokes
  settling away from where they were aimed.
- **The smoke** (Patch 0.50 and the wiki). "Dark Cover smoke duration increased 12 >> 15 seconds".
  It's 4.1 m round and takes 1 s to deploy (from the game files, the wiki says), and inside it
  vision is clear; 1.5 s before it ends (since v7.08) a sound and a look warn that it's going, and
  then it's gone at once, in our words.
- **Its charges** (Patches 0.50, 3.0, 4.04 and 11.08). "Granted signature charges reduced 2 >>> 1";
  "Omen now must buy his second smoke for 100", and Patch 4.04 made it "Cost increased 100 >>> 150".
  Its cooldown went "Dark Cover cooldown increased 30 >> 35 seconds", "Cooldown time increased
  35 >>> 40", "Cooldown decreased 40s >>> 30s", and last "Cooldown increased from 30s → 40s".
- **Who hears it** (Patch 11.00). "Dark Cover no longer plays audio in third person within 12.5
  meters for opponents. This audio will still play for Allies." The same patch stopped a smoke
  giving away where he is, in our words.
- **His role and kit** (Patch 4.04 and the wiki). "We want to increase his reliability as a
  Controller by rolling back a selection of early nerfs to Dark Cover". The wiki lists Shrouded Step
  (C, 100 credits, 2 uses), Paranoia (Q, 250 credits, 1 use), Dark Cover (E, 150 credits, 2 uses)
  and From the Shadows (X, 7 points).

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Dark Cover smoke duration increased 12 >> 15 seconds"; "Dark Cover smoke projectile speed increased"; "Dark Cover cooldown increased 30 >> 35 seconds" | [VALORANT Patch Notes 0.50](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-50/), 12 May 2020 |
| "Omen now enters a “phaser” world where he can see through walls to place his smokes"; "pressing RELOAD toggles between phased and normal targeting."; "Dark Cover controls have been updated where Omen can now increase smoke distance with PRIMARY FIRE,"; "decrease it with SECONDARY FIRE, and throw smoke with the ABILITY KEY."; "We wanted to provide Omen with a more precise way to place his smokes, especially when verticality is at play." | [VALORANT Patch Notes 1.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-0/), 1 June 2020 |
| "Granted signature charges reduced 2 >>> 1"; "Omen now must buy his second smoke for 100"; "Cooldown time increased 35 >>> 40"; Paranoia "Cost decreased 400 >>> 300"; Shrouded Step "Cost increased 100 >>> 150" | [VALORANT Patch Notes 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/), 22 June 2021 |
| Dark Cover "Cooldown decreased 40s >>> 30s"; "Cost increased 100 >>> 150"; "Projectile Speed increased 2800 >>> 6400"; "We want to increase his reliability as a Controller by rolling back a selection of early nerfs to Dark Cover" | [VALORANT Patch Notes 4.04](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-4-04/), 1 March 2022 |
| "Dark Cover no longer plays audio in third person within 12.5 meters for opponents. This audio will still play for Allies."; in our words, a smoke no longer gives away where he is | [VALORANT Patch Notes 11.00](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-00/), 24 June 2025 |
| Dark Cover "Cooldown increased from 30s → 40s" | [VALORANT Patch Notes 11.08](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-08/), 14 October 2025 |

### From the community

| What | Source |
| --- | --- |
| A Controller. Dark Cover: "EQUIP a shadow orb, entering a phased world to place and target the orbs."; 150 credits, 2 uses, 15 s, a 40 s cooldown. Shrouded Step 100 credits and 2 uses, Paranoia 250 credits and 1 use, From the Shadows 7 points | [VALORANT Wiki, Omen](https://wiki.playvalorant.com/en-us/Omen) (Weird Gloop) |
| In our words: equip 0.6 s (its estimate); unequip 0.7 s, a reach of 80 m, a deploy time of 1 s and a radius of 4.1 m (from the game files, it says); 64 m/s (Patch 4.04); 15 s (Patch 0.50); a warning at 13.5 s (v7.08); a phased world mirroring the map, the view centred on the indicator, the fire keys moving it as the body still moves, allies, walls and roofs unseen and enemies in view outlined red; "Omen will still be able to hear everything happening around him clearly while in the phased world."; reload for a normal view that still moves the indicator; any position and height in range; the orb unseen, the smoke forming as it arrives; a smoke not over level ground it could stand on sinking until it is (v6.0, v9.10); vision inside clear; gone at once after its warning | [VALORANT Wiki, Dark Cover](https://wiki.playvalorant.com/en-us/Dark_Cover) |
| History, in our words: v3.04 fixed smokes settling away from where they were aimed; v11.10 made its darkness on the minimap match that of other dome smokes; v13.05 fixed it blocking abilities that need a line of sight after it had gone | The same |
| Team Deathmatch: Shrouded Step back 33 s after, Paranoia 73 s and Dark Cover 65 s; From the Shadows 60 points | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| Where the mark starts | Clips of Dark Cover readied facing walls at known distances and in the open, stepped to the first frame its indicator shows |
| How fast fire moves it | Clips of fire held, stepped against map features of known spacing |
| How near it comes | A custom game: hold alt fire until it stops, and measure from where you stand |
| Whether anything stops the orb | A custom game: send it through a wall and into the open the same distance away, and time each from the throw's sound to the smoke |
| The cooldown | A custom game with both charges spent: note when each comes back |
| Inside a smoke | A custom game with a second player: stand inside one, and note what each of you sees |
| On a slope | A custom game: send it onto roofs and ramps, and note where it forms |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| His kit | Omen in agent select after Jett, Phoenix and Sage, a Controller, with Shrouded Step, Paranoia, Dark Cover and From the Shadows on his card and the bar. Dark Cover's played; the rest read NOT YET, and aren't sold | Confirmed (Controller: Patch 4.04); community (the kit: the wiki) |
| Its charges | Two at most: one free each round and the second 150 credits in the spike rounds. A spent one comes back 40 s after, a charge at a time, and in Team Deathmatch 65 s after, starting with one; on the course a spent one's back 1.5 s after | Confirmed (150: Patch 4.04; one free: Patch 3.0; 40 s: Patch 11.08); community (two, 65 s: the wiki); estimate (a charge at a time) |
| In hand | E puts the orb in the fifth slot, ready 0.6 s later; a number key puts it away, with nothing spent. Fire and alt fire throw nothing and shoot nothing. With it you run at the knife's speed | Community (0.6 s: the wiki's estimate); estimate (the speed) |
| The mark | Along the crosshair from the eye, through walls. It starts where the crosshair meets the level, 15 m out at most and 2 m at least; held fire sends it 15 m a second further and held alt fire brings it 15 m a second closer, from 2 m to 80 m; both held, it stays. A new life or round forgets it | Confirmed (fire and alt fire, through walls: Patch 1.0); community (80 m: the wiki); estimate (15 m, 15 m a second, 2 m) |
| Where the smoke goes | On the floor under the mark, looked for straight down, up to 50 m below. A mark inside the level is first brought back along the crosshair, a quarter metre at a time, until it's out; the smoke falls on through a floor too steep to stand on (more than about 45 degrees, as the Barrier Orb's) to the next one below that could hold it. With no floor, nothing's sent, and the orb stays in hand | Community (falling to ground it could stand on: the wiki); estimate (50 m, the steps, 45 degrees, nothing sent) |
| E again | Once the orb's ready: its charge is spent, it's put away and the gun's back 0.7 s later. Before it's ready, nothing's sent | Confirmed (the key: Patch 1.0); community (0.7 s: the wiki) |
| The flight | Straight from the eye to the smoke at 64 m/s, unseen, through anything in its way; the smoke forms as it gets there | Confirmed (64 m/s: Patch 4.04); community (unseen: the wiki); estimate (through anything) |
| The smoke | A ball 4.1 m round, its middle on the floor, so a dome above it, growing over 1 s, quickly at first. It stands 15 s from when it formed; for its last 1.5 s it flickers lighter, never thinner, with a low tone, and then it's gone at once | Confirmed (15 s: Patch 0.50); community (4.1 m, 1 s, 1.5 s: the wiki); estimate (the growth, the flicker) |
| What it hides | The minimap's spotting stops at it, as do the Healing Orb's and the Resurrection's aim, as they do at a cloud; the minimap draws it. The fog of war still sends whoever's behind it, who could step out at any moment. From inside it, the screen is dark | Community (on the minimap: the wiki); estimate (the rest; the wiki has vision inside clear) |
| Who hears it | The orb sent: the sender and their side, wherever they are, and no opponent. The smoke forming and its warning: anyone near it, from the smoke | Confirmed (Patch 11.00); estimate (opponents nowhere, the forming and warning) |
| A new round | Every smoke gone | Estimate |
| Its look | The orb in hand a violet ball with two wisps over an open hand; the mark a small violet ball, and the smoke it would make a faint violet ball on the floor under it, both seen through walls; with nowhere for it, the mark red and alone; the smoke dark violet | Estimate (ours) |
| Its sounds | A low whoosh as the orb comes into hand; a slow, deep swish as it's sent; a deep whoosh as the smoke forms; a low bell as it warns | Estimate (ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** adds Omen and his kit: Dark Cover's cost, charges, free charge, cooldown,
  weapon and line on his card, the others' costs and charges, and `DarkCover` (the unequip, the
  reach and its start, how near, how fast it's pushed, the orb's speed, the smoke's radius, growth,
  duration and warning, and how far down a floor is looked for), each with its status and source;
  Team Deathmatch's times and points for his kit.
- **`WeaponConfig`** adds `smokeorb`, the orb in hand, 31st of the weapons' wire ids.
- **`SmokeSim`** is new: the mark (`start`, `moved`, `mark`), where a smoke goes (`place`), the
  orb's flight (`flight`) and the smoke (`radiusAt`, `warning`).
- **`AbilitySim`** plays Dark Cover as it plays the other orbs: E puts it in hand, and the kit keeps
  how far along the crosshair its mark is (`reach`, on the ack), which held fire or alt fire moves;
  E again is a `smoke` cast carrying the mark. `VFKit` ends in `equip mark 15.0` while it's in hand.
- **`PlayerSim`** starts the mark as the orb comes into hand. For each `smoke` cast, once the orb's
  ready, it finds where the smoke goes; with somewhere, it spends the charge, puts the orb away and
  the cast carries where, and with nowhere, the cast's dropped. Fire with the orb in hand fires
  nothing.

### The server

- **`CloudServer`** sends each smoke: it forms when the orb gets there, the server time it was sent
  plus its flight; every client is told at once (`darkcover`: where, and when), and it's kept with
  the clouds while it stands, so the minimap's spotting and the heal's and the return's aim stop at
  it. The sender's `VFLastSmoke` is where it went. `clear` drops every cloud and smoke.
- **`AbilityServer`** tells of the orb sent (the `smoke` cast) to the sender and their side alone.
- **`Arena`** clears the clouds and smokes with each round.

### The client

- **`CloudView`** draws the mark and the smoke it would make, seen through walls, red with nowhere
  for it; each smoke, growing, flickering as it warns, and gone at its end; the dark screen from
  inside one; and the sounds of yours forming and of every warning. A new round's `out` clears them.
- **`AbilityEffects`** plays the orb sent and others' smokes forming, as it plays any cast, and
  **`WeaponLooks`** and **`SoundConfig`** give the orb in hand its look and the sounds.

### Not here yet

- **The phased world.** There's no phased view: the mark and the smoke it would make are drawn over
  the level instead, and reload does nothing.
- **Inside a smoke.** The wiki has vision inside clear; ours darkens the screen, as a cloud's does.
- **The buy phase.** Smokes can be sent in it; no source says whether they can.
- **The rest of his kit.** Shrouded Step, Paranoia and From the Shadows are on his card and the bar
  but not played yet.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | Omen and his kit; `DarkCover`'s numbers, each with its status and source; Team Deathmatch's for his kit; `unequip` |
| `src/shared/Weapons/WeaponConfig.luau` | `smokeorb`, the orb in hand, and its wire id |
| `src/shared/Abilities/SmokeSim.luau` | New: the mark, where a smoke goes, the flight and the smoke |
| `src/shared/Abilities/AbilitySim.luau` | Dark Cover played: its mark kept and moved, and its `smoke` cast |
| `src/shared/PlayerSim.luau` | The mark started; a smoke sent, its charge spent and the orb put away, or nothing sent |
| `src/shared/Net/PlayerCodec.luau` | The mark in the ack |
| `src/shared/Audio/SoundConfig.luau` | The orb's draw, the send, the smoke forming and its warning |
| `src/server/CloudServer.luau` | Smokes sent, formed, told of and kept with the clouds; `VFLastSmoke`; `clear` |
| `src/server/AbilityServer.luau` | The orb sent told of to the sender's side alone |
| `src/server/Arena.luau` | Clouds and smokes cleared with each round |
| `src/client/CloudView.luau` | The mark, the smokes, their warning, the screen from inside, and the sounds |
| `src/client/Combat/WeaponLooks.luau`, `src/client/AbilityEffects.luau` | The orb in hand; the sounds of others' sends and smokes |
| `tests/darkcover.luau` | New: its numbers, Omen and his kit, where its smoke goes, the flight and the smoke, the orb in hand and its mark, the send, and the wire |
| `tests/arsenal.luau`, `tests/healingorb.luau`, `tests/resurrection.luau` | The weapons' ids and the agents picked |

## 7. Debug tools

- A player's `VFLastSmoke` is the floor their last smoke went on, in metres, set as it's sent.
- `Workspace.VFClouds` holds each smoke as a `Smoke` ball with its `SmokeEdge`, the `Centre`
  attribute where it is (metres), and with the orb in hand the mark, a `SmokeMark` part with its
  `Mark` and `Ghost` adornments.
- `VFKit` reads `E2/2` with both charges, and ends in `equip mark 15.0` while the orb's in hand, how
  far out its mark is, in metres.
- `VFTestButtons` 16384 presses E, 128 the left button and 256 the right, so the orb can be readied,
  its mark moved and sent without a key or a mouse button; `VFTestYaw` and `VFTestPitch` aim.

## 8. Refinement loop

1. Step through clips of the indicator as it shows, and set `start`.
2. Step through clips of fire held, and set `push`.
3. In a custom game, bring it in as near as it goes, and set `near`.
4. Time sends through walls and in the open, and keep or change the flight through anything.
5. Spend both charges, and set how the cooldown brings them back.
6. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Omen lit in agent select, a Controller, with Dark Cover lit and the rest NOT YET, and `E2/2` on
  the course.
- In hand 0.6 s after E, the mark 15 m out, moved by held fire and alt fire within 2 to 80 m, seen
  through walls, and red with nowhere for it.
- The smoke: sent with E, the gun back 0.7 s after, forming where the mark showed, growing over 1 s,
  standing 15 s, flickering for its last 1.5 s and gone.
- A mark behind a wall, and over a ramp too steep to stand on.
- With other players: their spotting stopped at it, the send heard by the sender's side alone,
  every smoke gone with a new round, and the second charge bought at 150.

Section 44 of the [Studio checklist](../studio-checklist.md) covers these.
