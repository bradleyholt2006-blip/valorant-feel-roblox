# System 51: Agents and ultimates at a glance

In the reference, the top bar has every player's agent either side of the score, dimmed once they're
dead, with a health bar under your side's, and anyone's ultimate shows there once it's ready, an
enemy's too. The scoreboard has each player's agent and how far along their ultimate is, both sides'
alike. Until now ours had a tile for each player with the first two letters of their name (system
16), no health under them, and a scoreboard with neither agents nor ultimates, so a player's points
showed only on their own ability bar (system 50). This system keeps each player's ultimate in a
player attribute every client reads, `VFUlt`, as its points and what it needs (`3/8`). Each tile on
the top bar now has the first two letters of the player's agent (`JE`, `PH`, `SA`, `OM` or `SO`), a
white bar under your side's as full as their health, and a gold diamond under anyone's while their
ultimate is ready. The scoreboard has the agent in a box before each name and a ULT column after it,
`3/8` or `READY` in gold, for both sides.

As before, everything comes from public sources: Riot's patch notes (11.10) and, for what Riot
doesn't give, guides (ONE Esports, Dignitas and The Global Gaming), a player's blog on Medium and a
thread on VLR.gg. No game files, memory or network traffic were used, and nothing was read from the
live game. Riot gives the health bar under your side's agents; the community gives the rest. Nothing
in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, the press or players, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source we could read says how the top bar draws a ready ultimate, whether the other side's tiles
have health bars, or whether the scoreboard counts the points in numbers or in pips. Ours, in
section 4: a gold diamond under the tile; no; and numbers, as a player writes them ("5/6 or 6/7").
The agents' portraits are Riot's art, so ours has the first two letters of each agent's name in
their place.

## 1. Observable behaviour

- **The agents on the top bar** (the community). ONE Esports: "At the top center of your HUD are the
  match timer, team score, and team agent identifier.", and "Each agent will be shown on the bar and
  reflects who is still alive in the round." The Global Gaming lists "The TOP bar with the timer and
  enemy/ally Agents".
- **Your side's health** (Riot). Patch 11.10, in 2025, under "Team HUD Health Improvements":
  "Healing Indicator: The top HUD health bar now shows when you or an ally are healing.", "During
  recovery, the bar turns teal and fills to reflect healing progress." and "Once recovered, the bar
  returns to its normal white color."
- **An enemy's ultimate on the top bar** (the community). A thread on VLR.gg asking for it to be
  hidden: "As we all know, we can see enemy's ULT status from the top bar (on the agent display,
  next to score if that make sense)."
- **Everyone's ultimate on the scoreboard** (the community). Joseph Edwards, in 2020: "both ult
  availability and the progress to it for allies and enemies are shown pretty plainly on the
  scoreboard, after all."; he treats "5/6 or 6/7 as imminent". Dignitas, in 2021: "The ultimate
  status shows how close or far every player is from their ultimate and updates live.", and
  "Whenever an enemy picks up an orb or plants, their total ultimate points increases by one."
  Dignitas again, in 2023: "The scoreboard will tell you who will have an Ultimate." ONE Esports
  lists the scoreboard's "player names, agent ultimates, KDA (Kill/Death/Assist) scores".

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Team HUD Health Improvements"; "Healing Indicator: The top HUD health bar now shows when you or an ally are healing."; "During recovery, the bar turns teal and fills to reflect healing progress."; "Once recovered, the bar returns to its normal white color." | [VALORANT Patch Notes 11.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-10/), 11 November 2025 |

### From the community

