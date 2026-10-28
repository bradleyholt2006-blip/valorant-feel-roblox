# System 54: Damage direction and danger indicators

In the reference, a hit you take shows round the crosshair on the side it came from, since
Patch 0.49's "New directional damage indicator visual". Damaging utility shows there too: yellow
when it's around you, red when you're taking damage from it or about to, with a small animation on
the yellow since Patch 6.07. Low health and low ammo have had their own look since Patch 0.49. Until
now ours had none of these: a hit showed only as the health going down. This system adds them. The
server tells the player who was hit, and nobody else, where each hit came from: a bullet's or a
blade's from the eye that fired or swung, and a burst's from where it burst. A red arc then shows on
that side of a ring round the crosshair, and it goes on pointing at that place as you turn and move.
It shows whole for a second and fades over the next, and a hit from much the same way renews it. A
hit on the Owl Drone you're flying shows the same way. A fire or a wall of fire that isn't yours
shows a pulsing yellow chevron out past the ring on its side once it's within 3 m of reaching you,
and a red diamond under the crosshair once it does. The health reads red at 30 or under, and a gun's
magazine count at a quarter of the magazine or under.

As before, everything comes from public sources: Riot's patch notes (0.49, 0.50, 1.10, 6.07, 8.11
and 12.02) and, for what Riot doesn't give, the press (Mein-MMO, Dot Esports, Fragster and
TheSportsRush). No game files, memory or network traffic were used, and nothing was read from the
live game. Riot gives that the indicators exist and what they're for, that they point the way damage
came from, the yellow and the red and the yellow's animation, which abilities have them, that a
controlled object's damage shows, that observers don't see them, and that low health and low ammo
have their own look; the press adds what players made of them. Nothing in this system is measured.
Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide or the press, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source we could read says how the indicators look, how long a hit's shows, how near utility must
be for the yellow, or at what health and ammo the low looks start. Ours, in section 4: an arc on a
ring, whole for 1 s and fading over 1 s, renewed by a hit within 20° of its way, eight at most; the
yellow within 3 m, pulsing every 0.8 s; and low at 30 health, and at a quarter of the magazine. The
reference's indicators are Riot's art, so ours are drawn from plain frames.

## 1. Observable behaviour

- **Where a hit came from** (Riot and the community). Patch 0.49: "New directional damage indicator
  visual". Mein-MMO's headline on it: "With Valorant Patch 0.49 you can finally see where someone is
  shooting from". Patch 8.11, of Iso's shield: "Additionally, Iso now gets a damage indicator
  towards the direction of the enemy that broke the shield".
- **Danger around you** (Riot). Patch 6.07: "Visual updates to our in-game UI indicators (the yellow
  and red UI that appear when utility is around you or you are taking/about to take damage)." and
  "Added a small animation to our Yellow Directional Indicator."
- **Which abilities have them** (Riot and the community). Patch 6.07: "In an effort to consolidate
  and make consistent our use of UI indicators throughout our roster, we’ve updated some abilities
  to have or not have UI indicators.", among them "Yellow indicator removed from Leer (C)", "Yellow
  indicator removed from Seekers (X)", "Yellow indicator removed from Alarmbot (E)", "Yellow
  indicator removed from Trademark (C)" and "Critical danger indicator added to FRAG/ment (C)". Dot
  Esports: "KAY/O's FRAG/ment, on the other hand, will be getting a critical danger indicator added
  whenever a player is within range.", and of the ones removed, "the yellow indicators were a great
  way to identify where these specific abilities were coming from". Fragster: "adding indicators to
  the KAY/O’s FRAG/MENT and the Killjoy’s Lockdown". TheSportsRush shows a post from the 6.07 test
  build naming a "Danger Indicator" and a "Critical Indicator".
- **How much room they take** (the community). Fragster: "The new indications are taking up too much
  screen space, according to the fan base,".
- **What's controlled** (Riot). Patch 12.02: "There are new UI damage indicators that display for
  objects that take damage while controlled by a player".
