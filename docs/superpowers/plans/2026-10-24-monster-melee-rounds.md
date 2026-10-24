# Monster Melee Rounds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve every source monster melee contact in one actor action.

**Architecture:** A Lua sequence owner selects current attacks and head
repetitions. Existing player and monster contact logic becomes one-contact
helpers called by a source-shaped round loop. Hydra heads remain saved ECS
state, initialized in the population owner.

**Tech Stack:** Embedded Lua, Akara ECS, source-traced `_test.lua` tests.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-melee-rounds-design.md`

## Global Constraints

- Use named IDs and shared Lua policies; no Go gameplay switch.
- Comment every new function with its why and how; keep lines <=120.
- Keep one contiguous category commit and push it to `main`.

## Review Focus

- A dying attacker or displaced defender ends its round before another roll.
- A normal monster does not inherit a hydra's repeated first slot.
- Authored heads override the natural 4..8 roll; Lernaean gets 27.
- Constriction's second slot cannot resolve twice.
- A hydra may retarget only adjacent enemies after losing its first target.
- A derived undead actor inherits downscaled base attacks, while an
  unrelated base annotation grants no attacks.
- A dual wielder's second contact must use its equipped offhand item.
- First-slot constriction ticks with its constrict attack damage.

---

### Task 1: Attack sequence and head state

**Files:** `policy/combat/monster_attack_sequence.lua`,
`policy/population/factory.lua`, a new `_test.lua` file.

**Interface:** `sequence.for_actor(ctx, actor, definition)` returns ordered
records with a source slot number and attack. It reads current
`MONSTER_HYDRA_HEADS` and skips `AT_NONE` contacts.

- [x] Test ordinary multiple slots, a single slot, saved hydra heads,
  Lernaean heads, derived-undead inheritance, and authored head
  preservation. Run red.
- [x] Implement sequence selection and spawn-time head rolls. Run green.

### Task 2: One complete round against the player

**Files:** `policy/combat/melee_actions.lua`, round `_test.lua`.

**Interface:** Keep `actions.monster(ctx, attacker, options)`; extract the
current body to a local one-contact function receiving the chosen attack.

- [x] Test two Ettin contacts in one action, single-contact constriction,
  and death stopping later contacts. Run red.
- [x] Implement ordered contact calls and stop conditions. Run green.

### Task 3: One complete round against a monster

**Files:** `policy/combat/melee_actions.lua`, round `_test.lua`.

**Interface:** Keep `actions.monster_target(ctx, attacker, target)`; use the
same sequence owner and live stop checks. Preserve special summons and
vines as action-level branches.

- [x] Test multi-contact damage against a durable ECS target and that
  death stops further contacts. Run red.
- [x] Implement target loop, including adjacent retargeting for living
  hydras with more heads. Run green.

### Task 4: Category gate

**Files:** `docs/port-inventory.md` and this plan.

- [x] Run affected Lua and Go tests, build, style, and diff checks.
- [x] Request one fresh source review and resolve substantive findings.
- [x] Commit once, push `origin main`, and verify clean HEAD.

The focused melee and neighboring Lua suites passed, as did the build and
diff checks. The repository-wide Go style script reports 229 existing
findings in unchanged Go files. A parallel `go test ./...` timed out after
ten minutes while the game, script, and terminal packages loaded large Lua
catalogs concurrently; each timed-out test passed when run on its own.
