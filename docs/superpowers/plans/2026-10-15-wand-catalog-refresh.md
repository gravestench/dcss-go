# Wand spell link refresh implementation plan

> **For agentic workers:** Use superpowers:executing-plans. The user wants
> one commit for the complete wand catalog refresh category.

**Goal:** The deliberate content exporter reproduces all 11 committed
wand-to-spell links from source-traced, checked-in import data.

**Architecture:** A developer-only importer reads the pinned `spl-book.cc`
wand table into a committed JSON artifact. The existing Lua catalog exporter
joins that artifact with committed item definitions and emits each wand's
spell link in its item file using `ids.spells`. Normal game launch reads only
the embedded Lua definitions.

**Tech stack:** Python 3 importer/exporter, committed JSON, embedded Lua,
Go 1.25 integration tests.

**Spec:** `docs/superpowers/specs/2026-10-13-complete-item-catalog-design.md`
and `docs/superpowers/specs/2026-10-14-discoverable-lua-content-design.md`.

## Constraints and review focus

- Pinned DCSS revision: `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- All 11 active wand types get exactly one valid spell link; no Go runtime
  wand-ID switch or build dependency on the C++ checkout is added.
- The importer rejects duplicate or unknown wand/spell IDs and an unfamiliar
  source table form instead of silently dropping a row.
- `export-catalog-lua.py --check` passes without changing committed files.
- Source path, line, revision, and hash are comments or offline import data,
  not runtime definition fields.
- Preserve `dcrawl-save.json`; commit this whole category once.

## Tasks

### 1. Import the complete source table

**Files:** `scripts/import_wand_spells.py`,
`scripts/test_import_wand_spells.py`,
`internal/content/generated/wand-spells.json`.

- [x] Test parsing the pinned table shape, duplicate and unknown IDs, and a
  missing table. Confirm the parser tests fail before the importer exists.
- [x] Implement a deliberate `--source`, `--out`, `--check` importer that
  records the source hash and exact row lines. Validate the 11 source wand
  IDs against committed item/spell artifacts.
- [x] Generate `wand-spells.json`; run importer `--check`.

### 2. Make the Lua exporter reproduce the runtime files

**Files:** `scripts/export-catalog-lua.py`,
`scripts/test_export_catalog_lua.py`, and the 11 files under
`internal/modfs/builtin/content/items/` with `wand_spell_id`.

- [x] Test that every imported link enters the matching wand definition,
  that a missing or extra link fails, and that the output uses `ids.spells`
  with source provenance in comments.
- [x] Join the committed mapping into item definitions during export.
  Keep ordinary item definitions unchanged; do not create a runtime aggregate.
- [x] Regenerate item files and run `export-catalog-lua.py --check`.

### 3. Verify and commit

**Files:** `docs/port-inventory.md`, `docs/modding.md` if wording changes.

- [x] Run focused importer/exporter tests, `go test` for content, modfs, and
  script wand coverage, `go vet ./...`, `go build ./...`, Go style, and diff
  checks. Runtime gameplay code is unchanged, so use those focused tests for
  this data-generation category.
- [ ] Commit once; fast-forward local Go `main`; return to the continuing
  feature branch.
