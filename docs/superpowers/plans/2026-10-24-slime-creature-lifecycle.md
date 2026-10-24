# Slime Creature Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make ordinary slime creatures split and merge during pursuit with correct ECS, save, combat, and Duel behavior.

**Architecture:** `policy.monsters.slime_lifecycle` owns source behavior and is called once in monster decision before ordinary action selection. One living blob group is one ECS actor; a saved birth marker admits offspring outside the starting roster. Existing `slime_blob` owns naming and damage scaling.

**Tech Stack:** Go host, embedded Lua rules, Akara ECS, production Lua test VM.

**Spec:** `docs/superpowers/specs/2026-10-24-slime-creature-lifecycle-design.md`

## Global Constraints

- Gameplay rules in Lua, generic ECS and grid services in Go, no inline Lua in Go.
- Deterministic named RNG stream; no load-order dependence.
- Each Lua function has a why/how comment; max 120 characters per line.
- Work on `main`, commit this contiguous category once, push after verification.

## Review Focus

- A shapeshifter wearing slime form cannot split or merge: test eligibility.
- A legal closer empty cell blocks merge: test route preference.
- Five is the hard blob cap: test merge ceiling and saved size.
- A split Duel target keeps both descendants locked in Arena: test copied mark and merge transfer.
- Save/restore must accept a generated child yet reject an unrelated forged marker: test validation.

---

### Task 1: Live slime lifecycle

**Files:**
- Create: `internal/modfs/builtin/policy/monsters/slime_lifecycle.lua`
- Modify: `internal/modfs/builtin/systems/monster_decision.lua`
- Modify: `internal/modfs/builtin/constants/rng_streams.lua`
- Test: `internal/script/testdata/lua/tests/monster_slime_lifecycle_test.lua`

**Interfaces:**
- Consumes: existing `slime_blob.size(ctx, entity)`, `factory.spawn`, `ctx:actor_at`, `habitat.at`, `ctx:get/set/add/remove_actor/destroy`, `targets`.
- Produces: `slime_lifecycle.tick(ctx, entity) -> boolean`; true means this actor spent its action.

- [x] Add a Lua test using production schemas and the shared observed grid fixture: size-three split into sizes two and one, health conservation, two distinct actor positions, and one spent action.
- [x] Run `go test ./internal/script -run 'TestLuaRules/monster_slime_lifecycle_test.lua' -count=1` and confirm failure.
- [x] Implement split eligibility, route preference, fair adjacent selection, state transfer, and action ownership in the focused policy.
- [x] Add merge compatibility, route blockage rule, combined HP/size, Duel mark transfer, survivor energy cost, and dismissed removal.
- [x] Call `tick` from monster decision before confusion and ordinary routing, then run the targeted test.
- [x] Add tests for disabled/shifter cases, open routes, cap, allegiance, summon lineage, and inherited statuses.

### Task 2: Persistent lineage and save rules

**Files:**
- Create: `internal/modfs/builtin/schemas/monster_slime_birth.lua`
- Modify: `internal/modfs/builtin/constants/component.lua`
- Modify: `internal/modfs/builtin/policy/monsters/slime_lifecycle.lua`
- Modify: `internal/modfs/builtin/policy/save/monsters.lua`
- Modify: `internal/modfs/builtin/policy/magic/effects/statuses/polymorph.lua`
- Test: `internal/script/testdata/lua/tests/monster_slime_lifecycle_test.lua`

**Interfaces:**
- `monster.slime_birth` has `created_aut` and records only generated offspring.
- `slime_lifecycle.validate(ctx, entity, health, profile, now)` checks size, birth origin, and per-blob HP bound.

- [x] Add save tests for split child, mixed authored HP merge, invalid birth marker, impossible size and HP.
- [x] Run targeted Lua tests and confirm failure.
- [x] Add production schema and validation; exempt offspring from the initial roster budget and allowed-kind checks.
- [x] Clear stale slime size on polymorph; retain birth origin for roster accounting.
- [x] Run targeted Lua tests and relevant Go save/restore tests.

### Task 3: Demonstrate and integrate

**Files:**
- Create: `docs/snapshots/slime-creature-lifecycle.md`
- Modify: existing game integration test if direct Lua cases cannot prove action scheduling.

- [x] Record a compact text floor with before/after positions, sizes, HP, and blocked route.
- [x] Run targeted Lua and game tests, `go build ./...`, format checks, and `git diff --check`.
- [x] Review whole category for stale body links and state transfer gaps; correct any found.
- [x] Commit the category once and push `main`.
