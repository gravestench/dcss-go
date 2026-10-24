# Live monster flight and sight

## Intent

An equipped ring, armour ego, or artefact should change what a monster can
reach and see on its next decision. These properties belong to the live
actor, not the static monster catalog. A modder can add gear without adding
a new branch to every AI, habitat, trap, and gaze rule.

## Approaches

Copying gear checks into every consumer would make future items difficult
to extend and would let targeting disagree with movement. A single large
monster-capabilities switch would combine unrelated rules. The chosen
approach extends the existing actor flight owner and gives monster sight
its own small owner. Both read the same active equipment snapshot. A
shared artefact scan in the equipment owner enforces item-use, slot class,
and dual-wield rules for resistance, willpower, flight, and sight.

## Source behavior

Monster flight is true for an inherently flying class or base, a positive
active artefact Flight property, a worn Flying body armour ego, a worn ring
of flight, or a current flight enchantment. A black-based draconian job
inherits its base color's flight. A Pan lord uses its saved generated trait.
The saved mutant beast Bat facet also grants inherent flight. Zombies,
skeletons, simulacra, spectral things, and bound souls inherit flight from
their saved corpse base, including legacy small and large catalog variants.

Monster sight of invisible creatures comes from the class or colored
draconian base, a saved player illusion's sight, a positive active artefact
See Invisible property, a worn ring of see invisible, or a worn armour ego.
The saved mutant beast Weird facet also grants innate sight.

An artefact property contributes only when its item is in a valid active
slot on an item-using monster. A second weapon counts for a dual wielder;
a normal spare weapon does not. An ordinary jewellery or ego effect is
read from the worn item rather than from a catalog promise.

## Boundaries

`policy.combat.equipment` owns active monster artefact-property scans.
`policy.combat.flight.active` remains the actor-wide flight decision.
`policy.combat.monster_senses.see_invisible` owns monster sight.
`policy.potions.invisibility.visible_to` and monster gaze planning call the
new sight owner; movement, habitat, webs, and bog already call flight.
All gameplay rules remain in Lua files under the embedded mod root.

## Verification

Use real ECS gear and catalog items. Equip and remove each gear source;
check the next flight and invisibility decision without refreshing the
actor. Check the black draconian and derived-undead bases, saved mutant
beast facets, player illusion sight, item-use
limit, and dual-wield artefact behavior. Test a habitat or web consequence
and a real player invisibility or gaze decision. Run affected Lua tests and
Go build, review the category once, then commit and push it on `main`.
