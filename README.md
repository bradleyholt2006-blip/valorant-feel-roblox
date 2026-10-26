# valorant-feel-roblox

Valorant-style tactical FPS mechanics rebuilt from scratch in Roblox (Luau), aiming for the same
feel, responsiveness and mechanical depth with original code and assets. Reference behaviour comes
only from public footage, patch notes, developer blogs and our own measurements.

Built one system at a time:

1. **First-person movement and counter-strafing**, with Counter-Strike's air strafing held to running
   speed - [research and design](docs/research/01-movement.md)
2. **Weapon firing**: fire modes, fire rate, ammo, reload, draw, ADS and scopes, damage, health and
   shields, hit slow, server-side hit resolution, practice dummies, and other players drawn as
   their hitboxes until there are agent models - [research and design](docs/research/02-weapon-firing.md)
3. **Spread and recoil**: firing error by bullet, recovery and tap efficiency, movement error by
   state, jump landing, aim-down-sights, recoil climb and sideways drift, seeded per-shot spread
   the server and client agree on - [research and design](docs/research/03-spread-recoil.md)
4. **Hit registration and lag compensation**: server rewind to what the shooter saw with Riot's
   140 ms cap, a render clock measured from snapshot arrivals, Network Buffering, players' and
   dummies' moves paced in the snapshots so others see them move evenly, client-predicted sparks
   and server hit confirms pinned to the body part, simulated latency, jitter and loss for testing
   in Studio - [research and design](docs/research/04-hit-registration.md)
5. **Wall penetration**: Low / Medium / High weapon classes against soft, medium, hard and solid
   materials, thickness along the ray, damage left after walls, bullets stopping inside walls,
   holes, dust and sparks, a wallbang lane - [research and design](docs/research/05-wall-penetration.md)
6. **The look**: a lighting preset that keeps shade from getting dark and values close together,
   colour grading and soft bloom, a subtle vignette, a red outline on enemies (blue on allies) that
   grows with distance, the reference's four enemy colours for colour blindness, and no character
   shadows - [research and design](docs/research/06-visuals.md)
7. **The arena**: a whitebox of Skirmish A, the reference's small-fight layout, measured from
   Riot's minimap, played by Skirmish's rules: two sides on Roblox teams, a buy phase held behind
   each spawn's barrier, rounds that end when a side is wiped out, first to 10, with a score bar
   and banners, and round restarts that respawn living players cleanly -
   [research and design](docs/research/07-arena.md)
8. **Sound**: running footsteps heard by others out to a flat 20 m edge, never walking or
   crouching ones; landings heard unless they come up onto something higher; gunshots from where
   they were fired, dulled by distance and muffled through walls; reloads played in parts as
   they go, draws and dry fire; hit, headshot and kill sounds; nothing from the other side in the
   buy phase. The sounds are Pro Sound Effects' recordings from the Creator Store's free library,
   and Roblox's own character sounds are off -
   [research and design](docs/research/08-sound.md)
9. **The arsenal**: all 20 guns and the knife, with every way they fire: semi and automatic, the
   Stinger's and the Bulldog's bursts zoomed, the Classic's three-bullet right click, shotgun
   pellets that land as one hit, shell-by-shell reloads, the Outlaw's double tap, the Odin's rising
   fire rate, every zoom and scope, and suppressed guns whose tracers only their own side sees;
   Light Armor, Heavy Armor and the Regen Shield, each taking its share of a hit; and a buy menu
   on B with every gun and shield, its numbers on hover, click to buy and right-click to sell back -
   [research and design](docs/research/09-arsenal.md)
10. **The knife**: a slash on the left button round a three-swing combo and a harder, slower stab
    on the right; double damage from behind, judged on a 180-degree arc, so a stab in the back
    kills through any shield; one target a swing, the one nearest the aim, never through a wall;
    lag compensated like a bullet, guessed on your screen at once with a cut where it strikes the
    level, and the library's knife recordings for its sounds -
    [research and design](docs/research/10-knife.md)
11. **Settings**: your Valorant sensitivity and scoped multiplier, turning the view exactly as far
    as the reference does for the same mouse movement, with cm/360 worked out from your mouse's
    DPI; crosshair codes pasted from the reference or a crosshair site and drawn pixel for pixel,
    with their own crosshairs for aiming down sights and the sniper scope's dot, lines that spread
    as you move and fire and top lines that fade in a spray; a settings menu on O, and both kept
    for your next session - [research and design](docs/research/11-settings.md)
