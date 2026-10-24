# Live Monster Flight and Sight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task by task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make monster flight and sight follow current equipment and
saved actor traits.

**Architecture:** The equipment owner supplies one source-shaped active
artefact scan. Flight stays in the actor-wide flight owner; monster sight
gets a focused owner used by visibility and gaze rules.

**Tech Stack:** Embedded Lua, Akara ECS items, `_test.lua` tests.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-gear-capabilities-design.md`

## Global Constraints

- No inline Lua in Go; name shared IDs and constants.
- Comment every new function with why and how. Keep lines at 120 or less.
- Commit this category once to `main` and push after verification.

## Review Focus

- A spare artefact weapon must not grant flight or sight to a single wielder.
- A dual wielder's second active artefact weapon must grant its property.
- Removing a ring or armour must change the very next visibility or flight
  decision, with no cached projection.
- A black-based draconian job must fly despite its job catalog flag set.
- A mutant beast with Bat or Weird facets must use those saved facets for
  flight or sight.
- A derived undead actor based on a flying species must inherit flight.
- An ordinary monster with no sight gear must still fail to see an
  invisible player.

---

### Task 1: Active artefact scan

**Files:** `policy/combat/equipment.lua`,
`policy/combat/monster_resistance.lua`,
`policy/combat/monster_willpower.lua`, new `_test.lua` fixture.

**Interface:** `equipment.monster_artefact_value(ctx, monster,
definition, property_id)` returns the sum for valid active items. Use the
existing `equipment.worn` snapshot; enforce source item-use and slot class.

- [x] Write an ECS test for active weapon, spare weapon, dual wielder,
  non-item-user, and removal. Run it red on the missing function.
- [x] Implement the scan, then route resistance and willpower through it.
- [x] Run the new test and existing resistance/willpower tests to green.

### Task 2: Live flight

**Files:** `policy/combat/flight.lua`, flight `_test.lua`.

**Interface:** `flight.active(ctx, actor)` keeps its existing boolean API.
Monster branches read saved Pan lord, black draconian base, derived undead
base, Bat facet, current gear, and temporary flight without changing
player behavior.

- [x] Add failing ECS tests for ring, Flying body ego, artefact Flight,
  black draconian base, derived undead base, Bat facet, removal, and a
  habitat consequence.
- [x] Implement the source precedence in the flight owner.
- [x] Run focused flight, habitat, and web tests to green.

### Task 3: Live sight

**Files:** New `policy/combat/monster_senses.lua`,
`policy/potions/invisibility.lua`, `policy/combat/monster_gazes.lua`,
sight `_test.lua`.

**Interface:** `monster_senses.see_invisible(ctx, monster, definition)`
returns whether the actor can see invisible creatures. The player
visibility and monster gaze rules delegate to it.

- [x] Add failing ECS tests for ring, armour ego, artefact sight, removal,
  Weird facet, player illusion, and unseen player/gaze behavior.
- [x] Implement the owner and route both consumers.
- [x] Run focused visibility and gaze tests to green.

### Task 4: Category gate

**Files:** `docs/port-inventory.md` and this plan.

- [x] Review the full category against pinned source and one fresh reviewer.
- [x] Run affected Lua tests, Go build, line-width and diff checks.
- [x] Commit once, push `origin main`, and verify clean HEAD.
