# System 41: Omen's Paranoia

Omen's Paranoia is the second of his kit played. Q puts a shadow orb in hand, ready in 1.1 s, and
fire sends it straight along the crosshair: it appears 4.5 m ahead of his eye and flies 25 m at
20 m/s, through walls and anyone in its way, touching everyone who comes within 4.3 m of its middle,
his own side and Omen too. Whoever stands in its path as it's sent is warned. A touch nearsights
them for 2 s: they see nothing further than 7.5 m but darkness, they're deafened, their minimap is
covered, and a flash popping further away doesn't blind them; then it clears over half a second.
This system adds the orb's flight, whom it touches, the warning, the nearsight and the deafening,
the nearsighted in the minimap's spotting and in the Curveball's blind, who hears it sent, and how
it looks and sounds.

As before, everything comes from public sources: seven of Riot's patch notes and Riot's agent page
and, for what Riot doesn't give, the VALORANT Wiki's pages on Paranoia, on status effects and on
Team Deathmatch. No game files, memory or network traffic were used, and nothing was read from the
live game. Here the wiki's numbers are labelled community, though it says some of them come from the
game files. Riot gives that it's equipped, the cost, that it goes through walls, that it appears a
little ahead of Omen, that his movement doesn't carry into it, its speed and travel, and that
enemies are warned; the wiki gives fire sending it, the equip and unequip times, the radius, the
nearsight's time and how far the nearsighted see, that it deafens and touches allies and Omen too,
and what nearsight and deafening do; how far ahead it appears, how the nearsight clears, how the
deafened hear and how it all looks are ours. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes and agent page) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source gives how far ahead of Omen the orb appears, whether its 25 m are flown from there or from
Omen, how long a nearsight takes to clear, how muffled and how much quieter the deafened hear, or
what the warning looks like. Ours are in section 4: 4.5 m, just past its radius; from where it
appears; half a second; a 400 Hz low-pass and about 9 dB down; and shadow at the screen's edges for
0.6 s.

## 1. Observable behaviour

- **In hand** (Patch 1.0 and the wiki). "Paranoia is now equipped instead of quickcast, and hit
  detection improved, especially at close range". The wiki has "EQUIP a blinding orb. FIRE to throw
  it forward, briefly Nearsighting and Deafening all players it touches." It's ready 1.1 s after Q,
  and the gun is back 0.7 s after it's sent (from the game files, it says). Riot's agent page has
  "INSTANTLY fire a shadow projectile forward, briefly reducing the vision range of all players it
  touches."
- **Its flight** (the agent page and Patches 4.04, 7.04 and 11.08). "This projectile can pass
  straight through walls." Patch 4.04: "Added forward spawn offset, so players adjacent to Omen are
  not hit". Patch 7.04: "No movement velocity imparted when casting". Patch 11.08: "Projectile speed
  increased from 16 meters per second → 20 meters per second"; "Travel distance reduced from 32.5m →
  25m". The wiki adds, in our words, that v7.04 also slowed it from 20 to 16 m/s without saying so,
  and that it passes through all terrain.
- **Whom it touches** (the wiki, in our words). Everyone within 4.3 m of it (from the game files, it
  says), allies and Omen himself too, and any deployed ability with a field of vision. Since v1.09
  its look matches what it touches.
- **The warning** (Patch 1.0 and the wiki). "Changed the cast paradigm to reward more proactive use
  of Paranoia over its previous reactive use case."; "Enemies will receive a warning when the
  projectile is fired rather than being in the direct path of it."; "This should make it hit enemies
  more reliably." The wiki has agents standing in its path see a warning, in our words.
