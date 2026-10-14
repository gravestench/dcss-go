# Rat Corpse and Skeleton in the Fixed Dungeon

## Source and scope

Pinned DCSS revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`: `mon-death.cc:521-595` gives an ordinary eligible kill a 50% corpse chance; `_fill_out_corpse` starts freshness at 110 and draws `1+random2(255)` for appearance. The committed monster catalog marks rat corpse eligible. `corpse.cc:25-104` reduces freshness by elapsed aut / 20, turns an expired rat corpse into a fresh skeleton with a new appearance draw, then removes the expired skeleton. `timed-effects.cc:250-330` schedules corpse rotation at fixed 200-aut intervals, and `item-prop.cc:923-925` plus `items.cc:1305-1324` make corpses stationary. `item-name.cc:1839-1870` displays rat corpse and rat skeleton.

## Ownership and runtime

`monster` owns pure drop and decay rules, taking a named `corpse` roller. `Game` creates a corpse only for a newly player-killed rat, after Akara system update reaches its structural barrier. An ECS Corpse component owns source monster ID, freshness, and appearance. The corpse is a floor item with the already committed corpse/skeleton catalog kind. The game advances active-floor corpses at the fixed 200-aut boundary after player and monster actions. It records when each floor was left and, on return, applies one catch-up decay with the whole absence, matching `files.cc:2185` and `timed-effects.cc:692`. In particular, an expired body resets to a fresh skeleton even after a very long absence. The UI displays the monster-derived name and `%` glyph. A corpse alone underfoot produces the source's no-time pickup refusal; a portable item on the same tile remains pickable.

## Save and validation

The optional Corpse component and per-level away clock are added to version-6 records. Older saves need no migration. Restore requires the component exactly for corpse/skeleton floor items, checks rat species, freshness 1..110 and appearance 1..255, and rejects corpse components on other roles. An inactive floor containing a corpse must carry its away clock. Saved RNG state, freshness, and away clocks continue without reroll. No regeneration of content occurs during builds.

## Verification

Scripted rule tests check draw order, 50% absence, skeleton transition, and disappearance. Game tests cover kill drops, no corpse for pre-dead cleanup, names, pickup, 200-aut boundaries, save continuation and malformed records. Run full Go tests, vet, build, and a read-only whole-branch review before local-main merge.
