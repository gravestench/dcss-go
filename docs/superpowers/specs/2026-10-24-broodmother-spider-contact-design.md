# Broodmother spider contact

## Intent

Complete the source `AF_SPIDER` natural bite used by Broodmother. A
successful damaging contact can produce one spider next to the wounded
actor. The spider must be an ordinary timed Akara summon, with the
Broodmother as owner, and remain valid after save and restore.

## Approaches

Copying the Summon Spiders spell's roster into the melee dispatcher is
quick but lets its weights drift. Calling the spell resolver would choose
an unrelated count, anchor at the caster, and attribute the offspring to
a spell. The chosen approach shares only the source species pool with
the spell. The bite owns its one-in-three gate, wound anchor, and native
monster source; the common summon owner handles placement and lifetime.

## Contact and summon

Only a landed contact with positive post-armour physical damage reaches
the one-in-three melee chance. The existing melee dispatcher already
rejects misses, blocks, dodges, and dead defenders. The wound's defender
cell is the summon anchor; the common placement owner chooses a legal
adjacent cell and silently fails if none exists.

`summon_spider` chooses Redback and Jumping Spider at weight 100 each,
Tarantella at 75, Culicivora and Orb Spider at 50 each, and Wolf Spider
at half the power. For the bite, source power is attacker HD times 12.
It creates at most one actor at abjuration degree three, with no separate
cap. The source category is `monsters` and its ID is the effective
attacker species, so native offspring are not mislabeled as a spell.

The melee chance uses the melee random stream. Spider selection,
placement, and expiry use the summon owner's stream. This preserves the
port's named-stream isolation without changing source weights or timing.
The player sees the source wound message only when creation succeeds.

## Save and mod behavior

Save validation accepts a monster-origin spider only when its source
profile contains the Spider attack flavour and its kind is in the shared
roster. An effective modded monster with that flavour uses the same
path. The existing summon owner continues to validate owner references,
attitude, and expiry.

## Verification

Production Lua tests cover both target types, chance and damage gates,
source weight boundaries, blocked placement, real melee dispatch, and
summon records. The production Lua save validator checks native provenance;
existing game-level summon restore tests cover the generic serialized state.
