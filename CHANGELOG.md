# Changelog

## v0.2.0-beta.2 — 2026-10-16

- Fix native VORP storage verification for unregistered empty current/legacy bags. Register runtime metadata before reading, while continuing to reject failed registration, unreadable data and non-empty contents.
- Add a regression fixture matching native VORP's unregistered-bag behaviour.
- Validate migration from original Stables 1.3 with real native Inventory V2 exports and persistence across restart. See docs/NATIVE-INVENTORY-VALIDATION.md; client gameplay acceptance is separate.

## v0.2.0-beta.1 — 2026-10-16

First public beta: **330 Stables for VORP**.

- Horses, My Stable, Tack and Wagons with real 3D previews.
- Eleven locations, per-vendor catalogues, blips and stable hands.
- Cash/gold purchases, persistent equipment collection and consent-based online sale requests.
- Wagon buyback (default 60%) in receipt currency, storage guards and deferred refunds.
- Distant horse calls, character whistle, wagon call/dismiss and riding-horse Lead.
- EN/CS locales, owner/developer guides and bug-report forms.
- Leading state follows the native led-horse handle; stale permission/task callbacks are cancelled.
- E/F remain enabled so action prompts stay visible.

### Beta limitations

Draft leading defaults off after native rejection. Old bag contents need the documented manual/version-specific procedure. Full Inventory V2 storage, all maps/game builds and third-party event compatibility are not universally certified.
