# Walking tomes and living spells

## Intent

Make the four defined walking tome species cast their source living spell
instead of retaining an inert shared spellbook. A living spell is a summoned
Akara actor with a saved spell ID and hit dice. It uses the ordinary monster
spell planner and resolver, then disappears after its one successful cast.

## Source behavior

Pinned DCSS `mon-cast.cc` maps earthen, crystal, divine, and frostbound tomes
to Petrify, Lehudib's Crystal Spear, Smiting, and Iceblast. Their shared
`MST_WALKING_TOME` book casts `SPELL_CONJURE_LIVING_SPELLS`. The summon case
attempts two or three actors, gives each the caster's effective spell HD,
degree-one abjuration, and a custom spell slot with frequency 200. Source
monster casting dismisses a living spell after its cast. AI refuses the
conjuration when six aligned living spells already belong to its tome.
The shared summon cap excludes the newly created actor when selecting an
older one to evict.

Iceblast is the only missing monster resolver in this family. It receives
the source `ZAP_ICEBLAST` explosion profile, with the same damage calculator
as Seracfall but normal monster spell power. The ordinary monster beam
targeting and contact rules protect allies and apply cold resistance.

## Ownership

- Each tome content file declares its living spell ID, so a modded tome can
  supply its own choice without editing a central species switch. A Lua
  summon policy reads the declaration, chooses the count, and calls the shared
  summon owner. No Go content switch is introduced.
- A Lua component on each living spell saves its specific spell ID.
- The monster spellbook policy projects that component as one ordinary
  magical slot. The existing AI then plans and resolves the cast.
- The spell execution system sets a living spell's health to zero only after
  its effect resolves. The existing death phase removes the summoned actor.
- Tome definitions and spell IDs are imported by name where used. Mods may
  add or replace a tome definition, resolver, or summon policy by path.

## Verification

Lua tests cover all four mappings, source count and cap, saved spellbook
projection, Iceblast profile, and dismissal after a successful cast. Live
Go game tests cover tome casting and continuation after save/restore. Run
focused checks, the full Lua rule suite, build, style, and diff gates before
one category commit, then fast forward and push `main`.
