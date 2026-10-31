# System 68: Controller support

A gamepad now plays the game, on the reference's console layout: RT fires, LT held is Focus (the
view turns slower) or a sniper's scope, LT with RS aims down sights, the bumpers and B are the
abilities and both bumpers together the ultimate, and Y swaps guns or, held, draws the knife. The
D-pad pings, drops, draws the spike and opens the buy menu; Select opens the big map, shows the
scoreboard held, and with the D-pad opens the other menus. In a menu the pad drives Roblox's
gamepad cursor, and B shuts it. The player sets how fast the stick turns the view, Focus's share of
that, inverting it and walking in Focus in the settings menu, kept with the rest.

The layout and the names of the console version's settings are published; its numbers aren't, so
the stick's curve, speeds and dead zones are ours and marked as estimates. No game file or source
code was read, nothing was read from the live game, and no Riot image is in the repository: the
prompts name buttons in words.

## 1. Observable behaviour

- On the console version, holding LT turns the right stick's aim slower without aiming down
sights, and LT with RS aims down sights; a sniper's LT held is its scope.
- The bumpers and a face button cast the three abilities, and both bumpers the ultimate.
- Crouch toggles; the D-pad pings (held for the wheel), drops, and is the spike's.
- Y swaps between the guns, and held draws the knife.

## 2. Publicly documented details

