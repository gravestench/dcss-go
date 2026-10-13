# Starting Gear and Weapon Choice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the fixed Human/Fighter start a legal chosen weapon and source-backed carried/equipped gear while committing typed starter-item data for every selectable job.

**Architecture:** An optional importer resolves the pinned jobs' raw equipment specs and item names into a committed `starting-gear.json`; `content.LoadDefault` embeds and validates it with species/jobs. Pure `character` rules list legal weapon options. A Bubble Tea pregame selector supplies the chosen ID; `game` owns ECS loadout creation and version-3 save validation.

**Tech Stack:** Go 1.25, standard-library JSON/embed/SHA-256/Git command execution, existing Akara ECS, Bubble Tea/Lip Gloss, existing Go save codec. No new runtime dependency.

**Spec:** `docs/superpowers/specs/2026-10-13-starting-gear-weapon-choice-design.md`

## Global Constraints

- Source checkout: `/Users/dylanknuth/src/crawl/crawl-ref/source`, Git `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, tag major 34. Do not edit the paused C++ refactor.
- All imported content is a committed Go-repository artifact. Importers run only by explicit developer command; ordinary build, tests, CI, save, and gameplay need no C++ checkout.
- Exactly 25 selectable jobs contribute 63 ordered grants with 36 distinct raw equipment strings and 32 distinct item names. Accepted spec tags: `q:`, `plus:`, `charges:`, `ego:`, `no_exclude`.
- Human/Fighter's legal choices: `WPN_RAPIER`, `WPN_FLAIL`, `WPN_WAR_AXE`, `WPN_TRIDENT`, `WPN_LONG_SWORD`, `WPN_UNARMED`; `WPN_QUARTERSTAFF` is banned. Unarmed creates no weapon entity.
- Normal Human/Fighter grants, in source order: scale mail, buckler, potion of might; the chosen weapon is created first. Potion of curing remains on the floor. No Sprint bonus items.
- Player HP 20, base damage 4, and rat combat stay fixture behavior; equipped weapons do not yet change damage. No item effects, identification, species gear substitutions, other playable jobs, skill reassessment, or full character creation.
- Save version 3 rejects version 2; no compatibility shim. Restore never replaces a live game on failure.
- Commit one contiguous problem category at a time. Do not run the entire suite after every small task; run focused tests per task and integrated tests at the end.

## File Map

- `internal/content/starting_gear.go`, `starting_gear_test.go`, `catalog.go`, `fixture.go`: immutable item-kind and ordered grant types, validation, defensive catalog accessors; add class metadata to the current floor-potion fixture until Task 5 replaces it.
- `internal/content/startinggearimport/spec.go`, `spec_test.go`: strict parser for the pinned equipment-string grammar.
- `internal/content/startinggearimport/kinds.go`, `kinds_test.go`: source-backed item name/ID/class/slot/skill resolution. Direct weapon/armour/missile rows come from `item-prop.cc`; indirect potion/scroll/wand names and the misc case come from `item-name.cc` and active enums.
- `internal/content/startinggearimport/import.go`, `import_test.go`, `cmd/importstartinggear/main.go`, `internal/content/generated/starting-gear.json`: pinned checkout validation, source hashes, deterministic artifact, atomic/check CLI.
- `internal/content/default.go`, `default_test.go`, `starting_gear_test.go`, `fixture.go`: embed and cross-validate all three committed artifacts; replace the potion fixture kind with imported content.
- `internal/character/weapon.go`, `weapon_test.go`: pure ordered choice, good upgrades, restrictions, and recommendations.
- `internal/ecs/components.go`, `stores.go`; `internal/game/scenario.go`, `starting_gear.go`, `view.go`, `save.go`; `internal/save/snapshot.go`; `internal/terminal/start.go`, `model.go`, `render.go`; `cmd/dcrawl/main.go` and their tests: pregame selection, ECS carried/equipped items, display, version-3 persistence and restore.
- `docs/port-inventory.md`: shipped and deferred behavior.

## Review Focus

1. An item name containing spaces or an apostrophe (especially `piece from Xom's chessboard`) must stay intact while tags are parsed; a malformed or duplicate tag must fail with job/spec context (Task 2 tests).
2. A `TAG_MAJOR_VERSION > 34` or `#else` source branch must not supply a kind or name to the tag-34 artifact; an inactive enum ID must fail import (Task 3 tests).
3. A small Fighter choosing a spear must keep `WPN_SPEAR`; no-grasping species must offer only unarmed, while quadrumanous Fighter may choose quarterstaff (Task 6 tests).
4. A saved equipped item without the player as carrier, or two items in the same slot, must fail restore without replacing the live game (Task 7 tests).
5. Invalid pregame input and an invalid/old save must leave the menu active without creating a game or advancing auts; loading a valid version-3 save bypasses weapon selection (Task 7 tests).

