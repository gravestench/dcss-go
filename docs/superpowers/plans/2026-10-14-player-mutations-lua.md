# Player Mutations in Lua Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan. Use the checkboxes to
> track work. The user's category preference requires one mutation-domain
> commit after integrated verification.

**Goal:** Port source mutation acquisition, consequences, saves, and display
through Lua and ECS, then complete Violent Unravelling.

**Architecture:** Commit one source-traced Lua definition per mutation.
Akara records own all real player mutation levels; Lua owns selection,
transitions, capability effects, and presentation. Go retains only generic
ECS, save, grid, RNG, and terminal services.

**Tech Stack:** Go 1.25, Akara, GopherLua, Bubble Tea v2, embedded Lua.

**Spec:** `docs/superpowers/specs/2026-10-14-player-mutations-lua-design.md`

## Global Constraints

- Source revision: `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Commit generated Lua and never import C++ content during builds or play.
- No Go mutation-ID switch, parallel rule path, inline Lua, or adapter.
- One field per line in multi-field literals; maximum 120 columns.
- Use `_test.lua` with production schemas for Lua rule tests.
- One mutation-domain commit after broad verification.

## Review Focus

1. A mod definition imports an ID declared later: resolve after discovery
   and reject a missing final ID with its originating file.
2. Two records for one player/mutation pair in a save: reject at restore.
3. A form suppresses a body mutation: effective level changes without
   deleting its saved base level.
4. A conflict trades or removes levels: preserve source table order and RNG.
5. Unravelling explodes beside the caster: apply durable malmutation and
   damage, then restore the same state and RNG continuation.

---

### Task 1: Source catalog and mod contract

**Files:**
- Create: `scripts/import-mutations.py`
- Create: `internal/modfs/builtin/content/mutations/*.lua`
- Create: `internal/modfs/builtin/ids/mutations.lua`
- Create: `internal/modfs/builtin/data/mutation_enum.lua`
- Modify: `internal/modfs/builtin/constants/catalog.lua`
- Modify: `internal/modfs/builtin/content/validation.lua`
- Test: `internal/script/testdata/lua/tests/mutation_catalog_test.lua`
- Test: `internal/script/testdata/lua/tests/mutation_enum_test.lua`
- Test: `internal/script/lua_rules_test.go`

**Interfaces:** `catalog.get("mutations", id)` returns one immutable
definition; `ids.mutations.MUT_*` resolves through the existing deferred ID
registry. The importer accepts `--check` and writes only committed Lua.

- [x] Test source active/removed identity and order, duplicate/malformed
  overlay rejection, and a new one-file mutation definition.
- [x] Parse the pinned enum and table, filtering source conditionals;
  emit definitions with provenance comments and gameplay-only fields.
- [x] Add validation for status, weight, levels, use flags, description
  lengths, and required behavioral registration metadata.
- [x] Run the importer `--check` and catalog tests.

### Task 2: Authoritative mutation records

**Files:**
- Create: `internal/modfs/builtin/schemas/character_mutation.lua`
- Create: `internal/modfs/builtin/schemas/character_mutation_timer.lua`
- Create: `internal/modfs/builtin/policy/mutations/records.lua`
- Create: `internal/modfs/builtin/policy/mutations/levels.lua`
- Create: `internal/modfs/builtin/policy/mutations/temporary.lua`
- Modify: `internal/modfs/builtin/policy/character/start.lua`
- Modify: `internal/modfs/builtin/policy/character/advancement.lua`
- Modify: `internal/modfs/builtin/schemas/character_origin.lua`
- Modify: `internal/modfs/builtin/policy/save/player.lua`
- Test: `internal/game/player_mutation_state_test.go`
- Test: `internal/script/testdata/lua/tests/mutation_records_test.lua`
- Test: `internal/script/testdata/lua/tests/mutation_temporary_test.lua`

**Interfaces:** `records.find(ctx, owner, id)`, `.grant_innate(ctx, owner,
id, count)`, `.grant_acquired(ctx, owner, id, count)`,
`.grant_temporary(ctx, owner, id, count, progress)`, and
`.delete(ctx, owner, id, class)` own state changes. `levels.base` and
`levels.effective` are the only gameplay reads. A player timer owns one XP
countdown shared by all temporary records, and awarded XP advances it.

- [x] Test character creation, scheduled innate level-up, temporary and
  acquired levels, duplicate saved record rejection, and save continuation.
- [x] Implement one record per owner/ID, remove opaque origin mutation
  strings, and route all existing mutation-level readers through `levels`.
- [x] Run state, start, advancement, and restore tests.

### Task 3: Selection, conflicts, and transitions

**Files:**
- Create: `internal/modfs/builtin/data/mutation_conflicts.lua`
- Create: `internal/modfs/builtin/policy/mutations/selection.lua`
- Create: `internal/modfs/builtin/policy/mutations/conflicts.lua`
- Create: `internal/modfs/builtin/policy/mutations/transition.lua`
- Create: `internal/modfs/builtin/policy/mutations/malmutate.lua`
- Test: `internal/script/testdata/lua/tests/mutation_transition_test.lua`
- Test: `internal/game/player_mutation_transition_test.go`

**Interfaces:** `transition.grant(ctx, player, id, class, forced)` and
`.remove(ctx, player, id, class)` return explicit results. The classes are
named constants for innate, acquired, and temporary. `malmutate.apply`
uses source weighted selection and the saved `mutation` RNG stream.

- [x] Test pinned source conflict vectors, resistance, physiology, max
  levels, failed grants, forced replacement, and RNG continuation.
- [x] Implement source selection and acceptance in Lua with the ordered
  conflict table. Keep validation, selection, mutation, and messages distinct.
- [x] Run transition tests before connecting gameplay callers.

### Task 4: Every active mutation consequence

**Files:**
- Create focused modules under `internal/modfs/builtin/policy/mutations/effects/`
- Modify consumers under `policy/character/`, `policy/combat/`,
  `policy/inventory/`, `policy/magic/`, `policy/world/`, and `systems/`.
- Test: `_test.lua` files beside the mutation effect families.
- Test: `internal/game/player_mutation_effects_test.go`

**Interfaces:** Uniform scalar properties are read from definitions;
behavioral effects register named Lua functions by mutation ID and capability.
Every active selectable definition has one complete consequence path.

- [x] Add coverage asserting all active definitions are implemented and
  removed IDs cannot be granted.
- [x] Test source vectors for stats, HP/MP, resistances, speed, body slots,
  attacks, regeneration, senses, magic, passive turn effects, and abilities.
- [x] Implement those families in focused Lua files and convert existing
  consumers to the effective level API. Complete dependent generic behavior
  rather than changing source selection weights.
- [x] Run focused effect tests and representative whole-turn tests.

### Task 5: Unravelling and presentation

**Files:**
- Modify: `internal/modfs/builtin/policy/magic/effects/zaps/unravelling.lua`
- Modify: `internal/modfs/builtin/policy/presentation/`
- Modify: `internal/game/player_spell_coverage_test.go`
- Test: `internal/game/player_mutation_unravelling_test.go`
- Test: `internal/terminal/player_mutation_screen_test.go`

**Interfaces:** The spell calls `malmutate.apply` for its caster blast. The
mutation screen projects records and source descriptions through Lua UI
policy; Go renders the generic terminal rows.

- [x] Test no-time rejection, enchanted and summoned targets, monster and
  self-hit blast effects, save/restore, and source-shaped mutation display.
- [x] Register Unravelling only after self-hit malmutation and all affected
  domains are operational; make spell coverage expect zero missing effects.
- [x] Run the spell, mutation, save, and terminal tests together.

### Task 6: Integrated verification and category commit

**Files:**
- Update: `docs/port-inventory.md`
- Update: `docs/modding.md`
- Update: `docs/ecs-architecture-roadmap.md`

- [x] Review all active source mutations against the generated catalog and
  effect coverage, with no unimplemented selectable entry.
- [x] Run `go build ./...`, `go vet ./...`, `sh scripts/check-go-style.sh`,
  importer `--check`, `git diff --check`, and the relevant broad tests. Use
  a timeout long enough for the expanded Lua catalog and report exact gaps.
- [ ] Commit the whole mutation category once, then review the branch and
  merge into local `main` only after integrated verification.
