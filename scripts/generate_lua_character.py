#!/usr/bin/env python3
"""Refresh committed Lua species and jobs from pinned JSON import artifacts.

Run deliberately from the Go repository root after an upstream content import.
Normal builds and game startup read the committed Lua files directly.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path

from menu_group_keys import group_key

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "internal/content/generated"
DESTINATION = ROOT / "internal/modfs/builtin/content"
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for",
    "function", "if", "in", "local", "nil", "not", "or", "repeat",
    "return", "then", "true", "until", "while",
}
PROVENANCE_FIELDS = frozenset({"source_path"})


@dataclass(frozen=True)
class LuaReference:
    module: str
    name: str


def quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def key_text(key: str) -> str:
    if IDENTIFIER.fullmatch(key) and key not in LUA_KEYWORDS:
        return key

    return f"[{quote(key)}]"


def scalar(value: object) -> str:
    if isinstance(value, LuaReference):
        if not IDENTIFIER.fullmatch(value.name):
            raise ValueError(f"invalid Lua reference {value.name}")

        return f"{value.module}.{value.name}"

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
        entries = [
            (key_text(key), item)
            for key, item in value.items()
            if key not in PROVENANCE_FIELDS
        ]
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


def description_lines(value: str) -> list[str]:
    first = "    description = " + quote(value) + ","

    if len(first) <= 80:
        return [first]

    chunks = []
    remaining = value

    while len(remaining) > 60:
        end = remaining.rfind(" ", 0, 61)

        if end < 1:
            end = 60
        else:
            end += 1

        chunks.append(remaining[:end])
        remaining = remaining[end:]

    chunks.append(remaining)
    output = []

    for index, chunk in enumerate(chunks):
        prefix = "    description = " if index == 0 else "        "
        suffix = "," if index == len(chunks) - 1 else " .."
        output.append(prefix + quote(chunk) + suffix)

    return output


def module_text(kind: str, revision: str, row: dict[str, object]) -> str:
    source = row["source_path"]
    grants = row.get("starting_grants") if kind == "jobs" else None

    if isinstance(grants, list):
        row = dict(row)
        row["starting_grants"] = [
            {
                **grant,
                "kind_id": LuaReference("item_ids", grant["kind_id"]),
            }
            for grant in grants
        ]

    header = [
        "-- Generated from the pinned DCSS import. Refresh deliberately.",
        f"-- Revision: {revision}",
        f"-- Source: {source}",
    ]

    if kind == "jobs":
        header.append(
            "-- Starting grants: internal/content/generated/starting-gear.json"
        )

    header.extend(["", 'local categories = require("constants.catalog")'])

    if grants:
        header.append('local item_ids = require("ids.items")')

    if isinstance(row.get("difficulty"), LuaReference) or \
            isinstance(row.get("menu_group"), LuaReference):
        header.append('local groups = require("constants.menu_groups")')

    header.append("")
    lines = table_lines(row, 0)
    lines[0] = "local definition = " + lines[0]

    if kind == "jobs" and row.get("menu_group"):
        for index, line in enumerate(lines):
            if line.startswith("    menu_group = "):
                lines.insert(index, "    -- Source: crawl-ref/source/newgame.cc")
                break

    if row.get("description"):
        for index, line in enumerate(lines):
            if line.startswith("    description = "):
                source_kind = "species" if kind == "species" else "backgrounds"
                lines[index:index + 1] = [
                    "    -- Source: crawl-ref/source/dat/descript/" +
                    source_kind + ".txt",
                    *description_lines(row["description"]),
                ]
                break

    footer = [
        "",
        f"register.definition(categories.{kind.upper()}, definition)",
        "",
        "return definition",
    ]

    return "\n".join(header + lines + footer) + "\n"


def merge_job_grants(
    jobs_artifact: dict[str, object],
    gear_artifact: dict[str, object],
) -> list[dict[str, object]]:
    if jobs_artifact["source_revision"] != gear_artifact["source_revision"]:
        raise ValueError("job and starting-gear revisions differ")

    jobs = jobs_artifact["jobs"]
    job_ids = {job["id"] for job in jobs}
    gear_by_id = {}

    for row in gear_artifact["jobs"]:
        job_id = row["job_id"]

        if job_id not in job_ids:
            raise ValueError(f"unknown starting-gear job {job_id}")

        if job_id in gear_by_id:
            raise ValueError(f"duplicate starting-gear job {job_id}")

        gear_by_id[job_id] = row["grants"]

    merged = []

    for job in jobs:
        job_id = job["id"]

        if job_id not in gear_by_id:
            if job["selectable"]:
                raise ValueError(f"selectable job {job_id} has no starting gear")

            grants = []
        else:
            grants = gear_by_id[job_id]

        definition = dict(job)

        if grants is None:
            definition["starting_grants"] = None
        else:
            definition["starting_grants"] = [
                {key: value for key, value in grant.items() if key != "raw"}
                for grant in grants
            ]

        merged.append(definition)

    return merged


def merge_presentation(
    category: str,
    artifact: dict[str, object],
    presentation: dict[str, object],
) -> list[dict[str, object]]:
    if artifact["source_revision"] != presentation["source_revision"]:
        raise ValueError(f"{category} and presentation revisions differ")

    rows = [dict(row) for row in artifact[category]]
    by_id = {row["id"]: row for row in rows}

    if len(by_id) != len(rows):
        raise ValueError(f"duplicate {category} definition ID")

    menu_kind = "species" if category == "species" else "job"
    groups = presentation[f"{menu_kind}_groups"]
    descriptions = presentation[f"{menu_kind}_descriptions"]
    seen = set()

    for group in groups:
        label = group["label"]
        key = group_key(category, label)

        for order, identifier in enumerate(group["ids"], start=1):
            if identifier in seen:
                raise ValueError(f"duplicate {category} menu ID {identifier}")

            row = by_id.get(identifier)

            if row is None or not row["selectable"]:
                raise ValueError(f"unknown selectable {category} {identifier}")

            description = descriptions.get(identifier)

            if not isinstance(description, str) or not description:
                raise ValueError(f"missing {category} description {identifier}")

            row["description"] = description

            if category == "species":
                if row.get("difficulty") != label:
                    raise ValueError(f"species group differs for {identifier}")

                row["difficulty"] = LuaReference("groups", key)
            else:
                row["menu_group"] = LuaReference("groups", key)
                row["menu_order"] = order

            seen.add(identifier)

    for row in rows:
        if row["selectable"] and row["id"] not in seen:
            raise ValueError(f"missing {category} menu entry {row['id']}")

    if set(descriptions) != seen:
        raise ValueError(f"{category} descriptions differ from menu IDs")

    if category == "species":
        for group in groups:
            actual = sorted(group["ids"],
                            key=lambda identifier: by_id[identifier][
                                "difficulty_priority"],
                            reverse=True)

            if actual != group["ids"]:
                raise ValueError(f"species priority differs for {group['label']}")

    return rows


def generated_files() -> dict[Path, str]:
    output: dict[Path, str] = {}
    presentation = json.loads((SOURCE / "presentation.json").read_text())

    for category, row_key, singular in (
        ("species", "species", "species"),
        ("jobs", "jobs", "jobs"),
    ):
        artifact = json.loads((SOURCE / f"{category}.json").read_text())
        revision = artifact["source_revision"]
        rows = artifact[row_key]

        if category == "jobs":
            gear_artifact = json.loads(
                (SOURCE / "starting-gear.json").read_text()
            )
            rows = merge_job_grants(artifact, gear_artifact)

        rows = merge_presentation(
            category,
            {"source_revision": revision, category: rows},
            presentation,
        )

        for row in rows:
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
