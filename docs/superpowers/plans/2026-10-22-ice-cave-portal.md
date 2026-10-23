# Ice Cave Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking. The user chose native execution
> and authorized taking recommendations without another approval pause.

**Goal:** Make all 15 source Ice Cave entrances and 11 easy/hard destination
maps one playable, timed, saved portal domain.

**Architecture:** Individually replaceable DES files own geometry and
directive order. Named Lua hooks own source decisions, including the saved
easy/hard choice. An Akara gate carries that choice into a whole-floor Lua
generator; the generic staged portal transaction owns rollback and travel.
Go adds only neutral terrain, save, and terminal integration.

**Tech Stack:** Embedded Lua, source DES, Akara ECS, Go grid/save services,
Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-22-ice-cave-portal-design.md`

## Global Constraints

- Preserve all 26 source `NAME` identities, MAP bytes, static directives,
  depth rules, weights, and source-position decision order.
- The source entrance draws one 600–800-turn clock and saves hard difficulty
  from its origin branch. Destination generation never redraws either.
- Normal builds and tests use committed assets. No importer or C++ checkout
  is needed in the runtime or ordinary test path.
- Hook code lives in commented `.lua` files, never Go strings. Keep the
  source script as explanatory DES comments until DES-local Lua is ready.
- Use Akara ECS for gate and visit state; keep terrain in the existing grid.
  No Ice Cave-specific Go travel path or ID switch is allowed.
- Work on `main` per the user's latest direction, verify the full slice,
  make one contiguous Ice Cave commit, and push `origin main`.
- Do not use the exhaustive 855-test game package as the slice gate: the
  baseline `TestEveryLegalCharacterStartReachesDungeon` exceeded 25 minutes
  during full runtime initialization. Run focused integrated tests and
  report this broader suite limit separately.

## Review Focus

1. A D:13 gate is easy and a D:14 gate is hard even if entered after other
   branch travel. Task 3 pins saved difficulty and restore behavior.
2. A source child with complex fog or transporter markers must populate
   through the live owner, not merely retain text. Tasks 1 and 2 test both.
3. An entrance expiring on an inactive floor must close once; last-turn
   accepted travel still completes. Task 3 tests the action order.
4. Failed child placement or a blocked outside return must preserve RNG,
   gate, player, floor set, and actors. Task 3 tests both paths.
5. A modded child with zero weight, bad geometry, or broken hook must fail
   without changing saved state. Task 4 tests effective-catalog failures.

## File Map

- `internal/modfs/builtin/vaults/{ice_cave_entry,ice_cave}/*.des`:
  15 entrance and 11 destination source definitions.
- `internal/modfs/builtin/policy/generation/vaults/{ice_cave_entry,ice_cave}/*.lua`:
  shared source helpers and readable named local hooks.
- `internal/modfs/builtin/policy/generation/ice_cave/level.lua`:
  weighted effective child selection and whole-floor publication.
- `internal/modfs/builtin/policy/world/ice_cave/{portal,travel}.lua` and
  `internal/modfs/builtin/systems/world_ice_cave_portals.lua`:
  marker materialization, source timer, and staged travel callbacks.
- `internal/modfs/builtin/schemas/{world_ice_cave_portal,character_ice_cave_visit}.lua`,
  `internal/modfs/builtin/constants/{ice_cave,component,terrain}.lua`,
  `internal/modfs/builtin/ids/branches.lua`, and
  `internal/modfs/builtin/content/terrain_features.lua`:
  named IDs, state, and feature decoding.
- `internal/modfs/builtin/policy/save/{ice_cave_portals,ice_cave_levels,generated_levels}.lua`,
  `internal/modfs/builtin/policy/generation/scenario.lua`,
  `internal/game/save_restore_components.go`, `internal/terrain/feature.go`,
  and `internal/terminal` terrain presentation:
  generic registration and reciprocal restore checks.
- `internal/script/testdata/lua/tests/ice_cave_*_test.lua`, focused
  `internal/game/ice_cave_*_test.go`, terrain and terminal tests, and
  sparse mod fixtures: source and runtime verification.
- `internal/script/testdata/ice-cave-source-map-digests.txt`:
  pinned MAP digests without a build-time C++ dependency.
- `docs/level-snapshots/ice-cave/`, `docs/modding.md`, and
  `docs/port-inventory.md`: 22 variant snapshots, connection index,
  mod contract, and exact coverage.

---

### Task 1: Source Corpus and Lua Hooks

**Interfaces:** Each DES file registers one source identity. Each
`vault.run` hook consumes the production vault API and emits typed
directives and records in source order. No hook stores mutable session
state in a module global.

- [ ] Write `ice_cave_source_catalog_test.lua`: assert 15 entrances,
  11 encompassing children, all source depth pools and weights, marker
  and hook order, and committed MAP digests. Add hook tests for both
  difficulties, monster sets, equipment, loot, fog, transporters, and
  feature names, importing production IDs and modules.
- [ ] Run `go test ./internal/script -run 'TestLuaRules/ice_cave' -count=1`
  and verify that the absent corpus and hooks fail.
- [ ] Split the pinned `icecave.des` into 26 DES files with identical MAP
  blocks. Port common `ice_cave_portal`, appearance, simulacrum, natural
  and undead/demon, loot, and freezing-vapour helpers into documented Lua.
  Port each source conditional at its original directive position.
- [ ] Run the focused Lua test until the full source catalog and hooks
  pass; inspect each MAP digest and directive audit.

### Task 2: Easy/Hard Whole-Floor Generation

**Interfaces:** `policy.generation.ice_cave.level.candidates(player)`
returns positive-weight effective IceCv children in stable ID order.
`level.generate(ctx, input)` consumes `input.hard` and optional
`input.layout_id`, and returns one uninstalled `{ level = ... }` with
authored terrain, typed records, entities, safe arrival, and live exit.

- [ ] Write `ice_cave_generation_test.lua` and
  `TestIceCaveAllSourceMapsPopulate`. Generate all 11 children through
  production placement in both variants; check exit reachability,
  source monsters, items, fog, transporter links, and saved vault ID.
  Reject empty effective pools and ineligible requested IDs.
- [ ] Run focused Lua and game tests; verify red on missing generator.
- [ ] Register `world.generate_ice_cave_level` in `scenario.lua`. Add the
  IceCv generator using existing weighted effective catalog selection,
  whole-floor placement, feature projection, and vault population.
  Carry hard difficulty only from the saved gate input.
- [ ] Run the same focused tests; verify all 22 variant placements and
  no direct Go content branching.

### Task 3: Timed Gate, Travel, and Save Invariants

**Interfaces:** `policy.world.ice_cave.portal.materialize(ctx, level,
record)` creates one ECS gate from the fixed source marker and origin
difficulty. `portal.at(ctx, level_id, x, y)` finds that exact gate.
`world.ice_cave.commit_travel` is the Lua callback used by generic
`luaPortal` staging.

- [ ] Write `ice_cave_portal_messages_test.lua` and integrated game
  tests for the 600–800-turn draw, easy/hard origin, audible discovery,
  five speed bands, final warning, Silence, off-floor expiry, last-turn
  entry, exact return, blocked return, rollback, retirement, and restore.
  Forge missing marker, wrong difficulty/deadline, changed feature,
  missing exit, and mismatched return pointer; assert rejection.
- [ ] Run focused tests and verify red on absent portal ownership.
- [ ] Add Ice Cave entrance/exit terrain, constants, gate and visit
  schemas, marker materialization, action-time system, Lua travel policy,
  and save validators. Route both terrain features through the generic
  staged portal transaction. Spend the gate only after staging succeeds;
  preserve distinct entry and expiry closure reasons.
- [ ] Run focused Lua, game, terrain, and terminal tests. Confirm
  saved state and RNG equality across each rejected transaction.

### Task 4: Mods, Snapshots, Documentation, and Category Gate

**Interfaces:** A sparse mod-added IceCv child joins by effective branch
and weight; same-path DES and Lua replacements supersede only that path.
The snapshot exporter uses production generation with a fixed outside
site and labels both difficulty variants.

- [ ] Add sparse added-map, same-path replacement, zero-weight pool,
  too-wide map, and malformed-hook fixtures. Assert effective-catalog
  selection or clear early rejection with unchanged saved state.
- [ ] Extend the opt-in text-snapshot helper to export all 22 production
  map variants and a connection index. Verify every exit points to the
  exact outside cell, then commit the readable snapshots.
- [ ] Document Ice Cave authoring and the saved difficulty/clock in
  `docs/modding.md`; record exact source coverage and any wider gameplay
  gaps in `docs/port-inventory.md`.
- [ ] Run focused integrated Lua, game, terrain, and terminal verification,
  `sh scripts/check-go-style.sh`, `gofmt` on changed Go, and
  `git diff --check`. Review source parity, rollback, save invariants,
  snapshots, and final diff. Commit the whole Ice Cave category and push.
