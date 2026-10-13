# Species Content Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Import every species compiled by the pinned DCSS tag-34 source into a deterministic Go catalog while preserving the current Human/Fighter scenario.

**Architecture:** A build-time, species-specific importer reads strict YAML and the three legacy template definitions, validates them against the active C++ enum IDs, and writes a checked-in JSON artifact. The runtime embeds that artifact and exposes defensive copies through `content.Catalog`; normal builds and games never read the C++ checkout.

**Tech Stack:** Go 1.25, `gopkg.in/yaml.v3`, `encoding/json`, `embed`, standard-library crypto and Git command execution. Existing Akara, Bubble Tea, and save packages remain in place.

**Spec:** `docs/superpowers/specs/2026-10-13-species-content-import-design.md`

## Global Constraints

- Source revision is exactly `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`; `TAG_MAJOR_VERSION` is exactly `34`.
- Import 40 `crawl-ref/source/dat/species/*.yaml` records and three tag-34 legacy definitions, yielding exactly the 43 concrete IDs in `species-type.h`.
- Keep non-selectable species, including `difficulty: False` and all three legacy definitions, with `Selectable=false`.
- Preserve YAML `False` skill aptitude as unusable, distinct from numeric zero; omitted ordinary skills default to allowed aptitude zero.
- Keep the existing scenario's Human/Fighter IDs, controlled HP/damage, and save format unchanged.
- Import errors include source file and record/field context; never partially replace the artifact.
- A normal game run needs only the checked-in artifact, never the C++ source tree.

## File Map

- `internal/content/species.go`: immutable species value types, artifact schema, catalog accessors, cloning, and validation.
- `internal/content/species_test.go`: artifact validation and defensive-copy tests using in-memory records.
- `internal/content/speciesimport/yaml.go`: strict YAML decoding, source defaults, skill normalization, and detailed field errors.
- `internal/content/speciesimport/legacy.go`: narrow parser for the three tag-34 brace-initializer species and aptitude rows.
- `internal/content/speciesimport/enums.go`: limited tag-34 preprocessor and active species, monster, and job enum extraction.
- `internal/content/speciesimport/import.go`: source/revision checks, cross-reference validation, provenance hashes, sorted artifact encoding, and atomic output.
- `internal/content/speciesimport/*_test.go`: parser, enum, determinism, and failure fixtures independent of the C++ checkout.
- `cmd/importspecies/main.go`: `-source`, `-out`, and `-check` command with useful stderr errors.
- `internal/content/generated/species.json`: checked-in generated artifact.
- `internal/content/default.go`: embed, load, and validate the generated artifact; add the existing fixture's monster/item/player data.
- `internal/content/catalog.go`, `internal/content/fixture.go`: add species ownership; move the old fixture data behind `LoadDefault`.
- `cmd/dcrawl/main.go` and tests under `internal/{content,game,terminal}`: propagate `LoadDefault() (Catalog, error)`.
- `LICENSE` and `docs/port-inventory.md`: upstream license and precise imported-versus-unported status.

## Review Focus

1. YAML boolean `False` versus integer `0` in skill aptitudes: test that Felid's weapon skill is unusable while Human's omitted skill is allowed at zero (Tasks 2 and 5).
2. A duplicate YAML mapping key hidden by ordinary struct decoding: test rejection with file and key in the error (Task 2).
3. `#else` inside a tag-34 enum that would select the wrong ID set: test both `== 34` and `> 34` branches and reject an unfamiliar directive (Task 3).
4. A stale output path in `-check` mode: test nonzero result and byte-for-byte unchanged output (Task 4).
5. A caller mutating nested returned maps or slices: test that later catalog reads and a new scenario retain the original values (Task 5).

---

### Task 1: Define species catalog values and invariants

**Files:** Create `internal/content/species.go`, `internal/content/species_test.go`; modify `internal/content/catalog.go`.

**Interfaces:** Produce `SpeciesDef`, `SpeciesAptitude`, `SpeciesMutation`, `SpeciesFakeMutation`, `SpeciesSourceFile`, and `SpeciesArtifact` in package `content`; `Catalog.Species(id string) (SpeciesDef, error)` and `Catalog.SpeciesIDs() []string`. `SpeciesArtifact` has `SchemaVersion`, `SourceRevision`, `TagMajorVersion`, sorted `SourceFiles`, and sorted `Species`; schema version is `1`.

