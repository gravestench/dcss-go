# Monster Contact Blinks Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement
> this plan. The user chose native execution for these port slices.

**Goal:** Complete the Blink and Blink With melee flavour pair.

**Architecture:** Each melee round owns a local queue of blink contacts.
The flavour resolver records successful procs, then a focused Lua movement
policy merges and resolves them through the existing displacement owner.

**Tech Stack:** Embedded Lua policies and tests, Akara actor state, Go test
runner.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-contact-blinks-design.md`

## Global Constraints

- Preserve source chance and delayed movement order.
- Keep all rules in readable Lua and all durable state in existing owners.
- Commit the whole blink pair as one category and push Go `main`.

## Review Focus

- An attacker killed by a later contact must not blink.
- An anchored defender must not accompany a Blink With attacker.
- A blinked attacker with no adjacent partner cell must still move.
- Multiple matching contacts must schedule only one final effect.
- Departure movement must not spend a blink chance draw.

---

### Task 1: Add failing contact and resolution tests

**Files:** Create `internal/script/testdata/lua/tests/monster_contact_blinks_test.lua`.

- [x] Test the five review cases and the two source chance gates.
- [x] Run the focused Lua test and observe missing behavior.

### Task 2: Implement one round-owned blink queue

**Files:** Create `internal/modfs/builtin/policy/combat/monster_attack_flavours/blinks.lua`;
modify `monster_attack_flavours.lua`, `melee_actions.lua`, and the existing
displacement owner as required.

- [x] Record proc events on the round, merge identical entries, and resolve
      them after all contact slots.
- [x] Use ordinary blink landing for the attacker and reservoir sampling
      for the partner beside its new cell.
- [x] Run the focused test until it passes.

### Task 3: Verify and integrate

**Files:** Update `docs/port-inventory.md`.

- [x] Run related Lua and game tests, compile all Go packages, check style
      and diff, and request one read-only review.
- [x] Fix substantive findings, then commit and push one category.
