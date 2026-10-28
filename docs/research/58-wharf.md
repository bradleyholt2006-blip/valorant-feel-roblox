# System 58: Wharf, and the kit its cover is built from

The spike rounds had three maps of our own, Outpost, Quarry and Foundry, whiteboxes of grey walls
and grey crates (system 25). This system adds a fourth, Wharf, for five a side, and the first that's
dressed. It's laid out as the reference's two-site maps are, with three lanes, and set on a harbour:
a warehouse loading yard at A, a garden plaza in mid, and a container yard at B under a gantry
crane. Its cover comes from a kit of placeholder props: crates, crate stacks, shipping containers,
barrels on pallets, planters, hedges and trees. Each piece is a box that's all there is to it for
moving, seeing and shooting, with a look over it that's for show. A model named after a piece, put
in a folder named VFMapKit in ServerStorage, is fitted over every piece of that name in place of the
placeholder, so the art can be swapped in without touching the layout. Each zone of the floor has
its own look. Three halls have roofs, with a light under each, the spawns' doors and the sites'
chokes have lintels, and buildings rise over the walls. A harbour tower by mid and the crane over B
are landmarks, and each site has a sign.

As before, everything comes from public sources: Riot's developer post on how Split was made, Riot's
level designers quoted by ONE Esports, esports.gg and PC Gamer, and for how to block out a map and
build a kit, the awesome-level-design list and the Level Design Book it points to, with ISO 668 for
a container's height. No game files, memory or network traffic were used, and nothing was read from
the live game; no Riot image, model or sound is in the repository. None of the reference's maps is
published at a scale to build from, so Wharf's layout is ours: Riot gives the pattern (three lanes,
two sites, each site its own look, landmarks, the greybox first), and the Level Design Book the
metrics and the kit. Nothing in this system is measured from the reference. Our own map's run times
are measured by the offline tests.

## 1. Observable behaviour

- Two sites and three lanes: the attackers' spawn at one end with a way into each lane, the
  defenders' at the other, nearer both sites, and mid between, joined to each site (system 25).
- Each site has a look of its own, and landmarks seen from far off tell you where you are.
- Cover is dressed as things of the place, such as crates, containers and planters, and how tall it
  is reads at a glance: what you can shoot over, and what hides you.
