# Door Interaction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make explicit `O`/`C` door interaction work on generated Dungeon floors.

**Architecture:** Keep door terrain and connected groups in `Level`; use an
Akara intent and door system for turn actions; keep terminal direction
selection as a view of nearby door cells.

**Tech Stack:** Go, Akara ECS, Bubble Tea, current Go JSON save format.

**Spec:** `docs/superpowers/specs/2026-10-14-door-interaction-design.md`

## Global Constraints

- Match the pinned 10-aut ordinary turn for successful opening and closing.
- Invalid selections and visible blockers do not spend time or draw RNG.
- A blocked unseen monster costs one turn without closing the door.
- Push floor items outside the whole door group before closing it.
- Preserve the 120-column maximum and readable spacing in handwritten Go.
- Commit one contiguous category after integrated verification.

## Review Focus

- Two adjacent cells of one connected door still ask for direction, as the
  source's adjacent-cell count does.
- A large door refuses closure if one segment is blocked or jammed.
- A door with floor items moves every item to a walkable cell outside the group.
- A closed doorway and item positions remain valid through save/restore.
- A no-time refusal preserves actor clock, terrain, items, and door RNG state.

---

### Task 1: Level groups and game command

**Files:** `internal/game/level.go`, `internal/game/doors.go`,
`internal/game/commands.go`, `internal/game/movement.go`,
`internal/game/scenario.go`, `internal/ecs/components.go`, game tests.

**Interfaces:** `CommandOpenDoor` and `CommandCloseDoor` use `DX/DY`, zero for
automatic choice. `Level.CloseDoor` mirrors `OpenDoor`. `doorSystem` owns
successful mutation; the game prepares only legal intents.

- [x] Write failing tests for opening, closing, groups, blockers, and items.
- [x] Implement connected-group reuse, command preparation, and door system.
- [x] Test no-time refusals, RNG, save/restore, and focused game cases.

### Task 2: Terminal direction flow

**Files:** `internal/terminal/app.go`, `internal/terminal/play_input.go`,
`internal/terminal/modals.go`, `internal/terminal/keys.go`, terminal tests,
`docs/port-inventory.md`.

**Interfaces:** `O`/`C` act immediately for one target; multiple targets
record a pending door command and accept a movement direction or Escape.

- [x] Write failing terminal tests for automatic, directional, and cancel flow.
- [x] Implement the input flow and on-screen prompt.
- [x] Run focused terminal tests.
- [x] Run full Go tests, vet, build, style, and diff checks; obtain review.
- [x] Commit the door category and fast-forward local `main`.
