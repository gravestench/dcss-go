#!/usr/bin/env python3
"""Refresh committed player zap power caps from an explicit DCSS source."""

import argparse
import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAPPING = ROOT / "internal/modfs/builtin/data/player_spell_zaps.lua"
OUTPUT = ROOT / "internal/modfs/builtin/data/player_zap_caps.lua"
REVISION = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

ZAP_ID = re.compile(r'zap_id = "(ZAP_[A-Z0-9_]+)"')
ENTRY = re.compile(
    r'\{\s*(ZAP_[A-Z0-9_]+)\s*,\s*'
    r'(?:\/\/[^\n]*\n\s*)?"[^"]*"\s*,\s*(\d+)\s*,',
    re.MULTILINE,
)
HEX = re.compile(
    r'_mon_hex_zap\(\s*(ZAP_[A-Z0-9_]+)\s*,\s*'
    r'BEAM_[A-Z0-9_]+\s*(?:,\s*(\d+))?',
)


def render(source_path):
    source = source_path.read_bytes()
    lines = source.decode("utf-8")
    eligible = set(ZAP_ID.findall(MAPPING.read_text()))
    caps = {zap_id: int(value) for zap_id, value in ENTRY.findall(lines)}

    for zap_id, value in HEX.findall(lines):
        caps[zap_id] = int(value) if value else 100

    missing = eligible - caps.keys()

    if missing:
        raise ValueError("missing player zap caps: " + ", ".join(sorted(missing)))

    output = [
        "-- Generated from a committed DCSS import. Refresh deliberately.",
        f"-- Revision: {REVISION}",
        "-- Source: crawl-ref/source/zap-data.h",
        f"-- SHA-256: {hashlib.sha256(source).hexdigest()}",
        "local catalog = {",
    ]

    for zap_id in sorted(eligible):
        output.append(f"    {zap_id} = {caps[zap_id]},")

    output.extend(["}", "", "return catalog", ""])

    return "\n".join(output), len(eligible)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    output, count = render(args.source)

    if args.check:
        if OUTPUT.read_text() != output:
            raise SystemExit("player zap cap catalog is stale")
    else:
        OUTPUT.write_text(output)

    print(f"{count} player zap power caps")


if __name__ == "__main__":
    main()
