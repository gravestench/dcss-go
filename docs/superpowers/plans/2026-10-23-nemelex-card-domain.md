# Nemelex Card Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task by task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Nemelex gifts, deck actions, and every active source card
playable and saved through Lua-owned rules.

**Architecture:** A versioned player ECS component owns deck counts and
pending choices. Individually registered card definitions name Lua effect
modules. One deck owner selects and consumes cards; existing combat,
summon, magic, and religion policies apply their effects. Go carries
terminal input and renders Lua screen decisions.

**Tech Stack:** Go, Akara ECS, embedded Lua, Bubble Tea terminal client.

**Spec:** `docs/superpowers/specs/2026-10-23-nemelex-card-domain-design.md`

## Global Constraints

- Work in `/Users/dylanknuth/src/dcrawl-go` on `main`; commit each
  complete contiguous category and push to `origin/main`.
- All card and deck rules and content live in real embedded Lua files.
- Every Lua function and content file explains why and how it works.
- Lines are at most 120 characters, with 80 preferred; split struct and
  table initializers across lines unless only one field is populated.
- Seeded outcomes depend on stable IDs, never file load order.
- Committed content is authoritative; do not add a build-time importer.

## Review Focus

- Missing mod card ID in a restored stack: report the ID without losing
  saved cards. Task 1's restore test covers this.
- Full decks on a successful gift check: spend the gift and cooldown,
  while adding no cards. Task 2's Lua test covers this.
- Cancel before Stack Five's commit point: retain old stack and counts.
  Task 3's input test covers this.
- Restore during Triple Draw or Stack Five: require the pending choice
  before any other action. Task 3's game test covers this.
- Abort a targeted card after consumption: ask whether to waste it and
  never refund it after confirmed abort. Task 4's game test covers this.

---

### Task 1: Card catalog and durable deck state

**Files:** Create `internal/modfs/builtin/ids/cards.lua`,
`ids/decks.lua`, individual `content/cards/*.lua`,
`schemas/religion_nemelex_decks.lua`, and
`policy/religion/cards/state.lua`, and
`policy/religion/cards/catalog.lua`. Modify `constants/catalog.lua`,
`constants/component.lua`, and `init.lua`; Go's content registry already
accepts new category names. Test in
`internal/script/testdata/lua/tests/nemelex_catalog_state_test.lua` and
`internal/game/religion_nemelex_save_test.go`.

**Interfaces:** `state.get(ctx, player)` reads or returns an empty player
component; `state.set(ctx, player, value)` validates counts, stack IDs,
and pending phase before writing; `state.clear(ctx, player)` removes
access on renunciation. `catalog.get(categories.CARDS, id)` returns a
card with `id`, `name`, `effect_module`, and deck weights. The deck IDs
are escape, destruction, summoning, punishment, and stack.

- [x] Write catalog and state tests for all 21 active IDs, source deck
  memberships, maxima 13/26/13, save and restore, unknown saved IDs,
  and deterministic ID order.
- [x] Run focused tests; confirm failures identify missing catalog/state.
- [x] Add the schema, IDs, definitions, validation, and state owner.
- [x] Run focused tests and `go build ./...`; commit and push the category.

### Task 2: Nemelex gift economy

**Files:** Create `policy/religion/gifts/nemelex_xobeh.lua` and a
production-schema `religion_nemelex_gifts_test.lua`. Modify
`content/gods/nemelex_xobeh.lua` and `docs/modding.md`.

**Interfaces:** `nemelex.check(ctx, player, worship)` implements the
first and later gift chance. It uses `state.get/set`, chooses 4–13
independent deck slots with 3:1:1 weights, and calls `gifts.record` with
`5 + random2avg(9, 2)` even when all decks are full.
`nemelex.leave(ctx, player)` calls `state.clear`.

- [x] Test the one-star gate, first gift, later gift, 4–13 attempts,
  3:1:1 choice, capacity skips, full-deck spent gift, cooldown, and
  renunciation.
- [x] Run the new Lua test red, implement the gift rule, then run it
  green alongside current religion gift tests.
- [x] Run the focused game save test, build, and style check; commit and
  push the category.

### Task 3: Deck actions and terminal choice flow

**Files:** Create `policy/religion/cards/draw.lua`,
`policy/religion/cards/operations.lua`, Nemelex ability modules under
`policy/abilities/`, Lua input and presentation policies, and a small
generic terminal pending-choice bridge. Modify
`policy/commands/abilities.lua`, `policy/abilities/registry.lua`,
`internal/game/commands.go`, `internal/game/command_script.go`,
`internal/ecs/components.go`, and `internal/terminal/*` only where the
new choice/target values need transport. Test in
`internal/script/testdata/lua/tests/nemelex_deck_actions_test.lua`,
`internal/game/religion_nemelex_actions_test.go`, and terminal tests.

**Interfaces:** `draw.sample(ctx, deck_id)` selects a card by sorted
catalog ID and source weight. `operations.prepare(ctx, player, request)`
returns a no-time rejection, a prompt, or a timed intent. The timed
`operations.resolve(ctx, player, intent)` updates saved state and either
returns a completed effect request or a pending choice. A generic
`operations.continue(ctx, player, response)` completes persisted pending
phases. Ability definitions own rank, MP and piety costs, and source
failure calculations; generic command timing charges one normal turn.

- [ ] Test Draw, Triple Draw, Deal Four, Stack Five, stack ordering and
  deck exhaustion; assert source counts and RNG order.
- [ ] Test precommit cancellation, pending-phase save and restore,
  blocked unrelated actions, ability rank/cost/failure, and terminal
  prompts. Run new tests red.
- [ ] Implement Lua operations and the minimal generic Go transport and
  menu bridge. Keep pending card IDs only in the ECS component.
- [ ] Run focused Lua/game/terminal tests, build, and changed-file style
  checks; commit and push the category.

### Task 4: All active card effects

**Files:** Create one module per card under
`policy/religion/cards/effects/`, plus focused shared policy files only
for mechanics reused outside this deck. Register each effect through
its card definition. Add `nemelex_card_effects_test.lua` and targeted
game tests; update `docs/modding.md` and `docs/port-inventory.md`.

**Interfaces:** Each effect exports `apply(ctx, player, request)` and
returns a completed effect or a postcommit target prompt. The card
owner computes source power once and passes `power`, `dealt`, and
`punishment`. Effect modules call existing policies for summons, zaps,
status, transformations, banishment, clouds, and damage; new generic
mechanics receive their own Lua owner and saved component as needed.

- [ ] Write one production-schema scenario per active card, including
  power levels 0/1/2 and both normal and punishment power where
  relevant. Cover targeted card abort after consumption.
- [ ] Run new tests red. Implement the 21 named effect modules and any
  missing reusable mechanics needed by them.
- [ ] Run focused Lua/game/terminal tests, `go build ./...`,
  `git diff --check`, and changed-file line limits. Inspect the live
  deck screens and save/restore. Commit and push the complete effects
  category.
