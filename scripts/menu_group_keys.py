"""Stable Lua constant names for the pinned character-menu groups."""

import re


def group_key(category: str, label: str) -> str:
    prefix = "SPECIES" if category == "species" else "JOB"
    name = re.sub(r"[^A-Z0-9]+", "_", label.upper()).strip("_")

    if not name:
        raise ValueError("menu group label is empty")

    return f"{prefix}_{name}"
