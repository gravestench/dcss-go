"""Source parsing checks for the deliberate monster beam refresh tool."""

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("import-monster-beams.py")
SPEC = importlib.util.spec_from_file_location("import_monster_beams", SCRIPT)
IMPORTER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(IMPORTER)


SPELL_ZAPS = """static pair<spell_type, zap_type> _spl_zaps[] =
{
    { SPELL_MAGIC_DART, ZAP_MAGIC_DART },
    { SPELL_SLEEP, ZAP_SLEEP },
    { SPELL_MAGIC_DART, ZAP_OTHER_DART },
};
"""

ZAP_DATA = """static const zap_info zap_data[] =
{
{
    ZAP_MAGIC_DART,
    "magic dart",
    25,
    new dicedef_calculator<1, 3, 1, 5>,
    new tohit_calculator<AUTOMATIC_HIT>,
    new dicedef_calculator<3, 4, 1, 100>,
    new tohit_calculator<AUTOMATIC_HIT>,
    LIGHTMAGENTA,
    false,
    BEAM_MMISSILE,
    DCHAR_FIRED_ZAP,
    false,
    false,
    1
},
_mon_hex_zap(ZAP_SLEEP, BEAM_SLEEP),
};
"""

MON_CAST = """static int _mons_power_hd_factor(spell_type spell)
{
    switch (spell)
    {
        case SPELL_SLEEP:
            return 8;
        default:
            return 12;
    }
}
bool mons_spell_is_spell(spell_type spell)
{
    switch (spell)
    {
        case SPELL_MAGIC_DART:
            return false;
        default:
            return true;
    }
}
switch (real_spell)
{
    case SPELL_FREEZING_CLOUD:
        zappy(ZAP_FREEZING_BLAST, power, true, beam);
        break;
}
"""


