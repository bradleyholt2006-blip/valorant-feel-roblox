# System 37: Sage's Slow Orb

Sage's second ability is played: Q puts her Slow Orb in hand, and fire throws it. It bursts where it
lands into a field of ice that slows everyone in it for 7 s, enemies, allies and Sage alike: their
speed is held to half, on the ground and in the air, a jump goes lower and a dash goes half as fast.
It has two charges at 200 credits each. This system adds the orb's flight (flown as Hot Hands'
fireball is, with numbers of its own), its field (laid as Hot Hands' fire is), the slow in the
shared simulation, judged at the time each player's screen showed so that their own prediction slows
them just as the server does, and how it looks and sounds.

As before, everything comes from public sources: five of Riot's patch notes and, for what Riot
doesn't give, the VALORANT Wiki's pages on the Slow Orb, crowd control, status effects and
projectiles, and valoranttracker.org's page on Sage. No game files, memory or network traffic were
used, and nothing was read from the live game. Here the wiki's numbers are labelled community, and
so are the tracker's. Riot gives the slow, its time, that it slows the air and dashes, and the cost;
the radius is the tracker's 8 m less Patch 1.07's 30%; how fast the field spreads, how high it
reaches and the rest of its shape are ours. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop; valoranttracker.org) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **In hand** (the wiki). "EQUIP a slowing orb. FIRE to throw a slowing orb forward that detonates
  upon landing". It's ready 0.5 s after Q (its equip time), and the gun is back 0.4 s after the
  throw (its unequip time). It has two uses at 200 credits each; Patch 3.0 raised the cost from 100.
  The wiki puts its windup at 0.5 s, an estimate of its own, and says it affects allies and Sage
  herself.
