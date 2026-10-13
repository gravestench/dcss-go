# DCrawl Go: source-traced monster catalog import

Date: 2026-10-13

## Purpose and scope

The Go port needs the full monster definition table before monster combat, spawning, and generation can be ported faithfully. This slice replaces the hand-written rat definition with a committed, source-traced catalog for the pinned DCSS tag-34 monster table. It imports immutable definitions only. Live monsters remain Akara entities whose health, position, inventory, intent, and turn state are owned by the game session.

This is one content category in the wider goal: faithful gameplay and content, a new Go save format, dense terrain grids, explicit owners, and a Bubble Tea/Lip Gloss terminal client. The fixed Dungeon scenario remains playable. The paused C++ refactor is untouched.

## Source and coverage contract

The source of truth is `/Users/dylanknuth/src/crawl` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, under `crawl-ref/source`, with `TAG_MAJOR_VERSION=34`. The primary files are `monster-type.h` (IDs and aliases), `mon-data.h` (table and `AXED_MON` records), `mon-util.h` (the `monsterentry`, attack, tile, and energy layouts), `mon-enum.h` (attack vocabularies), and `tag-version.h`. The importer records hashes for every file it actually interprets, including any other supporting enum or macro definitions. It rejects another revision or tag rather than silently combining sources.

At this revision, the active, non-alias `MONS_*` enum has **700 IDs**. `mon-data.h` has **562 explicit entries** and **120 active `AXED_MON` records**. The remaining **18 enum-only IDs** have no table entry; they include genus and special placeholders such as `MONS_BEAR` and `MONS_PLAYER`. These are coverage categories, not 700 spawnable monsters. The importer must account for each ID exactly once as `defined`, `removed`, or `enum_only`, and reject duplicates, extras, and omissions. Alias and sentinel values such as `MONS_0`, `NUM_MONSTERS`, `MONS_NO_MONSTER`, and `RANDOM_*` are not monster definitions.

The source files and imported definitions retain upstream attribution and license notices in the Go repository. Source paths in the artifact are relative to `crawl-ref/source`, so the artifact is independent of the developer's machine path.

## Approaches considered

1. **Category importer plus committed artifact (selected).** A developer intentionally refreshes one deterministic JSON artifact from the pinned C++ checkout. Ordinary builds, tests, and runs read only committed Go repository content. This matches the existing species, jobs, gear, and presentation imports and gives reviewable diffs.
2. **Hand-written monster definitions.** This keeps the runtime simple for one rat but makes complete coverage and source fidelity hard to verify.
3. **Parse C++ definitions during build or launch.** This couples the Go project to a C++ checkout and moves content failures into normal gameplay. It also violates the agreed content-import policy.

## Importer and artifact

`cmd/importmonsters` is an optional developer command with explicit `-source`, `-out`, and `-check` options, backed by `internal/content/monsterimport`. It never writes to the C++ checkout. Normal `go build`, `go test`, CI, and gameplay do not invoke it. A successful refresh writes `internal/content/generated/monsters.json` atomically; `-check` regenerates in memory and fails if bytes differ without changing the file. Output has stable ID order, stable field order, stable source-file hash order, and no timestamp.

The importer uses the existing narrow tag-34 conditional handling where applicable. It scans balanced C++ initializers, parentheses, and quoted strings across line breaks so nested attacks, tiles, and resistance expressions such as multiline `mrd(...)` calls cannot be mistaken for row boundaries. It expands the pinned `AXED_MON` form. It supports only the source constructs present in this pinned category; an unfamiliar directive, macro, expression, field count, or enum token fails with file, line, and monster ID when available. It is not a general C++ parser.

The versioned artifact contains source revision, tag, sorted file hashes, and one record for every active non-alias enum ID. Records are sorted by ID and carry source path, source line where a table row exists, and one of the three statuses. `removed` records keep their ID and source name but cannot become live monsters; `enum_only` records keep their ID and cannot become live monsters. Explicit definitions retain all `monsterentry` information:

- ID, glyph, display colour, name, class flags, resistances, experience modifier, genus, species, holiness, and willpower;
- all four ordered attacks, each with type, flavour, and damage; hit dice, average HP multiplied by ten, armour class, and evasion;
- spellbook ID, corpse availability, shout, intelligence, habitat, speed, all eight energy usage values, item-use class, size, and body shape;
- tile ID and variation, plus corpse tile ID.

Plain enum values remain stable symbolic IDs (`AT_BITE`, `MST_NO_SPELLS`, etc.) until their gameplay domain is ported. Numeric values are stored as numbers. Flags become validated symbolic sets, resistance levels become explicit values per resistance type, and energy macros/combinations become the eight resulting numeric values. The importer interprets the pinned expressions according to their source definitions, including aliases and defaults; it does not put opaque C++ expressions in the runtime artifact. It rejects expressions it cannot resolve exactly. Optional display names and zero speed/HP are valid for some nonspawnable definitions, so validation uses status and source flags rather than blanket “all monsters have a name and positive speed” rules.

References such as genus/species IDs, attack symbols, and spellbook IDs are checked against the active source vocabularies. A reference to an enum-only genus is valid; it does not make that genus instantiable. The importer checks the full 700-ID partition against `monster-type.h` and verifies every explicit row matches the `monsterentry` layout. It does not silently drop a row because later gameplay cannot use it yet.

## Runtime ownership and current scenario

`content.LoadDefault` embeds and validates the committed monster artifact alongside the existing artifacts. The catalog privately owns its ID index and returns copies of records and nested slices/maps. `Catalog.Monster(id)` returns explicit definitions, including source-marked nonspawnable definitions needed as references, and reports a clear error for removed, enum-only, and unknown IDs. The catalog also exposes an ordered listing and status lookup so coverage is inspectable without confusing placeholders with live monster types. It checks schema, revision, tag, source-file metadata, duplicate/order/coverage errors, and source references before a session is created. There is no mutable package-global monster registry.

The fixed Dungeon rat reads its canonical ID, glyph, speed, and attack definition from `MONS_RAT`. Its current **4 HP and simple 3-damage melee model remain explicit scenario rules** until HP generation and combat are ported; they are not fields of the monster catalog. Any mapping from the rat's first source attack to the simple scenario damage must be explicit and checked, so later combat work can remove it cleanly. The rat-only `MonsterDef` fixture is removed. Existing save snapshots keep live entity state and monster IDs; this immutable catalog change does not require a save-format version change. Restore validates monster IDs through the new catalog.

## Errors and verification

The importer fails before writing on a wrong Git revision or tag, malformed initializer, unsupported expression, unknown reference, duplicate ID, missing ID, bad status partition, or unexpected source layout. Errors identify the source file and row/ID when known. Runtime loading rejects invalid artifact schema, revision, ordering, references, or metadata with a normal startup error.

Acceptance checks:

1. Two imports from the pinned source produce byte-identical output. `-check` passes for committed output; a stale artifact fails and remains unchanged.
2. The artifact partitions all 700 active non-alias IDs into 562 explicit, 120 removed, and 18 enum-only records. Tests verify aliases and sentinels are excluded.
3. Golden records cover `MONS_RAT` (including four attacks and average HP `25`), a caster, a multi-resistance monster, a nondefault energy monster, a removed ID, and an enum-only ID. Negative fixtures cover nested-initializer damage, duplicate/missing IDs, unsupported constructs, and invalid references.
4. Catalog reads and listings cannot mutate the stored data. Removed and enum-only IDs cannot be instantiated by the scenario or restored as live monsters.
5. `go test ./...`, `go vet ./...`, the existing seeded Dungeon and save/restore checks, and a clean Go-only build pass without access to the C++ checkout.
6. `docs/port-inventory.md` marks monster definitions imported while monster AI, combat, spells, spawning, generation, corpses, loot, and experience remain separately tracked.

## Follow-on work

This slice does not port monster behavior, attack resolution, HP rolls, resistance effects, spellcasting, spawn weights, branch populations, procedural generation, corpse or loot rules, or C++ saves. Later domain slices consume the imported definitions and replace the temporary fixed-scenario rules. Importers remain developer tools for intentional upstream refreshes; committed generated content remains sufficient to build and play the Go game.