12. **The spike**: carried in slot 4 and dropped with G, picked up by running over it; held 4
    plants it in a site in 4 seconds and defuses it in 7, rooted, with half a defuse kept; a
    defuse needs the defuser in range and in sight of it throughout; a 45-second countdown that
    beeps faster as it ends, with the reference's tells (red lights and a rising casing while
    defused, the white sphere at 7 seconds), and a blast that kills everyone within 35 m; all
    predicted on your screen and decided by the server. On the course, two sites behind the spawn
    where anyone can plant and defuse - [research and design](docs/research/12-spike.md)
13. **Rounds played for the spike**: the reference's standard match on Outpost, a small two-site
    map of our own for one to three a side. One side attacks with the spike, which lies in front
    of them each round and only they can carry; the other defends the sites, and only it can
    defuse. A buy phase behind the spawn barriers (45 s at each half, 30 s otherwise), 100 s to
    plant, a round won by a wipe, the clock, a defuse or the blast, halves of 12, first to 13 and
    sudden death at 12-12, or Competitive's win by two, or Swiftplay's first to 5; the Classic and
    the knife at each half and after a death; a top bar with the round's clock that gives way to
    the spike, and banners for match point, overtime, switching sides and how each round was won -
    [research and design](docs/research/13-rounds.md)
14. **The economy**: credits in the spike rounds, paid as the reference pays them. 800 at the start
    of each half; each round then pays 3000 for a win, or 1900, 2400 and 2900 for losses in a row,
    or 1000 for a loss survived without a plant (or, defending, after the blast); 200 a kill and 300
    to every attacker for the plant, as they happen; 9000 at most; everyone on 5000 in overtime,
    and Swiftplay's own schedule. The buy menu charges for each purchase, less the refund of what it
    replaces from the same buy phase, dims what you can't afford and shows what the round pays; a
    survivor keeps their shield, damaged, into the next round - [research and
    design](docs/research/14-economy.md)
15. **Guns on the ground**: G drops the gun in hand, a little ahead of you, and the next weapon
    comes out; in the spike rounds the dead drop their primary, or their sidearm without one.
    Anyone can pick one up, on either side: walking over it fills an empty slot, and F swaps the
    gun you're looking at for yours, which goes down in its place. Guns keep their rounds on the
    ground, the drop is predicted on your screen, and the ground is cleared as each round starts -
    [research and design](docs/research/15-ground-guns.md)
16. **The round at a glance**: a kill feed at the top right, a line a kill with the killer, the
    weapon, the headshot and wallbang marks and whoever died, each name in its side's colour and
    your own lines outlined in gold; a tile for each player beside the top bar, dimmed once they're
    dead; and in the spike rounds a scoreboard held on Tab, with everyone's kills, deaths, assists
    and average combat score (damage, kills worth more with more enemies alive, multikills), your
    side's credits and guns, and the other side's credits as the round started -
    [research and design](docs/research/16-scoreboard.md)
17. **The ability kit**: four abilities on C, Q, E and X, with an ability bar between health and
    ammo. Basic abilities are bought a charge at a time in the buy phase and kept through a death
    into the next round; the signature has a free charge every round; the ultimate fills with a
    point for each kill, death, plant and defuse. Jett's kit came first: Updraft throws you
    straight up about 4 m, and Tailwind readies a gust that, after a second's windup, dashes you
    about 7 m the way you're moving, and comes back with two kills. Casts are predicted on your
    screen and decided by the server, and others see and hear them where you're drawn -
    [research and design](docs/research/17-abilities.md)
18. **Cloudburst**, Jett's smoke: C throws it at once from your eye the way you look, and puts
    your gun away for a quarter of a second. It flies at 30 m/s, and holding C curves it towards
    your crosshair. It bursts where it hits the level, or in mid-air after 2 s, into a ball of
    smoke 3.35 m in radius that lasts 2.5 s and hides what's behind it, enemy outlines included;
    from inside it, the screen is smoke. The server flies each throw on its thrower's ticks, and
    your screen flies yours the same way, so your cloud forms at once where the server's will -
    [research and design](docs/research/18-cloudburst.md)
