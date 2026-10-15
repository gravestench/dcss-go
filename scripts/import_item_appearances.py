#!/usr/bin/env python3
"""Refresh the committed Lua item appearance tables from pinned DCSS."""

import argparse
import ast
import hashlib
import json
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ITEMS = ROOT / "internal/content/generated/items.json"
SOURCE_PATH = "crawl-ref/source/item-name.cc"

FUNCTIONS = {
    "wand": {
        "primary": "wand_primary_string",
        "secondary": "wand_secondary_string",
    },
    "ring": {
        "primary": "ring_primary_string",
        "secondary": "ring_secondary_string",
    },
    "amulet": {
        "primary": "amulet_primary_string",
        "secondary": "amulet_secondary_string",
    },
    "staff": {
        "primary": "staff_primary_string",
        "secondary": "staff_secondary_string",
    },
}

EXPECTED = {
    "wand": {"primary": 12, "secondary": 16},
    "ring": {"primary": 29, "secondary": 13},
    "amulet": {"primary": 29, "secondary": 13},
    "staff": {"primary": 4, "secondary": 10},
    "potion": {"colours": 22, "qualifiers": 15},
}

ARRAY = re.compile(
    r"static\s+const\s+char\s*\*\s*(?:const\s+)?\w+\[\]\s*=\s*"
    r"\{(?P<body>.*?)\};",
    re.DOTALL,
)

STRING = re.compile(r'"(?:\\.|[^"\\])*"')


def source_array(source: str, marker: str) -> list[str]:
    offset = source.find(marker)

    if offset < 0:
        raise ValueError(f"missing source appearance table {marker}")

    if marker.endswith("[]"):
        declaration = source.rfind("static const", 0, offset + 1)

        if declaration < 0:
            raise ValueError(f"missing source declaration for {marker}")

        match = ARRAY.match(source, declaration)
    else:
        match = ARRAY.search(source, offset + len(marker))

    if match is None:
        raise ValueError(f"unfamiliar source appearance table {marker}")

    body = re.sub(
        r"#if\s+TAG_MAJOR_VERSION\s*==\s*34.*?#endif",
        "",
        match.group("body"),
        flags=re.DOTALL,
    )
    values = [ast.literal_eval(token) for token in STRING.findall(body)]

    if not values:
        raise ValueError(f"empty source appearance table {marker}")

    return values


def parse_source(source: str) -> dict[str, dict[str, list[str]]]:
    tables = {}

    for category, fields in FUNCTIONS.items():
        tables[category] = {}

        for field, function in fields.items():
            marker = f"static const char* {function}("
            tables[category][field] = source_array(source, marker)

    tables["potion"] = {
        "colours": source_array(source, "potion_colours[]"),
        "qualifiers": source_array(source, "potion_qualifiers[]"),
    }

    for category, fields in EXPECTED.items():
        for field, expected in fields.items():
            actual = len(tables[category][field])

            if actual != expected:
                raise ValueError(
                    f"{category}.{field} has {actual} values, want {expected}"
                )

    return tables


def lua_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def render(source_bytes: bytes) -> str:
    source = source_bytes.decode("utf-8")
    tables = parse_source(source)
    digest = hashlib.sha256(source_bytes).hexdigest()
    lines = [
        "-- Generated from a committed DCSS import. Refresh deliberately.",
        f"-- Source: {SOURCE_PATH}",
        f"-- Source SHA-256: {digest}",
        "",
        "local appearances = {",
    ]

    for category, fields in tables.items():
        lines.append(f"    {category} = {{")

        for field, values in fields.items():
            lines.append(f"        {field} = {{")

            for value in values:
                lines.append(f"            {lua_string(value)},")

            lines.extend(["        },", ""])

        lines.extend(["    },", ""])

    lines.extend(["}", "", "return appearances", ""])

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    if args.source.name != "item-name.cc":
        parser.error("--source must name item-name.cc")

    items = json.loads(ITEMS.read_text())
    source_revision = subprocess.run(
        ["git", "-C", str(args.source.parent.parent), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()

    if source_revision != items["source_revision"]:
        parser.error("item-name.cc checkout revision does not match items")

    expected = render(args.source.read_bytes())

    if args.check:
        if not args.out.exists() or args.out.read_text() != expected:
            raise SystemExit(f"stale item appearance artifact: {args.out}")

        return

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(expected)


if __name__ == "__main__":
    main()
