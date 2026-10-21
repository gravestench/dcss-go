# Vaults End Design

## Purpose and scope

Make Vaults:5 the source end encounter rather than a fifth ordinary Vaults
layout. The floor must contain the authored four-quadrant main map, one real
silver rune, source enemies and loot, reciprocal stairs, and durable save
state. This slice covers the 73 end-map definitions in the reference
`branches/vaults.des`: one main map, 40 ordinary quadrant maps, 25 prize
quadrants, three rune-location helpers, and four inner-room helpers. The
13 Vaults entrance maps in that source file are a separate entry-map slice.

The port keeps `.des` MAP geometry and placement directives as committed
runtime content. Lua modules port the source script decisions. No importer,
generated-content step, inline executable Lua, Go branch switch, or copied
quadrant geometry belongs in the runtime path. Every new Lua file has its
own comments that explain why and how its functions work.

## Main-map selection and composition

Commit each end definition as one named `.des` file. Put `vaults_vault.des`
under `vaults/layout/`, with its source `PLACE: Vaults:$` and an engine
`layout` tag. Put its companion hook under `policy/generation/layouts/`.
The other 72 definitions live under `vaults/vaults_end/`, discovered by the
existing vault catalog. Keep source names, tags, weights, SHUFFLE, SUBST,
MONS, KMONS, KITEM, and MAP cells. Replace each source script site with a
named `vault.run` call at that same position.

The generic layout catalog gives an eligible `PLACE` map priority over
ordinary weighted layouts. Thus Vaults:1–4 still draw one of the eleven
primary layouts, while Vaults:5 always selects its authored end map. The
availability policy opens V:5 only when an effective explicit end layout
can be built. A mod can replace that relative path or register another
eligible `PLACE` end layout without editing Go or a central name list.

The main hook draws the source one-in-36 mall mode and emits the four
quadrant `SUBVAULT` directives in source order. It also records the two
source wall names as typed feature-name data. SHUFFLE chooses which physical
quadrant carries the prize glyph; exactly one prize quadrant and three
ordinary quadrants are selected. The generic DES composer embeds their
MAPs and any nested helpers before population materializes their records.

## Shared local selection state

The DES composer owns one temporary selection state for a level build.
Its tagged helper selector checks effective weights, depth, and used names
before drawing, then records each successfully embedded helper ID. This
prevents non-duplicable quadrants from repeating and makes their selected
IDs part of the level's saved vault history. A failed composition publishes
neither a helper ID nor partial terrain.

Named hooks can ask whether a tag has already been placed in the current
composition. This replaces the source script's implicit global
`dgn.map_by_tag` availability check. The first prize quadrant gets the
source one-in-four chance to claim the real rune; if it declines, the first
ordinary quadrant claims it. A special prize quadrant with nested rooms
uses its rune-room helper through the same claim. Subsequent candidate
locations receive the source no-rune helper. A generation assertion rejects
zero or multiple real rune records before the floor is accepted.

The weighted `vaults_end_rune_mimic` definition is retained as a documented
legacy source record but excluded from live selection. Its referenced item
mimic is removed from the active monster catalog. No ordinary silver rune
item may be used as a stand-in for a mimic, because pickup would grant false
rune progress.

## Source-sized room helpers

Three inner-room helpers have empty source MAP blocks because legacy DES
Lua painted them to the size of their assigned SUBVAULT region. The generic
composer supplies that region's width and height when it creates an empty
helper matrix. A named hook can read the matrix size and set bounded glyphs
at its source position. This is a small map-painting API, not a second
Vaults-specific layout engine. The border helper paints a floor border and
loot interior; the diamond helper alternates money and floor; the traps and
loot helper starts with ordinary floor and applies its source substitutions.
The fourth inner-room helper keeps its authored 6×7 MAP and may select the
real rune in exactly the same local composition state.

## Rune, actors, and saves

The real helper's `KITEM` resolves to the existing `RUNE_VAULTS` item.
The existing ECS item and rune-pickup policies own it after materialization;
the player's saved rune set records collection. Source guard monsters and
out-of-depth `8`/`9` requests use the already branch-aware Vaults population
resolver. No fake rune or second rune ledger is added.

The main map, each selected quadrant and nested helper, terrain, typed
entity records, stair links, and rune item are saved. Restore validates
the one-rune floor before collection, the collected-rune state afterward,
and exact reciprocal V:4/V:5 links. Once the end map is present, V:4's
formerly unavailable stair becomes a pending V:5 frontier in newly created
games. An older save made with that stair unavailable keeps its recorded
boundary until a deliberate save migration is designed; restore must not
silently rewrite its links.

## Verification and modding

Tests parse and count all 73 definitions, exercise every named hook,
confirm one prize and three ordinary quadrants, cover mall mode and both
rune-allocation paths, and reject missing or duplicate rune records. Tests
also exercise every inner-room helper at several region sizes, all source
quadrant maps through the production composer, unique-map selection,
V:4→V:5→V:4 travel, rune pickup, and save/restore before and after pickup.
The modding guide explains how a new quadrant or inner-room helper joins
selection through one `.des` file and, when needed, one named Lua hook.

The full game package currently exceeds Go's default ten-minute timeout
in its exhaustive character-start sweep. This slice uses focused Lua and
game integration tests plus a separately budgeted broad run; no result is
called complete merely because the focused checks pass.
