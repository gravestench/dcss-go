# Ordinary monster return catch-up design

## Purpose and scope

When the player returns to a visited Dungeon floor, the three supported
ordinary animals should receive the source's single off-level update before
their ordinary turns resume. This covers HP recovery and coarse movement
toward an existing target. It does not simulate every missed turn. The source
path is `files.cc:2185-2186`, `timed-effects.cc:680-759`, and
`timed-effects.cc:378-540` in the pinned C++ checkout.

The existing first visit remains different: no away clock means no catch-up.
The existing corpse update runs first, as in `update_level`. Monster deadlines
are then rebased to the current clock. Restoring a saved inactive floor must
produce the same return result and subsequent turns as an uninterrupted run.

## Ownership and rules

`Level.awaySinceAut` is the authority for elapsed off-level time. An
event-driven monster catch-up system queries Akara `Actor`, `Health`,
`Position`, and `MonsterAI` stores; it mutates only those live components and
uses `Level.MoveActor` to preserve the occupancy index. The immutable monster
catalog supplies the supported kind and speed. `Game` coordinates the return
barrier but implements no monster-specific rule.

For these three HD-1, regenerating animal definitions, the pinned source's
`off_level_regen_rate` resolves to 10 hundredths of HP per player turn
(`monster.cc:2928-2955`, `mon-util.cc:1568-1584`). `turns` is whole elapsed
aut divided by ten. Recovery is `div_rand_round(turns * 10, 100)`, capped at
maximum HP; a nonzero remainder consumes one draw from the serialized
`offlevel` RNG stream. Zero turns consume no draw. This stream keeps this
update independent of normal AI and combat rolls.

The source's coarse movement ignores individual action deadlines. With a
nonzero saved AI target, move at most `min(turns * speed / 10, 50)` steps,
using the sign of each coordinate difference. Stop on the target, blocked
terrain, or another actor. The source does not reroute around an obstacle.
The Go AI's absolute memory deadline expires naturally on its next normal
decision after return. The source's summon, pacification, ranged, enchantment,
and non-land branches await their corresponding live capabilities.

Process monsters by entity ID so RNG draws and occupancy conflicts are
deterministic. Ordinary live play and save validation already reject other
monster kinds; this system should report an unexpected kind or missing
component rather than silently skip it.

## Verification

Tests must cover fractional and integral healing, no draw for zero turns,
movement toward a target with a 50-step cap, a blocked step, no target, first
entry, and save/restore return equivalence. At the category boundary run
Go tests, vet, build, the readability check, and `git diff --check`.
