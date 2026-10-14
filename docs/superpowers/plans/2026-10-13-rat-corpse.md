# Rat Corpse Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Source-backed corpse drop, decay, pickup refusal, and save continuation for the fixed rat.

**Spec:** `docs/superpowers/specs/2026-10-13-rat-corpse-design.md`

## Task 1 — Pure rules and ECS state

- Write failing scripted tests for drop and decay rolls, bounds, skeleton reset, and final removal.
- Implement rules in `internal/monster`, register an ECS Corpse component, and run focused tests.

## Task 2 — Game lifecycle and presentation

- Write failing integration tests for eligible kill, pre-dead cleanup, placement, visible name/glyph, stationary pickup, and the 200-aut boundary.
- Queue corpse creation in the death system and apply it after the Akara update. Age floor corpses after a completed player turn. Keep portable item pickup working when sharing a tile.

## Task 3 — Save and finish

- Write failing round-trip and invalid-record tests. Add optional save field and restore checks without changing version-6 legacy saves.
- Run full tests, vet, build; review the whole branch read-only; fix Important/Critical findings; commit the category and fast-forward merge to local Go `main`.
