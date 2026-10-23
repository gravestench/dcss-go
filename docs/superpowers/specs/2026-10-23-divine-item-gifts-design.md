# Divine item gifts

## Goal

Port the complete physical gift decisions for Sif Muna, Trog, and Okawaru
through Lua god modules and real floor item entities. Preserve the source
piety gates, item classes, gift timeouts, and source acquirement preferences.

## Ownership

Each god definition names its gift module. Sif chooses books; Trog chooses
weapons; Okawaru chooses weapons, armour, or missiles. The shared gift owner
enforces penance and timeout and records successful gifts. The existing
acquirement owner chooses usable subtypes and rolls their properties.
Item generation creates a normal ECS item at the player's position. The
gift source is passed as `purpose.GOD_GIFT` and the god ID, so artefact
history and random book names retain provenance.
The item generator uses source `ISPEC_GIFT` quality, distinct from the
`ISPEC_GOOD_ITEM` quality used by scroll acquirement. Gifts keep the
source's lower unique odds and normal-brand chance on some missiles.
Trog permits artefact generation on only one in three acquisition attempts.
Gods use the source's linear skill weights for weapon families, and Trog
does not choose ranged weapons. Divine weapon subtypes keep base weights
instead of scroll acquirement's high-damage bonus. Divine armour favors
the body slot five to one against each auxiliary slot, then uses base
body-armour weights. Sif's level randbooks retain their full source size,
and themed books can contain two through eight spells.

## Source decisions

Trog and Okawaru may give equipment above 120 piety after the source
random checks. Okawaru may instead give throwing ammunition above 75 piety
after its Throwing weighted check. Trog gives weapons only. Okawaru weights
weapons and armour equally when equipment is due. Missiles use the source
usable-type weights and half an ordinary generated stack. A failed roll does
not consume a gift. Equipment and missile gifts use the distinct source
timeout formulas.

Sif considers a book at 120 piety when the source random and coin checks
succeed. Sif cannot gift a book to an innate caster or on terrain that
would destroy or permanently hide the item. Its acquirement never chooses
a manual. Fixed books are weighted by spells absent from the player's
library, while themed and level books carry committed spell lists. If no
usable book can be made, no gift is recorded. The timeout depends on the
number of spells in the resulting book.

## Verification

Use production Lua component schemas and item generation in `_test.lua`
cases for each god's gate, item class, source purpose, position, and gift
timeout. Verify no gift on destructive terrain and no second gift while
timeout remains. Run focused Lua and game tests and a Go build at the
category boundary, then commit and push the category on `main`.
