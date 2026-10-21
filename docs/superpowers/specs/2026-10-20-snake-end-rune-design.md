# Snake Pit End Vault and Rune Design

## Purpose and scope

Make Snake:4 a faithful branch ending. One of the nine `PLACE: Snake:$`
end vaults from the pinned DCSS `branches/snake.des` must appear on every
new Snake:4 floor. The chosen source map supplies its authored geometry,
monsters, terrain, and serpentine rune. The player can reach the rune, pick
it up through the existing ECS item policy, leave by linked stairs, and
restore the floor and rune state from a Go save.

This slice covers all nine source end definitions, not just one demonstration
map. The rest of Snake generation remains on its existing branch, layout,
monster, and travel paths. No C++ importer or generated file step remains in
the repository. Each committed `.des` MAP is the runtime source of geometry;
source executable Lua is ported to named Lua hook files.

## Catalog and selection

Commit each source ending as `vaults/snake_end/<NAME>.des`, preserving its
`NAME`, `PLACE`, `ORIENT`, weights, terrain, item and monster declarations,
and MAP rows. The ordinary vault catalog auto discovers this family. A
branch definition declares `end_vault_family = "snake_end"` and
`end_vault_required = true`, so no Go branch switch or hardcoded map name
list is needed. Other rune branches can use the same mechanism with their
own family.

On the branch's last floor, draw one eligible end vault by its effective
weight from a NAME sorted list. Select before optional CHANCE, PLACE,
minivault, altar, or unique passes. This is a mandatory encounter, not an
ordinary optional PLACE minivault. A dummy or zero weight map is ineligible.
A mod may replace a source relative path or add another end map in the
family. Extra maps with `PLACE: Snake:$` outside this family stay subject to
the existing optional PLACE rule.

The selected map is fit into a normal 80 by 70 Snake floor with its source
orientation. Generation may redraw the base layout when a fixed orientation
collides with protected stairs or cannot connect to them. It must never
silently accept a Snake:4 floor without an end vault. A bad definition,
missing hook, impossible map size, or exhausted bounded redraw returns a
clear error. A rejected fit restores all terrain and typed records before
retrying. Later optional vaults cannot overwrite the end vault.

## Source scripts and terrain

`snake_hunt`'s source glyph-connection validator becomes a named
`vault.validate` method. It checks the final transformed map path from an
entry glyph to its rune glyph, and rejects disconnected variants before
commit. `grunt_snake_rune_pools`' one-in-three fire theme becomes a named
`vault.run` method at the original source position. That method emits the
source fire or water `MONS`, `KMONS`, `KFEAT`, `SUBST`, and `NSUBST`
directives through the ordinary typed directive engine. Each hook has a
local handler object, named functions, and explanatory why/how comments.
The source `.des` file retains notes at the former script site.

The source `serpentine rune of Zot mimic` request in `grunt_snake_rune_spirals`
refers to a legacy mimic behavior unavailable in the active DCSS ruleset.
The end still has exactly one real rune. Its other location receives the
source good-item alternative, not a second collectible rune or a false
rune pickup. The five candidate runes in
`johnstein_snake_rune_scales` remain under source `NSUBST` so exactly one
survives. Any source selection yielding zero or multiple real rune
placements is rejected before the level is published.

## Live floor and save invariants

The authored rune materializes as the already registered `RUNE_SNAKE` item
entity. Existing pickup logic adds it to the player `character.runes` ECS
component and removes the floor item. The typed vault record remains as
historical evidence of the map that generated it; a later save is valid
whether that item is still on the floor or has been collected.

The chosen end map ID becomes the floor's primary vault ID and is included
in its vault history. Save validation checks that a Snake:4 floor references
one current `snake_end` definition with a matching `PLACE` rule and one
historical real Snake rune record. It also checks its reciprocal Snake:3
stairs through the existing link validator. A mod removing or changing a
previously saved map fails restore explicitly. An older save with an
ordinary Snake:4 floor is not silently rewritten; it needs a deliberate
migration later.

## Verification and modding

Corpus tests parse all nine definitions and every named hook, assert
committed MAP dimensions and checksums audited once against pinned source,
and check the rune, orientation, and placement directives. Tests do not
read the C++ tree during ordinary builds. Generation tests cover all nine maps across seeded
layouts, fixed orientation collisions, the pools fire and water outcomes,
`snake_hunt` disconnected veto, exactly one real rune, and no accepted
fallback floor. Game tests travel Snake:3 to Snake:4 and back, collect the
rune, save, restore, and reject corrupted end-map or rune records. A mod
fixture adds an end map through the layered VFS without editing Go.

The modding guide explains the declarative `end_vault_family` contract,
where the `.des` and hook files go, and why an end map is mandatory rather
than part of the optional PLACE pool.
