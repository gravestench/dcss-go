# Monster Polymorph Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route all monster polymorph effects through source behavior for shifters, ugly things, and merged slimes.

**Architecture:** A Lua monster route owns kind-specific decisions; the
existing slime lifecycle owns forced division. Spell and combat callers
use the shared route while random shifter ticks keep their separate
destination chooser.

**Tech Stack:** Embedded Lua rules, Go host, Akara ECS, production Lua test VM.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-polymorph-routing-design.md`

## Global Constraints

- Monster gameplay stays in Lua; no inline Lua in Go.
- One live slime body is one ECS actor; preserve save and split lineage.
- Named RNG streams; file load order never changes behavior.
- Work on `main`; one category commit and push after verification.
- Comment why and how, with lines no longer than 120 characters.

## Review Focus

- A borrowed shifter body reverts to its actual permanent variant.
- Ugly mutations precede shifter reversion and direct effects force traits;
  illegal fixed destinations do not mutate an actor or reroll HP.
- A merged slime with room divides before each body changes form.
- Slime routes always use the same-power candidate picker, and a forced
  split consumes the source coin-flip draw without using it as a veto.
- A blocked merged slime still changes its one surviving body.
- Forced division does not spend a natural action or obey the split coin flip.
- Generated split bodies save and restore after transformation.

---

### Task 1: Shared polymorph routing and forced slime division

**Files:**
- Create: `internal/script/testdata/lua/tests/monster_polymorph_routing_test.lua`
- Modify: `internal/modfs/builtin/policy/magic/effects/statuses/polymorph.lua`
- Modify: `internal/modfs/builtin/policy/monsters/slime_lifecycle.lua`
- Modify: `internal/modfs/builtin/policy/monsters/ugly_thing.lua`
- Modify: `internal/modfs/builtin/policy/monsters/malmutation.lua`
- Modify: `internal/script/testdata/lua/tests/ugly_thing_test.lua`
- Read: `internal/modfs/builtin/policy/combat/monster_hexes/polymorph.lua`
  (already delegates through `polymorph.shapeshift`)
- Modify: `internal/modfs/builtin/policy/save/monsters.lua`
- Modify: `internal/game/monster_shapeshifter_test.go`
- Create: `internal/modfs/builtin/constants/polymorph_power.lua`
- Create: `docs/snapshots/monster-polymorph-routing.md`

**Interfaces:**
- Produces: `polymorph.monster(ctx, target, source, stream, power) -> boolean`.
- Produces: `slime_lifecycle.force_split(ctx, entity) -> child | nil`.
- Existing caller's `polymorph.shapeshift` delegates to this route.

- [x] Write production-schema Lua tests for shifter reversion, merged slime
  division, blocked division, and split origin.
- [x] Add a Go restore test for a durable shifter currently wearing its original kind.
- [x] Run the focused `TestLuaRules/monster_polymorph_routing_test.lua` test;
  confirm expected failure.
- [x] Add a forced placement mode to the slime owner, returning its child entity and reusing split state transfer.
- [x] Add the shared route and use it in the player spell, monster hex, and chaos path.
- [x] Admit equal current/original kinds in save validation only for a durable shifter.
- [x] Run focused Lua and Go integration tests; record a short text floor snapshot.
- [x] Run the affected Lua and Go integration tests, `go build ./...`,
  format, line length, and diff checks.
- [x] Commit the whole category and push `main`.
