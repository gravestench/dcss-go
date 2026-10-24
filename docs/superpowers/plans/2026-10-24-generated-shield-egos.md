# Generated Shield Egos Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all seven source-generated shield egos effective on a worn
player shield.

**Architecture:** Keep the source-weighted Lua generator and live Akara item
state. Extend the existing Lua resistance, AC, and reflection owners to read
the shield entry from `equipment.worn`.

**Tech Stack:** Embedded Lua rules and `_test.lua` fixtures, Akara ECS,
Go game integration tests.

**Spec:** `docs/superpowers/specs/2026-10-24-generated-shield-egos-design.md`

## Global Constraints

- Keep combat policy in readable Lua with no inline Lua in Go.
- Import ego IDs from `constants.armour_egos` at their use sites.
- Comment every added Lua function with its why and how.
- Keep handwritten lines at most 120 columns, preferring 80.
- Commit this whole shield category once and push `origin main`.

## Review Focus

- An unequipped or form-melded shield contributes no ego effect.
- Fire and cold Resistance each add a pip, with no extra poison pip.
- Protection adds three AC, but ordinary shield base AC remains SH.
- Reflection triggers only on a successful block and retains its return
  target, original projectile, and player kill credit.
- Save/restore preserves the shield ego and its derived defenses.

---

### Task 1: Resistance and AC

**Files:** `policy/magic/damage.lua`,
`policy/combat/player_resistance.lua`, `policy/combat/fighter.lua`, focused
`_test.lua` rules, and a Go game save/restore case.

- [x] Add failing equipped-shield tests for all five resistance egos and
  source +3 Protection AC, plus unequip and form-melded behavior.
- [x] Route the shield through the existing worn-armour scans and AC sum.
- [x] Run the focused rules and game case.

### Task 2: Reflection

**Files:** `policy/combat/reflection.lua`, `ranged_reflection_test.lua`,
and existing monster beam reflection tests as needed.

- [x] Add a failing real blocked-shot test using a Reflection shield
  without an amulet, then prove removing the shield stops reflection.
- [x] Extend the shared player reflection predicate through worn armour.
- [x] Run projectile and beam reflection tests.

### Task 3: Category gate

**Files:** `docs/port-inventory.md` and this plan.

- [x] Run focused tests, `go build ./...`, `gofmt`, the style script, and
  `git diff --check`; resolve new findings.
- [x] Review the complete diff against the source and commit once.
- [x] Push `origin main` and verify the checkout is clean.
