# Monster HP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Source-roll the fixed rat's HP from the committed monster catalog, preserving deterministic saves and one-XP kills.

**Spec:** `docs/superpowers/specs/2026-10-13-monster-hp-design.md`

## Task 1 — Pure HP roll

- Add failing scripted tests for source variance rounding, eight random2avg draws, final rounding, and the rat's 1–4 HP bounds.
- Implement pure monster HP generation with explicit input/roll validation and no global RNG.
- Run focused tests and commit this rules category.

## Task 2 — Scenario, XP, and saves

- Add failing tests for source-rolled rat HP, deterministic seed and save continuation, one-XP kills across valid HP, and restore rejection outside 1–4.
- Generate the rat's current/max HP at creation; relax the fixed XP rule to 1–4 HP and validate saved rat HP. Preserve old 4-HP saves without reroll.
- Update the port inventory. Run full tests, vet, and build; obtain a read-only branch review, fix Important/Critical findings with tests, and fast-forward merge into local Go `main`.
