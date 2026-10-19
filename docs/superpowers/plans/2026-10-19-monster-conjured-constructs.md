# Monster Conjured Constructs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task.
> The user requested native execution and one commit for this category.

**Goal:** Playable monster Battlesphere, Conjure Ball Lightning, and Spellforged Servitor with saved ECS actors.

**Architecture:** Monster spell files reuse actor-neutral Lua summon policies.
A cast signal drives owner-bound battlespheres. A saved servitor spell list
feeds the ordinary monster spellbook and AI path.

**Tech Stack:** Go turn runner, embedded Lua policies and systems, Akara components, Go save format.

**Spec:** `docs/superpowers/specs/2026-10-19-monster-conjured-constructs-design.md`

## Global constraints

- Keep all game policy and all Lua tests in `.lua` files under the embedded or test mod tree.
- Dynamic mutable actor state survives save/restore as Akara components.
- Use source names and rules; keep Lua lines at most 120 characters and comment why and how.
- Merge the category commit into local `main` and push `origin/main`.

## Review focus

- A dead caster cannot trigger an orphaned battlesphere.
- A monster ball's explosion must use monster spell RNG and player AC.
- A servitor must not reselect spells when its caster changes state.
- Player-owned constructs must retain their existing cast and action paths.
- A saved monster servitor must keep slot order and frequencies after restore.

## Tasks

### 1. Actor-neutral construct owners

**Files:** `policy/magic/effects/summons/battlesphere.lua`,
`ball_lightning.lua`, `blast.lua`, `systems/magic_summon_battlesphere.lua`.

- [x] Add failing Lua tests for monster ownership, the caster's sight and
  conjuration trigger, monster RNG and AC, and player-path preservation.
- [x] Extend creation, target choice, damage, messages, and trigger to read
  saved owner and actor state. Use source HD and spell power formulas.
- [x] Run the focused Lua rule tests and correct failures.

### 2. Monster cast entry points

**Files:** three new `policy/combat/monster_spells/<spell>.lua` modules,
`systems/attack_spell.lua`, `systems/magic_summon_battlesphere.lua`.

- [x] Add sparse source spellbook fixtures and failing live cast tests.
- [x] Implement self-target plans and source power setup, then emit the
  successful monster-cast signal after resolution.
- [x] Verify a later conjuration triggers the saved sphere.

### 3. Saved servitor book

**Files:** `schemas/magic_summon_servitor.lua`,
`policy/magic/effects/summons/spellforged_servitor.lua`,
`policy/combat/monster_spellbook.lua`, `systems/magic_summon_construct_decision.lua`.

- [x] Add failing Lua tests for Frederick's priority list, HD, HP, spell
  weights, and saved book projection.
- [x] Store the ordered IDs and rolled frequencies on the servitor. Let
  generic monster AI use that book for monster-owned servitors.
- [x] Add a live save/restore test that continues the servitor's action.

### 4. Category gate and integration

**Files:** `docs/port-inventory.md`,
`docs/port-slices/monster-conjured-constructs.md`, tests above.

- [x] Run the focused game and Lua tests, full Lua suite, `go build ./...`,
  style check, line-length check, and `git diff --check`.
- [x] Review changed code against the pinned source, fix discrepancies, and
  commit the whole category once.
- [x] Fast-forward local `main`, push `origin/main`, and verify both heads.
