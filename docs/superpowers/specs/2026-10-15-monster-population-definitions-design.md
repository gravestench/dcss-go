# Monster-owned Dungeon population rows

## Intent

A monster mod should describe its Dungeon spawn weights in the same Lua
file as the monster definition. The bundled game should use that path too.
Remove the runtime dependency on the aggregate
`data/dungeon_population.lua`, while preserving the pinned DCSS pick order
and weights for every currently supported scenario.

The committed `dungeon-population.json` remains an import artifact. Normal
builds and games use only generated, committed monster Lua files. Import
tools run only for an intentional upstream refresh.

## Source and ownership

The pinned source is `crawl-ref/source/mon-pick-data.h` at revision
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. Its 125 Dungeon rows
refer to 120 defined monsters. The exporter joins those rows to the
corresponding generated monster definition. The row inherits the owning
definition's monster ID instead of repeating it as a string. Each row
carries a stable `source_order` for the source picker order, depth range,
rarity, and curve.
Source lines are comments beside generated rows, not runtime fields.
Population curves use named values imported from
`constants.population_curves` in the generated definitions and policies.

`policy.population.pool` reads monster definitions through the registered
catalog. It sorts source rows by `source_order` and retains the existing
weighted pick calculation. Mod rows without `source_order` follow source
rows in registered monster order and require a `scenario_id`, preserving
today's extension behavior. A mod can replace a monster file to adjust
its source rows or add a new monster file with its own scenario rows.
There is no central population ID table or second registration path.

`content.validation` checks row shape, curves, source-order uniqueness,
and spawnable monster fields. It reports the monster file origin for a
bad row. A source-order row applies wherever the scenario roster allows
that monster. A mod row applies only to its named scenario and can extend
that scenario's allowed roster.

## Compatibility and verification

The exported per-monster rows preserve the current ordered pool and total
weight at D:1 and D:2 for both fixed and generated scenarios, including
duplicate monster IDs from separate source rows. Changing only the file
layout must not change a fixed seed's spawn sequence. Ruleset hashes will
change because the effective Lua paths and bytes change; existing saves
need the explicit ruleset-mismatch policy already provided by the engine.
The pinned duplicate-ID pairs have disjoint depth ranges, so tests preserve
both rows and their source orders rather than expecting both in one pool.

Tests exercise source-order parity, duplicate rows, a one-file modded
monster with a scenario row, same-path override, invalid rows, exporter
staleness checks, and save identity. Gameplay tests live in `_test.lua`
and import production definitions. Go tests cover the exporter and host
save bridge only where Lua cannot reach them.
