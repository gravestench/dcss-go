# Remaining Lair Entrances Implementation Plan

**Goal:** Port every source Swamp and Shoals Lair entrance in one category.

**Spec:** `docs/superpowers/specs/2026-10-21-remaining-lair-entrances-design.md`

**Architecture:** Separate source DES files join the existing effective
catalog. `branch_entry.lua` selects their keyed gates; fog marker behavior
uses the existing Lua ECS system.

## Tasks

- [x] Add a failing Lua catalog test for ten Swamp and eight Shoals entries,
  weighted candidates, one keyed gate per map, and source fog records.
- [x] Commit the eighteen source DES definitions, preserving MAP rows and
  directive order except for the named Shoals validation hook. Compare
  them to the pinned source with a one-off audit.
- [x] Add family, tag, and feature constants and declare both branch entry
  families in `branch_entry.lua`.
- [x] Exercise scheduled Swamp and Shoals keyed gates, saved selection,
  reciprocal travel, and fog ECS state in Go integration tests.
- [x] Exercise a sparse mod-added gate in each family through the effective
  catalog without changing the bundled definitions.
- [x] Update the modding guide and port inventory for both families.
- [x] Run focused tests, compile, source audit, and changed-file style checks;
  review the whole category, commit once on `main`, and push.
