# Live Monster Willpower Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task by task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all live monster willpower decisions reflect equipment,
artefacts, and timed conditions.

**Architecture:** `policy.combat.monster_willpower` owns the derived actor
value. `policy.magic.effects.zaps.will` retains saving-throw arithmetic
and delegates its target path to the owner.

**Tech Stack:** Embedded Lua, Akara ECS equipment, `_test.lua` tests.

**Spec:** `docs/superpowers/specs/2026-10-24-live-monster-willpower-design.md`

## Global Constraints

- No inline Lua in Go; use production Lua modules and named IDs.
- Keep each new function commented with why and how and lines within 120 columns.
- Commit one contiguous category to `main` and push after verification.

## Review Focus

- An invulnerable monster remains invulnerable even while wearing Folly.
- A single wielder's spare artefact does not grant a willpower bonus.
- Lowered Will halves the total after gear and Trog's Hand.
- Removing an equipped item immediately changes the next saving throw.
- A caster's Guile item reduces the target's effective will by eighty
  without changing the target's own derived willpower.
- Fixtures without equipped items expose an empty equipment query, so
  they exercise the same live willpower rule.

---

### Task 1: Live willpower owner

**Files:** Create `internal/modfs/builtin/policy/combat/monster_willpower.lua`;
create `internal/script/testdata/lua/tests/monster_willpower_equipment_test.lua`.

**Interface:** `willpower.level(ctx, monster, definition)` returns the
nonnegative source willpower integer, or the invulnerable sentinel.

- [x] Write production-item ECS tests for the source order and review cases.
- [x] Run the new Lua test and observe the missing-owner failure.
- [x] Implement the owner and rerun the test to green.

### Task 2: Actor-aware consumers

**Files:** Modify `policy/magic/effects/zaps/will.lua` and the Phantom
Mirror resolver under `policy/magic/effects/summons`.

**Interface:** `will.resists(ctx, definition, power, target, stream)`
retains its existing return and random draws. Live targets read
`willpower.level`; targetless probes retain their pure catalog formula.
`will.margin(ctx, definition, power, target, stream)` returns the source
rolled `check_willpower` integer, which Phantom Mirror uses directly.
Add a final optional `source` entity argument for the caster's Guile item;
pass it from every live willpower check whose source actor is known.

- [x] Add a saving-throw test where equipment changes the result and
  the spell stream still makes exactly two draws.
- [x] Add a margin test and route Phantom Mirror duration through the
  same source roll.
- [x] Add a caster-Guile regression case and pass source actors through
  every live will check that knows its caster.
- [x] Route live consumers and remove duplicated status arithmetic.
- [x] Run the affected hex, status, and mirror Lua tests.

### Task 3: Category gate

**Files:** Update `docs/port-inventory.md` and this plan.

- [x] Review source order, every actor-aware willpower read, and the diff.
- [x] Run focused Lua tests, Go build, style and line-width checks, and
  `git diff --check`; resolve new findings.
- [x] Commit once, push `origin main`, and verify clean HEAD.

The affected Lua suite passed after the fixture corrections. The Go style
script still reports its pre-existing 229 findings; this category changes
no Go files. The full suite was stopped because 720 Lua fixtures make it a
long-running gate for this focused category.
