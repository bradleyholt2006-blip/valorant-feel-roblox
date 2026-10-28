# System 57: Buying for teammates

In the reference, a player short of credits right-clicks a gun in the buy menu to ask their team for
it, and a teammate with the credits buys it for them from the menu, with no gun dropped on the
floor. TechSpot: "Valorant lets you right-click on a weapon in the buy menu, and then your character
will request it." Riot's patch notes say how it settles: a gun bought this way can be "sold back to
the shop, doing so will refund the player who fulfilled the request" (Patch 1.10). Until now ours
had teammates buy for each other only the old way, as system 15 left it: buy a gun and drop it (G)
for a teammate to pick up. This system adds the request. In the spike rounds, where guns cost
credits, a right click on a gun you don't have asks your team for it, and another takes that back. A
team panel left of the buy menu has a card for each of your side, you first: their credits, gun and
shield, plan, and the gun they're asking for, with BUY to buy it for them. The buyer pays its price,
and the gun goes into the teammate's slot as theirs, drawn, as if they'd bought it. Selling it back
refunds the buyer, as does buying something else into its slot; dropped, it's gone. The panel's
three buttons tell your team your plan: saving, buying, or extra credits to buy for them.

As before, everything comes from public sources: Riot's patch notes (0.50, 1.03, 1.10 and 8.11), two
Riot developers' posts, and for what Riot doesn't give, guides and the press (TechSpot, Dignitas,
GamersDecide, PlayerAssist, ONE Esports, EarlyGame, a Medium guide, Turbosmurfs, Eloboss, Gameriv
and GGRecon). No game files, memory or network traffic were used, and nothing was read from the live
game. Riot gives that a gun bought on request can be sold back for the buyer's refund, that two
buying the same request at once was a bug, that buying one doesn't stop your movement, that the menu
has a slot for each teammate, and, in a developer's words, that a request is bought as the funds for
the teammate's own gun. The community gives the right click, where requests show and how they're
bought, the plans, and that a dropped gun can't be sold back. Nothing in this system is measured.
Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes, or a Riot developer) |
| **Community** | Published by a guide or the press, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source we could read says whether shields or abilities can be asked for, whether a request can be
taken back, how long it lasts, who gets a gun's price back when the teammate it was bought for buys
another into its slot, or how the cards look now. Ours, in section 4: guns alone can be asked for,
and not the free Classic; one request at a time, taken back by asking for it again, and gone with
the next round; buying another gun into its slot refunds the teammate who bought it, as selling it
back does; and the cards are our own plain ones, left of the menu. The reference's teammates hear
the request said aloud; that voice is Riot's, so ours plays the ping's blip (system 52).

## 1. Observable behaviour

- **Asking for a gun** (the community). TechSpot: "Valorant lets you right-click on a weapon in the
  buy menu, and then your character will request it." Dignitas: "if you're short on cash then just
  right click a weapon and your teammates will be able to confirm". ONE Esports: "If you're low on
  credits, you can ask someone to help you buy a weapon by right-clicking it." A Medium guide:
  "Simply open your buy menu, hover over the gun you want, then right-click it, that's it!"
  Turbosmurfs: "The Request button on any weapon in the buy menu pings your team for a drop."
- **Teammates see it and hear it** (Riot and the community). TechSpot: "Your teammates can see this,
  hear an automated shout-out, and anyone with the cash can click the 'purchase' option".
  GamersDecide: "If your credits are enough, their request should be seen on the left part of the
  weapon store." PlayerAssist: "Look for your teammate who just 'requested' an item on the
  right-hand side of the Buy Menu." Eloboss: "If he wants you to help him, he can buy it on his card
  in the Buy menu." Patch 8.11 speaks of the menu's "team member slots".
- **Buying it for them** (Riot and the community). GamersDecide: "Clicking on it automatically buys
  the weapon for them and the price will be deducted from your credits." PlayerAssist: "Click on the
  'Buy It' button to purchase the item for them." Dignitas: "No more dropping weapons on the floor
  for teammates like in CSGO, it all goes through an easy to use buy menu now." A Riot developer,
  ProgRocktopus: "We think of fulfilling a gun request as giving them the funds to buy their own
  gun", "rather than giving them a gun from your arsenal." Patch 1.03: "Fulfilling a buy request
  while moving will no longer interrupt your movement". Patch 0.50: "Fixed bug where various issues
  would occur after multiple players would fulfill a weapon buy request at the same time".
