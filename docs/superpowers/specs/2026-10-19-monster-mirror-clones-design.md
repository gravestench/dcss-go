# Monster mirror clones

## Intent

Make Rakshasa's Phantom Mirror and Mara's fake summoning produce living,
saved monster copies. Both spells use the existing monster cast pipeline.
The copies retain the original's current combat body and independently
owned equipment. Lua owns every rule; Go only supplies its existing ECS,
grid, and save primitives.

## Source behavior

The pinned DCSS `mon-cast.cc` chooses one nearby, aligned, mobile,
unsummoned, nonconjured, nonunique ally for Phantom Mirror. It copies that
ally at full current and maximum HP, gives the copy a degree-five summon
lifetime, and marks the copy so it cannot mirror again. Mara instead copies
itself at half current and maximum HP, up to two active fake Maras. A copy
starts beside its source. The source may swap positions with a successful
copy on a coin flip to conceal the original.

`mon-clone.cc` copies carried equipment and the monster's current body
state. The Go implementation copies only state whose current owner is the
monster actor: HP, speed, effective HD, selected timed bodily effects, and
new item entities for equipped gear. It does not duplicate a source actor's
world origin, death trigger, summon ownership, AI target handle, or entity
references to other actors. The mirror gets its own summon owner and timer.
Once placement succeeds, the source is freed from trapping and direct
constriction; the clone never inherits those outside bindings.

## Ownership

- `policy/combat/monster_summons/mirror.lua` owns eligibility, candidate
  choice, cloning, state copying, position swap, and cap checks.
- One saved Lua component marks a mirror copy. Spell planners reject this
  marker so copies cannot recurse through the mirror spells.
- Two small spell effect files select the Phantom Mirror or fake Mara rule.
  They do not construct entities themselves.
- A shared item-copy function is used by the mirror owner and the existing
  chaos clone effect, so both create independent item entities.
- Restore rejects a mirror marker without a valid summoned actor, source
  spell, and positive derived HD. The source monster may have died.

## Boundaries

`SPELL_SUMMON_ILLUSION` belongs to the next category. Its player target
requires an independent player-ghost profile with saved derived attacks,
defenses, resistances, and spells; treating that as an ordinary catalogue
monster would make Mara's illusion misleading. This mirror slice provides
the monster-copy owner that the later illusion category can reuse.

## Verification

Lua tests cover eligibility, two fake Maras, selected ally identity, HP,
equipment independence, summon state, swap, stale plans, and failed
placement. A live monster test casts and resumes a copy after save/restore.
Run the Lua rule suite, focused live test, build, style, and diff checks
before one category commit, then fast forward and push `main`.
