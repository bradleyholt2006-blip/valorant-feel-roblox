# System 70: AFK in a match

A player in the spike rounds' match under way who stops playing is AFK. Alive in one of its rounds,
with someone else playing in the match, they're warned after 90 seconds without playing at anything:
a red line across the top of the screen says so, counting down. Thirty seconds more and they're
taken out of the match, their place held for them as for anyone who leaves (system 69): a bot stands
in, their Play menu opens on RECONNECT and says why, and in Competitive, still away at the match's
end, it's the leaver's loss. Anything played takes the warning back: a key pressed or let go, a
look, a weapon asked for, a buy or a ping.

That AFK is not playing as much as leaving, that a player AFK for a whole round is removed, and that
it costs RR in Competitive are the reference's; the 90 and 30 seconds come from a post that couldn't
be read, only seen in a search listing, and what counts as playing, when the time counts and what
taking a player out does are ours. The reference's penalties past the match (warnings, XP denied,
queue restrictions, bans) aren't in. No game file or source code was read, and nothing was read from
the live game.

## 1. Observable behaviour

- AFK is leaving a match or not playing in it: being present but not participating, or being
  detected as a bot.
- A player who stays AFK for a whole round is removed from the game, and the next round starts with
  uneven teams; since Patch 10.0 an AFK player starts a remake for their team, decided by a majority
  of the rest.
- Removal is so enemies can't take advantage of an idle player, and the penalties grow by severity:
  a warning, XP denied, in Competitive 6 to 24 RR, a queue timer, a ranked restriction, a ban.

## 2. Publicly documented details

