# Monster Status and Enchantment Spells Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the nine non-ray monster status and enchantment spells playable through focused Lua effects and saved ECS state.

**Architecture:** Spell modules own eligibility and source rolls. Existing actor owners apply effects. New small schemas and systems hold and age only conditions that have no current owner.

**Tech Stack:** Lua rules in the embedded mod tree, Akara ECS, Go host grid/save, Go and Lua tests.

**Spec:** `docs/superpowers/specs/2026-10-19-monster-status-enchantments-design.md`

## Global Constraints

- Implement all nine spells as one contiguous category and one implementation commit.
- Keep source-specific policy in Lua, mutable state in ECS, and terrain on grids.
- Each Lua function explains why and how; each system has a theory of operation.
- No Lua line exceeds 120 characters; prefer 80 where practical.
- Tests use `_test.lua` modules and import production IDs, schemas, and policies.

## Review Focus

- A caster's target dies between plan and resolve: resolution must not retarget.
- A protector dies during Injury Bond damage: the victim takes its full damage.
- Flay meets mitigation and later healing: only damage actually dealt returns.
- A monster-created Silence aura overlaps player Silence: both fields affect action checks.
- Save/restore occurs mid-condition: timers and entity references remain valid.

---

### Task 1: Effect contracts and source-backed selection

**Files:** `internal/modfs/builtin/policy/combat/monster_spells/{abjuration,berserk_other,black_mark,brain_feed,corrupting_pulse,dream_dust,flay,injury_bond,silence}.lua`; focused Lua tests under `internal/script/testdata/lua/tests/`.

- [ ] Write failing Lua tests for each spell's `plan` refusal, saved target, and effective resolution.
- [ ] Run the focused `TestLuaRules` subtests and confirm the missing modules or behavior fail.
- [ ] Implement separate, readable handlers that delegate state changes to their owners.
- [ ] Re-run the focused Lua tests and verify the selection and resolution paths.

### Task 2: Durable condition owners and consumers

**Files:** focused schemas, systems, and policies under `internal/modfs/builtin/{schemas,systems,policy}/`; imported IDs in `constants/component.lua`.

- [ ] Write failing Lua tests for Black Mark melee effects, corruption, Flay recovery, Injury Bond damage split, and monster Silence radius/expiry.
- [ ] Add only the missing saved components and expiry systems; reuse existing summon, allegiance, stat, sleep, mutation, and health owners.
- [ ] Connect damage, melee, noise, action, and death consumers to the new conditions without a spell-ID switch.
- [ ] Run the focused Lua tests and verify the damage and timing invariants.

### Task 3: Live integration and category gate

**Files:** focused `internal/game/*_test.go`; `docs/port-slices/monster-status-enchantments.md`; `docs/port-inventory.md`.

- [ ] Add live spellbook tests for representative casts, allied casters, save/restore, and post-restore expiry.
- [ ] Verify all nine spell IDs have discoverable handlers and can enter eligible live monster rosters.
- [ ] Run the full Lua suite, focused Go game tests, formatting/style checks, and diff checks once after integration.
- [ ] Request whole-category review, fix confirmed findings, rerun affected checks, commit once, and fast-forward local `main`.

Use the standing approved native execution and local merge workflow.
