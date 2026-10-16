# Hostile Ranged Reflection Implementation Plan

**Goal:** Return every currently implemented blockable hostile shot from
the player to its shooter when a Lua reflector capability is worn.

**Design:** `docs/superpowers/specs/2026-10-15-ranged-reflection-design.md`

**Method:** Make the entire current hostile ranged category coherent in
one pass. Keep the production rule in Lua, write gameplay tests in
`_test.lua`, review the integrated change, and make one commit.

**Source ruling:** A returned thrown or launched missile cannot be blocked
by its original shooter (`attack.cc:1256-1258`). A returned Slug Dart beam
can be blocked, and its monster shield bonus rolls before the bypass roll
(`beam.cc:4785-4830`).

## Task 1: Shared reflection rule and test fixture

**Files:**
- Create `policy/combat/reflection.lua`.
- Create `tests/fixtures/ranged_reflection.lua` and
  `tests/ranged_reflection_test.lua` in the Lua test overlay.

- [x] Pin the source gate and return trajectory in tests using actual
  amulet content and a deterministic RNG context.
- [x] Implement capability-driven reflection detection, live monster
  defense projection, damage ownership, and common messaging.
- [x] Prove a normal shield block still stops the shot and that removing
  the reflector disables the return.

## Task 2: All current hostile missiles

**Files:**
- Modify `policy/combat/ranged_actions.lua` and the focused hostile
  missile modules only where their return payload needs it.
- Modify common monster poison and launcher-brand policies only if the
  current owner route lacks a monster-target equivalent.

- [x] Test stone, poisoned dart, and sling-bullet launcher routes through
  their real action coordinator: returned hit, miss, and target death.
- [x] On a block, resolve the same attack against the original shooter
  once. Apply poison and the current launcher brands only on a return hit.
- [x] Keep shield practice, block count, attack cost, and normal damage
  behavior unchanged.

## Task 3: Blockable hostile spell

**Files:**
- Modify `policy/combat/monster_spells/slug_dart.lua` and its focused
  spell resolver if needed.

- [x] Test Slug Dart block and return through its real spell effect.
- [x] Preserve spell hit/AC/EV rolls and source attribution on the return.

## Task 4: Boundary verification and commit

**Files:**
- Update `docs/port-inventory.md` and `docs/modding.md`.

- [x] Test a modded reflector with the existing named capability and no
  central ID edit.
- [x] Run Lua tests, representative game integration tests, build, vet,
  exporter and style checks, then one broad Go suite at the category
  boundary. Investigate only concrete failures.
- [x] Review the staged diff and commit once for the full reflection
  category. Fast-forward local `main` and return to the active branch.
- [x] Leave `dcrawl-save.json` untracked and untouched.
