# Monster Content Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the rat-only fixture with a complete, committed, source-traced tag-34 monster catalog while keeping the fixed Dungeon scenario playable.

**Architecture:** A developer-only importer scans the pinned C++ enum and table, resolves the supported source expressions into typed Go values, and writes a deterministic artifact. `content.Catalog` embeds and owns that immutable artifact; Akara continues to own live monster state. The scenario keeps its 4 HP and simple melee fixture explicitly until combat and HP rules are ported.

**Tech Stack:** Go 1.25, standard-library JSON/embed/Git execution, the existing narrow source parser, Akara ECS, current version-4 Go save codec. No new runtime dependency.

**Spec:** `docs/superpowers/specs/2026-10-13-monster-content-import-design.md`

## Global Constraints

- Source revision: `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`; `TAG_MAJOR_VERSION=34`.
- Cover exactly 700 active non-alias monster IDs: 562 `defined`, 120 `removed`, 18 `enum_only`. Exclude aliases and sentinels.
- Preserve every `monsterentry` field, including four attacks, eight energy values, tile symbols, source status, and provenance. No opaque C++ expressions in runtime data.
- Generated content is committed. Normal build, test, CI, and play never call importers or require the C++ checkout.
- Preserve the existing fixed rat scenario's 4 HP and simple 3-damage model and save version 4; keep those fixture values out of immutable content.
- Never edit the paused C++ refactor or the untracked `dcrawl-save.json` in the Go checkout.

## File Map

- `internal/content/monster.go`, `monster_test.go`, `catalog.go`: typed record/artifact, validation, private map, copy-safe lookup/list/status APIs.
- `internal/content/sourceparse/tag34.go`, `tag34_test.go`: numbered active lines without changing existing `Tag34Lines` behavior.
- `internal/content/monsterimport/scan.go`, `scan_test.go`: balanced table-row and `AXED_MON` scanner with source locations.
- `internal/content/monsterimport/decode.go`, `decode_test.go`: field decoder, restricted symbol and expression resolution, attack/resistance/energy values.
- `internal/content/monsterimport/import.go`, `import_test.go`, `cmd/importmonsters/main.go`: revision/tag/hash/ID validation, deterministic JSON, atomic write, explicit CLI.
- `internal/content/generated/monsters.json`, `internal/content/default.go`, `default_test.go`, `fixture.go`: committed artifact and combined runtime load, replacing rat fixture data.
- `internal/game/scenario.go`, `view.go`, `save.go` and tests: canonical rat presentation/speed, explicit scenario HP/damage, restore validation.
- `docs/port-inventory.md`: imported definitions and still-unported gameplay.

## Review Focus

1. A quoted `//` or comma in a synthetic monster name must stay inside that string; the scanner must not truncate it as a comment (Task 2).
2. A multiline `mrd(MR_RES_FIRE | MR_RES_COLD, 3)` plus vulnerability must resolve without splitting the row or losing a level (Tasks 2–3).
3. `MONS_0`, `MONS_NO_MONSTER`, `RANDOM_*`, and inactive `> 34` IDs must never count toward the 700-record partition (Task 4).
4. A removed `AXED_MON` record and an enum-only genus must remain inspectable but cannot validate a live saved monster (Tasks 4–5).
5. A failed refresh or stale `-check` must leave existing artifact bytes untouched; a Go-only checkout must still build and play (Tasks 4–6).

---

### Task 1: Define the typed monster artifact and catalog contract

**Files:** Create `internal/content/monster.go`, `monster_test.go`; modify `internal/content/catalog.go`, `fixture.go`, `catalog_test.go`, `default_test.go`, `internal/game/scenario.go`, and its rat scenario tests.

**Interfaces:** `MonsterStatus string` constants `MonsterDefined`, `MonsterRemoved`, `MonsterEnumOnly`; `MonsterAttack{TypeID, FlavourID string; Damage int}`; `MonsterResistance{ID string; Level int}`; `MonsterEnergy{Move, Swim, Attack, Missile, Spell, Special, Item, PickupPercent int}`; `MonsterTile{ID, VariationID string}`. `MonsterDef` has `ID, Status, SourcePath, Name, ColourID, GenusID, SpeciesID, SpellbookID, ShoutID, IntelligenceID, HabitatID, ItemUseID, SizeID, ShapeID, CorpseTileID string`, `SourceLine, XPModifier, Willpower, HD, AverageHP10x, AC, EV, Speed int`, `Glyph rune`, `Flags, Holiness []string`, `Resistances []MonsterResistance`, `Attacks [4]MonsterAttack`, `Energy MonsterEnergy`, `Tile MonsterTile`, and `LeavesCorpse bool`. `MonsterArtifact{SchemaVersion, TagMajorVersion int; SourceRevision string; SourceFiles []JobSourceFile; Monsters []MonsterDef}`. `Catalog.Monster(id string) (MonsterDef,error)`, `Catalog.MonsterStatus(id string) (MonsterStatus,error)`, `Catalog.MonsterIDs() []string`; private `monsters map[string]MonsterDef` owns all statuses.