- **Nearsight** (the wiki's Status Effect and Paranoia pages). The nearsighted will "only be able to
  see what's immediately in front of them up to a maximum radius."; past it, all is "replaced with
  dark, opaque colors." Paranoia's lasts 2 s and reaches 7.5 m (from the game files, it says), and a
  flash popping outside that radius doesn't affect them, in our words. Neither page gives a time for
  it to clear.
- **Deafened** (the Status Effect page). Nearsight deafens too: their audio is "severely dampened.",
  and their minimap "will become obscured." In our words, some enemy abilities' screen effects are
  hidden from them, and the lines spoken across the map for an ultimate are still heard.
- **Its cost** (Patches 2.0, 3.0 and 5.12). "Cost increased: $200 >>> $400", then "Cost decreased
  400 >>> 300", and last "Paranoia (Q) Cost decreased 300 >>> 250". One use (the wiki), and none
  free.
- **Team Deathmatch** (the wiki). Back 73 s after it's spent.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Paranoia is now equipped instead of quickcast, and hit detection improved, especially at close range"; "Changed the cast paradigm to reward more proactive use of Paranoia over its previous reactive use case."; "Enemies will receive a warning when the projectile is fired rather than being in the direct path of it."; "This should make it hit enemies more reliably." | [VALORANT Patch Notes 1.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-0/), 1 June 2020 |
| Paranoia "Cost increased: $200 >>> $400"; "Paranoia has been quite strong for a while, and rather than reduce its effectiveness" | [VALORANT Patch Notes 2.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-2-0/), 12 January 2021 |
| Paranoia "Cost decreased 400 >>> 300" | [VALORANT Patch Notes 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/), 22 June 2021 |
| Paranoia "Added forward spawn offset, so players adjacent to Omen are not hit" | [VALORANT Patch Notes 4.04](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-4-04/), 1 March 2022 |
| "Paranoia (Q) Cost decreased 300 >>> 250" | [VALORANT Patch Notes 5.12](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-12/), 6 December 2022 |
| Paranoia "No movement velocity imparted when casting" | [VALORANT Patch Notes 7.04](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-7-04/), 29 August 2023 |
| Paranoia "Projectile speed increased from 16 meters per second → 20 meters per second"; "Travel distance reduced from 32.5m → 25m" | [VALORANT Patch Notes 11.08](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-08/), 14 October 2025 |
| Paranoia: "INSTANTLY fire a shadow projectile forward, briefly reducing the vision range of all players it touches." "This projectile can pass straight through walls." | [Riot's agent page for Omen](https://playvalorant.com/en-us/agents/omen/) |

### From the community

| What | Source |
| --- | --- |
| "EQUIP a blinding orb. FIRE to throw it forward, briefly Nearsighting and Deafening all players it touches."; "This projectile can pass straight through walls."; a basic ability, 250 credits, 1 use, on Q, affecting allies and Omen himself. In our words: equip 1.1 s, unequip 0.7 s, a radius of 4.3 m, a nearsight of 2 s and a vision of 7.5 m (from the game files, it says); 20 m/s and 25 m (v11.08); through all terrain; any deployed ability with a field of vision it touches nearsighted; agents in its path warned | [VALORANT Wiki, Paranoia](https://wiki.playvalorant.com/en-us/Paranoia) (Weird Gloop) |
| History, in our words: v1.0 equipped, not cast at once, with better hit detection; v1.09 its look matched to what it touches; v2.0 200 to 400 credits; v3.0 400 to 300; v4.04 the forward offset; v5.12 300 to 250; v7.04 no movement carried into it, and slowed from 20 to 16 m/s unannounced; v11.08 16 to 20 m/s and 32.5 to 25 m; v11.09 a smaller minimap icon | The same |
| Nearsight: "only be able to see what's immediately in front of them up to a maximum radius."; past it, "replaced with dark, opaque colors."; in our words, flashes popping outside the radius don't affect them, and nearsight deafens too. Deafen: audio "severely dampened."; the minimap "will become obscured."; in our words, some enemy abilities' screen effects hidden, and the lines spoken across the map for an ultimate still heard | [VALORANT Wiki, Status Effect](https://wiki.playvalorant.com/en-us/Status_Effect) |
| Team Deathmatch: Paranoia back 73 s after; in our words, each basic ability starts a match half way to its first charge | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How far ahead it appears | Clips of it sent alongside a wall with known spacing, stepped to the first frame it shows |
| Where its travel is from | A custom game: send it down a long, marked corridor, and note where it ends |
| Its radius at the edge | A custom game with a second player: send it past them, a step further to the side each time, until it misses |
| The warning | Clips of standing in its path, and just beside it, as it's sent |
| How it clears | Clips of a nearsight ending, stepped frame by frame |
| How the deafened hear | Recordings of the same shot heard with and without a nearsight, compared |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| His kit | Paranoia lit on Omen's card and the bar with Dark Cover; Shrouded Step and From the Shadows still read NOT YET, and Shrouded Step isn't sold | Community (the kit: the wiki) |
| Its charge | One at most, none free: 250 credits in the spike rounds. On the course and in Skirmish it's there every life, and on the course a spent one's back 1.5 s after; in Team Deathmatch it's back 73 s after, and half way there as a match starts | Confirmed (250: Patch 5.12); community (one, 73 s, half way: the wiki) |
| In hand | Q puts the orb in the fifth slot, ready 1.1 s later; Q again or a number key puts it away, with nothing spent. Alt fire sends nothing. With it you run at the knife's speed | Confirmed (equipped: Patch 1.0); community (1.1 s: the wiki); estimate (the speed) |
| Fire | Once it's ready, fire, held too, sends it from the eye along the crosshair: its charge is spent, it's put away and the gun's back 0.7 s later | Community (fire, 0.7 s: the wiki) |
| The flight | Appearing 4.5 m ahead of the eye, then straight on at 20 m/s for 25 m from there, 1.25 s, and gone. Nothing stops or turns it, the level, clouds, walls and bodies alike, and the thrower's movement doesn't carry into it | Confirmed (20 m/s, 25 m: Patch 11.08; no movement: Patch 7.04; through walls: the agent page; ahead: Patch 4.04); estimate (4.5 m, from where it appears) |
| Whom it touches | Everyone whose head, body or legs comes within 4.3 m of its middle on the way, once each: players in play, Omen and his side too, and the practice dummies. Looking straight down, Omen touches himself | Community (4.3 m, allies and self: the wiki); estimate (the three points) |
| The warning | Whoever stands in its path as it shows on their screen, allies too: shadow at their screen's edges, fading over 0.6 s | Confirmed (warned as it's sent: Patch 1.0); estimate (allies, its look and time) |
| The nearsight | Whole for 2 s from the touch: nothing past 7.5 m but darkness. Then it clears over 0.5 s. A second touch while any is left runs it on | Community (2 s, 7.5 m, the dark: the wiki); estimate (0.5 s, running on) |
| Deafened | While it lasts, the world's sounds and your own are muffled by a 400 Hz low-pass and turned down about 9 dB, clearing with the dark; hit sounds and the touch's tone aren't | Community (deafened: the wiki); estimate (the numbers) |
| The minimap | While it's whole, their minimap and big map are covered in dark and they're told of nobody; their sight spots nobody further than 7.5 m for their side | Community (obscured: the wiki); estimate (the rest) |
| A flash | While it's whole, a Curveball popping further than 7.5 m from their eye doesn't blind them | Community (the wiki) |
| What clears it | A death, a new life, and a Phoenix's body gone in Run it Back; a thrower's orbs in flight go as they start a new life | Estimate |
| Who hears it | The orb sent: anyone near enough to hear it, out to 30 m, as other casts. The touch: a tone for whoever's touched | Estimate |
| Its look | In hand, a dark violet orb with a flat band of shadow through it over an open hand; in flight, a see-through ball of shadow 8.6 m across with a darker core; on others nearsighted, a wisp of shadow round the head; the nearsight's dark, a shell round the camera that draws back and thins away as it clears | Estimate (ours) |
| Its sounds | A thick, low whoosh as it comes into hand; a heavy whoosh slowed right down as it's sent; a slowed tone as it touches you | Estimate (ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** makes Paranoia played: its cost, confirmed now (Patch 5.12), its weapon and
  its line on Omen's card, and `Paranoia` (the unequip, the offset, the speed, the travel, the
  radius, and the nearsight's duration, vision and fade), each with its status and source.
- **`WeaponConfig`** adds `blindorb`, the orb in hand, 32nd of the weapons' wire ids.
- **`ParanoiaSim`** is new: the orb sent (`send`), its flight (`flight`, `at`), whom it touches
  (`touches`, `inPath`) and the nearsight (`nearsight`, `darkAt`, `whole`, `range`), kept as an
  attribute (`encode`, `decode`).
- **`AbilitySim`** plays Paranoia as it plays the other orbs: Q puts it in hand, and fire once it's
  ready is a `paranoia` cast from the eye along the crosshair.
- **`Sight`** takes how far a viewer sees (`range`): nobody further is seen.
- **`SoundConfig`** and **`SoundMath`** add the sounds and how the deafened hear (`Deafen`,
  `deafened`).

### The server

- **`ParanoiaServer`** is new. Each orb sent flies on the server's clock, and every client is told
  of it at once (the `flight`: where from, which way and when). Each server frame, whoever its
  middle has come within its radius of since the last is touched, at the pose the snapshots show,
  and a touched player is nearsighted, their `VFNearsight` attribute. It goes with a death, a new
  life and a Phoenix's body gone in Run it Back (`clear`), and once an orb has flown, the thrower's
  `VFLastParanoia` is whom it touched.
- **`MinimapServer`** spots nobody further than a nearsighted player's vision for their side, and
  tells them of nobody while it's whole; **`FlareServer`** blinds no nearsighted player with a pop
  further away than that.
- **`RunItBackServer`** clears a nearsight with a Phoenix's body gone.

### The client

- **`ParanoiaView`** is new. It flies your own orbs at once and others' as their send reaches your
  screen, warns you if you stand in one's path as it shows, and draws the nearsight on your screen
  or the watched player's: the dark round the camera, the deafening and the tone. Others nearsighted
  get a wisp. The dark is a shell of 120 thin slabs round the camera, each square to the way out to
  it, spread evenly so that whichever way the camera looks the nearest is no more than 3% further
  out than the vision. A ball turned inside out isn't seen from inside: Roblox draws a sphere mesh
  scaled by -1 as an ordinary ball, as the Studio checklist's PA5 found.
- **`SoundEngine`** gives the World and Self buses a low-pass after them, open but while you're
  deafened (`setDeafened`), and **`MinimapView`** covers the minimap and the big map in dark as the
  nearsight on your screen has it.
- **`AbilityEffects`** plays the orb sent, as it plays any cast, and **`WeaponLooks`**,
  **`GameSounds`** and **`SoundConfig`** give the orb in hand its look and the sounds.

### Not here yet

- **Deployed abilities.** Nothing deployed here has a field of vision for it to nearsight.
- **The fog of war.** It still sends a nearsighted player whoever's past the dark; only the dark
  hides them.
- **Hidden effects.** Enemy abilities' screen effects aren't hidden from the deafened.
- **The minimap's orb.** The orb in flight isn't drawn on the minimap.
- **The rest of his kit.** Shrouded Step and From the Shadows are on his card and the bar but not
  played yet.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | Paranoia played; `Paranoia`'s numbers, each with its status and source; `unequip` |
| `src/shared/Weapons/WeaponConfig.luau` | `blindorb`, the orb in hand, and its wire id |
| `src/shared/Abilities/ParanoiaSim.luau` | New: the orb sent, its flight, whom it touches and the nearsight |
| `src/shared/Abilities/AbilitySim.luau` | Paranoia played, and its `paranoia` cast |
| `src/shared/Combat/Sight.luau` | How far a viewer sees |
| `src/shared/Audio/SoundConfig.luau`, `src/shared/Audio/SoundMath.luau` | The orb's draw, the send and the tone; how the deafened hear |
| `src/server/ParanoiaServer.luau` | New: orbs flown and told of, whom they touch, the nearsights, `VFLastParanoia` and `clear` |
| `src/server/MinimapServer.luau`, `src/server/FlareServer.luau` | The nearsighted in the minimap's spotting and in the Curveball's blind |
| `src/server/RunItBackServer.luau`, `src/server/init.server.luau` | A nearsight cleared with a Phoenix's body gone; `ParanoiaServer` started and stepped |
| `src/client/ParanoiaView.luau` | New: the orbs in flight, the warning, the nearsight and the wisps |
| `src/client/Audio/SoundEngine.luau`, `src/client/Audio/GameSounds.luau` | The World and Self buses muffled; the tone |
| `src/client/MinimapView.luau` | The minimap and big map covered |
| `src/client/Combat/WeaponLooks.luau`, `src/client/AbilityEffects.luau`, `src/client/init.client.luau` | The orb in hand; the send's sound; the view started |
| `tests/paranoia.luau` | New: its numbers, the orb in hand and its send, the flight, whom it touches and who's warned, the nearsight and its attribute, how far the nearsighted see, and how the deafened hear |
| `tests/arsenal.luau`, `tests/darkcover.luau` | The weapons' ids, and what of Omen's kit is played |

## 7. Debug tools

- A player's `VFNearsight` is their nearsight while any of it is left: when it began, when it stops
  being whole and when it's gone, in server time (`812.500,814.500,815.000`).
- A player's `VFLastParanoia` is whom their last orb touched, set once it's flown: their names in
  the order it touched them, comma-separated, and empty for nobody.
- `Workspace.VFParanoia` holds each orb in flight as an `Orb` ball with its `Core`, the dark round
  the camera as `Dark`, a model of `Slab` parts, and each wisp as a `Wisp` with its player's name as
  its `Player` attribute; PlayerGui's `VFParanoia` has the warning, `Warn`.
- The minimap's ScreenGui, `VFMinimap`, has `Dark`: how covered it is, 0 to 1.
- SoundService's `VFSound` has the `world` and `self` buses' low-passes, `worldMuffle` and
  `selfMuffle`, bypassed but while you're deafened, when their Frequency drops to 400 and the buses'
  Volume to 0.35.
- `VFKit` reads `Q1/1` with its charge, and ends in `equip` while the orb's in hand.
- `VFTestButtons` 8192 presses Q, 128 the left button and 256 the right, so the orb can be readied
  and sent without a key or a mouse button; `VFTestYaw` and `VFTestPitch` aim.

## 8. Refinement loop

1. Step through clips of it sent alongside walls, and set `offset`.
2. Note where it ends down a marked corridor, and keep or change reading `travel` from where it
   appears.
3. Step through clips of a nearsight ending, and set `fade`.
4. Compare recordings of shots heard deafened and not, and set `Deafen`'s cutoff and volume.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Paranoia lit on Omen's card and the bar, with `Q1/1` on the course, and in hand 1.1 s after Q.
- Sent with fire: appearing ahead, flying 25 m down the lane in 1.25 s and gone, the gun back 0.7 s
  after, and whom it touched in `VFLastParanoia`.
- Through walls: the dummies behind the wallbang lane's walls touched.
- The nearsight on your own screen: dark past 7.5 m whichever way you look, the sky too, a shell of
  shadow round the camera seen from inside, the tone, the muffling and the minimap covered, all
  clearing after 2 s.
- With other players: the warning in its path, an enemy nearsighted and deafened, their minimap
  telling them of nobody, the wisp, a far flash not blinding them, and the charge bought for 250.

Section 45 of the [Studio checklist](../studio-checklist.md) covers these.
