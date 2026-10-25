# Ru Sacrifice History Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement
> this plan natively as one category, then commit and push it.

**Goal:** Save accepted Ru mutation count and apply its Demonspawn silver
effect through the existing Lua owners.

**Architecture:** Add one field to the player-owned `religion.ru` schema.
Ru acceptance updates it; the existing silver policy reads it. No new Go
gameplay dispatch is needed.

**Tech Stack:** Lua rules and Akara components, Go snapshot tests.

**Spec:** `docs/superpowers/specs/2026-10-24-ru-sacrifice-history-design.md`

## Global constraints

- Keep gameplay policy in real embedded Lua files.
- Keep handwritten lines at or below 120 columns and explain the source
  quirk beside the silver calculation.
- Do not read the C++ checkout at build or runtime.

## Review focus

- A rejected offer keeps the lifetime count.
- A new offer keeps the lifetime count.
- Arcana adds three although it is one accepted menu choice.
- The count survives save/restore and invalid negative state is rejected.
- Shapechange continues to take priority over mutation-based silver.

## Task 1: Persist Ru history

**Files:** `internal/modfs/builtin/schemas/religion_ru.lua`,
`policy/religion/gods/ru.lua`, `policy/religion/ru/offers.lua`,
`policy/religion/ru/resolution.lua`, `policy/religion/validation.lua`,
`internal/script/testdata/lua/tests/religion_ru_resolution_test.lua`.

- [x] Add `sacrifice_mutations` as a default-zero `int64` field and bump
  the schema version.
- [x] Initialize a fresh Ru history to zero; preserve existing history
  through rejoining and offer replacement.
- [x] On acceptance, add `#selected` after successful mutation grants;
  rejection must leave it alone.
- [x] Reject negative saved values; test ordinary, Arcana, rejection,
  and offer carryover with production definitions.

## Task 2: Apply the silver consequence

**Files:** `internal/modfs/builtin/policy/combat/monster_missile_egos/silver.lua`,
`internal/script/testdata/lua/tests/religion_ru_silver_test.lua`.

- [x] Keep the baseline minimum silver roll and shapechange branch.
- [x] For Demonspawn with positive saved sacrifice count, suppress the
  mutation-based silver term as the pinned source does. Other players
  retain the present calculation.
- [x] Test the policy with production schemas and mutation records.

## Task 3: Integrated verification and release

**Files:** `internal/game/religion_ru_history_test.go`,
`docs/modding.md`, `docs/port-inventory.md`.

- [x] Verify acceptance and snapshot/restore in a real game.
- [x] Update modding and port coverage for the new saved history.
- [x] Run focused Lua and Go tests, build `cmd/crawl`, run the Go style
  check, and inspect `git diff --check`.
- [x] Commit one Ru history category on `main` and push `origin/main`.
