# DCrawl Go: job catalog and character choice

Date: 2026-10-13

## Purpose and scope

This slice advances the faithful DCSS-to-Go port from imported species definitions to source-backed jobs and character choices. It imports every concrete job definition compiled by the pinned tag-34 C++ source, preserves both directions of species/job recommendations, reproduces normal Dungeon choice bans, and applies species-plus-job starting attributes to the existing Human/Fighter scenario. The game remains playable only as Human/Fighter until starting equipment, spells, weapon-dependent skills, mutations, HP, and other character effects have their own implementations. Imported data and choice availability must never be described as a complete character-generation port.

The Go runtime remains one game with Akara ECS for dynamic entities, dense level terrain, explicit ownership, Bubble Tea/Lip Gloss for the ASCII client, and a versioned Go save. The paused C++ refactor is unchanged.

## Source of truth and observed behavior

The C++ reference is `/Users/dylanknuth/src/crawl` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, `TAG_MAJOR_VERSION=34`. `crawl-ref/source/job-data.h` supplies 31 `job_def` records and their order-sensitive spell, equipment, and skill lists; `job-type.h` supplies the active concrete IDs. Twenty-five jobs have nonempty `recommended_species` and are starting jobs. Six tag-34 jobs have empty lists and are removed from character selection: Death Knight, Healer, Jester, Priest, Skald, and Stalker. `jobs.cc` defines that rule. `species.cc` treats a valid species with nonempty recommended jobs as a starting species; the species artifact already marks the 27 matching records selectable.

`ng-restr.cc` separates legality from recommendation. No-grasping species cannot start as Gladiator, Brigand, Hunter, or Arcane Marksman. Forlorn species cannot start as Berserker, Chaos Knight, Abyssal Knight, Cinder Acolyte, or Monk. Fully undead species cannot start as Transmuters. The first two predicates use `species::mutation_level`, which checks whether the species ever gains the mutation, rather than only whether it has the mutation at level 1. For normal Dungeon, the pinned source gives 27 starting species, 25 starting jobs, and 664 legal pairs after these 11 bans. Sprint-specific exclusions are outside this slice.

The two recommendation views are intentionally distinct. `job_allowed(species, job)` uses the **species** definition's `recommended_jobs` for the species-first menu; `species_allowed(job, species)` uses the **job** definition's `recommended_species` for the job-first menu. A pair can be legal even when neither list recommends it: Human/Fighter is the regression case. `species_stat_init` sets base Strength, Intelligence, and Dexterity from the species record; `job_stat_init` adds the job's three modifiers. `_unfocus_stats` can later adjust the result. Wanderer is selectable but its displayed zero modifiers are placeholders for randomized setup in `ng-wanderer.cc`; this slice does not treat them as a complete Wanderer start.

## Approach selected

Use a job-specific build-time importer and checked-in artifact, matching the species import pattern, followed by pure choice and attribute rules in a small `character` package. This keeps normal builds independent of the C++ checkout and keeps mutable game state in ECS. Importing only hand-selected jobs would lose parity and provenance. Exposing every legal pair as playable now would present incomplete starting effects as faithful gameplay. Porting every start effect in this slice would mix job import with item, spell, mutation, religion, skill, HP, and Wanderer systems before their dependencies exist.

## Import and catalog design

`cmd/importjobs` accepts `-source`, `-out`, and `-check`, with the same pinned revision and atomic-write semantics as `cmd/importspecies`. `internal/content/jobimport` parses the limited brace-initializer grammar in the pinned `job-data.h`: one `JOB_*` key and exactly the defined fields in order, quoted abbreviation/name, three signed integer modifiers, ordered species and spell IDs, ordered equipment strings, one `WCHOICE_*`, and ordered skill/amount pairs. It evaluates only the tag-34 conditional forms actually present in the source. Comments, whitespace, trailing commas, and quoted commas are handled explicitly. Unsupported preprocessor or initializer syntax is an error naming the source location; the importer must not silently skip a job.

The importer validates the 31 records against the concrete active `job-type.h` enum, each recommended species against `species-type.h`, each spell against a concrete active `spell-type.h` ID before its sentinel (never `SPELL_NO_SPELL`), and each skill against an active ordinary `skill-type.h` ID or the character-creation placeholder `SK_WEAPON`. It checks unique job IDs and abbreviations, the three `WCHOICE_*` values, signed integer stat modifiers, and skill grant amounts in `0..27`. A narrow shared tag-34 source scanner can be extracted from `speciesimport`; this is shared parsing behavior, not a general C++ compatibility layer. Both importers continue to reject a checkout at another Git revision or with modified tracked source files.

