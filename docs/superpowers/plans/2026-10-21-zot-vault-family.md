# Zot Vault Family Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans for native
> implementation. Track this category in the checkboxes below and make
> one commit when its integrated boundary passes review.

**Goal:** Make all 88 pinned Zot definitions discoverable and open the
source-authored Zot:1–5 branch with the Orb of Zot on Zot:5.

**Architecture:** DES owns maps and static placement; named Lua modules
own source script decisions. The existing branch-entry, regular-vault,
layout, population, ECS, and save paths own generated game state.

**Tech Stack:** Go, Lua 5.1 runtime, Akara ECS, layered embedded mods.

**Spec:** `docs/superpowers/specs/2026-10-21-zot-vault-family-design.md`

## Global Constraints

- Pinned source: `crawl-ref/source/dat/des/branches/zot.des` at DCSS
  `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Keep original MAP rows and source-order static directives in committed
  individual DES files. Import runs only for deliberate source refreshes.
- Keep executable Lua in `.lua` files, one function per explained decision.
  No inline Lua in Go or a production DES file.
- Bundle generated content; ordinary builds never read the C++ tree.
- Keep lines at most 120 characters and multi-field literals expanded.
- Work on `main`, make one Zot category commit, and push to `origin`.

## Review Focus

- An encompassing Depths:4 map with an existing Zot feature must get one
  scheduled link; the entry selector must not add a second map.
- `zot_entry_small` has no `PLACE` rule and must stay out of the Depths
  gate draw; the weight-60 dummy must suppress one Zot:5 ordinary draw
  without placing its one-cell MAP.
- All 80 columns of the Zot:5 hall must fit without widening ordinary
  vault placement or losing the north orientation.
- A failed hall validator must prevent generation and saving a broken
  floor rather than fall back to a generic layout.
- The Orb item, overgrown trigger countdown, and floor links must retain
  the same identity and outcome across save/restore.

---

### Task 1: Source Inventory and Failing Catalog Tests

**Files:**
- Create: `internal/script/testdata/lua/tests/zot_vault_family_test.lua`
- Create: `internal/script/testdata/zot-vault-mod/` fixtures
- Modify: `internal/script/lua_rules_test.go`

**Interfaces:** The effective `policy.generation.vaults.catalog` and
`policy.generation.layouts.catalog` expose source `NAME` definitions.

- [x] Write assertions for 88 IDs, 14 weighted Depths-side entries, one
  unplaced small entry, one weighted dummy, Zot depth rules, the required
  hall, and source-independent VFS overlay selection.
- [x] Run the focused Lua test and confirm that the absent family fails.
- [x] Record source names, MAP rows, directives, and script sites with a
  temporary audit program outside the repository.

### Task 2: Entry DES and Named Setup Hooks

**Files:**
- Create: `internal/modfs/builtin/vaults/zot_entry/*.des`
- Create: `internal/modfs/builtin/policy/generation/vaults/zot_entry/*.lua`
- Modify: `internal/modfs/builtin/constants/vault_families.lua`
- Modify: `internal/modfs/builtin/constants/vault_tags.lua`
- Modify: `internal/modfs/builtin/policy/generation/vaults/branch_entry.lua`

**Interfaces:** `branch_entry.candidates(BRANCH_ZOT, floor)` selects only
effective `zot_entry` maps with `PLACE`. A named
`shared.entry_setup(api)` emits the source's common monster and keyed
Zot feature directives; `PLACE` and `ORIENT` remain static DES metadata.

- [x] Split all 15 entry MAPs and keep source scripts as comments beside
  named hooks; filter the small map by its missing `PLACE` rule.
- [x] Port the gauntlet's four ordered coinflip choices to one readable
  named Lua method, preserving source roll order.
- [x] Add Zot to the data-driven branch-entry selector and assert that a
  primary Depths map's existing Zot feature suppresses duplicate placement.
- [x] Run the focused entry selection and direct-placement tests.

### Task 3: Ordinary Zot DES and Script Sites

**Files:**
- Create: `internal/modfs/builtin/vaults/zot/*.des`
- Create: `internal/modfs/builtin/policy/generation/vaults/zot/*.lua`
- Modify: `internal/modfs/builtin/policy/generation/vaults/regular.lua`

**Interfaces:** `regular.candidates(context)` discovers effective
`vaults/zot/` definitions; named hook methods receive the existing
generation `api` and emit typed directives at their source positions.

- [x] Split all 67 ordinary and four floor-style definitions, plus the
  source dummy; keep MAP rows byte-for-byte and script order explicit.
- [x] Port shared dragon-hoard and coloured-glass routines and each
  source-local conditional and monster-choice script to small Lua methods.
- [x] Keep the weight-60 dummy in the Zot:5 regular draw, but let its
  selection end that attempt without terrain, history, or retry.
- [x] Place every non-dummy map through production DES placement with
  seeded contexts; verify source MAP audit and sparse overlay behavior.

### Task 4: Zot:5 Hall and Branch Travel

**Files:**
- Create: `internal/modfs/builtin/vaults/layout/hall_of_Zot.des`
- Create: `internal/modfs/builtin/policy/generation/layouts/hall_of_Zot.lua`
- Modify: `internal/modfs/builtin/content/branches/branch_zot.lua`
- Modify: `internal/modfs/builtin/policy/generation/vaults/placement.lua`
- Test: `internal/game/zot_vault_family_test.go`

**Interfaces:** `floor_availability.can_build(BRANCH_ZOT, 5)` requires the
explicit hall layout; its validator receives resolved cells and composed
records. The existing `generated.next` and `generated_stairs.pair` return
linked, saved Zot levels.

- [x] Add failing Lua checks for 80-column hall fit, connected Orb glyph,
  one Orb item record, and mandatory Zot:5 layout selection.
- [x] Permit full-width authored PLACE layouts while keeping normal vault
  bounds; port the hall's source validator and fixed placement.
- [x] Add a Go travel/save test from Depths:4 through Zot:5, asserting
  reciprocal links, source hall ID, Orb Akara entity, and restore.
- [x] Run focused Lua and Go tests; resolve any missing source item or
  monster materialization in the existing owners.

### Task 5: Zot Live Source Triggers and Finish

**Files:**
- Create: focused `internal/modfs/builtin/policy/world/` trigger module
  and `internal/modfs/builtin/schemas/` component only if needed by the
  overgrown source vault's delayed oklob transformation
- Modify: `internal/modfs/builtin/policy/population/vaults.lua`
- Create: `internal/modfs/builtin/policy/world/zot_overgrown.lua`
- Create: `internal/modfs/builtin/schemas/world_zot_overgrown.lua`
- Create: `internal/modfs/builtin/systems/world_zot_overgrown.lua`
- Modify: `docs/modding.md`
- Modify: `docs/port-inventory.md`

**Interfaces:** Source marker positions create saved actor or level state;
the live trigger consumes turns and transforms eligible plants once under
the source countdown. Modders use the same named DES/Lua path.

- [x] Write a live regression for the overgrown trigger, including a
  save/restore midway through its countdown.
- [x] Implement the trigger through existing ECS world owners and record
  source marker intent in the DES placement path.
- [x] Document Zot additions, Orb boundary, and mod extension steps.
- [x] Verify all 88 names and MAP rows against source, focused rules and
  travel tests, all-package compilation, and changed-file style checks.
- [x] Request whole-category review; fix Critical and Important findings.
- [x] Commit the category once on `main` and push to the fork.

## Verification record

The temporary source audit found all 88 names and 88 byte-identical MAP row
arrays. Its 33 unmatched source directive lines are the conditional Lua
branches intentionally moved into named hook methods. Focused Lua and Go
tests cover catalog discovery, sparse overlays, every non-dummy map, the
mandatory Hall, live Orb materialization, Depths-to-Zot travel, and an
overgrown countdown restored halfway through. All Go packages compile.
Changed Go files pass `gofmt`, the 120-column check, and `git diff --check`.
The repository-wide readability script still reports existing findings in
unmodified Go files.
