# Random artefact name catalog implementation plan

**Spec:** `docs/superpowers/specs/2026-10-19-randart-name-catalog-design.md`

1. Convert the five source name database files into individual committed
   Lua definitions. Preserve every key, phrase, and weight in source order;
   remove the one-time converter after verification.
2. Add a focused Lua catalog policy that validates all weighted entries and
   references, draws with a caller-supplied cosmetic RNG, and expands
   database plus player/world markers with bounded recursion.
3. Update random equipment naming to use source class odds and appearance
   groups. Keep the item-local seed and saved names; leave book title
   selection to its own source-aware slice.
4. Add Lua tests for weighting, expansion, seeded output, and mods; add a
   Go save test if existing artefact discovery coverage does not suffice.
5. Update modding and port inventory docs, run the relevant integrated
   checks, review the category, commit once, fast-forward `main`, and push.
