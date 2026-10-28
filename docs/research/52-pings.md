# System 52: Pings

In the reference, a player marks things for their side without a word. Tapping the ping key (Z by
default) pings what the crosshair's on: an enemy, the spike, a gun on the ground, or the place
itself. Holding it opens a wheel of calls to pick from with the mouse. With the map open, a click
pings a place on it. Each ping shows where it is for the pinger's side, with a sound, and only so
many come in quick succession. Since Patch 9.11, a smoke stops a ping along the crosshair, and a
ping made on the map shows on the map alone. Until now ours had no pings. This system adds them. Z
tapped pings what the crosshair's on, judged on the server as a shot is. Z held opens a wheel of
four, Danger, Watching, Pushing and Need support, that the mouse picks from. With the big map up
(Caps Lock), the mouse moves a white cursor across it, and a left click pings the place under it,
dead or alive. Each ping goes to the pinger's side, with a beep, or a ding for the map's. It shows
on the minimap and the big map and, but for the map's, in the world, as a diamond with a word over
it and how far away it is under it.

As before, everything comes from public sources: Riot's patch notes (0.47, 0.49, 0.50, 1.0, 8.11 and
9.11) and support site and, for what Riot doesn't give, guides (Gfinity, The Global Gaming and
DostGame), the press (Dot Esports, Dexerto and Forbes) and threads on VLR.gg. No game files, memory
or network traffic were used, and nothing was read from the live game. Riot gives the ping key, what
it pings, the wheel, the limit, the fading under the crosshair, the smokes and where a map ping
shows; the community gives the key's default, the wheel's options and how to ping on the map.
Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes and support site) |
| **Community** | Published by a guide, the press or players, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source we could read says how many pings come before the limit or how fast they come back, how
long a ping shows, how long the key is held before the wheel opens, or what a marker says. Ours, in
section 4: four, then one more each 1.5 seconds; 4 seconds; a quarter of a second; and a word for
what it marks, with how far away it is. The reference's icons and its agents' voice lines are Riot's
art and recordings, so ours has a diamond and a word in their place, and a beep and a ding from
Roblox's free library as stand-ins.

## 1. Observable behaviour

- **The ping key** (Riot and the community). Riot Support: "Tapping a designated Ping Key will ping
  whatever you're looking at.", and "Spikes, weapons…hell, even a particularly striking wall if
  you're feeling contemplative." Gfinity: the key is the one "which is 'Z' by default"; "With your
  sight centred on the enemy, just quickly tap your ping hotkey (again, 'Z' by default) to alert
  your team." DostGame: "Aim at a dropped weapon or the Spike to tell teammates where the item is."
- **The ping wheel** (Riot and the community). Riot Support: "When in-game, you can pull up the Ping
  Wheel with your assigned hotkey.", and "You can scroll using your scroll wheel (big surprise),
  showing the Combat, Social, and Strategic pings available to you." DostGame: "Tap for a quick
  marker; hold the key to open the ping wheel and choose a more specific callout.", and "Hold your
  assigned Ping key, move toward the command you want and release or confirm it." The Global Gaming:
  "Additionally, if you hold down the Z key or the ping button, a radial menu, called a ping wheel,
  will pop up.", among its calls "Danger incoming", "Watching area", "I am pushing the area" and
  "Need support", with a caution sign, an eye, a clock and a flag. Patch 0.50: "Icon for Need Help
  changed from the little bug thing to a flag".
- **Pinging on the map** (Riot and the community). The Global Gaming: "Hold Caps Lock (the default
  button) to open the in-game map.", "Move your cursor to the spot you want to mark." and
  "Left-click to ping that location." Patch 0.50: "When using the ping wheel on the map, right
  clicking now correctly cancels the action and does not place a ping". Patch 9.11: "Pings made on
  your map will no longer appear in the world and only display on the minimap.", with "new ping
  visuals and new ping sound" "for pings made on the map."
