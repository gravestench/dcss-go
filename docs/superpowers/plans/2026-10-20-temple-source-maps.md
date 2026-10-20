# Source Temple Maps and Altars Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan natively. Work in
> category-sized commits on `main` and push each category to `origin main`,
> as the user requested. The user has approved the recommended native method
> and asked the project to proceed continuously.

**Goal:** Make all source Temple maps and entry maps executable, with one
saved source-selected Temple plan and reciprocal Dungeon travel.

**Architecture:** The effective DES files and named Lua hooks own maps and
selection. One saved Temple plan owns map and god allocation. The existing
Go floor installer owns grids, links, entities, and save transactions.

**Tech Stack:** Go 1.25, gopher-lua, layered modfs, Akara ECS, Bubble Tea.

**Spec:** `docs/superpowers/specs/2026-10-20-temple-source-maps-design.md`

## Global constraints

- Import all 90 main Temple maps and 53 entry maps from the pinned source.
  Convert legacy script lines to named Lua hooks; no raw Lua evaluator and no
  importer code in the game repository.
- Keep the `.des` map format and source directive order. The effective
  layered files are authoritative during game startup; the C++ tree is not
  a build or runtime dependency.
- Temple's source main-map selection includes a one-in-one-hundred rare draw
  and ordinary 6–21 altar-count distribution. The selected map and god
  partition are saved before the Temple floor is generated.
- Exclude Lugonu, Beogh, Jiyva, Ignis, and disabled gods from the Temple
  pool. Correct the source `temple_altar_6` typo with a nearby explanation.
- Lua owns content, policy, and text. Go owns ECS/world installation and
  save records. No new Go branch-ID switch.
- Comment each Lua function for what, why, and how. Lines stay at or below
  120 characters, preferably 80. Keep struct values multiline.

## Review focus

1. A map with multiple `temple_altars_*` tags must place exactly the chosen
   number of altars, not the highest tag value.
2. A rare map must never be drawn by an ordinary count selection.
3. A Temple entry vault with water or transparent cells must not disconnect
   Dungeon stairs or overwrite its scheduled entrance.
4. A saved god partition must reject duplicates, missing gods, and an altar
   count inconsistent with the selected map.
5. A mod that adds a Temple map or replaces its Lua hook must affect the
   effective catalog and ruleset hash without changing Go code.

---

### Task 1: Port the complete Temple map catalogs

**Files:** Create `internal/modfs/builtin/vaults/temple/*.des` for the 90
main maps and `vaults/temple_entry/*.des` for the 53 entries. Create hook
modules under `policy/generation/vaults/temple/` and
`policy/generation/vaults/temple_entry/`. Add
`policy/generation/temple/catalog.lua` and Lua catalog tests under
`internal/script/testdata/lua/tests/`.

**Interfaces:** `temple.catalog.load()` parses and validates every effective
main and entry definition. `temple.catalog.main(id)` and
`temple.catalog.entry(id)` return parsed DES definitions with source tags,
weights, rows, and operations; `main_ids()` and `entry_ids()` return sorted
IDs. The existing `vaults.hooks` dispatcher loads
same-named family hook modules; no Temple-specific hook router is needed.

- [ ] Write Lua tests for 90/53 source IDs, representative map row hashes,
  source weights and tags, hook coverage, missing hook errors, and layered
  addition/replacement.
- [ ] Run those tests to see their missing-catalog failure.
- [ ] Split and commit all source maps as effective DES files. Keep source
  scripts as comments at their original positions and invoke named Lua
  hooks there. Port each script's conditional directives through the
  production hook API; reject unknown legacy APIs with a map-specific
  diagnostic. Ensure the parser validates every definition at boot.
- [ ] Run all Temple catalog and hook tests, `git diff --check`, then commit
  the complete map-and-hook category and push `origin main`.

### Task 2: Select and save the Temple plan at new-game creation

**Files:** Create `policy/generation/temple/plan.lua`; modify
`policy/generation/generated.lua`, `internal/game/generation_script.go`,
`internal/game/save.go`, `internal/game/save_restore_levels.go`,
`internal/save/snapshot.go`, and save validators. Add Lua and Go tests.

**Interfaces:** `temple.plan.choose(ctx,catalog)` returns
`{map_id, altar_count, main_god_ids, overflow_god_ids}`.
`temple.plan.validate(plan,catalog)` verifies the saved record. Add
`TemplePlanRecord` to the Go snapshot and round-trip the Lua table through
the generation/restore boundary. This record is separate from
`BranchScheduleRecord`.

- [ ] Test seeded rare and ordinary bands, 6–21 count boundaries, exact god
  partition, modded map selection, and stable ID order.
- [ ] Implement source selection and save validation. Bump save version and
  reject old generated saves lacking the plan.
- [ ] Test new-game, save/restore, and forged map/count/god records.
- [ ] Commit the selection-and-state category and push.

### Task 3: Generate Temple and source Dungeon entrance

**Files:** Modify `policy/generation/generated.lua`,
`generated_stairs.lua`, `policy/generation/layouts/catalog.lua`,
`policy/generation/vaults/placement.lua`, `policy/population/populate.lua`,
`internal/game/generate_next.go`, and relevant level decoding. Add focused
generation and travel tests.

**Interfaces:** The Temple plan fixes the primary map for Temple:1.
`temple.catalog.entry_candidates(ctx,plan)` selects a source entry on the
scheduled Dungeon depth; the selected `O` glyph produces the pending link.
`generated.next` retains its branch-independent input/output contract.
Typed level records carry assigned god ID for every Temple altar.

- [ ] Test every main map and entry map through placement; prove variable
  altar count, authored monsters/items, source features, and entry fit.
- [ ] Place source Temple maps in the shared grid without a generic Dungeon
  layout. Suppress ambient Temple monsters and ordinary items by source
  branch policy. Preserve authored content and add one return stair only
  when needed.
- [ ] Use source entry maps for scheduled Dungeon entrances. Pair their
  `O` cells to the Temple's selected return cell, with bounded retries for
  conflicting entry positions.
- [ ] Test entry, exact return, no reroll, two nearby frontiers, and failed
  map transaction rollback. Commit the terrain-and-travel category and push.

### Task 4: Overflow identity, inspection, and integrated validation

**Files:** Modify Lua overflow selection and feature policy,
`policy/presentation/view.lua`, save validators, `docs/modding.md`, and
`docs/port-inventory.md`. Add Lua, Go game, and terminal tests.

**Interfaces:** Saved overflow god IDs remain attached to their selected
Dungeon altar records. Temple altar source records expose their assigned
god to the renderer and inspection policy. Worship and piety remain a
separate explicit domain.

- [ ] Test complete god partition, Temple inspection, overflow assignment,
  save/restore, forged altar identity, and mod replacement.
- [ ] Integrate source overflow map placement where executable; preserve
  named pending records for any still-unported altar effect. Explain those
  effects on interaction rather than silently substituting another god.
- [ ] Update modding instructions for Temple maps and named hooks. Run the
  Temple Lua suite, focused Go generation/save/UI suites, one integrated
  `go test ./...`, and `git diff --check` after the whole slice.
- [ ] Commit and push, then verify `main` is clean and synced.
