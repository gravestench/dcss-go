# Monster Life and Magic Draining Contacts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve source monster life, speed, stat, and magic-drain melee flavours.

**Architecture:** Select abstract Drain Stat in the attack sequence. Keep effect rules in one focused Lua life-drain policy and dispatch them from the existing monster flavour owner. Save state through existing ECS owners.

**Tech Stack:** Go test runner, embedded Lua rules, Akara ECS components.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-life-drain-contact-design.md`

## Global Constraints

- Keep rules in `.lua` files, with no inline Lua in Go.
- Use named constants for attack flavour IDs and 120-character maximum lines.
- Commit this contiguous contact-flavour category to the authorized Go `main` branch.

## Review Focus

- Negative-energy immunity must prevent both bonus damage and lasting drain.
- The weapon brand proc chance must not leak into natural Vampiric contact.
- Scarab's speed roll must precede its vampiric heal draw.
- Each Drain Stat contact must independently choose a stat.
- A zero-damage or missed contact must leave health, magic, and status unchanged.

---

### Task 1: Contact selection and tests

**Files:**
- Modify: `internal/modfs/builtin/constants/attack_flavours.lua`
- Modify: `internal/modfs/builtin/constants/pan_lord_traits.lua`
- Modify: `internal/modfs/builtin/policy/combat/monster_attack_sequence.lua`
- Modify: `internal/modfs/builtin/policy/combat/melee_actions.lua`
- Create: `internal/script/testdata/lua/tests/monster_life_drain_contact_test.lua`

**Interfaces:**
- Produce `sequence.contact_flavour(ctx, flavour_id)` returning one named source ID.
- Consume its result in both monster/player and monster/monster contact paths.

- [x] Write Lua tests for each Drain Stat choice on successive contacts and for live melee routing.
- [x] Run the focused Lua test and confirm it fails on unresolved `AF_DRAIN_STAT`.
- [x] Add named IDs and resolve Drain Stat before attacker-specific overrides.
- [x] Run the focused Lua test and confirm those cases pass.

### Task 2: Life-drain contact effects

**Files:**
- Create: `internal/modfs/builtin/policy/combat/monster_attack_flavours/life.lua`
- Modify: `internal/modfs/builtin/policy/combat/monster_attack_flavours.lua`
- Modify: `internal/script/testdata/lua/tests/monster_life_drain_contact_test.lua`
- Modify: `docs/port-inventory.md`

**Interfaces:**
- Produce `life.drain`, `life.vampiric`, `life.scarab`, `life.pain`,
  `life.antimagic`, and `life.drain_speed`, each `(ctx, hit) -> boolean`.
- Consume existing health, slow, drain, and antimagic policies; keep the
  main flavour dispatcher as a lookup of named source IDs.

- [x] Add player and monster tests for resistance, damage, healing, MP loss,
  ghost-moth healing, speed slow, and miss/zero-damage gates.
- [x] Run the focused Lua test and confirm the missing effects fail.
- [x] Implement source contact rules without copying weapon-brand chances.
- [x] Run focused Lua, adjacent melee, and distortion tests; review
  `git diff --check`, style checker output, and the updated inventory.
- [x] Commit and push one life-drain contact category.