- Some halls are roofed, and doors and chokes are framed.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "The design philosophy behind our maps on VALORANT is relatively simple": each is made to "center the map around a specific gameplay experience" | Chris Carney and Salvatore Garrozzo, ["The Creation of Split"](https://playvalorant.com/en-gb/news/dev/the-creation-of-split/), Riot's dev blog |
| Each site its own look: "B Site was to be the older district in the city", A a new tech campus | The same |
| "We want players executing strategies and fighting enemies rather than fighting the layout of the map" | The same |
| Points of interest "help players build an easy mental map of how the places connect" | The same |
| The greybox is "our earliest playable version of a map" | The same |
| "Our maps are 'gameplay first', so the graybox definitely leads the way." "Metrics are all determined by the needs of the space." | Joe Lansford, a level designer, in a Riot AMA, quoted by Wanzi Koh, ["How Valorant map designers create a new map"](https://www.oneesports.gg/valorant/valorant-map-design-explained-riot-devs/), ONE Esports, 11 March 2022 |
| "We want each new map to come with its own set of challenges and puzzles for players to overcome and solve." | Joey Simas, a level designer, the same |
| Corrode is a "core three-lane tactical FPS map with a particular focus on layered defenses", its mid "fairly simple" | Joey Simas, lead map designer, quoted by Sofia Guimarães, [esports.gg](https://esports.gg/news/valorant/corrode-inspiration-and-design-behind-the-new-valorant-map-with-developers) |
| Of Haven's three sites: "moving beyond two areas of importance can really thin out the team in a way that makes it difficult to deal with" | Trevor Romleski, lead game designer, to Tyler Wilde, [PC Gamer](https://www.pcgamer.com/valorants-lead-designer-on-the-current-meta-razes-ult-map-design-and-more), 17 April 2020 |

### From level design references

| What | Source |
| --- | --- |
| "You can't play documentation. Start blocking out your ideas early." | [awesome-level-design](https://github.com/bradleyholt2006-blip/awesome-level-design), its Tips |
| A blockout is "a 3D rough draft level built with simple 3D shapes, but without any details or polished art assets." "99% of the time, your blockout will not survive a playtest." | The Level Design Book, [Blockout](https://book.leveldesignbook.com/process/blockout) |
| "Entryways and hallways should be at least twice as wide as the scale figure." "Build a wall segment that's approximately 150-200% as tall as the scale figure." | The same |
| "Color and brightness provide important context for understanding what the space is made of." | The same |
| "High cover. Standing head height object, 1.75 or more meters." "Low cover. Standing waist height object, 1.0-1.25 meters." (Uncharted 4's metrics) | The Level Design Book, [Cover](https://book.leveldesignbook.com/process/combat/cover) |
| "Consistent cover is useful for combat games that want to avoid ambiguity." "Too many wide tall cover objects can create confusing maze-like flow and wayfinding." | The same |
| "In general, low cover is better than tall cover." | Epic Games on Gears of War, quoted on the same page |
| "pay attention to naming, level designers and kit artists need to agree on a pattern" | The Level Design Book, [Modular kit design](https://book.leveldesignbook.com/process/blockout/metrics/modular) |
| "consider building a tool for easily swapping in module types, which will make art pass and remesh much faster" | The same |
| "collision is one of the biggest issues, make sure you can't get stuck?" | The same |
| "For competitive multiplayer maps, flow strongly affects overall map balance." | The Level Design Book, [Flow](https://book.leveldesignbook.com/process/layout/flow) |
| A 20 ft container ('1CC: 20 foot standard') is 2.591 m high | [ISO 668](https://en.wikipedia.org/wiki/ISO_668), Wikipedia |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How long each side takes to reach each plant area | The offline tests, on the map's parts, running with the knife (tests/match.luau prints it) |
| Whether a pickup is as near one spawn as the other | The offline tests (tests/tdmpickups.luau prints each one's lean) |
| How the map looks, and whether it plays well | In Studio: section 62 of the [Studio checklist](../studio-checklist.md), and playtests ("your blockout will not survive a playtest") |
| Whether a model swaps in | In Studio, with a model in ServerStorage's VFMapKit folder |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Lanes and sites | Three lanes and two sites | Confirmed (Riot on Corrode and on Haven's three sites) |
| A map's own challenge | Mid's two links leave from different ends of it, one from the plaza to A and one from top mid to B; B main is a slalom between containers; A main is a long roofed hall to a choke | Ours, after Riot's "its own set of challenges" |
| Each site its own look | A in sandy concrete with crates and barrels round a container, B in teal-grey among containers under a crane, mid in warm paving with trees, the attackers' side asphalt, the defenders' slate, the halls wood | Confirmed (Split's sites); estimate (the looks) |
| Landmarks | A tower by top mid, a gantry crane over B, a tree at the heart of the plaza, and a sign at each site | Confirmed (Split's points of interest); estimate (which) |
| Timings | The defenders reach each plant area first: A 7.1 s against the attackers' 11.5, B 6.7 against 12.1 | Ours (measured offline); estimate (the gap, about Quarry's and Foundry's) |
| Widths | Halls and lanes 5 to 10 m, chokes 5 m, the plaza 30 m | Community (twice a player's width at least); estimate (the rest) |
| Walls | 5 m, as on every map, with buildings above some | Community (150 to 200% of a player, the book); estimate |
| Cover heights | Low 1.3 m and high 2.0 m, as on every map, and tall 2.6 m for a container | Community (the book's metrics); confirmed (a container's 2.591 m, ISO 668); estimate (ours) |
| Pieces | Crate (low), crate stack (high), container (tall, 6 x 2.4 m), barrels (low), planter (low), hedge (high), tree (low, its leaves overhead) | Ours |
| A piece's box | All there is to it for play: its look, placeholder or model, collides with nothing and stops no bullet | Community (consistent cover, the book) |
| Swapping in models | A Model named after a piece, in a folder named VFMapKit in ServerStorage, fitted over each piece of that name: as big as fits its box, its own x along the box's longer side, and the middle of its base on the box's | Ours, after the book's tool for swapping in modules |
| Wallbangs | Crates soft, planters, hedges and trees medium, containers and barrels hard, floors, walls and dressing solid | Estimate (as wood, stone and metal are in system 5) |
| Overhead | Roofs and lintels from 3.4 m up, above a jump (0.85 m) on a standing player (1.8 m); trees' leaves from 2.9 m up, for show | Estimate |

## 5. Design

### The layout

North (up) is the defenders' end and south the attackers', A west and B east. Each character is 2 m:
`#` wall, `.` floor, `=` a spawn's door, `a` and `b` the plant areas, `s` spawn spots, `*` where the
spike starts, and the pieces of the kit: `c` crate, `C` crate stack, `K` container, `o` barrels, `p`
planter, `h` hedge, `t` tree.

```
###########..........#.........#..........#########
###########.....c....=.........=..........#########
###########..........=..sssss..=..........#########
###########..........=.........=....o.....#########
###########..........#.........#..........#########
###########....#######.........#######....#########
###########....#######...===...#######....#########
###########....##########===.....#####....#########
###########....##########........#####....#########
...............##########........####..............
....c..........##########........####..............
.K..c....CC....#############.....####.....KKK......
.K.............#############.....####..............
.K.aaaaaaaa....#############.............bbbbbcc...
.K.aaaaaaaa....#############...C.......o.bbbbbcc...
...aaKKKKaa....#############...........o.bbbbbb....
...aaaaaaaa..p.#############.............bbCCbb..K.
...aaaaaaaa..p.#############.....####....bbbbbb..K.
...aaaaaacc.......................###....bbbbbb..K.
...aaaaaaaa.......................###....bbbbbb..K.
..oo..........................pp..###..............
..oo.........C................pp..###.c.......C....
...............####...............###..............
...............####..hh...........#########...#####
##########...######...............#########...#####
##########...######...............######......#####
#########.....#####.......t.......######.c....#####
#########.o...#####...............######.c....#####
#########.o...#####...............######......#####
#########.....#####...........hh..######..KKKK#####
#########.....#####..pp.......hh..######..KKKK#####
#########...C.#####..pp...........######......#####
#########.....#####.t...........t.######......#####
#########.....#####.t...........t.######......#####
#########.....#####...............######......#####
#########.....#########.....o.##########KKKK..#####
#########.c...#########.....o.##########KKKK..#####
#########.c...#########.......##########......#####
#########.....#########.c.....##########......#####
#########.....#########.c.....##########......#####
#########............##.......##....KKK.......#####
#########............##.......##....KKK.....#######
#########..C.........##..===..##............#######
#########............#...===...#............#######
#########............#....*....#............#######
#########............=.........=............#######
#########.....KKK....=.........=..........o.#######
#########.....KKK....#..sssss..#............#######
######################o.......c####################
######################.........####################
```

- **A.** From the attackers' spawn, a lobby west to A main, a roofed warehouse hall 28 m north with
  a crate, a crate stack and barrels in it, and a 5 m choke under a lintel onto the site. The site
  is a 28 m yard: a container as the default plant in the middle of the plant area, another in the
  back corner, crate stacks at the choke and by the defenders' way in, and crates and barrels about.
  The arcade, a roofed walk, joins it to the plaza; the defenders come in from the hall behind it.
- **Mid.** A street north from the attackers' door into the plaza, 30 m across, with a tree at its
  heart and planters, hedges and two more trees for cover. The arcade leaves its north-west corner
  for A. Top mid leaves its north-east corner and turns west to the defenders' door, so from one
  spawn nobody sees down mid into the other. The market, another roofed walk, leads from top mid
  east onto B: whoever holds top mid holds the quick way to B.
- **B.** A lobby east to B main, a lane through the container yard with a container parked across
  each half of it, so it's a slalom, then a 5 m choke under a lintel onto the site. The site has a
  crate stack as the default plant, a container by its east wall and another by the defenders' way
  in, and barrels where the market comes in. The crane spans it overhead.
- **The defenders.** A hall from their spawn to the back of each site, and their door into top mid.

Running with the knife, the defenders reach A's plant area in 7.1 s and B's in 6.7 s; the attackers
in 11.5 s and 12.1 s. Quarry and Foundry give the defenders 3.5 to 4.7 s; Wharf gives them 4.4 to
5.4 s, its sites a little nearer their spawn. Team Deathmatch's pickups and the Ultimate Orbs
(systems 28 and 49) are placed as the offline tests want them: out on the floor, even between the
sides overall, and the orbs nearer the attackers.

### The kit

MapKit has each piece's height, its looks and how bullets go through it, and its placeholder: a few
blocks, cylinders and balls in the piece's own frame, from the middle of its base with x along its
longer side. A crate is planks with a post at each corner, a band and a lid; a crate stack two of
them; a container a body with corrugated sides, corner posts, rails and doors with locking bars, in
one of five colours; barrels steel drums with hoops on a pallet; a planter and a hedge a stone box
with a cap and a hedge to the piece's height; a tree a planter with a trunk and leaves above it, out
of reach. Everything but the tree's trunk and leaves stays inside the box. A piece's look is its own
number on the map, or else follows from its name, so the map looks the same every time.

### The look

A dressed map's floor is built as each zone's own blocks, swept from its rooms as the walls are, so
each cell of floor is covered once. Its walls take the walls' look. A roofed room gets a roof on its
walls, 0.4 m thick and 0.5 m over each edge, with a light strip under it; a door with a lintel gets
one across it from 3.4 m to the top of the walls. The rest of its dressing is boxes: buildings and
the tower standing on the walls, the crane over B, and the signs, which hold their letter on their
face. Every look sets the part's wallbang material outright (RobloxLevel's VFPenetration), so its
Roblox material is only how it looks: the walls are Plaster and still stop every bullet. The other
maps are built as before.

### Swapping in models

To swap a piece's placeholder for a model, make a Model named after the piece (Crate, CrateStack,
Container, Barrels, Planter, Hedge or Tree), with its longer side along its own x and its base at
the bottom of its box, and put it in a Folder named VFMapKit in ServerStorage. When the server
builds Wharf, every piece of that name gets a copy, scaled to fit inside its box and set on the
box's base. A model put in the folder while the game runs, or taken out of it, shows at once on
every piece of its name, so a model can be tried in Play and kept by adding it in Edit. Nothing in
it collides, is hit or is touched: the box still does all that, so a model can't change where anyone
can go, see or shoot.

### Not here yet

- Height: the floor is flat, as on every map. Ramps, stairs and raised positions over a site need
  the plan, the movement checks and the minimap to know about floors above the ground.
- Windows and thin walls to shoot through: every wall is solid, and at least 1 m thick.
- A model per look: a container's five colours are the placeholder's; a model swapped in is the same
  for every container.
- The reference's own maps: none is published at a scale we could build from.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/MapKit.luau` | New: the pieces, their placeholders and looks, the zones' and the dressing's looks, and the VFMapKit folder's name |
| `src/shared/Match/Wharf.luau` | New: the map |
| `src/shared/Match/MapPlan.luau` | Dressed maps: rooms' zones, roofs and lintels, cover's pieces and looks, dressing, tall cover, the floor swept by zone, and the clearance overhead |
| `src/shared/Match/SpikeMaps.luau` | Wharf, the fourth map |
| `src/shared/Arena/TeamDeathmatchConfig.luau` | Wharf's pickups and Ultimate Orbs |
| `src/shared/Match/Minimap.luau` | Tall cover drawn as high cover |
| `src/shared/Match/MatchConfig.luau` | `VFMatchMap` |
| `src/server/MapDresser.luau` | New: builds a dressed map's look: the zones, the kit's placeholders or models, and the dressing, and swaps a piece's model as the kit folder changes |
| `src/server/Arena.luau`, `src/server/init.server.luau` | MapDresser for each part of a dressed map, and watching the kit folder; `VFMatchMap` |
| `tests/mapkit.luau`, `tests/run.luau` | New: 20 checks: the kit's placeholders inside their boxes, the looks, Wharf's zones, its dressing out of reach, its trees and signs, and the other maps as they were |
| `tests/match.luau`, `tests/deathmatch.luau`, `tests/mapvote.luau` | Four maps |

## 7. Debug tools

- `VFMatchMap` on Workspace, set from the server to a map's key (`outpost`, `quarry`, `foundry` or
  `wharf`) before the spike rounds begin, has their first match on that map.
- Each piece's box and its model carry `VFKitPiece`, the piece's name. The models are in the map
  model's `Kit` folder, named after their pieces of cover (as `ADefault`).
- `VFArenaMode`, `VFArenaOn` and `VFMatchSkip` as before.

## 8. Refinement loop

1. Play it: whether each site holds, how each is retaken, whether mid matters, and what the playtest
   changes ("your blockout will not survive a playtest").
2. From public footage of the reference's maps, check how wide its lanes, chokes and sites are
   against a player.
3. Check the run times against the reference's, from public footage of a round's first seconds.
4. Swap in models, a piece at a time, and check each fits its box.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Wharf is built off the course's left, past Foundry, and the spike rounds start on it with
  `VFMatchMap` set to `wharf`.
- Its look: the zones' floors, the walls, the roofs and their lights, the lintels, the buildings,
  the tower, the crane and the signs.
- The kit's placeholders: each piece's look, over its box, and nothing of it in the way of a shot or
  a step.
- The cover: low pieces shot over standing, high and tall ones hiding a standing player.
- A model in ServerStorage's VFMapKit folder fitted over every piece of its name.
- Each side's way to each site, the barriers, and no sight of one spawn from the other.
- How it feels at five a side: too big, about right or too small.

Section 62 of the [Studio checklist](../studio-checklist.md) covers these.
