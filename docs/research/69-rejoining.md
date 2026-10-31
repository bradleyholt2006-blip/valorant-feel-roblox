# System 69: Rejoining a match

A player who drops out of the spike rounds' match under way, by a crash, a lost connection or
closing the game, keeps their place in it until it ends: their kills, deaths, assists, combat score
and rounds, their side, their credits, paid each round as their side is, and their agent, which no
teammate can lock in meanwhile. A bot fills in for them while they're away. Coming back, the Play
menu has the match's mode picked and PLAY reads RECONNECT: on the match's own server it puts them
back, and from another it sends them back there. The bot on their side gives way as soon as it's
down or nothing's at stake, and they're back on their side. In Competitive, a player away at the
match's end, or back too late to have played half its rounds, takes the loss that leaving always
cost; one back in time takes the match's real result instead.

That a player can reconnect, and that their agent stays in the match meanwhile, is the reference's;
what's held, the bot that fills in and what the career counts are ours, as the reference's rules for
them aren't published, and its remake vote isn't in. No game file or source code was read, and
nothing was read from the live game.

## 1. Observable behaviour

- A player who disconnects can reconnect to the match in progress, and their agent stays in it while
  they're gone: it can die there.
- The rest of the match, a player down, goes on "with uneven teams" unless the team votes to remake
  it, which ends it with no RR won or lost, but for a penalty to the player who left.
- Leaving a match, or staying in it without playing, is AFK, and costs penalties that grow with how
  often a player does it: warnings, XP denied, queue restrictions and bans, and in Competitive RR.

## 2. Publicly documented details

