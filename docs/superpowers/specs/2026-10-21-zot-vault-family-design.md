# Zot Vault Family and Branch Generation

## Purpose and source boundary

Port the complete 88-definition `zot.des` family from pinned DCSS commit
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. Fifteen definitions
describe the Depths-side gate, one is the weighted dummy balancer, 67 are
ordinary Zot maps, one is `hall_of_Zot`, and four are floor-style helpers.
Each source `NAME` gets one committed `.des` file. Keep its `MAP` rows and
static directive order; make file-global source setup explicit per file.
The original C++ checkout is an audit reference, never a build input.

This slice opens Zot:1–5 and places the Orb of Zot as the source hall's
authored item. Orb pickup, the Orb run, ascent, and victory are a separate
gameplay category. Those later rules must consume the real Orb entity and
saved branch state produced here, not a parallel endgame fixture.

## Map and Lua ownership

The effective layered VFS discovers `vaults/zot_entry/*.des` and
`vaults/zot/*.des`. The four `hall_of_Zot_<depth>` helpers remain discoverable
Zot extras. The fixed Zot:5 `hall_of_Zot` lives in `vaults/layout/` because
it owns the floor; its source `PLACE: Zot:$` and `ORIENT: north` remain
visible. A general authored-layout fit rule must admit its 80-column map
without weakening the ordinary smaller-vault bounds.

Source executable blocks become named Lua methods under
`policy/generation/vaults/zot_entry/`, `policy/generation/vaults/zot/`,
or `policy/generation/layouts/`. DES declares them with source-position
`vault.run` or `vault.validate` hooks and keeps the original script text in
comments for auditing. The shared entry, dragon-hoard, and coloured-glass
source routines get one focused Lua module each, called by each map that
uses them. The `grunt_zot_stairs_overgrown` timer and plant transformation
are live ECS marker/system behavior with saved one-shot and countdown state.
No inline Lua executes from `.des`; no Lua source is embedded in Go.

The small entry is retained but not selected: the source describes it as
unused while larger entry maps are placed as primaries, and it has no
`PLACE` rule. The other 14 entry maps use their source weights and
`Depths:$` placement. On an
encompassing Depths:4 map whose keyed Zot gate is already present, that
gate wins and no second entry map is added. Without one, the source-weighted
entry family supplies the keyed gate through the existing branch-entry
owner. Seeded selection sorts names, so VFS file load order changes neither
which vault is chosen nor any random draw.

## Zot floors and Orb placement

Zot:1–4 use the existing source-qualified generic layout pool, the Zot
population table, and eligible ordinary Zot vaults. They pair stairs and
save links through the same branch path as other playable branches. The
four depth-specific style helpers must apply their colour and tile records
on the intended floor without displacing geometry or eating a random
ordinary-vault slot.
The source's Zot:5 dummy has weight 60 in the ordinary vault draw.
Choosing it ends that placement attempt with no geometry or saved vault
ID; it is not a disabled or placed one-cell map.

Zot:5 requires `hall_of_Zot`; generation must never substitute an ordinary
layout if the effective hall is missing or invalid. The hall's source
monster, trap, and Orb requests materialize through the ordinary typed
placement and Akara entity pipeline. Its source `has_exit_from_glyph('Z')`
validator must test the resolved geometry. The source's Orb item is unique
and must survive save/restore with its vault origin. Source exits stay
reciprocal with Zot:4, and the player must arrive on a connected part of
the hall.

## Verification and modding

Audit all 88 source names, every original `MAP` row, static directives,
and moved script site against the pinned file using a temporary tool outside
the repository. Lua tests load all definitions, assert the active entry
weights and floor eligibility, exercise every map's placement path, and
verify the hall's one Orb record and exit path. A sparse mod may replace
one bundled map and add a new Zot map without Go registration. An integrated
game test travels from Depths:4 through Zot:5, checks reciprocal stairs,
the Orb entity, source IDs, and save/restore. Run focused regressions,
all-package compilation, changed-file style checks, and category review.
Commit this contiguous source family once and push it to `main`.
