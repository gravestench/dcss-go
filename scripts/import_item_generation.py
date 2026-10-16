#!/usr/bin/env python3
"""Refresh committed item-generation metadata from the pinned DCSS tree.

This is a deliberate import command. Normal builds and play use the
committed JSON and Lua files rather than reading the C++ checkout.
"""

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = Path("/Users/dylanknuth/src/crawl/crawl-ref/source")
GENERATED = ROOT / "internal/content/generated"

PINNED_REVISION = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"
FORCED_CLASSES = {
    "OBJ_CORPSES",
    "OBJ_ORBS",
    "OBJ_RUNES",
}
ABSENT_CLASSES = {
    "OBJ_FOOD",
    "OBJ_RODS",
}
# Source: crawl-ref/source/makeitem.cc:611-631 and 1624-1634.
RANDOM_MISSILES = {
    "MI_STONE",
    "MI_DART",
    "MI_BOOMERANG",
    "MI_JAVELIN",
    "MI_THROWING_NET",
    "MI_LARGE_ROCK",
}
RANDOM_MISCELLANY = {
    "MISC_PHIAL_OF_FLOODS",
    "MISC_LIGHTNING_ROD",
    "MISC_BOX_OF_BEASTS",
    "MISC_PHANTOM_MIRROR",
    "MISC_TIN_OF_TREMORSTONES",
    "MISC_CONDENSER_VANE",
    "MISC_XOMS_CHESSBOARD",
}
NUMERIC_PROPERTIES = {
    "AC", "ANGRY", "BASE_ACC", "BASE_DAM", "BASE_DELAY", "COLD",
    "DEX", "EV", "FIRE", "HP", "INT", "LIFE", "MP", "PLUS",
    "REGEN", "SH", "SLAY", "STEALTH", "STR", "VALUE", "WILL",
}


def _art_blocks(text):
    block = []
    first_line = 1

    for number, line in enumerate(text.splitlines(), start=1):
        if line.strip():
            if not block:
                first_line = number

            block.append(line)
            continue

        if block:
            yield first_line, block
            block = []

    if block:
        yield first_line, block


def _enum_from_name(name):
    value = name.replace("'", "")
    quoted = re.search(r'"(.*)"', value)
    of = re.search(r" of (?:the )?(.*)", value)

    if quoted:
        value = quoted.group(1)
    elif of:
        value = of.group(1)

    return re.sub(r"[ -]", "_", value.upper())


def parse_preferred_unrand_depths(source_text):
    body = source_text.split("static int _preferred_max_level", 1)[1]
    body = body.split("default:", 1)[0]
    preferred = {}
    pending = []

    for line in body.splitlines():
        match = re.search(r"case (UNRAND_[A-Z0-9_]+):", line)

        if match:
            pending.append(match.group(1))

        depth = re.search(r"return (\d+);", line)

        if depth:
            for identifier in pending:
                preferred[identifier] = int(depth.group(1))

            pending = []

    return preferred


