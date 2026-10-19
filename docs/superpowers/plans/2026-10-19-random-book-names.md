# Source random-book title implementation plan

**Spec:** `docs/superpowers/specs/2026-10-19-random-book-names-design.md`

1. Add named source school and book title group keys, with a focused Lua
   title policy that draws from the committed name catalog.
2. Pass selected schools, level, spell list, and optional owner facts from
   random-book generation to the seeded artefact naming entrypoint. Select
   source book appearances there as well.
3. Add Lua rules tests for level bands, school titles, optional authors,
   replacement markers, and deterministic names. Verify existing book save
   behavior through Go tests.
4. Document the modding contract and update the port inventory. Review the
   category, run focused and integrated checks, commit once, merge into
   `main`, and push the fork.
