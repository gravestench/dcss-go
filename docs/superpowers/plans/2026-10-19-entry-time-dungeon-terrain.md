# Entry-time Dungeon Terrain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate D:2–15 terrain, vaults, and population on first stair entry while preserving reciprocal links and deterministic save continuation.

**Architecture:** Lua produces one floor and a small patch for its already-live parent. Go validates and applies the level and link transaction before the player stair system runs. A pending stair is explicit in level state and saves; the existing Lua population policy materializes the new floor using the actual arrival cell.

**Tech Stack:** Go, Akara ECS, embedded Lua, `.des` vaults, versioned JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-19-entry-time-dungeon-terrain-design.md`

## Global Constraints

- Only D:1 and the Abyss exist at generated game startup; fixed scenarios retain their full levels.
- D:2–15 terrain, vaults, monster budgets, and population use the live RNG state on first entry.
- Every generated stair eventually has an exact reciprocal endpoint; source-vault extra stairs are included.
- D:1 curing and D:2 heal/haste appear once, after the appropriate floor's monster inventory draws.
- Lua owns layout, vault, item, and population policy. Go owns grid, occupancy, links, and save encoding.
- Keep handwritten Go and Lua at most 120 columns, with comments explaining ownership and unusual order.
- One implementation commit covers this contiguous terrain-generation category, then merge and push `main`.

## Review Focus

- Saving just before the first D:2 descent must preserve pending links and RNG for the same resulting D:2.
- A source vault with extra down stairs must gain child landings; extra up stairs must gain parent departures without overwriting an actor or non-floor feature.
- Invalid or unavailable stairs must not generate a floor or spend generation RNG.
- A generated prefix with a missing middle floor, a resolved link into a missing floor, or a pending link into an existing floor must fail restore.
- An existing D:2 potion or actor must not be recreated on return or after restore.

---

### Task 1: Explicit pending stair state and save validation

**Files:** `internal/game/level.go`, `internal/save/snapshot.go`, `internal/game/save.go`, `internal/game/save_restore_levels.go`, `internal/game/generation_script.go`, `internal/modfs/builtin/policy/save/generated_levels.lua`, `internal/game/stairs_test.go`, `internal/game/generated_dungeon_test.go`

**Interfaces:** `StairLink.Pending bool`, `save.StairRecord.Pending bool`, and `Level.ResolveStairLink(x, y, toX, toY int) error`. Pending has positive `ToLevelID`, zero destination coordinates, and an empty unavailable message. Resolved and unavailable states keep their current contracts. Lua save policy receives `pending` in every stair projection.

- [ ] Write tests for valid frontier pending links and all five malformed save cases in Review Focus.
- [ ] Run the focused stair and generated save tests; verify the new cases fail.
- [ ] Implement pending validation, resolution, serialization, and contiguous-prefix policy checks. Advance save format version to 22.
- [ ] Run the focused stair and generated save tests until they pass.

### Task 2: Lua floor generation and pairing

**Files:** `internal/modfs/builtin/policy/generation/generated.lua`, create `internal/modfs/builtin/policy/generation/generated_stairs.lua`, `internal/modfs/builtin/policy/generation/scenario.lua`, `internal/modfs/builtin/policy/generation/vaults/extra.lua`, `internal/script/testdata/lua/tests/generated_dungeon_test.lua`

**Interfaces:** `world.generate_scenario` returns D:1 plus Abyss for generated play. `world.generate_next_floor` accepts `depth`, `player_species_id`, `player_name`, `from_x`, `from_y`, and a parent record with `id`, `width`, `height`, `seen`, and pending down links. It returns one decoded `level`, `parent_links` (`x`, `y`, `to_x`, `to_y`, `new`), an `entry` point, and D:2 starting-item intents. Existing parent links are paired in stable coordinate order; new parent departures use connected, unoccupied floor, preferring unseen cells. The child has resolved up links and pending down links, except D:15's unavailable boundary.

- [ ] Add `_test.lua` cases for the D:1-only result, ordinary stair pairing, extra parent down and child up exits, and no parent-cell overwrite.
- [ ] Run the Lua generation tests to confirm the new contract fails.
- [ ] Extract stair pairing from the whole-Dungeon loop, retain existing vault eligibility, and register the next-floor policy. Decode its `.des` terrain through the same feature owner used at startup.
- [ ] Run the Lua generation tests and source-vault generation tests until they pass.

### Task 3: Go first-entry transaction and starting items

**Files:** `internal/game/generation_script.go`, `internal/game/populate_script.go`, `internal/game/commands.go`, `internal/modfs/builtin/policy/population/populate.lua`, `internal/game/generated_dungeon_test.go`, `internal/game/populate_test.go`

**Interfaces:** `Game.ensureStairDestination(intent ecs.IntentKind, position *ecs.Position) error` replaces population-only preflight. It invokes `world.generate_next_floor` only for a pending link, validates the returned parent patch and new level, resolves all parent links, then invokes existing `populateGeneratedLevel` with the selected destination cell. The population input carries Lua-produced `starting_items` records; Go treats item IDs as opaque values.

- [ ] Rewrite generated integration tests to expect D:1 plus Abyss, then traverse D:1–15 by real stair actions. Add save-before-entry, save-after-entry, return, RNG-divergence, extra-vault-stair, and potion-once checks.
- [ ] Run those integration tests to observe missing-floor failures.
- [ ] Implement the one-level materializer and stair preflight. Change Lua population to place only the passed floor's starting items after monster inventory.
- [ ] Run the generated, population, vault, stair, save, and terminal-focused tests until they pass.

### Task 4: Reconcile remaining callers and verify the slice

**Files:** generated-level assumptions in `internal/game/*_test.go`, `internal/terminal/*_test.go`, `docs/port-inventory.md`, `docs/ecs-architecture-roadmap.md`

**Interfaces:** Tests that need depth-specific content must enter that depth. Unrelated rule tests should use the fixed scenario when possible. Documentation describes entry-time terrain and the pending-link save contract.

- [ ] Update tests that depended on fifteen eager floor grids while preserving their gameplay assertions.
- [ ] Run `gofmt` on changed Go files, `sh scripts/check-go-style.sh`, Lua line checks, and `git diff --check`.
- [ ] Run the focused suites from Task 3, then one broad `go test ./... -count=1 -p 2 -timeout 20m` after the slice is integrated. Diagnose only concrete failures rather than repeating the broad run blindly.
- [ ] Commit the contiguous slice, fast-forward `main`, and push `origin main`.
