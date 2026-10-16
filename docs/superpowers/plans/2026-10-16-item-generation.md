# Source-backed Item Generation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Generate every active item class with source-backed Lua rules, and persist complete vault and
acquirement results as ECS items.

**Architecture:** Committed, individually discoverable Lua definitions hold item and artefact metadata.
Focused class policies implement source rolls behind one `policy.item_generation` API; a shared materializer
attaches the result to an ECS item. Go owns only the generic item location invariant and save codec. Vaults
and acquirement call the same API.

**Tech Stack:** Go 1.25, Akara ECS, embedded layered Lua mod, Lua `_test.lua` harness, JSON save snapshots,
deliberate Python catalog export tools.

**Spec:** `docs/superpowers/specs/2026-10-16-item-generation-design.md`

## Global Constraints

- Work in `/Users/dylanknuth/src/dcrawl-go` on `codex/item-generation`, based on Go `main` at `7412bf2`.
- Use pinned DCSS source `e60ba3568b0c26447ad36ec5c7b963eb04b2778f` under
  `/Users/dylanknuth/src/crawl/crawl-ref/source` for source rules.
- Normal build and play read committed Lua content. Importers run only for deliberate upstream refreshes.
- Lua owns game policy and extensible instance state. Go owns generic ECS storage, location, save, and script services.
- No inline Lua in Go, giant class/content switches, uniform fallback, or replicated test schemas.
- Keep Lua and Go readable: at most 120 characters per line, prefer 80; split populated struct/table fields
  across lines.
- Verify at the domain boundary and make one contiguous-category **implementation** commit. The plan document
  is its own documentation commit.

## Review Focus

1. A mod adds a valid item file to an existing class: the eligible pool includes it without a registry edit.
   Pin in Task 2.
2. A forced item lacks eligibility or conflicts with an override: generation reports item and caller site
   rather than changing the kind. Pin in Task 3.
3. A unique is offered, the menu is cancelled, and the game is restored: the same offered entity, name, and
   unique history remain. Pin in Task 7.
4. A save gives one item two locations or a dead reservation owner: restore rejects it before play. Pin in Task 6.
5. A mod overrides a class policy with invalid weights or incompatible artefact properties: load fails with
   the effective path. Pin in Tasks 2 and 5.

---

### Task 1: Commit source generation metadata and artefact definitions

**Files:**
- Create: `scripts/import_item_generation.py`, `scripts/test_import_item_generation.py`
- Modify: `scripts/export-catalog-lua.py`, `scripts/test_export_catalog_lua.py`
- Create: `internal/content/generated/item-generation.json`, `internal/content/generated/unrands.json`
- Modify: `internal/modfs/builtin/content/items/*.lua` through deliberate export
- Create: `internal/modfs/builtin/content/artefacts/*.lua`, `internal/modfs/builtin/ids/artefacts.lua`
- Modify: `internal/modfs/builtin/constants/catalog.lua`
- Test: `internal/script/testdata/lua/tests/item_generation_content_test.lua`

**Interfaces:**
- Each item definition gains `generation = { mode, rarity, min_depth, ... }` with source-specific, named
  fields. `mode` is `random`, `forced`, or `none`; absence is invalid for an active definition.
- Each unique definition registers in catalog category `artefacts` with ID, source order, base kind, flags,
  properties, and hook IDs. The 127 source records remain separate files; `nogen` and dummy remain registered
  but not random eligible.
- `python3 scripts/import_item_generation.py --source <pinned-source> --check` compares source to committed
  JSON; `python3 scripts/export-catalog-lua.py --check` compares committed JSON to Lua. Neither runs in the
  normal build.

- [ ] **Step 1: Write failing importer and Lua content tests.** Assert all 368 base definitions have explicit
      generation mode, all 127 unique definitions preserve source order, 44 removed entries remain
      inspectable, and `nogen`/dummy are not random eligible. Include one deliberately changed source weight
      and one missing artefact property in the importer fixtures.
- [ ] **Step 2: Run red checks.**
      `python3 -m unittest scripts.test_import_item_generation scripts.test_export_catalog_lua` and
      `go test -p1 ./internal/script -run 'TestLuaRules/item_generation_content_test\.lua' -count=1` must fail
      for missing metadata/catalogue.
- [ ] **Step 3: Implement the deliberate source parser and exporter.** Trace `makeitem.cc`, `item-prop.cc`,
      `spl-book.cc`, `artefact.cc`, `art-data.txt`, and relevant `art-func.h` generation hooks. Keep source
      paths as comments near generated Lua declarations, never runtime fields. Preserve source conditions as
      named metadata rather than flattening to a uniform weight.
