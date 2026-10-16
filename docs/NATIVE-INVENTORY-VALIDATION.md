# Native VORP migration validation — 16 October 2026

An isolated FXServer/database clone was used. No production ownership or inventories were edited. The source was the original VORP Stables **1.3**, commit `0d388f8ae6283d699595169a765ed28e5b4f7518`, with native VORP Inventory V2 commit `25302ee565f9f106141234b3ec0922797a921021` and VORP Core 3.3. No 330 inventory/compatibility bridge was running.

## Procedure and evidence

1. Installed the original 1.3 schema in the isolated database and seeded six owned records: two identical horses and a wagon for each of two test characters, plus fitted/purchased tack.
2. Started the unmodified original stable and invoked its actual load event. It registered the old model/character bags through native VORP Inventory. Inserted two waters with fixture metadata and a serialised weapon into each test owner's old horse bag through native inventory exports. **16 checks passed.**
3. Replaced only the stable resource with 330. Compared complete stables and horse_complements rows before/after: ownership IDs, names, active flags and gear were unchanged.
4. For the two known test bags, used an explicit old-to-new map to one specified horse per owner. Moved inventory-type references and weapon container references transactionally, without cloning crafted-item IDs or weapon serials. Identical second horses intentionally received no duplicate contents. This is a version-specific test map, **not a general automatic content importer**.
5. Tested the shipped storage guard against the real inventory exports. Found and fixed the unregistered-empty-bag case: native exports return false for an unregistered bag, so both current and legacy runtime registrations must exist before checking contents. No stored contents are cleared by registration.
6. Repeated after restarting native inventory and the stable: **20 checks passed, zero failed**. Item amounts and unique weapon serials remained correct. Loaded bags blocked permanent removal; empty separate bags permitted it.

## What this does not prove

The server-side API and persistence checks are real runtime tests. They do not replace a player's final check of the native inventory window, moving items/weapons through its UI, character reconnect, camera and animations. Other inventory commits, custom schemas and third-party scripts still need staging acceptance. Read MIGRATION.md before switching; old shared-model bags require an explicit choice or the documented empty/refill procedure.
