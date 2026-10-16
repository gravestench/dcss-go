# Character Menu Content Implementation Plan

**Goal:** Make species and job files the only owners of their menu entries,
while preserving the pinned character menu and mod behavior.

**Design:** `docs/superpowers/specs/2026-10-15-character-menu-content-design.md`

**Method:** One coherent character-menu content commit after integrated
verification. Keep `dcrawl-save.json` out of the commit.

## Task 1: Pin the effective menu

- [x] Add `_test.lua` checks for group labels, representative source order,
  all group counts, exact representative descriptions, and the Modded page,
  including overflow from a full pinned group.
- [x] Add a host overlay test that changes one bundled description through
  a same-path file and checks menu projection and ruleset identity.

## Task 2: Generate owned fields and shared constants

- [x] Join the presentation artifact in `generate_lua_character.py`, checking
  revision, duplicate IDs, and complete selectable membership.
- [x] Emit description and job group/order into per-definition Lua files,
  with imported group constants and provenance comments.
- [x] Generate `constants/menu_groups.lua`, strip ID lists and descriptions
  from `data/presentation.lua`, and remove the unused item identity Lua export.
  Preserve source-derived fixed screen capacities.
- [x] Run both exporter checks and their focused Python tests.

## Task 3: Build and validate the menu from definitions

- [x] Replace the aggregate lookup in `policy/character/menu.lua` with
  registered definitions sorted by group and owner order.
- [x] Validate group, order, and description fields at boot with the owning
  file path; preserve ungrouped mod placement and nonselectable exclusion.
- [x] Run Lua, script, and terminal menu tests; update modding and roadmap
  documentation for the one-file contract.

## Task 4: Verify and integrate

- [x] Run exporter checks, relevant Go tests, vet, build, style, diff, and
  one full suite at the category boundary.
- [x] Review the diff, make one category commit, and fast-forward local main.

The full `go test ./... -p 2` run passed every package except one Wanderer
seed, where `world.populate` exceeded its two-second Lua callback deadline.
The failing seed and the complete Wanderer seed matrix passed in isolated
reruns. No game or population policy code changed in this slice.
