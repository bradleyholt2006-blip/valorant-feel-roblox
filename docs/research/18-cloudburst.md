# System 18: Cloudburst

Jett's Cloudburst is her smoke. In the reference it's thrown the moment C is pressed: a small
projectile that flies fast and straight, and bursts into a ball of smoke where it hits a surface,
or in mid-air once it has flown its longest. Holding C curves it towards the crosshair. The cloud
blocks sight both ways for a couple of seconds. She has two charges, bought in the buy phase.

This system adds it on top of system 17's kit, which already had it on the bar and in the buy
menu but couldn't cast it. It's the kit's first thrown ability. The projectile outlives the throw
and keeps flying after its thrower dies, so it isn't part of the player's simulation: it flies on
its own, on its thrower's ticks, from the same inputs on the server and on the thrower's screen.

As before, everything comes from Riot's patch notes and from community wikis and guides. No game
files, memory, network traffic or protected assets were used, and nothing reads the game while it
runs. The cloud's look is ours, and its sounds are recordings from the Creator Store's free
library, as system 17's are. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

## 1. Observable behaviour

- **The throw.** C throws it at once, with no equip first, from Jett's eye the way she's looking,
  up and down as well as round. Her gun is put away for a moment, and comes back quickly.
- **The flight.** Fast and straight, with no drop.
- **The curve.** Holding C after the throw bends it towards the crosshair, so a throw can go round
  a corner. Let go and it flies straight on.
- **The burst.** Where it hits a wall, a floor or a ceiling. Thrown into the open, it bursts in
  mid-air once it has flown its longest.
- **The cloud.** A ball of smoke that grows quickly to its size, stays for a couple of seconds and
  thins away. Nothing can be seen through it either way, and from inside it almost nothing can be
  seen at all. Shots, players and other throws go through it.
- **Charges.** Two, bought one at a time in the buy phase, and kept like any other basic ability's.
- **Sounds.** The throw, and the burst.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| Its time | Patch 7.04: from 4.5 s to 2.5 s, and the re-equip after it slightly longer, to cut "the persistent safety Jett gets dashing into or escaping with smokes" ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-7-04/), otherwise in our words) |
| What a charge costs | Patch 3.0: Cloudburst "Cost increased 100 >>> 200" ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/); system 17) |

### From the community

