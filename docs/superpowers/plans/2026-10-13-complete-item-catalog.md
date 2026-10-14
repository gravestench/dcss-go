# Complete Base Item Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Import every concrete tag-34 base item identity, name, ASCII glyph, and available static property row into committed Go content, then use that catalog for the existing Dungeon slice.

**Architecture:** A developer-only importer independently extracts enum identity and explicit-removal data into a manifest, then joins the source's name, presentation, and four property views into an item artifact. `content.Catalog` loads and cross-validates both embedded artifacts, keeps immutable definitions private, and supplies copies to existing game code. Starting gear retains ordered grant IDs but ceases to own item definitions.

**Tech Stack:** Go 1.25, standard-library JSON/embed/Git execution, existing `sourceparse.Tag34NumberedLines`, Akara ECS, current version-4 Go save codec. No new runtime dependency.

**Spec:** `docs/superpowers/specs/2026-10-13-complete-item-catalog-design.md`

## Global Constraints

- Source: `/Users/dylanknuth/src/crawl/crawl-ref/source` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, `TAG_MAJOR_VERSION=34`; reject another revision/tag or modified tracked files read by the importer.
- Exactly 16 active object classes; preserve concrete numeric class/subtype values and stable symbolic IDs. Exclude aliases, numeric gaps, count/range markers, `OBJ_RANDOM`, `OBJ_DETECTED`, and weapon pseudo-values after `NUM_WEAPONS`; `OBJ_GOLD` has subtype zero.
- Record explicit `removed_items` membership independently from names and property rows; never infer a `spawnable` flag or generation eligibility.
- Include every field and row of tag-34 `Armour_prop`, `Weapon_prop`, `Missile_prop`, and `Food_prop`; no invented table for other classes. Keep instance-dependent names as naming kinds.
- Commit `internal/content/generated/items.json` and `item-identities.json`. Normal Go build/test/play and version-4 save/restore never need C++ or run an importer.
- Preserve current fixed Dungeon behavior, Akara ownership of mutable item state, DCSS attribution/license, the untracked `dcrawl-save.json`, and the paused C++ refactor.
- `-source` and `-out` are explicit; `-out` names `items.json`, with `item-identities.json` beside it. `-check` is read-only. Both files are deterministic and individually atomically replaced after both validate.

## File Map

- `internal/content/item.go`, `item_test.go`, `catalog.go`: typed item identity, source evidence, class-specific properties, private catalog index, copy-safe lookup/list API.
- `internal/content/itemimport/identity.go`, `identity_test.go`: numbered tag-34 enum parsing, numeric/alias/gap rules, 16-class mapping, independent identity and explicit-removal manifest.
- `internal/content/itemimport/properties.go`, `properties_test.go`: scanner and decoder for four complete static property tables and pinned macro forms.
- `internal/content/itemimport/presentation.go`, `presentation_test.go`: source names and dynamic naming cases from `item-name.cc`; default ASCII glyphs from `show.cc`, `show.h`, `dungeon-char-type.h`, and `viewchar.cc`.
- `internal/content/itemimport/import.go`, `import_test.go`, `cmd/importitems/main.go`: revision/cleanliness/hash checks, join and coverage checks, deterministic artifact pair, atomic write and `-check`.
- `internal/content/generated/items.json`, `item-identities.json`, `default.go`, `default_test.go`: committed data, embed, strict cross-validation, combined catalog loading.
- `internal/content/starting_gear.go`, `starting_gear_test.go`, `internal/content/startinggearimport/import.go`, `kinds.go`, `import_test.go`, `cmd/importstartinggear/main.go`, `internal/content/generated/starting-gear.json`: schema-2 ordered grants resolved against complete catalog; remove duplicate `Kinds` path.
- `internal/character/starting_skills_test.go`, `internal/game/save.go`, `save_test.go`, `view.go`, `starting_gear.go`, their focused tests, `docs/port-inventory.md`: adapt consumers only where item shape changes and prove existing play/save behavior.

