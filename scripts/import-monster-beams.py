#!/usr/bin/env python3
"""Deliberately refresh committed monster beam profiles from pinned DCSS.

Normal builds and game launches use only the generated Lua files.
"""

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REVISION = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"
SPEC = ROOT / "docs/superpowers/specs/2026-10-16-monster-beam-spells-design.md"
HEX_SPEC = ROOT / "docs/superpowers/specs/2026-10-18-monster-hex-spells-design.md"
OUTPUT = ROOT / "internal/modfs/builtin"

SPELL_PAIR = re.compile(
    r"\{\s*(SPELL_[A-Z0-9_]+)\s*,\s*(ZAP_[A-Z0-9_]+)\s*\}"
)
ZAP_START = re.compile(r"\{\s*(ZAP_[A-Z0-9_]+)\s*,")
HEX_START = re.compile(
    r"_mon_hex_zap\(\s*(ZAP_[A-Z0-9_]+)\s*,\s*"
    r"(BEAM_[A-Z0-9_]+)\s*(?:,\s*(\d+))?"
    r"\s*(?:,\s*([A-Z][A-Z0-9_]+))?\s*\)"
)
CALCULATOR = re.compile(
    r"new (dicedef|calcdice|tohit)_calculator<([^>]+)>"
)

# Every flavor in the pinned 44-spell beam family needs a real runtime rule.
SUPPORTED_FLAVOURS = {
    "BEAM_ACID",
    "BEAM_COLD",
    "BEAM_CRYSTAL",
    "BEAM_DAMNATION",
    "BEAM_DEVASTATION",
    "BEAM_DIGGING",
    "BEAM_DISPEL_UNDEAD",
    "BEAM_ELECTRICITY",
    "BEAM_FIRE",
    "BEAM_HOLY",
    "BEAM_ICE",
    "BEAM_LAVA",
    "BEAM_MIASMA",
    "BEAM_MMISSILE",
    "BEAM_NEG",
    "BEAM_POISON",
    "BEAM_POISON_ARROW",
    "BEAM_SLEEP",
    "BEAM_AGONY",
    "BEAM_BANISH",
    "BEAM_CONFUSION",
    "BEAM_CORONA",
    "BEAM_DIMENSION_ANCHOR",
    "BEAM_DRAIN_MAGIC",
    "BEAM_MINDBURST",
    "BEAM_PAIN",
    "BEAM_PETRIFY",
    "BEAM_PARALYSIS",
    "BEAM_POLYMORPH",
    "BEAM_SAP_MAGIC",
    "BEAM_SENTINEL_MARK",
    "BEAM_SLOW",
    "BEAM_VIRULENCE",
    "BEAM_VULNERABILITY",
    "BEAM_STEAM",
    "BEAM_STUN_BOLT",
    "BEAM_WATER",
}


def without_comments(source):
    def blank(match):
        return re.sub(r"[^\n]", " ", match.group())

    return re.sub(r"/\*.*?\*/|//[^\n]*", blank, source, flags=re.DOTALL)


def source_line(source, offset):
    return source.count("\n", 0, offset) + 1


def parse_spell_zaps(source):
    start = source.find("_spl_zaps[]")

    if start < 0:
        raise ValueError("source has no _spl_zaps[] table")

    end = source.find("};", start)

    if end < 0:
        raise ValueError("source has no _spl_zaps[] terminator")

    links = {}

    for match in SPELL_PAIR.finditer(without_comments(source), start, end):
        links.setdefault(match.group(1),
                         (match.group(2), source_line(source, match.start())))

    if not links:
        raise ValueError("_spl_zaps[] has no spell links")

    return links


def fields_in(entry):
    fields = []
    field_start = 0
    angle = 0
    quoted = False

    for index, char in enumerate(entry):
        if char == '"':
            quoted = not quoted
        elif not quoted and char == "<":
            angle += 1
        elif not quoted and char == ">":
            angle -= 1
        elif not quoted and char == "," and angle == 0:
            fields.append(entry[field_start:index].strip())
            field_start = index + 1

    tail = entry[field_start:].strip()

    if tail:
        fields.append(tail)

    return fields


def calculator(expression):
    if expression == "nullptr":
        return None

    match = CALCULATOR.fullmatch(expression)

    if not match:
        raise ValueError("unsupported monster calculator " + expression)

    args = []

    for item in match.group(2).split(","):
        item = item.strip()

        if item.isdigit():
            args.append(int(item))
        elif item == "AUTOMATIC_HIT":
            args.append(item)
        else:
            raise ValueError("unsupported monster calculator argument " + item)

    return match.group(1), tuple(args)