| What | Source |
| --- | --- |
| "AFK (Away From Keyboard) is the act of leaving a match or not participating in a match."; "E.g. disconnecting from rounds, being present but not participating in a match, or being detected as a bot." | playvalorant.com, [VALORANT Systems Health Series - AFK and Queue Dodge Update](https://playvalorant.com/en-us/news/dev/valorant-systems-health-series-afk-and-queue-dodge-update/) |
| Players who "had either disconnected from the game, or stayed completely inactive for a prolonged period of time"; penalties going "from receiving a warning, to XP denials, to queue restrictions, and eventually banned" | playvalorant.com, [VALORANT Systems Health Series - AFK](https://playvalorant.com/en-us/news/dev/valorant-systems-health-series-afk/) |
| "you may be kicked from the match to prevent opportunistic enemies from taking advantage of the situation."; "If you AFK or queue dodge in a competitive match, you will lose 6–24 RR points."; "you won't necessarily receive every penalty or receive them in order." | Riot Games Support, [Be on Your Best Behavior](https://support.riotgames.com/en-us/valorant/penalties/be-on-your-best-behavior) |
| "A player can disconnect on their own or be forcibly removed from the game if they remain AFK for the entire round."; "the next round kicks off with uneven teams" | esports.gg, [How to remake in VALORANT](https://esports.gg/guides/valorant/how-to-remake-in-valorant/) |
| AFK as "in the match but not playing, whether you are away from the computer or just not moving or talking" (from Riot's penalties FAQ, it says); "a two-round AFK weighs differently from a six-round one" | senseos.gg, [VALORANT Penalties: AFK, Dodging, Restrictions, Bans](https://senseos.gg/guides/valorant/valorant-penalties/) |
| "If you're AFK for 90 seconds, you'll receive this warning. "You will be kicked in 30 seconds for inactivity. Tap OK to return to the game."" | A post on x.com, seen only as a search listing (x.com can't be read here); "Tap OK" points to the mobile version |
| Since Patch 10.0, "Upon detecting an AFK player, the game will automatically trigger the remake for your team." | Dot Esports, [Valorant shifts to automatic remake system with patch 10.0](https://dotesports.com/valorant/news/valorant-shifts-to-promising-automatic-remake-system-with-patch-10-0) |

Nothing published says how the reference tells an idle player from one holding still, nor how long
it waits on PC, so the rest is ours.

## 3. What can be measured, and how

The clock is plain functions, checked offline: `tests/afk.luau` has 22 checks, and the suite's 4134
pass. In Studio AFK's off unless Workspace's `VFTestAfk` has the seconds to warn after, as a check's
players often stand idle; with it, a player standing still in a round is warned and taken out, and
the Output prints each (section 74 of the checklist).

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| AFK | Not playing in a match, as leaving it is | Confirmed | playvalorant.com |
| Taken out | After a whole round's AFK | Community | esports.gg |
| The warning | After 90 s without playing | Community | The x.com post, unread, likely of the mobile version |
| Out | 30 s after the warning | Community | The same |
| The time that counts | Alive in a round of the spike rounds' match under way, its buy phase and after the plant too; stopped while dead or between rounds, and started over out of a match | Estimate | Ours: so the warning and the time after it, 120 s, are about a whole round alive (a 30 s buy phase and a 100 s round) |
| Playing | A key or button pressed or let go, but not one held on; a look turning the view more than 0.002 rad (about a tenth of a degree) from where it was as the clock last started; a weapon asked for; a buy; a ping | Estimate | Ours |
| Who it's for | Only with another player in the match, bots aside | Estimate | Ours: with nobody else, nobody's let down |
| What taking out does | As leaving (system 69): the place held, a bot standing in, RECONNECT | Estimate | Ours: the reference plays on "with uneven teams", or remakes |
| Competitive | Away at the match's end: the leaver's loss (system 67) | Estimate | Ours; the reference: "6–24 RR" |
| Penalties past the match | None | Estimate | Ours |
| Modes | The spike rounds | Estimate | Ours: the modes that hold a place |

## 5. Design

### The clock

`AfkRules` keeps a clock for each player: the seconds counted since they last played, and whether
they're warned. It moves on each frame in the state the arena gives it: `count`, alive in a round of
the spike rounds' match under way (the buy phase, the round and after the plant); `pause`, dead or
between rounds, where it keeps what it had; and `off`, out of a match under way, or with nobody else
playing in it, where it starts over. Past `MatchConfig.Afk.warnAfter` seconds the player's warned,
and past `outAfter` more they're due out, and the clock starts over.

An input plays at something if it presses or lets go of a key or button (a key held on, as a crouch
toggled on is, doesn't count from tick to tick), turns the view more than `turn` from where it was
as the clock last started (so a slow turn adds up), or asks for another weapon. A life starts on the
server's aim, so its first input only says where the aim is.

### On the server

`AfkServer` keeps the clocks: PlayerSimServer's ticks bring each input, a new life (its spawn
listeners) sets the aim afresh, and the Buy and Ping remotes count as playing. Each frame, after the
arena's rounds, it moves every clock on in the state the arena says (`AfkServer.state`, Arena's).
Warned while the time counts, the player's `MatchConfig.AFK_AT` (`VFAfkAt`) has the server time
they'll be taken out at, set afresh if the clock stopped meanwhile; due out, their `AFK_OUT`
(`VFAfkOut`) is set, and the arena takes them out as Studio's `VFTestAway` does
(`AfkServer.takeOut`, Arena's `takeOut`): out of play with no death, the spike they carried on the
ground, their place held. Pressing PLAY or RECONNECT clears `AFK_OUT` (`AfkServer.back`, from
`Arena.play`).

### On screen

`AfkView` shows the warning in red across the top of the screen while `VFAfkAt` is set:
`INACTIVE: PLAY, OR YOU'RE TAKEN OUT OF THE MATCH IN 23`, counting down. Taken out, the Play menu
opens on a server that has players pick first (as the player's `PlayConfig.PLAYING` goes, so
Studio's `VFTestAway` opens it too), with RECONNECT and
`TAKEN OUT FOR BEING INACTIVE: RECONNECT TO GET BACK IN`.

### In Studio

AFK's off in Studio unless Workspace's `VFTestAfk` is a number of seconds, which takes the place of
`warnAfter`; with it, AFK counts with no other player in the match too, so a check with one player
can see it.

### Not in yet

- The penalties past the match: warnings that build up, XP denied, queue timers, ranked restrictions
  and bans.
- AFK in Skirmish, the 1v1, gun game and both deathmatches.
- The remake vote, as a bot stands in.
- Talking as playing.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/AfkRules.luau` | The clock: what's playing, when it counts, the warning and when they're due out |
| `src/shared/Match/MatchConfig.luau` | `Afk`, `AFK_AT`, `AFK_OUT` and `TEST_AFK` |
| `src/server/AfkServer.luau` | The clocks, from the ticks, the spawns, buys and pings, the attributes, and taking a player out |
| `src/server/Arena.luau` | `AfkServer.state` and `takeOut`, and `AfkServer.back` from `Arena.play` |
| `src/server/init.server.luau` | `AfkServer.start`, and its step after the arena's |
| `src/client/AfkView.luau` | The warning |
| `src/client/PlayMenu.luau` | Opening as a player's taken out, and why |
| `tests/afk.luau` | 22 checks |
| `docs/studio-checklist.md` | Section 74 |

## 7. Debug tools

- `VFTestAfk` on Workspace, in Studio: the seconds without playing before a warning, AFK being off
  in Studio without it.
- `VFAfkAt` on the player: the server time they'll be taken out at, while warned and their time
  counts; `VFAfkOut`: taken out, until they press PLAY or RECONNECT.
- PlayerGui's `VFAfk` carries `Line`, the warning shown, or "".
- `[VF] AFK: <UserId> warned` as a player's warned, once however often the line comes and goes
  with the rounds, and `[VF] AFK: <UserId> taken out of the match`.

## 8. Refinement loop

1. Stand still in a round in Studio (`VFTestAfk`), and on a live server; play through a match
   holding angles, and watch for a warning that shouldn't come.
2. Tune `MatchConfig.Afk`, and re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Standing still alive in a round: the warning at the time set, counting down, and gone at a key, a
  look or a buy.
- Dead, or between rounds: the time stopping and going on.
- Taken out: the Output's line, the place held and the bot on their side, the menu opening with
  RECONNECT and the line saying why, and back by RECONNECT.
- No warning with nobody else playing, without `VFTestAfk`.

Section 74 of the [Studio checklist](../studio-checklist.md) covers these.
