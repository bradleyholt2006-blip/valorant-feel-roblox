# System 17: The ability kit

In the reference every agent carries four abilities, one on each of C, Q, E and X. Two are basic
abilities, bought a charge at a time in the buy phase. One is the signature, with a free charge
every round. The last is the ultimate, cast once enough ultimate points have built up: a point for
each kill, death, plant, defuse and ultimate orb. Every agent's abilities are their own, but the
rules for charges, buying and points are the same for all of them.

This system adds that kit, and plays the first agent's movement through it: Jett's Updraft, which
throws her straight up, and her Tailwind, which readies a gust and then dashes her the way she's
moving. They're the abilities that most need what the simulation already does, since they move the
player: each cast is predicted on your screen on the tick you press it and decided by the server,
which runs the same ticks. Her other two, the Cloudburst smoke and the Blade Storm knives, were
in the kit and the buy menu but couldn't be bought or cast yet. Cloudburst came next, in system 18
([18-cloudburst.md](18-cloudburst.md)), then Blade Storm in system 19
([19-blade-storm.md](19-blade-storm.md)) and her passive, Drift, in system 20
([20-drift.md](20-drift.md)). Everyone plays Jett until there's an agent select.

As before, everything comes from Riot's patch notes and from community wikis and guides. No game
files, memory, network traffic or protected assets were used, and nothing reads the game while it
runs. The casts' look is ours, and their sounds are recordings from the Creator Store's free
library, which systems 8 and 10 already use. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

## 1. Observable behaviour

- **The keys.** C, Q, E and X by default, and an ability bar at the bottom of the screen showing
  each, with a pip for each charge.
