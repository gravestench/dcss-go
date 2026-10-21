# Hell Ordinary Floors Implementation Plan

**Goal:** Make Dis, Gehenna, Cocytus, and Tartarus depths 1–6 playable,
source-shaped, persistent floors reachable through their Vestibule gates.

**Source:** `docs/superpowers/specs/2026-10-21-hell-branches-design.md`,
the pinned `crawl-ref/source/dat/des/branches/{dis,geh,coc,tar,hells,
geh_lava_maze}.des`,
`dungeon.cc` stair fixup, `stairs.cc` branch return, and `branch.h` monster
budget. The source `.des` assets are development inputs, not build inputs.

**Architecture:** Lua owns Hell floor selection, source map operations, and
the meaning of each gate. Go stages a new persistent level using the existing
transaction and saves the destination. Compact geometry is a generation
choice; the dense grid and ECS actor model remain unchanged. A Hell up exit
routes to the Vestibule, while one ordinary down stair routes to the next
depth. Discovery order must not affect seeded selection.

## Task 1: Source map catalog

1. Inventory the active maps and script sites in the four branch files,
   `hells.des`, and `geh_lava_maze.des`; distinguish ordinary maps, helper
   maps, end maps, and disabled definitions. Record source counts in the
   port inventory. Source `*_old` and `*_mu` endings remain active choices.
2. Commit one `.des` per active ordinary source map under a family path in
   `internal/modfs/builtin/vaults/`. Preserve map geometry, tags, weights,
   depth clauses, directives, and source names. Do not check in an importer.
3. Move executable source Lua into named, commented hook modules at the
   original declaration positions. Validate every hook through the effective
   layered VFS. Add catalog and overlay tests that prove maps can be
   discovered without file-order dependence.

## Task 2: Compact source floor generation

1. Add a focused Hell ordinary-floor builder in
   `internal/modfs/builtin/policy/generation/hell/`. Select the committed
   source layouts and ordinary vaults. Use the source compact size of 40×35
   for depths 1–6. Thread dimensions through the builder and placement
   operations that currently assume 80×70; do not change a module global
   while building a level. Populate the source monster budget (`3d6`) and
   preserve typed terrain, actor, item, and pending-effect records.
2. Place exactly one connected down stair where the source builder requires
   one. Convert ordinary up stairs to the branch's `escape_feature` after
   layout and vault placement, following the source fixup order. Ensure an
   entry landing and a branch exit are reachable. Do not fabricate a
   scheduled parent floor.
3. Add Lua tests covering all four branches, several fixed seeds, map
   eligibility, one down stair, exits, compact bounds, and hook failures.

## Task 3: Travel, persistence, and validation

1. Extend the Lua Hell travel policy to map each Vestibule entrance feature
   to its branch and each branch escape feature back to the Vestibule.
   Descending in a Hell branch opens its next depth. Revisit saved floors
   without regenerating their maps or actors.
2. Extend the Go Hell portal transaction only for level staging and saved
   destination validation. Keep gate dispatch in Lua; avoid a Go switch over
   Dis, Gehenna, Cocytus, and Tartarus. Failed generation must restore the
   previous floor and save state.
3. Extend Hell save validation to prove each saved floor's branch, depth,
   compact geometry, required exits, and destination graph. Add integrated
   travel and save/restore tests for all four branches and a rollback case.

## Task 4: Category boundary

1. Run focused Lua and Go tests for Hell generation, travel, and saves.
2. Run the repository style check and broader relevant Go suite once after
   the category is integrated. Fix regressions in changed files.
3. Update the port inventory and modding guide with the effective Hell map
   families and remaining end-map/effect gaps.
4. Commit this contiguous category on `main`, push to the configured fork,
   and then proceed to the four branch endings under the approved spec.
