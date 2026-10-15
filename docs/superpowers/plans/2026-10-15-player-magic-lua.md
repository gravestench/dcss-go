# Player Magic in Lua Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan. Task boxes track the
> work; per the user's category-commit preference, commit once at the end.

**Goal:** Make every pinned-source player-use spell resolve through Lua-owned
knowledge, learning, casting, targeting, and effect rules.

**Architecture:** Keep the existing Go kernel and Lua policy/ECS interface.
Represent spell knowledge as Lua-schema ECS records, run one player-cast
intent through Lua, and register effects by source spell ID in focused Lua
modules. Terminal Go carries choices and draws Lua presentation decisions.

**Tech Stack:** Go 1.25, Akara v0.1.4, GopherLua, Bubble Tea v2, embedded
Lua 5.1-compatible files.

**Spec:** `docs/superpowers/specs/2026-10-15-player-magic-lua-design.md`

## Global Constraints

- The pinned C++ source is `crawl-ref/source` at revision
  `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`; runtime never reads it.
- Cover 109 memorisable book spells and 16 other player-use spell IDs.
- No Go game-rule dispatcher, adapter, parallel cast path, or inline Lua.
- Commit generated Lua content; importers run only on deliberate refresh.
- Prefer 80-character Lua/Go lines, maximum 120; split multi-field literals.
- Make one category commit after broad integration and verification.

## Review Focus

1. A monster-only or removed ID appears in a book/mod: reject before effect
   resolution; exercise in the catalog coverage test in Task 1.
2. Target selection cancels after preflight: preserve MP, HP, RNG, and aut;
   exercise in the transaction test in Task 3.
3. Save resumes during memorisation: preserve remaining delay and original
   spell record; exercise in the restore test in Task 2.
4. A mod replaces a spell effect at the same path: resolve the overlay and
   change the ruleset hash; exercise in the mod test in Task 7.
5. A persistent summon, cloud, or form survives save/restore and level
   transition with the correct owner and duration; exercise in Task 6.

---

### Task 1: Source classification and spell state

**Files:**
- Create: `internal/modfs/builtin/data/player_spell_ids.lua`
- Create: `internal/modfs/builtin/schemas/spell_record.lua`
- Create: `internal/modfs/builtin/schemas/spellcasting.lua`
- Create: `internal/modfs/builtin/policy/character/spell_records.lua`
- Modify: `internal/modfs/builtin/policy/character/start.lua`
- Modify: `internal/modfs/builtin/schemas/character_origin.lua`
- Modify: `internal/modfs/builtin/policy/save/player.lua`
- Modify: `internal/game/save_restore_validation.go` only for generic dynamic
  entity role validation when needed; keep spell semantics in Lua.
- Test: `internal/game/player_magic_state_test.go`

**Interfaces:** `spell_records.list(ctx, owner)`, `.find(ctx, owner, id)`,
`.grant_library(ctx, owner, id)`, `.know(ctx, owner, id, slot)`, and
`.schedule(ctx, owner, id, level)`. Records have owner, spell ID, library,
known slot, letter slot, and future innate level fields. `character.spellcasting` has last
spell ID and pending memorisation fields.

- [ ] Add a test that counts the source classifications, rejects invalid
  player IDs, and verifies all starts create saved ECS records.
- [ ] Add the committed 125-ID classification and schemas; convert the start
  transaction and save validator; remove the origin spell strings.
- [ ] Run only the new state and restore tests; resolve failures before
  building on these interfaces.

### Task 2: Complete spell learning lifecycle

**Files:**
- Create: `internal/modfs/builtin/policy/character/spell_learning.lua`
- Create: `internal/modfs/builtin/systems/spell_memorisation.lua`
- Modify: `internal/modfs/builtin/policy/character/advancement.lua`
- Modify: `internal/modfs/builtin/policy/command_prepare.lua`
- Modify: `internal/modfs/builtin/policy/command_timing.lua`
- Test: `internal/game/player_spell_learning_test.go`

**Interfaces:** `spell_learning.available(ctx, player)`,
`.begin(ctx, player, spell_id)`, `.interrupt(ctx, player)`, and
`.finish(ctx, player)`. The system advances a saved delay in aut. Advancement
uses scheduled records for Djinni at source levels.

- [ ] Test library/known separation, species and level restrictions, spell
  level capacity, known cap, delay length and interruption, Djinni grants,
  and mid-delay save continuation.
- [ ] Port `spl-book.cc`, `player.cc`, and `delay.cc` rules into the Lua
  modules and route learning through the existing intent pipeline.
- [ ] Run the learning tests and character-start tests together.

### Task 3: Source cast transaction and formulas

**Files:**
- Create: `internal/modfs/builtin/policy/commands/cast.lua`
- Create: `internal/modfs/builtin/policy/magic/power.lua`
- Create: `internal/modfs/builtin/policy/magic/failure.lua`
- Create: `internal/modfs/builtin/policy/magic/targeting.lua`
- Create: `internal/modfs/builtin/policy/magic/cast.lua`
- Create: `internal/modfs/builtin/systems/player_spell.lua`
- Modify: `internal/ecs/components.go`, `internal/game/commands.go`,
  `internal/game/command_script.go`, and `internal/modfs/builtin/policy/command_prepare.lua`
  only to carry a generic player spell intent and target data.
