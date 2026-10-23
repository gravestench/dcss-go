# Wizard Labs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan. Work in coherent
> batches and verify each integrated batch. Commit the shared portal
> registry as one category, then the completed Wizard Labs domain as one
> product category, following the user's commit preference.

**Goal:** Make all eleven source Wizard Labs entrances and fifteen complete
labs playable, moddable, and durable through the Go save format.

**Architecture:** Effective `.des` files supply stable map IDs and exact
source geometry. Lua hooks and policies own portal selection, travel,
timers, and lab events; Akara owns changing actors and timers, while the
level grid owns terrain. A Lua-discovered handler catalog replaces the
growing command and population portal chains. Go only supplies generic
context operations, staging, persistence, and terminal drawing.

**Tech Stack:** Go, GopherLua, Akara ECS, layered embedded modfs, `.des`
vault maps, Bubble Tea terminal client, JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-22-wizard-labs-design.md`

## Global constraints

- Keep the original MAP bytes and ordinary `.des` format.
- Put executable Lua in separate embedded files at source hook positions;
  never embed Lua text in Go.
- Commit generated content. Do not make source extraction part of builds.
- Keep dynamic state in Akara, terrain in grids, and seeded choices
  independent of file order.
- Comment every Lua function with why and how; use a theory of operation
  and usage examples. Use shared IDs at their use sites.
- Keep lines at most 120 characters, prefer 80, and expand multi-field
  literals.
- Keep tests in `_test.lua` where they exercise Lua behavior; reuse
  production catalogs and schemas in fixtures.
- Generate reviewable text floors and outside connections for every lab.

## Review focus

1. A Vaults room and an ordinary branch entrance must not both run the
   five-percent chance for one floor. The entrance test covers both paths.
2. An expired portal on an inactive floor must close before a later
   return; a last-valid-turn entry must still succeed. Timer/travel tests
   cover both edges.
3. A callback can fire again after restore without respawning the lich,
   reopening the door, or lowering the same wall twice. Event tests cover
   each once-only state.
4. A modded lab with no usable exit or duplicate portal ownership must
   fail before payment or movement. Catalog/staging tests cover both.
5. Reordering mod files must not change seeded selection or callback
   order. Catalog and replay tests compare effective ID order and the
   first post-restore draws.

---

### Task 1: Make portal handling extensible before adding another domain

**Files:**
- Create: `internal/modfs/builtin/policy/world/portals/catalog.lua`
- Create: `internal/modfs/builtin/policy/world/portals/handlers/*.lua`
- Modify: `internal/modfs/builtin/policy/commands/navigation.lua`
- Modify: `internal/modfs/builtin/policy/population/vaults.lua`
- Test: `internal/script/testdata/lua/tests/portal_handler_catalog_test.lua`
- Test: existing portal command, population, and save Go tests

**Interfaces:** `catalog.dispatch(ctx, request)` returns the temporary
portal travel decision; `request` holds `position`, `downstairs`, `forced`,
and `target_id`. Pan/Hell remain with their persistent branch owners.
`catalog.for_marker(record)` resolves a marker owner without side effects;
population invokes that owner's `materialize(ctx, level, record)` only after
earlier nonportal marker owners decline the record. Handlers declare a stable
ID and their feature IDs, and expose `prepare`, `is_marker`, and
`materialize` as applicable. The catalog rejects duplicate feature
ownership at load and multiple marker matches at materialization.

- [x] Write a Lua test using the real effective handler catalog: all
  existing portal entry/exit features have one owner, an unknown feature
  returns nil, a duplicate mod feature is rejected, and marker routing
  keeps source record order.
- [x] Implement a sorted, modfs-discovered catalog and one small wrapper
  module per existing temporary domain. Move their repeated calls and
  marker branches to one catalog call each. Keep persistent Pan/Hell
  travel and nonportal markers in their owners.
- [x] Run the catalog test and existing Bazaar, Sewer, Ossuary, Bailey,
  Ice Cave, Volcano, and Trove focused tests as one integration
  batch. Fix regressions before proceeding.
- [ ] Commit and push the shared temporary-portal handler category after
  that integration batch passes.

### Task 2: Commit source maps and port all source-position hooks

**Files:**
- Create: `internal/modfs/builtin/vaults/wizlab_entry/*.des` (11)
- Create: `internal/modfs/builtin/vaults/wizlab/*.des` (15)
- Create: `internal/modfs/builtin/policy/generation/vaults/wizlab_entry/*.lua`
- Create: `internal/modfs/builtin/policy/generation/vaults/wizlab/*.lua`
- Modify only where a real directive needs generic support:
  `policy/generation/vaults/{des,operations,placement}.lua` and
  `policy/generation/transporters.lua`
- Test: `internal/script/testdata/lua/tests/wizlab_source_catalog_test.lua`
- Test: `internal/script/testdata/lua/tests/wizlab_hooks_test.lua`

**Interfaces:** `vault.run("shared.portal")` sets source entrance
metadata and a typed timed `O` marker. Destination hooks emit source
directives, named fog and transporter records, and local map choices via
the existing placement API. `vaults.get(id)` resolves every effective
source `NAME` without a static Go map.

- [ ] Write source catalog assertions for all 26 IDs, MAP digests,
  metadata, source hook positions, and the Vaults zero-weight exception.
  Write hook tests for the nontrivial source branches and all destination
  hook references.
- [ ] Extract the 26 definitions into committed `.des` files with unique
  comments. Port shared and map-local Lua to focused modules; keep source
  bodies as comments near their DES hook where useful. Resolve item,
  monster, equipment, shuffle, transporter, fog, and feature records
  through existing content owners.
- [ ] Run the Lua catalog/hook group once the entire corpus resolves;
  audit all source MAP digests and review any intentional source fault
  correction in the per-file comments.

### Task 3: Timed entrance, destination generation, and travel

**Files:**
- Create: `internal/modfs/builtin/constants/wizlab.lua`
- Create: `internal/modfs/builtin/schemas/world_wizlab_portal.lua`
- Create: `internal/modfs/builtin/schemas/character_wizlab_visit.lua`
- Create: `internal/modfs/builtin/policy/world/wizlab/{portal,travel}.lua`
- Create: `internal/modfs/builtin/systems/world_wizlab_portals.lua`
- Create: `internal/modfs/builtin/policy/generation/wizlab/level.lua`
- Create: `internal/modfs/builtin/policy/save/wizlab_portals.lua`
- Modify: `internal/modfs/builtin/policy/generation/scenario.lua`
- Modify: `internal/modfs/builtin/policy/population/vaults.lua`
- Modify: `internal/modfs/builtin/policy/save/generated_levels.lua`
- Modify: `internal/game/save_restore_components.go`
- Modify: `internal/game/save_vault.go`
- Modify: `internal/modfs/builtin/constants/{component,rng_streams,terrain}.lua`
- Modify: `internal/modfs/builtin/content/terrain_features.lua`
- Modify: `internal/terrain/feature.go` and terminal glyph/presentation files
- Test: `internal/script/testdata/lua/tests/wizlab_portal_test.lua`
- Test: `internal/game/wizlab_travel_game_test.go`

**Interfaces:** `level.candidates(player)` returns stable positive-weight
effective destination IDs; `level.generate(ctx, input)` produces one
complete staged WizLab level, optionally with verified `layout_id`.
`portal.materialize(ctx, level, record)` creates one Akara gate.
`travel.prepare(ctx, position, downstairs)` and registered
`world.wizlab.commit_travel` use the generic staged transaction.
`save.validate_wizlab_portals` checks gate, marker, visitor, floor, and
feature without rerolling.

- [ ] Write tests for every entrance marker, Vaults' one-chance path,
  600–800-turn deadline, discovery/hearing/Silence, last-valid-turn
  entry, inactive-floor expiry, exact return address, occupied-return
  refusal, failed-stage rollback, and forged save joins.
- [ ] Implement the source clock and message policy, whole-floor weighted
  selector, source exit projection, handler registration, staged travel,
  and save validation. Add feature display and inspection using named
  constants. Keep only generic staging and persistence changes in Go.
- [ ] Run focused Lua and integrated travel/save tests as one batch.

### Task 4: Live Wizard Labs events

**Files:**
- Create: four focused Akara schemas under
  `internal/modfs/builtin/schemas/world_wizlab_*.lua`, one per callback
  family; add actor provenance only if the existing source-origin owner
  cannot carry the event identity
- Create: `internal/modfs/builtin/policy/world/wizlab/events/*.lua`
- Create: focused `internal/modfs/builtin/systems/world_wizlab_*.lua`
  files for countdown and death signals
- Create: `internal/modfs/builtin/policy/save/wizlab_events.lua`
- Modify: existing monster death and summoned-actor signal paths only
  where they lack a generic event needed by all four source callbacks
- Test: `internal/script/testdata/lua/tests/wizlab_events_test.lua`
- Test: `internal/game/wizlab_events_game_test.go`

**Interfaces:** Each event module exposes `materialize(ctx, level,
record)`, `tick(ctx, state)`, or `on_death(ctx, event)` only where its source
trigger needs it. Its own registered system queries its own component and
returns immediately outside its lab. No central lab-ID or monster-name
switch is added. Event state records source record indices, phase,
deadline, counters, and once-only flags.

- [ ] Write Lua tests against real source markers for Doroklohe's three
  phases, Zonguldrok's escalating grave waves and one-shot door/lich,
  Wucad's messages/monks/death suppression, and Borgnjor's lost-soul
  death guard. Add an integrated save/restore test for each callback's
  next draw and terrain/actor state.
- [ ] Implement all four event families as focused Lua files with Akara
  state, existing summon/fog/cloud owners, and grid mutations. Register
  each system in the established action/death ordering. Add semantic
  restore validation for marker groups and event counters.
- [ ] Run the event Lua and game tests together; inspect any source
  behavior whose current engine owner cannot yet execute and finish that
  owner before calling the domain complete.

### Task 5: Full-corpus integration, snapshots, docs, and one product commit

**Files:**
- Create: `internal/game/wizlab_maps_game_test.go`
- Create: `internal/game/testdata/wizlab-*-mod/` sparse fixtures
- Create: `docs/level-snapshots/wizlab/*.txt` (15 rooms and index)
- Modify: `docs/modding.md` and `docs/port-inventory.md`

- [ ] Add tests that stage and populate every destination with the real
  source hook and event state. Test sparse addition, same-path
  replacement, zero-weight removal, malformed marker/hook, ordinary
  terminal entry and return, and every authored return arch.
- [ ] Generate text snapshots from the production staging test; the
  index names selected lab IDs, any source helper, each return arch,
  and the exact outside gate.
- [ ] Explain the full lab mod contract and remaining cross-domain
  fidelity gaps. Run grouped Lua, integrated game, terrain, and terminal
  tests, then `git diff --check`, Lua line-length checks, and `gofmt -l`.
- [ ] Commit the finished domain as `Implement Wizard Labs portal domain`
  and push `main` to the user's fork. Leave the active port goal open for
  the next complete domain slice.
