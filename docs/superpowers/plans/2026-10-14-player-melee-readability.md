# Player Melee Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the Human Fighter melee phases clear while preserving exact DCSS roll order and outcomes.

**Architecture:** Keep `PlayerMelee` as the ordered coordinator. Extract hit resolution, base potential, damage modifiers, and armour reduction into named functions, with the same `Roller` passed through each phase.

**Tech Stack:** Go, scripted combat roller tests.

**Spec:** Current source-traced combat implementation and `AGENTS.md` readability rules.

## Global Constraints

- Preserve all random draws and their order, including shieldless bypass and odd-AC draws.
- Preserve miss/hit result and error behavior.
- Keep the phase order visible in `PlayerMelee` and comment only source-specific choices.
- Keep all handwritten lines at or below 120 columns.

## Review Focus

- Automatic hit and miss rolls must precede the shield bypass roll.
- Unarmed fractional damage must draw only when the skill has a remainder.
- Weapon skill, fighting, might, and enchantment modifiers must stay in order.
- Armour reduction and odd-AC rounding draw must remain last.
- Roller errors must still stop at the same phase.

---

### Task 1: Name the player melee phases

**Files:**
- Modify: `internal/combat/player.go`
- Test: `internal/combat/player_test.go`

**Interfaces:**
- `playerHitRoll(r Roller, in PlayerAttackInput) (bool, error)` returns whether damage can proceed.
- `playerDamageRoll(r Roller, in PlayerAttackInput) (int, error)` preserves potential and modifiers.
- `playerArmourReduction(r Roller, ac int) (int, error)` preserves the final AC draws.
- `PlayerMelee` validates, calls phases in order, and returns the outcome.

- [x] Run focused scripted-roll tests as baseline.
- [x] Extract phases while retaining exact roll order and errors.
- [x] Run `gofmt`, focused tests, and full verification once for the category.
- [x] Obtain independent review; commit and fast-forward local `main`.
