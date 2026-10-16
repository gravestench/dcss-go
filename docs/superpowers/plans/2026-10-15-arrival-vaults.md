# Source-backed Arrival Vaults Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking. The user chose native execution.

**Goal:** Make all 337 source-tagged Dungeon arrival vaults selectable and
placeable from committed `.des` files, with their 36 scripted definitions
ported to readable Lua and their effects preserved through saves.

**Architecture:** The layered mod filesystem serves both `.lua` and `.des`.
A Lua DES reader registers 339 ordered definitions, runs small named hooks
at source positions, and owns selection and placement. Go retains the level
grid, ECS entities, typed level annotations, and save codec.

**Tech Stack:** Go, Gopher Lua, Akara ECS, the existing layered mod filesystem,
and the pinned DCSS `.des` files at revision
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

**Spec:** `docs/superpowers/specs/2026-10-15-arrival-vaults-design.md`

## Global Constraints

- Commit generated `.des` sources; normal builds never read the C++ checkout.
- Preserve the original DES map syntax and source declaration order.
- Keep gameplay Lua in `.lua` files; no Lua source in Go strings.
- All 337 tagged arrivals remain selectable; two untagged helpers remain
  parent-only. Unsupported effects become typed, saved pending records.
- Mods may add or replace one `.des` or Lua handler file through layered paths.
- Keep handwritten Go and Lua under 120 columns, preferably near 80, with
  expanded multi-field declarations and named, focused Lua functions.
- Use one commit for this contiguous arrival-vault category after its full
  boundary verification, as requested by the user.

## Review Focus

1. A sparse overlay replacing only a DES file or only its handler resolves
   against the effective tree and changes its hash (Task 1 and Task 3 tests).
2. A script branch around DES directives executes only the chosen branch
   at its source position, including the crop-circle `SUBST` case (Task 3).
3. A vault with an exit marker or multiple stairs keeps every coordinate and
   validates its links after fitting and connection (Task 5).
4. A source item, monster, marker, or effect without active gameplay keeps a
   typed identity across save/restore, without becoming a generic string
   blob or silently vanishing (Task 6).
5. A malformed mod vault, duplicate `NAME`, unported inline Lua, or failed
   placement reports its path, vault ID, and failing operation (Tasks 3–5).

## File map

- `internal/modfs/ruleset.go` owns effective `.lua` and `.des` bytes and
  hashes; `internal/script/runtime.go` exposes sorted `mod.paths` and
  `mod.read` without evaluating DES as Lua.
- `cmd/importvaults/main.go` and `internal/vaultimport/` own the deliberate
  pinned-source split. `internal/vaultimport/ports/<id>.json` contains only
  import-time script spans and hook replacements, not runtime content.
- `internal/modfs/builtin/vaults/arrival/<id>.des` contains one committed
  source-format definition per vault. Script provenance stays in comments.
- `internal/modfs/builtin/policy/generation/vaults/des.lua` parses DES;
  `catalog.lua` registers it; `hooks.lua` dispatches named handler methods;
  `operations.lua`, `transforms.lua`, `selection.lua`, `placement.lua`, and
  `connect.lua` own the distinct generation steps. The 36 scripted vaults
  each get `policy/generation/vaults/arrival/<id>.lua`.
- `internal/modfs/builtin/constants/catalog.lua` names the `VAULTS` category;
  `ids/vaults.lua` resolves registered names where policy needs them.
- `internal/modfs/builtin/policy/generation/generated.lua` and `basic.lua`
  integrate the D:1 vault into the existing 80×70 generator. The save
  validator in `policy/save/generated_levels.lua` checks the resulting
  variable stair set.
- `internal/terrain/feature.go`, `internal/game/level.go`,
  `internal/game/generation_script.go`, `internal/game/save.go`,
  `internal/game/save_restore_levels.go`, and `internal/save/snapshot.go`
  own typed terrain, placement records, and persistence.

### Task 1: Serve DES through the layered ruleset

**Files:** Modify `internal/modfs/ruleset.go`, `internal/modfs/ruleset_test.go`,
and `internal/script/runtime.go`. Test in `internal/script/runtime_test.go`.

**Interfaces:** `Ruleset.ReadFile(path string) ([]byte, error)` accepts `.lua`
and `.des`; `Ruleset.Paths()` includes both. Lua gets
`mod.paths(prefix, suffix) -> sorted path list` and
`mod.read(path) -> exact source string` from the effective ruleset.
`mod.load_tree` and `require` still execute only `.lua`.

- [ ] Add `TestDESOverlayIdentity` and `TestDESPathValidation`: one added
  `.des` must appear once in sorted paths and the manifest; replacement by
  the last layer must change its bytes and hash; an unchanged overlay must
  leave the hash unchanged. Assert copy-on-read and rejection of traversal,
  symlinks, case collisions, and unsupported extensions. Add
  `TestLoadTreeSkipsDES` to assert Lua bootstrap succeeds with a DES file in
  a loaded tree.
