# System 38: Sage's Barrier Orb

Sage's third ability is played: C puts her Barrier Orb in hand, a targeter shows where its wall
would go, and fire raises it there: four segments of ice in a row across her view, up to 15 m away,
that rise out of the floor and stand in everyone's way for 40 s, until enemies break them. C again
turns the targeter a quarter, and alt fire held keeps it facing the way it did as she turns. It has
one charge at 300 credits. This system adds where the wall goes (from the crosshair, through the
same world the movement uses), the wall in the shared simulation, so that nobody walks, shoots or
sees through it and whoever stands where it rises is lifted onto it, judged at the time each
player's screen showed as the Slow Orb's fields are, each segment's health on the server,
fortifying, decaying and taking damage, and how it looks and sounds.

As before, everything comes from public sources: five of Riot's patch notes and, for what Riot
doesn't give, the VALORANT Wiki's page on the Barrier Orb, Mobalytics' page on Sage, and guides by
Dignitas, Hotspawn, valorant-spind.de and Liquipedia. No game files, memory or network traffic were
used, and nothing was read from the live game. Here the wiki's numbers are labelled community,
though it says some of them come from the game files, and so are the guides'. Riot gives the cost,
the range, the health as it forms and once fortified, when it fortifies, that damage done before
then stays done, that it doesn't wear down until near its end, and that it can't be cast in the buy
phase; the wiki gives its segments, their size, its deploy time, its duration and when it decays;
its height is a guide's reading (about 140% of a player's); where exactly it goes, how a segment
finds its floor, its thickness, and how alt fire turns it are ours. Nothing in this system is
measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop; Mobalytics; Dignitas; Hotspawn; valorant-spind.de; Liquipedia) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **In hand** (the wiki). "EQUIP a barrier orb. FIRE places a wall that fortifies after a few
  seconds. ALT FIRE rotates the targeter." It's ready 0.8 s after C (its equip time, the wiki's
  estimate), and the gun is back 0.7 s after the wall goes up (its unequip time, from the game
  files, it says). It has one use at 300 credits, since Patch 11.08 cut it from 400.
- **Where it goes** (the wiki and Patch 11.04). Its targeter goes on horizontal terrain, up to 15 m
  away: "Sage wall cast range has increased from 10m >>> 15m", "by allowing her to control space
  from further safety." When it's first equipped in a round it's across her view; recasting turns it
  a quarter; alt fire gives full control of its angle, and a recast after alt fire puts it back
  across her view or along it; it keeps its turn when it's equipped again. Since Patch 6.11 a turn
  doesn't hold up the wall: before it, the wiki's history says, "when Sage rotated her Barrier Orb
  90 degrees, she was blocked from placing the wall for .8 seconds". A segment with no horizontal
  terrain under it isn't made: Patch 0.49, as the wiki's history gives it, "Will only spawn a chunk
  of the barrier if it is supported by the ground".
- **The wall** (the wiki, Mobalytics, Dignitas, Hotspawn and Liquipedia). Four segments, "2.6 x 1.5
  meters each, 10.4 x 1.5 meters total"; a deploy time of 1.35 s (the wiki's estimate); 40 s in all,
  its deploy time included, decaying from 35 s ("Begins to decay after 35 seconds", Mobalytics).
  "Fire places a solid wall." (Liquipedia): it blocks sight and stops whatever would go through it
  (the wiki). No source gives its height: Dignitas, "It seems to be about 140% of the player's
  height". Players boost on it: "stand directly above it before creating it" (Hotspawn).
