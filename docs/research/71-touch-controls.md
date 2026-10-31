# System 71: Touch controls

A phone or a tablet plays the game with its screen. A thumb on the left of the screen moves, as a
stick that starts wherever it lands, and pushed only part of the way, walks; a drag anywhere else
turns the view as the mouse does, and so does the fire button's touch as it moves, so a burst can
follow what it's fired at. Round the right thumb are FIRE, AIM (right click: aiming down sights, a
scope, the Classic's burst), JUMP, CROUCH (on, and off again), RELOAD, the abilities C, Q, E and X,
USE (F), SPIKE (4, shown while the spike's carried), DROP (G), SWAP (tapped, the primary or the
sidearm; held, the knife) and PING (Z, held for the wheel); a second FIRE sits for the left thumb,
and down the left are BUY, MAP, SCORES, AGENTS, PLAY and SETTINGS. With a menu up, only CLOSE shows,
and a tap on the menu is the menu's. Dead, FIRE and AIM switch who's watched and USE takes over the
bot watched. The buttons keep clear of each other, of the screen's edges and of the HUD on phones
and tablets alike, and the settings menu sets how far a drag turns the view.

Guides to the reference's mobile version name its settings (sensitivities for the camera, aiming
down sights and a scope, a gyroscope for aiming, a layout the player can move, setups for two to
four fingers) but give none of its layout's places or sizes, so the layout, its sizes and how far a
drag turns are ours, laid out as mobile shooters commonly are. No game file or source code was read,
and nothing was read from the live game.

## 1. Observable behaviour

- The reference's mobile version has separate sensitivities for the camera, aiming down sights and a
  scope, and a gyroscope that can aim while aiming down sights.
- Its layout can be moved: guides tell players to put the shoot button where the thumb rests.
- Its players hold the phone with two, three or four fingers, or a claw grip; more fingers bring a
  dedicated fire button and higher sensitivities.
- With two fingers, guides set the fire mode to Auto; with more, to Manual.

## 2. Publicly documented details

| What | Source |
| --- | --- |
| "Enable Gyroscope (ADS only)"; "Set sensitivity: 40-50% general, 25-35% ADS"; "Customize HUD: move shoot button where your thumb naturally rests" | Garena Gamehub, [Valorant Mobile Beginner Guide](https://gamehub.garena.com/guides/cmnfsfu7z008lv40aj2cjae5n) |
| 2-Finger: "Perfect for beginners and casual players. Simple and intuitive control scheme."; 3-Finger: "Great balance between simplicity and advanced control. Adds dedicated fire button."; 4-Finger: "Maximum control and precision."; Claw: "Advanced grip technique for maximum speed and precision." | valomobile.net, [Control Setups & HUD Layouts](https://valomobile.net/setups) |
| Camera, ADS and Scope sensitivities for each setup (2-Finger 45-55, 35-45 and 25-35; Claw 70-80, 50-60 and 40-50); 2-Finger "Fire Mode:Auto", the others Manual | The same |

Neither says where a button sits, how big it is, what the fire modes do, or how far a drag turns the
view, so the rest is ours.

## 3. What can be measured, and how

The layout and the rules are plain functions, checked offline: `tests/touch.luau` has 44 checks (the
layout on nine phones' and tablets' screens, with their safe areas, Roblox's top bar at both its
heights and the minimap at its biggest; what a touch hits; the stick, the look drag and the buttons
as flags; and the text checks give), and the suite's 4179 pass. In Studio the player's `VFTestTouch`
stands in for a touch screen, and their `VFTouch` says what it's doing (section 75 of the
checklist). A phone or a tablet, or Studio's device emulator, checks the feel.

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| Separate sensitivities for aiming down sights and a scope | The scoped multiplier, the mouse's, applies to a drag too | Community | Garena Gamehub, valomobile.net |
| Where the fire button sits | Where the right thumb rests, the rest round it | Community | Garena Gamehub: "where your thumb naturally rests" |
| A dedicated fire button for more fingers | A second FIRE on the left | Community | valomobile.net |
| The unit | 1% of the screen's short side | Estimate | Ours: the same shape on every screen |
| The buttons' places and sizes | `TouchConfig.Cluster` (FIRE 9 units across its radius, the rest 4 to 5.5) | Estimate | Ours |
| The stick | Anywhere in the left 40% of the screen not on a button; 12 units of throw; walking under 0.6 of it, nothing under 0.25 | Estimate | Ours; the dead zone and the walk are the gamepad's (system 68) |
| The look drag | 120 degrees for a drag the screen's short side (`touchLook`, 30 to 400); zoomed, slower by the zoom and the scoped multiplier as the mouse is | Estimate | Ours: a drag right across a phone held sideways turns 210 to 260 degrees |
| The fire button's touch | Turns the view as it moves | Estimate | Ours |
| CROUCH | On, and off again; off with each life | Estimate | Ours, as the gamepad's L3 |
| SWAP | Tapped, the primary or the sidearm; held 0.25 s, the knife | Estimate | Ours, as the gamepad's Y |
| Keeping clear | 1.5 units between buttons, from the safe area's edges and from the HUD; over the HUD's band along the bottom where it reaches under the right thumb's buttons | Estimate | Ours |
| Auto fire, the gyroscope, moving the buttons | None | Estimate | Ours: not in yet |

## 5. Design

### The layout

`TouchRules.layout` lays the buttons out in the screen's safe area (Roblox's `CoreUISafeInsets`:
under the top bar and clear of a notch), in units of 1% of the screen's short side. The right
thumb's buttons stand on a floor: the bottom of the safe area, or where the HUD's band along the
bottom (health, abilities and ammo, within 300 pixels of the middle and 70 above the bottom) reaches
under them, its top, as it does on every phone. FIRE is the biggest, where the right thumb rests;
JUMP and CROUCH below it, RELOAD and X to its right, E, Q and C in an arc above and to its left, AIM
to its left, and USE, SPIKE, DROP, SWAP and PING further left. Kept under 41 units high, they fit
under the players' tiles across the top on a phone. The second FIRE sits right of the minimap, below
the tiles; the column runs down the left from under the minimap, and on into a second column where
it would reach the floor. CLOSE sits at the top right.

