# Job Catalog and Character Choice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Commit all 31 pinned tag-34 job definitions, reproduce normal Dungeon species/job choice rules, and give the playable Human/Fighter source-derived base attributes.

**Architecture:** An optional developer importer writes a committed `jobs.json`; normal builds and tests embed that file alongside the committed species artifact and never read the C++ checkout. Pure `character` rules answer choice and base-stat questions; `game.NewScenario` stores the Human/Fighter result in ECS, shows it in the terminal, and saves it in Go save version 2.

**Tech Stack:** Go 1.25, standard-library JSON/embed/crypto/Git command execution, Akara ECS, Bubble Tea/Lip Gloss, existing Go save codec. No new runtime dependency.

**Spec:** `docs/superpowers/specs/2026-10-13-job-catalog-character-choice-design.md`

## Global Constraints

- Source revision is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`; `TAG_MAJOR_VERSION=34`.
- Exactly 31 concrete jobs: 25 starting jobs and the six retained removed jobs `JOB_DEATH_KNIGHT`, `JOB_HEALER`, `JOB_JESTER`, `JOB_PRIEST`, `JOB_SKALD`, `JOB_STALKER`.
- Normal Dungeon has 27 starting species, 25 starting jobs, 664 legal pairs, and 11 banned pairs. Sprint rules are not part of this slice.
- Species-first recommendations read species `RecommendedJobs`; job-first recommendations read job `RecommendedSpecies`. Recommendations never determine legality.
- Human/Fighter is legal, restricted in both directions, and has base attributes Strength 16, Intelligence 8, Dexterity 12.
- Wanderer is selectable but has randomized starting stats; `BaseStatSum` rejects it rather than interpreting its zero job modifiers as a full start.
- Every content importer is an optional developer tool. Commit its generated artifact; no normal Go build, test, CI, save, or game run invokes an importer or needs C++ source.
- Preserve fixed-scenario HP 20 and base damage 4; do not claim equipment, spells, weapon-dependent skills, mutations, HP/MP, or complete character creation are ported.
- Use no compatibility layer for version-1 saves; version 2 rejects them.

## File Map

- `internal/content/job.go`, `job_test.go`, `catalog.go`: job value schema, validation, private catalog map, sorted and defensive accessors.
- `internal/content/sourceparse/tag34.go`, `tag34_test.go`: extract the existing narrow tag-34 line/enum scanner from `speciesimport/enums.go`; keep species importer behavior unchanged.
- `internal/content/jobimport/parse.go`, `parse_test.go`: parse only the pinned `job-data.h` initializer grammar.
- `internal/content/jobimport/import.go`, `import_test.go`, `cmd/importjobs/main.go`: pinned-source checks, ID validation, deterministic artifact, atomic write, explicit CLI.
- `internal/content/generated/jobs.json`, `default.go`, `default_test.go`: committed job artifact and combined runtime load with committed species.
- `internal/character/choice.go`, `choice_test.go`, `stats.go`, `stats_test.go`: pure directional restrictions and additive base-stat rule.
- `internal/ecs/components.go`, `stores.go`; `internal/game/scenario.go`, `view.go`, `save.go`; `internal/save/snapshot.go`; `internal/terminal/render.go` and their tests: source-derived player attributes, display, version-2 persistence, restore validation.
- `docs/port-inventory.md`: precise shipped and remaining domain status, preserving the port-wide committed-content policy.

## Review Focus

1. Quoted commas and tags inside job equipment specs must remain one ordered string, not split into false fields (Task 2 parser test).
2. A `#if TAG_MAJOR_VERSION > 34` or `#else` branch must never leak jobs/spells from the wrong tag into the artifact (Task 2 source scanner and Task 3 import tests).
3. Human/Fighter is legal but absent from both recommendation lists, while the two list directions can disagree (Task 5 choice tests).
4. Wanderer's zero table modifiers must not produce a supposedly complete start (Task 5 base-stat test).
5. A corrupted save with attributes on a monster or with player attributes altered from the catalog must fail without replacing the live game (Task 6 restore tests).

