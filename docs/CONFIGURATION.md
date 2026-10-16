# Configuration guide

Edit `vorp_stables/config.lua`; stable positions and local shop lists are in `locations.lua`. Examples are fields **inside the existing Config table**, not another Config table to append.

| Option | Purpose |
|---|---|
| Locale | en / cs; English fallback |
| Command / OpenKey | Nearby menu command and default G prompt |
| CallHorseKey / CallCartKey | Default H / J |
| WhistleOnCall | Uses VORP character's existing whistle style |
| MaxHorses / MaxCarts / StableSlots | Horse, wagon and combined capacities |
| DisableBuyOption | Disable new shop purchases |
| JobRequired / JobFor…Dealer | Shop job restrictions |
| WagonSellPercent | Buyback percentage, default 60 |
| TransferDistance | Online negotiated-transfer distance |
| SpawnCooldown | New-spawn delay in milliseconds |
| HorseCallDistance | Minimum 35m; search capped at 80m |
| FleeDespawnMs | Dismissed horse cleanup delay |
| EnableLeading | Owned riding-horse leading |
| EnableDraftLeading | Experimental, defaults false after native rejection |
| InteractionDistance | Wagon interaction range, including long teams |
| ShowBlips / SpawnNPCs | Stable map icons and hands |
| MenuReading | Book-reading scenario while browsing on foot |
| PreviewCamera | Horse/wagon FOV and horse use of wagon display area |
| Preload / EntryTimeoutMs | Streaming distances, concurrency, timeout |
| Thumbnails | Model/component image mapping |
| DefaultMaxWeight / CustomMaxWeight | Default/per-model inventory adapter limits |
| StackInvIgnore | Inventory adapter stack-limit policy |

## Money and gold example

```lua
Payments = {
    GoldEnabled = true,
    CashPerGold = 25,
    GoldPrices = {
        A_C_Horse_AmericanStandardbred_Black = 4,
        ['275341736'] = 1.25,
    },
},
WagonSellPercent = 60,
```

Cash is VORP currency 0; gold is currency 1. A displayed inventory gold item represents that wallet, not another balance to charge. Conversion rounds up to 0.01 gold. Overrides use an exact model or component-hash string. Choose your server's own economy rate. Disabling GoldEnabled hides/rejects gold purchases. Player-to-player offers use cash.

New wagon receipts remember paid price and currency. A 100-cash wagon sells for 60 cash at the default rate; a 4-gold wagon sells for 2.4 gold. Legacy records without receipts use the catalogue fallback. Read the displayed confirmation before selling.

## Limits and presentation example

```lua
Locale = 'cs',
MaxHorses = 3,
MaxCarts = 1,
StableSlots = 4,
ShowBlips = true,
SpawnNPCs = true,
PreviewCamera = { HorsesUseWagonSpot = true, HorseFov = 28.0, WagonFov = 60.0 },
MenuReading = { Enabled = true, Scenario = 'WORLD_HUMAN_SIT_GROUND_READING_BOOK' },
```

Translations live in locales/en.json and cs.json. Preserve `{name}` and similar placeholders. Player-chosen names remain unchanged; technical logs stay English.

Large catalogues with AllModels=true consume more streaming memory. Reduce local vendor lists or set AllModels=false for lighter first-model preparation. There is no universal best configuration for all game builds/hardware.

Each location needs entrance/NPC, preview positions and cameras. Check long-wagon clearance on staging. An IPL alone does not create stable interactions. After deploying manifest changes, refresh resource metadata before restarting.
