# System 19: Blade Storm

Jett's Blade Storm is her ultimate. In the reference, X with its points full puts five throwing
knives in her hand. Fire throws one, exactly where she aims, and a kill with it brings all five
back. Alt fire throws every knife she has left at once, a spread that's meant for close range,
and its kills bring none back. She can draw her guns and use her other abilities while it lasts,
and X draws the knives again. Once they're all thrown with no kill to refill them, it's over.

This system adds it on top of system 17's kit, where Blade Storm was on the bar but couldn't be
cast. It's the kit's first ability that's a weapon. The knives are a weapon of their own in a
fifth slot while the ultimate lasts, so throwing them, hitting with them, their sounds and the
HUD all go through what guns already do: the same ticks, the same lag compensation, the same
server verdicts.

As before, everything comes from Riot's patch notes and from community wikis and forums. No game
files, memory, network traffic or protected assets were used, and nothing reads the game while it
runs. The knives' look is ours, and their sounds are recordings from the Creator Store's free
library, as system 17's are. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

## 1. Observable behaviour

- **The cast.** X, once the ultimate's 8 points are full. Jett winds up for about a second and the
  knives come into her hand. The points are spent.
- **One at a time.** Fire throws a single knife. It's hitscan, so it lands the moment it's thrown,
  and it goes exactly where the crosshair is, whether she's standing, running or in the air.
- **A kill brings them back.** A kill with a single knife puts all five back in her hand. That
  includes the Range's training dummies.
- **All at once.** Alt fire throws every knife she has left in one go, which can miss: it's a
  spread. Its kills don't bring them back.
- **The knives run out.** With none left, they're put away a moment after the last throw, and her
  gun comes back.
- **Guns and abilities.** She can switch to a gun, and use her other abilities, without ending
  Blade Storm. X draws the knives again.
- **The HUD.** The ammo count shows the knives left.
- **Sounds.** The cast, and each throw.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| The points | Patch 7.04: Blade Storm's ultimate points up from 7 to 8 ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-7-04/); system 17) |
| The burst's rate | Patch 1.09: "The time between consecutive Burst Fire use has increased from 0.33 seconds >>> 0.45 seconds" ([patch notes](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-1-09/)) |
| What the burst was for | Patch 1.09's developer note: "The burst fire is intended to be a close range attack, but we found it frequently getting frags at over 20 meters away." The same patch gave the burst a damage falloff and a 2x headshot multiplier |
| The burst's kills | Patch 3.06: "Right-click/Alternate Fire kills no longer recharge Jett's kunai", so that players "optimize for the single kunai kills in order to keep the Bladestorm going" ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-06/)) |
| The burst's damage | Patch 3.06: "Right-click/Alt. Fire damage changes are reverted, damage and multipliers will mirror the left-click", which undoes 1.09's falloff and headshot change |

### From the community

