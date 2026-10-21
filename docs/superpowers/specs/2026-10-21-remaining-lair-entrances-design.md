# Remaining Lair Entrance Maps

## Purpose

Finish the authored Lair branch entrance category. Snake, Spider, and Slime
already select source DES maps. The scheduled Swamp and Shoals gates still use
synthetic stairs because their source entry families are absent.

## Source and scope

The pinned `swamp.des` contains ten `swamp_entry` definitions and the pinned
`shoals.des` contains eight `shoals_entry` definitions. Commit one separate
DES file per `NAME`, retaining MAP rows, directive order, tags, weights,
substitutions, monsters, and keyed `O` feature. Swamp fog machine markers
stay in their original declarations. The Shoals room entry's one inline
connectivity check becomes a named `vault.validate` Lua hook at the same
declaration position; the original check remains as a DES comment.

The existing branch schedule decides whether a run opens Swamp or Shoals.
`branch_entry.lua` uses declarative family, tag, and keyed feature metadata
to offer the matching source maps in stable ID order. It draws by source
weight, retries maps that cannot fit protected cells, and falls back to the
ordinary stair only if no candidate fits. The placed keyed `O` cell becomes
the pending branch link; travel establishes a reciprocal link and saves the
chosen map and its typed records.

## Boundaries

This category covers entrance maps and their live branch links. Ordinary
Swamp and Shoals vaults are a separate source family and remain to port.
Fog machines already have ECS runtime and save validation; entrance maps
use that existing marker path. No C++ importer becomes a build dependency.

## Verification

Compare the eighteen committed MAP bodies and static directive sequences
to the pinned source. Use the production DES placement path on every entry,
assert one keyed gate per map, and verify the exact weighted candidate pools.
Exercise Swamp and Shoals travel, fog materialization, reciprocal stairs,
save/restore, and a sparse mod-added entry. Run focused Lua and Go tests,
all-package compilation, and style checks at the category boundary.
