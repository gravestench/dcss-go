# Demonspawn Facet Schedule Design

## Intent

Port Demonspawn's character-creation trait roll and level schedule as one
playable domain. This is needed for Demonspawn growth itself and for Ru's
Frail offer rule, which checks a future Robust facet before that mutation
has appeared. The schedule must be saved player state, not a fresh roll
performed when a level is gained or a save is restored.

## Ownership

Each source facet is an individually discoverable Lua definition under
`content/demonspawn_facets/`. The definition names its stable ID, tier,
three ordered mutation IDs, three source timing windows, and any body slot
or selection exclusion group. This keeps additions and replacements in
the same layered mod system as other content. A focused Lua catalog
validator checks each definition before a character can roll it.

The player owns a set of `character.demonspawn_trait` ECS records. Each
record names its player, facet ID, rank within that facet, mutation ID,
and scheduled experience level. There may be repeated mutation IDs but
only one trait per level. The
records contain the whole future plan, including traits that have not
yet appeared. Other policies read these records through one
`policy.character.demonspawn` owner rather than inspect storage directly.
The mutation owner continues to hold granted ranks. A player-owned
`character.demonspawn_ancestry` record stores the highest level reached,
so saved grant flags remain verifiable after Ru lowers current level.

## Source algorithm

At creation, a Demonspawn selects one body facet, one scale facet, two
tier-two facets, and one tier-three facet. One in ten instead selects
three body facets, no scale facet, two tier-two facets, and one tier-three
facet. Facets are unique and body slots do not overlap. The source also
retries a selection if it contains more than one elemental or cloud
producing facet. Each selected facet contributes three ordered mutation
grants. Timing windows place body and scale grants earlier and tier-three
grants later, while preserving order within one facet. The selected
facets must also fit the rank cap of every mutation they name. The
effective catalog is validated before the player receives a schedule.
Its 15 or 18 grants are assigned distinct levels from XL2 through XL27;
the first grant always occurs at XL2. A named persisted Demonspawn RNG
stream makes this independent of file load order and unrelated actions.

The level-up owner grants all records scheduled at the attained level
through the existing permanent mutation transition, before computing HP
and MP. Reaching a level again after Ru's Experience loss must not grant
the same rank a second time. Validation checks record ownership, known
mutation IDs, level bounds, unique level assignments, source facet shape,
and consistency between the attained schedule and innate ranks.

## Consumers and compatibility

Ru's variant validity rejects Frail when the saved Demonspawn schedule
contains Robust, even if the character has not gained a Robust rank.
Other species have no Demonspawn trait records. The source's mutation
effects remain in their existing focused Lua owners; this slice wires
their scheduled acquisition rather than duplicating effect handlers.

New ECS schema and content manifest changes will make older Go saves
incompatible. The committed Lua definitions are authoritative at runtime;
no C++ checkout or importer runs during builds. Mod overrides use the
same relative paths and stable IDs as the base definitions.

## Verification

Use production definitions in Lua tests for selection counts, all facet
constraints, grant ordering, saved schedule validation, Ru eligibility,
and level loss/regain. A Go game test starts several seeded Demonspawn,
checks save/restore and level grants, and checks non-Demonspawn state.
Run focused Lua and Go suites and build `cmd/crawl` after the category.
