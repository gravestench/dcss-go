# Bailey Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking. The user chose native execution.

**Goal:** Make all nine source Bailey entrances and all 15 axe and polearm
destinations a playable, timed, saved D:7–10 portal domain.

**Architecture:** Committed `.des` files own authored geometry and directive
order. Named Lua hooks own source decisions, including the mapless `bailey`
dispatcher. A saved ECS gate carries the entrance theme into a Lua whole-floor
generator; the existing staged `luaPortal` transaction owns travel and
rollback. Go adds only neutral terrain and save integration.

**Tech Stack:** Embedded Lua, source DES, Akara ECS, Go terrain and save
services, Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-22-bailey-portal-design.md`

## Global Constraints

- Preserve all 25 active source `NAME` identities, original `MAP` rows,
  static directives, weights, tags, orientation, and source decision order.
- D:7–10 is the only source entrance range. The source chance is 1000 and
  the timer is one 600–800-turn draw after the two-way theme draw.
- Builds and play use committed assets only. Leave no importer or required
  C++ checkout in the normal build or test path.
- Keep hook bodies in documented `.lua` modules and source-position calls
  in `.des`; never put Lua source in Go strings.
- Explain every new Lua function's why and how. Prefer 80-character lines,
  never exceed 120, and expand multi-field tables.
- Put gate and visit state in Akara ECS. Keep terrain in the existing grid.
  Do not add a Bailey-specific Go travel path, content switch, or
  `source_order` field.
- Work on `main`. Verify the complete category, make one Bailey commit,
  and push `origin main`.

## Review Focus

1. A mapless `bailey` dispatcher passed to the geometry fitter must fail;
   the Bailey generator must run its post-place hook first. Task 2 tests both.
2. A saved gate with no theme, or a theme whose effective mod catalog has no
   positive-weight child, must fail before travel changes state. Tasks 2 and
   4 test these cases.
3. A gate may expire while its Dungeon floor is inactive. An entry accepted
   on the last valid turn must finish first. Task 3 tests both timings.
4. A failed child placement or blocked outside return must preserve the
   player, gate, RNG, entities, and floor set. Task 3 tests both failures.
5. A same-path hook replacement and a sparse added tagged child must use
   the effective VFS without changing built-in seeded order. Task 4 tests
   these overlays.

## File Map

- `internal/modfs/builtin/vaults/{bailey_entry,bailey}/*.des`: one effective
  source definition per replaceable file, including the empty dispatcher.
- `internal/script/testdata/bailey-source-map-digests.txt`: the 25 pinned
  source `MAP` digests, so normal tests need no C++ checkout.
- `internal/modfs/builtin/policy/generation/vaults/{bailey_entry,bailey}/*.lua`:
  documented source-position hooks and shared source helper expressions.
- `internal/modfs/builtin/policy/generation/bailey/level.lua`: execute the
  dispatcher, select the themed child, and publish one uninstalled floor.
- `internal/modfs/builtin/policy/world/bailey/{portal,travel}.lua` and
  `internal/modfs/builtin/systems/world_bailey_portals.lua`: marker identity,
  ECS clock, source messages, and staged travel policy.
- `internal/modfs/builtin/schemas/{world_bailey_portal,character_bailey_visit}.lua`,
  `internal/modfs/builtin/constants/{bailey,component,terrain}.lua`,
  `internal/modfs/builtin/ids/branches.lua`, and
  `internal/modfs/builtin/content/terrain_features.lua`: names and state.
- `internal/modfs/builtin/policy/save/{bailey_portals,bailey_levels,generated_levels}.lua`
  and `internal/game/save_restore_components.go`: reciprocal save checks.
- `internal/modfs/builtin/policy/generation/scenario.lua`,
  `internal/terrain/feature.go`, and existing terminal terrain presentation:
  policy registration and neutral feature rendering.
- `internal/script/testdata/lua/tests/bailey_*_test.lua`,
  `internal/script/testdata/bailey-vault-mod/`,
  `internal/game/bailey_travel_game_test.go`,
  `internal/terrain/bailey_portal_test.go`, and terminal terrain tests:
  corpus, generation, overlay, clock, travel, and save evidence.
- `internal/game/level_snapshot_text_test.go` and
  `docs/level-snapshots/bailey/`: opt-in text export of all 15 layouts and
  their Dungeon return connections.
- `docs/{modding,port-inventory}.md`: authoring contract and coverage.

---

### Task 1: Complete Source Corpus and Named Hooks

**Interfaces:** Every `.des` has one source `NAME` and source-position
`vault.run` or `vault.post_place` references. Hook modules consume the
production hook API and emit existing typed terrain, item, monster, trap,
marker, and pending-effect records; they do not hold durable module globals.

- [ ] **Step 1: Write failing corpus tests.** Add
  `internal/script/testdata/lua/tests/bailey_source_catalog_test.lua`.
  Assert nine entrances, one empty-map dispatcher, six axe layouts, and nine
  polearm layouts; compare committed map digests to
  `internal/script/testdata/bailey-source-map-digests.txt`, made from the
  pinned source. Check D:7–10, chance 1000, static weights,
  tags, hook order, and all 25 identities. Focused hook tests assert the
  source's conditional weapons and monsters, names, loot expressions,
  delayed skeleton decay, and typed requests for rare content.
- [ ] **Step 2: Verify red.** Run
  `go test ./internal/script -run 'TestLuaRules/bailey' -count=1`.
  Expect absent Bailey definitions and hook assertions to fail.
- [ ] **Step 3: Port source definitions.** Check in one `.des` per `NAME`,
  retaining authored rows and directive order. Port `bailey_portal`,
  `bailey_setup`, axe and polearm monster helpers, and each local script
  into named Lua modules. Use shared imported IDs and constants. Keep the
  empty dispatcher as a real definition with `vault.post_place`.
- [ ] **Step 4: Verify green.** Run the focused Lua test. Expect all 25
  definitions to load and every hook to emit its asserted source records.

### Task 2: Themed Dispatcher and Whole-Floor Placement

**Interfaces:** `policy.generation.bailey.level.candidates(theme, player)`
returns positive-weight effective child IDs in stable ID order.
`level.generate(ctx, input)` accepts `theme` and optional `layout_id`,
executes the `bailey` controller hook, and returns `{ level = ... }` with
both dispatcher and selected child in vault history. The controller hook
uses the existing placement API; it never passes the empty map to geometry.

- [ ] **Step 1: Write failing generation tests.** Add
  `bailey_generation_test.lua` and `TestBaileyAllSourceMapsPopulate`.
  Assert that both theme pools are disjoint, all 15 children can be selected
  through the dispatcher, and every resulting floor has safe arrival, a
  live `exit_bailey`, authored entities and equipment, and both vault IDs.
  Assert direct geometry placement of `bailey` fails, while controller-first
  placement succeeds. A missing theme or empty matching pool fails before
  a floor is published.
- [ ] **Step 2: Verify red.** Run the focused Lua test and
  `go test ./internal/game -run TestBaileyAllSourceMapsPopulate -count=1`.
  Expect the missing generator and controller behavior to fail.
- [ ] **Step 3: Implement generation.** Add the Bailey branch identity and
  `world.generate_bailey_level` registration in `scenario.lua`. Have the
  level owner run the source mapless dispatcher's `post_place` hook to
  choose one matching positive-weight child, then use the existing
  whole-floor placement, terrain projection, and entity population path.
  Keep the source theme and chosen layout in the generated record, and
  preserve authored effects whose wider gameplay owner is pending as
  typed saved records.
- [ ] **Step 4: Verify green.** Run the same focused tests. Expect all 15
  layouts to populate through the real dispatcher without a special Go
  placement branch.

### Task 3: Saved Timed Gate and Exact Travel

**Interfaces:** `policy.world.bailey.portal.materialize(ctx, level, record)`
creates one gate component from the source `timed_marker`, including its
`bailey_type` and fixed duration. `portal.at(ctx, level_id, x, y)` finds
that exact gate. `world.bailey.commit_travel` is the Lua callback for the
existing `luaPortal` transaction. `world.generate_bailey_level` consumes
the saved theme supplied by entry policy.

- [ ] **Step 1: Write failing behavior tests.** Add
  `bailey_portal_messages_test.lua` and
  `bailey_travel_game_test.go`. Assert theme draw precedes the one
  600–800-turn duration draw; clocks start at entrance population; five
  source remaining-time bands, hearing and Silence, final warning and
  closing thud match the source; silent notices still advance cadence.
  Test off-floor expiry, last-valid-turn entry, failed child staging
  rollback, saved exact return, blocked return, spent/expired arch state,
  and retirement of temporary actors and items.
- [ ] **Step 2: Verify red.** Run focused Lua tests and
  `go test ./internal/game -run TestBailey -count=1`. Expect missing
  component, timer, or travel behavior to fail.
- [ ] **Step 3: Implement the domain.** Add distinct entrance and exit
  feature IDs, constants, gate and visit schemas, marker materialization,
  action-time system, and Lua travel policy. Carry the source marker's
  `bailey_type` into the saved gate, then into the generation input and
  saved visit. Route `enter_bailey` and `exit_bailey` through domain `lua`.
  Spend the outside gate only after staging succeeds; use the existing
  transaction to retire the temporary floor on return.
- [ ] **Step 4: Verify green.** Run the same focused tests and
  `go test ./internal/terrain ./internal/terminal -run Bailey -count=1`.
  Expect clock, messages, travel, rollback, and terrain rendering to pass.

### Task 4: Restore, Mods, Snapshots, and Category Verification

**Interfaces:** `save.validate_bailey_portals(ctx, input)` checks each gate
against source marker, deadline, theme, spent state, and grid feature.
`bailey_levels.validate(saved_levels)` checks selected tagged child,
dispatcher history, exit, and active visit's reciprocal outside site.

- [ ] **Step 1: Write failing integrity and overlay tests.** Forge missing
  and mismatched marker/theme, bad deadline, changed feature, wrong child
  tag, missing dispatcher, absent exit, and mismatched return site; assert
  restore rejection. Test save/restore before entry, during visit, after
  expiry, and after exit without redrawing theme, duration, layout, or
  entities. Add one sparse tagged child and a same-path hook replacement;
  assert the effective catalog uses both, stable built-in seed behavior,
  and clear early rejection of a malformed hook or missing theme pool.
- [ ] **Step 2: Verify red.** Run focused Lua and
  `go test ./internal/game -run TestBailey -count=1`. Expect the new
  integrity and overlay cases to fail.
- [ ] **Step 3: Implement validation and export.** Register Bailey save
  policies with generic restore. Extend the opt-in text-snapshot helper to
  export all 15 production-generated Bailey layouts and a connection
  index showing each temporary exit and exact Dungeon return site. Check
  in readable output under `docs/level-snapshots/bailey/`. Document the
  two mod directories, theme tags, dispatcher contract, hook API, gate and
  visit state, and sparse added-layout example in `docs/modding.md`.
  Record exact coverage and wider gaps in `docs/port-inventory.md`.
- [ ] **Step 4: Verify and commit the category.** Regenerate snapshots
  intentionally and compare their diff. Run focused Lua, game, terrain,
  and terminal tests, then `go test -timeout 5m ./...`; report existing
  suite timeouts separately if they recur. Run `gofmt` on changed Go,
  `sh scripts/check-go-style.sh`, and `git diff --check`. Review source
  parity, rollback, save invariants, snapshot connections, and the diff.
  Commit the complete Bailey category on `main` and push `origin main`.
