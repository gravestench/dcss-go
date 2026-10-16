#!/usr/bin/env python3
"""Refresh committed Lua catalogs from committed DCSS import artifacts.

This is a deliberate source update tool, never part of a normal Go build.
The JSON artifacts retain their independent import validation while the Lua
copies are the data that game rules can load and override by relative path.
"""

import argparse
import json
import math
import re
from pathlib import Path

from import_wand_spells import validate_links
from menu_group_keys import group_key


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "internal/content/generated"
DESTINATION = ROOT / "internal/modfs/builtin/data"
CONSTANTS = ROOT / "internal/modfs/builtin/constants"

CATALOGS = (
    "monster-vocabulary",
    "presentation",
)

DEFINITIONS = {
    "branches": ("branches", "branches"),
    "items": ("items", "items"),
    "monster-spellbooks": ("books", "monster_spellbooks"),
    "monsters": ("monsters", "monsters"),
    "spells": ("spells", "spells"),
}

CONTENT = ROOT / "internal/modfs/builtin/content"

PROVENANCE_FIELDS = frozenset({
    "source_revision",
    "source_files",
    "source_path",
    "source_line",
    "enum_line",
    "name_source",
    "property_source",
    "evidence",
    "tag_major_version",
    "wand_spell_source_path",
    "wand_spell_source_line",
    "spec_line",
    "weapon_list_line",
    "brand_list_line",
})


def source_comments(value):
    if not isinstance(value, dict):
        return []

    comments = []
    path = value.get("source_path")
    line = value.get("source_line")

    if "spec_line" in value:
        gear_path = "crawl-ref/source/mon-gear.cc"

        for label, field in (
            ("Source", "source_line"),
            ("Spec", "spec_line"),
            ("Weapon list", "weapon_list_line"),
            ("Brand list", "brand_list_line"),
        ):
            if value.get(field):
                comments.append(f"{label}: {gear_path}:{value[field]}")
    elif path:
        comments.append(f"Source: {path}" + (f":{line}" if line else ""))
    elif line:
        comments.append(f"Source line: {line}")

    if value.get("enum_line"):
        comments.append(f"Enum line: {value['enum_line']}")

    for field in ("name_source", "property_source"):
        if value.get(field):
            comments.append(f"{field.replace('_', ' ').title()}: {value[field]}")

    evidence = value.get("evidence")

    if isinstance(evidence, dict):
        for field, line in evidence.items():
            if line:
                comments.append(f"{field.replace('_', ' ').title()}: {line}")

    return comments


def lua_string(value):
    escaped = []

    for char in value:
        code = ord(char)

        if char == "\\":
            escaped.append("\\\\")
        elif char == '"':
            escaped.append('\\"')
        elif char == "\n":
            escaped.append("\\n")
        elif char == "\r":
            escaped.append("\\r")
        elif char == "\t":
            escaped.append("\\t")
        elif code < 32 or code == 127:
            escaped.append(f"\\{code:03d}")
        else:
            escaped.append(char)

    return '"' + "".join(escaped) + '"'


def key_name(key):
    if key.isidentifier() and not key[0].isdigit():
        return key

    return "[" + lua_string(key) + "]"


def string_chunks(value, width):
    chunks = []
    current = ""

    for char in value:
        candidate = current + char

        if current and len(lua_string(candidate).encode()) > width:
            chunks.append(current)
            current = char
        else:
            current = candidate

    if current:
        chunks.append(current)

    return chunks


def lines_for(value, depth=0):
    indent = "    " * depth

    if value is None:
        return ["mod.null"]

    if isinstance(value, bool):
        return ["true" if value else "false"]

    if isinstance(value, int):
        return [str(value)]

    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError("catalog has a non-finite number")

        return [repr(value)]

    if isinstance(value, str):
        return [lua_string(value)]

    if isinstance(value, (dict, list)):
        entries = value.items() if isinstance(value, dict) else enumerate(value)
        result = ["{"]

        for key, child in entries:
            if isinstance(value, dict) and key in PROVENANCE_FIELDS:
                continue

            for comment in source_comments(child):
                result.append(indent + "    -- " + comment)

            prefix = key_name(key) + " = " if isinstance(key, str) else ""

            if isinstance(child, str):
                single_line = indent + "    " + prefix + lua_string(child)

                if len(single_line.encode()) > 119:
                    padding = indent + "        "
                    width = 119 - len(padding.encode()) - 3
                    chunks = string_chunks(child, width)

                    if prefix:
                        result.append(indent + "    " + prefix.rstrip())

                    for chunk in chunks[:-1]:
                        result.append(padding + lua_string(chunk) + " ..")

                    result.append(padding + lua_string(chunks[-1]) + ",")
                    continue

            child_lines = lines_for(child, depth + 1)
            result.append(indent + "    " + prefix + child_lines[0])

            for continuation in child_lines[1:]:
                result.append(continuation)

            result[-1] += ","

        result.append(indent + "}")

        return result

    raise TypeError(f"unsupported catalog value: {type(value)}")