class MonsterBeamSourceTest(unittest.TestCase):
    def test_spell_links_preserve_first_source_mapping(self):
        links = IMPORTER.parse_spell_zaps(SPELL_ZAPS)

        self.assertEqual(links["SPELL_MAGIC_DART"],
                         ("ZAP_MAGIC_DART", 3))
        self.assertEqual(links["SPELL_SLEEP"], ("ZAP_SLEEP", 4))

    def test_reads_monster_calculators_and_hex_helper(self):
        zaps = IMPORTER.parse_zap_data(ZAP_DATA)
        dart = zaps["ZAP_MAGIC_DART"]

        self.assertEqual(dart["monster_damage"],
                         ("dicedef", (3, 4, 1, 100)))
        self.assertEqual(dart["monster_tohit"],
                         ("tohit", ("AUTOMATIC_HIT",)))
        self.assertEqual(dart["flavour"], "BEAM_MMISSILE")
        self.assertEqual(dart["can_beam"], False)
        self.assertEqual(dart["noise"], 1)
        self.assertEqual(zaps["ZAP_SLEEP"]["flavour"], "BEAM_SLEEP")
        self.assertTrue(zaps["ZAP_SLEEP"]["is_enchantment"])

    def test_unknown_monster_calculator_fails_loudly(self):
        broken = ZAP_DATA.replace(
            "new dicedef_calculator<3, 4, 1, 100>",
            "new invented_calculator<3, 4, 1, 100>",
        )

        with self.assertRaisesRegex(ValueError, "invented_calculator"):
            IMPORTER.parse_zap_data(broken)

    def test_unknown_beam_flavour_fails_loudly(self):
        broken = ZAP_DATA.replace("BEAM_MMISSILE", "BEAM_UNKNOWN")
        zaps = IMPORTER.parse_zap_data(broken)
        links = IMPORTER.parse_spell_zaps(SPELL_ZAPS)

        with self.assertRaisesRegex(ValueError, "BEAM_UNKNOWN"):
            IMPORTER.render_catalog(
                {"SPELL_MAGIC_DART"}, links, zaps, ""
            )

    def test_rendered_profile_imports_shared_ids_and_source_lines(self):
        profile = IMPORTER.parse_zap_data(ZAP_DATA)["ZAP_MAGIC_DART"]
        rendered = IMPORTER.render_profile(
            "SPELL_MAGIC_DART", "ZAP_MAGIC_DART", 3, profile
        )

        self.assertIn('id = "SPELL_MAGIC_DART"', rendered)
        self.assertIn("zap_id = zaps.ZAP_MAGIC_DART", rendered)
        self.assertIn("flavour = flavours.BEAM_MMISSILE", rendered)
        self.assertIn("-- spl-zap.cc:3", rendered)
        self.assertIn("-- zap-data.h:3", rendered)
        self.assertIn("kind = \"dicedef\"", rendered)
        self.assertIn("register.definition(categories.MONSTER_BEAMS", rendered)

    def test_catalog_requires_every_source_mapping(self):
        links = IMPORTER.parse_spell_zaps(SPELL_ZAPS)
        zaps = IMPORTER.parse_zap_data(ZAP_DATA)

        rendered = IMPORTER.render_catalog(
            {"SPELL_MAGIC_DART", "SPELL_SLEEP"}, links, zaps, ""
        )

        self.assertIn("content/monster_beams/magic_dart.lua", rendered)
        self.assertIn("content/monster_beams/sleep.lua", rendered)
        self.assertIn("constants/zap_ids.lua", rendered)
        self.assertIn("constants/beam_flavours.lua", rendered)

        with self.assertRaisesRegex(ValueError, "SPELL_MISSING"):
            IMPORTER.render_catalog(
                {"SPELL_MISSING"}, links, zaps, ""
            )

    def test_monster_power_and_special_source_override(self):
        factors, natural, default = IMPORTER.parse_power_rules(MON_CAST)

        self.assertEqual(factors["SPELL_SLEEP"], 8)
        self.assertEqual(default, 12)
        self.assertEqual(factors.get("SPELL_MAGIC_DART", default), 12)
        self.assertIn("SPELL_MAGIC_DART", natural)

        links = IMPORTER.parse_spell_zaps(SPELL_ZAPS)
        zaps = IMPORTER.parse_zap_data(ZAP_DATA)
        zaps["ZAP_FREEZING_BLAST"] = dict(zaps["ZAP_MAGIC_DART"])
        zaps["ZAP_FREEZING_BLAST"]["id"] = "ZAP_FREEZING_BLAST"
        rendered = IMPORTER.render_catalog(
            {"SPELL_FREEZING_CLOUD"}, links, zaps, MON_CAST
        )["content/monster_beams/freezing_cloud.lua"]

        self.assertIn("-- mon-cast.cc:", rendered)
        self.assertIn("zap_id = zaps.ZAP_FREEZING_BLAST", rendered)

    def test_hex_power_factors_include_lambda_and_sap_cases(self):
        source = """{ SPELL_CONFUSE, _hex_logic(SPELL_CONFUSE) },
{ SPELL_AGONY, _hex_logic(SPELL_AGONY, [](const monster &caster) {
    return ai_action::good_or_impossible(caster.is_alive());
}, 6) },
{ SPELL_SENTINEL_MARK, _hex_logic(SPELL_SENTINEL_MARK, nullptr, 16) },
{ SPELL_SAP_MAGIC, {
    _always_worthwhile, _fire_simple_beam, _zap_setup(SPELL_SAP_MAGIC),
    MSPELL_LOGIC_NONE, 10,
} },
"""

        factors = IMPORTER.hex_power_rules(source)

        self.assertNotIn("SPELL_CONFUSE", factors)
        self.assertEqual(factors["SPELL_AGONY"], 18)
        self.assertEqual(factors["SPELL_SENTINEL_MARK"], 48)
        self.assertEqual(factors["SPELL_SAP_MAGIC"], 10)

    def test_energy_bolt_short_name_override_is_preserved(self):
        source = MON_CAST.replace(
            "    case SPELL_FREEZING_CLOUD:",
            "    case SPELL_ENERGY_BOLT:\n"
            "        zappy(spell_to_zap(real_spell), power, true, beam);\n"
            '        beam.short_name = "energy";\n'
            "        break;\n"
            "    case SPELL_FREEZING_CLOUD:",
        )
        links = IMPORTER.parse_spell_zaps(
            SPELL_ZAPS.replace("SPELL_SLEEP, ZAP_SLEEP",
                               "SPELL_ENERGY_BOLT, ZAP_ENERGY_BOLT")
        )
        zaps = IMPORTER.parse_zap_data(ZAP_DATA)
        zaps["ZAP_ENERGY_BOLT"] = dict(zaps["ZAP_MAGIC_DART"])
        zaps["ZAP_ENERGY_BOLT"]["id"] = "ZAP_ENERGY_BOLT"

        rendered = IMPORTER.render_catalog(
            {"SPELL_ENERGY_BOLT"}, links, zaps, source
        )["content/monster_beams/energy_bolt.lua"]

        self.assertIn('short_name = "energy"', rendered)
        self.assertIn("-- mon-cast.cc:", rendered)

    def test_unknown_source_beam_override_fails_loudly(self):
        source = MON_CAST.replace(
            "    case SPELL_FREEZING_CLOUD:",
            "    case SPELL_MAGIC_DART:\n"
            "        beam.unexpected = 9;\n"
            "    case SPELL_FREEZING_CLOUD:",
        )
        links = IMPORTER.parse_spell_zaps(SPELL_ZAPS)
        zaps = IMPORTER.parse_zap_data(ZAP_DATA)

        with self.assertRaisesRegex(ValueError, "unexpected"):
            IMPORTER.render_catalog(
                {"SPELL_MAGIC_DART"}, links, zaps, source
            )

    def test_generated_files_are_checked_without_rewriting(self):
        files = {"content/monster_beams/magic_dart.lua": "source profile\n"}

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)

            IMPORTER.write_output(files, root, check=False)
            IMPORTER.write_output(files, root, check=True)

            path = root / "content/monster_beams/magic_dart.lua"
            path.write_text("stale\n")

            with self.assertRaisesRegex(ValueError, "magic_dart.lua"):
                IMPORTER.write_output(files, root, check=True)

            self.assertEqual(path.read_text(), "stale\n")


if __name__ == "__main__":
    unittest.main()
