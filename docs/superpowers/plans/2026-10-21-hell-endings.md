# Hell Seventh-Floor Endings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all four Hell seventh floors source-shaped, playable, persistent, and able to award their guarded runes.

**Architecture:** Keep each pinned `.des` MAP authoritative and move its inline Lua to a named module at the same operation position. Branch metadata names one mandatory primary end-map family at depth seven; the existing weighted primary selector, DES fitter, population pipeline, and portal transaction build and save the floor. Lua owns the branch-specific effects, while Go keeps only generic level staging and save storage.

**Tech Stack:** Go, Akara ECS, Gopher-Lua, committed DES maps, layered mod VFS.

**Spec:** `docs/superpowers/specs/2026-10-21-hell-branches-design.md`

## Global Constraints

- Work on `main` in `/Users/dylanknuth/src/dcrawl-go`; commit and push one contiguous ending category.
- Runtime builds use committed content only; the pinned C++ source is a development reference.
- Preserve source MAP geometry and the source order of scripted directives.
- Lua owns game rules and effects; Go exposes only reusable kernel services.
- Keep named Lua functions commented with why and how; prefer 80-character lines and never exceed 120.
- Reuse existing item, monster, rune, branch, and component IDs at their use sites.

## Review Focus

- A missing required primary map must reject seventh-floor generation and roll back the travel command; Task 2 tests this.
- A selected source end map must fit 80×70 with its helper children, including the north-oriented Dis castle; Task 2 tests this.
- Each selected end must materialize exactly its branch rune and boss without a duplicate from a helper; Task 3 tests this.
- A saved seventh floor must restore its selected map, boss, rune state, and return path; Task 3 tests this.
- A same-path mod replacement with a missing hook must fail during catalog validation, before a map is selected; Task 1 tests this.

---

### Task 1: Port all four end-map families

**Files:**
- Create: `internal/modfs/builtin/vaults/{dis_end,geh_end,coc_end,tar_end}/*.des`
- Create: `internal/modfs/builtin/policy/generation/vaults/{dis_end,geh_end,coc_end,tar_end}/*.lua`
- Modify: `internal/modfs/builtin/constants/vault_families.lua`
- Test: `internal/script/testdata/lua/tests/hell_end_vault_families_test.lua`

**Interfaces:** The primary controllers have static `PLACE: <branch>:$` derived from their source setup function, a family directory, source `WEIGHT`, and a named hook for every executable source script site. Helpers keep source tags and are selected only by their parent's `SUBVAULT` or post-place request. The expected family counts are 15 Dis, 7 Gehenna, 8 Cocytus, and 21 Tartarus definitions, including helpers.

- [ ] Write a Lua test that counts every effective definition, checks source tags and weights, validates every named hook, and checks overlay failure for a missing hook.
- [ ] Run `go test ./internal/script -run '^TestLuaRules/hell_end_vault_families_test.lua$' -count=1`; expect a missing-family failure.
- [ ] Port the source blocks after each branch file's ordinary-map section, retaining each MAP body byte for byte. Give each original Lua site a readable named handler in the same family.
- [ ] Run the focused test; expect all four counts and hook contracts to pass.

### Task 2: Select and build mandatory seventh floors

**Files:**
- Modify: `internal/modfs/builtin/content/branches/branch_{dis,gehenna,cocytus,tartarus}.lua`
- Modify: `internal/modfs/builtin/policy/generation/generated.lua`
- Modify: `internal/modfs/builtin/policy/generation/vaults/primary.lua` only if its source-weighted mandatory selector cannot admit a source north-oriented whole map
- Modify: `internal/modfs/builtin/policy/save/hell_levels.lua`
- Test: `internal/script/testdata/lua/tests/hell_end_generation_test.lua`
- Test: `internal/game/hell_travel_game_test.go`

**Interfaces:** Each branch adds one `primary_vaults` record with `depth = 7`, its end family, and no dummy option. `generated.hell` returns an 80×70 level at depth seven with no down stair, a branch escape, the chosen primary ID, and its source records. The existing `hellPortal` stages it as a persistent `HellFloorRecord`.

- [ ] Write failing Lua generation tests for every branch and several fixed seeds: mandatory source primary, 80×70 extent, no descent, reachable escape, and deterministic selection by ID.
- [ ] Write a Go travel test that descends from depth six into seven, returns directly to the Vestibule, revisits the same saved floor, and rejects malformed or missing primary maps without changing the prior save.
- [ ] Run the focused Lua and Go tests; expect depth-seven rejection with the current ordinary-floor validator.
- [ ] Connect the end families to the existing primary selector, make whole-level orientation work for the selected castle, and validate bottom-floor geometry and travel in Lua save policy.
- [ ] Rerun the focused tests; expect generation, travel, and rollback to pass.

### Task 3: Bosses, runes, and source effects

**Files:**
- Modify: end-map Lua handlers from Task 1
- Modify: `internal/modfs/builtin/policy/world/hell/travel.lua` for source arrival effects
- Modify: `internal/modfs/builtin/policy/save/hell_levels.lua` for saved boss and rune-site contracts
- Test: `internal/script/testdata/lua/tests/hell_end_generation_test.lua`
- Test: `internal/game/hell_travel_game_test.go`

**Interfaces:** Existing rune item IDs (`RUNE_DIS`, `RUNE_GEHENNA`, `RUNE_COCYTUS`, `RUNE_TARTARUS`) and boss monster IDs are imported from their catalogs. A primary end map emits one rune intent and one boss intent; the existing population pipeline instantiates them as ECS entities. The existing rune pickup state is authoritative after collection.

- [ ] Extend the tests to inspect the selected map's typed boss and rune records, live ECS entities, successful pickup, and save/restore after pickup.
- [ ] Run those tests; expect failures for any missing source hook or unsupported effect.
- [ ] Port the source `*_setup` and Serpent of Hell decisions as named Lua functions; add focused generic services only where a source effect cannot be expressed through the current API.
- [ ] Rerun the focused tests; expect one guarded rune and boss per ending, with the collected rune persisting.

### Task 4: Category verification and integration

**Files:**
- Modify: `docs/port-inventory.md`
- Modify: `docs/modding.md`

- [ ] Update the inventory with exact family counts, enabled effects, and any explicit source gap; explain end-map hooks and overlays in the modding guide.
- [ ] Run `git diff --check`, focused Lua catalog and generation tests, focused Go Hell travel/save tests, and `sh scripts/check-go-style.sh`; separate pre-existing style findings from changed-file findings.
- [ ] Run one broader Go verification if its cost is reasonable; do not repeat the full suite for minor edits.
- [ ] Commit the complete ending category once on `main` and push `origin main`.
