# System 65: bots' agents

Each bot plays an agent. In the agent select window it picks one as a player does, an agent nobody
on its side has, and the top bar and the scoreboard show it with its ultimate's points. Its kit is a
player's: the round's free charge of its signature, and points for kills, deaths, plants and
defuses. It keeps its kit from one life to the next, as a player does.

Every ability treats a bot as it treats a player. A flash blinds it, and while it's at its whitest
the bot sees nothing; Paranoia leaves it seeing no further than a player would; a Healing Orb heals
an allied bot; and a Recon Bolt or Hunter's Fury no longer reveals or hits a bot on its own side, as
it did while bots were taken for practice dummies. Buying charges and casting are system 66: here a
bot holds its kit but doesn't use it yet.

Nothing new is published about bots playing agents, so how a bot picks is ours, set against how a
player does (systems 29 and 48) and against two of the Counter-Strike bot's designer's aims: bots
that differ from one another, and bots that leave what matters most to players. No game file or
source code was read, nothing was read from the live game, and no Riot image, model or sound is in
the repository.

## 1. Observable behaviour

- Agent select gives each player a window, and an agent a teammate has locked in is taken from the
  rest of the side; what's selected is locked in as the window closes (system 29, system 48).
- A flash turns a player's screen white, and they see again as it fades; Paranoia leaves them
  seeing only what's near (systems 30 and 41).
- The Counter-Strike bot's designer varies how bots behave, and by default has them leave the
  scenario's key objective to players.

## 2. Publicly documented details

| What | Source |
| --- | --- |
| "Creates behavior variation among bots" | Michael Booth, [The Official Counter-Strike Bot](https://media.gdcvault.com/gdc04/slides/making_of_official.pdf), GDC 2004, slides: The Importance of Being Human |
| "By default, bots defer key scenario objective to human Players" | The same: Making it Fun: Respect the Player |

What a pick, a window and an ability's charges are, and what a flash and Paranoia do to a player,
are the earlier systems', with their sources (systems 17, 29, 30, 36, 41, 44, 46 and 48).

## 3. What can be measured, and how

How a bot picks is decided on the server, so it's checked in Studio (section 69 of the checklist):
each bot's stand-in carries its pick and its kit as a player carries theirs (`VFAgent`,
`VFAgentPick`, `VFKit`, `VFUlt`), and a blind or a nearsight on it (`VFBlind`, `VFNearsight`). The
offline suite, 3860 checks, still passes with every ability server taking bots.

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| Each bot plays an agent, one of each on a side | Agent select's rules, as a player's | Estimate | Ours, on systems 29 and 48 |
| Which agent | At random, of those nobody on its side has locked in or selected | Estimate | Ours, for "behavior variation" (Booth) |
| When it's locked in | As its window closes, after every player's; at once where picks are free | Estimate | Ours: players first, as Booth's bots "defer" to them |
| Its kit between lives | Kept, with nothing under way | Estimate | As a player's (system 17) |
| A flash's blind on a bot | Sees nothing while the white is at least 0.5 | Estimate | Ours: past that, a player starts to see again as it fades |
| Paranoia on a bot | Sees nothing further than the nearsight's range | Estimate | As a player's screen (system 41) |

## 5. Design

### Picking

Agent select (`AgentSelect`) takes bots after every player, by their ids in the rules
(`AgentServer`). The first time a bot picks for a side of a match it selects at random from the
agents nobody on its side has locked in or selected, a player's selection too, so a bot never stands
in a player's way; it keeps that selection until a teammate takes it, and then selects again from
what's left. Its selection is locked in as its window closes, after every player's, so where a
player and a bot close on one agent at once, the player gets it. Where picks are free (the course,
and a mode waiting for players) it's locked in at once. With five agents and five a side, a side of
bots plays all five.

Its pick goes to clients on its stand-in as a player's goes on them, so the top bar and the
scoreboard badge it with its agent and show its ultimate's points. A bot that leaves gives its pick
up with it.

### The kit

