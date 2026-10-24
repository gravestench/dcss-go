# Shared Actor Cells Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let Fedhas worshipers share cells with eligible plants while
retaining deterministic actor lookup, atomic Lua actions, and valid saves.

**Architecture:** The level owns ordered occupancy lists. Lua supplies
permission to share; the Go grid provides only a generic explicit shared
operation. The Lua runtime stages lists and commits them transactionally.

**Tech Stack:** Go, Akara ECS, gopher-lua, committed embedded Lua.

**Spec:** `docs/superpowers/specs/2026-10-24-shared-actor-cells-design.md`

## Global Constraints

- Gameplay permission belongs in Lua; Go owns generic grid invariants.
- No inline Lua in Go. Keep Lua functions and Go lines under 120 characters.
- Preserve save determinism and reject unrelated overlapping actors.
- Work on the user's authorized `main`; push coherent category commits.

## Review Focus

- Removing one of two actors must leave the other indexed.
- A staged move after a staged placement must see both occupants.
- Region replacement must not lose a shared actor.
- Restore must reject arbitrary overlaps and accept eligible Fedhas plants.
- Monster actions must target the player when the player shares a cell.

---

### Task 1: Level occupancy owner

**Files:** `internal/game/level.go`, `internal/game/level_region.go`,
`internal/game/script_services.go`, `internal/game/abyss_state.go`, focused
Go tests.

**Interfaces:** Produce `ActorsAt`, `PlaceActorShared`, and
`MoveActorShared`. Preserve `ActorAt`, `PlaceActor`, and `MoveActor` default
single-occupant semantics.

- [ ] Write tests for ordering, removal, blocked default placement, and
  simultaneous movement around a shared cell; watch them fail.
- [ ] Replace the single-actor index with ordered actor lists and update
  region copies and validation.
- [ ] Run focused Go tests and commit the category.

### Task 2: Transactional Lua grid interface

**Files:** `internal/script/runtime.go`, `internal/script/grid_pending.go`,
`internal/script/context.go`, `internal/script/grid_batch.go`,
`internal/script/grid_region.go`, script tests.

**Interfaces:** Consume Task 1's shared grid operations. Produce
`ctx:actors_at` and explicit sharing for `ctx:place_actor` and
`ctx:move_actor`.

- [ ] Write a failing Lua action test for two staged occupants and rollback.
- [ ] Stage full occupancy lists and preserve actor order across structural
  commands, batches, and region changes.
- [ ] Run focused script tests and commit the category.

### Task 3: Source-backed Fedhas rules and restore

**Files:** Fedhas Lua policy, movement and navigation Lua, common summon Lua,
save placement validation, Lua and Go integration tests, port inventory.

**Interfaces:** Consume Task 2's enumeration and explicit sharing API.

- [ ] Write failing tests for self-growth, passage, cost, messages, and save
  round trip, including loss of the passive.
- [ ] Add a focused Lua pass-through policy and use it at movement and growth
  call sites. Validate restored shared cells after Lua components load.
- [ ] Run focused tests, build CLI, inspect style and diff, and commit/push.

### Task 4: Integrated verification and review

**Files:** No production files unless verification reveals a defect.

- [ ] Run the relevant broader Go/Lua suites once at the slice boundary.
- [ ] Review the whole change for source fidelity, invariants, readability,
  and unintended permissions; fix findings.
- [ ] Update the inventory and push final corrections if needed.