- **Basic abilities** (Jett's Cloudburst on C and Updraft on Q). Bought a charge at a time in the
  buy phase, up to as many as each holds, and sold back while the buy phase lasts. Unused charges
  are kept into the next round, and through a death.
- **The signature** (Jett's Tailwind, on E). A free charge every round. Some signatures come back
  on a cooldown, Jett's with kills. A charge that came back that way isn't kept into the next
  round.
- **The ultimate** (Jett's Blade Storm, on X). Its points show as pips. They come from kills,
  deaths, the plant, the defuse and the orbs on the map, and it's cast when they're full.
- **Updraft.** Jett is thrown high into the air at once, and then falls back down.
- **Tailwind.** E readies a gust, with a windup before it can be used. Then, for a few seconds,
  E again dashes her the way she's moving, or forward if she's standing still. The dash is short
  and fast. Two kills bring the charge back.
- **Drift**, Jett's passive. Holding jump while she falls lets her glide.
- **Sounds.** Ability sounds can be heard by enemies, and show on the minimap's sound circle.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| Tailwind's windup and window | Patch 7.04: the windup up from 0.75 s to 1 s, the window down from 12 s to 7.5 s ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-7-04/), in our words) |
| Updraft's charges | Patch 7.04: from 2 to 1 |
| Blade Storm's points | Patch 7.04: from 7 to 8 |
| Cloudburst's time | Patch 7.04: from 4.5 s to 2.5 s, with a slightly longer re-equip after it |
| What a charge costs | Patch 3.0: Updraft "Cost increased 100 >>> 150", Cloudburst "Cost increased 100 >>> 200" ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/)) |
| Tailwind before 7.04 | Patch 4.08: "Upon pressing E, Jett consumes her Tailwind charge and after a .75 second delay," "activates a 12-second window where she's able to dash on next key press" ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-4-08/)) |
| Tailwind's recharge | The same notes: "Jett's Tailwind charge can still be regained with 2 kills" |
| Ability sounds | Patch 1.0: sounds "that display their audio distance on the mini-map via the white circle. This includes ability sounds" ([patch notes](https://playvalorant.com/news/game-updates/valorant-patch-notes-1-0/); system 8) |

### From the community

| What | Value | Sources |
| --- | --- | --- |
| The keys | C, Q, E and X: "Use/Equip Ability: 3" on C, "1" on Q, "2" on E, "Ultimate" on X; and "Crouch" on "Left Ctrl" | [Shacknews' key bindings](https://www.shacknews.com/article/117434/valorant-pc-controls-and-keybindings) |
| The signature | "All agents have one signature ability that will give them one free charge..." | [The Fandom wiki's Abilities page](https://valorant.fandom.com/wiki/Abilities) |
| Carried over | "Charges that do not get used and did not get regenerated will be carried over to the next round", while "any regenerated charges from cooldowns will not be kept for the next round" | The same page |
| Through a death | "If you die the previous round, you will lose any purchased weapons and armor, but you will keep purchased unused abilities." | [Hotspawn's economy guide](https://www.hotspawn.com/valorant/guide/how-to-manage-the-valorant-economy); [ONE Esports](https://www.oneesports.gg/valorant/valorant-economy-guide-how-to-earn-credits-and-what-to-buy-with-them/): "you keep your abilities even after you die on most agents" |
| Ultimate points | "Every kill you get will get you one Ultimate Point", and the same for "Every death", "Planting the spike", "Defusing the spike" and "Collecting an Ultimate Orb" | [Gfinity](https://www.gfinityesports.com/article/how-to-get-ultimate-points-in-valorant) |
| Cloudburst | 200 credits, 2 charges, 2.5 s; "HOLD the ability key to curve the smoke in the direction of your crosshair"; v3.06: "Charges reduced 3 >>> 2" | [The VALORANT Wiki's Jett page](https://wiki.playvalorant.com/en-us/Jett) |
| Updraft | 150 credits, 1 charge, 0.6 s: "INSTANTLY propel Jett high into the air." | The same page |
| Tailwind | Free; windup 1 s; 7.5 s charged and a 0.45 s dash; "RE-USE the wind to propel Jett in the direction she is moving." "If Jett is standing still, she propels forward." | The same page |
| Tailwind's patch history | v13.01: "Fixed an inconsistency where she could not pick up the Spike or weapons during it"; v5.0: "Fixed a bug where Jett could equip a weapon during the dash"; v2.01: "Can no longer trigger the defuse sound while dashing" | The same page |
| Blade Storm | 8 points; v3.07: "Kunai will now recharge after killing a training dummy or defuse practice bot" | The same page |
| Drift | "Holding the jump button while falling allows you to glide through the air." | The same page |

Nothing public gives the movement as numbers: how far the dash goes, how fast, what speed Jett
keeps after it, how high Updraft throws her, or how it rises. Those are ours, and labelled as
estimates. So is everything about how the kit behaves at the edges: a cast during a plant, a
dash in the air, a lift cut short by a dash.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How far the dash goes | A public video of a dash along a wall or floor of known length (the Range's floor grid): its start and end |
| How the dash's speed runs | The same, frame by frame: steady, or fast at first and easing |
| What's left after the dash | The same: how far she slides after it, against her run |
| How high Updraft throws her | A public video of Updraft beside crates or boxes of known height, the feet at the top |
| How Updraft rises and falls | The same, frame by frame: the rise's speed, the moment it tops out and the fall |
| A dash in the air | A public video of an Updraft and then a dash: whether she keeps her height through it |
| How far ability sounds carry | The minimap's sound circle around a cast in a public video, against the map's scale |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| The keys | C, Q, E and X; crouch is Left Ctrl alone now, as the reference's default is | Community |
| A basic ability's charges | Bought one at a time in the buy phase, up to its most: Updraft 1 for 150, Cloudburst 2 for 200 | Confirmed (prices, Updraft's charge); community (Cloudburst's charges) |
| Selling back | A charge bought this buy phase, for its price, while the buy phase lasts | Estimate |
| Kept charges | Unused charges are kept into the next round and through a death | Community |
| The half and a new match | A new half takes every charge away, but keeps the ultimate's points; a new match takes both | Estimate |
| The signature | Tailwind's charge is free every round: at least 1 as a round starts | Community |
| Tailwind's recharge | Two kills bring it back, counted only while it's spent, and from zero each round | Confirmed (two kills); estimate (when they count) |
| A recharged charge | Taken back as the next round starts, if it wasn't used | Community |
| A dummy's kill | Counts as a kill, for points and for Tailwind | Ours (the wiki's v3.07 note does the same for Blade Storm) |
| Ultimate points | 1 for each kill, death, plant and defuse, up to the 8 Blade Storm needs | Community (each point); confirmed (8); estimate (the cap) |
| Ultimate orbs | None on our maps | Not here |
| Updraft | Q: lifted straight up at once, at a steady speed for 0.6 s (77 ticks), then a fall as from a jump. The feet top out 4 m up, about 0.95 s after the press, and land about 1.7 s after it | Community (0.6 s); estimate (4 m, the rise) |
| Updraft in the air | It works there too, lifting from where you are | Estimate |
| Tailwind's gust | E spends the charge; after a 1 s windup, a 7.5 s window opens. E in the windup does nothing, and the window closes unused with the charge gone | Confirmed (the charge spent on the first E, the windup, the window); estimate (E in the windup) |
| Tailwind's dash | E in the window: the way the keys point, or forward with none, for 0.45 s (58 ticks), 7 m straight and level, at 15.4 m/s | Community (the time, the way); estimate (7 m, level, steady) |
| After the dash | No faster than 6.75 m/s, the run speed with the knife out, as it ends; a slower gun's run speed a moment later | Estimate |
| A dash and a lift | A dash ends a lift and goes level through the air | Estimate |
| In the dash | Nothing fires or casts, the zoom comes off, a burst stops, a weapon switch waits for its end, a plant or a defuse can't start, and no steps are heard. Running over the spike or a gun, or F, still picks it up | Ours; the wiki's patch history (pickups, equipping, the defuse sound) agrees |
| Planting and defusing | Nothing casts while rooted; a plant pressed on the same tick as a dash goes first | Estimate |
| The course | Every charge, and a spent one back 1.5 s after nothing's under way, to practise | Ours |
| Skirmish | Every charge at the start of each life, none back within it | Ours |
| The bar | At the bottom between health and ammo: each slot's key, name, a pip for each charge (points for X), the gust's windup and seconds left, lit while under way | Ours |
| The look | Updraft: a ring of air at the feet and streaks rising. The gust: a ring at the waist through its windup. The dash: a streak along its way for others, a flash at the screen's edges for you | Ours |
| The sounds | Updraft's gust, the dash and the gust readying, from the knife's measured whooshes; heard to a 30 m edge, and not from the other side in the buy phase | Ours; estimate (30 m) |

## 5. Design

### The kit in the simulation

`AbilitySim` is the kit's state and its rules, and it's part of `PlayerSim`. Each tick it reads
the same input as movement and weapons: an ability's key pressed since the last tick casts it, if
it has a charge and nothing stops it. What a cast does to movement comes back as a `Motion`, which
`MovementSim.step` applies:

- **A dash** sets the velocity, level, for the dash's ticks, with no gravity.
- **A lift** takes the player off the ground and sets the speed up, with no gravity and the air's
  control along the ground.
- **A cap** holds the speed along the ground to the run speed with the knife out, on the tick
  after a dash.

The order in a tick is the spike first (a plant or a defuse that starts roots the player, and a
dash keeps one from starting), then the kit, then movement, then weapons, which a dash skips. The
speeds are worked out from the config so the numbers come out exact at 128 ticks a second: the
dash's speed is its distance over its whole ticks, and Updraft's lift is the speed that, held for
its ticks and then left to gravity, tops out at its height. `AbilityConfig` holds every number with
its status and source, as the other configs do.

Because the kit is in `PlayerSim`, the client predicts it and replays it on a correction like any
other move. The ack carries the kit (56 bytes), so a change from the server, a charge bought or a
point from a kill, reaches the owner's prediction. The input's buttons use all 16 of their bits
now, the top four for the keys. A new life keeps the last one's kit, with nothing under way, on
both ends.

### The server

- `AbilityServer` changes kits between ticks. In the spike rounds (`economy` on), the arena tells
  it each round's kind: a new match's first round starts everyone on a new kit, a half's takes
  away what was bought, and every round takes back the recharged charges and gives Tailwind its
  free one. On the course and in Skirmish, every life starts with every charge, and on the course
  (`refill` on) a spent charge comes back 1.5 s after nothing's under way.
- Points come from `CombatServer.killListeners` (a kill by someone else, a dummy's too),
  `PlayerSimServer.deathListeners` and `SpikeServer.objectiveListeners` (the plant and the
  defuse).
- Each cast goes to every client on the `Ability` remote: who, what, when in server time, where
  their feet were and which way.
- `ShopServer` sells charges as items of their own kind: a buy goes into the kit if it has room
  and the credits are there, and a charge bought this buy phase sells back for its price.
  `VFBoughtCharges` lists them for the buy menu.
- Each kit is its player's `VFKit` attribute, as `C0/2 Q1/1 E1/1 X0/8`, with what's under way after
  it. Scripted checks read it.

### The client

- `InputSampler` puts the four keys on their buttons. Crouch is Left Ctrl alone.
- `AbilityHud` draws the bar from the predicted kit, so a cast shows the tick it's pressed.
- `AbilityEffects` shows your own casts at once, from `PlayerController.castListeners`, and
  others' from the `Ability` remote when the frame on your screen reaches them, so they line up
  with where the caster is drawn. One more than a second late is dropped.
- `GameSounds.playCast` plays yours on the Self bus and others' where they were cast. A dash
  makes no steps, and a lift no jump sound.
- `BuyMenu` has an "Abilities" group under the shields: a tile for each ability sold by the
  charge, with a pip for each charge it holds. One that can't be played yet shows `NOT YET`, and a
  full one `FULL`.

### Not here yet

- **Blade Storm.** In the bar, dimmed: it can't be cast. Like most of the reference's abilities
  it's equipped first and then used with the fire buttons, which needs an equipped state between
  the kit and the weapons. Cloudburst, thrown at once, came in system 18, and Blade Storm, as a
  weapon in a fifth slot, in system 19.
- **Drift**, Jett's glide, which came in system 20 ([20-drift.md](20-drift.md)).
- **Other agents and an agent select.** Everyone is Jett.
- **Cooldown recharges.** The config can hold one, but no ability uses it yet.
- **Ultimate orbs**, and the points they give.
- **What clients are told.** `VFKit` and `VFBoughtCharges` are attributes every client can read,
  as with system 16's record, so a client can read the other side's kits. The reference would
  tell it less.
- **Assists from abilities** (Patch 12.05). None of these give one.
- **The minimap's sound circle.** There's no minimap.
- **The ultimate on the scoreboard** (system 16), where the reference shows each player's.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | The kit's slots and keys, ultimate points, each ability's numbers, the agents, Jett's movement |
| `src/shared/Abilities/AbilitySim.luau` | The kit: charges, rounds, halves, points, kills, buying, and the casts tick by tick |
| `src/shared/Movement/MovementSim.luau` | The ability buttons, and `Motion`: dash, lift and cap |
| `src/shared/PlayerSim.luau` | The kit in the state and in each tick, after the spike and before movement |
| `src/shared/Net/PlayerCodec.luau` | 16-bit buttons, and the kit in the ack |
| `src/shared/Net/Remotes.luau` | `Ability`: casts to every client |
| `src/shared/Weapons/Shop.luau` | Charges as items: their price, refunds this buy phase, `VFBoughtCharges` |
| `src/shared/Audio/SoundConfig.luau` | The casts' sounds and their distance curve |
| `src/server/AbilityServer.luau` | Kits by round and life, the course's refill, buying, points, casts out, `VFKit` |
| `src/server/PlayerSimServer.luau` | `castListeners`, the kit kept across lives, a dash's quiet steps |
| `src/server/CombatServer.luau` | `killListeners` |
| `src/server/SpikeServer.luau` | `objectiveListeners`: the plant and the defuse |
| `src/server/ShopServer.luau` | Charges bought and sold |
| `src/server/Arena.luau` | Each round's kind, and the kit's mode by what's played |
| `src/client/InputSampler.luau` | C, Q, E and X; crouch on Ctrl alone |
| `src/client/PlayerController.luau` | `castListeners`, the kit compared on a correction and kept across lives |
| `src/client/AbilityHud.luau` | The ability bar |
| `src/client/AbilityEffects.luau` | The casts' look, yours at once and others' when they're drawn |
| `src/client/Audio/GameSounds.luau` | `playCast`; no steps in a dash, no jump sound for a lift |
| `src/client/BuyMenu.luau` | The abilities group |
| `src/client/Debug/TestAim.luau` | The ability keys in `VFTestButtons` |
| `src/shared/Movement/JumpAnalyzer.luau`, `src/client/Debug/DebugHud.luau` | How high the feet rose, on the HUD's jump line (F3) |
| `tests/abilities.luau` | 87 checks: the config and its labels, the kit's rules through rounds, halves, kills and deaths, motion in movement, Updraft's height and time, Tailwind's windup, window, dash and its way, what a dash stops, planting, the wire and replays, the shop's charges |

## 7. Debug tools

- Select a player under Players in the Explorer: their kit is the `VFKit` attribute, as
  `C0/2 Q1/1 E1/1 X0/8`, with `lift` or `dash`, and `windup` or `ready`, after it while one's
  under way.
- `VFTestButtons` holds the keys without the keyboard: 4096 is C, 8192 Q, 16384 E and 32768 X.
  Clear it to let go: a key casts on its press, not while held.
- `VFTestBuy` set to `updraft` buys a charge as a click in the menu does, and `-updraft` sells it
  back.
- The bar's E slot shows `WINDUP` and then the window's seconds left.
- The HUD (F3) measures each time in the air: its jump line now shows how high the feet rose,
  so an Updraft reads its height and its time in the air.
- On the course a spent charge comes back 1.5 s after nothing's under way, so a cast can be tried
  again and again.

## 8. Refinement loop

1. Find a public video of Tailwind's dash along the Range's floor grid, and one of Updraft beside
   boxes of known height.
2. Measure the dash's distance and how its speed runs, and set `AbilityConfig.Jett.dashDistance`;
   measure the slide after it and set `dashExit`.
3. Measure the feet's height at Updraft's top and when it comes, and set `updraftApex`. If the
   rise isn't steady, change `AbilitySim.liftSpeed`'s profile and its test.
4. Play both on the course against the video, a few casts each, and adjust.

## Known gaps to check in Studio

- The bar shows the kit as the tests have it, and lights and counts down as casts go.
- Updraft throws you about 4 m up from the ground and from the air, and you land as from a jump.
- Tailwind's windup, its window and its dash, the way you're moving or forward, about 7 m, and
  no faster than a run after it.
- Nothing fires during a dash, the zoom comes off, and a dash ends a lift.
- Nothing casts while planting, and a plant doesn't start in a dash.
- Another player sees and hears each cast where you are on their screen.
- The spike rounds' kit: charges bought and sold back, kept through a death, and the ultimate's
  points.

Section 21 of the [Studio checklist](../studio-checklist.md) covers these.