### Touches

Each touch is what it started on until it's lifted: a button, the stick (the first touch in the
left 40% of the screen on no button), or a look (any other). The stick's tilt is how far the touch
is from where it started, over its throw, and moves as a gamepad's left stick does
(`PadRules.move`). A look turns the view by its movement, as the mouse's counts: `touchLook` degrees
for a drag the length of the screen's short side, divided by the degrees a mouse count turns
unzoomed, so zoomed it turns slower as the mouse does. FIRE's touches turn it too. With the ping
wheel or the big map up, a drag moves their cursor a pixel a pixel.

### The buttons

What each button holds is its key's (`TouchRules.HOLDS`): FIRE fire, AIM alt fire (right click, so a
tap aims down sights or zooms a scope and taps again come back, and held, the Classic bursts), JUMP,
RELOAD, the abilities, USE F (`Interact`, which defuses and takes an Ultimate Orb), SPIKE 4 (`Use`,
which plants), DROP G. CROUCH turns the crouch on and off. The rest act as they're pressed: SPIKE
draws the spike, USE takes a gun off the ground, SWAP draws a slot as the gamepad's Y does, PING
pings as Z does, FIRE pings on the big map, and the column opens and shuts its menu or view. Dead,
FIRE and AIM switch who's watched and USE takes over the bot watched.

### On the client

`TouchControls` reads the touches each frame before the player's own render step samples the input,
as the gamepad's module does: its flags go to `InputSampler.touchSample`, its presses latched as a
key's are, and its look to `CameraController.touchCounts`. While the last input was a touch
(`InputSampler.touchActive`), the buttons show, the mouse's buttons and its turn are left out, and
the HUD's prompts name these buttons (`HOLD SPIKE TO PLANT`, `HOLD USE TO DEFUSE`, `USE  PICK UP`,
`USE  take control`, `FIRE / AIM  switch`). A key, a gamepad or the mouse moved takes over. A phone
or a tablet with no keyboard or mouse starts on touch. Roblox's own touch controls are off.

### Not in yet

- Auto fire (firing as the crosshair crosses an enemy), the gyroscope, and moving or sizing the
  buttons.
- The menus on a phone: drawn for a monitor and scaled to fit, their text is small.
- Selling back in the buy menu (a right click) and the combat report (N).
- A phone held upright.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Input/TouchConfig.luau` | The layout, the stick, the margins and the HUD's band |
| `src/shared/Input/TouchRules.luau` | The layout on a screen, what a touch hits, the stick, the look drag, the flags, and the text checks give |
| `src/client/TouchControls.luau` | The touches, the buttons drawn, what they do, and Roblox's touch controls off |
| `src/client/InputSampler.luau` | `touchSample`, `touchPress` and `touchActive`, and the mouse buttons left out |
| `src/client/CameraController.luau` | `touchCounts`, and the mouse's turn left out |
| `src/shared/Settings/PlayerSettings.luau` | `touchLook` |
| `src/client/ClientSettings.luau`, `src/client/SettingsMenu.luau` | Touch look, under CONTROLLER AND TOUCH |
| `src/client/SpikeHud.luau`, `src/client/Spectate.luau`, `src/client/GroundGunsView.luau` | The prompts naming the buttons |
| `src/client/Debug/TestAim.luau` | `VFTestTouch` |
| `src/client/init.client.luau` | `TouchControls.start` |
| `tests/touch.luau` | 44 checks |
| `docs/studio-checklist.md` | Section 75 |

## 7. Debug tools

- `VFTestTouch` on the player, in Studio: a touch screen held as given, as text: the stick's x and
  y, the look drag's speed right and up in screen heights a second, and the buttons held by name
  ("0 1 0.2 0 fire": running ahead, turning right, firing).
- `VFTouch` on the player, in Studio: "off", or the flags, the turn in the mouse's counts, the
  crouch, a menu up, and the safe area's size ("flags=129 turn=12.5,0.0 crouch=0 menu=0
  size=750x311").
- PlayerGui's `VFTouch` holds the buttons, each a frame under `Safe` named for its button, and the
  stick's `Stick` and `Knob`.

## 8. Refinement loop

1. Play on a phone and a tablet, or in Studio's device emulator: reach each button with a thumb, aim
   with a drag and with FIRE's, and walk with a light push.
2. Tune `TouchConfig` and the `touchLook` default, and re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The buttons shown as a touch screen's in use, where the layout says, and none with the mouse.
- The stick moving and walking, the look drag turning, and FIRE's touch turning too.
- Each button doing what its key does, CROUCH on and off, SWAP tapped and held, and the column's
  menus.
- With a menu up, only CLOSE, which shuts it.
- Dead: FIRE and AIM switching, and USE taking over the bot watched.
- On a phone: the feel, the sizes, and Roblox's own touch controls gone.

Section 75 of the [Studio checklist](../studio-checklist.md) covers these.
