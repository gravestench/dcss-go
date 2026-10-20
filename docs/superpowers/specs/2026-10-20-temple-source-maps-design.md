# Source Temple Maps and Altars Design

## Purpose

Make the scheduled Ecumenical Temple entrance lead to a persistent,
source-shaped Temple floor. Keep the C++ checkout read-only and commit the
authored `.des` maps that the game uses. The Temple's selected map, altar
allocation, entrance, and return stair must survive save and restore. This
slice ports Temple terrain and altar identity; worship and god powers remain
their own gameplay domain.

The source `temple.des` contains 53 Dungeon entry definitions and 90 main
Temple maps. Forty-seven main maps have map-specific Lua. The source selects
one main map and altar count at new-game creation, with a one-in-one-hundred
rare-map chance. Ordinary counts use the source two-sided distribution over
6–21 altars. Gods not assigned to the main Temple become overflow altars in
the Dungeon. The existing Go port has none of this selection or altar
placement; its scheduled entrance is currently a generic stair.

Source Temple eligibility excludes Lugonu, Beogh, Jiyva, and Ignis, as
well as disabled gods. The source map
`nicolae_temple_stand_before_the_council` spells its altar-count tag
`temple_altar_6` (singular). Treat this as a source typo: correct it to
`temple_altars_6` in committed content and explain the correction beside
the tag, so the map can participate in six-altar selection.

## Approach

Use the effective layered `.des` catalog as the single source of map IDs,
tags, weights, and authored rows. Add a Temple catalog alongside the
existing primary layout and ordinary vault catalogs. This avoids declaring
map names or altar counts twice. Keep the original DES map and directive
syntax, and move each legacy script into a named Lua hook file under
`policy/generation/vaults/temple/`. Hooks are small functions on the
existing vault operation API, with comments explaining their source rule.
No legacy Lua evaluator or generated importer ships with the game.

The alternative of treating Temple maps as ordinary Dungeon layouts would
lose the source altar-count selection and overflow allocation. Treating
their scripts as inert text would render variable maps incorrectly. A new
Go temple switch would make mods unable to add a map by file. The dedicated
Lua catalog keeps these decisions modifiable through the existing layered
filesystem.

## Run state and selection

At new-game creation, Lua chooses the Temple map, count, and an ordered
partition of eligible Temple gods. The source rare chance and ordinary
count distribution run before the first Dungeon layout draw. Selection
only considers effective maps tagged for the chosen count, excluding rare
maps on ordinary draws. Stable sorted map IDs make file discovery order
irrelevant to a seed; map weights still determine the draw. A mod can add
or replace a map file and its same-path hook without editing Go.

Save one `temple_plan` record containing the selected map ID, selected altar
count, main god IDs, and overflow god IDs. Validate it against the effective
Temple and god catalogs on restore. Keep the selected map fixed for that
run, including before the Temple is generated. A save version bump rejects
older generated saves that cannot prove the new plan. The ordinary branch
schedule remains responsible for the Dungeon entrance depth and level ID;
it does not own Temple altar allocation.

## Maps and placement

Import all 90 main Temple definitions as individual DES files. Port the
47 map-specific scripts to named Lua files, preserving conditional
substitutions, shuffles, feature mappings, markers, and source directive
order. Parse and validate every map during Lua catalog loading, including
rare and low-weight maps. A broken script or unknown directive fails with
its map ID and path; it never silently substitutes another Temple.

The selected map is the Temple's primary floor, not an extra vault placed
inside an ordinary layout. Its authored `ORIENT: encompass` geometry,
features, and stair glyphs feed the shared grid, source records, and stair
link machinery. Add only the return exit the selected map lacks. Temple
has no ambient monster pool; authored monster records still materialize.
Its `no_items` branch flag suppresses ordinary item generation while
preserving authored map items. The generated level records the selected
map ID and each altar as typed source feature plus assigned god ID. The
player can inspect an altar even before worship actions are ported.

Import all 53 Dungeon entry definitions into the ordinary secondary-vault
catalog with their `temple_entry` tag and source weights. The scheduled
Temple entrance uses one eligible source entry map whose `O` glyph becomes
the live entrance, rather than adding an unrelated stair. A map that cannot
fit without disconnecting required stairs is retried with bounded,
seeded selection. The chosen entry map and its source feature identity are
saved on the Dungeon floor. Its `O` cell links to the Temple's return exit
at that exact coordinate. Source entry scripts use named Lua hooks as well.

Overflow altars are chosen once with the Temple plan. Their later Dungeon
placement uses the existing extra-vault path and source altar maps; if an
overflow map or altar effect is not yet executable, keep its allocation
saved and expose the missing effect explicitly. Do not quietly place a
different god. Worship, piety, god abilities, and overflow map coverage
remain separately tracked after this terrain-and-identity slice.

## Verification

- Compare imported counts, IDs, tags, weights, map row checksums, and hook
  coverage against the pinned source checkout. The verifier reads committed
  game data during normal tests; the C++ source is an optional development
  reference, never a build input.
- Exercise every Temple map and entry hook through the production DES parser
  and placement engine, including rare maps and variable altar counts.
- Seeded tests cover source selection bands, altar partition, layered mod
  addition and replacement, and discovery-order independence.
- Enter Temple from a generated Dungeon floor, inspect all assigned altar
  identities, return to the exact entrance, save and restore, and reject a
  forged map, altar partition, or stair link.
- Run the focused Lua, game, and save suites after each coherent category,
  then one integrated run after Temple terrain and identity are wired.
