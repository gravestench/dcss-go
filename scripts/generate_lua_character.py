#!/usr/bin/env python3
"""Refresh committed Lua species and jobs from pinned JSON import artifacts.

Run deliberately from the Go repository root after an upstream content import.
Normal builds and game startup read the committed Lua files directly.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "internal/content/generated"
DESTINATION = ROOT / "internal/modfs/builtin/content"
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for",
    "function", "if", "in", "local", "nil", "not", "or", "repeat",
    "return", "then", "true", "until", "while",
}


def quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def key_text(key: str) -> str:
    if IDENTIFIER.fullmatch(key) and key not in LUA_KEYWORDS:
        return key

    return f"[{quote(key)}]"


def scalar(value: object) -> str:
    if value is None:
        return "mod.null"

    if value is True:
        return "true"

    if value is False:
        return "false"

    if isinstance(value, str):
        return quote(value)

    if isinstance(value, (int, float)):
        return repr(value)

    raise TypeError(f"unsupported scalar {type(value).__name__}")


def table_lines(value: object, depth: int) -> list[str]:
    indent = "    " * depth

    if not isinstance(value, (dict, list)):
        return [indent + scalar(value)]

    if not value:
        return [indent + "{}"]

    lines = [indent + "{"]

    if isinstance(value, dict):
        entries = [(key_text(key), item) for key, item in value.items()]
    else:
        entries = [("", item) for item in value]

    for key, item in entries:
        prefix = "    " * (depth + 1)

        if key:
            prefix += key + " = "

        rendered = table_lines(item, depth + 1)

        if len(rendered) == 1:
            lines.append(prefix + rendered[0].lstrip() + ",")
            continue

        lines.append(prefix + "{")
        lines.extend(rendered[1:-1])
        lines.append("    " * (depth + 1) + "},")

    lines.append(indent + "}")

    return lines


def module_text(kind: str, revision: str, row: dict[str, object]) -> str:
    source = row["source_path"]
    header = [
        "-- Generated from the pinned DCSS import. Refresh deliberately.",
        f"-- Revision: {revision}",
        f"-- Source: {source}",
        "",
    ]
    lines = table_lines(row, 0)
    lines[0] = f"register.{kind}" + lines[0]

    return "\n".join(header + lines) + "\n"


def generated_files() -> dict[Path, str]:
    output: dict[Path, str] = {}

    for category, row_key, singular in (
        ("species", "species", "species"),
        ("jobs", "jobs", "job"),
    ):
        artifact = json.loads((SOURCE / f"{category}.json").read_text())
        revision = artifact["source_revision"]

        for row in artifact[row_key]:
            name = row["id"].lower() + ".lua"
            path = DESTINATION / category / name
            output[path] = module_text(singular, revision, row)

    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    files = generated_files()
    mismatch = []

    for path, expected in files.items():
        if args.check:
            if not path.exists() or path.read_text() != expected:
                mismatch.append(path.relative_to(ROOT))
            continue

        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(expected)

    if mismatch:
        names = "\n".join(str(path) for path in mismatch)
        raise SystemExit(f"Lua character catalog is stale:\n{names}")

    print(f"{'Checked' if args.check else 'Generated'} {len(files)} Lua definitions")


if __name__ == "__main__":
    main()
