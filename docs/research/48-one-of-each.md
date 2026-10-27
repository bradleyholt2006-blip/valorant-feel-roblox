# System 48: One of each agent on a side

The reference lets a team have only one of each agent: once a player on a team locks an agent in,
nobody else on that team can pick it, while the other team still can. Sova's kit made five agents to
pick from, as many as a side of the spike rounds or Team Deathmatch has places and more than
Skirmish's two, so every player on a side can now have an agent of their own. This system makes a
side's agents all different. An agent a teammate has locked in this match is taken: it can't be
selected or locked in, and a selection it's taken from moves back to the agent the player plays, or
else to the first that's free, so the time running out never locks in a taken one. The first to lock
an agent in has it, and of windows closing at once on one agent, the first player on the server
keeps it; the other side can play it too. As our matches never stop and players drop in and out of
them, a window is now for a side of a match: someone moved across to even the sides has one for
their new side, and someone back in a match to find their agent taken meanwhile has another. The
agent select screen shows each agent a teammate has taken.

As before, everything comes from public sources: three of Riot's articles (its Beginner's Guide, its
post on Replication and Patch 13.05's notes, with Patch 11.07's read for system 29) and, for what
Riot doesn't give, the VALORANT Wiki's page on Unrated, Mobalytics' guide for beginners and the
press: Sportskeeda, GINX TV, Player.One, Dot Esports and two of ONE Esports' reports. The wiki's
site now refuses every fetch, so its page is quoted as it was read for system 29. No game files,
memory or network traffic were used, and nothing was read from the live game. Riot doesn't state the
rule in anything we could read; the wiki and Mobalytics do, and the press's reports of players
locking agents in before their teammates can show it at work. Nothing in this system is measured.
Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's articles and patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source we could read says what becomes of a teammate's selection of an agent once someone else
locks it in, whether Skirmish and Team Deathmatch keep a side's agents different too, or what the
reference would do with a player who joins a match under way, is moved across to even the sides or
comes back, as it does none of them. Ours are in section 4: the selection moves back to the agent
the player plays, or else to the first that's free; every mode that picks keeps a side's agents
different; and each side of a match has its own window, with another for someone back to find their
agent taken.

## 1. Observable behaviour

- **One of each on a team** (the wiki and Mobalytics). The wiki: "Each player within a team must
  select a unique agent." Mobalytics: "Each team can only choose an agent one time, you cannot have
  duplicates on the same team." Riot's Beginner's Guide has the team pick before the first round,
  "After everyone selects their Agent", and a better chance of winning "when your team has a more
  diverse Agent pool".
- **Locked in first** (the wiki and the press). Only locking in makes an agent a player's: "The
  player's choice is only confirmed when they 'Lock In' their agent choice." The first to lock an
  agent in has it. Sportskeeda's insta-locking is when players "instantly select their agent before
  a match begins", and then "the remaining players are forced to select agents that can effectively
  complement the already selected agents"; GINX TV has teammates who "instantly lock in their agent
  of choice without consulting anyone else on the team"; Player.One has instalocking software that
  would "beat everyone else to a limited team slot"; and Dot Esports has players dodging a match
  because "their agent is taken". Riot penalises "instalock tools" (Patch 13.05).
- **In turns, tested** (ONE Esports, 2022). Riot tested a cascading agent select, where "players
  have to wait their turn to select the agent they want to play", 10 s each, with "a second agent as
  a preference", "designed to mitigate situations where players instalock an agent".
- **The other team** (ONE Esports). Both teams can play the same agents: "two teams playing mirror
  compositions" because they're the meta.
