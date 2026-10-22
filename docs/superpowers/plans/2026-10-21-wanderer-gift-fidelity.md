# Wanderer Gift Fidelity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan in the current session. Track the test cycle below.

**Goal:** Make all Wanderer gift branches use source-shaped choices and the
saved per-run item-set representatives.

**Architecture:** Keep role/skill orchestration in `wanderer.lua`, item
decisions in `wanderer_gifts.lua`, and spell decisions in
`wanderer_spells.lua`. Use the shared item-set owner and a dedicated named
Wanderer RNG stream; retain the existing ECS start/save owners.

**Tech Stack:** Embedded Lua policies, Akara-backed components, Go integration
tests.

**Spec:** `docs/superpowers/specs/2026-10-21-wanderer-gift-fidelity-design.md`

## Global constraints

- One contiguous commit on local `main`, pushed to `origin` as requested.
- Production Lua under the embedded mod root; tests in `_test.lua` files.
- Source IDs come from `ids` or `constants` modules where used.
- Multi-field tables are expanded, and changed Lua lines stay at or below
  120 characters.

## Review focus

1. A saved item-set choice remains unchanged and no gift path rerolls it.
2. Each strong wand slot draws once after the per-run set is resolved.
3. Minor spell pairs contain distinct, usable player-book spells totaling
   exactly four levels, including the 2+2 case.
4. A no-grasping or armour-limited species still receives legal fallback
   gifts without a second source of equipment rules.
5. Restoring a started Wanderer does not change gear, spells, or item sets.

## Work

- [x] Add failing Lua tests for item-set reuse, draw order, and minor
      spellbook pair selection. Run each new test to confirm the intended
      failure before changing production Lua.
- [x] Route Wanderer decisions to the saved item-set choices and named
      stream, then correct armour and aux fallback choices.
- [x] Replace minor-spell priority fallback with source-shaped pair
      selection and numeric candidate order. Keep strong spell reservoirs.
- [x] Run focused Lua tests, seeded Wanderer Go start/restore tests,
      all-package compilation, style, line-length, and diff checks.
- [x] Review the complete category, fix material findings, commit once,
      and push `main`.

## Verification and review

- The new Lua tests failed before the item-set, Djinni, book-membership,
  Fighting, and charge-bound fixes, then passed after each correction.
- The focused Wanderer Lua tests, seeded start/save/restore tests, and
  all-package Go compilation passed. An exhaustive 80-start species/seed
  integration run also passed before the final review fixes; a focused
  restore and fallback run passed afterward.
- `gofmt -d`, `git diff --check`, and the changed-file 120-character check
  passed. `scripts/check-go-style.sh` still reports pre-existing findings
  in untouched Go files; this category adds no new Go style finding.
- Independent review found four issues: `random2avg` bounds, the first
  equipped weapon, modded player-book membership, and explicit restore
  comparisons. All four have targeted coverage and fixes.
