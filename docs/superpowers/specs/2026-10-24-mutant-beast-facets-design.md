# Mutant Beast Facets

## Intent

Every mutant beast has one catalog species but a saved tier and facet list.
The current port saves authored forms and uses Bat for flight and Weird for
invisible sight. Combat, speed, resistance, armour, and facet spells still
read the generic catalog monster, so the same actor behaves differently
depending on which subsystem examines it.

## Source rules

Pinned `mutant-beast.h` defines tier HD 3, 9, 15, 21, and 27. Source
`mon-util.cc` gives every beast a first HIT for `tier * 7 + 5` damage.
In authored facet order, Sting adds STING/REACH_STING, Ox adds
TRAMPLE/TRAMPLE, and Weird adds CONSTRICT/CRUSH, each for `tier * 5`
damage. Other facets add no attack. An unauthored beast rolls two distinct
facets once at spawn. The monster attack round consumes this projected
sequence without a separate beast combat resolver.

Sting grants poison resistance, Fire grants fire resistance, Shock grants
electricity resistance, and Ox grants cold resistance. Ox adds five base
AC. Bat doubles actor speed and supplies batty movement and flight;
Weird supplies invisible sight. Fire and Shock respectively add natural
Fire Breath and Blinkbolt spell slots at frequency 60, with Fire Breath
also marked as a breath spell. These slots are actor-specific and must
obey the ordinary monster spell decision and execution flow.

An authored tier changes rolled HP as well as combat HD. Sting's poison
applies to monster and player defenders, and its natural reach offers a
two-cell melee intent when at least one middle path is open. Fire Breath
starts a saved own-action cooldown after casting. Generic and partial DES beast
spellings roll unspecified facets once, then save the completed form.

## Ownership

The saved `MONSTER_MUTANT_BEAST` component remains the only mutable form
state. A focused Lua beast profile projects its attacks, intrinsic
resistances, AC, speed, and Bat flag from that state. Generic combat,
defense, and AI consume the projection. The population owner rolls the
natural form once and saves it; monster stats reads its HD. The spellbook
owner builds Fire and Shock slots from the same saved form after authored
spell overrides. No Go species switch or duplicate attack path is added.

## Verification

Use real mutant beast entities with saved components. Cover all five tiers,
all six facets, the authored facet order, natural distinct facets, resistance
and armour, speed and Bat behavior, live spell slots, and save/restore.
Include authored HD/HP bounds, partial DES forms, monster-target poison,
Fire Breath recovery, and Sting reach geometry in that domain check.
Check neighboring melee, spellbook, and vault-spec tests before one category
commit on `main`. The source's full monster-to-monster constriction hold is
a separate combat-state domain; this slice projects Weird's attack and
uses the existing player hold path.
