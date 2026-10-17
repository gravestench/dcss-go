# Source-backed Shop Vaults Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this
> plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking. Make one implementation
> commit for the complete shop-vault category, as requested by the user.

**Goal:** Import and play all 70 pinned shop vault definitions through the layered `.des` and Lua
runtime, including scripted maps and authored shop stock.

**Architecture:** Generalize the arrival importer and vault catalog by family. Lua parses source map
and shop specifications, selects and fits extra maps, ports source scripts as discoverable handlers,
and materializes shop entities through the existing Akara shop policy. Go remains the generic grid,
save, and terminal kernel.

**Tech Stack:** Go, Akara, gopher-lua, layered mod VFS, `.des`, JSON saves, Lua `_test.lua` tests.

**Spec:** `docs/superpowers/specs/2026-10-16-shop-vaults-design.md`

## Global Constraints

- Pinned source revision: `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Source files: `builder/shops.des` (69 names, SHA-256
  `4c5268cca221223c4c3ce8be64caec3f78cfd29327e5bfc0af544383b172132b`) and `builder/alphashops.des`
  (one name, SHA-256 `235b3fbfa6adf9ac4ec9696894580cfff90afa1a9dd2de5c3680e0f9ddfb9965`).
- Commit generated `.des` and Lua source. Build, launch, and restore never invoke the importer or read the C++ tree.
- Keep `.des` maps, port Lua scripts into actual `.lua` files, and keep source script comments and hashed port recipes.
- Dynamic shops and stock remain Akara entities; terrain remains a grid. No Go switch over vault or shop IDs.
- Handwritten Go and Lua lines stay within 120 columns, preferably near 80; multi-field literals are expanded.
- Test coherent work in batches and make one implementation commit for this category. Merge verified
  work into local `main`.

## Review Focus

1. A supplemental vault overlaps a stair, player entry, shop, or prior
   authored cell: retry a bounded location without changing those cells.
2. A source script emits a shop specification after `SUBST` or `SHUFFLE`:
   preserve declaration order and consume one deterministic RNG sequence.
3. `greed:0`, weighted shop alternatives, and `use_all` stock appear in
   source: parse and purchase them without fallback or silent omission.
4. A sparse mod adds a shop vault or replaces only its handler: load it from
   the effective VFS and include both files in ruleset identity.
5. Restore encounters a missing vault ID, shop record, stock entity, or
   changed ruleset: reject or require the existing explicit mismatch policy
   before using the save.

---

## File map

- `internal/vaultimport/{import,split,write,ports}.go`, `cmd/importvaults/main.go`: reusable family
  configuration, source checks, split, port recipe verification, and CLI.
- `internal/vaultimport/shop_ports/*.json`, `internal/modfs/builtin/vaults/shop/*.des`: pinned
  source-position rewrites and 70 committed maps.
- `internal/modfs/builtin/policy/generation/vaults/{des,catalog,hooks,selection}.lua`: shared
  parsing, discovery, validation, depth/chance selection, and family handler path.
- `internal/modfs/builtin/policy/generation/vaults/{depth,extra,shop_spec}.lua`: focused branch
  eligibility, supplemental placement, and keyed shop-expression parsing.
- `internal/modfs/builtin/policy/generation/vaults/shop/*.lua`: one readable script handler per
  scripted vault, plus shared source helpers.
- `internal/modfs/builtin/policy/generation/{generated.lua,vaults/placement.lua}`: place serial and
  eligible extra shop maps on generated levels.
- `internal/modfs/builtin/policy/generation/vaults/specs/{item,resolve}.lua`,
  `policy/item_generation/*.lua`, `policy/shops/generation.lua`: source item modifiers and typed
  shop stock requests.
- `internal/modfs/builtin/policy/population/vaults.lua`, `content/terrain_features.lua`: turn shop
  feature records into entrance terrain and Akara shop/stock entities.
- `internal/game/save_vault.go`, `internal/game/save_restore_levels.go`, and existing shop
  validation: enforce shop record/entity consistency on restore if the current hooks do not already
  cover it.
- Lua `_test.lua` files, Go importer tests, focused game save tests, and
  `docs/{port-inventory,ecs-architecture-roadmap}.md`: behavior and precise coverage.

### Task 1: Reusable pinned importer and all source maps

**Interfaces:** `vaultimport.WriteFamily(family, sourceDir, portsDir, outDir, check)` accepts an
arrival or shop family configuration. The existing arrival `Write` remains a thin call using the
arrival config. A shop config names two hashes and `vaults/shop` output.

- [ ] Add Go tests for 70 source names, exact two pinned hashes, ordered script-span rewrites,
      duplicate names, drift, and a one-file mod replacement. Confirm the new shop import test fails
      before implementation.
- [ ] Generalize split and write paths without changing the 339 committed arrival bytes or their
      check command. Pin the two pre-`NAME` Lua preludes, add hashed shop port recipes, and generate
      the 70 committed `.des` files. Keep source scripts as comments beside hooks.
- [ ] Run importer `-check` for arrival and shop families. Compare generated file count, names,
      directives, and script-span coverage with the pinned source.

### Task 2: Shared catalog, depth/chance policy, and handlers

**Interfaces:** `catalog.get(id)` returns a parsed definition from either family.
`depth.eligible(definition, branch_id, depth, branch_bottom)` and `selection.choose_tag(random, tag,
context)` use parsed `DEPTH`, `CHANCE`, `WEIGHT`, and source order. `hooks` resolves
`policy.generation.vaults.<family>.<id>` and executes `HOOK_POST_PLACE` after a controller map is
placed.

- [ ] Add Lua parser/catalog tests for both families, no-name collision, serial's empty map, branch
      ranges and exclusions, branch-specific chance, malformed source context, and sparse mod
      overrides. Confirm red.
- [ ] Extend `des.lua`, `catalog.lua`, `hooks.lua`, and focused `depth.lua`/`selection.lua` rules.
      Keep arrival selection and its saved RNG order unchanged.
- [ ] Port the two source preludes and every shop vault script block and inline conditional to
      focused handler modules. Test each handler's emitted operation and source order using
      production parser fixtures, not a test-only schema.

### Task 3: Shop specs and item requests

**Interfaces:** `shop_spec.parse(expression, site)` returns weighted typed alternatives.
`shop_spec.choose(ctx, alternatives)` yields `kind_id`, names, count, greed, `use_all`, and item
requests. `policy.shops.generation.place(ctx, spec)` accepts the typed requests and still accepts
the existing fixture's simple item IDs.

- [ ] Add Lua tests for all shop types, `any shop`, weighted KFEAT choices, source name tokens,
      count cap 20, `greed:0`, `use_all`, and the source item modifiers present in the two files.
      Confirm red.
- [ ] Implement the parser in `shop_spec.lua`; extend focused item-spec and item-generation modules
      for quantity, quality, plus, ego, randart/unrand, manual, and randbook choices. Use committed
      item IDs and source aliases, not a Go switch or a second item catalog.
- [ ] Extend shop stock generation to resolve typed requests once and retain the original item
      entities. Preserve an explicit typed pending record for any adjacent mechanic that cannot yet
      materialize; never silently substitute another item.

### Task 4: Supplemental map fitting and source selection

**Interfaces:** `extra.place(ctx, builder, vault, context)` returns occupied cells, exits, source
records, and transformed coordinates without changing protected cells. `extra.generate(ctx, builder,
context)` applies serial controller and eligible extra shop maps with bounded retries.

- [ ] Add Lua tests for transparent and opaque maps, rotated glyphs, multi-shop maps, sub-vaults,
      stairs/entry protection, bounded no-fit, deterministic saved stream, serial count and chance,
      D:1–2 eligibility, and deeper-branch metadata. Confirm red.
- [ ] Reuse existing transform and operation semantics. Add a focused supplemental-origin search and
      connection step, then wire it into `generated.lua` before rows and population are finalized.
      Keep distinct record source IDs for every placed vault.
- [ ] Remove the unconditional D:2 shop insertion in `policy/population/populate.lua`. Retain
      `NewShopScenario` and its fixed shop fixture. Update tests that assumed an ordinary generated
      D:2 always had a shop.

### Task 5: Materialize, save, and play authored shops

**Interfaces:** a resolved `FEATURE` record with typed shop arguments becomes `DNGN_ENTER_SHOP` and
exactly one `world.shop` entity via `policy.shops.generation.place`; shop stock uses `shop.stock`.
The existing purchase, UI, and save paths consume those entities unchanged.

- [ ] Add Lua and Go tests for one authored shop purchase, multiple shop cells, helper map
      composition, gold/no-stock edge cases, save/restore, orphan/mismatched records, and a
      mod-added shop vault. Confirm red.
- [ ] Extend terrain-feature resolution and `policy.population.vaults.materialize` to route shop
      records to the existing shop generator. Update restore validation only for a concrete
      uncovered invariant; bump save version only if its shape changes.
- [ ] Update the inventory and roadmap with exact playable coverage and remaining unrelated vault
      families. Run focused importer/Lua/game tests, build, vet, style, diff, then one broad game
      package run. Request whole-branch review, fix findings, make one implementation commit, and
      fast-forward local `main`.

## Self-review

The tasks cover import/discovery, source scripts, selection, typed shop specs,
map geometry, materialization, persistence, mod identity, and tests. The
review-focus failures each have a test in Tasks 1–5. The family is one
coherent content/runtime category; deeper branch generation and unrelated
vault families stay in later domain slices.
