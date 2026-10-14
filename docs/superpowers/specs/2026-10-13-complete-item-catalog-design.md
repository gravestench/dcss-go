# DCrawl Go: complete base item catalog

Date: 2026-10-13

## Purpose and scope

The Go port currently knows only the item kinds needed by starting gear and its fixed Dungeon scenario. This slice gives the port a source-traced catalog of every base item class and concrete subtype in the pinned DCSS tag-34 source. It imports immutable identity, canonical naming information, default ASCII presentation, and the static property tables. It does not claim that every cataloged subtype can be generated, equipped, used, or found in normal play. Those are gameplay rules to port in later slices.

The larger goal remains faithful gameplay and content with Akara ECS for dynamic entities, dense terrain grids, a Bubble Tea/Lip Gloss terminal client, and a new Go save format. Normal Go builds, tests, CI, saves, and gameplay use committed Go content only. The paused C++ refactor is untouched.

## Source and coverage

The pinned source is `/Users/dylanknuth/src/crawl/crawl-ref/source` at Git revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, with `TAG_MAJOR_VERSION=34`. The importer checks the revision and cleanliness of the tracked files it reads, records their relative paths and SHA-256 hashes, and rejects another source revision or tag. Untracked IDE files do not matter. Generated data and the Go repository retain DCSS attribution and license notices.

`object-class-type.h` defines 16 active object classes. Class-specific concrete subtype IDs come from `item-prop-enum.h`, `potion-type.h`, `book-type.h`, and `orb-type.h`. The source mapping is:

| Class | Subtype source |
| --- | --- |
| Weapons, missiles, armour, wands, food, scrolls, jewellery, staves, miscellany, rods, runes | Named enums in `item-prop-enum.h` |
| Potions | `potion-type.h` |
| Books | `book-type.h` |
| Orbs | `orb-type.h` |
| Corpses | `corpse_type` in `item-prop-enum.h`; the corpse's monster is per-instance state |
| Gold | One class-level kind (`OBJ_GOLD`, numeric subtype zero); no subtype enum |

The importer preserves the source class and subtype numeric values as well as stable symbolic IDs. It interprets explicit assignments and gaps, recognizes aliases without creating duplicate kinds, and excludes count constants, range markers, and pseudo-item sentinels such as `OBJ_RANDOM`, `OBJ_DETECTED`, and the weapon values after `NUM_WEAPONS` (`WPN_UNARMED`, `WPN_UNKNOWN`, `WPN_RANDOM`, `WPN_VIABLE`). Every concrete class/subtype pair has exactly one catalog identity, including legacy entries that remain in the tag-34 enums. The full per-class totals are captured from the pinned source in acceptance tests rather than inferred from the current starter subset.

`item-prop.cc` supplies the complete `Armour_prop`, `Weapon_prop`, `Missile_prop`, and tag-34 `Food_prop` rows. The importer includes every field of those static structs, including weapon brand weights, armour flags and size limits, missile damage and mulch rate, food nutrition, prices, and acquisition or generation weights. It resolves the pinned `DRAGON_ARMOUR` and brand-table forms. Other classes have identity and naming information but no invented property table. `item-name.cc` supplies subtype names and naming cases; `show.cc` and the ASCII character set in `viewchar.cc` supply default class/subtype glyphs. If an item name depends on instance state, such as a manual's skill or a corpse's monster, the artifact records a naming kind and the fixed source text rather than a false complete name. Unique and random artefacts in `art-data.txt` and related code are separate content slices; they refer to these base kinds later.

DCSS's `removed_items` list in `item-prop.cc` is only one source signal. Other legacy entries remain in property tables or have “removed” display text, and generation code makes additional exclusions. The catalog records the explicit `removed_items` membership and source naming/property evidence separately. It does not collapse those facts into a guessed `spawnable` boolean. Generation eligibility is defined when item generation is ported. A known identity with no source definition remains inspectable but cannot be silently treated as a fully defined item.

## Approaches considered

1. **Complete base identity and static-property catalog (selected).** This gives every later item, equipment, combat, spell, and generation slice stable source IDs while keeping behavior in its owning domain. It requires a broader importer now.
2. **Weapon and armour data first.** Combat could start sooner, but the Go port would retain two item-definition paths and need a later catalog migration.
3. **Combat on the current starter fixture.** This is a short route to visible play changes, but formula work would depend on incomplete item data and require rework for ordinary loot.

## Import artifacts and boundaries

