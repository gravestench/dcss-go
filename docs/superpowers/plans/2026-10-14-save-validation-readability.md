# Save Validation Readability Pass

## Goal

Make restore validation readable by giving its temporary bookkeeping one
owner and separating role, monster, clock, and final invariant checks.
Preserve accepted version-8 saves, rejected malformed saves, and the
existing error messages.

## Work

1. Create a short-lived validator for one snapshot. Keep its seen IDs,
   entity lookup, equipped slots, live-monster counts, player data, and
   earliest active deadline together.
2. Move each record's item role, player and monster role, generic actor
   state, and registration checks into named methods in the same order.
3. Validate band links and final XP, equipment, and turn-clock invariants
   after all records are registered, as before.
4. Run focused save and restore tests, then full Go tests, vet, build,
   style check, and diff check. Review the diff before committing this one
   category.
