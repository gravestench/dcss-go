# Ordinary Shoals vaults

## Purpose

The playable Shoals branch has entrances, island terrain, tides, and endings,
but its ordinary authored encounters are absent. Port all 74 remaining
non-entry, non-ending definitions from the pinned `shoals.des` together so
Shoals floors can select the complete source family.

## Content and behavior

- Commit one readable `.des` file per source `NAME` under `vaults/shoals/`.
  Preserve `MAP`, static directives, tags, weights, and source operation order.
  Make the inherited `default-depth: Shoals` explicit in each file.
- Replace the 12 maps' inline Lua sites with named hook declarations at those
  sites. Keep original script text as source comments, and implement each
  actual choice or effect in a focused Lua handler. Use existing typed effect
  records for delayed decay and the existing deterministic hook API for
  branch-depth choices. The shared source ghost and weapon helpers become
  readable Lua policy, not DES interpreter compatibility layers.
- Reuse the effective vault catalog, weighted regular/minivault selectors,
  placement, ECS population, tide markers, and saved vault history. No file
  index or source order may influence seeded selection.
- Keep authored item, monster, feature, and marker requests in DES. If a
  source mechanic lacks a live consumer, retain its typed placement record
  and document the remaining gameplay gap explicitly.

## Verification

Compare all 74 source `MAP` blocks and static directives to the pinned file.
Load every definition through the production catalog, execute every named
hook through the real resolver, place representative scripted and ordinary
maps, and generate Shoals floors through the live game path. Check saved
selection and travel; run focused tests and compile all Go packages once.
