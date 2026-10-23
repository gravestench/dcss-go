# Jiyva Mutation Gifts Implementation Plan

**Goal:** Complete Jiyva's source mutation gift cycle in Lua.

**Spec:** `docs/superpowers/specs/2026-10-23-jiyva-mutation-gifts-design.md`

**Constraints:** Use existing ECS mutation records, shared gift counters,
committed mutation definitions, and named RNG streams. Keep one commit for
this category and push to `origin/main`.

## Steps

1. Add a production-schema `_test.lua` fixture. Pin the piety gate,
   acquired-only deletion, four mutation levels, timeout, and refusal
   while cooldown remains. Watch the new test fail before implementation.
2. Add a focused Jiyva gift module and register it on its god definition.
   Keep selection, record updates, and conflict handling with their
   existing mutation owners.
3. Document the mutation gift contract and update the port inventory.
4. Run focused Lua and game tests, Go build, diff and style checks.
   Commit the complete category on `main` and push it.
