# Bazaar Portal Domain

## Purpose

Make the source Bazaar a playable one-floor portal branch. A source entry
vault should lead to one of the 42 Bazaar maps, fill its shops,
and return the player to the exact entrance floor. The 13 entry maps and
42 Bazaar layouts in `dat/des/portals/bazaar.des` are the pinned content.
Of those layouts, 41 have authored MAP rows and one is a generated cavern.
The ordinary shop system already owns stock, purchasing, and the menu;
the Bazaar must use that owner rather than create a second shop economy.

## Content and mod contract

Commit one `.des` file for every source `NAME`. Place the 13 entrances
under `vaults/bzr_entry/` and the 42 whole-floor maps under
`vaults/bazaar/`. Preserve source MAP rows, weights, tags, placement
directives, and declaration order. The generated cavern keeps its source
weight in DES and uses a Lua carving hook. The source's embedded executable Lua
becomes named `vault.run`, `vault.veto`, or validation hooks at the same
positions. Hook modules live under `policy/generation/vaults/bzr_entry/`
and `policy/generation/vaults/bazaar/`. Shared setup functions may live in
one `shared.lua`; map-specific choices remain local methods. A mod can add
one map or override one map or hook by effective relative path.

The entry hook emits a keyed `enter_bazaar` feature and a typed portal
record: five in six ordinary entries are timed, while `statue_bzr` is
permanent. Timed entry uses the source low and high duration formula based
on absolute depth; the saved countdown removes the entry feature when it
expires. `bzr_entry_dummy` vetoes a second Bazaar already active on the
travel stack. Pan-only `bzr_crystal_pan` stays eligible only in Pan.

Each Bazaar map's setup marks ordinary monster generation off, converts
the authored `<` into the arrival arch and `>` into the exit, and selects
its source tileset and shop halo policy. Conditional DES choices remain
hook calls, with generated directives inserted at source position.
Authored monsters and items still use the generic vault materializer.

## Travel and state ownership

Lua chooses the effective weighted Bazaar layout and returns a typed
travel plan. Go stages the level, shops, actors, and return link before
committing the player's move. The saved Bazaar state has the origin floor
and cell, active Bazaar level ID, chosen map ID, timer state on the entry,
and a one-way exit. Go owns level grids and atomic installation; Lua owns
which portal is usable, duration, map selection, messages, and save
semantics. Restoring a save validates the layout ID, portal ownership,
remaining timer, destination, and reciprocal return location. Entering
cannot reroll a previously created Bazaar. Exiting retires its level and
cannot clone its stock by re-entering.

Source Bazaar shop placement uses the existing shop generation and item
value policies. The Bazaar's 60–95% price bargain and source stock quality
adjustment are scoped to the Bazaar branch and live in Lua shop policy.
No Bazaar-specific monster, spell, item, or shop switch enters Go.

## Verification

Check all 55 IDs and byte-equivalent rows for the 54 authored MAP blocks
against the pinned source.
Parse every map through production DES code and exercise every named hook.
Generate each whole-floor layout and resolve its shops. Test timed and
permanent entries, expiry, failed placement rollback, Pan-only eligibility,
weighted selection independent of file order, return to the correct cell,
save/restore, shop pricing, and one-way stock protection. Finish with an
integrated game run and a clean pushed category commit on `main`.
