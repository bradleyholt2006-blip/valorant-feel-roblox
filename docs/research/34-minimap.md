# System 34: The minimap

The minimap sits at the top left of the screen. It shows the map from above, you and your side on
it, the enemies your side sees, the spike, the clouds, walls of fire and fires that are out, and a
white circle as far as the sounds you make are heard. Holding Caps Lock opens the big map over the
middle of the screen, with the names of the places on it. This system adds both, drawn from each
level's own plan, and the server's spotting that decides which enemies each side sees: twenty times
a second, through the level, the clouds and the walls of fire, with nobody blinded white seeing
anyone. It also adds the reference's map settings to the settings menu.

As before, everything comes from public sources: seven of Riot's patch notes (0.50, 1.0, 1.02, 2.06,
5.08, 6.07 and 10.03), a Riot developer's replies on 0.50, Riot's UI settings FAQ and Riot's tech
blog on the fog of war; then the VALORANT Wiki's pages on the Spike, Deathmatch and status effects,
and guides from thespike.gg, setup.gg, Dignitas, 1v9.gg, ONE Esports, ludo.guide, Sportskeeda,
Mobalytics, techweez and Shacknews, with win.gg, PCGamesN and VLR.gg on its bugs. No game files,
memory or network traffic were used. Riot says what shows and names the settings, but gives almost
no numbers: how long anything stays, how far the cones reach and how often any of it is worked out
are ours. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes, support pages, tech blog or a developer's post) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **Where it is** (ONE Esports, Patch 5.08 and Shacknews). "On the upper left side of your screen,
  you will see a minimap." The larger map is "defaulted to Caps Lock and 'M'" (Patch 5.08);
  Shacknews lists "Open Map (Toggle)" on M and "Open Map (Hold)" on Caps Lock.
- **You and your side** (Patch 0.50, ludo.guide and Patch 5.08). Patch 0.50 "Added color to the
  player's own minimap icon with a slightly thicker border to aid in finding oneself". In
  ludo.guide's account, you're a solid arrow and your teammates solid arrows in your team's colour,
  with faint cones from them for where they look. An ally off the minimap is held on its edge: 5.08
  fixed "Ally position indicators would persist on the edge of minimap even after ally came back
  into view". techweez: "When a teammate dies, their death marker appears on the minimap with a red
  X."
- **Enemies** (ludo.guide, Sportskeeda, Patch 5.08 and Patch 6.07). An enemy shows while they're
  "visible to you or a teammate" (ludo.guide), detected as they "appear in their vision cone"
  (Sportskeeda). Where one was last seen stays a while: 5.08 fixed "\"Recently Seen Enemy\" icon
  indicators could sometimes update their position without the enemy being visible". And nothing out
  of sight should show: 6.07 fixed "teleport abilities can reveal an Agent's out-of-sight minimap
  location" under packet loss, and 1.02 "enemy players would appear on the minimap while watching
  the Spike, once your team was dead".
- **The spike** (the wiki, Patch 0.50 and Mobalytics). "A dropped spike is visible on the minimap to
  Attackers, and to Defenders while they have sight of it." 0.50 "Removed Spike icon from being
  visible on enemy player minimap icons", and a Riot developer explained: "You won't see enemies
  carrying the spike on the minimap", "Dropped spike still shows, though", and "Dropped spike icon
  should be fairly easy to spot - it's pretty large compared to the other icons." Mobalytics:
  attackers see "the spike carrier in yellow on your minimap"; for defenders it "will remain on your
  minimap as long as someone from your team has line of sight on it." ludo.guide marks it when it's
  planted or dropped.
- **The white circle** (Patch 1.0, ONE Esports and the wiki). Patch 1.0 "brought in more sounds made
  by Agents under the category of sounds that display their audio distance on the mini-map", "via
  the white circle": "This includes ability sounds, reloads, spike interactions and more." ONE
  Esports: a small circle round you while you move, where your footsteps can be heard; "Anyone
  outside of this white circle can't hear you." The wiki: the audio range is "also displayed on the
  minimap as a circle around the player."