19. **Blade Storm**, Jett's ultimate: X, once its 8 points are full, puts five throwing knives in
    your hand after a second's windup. Mouse 1 throws one, exactly where the crosshair is,
    standing, running or in the air, for 50 to the body and 150 to the head, and a kill with one
    brings all five back. Mouse 2 throws all that are left at once, in a spread, and its kills
    bring none back. Once they're all thrown, your gun comes back. A number key draws a gun and
    keeps the knives for later, X draws them again, and the other abilities work with them out.
    The knives are a weapon of their own in a fifth slot, so the server decides each throw as it
    does a shot, with lag compensation - [research and design](docs/research/19-blade-storm.md)
20. **Drift**, Jett's passive: with Space held while you fall, you glide, falling no faster than
    2 m/s, so a held jump comes down slowly and the top of Updraft keeps you in the air about 3 s.
    The rise, a dash and your speed along the ground are left alone, and you can shoot and cast as
    in any fall. Others hear a soft run of gusts and see rings of air left behind you as you sink -
    [research and design](docs/research/20-drift.md)
21. **Matches that never stop**: a live server plays from the moment it starts, Skirmish for now,
    so whoever joins drops into a match under way. They go on the side with fewer players: in a
    buy phase they spawn at once, and later they watch a teammate until the next round, switching
    with the mouse buttons. Past two a side (five in the spike rounds) they wait in line for a
    place, and the sides are evened out before each round. Skirmish keeps the same record as the
    spike rounds, and each match ends on a 10-second victory screen with everyone's kills, deaths,
    assists and combat score and the MVPs, before the next starts on the same server -
    [research and design](docs/research/21-drop-in.md)
22. **The map vote**: Skirmish B and C, built beside A from Riot's minimaps, so Skirmish has the
    reference's three maps, sharing one hall. A server's first match is on one of them at random,
    and after each victory screen everyone votes for the next for 15 s, clicking one of three map
    cards that each show the map's plan. The most votes wins, a tie or no votes at all is settled
    at random, and the next match starts on it - [research and design](docs/research/22-map-vote.md)
23. **Gun game**: Counter-Strike's Arms Race played in the arena with the reference's guns, on
    Skirmish's three maps and with the same vote between matches. Each player climbs a ladder of
    12 guns, one kill a level, from the Vandal or the Phantom to the knife, with a gun of each kind
    picked at random for each match. A kill on the knife's level wins the match for the killer's
    side, or after 10 minutes whoever is furthest up, and a knife kill also knocks the one killed
    down a level. The dead are back in 1.5 s and can't be hurt for 5 s or until they fire. Up to
    four a side, with no buying, no abilities and no guns on the ground -
    [research and design](docs/research/23-gun-game.md)
24. **The Play menu**: as Counter Blox's main screen, a live server opens on a menu of the modes,
    Skirmish (2v2), gun game (4v4) and the spike rounds as Unrated, Competitive and Swiftplay
    (5v5), each with how many play it. Each server plays one mode: a public server Skirmish, and
    PLAY for its mode drops you into its match under way. PLAY for another mode, or for this one
    once its match is full, teleports you to the fullest server playing it with a place free, or
    to a new one. Every server keeps a line in a memory store that every server reads, for where
    to send players and the menu's counts. M opens the menu again during a match. In Studio, which
    can't teleport, PLAY for another mode switches the server to it -
    [research and design](docs/research/24-play-menu.md)
25. **The spike rounds' maps**: Quarry and Foundry, two maps of our own for five a side beside
    Outpost, laid out as the reference's traditional maps are, with two sites and three lanes. A
    server's first spike match is on one of the three at random, and after each victory screen
    everyone votes for the next, as in Skirmish. The tests check every map the same way: every
    room reached, no sightline from one spawn into the other, barriers that hold each side in, and
    the defenders at each site first - [research and design](docs/research/25-spike-maps.md)
