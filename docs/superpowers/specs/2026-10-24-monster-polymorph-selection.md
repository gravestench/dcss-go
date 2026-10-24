# Monster polymorph selection

## Intent

Complete the source monster polymorph selection category. A monster owns a
persisted set of up to three same-power destinations. Creation rolls the set
once, a successful body change replaces it, and later same-power requests
choose uniformly from the stored set. Selection order is independent of Lua
file discovery order.

## Runtime

- `monster.polymorph_set` is a Lua-defined ECS component containing a list of
  catalog monster IDs. The ordinary monster factory creates it after placement.
- The selection policy chooses unique, base, eligible species with compatible
  habitat. It weights HD and demon-tier distance exactly as `init_poly_set`
  does. A dedicated persisted RNG stream avoids perturbing unrelated actions.
- The spell chooses a stored form uniformly, validates the current cell, and
  transforms or fails. A successful transformation regenerates the set for
  the new body. A failed request does not change the component.
- Relative-power and shapeshifter requests draw uniformly from the destination
  cell's species pool. They test species, demon tier, and power in source order.
  Shifters may take only natural forms. Their durable shifter component remains
  the owner of permanent variant identity.
- Save validation checks that any persisted set has at most three distinct
  legal destinations. Older saves without the optional component remain
  loadable; their first same-power request initializes it once.

## Verification

Lua tests use production catalogs and schemas to check persistent choice,
regeneration, exclusions, and relative picker behavior. Go integration verifies
the new component survives save and restore. Focused rule and game suites run
after the category is complete.
