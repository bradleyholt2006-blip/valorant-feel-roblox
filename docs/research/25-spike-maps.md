# System 25: The spike rounds' maps

The goal is servers that are always playing, as Counter Blox's are, with a vote between three
random maps after each game. Skirmish and gun game have had that since system 22, on Skirmish's
three maps. The spike rounds had only Outpost (system 13), a small map for one to three a side, so
each of their matches started on it again, with no vote. This system adds two maps of our own
built for the reference's five a side, Quarry and Foundry, and holds the same vote after each spike
match, between all three.

None of the reference's maps is copied or measured here. None is published at a scale to build
from, and the goal is a game of our own, so Quarry and Foundry follow the pattern the public
sources describe for the reference's traditional maps: two sites, three lanes, and a spawn at each
end, the defenders' nearer the sites. The offline tests check each of them the way they checked
Outpost.

As before, everything comes from public sources: the VALORANT Wiki, the press on Riot's design of
Ascent, a guide to the current map pool, and Riot's own description of the game. No game files,
memory or network traffic were used. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker |
| **Community** | Published by a wiki, a guide or the press, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **The reference's maps.** Most have two sites, A and B, and three lanes between the spawns: one
  to each site and one through the middle, which links to both. The attackers spawn at one end and
  the defenders at the other, nearer the sites, so the defenders can get set first. A few differ:
  Haven has three sites.
- **The pool.** Each competitive match is played on one map of a pool of seven, which changes
  with the patches as maps go out of it.