## Review Focus

1. Enum aliases with explicit numeric assignments must not create a second identity or shift the next concrete numeric value (Task 2 test).
2. A legacy subtype that has a property row and a “removed” name but is absent from `removed_items` must retain those separate facts (Tasks 2–4 tests).
3. String/comment delimiters and nested brand braces in source rows must not end a field early or silently drop a brand (Task 3 test).
4. A refresh that replaces only one of the two artifacts must fail at startup through independent identity/removal/hash comparison (Tasks 5–6 tests).
5. A known but incomplete legacy identity must remain inspectable while `Catalog.Item` and save restore reject attempts to instantiate it (Tasks 1 and 6 tests).

---

### Task 1: Define item values and the catalog contract

**Files:** Create `internal/content/item.go`, `item_test.go`; modify `internal/content/catalog.go`, `catalog_test.go`, `internal/content/starting_gear.go` only as needed to move existing `ItemDef.validate` without behavior change.

**Interfaces:** `ItemIdentity{ID,ClassID string; ClassValue,SubtypeValue,SourceLine int; SourcePath string; ExplicitlyRemoved bool}`; `ItemAlias{ID,TargetID,ClassID,SourcePath string; NumericValue,SourceLine int}`; `ItemName{Text,Kind,SourcePath string; SourceLine int}` (`Kind` is `static`, `manual_skill`, or `corpse_monster`); `ItemEvidence{NameSource,PropertySource string; NameLine,PropertyLine int}`; `ItemFlag{ID string; Level int}`; `ArmourProperties{AC,EV,Price,AcquireWeight int; SlotID,FitMinID,FitMaxID string; Mundane bool; Flags []ItemFlag}`; `WeaponProperties{Damage,Hit,Speed,Commonness,AcquireWeight,Price int; SkillID,Min2HSizeID,Min1HSizeID,AmmoID string; DamageFlags []string; BrandWeights []ItemBrandWeight}`; `ItemBrandWeight{BrandID string; Weight int}`; `MissileProperties{Damage,MulchRate,Price int}`; `FoodProperties{NormalNutrition,CarnivoreNutrition,HerbivoreNutrition int}`. `ItemDef` retains existing `ID,Name,Glyph,Class,Slot,WeaponSkill,Stackable` consumer fields and adds `ClassValue,SubtypeValue int`, `Naming ItemName`, `Evidence ItemEvidence`, `ExplicitlyRemoved bool`, and exactly one applicable pointer to the four property types. `ItemArtifact{SchemaVersion,TagMajorVersion int; SourceRevision string; SourceFiles []JobSourceFile; Items []ItemDef}`; `ItemIdentityManifest{SchemaVersion,TagMajorVersion int; SourceRevision string; SourceFiles []JobSourceFile; Identities []ItemIdentity; Aliases []ItemAlias; Vocabulary ItemVocabulary}`; `ItemVocabulary` has `Slots,Skills,Sizes,Ammo,DamageFlags,Brands,ArmourFlags []string`, each sorted. `Catalog.Item(id string) (ItemDef,error)` stays; add `Catalog.ItemIdentity(id string) (ItemIdentity,error)` and `Catalog.ItemIDs() []string`; clone all nested slices on ingress/egress.

