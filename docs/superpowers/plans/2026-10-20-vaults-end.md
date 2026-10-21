# Vaults End Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan natively. The user
> authorized category-sized work on `main`; commit coherent categories and
> push `origin main` as they pass. Steps use checkbox syntax for tracking.

**Goal:** Build the source four-quadrant Vaults:5 encounter with exactly one
collectible silver rune and durable return travel.

**Architecture:** Commit the 73 source end maps as individual DES files.
Generic Lua DES composition selects source quadrants, paints source-sized
helpers, and tracks selected names. Named Lua hooks port the source choices.
Existing Akara entities, grid terrain, branch links, and Go saves own play.

**Tech Stack:** Go 1.26, gopher-lua, layered modfs, Akara ECS, DES maps,
Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-20-vaults-end-design.md`

## Global constraints

- The source `.des` MAPs remain authoritative; Lua lives in files under the
  embedded mod root and no importer or generated source step stays in repo.
- The main end map is selected by generic `PLACE: Vaults:$` precedence.
  No Go branch switch, second rune ledger, or separate V:5 map format.
- Source-size helper painting, selected-map queries, and selection history
  are local to one generation call. No process globals or load-order seeds.
- Lua files use named functions with why/how comments, lines at most 120
  characters, and multiline tables when populating several fields.
- Work on `main`, as the user requested; push commits to `origin/main`.
- Use focused verification after a coherent category. A full game package
  currently exceeds Go's default ten-minute timeout in the exhaustive
  character-start sweep; budget any broad run separately.

## Review focus

1. A duplicated quadrant NAME fails with both file paths at catalog load.
2. A helper whose MAP is empty paints only inside its assigned region and
   cannot mutate the parent outside it.
3. The rare mall mode still has one prize quadrant and one real rune.
4. A saved level missing its rune, carrying two real runes, or pointing its
   V:5 stair at another branch fails restore validation.
5. An old save with the earlier unavailable V:5 frontier remains valid
   without silently changing its stored stair link.

---

### Task 1: Commit the source Vaults end corpus

**Files:** Create `vaults/layout/vaults_vault.des` and 72 named maps under
`internal/modfs/builtin/vaults/vaults_end/`; create named Lua modules under
`policy/generation/layouts/` and
`policy/generation/vaults/vaults_end/` for every replaced source script site;
test with `internal/script/testdata/lua/tests/vaults_end_corpus_test.lua`.

**Interfaces:** The existing `policy.generation.vaults.catalog.get(id)`
returns parsed helpers. `policy.generation.layouts.catalog.get("vaults_vault")`
returns the main map with its `PLACE: Vaults:$` clause. Hook validation uses
the existing module-resolution convention.

- [ ] Write a failing Lua corpus test asserting one main map, 40 regular
  quadrants, 25 prize quadrants, three rune-location helpers, four inner-room
  helpers, their overlapping mall tags, unique IDs, and valid named hooks.
- [ ] Split only the 73 end definitions from the pinned source into one
  committed DES file each. Use a temporary outside-repo splitter; retain
  source MAPs and directive order, replacing executable source Lua sites
  with named hook calls. Document the inactive legacy rune mimic in its file.
- [ ] Implement each named hook module as a local object of commented
  functions. At this task boundary, hooks may rely on Task 2's agreed API
  signatures, but they must load and validate.
- [ ] Run the corpus test, inspect every emitted file for inline Lua and
  path/name collisions, then commit and push the content category.

### Task 2: Extend generic DES composition for end maps

**Files:** Modify `policy/generation/layouts/catalog.lua`,
`policy/generation/layouts/authored.lua`,
`policy/generation/vaults/operations.lua`, and the source-size hook API in
that module. Add generic fixture tests in
`internal/script/testdata/lua/tests/des_composition_test.lua` and
`layout_place_selection_test.lua`.

**Interfaces:** `catalog.choose(random, branch_id, depth, bottom, tags)`
chooses an eligible explicit `PLACE` layout before ordinary weighted maps.
The DES hook API gains `map_size()`, `set_cell(x, y, glyph)`, and
`has_placed_tag(tag)`; coordinates are zero-based within the current MAP.
`operations.apply` shares one used-map state across nested SUBVAULT calls
and returns the selected helper IDs with typed records. Authored layout
results expose those IDs and protected occupied cells.

- [ ] Write failing fixtures for explicit PLACE precedence, an absent PLACE
  fallback, repeated non-duplicable helper names, selected-tag visibility,
  nested helper ID order, source-size painting at two rectangular sizes,
  and attempts to paint outside the helper region.
- [ ] Implement explicit PLACE selection without changing ordinary Dungeon
  or Vaults:1–4 weighted draws. Keep any exact-floor eligibility in parsed
  DES metadata rather than a handwritten map-name switch.
- [ ] Thread a local used-map state and selected-tag view through nested
  helper placement; publish a helper name only after successful embedding.
  Return committed IDs with the authored layout for saves and later draws.
- [ ] Give empty-MAP helpers a matrix sized to their assigned region and
  expose only bounded map mutation to named hooks. Preserve source directive
  order and typed record coordinates.
- [ ] Run the generic fixture tests and affected layout/vault tests, then
  commit and push the reusable composition category.

### Task 3: Implement source quadrant and rune decisions

**Files:** Fill the Task 1 Lua hook bodies in
`policy/generation/layouts/vaults_vault.lua` and
`policy/generation/vaults/vaults_end/*.lua`; update
`policy/generation/floor_availability.lua` to require an effective explicit
end layout on V:5. Test with
`internal/script/testdata/lua/tests/vaults_end_composition_test.lua`.

**Interfaces:** Main hook methods emit four SUBVAULT declarations after its
SHUFFLE, with source one-in-36 mall mode. Shared quadrant hooks emit source
loot and choose real/no-rune helper from local selected-map state. The end
composition result has `records`, `vault_ids`, and `protected` cells.

- [ ] Write failing tests for all 65 quadrant definitions composing at their
  source size; normal and mall mode; prize location after SHUFFLE; one-in-four
  prize rune path; ordinary-quadrant fallback; one real `RUNE_VAULTS` item;
  source no-rune loot/shop choices; and inner-room border/diamond patterns.
- [ ] Implement the named methods using imported directive, tag, item, and
  effect IDs. Keep each source decision in a small commented function and
  preserve the authored MAP rather than recreating it in Lua.
- [ ] Assert exactly one real rune record before accepting a composed V:5
  floor. Reject an unsupported source expression with its DES path and name.
- [ ] Run the complete V:5 Lua composition batch and affected vault entity
  tests, then commit and push this behavior category.

### Task 4: Open V:5, play the rune, and validate saves

**Files:** Modify `policy/generation/generated.lua`,
`policy/generation/generated_stairs.lua`,
`policy/save/generated_levels.lua`, and rune/item save validation only where
the existing owners need a shared V:5 invariant. Add
`internal/game/vaults_end_test.go`. Update `docs/modding.md` and
`docs/port-inventory.md`.

**Interfaces:** A new V:4 down stair points to V:5; V:5 uses the explicit
`vaults_vault` PLACE map and reciprocal landing. The existing
`RUNE_VAULTS` item enters the ECS world, and the existing player rune
component records pickup. Restore validates generated levels and rune state.

- [ ] Write a failing seeded game test for V:4→V:5→V:4 exact coordinates,
  four quadrant IDs, one ground silver rune, source monsters and loot,
  save/restore before and after rune pickup, and no generic V:5 layout.
- [ ] Write restore rejection tests for zero or two real rune records,
  missing selected-map IDs, forged V:5 links, and old unavailable V:5 saves.
- [ ] Open V:5 only after the explicit end map is discoverable; carry its
  helper IDs and records through generic population and save paths. Reuse
  existing rune pickup and player progress policies without a second ledger.
- [ ] Explain adding an end quadrant and a source-sized helper in the
  modding guide; update the port inventory. Run focused Lua, game, style,
  and diff checks, then commit and push the playable V:5 category.
