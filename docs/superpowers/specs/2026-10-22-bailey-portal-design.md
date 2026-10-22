# Bailey Portal Design

## Intent and scope

Port Bailey as one complete D:7–10 portal domain in Dungeon Crawl's Go
engine. A character can find an authored temporary gate, enter a source
Bailey layout with its chosen axe or polearm theme, fight and collect its
authored content, and return to the exact Dungeon cell. Generation, clock
state, chosen theme and map, travel, and retirement survive save and restore.
Mods can add or replace an entrance, layout, or Lua hook through the layered
virtual filesystem. Normal builds and play use only committed assets;
one-time import tools do not remain in the repository.

The pinned source is `crawl-ref/source/dat/des/portals/bailey.des` at DCSS
commit `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. It has 25 active
`NAME` definitions: nine Dungeon entrances, the mapless `bailey` dispatcher,
and 15 encompassing destination layouts. Six destinations carry the
`bailey_axe` tag and nine carry `bailey_polearm`. All 25 belong to this slice;
none is disabled merely because it has a rare item, monster, trap, or marker.

## Source maps and scripts

Commit each source definition as one individually replaceable `.des` file
under `vaults/bailey_entry/` or `vaults/bailey/`. Keep the original `MAP`
rows, static directives, weights, tags, orientation, and directive order.
The mapless dispatcher remains a real catalog definition with an empty map,
not a fabricated terrain layout. Source-position executable sites become
named `vault.run` hooks in the `.des` files. Their bodies live in documented
Lua modules under `policy/generation/vaults/bailey_entry/` and
`policy/generation/vaults/bailey/`. The existing roadmap item for readable
DES-local Lua remains; this slice does not add inline Lua to Go.
Every new Lua function explains its purpose, source rationale, and effect
on generation or saved state in its own comments.

Port the shared `bailey_portal` and `bailey_setup` helpers and every
source-specific script choice. These include the entry's conditional
weapons and monsters, statue names and tiles, axe and polearm monster
loadouts, source loot-pool expressions, the vampire castle's delayed
skeleton decay, and its dead-tree and gravestone names. The source's
`NSUBST`, `SUBST`, `SHUFFLE`, masks, properties, colours, keyed features,
monsters, items, and tiles use the existing DES and typed-placement paths.
Preserve each source draw's stage and order. An authored effect whose wider
gameplay owner is still absent remains an explicit typed saved record and
inventory gap; placement must not silently drop it.

## Theme, selection, and generation

Only eligible D:7–10 floors may select one of the nine entrance maps.
Static source selection metadata is available before its hook runs; the
source `uniq_bailey chance_bailey` tags and chance 1000 are represented
there. The chosen entrance uses ordinary effective-catalog weight,
placement, and used-map rules. Its hook draws the source two-way theme
choice once. Any conditional entrance decorations use that same choice.

The source stores `bailey_axe` or `bailey_polearm` in `dgn.persist`, then
its mapless dispatcher selects a destination by matching tag. The Go port
stores the theme on the entrance's saved ECS portal component. On entry,
Lua runs the dispatcher and selects one positive-weight effective layout
with the matching tag, using stable vault IDs to remove filesystem load
order from seeded results. A live gate without a theme, or a theme with no
eligible layout, is an error; the source's missing-theme Wizmode fallback
does not replace normal gameplay state. The source dispatcher and selected
child identities are both retained in the generated level's history.

Each selected child encompasses one temporary Bailey floor. Use ordinary
DES placement and Akara entity population for its terrain, monsters,
equipment, loose items, traps, and records. Every layout
must yield a safe arrival and at least one live exit. All 15 children are
selectable and must pass production placement. A modded child joins its
theme pool by tag without a Go content switch, hardcoded ID list, or
`source_order` field. The effective ruleset hash and existing duplicate-ID
checks apply to every `.des` and Lua hook.

## Portal clock and travel ownership

Reuse the generic staged `luaPortal` transaction. Go continues to own
bounds, occupancy, staging, rollback, and retirement. Bailey-specific
choice, generation, timer, messages, save checks, and travel policy remain
Lua. The source gate has one `timed_marker` on `O`, a 600–800-turn lifetime
drawn once after the theme choice, and the `enter_bailey` feature. Its
dynamic Akara component records the source vault and marker, cell, theme,
creation and expiry action time, spent flag, and message cadence. The
clock begins when the entrance is populated, including when that Dungeon
floor is entered before the player reaches the gate. Global player action
time can close it while its source floor is inactive.

Keep the source discovery, speed-band, final-warning, and expiry wording:
the roar of battle, creaking portcullis, its nearly lowered warning, and
the closing thud. Preserve the five source remaining-time bands and use
the existing hearing and Silence policy at the gate and player. A silent
notice still advances its saved schedule. An entry accepted on its last
valid turn completes before expiry can consume it. Once expired or spent,
the source cell becomes the authored stone arch. The saved component, not
the arch glyph, distinguishes a spent gate from an expired one.

The player owns a saved Bailey visit component with the exact outside
level and coordinate, selected theme, selected layout, and temporary level
ID. The source `exit_bailey` returns to that cell and retires the temporary
floor and its entities. A blocked outside cell rejects exit without moving
the player, consuming time, or retiring the level. Failed map selection,
placement, population, or commit leaves the outside gate, player, RNG,
levels, and entities unchanged. No Bailey-specific Go travel path is added.

## Save, terminal, and mod contracts

Add distinct Bailey entrance and exit terrain features to the Go grid
vocabulary and Lua/terminal presentation. The gate and return messages
appear in the ordinary message panel. Restore validates the portal
component against its source marker, deadline, theme, spent state, and
outside feature. It validates an active visit against the selected
theme-tagged map, temporary floor, exit, and reciprocal outside site.
Restore must not redraw the theme, duration, layout, or authored entities.

The modding guide documents both Bailey directories, theme tags, the
mapless dispatcher, hook locations, portal and visit state, and a sparse
added-layout example. Replacing a same-path file changes only that
effective file; malformed hook or missing required theme pool fails with
a clear error before a game can enter a broken map. The port inventory
records exact Bailey coverage and any wider gameplay gaps.

## Verification and review artifacts

- Audit all 25 effective definitions and compare their committed `MAP`
  blocks to the pinned source. Check source weights, tags, D:7–10 range,
  directive order, and every named hook without requiring the C++ checkout
  during normal tests.
- Put Lua behavior checks in `_test.lua` files that import the same IDs,
  schemas, and policy modules as production; do not redeclare them in
  a parallel test catalog.
- Generate and populate each of the 15 playable layouts through the real
  dispatcher and placement path. Exercise both themes, authored gear and
  loot, traps, delayed decay, feature names, exits, and sparse mod addition.
- Test theme and duration draw order, 600–800-turn bounds, source messages,
  Silence and hearing, on-floor and off-floor expiry, last-turn entry,
  exact return, save/restore at each stage, and forged or inconsistent
  theme, marker, visit, and map state.
- Test failed staging rollback, blocked return, spent/expired gates, and
  temporary actor and item retirement. No failed attempt may consume RNG
  or leave a partial floor behind.
- Extend the text-snapshot helper used for generated Dungeon floors to
  export Bailey floor maps and a connection index. Check in a readable
  sample for all 15 layouts, so the authored geometry and Dungeon return
  link can be inspected without running a terminal client.
- Run focused Lua and integrated Go verification at the domain boundary,
  report broader suite limitations honestly, check changed-file style and
  diff hygiene, then commit and push one contiguous Bailey category.
