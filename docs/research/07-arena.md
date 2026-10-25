# System 7: The arena

This covers somewhere to play rounds against a friend: a whitebox of Skirmish A, the smallest of
the three layouts of the reference's Skirmish mode (the mode its 2v2 queue plays), with
Skirmish's rules for sides, rounds and the score. Skirmish B and C and anything to do with the
spike are separate work; the buy menu came with system 9 ([09-arsenal](09-arsenal.md)).

As before, everything comes from Riot's patch notes, the community wiki and articles about the
mode, plus one image: the three Skirmish minimaps, credited to Riot, in Sheep Esports' article on
the mode. We measured that image's pixels for the plan, and the image isn't kept or committed
anywhere. No game files, memory, network traffic or protected assets were used. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Measured** | Ours, measured from a public source: here, the pixels of the published minimap |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- Skirmish is for small fights: custom games from 1v1 to 5v5, and for a limited time a 2v2 queue.
- There's no agent select, no abilities, no spike and no economy. Each round, everyone spawns on
  their own side with Heavy Armor and can pick any weapon, or keep the one they had.
- Each round starts with a short buy phase, longer in the first round, then the fight. There's no
  round timer: a round ends when one side has nobody left alive.
- The first side to win 10 rounds takes the match.
- There are three layouts, Skirmish A, B and C. They share one hall and its two spawn rooms, and
  differ in where the obstacles stand. The queue picks one at random for each match.
- Skirmish A is a rectangular hall with its corners cut off and a spawn room in the middle of each
  short wall. Each room is open to the hall across its whole width, so the two spawns face each
  other down the long axis. A big block stands in the middle with a small crate either side, two
  angled double crates stand in each half, and two crates stand against each long wall.
- Every layout looks the same from either spawn: turned half way round, the plan lands on itself,
  so neither side has better cover. None is a mirror image.

## 2. Publicly documented details

From Riot:

| Fact | Status | Source |
| --- | --- | --- |
| Skirmish in custom games: "Supports 1v1 through 5v5, including asymmetric team sizes" | Confirmed | [Patch 11.07b](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-07b/) |
| "First to 10 wins", "Unlimited round timer", "No economy system", "No abilities by default (can be enabled in Cheat Menu)" | Confirmed | The same notes |
| "Set and forget your weapon, or change loadouts each round"; "Quick rounds and transitions designed for high-repetition gameplay" | Confirmed | The same notes |
| "Small combat spaces with 3 unique layouts, selectable from the Custom Game Lobby as Skirmish A, Skirmish B, and Skirmish C"; "Each layout is designed to accentuate different combat styles" | Confirmed | The same notes |
| "Skirmish comes to matchmaking as a 2v2 queue for a limited time", with "First to 10 rounds wins", "Full weapon selection each round (no economy)", "No agent select–hop in and go next fast", and the map "randomly selected each match" | Confirmed | [Patch 12.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-12-03) |
| The three minimaps side by side, unlabelled: "The three skirmish minimaps - Credit: Riot Games" | Confirmed (the image) | [Sheep Esports](https://www.sheepesports.com/en/articles/valorant-riot-games-unveils-new-skirmish-game-mode-at-champions-2025/en) |

From the community:

| Fact | Status | Source |
| --- | --- | --- |
| "a best-of-nineteen duel mode"; "The team that kills all of the opposing team players wins the round"; "Match time is set to infinite and will only conclude when a team is defeated" | Community | [Valorant Fandom wiki, Skirmish](https://valorant.fandom.com/wiki/Skirmish) |
| Everyone spawns with Heavy Armor, again every round; credits are infinite; the first round's buy phase is 15 seconds and later ones 3 seconds; weapons can't be dropped | Community (paraphrased) | The same page |
| One map with three variations that differ in where the obstacles are. Sheep Esports: "They all share the same overall layout but differ in the placement of obstacles" | Community | The same page; Sheep Esports |
| A is "A tight central corridor with side peeks", suited to 1v1 and 2v2. B is "Slightly larger, featuring a few elevation changes and corners for tactical plays", and C is "The biggest layout, suitable for full 5v5 battles" | Community (B's and C's sizes disagree with the line above and with the minimaps) | [thespike.gg](https://www.thespike.gg/valorant/maps/skirmish) |
| "There is no spike, no abilities, and no buy phase" | Community (disagrees with the wiki's buy phase) | [talkesport](https://www.talkesport.com/news/valorant-skirmish-2v2-new-game-mode-patch-12-03/) |
| "no guns or projectiles can do damage to teammates in Valorant" | Community | [talkesport](https://www.talkesport.com/news/valorant-to-add-friendly-fire-penalty-to-deal-with-griefers-in-new-patch/) |

**Not found publicly:** any size or height (the minimap has no scale bar, grid or doors), what
holds players in their spawn during the buy phase, how long passes between a round's last kill
and the next round, how the end of a match is shown and what follows it, where each player of a
2v2 side starts, which of the three minimaps is A, and what the obstacles are made of (whether
bullets go through them). Section 3 says how to measure each.

### The minimap, measured

We measured the image's pixels: the grey floor, the obstacles' white outlines, and each
obstacle's centre, size and angle. Positions are fractions of the hall's width across it, from the
left wall, and of its length down it, from side 1's wall at the top. Sizes are fractions of the
width. A tilt is the angle of the piece's long side on the minimap, positive clockwise. Everything
here is Measured, except which panel is A.

| What | Measured |
| --- | --- |
| The hall | Width to length 1 : 1.32 (286 x 378 px for A). Each corner is cut at 45 degrees, 0.03 of the width along each wall |
| The spawn rooms | One in the middle of each short wall, 0.245 of the hall's width wide and 0.175 of its length deep, open to the hall across all of it. The rooms and the hall together are 1.78 widths long |
| Heights, ramps, steps | None shown: a flat plan |
| Symmetry | Every layout lands on itself turned half way round its centre. None is a mirror image |
| Centre block | A 0.16 square at (0.50, 0.50) |
| Side crates | 0.086 squares at (0.21, 0.50) and (0.79, 0.50) |
| Double crates | Two 0.087 squares side by side (0.175 x 0.087): (0.31, 0.19) at -20 degrees, (0.65, 0.28) at +20, (0.35, 0.72) at +17, (0.69, 0.81) at -20 |
| Wall crates | 0.085 squares against the long walls: the left wall at 0.34 and 0.80 down it, the right wall at 0.20 and 0.65 |
| Which panel is A | The left one. This is an assumption, from the order the wiki lists the layouts' files (A, B, C) |

Each pair agrees to within 0.01 of the width, except one double crate's angle (20 and 17 degrees).
B and C, measured the same way, have the same hall, except that C's is a touch longer (1 : 1.36)
and B's rooms are a little wider (0.27):

- **B:** a long screen (0.25 x 0.083) across the hall in front of each spawn, a smaller centre
  block (0.10), small crates turned 15 to 20 degrees, a long crate with a small one beside it
  angled across each half, and a group of crates against each long wall.
- **C:** a Z-shaped spine of crates through the centre, a long crate against the middle of each
  long wall, a double crate and an L-shaped stack of three crates in each half, small crates turned
  about 15 degrees, and a small crate on each end wall beside the spawn opening.

## 3. What can be measured, and how

From your own copy of the game, played normally, in a custom game on Skirmish A, with screenshots,
a video (Windows' Game Bar or your graphics driver's recorder) and a stopwatch. Never use any tool
that reads the game's memory, files or network traffic.

| Measurement | Method | Gives us |
| --- | --- | --- |
| Which minimap is A | Walk round Skirmish A and compare its obstacles with the three minimaps | Confirms the panel we built from |
| The scale | With the knife out (6.75 m/s, [01-movement](01-movement.md)), run straight across the hall from one long wall to the other, then down it from one room's opening to the other's. Count the video's frames | The hall's width and length in metres. The width sets the whole plan's scale (`hallWidth`), and the length checks the 1.32 |
| Heights | Stand, crouch and jump beside each kind of obstacle: can you see over it? With a friend behind it, standing and crouched, how much of them shows? | Which height band each piece is in (section 5), or its height |
| The buy phase | Time from the round's start to when you can leave your spawn, in round 1 and in a later round | `firstBuyTime` and `buyTime`, and which source in section 2 is right |
| What holds you in | During the buy phase, walk into your spawn's opening and try to shoot out of it | Whether it's a barrier, and whether it stops bullets |
| Between rounds | Time from a round's last kill to the next round's start, and at 10 wins, from the last kill to whatever follows | `roundOverTime`, `matchOverTime` |
| 2v2 spawns | Where each player of a side starts | `spotSpacing` |
| What the cover is made of | Shoot each kind of obstacle with a Vandal and a Classic: does a bullet go through? | Each piece's material for wall penetration ([05-wall-penetration](05-wall-penetration.md)) |

Our side is measured the same way in Studio, counting by the 2 m grid on the hall's floor.

## 4. Confirmed vs estimated, as implemented

The rules live in `src/shared/Arena/ArenaConfig.luau` and the map in
`src/shared/Arena/ArenaLayout.luau`, each value with its status and source.

| Parameter | Value | Status |
| --- | --- | --- |
| To win the match | 10 rounds | Confirmed |
| Round timer | None | Confirmed |
| Economy | None: anyone can buy any gun or shield during the buy phase, from the buy menu (B), and nothing is charged | Confirmed (no economy, full weapon selection) |
| Your weapons between rounds | Kept until you pick others | Confirmed ("Set and forget your weapon") |
| Your weapons in a new match | The starting kit again: Vandal, Classic, knife and Heavy Armor | Estimate |
| Abilities | None (the project has none yet) | Confirmed |
| Winning a round | The other side has nobody left alive | Community |
| Teammates | Bullets pass through them | Community |
| Armour | Full health and a full shield at every spawn: Heavy Armor (50), as on the course, unless you've bought another | Community (Heavy Armor every round); estimate (keeping one you bought) |
| Buy phase | 15 s in round 1, 3 s after | Community |
| What holds you in | A barrier across your room's opening during the buy phase, which stops players and bullets | Estimate |
| Next round | 3 s after the round's last kill, with everyone respawned, dead or alive | Estimate |
| The end of a match | The result shows for 6 s, then a new match starts at 0-0 | Estimate |
| Nobody to play against | The arena waits: you can pick any weapon, and you're back 3 s after dying | Estimate |
| Sides | Each new player joins the side with fewer players (side 1 when level) and spawns in their room straight away, in the round being played | Estimate |
| The hall's width | 19 m | Estimate |
| The hall's length | 1.32 widths (25.1 m) | Measured |
| Spawn rooms | 0.245 widths wide, 0.175 lengths deep (4.7 x 4.4 m), open across their width | Measured |
| Cut corners | 0.03 widths (0.57 m) along each wall | Measured |
| Cover: where, how big, at what angle | As in section 2, each pair the mean of its two | Measured |
| Side and wall crates | 1.3 m tall | Estimate |
| Double crates | 2.0 m tall | Estimate |
| The centre block | 3.0 m tall | Estimate |
| Walls | 5 m tall, far above a jump | Estimate |
| Spawn spots | Two per room, 2 m apart, halfway back, facing the hall | Estimate |
| What it's made of | SmoothPlastic everywhere, which bullets don't go through | Estimate |

What the numbers give (from `luau tests/run.luau`):

| Hall | Spawn rooms | Spawn to spawn | Hall, corner to corner | Lines from one room to the other that are open |
| --- | --- | --- | --- | --- |
| 19.0 x 25.1 m | 4.7 x 4.4 m | 29.5 m | 31.5 m | None standing, 5% at the top of a jump |

## 5. Design

```
 P (Studio or the place owner) ──► Arena remote ──► Workspace.VFArenaOn ──► on or off
   on:  teams North and South, Players.CharacterAutoLoads off, everyone joins a side
   off: everyone back on the course on no team, CharacterAutoLoads on
 Heartbeat, after the frame's snapshot ──► Arena.step ──► ArenaRules.step ──► who to spawn
 PlayerSimServer
   spawnPicker      a new life starts in its side's room, facing the hall
   loadoutRule      buying (the menu, and 5 to 9) is open in the buy phase, and while waiting
   deathListeners   a death ──► ArenaRules.died ──► is the round over?
 on every change ──► the arena model's attributes (Phase, Round, Score1, Score2, ...) ──► ArenaHud
                 ──► the barriers: up in the buy phase, gone otherwise
```

```
            both sides have someone          15 s in round 1, 3 s after
  waiting ──────────────────────────► buy ──────────────────────────────► live
     ▲                               ▲ ▲                                   │ a side has nobody alive,
     │                               │ └──── 3 s ──── roundOver ◄──────────┤ so the other side scores
     │                               └─ 6 s, at 0-0 ─ matchOver ◄──────────┘ ... and that was its 10th
     └── from any phase when a side is empty: the score stays, unless the match was over
```

Every move into the buy phase respawns everyone in their rooms, dead or alive.

The plan as built, seen from above with side 1 (North) at the top. It's drawn from
`ArenaLayout.parts()` with one character for 0.5 m across and 1 m down, so edges are rounded to
that:

```
              ##############
              ##############
              ###........###
              ###.1....1.###
#################........#################
#################========#################
##......................................##
##......................................##
##..............H.......................##
##........HHHHHHH...................LLLL##
##........HHHHHHHH..................LLLL##
##........HHHH.........HHHHHH.......LLLL##
##.....................HHHHHHHH.........##
##LLLL...................HHHHH..........##
##LLLL..................................##
##......................................##
##................CCCCCC................##
##......LLLL......CCCCCC......LLLL......##
##......LLLL......CCCCCC......LLLL......##
##................CCCCCC................##
##......................................##
##..................................LLLL##
##..........HHHHH...................LLLL##
##.........HHHHHHHH.....................##
##LLLL.......HHHHHH.........HHHH........##
##LLLL..................HHHHHHHH........##
##LLLL...................HHHHHHH........##
##.......................H..............##
##......................................##
##......................................##
#################========#################
#################........#################
              ###.2....2.###
              ###........###
              ##############
              ##############
```

`#` wall, `=` barrier (buy phase only), `C` centre block (3 m), `H` double crate (2 m), `L` crate
(1.3 m), `1` and `2` the spawn spots.

- **Rules as plain state.** `ArenaRules` uses no Roblox APIs. The server module tells it who
  joins, leaves and dies and what time it is, and spawns whoever it returns. So the offline tests
  play whole matches, 1v1 and 2v2, with players leaving and joining part way.
- **One number sets the scale.** Every position and size on the plan is a fraction of the hall's
  width or length, as measured, so `hallWidth` scales all of it. The minimap's small crates are
  0.086 of the width, so at 19 m they're 1.6 m across, our guess at the reference's crates.
- **The same from either end.** Only one of each pair of obstacles is listed. Its partner is made
  by turning it half way round the hall's centre. Where the two measured differently, the plan
  takes the mean, so the sides are exactly even, and the tests check that every part has its
  partner.
- **Two heights of cover.** The minimap has no heights, so ours keep to two bands. Low crates
  (1.3 m) hide you crouched (1.25 m), and standing you shoot over them with your whole head
  showing. Double crates (2 m) and the centre block (3 m) hide you standing. No cover ends between
  the bottom of a standing head (1.49 m) and 0.1 m above its top (1.85 m), where it would hide
  part of your head, or your eye but not your head. Standing anywhere in your room, you can't see
  into the other one. At the top of a jump, 5% of the lines between them are open, over the double
  crates.
- **Room to move everywhere.** The tests fill the floor on a 20 cm grid with a box 0.2 m wider
  than a player: with the barriers down it's all one space, so there's no pocket you can't reach
  and every gap is wide enough, and with them up each side is held in its room.
- **Barriers.** Each room's opening has a ForceField part across it. In the buy phase it collides
  and blocks queries, so neither players nor bullets get through. The rest of the time it's
  invisible and blocks nothing, because our movement and our shots only test parts that collide.
  The tests run the real movement code at it: held in for 3 s with it up, out into the hall with it
  down.
- **A round restart respawns players who are alive.** Each round starts with everyone in their
  room, so the server gives a new character to players who are still alive. Until now a new life
  only began after a death, when the owner had stopped sending moves. Now the owner can still be
  sending moves for the old life when the new one starts. Those would run on the new character,
  and the owner, which starts its prediction of the new life from the spawn, would be corrected.
  So each life numbers its inputs from 65,536 past the last one the server ran
  (`InputQueue.LIFE_GAP`), and tells the owner where to start (the character's `VFFirstSeq`
  attribute). The server drops anything below that. The owner ignores acks from the old life, and
  acks from a new life its character hasn't reached yet. It can't keep sending for an old life
  for more than about 12 seconds (1,536 ticks), far below the gap. The net tests start a life while
  a client is alive and check that both sides run the new life the same.
- **Teams.** The two sides are Roblox teams, North and South, which nobody is put on
  automatically. The look (system 6) already outlines a player on your team in blue, and now a
  bullet passes through a teammate, as the reference's guns do.
- **On and off at any time.** P asks the server (in Studio, or from the place's owner) to set
  Workspace's `VFArenaOn`, which scripted checks can also set from the server. Off puts everyone
  back on the course on no team, and Roblox spawns players again.
- **Joining and leaving.** A new player joins the side with fewer players and spawns straight away
  in their room, in the round being played. If a side empties, the arena waits for someone to
  join it, keeping the score unless the match was over. Someone leaving who was the last one
  alive on their side loses the round for it.
- **While waiting** there's nobody to play against, so the arena behaves like the course: the
  barriers are down, you can buy anything, and you're back 3 s after dying.
- **The HUD.** The top bar shows your side's score in the ally colour on the left and the other
  side's in the enemy colour on the right, with the round between them, like the reference's top
  bar. A banner says what's happening: waiting, the buy phase's countdown, the round won or lost,
  and the match's result.
- **On every client.** The arena's model streams as Persistent, so in a place with streaming on,
  every client has all of it wherever its player is.

### Roblox differences that matter

- **A new life is a new character.** The reference puts everyone back at the start of a round.
  Roblox's nearest thing is `LoadCharacterAsync`, which builds a new character, hence the life gap
  above.
- **A barrier changes late on clients.** The server raises and drops the barriers, and each client
  sees the change a moment later. Pushing on a barrier as it drops can give a small correction,
  because your prediction still has it up for that moment.
- **The buy menu.** B opens it during the buy phase and while waiting, for everyone in the arena;
  the debug keys 5 to 9 work at the same times. A new match puts everyone back on the starting
  kit ([09-arsenal](09-arsenal.md)).

### Building B and C

The three layouts share the hall and its rooms, near enough, so B and C each need their own list
of pieces like `ArenaLayout.Pieces`, from the measurements in section 2, and a way to pick one
each match. The tests' map checks (inside the hall, the same from either end, room to move, no
sightline between the rooms) apply to them unchanged.

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Arena/ArenaConfig.luau` | The rules' numbers, with status and source, and the names the server and clients share |
| `src/shared/Arena/ArenaRules.luau` | Sides, phases, rounds and the score, as plain state |
| `src/shared/Arena/ArenaLayout.luau` | The plan as measured, its heights, and every part, room and spawn spot in metres |
| `src/server/Arena.luau` | Builds the arena, turns it on and off, the teams, spawns, the starting kit for each match, the barriers, and the phase and score for clients |
| `src/client/ArenaHud.luau` | The top bar, the banner, and P |
| `src/server/PlayerSimServer.luau` | Hooks for where a life starts and which way it faces, who can change weapons, and deaths; each life's first input |
| `src/client/PlayerController.luau` | Starts a new life's inputs where the server says, ignores acks from other lives, and faces the spawn's way |
| `src/shared/Net/InputQueue.luau`, `src/shared/CharacterRig.luau` | The life gap, and the character attributes for a life's first input and its facing |
| `src/server/CombatServer.luau` | Bullets pass through teammates |
| `src/shared/Net/Remotes.luau` | The `Arena` remote |
| `tests/arena.luau` | The rules and the map, offline, and the report above |
| `tests/net.luau` | A life that starts while the player is alive |

## 7. Debug tools

| Where | Tool |
| --- | --- |
| P | The arena on and off (Studio, or the place's owner) |
| The command bar, on the server | `workspace:SetAttribute("VFArenaOn", true)`, or `false` |
| Output | `[VF] Arena on` and `[VF] Arena off` |
| The hall's floor | A grid line every 2 m, to judge distances by |
| F3 HUD | `corrections` goes up once at each spawn, as on the course, and `max` shouldn't grow at a round restart |
| Explorer, while playing | `Workspace.VFArena` and its attributes `Phase`, `Round`, `Score1`, `Score2`, `RoundWinner`, `MatchWinner`, `PhaseEndsAt` (server time) and `WinScore`; `Teams.North` and `Teams.South`; `VFArenaSide` on each player; `VFFirstSeq` and `VFSpawnYaw` on each character |

## 8. Refinement loop

1. Play Skirmish A in a custom game and take the measurements in section 3.
2. Check that the minimap we built from is A. If it isn't, measure the right one and replace
   `ArenaLayout.Pieces`.
3. Set `hallWidth` from the timed runs, and the heights from what you could see over.
4. Set the buy phase, the time between rounds and the end of a match in `ArenaConfig`.
5. If bullets go through some obstacles, give those pieces a material that wall penetration knows.
6. Re-run `luau tests/run.luau`. It checks that the map still holds (inside the hall, the same from
   either end, room to move everywhere, no sightline between the rooms, no cover in the head
   band) and says which piece breaks it. Update section 4.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- The arena builds beside the course, nothing in the place overlaps it, and every client has it.
- Each spawn puts you in your side's room facing the hall, and a round restart while you're alive
  starts the new life cleanly, with no snap back and no growth in `max` corrections.
- The barriers hold players and bullets in the buy phase and are gone when it ends. Pushing on one
  as it drops gives at most a small correction.
- Teammates show in blue and opponents in red, and bullets pass through teammates.
- The top bar and the banner follow the rounds on both players' screens.
- P turns it on and off, in Studio and for the owner of a published place, and off puts everyone
  back on the course.
- Whether 19 m feels right.

The [Studio test session](../studio-checklist.md) walks through these, with what to expect.
