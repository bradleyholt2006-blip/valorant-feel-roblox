# valorant-feel-roblox

Valorant-style tactical FPS mechanics rebuilt from scratch in Roblox (Luau), aiming for the same
feel, responsiveness and mechanical depth with original code and assets. Reference behaviour comes
only from public footage, patch notes, developer blogs and our own measurements.

Built one system at a time:

1. **First-person movement and counter-strafing** - [research and design](docs/research/01-movement.md)
2. **Weapon firing**: fire modes, fire rate, ammo, reload, draw, ADS and scopes, damage, health and
   shields, hit slow, server-side hit resolution, practice dummies - [research and design](docs/research/02-weapon-firing.md)
3. Spread and recoil
4. Hit registration with lag compensation

## Running it

1. Install [Rojo](https://rojo.space) 7.x and the Rojo Studio plugin.
2. `rojo serve` in this folder, connect from Studio, press Play.
3. With no `Map` in Workspace, a measurement course with a target lane and practice dummies is
   built automatically. Look straight ahead from the spawn to face the lane.

Controls: WASD, Shift walk, Ctrl/C crouch, Space jump, mouse 1 fire, mouse 2 zoom / scope,
R reload, 1/2/3 primary / secondary / knife.
Debug: F2 weapon lab, F3 HUD, F4 counter-strafe lab, F6 record CSV, F7 server ghost,
F8 zero cm/360 counter, F10 hitbox overlay, Backspace clear impact marks, 4-8 give Vandal /
Phantom / Operator / Sheriff / Classic (Studio or place owner only).

## Tests

The shared simulation (movement, weapons, hitboxes, wire formats) is pure Luau and runs outside
Roblox:

```
luau tests/run.luau
```

It prints metrics reports (start, stop and counter-strafe timings per weapon; fire rate, magazine
and time-to-kill per weapon) and runs the test suites. CI also type-checks everything with
`luau-lsp` and Roblox definitions.

## Rules for this project

- No game memory access, no anti-cheat circumvention, no extracted assets.
- Every gameplay number carries a status: confirmed, community or estimate, with its source.
- Gameplay is server-authoritative; clients predict.
