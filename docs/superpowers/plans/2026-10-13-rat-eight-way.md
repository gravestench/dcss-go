# Eight-Direction Rat Movement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Correct the fixed rat's local movement and attack adjacency to include diagonals.

**Spec:** `docs/superpowers/specs/2026-10-13-rat-eight-way-design.md`

## One cohesive category

- Write failing tests for diagonal melee, diagonal movement, blocked diagonal fallback, cardinals, and different-floor wait.
- Update the target step choice in `game.chooseMonsterIntent` without new state or RNG.
- Update the port inventory, run full tests/vet/build, obtain read-only whole-branch review, fix Important findings, commit and fast-forward merge into local Go main.