---

### Task 1: Define immutable starting-gear catalog values

**Files:** Create `internal/content/starting_gear.go`, `starting_gear_test.go`; modify `internal/content/catalog.go`, `fixture.go`.

**Interfaces:** Extend `ItemDef` with `Class, Slot, WeaponSkill string`, `Stackable bool` while retaining `ID, Name string; Glyph rune`. Define `StartingGrant{Raw, KindID, Ego string; Quantity, Plus, Charges int; NoExclude bool}`, `JobStartingGear{JobID string; Grants []StartingGrant}`, and `StartingGearArtifact{SchemaVersion int; SourceRevision string; TagMajorVersion int; SourceFiles []JobSourceFile; Kinds []ItemDef; Jobs []JobStartingGear}`. Add private `Catalog.startingGear map[string][]StartingGrant`, `Catalog.StartingGrants(jobID string) ([]StartingGrant,error)` returning copies. `Catalog.Item` continues to return a value copy.

- [ ] **Step 1: Write failing tests** `TestStartingGearCatalogCopies` mutates a returned grant slice and proves later reads unchanged; `TestStartingGearArtifactValidation` rejects duplicate kind/job IDs, empty names, incompatible class/slot/skill, nonpositive quantity, charges on non-wands, and invalid ego/class combinations. Include `POT_CURING` and a weapon kind in the fixture.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content -run 'TestStartingGear'`; expect missing types/accessor.
- [ ] **Step 3: Implement** the types and `Validate()` in `starting_gear.go`; give the current floor-potion fixture its required item class until Task 5 loads the artifact. No mutable package-level registry or compatibility layer.
- [ ] **Step 4: Run** the focused content tests and format changed Go files; expect pass.
- [ ] **Step 5: Commit** `feat: define immutable starting gear catalog values`.

### Task 2: Parse pinned equipment spec strings

**Files:** Create `internal/content/startinggearimport/spec.go`, `spec_test.go`.

**Interfaces:** `parseEquipmentSpec(jobID, raw string) (name string, grant content.StartingGrant, err error)` consumes only the pinned tags; resolution of `name` to `KindID` occurs in Task 3. Defaults: quantity 1, plus 0, charges 0, ego empty, no-exclude false. Preserve `Raw`; a present `charges:` value must be positive, so zero remains the absent value.

- [ ] **Step 1: Write failing tests** `TestParseEquipmentSpec` over plain `scale mail`, `potion of invisibility q:2`, `wand of flame charges:15`, `dart ego:curare q:3`, `scroll of fog no_exclude`, and `piece from Xom's chessboard`. `TestParseEquipmentSpecRejectsBadTag` covers duplicate `q:`, `q:0`, negative charge, unsupported tag, malformed number, empty name, and mixed `plus:`/`charges:`; error includes job ID and raw spec.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/startinggearimport -run 'TestParseEquipmentSpec'`; expect missing function.
- [ ] **Step 3: Implement** the parser: peel recognized suffix tokens from the right, then join the remaining name tokens, preserving spaces and apostrophes. Reject unconsumed colon-tags and duplicate fields. Do not call the C++ vault parser at runtime.
- [ ] **Step 4: Run** focused tests and format files; expect pass.
- [ ] **Step 5: Commit** `feat: parse pinned starting equipment specs`.

