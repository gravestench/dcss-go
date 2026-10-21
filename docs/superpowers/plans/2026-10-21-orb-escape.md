# Orb Escape Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the live Orb of Zot lead to a saved escape run and a real Dungeon win.

**Architecture:** Lua owns player endgame phase, rune gate, pickup, exit, and defender selection. Go carries a generic terminal stair marker through levels and saves, projects outcome to the client, and stops finished turns.

**Tech Stack:** Go, Akara ECS, embedded Lua, Go save snapshots, Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-21-orb-escape-design.md`

## Global Constraints

- Work directly on `main`, as explicitly requested, and push the completed category.
- Keep all rules and monster choices in Lua; no inline Lua in Go.
- Source-specific constants and names come from shared Lua modules.
- Give every Lua function explanatory comments; keep lines at or below 120 characters.
- Commit this contiguous endgame slice as one implementation commit.

## Review Focus

- A save from this ruleset must restore D:1's exit without changing its generated floor.
- A refused Zot entrance must not roll generation RNG.
- A restored escaping player must not receive a second Orb or restart spawn timing.
- A blocked spawn ring must leave the run playable and the saved RNG deterministic.
- A finished game must reject another timed command without mutating the save.

---

### Task 1: Player phase and Orb pickup

**Files:** `internal/modfs/builtin/schemas/player_endgame.lua`, `policy/character/endgame.lua`, `systems/item_pickup.lua`, `policy/character/start.lua`, `constants/component.lua`, `internal/game/orb_escape_test.go`.

**Interfaces:** `endgame.phase(ctx, player)` and `endgame.take_orb(ctx, player, item)`; the saved player component has one phase string.

- [ ] Add a failing integrated pickup test using a real Orb item entity and a generated Hall continuation.
- [ ] Run the focused test and confirm the current generic pickup fails its assertions.
- [ ] Implement the Lua phase owner and special pickup, consuming the floor entity.
- [ ] Verify pickup, message, component save/restore, and no carried Orb stack.

### Task 2: Zot rune gate and Dungeon exit

**Files:** `policy/commands/navigation.lua`, `policy/commands/entries_navigation.lua`, `systems/world_stairs.lua`, `policy/generation/generated_stairs.lua`, `policy/save/generated_levels.lua`, Go `StairLink` and save projection, terminal outcome projection, and focused Go/Lua tests.

**Interfaces:** a generic `StairLink.Exit`/`StairRecord.Exit` flag marks a terminal destination; Lua endgame phase sets `won` or `left`.

- [ ] Write failing tests for three-rune first entry, free refusal, confirmed Orb-less exit, Orb win, save restore, and stopped turns.
- [ ] Run focused tests and inspect the expected failures.
- [ ] Add the exit marker through level generation, save, restore, Lua stair projection and validation.
- [ ] Add Lua command and stair rules; project a generic outcome in Go, and finish the turn before monster scheduling.
- [ ] Verify live travel, save continuation, and both terminal outcomes.

### Task 3: Orb-run defenders

**Files:** `policy/character/orb_run.lua`, `systems/world_orb_run.lua`, shared Lua constants, `internal/script/testdata/lua/tests/orb_run_test.lua`, and integrated Go test.

**Interfaces:** one Lua system reads the saved phase and crossed 50-aut boundaries, selects a defender, and calls the existing monster factory.

- [ ] Write failing Lua and integrated tests for timing, category weights, legal near-player placement, blocked cells, and restore.
- [ ] Verify the tests fail for missing run behavior.
- [ ] Implement source spawn draws in focused Lua functions and create actors through `policy.population.factory`.
- [ ] Verify focused tests and seeded save continuation.

### Task 4: Client, guide, and category verification

**Files:** `internal/terminal/app.go`, `internal/terminal/play_input.go`, `policy/presentation/help.lua`, `docs/modding.md`, `docs/port-inventory.md`, and terminal tests.

**Interfaces:** view outcome `won`/`left` selects a distinct terminal screen; Enter returns to startup.

- [ ] Write failing terminal tests for win and leave screens.
- [ ] Implement the distinct presentation and route.
- [ ] Document endgame mod points and update the port inventory truthfully.
- [ ] Run focused Lua tests, integrated Go tests, `go test ./...`, and `sh scripts/check-go-style.sh`; inspect and report unrelated preexisting failures.
- [ ] Review the entire diff, commit the category once, and push `main`.