- [ ] **Step 4: Run green checks.** Run the Step 2 commands, both `--check` commands, and verify committed
      data contains exactly 127 unique records.

### Task 2: Validate and discover generation policies

**Files:**
- Create: `internal/modfs/builtin/policy/item_generation/catalog.lua`,
  `internal/modfs/builtin/policy/item_generation/validate.lua`
- Create: `internal/modfs/builtin/policy/item_generation/classes/*.lua` as each class policy is added in Tasks 3–5
- Modify: `internal/modfs/builtin/init.lua`, `internal/modfs/builtin/content/validation.lua`
- Test: `internal/script/testdata/lua/tests/item_generation_registry_test.lua`
- Test: existing layered-mod Go tests under `internal/modfs/` and `internal/script/`

**Interfaces:**
- `catalog.register(class_id, policy)` accepts a policy with `eligible`, `weight`, and `roll` functions.
  Each takes `(ctx, definition, request)`; `roll` also takes `result`. The loader discovers class policy
  files by path.
- `catalog.policy(class_id)` returns the effective layered policy. `validate.check()` runs after
  `mod.load_tree("policy")`, checking all active definitions, class coverage, positive weights, named IDs,
  compatibility metadata, and nonempty eligible pools. Errors include the effective mod path and ID.

- [ ] **Step 1: Write failing Lua and layered-mod tests.** Add one valid item file in an overlay, replace one
      class policy at the same path, and assert both affect generation without editing a registry. Add
      malformed weight, missing mode, unknown property, and empty-pool cases; assert source-addressed errors.
- [ ] **Step 2: Run red checks.**
      `go test -p1 ./internal/script -run 'TestLuaRules/item_generation_registry_test\.lua' -count=1` and
      focused modfs overlay tests fail for absent registry/validation.
- [ ] **Step 3: Implement registration and load-time validation.** Keep `register` ordering deterministic.
      Validate effective layered files after policy loading; avoid a parallel Go definition list.
- [ ] **Step 4: Run the same checks green.** Each overlay mutation must produce the intended pool/policy or
      exact validation failure.

### Task 3: Shared class, subtype, and ordinary instance rolls

**Files:**
- Create: `internal/modfs/builtin/policy/item_generation/init.lua`, `class_choice.lua`, `materialize.lua`
- Create: focused `internal/modfs/builtin/policy/item_generation/classes/` modules for every active base class
- Modify: `internal/modfs/builtin/constants/vault_item_quality.lua` and shared `ids/` modules only for missing named IDs
- Test: `internal/script/testdata/lua/tests/item_generation_roll_test.lua`
- Test: `internal/script/testdata/lua/tests/item_generation_classes_test.lua`

**Interfaces:**
- `generation.roll(ctx, request)` returns `{ kind_id, quantity, plus, charges, ego, components, source }`,
  with all random choices complete and no entity created. Request fields are `class_id?`, `kind_id?`,
  `depth`, `quality`, `allow_uniques`, `purpose`, `quantity?`, `ego?`, and `site`; `quality` is
  ordinary, `*`, good, or superb. `source` retains the typed caller request.
- `generation.create(ctx, result, location)` returns an ECS entity; location is exactly one of
  `{ position = { level_id, x, y } }`, `{ carrier = entity }`, or `{ reservation = entity }`. The
  materializer never draws RNG.
- Use one persisted, named `item_generation` RNG stream for source rolls; callers may use their own stream to
  choose when to request an item.

- [ ] **Step 1: Write failing deterministic Lua tests.** Check first/last weighted draw for ordinary and
      superb class tables, early wand and miscellaneous adjustments, all 16 class eligibility modes, source
      subtype boundaries, forced-only classes, depth/quality effects, overrides, quantities, charges, plus,
      and ego. Assert an impossible fixed request reports `site` and `kind_id` without fallback.
- [ ] **Step 2: Run red checks.**
      `go test -p1 ./internal/script -run 'TestLuaRules/item_generation_(roll|classes)_test\.lua' -count=1`
      fails at the public API.
- [ ] **Step 3: Implement the class selector and one focused module per generated class.** Preserve the
      source's selection order. A forced kind skips only class/subtype selection; it still receives applicable
      instance rolls. Classes generated only by explicit source paths get no ambient weight.
- [ ] **Step 4: Implement `materialize.lua` against `core.item` and dynamic component schemas.** It validates
      the rolled record and adds the chosen location plus optional instance components without re-rolling.
- [ ] **Step 5: Run the Step 2 command green.** Check a repeated seed/ruleset/request yields the same result.

