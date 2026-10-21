# Transporter Gameplay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make source-named `.des` transporters playable and durable.

**Architecture:** Lua pairs all marker records after floor assembly and
stores links in saved marker arguments. Two Go terrain features display
the source and landing cells. Lua navigation and travel rules consume the
same links and validate them on restore.

**Tech Stack:** Go, Akara ECS, GopherLua, committed `.des` maps.

**Spec:** `docs/superpowers/specs/2026-10-20-transporter-gameplay-design.md`

## Global Constraints

- Work directly on Go `main` and push each coherent category to `origin/main`.
- Keep gameplay policy and content in Lua files; Go owns generic terrain and
  context primitives only.
- Comment every new Lua function with why and how. Keep lines at most 120
  characters and split multifield tables across lines.
- Import shared feature, marker, and intent IDs where used.
- Preserve source `.des` maps and do not add inline Lua to Go.

## Review Focus

- Separate subway stations link only after all three maps are placed.
- Multiple sources may share one destination; duplicate destinations fail.
- The landing feature is not itself an outbound transporter.
- A blocked or uninhabitable landing does not spend an action.
- A forged saved coordinate or altered feature cannot redirect a link.
- Repeated use does not reroll generation or change the ruleset hash.

---

### Task 1: Pair and display authored links

**Files:** `policy/generation/transporters.lua`,
`policy/generation/scenario.lua`, `constants/terrain.lua`,
`constants/transporter.lua`, `content/terrain_features.lua`,
`internal/terrain/feature.go`, and Lua/Go generation tests.

**Interfaces:** `transporters.resolve(level)` reads `level.vault_records`,
sets `level.cells`, and adds destination arguments to source markers.

- [x] Add Lua tests for a two-link tutorial, three-station subway, duplicate
      destination, missing/unused name, and overwritten marker.
- [x] Run the focused tests red, implement pairing, and rerun green.
- [x] Add the two Go terrain IDs and their DCSS console glyphs; test feature
      validity, walking, and display.

### Task 2: Player travel and nearby followers

**Files:** `policy/world/transporters.lua`,
`policy/commands/navigation.lua`, `policy/commands/entries_navigation.lua`,
`systems/world_stairs.lua`, `schemas/character_transporter_knowledge.lua`,
`policy/presentation/view.lua`, and Lua command/travel tests.

**Interfaces:** `transporters.prepare(ctx, position)` returns a destination
or a refusal message. `transporters.take(ctx, actor, elapsed_aut)` performs
the checked movement and emits its result.

- [x] Add tests for `<` and `>`, successful movement, blocked terrain,
      occupied landing, eligible and ineligible followers, action cost,
      short translocation cloud, and durable destination knowledge.
- [x] Run focused tests red, implement the Lua travel policy, rerun green.
- [x] Verify transporter travel and stairs share the existing action and
      save pipeline without changing normal stair behavior.

### Task 3: Restore, integration, and documentation

**Files:** `policy/save/transporters.lua`,
`docs/modding.md`, `docs/port-inventory.md`, and game integration tests.

**Interfaces:** `save.validate_transporters(ctx, input)` validates saved
link arguments against marker names and the terrain grid.

- [x] Add restore tests for intact links and forged names, coordinates,
      duplicate destinations, and wrong terrain.
- [x] Run focused tests red, implement validation, rerun green.
- [x] Run an authored-map game test through travel and save/restore.
- [x] Run affected Lua and game suites, `git diff --check`, and style checks.
- [x] Commit this category on `main` and push `origin/main`.

The focused Lua and game suites pass. A combined full-suite run exceeded the
game package's 10-minute timeout while the Lua suite concurrently hit a
procedural-layout context deadline; that layout test passed alone. The
scheduled Temple entry test also fails with the same missing stair link on a
fresh archive of pre-change `HEAD`, so it is not caused by this slice. The
repository-wide Go readability checker reports existing violations outside
the files changed here; changed Go files are formatted and pass its local
checks.
