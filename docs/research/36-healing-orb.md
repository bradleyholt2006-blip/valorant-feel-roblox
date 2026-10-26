# System 36: Sage's Healing Orb

Sage joins Jett and Phoenix in agent select, a Sentinel with her whole kit on the bar, and her
Healing Orb, her signature, is the first of it played. E puts the orb in hand. With the crosshair
over a hurt ally, fire heals them, and alt fire heals Sage herself if she's hurt: 100 health over
5 s either way. A heal spends the orb's one charge, which comes back 45 s later. This system adds
Sage, the orb in hand and its tries, the server's judgement of whom a try heals, the heal itself,
and how it's marked, drawn and heard. It also lets an ability recharge on a cooldown of its own
outside Team Deathmatch.

As before, everything comes from public sources: five of Riot's patch notes (Patch 5.12's as
Liquipedia copies them) and, for what Riot doesn't give, the VALORANT Wiki's pages on the Healing
Orb, Sage, Team Deathmatch and health. No game files, memory or network traffic were used, and
nothing was read from the live game. Here the wiki's numbers are labelled community. Riot gives the
heals, their time and the cooldown; how near the crosshair has to be, how far it reaches and how
long a pause lasts are ours. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **In hand** (the wiki). "EQUIP a healing orb." It's ready 0.5 s after E (its equip time), and the
  gun is back 0.7 s after a heal (its unequip time). It has one use, free, and a 45 s cooldown; in
  Team Deathmatch the cooldown is 22 s.
- **An ally** (the wiki and Patch 5.12). "FIRE with your crosshairs over a damaged ally to activate
  a Heal-Over-Time on them." "To target an ally, they must be in Sage's line of sight." It heals 100
  in all, 20 a second for 5 s. Patch 5.12 raised it from 60, hoping "the heal update will push her
  power and satisfaction when fully healing others".
- **Herself** (the wiki and the patch notes). "ALT FIRE while Sage is damaged to activate a self
  Heal-Over-Time." It was 60 over 10 s from 1.07 (the wiki's history), 30 from Patch 5.12, "creating
  tradeoffs for playing Sage overly aggressive and relying on self-healing", 50 from Patch 9.10,
  which "matched" its time "to ally heal at around 5 seconds", and 100 from Patch 13.00. Both heals
  are back where they began, 100 over 5 s.