- [ ] **Step 1: Write failing tests** `TestMonsterArtifactValidation` (duplicate, unsorted, bad status, malformed defined attack, removed/enum-only carrying live fields) and `TestMonsterCatalogCopies` (mutate returned flags/holiness/resistances and ID listing; later reads unchanged). Assert unknown/removed/enum-only `Monster` errors but known status remains readable; the fixed rat still starts at 4 HP and 3 base damage.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content -run 'TestMonster'`; expect missing types or failed assertions.
- [ ] **Step 3: Implement** the named types and `MonsterArtifact.Validate() error`, `MonsterDef.validate() error`, `MonsterDef.clone() MonsterDef`, and catalog accessors. Represent the in-memory rat with the new source fields until Task 5 replaces the fixture; move HP 4 into the scenario and take simple damage 3 from its checked first `AT_BITE/AF_PLAIN` attack. Remove `BaseDamage` and `ScenarioHP` from monster content immediately.
- [ ] **Step 4: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content ./internal/game` and `gofmt` changed Go files; expect pass.
- [ ] **Step 5: Commit** as `feat: define immutable monster catalog values`.

### Task 2: Scan pinned table rows without losing source structure

**Files:** Modify `internal/content/sourceparse/tag34.go`, `tag34_test.go`; create `internal/content/monsterimport/scan.go`, `scan_test.go`.

**Interfaces:** `sourceparse.Tag34NumberedLines(path string, data []byte) ([]sourceparse.Line,error)` with `Line{Number int; Text string}`; existing `Tag34Lines` remains stable. Private `monsterimport.sourceRow{ID string; Line int; Fields []string; Removed bool; RemovedName string}` and `parseRows(path string, data []byte) ([]sourceRow,error)` return 562 explicit plus 120 removed rows for the pinned file.

- [ ] **Step 1: Write failing tests** for 28 top-level `monsterentry` fields, nested attack/tile braces, multiline parentheses and `mrd`, escaped quotes/commas/`//` in strings, trailing comments, `AT_NO_ATK`, `AXED_MON`, and source line numbers; reject unbalanced braces, truncated strings, unsupported conditionals/macros, and wrong field count with path/line/ID context.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/sourceparse ./internal/content/monsterimport`; expect failure.
- [ ] **Step 3: Implement** a lexical scan from `static monsterentry mondata[]`, tracking quote/comment/escape and brace/parenthesis depth; expand only the pinned `AXED_MON` definition and calls, and reject unconsumed tokens. Preserve original line numbers through tag filtering.
- [ ] **Step 4: Run** focused parser tests and existing species/job/gear importer tests; expect pass; format files.
- [ ] **Step 5: Commit** as `feat: scan pinned monster table rows`.

### Task 3: Decode source fields into complete typed definitions

**Files:** Create `internal/content/monsterimport/decode.go`, `decode_test.go`; adjust `scan.go` only where the grammar requires it.

**Interfaces:** Private `decodeRows(path string, rows []sourceRow, symbols symbolSets) ([]content.MonsterDef,error)`, with `symbolSets` maps for monster, attack type, attack flavour, spellbook, class flag, resistance, holiness, shout, intelligence, habitat, item use, size, shape, colour, and tile variation IDs; separate helpers decode flags, resistance terms, four attacks, tile info, and eight energy costs. These helpers accept only the pinned source operators/macros and return typed values or contextual errors.

- [ ] **Step 1: Write failing tests** for rat (`r`, speed 10, attack bite/plain/3, three no-attacks, average HP 25), orc wizard (`MST_ORC_WIZARD`), fire dragon (fire resistance level 2, cold vulnerability, three attacks), demonspawn (`MH_NATURAL` and `MH_DEMONIC`), spriggan (move energy 6, all other action costs 10, pickup 100), and `MONS_PROGRAM_BUG` (valid zero speed/HP). Assert unknown flag, enum, macro, arithmetic, and extra/missing field errors.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/monsterimport -run 'TestDecode'`; expect failure.
- [ ] **Step 3: Implement** exact field positions from `mon-util.h`, `mon-enum.h`'s `mrd` bit-level semantics, `mon-flags.h` base flags, `mon-data.h` flag aliases and energy macros, and default tile variation. Retain symbolic IDs for enums/tiles, numeric values for stats/energy/resistance levels, and reject unresolved expressions rather than preserving raw C++ strings.
- [ ] **Step 4: Run** focused tests; expect pass; format files.
- [ ] **Step 5: Commit** as `feat: decode complete monster definitions`.

### Task 4: Generate and commit the complete source-traced artifact

**Files:** Create `internal/content/monsterimport/import.go`, `import_test.go`, `cmd/importmonsters/main.go`, `internal/content/generated/monsters.json`.