| What | Value | Sources |
| --- | --- | --- |
| The ability | Equip "a set of highly accurate throwing knives". Fire throws one and recharges them on a kill; alt fire throws all that remain, and doesn't | [The VALORANT Wiki's Blade Storm page](https://wiki.playvalorant.com/en-us/Blade_Storm), in our words |
| Hitscan | "On cast, she winds up and equips herself with hitscan throwing knives" | The same page |
| Guns and abilities | "Jett can use other abilities and weapons without deactivating Blade Storm", and "she can re-use the ability to reequip the knives" | The same page |
| The knives | 5 | The same page; the [Fandom wiki's Jett page](https://valorant.fandom.com/wiki/Jett): "Equip a set of 5 highly accurate throwing knives" |
| Its times | "Initial windup time" 1.02 s, "Reequip time" 0.5 s, "Quick equip time" 0.15 s | The VALORANT Wiki's Blade Storm page |
| Single throws | 6 a second, one every 0.167 s, timed by the wiki's editors rather than published; "has 100% accuracy at all times (even when Jett is running or in the air)" | The same page |
| The burst | "throws all of Blade Storm's remaining knives, though this can be inaccurate" | The same page |
| Damage | 50 a knife on the Range's bot, the head 3x and the legs 0.85x; the wiki's Jett page rounds them to "150 Head, 50 Body, 42 Legs" | The same page; [the VALORANT Wiki's Jett page](https://wiki.playvalorant.com/en-us/Jett) |
| Time to kill | 100 HP: one to the head or two to the body; 125 HP: three to the body or the legs; 150 HP: three to the body or four to the legs | The VALORANT Wiki's Blade Storm page |
| Running out | Put away 0.167 s after the last single throw, 0.45 s after a burst | The same page |
| Its history | v1.02 refreshes on killing Phoenix during Run It Back; v3.0 points 6 to 7; v3.07 "Kunai will now recharge after killing a training dummy or defuse practice bot"; v4.07 can be input-queued to equip after the current action; v4.08 the ammo count added to the HUD, and a fix for Tailwind straight after the knives ran out; v5.03 "legshot multiplier reduced from 1.0 >>> 0.85"; v7.10 third-person animations adjusted | The same page and the wiki's Jett page; [ONE Esports](https://www.oneesports.gg/valorant/valorant-patch-5-03-damage-multiplier) on 5.03 |
| Through walls | A clip of a knife kill through a wall, its poster asking "I thought this wasn't possible?", and others doubting it was one | [vlr.gg](https://www.vlr.gg/473053/wallbang-jett-knife-kill) |

Nothing public gives how wide the burst's spread is, whether holding fire throws on, how fast she
runs with the knives, what the 0.15 s "quick equip" is for, or what a death or the round's end
does to Blade Storm. Those are ours, and labelled as estimates.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| The burst's spread | A public video of a burst at a wall from a known distance in the Range: the marks against the wall's grid |
| Single throws' rate | Frame-count a clip of throws clicked as fast as possible, against 0.167 s |
| Holding fire | A video with its inputs shown, where fire is held after a throw |
| The run speed | A run with the knives out along the Range's floor grid, against the knife's 6.75 m/s |
| The windup and the re-equip | Frames from the cast, or from X again, to the first knife that can be thrown |
| Running out | Frames from the last knife, or from the burst, to the gun back in hand |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| The cast | X with all 8 points spends them and puts five knives in hand, from the fifth slot, ready 1.02 s later; held, X casts once | Confirmed (8); community (5, 1.02 s) |
| One at a time | Fire throws one, hitscan, exactly where the crosshair is (standing, moving, in the air or landing), at most six a second; a knife a click | Community (6 a second, exact); estimate (a click a knife) |
| All at once | Alt fire throws every knife left as one volley, inside a 2° cone whatever she's doing; nothing more for 0.45 s | Confirmed (0.45 s); community (every knife left, it can miss); estimate (2°) |
| Damage | 50 a knife to the body, 150 to the head and 42.5 to the legs, at any range; the burst's the same | Confirmed (the burst's the same); community (50, the multipliers) |
| Walls | A knife stops at the first wall | Estimate |
| A kill brings them back | A kill with a single knife, a dummy's too, fills all five again, even with a gun in hand; the burst's kills and a gun's don't | Confirmed (the burst's don't); community (a single knife's, dummies) |
| A kill's point | A kill with a knife is an ultimate point, as any kill is, towards the next Blade Storm | Estimate |
| Running out | Put away 0.167 s after the last single throw, 0.45 s after a burst, or at once if a gun's in hand; the hand goes back to the gun they came from, or the first slot that holds something | Community (0.167 s, 0.45 s); estimate (the rest) |
| Guns and abilities | A number key draws a gun and the knives are kept; X draws them again, ready 0.5 s later; Cloudburst puts them away for its 0.25 s, as it does a gun; nothing's thrown in a dash | Community (all of it, and 0.5 s); estimate (Cloudburst's and the dash's rules, which are system 17's and 18's) |
| What ends it | All thrown with no kill to bring them back, a death, a new round, and a new kit (the arena starting or stopping) | Community (thrown); estimate (the rest) |
| Run speed | The knife's 6.75 m/s | Estimate |
| The course | Every life starts with the points full, they fill again 1.5 s after it ends, and a spent charge still comes back in it | Ours |
| The HUD | The ammo box shows the knives left, on `[X]`; X's square is outlined with `x` and the knives left; the bar under the crosshair fills over the windup | Community (the ammo count, v4.08); ours (the rest) |
| The sounds | The cast a knife's draw, slowed; each throw a quick, thin swish heard to system 17's 30 m edge; a body hit the knife's blade going in | Ours; estimate (30 m) |

## 5. Design

### The cast

`AbilitySim` casts it as it does the others: X pressed since the last tick, with nothing in the
way (a dash, a plant or a defuse), and the points full (`AbilitySim.charged`). The cast is a
`storm`: the points go to 0 and the kit's `storm` is set, which the summary shows. X while it lasts
is a `draw` instead, which the server keeps to itself.

### The knives

They're `WeaponConfig`'s `kunai`, a weapon of the new `ultimate` category in a fifth slot
(`WeaponSim.ULT`). On `storm`, `PlayerSim` has `WeaponSim.arm` put them in that slot with all five
and take them in hand, ready once the windup's 1.02 s are up. From there they're a gun as far as
the rest of the code goes:

- **One at a time** is the hip mode: semi-automatic at 6 a second, with no firing error, no
  movement error, no recoil and its own landing penalty of 0 (an accuracy can now have its own,
  in place of `WeaponConfig.Accuracy`'s).
- **All at once** is the alt mode, like the Classic's right click: one round that takes all five
  knives, so with fewer left it throws as many as there are, in a 2° cone, and nothing can follow
  for 0.45 s.
- **No reload.** Their reserve is 0.
- **Damage** is one band, 50, 150 and 42.5, whatever the range. The volley is one hit, as a
  shotgun's is.
- **The server's verdict** comes as a gun's does, through `CombatServer` with lag compensation.
- **Never bought, given or dropped.** `Shop` doesn't sell them, `PlayerSimServer.give` won't give
  them, and G only lets go of a primary or a sidearm.

### Swapping

A gun drawn with a number key keeps the knives in their slot, and X draws them again with
`WeaponSim.takeUp`: the re-equip's 0.5 s. `WeaponSim` remembers where they came from (`back`), to
give the hand back to when they're gone.

The input's `slot` says which slot the client wants in hand, every tick. The knives come into hand
without it asking, so on the tick they do, the input still names the gun. `WeaponSim` keeps the
slot the input was asking for (`hold`), and until the input asks for something else, that slot
doesn't take the knives out of hand. `PlayerController` asks for the fifth slot from the next tick
on, which clears it.

### What brings them back, and what ends them

- **A kill.** `CombatServer` tells `killListeners` the weapon and the mode it fired in. A kill
  with the knives' hip mode refills all five (`PlayerSim.killedWith`), which the ack takes to the
  thrower. Kills are run on the tick the knife was thrown, so a kill with the last one refills them
  before they're put away.
- **Running out.** With none left, `WeaponSim.step` puts them away once the last throw's time is up
  (0.167 s, or the burst's 0.45 s), or at once if a gun is in hand, and draws the gun they came
  from.
- **Its end.** `PlayerSim` ends Blade Storm when the knives are gone, and puts them away when it has
  ended some other way: the server ends it with everything else under way, at a death, a new
  round or a new kit. No life starts with them.

### The server

- `AbilityServer` applies each kill to the killer's simulation through `PlayerSim.killedWith`,
  which is the kit's point and the signature's count as before, and now the knives.
- On the course, every life starts with the ultimate's points full, and when Blade Storm is over
  they fill again after the course's 1.5 s, so it can be practised over and over. The other
  charges still come back in it.
- `draw` casts aren't told to clients: others see the knives in hand.

### The client

- `PlayerController` asks for the fifth slot as the knives come into hand, and goes on asking for
  it when they go, so a kill with the last knife the server has heard and this client hasn't yet
  doesn't send the gun's slot and put them away on the server. Its mismatch check covers `back`,
  `hold` and `storm`.
- `CombatHud` shows the knives left, on `[X]`, and its bar fills over the windup as well as the
  re-equip.
- `AbilityHud` outlines X while Blade Storm lasts, with the knives left as its note.
- `WeaponLooks` has their look: three thin pale blue blades held fanned out. In hand, a throw
  snaps them forward, with no flash and no kick.
- `WeaponEffects` draws each knife's streak, a little wider and longer lasting than a tracer, from
  your hand on your screen and from the thrower's eye on others'.
- `AbilityEffects` shows others' casts as five blades circling them through the windup, and plays
  the cast's sound.

### Not here yet

- **The quick equip.** The wiki's 0.15 s "quick equip time" isn't used: nothing says when it
  applies.
- **Input queueing.** X during a reload or a draw casts at once, as any switch would, rather than
  waiting for it to finish (v4.07's queueing).
- **The knives in others' hands.** Others are drawn as their hitboxes, holding nothing.
- **Run It Back.** There's no Phoenix yet.
- **Drift**, Jett's glide, came next, in system 20 ([20-drift.md](20-drift.md)).

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | `BladeStorm.windup`, and the ultimate's `weapon` |
| `src/shared/Abilities/AbilitySim.luau` | The `storm` and `draw` casts, `storm` under way, `charged`; the course's `fill` and `full` with the ultimate |
| `src/shared/Weapons/WeaponConfig.luau` | The `kunai`: five knives, their damage, the exact throw and the burst; the `ultimate` category |
| `src/shared/Weapons/Accuracy.luau` | An accuracy's own landing penalty |
| `src/shared/Weapons/WeaponSim.luau` | The fifth slot: `arm`, `takeUp`, `refill`, `putAway`, `back` and `hold` |
| `src/shared/PlayerSim.luau` | The casts put the knives in hand; Blade Storm and its knives end together; `killedWith` |
| `src/shared/Net/PlayerCodec.luau` | Slot 5 in inputs; `back`, `hold` and `storm` in the ack |
| `src/shared/Weapons/Shop.luau` | Never on sale |
| `src/shared/Audio/SoundConfig.luau` | The cast's, the throws' and the hits' sounds |
| `src/server/CombatServer.luau` | `killListeners` told the weapon and the mode |
| `src/server/AbilityServer.luau` | Kills through `killedWith`; the course's ultimate; `draw` kept back |
| `src/server/PlayerSimServer.luau` | Never given |
| `src/client/PlayerController.luau` | The fifth slot asked for, and the mismatch check |
| `src/client/AbilityHud.luau` | X outlined, with the knives left |
| `src/client/Combat/CombatHud.luau` | The knives' count on `[X]`, and the windup's bar |
| `src/client/Combat/WeaponLooks.luau` | The knives' look |
| `src/client/Combat/WeaponEffects.luau` | The throw's snap and the knives' streaks |
| `src/client/AbilityEffects.luau` | Others' casts |
| `tests/bladestorm.luau` | 76 checks: the numbers and their labels, the cast and its points, the windup, single throws (exact, a click a knife, six a second), running out and the gun back, the burst, kills that do and don't bring them back, a kill heard late, the input's slot, swapping and X again, Cloudburst, Tailwind and Updraft with them out, what ends it, the course, and the wire |

## 7. Debug tools

- Each player's `VFKit` reads `storm` after the points while Blade Storm lasts, as
  `C2/2 Q1/1 E1/1 X0/8 storm`.
- The HUD's ammo box reads the knives left, and `Blade Storm   [X]` under it.
- `VFTestButtons` 32768 presses X, 128 throws one and 256 throws all; set it and clear it again for
  each. `VFTestAimEntity` and `VFTestAimRegion` aim at a dummy's head, body or legs.
- On the course the points are full at every spawn and fill again 1.5 s after Blade Storm ends.
- The Sound Lab logs `storm`, `kunai` and `kunaiHit`.

## 8. Refinement loop

1. Find a public video of a burst at a wall in the Range, from a known distance, and set the
   burst's firing error (`kunaiSpread` in `WeaponConfig`) to the marks' spread.
2. Frame-count single throws clicked as fast as possible, and check 0.167 s.
3. Find whether holding fire throws on, and make the hip mode automatic if it does.
4. Time a run with the knives out along the floor grid, and set the `kunai`'s `moveMultiplier`.
5. Throw on the course against the videos and adjust.

## Known gaps to check in Studio

- With its points full, X casts it: the knives come up over about a second, and the HUD shows 5.
- A click throws one, straight to the crosshair standing, running or in the air.
- Three to the body or one to the head kills a dummy, and the kill brings all five back.
- Alt fire throws all that are left, spread round the crosshair, and its kills bring none back.
- A knife stops at the first wall it meets.
- They're gone a sixth of a second after the last, or half a second after a burst, and the gun
  comes back.
- A number key draws a gun with the knives kept, and X draws them again in half a second.
- Cloudburst, Updraft and Tailwind work with the knives out.
- On the course the points fill again once it's over.
- The cast, the throws and a body hit are heard.
- Another player sees your cast and your knives' streaks, and hears both.
- A death ends it.

Section 23 of the [Studio checklist](../studio-checklist.md) covers these.
