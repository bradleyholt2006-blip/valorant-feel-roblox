# System 3: Spread and recoil

This covers where a bullet goes once the trigger has fired it: the cone of fire ("firing error"),
how it grows over a spray and recovers between shots (Gun Recovery Time and tap efficiency), the
extra error for moving, jumping and landing, what crouching and aiming down sights do, where in
the cone a bullet lands ("error power"), the recoil climb and sideways drift, and how much of the
recoil the camera shows. Firing itself (fire rate, ammo, scopes) is system 2. Rewinding targets to
what the shooter saw is system 4 (`docs/research/04-hit-registration.md`).

As before, everything comes from public patch notes, developer statements, community wikis and
footage. No game files, memory or protected assets were used. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public statement) or shown directly in-game |
| **Community** | Published by a wiki, stat site or guide, not by Riot |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |

Weapons: Vandal, Phantom, Operator, Classic and Sheriff (the knife never fires).

## 1. Observable behaviour

- The first bullet doesn't always land exactly on the crosshair. Each weapon has a small random
  first-shot spread. Snipers have none while scoped; an unscoped Operator is wildly inaccurate.
- Holding the trigger, the first few bullets stay tight, then the spread grows over the spray and
  levels off.
- Pausing between shots keeps them accurate. Each weapon has a recovery time; fire again sooner and
  the spray carries on, wait part of it and part of the spray is forgiven.
- Moving while shooting adds spread: crouch-walking a little, walking more, running a lot, and
  being in the air the most. For a moment after landing from a jump every weapon is inaccurate.
- Crouching tightens spread; aiming down sights (ADS) tightens it too. Crouched and zoomed, rifle
  first shots are as good as perfect.
- Recoil: a spray always climbs, then levels off and drifts left and right, which together look
  like a "T". The first several bullets go to the same place every spray; deeper in, the drift is
  different every time.
- In hip fire the crosshair doesn't follow the bullets: the view kicks a little and the bullets
  climb away from the crosshair. ADS keeps the bullets on the sight and moves the screen more.
- Running makes the climb steeper. Crouching while still shrinks the sideways drift.
- A running player who gets hit and slowed by a tag should not suddenly become accurate.

## 2. Publicly documented details

How it works (Riot):

