# Monster conjured constructs

Battlesphere, Conjure Ball Lightning, and Spellforged Servitor now cast from
monster spellbooks. Their player and monster creation paths share Lua summon
policies, while Akara components preserve owner, lifetime, hit dice, charge,
and chosen spells across Go saves.

## How the slice works

- Battlesphere is one actor per caster. A monster casts it only while it has
  no living sphere. A later successful conjuration signals the sphere after
  the spell resolves; source sight and ray checks choose an unaligned foe,
  and the saved charge decreases on a shot. The player recast path still
  recharges its existing sphere.
- Conjure Ball Lightning attempts three adjacent actors. Each has source
  monster HD, a short lifetime, and its caster's allegiance. Contact,
  timeout, or death resolves one electrical explosion with the caster's
  monster spell RNG stream, target armour, and resistance.
- Spellforged Servitor snapshots its caster's eligible spells in source
  priority order when a monster resolver exists for each spell. The IDs and
  rolled frequencies live on the
  servitor's component. The ordinary monster AI projects that snapshot as
  a spellbook, selects its spells, and executes the shared effects. A mod
  can add a missing resolver file; the next newly summoned servitor can
  then inherit that spell without changing the engine.

Sparse live spellbook fixtures exercise all three casts and save/restore
continuation. Focused Lua tests cover source counts, HD, ownership,
frequency projection, damage, and RNG ownership. Live game tests also
verify a later monster conjuration fires its battlesphere and a summoned
servitor casts its inherited Iron Shot.

Living Spells and their walking-tome caster family remain in a later slice,
which will also add the missing monster Iceblast effect.