---

### Task 1: Define immutable job catalog values

**Files:** Create `internal/content/job.go`, `job_test.go`; modify `internal/content/catalog.go`.

**Interfaces:** `JobSkillGrant{ID string, Level int}`, `JobSourceFile{Path, SHA256 string}`, `JobDef{ID, SourcePath, Abbreviation, Name string; Strength, Intelligence, Dexterity int; RecommendedSpecies, Spells, Equipment []string; WeaponChoice string; Skills []JobSkillGrant; Selectable bool}`, `JobArtifact{SchemaVersion int; SourceRevision string; TagMajorVersion int; SourceFiles []JobSourceFile; Jobs []JobDef}`. `Catalog.Job(id string) (JobDef,error)` and `Catalog.JobIDs() []string` return copies; private `Catalog.jobs map[string]JobDef` owns definitions.

- [ ] **Step 1: Write failing tests** `TestJobCatalogCopiesAndSorts` with two jobs: mutate every returned slice, then assert later `Job` reads and sorted `JobIDs` are unchanged; unknown ID errors. `TestJobArtifactRejectsInvalidRecord` rejects duplicate IDs/abbreviations, empty names, invalid `WCHOICE_*`, `Selectable` inconsistent with recommendations, and skill grants outside `0..27`.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content -run 'TestJob'`; confirm missing interfaces or failing assertions.
- [ ] **Step 3: Implement** the named values, `JobArtifact.Validate() error`, `JobDef.validate() error`, defensive `clone`, catalog accessors and optional job validation in `Catalog.Validate()` (fixture-only test catalogs may have no jobs until Task 4).
- [ ] **Step 4: Run** focused tests and `gofmt` changed Go files; confirm pass.
- [ ] **Step 5: Commit** as `feat: define immutable job catalog values`.

### Task 2: Parse pinned job initializers and share the tag scanner

**Files:** Create `internal/content/sourceparse/tag34.go`, `tag34_test.go`, `internal/content/jobimport/parse.go`, `parse_test.go`; modify `internal/content/speciesimport/enums.go` and its tests as needed.

**Interfaces:** `sourceparse.Tag34Lines(path string, data []byte) ([]string,error)` and `sourceparse.ActiveEnumIDs(path string, data []byte, prefix string) (map[string]struct{},error)` preserve species-import semantics. `jobimport.parseJobData(path string, data []byte) ([]content.JobDef,error)` parses the exact map rows and sets `Selectable` from `RecommendedSpecies` length.

- [ ] **Step 1: Write failing tests** for tag-34 `==`, `>`, `#else`, nested branches, and unsupported directives; for the job parser, use small source strings asserting all ten fields, preserved vector order, signed modifiers, quoted equipment specs containing commas/tags, trailing commas/comments, a zeroed removed job, and errors for duplicate/missing fields, unknown tokens, malformed strings, duplicate IDs, and an unsupported conditional. Error text names path, job, and field where available.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/sourceparse ./internal/content/jobimport`; confirm failure.
- [ ] **Step 3: Move** the current tag-34 scanner into `sourceparse` without broadening its grammar; update `speciesimport` to call it. Implement `parseJobData` with a small tokenizer that distinguishes braces, commas, signed integers, identifiers, quoted strings, and comments; reject unconsumed tokens instead of skipping them.
- [ ] **Step 4: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/sourceparse ./internal/content/jobimport ./internal/content/speciesimport`; confirm parser and existing species tests pass; format files.
- [ ] **Step 5: Commit** as `feat: parse pinned job definitions`.

### Task 3: Generate and commit the complete job artifact

**Files:** Create `internal/content/jobimport/import.go`, `import_test.go`, `cmd/importjobs/main.go`, `internal/content/generated/jobs.json`.

**Interfaces:** `jobimport.Generate(sourceDir string) ([]byte,error)` verifies Git HEAD, clean tracked source, and tag major; `jobimport.Write(sourceDir, outPath string, check bool) error` writes atomically or compares bytes. CLI: `go run ./cmd/importjobs -source <crawl-ref/source> -out internal/content/generated/jobs.json [-check]`.

- [ ] **Step 1: Write failing tests** with a small temporary source tree and private `generateFromSource(sourceDir, revision string)`: artifact sorts jobs and six source-file hashes, retains ordered inner lists, rejects missing/extra job enum IDs, duplicate IDs/abbreviations, unknown species/spell/skill IDs, pseudo `SPELL_NO_SPELL` and pseudo skills other than `SK_WEAPON`, wrong tag/revision, and unexpected conditional. `Write(..., true)` fails on stale bytes without modifying them; generation failure leaves output untouched.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/jobimport -run 'TestGenerate|TestWrite'`; confirm failure.
- [ ] **Step 3: Implement** the interfaces using only source files `tag-version.h`, `job-data.h`, `job-type.h`, `species-type.h`, `spell-type.h`, and `skill-type.h`; hash each, validate referenced IDs and complete job coverage, sort output, encode indented JSON with a final newline, and use temp-file-plus-rename. Create the CLI and generate the committed artifact from the pinned checkout.
- [ ] **Step 4: Run** importer twice to separate temporary paths and `cmp` them; run `-check` against committed output; inspect 31 unique jobs, 25 selectable, six removed, six hashed source paths, matching revision/tag. Run focused tests and format files.
- [ ] **Step 5: Commit** as `feat: generate complete source-traced job artifact`.

