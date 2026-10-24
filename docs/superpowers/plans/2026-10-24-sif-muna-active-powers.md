# Sif Muna Active Powers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all three Sif Muna active powers usable through Lua rules.

**Architecture:** Ability modules use shared divine costs and spell owners.
A saved ECS component and Lua system own Channel Magic's timed MP recovery.
The generic ability command carries selected spell IDs into Lua resolution.

**Tech Stack:** Go runtime, embedded Lua mod, Akara ECS.

**Spec:** `docs/superpowers/specs/2026-10-24-sif-muna-active-powers-design.md`

## Global Constraints

- Production rules stay in `.lua` files, never Go strings.
- Shared IDs are declared once and imported where used.
- Explain why and how every Lua function works; explain each system's theory.
- Prefer 80-character lines; keep all handwritten lines below 120 characters.
- Commit this one contiguous category on `main` and push after verification.

## Review Focus

- Empty spellbook or no known spells must produce a free refusal.
- Cancellation must not consume time, MP, piety, or the selected spell.
- Exegesis must pay the selected spell's resource cost while leaving its
  learned slot unchanged.
- A full MP pool must not corrupt channel timing or exceed max MP.
- Save/restore must retain channel duration and reject invalid saved values.

---

### Task 1: Selection and ability registration

**Files:** `internal/modfs/builtin/ids/abilities.lua`,
`internal/modfs/builtin/policy/abilities/sif_muna/*.lua`,
`internal/modfs/builtin/policy/commands/abilities.lua`,
`internal/script/testdata/lua/tests/religion_sif_muna_active_powers_test.lua`.

**Interfaces:** Register `SIF_MUNA_CHANNEL_ENERGY`,
`SIF_MUNA_FORGET_SPELL`, and `SIF_MUNA_DIVINE_EXEGESIS` with the live
ability registry. Carry `input.spell_id` to the resolved ability intent.

- [ ] Add tests for ranks, costs, missing and cancelled selection.
- [ ] Add stable IDs and three focused Lua ability modules.
- [ ] Pass focused Lua tests.

### Task 2: Shared spell behavior and channel timer

**Files:** `internal/modfs/builtin/policy/character/spell_learning.lua`,
`internal/modfs/builtin/policy/magic/invoke.lua`,
`internal/modfs/builtin/schemas/religion_sif_channel.lua`,
`internal/modfs/builtin/systems/religion_sif_channel.lua`,
`internal/modfs/builtin/constants/component.lua`, and relevant save policy.

**Interfaces:** `learning.forget(ctx, player, spell_id)` remains the sole
known-slot remover. The existing spell effect registry dispatches Exegesis
from a documented mode with the spell's normal resource payment and no
learned-slot requirement. The channel
system ages and restores MP on player actions, with saved remaining aut.

- [ ] Test channel roll, aut scaling, maximum MP, abandonment, and restore.
- [ ] Test Exegesis against known and library-only spells through real effects.
- [ ] Implement the shared owners and pass focused Lua tests.

### Task 3: Integration and delivery

**Files:** `internal/game/religion_sif_muna_active_powers_test.go`,
`docs/port-inventory.md`, `docs/modding.md`.

- [ ] Test all three powers through the game command bridge.
- [ ] Run focused Go and Lua tests, build, and changed-file style checks.
- [ ] Review source behavior and one-category diff, then commit and push.
