# Treasure Trove Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all source Treasure Trove entrances, prices, reward maps, payment paths, and exact return travel playable and saved.

**Architecture:** Source DES files remain separate mod assets. Focused Lua modules roll and save an Akara toll, match and debit payment, generate a weighted whole-floor reward map, and commit travel through the existing staged portal transaction. Go remains responsible for generic grid, ECS, command, save, and terminal services.

**Tech Stack:** Go, Akara ECS, embedded Lua, layered mod VFS, DES placement, Bubble Tea/Lip Gloss, Go snapshot codec.

**Spec:** `docs/superpowers/specs/2026-10-22-trove-portal-design.md`

## Global Constraints

- Implement all 35 source definitions: 14 entrances and 21 destinations, including source-position hooks and byte-identical MAP rows.
- Builds and normal tests read committed Lua/DES only; do not commit a source importer or embed Lua text in Go.
- Mutable toll, payment, and visit state belongs in Akara; terrain and appearance remain in grids and source records.
- A denied toll spends no action time and does not change the gate, inventory, piety, RNG, or staged world.
- A successful toll debit and portal travel are one reversible transaction; every exit returns to the exact saved outside cell.
- Lua files need per-function why/how comments, systems need a theory of operation, policies need usage examples, and lines must be at most 120 characters.
- Use one contiguous product commit after the slice gate, then push `main`. The spec and plan are documentation commits.

## Review Focus

1. A mod-added entrance with an absent or malformed toll must fail at placement, before a game can save it; Task 2 tests this.
2. An item that matches type but is unidentified or equipped must not open the gate or be consumed; Task 4 tests this.
3. A rune toll must check the named rune and keep it, including after save/restore; Task 4 tests this.
4. A confirmed stair command for an old gate must not pay a different gate after the player moves; Task 4 tests the confirmation target.
5. A paid gate followed by failed destination placement must leave the item, piety, gate, and RNG intact; Task 4 tests this.

---

### Task 1: Source corpus, hook registration, and portal features

**Files:**
- Create: `internal/modfs/builtin/vaults/trove_entry/*.des`, `internal/modfs/builtin/vaults/trove/*.des`
- Create: `internal/modfs/builtin/policy/generation/vaults/trove_entry/shared.lua`, `internal/modfs/builtin/policy/generation/vaults/trove/*.lua`
- Modify: `internal/terrain/feature.go`, `internal/modfs/builtin/constants/terrain.lua`, `internal/modfs/builtin/policy/generation/vaults/hooks.lua` (if needed for named hooks)
- Test: `internal/script/testdata/lua/tests/trove_source_catalog_test.lua`, `internal/script/testdata/lua/tests/trove_hooks_test.lua`, `internal/terrain/ice_cave_portal_test.go`

**Interfaces:**
- Produces the effective vault families `trove_entry` and `trove`, named hook IDs, and `DNGN_ENTER_TROVE`/`DNGN_EXIT_TROVE` grid features.
- The entrance hook emits a declarative marker with an empty typed price
  field; Task 2 rolls and fills it during population. Destination hooks
  emit ordinary typed operations and source item requests.

- [ ] Compare source definitions and write a failing Lua test for 14/21 IDs, source MAP digests, entry depth/chance metadata, and all hook names; verify it fails before adding files.
- [ ] Extract the 35 definitions into individually named DES files. Keep MAP rows exact; convert source script sites to named Lua hooks, preserving directive order. Implement shared and map-specific hooks as focused commented modules.
- [ ] Add terrain IDs and assert source glyph/description rendering in the existing terrain test. Run `go test ./internal/script -run 'TestLuaRules/trove_(source_catalog|hooks)' -count=1 -timeout 5m` and the focused terrain test; expect pass.

### Task 2: Saved price and source marker owner

**Files:**
- Create: `internal/modfs/builtin/constants/trove.lua`, `internal/modfs/builtin/policy/world/trove/toll.lua`, `internal/modfs/builtin/policy/world/trove/portal.lua`, `internal/modfs/builtin/schemas/world_trove_portal.lua`
- Modify: `internal/modfs/builtin/constants/component.lua`, `internal/modfs/builtin/constants/rng_streams.lua`, `internal/modfs/builtin/policy/population/vaults.lua`
- Test: `internal/script/testdata/lua/tests/trove_toll_test.lua`, `internal/game/trove_toll_game_test.go`

**Interfaces:**
- `toll.roll(ctx, player)` returns one source-shaped immutable price table: kind, item base/subtype, quantity, minimum plus, ego, artefact, or rune ID.
- `toll.encode(price)` returns the validated canonical marker string that
  save validation compares to the Akara gate's price fields.
- `portal.materialize(ctx, level, record)` validates the source marker,
  draws exactly one price from the `TROVE_TOLL` generation stream,
  compare-and-replaces the marker's empty price with `toll.encode(price)`,
  and adds `world.trove_portal` with source level/cell/vault/record, price,
  open/spent state, closure reason, and empty receipt.
- `portal.at(ctx, level_id, x, y)` returns the matching gate entity and component or nil.

