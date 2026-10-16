"""Source import checks for committed item-generation definitions."""

import json
import runpy
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path("/Users/dylanknuth/src/crawl/crawl-ref/source")
IMPORTER = ROOT / "scripts/import_item_generation.py"
GENERATED = ROOT / "internal/content/generated"


class ItemGenerationImportTest(unittest.TestCase):
    def importer(self):
        self.assertTrue(IMPORTER.exists(), "source-backed importer is missing")

        return runpy.run_path(str(IMPORTER), run_name="item_generation_import_test")

    def test_all_source_unrands_keep_order_and_exclusions(self):
        importer = self.importer()
        records = importer["parse_art_data"](
            (SOURCE / "art-data.txt").read_text()
        )

        self.assertEqual(len(records), 127)
        self.assertEqual(records[0]["id"], "UNRAND_DUMMY1")
        self.assertEqual(records[0]["generation"]["mode"], "none")
        self.assertEqual(records[0]["source_order"], 1)
        self.assertEqual(records[-1]["source_order"], 127)
        self.assertEqual(records[-1]["id"], "UNRAND_DUMMY2")
        self.assertEqual(records[-1]["generation"]["mode"], "none")

        for record in records:
            if "nogen" in record["flags"]:
                self.assertNotEqual(record["generation"]["mode"], "random")

    def test_all_base_items_have_explicit_generation_mode(self):
        self.importer()
        records = json.loads((GENERATED / "item-generation.json").read_text())
        items = records["items"]
        modes = {"random", "forced", "none"}

        self.assertEqual(len(items), 368)
        self.assertTrue(all(row["generation"]["mode"] in modes for row in items))
        self.assertEqual(sum(row["explicitly_removed"] for row in items), 44)

        by_id = {row["id"]: row for row in items}
        self.assertEqual(by_id["MI_NEEDLE"]["generation"]["mode"],
                         "forced")
        self.assertEqual(by_id["MISC_FAN_OF_GALES"]["generation"]["mode"],
                         "forced")
        self.assertEqual(by_id["MISC_PHIAL_OF_FLOODS"]["generation"]["mode"],
                         "random")
        self.assertEqual(by_id["ARM_CAP"]["generation"]["mode"],
                         "forced")
        self.assertEqual(by_id["ARM_ANIMAL_SKIN"]["generation"]["mode"],
                         "forced")
        self.assertEqual(by_id["ARM_BARDING"]["generation"]["mode"],
                         "random")

    def test_malformed_unique_record_is_rejected(self):
        importer = self.importer()
        source = (
            "NAME: Test blade\n"
            "OBJ: OBJ_WEAPONS/WPN_DAGGER\n"
            "COLOUR: RED\n"
            "BOOL: nogen\n"
        )
        records = importer["parse_art_data"](source)

        self.assertEqual(records[0]["generation"]["mode"], "none")

        with self.assertRaisesRegex(ValueError, "OBJ"):
            importer["parse_art_data"]("NAME: Missing base kind\n")

        with self.assertRaisesRegex(ValueError, "COLOUR"):
            importer["parse_art_data"](
                "NAME: Missing colour\nOBJ: OBJ_WEAPONS/WPN_DAGGER\n"
            )

    def test_numeric_inline_comments_follow_source_parser(self):
        importer = self.importer()
        source = (
            "NAME: Test blade\n"
            "OBJ: OBJ_WEAPONS/WPN_DAGGER\n"
            "COLOUR: RED\n"
            "PLUS: +8 # source note\n"
        )

        record = importer["parse_art_data"](source)[0]

        self.assertEqual(record["properties"]["plus"], 8)

    def test_comment_only_line_does_not_extend_base_kind(self):
        importer = self.importer()
        source = (
            "NAME: Test blade\n"
            "OBJ: OBJ_WEAPONS/WPN_DAGGER\n"
            "COLOUR: RED\n"
            "# A comment about the next field.\n"
            "PLUS: +3\n"
        )

        record = importer["parse_art_data"](source)[0]

        self.assertEqual(record["kind_id"], "WPN_DAGGER")

    def test_property_output_order_is_deterministic(self):
        importer = self.importer()
        source = (
            "NAME: Test blade\n"
            "OBJ: OBJ_WEAPONS/WPN_DAGGER\n"
            "COLOUR: RED\n"
            "PLUS: +3\n"
            "FIRE: 1\n"
            "AC: 2\n"
            "COLD: 1\n"
            "EV: 4\n"
        )
        record = importer["parse_art_data"](source)[0]

        self.assertEqual(
            list(record["properties"]),
            ["ac", "cold", "ev", "fire", "plus"],
        )

    def test_source_weight_change_changes_import(self):
        importer = self.importer()
        source = (
            "static int _potion_weight(item_rarity_type rarity)\n"
            "{\n"
            "    switch (rarity)\n"
            "    {\n"
            "    case RARITY_VERY_COMMON:\n"
            "        return 193;\n"
            "    case RARITY_COMMON:\n"
            "        return 105;\n"
            "    case RARITY_UNCOMMON:\n"
            "        return 67;\n"
            "    case RARITY_RARE:\n"
            "        return 35;\n"
            "    case RARITY_VERY_RARE:\n"
            "        return 2;\n"
            "    }\n"
            "}\n"
        )
        weights = importer["parse_consumable_weights"](
            source, "_potion_weight"
        )

        self.assertEqual(weights["RARITY_VERY_COMMON"], 193)


if __name__ == "__main__":
    unittest.main()