- **Selling it back** (Riot and the community). Patch 1.10: "Requested guns can now be sold back to
  the shop, doing so will refund the player who fulfilled the request". PlayerAssist: "the Credits
  you used to purchase the item/gun will be credited back to you.", and "This only works if your
  teammate presses right-click on the same item/weapon in the Buy Menu without dropping the weapon."
  For a while after 1.10 the refund could go missing. Gameriv, of a player bought a Phantom who sold
  it for a Vandal: "the 2900 credits disappear from their buy menu." A Riot developer, Brandon Wang,
  via Gfinity: "We are aware of this issue, and while it may not land in the current patch". GGRecon
  quotes daps: "When you resell a weapon someone buys you they do not get their money back always."
- **Plans** (the community). Dignitas: "Using the buttons in the buy menu, you can indicate if you'd
  like to save, buy, or offer to spend your extra credits". TechSpot: "Valorant's beautiful perfect
  buy screen includes buttons to tell your teammates you're saving, or have extra credits".
  GamersDecide: you "can click on the 'I have extra credits' button on the upper left portion of the
  buy window.", and "This will let your teammates know that you can buy for them."
- **Teammates' credits** (the community). EarlyGame: "You can see the exact amount of credits each
  player has at their disposal." Turbosmurfs: "The scoreboard shows each teammate's credits during
  the buy phase." Ours had them on the scoreboard already (system 16).

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Fixed bug where various issues would occur after multiple players would fulfill a weapon buy request at the same time" | [VALORANT Patch Notes 0.50](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-0-50/), Jeff Landa, 12 May 2020 |
| "Fulfilling a buy request while moving will no longer interrupt your movement" | [VALORANT Patch Notes 1.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-03/), Jeff Landa, 7 July 2020 |
| "Requested guns can now be sold back to the shop, doing so will refund the player who fulfilled the request" | [VALORANT Patch Notes 1.10](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-1-10/), Jeff Landa, 13 October 2020 |
| "Ally utility is now visible on team member slots for easier strategization."; "Holistically added animations to increase clarity around affordability, requesting and weapon purchases." | [VALORANT Patch Notes 8.11](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-811/), Riot Tiny Frogo, 11 June 2024 |
| "This was our conclusion, too, after debating it for a while."; "We think of fulfilling a gun request as giving them the funds to buy their own gun", "rather than giving them a gun from your arsenal."; "you can always share your own skins by buying and dropping the old fashioned way." | ProgRocktopus on r/VALORANT (2020), via [devtrackers.gg](https://devtrackers.gg/valorant/p/a8391eae-if-you-buy-a-weapon-for-your-teammate-he-should-get-it-with-your-skin) |
| Of a teammate's refund going missing: "We are aware of this issue, and while it may not land in the current patch"; "trying our best to get it fixed in an upcoming one." | Brandon Wang on Reddit, 12 January 2021, via [Gfinity](https://www.gfinityesports.com/valorant/valorant-buyback-glitch-fix-dev-confirms-a-fix-is-coming-the-future/), Gemma Le Conte, 13 January 2021 |

### From the community

| What | Source |
| --- | --- |
| "Valorant lets you right-click on a weapon in the buy menu, and then your character will request it."; "Your teammates can see this, hear an automated shout-out, and anyone with the cash can click the 'purchase' option"; "Valorant's beautiful perfect buy screen includes buttons to tell your teammates you're saving, or have extra credits" | [TechSpot, on Valorant](https://www.techspot.com/article/2038-valorant-takes-aim/) |
| "Using the buttons in the buy menu, you can indicate if you'd like to save, buy, or offer to spend your extra credits"; "if you're short on cash then just right click a weapon and your teammates will be able to confirm"; "No more dropping weapons on the floor for teammates like in CSGO, it all goes through an easy to use buy menu now." | [Dignitas, an easy economy guide](https://dignitas.gg/articles/an-easy-valorant-economy-guide), Sui, 14 April 2020 |
| "Valorant has a request system where you can buy guns for others if you have extra credits."; "can click on the 'I have extra credits' button on the upper left portion of the buy window."; "This will let your teammates know that you can buy for them."; "Teammates can request from you by right-clicking on the weapon."; "If your credits are enough, their request should be seen on the left part of the weapon store."; "Clicking on it automatically buys the weapon for them and the price will be deducted from your credits." | [GamersDecide, on buying for someone](https://gamersdecide.com/articles/valorant-how-buy-someone), Romeli Daclizon, updated 27 November 2022 |
| "Look for your teammate who just 'requested' an item on the right-hand side of the Buy Menu."; "Click on the 'Buy It' button to purchase the item for them."; "the Credits you used to purchase the item/gun will be credited back to you."; "This only works if your teammate presses right-click on the same item/weapon in the Buy Menu without dropping the weapon." | [PlayerAssist, on buying for teammates](https://playerassist.com/valorant-how-to-buy-items-for-teammates/), John Paul Santiago, 26 June 2023 |
| "If you're low on credits, you can ask someone to help you buy a weapon by right-clicking it."; "This goes both ways, so remember to buy your teammates' weapons when you have a good amount of credits." | [ONE Esports, on the HUD](https://www.oneesports.gg/valorant/valorant-beginners-guide-understanding-the-hud/), Nigel Zalamea, 22 July 2023 |
| "Simply open your buy menu, hover over the gun you want, then right-click it, that's it!" | [A Medium guide, on requesting a gun](https://medium.com/@Luckofbuck/how-to-request-a-gun-in-valorant-560f76bf06d), Ben Bowden, 20 April 2020 |
| "You can either request a drop in the buy menu by right-clicking on the weapon"; "You can see the exact amount of credits each player has at their disposal." | [EarlyGame's economy guide](https://earlygame.com/valorant-economy-guide), Antonio Kaurinovic, 27 September 2020 |
| "The Request button on any weapon in the buy menu pings your team for a drop."; "The scoreboard shows each teammate's credits during the buy phase." | [Turbosmurfs' economy guide](https://turbosmurfs.gg/article/valorant-economy-guide), 28 September 2026 |
| "If he wants you to help him, he can buy it on his card in the Buy menu." | [Eloboss's economy guide](https://eloboss.net/blog/valorant-economy-guide), Henry Walker, updated 8 July 2026 |
| "the credit sell-back bug appears when a player tries to sell back a weapon that their teammates originally purchased."; "the 2900 credits disappear from their buy menu." | [Gameriv, on the sell-back bug](https://gameriv.com/valorants-annoying-credit-sell-back-bug-might-be-fixed-with-patch-2-1-confirmed-by-a-dev/), Nafiu Aziz, 14 January 2021 |
| "A big addition to October's Act 3 1.10 update added the ability to sell back guns bought for a teammate."; daps: "When you resell a weapon someone buys you they do not get their money back always." | [GGRecon, on selling back team guns](https://www.ggrecon.com/articles/valorant-players-buy-back-feature-refund-team-guns) |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| Whether shields and abilities can be asked for | Public clips of the buy menu, right-clicking a shield |
| Whether asking again takes a request back, and how long one lasts | Public clips of requests through a buy phase |
| Whether a gun bought for you is drawn | Public clips from the asker's view |
| Who gets a gun's price back when the teammate it was bought for buys another into its slot | Public clips of both players' credits as it happens |
| How the cards and the plans look now, and where they sit | Public clips of the current buy menu |
| How several requests at once show | Public clips with several teammates asking |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Asking | A right click on a gun you don't have, in the spike rounds, asks your team for it; on one bought this buy phase it sells it back, as before | Community (TechSpot, Dignitas, ONE Esports, the Medium guide) |
| What can be asked for | A gun that costs something: not the free Classic, a shield or an ability | Estimate (the sources speak of guns alone) |
| One at a time | Asking for another gun replaces the request; asking for the same one again takes it back | Estimate |
| How long it lasts | Until it's bought, by anyone, or the asker gets the gun another way, or their next life (the next round) | Estimate |
| Who sees it | Their side: the asker's card in the team panel shows it, and the ping's blip plays | Community (TechSpot, GamersDecide, PlayerAssist, Eloboss); confirmed (team member slots, Patch 8.11); estimate (the blip, for the reference's voice) |
| Buying it | BUY on the asker's card, for its price in credits, which the buyer pays | Community (GamersDecide, PlayerAssist) |
| Whose it is | The asker's, in its slot as if they'd bought it, and drawn | Confirmed (a developer's post); estimate (drawn) |
| Bought once | The first to buy it does; a second finds the request gone and pays nothing | Confirmed (Patch 0.50 fixed it going wrong); estimate (how) |
| Moving | Buying never stops you moving | Confirmed (Patch 1.03) |
| Selling it back | Refunds the buyer its price, and the slot goes back to what it began the buy phase with | Confirmed (Patch 1.10); community (PlayerAssist) |
| Buying another gun over it | The asker pays the new gun's full price, and the buyer gets theirs back | Estimate (as selling it back; Gameriv reported the credits vanishing as a bug) |
| Over a gun the asker bought | Their own goes back to them, as when they buy over it | Estimate |
| Dropped | Gone: nothing to sell back, and no refund | Community (PlayerAssist) |
| A buyer who's left | Their refund is lost | Estimate |
| Plans | Saving, buying or extra credits, one at a time on your card; picking it again clears it, as does the next round | Community (Dignitas, TechSpot, GamersDecide); estimate (how it shows and clears) |
| Teammates' credits | On each card, as they change | Community (EarlyGame) |
| The panel | Left of the menu: you first, then your side by name, up to five cards | Community (GamersDecide's left part; PlayerAssist's right-hand side); estimate (the look) |
| Where | The spike rounds alone, where guns cost credits | Estimate |

## 5. Design

### The rules

- **`TeamBuy`** (new) has the rules, with no Roblox APIs: what can be asked for (`askable`,
  `canAsk`), asking and taking it back (`ask`), plans (`plan`), and why a request can't be bought
  for someone (`refusal`: not a teammate, not what they're asking for, a gun they have, or short of
  credits).
- **`Shop`** remembers who paid for a gun bought into a slot this buy phase (`paid`), buys one for a
  teammate (`give`), says what a slot's purchase goes back for and to whom (`payback`), leaves a
  teammate's gun out of what a purchase over it costs (`cost`), and shares who paid with clients
  (`paidList`, `fromLists`, `VFBoughtBy`).

### The server

- **`ShopServer`** keeps each player's request and plan, takes `request`, `plan` and `fulfil` on the
  Buy remote, buys a request for the asker (the buyer paying, and what the asker had bought into the
  slot going back to whoever paid for it), refunds the buyer as a gun they bought is sold back or
  replaced, clears a request the asker no longer needs, and starts each life with neither.
  `VFRequest` and `VFPlan` carry them to clients.
- **`Arena`** gives each player's side for it, in the spike rounds (`ShopServer.teamOf`).

### The client

- **`BuyMenu`**: a right click asks for a gun (`rightClick`); the team panel left of the menu, in
  the spike rounds, with the plan buttons and a card for each of the side (`buyFor`); the REQUESTED
  tag; hints for a gun bought for you and one you've asked for; the ping's blip for a teammate's
  request; and a gun bought for you drawn.
- **`TestAim`**: `VFTestTeam`, for scripted checks.

### Not here yet

- **The voice.** The reference's agent says the request aloud; ours plays the ping's blip.
- **A request anywhere else.** No source we could read says whether it shows outside the menu; ours
  shows on the cards only.
- **Shields and abilities.** No source says they can be asked for; ours asks for guns alone.
- **Ally utility on the cards** (Patch 8.11). Ours shows credits, gun, shield, plan and request.
- **Riot's look.** The reference's menu and cards are Riot's art; ours are plain panels.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Weapons/TeamBuy.luau` | New: what can be asked for, asking and taking it back, plans, and why a request can't be bought |
| `src/shared/Weapons/Shop.luau` | Who paid for each slot's purchase, `give`, `payback`, `cost` without a teammate's gun, `paidList`, `fromLists`, `PAID_ATTRIBUTE` |
| `src/server/ShopServer.luau` | Requests and plans, `fulfil`, refunds to the buyer, `teamOf`, and `VFRequest`, `VFPlan` and `VFBoughtBy` |
| `src/server/Arena.luau` | `ShopServer.teamOf` in the spike rounds |
| `src/client/BuyMenu.luau` | A right click asking, the team panel and its cards, plans, the REQUESTED tag and hints, the blip, and a gun bought for you drawn |
| `src/client/Debug/TestAim.luau` | `VFTestTeam` |
| `tests/teambuy.luau`, `tests/run.luau` | New: 53 checks: what can be asked for, asking and taking it back, plans, when a request can be bought and by whom, and whose credits go where as a gun bought for a teammate is sold back, replaced or dropped |

## 7. Debug tools

- Each player carries `VFRequest`, the gun they're asking their team for; `VFPlan`, their plan
  (`save`, `buy` or `extra`); and `VFBoughtBy`, who paid for each of `VFBought`'s, in its order (a
  teammate's UserId, or "" for themselves).
- `VFTestTeam` on a player, in Studio: `ask <gun>` right-clicks that gun in the buy menu,
  `buy <UserId>` buys that teammate the gun they're asking for, and `plan <plan>` presses that
  plan's button; then it clears itself.
- `VFTestBuy` and `VFMatchSkip` as before.

## 8. Refinement loop

1. From public clips of the current buy menu, check where the cards sit, what they show, and how a
   request and a plan look.
2. From public clips of an asker's view, check whether a gun bought for them is drawn.
3. From public clips of a gun bought for someone being replaced, check who gets its price back.
4. Check whether shields can be asked for, and how long a request lasts.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- In the spike rounds, the team panel left of the buy menu: a card for each of your side, you first,
  with their credits and gun, and nobody from the other side.
- A teammate asking for a gun: the ping's blip, and their card showing the gun with BUY; their own
  tile for it reading REQUESTED.
- BUY: the buyer pays its price, and the gun's in the asker's hands, bought by the buyer.
- Selling it back: the buyer's credits back.
- The other side can't buy it.
- Asking again takes it back; a plan on the card, gone when picked again.
- Buying another gun over one bought for you: the buyer's credits back; a request for more than the
  buyer has: SHORT, and nothing bought.

Section 61 of the [Studio checklist](../studio-checklist.md) covers these.
