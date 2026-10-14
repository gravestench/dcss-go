# Weapon Wielding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Fighter's weapon slot changeable through source-shaped `w` play.

**Architecture:** Validate a carried weapon before spending time, record an Akara intent, then change the existing equipment relation after `World.Update`. Keep the terminal selection independent of the simulation and let combat read the live slot.

**Tech Stack:** Go, Akara ECS, Bubble Tea, current Go JSON save format.

**Spec:** `docs/superpowers/specs/2026-10-14-weapon-wielding-design.md`

## Global Constraints

- Match the pinned source's 5-aut wield and 3-aut bare-hands costs for a 10-aut Human/Fighter baseline.
- Reject invalid choices without a world mutation, RNG draw, or spent time.
- Keep the weapon slot on `ecs.Equipped`, with the change at the post-update barrier.
- Keep handwritten Go at 120 columns maximum, prefer 80, and separate logical steps.
- Commit one contiguous wielding category after integrated verification.

## Review Focus

- A recovered starting weapon can be wielded after pickup and restored from a save.
- Switching weapons leaves exactly one equipped weapon and never changes the shield.
- A medium Human cannot wield a weapon requiring two hands while wearing the buckler.
- A no-time rejection leaves the current equipped weapon and actor clock untouched.
- The `w` menu uses inventory letters even when non-weapons precede the weapon.

---

### Task 1: Weapon legality and live equipment command

**Files:**
- Modify: `internal/ecs/components.go`
- Modify: `internal/game/commands.go`
- Add: `internal/game/wield.go`
- Modify: `internal/game/scenario.go`
- Modify: `internal/game/save_restore_rules.go`
- Modify: `internal/game/save_restore_validation.go`
- Add: `internal/game/wield_test.go`

**Interfaces:**
- `CommandWield` takes `ItemID`; zero means bare hands.
- `IntentWield` carries the selected item entity, if any.
- `prepareWieldCommand` returns 5, 3, or no aut after validating the live component state.
- `wieldSystem.Update` records a pending change; `Game.applyWield` changes `Equipped` after Akara's update.

- [x] Write and run failing tests for re-wield, bare hands, alternate weapon, and no-time refusal.
- [x] Implement the command, system, and structural barrier.
- [x] Generalize save validation to check actual equipment and the starting weapon independently.
- [x] Run focused game tests.

### Task 2: Terminal selection and integration

**Files:**
- Modify: `internal/terminal/app.go`
- Modify: `internal/terminal/play_input.go`
- Modify: `internal/terminal/modals.go`
- Add: `internal/terminal/wield_test.go`
- Modify: `docs/port-inventory.md`

**Interfaces:**
- `ScreenWield` displays carried weapons with inventory letters and a bare-hands option.
- `handleWieldKey` submits `CommandWield` and returns to play after selection.

- [x] Add terminal key, menu, and cancellation tests.
- [x] Implement the `w` menu and explanatory no-time notices.
- [x] Run focused terminal tests.
- [x] Run full Go tests, vet, build, style, and diff checks; obtain review.
- [x] Commit the wielding category and fast-forward local `main`.