26. **Deathmatch**: the reference's FFA Deathmatch on the spike rounds' three maps, a sixth mode on
    the Play menu. Up to 14 play, each for themselves, and the first to 40 kills wins, or whoever
    has the most after 9 minutes. The dead are back in 1.5 s wherever no enemy sees them or is
    near, close to the fight and away from where they fell, facing open floor. Every death leaves
    a health pack for 10 s that heals in full and reloads, and every kill reloads the killer's
    gun. Every gun is free at any time, every life wears Heavy Armor, and there are no abilities,
    so no glide. The victory screen shows everyone in their places, then the vote for the next
    map - [research and design](docs/research/26-deathmatch.md)
27. **Team Deathmatch**: the reference's 5v5 Team Deathmatch on the spike rounds' three maps, a
    seventh mode on the Play menu. The first side to 100 kills wins, or the side with more after
    9 minutes 30 seconds, in four stages; a tie is a draw. B picks a loadout for each stage, a gun
    and its shield, before the match or in your spawn room, and each new stage hands its loadout
    over a moment in. The dead are back in 1.5 s in their side's spawn room, can't be hurt for 15 s
    or until they fire or leave it, and the room burns anyone who stays after that, as the other
    side's does at once. Then the victory screen, `DRAW` for a tie, and the vote for the next map -
    [research and design](docs/research/27-team-deathmatch.md)
28. **Team Deathmatch's pickups**: four weapon spawners on each map, each with a gun of the stage's
    at random and limited rounds, lent in place of your loadout's until it's spent or G destroys
    it; two Recovery Orbs, which mend health and shield over 6 s, leave a zone that mends allies
    who walk in, and come back after 30 s; and two Ultimate Orbs, up together every so often, worth
    10 points each. Abilities recharge over time, each at its own rate and kept through a death,
    and Blade Storm needs 60 points, 3 a kill. The tests hold every pickup out on the floor and
    about as quick a run from either side's spawn -
    [research and design](docs/research/28-tdm-pickups.md)
29. **Agent select**: each player plays their own agent in Skirmish, the spike rounds and Team
    Deathmatch. Once a match you have 10 s to pick one, from the match's start or from when you
    join it under way: T opens the agent select screen, with a card for each agent, the kit of the
    one selected, what your teammates have selected and LOCK IN, and when the time's up the agent
    selected is locked in for the rest of the match. On the course and while a mode waits for
    players, an agent picked is yours at once, as in the reference's Range. An agent locked in goes
    on your kit at once where nothing's lost by it (a buy phase, the pre-game, your own spawn room,
    or while you're down), or else with your next life, and in the spike rounds what you'd bought
    into the last agent's kit this buy phase is sold back. Jett and Phoenix (system 30) are the
    agents to pick from - [research and design](docs/research/29-agent-select.md)
30. **Curveball**, Phoenix's flash: Phoenix joins Jett in agent select with his whole kit on the
    bar, and Curveball, his signature, is the first of it played. E readies a flare in 0.8 s;
    mouse 1 throws it curving round to the left and mouse 2 to the right, and your gun is back
    0.48 s later. It flies straight for a moment, turns a quarter round, stops against a wall, and
    pops 0.6 s after the throw, blinding everyone who can see it, you and your side too: the
    screen goes white for up to 1.5 s, longest looking straight at it from close by and briefly
    turned away, then clears over a second. The server decides who's blinded and for how long,
    and others see a glow on a blinded player's face. It holds two charges at 250 credits, with
    one free every round and one back for two kills -
    [research and design](docs/research/30-curveball.md)
31. **Hot Hands**, Phoenix's fire: Q readies a fireball in 0.8 s; mouse 1 throws it and mouse 2
    lobs it underhand, and your gun is back 0.7 s later. It falls gently as it flies, comes back off
    walls and ceilings, and bursts on the first floor it meets, dropping straight down if it's
    still in the air 1.5 s after the throw. Its fire spreads over the floor to 9 m across, no
    further than the walls round it let it, and burns for 4 s: 60 a second to enemies standing in
    it, however they jump, and a third of that to allies, credited to the thrower for the kill.
    Phoenix heals in his own fire instead, which is his passive, Inner Fire: 50 health over 4 s
    from his first touch of each fire, going on if he leaves it. Since Patch 9.10 it's one charge
    at 200 credits, with none free - [research and design](docs/research/31-hot-hands.md)
