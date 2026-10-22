# Ossuary Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking. The user chose native execution.

**Goal:** Make the 14 source Ossuary entrances and 20 destinations a playable,
timed, saved D:4–8 portal domain, including the sliding-wall event.

**Architecture:** Checked-in source `.des` maps own geometry and static
selection metadata; named Lua hooks own source scripts. Lua owns selection,
ECS clocks, travel, triggers, and save invariants. Go reuses its staged
`luaPortal` transaction and adds only generic terrain and save wiring.

**Tech Stack:** Embedded Lua, source DES, Akara ECS, Go terrain and save
services, Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-21-ossuary-portal-design.md`

## Global Constraints

- Preserve all 34 active source `NAME` identities, `MAP` rows, directive
  order, weights, tags, and orientation in committed assets.
- Only intentional upstream refreshes read C++; neither builds nor play
  require the C++ checkout or an importer.
- Put executable Lua in documented named `.lua` files, never Go strings or
  inline `.des` scripts. Keep source map syntax for authored geometry.
- Keep every Lua function's why/how comments, prefer 80-character lines,
  never exceed 120, and expand multi-field declarations.
- Dynamic clocks and visits live in Akara ECS; terrain remains a dense grid.
- Reuse the generic staged portal transaction and layered VFS. Do not add an
  Ossuary-only Go travel path or an order-sensitive content switch.
- Work on `main`; verify the complete category, then make one category
  commit and push to the user's fork.

## Review Focus

1. A generated Dungeon floor with an Ossuary entrance starts its timer at
   placement, even before the player steps on the gate. Task 2 tests this.
2. Entering on the last valid turn must finish before expiry; a rejected
   staged floor must leave player, gate, RNG, and entities intact. Task 2
   tests both boundaries.
3. A save made after some, but not all, linked walls have opened must be
   rejected rather than silently restored. Task 3 tests this forgery.
4. A sparse mod map and a same-path hook override must use the effective
   VFS catalog without changing seeded built-in order. Tasks 1 and 3 test
   both forms.
5. An exit blocked at the saved outside cell must not relocate the player
   or retire the Ossuary. Task 2 tests this after restore.

## File Map

- `internal/modfs/builtin/vaults/{ossuary_entry,ossuary}/*.des`: one source
  definition per replaceable file.
- `internal/modfs/builtin/policy/generation/vaults/{ossuary_entry,ossuary}/*.lua`:
  named source-position hooks; shared entry and exit helpers.
- `internal/modfs/builtin/policy/generation/ossuary/level.lua`: stable
  weighted whole-floor selection and placement.
- `internal/modfs/builtin/policy/world/ossuary/{portal,travel}.lua` and
  `internal/modfs/builtin/systems/world_ossuary_portals.lua`: ECS clock and
  staged travel policy.
- `internal/modfs/builtin/policy/world/vault_triggers.lua`,
  `policy/world/vault_trigger_callbacks/ossuary_boxes.lua`, and
  `schemas/world_vault_trigger.lua`: synchronized saved trigger group.
- `internal/modfs/builtin/policy/save/{ossuary_portals,ossuary_levels}.lua`:
  reciprocal portal, visit, level, and linked-wall validation.
- `internal/modfs/builtin/constants/{ossuary,component,terrain}.lua`,
  `internal/modfs/builtin/schemas/{world_ossuary_portal,character_ossuary_visit}.lua`,
  `internal/modfs/builtin/content/terrain_features.lua`, and
  `internal/terrain/feature.go`: vocabulary and durable state.
- `internal/modfs/builtin/policy/generation/scenario.lua`,
  `internal/modfs/builtin/policy/save/generated_levels.lua`, and
  `internal/game/save_restore_components.go`: registration and generic
  restore calls; other existing portal dispatch files only as required.
- `internal/script/testdata/lua/tests/ossuary_*_test.lua`,
  `internal/script/testdata/ossuary-vault-mod/`,
  `internal/script/lua_rules_test.go`,
  `internal/game/ossuary_travel_game_test.go`, and
  `internal/terminal/dungeon_render_test.go`: corpus, mod, timer, trigger,
  travel, save, rollback, and glyph tests.
- `docs/{modding,port-inventory}.md`: mod authoring and coverage.

---

### Task 1: Source Corpus and Whole-Floor Generation

**Interfaces:** `policy.generation.ossuary.level.candidates(player) ->
{ { id, weight } }` returns positive-weight maps in stable ID order;
`level.generate(ctx, input) -> { level }` accepts optional `layout_id` and
returns an uninstalled, populated whole-floor record. Named DES hooks accept
the production `api` object and emit typed directives or source records.

- [ ] **Step 1: Write failing corpus tests.** In
  `internal/script/testdata/lua/tests/ossuary_source_catalog_test.lua`,
  assert exactly 14 entrance paths and 20 destination paths, all 34 IDs,
  source-derived `MAP` digest `3110416243`, original weights, D:4–8
  chance 500 and
  `uniq_ossuary no_monster_gen chance_ossuary` tags. Assert every destination
  generates with safe arrival, live exit, and its authored placement records;
  collectively check typed item, monster, trap, marker, and terrain requests.
  Add focused assertions for the coinflip,
  conditional substitutions, loot, flood reservoir/range/weights, and
  sliding-wall marker records.
- [ ] **Step 2: Verify red.** Run
  `env GOCACHE=/private/tmp/dcrawl-go-cache go test ./internal/script -run 'TestLuaRules/ossuary' -count=1`;
  expect absent Ossuary corpus/generator assertions to fail. Register the
  new Lua test through the existing Lua rule harness if its file list is
  explicit.
- [ ] **Step 3: Split and port the source.** Check in each source `NAME` as
  one `.des` file, preserving geometry and static directive order. Replace
  executable source lines with named Lua hook references at the same
  positions. Implement `ossuary_portal`, `ossuary_setup_features`, and
  local hooks for `nicolae_ossuary_entry_plus`, `ossuary_tomb_2`,
  `ossuary_crypta`, `ossuary_the_hunt_dpeg`, `ossuary_zaba_flooded`, and
  `ossuary_boxes_badplayer`. Preserve sand colours and tiles, one draw per
  source decision, and the flood's reservoir sampling.
  Add `level.candidates` and `level.generate` through existing vault
  eligibility, weight, placement, typed population, and branch-level APIs.
  Preserve any not-yet-active gameplay effect as an explicit typed record.
- [ ] **Step 4: Verify green.** Run the focused Lua corpus test and
  `env GOCACHE=/private/tmp/dcrawl-go-cache go test ./internal/game -run TestOssuaryAllSourceMapsPopulate -count=1`
  after adding the integrated 20-map population test. Expect all 20
  destinations to install without losing authored records.

### Task 2: Timed Entrance and Exact Travel

**Interfaces:** `policy.world.ossuary.portal.materialize(ctx, level,
record) -> { level_id, index }` creates one `world.ossuary_portal` entity at
placement time; `portal.at(ctx, level_id, x, y) -> entity, state` identifies
it. `world.ossuary.commit_travel` is the Lua callback for the existing
`luaPortal` transaction; `world.generate_ossuary_level` calls Task 1.

- [ ] **Step 1: Write failing Lua and game tests.** Pin source initial,
  periodic, final, visible-expiry, and unseen-expiry text; five speed bands;
  Silence at either end; message cadence advancing while silent; and a
  600–800-turn duration drawn once. Test D:4–8 eligibility and absence
  outside that range. In Go test timer origin immediately after Dungeon
  floor population, off-floor expiry, entry at deadline, failed staging
  rollback including RNG/entities, exact return after save/restore, blocked
  return, and retired temporary entities. Add a terminal glyph assertion for
  both distinct Ossuary terrain IDs.
- [ ] **Step 2: Verify red.** Run the focused Lua tests and
  `env GOCACHE=/private/tmp/dcrawl-go-cache go test ./internal/game -run 'TestOssuary' -count=1`;
  expect missing terrain, clock, or travel behavior to fail.
- [ ] **Step 3: Implement the domain.** Add named Ossuary terrain and ECS
  schemas, source marker parsing, placement-time clock materialization,
  global action-time system, and Lua travel policy. Register the whole-floor
  generator and use `luaPortal` to stage entry and retire exit. Spend the
  outside gate only after successful staging. Save the outside level and
  exact cell on `character.ossuary_visit`; reject occupied returns without
  spending time. Use the source timed-marker hearing distance and existing
  Silence owner.
- [ ] **Step 4: Verify green.** Run the same focused tests; expect timer,
  entry, return, and rollback assertions to pass.

### Task 3: Synchronized Walls, Saves, Mods, and Category Verification

**Interfaces:** `vault_triggers.materialize` stores a stable group ID and
source record links on `world.vault_trigger`; the Ossuary callback consumes
all sibling triggers and opens all surviving linked walls atomically.
`save.validate_ossuary_portals(ctx, input)` and
`ossuary_levels.validate(saved_levels)` reject inconsistent saved state.

- [ ] **Step 1: Write failing trigger, save, and VFS tests.** Enter each
  `ossuary_boxes_badplayer` `:` cell before and after restore; assert one
  click message, every `a`/`b` wall opens, and no rearmed group. Forge a
  partly opened wall set, bad group/record links, deadline, marker, outside
  site, and chosen map; expect restore rejection. Add a sparse mod-added
  destination and a same-path Lua hook override; assert sorted candidates,
  stable built-in seeded choice, overridden hook behavior, and early
  rejection of a broken hook.
- [ ] **Step 2: Verify red.** Run focused Lua rules and
  `env GOCACHE=/private/tmp/dcrawl-go-cache go test ./internal/game -run 'TestOssuary' -count=1`;
  expect trigger, save, and mod assertions to fail.
- [ ] **Step 3: Implement the group and validators.** Extend the existing
  trigger owner and schema with durable group/record identity. Put the wall
  transformation and message in a named Ossuary callback. Add Ossuary
  portal and level validators, register them with generic save restore,
  and validate selected effective maps and reciprocal visit links. Update
  the modding guide with both directories, hook API, clock/trigger schemas,
  and sparse layer example; update the port inventory with precise coverage
  and any remaining broader gameplay gaps.
- [ ] **Step 4: Verify green and commit once.** Run focused Lua and game
  tests, `env GOCACHE=/private/tmp/dcrawl-go-cache go test ./...`,
  `gofmt -w` on changed Go files, the changed-file 120-column check, and
  `git diff --check`. Review staged source/map parity and save invariants.
  Commit the complete Ossuary category on `main` and push `origin main`.
