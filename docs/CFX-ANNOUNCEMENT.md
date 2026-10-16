# [FREE][VORP][BETA] 330 Stables for VORP — Horses, Tack & Wagons

Hey everyone! I'm sharing the first public beta of **330 Stables for VORP**, a free stable resource for RedM.

I would love server owners to try it on a staging copy of their server and report feedback. It is **still a beta**, with known limitations documented on GitHub.

## What's included?

- Horses, My Stable, Tack and Wagons, with real local 3D previews and smooth menu transitions.
- Named owned rides, active selection and persistent equipment collections. Buy tack once and re-equip it free.
- Horse calls using your VORP character's whistle, riding-horse Lead/Stop leading, wagon calls and owner-only Dismiss.
- Cash and gold purchases through the VORP Core wallet, with configurable prices and gold overrides.
- Wagon buyback at **60% by default**, configurable, paid in the original receipt currency.
- Sell/transfer horses or wagons to online nearby players at an agreed cash price. The recipient receives an offer request and accepts/declines in **My Stable → Incoming offers**. Payment/ownership change only after acceptance.
- Per-ride storage identities and initial inventory adapters; full native inventory acceptance and old bag-content migration remain beta work.
- English/Czech locales, notifications, loading progress, keyboard feedback and reduced-motion support.

## In-game screenshots

![Horse catalogue](https://raw.githubusercontent.com/editlxrd/330-stables-for-vorp/main/assets/screenshots/horse-catalogue.png)

[details="My Stable, tack, wagons and horse leading"]

**My Stable and owned horse management**

![My Stable and owned horse management](https://raw.githubusercontent.com/editlxrd/330-stables-for-vorp/main/assets/screenshots/my-stable.png)

**Tack selection and equipment collection**

![Tack selection and equipment collection](https://raw.githubusercontent.com/editlxrd/330-stables-for-vorp/main/assets/screenshots/tack.png)

**Wagon catalogue with native draft team**

![Wagon catalogue with native draft team](https://raw.githubusercontent.com/editlxrd/330-stables-for-vorp/main/assets/screenshots/wagon-catalogue.png)

**Owned wagon, storage action and resale**

![Owned wagon, storage action and resale](https://raw.githubusercontent.com/editlxrd/330-stables-for-vorp/main/assets/screenshots/my-wagons.png)

**Native riding-horse leading**

![Native riding-horse leading](https://raw.githubusercontent.com/editlxrd/330-stables-for-vorp/main/assets/screenshots/horse-leading.png)

[/details]

## Locations

Valentine, Rhodes, Wapiti, Saint Denis, Strawberry, Blackwater, Tumbleweed, Colter, Van Horn, Emerald Ranch and Scarlett Meadows.

Positions, cameras, shop availability/prices, capacities, jobs, blips/NPCs, payments and streaming behaviour are configurable. The four added locations need map-specific camera/spawn acceptance on your server.

## Moving from VORP Stables

Supported VORP Stables ownership rows are reused from the existing database, with names, IDs and gear kept. The repository includes a **read-only migration checker and step-by-step backup/cutover/rollback guide**.

Old custom-inventory bag contents are a separate step, not blindly copied. Read the migration guide before replacing a live resource. Never import upstream SQL containing DROP TABLE over existing data.

## Planned next

Horse hunger/thirst/stamina/status, horse care/service and brushing, breeding, aging, complete VORP Inventory acceptance and a more complete wagon-storage flow. These are roadmap directions, not completed features or dated promises.

Harnessed wagon leading is currently disabled after the engine rejected the native task in testing. Riding-horse leading and wagon Dismiss are available.

## Download, docs and bug reports

- [GitHub](https://github.com/editlxrd/330-stables-for-vorp)
- [Beta download](https://github.com/editlxrd/330-stables-for-vorp/releases)
- [Installation and migration](https://github.com/editlxrd/330-stables-for-vorp/blob/main/docs/MIGRATION.md)
- [Report a bug](https://github.com/editlxrd/330-stables-for-vorp/issues/new/choose)

Please include versions, reproduction steps and redacted F8/server errors. Never post keys/passwords/player identifiers. Support is best effort; no guaranteed response time or custom integration is promised.

No universal performance figure is claimed; test with your map, game build and resources.

| | |
|---|---|
| Code is accessible | Lua/config: Yes; UI: compiled build only; separate asset notices retained |
| Subscription-based | No |
| Price | Free |
| Lines (approximately) | About 4,400 shipped runtime lines; UI is compiled/minified (about 7,500 authoring lines) |
| Requirements & dependencies | RedM, OneSync, VORP Core, oxmysql, compatible inventory |
| Support | GitHub Issues, best effort |
| Status | First public beta — server testing wanted |
