# System 73: Reyna's Devour and Dismiss

Reyna joins Jett, Phoenix, Sage, Omen and Sova in agent select, a Duelist, the sixth agent, and her
Soul Orb abilities are the first of her kit played. An enemy she kills, or one who dies within 3 s
of her last hurting them, whoever finished them, leaves her a Soul Orb where they fell, for 3 s.
With one in reach, Q (Devour) takes it and heals her 50 over 2 s, past full health up to 150, the
part past 100 lasting 10 s; E (Dismiss) takes it instead, and for 1.5 s nothing hurts her and she
runs at up to 12 m/s, but she can't fire or cast. This system adds Reyna, her orbs, who earns one
and which is in reach, the two casts, the overheal and the intangibility they need, how others see
her Dismiss, how bots play her, and how Basic Training copes with a kit it can't fully play yet.

As before, everything comes from public sources: Riot's patch notes 2.03, 8.11, 11.11, 12.02
and 13.01, Liquipedia's page on Reyna, and two guides, PC Gamer's and esports.net's. No game files,
memory or network traffic were used, nothing was read from the live game, and no Riot asset or sound
is used. Riot gives the orbs' time, the damage window, the charges and their price, the heal, its
time and how long its overheal lasts, Dismiss's time and top speed, and Empress's points. The guides
give the overheal's cap and that she can't shoot or cast through Dismiss. How near an orb has to be,
how it looks, and how intangibility is judged are ours. Nothing in this system is measured yet.
Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (Liquipedia, PC Gamer, esports.net) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **Soul Orbs** (Liquipedia, Patches 2.03 and 12.02). "Enemies killed by Reyna leave behind Soul
  Orbs that last 3 seconds." Since Patch 2.03, "Slain enemies that Reyna has damaged in the last 3
  seconds now drop Soul Orbs, even if Reyna does not land the killing shot", meant to "reduce the
  animosity when an ally lands the final blow and Reyna goes empty handed." Patch 12.02 brought
  their time down from 4 s to 3 s: "The ability description had incorrectly listed the duration
  at 3s while they were lasting 4s."
- **Devour** (Liquipedia, Patches 8.11 and 12.02, PC Gamer). "Instantly consume a nearby soul orb,
  rapidly healing for a short duration." Patch 8.11 halved the heal, "Healing decreased 100 >>> 50",
  and quickened it, "Full heal time reduced from 3s >>> 2s", as "Healing has proven very strong
  statistically in Ranked". PC Gamer: "The ability can also overheal Reyna, though her maximum
  health can't exceed 150." Patch 8.11 made the overheal last ("Overheal of armor no longer decays
  after a timer"); Patch 12.02 made it temporary again: "Overheal applied by Devour is now temporary
  and lasts 10s".
- **Dismiss** (Liquipedia, Patch 8.11, PC Gamer, esports.net). "Instantly consume a nearby Soul Orb,
  becoming instangible for a short duration." PC Gamer: "Casting Dismiss instantly makes Reyna an
  intangible phantom immune to damage for a few seconds", and "Reyna is also faster during this
  time, but she cannot use any weapons or other abilities." esports.net has her "slightly visible
  and intangible" and "immune to both bullet damage and abilities." Patch 8.11 made it shorter and
  faster: "Top speed increased 9.1 meters/second >>> 12 meters/second" and "Total duration of
  Dismiss reduced from 2s >>> 1.5s".
- **In sight** (PC Gamer, esports.net). Both guides had Devour's heal work only while she could see
  the orb: "The healing will only work while Reyna remains in line-of-sight of the Soul Orb", and
  "heal Reyna a flat 100 points over time when in vision." Both give the heal as 100, so both come
  from before Patch 8.11, which removed "the time restrictions on her Devour (Q) and Empress (X)".
- **The charges** (Patch 2.03). "Maximum Devour(Q) and Dismiss(E) charges reduced 4 >>> 2" and "Cost
  of Devour and Dismiss charges increased 100 >>> 200".
- **Her prompts** (Patch 11.11). A fix for "Reyna's HUD UI prompts for Devour and Dismiss" that
  lingered "even if Reyna has no ability charges": the prompts show only with a charge to cast.