- **Paused** (the wiki). "The healing effect is briefly paused if the target takes damage."
- **Health alone** (the wiki's page on health). "Agents are the only entities that can replenish any
  health that they have lost during play by healing", and "healing can only be received from
  abilities". Nothing says a heal brings a shield back.
- **Its cooldown** (Patch 1.0). "Healing Orb cooldown increased 35 >>> 45 seconds": "We like how
  much Sage is able to heal in a single heal, but felt she was able to use it too frequently during
  a round."
- **Its targeting** (the wiki's history). 12.00 "Updated targeting"; 12.01 fixed the targeting UI
  showing on allies who'd broken line of sight; 12.05 added "a new widget above the targeted allies
  head" and "an additional highlight around the agent's model"; 12.11 "Fixed a bug where it was not
  usable during the buy phase."
- **Sage** (Patch 1.01 and the wiki). "As a Sentinel, Sage is supposed to be most effective when
  defending territory that she already controls." Her kit: Barrier Orb (C, 300 credits, one), Slow
  Orb (Q, 200, two), the Healing Orb (E, free, one) and Resurrection (X, 7 points since Patch 9.10's
  "Ult Cost 8 >>> 7"), with no passive.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Healing Orb cooldown increased 35 >>> 45 seconds"; "We like how much Sage is able to heal in a single heal, but felt she was able to use it too frequently during a round." | [VALORANT Patch Notes 1.0](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-1-0/), 1 June 2020 |
| "As a Sentinel, Sage is supposed to be most effective when defending territory that she already controls." | [VALORANT Patch Notes 1.01](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-01/), 9 June 2020 |
| "Self heal total amount decreased 60HP >>> 30HP"; "Ally heal total amount increased 60HP>>> 100HP"; "We're hoping the heal update will push her power and satisfaction when fully healing others" "while creating tradeoffs for playing Sage overly aggressive and relying on self-healing." | VALORANT Patch Notes 5.12, 6 December 2022, as [Liquipedia copies them](https://liquipedia.net/valorant/Patch_5.12) |
| "Self Heal 30HP >>> 50HP"; "Heal time matched to ally heal at around 5 seconds"; Resurrection "Ult Cost 8 >>> 7" | [VALORANT Patch Notes 9.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-10), 19 November 2024 |
| "Self Heal-Over-Time has increased from 50 to 100." | [VALORANT Patch Notes 13.00](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-13-00), 23 June 2026 |

### From the community

| What | Source |
| --- | --- |
| "EQUIP a healing orb. FIRE with your crosshairs over a damaged ally to activate a Heal-Over-Time on them."; "ALT FIRE while Sage is damaged to activate a self Heal-Over-Time." | [VALORANT Wiki, Healing Orb](https://wiki.playvalorant.com/en-us/Healing_Orb) (Weird Gloop) |
| The ally's heal 20 a second, 100 in all; duration 5 seconds; cooldown 45 seconds; 1 use; equip 0.5 seconds; unequip 0.7 seconds | The same |
| "To target an ally, they must be in Sage's line of sight."; "The healing effect is briefly paused if the target takes damage." | The same |
| History: 1.07, "Heal reduced from 100 over 5 seconds >>> 60 over 5 seconds" and "Self heal reduced from 100 over 5 seconds >>> 60 over 10 seconds"; 12.00, "Updated targeting"; 12.01, the targeting UI on allies who'd broken line of sight; 12.05, "Updated Ally Targeting UI/UX with a new widget above the targeted allies head" and "an additional highlight around the agent's model"; 12.11, "Fixed a bug where it was not usable during the buy phase." | The same |
| A Sentinel; Barrier Orb (C), 300 credits, 1 use; Slow Orb (Q), 200 credits, 2 uses; Healing Orb (E), free, 1 use; Resurrection (X), 7 ultimate points; no passive | [VALORANT Wiki, Sage](https://wiki.playvalorant.com/en-us/Sage) |
| Team Deathmatch's cooldowns: Barrier Orb 94 s, Slow Orb 51 s, Healing Orb 22 s; Resurrection 50 points | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) |
| "Agents are the only entities that can replenish any health that they have lost during play by healing."; "healing can only be received from abilities" | [VALORANT Wiki, Health](https://wiki.playvalorant.com/en-us/Health) |

No source says how near the crosshair has to be to an ally, how far away one can be, what blocks the
line of sight (a smoke, a wall of fire, another body), how long "briefly paused" is or whether the
heal's time stops with it, what a try with nobody to heal does, whether a heal goes on if Sage dies,
or how the heal and the widget look and sound. Ours are in section 4. We read "paused" as the heal's
time stopping too, so a hurt ally still gets all of it, and "line of sight" as sight, which clouds
and walls of fire block as the level does (system 34). Both readings are ours. The wiki's 20 a
second over 5 s is the ally's heal; Patch 9.10 matched the self heal's time to it, so Patch 13.00's
100 is 20 a second too.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How near the crosshair has to be | Clips of heals tried at the edge of an ally's body, stepped to the click |
| How far an ally can be | A custom game: heal a teammate down a map's longest sightline, stepping back between tries |
| How long the pause is | Clips of a healed ally hit, their health stepped frame by frame until it climbs again |
| A try with nobody to heal | A custom game: fire with the orb in hand at nobody, at a teammate on full health and at an enemy |
| What blocks the line of sight | A custom game: try through a smoke, a wall of fire and a teammate standing in the way |
| Whether a heal goes on after Sage dies | Clips of a Sage killed just after a heal |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Sage | A Sentinel, with Barrier Orb (C, 300 credits, one charge), Slow Orb (Q, 200, two), the Healing Orb (E, one, free) and Resurrection (X, 7 points; 50 in Team Deathmatch), and no passive. The Healing Orb alone can be played; the rest are on her card, the bar and the buy menu, `NOT YET` | Confirmed (a Sentinel, Patch 1.01; 7 points, Patch 9.10); community (the rest) |
| Its charge | One, free each round, and back 45 s after it's spent, or 22 s in Team Deathmatch; the course fills it 1.5 s after, as it does every ability | Confirmed (45 s, Patch 1.0); community (one, free, 22 s); estimate (the course's) |
| In hand | E puts the orb in hand, ready 0.5 s later, as Curveball's flare is (system 30); E again or a gun drawn puts it away unspent. With it you run at the knife's speed | Community (0.5 s); estimate (the speed) |
| A try | Each click of fire with it ready is a try on the ally the crosshair's over, and each click of alt fire a try on herself; ten a second at most | Community (fire and alt fire); estimate (a click a try, ten a second) |
| Whom fire heals | Of the allies who are hurt, the nearest along the crosshair that it passes within 0.4 m of, anywhere from their feet to the top of their head, within 60 m, and in sight of the eye: any of the three points of them the minimap counts (system 34), with nothing of the level, no cloud and no wall of fire in the way. Bodies don't hide each other | Community (the crosshair over a damaged ally, in line of sight); estimate (0.4 m, 60 m, what blocks sight) |
| As her screen showed | Those allies posed as her screen showed them as she tried, rewound as a shot is (system 4) | Estimate |
| Hurt | Short of the most health, 100, in whole points as the HUD shows it | Community (damaged); estimate (whole points) |
| Nobody to heal | The try does nothing: the orb stays in hand with its charge, and nothing's heard | Estimate |
| A heal | Its charge spent, the orb's put away, and the gun's back 0.7 s after the try | Community (0.7 s) |
| How much | 100 health, on an ally or on herself, over 5 s: 20 a second, given in whole points every 0.1 s, up to the most. No shield | Confirmed (100 each, Patches 5.12 and 13.00; about 5 s, Patch 9.10); community (20 a second, health alone); estimate (every 0.1 s) |
| Hurt while healed | It stops for 1 s from each hurt, its time with it, then gives the rest | Community (paused); estimate (1 s, its time stopping) |
| Over | Once its 5 s have run, its stops left out, whether they're at the most or not; or as they die, come back to a new life or leave, or a round starts. Not as the healer dies | Estimate |
| The buy phase | It can be used in it | Community (12.11's fix) |
| Its mark | With the orb ready, the hurt ally it would heal, as your screen shows them, has a green box round each of their blocks and a green + over their head | Community (a widget over their head and a highlight round them, 12.05); estimate (the look) |
| Its glow | Whoever's healed glows green, for those who heard it start, until it's over; for them, the edge of their screen pulses green | Estimate |
| Its sounds | A quick whoosh as it's put in hand, and a soft bell as a heal starts, from the healer, heard as an ability's cast is, by those near enough or who have the healer (system 35) | Estimate (ours, from free Roblox sounds) |
| The bar | E lit with `EQUIP` under it until it's ready, and while its charge is coming back, the seconds to it | Estimate |

## 5. Design

### The rules

- **`AbilityConfig`** adds Sage: her four abilities with their costs, charges and points, the
  Healing Orb's cooldown as a `recharge` of its own, Team Deathmatch's cooldowns for her and
  Resurrection's points there; and `HealingOrb`, the unequip time, the two heals, their duration,
  the pause, and a try's width and reach, each with its status and source. The Healing Orb is
  playable (`AbilitySim`).
- **`WeaponConfig`** adds `healorb`, the orb in the fifth slot: semi, a try a click, ten a second at
  most, ready 0.5 s after E, its alt fire the try on herself, with no spread or kick.
- **`AbilitySim`**: `thrown` turns a try of the orb into a `heal` or `selfheal` cast and leaves the
  orb in hand with its charge. `used` spends a charge and takes it out of hand; the server calls it
  between ticks.
- **`PlayerSim`** keeps the orb ready in hand after each try.
- **`HealSim`** (new) is whom a try heals (`hurt`, `along` and `aimedAt`) and a heal's run (`new`,
  `step` with its pauses, `take` and `done`), with no Roblox APIs: the level comes in as `hidden`,
  so the tests run it on a fake one.

### The server

- **`HealServer`** (new) judges each try from the viewTime of the input it came in: on the hurt
  allies posed as the healer's screen showed them (`CombatServer.rewound`), through the level
  (`FogServer.blocked`, which sees through the barriers) and the clouds and walls of fire standing
  then (`Sight.hidden`). A try that heals spends the charge (`AbilitySim.used`), puts the orb away
  (`WeaponSim.putAway`, 0.7 s) and marks the player's simulation changed, so the ack takes it to
  their client; then the heal is under way. Each frame it steps every heal, and gives what each owes
  through `CombatServer.mend` at most every 0.1 s, as fires burn (`FireServer.EVERY`). It tells
  those who'd hear the cast (the fog of war's way) as a heal starts (the Ability remote's `healing`)
  and every client as it's over (`healed`), and sets the healer's `VFLastHeal`.
- **`CombatServer`** adds `rewound`: everyone a filter lets through, posed as a viewer's screen
  showed them.
- **`FogServer`** shares `blocked`, its look through the level.
- **`AbilityServer`**: outside Team Deathmatch, an ability with a cooldown of its own recharges on
  it, the bar counting down to it (`VFRecharge`), as Team Deathmatch's do. The orb's tries aren't
  told as casts.
- **`Arena`** ends every heal as a round starts, and **`init.server`** steps the heals after the
  fires, whose burns pause them.

### The client

- **`HealView`** (new) marks the ally a try would heal while the orb's ready: HealSim's test on what
  your screen shows, through the level and the clouds. It plays the chime from the healer as a heal
  starts, yours at once and others' as the frame on your screen reaches them, and draws the glow on
  whoever's healed until it's over: green boxes round their blocks, or for you a green edge round
  your screen.
- **`WeaponLooks`** draws the orb in hand, a green ball over an open hand, and **`SoundConfig`**
  adds `orbEquip` and `healChime`.
- **`RemoteEntities`** adds `modelOf`, the model an entity is drawn as.
- **`AbilityEffects`** leaves heals to `HealView`, and **`AbilityHud`** counts the orb's cooldown
  down as it does Team Deathmatch's.

### Not here yet

- **The rest of her kit.** Barrier Orb, Slow Orb and Resurrection are on her card, the bar and the
  buy menu, `NOT YET`.
- **Walls of fire on the mark.** The mark looks through the level and the clouds but not the walls
  of fire, which the server's judgement does; a mark through a wall of fire can heal nobody.
- **The orb after a heal.** A client can't know whether its try heals, which needs the others'
  health and where they were, so the orb leaves its hand when the server's word comes, a round trip
  after the click.
- **Held fire.** A try needs a click of its own: fire held as the orb comes up tries nothing until
  it's let go and pressed again.
- **The healer's death.** A heal goes on after its healer dies; no source says either way.
- **Two Sages on a side.** The reference's agents are unique on a team, and ours aren't yet (system
  29), so two heals can run on one ally, each giving its own.
- **Late joiners** don't see a glow already under way.
- **Voices.** The reference's Sage calls out as she heals; there are no voices here.
- **The look and the sounds** are ours until clips are stepped through.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | Sage and her kit, the Healing Orb's cooldown, Team Deathmatch's numbers for her, and `HealingOrb`'s numbers, each with its status and source; the Healing Orb playable |
| `src/shared/Weapons/WeaponConfig.luau` | `healorb`, the orb in hand, and its wire id |
| `src/shared/Abilities/AbilitySim.luau` | The `heal` and `selfheal` tries, and `used` |
| `src/shared/PlayerSim.luau` | The orb kept ready in hand after a try |
| `src/shared/Abilities/HealSim.luau` | New: whom a try heals, and a heal's run with its pauses |
| `src/server/HealServer.luau` | New: tries judged, heals started, stepped, given and ended, and clients told |
| `src/server/CombatServer.luau` | `rewound` |
| `src/server/FogServer.luau` | `blocked` shared |
| `src/server/AbilityServer.luau` | An ability's own cooldown outside Team Deathmatch; tries not told as casts |
| `src/server/Arena.luau`, `src/server/init.server.luau` | Heals ended with each round; `HealServer` started and stepped |
| `src/shared/Audio/SoundConfig.luau` | The orb's draw and the heal's chime |
| `src/client/HealView.luau` | New: the mark, the chime and the glows |
| `src/client/Combat/WeaponLooks.luau`, `src/client/RemoteEntities.luau` | The orb in hand; `modelOf` |
| `src/client/AbilityEffects.luau`, `src/client/AbilityHud.luau`, `src/client/init.client.luau` | Heals left to `HealView`, the countdown, the view started |
| `tests/healingorb.luau` | New: its numbers, Sage, the kit, the orb in hand and its tries, whom a try heals, the heal and its pauses, and the wire |

## 7. Debug tools

- The healer's `VFLastHeal` is the name of the player they last healed.
- `VFKit` ends in `equip` while the orb's in hand, as `C0/1 Q0/2 E1/1 X0/7 equip`.
- `VFRecharge` is when each of C, Q and E next has a charge back, in server time (0 for none
  coming), which the bar counts down to.
- `VFTestButtons` 16384 presses E, 128 the left button and 256 the right. `VFTestAimEntity` and
  `VFTestAimRegion` put the crosshair on someone, as for a shot.
- The ScreenGui `VFHealFx` is the green edge while you're healed; each block of a marked or glowing
  player has a `VFHeal` box, and a marked player's head the `VFHealMark` +.

## 8. Refinement loop

1. Step through clips of heals tried at the edge of a body, and set `width`.
2. Heal down a long sightline in a custom game, and set `reach`.
3. Step through clips of a healed ally hit, and set `pause`.
4. Settle what a try with nobody to heal does, and whether a heal goes on after Sage dies.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Sage's card in agent select, the Healing Orb alone lit, and her kit on the bar and in the buy
  menu.
- E puts the orb in hand in 0.5 s, `EQUIP` on the bar; a try with nobody to heal leaves it there; E
  again or a number key puts it away.
- Alt fire with Sage hurt: the chime, the orb away, the gun back 0.7 s later, 20 health a second for
  5 s up to the most, no shield, and the green edge.
- A hit while healed pausing the heal, which still gives 100 in all.
- An enemy not healed, nor marked.
- A third player: the hurt ally marked under the crosshair, not behind cover or on full health; a
  heal on them, their glow and their green edge; `VFLastHeal`; the 45 s countdown.
- Team Deathmatch's 22 s.

Section 40 of the [Studio checklist](../studio-checklist.md) covers these.
