# Ordinary Branch Travel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan natively. The user
> authorized category-sized commits directly on `main` and pushes after
> each completed category. Do not split a category into tiny commits.

**Goal:** Make ordinary DCSS branch entrances lead to persistent,
source-populated branch floors with exact reciprocal return travel.

**Architecture:** Lua chooses branch entrances and owns branch-aware
generation and population. Go keeps opaque level IDs, installs floor and
parent-link patches atomically, and saves the branch schedule and levels.
Stable IDs come from the committed branch catalog, with no Go branch-ID
switch. Unsupported branches retain a visible, explained entrance.

**Tech Stack:** Go 1.25, gopher-lua, layered modfs, committed Lua/DES,
Akara ECS, Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-20-ordinary-branch-travel-design.md`

## Global constraints

- Ordinary floor ID is `branch.numeric_id * 100 + local_depth`; Dungeon
  remains 1–15 and the existing Abyss remains 1000.
- `no_x_level_travel`, invalid depth ranges, rootless entries, and depth-zero
  legacy branches are excluded from the ordinary schedule.
- Lua owns branch choices, layouts, vaults, monster selection, and text;
  Go owns grids, links, actors, transactional installation, and saves.
- Committed generated content is authoritative. Importers are temporary
  development tools outside the repository and never run at build time.
- Keep Lua functions and systems commented with the why and how. Lines
  stay at or below 120 characters, preferably 80; multiline struct values
  remain readable. Use category-sized commits and push each to `origin main`.
- The original C++ checkout is read-only source evidence. The paused C++
  refactor is untouched.

## Review focus

1. A finite entry range on Ziggurat must not put it into ordinary travel:
   test the `no_x_level_travel` exclusion in Task 2.
2. Generating Orc after Lair cannot overwrite either pending frontier:
   test two saved frontiers in Task 4.
3. An authored branch map with more than one up exit cannot invent a second
   Dungeon entrance: test the branch-entry profile in Task 3.
4. An unknown source monster or empty branch pool must fail with its branch
   and row context, never draw Dungeon monsters: test Task 1.
5. A malformed child policy cannot leave half-resolved parent links or a
   spawned actor: test rollback before population in Task 4.

---

### Task 1: Commit source branch population catalogs

**Files:** Add `POPULATIONS` to
`internal/modfs/builtin/constants/catalog.lua`; create
`internal/modfs/builtin/content/populations/branch_*.lua`; modify
`internal/modfs/builtin/policy/population/pool.lua`, `roster.lua`, and
`populate.lua`; add branch population `_test.lua` files.

**Interfaces:** Each population definition has `id`, `branch_id`, and an
ordered `rows` array of `{monster_id,min_depth,max_depth,rarity,curve}`.
`pool.at_depth(branch_id, local_depth, allowed, scenario_id)` and
`roster.allowed(scenario_id, branch_id)` consume that catalog. Fixed
fixtures keep their current pinned monsters.

- [ ] Write failing Lua tests for source row counts, representative Lair,
  Orc, Swamp, and Depths weights, duplicate rows, missing monsters, empty
  pools, and a sparse mod that adds a branch row.
- [ ] Extract all active version-34 branch tables and macro expansions
  from `mon-pick-data.h` into one commented Lua file per branch. Use
  `ids.monsters` and `constants.population_curves`; do not commit the
  temporary extraction program. Record exact source counts in tests.
- [ ] Route generated population by explicit branch ID/local depth, then
  run the Lua population suite and existing Dungeon scenario tests.
- [ ] Commit the population category and push `origin main`.

### Task 2: Schedule ordinary branch entrances once per run

**Files:** Create
`internal/modfs/builtin/policy/generation/branch_schedule.lua` and
`branch_levels.lua`; modify `generated.lua`, `scenario.lua`,
`internal/game/generation_script.go`, `game.go`, `save.go`,
`internal/save/snapshot.go`, and save restore. Add Lua and Go schedule tests.

**Interfaces:** `branch_levels.id(branch_id, local_depth)` resolves the
catalog's numeric ID. `branch_schedule.choose(ctx)` returns a saved map of
`branch_id -> {parent_id,parent_depth}` plus the selected Lair pairs.
`branch_schedule.entries(schedule, parent_branch_id, local_depth)` returns
only entries assigned to that floor. `Game.branchSchedule` owns the saved
copy; Go passes it back to Lua when a later floor is generated.

- [ ] Test stable IDs, branch depth bounds, mutually exclusive Lair pairs,
  rootless and portal exclusions, sorted discovery independence, and
  schedule save/restore with tampered-entry rejection.
- [ ] Implement Lua scheduling from effective branch definitions; add
  saved schedule to the first-floor result and snapshot. Bump save
  version to 30 and reject older generated saves with no schedule.
- [ ] Place source-labelled pending entrance links at safe parent floor
  cells selected from the generated grid, protecting them from extra vault
  placement and ordinary stair pairing. Retain unavailable entrances for
  branches whose generation prerequisites are still absent.
- [ ] Run schedule, generated-floor, and save tests; commit and push this
  world-state category.

### Task 3: Generate branch floors through the shared Lua pipeline

**Files:** Modify `policy/generation/generated.lua`,
`generated_stairs.lua`, `layouts/catalog.lua`, `layouts/stairs.lua`,
`scenario.lua`, and `policy/population/populate.lua`. Add branch floor
generation `_test.lua` files and focused Go generation tests.

**Interfaces:** `generated.next(ctx,input)` takes destination `branch_id`,
`local_depth`, `level_id`, selected parent stair, saved schedule, and prior
vault IDs. It returns the existing `{level,parent_links,entry,starting_items}`
shape. `stairs.complete(builder,profile)` accepts required up/down counts,
preserving authored exits. The same placement path handles Dungeon, Lair,
Orc, and later ordinary branches.

- [ ] Test branch-specific layout weights, depth and absolute depth,
  one return stair on branch entry, no invented downward stair at branch
  bottom, exact parent landing, and existing Dungeon behavior.
- [ ] Generalize `build_floor`, level records, and stair pairing around
  branch metadata. Use actual branch population budget and pool; never
  derive depth from the numeric level ID.
- [ ] Run Lua layout, vault, population, and stair tests together, then
  commit and push the generation category.

### Task 4: Install any scheduled floor atomically in Go

**Files:** Modify `internal/game/generate_next.go`,
`populate_script.go`, `generation_script.go`, `level.go`,
`commands.go`, and focused game tests.

**Interfaces:** `generateNextFloor(parentID int, selected StairLink)`
validates the scheduled destination branch and ID, decodes one new level,
applies parent patches, verifies reciprocal links, and returns starting
items. `validateStairLinks` permits pending links to any scheduled absent
child ID; Lua validates that those IDs are legal branch graph edges.

- [ ] Test first Lair and Orc entry, inner branch descent, exact return,
  simultaneous frontiers, actor occupancy, failed Lua output rollback, and
  no reroll on revisiting a floor.
- [ ] Remove `id + 1` assumptions from the generic Go stair validator and
  generated-floor installer. Keep fixed-scenario and Abyss links working.
- [ ] Run targeted game generation, stair, population, and save tests;
  commit and push the installation category.

### Task 5: Validate saved topology and show branch identity

**Files:** Modify `policy/save/generated_levels.lua`,
`scenario_levels.lua`, `internal/game/view.go`,
`internal/terminal/policy_render.go`, relevant Lua presentation policy,
`docs/modding.md`, and `docs/port-inventory.md`.

**Interfaces:** The Lua validator checks each level's branch/local depth,
schedule membership, pending target, and exact reciprocal links. Game views
carry branch ID and local depth; Lua presentation renders the branch label
and source entrance identity.

- [ ] Test forged branch IDs, duplicate level IDs, unscheduled entrances,
  broken reciprocal returns, missing frontiers, and unrelated fixed saves.
- [ ] Validate the branch graph set-wise instead of requiring a contiguous
  Dungeon-only prefix. Render Lair/Orc depth and entrance/return messages.
- [ ] Document ordinary branch modding and the remaining unavailable
  special branches. Run the integrated Lua rules, `go test ./...` using a
  writable `GOCACHE`, style checks, and `git diff --check` sequentially.
- [ ] Commit and push the integrated category; verify clean `main` sync.
