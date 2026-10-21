# Depths Encompassing Vault Family

## Purpose and source boundary

Port all 17 definitions in the pinned `depths_encompass.des`: seven
whole-floor Depths maps and ten named helpers. Keep one committed `.des`
file per source `NAME`, exact `MAP` rows, original static directives, and
source-position comments for every moved script. The C++ checkout and any
one-off split tool remain outside the build.

The source `default-depth` applies to Lemuel's River Lethe, Box Level,
Crystal Crosses, and both Radiant Caverns maps on Depths:2–3. Profane Halls
and Pleasuredromes explicitly `PLACE` on Depths:4. Split files must state
their effective `DEPTH` individually, since file-global DES parser state
must not depend on which file loads first. The source weights remain 10 for
ordinary maps, 5 for each Radiant Caverns map, and 1 on Depths:4 for each
explicit end map.

## Lua ownership and composition

Original map geometry and authored selectors stay in DES. Executable source
Lua becomes named, well-commented Lua methods called at the corresponding
DES script sites. Helpers stay independent DES definitions discovered by
tag. Profane Halls chooses temple and Zot/loot children by effective tags;
Crystal Crosses chooses its six arms by the source groups. The generated
terrain, monster and item requests, markers, child IDs, and branch feature
records must use the existing typed vault placement/save pipeline. No
second representation of each map is maintained in Go.

## Whole-floor generation

Depths:1 keeps ordinary layout generation. On Depths:2–3 the source's
positive-weight encompassing maps form a weighted primary pool; Depths:4
first chooses from explicit `PLACE` maps. The shared `uniq_d_encompass` tag
allows only one of these maps per run. When no candidate remains, ordinary
layout generation takes over. The selected map is fixed across generation
retries and kept in vault history. A mod can add or replace a matching DES
definition without editing a Go list.

An encompassing map establishes the floor before procedural layout stairs
are placed. Its own `<`, `>`, and keyed branch features are authoritative.
The encompassing connection pass preserves one-way source exits in tiny
regions and adds missing branch stairs in the main playable region without
overwriting authored geometry. The scheduled Zot link uses the final keyed
`enter_zot` record where present; Zot destination travel awaits its own
playable branch layout. The parent-child links, selected
primary ID, helpers, typed effects, and RNG state survive save/restore.

## Verification

Compare the complete 17-map source inventory, original MAP rows, static
directives, and Lua script sites against the pinned file with a tool outside
the repository. A Lua catalog test validates all maps and helper tags,
source floor/weight eligibility, hook execution, and selected child IDs.
A sparse mod test adds a new Depths whole-floor map and replaces one source
path. Integrated Go travel tests generate Depths:2 and verify authored
terrain, reciprocal stairs, and a save round trip. Lua tests execute both
Depths:4 endings and verify their keyed Zot links. Run focused regressions,
all-package compilation, style checks for changed Go files, and review at
the category boundary before one commit and push to `main`.
