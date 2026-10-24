# Okawaru Active Abilities Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Heroism, Finesse, and Duel playable and saveable as one faithful Okawaru domain.

**Architecture:** Lua ability modules own patron choices. Saved player and monster ECS components carry buffs and Duel identity. Shared skill, timing, generation, death, and travel owners consume that state without a Go patron switch.

**Tech Stack:** Lua rules, committed `.des` maps, Akara ECS, Go region grid/save kernel, Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-24-okawaru-active-abilities-design.md`

## Global Constraints

- Work in `/Users/dylanknuth/src/dcrawl-go` on `main`; commit the whole Okawaru category once and push `origin/main`.
- Keep original Arena MAP rows in four separate `.des` files. Named Lua hooks replace source script blocks; no Lua text belongs in Go.
- New tests use `_test.lua` and production schemas; Go tests cover the command, save, and terminal boundaries.
- Every new Lua function has a why/how comment. Use expanded tables, preferred 80 columns, maximum 120.
- Preserve source failure, cost, and RNG order, and source duration and attack timing behavior.

## Review Focus

- Heroism changes only effective mundane skills, not saved skill XP or magical skills (Task 1).
- Finesse and Haste combine to one speed boost; Berserk cancels Finesse (Task 2).
- Invalid Duel targets and failed generation spend neither resources nor a turn (Tasks 3–4).
- A revealed eligible illusion spends a turn and success costs without moving floors (Task 3).
- Revival/split/merge keeps the duel active, but a clone never inherits the target mark (Task 5).

---

### Task 1: Okawaru ability and status foundations

**Files:** `ids/abilities.lua`, `constants/component.lua`, `schemas/religion_okawaru_status.lua`, `policy/religion/okawaru/status.lua`, `systems/religion_okawaru_status.lua`, `policy/combat/fighter.lua`, `policy/religion/gods/okawaru.lua`, `policy/save/status.lua`, `policy/abilities/okawaru/heroism.lua`; test in `internal/script/testdata/lua/tests/religion_okawaru_status_test.lua`.

**Interfaces:** `status.active(ctx, player, kind)`, `status.invoke(ctx, player, kind)`, `status.tick(ctx, player, aut)`, `status.clear(ctx, player)`, and `status.validate(ctx, player)`. Heroism is +5 capped at 27 on skills through `SK_UNARMED_COMBAT`; invocation extends by 10 plus source average of two `random2(skill(SK_INVOCATIONS,6))`, capped at 100 turns. Heroism rank 1 costs 2 MP and generic piety base 1, with failure `(30,6,20)`.

- [ ] Add a failing Lua test for registration, rank/penance/MP gates, success and failure costs, refresh/cap/expiry, departure/penance, and mundane versus magic skill reads.
- [ ] Add the saved component, owner, tick system, Heroism ability, shared skill projection, and restore validation. Run the focused Lua test.

### Task 2: Finesse and attack timing

**Files:** `policy/abilities/okawaru/finesse.lua`, `policy/combat/delay.lua`, `policy/character/rage.lua`; extend the same Lua test and `internal/game/religion_okawaru_timing_test.go`.

**Interfaces:** Finesse rank 4 costs 5 MP, generic piety base 3, and failure `(60,4,25)`; it shares the status duration owner. `delay.player` and `delay.projectile` halve the pre-speed attack distribution with source random rounding. Haste does not give a second attack-speed multiplier. `rage.begin` clears Finesse before Berserk starts.

- [ ] Add failing Lua tests for melee, launcher, throw, Haste, Berserk, refresh and expiration, and one game command test for elapsed aut.
- [ ] Implement the ability and timing/status integration. Run the affected timing and Lua tests.

### Task 3: Duel targeting and paid illusion reveal

**Files:** `policy/abilities/okawaru/duel.lua`, `policy/world/arena/eligibility.lua`, `policy/combat/monster_threat.lua`; test in `internal/script/testdata/lua/tests/religion_okawaru_duel_test.lua`.

**Interfaces:** Duel rank 5 costs 7 MP, generic piety base 10, and failure `(80,4,20)`. Its prepare validates visible target, hostility, source firewood/conjured/tentacle/habitat/summon exclusions, and source `MTHRT_TOUGH` XP band. Invalid targets cancel freely. An eligible illusion pays success costs and time but does not travel.

- [ ] Add failing tests for every eligibility class, cancellation, failed invocation, and paid eligible illusion.
- [ ] Implement the target predicate and Duel ability, reusing the existing threat XP formula and projectile vision owner. Run focused Lua tests.

### Task 4: Four live Arena layouts and transactional entry/exit

**Files:** four `vaults/arena/okawaru_arena_*.des` files, `policy/generation/vaults/arena/*.lua`, `policy/generation/arena/level.lua`, `policy/world/arena/travel.lua`, terrain constants and mappings, `schemas/character_arena_visit.lua`, and the generic stair/region owners. Extend Duel Lua tests and add `internal/game/religion_okawaru_arena_test.go` plus text snapshots.

**Interfaces:** `level.generate(ctx, input)` selects a mod-layered source map and creates the full grid plus A/B/exit positions. `travel.enter(ctx, player, target)` stages that region, saves the exact origin, alerts and moves the target/player, and commits resource payment once. `travel.leave(ctx, player)` returns the player to that origin and any living duel target nearby; it retires the temporary Arena floor. The source spectator, no-item, no-teleport, no-monster, and victory marker rules are live Lua behavior.

- [ ] Add failing layout snapshots for all four maps and tests for generation failure rollback, entry source/target positions, blocked return, live target return, and save during travel.
- [ ] Port the four source MAPs and named hook effects, add Arena feature IDs, generation and travel policies, then run the focused Lua/game tests.

### Task 5: Victory and target lineage

**Files:** `schemas/religion_okawaru_duel_target.lua`, `policy/world/arena/victory.lua`, Bennu revival, slime split/merge, ordinary clone owners, `policy/save/generated_levels.lua` and `policy/save/status.lua`; extend Lua/game/terminal tests and `docs/port-inventory.md`.

**Interfaces:** `victory.on_death(ctx, target, ...)` opens the authored exit only when no live current target or pending Bennu revival remains; separate mark transfers preserve identity through revival and slime lineage, while clones clear it. Arena exit ages the source victory timer and also works before victory. Renunciation forces return; penance only clears buffs. Save validation binds visit, target marks, branch, map, and return site.

- [ ] Add failing tests for final death, Bennu revival, split/merge, clone exclusion, renunciation, forced return, saved malformations, and terminal Arena/ability menu rendering.
- [ ] Implement lineage and victory hooks, automatic/voluntary return, restore validation, inventory update, and text snapshots. Run affected Lua/game/terminal groups and `go build ./...`.
- [ ] Review the full category, run `git diff --check`, check Lua line lengths and Go formatting, then commit once and push `origin/main`.
