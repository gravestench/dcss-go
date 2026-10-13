# DCrawl Go: Human/Fighter starting profile

Date: 2026-10-13

## Purpose and boundary

Finish the source-backed character values for the existing Human/Fighter normal Dungeon start. After the weapon is chosen, the player begins with the pinned DCSS starting skill grants, reassessed Human skill levels and points, and starting HP/MP. The Bubble Tea client shows those values, and a new Go save version preserves them. The fixed two-floor map, rat, gear, and turn loop remain the playable scenario. This is one creation slice, not a claim that other species or jobs are ready to play.

The intended port remains faithful in gameplay and content, with a new Go save format. Dynamic actors and items remain Akara ECS entities; terrain remains a dense level grid. All content used by normal builds and play comes from committed Go-repository artifacts. The pinned C++ checkout is a source reference for intentional development, never a build or runtime dependency. This slice needs no new content importer: the committed species and job catalogs already contain Human aptitudes, HP/MP modifiers, Fighter skill grants, and weapon choice metadata.

## Pinned source trace

The reference is `/Users/dylanknuth/src/crawl/crawl-ref/source` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, `TAG_MAJOR_VERSION=34`.

`ng-setup.cc:_setup_generic` initializes species and job stats, unfocuses any base stat below three, applies mutations, grants equipment and skills, calls `reassess_starting_skills`, then calculates HP/MP and fills both pools. `species.cc:species_stat_init` and `jobs.cc:job_stat_init` add the table attributes; the existing Go `BaseStatSum` already yields Human/Fighter Str 16, Int 8, Dex 12, so unfocusing changes nothing for this pair. The spec does not generalize that shortcut to other pairs.

`job-data.h:JOB_FIGHTER` grants Fighting 3, Shields 3, Armour 3, and `SK_WEAPON` 2. `jobs.cc:give_job_skills` resolves `SK_WEAPON` from the equipped chosen weapon, or Unarmed Combat if there is no weapon. The current six Human/Fighter choices therefore share the first three skills and put the final two levels into the chosen weapon's skill. The no-grasping Fighter bonus does not apply to Human. Skill assignment happens after the chosen weapon and job gear are created; an unarmed start must never acquire a phantom weapon.

`skills.cc:reassess_starting_skills`, `skill_exp_needed`, `apt_to_factor`, and skill progress convert the granted levels into skill points at Human costs, then into effective starting levels under the species aptitude. Preserve integer truncation and the source's `+1` point convention. Human's relevant aptitudes are zero, so the four granted levels remain 3/3/3/2 for this slice. The source-derived point totals are 301 for each level-three skill and 151 for the level-two chosen skill; all other ordinary skills start at zero. Keep both level and points because later training depends on points, and use stable `SK_*` IDs rather than presentation names.

`player.cc:get_real_hp` at experience level one starts with `1*11/2+8`, adds Fighting contributions, applies Human's zero HP modifier, and has no active mutation, item, form, religion, or drain adjustment in this start. It yields max HP 18. `player.cc:get_real_mp` starts from level one plus zero Spellcasting/Invocations, applies Human's zero MP modifier, and yields max MP 1. Both pools start full. These are source-traced initial values, not fixed values to be reused after leveling, mutation, equipment effects, or damage. The existing player base damage 4 and rat combat remain scenario fixtures and must be labeled as such.

## Approaches considered

1. **Complete the current start (selected).** Make a pure Human/Fighter starting-profile calculation, store the result on the ECS player, and serialize it. This replaces the current HP fixture with a source value while giving later advancement and combat slices a clear skill/MP owner.
2. Open every legal species/job pair immediately. Although the catalogs contain 664 legal pairs, source setup also branches through mutations, religion, spells, random Wanderer setup, body restrictions, and skill reassessment. Starting all pairs now would overstate gameplay fidelity and combine several domains into one change.
3. Port weapon combat before character values. That would make attacks more interesting while leaving starting Fighting and HP as fixtures, requiring the combat rules to be revisited as soon as creation is fixed.

## Ownership and data flow

`character` owns pure starting-profile rules. An explicit function accepts the immutable catalog, species ID, job ID, and selected weapon ID, validates that this is the supported Human/Fighter normal Dungeon start, resolves the chosen weapon skill through `content.ItemDef`, and returns attributes, ordered skill entries (`SK_*` ID, level, points), max HP, and max MP. It does not mutate ECS or read a package-global game. The calculations should be broken into small named rules for job grants, reassessment, HP, and MP, with source anchors in comments where a formula is otherwise opaque. The public result is immutable by convention and copied at the game boundary.

`game.NewScenario` is the creation coordinator. It validates the catalog and weapon, creates the chosen weapon and ordered Fighter gear, computes the starting profile after equipment is known, then installs `Attributes`, a `Skills` component, `Health`, and a `Magic` pool on the player entity. The skill component is a deterministic collection of stable IDs and point/level values, with no shared mutable backing storage. Only the player has these character-specific components in this slice. Existing monster health is unaffected. The game view exposes HP/MP and the skill list; the terminal status line shows both pools, and a character-information view presents source names and levels without spending auts. Core creation math stays out of Bubble Tea.

Go save version 4 records the player skills and MP alongside existing attributes, HP, gear, selected weapon, RNG, and turn state. Restore continues to build a separate game, validates one player, unique legal skill IDs, nonnegative points, consistent source-derived initial skills for this no-training slice, MP bounds, and player-only ownership of these components before replacing the live game. It rejects version-3 saves explicitly; no compatibility shim or C++ save support is added. A failed load leaves the current game untouched. Snapshot copying must deep-copy any skill collection.

The source-derived initial profile is calculated at character creation. Later mutations, skill training, level gains, consumables, equipment changes, and full recalculation rules require their own gameplay slices. The current runtime must not silently reapply the level-one formula after damage or across a save/load.

## Errors and acceptance checks

Invalid species/job/weapon combinations, missing catalog skill or weapon metadata, duplicate skill IDs, impossible points/levels, and invalid saved MP fail with context. Source-backed rules use only the committed catalog; they do not run an importer during ordinary tests or play.

1. Pure tests cover all six Human/Fighter weapon options, including unarmed: exactly Fighting 3, Shields 3, Armour 3, and the chosen weapon skill 2, with 301/301/301/151 points and all other skills absent or zero. Base attributes remain 16/8/12; max HP is 18 and max MP is 1. Invalid choices fail without partial state.
2. A new game creates those components once, starts both pools full, retains the existing gear and fixed-map behavior, and consumes zero auts during character selection or inspection. Damage lowers current HP without changing the initial max.
3. Save/restore round-trips the profile and deterministic continuation. Corrupt skill IDs, duplicate entries, altered points or levels, MP outside `[0,max]`, misplaced character components, and old versions fail atomically.
4. The terminal visibly reports HP/MP and skill levels. Focused rule, game, save, and terminal tests pass; the integrated `go test ./...` and `go vet ./...` pass. A Go-only checkout builds and tests without the C++ source.

The inventory records this slice as source-backed initial Human/Fighter skills and HP/MP, while keeping combat damage, skill training, advancement, mutations, spells, other starts, and procedural generation marked unported.
