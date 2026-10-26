# System 31: Hot Hands

Phoenix's second ability played here is Hot Hands, on Q since Patch 9.10: Q readies a fireball,
the left button throws it and the right button lobs it underhand, and where it meets the floor it
bursts into a pool of fire that burns enemies standing in it, allies less. Phoenix heals in it
instead, which is his passive, Inner Fire: this system makes that work too. It adds the fireball
in hand, its throw and lob, its flight off walls and ceilings to the floor, its fire spreading to
its radius no further than the walls round it let it, the burn by the point, credited to the
thrower for the kill, and Inner Fire's heal, which goes on after Phoenix leaves the fire.

As before, everything comes from public sources: four of Riot's patch notes and, for the numbers
Riot doesn't give (the fireball's equip and unequip, its air time, the fire's size, spread,
duration and damage a second), the VALORANT Wiki's pages on Hot Hands, Inner Fire, Phoenix,
projectiles and Brimstone's Incendiary, with Liquipedia and two press articles to cross-check. No
game files, memory or network traffic were used. The wiki marks some of its numbers as read from
the game's files by its editors, and its projectile classes as its own grouping; here they're the
wiki's numbers, labelled community. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **The fireball** (the wiki). "EQUIP a fireball. FIRE to throw a fireball that explodes after a
  set amount of time or upon hitting the ground, creating a lingering fire zone that damages
  enemies. ALT FIRE to lob." 0.8 s to equip, 0.7 s to put away, one use, 200 credits since Patch
  9.10 made it a basic ability.
- **Its flight** (the wiki). It "detonates as soon as it comes into contact with horizontal
  terrain"; it "has a set timer and will immediately drop down vertically if still airborne until
  it hits horizontal terrain", the timer being a "maximum air time" of 1.5 s. The wiki's page on
  projectiles groups the throw as "Class 2" (speed 1800, gravity 0.3) and the lob as "Class 0.7"
  (630, 0.3), with no units given. Brimstone's Incendiary, a grenade of the same kind, "bounces
  against surfaces, reducing its arc and velocity with each bounce."
