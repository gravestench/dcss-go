# Vault Monster Spawn Behavior Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make authored monster sleep and patrol behavior live, persistent ECS state.

**Architecture:** The selected DES flags flow through the existing vault record
and factory. AI remains a Go-hosted Akara component; patrol anchor is a Lua
component read by a focused Lua wander policy.

**Tech Stack:** Go, Akara ECS, GopherLua, committed `.des` maps.

**Spec:** `docs/superpowers/specs/2026-10-20-vault-monster-spawn-behavior-design.md`

## Global Constraints

- Keep rules in Lua files, with no inline Lua in Go.
- Comment each new Lua function with why and how; keep lines at most 120 characters.
- Use imported IDs rather than repeating static strings.
- Keep one coherent implementation commit on `main` and push `origin main`.

## Review Focus

- A hostile vault actor sleeps by default; a friendly or neutral one does not.
- Source statues remain awake even in an otherwise sleeping vault.
- Both `generate_awake` on an expression and the map tag wake an actor.
- A sleeper hearing noise or taking damage wakes without losing its saved AI state.
- A patrol cannot drift from its saved anchor or be forged onto another actor.
- Existing non-vault summons and revival actors still start awake.

---

### Task 1: Source flags to live ECS state

**Files:** `policy/generation/vaults/placement.lua`,
`policy/population/vaults.lua`, `policy/population/factory.lua`,
`schemas/world_monster_patrol.lua`, `constants/component.lua`, and
`tests/vault_entity_placement_test.lua` under `internal/modfs/builtin/` or
`internal/script/testdata/lua/` as applicable.

**Interfaces:** Factory options `generate_awake` and `patrolling`; component
`world.monster_patrol` with `level_id`, `x`, and `y`.

- [x] Add failing placement tests for default sleep, both awake directives,
      neutral spawn, statues, and patrol anchor.
- [x] Run focused Lua tests and confirm failure.
- [x] Pass flags through placement and create the live AI/patrol state.
- [x] Rerun the focused test.

### Task 2: Wake and patrol decisions

**Files:** `policy/ai/awareness.lua`, `policy/ai/wander.lua`, new
`policy/ai/patrol.lua`, `systems/monster_decision.lua`,
`policy/world/noise.lua`, `policy/combat/monster_health.lua`,
`policy/combat/stab.lua`, and relevant Lua tests.

**Interfaces:** `patrol.target(ctx, entity, state, position)` selects an
anchor-area target; AI `sleep` produces WAIT until a wake trigger occurs.

- [x] Add failing tests for sight, noise, damage, sleeping stab, and bounded patrol movement.
- [x] Run focused Lua tests and confirm the expected failures.
- [x] Implement the focused Lua wake and patrol policies.
- [x] Rerun the focused tests.

### Task 3: Restore and integration

**Files:** `policy/save/monsters.lua`, `policy/save/vault_entities.lua`,
`tests/vault_entity_save_test.lua`, `docs/{modding,port-inventory}.md`.

**Interfaces:** Saved AI accepts targetless `sleep`. Patrol anchor agrees
with the actor's source vault origin.

- [x] Add tests that restore a sleeper and reject forged patrol anchors.
- [x] Run the focused tests red, implement validation, and rerun green.
- [x] Run the relevant script and game tests, `git diff --check`, and the Lua line-length check.
- [x] Commit the category on `main` and push `origin main`.
