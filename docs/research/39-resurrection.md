# System 39: Sage's Resurrection

Sage's ultimate is played, and with it her whole kit: X with its points full puts the Resurrection
in hand, and fire with the crosshair over a fallen ally's body, up to 12 m away, brings them back
where they lie. Their body rises in a shell of crystal for 2 s, out of harm's way, and they burst
out at its top with full health and no shield, then fall to the floor for 1.3 s, held and in harm's
way, before they've control back. It costs 7 points. This system adds where the fallen lie (a body
for everyone who's killed, on the floor under where they fell), which body the crosshair's over,
judged on the server as the screen showed it, the return in the shared simulation, a new life that
starts out of play and rises with the body, who can be brought back in each mode, the kill feed's
line for it, and how it looks and sounds.

As before, everything comes from public sources: five of Riot's patch notes and, for what Riot
doesn't give, the VALORANT Wiki's pages on the Resurrection and on Sage, and guides by esports.net,
GamerJournalist, Player Assist and esports.gg. No game files, memory or network traffic were used,
and nothing was read from the live game. Here the wiki's numbers are labelled community, though it
says some of them come from the game files, and so are the guides'. Riot gives the cost, the reach,
that a revived agent breaks a wall of ice they'd come back inside, and that the kill feed shows a
revive; the wiki gives the equip and unequip times, the rise and the fall, and what they come back
with; where a body lies, how wide the crosshair's aim is, and how high the body rises are ours.
Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop; esports.net; GamerJournalist; Player Assist; esports.gg) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source gives how a body lies, how close to it the crosshair must be, how high it rises, whether
Sage can move as she casts it, whether her death stops a return under way, or whether whoever's
brought back keeps their abilities and ultimate points. Ours are in section 4. The cast is instant,
as the wiki has it, so she moves freely once it's cast; a return carries on if she falls; and the
one brought back keeps their kit as it was.

## 1. Observable behaviour

- **In hand** (the wiki). "EQUIP a resurrection ability. FIRE with your crosshairs placed over a
  dead ally to begin resurrecting them." It's ready 0.8 s after X (its equip time, from the game
  files, it says), and the gun is back 1 s after the cast (its unequip time, the same). It costs 7
  points, since Patch 9.10 cut it from 8.
- **Its reach** (Patch 11.04). "Sage resurrection range has increased from 6m >>> 12m".
  GamerJournalist: "You need to be close to the body to resurrect them."
- **The return** (the wiki and esports.net). "After a brief channel, the ally will be brought back
  to life with full health." "The target's body will begin to rise up encased in radianite crystals,
  making them immune to incoming damage." "The target will then burst out with full HP (excluding
  shields)," "falling down to ground for a brief duration before regaining control of their
  character," "during which time they can be damaged." Its windup is 2 s and its revive 1.3 s (the
  wiki, from the game files, it says); esports.net has "3.3s total animation, 2s invulnerability,
  and 1.3s vulnerability for the revived player".
- **What they come back with** (GamerJournalist). "The revived person has full HP with no armor, and
  the weapon they die with assuming you didn't steal it."
- **A wall of ice** (Patch 3.0). "Characters blocked by Sage’s Barrier Orb when resurrected now
  break the wall to ensure they don’t get pushed inside map geo".
- **The kill feed** (Patch 3.0). "The killfeed will display certain ultimate abilities when players
  on either team are killed in a second-life state or revived"; "For example: Sage’s player
  resurrection or Phoenix’s death during his Run It Back ability."