- [ ] **Step 1: Write failing tests** `TestSpeciesCatalogDefensiveCopies`, `TestSpeciesCatalogRejectsDuplicateOrInvalidRecord`, and `TestSpeciesIDsSorted`. Construct a two-record catalog in the package test, mutate `Aptitudes`, `Mutations`, `Flags`, `LevelUpStats`, recommendations, and fake-mutation slices returned by `Species`, then assert a second read is unchanged. Assert unknown IDs error and IDs are sorted.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content -run 'TestSpecies'` and confirm failure from missing species interfaces.
- [ ] **Step 3: Implement** the named types and accessors in `species.go`. `SpeciesDef` must retain ID, monster ID, source path, names, selection/difficulty, `XP`/`HP`/`MPMod`/`MR`, starting stats, level-up rules, all ordinary skill aptitudes as a map keyed by canonical `SK_*`, mutations, fake text, flags, habitat, size, undead type, job/weapon recommendations, and optional verbs/actions. `SpeciesAptitude` is `{Allowed bool, Value int}`. Extend `Catalog.Validate()` to check record IDs, required fields, and that player species exists when species are loaded; catalog-owned maps are private.
- [ ] **Step 4: Run** the focused tests and confirm pass; run `gofmt` on changed Go files.
- [ ] **Step 5: Commit** these content-model files as `feat: define immutable species catalog values`.

### Task 2: Decode the pinned YAML schema strictly

**Files:** Create `internal/content/speciesimport/yaml.go`, `internal/content/speciesimport/yaml_test.go`; modify `go.mod`, `go.sum`.

**Interfaces:** Produce unexported `parseYAML(path string, data []byte) (content.SpeciesDef, int, error)`, where the integer is the optional source `TAG_MAJOR_VERSION` (zero means unconditional). Task 4 consumes it.

- [ ] **Step 1: Write failing tests** for Human defaults (`XP=1`, `MR=3`, omitted `SK_FIGHTING` allowed/zero), Deep Elf `SK_SPELLCASTING=3`, Felid `SK_SHORT_BLADES` unusable, nested Felid mutations, a tag-34-only record, and all optional fields. Table-test unknown field, duplicate key, non-integer aptitude, invalid stat/mutation ranges, invalid difficulty, invalid flag/skill, and inconsistent selectable jobs; each error must contain file and field. Use small YAML strings in tests; no test requires `/Users/dylanknuth/src/crawl`.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/speciesimport -run TestParseYAML` and confirm compile/test failure.
- [ ] **Step 3: Add** `gopkg.in/yaml.v3`; implement `parseYAML`. Inspect `yaml.Node` mappings for duplicate keys before `KnownFields(true)` decoding; use a dedicated aptitude scalar decoder to distinguish `False` from `0`. Apply generator defaults and ranges from `crawl-ref/source/util/species-gen.py`: ordinary skills zero, `HT_LAND`, `US_ALIVE`, `SIZE_MEDIUM`, default level-up stats `str/int/dex`, mutation level `1..27`, mutation amount `-3..3`, stats `1..100`, and frequency `0..28`. Map the source's `ranged weapons`, `maces_and_flails`, and `summoning` names to their canonical `SK_*` IDs. Keep source-relative path in each record.
- [ ] **Step 4: Run** focused tests and confirm pass; format files.
- [ ] **Step 5: Commit** as `feat: parse species YAML with source defaults`.

### Task 3: Parse legacy species and active source IDs

**Files:** Create `internal/content/speciesimport/legacy.go`, `legacy_test.go`, `enums.go`, `enums_test.go`.

**Interfaces:** Produce `parseLegacy(speciesPath string, speciesText []byte, aptitudePath string, aptitudeText []byte) ([]content.SpeciesDef, error)` and `activeEnumIDs(path string, data []byte, prefix string) (map[string]struct{}, error)`. Task 4 uses both. Parsers accept only the pinned tag-34 expression forms `== 34`, `> 34`, `#else`, `#endif`; unexpected syntax is an error.

