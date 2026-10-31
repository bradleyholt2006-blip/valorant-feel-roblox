# System 62: taking over a bot

A player who dies can play on as a bot of their side. Watching a living bot on their side, in
Skirmish or in the spike rounds of any format but Competitive, while a round's played, the line
under its name reads `F  take control`, and F starts their new life in the bot's body: where it
stands, looking where it looked, with its guns and the rounds in them, the gun it had in hand
already drawn, its health and shield as they are, and the spike if it carries it. The bot's out of
the round from then, with no death in the record, and plays again from the next round; the player's
alive in its place, so each side has as many alive as before.

This is Counter-Strike's way with bots, which lets the dead take over a bot they're watching with
the use key and play on as it for the rest of the round, and which Counter-Strike took out of its
competitive modes in 2021, with the bots themselves. Here it's F, the interact key, and not in
Competitive either.

Two things differ from Counter-Strike, by choice. What the player does in the bot's body goes in
their own record, not the bot's: the body's theirs for the rest of the round, and its guns are
theirs to keep if they live, as a survivor keeps theirs. And a player keeps their own abilities in
it, as any life of theirs does, where a Counter-Strike bot has none to give.

Everything comes from public sources: PC Gamer's report of Counter-Strike's change, the Valve
Developer Community's list of Counter-Strike 2's console variables, a Steam Community discussion and
a Counter-Strike guide. No game file or source code was read, nothing was read from the live game,
and no Riot image, model or sound is in the repository.

## 1. Observable behaviour

- In Counter-Strike's casual modes, a dead player watching a bot on their team presses the use key
  and plays on as that bot, from where it is, with what it carries.
- It lasts for the rest of the round: the next round, the player's back in their own body and the
  bot's a bot again.
- A bot someone's playing as can't be taken by anyone else.
- In Counter-Strike's competitive mode, before 2021, a player who left was replaced by a bot that
  the first of their team to die took over; since then there are no bots there at all.

## 2. Publicly documented details

