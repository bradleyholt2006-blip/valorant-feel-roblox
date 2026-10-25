# System 16: The round at a glance

In the reference you can always tell how a round stands without counting. The top bar shows who's
still alive on each side. The kill feed in the corner says who killed whom, with what, and how: a
headshot, a kill through a wall. Holding Tab shows the scoreboard: everyone's kills, deaths and
assists, their combat score, the credits each player has and, for your side, the gun and shield
each holds. This system adds all three, with the match's record behind them: kills, deaths,
assists and the combat score, kept by the server from every hit and every death.

The record is kept in the spike rounds (systems 13 and 14), where it means something. The top
bar's players and the kill feed work in Skirmish too, and the kill feed on the course.

As before, everything comes from Riot's patch notes and from community wikis and guides. No game
files, memory, network traffic or protected assets were used, and nothing reads the game while it
runs. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

## 1. Observable behaviour

- **The top bar.** Beside the score and the round's clock, a portrait for each player, your side's
  on one side and theirs on the other. A portrait dims when its player dies.
- **The kill feed.** A line for each kill, in a corner of the screen, the newest at the top. Each
  line reads: the killer, the weapon's icon, a mark for a headshot or a kill through a wall, and
  whoever died. The names are in their side's colours. A line goes after a few seconds.
- **The scoreboard.** Held on Tab. A table for each side, a row for each player: their name, their
  ultimate's points, kills, deaths and assists, their loadout (gun and shield), their credits and
  their ping. Your side's loadouts show; the other side's credits show as they were at the round's
  start.
- **The combat score.** Each round's is made of damage, kills (worth more the more enemies are
  alive) and a bonus for each kill after the first in a round. The match's is the average over the
  rounds played: the ACS.
