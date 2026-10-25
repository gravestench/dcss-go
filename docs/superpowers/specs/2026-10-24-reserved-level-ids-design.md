# Reserved Level IDs

## Problem

The two permanent Abyss regions use IDs 1000 and 1001. Ordinary branches
use `numeric_id * 100 + depth`; Slime:1 is therefore also 1001. The second
Lair branch entrance can be rejected before Slime is entered because its
pending target appears to exist already. The pinned Jiyva-to-Slime test
reproduces this in the current `main` baseline.

## Design

Reserve IDs at 1,000,000,000 and 1,000,000,001 for the moving Abyss and
its inert transit region. They are positive and exactly representable in
both Go integers and Lua numbers. Ordinary branch IDs must stay below this
special namespace. The existing Lua Abyss constant owner and Go session
owner hold the two values; tests and fixtures import their local owner's
constant rather than repeating the old integers.

The game continues to save concrete level IDs. Existing snapshots made
with the old ID assignment have a different ruleset hash and are not
silently reinterpreted as Slime floors.

## Verification

An effective-catalog Lua test enumerates every active branch floor and
asserts uniqueness and disjointness from both special IDs. The existing
Jiyva-to-Slime journey, Abyss storage/transit tests, and save/restore tests
exercise live paths. A staged invalid branch ID cannot enter the reserved
range. If the longer Jiyva journey exposes another failure after it reaches
Slime, that is diagnosed and tracked as a separate gameplay category.
