# Ice Cave Portal Design

## Intent and source

Port Ice Cave as one complete, playable one-floor portal domain. A character
finds a source entrance on an eligible floor, hears and sees its melting
deadline, enters a source Ice Cave map with the correct easy or hard variant,
fights and collects its authored content, and returns to the exact outside
cell. The gate, difficulty, selected map, authored entities, and visit survive
save and restore. Mods may replace any source file or add a separately named
entrance, map, or hook through the layered virtual filesystem.

The pinned source is `crawl-ref/source/dat/des/portals/icecave.des` at DCSS
commit `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. It defines 15 entry
maps and 11 encompassing destination maps. All 26 are in scope, including
the transporter garden, freezing-vapour caverns, and Jiyva passage. A map
is never excluded merely because one of its monsters, items, or markers is
rare. Normal builds and play use committed DES and Lua; source import tools
do not remain in the repository.

## Content and generation

Commit each source definition as its own `.des` file under
`vaults/ice_cave_entry/` or `vaults/ice_cave/`. Preserve MAP rows byte for
byte and retain the authored directives, tags, weights, orientation,
conditional order, and selection expressions. The existing parser and
placement pipeline interpret DES. Convert executable source-script sites
into source-position named `vault.run` hooks in readable Lua modules under
`policy/generation/vaults/ice_cave_entry/` and
`policy/generation/vaults/ice_cave/`. Keep the original script near each
definition as comments and leave a TODO to consolidate hooks into DES when
DES-local Lua execution is ready. No Lua source appears inside Go code.

The first three entrance definitions use the source broad depth pool:
D:11+, Lair, Orc, Elf, Swamp, Shoals, Snake, Spider. The next four use
D:11–13, Lair, Orc; the last eight use D:14+, Elf, Swamp, Shoals, Snake,
Spider. Their narrower per-map `DEPTH` rules and lower weights still apply.
The common source helper adds `uniq_icecv chance_icecave`, `CHANCE: 500`,
the timed `O` marker, Ice Cave feature, floor and wall colours, and tile
requests. It draws one 600–800-turn deadline when the entrance is placed.
The existing `serial_ice` request can find this new effective entrance pool.
Selection uses effective catalog weights and stable IDs, never filesystem
load order or a handwritten Go list.

The entrance's source branch decides difficulty at placement: easy on
D:11–13, Lair, and Orc; hard on D:14–15, Elf, Swamp, Shoals, Snake, and
Spider. The saved ECS gate owns that boolean. Destination generation reads
it without re-evaluating branch state or drawing another difficulty roll.
All 11 maps join the effective IceCv destination pool. Each encompasses a
single temporary floor and must provide a safe arrival at a live exit.
Select by source weight; do not infer order from filenames. A requested map
ID is useful for full-corpus verification and mod tests but must still be
eligible in the effective catalog.

Port every shared source helper and script choice. These cover the three
simulacrum classes, natural and undead/demon monster lists, difficulty
substitutions, authored monster gear, cold-themed armour, freezing weapons,
magic and necromancy loot, potion and scroll pools, coloured terrain,
feature names, and freezing-vapour generators. Preserve source draw order
within a hook. The source `NSUBST`, `SUBST`, `SHUFFLE`, keyed directives,
transporter markers, fog markers, random monster lists, and all source
MAP glyphs must reach normal typed placement and Akara population. Existing
fog-machine and transporter systems consume their markers. A wider effect
whose gameplay owner is incomplete remains an explicit typed saved record
and an inventory gap; placement must never silently discard it.

The Ice Cave branch has no ordinary floor loot generation. Authored loot
and monsters come from the selected map; source random monster lists retain
their intended branch population behavior. The hard variant changes
monster and loot definitions at generation time, not after a cave is saved.

## Clock, travel, and state ownership

Reuse the generic staged Lua portal transaction. Go owns bounds checks,
staging, rollback, level installation, and retirement. Lua owns Ice Cave
selection, generation, timed messages, travel policy, and save validation.
The entrance's saved Akara component records source vault and marker, cell,
difficulty, creation and expiry action times, spent state, closure reason,
and message cadence. The clock begins when the entrance is populated, not
when the player first stands beside it. Global player action time advances
it even while the entrance floor is inactive. It does not restart when the
floor is revisited or a save is restored.

Use the source discovery messages about a wave of frost and the melting
portal, its five crackling-distance bands, final warning, and disappearance
message. The existing hearing and Silence rule decides whether a notice is
audible; an inaudible scheduled notice still advances the saved cadence.
Expiry changes the source cell to `expired_portal` with the authored gone
tile. Entry accepted on the last valid turn completes before expiry. A
spent gate and an expired gate retain distinct saved closure reasons.

The visitor's Akara component stores the exact outside level and coordinate,
temporary Ice Cave level ID, chosen layout, and difficulty. Entry spends the
gate in the same transaction that installs the new floor and moves the
player. The source Ice Cave exit returns to the recorded outside cell and
retires the temporary floor and its remaining actors and items. An occupied
outside cell refuses return without movement, action cost, or retirement.
Failure during map selection, hook execution, placement, population, or
commit leaves the gate, player, RNG, levels, and entities unchanged.

## Save, presentation, and mod contracts

Add distinct entrance and exit terrain features to the grid and terminal
vocabulary. Render the source frozen archway and its Ice Cave exit, with
ordinary message-panel text and help. Restore validates gate identity,
marker, deadline, difficulty, closure reason, source terrain, and the
active visit's reciprocal return and selected map. Restore never rerolls
the difficulty, duration, layout, loot, or monsters. The ruleset hash and
duplicate-ID checks apply to every new DES and hook file.

The modding guide names both directories, the Lua hook API, the gate and
visit fields, the difficulty contract, and how a sparse mod adds one map.
It explains that the mod's map joins the effective pool by branch, tag, and
weight, and that malformed hooks or an empty pool produce a clear error
without partial travel. The port inventory records the exact coverage and
any remaining wider gameplay effects.

## Verification and review artifacts

- Compare all 26 committed MAP blocks and selection metadata to the pinned
  source. Normal tests do not read the C++ checkout.
- Use `_test.lua` files that import the production IDs, schemas, and policies.
  Exercise all 15 entrance hooks and all 11 destinations through the real
  placement and population path, with both easy and hard variants.
- Exercise source depth eligibility and the `serial_ice` request; the
  600–800-turn clock; message bands, Silence, and off-floor expiry; last-turn
  entry; exact return; failed staging rollback; blocked return; and save
  validation of forged or inconsistent gate and visit states.
- Check themed monsters, gear, loot, fog machines, transporters, appearance,
  and source random-monster lists. Test a sparse added map and a same-path
  replacement through the effective layered catalog.
- Check in readable text snapshots for both variants of all 11 destination
  maps, plus a connection index showing each Ice Cave exit and its outside
  return cell.
- Run focused Lua and integrated Go tests at the domain boundary, check
  changed-file style and diff hygiene, then commit and push one contiguous
  Ice Cave category. State any broader suite limits explicitly.