def parse_zap_data(source):
    cleaned = without_comments(source)
    start = cleaned.find("zap_data[]")

    if start < 0:
        raise ValueError("source has no zap_data[] table")

    zaps = {}

    for match in ZAP_START.finditer(cleaned, start):
        close = cleaned.find("}", match.end())

        if close < 0:
            raise ValueError("unterminated " + match.group(1))

        values = fields_in(cleaned[match.start() + 1:close])

        if len(values) != 14:
            raise ValueError(match.group(1) + " has " +
                             str(len(values)) + " fields, want 14")

        zap_id = values[0]

        if zap_id in zaps:
            raise ValueError("duplicate " + zap_id)

        zaps[zap_id] = {
            "id": zap_id,
            "name": values[1].strip('"'),
            "cap": int(values[2]),
            "monster_damage": calculator(values[5]),
            "monster_tohit": calculator(values[6]),
            "colour": values[7],
            "is_enchantment": values[8] == "true",
            "flavour": values[9],
            "glyph": values[10],
            "can_beam": values[11] == "true",
            "is_explosion": values[12] == "true",
            "noise": int(values[13]),
            "source_line": source_line(source, match.start()),
        }

    for match in HEX_START.finditer(cleaned, start):
        zap_id = match.group(1)

        if zap_id in zaps:
            raise ValueError("duplicate " + zap_id)

        zaps[zap_id] = {
            "id": zap_id,
            "name": "",
            "cap": int(match.group(3) or 100),
            "monster_damage": None,
            "monster_tohit": ("tohit", (0, 1, 3)),
            "colour": match.group(4) or "BLACK",
            "is_enchantment": True,
            "flavour": match.group(2),
            "glyph": "NUM_DCHAR_TYPES",
            "can_beam": False,
            "is_explosion": False,
            "noise": 0,
            "source_line": source_line(source, match.start()),
        }

    if not zaps:
        raise ValueError("zap_data[] has no zap profiles")

    return zaps


def calculator_lines(name, value):
    if value is None:
        return [f"    {name} = false,"]

    kind, args = value
    lines = [
        f"    {name} = {{",
        f"        kind = {json.dumps(kind)},",
        "        args = {",
    ]

    for arg in args:
        encoded = json.dumps(arg) if isinstance(arg, str) else str(arg)
        lines.append(f"            {encoded},")

    lines.extend(["        },", "    },"])

    return lines


def lua_bool(value):
    return "true" if value else "false"


def render_profile(spell_id, zap_id, spell_line, zap,
                   power_factor=12, natural=False,
                   mapping_source="spl-zap.cc", override=None):
    lines = [
        "-- Generated from a committed DCSS import. Refresh deliberately.",
        f"-- Revision: {REVISION}",
        f"-- {mapping_source}:{spell_line}",
        f"-- zap-data.h:{zap['source_line']}",
        "",
        'local categories = require("constants.catalog")',
        'local zaps = require("constants.zap_ids")',
        'local flavours = require("constants.beam_flavours")',
        'local colours = require("constants.beam_colours")',
        'local glyphs = require("constants.beam_glyphs")',
        "",
        "local definition = {",
        f"    id = {json.dumps(spell_id)},",
        f"    zap_id = zaps.{zap_id},",
        f"    name = {json.dumps(zap['name'])},",
        f"    cap = {zap['cap']},",
        f"    power_hd_factor = {power_factor},",
        f"    natural_power = {lua_bool(natural)},",
    ]

    if spell_id == "SPELL_PAIN":
        # mons_power_for_hd floors Pain at 50 * ENCH_POW_FACTOR (3).
        lines.append("    minimum_power = 150,")

    if override:
        lines.extend([
            f"    -- mon-cast.cc:{override['source_line']}",
            f"    short_name = {json.dumps(override['short_name'])},",
        ])

    lines.extend(calculator_lines("monster_damage", zap["monster_damage"]))
    lines.extend(calculator_lines("monster_tohit", zap["monster_tohit"]))
    lines.extend([
        f"    colour = colours.{zap['colour']},",
        f"    is_enchantment = {lua_bool(zap['is_enchantment'])},",
        f"    flavour = flavours.{zap['flavour']},",
        f"    glyph = glyphs.{zap['glyph']},",
        f"    can_beam = {lua_bool(zap['can_beam'])},",
        f"    is_explosion = {lua_bool(zap['is_explosion'])},",
        f"    hit_loudness = {zap['noise']},",
        "}",
        "",
        "register.definition(categories.MONSTER_BEAMS, definition)",
        "",
        "return definition",
        "",
    ])

    return "\n".join(lines)


