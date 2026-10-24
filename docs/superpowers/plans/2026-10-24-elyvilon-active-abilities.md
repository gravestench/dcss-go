# Elyvilon Active Abilities Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan task by task. Checkboxes track work; commit this
> patron domain once after integration.

**Goal:** Make all four source Elyvilon powers playable, durable, and Lua-owned.

**Architecture:** Four ability files own invocation rules. Focused Lua
owners handle cleansing, healing and pacification, and Divine Vigour state.
The existing command, turn, resources, allegiance, and save boundaries
provide their generic services.

**Tech Stack:** Lua rules and `_test.lua` tests, Akara ECS, Go save/runtime,
Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-24-elyvilon-active-abilities-design.md`

## Global constraints

- Work in `/Users/dylanknuth/src/dcrawl-go` on `main`; the user requested
  one coherent commit per category and direct pushes to `origin/main`.
- The pinned source is `/Users/dylanknuth/src/crawl/crawl-ref/source` at
  `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- All game rules are Lua files under `internal/modfs/builtin`; Go only
  supplies generic runtime, storage, terminal, and save mechanisms.
- Comments explain why and how; no line exceeds 120 columns; multi-field
  table literals are expanded. Tests import production IDs and schemas.
- Do not add special-case Go dispatch or inline Lua in Go.

## Review focus

- Purification works while confused and rejects a healthy player for free.
- An aimed Heal Other action on an empty cell spends time without revealing
  an unseen monster.
- Heal Other rejects an ineligible hostile target without MP or piety cost.
- Pacification changes durable real allegiance, not just temporary charm.
- Divine Vigour changes derived maxima through later level, training, form,
  and save paths; expiry or patron loss restores the correct values.

### Task 1: Ability catalog and generic preflight

**Files:** `ids/abilities.lua`, `policy/abilities/registry.lua`,
`policy/commands/abilities.lua`, `policy/input/abilities.lua`, matching
`_test.lua` files.

**Interface:** Register four stable `ABIL_ELYVILON_*` IDs. Add a
`confusion_ok` boolean to an ability registration; only Purification opts
in. Keep selection and aim through the existing ability command.

- [x] Cover menu, rank, penance, patron, and confusion behavior.
- [x] Implement the shared preflight and four registrations.
- [x] Run the focused Lua command and input tests.

### Task 2: Purification and Heal Self

**Files:** `policy/abilities/elyvilon/purification.lua`,
`heal_self.lua`, `policy/religion/elyvilon/cleansing.lua`, resource and status
owners as needed, and matching `_test.lua` files.

**Interface:** `cleansing.needed(ctx, player)` and `.apply(ctx, player)`
use the current status owners. Heal Self uses source cap, dice, failure,
and two MP/three piety. Purification uses two MP/two piety.

- [x] Cover represented ailment cleansing and Heal Self effects.
- [x] Implement the two abilities and common cleansing operation.
- [x] Run the focused Lua rules tests.

### Task 3: Heal Other and pacification

**Files:** `policy/abilities/elyvilon/heal_other.lua`,
`policy/religion/elyvilon/pacification.lua`, a saved pacification schema,
`policy/ai/targets.lua`, save validator, and matching `_test.lua` files.

**Interface:** `pacification.reason(ctx, target)` checks source eligibility;
`.attempt(ctx, player, target, amount, power)` returns aborted, failed,
or pacified. Successful pacification stores a durable neutral side and
one-time nonlethal defeat credit. The targeter accepts visible cells
without requiring a projectile path.

- [x] Cover empty, mindless, tentacle, sleeping, and ordinary hostile
  targets plus save/restore.
- [x] Implement source power, weighted chance, healing, and allegiance.
- [x] Run focused Lua and game integration tests.

### Task 4: Divine Vigour

**Files:** `policy/abilities/elyvilon/divine_vigour.lua`,
`policy/religion/elyvilon/vigour.lua`, a player status schema,
`policy/character/formulas.lua`, religion departure and penance hooks,
  player turn and save validation owners, matching `_test.lua` files.

**Interface:** `vigour.amount(ctx, player)` reads a saved positive timer;
`.invoke`, `.tick`, `.clear`, and `.validate` own all lifecycle changes.
Max HP/MP formulas add five percent per amount before their source
percentage division; current resources scale on invocation.

- [x] Cover grant, formula, expiry, patron loss, and restore.
- [x] Implement status owner and wire live resource readers.
- [x] Run focused Lua and game integration tests.

### Task 5: Integration and review

**Files:** `docs/port-inventory.md`, `docs/modding.md`, Go terminal and game
integration tests if Lua coverage cannot prove the bridge.

- [x] Exercise all four abilities through the generic command and terminal
  routes, including one successful and one failed Heal Other targeting.
- [x] Run focused Lua, game, and terminal tests after the full patron
  slice; run `go build ./...` and `git diff --check`.
- [x] Review the complete diff for source fidelity, comments, line length,
  and schema/save consistency. Fix material findings.
- [x] Commit the whole Elyvilon active ability category and push `main`.

The broad `go test ./internal/script ./internal/game ./internal/terminal`
run was stopped after 269 seconds without a package result. Focused
Lua, game, XP regression, and terminal suites passed. Source pacified
departure behavior remains in the monster AI inventory.