| Fact | Status | Source |
| --- | --- | --- |
| "Each weapon has a base spread (deviation from the center) value." "ADS provides a flat spread reduction, while crouch provides a percentage reduction." Zoomed and crouched, rifles have no first-shot deviation "at pretty much any range" | Confirmed (developer statement) | Riot's lead gameplay designer, quoted by [Sportskeeda, Jul 2020](https://www.sportskeeda.com/esports/valorant-how-rng-first-shot-accuracy-can-ruin-competitive-integrity-game) |
| Firing error "is a curve that has intermediate values between each bullet" | Confirmed | [Patch 0.50](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-0-50/) (Ares note) |
| "Inaccuracy is accrued any time the weapon is re-fired prior to a complete duration of a weapon's respective Gun Recovery Time." Tap efficiency "determines the rate that inaccuracy is accrued"; "the higher the Tap Efficiency, the lower the rate of inaccuracy accrual" | Confirmed | Patch 0.50 |
| Vandal recovery 0.4 → 0.375 s, tap efficiency 4 → 6; Phantom recovery 0.55 → 0.35 s, tap efficiency 3 → 4 | Confirmed | Patch 0.50 |
| No "walking accuracy" state while slowing from a run to a stop | Confirmed | Patch 0.50 |
| Deadzone 25% → 30% (0.50), then "Weapon Deadzones changed from 30% >>> 27.5%" for all weapons | Confirmed | Patch 0.50; [Patch 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/) |
| Tagging 75% → 72.5% slow, together with the tighter deadzone, against "tag into accuracy": a running player hit and slowed "enough to make their bullets more accurate" | Confirmed | Patch 3.0 |
| Jump landing: "binary", 0.225 s, value 7.0, all weapons | Confirmed | [Patch 1.09](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-09) |
| Error power, "also known as Center Biasing", biases shots "toward the center of the crosshair" and works "as intended for stationary firing"; shots fired while moving "are now almost uniformly random within their spread cone" | Confirmed | [Patch 6.11](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-6-11/) |
| Vertical recoil multiplier while running: Vandal, Phantom, Spectre 1.5 → 1.8; Frenzy 1.25 → 1.5 | Confirmed | Patch 6.11 |
| Vandal: "Horizontal (Yaw) Recoil reduced by 15% while crouched and stationary", which "matches the crouch benefits of other rifles" | Confirmed | Patch 0.50 |
| Ares and Odin: changes to yaw recoil "after the first 8 bullets" | Confirmed (those weapons) | Patch 0.50 |
| "The first several bullets have fully deterministic recoil, deeper into the spray, your weapon will make pseudo-random deviations" | Community (attributed to Riot_Classick; original post not found) | [turbosmurfs.gg](https://turbosmurfs.gg/article/how-to-improve-aim-in-valorant) |

Numbers:

| Fact | Value | Status | Source |
| --- | --- | --- | --- |
| Rifle movement error | walk 0.6 → 0.8 (0.50); run 3.75 → 5.0, walk 0.8 → 1.1, crouch-walk 0.3 → 0.8 (2.02); walk 1.3 → 2.0 (3.0); walk 2 → 3, run 5 → 6 (9.10) | Confirmed | Patches 0.50, [2.02](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-2-02/), 3.0; 9.10 as quoted by [esports.gg](https://esports.gg/news/valorant/valorant-9-10-patch/) and [Sportskeeda](https://www.sportskeeda.com/valorant/new-valorant-regen-shield-weapon-changes-explained) |
| Classic movement error | walk 0.25 → 0.84, run 1.5 → 2.1 (3.0); walk 0.84 → 1.1, run 2 → 2.3 (9.10) | Confirmed | Patches 3.0, 9.10 |
| Sheriff movement error | walk 0.25 → 1.2, run 2.0 → 3.0 | Confirmed | Patch 3.0 (9.10 didn't list the Sheriff) |
| Pistol crouch-walk error | 0.1 → 0.5 (all pistols but the Shorty) | Confirmed | Patch 9.10 |
| First-shot spread | Vandal 0.25°, Phantom 0.20°, Operator 5°, Classic 0.4°, Sheriff 0.25° | Community | metabot ([Vandal](https://metabot.gg/en/valorant/weapon/vandal/overview), [Phantom](https://metabot.gg/en/valorant/weapon/phantom/overview), [Operator](https://metabot.gg/en/valorant/weapon/operator/overview), [Classic](https://metabot.gg/en/valorant/weapon/classic/overview), [Sheriff](https://metabot.gg/en/valorant/weapon/sheriff/overview)) |
| ADS first-shot spread | Vandal 0.157°, Phantom 0.11° (in 2020) | Community | Sportskeeda, Jul 2020 |
| No first-shot spread scoped | Operator (and Guardian, Marshal, Outlaw) | Community | [Fandom, Weapons](https://valorant.fandom.com/wiki/Weapons) |
| Movement penalties add on top; crouch-walk < walk < run < airborne; shared by weapon class | — | Community | Fandom, Weapons |
| Crouched first shot | 0.17° against 0.2° standing (Phantom) | Community | [gamer.org](https://www.gamer.org/valorant-gun-mechanics-explained-accuracy-spray-movement/) |
| Spray shape | always up, a "T", horizontal direction random and can switch; ADS "keeps shots on target" and "amplifies screen movement" | Community | [esports.net](https://www.esports.net/wiki/guides/how-to-spray-valorant/) |
| Error growth | "around the fourth or fifth bullet, the inaccuracy spikes" | Community | gamer.org |

**Not found publicly:** the firing error curves after bullet 1, the recoil curves, the size and
rhythm of the sideways drift, airborne error, recovery and tap efficiency for pistols and the
Operator, the error power values, how much of the recoil the camera shows, how much ADS reduces
recoil, and the exact shape of recovery between "just fired" and "fully recovered". We also read
the error values as the cone's radius (half-angle) in degrees; Riot never says. All of those are
estimates below.

## 3. What can be measured, and how

All of it can be measured in The Range from your own footage. Shoot at a flat wall from a marked
distance (10 m is a good default), record at 120 fps or more, and convert a distance on screen
to an angle with the field of view: for an offset of `x` pixels on a `W`-pixel-wide frame,
`angle = atan(2x / W * tan(103° / 2))` (with a zoom `z`, divide `tan(103° / 2)` by `z`). Or
measure impact marks on the wall: `angle = atan(offset / distance)`.

| Measurement | Method | Gives us |
| --- | --- | --- |
| First-shot cone | 30+ single taps with a full second between them, crosshair on a fixed spot; the radius that holds all but the odd one | `firingError` at bullet 1 |
| ADS and crouch | The same aiming down sights, crouched, and both | `ads.accuracy.firingError`, `crouchMultiplier` |
| Spray pattern | A full spray at the wall with the mouse untouched, 5+ times; average position of each bullet is the recoil path, the scatter around it the firing error | `recoil.pitch`, `swayStart`, `swayStep`, `swayMax`, `swayFlipChance`, `firingError` |
| Recovery | Pairs of taps with a growing gap (0.1, 0.15, 0.2 ... s, from a metronome or frame counting); the gap at which the second bullet is always as tight as the first | `recoveryTime`, `tapEfficiency` |
| Movement error | Shots while walking, running, crouch-walking and in the air; the game's "Show movement error" and "firing error" crosshair options draw the error as the lines spread | `walkError`, `runError`, `crouchMoveError`, `airError` |
| Landing | Shots on the frame of landing and 0.1, 0.2, 0.25 s after | `landError`, `jumpLandPenaltyTime` |
| Centre bias | Of 50+ first shots, the share inside half the cone's radius: 25% if spread evenly (power 0.5), 50% at power 1, 71% at power 2 | `errorPower` (standing), `moveErrorPower` (moving) |
| Camera share | Spray in hip fire and compare how far the crosshair moved on screen with how far the impacts climbed | `cameraFraction`, `adsCameraFraction` |

Enter results in `src/client/Debug/ReferenceData.luau`: `firstShotError` (degrees) and
`sprayPattern` (each bullet's `{right, up}` in degrees, bullet 1 first). The spray lab draws the
reference spray over ours.

## 4. Confirmed vs estimated, as implemented

All values live in `src/shared/Weapons/WeaponConfig.luau` (`accuracy`, `recoil` and
`WeaponConfig.Accuracy`), each with its status and source.

| Parameter | Value | Status |
| --- | --- | --- |
| Deadzone | 27.5% of run speed (Operator 15%) | Confirmed |
| Recovery time, tap efficiency | Vandal 0.375 s, 6; Phantom 0.35 s, 4; Outlaw 0.15 s | Confirmed |
| Recovery counts from when the gun can fire again | So a held trigger never recovers, and the Outlaw's 0.15 s means something | Estimate (the patch notes don't say where it counts from) |
| Rifle movement error | run 6, walk 3, crouch-walk 0.8 | Confirmed |
| Classic movement error | run 2.3, walk 1.1, crouch-walk 0.5 | Confirmed |
| Sheriff movement error | run 3.0, walk 1.2, crouch-walk 0.5 | Confirmed |
| Jump landing | +7 for 0.225 s | Confirmed |
| Running climb | x1.8 Vandal and Phantom | Confirmed |
| Crouched, still sideways recoil | x0.85 Vandal (Phantom by the same statement) | Confirmed |
| First-shot spread | 0.25 / 0.20 / 5 (0 scoped) / 0.4 / 0.25° (Vandal / Phantom / Operator / Classic / Sheriff); every other gun in [09-arsenal](09-arsenal.md) | Community |
| The most the cone grows to | Vandal 1.0°, Phantom 0.9°, Classic 1.8°, Sheriff 2.75° | Community |
| Zoomed | Its own curve for each gun, from the wiki's zoomed first shot and maximum: Vandal 0.157 to 1.02°, Phantom 0.11 to 0.91°; scoped snipers 0 | Community |
| Crouch multiplier | Rifles, SMGs and shotguns x0.85, pistols x0.75, snipers x0.9, machine guns x0.6 | Community |
| Firing error between bullet 1 and the maximum | Our shape: tight for 3 bullets, a jump at bullets 4 and 5, then levelling off; rifles reach the maximum at bullet 25 | Estimate |
| Recoil climb | Vandal to 6.4°, Phantom to 5.5°, levelling off by bullet 16 | Estimate |
| Sideways drift | From bullet 7 (Vandal) and 9 (Phantom), the bullets before it "protected"; a 10% chance a bullet to reverse | Community (Patch 11.08 in the wiki's history) |
| Drift size | 0.55 / 0.45° a bullet, up to 2.6 / 2.2° | Estimate |
| Airborne error | Rifles, SMGs and machine guns 10, pistols 7, shotguns 4, Marshal and Outlaw 20, Operator 15 | Community |
| Sniper movement error | Run 15, walk 10, crouch-walk 7.5 | Community |
| Pistol recovery | Classic 0.3 s / 2, Sheriff 0.25 s / 1.5 (after it can fire again) | Estimate |
| Error power | 1.0 standing, 0.6 moving | Estimate (direction confirmed) |
| Camera share of recoil | hip 0.25, ADS 0.9 (rifles) | Estimate |
| ADS recoil multiplier | 0.9 | Estimate |

What the simulation produces (from `luau tests/run.luau`), standing still:

| Vandal bullet | 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 | 12 | 16 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Cone radius (°) | 0.25 | 0.26 | 0.27 | 0.37 | 0.50 | 0.58 | 0.70 | 0.81 | 0.85 | 0.93 |
| Climb (°) | 0 | 0.3 | 0.8 | 1.4 | 2.1 | 2.8 | 4.0 | 4.9 | 5.6 | 6.1 |

| Tapping, where the 10th tap lands | every 0.15 s | 0.20 s | 0.25 s | 0.30 s | 0.40 s |
| --- | --- | --- | --- | --- | --- |
| Vandal | bullet 1.84 (0.26°) | 1.18 (0.25°) | 1.05 | 1.01 | 1.00 |
| Phantom | 1.95 (0.21°) | 1.27 (0.20°) | 1.10 | 1.03 | 1.00 |
| Classic | 10 (fire rate, 1.80°) | 2.95 (1.46°) | 1.77 (0.79°) | 1.34 (0.43°) | 1.03 |
| Sheriff | 6 (fire rate, 2.75°) | 6 | 6 | 3.16 (2.58°) | 1.35 (0.57°) |

The Sheriff can't fire faster than every 0.25 s, so tapping any faster just fires it at its rate.
Most of the climb a spray shows is recoil, not cone: the Vandal's cone never passes 1°.

The Vandal's first shot is a 4.4 cm radius at 10 m and 13 cm at 30 m, about the width of a head:
that is why first-shot misses at long range are a common complaint about the reference.

## 5. Design

```
 one shot, inside WeaponSim.step (client prediction and server alike)

   time since last shot ──► recovery factor ──► bullet number b = spray x factor + 1
                                                    │
   movement state ◄── PlayerSim (speed, ground,     ├─► cone radius = (firing error(b) - ADS) x crouch
   (still / walk / run / crouch / air, landing)     │                 + movement error + landing
                                                    ├─► recoil = climb(b) x running x ADS, drift x crouch x ADS
   seed + shot number ──► hash ──► u1, u2 ──────────┴─► offset = radius x u1 ^ error power, at angle 2 pi u2
                                                    │
                                    direction = aim turned by recoil, then by the offset
```

- **Spray position and recovery.** Each shot reads the curves at a bullet number. Holding the
  trigger counts 1, 2, 3 ... The recovery time counts from the moment the gun can fire again, not
  from the last shot. A shot fired `e` seconds after that scales the spray so far by
  `(1 - e / recovery) ^ tapEfficiency`, so a held trigger, or a click on the first tick the gun
  is ready, recovers nothing. At the recovery time the next shot is a first shot again, exactly as
  the patch notes describe, and a higher tap efficiency forgives more of a short pause. Partly
  recovered sprays sit between bullets, which is why the curves have values between bullets.
  Counting from the shot instead would make a slow gun's recovery meaningless: the Outlaw fires
  every 0.36 s, so its 0.15 s (Patch 13.01) would always be over before it could fire again.
- **Cone.** Firing error at the bullet number, from the zoomed curve when aiming down sights or
  scoped, times a percentage when crouched; then the movement error for the state and the landing
  penalty are added on top. Each mode a gun fires in has its own accuracy
  (`WeaponConfig.mode`): from the hip, zoomed, and the Classic's right click.
- **Movement state** is binary, like the reference: in the air; still (below the deadzone);
  crouch-walking; walking (walk key held at walking speed); running. Slowing from a run to a stop
  without the walk key never passes through walk accuracy. The deadzone test is strictly below
  27.5% with a 1 mm/s margin: Patch 3.0 put the tag slow at exactly that speed, and a tagged
  runner must not count as still.
- **Where in the cone.** The bullet lands at `radius x u ^ power` from the centre, at a uniform
  angle. Power 0.5 spreads bullets evenly over the cone and 1 piles them toward the middle: we use
  1 standing and 0.6 moving, Patch 6.11's "almost uniformly random" for moving shots.
- **Recoil.** The climb is a curve by bullet number (the same every spray, as the reference's
  first bullets are), multiplied while running and while aiming down sights. The sideways drift
  starts after a few bullets, steps a fixed amount each bullet, reverses at random or at its
  limit, and is shrunk while crouched and still. It is part of the weapon state, so it recovers
  with the spray.
- **Randomness that both sides agree on.** The server picks a seed for each life; it travels in
  the ack, so the client knows it from the first round trip after spawning. Every random number is
  a 32-bit integer hash of (seed, shot number, stream), the same on every machine. The recovery
  factor is rounded to 1/65536 so a last-bit difference in the maths library can't split client
  and server, and the client compares the spray position and drift with a tiny tolerance.
- **Camera.** The view shows the weapon's camera share of the recoil the next bullet would get,
  eased in at 30/s so each shot reads as a kick, and settling as the spray recovers. It is visual
  only: the aim the client sends never includes it, and the bullets go where the simulation says.

### The seed trade-off

Because the client knows the seed, it predicts every bullet exactly: tracers, impact marks and its
own hit guess match the server's verdict. The cost is that a modified client could compute the
spread and aim against it ("no-spread"), a long-standing weakness of games that share their spread
seed. The alternative is a server-only seed: the client would draw tracers with its own
randomness and correct them to the server's end point a round trip later. We chose exact
prediction for now; switching is a matter of not sending `seed` in the ack. This is about our own
game's anti-cheat design and has nothing to do with the reference's.

### Fixed in the movement follow-up

System 1's Source-style friction floor (`stopSpeed`) couldn't hold a speed below about 1.6 m/s, so a
tagged runner (capped at 1.485 m/s) sagged below the cap and into the deadzone within a few ticks.
The Unreal-style ground model that replaced it (see `docs/research/01-movement.md`) has no friction
while moving the way you push, so a held key holds the cap exactly, and the accuracy test now
checks every tick of the slow.

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Weapons/WeaponConfig.luau` | `accuracy` and `recoil` for every weapon and the shared `WeaponConfig.Accuracy`, each value with its status and source |
| `src/shared/Weapons/Accuracy.luau` | Curves, recovery factor, cone, recoil and drift, per-shot hash randomness, bullet direction |
| `src/shared/Weapons/WeaponSim.luau` | Applies them on each shot; spray position, drift and seed are weapon state |
| `src/shared/PlayerSim.luau` | Movement state for the cone (still / walk / run / crouch / air, landing), strict deadzone |
| `src/shared/Net/PlayerCodec.luau` | The ack carries the seed, the drift and its direction |
| `src/server/PlayerSimServer.luau` | A fresh random seed for every life |
| `src/client/PlayerController.luau` | Camera kick from the simulated recoil; reconciliation checks the new state |
| `src/client/Debug/DebugHud.luau` | Ring showing the next shot's true cone where its bullet would go |
| `src/client/Debug/SprayLab.luau` | The spray lab (below) |
| `tests/accuracy.luau` | Offline tests and the spread and recoil metrics report |

## 7. Debug tools

| Key | Tool |
| --- | --- |
| F2 (second press) | Spray lab: the current spray plotted in degrees from the aim (bullets coloured by number, the recoil centre path, the last cone, a measured reference spray in blue); the last shot's cone piece by piece (curve, ADS, crouch, movement, landing, error power, offset, recoil); the next shot now (bullet number after recovery, cone, size at 10 / 20 / 30 m); the weapon's curves by bullet; where tapping at 0.15 to 0.4 s settles |
| F3 | The HUD's ring is the next shot's real cone, drawn where that bullet would go (recoil less the camera kick). Green: a clean first shot. Blue: the spray hasn't recovered. Red: movement or landing error |
| always | Impact marks stay on walls (newest 80), so a spray leaves its pattern next to the reference's |
| Backspace | Clear impact marks, the shot log and the spray plot |

## 8. Refinement loop

1. Measure first-shot cones (hip, ADS, crouched) for each weapon and enter `firstShotError`;
   correct bullet 1 of each `firingError` curve, hip and zoomed, and the crouch values.
2. Record five full sprays per rifle, average them into `sprayPattern`, and fit the climb curve,
   drift start, step and limit until the spray lab's dots sit on the blue reference.
3. Measure recovery with tap pairs and set `tapEfficiency` (and recovery time where not
   confirmed) so the lab's tapping table matches.
4. Measure movement, airborne and landing error; update what isn't confirmed.
5. Count the share of first shots inside half the cone to set `errorPower`.
6. Measure the camera share in hip fire and ADS.
7. Re-run `luau tests/run.luau` and update the tables in section 4.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- The camera kick feels like a kick at 60 and 240 fps, and the HUD ring sits on the impacts
  (spray at a wall with F3 on).
- The first ack after spawning corrects the seed before the first shot in normal play (the weapon
  lab's agreement column should stay at 100% against static dummies).
- The spray lab's plot matches the impact marks on the wall at a known distance.

The [Studio test session](../studio-checklist.md) walks through these, with what to expect.