- **Bodies** (Player Assist and esports.gg). A setting swaps the bodies for discs: "Turning this
  option ON/OFF will alter corpse representation in-game from dead bodies to discs", and the discs
  glow, blue for allies and red for enemies, in our words. "Sage can interact with her teammates'
  dead bodies to bring them back to life." When a bug hid bodies, "Without any available target,
  Sage players cannot resurrect their teammates."

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Ultimate points required increased 7 >>> 8"; "Characters blocked by Sage’s Barrier Orb when resurrected now break the wall to ensure they don’t get pushed inside map geo"; "The killfeed will display certain ultimate abilities when players on either team are killed in a second-life state or revived" | [VALORANT Patch Notes 3.0](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-3-0/), 22 June 2021 |
| Resurrection "Ult Cost 8 >>> 7" | [VALORANT Patch Notes 9.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-10), 19 November 2024 |
| "Sage resurrection range has increased from 6m >>> 12m" | [VALORANT Patch Notes 11.04](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-04/), 19 August 2025 |
| "Fixed an issue where Sage's Resurrection indicator was snapping to allies out of Sage's POV." | [VALORANT Patch Notes 11.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-10/), 11 November 2025 |
| "Fixed an issue where players revived by Sage inside Viper's Pit or Poison Cloud would not correctly receive the nearsighted debuff." | [VALORANT Patch Notes 13.01](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-13-01/), 14 July 2026 |

### From the community

