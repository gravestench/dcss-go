# Human Fighter Regeneration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore HP and MP over player action auts using the pinned DCSS rates and saved fractional counters.

**Spec:** `docs/superpowers/specs/2026-10-13-human-fighter-regeneration-design.md`

## Task 1 — Pure survival rule

- Add RED scripted tests for 18-HP/1-MP rates, full-HP counter accumulation, full-MP freeze, variable-aut random rounding and draw order, multiple-point restoration, and bad inputs.
- Implement the pure Human/Fighter regeneration calculation, using a named roller and integer aut; run focused tests and commit this rule category.

## Task 2 — ECS integration and saves

- Add RED game tests for damaged player recovery through waits, rat-turn exclusion, deterministic save continuation, optional old-save field, and save ownership/range validation.
- Add an ECS regeneration component and after-player-action system. Serialize it optionally in version 6, initialize to zero, validate restore, and update port inventory.
- Run full tests, vet, and build; obtain a read-only whole-branch review and fix Important/Critical findings with RED→GREEN. Fast-forward merge into local Go `main`.
