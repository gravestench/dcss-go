#!/usr/bin/env python3
"""Refresh committed wand spell links from a pinned DCSS spl-book.cc file."""

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "internal/content/generated"
SOURCE_PATH = "crawl-ref/source/spl-book.cc"
TABLE = re.compile(
    r"static\s+const\s+map<\s*wand_type\s*,\s*spell_type\s*>"
    r"\s+_wand_spells\s*=\s*\{(?P<body>.*?)^\s*\};",
    re.MULTILINE | re.DOTALL,
)
ROW = re.compile(
    r"\{\s*(WAND_[A-Z0-9_]+)\s*,\s*(SPELL_[A-Z0-9_]+)\s*\},"
)


def parse_wand_table(source: str) -> list[dict[str, object]]:
    match = TABLE.search(source)

    if match is None:
        raise ValueError("missing or unfamiliar _wand_spells table")

    links = []
    seen = set()
    first_line = source[: match.start("body")].count("\n") + 1

    for index, line in enumerate(match.group("body").splitlines()):
        if not line.strip():
            continue

        row = ROW.fullmatch(line.strip())

        if row is None:
            raise ValueError(f"unfamiliar wand row at line {first_line + index}")

        wand_id, spell_id = row.groups()

        if wand_id in seen:
            raise ValueError(f"duplicate {wand_id} in _wand_spells")

        seen.add(wand_id)
        links.append({
            "wand_id": wand_id,
            "spell_id": spell_id,
            "source_line": first_line + index,
        })

    if not links:
        raise ValueError("_wand_spells has no rows")

    return links


def validate_links(
    links: list[dict[str, object]],
    items_artifact: dict[str, object],
    spells_artifact: dict[str, object],
) -> None:
    if items_artifact["source_revision"] != spells_artifact["source_revision"]:
        raise ValueError("item and spell source revisions differ")

    active_wands = {
        item["id"]
        for item in items_artifact["items"]
        if item["class"] == "OBJ_WANDS" and
        not item.get("explicitly_removed", False)
    }
    active_spells = {
        spell["id"]
        for spell in spells_artifact["spells"]
        if spell["status"] == "defined"
    }
    linked_wands = {link["wand_id"] for link in links}

    if len(linked_wands) != len(links):
        raise ValueError("wand links contain a duplicate wand ID")

    if linked_wands != active_wands:
        missing = sorted(active_wands - linked_wands)
        extra = sorted(linked_wands - active_wands)

        raise ValueError(f"wand links differ from active items: missing={missing}, extra={extra}")

    for link in links:
        if link["spell_id"] not in active_spells:
            raise ValueError(
                f"{link['wand_id']} refers to unknown spell {link['spell_id']}"
            )


def render_artifact(source_bytes: bytes) -> str:
    items = json.loads((GENERATED / "items.json").read_text())
    spells = json.loads((GENERATED / "spells.json").read_text())
    links = parse_wand_table(source_bytes.decode("utf-8"))
    validate_links(links, items, spells)

    artifact = {
        "schema_version": 1,
        "source_revision": items["source_revision"],
        "source_path": SOURCE_PATH,
        "source_sha256": hashlib.sha256(source_bytes).hexdigest(),
        "links": links,
    }

    return json.dumps(artifact, indent=2, ensure_ascii=False) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    if args.source.name != "spl-book.cc":
        parser.error("--source must name spl-book.cc")

    item_artifact = json.loads((GENERATED / "items.json").read_text())
    source_revision = subprocess.run(
        ["git", "-C", str(args.source.parent.parent), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()

    if source_revision != item_artifact["source_revision"]:
        parser.error(
            "spl-book.cc checkout revision does not match the item artifact"
        )

    expected = render_artifact(args.source.read_bytes())

    if args.check:
        if not args.out.exists() or args.out.read_text() != expected:
            raise SystemExit(f"stale wand spell artifact: {args.out}")

        return

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(expected)


if __name__ == "__main__":
    main()
