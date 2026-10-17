# Source Monster Spell Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task by task. Steps use
> checkbox (`- [ ]`) syntax. Make one implementation commit for the whole
> selection category, as requested by the user.

**Goal:** Let every committed source monster spellbook use the pinned
weighted and conditional selection rules, while validating live effects
before a monster can enter a generation roster.

**Architecture:** Lua `policy.ai.spell_prospect` owns the pure source roll.
Lua `policy.ai.spell` owns actor conditions and target validation. The
`attack.spell` system resolves only a slot selected from the actor's
effective book. A separate coverage policy checks the live roster against
discoverable effect modules. Go only adds a generic intent field if the
selected source slot index cannot be represented today.

**Tech Stack:** Go, Akara ECS, gopher-lua, embedded layered Lua mods, Lua
`_test.lua` rules tests.

**Spec:** `docs/superpowers/specs/2026-10-16-monster-spell-selection-design.md`

## Global Constraints

- Match pinned DCSS source `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Runtime uses committed catalogs; no C++ tree read during build or launch.
- Game policy and spell handlers remain in discoverable Lua files.
- No inline Lua in Go, central spell switch, silent unsupported spell, or
  compatibility adapter.
- Handwritten Go and Lua lines are at most 120 characters, preferably 80;
  expand multi-field literals and leave blank lines between distinct steps.
- Keep the current D:1–2 roster playable; later effect slices expand it.
- Commit the whole selection category once and merge verified work into
  local `main`.

## Review Focus

1. A 200-point roll equal to a slot frequency selects that slot, matching
   the source's inclusive comparison.
2. A slot filtered by emergency or range consumes no weight.
3. A failed target check gets one second prospect; a no-spell roll gets none.
4. Two slots with the same spell ID retain their distinct selected flags.
5. A mod-added live monster with a missing effect fails a named coverage
   check before generation; unused books do not block launch.

---

## File map

- `policy/ai/spell_prospect.lua`: pure weighted and flagged source choice.
- `policy/ai/spell.lua`: actor/target orchestration, retry, silence, and
  antimagic checks.
- `policy/combat/monster_spells.lua`: discoverable effect lookup and
  interface validation.
- `policy/combat/monster_spellbook.lua`: effective book and slot lookup,
  shared by decision and execution.
- `policy/population/roster.lua`: uses coverage for the active scenario.
- `systems/attack_spell.lua`: validates and resolves the selected slot.
- `constants/monster_spell_flags.lua`: names all slot flags used by choice.
- `internal/ecs/components.go`: selected slot index in generic intent, if
  needed; host conversion and save round trip use the same field.
- `internal/script/testdata/lua/tests/monster_spell_*_test.lua`: production
  selector, catalog, and coverage tests.
- `internal/game/monster_spell_*_test.go`: integrated cast and save tests.
- `docs/port-inventory.md`: record selection completion and effect gap.

### Task 1: Source weighted prospect for every book

**Files:** Create `policy/ai/spell_prospect.lua`,
`constants/monster_spell_flags.lua`, and
`internal/script/testdata/lua/tests/monster_spell_prospect_test.lua`.

**Interfaces:** `prospect.choose(book, condition, random, preferred)`
returns `slot, index` or nil. `condition` has `hp`, `max_hp`, `distance`,
and `fleeing`; `random(bound)` returns a zero-based draw. `preferred`
is nil, `"selfench"`, or `"escape"`. The selector reads spell definition
flags from the production catalog.

- [ ] Write Lua tests for each review-focus roll boundary, empty and
  overweight books, source-order priority, emergency threshold, both range
  flags, fleeing escape, and weighted self-enchantment. Use production
  definitions where available and minimal test-only book slots.
- [ ] Run focused `TestLuaRules/monster_spell_prospect_test`; observe a
  missing module or wrong selection, not a test harness error.
- [ ] Implement the pure selector with source ordering and flag constants;
  run the focused test green.

### Task 2: Decision and execution share the effective slot

**Files:** Create `policy/combat/monster_spellbook.lua`; modify
`policy/ai/spell.lua`, `systems/attack_spell.lua`, the generic intent
component and host conversion if required. Add
`monster_spell_decision_test.lua` and `monster_spell_execution_test.lua`.

**Interfaces:** `monster_spellbook.for_actor(ctx, actor)` returns the
effective book, including the existing vault empty-book suppression.
`monster_spellbook.slot(book, index, spell_id)` validates an exact slot.
Decision returns `{ kind = 12, spell_id = id, spell_slot = index }`.

- [ ] Write failing tests for multi-slot decisions, duplicate spell IDs,
  two targeting attempts, no retry on no-spell, unchanged silence and
  antimagic, exact execution slot validation, and the existing vault
  empty-book override. An added book in a layered mod follows the same
  selector once its monster is admitted to a scenario.
- [ ] Make the decision and execution use shared book/slot lookup. Persist
  the selected slot index in generic `core.intent` and its Go codec only
  if the existing host component cannot carry it already.
- [ ] Run the focused Lua tests and existing single-slot monster tests.

### Task 3: Live roster effect coverage

**Files:** Modify `policy/combat/monster_spells.lua` and
`policy/population/roster.lua`; create
`policy/combat/monster_spell_coverage.lua` and
`monster_spell_coverage_test.lua`. Update `docs/port-inventory.md`.

**Interfaces:** `coverage.missing(monster_ids)` returns sorted diagnostic
records naming monster, book, spell, and missing or malformed effect.
`roster.allowed(scenario_id)` rejects a live roster whose missing list is
nonempty. Catalog-only books are not checked until admitted.

- [ ] Write a failing Lua coverage test for a missing effect, malformed
  effect, an unused source book, and every current generated-roster monster.
- [ ] Add discoverable effect interface checks and roster preflight. Keep
  unsupported effects out of live generation; never skip a selected spell.
- [ ] Run focused Lua coverage and existing generation tests green.

### Task 4: Integrated verification and one category commit

**Files:** Add `internal/game/monster_spell_selection_test.go` only for
end-to-end cases not covered by Lua rules tests; adjust existing tests
when source roll parity changes.

- [ ] Write integrated tests for a multi-slot monster with implemented
  effects and deterministic save/restore continuation. Verify they fail
  for the intended behavior before completing the slice.
- [ ] Run focused Lua and Go tests, then `go build ./...`, `go vet ./...`,
  `sh scripts/check-go-style.sh`, and `git diff --check`. Run broader tests
  once at this category boundary; report any timeout by name.
- [ ] Review the branch against the spec, fix material findings, make one
  implementation commit, and fast-forward local `main`.
