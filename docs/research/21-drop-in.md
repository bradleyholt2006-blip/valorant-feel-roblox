# System 21: Matches that never stop

The goal is servers like Counter Blox's on Roblox: you click play and drop into a match that's
already under way, so nobody queues. One match follows another on the same server, and a
victory screen shows every player at the end of each. The reference has no servers like that. Its
matches are made by a queue, start with ten players and end with everyone leaving. So the model
for this system is a Counter-Strike community server, which Counter Blox follows. It runs whether
anyone's there or not, players come and go mid-match, and its settings say what happens when
they do.

This system makes the arena (system 7) and the spike rounds (system 13) run that way. A live
server plays Skirmish, the 2v2 mode, from the moment it starts. Joining mid-match puts you on the
side with fewer players, and you either spawn at once or watch a teammate until the next round.
Past the mode's team size you wait in line for a place. The sides are evened out before each
round. Skirmish keeps the same record as the spike rounds now, and each match ends on a victory
screen before the next starts. Choosing the next map, other modes such as gun game, and a menu to
pick a mode come after this, as systems 22 to 24.

As before, everything comes from public sources: Riot's own pages, and for the server's rules the
documentation of Counter-Strike's server settings and the Counter-Strike Wiki. No game files,
memory or network traffic were used, and nothing reads either game while it runs. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (patch notes, the game's own store page, a developer's post) |
| **Community** | Published by a wiki, guide or a server-settings reference, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

## 1. Observable behaviour

- **A server that's always on.** A Counter-Strike server plays its map round after round, and a
  player who connects joins the match where it is.
- **Joining mid-round.** Unless the server allows a grace period, someone who joins after a round
  has started watches until the next round, then plays.
- **Even teams.** The server keeps the teams within a player of each other, moving players across
  between rounds when they aren't.
- **Watching.** In competitive play the dead watch their living teammates in first person,
  switching between them with the mouse buttons.
