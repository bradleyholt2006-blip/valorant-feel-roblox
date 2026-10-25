# System 22: The map vote

The goal is a vote like Counter Blox's: when a match ends, everyone picks the next map from three
chosen at random. The reference's Skirmish already has three maps, A, B and C, and its queue picks
one at random for each match. So this system builds B and C as whiteboxes beside A (system 7), and
after each match's victory screen (system 21) it holds a vote between them. The model for the vote
is Counter-Strike's end of match, the one setting out how long players get and what happens when
nobody votes.

The spike rounds still have one map, Outpost, so there's no vote there. Gun game and the menu to
pick a mode are systems 23 and 24.

As before, everything comes from public sources: Riot's patch notes, the Skirmish minimaps
credited to Riot in Sheep Esports' article on the mode (measured earlier, and neither kept nor
committed), and for the vote the documentation of Counter-Strike's server settings and the
Counter-Strike Wiki. No game files, memory or network traffic were used. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (patch notes, a developer's post) |
| **Community** | Published by a wiki, guide or a server-settings reference, not by the maker |
| **Measured** | Ours, measured from a public source: here, the pixels of the published minimaps |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **Skirmish's maps.** Three layouts of one hall, A, B and C, which differ only in their cover.
  Matchmaking picks one at random for each match.
- **Counter-Strike's end of match.** Players vote for the next map from a list. The list holds up
  to ten maps, chosen at random from the server's map group when it has more. By default the map
  just played is kept in the list, and players have 20 seconds. With the vote off, the next map is
  picked at random.
- **Counter Blox.** Three random maps after each game, as the goal says. Its own rules aren't
  published.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Small combat spaces with 3 unique layouts, selectable from the Custom Game Lobby as Skirmish A, Skirmish B, and Skirmish C"; "Each layout is designed to accentuate different combat styles" | [Patch 11.07b](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-07b/) |
| The 2v2 queue's map is "randomly selected each match" | [Patch 12.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-12-03) |
| The three minimaps side by side, unlabelled: "The three skirmish minimaps - Credit: Riot Games" | [Sheep Esports](https://www.sheepesports.com/en/articles/valorant-riot-games-unveils-new-skirmish-game-mode-at-champions-2025/en) |

### From the community: Counter-Strike's vote

| Setting | What it does | Source |
| --- | --- | --- |
| `mp_endmatch_votenextmap` | It "enables and disables the option for players to vote for the next map at the end of the game". Default 1. With 0 "the next map is chosen at random" | [Total CS](https://totalcsgo.com/commands/mpendmatchvotenextmap) |
| `mp_endmatch_votenextleveltime` | It "sets how much time (in seconds) players have to vote for the next map at the end of the game". "Default is 20." | [Total CS](https://totalcsgo.com/commands/mpendmatchvotenextleveltime) |
| `mp_endmatch_votenextmap_keepcurrent` | It "sets whether or not the current map is allowed to be voted for at the end of the game". Default 1: "players can vote again for the same map" | [Total CS](https://totalcsgo.com/commands/mpendmatchvotenextmapkeepcurrent) |
| The list | "If a server is running a map group with more than 10 maps in it, a random set of 10 maps will be selected from the group" to be "shown to clients at the end of the match in the map vote list". With `keepcurrent` off, "the current map is not guaranteed to be in the list and will randomly enter the list like any other map" | [Counter-Strike Wiki, the patch of March 8, 2013](https://counterstrike.fandom.com/wiki/Counter-Strike:_Global_Offensive_patches/March_8,_2013) |

Nothing public says how Counter-Strike settles a tie, or whether a vote can be changed, and
Counter Blox's own rules aren't published. Everything not in these tables is ours, and labelled.

### B and C, measured

System 7 measured all three minimaps. Positions are fractions of the hall's width across it from
the left wall, and of its length down it from side 1's wall at the top; sizes are fractions of the
width, and a tilt is clockwise on the minimap. Every layout lands on itself turned half way round
its centre, so only one of each pair is listed.

| Map | Cover, measured |
| --- | --- |
| B | A screen 0.25 x 0.083 across the hall at (0.50, 0.16), in front of the spawn. A 0.10 centre block. A small crate (0.086) turned 15 to 20 degrees at (0.25, 0.26). A long crate with a small one at its end, 0.27 x 0.13 together, turned 25 degrees at (0.70, 0.35). Against the left wall at 0.44 down it, a long crate with a small one on its hall side, 0.17 out from the wall |
| C | A Z through the centre, 0.25 wide and 0.30 of the length long: a column 0.08 wide, with a block on its upper right and its partner on its lower left. A long crate out from the middle of each long wall, 0.19 long, with a small crate beside it at the wall. A double crate 0.17 x 0.087 at (0.34, 0.19). An L of three crates about 0.16 x 0.15 of the length at (0.76, 0.20). A small crate turned about 15 degrees at (0.21, 0.35). A small crate on the end wall beside the spawn's opening, at 0.34 across |

B's rooms measured a little wider (0.27) and C's hall a little longer (1 : 1.36). The article says
the three "share the same overall layout but differ in the placement of obstacles", so both are
read as measuring error, and all three use A's hall.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| Which panel is B and which is C | Play Skirmish B and C in a custom game and compare each with the panels. Ours is the middle panel for B and the right-hand one for C |
| How the crates sit in B's and C's groups, and their heights | In a custom game, as system 7 does for A: walk round each group, and stand, crouch and jump beside each piece |
| Which way B's and C's small crates turn | The same visit, from above the spawn |
| How long a vote should last | A public clip of a Counter Blox or Counter-Strike community server's end of match, from the vote's start to the next map. Ours is 15 s |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Skirmish's maps | A, B and C, sharing A's hall and its rooms | Confirmed (three layouts); community (the same hall) |
| The spike rounds' maps | Outpost only, so no vote | Ours |
| The first match on a server | On one of the three at random | Confirmed ("randomly selected each match") |
| When the vote comes | After the victory screen's 10 s | Ours (the goal: a victory screen, then the vote) |
| What's offered | Three maps, chosen at random from the mode's, the one just played among them like any other. With three maps, all three | Ours (the goal); community (Counter-Strike's list is random from the group) |
| How long | 15 s | Estimate (Counter-Strike's default is 20 s) |
| Who votes | Everyone in the server, playing or waiting in line, one vote each, which they can change until the time is up. Someone leaving takes their vote with them | Estimate |
| The winner | The most votes. A tie is settled at random between the maps tied for the most, and no votes at all picks any of them at random | Community (random without a vote); estimate (the tie) |
| During the vote | Nothing goes in the record, and nobody spawns. Someone joining is down until the next match, and can vote | Estimate |
| A side emptying during the vote | The vote ends there, the score goes back to 0-0, and the next match is on the same map, as whoever's left plays on in it | Estimate |
| The next match | Everyone spawns in their room on the new map, at 0-0, on the starting kit | Ours |
| B's and C's cover | Where each piece stands, how big it is and how it's turned, as measured. How the crates sit inside each group, which way the small crates turn, and the heights are ours: B's screens and centre block, the long crates, the Z, C's double crates and the L's pair 2.0 m, the rest 1.3 m | Measured; estimate (the rest) |

What the maps give (from `luau tests/run.luau`; the hall is A's, 19.0 x 25.1 m):

| Map | Pieces of cover | Lines from one room to the other that are open |
| --- | --- | --- |
| Skirmish A | 15 | None standing, 5% at the top of a jump |
| Skirmish B | 13 | None standing, all at the top of a jump |
| Skirmish C | 23 | None standing, all at the top of a jump |

B and C have nothing as tall as A's 3 m centre block, so a jump in the spawn sees the other spawn
over the cover. The barriers stop bullets during the buy phase, and after it everyone has left.

## 5. Design

### The maps

`ArenaLayout.Maps` holds each map's name and its cover, one of each pair, with the status and source
of its numbers, and `ArenaLayout.MAPS` lists them in order. `hallParts()` is what every map shares
(the floor, the walls, the rooms, their barriers and the grid), and `coverParts(key)` a map's
cover, with each piece's partner turned half way round. A piece at the centre is its own partner,
as A's centre block was. `parts(key)` is both, for the tests, which now check every map the way
they checked A: inside the hall, the same from either end, room to move everywhere, no sightline
between the rooms, and a run out of the room once the barrier drops.

B and C, seen from above with side 1 at the top, drawn from `ArenaLayout.parts("B")` and `"C"`
with one character for 0.5 m across and 1 m down, so edges are rounded to that. `#` wall, `=`
barrier (buy phase only), `H` 2.0 m, `L` 1.3 m, `1` and `2` the spawn spots:

```
              ##############                                ##############
              ###........###                                ###........###
              ###........###                                ###........###
              ###.11..11.###                                ###.11..11.###
#################........#################    #################........#################
################==========################    #############LLLL=========################
##......................................##    ##...........LLLL.......................##
##......................................##    ##......................................##
##..............HHHHHHHHHH..............##    ##............................HHHH......##
##..............HHHHHHHHHH..............##    ##.........HHHHHHHH...........HHHH......##
##..............HHHHHHHHHH..............##    ##.........HHHHHHHH........LLLLHHH......##
##.......LLLLL..........................##    ##.........................LLLLHHH......##
##.......LLLL...........HHHHH...........##    ##......................................##
##.....................HHHHHHHH.........##    ##......LLLL............................##
##HHHH....................HHHLLLLL......##    ##......LLLL.......HHHHHHH..............##
##HHHLLLL....................LLLLL......##    ##LLLL....LL.......HHHHHHH..............##
##HHHLLLL......................LL.......##    ##LLLL.............HHHHHHH..............##
##HHHLLLL..........HHHH.............HHHH##    ##LLLLHHHH.........HHHHHHH......HHHHHHHH##
##.................HHHH..........LLLLHHH##    ##HHHHHHHH......HHHHHHH.........HHHHLLLL##
##.......LLL.....................LLLLHHH##    ##..............HHHHHHH.............LLLL##
##......LLLLL....................LLLLHHH##    ##..............HHHHHHH.......LLL...LLLL##
##.......LLLHHHHH.......................##    ##..............HHHHHHH.......LLLL......##
##.........HHHHHHHH.....................##    ##............................LLLL......##
##...........HHHHH..........LLLLL.......##    ##......................................##
##..........................LLLLL.......##    ##......HHHLLLL........HHHHHHHH.........##
##..............HHHHHHHHHH..............##    ##......HHHLLLL........HHHHHHHH.........##
##..............HHHHHHHHHH..............##    ##......HHHH...........HHHHHHHH.........##
##..............HHHHHHHHHH..............##    ##......HHHH............................##
##......................................##    ##.......................LLLL...........##
##......................................##    ##.......................LLLL...........##
################==========################    ################=========LLLL#############
#################........#################    #################........#################
              ###.22..22.###                                ###.22..22.###
              ###........###                                ###........###
              ##############                                ##############
              ##############                                ##############
```

### The vote

`MapVote` is the vote as plain state: `new` picks the options with the dice it's given, `cast`
and `drop` take and remove a vote, `tally` counts them, and `winner` settles the result, rolling
the dice for a tie. The rules pass in the dice (`math.random` in the game, loaded dice in the
tests), so the offline tests play every outcome.

### The rules

`ArenaRules` keeps the maps it plays on, the map being played (the first at random) and, after a
match, the vote:

```
          10 s                       15 s, everyone votes
  matchOver ────► vote (3 at random) ───────────────────► buy, round 1 at 0-0, on the winner
      │                      │
      │ one map only         │ a side empty: waiting at 0-0, on the same map
      └────────────────────────────────────────────────► buy, round 1 at 0-0
```

`ArenaRules.vote` takes a vote from anyone the rules know, playing or in line. `ArenaRules.skip`
ends the phase under way for scripted checks, as `MatchRules.skip` does, and gives a round to
side 1, as Skirmish's rounds have no clock.

### The server

`Arena` builds the hall once, then a map's cover whenever the map played changes, replacing the
last one's parts: at the start of a match, with everyone respawning in their rooms. It publishes
the map and, during the vote, the options and their counts on the arena's model (`Map`, `MapVote`,
`VoteMaps`, `Votes`), and each player's own vote as `VFMapVote`. The `Vote` remote takes a vote by
its number in the list, and the rules decide whether it counts.

### The client

- **`VoteScreen`.** While the phase is `vote`, three cards side by side, each with the map's
  name, its plan seen from above (taller cover lighter) and its votes, and the time left. A click
  on a card votes for it, and your pick is outlined in gold. The cursor is free while it's up,
  as in the buy menu, so the mouse buttons don't fire.
- **`Scoreboard`.** The victory screen's footer counts down to the map vote where there is one,
  and Tab shows the result again during the vote.
- **`ArenaHud`.** Round 1's buy phase names the map.
- **`Spectate`.** Its labels give way to the vote, as they do to the victory screen.

### Not here yet

- **More maps.** The vote already picks three at random from more. A second map for the spike
  rounds would give them a vote too.
- **A Play menu.** System 24. Gun game, system 23, is played on the same three maps with the same
  vote after each match ([23-gun-game](23-gun-game.md)).

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Arena/ArenaLayout.luau` | Skirmish B and C beside A; the hall and each map's cover apart |
| `src/shared/Match/MapVote.luau` | New: the vote as plain state |
| `src/shared/Arena/ArenaRules.luau` | The map played, the vote after a match, and `skip` |
| `src/shared/Arena/ArenaConfig.luau` | `VOTE`, `Rules.voteChoices` (3) and `voteTime` (15 s) |
| `src/shared/Net/Remotes.luau` | The `Vote` remote |
| `src/server/Arena.luau` | Each map's cover built in turn, the vote published and taken, and `VFMatchSkip` in Skirmish |
| `src/client/VoteScreen.luau` | New: the vote's cards |
| `src/client/Scoreboard.luau` | The countdown to the vote, and the result on Tab during it |
| `src/client/ArenaHud.luau` | The map's name in round 1's buy phase |
| `src/client/Spectate.luau` | Its labels hidden during the vote |
| `src/client/Debug/TestAim.luau` | `VFTestVote` |
| `tests/mapvote.luau` | 31 checks: picking the options, votes, ties, no votes, leaving, joining and a side emptying during the vote, one map, and `skip` |
| `tests/arena.luau` | The map checks for every map |

## 7. Debug tools

- Output says which map a server starts on: `[VF] Arena on: Skirmish B`.
- The arena's model has `Map` (`A`, `B` or `C`), and during the vote `VoteMaps` (`A,B,C`) and
  `Votes` (`2,0,1`). Each player's `VFMapVote` is their vote, by its number in the list.
- `VFMatchSkip`, set true from the server, now works in Skirmish too: it ends a buy phase, gives
  the round to side 1, and ends the wait for the next round, the victory screen and the vote.
- `VFTestVote` set to 1, 2 or 3 on the local player votes as a click on that card does (Studio
  only).

## 8. Refinement loop

1. Play Skirmish B and C in a custom game, check which panel is which, and take system 7's
   measurements for each, then set their pieces and heights in `ArenaLayout.Maps`.
2. Time a Counter Blox or community server's map vote in a public clip, and set `voteTime`.
3. Re-run `luau tests/run.luau`: every map must still hold.

## Known gaps to check in Studio

- Each map's cover builds where it should, with nothing left over from the last.
- The vote shows by itself after the victory screen: three cards, a click votes and outlines the
  card, and the counts and the time change for everyone.
- The next match starts on the winner, with the map's name in the buy phase.

Section 26 of the [Studio checklist](../studio-checklist.md) covers these.
