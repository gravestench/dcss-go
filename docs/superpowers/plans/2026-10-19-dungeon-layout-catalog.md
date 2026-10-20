# Dungeon Layout Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task by task. The user
> requested native execution, one contiguous category commit, and immediate
> pushes to `main` for completed work.

**Goal:** Make every active source Dungeon layout selectable and executable
from committed `.des` and Lua files during entry-time generation.

**Architecture:** A source-format layout catalog parses effective `.des`
files, resolves named Lua hooks, and selects eligible IDs in stable order.
Lua layout modules carve a shared grid; one Lua stair postpass completes
missing links before the existing vault and population flow runs. Go keeps
the current Level and save responsibilities.

**Tech Stack:** Go 1.26, gopher-lua, layered `modfs`, committed `.des` and
Lua content, Akara ECS for actors and items.

**Spec:** `docs/superpowers/specs/2026-10-19-dungeon-layout-catalog-design.md`

## Global constraints

- Keep original `.des` map syntax; no inline Lua in Go or executable raw
  source script blocks. Port those scripts into documented Lua functions.
- Import all 21 Dungeon-eligible definitions, including four disabled ones.
  Normal builds use only committed content; do not retain the importer.
- A mod adds or replaces one layout through one or two files at the same
  relative paths. No hard-coded per-layout Go switch or second metadata table.
- Loading order cannot affect seeds. Sort eligible IDs before weighted draws.
- Keep Go and Lua lines at or below 120 columns; prefer 80. Comment every
  function with the reason for its behavior, and avoid crowded literals.
- Implement and test the whole Dungeon layout category before the single
  implementation commit; merge and push completed work on `main`.

## Review focus

1. A zero-weight Dungeon layout must register yet never draw: test its
   metadata and run repeated selections with only that ID available.
2. A source weight with branch clauses must resolve the Dungeon value:
   table-test `layout_basic`, `layout_rooms`, and `layout_layer_cave`.
3. A map with too few reachable floor cells must fail within the retry
   bound: test the shared stair placer with a blocked grid.
4. An arrival with `layout_*` or `nolayout_*` tags must constrain D:1
   candidates: test both positive and negative tags.
5. A sparse mod overlay or file rename must not reorder unrelated
   candidate draws: compare effective catalog choices under both VFS orders.

---

### Task 1: Commit and load the source layout catalog

**Files:** Create `internal/modfs/builtin/vaults/layout/*.des` (one file per
source `NAME`), `internal/modfs/builtin/policy/generation/vaults/weight.lua`;
modify `.../vaults/des.lua`, `.../vaults/catalog.lua`,
`.../vaults/hooks.lua`, and Lua catalog tests under
`internal/script/testdata/lua/tests/`.

**Interfaces:** `catalog.get(id)` returns a parsed layout definition with
its source tags, depth rules, and branch weight rules. `weight.for_branch`
returns a nonnegative weight for a registered branch. `register.ids` remains
the stable ID order for all selection.

- [ ] Add a failing Lua catalog test that enumerates the 21 IDs, checks 17
  positive Dungeon weights and four disabled weights, and rejects duplicate
  IDs, missing hooks, malformed depth/weight clauses, and unsupported DES.
- [ ] Run only that Lua test and confirm the missing layout family fails.
- [ ] Extract one `.des` file per source definition with its original
  directives and map rows. Convert source scripts to named hook calls and
  nearby explanatory comments. Keep temporary extraction tools outside the
  repository.
- [ ] Extend the common DES/catalog code to handle branch weight clauses,
  zero weights, and empty hook-driven layout maps without weakening the
  existing arrival and shop validation.
- [ ] Run the catalog and existing arrival/shop parser selections until
  they pass.

### Task 2: Port all active layout behavior into Lua

**Files:** Create `internal/modfs/builtin/policy/generation/layouts/<id>.lua`
for each active source layout, plus focused shared helpers in that directory;
modify `policy/generation/grid.lua` only for generic missing operations.
Add `layout_catalog_test.lua` and `layout_stairs_test.lua` under the Lua tests.

**Interfaces:** `layouts.execute(ctx, definition, input)` returns a builder,
source vault records, and authored stair cells. `layouts.stairs.complete`
adds missing up/down cells on eligible floor and verifies all exits are
reachable. Hook IDs exactly match the committed `.des` declarations.

- [ ] Add failing forced-ID tests for all 17 active Dungeon layouts at their
  minimum and maximum eligible Dungeon depths; assert 80×70 terrain, source
  feature preservation, at least three connected up/down exits, and no
  hidden basic-layout substitution.
- [ ] Add the blocked-grid, zero-weight, and hook-missing cases from Review
  Focus, then run those tests red.
- [ ] Port the source layout scripts into named local-object Lua modules,
  factoring repeated geometry and RNG operations into commented helpers.
  Keep source-specific choices in each layout file, not a giant selector.
- [ ] Implement the shared stair postpass after layout carving, then run
  all forced-ID layout tests green.

### Task 3: Use the catalog in live Dungeon generation

**Files:** Modify `policy/generation/generated.lua`,
`policy/generation/basic.lua`, layout selection Lua, and the generated game
integration tests. Fixed scenarios remain untouched.

**Interfaces:** `layouts.choose(ctx, branch_id, depth, primary_tags)` makes
one weighted choice among depth-eligible IDs. `build_floor` calls it, then
`layouts.execute`, the shared stair postpass, supplemental vault placement,
live parent pairing, and population. The Go decoder contract is unchanged.

- [ ] Add failing D:1 arrival-tag, D:2–15 weighted-layout, save/reentry,
  deterministic seed, VFS overlay, and full fifteen-floor travel tests.
- [ ] Run those focused tests red; ensure they fail for the missing layout
  behavior rather than an unrelated fixture.
- [ ] Replace the unconditional `basic.generate` call with the effective
  layout selection and execution path. Preserve first-entry RNG timing and
  the existing starting-item and vault-entity flow.
- [ ] Run focused generation, vault, stair, save, and terminal tests green.

### Task 4: Verify, document, and push the category

**Files:** Update `README.md`, `docs/modding.md`, `docs/port-inventory.md`,
and `docs/ecs-architecture-roadmap.md` for layout authoring and the new
selection behavior.

- [ ] Explain how to add or overlay one layout `.des` and hook module,
  including the shared `ctx` and builder contract.
- [ ] Remove the old unconditional basic-layout path. Run `gofmt`, Go style,
  Lua line checks, and `git diff --check`.
- [ ] Run the category's focused tests once after integration, plus one
  broad repository verification with a 20-minute bound. Diagnose only
  concrete failures; do not repeat broad checks for minor edits.
- [ ] Commit the contiguous Dungeon-layout implementation, push `origin
  main`, and confirm the visible checkout is clean and matches its remote.
