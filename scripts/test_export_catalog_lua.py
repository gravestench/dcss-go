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
        self.gear = {
            "source_revision": "pinned",
            "primary": [],
            "secondary": [],
        }
        self.items = {
            "source_revision": "pinned",
            "items": [],
        }

    def test_rows_are_embedded_in_their_monster_file(self):
        enrich = EXPORTER["enrich_monster_definitions"]
        render = EXPORTER["render_definition"]
        definition = enrich(
            self.monsters, self.population, self.gear, self.items
        )[0]
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
            enrich(self.monsters, self.population, self.gear, self.items)

        self.population["rows"][0]["monster_id"] = "MONS_TEST_RAT"
        self.population["source_revision"] = "different"

        with self.assertRaisesRegex(ValueError, "revision"):
            enrich(self.monsters, self.population, self.gear, self.items)

    def test_committed_source_rows_all_have_monster_owners(self):
        source = EXPORTER["SOURCE"]
        monsters = json.loads((source / "monsters.json").read_text())
        population = json.loads(
            (source / "dungeon-population.json").read_text()
        )
        definitions = EXPORTER["enrich_monster_definitions"](
            monsters, population,
            json.loads((source / "monster-weapons.json").read_text()),
            json.loads((source / "items.json").read_text()),
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


class MonsterGearExportTest(unittest.TestCase):
    def setUp(self):
        self.monsters = {
            "source_revision": "pinned",
            "monsters": [{"id": "MONS_TEST_RAT", "status": "defined"}],
        }
        self.population = {
            "source_revision": "pinned",
            "rows": [],
        }
        self.items = {
            "source_revision": "pinned",
            "items": [{
                "id": "WPN_DAGGER",
                "status": "defined",
                "class": "OBJ_WEAPONS",
            }],
        }
        self.gear = {
            "source_revision": "pinned",
            "primary": [{
                "monster_id": "MONS_TEST_RAT",
                "source_line": 40,
                "spec_line": 41,
                "weapon_list_line": 42,
                "brand_list_line": 43,
                "weapons": [{"id": "WPN_DAGGER", "weight": 3}],
                "plus": {"odds": 0, "min": 0, "max": 0, "rolls": 0},
                "brands": [{"id": "SPWPN_FLAMING", "weight": 1}],
                "good_chance": 0,
            }],
            "secondary": [{
                "monster_id": "MONS_TEST_RAT",
                "source_line": 50,
                "weapons": [{"id": "NUM_WEAPONS", "weight": 1}],
                "plus": {"odds": 0, "min": 0, "max": 0, "rolls": 0},
                "brands": None,
                "good_chance": 0,
            }],
        }

    def definitions(self):
        return EXPORTER["enrich_monster_definitions"](
            self.monsters, self.population, self.gear, self.items
        )

    def test_primary_and_secondary_are_owned_and_named(self):
        definition = self.definitions()[0]
        output = EXPORTER["render_definition"](
            "monsters", "pinned", definition
        )

        self.assertEqual(definition["weapon_gear"]["primary"]["weapons"][0]["id"], "WPN_DAGGER")
        self.assertIn("weapon_gear = {", output)
        self.assertIn("item_ids.WPN_DAGGER", output)
        self.assertIn("brands.FLAMING", output)
        self.assertIn("sentinels.NO_WEAPON", output)
        self.assertIn("-- Source: crawl-ref/source/mon-gear.cc:40", output)
        self.assertIn("-- Spec: crawl-ref/source/mon-gear.cc:41", output)
        self.assertIn("-- Weapon list: crawl-ref/source/mon-gear.cc:42", output)
        self.assertIn("-- Brand list: crawl-ref/source/mon-gear.cc:43", output)
        self.assertNotIn("spec_line =", output)
        self.assertNotIn("monster_id =", output)

    def test_gear_imports_only_used_namespaces(self):
        self.gear["primary"][0]["brands"] = None
        self.gear["secondary"] = []
        output = EXPORTER["render_definition"](
            "monsters", "pinned", self.definitions()[0]
        )

        self.assertIn('local item_ids = require("ids.items")', output)
        self.assertNotIn('local brands = require("constants.weapon_brands")', output)
        self.assertNotIn('local sentinels = require("constants.monster_gear_sentinels")', output)

    def test_bad_revision_owner_slot_and_item_fail(self):
        self.gear["source_revision"] = "different"

        with self.assertRaisesRegex(ValueError, "revision"):
            self.definitions()

        self.gear["source_revision"] = "pinned"
        self.gear["primary"].append(dict(self.gear["primary"][0]))

        with self.assertRaisesRegex(ValueError, "duplicate.*MONS_TEST_RAT"):
            self.definitions()

        self.gear["primary"].pop()
        self.gear["primary"][0]["monster_id"] = "MONS_MISSING"

        with self.assertRaisesRegex(ValueError, "MONS_MISSING"):
            self.definitions()

        self.gear["primary"][0]["monster_id"] = "MONS_TEST_RAT"
        self.gear["primary"][0]["weapons"][0]["id"] = "WPN_MISSING"

        with self.assertRaisesRegex(ValueError, "WPN_MISSING"):
            self.definitions()

        self.gear["primary"][0]["weapons"][0]["id"] = "WPN_DAGGER"
        self.items["items"][0]["status"] = "removed"

        with self.assertRaisesRegex(ValueError, "WPN_DAGGER"):
            self.definitions()

        self.items["items"][0]["status"] = "defined"
        self.gear["primary"][0]["brands"][0]["id"] = "SPWPN_MISSING"

        with self.assertRaisesRegex(ValueError, "SPWPN_MISSING"):
            self.definitions()

    def test_all_committed_gear_rows_have_owners(self):
        source = EXPORTER["SOURCE"]
        definitions = EXPORTER["enrich_monster_definitions"](
            json.loads((source / "monsters.json").read_text()),
            json.loads((source / "dungeon-population.json").read_text()),
            json.loads((source / "monster-weapons.json").read_text()),
            json.loads((source / "items.json").read_text()),
        )
        primary = sum(
            "primary" in row.get("weapon_gear", {}) for row in definitions
        )
        secondary = sum(
            "secondary" in row.get("weapon_gear", {}) for row in definitions
        )

        self.assertEqual((primary, secondary), (162, 16))


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
