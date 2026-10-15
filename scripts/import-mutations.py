#!/usr/bin/env python3
"""Refresh committed Lua mutation definitions from a pinned DCSS checkout."""

import argparse
import ast
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / "internal/modfs/builtin/content/mutations"
CONFLICT_DESTINATION = ROOT / "internal/modfs/builtin/data/mutation_conflicts.lua"
ENUM_DESTINATION = ROOT / "internal/modfs/builtin/data/mutation_enum.lua"
PINNED_REVISION = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

# Tag-34 keeps this old mutation only to read historical DCSS saves.
# This port starts with a new save format, so it must not grant that entry.
LEGACY_SAVE_ONLY = {"MUT_STOCHASTIC_TORMENT_RESISTANCE"}

ENTRY = re.compile(r"^\{\s*(MUT_[A-Z0-9_]+)\s*,", re.MULTILINE)
HEADER = re.compile(
    r"^\{\s*(MUT_[A-Z0-9_]+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,"
    r"\s*(.*?)\s*,\s*(true|false)\s*,",
    re.DOTALL,
)
STRING = re.compile(r'"(?:\\.|[^"\\])*"', re.DOTALL)
FLAG = re.compile(r"mutflag::([a-z_]+)")
TILE = re.compile(r"\b(TILEG_[A-Z0-9_]+)\b")
CONFLICT = re.compile(
    r"\{\s*(MUT_[A-Z0-9_]+)\s*,\s*(MUT_[A-Z0-9_]+)\s*,"
    r"\s*(-?\d+)\s*\}"
)


def source_revision(source_root):
    return subprocess.check_output(
        ["git", "-C", str(source_root), "rev-parse", "HEAD"],
        text=True,
    ).strip()


def entry_block(source, start):
    depth = 0
    quoted = False
    escaped = False

    for index in range(start, len(source)):
        char = source[index]

        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False

            continue

        if char == '"':
            quoted = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1

            if depth == 0:
                return source[start:index + 1]

    raise ValueError("unterminated mutation definition")


def quoted_values(source):
    return [ast.literal_eval(match.group()) for match in STRING.finditer(source)]


def removed_ids(source):
    start = source.index("get_removed_mutations()")
    begin = source.index("removed_mutations =", start)
    end = source.index("};", begin)

    return set(re.findall(r"\bMUT_[A-Z0-9_]+\b", source[begin:end]))


def parse_definition(block, removed, line):
    block = re.sub(r"/\*.*?\*/", "", block, flags=re.DOTALL)
    header = HEADER.match(block)

    if not header:
        raise ValueError(f"invalid mutation definition at source line {line}")

    mutation_id, weight, levels, use_flags, form_based = header.groups()
    body = block[header.end():]
    array_matches = list(re.finditer(r"\{([^{}]*)\}", body, re.DOTALL))

    if len(array_matches) != 3:
        raise ValueError(
            f"{mutation_id} has {len(array_matches)} description arrays"
        )

    before_arrays = body[:body.index("{")]
    names = quoted_values(before_arrays)

    if len(names) != 1:
        raise ValueError(f"{mutation_id} has no single short description")

    descriptions = [quoted_values(match.group(1)) for match in array_matches]

    for values in descriptions:
        if len(values) > 3:
            raise ValueError(f"{mutation_id} has more than three level messages")

        values.extend([""] * (3 - len(values)))

    trailing = body[array_matches[-1].end():]
    tile = TILE.search(trailing)

    return {
        "id": mutation_id,
        "status": "removed" if mutation_id in removed else "active",
        "weight": int(weight),
        "max_level": int(levels),
        "uses": FLAG.findall(use_flags),
        "form_based": form_based == "true",
        "short_description": names[0],
        "have": descriptions[0],
        "gain": descriptions[1],
        "lose": descriptions[2],
        "tile_id": tile.group(1) if tile else None,
        "source_line": line,
    }


def definitions(source_root):
    table = (source_root / "mutation-data.h").read_text()
    removed = removed_ids((source_root / "mutation.cc").read_text())
    removed.update(LEGACY_SAVE_ONLY)
    values = []

    for match in ENTRY.finditer(table):
        line = table.count("\n", 0, match.start()) + 1
        block = entry_block(table, match.start())
        values.append(parse_definition(block, removed, line))

    ids = [value["id"] for value in values]

    if len(ids) != 196 or len(set(ids)) != len(ids):
        raise ValueError("pinned mutation table must contain 196 unique IDs")

    if not removed.issubset(ids):
        raise ValueError("removed mutation list contains an unknown ID")

    return values


