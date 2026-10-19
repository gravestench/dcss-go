# Monster direct strikes implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Smiting, Airstrike, Waterstrike, and Resonance Strike playable Lua monster effects.

**Architecture:** One focused file per effect; shared target and HP helpers only where all four use the same contract. No Go spell dispatch additions.

**Tech Stack:** Lua rules, Akara ECS context, Go integration tests.

**Spec:** `docs/superpowers/specs/2026-10-18-monster-direct-strikes-design.md`

## Global Constraints

- Committed Lua is runtime source. No C++ import at build or test time.
- Every Lua function has an adjacent why/how comment; each policy has a usage example.
- Maximum line length 120; prefer 80. Multi-field table literals are vertical.
- Import shared IDs at use sites and keep tests in `_test.lua` files.

## Review Focus

- An actor between caster and target must not block a direct strike.
- A wall must block visibility to the target.
- A stale target cannot redirect the spell to another entity.
- Drowning immunity changes only Waterstrike's resistible share.
- Nearby nonconstructs or enemy constructs cannot boost Resonance Strike.

---

### Task 1: Direct target and damage owner

**Files:** Create `internal/modfs/builtin/policy/combat/monster_direct.lua`; test `internal/script/testdata/lua/tests/monster_direct_strikes_test.lua`.

**Interfaces:** `direct.plan(ctx, caster, foe, spell_id)` returns a typed entity plan or nil; `direct.require(ctx, caster, foe, plan)` validates it; `direct.damage(ctx, caster, foe, amount)` delegates to existing health owners; `direct.armour(ctx, foe, amount)` rolls target AC.

- [ ] Write failing tests for LOS, intervening actor, range, and stale target.
- [ ] Run `go test ./internal/script -run TestLuaRules` and confirm the focused test fails.
- [ ] Implement the four helper methods and comments.
- [ ] Run the focused Lua suite and confirm it passes.

### Task 2: Four source effects

**Files:** Create four `internal/modfs/builtin/policy/combat/monster_spells/<name>.lua` effects; extend `monster_direct_strikes_test.lua`.

**Interfaces:** Each effect exports `plan(ctx, caster, foe, slot)` and `resolve(ctx, caster, foe, slot, plan)`; the existing file-per-ID registry discovers it.

- [ ] Write failing deterministic tests for each damage formula, AC and water resistance, and allied construct filtering.
- [ ] Run the focused tests and confirm failure.
- [ ] Implement each source effect using the direct helper and named RNG stream.
- [ ] Run the focused tests and confirm pass.

### Task 3: Integration and documentation

**Files:** Modify `internal/game/monster_beam_test.go` or create `internal/game/monster_direct_test.go`; modify `docs/modding.md`.

- [ ] Add a real-cast game test and save/restore RNG continuation.
- [ ] Explain the direct effect contract and `ctx` use in the mod guide.
- [ ] Run the full Lua suite, affected Go tests, build, vet, style, and diff check.
- [ ] Review and commit this coherent spell family; fast-forward local main.