- **Vision cones** (Dignitas, Patch 6.07 and win.gg). Minimap Vision Cones "Shows the current
  Field-of-View of the players" (Dignitas). 6.07 fixed "vision cones of vertical wall-type abilities
  (Phoenix's Blaze (C), Viper's Toxic Screen (E), Harbor's High" Tide flickering on the minimap, so
  a wall of fire cuts a cone. win.gg reported cones that don't match what's seen, from Haven's mid
  window and Ascent's mid top.
- **Utility** (Patch 1.0, Patch 2.06 and ludo.guide). "Friendly Barrier Orb walls now show on the
  minimap" (1.0); "Poison Cloud's landing location is shown on the minimap while equipped" (2.06).
  ludo.guide: only some abilities show.
- **The settings** (Riot's UI settings FAQ, thespike.gg, setup.gg, Dignitas and 1v9.gg). Settings,
  General, Map: Rotate (Rotate or Fixed), Fixed Orientation (Always the Same or Based on Side, for a
  fixed map), Keep Player Centered, Minimap Size, Minimap Zoom, Minimap Vision Cones and Show Map
  Region Names. Dignitas lists Rotate, "If the map rotates according to the way you're facing or
  not", apart from Keep Player Centered, "Have your map dot on the center of the map or not". Region
  names: "This setting only affects the megamap that shows up when you press m, not the minimap in
  your HUD", with "Always", "Only in Buy Phase" and "Never" (the FAQ). On console, setup.gg says,
  Keep Player Centered is forced on above a zoom of 1.0.
- **Deathmatch** (the wiki). Players "receive a brief pulse on their minimap showing the location of
  all enemy players" as they respawn; 1.10 "Removed periodic location pulse, and you'll now only
  receive a pulse right when you respawn."
- **Its look** (Patch 10.03). "Minimap visual language has been updated for increased clarity and
  fidelity"; Insider Gaming: it "now uses shading to clearly show elevated spots across the whole
  map, as well as ziplines."

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Removed Spike icon from being visible on enemy player minimap icons"; "Added color to the player's own minimap icon with a slightly thicker border to aid in finding oneself" | [VALORANT Patch Notes 0.50](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-50), 12 May 2020 |
| A Riot developer on 0.50: "You won't see enemies carrying the spike on the minimap."; "Showing it was a bug."; "Dropped spike still shows, though."; "Dropped spike icon should be fairly easy to spot - it's pretty large compared to the other icons." | [devtrackers.gg's copy of the 0.50 thread](https://devtrackers.gg/valorant/p/cf4e359d-valorant-0-50-patch-notes) |
| "We've brought in more sounds made by Agents under the category of sounds that display their audio distance on the mini-map" "via the white circle"; "This includes ability sounds, reloads, spike interactions and more."; "We wanted to provide players with the ability to understand when their noise can be heard by enemies"; "Friendly Barrier Orb walls now show on the minimap"; "Fixed bug where minimap would calculate twice per frame" | [VALORANT Patch Notes 1.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-0/), 1 June 2020 |
| "Fixed a bug where enemy players would appear on the minimap while watching the Spike, once your team was dead" | [VALORANT Patch Notes 1.02](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-02/), 23 June 2020 |
| "Poison Cloud's landing location is shown on the minimap while equipped"; "the megamap now consistently uses a mouse pointer instead of a crosshair for map pings" | Patch 2.06, as [Liquipedia](https://www.liquipedia.net/valorant/Patch_2.06) copies it |
| "Fixed various minimap bugs:" "Ally position indicators would persist on the edge of minimap even after ally came back into view"; "Opening the larger map (defaulted to Caps Lock and 'M') during round transition" "could cause spawn barriers to appear as a single pixel"; "\"Recently Seen Enemy\" icon indicators could sometimes update their position without the enemy being visible" | [VALORANT Patch Notes 5.08](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-08) |
| "Fixed a bug in the minimap where teleport abilities can reveal an Agent's out-of-sight minimap location when under packet" loss; "Fixed issues where vision cones of vertical wall-type abilities (Phoenix's Blaze (C), Viper's Toxic Screen (E), Harbor's High" Tide flickered or warped on the minimap | [VALORANT Patch Notes 6.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-6-07) |
| "Minimap visual language has been updated for increased clarity and fidelity." | Patch 10.03, as [esports.gg](https://esports.gg/news/valorant/valorant-patch-10-03-delivers-a-sleek-new-visual-to-your-minimap/) quotes it |
| Show Map Region Names, at "Settings->General->Map->Show Map Region Names": "This setting only affects the megamap that shows up when you press m, not the minimap in your HUD."; "Always", "Only in Buy Phase" and "Never" | [VALORANT UI Settings FAQ](https://support.riotgames.com/en-us/valorant/gameplay/valorant-ui-settings-faq) |
| The server works out what each player can see and stops sending what they can't (the fog of war): first by casting rays to the corners of a body's box, its camera and its middle, then from precomputed sets of what each place sees. It doesn't mention the minimap | [Riot's tech blog on the fog of war](https://technology.riotgames.com/node/108) |

### From the community

| What | Source |
| --- | --- |
| "A dropped spike is visible on the minimap to Attackers, and to Defenders while they have sight of it."; the audio range is "also displayed on the minimap as a circle around the player."; 8.01 fixed "the white circle minimap indicator would not appear when the Spike was dropped" | [VALORANT Wiki, Spike](https://wiki.playvalorant.com/en-us/Spike) (Weird Gloop) |
| "receive a brief pulse on their minimap showing the location of all enemy players"; 1.10 "Removed periodic location pulse, and you'll now only receive a pulse right when you respawn." | [VALORANT Wiki, Deathmatch](https://wiki.playvalorant.com/en-us/Deathmatch) |
| Flash: "An agent with a Flash debuff has their vision replaced with an opaque, colored screen."; Deafen: "their minimap will become obscured"; Paranoia: "minimap obscured" | [VALORANT Wiki, Status Effect](https://wiki.playvalorant.com/en-us/Status_Effect) |
| The settings: Rotate or Fixed; Fixed Orientation, Always the Same or Based on Side, only when fixed; Keep Player Centered; Minimap Size (1.0 to 1.2 recommended); Minimap Zoom (0.9 to 1.0); Minimap Vision Cones; Show Map Region Names. It shows teammates and the way they face, the spike, and enemies once your team has spotted them | [thespike.gg](https://www.thespike.gg/valorant/maps/best-map-settings-in-valorant) |
| The same settings, none with a default; Size 1.0 to 1.2 and Zoom about 0.7 to 1.0 mentioned; on console "Keep Player Centered is forced On when zoom is above 1.0"; your footsteps' range shown while you move | [setup.gg](https://www.setup.gg/game/valorant/valorant-map-settings/) |
| Rotate: "If the map rotates according to the way you're facing or not"; Keep Player Centered: "Have your map dot on the center of the map or not"; Minimap Vision Cones: "Shows the current Field-of-View of the players"; Show Map Region Names: "Whether the map has written callouts or not" | [Dignitas](https://dignitas.gg/articles/blogs/valorant/14317/an-overview-of-all-valorant-settings-in-the-settings-menu) |
| Minimap Size "1.00 to 1.10", 1.04 recommended; Zoom 0.8 recommended; no defaults | [1v9.gg](https://1v9.gg/blog/valorant-best-map-settings) |
| "On the upper left side of your screen, you will see a minimap."; the full map on Caps Lock by default, with pings | [ONE Esports' HUD guide](https://www.oneesports.gg/valorant/user-interface-valorant-hud/) |
| A small circle round you while you move, where your footsteps can be heard: "Anyone outside of this white circle can't hear you." | [ONE Esports' minimap guide](https://www.oneesports.gg/valorant/valorant-minimap-guide-radar) |
| "Open Map (Toggle)": M; "Open Map (Hold)": Caps Lock | [Shacknews](https://www.shacknews.com/article/117434/valorant-pc-controls-and-keybindings) |
| Enemies show as red dots when "visible to you or a teammate"; you a solid arrow, teammates solid arrows in your team's colour, with faint cones for their lines of sight; the spike marked when planted or dropped; only some abilities shown | [ludo.guide](https://www.ludo.guide/guide/valorant/the-ultimate-tactical-fps-guide/2-7-minimap-usage-and-information-gathering) |
| An enemy is detected as they "appear in their vision cone"; the cones let "players view their teammates' range of vision" | [Sportskeeda](https://sportskeeda.com/valorant/valorant-minimap-guide-how-perfect-map-awareness-2022), 2022 |
| Attackers see "the spike carrier in yellow on your minimap"; for defenders a dropped spike "will remain on your minimap as long as someone from your team has line of sight on it." | [Mobalytics](https://mobalytics.gg/blog/valorant/valorant-spike-guide/) |
| "When a teammate dies, their death marker appears on the minimap with a red X." | [techweez](https://techweez.com/2026/01/24/how-to-master-the-valorant-minimap/), 24 January 2026 |
| Cones that don't match the view: Haven's mid window shows up the stairs to B, and Ascent's mid top shows mid bottom | [win.gg](https://win.gg/news/valorant-players-call-on-riot-to-fix-broken-vision-cones/) |
| Enemies shown the whole round, a bug: so normally they aren't | [PCGamesN](https://www.pcgamesn.com/valorant/gekko-bug-minimap); [VLR.gg](https://www.vlr.gg/post/1116396/spectator-bug-may-jeopardize-competitive-integrity), Riot: the minimap "would sporadically show opponents' locations to coaches" |
| "The minimap now uses shading to clearly show elevated spots across the whole map, as well as ziplines." | [Insider Gaming](https://insider-gaming.com/valorant-10-03-patch-notes-minimap-and-slow-ability-changes/) on Patch 10.03 |

No source says how the reference decides that someone is seen for the minimap (Riot's fog of war
decides what's sent, not what's drawn), which points of a body count, or how often it's worked out;
how long a Recently Seen Enemy icon stays or how it looks; how long Deathmatch's pulse lasts; how
far a cone reaches; which sounds draw the white circle beyond Patch 1.0's list; what utility shows
besides 1.0's and 2.06's, and whether an enemy's shows out of sight; the settings' defaults; or the
ranges of Size and Zoom (1v9.gg's 1.00 to 1.10 for Size is narrower than the 1.2 other guides
recommend). Ours are in section 4. Sportskeeda lists gunfire among what the minimap shows, apart
from suppressed shots, without saying whose or how; we read the white circle as Patch 1.0 lists its
sounds, and gunfire, heard across the map, draws none. Where Rotate is on and Keep Player Centered
off, the map here turns about its own middle, as Dignitas lists the two as separate settings; how
the reference turns it then is ours to check.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How long a Recently Seen Enemy icon stays, and how it looks | Clips with the minimap in shot, an enemy stepping out of sight, stepped frame by frame until the icon's gone |
| Deathmatch's pulse | Clips of a deathmatch respawn, from the respawn until the enemies go from the minimap |
| Which sounds draw the white circle, and how long it lasts | Clips of a player reloading, using abilities, planting and firing, the minimap in shot |
| How far a cone reaches | Clips of a long open sightline, the cone's tip against the map |
| The settings' defaults and ranges | A fresh account's Map settings, each slider to its ends |
| Rotate without Keep Player Centered | Clips with the setting known, the player turning on the spot |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Where it is | The top left, 12 px in, a square a quarter of the screen's height across at Minimap Size 1 | Community (the top left); estimate (its size) |
| The big map | Held Caps Lock, over the middle of the screen, 82% of its height across; M is the Play menu here (system 24), so it stays Caps Lock alone | Confirmed (Caps Lock and M, Patch 5.08); estimate (its size) |
| The map drawn | Each level's own plan from above: its floor, walls, cover (low and high), each spawn's floor (yours tinted in the allies' colour, the other in the enemies') and each site's plant area and letter. A map's minimap is always that map, as both are built from the same plan | Estimate (the look; Patch 10.03's shading isn't here) |
| Region names | The places' names on the big map only, by Show Map Region Names: Always, Only in Buy Phase (and Team Deathmatch's pre-game) or Never; no name on a door or a room under 30 m² | Confirmed (the FAQ); estimate (which rooms) |
| Rotate, Fixed and Based on Side | Rotate turns the map as you turn, so you look up it; Fixed keeps it still, Always the Same or with your spawn at the bottom (Based on Side: in deathmatch, with no spawn of your own, the same way) | Community (thespike.gg, setup.gg) |
| Keep Player Centered | On, you're in the middle; off, the map's middle is, and Rotate turns it about its middle. Past a zoom of 1 you're kept in the middle | Community (the setting, Dignitas; past 1, setup.gg on console); estimate (the turn about the middle, and past 1 on PC) |
| Size and Zoom | Size 0.8 to 1.2, Zoom 0.6 to 1.4; a zoom of 1 fits the whole map, 2 m round it, across the box | Estimate (the guides' values are inside them) |
| The defaults | Rotate, Based on Side, not centred, Size 1, Zoom 0.9, cones on, names Always: what the guides set | Estimate |
| You | An arrow the way you look, in a colour of its own with a thicker edge; while you spectate, whoever you look out of | Confirmed (Patch 0.50); estimate (spectating) |
| Your side | Arrows in the allies' colour the way each looks, held on the minimap's edge while off it; a red X where one died until they're back or the round's over | Community (ludo.guide, techweez); confirmed (the edge, Patch 5.08); estimate (how long the X stays) |
| Who sees whom | Everyone in play, from their eye, the way they look: a point is seen when it's in their view, 103 degrees across a 16:9 screen, and nothing's in the way. In the way: the level, but not the spawns' barriers, which are see-through, nor anyone's body; the clouds standing and the walls of fire. A body is seen when its head, body or legs' middle is | Community (seen by you or a teammate, in the cone; 103 degrees, system 1); estimate (the rest) |
| Who doesn't see | Nobody out of play (dead, or a Phoenix whose body's gone in Run it Back, system 33), and nobody a Curveball (system 30) has more than half white | Confirmed (not once your side's dead, Patch 1.02); community (a flash's opaque screen, the wiki); estimate (half white) |
| How often | The server looks 20 times a second, and tells each player what their side sees as it changes, dead or alive | Estimate |
| Enemies | A red dot on each enemy your side sees, where they're drawn; once they're not, a faded dot with a `?` where they were last drawn, for 3 s, unless they've died | Community (red dots, ludo.guide); confirmed (Recently Seen Enemy icons that stay put, Patch 5.08); estimate (3 s, the look, none for the dead) |
| The spike | Planted, shown to everyone; on the ground, to the attackers always and to the defenders while one of them sees it; carried, a mark on its carrier for the attackers only, never on an enemy | Community (the wiki, Mobalytics, ludo.guide); confirmed (Patch 0.50); estimate (planted, to the defenders too) |
| Vision cones | Yours and your side's, faint, each of 20 rays as far as it goes before the level, a cloud or a wall of fire stops it, 40 m at the most, cast 15 times a second | Community (the cones, ludo.guide and Dignitas); confirmed (walls of fire cut them, Patch 6.07); estimate (the rest) |
| Utility | Every cloud, wall of fire and fire out, edged in the allies' colour or the enemies' by whose it is | Confirmed (some utility shows, Patches 1.0 and 2.06); estimate (which, and the look) |
| The white circle | A white ring round you as far as a sound you make where you are is heard, for any heard no further than 60 m (footsteps, landings, reloads, the knife's swings, abilities and the spike's plant and defuse; not a soft landing, a draw or gunfire), fading over 0.6 s | Confirmed (abilities, reloads and the spike, Patch 1.0); community (footsteps, ONE Esports; the wiki); estimate (60 m, 0.6 s) |
| Deathmatch's pulse | As you come back to life, every other player where they are, for 3 s | Community (the wiki); estimate (3 s) |

## 5. Design

### The rules

- **`Sight`** (new) is who sees whom, with no Roblox APIs: `inView` (the view's width and height, as
  the camera has it), `cloudHides` and `wallHides` (as far as the fire has spread, between its depth
  and its height), `hidden`, `sees` (any of a body's `points`), `spotted` (each side's set of the
  enemies it sees) and `sideSees` (a point, for the spike). The level comes in as `blocked`, so the
  tests run it on a fake one.
- **`Minimap`** (new) is the minimap as data and maths. `planFor` builds the plan of the map a mode
  is played on: the arena's three from `ArenaLayout`, the spike maps' three from `SpikeMaps`, with
  `regionName` for their rooms. `homeOf` and `homeTurn` find your spawn and the turn that puts it at
  the bottom. `miniView` and `bigView` are how a box shows the plan by the settings; `toView`,
  `facing` and `yawOf` place points and arrows on a view, and `toEdge` holds an ally on its edge.
  `coneYaws`, `rayCircle`, `raySegment`, `reach` and `coneRects` are the cones' rays and the
  rectangles they're drawn with; `spikeShown` and `namesShown` are the rules for the spike and the
  names.
- **`PlayerSettings`** adds the map settings, with their limits and defaults, on the wire and in the
  data store; settings kept before them take the defaults. `BlazeSim.spreadPath` is a wall's path as
  far as the fire has spread.

### The server

- **`MinimapServer`** (new) looks 20 times a second. Everyone on a side who's in play is seen at the
  pose the snapshots show, and looks from where the server last had their eye, unless a Curveball
  has them half white. The level is a raycast that goes through the barriers; the clouds and walls
  are `CloudServer.standing` and `BlazeServer.standing`. A dropped spike is looked at for the
  defenders, just over the floor. Each player is told their side's enemies seen and whether the
  spike on the ground is, as it changes (the new `Sight` remote).
- **`init.server`** steps it after the frame's shots, so nobody they killed is seen.

### The client

- **`MinimapView`** (new) draws the minimap and the big map, two ScreenGuis, each a box with the
  map's art in a CanvasGroup that cuts it to the box however it's turned. The plan's shapes are
  built once for each plan, scale and setting of the names; each frame the art turns and moves to
  the view, and the words on it stay upright. The cones are painted solid in a group of their own,
  shown faint, so where they overlap is no brighter; their rays are cast through the level (the
  barriers seen through), the clouds and the walls, 15 times a second. The icons sit in a layer that
  doesn't turn, placed by `Minimap.toView`. What the server says is seen is drawn where the
  snapshots draw it, and those it stops seeing are marked where they were. The X marks and the pulse
  come from the Combat remote, the white circle from the game's sounds (`GameSounds`, the curve of
  each). Caps Lock held opens the big map, unless a text box has it.
- **`CloudView.standing`**, **`BlazeView.standing`** and **`FireView.burning`** say what's out, and
  whose.
- **`SettingsMenu`** adds the MAP block: ROTATE or FIXED, SAME WAY or BY SIDE, Keep me centred and
  Vision cones ON or OFF, the size and zoom boxes, and Region names' three choices.
  **`ClientSettings.setOne`** takes their keys.
- **`DebugHud`** puts its panel under the minimap while it's shown.

### Not here yet

- **The fog of war.** The snapshots still carry every pose to every client, so a client that read
  them could see everyone; the minimap draws only what the server says your side sees. Keeping from
  each client what its side can't see is Riot's fog of war, and work of its own.
- **M.** M is the Play menu here (system 24), so the big map is on Caps Lock alone, held.
- **Pings.** The big map takes no pings.
- **Height.** Patch 10.03's shading for raised ground isn't here, nor ziplines; the plans are flat.
- **Status effects.** No ability here deafens or brings paranoia, so nothing obscures the minimap.
- **Reveals.** No ability here reveals anyone (Sova's, Cypher's), so only sight does.
- **Enemy utility out of sight.** Every cloud, wall and fire shows, whoever's it is and wherever it
  is; no source says whether the reference hides an enemy's out of sight.
- **Spectating.** A spectator of the whole match (a coach, an observer) isn't here.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Combat/Sight.luau` | New: who sees whom, through the level, clouds and walls of fire |
| `src/shared/Match/Minimap.luau` | New: every map's plan, the views, the edge, the cones' maths, the spike and the names, and the numbers with their status and source |
| `src/shared/Settings/PlayerSettings.luau` | The map settings, their limits and defaults |
| `src/shared/Abilities/BlazeSim.luau` | `spreadPath` |
| `src/shared/Net/Remotes.luau` | The `Sight` remote |
| `src/server/MinimapServer.luau` | New: the server's spotting, 20 times a second, and each player told as it changes |
| `src/server/CloudServer.luau`, `src/server/BlazeServer.luau` | `standing`: the clouds and walls out |
| `src/server/init.server.luau` | `MinimapServer` started and stepped after the shots |
| `src/client/MinimapView.luau` | New: the minimap and the big map |
| `src/client/CloudView.luau`, `src/client/BlazeView.luau`, `src/client/FireView.luau` | What's out, and whose |
| `src/client/SettingsMenu.luau`, `src/client/ClientSettings.luau` | The MAP block, and its keys |
| `src/client/Debug/DebugHud.luau`, `src/client/Debug/TestAim.luau`, `src/client/init.client.luau` | The panel under the minimap, `VFTestMap`, the view started |
| `tests/minimap.luau` | New: who sees whom, every map's plan, the views, the edge, the spike, the names, the cones, the spread path and the settings |

## 7. Debug tools

- The minimap's ScreenGui, `VFMinimap` in the player's PlayerGui, carries what it shows: `Plan` (the
  plan's key, as `arena:A` or `spike:quarry`), `Seen` (the entity ids of the enemies drawn, as
  `3,7`), `Spike` (whether the spike is drawn), `Turn` (degrees the map's turned) and `Big` (whether
  the big map's open). The big map is `VFMegamap`.
- Its icons are named `Self`, `Ally_<id>`, `Enemy_<id>`, `Seen_<id>` (last seen), `Pulse_<id>`,
  `Dead_<id>`, `Spike` and `Ring`, under each box's `Icons`.
- `VFTestMap` set to true opens the big map as holding Caps Lock does, and false closes it; then it
  clears itself.
- `VFTestSetting` takes the map's keys: `mapRotate=0`, `mapBySide=0`, `mapCentred=1`, `mapCones=0`
  (each `1` or `0`), `mapSize=1.2`, `mapZoom=1.4` and `mapNames=buy` (`always`, `buy` or `never`).

## 8. Refinement loop

1. Step through clips of an enemy stepping out of sight, and set `lastSeen` and the icon's look.
2. Step through clips of a deathmatch respawn, and set `pulse`.
3. Watch clips of each kind of sound with the minimap in shot, and settle `ringMost` and `ring`.
4. Read a fresh account's Map settings, and set the defaults and the limits of Size and Zoom.
5. Compare the cones with clips of long sightlines, and set `coneLength`.
6. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The minimap at the top left in the arena and the spike rounds, gone on the course; the map drawn
  as it's built, your spawn tinted, the F3 panel under it.
- Rotate turning the map as you turn, the words upright, the art cut to the box; Fixed, Based on
  Side, Keep Player Centered, Size and Zoom from the settings menu.
- The big map on Caps Lock held, with the places' names by the setting.
- Your cone cut by the level, a cloud and a wall of fire, and the barriers seen through.
- The white circle as you run, reload and use an ability, and none as you walk or fire.
- A second player: shown while you see them, gone behind a wall, a cloud or a wall of fire, and not
  while you're blinded; the last-seen mark; the spike's rules; deathmatch's pulse.
- A third: an ally's arrow and cone, held on the edge, and the X where they fall.

Section 38 of the [Studio checklist](../studio-checklist.md) covers these.
