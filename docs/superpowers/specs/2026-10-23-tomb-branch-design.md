# Tomb branch design

## Intent

Make Tomb a complete, playable three-floor branch with its source-authored
one-way route, golden rune, monsters, traps, and Crypt-side entry vaults. The
maps remain the original DES format. Lua owns map selection and the source
scripts' game rules; Go owns only reusable staging, ECS population, travel,
and save validation. A mod can replace or add one map without editing a
central switch.

## Source and scope

The pinned source is `crawl-ref/source/dat/des/branches/tomb.des`. It contains
35 named maps. The final four are labeled old-save compatibility maps; the
active corpus is 31: ten Crypt-side entries, the Tomb:1 whole map and nine
helpers, the Tomb:2 whole map and four helpers, and the Tomb:3 whole map and
five rune helpers. Commit one effective `.des` file per active map, retaining
each MAP block byte-identically. Keep the source map language, but replace
embedded scripts with source-position calls to readable, commented Lua files.
Do not commit or run the disposable extraction tool.

All ten `tomb_entry` maps belong in the Crypt:3 scheduled gate pool. An ending
that already supplies an authored Tomb gate retains its single gate. If it
does not, a fitting entry map supplies the gate, with a plain gate as the
last fallback. Tomb becomes available once its three authored floors can be
built. The Tomb rune is a normal saved rune item and obeys existing pickup
rules. Unrelated monster spell and religion mechanics remain with their
existing domain owners.

## Architecture and travel

`tomb_1`, `tomb_2`, and `tomb_3` each own an authored whole floor. Their
`SUBVAULT` tags select one committed helper from each source pool, and the
source-position Lua hooks set monster pools, trap substitutions, and rune
placement before the final terrain/record projection. Use stable NAME order
for draws; filesystem iteration must never affect seeds.

Tomb's `hatch_name(name)` marks an outgoing one-way linked stair. A matching
`hatch_dest_name(name)` marks its walkable landing, often in another helper.
Resolve these markers **after** substitutions, child placement, and map
transforms, by final coordinates. Any number of outgoing hatches may share a
name: some Tomb:1 centre variants deliberately have four. Each name has
exactly one destination marker, and several names may share a landing cell.
A missing or duplicate destination, blocked endpoint, or wrong-level match
rejects the staged bundle. Tomb:1's ordinary Crypt exit stairs bind back to
the chosen Crypt gate. A hatch does not fabricate a reciprocal stair at its
landing.

At first entry, a Lua Tomb policy builds all three floors and returns a
generic multi-level result to `world.generate_next_floor`. The Go installer
validates and stages all three floors and parent patches in the existing
command checkpoint. It populates each floor once using the same ECS owner as
ordinary generation; inactive floors do not take turns. On failure, terrain,
links, actors, RNG, and pending parent stair remain unchanged. Saves contain
all selected IDs, final hatch links, actors, rune, and floor state. Restore
does not rerun generation.

The source guardian-set balance is local to this three-floor build. It chooses
among the three active sets by least use with source tie breaking, then
disappears. The three duplicated sets inside the old-version source guard
are save compatibility data and are excluded. No process-global or
module-global mutable game state is introduced.

## Verification

Compare all 31 MAP blocks with the pinned source. Load and place every
entry and helper through the production DES path; sample all legal helper
choices, both conditional hook outcomes, trap sets, Khufu chance, and rune
record. Exercise the complete one-way route and return paths, including
landing on plain floor, before and after save/restore. Generate a text
snapshot of each floor with selected helper IDs, named hatch links, and rune
cell. A malformed sparse overlay (duplicate or missing hatch, blocked
landing, missing rune, bad child map) must fail without a partial floor or
spent pending stair. Run focused Lua and Go tests, build, formatting, and
source MAP comparison at the whole-slice boundary.

## Approaches considered

The selected approach stages a complete three-floor bundle. It makes
source-named one-way endpoints concrete before the first Tomb move and
requires one reusable multi-level installer contract. Lazy generation
would have to save unresolved hatch blueprints and extra cross-floor state.
A Tomb-specific Go generator would bury mod rules in the kernel and make
single-file map extension harder.

## Boundaries and constraints

This is one Tomb domain slice and one contiguous implementation commit on
`main`, followed by a push. The 31 active DES maps and production Lua rules
are committed content, never build-time products. No inline Lua belongs in
Go. Lua files explain each function's why and how; keep lines at most 120
characters, prefer 80, and expand multi-field literals. New Lua tests use
`_test.lua` and production schemas. New Go behavior must be generic to any
multi-floor policy result, not keyed on Tomb's branch ID.
