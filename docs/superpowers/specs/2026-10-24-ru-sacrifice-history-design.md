# Ru Sacrifice History and Silver Design

## Intent

Finish the source's saved count of mutation grants from accepted Ru
sacrifices and its Demonspawn silver-damage consequence. The count is a
historical fact: later changes to a mutation do not undo a sacrifice.
Lua owns the rule, and Akara saves the count on the player.

## Approaches

- **Save the count on `religion.ru` (chosen).** This follows the source's
  separate `num_sacrifice_muts` property and makes save/restore explicit.
- Recount current Ru mutations on every hit. This loses history when a
  mutation changes and cannot distinguish a Ru rank from another innate
  grant.
- Keep a counter in the Lua module. This would not survive a save or a
  new game in the same process.

## Source behavior

`god-abil.cc:ru_do_sacrifice` adds the number of mutations in the accepted
choice to a lifetime counter. Arcana adds three; an ordinary choice adds
one. Rejecting, leaving Ru, rejoining, and generating another offer do not
erase the count. A fresh game starts at zero.

`beam.cc:silver_damages_victim` includes Demonspawn innate mutation ranks
when calculating extra silver damage. In the pinned source,
`mutation.cc:player::how_mutated` subtracts the saved Ru sacrifice count
once *per mutation enum entry*. That unusual placement makes any positive
count suppress the mutation-based silver term for a Demonspawn in
practice. The ordinary minimum silver fragment still applies. The port
will implement that observable rule directly and comment the source
quirk rather than copy a large loop into the hit path. Shapechanged
players retain the independent three-quarter-damage branch.

## Ownership and validation

`schemas/religion_ru.lua` adds nonnegative `sacrifice_mutations` with a
default of zero and a schema version increase. The Ru join owner keeps an
existing count while resetting its offer clock. Offer replacement carries
it forward.
`resolution.accept` increments it only after mutation grants complete;
rejection keeps it. The religion save validator rejects negative values.

`policy/combat/monster_missile_egos/silver.lua` reads the saved count only
for Demonspawn and only in the mutation branch. A non-Demonspawn Ru
worshipper and a Demonspawn with zero Ru sacrifices retain their current
mutation calculation.

## Verification

Lua tests use production schemas, sacrifice definitions, and silver
policy. They cover single and Arcana acceptance, rejection, offer
replacement, Demonspawn silver with and without Ru history, another
species, and shapechange precedence. A Go game test verifies the count
and continuation across save/restore. Run focused suites, build the game,
check changed-file style, and commit the domain as one category.
