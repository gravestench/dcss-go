# Monster direct strikes design

## Goal

Port the complete family of four committed monster spells that strike one
visible foe without a projectile ray: Smiting, Airstrike, Waterstrike, and
Resonance Strike. Their behavior is defined by the pinned DCSS `mon-cast.cc`
revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. They become ordinary
Lua monster spell effects, selected through the existing spellbook and intent
flow, with no new Go spell switch.

## Ownership and target contract

Each `policy/combat/monster_spells/<name>.lua` file owns its spell formula
and message. A small shared `monster_direct` helper plans a visible entity
within the spell catalog's fixed LOS range, checks the selected foe at
resolution, and delivers damage through player or monster health policy.
Direct strikes do not trace projectile blockers or roll beam hit, shield,
or evasion. A wall blocks visibility; an actor between caster and foe does
not. Planning has no world writes and stores the target handle in the typed
monster intent. Resolution uses the saved handle and current positions.

## Source behavior

- **Smiting:** 7 plus `random2avg(11, 2)` damage. It ignores AC and elemental
  resistance. Source attribution belongs to the caster.
- **Airstrike:** Count empty walkable cells around the target, then roll
  `2 * empty + random2avg(2 + div_rand_round(power, 7), 2)` with source monster
  power `12 * spell HD`. Apply target AC. Air has no resistance here.
- **Waterstrike:** Roll `3d(7 + spell HD)`, reduce for drowning immunity using
  the existing water-beam resistance rule, then apply AC. The text uses the
  target's airborne state when available.
- **Resonance Strike:** Roll `3d(spell HD)` plus one die for each pair of
  nearby allied constructs, with source stochastic rounding for an odd
  count. Apply target AC. The construct count uses the caster's allegiance
  and the source construct type test; it is not every nearby monster.

All randomness uses the saved `monster_spell` stream. The monster's live
spell HD includes drained, wretched, and empowered states through
`monster_stats.spell_hit_dice`. Persistent HP changes use existing ECS
health components. A failed or stale target cannot silently retarget.

## Verification

Lua `_test.lua` tests import production effects, use deterministic context
fixtures, and cover intervening actors, blocked LOS, stale target, damage
bounds, immunity, armour, and construct allegiance. Go game integration
exercises a real monster cast against a player and save/restore continuation.
Run the focused Lua and game tests, then the full Lua suite, build, vet, and
style checks at the slice boundary. The checked-in Lua is runtime source;
no C++ importer runs during build or test. The mod guide gains a concrete
example of a direct monster effect using `ctx`.
