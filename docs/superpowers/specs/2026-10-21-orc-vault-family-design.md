# Orc vault family

## Purpose

Port the complete pinned `orc.des` family as one content category: the
authored Dungeon gate to Orc, ordinary Orc rooms, and the required Orc:2
ending. The source has 77 definitions: 19 gates, 42 ordinary or helper
maps, and 16 endings. Success means each authored map can be selected at
its intended stage, with its source decisions and saved effects intact.

## Content ownership

Keep one committed `.des` file per source `NAME`. Use `vaults/orc_entry/`,
`vaults/orc/`, and `vaults/orc_end/` for the three stages. Preserve MAP
bytes and static declarations. A definition covered by the source
`default-depth: Orc` directive gets an explicit `DEPTH: Orc` in its own
file; this records the same source meaning without load order. End maps
keep their `PLACE: Orc:$` declaration. Executable source Lua moves into
named, commented modules under the matching generation policy directory.
The source's original script site remains visible as a nearby DES comment.
No importer or regeneration command becomes part of the repository.

## Entry and ordinary maps

The saved branch schedule chooses a Dungeon parent floor for Orc. That
floor draws one of the 19 effective `orc_entry` maps by source weight,
places it through the shared vault fitter, and links its keyed
`enter_orcish_mines` feature to Orc:1. The one-cell dummy remains a source
candidate, and the existing lone-stair fallback handles maps that cannot
fit. Ordinary Orc maps use the existing weighted regular, minivault,
decor, and explicit placement stages. Authored monsters and items enter
the common ECS population path. Source delayed corpse instructions use
typed, saved decay records.

## Orc:2 endings

Orc declares a mandatory, rune-free `orc_end` family. Its 16 weighted
`PLACE: Orc:$` definitions are eligible through the effective DES catalog.
The selected ending fits before optional vault passes and keeps its ID in
saved history. A failed geometric fit redraws the base floor without
rerolling the chosen ending.

The mapless `grunt_orc_gardens` controller chooses a giant or orc theme,
assigns four distinct source shop choices, and places four garden helpers.
The first helper receives the boss role. The
`grunt_orc_community_town_hall` map places two big houses and four to six
small houses after its own map. Both controllers use the existing bounded
child-placement API. Placement-local settings carry theme, shop, and role
to each child hook; no process global or retained Lua closure is needed.
Child maps retain their source `allow_dup` behavior, and each placement
gets its own typed records. Save validation checks the controller's
expected child count and family without rerunning randomness.

The `pubby_orc_utopia` Elf gate decision reads the saved branch schedule:
its `p` feature becomes the Elf entrance only on the scheduled Orc floor.
This fact enters the generation API as a narrow, read-only branch-entry
query. It does not hardcode the current Elf depth in the map handler. When
the selected end supplies that keyed gate, the existing Elf branch link
must bind to its authored cell and the provisional lone stair must be
cleared. The floor must never expose two live entrances to the same Elf
floor.

## Boundaries and verification

Generation hooks choose source directives and emit typed records. Live
shop behavior, monster behavior, and decay are owned by their existing
systems. A missing live consumer remains a documented pending effect; it
must not silently disappear during save or restore.

One-off source audit checks all 77 names, MAP bytes, static directive
order, and every executable script site. Lua tests load the effective
catalog and place each map through the production path, including
controller children and source random branches. Go tests travel through
an authored gate, build Orc:2, and roundtrip the ending through save and
restore. A sparse mod adds an entrance, ordinary map, and ending without
editing a Go roster. Run the focused category tests, compile all packages,
review the full category, and commit and push it as one unit on `main`.
