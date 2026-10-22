# Jiyva Heavy-Hit Slimes Implementation Plan

**Goal:** Implement Jiyva's complete five-star heavy-hit ejection category.

**Spec:** `docs/superpowers/specs/2026-10-21-jiyva-heavy-hit-slimes-design.md`

**Integration unit:** One category commit to `main`, pushed to the fork.

## Work

- [x] Trace the source damage gate, thresholds, species, summon duration,
      target, and message.
- [x] Add a failing `_test.lua` case using real player-health and summon
      policies with production schemas.
- [x] Pass attacker to sorted after-HP callbacks and register the Jiyva
      reaction in source order.
- [x] Give the common summon owner named-stream and silent-failure options;
      use saved ECS summon and foe-target components.
- [x] Expand Lua tests over thresholds, rank, penance, departure, sources,
      lethal damage, species, duration, and allegiance.
- [x] Validate god-origin Jiyva summons across save and restore, and keep
      Curl's beam response separate from direct smiting.
- [x] Explain the extension point and saved state in the modding guide.
- [x] Run related Lua tests, all-package build, changed-file readability
      checks, and staged diff checks.
- [x] Commit and push the category.
