# Monster Ally-Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan. Work as one coherent
> category and make one implementation commit, per the user's preference.

**Goal:** Make Haste Other, Might Other, Invisibility Other, and Heal Other
live Lua monster spells with source target selection and saved effects.

**Architecture:** A focused `monster_support/ally_target.lua` chooses one
beneficial beam recipient and returns an entity plan. Four thin spell modules
use that plan and existing actor-owned effect policies; no new Go spell
dispatcher or parallel status component is needed.

**Tech Stack:** Go host, GopherLua, Akara dynamic components, committed Lua
content and `_test.lua` rule tests.

**Spec:** `docs/superpowers/specs/2026-10-18-monster-ally-support-design.md`

## Global constraints

- Keep production policy and all spell-specific behavior in separate Lua files.
- Keep generated content committed; no importer runs at build or launch.
- Comment every new function, explain how and why, and keep lines <=120 columns.
- Use imported IDs at use sites and multiline struct/table declarations.
- Use one contiguous implementation commit, then fast-forward local `main`.

## Review focus

1. Charmed enemies must not become buff targets because temporary alignment
   resembles the caster's side.
2. An intervening actor or wall must prevent a selected target from receiving
   a beneficial beam through that blocker.
3. Heal Other must consider a one-HP wound and cap healing at maximum HP.
4. A selected entity that dies or moves before resolution must not redirect
   its effect to another actor.
5. Existing boon and invisibility durations must remain shared with self
   spells and survive save/restore without duplicate state.

## Task 1: Source target owner

**Files:** `policy/combat/monster_support/ally_target.lua`,
`tests/monster_ally_target_test.lua`.

**Interface:** `plan(ctx, caster, spell_id, benefits)` returns an entity target plan or
`nil`; `selected(ctx, caster, plan)` validates and returns the chosen actor
or `nil`. `benefits(ctx, target)` is supplied by one spell module and must
be side-effect free.

- [x] Test nearest eligible, deterministic tie, genus, holy, Naga/Snake,
  special casters, firewood, player, charm, wall, and interception cases.
- [x] Observe target tests fail before implementing the owner.
- [x] Implement source-aligned selection using catalog genus and stable ECS
  queries; trace the chosen ray through `trajectory.to_target`.
- [x] Verify the target tests pass, including stale selected-entity checks.

## Task 2: Four effect modules and shared state

**Files:** `policy/combat/monster_spells/{haste_other,might_other,
invisibility_other,heal_other}.lua`; extract a focused monster invisibility
apply method from the self spell if needed. Tests:
`tests/monster_ally_support_effects_test.lua`,
`tests/monster_spell_coverage_test.lua`.

- [x] Add failing coverage and effect tests for all four modules and the
  actual speed, melee, visibility, and HP consumers.
- [x] Resolve Haste/Might through `monster_support.boons`; Invisibility
  through the existing monster enchant component; Heal Other through the
  existing HP owner and source `3 + 2d(spell_hd/2)` formula.
- [x] Avoid a shared spell-ID switch; use one module and one imported spell
  ID per effect. Check status already active or full HP in each planner.
- [x] Verify focused Lua tests and existing self-support tests pass.

## Task 3: Live integration and boundary verification

**Files:** `internal/game/monster_ally_support_test.go`, sparse book/effect
fixtures under `internal/game/testdata/monster-ally-support/`,
`docs/port-inventory.md`, `docs/ecs-architecture-roadmap.md`.

- [x] Make a source-shaped book caster select an allied recipient and spend
  the selected spell slot in a real game turn.
- [x] Save/restore active recipient status and compare the next turn's
  events, intent, and named RNG state; check a one-file effect override.
- [x] Run the full Lua suite, affected Go game tests, build, vet, style, and
  staged diff check. The exhaustive `go test ./...` suite has a known
  unrelated ten-minute corpse-test timeout and is deferred to a broader
  milestone boundary, per the user's category-level testing preference.
- [x] Review source fidelity, update exact coverage docs, and commit the
  whole family once. Fast-forward local `main` after verification.