def long_descriptions(source_root):
    source = (source_root / "dat/descript/mutations.txt").read_text()
    entries = {}

    for block in source.split("%%%%"):
        lines = block.splitlines()

        while lines and (not lines[0].strip() or
                         lines[0].lstrip().startswith("#")):
            lines.pop(0)

        if not lines:
            continue

        key = lines.pop(0).strip()

        if not lines or lines[0].strip():
            raise ValueError(f"mutation description {key} has no separator")

        lines.pop(0)
        description = "\n".join(lines).strip()

        if not description or key in entries:
            raise ValueError(f"duplicate or empty mutation description {key}")

        entries[key] = description

    if len(entries) != 170 or "horns mutation" not in entries:
        raise ValueError("pinned mutation descriptions changed")

    return entries


def conflicts(source_root):
    source = (source_root / "mutation.cc").read_text()
    begin = source.index("static const int conflict[][3]")
    end = source.index("};", begin)
    rows = CONFLICT.findall(source[begin:end])

    if len(rows) != 32:
        raise ValueError("pinned mutation conflict table must contain 32 rows")

    return rows


def mutation_enum(source_root, definitions_by_table):
    source = (source_root / "mutation-type.h").read_text()
    start = source.index("enum mutation_type")
    end = source.index("NUM_MUTATIONS,", start)
    enabled = True
    parents = []
    ids = []

    for line in source[start:end].splitlines():
        stripped = line.strip()

        if stripped.startswith("#if "):
            if stripped == "#if TAG_MAJOR_VERSION == 34":
                condition = True
            elif stripped == "#if TAG_MAJOR_VERSION > 34":
                condition = False
            else:
                raise ValueError(f"unknown mutation enum conditional {stripped}")

            parents.append(enabled)
            enabled = enabled and condition
            continue

        if stripped == "#else":
            if not parents:
                raise ValueError("mutation enum has unmatched #else")

            enabled = parents[-1] and not enabled
            continue

        if stripped == "#endif":
            if not parents:
                raise ValueError("mutation enum has unmatched #endif")

            enabled = parents.pop()
            continue

        if enabled:
            match = re.match(r"(MUT_[A-Z0-9_]+)\s*,", stripped)

            if match:
                ids.append(match.group(1))

    table_ids = {value["id"] for value in definitions_by_table}

    if parents or len(ids) != 196 or len(set(ids)) != len(ids):
        raise ValueError("pinned tag-34 mutation enum must have 196 unique IDs")

    if set(ids) != table_ids:
        raise ValueError("mutation enum and mutation table IDs disagree")

    return ids


def lua_string(value):
    value = value.replace("\\", "\\\\")
    value = value.replace('"', '\\"')
    value = value.replace("\n", "\\n")
    value = value.replace("\r", "\\r")
    value = value.replace("\t", "\\t")

    return '"' + value + '"'


def string_lines(name, value, indent="    "):
    prefix = indent + (name + " = " if name else "")
    literal = lua_string(value)

    if len(prefix + literal + ",") <= 100:
        return [prefix + literal + ","]

    chunks = []
    current = ""

    for char in value:
        candidate = current + char

        if current and len("        " + lua_string(candidate) + " ..") > 100:
            break_at = max(current.rfind(" "), current.rfind("\n"))

            if break_at > 0:
                chunks.append(current[:break_at])
                current = current[break_at:] + char
            else:
                chunks.append(current)
                current = char
        else:
            current = candidate

    chunks.append(current)
    lines = [prefix.rstrip()]

    for chunk in chunks[:-1]:
        lines.append("        " + lua_string(chunk) + " ..")

    lines.append("        " + lua_string(chunks[-1]) + ",")

    return lines


def list_lines(name, values):
    lines = ["    " + name + " = {"]

    for value in values:
        lines.extend(string_lines("", value, indent="        "))

    lines.append("    },")

    return lines


