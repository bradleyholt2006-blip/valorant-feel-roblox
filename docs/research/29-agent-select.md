# System 29: Agent select

The reference has each player pick an agent before a match, in Agent Select, a lobby that every
player loads into. Our matches never stop (system 21) and players drop into them under way, so
there's no lobby to pick in. This system gives each player their own agent all the same: once a
match, a short window to pick in, from the match's start or from when they join it, and the agent
locked in for the rest of the match; picking at any time on the course and while a mode waits for
players, as in the reference's Range; the agent select screen, on T; and the buy menu selling the
abilities of the agent you play.

As before, everything comes from public sources: Riot's Beginner's Guide, an Ask VALORANT answer on
agent select's time, two patch notes and Jett's page, and, for what Riot doesn't give (the time,
locking in, the time running out, a team's agents all different and each mode's way of picking), the
VALORANT Wiki's pages on the modes and the Range. No game files, memory or network traffic were
used. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's articles, patch notes and agent pages) |
| **Community** | Published by a guide or wiki, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **Agent Select** (Riot's Beginner's Guide). Before the first round, players enter Agent Select
  and pick from the agents, 24 when it was written, in four roles; a team of five doesn't have to
  have every role. Jett's role, on her page, is Duelist.
- **Its time.** The wiki: 90 s. Riot, asked whether Spike Rush's could be shorter, kept it: the
  time is there for players' different load-in times, and a shorter one "might result in
  significantly more dodges".
- **Locking in** (the wiki). Selecting an agent shows teammates what a player is thinking of; only
  locking in confirms it, and once it's locked in it can't be changed. Riot's patch notes name the
  step too (11.07: a crash "on the Agent Select screen after locking in your Agent").
- **Time running out** (the wiki). The last agent a player selected is locked in for them; if they
  never selected one, the match is cancelled.
