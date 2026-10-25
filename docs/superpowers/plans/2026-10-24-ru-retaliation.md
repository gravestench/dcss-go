# Ru Damage Retaliation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port Ru's complete two-star damage retaliation through Lua.

**Architecture:** One ordered after-HP callback reads live Ru worship
and writes existing monster enchantments. Focused status-owner methods
accept the source's fixed durations without duplicating schemas.

**Tech Stack:** Go engine, Akara ECS, embedded Lua mod.

**Spec:** `docs/superpowers/specs/2026-10-24-ru-retaliation-design.md`

## Global Constraints

- Work on Go `main`, in one coherent category commit, then push.
- Keep game rules and tests in actual Lua files; no inline Lua in Go.
- Comment every new Lua function with its why and how.
- Prefer 80-character lines; never exceed 120.

## Review Focus

- Penance or switching gods removes the passive immediately.
- The chance roll precedes the source check when Ru's passive is active.
- An antimagic-immune target falls through to paralysis.
- An unblindable target falls through to corona.
- Repeated statuses extend saved time and continue after restore.

---

### Task 1: Reusable fixed monster statuses

**Files:**

- Modify: `internal/modfs/builtin/constants/monster_flags.lua`
- Modify: `internal/modfs/builtin/policy/combat/monster_enchant.lua`
- Reuse: `policy.magic.effects.statuses.enfeeble`,
  `policy.magic.effects.zaps.paralysis`, `policy.combat.monster_slow`,
  and `policy.combat.monster_hexes.status`.
- Test: `internal/script/testdata/lua/tests/religion_ru_retaliation_test.lua`

**Interfaces:** `enchant.apply_fixed_blind(ctx, monster, definition,
duration_aut)`.

- [x] Write the effect-branch test with production component schemas.
- [x] Confirm it fails before the fixed-blind owner exists.
- [x] Add named flag and fixed-blind duration extension.
- [x] Confirm the focused test passes.

### Task 2: Ru retaliation policy and registration

**Files:**

- Create: `internal/modfs/builtin/policy/religion/ru/retaliation.lua`
- Modify: `internal/modfs/builtin/policy/combat/player_health.lua`
- Modify: `internal/modfs/builtin/constants/damage_reaction_order.lua`
- Modify: `internal/modfs/builtin/constants/ru_powers.lua`
- Test: `internal/script/testdata/lua/tests/religion_ru_retaliation_test.lua`

**Interfaces:** `retaliation.on_damage(ctx, player, damage, cause,
attacker)` and `retaliation.register()`.

- [x] Pin rank, penance, chance, damage, HD, immune fallthrough, and
  the five saved effect branches in the Lua test.
- [x] Confirm the test fails before registration.
- [x] Implement the source roll order and register at the damage owner.
- [x] Run the focused test and adjacent damage-reaction tests.

### Task 3: Integrated continuation and release

**Files:**

- Modify: `docs/modding.md`
- Modify: `docs/port-inventory.md`
- Test: `internal/game/religion_ru_retaliation_test.go`

- [x] Exercise real monster HP loss, status save/restore, and next-turn
  continuation through the game action path.
- [x] Run focused Lua and Go tests, a `cmd/crawl` build, formatting,
  line-width, and `git diff --check`.
- [x] Review the whole category, commit once, and push `main`.