| What | Source |
| --- | --- |
| "Fixed a bug where you were unable to plant the Spike after reconnecting to a match where you died while disconnected." | playvalorant.com, [VALORANT Patch Notes 6.01](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-6-01) |
| "From what we've seen, you'll be able to reconnect if disconnected," (an early guide) | Gfinity, [Valorant: How To Leave Games](https://www.gfinityesports.com/article/valorant-leave-exit-games-friends-matches-riot-games-pc) |
| "AFK (Away From Keyboard) is the act of leaving a match or not participating in a match."; "E.g. disconnecting from rounds, being present but not participating in a match, or being detected as a bot."; "a 1 day ranked restriction for players who frequently engage in excessive AFK behavior" | playvalorant.com, [VALORANT Systems Health Series - AFK and Queue Dodge Update](https://playvalorant.com/en-us/news/dev/valorant-systems-health-series-afk-and-queue-dodge-update/) |
| Players who "had either disconnected from the game, or stayed completely inactive for a prolonged period of time"; an AFK "rating" per player; penalties going "from receiving a warning, to XP denials, to queue restrictions, and eventually banned"; the trackers' details aren't given | playvalorant.com, [VALORANT Systems Health Series - AFK](https://playvalorant.com/en-us/news/dev/valorant-systems-health-series-afk/) |
| "The opportunity to remake arises when a player disconnects from a VALORANT match prior to the first round ending."; "the next round kicks off with uneven teams"; "In the competitive queue, no RR gains or losses take place after a remake."; "aside from a penalty to the player who left"; "There's a chance the disconnected player may return" | esports.gg, [How to remake in VALORANT](https://esports.gg/guides/valorant/how-to-remake-in-valorant/) |
| "All four players must select the 'Yes' option (F5 button)"; "The player who disconnected will get a penalty but the rest of your team won't suffer any losses." | Dexerto, [Valorant remake guide](https://www.dexerto.com/valorant/valorant-remake-guide-2135330/) |
| Since Patch 10.0, "Upon detecting an AFK player, the game will automatically trigger the remake for your team."; "it only mandates a majority vote of the remaining players to be successful." | Dot Esports, [Valorant shifts to automatic remake system with patch 10.0](https://dotesports.com/valorant/news/valorant-shifts-to-promising-automatic-remake-system-with-patch-10-0) |
| "Going AFK or queue dodging in Competitive games for a prolonged period of time will affect your RR" | [67-competitive-ranks.md](67-competitive-ranks.md), section 2 |

Nothing published says what a reconnecting player has kept, beyond their agent having stayed in the
match, so the rest is ours.

## 3. What can be measured, and how

The rules are plain functions, checked offline: `tests/rejoin.luau` has 34 checks, and the
suite's 4110 pass. In Studio a Local Server's players can't come back once gone, so Workspace's
`VFTestAway`, set from the server, takes a player out of the match as if they'd left, and the menu's
RECONNECT, or PLAY, puts them back (section 73 of the checklist). Each place held and let go prints
a line in Studio. Coming back from another server needs a live server, as Studio can't teleport.

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| Reconnecting | A player who left a match under way can come back to it until it ends | Confirmed | Patch 6.01 |
| What's held | Kills, deaths, assists, combat score and rounds, side, credits and agent | Estimate | Ours: the reference's agent stays in the match (Patch 6.01), and so, here, do its record and credits |
| Credits while away | Paid each round as the side is: a win, a loss and its streak, the half's and overtime's starts; no kills, and never a loss survived | Estimate | Ours, as for an agent standing in the spawn |
| While away | A bot fills the place, by system 60's quota | Estimate | Ours: the reference plays a player down, "with uneven teams" |
| The agent | Kept, and no teammate can lock it in while they're away | Estimate | Ours |
| Coming back | On their side, alive in a buy phase and else down until the next round; with both sides full, first in line until a place opens, the bot on their side the first to leave, as it's down or nothing's at stake | Estimate | Ours |
| Competitive | Away at the match's end, or back too late to have played half its rounds: a loss, as leaving was (system 67), if they'd played a round; back in time: the match's result | Estimate | Ours; the reference: going AFK "will affect your RR" |
| Other modes | Away at the end, or back too late: nothing, as leaving counts nothing in them | Estimate | Ours |
| The server closing with a place held | Leaving, as the match stands | Estimate | Ours |
| A held place's entry, for another server | Lasts 7,200 s, unless the match's end or the player's return takes it out first | Estimate | Ours |
| Remake | Not in | Estimate | Ours: a bot fills the place instead |

## 5. Design

### The place held

`MatchRules.leave` takes `hold`: a player leaving a match under way (a round of it started, and not
over) goes from `members` to `away`, down, their record, side and credits as they were, and marked
as having left (`Roster.Member.left`). Their place opens on their side as any other, so the first in
line, or a bot, can take it. Each round's pay (`payFor`) goes to everyone in `away` too, by the side
they were on: the half's and overtime's credits, the win and the loss with its streak, and
Swiftplay's schedule. The match's end lets the places go as the next match starts. A bot's never
held.

### Back

Joining again (`MatchRules.join`) puts a held player back on their side if it has room, or else on
the other's; alive in a buy phase or while waiting for an opponent, and otherwise down until the
next round, as anyone joining is. With both sides full they're first in line, ahead of anyone
already waiting, their place still held until they're in. `BotFill.plan` takes the side of the first
in line coming back to a held place, and the first bot to leave is on it, if it has any: so the one
that filled in for them gives way, as soon as it's down or once nothing's at stake. One who leaves
the line again keeps their place held.

### The agent

`AgentServer` keeps a held player's pick as they leave (`AgentServer.keeps`, Arena's), so it stays
locked in, taken from teammates, and puts it back on the kit they come back with (`onKit`, the agent
last put on each player's kit). Back on their side, it's theirs unless a teammate locked it in after
they returned to the server; then they pick again, as `AgentSelect` has anyone back on a side. Once
a place is let go with its player gone, so is the pick (`AgentServer.forget`).

### The career

Leaving no longer costs the loss at once (system 67's `CareerServer.left` as they went).
`CareerServer.hold` keeps the player's record past `LINGER` while their place is held, and the
match's end counts it: `CareerRules.results` has, for anyone `away` or who `left` and came back
short of half the match's rounds, what leaving counts (`CareerRules.left`: in Competitive a loss, if
they'd played a round, and nothing elsewhere), and for anyone back in time the match as it ended.
The server closing has the arena count leaving for anyone still away from a Competitive match under
way (`CareerServer.beforeClose`), before what's left is written.

### Another server

A listed server writes an entry for each place it holds in a memory store sorted map of its own,
`PlayConfig.HELD` (`VFHeldPlaces`), by the player's UserId: its line's key and the mode
(`ServerList.encodeHeld`). The entry goes as the place is let go, unless it's since been written for
another server's. A player arriving with no mode in their teleport data has their entry read: if
it's another server's, and that server's line is up to date, for the same mode and says how to get
there (`ServerList.canRejoin`), their `VFRejoin` names the mode. RECONNECT sends them there with the
mode in the teleport data, once, as it's that server or none, and arriving there puts them back in
the match.

### The menu

With `VFRejoin` set, by the arena for a place held on this server or by `ModeServers` for one on
another, the Play menu picks that mode as it comes, PLAY reads RECONNECT, and the line under it says
the match is still on. Pressing it sends the Play remote the mode with `true`; PLAY for that mode is
always RECONNECT. Taken out of the match while still in the server, as by `VFTestAway` or for being
AFK (system 70, [70-afk.md](70-afk.md)), the menu opens by itself on a server that has players pick
first.

### In Studio

`VFTestAway`, set on Workspace from the server to a player's UserId, takes them out of the match as
if they'd left (`Arena`'s `takeOut`): the spike they carried drops where they stand
(`SpikeServer.gone`), their character goes with no death (`PlayerSimServer.unspawn`), their place is
held and their `VFRejoin` set. They stay in the server, so the kit they had isn't lost as a real
leaver's is.

### Not in yet

- The remake vote, as a bot fills the place.
- A held player on the scoreboard, shown as away.
- The ultimate's points and the charges bought, which go with the player.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/MatchRules.luau` | `away`, `leave`'s `hold`, `held`, `underWay`, the held paid in `payFor`, and `restore` in `admit` |
| `src/shared/Match/Roster.luau` | `Member.left` |
| `src/shared/Bots/BotFill.luau` | `plan`'s `prefer` |
| `src/shared/Career/CareerRules.luau` | `Player.away` and `left`, and `results` for them |
| `src/shared/Match/ServerList.luau` | `Held`, `encodeHeld`, `decodeHeld` and `canRejoin` |
| `src/shared/Match/PlayConfig.luau` | `HELD`, `REJOIN` and `Rules.heldFor` |
| `src/shared/Match/MatchConfig.luau` | `AWAY` |
| `src/server/Arena.luau` | Holding a leaver's place, letting it go, `standing` with those away, `fill`'s side, `holds`, `onHold` and `onRelease`, `takeOut`, and the hooks for `AgentServer` and `CareerServer` |
| `src/server/CareerServer.luau` | `hold` and `beforeClose` |
| `src/server/AgentServer.luau` | `keeps`, `forget` and the agent back on a returning player's kit |
| `src/server/ModeServers.luau` | The held places' entries, `VFRejoin` for one on another server, and RECONNECT's teleport |
| `src/server/SpikeServer.luau` | `gone` |
| `src/server/PlayerSimServer.luau` | `unspawn` |
| `src/client/PlayMenu.luau` | RECONNECT |
| `tests/rejoin.luau` | 34 checks |
| `docs/studio-checklist.md` | Section 73 |

## 7. Debug tools

- `VFTestAway` on Workspace, in Studio, set from the server to a player's UserId: they're taken out
  of the match as if they'd left, and it clears itself.
- `VFRejoin` on the player: the mode of a match under way that holds their place, here or on another
  server.
- In Studio, `[VF] place held: <UserId> in <mode>` as a place is held, and
  `[VF] place let go: <UserId>, back` or `its match ended` as it's let go.
- `[VF] career:` lines (system 67) for a match's end, with what it counted for anyone away.

## 8. Refinement loop

1. Leave and come back in Studio (`VFTestAway`) and on a live server, and watch what's kept, the bot
   giving way and the career line.
2. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- A place held: the bot filling it on the player's side, the spike they carried dropped, and the
  line printed.
- Back by RECONNECT or PLAY: on their side with their record, credits and agent, at once in a buy
  phase or down until the next round, and the bot on their side giving way.
- A match's end with a player away, in Competitive and in Swiftplay: what the career lines say.
- On a live server: closing the game during a match and coming back, to the same server and to
  another, by RECONNECT.

Section 73 of the [Studio checklist](../studio-checklist.md) covers these.
