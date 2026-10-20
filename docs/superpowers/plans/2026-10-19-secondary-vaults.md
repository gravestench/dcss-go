# Secondary Vaults Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan natively. The user
> authorized continued execution, category-sized commits directly on
> `main`, and pushes after each completed category.

**Goal:** Replace the shop-only secondary-vault approximation with the
complete source builder and serial vault corpus and its real selection
stages.

**Architecture:** Lua parses effective `.des` files and owns chance,
place-specific, depth-minivault, and serial-controller policy. Focused
Lua modules share a bounded placement API and save used map IDs through
the existing Go level record. Go owns terrain, typed effects, dynamic
entities, and snapshots.

**Tech Stack:** Go 1.25, gopher-lua, layered modfs, committed `.des` and
Lua, Akara ECS.

**Spec:** `docs/superpowers/specs/2026-10-19-secondary-vaults-design.md`

## Global constraints

- Commit all 600 source builder/serial definitions or document an exact
  legacy exclusion; 91 are already committed. Only executable definitions
  may enter a live selector.
- Preserve source `.des` map syntax and directive order. Source scripts
  become named functions in discoverable Lua modules. No inline Lua in Go
  and no runtime dependency on the C++ checkout.
- Keep filenames, file discovery, and provenance independent of seeded
  choice. Sort effective IDs. Source order is meaningful only within one
  map's directives and alternatives.
- Keep stateful game policy in Lua, dynamic entities in ECS, terrain in
  grids, and map-use IDs in Go level saves.
- Every Lua function explains why and how; controllers are returned local
  objects. Lines stay at or below 120 characters, preferably 80.
- Batch related content and tests; one implementation commit per
  contiguous category, then push `origin main`. Do one broad verification
  after wiring the category, not after each definition.

## Review focus

1. An omitted `DEPTH` on a helper must not make it a random Dungeon map:
   test `PLACE`/depth/tag eligibility separately in Task 2.
2. A bare `CHANCE: 1%` and a mixed branch/depth percentage line must
   resolve without an accidental 100% default: test both in Task 1.
3. A serial controller with an empty MAP still needs its post-place hook
   and saved ID: test Task 3 and Task 4.
4. A map with no cell records must still block a later unique selection:
   test Task 4 across save and restore.
5. Replacing a `.des` file in a mod layer must change its content without
   reordering unrelated draws: test Task 5.

---

### Task 1: Parse the complete source declaration language

**Files:** Modify `internal/modfs/builtin/constants/vault_directives.lua`,
`policy/generation/vaults/des.lua`, `depth.lua`, `weight.lua`,
`operations.lua`, `transforms.lua`, and focused parser tests under
`internal/script/testdata/lua/tests/`.

**Interfaces:** `des.parse(path, source)` returns `place`, ordered
`depths`, `chances`, `weights`, tags, rows, and operations. `depth.chance`
resolves bare and qualified source clauses for a branch and depth.
`weight.for_branch` resolves nonnegative source branch weights.

- [ ] Add failing `_test.lua` cases from real builder/serial declarations:
  bare chance, branch/depth chance clauses, `PLACE`, zero and branch
  weights, continued declarations, controller with empty MAP, and every
  newly encountered directive. Include path/site diagnostics.
- [ ] Run the focused parser tests red. Extend only the common grammar and
  typed operations needed by the corpus; reject unsupported statements
  instead of storing opaque text that will be lost at placement.
- [ ] Run parser tests green and the existing arrival/shop/layout suites.

### Task 2: Implement source selection stages

**Files:** Create `policy/generation/vaults/chance.lua`,
`minivault.lua`, `eligibility.lua`, `secondary.lua`; modify
`catalog.lua`, `selection.lua`, `extra.lua`, and `generated.lua`. Add
`secondary_selection_test.lua` and `secondary_placement_test.lua`.

**Interfaces:** `secondary.generate(ctx, builder, context)` returns an
ordered list of placed maps and their IDs. `eligibility` separates
chance, place, depth, and tag candidates. `extra.place` remains the
bounded, reversible geometric operation called by all stages.

- [ ] Add failing Lua tests for chance independently rolling eligible
  maps, shuffled success order, source fallback tags, `PLACE` priority,
  one ordinary depth minivault, repeated `extra` draws, a bounded
  all-extra pool, and omission of unqualified helpers from random draws.
- [ ] Run those tests red. Split the existing shop-specialized
  `extra.generate` into the four focused stages; route `serial_shops`
  through the same chance/controller path as all new serial maps.
