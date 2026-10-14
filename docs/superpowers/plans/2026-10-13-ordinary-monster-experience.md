# Ordinary Monster Experience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract and test the source XP arithmetic used by ordinary monsters.

**Architecture:** A pure `character.OrdinaryMonsterExperience` rule accepts explicit numeric stats. The current rat/quokka wrapper preserves its eligibility checks and delegates the arithmetic.

**Tech Stack:** Go standard library and committed monster definitions.

**Spec:** `docs/superpowers/specs/2026-10-13-ordinary-monster-experience-design.md`

## Global Constraints

- Preserve the fixed scenario, existing rewards, and save format.
- Do not imply that spells, equipment, or special monster XP is supported.
- Use one coherent commit after broad verification and review.

## Review Focus

- Source integer truncation order for base, speed, modifier, and stepdowns.
- Slow monsters halve experience only in the specified no-spell/no-item subset.
- Large damage difficulty uses the sum of four attacks and speed-specific divisor.
- Zero modifier skips multiplication, while a low positive modifier may reduce to the one-XP floor.
- Invalid HP, hit dice, speed, or negative attack damage must return an error.

---

### Task 1: Pure rule and existing caller

**Files:**
- Create: `internal/character/ordinary_monster_experience.go`
- Test: `internal/character/ordinary_monster_experience_test.go`
- Modify: `internal/character/experience.go`
- Modify: `docs/port-inventory.md`

**Interfaces:**
- `type OrdinaryMonsterXPInput struct { HitDice, MaxHP, Speed, Modifier int; AttackDamage [4]int; FastRegen bool }`
- `func OrdinaryMonsterExperience(OrdinaryMonsterXPInput) (int, error)`

- [ ] Write failing table tests for source formula branches and invalid inputs.
- [ ] Run focused tests and confirm the missing API fails.
- [ ] Implement the pure rule and replace rat/quokka numeric arithmetic with a call using cataloged stats.
- [ ] Run focused tests, full tests, vet, build, formatting, and diff check.
- [ ] Obtain read-only whole-branch review, fix findings, commit, and fast-forward local Go `main`.