- Test: `internal/game/player_spell_cast_test.go`

**Interfaces:** `cast.prepare(ctx, player, spell_id, target, forced)` returns
an abort message or prepared intent; `cast.resolve(ctx, player, intent)`
returns `abort`, `fail`, or `success` and emitted events. Formula modules
expose source-scaled power, raw/true failure, range, MP cost, and noise.

- [ ] Test source numeric vectors and abort/fail/success order, MP/HP refund,
  RNG stream, practice, messages, aut, and target cancellation.
- [ ] Implement common rules directly in Lua with source comments; add only
  reusable grid/targeting primitives to Go when the existing context lacks
  them.
- [ ] Run the cast transaction tests and existing combat tests.

### Task 4: Full-terminal spell controls

**Files:**
- Create: `internal/modfs/builtin/policy/input/spells.lua`
- Create: `internal/modfs/builtin/policy/presentation/spells.lua`
- Modify: `internal/modfs/builtin/policy/input/play.lua`
- Modify: `internal/terminal/app.go` and the focused input/view files that
  currently assume aim means only Fire or Throw.
- Modify: `internal/game/view.go` to project known/library spell records.
- Test: `internal/terminal/player_spell_input_test.go`

**Interfaces:** Lua input returns spell selection, memorisation, recast,
and aim decisions. The Go terminal renders rows/prompts from Lua and sends
the selected ID and target as ordinary `game.Command` fields.

- [ ] Test `z`, `Z`, `M`, letter choice, recast, target cancellation, no-time
  invalid choice, full-size layout, and source-shaped messages.
- [ ] Implement Lua policy and presentation with minimal generic Go input
  plumbing; keep failure, range, and cost calculations out of Go.
- [ ] Run terminal spell input and current presentation tests.

### Task 5: Direct, zap, area, cloud, and terrain effects

**Files:**
- Create: `scripts/import-player-zaps.py` and the committed
  `internal/modfs/builtin/data/player_spell_zaps.lua` mapping. The importer
  runs only during a reviewed source refresh.
- Create focused modules under `internal/modfs/builtin/policy/magic/effects/`
  and any Lua schemas/systems for persistent clouds and terrain effects.
- Create: `internal/modfs/builtin/policy/magic/effects/registry.lua`
- Test: `internal/game/player_spell_effects_test.go`

**Interfaces:** Each effect module registers source spell IDs with
`registry.add(id, effect)`; `effect.can_target` and `effect.resolve` use the
same Lua context. Registry validation compares the 125-ID manifest against
registered effects at boot.

- [ ] Port every player-use direct, zap, projectile, area, cloud, and terrain
  spell effect; share only mechanically identical primitives.
- [ ] Convert terrain storage to feature IDs and source-traced Lua feature
  properties where a spell needs rock, permanent wall, door, and floor
  distinctions. Keep rendering glyphs separate from feature identity.
- [ ] Test representative source vectors in each family and assert no
  missing/duplicate registrations across the full manifest.

### Task 6: Summons, translocation, statuses, forms, and necromancy

**Files:**
- Create remaining focused effect modules under
  `internal/modfs/builtin/policy/magic/effects/`.
- Create Lua schemas/systems for durable summon ownership, spell statuses,
  form state, and timed effects as required by the pinned source.
- Modify Lua actor death, world timing, and save policies where these effects
  create state; avoid Go spell-specific logic.
- Test: `internal/game/player_spell_persistent_effects_test.go`

**Interfaces:** Effects use the registry from Task 5 and generic ECS/grid
operations; persistent state is queryable and serializable.

- [ ] Port every remaining player-use spell effect without placeholder
  success or a fallback to a Go resolver.
- [ ] Test representative summon, movement, status, form, and necromancy
  behavior, expiry, level travel, and save continuation.
- [ ] Verify all 125 IDs have a source-backed result path.

### Task 7: Overlay, integration, and category commit

**Files:**
- Modify: `docs/port-inventory.md`
- Create test overlay Lua under an existing `internal/modfs` or
  `internal/script/testdata` mod directory.
- Test: integration tests in `internal/game` and `internal/terminal`.

**Interfaces:** No new runtime interface; this task verifies the complete
category in its exact final tree.

- [ ] Test same-path spell effect override, changed ruleset hash, save
  mismatch, deterministic replay, every species/job start, and all player
  spell ID classification outcomes.
- [ ] Run `gofmt` on changed Go, `go test ./... -count=1`, `go vet ./...`,
  `go build ./...`, `sh scripts/check-go-style.sh`,
  `python3 scripts/export-catalog-lua.py --check`, the player-zap importer
  `--check` against the pinned source, and `git diff --check`.
- [ ] Review the full category for source fidelity and readability; repair
  substantive findings, then commit once and merge into local `main`.
