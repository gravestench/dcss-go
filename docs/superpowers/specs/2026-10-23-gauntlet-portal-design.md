# Gauntlet portal design

## Intent

Port the complete Gauntlet portal domain from the pinned DCSS source. A
player should find a timed gate, enter an authored Gauntlet, choose among
visible arena routes, use linked transporters to fight for rewards, face
the minotaur, and leave through the authored exit. The floor must survive
save and restore while occupied and retire after the player leaves.

## Source and scope

The source is `crawl-ref/source/dat/des/portals/gauntlet.des` and
`crawl-ref/source/dat/dlua/gauntlet.lua`. The DES file has 60 named maps:
one entrance, 43 arena helpers, six exit helpers, and ten complete parent
layouts. Commit one `.des` file per map with its MAP bytes unchanged.
Convert source Lua statements to named, commented Lua hooks at their DES
positions. Keep the source's map format; leave the existing TODO to
consolidate hooks into DES later. No Lua source belongs in Go strings.
The 60 extracted MAP blocks match the pinned source byte for byte. The
SHA-256 of the sorted `name SHA-256(MAP block)` manifest is
`640b1822b323ac785dd98eabb45f33830271fdbdabb9b66230bde269e056a8bb`.

The source entrance is eligible at D:11 onward, Orc's bottom, and Lair,
with a five-percent chance and a 400–600-turn gate clock. The parent maps
own the route topology. Arena helpers use source first/second tier tags,
monster-set weights, per-glyph creature counts, trap and terrain rolls,
and tier-specific prize slots. Exit helpers own the awake minotaur and
their authored loot rules. The source's `no_pickup` item flag prevents
monsters from taking prizes; it does not stop the player from picking
them up. The source forbids long-range teleporting and suppresses
teleportitis and Passage of Golubria within Gauntlet, while ordinary
blinking remains available.

## Architecture

* The layered vault catalog discovers entrance, arena, exit, and parent
  files by path and source tags. Stable ID ordering makes directory order
  irrelevant to seeded selections. Builds load committed content only.
* A Lua domain generator chooses a complete parent map with source
  weights, places all nested helpers through the generic `SUBVAULT`
  operation, and resolves transporter pairs after terrain projection.
  Parent source hooks carry the selected arena tier and ordinal to their
  child through a scoped nested-vault context. No mutable module global
  retains the current tier, arena count, or extra-prize pattern.
* A shared Lua arena module owns the source encounter tables and the
  `gauntlet_arena_setup` algorithm. It draws one set per helper, then
  emits keyed monster, item, trap, wall, liquid, and plant operations.
  Individual special exit scripts stay in named modules where their
  rules differ.
* A Lua portal handler owns gate clocks, entry direction, exact outside
  return location, exit direction, and Gauntlet-only restrictions. The
  generic staged portal transaction owns atomic floor installation,
  player movement, rollback, save, and retirement. Akara components own
  durable gate and visit state.
* The generic transporter policy owns movement between linked stations.
  Gauntlet prizes use the normal item owner and retain the source's
  monster `no_pickup` flag.

## Behavior and invariants

Each generated floor contains one parent layout, exactly one exit
helper, and all selected arena helpers. Each source transporter has one
named destination, and every player-choice route can reach an exit.
The gate clock begins
when the outside floor is generated and does not restart after loading.
Entry spends the gate once; return goes to the exact outside cell.
Failed generation or movement cannot spend the gate, advance the RNG,
or leave a partial floor. The source monster-set weights and roll order
remain visible in Lua. Save validation rejects broken transporter pairs,
gate clocks, visit pointers, and reward ownership.

The source MAP blocks are compared byte for byte during development.
Tests exercise all 60 definitions, every parent layout, both arena
tiers, transporter routing, monster prize pickup rules, minotaur exits, gate
expiry, round-trip travel, save/restore, and sparse mod overlays. Commit
text snapshots of each parent floor with a legend and route/link index.

## Approaches considered

The selected approach keeps source DES maps and ports the source Lua into
focused modules. It extends the existing nested-vault and transporter
primitives only where they need scoped context or reward ownership. A Go
Gauntlet controller would place game rules in the engine and force every
mod to recompile. A rewritten single Lua map would discard the 60-map
selection surface and make source parity hard to check.

## Boundaries

This is one Gauntlet domain slice. Generic kernel changes are allowed
only for reusable nested-vault context, transporters, or staged travel.
Unsupported authored mechanics are acceptance failures, not inert
records. Unrelated portal or branch behavior remains with its owner.
