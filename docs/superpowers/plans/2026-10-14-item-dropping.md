# Item Dropping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add source-shaped `d` item dropping to the playable Go Dungeon slice.

**Architecture:** Terminal selection produces a `CommandDrop` with item ID and optional quantity. An Akara system records the action; `Game` applies item component changes at its structural barrier, preserving entity ownership and save compatibility.

**Tech Stack:** Go, Akara ECS, Bubble Tea, current JSON save format.

**Spec:** `docs/superpowers/specs/2026-10-14-item-dropping-design.md`

## Global Constraints

- Preserve the source's no-time refusal and quantity clamp behavior.
- Keep entity state on Akara components and floor terrain on `Level`.
- Keep 120-column maximum, readable spacing, and multiline struct literals.
- Commit one contiguous item-drop category after integrated verification.

## Review Focus

- Equipping and carrying invariants after a full weapon drop.
- Partial stack drops keep the carried item's properties and quantity.
- A compatible floor stack merges without duplicating item entities.
- Save and restore retain dropped and carried split stacks.
- Invalid item IDs and zero quantities spend no time and make no world change.

---

### Task 1: ECS drop action and game command

**Files:**
- Modify: `internal/ecs/components.go`
- Modify: `internal/game/commands.go`
- Modify: `internal/game/items.go`
- Modify: `internal/game/scenario.go`
- Test: `internal/game/drop_test.go`

**Interfaces:**
- `CommandDrop` carries `ItemID` and `Quantity` (`0` means whole stack).
- `IntentDrop` carries the selected entity and resolved quantity.
- `dropSystem` records a pending drop; `Game.applyDrop` performs structural changes after `World.Update`.

- [x] Add tests for command validation, full and partial drops, merge, equipment, and save continuation.
- [x] Implement the command, system, and structural barrier.
- [x] Run focused game tests.

### Task 2: Terminal drop selection

**Files:**
- Modify: `internal/terminal/app.go`
- Modify: `internal/terminal/play_input.go`
- Modify: `internal/terminal/modals.go`
- Test: `internal/terminal/drop_test.go`
- Modify: `docs/port-inventory.md`

**Interfaces:**
- `ScreenDrop` renders the inventory and the optional decimal quantity.
- `handleDropKey` calls `Game.Step(CommandDrop)` using displayed inventory letters.

- [x] Add key and rendered-menu tests.
- [x] Implement drop selection and notices.
- [x] Run focused terminal tests.
- [x] Run full tests, vet, build, style and diff checks; obtain review.
- [x] Commit and fast-forward local `main`.
