# Monster Forest and Plant Spells Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all five remaining forest and plant monster spells live, including their continuing actor and terrain behavior.

**Architecture:** Keep one `plan`/`resolve` module per spell. Share existing summon, root, and terrain owners; add small Lua policies and Akara components only for new continuing invariants. No Go spell-ID switch or alternate Lua source path.

**Tech Stack:** Embedded Lua mod tree, Akara ECS, Go level grids and saves, Lua rule tests, live Go spellbook tests.

**Spec:** `docs/superpowers/specs/2026-10-19-monster-forest-and-plant-spells-design.md`

## Global Constraints

- Implement Awaken Forest, Awaken Vines, Wall of Brambles, Grasping Roots, and Sporulate as one category and one implementation commit.
- Preserve source eligibility, geometry, allegiance, roll order, expiration, and actor death cleanup.
- Mutable dynamic state belongs in Akara; terrain remains in the level grid.
- Put every gameplay decision in readable Lua files with function comments and system theory of operation.
- Import production IDs; no inline Lua in Go; Lua lines at most 120 columns.
- Test the integrated category after the contiguous implementation swath rather than each tiny file edit.

## Review Focus

- The target moves or dies after preflight: a cast must use or reject its saved target, never silently choose another.
- The caster dies or leaves a level with living vines or an awake forest: dependents must release without a dangling handle.
- A briar wall has no legal arc: no action or random draw should be consumed.
- Roots hit an already-held or immune actor: no duplicate restraint remains.
- Save/restore happens mid-condition: actor identity, timers, geometry, and RNG continuation must agree.
- Before completion, compare forest sanctuary and friendly-plant protection, tree hit and armour draws, and visible messages against the pinned source.
- Compare monster-root constriction against player Fastroot on both player and monster defenders, including source death and player movement.

---

### Task 1: Shared plant and restraint owners

**Files:** `internal/modfs/builtin/policy/combat/monster_plants/{forest,vines,brambles,spore}.lua`; existing `policy/magic/effects/zaps/fastroot.lua` and `policy/magic/effects/summons/common.lua`; focused schemas and systems in their standard directories.

**Interfaces:** Each owner exposes named eligibility, apply/spawn, tick, and release functions used by its spell. Use the existing summon lifetime and root components when their fields already express the invariant; define a new schema only for missing saved state.

- [ ] Trace each source rule through cast, later action, and death/expiry paths; write focused `_test.lua` cases against production IDs and schemas.
- [ ] Implement actor-neutral plant and restraint ownership, including tree attacks, vine linkage, briar lifetime/thorns, and spore movement/explosion.
- [ ] Connect owner cleanup to actor death and active-level systems without a domain switch in Go.

### Task 2: Five named spell effects

**Files:** `internal/modfs/builtin/policy/combat/monster_spells/{awaken_forest,awaken_vines,wall_of_brambles,grasping_roots,sporulate}.lua`; existing source-backed content definitions and shared constants.

**Interfaces:** Each module returns a local object with commented `plan(ctx, caster, foe, ...)` and `resolve(ctx, caster, foe, ..., plan)` methods. Plans are read-only and carry any chosen actor or cell needed by resolution.

- [ ] Add source-shaped cast eligibility and independent effect modules for all five spell IDs.
- [ ] Route world changes through the Task 1 owners and preserve source roll order after a committed cast.
- [ ] Ensure allied casters can select enemy monsters without harming their own side.

### Task 3: Live and regression gate

**Files:** `internal/game/monster_forest_plant_test.go`, sparse spellbook fixtures under `internal/game/testdata/`, `docs/port-slices/monster-forest-and-plant-spells.md`, `docs/port-inventory.md`.

- [ ] Run focused Lua tests for all five spells, the player Fastroot and Summon Forest tests, and correction cases from Review Focus.
- [ ] Run live spellbook casts and save/restore continuation for each continuing effect on an eligible level.
- [ ] Run the full Lua suite, focused Go game tests, `go build ./...`, Go style, Lua line-length, and `git diff --check` once after integration. Record any unrelated broad-suite timeout separately.
- [ ] Request whole-category read-only review, fix confirmed findings, rerun affected checks, commit once, fast-forward local `main`, and push `main` to the fork.