- **One of each** (the wiki). "Each player within a team must select a unique agent."
- **Each mode** (the wiki's pages). Competitive, Swiftplay and Team Deathmatch are player choice;
  Skirmish is "Either random or player choice", its 2v2 random; Deathmatch gives each player a
  random agent, with no abilities to buy or use.
- **The Range** (the wiki). Every agent is unlocked there, and a key swaps the agent played at any
  time.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Before you enter your first round, you'll enter Agent Select." | [Beginner's Guide](https://playvalorant.com/en-us/news/announcements/beginners-guide/), Riot, 2 August 2024 |
| "Here you'll pick from a group of 24 Agents currently, all divided into four different roles based on their functionality." | The same |
| "While it's not mandatory to have each role in your team of five" | The same |
| Asked whether Spike Rush's agent select could be shorter: "we're going to leave the Agent select time as is, for now." | [Ask VALORANT - Feb. 11](https://playvalorant.com/en-us/news/dev/ask-valorant-feb-11/), Riot, 11 February 2021 |
| "the current time is to help account for different load-in times per player."; "a shorter Agent select window might result in significantly more dodges" | The same |
| "We're aware of an issue that's causing intermittent crashing on the Agent Select screen after locking in your Agent." | [VALORANT Patch Notes 11.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-07/) |
| "Report in Agent Select is now live!"; "You can now report disruptive players during the pregame." | [VALORANT Patch Notes 3.12](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-12/) |
| Jett's role: "Duelist" | [Jett](https://playvalorant.com/en-us/agents/jett/), Riot's agent page |

### From the community

| What | Source |
| --- | --- |
| "Agent Select, which lasts for 90 seconds." | [VALORANT Wiki, Unrated](https://wiki.playvalorant.com/en-us/Unrated) (Weird Gloop) |
| "The player's choice is only confirmed when they 'Lock In' their agent choice." | The same |
| "Each player within a team must select a unique agent." | The same |
| When the time runs out, "the game will automatically lock in the last agent that the player had selected"; with none selected, "the match will be cancelled instead." | The same |
| "Once locked in, a player cannot change their chosen agent." | The same |
| Agent selection "Player choice"; "two teams of five players select their agents." | [VALORANT Wiki, Competitive](https://wiki.playvalorant.com/en-us/Competitive) |
| Agent selection "Player choice" | [VALORANT Wiki, Swiftplay](https://wiki.playvalorant.com/en-us/Swiftplay) |
| "players select their agent before going into game"; agent selection "Player choice." | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) |
| Agent selection "Either random or player choice."; for its 2v2 "Random", agents "random depending on the player's ownership of Agents." | [VALORANT Wiki, Skirmish](https://wiki.playvalorant.com/en-us/Skirmish) |
| Agent selection "Random"; "Each player loads into a random map with a random agent that they own."; "Players cannot buy or use abilities." | [VALORANT Wiki, Deathmatch](https://wiki.playvalorant.com/en-us/Deathmatch) |
| "All agents are unlocked in the Range"; "the player can press F2" to swap their current agent | [VALORANT Wiki, Range](https://wiki.playvalorant.com/en-us/Range) |

Neither source says whether someone who joins a match under way picks, or for how long, as the
reference doesn't drop players into matches; whether the two sides can play the same agent; or
what a kit would do if its agent changed during a match, which it can't. Ours are in section 4.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How the reference's screen reads: the cards' order, what the kit panel shows, and how teammates' picks show | Public clips of agent select |
| Whether 10 s is long enough to pick in without hurrying, and short enough to leave the first buy phase for buying | Our own playtests: how long each player takes from the window's start to LOCK IN, how often the time runs out, and what they buy in that buy phase |
| Whether a side needs one of each agent | Our playtests once there are several agents: how often a side has two of one, and how those matches go |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Each player's agent | Their own in Skirmish, the spike rounds and Team Deathmatch, as they pick it; Jett until they do | Confirmed (Agent Select); community (player choice); estimate (Jett until then) |
| The window | Once a match, from its start, or from when they join it under way or get a place out of line; while it's open, an agent can be selected and locked in | Community (locking in); estimate (once a match, and a latecomer's own) |
| Its time | 10 s, inside every mode's first phase: Skirmish's first buy phase, 15 s, the spike rounds', 45 s, and Team Deathmatch's pre-game, 20 s. A latecomer to Team Deathmatch has 5 s to spare before their spawn room burns them | Estimate (the reference's 90 s is for a lobby that loads everyone in) |
| Locking in | LOCK IN makes the agent selected theirs, and the window closes | Confirmed (locking in); community |
| Time running out | What's selected is locked in. A window starts with the agent they last played selected, so nobody is left without one | Community (the last selected); estimate (the last played, in place of the reference's cancelled match) |
| Locked | Their agent until the match is over; the next match opens another window | Community |
| Free picking | On the course and while a mode waits for players, an agent picked is theirs at once, as often as they like | Community (the Range's swap at any time); estimate (while waiting) |
| Nobody picks | In gun game and deathmatch, which have no abilities; between matches, on the victory screen and in the vote; and off a side, in line or in the Play menu | Community (no abilities in deathmatch); estimate (the rest) |
| A team's agents all different | Not applied: two on a side can play one agent | Community (the rule); estimate (not yet, with fewer agents than a side has places) |
| Skirmish | Player choice | Community (either); estimate (choice, where the reference's 2v2 is random) |
| Deathmatch | No agent, as before (system 26) | Community (no abilities); estimate (no agent rather than a random one) |
| Onto the kit | At once where nothing's lost by it: on the course, while down, while a mode waits, in a buy phase, in Team Deathmatch's pre-game and in your own spawn room there; anywhere else with the next life | Estimate |
| A new agent's kit | As the mode starts one: every charge on the course and in Skirmish, and on the course the ultimate's points too; as a half starts in the spike rounds (the signature's free charge, nothing bought, no points); and as a match starts in Team Deathmatch | Estimate |
| Selling back | In the spike rounds, every charge bought into the last agent's kit this buy phase is sold back for its price | Estimate |
| Roles | Each card shows its agent's role as Riot's page names it: Jett a Duelist | Confirmed |
| The screen | T: a card for each agent with its name and role, the kit of the one selected, your side's picks, the time left and LOCK IN | Confirmed (a screen to lock in on); estimate (the layout, T) |

## 5. Design

### Where you pick

Once a server frame, each player is somewhere for picking (`AgentSelect.moment`), as the mode
played, its phase and their side say:

| Where | Picking |
| --- | --- |
| The course | Free: an agent picked is yours at once |
| A mode waiting for players | Free |
| A match of Skirmish, the spike rounds or Team Deathmatch, on a side | A window once a match, then locked |
| Gun game and deathmatch | Nobody picks |
| The victory screen and the vote | Nobody picks |
| In line, or in the Play menu | Nobody picks |

A match is known by a key of its own: the mode, how many times a mode has started on the server,
and the match's number, so the first match after a mode starts over is a new one. The first frame
a player is in a match they haven't had a window in, theirs opens for `AbilityConfig.Select.time`,
with the agent they play selected. It closes once the time's up or once they're out of the match,
and what's selected is locked in. A player who leaves their side and comes back in the same match
has had their window. In gun game, which has no abilities, the kit stays the agent's they last
played, for its passive (Jett's glide); in deathmatch it's no agent's, as before.

### The rules

`AgentSelect` keeps each player's pick as plain state, by player id: the agent they play, the one
selected, where they stand (`free`, `open`, `locked` or `none`), when the window closes, and the
match it was for. `update` moves a pick on to where its player is, and says when the agent they
play has changed; `select` takes a click on a card, where they can pick; `lock` locks in, closing
the window, or where it's free makes the agent theirs at once; and `swapsNow` says whether an
agent locked in goes on the kit at once. The agents to pick from are those with an ability that
can be played (`pickable`), in `AbilityConfig.AgentIds`' order, so an agent whose kit is being made
comes in with its first ability.

### The server

- **`AgentServer`** (new) hears the `AgentPick` remote (`select` with an agent's id, or `lock`),
  moves every pick on once a server frame after the arena, and puts each player's on their
  attributes, `VFAgent`, `VFAgentSelected`, `VFAgentPick` and `VFAgentCloses`, which teammates'
  screens read too.
- **`Arena`** says where each player is (`AgentServer.momentOf`) and whether an agent goes on their
  kit at once (`AgentServer.swapsNow`); in Team Deathmatch it's at once in their own spawn room, as
  a loadout is. Every mode but deathmatch now leaves the kit's agent to each player
  (`AbilityServer.agent` nil).
- **`AbilityServer`** keeps each player's agent (`agentOf`). `choose` puts a new one on the kit at
  once, starting the kit over as the mode starts one, or leaves it for the next life, whose spawn
  starts it over.
- **`ShopServer`.** A new agent's kit sells back every charge bought into the last one's this buy
  phase (`refundCharges`, by `Shop.sellCharges`), and the credits come back.

### The client

- **`AgentMenu`** (new), on T where you can pick: a card for each agent with its name and role,
  outlined in gold while it's selected and tagged `YOURS` or `LOCKED IN`; the kit of the agent
  under the cursor or selected, each ability with its key and line, and its passive; `YOUR TEAM`,
  each teammate with what they've selected, `SELECTING` while their window's open and `LOCKED IN`
  after; the time left; and the button: `LOCK IN` in a window, and where it's free `PICK` and the
  agent selected, or `PLAYING` and yours. It comes up by itself as your window opens, when there's
  more than one agent, closing the buy menu or the loadout menu, and goes as the window closes.
  It doesn't open over the Play menu or another menu, but the settings menu opens over it. While
  it's open the mouse moves a cursor and you can still move. An agent locked in that comes with
  your next life says so under the button.
- **`BuyMenu`** sells the abilities of your kit's agent, each agent's in the same places; with a
  kit of no agent's (deathmatch), those of the agent you've picked.

### Not here yet

- **A second agent.** Only Jett plays, so the screen has one card and never comes up by itself,
  and a change of agent is played only by the offline tests until another agent's kit is in.
- **A team's agents all different**, until there are as many agents as a side has places.
- **Portraits, models and voice lines.** The cards are text, and players are still drawn as their
  hitboxes.
- **Deathmatch's random agent.** Deathmatch's kit is still no agent's (system 26), as it has no
  abilities.
- **Owning agents.** Every agent can be picked by everyone, as every agent can in the Range.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AgentSelect.luau` | New: each player's pick as plain state: windows, locking in, free picking, where a player is, and whether an agent goes on the kit at once |
| `src/shared/Abilities/AbilityConfig.luau` | Each agent's role, the passives' names and lines, and `Select.time`, with its status and source |
| `src/shared/Weapons/Shop.luau` | `sellCharges`: every charge bought this buy phase sold back |
| `src/shared/Net/Remotes.luau` | `AgentPick` |
| `src/server/AgentServer.luau` | New: the remote, every pick moved on once a frame, and the attributes |
| `src/server/AbilityServer.luau` | Each player's own agent: `agentOf`, `choose`, and a new agent's kit at once or with the next life |
| `src/server/ShopServer.luau` | `refundCharges` |
| `src/server/Arena.luau`, `src/server/init.server.luau` | Where each player is for picking and whether a swap is at once; each mode's agent; agent select started and stepped |
| `src/client/AgentMenu.luau` | New: the agent select screen, on T |
| `src/client/BuyMenu.luau` | The abilities of the agent you play |
| `src/client/init.client.luau`, `src/client/Debug/TestAim.luau` | The screen started; `VFTestAgents` and `VFTestAgent` |
| `tests/agentselect.luau` | New: 77 checks: the numbers, the agents, where a player is, a swap at once, free picking, a window, Skirmish played, and selling back |

## 7. Debug tools

- Each player's `VFAgent` is the agent they play, or will from their next life; `VFAgentSelected`
  what they've selected, while they can pick; `VFAgentPick` where they stand (`free`, `open` or
  `locked`, unset where nobody picks); and `VFAgentCloses`, while their window's open, when it
  closes, in server time.
- `VFTestAgents` set to true or false opens or closes the screen as T does, and `VFTestAgent` set
  to an agent's id selects it as a click on its card does, or set to `lock` locks in as the button
  does. Each clears itself.
- `VFMatchSkip` moves a match on, and the next match opens everyone's window again.

## 8. Refinement loop

1. Play with as many as can join, and time each player's lock-in from the window's start. If the
   time often runs out with players still choosing, or the first buy phase goes by with too little
   bought, change `AbilityConfig.Select.time`; the tests hold it inside every mode's first phase.
2. Once there are as many agents as a side of five has places, make a team's agents all
   different, and look again at Skirmish's random 2v2.
3. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- T on the course: Jett's card with her role, her kit and Drift, `PICK ANY TIME` and
  `PLAYING JETT`, with a cursor, and you can still move.
- It doesn't open over the buy menu, the settings menu or the Play menu, and the settings menu
  opens over it and gives the cursor back to it.
- In a match, the window: `LOCK IN WITHIN` counting down from 10 as the match starts; LOCK IN, or
  the time running out, locks in what's selected, and the screen goes. (A latecomer's own window
  is the offline tests'.)
- After the window, `LOCKED IN` until the match is over, and a new window as the next one starts.
- The buy menu's abilities, Jett's as before.
- Nobody picks in gun game or deathmatch, on the victory screen or in the vote: T does nothing.
- Teammates' picks: `SELECTING` while their window's open, and `LOCKED IN` after.

Section 33 of the [Studio checklist](../studio-checklist.md) covers these.
