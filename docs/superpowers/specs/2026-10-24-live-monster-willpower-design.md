# Live monster willpower

## Intent

Hexes must test the monster standing in the dungeon, including its worn
items and active conditions. A modder should be able to equip a ring or
armour with willpower and have existing spells respond immediately.

## Approaches

One option is to add gear cases directly to the zap saving-throw file.
That would make a general actor property belong to one spell family and
leave other willpower consumers to duplicate it. The chosen option is a
focused `policy.combat.monster_willpower` owner. Spell saving throws keep
their dice and power step-down rules, but ask that owner for the live
willpower level. This follows the existing monster resistance boundary.

## Source behavior

The pinned source's `monster::willpower` first honors invulnerable will,
then the robe of Folly's zero-will exception. Base willpower comes from
the monster kind: a negative catalog number scales with current HD,
while nonnegative values are already absolute. Hepliaklqana ancestors
use unmodified HD squared over two. Draining and Wretched reduce the
base in proportion to current HD and unmodified HD.
Draconian job monsters take intrinsic willpower from their saved colored
base, while keeping the job's own HD.

Artefact properties, body and shield armour flags and egos, and jewellery
then add or subtract forty-point willpower pips. Trog's Hand adds eighty.
Lowered Will halves the total after all bonuses, and the final value
cannot be negative. At the saving-throw boundary, a caster wearing
Guile lowers the target's effective willpower by another eighty points,
floored at zero. A dual wielder counts its active second artefact
weapon; an ordinary spare weapon contributes nothing.

## Boundaries

The owner reads ECS equipment, artefact, and status components and a
projected monster profile. The source's invulnerability sentinel remains
an early gate. A pure, targetless formula probe remains available to
tests; every live target path uses the owner. The shared spell rule also
exposes the source `check_willpower` margin: a resisted hex checks whether
it is positive, while Phantom Mirror uses its actual rolled margin for
clone duration. No Lua is embedded in Go.

## Verification

Use production item and monster definitions with live ECS items. Cover
equip/remove, intrinsic body armour, shield ego, Guile, ring, artefact,
Folly, Trog's Hand, Lowered Will, drain/Wretched, dual wielding, and the
invulnerable sentinel. Confirm a normal hex changes its saving result
when equipment changes without altering its RNG stream or draw count.
Check caster Guile separately from target Guile. Check that Phantom
Mirror uses the live roll rather than a catalog-only
approximation.
Run the affected Lua tests and Go build, then commit this category on
`main` and push it to the fork.
