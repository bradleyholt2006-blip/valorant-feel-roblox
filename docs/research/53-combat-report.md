# System 53: The combat report

In the reference, a player who dies gets a combat report: who killed them, the damage they did and
took, and where their shots and the enemy's struck. It comes up on the right of the screen as they
die, a key shows or hides it, and since Patch 9.02 it shows again through the next buy phase. A
second key opens its details, each weapon's and ability's damage and hits. Until now ours had none,
and the kill feed alone said who died. This system adds it. The server keeps a report for each
player: in Skirmish and the spike rounds over the round, and elsewhere over a life. Every hit that
took health or shield goes in the attacker's report as dealt and in the victim's as taken, by what
made it and by the part each bullet or blade struck, and every kill in both. As a player dies,
theirs comes up on the right of their screen, and N hides it and shows it again. In the rounds, the
round's report shows again through the next buy phase. Mouse 3 opens the details beside it. On the
course, N shows yours at any time. The enemy outline colour moves from N to I.

As before, everything comes from public sources: Riot's patch notes (0.50, 1.0, 9.02, 9.04, 9.10,
11.11 and 12.02) and support site and, for what Riot doesn't give, a guide (ONE Esports), a list of
key bindings (Shacknews) and a guide to calling out (esports.gg). No game files, memory or network
traffic were used, and nothing was read from the live game. Riot gives the key, when the report pops
up and when it goes, the buy phase, the details and their headers, the spike's kills, that it shows
yourself and allies, healing and damaging abilities, and that it mustn't leak what a player couldn't
otherwise know; the community gives where it shows and what's in it. Nothing in this system is
measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes and support site) |
| **Community** | Published by a guide or the press, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source we could read says how the report is laid out, in what order its rows come, what counts as
a hit for a shotgun's pellets or for a fire, whether it changes while its owner is dead, or what it
covers outside the rounds. Ours, in section 4: a head with who killed you, a row for everyone you
fought with a figure for where each way's hits struck, whoever killed you first; a pellet, a blade
and a burst each a hit and a burn none; changes sent again while you're down; and in the modes
without rounds, the life. The reference's agent portraits and icons are Riot's art, so ours has each
agent's first two letters in a box and a figure drawn from three boxes in their place.

## 1. Observable behaviour

- **When it comes up** (Riot and the community). Riot Support: "You can show or hide the combat
  report that pops up when you die by pressing N while in-game." ONE Esports: "After getting
  eliminated, a combat report notification will pop up on the right side of your screen."
- **What's in it** (the community and Riot). ONE Esports: "There, you can find who killed you, how
  much damage you’ve done to the enemy team, and how much damage you’ve received.", and "The combat
  report is appropriately detailed in showing where you hit your opponents, and where you were shot
  as well." Patch 9.04: "Fixed an issue where spike icons would not show on the combat report when
  killed by spike explosion damage." Patch 9.02: "Fixed 'Self' and 'Ally' not localizing in Combat
  Report text." Patch 12.02: "Fixed an issue where player names were misaligned in the Combat
  Report". Abilities are in it too, damaging and healing: Patch 9.04, "Vyse’s damaging abilities
  display incorrectly in the Combat Report."; Patch 11.11, "Fixed a bug where Phoenix’s Hot Hands
  would show inaccurate healing done in the combat report".
- **The key** (Riot and the community). Riot Support: N, and "You can rebind this key by going to
  Settings->Controls->Interface->Combat Report." Shacknews lists Combat Report on N among the
  default bindings.
- **The buy phase** (Riot). Patch 9.02: "Combat Report will now be visible during the Buy Phase by
  default.", and "You will still be able to toggle it on and off during this phase." Patch 0.50:
  "Ability details in the combat report will now correctly appear in the buy phase of the round when
  teams switch sides".
- **The details** (Riot). Patch 9.04: "Pressing M3 now will open up the additional details panel of
  the combat report (previously Tab+M3)." Patch 9.02's known issue gives its columns: "Combat Report
  additional details window is missing headers for 'Weapon / Ability,' 'Damage,' and 'Hits'."
