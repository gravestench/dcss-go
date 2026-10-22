# Sewer Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native execution. The user has authorized
> continuous work, one coherent category commit on `main`, and pushes.

**Goal:** Make all 34 source Sewer maps available through a timed,
saveable, playable D:3–6 portal.

**Architecture:** The effective DES catalog owns authored geometry and
named Lua hooks. Lua owns generation decisions, clocks, travel, and save
rules. The existing Go `luaPortal` transaction stages and retires the
one-floor destination; dynamic portal and visit state live in ECS.

**Tech Stack:** Embedded Lua, source DES, Akara ECS, Go terrain and save
services, Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-21-sewer-portal-design.md`

## Global constraints

- Preserve all 34 `NAME` identities, authored `MAP` blocks, source weights,
  and directive order; keep source content checked in.
- Put executable Lua in named files, never inline in Go or `.des`.
- Give each Lua function useful why/how comments. Prefer 80-character lines,
  never exceed 120; expand multi-field declarations.
- Use the existing VFS and generic portal transaction; no Sewer-specific Go
  generation or travel switch.
- Commit and push the entire usable Sewer category together, after integrated
  verification. Work on `main` per the user's latest instruction.

## Review focus

1. An accepted entry at the expiry boundary must not vanish during the
   same action. Cover with an integrated deadline test.
2. A failed Sewer build must not spend a gate or leave monsters and loot.
   Cover with a rejected staged-level rollback test.
3. Mod file order must not affect map selection. Cover with sparse overlay
   discovery and a fixed-seed candidate-order assertion.
4. Exit must use the exact saved outside site and retire Sewer entities.
   Cover with a save-inside, restore, exit test.
5. All 19 source destinations must materialize their authored content.
   Cover with a full corpus generation and population test.

## File map

- `vaults/sewer_entry/*.des`, `vaults/sewer/*.des`: one source map per file.
- `policy/generation/vaults/sewer_entry/*.lua`,
  `policy/generation/vaults/sewer/*.lua`: named source-position hooks.
- `policy/generation/sewer/level.lua`: stable weighted destination choice.
- `policy/world/sewer/{portal,travel}.lua`, `systems/world_sewer_portals.lua`:
  ECS marker, clock, and live travel policy.
- `schemas/world_sewer_portal.lua`, `schemas/character_sewer_visit.lua`:
  durable portal and return state.
- `policy/save/{sewer_portals,sewer_levels}.lua`: restore invariants.
- `constants/{terrain,component,rng_streams,world_signals}.lua`,
  `internal/terrain/feature.go`: vocabulary and generic grid properties.
- `internal/game/*`: only generic portal integration and save projection.
- `internal/script/testdata/lua/tests/*`, `internal/game/*_test.go`:
  source-corpus and integrated gameplay checks.
- `docs/{modding,port-inventory}.md`: extension API and remaining gaps.

## Task 1: Source corpus and named hooks

- [x] Add a Lua corpus test that enumerates 15 entry and 19 destination
      IDs, validates each effective DES definition and hook, and pins all
      authored MAP geometry to a source-derived digest.
- [x] Split `sewer.des` into 34 individual checked-in files. Port the two
      shared source helpers and every local script site to commented named
      Lua functions at the same directive positions. Put chance and unique
      tags in each entrance declaration for pre-hook discovery.
- [x] Exercise each entry as a secondary vault and each destination as a
      whole-floor placement. Confirm source monsters, items, traps, terrain,
      and exit records survive the typed path.

## Task 2: Portal lifetime and destination

- [x] Add tests for weighted candidate ordering, species and depth
      eligibility, sparse mod discovery, deadline entry, and off-floor
      expiry. Watch the relevant tests fail against the Bazaar-only runtime.
- [x] Add Sewer terrain and ECS schemas, source marker materialization,
      global-action clock system, and Lua generation policy. Wire the entry
      tag into the existing source selector.
- [x] Use the generic `luaPortal` transaction for entry and return. Store
      the exact source cell on the player; spend the drain only after staging
      succeeds; retire the destination after a successful return.

## Task 3: Saves, docs, and category verification

- [x] Add restore tests for active and expired gates, an inside visit,
      forged source map or return site, and failed staging rollback.
- [x] Add save validators for the marker, selected destination, exit, and
      reciprocal visit. Reuse generic save projection where possible.
- [x] Document Sewer map and hook authoring in the modding guide and update
      the port inventory with exact supported behavior and remaining gaps.
- [x] Run the focused Lua corpus, integrated Go Sewer tests, all-package
      compile, changed-file style, `gofmt`, and `git diff --check`. Review
      the whole category, commit once, and push `main`.