- [ ] Run focused generation, shop, arrival, layout, stair, and scripted
  placement tests green. Keep the one-in-eight approximation until the
  full eligible corpus is ready, then remove it in Task 6.

### Task 3: Generalize controller hooks and geometric placement

**Files:** Create `policy/generation/vaults/controller.lua`; modify
`hooks.lua`, `placement.lua`, `connect.lua`, and the existing shop handler
only where it assumes a shop-only controller. Add
`secondary_controller_test.lua`.

**Interfaces:** `controller.new(ctx, builder, context, placed)` offers
bounded `roll`, `chance`, `one_in`, `random_range`, `absolute_depth`, and
`place_maps(tag, count)` methods. It loads child maps through the catalog
and shared placement path; every successful child appends to `placed`.

- [ ] Test a controller that places several tagged children, source
  post-place ordering, a missing child tag, protected-stair rejection,
  rollback after a failed origin, and malformed-hook propagation.
- [ ] Implement the shared API and use it from shop and new serial hooks.
  Put map-specific choices in their own Lua files.
- [ ] Run those focused Lua tests and the existing shop scenarios green.

### Task 4: Persist map use and enforce uniqueness

**Files:** Modify `internal/game/level.go`, generation level decoding,
`generate_next.go`, Go save/snapshot code, and
`policy/generation/generated.lua`; create
`policy/generation/vaults/used.lua`. Add Lua uniqueness tests and Go
generation/save tests.

**Interfaces:** A level stores an ordered `vault_ids` list, including
controllers and maps with no records. New-floor policy receives prior
placed IDs. `used` computes run and level name/tag sets from those IDs
and the effective catalog. Restore validates every saved map ID.

- [ ] Test same-floor `luniq_*`, cross-floor `uniq_*`, `allow_dup`,
  zero-record controllers, first-entry continuation, and missing-ID
  restore diagnostics. Run these tests red.
- [ ] Add level serialization and Lua use-state checks without using
  source paths or line ranks as identity.
- [ ] Run the focused generation and save suites green.

### Task 5: Port the entire builder and serial map categories

**Files:** Create `internal/modfs/builtin/vaults/builder/*.des` and
`vaults/serial/*.des`, one effective file per remaining `NAME`; create
matching `policy/generation/vaults/builder/*.lua` and
`vaults/serial/*.lua` for maps with scripts. Add corpus and per-family
contract tests under `internal/script/testdata/lua/tests/`.

**Interfaces:** `catalog.get(id)` returns each source definition.
`hooks.validate` resolves every named hook. A map's own handler returns
typed operations or uses the shared controller API; no Go map-ID switch
or separately maintained ID/weight table is permitted.

- [ ] Build a temporary source audit outside the repo to enumerate the
  600 `NAME` values, the 91 existing names, all directives/scripts, and
  exact legacy exclusions. Use its output only for deliberate extraction;
  commit the resulting `.des` and Lua files, not the importer.
- [ ] Add failing corpus tests that compare the expected source ID set,
  verify unique effective IDs and hook methods, and force each active
  Dungeon map in a legal context. Test branch-only registration without
  pretending its branch is generated.
- [ ] Port builder definitions as a coherent category and their script
  families as local-object Lua modules; run the builder contract tests.
- [ ] Port all 17 serial source-file families, including controller and
  helper maps; run per-family controller and placement contract tests.
- [ ] Check all 600 definitions against the audit, then commit and push
  the builder and serial categories after each passes its own checks.

### Task 6: Integrate, document, verify, and push

**Files:** Modify `policy/generation/vaults/secondary.lua`,
`generated.lua`, `README.md`, `docs/modding.md`,
`docs/port-inventory.md`, and `docs/ecs-architecture-roadmap.md`.

- [ ] Remove `GENERIC_EXTRA_ROLL` and the shop-only stage. Use the actual
  chance, place, and minivault pools on D:1–15. Preserve source branch
  eligibility for later branch generation.
- [ ] Document new map, helper, controller, chance, hooks, context API,
  sparse overlays, uniqueness, and save behavior in the modding guide.
- [ ] Run `git diff --check`, style/line checks, all Lua rule tests, and
  one broad `go test ./...` after the integrated category is in place.
  Diagnose concrete failures and rerun only failed scopes after fixes.
- [ ] Commit the integrated category on `main`, push `origin main`, and
  verify the checkout is clean and matches the remote.
