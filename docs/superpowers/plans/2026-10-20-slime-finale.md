# Slime Finale and Slimy Rune Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native implementation. Steps use checkbox
> syntax for tracking. The user authorized contiguous commits on `main`
> and pushes to `origin/main`.

**Goal:** Make Slime:5 an authored Royal Jelly encounter with a collectible
slimy rune and a saved, death-triggered seal.

**Architecture:** Keep the source map in DES. Lua owns the source-position
hook, ECS seal cells, Royal Jelly death reaction, and save invariants.
Existing Go grid, ECS, and save codecs remain generic.

**Tech Stack:** Go, gopher-lua, layered modfs, Akara ECS, DES.

**Spec:** `docs/superpowers/specs/2026-10-20-slime-finale-design.md`

## Global constraints

- Preserve source MAP rows byte for byte; keep all gameplay Lua in files.
- Keep policy functions focused, commented, and at most 120 columns.
- Use stable named IDs from shared Lua modules instead of duplicated strings.
- Build and play without the C++ tree or an importer.
- Verify the integrated category before one implementation commit and push.

## Review focus

1. A Slime:5 map must not be a generic layout or a partial `slime_pit`.
2. The Royal Jelly source origin, not its current location, owns seal release.
3. An unrelated or banished Royal Jelly cannot open the inner chamber.
4. Saved released cells and terrain must agree in both directions.
5. The one historical rune record must survive pickup and restore.

---

### Task 1: Authored end floor

**Files:** `vaults/layout/slime_pit.des`,
`policy/generation/layouts/slime_pit.lua`, branch catalog, DES tests.

- [x] Import the complete map and audit every MAP row.
- [x] Replace source scripts with a named hook and typed markers.
- [x] Require the authored end layout and one slimy rune record.
- [x] Exercise layout selection, terrain, source records, and bad saves.

### Task 2: Live seal and death reaction

**Files:** `schemas/world_slime_seal.lua`, `policy/population/slime_seal.lua`,
`policy/combat/monster_death/slime_pit.lua`, `policy/save/slime_seal.lua`,
`systems/actor_death.lua`, focused Lua tests.

- [x] Materialize one saved seal cell for each final source `n` marker.
- [x] Release only for the matching authored Royal Jelly death.
- [x] Validate source linkage, uniqueness, state, and saved terrain.
- [x] Test pre- and post-release behavior and forged save states.

### Task 3: Integrated Slime travel

**Files:** `internal/game/slime_end_test.go`, `docs/modding.md`,
`docs/port-inventory.md`.

- [x] Travel from the scheduled Lair entry through Slime:5 and return.
- [x] Collect the rune after the seal opens; save and restore both states.
- [x] Test an effective same-path mod override.
- [x] Run focused Lua/Go tests, source MAP audit, diff and style checks.
- [x] Commit the category and push `origin/main`.
