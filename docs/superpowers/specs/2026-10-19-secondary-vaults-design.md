# Secondary vaults and serial map design

## Purpose

Ordinary Dungeon floors now draw from the complete positive-weight layout
family, but their secondary map pool contains only shop vaults. The current
one-in-eight generic-extra roll is a temporary shop-only approximation. Port
the remaining source builder and serial vault families, and select them at
the stages where Dungeon Crawl selects chance maps, minivaults, and serial
controllers. A modder must be able to add one map without editing a selector.

The pinned source has 282 named maps under `dat/des/builder` and 318 under
`dat/des/serial`. Ninety-one builder maps are already committed: 21 layouts
and 70 shop maps. This leaves 509 definitions in those two directories.
The arrival family is already committed separately. The corpus includes
Dungeon maps, branch-only maps, controllers, and helpers. Commit every
non-legacy definition as its own effective `.des` file, including maps that
will become selectable only when their branch exists. A map must never be
declared selectable until its hooks and placement effects work.

## Content contract

- Keep authored `NAME`, map rows, terrain glyphs, tags, depth/chance/weight
  rules, and supported directives in `.des` syntax. Put source provenance
  in nearby comments. A normal build uses the committed files and never
  reads the C++ checkout. One-off extraction tools stay outside the repo.
- Move each source script statement or block into a same-named, readable
  Lua module. The `.des` file retains a named hook at that operation's
  position. Each Lua function documents why and how it works; a controller
  module builds a local object, assigns its methods, and returns it.
- A source declaration with a depth rule retains that rule. Do not invent
  a Dungeon depth for an unqualified helper. Branch-only maps register now
  and wait for their real branch generator. The builder/serial corpus has
  no `PLACE` declarations; its selection stage is empty until branch and
  portal maps are imported.
- Extend the existing DES parser for source forms that this corpus actually
  uses: bare and branch-qualified `CHANCE`, depth-specific `WEIGHT`,
  map geometry, and keyed terrain/entity/marker directives. Reject unknown
  forms with the effective path and declaration site. Do not interpret raw
  source Lua or silently drop an unsupported instruction.
- The layered VFS discovers files in `vaults/builder/` and `vaults/serial/`.
  A later layer replaces the same relative path; a new path adds a map.
  Duplicate effective `NAME` values fail at load. Catalog IDs are sorted
  before any weighted draw. Filenames, VFS discovery order, and provenance
  comments have no effect on seeds. Within a map, authored directive and
  alternative order remain meaningful and are preserved.

## Selection and placement

`policy/generation/vaults/secondary.lua` coordinates four focused stages
after the primary layout and arrival are connected and before population:

1. **Chance maps.** Evaluate each depth-eligible, non-dummy `CHANCE` map's
   source chance on the layout stream. Shuffle the successes on that same
   stream, then attempt each placement. A conflicting uniqueness tag or
   geometric failure may trigger its source `fallback_*` tag, when present.
   A bare chance applies to every branch allowed by `DEPTH`; a qualified
   chance applies only to the named branches and depths. Source chances use
   a 10,000-point roll: `0.5%` means 50, while raw `8333` means 83.33%.
   The controller's post-place hook runs only after its own map places
   successfully.
2. **Place-specific minivaults.** Keep this stage available for future
   `PLACE` maps. None of the current builder/serial maps use `PLACE`.
3. **Depth minivaults.** Draw ordinary depth-eligible minivaults by weight.
   A selected `extra` minivault requests another draw, with an explicit
   finite bound for a pool containing only extras. Maps with `CHANCE` do not
   join this weighted pool. The shop controller joins the chance stage
   through the same general contract, replacing its special-case call.
4. **Other secondary maps.** The source generator also has primary and
   non-Dungeon extra-map paths. Keep those paths distinct. Do not run the
   current generic `extra` roll on Dungeon once the actual pools exist.

Selection filters honor `DEPTH`, `PLACE`, `TAGS`, `CHANCE`, weight, `dummy`,
layout compatibility, species exclusions, and map uniqueness. A controller
can request tagged child maps through a small documented API with bounded
draws and placement attempts. That API does not special-case shops or map
IDs. It uses the same catalog, eligibility, uniqueness, terrain projection,
and record path as an ordinary map. Related serial maps stay separate files;
their controller may place several on one floor in source order.

`placement.lua` continues to own geometric projection and typed pending
records for item, monster, shop, marker, and terrain effects. Secondary
placement cannot overwrite protected stairs, the arrival, or another
authored vault. A geometric conflict restores the grid and can try a new
origin or eligible map; malformed content fails with a site diagnostic.
Stair connectivity remains mandatory. The source map's legal effects must
not disappear merely because their active gameplay handler belongs to a
later domain slice; such effects remain typed level data and save intact.

## Uniqueness and saved state

Record the ordered list of successfully placed vault IDs on each level,
including maps that produce no cell records, and include it in the Go save.
Pass prior-level IDs into Lua when generating a new floor. Lua derives the
run-used names and `uniq_*` tags from the effective catalog. It also tracks
level-used names and `luniq_*` tags during the current build. `allow_dup`
permits the source-defined duplicate case without bypassing a uniqueness
tag. Reentry reads the saved level and consumes no selection draws. Save
validation reports a missing or renamed referenced map before generation
or restore silently changes its meaning.

The save records IDs, not source file paths or source line numbers. The
effective mod manifest is already part of save validation; changing a map
while loading a run must follow the existing ruleset-change policy.

## Runtime ownership

Lua owns map eligibility, weighted choice, controller policy, hook calls,
and generation-stage order. Go supplies RNG streams, the current level
snapshot, typed record decoding, grid storage, occupancy, and save format.
ECS holds placed dynamic entities and effects; terrain stays a grid. Do
not add a Go dispatcher for individual map IDs or a second map format.

Split modules by responsibility: DES parsing, catalog loading, eligibility,
chance-stage choice, minivault choice, controller API, geometric placement,
and persistent used-map state. Keep each map's unusual rule in its own Lua
file. Shared pure rules may be named free functions. Avoid a giant switch,
deeply nested callbacks, inline Lua in Go, and generated metadata that
duplicates `.des` declarations.

## Verification and documentation

- Enumerate the complete 600-definition builder/serial corpus by source
  `NAME`, accounting for the 91 already committed and every intentional
  legacy exclusion. Detect missing, duplicate, or unexpectedly selectable
  definitions. Every ported hook must load and execute under its own
  contract test; every selectable map must place in a representative legal
  context or give a documented source veto.
- Test chance boundaries, fallback tags, serial multi-map placement,
  `PLACE` versus depth selection, extra retry bounds, cross-floor and
  same-floor uniqueness, overlay additions/replacements, filename/order
  invariance, stair protection, save/restore, and first-entry RNG replay.
- Keep focused Lua `_test.lua` files importing production schemas and ID
  catalogs. Run one broad Go verification after the full category is wired;
  refine only concrete failures rather than retesting each content file.
- Explain in `docs/modding.md` how a new secondary map, helper, controller,
  chance rule, and Lua hook are discovered and how the controller context
  uses the current branch, depth, player, layout stream, and placement API.
  Update README, port inventory, and architecture roadmap when the
  shop-only approximation is removed.

The corpus import and the selection/runtime work can be delivered in
contiguous category commits. Each commit must leave its included maps
honestly executable and tested; do not retain inert placeholder maps to
claim source coverage. Commit on `main` and push each completed category.
