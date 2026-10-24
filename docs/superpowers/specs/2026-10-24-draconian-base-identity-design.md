# Draconian base identity

## Intent

Keep the colored base of a classed draconian as actor state. The pinned source
assigns each ordinary draconian job a fixed default color and lets an authored
vault choose another base. Corpse and first-polymorph rules consult that base.

## Design

- A focused `monster.draconian_base` ECS component stores the colored base ID
  of a live classed draconian. The spawn factory installs it using a source
  job-to-color table unless an authored valid draconian base overrides it.
  Base draconians and Tiamat need no extra component.
- Polymorph stores roster lineage and corpse lineage separately. Its existing
  `original_kind_id` remains the original job for spawn and save checks. A
  new `corpse_kind_id` records the first source corpse class: a colored base
  for a classed draconian, the ordinary original class otherwise. Once set,
  later transformations cannot overwrite it.
- A new draconian job body receives its own base component. Leaving that body
  removes the stale component. A shifter marked after polymorph inherits the
  earlier corpse class, while marking it first keeps the shifter variant.
- Corpse creation records the death-time class, source class, and colored
  species according to source `_fill_out_corpse`. An unpolymorphed job keeps
  the job as original class but uses its colored base as corpse species. A
  polymorphed job uses its colored base for both original class and species.
  The corpse's general `source_monster_id` field carries roster ancestry for
  all transformed bodies, replacing the shifter-only source field.
- Save validation checks component owners and the relationship between a
  draconian job, its base, and its corpse. Authored vault records may fix a
  color different from the job's default; ambient jobs use the fixed table.
  Corpse roster checks use the branch of the corpse's saved floor so Zot
  draconian jobs are not checked against Dungeon's spawn list.

## Evidence

Lua tests exercise default and authored colors through the real spawn
factory, first polymorph, death, and save validation. A live game test or
equivalent integration verifies snapshot and restore of the ECS state.
