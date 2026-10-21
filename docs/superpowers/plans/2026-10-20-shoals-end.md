# Shoals Finale and Barnacled Rune Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native implementation. Steps use checkbox
> syntax for tracking. The user authorized contiguous commits on `main` and
> pushes to `origin/main`.

**Goal:** Port all six Shoals:4 finales, twenty helpers, and the barnacled
rune through live play and saves.

**Architecture:** Keep DES as the authored geometry and directive source.
Use named Lua hooks for finale assembly and source script choices, a shared
end-vault controller path, and a Lua ECS component for false rune items.

**Tech Stack:** Go, gopher-lua, layered modfs, Akara ECS, DES, Bubble Tea.

**Spec:** `docs/superpowers/specs/2026-10-20-shoals-end-design.md`

## Global constraints

- Commit imported content; do not require or commit a C++ importer.
- Preserve source MAP bytes and source directive order.
- Put game policy in Lua with focused, commented functions and named IDs.
- Keep source stage and save rules generic across branch endings.
- Test the integrated family before the single category commit and push.

## Review focus

1. All six weighted finales and twenty helpers are selectable as source rules.
2. Controller child composition runs before optional maps and keeps its
   selected parent ID across whole-floor retries.
3. A mimic item never counts as a second rune and never grants progress.
4. The only real rune is sourced from the matching theme's selected child.
5. Save and restore detect altered parent, helper, or rune ownership.

---

### Task 1: DES corpus and scripted decisions

**Files:** `vaults/shoals_end/*.des`,
`policy/generation/vaults/shoals_end/*.lua`, branch and constants modules.

- [x] Import all 26 source definitions and audit the nonempty MAP rows.
- [x] Port controller, false-rune, ice, and border scripts into named hooks.
- [x] Add source corpus and hook outcome tests.

### Task 2: Composed end-vault ownership and mimic items

**Files:** `policy/generation/vaults/end.lua`,
`policy/save/vaults.lua`, item spec, ECS schema, population, and pickup files.

- [x] Make required mapless controllers run post-place before optional maps.
- [x] Validate real rune child ownership at generation and restore.
- [x] Store source mimic intent on an ECS item and reveal it on pickup.
- [x] Test family composition, false rune pickup, and corrupt saves.

### Task 3: Live travel, modding, and documentation

**Files:** `internal/game/shoals_end_test.go`, sparse mod fixture,
`docs/modding.md`, `docs/port-inventory.md`.

- [x] Travel to Shoals:4, collect the rune, and verify reciprocal stairs.
- [x] Add the missing Shoals primary layout and forward its heights to tides.
- [x] Round-trip saves and reject forged finale and rune ownership.
- [x] Add a sparse mod ending and verify weighted discovery.
- [x] Run focused Lua and Go suites, source MAP audit, style and diff checks.
- [ ] Commit the category and push `origin/main`.