### Task 4: Load committed jobs with committed species

**Files:** Modify `internal/content/default.go`, `default_test.go`, `catalog.go`, `job_test.go`; update private `loadDefault` test call sites.

**Interfaces:** `content.LoadDefault() (Catalog,error)` keeps its public signature. Private `loadDefault(speciesData, jobData []byte) (Catalog,error)` loads and validates both artifacts, including matching source revision/tag, sorted provenance, complete 43 species and 31 jobs, and valid IDs in each recommendation list without requiring list symmetry.

- [ ] **Step 1: Write failing tests** for 31 loaded jobs, Fighter `8/0/4`, its three equipment specs and four skill grants, an Air Elementalist spell library, Wanderer zero/randomized table fields, six removed jobs, fresh independent catalogs, malformed/wrong-revision job JSON, duplicate/missing jobs, missing cross-references, malformed provenance hashes, and matching species/job source metadata.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content -run 'TestLoadDefault|TestJob'`; confirm failure.
- [ ] **Step 3: Embed** `generated/jobs.json`, decode both artifacts strictly, validate and copy them into one `Catalog`, and require the scenario job. Update existing private-loader tests to pass both byte slices; keep normal game startup independent of C++ files.
- [ ] **Step 4: Run** focused content tests and `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/speciesimport`; confirm pass and format files.
- [ ] **Step 5: Commit** as `feat: load committed jobs into the content catalog`.

### Task 5: Implement directional choice and base-stat rules

**Files:** Create `internal/character/choice.go`, `choice_test.go`, `stats.go`, `stats_test.go`.

**Interfaces:** `type Restriction uint8` with `Banned`, `Restricted`, `Recommended`; `JobForSpecies(c content.Catalog, speciesID, jobID string) (Restriction,error)` reads species recommendations; `SpeciesForJob(c content.Catalog, speciesID, jobID string) (Restriction,error)` reads job recommendations; `BaseStatSum(c content.Catalog, speciesID, jobID string) (Attributes,error)` returns `Attributes{Strength, Intelligence, Dexterity int}` for a legal fixed-stat pair and errors for Wanderer.

- [ ] **Step 1: Write failing tests** using `content.LoadDefault`: Human/Fighter restricted both ways but legal and `16/8/12`; all 27×25 pairs give exactly 664 non-banned results; Felid four bans, Demigod five bans, Ghoul and Mummy Transmuter bans; Barachi/Arcane Marksman recommended only in the species-first direction; removed job and nonselectable species banned; unknown IDs error; Wanderer `BaseStatSum` error. Test the private banned-pair predicate with a synthetic `SpeciesDef` whose mutation arrives after level 1.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/character`; confirm failure.
- [ ] **Step 3: Implement** one pure banned-pair predicate from `ng-restr.cc`, directional recommendation lookup, and additive stat calculation. A positive `MUT_NO_GRASPING` or `MUT_FORLORN` at any level triggers its bans; `US_UNDEAD` triggers the Transmuter ban. Keep no package-level mutable state.
- [ ] **Step 4: Run** focused tests and format files; confirm pass.
- [ ] **Step 5: Commit** as `feat: port normal Dungeon character choice rules`.

