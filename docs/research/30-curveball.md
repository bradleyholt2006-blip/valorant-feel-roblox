# System 30: Curveball

The reference's second agent here is Phoenix, a Duelist, and the first of his abilities that can be
played is his signature, Curveball: E readies a flare in hand, the left button throws it curving
round to the left and the right button to the right, and a moment later it pops and blinds whoever
can see it, by how they face it and how far off they are, Phoenix and his side included. This
system adds Phoenix to agent select with his whole kit on the bar, Curveball played and the rest
shown but not yet played; the flare in hand, its throw, its flight round a corner and its pop; and
the blind: a white screen that clears, judged by the server, and the look of a blinded player to
everyone else.

As before, everything comes from public sources: Riot's agent page for Phoenix, six patch notes and
an Agent Origins article, and, for the numbers Riot doesn't give (the flare's equip and unequip,
the uses, what blinds whom and how the blind clears), the VALORANT Wiki's pages on Curveball,
Phoenix and status effects, with two news articles on what stops a blind. No game files, memory or
network traffic were used. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's agent pages, patch notes and articles) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **The kit** (Riot's page and the wiki). Phoenix is a Duelist: C Blaze, a wall of fire; Q Hot
  Hands, a fireball; E Curveball, his signature since Patch 9.10; X Run it Back, his ultimate, 7
  points since Patch 13.02; and Inner Fire, a passive that heals him in his own fire.