- **The spike.** It lies in front of the attackers as each round starts (system 13).
- **Counter Blox.** Three random maps after each game, as the goal says (system 22).

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| Five a side | "Valorant is a character-based 5v5 tactical shooter set on the global stage." ([PlayStation Store page](https://www.playstation.com/en-us/games/valorant/)) |

### From the community

| What | Source |
| --- | --- |
| "Sunset is one of VALORANT's more traditional maps with two sites and three lanes." | [VALORANT Wiki, Sunset](https://valorant.fandom.com/wiki/Sunset) |
| Haven is the exception: on it the sides are "clashing to control three sites", which gives the attackers "more territory to control, but defenders can use the extra real estate for aggressive pushes" | [VALORANT Wiki, Haven](https://valorant.fandom.com/wiki/Haven) |
| Ascent was made to "make a map with a traditional three-lane tactical experience", and to "separate site A and site B, not only with different routes and distance, but also vertically": "site A will be on the high ground, site B will be the lowest point of the map", with "some kind of central tower" between them in the middle | [THESPIKE](https://thespike.gg/valorant/news/the-design-behind-ascent-explained/317), on Riot's dev post "The Birth of Ascent" |
| Keeping players easy to see: "visual details of the map can be placed only below 0.3 meters (or 1 feet) and above 2.7 meters (or 9 feet)", and "Everything in between those parameters must be simple", because "It's extremely important to make sure that agents' heads are as clearly visible as possible." | The same |
| "For V26 Act 6, the map pool for Competitive play is:" Summit, Abyss, Sunset, Lotus, Corrode, Haven and Bind. Maps leave it with a patch: Icebox in 11.04, Pearl and Fracture in 13.00, Breeze in 13.04, and Ascent and Split in 13.08 | [Strafe](https://www.strafe.com/articles/read/valorant-active-map-pool/), last updated 14 October 2026 |

None of these gives a map's size, how far its sites are from either spawn, or how long a side takes
to reach them. Everything in Quarry and Foundry beyond the pattern is ours, and labelled.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How long each side takes to reach each site on the reference's maps | Public match videos: from the barriers dropping, the time the first attacker takes to reach a site, against a defender running from their spawn. Or a stopwatch in a custom game. Ours are in section 4 |
| How big a lane, a choke or a site is | In a custom game, the time a run takes from one end to the other with the knife out, at its known speed |
| How long the defenders take to move from one site to the other | The same, from site to site through mid and through their spawn |
| Whether a map is fair to both sides | Play it five a side and count the rounds each side wins at each site (section 8) |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Who the maps are for | Quarry and Foundry five a side, each spawn with five spots; Outpost stays the small one | Confirmed (five a side); ours (the maps) |
| The spike rounds' maps | Outpost, Quarry and Foundry, all three our own | Ours |
| Their pattern | Two sites, A on the attackers' left and B on their right. Three lanes from the attackers' spawn: one to each site and one through mid, with a link from mid to each site. The defenders' spawn at the other end, nearer both sites, with a hall to each | Community (the reference's traditional maps); ours (the plans) |
| The two sites | On Quarry and Foundry, set apart by their routes and their size: A's plant area 14 x 12 m, B's 12 x 10 m. Outpost is mirrored, with both 12 x 10 m | Community (sites set apart by their routes); estimate (the sizes) |
| Heights | Everything on one floor. Walls 5 m; cover 1.3 m, which you crouch behind and stand to shoot over, or 2.0 m, which hides you standing; every piece a plain block | Estimate. Plain blocks keep to the rule for keeping heads easy to see |
| Where the spike lies | On the floor in front of the attackers, between their spawn spots and their door to mid, about 4 m ahead of them | Community (in front of the attackers); estimate (the spot) |
| The first match on a server | On one of the three at random | Ours, as in Skirmish (system 22) |
| After each match | The victory screen's 10 s, then 15 s to vote between all three, and the next match on the winner, at 0-0 on the starting credits | Ours (the goal), with system 22's vote: its ties, no votes, leaving, and a side emptying |
| Who votes | Everyone in the match, playing or in line, as in Skirmish | Estimate (system 22) |

What the maps give (from `luau tests/run.luau`, running with the knife at 6.75 m/s from the
barriers dropping):

| Map | Size | Pieces of cover | Site A: attackers, defenders | Site B: attackers, defenders | Lines from one spawn into the other |
| --- | --- | --- | --- | --- | --- |
| Outpost | 66 x 68 m | 18 | 7.5 s, 4.8 s | 7.5 s, 4.8 s | None |
| Quarry | 90 x 92 m | 17 | 10.4 s, 6.6 s | 10.5 s, 7.0 s | None |
| Foundry | 88 x 98 m | 20 | 11.1 s, 6.4 s | 10.5 s, 6.8 s | None |

So on Quarry the defenders reach each site 3.5 to 3.8 s first, and on Foundry 3.7 to 4.7 s. These
times are ours: nothing public gives the reference's, so whether they're right needs section 3's
measurements.

## 5. Design

### One plan for every map

`MapPlan` is Outpost's plan from system 13, made general. `MapPlan.new(def)` takes a map as it's
written down (its name and key, where it stands in the place, its rooms, its cover, each spawn's
doors, its sites' plant areas and where the spike lies) and gives back the map with the functions
Outpost had: its rooms and cover, its outline, its sites as the spike knows them (`zones`), each
spawn's five spots (`spots`), and every part to build (`parts`). A room or a piece of cover with a
`mirror` gets a partner across the middle, which is how Outpost is mirrored left to right. Quarry
and Foundry have none, so their sites differ, as the reference's do.

`MatchMap` is now Outpost written down that way, with the same rooms, cover and numbers.
`SpikeMaps` holds the three by key (`outpost`, `quarry` and `foundry`) in the order the vote shows
them, and the spike knows each one's sites by the same key (`Spike.Layouts`).

### Quarry and Foundry

Both are on one floor, on a 1 m grid, with walls 5 m tall. The attackers spawn at one end with a
door into each lane, and the defenders at the other, with a door into mid and a door to each of
their halls, which lead to the sites.

- **Quarry, 90 x 92 m.** Its lanes turn. A: a lobby west from the attackers' spawn to A main, a
  long corridor north, and a choke into the site. Window, a passage from A main to mid bottom,
  joins the two lanes on the attackers' side. Mid: a lane north from mid bottom into a courtyard
  that runs round a block, so nobody sees down mid from one end to the other. From the courtyard,
  A link leads west onto site A, market east onto site B, and top mid north to the defenders'
  door. B: a lobby east to B main, which turns at an elbow and comes onto the site through a
  choke.
- **Foundry, 88 x 98 m.** Its lanes run straight, for longer fights. A: a lobby west to A long, a
  corridor 46 m straight up the map's west side, which turns at a corner onto the site. A short, a
  hall west from mid bottom, turns north onto the attackers' side of the site. Mid: a wide mid
  bottom, then a hall round a block, so nobody sees down mid either, and top mid to the defenders'
  door; B link leads east from the hall onto site B. B: a lobby east to B main, straight north to
  a choke into the site.

Seen from above as the attackers face them, Quarry on the left and Foundry on the right, drawn from
their plans in the code. One character is 2 m each way, so edges are rounded to that, and the
plans look stretched from top to bottom. `#` wall, `=` barrier (buy phase only), `H` 2.0 m cover,
`L` 1.3 m, `a` and `b` the plant areas, `^` the attackers' spawn spots, `v` the defenders', and `*`
where the spike lies:

```
Quarry                                           Foundry

#######...........##.......##............####    #######...........##.......##.........######
######............==.......==.............###    ######............==.......==..........#####
######............==.vvvvv.==.............###    ######............==.vvvvv.==..........#####
######............==.......==.............###    ######............==.......==..........#####
######............#.........#.............###    ######............#.........#..........#####
######.....#########..===..##########.....###    ######.....########.........#######....#####
######.....###########===############.....###    ######.....#########..===..########....#####
######.....###########...############.....###    ######.....###########===##########....#####
######.....###########...############.....###    ####..........########...##########....#####
#...........##########...############.....###    ###.HH.........#######...##########....#####
........LL...#########...###########........#    ###.HH......HH.#######...##########....#####
..H.....LL...#########...##########.H......L.    ###..aaaaaaaHH.#######...##########....#####
...aaaaaaa...#########...##########..bbbbbbL.    ###..aaaaaaaLL.#######...##########........#
...aaaaaaa...#########...##########..bbbbbb..    ###..aaaaaaaa..#######...#########.HHbbbbbL.
...aaaHaaa...#########...##########..bbHHbb..    ###..aaaHHaaa..#######...#########.HHbbbbbL.
...aaaHaaa...#########...##########..bbHHbb..    ###..aaaaaaaa..#######...#########..bbHHbb..
...aaaaaaa...####...........#######..bbbbbb..    #....aaaaaLLL..#######...#########..bbHHbb..
...aaaaaaa...................######..bbbbbb..    ....LLaaaaLLL..###...........#####..bbbbbb..
.......LL.LL.............................LLL.    ....LL........###.............####..bbbbbb..
.......LL.LL........#####...................#    ......####....###.............####..........
#...................#####......H....#####...#    ....######....###....#####....####.....LL...
##...###########....#####...........#####...#    ....######....###....#####.............LL...
##...###########...................#####.....    ....######....###....#####.......L.........#
#.....##########.........LLL.###########.....    ....######....###....#####.......L.###...###
#.....###########...........############.....    HH..######....###....#####........####...###
#...H.################...###############.....    ....######.LL.###....#####....#######.....##
#.....################...###############.....    ....######....###.............#######.....##
#.....################...##########..........    ....######....###.....LLL.....#######.....##
#.....################...#########.....L.....    ....######....###.....LLL.....#######.....##
#.....################...#########.....L.....    ....######....####...........########.....##
#.....################...#########..........#    ....######....######.......##########.....##
#.L...################...#########.....######    ....######.................##########.....##
#.....##############.......#######.....######    .LL.######.................##########.....##
#..........................#######.....######    ....######.................##########..LL.##
#..........................#######.....######    ....#######................##########.....##
#....................L.....#######.....######    ....################.L.....##########.....##
#.....##############.......#######.....######    ....################.......##########.....##
#.....##############.......#######.....######    ....################.......##########.....##
#.................##..===..##..........######    ....################.....H.##########.....##
#..................#..===..#...........######    ....################.......##########.....##
#........H........==.......==...H......######    ....################.......##########.....##
#.................==...*...==..........######    ....################..===..##########.....##
##................==.......==.........#######    ..................##..===..##.............##
###################..^^^^^..#################    ..................==.......==.............##
###################.........#################    ........H.........==...*...==....H........##
####################.......##################    ..................==.......==.............##
                                                 #.................#..^^^^^..#............###
                                                 ###################.........################
                                                 ####################.......#################
```

The tests check every map the same way, and each of the three passes every check:
- Every room is on the 1 m grid, and every piece of cover stands on the floor, clear of the walls.
- With the barriers down the floor is one space: every room can be reached, every gap is wider
  than a player, and there's room to stand in every room.
- Five clear spawn spots a side, even with the barriers up, and the spike's start inside the
  attackers' spawn, clear of everything.
- With the barriers up each side is held in its spawn, and running at a barrier for 3 s doesn't get
  through it. With them down, the attackers run out to mid.
- Each site's plant area is inside its site, and the spike knows them as the map's.
- The defenders reach each site before the attackers can.
- From anywhere in either spawn, nobody can see into the other.
- No cover hides your eye but not your head, and nobody can jump out.

### The vote

As in Skirmish (system 22). `MatchRules` now keeps the maps it plays on, the map being played (the
first at random) and, after a match, the vote (`MapVote`), with Skirmish's numbers: three maps to
pick from, so all three here, and 15 s.

```
          10 s                       15 s, everyone votes
  matchOver ────► vote (all three) ───────────────────► buy, round 1 at 0-0, on the winner
      │                      │
      │ one map only         │ a side empty: waiting at 0-0, on the same map
      └────────────────────────────────────────────────► buy, round 1 at 0-0
```

`MatchRules.vote` takes a vote from anyone the rules know, playing or in line, and someone leaving
takes their vote with them. Nothing during the vote goes in the record. `MatchRules.skip` ends the
victory screen and the vote too, for scripted checks.

### The server

`Arena` builds all three maps as the place starts, about 70 parts each, every map a model of its
own in `Workspace.VFSpikeMap` at its own origin: Outpost at x -150 m, Quarry at -300 m and Foundry
at -450 m, all off the course's left. A match's map decides where everyone spawns, whose barriers
go up in the buy phase, and where the spike's sites are and where it lies: as a match starts on
another map, `SpikeServer.setMap` moves the spike to it. The map and the vote go out on the arena's
model as in Skirmish (`Map`, `MapVote`, `VoteMaps` and `Votes`), and the `Vote` remote takes votes
in the spike rounds too.

### The client

- **`VoteScreen`.** In the spike rounds the cards are the spike maps', each with its name and its
  plan seen from above as the attackers face it: the defenders' spawn at the top and A on the
  left, each spawn's floor in its colour, the plant areas in amber, and the cover, lighter for the
  taller.
- **`ArenaHud`.** Round 1's buy phase names the map first, as in Skirmish: `QUARRY   800 CREDITS
  Attack: plant the spike at A or B   B buy menu`.
- **`Scoreboard`.** The victory screen counts down to the map vote, as in Skirmish.

### Not here yet

- **Height.** Every map is on one floor. The reference sets its sites apart in height too, as
  Ascent's A high and B low, which would take ramps and stairs.
- **Maps by player count.** The vote offers all three whoever is playing, so two players can pick
  Outpost and ten Quarry or Foundry, but nothing steers them.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/MapPlan.luau` | New: a spike map's plan, from its rooms, cover, doors and sites |
| `src/shared/Match/MatchMap.luau` | Outpost, now written down as a `MapPlan` |
| `src/shared/Match/Quarry.luau` | New: Quarry |
| `src/shared/Match/Foundry.luau` | New: Foundry |
| `src/shared/Match/SpikeMaps.luau` | New: the three by key, in the vote's order |
| `src/shared/Match/MatchRules.luau` | The map played, the vote after a match, `vote`, and `skip` for the victory screen and the vote |
| `src/shared/Spike/Spike.luau` | Every map's sites in `Layouts` |
| `src/server/Arena.luau` | All three maps built; spawns and barriers on the match's map; the map and the vote published, and votes taken |
| `src/server/SpikeServer.luau` | `startRounds` and the new `setMap` take the map's sites and where the spike lies |
| `src/client/VoteScreen.luau` | The spike maps' cards, with their plans |
| `src/client/ArenaHud.luau` | The map's name in round 1's buy phase |
| `tests/match.luau` | Every check Outpost had, for every map, and the times to each site |
| `tests/mapvote.luau` | 13 checks of the spike rounds' vote: the first map, the victory screen, votes, leaving, the next match, one map, a side emptying, and `skip` |
| `tests/scoreboard.luau` | Through the vote to the next match |

## 7. Debug tools

- Output says which map a server starts on: `[VF] Arena on: the spike rounds, Standard, on
  Quarry`.
- The arena's model has `Map` (`outpost`, `quarry` or `foundry`), and during the vote `VoteMaps`
  (`outpost,quarry,foundry`) and `Votes` (`2,0,1`). Each player's `VFMapVote` is their vote, by its
  number in the list.
- Workspace's `VFSpikeLayout` is the map being played, and `VFSpikePosition` where the spike is.
- `VFMatchSkip`, set true from the server, now ends the spike rounds' victory screen and vote too.
- `VFTestVote` set to 1, 2 or 3 on the local player votes as a click on that card does (Studio
  only).
- `luau tests/run.luau` prints how long each side takes to reach each map's sites (`Spike maps
  report`).

## 8. Refinement loop

1. Time the reference's maps from public videos (section 3), and move doors, chokes and lanes until
   the times to each site are in line with theirs.
2. Play Quarry and Foundry five a side, and move cover where one side always wins a site.
3. Once a map plays well flat, give its sites height where they want it.
4. Re-run `luau tests/run.luau` after each change: every map must still hold.

## Known gaps to check in Studio

- All three maps build at their origins with nothing overlapping them, and play at the right scale
  for five a side.
- A server's first match is on one of them at random, named in round 1's buy phase: everyone spawns
  in its spawns, behind its barriers, with the spike in front of the attackers.
- After a match, the vote shows the three spike maps' cards with their plans, and the next match
  is on the winner: the spawns, the barriers and the spike's sites all the new map's.

Section 29 of the [Studio checklist](../studio-checklist.md) covers these.
