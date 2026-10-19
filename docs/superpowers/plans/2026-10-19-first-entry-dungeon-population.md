# First-entry Dungeon Population Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Populate each generated Dungeon floor when the player first enters it.

**Architecture:** Terrain and paired stairs remain prebuilt. `Level` stores
the generation exclusion cells and initial population count; the Go command
preflight asks the existing Lua population policy to fill an unvisited target
before stair movement. Saves preserve pending floors and their RNG future.

**Tech Stack:** Go, Akara, gopher-lua, embedded Lua rules, Go save records.

**Spec:** `docs/superpowers/specs/2026-10-19-first-entry-dungeon-population-design.md`

## Global Constraints

- Keep all game decisions in embedded Lua; Go coordinates the policy and owns
  level grids, saves, and stair movement.
- Preserve existing fixed scenarios and the validation path for fully
  populated generated snapshots, subject to normal ruleset-hash checks.
- Use a single commit for this population category, then fast-forward and
  push `main` as authorized by the user.
- Follow `AGENTS.md` formatting and comment rules.

## Review Focus

- An unavailable D:1 or D:15 exit must not populate or advance RNG.
- A restored pending floor must populate identically to uninterrupted play.
- Returning to an already populated floor must never duplicate vault items,
  shops, monsters, or ordinary population.
- Spawn exclusions must survive save/restore and reject invalid coordinates.
- A stair landing occupied by an authored vault actor must be resolved before
  moving the player, rather than making travel fail after spending time.

---

### Task 1: Save pending population state

**Files:** `internal/game/level.go`, `internal/game/generation_script.go`,
`internal/game/save.go`, `internal/game/save_restore_levels.go`,
`internal/save/snapshot.go`, `internal/modfs/builtin/policy/save/scenario_levels.lua`,
`internal/game/generated_dungeon_test.go`.

**Interfaces:** `Level.spawnExclusions []point` persists as a level record
field. `initialActors == 0` identifies a pending generated floor; populated
floors retain the existing positive count.

- [ ] Write a failing generated save test for a pending D:2 with exclusions.
- [ ] Run the focused test and observe the missing state or validation error.
- [ ] Store and validate the exclusion coordinates and pending count.
- [ ] Rerun the focused test.

### Task 2: Populate a generated floor at first stair entry

**Files:** `internal/game/populate_script.go`, `internal/game/commands.go`,
`internal/modfs/builtin/policy/population/populate.lua`,
`internal/game/generated_dungeon_test.go`.

**Interfaces:** `g.populateGeneratedLevel(levelID int, entry point) error`
calls `world.populate` for one floor and commits its actor count and
materialized vault records. Initial D:1 population also places the fixed
consumables; later population does not repeat them.

- [ ] Add failing tests for D:1-only startup, first D:2 descent, second
  descent without duplication, and save/restore before D:2 entry.
- [ ] Run those tests and confirm the old eager behavior fails them.
- [ ] Move population into the first-entry flow, using the prepared stair
  destination before the player action runs.
- [ ] Run focused generation, stairs, and save tests.

### Task 3: Verify and integrate the slice

**Files:** `docs/port-inventory.md`, this plan, and the spec.

- [ ] Update coverage wording to distinguish prebuilt terrain from pending
  population.
- [ ] Run `go test` for affected packages, `git diff --check`, `gofmt -d`
  on changed Go files, and `sh scripts/check-go-style.sh`.
- [ ] Review the changed category, commit once, fast-forward local `main`,
  push `origin main`, and verify the checkout is clean.
