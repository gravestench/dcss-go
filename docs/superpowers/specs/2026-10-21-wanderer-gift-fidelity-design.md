# Wanderer Gift Fidelity

## Intent

Finish the Wanderer starting-gift category against pinned
`crawl-ref/source/ng-wanderer.cc`. A legal Wanderer should start with
source-shaped strong, decent, and tactical gifts without redrawing a
per-run item set or making the result depend on Lua file load order.
The game already creates all selectable species and jobs, saves item-set
choices, and assigns Wanderer gear through Lua. This slice replaces the
remaining gift-selection shortcuts in that path.

## Ownership and source rules

`policy.character.wanderer` owns the three role draws, stat/skill allocation,
and the ordered strong/decent/extra gift sequence. Its gift and spell
modules own their respective decisions. All Wanderer-only draws use a
named persisted `wanderer` RNG stream, reflecting the source's isolated
subgenerator. The earlier character-creation item-set initializer remains
the sole owner of one representative per hex-wand, beam-wand, blast-wand,
and concealment-scroll set. Gifts read those saved representatives via
`policy.item_generation.item_sets.choice` without drawing substitutes.

The strong evoker branch draws one of six source wand slots, using the
saved representative in the three set slots. The decent consumable branch
uses the saved concealment scroll. Aux armour reservoir selection asks for
a helmet when the source hat candidate wins, leaving species-specific
helmet-to-hat substitution to the ordinary starting-gear owner. An
unwearable strong Armour gift falls back to acid dragon armour through
the same item-grant path. Strong wand charges use the source's `16, 17, 17`
draw bounds. A decent Fighting gift upgrades the first weapon that starting
gear can actually equip; a no-grasping character gets the source fallback
consumable. No new item IDs or static content copies are introduced.

Spell candidates are ordered by their numeric source ID. Strong magic
gifts keep source reservoir selection. A minor magic gift uses its selected
school, or selects a school for Spellcasting, then forms a two-spell
pair whose levels sum to four. The first spell is chosen uniformly among
eligible player-book spells that have a distinct eligible complement;
the second is chosen uniformly from its complements. This admits both
1+3 and 2+2 without giving either pattern an artificial first try.
Species usability and existing known-spell restrictions are read through
the production spell and trait policies. Player-book membership comes from
the effective layered book catalog so a modded book can add a spell without
editing a frozen source list.

The starting-gear owner still fills empty body and weapon slots and the
spell-record owner still persists library and memorized grants. Tests
exercise the production Lua policies and schemas. A seeded integrated
Wanderer start must survive Go save/restore with the same item-set choices,
gear, and spells. This category changes no Go gameplay branch or importer.

## Limits

The Go RNG does not reproduce C++'s byte-for-byte subgenerator state.
This slice preserves independent stream ownership and source decision
order, which are the observable replay contract for a given Go seed.
Other character-generation differences are tracked in the port inventory
and do not justify a second Wanderer gift path.
