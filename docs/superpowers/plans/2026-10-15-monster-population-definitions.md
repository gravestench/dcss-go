# Monster-owned Dungeon Population Implementation Plan

**Goal:** Move all 125 pinned Dungeon population rows into their monster
definition files without changing spawn selection or mod discovery.

**Design:** `docs/superpowers/specs/2026-10-15-monster-population-definitions-design.md`

**Method:** One coherent content/selection category, one commit after
integrated verification. Preserve `dcrawl-save.json`.

## Task 1: Pin current pool behavior

- [x] Add `_test.lua` cases for D:1 and D:2 source picker rows, order,
  weights, and duplicate monster IDs through production `pool.at_depth`.
- [x] Add one-file mod monster coverage using its own `population` field.
- [x] Run focused tests and record the baseline.

## Task 2: Generate population in monster files

- [x] Extend `scripts/export-catalog-lua.py` to join the committed
  population artifact to monster definitions with `source_order` and
  provenance comments.
- [x] Remove the aggregate Lua output and regenerate the committed
  monster files. Keep the JSON artifact for deliberate refreshes.
- [x] Add exporter tests for row counts, duplicate rows, and missing
  monster references.

## Task 3: Consume and validate registered rows

- [x] Change `pool.at_depth` to gather source-order rows from registered
  monsters, sort them, then append mod rows in the existing order.
- [x] Change `content.validation` to validate source rows from definitions,
  require unique positive source orders, and keep mod row validation.
- [x] Remove the runtime aggregate Lua dependency. Test override,
  malformed rows, and deterministic fixed-seed population.

## Task 4: Review and integrate

- [x] Update modding docs and the port inventory with the one-file rule.
- [x] Run focused Lua and game tests, exporter check, vet, build, style,
  and one broad Go suite at the category boundary.
- [x] Review the diff, commit once, and fast-forward local `main`.
