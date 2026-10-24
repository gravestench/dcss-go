# Monster elemental contact in Crawl

## Intent

Complete the source monster melee flavours Holy, Pure Fire, and Sear for
player and monster defenders. The committed Apis, holy swine, pearl dragon,
Bennu, fire elemental, fire vortex, and searing wretch definitions already
name these flavours. Their contact effects belong in Lua and must work for
ordinary and summoned actors through the same melee path.

## Approaches

One option is to add three cases to the central flavour dispatcher and leave
the fire vortex's separate summon combat path. That keeps duplicate damage
rules and misses future status effects on special summons. The selected
approach gives this related group a focused Lua module and routes fire
vortices through the ordinary contact sequence. It reuses the existing fire
resistance, health, and saved fire-vulnerability owners. A wider rewrite of
all remaining flavours would mix unrelated inventory, mutation, and summon
systems into this slice.

## Contact rules

- Holy grants a separate bonus of `floor(attack base damage * 3 / 4)` to
  susceptible undead and demonic defenders. A living or exceptionally
  resistant defender gets no bonus. The source computes this from the attack
  definition's damage, rather than the HP already lost to the physical hit.
- Pure Fire triggers on a landed contact even when physical damage is zero.
  It rolls `floor(HD * 3 / 2) + random2(HD)`, lets a half armour roll absorb
  damage, then applies current fire resistance. A fire vortex dies after its
  successful contact; a missed, dodged, or blocked contact leaves it alive.
- Sear runs only after physical damage passes armour, even if later HP
  mitigation absorbs it. One in three such hits
  adds `3 + random2(attack base damage)` turns of fire vulnerability. Player
  duration caps at 50 turns; monster duration stacks according to the
  existing enchantment owner. Fire damage immediately reads this saved state.

All three apply through both monster-versus-player and monster-versus-monster
contact dispatch. Source credit for a friendly monster's killing secondary
damage goes through the existing player-kill signal. Reflection can kill the
attacker before the flavour phase; its flavour then stops. Pure Fire reads
the defender's AC again at this phase because physical injury can activate
armour before the second packet.

## Verification

Production Lua tests use the catalog and component schemas to cover both
defender types, eligibility, zero-damage Pure Fire, half armour, fire
resistance, Sear duration and cap, and fire vortex death only on contact.
The existing save and elemental tests protect the shared state. The entire
category is one commit on `main` and is pushed to the configured fork.
