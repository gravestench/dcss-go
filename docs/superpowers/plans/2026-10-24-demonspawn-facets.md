# Demonspawn Facet Schedule Implementation Plan

> **For agentic workers:** Execute natively as one contiguous category.
> The user has approved the recommended design and one-commit workflow.

**Goal:** Roll and save the complete Demonspawn facet schedule, grant its
mutations at their assigned levels, and let Ru reject Frail when Robust
is anywhere in that schedule.

**Architecture:** Source-backed facet definitions are separate discoverable
Lua files. One Lua owner rolls and reads player-owned schedule entities.
Existing mutation transition grants ranks; the Go kernel only persists
the typed ECS state and runs registered Lua policies.

**Spec:** `docs/superpowers/specs/2026-10-24-demonspawn-facets-design.md`

## Constraints

- Work on `/Users/dylanknuth/src/dcrawl-go` `main` and push one verified
  category commit to `origin/main`.
- No inline Lua in Go, no importer or original C++ dependency at build.
- Each Lua definition and function needs comments explaining source
  behavior and why it is represented this way.
- Keep lines at most 120 columns and break multi-field declarations out.
- Seed behavior must depend on stable IDs and named RNG streams, never
  file load order.

## Task 1: Facet definitions and validation

**Files:** `internal/modfs/builtin/content/demonspawn_facets/*.lua`,
`constants/catalog.lua`, `ids/demonspawn_facets.lua`, and a focused
`policy.character.demonspawn` catalog validator.

- [x] Transcribe every active facet in pinned `mutation.cc`, including
  ordered mutation IDs and timing windows, tier, body slot, and the two
  exclusion groups. Put provenance in comments, not data fields.
- [x] Validate exactly three known active mutations per facet, known
  timing windows, tier, unique IDs, and body slot/group constraints.
- [x] Add production-definition Lua tests for the complete catalog and
  mod override path.

## Task 2: Saved schedule and source roll

**Files:** `schemas/character_demonspawn_trait.lua`,
`schemas/character_demonspawn_ancestry.lua`,
`constants/component.lua`, `constants/rng_streams.lua`,
`policy/character/demonspawn.lua`, and focused Lua tests.

- [x] Select ordinary or monstrous tier counts, unique facets and body
  slots, and restart on elemental/cloud clashes.
- [x] Place each facet's three grants in ordered timing windows and
  assign 15 or 18 grants to distinct XL2–27 slots, starting at XL2.
- [x] Save each scheduled grant as a player-owned typed ECS entity with
  facet ID and rank index for source-shape validation.
- [x] Validate the complete schedule and reject missing, duplicate,
  foreign, out-of-range, or impossible saved records.

## Task 3: Level grants and Ru consumer

**Files:** `policy/character/start.lua`,
`policy/character/advancement.lua`, `policy/mutations/records.lua`,
`policy/save/player.lua`, `policy/religion/ru/variants.lua`, and tests.

- [x] Roll once during Demonspawn creation, after identity is selected.
- [x] Grant the level's scheduled mutation before resource formulas;
  prevent duplicate grants after level loss and regain.
- [x] Validate attained innate ranks against the saved schedule.
- [x] Reject Ru's Frail variant when any saved trait names Robust,
  including an unacquired future trait.

## Task 4: Integrated verification and release

**Files:** `internal/game/*demonspawn*test.go`, `docs/modding.md`,
`docs/port-inventory.md`.

- [x] Test several seeded starts, save/restore, advancement, Ru offer
  exclusion, and non-Demonspawn state through a real game.
- [x] Document facet files, owner APIs, RNG and save behavior for modders.
- [x] Run focused Lua and Go tests, build `cmd/crawl`, inspect changed-file
  style, and run `git diff --check`.
- [x] Commit the complete domain once on `main` and push it.
