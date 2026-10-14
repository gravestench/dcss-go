# Lua character catalog implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native implementation. This plan is one
> contiguous content and policy category; commit only after integrated review.

**Goal:** Make all pinned species/job definitions and character choice policy
Lua-owned while preserving the current playable starts and saves.

**Architecture:** Committed source-traced Lua files register typed definitions.
A per-ruleset Lua VM validates them and projects one read-only Go catalog for
existing consumers. One Lua choice policy drives pregame restrictions and
playable-start status. Existing Go start mechanics remain until dependent
item, spell, and religion domains can migrate together.

**Tech Stack:** Go 1.25, GopherLua v1.1.2, Akara v0.1.4, embedded Lua tree.

**Spec:** `docs/superpowers/specs/2026-10-14-lua-character-catalog-design.md`.

## Global constraints

- All Lua source, including tests, is in actual `.lua` files.
- Generate and commit all 43 species and 31 job files together.
- Runtime never reads source JSON as a fallback for Lua definitions.
- Existing supported starts and named RNG sequence remain source-faithful.
- One category commit after full verification and review.

## Review focus

- A duplicate ID in an overlay-only file fails rather than silently replacing.
- Empty arrays, aptitude maps, mutations, and nested skill lists preserve
  their source JSON types through Lua registration and Go projection.
- Character menu and game constructor use the same effective overlay.
- Unsupported starts are visible but cannot enter an invalid game session.
- Save restore with changed definitions uses the existing explicit mismatch
  rule and validates the projected character state.

---

### Task 1: Deterministic generated Lua character definitions

**Files:** `scripts/generate_lua_character.py`, committed files under
`internal/modfs/builtin/content/species/` and `content/jobs/`, generator test.

- [x] Convert every source JSON row to one `register.species{...}` or
  `register.job{...}` Lua file, with source revision and path comments.
- [x] Compare generated values with the pinned JSON artifacts in a developer
  test; the generator never runs during normal build or game startup.

### Task 2: Registry and typed projection

**Files:** `internal/script/definitions.go`, `internal/content/catalog.go`,
`internal/game/scenario.go`, `internal/game/save.go`, tests.

- [x] Parse Lua tables recursively with exact scalar, array, and map rules;
  reject cycles, mixed keys, nonfinite numbers, duplicate IDs, and unknown
  fields. Include the Lua path in registration errors.
- [x] Add `register.species` and `register.job`; freeze them after bootstrap.
- [x] Add `Catalog.WithCharacterDefinitions` that validates and swaps both
  maps. Construct game and restore with the effective projection.
- [x] Prove a same-path Lua override changes a game catalog value without
  changing Go code and an added definition is available to the session.

### Task 3: Lua choice policy and pregame projection

**Files:** `internal/modfs/builtin/policy/character_choice.lua`,
`internal/script/choice.go`, `internal/terminal/app.go`, `pregame.go`,
`pregame_render.go`, `internal/character/choice.go`, tests.

- [x] Register one Lua policy for bans, recommendations, and supported-start
  status. Apply the pinned source special cases and default four playable
  Fighter species.
- [x] Have pregame own a ruleset VM and use its catalog projection and
  policy. Show all selectable definitions while clearly marking unsupported
  starts; do not let an unavailable pair start a game.
- [x] Remove the Go choice-policy path from live pregame behavior. Preserve
  exact current start outcomes and RNG continuation.

### Task 4: Category verification and integration

- [x] Update `docs/modding.md`, the roadmap, and port inventory with the
  real supported-start boundary.
- [x] Run `go test ./...`, `go vet ./...`, `go build ./...`, style and diff
  checks once after the category is integrated.
- [x] Request whole-branch code review, resolve important findings, make
  one category commit, and merge into local Go `main`.
