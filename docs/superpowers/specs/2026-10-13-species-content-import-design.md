# DCrawl Go: source-traced species content import

Date: 2026-10-13

## Purpose and scope

The first Dungeon slice proved the Go runtime with a hand-written Human/Fighter fixture. The next slice establishes the content import pattern needed for a faithful DCSS port. It imports the complete species definition set that the pinned C++ source compiles for `TAG_MAJOR_VERSION=34`, stores a deterministic artifact in the Go repository, and exposes those definitions through the existing immutable `content.Catalog`. This is a content slice, not character creation: the playable scenario remains Human/Fighter until job and character rules have their own slice.

The program goal remains faithful gameplay and content with Akara for dynamic entities, dense terrain grids, explicit state owners, and Bubble Tea/Lip Gloss for the ASCII client. The Go repository is `/Users/dylanknuth/src/dcrawl-go`; the paused C++ refactor is untouched.

## Source of truth

- DCSS reference: `/Users/dylanknuth/src/crawl` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, with 40 species YAML records in `crawl-ref/source/dat/species/*.yaml`, three legacy definitions in `crawl-ref/source/util/species-gen/species-data-deprecated-species.txt` and their aptitudes in `aptitudes-deprecated-species.txt`, and generated comparison data in `crawl-ref/source/species-type.h` and `species-data.h`.
- The source tree's `crawl-ref/source/tag-version.h` defines `TAG_MAJOR_VERSION=34`. All 43 concrete species definitions compile at this tag. YAML records whose `difficulty` is `False`, and the three legacy template records, are not selectable at character creation; the artifact must retain them with `Selectable=false`.
- The existing source generator, `crawl-ref/source/util/species-gen.py`, defines default aptitude values, the distinct meaning of a YAML `False` aptitude (`UNUSABLE_SKILL`), accepted skill names, difficulty groups, and other input rules. The Go importer must preserve these semantics rather than treating `False` as integer zero.
- Imported content retains source revision and per-record relative source path. The Go project carries upstream copyright/license information for imported definitions.

A future source update is a separate reviewed change. This slice's generator rejects a checkout at any other Git revision or tag major version instead of silently mixing data from two references.

## Approaches considered

1. **Checked-in artifact from category-specific build-time importers (selected).** A small importer reads the pinned source and writes deterministic data consumed by Go. Normal game builds need no C++ checkout. Each later content category gets its own importer and validation.
2. **Hand-transcribed catalogs.** Simple for a few fixtures, but cannot give reliable coverage or source trace for the full game.
3. **Runtime parsing of C++ or Lua data.** Keeps source nearby, but couples every run to the old repository and pushes format errors into gameplay. This also blurs the boundary between immutable content and mutable game state.

## Import flow and ownership

`cmd/importspecies` is a developer tool with explicit `-source` and `-out` paths and a `-check` mode. The source path points at `crawl-ref/source`; the command reads its enclosing Git revision, `tag-version.h`, every species YAML file, the three-record legacy species and aptitude templates, and only the enum headers needed to validate referenced IDs. It never writes to the source checkout. It writes `internal/content/generated/species.json` atomically, with stable record ordering and no timestamp. In `-check` mode it regenerates bytes in memory and exits nonzero if the checked-in artifact differs.

The importer lives in `internal/content/speciesimport`, separate from runtime catalog code. It uses strict YAML decoding into typed source records and a narrow parser for the three fixed-format legacy template records. It accepts exactly the fields used by the pinned species YAML schema, including nested mutation levels, fake mutation text, optional flags, recommended jobs and weapons, and skill aptitudes. Unknown fields, duplicate YAML keys, malformed types, duplicate species IDs, and invalid ranges are errors that name the file and field. The importer supports only the `TAG_MAJOR_VERSION` conditional forms present in the pinned enum and legacy headers; an unfamiliar preprocessor expression is an error, not a guessed interpretation.

References are checked against active IDs in the pinned `species-type.h`, `monster-type.h`, and `job-type.h`; recommended skill and flag names are checked against the source generator's documented sets. The set of 40 YAML IDs plus three legacy IDs must equal the concrete, active species entries in `species-type.h`, excluding enum aliases and sentinels. This catches missing files and accidental inclusion of a different tag branch. The importer is deliberately category-specific; it is not a general C++ parser or a generic content schema framework.

The artifact has a schema version, source revision, tag major version, sorted source-file hashes, and sorted species records. A species record keeps its stable `SP_*` ID, associated `MONS_*` ID, names, selection metadata, stats, aptitudes, mutations, flags, habitat/size/undead information, recommendations, and optional text/actions. Aptitudes represent `allowed` and numeric value separately so unusable skills cannot become zero aptitude. Missing ordinary skill aptitudes take the source generator's zero default.

`content.LoadDefault() (Catalog, error)` loads the checked-in artifact, validates its metadata and relationships, and returns a catalog that owns its map privately. It replaces the infallible `DefaultFixture()` call sites so malformed embedded content has a normal startup error rather than a panic or hidden invalid state. `Catalog.Species(id)` and any listing API return copies of nested maps and slices. No mutable package-level gameplay registry is introduced. The existing scenario continues to use `SP_HUMAN` and `JOB_FIGHTER`; its HP and damage remain controlled-scenario values until character rules replace them. The save format is unchanged because this slice adds immutable definitions, not new mutable character state.

## Errors, verification, and completion

The generator must report source mismatch, malformed YAML, unsupported source constructs, missing or duplicate IDs, and invalid references with actionable file/record context. Atomic output prevents a failed import from truncating the checked-in artifact. Runtime catalog loading must reject unsupported artifact schema or source revision before constructing a game.

Acceptance checks:

1. Running the importer twice against the pinned checkout yields identical bytes; `-check` succeeds, and a deliberately stale artifact fails without changing it.
2. All 40 pinned species YAML records and three legacy template records are represented once, including non-selectable and tag-34 records, with the same 43 concrete active IDs as `species-type.h`.
3. Golden checks cover Human defaults, Deep Elf aptitudes, Felid's unusable skills and mutations, and a tag-34 species. Negative fixtures cover an unknown field, duplicate ID, missing reference, malformed aptitude, and unsupported conditional.
4. `Catalog.Species` returns deep copies; changing a returned record cannot change later reads or the playable scenario.
5. `go test ./...`, `go vet ./...`, and the existing seeded save/restore continuation tests pass. The terminal Dungeon scenario still starts and plays with no source checkout at runtime.
6. `docs/port-inventory.md` distinguishes imported species definitions from unported species gameplay, character creation, skills, mutations, jobs, and progression. No broad category is called complete merely because its data was imported.

## Next slices

Jobs and character creation follow this import foundation, then character advancement and combat; items and spells; monster behavior and content; visibility and world generation; religion, mutations and forms; branches, vaults and progression; and parity closure. Each slice gets its own source-backed spec, plan, implementation commits, integrated tests, and fresh review. Full-port completion requires every gameplay/content inventory entry to be implemented and checked or explicitly accepted as an intentional difference.
