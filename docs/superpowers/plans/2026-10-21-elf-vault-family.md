# Elf Vault Family Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement
> this plan as one reviewed category. Check off tasks as they finish.

**Goal:** Make all 115 source Elf vaults selectable and live through
Elf:1–3, with authored branch travel and save history.

**Architecture:** DES files own map geometry and directives. Named Lua
modules own source choices and the branch data names one floor-primary
family at each required depth. Generic generation and save owners handle
selection, placement, branch links, and persistence.

**Tech Stack:** Go, embedded Lua, Akara ECS, source DES, Go save format.

**Spec:** `docs/superpowers/specs/2026-10-21-elf-vault-family-design.md`

## Global Constraints

- Work on `main`; push each completed category to the user's fork.
- No executable Lua in Go or DES, no committed importer, no duplicated
  content roster, and no file-discovery-order dependency.
- Comment every Lua function and explain why and how where useful.
- Keep Go/Lua lines at most 120 characters, preferably near 80.
- Commit the complete Elf category as one contiguous commit.

## Review Focus

- An Elf:1 authored `{` must receive the Orc link; the procedural up
  stair must not steal the branch entry.
- The Elf:1 dummy must leave one usable reciprocal branch landing.
- Hall of Blades SUBVAULT must use the effective tagged helper pool.
- The four Hall primaries and 21 endings must not fall back silently.
- A rejected primary fit must not claim a map or leak an RNG choice.

## Tasks

### 1. Source boundary and catalog

- [x] Write a failing Lua catalog test for 16 arrivals, 55 ordinary
  maps, 19 blade helpers, four Hall primaries, and 21 endings.
- [x] Split all 115 source definitions into committed `.des` files with
  unchanged MAP rows. Keep source scripts as comments at their sites.
- [x] Run an out-of-repo audit for names, MAP bytes, directives, and
  every script site. Fix all mismatches before behavior work.

### 2. Shared source Lua and per-map scripts

- [x] Port shared blade-entry, Hall monster and weapon, and Elf ending
  helper functions as named Lua methods with no giant switch.
- [x] Port each conditional and controller source script, including
  the mapless `elven_spread` PLACE choice and defective weapon store.
- [x] Run every map through the production placement owner and test
  its source choices and keyed effects.

### 3. Three floor primaries and branch travel

- [x] Generalize the existing end-vault selector into a branch-declared
  floor-primary selector; migrate existing branch-end data in one pass.
- [x] Select Elf:1, Elf:2, and Elf:3 source PLACE pools, including the
  Elf:1 dummy; keep weighted choice across redraws.
- [x] Prefer an Elf:1 authored up landing for the scheduled Orc link,
  then verify reciprocal travel and all three generated floors in Go.

### 4. Save, mods, and category gate

- [x] Validate selected primary IDs, family, depth, helper history,
  and rune-free Elf end on save restore.
- [x] Add a sparse Elf mod and update the modding guide and port
  inventory with source family paths and pending live effects.
- [x] Run focused Lua and Go travel/save tests, compile all Go packages,
  check `gofmt`, line length, and `git diff --check`; review and fix
  the entire slice.
- [x] Commit the complete Elf category once on `main` and push it.