- **Her kit** (Liquipedia, Patch 12.02). Leer (C), "Equip an ethereal, destructible eye. Activate to
  cast the eye a short distance forward." and "The eye will nearsight all enemies who look at
  it.", 250 credits, two charges; Devour (Q) and Dismiss (E), 200 credits and two charges each; and
  Empress (X), now "Ult points increased 6 >> 7". PC Gamer's guide calls her "the new Duelist" in
  its title.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Maximum Devour(Q) and Dismiss(E) charges reduced 4 >>> 2"; "Slain enemies that Reyna has damaged in the last 3 seconds now drop Soul Orbs, even if Reyna does not land the killing shot"; "Cost of Devour and Dismiss charges increased 100 >>> 200"; "Reyna getting Soul Orbs from recently damaged enemies should help her reliability when playing around teammates," "and reduce the animosity when an ally lands the final blow and Reyna goes empty handed." | [VALORANT Patch Notes 2.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-2-03/), 17 February 2021 |
| Devour: "Healing decreased 100 >>> 50", "Full heal time reduced from 3s >>> 2s", "Overheal of armor no longer decays after a timer."; Dismiss: "Top speed increased 9.1 meters/second >>> 12 meters/second", "Total duration of Dismiss reduced from 2s >>> 1.5s"; "Healing has proven very strong statistically in Ranked with higher impact at low and mid ranks."; "Dismiss (E) has been re-tuned to provide a greater movement speed boost, but has a shorter duration." | [VALORANT Patch Notes 8.11](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-811/), 11 June 2024 |
| "Fixed a bug where Reyna's HUD UI prompts for Devour and Dismiss would linger on screen even if Reyna has no ability charges" (the line goes on); "Fixed a bug where Reyna's overheal health was not being displayed accurately on the HUD for spectators" | [VALORANT Patch Notes 11.11](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-11/), 2 December 2025 |
| Soul Orbs: "Duration in world decreased from 4s >> 3s"; "The ability description had incorrectly listed the duration at 3s while they were lasting 4s."; Devour: "Overheal applied by Devour is now temporary and lasts 10s", "Healing applied while in Empress is still permanent"; Empress: "Ult points increased 6 >> 7"; "We're looking to increase proactive requirements on Reyna after she gets a kill to encourage continued aggression." | [VALORANT Patch Notes 12.02](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-12-02/), 3 February 2026 |
| "Fixed an issue where Dismiss could occasionally leave Reyna unable to equip a weapon." | [VALORANT Patch Notes 13.01](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-13-01/), 14 July 2026 |

No later notes searched change her numbers.

### From the community

