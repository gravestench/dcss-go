#!/usr/bin/env python3
"""Refresh the committed player spell-to-zap mapping from a DCSS source tree.

The source path is explicit. The game and ordinary builds use only the
generated Lua file, so they never depend on a C++ checkout.
"""

import argparse
import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BOOKS = ROOT / "internal/modfs/builtin/data/player_book_spells.lua"
INVOKED = ROOT / "internal/modfs/builtin/data/player_spell_ids.lua"
OUTPUT = ROOT / "internal/modfs/builtin/data/player_spell_zaps.lua"
PINNED_REVISION = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

SPELL_ID = re.compile(r"\b(SPELL_[A-Z0-9_]+)\s*=\s*true")
ZAP_PAIR = re.compile(
    r"^\s*\{\s*(SPELL_[A-Z0-9_]+)\s*,\s*(ZAP_[A-Z0-9_]+)\s*\}"
)


def player_ids():
    return set(SPELL_ID.findall(BOOKS.read_text())) | set(
        SPELL_ID.findall(INVOKED.read_text())
    )


def render(source_path, revision):
    source = source_path.read_bytes()
    lines = source.decode("utf-8").splitlines()
    mappings = {}
    eligible = player_ids()
    in_table = False

    for line_number, line in enumerate(lines, 1):
        if "_spl_zaps[]" in line:
            in_table = True
            continue

        if in_table and line.strip() == "};":
            break

        if not in_table:
            continue

        match = ZAP_PAIR.match(line)

        if not match or match.group(1) not in eligible:
            continue

        spell_id, zap_id = match.groups()
        mappings.setdefault(spell_id, []).append((zap_id, line_number))

    if not mappings:
        raise ValueError("no player spell zaps found in source table")

    result = [
        "-- Generated from a committed DCSS import. Refresh deliberately.",
        f"-- Revision: {revision}",
        "-- Source: crawl-ref/source/spl-zap.cc",
        f"-- SHA-256: {hashlib.sha256(source).hexdigest()}",
        "-- spell_to_zap uses the first listed pair for each spell.",
        "local catalog = {",
    ]

    for spell_id in sorted(mappings):
        result.append(f"    {spell_id} = {{")

        for zap_id, line_number in mappings[spell_id]:
            result.extend(
                [
                    f"        -- spl-zap.cc:{line_number}",
                    "        {",
                    f'            zap_id = "{zap_id}",',
                    "        },",
                ]
            )

        result.append("    },")

    result.extend(["}", "", "return catalog", ""])

    return "\n".join(result), len(mappings)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--revision", default=PINNED_REVISION)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    text, count = render(args.source, args.revision)

    if args.check:
        if OUTPUT.read_text() != text:
            raise SystemExit("player spell zap catalog is stale")
    else:
        OUTPUT.write_text(text)

    print(f"{count} player spell IDs have source zap mappings")


if __name__ == "__main__":
    main()
