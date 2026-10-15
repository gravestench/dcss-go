"""Source and catalog checks for the deliberate wand link importer."""

import unittest

from import_wand_spells import parse_wand_table, validate_links


TABLE = """static const map<wand_type, spell_type> _wand_spells =
{
    { WAND_FLAME, SPELL_THROW_FLAME },
    { WAND_DIGGING, SPELL_DIG },
};
"""


class WandSourceTest(unittest.TestCase):
    def test_parses_rows_and_source_lines(self):
        self.assertEqual(
            parse_wand_table(TABLE),
            [
                {
                    "wand_id": "WAND_FLAME",
                    "spell_id": "SPELL_THROW_FLAME",
                    "source_line": 3,
                },
                {
                    "wand_id": "WAND_DIGGING",
                    "spell_id": "SPELL_DIG",
                    "source_line": 4,
                },
            ],
        )

    def test_rejects_missing_malformed_and_duplicate_rows(self):
        with self.assertRaisesRegex(ValueError, "_wand_spells"):
            parse_wand_table("static const int unrelated = 1;")

        malformed = TABLE.replace("{ WAND_DIGGING, SPELL_DIG },", "oops")

        with self.assertRaisesRegex(ValueError, "row"):
            parse_wand_table(malformed)

        duplicated = TABLE.replace(
            "{ WAND_DIGGING, SPELL_DIG },",
            "{ WAND_FLAME, SPELL_DIG },",
        )

        with self.assertRaisesRegex(ValueError, "duplicate WAND_FLAME"):
            parse_wand_table(duplicated)

    def test_validates_complete_active_wand_and_spell_sets(self):
        links = parse_wand_table(TABLE)
        items = {
            "source_revision": "pinned",
            "items": [
                {"id": "WAND_FLAME", "class": "OBJ_WANDS"},
                {"id": "WAND_DIGGING", "class": "OBJ_WANDS"},
            ],
        }
        spells = {
            "source_revision": "pinned",
            "spells": [
                {"id": "SPELL_THROW_FLAME", "status": "defined"},
                {"id": "SPELL_DIG", "status": "defined"},
            ],
        }

        validate_links(links, items, spells)

        with self.assertRaisesRegex(ValueError, "WAND_DIGGING"):
            validate_links(links[:1], items, spells)

        links[1]["spell_id"] = "SPELL_NOT_DEFINED"

        with self.assertRaisesRegex(ValueError, "SPELL_NOT_DEFINED"):
            validate_links(links, items, spells)


if __name__ == "__main__":
    unittest.main()
