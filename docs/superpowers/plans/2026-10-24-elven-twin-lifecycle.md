# Elven Twin Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this connected Lua category.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the linked Dowan and Duvessa attack, death, banishment,
spell, and permanent-power reactions in one category.

**Architecture:** `policy.monsters.elven_twins` owns identity and grief.
Attack contact and departure owners call it; Akara stores grief and
peace-history markers. Existing spell and status owners project effects.

**Tech Stack:** Lua rules, Akara ECS, Go save and test runner.

**Spec:** `docs/superpowers/specs/2026-10-24-elven-twin-lifecycle-design.md`

## Global Constraints

- Work on the user-authorized Go `main` branch; one category commit and
  push to `origin/main`.
- Keep all game-specific rules in Lua; no inline Lua in Go.
- Comment why and how in every Lua function; <=120 columns, 80 preferred.
- Import named monster, spell, component, and status IDs where used.

## Review Focus

- A missed player contact still angers both formerly pacified twins.
- An attack records piety conduct while the target is still neutral.
- Reconversion restores peace without granting nonlethal XP again.
- Only the twin on the same active floor responds to grief.
- A polymorphed Dowan keeps its current book while original identity
  still connects the pair.

### Task 1: Attack contact and peace history

**Files:** `policy/combat/player_contact.lua`,
`policy/religion/elyvilon/pacification.lua`, existing production contact
call sites, departure/decision/save owners, matching `_test.lua`.

**Interface:** `player_contact.report(ctx, target, definition)` records
religious conduct and then calls `pacification.anger(ctx, target)`.
`pacification.anger` switches an active marker's boolean off, resets AI
toward the player, and asks `elven_twins.anger_partner` to do the same.

- [x] Add tests for a missed contact, both twins' hostility, departure
  suppression, and nonlethal XP remaining credited.
- [x] Run focused tests and confirm the expected failures.
- [x] Implement the contact owner and update every production call site.
- [x] Make conversion, departure, and restore validation read the boolean.
- [x] Run focused tests to green.

### Task 2: Grief and source permanent statuses

**Files:** `schemas/monster_elven_twin.lua`, `constants/component.lua`,
`policy/monsters/elven_twins.lua`, `policy/combat/monster_spellbook.lua`,
`policy/combat/monster_support/boons.lua`,
`policy/magic/effects/statuses/monster_allegiance.lua`,
`policy/world/abyss.lua`, `systems/actor_death.lua`,
`systems/monster_decision.lua`, matching `_test.lua`.

**Interface:** `twins.grieve(ctx, departed, definition, position,
cause)` records grief for the live partner. `twins.maybe_energize(ctx,
survivor)` applies the pending source power when visible and eligible.
`spellbook.for_actor` projects Dowan's three changed slots from grief.

- [x] Add failing tests for death, banishment, same-floor lookup,
  polymorph, Dowan spell changes, Duvessa Berserk, and pending activation.
- [x] Add focused schema and grief owner; register death, banish, and
  Arena separation calls.
- [x] Teach the existing boon and allegiance owners source infinite
  duration, and project Dowan's spell slots without changing the catalog.
- [x] Activate pending grief before a monster decision when it sees the
  player; run focused Lua tests.

### Task 3: Integration and category boundary

**Files:** Go save tests, `docs/port-inventory.md`, `docs/modding.md`.

- [x] Add a Go restore test for pacification history after anger; Lua
  validates grief and permanent statuses through production owners.
- [x] Run focused Lua and game tests, `go build ./...`,
  `sh scripts/check-go-style.sh`, `gofmt -d`, and `git diff --check`.
- [x] Review the complete diff for source behavior, readability, and
  category scope; commit once and push `main`.