def render(name):
    source = SOURCE / f"{name}.json"
    artifact = json.loads(source.read_text())
    revision = artifact["source_revision"]

    if name == "presentation":
        artifact = {
            key: value
            for key, value in artifact.items()
            if key not in {
                "species_groups", "job_groups",
                "species_descriptions", "job_descriptions",
            }
        }
    header = [
        "-- Generated from a committed DCSS import. Refresh deliberately.",
        f"-- Revision: {revision}",
    ]

    for entry in artifact["source_files"]:
        header.append(f"-- Source: {entry['path']}")
        header.append(f"-- SHA-256: {entry['sha256']}")

    body = lines_for(artifact)
    body[0] = "local catalog = " + body[0]

    return "\n".join(header + [""] + body + ["", "return catalog"]) + "\n"


def render_menu_groups(artifact):
    lines = [
        "-- Generated from a committed DCSS import. Refresh deliberately.",
        f"-- Revision: {artifact['source_revision']}",
        "-- Source: crawl-ref/source/species-groups.h",
        "-- Source: crawl-ref/source/newgame.cc",
        "",
        "local groups = {",
        '    MODDED_SPECIES = "Modded species",',
        '    MODDED_BACKGROUNDS = "Modded backgrounds",',
    ]

    for category, field in (
        ("species", "species_groups"),
        ("job", "job_groups"),
    ):
        for entry in artifact[field]:
            key = group_key(category, entry["label"])
            lines.append(f"    {key} = {lua_string(entry['label'])},")

    lines.append("}")

    for category, field in (
        ("species", "species_groups"),
        ("job", "job_groups"),
    ):
        name = "species" if category == "species" else "jobs"
        lines.extend(["", f"groups.{name} = {{"])

        for entry in artifact[field]:
            key = group_key(category, entry["label"])
            lines.append(f"    groups.{key},")

        lines.append("}")

        lines.extend(["", f"groups.{name}_capacities = {{"])

        for entry in artifact[field]:
            lines.append(f"    {len(entry['ids'])},")

        lines.append("}")

    lines.extend(["", "return groups"])

    return "\n".join(lines) + "\n"


