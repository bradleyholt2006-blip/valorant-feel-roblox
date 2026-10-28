# System 56: Round-end callouts

In the reference, a round won in a way worth naming ends with that name on the screen, and the
announcer says it: ACE, TEAM ACE, FLAWLESS, CLUTCH or THRIFTY, in place of the plain win's. GINX, of
THRIFTY: the game lets the teams know by "narrating and displaying 'Thrifty' written on the screen."
Riot's patch notes name one of them, the Team Ace: Patch 3.07 fixed it being "awarded in scenarios
where it wasn't earned by the team". Until now ours ended every round with ROUND WON for the winners
and ROUND LOST for the losers. This system adds the callouts. The server follows each round of
Skirmish and the spike rounds from when it goes live: who's playing it on each side, who kills whom,
who dies, who's brought back and who leaves, and in the spike rounds what each player's loadout is
worth. As the round ends it names the first callout that holds, in this order: ACE when one of the
winners killed every enemy who started the round; TEAM ACE when each of the winners killed an enemy;
FLAWLESS when none of the winners died; CLUTCH when the winners were down to their last player
against two or more; and THRIFTY when the winners' loadouts were worth at least 2500 credits less on
average than the losers'. The winners' banner shows it in place of ROUND WON. The losers' still
reads ROUND LOST, except for a FLAWLESS, which they see as well.

As before, everything comes from public sources: Riot's patch notes (3.07) and, for what Riot
doesn't give, guides and the press (ONE Esports, TheGlobalGaming, GINX, win.gg, Liquipedia, and FPS
Aim Lab, a Japanese guide). No game files, memory or network traffic were used, and nothing was read
from the live game. Riot gives that a Team Ace exists and has to be earned by the whole team; the
community gives what each callout means, the 2500 credits, which callout shows when several hold,
and that the losers see a FLAWLESS too. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide or the press, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source we could read says what a side of fewer than five gets, how many enemies a clutch has to
face, when loadouts are valued for THRIFTY and whether abilities count, or how the banner looks.
Ours, in section 4: an ace needs two or more enemies, a flawless two or more winners, and a team ace
two or more on each side, or in one against one every round won by a kill would be all three; a
clutch is against two or more, FPS Aim Lab's one against several; a loadout is worth its guns' and
its shield's prices as the round goes live; and the callout takes the place of ROUND WON on the
banner ours already had. The announcer's voice is Riot's, so ours says nothing.

## 1. Observable behaviour

- **ACE** (the community). ONE Esports: "When one player gets five or six kills in a single round."
  TheGlobalGaming: "one player on the winning team killed each enemy at least once". Liquipedia:
  "Ace is when one person kills all players in one round." A sixth kill is of an enemy brought back,
  as by Sage's Resurrection (our reading).
- **TEAM ACE** (Riot and the community). ONE Esports: "When each player from the winning team scores
  a kill against the opposing team." win.gg: "Players may die after getting their one kill and still
  receive the Team Ace title upon winning." TheGlobalGaming, of a side one short: "If the opposing
  team has a disconnected player, four players in your team must kill the four enemy players.", and
  "If you're on the four-player team, four players all killed at least one of the five enemy
  players." Patch 3.07: "Fixed a bug where Team Ace could be awarded in scenarios where it wasn't
  earned by the team (we still respect teamwork!)."
- **FLAWLESS** (the community). ONE Esports: "A round where no one from the winning team died."
  TheGlobalGaming: "Flawless means that no one died on the winning team". FPS Aim Lab calls it
  PERFECT, or FLAWLESS: a win with the whole team alive.
- **CLUTCH** (the community). ONE Esports: "The last player alive wins the round for his team."
  Liquipedia: "Clutch is when the last player alive wins the round, often when the odds of winning
  are lower." FPS Aim Lab: a win from behind once it's one against several.
- **THRIFTY** (the community). GINX: "If the winning team has a loadout value of at least an average
  of 2500 credits less than the enemy team". TheGlobalGaming: "Thrifty means that the winning team
  won while possessing at least an average of 2500 less credit than the enemy team". win.gg: "The
  team must possess armory of an average of 2500 less creds than the enemy." ONE Esports: "The
  winning team spends about 2,500 fewer credits than their opponents."