| What | Source |
| --- | --- |
| "EQUIP a resurrection ability. FIRE with your crosshairs placed over a dead ally to begin resurrecting them." "After a brief channel, the ally will be brought back to life with full health." | [VALORANT Wiki, Resurrection](https://wiki.playvalorant.com/en-us/Resurrection) (Weird Gloop) |
| 7 points; weapon reequip speed fast; equip 0.8 s, windup 2 s, unequip 1 s and revive 1.3 s (from the game files, it says); a reach of 12 m (Patch 11.04); in our words, its crosshair goes on an ally's body to cast it at once; "The target's body will begin to rise up encased in radianite crystals, making them immune to incoming damage." "The target will then burst out with full HP (excluding shields)," "falling down to ground for a brief duration before regaining control of their character," "during which time they can be damaged." | The same |
| History: 10.05, "Fixed an issue where there was a single frame of vulnerability upon reviving a target"; 9.01, "Fixed an issue regarding resurrection not being visible for Spectators and Observers."; 8.04, "Fixed a bug where if you were revived by Sage's Resurrection, you would be nudged slightly at the end of the animation." | The same |
| Resurrection, 7 points, duration "3.3 s" | [VALORANT Wiki, Sage](https://wiki.playvalorant.com/en-us/Sage) |
| "3.3s total animation, 2s invulnerability, and 1.3s vulnerability for the revived player"; "Sage is a vulnerable target while casting her ultimate"; "your teammate is vulnerable for a brief moment after being resurrected" | [esports.net, Sage guide](https://www.esports.net/wiki/guides/valorant-sage-guide) |
| "Target a teammate's corpse and revive them after a short delay." "You need to be close to the body to resurrect them." "The revived person has full HP with no armor, and the weapon they die with assuming you didn't steal it." | [GamerJournalist, Sage guide](https://gamerjournalist.com/valorant-sage-guide) |
| "turning the option OFF will swap out the dead bodies for colored discs that show the face of your dead teammate"; "Sage can interact with her teammates' dead bodies to bring them back to life." | [Player Assist, how to see dead bodies](https://playerassist.com/valorant-how-to-see-dead-bodies/) |
| "Without any available target, Sage players cannot resurrect their teammates." | [esports.gg, the corpse bug](https://esports.gg/news/valorant/valorant-corpse-bug/) |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How a body lies | Clips of agents falling beside a spike site's boxes, stepped to where the body's still |
| How close the crosshair must be | A custom game with a second player: aim beside, above and past a body at known distances, and note when the indicator shows |
| How high the body rises | Clips stepped from the cast to the burst, beside boxes of known height |
| The fall | Clips stepped from the burst to the first step, and where they land against where the body lay |
| What they keep | A custom game: spend some charges and points, fall, be brought back, and read the ability bar |
| If Sage falls | A custom game: kill her during the rise, and watch the return |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Its points | 7. On the course every life starts with them full, and they fill again 1.5 s after they're spent; elsewhere they come as any ultimate's do (system 19); in Team Deathmatch it costs 50 | Confirmed (7, Patch 9.10); community (50) |
| In hand | X with its points full puts the orb in the fifth slot, ready 0.8 s later, as the Healing Orb's is (system 36); a number key puts it away, with nothing spent. With it you run at the knife's speed | Community (0.8 s); estimate (the speed) |
| Who it brings back | In Skirmish and the spike rounds, a fallen ally of your own side while the round's played (live, or with the spike planted). On the course, with no sides, the practice dummies, so it can be tried alone. Elsewhere nobody, as everyone comes back by themselves | Community (allies: the wiki); estimate (the course; elsewhere) |
| Where the fallen lie | Whoever's killed leaves a body on the floor under where they fell, looked for up to 50 m below; with no floor, none. It lies along the way they faced, its middle where they stood, head ahead: 1.75 m long, as tall as they stood, their head, body and legs laid down. It's there until they're back, by a new life or a return, and every body goes with a new round | Community (bodies: Player Assist; no target without one: esports.gg); estimate (the rest) |
| The aim | Fire's on the first body along the crosshair that it passes within 0.5 m of a line along it, 0.14 m off the floor, within 12 m of the eye, of those it can bring back, with any of its three blocks' middles in sight past the level, clouds and walls of fire and of ice. The server judges each try as the screen showed it | Confirmed (12 m, Patch 11.04); community (the crosshair over the body: the wiki); estimate (0.5 m, the line, sight) |
| The cast | At once: the points are spent, the orb's put away, and the gun's back 1 s later; Sage moves as she likes. A try with nobody to bring back leaves it in hand, a try each click, ten a second at most | Community (1 s; at once: the wiki); estimate (the tries) |
| The rise | From the server's time at the cast, the body rises 0.5 m over 2 s in a shell of crystal. A player's new life starts at once, out of play: nothing shows them or hits them, and they rise with the body, unable to move, jump or shoot | Community (2 s, immune: the wiki, esports.net); estimate (0.5 m) |
| The burst | 2 s after the cast they're back in play at the top, facing the way they faced as they fell, with full health and no shield; the kind of shield they wore stays theirs for later lives | Community (full HP excluding shields: the wiki; no armour: GamerJournalist) |
| A wall of ice | Any segment they'd come back inside, from the floor to their height over the top, breaks as they burst out | Confirmed (Patch 3.0) |
| The fall | 1.3 s, falling to the floor, held, unable to move, jump or shoot, and in harm's way; then control's back | Community (1.3 s, in harm's way: the wiki, esports.net) |
| What they keep | Their kit as it was when they fell. In the spike rounds the gun they dropped lies by their body, and walking over it picks it up | Community (the weapon: GamerJournalist); estimate (the kit) |
| If Sage falls | The return carries on | Estimate |
| A practice dummy | Kept down while anyone has the orb in hand; brought back where its body lay, held as it falls | Estimate |
| A new round | Every body and return gone | Estimate |
| The kill feed | Everyone's: the one who cast it, `Resurrection` in teal, and the one brought back | Confirmed (Patch 3.0) |
| Its look | The orb in hand a small teal ball with three shards of crystal over an open hand; a body its owner's colours darkened, over a disc on the floor 1.6 m across, glowing blue for your side's and red for anyone else's; with the orb in hand a green box round each of the blocks of the body it would bring back and a green + over it; the shell pale crystal round the body as it rises, bursting in ten chips that fall and fade | Community (the discs' colours: Player Assist); estimate (ours) |
| Its sounds | A gust as the orb comes up in hand; a deep chime from the body as the return starts; a sharp crack as they burst out, each heard as far as an ability | Estimate (ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** adds `Resurrection` (the unequip, the reach and width, the rise and fall, and
  the height), each with its status and source; the Resurrection's def gains its weapon and its line
  on her card.
- **`WeaponConfig`** adds `revive`, the orb in hand, 30th of the weapons' wire ids.
- **`AbilitySim`** plays the Resurrection as it plays the Healing Orb: X with the points full puts
  it in hand, and fire with it is a `revive` try. `used` spends the points. A kit carries when the
  return it's on lets go (`floatUntil` and `heldUntil`, on the ack); `reviving` and `floating` say
  whether it's under way, and `VFKit` ends in `revived` meanwhile.
- **`ReviveSim`** is new: where a body lies and its blocks, the line along it, which body a try from
  an eye brings back (`aimedAt`, given what hides a line), and the return's times (`burstAt`,
  `backAt`, `risen`).
- **`PlayerSim`** runs a revived tick: while floating, the player rises with the body, held; then
  they fall as the movement does, with no buttons; the gun's stowed until `heldUntil`.
- **`MatchRules`** and **`ArenaRules`** add `canRevive` (both there, the reviver alive, the other
  down, the same side, the round played) and `revived`, which counts them alive again.

### The server

- **`ReviveServer`** is new. Each kill lays a body: an invisible part in `Workspace.VFBodies` named
  by the entity id, its CFrame where they lie, which every client draws. Each `revive` try is judged
  from the reviver's input as their screen showed it: the bodies they could bring back (`canRevive`,
  the arena's hook; the dummies on the course), the crosshair, and sight past the level, clouds,
  walls of fire and walls of ice. A try that brings someone back spends the points, puts the orb
  away and tells those who'd hear it (the fog of war's way); the body's part carries `VFReviver` and
  `VFReviveAt`. Each frame it bursts the returns that are due, breaks any wall of ice in their way,
  tells the rules (`reviveListeners`), the kill feed and those who'd hear, and removes the body; it
  removes bodies whose owners are back or gone, and keeps a dummy down while it's awaited.
- **`PlayerSimServer.revive`** asks for the player's new life where their body lies, out of play: it
  rises from there with the body, keeps the kit, and carries the float and hold in the character's
  `VFRevived` attribute, which the client reads. The new life starts with full health and no shield
  (`ReviveSim.UNSHIELDED`).
- **`Dummies`** keeps a fallen dummy down past its respawn (`keepDown`, `release`) and brings it
  back where its body lies, held as it falls (`revive`).
- **`BarrierServer.breakIn`** breaks the segments a box is in, for the one coming back.
- **`Arena`** says who can be brought back in each mode, counts them alive again, and clears every
  body with each round.

### The client

- **`ReviveView`** is new: the bodies drawn from the server's parts, their discs, the mark on the
  body your try would bring back (the same test as the server's, on what you see), the shell rising
  as the frame on your screen reaches it, and its chips as they burst out. Your own return isn't
  drawn round you: you rise with it.
- **`PlayerController`** reads `VFRevived` as the new life starts, so its own prediction floats and
  holds as the server's does.
- **`KillFeed`** shows a return, and **`WeaponLooks`**, **`SoundConfig`** and **`AbilityEffects`**
  give the orb in hand its look and sounds and leave the return's to `ReviveView`.

### Not here yet

- **Viper.** Patch 13.01's nearsight for the revived in Viper's Pit or Poison Cloud: there's no
  Viper yet.
- **A second life's death.** Patch 3.0's kill feed also marks a death in Run it Back's second life
  (system 37); ours doesn't yet.
- **A body's look.** Bodies are boxes laid down, not the agent's model, and the discs have no face.
- **Team Deathmatch.** It can be readied there, at 50 points, but nobody's brought back, since
  everyone comes back by themselves.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | `Resurrection`'s numbers, each with its status and source; the Resurrection's weapon and line; `unequip` |
| `src/shared/Weapons/WeaponConfig.luau` | `revive`, the orb in hand, and its wire id |
| `src/shared/Abilities/AbilitySim.luau` | The Resurrection played, its `revive` try, the points spent, and the return's float and hold |
| `src/shared/Abilities/ReviveSim.luau` | New: where a body lies, the aim along it, and the return's times |
| `src/shared/Abilities/HealSim.luau` | `closest`, shared with the aim |
| `src/shared/PlayerSim.luau` | A revived tick: risen, held, then falling held |
| `src/shared/Net/PlayerCodec.luau` | The float and hold in the ack |
| `src/shared/CharacterRig.luau` | `VFRevived` |
| `src/shared/Match/MatchRules.luau`, `src/shared/Arena/ArenaRules.luau` | Who can be brought back, and counted alive again |
| `src/shared/Audio/SoundConfig.luau` | The orb's draw, the chime and the burst |
| `src/server/ReviveServer.luau` | New: bodies laid, tries judged, returns burst, rules told; `VFLastRevive` |
| `src/server/PlayerSimServer.luau` | A new life where the body lies, out of play, rising with it; in Studio, the ultimate's points filled on request |
| `src/server/Dummies.luau` | A dummy kept down and brought back |
| `src/server/BarrierServer.luau` | Segments broken where someone's coming back |
| `src/server/Arena.luau`, `src/server/init.server.luau` | Who can be brought back in each mode; bodies cleared with each round; `ReviveServer` started and stepped |
| `src/client/ReviveView.luau` | New: bodies, discs, the mark, the shell, the chips and the sounds |
| `src/client/PlayerController.luau` | The new life's float and hold, predicted |
| `src/client/KillFeed.luau` | A return in the kill feed |
| `src/client/Debug/TestAim.luau` | `VFTestGive` `ultimate` |
| `src/client/Combat/WeaponLooks.luau`, `src/client/AbilityEffects.luau`, `src/client/init.client.luau` | The orb in hand; the return left to `ReviveView`; the view started |
| `tests/resurrection.luau` | New: its numbers, the orb in hand, the points, bodies and the aim, the return's times and hold, the rules and the wire |
| `tests/healingorb.luau`, `tests/arsenal.luau` | Sage's kit with the Resurrection played, and the weapons' ids |

## 7. Debug tools

- `Workspace.VFBodies` holds an invisible part for each body, named by its owner's entity id, with
  `VFReviver` (the caster's entity id) and `VFReviveAt` (the server time of the cast) while a
  return's under way. `Workspace.VFBodyViews` holds the drawn ones, a `VFBody<id>` model each.
- A player's `VFLastRevive` is the name of the one they last brought back.
- `VFKit` reads `X7/7` with the points full, ends in `equip` while the orb's in hand, and in
  `revived` while you're coming back.
- `VFTestButtons` 32768 presses X and 128 the left button, so the orb can be readied and tried
  without a key or a mouse button; `VFTestYaw` and `VFTestPitch` aim.
- In Studio, `VFTestGive` `ultimate` fills the ultimate's points, so it can be checked in Skirmish
  and the spike rounds without earning them.

## 8. Refinement loop

1. Step through clips of bodies beside boxes, and set how a body lies.
2. In a custom game, aim round a body at known distances, and set `width`.
3. Step through clips of returns beside boxes, and set `height`.
4. Spend some of a kit, fall and be brought back, and set what's kept.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The Resurrection lit on Sage's card and the bar, `X7/7` on the course, and in hand 0.8 s after X.
- A body where a dummy falls, kept down while the orb's in hand, and the mark on it within reach and
  nowhere else.
- The return: the chime, the body rising 0.5 m in its shell over 2 s, the crack and the chips, the
  dummy back where it lay and falling to the floor, the kill feed's line, the points spent and
  refilled, and the gun back 1 s after.
- Brought back with no shield: fewer shots to fell it again.
- A wall of ice where it comes back breaking.
- An ally in Skirmish: rising with the body, held as they fall, hurt only once they've burst out,
  with their kit kept; an enemy's body never marked.

Section 43 of the [Studio checklist](../studio-checklist.md) covers these.
