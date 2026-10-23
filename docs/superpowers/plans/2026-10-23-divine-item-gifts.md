# Divine Item Gifts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Give Sif Muna, Trog, and Okawaru their source physical gifts.

**Architecture:** Effective god definitions select focused Lua modules.
The existing acquirement and item generation owners produce normal floor
items; the shared religion owner records gifts and timeouts.

**Tech Stack:** Lua policies and ECS components, Akara, Go integration.

**Spec:** `docs/superpowers/specs/2026-10-23-divine-item-gifts-design.md`

## Global Constraints

- Lua owns gift policy and content; Go only exposes generic engine context.
- Import IDs and shared constants where used; keep Lua functions commented.
- Keep generated items as real ECS records with god provenance.
- Use one commit for this contiguous gift category and push to `main`.

## Review Focus

- Unusable floor: no gift or counter change.
- Nonwearable armour or unwieldable weapon: retry another subtype.
- Known-spell book: avoid a useless fixed book; never give Sif a manual.
- Failed generation: release a unique claim and preserve gift eligibility.
- Repeated piety points: a new timeout must affect later candidates.

---

### Task 1: Pin gift outcomes in Lua tests

**Files:** `internal/script/testdata/lua/tests/religion_item_gifts_test.lua`

- [x] Add a production-schema fixture for piety, position, skills, and item
      generation state.
- [x] Cover Sif books, Trog weapons, Okawaru equipment and missiles,
      destructive terrain, source purpose, placement, counters, and timeout.
- [x] Run the focused test and confirm the missing behavior fails.

### Task 2: Extend direct acquirement for gods

**Files:** `internal/modfs/builtin/policy/scrolls/acquirement_offers.lua`,
`internal/modfs/builtin/policy/scrolls/acquirement/books.lua`,
`internal/modfs/builtin/policy/scrolls/acquirement/missiles.lua`

- [x] Let a god request one item without a scroll reservation.
- [x] Preserve god purpose and ID through generation and item placement.
- [x] Implement Sif's no-manual book selection and unknown-spell weighting.
- [x] Implement source usable missile types and gift stack quantity.
- [x] Preserve source gift quality separately from scroll acquirement,
      including brand and unique-item probabilities.
- [x] Apply divine equipment subtype weights and Trog's melee-only pool.
- [x] Keep Sif's original level-book size and 2–8 themed-book range.

### Task 3: Port god decisions

**Files:** `internal/modfs/builtin/policy/religion/gifts/{sif_muna,trog,okawaru}.lua`,
`internal/modfs/builtin/content/gods/{sif_muna,trog,okawaru}.lua`

- [x] Implement source gates, terrain check, messages, and timeout formulas.
- [x] Add each god's `gift_module` and validate its resolved definition.
- [x] Keep Sif, Trog, and Okawaru decisions out of the shared dispatcher.

### Task 4: Verify and integrate

**Files:** `docs/modding.md`, `docs/port-inventory.md`

- [x] Document direct item gifts and the god module contract.
- [x] Run focused Lua and game tests, `go build ./...`, and diff checks.
- [x] Commit the whole gift category and push to `origin/main`.
