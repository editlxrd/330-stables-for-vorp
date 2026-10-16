# Installation

You need a working **RedM server, OneSync, VORP Core, oxmysql and compatible inventory**. Development used VORP Core 3.3 and the VORP Stables 1.3 ownership layout. Test on a copy first.

1. Download the install ZIP from Releases and extract it.
2. Copy only `vorp_stables` into resources. The path must end in `vorp_stables/fxmanifest.lua`, not a double-nested folder. Keep that name.
3. Back up and remove/stop the old implementation; never run two stable systems providing the same prompts. Keep backups outside the scanned resources folder.
4. Start dependencies in this order:

```cfg
ensure oxmysql
ensure vorp_core
ensure vorp_inventory
ensure vorp_stables
```

5. Configure your existing database connection privately. Included `sql/install.sql` creates missing tables without dropping rows. Startup also creates cash/gold refund tables. The DB user needs the appropriate CREATE permission. Incompatible existing columns are not silently rewritten.
6. Edit `config.lua`: choose language, prices, gold rate and capacities. Locations/shop lists are in `locations.lua`.
7. In the **server console**, run `refresh`, then `ensure vorp_stables`. After a manifest update, refresh before restart so clients receive new scripts.
8. Wait for `[330 Stables] Ready. VORP connected; stable records loaded.` Join, select a character and press G at a stable.
9. Run [the staging checklist](TESTING.md) before allowing public use.

## Existing VORP Stables

Read [MIGRATION.md](MIGRATION.md) before installation. Do not run upstream SQL with DROP TABLE. Horse/wagon ownership and old inventory contents are separate migration concerns.

## 330 Inventory

Keep your existing compatibility bridge named `vorp_inventory`. Start `lab_inventory`, then that bridge, then `vorp_stables`. Do not also install a different native inventory under the same name. This repository does not install/replace your inventory.

## Updating

Disconnect players, back up resource/database, read release notes, replace files and reapply your settings to the new config. Run refresh before restarting after manifest changes. Restart removes called entities; ownership stays saved and H/J calls them again. Do not restart while players are mounted/driving.

Default language is English; set `Locale = 'cs'` inside Config for Czech. Runtime needs no npm install or frontend build.