- **The damage it shows** (Riot). Patch 0.50: "Fixed an issue where the combat report would show 150
  damage but the enemy player was still alive" "(in cases where healing was not involved)".
- **When it goes** (Riot). Patch 9.04, on console: "Fixed an issue with Combat Reports flickering
  after respawning in Team Deathmatch.", "Fixed an issue with Combat Reports overlapping with the
  Victory/Defeat ceremony if the player is dead at the final round." and "Fixed a bug with Combat
  Reports not showing up after force closing the game and reconnecting to the match."
- **What it mustn't tell** (Riot). Patch 9.10: "While the combat report should be a tool to provide
  gameplay context for what your impact was within a round of VALORANT," "it has the occasional
  downside of leaking information to you that you otherwise would have had no way of knowing." So
  since then "Your utility usage statistics now appear once the round has resolved rather than
  immediately upon death.", "In its place, you will see an animated hourglass.", and "Once the round
  ends, utility usage statistics will become available and persist through pre-round of the next
  round."
- **What it's for** (Riot and the community). Patch 9.10: "The combat report is intended to share
  in-game information easily." ONE Esports: "Make sure to let your team know how much damage you’ve
  done to enemy agents when you’re out of the round." esports.gg: "Reveal any damage done to an
  opposing player, if not traded, upon your death."

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Fixed an issue where the combat report would show 150 damage but the enemy player was still alive" "(in cases where healing was not involved)"; "Ability details in the combat report will now correctly appear in the buy phase of the round when teams switch sides" | [VALORANT Patch Notes 0.50](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-50/), 12 May 2020 |
| "Fixed overlaps and overruns in the Combat Report" | [VALORANT Patch Notes 1.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-0/), 2 June 2020 |
| "Visual refresh! The in-game combat report has a new look."; "Combat Report will now be visible during the Buy Phase by default."; "You will still be able to toggle it on and off during this phase."; "Combat Report additional details window is missing headers for 'Weapon / Ability,' 'Damage,' and 'Hits'."; on console, "Fixed an update with timestamp and ability status text overlapping in Combat Reports." and "Fixed 'Self' and 'Ally' not localizing in Combat Report text." | [VALORANT Patch Notes 9.02](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-902/), 30 July 2024 |
| "Fixed an issue where spike icons would not show on the combat report when killed by spike explosion damage."; "Pressing M3 now will open up the additional details panel of the combat report (previously Tab+M3)."; on console, "Fixed an issue with Combat Reports flickering after respawning in Team Deathmatch.", "Fixed an issue with Combat Reports overlapping with the Victory/Defeat ceremony if the player is dead at the final round.", "Fixed a bug with Combat Reports not showing up after force closing the game and reconnecting to the match." and "Vyse’s damaging abilities display incorrectly in the Combat Report." | [VALORANT Patch Notes 9.04](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-04), 27 August 2024 |
| "The combat report is intended to share in-game information easily."; "While the combat report should be a tool to provide gameplay context for what your impact was within a round of VALORANT," "it has the occasional downside of leaking information to you that you otherwise would have had no way of knowing."; "Your utility usage statistics now appear once the round has resolved rather than immediately upon death."; "In its place, you will see an animated hourglass."; "Once the round ends, utility usage statistics will become available and persist through pre-round of the next round." | [VALORANT Patch Notes 9.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-10/), 19 November 2024 |
| "Fixed a bug where Phoenix’s Hot Hands would show inaccurate healing done in the combat report" | [VALORANT Patch Notes 11.11](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-11-11), 2 December 2025 |
| "Fixed an issue where player names were misaligned in the Combat Report" | [VALORANT Patch Notes 12.02](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-12-02), 3 February 2026 |
| "How do I make the combat report show up?"; "You can show or hide the combat report that pops up when you die by pressing N while in-game."; "You can rebind this key by going to Settings->Controls->Interface->Combat Report." | [Riot Support, VALORANT UI Settings FAQ](https://support.riotgames.com/en-us/valorant/gameplay/valorant-ui-settings-faq), as of 12 January 2026 |

### From the community

| What | Source |
| --- | --- |
| "After getting eliminated, a combat report notification will pop up on the right side of your screen."; "There, you can find who killed you, how much damage you’ve done to the enemy team, and how much damage you’ve received."; "The combat report is appropriately detailed in showing where you hit your opponents, and where you were shot as well."; "Make sure to let your team know how much damage you’ve done to enemy agents when you’re out of the round." | [ONE Esports, understanding the HUD](https://www.oneesports.gg/valorant/valorant-beginners-guide-understanding-the-hud/), Nigel "Zim947" Zalamea, 22 July 2023 |
| Combat Report, bound to N, in its table of the default bindings | [Shacknews, PC controls and keybindings](https://www.shacknews.com/article/117434/valorant-pc-controls-and-keybindings), 2 June 2020 |
| "Reveal any damage done to an opposing player, if not traded, upon your death." | [esports.gg, the importance of communication](https://esports.gg/news/valorant/entry-frag-part-one-the-importance-of-communication-in-valorant/), Brandon Moore |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How the report is laid out, and in what order its rows come | Public clips of a death since Patch 9.02, paused on the report |
| What counts as a hit for a shotgun's pellets, a knife and a fire | Public clips of a Bucky or Judge kill, a knife kill and a death in Phoenix's or Brimstone's fire, with the details open |
| Whether the damage it shows is what the hits took or what they'd have done | Public clips of a headshot on a damaged enemy: the report against the damage the gun does there |
| Whether it changes while its owner is dead | Public clips of a player killed while their fire still burns an enemy |
| What it covers in Team Deathmatch and Deathmatch | Public clips of a second death in either |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| When it shows | As you die, on the right of the screen, under the kill feed | Confirmed (Riot Support: "the combat report that pops up when you die"); community (ONE Esports: "on the right side of your screen") |
| The key | N shows or hides it, while there's one to show | Confirmed (Riot Support: "by pressing N"); community (Shacknews: Combat Report on N) |
| The buy phase | In Skirmish and the spike rounds, the round's report shows again through the next buy phase, N still showing or hiding it, until the round goes live | Confirmed (Patch 9.02: "visible during the Buy Phase by default", "toggle it on and off during this phase"); estimate (gone as the round goes live) |
| When it goes | As you come back, but for the round's report through the buy phase; and as a match ends, for its victory screen and the vote after it | Confirmed (Patch 9.04: "flickering after respawning in Team Deathmatch" and "overlapping with the Victory/Defeat ceremony" were bugs) |
| What it covers | In Skirmish and the spike rounds, the round, through whatever Sage's Resurrection brings back; elsewhere, and while a match waits for an opponent, a life | Confirmed (the round: Patch 9.10, "what your impact was within a round"); estimate (the life) |
| Who killed you | At its head: their agent's letters, their name in their side's colour and what killed you; the spike's blast or a spawn room's burn by name, in the spike's red; or yourself | Community (ONE Esports: "who killed you"); confirmed (the spike: Patch 9.04); estimate (its look) |
| A row for each | Everyone you hurt or who hurt you: enemies, allies your fire burned or whose burned you, and yourself (Sova's Shock Bolt). Whoever killed you first, then the rest in the order you first met; eight at most, then how many more | Community (ONE Esports: "how much damage you’ve done to the enemy team, and how much damage you’ve received"); confirmed (yourself and allies: Patch 9.02, "'Self' and 'Ally'"); estimate (the order and the eight) |
| Each row | Their agent's letters, their name in their side's colour (yours for yourself, SELF), KILLED in gold for those you killed and KILLED YOU in red for whoever killed you; under DEALT and TAKEN each way's damage | Community (ONE Esports); estimate (the look and the words) |
| Its damage | What the hits took of health and shield together, in whole points, rounded down, so someone left alive never reads as having taken all they had | Confirmed (Patch 0.50: "150 damage but the enemy player was still alive" was a bug) |
| Where it struck | A figure beside each way's damage: its head, body and legs lit where bullets and blades struck, with how many there | Community (ONE Esports: "where you hit your opponents, and where you were shot as well"); estimate (the figure) |
| What's a hit | Each bullet that struck, a shotgun's pellets each; each knife's blade; each burst (a Shock Bolt's, a Hunter's Fury blast's), which strikes no part; a fire's burn, which goes a few points at a time, none | Estimate |
| The totals | At its foot, all you dealt and all you took | Estimate |
| The details | Mouse 3 opens them beside the report, while it's up: each row's weapons and abilities each way, under WEAPON / ABILITY, DAMAGE and HITS (a burn's hits `-`) | Confirmed (Patch 9.04: "Pressing M3"; Patch 9.02: "'Weapon / Ability,' 'Damage,' and 'Hits'") |
| Abilities | Their damage, as their own lines: Hot Hands', Blaze's, the Shock Bolt's, Hunter's Fury's and Blade Storm's | Confirmed (Patch 9.04: "Vyse’s damaging abilities") |
| Only yours | Each player gets their own report alone, and it holds only whom they hurt and who hurt them | Confirmed (Patch 9.10: not "leaking information to you that you otherwise would have had no way of knowing") |
| While you're down | As it changes (a fire of yours still burning), it comes again, every 0.25 s at most; and again as the round ends, its last | Estimate |
| Coming back | Reports are kept by player, so leaving and coming back to a stretch of play you died in shows yours again | Confirmed (Patch 9.04: reports "not showing up after force closing the game and reconnecting" was a bug) |
| On the course | N shows the report of your life so far at any time | Estimate (ours, for practice and checks) |
| The enemy outline colour | I goes through the four colours, as N did | Estimate (ours: the reference has it in Settings > General > Accessibility, system 6) |

## 5. Design

### The rules

- **`CombatReport`** (new) has the rules, with no Roblox APIs: `open`, `keep` and `clear` start a
  report over for a new life, keep one through a life in a round, and clear everyone's for a new
  round; `hit` puts a hit in the reports it touched, by weapon or ability and by part, and `killed`
  a kill; `ordered` puts the rows in the order they show in; `points` rounds the damage down; `hits`
  and `totals` count; and `wayText` and `rowText` give the text scripted checks read.
- **`Volley.totals`** counts each target's bullets by the part each struck (`parts`).

### The server

- **`CombatServer`** tells its damage listeners what made each hit (`CombatServer.Hit`): the
  weapon's or ability's id, and the parts its bullets or blade struck, or that it was a burst.
- **`ReportServer`** (new) keeps everyone's reports from what `CombatServer` tells of hits and
  kills, opens one at each spawn, or keeps the round's, and sends each player theirs with the
  `Report` remote: as they die (`death`), again as it changes while they're down and as the round
  ends (`update`, marked `final` once the round's over), on the course as they ask (`now`), and as
  they join if they died in what's being played (`death`). Each comes with the round's number in the
  rounds.
- **`Arena`** tells `ReportServer` as each round of Skirmish and the spike rounds starts and ends,
  but for a match's last, which has its victory screen, and whether reports go by the round
  (`ReportServer.byRound`): once a round's under way. A mode starting or stopping starts everyone's
  over (`ReportServer.reset`).
- **`Remotes`** has `Report`, both ways.

### The client

- **`ReportView`** (new) draws the report (`VFCombatReport`): its head, its rows with their figures,
  its foot and its details. It shows a report as it comes as you die, or as you ask on the course;
  keeps the round's last through the next buy phase, showing it as the phase starts; drops any other
  as you come back; drops them all as the round goes live and as a match ends; and has N, mouse 3
  and the course's ask.
- **`Visuals`** has I for the enemy outline colour, and **`DebugHud`** says so.
- **`TestAim`** has `VFTestReport`.

### Not here yet

- **Utility usage.** Since Patch 9.10 the report has "utility usage statistics" that show once the
  round's over, with "an animated hourglass" in their place until then, and Patch 11.11 names
  "healing done". Ours has abilities' damage alone, and nothing of blinds, slows, reveals or heals.
- **Times.** Patch 9.02 mentions a "timestamp" in the report. Ours has no times.
- **Rebinding.** The reference rebinds N in its settings ("Settings->Controls->Interface->Combat
  Report"); ours has no key bindings menu.
- **Riot's look.** The agents' portraits, the report's art and its icons are Riot's, and none is
  copied: letters, boxes and words stand in.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/CombatReport.luau` | New: the rules: reports opened, kept and cleared, hits and kills in them, their order, whole points, counts and their text |
| `src/shared/Combat/Volley.luau` | Each target's bullets counted by part |
| `src/server/CombatServer.luau` | What made each hit, and its parts, for its damage listeners |
| `src/server/ReportServer.luau` | New: everyone's reports kept, and each sent to its owner |
| `src/server/Arena.luau` | Rounds starting and ending, and whether reports go by the round |
| `src/shared/Net/Remotes.luau` | `Report` |
| `src/client/ReportView.luau` | New: the report on screen, N, mouse 3 and the course's ask, and `VFCombatReport` |
| `src/client/Visuals.luau`, `src/client/Debug/DebugHud.luau` | I for the enemy outline colour |
| `src/server/init.server.luau`, `src/client/init.client.luau` | `ReportServer` and `ReportView` started, and the server's reports sent at the end of each frame |
| `src/client/Debug/TestAim.luau` | `VFTestReport` |
| `tests/combatreport.luau`, `tests/run.luau` | New: 41 checks: a volley's parts; hits in the reports they touch, by weapon and by part; bursts and burns; dummies, what nobody did, and yourself; kills, deaths and the spike's; the rows' order; whole points; a report's stretch; and the text checks read |

## 7. Debug tools

- PlayerGui's `VFCombatReport` carries `Shown` and `Details` (whether the report and its details are
  up), `Final` (whether it's a round's last), `Round` (its round's number, in the rounds), `Killer`
  (who killed you and with what, `Player2, Vandal`, or `the spike`, `the spawn room` or
  `yourself, Shock Bolt`; empty if nobody did), `Rows` (its rows in order, as `CombatReport.rowText`
  gives them: `Dummy 1: dealt 150 (1 head, 3 body), taken 0, killed`) and `Totals`
  (`dealt 150, taken 0`).
- `VFTestReport` set to `toggle` shows or hides it as N does, and to `details` opens or shuts its
  details as mouse 3 does.

## 8. Refinement loop

1. Pause public clips of a death since Patch 9.02 on the report, and redraw its head, rows and
   details from them, in their order.
2. From a clip with the details open after a shotgun kill and a death in a fire, set what counts as
   a hit.
3. Add the utility usage, with its hourglass until the round's over (Patch 9.10).
4. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- On the course, N with nothing done: the report, empty; N again hides it. Three Vandal shots at
  Dummy 1's body, then N: a row for it with 120 dealt and its figure's body lit with 3. N to hide
  it, a shot at its head, and N: 150 dealt, the head lit with 1 too, and KILLED.
- Mouse 3: the details beside it, `Vandal` with 150 and 4 hits.
- Shot dead by another player: the report up on the right at once, with who killed you and with
  what, a row for them first with KILLED YOU, and what each of you dealt; N hiding it and showing it
  again; gone as you come back.
- In Skirmish, the round's report back through the next buy phase, N still hiding and showing it,
  and gone as the round goes live.
- Each player's report holding only whom they fought.
- I for the enemy outline colour, and N no longer changing it.

Section 57 of the [Studio checklist](../studio-checklist.md) covers these.
