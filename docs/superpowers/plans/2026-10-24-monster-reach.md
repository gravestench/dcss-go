# Monster Reach Implementation Plan

**Goal:** Apply live source reach for all monster natural and weapon attacks.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-reach-design.md`

## Tasks

- [x] Add a Lua domain test using real equipped ECS items, natural
  attackers, map geometry, and ordered melee slots; run it failing first.
- [x] Extend equipment's current weapon view and the Lua reach policy for
  natural Reach, Tongue, Rift, polearms, Lochaber, and Rift artefact.
- [x] Route and resolve distant intents with per-contact eligibility,
  preserving the source slot order and current equipment state.
- [x] Update port inventory and modding comments. Verify affected Lua and
  game tests, build, style baseline, and diff; source review; commit and
  push one contiguous monster reach category on `main`.
