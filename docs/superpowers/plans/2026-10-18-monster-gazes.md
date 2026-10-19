# Monster gaze implementation plan

**Spec:** `docs/superpowers/specs/2026-10-18-monster-gazes-design.md`

1. Add failing Lua tests that import all four gaze effects and exercise
   sight-only planning, player/monster outcomes, and saved status owners.
2. Add a small shared direct-gaze policy and four focused effect modules.
   Reuse the existing confusion, paralysis, antimagic, and enfeeble owners.
3. Add actor-owned player weakness state, aut aging, and the raw melee
   damage modifier. Keep the source formula and RNG stream explicit.
4. Add one real game overlay test for a forced gaze, ECS state, save/restore,
   and deterministic continuation. Document the `ctx` pattern for direct
   status effects in the modding guide.
5. Run focused Lua and game tests, compile, vet, style, and staged diff
   checks. Request read-only review, fix material findings, commit the
   complete family once, and fast-forward local Go `main`.

Every new Lua function gets a nearby why/how comment. Keep tables readable,
lines at or below 120 characters, and shared IDs imported at use sites.