Its agent goes on its kit as a player's does (`AbilityServer.choose`), and every round start gives
it what a player's gets: the signature's free charge, and the ultimate's points for the round
(`AbilityServer.roundStarted`), as does a fresh start in Team Deathmatch. Kills and deaths give it
points, and a kill gives a signature charge back where the agent has one (`AbilityServer`'s kill
listener, which now knows a bot as the killer by its entity), and so do a plant and a defuse
(`SpikeServer.objectiveListeners`, with the bot's stand-in). Between lives its kit is kept with
nothing under way (`AbilitySim.settle`), as a player's.

### Abilities on bots

Every ability server knows a bot by its stand-in, as it knows a player by the `Player`
(`PlayerSimServer.Actor`), and `BotServer` answers for it there: its entity, its simulation, its eye
and aim, whether it's alive and in play (`PlayerSimServer.bots`). Its deaths and new lives go to
the ability servers as a player's do (`botDeathListeners`, `botSpawnListeners`), so a blind ends
with its life, a fire stops healing it, and a cloud it was steering flies on by itself.

- **Flashes.** A pop blinds every bot that can see it as it blinds a player (`FlareServer`), on its
  stand-in's `VFBlind`. While the blind is at least half white (`BotConfig.blindFrom`) the bot's
  looks find nobody; once it fades past that, it sees again.
- **Paranoia.** It nearsights a bot as a player (`ParanoiaServer`, `VFNearsight`), and the bot's
  looks find nobody further than the nearsight's range (`ParanoiaSim.range`).
- **Heals.** A Healing Orb heals an allied bot, and the healer's `VFLastHeal` names it.
- **Recon and Hunter's Fury.** Both now skip bots on the owner's side, as they skip players on it;
  they took bots for practice dummies before, and revealed or hit them whatever their side.
- **What it casts.** A bot's casts and ticks go to the ability servers as a player's do
  (`castListeners`, `tickListeners`), so once it casts (system 66) what it throws flies, bursts and
  hurts as a player's. The Owl Drone, Resurrection, Run it Back, From the Shadows and Shrouded Step
  take only players' ticks for now.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/server/PlayerSimServer.luau` | `Actor`: a player or a bot's stand-in; the bots' hooks, and their deaths and lives for the ability servers |
| `src/server/BotServer.luau` | Answers for its bots there; their casts and ticks to the ability servers; the kit kept between lives; blinded and nearsighted looks |
| `src/server/AgentServer.luau` | Bots pick after every player, on their stand-ins |
| `src/server/Arena.luau` | A bot's kit at each round's start and in Team Deathmatch; picks by id |
| `src/server/AbilityServer.luau` | Kits, points and recharge for bots too |
| `src/server/SpikeServer.luau` | A bot's plant and defuse give it points |
| `src/server/FlareServer.luau`, `src/server/ParanoiaServer.luau` | Blinding and nearsighting bots |
| `src/server/ReconServer.luau`, `src/server/FuryServer.luau` | Bots on the owner's side skipped |
| `src/server/HealServer.luau`, `src/server/FireServer.luau`, `src/server/CloudServer.luau`, `src/server/BlazeServer.luau`, `src/server/BarrierServer.luau`, `src/server/ShockServer.luau`, `src/server/SlowServer.luau` | Bots as actors |
| `src/server/DroneServer.luau`, `src/server/ReviveServer.luau`, `src/server/RunItBackServer.luau`, `src/server/ShadowServer.luau`, `src/server/StepServer.luau` | Players' ticks only, for now |
| `src/shared/Bots/BotConfig.luau` | `blindFrom` |
| `docs/studio-checklist.md` | Section 69 |

## 7. Debug tools

- Each bot's stand-in (ReplicatedStorage's `VFBots`) carries what a player carries: its pick
  (`VFAgent`, `VFAgentSelected`, `VFAgentPick`), its kit (`VFKit`, as `C0/2 Q0/1 E1/1 X3/7`), its
  ultimate (`VFUlt`), a blind (`VFBlind`) and a nearsight (`VFNearsight`).

## 8. Refinement loop

1. Play the spike rounds with bots and look at the scoreboard: which agents the bots play, and
   whether a flash or Paranoia on them buys a player the time it buys against a player.
2. Tune `BotConfig.blindFrom`, and re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Bots picking in the window, one of each agent on a side, never what a player selected, and their
  agents on the top bar and the scoreboard.
- A flash blinding a bot and Paranoia nearsighting it, in the place's real geometry.
- A Healing Orb healing an allied bot, and a Recon Bolt and Hunter's Fury leaving allied bots be.

Section 69 of the [Studio checklist](../studio-checklist.md) covers these.