def parse_art_data(text, preferred_depths=None):
    """Keep every art-data record, including dummy and `nogen` entries."""
    records = []
    seen = set()

    for first_line, block in _art_blocks(text):
        fields = {}
        current = None

        for line in block:
            line = line.split("#", 1)[0]

            if not line.strip():
                continue

            match = re.match(r"^([A-Z_]+):\s*(.*)$", line)

            if match:
                current = match.group(1)
                fields[current] = match.group(2)
            elif current and not line.lstrip().startswith("#"):
                fields[current] += "\n" + line.strip()

        if "NAME" not in fields:
            continue

        if not fields.get("OBJ"):
            raise ValueError(f"art-data NAME {fields['NAME']} has no OBJ")

        if not fields.get("COLOUR"):
            raise ValueError(f"art-data NAME {fields['NAME']} has no COLOUR")

        enum = fields.get("ENUM") or _enum_from_name(fields["NAME"])
        identifier = "UNRAND_" + enum

        if identifier in seen:
            raise ValueError(f"duplicate art-data enum {identifier}")

        seen.add(identifier)
        flags = [flag.strip() for flag in fields.get("BOOL", "").split(",")]
        flags = [flag for flag in flags if flag]
        base_class, separator, base_kind = fields["OBJ"].partition("/")

        if not separator or not base_class or not base_kind:
            raise ValueError(f"art-data {identifier} has invalid OBJ")

        properties = {}

        for key in sorted(NUMERIC_PROPERTIES):
            if key in fields:
                properties[key.lower()] = int(fields[key])

        records.append({
            "id": identifier,
            "name": fields["NAME"],
            "source_order": len(records) + 1,
            "source_path": "crawl-ref/source/art-data.txt",
            "source_line": first_line,
            "class": base_class,
            "kind_id": base_kind,
            "fallback": fields.get("FALLBACK", ""),
            "brand": fields.get("BRAND", ""),
            "fallback_brand": fields.get("FB_BRAND", ""),
            "appearance": fields.get("APPEAR", ""),
            "inscription": fields.get("INSCRIP", ""),
            "description": fields.get("DESCRIP", ""),
            "brand_description": fields.get("DBRAND", ""),
            "colour": fields.get("COLOUR", ""),
            "tile": fields.get("TILE", ""),
            "tile_equipment": fields.get("TILE_EQ", ""),
            "type": fields.get("TYPE", ""),
            "flags": flags,
            "properties": properties,
            "generation": {
                "mode": "none" if enum.startswith("DUMMY") or "nogen" in flags
                else "random",
                **({"preferred_max_depth": preferred_depths[identifier]}
                   if preferred_depths and identifier in preferred_depths
                   else {}),
            },
        })

    return records


def _rarities(source_text, table_name):
    table = re.search(
        rf"static map<[^>]+> {table_name} = \{{(.*?)\n\}};",
        source_text,
        re.DOTALL,
    )

    if not table:
        raise ValueError(f"missing source rarity table {table_name}")

    return dict(re.findall(
        r"\{\s*([A-Z_0-9]+),\s*(RARITY_[A-Z_]+)\s*\}",
        table.group(1),
    ))


def parse_consumable_weights(source_text, function_name):
    function = re.search(
        rf"static int {function_name}\(.*?\)\s*\{{(.*?)\n\}}",
        source_text,
        re.DOTALL,
    )

    if not function:
        raise ValueError(f"missing source weight function {function_name}")

    weights = {
        rarity: int(weight)
        for rarity, weight in re.findall(
            r"case (RARITY_[A-Z_]+):\s*return (\d+);",
            function.group(1),
        )
    }

    if len(weights) != 5:
        raise ValueError(f"incomplete source weight function {function_name}")

    return weights


def parse_book_templates(enum_text, template_text):
    """Pair active book enum order with the source's spell templates."""
    enum_body = enum_text.split("enum book_type", 1)[1].split("};", 1)[0]
    template_body = template_text.split(
        "spellbook_templates[] =", 1
    )[1].split("};", 1)[0]

    def active(text):
        # The pinned source's tag-version.h sets TAG_MAJOR_VERSION to 34.
        # Every guarded book here is therefore part of the active catalog.
        return re.sub(r"^#(?:if|endif).*\n", "", text,
                      flags=re.MULTILINE)

    enum_body = re.sub(r"//.*", "", active(enum_body))
    names = []

    for entry in enum_body.split(","):
        if "=" in entry:
            continue

        name = re.search(r"\bBOOK_[A-Z0-9_]+\b", entry.split("=", 1)[0])

        if name:
            names.append(name.group(0))

    templates = re.findall(r"\{([^{}]*)\}", active(template_body))

    if len(names) != len(templates):
        raise ValueError("book enum and template counts differ")

    return {
        name: re.findall(r"\bSPELL_[A-Z0-9_]+\b", template)
        for name, template in zip(names, templates)
    }


def _item_mode(item, random_armour):
    if item.get("explicitly_removed") or item.get("status") in (
        "removed", "enum_only",
    ):
        return "none"

    if item["class"] in ABSENT_CLASSES:
        return "none"

    if item["class"] in FORCED_CLASSES:
        return "forced"

    if item["class"] == "OBJ_ARMOUR" and (
        item["id"] not in random_armour
    ):
        return "forced"

    if item["class"] == "OBJ_MISSILES" and (
        item["id"] not in RANDOM_MISSILES
    ):
        return "forced"

    if item["class"] == "OBJ_MISCELLANY" and (
        item["id"] not in RANDOM_MISCELLANY
    ):
        return "forced"

    return "random"