### Task 6: Apply attributes in ECS, terminal, and save version 2

**Files:** Modify `internal/ecs/components.go`, `stores.go`, `internal/game/scenario.go`, `view.go`, `save.go`, `internal/save/snapshot.go`, `internal/terminal/render.go`, and corresponding tests.

**Interfaces:** `ecs.Attributes{Strength, Intelligence, Dexterity int}` stored in `Stores.Attributes`. `game.View` exposes `CharacterName string` and `Attributes ecs.Attributes`. `save.Version` becomes 2; `save.EntityRecord.Attributes *ecs.Attributes` serializes only player attributes.

- [ ] **Step 1: Write failing tests** that `NewScenario` has Human/Fighter attributes `16/8/12`, `View` and terminal show the source-backed name and stats, and save/restore preserves the component through seeded continuation. Restore rejects absent/player-mismatched attributes, attributes on monsters or items, nonpositive values, and version-1 saves without changing the live game. Update the existing wrong-version test to use version 3 once `save.Version` becomes 2. Keep HP 20 and damage 4 assertions.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/ecs ./internal/game ./internal/save ./internal/terminal`; confirm failure.
- [ ] **Step 3: Register** the component, calculate it before creating the player entity, include it in view and snapshot, validate it during restore against `character.BaseStatSum`, and render a compact status/name line. Do not add a character-selection UI or apply job skills/items in this task.
- [ ] **Step 4: Run** the focused package tests and format files; confirm pass.
- [ ] **Step 5: Commit** as `feat: persist and display source-derived player attributes`.

### Task 7: Integrated verification and inventory

**Files:** Modify `docs/port-inventory.md` and only code/tests needed to correct observed integration failures.

**Interfaces:** No new production API. The inventory distinguishes imported job content and implemented eligibility/base stats from unported starting effects.

- [ ] **Step 1: Update** the inventory with 31 imported jobs, 25 selectable, 664 normal Dungeon pairs, Human/Fighter attributes, version-2 save, and explicit gaps: starting equipment/weapon choice, spells, skills, mutations, religion, HP/MP, `_unfocus_stats`, Wanderer randomization, Sprint, and complete character creation. Retain the all-content committed-artifact policy.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./...`, `GOCACHE=/tmp/dcrawl-go-cache go vet ./...`, and focused seeded save/restore tests. Fix concrete failures, then rerun only the failed check.
- [ ] **Step 3: Run** both optional importers' explicit `-check` against the pinned C++ checkout; compare two job generations byte-for-byte. Build/test a temporary copy containing only the Go repository to confirm ordinary commands need no C++ checkout; launch the terminal and confirm Human/Fighter stats appear.
- [ ] **Step 4: Review** the branch diff against the spec: complete source IDs, legal/recommended distinction, no mutable global content registry, no importer hooked into build/test/runtime, no version-1 compatibility shim, and no broad completion claim. Run `git diff --check`.
- [ ] **Step 5: Commit** inventory and integration fixes as `docs: record job and character choice status` (or `fix:` for substantive corrections), then request one whole-branch review before local integration.
