# Item Name Import Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Separate source lookup, special item names, and ordinary item names in the item-name importer without changing its output.

**Architecture:** Keep `parseItemNames` as the entry point. A small parser owns the source view, parsed C++ cases, and result map; named methods load source cases and add each identity's name in the original order.

**Tech Stack:** Go, the existing C++ source view helpers, item importer tests.

**Spec:** `AGENTS.md` readability rules and the existing committed item presentation catalog contract.

## Global Constraints

- Preserve exact item names, kinds, source lines, error text, and generated catalog bytes.
- Keep the C++ source lookup and identity traversal order unchanged.
- Keep handwritten lines at or below 120 columns with blank lines between distinct steps.
- Commit this item-name category after one focused and one broad verification pass.

## Review Focus

- Jewellery must read the non-terse naming branch.
- Removed food and rods must retain their full-source fallback line lookup.
- Book manual, corpses, removed decks, gold, and Orb of Zot must preserve special names.
- Missing active potion names must remain errors; explicitly removed potion names may be absent.
- Weapon, armour, and missile names must remain excluded from this parser.

---

### Task 1: Split item-name import by responsibility

**Files:**
- Modify: `internal/content/itemimport/presentation.go`
- Test: `internal/content/itemimport/presentation_test.go`

**Interfaces:**
- `itemNameParser` owns `path`, `data`, `view`, parsed case maps, and the result map.
- `loadFunctionNames` and `loadSubtypeCases` preserve source parsing order.
- `addIdentity` dispatches to `addSpecialIdentity` and `addOrdinaryIdentity`.
- `parseItemNames` constructs the parser, loads cases, walks identities, and returns names.

- [x] Run existing focused tests and record presentation artifact hash.
- [x] Extract the source-case and identity-name stages without changing the rules.
- [x] Run `gofmt` and focused tests.
- [x] Run full tests, vet, build, style check, artifact check, and diff check.
- [x] Obtain independent review; commit and fast-forward local `main`.
