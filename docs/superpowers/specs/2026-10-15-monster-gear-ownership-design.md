# Monster gear owned by monster definitions

## Intent

The committed monster weapon import contains 162 primary and 16 secondary
specifications. Runtime Lua currently copies them into one shared table and
scans that table to find Goblin's equipment. A monster author should find
the weapon specification in the monster's own file, and should be able to
replace that file through the layered mod directory. The two gear behaviors
used by the playable Dungeon slice should live in focused Lua handlers.

## Content boundary

The offline exporter joins the committed `monster-weapons.json` artifact to
the committed monster catalog by monster ID and source revision. It rejects
duplicate primary or secondary specs, missing monsters, and invalid weapon
or brand IDs. Every source row becomes `weapon_gear.primary` or
`weapon_gear.secondary` in its owning `content/monsters/<id>.lua` file.
Source locations remain comments beside the fields; source line numbers do
not become runtime data. Weapon IDs import `ids.items`, brand IDs import
`constants.weapon_brands`, and the two source sentinels import one
`constants.monster_gear_sentinels` module. The old
`data/monster_weapons.lua` export is removed. Normal builds read committed
Lua and do not run the importer or require the C++ checkout.

## Runtime behavior

`policy.population.gear` keeps shared weighted draws and weapon quality
rules. A small `policy.population.gear.registry` accepts one handler per
monster ID; each `policy/population/gear/handlers/*.lua` file registers one
handler and is discovered with the existing policy tree. Goblin's handler
reads its owned primary spec and preserves its current preliminary draws,
sling override, and alternate melee weapon. Kobold's handler preserves its
current special weapon and ammunition sequence. A monster without a handler
gets no gear, matching the current playable slice. Data for all other
monsters is ready in their definitions for later full-game behavior work.

Mods can replace a monster definition at the same relative path to change
its gear data. Mods can add a handler file for a newly added monster or
replace a bundled handler at the same relative path. Duplicate handler IDs
fail at boot. No handler lookup uses a growing monster ID switch.

## Verification and limits

Lua `_test.lua` checks owned specs and their live references through production
catalogs. Go source-parity tests and exporter tests check all 178 rows,
revision and ID failures, and generator freshness. Current fixed-seed Goblin
and Kobold loadouts, inventory saves, and the effective ruleset hash remain
covered by Go integration tests. This slice moves ownership and the active
handlers; it does not claim that the other 160 weapon-bearing monsters can
spawn or equip yet.
