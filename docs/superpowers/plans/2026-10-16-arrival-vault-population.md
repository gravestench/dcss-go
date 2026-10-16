# Arrival Vault Population Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve every valid arrival-vault monster and item expression and
create its selected objects as saved Akara entities.

**Architecture:** Lua parses the source expression grammar, selects from
source-backed content and depth pools, and hands typed results to generic
ECS factories. A vault-origin component links each created entity to its
materialized level record. Save validation checks that link without
replaying generation.

**Tech Stack:** Go 1.25, embedded Lua, Akara ECS, layered mod VFS, JSON save
version 18, committed DCSS content, Lua `_test.lua` fixtures.

**Spec:** `docs/superpowers/specs/2026-10-16-arrival-vault-population-design.md`

## Global Constraints

- Work in `/Users/dylanknuth/src/dcrawl-go` on `codex/vault-population`,
  based on local `main` at `fe9b0e1`; do not alter the paused C++ refactor.
- The committed `.des` files and individual Lua content files are runtime
  authority. The C++ tree is read only for deliberate source tracing.
- All game rules, parsers, random selectors, and ECS systems for this slice
  live in actual Lua files. Go may change only for reusable record transport
  or save validation primitives. No inline Lua or compatibility adapter.
- Source identity constants are imported where used. Provenance stays in
  comments beside content declarations. Tests import production schemas.
- Keep handwritten lines at or below 120 characters, preferably 80; split
  multi-field table and struct literals across lines. Keep Lua methods flat.
- One implementation commit closes this entire contiguous category. Focused
  tests run during development; the full suite runs once after the batch.

## Review Focus

1. A monster equipment clause containing `|` or `.` must stay attached to
   its chosen monster, not become another slash choice (Task 1 test).
2. Two effective content definitions with the same source name must fail
   with both IDs and the vault source site (Task 2 test).
3. An implicit random request with no eligible depth pool must fail with
   vault path, line, and glyph (Task 2 test).
4. A spawned monster that dies or an item that is picked up must save and
   restore without respawning; a live duplicate origin must fail (Task 5
   test).
5. Multiple declarations targeting one cell must obey source slot order and
   never create two actors on one tile (Task 4 test).

---

### Task 1: Parse the full arrival entity expression family

**Files:** Create
`internal/modfs/builtin/policy/generation/vaults/specs/choice.lua`,
`monster.lua`, and `item.lua`; create
`internal/script/testdata/lua/tests/vault_entity_specs_test.lua`.

**Interfaces:** `monster.parse(expression, site)` and
`item.parse(expression, site)` each return an ordered choice list with
positive integer weights and typed modifiers. `choice.pick(random, list)`
accepts an object with `roll(bound)` and returns one parsed choice. `site`
contains `path`, `vault_id`, `line`, `directive`, and `glyph` for errors.

- [ ] Write `vault_entity_specs_test.lua` using actual DES expressions and
  handler outputs. Cover comma slots, slash weights, `nothing`, `0`, `w:`,
  `q:`, `col:`, `att:`, `spells:`, `place:`, monster `;` equipment with `|`
  alternatives and `.` slots, plus malformed weights and unknown modifiers.
  Assert the source `mapdef.cc` weighted boundaries and cumulative draw
  sequence, and that equipment stays attached to the selected monster.
- [ ] Run `env GOCACHE=/private/tmp/dcrawl-go-cache go test -p 1
  ./internal/script -run 'TestLuaRules/vault_entity_specs_test.lua' -count=1`;
  confirm RED for the missing parser.
- [ ] Implement the three focused parser modules. Use the pinned
  `mapdef.cc:3656-3860,3880-4065,4824-4860,5146-5310,5645-5670`
  semantics for this arrival-family grammar. For each alternative, add its
  weight to the cumulative total, call `random:roll(total)`, and replace the
  chosen alternative when the draw is below that alternative's weight.
  Return a typed no-spawn choice for `nothing`; reject leftover tokens with
  the complete `site`.
- [ ] Re-run the focused test; confirm PASS.

### Task 2: Resolve names and random source choices

**Files:** Create
`internal/modfs/builtin/policy/generation/vaults/specs/resolve.lua`,
`random_monsters.lua`, and `random_items.lua`; modify
`internal/modfs/builtin/policy/population/pool.lua`; create
`internal/script/testdata/lua/tests/vault_entity_resolution_test.lua`.