- **Its flight** (the wiki's projectiles). A "Class 3" projectile, as Cloudburst thrown and
  Brimstone's Incendiary are: speed 2900 and gravity 0.45, which we read as 29 m/s and 0.45 of the
  world's gravity. It bursts where it touches level ground.
- **Its field** (the wiki and Patches 0.50 and 1.07). Radianite crystals cover the ground where it
  bursts, and as its time runs out they're gone quickly. It lasts 7 s (9 s until Patch 0.50). Patch
  1.07 reduced its "Size" by 30%: "Right now, slow orb unintentionally covers a lot more ground than
  it should if aimed properly." The tracker gives it an 8 m radius, from mid-2020, before that
  patch.
- **The slow** (Patches 0.47, 0.50 and 9.10, and the wiki). Half the speed of anyone in it (65%
  until Patch 0.50, cut because "These changes aim to reduce the overall efficacy of her Slow Orb,
  especially if they are chained back-to-back."). Since Patch 0.47 it "also slows the air speed of
  players in the zone", because "Players were able to circumvent too much of Sage's Slow Orb by
  bunny hopping through the zone", "while still allowing for bunny hopping and walking to provide a
  slight benefit to traversing the zone." A slow reduces "movement speed and jump height" (the
  wiki's crowd control) and "dash speed" (its status effects); the tracker has the jump's height 30%
  lower. Since Patch 9.10 it slows dashes by half, to "make slows a more meaningful debuff against
  duelists with dashes"; the same patch says the concussions' like change "affects Jett's Tailwind
  and Neon's Slide."
- **Its sound** (Patch 0.47 and the wiki). Those slowed make a sound running or jumping through it,
  and since Patch 0.47 "Players can now walk through the Slow Orb without making noise", "adding a
  stealthy yet slow way to move through the field". Patch 8.08 fixed running footsteps going missing
  while slowed by it.
- **Sage** (system 36). Her Barrier Orb (C) and Resurrection (X) are still to come; her Healing Orb
  (E) is played.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Slow Orb now also slows the air speed of players in the zone"; "Players can now walk through the Slow Orb without making noise"; "Players were able to circumvent too much of Sage's Slow Orb by bunny hopping through the zone."; "We want the minimum slow amount to be a bit more consistent with all movement in the zone" "while still allowing for bunny hopping and walking to provide a slight benefit to traversing the zone."; walking, "adding a stealthy yet slow way to move through the field" | [VALORANT Patch Notes 0.47](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-47/), 21 April 2020 |
| "Slow Orb zone duration decreased from 9 seconds to 7 seconds"; "Slow Orb slowing amount decreased from 65% to 50%"; "These changes aim to reduce the overall efficacy of her Slow Orb, especially if they are chained back-to-back." | [VALORANT Patch Notes 0.50](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-50/), 12 May 2020 |
| Slow Orb "Size reduced by 30%"; "This should slightly reduce the power of Slow Orb and increase intentionality."; "Right now, slow orb unintentionally covers a lot more ground than it should if aimed properly." | [VALORANT Patch Notes 1.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-07/), 1 September 2020 |
| Slow Orb (Q) "Cost increased 100 >>> 200" | [VALORANT Patch Notes 3.0](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-3-0/), 22 June 2021 |
| Slowing Orb "Now will additionally reduce the dash speed of enemies caught inside the slowing zone by 50%"; "make slows a more meaningful debuff against duelists with dashes"; of the concussions' like change, "This affects Jett's Tailwind and Neon's Slide." | [VALORANT Patch Notes 9.10](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-9-10/), 19 November 2024 |

### From the community

| What | Source |
| --- | --- |
| "EQUIP a slowing orb. FIRE to throw a slowing orb forward that detonates upon landing", "creating a lingering field that Slows and reduces the dash speed of players caught inside of it." | [VALORANT Wiki, Slow Orb](https://wiki.playvalorant.com/en-us/Slow_Orb) (Weird Gloop) |
| Basic; 200 credits; 2 uses; a "Class 3 Projectile"; "Affects allies/self?: Yes"; equip 0.5 seconds and unequip 0.4 seconds (from the game files, it says); windup 0.5 seconds (its own estimate); slow 50% and duration 7 seconds (Patch 0.50) | The same |
| In our words, it says it bursts on touching level ground, covering it in radianite crystals; those who touch them are slowed and make a sound running or jumping through them; and as it ends it's gone quickly | The same |
| History: 8.08, "Fixed an issue where footsteps were not produced when in ADS and when running while slowed by Slow Orb." | The same |
| "A slow afflicts the Slowed debuff on affected agents, reducing their movement speed and jump height."; the Slow Orb's slow 50% for 7 s | [VALORANT Wiki, Crowd Control](https://wiki.playvalorant.com/en-us/Crowd_Control) |
| "An agent with a Slow debuff has their movement speed, jump height and dash speed reduced." | [VALORANT Wiki, Status Effect](https://wiki.playvalorant.com/en-us/Status_Effect) |
| Class 3: speed 2900 and gravity 0.45, for the Slow Orb, Cloudburst not held, the Incendiary and others; "Projectile classes are not official VALORANT terminology" | [VALORANT Wiki, Projectile](https://wiki.playvalorant.com/en-us/Projectile) |
| Slow 50%; duration 7 seconds; its "Hump Height Reduction" (the jump's) 30%; "Radius 8m". Its prices (the Slow Orb at 100 credits, the Barrier Orb at 400) were Riot's only between Patches 0.50 and 1.07, in mid-2020, so its numbers are from before Patch 1.07's cut | [valoranttracker.org, Sage](https://valoranttracker.org/agents/sage) |

No source says how far the field reaches today, how fast it spreads, how high above its floor or how
far below it it slows, what stops it spreading, how fast someone slowed in the air may go, how much
lower or faster a jump in it is beyond the tracker's 30%, whether it slows a lift (Jett's Updraft),
what a hop through it gains ("a slight benefit"), or what the orb, the field and the slow look and
sound like. Ours are in section 4. We read Patch 1.07's 30% as the radius's (8 m to 5.6 m); as the
area's it would be 6.7 m. We read the projectile class's speed as centimetres a second and its
gravity as a share of Unreal's default, as for Hot Hands (system 31). Patch 9.10 says the dash slow
is for "enemies", but the wiki's description says "players", and the orb slows allies and Sage; ours
slows anyone's dash.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| The field's size | Clips of a field beside something of known size (a spike site's boxes, an agent), stepped to its edge |
| How fast it spreads, and how high it reaches | Clips stepped frame by frame from the burst; a jump in it beside a crate |
| A slowed jump's height | A custom game: jump in a field beside a crate of known height, and out of one |
| A hop's gain | A custom game: time a run, a walk and a run of hops through a field between two marks |
| The flight | Clips of throws on open ground, level and pitched up, stepped to the burst |
| A windup | Clips of a throw stepped from the click to the orb leaving the hand |
| A slowed Updraft | A custom game: Jett's Updraft in a field and out of one, beside something tall |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Its charges | Two, 200 credits each, bought in the buy phase in the spike rounds; the course fills both 1.5 s after one's spent, and the arena gives both every life; in Team Deathmatch a spent one comes back in 51 s | Confirmed (200, Patch 3.0); community (two; 51 s) |
| In hand | Q puts the orb in the fifth slot, ready 0.5 s later, as Hot Hands' fireball is (system 31); Q again or a number key puts it away unthrown, with nothing spent, and E puts the Healing Orb there instead. With it you run at the knife's speed | Community (0.5 s); estimate (the speed) |
| The throw | The left button throws it from the eye along the crosshair, as soon as it's ready (held, it goes at once). A charge goes, and the gun's back 0.4 s later. The right button does nothing. It leaves the hand on the click: there's no windup | Community (0.4 s); estimate (no windup, where the wiki estimates 0.5 s) |
| Its flight | 29 m/s, falling at 0.45 of 9.8 m/s/s. Level from the eye it bursts about 24 m ahead after 0.82 s, and thrown up at 45 degrees on open ground about 190 m away after 9.4 s. It's never lobbed, and has no air time to run out | Community (the class); estimate (its units and 9.8) |
| What it meets | It bursts on anything level enough (its up at least 0.7, about 45 degrees) and bounces off anything steeper, walls and ceilings, keeping half its speed. Players don't stop it | Community (bursts on level ground); estimate (the threshold, the half, players) |
| Given up on | Meeting no floor within 5 s of when a throw straight up would come back down (18.2 s in all), it's gone, and there's no field | Estimate |
| Its field | On the floor under the burst, out to 5.6 m, spreading evenly over 0.3 s, lasting 7 s from the burst, then gone at once | Confirmed (7 s, Patch 0.50); community (5.6 m: the tracker's 8 m, less Patch 1.07's 30%); estimate (0.3 s, gone at once) |
| Walls | Each way round (24 of them) it reaches no further than the first wall 0.5 m up, as Hot Hands' fire does; a ramp up doesn't stop it, nor a kerb under 0.5 m | Estimate |
| Who's slowed | Everyone whose feet are over it as a tick starts, its edge pushed out by the body's half width (0.34 m), no more than 1.2 m above its floor and no more than 0.5 m below: enemies, allies and Sage alike. A standing jump peaks at 0.85 m, so a jump in it stays in it | Community (allies and herself); estimate (the rest) |
| The slow | The most speed along the ground and in the air held to half of what it was, at once, a tick at a time: with a rifle, 2.7 m/s running and 1.65 m/s walking. A jump at 0.84 of its speed, so 0.7 as high (0.58 m). A dash at half its speed, so half as far (Tailwind's 7 m to 3.5 m) and no faster than the slow lets them go as it ends. Leaving it, they speed back up as from any slower pace | Confirmed (half, Patch 0.50; the air, Patch 0.47; dashes, Patch 9.10); community (the jump's 30%: the tracker); estimate (at once, in the air as on the ground) |
| Judged when | Each tick of a player is judged at the server time their screen showed as they made it (its input's viewTime), on both ends: their own prediction slows them just as the server does. The server judges a screen no more than 1 s behind it, and never ahead | Estimate |
| A practice dummy | Slowed in it as a player is, on the server's clock | Estimate |
| A new round | Every field gone | Estimate |
| Its look | The orb a pale glowing ball; its burst a flash; its field a floor of ice spreading as the server's does, with shards of ice standing up as it reaches them, fading in its last 0.3 s; the edge of your screen frosted while you're slowed; on the minimap, a round in its thrower's colour | Community (the crystals, gone quickly); estimate (the rest, ours) |
| Its sounds | A light gust as it comes up in hand, a swish as it's thrown, a crack of ice as it bursts, heard as far as an ability; a crunch of ice with each running step, jump and loud landing of anyone in a field, and nothing walking or crouching | Community (running and jumping heard, walking not: Patch 0.47 and the wiki); estimate (the sounds, ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** adds `SlowOrb` (the unequip; the flight, its bounce and its floor; the field's
  radius, spread, duration and reach up, down and against walls; and the slow, the jump's and the
  dash's), each with its status and source. The Slow Orb's cost is confirmed by Patch 3.0, its
  `weapon` is the orb, and `unequip(id)` says the gun's back 0.4 s after a throw.
- **`WeaponConfig`** adds `iceorb`, the orb in hand, an `ability` weapon for the fifth slot as the
  fireball is: 0.5 s to draw, one throw, no alt fire, no spread and no kick; never sold or dropped.
  Its wire id is the 28th.
- **`AbilitySim`** plays the Slow Orb: Q puts it in hand (`held`), and `thrown` turns its throw into
  a `slow` cast.
- **`FireballSim`** flies a throw as a `Flight` says (Hot Hands' fireball's unless another's given):
  lobbed only if it can be, and dropping only if it has an air time. `longest` says how long one
  flies before it's given up on: 5 s, or for one with no air time, 5 s after a throw straight up
  would come back down.
- **`FireSim`** lays what lies where a throw burst as a `Shape` says (Hot Hands' fire's unless
  another's given): its radius, spread, duration, reach and walls.
- **`SlowSim`** (new) is the Slow Orb's own: its `FLIGHT`, its `SHAPE`, and its `SLOW` (the shares
  kept of a speed, a jump's speed and a dash's); `throw`, `floorUnder`, `reaches` and `field`;
  `slowed`, whether feet stand in any field at a time; and `judged`, the time the server judges a
  screen at. No Roblox APIs, so the offline tests run it through a fake world.
- **`MovementSim`**: a tick's `Motion` can be `slow`: its most speed is held to the slow's share at
  once, along the ground and in the air, as a cap is, a jump goes at its share, and a dash at its
  share. The state's `slowed` says whether the last tick was, for the sound and the look; nothing
  steps from it.
- **`PlayerSim.step`** takes the fields in play and the time they're judged at (`Slows`), and slows
  a tick whose feet start it in one.
- **`PlayerCodec`** carries `slowed` in the ack.

### The server

- **`SlowServer`** (new) hears each `slow` cast, flies the orb through the level at once and works
  out its field's reach, and tells every client its `flight` (the Ability remote's): its keys,
  `land` (how long after the throw it bursts), `point` (its field's floor) and `reaches`. It keeps
  each field for the simulation from the throw until a second after it's over, for moves that come
  in late, whoever leaves; sets the thrower's `VFLastSlow` as it bursts and each player's `VFSlowed`
  from their last tick; and lets them all go with a new round.
- **`PlayerSimServer`** gives each player's tick the fields, judged at the time their screen showed
  (`SlowSim.judged`), and **`Dummies`** give each dummy's the fields at the server's clock.
- **`Arena`** clears the fields with each new round, mode and the course; **`init.server`** starts
  `SlowServer` and steps it after the heals.

### The client

- **`SlowView`** (new) flies your own throws at once, through the level as the server's do, and
  draws others' from their `flight` as the frame on your screen reaches the throw; if the server's
  field lies more than 0.25 m from yours, the server's goes instead. Every field the server tells
  of, yours too, is kept on the server's clock for your prediction (`PlayerController.fields`) until
  2 s after it's over. It draws each orb as a pale glowing ball, its burst as a flash with its
  crack, and its field as a floor of icy wedges spreading as the server's does, shards standing up
  as it reaches them, fading as it ends; and while you're slowed it frosts the edge of your screen.
- **`PlayerController`** gives each predicted tick, and each replayed after a correction, the fields
  judged at the time its frame showed.
- **`GameSounds`** crunches your running steps, jumps and loud landings while your ticks are slowed,
  and anyone else's where your screen has them in a field (`SlowView.iced`). **`SoundConfig`** adds
  `slowEquip`, `slowThrow`, `slowBurst` and `iceCrunch`.
- **`MinimapView`** draws each field as a round in its thrower's colour, as far as it has spread.
- **`FireView`** shares its wedges and its checks of what the server sends; **`WeaponLooks`** draws
  the orb in hand, a pale ball with two shards over an open hand; **`DebugHud`** shows `SLOWED`
  among its flags.

### Not here yet

- **The rest of her kit.** Barrier Orb and Resurrection are on her card, the bar and the buy menu,
  `NOT YET`.
- **A hop's slight benefit.** Riot meant bunny hopping to keep "a slight benefit" through the field;
  ours holds the air to the same half as the ground, so a hop through it is no faster than a run,
  and louder. How much faster a hop should be needs timing in clips.
- **A windup.** The wiki estimates 0.5 s; ours throws on the click.
- **The radius.** We read Patch 1.07's 30% as the radius's; as the area's it would be 6.7 m.
- **Updraft.** Patch 9.10 slows dashes, and nothing says what a slow does to a lift; ours slows its
  speed along the ground but not its rise.
- **Other dashes.** Tailwind is the only dash here; others come with their agents.
- **Its start on your own screen.** Your field bursts on your screen as your own flight has it, and
  slows you from when your screen reaches the server's burst, a moment later at a high ping.
- **A screen more than a second behind** is judged as if it were a second behind, so its prediction
  may be corrected.
- **The fog of war.** Every client is told of every throw, as of every cloud and fire, so an orb is
  drawn in the air behind a wall.
- **Late joiners.** Someone who joins while a field lies doesn't see it, and isn't slowed by it
  until the server corrects them.
- **Slopes and steps.** The ice is drawn flat at the height it burst, whatever is under it, though
  it slows on a step or a slope as far as it reaches.
- **The server's flights.** Each throw is flown a tick at a time at once; one thrown high into the
  open is flown for up to 18 s of ticks in one frame.
- **The look and the sounds** are ours until clips are stepped through.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | `SlowOrb`'s numbers, each with its status and source; the Slow Orb's confirmed cost and its weapon; `unequip` |
| `src/shared/Weapons/WeaponConfig.luau` | `iceorb`, the orb in hand, and its wire id |
| `src/shared/Abilities/AbilitySim.luau` | The Slow Orb played, and its `slow` cast |
| `src/shared/Abilities/FireballSim.luau` | A throw's `Flight`; `longest` |
| `src/shared/Abilities/FireSim.luau` | A field's `Shape` |
| `src/shared/Abilities/SlowSim.luau` | New: the orb's flight, its field and its slow; whether feet stand in a field; the time a screen's judged at |
| `src/shared/Movement/MovementSim.luau` | A `Motion`'s `slow`, and `slowed` |
| `src/shared/PlayerSim.luau` | Ticks slowed in the fields given |
| `src/shared/Net/PlayerCodec.luau` | `slowed` in the ack |
| `src/shared/Audio/SoundConfig.luau` | The orb's draw, throw and burst, and the crunch of ice |
| `src/server/SlowServer.luau` | New: orbs flown, fields kept and told of, `VFLastSlow` and `VFSlowed` |
| `src/server/PlayerSimServer.luau`, `src/server/Dummies.luau` | Players' ticks and dummies' slowed in the fields |
| `src/server/Arena.luau`, `src/server/init.server.luau` | Fields cleared with each round; `SlowServer` started and stepped |
| `src/client/SlowView.luau` | New: orbs in the air, their bursts and their fields, the fields kept for prediction, and the frosted edge |
| `src/client/PlayerController.luau` | Predicted and replayed ticks slowed in the fields |
| `src/client/Audio/GameSounds.luau` | The crunch of ice |
| `src/client/MinimapView.luau` | Fields on the minimap |
| `src/client/FireView.luau`, `src/client/Combat/WeaponLooks.luau`, `src/client/Debug/DebugHud.luau`, `src/client/AbilityEffects.luau`, `src/client/init.client.luau` | Wedges and checks shared; the orb in hand; `SLOWED`; flights left to `SlowView`; the view started |
| `tests/sloworb.luau` | New: its numbers, the kit, the orb in hand, its flight, its field, the slow and the wire |

## 7. Debug tools

- The thrower's `VFLastSlow` is the floor under their last orb's burst, in metres, set as it bursts.
- Each player's `VFSlowed` is whether their last tick was slowed.
- `VFKit` ends in `equip` while the orb's in hand, as `C0/1 Q2/2 E1/1 X0/7 equip`.
- `Workspace.VFSlows` holds an `Orb` ball for each orb in the air, a `Burst` for each burst while it
  flashes, and an `Ice` model for each field while it lasts: its `Floor` wedges and its `Shard`s.
- The ScreenGui `VFSlowFx` is the frosted edge, and the HUD panel's (F3) flags read `SLOWED` while
  you're slowed.
- `VFTestButtons` 8192 presses Q, 128 the left button and 256 the right, so an orb can be readied
  and thrown without a key or a mouse button; `VFTestPitch` aims it up or down.

## 8. Refinement loop

1. Step through clips of fields beside things of known size, and set `radius`, settling whether
   Patch 1.07's 30% was of the radius or the area.
2. Step through clips of throws on open ground, and set `speed`, `gravity` and `worldGravity` until
   it bursts where the reference's does.
3. Measure a slowed jump against a crate, and set `jump`.
4. Time hops, runs and walks through a field, and give a hop its slight benefit.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The Slow Orb lit on Sage's card and the bar, its two pips, and for sale at 200 in the spike
  rounds, two and no more.
- Q puts the orb in hand in 0.5 s, `EQUIP` on the bar; the left button throws it, a pip goes dark
  and the gun is back 0.4 s later; the right button does nothing; Q again, or a number key, puts it
  away, and E swaps it for the Healing Orb.
- The flight: a level throw bursting about 24 m ahead on the course; one into a wall coming back off
  it; one thrown high coming down.
- The field: spreading to about 11 m across, stopped by a wall but not by a step, gone after 7 s,
  and on the minimap.
- Running into it: 2.7 m/s with the Vandal at once, the frosted edge, `SLOWED`, `VFSlowed` and a
  crunch with each step; walking silent; a jump lower; back to 5.4 m/s out of it, and no correction
  going in or out.
- A strafing dummy slowed in it, its steps crunching.
- A second player slowed in your field, crunching where you see them, on a step too; Jett's dash
  half as far in it; no correction at 100 ms each way.

Section 41 of the [Studio checklist](../studio-checklist.md) covers these.
