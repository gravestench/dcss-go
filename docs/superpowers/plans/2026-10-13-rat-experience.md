# Rat Kill Experience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Grant the fixed rat's source-derived XP on a player kill and show/persist progress to XL2.

**Architecture:** Pure `character` XP math; ECS `Progression` state; explicit combat kill attribution; death award; HUD projection; version-6 optional-field compatibility for existing saves.

**Spec:** `docs/superpowers/specs/2026-10-13-rat-experience-design.md`

## Task 1 — Source XP and progress rules

- Write RED tests for ordinary rat `exper_value = 1` with live 4 HP, Human XL1 threshold 9, and percent floor rounding.
- Implement bounded pure math from the pinned source with explicit unsupported-input rejection; run focused tests and commit.

## Task 2 — ECS attribution and persistence

- Write RED game tests for one XP on a player kill, zero on pre-dead cleanup, no duplicate credit, save/load, old-version-6 omission defaulting zero, and malformed XP rejection.
- Add `Progression` to Akara stores/snapshot/restore. Record player-caused lethal damage during combat, award in death handling, and expose total XP/XL in `View`. Keep the single-rat 0–1 XP invariant.
- Run focused game/save tests and commit.

## Task 3 — HUD and integration

- Write RED terminal tests for `XL:  1 Next:  0%` before a kill and `11%` after it; implement source-shaped HUD text and update port inventory.
- Run full `go test ./...`, `go vet ./...`, `go build ./...`; smoke a 79×24 kill and save/load. Obtain one read-only branch review, repair Important/Critical findings with RED→GREEN, and fast-forward merge into local Go `main`.
