# Abyss Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this
> plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the fixed Abyss floor with source-faithful mutable terrain, vaults, encounters,
travel, rune, and saved replay.

**Architecture:** Lua owns every Abyss rule and the effective DES catalog. One saved 80×70 level is
a moving window over the procedural world; Akara owns dynamic entities. The Go kernel only validates
and commits generic grid, record, and entity changes as one reversible operation.

**Tech Stack:** Go, Akara ECS, Gopher Lua, committed layered DES/Lua, JSON saves, Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-23-abyss-domain-design.md`

## Global Constraints

- Work directly on the current Go `main`; use one contiguous Abyss implementation commit after
  whole-domain verification, then push it.
- Keep all 97 source MAP blocks byte-identical and separately replaceable; retain the three mapless
  weighted definitions.
- Keep source DES geometry and directives. Translate executable source lines to named, commented Lua
  hooks at their source positions.
- No Lua source in Go, no build-time importer, no checked-in importer, and no branch-specific content switch in Go.
- Lua functions explain why and how; handwritten lines are at most 120 characters, preferably about
  80; expand multi-field literals.
- Tests for Lua policy live in `_test.lua` files and import production schemas/IDs.
- Preserve independent branch depth, morph depth, phase, exit XP counter, minimum branch depth,
  borrowed layout, and sample queue.

## Review Focus

- A failed map hook or region shift leaves terrain, entities, origin, and RNG unchanged; Task 3
  tests full snapshot equality.
- Repeated banishment from an outside floor keeps the most recent valid origin; Task 4 tests departure and return.
- A protected vault crossing the shifting boundary moves whole or is rejected without clipping; Task 3 tests both cases.
- A rune or unique actor at the discarded edge cannot reappear in the next region; Tasks 3 and 5
  test lifecycle and restore.
- A one-file overlay joins the intended selection pool without depending on directory order; Task 1
  tests sparse addition and replacement.

---

### Task 1: Source vault catalog and hook port

**Files:**
- Create: `internal/modfs/builtin/vaults/abyss/*.des`, `internal/modfs/builtin/vaults/abyss_entry/*.des`.
- Create: `internal/modfs/builtin/policy/generation/vaults/abyss/*.lua` and `abyss_entry/*.lua`.
- Test: `internal/script/testdata/lua/tests/abyss_source_catalog_test.lua`, `abyss_hooks_test.lua`.
- Test: `internal/script/testdata/abyss-mod/` sparse overlay fixture.

**Interfaces:** The existing effective DES catalog supplies sorted definitions by family. Each
committed source `NAME` remains its stable ID. Named Lua hooks use the existing `vault.run`,
`vault.veto`, `vault.validate`, and placement context API; registration is by relative path, never a
central map-name switch.

- [x] Write failing catalog tests for 100 names, 97 exact MAP blocks, three dummies, the first nine
      outside entry maps, source tags/depths/weights, and sparse overlay precedence.
- [x] Split pinned `crawl-ref/source/dat/des/branches/abyss.des` with temporary tooling outside the
      repository; preserve the original MAP bytes and ordinary directives.
- [x] Port each executable DES script site to a named Lua hook, with source-position hook markers
      and a why/how comment on each function.
- [x] Run every definition through the production DES parser and selection/placement path; test both
      outcomes of each conditional hook. Reject malformed overlay hooks before publication.

### Task 2: Terrain sampler and saved procedural state

**Files:**
- Replace: `internal/modfs/builtin/policy/generation/abyss.lua`.
- Create: `internal/modfs/builtin/policy/generation/abyss/state.lua`, `sampler.lua`,
  `wastes.lua`, `worley.lua`, `rivers.lua`, `roiling_chaos.lua`,
  `borrowed.lua`, `features.lua`, and `vaults.lua` in that directory.
- Create: `internal/modfs/builtin/constants/abyss.lua`.
- Create: `internal/noise/{hash,worley,perlin}.go` and the generic Lua math
  bridge in `internal/script/`, if the source sampler needs exact integer or
  cellular arithmetic unavailable in Lua's numeric representation.
- Test: `internal/script/testdata/lua/tests/abyss_{sampler,state,generation}_test.lua`.
- Modify: `internal/save/snapshot.go`, game snapshot/restore owners, `policy/save/abyss_levels.lua`.

**Interfaces:** `abyss.state.new(ctx, entry)` returns a serializable state with `branch_depth`,
`morph_depth`, `phase`, `world_x`, `world_y`, `terrain_seed`, `shift_count`, `sample_queue`,
`borrowed_level_id`, `borrowed_layout`, `exit_xp`, `exit_spawned`, `min_branch_depth`,
`pocket_start`, and transit records. `abyss.sampler.sample(ctx, state, x, y)` returns a terrain
feature and next change point. `abyss.generate(ctx, state)` returns the current level plan and
updated state without publishing either.

- [x] Write failing `_test.lua` vectors for each of the five source sampler families, borrowed-level
      choice, change points, source initial vault-before-proto order, and deterministic draws after
      state restore.
- [x] Implement sampler functions from `crawl-ref/source/abyss.cc`; keep source probabilities,
      spatial scale, and feature precedence in named Lua constants.
- [x] Use the existing DES placement owner for weighted Abyss furniture. Keep outside `enter_abyss`
      maps in the ordinary entry pool.
- [x] Add an explicit Abyss save record and validator. Save the sample queue and borrowed layout,
      restore without terrain generation or an extra RNG draw.

### Task 3: Moving window and atomic region mutation

**Files:**
- Create: `internal/script/grid_region.go`, `internal/game/level_region.go`.
- Modify: `internal/script/runtime.go`, `context.go`, `systems.go`, `internal/game/script_services.go`.
- Create: `internal/modfs/builtin/policy/world/abyss/{shift,morph,transit}.lua`.
- Test: `internal/script/grid_region_test.go`,
  `internal/script/testdata/lua/tests/abyss_shift_test.lua`,
  `internal/game/abyss_region_game_test.go`.

**Interfaces:** A generic `ctx:replace_region(level_id, plan)` stages one complete
grid/visibility/record/stair update and actor/item coordinate moves or retirements. The grid service
validates bounds, unique destinations, live entity ownership, and stair/record coordinates before
applying; its undo restores the prior region. Lua `abyss.shift(ctx, state, player)` uses the source
radius-10 preservation rule and returns an updated state.

- [x] Write failing tests for a preserved vault and actors/items/clouds moving by the same delta;
      reject clipped vaults, blocked actor destinations, malformed records, and a forced error after
      staging, asserting full snapshot/RNG equality.
- [x] Add the generic reversible grid region operation to the existing structural-command
      transaction. Reuse Akara position/ownership and existing region retirement logic; do not add
      Abyss-specific Go policy.
- [x] Implement Lua world-coordinate shift, source protection and transit rules, and fresh-edge
      sampling. Morph eligible cells after source time increments while keeping player-safe terrain.
- [x] Test edge crossing over repeated turns, whole-vault preservation, discarded unique/rune
      lifecycle, and save/restore replay of the next shift.

### Task 4: Entry, depth, exit, rune, and population

**Files:**
- Replace: `internal/modfs/builtin/policy/world/abyss.lua`.
- Create: `internal/modfs/builtin/policy/world/abyss/{entry,travel,exits,rune,depth}.lua`.
- Modify: `internal/modfs/builtin/systems/world_stairs.lua`, `policy/population/populate.lua`,
  character start and Pan travel Lua policies, terminal status/travel projection.
- Test: `internal/script/testdata/lua/tests/abyss_{travel,exits,rune,population}_test.lua`.
- Test: `internal/game/abyss_travel_game_test.go`, `abyss_knight_game_test.go`.

**Interfaces:** `abyss.entry.banish(ctx, actor, origin)` saves the outside site and enters a
generated region. `abyss.entry.pocket_start(ctx, player)` gives an Abyssal Knight a D:1 exit without
a banishment origin. `abyss.travel.descend(ctx, actor)` advances branch depth through level seven.
`abyss.travel.escape(ctx, actor)` uses the saved origin and shared safe landing. The world stair
system delegates to these Lua policies by feature.

- [x] Write failing end-to-end tests for ordinary and monster banishment, Pan's Abyss gate, pocket
      start and D:1 return, branch depths 1–7, force descent, and an occupied origin.
- [x] Implement source depth/exit XP clocks and source exit or downward-stair appearance. Time
      changes morph depth, XP changes the counter, and stairs/banishment change branch depth.
- [x] Select rune vaults or source fallback only at eligible depths; materialize the rune as one
      saved item and suppress future copies after pickup.
- [x] Populate depth-qualified monsters and items through existing ECS factories, respecting source
      weights, uniqueness, saved transit, and the effective layered catalog.
- [x] Route symbols, messages, status labels, and commands through the existing terminal policy. An
      unavailable feature remains visible and explains why.

### Task 5: Save integrity, overlays, snapshots, and whole-domain verification

**Files:**
- Modify: `internal/modfs/builtin/policy/save/abyss_levels.lua`, `policy/save/status.lua`, game
  save/restore validators, `docs/modding.md`, `docs/port-inventory.md`.
- Create: `docs/level-snapshots/abyss/{index,proto,shifted,rune,exit}.txt`.
- Test: `internal/game/abyss_save_game_test.go`, `internal/script/testdata/lua/tests/abyss_overlay_test.lua`.

**Interfaces:** `save.Snapshot.AbyssState` persists the active procedural state; level record ID
1000 stores the current grid and records. Restore rejects inconsistent state before exposing the
game. Text snapshots are produced from seeded, playable generated floors.

- [x] Test exact post-restore next-turn snapshot equality, malformed depth/queue/borrowed
      layout/transit rejection, rune uniqueness, and sparse add/replace overlays.
- [x] Document the mod file paths, DES hook context, source roles, rule override examples, state
      fields, and the moving-window model.
- [x] Capture proto, shifted, rune, and exit text snapshots with connectivity and selected map IDs in the index.
- [x] Run focused Lua, game, terminal, save, build, style, and `git diff --check` once after the
      whole category; fix failures tied to the Abyss domain.
- [x] Obtain one fresh whole-domain review, address Important findings, commit the contiguous
      implementation, and push `main`.