| What | Value | Sources |
| --- | --- | --- |
| The ability | "INSTANTLY throw a projectile that expands into a brief vision-blocking cloud on impact with a surface." "HOLD the ability key to curve the smoke in the direction of your crosshair." | [The VALORANT Wiki's Jett page](https://wiki.playvalorant.com/en-us/Jett) |
| Cost, charges, time | 200 credits, 2 charges, 2.5 s; v3.06: "Charges reduced 3 >>> 2" | The same page |
| Its speed | "Travel Rate 30 meters/s" | [The Fandom wiki's Cloudburst page](https://valorant.fandom.com/wiki/Cloudburst) |
| In the open | "The Cloudburst forcefully expands after a long duration of travelling." | The same page |
| The stow | "Jett's cloudburst quick stow mechanic could be used to equip weapons faster in desperate conditions." | The same page |
| An older stat block | "Time to Reach Full Size 0.5 seconds", "Cover Radius (Sphere) 5 meters wide", "Vision Range 4 meters", "Duration 4.5 seconds" (its time from before 7.04) | The same page |
| Flight, size, growth, stow | "Maximum travel time in air: 2 seconds", "Radius: 3.35 meters", "Duration: 2.5 seconds", "(includes 0.6-second deployment time)", "Unequip time: 0.25 seconds" | [Mobalytics' Jett page](https://mobalytics.gg/valorant/agent/jett) |
| Another size | "Radius: 4.5 meters", "Max duration: 2.5 seconds" | [GameRiv's list of smokes](https://gameriv.com/valorant-all-the-smoke-agents-smoke-durations-and-best-smokers/) |
| Among the smallest | "Starting from smallest we have Jett, Cypher and Brimstone followed by Omen and Viper." "Within the smoke, Brimstone and Jett provide the greatest visual obstruction." | [The Spike](https://thespike.gg/news/which-smoke-ability-is-the-best-in-valorant/62) |
| Omen's smoke, for scale | Dark Cover: "Radius 4.1 meters" | [The Fandom wiki's Dark Cover page](https://valorant.fandom.com/wiki/Dark_Cover) |
| Its earlier times | Patch 1.0: "Cloudburst smoke duration increased 4>>>7 seconds"; Patch 2.01: "cloudburst smoke duration decreased from 7 to 4.5 seconds." | The Fandom wiki's Cloudburst page; [esports.net's 2.01 notes](https://www.esports.net/wiki/game-updates/valorant-patch-notes-2-01/) |

The sources disagree on the cloud's size. Mobalytics gives a radius of 3.35 m, GameRiv 4.5 m, and
the Fandom wiki "5 meters wide", which reads as a diameter. The Spike ranks Jett's the smallest
smoke, below Omen's, whose radius the Fandom wiki gives as 4.1 m. That rules out GameRiv's 4.5 m.
We use Mobalytics' 3.35 m, the one stated as a radius with the current time beside it.

Nothing public says how fast the curve turns, how big the projectile is, how the cloud thins at
the end, or whether a player in the way stops a throw. Those are ours, and labelled as estimates.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How fast it curves | A public video of a curved throw from a known spot in the Range: its path against the floor grid, and the crosshair's turn |
| Its speed and longest flight | A throw into open sky in the Range: the frames from the throw to the mid-air burst, against 30 m/s and 2 s |
| The cloud's size | A cloud against the Range's floor grid or a wall of known size |
| How it grows and goes | The same, frame by frame: the burst to full size, and its last moments |
| Whether players stop it | A public video of a throw that hits a player |
| The stow | Frames from the throw to the first shot that can follow it |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| The throw | C throws it at once with a charge, from the eye, the way the crosshair points; a key held through doesn't throw again | Community |
| The gun put away | For 0.25 s it can't fire, reload or zoom, and a reload or a zoom under way stops | Community (0.25 s); estimate (what it stops) |
| Its flight | 30 m/s, straight, with no drop | Community (the speed); estimate (no drop) |
| Its longest | 2 s, then it bursts where it is: 60 m out on a straight throw | Community |
| The curve | While C is held from the throw on, it turns towards the crosshair at up to 240° a second, keeping its speed. Once C is let go it flies straight, and holding C again doesn't steer it | Community (holding curves it); estimate (240°/s, no steering after letting go) |
| What stops it | The level, as movement sees it. In flight it's a ball 0.2 m across, and it bursts touching what it hit. Players and dummies don't stop it | Estimate |
| The cloud | A ball 3.35 m in radius, growing over 0.6 s, fastest at first, then full; 2.5 s in all, the growth included, thinning to nothing over its last 0.3 s | Confirmed (2.5 s); community (3.35 m, 0.6 s); estimate (how it grows, the thinning) |
| Blocking sight | Solid to its radius, so nothing behind it shows, the enemy outlines included, with a softer edge round it | Ours |
| From inside | The screen is smoke | Ours |
| Charges | 2, at 200 credits each | Confirmed (200); community (2) |
| In a dash, rooted | No throw, as for every cast (system 17) | Estimate |
| The sounds | The throw a quick, thin swish; the burst a slow, thick whoosh; each heard to system 17's 30 m edge | Ours; estimate (30 m) |

## 5. Design

### The throw

`AbilitySim` casts it as it does the others: C pressed since the last tick, with a charge, and
nothing in the way (a dash, a plant or a defuse). The cast is a `throw`, with the eye and the aim.
`PlayerSim` then puts the gun away for its 0.25 s with `WeaponSim.stow`, which stops what a
holster stops and holds the gun's draw till then. That's all the player's simulation knows of it:
the charge and the stow are corrected by the ack like any other part of the kit.

### Its flight

`CloudSim` flies throws, a tick at a time, through the same world interface as movement:

- `CloudSim.step` turns a throw towards the aim if it's still curving, sweeps a 0.2 m box along
  its way, and bursts it where the sweep hits, part-way through the tick, or where it is once it
  has flown 2 s.
- `CloudSim.tick` is one of the thrower's ticks: each of their throws flies on with that tick's
  input (its aim, and whether C is held), the ones that burst leave the list, and the tick's own
  throws join it, to fly from the next tick. A throw is named by the tick it was thrown on, which
  both ends agree on.
- `CloudSim.drift` flies a throw nobody steers: straight on.
- `CloudSim.radiusAt`, `thicknessAt` and `inside` give the cloud at any age.

### The server

- `CloudServer` flies each player's throws on their ticks, after the tick's casts
  (`PlayerSimServer.tickListeners`). So C held on the thrower's screen steers the throw on the
  server on the same tick, from the same aim.
- It tells every client on the `Ability` remote, where casts already go: `flight`, where a throw
  is, as it's thrown and every 4 of its ticks after; and `cloud`, where it burst. Each is timed in
  server time: the throw's, plus how long it has flown.
- A throw whose thrower dies or leaves flies straight on, on the server's clock, and bursts as
  any other.
- The thrower's last cloud is their `VFLastCloud` attribute, in metres.

### The client

- `CloudView` flies your own throws at once, on your predicted ticks
  (`PlayerController.tickListeners`), through the same `CloudSim` and from the same inputs, so
  your cloud forms on your screen where the server's will. When the server's `cloud` comes, yours
  moves there if it's more than 0.25 m off, and forms there if it hadn't. If your ticks stop (you
  died), your throws fly straight on by themselves.
- Others' throws are drawn between the server's `flight` frames as the frame on your screen
  reaches them, and their clouds form when it reaches the `cloud`.
- A cloud is two balls: a solid core, and a translucent edge 1.12 times its size. The core has to
  be solid: a Highlight with `DepthMode` `Occluded`, our enemy outline, shows through translucent
  parts. As it thins, the core goes translucent and the outlines come back. With the camera
  inside a cloud, a full-screen smoke covers the view, under the HUD.
- None of a cloud's parts can be hit or touched, so shots, moves and throws go through it, on both
  ends.
- `AbilityEffects` plays others' throws and bursts through `GameSounds.playCast`, as it plays their
  other casts; your own burst plays where your cloud forms.
- `BuyMenu` shows the cloud's size and time and the throw's speed and longest flight.

### Not here yet

- **Your gun in a cloud.** The smoke covers the screen, your gun with it. The reference still shows
  your gun, and a little of the smoke close by.
- **Players in the way.** A throw flies through them.
- **A throw the server didn't see.** If your screen predicts a throw the server refuses (a charge
  it says you'd spent), its cloud stays on your screen alone for its time.
- **Sound through a cloud.** It doesn't dull what's behind it.
- **What clients are told.** Every client is told of every throw and cloud, wherever it is, and
  `VFLastCloud` is an attribute anyone can read.
- **Drift** is still to come. Blade Storm came next, in system 19
  ([19-blade-storm.md](19-blade-storm.md)).

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | `Cloudburst`: its numbers, each with its status and source |
| `src/shared/Abilities/AbilitySim.luau` | The `throw` cast, from the eye the way you look; Cloudburst playable |
| `src/shared/Abilities/CloudSim.luau` | The throw in flight: its curve, what it hits, its longest flight, and the cloud's size and thickness |
| `src/shared/PlayerSim.luau` | The eye passed to the kit, and the gun put away after a throw |
| `src/shared/Weapons/WeaponSim.luau` | `stow`: the gun away for a time |
| `src/shared/Audio/SoundConfig.luau` | The throw's and the burst's sounds |
| `src/server/PlayerSimServer.luau` | `tickListeners`: each tick's input and casts |
| `src/server/CloudServer.luau` | Each player's throws flown on their ticks, the dead's on the clock, `flight` and `cloud` out, `VFLastCloud` |
| `src/client/CloudView.luau` | Your throws flown at once, others' drawn, the clouds, and the smoke from inside |
| `src/client/AbilityEffects.luau` | Others' throw and burst sounds; `flight` left to `CloudView` |
| `src/client/BuyMenu.luau` | The cloud's and the flight's rows |
| `tests/cloudburst.luau` | 59 checks: the numbers and their labels, the throw and its charge, the aim, the stow, a dash and a plant, the flight and what stops it, the curve, the thrower's ticks, a copy flown on, a throw left alone, the cloud's life, the shop |

## 7. Debug tools

- After each burst the thrower's `VFLastCloud` attribute (select them under Players) is where the
  server says it burst, in metres.
- `Workspace.VFClouds` holds the parts: a small glowing `Throw` ball for each throw in the air,
  and a `Cloud` ball and its `CloudEdge` for each cloud. A cloud's `Centre` attribute is where it
  is on this screen, in metres, and `Moved` is set on one of yours that the server's word moved,
  more than 0.25 m from where your screen had it.
- `VFTestButtons` 4096 holds C: set it to throw, and keep it set to curve the throw. `VFTestYaw`
  and `VFTestPitch` aim.
- On the course a spent charge comes back 1.5 s later, as for the others, and `VFKit` reads
  `C2/2` when both are there.

## 8. Refinement loop

1. Find a public video of a curved throw in the Range, and one thrown into the open sky.
2. Measure the curve's rate from the path against the floor grid, and set
   `AbilityConfig.Cloudburst.turnRate`.
3. Time the open-sky throw to its burst, and check `speed` and `maxFlight` against it.
4. Measure a cloud against the grid, from its burst to its end, and set `radius`, `grow` and
   `fade`.
5. Throw on the course against the videos, a few each, and adjust.

## Known gaps to check in Studio

- C throws it at once from the eye, the way you look, and the gun comes back a quarter of a
  second later.
- It flies straight at 30 m/s, through the dummies, and bursts on a wall, on the floor, or in
  mid-air 60 m out.
- Holding C curves it towards the crosshair, and letting go straightens it.
- The cloud grows, stays and thins as the tests have it, and hides what's behind it, the outlines
  included, until it thins.
- From inside it the screen is smoke.
- Nothing is thrown in a dash or while planting.
- The throw and the burst are heard, the burst out to 30 m.
- Your cloud forms where the server says, on your screen at once.
- Another player sees the throw fly and the cloud form where it burst, and hears both, even once
  the thrower is dead.
- Cloudburst is on sale in the spike rounds, two charges at 200.

Section 22 of the [Studio checklist](../studio-checklist.md) covers these.
