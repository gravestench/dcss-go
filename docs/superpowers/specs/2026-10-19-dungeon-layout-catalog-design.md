# Dungeon layout catalog design

## Purpose and scope

The Go port currently builds every Dungeon floor with `basic.generate`, even
though the source selects among authored builder layouts. Port the complete
Dungeon-eligible layout family as one content and generation slice. Keep
the source `.des` map language and move its embedded script behavior into
readable Lua modules. D:1–15 continue to generate on first entry.

The pinned source audit found 21 layout definitions with a `D` depth rule in
`dat/des/builder/layout*.des`. Sixteen have positive Dungeon weight; five
are disabled by a zero Dungeon weight. Import all 21 as individually
replaceable `.des` files, register the disabled definitions, and select only
positive-weight definitions at eligible depths. The importer is a one-time
development tool and is not required for a normal build or kept in the repo.

This slice covers Dungeon layouts. Branch-specific layout eligibility and
branch terrain belong to the branch-generation domain. Primary vaults beyond
the already ported D:1 arrival family remain a separate vault-content domain;
the layout selector must accept primary-vault tags now so those maps can
join the same flow later.

## Source layout contract

- Each committed `vaults/layout/<name>.des` retains `NAME`, `DEPTH`, `WEIGHT`,
  `ORIENT`, `TAGS`, map rows, and supported map directives in `.des` syntax.
  Source provenance belongs in a nearby comment, not in registration data.
  Disabled definitions retain their original zero-weight status.
- Source `{{ ... }}` and `:` script statements become named hooks in matching
  `policy/generation/layouts/<name>.lua` files. These are real Lua functions
  called by the production generator. The `.des` file invokes the hook by
  name; no inline Lua executes from Go or from the `.des` parser.
- Common map operations such as filling regions, carving rooms, stairs,
  shuffling glyphs, and connectivity belong in focused Lua helper modules.
  A layout module builds a local object, assigns documented functions to it,
  and returns it. It must not become a giant nested handler.
- The layout catalog reads effective files through the layered mod VFS.
  Adding one file adds one layout; replacing the same relative path overlays
  it. Duplicate `NAME` values in different effective files fail at startup.
  Loading or renaming unrelated files cannot change a seeded selection:
  eligible IDs are sorted before a weighted draw.
- Depth rules and branch-specific weights are parsed once from `.des`
  metadata. There is no second hand-maintained table of layout names,
  weights, or depth ranges. A zero effective Dungeon weight is never drawn.

## Generation flow

On D:1, the selected arrival remains the primary map. Its `layout_*` and
`nolayout_*` tags constrain the layout family; `no_primary_vault` layouts
are excluded. On D:2–15, the Dungeon generator draws an eligible layout
using its Dungeon weight, then places compatible extra vaults, pairs all
stairs with the live parent, and populates the floor. A layout returns a
builder plus any stairs it authored. A shared Lua postpass places missing
up/down stairs on eligible floor cells, matching the source's separation
between layout carving and `dgn_place_stone_stairs`. It then proves at least
three usable connected stair pairs before returning rows to Go.
Layout-specific authored features and no-spawn masks remain level data and
survive save/restore.

The weighted choice and all map construction run in Lua with the current
game RNG streams. Go receives the finished terrain and vault records through
the existing level decoder and owns the grid, occupancy, links, and save
encoding. Reentry uses the saved floor and consumes no layout draws.

## Validation and failure behavior

Catalog load rejects malformed metadata, duplicate IDs, missing hook
modules, unsupported directives or map operations, and positive-weight
layouts that cannot be executed. It never silently substitutes basic
terrain. A generation attempt may retry a candidate when a source-defined
placement constraint fails, but it records the failed candidate and has a
bounded retry count; malformed content is an error, not a retry reason.

Tests exercise every positive-weight Dungeon layout at each boundary depth
where it becomes eligible, assert valid connected stairs and saved round
trips, and verify each disabled definition remains unselected. They check
the expected family weights from the source, stable selection under VFS file
order changes, D:1 arrival constraints, and mod-added/replaced layouts.
One game integration test descends through all fifteen floors using the
effective catalog. The existing fixed scenarios remain unchanged.