| What | Source |
| --- | --- |
| Leer: "Equip an ethereal, destructible eye. Activate to cast the eye a short distance forward." "The eye will nearsight all enemies who look at it."; 250 credits, Max Charges 2 (200 to 250 in 3.0) | [Liquipedia, Reyna](https://liquipedia.net/valorant/Reyna) |
| Devour: "Enemies killed by Reyna leave behind Soul Orbs that last 3 seconds." "Instantly consume a nearby soul orb, rapidly healing for a short duration." "Health gained through this skill exceeding 100 will decay over time."; 200 credits, Max Charges 2 | The same |
| Dismiss: "Instantly consume a nearby Soul Orb, becoming instangible for a short duration." "If Empress is active, also become invisible."; 200 credits, Max Charges 2; 2.06, "Fixed Reyna taking decay damage while intangible." | The same |
| Empress: Ultimate Cost 6 (before Patch 12.02); "Instantly enter a frenzy, increasing firing, equip and reload speed by 25%." | The same |
| "Of her three main abilities, two require absorbing a Soul Orb from eliminated opponents."; "The ability can also overheal Reyna, though her maximum health can't exceed 150."; "The healing will only work while Reyna remains in line-of-sight of the Soul Orb."; "Casting Dismiss instantly makes Reyna an intangible phantom immune to damage for a few seconds."; "Reyna is also faster during this time, but she cannot use any weapons or other abilities." | [PC Gamer, Valorant Reyna abilities guide: How to get the most from the new Duelist](https://www.pcgamer.com/valorant-reyna-abilities-skills/) |
| "Using devour on a soul orb will heal Reyna a flat 100 points over time when in vision."; "Once Reyna's health exceeds 100, the additional points will be converted up until 50 decayable armor."; "Using dismiss on a soul orb will turn Reyna to be slightly visible and intangible" "where she is immune to both bullet damage and abilities." | [esports.net, Valorant Reyna Guide](https://www.esports.net/news/valorant-reyna-guide-how-to-play-reyna-like-a-pro/) |

No source says how near an orb has to be ("nearby"), whether she must look at it, who else sees it,
how high it floats or how it looks, whether the overheal is health or a shield of its own
(Patch 8.11 says "armor", Patch 11.11 "overheal health", esports.net "decayable armor" up to 50),
when its 10 s start or whether it fades or drops, whether Devour and Dismiss share charges, what
still hurts her in Dismiss, how fast she gets to 12 m/s, how she looks to others in it without
Empress, or Team Deathmatch's cooldowns for her. Ours are in section 4. We read the overheal as
health past 100, as PC Gamer's cap has it, and Patch 12.02's 10 s as running from the heal's last
point. Both readings are ours.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How near an orb has to be, and whether she must see it | A custom game: kill a bot, then back away from its orb and step behind cover, trying Devour each time |
| When the overheal goes, and how | Clips of a full-health Devour, stepped frame by frame from the cast until the health falls back to 100 |
| How fast she gets to 12 m/s | Clips of a Dismiss along a wall's tiles, stepped frame by frame |
| What still hurts her in Dismiss | A custom game: Dismiss into a fire, a shock dart and the spike's blast |
| How she looks to others in it | Clips from an enemy's view of a Dismiss |
| How high an orb floats, and its size | Clips of an orb beside a body that fell |
| Team Deathmatch's cooldowns for Devour and Dismiss | A Team Deathmatch match, timing each charge's return from its cast |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Reyna | A Duelist, with Leer (C, 250 credits, two charges), Devour (Q, 200, two), Dismiss (E, 200, two) and Empress (X, 7 points), and no passive. Devour and Dismiss can be played; Leer and Empress are on her card, the bar and the buy menu, `NOT YET` | Confirmed (Devour and Dismiss's costs and charges, Patch 2.03; 7 points, Patch 12.02); community (Leer's, Liquipedia; a Duelist, PC Gamer) |
| The charges | Each its own, bought, none free each round; on the course they fill as every ability's do; in Team Deathmatch each comes back 40 s after it's spent | Confirmed (bought, two each, Patch 2.03); estimate (their own; 40 s) |
| An orb | An enemy she kills, or who dies within 3 s of her last hurting them, by anyone or anything, leaves her one at their feet where they fell, if she's alive and the mode plays abilities; it lasts 3 s. Dummies on the course leave them too | Confirmed (3 s, Patch 12.02; 3 s of her damage, Patch 2.03); estimate (at their feet, alive, dummies) |
| Hers alone | Only she sees her orbs and only she can take them | Estimate |
| Its look | A purple ball 0.35 m across, 1 m over where they fell, pulsing; 0.45 m and brighter while it's the one in reach; fading over its last 0.6 s | Estimate |
| In reach | Its middle within 15 m of her eye, with nothing of the level between; of those, the nearest, and of two as near, the lower number. Her client picks from the same numbers as the server, to the centimetre and the millisecond | Community ("nearby", Liquipedia; in sight, PC Gamer); estimate (15 m, 1 m up, the tie) |
| The prompt | With one in reach, the keys for those with a charge, under the crosshair, named as the input in use has them (`Q DEVOUR    E DISMISS`); none through her Dismiss | Confirmed (only with charges, Patch 11.11); estimate (the look) |
| Devour | Q with one in reach and a charge takes it and spends the charge; the gun stays in hand. It heals 50 over 2 s, 25 a second, given in whole points every 0.1 s, past 100 up to 150. Nothing pauses it, and losing sight of the orb's spot doesn't stop it | Confirmed (50 over 2 s, Patch 8.11); community (150, PC Gamer); estimate (whole points every 0.1 s, nothing stopping it) |
| The overheal | Health past 100, hit off as health is (a shield still takes its share first); a mend or a health pack doesn't take it away. It goes at once 10 s after the last point of her last heal, unless another's under way | Confirmed (temporary, 10 s, Patch 12.02); estimate (health; at once; from the last point) |
| Dismiss | E with one in reach and a charge takes it and spends the charge. For 1.5 s nothing anyone does hurts her (shots go through her), though harm with nobody behind it, the spike's blast, still does; her top speed's 12 m/s whatever's in hand; her gun's put away, and she can't fire, cast, plant or defuse. As it ends, her top speed's the run speed's and her gun's drawn again | Confirmed (1.5 s, 12 m/s, Patch 8.11); community (intangible, Liquipedia; immune to damage, faster, no weapons or abilities, PC Gamer and esports.net); estimate (what still hurts, the gun drawn) |
| Judged | Intangible on the server from the cast until it ends in her simulation, and never past 1.5 s on the server's clock, however her moves come in | Estimate |
| Others' view | Others see her dark and see-through for its time, from the frame on their screen it started | Community ("slightly visible", esports.net; a "phantom", PC Gamer); estimate (the look) |
| Q and E together | One orb is taken once, by Devour | Estimate |
| Q or E without an orb or a charge | Nothing, and nothing's heard | Estimate |
| Its sounds | Devour the Healing Orb's soft bell, Dismiss a fizzle, heard as a cast is | Estimate (ours, from free Roblox sounds) |
| Her screen in Dismiss | Darkened, purple round its edge; E's square lit with the seconds left | Estimate |
| Bots | A bot playing her presses Q when it's hurt and has an orb in reach and a charge, unless the spike's in its hands or it's planting or defusing; it never dismisses | Estimate |
| Basic Training | Leer and Empress count as used, as they can't be played; while Devour or Dismiss is still to use, the progress says they take a Soul Orb | Estimate |

## 5. Design

### The rules

- **`AbilityConfig`** adds Reyna and her four abilities with their costs, charges and points, Team
  Deathmatch's cooldowns for Devour and Dismiss, and `Reyna`: the orbs' time, the damage window, the
  reach and the orb's height, the heal, its time, the overheal's most and time, and Dismiss's time
  and top speed, each with its status and source. Devour and Dismiss are playable (`AbilitySim`).
- **`SoulSim`** (new) is the orbs with no Roblox APIs: one made where they fell, kept to the
  centimetre and its end to the millisecond (`orb`); who earns one (`earns`); the one in reach
  (`pick`, with the level as `sees`, so the tests run it on a fake one); those that last; the wire
  (`encode`, `decode`); and Devour's heal (`heal`, `over`, `take`).
- **`Spike.Context`** carries `soul`, the orb in reach, into each tick, as it carries the spike's
  state.
- **`AbilitySim`**: Q or E with an orb in reach and a charge casts `devour` or `dismiss`, carrying
  the orb's number; one orb a tick, Q before E. Dismiss sets `dismissUntil`, through which nothing
  else casts, and casts `solid` as it ends, its speed capped at the run speed's. The ack carries
  `dismissUntil`, so a replay comes back the same.
- **`PlayerSim`**: through a Dismiss the top speed is 12 m/s, the gun's stowed for its time, nothing
  fires, and the spike's key does nothing; `solid` draws the gun again.
- **`Health`** adds `overheal`, health past the most up to a most of its own, and `trim`, the
  overheal gone; a mend and a health pack leave health past the most alone.

### The server

- **`SoulServer`** (new) watches damage and kills: when each Reyna last hurt each entity, and, at a
  death, an orb for each Reyna it earns one, sent to her as a player attribute (`VFSouls`). It
  answers each tick's orb in reach from her eye (`PlayerSimServer.soulOf`), takes an orb as a cast
  says, gives Devour's heal through `CombatServer.overheal` at most every 0.1 s
  (`FireServer.EVERY`), trims the overheal 10 s after the last heal, and keeps each Dismiss's time
  on the server's clock. Orbs, heals and Dismisses go as she dies, a new life starts or she leaves,
  and all of them with a new round. In Studio the Output has a `[VF] soul:` line as each orb's
  earned, taken, and each overheal goes.
- **`CombatServer`** adds `intangible`: damage someone does to an entity in it is nothing, and the
  rewind leaves it out, so shots pass through; `overheal` and `trim` tell clients.
- **`PlayerSimServer`** adds `soulOf` and `withSoul`, the orb in reach put into a tick's context,
  for players and bots alike. **`AbilityServer`** leaves `solid` untold, and **`Arena`** clears the
  orbs as a round starts.

### The client

- **`SoulView`** (new) draws her orbs from her attribute, picks the one in reach each frame from her
  predicted eye as the server does and hands it to her ticks (`PlayerController.soul`), shows the
  prompt, and darkens her screen through a Dismiss. PlayerGui's `VFSouls` carries `Orbs`, `Reach`
  and `Prompt`.
- **`AbilityEffects`** has others see a Dismiss from its cast: `RemoteEntities.ghost` draws her dark
  and see-through for its time. **`AbilityHud`** lights Dismiss with the seconds left,
  **`SoundConfig`** gives Devour and Dismiss their sounds, and **`CombatHud`** puts the health it
  shows on its gui (`Health`).

### Bots and Basic Training

- **`BotServer`** gives a bot playing her its orb in reach, as a player's, and presses Q when it's
  hurt and has a charge, unless its hands are on the spike. It never dismisses, as a fight wants its
  gun.
- **`TrainingServer`** counts an ability the kit can't play yet as used, and adds the Soul Orb hint
  to the abilities step's progress while Devour or Dismiss is to use.

### Not here yet

- **Leer and Empress.** On her card, the bar and the buy menu, `NOT YET`; so is Empress's free
  Devour on a kill and invisibility in Dismiss.
- **Sight after the cast.** The guides had Devour's heal stop out of sight of the orb; since
  Patch 8.11 removed Devour's time limits, ours needs sight only to take it.
- **The overheal's look.** It shows as health past 100; there's no bar of its own, and spectators
  see what the HUD does.
- **What still hurts in Dismiss.** Harm with nobody behind it, the spike's blast, still does;
  whether a fire or a shock dart does isn't known, and here they don't.
- **Bots' Dismiss.** Bots never dismiss.
- **Late joiners** don't see a Dismiss already under way.
- **Voices.** The reference's Reyna calls out; there are no voices here.
- **The look, the sounds and the reach** are ours until clips are stepped through.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | Reyna and her kit, Team Deathmatch's cooldowns for Devour and Dismiss, and `Reyna`'s numbers, each with its status and source |
| `src/shared/Abilities/SoulSim.luau` | New: the orbs, who earns one, which is in reach, the wire, and Devour's heal |
| `src/shared/Abilities/AbilitySim.luau` | The `devour`, `dismiss` and `solid` casts, and `dismissUntil` |
| `src/shared/PlayerSim.luau` | Dismiss's top speed, the gun stowed and drawn again, nothing fired, the spike's key masked |
| `src/shared/Spike/Spike.luau` | `Context.soul` |
| `src/shared/Combat/Health.luau` | `overheal` and `trim`; health past the most left alone by a mend and a health pack |
| `src/shared/Net/PlayerCodec.luau` | The ack's `dismissUntil` |
| `src/server/SoulServer.luau` | New: orbs earned, sent, taken and gone; Devour's heals, the overheal trimmed, and Dismiss on the server's clock |
| `src/server/CombatServer.luau` | `intangible`, `overheal` and `trim` |
| `src/server/PlayerSimServer.luau` | `soulOf` and `withSoul` |
| `src/server/BotServer.luau` | A bot's orb in reach, and its Devour |
| `src/server/AbilityServer.luau`, `src/server/Arena.luau`, `src/server/init.server.luau` | `solid` untold; orbs cleared each round; SoulServer started and stepped |
| `src/server/TrainingServer.luau` | Abilities that can't be played counted, and the Soul Orb hint |
| `src/client/SoulView.luau` | New: the orbs drawn and picked, the prompt, the screen in Dismiss |
| `src/client/PlayerController.luau` | `soul`, put into each tick's context |
| `src/client/RemoteEntities.luau`, `src/client/AbilityEffects.luau` | Others seeing her Dismiss |
| `src/client/AbilityHud.luau`, `src/client/Combat/CombatHud.luau`, `src/shared/Audio/SoundConfig.luau` | Dismiss's seconds, the `Health` attribute, the sounds |
| `tests/soulharvest.luau` | Her kit and numbers, the orbs, the wire, the heal and the overheal, both casts, the ack, Basic Training |

## 7. Debug tools

- Your `VFSouls` attribute: your orbs as `number,x,y,z,ends`, apart by `;`.
- PlayerGui's `VFSouls` carries `Orbs`, `Reach` (the number of the one in reach, -1 for none) and
  `Prompt`; Workspace's `VFSouls` holds the balls (`VFSoulOrb`).
- `VFCombatHud`'s `Health`: the health the HUD shows, past 100 with an overheal.
- `VFKit` has `dismiss` and the seconds left through a Dismiss.
- In Studio, the server's Output: `[VF] soul: <name> earns <number> at <x, y, z> (her kill)` or
  `(hurt 1.4 s before)`, `[VF] soul: <name> devour takes <number> (there)` and
  `... dismiss takes ...`, and `[VF] soul: <name> overheal over`.

## 8. Refinement loop

1. Play her on the course and against bots: whether the orb's easy to see and to take, whether 15 m
   is the right reach, and how the heal and Dismiss's speed feel.
2. Tune `AbilityConfig.Reyna` and `SoulView`, and re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Her card, the bar and the kit, Leer and Empress not yet.
- An orb for her kill where it fell, drawn only for her, brighter in reach, gone after 3 s.
- Devour taking the orb in reach, 50 over 2 s up to 150, and the overheal gone 10 s after.
- Dismiss taking it: 12 m/s, no firing, the screen darkened, the gun back as it ends.
- Nothing hurting her through it, and others seeing her dark and see-through.
- Basic Training with her kit.
- Bots playing her.

Section 77 of the [Studio checklist](../studio-checklist.md) covers these.
