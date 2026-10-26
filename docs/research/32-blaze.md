# System 32: Blaze

Phoenix's third ability played here is Blaze, on C: C readies a flame, the left button sends a line
of fire out along the floor from his feet, and while the button's held the line bends towards the
crosshair. Where it ends, a wall of fire rises from Phoenix's end of it and spreads along it to the
far end: nobody sees through it, enemies standing in it burn, allies less, and Phoenix heals in it
instead (Inner Fire, system 31). This system adds the flame in hand, the send and the bend, the run
over the floor and through walls, the wall, its burn and its heal, and how it's drawn, seen from
inside and heard.

As before, everything comes from public sources: four of Riot's patch notes and, for the numbers
Riot doesn't give (the flame's equip and unequip, the run's time and length), the VALORANT Wiki's
pages on Blaze and Phoenix, with its pages on Harbor's High Tide and Viper's Toxic Screen, walls of
the same kind, and Liquipedia, Mobalytics and a NeuralBoost guide to cross-check. No game files,
memory or network traffic were used. The wiki marks some of its numbers as read from the game's
files by its editors and others as its own estimates; here they're the wiki's numbers, labelled
community. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **The flame** (the wiki). "EQUIP a flame wall. FIRE to create a line of flame that moves forward,
  passing through the world", "HOLD FIRE to bend the wall in the direction of your crosshair." 0.8 s
  to equip (from the game's files, there), 0.5 s to put away (estimated there), one use, 150 credits
  since Patch 5.12.
- **Its run** (the wiki and Patch 9.10). The line of flame travels forward through terrain, "leaving
  a path of fire on the ground" below it, for 0.125 to 0.75 s "depending on distance", 1 to 21 m
  (both the wiki's estimates). Holding fire steers it, its direction and its altitude, towards the
  crosshair; sent without holding, it can't be steered after. Since Patch 9.10 its "Initial
  projectile goes through walls, allowing Blaze to function similarly to Harbor's High Tide", whose
  line bends at "180 degrees/second" at most (the wiki, from the game's files).
- **The gun back** (Patch 5.01). "Phoenix will now equip his weapon earlier if he stops bending his
  wall."
- **Its wall** (the wiki). "Once the missile reaches its maximum distance, a wall of flame will
  start to rise from Phoenix's location", spreading along the path to its end. It blocks vision. It
  burns agents from when the flame reaches them, at the same rate for all, so the nearer the cast
  point the more in all; after its 8 s (Patch 1.0) it "rapidly falls". The wiki gives no height or
  thickness; Viper's Toxic Screen, a wall that also runs through terrain and follows it, is "4-meter
  height" (estimated there).
- **The burn** (Patch 1.0 and the wiki). "1 every 0.033 seconds": 30 a second, 225 to 240 in all
  against the wiki's range training bot. Allies: "Yes (damage reduced for allies)", with no number.
  Objects at half (Patch 5.12 and the wiki).
- **Inner Fire** (Patch 1.0 and Patch 9.10). "Blaze healing: 3 every 0.25s >>> 1 every 0.16
  seconds", half Hot Hands' pace for the same 50, so 8 s, going on after Phoenix leaves the fire
  (system 31).

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Blaze duration increased 6 >>> 8 seconds"; "Blaze damage: 15 every 0.25s >>> 1 every 0.033 seconds"; "Blaze healing: 3 every 0.25s >>> 1 every 0.16 seconds" | [VALORANT Patch Notes 1.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-0/), 1 June 2020 |
| "we've matched the damage/healing values to be half as effective as Hot Hands, primarily so that the total healing output of these two abilities is at parity (50 health each)." | The same |
| Blaze (C): "Phoenix will now equip his weapon earlier if he stops bending his wall" | [VALORANT Patch Notes 5.01](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-5-01/), 12 July 2022 |
| "Blaze (C) Cost decreased 200 >>> 150"; "Blaze now damages:" a list of enemy objects | [VALORANT Patch Notes 5.12](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-12/), 6 December 2022 |
| "Initial projectile goes through walls, allowing Blaze to function similarly to Harbor's High Tide."; it's to "allow him to cast Blaze from safety for his teammates similar to other vision-blocking utility." | [VALORANT Patch Notes 9.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-10), 19 November 2024 |
| "Phoenix now applies a Heal over time to himself whenever he touches his flames which persists even if he leaves the fire." | The same |

### From the community

| What | Source |
| --- | --- |
| "EQUIP a flame wall. FIRE to create a line of flame that moves forward, passing through the world", "and creating a wall of fire that blocks vision and damages players passing through it"; "HOLD FIRE to bend the wall in the direction of your crosshair." | [VALORANT Wiki, Blaze](https://wiki.playvalorant.com/en-us/Blaze) and [Phoenix](https://wiki.playvalorant.com/en-us/Phoenix) (Weird Gloop) |
| A wall that blocks vision; its missile goes through terrain, "leaving a path of fire on the ground"; held fire steers its direction and altitude towards the crosshair, and sent without, it can't be steered after | [VALORANT Wiki, Blaze](https://wiki.playvalorant.com/en-us/Blaze) |
| "Once the missile reaches its maximum distance, a wall of flame will start to rise from Phoenix's location", spreading along the path to its end; it burns from when the flame reaches you, at the same rate for all; after its duration it "rapidly falls"; Phoenix heals in it | The same |
| Cost 150 (200 before 5.12); uses 1; "Affects allies/self": "Yes (damage reduced for allies)" | The same |
| Equip 0.8 s (game files); deploy 0.125-0.75 s "depending on distance" and unequip 0.5 s (both estimated); length 1-21 m (estimated) | The same |
| Damage "1 per tick", 30 ticks a second, 225-240 in all (a range training bot); objects at half; duration 8 s | The same |
| Blaze: uses "1", cost "150", duration "8 s", damage "30/s" | [VALORANT Wiki, Phoenix](https://wiki.playvalorant.com/en-us/Phoenix) |
| "Maximum bend" 180 degrees/second (game files); its missile passes through terrain, steered towards the crosshair while fire's held; its wall "begins rising from Harbor's location" and spreads along the path | [VALORANT Wiki, High Tide](https://wiki.playvalorant.com/en-us/High_Tide) |
| A "4-meter height" (estimated); its projectile goes through terrain and drops its emitters to the floor, so the wall follows the terrain | [VALORANT Wiki, Toxic Screen](https://wiki.playvalorant.com/en-us/Toxic_Screen) |
| "Equip a flame wall." "Fire to create a line of flames that moves forward." "Hold fire to bend the wall in the direction of your crosshair." | [Liquipedia, Phoenix](https://liquipedia.net/valorant/Phoenix) |
| Cost 150; length 1-21 m; duration 8 s; 225-240 in all, 30 ticks a second; equip 0.8 s, deploy 0.125-0.75 s, unequip 0.5 s | [Mobalytics, Phoenix](https://mobalytics.gg/valorant/agent/phoenix/overview) |
| 150 credits, one charge, 8 s, 30 a second; the wall rises from where he cast it and spreads along the path | [NeuralBoost](https://neuralboost.gg/blog/valorant-phoenix-guide-abilities-heating-up-and-the-ult-nerf-in-patch-13-02), 19 September 2026 |

No source gives how fast the line bends (we take High Tide's), how high over the floor it runs (so
what it climbs and what it goes through), how far it can drop, how fast the wall spreads, how tall
or thick the wall is, how much less an ally burns, or whether bullets go through it. Ours are in
section 4. We read the wiki's "0.125-0.75 s" and "1-21 m" as one speed, 28 m/s, the longest run
taking 0.75 s; and its "225-240" at 30 a second as the far end of the longest wall starting to burn
0.5 s after Phoenix's end, so the wall spreads at 42 m/s. Both readings are ours.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| The run's speed and length | Public clips of Blaze sent down a straight corridor of known length, stepped frame by frame |
| How fast it bends | Clips of it bent hard on open ground, against the floor's lines |
| What it climbs and what it goes through | Clips of it sent up stairs, over boxes and through walls |
| The spread, the height and the thickness | Clips of the wall rising beside an agent, stepped frame by frame, and of agents walking through it |
| An ally's burn | A custom game's combat report, or a clip with an ally's health showing |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Blaze's charge | One, 150 credits, none free; in Team Deathmatch, back every 48 s (system 28) | Confirmed (150); community (one, 48 s) |
| The flame in hand | C puts it in a fifth slot, drawn in 0.8 s, with the move speed of a knife; C again, a number key, a plant or defuse, a death, or selling its charge puts it away unsent, with nothing spent; Q or E puts its own in hand instead, and C the flame in place of theirs | Community (0.8 s); estimate (the rest) |
| Sending it | The left button sends it as soon as it's drawn (held, as soon as it's ready), from the floor under his feet, the way the crosshair faces, level; its charge goes. The right button does nothing | Community |
| Bending it | While the left button's held from the send, the flame stays in hand and the line turns towards the crosshair at up to 180 degrees a second; let go, it runs straight on, and holding it again doesn't bend it. The gun is back 0.5 s after it's let go or the run's over. Another ability in hand, a gun drawn, a plant or defuse, or a death lets go of it too | Community (the bend, 0.5 s); confirmed (the gun back on letting go, Patch 5.01); estimate (180 degrees a second, High Tide's) |
| Its run | Along the floor at 28 m/s for 0.75 s, so 21 m, a point of its path every 4 ticks. Looking for the floor below from 0.9 m over the floor it last ran on, it climbs whatever's lower (a step, a box, a ramp) and runs through whatever's taller, on the floor under it; it runs down a ledge as deep as 10 m, and ends where it finds no floor that near | Community (21 m, 0.75 s); confirmed (through walls); estimate (one speed, 0.9 m, 10 m) |
| Its wall | Rising from his end of the run as the run ends, spreading along it at 42 m/s, so the far end of a 21 m wall half a second later; standing 8 s from rising, then gone. 4 m tall over its floor and 1 m thick, its ends rounded | Confirmed (8 s); community (rising from his end); estimate (42 m/s, 4 m, 1 m) |
| Who stands in it | Feet within half its thickness of its path, as far as it has spread, that edge pushed out by the body's half width (0.34 m), no more than 4 m above its floor there and no more than 0.5 m below it. A standing jump peaks at 0.85 m, so none gets out of it | Estimate |
| The burn | 30 a second to an enemy wherever in it they stand, through the shield as any hit, credited to Phoenix for the kill feed (`Blaze`), the kit's points and the score; a third of that to an ally; spawn protection keeps it off; it doesn't slow. Standing in it, 240 at his end and 225 at the far end of the longest | Confirmed (30 a second); community (allies less, 225-240); estimate (a third, no slow) |
| How it's given | Whole points, every 0.1 s, and what's left as they leave it or it falls | Estimate (ours: the reference gives a point a tick) |
| Inner Fire | Phoenix never burns in his own wall. His first touch of each starts a heal of 50, a point every 0.16 s for 8 s, which goes on if he leaves it; health alone, up to his most; it ends with his death or a new life | Confirmed (50, 0.16 s, going on after); community (the first touch); estimate (health alone) |
| Sight | Nothing shows through it, outlines included, and from inside it the screen is flame. Shots, moves and throws go through it | Community (it blocks vision); estimate (the rest) |
| Its look | A flame running over the floor with a line of fire behind it; the wall an orange sheet of flame rising over a quarter second wherever the fire reaches, with flames and lights along it, falling over 0.3 s | Estimate (ours) |
| Its sounds | A whoosh as the flame comes up in hand, a heavy whoosh as it's sent, a crack and a roar as the wall rises, and a crackle while it stands, heard as far as an ability | Estimate (ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** adds `Blaze` (the unequip; the run's flight, length and turn rate, and how far
  over and under the floor it looks; the wall's spread, duration, height, thickness and depth; the
  burn and an ally's share) and `InnerFire.blazeEvery`, each with its status and source. Blaze's
  `weapon` is the flame, and `unequip("blaze")` is 0.5 s. Its cost is confirmed now, from Patch
  5.12.
- **`WeaponConfig`** adds the flame (`flamewall`), an `ability` weapon (`ability = "blaze"`) for the
  fifth slot, as the fireball is: 0.8 s to draw, one send a magazine, no spread, no kick and no alt
  fire; never sold or dropped. It's the weapon the wall's burns are, for the kill feed.
  **`WeaponSim`** adds `keep`, which holds the flame in hand with nothing left to fire.
- **`AbilitySim`** plays Blaze. C puts the flame in hand as Q and E put theirs, in place of either.
  Sent, it's a `flame` cast from the feet the way the crosshair faces, and the kit is `steering` its
  wall (its slot) until `steerUntil`, when its run's over; `bend` in its summary meanwhile. Both are
  on the wire with the rest of the kit (**`PlayerCodec`**), and the client corrects them as it does
  the rest (**`PlayerController`**).
- **`PlayerSim`** keeps the flame in hand while fire's held after the send, and lets go of the wall
  as fire's let go or the run's over, the gun back 0.5 s later; another ability in hand, a gun
  drawn, a plant or defuse lets go of it too, and a death settles it with the rest of the kit.
- **`BlazeSim`** (new) runs a wall's run a tick at a time from its caster's input (`send`, `step`,
  `tick`, and `drift` for one nobody bends), as the server and the caster's client both do, and is
  the wall: `wall`, `reachAt`, `reachedAt`, `ends`, `standing`, `inside`, `nearest` and `burnRate`.
- **`FireSim`**'s Inner Fire heal takes its pace (`healed`, `healTime`).

### The server

- **`BlazeServer`** (new) runs each player's runs on their ticks, as their client predicts them,
  bent while their kit says so. It tells every client where each run's head is at each point of its
  path (the Ability remote's `flight`) and, as it ends, its `wall`: its path and when it rose. A run
  whose caster dies runs straight on, on the server's clock; one whose caster leaves goes with them.
  Each wall is lit as it rises (`FireServer.light`), and `VFLastWall` is the far end of the caster's
  last.
- **`FireServer`** lights any fire from a `Spec`: when it burns, who stands in it, its burn and an
  ally's share, its weapon for the kill feed, Inner Fire's pace, and the attribute that says where
  it is. Hot Hands' fires and Blaze's walls burn and heal the same way, each by its own numbers. A
  new round puts every fire out and tells every client so (`out`).
- **`Arena`** drops every run under way with each new round, a new mode and the course
  (`BlazeServer.clear`).

### The client

- **`BlazeView`** (new) runs your runs at once on your predicted ticks, through the level as the
  server runs them, bent while you bend them, and stands their walls as they end; if the server's
  wall stands somewhere else, the server's stands instead. Others' runs are drawn from their
  `flight` as the frame on your screen reaches them, and their walls from `wall`. A run is a flame
  running over the floor with a line of fire behind it; its wall rises from its caster's end and
  spreads to the far end as the server's does, an orange sheet of flame nothing shows through, with
  flames and lights along it, and falls once its 8 s are up. From inside it, the screen is flame;
  its crackle is heard every half second from the closest place it's reached.
- **`FireView`** glows your screen's edge as Blaze burns you, as Hot Hands does, and forgets every
  fire when the server says they're out.
- **`WeaponLooks`** draws the flame in hand as a tongue of fire over an open hand. **`AbilityHud`**
  keeps C lit while the wall's bent. **`BuyMenu`**'s Blaze panel adds its wall, its burn and its
  heal; Blaze is for sale.
- **`SoundConfig`** adds the flame's draw (`wallEquip`), the send (`wallSend`) and the rise
  (`wallRise`); it crackles as Hot Hands' fire does.

### Not here yet

- **Run it Back.** It stays dimmed and `NOT YET`.
- **Altitude.** The reference's line is steered up and down by the crosshair too; ours always runs
  on the floor, so it can't be sent across a gap or up a ledge taller than its hover.
- **Hover.** At 0.9 m, the run climbs the course's 0.5, 0.7 and 0.85 m jump boxes and its steps, and
  runs through the 1.0 m box and the 1.2 m low wall, its wall standing inside them.
- **Its last tick.** Fire held to the end lets go on the run's last tick, so that tick isn't bent
  (8 ms); a gun drawn lets go a tick late; and a run that ends early, out of floor, keeps the flame
  in hand until its 0.75 s are up or fire's let go.
- **Through the wall.** The health labels drawn over everything show through it, as through a cloud,
  and a flare's blind isn't stopped by it, as it isn't by a cloud.
- **Objects.** The reference's wall burns utility at half its rate; there's no utility here to burn.
- **Late joiners.** Someone who joins while a wall stands doesn't see it, though it burns them.
- **Its shape.** Each stretch of it is drawn upright from its lower floor to its height over its
  higher one, so on a slope or a ledge it steps, and under a low roof it shows through. The run, the
  bend and the wall are estimates until clips are stepped through.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | `Blaze`'s numbers and `InnerFire.blazeEvery`, each with its status and source; the flame as Blaze's weapon; `unequip` |
| `src/shared/Abilities/AbilitySim.luau` | Blaze played; the `flame` cast; `steering`, `steerUntil` and `bend` |
| `src/shared/Abilities/BlazeSim.luau` | New: the run, its bend, the floor it follows and where it ends; the wall, its spread, who stands in it and its burn |
| `src/shared/Abilities/FireSim.luau` | Inner Fire's heal at either pace |
| `src/shared/Weapons/WeaponConfig.luau`, `src/shared/Weapons/WeaponSim.luau` | The flame, an `ability` weapon for the fifth slot, last on the wire; `keep` |
| `src/shared/PlayerSim.luau` | The flame held while the wall's bent, and the gun back once it's let go |
| `src/shared/Net/PlayerCodec.luau`, `src/client/PlayerController.luau` | A wall being bent on the wire, and corrected as the rest of the kit is |
| `src/shared/Audio/SoundConfig.luau` | The flame's draw, the send and the rise |
| `src/server/BlazeServer.luau` | New: the runs, told to every client, and each wall lit as it rises |
| `src/server/FireServer.luau` | Any fire lit from its `Spec`, Hot Hands' or Blaze's, burning and healing by its own numbers; `out` |
| `src/server/Arena.luau`, `src/server/init.server.luau`, `src/server/AbilityServer.luau` | Runs dropped with each round and mode; the runs started and stepped |
| `src/client/BlazeView.luau` | New: runs on their way, walls standing and falling, the screen from inside one, and the crackle |
| `src/client/FireView.luau` | The glow as Blaze burns you, and every fire gone with `out` |
| `src/client/Combat/WeaponLooks.luau`, `src/client/BuyMenu.luau`, `src/client/AbilityHud.luau` | The flame in hand; Blaze's panel; C lit while the wall's bent |
| `src/client/AbilityEffects.luau`, `src/client/Combat/CombatHud.luau`, `src/client/init.client.luau` | The send heard, and others' walls rising; the flame on the HUD; the view started |
| `tests/blaze.luau` | New: Blaze's numbers, its charge, the flame in hand, sending and bending it, its run, its wall, the burn and the heal, and the wire |

## 7. Debug tools

- The caster's `VFLastWall` is the far end of their last wall, on its floor, in metres, set as it
  rises.
- `VFKit` ends in `equip` while the flame's in hand and `bend` while the wall's bent, as
  `C0/1 Q1/1 E2/2 X0/7 bend`.
- `Workspace.VFWalls` holds a `Run` model for each run on its way, its `Head` and its `Line`s, and a
  `Wall` model for each wall while it stands, its `Sheet`s, with its ends (metres) as its `From` and
  `To` attributes and `Moved` set on one of yours that the server's word moved.
- The `VFBlaze` screen is the flame over your view while your camera's in a wall.
- The kill feed names a kill by a wall `Blaze`, between Phoenix and whoever it killed.
- `VFTestButtons` 4096 presses C and 128 the left button, so a wall can be readied, sent and bent
  without a key or a mouse button; `VFTestYaw` turns the crosshair, which bends it.

## 8. Refinement loop

1. Step through clips of Blaze sent down a straight corridor of known length, and set `Blaze.flight`
   and `length`.
2. Step through clips of it bent hard on open ground, and set `turnRate`.
3. Watch it sent up stairs, over boxes and through walls, and set `hover` and `drop`.
4. Step through clips of the wall rising beside an agent, and set `spreadSpeed`, `height` and
   `thickness`.
5. Find an ally's burn in a combat report, and set `allyShare`.
6. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Blaze lit on Phoenix's card, the bar and the buy menu, for sale at 150.
- C draws the flame in 0.8 s, `EQUIP` on the bar; the left button sends the wall and, held, bends
  it, and the gun is back 0.5 s after it's let go or the run's over; C again, or a number key, puts
  it away, and Q or E swaps it for theirs.
- The run: 21 m down the lane in 0.75 s; bent round to the left; up onto the 0.85 m jump box and
  through the 1.00 m one; up the 30 degree ramp.
- The wall: rising from your feet and spreading to the far end in half a second, 4 m tall, gone 8 s
  later; nothing seen through it, and the screen flame from inside it; a dummy standing in it burns
  and dies, `Blaze` in the kill feed.
- Inner Fire: Phoenix hurt, then standing in his own wall, heals 50 over 8 s and takes no damage.
- A second player: the send heard, the run and the wall seen, the wall burning them as an enemy, a
  third as fast on Phoenix's side, and the orange glow at their screen's edge.

Section 36 of the [Studio checklist](../studio-checklist.md) covers these.
