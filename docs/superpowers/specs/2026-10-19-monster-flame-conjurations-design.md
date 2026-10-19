# Monster flame conjurations design

## Purpose

Make all three remaining monster spellbook flame conjurations playable:
Marshlight, Holy Flames, and Stoke Flames. Preserve their DCSS behavior at
the pinned source revision while keeping actor, cloud, and explosion state
in the existing Lua and ECS owners. A mod replaces an individual spell file
without editing a central Go or Lua switch.

## Source behavior

- `mon-cast.cc` casts Marshlight through `cast_foxfire` with effective monster
  spell power. `spl-summoning.cc` tries two fair adjacent cells. Each foxfire
  is a short-lived moving actor that attacks the caster's enemies. A living
  caster must see both foxfire and target cell at contact. Player contact
  uses `1d(4 + min(power, 50)/5)` while monster contact uses
  `3d(3 + min(power, 50)/12)`; target armour and fire resistance follow.
- `spl-clouds.cc:holy_flames` places holy clouds in open adjacent cells around
  the selected foe. It skips existing clouds, solid cells, occupied monsters,
  and sanctuary, but it may place fire beneath an adjacent player. Cloud
  duration is `8 + random2avg(HD * 3, 2)` turns.
- `mon-cast.cc` summons one creeping inferno for Stoke Flames. Its monster
  profile supplies ordinary speed and movement. `mon-explode.cc` resolves a
  Fire Storm power-100 blast when the inferno dies; source monster Fire Storm
  dice and its partially resistible lava flavour govern damage.

## Runtime ownership

`policy/combat/monster_spells/<id>.lua` owns each spell's plan and resolve
contract. Marshlight reuses the foxfire summon policy after making its foe
selection and damage attribution actor-neutral. Holy Flames writes to the
existing world-cloud ECS owner. Stoke Flames writes to the shared summon
owner, while a focused Lua death hook resolves its blast during the existing
`actor.death` system before actor deletion. No spell uses a Go content switch
or unsaved Lua module state.

The player Foxfire path retains its existing behavior. Monster-created
foxfire retains its caster and source spell in saved summon state. All
spell-specific random draws for monster casts and their effects use the
monster-spell stream; shared summon HP uses its existing population stream.
Player casts keep the player spell stream. Target plans are
revalidated at resolution so a changed or dead foe is not silently
retargeted.

## Verification

Lua rules tests cover two monster-owned foxfires, actual target damage,
holy cloud placement and exclusions, inferno creation and detonation, and
no repeated explosion. A live spellbook test casts each spell, saves and
restores the resulting ECS state, and compares next-action continuation.
Run the full Lua suite, focused Go game tests, Go build, and style gate at
the category boundary.

Sanctuary suppression becomes active when the religion slice creates
sanctuary state; the current playable game has no producer for it.
