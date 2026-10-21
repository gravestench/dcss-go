# Vaults Primary Layouts Design

## Purpose

Make the scheduled Vaults entrance lead to source-shaped Vaults:1–4 floors.
The category includes all 11 primary layout definitions in the reference
`layout_vaults.des` and the tagged room content those layouts use. Vaults:5
has a distinct source end-vault builder and rune encounter; it is the next
category, not a fifth generic room layout. The existing branch topology,
Akara actors, dense level grid, Go save, and layered Lua VFS remain the
runtime owners.

The intent is playable breadth, not a one-layout sample. A new room or
layout remains addable by placing a `.des` file and, for a procedural shape,
one named Lua hook file at the expected relative path. No source importer or
C++ checkout is needed during build or play.

## Source content and discovery

Commit one source-style `.des` file per source primary layout. Preserve
NAME, tags, weight, orientation, and map declarations. Replace executable
source Lua lines with named `vault.run` hooks in actual Lua files. Every
source room carrying `vaults_room`, `vaults_hard`, or `vaults_empty` is
committed as its own named `.des` file. The three dedicated source files
alone contain 99 standard, 58 hard, and 93 empty definitions. Many standard
rooms receive their tag from a source setup hook, and other tagged rooms
live in separate source files; the import must include those too. Source
hooks in those room maps become named Lua modules or equivalent source
directives at the original position. Unsupported source instructions must
cause a named load error, never a silent no-op or partial room.

The room catalog discovers effective `.des` paths and indexes IDs and tags
in sorted ID order. It retains source weights and eligibility. A sparse mod
can add a tagged room or replace one relative path without editing a Go
registry. File discovery order does not change seeded selection. Fixed
content stays in `.des`; dynamic placement choices stay in Lua policy.

## Layout ownership

The 11 hook modules describe ring, omnibox, omnicross, omnigrid,
quadrants, big cross, big room, chaotic city, and the three maze variants.
Shared readable Lua modules own their geometry primitives, wall materials,
room candidate search, orientation, placement, and connectors. These are
focused functions with comments explaining source rationale, not a direct
copy of the source's global `hypervaults` namespace. Layout hooks return
the existing `{builder, rows, records}` shape to the generic layout
catalog. Room placement uses the normal DES operation engine so keyed
items, monsters, features, and markers survive as typed records and later
materialize through existing population. The layout must retain a
connected return route and feed the shared stair postpass.

Vaults local depth changes source wall weights: stone declines, metal and
crystal grow. Floor motifs and tagged rooms use the saved layout RNG stream
and stable catalog order. Room attempts have the source's bounded retry
budgets. A failed room does not erase the surrounding layout. If an entire
layout cannot produce a connected playable floor after the generic retry
limit, generation fails with its layout ID rather than substituting a
Dungeon map.

## Branch edge and saves

Vaults:1 entry must pair with the exact scheduled Dungeon stair, and
Vaults:2–4 must keep reciprocal local stairs and branch population. This
category must not generate a generic Vaults:5 floor. The Lua branch
generation policy records the currently executable terminal depth for
Vaults as four until the end-vault category installs its source builder.
That boundary is explicit in the generation and save validators; saved
branch depth remains the source value of five. The V:4 frontier is visible
with an unavailable reason and becomes executable only when the V:5
category lands. An overlay can supply its own V:5 generator through the
same policy boundary.

No new Go branch switch or save-only compatibility layer is added. The
already saved layout ID, room-map IDs, terrain, stairs, typed records,
population, and RNG streams describe the created floor. Restore validates
the same branch graph and source map IDs, and does not regenerate a room.

## Verification and readability

Lua tests count and parse all effective source layout and room files,
exercise every layout hook, and assert connected floor, source material
weights, eligible room tags, and typed room records. Seeded game tests
enter Vaults from Dungeon, descend through V:4, return to the exact
entrance, save and restore, and reject a forged V:5 generic frontier.
Modding documentation explains layout hooks, room tags, and how a new
room file joins selection. Each production Lua function explains why and
how, with lines no longer than 120 characters and no crowded struct
declarations.
