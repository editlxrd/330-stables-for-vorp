"""Read-only preflight for the supported VORP ownership layout. Never copies bag contents."""

import argparse
import json
import os
import sys

REQUIRED = {
    "stables": {"id", "identifier", "charidentifier", "name", "modelname", "type", "status", "xp", "injured", "gear", "isDefault", "inventory"},
    "horse_complements": {"identifier", "charidentifier", "complements"},
}


def inspect(columns, rides, collections):
    problems = []
    for table, required in REQUIRED.items():
        missing = sorted(required - set(columns.get(table, [])))
        if missing:
            problems.append(f"{table}: missing columns: {', '.join(missing)}")
    active, bags, owners = {}, {}, {}
    invalid_json = unsupported = invalid_owner = 0
    for row in rides:
        if row.get("type") not in ("horse", "cart"):
            unsupported += 1
        if not isinstance(row.get("charidentifier"), int) or row["charidentifier"] <= 0:
            invalid_owner += 1
        key = (row.get("charidentifier"), row.get("type"))
        if row.get("isDefault") == 1:
            active[key] = active.get(key, 0) + 1
        key = (row.get("charidentifier"), row.get("modelname"))
        bags[key] = bags.get(key, 0) + 1
        for field in ("gear", "status"):
            value = row.get(field)
            if value not in (None, ""):
                try:
                    json.loads(value)
                except (ValueError, TypeError):
                    invalid_json += 1
    for row in collections:
        owner = row.get("charidentifier")
        owners[owner] = owners.get(owner, 0) + 1
        try:
            json.loads(row.get("complements", ""))
        except (ValueError, TypeError):
            invalid_json += 1
    duplicate_active = sum(count > 1 for count in active.values())
    duplicate_collections = sum(count > 1 for count in owners.values())
    for count, label in [
        (invalid_json, "invalid JSON values"),
        (unsupported, "unsupported ride types"),
        (invalid_owner, "invalid character IDs"),
        (duplicate_active, "duplicate active ride groups"),
        (duplicate_collections, "duplicate equipment collection owners"),
    ]:
        if count:
            problems.append(f"{count} {label}")
    return {
        "ownershipRows": len(rides),
        "equipmentRows": len(collections),
        "ambiguousLegacyBagGroups": sum(count > 1 for count in bags.values()),
        "problems": problems,
        "bagContentsMigrated": False,
        "note": "Ownership tables are reused. Follow docs/MIGRATION.md for backups, cutover and old bags.",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=3306)
    parser.add_argument("--database", required=True)
    parser.add_argument("--user", required=True)
    parser.add_argument("--password-env", default="VORP_DB_PASSWORD")
    args = parser.parse_args()
    import pymysql

    try:
        db = pymysql.connect(
            host=args.host, port=args.port, database=args.database, user=args.user,
            password=os.environ.get(args.password_env, ""), charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor, autocommit=False,
        )
        try:
            with db.cursor() as cursor:
                cursor.execute("START TRANSACTION READ ONLY")
                cursor.execute("SELECT TABLE_NAME,COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('stables','horse_complements')")
                columns = {}
                for row in cursor.fetchall():
                    columns.setdefault(row["TABLE_NAME"], []).append(row["COLUMN_NAME"])
                rides, collections = [], []
                if REQUIRED["stables"] <= set(columns.get("stables", [])):
                    cursor.execute("SELECT charidentifier,modelname,type,status,gear,isDefault FROM stables")
                    rides = cursor.fetchall()
                if REQUIRED["horse_complements"] <= set(columns.get("horse_complements", [])):
                    cursor.execute("SELECT charidentifier,complements FROM horse_complements")
                    collections = cursor.fetchall()
                report = inspect(columns, rides, collections)
                print(json.dumps(report, indent=2))
                return 1 if report["problems"] else 0
        finally:
            db.rollback()
            db.close()
    except pymysql.MySQLError as error:
        # Do not expose server addresses, usernames or connection data in a shareable report.
        print(f"Database preflight failed (error {error.args[0]}). Check credentials, SELECT permission and schema privately.", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