| What | Source |
| --- | --- |
| "That player is then replaced by a bot, which has terrible AI but can be taken-over by a dead player on the team." | PC Gamer, [Counter-Strike: Global Offensive removes bots from competitive](https://pcgamer.com/counter-strike-global-offensive-removes-bots-from-competitive), 8 January 2021 |
| "and then the first member of the team to die takes it over." | The same |
| "it's removed them from classic competitive (5v5) and the wingman (2v2) modes entirely." | The same |
| `bot_controllable`, true by default: "Determines whether bots can be controlled by players" | Valve Developer Community, [List of Counter-Strike 2 console commands and variables](https://developer.valvesoftware.com/wiki/List_of_Counter-Strike_2_console_commands_and_variables) |
| `cl_observed_bot_crosshair`, 0 by default: "Control the crosshair shown when observing a bot. 0: Show player crosshair. 1: Show player crosshair only when bot can be taken over, otherwise show default.. 2: Always show default crosshair for bots." | The same |
| "If nobody is possessing the bot, press E."; "Check your "Use" key in settings." | Steam Community, [a Counter-Strike discussion](https://steamcommunity.com/app/730/discussions/0/527274088404499735), 7 September 2015 (community) |
| "Just switch your view to a bot", then E, which "lets you continue playing for the rest of the round" | cs2pulse, [How To Control Bots in CS2?](https://cs2pulse.com/how-to-control-bots-in-cs2) (community) |
| "All kills will count toward the bot's scoreboard, not yours." | The same (community) |

Valve doesn't publish what a takeover carries over, or when one isn't allowed beyond
`bot_controllable`; what's carried here, and when, is ours, below.

## 3. What can be measured, and how

Nothing about a takeover is timed in Counter-Strike's sources, so it's measured by what the offline
tests can check (`tests/takeover.luau`, 37 checks): the rules of who may take over whom and when, in
each format and in Skirmish; what the round's rules and its callouts make of it; and the kit a
body's taken over on, from the bot's simulation to the text its new character carries and back to
the new life's weapons, which come out the same on the server and the client. A bot with 7 rounds
left in its Vandal and 40 in reserve, 3 in its Sheriff, which it has in hand, and the spike is taken
over on `vandal:7:40,sheriff:3:24,knife:0:0,spike:0:0;2`, and the new life has the Sheriff drawn
with its 3 rounds.

The time from F to playing is a new character's: the server starts the life once Roblox has loaded
the player's character, which the server's notes put at about a third of a second in Studio
(`PlayerSimServer.SPAWN_WAIT`). The bot plays on meanwhile, and the life starts where it is then. If
it falls first, the takeover doesn't happen, and the player goes on watching.

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| Taking over a bot of your side after dying, for the rest of the round | Watching it, a key | Community | The Steam discussion and cs2pulse; `bot_controllable` (Valve Developer Community) |
| Not in the competitive mode | Competitive's format has none | Confirmed (Counter-Strike, quoted by the press) | PC Gamer, 8 January 2021 |
| The key | F, the interact key | Estimate | Counter-Strike's use key (E), as ours is F |
| Where | Skirmish, and the spike rounds' standard and Swiftplay formats | Estimate | Counter-Strike's casual modes; ours has no casual mode of its own |
| When | While a round's played: live, and in the spike rounds planted too | Estimate | Ours |
| Who | Anyone down on a side, a player who joined the round under way too; any living bot on it, once | Estimate | Ours; Counter-Strike's bot is "possessed" by one player |
| What carries over | Where it stands, its yaw and pitch, its guns, rounds and reserve, the gun in hand drawn, its health, shield, the shield's regen pool and when it was last hit, the spike, and half a defuse | Estimate | Ours |
| What doesn't | Its speed, a crouch, a reload or a plant under way | Estimate | Ours: the new life starts standing still |
| Abilities | The player's own | Estimate | Ours: a bot has none |
| Whose record | The player's | Estimate | Ours, where Counter-Strike counts it for the bot (cs2pulse, community) |
| The bot's next life | On the mode's starting kit; its guns went with its body | Estimate | Ours |
| Waiting for the new life before F asks again | 3 s | Estimate | Ours; a character's loaded in about a third of a second in Studio |

## 5. Design

### Who may, and when

The round's rules decide (`MatchRules.canTakeOver`, `ArenaRules.canTakeOver`, both on
`Roster.canTakeOver`): in the spike rounds while a round's live or the spike's planted, in a format
whose `takeOver` is true (the standard format and Swiftplay's, not Competitive's); in Skirmish while
a round's live; someone down on a side, and someone alive on the same side to take over. The rules
know no bots, so the server checks the one asked for is a bot and alive (`Arena`), and that the
player isn't alive or about to be: not mid-spawn, and not on their way back by Sage's Resurrection.

### What it changes

In the rules (`Roster.takeOver`), the player's alive and the bot's down, with no death in the
record, so each side has as many alive as before and the round goes on as it was. The hurts of the
bot's life carry on as the player's, so an enemy who damaged the body assists if the player then
falls in it; and a player who joined the round under way has played in it now, for their average.
What the player does from then counts for them, kills, damage, credits for kills and ultimate points
alike, and a death in the body is theirs: their next life's on the starting kit in the spike rounds,
as after any death, and if they live, they keep the body's guns. The bot's next life is on the
mode's starting kit, its guns gone with its body; in the spike rounds it buys again with its own
credits.

The round-end callouts (`RoundCallouts.tookOver`) put the player in the bot's place, as if they'd
started the round in it, so their kills in it count toward an ace, and the bot's out of the round
there too.

### The body

The bot keeps playing until the player's new character is there. Then the server checks it can still
be taken; if so, the bot's taken out of play (`BotServer.takeOut`), with no death, and its body's
handed over as it is (`PlayerSimServer.Body`): the new life starts at its feet, facing and looking
as it did, on its kit (`BotTakeover.Kit`) with each gun's rounds and the one in hand already drawn,
its health and its shield's kind, points, regen pool and last hit. The spike it carried becomes the
player's as the life starts (`SpikeServer.botTaken`), and a defuse it had taken past its half keeps
its half, as at a death. The player's own ability kit goes on as in any life of theirs. If the bot
fell meanwhile, or the round ended, the new character's taken away again with no life in it, and the
player goes on watching.

The new character carries the body's pitch and kit (`VFSpawnPitch` and `VFSpawnKit`, set before
`VFSpawnFeet`), so the owner's prediction starts on the bot's guns and rounds with the server's, and
the first shots are the right gun's.

### On screen

`Spectate`'s line under the watched bot's name reads `F  take control` when it may be taken
(`BotTakeover.open`, from the arena's mode, format and phase), then `Taking control` for up to 3 s
after F, until the new life starts. F asks once; the server checks everything again.

### The tests

`tests/takeover.luau` has 37 checks: the formats that have it; in the spike rounds, nobody in the
buy phase, nobody alive, not an enemy or themselves, taking over, alive in its place with as many
alive on the side, no death for it, the round going on and ending once the rest fall, the bot not
taken twice; the hurts and the assist; with the spike planted; Competitive and Swiftplay; a joiner
under way; Skirmish's rules; the callouts, an ace in a body taken over, and a joiner's worth; when
the client offers it; and the kit, as text and back, what isn't one, and the new life's weapons the
same on the server and the client.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Bots/BotTakeover.luau` | New: when the client offers it, and a body's kit, as text and on a new life's weapons |
| `src/shared/Match/MatchConfig.luau` | Each format's `takeOver`: not Competitive's |
| `src/shared/Match/Roster.luau`, `src/shared/Match/MatchRules.luau`, `src/shared/Arena/ArenaRules.luau` | Who may take over whom, and when; alive in its place, with no death for it |
| `src/shared/Match/RoundCallouts.luau`, `src/server/CalloutServer.luau` | The callouts with the player in the bot's place |
| `src/server/PlayerSimServer.luau` | A new life in a bot's body, or none if it's gone |
| `src/server/BotServer.luau` | Taking a bot out of play, its body as it is |
| `src/server/SpikeServer.luau` | The spike a bot taken over carried, and its half of a defuse |
| `src/server/Arena.luau` | The `TakeOver` remote, the checks, and the hand-over |
| `src/shared/CharacterRig.luau`, `src/shared/Net/Remotes.luau` | `VFSpawnPitch`, `VFSpawnKit`, and the remote |
| `src/client/Spectate.luau` | The line under the name, and F |
| `src/client/Debug/TestAim.luau` | `VFTestTake` takes over the bot watched too |
| `src/client/PlayerController.luau` | The new life on the body's kit and pitch; a character taken away again |
| `tests/takeover.luau`, `tests/run.luau` | New: the 37 checks |
| `docs/studio-checklist.md` | Section 66 |

## 7. Debug tools

- The watched bot's stand-in (ReplicatedStorage's `VFBots`) reads `VFAlive` false once it's taken
  over, and the player's `VFAlive` true, with no death added to the bot's `VFDeaths`.
- The player's new character carries `VFSpawnKit`, the body's kit as text, and `VFSpawnPitch`.
- In Studio, a player's `VFTestTake` set to true presses F for them, as it does for a gun on the
  ground: set from the server's command bar for two players at once, it has them ask for the same
  bot together.
- In Studio, the server prints a `[VF] takeover:` line for each takeover asked for: `asked`, then
  `into` the bot's body as the new life starts; or why not: refused, with the rules' phase and who's
  down, the bot gone first, or another life asked for before the character loaded.

## 8. Refinement loop

1. Play the spike rounds and Skirmish with bots, die and take one over: how quickly F answers,
   whether the view and the gun carry on as they were, and whether the round reads right afterwards.
2. Tune `TAKE_WAIT` in `Spectate` and what carries over, and re-run `tests/takeover.luau`.
3. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The prompt under a watched bot's name, F, and the new life in its body: where it stood, looking
  the same way, its gun in hand with its rounds, its health and shield, and the HUD showing them.
- The bot taken out of play with no death: gone from view, down on the scoreboard and the top bar,
  its deaths as they were, and back next round on the starting kit.
- The spike a bot carried, the player's, and planted by them.
- Not in Competitive, nor in the modes that respawn; and in Skirmish.
- A takeover asked for as the bot falls: no life, and watching goes on.
- With a controller's RS in Skirmish (section 72's PD7), a takeover asked for twice never came in
  one Studio run, the player's `VFAlive` reading true as they watched; the `[VF] takeover:` lines
  are to say why, by RS and by F.
- The record afterwards: kills in the body the player's, and the guns kept for the next round if
  they live.

Section 66 of the [Studio checklist](../studio-checklist.md) covers these.