- [ ] Write `_test.lua` vectors for the source price classes, 1-in-20 piety choice, species/god exclusions, shop candidate path, malformed toll marker, and stable seed order. Run the focused Lua test and observe failures.
- [ ] Implement price selection in small Lua functions, import item/god/species IDs where used, and materialize one Akara gate per realized `O`. Do not store mutable price globals.
- [ ] Add a Go integration test that places all 14 entrances, proves each has exactly one saved gate and a legal price, and compares an uninterrupted next draw with restore. Run focused Go and Lua tests; expect pass.

### Task 3: Whole-floor reward generation

**Files:**
- Create: `internal/modfs/builtin/policy/generation/trove/level.lua`, focused destination hook modules under `policy/generation/vaults/trove/`
- Modify: `internal/modfs/builtin/policy/generation/scenario.lua`, item-request policy only where a source request lacks a generic implementation
- Test: `internal/script/testdata/lua/tests/trove_generation_test.lua`, `internal/game/trove_maps_game_test.go`

**Interfaces:**
- `level.candidates(player)` returns sorted positive-weight effective top-level Trove maps.
- `level.generate(ctx, input)` returns the existing staged-level result for `world.generate_trove_level`, with selected vault ID, full grid, safe source exit arrival, typed records, and Akara-populatable actors/items.

- [ ] Write failing Lua tests for source weights, exclusion of zero-weight maps, requested-ID eligibility, and branch/depth context; write a Go table test staging all 21 maps and checking every authored exit and populated source record.
- [ ] Implement whole-floor selection and all map hooks using existing weighted catalogs, placement, item generation, acquirement, fog, shops, and Akara population. Keep content decisions in Lua and every source operation represented.
- [ ] Run `go test ./internal/script -run 'TestLuaRules/trove_generation' -count=1 -timeout 5m` and `go test ./internal/game -run '^TestTroveAllSourceMapsPopulate$' -count=1 -timeout 7m`; expect pass.

### Task 4: Confirmation, debit, travel, and return

**Files:**
- Create: `internal/modfs/builtin/policy/world/trove/payment.lua`, `internal/modfs/builtin/policy/world/trove/travel.lua`, `internal/modfs/builtin/schemas/character_trove_visit.lua`
- Modify: `internal/modfs/builtin/constants/component.lua`,
  `internal/modfs/builtin/policy/commands/navigation.lua`,
  `internal/modfs/builtin/policy/commands/entries_navigation.lua`; use the
  existing `TargetID` confirmation contract.
- Test: `internal/script/testdata/lua/tests/trove_payment_test.lua`, `internal/game/trove_travel_game_test.go`, focused terminal confirmation test

**Interfaces:**
- `payment.offer(ctx, player, gate)` returns the price prompt and stable marker target, with no writes.
- `payment.match(ctx, player, gate)` returns the exact carried entity or named rune proof, or a refusal message.
- `payment.commit(ctx, player, gate, match)` stages the source debit or piety reduction and returns a receipt.
- `travel.prepare(ctx, position, downstairs, forced, target_id)` returns the ordinary confirmation/free refusal or staged Lua portal plan.
- `world.trove.commit_travel` rechecks price and marker, pays once, spends the gate, creates/removes `character.trove_visit`, and moves the player through the generic transaction.

- [ ] Write failing tests for refusal, insufficient quantity, unknown identity, equipped item, exact/higher plus choice, partial stack, rune proof, no-piety and Ashenzari cases, stale confirmation target, and failed generation rollback. Assert zero action time and unchanged snapshots on refusals.
- [ ] Implement the Lua payment owner using current inventory, identification, rune, religion, and stack services. Add the Trove route to navigation and return through any source exit. Preserve the terminal's existing confirmation screen.
- [ ] Run `go test ./internal/game -run '^TestTrove' -count=1 -timeout 7m` and focused terminal confirmation checks; expect pass.

### Task 5: Save validation, mods, snapshots, and final gate

**Files:**
- Create: `internal/modfs/builtin/policy/save/trove_portals.lua`, `internal/modfs/builtin/policy/save/trove_levels.lua`, `internal/game/trove_mod_game_test.go`
- Modify: `internal/game/save_restore_components.go`, `docs/modding.md`,
  `docs/port-inventory.md`, `internal/terminal/dungeon_render_test.go`
- Create: `docs/level-snapshots/trove/index.txt` and one text snapshot per source destination

**Interfaces:**
- Save validators consume effective source records and the `world.trove_portal`/`character.trove_visit` components; they reject impossible price, receipt, marker, terrain, or reciprocal floor state before play resumes.
- Mod fixtures exercise add, replace, zero weight, malformed hook, malformed price, and impossible fit without editing bundled files.

- [ ] Write failing restore tests for forged price, duplicate/missing gate, spent gate without receipt, missing visitor, moved return cell, and mismatched selected layout. Run targeted tests to confirm rejection is absent.
- [ ] Add Lua save validators and source-description presentation, then test save/restore before and after payment and after return. Verify no toll, map, or reward reroll.
- [ ] Export all 21 destination floor text snapshots through the production staging test. Index each source exit and the exact outside gate; commit the generated text. Add sparse mod fixtures and modding instructions.
- [ ] Run focused Trove Lua, game, terrain, and terminal gates; run changed-file Go readability, Lua 120-character line check, and `git diff --cached --check`. Fix actual Trove failures in one category pass. Request a final code review, then commit and push the contiguous Trove product change on `main`.