**Interfaces:** `monsterimport.Generate(sourceDir string) ([]byte,error)` checks pinned Git revision, clean tracked source, and tag; private `generateFromSource(sourceDir, revision string) ([]byte,error)` supports fixtures; `monsterimport.Write(sourceDir, outPath string, check bool) error` compares or atomically replaces. CLI: `go run ./cmd/importmonsters -source /Users/dylanknuth/src/crawl/crawl-ref/source -out internal/content/generated/monsters.json [-check]`.

- [ ] **Step 1: Write failing tests** using temporary source fixtures for sorted deterministic records/file hashes, a complete small defined/removed/enum-only partition, alias/sentinel/inactive exclusion, missing/extra/duplicate IDs, wrong revision/tag, unknown references, stale `-check`, and failed generation preserving output bytes. These tests never read the developer's C++ checkout; Task 5 checks the committed artifact's exact 700/562/120/18 counts.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/monsterimport -run 'TestGenerate|TestWrite'`; expect failure.
- [ ] **Step 3: Implement** source reads/hash collection and active symbol/reference checks using tracked `tag-version.h`, `monster-type.h`, `mon-data.h`, `mon-util.h`, `mon-enum.h`, `mon-flags.h`, `mon-holy-type.h`, `size-type.h`, `mon-mst.h`, and `defines.h` (terminal colours). Parse the named enum blocks in headers that contain several enums; exclude aliases/sentinels rather than treating every prefixed token as a definition. Enforce the pinned 700/562/120/18 counts in `Generate` and runtime loading; allow the private fixture helper to validate smaller complete ID sets. Use stable JSON with final newline and temp-file-plus-rename; generate the committed artifact. Tile IDs stay validated symbolic forms because tile build headers are generated outside the pinned tracked source.
- [ ] **Step 4: Run** importer twice to temporary outputs and `cmp` them; run CLI `-check` against the committed path; inspect exact partition, source hashes, rat/caster/resistance/energy golden values; run importer tests.
- [ ] **Step 5: Commit** as `feat: import complete pinned monster catalog`.

### Task 5: Load the artifact and keep the Dungeon slice playable

**Files:** Modify `internal/content/default.go`, `default_test.go`, `catalog_test.go`, `fixture.go`, `catalog.go`, `internal/game/scenario.go`, `view.go`, `save.go`, and focused game tests.

**Interfaces:** `content.LoadDefault() (Catalog,error)` keeps its signature and embeds `generated/monsters.json`; private `loadDefault` gains `monsterData []byte`. `Catalog.Monster` returns only `defined` records. `NewScenario` maps the rat's first `AT_BITE/AF_PLAIN/3` attack to the temporary 3-damage combat component and keeps scenario HP 4; save version stays 4.

- [ ] **Step 1: Write failing tests** for full default catalog and exact 700/562/120/18 counts, deep copies, bad schema/revision/tag/provenance/order/duplicate/genus/species-reference rejection, rat source fields, fixed scenario HP/damage/view, and seeded save/restore. Mutate a saved actor type to `MONS_BUMBLEBEE` and `MONS_BEAR`; restore must reject both without replacing the live game.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content ./internal/game -run 'TestMonster|TestRat|TestSave|TestRestore|TestLoadDefault'`; expect failure.
- [ ] **Step 3: Embed/decode** the artifact, check revision/tag and shared-file hashes, build the private catalog map, remove rat content fixture fields and old positive-speed/name assumptions, update view/scenario/save callers, and retain explicit scenario constants. Update private `loadDefault` test call sites.
- [ ] **Step 4: Run** focused content/game/save tests; expect pass; format files.
- [ ] **Step 5: Commit** as `feat: use committed monsters in the Dungeon scenario`.

### Task 6: Verify integration and record domain status

**Files:** Modify `docs/port-inventory.md` and only code/tests needed for observed integration failures.

**Interfaces:** No new product API. Imported definitions do not imply ported behavior or generation.

- [ ] **Step 1: Update** the inventory with 700 accounted-for IDs, 562 explicit definitions, 120 removed IDs, 18 enum-only IDs, the committed importer policy, and separate unported monster combat/AI/spawning/loot/XP domains.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./...`, `GOCACHE=/tmp/dcrawl-go-cache go vet ./...`, and `GOCACHE=/tmp/dcrawl-go-cache go build ./cmd/dcrawl`; fix any concrete failures and rerun failed checks.
- [ ] **Step 3: Run** `go run ./cmd/importmonsters ... -check`; compare two generated outputs byte-for-byte, and build/test a temporary Go-only copy without the C++ checkout. Exercise startup, rat rendering/combat, save, and restore in the terminal.
- [ ] **Step 4: Review** diff against every spec acceptance check, run `git diff --check`, confirm the existing `LICENSE` and source-revision provenance cover the imported material, and confirm `dcrawl-save.json` and C++ work remain untouched.
- [ ] **Step 5: Commit** inventory/integration changes as `docs: record imported monster content` (or `fix:` for a substantive correction), then request a whole-branch code review before integration.
