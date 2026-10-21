# Depths Encompassing Vault Family Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans for native
> implementation. Keep this source family in one category commit.

**Goal:** Make all 17 source Depths encompassing definitions live through
the Lua-owned whole-floor generation and save path.

**Architecture:** DES owns geometry and static selectors; named Lua hooks
own executable source choices. A primary vault is selected before normal
layout construction so an encompass map owns the floor and its stairs.

**Tech Stack:** Go, Lua 5.1 runtime, Akara ECS, layered embedded mods.

**Spec:** `docs/superpowers/specs/2026-10-21-depths-encompass-family-design.md`

## Tasks

- [x] Add failing Lua tests for all 17 definitions, five Depths:2–3
  primaries, two Depths:4 `PLACE` primaries, source weights, shared run
  uniqueness, and helper tags.
- [x] Split and audit every DES definition; state file-global depth defaults
  per map and port every executable source site to a named Lua hook.
- [x] Add failing Lua and Go tests for whole-floor selection, child
  composition, authored stairs, Zot gate, mod overlays, and save/restore.
- [x] Give encompass maps an early floor owner, keep source weighted choice
  stable across retries, and project their ordinary/branch stairs without a
  provisional procedural layout underneath.
- [x] Document the complete family and mod extension path. Run focused Lua
  and Go tests, all-package compilation, source audit, changed-file style
  checks, and category review.
- [ ] Commit the whole category once on `main` and push to the fork.
