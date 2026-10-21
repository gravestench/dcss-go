# Orc Vault Family Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Track
> progress with the checkboxes below. Commit the whole Orc category once.

**Goal:** Make all 77 source Orc vault definitions selectable and placeable
through the effective Lua/DES catalog, including authored gates and Orc:2
endings.

**Architecture:** DES owns geometry and static declarations. Focused Lua
handlers own source choices, while the existing generation and save owners
place maps, link stairs, populate ECS entities, and validate durable
history. Composed endings pass placement-local settings to helper maps.

**Tech Stack:** Go, embedded Lua, DES, Akara ECS, JSON save format.

**Spec:** `docs/superpowers/specs/2026-10-21-orc-vault-family-design.md`

## Global Constraints

- Preserve all 77 source names and MAP blocks; explicitly represent source
  default depth in each split file.
- Keep source Lua in named Lua modules, with no inline Lua in Go or DES.
- Commit generated content; leave one-off import and audit scripts outside
  the repository.
- Keep Lua functions commented, avoid large declarations, and keep code
  lines at or below 120 characters.
- Produce one commit for the complete Orc category and push `main`.

## Review Focus

- A keyed Elf gate in `pubby_orc_utopia` must replace, not duplicate, the
  provisional scheduled entrance.
- Garden helper maps may repeat IDs because of `allow_dup`, but each
  placement must retain its own shop and boss state.
- A rejected child fit must not claim a map ID or leak controller settings
  into another placement.
- An Orc:2 controller with missing children must fail save validation.
- An authored gate that cannot fit must leave a usable lone Orc entrance.

## Tasks

### 1. Source catalog and audit

- [x] Add Lua catalog tests asserting 19 `orc_entry`, 42 `orc`, and 16
  `orc_end` definitions and the correct weighted selection stages.
- [x] Split `crawl-ref/source/dat/des/branches/orc.des` into individually
  named files under the three matching `internal/modfs/builtin/vaults/`
  directories. Keep source MAP bytes and static directives in order.
- [x] Run an out-of-repo audit against the pinned source for names, MAP
  bytes, static directives, and executable source sites. Confirm 77/77.

### 2. Authored Dungeon gates and ordinary Orc maps

- [x] Add `ORC_ENTRY`, `ORC`, `ORC_END` family/tag constants and
  `ENTER_ORC` feature constant. Add Orc to
  `policy/generation/vaults/branch_entry.lua`.
- [x] Port depth and random source sites to small handlers under
  `policy/generation/vaults/orc_entry/` and `.../orc/`.
- [x] Test all 18 placeable entries for one keyed Orc stair, keep the
  source dummy as a fallback candidate, place every ordinary MAP through
  `placement.place`, and test reciprocal D-to-Orc travel in Go.

### 3. Source effect records and controller settings

- [x] Port delayed corpse and skeleton source sites to existing typed
  `DELAYED_DECAY` records; test their saved location and item arguments.
- [x] Extend `controller.place_maps(api, tag, count, options)` so
  `options.settings` is copied into each child's `player.settings` and
  visible through the existing vault `api:setting(name)` method. Never
  mutate the parent's settings table.
- [x] Port the gardens and community controllers and child hooks under
  `policy/generation/vaults/orc_end/` and `.../orc/`. Test the four garden
  placements, two big houses, four-to-six small houses, failed fits,
  `allow_dup`, and independent shop/boss decisions.

### 4. Orc:2 ending and authored Elf link

- [x] Set `branch_orc.lua` to require the rune-free `orc_end` family. Test
  all 16 primary endings through the real end placement stage.
- [x] Supply the scheduled branch-entry IDs to the generated floor's vault
  `player` facts; expose `api:branch_entry(branch_id)` in
  `policy/generation/vaults/operations.lua` as a read-only boolean.
- [x] After extra vault placement in `policy/generation/generated.lua`,
  bind a keyed `enter_elven_halls` record to the existing Elf branch link,
  clear its provisional lone stair, and keep the final cell protected.
  Test `pubby_orc_utopia` with and without the scheduled Elf gate.
- [x] Extend `policy/save/vaults.lua` to validate each Orc controller's
  family, number of helper placements, and selected end history. Test
  missing, forged, and restored children.

### 5. Mod, docs, and category gate

- [x] Add a sparse mod layer with one Orc gate, one ordinary room, and one
  ending; verify effective-catalog discovery without Go roster edits.
- [x] Update `docs/modding.md` and `docs/port-inventory.md` with Orc paths,
  controller settings, and any pending live effects.
- [x] Run focused Lua placement and Go travel/save tests, compile all Go
  packages, check `gofmt`, line lengths, and `git diff --check`, then
  review the whole category and fix findings.
- [ ] Commit the complete Orc category once on `main` and push it to
  `origin`.
