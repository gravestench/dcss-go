# Monster Flame Conjurations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Port Marshlight, Holy Flames, and Stoke Flames as live monster spells.

**Architecture:** Keep spell selection in the existing per-spell Lua modules. Generalize foxfire's owner-sensitive behavior, reuse saved cloud and summon state, and resolve inferno death through the existing Lua actor-death hook.

**Tech Stack:** Go runtime, Akara ECS, embedded Lua rules, source-traced DCSS reference.

**Spec:** `docs/superpowers/specs/2026-10-19-monster-flame-conjurations-design.md`

## Global Constraints

- Preserve the pinned C++ source behavior and saved actor/cloud state.
- Keep Lua source in files; no inline Lua in Go.
- Keep lines at most 120 characters and explain ownership, why, and how in comments.
- Commit this contiguous spell category, then merge and push `main`.

## Review Focus

- A monster foxfire must attack the caster's enemy, including the player, without granting player kill credit for hostile damage.
- No caster may create foxfire inside an occupied or blocked cell.
- Holy clouds skip prior clouds, actors, walls, and sanctuary without changing unrelated clouds.
- Inferno explosion applies Fire Storm's partly irresistible lava damage exactly once.
- Save/restore preserves owner, source, expiry, cloud cells, and next-action RNG.

---

### Task 1: Actor-neutral foxfire and Marshlight

**Files:** `policy/magic/effects/summons/foxfire.lua`, `policy/magic/effects/summons/blast.lua`, `policy/combat/monster_spells/marshlight.lua`, Lua tests.

**Interfaces:** Foxfire exposes `spawn(ctx, owner, source_id, power, cap)` and `act(ctx, entity, origin)`. Blast target search takes the acting construct.

- [ ] Write Lua tests for monster ownership, two fair adjacent foxfires, enemy targeting, and damage.
- [ ] Confirm the tests fail without Marshlight.
- [ ] Make the shared foxfire policy actor-neutral and add the spell plan/resolve.
- [ ] Run the new tests and existing player Foxfire tests.

### Task 2: Holy cloud ring

**Files:** `policy/combat/monster_spells/holy_flames.lua`, Lua test.

**Interfaces:** A selected-foe plan is revalidated at cast time; cloud cells use `policy.clouds.placement.place`.

- [ ] Write Lua tests for adjacent eligible and excluded cells.
- [ ] Confirm the tests fail without Holy Flames.
- [ ] Place the source-duration holy cloud ring through the existing world owner.
- [ ] Run focused tests.

### Task 3: Creeping inferno lifecycle

**Files:** `policy/combat/monster_spells/stoke_flames.lua`, `policy/combat/monster_flames/inferno.lua`, `systems/actor_death.lua`, Lua tests.

**Interfaces:** The existing death system invokes `inferno.on_death(ctx, entity, definition, position)` through `death_hooks.run` once before actor deletion. The spell summons one source-owned inferno.

- [ ] Write Lua tests for summon ownership, source duration, and death explosion.
- [ ] Confirm the tests fail without Stoke Flames.
- [ ] Implement summon and explosion with monster beam lava resistance and cloud aftermath.
- [ ] Run focused tests, including save validation.

### Task 4: Live integration and category gate

**Files:** `internal/game/monster_flame_conjurations_test.go`, sparse spellbook overlays, port inventory, port slice note.

- [ ] Cast all three through live monster spellbooks and verify save/restore continuation.
- [ ] Run the full Lua suite, focused game suite, `go build ./...`, and `sh scripts/check-go-style.sh`.
- [ ] Review the category diff, commit once, fast-forward `main`, and push to `origin`.