- [ ] **Step 1: Write failing tests** for the three legacy IDs `SP_HIGH_ELF`, `SP_LAVA_ORC`, `SP_SLUDGE_ELF`, each with source path, correct monster/stat fields, `Selectable=false`, and preserved `UNUSABLE_SKILL` aptitude rows. Test malformed or duplicate legacy rows, missing aptitude records, and unsupported expressions. Test enum aliases/sentinels excluded (`SP_FIRST_NONBASE_DRACONIAN`, `NUM_SPECIES`, `SP_UNKNOWN`), active `== 34` members included, inactive `> 34` members excluded, and `#else` evaluated correctly.
- [ ] **Step 2: Run** focused legacy and enum tests; confirm failure.
- [ ] **Step 3: Implement** a small conditional-state scanner in `enums.go` and a parser limited to the exact legacy initializer and aptitude-row shapes in the pinned templates. Do not introduce a general C++ parser. Preserve any legacy aptitude keys still present in the template, including old `SK_*` names, and require exactly the three expected definitions.
- [ ] **Step 4: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/speciesimport` and confirm pass; format files.
- [ ] **Step 5: Commit** as `feat: parse tag-34 species IDs and legacy definitions`.

### Task 4: Validate sources and generate the checked-in artifact

**Files:** Create `internal/content/speciesimport/import.go`, `import_test.go`, `cmd/importspecies/main.go`, `internal/content/generated/species.json`; add `LICENSE` from the pinned upstream repository.

**Interfaces:** Produce `speciesimport.Generate(sourceDir string) ([]byte, error)`, `speciesimport.Write(sourceDir, outPath string, check bool) error`, and a CLI `go run ./cmd/importspecies -source <crawl-ref/source> -out <species.json> [-check]`. `Generate` checks enclosing Git HEAD against the pinned revision and `tag-version.h` against 34.

- [ ] **Step 1: Write failing tests** for a complete small synthetic source fixture that yields stable JSON with sorted species and sorted source-file SHA-256 hashes; duplicate IDs, missing active species, missing `MONS_*`/`JOB_*`, wrong tag, unsupported conditional, and unexpected Git revision fail with file/record context. Test `Write(..., true)` accepts current bytes and rejects stale bytes without changing them; test failed generation leaves existing output untouched. Use an injectable private reader/revision helper or a temporary local Git fixture so tests remain self-contained.
- [ ] **Step 2: Run** focused import tests; confirm failure.
- [ ] **Step 3: Implement** source-root and revision checks, YAML/legacy loading, active enum comparison, reference validation, provenance hashing, stable JSON encoding with a trailing newline, and temporary-file-plus-rename output in the target directory. The command prints errors to stderr and exits nonzero. Check in an artifact generated from the actual pinned source and copy upstream `LICENSE` into the Go repository.
- [ ] **Step 4: Run** the importer twice to separate temporary paths and compare with `cmp`; run `-check` against `internal/content/generated/species.json`; inspect artifact for exactly 43 unique IDs, 40 YAML paths, three legacy paths, and revision/tag/schema metadata. Run focused package/command tests and format files.
- [ ] **Step 5: Commit** as `feat: generate complete source-traced species artifact`.

### Task 5: Load species into the runtime catalog

**Files:** Create `internal/content/default.go`; modify `internal/content/catalog.go`, `internal/content/fixture.go`, `internal/content/catalog_test.go`, `internal/content/species_test.go`, `cmd/dcrawl/main.go`, and call sites in `internal/game/*_test.go` and `internal/terminal/model_test.go`.

**Interfaces:** Produce `content.LoadDefault() (Catalog, error)` and private `loadDefault(data []byte) (Catalog, error)` for malformed-artifact tests. Remove `DefaultFixture()` once all callers use the new result. Keep catalog version/source revision and existing monster/item/player fixture data.

- [ ] **Step 1: Write failing tests** that `LoadDefault` has 43 species, preserves source provenance, retains Human and Felid aptitude semantics and a tag-34 species, and returns independent nested values; after mutating a returned Human record, a newly created scenario must still use the original catalog values. Test `loadDefault` rejects wrong schema/revision/tag, duplicate species, missing player species, and malformed JSON without panicking. Keep the existing rat/item/scenario assertions.
- [ ] **Step 2: Run** content tests and confirm failure from missing loader.
- [ ] **Step 3: Embed** `generated/species.json`, validate artifact metadata and relationships, build a fresh catalog per call, and return errors. Update terminal startup and tests to handle the loader error explicitly. Remove the old fixture constructor after all call sites are migrated; do not alter scenario HP/damage or save encoding.
- [ ] **Step 4: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content ./internal/game ./internal/terminal ./cmd/dcrawl` and confirm pass; format files.
- [ ] **Step 5: Commit** as `feat: load imported species in immutable runtime catalog`.

### Task 6: Integrated verification and inventory

**Files:** Modify `docs/port-inventory.md` and any implementation/test files needed to correct observed integration failures.

**Interfaces:** No new production API. Deliver an accurate inventory entry: species definitions imported; species gameplay, character creation, skills, mutations, jobs, and progression still unported.

- [ ] **Step 1: Update** `docs/port-inventory.md` with the imported category, provenance, count, and explicit remaining gameplay gaps.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./...` and `GOCACHE=/tmp/dcrawl-go-cache go vet ./...`; fix any concrete failures and rerun the failing command.
- [ ] **Step 3: Run** `go run ./cmd/importspecies -source /Users/dylanknuth/src/crawl/crawl-ref/source -out internal/content/generated/species.json -check`; exercise the seeded save/restore continuation tests and a terminal startup without the C++ checkout available in the game process.
- [ ] **Step 4: Review** the diff against the spec: no unvalidated references, mutable globals, new save fields, or false inventory completion claim. Run `git diff --check`.
- [ ] **Step 5: Commit** documentation and integration fixes as `docs: record species data import status` (or a `fix:` commit if code corrections are substantial). Request one whole-branch review before integration.
