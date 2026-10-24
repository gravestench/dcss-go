# Monster corpse identity implementation

1. Add a failing Lua test for a polymorphed body, a class whose species is
   broader, and a shifter; assert corpse species and original class.
2. Extend the typed Go corpse component with `OriginalMonsterID` and update
   Lua corpse creation to receive the dead entity and resolve its true class.
3. Update generated-roster, Beogh, and vault-origin save validation and
   direct test callers for the new field and source species rule. Check both
   shapeshifter orderings, vault source provenance, and Beogh snapshots of
   polymorphed Orcs through the full actor-death path and save restore.
4. Review the focused diff, run affected Lua and Go tests plus build and
   whitespace checks, then commit this one category on `main` and push it.
