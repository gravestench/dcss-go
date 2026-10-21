# Religion Worship and Piety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan. Steps use checkbox
> (`- [ ]`) syntax for tracking.

**Goal:** Make altar worship, renunciation, and piety live, saved Lua rules
for every active source god.

**Architecture:** `religion.worship` owns the player's mutable divine state.
Lua eligibility and per-god modules own rules. A generic level-record query
lets Lua identify the altar under the player; Go supplies timing, saves,
and the terminal's primitive input and display.

**Tech Stack:** Go, Akara dynamic components, embedded Gopher Lua, Bubble Tea.

**Spec:** `docs/superpowers/specs/2026-10-21-religion-worship-design.md`

## Global Constraints

- Work on local `main` and push each completed problem-category commit to
  `origin/main`, per the user's latest integration instruction.
- Keep game rules in `.lua` files under the embedded mod tree; Go remains
  content-neutral. No inline Lua in Go, content importer, or compatibility
  adapter for the old Go save schema.
- Use IDs from shared modules at each use site. Do not add a central god
  switch or depend on file discovery order for random seeds.
- Comment each new Lua function's why and how. Keep lines at or below 120
  characters, preferably near 80. Break multi-field table declarations out.
- Keep this as one worship/piety category commit after meaningful boundary
  verification. Later conduct, abilities, gifts, passives, and wrath are
  separate contiguous categories, and remain explicit inventory work.

## Review Focus

1. A temple altar with a saved `god_id` must resolve that exact god after
   save/restore; add this to Task 2's integration test.
2. A refused conversion must leave piety, turn time, RNG, and altar identity
   untouched; add this to Task 5's terminal test.
3. A modded altar with an unknown god ID must produce a clear load or action
   error; add this to Task 2's validation test.
4. A player with a god-linked starting job must keep its source starting
   piety after the component migration; add this to Task 1's start test.
5. Rejoining Ignis must not reset depleted piety; add this to Task 4's Lua
   state-machine test.

---

### Task 1: Move mutable worship out of character origin

**Files:**
- Create: `internal/modfs/builtin/schemas/religion_worship.lua`
- Modify: `internal/modfs/builtin/constants/component.lua`
- Modify: `internal/modfs/builtin/schemas/character_origin.lua`
- Modify: `internal/modfs/builtin/policy/character/start.lua`
- Modify: `internal/modfs/builtin/policy/save/player.lua`
- Test: `internal/script/testdata/lua/tests/religion_state_test.lua`
- Test: `internal/game/all_character_starts_test.go`

**Interfaces:**
- Produces `component.RELIGION_WORSHIP = "religion.worship"`.
- Produces schema fields `god_id`, `piety`, `piety_hysteresis`,
  `gift_timeout`, `penance`, `worshipped`, `piety_max`,
  `previous_good_god`, `saved_good_piety`, and `min_ignis_piety`.
- `penance`, `worshipped`, and `piety_max` use `map<string,int64>`.

- [ ] Write a Lua test using production schema/IDs: all four religious
      starting jobs get their pinned god/piety, ordinary jobs get no god,
      and the origin component contains no mutable worship fields.
- [ ] Run `GOCACHE=/private/tmp/crawl-gocache go test ./internal/script
      -run 'TestLuaRules/religion_state_test' -count=1`; verify the
      pre-implementation failure identifies missing worship state.
- [ ] Add the schema and migrate `character.start` to initialize it. Remove
      the three religion fields from origin and validate the new schema in
      `save/player.lua`, including registered god IDs and nonnegative history
      maps.
- [ ] Run the focused Lua test and `go test ./internal/game
      -run TestDistinctCharacterStartFamiliesReachDungeon -count=1`.

### Task 2: Expose typed level records at a coordinate

**Files:**
- Modify: `internal/script/context.go`
- Modify: the active grid host file implementing `luaGridCell`
- Modify: `internal/game` runtime context binding for the active level
- Test: `internal/script/host_components_test.go`
- Test: `internal/game/temple_travel_test.go`

**Interfaces:**
- Produces `ctx:records_at(level_id, x, y)` returning a fresh sorted Lua
  array of generic record tables (`kind`, `identity`, `arguments`, `x`, `y`,
  `pending`). No god-specific branch enters Go.
- The query reads authoritative `Level.VaultRecords()` and does not expose
  a mutable Go record to Lua.

- [ ] Write a failing host test for several typed records on one cell,
      including altar `god_id` and defensive copying of returned tables.
- [ ] Run that test and verify the missing API failure.
- [ ] Implement the generic query through the existing context/grid host
      boundary, preserving record order and typed arguments.
- [ ] Add a generated Temple integration test that queries a saved altar
      before and after restore; reject unknown saved altar god IDs.
- [ ] Run both focused tests.

### Task 3: Implement eligibility and common piety owner

**Files:**
- Create: `internal/modfs/builtin/policy/religion/eligibility.lua`
- Create: `internal/modfs/builtin/policy/religion/piety.lua`
- Create: `internal/modfs/builtin/constants/piety.lua`
- Test: `internal/script/testdata/lua/tests/religion_eligibility_test.lua`
- Test: `internal/script/testdata/lua/tests/religion_piety_test.lua`