def render_definition(category, revision, definition):
    header = [
        "-- Generated from a committed DCSS import. Refresh deliberately.",
        f"-- Revision: {revision}",
    ]

    header.extend("-- " + comment for comment in source_comments(definition))
    header.extend(["", 'local categories = require("constants.catalog")'])
    wand_spell = definition.get("wand_spell_id")
    staff = definition.get("staff")
    jewellery = definition.get("jewellery")
    population = definition.get("population")
    weapon_gear = definition.get("weapon_gear")

    if wand_spell:
        header.append('local spells = require("ids.spells")')

    if staff:
        header.append('local schools = require("constants.spell_schools")')

        if staff.get("resistance_id"):
            header.append('local resistances = require("constants.resistance_ids")')

    if jewellery:
        header.append('local jewellery_kinds = require("constants.jewellery_kind")')

        if jewellery.get("effects"):
            header.append(
                'local capabilities = require("constants.jewellery_capabilities")'
            )
            header.append(
                'local magnitudes = require("constants.jewellery_magnitudes")'
            )

    if population:
        header.append('local curves = require("constants.population_curves")')

    if weapon_gear:
        gear_ids = {
            choice["id"]
            for spec in weapon_gear.values()
            for field in ("weapons", "brands")
            for choice in (spec.get(field) or [])
        }

        if any(identifier.startswith("WPN_") for identifier in gear_ids):
            header.append('local item_ids = require("ids.items")')

        if any(identifier.startswith("SPWPN_") for identifier in gear_ids):
            header.append('local brands = require("constants.weapon_brands")')

        if gear_ids.intersection({"NUM_WEAPONS", "NUM_SPECIAL_WEAPONS"}):
            header.append(
                'local sentinels = require("constants.monster_gear_sentinels")'
            )

    body = lines_for(definition)
    body[0] = "local definition = " + body[0]

    if population:
        for index, line in enumerate(body):
            match = re.fullmatch(r'(\s*curve = )"([A-Z]+)",', line)

            if match:
                body[index] = f"{match.group(1)}curves.{match.group(2)},"

    if weapon_gear:
        replacements = {
            "NUM_WEAPONS": "sentinels.NO_WEAPON",
            "NUM_SPECIAL_WEAPONS": "sentinels.NO_FORCED_BRAND",
        }

        for index, line in enumerate(body):
            match = re.fullmatch(
                r'(\s*id = )"(WPN_[A-Z0-9_]+|SPWPN_[A-Z0-9_]+|'
                r'NUM_WEAPONS|NUM_SPECIAL_WEAPONS)",', line
            )

            if not match:
                continue

            identifier = match.group(2)
            value = replacements.get(identifier)

            if value is None and identifier.startswith("WPN_"):
                value = f"item_ids.{identifier}"
            elif value is None and identifier.startswith("SPWPN_"):
                value = f"brands.{identifier.removeprefix('SPWPN_')}"

            body[index] = f"{match.group(1)}{value},"

    if wand_spell:
        if re.fullmatch(r"SPELL_[A-Z0-9_]+", wand_spell) is None:
            raise ValueError(f"invalid wand spell ID {wand_spell}")

        original = f"    wand_spell_id = {lua_string(wand_spell)},"
        index = body.index(original)
        source_path = definition["wand_spell_source_path"]
        source_line = definition["wand_spell_source_line"]
        body[index:index + 1] = [
            f"    -- Source: {source_path}:{source_line}",
            f"    wand_spell_id = spells.{wand_spell},",
        ]

    if staff:
        school = staff["school"]
        original = f"        school = {lua_string(school)},"
        body[body.index(original)] = f"        school = schools.{school.upper()},"

        resistance = staff.get("resistance_id")

        if resistance:
            keys = {
                "MR_RES_FIRE": "FIRE",
                "MR_RES_COLD": "COLD",
                "MR_RES_POISON": "POISON",
                "MR_RES_NEG": "NEGATIVE_ENERGY",
                "MR_RES_ELEC": "ELECTRICITY",
            }
            key = keys.get(resistance)

            if key is None:
                raise ValueError(f"unknown staff resistance {resistance}")

            original = f"        resistance_id = {lua_string(resistance)},"
            body[body.index(original)] = f"        resistance_id = resistances.{key},"

        naming = body.index("    naming = {")
        separator = naming - 1 if body[naming - 1].lstrip().startswith("--") else naming
        body.insert(separator, "")

    if jewellery:
        kind = jewellery["kind"]
        constant = "RING" if kind == "ring" else "AMULET"

        if kind not in ("ring", "amulet"):
            raise ValueError(f"unknown jewellery kind {kind}")

        original = f"        kind = {lua_string(kind)},"
        body[body.index(original)] = (
            f"        kind = jewellery_kinds.{constant},"
        )

        if jewellery.get("pluses"):
            body.insert(body.index("        pluses = true,"),
                        "        -- Source: crawl-ref/source/item-prop.cc:2129-2135")

        if jewellery.get("effects"):
            for capability, magnitude in jewellery["effects"].items():
                literal = (lua_string(magnitude) if isinstance(magnitude, str)
                           else str(magnitude))
                original = f"            {capability} = {literal},"
                replacement = f"            [capabilities.{capability}] = "

                if magnitude == "item_plus":
                    replacement += "magnitudes.ITEM_PLUS,"
                else:
                    replacement += f"{magnitude},"

                body[body.index(original)] = replacement

            source = ("player-equip.cc:1000-1290" if kind == "amulet"
                      else "artefact.cc:346-379")
            body.insert(body.index("        effects = {"),
                        f"        -- Source: crawl-ref/source/{source}")

        record = body.index("    jewellery = {")
        body.insert(record,
                    "    -- Source: crawl-ref/source/item-prop-enum.h:200-266")
        naming = body.index("    naming = {")
        separator = naming - 1 if body[naming - 1].lstrip().startswith("--") else naming
        body.insert(separator, "")

    footer = [
        "",
        f"register.definition(categories.{category.upper()}, definition)",
        "",
        "return definition",
    ]

    return "\n".join(header + [""] + body + footer) + "\n"


