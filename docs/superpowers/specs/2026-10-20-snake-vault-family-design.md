# Snake Pit Entrance and Ordinary Vault Family Design

## Purpose

Complete the non-finale content from the pinned source `snake.des`. Eight
`snake_entry` definitions own scheduled Lair entrances to Snake. Sixty-eight
other definitions supply Snake's ordinary, extra, and explicitly oriented
vaults. The nine already committed Snake:4 endings stay with the existing
end-vault owner.

## Source content and selection

Commit each remaining source definition as one DES file under
`vaults/snake_entry/` or `vaults/snake/`. Keep MAP rows and gameplay
directives in source order. The source's file-level `default-depth: Snake`
becomes an explicit `DEPTH: Snake` on each affected ordinary file, because
individual files must remain independently loadable. Keep source inline
Lua as comments at its original position and replace its executable site
with one named hook. The hook implementation belongs to a readable Lua
module in the corresponding `policy/generation/vaults/<family>/` directory.
No importer is checked in or required at build or runtime.

The effective layered catalog discovers added and replaced DES files.
Unoriented maps use the shared depth-qualified minivault draw; explicitly
oriented maps use the branch-family regular draw. Source `DEPTH`, `WEIGHT`,
`TAGS`, and `PLACE` constraints remain authoritative. Every ordinary map
uses the existing DES placement, population, and saved vault-history path.
No source map is made eligible solely to satisfy a count.

## Scheduled entrances

The shared branch-entry owner gains a small declarative spec for Snake,
alongside Temple and Slime. It draws all effective `snake_entry` maps in
stable ID order with source weights and retries another candidate after a
fit rejection. The placed `KFEAT: O = enter_snake_pit` cell is the actual
linked stair to Snake:1. `dummy_snake_entry` participates with its source
weight. If no source map fits, keep the existing single-stair fallback.
The chosen map identity and typed records survive save/restore.

## Verification and limits

Audit all 76 definitions against source MAP rows and gameplay directives,
allowing only the explicit inherited depth and named-hook substitutions.
Exercise all source definitions through the DES engine, all scripted
branches, effective-catalog counts, candidate isolation, and a scheduled
Lair-to-Snake entry with reciprocal travel and restore. A sparse mod adds
one entry and one ordinary file without a Go registration edit.

Source directives whose gameplay consumer remains unported stay as typed
records and are named in the port inventory. This slice does not claim all
Snake monsters, terrain hazards, or branch events have gameplay parity.
