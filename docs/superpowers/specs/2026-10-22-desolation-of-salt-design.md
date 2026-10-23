# Desolation of Salt design

## Intent

Port the whole Desolation of Salt portal domain from the pinned DCSS source
into Crawl's Go engine and Lua game rules. A player should encounter a timed
entrance in its eligible branches, enter one of the authored Desolation floors,
find its ruin submaps and salt fog, and return to the exact outside cell.
Modders should be able to add or replace a single entrance, ruin, or floor
without editing a central registry.

## Source and scope

The source is `crawl-ref/source/dat/des/portals/desolation.des` at the pinned
DCSS revision. It contains nine entrance maps, 54 `desolation_ruin` helpers,
and three complete floors. All 66 source MAP blocks will be committed as
individual `.des` files, preserving their MAP bytes and source directives.
One-time extraction is a development operation; routine builds load only
committed content. Original script statements become named Lua hooks at the
same DES positions. The eventual consolidation of these hooks back into DES
remains a TODO in the code.

The 66 committed MAP blocks were compared byte for byte with the pinned
source. The SHA-256 of the sorted `name SHA-256(MAP block)` manifest is
`e07431b6e40faeb57e55d6f36279af3a2d45ba9ab4e7a7949261b401fc81a010`.

The source has a 600–800-turn entrance clock, an expired portal feature,
wind messages, and a five-percent chance in eligible Elf/Vaults depths.
The Vaults special-room draw follows pinned `v_rooms.lua` order: it tries
Wizard Lab first, then Desolation. A successful Desolation draw replaces
the earlier special-room choice. There is one Desolation attempt per Vaults
floor, not a second ordinary entrance chance. The three destination
layouts retain source weights,
source `SUBVAULT` selection, exit arches, rewards, terrain, creatures,
and fog machine markers. Branch entry uses the source entry message.

## Architecture

* The effective layered VFS discovers the 66 DES maps by path and stable ID.
  Their family is determined by source tags, branch depth, and explicit
  domain path, never by filesystem enumeration order.
  Each entrance file carries the inherited source `default-depth` as an
  explicit `DEPTH` directive; each destination carries `DEPTH: Desolation`.
* The DES interpreter keeps source operation order. Hook files implement
  `desolation_portal`, `desolation_ruins_setup`, library scroll choice,
  conditional temple shuffle, and floor visual rules through the existing
  vault API. There is no Lua embedded in Go.
* A domain Lua policy selects an eligible destination with stable weighted
  order, builds the entire floor, places ruin helpers through generic
  `SUBVAULT`, and identifies the first authored exit as the landing.
* A Desolation Lua portal handler owns marker materialization and stair
  directions. The existing staged portal transaction owns atomic entry,
  return, floor retirement, and save state. A saved ECS component owns each
  clock; a saved visit component owns the exact outside return address.
* The generic fog-machine system owns salt cloud emission after marker
  placement. Existing monster/item systems interpret placed records.

## Behavior and invariants

Generation has one candidate draw, with stable ID sorting; a requested ID
is allowed only when eligible. The three complete layouts are candidates,
while ruin and entrance maps are not. All 54 ruin helpers remain selectable
by source `desolation_ruin` tag, subject to fit and source uniqueness tags.
Every generated floor has an exit. Every placed source marker, creature,
item, and ruin ID survives save and restore. A failed placement or portal
entry leaves RNG and world state unchanged. Entrance clocks keep running
while their outside floor is inactive and do not restart on return.

Tests verify all source MAP bytes against the pinned source, register and
place all 66 maps, enumerate eligible entrances/floors, generate each floor,
exercise timed expiry and round-trip travel, save/restore, and sparse mod
overlays. Text snapshots of all three generated floors show their exits,
walls, salt, ruins, and connectivity.

## Approaches considered

The selected approach ports source DES files and small named Lua hooks.
It preserves the modding surface and source geometry while using the
existing generic vault runtime. A direct Go rewrite of three floors
would conceal source rules in engine code. Hand-authored Lua copies of all
maps would duplicate the source data and invite drift.

## Boundaries

This slice implements Desolation-specific behavior and any generic vault,
monster, item, or fog rule needed by its authored maps. It does not
introduce a second portal framework or a compatibility runtime for the
original DCSS Lua API. A missing rule is a failing acceptance check, not
a silently accepted placeholder. Unrelated gameplay outside Desolation's
authored content stays with its own domain slice.
