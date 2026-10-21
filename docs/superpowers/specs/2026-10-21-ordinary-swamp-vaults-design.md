# Ordinary Swamp vaults

## Purpose

The ten Swamp entrances and eleven Swamp endings are live, but the 107
ordinary definitions between them in the pinned `swamp.des` are missing.
Port that complete family so Swamp:1–4 draws its authored decorations,
encounters, controllers, and keyed items through the existing Lua-owned
generation path. Keep each source MAP in DES, with executable decisions in
named Lua files.

## Ownership and format

- Commit one `.des` file per ordinary source `NAME` under `vaults/swamp/`.
  Source `MAP` bytes and static directive order remain authoritative. Write
  inherited `default-depth: Swamp` explicitly on each file that lacks DEPTH.
- Keep catalog-time tags, weight, depth, chance, and place declarations in
  DES. The source `swamp_ruins` helper emits only constant declarations, so
  expand those declarations at its call site rather than hiding eligibility
  in a generation hook.
- Move variable source Lua to named handlers in
  `policy/generation/vaults/swamp/`. Hook calls occupy the original script
  position. A shared helper module handles repeated remains and choices.
- The three mapless decor controllers keep their source PLACE, tags and
  weights in DES; Lua post-place hooks ask the effective catalog for one
  ruin, two or three ruins, or one decor map respectively.
- The Lady of the Lake uses a typed marker and saved ECS movement trigger.
  Its callback spawns one awake merfolk avatar at its marked lake cell when
  the player enters the encounter, with the source visible/ripple message.
- For source directives with no current gameplay consumer, retain their
  typed saved records and name the gap in the port inventory. Never drop a
  map or silently remove its content because an effect is pending.

## Verification

Compare all 107 source MAP blocks and static declarations to the pinned
file, accounting for explicit default depth and expanded constant helper
declarations. Load every definition through the production catalog and
exercise every named script site through the actual placement path. Check
weighted Swamp selection, controller composition, triggered avatar state,
save/restore, and a sparse mod-added Swamp map and handler. Use focused Lua
and Go tests, then compile Go packages once at the category boundary.