### Task 3: Resolve pinned item names and active IDs

**Files:** Create `internal/content/startinggearimport/kinds.go`, `kinds_test.go`.

**Interfaces:** `resolveKinds(sourceDir string, names []string) ([]content.ItemDef,error)` reads tag-34 active IDs from `item-prop-enum.h` and `potion-type.h`; direct `Armour_prop`, `Weapon_prop`, and `Missile_prop` rows from `item-prop.cc`; switch names from `item-name.cc` for potions, scrolls, wands, misc. For indirectly composed names, a source-anchored mapping in this importer is acceptable only if each mapped ID is active. Include weapon skill/armour slot, class glyph, and stackability. `WPN_UNARMED` is a legal choice token, never an `ItemDef`.

- [ ] **Step 1: Write failing tests** `TestResolveKinds` with small synthetic source excerpts: direct `ARM_SCALE_MAIL`, `WPN_FLAIL` with `SK_MACES_FLAILS`, `MI_DART`, indirect `POT_MIGHT`, `SCR_MAGIC_MAPPING`, `WAND_CHARMING`, and `MISC_XOMS_CHESSBOARD`. `TestResolveKindsRejectsInactiveOrAmbiguousName` adds `#if TAG_MAJOR_VERSION > 34`, `#else`, an inactive enum, duplicate display names, and an unknown requested name. Every error names the source path and name/ID.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/startinggearimport -run 'TestResolveKinds'`; expect missing resolver.
- [ ] **Step 3: Implement** the narrow source reader using `sourceparse.Tag34Lines`/`ActiveEnumIDs` and source-anchored indirect mappings; reject any requested kind whose ID lacks an active enum or whose definition/name cannot be verified. Keep property extraction limited to fields needed for this slice.
- [ ] **Step 4: Run** focused resolver tests and format files; expect pass.
- [ ] **Step 5: Commit** `feat: resolve source-backed starting item kinds`.

### Task 4: Generate and commit the complete starter artifact

**Files:** Create `internal/content/startinggearimport/import.go`, `import_test.go`, `cmd/importstartinggear/main.go`, `internal/content/generated/starting-gear.json`.

**Interfaces:** `Generate(sourceDir string) ([]byte,error)` enforces pinned HEAD, clean tracked source, tag 34, obtains all 31 parsed jobs through the existing `jobimport.Generate`, then resolves all 25 selectable jobs. Include the union of starter-spec kinds, all base and upgraded weapon-choice kinds, and `POT_CURING`. Private `generateFromSource(sourceDir,revision string,jobs []content.JobDef)` permits small synthetic fixtures without requiring Git or the C++ checkout in tests. `Write(sourceDir,outPath string,check bool) error` atomically writes or compares. CLI: `go run ./cmd/importstartinggear -source <crawl-ref/source> -out internal/content/generated/starting-gear.json [-check]`.

- [ ] **Step 1: Write failing tests** `TestGenerateStartingGear` uses a small synthetic job list and source snippets to assert exact order, resolved grants, sorted kinds/jobs/source hashes, revision/tag, and `POT_CURING` coverage. Synthetic cases reject bad revision/tag, missing job or item, wrong source branch, unknown ego, and ambiguous name. `TestWriteStartingGear` verifies stale `-check` and failed generation never modify output. These normal Go tests require no C++ checkout; the full 25/63/36/32 counts and Fighter grants are checked by the explicit pinned-source command in Step 4.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content/startinggearimport -run 'TestGenerateStartingGear|TestWriteStartingGear'`; expect missing generation/write methods or assertions.
- [ ] **Step 3: Implement** pinned source hashing, deterministic sorting, JSON indentation with final newline, temp-file-plus-rename, and explicit CLI. Decode and validate `jobimport.Generate` output; pass its jobs into `generateFromSource` and carry its six source-file hashes into the gear artifact. Generate the committed artifact from the pinned checkout. Hash every additional C++ file read, including item enum/property/name files and `newgame.cc`, `ng-restr.cc`, `ng-setup.cc`, `jobs.cc`; cross-check every shared path with species/jobs in Task 5.
- [ ] **Step 4: Run** importer twice to separate temp paths and `cmp`; run its `-check` against the committed artifact; inspect 25/63/36/32 counts and Fighter entries; run focused tests and format files. Expect exact byte matches and pass.
- [ ] **Step 5: Commit** `feat: commit complete source-traced starting gear artifact`.

