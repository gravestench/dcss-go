# Active Lua Potion Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all 17 active DCSS potion effects usable through the Lua
quaff flow.

**Architecture:** One Lua module per potion registers a small effect object
with `policy.potions`. The existing quaff intent performs one generic
preflight, resolution, and consumption transaction. Lasting effects use
saved Akara components and are consumed by focused Lua rules.

**Tech Stack:** Go 1.25, Akara ECS, embedded Lua, Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-15-active-potion-effects-design.md`

## Global Constraints

- Use the 17 active potion IDs from pinned `crawl-ref/source/potion.cc`.
- Put all gameplay rules in real files under `internal/modfs/builtin/`.
- Import IDs from `ids.items` and component names from shared constants.
- Keep handwritten Lua and Go lines at or below 120 characters, preferably
  near 80; keep multi-field tables expanded.
- Use `_test.lua` files that import production IDs and schemas.
- Leave item type identification and religious conduct to their named future
  domains, while recording the exact integration points.
- Preserve the untracked `dcrawl-save.json`.
- Make one commit for this contiguous category after integrated verification.

## Review Focus

1. A potion rejected by preflight spends no aut and loses no item.
2. A legal potion whose effect is resisted still spends aut and one item.
3. A saved timed effect resumes its gameplay rule after restore, not just
   its display.
4. A sparse mod adds a potion without an effect: startup names its ID and
   source file.
5. A one-item stack is destroyed exactly once when an effect emits several
   messages.

Each case gets a source-vector test in Task 1, including a whole-game test
for its transaction or save consequence.

---

### Task 1: Complete active potion effects and integration

**Files:**
- Modify: `internal/modfs/builtin/policy/potions.lua`,
  `policy/commands/quaff.lua`, `systems/item_quaff.lua`, and `init.lua`
- Create: one file per active ID under
  `internal/modfs/builtin/policy/potions/effects/`
- Move: current mutation potion effect from
  `policy/potions/mutation.lua` to `policy/potions/effects/mutation.lua`
- Modify: focused Lua `schemas/`, `systems/player_status.lua`,
  `policy/character/`, `policy/combat/`, `policy/magic/`, `policy/ai/`,
  `policy/presentation/`, and `policy/save/` owners when effects require
  durable state or a live consumer
- Modify: `internal/terminal/` only for a reusable choice screen if the
  experience potion requires player input
- Test: `internal/script/testdata/lua/tests/potion_registry_test.lua`,
  `potion_resources_test.lua`, `potion_buffs_test.lua`, and
  `potion_volatile_test.lua` in that directory
- Test: `internal/game/potion_transaction_test.go`,
  `potion_resources_test.go`, `potion_status_test.go`, and
  `potion_save_test.go`
- Test: `internal/terminal/potion_input_test.go`
- Document: `docs/port-inventory.md`, `docs/modding.md`, and
  `docs/ecs-architecture-roadmap.md`

**Interfaces:** `potions.register(id, effect)` accepts an object with
`can_quaff(ctx, player, forced) -> refusal?, confirmation?` and
`apply(ctx, player) -> nil|string`; `potions.get(id)` returns it;
`potions.validate()` rejects missing active definitions, duplicate IDs,
and malformed handlers. The command and ECS system use those methods.
Existing advancement, training, rage, mutation transition, stat loss, and
form owners remain authoritative; potion modules call them rather than
editing their fields through a second rule path.

- [x] **Write the failing tests.** Cover the 17-ID active roster; duplicate,
  malformed, and missing handlers; legal and rejected quaff transactions;
  a one-item stack; save continuation; and the five Review Focus conditions.
  Pin the source rolls: curing `5 + random2(7)`, both heal wounds and magic
  `10 + random2avg(28, 3)`, might/brilliance `35 + random2(40)`, attraction
  `20 + random2(40)/2`, ambrosia `3 + random2(8)`, invisibility
  `15 + random2(40)`, resistance `35 + random2(40)`, degeneration three
  `1 + random2(3)` rolls, and mutation's `2..3` removals before `1..3`
  additions and optional good addition. Test real gameplay consequences,
  a mod override, and missing-effect startup. Run the named focused tests
  and confirm RED for the missing behavior.
- [x] **Implement in one pass.** Replace the function-valued potion table
  with the registry, add all 17 focused effect modules, then connect
  preflight and consumption to the registry. Add only the durable status,
  contamination, tree-form, and pending-choice owners that the effects need.
  Each timed effect must have at least one real gameplay consumer. Do not
  add compatibility adapters or a second Go potion dispatch.
- [x] **Refine together.** Run the focused Lua, game, and terminal potion
  tests. Fix integration failures until all pass; then inspect the source
  roster and each effect file for a missing preflight or consequence.
- [x] **Verify the category once.** Run `go test ./... -timeout 30m`,
  `go vet ./...`, `go build ./...`, `sh scripts/check-go-style.sh`, and
  `git diff --check`. Verify that every spec section has implementing code
  and tests. Update the three listed docs with precise remaining religion
  and item-identification integration debt.
- [x] **Review and commit.** Obtain one read-only whole-category review.
  Fix Important/Critical findings with failing tests, stage only this
  category, and commit once as `feat: port active potion effects to Lua`.
  Fast-forward local `main` to the tested commit, leave the continuing
  branch checked out, and preserve `dcrawl-save.json`.