**Interfaces:**
- `eligibility.check(ctx, player, god_id, temporary)` returns nil when
  allowed, otherwise a source-specific reason string.
- `piety.gain(ctx, player, numerator, denominator, scale)` and
  `piety.lose(ctx, player, points)` update `religion.worship`, emit rank
  signals, and never apply an unspecified god gift or passive.
- `piety.rank(god_id, points)` and `piety.breakpoint(stars)` are pure.

- [ ] Write table-driven Lua tests for all 26 active gods and each source
      restriction family, including form and wallet state that can change.
- [ ] Write piety tests for breakpoint edges, cap, Ru, Xom, no god/Gozag,
      hysteresis, timeout, penance, and deterministic restored random state.
- [ ] Run both focused tests and confirm failures target missing rules.
- [ ] Implement modules using existing species, mutation, form, holiness,
      and wallet owners. Keep god-specific special cases in their god files.
- [ ] Run both focused tests.

### Task 4: Implement one transition path for the pantheon

**Files:**
- Create: `internal/modfs/builtin/policy/religion/worship.lua`
- Create: one definition per active god under
  `internal/modfs/builtin/content/gods/`
- Create: focused modules under
  `internal/modfs/builtin/policy/religion/gods/<god>.lua`
- Modify: `internal/modfs/builtin/constants/catalog.lua` to register the
  `gods` content category
- Modify: `internal/modfs/builtin/content/validation.lua` to validate each
  effective god definition before policies load
- Modify: `internal/modfs/builtin/constants/gods.lua` to include the source
  temporary `GOD_ECUMENICAL` altar ID
- Test: `internal/script/testdata/lua/tests/religion_worship_test.lua`

**Interfaces:**
- `worship.join(ctx, player, god_id, source)` runs old god leave, common
  state transition, and named god join in that order.
- `worship.renounce(ctx, player)` runs the same leave path without a new god.
- Each god definition declares its ID, name, starting piety, and hook module
  name. A behavior module exports `join(ctx, player, state, source)` and
  `leave(ctx, player, state, next_god)` when it has an immediate source effect.
  All 26 active IDs must register; no empty behavior files are needed.

- [ ] Write a Lua test for every god's registration and starting state,
      transfer between good gods, Monk/ecumenical bonuses, Gozag fee, and
      leaving/returning to Ignis. Assert ordering of leave/join signals and
      ID-order traversal independent of file path order.
- [ ] Run it and verify missing behavior fails.
- [ ] Implement the common transition and per-god immediate effects from
      `religion.cc`. Persist deferred effects as typed state owned by their
      later system rather than dropping them or substituting generic effects.
- [ ] Run the focused test.

### Task 5: Wire prayer, confirmation, save, and presentation

**Files:**
- Modify: `internal/modfs/builtin/policy/input/play.lua`
- Modify: `internal/modfs/builtin/policy/input/commands.lua`
- Modify: `internal/modfs/builtin/constants/command_kind.lua`
- Modify: `internal/modfs/builtin/constants/intent.lua`
- Modify: `internal/modfs/builtin/policy/command_prepare.lua` and command
  registry entry
- Create: `internal/modfs/builtin/systems/religion_prayer.lua`
- Modify: `internal/game/commands.go`
- Modify: `internal/ecs/components.go`
- Modify: `internal/terminal/play_input.go` and terminal confirmation flow
- Modify: `internal/game/view.go` and terminal sidebar renderer
- Test: `internal/script/testdata/lua/tests/religion_prayer_test.lua`
- Test: `internal/game/religion_prayer_test.go`
- Test: `internal/terminal/religion_prayer_test.go`

**Interfaces:**
- `<` or `>` on altar enters the prayer command; their existing behavior
  applies elsewhere. The accepted prayer uses a dedicated intent and
  resolves on the player system schedule.
- The terminal confirmation carries a stable altar ID and returns a no-time
  cancellation without consuming RNG. The sidebar reads `religion.worship`
  through a Lua presentation policy.

- [ ] Write failing Lua and Go integration tests for same-god prayer,
      ordinary conversion, refusal, forbidden worship, ecumenical choice,
      save/restore, and terminal key behavior on and off an altar.
- [ ] Run focused tests and confirm the first failure is the missing
      command/intent behavior.
- [ ] Implement input routing, generic command decoding, a Lua prayer
      policy/system, confirmation, altar mutation, and presentation. Keep
      decisions in Lua and generic timing/saving/rendering in Go.
- [ ] Run focused tests, then the category boundary suite:
      `GOCACHE=/private/tmp/crawl-gocache go test ./internal/script
      ./internal/game ./internal/terminal -count=1`.
- [ ] Run `sh scripts/check-go-style.sh` and inspect changed Lua files for
      widths over 120 and poor comment coverage. Record pre-existing style
      failures separately from regressions.
- [ ] Update `docs/modding.md` with the religion component, per-god module
      paths, prayer command, piety API, signals, and a mod example. Update
      `docs/port-inventory.md` with remaining conduct, ability, gift,
      passive, and wrath coverage.
- [ ] Commit this contiguous category and push `main` to `origin/main`.
