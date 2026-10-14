# Ordinary Monster Return Catch-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan task by task.

**Goal:** Apply the supported C++ off-level monster update when returning to a visited floor.

**Architecture:** A focused event-driven system updates Akara monster
components through the level's occupancy service. `Game.activateLevel`
coordinates corpse aging, monster catch-up, deadline rebasing, and clearing
the away clock in source order.

**Tech Stack:** Go, Akara ECS, committed monster catalog, serialized RNG streams.

**Spec:** `docs/superpowers/specs/2026-10-14-ordinary-monster-return-catchup-design.md`

## Global Constraints

- Keep each handwritten line at most 120 columns; prefer 80 and expand struct fields.
- The C++ checkout is reference material; normal Go builds use committed content.
- Preserve saved version 8 and deterministic continuation.

## Review Focus

- Fractional healing draws exactly once and never exceeds maximum HP.
- A destination occupied by another monster stops catch-up movement.
- The player arrival cell cannot receive an overlapping monster.
- A first visit cannot apply return catch-up.
- Restored inactive actors return with the same HP, position, RNG state, and deadline.

---

### Task 1: Pin the pure ordinary-animal catch-up arithmetic

**Files:** Create `internal/monster/offlevel.go` and
`internal/monster/offlevel_test.go`.

**Interfaces:** `OffLevelRecovery(roller Roller, turns int) (int, error)`
returns the HD-1 ordinary-animal recovery. `OffLevelMoveCount(turns,
speed int) int` returns the capped move count.

- [x] Write tests for zero, fractional, integral, and capped cases.
- [x] Verify the tests fail, then implement the pinned arithmetic.
- [x] Verify the focused tests pass.

### Task 2: Apply catch-up to live ECS monsters

**Files:** Create `internal/game/monster_catchup.go`; modify
`internal/game/game.go`, `scenario.go`, and `level_activation.go`. Add
`internal/game/monster_catchup_test.go`.

**Interfaces:** `monsterCatchupSystem.TickLevel(level *Level, turns int) error`.
The system owns exact stores, catalog, and RNG dependencies. It iterates
entity IDs in order, heals, and walks directly toward a saved target through
`Level.MoveActor`.

- [x] Write tests for healing, direct movement, blocked movement, no target,
  first entry, and save/restore return equivalence.
- [x] Verify a representative test fails, then implement the system and
  connect it after corpse aging and before deadline rebasing.
- [x] Verify the focused tests pass.

### Task 3: Document and integrate

**Files:** Update `docs/ecs-architecture-roadmap.md` and
`docs/port-inventory.md`.

- [x] State which off-level behaviors are now faithful and which require
  future monster capabilities.
- [x] Run full `go test ./...`, `go vet ./...`, `go build ./...`,
  `sh scripts/check-go-style.sh`, and `git diff --check` once for the category.
- [x] Review the diff, commit one category, and fast-forward local Go `main`.