32. **Blaze**, Phoenix's wall of fire: C readies a flame in 0.8 s; mouse 1 sends a line of fire out
    along the floor from your feet, 21 m in 0.75 s, up steps and boxes and through walls, and while
    it's held the line bends towards your crosshair, at up to 180 degrees a second; your gun is back
    0.5 s after you let go, or once its run's over. Where it ends, a wall of fire 4 m tall rises
    from your end and spreads to the far end in half a second, and stands for 8 s: nobody sees
    through it, enemies standing in it burn 30 a second and allies a third of that, and Phoenix
    heals in it instead, 50 over 8 s (Inner Fire). One charge at 150 credits, with none free -
    [research and design](docs/research/32-blaze.md)
33. **Run it Back**, Phoenix's ultimate: X, once its 7 points are full, marks where you stand, and
    for the next 10 s a hit that would kill you doesn't. Your body goes instead, and 1 s later you
    rise at the mark, held there 1.4 s more, facing the way you did as you cast it, with full
    health, the shield you had then and your guns reloaded. If nothing kills you, its 10 s running
    out brings you back the same way. While your body's gone nothing hurts you and shots go through,
    and a hit it spared counts for nobody - [research and design](docs/research/33-run-it-back.md)
34. **The minimap**, at the top left: the map from above, drawn from the level's own plan, with you,
    your side and the way each of you looks, the enemies your side sees, the spike, the clouds,
    walls of fire and fires that are out, and a white circle as far as the sounds you make are
    heard. The server works out who each side sees twenty times a second, through the level, the
    clouds and the walls of fire, and nobody blinded white sees anyone; an enemy it stops seeing
    leaves a faded mark where they were for 3 s. Caps Lock held opens the big map, with the
    places' names, and the settings menu has the reference's map settings -
    [research and design](docs/research/34-minimap.md)

## Running it