def parse_random_armour(makeitem_text):
    """Return armour subtypes the source's ordinary picker can produce."""
    body = makeitem_text.split(
        "static armour_type _get_random_armour_type", 1
    )[1].split("static void _generate_armour_item", 1)[0]
    selected = set(re.findall(r"\bARM_[A-Z0-9_]+\b", body))

    # makeitem.cc:1140 can replace generated boots with barding.
    selected.add("ARM_BARDING")

    return selected


def import_items(items_artifact, item_prop_text, makeitem_text,
                 book_templates=None):
    potions = _rarities(item_prop_text, "_potion_rarity")
    scrolls = _rarities(item_prop_text, "_scroll_rarity")
    potion_weights = parse_consumable_weights(
        makeitem_text, "_potion_weight"
    )
    scroll_weights = parse_consumable_weights(
        makeitem_text, "_scroll_weight"
    )
    random_armour = parse_random_armour(makeitem_text)
    result = []

    for item in items_artifact["items"]:
        mode = _item_mode(item, random_armour)
        generation = {
            "mode": mode,
            "source_path": "crawl-ref/source/makeitem.cc",
        }

        if item["class"] == "OBJ_WEAPONS" and mode == "random":
            generation["commonness"] = item.get("weapon", {}).get(
                "commonness", 0
            )
            generation["source_path"] = "crawl-ref/source/item-prop.cc"
        elif item["class"] in ("OBJ_POTIONS", "OBJ_SCROLLS"):
            rarity = (potions if item["class"] == "OBJ_POTIONS"
                      else scrolls).get(item["id"])
            weights = (potion_weights if item["class"] == "OBJ_POTIONS"
                       else scroll_weights)
            generation["rarity"] = rarity or "RARITY_NONE"
            generation["weight"] = weights.get(rarity, 0)
            generation["source_path"] = "crawl-ref/source/item-prop.cc"

            if generation["weight"] == 0 and mode == "random":
                generation["mode"] = "forced"
        elif item["class"] == "OBJ_BOOKS" and book_templates is not None:
            generation["spells"] = book_templates.get(item["id"], [])
            generation["source_path"] = "crawl-ref/source/book-data.h"

        result.append({
            "id": item["id"],
            "class": item["class"],
            "explicitly_removed": bool(item.get("explicitly_removed")),
            "generation": generation,
        })

    return result


def generated_artifacts(source):
    items = json.loads((GENERATED / "items.json").read_text())
    revision = items["source_revision"]

    if revision != PINNED_REVISION:
        raise ValueError(f"item catalog revision {revision} is not pinned")

    item_prop = (source / "item-prop.cc").read_text()
    makeitem = (source / "makeitem.cc").read_text()
    art_data = (source / "art-data.txt").read_text()
    artefact_source = (source / "artefact.cc").read_text()
    book_enum = (source / "book-type.h").read_text()
    book_data = (source / "book-data.h").read_text()
    book_templates = parse_book_templates(book_enum, book_data)

    return {
        GENERATED / "item-generation.json": {
            "schema_version": 1,
            "source_revision": revision,
            "items": import_items(
                items, item_prop, makeitem, book_templates
            ),
        },
        GENERATED / "unrands.json": {
            "schema_version": 1,
            "source_revision": revision,
            "artefacts": parse_art_data(
                art_data, parse_preferred_unrand_depths(artefact_source)
            ),
        },
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    stale = []

    for path, artifact in generated_artifacts(args.source).items():
        expected = json.dumps(artifact, indent=2, ensure_ascii=False) + "\n"

        if args.check:
            if not path.exists() or path.read_text() != expected:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.write_text(expected)

    if stale:
        raise SystemExit("stale item-generation imports: " + ", ".join(stale))


if __name__ == "__main__":
    main()
