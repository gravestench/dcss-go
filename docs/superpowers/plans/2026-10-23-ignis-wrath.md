# Ignis Wrath Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement
> this plan. Commit the whole domain after integrated verification.

**Goal:** Complete Ignis's shaft, fire champion, and elemental wrath.

**Architecture:** Lua owns deity choice, shaft rules, target choice, and
champion policy. A typed pending travel effect crosses into the existing
Go level staging transaction because generation and session commit are
engine work. A saved ECS marker changes ordinary monster combat, movement,
and visibility through their existing owners.

**Spec:** `docs/superpowers/specs/2026-10-23-ignis-wrath-design.md`

## Tasks

### Task 1: Shaft transport

- [x] Trace current level generation, action lifecycle, and save boundary.
- [x] Add the typed pending shaft request and generic post-action transport
  transaction, including branch rules, Mountain Boots, and destination.
- [x] Cover loaded and newly generated destinations and failure rollback.

### Task 2: Fire champion

- [x] Add a saved monster marker and source-faithful candidate selection.
- [x] Read the marker in first-attack flavour, movement cost, visibility,
  and save validation without duplicating those mechanics in wrath.
- [x] Cover target guards, highest-HD tie selection, gameplay effects, and
  save and restore.

### Task 3: Integrated Ignis wrath

- [x] Replace the shaft and champion errors while preserving source
  fallthrough and elemental draw order.
- [x] Run focused Lua and Go scenarios, build, formatting, and line checks.
- [x] Update port inventory, commit one category, and push `main`.
