# Move from original VORP Stables

## What migration means

This resource reads the supported **same `stables` and `horse_complements` tables, with the same row IDs**, as VORP Stables 1.3. You replace the resource, not ownership or character IDs. Think of changing the shop front while keeping its records.

| Data | Result |
|---|---|
| Row ID, owner, character ID, name, model, type, active flag | Kept |
| Purchased tack and fitted gear | Reused from horse_complements / gear |
| Legacy XP/injury/inventory columns | Left in place; upstream gameplay is not all ported |
| New cash/gold compensation | Separate additive refund tables |
| Old custom-inventory contents | Separate procedure below |

## Step by step

1. **Make a staging copy.** Copy server/database to a private test setup. Confirm it does not point at the live DB.
2. **Back up the full database**, including inventory/custom-inventory tables, stables and horse_complements. Save the old resource/config. Verify the backup can be restored.
3. **Disconnect players for cutover.** Data that keeps changing cannot form a reliable migration snapshot.
4. **Run the read-only check** `vorp_stables/sql/migration-check.sql`, or the Python checker below, against staging. Resolve missing columns, invalid JSON, duplicate active records and unsupported types before proceeding. These checks do not modify data.
5. **Empty old bags using the original inventory.** Move items and weapons into safe player/stash storage using normal inventory actions. Respect that inventory's limits. This is the simplest supported content-migration route.
6. **Stop the old resource.** Store it outside resources. Replace it with this release, still named **vorp_stables**. Disable other stable/prototype prompts.
7. **Use the new config.** Reapply intended prices, capacities, jobs and locations. Do not overwrite the new config with an entire old settings.lua.
8. **Refresh and start dependencies/stables.** Missing tables are created additively. **Never import upstream stables.sql containing DROP TABLE: it can erase your ownership.**
9. **Check the same character.** Compare counts, names, active rides and equipment. Check H/J calls, wallet, purchase, storage and reconnect.
10. **Refill the correct new bags** through normal inventory actions. Verify two identical horse models have independent storage.
11. After staging passes, repeat the controlled process with a fresh live backup. Keep the old snapshot until acceptance.

## Read-only Python checker

Install Python and `pip install -r tools/requirements-migration.txt`. Put the password in an environment variable, not command arguments or Git:

```powershell
$env:VORP_DB_PASSWORD = Read-Host 'Database password' -MaskInput
python tools/check-migration.py --host 127.0.0.1 --database YOUR_STAGING_DATABASE --user YOUR_DB_USER
```

It uses a READ ONLY transaction and prints counters, not player data. A SELECT-only DB account is recommended. Exit 0 means these structural checks pass; it does not certify third-party inventory APIs or native gameplay.

## Why old bags need care

Original native stable bags commonly used `<model>_<character ID>`. This release uses `stable_<ride row ID>` for native storage. That separates identical models into individual bags.

Two identical models can make the old ID ambiguous. Copying the old bag into both would duplicate items; choosing one silently could assign items incorrectly. This release does neither. Use empty-and-refill, or ask your inventory maintainer for an offline, audited, version-specific mapping that includes **both items and weapons**. Renaming only an inventory registry row is not a universal importer.

There is **no certified general Inventory V2 content importer** in this beta. Permanent removal is refused when storage cannot be verified. Do not bypass that safeguard.

## Rollback

Disconnect players. Stop this resource and restore the old resource/config **and the matching full DB snapshot**. Swapping only Lua back after purchases/transfers is not safe: wallet, ownership and inventory state must agree. Old scripts may not understand beta receipts/status fields or new per-ride bags.

This guide supports the specified VORP layout. RSG and unrelated stable tables need separate importers.
