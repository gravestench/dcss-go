# Monster weapon loadout catalog

Source: pinned `crawl-ref/source/mon-gear.cc` at revision
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

## Purpose

Early humanoids expose a missing boundary in the Go port: static source
loadout choices belong in immutable content, while each actual weapon belongs
to an Akara item entity carried by its monster. Import the complete declarative
weapon specification tables before adding live monster equipment.

## Imported content

The developer-run importer reads all named weapon lists, named weapon specs,
and the ordered `primary_weapon_specs` and `secondary_weapon_specs` maps in
`make_mons_weapon`. It commits a JSON artifact with source hashes and line
numbers, one record per map entry, weighted weapon and brand choices, optional
plus odds/range/roll count, and optional good-item odds. Preserve
`NUM_WEAPONS` as the explicit no-weapon choice. Resolve named initializer
references into their values while retaining provenance.

The importer checks duplicate entries, positive weights, supported source
syntax, valid monster and weapon identities, and the pinned source revision.
Unexpected expressions fail visibly instead of becoming guesses. A `-check`
mode compares the committed artifact with regeneration. Runtime reads only
the committed JSON and exposes a deep-copy catalog query. The C++ checkout is
never required for play, tests, or a normal build.

The source's switch after these tables changes some monsters' choices
(including kobold and goblin), and `items()` determines actual plusses and
brands. Those rules are separate runtime work. This artifact does not claim
that the tables alone implement monster equipment. The next category will
give supported early humanoids ECS weapon/item state, source item generation,
combat behavior, drops, and save validation.

## Verification

Fixture tests cover named aliases, weighted lists, optional fields, no-weapon
sentinels, and malformed syntax. The pinned source importer must regenerate
byte-identical committed content. Runtime tests check representative entries
and mutation isolation. Full Go test, vet, build, and style gates run at the
category boundary.
