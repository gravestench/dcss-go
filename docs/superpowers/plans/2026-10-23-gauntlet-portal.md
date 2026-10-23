# Gauntlet Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Ship the full source-backed Gauntlet portal domain with all 60 maps, timed travel, arena encounters, linked transporters, minotaur exits, save safety, and visible floor snapshots.

**Architecture:** Commit each authoritative MAP in an individual DES file, port source script sites to readable Lua hooks, and reuse nested-vault placement, transporters, and staged portal travel. Scoped nested-vault context replaces the source script's module-global tier and arena counter. Akara owns durable gate and visit state.

**Tech Stack:** Go kernel, embedded Lua, Akara ECS, source DES maps, Lua `_test.lua` fixtures, Go integration tests.

**Spec:** `docs/superpowers/specs/2026-10-23-gauntlet-portal-design.md`

## Global Constraints

* Treat pinned `crawl-ref/source/dat/des/portals/gauntlet.des` and `crawl-ref/source/dat/dlua/gauntlet.lua` as behavioral source.
* Keep all 60 MAP blocks byte-identical; commit only generated content, not an importer script.
* Keep script hooks in named Lua files at their source DES positions; no inline Lua in Go.
* Use one Gauntlet domain commit, per the user's contiguous-category preference.
* Every Lua function explains why and how; Go lines stay within 120 characters.
* Run `gofmt`, focused Lua and Go tests, `sh scripts/check-go-style.sh`, and source MAP comparison at the category boundary.

## Review Focus

* A parent with conditional arena tiers must produce the source number and order of choices; test all ten parents under seeds exercising both outcomes.
* A helper with multiple transformed orientations must keep its entry and exit link on the right stations; test transporter routes after rotation.
* A prize with `no_pickup` must still be available to the player and unavailable to monsters; test both actors.
* A save while inside Gauntlet must restore clocks, link targets, visit origin, and pending rewards; compare before and after restore.
* A malformed sparse mod with a missing destination, duplicate link, or absent exit must fail generation without mutating the world or RNG; test each case.

---

### Task 1: Authoritative Gauntlet corpus

**Files:** Create `internal/modfs/builtin/vaults/gauntlet_entry/*.des`, `vaults/gauntlet_arena/*.des`, `vaults/gauntlet_exit/*.des`, `vaults/gauntlet/*.des`, `internal/modfs/builtin/constants/gauntlet.lua`, `internal/script/testdata/lua/tests/gauntlet_source_catalog_test.lua`.

**Interfaces:** The existing catalog discovers `gauntlet_entry`, `gauntlet_arena`, `gauntlet_exit`, and `gauntlet` families by path. Each file exposes one source NAME, full metadata, MAP, and named hook directives. `constants.gauntlet` names family and feature IDs, gate duration, and encounter tags.

- [x] Write the failing Lua catalog test: exactly 60 source names, one entrance, 43 arenas, six exits, ten parents; every MAP byte matches source; ID order is stable under VFS overlays.
- [x] Run `go test ./internal/script -run '^TestLuaRules/gauntlet_source_catalog_test.lua$' -count=1`; confirm failure from absent maps.
- [x] Extract all MAP blocks with a disposable local script. Convert source script sites to `HOOK_RUN` or `HOOK_VALIDATE` without changing MAP bytes. Remove the extraction script after generation.
- [x] Rerun the catalog test and compare a sorted `name SHA-256(MAP)` manifest with pinned source.

### Task 2: Scoped nested-vault state and source encounter rules

**Files:** Modify `internal/modfs/builtin/policy/generation/vaults/operations.lua`; create `internal/modfs/builtin/policy/generation/vaults/gauntlet_arena/shared.lua`, `vaults/gauntlet/shared.lua`, `vaults/gauntlet_exit/*.lua`, and focused Lua tests.

**Interfaces:** A child hook reads its selected `SUBVAULT` tag, ordinal, and parent-scoped values through generic vault API methods. The parent controls only this placement's context. `gauntlet_arena.shared.setup(api)` emits source item, monster, trap, wall, liquid, and plant operations; it never stores state in the module.

- [x] Write failing Lua tests for first and second tier encounters, conditional parent choices, tier-specific item slots, source monster weights, and two independent generations without leaked state.
- [x] Run focused Lua tests; confirm missing nested context and hooks.
- [x] Add generic nested context to `operations.apply` and `hook_api`; carry it only through the selected child call. Keep other families' behavior unchanged.
- [x] Port the two source encounter tables and setup procedures into commented Lua modules; implement all source script sites, including dead-adventurer loot and exit validation.
- [x] Rerun focused tests for all ten parents and 43 arena helpers.

### Task 3: Staged Gauntlet floor and portal lifetime

**Files:** Create `policy/generation/gauntlet/level.lua`, `policy/world/gauntlet/{portal,travel}.lua`, `policy/world/portals/handlers/gauntlet.lua`, `schemas/{world_gauntlet_portal,character_gauntlet_visit}.lua`, `systems/world_gauntlet_portals.lua`; modify `policy/generation/scenario.lua`, shared portal registry, constants, and save validators.

**Interfaces:** `world.generate_gauntlet_level(ctx, input)` returns the one generated floor. The portal handler materializes the source timed marker and prepares entry/exit. `world.gauntlet.commit_travel` commits an accepted staged move. Components store the outside gate deadline and exact return site.

- [x] Write failing tests for gate placement and 400–600-turn duration, world-clock expiry, one-time entry, exact return, floor retirement, save/restore, and failed-generation rollback.
- [x] Run focused tests; confirm missing domain policies.
- [x] Implement Lua generator and portal policies using existing staged transaction and transporter resolution. Keep Gauntlet teleport restriction in Lua game policy.
- [x] Validate all saved Gauntlet component references and resolved transporter links during restore.
- [x] Rerun focused Lua and Go integration tests.

### Task 4: Complete population and visible verification

**Files:** Extend Gauntlet Lua tests and Go integration tests; create `docs/level-snapshots/gauntlet/{index.txt,<parent-id>.txt}`; update `docs/ecs-architecture-roadmap.md` and modding guide where new nested context is exposed.

**Interfaces:** Each snapshot shows the full generated floor, selected helper IDs, exit, minotaur, arena tiers, and transporter source→destination index. Sparse mods may replace one parent, arena, or exit by relative path.

- [x] Add tests for all 60 maps, ten parent floors, both tier outcomes, player prize pickup, retained monster no_pickup source flags, exit connectivity, and sparse add/replace overlays. Monster floor-item pickup remains in the future monster AI domain.
- [x] Generate deterministic text snapshots for every parent floor; inspect floor bounds, links, and visible route topology.
- [x] Run source MAP comparison, focused Go/Lua tests, `gofmt`, and `sh scripts/check-go-style.sh`. Fix changed-file violations; report unrelated existing failures accurately.
- [x] Mark plan tasks complete, commit this whole Gauntlet category once, and push `main` to the fork.
