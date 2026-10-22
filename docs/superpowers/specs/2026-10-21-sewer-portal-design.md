# Sewer Portal Design

## Intent

Port Sewer as one complete early-game domain. A Dungeon character should
encounter an authored, temporary drain on D:3–6, enter one of the source
Sewer maps, fight and collect its authored content, return to the exact
outside location, and save or restore on either side of the portal. Mods
must be able to add or replace an entry or Sewer map through the layered
VFS. This is part of the faithful Dungeon Crawl Go port, with source maps
retained and gameplay policy implemented in readable Lua.

## Source and content

The pinned `crawl-ref/source/dat/des/portals/sewer.des` contains 34 named
maps: 15 Dungeon entrances and 19 one-floor Sewer destinations. Commit one
`.des` file per `NAME` in `vaults/sewer_entry/` or `vaults/sewer/`. Preserve
each authored `MAP` block and DES directive order. Replace executable
source Lua sites with named `vault.run` or other supported named hooks at
the same position. Each source function becomes a small, commented Lua
module under `policy/generation/vaults/<family>/`; no source script is
embedded in Go or executed as legacy inline DES Lua.

The source `sewer_portal` helper gives every entrance a temporary portal,
an entry feature, timed marker, water colors, and a `chance_sewer` tag.
Declare its chance and unique tags statically in each `.des` file, because
the selector reads them before the source-position hook can run.
Its `600–800` turn timer is drawn once and saved. `sewer_setup` gives every
destination an exit feature and source water colors. Source expressions
using loot pools must become explicit, source-backed Lua directives without
changing their probabilities or creating a separate content catalog. All
authored monsters, items, traps, altars, feature names, and markers are
passed through the existing typed vault population path. A source feature
whose behavior still needs a broader gameplay domain remains a typed saved
record with a visible, truthful inventory note.

## Selection and generation

Only eligible D:3–6 floors can draw a Sewer entry. The selected entrance
uses the same chance, weight, placement, and used-map rules as other DES
vaults. On entry, select among every eligible positive-weight Sewer map by
stable map ID and source weight. A sparse mod overlay adds a new map to that
pool without a Go switch, directory-order effect, or duplicate ID. A
destination map encompasses one Sewer floor and is generated through the
ordinary DES placement, terrain, and population owners. The source map
identity and all emitted records survive save and restore. A map must have
at least one live exit and a safe arrival cell.

## Live portal and ownership

Reuse the generic Go `luaPortal` staging transaction. Go only validates
level IDs, grid bounds, occupancy, and rollback. Lua policy owns the
entrance clock, gate messages, one-way travel, exact return location,
selection, and post-exit retirement. The temporary drain is a dynamic ECS
entity with a component that records its source vault, cell, creation time,
expiry time, and spent state. A Lua system advances expiry on global action
time even while the player is elsewhere, but an accepted entry on its last
available turn is not cancelled. The outside cell becomes the source's
expired feature when the gate closes or is spent. The player holds a saved
visit component while inside; the exit consumes that visit and retires the
Sewer floor and its dynamic contents.

All custom rules stay in `policy/world/sewer/`, `systems/`, schemas, and
source-specific generation modules. Shared portal services may be
generalized only when the same invariant applies to Bazaar and Sewer;
there is no second Go travel path or per-content Go switch.

## UI and saves

The terminal renders the source drain and exit using distinct terrain IDs.
The visible entry, expiry, and return messages follow the source text. Save
validation checks the portal component against its source marker, clock,
grid cell, and spent state; an active visit checks the selected map, exit,
and reciprocal outside site. A failed generation or population transaction
leaves the entrance, gold, entities, RNG, and current level unchanged.

## Verification

- Enumerate all 34 effective source definitions, validate every hook, and
  compare all authored `MAP` blocks to pinned source geometry.
- Generate and populate every destination map, including rare directives,
  and prove each has an exit and playable arrival.
- Test D:3–6 eligibility, expiry both on and off the source floor, travel
  at the deadline, one-way return, save/restore inside, and a forged save.
- Test failed staging rollback and a sparse modded destination without
  changing the built-in catalog or seeded order.
- Run focused integrated Go and Lua tests, an all-package compile check,
  style checks for changed code, and diff checks before one Sewer commit.
