"""Checks that committed Lua catalogs preserve their source artifacts."""

import json
import runpy
import tempfile
import unittest
from pathlib import Path


EXPORTER = runpy.run_path(
    str(Path(__file__).with_name("export-catalog-lua.py")),
    run_name="catalog_exporter_test",
)


class WandExportTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        source = Path(directory.name)

        for name, records in (
            ("staff-rules", {"staves": []}),
            ("jewellery-rules", {"rules": []}),
        ):
            artifact = {
                "source_revision": "pinned",
                **records,
            }
            (source / f"{name}.json").write_text(json.dumps(artifact))

        globals_for_enrich = EXPORTER["enrich_item_definitions"].__globals__
        previous_source = globals_for_enrich["SOURCE"]
        globals_for_enrich["SOURCE"] = source
        self.addCleanup(globals_for_enrich.__setitem__, "SOURCE", previous_source)

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


class PopulationExportTest(unittest.TestCase):
    def setUp(self):
        self.monsters = {
            "source_revision": "pinned",
            "monsters": [
                {
                    "id": "MONS_TEST_RAT",
                    "status": "defined",
                },
            ],
        }
        self.population = {
            "source_revision": "pinned",
            "rows": [
                {
                    "monster_id": "MONS_TEST_RAT",
                    "min_depth": 1,
                    "max_depth": 2,
                    "rarity": 100,
                    "curve": "FLAT",
                    "source_line": 62,
                },
                {
                    "monster_id": "MONS_TEST_RAT",
                    "min_depth": 3,
                    "max_depth": 4,
                    "rarity": 50,
                    "curve": "FALL",
                    "source_line": 63,
                },
            ],
        }

    def test_rows_are_embedded_in_their_monster_file(self):
        enrich = EXPORTER["enrich_monster_definitions"]
        render = EXPORTER["render_definition"]
        definition = enrich(self.monsters, self.population)[0]
        output = render("monsters", "pinned", definition)

        self.assertEqual(len(definition["population"]), 2)
        self.assertIn("source_order = 1", output)
        self.assertIn("source_order = 2", output)
        self.assertIn("-- Source line: 62", output)
        self.assertIn("curve = curves.FLAT", output)
        self.assertNotIn("monster_id =", output)

    def test_missing_monster_and_revision_mismatch_fail(self):
        enrich = EXPORTER["enrich_monster_definitions"]
        self.population["rows"][0]["monster_id"] = "MONS_MISSING"

        with self.assertRaisesRegex(ValueError, "MONS_MISSING"):
            enrich(self.monsters, self.population)

        self.population["rows"][0]["monster_id"] = "MONS_TEST_RAT"
        self.population["source_revision"] = "different"

        with self.assertRaisesRegex(ValueError, "revision"):
            enrich(self.monsters, self.population)

    def test_committed_source_rows_all_have_monster_owners(self):
        source = EXPORTER["SOURCE"]
        monsters = json.loads((source / "monsters.json").read_text())
        population = json.loads(
            (source / "dungeon-population.json").read_text()
        )
        definitions = EXPORTER["enrich_monster_definitions"](
            monsters, population
        )
        owned_rows = [
            row
            for monster in definitions
            for row in monster.get("population", [])
        ]

        self.assertEqual(len(owned_rows), 125)
        self.assertEqual(
            sorted(row["source_order"] for row in owned_rows),
            list(range(1, 126)),
        )


class PresentationExportTest(unittest.TestCase):
    def test_shared_presentation_has_no_character_id_lists(self):
        source = EXPORTER["SOURCE"]
        artifact = json.loads((source / "presentation.json").read_text())
        groups = EXPORTER["render_menu_groups"](artifact)
        shared = EXPORTER["render"]("presentation")

        self.assertIn('SPECIES_SIMPLE = "Simple"', groups)
        self.assertIn('JOB_WARRIOR_MAGE = "Warrior-mage"', groups)
        self.assertIn("groups.species_capacities = {\n    9,", groups)
        self.assertIn("groups.jobs_capacities = {\n    5,", groups)
        self.assertNotIn("SP_HUMAN", groups)
        self.assertNotIn("JOB_FIGHTER", groups)
        self.assertIn("startup_modes =", shared)
        self.assertIn("skill_columns =", shared)
        self.assertNotIn("species_groups =", shared)
        self.assertNotIn("job_groups =", shared)
        self.assertNotIn("species_descriptions =", shared)


if __name__ == "__main__":
    unittest.main()
