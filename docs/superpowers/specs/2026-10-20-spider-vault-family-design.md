# Spider Vault Family Design

## Purpose

Complete the authored Spider content in the pinned `spider.des` and
`spider_jumping.des` sources. `spider.des` contains eleven Lair entrances,
66 ordinary maps, and nine already committed Spider:4 endings.
`spider_jumping.des` adds one parent and sixteen child maps. The two source
files together own 103 definitions. The new 94 files must be independently
replaceable through the layered mod directory.

## DES ownership

Commit each definition as one `.des` file. Preserve its MAP rows and
non-script directives in source order. Put the eleven entrances in
`vaults/spider_entry/`; put the other 83 new definitions in
`vaults/spider/`. Preserve source tags, weights, explicit depth rules,
and the jumping parent's `SUBVAULT` composition. The file-level
`default-depth: Spider` in `spider.des` becomes explicit `DEPTH: Spider`
only on definitions inheriting it. Jumping helpers inherit no file-level
depth; their shared tag and the parent composition make them available.
No importer is needed at build or launch, and no importer belongs in the
repository.

The existing effective DES catalog chooses ordinary maps and helper
children. The shared branch-entry owner uses the eleven tagged maps for
scheduled Lair-to-Spider stairs. The placed `KFEAT: O =
enter_spider_nest` cell supplies the actual link, source map identity,
and save history. If all source entries fail to fit, the normal scheduled
single stair remains.

## Lua behavior

Move each executable source script into a same-family named Lua hook at
its original directive position. The `.des` file retains a comment at
that position explaining the source script and its replacement. Group
the sixteen jumping helpers around one readable shared setup module;
each child still owns its own `.des` geometry and declares the setup
hook. The setup hook emits source tags, monster request, substitutions,
and `CLEAR` operations in source order. Depth-dependent stairs use a
second named method.

The source's `dgn.delayed_decay` calls use the existing typed
`DELAYED_DECAY` record. The Spider basket's two `player_move` markers
become typed marker records and saved ECS trigger entities. A generic
vault-trigger owner dispatches a named Lua callback on entering its
cell, consumes it once, and leaves unrelated markers alone. The spawn
callback tries each passable, unoccupied cell in the surrounding 3x3
region, excluding the player; it creates awake redbacks and reports the
basket message only if at least one spawns. The warning callback reports
its source message. Other vaults and mods can use the same trigger
contract without adding another Go dispatcher.

## Verification

Compare all 94 new MAPs and ordered static directives against pinned
source, allowing only inherited depth and named hook substitution.
Exercise every definition through the production parser and appropriate
placer, every conditional script arm, all effective selection pools,
and sparse mod discovery. Verify a scheduled entrance's keyed stair,
reciprocal travel, save/restore, and source map history. Verify the
Spider basket's one-shot ECS state and callback after moving onto both
markers. Keep the 9 existing finales exclusive to Spider:4.

Unsupported gameplay from other source directives remains typed level
data and is listed in the port inventory. This slice does not claim
complete Spider monster AI or every branch hazard is implemented.
