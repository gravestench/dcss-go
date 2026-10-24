# Monster corpse identity

## Intent

Make death recover a monster's source body rather than its temporary combat
form. The pinned DCSS source records two identities on a corpse: its species
(`mon_type`) and its original class (`orig_monnum`). This matters for
polymorph, shapeshifters, and ordinary classes such as Orc Knights.

## Design

- The live ECS actor keeps its combat species until death, so XP and combat
  continue to use the body it actually fought with.
- Corpse creation resolves its true class from the first source identity
  written by polymorph or shapeshifter status. A shifter marked after an
  earlier polymorph retains the earlier class; a natural shifter or one
  marked before polymorph retains its shifter variant. It resolves corpse
  species from that class's catalog `species_id`.
- The Go host `core.corpse` record stores both `monster_id` (corpse species)
  and `original_monster_id` (true class), plus `death_kind_id` (the body at
  death) alongside freshness and appearance. Beogh's saved actor is the
  death-time Orc, even if the corpse species predates polymorph.
  A corpse whose true class is a shifter also records
  `shapeshifter_source_id`, the actor class present before the shifter mark.
  Existing species-only records without the latter interpret it as
  `monster_id`; old class-shaped corpse records are not migrated.
- Source species rules decide whether a corpse can exist. The corpse roll
  and appearance draw keep their existing persisted RNG stream.
- Restore validates both identities and their relationship. Generated
  population checks use the original class because population rows list
  classes, while Beogh Resurrection checks the death-time Orc class against
  its saved follower profile. An authored vault shifter corpse must match its
  recorded source class to the selected vault actor. Species consumers
  continue to read `monster_id`.

## Evidence

Lua rule tests use production catalog and ECS schemas for an ordinary class,
a polymorphed monster, both shifter orderings, generated population, Beogh,
and authored vault origin. A game test kills a transformed monster and
restores the resulting corpse. Focused corpse and game tests run before the
category is committed and pushed.
