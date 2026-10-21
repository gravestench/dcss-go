# Lair vault family

## Purpose

Port the complete pinned `lair.des` family so Dungeon entrances to Lair,
Lair:1–4 rooms, and the Lair:5 ending use the authored maps and rules. The
source contains 116 definitions: 13 entry maps, 89 ordinary or helper
definitions, and 14 endings. This is one content family with shared script
helpers, so source map placement and source decisions must be ported together.

## Content ownership

- Keep one committed `.des` file per source `NAME`. `vaults/lair_entry/`,
  `vaults/lair/`, and `vaults/lair_end/` separate selection stages, while
  each file retains its original `NAME`, MAP rows, static directives, and
  relative script position.
- The `.des` file owns geometry, tags, weight, depth, place, and static
  keyed declarations. A focused Lua module under
  `policy/generation/vaults/<family>/` owns only source decisions that
  require branch, depth, RNG, or another runtime fact. Shared source
  helpers live in a named Lua module, never in an inline script or a Go
  source string.
- Port fixed helper calls as explicit DES declarations at their original
  position. Keep source-script text in nearby comments, with an explanation
  of why each named hook exists. Neither generation nor tests depend on
  file load order.
- Retain source instructions whose gameplay consumer is pending as typed,
  saved level records. List those effects in the port inventory rather
  than silently ignoring them.

## Entry and ordinary placement

The saved branch schedule chooses the Lair parent Dungeon floor. That floor
draws one of the 13 effective `lair_entry` maps by source weight, fits it
before optional extra vaults, and links the final keyed `enter_lair` cell to
Lair:1. A sparse mod can add or replace a map without editing Go selection.
The source dummy entry remains a candidate and the existing lone-stair
fallback remains available if no authored map can fit.

On Lair:1–4, ordinary maps join the existing regular, minivault, explicit
PLACE, and post-place controller stages by their source eligibility. Their
authored monsters and items become ECS entities through the current common
population path. Source fog machines use the existing saved marker owner.

## Lair:5 ending

Lair:5 chooses exactly one source-weighted primary ending from the 14
`PLACE: Lair:$` definitions. It is required before optional vault passes,
even though Lair has no rune. Five small-ending definitions also request
one other eligible `lair_end_small` map after their own placement. The
controller draws from the effective catalog, excludes the selected map,
and records the child ID and typed effects in the same level history. A
failed fit requests a redraw; a saved Lair:5 never invents a new ending
when restored.

## Script and gameplay boundaries

The source `wad_woods_setup`, `beast_lair_*`, and other shared decisions are
Lua policies invoked at their original DES sites. Branch and depth reads
come from the generation `api`; no process globals or copied player state
live in a module. A script that calculates a value before another source
directive and uses it later uses placement-local `api:remember` and
`api:recall` at two script sites.

Generation hooks emit DES operations or saved records. Movement, fog,
monster behavior, and item effects run later through their existing live
systems. A new live effect gets an ECS owner and restore validation, rather
than retaining a Lua closure from generation. Map-local hooks remain
separate from the live game `ctx`.

## Verification

An out-of-repo one-off audit compares all source MAP blocks byte for byte,
checks static directives and script-site coverage, and verifies the 116
names. Lua tests load all definitions through the production catalog and
place every MAP through the normal path, including source RNG endpoints.
Go travel tests exercise a weighted entry, reciprocal stair, Lair:5 ending,
small-ending pairing, and save/restore. A sparse mod fixture adds one
entry, ordinary map, and ending through the same discovery path. Run
focused category tests and a Go compile check at the category boundary.
