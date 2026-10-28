# System 59: heights, and Wharf rebuilt with them

Wharf (system 58) was flat, and laid out by eye: a plaza 30 m across, sites 28 m wide with their
cover set well apart, and nowhere higher than the floor. It felt empty and random. This system gives
the spike maps heights, and rebuilds Wharf to measurements. A map can now have a room raised off the
ground, a deck over a room's floor that leaves the floor open under it (a heaven over its hell),
stairs and ramps from one floor to another, a railing where a floor drops away, and a window through
a wall. Wharf now has a heaven over A with hell under it, a window room looking down mid, a raised
platform at the back of B, a long lane to B and a room by B with a door and a window to vault
through. Its sites, chokes, lanes and cover follow what Counter-Strike's maps measure, and so do the
times each side takes to reach each site.

Each part of Wharf is built the way a well-known part of the reference's maps or Counter-Strike's
is: A's heaven and hell like Ascent's A, mid's window like Mirage's, B's room with a door and a
window like Bind's hookah, and B's long lane like Dust II's long A. They follow those parts'
structure (what joins what, which way it faces, how high it stands), measured, but none is traced,
so the map stays our own.

Everything comes from public sources: Valve's developer wiki for Counter-Strike's player and map
metrics, the Level Design Book, design analyses on Game Developer and Dignitas, Dave Johnston's
notes on making Dust 2, and The Spike on how Split was designed. Counter-Strike's maps are measured
from awpy, an open-source Python library that publishes each map's navigation areas (rectangles with
place names) and how they connect. Its data was read in a scratch folder and isn't in the
repository. No Valorant game files, memory or network traffic were used, and nothing was read from
the live game. No Riot image, model or sound is in the repository.

## 1. Observable behaviour

- Each site has two or three ways in for the attackers, each through a narrow door or the end of a
  lane, and the defenders get there first.
- Sites are full of cover. Nowhere on a site is far from something to hide behind.
- Some places are higher than the floor round them: a heaven over a site that looks down on its
  plant area, reached by stairs, with a railing in front and a gap to drop through, and hell under
  it; a window over mid; a platform at the back of a site.
- Lanes mix lengths: a long lane for long shots, and halls that bend for close ones.
- No raised place sees into the attackers' spawn, where the round starts.

## 2. Publicly documented details

### Where things go, and why