- **The end of a match.** A Counter-Strike server can hold a vote for the next map at the end of
  the match. The reference's end of match shows everyone's scores and names the best players its
  MVPs.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| Five a side | "Valorant is a character-based 5v5 tactical shooter set on the global stage." ([PlayStation Store page](https://www.playstation.com/en-us/games/valorant/)) |
| Two a side in Skirmish's queue | "Skirmish comes to matchmaking as a 2v2 queue for a limited time" ([Patch 12.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-12-03)) |

### From the community: Counter-Strike's server settings

| Setting | What it does | Source |
| --- | --- | --- |
| `mp_join_grace_time` | It "sets the amount of time (in seconds) that a player can join the game for after a round starts". Players who join after it "will be added to the spectators until the next round". "Default is 0 (players cannot join after round has started)." | [Total CS](https://totalcsgo.com/commands/mpjoingracetime) |
| `mp_autoteambalance` | "This feature will swap players around teams at the end of a round if there are an unequal amount of players on either time." Default 1, on | [Total CS](https://totalcsgo.com/commands/mpautoteambalance) |
| | "The teams are balanced to equal or +1 players." | [Fragnet's CS:GO RCON commands](https://kb.fragnet.net/Games/CS%20GO/CSGO_RCON_commands/) |
| `mp_limitteams` | "Max player imbalance between teams (0=no limit)". Default 2 | [csdb.gg](https://csdb.gg/command/mp-limitteams/) |
| `mp_forcecamera` | "Set this to 1 to allow players to only spectate their own team." Default 1 | [Total CS](https://totalcsgo.com/command/mpforcecamera) |
| `mp_endmatch_votenextleveltime` | It "sets how much time (in seconds) players have to vote for the next map at the end of the game". "Default is 20." | [Total CS](https://totalcsgo.com/commands/mpendmatchvotenextleveltime) |

### From the community: watching

| What | Source |
| --- | --- |
| In competitive play "dead players can only watch their teammates in first person". In casual they "are allowed to spectate both their teammates and their enemies" | [The Counter-Strike Wiki's Spectator page](https://counterstrike.fandom.com/wiki/Spectator) |
| Players are switched with "left and right mouse button" by default | The same page |
| "If a team was eliminated", the dead's cameras "will be frozen at the last viewed position of the last player" | The same page |

### From the community: the reference's MVPs

| What | Source |
| --- | --- |
| "The player with the highest ACS between the two teams is considered the Match MVP", and "the player with the highest ACS of any team is rewarded as that team's Team MVP" | [Sportskeeda](https://sportskeeda.com/valorant/valorant-beginners-guide-what-acs-mean) |
| "The person with the highest ACS at the end of a competitive VALORANT match is crowned the Match MVP." "ACS is the sole determining factor." | [esports.net](https://www.esports.net/wiki/guides/acs-explained-valorant/) |
| Since the "September 22, 2026 update", a Performance Score decides them instead, and "the average combat score (ACS) no longer exists in VALORANT". "The publisher doesn't detail which elements are taken into account." | [playnews.gg](https://www.playnews.gg/en/guides/valorant-performance-score-what-does-it-measure-and-who-gets-the-mvp) |
| "Performance Score determines your placement on the leaderboard, with the top players becoming Match and Team MVPs." | [Dot Esports](https://dotesports.com/valorant/guides/valorant-performance-score) |

The Performance Score's formula isn't public, so the MVPs here are still picked by the combat
score (system 16).

Nothing public gives how long the reference's end-of-match screen shows, since it ends the session
rather than leading to another match. Counter Blox's own rules aren't published either. Everything
not in these tables is ours, and labelled as an estimate.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How long a victory screen should stay | A public clip of a Counter Blox or Counter-Strike community server's match ending, from the last kill to the next match's start. Ours is 10 s |
| How long a death holds the view | A clip of a competitive Counter-Strike death, from the kill to the camera moving to a teammate. Ours is 2 s |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Always on | A live server starts Skirmish as it starts, or what the place's `VFArenaMode` says. Studio starts on the course, the practice range, unless the place's `VFArenaOn` is true | Ours (the goal) |
| Team size | Two a side in Skirmish, five in the spike rounds | Confirmed |
| Joining | The side with fewer players, side 1 when level | Community (`mp_autoteambalance`: "equal or +1") |
| Joining in a buy phase, or while waiting for an opponent | You spawn at once | Estimate (the buy phase is before the round's fighting starts) |
| Joining later | You're down until the next round starts, and watch a teammate meanwhile | Community (`mp_join_grace_time` 0: "added to the spectators until the next round") |
| Both sides full | You wait in line, first come first served, on no side, and see your place. When a player leaves, the first in line takes their place, as if they'd just joined | Estimate (a Counter-Strike server has a player cap instead) |
| Evening out | Before each round starts, while one side has two or more players more than the other, the last to join it moves across | Community (at the end of a round, "equal or +1") |
| Pay for a move | Someone moved across is paid for the round just played on the side they played it for | Estimate |
| The record | The same in both modes: kills, deaths, assists and the combat score. A round counts toward the average only for those in it from its start | Community (ACS is per round played); estimate (a round sat out) |
| Watching | Your side's living players in first person, from their eyes as they're drawn. Left click watches the next, right click the one before | Community (competitive's rule, the buttons) |
| Anyone not on a side | May watch anyone alive, as may someone who has just joined with nothing to look at yet | Community (casual's rule); estimate (just joined) |
| A death | The view stays where it was for 2 s, yours or the watched player's, then moves on. A click ends it early. With nobody left to watch, it holds where it was | Estimate (2 s); community (the hold) |
| The victory screen | 10 s, in both modes: everyone's kills, deaths, assists and average combat score under the result, the time left under them, then the next match starts on the same server | Estimate (10 s, half Counter-Strike's 20 s map vote, which system 22 will add) |
| MATCH MVP | The best average combat score of the match; a tie goes to the side that won | Community (by ACS); estimate (the tie) |
| TEAM MVP | The best on the other side | Community |
| No MVP | A side's best with no score at all gets nothing | Estimate |
| The debug HUD | Off on a live server, F3 still shows it; on from the start in Studio | Ours |

## 5. Design

### Roster

`Roster` is the sides, shared by `ArenaRules` and `MatchRules`. It keeps its part of each mode's
state, so both modes join, leave, queue and balance the same way and the offline tests can play
them:

- **`openSide(size)`.** The side with fewer players, side 1 when level, or nil when both have
  `size`.
- **`add` and `remove`.** `add` puts a player on the open side, alive or not, with the mode's
  credits, or at the end of the line when there's none. `remove` takes them out of either.
- **`nextInLine` and `placeInLine`.** Who's first in line, taken out of it once a side has a place,
  and where someone stands.
- **`balance`.** While one side has two or more players more than the other, the member with the
  latest join on the bigger side moves across. Each member's join order is also their spawn spot
  (`spotOf`), so the one moved takes the last spot on their new side.
- **The record.** `damaged` and `recordDeath` keep kills, deaths, assists and the combat score as
  system 16 set them out, now for both modes. `roundPlayed` counts a round for those who `played`
  it from its start.

### The modes

`ArenaRules` and `MatchRules` keep their own phases and call `Roster` for the sides:

- **`join`** admits the player: in a buy phase or while waiting they spawn, and a player who
  makes up the numbers starts the first round. Mid-round they're down, so their side's last
  player falling still ends the round.
- **`leave`** gives the place to whoever's first in line, then checks whether the round or the
  match can go on.
- **A round's start** evens the sides out, after the spike rounds have paid for the round just
  played.

`ArenaConfig.Rules.sideSize` and `MatchConfig.Rules.sideSize` set the team size, and both modes'
`matchOverTime` is the victory screen's 10 s.

### The server

`Arena.start` turns the arena on by itself on a live server, once everything it needs is set up.
`publish` seats everyone on their team from the rules each time they change (`seat`): a side's
team, or none while in line, with the place in line as `VFInLine`. It then sends every member's
record, in both modes. Mid-round joiners get no character until the next round spawns them, as
`CharacterAutoLoads` is off while either mode runs.

### The client

- **`Spectate`.** It runs after the other cameras (`Camera + 3`) while you're down with the
  arena on. It picks someone to watch from the player attributes and puts the camera at their
  eye, drawn where `RemoteEntities` draws them (`CameraController.lookFrom`). It also tells
  `RemoteEntities` to leave their blocks out (`viewing`). It holds the view through a death and
  shows who you're watching and when you play.
- **`Scoreboard`.** Tab works in both modes, with credits only in the spike rounds. At
  `matchOver` it shows by itself as the victory screen: VICTORY or DEFEAT (MATCH OVER for anyone
  not on a side) between the scores, nobody dimmed, MATCH MVP and TEAM MVP where the guns go, and
  the next match's countdown under it.
- **`ArenaHud`** leaves the match's end to the victory screen. **`CombatHud`**'s death notice
  says ELIMINATED in rounds, and gives way to the name of whoever you're watching.
- **`DebugHud`** starts hidden on a live server.

### Not here yet

- **Choosing the next map.** System 22: three random maps for 15 s at the end of a match, the
  most votes winning, and two more whitebox maps to choose between.
- **Other modes.** Gun game is system 23. System 24 is a Play menu to pick a mode and join a
  server running it. Until then, live servers play Skirmish.
- **The other side's view.** Nobody on a side watches the other side, even with their own side
  all down.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/Roster.luau` | New: the sides, the line, balancing, and the record, for both modes |
| `src/shared/Arena/ArenaRules.luau` | Skirmish on `Roster`: joining mid-round, the line, balancing, and the record |
| `src/shared/Match/MatchRules.luau` | The spike rounds on `Roster`, paying for the round before balancing |
| `src/shared/Arena/ArenaConfig.luau` | `LINE`, `Rules.sideSize` (2) and `matchOverTime` (10 s) |
| `src/shared/Match/MatchConfig.luau` | `Rules.sideSize` (5) and `matchOverTime` |
| `src/server/Arena.luau` | Live servers start the arena, `seat` and `VFInLine`, and both modes' record |
| `src/client/Spectate.luau` | New: watching a teammate while you're down |
| `src/client/CameraController.luau` | `lookFrom`, someone else's eye and aim |
| `src/client/RemoteEntities.luau` | `viewing`, whose blocks are left out |
| `src/client/Scoreboard.luau` | Both modes, and the victory screen with its MVPs |
| `src/client/ArenaHud.luau` | The match's end left to the victory screen |
| `src/client/Combat/CombatHud.luau` | ELIMINATED in rounds, hidden while you watch someone |
| `src/client/Debug/DebugHud.luau` | Hidden from the start on a live server |
| `tests/dropin.luau` | 32 checks: the sides, Skirmish's drop-in and line, balancing in the spike rounds, the line at five a side, Skirmish's record, and the victory screen's time |

## 7. Debug tools

- Each player's `VFInLine` is their place in line while both sides are full.
- The record's attributes (`VFKills`, `VFDeaths`, `VFAssists`, `VFScore`, `VFRounds`) are kept in
  Skirmish too.
- Workspace's `VFArenaOn`, set true in a place before Play, starts the arena as a live server
  does.
- `VFTestBoard` holds the scoreboard open in Skirmish as in the spike rounds.

## 8. Refinement loop

1. Time a Counter Blox or community server's end of match in a public clip, and set
   `matchOverTime` to match.
2. Watch players drop into a live server and see whether the side they're put on, and the line,
   feel fair. If teams stay uneven too long, balance during the round's end instead.
3. Time a competitive Counter-Strike death to the camera moving on, and set the hold.

## Known gaps to check in Studio

- A published server starts Skirmish by itself.
- A third player joins the side with fewer players, and spawns at once in a buy phase.
- Down with a teammate alive: 2 s where you fell, then their view from their eyes, with their name
  and when you play. Their blocks aren't drawn, and clicks switch between teammates.
- Tab shows the scoreboard in Skirmish, with no credits.
- At the end of a match, the victory screen shows by itself: the result, everyone's record, MATCH
  MVP and TEAM MVP, and the countdown to the next match.
- The HUD panel (F3) shows from the start in Studio.

Section 25 of the [Studio checklist](../studio-checklist.md) covers these.
