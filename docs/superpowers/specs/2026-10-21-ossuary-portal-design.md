# Ossuary Portal Design

## Intent

Port Ossuary as one playable early-game domain. A Dungeon character can
find an authored, temporary entrance on D:4–8, enter one source Ossuary
layout, face its monsters and traps, collect its loot, and return to the
exact outside cell. Expiry, travel, the selected map, and the special
sliding-wall event survive save and restore. A mod can replace or add an
entrance or destination through the layered VFS. The result keeps DCSS's
map syntax and uses readable Lua for its rules.

## Source maps and scripts

The pinned `crawl-ref/source/dat/des/portals/ossuary.des` has 34 active
`NAME` definitions: 14 Dungeon entrances and 20 one-floor destinations.
Commit each definition as an individually replaceable `.des` file under
`vaults/ossuary_entry/` or `vaults/ossuary/`. Preserve authored `MAP` rows,
static directives, weights, tags, orientation, and directive order. Runtime
and builds read only committed Go and Lua assets; no importer or C++ checkout
is required to play.

The source file's executable Lua becomes documented Lua handlers at the
same generation stage. Source-position `:` hook calls remain in each `.des`
file; shared and substantial behavior uses named Lua modules so it can be
read and tested directly. These include the shared `ossuary_portal` and
`ossuary_setup_features` rules, the coin flip in
`nicolae_ossuary_entry_plus`, the conditional substitutions in
`ossuary_tomb_2`, the source loot expressions in `ossuary_crypta` and
`ossuary_the_hunt_dpeg`, the flood and rock-colour choices in
`ossuary_zaba_flooded`, and the synchronized markers in
`ossuary_boxes_badplayer`. Preserve their source draw order and
probabilities. The flood chooses one floor seed by reservoir sampling,
draws its source 6–16 range, and applies the source glyph replacement
weights. DES-local Lua is permitted where it improves an authored layout;
the current named-hook parser needs explicit support before executing such
bodies. Never place Lua source in Go.

The shared entry hook gives every entrance one keyed `O` gate, a timed
marker, source sand colour and tile directives, and the source
`uniq_ossuary no_monster_gen chance_ossuary` tags and chance 500. Declare
selection metadata statically in each `.des` file because selection runs
before source-position hooks. The shared destination hook makes `<` an
Ossuary exit after source substitutions. All authored item, monster, trap,
feature, and marker requests pass through the existing typed placement
and Akara population path. A broader gameplay effect that is not yet
ported must remain an explicit typed saved record and an inventory gap;
it cannot be silently discarded or made to block a valid source layout.

## Selection and floor generation

Only eligible D:4–8 floors may select a source entrance. Use the ordinary
source chance, weight, used-map, and placement rules. On entry, choose
among every positive-weight effective Ossuary destination by stable vault
ID and source weight. A sparse mod file joins the correct pool without a
Go content switch or directory-order-dependent seed. Each destination is
an encompassing map on one temporary Ossuary floor. Its source map ID,
placement records, entities, items, traps, and terrain are saved. Every
selected map must produce a safe arrival cell and at least one live exit.

## Portal, timer, and travel ownership

Reuse the existing generic staged Lua portal transaction. Go validates
bounds, occupancy, level lifecycle, and rollback; Lua owns the Ossuary
choice, clock, messages, travel, and return rule. The live entrance is an
Akara entity with a source marker reference, cell, once-drawn 600–800-turn
duration, creation time, deadline, spent state, and saved message cadence.
An Ossuary Lua system advances the deadline on global player action time,
including actions on another floor. An accepted entry on the last
available turn completes before expiry can close the gate. Entry spends
the outside gate and makes its cell the source `expired_portal` feature.

The source timer first announces the hiss of flowing sand and the
temporary entrance. Its periodic messages use the source slow, ordinary,
brisk, quick, and rapid bands; its final warning is "The hiss of flowing
sand is almost imperceptible now." A visible expiry says "The hiss of
flowing sand is gone." Unseen expiry follows the source timed-marker
message. Hearing uses the existing Lua Silence owner at the source and
player, plus the source default hearing distance. A message check that
passes while silenced still advances its saved schedule; reloading cannot
restart the announcement or redraw the duration.

The player owns one saved Ossuary visit component with the outside level
and exact return cell. The exit consumes it, moves the player back, and
retires the temporary floor and its dynamic entities. A blocked return
cell refuses travel without choosing a different location or spending
time. Failed generation or population leaves the outside gate, level,
entities, RNG, and player state unchanged.

## Synchronized wall event

`ossuary_boxes_badplayer` has source `:` trigger markers and `a`/`b`
disappearing-wall markers. Entering any synchronized trigger cell fires
the callback once, changes every surviving marked wall to floor, emits
"There is a click, and some walls slide away!", and consumes the whole
trigger group. Extend the existing Lua vault-trigger owner with a saved
group identity and source record links; keep callback behavior in a
focused Ossuary Lua module. Save validation checks the group and wall
records against the selected map. Restore must neither rearm an already
fired group nor leave only some of its walls changed. No Ossuary-specific
Go event path is added.

## Client, saves, and modding

Add distinct Ossuary entrance and exit terrain IDs to the grid vocabulary
and terminal presentation. The source gate and return text appear in the
game message panel. Save validation joins each active clock to its
authored marker, deadline, grid feature, and spent state. A live visit
must point to the selected saved Ossuary map and reciprocal outside cell.
The modding guide explains the two vault directories, named hooks, timer
and trigger components, and a sparse added-map example. The port
inventory states exact implemented coverage and any remaining broader
gameplay gap.

## Verification

- Audit all 34 effective definitions and compare every committed `MAP`
  block to the pinned source. Validate each named hook and reject a broken
  same-path override before its map can be selected.
- Generate and populate all 20 destinations through production placement;
  check source weights, exits, safe arrivals, item and monster records,
  flood choices, and sliding-wall marker placement.
- Test D:4–8 eligibility, source chance, timer cadence, Silence,
  visible and unseen expiry, expiry on inactive floors, deadline entry,
  exact return, and blocked return.
- Test the synchronized wall event before and after save, including a
  forged or partly opened group. Test save/restore on either side of the
  portal and failed staging rollback.
- Test a sparse mod-added destination and a same-path hook override without
  changing built-in discovery order or seeded draws.
- Run focused Lua and integrated Go game, terminal, and save tests; compile
  every package; check style and the staged diff. Commit the complete
  Ossuary category on `main` and push it to the user's fork.