- [ ] **Step 1: Write failing tests** `TestItemDefCopies` and `TestItemIdentityInspection`: mutate returned `BrandWeights`, `DamageFlags`, `Flags`, and ID listing, then assert repeat calls are unchanged; unknown IDs error; a known identity with no definition is inspectable but `Item` errors. `TestItemShapeValidation` rejects two class-property pointers or the wrong class pointer, bad source location, unknown naming kind, and an unsorted/duplicate brand list.
- [ ] **Step 2: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./internal/content -run 'TestItemDefCopies|TestItemIdentityInspection|TestItemShapeValidation'`; expect missing types or failed assertions.
- [ ] **Step 3: Implement** the named types, `ItemDef.clone() ItemDef`, `ItemDef.validate() error`, `ItemIdentityManifest.Validate() error`, `ItemArtifact.Validate(manifest ItemIdentityManifest) error`, and catalog accessors. Keep the old starter fixture valid until Task 6 switches default loading; the complete artifact validator enforces the stricter shape.
- [ ] **Step 4: Run** focused content tests and `gofmt` changed Go files; expect pass.
- [ ] **Step 5: Commit** `feat: define complete item catalog values`.

### Task 2: Parse the independent identity and removal manifest

**Files:** Create `internal/content/itemimport/identity.go`, `identity_test.go`; use `internal/content/sourceparse/tag34.go` unchanged unless a failing fixture proves a narrow fix is needed.

**Interfaces:** Private `parseIdentities(source map[string][]byte) (identities []content.ItemIdentity, aliases []content.ItemAlias, err error)` reads `object-class-type.h`, `item-prop-enum.h`, `potion-type.h`, `book-type.h`, `orb-type.h`; `parseRemovedItems(path string, data []byte) (map[itemKey]bool,error)` scans only the `removed_items` initializer in `item-prop.cc`; `itemKey{ClassID,SubtypeID string}`. `parseVocabulary(source map[string][]byte) (content.ItemVocabulary,error)` resolves the property symbols from pinned headers. These functions do not read decoded name/property rows.

- [ ] **Step 1: Write failing tests** `TestItemIdentityEnums` with explicit assignments, gaps, aliases, conditional tag branches, 16 active classes, gold subtype zero, corpse and orb mappings, and weapon pseudo IDs after `NUM_WEAPONS`. `TestRemovedItemsIndependent` checks exact class/subtype pairs, including a removed-looking row outside the list; reject duplicate pairs, unresolved numeric expressions, malformed conditionals, and unknown symbols with file/line context.
- [ ] **Step 2: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./internal/content/itemimport -run 'TestItemIdentityEnums|TestRemovedItemsIndependent'`; expect failure.
- [ ] **Step 3: Implement** the named parsers using numbered active lines, a narrow integer/alias expression evaluator, and explicit enum-to-class mapping. Preserve source line and numeric value; derive the manifest independently of row decoding; fail on unfamiliar syntax instead of skipping it.
- [ ] **Step 4: Run** focused parser tests and `gofmt`; expect pass.
- [ ] **Step 5: Commit** `feat: parse pinned item identities and removals`.

### Task 3: Decode all four static property tables

**Files:** Create `internal/content/itemimport/properties.go`, `properties_test.go`.

**Interfaces:** Private `parsePropertyTables(path string, data []byte, vocabulary content.ItemVocabulary) (map[itemKey]itemPropertyRow,error)`; `itemPropertyRow` carries `Name`, source `Line`, and one of `*content.ArmourProperties`, `*content.WeaponProperties`, `*content.MissileProperties`, `*content.FoodProperties`. It decodes `Armour_prop`, `Weapon_prop`, `Missile_prop`, and tag-34 `Food_prop`, including default-initialized trailing C++ struct fields, `DRAGON_ARMOUR`, named brand vectors, inline brand vectors, `ard(...)`, and flag unions.

