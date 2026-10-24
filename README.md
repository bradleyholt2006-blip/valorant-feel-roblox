# valorant-feel-roblox

Valorant-style tactical FPS mechanics rebuilt from scratch in Roblox (Luau), aiming for the same
feel, responsiveness and mechanical depth with original code and assets. Reference behaviour comes
only from public footage, patch notes, developer blogs and our own measurements.

Built one system at a time:

1. **First-person movement and counter-strafing** (this PR) - [research and design](docs/research/01-movement.md)
2. Weapon firing
3. Spread and recoil
4. Hit registration with lag compensation

## Running it

1. Install [Rojo](https://rojo.space) 7.x and the Rojo Studio plugin.
2. `rojo serve` in this folder, connect from Studio, press Play.
3. With no `Map` in Workspace, a measurement course is built automatically.

Controls: WASD, Shift walk, Ctrl/C crouch, Space jump, 1/2/3 rifle/Operator/knife.
Debug: F3 HUD, F4 counter-strafe lab, F6 record CSV, F7 server ghost, F8 zero cm/360 counter.

## Tests

The movement simulation is pure Luau and runs outside Roblox:

```
luau tests/run.luau
```

It prints a metrics report (start, stop and counter-strafe timings per weapon) and runs the test
suite. CI also type-checks everything with `luau-lsp` and Roblox definitions.

## Rules for this project

- No game memory access, no anti-cheat circumvention, no extracted assets.
- Every gameplay number carries a status: confirmed, community or estimate, with its source.
- Gameplay is server-authoritative; clients predict.