`cmd/importitems` is an optional developer command backed by `internal/content/itemimport`. Explicit `-source`, `-out`, and `-check` options match the existing content tools; `-out` names `items.json` and the manifest is its sibling. A normal refresh generates and validates both outputs before atomically replacing each of `internal/content/generated/items.json` and `item-identities.json`; runtime cross-validation detects any interrupted two-file refresh. `-check` regenerates in memory, reports stale output, and changes neither file. Both outputs are deterministic: stable class/ID ordering, stable field and source-hash order, and no timestamps. Records retain relative source paths and line numbers for their identity, name, and property rows; no developer-specific absolute path enters an artifact. The importer parses only the pinned syntax needed for these source files; unfamiliar preprocessor conditions, macros, expressions, rows, or enum references fail with source file and line context rather than being skipped.

The identity manifest is derived directly from the class and subtype enums, independently of the name/property row decoder. It records class ID and numeric value, subtype ID and numeric value, alias exclusions, and the source file hashes. A separate scan of the source `removed_items` initializer records its exact class/subtype pairs in the manifest; it does not infer removal from display names. `items.json` is built from the joined enum, name, presentation, explicit-removal, and property views. Startup compares exact identities, numeric values, and explicit-removal membership against the manifest, so a missing or substituted row cannot pass merely because counts match. The manifest also lists the allowed symbolic vocabularies for property fields such as equipment slots, skills, sizes, ammunition, damage flags, brands, and armour flags. Shared source hashes and revision must agree with the existing job and starting-gear artifacts.

`content.Catalog` privately owns the immutable item index. `Catalog.Item(id)` returns a copy of a fully defined base kind; an inspection/listing API exposes all identities and source signals without implying that every identity is playable. Item definitions use class-specific typed property values rather than an unstructured bag or a large set of unrelated optional numbers. Validation ensures the property shape matches the class, symbolic references exist, and nested slices cannot mutate catalog data. The default source glyph and stable name data remain available to the terminal view. Mutable item quantity, enchantment, charges, brand/ego, identification, location, carrier, and equipment state belong to Akara entities or later game-owned state, never to the catalog.

The committed starting-gear artifact advances its own schema and stops carrying duplicate `ItemDef` records. Its ordered grant IDs and raw source specs remain. The developer importer validates grant resolution against the complete item vocabulary; `content.LoadDefault` loads the item catalog before starting gear and verifies every grant, chosen weapon, and fixed floor potion against it. No compatibility layer keeps the duplicate runtime definition map. The stable item IDs in existing Go version-4 saves do not change, so this catalog migration alone does not bump the save schema. Restore continues to reject unknown IDs and invalid per-instance combinations; it does not pretend to validate unported generation eligibility.

## Errors and verification

Import fails before writing if the source revision/tag differs, a tracked interpreted file is modified, an enum numeric expression is unsupported, a concrete ID is missing or duplicated, an alias is treated as a new kind, a property row is missing or extra, a source name is ambiguous, or a property symbol cannot be resolved. Runtime loading rejects artifact metadata, identity, numeric, source-hash, ordering, and reference mismatches with an ordinary startup error. The fixed scenario keeps its current item behavior until later gameplay slices replace it.

Acceptance checks:

1. Every active one of the 16 object classes and every concrete tag-34 subtype is represented exactly once; aliases, range/count markers, pseudo-items, numeric gaps, and the gold singleton have explicit golden tests. The test records exact per-class counts from the pinned source.
2. All four source property tables have exact row coverage and representative golden values, including an expanded dragon armour, a weapon with brand weights, a removed ammunition ID, and a food record. No recognized source field is silently dropped.
3. Independent enum-manifest tests reject a same-count ID substitution, wrong numeric subtype, unknown symbol, omitted row, duplicate class/subtype pair, and swapped explicit-removal membership. Negative parser fixtures cover conditional branches, aliases, dynamic names, nested brand data, and unsupported syntax.
4. Two complete imports are byte-identical. `-check` accepts committed artifacts and rejects stale bytes without modifying them. Catalog reads and listings return defensive copies.
5. Starting gear, weapon choice, the fixed potion, inventory display, seeded turns, and version-4 save/restore remain deterministic. A Go-only copy of the repository builds and tests without the C++ checkout. `go test ./...`, `go vet ./...`, `go build ./...`, and a terminal smoke check pass before integration.
6. `docs/port-inventory.md` distinguishes imported base item definitions from unported item effects, identification, equipment changes, generation, artefacts, and combat rules.

## Follow-on work

This slice does not implement item generation or spawn weights, unidentified appearances, artefacts, randart properties, equipment restrictions, inventory commands beyond the current fixture, item use, food effects, ranged attacks, melee formulas, shops, or C++ save compatibility. Those remain part of the full port goal. Every later content importer likewise commits its generated output; normal Go builds and play never refresh from C++ automatically.
