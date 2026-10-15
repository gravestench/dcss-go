# All Character Starts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Start every legal selectable species/job pair with source-derived
initial state entirely defined by the embedded Lua rules.

**Architecture:** Go creates and positions the player entity, then invokes
one Lua `character.start` policy. Focused Lua modules calculate stats, skills,
gear, spells, religion, and species state from checked-in catalogs. The
Fighter-only gate and separate Go starting-gear invocation are removed in
the same pass.

**Tech Stack:** Go, Akara ECS, gopher-lua, embedded Lua modules and schemas.

**Spec:** `docs/superpowers/specs/2026-10-15-all-character-starts-design.md`

## Global Constraints

- All source-specific behavior lives in real Lua files under the embedded mod directory.
- Every normal start uses committed content; importers run only for deliberate refreshes.
- No Go species/job/item/spell switches, compatibility path, or fallback start.
- Keep source-derived roll order and use named RNG streams.
- One contiguous category commit after the integrated gate.
- Keep handwritten lines at or below 120 characters, preferably 80; split populated struct fields across lines.

## Review Focus

- A `WCHOICE_NONE` job must reach name confirmation without a blank weapon menu.
- A fixed-weapon job with `SK_WEAPON` must train the fixed weapon's skill.
- A restricted species must not receive unusable equipped armour or weapons.
- A god-linked or innate-caster start must retain its starting state after save/restore.
- An illegal pair or invalid selected weapon must fail without leaving a partial live game.

### Task 1: Source matrix and failing tests

**Files:** `internal/game/all_character_starts_test.go`,
`internal/terminal/all_character_starts_test.go`, source-traced fixture data
where exact expected values are required.

- [x] Enumerate legal selectable pairs through the effective Lua choice policy.
- [x] Add a matrix test for one Lua start-profile evaluation per legal pair.
- [x] Add full game and save/restore tests for Fighter, no-choice caster,
  fixed-weapon, restricted-gear, god-linked, Djinni, and Wanderer cases.
- [x] Add terminal tests for weapon-choice and no-choice flows.
- [x] Observe the tests fail on the current Fighter-only implementation.

### Task 2: Choice and weapon flow

**Files:** `policy/character_choice.lua`, `policy/character/start.lua`,
`policy/character/weapon_options.lua`, `internal/terminal/pregame.go`.

- [x] Make the Lua choice policy's `playable` result match source legal pairs;
  remove the Fighter-only list.
- [x] Let the Lua start-support projection accept all legal selectable
  definitions without a second ID whitelist.
- [x] Keep weapon options source-derived for `WCHOICE_PLAIN` and
  `WCHOICE_GOOD`; make `WCHOICE_NONE` skip the weapon menu.
- [x] Validate a chosen weapon against the Lua option set at game start.

### Task 3: Whole Lua starting transaction

**Files:** `policy/character/start.lua`, focused new modules under
`policy/character/start/`, `policy/character/starting_gear.lua`,
`internal/game/scenario.go`, new Lua schemas as needed.

- [x] Move source-ordered item grants and chosen-weapon creation into the
  single `character.start` call; remove the separate Go gear call.
- [x] Resolve `SK_WEAPON` from the selected or fixed starting weapon; fold
  duplicate grants and reassess forbidden skills by species rules.
- [x] Apply source stat floor, special job adjustments, species gear
  substitutions, and initial HP/MP after finalizing skills and traits.
- [x] Store initial spells, religion, and innate state in Lua components that
  round-trip through the existing dynamic save path.
- [ ] Preserve deterministic source order for Wanderer and other random
  starts using named Lua RNG calls.

The broad Wanderer start is playable and deterministic. Exact parity for
per-run item-set choices, minor themed books, and the C++ RNG subgenerator
remains open in the port inventory.

### Task 4: Integration and one commit

**Files:** changed Lua/Go files, `docs/port-inventory.md`.

- [x] Run focused matrix, terminal, and save/restore tests; fix all failures
  across the whole category.
- [x] Run `go test ./... -count=1`, vet, build, style, catalog, and diff checks.
- [x] Review the whole branch for Go ID handlers, old start paths, oversized
  functions, and malformed-mod behavior.
- [ ] Commit once and fast-forward local Go `main`, preserving the untracked save.