### Task 4: Per-run item sets, manuals, and random books

**Files:**
- Create: `internal/modfs/builtin/schemas/player_item_sets.lua`, `player_unique_history.lua`,
  `item_manual.lua`, `item_random_book.lua`
- Create: `internal/modfs/builtin/policy/item_generation/item_sets.lua`, `books.lua`
- Modify: session creation and scroll eligibility Lua modules that consume the four item sets
- Test: `internal/script/testdata/lua/tests/item_sets_test.lua`, `item_generation_books_test.lua`
- Test: `internal/game/item_generation_session_save_test.go`

**Interfaces:**
- `item_sets.initialise(ctx, player)` draws and saves one of each hex/beam/blast wand and concealment scroll
  choice once per run. `item_sets.allowed(ctx, player, kind_id)` reads the saved choices.
- `books.roll(ctx, definition, request, result)` supplies dedicated manual skill/points or random-book
  spell-list components; the result survives materialization and save.
- Unique history is a separate player component with ordinary and nonlevel acquisition state; Task 5 reads/writes it.

- [ ] **Step 1: Write failing Lua and Go tests.** Assert each set has one saved choice, excluded siblings
      never appear, restore preserves choices and RNG state, and manuals/random books retain exact rolled
      contents. Tests import production schemas and definitions.
- [ ] **Step 2: Run red checks.**
      `go test -p1 ./internal/script -run 'TestLuaRules/(item_sets|item_generation_books)_test\.lua' -count=1`
      and `go test -p1 ./internal/game -run TestItemGenerationSessionSave -count=1` fail.
- [ ] **Step 3: Implement schemas and source rolls.** Initialise during new-game creation only; restore does
      not redraw. Connect saved choices to generated item and scroll eligibility.
- [ ] **Step 4: Run the Step 2 commands green.** Inspect saved JSON for player set component and book/manual
      item components.

### Task 5: Random and unique artefacts

**Files:**
- Create: `internal/modfs/builtin/schemas/item_artefact.lua`
- Create: focused `internal/modfs/builtin/policy/item_generation/artefacts/` modules for eligibility,
  properties, names, unique selection, and source generation hooks
- Modify: existing Lua item naming, identification, equipment/combat/status property consumers
- Test: `internal/script/testdata/lua/tests/item_generation_artefacts_test.lua`
- Test: `internal/game/item_artefact_save_test.go`

**Interfaces:**
- `artefacts.roll(ctx, definition, request, result)` adds a saved dynamic component with artefact kind, unique
  ID or seed, name, appearance, property values, and property knowledge. `artefacts.properties(ctx, item)`
  returns applicable typed properties to existing consumers.
- Source `nogen`, dummy, duplicate, ordinary/nonlevel-history, and randart fallback outcomes are explicit; no
  invented substitution for an unported effect.

- [ ] **Step 1: Write failing tests.** Pin first/last source property draw and compatibility reroll, unique
      weighted eligibility, duplicate suppression, nonlevel fallback, `nogen`/dummy exclusion, and display
      before/after identification. A mod overlay with incompatible artefact property must fail at load with
      effective path.
- [ ] **Step 2: Run red checks.**
      `go test -p1 ./internal/script -run 'TestLuaRules/item_generation_artefacts_test\.lua' -count=1` and
      `go test -p1 ./internal/game -run TestItemArtefactSave -count=1` fail.
- [ ] **Step 3: Implement source generation and focused hook handlers.** Read the player unique-history
      component from Task 4. Retain all properties; connect only mechanics already implemented in this port,
      leaving other named properties saved and explicit.
- [ ] **Step 4: Run Step 2 commands green.** Check a restore preserves exact artefact identity, name, values,
      and knowledge without another roll.

### Task 6: Generic reserved item location and save invariant

**Files:**
- Modify: `internal/ecs/components.go`, `internal/ecs/stores.go`, `internal/game/script_services.go`
- Modify: `internal/save/snapshot.go`, `internal/game/save.go`, `internal/game/save_restore_validation.go`,
  `internal/game/save_restore_components.go`
- Modify: Lua item-role validation under `internal/modfs/builtin/policy/save/`
- Test: `internal/game/reserved_item_save_test.go`, `internal/save/codec_test.go`

**Interfaces:**
- Add `ecs.ReservedBy{Owner akara.Entity}` and a corresponding host store and script component
  `core.reserved_by`. Save `EntityRecord.ReservedBy` and increment the save version from 18.
- Every item has exactly one location: Position, CarriedBy, or ReservedBy. A reservation owner is live and is
  neither the item itself nor another reserved item; an acquirement owner has a matching menu reference.