- [ ] Run `go test ./internal/modfs ./internal/script -p 1`; confirm the new
  DES tests fail for the missing behavior.
- [ ] Extend path validation and runtime module APIs with the interfaces
  above. Keep the current Lua module loader's `.lua` restriction explicit.
- [ ] Run the same test command; confirm the new tests pass.

### Task 2: Import the full pinned source as committed DES files

**Files:** Create `cmd/importvaults/main.go`, `internal/vaultimport/import.go`,
`internal/vaultimport/import_test.go`,
`internal/vaultimport/ports/<scripted-id>.json`, and
`internal/modfs/builtin/vaults/arrival/<id>.des` for all 339 names.

**Interfaces:** `vaultimport.Generate(sourceDir, portsDir string)
(map[string][]byte, error)` returns path-keyed bytes;
`vaultimport.Write(sourceDir, portsDir, outDir string, check bool) error`
writes atomically or checks committed bytes. `-source`, `-ports`, `-out`,
and `-check` are CLI flags. Four pinned source hashes and the revision are
checked before generating. Each port recipe pins its source script span
and hash and replaces it with `: vault.run("method")` or
`: vault.veto("method")`; the original lines become DES comments.

- [ ] Add `TestPinnedArrivalImport` asserting 339 unique names, 337
  `arrival` tags,
  two helper names, exact map rows, all directive families, all 35 source
  `:` script owners, one additional `{{...}}` script owner, one veto, and
  rejection of unknown directives, source
  drift, or recipe drift. `TestArrivalImportCheck` must fail when one
  committed output byte is changed.
- [ ] Run `go test ./internal/vaultimport -p 1`; confirm failure.
- [ ] Implement the splitter and per-vault port recipes. For conditional
  source blocks, the recipe replaces the entire interleaved region, including
  branch-only directives, with one source-position hook and comments.
- [ ] Generate all 339 committed files once. Run the exact byte check:

  ```sh
  go run ./cmd/importvaults \
    -source ../crawl/crawl-ref/source/dat/des/arrival \
    -ports internal/vaultimport/ports \
    -out internal/modfs/builtin \
    -check
  ```

  Confirm byte-for-byte reproduction.
- [ ] Run `go test ./internal/vaultimport ./internal/modfs -p 1`; confirm pass.

### Task 3: Parse, register, and execute ordered DES hooks

**Files:** Create `internal/modfs/builtin/policy/generation/vaults/des.lua`,
`catalog.lua`, `hooks.lua`,
`internal/script/testdata/lua/tests/arrival_des_test.lua`, and
`arrival_hooks_test.lua`. Modify `internal/modfs/builtin/init.lua` and
`internal/modfs/builtin/constants/catalog.lua`; create
`internal/modfs/builtin/ids/vaults.lua`.

**Interfaces:** `des.parse(path, source) -> definition` yields `id`, `tags`,
`orientation`, `weight`, `rows`, and ordered `operations` containing source
line numbers. `catalog.load()` uses `mod.paths("vaults/arrival", ".des")`
and `mod.read`, then `register.definition(categories.VAULTS, definition)`.
`hooks.run(vault, method, api)` invokes that vault's same-ID Lua module.
An ephemeral `api` supplies `roll`, `one_in`, `emit`, `record`, marker lookup,
and exit checks; veto methods return a boolean. DES accepts only literal
named `vault.run` and `vault.veto` hook calls in executable `:` lines.

- [ ] In `arrival_des_test.lua`, assert each source directive parses into
  its ordered operation kind, `MAP` rows retain spaces, and weight and
  orientation retain source values. In `arrival_hooks_test.lua`, assert a
  small test handler inserts one operation between its neighbors. Add Go
  overlay tests for a new mod vault, replacement DES, duplicate `NAME` with
  both paths, and path/line errors for raw Lua or unknown hooks.
- [ ] Run `go test ./internal/script -run TestLuaRules -p 1`; confirm the
  new Lua tests fail.
- [ ] Implement the reader, catalog, and hook contract; load the catalog
  during `init.lua` before registrations freeze. Resolve handler methods
  when invoked; Task 4 adds eager validation once all 36 modules exist.
  Keep parse errors annotated with path, vault name, line, and operation.
- [ ] Run `go test ./internal/script -run TestLuaRules -p 1`; confirm pass.

### Task 4: Port all source Lua behavior to named handlers

**Files:** Create the 36 corresponding
`internal/modfs/builtin/policy/generation/vaults/arrival/<id>.lua` modules
and `internal/script/testdata/lua/tests/arrival_handlers_test.lua`.

**Interfaces:** Each module returns one local handler object whose named
methods accept the Task 3 ephemeral API. `vault.run` methods emit typed
operations or records; `vault.veto` methods return whether the candidate
must be rejected. No handler imports the old `crawl`, `dgn`, `you`, or
`util` API. Shared constants and IDs are imported where used.

