# Monster polymorph selection implementation

1. Add a production component schema and named RNG stream for a monster's
   three-form set. Add a focused Lua rule test that fails with the current
   per-request shortlist.
2. Move eligibility, set generation, and random relative picker to a
   `policy.monsters.polymorph_selection` Lua module. Keep body mutation and
   spell contact in the existing polymorph policy.
3. Initialize at factory placement and regenerate after body changes. Handle
   old saves lazily, and validate stored forms during restore.
4. Run focused Lua and Go integration tests, check line lengths and diff, then
   commit this contiguous category to `main` and push `origin`.
