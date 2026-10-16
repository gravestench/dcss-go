# Monster Gear Ownership Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan task by task. Keep the result in one category commit.

**Goal:** Put every imported monster weapon spec in its monster definition
and move active gear behavior into discoverable Lua handlers.

**Architecture:** The offline exporter joins committed gear and monster
artifacts. Monster definitions own optional primary and secondary specs;
one Lua registry dispatches the two active handlers without an ID switch.
The shared gear module retains only reusable draws and quality rules.

**Tech Stack:** Python exporter, embedded Lua mod tree, Go/Akara runtime.

**Spec:** `docs/superpowers/specs/2026-10-15-monster-gear-ownership-design.md`

## Global Constraints

- Commit generated Lua; do not require source C++ or run importers at launch.
- Use one source-backed definition file per monster and Lua `_test.lua` tests.
- Keep lines at 120 characters or less, with 80 preferred; expand struct tables.
- Use named imports for item, brand, monster, and sentinel IDs.
- Preserve `dcrawl-save.json` untouched and make one commit for this category.

## Review Focus

- Duplicate primary or secondary rows: exporter rejects the owner ID.
- Unknown or removed weapon IDs: exporter and boot validation identify the
  monster file; a sentinel remains a named non-item value.
- Null versus empty brand lists: preserve source semantics and draw counts.
- Layered same-path override: effective definition and ruleset hash change.
- Active Goblin/Kobold seed sequence: compare fixed loadouts and save restore.

## Task 1: Source join and generated definitions

**Files:** `scripts/export-catalog-lua.py`,
`scripts/test_export_catalog_lua.py`,
`internal/modfs/builtin/constants/monster_gear_sentinels.lua`,
`internal/modfs/builtin/content/monsters/*.lua`.

**Interface:** `enrich_monster_definitions(monsters_artifact,
population_artifact, gear_artifact, items_artifact)` returns the complete
definition list.
Each owner may have `weapon_gear.primary` and `weapon_gear.secondary`.

- [x] Write exporter tests for 162 primary and 16 secondary owners, exact
  source values, revision mismatch, duplicate slot, missing owner, invalid
  item ID, and sentinel rendering.
- [x] Join all gear rows during deliberate export, strip source line fields
  from runtime data, and emit nearby provenance comments and imported IDs.
- [x] Remove the shared `monster-weapons` Lua export and stale file.
- [x] Run exporter tests and `--check` after generation.

## Task 2: Effective Lua validation and overlays

**Files:** `internal/modfs/builtin/content/validation.lua`,
`internal/script/testdata/lua/tests/monster_gear_content_test.lua`,
`internal/script/monster_gear_catalog_test.go`.

**Interface:** Boot validates optional `weapon_gear` specs in registered
monster definitions. The Go parity test compares effective Lua gear to the
committed import artifact, including all primary and secondary values.

- [x] Add Lua tests for owned specs, item/brand references, absent gear, and
  malformed mod values using production catalog access.
- [x] Validate weights, plus ranges, odds, good chance, item class, brands,
  and source sentinels at boot with the owning content path.
- [x] Add Go source-parity and same-path override/ruleset-hash tests.

## Task 3: Focused active handlers

**Files:** `internal/modfs/builtin/policy/population/gear.lua`,
`internal/modfs/builtin/policy/population/gear/registry.lua`,
`internal/modfs/builtin/policy/population/gear/handlers/goblin.lua`,
`internal/modfs/builtin/policy/population/gear/handlers/kobold.lua`,
`internal/script/testdata/lua/tests/monster_gear_handlers_test.lua`.

**Interface:** `registry.register(monster_id, handler)` and
`registry.loadout(ctx, monster_id, depth)` dispatch handlers; unregistered
monsters return nil. The common gear module exposes weighted draw and
quality helpers, and `gear.loadout` delegates to the registry.

- [x] Test duplicate handler registration, unhandled monsters, and the
  owned Goblin spec lookup before changing behavior.
- [x] Move Goblin and Kobold functions into separate auto-discovered Lua
  handler files. Preserve RNG draws, sling alternate, ammunition, and
  weapon quality; remove the ID switch and raw repeated ID strings.
- [x] Run fixed-seed gear, inventory save/restore, Lua, and script tests.

## Task 4: Verify and integrate

**Files:** `docs/modding.md`, `docs/ecs-architecture-roadmap.md`,
`docs/port-inventory.md`.

- [x] Document the one-file monster gear contract and handler extension
  point, including the current gameplay coverage limit.
- [x] Run exporter checks, Python tests, script/game gear tests, vet, build,
  style and diff checks. Use a broad suite at the category boundary; report
  any two-second Lua callback deadline failures with isolated rerun evidence.
- [x] Review all 178 source rows, make one category commit, fast-forward
  local main, and return to `codex/lua-player-magic`.