- **While dead** (the community). The Global Gaming: "Luckily, Riot Games have added a feature for
  pinging even though you're dead." Since Patch 9.11, a player on VLR.gg: "I can't ping stuff for
  teammates anymore if I'm dead"; another: "players still can ping, but only visible on the mini
  map."
- **Smokes** (Riot). Patch 9.11: "Smokes will block your in-world pings from traveling through them
  and instead land on the smoke." Forbes: "Smokes will now block pings sent in world, resulting in
  your marker landing on the edge of the smoke itself".
- **The limit** (Riot and the community). Patch 0.47: "Fixed a bug where players could spam pings,
  causing frame rate drops for teammates". Dot Esports, on that patch: "Prior to the patch, there
  was no cap on the number of times players could ping the spike or a weapon on the ground.", and
  "Now, there will be a limit to how many times players can ping an item, similar to the cap placed
  on pinging locations." Patch 0.49: "Fixed a bug where ping wheel wouldn't show disabled when
  direct bound pings were used to reach usage limit". Patch 1.0: "Fixed a bug where the ping wheel
  on the megamap would not grey out when ping limited".
- **Under the crosshair** (Riot). Patch 0.49: "Ping elements now fade when under player aim;
  previously only text faded".
- **One wheel at a time** (Riot). Patch 0.49: "Fixed a bug where the Z ping wheel could be opened
  alongside the map ping wheel, creating a scenario" "where multiple ping wheels could be open at
  once".

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Fixed a bug where players could spam pings, causing frame rate drops for teammates" | [VALORANT Patch Notes 0.47](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-47/), 21 April 2020 |
| "Ping elements now fade when under player aim; previously only text faded"; "Fixed a bug where the Z ping wheel could be opened alongside the map ping wheel, creating a scenario" "where multiple ping wheels could be open at once"; "Fixed a bug where ping wheel wouldn't show disabled when direct bound pings were used to reach usage limit" | [VALORANT Patch Notes 0.49](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-49/), 28 April 2020 |
| "When using the ping wheel on the map, right clicking now correctly cancels the action and does not place a ping"; "Selecting a ping on the ping wheel and canceling no longer incorrectly spawns the canceled ping" "next time the player uses the basic ping"; "New artwork for pings to increase readability in the world"; "Icon for Need Help changed from the little bug thing to a flag" | [VALORANT Patch Notes 0.50](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-50/), 12 May 2020 |
| "Fixed a bug where the ping wheel on the megamap would not grey out when ping limited"; "Reduce cost of z-pings and death pings by 10x"; "Added chat message regulation so that only send one chat message is sent when multiples of the same ping" "or VO command are used in rapid succession" | [VALORANT Patch Notes 1.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-0/), 2 June 2020 |
| "to improve our Radio Command Wheels to include more relevant call-outs, a higher variety of pings and Agent VO"; "New Strategy Wheels during the Buy Phase"; "Unique Strategy Wheels for Attackers and Defenders"; "New Commands Wheel on the Megamap" | [VALORANT Patch Notes 8.11](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-811/), 11 June 2024 |
| "The in-game ping system was created with the simple goal of allowing players to communicate with one another" "without using their mic."; "Smokes will block your in-world pings from traveling through them and instead land on the smoke."; "Pings made on your map will no longer appear in the world and only display on the minimap."; "To help you differentiate these ping behaviors in game we’re introducing new ping visuals and new ping sound" "for pings made on the map." | [VALORANT Patch Notes 9.11](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-11/), 10 December 2024 |
| "Tapping a designated Ping Key will ping whatever you're looking at."; "Spikes, weapons…hell, even a particularly striking wall if you're feeling contemplative."; "When in-game, you can pull up the Ping Wheel with your assigned hotkey."; "You can scroll using your scroll wheel (big surprise), showing the Combat, Social, and Strategic pings available to you."; "There, you can hotkey both the Ping Wheel itself, as well as individual and specific notifications" "that may be extra valuable (such as Need Support)." | [Riot Support, Ping System](https://support.riotgames.com/en-us/valorant/gameplay/ping-system), 26 February 2024 |

### From the community

| What | Source |
| --- | --- |
| The key "which is 'Z' by default"; "With your sight centred on the enemy, just quickly tap your ping hotkey (again, 'Z' by default) to alert your team." | [Gfinity, how to ping](https://www.gfinityesports.com/article/valorant-how-to-ping-warn-enemies-guide-reveal-pc), 2 June 2020, updated 21 October 2024 |
| "Additionally, if you hold down the Z key or the ping button, a radial menu, called a ping wheel, will pop up."; "Danger incoming"; "Watching area"; "I am pushing the area"; "Need support"; "In Valorant, you can ping enemies by pressing the Z key while looking in their direction."; "Hold Caps Lock (the default button) to open the in-game map."; "Move your cursor to the spot you want to mark."; "Left-click to ping that location."; "Luckily, Riot Games have added a feature for pinging even though you're dead." | [The Global Gaming, how to mark](https://theglobalgaming.com/valorant/how-to-mark), updated 9 March 2024 |
| "Tap for a quick marker; hold the key to open the ping wheel and choose a more specific callout."; "Hold your assigned Ping key, move toward the command you want and release or confirm it."; "Aim at a dropped weapon or the Spike to tell teammates where the item is."; "Smokes also block in-world pings, which land on the smoke instead of travelling through it." | [DostGame, how to ping](https://www.dostgame.com/en/blog/valorant-isaretleme-nasil-yapilir), 29 January 2024 |
| "Prior to the patch, there was no cap on the number of times players could ping the spike or a weapon on the ground."; "Now, there will be a limit to how many times players can ping an item, similar to the cap placed on pinging locations." | [Dot Esports, the ping spam fix](https://dotesports.com/valorant/news/todays-valorant-patch-fixes-ping-spam-issue-that-causes-frame-drops) |
| "by holding down Z (by default) or holding Period for a more expansive list."; "So instead of your Agent calling out 'here' every time you ping a location"; a Riot developer, quoted: "The regions already appear in chat, but having the characters say the regions out loud will make a big difference." | [Dexerto, the ping system's overhaul](https://www.dexerto.com/valorant/valorant-ping-system-set-for-major-tactical-overhaul-1403965/), 10 August 2020 |
| "Smokes will now block pings sent in world, resulting in your marker landing on the edge of the smoke itself" | [Forbes, Patch 9.11](https://www.forbes.com/sites/mikestubbs/2024/12/10/valorant-911-patch-notes-bring-major-neon-nerf-ping-system-rework/), 10 December 2024 |
| "The ping still shows on the mini map."; "players still can ping, but only visible on the mini map." | [VLR.gg, new ping system](https://www.vlr.gg/431248/new-ping-system) |
| "I can't ping stuff for teammates anymore if I'm dead" | [VLR.gg, ping changes are literally fine](https://www.vlr.gg/427488/ping-changes-are-literally-fine) |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How many pings come before the limit, and how fast they come back | Public clips of a player pinging over and over: the pings before the wheel greys out, and the time until it's lit again |
| How long a ping shows, in the world and on the map | Public clips: from a ping's sound to its marker gone |
| How long the key is held before the wheel opens | Public clips with the keys shown on screen |
| What a marker shows for each thing pinged and each call | Public clips since Patch 9.11 |
| Whether an enemy's marker follows them | Public clips of an enemy pinged on the move |
| Where a ping lands from inside a smoke | Public clips since Patch 9.11 |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| The ping key | Z, tapped (let go within 0.25 s): a ping along the crosshair | Confirmed (Riot Support: "Tapping a designated Ping Key"); community (Z: Gfinity, The Global Gaming) |
| What it marks | The nearest along the crosshair of an enemy in sight whose body it passes within 0.4 m of, and the spike (dropped or planted) or a gun on the ground, in sight, whose middle it passes within 0.4 m of; otherwise the place where it stops | Confirmed (Riot Support: "Spikes, weapons…hell, even a particularly striking wall"); community (an enemy: Gfinity, The Global Gaming); estimate (0.4 m) |
| How it's judged | On the server: from its own eye for the pinger, along the look the client sent if that's within 10° of the server's own; the enemies as the pinger's screen showed them, as for a shot (lag compensation), and pinged only with some part of them in sight past the level, the clouds and smokes and the walls of fire and ice | Estimate |
| How far it goes | As far as the level, Sage's walls in it, through the spawns' barriers, and 200 m at the most. Nothing in the way (the sky): no ping | Estimate |
| Flying the Owl Drone | A ping goes from the drone, along its view | Estimate |
| Smokes | Jett's clouds and Omen's smokes stop it at their edge, where it lands; from inside one, where it comes out | Confirmed (Patch 9.11: "instead land on the smoke"; Forbes: "on the edge of the smoke itself"); estimate (from inside) |
| The wheel | Z held 0.25 s opens four calls round the middle of the screen: Danger at the top, Watching at the right, Pushing at the bottom and Need support at the left. The mouse moves a pick instead of the view, and 30 px towards a call picks it; letting Z go pings it on the place the crosshair's on | Community (DostGame: "hold the key to open the ping wheel", "move toward the command you want and release or confirm it"; the calls: The Global Gaming); estimate (where each sits, and the numbers) |
| Putting the wheel away | Right click, or letting Z go with nothing picked: nothing's pinged. Dying, a menu or the big map puts it away too | Estimate (as the reference's map wheel: Patch 0.50) |
| One wheel at a time | Z does nothing while the big map's up, and the big map coming up puts the wheel away | Confirmed (Patch 0.49: "multiple ping wheels could be open at once" was a bug) |
| The wheel's pages | One page of four | Not here yet (Riot Support: "Combat, Social, and Strategic pings") |
| Pinging on the map | With the big map up (Caps Lock), the mouse moves a white cursor across it instead of the view, from its middle; a left click pings the place under it. Not on From the Shadows' map | Community (The Global Gaming: "Move your cursor to the spot you want to mark.", "Left-click to ping that location.") |
| Where a map ping shows | On the minimap and the big map alone, as a disc ringed in white, with a sound of its own | Confirmed (Patch 9.11: "only display on the minimap", "new ping visuals and new ping sound"); its look and its sound are ours |
| While dead | Map pings; no Z | Community (The Global Gaming: "pinging even though you're dead"; VLR.gg since Patch 9.11: "players still can ping, but only visible on the mini map.") |
| The limit | Four in quick succession, then one more each 1.5 s, each ping spending one whatever it marks and however it's made, counted on the server; the client counts too, and asks for none with none left | Confirmed (a limit: Patches 0.47 and 0.49); community (Dot Esports: "similar to the cap placed on pinging locations"); estimate (the numbers) |
| Greyed out | The wheel's calls go grey while none are left, and pick nothing | Confirmed (Patch 0.49; Patch 1.0: "would not grey out when ping limited") |
| Who sees it | The pinger's side, the pinger too; on the course, the pinger alone | Community (Gfinity: "to alert your team") |
| In the world | A diamond where it is, its word over it and how far away it is under it, in metres. The words: `HERE`, `ENEMY`, `SPIKE`, the gun's name, or the call's (`DANGER`, `WATCHING`, `PUSHING` or `NEED SUPPORT`). An enemy's in the enemies' colour, the spike's orange, yours pale yellow and a teammate's in your side's colour | Estimate (in place of Riot's icons) |
| Under the crosshair | A marker within 48 px of the crosshair is 70% see-through, its word too | Confirmed (Patch 0.49: "Ping elements now fade when under player aim; previously only text faded"); estimate (the numbers) |
| How long | 4 s, fading away over the last 0.5 s | Estimate |
| An enemy pinged | The marker stays where they were as they were pinged | Estimate |
| On the maps | Each ping on the minimap and the big map in its colour, a diamond (the map's a disc), held on the minimap's edge while off it | Estimate |
| Sounds | A beep for each ping and a ding for each map ping, on the UI bus | Confirmed (a sound of the map's own: Patch 9.11); estimate (both, stand-ins) |

## 5. Design

### The rules

- **`Pings`** (new) has the rules, with no Roblox APIs: `resolve` judges a ping along the crosshair
  from the eye, the look, how far the level lets it go, the clouds and smokes, the enemies as posed,
  what's on the ground and what hides what; `cloudAt` finds where a ray meets a cloud's edge;
  `aimFrom` picks the look a ping's judged along; `newBudget`, `left` and `spend` keep the limit;
  `pick` finds the call the mouse has moved towards; and `word`, `tag` and `transparency` say how a
  ping shows. Its numbers are in `Pings.Params`, each with its status and source.

### The server

- **`PingServer`** (new) answers the `Ping` remote. A ping along the crosshair (`look`) comes with
  the wheel's call, if one was picked, the yaw and pitch it was made with, and the time the pinger's
  screen showed (its `viewTime`); it's the living's alone. It's judged from the server's eye for the
  pinger (`PlayerSimServer.view`), on the level as for a shot (`CombatServer.levelFor`, past the
  spawns' barriers), with the clouds and smokes standing (`CloudServer.standing`), the enemies
  rewound as for a shot (`CombatServer.rewound`), what's in the way of sight (`Sight.hidden`: the
  level as the fog of war has it, the clouds and smokes, and the walls of fire and ice), the spike
  where it lies and the guns on the ground. A ping on the map (`map`) is anyone's, at a point on the
  map being played (`Minimap.holds`). Each spends one of the player's pings, and goes to everyone on
  the pinger's side (`ArenaConfig.SIDE`), the pinger too.
- **`GroundGunsServer.guns`** lists the guns on the ground, by id.
- **`Remotes`** has `Ping`, both ways.

### The client

- **`PingView`** (new) has Z, tapped and held; the wheel (`VFPingWheel`); the big map's cursor,
  which the mouse moves instead of the view, and its left click; the limit, counted as the server
  counts it; the markers in the world (`VFPings`); and each ping's sound. `PingView.shown` and
  `PingView.cursor` give the maps what to draw.
- **`MinimapView`** draws each ping and the cursor on the minimap and the big map, and tells
  `PingView` while the big map's up to ping on, which it isn't while From the Shadows' map is.
- **`ShadowView`** lets go of the mouse only while it's its own (`CameraController.mapCursor`), so
  From the Shadows' map and the pings don't take it from each other.
- **`Spectate`** doesn't switch players on a click while the mouse moves a cursor on the big map.
- **`SoundConfig`** and **`GameSounds`** have the beep and the ding.

### Not here yet

- **The wheel's pages.** Riot Support: "You can scroll using your scroll wheel (big surprise),
  showing the Combat, Social, and Strategic pings available to you." Ours has one page of four.
- **A key for each call.** Riot Support: "There, you can hotkey both the Ping Wheel itself, as well
  as individual and specific notifications". Ours has Z alone.
- **The map's own wheel and the radio commands.** Patch 8.11 brought a "New Commands Wheel on the
  Megamap" and "New Strategy Wheels during the Buy Phase", and the radio wheel has a key of its own
  (Dexerto: "holding Period for a more expansive list."). Ours pings a place on the map with a
  click, and has no radio commands.
- **Voice lines and chat.** In the reference an agent calls out a ping (Dexerto: "instead of your
  Agent calling out 'here' every time you ping a location"), and it goes in the team's chat with its
  place's region (a Riot developer: "The regions already appear in chat"). Ours has a sound alone,
  and the big map's region names (system 34) aren't used.
- **Off screen.** A marker behind the camera or off the screen isn't drawn, nor pointed to from the
  screen's edge.
- **Following an enemy.** An enemy's marker stays where they were as they were pinged.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/Pings.luau` | New: the rules: a ping along the crosshair judged, a cloud's edge, the look, the limit, the wheel's pick, and how a ping shows |
| `src/server/PingServer.luau` | New: the `Ping` remote's pings judged and sent to the pinger's side |
| `src/server/GroundGunsServer.luau` | `guns`, the guns on the ground |
| `src/shared/Net/Remotes.luau` | `Ping` |
| `src/client/PingView.luau` | New: Z, the wheel, the big map's cursor and its click, the limit, the markers and the sounds, and `VFPings` |
| `src/client/MinimapView.luau` | The pings and the cursor on the minimap and the big map, and the `Pings` attribute |
| `src/client/ShadowView.luau`, `src/client/CameraController.luau` | The mouse shared between From the Shadows' map and the pings |
| `src/client/Spectate.luau` | No switching on a click while the big map's cursor is up |
| `src/shared/Audio/SoundConfig.luau`, `src/client/Audio/GameSounds.luau` | The beep and the ding |
| `src/server/init.server.luau`, `src/client/init.client.luau` | `PingServer` and `PingView` started |
| `src/client/Debug/TestAim.luau` | `VFTestPing`, and `VFTestMapPoint` for the big map's cursor |
| `tests/pings.luau`, `tests/run.luau` | New: 76 checks: the numbers, places, the sky and reach, smokes, enemies, guns and the spike, the wheel's calls, the look, the limit, the wheel's pick, and the words, tags and fading |

## 7. Debug tools

- PlayerGui's `VFPings` carries `Shown` (the markers on screen, each as its word and how far away it
  is: `HERE 12m, ENEMY 30m`), `Left` (the pings left, whole), `Wheel` (empty while it's shut,
  `open`, or the call picked) and `Cursor` (where the big map's cursor is, in metres, while it's up
  to ping on).
- `VFMinimap` carries `Pings`, the pings on the minimap in the order they came, by their tags
  (`place,map`); their icons are named `Ping_<id>`, and the big map's cursor's `Cursor`.
- `VFTestPing` set to `tap` pings as tapping Z does; to `danger`, `watching`, `pushing` or `help` as
  letting Z go with that call picked; to `wheel` opens the wheel as holding Z does; to `shut` puts
  it away as right click does; and to `map` pings as a left click on the big map does, where its
  cursor is.
- `VFTestMap` holds the big map up, and `VFTestMapPoint` (metres) puts its cursor nearest that
  place.

## 8. Refinement loop

1. Find a public clip of a player pinging over and over, count the pings before the wheel greys out
   and time how fast they come back, and set `budget` and `refill`.
2. Time a ping in a public clip, in the world and on the map, and set `duration` and `fadeOut`.
3. Draw the wheel's other pages and the radio commands from public clips.
4. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Z tapped at the floor, the sky, an enemy, a gun and the spike: a marker for each but the sky's,
  with its word and how far away it is, and a beep.
- Z held: the wheel, its pick, and a call pinged where the crosshair is; right click putting it
  away.
- The limit: four in quick succession, then the wheel greyed, and one more back after 1.5 s.
- A marker faded under the crosshair, and gone after 4 s.
- A cloud stopping a ping at its edge, and an enemy behind one not pinged.
- Pings seen by the pinger's side alone, in the world and on both maps.
- The big map's cursor and a left click: a ping on the maps and not in the world, with its ding.
- While dead: map pings, and no Z.

Section 56 of the [Studio checklist](../studio-checklist.md) covers these.
