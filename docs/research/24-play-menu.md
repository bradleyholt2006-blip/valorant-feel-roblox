# System 24: The Play menu

The goal asks for Counter Blox's way in: click play and drop into a match already under way, with
no queue, and a choice of modes such as 2v2, a competitive mode and gun game. Systems 21 to 23
made the matches that never stop, the vote for the next map and gun game. This system puts the
modes in front of the player: a Play menu as they join, with a card for each mode, and a server
for each mode behind it, so PLAY drops you into a match of the mode you picked.

Each server plays one mode. A server started by Roblox's own Play button plays Skirmish, and PLAY
for Skirmish drops you into its match. PLAY for another mode sends you to a server already playing
it with a place free, the fullest first, or opens a new one for it. Every server keeps a line in a
list that every server shares, which says what it plays and how full it is, and the menu's counts
of who plays each mode come from the same list.

As before, everything comes from public sources: Hotspawn's guide to Counter Blox, the Counter
Blox wiki, and Roblox's documentation of teleports, reserved servers, memory stores and
matchmaking. No game files, memory or network traffic were used. Nothing in this system is
measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the platform's maker (Roblox's documentation) |
| **Community** | Published by a guide or a wiki, not by the game's maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **Counter Blox's main screen.** You land on a main screen with settings, an inventory and the
  game modes. Picking a mode asks you to confirm a teleport to a new server, and once there a Join
  Match button puts you in, after a warm-up.
- **Counter Blox's servers.** Up to 14 players a server. Casual is first to 8 rounds, and Unranked
  Competitive is a 5v5 mode of its own. M opens the team menu, and the game asks you to join the
  smaller side when the teams are uneven.
- **Roblox's servers.** A place's public servers are the ones Roblox's Play button fills. A game
  can also reserve a server, which only a teleport with its access code reaches, and a player's
  own private server is reached by its owner's invitation. A teleport carries data of the game's
  choosing to the server it lands on.
- **Studio.** Teleports don't work in a playtest.

## 2. Publicly documented details

### From the community: Counter Blox

