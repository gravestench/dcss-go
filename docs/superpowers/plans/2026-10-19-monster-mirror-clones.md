# Monster mirror clones implementation plan

**Goal:** Phantom Mirror and fake Mara summoning create durable, independent
monster copies through Lua.

**Architecture:** The two spell files delegate to one mirror owner. A saved
marker prevents recursion; shared inventory copying creates distinct item
entities. The existing summon owner handles lifetime and allegiance.

**Spec:** `docs/superpowers/specs/2026-10-19-monster-mirror-clones-design.md`

## Work

1. Add Lua tests that exercise both source spellbooks through their effect
   modules, including ally filters and Mara's two-copy cap.
2. Add a saved mirror marker and the owner that clones HP, speed, effective
   HD, bodily status, and independent equipment adjacent to the source.
3. Add the two monster spell modules and prevent mirror copies from using
   mirror slots. Re-evaluate eligible sources during resolution after the
   self-targeted spell intent crosses the scheduler boundary.
4. Extract gear copying from chaos cloning into one focused Lua policy and
   use it for both kinds of clone.
5. Validate mirrored summon state on restore. Add a live cast/save/restore
   test and update the port inventory and slice documentation.
6. Check the source decisions and run focused tests, the Lua rule suite,
   `go build ./...`, style, and diff checks. Commit once, fast forward
   local `main`, push `origin/main`, and compare local and remote heads.
