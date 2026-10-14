# Curing Potion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the fixed Dungeon's curing potion quaffable with source healing, one-turn cost, and save continuation.

**Architecture:** Pure curing arithmetic, a validated `game` command and ECS quaff system, post-update item consumption, and a terminal choice screen that sends a selected item ID.

**Spec:** `docs/superpowers/specs/2026-10-13-curing-potion-design.md`

## Task 1 — Pure ordinary Human curing

- Add RED tests for `5 + random2(7)` healing, HP cap, and one named `potion` draw.
- Implement a pure `combat` or `character` curing function accepting a bounded roller and HP values. Reject invalid HP before drawing.
- Run focused tests and commit this contiguous rule.

## Task 2 — Game command, ECS effect, and saves

- Add RED tests for successful 10-aut quaff after pickup, full-health consumption without HP gain, wrong carrier or kind rejection, stack decrement, last-item destruction, rat scheduling, and save continuation.
- Add `CommandQuaff` with selected item ID and `IntentQuaff`. Validate before action; apply effect in the system order and consume after `World.Update`. Keep malformed saved items rejected by existing restore validation.
- Run game tests and commit integration.

## Task 3 — Terminal choice and verification

- Add RED UI tests for `q` potion list, inventory-letter selection, Esc cancellation, unavailable potion notice, and no-time rejection.
- Add the choice screen and update help/inventory labels and the port inventory.
- Run full `go test ./...`, `go vet ./...`, and `go build ./...`; smoke the 79×24 pickup/quaff/save/load flow. Obtain one read-only branch review, fix Important/Critical findings with RED→GREEN, and fast-forward merge into local Go `main`.