| What | Source |
| --- | --- |
| "you land on a main screen with settings, inventory, and the game modes"; the modes "Bomb Defusal, Hostage Rescue or Deathmatch"; picking one shows "This will teleport you to a new Server"; then "the Join Match button in the bottom-left corner", and a warm-up before the match starts | [Hotspawn, How to play Counter Blox](https://www.hotspawn.com/counter-strike/news/roblox-csgo-how-to-play-counter-blox) |
| "The Roblox listing caps a server at 14 players"; Casual is first to 8 round wins, and Unranked Competitive a separate 5v5 mode; "If the game says a team is uneven, join the smaller side", with M for the team menu | [Counter Blox Wiki, Your first round](https://counterblox-wiki.wiki/guides/first-round/) |

Neither says how Counter Blox picks the server a mode sends you to, what happens when its match is
full, or whether you can go back to the main screen during a match.

### From Roblox

| What | Source |
| --- | --- |
| "TeleportService doesn't support playtesting in Roblox Studio. You must publish the game and test in the Roblox client." | [Teleport between places](https://create.roblox.com/docs/projects/teleport) |
| Teleports "can fail and throw an error", and one asked for "can still fail at the last moment without throwing an error", which fires `TeleportInitFailed` | The same |
| Teleport data: "Don't pass secure data using this method; the data is visible to the client and unencrypted." Arriving, the server reads it with `Player:GetJoinData()` and the client with `TeleportService:GetLocalPlayerTeleportData()` | The same |
| `ReserveServerAsync` returns an access code and the reserved server's `PrivateServerId`; "Access codes remain valid indefinitely" | [TeleportService](https://create.roblox.com/docs/reference/engine/classes/TeleportService) |
| `TeleportOptions.ServerInstanceId` names a public server by its `JobId`, and `ReservedServerAccessCode` a reserved one; neither can be combined with the other, or with `ShouldReserveServer` | [TeleportOptions](https://create.roblox.com/docs/reference/engine/classes/TeleportOptions) |
| `TeleportResult`: `Flooded` among the reasons a teleport fails | [TeleportResult](https://create.roblox.com/docs/reference/engine/enums/TeleportResult) |
| A reserved server has a `PrivateServerId` and a `PrivateServerOwnerId` of 0; a player's own has its owner's id. `BindToClose` gives a closing server 30 seconds | [DataModel](https://create.roblox.com/docs/reference/engine/classes/DataModel) |
| Memory: "64 KB + 1.2 KB * [number of users]"; requests: "1000 + 120 * [number of concurrent users] request units per minute"; an item's expiration "between 0 and 3,888,000"; "The data in MemoryStoreService is isolated between Studio and production" | [Memory stores](https://create.roblox.com/docs/cloud-services/memory-stores) |
| `GetRangeAsync` reads up to 200 items in key order, and `UpdateAsync`'s transform reads the old value, with nil to leave it be | [MemoryStoreSortedMap](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreSortedMap) |
| Server attributes hold "Server-specific data like the server level or game mode", and a signal's "score is multiplied by the signal's weight" | [Matchmaking attributes and signals](https://create.roblox.com/docs/matchmaking/attributes-and-signals) |

Roblox's own matchmaking weighs servers by such signals and adds up a score; it doesn't rule a
server out, and nothing says it steers teleports. So it can't keep each mode to its own servers,
and the list here does that instead.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How long PLAY takes to land you in a match | A published place: from the press to the first frame on the new server, for a server in the list and a new one |
| How often a full server is picked | A published place with several players pressing PLAY at once: count arrivals that land in line |
| Whether the counts keep up | Two servers of a mode, then one closed: how long its players stay in the menu's count |
| Counter Blox's own flow | A public clip of Counter Blox's main screen, from a mode's card to the match, and whether a full match sends you elsewhere |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| The modes | Skirmish (2v2), gun game (4v4), and the spike rounds as Unrated, Competitive and Swiftplay (5v5) | Ours, from systems 7, 13 and 23 |
| A server's mode | A public server plays Skirmish, unless the place's `VFArenaMode` says otherwise; a reserved server plays the mode its first arrival's teleport data names | Estimate (Counter Blox's servers each play one mode) |
| The menu | Up as you join a live server, until you press PLAY. After that M opens and closes it over the match | Community (Counter Blox's main screen); estimate (M) |
| PLAY for this server's mode | Into its match if it has a place, or if you're already in it or in line; once it's full, to another server of the mode, as for another mode. A player's own private server keeps you there, in line | Estimate |
| PLAY for another mode | To the server playing it with the most in its match, then the most in it, then by key, with a place for you in both; or a new reserved server if there's none | Estimate (Roblox fills public servers before opening new ones) |
| A failed teleport | Tried once more, to a new server, unless Roblox says it's flooded | Confirmed (teleports can fail late); estimate (once) |
| Giving up | 30 s after asking, if the teleport has neither left nor failed | Estimate |
| Presses | At most one send every 3 s | Estimate |
| A server's line | Its mode, how many are in it and in its match, how many each holds, how to get there and when it was written: every 15 s, and 2 s after someone comes, goes or joins its match | Estimate |
| A line gone quiet | Not trusted after 45 s, gone after 60 s | Estimate (well inside the store's limit) |
| The counts | Everyone in each mode's servers, the menu too, read every 20 s | Estimate |
| Arriving | Straight into the match of the mode you pressed PLAY for, if it's this server's | Ours |
| Studio | PLAY for another mode switches this server to it, as P does | Confirmed (no teleports in Studio) |
| The vote and the victory screen | Only for players in the match or in line; the open menu hides them | Ours |

## 5. Design

### The modes and the list

`PlayConfig` has the menu's modes: for each, its key, its name, a line on how it's won (made from
the rules' own numbers), what the arena plays for it (Workspace's `VFArenaMode`, and for the spike
rounds `VFMatchFormat`) and how many its match holds. `PlayConfig.keyOf` reads which mode the
arena plays from those attributes, so every part agrees on what a server plays.

`ServerList` is the list as plain data. A line's key is `p:` and the `JobId` for a public server,
or `r:` and the `PrivateServerId` for a reserved one. `choose` picks where PLAY sends a player:
a server playing their mode, not the one they're on, written to recently, with a way there (a
public server's `JobId`, or a reserved one's access code) and a place for them in its match and
the server. The fullest match goes first, so matches fill up and start rather than spread
players thin, then the fullest server, then the lowest key, so two servers choosing at once
choose the same. `counts` adds up each mode's players for the menu.

### The server

`ModeServers` runs it, before `Arena` starts:

```
  a public server ── plays Skirmish ──────────────┐
                                                  │   its line, every 15 s and
  a reserved server ── its first arrival's mode ──┼─► soon after a change ───► the list
                                                  │                             │
  PLAY for another mode, or this one when full ───┴─► choose ◄──────────────────┘
                                                        │
                        a server with a place ◄─────────┴──► none: reserve a new one,
                        (ServerInstanceId, or its code)       with a line for it
                                                              until it writes its own
```

A reserved server's access code is known only to the server that reserved it, so that server
writes the first line for it, with the code and the player on their way. The new server keeps the
code as it writes its own line over it, which it does once its first arrival has said its mode.
Each line expires a minute after its last write, and a closing server takes its own out.

`Arena.menuFirst` keeps everyone out of what's played until they press PLAY (`Arena.play`),
which sets their `VFPlaying` attribute. Whoever arrives with a mode in their teleport data that
this server plays goes straight in. Studio can't teleport, so there PLAY for another mode
switches the server, and the menu shows this server's own count. A player's own private server
isn't listed, and its owner's PLAY switches it, for everyone in it.

### The client

- **`PlayMenu`.** `PLAY` at the top and what this server plays, a card for each mode (its name,
  `THIS SERVER` if it plays it, its size such as `2v2`, how it's won, and `6 PLAYING` or
  `NOBODY YET`), and a gold `PLAY GUN GAME` button for the card picked. The status line says
  `TELEPORTING TO GUN GAME...`, or why not in red. On a live server the menu stays up until you've
  pressed PLAY, and comes up 5 s late if you've arrived from another server's PLAY, which should
  have put you in by then. While it's up, the mouse moves a cursor and the match shows behind.
- **`VoteScreen`.** Only for players in the match or in line, the voters the rules count.
- **`Scoreboard` and `Spectate`.** Hidden while the menu is open.

### Not here yet

- **Parties.** Friends who press PLAY together go one by one, and may land on different servers.
  `choose` takes a group's size for when they don't.
- **Two at once.** Two servers sending players to the last place of a match at once both send
  them, and the second waits in line there. PLAY again sends them on.
- **Back to the menu.** M opens the menu over the match. Leaving the match without leaving the
  server isn't possible.
- **The place's server size.** Roblox's own Play button fills a public server to the place's Max
  Players, which should be at least 10 for the spike rounds' 5v5. A public Skirmish server's match
  holds 4, so its other players are in the menu, and PLAY for Skirmish sends them on to other
  servers.
- **A mode for the default.** Every public server plays Skirmish. Another mode as the default
  is the place's `VFArenaMode` attribute.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/PlayConfig.luau` | New: the menu's modes, which one the arena plays, the attributes and the list's rules, with status and source |
| `src/shared/Match/ServerList.luau` | New: the list's lines, where PLAY sends someone, and the counts, as plain data |
| `src/server/ModeServers.luau` | New: each server's mode and its line, PLAY's teleports and their failures, arrivals, and the counts |
| `src/server/Arena.luau` | `menuFirst`, `play`, `has` and `playing` |
| `src/server/init.server.luau`, `src/shared/Net/Remotes.luau` | `ModeServers.start` before `Arena.start`, and the `Play` remote |
| `src/client/PlayMenu.luau` | New: the menu |
| `src/client/VoteScreen.luau`, `src/client/Scoreboard.luau`, `src/client/Spectate.luau` | The vote for players in the match, and all three hidden while the menu is open |
| `src/client/Debug/TestAim.luau` | `VFTestPlayMenu` and `VFTestPlay` |
| `tests/play.luau` | New: 34 checks: the modes and what the arena plays for each, the lines and where PLAY sends someone, and the counts |

## 7. Debug tools

- M opens and closes the menu, when it may close.
- TestAim's `VFTestPlayMenu` (true or false) opens and closes it, and `VFTestPlay` (a mode's key)
  presses PLAY for that mode, without the mouse.
- Workspace's `VFModeCounts` is what the menu counts (`skirmish=2,gungame=0,...`), and
  `VFPlayMenu` whether this server has players pick first. Each player's `VFPlaying` is whether
  they've pressed PLAY here.
- In Studio, a place with `VFPlayMenu` ticked starts with everyone in the menu, as a live server
  does.
- On a live server, Output's warnings start `[VF] Server list:` when the list can't be read or
  written.

## 8. Refinement loop

1. Publish, and time PLAY from the press to the match, to a server in the list and to a new one.
2. Have several players press PLAY at once, and count who lands in line. If it's often, reserve a
   place in a line when choosing it.
3. Watch the counts as servers open and close, and tune `refresh`, `stale` and `listEvery`.
4. If a public clip shows Counter Blox's main screen, compare its flow with ours.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- M opens the menu over the course or a match: five cards, `THIS SERVER` on the one the server
  plays, and counts that follow who's in the server.
- PLAY for another mode switches the server to it, and the menu closes.
- PLAY for the mode the server plays closes the menu, and nothing else changes.
- The vote and the victory screen hide while the menu is open.
- On a live server only: the menu is up as you join, PLAY for Skirmish drops you into the match,
  and PLAY for another mode teleports you to a server playing it.

Section 28 of the [Studio checklist](../studio-checklist.md) covers these.