- **Who sees them** (Riot). Patch 1.10: "Observer player no longer see player-specific hud
  indicators (e.g. taking damage indicator) when in freecam".
- **Low health and low ammo** (Riot). Patch 0.49: "New low health and low ammo visuals". Patch 0.50:
  "Fixed a bug where a weapon’s ammo count on the HUD would disappear if swapping your knife, then
  back, while on low ammo."

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "New directional damage indicator visual"; "New low health and low ammo visuals" | [VALORANT Patch Notes 0.49](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-49/), 28 April 2020 |
| "Fixed a bug where a weapon’s ammo count on the HUD would disappear if swapping your knife, then back, while on low ammo." | [VALORANT Patch Notes 0.50](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-50/), 12 May 2020 |
| "Observer player no longer see player-specific hud indicators (e.g. taking damage indicator) when in freecam" | [VALORANT Patch Notes 1.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-10/), 13 October 2020 |
| "Visual updates to our in-game UI indicators (the yellow and red UI that appear when utility is around you or you are taking/about to take damage)."; "Added a small animation to our Yellow Directional Indicator."; "In an effort to consolidate and make consistent our use of UI indicators throughout our roster, we’ve updated some abilities to have or not have UI indicators."; "Yellow indicator removed from Leer (C)"; "Critical danger indicator added to FRAG/ment (C)"; "Yellow indicator removed from Seekers (X)"; "Yellow indicator removed from Alarmbot (E)"; "Yellow indicator removed from Trademark (C)" | [VALORANT Patch Notes 6.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-6-07), 11 April 2023 |
| "Additionally, Iso now gets a damage indicator towards the direction of the enemy that broke the shield" | [VALORANT Patch Notes 8.11](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-811/), 11 June 2024 |
| "There are new UI damage indicators that display for objects that take damage while controlled by a player" | [VALORANT Patch Notes 12.02](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-12-02/), 3 February 2026 |

### From the community