- [ ] Add `arrival_handlers_test.lua` as one table-driven test enumerating
  all 36 scripted vaults,
  verifies every DES hook has a method, forces each random branch, and checks
  the output operation or effect type against the pinned script. Include the
  marker-based veto, delayed decay, feature naming, and species-dependent
  cases explicitly. Force both crop-circle outcomes and assert exactly one
  `SUBST` appears between `COLOUR` and `KMASK`.
- [ ] Run `go test ./internal/script -run TestLuaRules -p 1`; confirm failure
  on missing methods or divergent behavior.
- [ ] Port all 36 modules. Keep functions flat and named, and make each
  method's source-specific roll order visible in a comment. Enable eager
  hook validation at catalog load, so a missing or misspelled method fails
  before play.
- [ ] Run the same Lua test and the importer `-check`; confirm both pass.

### Task 5: Select and place every arrival vault in D:1

**Files:** Create `internal/modfs/builtin/policy/generation/vaults/operations.lua`,
`transforms.lua`, `selection.lua`, `placement.lua`, `connect.lua`, and
`internal/script/testdata/lua/tests/arrival_placement_test.lua`. Modify
`internal/modfs/builtin/policy/generation/generated.lua`, `basic.lua`,
`content/terrain_features.lua`, `policy/save/generated_levels.lua`, and
`internal/terrain/feature.go`.

**Interfaces:** `selection.choose(ctx, definitions) -> vault` considers only
source-tagged arrivals in source order and uses source weights.
`placement.place(ctx, builder, vault) -> {entry, exits, records, bounds}`
applies ordered operations, orientation, keyed glyphs, helper vaults, and
typed placement intent. `connect.finish(ctx, builder, placement)` joins
exits to ordinary Dungeon rooms and stair links. `generated.generate(ctx)`
uses that route for D:1 and retains the D:2 basic layout.

- [ ] Add `arrival_placement_test.lua` for weighted selection, both helper
  references, each
  transform/directive family, glyph meaning, bounded fitting retries,
  connectivity, duplicate or missing exits, and clear diagnostic errors.
  Drive every one of the 337 tagged arrivals through placement twice under
  the same deterministic seed; assert identical results, 80×70 bounds,
  traversable entry/exit links, and path/ID/operation on failure.
- [ ] Run `go test ./internal/script -run TestLuaRules -p 1`; confirm failure.
- [ ] Implement selection and placement in focused Lua modules. Expand the
  terrain vocabulary only for pinned source features and preserve colour,
  tile, marker, item, monster, and pending effect identities as records.
- [ ] Integrate D:1 vault-first construction and adjust generated-level
  save validation for variable source stairs while retaining reciprocal
  D:1↔D:2 links and the current D:3 boundary.
- [ ] Run the Lua test and `go test ./internal/game -run 'Generation|Stair|Save'
  -p 1`; confirm pass.

### Task 6: Own placements on the level and preserve them in saves

**Files:** Modify `internal/game/level.go`, `internal/game/generation_script.go`,
`internal/game/save.go`,
`internal/game/save_restore_levels.go`, `internal/save/snapshot.go`, and
the relevant `internal/game/*_test.go` and `internal/save/codec_test.go`.

**Interfaces:** `Level` owns a typed `[]VaultRecord` copied on reads and
validated on writes. These records hold pending effects and persistent
terrain or marker annotations; live items and monsters live in ECS and are
saved with other entities, so restore does not spawn them twice. Each
`VaultRecord` has a kind enum, source ID, position, `[]VaultArgument`, and
optional activation hook. A
`VaultArgument` has name, value-kind enum, and one bool, int64, or string
value; validation rejects a mismatched value kind. `save.LevelRecord`
contains optional vault identity and records without changing save version
18. Current item/monster spawners create Akara entities when the source
identity is supported; otherwise a pending record retains the exact
identity and its unavailable interaction.

- [ ] Add `TestVaultRecordSaveRestore` and `TestVaultRecordValidation` for
  valid and invalid annotation coordinates/kinds,
  entity materialization where supported, explicit pending interactions,
  deterministic vault identity, save/restore equality, old records without
  vault fields, and rejection of corrupted records. Assert pending symbols
  reach the client view. Include a game-level smoke test with a forced
  simple vault and one complex scripted vault.
- [ ] Run `go test ./internal/game ./internal/save -p 1`; confirm failure.
- [ ] Decode Lua placement records into the level owner, materialize current
  ECS objects, save and restore typed records, and project their symbols to
  the client. Leave unsupported effects present for future domain slices.
- [ ] Run the same focused tests; confirm pass.

## Category boundary

- [ ] Run the pinned importer `-check` and verify 339 committed definitions,
  337 candidates, 36 handlers, one raw map-shaping block, and one ported veto.
- [ ] Run `go test ./... -p 1`, `go vet ./...`, `go build ./...`, and
  `sh scripts/check-go-style.sh`; resolve failures in this category.
- [ ] Review the diff for unported inline source Lua, dropped directives,
  overlong handwritten lines, and accidental changes outside this slice.
- [ ] Commit the complete arrival-vault category once, then use the
  superpowers branch-finishing workflow for integration.