| What | Source |
| --- | --- |
| "The bombsites are located closer to the CT's spawn point." "This is on purpose so that they can hold their position and plan a strategy before the terrorists arrive." | Hugues Barlet, ["Why is de_dust2's level design so popular?"](https://www.gamedeveloper.com/design/why-is-de_dust2-s-level-design-so-popular-), Game Developer |
| Chokepoints, doors that "force the team to go one by one through the door" | The same |
| "There are only three pathways within the level." Each of Dust II's sites has two ways in, each a choke point | ["Analyzing level layouts to improve level design in competitive FPS"](https://gamedeveloper.com/design/analyzing-level-layouts-to-improve-level-design-in-competitive-fps), Game Developer |
| "Too many paths to a location make defense of objectives too difficult for players." "Having too many choke points makes choices from either team less meaningful." | The same |
| "In multiplayer PvP maps, distribute 3-4 chokepoints across the map, one chokepoint per lane." "It should be impossible to cover all chokepoints from a single point." | The Level Design Book, [Balance](https://book.leveldesignbook.com/process/combat/balance) |
| "Most multiplayer combat games try to balance their maps with a mix of short and long sightlines." | The same |
| "Does the defending player have a height advantage?" | The same |
| "Every advantage needs a weakness." | Dave Johnston, ["Keeping CS Maps Fair"](https://www.johnsto.co.uk/blog/keeping-cs-maps-fair/) |
| In Dust 2's beta, B got a raised platform and more crates, placed to "break the space up and offer more gameplay opportunities"; its arches frame areas and block lines of sight | Dave Johnston, ["The Making Of: Dust 2"](https://www.johnsto.co.uk/design/making-dust2) |
| Split's towers: "Could we create an off-site position that was essential to defending or capturing each site." | ["The design behind Split explained"](https://www.thespike.gg/valorant/news/the-design-behind-split-explained/192), The Spike, from Riot's dev blog |
| Ascent's A heaven is "a huge spot for vision"; attackers check "under Heaven". A's ways in are catwalk, A main and mid | ["An Attacker's Guide to Ascent"](https://dignitas.gg/articles/an-attackers-guide-to-ascent-for-valorant), Dignitas |
| On Train, a CT holding connector gets there "just over 5 seconds earlier" than a T; rotation times, angles and choke points make a map CT-sided | ["What makes a map CT sided"](https://dignitas.gg/articles/what-makes-a-map-ct-sided-the-factors-that-define-map-design), Dignitas |

### Metrics

| What | Source |
| --- | --- |
| The player 72 units tall and 32 wide, standing; steps up to 18 units; a jump climbs 54 units; slopes walkable up to 45.573 degrees; a stair's step at most 18 units high and at least 16 deep | Valve Developer Community, [CS:GO Mapper's Reference](https://developer.valvesoftware.com/wiki/Counter-Strike:_Global_Offensive/Mapper%27s_Reference) |
| A big crate at least 72 units high, seen over only by jumping; a small one at most 44, a player behind it always seen | The same |
| "Maps, architecture, and some prop models use a scale of roughly 1 foot ≈ 16 units." | Valve Developer Community, [Dimensions](https://developer.valvesoftware.com/wiki/Dimensions_(Half-Life_2_and_Counter-Strike:_Source)) |
| "The minimum hallway width should be at least double the player width"; stairs of 30 to 35 degrees | The Level Design Book, [Metrics](https://book.leveldesignbook.com/process/blockout/metrics) |
| Each map's navigation areas, with their place names (BombsiteA, LongA, Heaven, Balcony and so on) and corners, and the graph of how they join | [awpy](https://awpy.readthedocs.io/en/latest/data.html) 1.3.1, its map data |

## 3. What can be measured, and how

Counter-Strike's maps were measured from awpy's navigation areas, at 0.025 m a unit: the player's 72
units as our standing player's 1.80 m, so each map is measured against its player as ours is against
ours (Valve's 16 units a foot would make everything about a quarter smaller). A site is its
BombsiteA or BombsiteB areas. Its walkable floor is their area; how open it is comes from a raster
of 8 units, as the widest circle clear of anything that isn't site floor and the share of the floor
more than 4 m from such a thing. A place's width is across its areas' narrower sides. A run is the
shortest way along the graph from the middle of a side's spawn to the site, at 250 units a second,
the speed with the knife out; a drop is one-way. Times on maps whose graph has one-way links in the
way came out unreachable or far off (Mirage's A, Nuke's B, Overpass, Ancient's B and Train's A) and
are left out.

| Map | Site | Its walkable floor | Widest open circle, radius | More than 4 m from anything | Ts' run | CTs' run | CTs first by |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Dust II | A | 151 m2 | 3.7 m | 0% | 18.7 s | 7.7 s | 11.0 s |
| Dust II | B | 456 m2 | 5.7 m | 8% | 15.2 s | 8.3 s | 7.0 s |
| Mirage | A | 387 m2 | 4.9 m | 2% | | | |
| Mirage | B | 540 m2 | 4.3 m | 0% | 16.7 s | 10.4 s | 6.2 s |
| Inferno | A | 349 m2 | 4.0 m | 0% | 15.5 s | 9.0 s | 6.5 s |
| Inferno | B | 391 m2 | 3.4 m | 0% | 15.5 s | 6.7 s | 8.8 s |
| Ancient | A | 363 m2 | 4.8 m | 2% | 13.0 s | 2.5 s | 10.5 s |
| Ancient | B | 223 m2 | 4.8 m | 2% | | | |
| Nuke | A | 336 m2 | 5.1 m | 4% | | | |
| Nuke | B | 507 m2 | 2.3 m | 0% | | | |
| Overpass | A | 315 m2 | 4.3 m | 0% | | | |
| Overpass | B | 182 m2 | 3.4 m | 0% | | | |
| Vertigo | A | 276 m2 | 4.4 m | 0% | 13.5 s | 6.2 s | 7.3 s |
| Vertigo | B | 371 m2 | 3.4 m | 0% | 11.2 s | 3.6 s | 7.6 s |
| Anubis | A | 223 m2 | 4.1 m | 0% | 17.0 s | 9.6 s | 7.4 s |
| Anubis | B | 239 m2 | 4.7 m | 1% | 13.0 s | 8.9 s | 4.1 s |
| Train | A | 628 m2 | 5.5 m | 2% | | | |
| Train | B | 461 m2 | 3.9 m | 0% | 19.3 s | 15.4 s | 3.8 s |
| **Wharf** | **A** | **388 m2** | **4.4 m** | **0%** | **14.3 s** | **7.8 s** | **6.5 s** |
| **Wharf** | **B** | **337 m2** | **4.0 m** | **0%** | **13.2 s** | **7.9 s** | **5.3 s** |

So a site has 150 to 630 m2 of floor (about 360 in the middle), its widest circle clear of
everything 2.3 to 5.7 m in radius (4.3 in the middle), and at most 8% of its floor more than 4 m
from anything. The CTs get to a site 3.8 to 11 s before the Ts (7.3 s in the middle), the Ts taking
11 to 19 s and the CTs mostly 6 to 10. Wharf's own numbers are measured the same way by the offline
tests, on its parts in three dimensions (section 5).

Raised places, measured as their areas' height over their site's floor and their middle's distance
from the site's middle:

| Map | Place | Over the site | From its middle |
| --- | --- | --- | --- |
| Inferno | Balcony, over A | 2.6 m | 14 m |
| Anubis | Heaven, over A | 2.9 m | 10 m |
| Dust II | Hole, by B | 2.9 m | 13 m |
| Mirage | Balcony | 3.2 m | 13 m |
| Mirage | Scaffolding | 3.3 m | 9 m |
| Vertigo | B platform | 3.0 m | 18 m |
| Train | B platform | 1.5 m | 15 m |
| Nuke | Hut roof, over A | 4.0 m | 8 m |
| **Wharf** | **Heaven, over A** | **3.2 m** | **11 m** |
| **Wharf** | **B's platform** | **1.6 m** | **12 m** |

And widths, as the median across a place's areas:

| What | Places | Width |
| --- | --- | --- |
| Doors and narrow ways | Dust II's B doors, catwalk and upper tunnel, Mirage's connector and tunnel, Inferno's apartments, Ancient's tunnel, Vertigo's connector | 2.4 to 3.6 m |
| Lanes | Dust II's middle, Inferno's middle and banana, Ancient's middle, ramp and alley, Anubis's main, Mirage's palace alley and T ramp | 4.4 to 5.6 m |
| Long lanes | Dust II's long A, Overpass's alley, Mirage's middle | 7.2 to 9.2 m |

| What | How |
| --- | --- |
| Whether every floor is reached, and left | The offline tests, on Wharf's parts in three dimensions (tests/heights.luau) |
| Each side's run to each plant area | The same, running with the knife (6.75 m/s); it prints them |
| What the raised places see | The same: lines from every metre of each raised place, jumping, to every metre of the attackers' spawn |
| How open the sites are | The same, as Counter-Strike's were measured |
| How it plays | In Studio: section 63 of the [Studio checklist](../studio-checklist.md), and playtests |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| The defenders first | By 6.5 s at A and 5.3 s at B; the attackers take 14.3 and 13.2 s, the defenders 7.8 and 7.9 | Confirmed (the sites nearer the CTs, Barlet); measured (Counter-Strike's 3.8 to 11.0 s); ours (measured offline) |
| Our band for it | The defenders 5 to 9 s first, in 6 to 9 s, the attackers in 12 to 17 | Estimate, the middle of what Counter-Strike's sites measure |
| Ways into a site | A: A main's door and A short from the link, and the defenders' way from the back and heaven. B: B long, hookah's door and its window, and the defenders' way from the back and the platform | Community (two ways in a site, one choke per lane) |
| Chokes | 3 m doors (A main's, A short, hookah's), a 3 m window, 4 m doors to B long, and mid's 4 m jog | Measured (Counter-Strike's doors 2.4 to 3.6 m); estimate (ours) |
| Lanes | 5 to 8 m: A main and its hall 6, mid 7, the market 8, top mid and hookah 5; B long 8 m wide and 48 m long | Measured (Counter-Strike's lanes 4.4 to 5.6 m, long lanes 7.2 to 9.2); estimate |
| Sites | 24 by 22 m each, with 388 and 337 m2 of floor clear of cover | Measured (150 to 630 m2) |
| Cover on a site | Nowhere more than 4.4 m (A) or 4.0 m (B) from something, and under half a percent of either more than 4 m from it | Measured (Counter-Strike's widest circles 2.3 to 5.7 m; 0 to 8% over 4 m) |
| Heaven | A room 3.2 m up at A's back, 11 m from the plant area's middle, its deck railed but for a 4 m gap at its east end to drop through, hell under it; stairs up from the defenders' side and others from the site | Measured (Counter-Strike's 2.6 to 3.3 m, 9 to 14 m off); community (Ascent's heaven and hell); estimate |
| The window | A room 3 m up on the defenders' side of mid, its frame 4 m wide, from 1.3 to 2.6 m over its floor, too high to climb; stairs up from the defenders' mid | Community (Mirage's window); estimate (its heights) |
| B's platform | 1.6 m up across B's back, a ramp to it from the site and another from the defenders' hall, no railing: a drop to the site | Measured (Train's B platform 1.5 m); community (Dust 2's raised platform at B) |
| Hookah | A roofed room off the market with a 3 m door onto B and a 3 m window, its sill 0.75 m up, to jump through | Community (Bind's hookah); estimate |
| A weakness for each height | Heaven taken from the site's stairs and seen from all of the site; the window seen from all of mid's lane; the platform open to the site and dropped from | Confirmed (Johnston's "Every advantage needs a weakness") |
| No sight into the attackers' spawn | From any raised place, jumping: 0 of 81,216 lines | Ours (measured offline) |
| Stairs | 3 to 3.2 m up over 8 m, 20.6 to 21.8 degrees, under steps of 0.2 m at most; the slope under them is what's walked on | Community (the book's stairs at 30 to 35 degrees; ours shallower); estimate |
| Ramps | 1.6 m over 6 m, 15 degrees | Estimate, under the movement's 46 degrees |
| Railings | 1.3 m, as low cover: a standing player's eye over it, a crouching one hidden | Estimate, as low cover (system 25) |
| Decks | 0.3 m thick, 2.9 m over the floor under them: room to stand and jump | Estimate |
| A wall's height | 5 m over the highest floor within 4 m of it, so the walls round a raised room rise with it | Estimate |
| The same structure as known parts, none traced | Heaven and hell (Ascent's A), the window (Mirage's), hookah (Bind's), B long (Dust II's long A) | Ours |

## 5. Design

### Heights in a map's plan

A room can stand at a height `y`: its floor is built from a metre under the ground up to it. Where
rooms overlap, the floor is the highest one's, so a platform can stand in a bigger room. A deck is a
floor 0.3 m thick at a height over another room's floor, which stays open under it. A flight runs
from its foot's floor up to its head's, one way across its rectangle, and is built as a wedge,
Roblox's WedgePart, turned to rise its way. A flight of stairs hides its wedge under steps for show,
none more than 0.2 m over the last, so it looks like stairs and walks like a ramp. A raised room or
a deck can ask for a railing on any of its sides, and gets one wherever the floor just beyond that
side is more than 0.5 m below it. A window is an opening through the wall's 1 m cells, from its sill
up to its top: the wall is built under the sill and over the top. A wall stands 5 m over the highest
floor within 4 m of it, so the walls round a raised room rise with it, and a roof or lintel stands
on the walls round its room. Cover stands on the floor under its middle.

The height of the floor anywhere is the flight's slope there, or else its room's; the floors anyone
can stand on there are that and any deck's over it. The server builds the wedges, the minimap draws
raised floors, decks and flights lighter than the floor, and a Team Deathmatch life starts only
where the floor is level all round. Outpost, Quarry and Foundry have no heights and are built
exactly as before.

### The layout

North (up) is the defenders' end and south the attackers', A west and B east. Each character is 2 m:
`#` wall, `.` floor, `=` a spawn's door, `^` a raised floor, `_` a deck over a floor, `/` stairs or
a ramp, `w` a window, `a` and `b` the plant areas, `s` spawn spots, `*` where the spike starts, and
the kit's pieces: `c` crate, `C` crate stack, `K` container, `o` barrels, `p` planter, `h` hedge,
`t` tree.

```
######################################################
######################..........######################
######################...sssss..######################
##########.......c...==........==.................####
##########...........==........==.................####
##########.............................o..........####
##########...#########..........#########..####///####
##########...#############==#############..####///####
##########...##########...........#######..####///####
###c^^####...##########o..........#######..####^^^####
###^^^////...############////##...#######..####^^^####
###^^^////...############////##...#######..####^^^####
#______c_....############////##...#######..///^^^^^^^#
#________..c.############////##...#######..///^^^^^^^#
#//..........###########c^^^^^#...#######.....^^^^^c^#
#//aaaaaaa...###########^^^^^^#...#######.o..........#
#//aaaaaaaC..###########^^^^^^#...#######..bbbbbb....#
#//aaKKKaa...###########^^^^^^#.c.####o....bbbbbbC...#
#..aaKKKaa...###########^^^^^^#...####.....bbcCbb....#
#..caaaaaa.o.###########^^^^^C#...####..w..bbbbbb....#
#.................c...##^^ww^^#...####..w..bbbbbb....#
#...Cc................o............C......c.......KK.#
#........KKK.#.......................................#
##..##################........tt.........########....#
##..##################...............c...########....#
##...#################.hh.........###############...c#
##...#################.........c..###############....#
##o..#################............###############....#
##...####################....####################....#
##...####################....####################....#
##...####################C...####################....#
##..c####################...p####################....#
##...####################....####################....#
##...####################....####################....#
##...KKK...##############p...####################....#
##.........##############....####################K...#
##c........##############.......#################K...#
########...##############.......#################....#
########...#################....#################....#
########C..#################....#################....#
########...#################...C#################....#
########...#################....#################....#
########...#################....#################....#
########..o#############.KK.....#################....#
########...#############........#################....#
########...#############........#################....#
########...#############........#################....#
########...#############.......c###########.........C#
########..............####==####....KK....#..........#
########c....C.....c.................................#
########.............==....*...==....................#
###########..........==........==.........#.o........#
###########..........==........==.......C.############
###########o...KK........sssss....c.......############
######################.o......c.######################
######################################################
```

### Where things go, and why

- **The defenders' side.** The defenders' spawn is in the middle of the north end, with a door into
  each of three halls: west to the back of A, east to the back of B, and south into the defenders'
  mid. The defenders reach A's plant area in 7.8 s and B's in 7.9, the attackers in 14.3 and 13.2,
  so the defenders are there 6.5 and 5.3 s first, as Counter-Strike's CTs are. The sites are nearer
  them on purpose, as Barlet has it of Dust II.
- **A, the loading yard.** The attackers' way in is A main: from the west end of their lobby a
  roofed hall runs 28 m north, turns west, then north again to a 3 m door into the site's south-west
  corner. The bends break the sightline, so nobody holds A main from the site, and each bend has its
  container or crate to fight round. A short, a 3 m door from the link, is the second way in, from
  mid's courtyard. The site is 24 by 22 m: the plant area round a container (the default plant), a
  truck (a container) along its south side, a crate stack and a crate inside A main's door, barrels
  inside A short, another crate stack to the east and crates about, so nowhere on it is more than
  4.4 m from cover or a wall. Heaven stands at the site's back, a roofed room 3.2 m up whose deck
  looks over the whole plant area, as Ascent's A heaven does: the defenders reach it by stairs from
  the back of A, and attackers who take the site can go up the stairs on its west side. Its railing,
  1.3 m high, shows a standing player's head and hides a crouching one. A 4 m gap at its east end
  lets a defender drop into the site to retake it; there's no climbing back up. Under the deck is
  hell, 2.9 m high, with a crate in it: a close angle on anyone who plants under heaven. Heaven's
  strength is its sight of the site; its weakness is that it's seen from all of it, and attackers on
  the site can come up its stairs.
- **Mid.** The attackers' mid door opens north into mid bottom, then the street jogs east and back,
  so from the window or anywhere north nobody sees their spawn's door. The lane runs north 7 m wide
  past planters and a crate stack into the courtyard, open down the middle under the window, with a
  hedge and barrels on its west side and a tree and a crate on its east. On the courtyard's north
  side is the window room, 3 m up and roofed, its frame 4 m wide across the end of the lane, as
  Mirage's window looks down its mid: a defender standing at the frame sees down the whole lane, the
  tree standing off to one side so its leaves hide none of it. Its stairs come up from the
  defenders' mid, so it's the defenders' to take first, and its frame is too high to climb through.
  From the courtyard, the link leads west to A short, top mid north to the defenders' mid, and the
  market east to B.
- **B, the container yard.** The attackers' first way in is B long: from their lobby through 4 m
  doors into a corner, then a lane 8 m wide and 48 m long down the yard, with a container along its
  side and a crate at its end, as Dust II's long A is the map's long shot. The second is through the
  market from mid to hookah, a roofed room with a 3 m door onto the site and beside it a 3 m window
  with its sill 0.75 m up, to jump through, as Bind's B has. The site is 24 by 22 m round a crate
  stack (the default plant), with a container by B long's end, crates and barrels about and a crate
  stack in the middle: nowhere more than 4 m from cover or a wall. Across its back is a platform
  1.6 m up, as Train's B platform is, with a ramp up to it from the site and another from the
  defenders' hall. It sees the site over the cover; it's open to the whole site, and a defender on
  it can drop down but not climb back. Attackers reach the plant area in 13.2 s at the quickest,
  through hookah's window, and the defenders in 7.9 s.
- **Sightlines.** Long ones down B long and mid's lane; middling ones across each site; short ones
  round A main's bends, in hookah and in hell. From no raised place, even jumping, does anyone see
  into the attackers' spawn: the tests check 81,216 lines.
- **Landmarks.** The warehouse and sheds over A's side, the customs house between A and the window,
  the terminal and offices over B's side, the control tower between top mid and B, and the gantry
  crane over B. Each site's sign is high on the wall at its back, facing the attackers' way in.

Team Deathmatch's spawners stand in A main's hall, either side of mid's courtyard and in B long; its
Recovery Orbs in the link and where the lane meets the courtyard; the Ultimate Orbs up A main and B
long, nearer the attackers (system 49). Their runs are measured in three dimensions now.

### The tests in three dimensions

tests/Levels.luau builds a map's floors from its parts as the server builds them: a grid of columns
0.25 m apart, each with a node at every height the player's box (0.68 m across and 1.80 m tall, with
0.1 m to spare all round) can stand at. From each node the box walks to the next if it's within a
step (0.35 m), jumps up to it if it's within 0.8 m (a little under the jump's apex, 0.85 m), and
drops down to it from any height. A ledge that low only stops the box itself, not the spare round
it. On those nodes it finds each run, and checks lines of sight against the boxes, the wedges and a
box round each tree's leaves, which shots and steps go through but an eye doesn't. Wharf has 63,379
places to stand.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/MapPlan.luau` | Heights: rooms' `y` and railings, decks, flights and windows; the floor's height and the floors over each point; walls that rise by a raised floor; floors, wedges, steps, railings and windows built |
| `src/shared/Match/Wharf.luau` | Rebuilt: the layout, its heights, its cover and its dressing |
| `src/shared/Match/MapKit.luau` | The deck's and the railing's looks, and the steps' |
| `src/server/Arena.luau` | A flight built as a WedgePart, and stairs' wedges unseen |
| `src/shared/Match/Minimap.luau`, `src/client/MinimapView.luau` | Raised floors, decks and flights drawn lighter than the floor |
| `src/shared/Arena/DeathmatchSpawns.luau` | A life starts at the floor's height, only where it's level all round |
| `src/shared/Arena/TeamDeathmatchConfig.luau` | Wharf's pickups and Ultimate Orbs moved |
| `tests/Levels.luau`, `tests/heights.luau`, `tests/run.luau` | New: floors in three dimensions, and 28 checks: each height as the plan builds it, and Wharf's reach, runs, raised places, windows, sightlines and open space |
| `tests/tdmpickups.luau` | Runs in three dimensions on a map with heights; pickups clear of heights |
| `tests/mapkit.luau` | Out of reach over the highest floor; the deck's look |
| `tests/match.luau` | Only what spans the eye's height blocks a spawn's sightline, not a window's sill or the wall over it |
| `docs/studio-checklist.md` | Section 62's checks on the rebuilt map, and section 63 for its heights |

## 7. Debug tools

- `VFMatchMap` on Workspace, set from the server to `wharf` before the spike rounds begin, has their
  first match on Wharf.
- In the place, each flight is a WedgePart named after it (`HeavenStairs`, `SiteStairs`,
  `WindowStairs`, `BRamp`, `BElbowRamp`), its steps parts named after it with `Step`, each deck a
  part (`HeavenDeck`, `HeavenDrop`) and each railing one named after its floor with `Rail`.

## 8. Refinement loop

1. Play it at five a side: whether heaven, the window and the platform are worth taking, and
   what each costs; whether A or B is easier to take, and to retake.
2. Check the run times in Studio against the tests' (section 63).
3. Move cover where a site plays too open or too closed, and re-run the tests' open-space
   check.
4. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The wedges: each stair and ramp rising toward its head, walked up and down at a run without a stop
  or a hop.
- The look of the heights: heaven, its deck and railing and hell under it, the window room and its
  frame, B's platform, hookah's window, the steps over the stairs.
- Heaven's railing holding, its gap to drop through, and no climbing back onto the deck or the
  platform.
- Jumping through hookah's window.
- From the window and heaven, standing shows a head over the frame or the railing, and crouching
  hides it.
- Each side's run to each site, and how the map feels at five a side.

Section 63 of the [Studio checklist](../studio-checklist.md) covers these.