**Interfaces:** `resolve.monster(ctx, choice, depth, site)` and
`resolve.item(ctx, choice, depth, site)` consume one Task 1 chosen term and
return a stable catalog ID,
variant/base ID where needed, and typed modifiers, or an explicit no-spawn
result. `random_monsters.pick(ctx, request, depth, site)` uses source
population rows without the ordinary D:1 roster whitelist.
`random_items.pick(ctx, request, depth, site)` uses source class and quality
rules. Both random modules return a catalog ID, not an English name.

- [ ] Write resolution tests against production catalog files. Exercise
  every name in the 339 DES files and all 36 handler branches, generated
  undead variants, `place:D:1`, random/good/superb item requests, moderate
  and super out-of-depth monster requests, empty pools, duplicate mod
  aliases, and the source unique-monster veto. Assert stable IDs and
  source-addressed failures.
- [ ] Run `go test` for `vault_entity_resolution_test.lua`; confirm RED.
- [ ] Implement lookup with catalog names and focused per-definition aliases
  or variant policy. Port D:1 and `place:D:1` random rules from
  `dungeon.cc:4769-4868,4991-5075`, `mapdef.cc`, and
  `makeitem.cc:1766` into Lua. For D:1, both source OOD glyphs draw at
  effective depth 2; the ordinary glyph draws at depth 1. Resolve `%`, `$`,
  `*`, and `|` through their source random item, gold, good, and superb
  branches. Reuse imported population rows and item properties; commit any
  additional source weights as Lua data with source comments. Do not read
  C++ during a build or game launch.
- [ ] Re-run the focused test and the pinned DES importer `-check`; confirm
  both PASS and no generated DES bytes changed.

### Task 3: Construct all resolved vault entities through ECS

**Files:** Modify `internal/modfs/builtin/policy/population/factory.lua`,
`gear.lua`, and `gear/registry.lua`; create
`internal/modfs/builtin/policy/population/vault_items.lua` and
`internal/modfs/builtin/schemas/vault_origin.lua`; modify
`internal/modfs/builtin/constants/component.lua`; create
`internal/script/testdata/lua/tests/vault_entity_factory_test.lua`.

**Interfaces:** Extend `factory.spawn(ctx, kind_id, level_id, x, y, options)`
with optional typed `options` for variant, colour, attitude, spells, and
vault origin. `vault_items.create(ctx, resolved, level_id, x, y, origin)`
creates floor, corpse, skeleton, gold, or stacked items through the current
item schema. `vault.origin` stores level ID, vault ID, record index,
occurrence, and original spawn coordinates.

- [ ] Write factory tests using production actor, item, and corpse schemas.
  Assert a D:1 vault can create catalog monsters outside the ambient roster,
  source HP/speed/energy and content-defined gear, carried `;` items,
  colour/attitude/spell overrides, undead base species, corpse and skeleton
  source species, stack quantity, and the origin component. Check invalid
  equipment and a failed placement leave no partial entity or carried item.
- [ ] Run `go test` for `vault_entity_factory_test.lua`; confirm RED.
- [ ] Generalize the Lua monster factory and gear selection for active
  catalog definitions. Keep specialist gear handlers only for source
  exceptions; otherwise consume each monster definition's `weapon_gear`.
  Add the focused item constructor and Lua origin schema. Apply habitat
  rules before placement as in `dungeon.cc:4991-5075`.
- [ ] Re-run the focused test; confirm PASS.

### Task 4: Wire choices to vault placement and population

**Files:** Modify
`internal/modfs/builtin/policy/generation/vaults/operations.lua`,
`placement.lua`, and `catalog.lua`; replace the partial materializer in
`internal/modfs/builtin/policy/population/vaults.lua`; modify
`internal/game/generation_vault.go` and `populate_script.go`; create
`internal/script/testdata/lua/tests/vault_entity_placement_test.lua`
and `internal/game/vault_population_test.go`.

**Interfaces:** `placement.place` produces one resolved outcome per authored
cell and ordered slot. A materialized `vault.Record` stores its original
expression, selected stable ID, and modifiers in typed arguments.
`vaults.materialize(ctx, level)` returns actor count and record outcomes;
ordinary ambient population still uses `roster.allowed(scenario_id)`.

- [ ] Write placement tests for all static expressions and forced handler
  branches. Assert keyed `:` shares one draw, `=` draws per cell, implicit
  glyphs use the same resolver, source slot order holds, one actor occupies
  a cell, explicit `nothing` is nonpending, and invalid mod declarations
  fail with source site. Include the Review Focus multi-declaration case
  and source-defined unique no-spawn case.
