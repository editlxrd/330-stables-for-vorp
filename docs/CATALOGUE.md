# Add models, tack and images

## File map

- `shared/data.lua`: global model prices and component hashes.
- `locations.lua`: vendor availability, local prices, positions and cameras.
- `shared/catalog.lua`: shared formatting and authoritative pricing.
- `server/service.lua`: validated ownership/economic behaviour.
- `server/main.lua`: Core/database/inventory adapter.
- `client/`: prompts, entities, streaming, reading cleanup and interaction state.
- `web/dist/`: compiled UI only; authoring source and source maps are not distributed.

## Add a horse or wagon

1. Choose an exact model supported by your game build.
2. Add its base price to Data.Horses or Data.Carts in shared/data.lua, following adjacent entries:

```lua
A_C_Horse_AmericanStandardbred_Black = 150,
```

3. If a stable has a restricted horses/carts map in locations.lua, add it there too:

```lua
horses = {
    A_C_Horse_AmericanStandardbred_Black = 125,
},
```

A map value overrides that vendor's price. An empty map sells the full corresponding catalogue. A model missing from a non-empty vendor list is unavailable there. Server checks ignore browser-supplied prices.

4. Optional exact gold prices go in Payments.GoldPrices.
5. On staging, check loading, preview, purchase, call, reconnect and storage. A valid string is not proof that the model exists or has safe spawn clearance.

## Equipment

Follow an existing family in Data.Complements. Its **last value is a price multiplier**; earlier entries are component hashes. Final price is that multiplier × EquipmentPriceMultiplier. Do not accidentally add a component after the multiplier. Test components on the intended breed: game combinations can be incompatible.

Purchased variants belong to the character's collection. Each horse saves its fitted pieces separately. Re-equipping an owned variant is free.

## Exact thumbnails

Put a licensed PNG/WebP in web/dist/images, then map its web-relative path:

```lua
Thumbnails = {
    A_C_Horse_AmericanStandardbred_Black = 'images/standardbred-black.webp',
    ['275341736'] = 'images/saddle-variant.webp',
},
```

Bundled images are category illustrations, not every coat's photograph. Missing files fall back to silhouettes. A path does not grant redistribution rights; retain the asset licence.

## Client exports

```lua
local horse = exports.vorp_stables:GetActiveHorse()
local wagon = exports.vorp_stables:GetActiveWagon()
```

Each returns the local entity handle or nil. Check existence and never persist handles across reconnects/restarts. Inventory ownership/access is server validated; a client handle alone must not grant permission.

330_stables:request / response are internal request plumbing, not a guarantee to reproduce every upstream stable event. Review third-party integrations individually. For inventory adaptation, see server/storage.lua and openStorage in server/main.lua.
