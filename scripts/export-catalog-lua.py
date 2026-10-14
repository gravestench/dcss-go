#!/usr/bin/env python3
"""Refresh committed Lua catalogs from committed DCSS import artifacts.

This is a deliberate source update tool, never part of a normal Go build.
The JSON artifacts retain their independent import validation while the Lua
copies are the data that game rules can load and override by relative path.
"""

import argparse
import json
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "internal/content/generated"
DESTINATION = ROOT / "internal/modfs/builtin/data"

CATALOGS = (
    "branches",
    "dungeon-population",
    "item-identities",
    "items",
    "monster-spellbooks",
    "monster-vocabulary",
    "monster-weapons",
    "monsters",
    "presentation",
    "spells",
    "starting-gear",
)


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
    source_lines = [entry["path"] for entry in artifact["source_files"]]
    header = [
        "-- Generated from a committed DCSS import. Refresh deliberately.",
        f"-- Revision: {revision}",
    ]

    for path in source_lines:
        header.append(f"-- Source: {path}")

    body = lines_for(artifact)
    return "\n".join(header + ["", "return " + body[0]] + body[1:]) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    stale = []

    if not args.check:
        DESTINATION.mkdir(parents=True, exist_ok=True)

    for name in CATALOGS:
        path = DESTINATION / f"{name.replace('-', '_')}.lua"
        expected = render(name)

        if args.check:
            if not path.exists() or path.read_text() != expected:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.write_text(expected)

    if stale:
        raise SystemExit("stale Lua catalogs: " + ", ".join(stale))


if __name__ == "__main__":
    main()