### Task 5: Load committed gear with species and jobs

**Files:** Modify `internal/content/default.go`, `default_test.go`, `starting_gear_test.go`, `catalog.go`, `fixture.go`; update private `loadDefault` test call sites.

**Interfaces:** `content.LoadDefault() (Catalog,error)` stays public. Private `loadDefault(speciesData,jobData,gearData []byte) (Catalog,error)` validates all three artifacts, cross-checks shared source-file hashes, exact job IDs and ordered raw spec strings, all item references, and scenario `POT_CURING`. Remove the fixture `POT_CURING` definition and populate `Catalog.items` and `.startingGear` from embedded JSON.

- [ ] **Step 1: Write failing tests** `TestLoadDefaultStartingGear` checks Fighter source-ordered scale mail/buckler/might, 25 job lists, source-backed `POT_CURING`, fresh independent catalogs, and weapon/armour fields. `TestLoadDefaultRejectsBadStartingGear` mutates revision/tag, source hash, duplicate/missing job, changed raw spec/order, unknown kind, malformed JSON, and missing floor potion; each must return an error.
- [ ] **Step 2: Run** focused content tests; expect missing embedded artifact or failure.
- [ ] **Step 3: Implement** embed and strict decode, revision/tag/schema/provenance checks, exact cross-artifact job/string coverage, and defensive copies. Update existing private-loader tests to supply the third byte slice; normal runtime reads no C++ source.
- [ ] **Step 4: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content ./internal/content/speciesimport ./internal/content/jobimport`; expect pass. Format files.
- [ ] **Step 5: Commit** `feat: load committed starting gear into catalog`.

### Task 6: Implement pure weapon-choice rules

**Files:** Create `internal/character/weapon.go`, `weapon_test.go`.

**Interfaces:** `WeaponOption{ID,Name string; Restriction Restriction}`; `WeaponOptions(c content.Catalog,speciesID,jobID string) ([]WeaponOption,error)` returns ordered non-banned options. `ValidateWeaponChoice(c content.Catalog,speciesID,jobID,weaponID string) error` checks membership. Good upgrades and restrictions are private pure helpers.

- [ ] **Step 1: Write failing tests** `TestHumanFighterWeaponOptions` expects ordered IDs rapier/flail/war axe/trident/long sword/unarmed, with rapier restricted and the skill-recommended choices marked appropriately. `TestWeaponChoiceRestrictions` covers small Fighter spear staying spear, Gladiator and quadrumanous Fighter quarterstaff allowance, a selectable no-grasping species yielding only unarmed, invalid job/species/weapon IDs, and no mutation of catalog data.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/character -run 'Test.*Weapon'`; expect missing API.
- [ ] **Step 3: Implement** the seven source base choices, `WCHOICE_GOOD` upgrades, species size and mutation restrictions, and recommendation lookup via each weapon's `WeaponSkill` against species `RecommendedWeapons`; preserve source order. Do not create ECS items.
- [ ] **Step 4: Run** focused character tests and format files; expect pass.
- [ ] **Step 5: Commit** `feat: port source-backed starting weapon choices`.

### Task 7: Create selected loadout, pregame menu, and version-3 saves

