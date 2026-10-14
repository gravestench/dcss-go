# Auxiliary Armour Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let the Human Fighter wear, remove, save, and defend with ordinary
headgear, cloaks, gloves, and boots using the existing equipment flow.

**Architecture:** Keep the six armour slots in the ECS `Equipped` component
and the current five-turn equipment delay. `game` validates slot and Human
fit, then projects worn items into a pure combat calculation. No new save
format is needed because saves already record slot and delay components.

**Tech Stack:** Go, Akara ECS, committed item catalog, source-traced tests.

**Spec:** Pinned DCSS `item-use.cc:1147-1220`, `player.cc:1941-1965`,
`player.cc:5747-5756`, `player.cc:5965-5990`.

## Global Constraints

- Preserve current body and shield behavior and all equipment turn costs.
- Human cannot wear either barding kind; reject it without spending aut.
- AC sums each non-shield item's skill-adjusted base and enchantment before
  final rounding; EV includes every worn non-shield item's base penalty.
- Keep mutable equipment in ECS and avoid crowded declarations or conditions.
- Run gofmt and full verification once at the category boundary.

## Review Focus

- Removing a piece reduces AC on the fifth turn, not at command start.
- Swapping two items in one auxiliary slot takes ten turns.
- A saved pending wear or removal delay restores with its slot intact.
- Barding refusal happens even though the catalog assigns it to boots.
- Body and shield projections remain unchanged when no auxiliary piece is worn.

---

### Task 1: Auxiliary slots and delay validation

**Files:** `internal/game/armour.go`, `internal/game/save_restore_validation.go`,
`internal/game/armour_test.go`

- [x] Add a failing table test for the four ordinary auxiliary slots and
  no-time Human barding refusal.
- [x] Extend the supported armour slots in command and save validation.
- [x] Run focused game tests.

### Task 2: Defense projection from worn auxiliary armour

**Files:** `internal/combat/ordinary_bite.go`,
`internal/combat/ordinary_bite_test.go`, `internal/game/player_combat.go`,
`internal/game/armour_test.go`, `docs/port-inventory.md`

- [x] Add a failing pure defense test for summed AC and EV.
- [x] Project non-shield worn pieces from ECS into combat input.
- [x] Verify worn armour changes defense only when the delay completes.
- [x] Update port inventory; run tests, vet, build, style, and diff checks.
- [x] Review and commit this one armour category, then merge to local main.
