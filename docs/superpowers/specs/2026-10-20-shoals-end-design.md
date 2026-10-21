# Shoals Finale and Barnacled Rune Design

## Purpose

Make Shoals:4 use every pinned DCSS finale. The source has six selectable
`PLACE: Shoals:$` definitions: four mapless controllers that assemble
islands, and two authored encompass maps. Twenty helper maps supply rune,
guardian, decoy, storm center, and corner pieces. One selected finale must
lead to exactly one collectible barnacled rune, with historical map identity
and child ownership retained through save and restore.

## Source content and Lua policy

Commit the 26 original DES definitions as individual files in
`vaults/shoals_end/`, preserving every MAP row and all ordinary directives.
Replace source inline Lua at the same positions with named modules under
`policy/generation/vaults/shoals_end/`. The four controllers call a shared
finale policy that places a theme-matched real rune hut, optional Ilsuiw
guardian, optional false rune hut, and source-count decoys. Preserve the
source one-in-five and one-in-ten decisions and the one-or-two fewer decoys
after a false rune hut. Iceberg helpers call one shared ice-style hook.
The two encompass maps retain open-sea border intent as typed records.

The source `mimic` item modifier makes a false rune look like a rune until
interacted with; it never enters player rune progress. Port that modifier
as a saved Lua-defined ECS component on the item. The generic pickup system
reveals and removes the decoy with a message. It remains a source item
effect, so other DES content can reuse the same modifier. No inline Lua or
build-time C++ importer enters the game repository.

## End composition and saves

Extend the generic required end-vault flow to accept mapless controllers.
The selected controller is the primary vault ID. It runs post-place policy
before optional vault stages. Children use the existing weighted tag
selector and return their own source IDs and typed records. The controller
must place its required real rune child; failure redraws the base floor
while keeping the selected finale ID fixed. A controller-specific named
validator checks exactly one real rune record and that its source belongs
to a helper with the selected theme's real-rune tag in saved history.
Save validation runs that same Lua method. Direct authored finales continue
to require the rune record from the selected primary map.

## Shoals floor dependency

The pinned Go baseline advertises a Shoals entrance but has no effective
Shoals primary layout, so the end family cannot be reached by normal play
without that dependency. Commit `layout_shoals.des` from the source layout
catalog and a named Lua heightmap hook that creates islands, cliffs, and
water bands. Pass the generated elevation array to the existing saved Go
Shoals tide owner. This opens the branch without a hard-coded branch switch.
The source island planner's exact contour algorithm and flora pass remain
separate fidelity work; the initial hook preserves its main parameters and
terrain thresholds.

## Verification

Pin all 26 source definitions and the 22 nonempty MAP dimensions and
checksums in committed Lua tests. Fit each helper and each authored map
through the production DES path. Exercise every controller theme, optional
guardian and mimic, decoy counts, one real rune, and failed child fit.
Travel from a scheduled Lair entrance to Shoals:4 in Go, collect the rune,
check reciprocal stairs, and round-trip pre- and post-pickup saves. Reject
forged controller, child, rune owner, or extra-rune history. Add a sparse
mod finale to verify layered discovery without engine registration.