- **One a round, in an order** (the community). FPS Aim Lab ranks them ACE or TEAM ACE first, then
  PERFECT (FLAWLESS), CLUTCH, THRIFTY and last the plain win, with a round that met THRIFTY's
  credits and had an ace showing ACE. win.gg ranks THRIFTY highest of three ("Out of all three,
  Thrifty is the highest victory tag in Valorant."), which reads as how prized it is rather than
  which shows (our reading); ours follows FPS Aim Lab's, the only source that says which shows.
- **The losers see FLAWLESS** (the community). FPS Aim Lab: for some reason, PERFECT, or FLAWLESS,
  shows on the losing side too.
- **Said and shown** (the community). GINX: "the game has a voice-over, which will let the teams
  know after the round ends", "narrating and displaying 'Thrifty' written on the screen."

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Fixed a bug where Team Ace could be awarded in scenarios where it wasn't earned by the team (we still respect teamwork!)." | [VALORANT Patch Notes 3.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-07/), 5 October 2021 |

### From the community

| What | Source |
| --- | --- |
| Ace: "When one player gets five or six kills in a single round."; Team Ace: "When each player from the winning team scores a kill against the opposing team."; Clutch: "The last player alive wins the round for his team."; Flawless: "A round where no one from the winning team died."; Thrifty: "The winning team spends about 2,500 fewer credits than their opponents." | [ONE Esports, on Valorant's terms](https://www.oneesports.gg/valorant/valorant-terms-calls-comms/), Nigel Zalamea, 7 June 2023 |
| "one player on the winning team killed each enemy at least once"; "When one player gets all five or six kills in a round, they get an ace"; "Team Ace in Valorant means all the members of the team killed different enemy players."; "or all the players must get at least one kill."; "If the opposing team has a disconnected player, four players in your team must kill the four enemy players."; "If you're on the four-player team, four players all killed at least one of the five enemy players."; "Thrifty means that the winning team won while possessing at least an average of 2500 less credit than the enemy team"; "Flawless means that no one died on the winning team"; "Clutch means that the round was won by the last player alive on the team." | [TheGlobalGaming, on the Team Ace](https://theglobalgaming.com/valorant/what-is-team-ace), Anthony Clement, updated 23 August 2023 |
| "If the winning team has a loadout value of at least an average of 2500 credits less than the enemy team"; "as long as your total loadout credit has an average of less than 2500 credits compared to the enemy team"; "the game has a voice-over, which will let the teams know after the round ends"; "narrating and displaying 'Thrifty' written on the screen." | [GINX, on Thrifty](https://www.ginx.tv/en/thrifty-explained), Arnab Baidya, 4 April 2023, updated 21 July 2024 |
| "Team Ace is acquired when all players on the winning team bagged one kill each."; "Players may die after getting their one kill and still receive the Team Ace title upon winning."; "The team must possess armory of an average of 2500 less creds than the enemy."; "Out of all three, Thrifty is the highest victory tag in Valorant." | [win.gg, on the victory tags](https://win.gg/news/heres-what-rare-valorant-victory-tags-mean/), Fariha Bhatti, 2021 |
| "Ace is when one person kills all players in one round."; "Team Ace is when each person kills 1 enemy player in one round."; "Clutch is when the last player alive wins the round, often when the odds of winning are lower."; "Flawless is when no one on your team dies."; "Thrifty is when you won a round spending less money than other team." | [Liquipedia, VALORANT glossary](https://liquipedia.net/valorant/Glossary) |
| In Japanese. The order: "ACE ／ TEAM ACE ＞ PERFECT ＞ CLUTCH ＞ THRIFTY ＞ WON"; ACE: "１人で全員倒しての勝利" (a win by one player downing everyone); TEAM ACE: "チーム全員が１キルずつ取っての勝利" (a win with each of the team taking a kill); PERFECT: "チーム全員が生き残っての勝利" (a win with the whole team alive); CLUTCH: "１人対複数になってからの逆転勝利" (a win from behind once it's one against several); THRIFTY: "相手より少ないクレジットでの勝利" (a win on fewer credits than the other side); "なぜかこの PERFECT / FLAWLESS は負けた側でも表示されます。" (for some reason, this PERFECT, or FLAWLESS, shows on the losing side too) | [FPS Aim Lab, on the round-win displays](http://fpsaim.blog.shinobi.jp/valorant/round-win-display), 17 August 2022 |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| Which callout shows when several hold, past FPS Aim Lab's one example | Public clips of an ace, or a team ace, with nobody on the winning side dying |
| Whether a win from one against one is a clutch | Public clips of round wins from one against one, with the banner |
| When loadouts are valued for THRIFTY, and whether abilities count | Public clips of eco rounds won, with the scoreboard's loadout values |
| What a side of two gets, in the reference's 2v2 Skirmish | Public clips of Skirmish rounds won |
| Whether a round won on time with nobody dead is a FLAWLESS | Public clips of rounds won on time with no kills |
| What the losers see for each callout | Public clips from the losing side |
| How the banner looks, and how long it shows | Public clips of round ends, frame by frame |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| ACE | One of the winners killed every enemy who started the round, with two or more of them | Community (ONE Esports, TheGlobalGaming, Liquipedia); estimate (two or more) |
| TEAM ACE | Each of the winners killed an enemy, dead or alive after; against fewer enemies than winners, as many of them as there were enemies. Two or more on each side | Confirmed (it exists, and has to be earned, Patch 3.07); community (ONE Esports, win.gg, and TheGlobalGaming for a side one short); estimate (two or more) |
| FLAWLESS | None of the winners died, a life Sage's Resurrection brought back included, with two or more of them. A round won on time with nobody dead is one | Community (ONE Esports, TheGlobalGaming); estimate (two or more, and on time) |
| CLUTCH | The winners were down to one alive against two or more at some point, or started the round as one against two or more | Community (ONE Esports, Liquipedia; one against several, FPS Aim Lab); estimate (from the start) |
| THRIFTY | In the spike rounds, where loadouts are bought, the winners' loadouts worth at least 2500 credits less on average than the losers' | Community (GINX, TheGlobalGaming, win.gg) |
| A loadout's worth | The prices of its guns and its shield as the round goes live, abilities left out; a gun picked up counts as one bought | Estimate |
| One a round | The first that holds, in the order ACE, TEAM ACE, FLAWLESS, CLUTCH, THRIFTY | Community (FPS Aim Lab) |
| Who plays the round | Everyone alive on a side as it goes live; someone who leaves is out of it, though they didn't die in it | Estimate |
| Which kills count | A kill of an enemy who started the round; not a teammate's, nor your own, nor a death nobody caused | Estimate |
| The winners' banner | The callout in place of ROUND WON, in the ally colour, with the spike rounds' line on how the round was won under it as before | Community (shown on the screen, GINX); estimate (its look) |
| The losers' banner | ROUND LOST, or the winners' FLAWLESS, in the enemy colour | Community (FPS Aim Lab) |
| Where | Skirmish and the spike rounds, but not a match's last round, which has the victory screen | Estimate |
| The announcer | Nothing said | Gap: the reference's voice is Riot's |

## 5. Design

### The rules

- **`RoundCallouts`** (new) has the rules, with no Roblox APIs: `begin` starts a round as it goes
  live, with who's on each side and, where loadouts are bought, what each is worth; `died`,
  `revived` and `left` follow it; `decide` names its callout, if it has one, as a side wins it;
  `title` says what each side's banner reads; and `worth` prices a loadout.

### The server

- **`CalloutServer`** (new) follows the round under way from the death listeners, the revive
  listeners of Sage's Resurrection and players leaving, values each player's loadout as it goes live
  where loadouts are bought, and gives its callout as it ends.
- **`Arena`** tells it when a round goes live (`roundLive`, new, with who's alive on each side and
  whether loadouts are bought) and when it ends, puts the callout on the arena's model as `Callout`,
  and clears it as the next round starts and as a mode starts or stops.
- **`init.server`** starts `CalloutServer`.

### The client

- **`ArenaHud`** shows the callout in place of ROUND WON on a round's end banner, and the losers'
  ROUND LOST or FLAWLESS (`RoundCallouts.title`); `VFArenaBanner` carries the banner's words as
  `Title`.

### Not here yet

- **The announcer.** The reference says the callout aloud; the voice is Riot's, and ours is silent.
- **Riot's look.** The reference's round-end banner is Riot's art; ours is the plain text banner it
  had.
- **A match's last round.** The victory screen shows in its place, so its callout isn't seen.
- **Who made it.** The banner doesn't say who aced or clutched; the kill feed and the kill banner
  do.
- **Abilities in a loadout.** No source we could read says whether they count toward THRIFTY.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/RoundCallouts.luau` | New: the rules: a round followed from going live, each callout and their order, the sides too small for them, each side's banner, and a loadout's worth |
| `src/server/CalloutServer.luau` | New: the round under way, from deaths, lives brought back and players leaving, its loadouts' worth, and its callout as it ends |
| `src/server/Arena.luau` | The round going live (`roundLive`), its callout on the arena's model as it ends, cleared with the next round and each mode |
| `src/server/init.server.luau` | `CalloutServer` started |
| `src/client/ArenaHud.luau` | The callout on the round's end banner, the losers' FLAWLESS, and `Title` |
| `tests/roundcallouts.luau`, `tests/run.luau` | New: 37 checks: what makes each callout, a team ace against fewer, which one a round won with several gets, the sides too small for them, deaths that don't count, a life brought back and someone leaving, each side's banner, and a loadout's worth |

## 7. Debug tools

- The arena's model, `Workspace.VFArena`, carries `Callout`, the callout of the round just played
  (`ace`, `teamAce`, `flawless`, `clutch` or `thrifty`), from its end to the next buy phase, and nil
  for none.
- PlayerGui's `VFArenaBanner` carries `Title`, the banner's words.
- `VFMatchSkip` ends a buy phase, or a round as its clock running out, as before.

## 8. Refinement loop

1. From public clips of wins from one against one, check whether they're clutches, and set `odds`.
2. From public clips of eco rounds won, check when loadouts are valued and whether abilities count.
3. From public clips of Skirmish, check what a side of two gets, and set `least`.
4. From public clips from the losing side, check what it sees for each callout.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- One against one in Skirmish: ROUND WON and ROUND LOST, with no callout.
- In the spike rounds, a Vandal against the Classic, the Classic's side winning on time: THRIFTY for
  the winners and ROUND LOST for the losers; the same loadouts on each side: ROUND WON.
- One against two in Skirmish: the one killing both, ACE; the two winning with nobody dead, FLAWLESS
  on all three screens; one against one at the end, nothing.
- The one alone against two winning after one of them leaves: CLUTCH.
- The callout gone as the next buy phase starts.

Section 60 of the [Studio checklist](../studio-checklist.md) covers these.
