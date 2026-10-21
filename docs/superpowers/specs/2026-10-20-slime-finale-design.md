# Slime Finale and Slimy Rune Design

## Purpose

Open the scheduled Slime Pits through Slime:5 and preserve the source
encounter: the authored whole-floor Slime Pit, the Royal Jelly, a sealed
inner vault, and one slimy rune. The existing Slime:1–4 candidate layouts,
branch schedule, ECS actors, level grid, and Go save are the owners. This
slice does not substitute a generic floor for Slime:5.

## Source map and Lua rules

Commit the pinned `slime_pit` DES definition as one map under
`vaults/layout/`, preserving its exact 80-column MAP rows and ordinary
directives. The file gains only the layout tags required by this engine.
The source's executable Lua blocks become a named source-position hook in
`policy/generation/layouts/slime_pit.lua` and a separate Lua death policy.
There is no inline Lua in Go or DES and no runtime C++ importer.

Slime:5 must carry the map's keyed Royal Jelly, acid blobs, eye monsters,
Jiyva altar, star items, walls, and one real slimy rune through existing
typed placement and population. Save validation requires `slime_pit` as
the selected end layout and exactly one source rune record. The rune is
collected through the ordinary ECS pickup system.

## The Royal Jelly seal

Source `n` cells are clear stone walls surrounding the inner treasure.
Each final placed `n` cell gets a typed DES marker and a saved Lua ECS seal
cell tied to that marker record. The terrain decoder can discard ordinary
source-feature records after applying them to the grid. When the Royal
Jelly from `slime_pit` dies, a death
hook turns every still-sealed clear stone wall into floor, marks the cells
released, and emits the source collapse message once. Banishment does not
run the death hook. A cell previously changed by another terrain effect
remains as it is; the seal still releases. Killing an unrelated Royal Jelly
does not release the Slime Pit.

Restore checks both directions: each authored clear stone wall has one seal
cell, each seal cell names the matching source record and coordinate, and
released cells cannot still be clear stone walls. A sealed source cell may
have changed earlier through ordinary terrain magic, so the death hook
leaves that altered feature in place. The component persists after release,
so no hidden process global or save compatibility layer is needed. The
source `no_jiyva` records remain typed data; their gameplay consumer
belongs to the later Jiyva religion slice.

## Verification and limits

Audit the committed MAP rows against the pinned C++ map. Lua tests exercise
the layout, keyed records, initial seal, Royal Jelly death, and forged save
rejection. A live Go test travels from the scheduled Lair entrance through
Slime:5, checks reciprocal stairs, kills the Royal Jelly, collects the
rune, and round-trips saves before and after release. A sparse mod can
replace the same map and hook path without an engine registration edit.

Slime entry decorations and the other 28 non-finale definitions in the
source `slime.des` were deferred to a separate vault-content category. The exact Jiyva
message variant and worship effects wait for the religion domain; the
collapse message, terrain change, and rune access are live now.
