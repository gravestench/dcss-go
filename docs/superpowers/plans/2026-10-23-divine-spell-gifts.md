# Divine spell gifts

## Scope

Implement the complete spell-knowledge gift path for Kikubaaqudgha and
Vehumet. Sif Muna gives a generated book item, so its item acquirement path
belongs with equipment and book gifts. Kiku's two sets are permanent library
knowledge. Vehumet's thirteen offers are temporary access to memorisation;
their history and current offers survive saves, and leaving clears access.

## Owners

- `religion.worship` stores per-god current and lifetime gift counts, plus
  the existing cooldown. Its transition owner resets current gifts on leave.
- `religion.vehumet` stores old and currently offered spell IDs and the
  absolute aut at which another offer becomes eligible.
- `policy/religion/gifts.lua` resolves the current god's optional gift module
  after each accepted piety candidate. Definitions choose modules, so a mod
  adds a gift without a shared switch.
- `policy/character/spell_records.lua` keeps one ECS record per owner and
  spell. Vehumet's temporary offer tag shares that record with permanent
  library knowledge and memorisation slots.
- The spell menu and learning owner accept current Vehumet offers. Finishing
  memorisation consumes only the accepted offer; leaving removes all offers.

## Source rules

Kiku grants Necrotise plus three distinct early spells at one star, then five
distinct later spells at three stars. Already known spells still count toward
the two gift events. Vehumet checks at each piety candidate, chooses source
book spells within the thirteen level windows, prefers never-offered spells,
and weights elemental schools by trained skill. The last offer contains three
spells. The source cooldown and gift timeout are saved and use the religion
RNG stream.

## Verification

Write `_test.lua` cases using production schemas for both Kiku sets,
Vehumet candidate filtering, offer replacement and acceptance, piety point
ordering, save validation, and renunciation. Run focused Lua rules, religion
game integration, and a Go build at the category boundary. Commit and push
one contiguous spell-gift category on `main`.
