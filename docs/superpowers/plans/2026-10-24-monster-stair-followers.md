# Monster Stair Followers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this connected category.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transfer source-eligible monsters with the player on ordinary
up and down stairs without losing ECS identity or saved state.

**Architecture:** A Lua follower owner tags candidates at accepted action
start. The ordinary monster decision skips marked actors; the existing
Lua stair system places them after player travel. Go passes only a generic
stair-action flag. The mark is transient but schema-backed in Akara.

**Tech Stack:** Lua rules, Akara ECS, Go grid/save host, Go test runner.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-stair-followers-design.md`

## Global Constraints

- Work directly on user-authorized Go `main`; commit one contiguous
  category and push it to `origin/main`.
- Keep gameplay rules and all Lua source in embedded `.lua` files.
- Use named IDs and detailed why/how comments; Lua and Go lines <=120.
- Run relevant tests after the category, not after each minor edit.

## Review Focus

- A failed or refused stair command must not leave follower marks.
- A tagged monster must not spend an intervening attack or movement.
- The pair must not separate when one twin lacks follower eligibility.
- A summon or stationary monster must remain on the source floor.
- A full destination must retain the actor and allow the player to travel.

### Task 1: Tag accepted stair followers

**Files:** `policy/world/stair_followers.lua`,
`schemas/world_stair_follower.lua`, `constants/component.lua`,
`policy/command_action_start.lua`, `internal/game/commands.go`, and a
focused Lua `_test.lua`.

**Interface:** `followers.tag(ctx, player, origin)` marks eligible actors
with `world.stair_follower`. The Go action-start input adds
`stair_travel = true` for an accepted ordinary stair intent. The Lua
policy checks the actual linked stair and source branch before tagging.

- [x] Write focused failing tests for ally and hostile eligibility,
  radius five versus adjacent-hostile radius one, cap 18, and exclusions.
- [x] Run focused tests and confirm missing tag behavior causes failure.
- [x] Implement source-order BFS selection and twin pair adjustment.
- [x] Connect the accepted command action to tagging; run focused tests.

### Task 2: Transfer and decision suppression

**Files:** `policy/world/stair_followers.lua`,
`systems/monster_decision.lua`, `systems/world_stairs.lua`, matching Lua
tests, and `internal/game/monster_stair_followers_test.go`.

**Interface:** `followers.transfer(ctx, player, origin, level_id, x, y)`
moves marked actors to connected free cells near the player and clears
marks. `followers.clear(ctx)` clears marks if travel aborts.

- [x] Write failing Lua tests that a marked monster skips its decision,
  twins transfer together, and a blocked landing leaves a follower safe.
- [x] Write failing Go tests for descent, ascent, and identity across
  restore. The crowded destination is covered in Lua.
- [x] Implement transfer in `world.stairs` after player movement, with
  clear calls on every early return.
- [x] Run focused Lua and Go tests to green.

### Task 3: Boundary verification and integration

**Files:** `docs/port-inventory.md`, `docs/modding.md`, this plan.

- [x] Document the follower owner, stair action order, and portal boundary.
- [x] Run focused suites, `go build ./...`, `gofmt -d` on changed Go,
  `sh scripts/check-go-style.sh`, and `git diff --check`.
- [x] Review category diff and source behavior; commit once and push.

The repository-wide Go style command still reports existing warnings in
unrelated files; neither changed Go file appears in that output. The
broader game test run also exposed an existing Temple fixture call that
omits the required plan input. Its focused reproduction fails without
executing this stair policy and belongs to a separate repair category.
