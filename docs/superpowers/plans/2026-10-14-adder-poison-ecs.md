# Adder Poison ECS Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this
> plan natively. Track steps with checkboxes. The user chose one commit per
> contiguous problem category, so commit this integrated slice once.

**Goal:** Make the source's D:1–2 adder and persistent poison playable through
one Akara-owned status path.

**Architecture:** Immutable catalog data identifies the adder's poison bite.
The combat system applies an optional `ecs.Poison` component; a system after
regeneration decays it on player-action aut. Curing clears that component.
Snapshot/restore and the copied view carry only authoritative status data.

**Tech Stack:** Go, Akara ECS, Bubble Tea/Lip Gloss, committed DCSS catalogs.

**Spec:** `docs/superpowers/specs/2026-10-14-adder-poison-ecs-design.md`

## Global constraints

- Reference pinned C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Normal build and play use committed content; no importer runs at build time.
- Handwritten Go lines must be at most 120 columns and should favor 80.
- Expand multi-field literals and separate validation, calculation, mutation,
  and event emission; keep comments about invariants and source rules.
- Preserve the user's untracked `dcrawl-save.json` in the main checkout.
- Commit this domain category once after integrated verification and review.

## Review focus

- A poison bite that hits for zero damage can still apply poison.
- Poison applied on a monster action must wait for the next player action to
  decay; monster actions do not multiply the elapsed poison time.
- Curing at full HP retains the existing healing RNG draw and clears Poison.
- Lethal poison must stop the monster scheduling loop and show death.
- An invalid or non-player saved Poison component must fail restore cleanly.

---

### Task 1: Source poison arithmetic

**Files:** Create `internal/character/poison.go` and
`internal/character/poison_test.go`.

**Interfaces:** `DecayHumanPoison(scaledAmount, elapsedAut int) (nextScaled,
damage int, err error)` owns only the deterministic source decay. The combat
system owns flavour probability and amount draws.

- [x] Test source minimum-rate, ordinary exponential, maximum-rate, and
  fractional-aut examples, whole-point damage truncation, below-1000 clear,
  invalid inputs.
- [x] Verify red, implement the piecewise source functions from
  `player.cc:4204–4339`, then verify green.

### Task 2: ECS status and save ownership

**Files:** Modify `internal/ecs/components.go`, `stores.go`,
`internal/save/snapshot.go`, `internal/game/save.go`,
`save_restore_components.go`, `save_restore_validation.go`,
`save_restore_rules.go`, and `view.go`. Add focused game save tests.

**Interfaces:** `ecs.Poison{AmountScaled int, SourceMonsterID string}` lives
only on poisoned entities. Save schema becomes 11. `View` exposes scaled
amount through a copied field; restore validates player ownership and amount
  1,000–2,147,483,647 and source ID `MONS_ADDER`.

- [x] Test snapshot isolation, exact restore continuation, invalid bounds,
  unknown source, and Poison on an item or monster; verify red.
- [x] Add one Akara store, save codec field, role validation, restore copy,
  and view projection; verify green.

### Task 3: Source-backed adder in the ordinary monster path

**Files:** Modify `internal/character/experience.go`,
`internal/combat/ordinary_bite.go`, `internal/game/ordinary_animal.go`,
`combat.go`, and population/save tests.

**Interfaces:** The adder profile validates HD 2, HP ×10 110, speed 13,
damage 4, `AT_BITE`/`AF_POISON`, no extra attacks, no spells or items, and
  its possible rolled-HP range 7–15. `ResolveAnimalBite` accepts the poison
flavour but retains the ordinary damage phases. `combatSystem` rolls the
source 1-in-3 trigger and inclusive 4–8 poison points on the melee stream
after a landed hit, then adds or increases the player's component.

- [x] Test adder catalog validation, population eligibility, rolled HP
  bounds, XP/corpse creation, RNG bounds, and poison after a zero-damage hit;
  verify red.
- [x] Extend the existing factory/combat/death path without a second actor
  implementation, then verify green.

### Task 4: Poison action phase, curing, and HUD

**Files:** Create `internal/game/poison.go`; modify `scenario.go`,
`curing.go`, `view.go`, and `internal/terminal/play_render.go` with focused
game and terminal tests.

**Interfaces:** `poisonSystem.Update` runs after regeneration and only on
player actions. It applies pure decay damage, removes Poison below one point,
and emits sickness/recovery events. Curing removes Poison while preserving
its existing healing roll and item consumption. The HUD shows poisoned
status from the view without touching stores.

- [x] Test regen-before-poison, monster-turn deferral, lethal poison, cure at
  full HP with RNG continuation, and HUD status; verify red.
- [x] Register the system in source order and implement game/UI integration;
  verify green.

### Task 5: Integrated boundary and review

**Files:** Update `docs/port-inventory.md` and
`docs/ecs-architecture-roadmap.md` with the exact new coverage and limits.

- [x] Run `go test ./...`, `go vet ./...`, `go build ./...`,
  `sh scripts/check-go-style.sh`, and `git diff --check` once after the
  category is integrated.
- [x] Obtain read-only review and fix Important findings.
- [x] Commit the category and fast-forward local Go `main` while preserving
  the user's save.