def enrich_item_definitions(items_artifact, links_artifact, spells_artifact):
    revision = items_artifact["source_revision"]

    if links_artifact["source_revision"] != revision:
        raise ValueError("wand spell and item source revisions differ")

    validate_links(links_artifact["links"], items_artifact, spells_artifact)
    staff_rules = json.loads((SOURCE / "staff-rules.json").read_text())
    jewellery_rules = json.loads((SOURCE / "jewellery-rules.json").read_text())

    if staff_rules["source_revision"] != revision:
        raise ValueError("staff rules and item source revisions differ")

    if jewellery_rules["source_revision"] != revision:
        raise ValueError("jewellery rules and item source revisions differ")

    by_staff = {rule["id"]: rule for rule in staff_rules["staves"]}
    by_jewellery = {
        rule["id"]: rule for rule in jewellery_rules["rules"]
    }
    active_staves = {
        item["id"]
        for item in items_artifact["items"]
        if item["class"] == "OBJ_STAVES" and not item["explicitly_removed"]
    }

    if set(by_staff) != active_staves or len(by_staff) != len(staff_rules["staves"]):
        raise ValueError("staff rules must cover each active magical staff once")

    active_jewellery = {
        item["id"]
        for item in items_artifact["items"]
        if item["class"] == "OBJ_JEWELLERY" and
        not item["explicitly_removed"]
    }

    if (set(by_jewellery) != active_jewellery or
            len(by_jewellery) != len(jewellery_rules["rules"])):
        raise ValueError("jewellery rules must cover each active item once")

    by_wand = {
        link["wand_id"]: link
        for link in links_artifact["links"]
    }
    jewellery_pluses = {
        "RING_SLAYING",
        "RING_PROTECTION",
        "RING_EVASION",
        "RING_STRENGTH",
        "RING_INTELLIGENCE",
        "RING_DEXTERITY",
    }
    definitions = []

    for item in items_artifact["items"]:
        link = by_wand.get(item["id"])
        staff = by_staff.get(item["id"])
        jewellery = (item["class"] == "OBJ_JEWELLERY" and
                     not item["explicitly_removed"])

        if link is None and staff is None and not jewellery:
            definitions.append(item)
            continue

        definition = {}

        for key, value in item.items():
            definition[key] = value

            if key == "class" and staff:
                definition["slot"] = "weapon"

            if key == "stackable" and staff:
                definition["staff"] = {
                    field: value
                    for field, value in staff.items()
                    if field != "id"
                }

            if key == "stackable" and jewellery:
                definition["jewellery"] = {
                    "kind": "ring" if item["id"].startswith("RING_")
                    else "amulet",
                }

                if item["id"] in jewellery_pluses:
                    definition["jewellery"]["pluses"] = True

                definition["jewellery"]["effects"] = by_jewellery[
                    item["id"]
                ]["effects"]

            if key == "stackable" and link:
                definition["wand_spell_id"] = link["spell_id"]

        if link:
            definition["wand_spell_source_path"] = links_artifact["source_path"]
            definition["wand_spell_source_line"] = link["source_line"]
        definitions.append(definition)

    return definitions


