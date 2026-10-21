# Slime Entrance and Ordinary Vault Family Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native implementation. Steps use checkbox
> syntax. The user authorized contiguous commits and pushes on `main`.

**Goal:** Port every non-finale source Slime vault and make authored Lair
entrances live.

**Architecture:** Source DES files are authoritative. The shared branch
entry selector places Temple or Slime entry maps; ordinary Slime maps use
the existing depth-qualified extra-vault path.

**Tech Stack:** Go, Lua, DES, layered modfs, Akara ECS.

**Spec:** `docs/superpowers/specs/2026-10-20-slime-vault-family-design.md`

## Global constraints

- Keep all 28 MAPs and gameplay directives byte-for-byte from source.
- Keep production Lua in named files, with comments explaining why and how.
- Use stable IDs and deterministic sorted effective-file selection.
- Add no C++ runtime dependency or checked-in importer.
- Verify the integrated category, then commit once and push `main`.

## Review focus

1. A source `slime_entry` map cannot appear as an ordinary extra vault.
2. A Slime branch stair must use the placed map's own `O` cell.
3. The effective mod catalog, not a fixed list, supplies candidates.
4. Failure to fit one entry must not hide another viable entry.
5. Slime:5 must remain reserved for `slime_pit`.

### Task 1: Source DES family

- [x] Commit ten entry and eighteen ordinary definitions individually.
- [x] Audit each MAP and directive against the pinned source.
- [x] Add branch-family regular-vault selection for oriented maps.
- [x] Test effective catalog loading and Slime depth eligibility.

### Task 2: Scheduled entry

- [x] Consolidate Temple and Slime entry placement in one owner.
- [x] Select effective `slime_entry` files by source weight and stable ID.
- [x] Link the map's own keyed entrance to Slime:1 and save its history.
- [x] Keep the source single-stair fallback and handle occupied landings.
- [x] Test live travel, restore, fit fallback, and sparse mod addition.

### Task 3: Integrated verification

- [x] Run focused Lua and Go tests, map audit, compile and style checks.
- [x] Update the modding guide and port inventory.
- [x] Commit the complete category and push `origin/main`.
