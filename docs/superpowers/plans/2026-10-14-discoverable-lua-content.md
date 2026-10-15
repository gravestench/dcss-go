# Discoverable Lua Content Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan category by category. Preserve the user's requested
> broad commits: one contiguous category per commit, then batch verification.

**Goal:** Add or replace any content definition by placing one Lua file in a
documented directory of the effective mod tree.

**Architecture:** The existing VFS merges embedded and user files by relative
path. One generic registration API stores immutable Lua definitions with
their origin; sorted `content/` discovery loads the effective files. Lua
catalog policy and ID modules read that registry. Checked-in import tools
write the per-definition base files only during deliberate refreshes.

**Tech Stack:** Go, Akara, gopher-lua, embedded Lua, Python import tools.

**Spec:** `docs/superpowers/specs/2026-10-14-discoverable-lua-content-design.md`

## Global Constraints

- No inline Lua source in Go.
- Runtime content and behavior are Lua authoritative.
- Provenance belongs in Lua comments, not declaration fields.
- Lua modules use local tables, named methods, registration, and a return.
- Shared IDs and constants are imported where used.
- Handwritten lines are at most 120 characters, with 80 preferred.
- New rule tests live in `_test.lua` and import production schemas/modules.
- Importers never run during a normal build or game launch.

## Review Focus

- A one-file added mod definition appears in gameplay and UI; test in Task 3.
- A same-path override changes the effective definition once; test in Task 3.
- A duplicate ID at two paths fails with both origins; test in Task 1.
- Cross-reference errors name the broken field and file; test in Task 2.
- A changed mod file changes the ruleset hash and blocks incompatible save;
  test in Task 4.

---

### Task 1: One generic registration contract

**Files:** `internal/script/runtime.go`, `internal/script/register.go`,
`internal/script/definitions.go`, `internal/script/character_catalog_test.go`,
`internal/script/testdata/`,
`internal/modfs/builtin/content/{species,jobs}/*.lua`.

**Interfaces:** `register.definition(category, table)` stores a copied Lua
definition; `register.get`, `register.ids`, and `register.origin` work for
every category. Unknown categories are created on first registration.

- [ ] Add Lua fixture files for registration and duplicate IDs. In the Go
  host test, assert boot accepts the first, rejects the duplicate with both
  paths, and accepts an effective same-path replacement. Registration is a
  host/VFS contract, so this is the narrow Go test exception.
- [ ] Generalize the host registry and convert species/jobs to the generic
  call in one generated content refresh. Remove category-specific host calls.
- [ ] Verify `go test ./internal/script ./internal/modfs -count=1`.
- [ ] Commit the registry category after its focused tests pass.

### Task 2: Per-file committed content catalogs

**Files:** `scripts/export-catalog-lua.py`,
`internal/modfs/builtin/content/{monsters,spells,items,branches,monster_spellbooks}/*.lua`,
`internal/modfs/builtin/content/validation.lua`,
`internal/modfs/builtin/policy/catalog.lua`, `internal/modfs/builtin/ids/*.lua`,
and policies still reading `data.{monsters,spells,items,branches,monster_spellbooks}`.

**Interfaces:** one generated file returns a local definition table and calls
`register.definition(category, definition)`. `catalog.get(category,id)` reads
the registry and rejects inactive IDs. `ids.<category>` derives references
from `register.ids(category)`.

- [ ] Add `_test.lua` assertions that one representative record from each
  category has the same playable fields as its pinned import.
- [ ] Teach the exporter to write committed per-record files with adjacent
  provenance comments and remove the runtime aggregate for converted
  categories. Generate all records in one category-wide pass.
- [ ] Replace direct aggregate readers with registry iteration; validate
  references after all files load. Keep generated JSON only for import tests.
- [ ] Verify exporter `--check`, Lua rule tests, and relevant game suites.
- [ ] Commit each complete catalog category as one contiguous change.

### Task 3: One-file mod authoring

**Files:** `internal/script/testdata/lua`, `internal/modfs/testdata`,
`internal/script/lua_rules_test.go`, `docs/modding.md`.

**Interfaces:** the user mod root mirrors `content/<category>/`, `schemas/`,
`systems/`, and `policy/`. New paths append; matching paths replace.

- [ ] Create fixture mods with one new monster, spell, item type, and unique
  item, each using the production registration API and a local returned table.
- [ ] Test discovery, Lua catalog reads, named ID imports, duplicate errors,
  same-path replacement, and origin reporting.
- [ ] Document the directory contract and provide one concise example per
  content kind without copying production schemas into test fixtures.
- [ ] Verify modfs, script, game, and terminal integration for the fixture.
- [ ] Commit the authoring category once its end-to-end checks pass.

### Task 4: Ruleset and save identity

**Files:** `internal/modfs/ruleset.go`, `internal/game/save.go`,
`internal/game/save_test.go`, `docs/modding.md`.

**Interfaces:** the existing effective path-and-byte hash identifies the
discovered set, including new files and same-path replacements. No catalog
version field duplicates this identity.

- [ ] Add a host/VFS test where a one-file mod changes the hash and a copy of
  unchanged bundled bytes preserves vanilla identity.
- [ ] Add a restore test proving changed effective content is rejected before
  ECS state loads; unchanged content restores normally.
- [ ] Remove any remaining runtime JSON catalog dependency rather than
  maintaining a second definition path.
- [ ] Run full Go tests with sufficient timeout, Lua tests, vet, build,
  importer checks, diff check, terminal smoke, and whole-category review.
- [ ] Commit the save/identity category, then merge the verified branch into
  local `main` after the current magic slice is coherent.