- [ ] **Step 1: Write failing tests** `TestPropertyTablesComplete` for exact pinned row IDs/counts per table and all fields of robe, fire dragon scales/hide (including fire resistance level 2 and cold vulnerability), mace and its brand weights, `MI_NEEDLE`, and `FOOD_RATION`. `TestPropertyScannerRejectsLoss` uses quoted commas/`//`, nested braces, a missing field, unknown macro, unknown symbol, duplicate row, and extra row; expect contextual error rather than partial output.
- [ ] **Step 2: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./internal/content/itemimport -run 'TestPropertyTablesComplete|TestPropertyScannerRejectsLoss'`; expect failure.
- [ ] **Step 3: Implement** the named scanner/decoder with string/comment awareness and brace/parenthesis depth. Expand only pinned macro forms and retain every struct field in typed values. Validate each table against Task 2's identity set without demanding property rows for non-table classes.
- [ ] **Step 4: Run** focused tests and `gofmt`; expect pass.
- [ ] **Step 5: Commit** `feat: decode complete item property tables`.

### Task 4: Resolve source names and ASCII presentation

**Files:** Create `internal/content/itemimport/presentation.go`, `presentation_test.go`.

**Interfaces:** Private `parseItemNames(path string, data []byte, identities []content.ItemIdentity) (map[itemKey]content.ItemName,error)` and `parseASCIIItemGlyphs(showPath string, showData []byte, showHeader []byte, dcharHeader []byte, viewPath string, viewData []byte, identities []content.ItemIdentity) (map[itemKey]rune,error)`. The glyph parser verifies `SHOW_ITEM_*` and `DCHAR_ITEM_*` order from the headers before indexing the tag-34 `CSET_ASCII` table. A naming case with per-instance suffix uses `ItemName.Kind` and fixed source text; no invented fully qualified manual/corpse name.

- [ ] **Step 1: Write failing tests** `TestPinnedItemNamesAndGlyphs` for representative weapon, potion, book/manual, corpse/skeleton, gold, orb, rune, and ring/amulet names/glyphs; test header-driven enum order and subtype override. `TestDynamicNameAndSourceErrors` checks manual/corpse dynamic kinds, ambiguous names, missing source case, malformed conditional, and unknown glyph reference with path/line errors.
- [ ] **Step 2: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./internal/content/itemimport -run 'TestPinnedItemNamesAndGlyphs|TestDynamicNameAndSourceErrors'`; expect failure.
- [ ] **Step 3: Implement** the two source scanners, restricting `viewchar.cc` to the ASCII character set and resolving `show.cc` class/subtype presentation. Keep display names distinct from property-table names and record both evidence locations.
- [ ] **Step 4: Run** focused tests and `gofmt`; expect pass.
- [ ] **Step 5: Commit** `feat: import item names and ASCII glyphs`.

### Task 5: Generate the deterministic artifact pair

**Files:** Create `internal/content/itemimport/import.go`, `import_test.go`, `cmd/importitems/main.go`, `internal/content/generated/items.json`, `item-identities.json`.

**Interfaces:** `itemimport.Generate(sourceDir string) (itemsJSON, identitiesJSON []byte, err error)` checks pinned Git revision, tracked-file cleanliness, and tag; private `generateFromSource(sourceDir, revision string) ([]byte,[]byte,error)` supports isolated fixtures; `itemimport.Write(sourceDir,outPath string,check bool) error` writes/checks both siblings. CLI: `go run ./cmd/importitems -source /Users/dylanknuth/src/crawl/crawl-ref/source -out internal/content/generated/items.json [-check]`.