| What | Source |
| --- | --- |
| "At the top center of your HUD are the match timer, team score, and team agent identifier."; "Each agent will be shown on the bar and reflects who is still alive in the round."; "This shows player names, agent ultimates, KDA (Kill/Death/Assist) scores, Loadout (weapons and armor)" (the scoreboard) | [ONE Esports, Valorant's HUD](https://www.oneesports.gg/valorant/user-interface-valorant-hud/), 22 July 2023 |
| "The TOP bar with the timer and enemy/ally Agents" | [The Global Gaming, customizing the HUD](https://theglobalgaming.com/valorant/how-to-customize-your-hud-in-valorant), 22 February 2024 |
| "As we all know, we can see enemy's ULT status from the top bar (on the agent display, next to score if that make sense)." | [VLR.gg, ult status should not be visible for enemy team](https://www.vlr.gg/201736/ult-status-should-not-be-visible-for-enemy-team) |
| "both ult availability and the progress to it for allies and enemies are shown pretty plainly on the scoreboard, after all."; "generally I'll treat 5/6 or 6/7 as imminent" | [Joseph Edwards on Medium](https://joejedwards.medium.com/valorant-adjusting-against-ultimate-threat-b6ac2b8390b), 6 May 2020 |
| "It displays K/D/A, usernames, ultimate status, economy, and more."; "The ultimate status shows how close or far every player is from their ultimate and updates live."; "Whenever an enemy picks up an orb or plants, their total ultimate points increases by one." | [Dignitas, the scoreboard explained](https://dignitas.gg/articles/all-the-valuable-information-on-the-valorant-scoreboard-tab-explained), 19 August 2021 |
| "The scoreboard will tell you who will have an Ultimate." | [Dignitas, game sense](https://dignitas.gg/articles/streamline-your-thought-process-and-improve-your-game-sense), 19 October 2023 |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How the top bar shows a ready ultimate, your side's and the other's | Public clips of a round with an ultimate ready: the tiles beside the score |
| Whether the other side's tiles have health bars | Public clips since Patch 11.10 |
| How the scoreboard counts the points: in numbers, or in pips | Public clips of the scoreboard held open mid-match |
| The bar's teal while a player heals | Public clips since Patch 11.10 of Sage's Healing Orb on a teammate |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| The agents on the top bar | A tile for each player either side of the score, yours on the left, dimmed once they're dead, as before (system 16), now with the first two letters of their agent's name: `JE`, `PH`, `SA`, `OM` and `SO` | Community (ONE Esports, The Global Gaming); the letters are ours, in place of portraits |
| Where nobody plays an agent | Gun game's tiles keep the first two letters of the player's name; deathmatch has no tiles, as before | Ours |
| Your side's health | A white bar under each of your side's tiles, as full as their health, empty once they're dead | Confirmed (Patch 11.10: "you or an ally"; "its normal white color") |
| The other side's health | None | Estimate (Patch 11.10 names only "you or an ally") |
| A ready ultimate on the top bar | A gold diamond under the tile of anyone whose ultimate has every point it needs, an enemy's too, dimmed once they're dead | Community (that it shows: VLR.gg); its look is ours |
| The scoreboard's agents | The agent's two letters in a box in the side's colour before each name, both sides' | Estimate (as the top bar's) |
| The scoreboard's ultimates | Each player's points and what their ultimate needs, as `3/8`, both sides' alike and live; `READY` in gold once full | Community (Joseph Edwards; Dignitas); `READY` is ours |
| The victory screen | The agents, but no ultimates | Ours |
| Where there are no abilities | Gun game and deathmatch: no agents and no ultimates on the scoreboard | Ours (as systems 23 and 26) |
| Team Deathmatch | Its own costs, as `30/70` for Sova | As system 28 |

## 5. Design

### The rules

- **`Glance`** (new) has what the top bar and the scoreboard show, with no Roblox APIs: `ultimate`
  writes a kit's ultimate as the attribute carries it (`3/8`, or nothing for a kit with no
  ultimate), `read` and `ready` read it back, `cell` is the scoreboard's ULT (`READY` once full),
  `badge` a tile's letters, `share` how full a health bar is, and `describe` a tile as scripted
  checks list it.
- **`AbilityConfig.ULT_ATTRIBUTE`** (`VFUlt`) names the attribute.

### The server

- **`AbilityServer`** sets each player's `VFUlt` as their kit's ultimate changes, and to nothing
  where there are no abilities (gun game and deathmatch). Every client can read it, as the reference
  shows an enemy's ultimate.

### The client

- **`ArenaHud`** puts the agent's letters on each tile, a bar under your side's filled to each one's
  health (from combat events, as the labels over players are), and the diamond under anyone's. The
  HUD's `Yours` and `Theirs` attributes list the tiles (`SO 100 ready, JE 74`).
- **`Scoreboard`** has a box for the agent before each name and a ULT column after it, in a panel
  700 wide, up from 640. Its `Ult` attribute lists each row while it's open
  (`SO Player1 READY, JE Player3 0/8`).

### Not here yet

- **Portraits.** Two letters stand in for each agent's portrait, which is Riot's art.
- **Healing's teal.** Patch 11.10's bar turns teal while a player heals and fills as they recover;
  ours simply follows their health.
- **Ping.** ONE Esports lists "player ping" on the scoreboard; ours has none.
- **What a client can read.** `VFUlt` and `VFKit` are both player attributes every client can read,
  so a client could read an enemy's charges as well as their ultimate.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/Glance.luau` | New: the ultimate as the attribute carries it and read back, the scoreboard's ULT, the tiles' letters, a health bar's fill, and a tile described |
| `src/shared/Abilities/AbilityConfig.luau` | `ULT_ATTRIBUTE` |
| `src/server/AbilityServer.luau` | Each player's `VFUlt` |
| `src/client/ArenaHud.luau` | The tiles' agents, your side's health bars, the ready diamonds, and the `Yours` and `Theirs` attributes |
| `src/client/Scoreboard.luau` | The agent box and the ULT column, and the `Ult` attribute |
| `tests/glance.luau`, `tests/run.luau` | New: 34 checks: the ultimate's text, read back, a kit charging, each agent's letters, a health bar, and the tiles described |

## 7. Debug tools

- Each player's `VFUlt` attribute: their ultimate's points and what it needs (`3/8`), or nothing.
- PlayerGui's `VFArenaHud` carries `Yours` and `Theirs`, the top bar's tiles, and `VFScoreboard`
  carries `Ult` while it's open. `VFTestBoard` holds the scoreboard open as Tab does.
- `VFTestGive` set to `ultimate` fills the points in Studio.

## 8. Refinement loop

1. Find a public clip of the top bar with an ultimate ready, and draw ours as it shows it.
2. Find a clip since Patch 11.10 of a teammate healing, and add the teal.
3. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Each player's agent on the top bar, yours and theirs, by its first two letters.
- Your side's health under its tiles, emptied by damage and death; none under the other side's.
- A gold diamond under anyone's tile while their ultimate's ready, an enemy's too.
- The scoreboard's agents and ULT, both sides', live, with `READY` in gold once full.
- The victory screen keeping the agents, without the ULT.
- Gun game: names' letters on the top bar, and no agents or ULT on the scoreboard.

Section 55 of the [Studio checklist](../studio-checklist.md) covers these.
