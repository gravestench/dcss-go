# Ru Active Powers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Ru's three source active powers playable through the Lua
ability registry, with saved exhaustion and faithful effects.

**Architecture:** Each command has one Lua ability module. A shared saved
character exhaustion component owns eligibility and elapsed-aut decay.
Effects use existing movement, damage, and status owners; missing monster
statuses get focused Lua schemas and policies.

**Tech Stack:** Go engine, Akara ECS, embedded Lua mod, Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-24-ru-active-powers-design.md`

## Global Constraints

- Work on Go `main`; preserve the paused C++ refactor.
- Production game rules and component schemas belong in embedded `.lua` files.
- No inline Lua in Go or test strings; tests belong in `_test.lua` files.
- Comment every Lua function with why and how; prefer 80-character lines,
  never exceed 120; split multi-field tables across lines.
- Complete all three powers in one contiguous category commit, then push.

## Review Focus

- A stale prepared intent after changing gods must not execute; the ability
  registry's live resolver and the integrated test cover this.
- A canceled leap or empty-Apocalypse confirmation must not spend MP, aut,
  exhaustion, or RNG; free-preparation tests cover this.
- A Leap constriction failure must spend the action and its cost without
  moving or damaging monsters; the Leap test covers this.
- A monster dying to Apocalypse must not retain a status component or evade
  kill credit; the Apocalypse test covers this.
- Save/restore midway through exhaustion and monster effects must continue
  with the same timers; the game integration test covers this.

---

### Task 1: Shared exhaustion and ability IDs

**Files:**

- Create: `internal/modfs/builtin/schemas/character_exhaustion.lua`
- Create: `internal/modfs/builtin/policy/character/exhaustion.lua`
- Create: `internal/modfs/builtin/systems/character_exhaustion.lua`
- Modify: `internal/modfs/builtin/constants/component.lua`
- Modify: `internal/modfs/builtin/ids/abilities.lua`
- Modify: `internal/modfs/builtin/policy/character/rage.lua`
- Modify: `internal/modfs/builtin/policy/save/status.lua`
- Test: `internal/script/testdata/lua/tests/religion_ru_exhaustion_test.lua`

**Interfaces:** `exhaustion.active(ctx, player)`,
`exhaustion.apply(ctx, player, turns)`,
`exhaustion.tick(ctx, player, elapsed_aut)`.

- [ ] Write the Lua test for an exact timer, elapsed-aut aging, rank-independent
  saved state, and both Ru-to-Berserk and Berserk-to-Ru restrictions.
- [ ] Run the test and confirm it fails for the missing status owner.
- [ ] Add the schema, policy, tick system, ability IDs, save validation, and
  Berserk shared-exhaustion gate. Preserve existing Rage save semantics.
- [ ] Rerun the focused test and confirm it passes.

### Task 2: Draw Out Power

**Files:**

- Create: `internal/modfs/builtin/policy/abilities/ru/draw_out_power.lua`
- Modify: relevant existing net/web, constriction, confusion, Slow, and
  Petrifying owners only where they lack a named release method.
- Test: `internal/script/testdata/lua/tests/religion_ru_draw_out_power_test.lua`

**Interfaces:** `draw.available(ctx, player)`,
`draw.prepare(ctx, player, input)`, `draw.resolve(ctx, player)`.

- [ ] Write the Lua test for ranks, full-resource/ailment gate, use while
  confused, release of each ailment, source HP/MP rolls, power-30 max-HP
  drain, and 12–16 turn exhaustion.
- [ ] Run it and confirm failure before implementation.
- [ ] Register the ability with the production registry and implement its
  source order using named status owners and the religion RNG stream.
- [ ] Rerun the focused test and confirm it passes.

### Task 3: Power Leap

**Files:**

- Create: `internal/modfs/builtin/policy/abilities/ru/power_leap.lua`
- Test: `internal/script/testdata/lua/tests/religion_ru_power_leap_test.lua`

**Interfaces:** `leap.available(ctx, player)`,
`leap.prepare(ctx, player, input)`,
`leap.resolve(ctx, player, intent, elapsed_aut)`.

- [ ] Write the Lua test for free cancellation and target rejection, exact
  range/visibility, fear/mesmerism, paid failed escape, successful landing,
  barbs, adjacent foe filtering, source damage, five MP, and 18–25 turns of
  exhaustion.
- [ ] Run it and confirm failure before implementation.
- [ ] Register the ability; use existing target, movement, monster-health,
  and barbs owners without a Go content-ID branch.
- [ ] Rerun the focused test and confirm it passes.

### Task 4: Apocalypse

**Files:**

- Create: `internal/modfs/builtin/policy/abilities/ru/apocalypse.lua`
- Create or extend only the monster status schemas and policies required for
  antimagic, paralysis, and Slow.
- Test: `internal/script/testdata/lua/tests/religion_ru_apocalypse_test.lua`

**Interfaces:** `apocalypse.available(ctx, player)`,
`apocalypse.prepare(ctx, player, input)`,
`apocalypse.resolve(ctx, player)`.

- [ ] Write the Lua test for free no-target confirmation, LOS filtering,
  each random effect and damage-only branch, kill credit, eight MP,
  power-100 drain, and 30–49 turn exhaustion.
- [ ] Run it and confirm failure before implementation.
- [ ] Register and implement the area effect with stable target order and
  the source's per-target RNG sequence; save all continuing status effects.
- [ ] Rerun the focused test and confirm it passes.

### Task 5: Real command, save, and terminal integration

**Files:**

- Modify: `docs/modding.md`
- Modify: `docs/port-inventory.md`
- Test: focused `internal/game` and `internal/terminal` Go integration tests
  plus a production `_test.lua` save-continuation test.

**Interfaces:** The existing ability menu and command bridge discover all
three registered powers without Go dispatch changes.

- [ ] Exercise rank acquisition, menu and target prompts, command spending,
  save/restore of exhaustion and monster effects, and sparse-mod override.
- [ ] Update the modding guide and port inventory with behavior and remaining
  Ru passive work.
- [ ] Run focused Lua and Go integration tests, build `cmd/crawl` to a temp
  path, run `git diff --check` and `scripts/check-go-style.sh`, and distinguish
  pre-existing failures from new ones.
- [ ] Review the whole category, commit it once, and push Go `main`.
