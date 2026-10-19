# Monster timed-area spell slice

## Purpose

Port both monster spellbook auras that repeatedly damage nearby actors:
Olgreb's Toxic Radiance and Polar Vortex. Each cast starts a timer on the
caster; later actions use the caster's current position. The effect must
continue after save and restore. These are complete spellbook effects, not
one-time damage approximations.

## Ownership and flow

- Each `policy/combat/monster_spells/<spell>.lua` owns its cast decision,
  source duration and power, message, and state initialization.
- Registered ECS components own the ongoing aura and cooldown. A focused
  Lua system advances them on the affected monster's actions; no Lua module
  variable stores per-game state.
- Polar Vortex uses the existing actor-neutral wind and impact rules from
  the player spell. Refactor the player spell module into focused policies
  where that removes duplicated geometry or damage logic. The player and
  monster retain their own cast contracts and durations.
- Toxic Radiance uses the source LOS_NO_TRANS pulse shape and monster
  alignment rule. Poison application follows the existing player and
  monster health and poison owners.
- The ordinary monster spellbook dispatcher loads each named spell file;
  no central spell switch or special Go handler is added.

## Source behavior

- A monster can start Radiance only when it is not already radiating and
  a susceptible enemy is in line of sight. Duration is
  `(4 + random2avg(power / 15, 2)) * 10` aut, with spell power based on the
  caster's hit dice. It pulses immediately and once per later monster
  action before duration decay. The caster and its allies are spared.
- A monster can start Vortex only when neither active nor cooling down.
  A nondemonic ally avoids exposing the player. The storm grants flight
  and lasts 60 aut; wind reach, ring damage, tree destruction, and victim
  rotation follow the shared source-derived vortex policy. At expiration
  the cooldown remains as saved state until it decays.
- The player spell contracts remain intact, including their existing
  start-of-cast and tick behavior.

## Verification

Focused Lua tests import production definitions and cover cast refusal,
immediate and later pulses, ally filtering, state expiration, cooldown,
and save-shaped component values. A live Go test casts each spell through
the monster spellbook and checks continuation across save and restore.
Run the Lua suite and targeted Go game tests once the category is assembled,
review it, then commit the whole category once.
