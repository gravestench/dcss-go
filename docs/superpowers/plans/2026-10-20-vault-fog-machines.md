# Vault Fog Machine Implementation Plan

**Goal:** Activate committed source-format fog-machine markers across
arrival, Temple, altar, serial, and shop vaults as saved Lua-owned world
mechanics.

**Architecture:** `.des` marker records are static authored input. A Lua
reader validates a flat parameter table; Lua population creates ECS machine
state; a Lua turn policy emits clouds through the existing cloud owner; Go
only passes generic level-transition timing and permits marker records to
be materialized.

**Spec:** `docs/superpowers/specs/2026-10-20-vault-fog-machines-design.md`

## Constraints

- Work directly on `main`; commit and push the complete category.
- Keep production Lua in files under the embedded mod root. Do not paste
  executable Lua into Go or regenerate content at build time.
- Comment every new Lua function with its why and how. Keep lines at most
  120 characters and break up multifield tables.
- Reuse registered cloud definitions and named constants. Loading order
  must not change a seed or a saved machine's continuation.
- Preserve the paused C++ refactor and read the reference checkout only.

## Tasks

- [x] Test and implement the focused marker reader using real committed
  `.des` records. Validate all effective fog calls and keep legacy ignored
  keys inert.
- [x] Add the Lua ECS schema and population path for one machine per live
  marker; validate saved marker/entity ownership and current countdown.
- [x] Implement source timing, entry bursts, random walks, buildup, area
  selection, and cloud placement through the existing cloud owner.
- [x] Wire initial floor and action transitions through generic Go policy
  calls, with no Go fog rule implementation.
- [x] Add an integrated game test for entry, turns, save/restore, and an
  offscreen machine. Document the modding contract and update the inventory.
- [x] Run affected Lua and game suites sequentially, style and diff checks,
  commit this category on `main`, and push `origin/main`.