- **Replication** (Riot). One mode turns the rule round: "All players on the same team play as the
  same Agent (e.g. 5 Sages against 5 Jetts)", chosen "in pre-match voting".

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Before you enter your first round, you'll enter Agent Select."; "After everyone selects their Agent, you'll jump into a random map and formally enter the first round."; "While it's not mandatory to have each role in your team of five," "you'll discover that you have a higher chance of winning when your team has a more diverse Agent pool" | [Beginner's Guide](https://playvalorant.com/en-us/news/announcements/beginners-guide/), Riot, 2 August 2024 |
| "All players on the same team play as the same Agent (e.g. 5 Sages against 5 Jetts)"; "Agent selection is decided in pre-match voting." | [New VALORANT Mode: Replication](https://playvalorant.com/en-us/news/game-updates/new-valorant-mode-replication/), Riot, 11 May 2021 |
| "We've started rolling out penalties if we detect usage of stream sniping and instalock tools." | [VALORANT Patch Notes 13.05](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-13-05), 1 September 2026 |
| "We're aware of an issue that's causing intermittent crashing on the Agent Select screen after locking in your Agent." | [VALORANT Patch Notes 11.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-07/), read for system 29 |

### From the community

| What | Source |
| --- | --- |
| "Each player within a team must select a unique agent."; "The player's choice is only confirmed when they 'Lock In' their agent choice."; "Once locked in, a player cannot change their chosen agent." | [VALORANT Wiki, Unrated](https://wiki.playvalorant.com/en-us/Unrated) (Weird Gloop), read for system 29 |
| "Each team can only choose an agent one time, you cannot have duplicates on the same team." | [Mobalytics, Valorant Guide for Beginners](https://mobalytics.gg/?p=21128) |
| "Insta-locking, for those unaware, is when players in Valorant instantly select their agent before a match begins."; "By doing so, the remaining players are forced to select agents that can effectively complement the already selected agents." | [Sportskeeda, Are players that insta-lock duelists ruining the Valorant competitive experience?](https://sportskeeda.com/valorant/news-are-players-insta-lock-duelists-ruining-valorant-competitive-experience) |
| "Effectively removing players' ability to insta-lock their favourite agents"; "having teammates instantly lock in their agent of choice without consulting anyone else on the team" | [GINX TV, Riot to target Valorant insta-lockers by introducing cascading Agent select](https://www.ginx.tv/en/riot-to-target-valorant-insta-lockers-by-introducing-cascading-agent-select), Payton Nash, 11 January 2022 |
| "A normal instalock happens when a player manually selects an Agent and locks them in"; "one player is effectively using software to beat everyone else to a limited team slot."; "If software can automatically secure a popular Agent before another player has a realistic chance to respond" | [Player.One, Valorant Is Going After Instalock Tools](https://www.player.one/valorant-going-after-instalock-tools-should-third-party-apps-allowed-choose-agents-faster-164059), Camille Laurent, 4 September 2026 |
| Players who "will opt to dodge simply because they dislike the map or their agent is taken." | [Dot Esports, on getting past agent select](https://dotesports.com/valorant/news/why-valorants-hardest-task-is-getting-past-agent-select-let-me-play-anything) |
| "players have to wait their turn to select the agent they want to play, similar to champion selection in League of Legends ranked games."; it "gives each player 10 seconds to choose their agent."; "Players can also pick a second agent as a preference."; "designed to mitigate situations where players instalock an agent." | [ONE Esports, on Riot testing cascading agent select](https://www.oneesports.gg/valorant/valorant-testing-cascading-agent-select/), Wanzi Koh, 28 April 2022 |
| "Forget about two teams playing mirror compositions because it is 'meta'."; "both teams fielded starkly different compositions on Fracture comprising 10 different agents." | [ONE Esports, on ZETA DIVISION against NIP](https://www.oneesports.gg/valorant/zeta-division-nip-10-different-agents/), Wanzi Koh, 14 April 2022 |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| What becomes of a teammate's selection of an agent someone else locks in | Public clips of agent select: a player's selection as a teammate locks the same agent in |
| Whether Skirmish and Team Deathmatch keep a side's agents different | Public clips of each mode's agent select or scoreboard |
| How often a player's first choice is taken, and what they play then | Our playtests: how often a selection's moved off a taken agent, and how often the time runs out on what it moved to |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| One of each on a side | In Skirmish, the spike rounds and Team Deathmatch, an agent a teammate has locked in this match is taken from the rest of their side: it can't be selected or locked in | Community (the wiki and Mobalytics); estimate (in Skirmish and Team Deathmatch) |
| Teammates | Everyone else on the same side of the same match now, locked in; someone off the side, in line or gone holds no agent | Estimate |
| Selecting | Teammates can select one agent until one of them locks it in, and see each other's selections, as before | Community (selections shown to teammates: the wiki, system 29); estimate (selecting doesn't take it) |
| The first to lock in | Has it. A lock-in of an agent taken since it was selected is refused, and the window stays open | Community (the press, on insta-locking) |
| A selection taken | Moves back to the agent the player plays if that's free, or else to the first that's free, in the order the cards are shown | Estimate |
| Time running out | What's selected is locked in, and it's never taken. Of windows closing at once on one agent, the first player on the server keeps it, and the others' selections move | Community (the last selected: the wiki, system 29); estimate (the first on the server) |
| The other side | Can play the same agent | Community (mirror compositions: ONE Esports) |
| Each side of a match | A window of its own: someone moved across to even the sides as a round starts (system 21) has one for their new side, in that round's buy phase. Halftime swaps which side attacks, not who's on it, so nobody picks then | Estimate (the reference doesn't move anyone across) |
| Back in a match | Someone back on the side of a match they've had their window in plays on locked in, unless a teammate has locked their agent in meanwhile: then they've another window, on an agent that's free. Of several back at once, as when a mode that waited for players carries its match on, the first on the server keeps theirs | Estimate |
| Free picking | On the course and while a mode waits for players nothing's taken, so teammates can play one agent there until the match carries on | Estimate |
| Fewer agents than places | Once every agent is taken from a player none is, and any can be played twice. With five agents and sides of five at the most, it doesn't happen | Estimate |
| The screen | An agent taken is dimmed and reads `TAKEN` on its card, and a click on it does nothing; with the cursor on it, the line under the button says it's taken. A window opening again brings the screen up by itself | Estimate (ours) |

## 5. Design

### The rules

`AgentSelect` keeps the rule as plain state, as it keeps the rest of agent select:

- **`step`** (new) moves every player's pick on at once, in the server's order of players, once a
  server frame: first each pick moves to where its player is; then, in order, whoever's back on the
  side of a match they've had their window in keeps their agent if it isn't taken, or has another
  window; then each window that's open keeps what's selected free, and closes once its time is up.
  Moved one player at a time, someone leaving or moving across that frame would still hold their
  agent for those moved before them. `update` moves one player's pick, as `step` does.
- **`taken`** (new) gives the agents taken from a player while they're in a match, their window open
  or locked in: those locked in by everyone else whose last window was for the same side of the same
  match and who's locked in on it now. **`takenOf`** (new) is its rule, from the agents teammates
  have locked in: every one of them, unless that's every agent, when none is. `select` and `lock`
  refuse an agent that's taken.
- **`moment`** gives a key for each side of a match: the mode, how many times a mode has started on
  the server, the match's number and the side. It takes the side a player's on, or nil, where it
  took whether they're on one.

### The server

- **`AgentServer`** moves every pick on together once a frame (`AgentSelect.step`), in the order
  `Players:GetPlayers()` gives, after the arena's rounds have moved on.
- **`Arena`** gives each player's side to `AgentSelect.moment` (`AgentServer.momentOf`).

### The client

- **`AgentMenu`** works out what's taken from you as the server does (`AgentSelect.takenOf`), from
  your teammates' `VFAgentPick` and `VFAgent`. Each taken agent's card is dimmed and reads `TAKEN`
  in grey, doesn't light under the cursor and does nothing when clicked, and with the cursor on it
  the line under the button reads, say, `SOVA is taken: a teammate has locked it in`. A click on a
  card shows it selected at once until the server's word on it comes, as before, but never a taken
  one.

### Not here yet

- **Picking in turns.** Riot's test of a cascading agent select, each in turn with a second choice,
  isn't here: the first to lock an agent in has it, as in the reference.
- **A second choice.** A selection taken moves back to the agent played or to the first that's free;
  nobody chooses where it goes.
- **Skirmish's random agents.** Skirmish is player choice, where the reference's 2v2 deals agents at
  random (system 29).
- **Who took it.** A taken card reads `TAKEN`, not who has it; `YOUR TEAM` says who.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AgentSelect.luau` | One of each agent on a side: `taken` and `takenOf`; `step`, every pick moved on together; `select` and `lock` refusing what's taken; a selection moved off a taken agent, and another window for a new side or an agent taken; `moment` by side |
| `src/server/AgentServer.luau` | Every pick moved on together, in the server's order of players |
| `src/server/Arena.luau` | Each player's side, for where they pick |
| `src/client/AgentMenu.luau` | Taken agents: dimmed, `TAKEN`, no click, and the line under the button |
| `tests/oneofeach.luau` | New: 41 checks: the agents, a key for each side, what's taken, a side picking, a selection moved, the time running out, fewer agents than places, back in a match, the spike rounds played and halftime |
| `tests/agentselect.luau`, `tests/run.luau` | System 29's checks with a key for each side and every pick moved on together; the new suite run |

## 7. Debug tools

- While a player's in a match, a teammate's `VFAgent`, with their `VFAgentPick` reading `locked`, is
  taken from them.
- `VFTestAgent` set to a taken agent's id is refused by the server, as a click on its card does
  nothing.
- `VFMatchSkip` moves a match on, and the next match opens everyone's window again, each side's of
  its own.

## 8. Refinement loop

1. Play full sides of five, and count how often a player's selection is moved off a taken agent and
   how often the time runs out on what it moved to. If players often end up on agents they didn't
   choose, try a second choice, as Riot's cascading test had, or picking in turns.
2. Once clips show what becomes of the reference's selection as a teammate locks the same agent in,
   match it.
3. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Three players in Skirmish: before anyone locks in, teammates can both select one agent; once one
  locks it in, its card on their teammate's screen is dimmed and reads `TAKEN`, a click on it does
  nothing, the cursor on it says it's taken, and their selection moves back to the agent they play.
- The other side locking in the same agent.
- The time running out on what a selection moved to.
- In the spike rounds, teammates' windows closing at once on one agent: the first player on the
  server keeps it, and the other's selection goes back to the agent they play.
- System 29's time running out, with player 1 on Jett: player 3 now ends on Phoenix.

Section 52 of the [Studio checklist](../studio-checklist.md) covers these.