- **The flare** (Riot's page). E equips "a flare orb that takes a curving path and detonates
  shortly after throwing": FIRE curves it to the left, ALTERNATE FIRE to the right, and its
  detonation blinds "any player who sees the orb". The wiki gives it 0.8 s to equip, 0.48 s to put
  away, and 2 uses.
- **Its path** (the wiki). "A missile on a fixed path that can be obstructed on contact with
  terrain", detonating "after a set amount of time", with no value given for the time from the
  throw. Riot's Agent Origins says why it bends: "Originally, Phoenix's flash went forward", and
  people "had trouble getting it around the wall and out of their line of sight".
- **Its windup.** 0.7 s at first ("almost impossible to turn away from", Agent Origins), then 0.5 s
  (Patch 5.01), then 0.6 s (Patch 11.00), for "more room for counterplay and opportunities for
  clutch moments like flicking to turn flashes."
- **The blind** (the wiki's status effects). Vision "replaced with an opaque, colored screen". Its
  length depends "on where the target is facing and the distance between them and the flash":
  looking straight at it is the full blind, 1.5 s since Patch 5.01; turned away, or with their
  backs to it, players are "only slightly blinded for a very brief time"; further off, the blind
  is shorter, and at "especially large distances" there's none. Once it's over, it "will gradually
  disappear from the player's screen over 1 second". Curveball blinds allies and Phoenix too.
- **How a blind looks** (Patch 5.07). On your screen, a full blind shrinks over time "to give a
  better indication of when the full flash will end"; on others, it shows in front of their face
  and "behind the player's head the moment that the flash starts to fade".
- **Its charges** (Patch 9.10). A free charge every round, and "2 kill reset to generate an
  additional charge". 250 credits a charge (Patch 3.0, still the wiki's price).

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| Role: "Duelist"; CURVEBALL: "EQUIP a flare orb that takes a curving path and detonates shortly after throwing." | [Phoenix](https://playvalorant.com/en-us/agents/phoenix/), Riot's agent page |
| "FIRE to curve the flare orb to the left, detonating and blinding any player who sees the orb."; "ALTERNATE FIRE to curve the flare orb to the right." | The same |
| Curveball "Cost increased 200 >>> 250" | [VALORANT Patch Notes 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/), 22 June 2021 |
| Curveball "Flash Max duration increased 1.1s >>> 1.5s"; "Flash Windup decreased .7s >>> .5s" | [VALORANT Patch Notes 5.01](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-5-01/), 12 July 2022 |
| "1P visuals when fully flashed now shrink overtime to give a better indication of when the full flash will end" | [VALORANT Patch Notes 5.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-07/), 4 October 2022 |
| "3P visuals for flashed enemies and allies now render behind the player's head the moment that the flash starts to fade." | The same |
| "Increased the window for awarding assists on flashes, nearsights and concusses from 1 >>> 3 seconds" | The same |
| "Originally, Phoenix's flash went forward."; "But people had trouble getting it around the wall and out of their line of sight." | [Agent Origins: Phoenix](https://playvalorant.com/en-gb/news/dev/agent-origins-phoenix/), Riot, 26 September 2022 |
| "A 700 millisecond wind-up felt almost impossible to turn away from."; "We shortened the time on its wind-up and increased the actual duration of the flash effect." | The same |
| Curve Ball "Changed to the signature ability slot"; "Grants a free charge on round start"; "2 kill reset to generate an additional charge" | [VALORANT Patch Notes 9.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-10), 19 November 2024 |
| Hot Hands "Changed to a non-signature ability"; "Cost 200 credits"; Phoenix "applies a Heal over time to himself whenever he touches his flames" | The same |
| "Curveball Windup increased 0.5s >>> 0.6s"; "there's more room for counterplay and opportunities for clutch moments like flicking to turn flashes." | [VALORANT Patch Notes 11.00](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-11-00/), 24 June 2025 |
| Yoru's Blindside "now follows the standard flash falloff curves as other Agents."; "Previously, Yoru's flashes that were slightly offscreen were more effective than intended" | [VALORANT Patch Notes 11.08](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-08/), 14 October 2025 |
| Run it Back: "Ultimate points increased from 6 to 7." | [VALORANT Patch Notes 13.02](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-13-02), 28 July 2026 |

### From the community

| What | Source |
| --- | --- |
| Equip "0.8 seconds"; Unequip "0.48 seconds"; Windup "0.6 seconds"; Max blind duration "1.5 seconds" | [VALORANT Wiki, Curveball](https://wiki.playvalorant.com/en-us/Curveball) (Weird Gloop) |
| Cost "250"; uses "2"; restock "2 kills"; "Affects allies/self?": "Yes." | The same |
| "a missile on a fixed path that can be obstructed on contact with terrain"; it detonates "after a set amount of time" | The same |
| "Any agent or object in line of sight of the detonation will then be flashed." | The same |
| "An agent with a Flash debuff has their vision replaced with an opaque, colored screen." | [VALORANT Wiki, Status Effect](https://wiki.playvalorant.com/en-us/Status_Effect) |
| "Once the flash's duration expires, its effects will gradually disappear from the player's screen over 1 second." | The same |
| "The duration of the flash is dependent on where the target is facing and the distance between them and the flash." | The same |
| "Players looking directly at the flash on detonation will be blinded for the full duration."; those who "have turned away from directly looking at the flash or have their backs to it" will "only be slightly blinded for a very brief time." | The same |
| "the further away from the flash the player is, the less time they will be blinded for"; "At especially large distances it is possible for a player to not be blinded at all" | The same |
| Phoenix's kit: Blaze 150 and 1 use, Hot Hands 200 and 1, Curveball 250 and 2, Run it Back 7 points; Inner Fire | [VALORANT Wiki, Phoenix](https://wiki.playvalorant.com/en-us/Phoenix) |
| Team Deathmatch: Blaze back every 48 s, Curveball 44 s, Hot Hands 54 s; Run it Back 70 points | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) |
| A player kept out of a blind from the outer edge of Astra's and Brimstone's smokes; "it didn't seem to work with Omen and Viper" | [Dot Esports](https://dotesports.com/valorant/news/valorant-player-discovers-how-to-avoid-getting-blinded-using-outside-edge-of-smokes), Andreas Stavropoulos, 16 April 2021 |
| "any type of flash that activates within the area-of-effect circle of Viper's Poison Cloud will neutralize the blind." | [ONE Esports](https://www.oneesports.gg/valorant/vipers-poison-orb-stop-flashes-valorant/), Nigel Zalamea, 2 December 2024 |

Neither source gives the flare's speed, how soon and how sharply it turns, how big it is, or the
shape of the falloff by angle and by distance, beyond its ends. Ours are in section 4.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| The flare's path: how far it goes before it turns, how sharply, and where it pops on open ground | Public clips of Curveball thrown on flat ground, stepped frame by frame against known distances on a map |
| The blind's length by angle and distance | Clips of players blinded at known places, timed from the pop to the screen clearing |
| Whether 0.6 s is long enough to turn away from, from where a thrower usually stands | Our own playtests: how often a defender who hears the throw turns in time |
| Whether a blind under the HUD reads well | Our own playtests |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Phoenix | A Duelist, C Blaze, Q Hot Hands, E Curveball, X Run it Back and Inner Fire, on agent select's card and the ability bar; only Curveball plays | Confirmed (the role, the slots); community (the kit) |
| Curveball's charges | Up to 2; 250 credits each; a free one every round; two kills bring one back | Confirmed (250, the free charge, two kills); community (2) |
| In Team Deathmatch | One back every 44 s; Run it Back's 70 points | Community |
| The flare in hand | E puts it in a fifth slot, drawn in 0.8 s, with the move speed of a knife; E again, a number key, a plant or defuse, a death, or selling the last charge puts it away unthrown, with nothing spent, and the gun comes back with its own draw | Community (0.8 s); estimate (the rest) |
| The throw | The left button throws it curving left, the right button curving right, as soon as it's drawn (held, as soon as it's ready); a charge goes, and the gun is back in hand 0.48 s later | Confirmed (the two ways); community (0.48 s) |
| Its flight | From the eye at 12 m/s, straight for 0.1 s, then turning round the vertical at 300 degrees a second to a quarter turn, with no drop; on level ground it pops about 3.5 m ahead and 4.7 m to the side | Estimate |
| What stops it | The level, where it meets it: it waits there. Players and dummies don't | Community (terrain); estimate (players) |
| The pop | 0.6 s after the throw, wherever it is | Confirmed |
| Who's blinded | Everyone alive who can see the pop: nothing of the level between their eye and it. Thrower, allies and enemies alike; clouds and players don't hide it; dummies aren't blinded | Community (line of sight, allies and self); estimate (clouds, dummies) |
| By facing | All of the longest within 50 degrees of the view, falling evenly to 0.15 of it at 90 degrees, and 0.15 behind | Community (full when looking at it, brief behind); estimate (the angles and the share) |
| By distance | All of it out to 25 m, falling evenly to none at 60 m; under 0.05 of it, none | Community (less further off, none very far); estimate (the distances) |
| The blind | White for its share of 1.5 s, then clearing evenly over that share of 1 s; on top of one still clearing, the later white and the later clear win | Confirmed (1.5 s); community (the 1 s fade); estimate (the share of the fade, and two at once) |
| Judged where | The server, at the pop, from each player's eye and view as it last ran their moves, with no rewind | Estimate |
| Your screen | Warm white under the HUD, with a whiter core shrinking from past the screen's edges to under a third of it as the white runs out, then all of it clearing | Confirmed (the shrinking); community (opaque); estimate (the look) |
| Others | A glow at the face, in front while their screen is white and behind the head once it clears | Confirmed |
| Its sounds | The flare's draw for the one drawing it, a swish as it's thrown and a crack as it pops, both heard as far as an ability | Estimate (ours, from free Roblox sounds) |
| Assists | Not yet: a blind gives no assist | Confirmed (the reference's 3 s window, not applied) |

## 5. Design

### The rules

- **`AbilityConfig`** adds Phoenix (`AgentIds` and `AgentIndex`), his four abilities and Inner
  Fire, Team Deathmatch's numbers for his kit, and `Curveball`: the unequip, windup, the longest
  blind and its fade, and the estimates for the flight and the falloff.
- **`WeaponConfig`** adds the flare, an `ability` weapon (category `"ability"`, `ability =
  "curveball"`) for the fifth slot: 0.8 s to draw, one throw a magazine, no spread and no kick.
  It's never sold or dropped, and lies on no ground.
- **`AbilitySim`** keeps `holding`, the kit slot whose ability is in hand. E with a charge puts the
  flare in hand (an `equip` cast, nothing spent); E again puts it away. `thrown` spends the charge
  and makes the `flare` cast, from the eye, its direction and `curve` (-1 left, 1 right). `carried`
  says what the fifth slot should hold: Blade Storm's knives while the storm lasts, or the
  weapon of the ability in hand.
- **`PlayerSim`** draws the flare as the `equip` cast comes, and catches what it fires: the shot
  is dropped, so no bullet goes, and is the throw instead (`thrown`), with the gun back in hand
  0.48 s later (`WeaponSim.putAway`'s `ready`). The flare goes away unthrown as soon as anything
  else is in hand or its slot is emptied: a switch, a plant or defuse, a death, or its last charge
  sold.
- **`FlareSim`** (new) flies a throw a tick at a time from FlareSim.throw: `step`, `fly` to its pop,
  `at` between ticks and `popTime`; with the world it stops where it meets the level, and with the
  server's `stop` it stops there instead, so a client flies it the same way without the level.
  `seen`, `facing`, `falloff` and `strength` give the blind, `blind` puts one on top of another,
  `whiteAt` says how white the screen is, and `encode` and `decode` keep it as an attribute.
- **`PlayerCodec`** carries `holding` in the ack, so a client that mispredicts it is put right.

### The server

- **`FlareServer`** (new) hears each `flare` cast, flies it through the level at once and tells
  every client its `flight`: where from and which way round, when, how long after the throw it met
  the level (`stop`) and where it pops (`pop`). At the pop it blinds everyone alive who can see it,
  each from their `PlayerSimServer.view`, as their `VFBlind` attribute (`from,full,gone` in server
  time), unset once it's gone, at a death and at a new life; a thrower's flares still in the air go
  as they start a new life. The thrower's `VFLastFlare` is where their last one popped (metres).
- **`AbilityServer`** doesn't tell others of an `equip` cast, as it doesn't Blade Storm's knives
  drawn again: others hear the throw (the `flare` cast) and the pop.
- **`PlayerSimServer.give`** never puts the flare in a slot.

### The client

- **`FlareView`** (new) draws each flare in the air as a small orange-white ball of light, and its
  pop as a flash of light swelling and fading. Yours fly at once as you throw them, through the
  level as the server's do; if the server's `flight` ends somewhere else, the server's flies
  instead. Others' are flown from their `flight` as the frame on your screen reaches the throw.
  The pop's crack is heard from where it pops.
- **`BlindView`** (new) draws your blind, or the watched player's: the warm white screen and its
  shrinking core, then the clear. On others it puts a glow at the face, as long as any of their
  blind is left.
- **`AbilityHud`** lights E while the flare is in hand, `EQUIP` until it can be thrown.
- **`CombatHud`** names the flare `Curveball   [E]`, with no ammo.
- **`WeaponLooks`** draws the flare in hand as an orb of light in the hand.
- **`BuyMenu`** is tall enough for three abilities under the shields; Curveball's panel adds its
  pop, its blind and the kills that bring a charge back.
- **`AgentMenu`** has Phoenix's card; with two agents to pick from, it now comes up by itself as a
  window opens. A passive that doesn't work yet is `NOT YET`, as an ability is.
- **`GameSounds.playCast`** plays a pop where it is (`exact`), not at the chest.

### Not here yet

- **Blaze, Hot Hands, Run it Back and Inner Fire.** They show on the bar and the card, dimmed and
  `NOT YET`, and can't be bought or cast. Hot Hands and Inner Fire play since system 31
  ([31-hot-hands.md](31-hot-hands.md)), Blaze since system 32 ([32-blaze.md](32-blaze.md)), and Run
  it Back since system 33 ([33-run-it-back.md](33-run-it-back.md)).
- **Flash assists.** A blind gives no assist, where the reference's give one for 3 s.
- **Rewinding the view.** A blind is judged from where the server last had each player's view,
  which runs a little behind their screen, so a flick away at the last moment can come too late.
- **Smokes against blinds.** Clouds don't hide a pop, where the reference's sometimes do.
- **Dummies.** Practice dummies aren't blinded.
- **The flare in others' hands.** Players are drawn as their hitboxes, with no weapon; the pose
  they send carries the flare, for when there are models to hold it.
- **Its shape.** The path and the falloff are estimates until clips are stepped through.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | Phoenix, his kit and passive, Team Deathmatch's numbers for it, and `Curveball`'s numbers, each with its status and source |
| `src/shared/Abilities/AbilitySim.luau` | `holding`, the `equip` and `flare` casts, `carried` and `thrown` |
| `src/shared/Abilities/FlareSim.luau` | New: the flight, the pop's time, who sees it, the blind's strength and its life, and its attribute |
| `src/shared/Weapons/WeaponConfig.luau` | The flare, an `ability` weapon for the fifth slot |
| `src/shared/Weapons/WeaponSim.luau` | `putAway`'s `ready`: the gun back sooner after a throw |
| `src/shared/PlayerSim.luau` | The flare drawn, its fire caught as the throw, and put away unthrown |
| `src/shared/Net/PlayerCodec.luau` | `holding` in the ack |
| `src/shared/Weapons/Shop.luau`, `src/shared/Audio/SoundConfig.luau` | The flare never sold; its draw, throw and pop sounds |
| `src/server/FlareServer.luau` | New: the flight told to clients, the pop, the blinds and `VFLastFlare` |
| `src/server/AbilityServer.luau`, `src/server/PlayerSimServer.luau`, `src/server/init.server.luau` | No `equip` casts told; the flare never given; the flares started and stepped |
| `src/client/FlareView.luau` | New: flares in the air and their pops |
| `src/client/BlindView.luau` | New: the white screen and the glow on others |
| `src/client/AbilityHud.luau`, `src/client/Combat/CombatHud.luau`, `src/client/Combat/WeaponLooks.luau` | The flare in hand on the bar, the HUD and the viewmodel |
| `src/client/BuyMenu.luau`, `src/client/AgentMenu.luau` | Three abilities for sale and Curveball's panel; Phoenix's card and his passive `NOT YET` |
| `src/client/AbilityEffects.luau`, `src/client/Audio/GameSounds.luau`, `src/client/PlayerController.luau`, `src/client/init.client.luau` | Flights left to FlareView; a sound where it is; `holding` checked against the server's; the views started |
| `tests/curveball.luau` | New: 88 checks: Phoenix, Curveball's numbers, the kit through a match, the flare in hand, its flight, the blind and the wire |

## 7. Debug tools

- A player's `VFBlind` is their blind while any of it is left: when it began, when the white ends
  and when it's gone, in server time (`812.500,814.000,815.000`).
- The thrower's `VFLastFlare` is where their last flare popped, in metres.
- `VFKit` ends in `equip` while the flare is in hand.
- `Workspace.VFFlares` holds a `Flare` ball for each flare in the air and a `Pop` for each pop while
  it lasts; `Workspace.VFBlinds` a `Blind` glow for each other player blinded, named for them in
  its `Player` attribute. In PlayerGui, `VFBlind`'s `White` is the screen and its `Core` the core.
- `VFTestButtons` 16384 presses E, 128 the left button and 256 the right, so a flare can be
  readied and thrown without a key or a mouse button; `VFTestYaw` turns you away or towards it.

## 8. Refinement loop

1. Step through clips of Curveball thrown on open ground, and set `Curveball.speed`,
   `straight`, `turnRate` and `turn` until the pop lands where the reference's does.
2. Time blinds in clips at known angles and distances, and set `fullAngle`, `edgeAngle`, `away`,
   `near` and `far`.
3. Play it: if a flick away often comes too late, rewind each view to the frame on its screen.
4. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Phoenix's card in agent select, his kit on the bar with only E lit, and his kit in the buy menu,
  Curveball the only one for sale.
- E draws the flare in 0.8 s, `EQUIP` on the bar; the left button throws it curving left, the
  right button right, and the gun is back 0.48 s later; E again or a number key puts it away.
- The flare's flight: straight, then round a quarter turn, popping 0.6 s after the throw, about
  3.5 m ahead and 4.7 m to the side on the course; stopped where it meets the floor or a wall.
- The blind: white and clearing, longer looking at it and shorter turned away, none behind a wall;
  the shrinking core.
- A second player: the throw and the pop heard, the flare seen in the air, the blind on whoever
  sees it, and the glow on a blinded player's face, then behind their head.

Section 34 of the [Studio checklist](../studio-checklist.md) covers these.