- **Its health** (Patches 1.07, 1.14, 6.04 and 11.08). Each segment forms with its own health, 400
  ("Wall forms at 400 HP", Patch 1.07), and fortifies 2 s after the cast to 600 (Patch 11.08:
  "Fortification delay reduced from 3.3 seconds to 2 seconds", "Health of Barrier segments decreased
  from 800 to 600"). Damage done to it as it fortifies stays done: Patch 6.04 fixed it fortifying to
  full health "instead of going to max health minus the damage that was dealt during fortification."
  Since Patch 1.14, "Once fortified, Barrier no longer loses health over time—Barrier only starts to
  deteriorate a few seconds before it expires"; the wiki has each segment then lose a share of the
  health it has left, so one with less doesn't go sooner, and all of them go together. Enemies break
  segments with damage (the wiki; valorant-spind.de: "enemies can destroy it with damage"), each on
  its own: "Barrier Orb deploys in sections, so portions of it can be destroyed independently"
  (Hotspawn).
- **The spike and the buy phase.** A segment touching the planted spike breaks at once (the wiki).
  Since Patch 1.14, "Barrier Orb can't be cast in Buy Phase", which began as a fix "intended to
  prevent an exploit with Omen".
- **On the minimap.** Liquipedia's history: "Friendly Barrier Orb (C) walls now show on the
  minimap". The wiki's history adds a preview of where it would go on the minimap (Patch 9.03).
- **Sage** (systems 36 and 37). Her Healing Orb (E) and Slow Orb (Q) are played; her Resurrection
  (X) is still to come.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| Barrier Orb "Cost reduced from 400 >>> 300"; "Fortifying Barrier: Wall forms at 400 HP—after a 3 second delay, the wall becomes fortified to 800 HP"; "Our hope is to increase counterplay on Barrier and reduce the strength of the wall during reactive use." | [VALORANT Patch Notes 1.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-07/), 1 September 2020 |
| "Barrier Orb can't be cast in Buy Phase"; "Although this was a hotfix solution intended to prevent an exploit with Omen, this change is overall a solid one" "that we believe creates cohesion across what can and can't be cast in buy phase."; "Once fortified, Barrier no longer loses health over time—Barrier only starts to deteriorate a few seconds before it expires"; "to prevent the mitigation of the fortifying counterplay, while rewarding Sage players that successfully fortify their walls." | [VALORANT Patch Notes 1.14](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-14/), 8 December 2020 |
| "Fixed bug where if Sage's Barrier Orb was damaged while fortifying, it would fortify to full health" "instead of going to max health minus the damage that was dealt during fortification." | [VALORANT Patch Notes 6.04](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-6-04/), 7 March 2023 |
| "Sage wall cast range has increased from 10m >>> 15m"; "We're leaning into Sage's identity as a Controller-leaning Sentinel hybrid by allowing her to control space from further safety." | [VALORANT Patch Notes 11.04](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-04/), 19 August 2025 |
| Barrier Orb "Cost reduced from 400 to 300"; "Fortification delay reduced from 3.3 seconds to 2 seconds"; "Health of Barrier segments decreased from 800 to 600" | [VALORANT Patch Notes 11.08](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-08/), 14 October 2025 |

### From the community

| What | Source |
| --- | --- |
| "EQUIP a barrier orb. FIRE places a wall that fortifies after a few seconds. ALT FIRE rotates the targeter." | [VALORANT Wiki, Barrier Orb](https://wiki.playvalorant.com/en-us/Barrier_Orb) (Weird Gloop) |
| Basic; 300 credits; 1 use; equip 0.8 s (its estimate); unequip 0.7 s (from the game files, it says); deploy time 1.35 s (its estimate); a cast range of 15 m (Patch 11.04); fortifying 2 s from the cast (Patch 11.08); size "4 segments, 2.6 x 1.5 meters each, 10.4 x 1.5 meters total"; 40 s in all, its deploy time included, and decaying from 35 s (from the game files, it says); 400 health a segment, 600 fortified | The same |
| In our words, it says: the targeter goes on horizontal terrain, across her view when first equipped in a round; a recast turns it a quarter; alt fire gives full control of its angle, and a recast after alt fire puts it back across or along her view; it keeps its turn when equipped again; a segment that wouldn't touch horizontal terrain isn't made; the wall blocks sight and stops what would go through; a segment touching the planted spike breaks at once; enemies break segments with damage, each with its own health; near the end each loses a share of what it has left, and all go together | The same |
| History: 0.49, "Will only spawn a chunk of the barrier if it is supported by the ground"; 1.11, "Sage wall segments no longer break if a player dies on top of them"; 3.0, "Agents blocked by Barrier Orb when resurrected now break the wall"; 6.11, before which "when Sage rotated her Barrier Orb 90 degrees, she was blocked from placing the wall for .8 seconds"; and, in our words, 9.03's preview of it on the minimap and 9.07's placeables not placed above one rising | The same |
| Equip 0.8 s, unequip 0.7 s, deploy 1.35 s; "4 segments \| 2.6 x 1.5 meters per segment \|Total 10.4 x 1.5 meters"; "Begins to decay after 35 seconds" | [Mobalytics, Sage](https://mobalytics.gg/valorant/agent/sage) |
| "It seems to be about 140% of the player's height"; "The wall is damaged over time, but if it is damaged it won't change the amount of time it takes it to be destroyed naturally." (from before Patch 1.14) | [Dignitas, Tips and Tricks Using Sage Effectively](https://dignitas.gg/articles/blogs/valorant/14735/tips-and-tricks-using-sage-effectively-in-valorant) |
| "Barrier Orb deploys in sections, so portions of it can be destroyed independently"; to boost, "stand directly above it before creating it" | [Hotspawn, How to play Sage](https://www.hotspawn.com/valorant/guide/how-to-play-sage) |
| "enemies can destroy it with damage"; it "fortifies after about two seconds and stands for up to 40 seconds" | [valorant-spind.de, Sage](https://www.valorant-spind.de/en/valorant-agent-sage.html) |
| "Fire places a solid wall."; "Alternate fire rotates the targeter."; "Friendly Barrier Orb (C) walls now show on the minimap" | [Liquipedia, Sage](https://liquipedia.net/valorant/Sage) |

No source gives the wall's height, which of the wiki's 2.6 x 1.5 is its thickness, how far over or
under the targeter's floor a segment may stand, how steep a floor may be, where the wall goes when
the aim meets no floor within its range, what alt fire's full control is like to use, how a decaying
segment loses its health over the last 5 s, whether allies' bullets or the owner's own break it, or
what the orb, the targeter and the wall look and sound like. Ours are in section 4. We read the 1.5
as its thickness, since a wall 1.5 m tall wouldn't hide a standing agent's eye; Dignitas' 140% of
our 1.8 m player is 2.5 m. We read alt fire as holding the targeter's facing in the world while she
turns, so letting go leaves it turned.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| Its height and thickness | Clips of a wall beside an agent and a spike site's boxes, stepped to where it stands still; a custom game, crouching and jumping beside it |
| Where it goes | A custom game: aim at known marks on open ground, at walls and into the sky, at and past 15 m, and note where the targeter sits |
| How a segment finds its floor | A custom game: raise it across steps, boxes and ledges of known heights, and note which segments are made and where |
| Alt fire | A custom game: hold alt fire and turn, then let go and turn, and watch the targeter |
| The decay | A custom game: shoot one segment down to half before 35 s, and time when each goes |
| The rise | Clips stepped frame by frame from the cast to the wall standing still; a custom game, standing where it rises |
| Who breaks it | A custom game: shoot your own wall, and have a teammate shoot it |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Its charge | One, 300 credits, bought in the buy phase in the spike rounds and sold back in it; the course fills it 1.5 s after it's spent, and the arena gives it every life; in Team Deathmatch a spent one comes back in 94 s | Confirmed (300, Patch 11.08); community (one; 94 s) |
| In hand | C puts the orb in the fifth slot, ready 0.8 s later, as the Slow Orb's is (system 37); a number key puts it away unthrown, with nothing spent, and Q or E puts the Slow Orb or the Healing Orb there instead. With it you run at the knife's speed | Community (0.8 s); estimate (the speed) |
| The targeter | With the orb in hand, a ghost of each segment where fire would raise it, as your own simulation would place it, pale blue, or red in the buy phase. It's across your view the first time it's in hand each life or round. C again turns it a quarter, so it runs along your view, and again back across. Alt fire held keeps it facing the way it did as you turn; let go, the turn it's left at is kept, in hand again too, until a new life or round; C after alt fire puts it back across your view. Alt fire doesn't zoom, and a turn doesn't hold up the wall | Community (across, a quarter, alt fire, back, kept: the wiki; no hold-up: Patch 6.11 as the wiki gives it); estimate (alt fire held as a facing kept in the world) |
| Where it goes | Where the crosshair's line meets a floor (its up at least 0.7, about 45 degrees) within 15 m of the eye. Aimed further, into the sky, or at a wall or anything steeper, it goes on the floor below where the aim ends, a little this side of what it met, up to 20 m below. Aimed level on open ground, it goes 14.9 m away. With no floor there, it goes nowhere | Confirmed (15 m, Patch 11.04); community (horizontal terrain: the wiki); estimate (the rest) |
| Its segments | Four in a row, 2.6 m each, centred on the targeter and across the way it faces. Each stands on the floor under its middle, looked for from just over 1 m above the targeter's floor to 1 m below it, and is left out if there's none; with none at all it goes nowhere | Community (four, 2.6 m: the wiki; left out: Patch 0.49 as the wiki gives it); estimate (1 m up and down) |
| Raised | The left button raises it as soon as the orb's ready (held, as it comes into hand). A charge goes, and the gun's back 0.7 s later. With nowhere for it, or in the buy phase, nothing goes up and the orb stays in hand, held fire trying again ten times a second | Community (0.7 s); confirmed (the buy phase, Patch 1.14); estimate (the tries) |
| The wall | From the server's time at the cast, each segment rises out of its floor to 2.5 m over 1.35 s, reaching 0.5 m under its floor so a slope or a step under its ends leaves no gap, and 1.5 m thick. It stands 40 s from the cast, and then what's left goes at once | Community (1.35 s, 40 s and 1.5 m: the wiki; 2.5 m: Dignitas' 140% of our 1.8 m player); estimate (0.5 m under; 1.5 m read as its thickness) |
| In everyone's way | Standing, each segment is a box in the world everyone moves through: nobody walks or jumps through it, and whoever stands even partly where it rises is lifted onto its top as it rises, as MovementSim keeps a player clear of what they're in. In the level shots and swings are traced through, it's a surface no bullet goes through; and it's in the way of a sight, for the minimap's spotting and the Healing Orb's aim | Community (blocks sight and passage: the wiki; boosting: Hotspawn); estimate (lifted when partly over it) |
| Judged when | As the Slow Orb's fields (system 37): each tick of a player's, on both ends, meets the walls as they stood at the server time their screen showed as they made it, no more than 1 s behind the server's, so their own prediction meets a wall just as the server does. Shots and swings meet them as the shooter's screen showed them | Estimate |
| Its health | Each segment's own: 400 as it forms; 2 s after the cast each one standing gains 200, so it's 600 less what it had lost; from 35 s each loses its share of what's left of the wall's time, so every segment comes to nothing at 40 s, whatever it had, and none goes before the rest | Confirmed (400, Patch 1.07; 600 and 2 s, Patch 11.08; what's lost stays lost, Patch 6.04; no wearing down until near the end, Patch 1.14); community (from 35 s, and all going together: the wiki); estimate (the share) |
| What breaks it | A bullet that stops at a segment takes off it what it would have done to a body there: the Vandal's 40, less what any wall before it took. A knife's swing that meets one takes its front damage, 50, or 75 for the heavy swing. At nothing it breaks, for everyone. The owner's enemies' bullets and knives do this; their teammates' and their own don't. On the course, with no sides, anyone's do, the owner's too, so it can be tried alone | Community (enemies, by damage, each segment its own: the wiki, valorant-spind.de, Hotspawn); estimate (what a bullet or a knife takes; on the course) |
| The spike | A segment that, risen, would touch the planted spike breaks as the wall's raised | Community (the wiki) |
| A practice dummy | Moves through walls as a player does, on the server's clock, and is lifted onto one the same way | Estimate |
| A new round | Every wall gone | Estimate |
| Its look | The orb in hand a pale ball with a slab of ice behind it over an open hand; the targeter pale ghosts of the segments; the wall pale blue blocks of solid ice rising from the floor, flashing white for 0.3 s as they fortify and paler after, clouding over grey in the last 5 s; each segment that breaks scattering eight chips of ice that fall and fade; sparks of ice where bullets and knives meet it; on the minimap a pale blue bar along each segment standing, edged in its owner's colour | Estimate (ours) |
| Its sounds | A gust as the orb comes up in hand; a deep crack as the wall rises, from you as you raise yours and from the wall as others' rise; a quieter, higher crack as it fortifies; and a sharp crack as a segment breaks or the wall's time is up, each heard as far as an ability | Estimate (ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** adds `BarrierOrb` (the unequip; the range and the floor; how far below the
  aim's end it looks for a floor and how far over and under a segment stands; the segments, their
  length, thickness, height and depth; the rise, fortify, decay and duration; and the health as it
  forms and fortified), each with its status and source. The Barrier Orb's cost is now confirmed by
  Patch 11.08, its `weapon` is the orb, and `unequip(id)` says the gun's back 0.7 s after a wall.
- **`WeaponConfig`** adds `wallorb`, the orb in hand, an `ability` weapon for the fifth slot as the
  Slow Orb's is: 0.8 s to draw, one wall, held fire trying ten times a second, no spread and no
  kick; never sold or dropped. Its wire id is the 29th.
- **`AbilitySim`** plays the Barrier Orb: C puts it in hand (`held`), C again turns its targeter
  (the kit's `turn`), alt fire held keeps its facing (`turning` and `fixed`), `settle` puts it back
  across, `thrown` turns a wall raised into a `barrier` cast, and the summary ends in `turn` while
  it's turned.
- **`BarrierSim`** (new) is the Barrier Orb's own: where a wall goes (`place`, from an eye, an aim
  and the angle the kit gives); the wall raised (`raise`, breaking any segment the planted spike
  touches); its times (`ends`, `fortifies`, `decays`, `risen`); which segments stand and their boxes
  (`standing`, `box`, `pieces`); the movement world with the walls in it (`world`), the shots' level
  (`level`, each segment a "solid" surface keyed by its piece) and sight (`hides`); and the health
  (`fortify`, `decay`, `summary`). No Roblox APIs, so the offline tests run it through a fake world.
- **`BoxMath`** sweeps a box against another, as Roblox's Blockcast does and the offline tests' fake
  world did (`sweep`, now shared), and casts a ray at one (`ray`, `inside`).
- **`PlayerSim.step`** takes the walls in play and the time they're judged at (`Walls`), moves
  everything in the tick through the world with them in, and turns fire with the orb in hand into a
  `barrier` cast with where its wall goes, or nothing where there's nowhere for it or in the buy
  phase.
- **`PlayerCodec`** carries the targeter's `turn`, `fixed` and `turning` in the ack; **`Sight`**
  takes the walls among what hides a line.

### The server

- **`BarrierServer`** (new) raises each `barrier` cast's wall where the caster's simulation placed
  it, from the server's time then, breaking any segment the planted spike touches, and tells every
  client of it (the Ability remote's `barrier`: its segments, when it rises, and where, for its
  sound) and of each segment that breaks (`break`). It keeps each segment's health, fortifying and
  decaying it as the wall's time goes, and takes each bullet's and knife's damage off it; it keeps
  each wall for the simulation until a second after its time's up, for moves that come in late; it
  sets each owner's `VFWall`; and it lets them all go with a new round.
- **`PlayerSimServer`** gives each player's tick the walls, judged at the time their screen showed
  (`SlowSim.judged`), and **`Dummies`** give each dummy's the walls at the server's clock.
- **`CombatServer`** traces each shot and swing through the walls as the attacker's screen showed
  them (`levelAt`), and tells `BarrierServer` what a bullet that stopped at one would have done
  there, and a swing's front damage (`struck`); a swing that meets one leaves a spark of ice.
- **`AbilityServer`** leaves the `barrier` cast to `BarrierServer`, which tells of it with its wall.
  **`MinimapServer`** and **`HealServer`** take the walls among what hides a line, so nobody's
  spotted, or healed, through one.
- **`Arena`** clears the walls with each new round, mode and the course; **`init.server`** starts
  `BarrierServer` and steps it after the Slow Orb's.

### The client

- **`BarrierView`** (new) draws the targeter while the orb's in hand, placed as your simulation will
  place it (through the walls standing, judged as your screen shows them), red in the buy phase,
  and, once you've raised it, leaves its ghost where it went until the server's wall rises there.
  Every wall the server tells of, yours too, is kept on the server's clock for your prediction
  (`PlayerController.barriers`) and your shots (`ClientShots.barriers`) until 2 s after its time's
  up. It draws each as the frame on your screen reaches it: a block of ice for each segment, rising
  out of its floor, flashing as it fortifies and clouding over as it decays, and breaking into chips
  with its sound as the server says or as its time's up. **`BarrierView.standing`** gives the
  minimap the segments standing.
- **`PlayerController`** gives each predicted tick, and each replayed after a correction, the walls
  judged at the time its frame showed.
- **`ClientShots`**, **`ClientMelee`** and **`WeaponEffects`** trace your shots and swings through
  the walls as your screen shows them, and draw a spark of ice where one meets a wall.
- **`MinimapView`** draws each segment standing as a pale blue bar edged in its owner's colour, and
  stops the vision cones at it. **`AbilityEffects`** sounds a wall rising, yours as you raise it and
  others' as it rises. **`WeaponLooks`** draws the orb in hand; **`SoundConfig`** adds
  `barrierEquip`, `barrierRise`, `barrierFortify` and `barrierBreak`.

### Not here yet

- **Resurrection.** Still on her card, the bar and the buy menu, `NOT YET`.
- **Throws and Blaze.** Cloudburst, Curveball's flare, Hot Hands' fireball, the Slow Orb's orb and
  Blaze's run are flown through the level alone, so they go through a wall of ice; their flights
  come before the walls in the server's frame.
- **Abilities' damage.** The wiki says damaging abilities break segments; Hot Hands' fire, Blaze's
  wall and the spike's blast don't touch them here.
- **The fog of war.** Its lines from an eye to a body don't count walls of ice, so an enemy behind
  one is still sent to you; the ice is solid, so they aren't seen, and the minimap doesn't spot
  them.
- **Sound.** Walls of ice don't muffle what's heard through them.
- **Alt fire.** Our reading of full control of the angle: the targeter keeps its facing while alt
  fire's held.
- **Its height and thickness** are readings, and its look and its sounds are ours until clips are
  stepped through.
- **Late joiners.** Someone who joins while a wall stands doesn't see it, and walks into it until
  the server corrects them.
- **A screen more than a second behind** is judged as if it were a second behind, so its prediction
  may be corrected.
- **The buy phase** is judged on each end from the arena's phase as that end has it: a wall raised
  on the very tick the phase ends may be refused by one end and not the other, and the correction
  puts it right.
- **No ghost for a refusal.** If the server finds nowhere for a wall your simulation placed (a
  correction's worth of difference), no wall rises, the correction puts the orb back in hand, and
  your ghost waits out its 1.5 s.
- **Crates taller than a metre.** A segment looks for its floor from just over 1 m above the
  targeter's floor, so under a taller crate it finds the floor through it and rises out of the
  crate.
- **The minimap's preview, doors, placeables and deaths on top** (the wiki's history: 9.03, 7.04,
  9.07 and 1.11): nothing here is placed or opens yet, and a death on a wall leaves it standing.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | `BarrierOrb`'s numbers, each with its status and source; the Barrier Orb's confirmed cost and its weapon; `unequip` |
| `src/shared/Weapons/WeaponConfig.luau` | `wallorb`, the orb in hand, and its wire id |
| `src/shared/Abilities/AbilitySim.luau` | The Barrier Orb played, its targeter's turn, and its `barrier` cast |
| `src/shared/Abilities/BarrierSim.luau` | New: where a wall goes, the wall, the world, level and sight with walls in them, and its health |
| `src/shared/Movement/BoxMath.luau` | A box swept against another, and a ray cast at one |
| `src/shared/PlayerSim.luau` | Ticks through the walls given, and fire with the orb in hand raising one |
| `src/shared/Net/PlayerCodec.luau` | The targeter's turn in the ack |
| `src/shared/Combat/Sight.luau` | Walls among what hides a line |
| `src/shared/Audio/SoundConfig.luau` | The orb's draw, and the wall rising, fortifying and breaking |
| `src/server/BarrierServer.luau` | New: walls raised, kept, told of, fortified, decayed and broken; `VFWall` |
| `src/server/PlayerSimServer.luau`, `src/server/Dummies.luau` | Players' and dummies' ticks through the walls |
| `src/server/CombatServer.luau` | Shots and swings traced through the walls, and what they strike |
| `src/server/AbilityServer.luau`, `src/server/MinimapServer.luau`, `src/server/HealServer.luau` | The cast left to `BarrierServer`; nobody spotted or healed through a wall |
| `src/server/Arena.luau`, `src/server/init.server.luau` | Walls cleared with each round; `BarrierServer` started and stepped |
| `src/client/BarrierView.luau` | New: the targeter, the walls kept for prediction and drawn, and their breaking |
| `src/client/PlayerController.luau` | Predicted and replayed ticks through the walls |
| `src/client/Combat/ClientShots.luau`, `src/client/Combat/ClientMelee.luau`, `src/client/Combat/WeaponEffects.luau` | Your shots and swings traced through the walls, and sparks of ice |
| `src/client/MinimapView.luau` | Walls of ice on the minimap |
| `src/client/Combat/WeaponLooks.luau`, `src/client/AbilityEffects.luau`, `src/client/init.client.luau` | The orb in hand; the wall's rise heard; the view started |
| `tests/barrierorb.luau` | New: its numbers, the kit, the orb in hand and its targeter, where it goes, the wall, what it does, its health and the wire |
| `tests/FakeWorld.luau`, `tests/healingorb.luau`, `tests/arsenal.luau` | The sweep shared with `BoxMath`; Sage's kit and the weapons' ids with the Barrier Orb played |

## 7. Debug tools

- Each owner's `VFWall` is their last wall's segments' health, in a row: a number for each standing,
  `x` for one broken or gone, and `-` for one left out, as `600,600,-,412`.
- `VFKit` ends in `equip` while the orb's in hand, and in `turn` while its targeter's turned from
  across the view, as `C1/1 Q2/2 E1/1 X0/7 equip turn`.
- `Workspace.VFBarriers` holds a `Barrier` model for each wall while it stands, with a `Segment`
  part for each segment; a `Targeter` model of `Ghost` parts; and the `Chip`s of each segment
  breaking.
- `VFTestButtons` 4096 presses C, 128 the left button and 256 the right, so the orb can be readied,
  turned and raised without a key or a mouse button; `VFTestYaw` and `VFTestPitch` aim.

## 8. Refinement loop

1. Step through clips of walls beside agents and boxes, and set `height` and `thickness`.
2. In a custom game, raise walls across steps, boxes and ledges, and set `climb`, `fall` and
   `floor`; aim past the range and into the sky, and set where it goes then.
3. Hold alt fire and turn in a custom game, and make the targeter turn as the reference's does.
4. Shoot a segment down before 35 s and time when each goes, and set how a segment decays.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The Barrier Orb lit on Sage's card and the bar, with its pip, and for sale at 300 in the spike
  rounds, one and no more.
- C puts the orb in hand in 0.8 s, `EQUIP` on the bar, with its targeter on the floor ahead; the
  left button raises the wall, the pip goes dark and the gun is back 0.7 s later; a number key puts
  it away.
- The targeter: across the view, turned a quarter by C and back, held by alt fire as you turn, kept,
  red in the buy phase, and nowhere off the edge of the course.
- The wall: rising out of the floor in 1.35 s, 10.4 m long and 2.5 m tall, solid, fortifying at 2 s
  with a flash and a crack, clouding over from 35 s and gone at 40 s; `VFWall` as it goes; on the
  minimap.
- In the way: walking and jumping into it, shots stopped at it, a dummy behind it, a segment shot
  down and the gap it leaves, being lifted onto it, and a segment over the planted spike breaking.
- A second player stopped by your wall, lifted onto it and breaking it, with no correction at 100 ms
  each way; and in the spike rounds, your own bullets not breaking it.

Section 42 of the [Studio checklist](../studio-checklist.md) covers these.