- **Assists.** Damage to someone a teammate then kills is an assist. Abilities give assists too.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| What an assist is | Patch 12.05 (Italian notes): "Quando la vostra abilità o i vostri danni contribuiscono a un'uccisione conseguita da un alleato" ("when your ability or your damage contributes to a kill secured by an ally") ([patch notes](https://playvalorant.com/it-it/news/game-updates/valorant-patch-notes-12-05)) |
| The assist in the kill feed | The same notes: "Il registro uccisioni della vostra squadra ora mostra l'icona dell'agente che ha fatto l'assist" ("your team's kill feed now shows the icon of the agent who got the assist"), and "Questa informazione è visibile solo alla vostra squadra" ("this information is visible only to your team") |

### From the community

| What | Value | Sources |
| --- | --- | --- |
| Damage | "Each point of damage dealt adds 1 point" | [esports.net's ACS guide](https://www.esports.net/wiki/guides/acs-explained-valorant/); [tracker.gg](https://tracker.gg/checkpoint/articles/what-is-acs-in-valorant-and-how-does-it-work): "Each damage you deal adds up one point" |
| A kill | By the enemies alive: 150 with five, 130 with four, 110 with three, 90 with two, 70 for the final enemy | esports.net; [Sportskeeda](https://www.sportskeeda.com/valorant/what-acs-mean-valorant): "150/130/110/90/70" |
| Multikills | "2 kills add 50, 3 kills add 100, and 4 kills add 150" | esports.net; tracker.gg: "For every addition kill, you can receive 50 points"; Sportskeeda: "+50 per additional kill" |
| Non-damaging assists | 25 each (a blind, a reveal, a heal) | esports.net, tracker.gg, Sportskeeda |
| The average | "Total Combat Score divided by the number of rounds played, rounded to the nearest whole number" | esports.net |
| Where ACS shows | "If you take a glimpse at the post-match scoreboard..." | Sportskeeda |
| The top bar | "At the top center of your HUD are the match timer, team score, and team agent identifier"; "Each agent will be shown on the bar and reflects who is still alive in the round" | [ONE Esports' HUD guide](https://www.oneesports.gg/valorant/user-interface-valorant-hud/) |
| The scoreboard | "This shows player names, agent ultimates, KDA (Kill/Death/Assist) scores, Loadout (weapons and armor), credits, and player ping" | The same guide |
| The other side's credits | "You could also keep tabs on the enemy team's credits since it will show how much they have at the start of each round" | The same guide |
| The headshot mark | Since Patch 2.09 "another icon is used to mark headshots" in the kill feed | [Sportskeeda](https://www.sportskeeda.com/valorant/valorant-changed-headshot-icon-patch-2-09-fans-happy) |

Two sources disagree with the rest or with the reference as it's played, and neither is used:
Sportskeeda's ACS article also counts round wins in the combat score, which no other source does,
and its patch 2.09 article puts the kill feed "on the top left side" of the HUD, where ONE Esports
puts the minimap.

Nothing public gives the kill feed's details: how many lines it holds, how long a line stays, or
how a line you're in is marked. Nor how long after damage an assist still counts. Those are ours,
and labelled as estimates.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How long a kill feed line stays | Frame-count a line from its kill to its fade in a public video |
| How many lines it holds | A public video of a fast trade: the most lines on screen at once |
| How a line you're in is marked | A public video from a player's own view |
| The combat score's numbers | A match's per-round combat score on a stat site against the round's damage and kills |
| Whether damage past a kill counts | The same, for a round with a big overkill (an Operator to the body of a weak enemy) |
| How long an assist's damage counts | A public video of a kill long after a teammate's damage, and the scoreboard after it |
| Where the scoreboard sorts players | A public video of Tab held over a few rounds |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Damage's score | A point for each point of health and shield taken from an enemy | Community |
| Overkill | Doesn't count: only what the hit took | Estimate |
| A kill's score | 150, 130, 110, 90 or 70 by the enemies alive, the one killed among them | Community |
| Multikills | 50 more for each kill after the first in a round | Community |
| The ACS | The combat score over the rounds played, at least one, to the nearest point | Community |
| A round played | Every round played to its end, for everyone in the match then, the dead too | Estimate |
| Assists | Damage to an enemy that a teammate then kills, in the same life, however long before | Confirmed (what an assist is), estimate (the whole life) |
| Non-damaging assists | None, as there are no abilities | Not here |
| Teammates and the spike | Damage to a teammate scores nothing; a teammate's kill is a death, not a kill; the spike's blast is a death with no kill | Estimate |
| When it's kept | In the spike rounds: in a round and after it, not while waiting for an opponent or once the match is won. A new match starts everyone over | Estimate |
| The top bar's players | A tile each with their name's first letters, yours to the left of the score and theirs to the right, dimmed once they're dead | Community (the portraits); ours (the letters) |
| The kill feed | The top right, the newest at the top, at most 6 lines, each for 6 s | Estimate |
| A kill feed line | The killer in their side's colour, the weapon's name, `HS` for a headshot, `WALL` through a wall, and whoever died in their side's colour | Community (the headshot mark); estimate (a wall's mark, the words) |
| A line you're in | Outlined in gold | Estimate |
| The spike's kills | `SPIKE` in red for the killer | Ours |
| The scoreboard | Held on Tab in the spike rounds: name, kills, deaths, assists, ACS, credits, and your side's loadouts | Community; estimate (ACS during a match) |
| The other side's credits | As the round started, after its pay | Community |
| The order | Best ACS first, then kills | Estimate |
| Your row | Your name in gold on a gold-tinted row | Ours |

## 5. Design

### The record as plain state

`MatchRules` already knew who killed whom (system 14 pays for kills). It now keeps each member's
kills, deaths, assists, combat score and rounds played, so the offline tests can play a match and
check them.

- `MatchRules.damaged` takes every hit between players: who, whom and how much. Damage to an
  enemy adds to the attacker's score, and marks the victim's life as hurt by them.
- `MatchRules.died` adds the death and, for a kill by an enemy, the kill and its score, worked out
  from the enemies alive and the killer's kills this round. Each teammate of the killer who hurt
  that life gets an assist. The life's marks go with it.
- `startRound` clears the round's kills and the marks; `endRound` counts the round for everyone;
  a new match clears the lot. Nothing counts while waiting or once the match is won.

The numbers are `MatchConfig.Score`, each with its status and source. `MatchRules.killScore` and
`MatchRules.average` are the two formulas, and the scoreboard uses the second.

Each member also keeps `startCredits`: their credits as the round started, after its pay. It's
what the other side's scoreboard shows of them, so a buy doesn't give away what they bought.

### The server

`CombatServer.damageListeners` hears every hit that took health or shield, before any death
listener runs. The arena passes hits between players to `MatchRules.damaged`. Damage events
(the `Combat` remote, which every client gets) now also say whether the bullets went through a
wall first: any pellet that hit through a wall marks its target.

The arena keeps the record on each player as attributes (`MatchConfig`: `VFKills`, `VFDeaths`,
`VFAssists`, `VFScore`, `VFRounds`, `VFStartCredits`), whether they're alive (`VFAlive`, in Skirmish
too), and the guns they hold (`VFLoadout`, "vandal,classic", whenever it changes). All of them are
cleared when what's played stops.

### The client

- `KillFeed` reads the damage events with a kill and draws a line for each at the top right.
  Names come from the entity ids, colours from each player's side as `ArenaHud` colours them,
  and the weapon's name from `WeaponConfig`. The old one-line feed in `CombatHud` is gone.
- `ArenaHud` puts a tile for each player either side of the top bar: up to five a side, sorted by
  name, in the side's colour, dimmed by `VFAlive`.
- `Scoreboard` is held on Tab, or with `VFTestBoard`. It reads the attributes, sorts each side by
  ACS, and shows your side first. Loadouts come from `VFLoadout`, the primary or else the
  sidearm, and the shield from what combat events last said of that player's health. While the
  spike rounds are on, Roblox's own player list is off, as Tab would open it.

### Not here yet

- **What clients are told.** Every client is told everyone's credits and guns as attributes,
  though the scoreboard shows the other side's credits only as the round started and none of
  their guns. A client reading the attributes sees more than the reference would tell it. Telling
  each side only its own would take a remote per client in place of the attributes.
- **Ultimates and ping** on the scoreboard. There are no abilities, and the Hit Reg Lab shows the
  ping.
- **Non-damaging assists** and the assist's icon in the kill feed (Patch 12.05), with abilities.
- **Agent portraits.** There are no agents, so the tiles and the rows carry names.
- **Icons.** The kill feed and the scoreboard name the weapon in words, as there are no icons yet.
- **The match's end screen**: the post-match scoreboard, with first bloods, plants, defuses and
  each round's timeline.
- **A record in Skirmish.** Skirmish keeps no record, so Tab does nothing there and Roblox's player
  list is left alone.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/MatchConfig.luau` | `Score`: the combat score's numbers; the record's attribute names |
| `src/shared/Match/MatchRules.luau` | The record: `damaged`, the kill's score in `died`, assists, rounds, `killScore`, `average`, `startCredits` |
| `src/server/CombatServer.luau` | `damageListeners`, and `wallbang` on damage events |
| `src/server/Arena.luau` | Hits into the record, and the record, who's alive and loadouts as attributes |
| `src/client/KillFeed.luau` | The kill feed |
| `src/client/ArenaHud.luau` | The players' tiles beside the top bar |
| `src/client/Scoreboard.luau` | The scoreboard on Tab |
| `src/client/Combat/CombatHud.luau` | The old feed taken out |
| `src/client/Debug/TestAim.luau` | `VFTestBoard`: Tab, for scripted checks |
| `tests/scoreboard.luau` | 41 checks: the score's numbers, damage, kills by enemies alive, multikills, assists, deaths nobody's credited with, what isn't recorded, rounds and the average, a new match, the other side's credits |

## 7. Debug tools

- Select a player under Players in the Explorer: the record is in their attributes while the spike
  rounds are on (`VFKills`, `VFDeaths`, `VFAssists`, `VFScore`, `VFRounds`, `VFCredits`,
  `VFStartCredits`), with `VFAlive` and `VFLoadout`.
- `VFTestBoard` (a boolean attribute on your player, Studio only) set to true holds the scoreboard
  open, and false lets it go. It clears itself.
- The practice dummies' kills show in the kill feed on the course.

## 8. Refinement loop

1. Find a public video of a round with a few kills, from a player's own view, with Tab held at the
   round's end.
2. Note each kill feed line's time on screen, how many show at once and how your own are marked.
3. From a stat site's round-by-round combat score for a public match, check a round's score
   against its damage and kills by the rules above, and adjust `MatchConfig.Score` or the overkill
   rule if they don't agree.
