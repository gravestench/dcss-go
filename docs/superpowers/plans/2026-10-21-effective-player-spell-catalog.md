# Effective Player Spell Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan in the current session.
> Steps use checkbox syntax for tracking.

**Goal:** Derive all player-book spell eligibility from effective Lua book
definitions, with stable source and mod spell ordering.

**Architecture:** One Lua owner builds a book ID set and ordered spell list
from the layered catalog. It caches membership after registration freezes,
with test accessor changes invalidating that derived view. Character,
magic, and item-generation policy consume it. A separate source declaration
retains only nonbook invoked IDs.

**Tech Stack:** Embedded Lua definitions and tests, Go game integration,
Akara save state.

**Spec:** `docs/superpowers/specs/2026-10-21-effective-player-spell-catalog-design.md`

## Global constraints

- Commit one contiguous category on local `main` and push `origin main`.
- Keep production rules in `.lua` files, with `_test.lua` behavior tests.
- Import shared IDs where used; avoid inline multi-field declarations.
- Changed source lines stay at or below 120 characters.

## Review focus

1. Base book membership remains equal to all 109 source records by digest.
2. Adding or removing a spell in an overlay book changes every consumer.
3. A mod spell without `numeric_id` sorts deterministically after source IDs.
4. Missing spell references fail visibly; no stale cache masks an overlay.
   Repeated scope checks avoid a full item catalog scan.
5. Save/restore retains a selected Djinni schedule after the new ordering.

## Work

- [x] Add failing Lua tests for effective membership, ordering, scope,
      random books, Djinni and Wanderer eligibility, and effect coverage.
- [x] Implement `policy.magic.player_book_catalog` and migrate all runtime
      consumers to it. Keep only the nonbook invoked declaration.
- [x] Remove the redundant static book list and update modding and port
      inventory documentation.
- [x] Run focused Lua and Go integration tests, all-package compilation,
      formatting, line, style, and diff checks.
- [x] Review, correct findings, commit one category, and push `main`.
