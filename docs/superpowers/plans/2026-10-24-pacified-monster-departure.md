# Pacified Monster Departure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans. Checkboxes track this one monster-lifecycle
> category, which is committed and pushed as a single change.

**Goal:** Make pacified monsters find an exit and leave without death
rewards or orphaned state.

**Architecture:** A Lua AI owner selects and caches a reachable exit. The
existing decision and movement systems execute ordinary intents. A small
post-movement system dismisses monsters once the source exit condition holds.

**Tech Stack:** Lua rules and `_test.lua` tests, Akara ECS, Go grid/save,
Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-24-pacified-monster-departure-design.md`

## Global constraints

- Work in `/Users/dylanknuth/src/dcrawl-go` on user-authorized `main`.
- Commit one contiguous category and push `origin/main`.
- Keep game policy in Lua; Go only exposes generic world services.
- Comment each Lua function's why and how; lines <=120 columns.
- Use production IDs and schemas in tests; no copied declaration tables.

## Review focus

- A monster on an exit leaves immediately after its action.
- A nearby monster chooses a reachable exit and does not attack the player.
- A blocked exit does not trap the AI in a permanent WAIT loop.
- Dismissal removes carried gear and actor links without a corpse or XP.
- A saved traveling monster resumes its route after restore.

### Task 1: Exit selection and route state

**Files:** `policy/ai/pacified_departure.lua`, focused `_test.lua`.

**Interface:** `departure.intent(ctx, monster, state, position)` returns
a saved AI state and an ordinary move or wait intent, or `nil` for no
reachable exit. It reads
terrain, travel features, and the trap ECS roster, then caches coordinates
in the saved AI target.

- [x] Write and run a failing live stair-departure test.
- [x] Implement nearest reachable exit and fallback.
- [x] Run Lua route/blocked-route and game route/restore tests.

### Task 2: Live decision and dismissal

**Files:** `systems/monster_decision.lua`,
`systems/monster_pacified_departure.lua`,
`policy/ai/pacified_departure.lua`, Go game integration test.

**Interface:** Decision reads the route owner before neutral wandering.
The post-move system calls `departure.complete(ctx, monster)` after movement.
Completion clears ownership links and belongings, removes actor occupancy,
and destroys the monster without death hooks.

- [x] Cover live departure, inventory, XP, and restore.
- [x] Implement decision and post-movement dismissal.
- [x] Run focused game and Lua tests.

### Task 3: Integration

**Files:** `docs/port-inventory.md`, `docs/modding.md`.

- [x] Document the AI owner and replace the obsolete movement gap with
  the remaining unique-monster exceptions.
- [x] Run relevant Lua, game, build, format, and diff checks once.
- [x] Review source semantics and save invariants; fix material findings.
- [x] Commit this category and push `main`.
