# Monster battlecries implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port Battlecry, Warning Cry, and Hunting Call as faithful Lua monster effects.

**Architecture:** One shared cry owner selects recipients and performs boon/noise effects; three focused spell modules expose the existing typed `plan/resolve` contract.

**Tech Stack:** Lua rules, Akara ECS context, Go game integration.

**Spec:** `docs/superpowers/specs/2026-10-18-monster-battlecries-design.md`

## Global Constraints

- Runtime content is committed Lua; C++ is only source reference.
- Every Lua function has an adjacent why/how comment and every policy has a usage example.
- Lua and Go lines stay at or below 120 characters, preferably 80.
- Multi-field literals are vertical; shared IDs are imported at use sites.
- Commit this family as one category after verification.

## Review Focus

- A sleeping ally wakes after receiving a boon; a confused ally cannot receive one.
- A friendly caster and a good-neutral recipient retain source allegiance.
- A clear but solid wall blocks no-trans cry eligibility.
- A failed plan consumes no random draws or emits no noise.
- Warning Cry causes actual awareness noise, not only display text.

---

### Task 1: Battlecry selection and boon owner

**Files:** Create `internal/modfs/builtin/policy/combat/monster_battlecries.lua`; create `internal/script/testdata/lua/tests/monster_battlecries_test.lua`.

**Interfaces:** `cries.plan(ctx, caster, foe, kind)` returns a self entity plan or nil; `cries.resolve(ctx, caster, plan, kind)` applies Might or Swift and sound.

- [ ] Write failing tests for allegiance, genus, status, existing boon, and LOS selection.
- [ ] Run the focused Lua test to confirm failure.
- [ ] Implement recipient selection, source duration, boon, wake, message, and noise.
- [ ] Run the focused Lua test to confirm pass.

### Task 2: Three effect modules

**Files:** Create `monster_spells/battlecry.lua`, `warning_cry.lua`, and `hunting_call.lua`; extend the Lua test and spell coverage test.

**Interfaces:** Each module exports `plan(ctx, caster, foe, slot)` and `resolve(ctx, caster, foe, slot, plan)`.

- [ ] Add failing effect and Warning Cry tests.
- [ ] Implement three source effects without a central dispatcher.
- [ ] Run focused tests and verify all three modules load and behave.

### Task 3: Real game, guide, and integration

**Files:** Add an overlay under `internal/game/testdata/monster-battlecries/`; add `internal/game/monster_battlecry_test.go`; update `docs/modding.md`.

- [ ] Force a real cry, inspect an allied ECS boon, and verify save/restore continuation.
- [ ] Add a guide example of a group-affecting spell using `ctx`.
- [ ] Run full Lua suite, affected game tests, build, vet, style, and diff checks.
- [ ] Review, commit once, fast-forward local main, and verify the merged checkout.