**Files:** Modify `internal/ecs/components.go`, `stores.go`; `internal/game/scenario.go`, `view.go`, `save.go`, `save_test.go`; `internal/save/snapshot.go`, `codec_test.go`; `internal/terminal/model.go`, `render.go`, `model_test.go`; `cmd/dcrawl/main.go`. Create `internal/game/starting_gear.go`, `starting_gear_test.go`, `internal/terminal/start.go`, `start_test.go`.

**Interfaces:** `game.NewScenario(seed uint64,catalog content.Catalog,weaponID string) (*Game,error)` requires a selected legal ID. Extend `ecs.PlayerControlled` with `StartingWeaponID string`; extend `ecs.Item` with `Plus,Charges int; Ego string`; `ecs.Equipped{Slot string}` in `Stores.Equipped`. `game.View` inventory entries expose slot/properties for clear rendering. `save.Version = 3`; save records carry the new fields/component. `terminal.NewStartModel(catalog content.Catalog,seed uint64,savePath string)` returns one top-level Bubble Tea model with a nullable `play *Model`: before selection it renders the menu and handles only choice/quit/load; afterward it forwards input and views to the existing game model. It closes a game only if one is active; `cmd/dcrawl` runs this model.

- [ ] **Step 1: Write failing tests** `TestNewScenarioStartingGear` checks all six choices, source order, carrier and slot ownership, armed four items or unarmed three, no time spent, fixture floor potion, HP 20 and base damage 4. `TestStartMenu` checks invalid key leaves selection/time untouched, legal selection enters the game, quit, valid version-3 load bypass, invalid/version-2 load stays on menu. `TestSaveStartingGearContinuation` checks seeded continuation and every item property/slot; `TestRestoreRejectsCorruptGear` covers duplicate slot, equipped item without player carrier, invalid quantity/charges/ego, changed selected weapon, unknown kind, missing weapon, and version 2 without changing the live game. Permit extra carried pickups, but require the selected starting weapon and coherent equipped slots. Update all existing `NewScenario` calls in tests to supply a legal weapon ID; update old-version test expectations to version 2.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/ecs ./internal/game ./internal/save ./internal/terminal`; expect missing fields/APIs or failing assertions.
- [ ] **Step 3: Implement** ECS item creation from typed Fighter grants and selected weapon; equip unique compatible slots, retain `CarriedBy` as owner, and expose loadout in view. Add pregame Bubble Tea state that calls the new constructor only on legal selection and uses `game.Restore(snapshot,catalog)` for load. Snapshot/restore all new data with validation before returning a replacement game; failed restore leaves the menu or current game untouched. Keep weapon combat damage at fixture value.
- [ ] **Step 4: Run** focused package tests and format files; expect pass. Inspect both armed and unarmed inventory views and a valid save round-trip.
- [ ] **Step 5: Commit** `feat: start and save equipped Human Fighter loadouts`.

### Task 8: Integrated verification and port inventory

**Files:** Modify `docs/port-inventory.md` and only code/tests needed for observed integration failures.

**Interfaces:** No new production API. Inventory distinguishes imported starter content and working Human/Fighter gear from item effects and other unported starts.

- [ ] **Step 1: Update** inventory with committed starting-gear artifact, Human/Fighter weapon menu/loadout, version-3 save, and explicit remaining gaps from the spec. Preserve the all-content committed-artifact policy.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./...`, `GOCACHE=/tmp/dcrawl-go-cache go vet ./...`, and focused seeded save/restore tests. Fix concrete failures, then rerun the failed check.
- [ ] **Step 3: Run** all three optional importers' explicit `-check` against the pinned C++ checkout; compare two new artifact generations byte-for-byte. Build/test a temporary copy containing only the Go repository. Launch the terminal, select both an armed and unarmed start, inspect inventory, and verify save/load.
- [ ] **Step 4: Review** the branch diff against the spec, including 25/63/36/32 source coverage, exact six Human/Fighter options, no importer in build/runtime, no version-2 shim, and `git diff --check`.
- [ ] **Step 5: Commit** inventory/integration corrections as `docs: record starting gear and weapon choice status` (or `fix:` for substantive corrections), then request one whole-branch review before local integration.
