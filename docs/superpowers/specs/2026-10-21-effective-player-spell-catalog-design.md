# Effective Player Spell Catalog

## Intent

Give every player-spell consumer one meaning for "in a player book". The
current base book files and frozen `data/player_book_spells.lua` both name
109 spells, but the frozen copy ignores sparse mod additions and replacements.
The effective registered book definitions must decide eligibility at runtime.

## Ownership

`policy/magic/player_book_catalog.lua` reads the effective item and spell
catalogs. Its `ids()` returns book membership and its `ordered()` returns
defined book spells in source numeric-ID order, then modded spells without
a source ordinal in stable ID order. A book contributes its
`generation.spells` entries. Missing referenced spell IDs fail with the
catalog's normal error instead of silently disappearing. The owner caches
the derived membership set after registration freezes, because spell-scope
checks otherwise copy every item definition for every spell. It returns a
copy to callers. Registry accessor replacement in tests invalidates the
cache; before freeze it always recomputes. Definitions cannot be registered
after freeze, so no live mod change can go stale.

Wanderer gifts, Djinni future spells, random book generation, player spell
scope, and effect coverage all consume this owner. The source's fixed
nonbook invoked spell set remains a separate Lua declaration because no
book definition can derive it. Explicit `player_scope` on a spell definition
still takes precedence when classifying an individual spell. Effect coverage
must include both effective book spells and invoked spells.

The generated source list is removed after equivalence is verified; there
is no second runtime book registry or compatibility adapter. Existing book
files remain the committed, individually replaceable source of truth.

## Fidelity and mod contract

The base catalog has exactly the same 109 book IDs as the old source list.
Adding a registered spell ID to an effective book makes it visible to every
player-book consumer. Removing the last book reference removes its BOOK
scope and gift/random-book eligibility. Source spells keep numeric enum
candidate order. Mod spells may omit `numeric_id` and sort after source
spells by stable ID, independently of Lua file load order.

## Verification

Lua tests compare a stable digest of the complete base effective set with
the former source set, then use registry overrides to add and remove a book
entry. They
exercise scope, Wanderer/Djinni candidate pools, random-book generation,
and effect coverage through production owners. Focused Go integration tests
exercise a Djinni start and save/restore. Run all-package compilation,
changed-file style and line checks, and one fresh code review before the
single category commit on `main` and push.