1. Install [Rojo](https://rojo.space) 7.x and the Rojo Studio plugin.
2. `rojo serve` in this folder, connect from Studio, press Play.
3. With no `Map` in Workspace, a measurement course with a target lane and practice dummies is
   built automatically. Look straight ahead from the spawn to face the lane; the wallbang lane is
   to the left, and the spike's two sites are 26 m behind you, with the spike waiting 4 m
   behind. In a place made from the Baseplate template, delete its `Baseplate` and
   `SpawnLocation` first.
4. The arena is built beside the course, off to its right, and the spike rounds' three maps off
   to its left. A live server starts the arena by itself; in Studio you start on the course, and
   P puts everyone in the server in the arena: you spawn in your side's room and wait there for an
   opponent, and whoever joins goes on the side with fewer players. After each match everyone
   votes for the next of Skirmish's three maps. P again starts gun game in the same hall, P again
   the spike rounds, on three maps of their own with the same vote, P again their shorter
   Swiftplay format, and P again puts everyone back on the course. A live server opens on the
   Play menu, and only once you press PLAY are you in a match; in Studio M opens the menu, where
   PLAY for another mode switches the server to it, as P does. Both deathmatches are only on the
   menu. PLAY's teleports between servers only work once the place is published.
5. For a first full check, follow the [Studio test session](docs/studio-checklist.md): every
   system's Studio checks in order, with what each lab should read.

Controls: WASD, Shift walk, Ctrl crouch, Space jump, mouse 1 fire, mouse 2 zoom / scope,
R reload, 1/2/3 primary / secondary / knife (mouse 1 slashes and mouse 2 stabs), 4 the spike
while you carry it (hold 4 to plant it in a site or to defuse it), G drops the gun or the spike
in hand, F picks up the gun on the ground you're looking at, B buy menu (on the course at any time; in the arena
during the buy phase and while waiting for an opponent; in deathmatch any time, guns alone; in
Team Deathmatch B is the loadout menu, before the match or in your spawn room), Tab
held the scoreboard (the arena and the spike rounds), mouse 1 and 2, while you're down in either,
the next or the last teammate to watch,
a click on a map card, during the vote after a match, your vote for the next map,
M the Play menu (a click picks a mode's card, and PLAY plays it), Caps Lock held the big map,
T agent select (a click selects an agent's card, and LOCK IN locks it in),
C Cloudburst (held, it curves the throw), Q Updraft, E Tailwind (E readies the gust,
and E again within its window dashes) and X Blade Storm (mouse 1 throws a knife and mouse 2 all
that are left; with a gun drawn, X draws the knives again). Space held in the air glides (Jett's
Drift). As Phoenix, E readies Curveball's flare: mouse 1 throws it curving left, mouse 2 curving
right, and E again puts it away; Q readies Hot Hands' fireball: mouse 1 throws it, mouse 2 lobs it,
and Q again puts it away; C readies Blaze's flame: mouse 1 sends its wall, held it bends the wall
towards your crosshair, and C again puts it away; X marks where you stand for Run it Back. The
spike rounds charge credits; the course and the arena are free.
On the course a spent charge comes back 1.5 s after it's done, and the ultimate's points are full at
every life and fill again 1.5 s after Blade Storm ends or Run it Back brings you back; in the arena
every life starts with every charge, in Team Deathmatch spent charges come back over time, and gun
game and deathmatch have no abilities.
O settings: sensitivity, scoped multiplier, mouse DPI (only for the cm/360 it shows), a
crosshair code (Enter takes a box's value; DEFAULT puts back the reference's own crosshair) and
the minimap's: Rotate or Fixed, the same way round or by side, kept centred, its size and zoom,
the vision cones, and when the big map names its places.
Look: V turns it off and on again (lighting, vignette and outlines), to compare with the place's
own lighting; N cycles the enemy outline colour.
Arena: P moves on through the arena, gun game, the spike rounds, Swiftplay and off (Studio or
place owner only). In the arena and the spike rounds, the buy menu and the debug keys 5-9 (below)
work for anyone during the buy phase, and while waiting for an opponent; the debug keys stay free
in the spike rounds. A new match in the arena puts everyone back on its starting kit (Vandal,
Classic, knife, Heavy Armor); in the spike rounds, each half and each death leaves you the Classic
and the knife, with no shield, and 800 credits at each half. Gun game has neither the buy menu nor
the debug keys: each life starts on your level's gun, the knife and Heavy Armor, a kill puts the
next gun in your hands at once, and G does nothing, as its guns can't be dropped.
Debug: F2 weapon lab, then spray lab, hit reg lab and sound lab on further presses, F3 HUD (on at
the start in Studio, off on a live server; with the next shot's cone round the crosshair, how far
the crosshair's lines have spread and the last jump measured; G with the HUD on and the knife in
hand shows the server ghost), F4 counter-strafe lab (Z zeroes its cm/360 counter, Backspace clears
its stops), F6 record CSV, F10 hitbox overlay, Backspace clear impact marks, counters and the spray
plot, 5-9 give Vandal / Phantom / Operator / Sheriff / Classic (Studio or place owner only). F7 and
F8 are left alone because Studio takes them for Start and Run.
In the hit reg lab: `[` / `]` simulated latency, J jitter, L packet loss, U Network Buffering,
K rewind cap 140 / 200 / 0 ms (0 is no lag compensation); its motion line measures how evenly the
player or dummy nearest the crosshair moves.
In the sound lab: `[` / `]` footstep radius (this client only), Y practice dummies' footsteps
(off by default), H the rings sounds draw on the floor, Backspace clears its log.
Scripted playtests (Studio only): a tool that can press keys but can't move the mouse aims by
setting attributes on the local player, `VFTestYaw` / `VFTestPitch`, `VFTestAimPoint` or
`VFTestAimEntity` with `VFTestAimRegion` ([TestAim](src/client/Debug/TestAim.luau)). `VFTestButtons`
holds input flags on top of the real ones (128 fire or slash, 256 right click or stab, 512 reload,
1024 the spike's 4 held, 2048 G, and the ability keys: 4096 C, 8192 Q, 16384 E and 32768 X),
`VFTestGive` set to a weapon id gives that weapon as 5-9 would (`spike` hands over the course's
spike), `VFTestBuy` set to an id buys it as the menu would (`-` and the id sells it back),
`VFTestMenu` set to true or false opens or closes the menu, `VFTestSlot` set to 1, 2, 3, 4 or 5
draws that slot (5 is Blade Storm's knives), `VFTestSettingsMenu` set to true or false opens or
closes the settings menu, `VFTestSetting` set to `key=value` (`sensitivity=0.8`, `scoped=0.5`,
`dpi=1600`, `crosshair=0;P;c;5` or `mapRotate=0`) enters that setting as its box or button in the
menu would, `VFTestMap` set to true or false opens or closes the big map as holding Caps Lock does,
`VFTestTake` set to true presses F, `VFTestBoard` set to true or false holds the scoreboard open as
Tab does or lets it go, `VFTestVote` set to 1, 2 or 3 votes for that map card as a click would,
`VFTestPlayMenu` set to true or false opens or closes the Play menu, `VFTestPlay` set to a mode's
key (`skirmish`, `gungame`, `deathmatch`, `teamdeathmatch`, `standard`, `competitive` or
`swiftplay`) presses PLAY for it, `VFTestLoadouts` set to true or false opens or closes Team
Deathmatch's loadout menu, `VFTestPick` set to `2,3` picks the second stage's third loadout as a
click would, `VFTestAgents` set to true or false opens or closes agent select as T does, and
`VFTestAgent` set to an agent's id (`jett`) selects it as a click on its card would, or set to
`lock` locks in. Each of the last sixteen clears itself.
`VFTestMute` on the local player silences the game's sound while the sound lab's meters still read.
From the server, Workspace's `VFArenaMode` (`skirmish`, `gungame`, `spike`, `deathmatch` or
`teamdeathmatch`), `VFMatchFormat` (`standard`, `competitive` or `swiftplay`) and `VFArenaOn`
choose what's played, and `VFMatchSkip`
set true ends the phase under way (a buy phase, a round, the wait for the next, a gun game match,
the victory screen or the vote; a Skirmish round goes to side 1, and a gun game match to whoever is
furthest up). The arena's model says which map is played (`Map`: `A`, `B` or `C` in the arena,
and `outpost`, `quarry` or `foundry` in the spike rounds, whose maps are models in Workspace's
`VFSpikeMap`), and during the vote the maps to pick from and their votes (`VoteMaps`, `Votes`),
with each player's own vote as `VFMapVote`. In gun game it also has the match's guns, a level
each (`Ladder`, as `vandal,phantom,...`), and the UserId of whoever is furthest up, or won
(`Leader`), and each player's level is their `VFGunLevel` attribute, with `VFProtected` true while
their spawn protection lasts. In the spike
rounds each player's credits are their `VFCredits` attribute, and each side's losses in a row
`Streak1` and `Streak2` on the arena's model. Every gun on the ground is a part in Workspace's
`VFGroundGuns`, with its `Weapon`, `Ammo` and `Reserve` as attributes. Each player's record is in
their attributes too: `VFKills`, `VFDeaths`, `VFAssists`, `VFScore`, `VFRounds`, `VFAlive` and
`VFLoadout` in either, and `VFStartCredits` in the spike rounds. `VFInLine` is a player's place in
line while both sides are full. Each player's ability kit is their
`VFKit` attribute, as `C0/2 Q1/1 E1/1 X0/8` (charges and most, then the ultimate's points), with
what's under way after it (`storm` while Blade Storm lasts, `glide` while you glide, `equip`
while Curveball's flare, Hot Hands' fireball or Blaze's flame is in hand, `bend` while a Blaze
wall is bent, `back` while Run it Back runs, and `away` and `rise` through its return), and
`VFTestBuy` set to `updraft` buys a charge. A player's agent is their `VFAgent` attribute, what
they've selected while they can pick `VFAgentSelected`, where they stand `VFAgentPick` (`free`,
`open` or `locked`, unset where nobody picks), and while their window's open, when it closes
(server time) `VFAgentCloses`. Where a player's last Cloudburst burst is their
`VFLastCloud` attribute (metres), and `Workspace.VFClouds` holds each throw in the air and each
cloud as parts. Where a player's last Curveball popped is their `VFLastFlare` attribute (metres),
and their blind their `VFBlind` (when it began, when its white ends and when it's gone, in server
time); `Workspace.VFFlares` holds each flare in the air and each pop as parts. Where a player's
last Hot Hands burst is their `VFLastFire` attribute (the floor under it, in metres), and
`Workspace.VFFires` holds each fireball in the air, each burst and each fire as parts. The far end
of a player's last Blaze wall is their `VFLastWall` attribute (metres), and `Workspace.VFWalls`
holds each wall's run on its way and each wall as models. Where a player last cast Run it Back is
their `VFLastMark` attribute (metres), and `Workspace.VFRunItBack` holds each mark as a model, its
`Entity` attribute whose it is. The minimap's ScreenGui, `VFMinimap`, carries what it shows: the
plan drawn (`Plan`, as `spike:quarry`), the entity ids of the enemies on it (`Seen`), whether the
spike is (`Spike`), how far it's turned (`Turn`, degrees) and whether the big map's open (`Big`).
Workspace's
`VFPlayMenu` is whether players start in the Play menu (always on a
live server; in Studio, tick it in the place before you press Play), and `VFModeCounts` how many
are in servers playing each mode (`skirmish=6,gungame=0,...`). A player's `VFPlaying` is true once
they've pressed PLAY on this server. The `Play` remote carries PLAY to the server, and what came of
it back.

## Tests

The shared simulation (movement, weapons and every gun's way of firing, the knife's swings and what
they catch, the spike's plant, defuse and drop, spread and recoil, hitboxes, wire formats, pose
history, render clock, move pacing, lag compensation and wall penetration), the look's maths, the
arena's rules and its three maps, the vote for the next map, gun game (its ladders of guns, levels,
knife kills, spawn protection, the time limit, and joining, leaving and evening the sides out in a
match), the Play menu's modes and its list of servers (what each server plays, which server PLAY
sends someone to, and the counts), the sound's rules (footsteps, landings,
distance curves, walls in the way, reload parts), the settings (crosshair codes and the pixels they
draw, sensitivity and cm/360), the spike's rules (sites, the defuse's reach, its beeps and its
blast), the spike rounds' rules and maps, the economy (what each round pays, kills, the plant, the
cap, what a purchase costs and the shield a survivor keeps), guns on the ground (G's drop, what the
dead drop, walking over one and the one in view), the match's record (the combat score, kills,
deaths, assists and the average), who plays on which side (dropping in, the line and evening the
sides out), the ability kit (charges through rounds, halves, kills and deaths, buying them,
Updraft's height and Tailwind's dash, and the kit on the wire), Cloudburst (the throw, its flight,
its curve and what stops it, and the cloud's life), Blade Storm (the cast, single throws and the
burst, the kills that bring the knives back, swapping, and what ends it), Drift (the glide from a
jump, a ledge and Updraft, a press in a fall, landing with jump held, and what it leaves alone),
agent select (where each player picks, the window, locking in, the time running out, a swap at
once or with the next life, and what's sold back), Curveball (Phoenix's kit, the flare in hand, its
throw and flight, the blind, and the kit on the wire), Hot Hands (the fireball in hand, its
flight off walls and ceilings to the floor, its fire and who stands in it, the burn, Inner Fire's
heal, and the wire), Blaze (the flame in hand, sending and bending the wall, its run up boxes,
through walls and down ledges, the wall and who stands in it, the burn, Inner Fire's heal, and the
wire), Run it Back (the cast and its activation, running out, the return and the rise, a hit it
spares, a plant under way, and the wire) and the minimap (who sees whom through the level, clouds
and walls of fire, every map's plan, the views each setting gives, allies held on the edge, the
spike's and the names' rules, and the cones' rays) are pure Luau and run outside Roblox:

```
luau tests/run.luau
```

It prints metrics reports (start, stop and counter-strafe timings per weapon; air drift, air stops
and how far air strafing bends a jump; fire rate, magazine and time-to-kill per weapon; cone and
recoil by bullet, and tapping recovery, per weapon; client and server agreement on a strafing
target through a simulated network; how evenly other players and dummies are drawn, paced and
not; damage left through walls by class, material and thickness; the vignette across the screen
and the outline's tint by distance; the arena's size and how much of it each spawn can see; the
footstep curve, steps per second by weapon, and the filters for walls and distance; cm/360 at
the default sensitivity, unzoomed and scoped; how long each side takes to reach each spike map's
sites) and runs the test suites. CI also type-checks everything with `luau-lsp` and Roblox
definitions.

## Rules for this project

- No game memory access, no anti-cheat circumvention, no extracted assets.
- Every gameplay number carries a status: confirmed, community, measured (ours, from a public
  source) or estimate, with its source.
- Gameplay is server-authoritative; clients predict.
