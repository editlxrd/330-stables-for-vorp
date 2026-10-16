import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("migration", Path("tools/check-migration.py"))
migration = importlib.util.module_from_spec(spec)
spec.loader.exec_module(migration)


class MigrationChecks(unittest.TestCase):
    def setUp(self):
        self.columns = migration.REQUIRED
        self.ride = dict(charidentifier=1, modelname="horse", type="horse", status="{}", gear="{}", isDefault=1)

    def test_existing_layout_is_reused(self):
        result = migration.inspect(self.columns, [self.ride], [dict(charidentifier=1, complements="[]")])
        self.assertEqual(result["problems"], [])
        self.assertFalse(result["bagContentsMigrated"])

    def test_missing_schema_blocks_cutover(self):
        self.assertTrue(migration.inspect({}, [], [])["problems"])

    def test_invalid_json_is_reported(self):
        self.assertTrue(migration.inspect(self.columns, [{**self.ride, "gear": "bad json"}], [])["problems"])

    def test_same_model_bag_is_flagged_not_copied(self):
        result = migration.inspect(self.columns, [self.ride, {**self.ride, "isDefault": 0}], [])
        self.assertEqual(result["ambiguousLegacyBagGroups"], 1)
        self.assertFalse(result["bagContentsMigrated"])

    def test_duplicate_active_and_collections_are_blocked(self):
        result = migration.inspect(self.columns, [self.ride, self.ride], [dict(charidentifier=1, complements="[]")]*2)
        self.assertEqual(len(result["problems"]), 2)


if __name__ == "__main__":
    unittest.main()