def render(value, revision):
    lines = [
        "-- Generated from a pinned DCSS mutation table. Refresh deliberately.",
        f"-- Revision: {revision}",
        f"-- Source: crawl-ref/source/mutation-data.h:{value['source_line']}",
    ]

    if value.get("description"):
        lines.append("-- Source: crawl-ref/source/dat/descript/mutations.txt")

    lines.extend([
        "",
        'local categories = require("constants.catalog")',
        "",
        "local definition = {",
        f'    id = {lua_string(value["id"])},',
        f'    status = {lua_string(value["status"])},',
        f'    weight = {value["weight"]},',
        f'    max_level = {value["max_level"]},',
    ])
    lines.extend(list_lines("uses", value["uses"]))
    lines.append("    form_based = " +
                 ("true" if value["form_based"] else "false") + ",")
    lines.extend(string_lines("short_description", value["short_description"]))

    if value.get("description"):
        lines.extend(string_lines("description", value["description"]))

    for field in ("have", "gain", "lose"):
        lines.extend(list_lines(field, value[field]))

    if value["tile_id"]:
        lines.extend(string_lines("tile_id", value["tile_id"]))

    lines.extend([
        "}",
        "",
        "register.definition(categories.MUTATIONS, definition)",
        "",
        "return definition",
        "",
    ])

    return "\n".join(lines)


def render_conflicts(rows, revision):
    outcomes = {
        "-1": "BLOCK_UNLESS_FORCED",
        "0": "IGNORE_UNLESS_FORCED",
        "1": "TRADE_ONE",
    }
    lines = [
        "-- Generated from the pinned ordered DCSS mutation conflict table.",
        f"-- Revision: {revision}",
        "-- Source: crawl-ref/source/mutation.cc:conflict",
        "",
        'local mutations = require("ids.mutations")',
        'local outcomes = require("constants.mutation_conflict_outcomes")',
        "",
        "local conflicts = {",
    ]

    for first, second, outcome in rows:
        if outcome not in outcomes:
            raise ValueError(f"unknown mutation conflict outcome {outcome}")

        lines.extend([
            "    {",
            f"        first = mutations.{first},",
            f"        second = mutations.{second},",
            f"        outcome = outcomes.{outcomes[outcome]},",
            "    },",
        ])

    lines.extend(["}", "", "return conflicts", ""])

    return "\n".join(lines)


def render_enum(ids, revision):
    lines = [
        "-- Generated from the pinned tag-34 DCSS mutation enum.",
        f"-- Revision: {revision}",
        "-- Source: crawl-ref/source/mutation-type.h:mutation_type",
        "",
        'local mutations = require("ids.mutations")',
        "",
        "local enum = {",
    ]

    for mutation_id in ids:
        lines.append(f"    mutations.{mutation_id},")

    lines.extend(["}", "", "return enum", ""])

    return "\n".join(lines)


def refresh(source_root, revision, check):
    expected = {}
    source_definitions = definitions(source_root)
    descriptions = long_descriptions(source_root)

    for index, value in enumerate(source_definitions, 1):
        key = value["short_description"] + " mutation"
        value["description"] = descriptions.get(key)
        name = f"{index:04d}_{value['id'].lower()}.lua"
        expected[name] = render(value, revision)

    existing = {path.name for path in DESTINATION.glob("*.lua")}
    changed = []

    for name, content in expected.items():
        path = DESTINATION / name

        if not path.exists() or path.read_text() != content:
            changed.append(name)

            if not check:
                DESTINATION.mkdir(parents=True, exist_ok=True)
                path.write_text(content)

    stale = existing - set(expected)

    if not check:
        for name in stale:
            (DESTINATION / name).unlink()

    if check and (changed or stale):
        raise SystemExit(
            "mutation Lua differs: " + ", ".join(sorted(changed + list(stale)))
        )

    expected_conflicts = render_conflicts(conflicts(source_root), revision)

    if (not CONFLICT_DESTINATION.exists() or
            CONFLICT_DESTINATION.read_text() != expected_conflicts):
        if check:
            raise SystemExit("mutation conflict Lua differs")

        CONFLICT_DESTINATION.parent.mkdir(parents=True, exist_ok=True)
        CONFLICT_DESTINATION.write_text(expected_conflicts)

    expected_enum = render_enum(
        mutation_enum(source_root, source_definitions), revision
    )

    if not ENUM_DESTINATION.exists() or ENUM_DESTINATION.read_text() != expected_enum:
        if check:
            raise SystemExit("mutation enum Lua differs")

        ENUM_DESTINATION.parent.mkdir(parents=True, exist_ok=True)
        ENUM_DESTINATION.write_text(expected_enum)

    print(f"{'Checked' if check else 'Wrote'} {len(expected)} Lua mutations")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--revision", default=PINNED_REVISION)
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    actual = source_revision(arguments.source_root)

    if actual != arguments.revision:
        parser.error(f"source revision {actual} differs from {arguments.revision}")

    refresh(arguments.source_root, arguments.revision, arguments.check)


if __name__ == "__main__":
    main()
