# Potion of Might Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the Fighter's starting might potion affect ordinary melee, expire on source aut timing, and survive saves.

**Architecture:** A pure duration rule, player-owned ECS status, ordered quaff/decay systems, a combat input flag, and a read-only HUD light.

**Spec:** `docs/superpowers/specs/2026-10-13-potion-might-design.md`

## Task 1 — Pure duration and combat rules

- Add RED tests for initial/repeated quaff rolls, 800-aut cap, valid ranges, action decay, and expiry.
- Implement the pure potion duration rule and source messages.
- Add scripted combat tests for hit bonus placement, armour, and no bonus draw on misses; add `Mighty` to `PlayerAttackInput` and apply the extra draw.
- Run focused tests and commit this rule category.

## Task 2 — Live game state and save continuation

- Add RED tests for starting potion quaff, item consumption, rat scheduling, repeat quaff, 9/10-aut action decay, expiry, and save/load continuation.
- Add player ECS duration state, register it, serialize optionally in version-6 snapshots, and validate restore ownership/range. Route `POT_MIGHT` through the existing quaff command/system; decrement after player actions.
- Keep existing curing behavior and unsupported-potion notice intact. Run focused tests and commit the game-state category.

## Task 3 — HUD and integration

- Add RED render test for the `Might` light and terminal choice test for selecting the starting might potion.
- Render the light, update help and port inventory, then run full tests, vet, build, and one 79×24 quaff/save/load smoke.
- Request a read-only whole-branch review, fix Critical/Important findings using RED→GREEN, and fast-forward merge into local Go `main`.
