# Volcano Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking. The user chose native execution
> and authorized taking recommendations without another approval pause.

**Goal:** Port all 34 source Volcano definitions as one playable, timed,
saved portal domain with live eruption, collapse, and lava-overflow effects.

**Architecture:** Source DES owns geometry and directive order; named Lua
hooks own content decisions. Existing Akara portal, fog, cloud, and staged
floor patterns carry generic state. Focused Lua Volcano components own the
two timed terrain events. Go adds neutral feature, staging, and save wiring.

**Tech Stack:** Embedded Lua, source DES, Akara ECS, Go terrain/save,
Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-22-volcano-portal-design.md`

## Global Constraints

- Preserve all 34 active source `NAME` identities: 11 entrances, 14
  top-level destinations, and nine nested helpers. Keep every MAP byte.
- Ordinary builds use committed DES and Lua only. Source extraction is
  one-time and never joins the build or runtime path.
- Every source Lua site runs through a documented Lua file, never a Go
  string. Keep modules small, with commented functions and assigned methods.
- Akara owns clocks, visit, fog, and event phase. Dense level grids own
  mutable terrain. No Volcano-only Go command or destination switch.
- Work directly on `main`, make one contiguous Volcano product commit, and
  push `origin main` after the category is verified.
- Verify the complete category rather than every minor edit. Report the
  known exhaustive script-suite timeout separately from focused checks.

## Review Focus

1. A chained `V` group emits at all authored positions from one saved
   clock; Task 2 tests simultaneous clouds and restored next firing.
2. A source cave-collapse marker occupied by the player remains open and
   available; Task 4 tests it beside an ordinary collapsed marker.
3. Overflow cannot turn the player's current cell into lava, and phases
   7–9 harden only earlier converted groups; Task 4 tests all nine phases.
4. Multi-exit source maps retain every return arch and exact outside cell;
   Tasks 2, 3, and 5 verify travel and the snapshot index.
5. A failed modded map or a forged hazard phase cannot leave partial
   terrain, RNG, gate, or visitor changes; Tasks 4 and 5 test rollback.

## File Map

- `internal/modfs/builtin/vaults/{volcano_entry,volcano}/*.des`:
  individually replaceable source definitions.
- `internal/modfs/builtin/policy/generation/vaults/{volcano_entry,volcano}/*.lua`:
  source-position hooks, shared loot, guardians, fog, and helper choices.
- `internal/modfs/builtin/policy/generation/volcano/level.lua` and
  `internal/modfs/builtin/policy/generation/scenario.lua`:
  effective weighted selection and an uninstalled whole-floor record.
- `internal/modfs/builtin/policy/world/volcano/{portal,travel,hazards}.lua`,
  `internal/modfs/builtin/systems/world_volcano_*.lua`, and
  `internal/modfs/builtin/schemas/{world_volcano_*,character_volcano_visit}.lua`:
  gate, visitor, eruption groups, collapse, and overflow state.
- `internal/modfs/builtin/policy/world/{fog_machines,fog_machine_definitions}.lua`,
  `internal/modfs/builtin/schemas/world_fog_machine.lua`, and
  `internal/modfs/builtin/policy/save/fog_machines.lua`, and
  `internal/modfs/builtin/policy/clouds/placement.lua`:
  synchronized fog firing, named warnings, and `no_cloud_gen` enforcement.
- `internal/modfs/builtin/policy/population/vaults.lua`,
  `internal/modfs/builtin/constants/rng_streams.lua`, and
  `internal/game/commands.go`:
  hazard materialization, named RNG stream, and generic accepted-action
  policy wiring.
- `internal/modfs/builtin/policy/save/{volcano_portals,volcano_levels,volcano_hazards}.lua`,
  `internal/modfs/builtin/policy/save/generated_levels.lua`, and
  `internal/game/save_restore_components.go`:
  marker/clock, reciprocal visit, and phase/terrain restore invariants.
- `internal/modfs/builtin/constants/{component,terrain,volcano}.lua`,
  `internal/modfs/builtin/content/terrain_features.lua`,
  `internal/terrain/feature.go`, `internal/terminal`,
  `internal/modfs/builtin/policy/commands/navigation.lua`:
  named feature IDs, travel command, and presentation.
- `internal/script/testdata/lua/tests/volcano_*_test.lua`,
  `internal/game/volcano_*_test.go`, sparse mod fixtures,
  `docs/level-snapshots/volcano/`, `docs/modding.md`, and
  `docs/port-inventory.md`: category tests and user-facing contract.

---

### Task 1: Source Corpus and Readable Lua Hooks

**Interfaces:** `vaults/volcano_entry/<NAME>.des` and
`vaults/volcano/<NAME>.des` retain source names and MAP rows.
`vault.run("<module>.<method>")` calls a named local Lua handler at the
source position. Handlers emit production typed directives via the vault API.

- [ ] Write `volcano_source_catalog_test.lua` to assert 11/14/9 map roles,
  source MAP digests, depth and chance rules, helper tags and weights,
  and valid hook references. Run
  `go test ./internal/script -run 'TestLuaRules/volcano_source_catalog'`
  and record the missing-source failure.
- [ ] Split `crawl-ref/source/dat/des/portals/volcano.des` with a temporary
  one-time tool outside the repository. Keep original static directives and
  source-position hook order. Compare each committed MAP byte-for-byte
  against the pinned source, then discard the tool.
- [ ] Add named Lua modules for `volcano_portal`, `volcano_setup`, fiery
  guardians, source loot, all map-specific conditionals, and the nine
  helper choices. Test source item and monster resolution in
  `volcano_hooks_test.lua`, importing production IDs and schemas.
- [ ] Run focused source and hook tests until all 34 source definitions
  parse and all emitted directives resolve. Do not stop at catalog parsing;
  every source entrance and helper must place and populate.

### Task 2: Destination Generation and Fog Events

**Interfaces:** `policy.generation.volcano.level.candidates(player)`
returns effective `{id, weight}` top-level choices in stable ID order.
`level.generate(ctx, input)` accepts optional `layout_id` and returns
`{level = record}` for the generic staging owner. Fog groups and listener
names are immutable marker input; Akara stores mutable clocks and warning
state.

- [ ] Write `volcano_generation_test.lua` and
  `TestVolcanoAllSourceMapsPopulate`. Exercise all 14 top-level maps and
  nine helpers through production placement/population; count every exit,
  and reject zero-weight or over-wide choices. Run the focused tests and
  verify missing generator and fog behavior fail.
- [ ] Register `world.generate_volcano_level` in `scenario.lua`, using
  existing weighted catalog, `SUBVAULT`, whole-floor placement, feature
  projection, and Akara population. Preserve source draw order and source
  records through staging.
- [ ] Extend fog materialization and firing to group source chained
  markers under one clock and dispatch named listener methods for warning
  at 30 aut before firing and at firing. Keep the listener's warning flag
  saved. Enforce `no_cloud_gen` in the generic cloud placement owner.
  Test source flame, smoke, steam, rain, synchronized positions, and
  uninterrupted versus restored next firing.
- [ ] Run focused Lua and Go generation/fog checks. Inspect source MAP
  digests, all helper IDs, every generated return exit, and typed records.

### Task 3: Entrance Clock, Travel, and Reciprocal Saves

**Interfaces:** `policy.world.volcano.portal.materialize(ctx, level,
record)` creates one `world.volcano_portal`; `portal.at(ctx, level_id,
x, y)` finds its exact cell. `world.volcano.prepare_travel` and
`world.volcano.commit_travel` use the generic staged transaction.
`world.generate_volcano_level` consumes the gate's saved selection context.

- [ ] Write focused Lua clock/message tests and Go
  `TestVolcanoEntrySaveAndExit`, `TestVolcanoGateExpiresOnInactiveFloor`,
  `TestVolcanoLastTurnEntry`, and forged-clock/visitor restore cases.
  Run them red against the missing gate and travel policies.
- [ ] Add Volcano feature IDs, Akara portal and visit schemas, Lua timer
  system, command navigation, terminal mapping, generation wiring, and
  reciprocal save validation. Preserve source 600–800-turn draw, heat,
  rumbling, disappearance messages, hearing, and closure reason.
- [ ] Run the focused tests green. Check exact outside-cell return,
  multi-exit travel, blocked return without action cost, failed stage
  rollback, and a save/restore across the gate deadline.

### Task 4: Cave Collapse and Overflow Phases

**Interfaces:** `policy.world.volcano.hazards.advance(ctx, input)`
advances only the active Volcano floor. Separate Akara components own
`volcano_caves` remaining marker indices and countdown, and
`volcano_overflow` marker groups, phase, and countdown. Level cells own
their current terrain; marker records own immutable source positions.

- [ ] Write `volcano_hazards_test.lua` for 50–200-aut collapse ticks,
  one random `M` choice, occupied-marker refusal, messages, smoke,
  200–400-aut overflow ticks, phases 1–9, and reverse hardening.
  Add Go save/restore and forged-phase cases. Run them red.
- [ ] Implement source-position hazard markers in Lua hooks, materialize
  their Akara owners during normal vault population, and register one
  Lua system on accepted action time. Use a named Volcano RNG stream;
  preserve deterministic event ordering against fog and return.
- [ ] Validate hazard component state against source record indices,
  current phase, countdown, and grid terrain. Retire event state with
  its floor. Run focused Lua and Go hazard tests green, including a
  restore immediately before each lava phase.

### Task 5: Mods, Snapshots, Documentation, and Category Gate

**Interfaces:** A sparse mod can add one `vaults/volcano/*.des` or replace
one same-relative-path file. The effective catalog owns selection; the
test snapshot exporter reads actual staged source floors.

- [ ] Add sparse add, same-path replace, zero-weight, too-wide, and
  malformed-hook fixtures and integration tests. Assert real geometry,
  typed content, source errors, and unchanged saved state on failure.
- [ ] Generate `docs/level-snapshots/volcano/` from all 14 top-level
  live floors. Index every `<` and `I` connection to the exact test gate,
  and list selected helper IDs. Check the index against actual exit counts.
- [ ] Update `docs/modding.md` with source paths, hook APIs, timer and
  hazard component fields, policy boundaries, and add/replace examples.
  Update `docs/port-inventory.md` with exact coverage and any remaining
  wider gameplay gaps.
- [ ] Run focused script, game, terrain, and terminal category checks;
  run `git diff --check` and the style checker on changed files. Explain
  any broader-suite timeout without claiming full-suite success.
- [ ] Get one fresh whole-category review, resolve actionable findings,
  make one Volcano category commit, push `origin main`, and confirm clean
  status and matching remote ref.