- [ ] **Step 1: Write failing tests** `TestItemImportPair` for exact enum-to-row joins, every concrete ID once, all four table row sets, no invented properties for other classes, source paths/lines/hashes, sorted vocabularies, same-count ID substitution, wrong numeric subtype, swapped removal membership, and unknown property symbols. `TestItemImportWrite` checks two byte-identical imports, stale `-check` preserving bytes, and generation failure preserving both previous files; reject wrong revision/tag and dirty tracked source.
- [ ] **Step 2: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./internal/content/itemimport -run 'TestItemImportPair|TestItemImportWrite'`; expect failure.
- [ ] **Step 3: Implement** join and exact coverage validation, stable JSON plus final newline, relative sorted SHA-256 provenance, and pair validation before either rename. Write both via same-directory temp files and individual atomic renames; runtime Task 6 detects an interrupted two-file refresh. Run the CLI to create the committed artifacts.
- [ ] **Step 4: Run** importer tests, generate twice to separate temporary dirs and `cmp` both outputs, then run CLI `-check` on committed output; inspect exact per-class totals and four property-table counts before committing.
- [ ] **Step 5: Commit** `feat: import complete pinned item catalog`.

### Task 6: Load both artifacts and migrate starting gear

**Files:** Modify `internal/content/default.go`, `default_test.go`, `catalog.go`, `starting_gear.go`, `starting_gear_test.go`, `internal/content/startinggearimport/import.go`, `kinds.go`, importer tests, `internal/content/generated/starting-gear.json`, `internal/character/starting_skills_test.go`, and focused `internal/game` item/save/view tests.

**Interfaces:** `content.LoadDefault() (Catalog,error)` and `LoadDefinitionsForImport() (Catalog,error)` retain signatures; private `loadDefault` gains `itemData, identityData []byte` before gear data. Add `content.LoadItemsForImport() (Catalog,error)` to load and validate only the committed item pair, avoiding a dependency on the gear artifact being refreshed. `StartingGearArtifact` schema becomes `2`, drops `Kinds`, retains `Jobs []JobStartingGear`; `StartingGearArtifact.Validate(catalog Catalog) error` resolves every grant against fully defined item IDs. `startinggearimport.Generate` and `Write` retain public signatures but resolve grants through `LoadItemsForImport`. `Catalog.Item` returns only fully defined kinds; `Catalog.ItemIdentity` covers all known concrete identities.

- [ ] **Step 1: Write failing tests** `TestDefaultItemManifest` for exact identity, numeric, removal, hash, order, provenance, vocabulary, and record equality; mutate one artifact at a time to simulate an interrupted refresh. `TestStartingGearCatalogReferences` rejects absent/undefined grant IDs and chosen weapons/potion, preserves 25 ordered job grants/raw specs, and verifies no `Kinds` field in schema 2. `TestKnownIncompleteItemRestore` rejects a save item using a known but undefined legacy ID without altering the live game.
- [ ] **Step 2: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./internal/content ./internal/game ./internal/character -run 'TestDefaultItemManifest|TestStartingGearCatalogReferences|TestKnownIncompleteItemRestore'`; expect failure.
- [ ] **Step 3: Implement** embed/decode of both artifacts before gear, exact manifest comparison, matching source hashes/revision across item, job, and gear artifacts, and private item index construction with copies. Remove `gear.Kinds` and the narrow `resolveKinds` path; update importer to use committed item catalog, regenerate schema-2 gear, and adapt `loadDefault` test fixtures/callers. Keep game item state and save schema at version 4.
- [ ] **Step 4: Run** content/character/game tests, the starting-gear importer `-check`, and `gofmt`; expect pass. Check that the starting weapon menu, inventory, fixed potion, and view still resolve the same IDs/names/glyphs.
- [ ] **Step 5: Commit** `feat: load complete items and reference them from starting gear`.

### Task 7: Verify the Dungeon slice and document content status

**Files:** Modify `docs/port-inventory.md` and only code/tests needed for observed integration failures.

**Interfaces:** No new product API. Item catalog definitions do not imply generation, identification, equipment effects, use, artefacts, or combat formulas.

- [ ] **Step 1: Add focused regression assertions** for existing Human/Fighter gear and weapon choices, item views, deterministic seeded turns, version-4 save/restore, and rejection of invalid per-instance fields; run them first and capture any actual failure before changing code.
- [ ] **Step 2: Fix** only observed regressions, then run `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./...`, `GOCACHE=/private/tmp/dcrawl-go-build-cache go vet ./...`, and `GOCACHE=/private/tmp/dcrawl-go-build-cache go build ./...`; expect pass.
- [ ] **Step 3: Run** both importer `-check` commands; build/test a temporary Go-only copy with no C++ checkout; smoke-check startup, terminal map/inventory, pickup, turns, save and restore.
- [ ] **Step 4: Update** `docs/port-inventory.md` with the exact imported per-class totals, four table counts, committed-artifact policy, and separate unported item domains. Review the spec's six acceptance checks, attribution, `git diff --check`, and untouched user save/C++ tree.
- [ ] **Step 5: Commit** `docs: record complete base item catalog` (or `fix:` for substantive integration corrections), then request whole-branch review before merging to local Go `main`.