- [ ] Run the focused Lua test and
  `env GOCACHE=/private/tmp/dcrawl-go-cache go test -p 1 ./internal/game
  -run TestVaultPopulationMaterializesSourceSelections`;
  confirm RED for missing materialization.
- [ ] Replace `weighted_identity` and name-based best-effort spawning with
  the Task 1–3 route. Validate static expressions at effective catalog
  load and handler expressions when emitted. Pass resolved typed arguments
  through the existing Go level record bridge; remove the early-roster
  whitelist only for authored vault entities. Do not create a second
  parser or an old-path adapter.
- [ ] Re-run the focused Lua and game tests; confirm PASS.

### Task 5: Validate and restore the authored entity lifecycle

**Files:** Create `internal/modfs/builtin/policy/save/vault_entities.lua`;
modify `internal/modfs/builtin/policy/save/monsters.lua`, `corpses.lua`,
`monster_inventory.lua`, and `internal/game/save.go`; create
`internal/game/vault_population_save_test.go` and
`internal/script/testdata/lua/tests/vault_entity_save_test.lua`.

**Interfaces:** `save.validate_vault_entities(ctx, input)` validates origin
links against materialized level records and ordinary ECS invariants.
Dead, consumed, or carried entities do not trigger a second spawn. A live
origin must match its record, source coordinates, stable ID, and occurrence.

- [ ] Write RED Lua and Go save tests for a live moved monster, killed
  monster, picked-up item, consumed item, corpse decay, carried equipment,
  duplicate occurrence, missing level record, forged ID, and a pre-vault
  version-18 save without optional origin fields. Assert exact ECS and
  record equality after restore and no replayed RNG draws. Name the Go test
  `TestVaultPopulationSaveRestore`.
- [ ] Run focused `go test -p 1 ./internal/game ./internal/script
  -run 'TestVaultPopulation|TestLuaRules/vault_entity_save_test.lua'`; confirm
  RED for origin validation.
- [ ] Validate source origins in Lua, separate authored monsters from the
  ambient population budget, and accept only legal live/dead transitions.
  Keep version 18 and the existing save/ruleset hash policy. Do not rerun
  entity expressions on restore.
- [ ] Re-run the focused tests; confirm PASS.

### Task 6: Exhaustive arrival and client verification

**Files:** Create `internal/script/testdata/lua/tests/vault_population_all_test.lua`;
modify `internal/game/vault_population_test.go`,
`internal/script/lua_rules_test.go`,
`docs/port-inventory.md` and `docs/ecs-architecture-roadmap.md`.

**Interfaces:** The exhaustive test drives all 337 selectable arrivals with
deterministic seeds and checks every selected entity or explicit no-spawn
outcome. The integrated test observes client glyphs and item/actor
interaction from a forced complex vault.

- [ ] Write the exhaustive Lua test and an integrated Go test covering an
  authored monster, equipment, corpse or skeleton, stack quantity, random
  identity, colour, friendly/neutral allegiance, client symbol, pickup,
  save/restore, and a mod-added content file. Name the Go test
  `TestVaultPopulationClientAndRestore`. Import production catalogs and
  schemas; use no copied test definition tables. Give the exhaustive Lua
  test its own 60-second context allowance in the existing test runner.
- [ ] Run these focused tests; resolve any uncovered source expression in
  its owning Lua module, then confirm PASS.
- [ ] Update the port inventory and ECS roadmap with the now-live vault
  population boundary and the still-unported special monster/item behavior.

## Category boundary

- [ ] Run the pinned importer `-check` against all 339 DES files. Confirm
  the parser and exhaustive tests cover 337 arrivals and 36 handler owners.
- [ ] Run `env GOCACHE=/private/tmp/dcrawl-go-cache go test -p 4 ./...
  -count=1 -timeout 30m`, `go build -p 1 ./...`, `go vet -p 1 ./...`,
  `sh scripts/check-go-style.sh`, and `git diff --check`.
- [ ] Inspect the complete diff for hard-coded identity branches, inline
  Lua in Go, duplicate rule paths, overlong lines, and declarations with
  provenance stored as data fields.
- [ ] Review the complete category, then create one implementation commit.
  The user's contiguous-category commit instruction overrides per-task
  commits. Integrate to local `main` through the branch-finishing workflow.
