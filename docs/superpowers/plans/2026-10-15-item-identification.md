# Source-backed Item Identification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking. Make one commit for the complete
> identification category after integrated verification.

**Goal:** Give every active identifiable item a stable unknown appearance and
shared type discovery while preserving per-item knowledge and save validity.

**Architecture:** Lua creates and owns one player knowledge component and
optional per-item identification components. The effective item catalog
drives appearance assignment and discovery. Existing Lua presentation
policies format visible names using entity IDs; Go only passes those IDs and
renders the returned text.

**Tech Stack:** Go 1.25, embedded Lua, Akara ECS, current native save format.

**Spec:** `docs/superpowers/specs/2026-10-15-item-identification-design.md`

## Global Constraints

- Work in `/Users/dylanknuth/src/dcrawl-go` on `codex/lua-player-magic`.
- Keep source tables and item definitions committed; importers run only for
  intentional refreshes, never during normal build or play.
- Put rules in `.lua` files. No Go item-ID switches or inline Lua fixtures.
- Use named IDs imported where used. Prefer 80-character lines; keep every
  handwritten Go/Lua line at or below 120 characters.
- Keep multi-field table and struct literals expanded and functions focused.
- Preserve the untracked `dcrawl-save.json` and the paused C++ refactor.
- Verify at the category boundary and commit all identification work once.

## Review Focus

1. Two copies of the same potion reveal the same type after one is used,
   including a copy on the floor (Task 3).
2. Two different unknown types in the same class never receive the same
   appearance within one run; save and restore do not reroll (Task 1).
3. A mod-added item participates in appearance assignment and discovery
   without editing a central ID list (Tasks 1 and 2).
4. A partially known weapon shows only the permitted plus, brand, and
   cosmetic fields; hidden fields never leak in the modal (Task 3).
5. A corrupted save with an unknown type key, duplicate appearance, or
   incompatible per-item knowledge is rejected (Task 2).

---

## Task 1: Committed source appearance data

**Files:** Add `scripts/import_item_appearances.py`,
`internal/modfs/builtin/data/item_appearances.lua`, and importer tests.

**Interfaces:** `data.item_appearances` exports the five source classes,
with separate ring and amulet pools within jewellery,
and source name formatters. It consumes stable class and item IDs from the
effective catalog, not a separate handwritten item roster.

- [ ] Write failing importer tests for source table values, deterministic
  scroll labels, uniqueness constraints, and `--check` drift detection.
- [ ] Extract the pinned `ng-init.cc` and `item-name.cc` descriptor tables
  into committed Lua data with source comments at declarations. Keep the
  importer as a deliberate refresh tool.
- [ ] Run the importer tests and `--check`; expect pass.

## Task 2: Saved ownership and validation

**Files:** Add `schemas/character_item_knowledge.lua`,
`schemas/item_identification.lua`, `policy/items/appearances.lua`,
`policy/items/identification.lua`; update `policy/character/start.lua` and
the relevant `policy/save/*` validators. Add Lua `_test.lua` and Go save tests.

**Interfaces:** `character.item_knowledge` has `known_types` and
`appearance_seeds` maps keyed by item ID. `item.identification` has
`known_type`, `known_pluses`, `known_properties`, and `cosmetic` fields.
`identification.initialize(ctx, player)` assigns one saved descriptor per
active identifying type. `identification.known(ctx, player, item_entity)`
resolves effective type/plus/property knowledge.
`identification.reveal_type(ctx, player, item_entity)` updates all copies by
type. `identification.reveal_item(ctx, item_entity, fields)` changes one
physical item. No knowledge is stored in a Lua module global.

- [ ] Write failing Lua tests for all five classes, mod-added definitions,
  shared type discovery, and separate per-item plus knowledge.
- [ ] Write failing Go save tests for stable appearance/name round trips and
  rejection of duplicate or invalid saved descriptors and flags.
- [ ] Register the two schemas, initialize knowledge from `character.start`,
  and implement the four policy methods above using the effective catalog.
- [ ] Add save validation to the existing Lua validators, then run focused
  Lua and Go tests until green.

## Task 3: One visible naming and discovery path

**Files:** Update `policy/presentation/view.lua`,
`policy/presentation/modals.lua`, `internal/game/view.go`, item mention
policies under `policy/inventory`, `policy/commands/quaff.lua`, and
`policy/inventory/wands.lua`. Add whole-turn and terminal tests.

**Interfaces:** `presentation.inventory_item` and `presentation.entity`
receive `item_entity_id` and return the visible name. Both call
`identification.name(ctx, player, item_entity)`; no Go caller formats hidden
plus, ego, charge, or type values. Potion and wand success paths call
`identification.reveal_type` after actual use.

- [ ] Write failing whole-turn tests: unknown potion and wand names,
  discovery after use, a matching floor copy changing appearance, and
  starting gear's known fields. Add a terminal inventory assertion so the
  visible label cannot leak hidden values.
- [ ] Route inventory and floor presentation through the one Lua name policy.
  Replace direct item name/plus/ego formatting in modals and item messages.
- [ ] Update potion and wand successful-use policies to reveal type; keep
  failed or cancelled uses from revealing. Make stack merging preserve
  compatible identification state.
- [ ] Run focused whole-turn, terminal, and save tests; expect pass.

## Task 4: Integrated verification and category commit

- [ ] Run `GOWORK=off GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./...
  -count=1 -timeout 30m` once after the implementation swathe.
- [ ] Run `go vet ./...`, `go build -o /private/tmp/dcrawl-item-id ./cmd/dcrawl`,
  `sh scripts/check-go-style.sh`, importer `--check`, and `git diff --check`.
- [ ] Update `docs/port-inventory.md` with actual identification coverage
  and any source parity gaps. Review the spec against this plan.
- [ ] Commit this contiguous category, fast-forward local `main`, and return
  to `codex/lua-player-magic`. Leave `dcrawl-save.json` untracked.