| What | Source |
| --- | --- |
| The default layout: "Fire" R2 / RT; "ADS" L2 + R3 / LT + RS; "Focus / Sniper Scope" (Hold) L2 / LT; "Jump" Cross / A; "Crouch" (Toggle) L3 / LS; "Reload" Square / X; "Activate / Use" R3 / RS; "Ability 1" L1 / LB, "Ability 2" R1 / RB, "Ability 3" Circle / B; "Ultimate" L1 + R1 / LB + RB; "Equip Secondary / Equip Melee" (Hold) Triangle / Y; "Plant / Defuse / Equip Spike" D-Pad Down; "Ping / Comm Wheel" (Hold) D-Pad Up; "Drop Equipped Item" D-Pad Left | primagames.com, [VALORANT complete controls for PlayStation and Xbox controllers](https://primagames.com/tips/valorant-complete-controls-for-playstation-xbox-controllers) |
| Another table of the default: "Ability 3" R3 / RS, "Equip Melee" L3 / LS, "Crouch (toggle)" Circle / B, "Reload/Activate/Use" Square / X, "Inspect/Open Spray Wheel (hold)" D-Pad Right; the rest as above | esports.net, [Best controller settings for VALORANT console](https://www.esports.net/news/valorant/best-controller-settings-valorant-console/) |
| Focus "mimics hip-fire but with reduced sensitivity"; its table also has "Crouch (Toggle)" on Circle / B; "Traditional" is the preset it gives | dexerto.com, [Best controller settings for VALORANT console](https://www.dexerto.com/valorant/best-controller-settings-valorant-console-2778165/) |
| "When pressing the trigger, the game quickly shifts how sensitive the aiming joystick is"; "It markedly lowers it compared to shooting from the hip, though you aren't actually aiming down sights"; "Both have similar accuracy but aiming down sights takes slightly longer to do"; "the console version also utilizes light aim assist" | Kotaku, [Valorant console's Focus Mode](https://kotaku.com/valorant-console-focus-mode-ps5-xbox-riot-fps-1851545155) (17 June 2024) |
| The settings' names: "Base", "Focus", "ADS" and "Sniper" "Horizontal Sensitivity" and "Vertical Sensitivity", an "Aim Curve" for each, "Walk While in Focus", "Vibration", "Left/Right Trigger Deadzone" (0.01 in its settings); "Turn off Walk While in Focus lets you move quicker in this aim mode"; the "Traditional", "Fighter" and "Tactician" presets | charlieintel.com, [Best VALORANT console controller settings](https://www.charlieintel.com/valorant/best-valorant-console-controller-settings-329370/) |
| ADS sensitivity "around 0.7 to 1.0 times your base sensitivity", sniper "around 0.5 to 0.8 times your base sensitivity" | thespike.gg, [Best controller settings](https://www.thespike.gg/valorant/console/best-controller-settings) |
| EnableGamepadCursor "enables the gamepad cursor if it's currently disabled", centred on a GuiObject "or `nil` to use the default cursor position"; the cursor is on for an experience by StarterGui's VirtualCursorMode | Roblox, [GamepadService](https://create.roblox.com/docs/reference/engine/classes/GamepadService) |

The tables disagree on B, X, L3 and R3: two of the three put crouch on B. What's here follows
primagames.com's, the fullest of the three.

## 3. What can be measured, and how

The rules are plain functions, checked offline: `tests/pad.luau` has 79 checks, the scope's driven
on the weapons' own zoom through `PlayerSim`, and the suite's 4112 pass. In Studio (section 72 of
the checklist) `VFTestPad` stands in for a pad, so the checks need no controller, and the player's
`VFPad` says what the pad's doing each frame. A real controller is needed for Roblox's own cursor in
the menus and for the stick's feel.

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| Layout | As primagames.com's table, with D-pad Right the buy menu's B and Select the big map, the scores and the menus | Community, and ours for D-pad Right and Select | primagames.com |
| Focus | LT held: the look speed times the player's padFocus, hip-fire accuracy | Community | Kotaku, dexerto.com |
| Focus's share | 0.5 | Estimate | Ours |
| Look speed | 220 degrees a second at full tilt | Estimate | Ours |
| Look curve | The tilt past the dead zone, squared | Estimate | Ours: the console version's curves are named, not published |
| Dead zones | The right stick 0.12 of its throw, the left 0.25 | Estimate | Ours |
| The ramp | Held past 0.95 of its throw for 0.2 s, the sideways turn speeds up to 1.8 times over 0.25 s; not in Focus or zoomed | Estimate | Ours |
| Zoomed | The look speed times the scoped multiplier over the zoom, as the mouse's | Estimate | Ours: a rifle's sights turn at 0.8 of it, inside thespike.gg's 0.7 to 1.0; a sniper's first zoom at 0.3 to 0.4, under its 0.5 to 0.8, which the scoped multiplier raises |
| Walking | Tilted less than 0.6 of the stick's throw; and in Focus with Walk While in Focus on | Estimate, and Community for the setting | Ours; charlieintel.com |
| Walk While in Focus | Off | Community | charlieintel.com's settings |
| Triggers | Held past 0.1 of their travel | Estimate | charlieintel.com's 0.01 is as low as it goes |
| The ultimate's chord | Each bumper's ability waits 0.08 s for the other | Estimate | Ours |
| Y and Select held | 0.25 s, as Z for the ping wheel | Estimate | Ours |
| The cursor on a map or the wheel | 700 pixels a second at full tilt | Estimate | Ours |
| Aim assist | None | Estimate | Ours: here a pad plays alongside mice on the same servers |

## 5. Design

### Reading the pad

Once a frame, before the player's render step samples the input, `Gamepad` reads the pad last used
(Gamepad1 to begin with): the sticks' and the triggers' positions from `GetGamepadState`, the
buttons
from `IsGamepadButtonDown`. Nothing comes from it while the mouse and keys are in use: the last
input decides (a button, or a stick or a trigger past its dead zone, for the pad; a key, a mouse
button or a move of a few pixels for them), and `InputSampler.padActive` says which.

The pad's flags join the keys' in `InputSampler.sample`, each tick: those held this frame, and the
presses among them latched as a key's are, so a tap shorter than a frame still counts. Fire and alt
fire are blocked with the mouse buttons' while the buy menu or the big map has the mouse.

### Moving

The left stick holds the keys of the nearest of the 8 directions the keys give, as PlayerSim moves
by keys; tilted less than 0.6 of its throw it walks. The console version leaves walking to Walk
While in Focus, which is here too.

### Looking

The right stick's tilt past its dead zone, squared, is a share of the look speed, so small tilts aim
finely. Held all the way over, the sideways turn speeds up after a moment, so turning round doesn't
take long. The turn goes to the camera as mouse counts (`CameraController.padCounts`), so a zoom,
the
scoped multiplier and Hunter's Fury's slow-down apply to it as they do to the mouse, and where a
cursor has the mouse (the ping wheel's pick, the big map's cursor, From the Shadows' map) the stick
moves that instead.

### LT, RS and the zoom

What LT does depends on what's in hand (`PadRules.role`):

- a rifle, an SMG or a heavy: Focus, and RS with it aims down sights, until RS is pressed again or
LT is let go
- a sniper: its scope, held as LT is, and RS with it its second zoom
- the Classic: Focus, and RS with it its burst, as right click is
- the knife, Blade Storm's knives, an ability's weapon or an ability in hand: alt fire itself
- anything else: Focus

PlayerSim zooms by alt fire, one press a level and past the last back to none. To hold a zoom as LT
is, the pad presses alt fire a tick at a time until the predicted zoom is the one wanted
(`PadRules.pulse`), and the server, sent the same presses, zooms the same. Going down, the pad lets
the zoom go instead (`Unzoom`, an input button of its own, the eighteenth, in the slot byte), which
takes it straight off, as letting go of a held scope does: the Operator's first zoom goes out with
no tick of its second, which two presses showed for a frame (measured in Studio), and from its
second back to its first the zoom's let go and pressed in one tick, never out of the scope.

### Abilities and the ultimate

LB, RB and B hold Q, E and C. Each bumper waits 0.08 s for the other before it's its ability, so
both together are the ultimate (X) and not two abilities; a bumper let go sooner still presses its
own once.

### Weapons and the spike

Y tapped draws the sidearm from the primary and the primary from anything else; held, the knife.
D-pad Down is 4 (it draws the spike, and held plants or defuses it), D-pad Left is G, A jumps, L3
toggles crouching (each life starts standing), X reloads, and RS is F: an Ultimate Orb, a defuse, a
gun on the ground. While LT is held with a gun, RS is LT's.

### Pings, the map and the scoreboard

D-pad Up is Z: tapped it pings along the crosshair, held it opens the wheel, whose pick the right
stick moves, and let go it pings the option picked. Select tapped opens or shuts the big map, where
the right stick moves the cursor and RT pings; held, it shows the scoreboard. With D-pad Up, Left,
Right or Down, Select opens or shuts the Play menu, agent select, the settings or the combat
report, and then neither the map nor the scores. D-pad Right alone is B: the buy menu, or the
loadouts in Team Deathmatch.

### Menus

With a menu up the pad's play stops, and the pad drives Roblox's gamepad cursor
(`GamepadService:EnableGamepadCursor`): the left stick moves it and A clicks. Where the place has
that cursor off (StarterGui's VirtualCursorMode, the place owner's call), the menu's buttons are
picked with the D-pad instead (`GuiService:Select`). B shuts any menu. A button held as a menu shuts
does nothing until it's let go, so the A that pressed PLAY doesn't jump. Roblox's own use of
Select, to start picking buttons (`GuiService.AutoSelectGuiEnabled`), is off, as Select is ours.

### Dead

RT and LT watch the next teammate and the one before, as left and right click do, and RS takes over
a bot watched, as F does.

### On screen

While the pad's in use, the prompts name its buttons: "RS PICK UP", "HOLD D-PAD DOWN TO PLANT",
"HOLD RS FOR THE ULTIMATE ORB", and when watching "RS take control" and "RT / LT switch". The
settings menu has a CONTROLLER section: the look speed, Focus's share, inverting and walking in
Focus, and the buttons listed.

### Roblox's own controls

The player scripts built on the Input Action System have no GetControls (Studio's warning:
"attempt to call missing method 'GetControls'"), so their bindings,
InputContexts, are switched off instead, as they come. The game's own input is UserInputService's,
which reads the pad whatever those bind.

### Not in yet

- The other presets (Fighter, Tactician, Bumper Shooter) and rebinding.
- Separate horizontal and vertical speeds, curves, and speeds for each zoom.
- Aim assist, on purpose, and vibration.
- The menus' own key hints ("O to close") and the HUD's ability keys still name keys.
- Typing in the settings' boxes needs Roblox's on-screen keyboard, untried.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Input/PadConfig.luau` | The pad's numbers, with their sources |
| `src/shared/Input/PadRules.luau` | The sticks as keys and turns, the bumpers' chord, taps and holds, LT's role and the zoom it wants, alt fire's presses and the zoom let go for it, Y's swap, the text for `VFTestPad` |
| `src/shared/Movement/MovementSim.luau`, `src/shared/Net/PlayerCodec.luau`, `src/shared/Weapons/WeaponSim.luau` | `Buttons.Unzoom`, carried in the input's slot byte, and the zoom it lets go |
| `src/client/Gamepad.luau` | Reads the pad each frame and plays it: flags, the turn, the D-pad, Y, Select, the menus and the gamepad cursor |
| `src/client/InputSampler.luau` | `padSample`, `padPress` and `padActive` |
| `src/client/CameraController.luau` | `padCounts`, added to the mouse's |
| `src/client/PingView.luau` | `press` and `release`, as Z |
| `src/client/Spectate.luau` | `step`, as a click; its line names the pad's buttons |
| `src/client/GroundGunsView.luau`, `src/client/SpikeHud.luau` | Prompts naming the pad's buttons |
| `src/client/PlayerController.luau` | The Input Action System's InputContexts switched off |
| `src/shared/Settings/PlayerSettings.luau`, `src/client/ClientSettings.luau`, `src/client/SettingsMenu.luau` | `padLook`, `padFocus`, `padInvert` and `padWalk`, and the CONTROLLER section |
| `src/client/Debug/TestAim.luau` | `VFTestPad` |
| `tests/pad.luau` | 79 checks; `tests/settings.luau` 2 more |
| `docs/studio-checklist.md` | Section 72 |

## 7. Debug tools

- `VFTestPad` on the player, in Studio: a pad held as given, the left stick's x and y, the right's,
the triggers, then the buttons held (`0 1 0 0 0 1 a lb`), until it's cleared.
- `VFPad` on the player, in Studio, set by the client: `off`, or the pad's flags, the zoom LT wants
and the zoom predicted, Focus, the turn in counts (the cursor's move while the ping wheel or a map
has the right stick), and how a menu's buttons are picked: `on` with Roblox's gamepad cursor on,
`pick` with one picked for the D-pad, else `off` (`flags=129 zoom=- scoped=0 focus=0
turn=12.5,0.0 cursor=off`).
- `VFTestSetting` takes `padLook`, `padFocus`, `padInvert` and `padWalk` (`padInvert=1`).

## 8. Refinement loop

1. Play with a controller, against bots and on the course, and tune `PadConfig.Params` (the curve,
dead zones, ramp, chord and cursor speed) and the settings' defaults.
2. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Moving, walking, looking, the ramp and inverting, by `VFTestPad`.
- Focus, a rifle's sights and a sniper's two zooms held as LT is.
- The abilities, the ultimate's chord, Y's swap and the knife, the spike, crouching and reloading.
- Pings, the buy menu, B shutting it, Select's map, scores and menus, and taking over a bot.
- With a real controller: Roblox's gamepad cursor in the menus, the prompts, and no warning about
Roblox's default controls.

Section 72 of the [Studio checklist](../studio-checklist.md) covers these.
