"""Checks that committed item definitions can be regenerated exactly."""

import runpy
import unittest
from pathlib import Path


EXPORTER = runpy.run_path(
    str(Path(__file__).with_name("export-catalog-lua.py")),
    run_name="catalog_exporter_test",
)


class WandExportTest(unittest.TestCase):
    def setUp(self):
        self.items = {
            "source_revision": "pinned",
            "items": [
                {
                    "id": "WAND_FLAME",
                    "class": "OBJ_WANDS",
                    "stackable": False,
                    "explicitly_removed": False,
                },
            ],
        }
        self.spells = {
            "source_revision": "pinned",
            "spells": [
                {
                    "id": "SPELL_THROW_FLAME",
                    "status": "defined",
                },
            ],
        }
        self.links = {
            "source_revision": "pinned",
            "source_path": "crawl-ref/source/spl-book.cc",
            "links": [
                {
                    "wand_id": "WAND_FLAME",
                    "spell_id": "SPELL_THROW_FLAME",
                    "source_line": 91,
                },
            ],
        }

    def test_wand_definition_imports_spell_and_cites_source(self):
        enrich = EXPORTER["enrich_item_definitions"]
        render = EXPORTER["render_definition"]
        definition = enrich(self.items, self.links, self.spells)[0]
        output = render("items", "pinned", definition)

        self.assertIn('local spells = require("ids.spells")', output)
        self.assertIn("-- Source: crawl-ref/source/spl-book.cc:91", output)
        self.assertIn("wand_spell_id = spells.SPELL_THROW_FLAME", output)
        self.assertNotIn('wand_spell_id = "SPELL_THROW_FLAME"', output)
        self.assertNotIn("wand_spell_source_line =", output)

    def test_missing_link_and_revision_mismatch_fail(self):
        enrich = EXPORTER["enrich_item_definitions"]
        self.links["links"].clear()

        with self.assertRaisesRegex(ValueError, "WAND_FLAME"):
            enrich(self.items, self.links, self.spells)

        self.links["source_revision"] = "different"

        with self.assertRaisesRegex(ValueError, "revision"):
            enrich(self.items, self.links, self.spells)


if __name__ == "__main__":
    unittest.main()