The generated `internal/content/generated/jobs.json` has schema version 1, source revision, tag major version, sorted source-file SHA-256 hashes, and job records sorted by stable ID. Each record retains source path, stable ID, abbreviation, name, stat modifiers, ordered recommendations, spell library, equipment specs, weapon-choice enum, and skill grants. `Selectable` is derived from nonempty `recommended_species`; the six removed definitions remain in the artifact. The existing upstream `LICENSE` covers imported content.

`content.LoadDefault()` embeds and validates the species and job artifacts together. It rejects mismatched revisions, tags, schemas, missing/duplicate records, malformed provenance hashes, and invalid species/job references. Without the C++ checkout at runtime, the hashes provide reviewable provenance rather than a runtime rehash of source files. `Catalog.Job(id)` and `Catalog.JobIDs()` provide defensive copies and stable order. `Catalog.Validate()` requires the fixed scenario's job to exist. No mutable package-level job registry is added.

## Choice, attributes, and runtime flow

`internal/character` contains pure functions that accept `content.Catalog` and stable species/job IDs. It returns a three-way result—banned, restricted, recommended—for both menu directions, using one shared banned-pair predicate and each direction's own recommendation list. Unknown IDs and removed/nonselectable definitions are rejected explicitly. A separate `BaseStatSum` function adds the species values and job modifiers for legal fixed-stat jobs. It rejects Wanderer as a randomized start, and it does not claim to apply `_unfocus_stats` or later stat changes. These functions perform no ECS mutation and own no global state.

`game.NewScenario` continues to create Human/Fighter in the fixed Dungeon. It calls the choice and `BaseStatSum` rules, rejects an invalid catalog pair, and stores the three resulting attributes as an ECS player component. The game view and terminal status show these attributes and the source-backed character name. Existing fixture HP, speed, and base damage remain clearly fixture behavior; job skill grants are imported but not applied until weapon/equipment and skill rules exist. The data model must not imply that raw `SK_WEAPON` is an ordinary trained skill. A later character-creation flow can reuse the same eligibility and attribute rules when all starting effects are ready.

The save schema advances to version 2 and stores the player attribute component. Restore validates exactly one such component on the player, positive resulting values, absence on monsters/items, and that the saved species/job pair remains legal and its starting attributes match the imported catalog for this slice. Version-1 saves are rejected by the version check; no compatibility shim is added. Seeded save/restore continuation must remain deterministic.

## Errors, verification, and completion

Importer errors identify source file, job ID, and field where possible. An import failure or stale `-check` never rewrites the checked-in artifact. Runtime loading returns errors rather than panics. A bad choice cannot partially construct a game; a bad save cannot modify the live game.

Acceptance checks:

1. Repeated import produces identical bytes; `-check` passes against the checked-in artifact, fails on stale bytes without changing them, and rejects wrong source revision/tag or dirty tracked source.
2. All 31 active jobs appear once with the exact 25 selectable and six removed classifications. Golden checks cover Fighter modifiers/gear/skills, a spellcasting job, a weapon-choice job, Wanderer's randomized placeholders, and a removed tag-34 job. Malformed, duplicate, missing, or unknown-reference cases fail with context.
3. The two recommendation directions stay distinct; Human/Fighter is legal but restricted both ways. The normal Dungeon matrix has 664 legal and 11 banned pairs. Explicit tests cover Felid's four no-grasping bans, Demigod's five forlorn bans, and Ghoul/Mummy Transmuter bans, plus nonselectable species and removed jobs.
4. Human/Fighter starts with imported base attributes `16/8/12` (Human `8/8/8` plus Fighter `8/0/4`), visible in the terminal and present in the ECS player entity. Scenario HP and damage remain their existing controlled values.
5. A version-2 save restores attributes and gives identical seeded continuation. Missing, duplicate, misplaced, or mismatched saved attributes and version-1 saves are rejected without changing the live game.
6. `go test ./...`, `go vet ./...`, generated-artifact checks, and a terminal startup pass. `docs/port-inventory.md` identifies job definitions, normal Dungeon eligibility, and base attributes as implemented while keeping equipment, spells, skills, mutations, HP, Wanderer starts, Sprint choices, and full character creation unported.

## Next dependency order

The next character slice ports starting item definitions/equipment and weapon choice, then skill grants and their reassessment; spell libraries, innate mutations, religion starts, HP/MP, `_unfocus_stats`, and Wanderer randomization follow as their content dependencies land. Combat, advancement, monsters, visibility, generation, branches, vaults, religion, and parity closure remain part of the full port goal. Each later slice must update the inventory against the pinned source before any broad completion claim.