- The Go kernel exposes set/remove/read for reservation through the same script services used by Position and
  CarriedBy; Lua remains responsible for menu policy.

- [ ] **Step 1: Write failing save and runtime tests.** Round-trip a reserved item, reject zero/dead/self
      owner, two simultaneous locations, and an offer missing from its owner's menu; assert reserved items are
      absent from floor/inventory queries.
- [ ] **Step 2: Run red checks.** `go test -p1 ./internal/game -run TestReservedItem -count=1` and
      `go test -p1 ./internal/save -run TestReservedItem -count=1` fail.
- [ ] **Step 3: Add the store, script binding, codec, and restore validation.** Include dynamic-component menu
      references in the validation pass after entities/components are restored, before play resumes. Preserve
      backward compatibility only if an existing save migration already defines it; do not add a second
      item-location model.
- [ ] **Step 4: Run Step 2 commands green.** Verify save and restore produce identical item IDs and reservation owners.

### Task 7: Replace vault and acquirement generators

**Files:**
- Modify: `internal/modfs/builtin/policy/generation/vaults/specs/random_items.lua`, `resolve.lua`
- Modify: `internal/modfs/builtin/policy/population/vault_items.lua`
- Modify: `internal/modfs/builtin/policy/scrolls/acquirement_offers.lua`, `effects/acquirement.lua`
- Modify: `internal/modfs/builtin/schemas/scroll_acquirement_offers.lua`
- Test: `internal/script/testdata/lua/tests/vault_item_generation_test.lua`, `acquirement_item_generation_test.lua`
- Test: `internal/game/vault_population_test.go`, `internal/game/vault_population_save_test.go`,
  `internal/game/acquirement_item_generation_test.go`

**Interfaces:**
- Vault spec resolution returns a typed generation request; population calls `generation.roll` then
  `generation.create` at the floor position. Vault-origin and source records attach to the created entity.
  Gold and corpse/skeleton placement keep their source-specific components.
- Acquirement `offers.generate(ctx, player, scroll)` rolls and creates all offers once in
  `ReservedBy{Owner=scroll}`. The scroll's versioned component stores `offer_ids: list<entity>`.
  `offers.options(ctx, player, state)` reads each actual entity; `offers.grant(ctx, player, state, index)`
  moves the chosen entity to floor and retires the rest according to source unique-history rules.

- [ ] **Step 1: Write failing Lua and Go tests.** Cover fixed and random vault specs, all quality modes,
      depth/quantity/ego overrides, origin records, corpse/gold paths, acquirement class shuffle and complete
      offered state, cancellation, save/restore, reopening, choice, and identification. Assert offer IDs/names
      do not change and grant performs no item RNG draw.
- [ ] **Step 2: Run red checks.**
      Run the vault and acquirement Lua tests with `go test -p1 ./internal/script -count=1` and the Go tests
      with `go test -p1 ./internal/game -run '(TestVaultPopulation|TestAcquirementItemGeneration)' -count=1`.
      Expect failures against the provisional paths.
- [ ] **Step 3: Replace both provisional pickers with the shared API.** Delete old uniform-selection and ad
      hoc plus/charge code. Keep source-specific caller syntax and conditions in small caller modules, not in
      the generator.
- [ ] **Step 4: Run Step 2 commands green.** Restore and reopen a cancelled acquirement menu; verify exact
      entity IDs, labels, artefact state, and unique history.

### Task 8: Domain verification and one implementation commit

**Files:** All changed files above; update the relevant roadmap entry if it tracks item generation.

**Interfaces:** No new API. This task checks the integrated category and commits it once.

- [ ] **Step 1: Run import and Lua checks.**
      `python3 -m unittest scripts.test_import_item_generation scripts.test_export_catalog_lua`; run both
      exporter `--check` commands; `go test -p1 ./internal/script ./internal/modfs/... -count=1`.
- [ ] **Step 2: Run integrated Go checks.** `go test -p1 ./internal/game ./internal/save -count=1`,
      `go build ./...`, and `go vet ./...`; fix only concrete failures and rerun their failing suites.
- [ ] **Step 3: Check readability and diff.** Run repository Go/Lua style checks, `gofmt` on touched Go files,
      `git diff --check`, and inspect the full diff for giant switches, inline tables, duplicated IDs,
      missing provenance comments, or source-generated files in build steps.
- [ ] **Step 4: Commit the contiguous item-generation category.** `git add` the implementation and tests, then
      `git commit -m "feat: generate source-backed items across vaults and acquirement"`. Record test
      commands and any source features intentionally preserved as pending properties in the commit body or
      completion report.
