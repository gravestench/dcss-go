# Ru Sacrifices Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all seventeen source Ru sacrifices offerable, actionable,
and saved through the Lua game rules.

**Architecture:** Per-sacrifice content and focused rule modules feed one
saved Ru offer owner. God time creates offers, and ordinary ability intents
accept or reject them. Existing mutation, skill, item, and piety owners
apply consequences.

**Tech Stack:** Embedded Lua, Akara ECS, Lua-rule harness, Go game tests.

**Spec:** `docs/superpowers/specs/2026-10-24-ru-sacrifices-design.md`

## Global Constraints

- Keep production behavior in Lua files; Go provides generic engine APIs.
- Commit each contiguous category once, then push authorized `main`. The
  source catalog and kill progress are one category; offer generation and
  sacrifice resolution are subsequent categories in this plan.
- Prefer 80-character Lua lines and never exceed 120 characters.
- Give each function and sacrifice module explanatory comments.
- Preserve source RNG gates and make file discovery order irrelevant.

## Review Focus

- Rejoining Ru clears stale offers and variant choices.
- A saved offer cannot be accepted after leaving Ru.
- A changed skill level updates acceptance piety without rerolling the offer.
- Failed placement or equipment changes do not leave a partial sacrifice.
- Canceled confirmations spend no turn, piety, or RNG.

---

### Task 1: Source catalog and saved offer state

**Files:** Add `content/ru_sacrifices/*.lua` and focused policy modules;
update `constants.catalog`, `schemas/religion_ru.lua`, `policy/religion/gods/ru.lua`.

**Interface:** Effective definition IDs and `ru.offer(ctx, player)` return
three saved choices with IDs, mutation variants, and piety quotes.

- [ ] Write registration, eligibility, selection, and seed-order Lua tests.
- [ ] Run them red against the current empty-offer state.
- [ ] Port all seventeen definitions, variant pools, and piety formulas.
- [ ] Run focused tests green.

### Task 2: Progress and god-time delivery

**Files:** Update `systems/actor_death.lua`, `policy/religion/upkeep.lua`,
Ru's god definition, and focused Lua death/upkeep tests.

**Interface:** Credited kills advance Ru progress; named god-time module
creates offers only after the saved delay and only with none outstanding.

- [ ] Write failing kill and god-time integration tests.
- [ ] Implement the source coin flip and god-time dispatch.
- [ ] Run the focused tests green.

### Task 3: Accept, reject, and consequences

**Files:** Add `policy/abilities/ru/*.lua`, focused Ru effect modules, and
tests; update `ids.abilities`, ability menu, mutation/skill/equipment
owners only where source sacrifice effects require it.

**Interface:** A selected offer and rejection resolve through ordinary
ability intents with cancellation, confirmation, and source timer reset.

- [ ] Write failing menu, acceptance, rejection, and restore tests.
- [ ] Implement all source sacrifices and their special consequences.
- [ ] Run focused Lua and game tests green.

### Task 4: Documentation, review, integration

**Files:** Update `docs/modding.md` and `docs/port-inventory.md`.

- [ ] Document adding a sacrifice and the saved offer contract.
- [ ] Run integrated Lua/game tests, build, and style check.
- [ ] Obtain whole-category code review and fix important findings.
- [ ] Commit and push the coherent Ru sacrifice category.