def render_constants(symbols):
    lines = [
        "-- Generated from a committed DCSS import. Refresh deliberately.",
        f"-- Revision: {REVISION}",
        "local ids = {",
    ]

    for symbol in sorted(symbols):
        lines.append(f"    {symbol} = {json.dumps(symbol)},")

    lines.extend(["}", "", "return ids", ""])

    return "\n".join(lines)


def function_body(source, signature):
    start = source.find(signature)

    if start < 0:
        raise ValueError("missing source function " + signature)

    opening = source.find("{", start)
    depth = 0

    for index in range(opening, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1

            if depth == 0:
                return source[opening + 1:index]

    raise ValueError("unterminated source function " + signature)


def parse_power_rules(mon_cast):
    factor_body = function_body(mon_cast,
                                "static int _mons_power_hd_factor(")
    natural_body = function_body(mon_cast,
                                 "bool mons_spell_is_spell(")
    factors = {}
    pending = []
    default = None

    for line in factor_body.splitlines():
        case = re.search(r"case (SPELL_[A-Z0-9_]+):", line)

        if case:
            pending.append(case.group(1))

        result = re.search(r"return (\d+)(?: \* ENCH_POW_FACTOR)?;", line)

        if result:
            factor = int(result.group(1))

            if "ENCH_POW_FACTOR" in line:
                factor *= 3  # mon-cast.h at the pinned revision

            if pending:
                for spell_id in pending:
                    factors[spell_id] = factor
            elif "default:" in previous:
                default = factor

            pending = []

        previous = line

    if default is None:
        raise ValueError("missing source monster power default")

    natural = set(re.findall(r"case (SPELL_[A-Z0-9_]+):",
                             natural_body.split("default:", 1)[0]))

    return factors, natural, default


def hex_power_rules(mon_cast):
    """Read explicit _hex_logic factors without matching lambda internals."""
    factors = {}
    calls = re.finditer(r"_hex_logic\(\s*(SPELL_[A-Z0-9_]+)", mon_cast)

    for call in calls:
        opening = mon_cast.find("(", call.start())
        depth = 0
        closing = None

        for index in range(opening, len(mon_cast)):
            if mon_cast[index] == "(":
                depth += 1
            elif mon_cast[index] == ")":
                depth -= 1

                if depth == 0:
                    closing = index
                    break

        if closing is None:
            raise ValueError("unterminated _hex_logic for " + call.group(1))

        arguments = mon_cast[opening + 1:closing]
        explicit = re.search(r",\s*(\d+)\s*$", arguments)

        if explicit:
            factors[call.group(1)] = int(explicit.group(1)) * 3

    sap = re.search(
        r"\{\s*SPELL_SAP_MAGIC\s*,\s*\{.*?"
        r"_zap_setup\(SPELL_SAP_MAGIC\)\s*,\s*"
        r"MSPELL_LOGIC_NONE\s*,\s*(\d+)\s*,",
        mon_cast,
        re.DOTALL,
    )

    if not sap:
        raise ValueError("missing source Sap Magic power factor")

    factors["SPELL_SAP_MAGIC"] = int(sap.group(1))

    return factors


def beam_overrides(mon_cast, spell_ids):
    start = mon_cast.find("switch (real_spell)")

    if start < 0:
        raise ValueError("missing monster beam setup switch")

    opening = mon_cast.find("{", start)
    section = function_body(mon_cast, "switch (real_spell)")
    section_start = opening + 1
    cases = list(re.finditer(r"case (SPELL_[A-Z0-9_]+):", section))
    overrides = {}

    for index, case in enumerate(cases):
        spell_id = case.group(1)

        if spell_id not in spell_ids:
            continue

        next_start = cases[index + 1].start() if index + 1 < len(cases) else len(section)
        body = section[case.end():next_start]
        assignments = list(re.finditer(
            r"beam\.([a-z_]+)\s*=\s*([^;]+);", body
        ))

        if not assignments:
            continue

        if spell_id == "SPELL_DIMENSION_ANCHOR" and \
                len(assignments) == 1 and \
                assignments[0].group(1) == "flavour" and \
                assignments[0].group(2).strip() == \
                "BEAM_DIMENSION_ANCHOR":
            # The setup repeats the zap's flavor, so the profile is exact.
            continue

        if spell_id != "SPELL_ENERGY_BOLT" or \
                len(assignments) != 1 or \
                assignments[0].group(1) != "short_name" or \
                assignments[0].group(2).strip() != '"energy"':
            names = ", ".join(match.group(1) for match in assignments)

            raise ValueError("unsupported source beam override " +
                             spell_id + ": " + names)

        overrides[spell_id] = {
            "short_name": "energy",
            "source_line": source_line(
                mon_cast,
                section_start + case.end() + assignments[0].start(),
            ),
        }

    return overrides


def render_catalog(spell_ids, links, zaps, mon_cast):
    rendered = {}
    used = []
    factors, natural, default = ({}, set(), 12)

    if mon_cast:
        factors, natural, default = parse_power_rules(mon_cast)

        if "SPELL_SAP_MAGIC" in spell_ids:
            factors.update(hex_power_rules(mon_cast))

    overrides = beam_overrides(mon_cast, spell_ids) if mon_cast else {}

    for spell_id in sorted(spell_ids):
        mapping = links.get(spell_id)
        mapping_source = "spl-zap.cc"

        if spell_id == "SPELL_FREEZING_CLOUD" and mapping is None:
            if "case SPELL_FREEZING_CLOUD:" not in mon_cast or \
                    "zappy(ZAP_FREEZING_BLAST" not in mon_cast:
                raise ValueError("missing source override for " + spell_id)

            mapping = ("ZAP_FREEZING_BLAST", source_line(
                mon_cast, mon_cast.index("case SPELL_FREEZING_CLOUD:")))
            mapping_source = "mon-cast.cc"

        if mapping is None:
            raise ValueError("missing source zap for " + spell_id)

        zap_id, spell_line = mapping
        zap = zaps.get(zap_id)

        if zap is None:
            raise ValueError("missing source profile for " +
                             spell_id + "/" + zap_id)

        if zap["flavour"] not in SUPPORTED_FLAVOURS:
            raise ValueError("unsupported monster beam flavour " +
                             zap["flavour"] + " for " + spell_id)

        used.append(zap)
        name = spell_id.removeprefix("SPELL_").lower()
        path = f"content/monster_beams/{name}.lua"
        rendered[path] = render_profile(
            spell_id,
            zap_id,
            spell_line,
            zap,
            factors.get(spell_id, default),
            spell_id in natural,
            mapping_source,
            overrides.get(spell_id),
        )

    groups = {
        "zap_ids": {zap["id"] for zap in used},
        "beam_flavours": {zap["flavour"] for zap in used},
        "beam_colours": {zap["colour"] for zap in used},
        "beam_glyphs": {zap["glyph"] for zap in used},
    }

    for name, symbols in groups.items():
        rendered[f"constants/{name}.lua"] = render_constants(symbols)

    return rendered


def write_output(files, output_root, check):
    for relative, expected in files.items():
        destination = output_root / relative

        if check:
            if not destination.is_file() or \
                    destination.read_text() != expected:
                raise ValueError("stale monster beam profile " + relative)

            continue

        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(expected)


def spell_ids_from_spec():
    document = SPEC.read_text()
    appendix = document.split("## Source spell IDs", 1)[1]
    listed = appendix.split("```text", 1)[1].split("```", 1)[0]
    ids = re.findall(r"SPELL_[A-Z0-9_]+", listed)

    if len(ids) != 44 or len(set(ids)) != 44:
        raise ValueError("source beam spell appendix must list 44 unique IDs")

    hex_document = HEX_SPEC.read_text()
    hex_appendix = hex_document.split("## Source spell IDs", 1)[1]
    hex_listed = hex_appendix.split("```text", 1)[1].split("```", 1)[0]
    hex_ids = re.findall(r"SPELL_[A-Z0-9_]+", hex_listed)

    if len(hex_ids) != 17 or len(set(hex_ids)) != 17:
        raise ValueError("source hex spell appendix must list 17 unique IDs")

    if set(ids) & set(hex_ids):
        raise ValueError("source hex spells overlap the earlier beam family")

    return set(ids) | set(hex_ids)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    links = parse_spell_zaps((args.source_dir / "spl-zap.cc").read_text())
    zaps = parse_zap_data((args.source_dir / "zap-data.h").read_text())
    mon_cast = (args.source_dir / "mon-cast.cc").read_text()
    files = render_catalog(spell_ids_from_spec(), links, zaps, mon_cast)

    write_output(files, args.output, args.check)

    print("61 committed monster zap profiles " +
          ("verified" if args.check else "generated"))


if __name__ == "__main__":
    main()