| What | Source |
| --- | --- |
| "With Valorant Patch 0.49 you can finally see where someone is shooting from", its headline | [Mein-MMO, on Patch 0.49](https://mein-mmo.de/en/with-valorant-patch-0-49-you-can-finally-see-where-someone-is-shooting-from,498813), Jürgen Horn, 29 April 2020 |
| "KAY/O's FRAG/ment, on the other hand, will be getting a critical danger indicator added whenever a player is within range."; "the yellow indicators were a great way to identify where these specific abilities were coming from" | [Dot Esports, on Patch 6.07's indicators](https://dotesports.com/?p=838874) |
| "The new indications are taking up too much screen space, according to the fan base,"; "adding indicators to the KAY/O’s FRAG/MENT and the Killjoy’s Lockdown" | [Fragster, on Patch 6.07's indicators](https://www.fragster.com/?p=31555), Jennifer Davis, 13 April 2023 |
| A post from the 6.07 test build naming a "Danger Indicator" and a "Critical Indicator" | [TheSportsRush, on the 6.07 test build](https://thesportsrush.com/valorant-pbe-early-6-07-patch-notes-show-threat-indicators-in-game/), Adnan Juzar Kachwala, 11 April 2023 |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How long a hit's indicator shows, and how it fades | Public clips of a single hit taken, frame by frame |
| Its size and its distance from the crosshair, and whether it follows the shooter as you turn | Public clips of a player turning after a hit |
| How near utility must be for the yellow, and how fast it pulses | Public clips of a player walking up to a Phoenix or Brimstone fire |
| At what health and ammo the low looks start, and what else they change | Public clips of a magazine emptied and of a player at low health |
| Whether a burn shows a hit's indicator | Public clips of a player standing in a fire |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| A hit's way | A red arc on a ring round the crosshair, on the side the hit came from: a bullet's or a blade's from the eye that fired or swung, a burst's (a Shock Bolt's, a Hunter's Fury blast's) from where it burst | Confirmed (Patch 0.49: "New directional damage indicator visual"; Patch 8.11: "towards the direction of the enemy"); estimate (its look) |
| As you turn and move | It goes on pointing at where the hit came from | Estimate |
| How long | Whole for 1 s after its latest hit, then fading to nothing over 1 s | Estimate |
| More hits | A hit within 20° of an arc's way renews it, pointing the newer way; one from elsewhere adds an arc, eight at most, the oldest giving way | Estimate |
| What shows none | A fire's burn, a spawn room's and the spike's blast, with nowhere they came from to point at; a hit that kills; a hit from straight above or below | Estimate |
| Who's told | The server tells the one hit alone, and only where that hit came from | Estimate (ours, as for the fog of war, system 35) |
| The Owl Drone | A hit on the drone you're flying that doesn't break it shows as one on you, pointing from the drone | Confirmed (Patch 12.02: "objects that take damage while controlled by a player") |
| Danger | A fire or a wall of fire that isn't yours, within 3 m of reaching you, shows a yellow chevron out past the ring on its side: a fire's middle, or the place on a wall nearest you. It pulses, once every 0.8 s | Confirmed (Patch 6.07: "the yellow and red UI that appear when utility is around you"; "a small animation to our Yellow Directional Indicator"); estimate (the 3 m, its look and its pulse) |
| Critical | Once it reaches you as the server burns you, a red diamond with a `!` under the crosshair, pulsing | Confirmed (Patch 6.07: "the yellow and red UI"; "Critical danger indicator added to FRAG/ment (C)"); estimate (its look) |
| Which utility | Hot Hands' fire and Blaze's wall, the ones of ours that hurt whoever stands in them | Estimate (Patch 6.07 gives some abilities indicators and takes the yellow from others) |
| Who sees them | The living alone, and each life starts with none | Confirmed (Patch 1.10: no "player-specific hud indicators" for observers in freecam) |
| Low health | At 30 or under, in whole points as the HUD shows them, the health reads red | Confirmed (Patch 0.49: "New low health and low ammo visuals"); estimate (30, and red) |
| Low ammo | A gun's magazine count reads red at a quarter of its magazine or under, rounded down, and at its last round at the least: a Vandal's at 6, a Classic's at 3, an Operator's at 1. The reserve beside it doesn't change | Confirmed (Patch 0.49: "New low health and low ammo visuals"); estimate (a quarter, and red) |

## 5. Design

### The rules

- **`Indicators`** (new) has the rules, with no Roblox APIs: `yawOf` gives the way a direction
  looks, as the camera's yaw; `bearing` where that shows on the ring for a view; `add` puts a hit
  among the arcs, renewing one within `merge` of its way or adding one, the oldest giving way past
  `most`; `wayTo` points an arc at where its hit came from, from wherever you are; `alpha` and
  `prune` fade arcs and take them away; `pulse` is the yellow's and the diamond's beat; `fireThreat`
  and `wallThreat` say how near a fire or a wall of fire is, by the same tests the server burns with
  (`FireSim.inside` and `BlazeSim.inside`, by the body's half width), and the way to it; `lowHealth`
  and `lowAmmo` say when they read low; and `text` gives what scripted checks read.

### The server

- **`CombatServer`** has where each hit came from (`CombatServer.Hit`'s `from`): a volley's eye, a
  swing's eye, or a burst's point (`blast`). A player who takes a hit and lives is told of it alone
  with the `Hurt` remote (`tellHurt`): where it came from and where it struck, their eye. Nobody
  else hears of it, so it says nothing of where anyone is to those who can't see them.
- **`ShockServer`** and **`FuryServer`** give their bursts' points.
- **`DroneServer`** tells the drone's pilot of each hit on it that doesn't break it, from the eye of
  whoever struck it.
- **`Remotes`** has `Hurt`.

### The client

- **`IndicatorView`** (new) draws them (`VFIndicators`): the red arcs from the `Hurt` remote, each
  in pieces along the ring and thinnest at its ends, pointing at where its hit came from from the
  camera, so from the drone while you fly it; the yellow chevrons and the red diamond from the fires
  and the walls there are; and none while you're dead, and none left at each spawn.
- **`FireView`** and **`BlazeView`** say what fires and walls there are, with the time on each one's
  clock (`pools`, `walls`).
- **`CombatHud`** reads low health and a low magazine count in red, and says so (`LowHealth` and
  `LowAmmo`).

### Not here yet

- **Other abilities' indicators.** Patch 6.07 gives indicators to some abilities and takes the
  yellow from others, and the press names KAY/O's FRAG/ment and Killjoy's Lockdown. Ours has them
  for the utility that burns, Hot Hands' fire and Blaze's wall: a Shock Bolt in the air, Hunter's
  Fury's blasts and a Curveball's flare show nothing until they land.
- **Observers.** Patch 1.10 took them away from observers in freecam. Ours shows none to anyone
  watching: Spectate's view of a teammate has none of theirs.
- **The drone's view and your body.** While you fly the Owl Drone, a hit on your body points from
  the drone, not from where you stand.
- **A burn's way.** A fire's burn shows no arc; the critical says you're in it.
- **Low health's other cues.** Whatever else the reference's low health look has, ours is the
  health's colour alone.
- **Riot's look.** The reference's indicators are Riot's art, and none is copied: plain frames stand
  in.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Combat/Indicators.luau` | New: the rules: a hit's way and where it shows on the ring, arcs renewed and giving way, their fade, the pulse, how near a fire or a wall of fire is, low health and low ammo, and the text checks read |
| `src/server/CombatServer.luau` | Where each hit came from, and the `Hurt` remote to the one hit |
| `src/server/ShockServer.luau`, `src/server/FuryServer.luau` | Where their bursts came from |
| `src/server/DroneServer.luau` | A hit on the Owl Drone told to its pilot |
| `src/shared/Net/Remotes.luau` | `Hurt` |
| `src/client/IndicatorView.luau` | New: the arcs, the chevrons and the diamond round the crosshair, and `VFIndicators` |
| `src/client/FireView.luau`, `src/client/BlazeView.luau` | The fires and the walls there are |
| `src/client/Combat/CombatHud.luau` | Low health and a low magazine in red, and `LowHealth` and `LowAmmo` |
| `src/client/init.client.luau` | `IndicatorView` started |
| `tests/indicators.luau`, `tests/run.luau` | New: 54 checks: ways as yaws and on the ring, arcs added, renewed and giving way, their fade and pruning, arcs pointing at where hits came from as you move, the pulse, fires and walls near and reaching you, low health and low ammo, and the text checks read |

## 7. Debug tools

- PlayerGui's `VFIndicators` carries `Hurt` (the arcs shown, each as where on the ring it is, in
  whole degrees clockwise from the top: `-90, 180`), `LastHurt` (where the latest hit's arc is, or
  would be once it's gone, empty before one in this life), `Danger` (the yellow chevrons, the same
  way) and `Critical` (whether the red diamond's up).
- `VFCombatHud` carries `LowHealth` and `LowAmmo`.

## 8. Refinement loop

1. From public clips of single hits, time the arc's hold and fade, and measure its size and its
   distance from the crosshair.
2. From public clips of players walking up to a fire, set `near` and the pulse.
3. From public clips of a magazine emptied and of a player at low health, set the low looks'
   thresholds and what they change.
4. Add indicators for other utility as it comes, after Patch 6.07's list.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- A hit from one side: a red arc on that side of the ring, whole for a second and fading over the
  next.
- The arc going on pointing at where the hit came from as you turn and move.
- Hits from much the same way renewing one arc; none for a hit that kills, and none left as you die.
- Only the one hit seeing it.
- A hit on the Owl Drone you fly: an arc on your ring, from the drone.
- A fire or a wall of fire near you: the yellow chevron on its side, pulsing; once it reaches you,
  the red diamond, and no arc for its burn.
- Low health and a low magazine reading red.

Section 58 of the [Studio checklist](../studio-checklist.md) covers these.