- **Its fire** (the wiki). It grows from the burst in a circle out to 4.5 m in about 0.75 s (both
  the wiki's own estimates), lasts 4 s from the burst, and then "disappears instantly". "The zone
  will always deal damage to agents at the same rate": a point a tick, 60 ticks a second, so
  standing in it from the burst takes 240, and from when it's full size 195.
- **How high it reaches** (Patch 0.50). "Height required to jump out of all damaging area denial
  abilities 80 >> 120": since then, no jump clears it.
- **Who it hurts** (the wiki). "Affects allies/self": "Yes (damage reduced for allies)", with no
  number. Phoenix "will heal himself instead of taking damage".
- **Inner Fire** (Patch 9.10, Patch 1.0 and the wiki). Phoenix "applies a Heal over time to
  himself whenever he touches his flames which persists even if he leaves the fire": 50 in all, a
  point every 0.08 s (Patch 1.0), so 4 s, starting "upon first contact with the ability". The
  wiki doesn't say whether two heals stack, whether one heals past 100, or whether it mends a
  shield.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Height required to jump out of all damaging area denial abilities 80 >> 120" | [VALORANT Patch Notes 0.50](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-50), 12 May 2020 |
| "Snake Bite, Fireball, and Incendiary damage tick speed increased (total damage per second unchanged)" | The same |
| "Blaze damage: 15 every 0.25s >>> 1 every 0.033 seconds"; "Blaze healing: 3 every 0.25s >>> 1 every 0.16 seconds"; "Hot Hands healing: 3 every 0.25s >>> 1 every 0.08s." | [VALORANT Patch Notes 1.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-0/), 1 June 2020 |
| "we've matched the damage/healing values to be half as effective as Hot Hands, primarily so that the total healing output of these two abilities is at parity (50 health each)." | The same |
| Hot Hands: "Updated the HoT model to match recent changes to the DoT abilities." | The same |
| "Bullet tagging changed from 75% slow >>> 72.5% slow" | [VALORANT Patch Notes 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/), 22 June 2021 |
| Hot Hands "Changed to a non-signature ability"; "Cost 200 credits" | [VALORANT Patch Notes 9.10](https://playvalorant.com/en-US/news/game-updates/valorant-patch-notes-9-10), 19 November 2024 |
| "Phoenix now applies a Heal over time to himself whenever he touches his flames which persists even if he leaves the fire." | The same |

### From the community

| What | Source |
| --- | --- |
| "EQUIP a fireball. FIRE to throw a fireball that explodes after a set amount of time or upon hitting the ground, creating a lingering fire zone that damages enemies. ALT FIRE to lob." | [VALORANT Wiki, Hot Hands](https://wiki.playvalorant.com/en-us/Hot_Hands) (Weird Gloop) |
| Cost "200"; uses 1; deployment "Class 2 Projectile; Class 0.7 Projectile (underhand)"; "Affects allies/self": "Yes (damage reduced for allies)" | The same |
| Equip "0.8 seconds"; Unequip "0.7 seconds"; Maximum air time "1.5 seconds"; Radius "4.5 meters" ("not confirmed by game files"); Duration "4 seconds" | The same |
| Damage "1 per tick", ticks "60 per second", "195-240" in all; a "0.75-second spread time" and "3.25 seconds at full size" (both estimated there) | The same |
| It "detonates as soon as it comes into contact with horizontal terrain"; it "will immediately drop down vertically if still airborne until it hits horizontal terrain" | The same |
| "The zone will always deal damage to agents at the same rate"; "Phoenix will heal himself instead of taking damage if he comes into contact with Hot Hands." | The same |
| "Healing is applied upon first contact with the ability with 1 HP ticks spread out evenly over the full healing duration."; 50 HP for each of his fires | [VALORANT Wiki, Inner Fire](https://wiki.playvalorant.com/en-us/Inner_Fire) |
| Hot Hands "60/s", "3.25 s (minimum at full size)"; Inner Fire: "PASSIVELY Heal Phoenix instead of taking damage after standing in Phoenix's own fire." | [VALORANT Wiki, Phoenix](https://wiki.playvalorant.com/en-us/Phoenix) |
| Class 2: speed 1800, gravity 0.3; Class 0.7: 630, 0.3, "All underhand throws"; "Projectile classes are not official VALORANT terminology" | [VALORANT Wiki, Projectile](https://wiki.playvalorant.com/en-us/Projectile) |
| The Incendiary "bounces against surfaces, reducing its arc and velocity with each bounce"; "Affects allies/self": "Yes (damage reduced)"; radius "4.5 meters", "60 per second" | [VALORANT Wiki, Incendiary](https://wiki.playvalorant.com/en-us/Incendiary) |
| Hot Hands "Maximum heal: 50 HP", "Duration: 4s" | [Liquipedia, Phoenix](https://liquipedia.net/valorant/Phoenix) (dated: Hot Hands is still his signature there) |
| "Phoenix will heal for 12 health per second while the ability is active." | [Upcomer](https://upcomer.com/how-much-does-phoenix-heal-in-valorant-explained), Warren Younger, 5 December 2022 |
| Hot Hands "60 DPS (15 damage/0.25 seconds)", "4 second duration" | [Gamer Journalist](https://gamerjournalist.com/valorant-agents-ability-damage/), Cole Andrews, 25 April 2020 (before Patch 0.50's quicker ticks) |

No source gives the units of the projectile classes, the gravity they're a share of, how a bounce
goes, how big the fireball is, how much less an ally burns, how high a wall has to be to stop the
fire, or how far below the burst it reaches. Ours are in section 4. We read the classes as
centimetres a second and a share of Unreal Engine's default gravity, which puts a level throw's
burst about 18 m ahead; that reading is ours.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| The throw's and the lob's arcs, and where each bursts on open ground | Public clips of Hot Hands thrown level on flat ground, stepped frame by frame against a map's known distances |
| The fire's edge against walls and round a corner | Clips of the fire burning against a wall, a box and a doorway |
| An ally's burn | A custom game's combat report, or a clip with an ally's health showing |
| A bounce | Clips of it thrown into a wall and a ceiling |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Hot Hands' charge | One, 200 credits, none free; in Team Deathmatch, back every 54 s (system 28) | Confirmed (200); community (one, 54 s) |
| The fireball in hand | Q puts it in a fifth slot, drawn in 0.8 s, with the move speed of a knife; Q again, a number key, a plant or defuse, a death, or selling its charge puts it away unthrown, with nothing spent; E puts the flare there instead, and Q the fireball in place of the flare | Community (0.8 s); estimate (the rest) |
| The throw | The left button throws it, the right button lobs it, as soon as it's drawn (held, as soon as it's ready); its charge goes, and the gun is back in hand 0.7 s later | Community |
| Its flight | From the eye at 18 m/s thrown and 6.3 m/s lobbed, falling at 0.3 of 9.8 m/s/s. Level from the eye it bursts about 18 m ahead after about a second, and lobbed about 6.4 m ahead | Community (the classes); estimate (their units and 9.8) |
| What it meets | It bursts on anything level enough (its up at least 0.7, about 45 degrees) and bounces off anything steeper, walls and ceilings, keeping half its speed. Players and dummies don't stop it | Community (bursts on horizontal terrain, bounces); estimate (the threshold, the half, players) |
| Its air time | 1.5 s; then it stops going anywhere but down and falls at 9.8 m/s/s to the floor, sliding down anything too steep to burst on | Community (1.5 s, the drop); estimate (9.8, the slide) |
| Given up on | Meeting no floor in 5 s, it's gone, and there's no fire | Estimate |
| Its fire | On the floor under the burst, out to 4.5 m, spreading evenly over 0.75 s, burning for 4 s from the burst, then gone at once | Community |
| Walls | Each way round (24 of them, with a straight edge between each two) it reaches no further than the first wall 0.5 m up; a ramp up doesn't stop it, nor a kerb under 0.5 m | Estimate |
| Who stands in it | Feet over it, its edge pushed out by the body's half width (0.34 m), no more than 1.2 m above its floor and no more than 0.5 m below. A standing jump peaks at 0.85 m, so none gets out of it | Confirmed (1.2 m); estimate (the rest) |
| The burn | 60 a second to an enemy wherever in it they stand, through the shield as any hit, credited to the thrower for the kill feed (`Hot Hands`), the kit's points and the score; a third of that to an ally; spawn protection keeps it off; it doesn't slow | Community (60, allies less); estimate (a third, no slow, as Riot calls its tagging "Bullet tagging") |
| How it's given | Whole points, every 0.1 s, and what's left as they leave it or it goes out | Estimate (ours: the reference gives a point a tick) |
| Inner Fire | Phoenix never burns in his own fire. His first touch of each starts a heal of 50, a point every 0.08 s for 4 s, which goes on if he leaves it; health alone, up to his most; it ends with his death or a new life. Two fires, two heals | Confirmed (50, 0.08 s, going on after); community (the first touch); estimate (health alone, two at once) |
| Its look | The fireball a glowing orange ball; its burst a flash; its fire a glowing orange floor as far as it has spread, with flames on it and its light; your screen's edge glowing orange as you burn | Estimate (ours) |
| Its sounds | A whoosh as it comes up in hand, a swish as it's thrown, a thump as it bursts and a crackle while it burns, heard as far as an ability | Estimate (ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** adds `HotHands` (the unequip, the flight, the bounce and the floor, the
  fire's radius, spread, duration and reach up, down and against walls, the burn and an ally's
  share) and `InnerFire` (the heal and its interval), each with its status and source. Hot Hands'
  `weapon` is the fireball, and `unequip(id)` says how soon the gun's back after a throw.
- **`WeaponConfig`** adds the fireball, an `ability` weapon (`ability = "hothands"`) for the fifth
  slot, as the flare is: 0.8 s to draw, one throw a magazine, no spread and no kick; never sold or
  dropped. It's the weapon its fire's burns are, for the kill feed.
- **`AbilitySim`** plays Hot Hands and Inner Fire. Any ability with a weapon of its own, outside
  the ultimate, is one its key puts in hand (`held`): Curveball's flare and now Hot Hands'
  fireball, either in place of the other. `thrown` takes whether alt fire threw it: a `flare`
  cast curving that way round, or a `fireball` cast, `lob` for alt fire.
- **`PlayerSim`** has the gun back after a throw as soon as the ability thrown says.
- **`FireballSim`** (new) flies a throw a tick at a time: `throw`, `step` through the world, and
  `fly` until it bursts or is given up on. Its path is a few `keys`, each a start, a velocity and
  a fall (the throw, each bounce, the drop and the burst), so `at` draws it anywhere along it
  exactly, from the keys alone.
- **`FireSim`** (new) is the fire: `reaches` against walls, `radiusAt`, `burning`, `ends`,
  `inside`, `edge` for drawing it, `burnRate`, Inner Fire's `healed`, and `owe`, which keeps what
  a burn owes someone between frames and says when its whole points go.

### The server

- **`FireServer`** (new) hears each `fireball` cast, flies it through the level at once, works out
  its fire's reach and tells every client its `flight`: its keys, `land` (how long after the throw
  it bursts), `point` (its fire's floor) and `reaches`. From the burst, each frame, it burns those
  standing in it from where the server's simulation has them, and starts Inner Fire's heal on the
  thrower's first touch. The thrower's `VFLastFire` is where their last fire burns (metres).
- **`CombatServer`** adds `burn`, a hit credited to its attacker that doesn't slow, and offers
  `teammates`.
- **`Arena`** puts every fire out with each new round, a new mode and the course.

### The client

- **`FireView`** (new) draws each fireball in the air as a glowing orange ball, its burst as a
  flash, and its fire as a floor of glowing wedges spreading as the server's does, with flames
  lit on it as it reaches them, its light and its crackle. Yours fly at once as you throw them,
  through the level as the server's do; if the server's `flight` puts its fire somewhere else, the
  server's goes instead. Others' are drawn from their `flight` as the frame on your screen reaches
  the throw. While you're burning, your screen's edge glows orange.
- **`WeaponLooks`** draws the fireball in hand as a ball of fire with a flame on top.
- **`BuyMenu`**'s Hot Hands panel adds its fire, its burn and its heal; Hot Hands is for sale.
- **`SoundConfig`** adds the fireball's draw, throw and burst, and its fire's crackle.

### Not here yet

- **Blaze and Run it Back.** They stay dimmed and `NOT YET`.
- **Objects.** The reference's fire burns utility at half its rate; there's no utility here to
  burn.
- **Late joiners.** Someone who joins while a fire burns doesn't see it, though it burns them.
- **Slopes and steps.** The fire is drawn flat at the height it burst, whatever is under it.
- **Its shape.** The arcs, the bounce and the walls are estimates until clips are stepped through.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | `HotHands` and `InnerFire`'s numbers, each with its status and source; the fireball as Hot Hands' weapon; `unequip` |
| `src/shared/Abilities/AbilitySim.luau` | Hot Hands and Inner Fire played; an ability in hand by its key, either for the other; the `fireball` cast and its `lob` |
| `src/shared/Abilities/FireballSim.luau` | New: the flight, its bounces and its drop, and its keys |
| `src/shared/Abilities/FireSim.luau` | New: the fire's reach, spread and life, who stands in it, the burn, the heal and what's owed |
| `src/shared/Weapons/WeaponConfig.luau` | The fireball, an `ability` weapon for the fifth slot, last on the wire |
| `src/shared/PlayerSim.luau` | The gun back after a throw by the ability thrown |
| `src/shared/Audio/SoundConfig.luau` | The fireball's draw, throw and burst, and the fire's crackle |
| `src/server/FireServer.luau` | New: the flight told to clients, the fires, the burns, Inner Fire's heals and `VFLastFire` |
| `src/server/CombatServer.luau` | `burn` and `teammates` |
| `src/server/Arena.luau`, `src/server/init.server.luau`, `src/server/AbilityServer.luau` | Fires put out with each round and mode; the fires started and stepped |
| `src/client/FireView.luau` | New: fireballs in the air, their bursts and their fire, and the glow as you burn |
| `src/client/Combat/WeaponLooks.luau`, `src/client/BuyMenu.luau` | The fireball in hand; Hot Hands' panel |
| `src/client/AbilityEffects.luau`, `src/client/AbilityHud.luau`, `src/client/Combat/CombatHud.luau`, `src/client/init.client.luau` | Flights left to FireView; the fireball in hand on the bar and the HUD; the view started |
| `tests/hothands.luau` | New: Hot Hands' numbers, its charge, the fireball in hand, its flight, its fire, the burn and the heal, and the wire |

## 7. Debug tools

- The thrower's `VFLastFire` is the floor under their last fireball's burst, in metres, set as it
  bursts.
- `VFKit` ends in `equip` while the fireball is in hand, as `C0/1 Q1/1 E2/2 X0/7 equip`.
- `Workspace.VFFires` holds a `Fireball` ball for each fireball in the air, a `Burst` for each
  burst while it flashes, and a `Fire` model for each fire while it burns: its `Floor` wedges, its
  `Glow` and its `Flame`s.
- The kill feed names a kill by fire `Hot Hands`, between the thrower and whoever it killed.
- `VFTestButtons` 8192 presses Q, 128 the left button and 256 the right, so a fireball can be
  readied and thrown without a key or a mouse button; `VFTestPitch` aims it up or down.

## 8. Refinement loop

1. Step through clips of Hot Hands thrown level and lobbed on open ground, and set
   `HotHands.speed`, `lobSpeed`, `gravity` and `worldGravity` until it bursts where the reference's
   does.
2. Step through clips of it thrown into walls and ceilings, and set `bounce` and `floor`.
3. Watch the fire against walls and boxes, and set `wallHeight`, `depth` and the sectors.
4. Find an ally's burn in a combat report, and set `allyShare`.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Hot Hands and Inner Fire lit on Phoenix's card, the bar and the buy menu, Hot Hands for sale at
  200.
- Q draws the fireball in 0.8 s, `EQUIP` on the bar; the left button throws it and the right
  lobs it, and the gun is back 0.7 s later; Q again, or a number key, puts it away, and E swaps
  it for the flare.
- The flight: a level throw bursting about 18 m ahead on the course, a lob about 6.4 m; one into a
  wall coming back off it; one thrown up dropping straight down once its 1.5 s are up.
- The fire: spreading to 9 m across over 0.75 s, stopped by a crate but not by a kerb, out after
  4 s; a dummy standing in it burns and dies, `Hot Hands` in the kill feed.
- Inner Fire: Phoenix hurt, then standing in his own fire, heals 50 over 4 s and takes no damage.
- A second player: the throw heard and seen, the fire burning them as an enemy, a third as fast
  on Phoenix's side, and the orange glow at their screen's edge.

Section 35 of the [Studio checklist](../studio-checklist.md) covers these.