def enrich_monster_definitions(
    monsters_artifact, population_artifact, gear_artifact, items_artifact
):
    revision = monsters_artifact["source_revision"]

    for name, artifact in (
        ("population", population_artifact),
        ("gear", gear_artifact),
        ("items", items_artifact),
    ):
        if artifact["source_revision"] != revision:
            raise ValueError(f"monster and {name} source revisions differ")

    definitions = [dict(monster) for monster in monsters_artifact["monsters"]]
    by_id = {monster["id"]: monster for monster in definitions}

    if len(by_id) != len(definitions):
        raise ValueError("monster catalog contains duplicate IDs")

    for order, row in enumerate(population_artifact["rows"], start=1):
        monster_id = row["monster_id"]
        monster = by_id.get(monster_id)

        if monster is None or monster["status"] != "defined":
            raise ValueError(f"population row {order} has undefined {monster_id}")

        owned = {"source_order": order}
        owned.update({
            field: value
            for field, value in row.items()
            if field != "monster_id"
        })
        monster.setdefault("population", []).append(owned)

    weapons = {
        item["id"] for item in items_artifact["items"]
        if item.get("class") == "OBJ_WEAPONS"
        and item.get("status") not in ("removed", "enum_only")
    }
    brand_source = (CONSTANTS / "weapon_brands.lua").read_text()
    brands = set(re.findall(
        r'^\s+[A-Z_]+ = "(SPWPN_[A-Z_]+)",$',
        brand_source,
        re.MULTILINE,
    ))

    for slot in ("primary", "secondary"):
        seen = set()

        for row in gear_artifact[slot]:
            monster_id = row["monster_id"]
            monster = by_id.get(monster_id)

            if monster_id in seen:
                raise ValueError(f"duplicate {slot} monster gear {monster_id}")

            if monster is None or monster["status"] != "defined":
                raise ValueError(f"{slot} monster gear has undefined {monster_id}")

            for choice in row["weapons"]:
                identifier = choice["id"]

                if identifier not in weapons and identifier != "NUM_WEAPONS":
                    raise ValueError(f"{monster_id} has invalid weapon {identifier}")

            for choice in row["brands"] or []:
                identifier = choice["id"]

                if identifier not in brands and identifier != "NUM_SPECIAL_WEAPONS":
                    raise ValueError(f"{monster_id} has invalid brand {identifier}")

            seen.add(monster_id)
            monster.setdefault("weapon_gear", {})[slot] = {
                field: value for field, value in row.items()
                if field != "monster_id"
            }

    return definitions


def output_files():
    presentation = json.loads((SOURCE / "presentation.json").read_text())
    yield CONSTANTS / "menu_groups.lua", render_menu_groups(presentation)

    for name in CATALOGS:
        yield DESTINATION / f"{name.replace('-', '_')}.lua", render(name)

    for name, (field, category) in DEFINITIONS.items():
        artifact = json.loads((SOURCE / f"{name}.json").read_text())
        revision = artifact["source_revision"]
        definitions = artifact[field]

        if name == "items":
            links = json.loads((SOURCE / "wand-spells.json").read_text())
            spells = json.loads((SOURCE / "spells.json").read_text())
            definitions = enrich_item_definitions(artifact, links, spells)

        if name == "monsters":
            population = json.loads((SOURCE / "dungeon-population.json").read_text())
            gear = json.loads((SOURCE / "monster-weapons.json").read_text())
            items = json.loads((SOURCE / "items.json").read_text())
            definitions = enrich_monster_definitions(
                artifact, population, gear, items
            )

        for index, definition in enumerate(definitions, start=1):
            filename = f"{index:04d}_{definition['id'].lower()}.lua"
            path = CONTENT / category / filename
            yield path, render_definition(category, revision, definition)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    stale = []
    files = dict(output_files())

    for path, expected in files.items():

        if args.check:
            if not path.exists() or path.read_text() != expected:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(expected)

    for _, category in DEFINITIONS.values():
        directory = CONTENT / category

        for path in directory.glob("*.lua"):
            if path in files:
                continue

            if args.check:
                stale.append(str(path.relative_to(ROOT)))
            else:
                path.unlink()

    for name in DEFINITIONS:
        legacy = DESTINATION / f"{name.replace('-', '_')}.lua"

        if not legacy.exists():
            continue

        if args.check:
            stale.append(str(legacy.relative_to(ROOT)))
        else:
            legacy.unlink()

    for legacy_name in (
        "dungeon_population.lua", "item_identities.lua",
        "monster_weapons.lua",
    ):
        legacy = DESTINATION / legacy_name

        if legacy.exists():
            if args.check:
                stale.append(str(legacy.relative_to(ROOT)))
            else:
                legacy.unlink()

    old_gear = DESTINATION / "starting_gear.lua"

    if old_gear.exists():
        if args.check:
            stale.append(str(old_gear.relative_to(ROOT)))
        else:
            old_gear.unlink()

    if stale:
        raise SystemExit("stale Lua catalogs: " + ", ".join(stale))


if __name__ == "__main__":
    main()
