# Source Monster Beam Spells Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task by task. Steps
> use checkbox (`- [ ]`) syntax for tracking. Make one implementation
> commit for the completed beam family.

**Goal:** Implement the 44 committed monster beam spells with source
targeting and effects, using discoverable Lua modules and one shared beam
kernel.

**Architecture:** A deliberate source importer emits committed Lua beam
profiles. Lua `policy.combat.monster_beams` handles actor-neutral tracing,
hit resolution, defenses, elemental/status/cloud effects, and source
attribution. One effect module per spell uses that kernel and any named
spell-specific rule. The existing spell intent carries the chosen book
slot and typed target plan through execution and saves.

**Tech Stack:** Go, Akara ECS, gopher-lua, embedded layered Lua mods,
Lua `_test.lua` rules tests.

**Spec:** `docs/superpowers/specs/2026-10-16-monster-beam-spells-design.md`

## Global Constraints

- Pin behavior to DCSS `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Runtime uses committed Lua; the importer is only for deliberate refresh.
- All game effects and source spell policies live in actual Lua files.
- No generic damage fallback, spell-ID switch, compatibility adapter, or
  player-caster effect reused as a monster effect.
- Source IDs and shared flags are imported from named Lua constants.
- Keep handwritten lines at most 120 characters; prefer 80 and expand
  multi-field tables.
- Implement the entire 44-spell family before the implementation commit.
- Run broad tests once at the category boundary, not after every file.

## Review Focus

1. A reflected beam preserves its monster source and cannot hit an
   unrelated actor after changing direction.
2. A penetrating beam visits contacts in source order, while a bolt ends
   on the first blocking contact.
3. Elemental resistance and AC apply only to the flavors whose source
   rules use them; poison, corrosion, and status effects survive saves.
4. An empty-cell target, blocked shot, or friendly-fire veto rejects the
   spell at planning time without silently substituting damage.
5. A layered mod can add or replace a beam effect by relative Lua path,
   and a missing effect is rejected by live-roster coverage.

---

## File map

- `scripts/import-monster-beams.py`: strict, manual parser for the 44
  source spell-to-zap mappings and monster zap profiles.
- `internal/modfs/builtin/content/monster_beams/*.lua`: committed,
  individually named source profiles with provenance comments.
- `internal/modfs/builtin/policy/combat/monster_beams/*.lua`: trajectory,
  target planning, hit/defense, damage/status, terrain/cloud, and messages.
- `internal/modfs/builtin/policy/combat/monster_spells/*.lua`: one
  discoverable effect per ID from the spec appendix.
- `internal/modfs/builtin/policy/ai/spell.lua`: calls `effect.plan` once per
  source targeting attempt and writes the selected target plan.
- `internal/modfs/builtin/systems/attack_spell.lua`: validates the exact
  book slot, then calls `effect.resolve` using the saved target plan.
- `internal/ecs/components.go` and the host intent codec: named entity or
  cell target fields, serialized without arbitrary Lua tables.
- Current `freeze.lua`, `slug_dart.lua`, `petrify.lua`, and `hex.lua`:
  migrate to the same plan/resolve interface in one change.
- `internal/script/testdata/lua/tests/monster_beam_*_test.lua`: real
  production profiles and effects under the shared Lua harness.
- `internal/game/monster_beam_*_test.go`: integrated actor, beam,
  cloud/status, mod override, and save/restore behavior.

### Task 1: Pin the source beam catalog

**Produces:** `content/monster_beams/<spell>.lua` for each of the 44
appendix IDs. Each profile names its zap, monster power rule, damage and
to-hit calculators, flavor, shape, range, noise, source overrides, and
any required special hook. A missing or unsupported source construct is
an importer error.

- [ ] Add importer tests using small pinned `zap-data.h` and
  `mon-cast.cc` fixtures. Assert monster calculators, hex helpers,
  fallthrough cases, source line comments, stable output, and rejection
  of an unknown calculator.
- [ ] Run importer tests red for the missing parser.
- [ ] Implement `scripts/import-monster-beams.py` and generate the 44
  committed Lua profiles. Use a common constants module for source
  flavor, shape, and status IDs.
- [ ] Run importer tests and a `--check` regeneration against the
  pinned source; assert exactly the spec's 44 IDs.

### Task 2: Carry a selected target plan in the intent

**Produces:** `effect.plan(ctx, caster, foe, slot) -> plan|nil` and
`effect.resolve(ctx, caster, foe, slot, plan)` for every monster effect.
The plan is a typed entity or level-cell target plus direction. Only
source target selection can consume RNG during planning. No world state
changes until resolution.

- [ ] Add Lua decision/execution tests for one entity target, one empty
  cell, source targeting rejection, duplicate book-slot IDs, and exactly
  one target RNG sequence through decision and execution. Add a Go save
  round-trip test for every new intent field.
- [ ] Run those tests red on the old `can_cast`/`resolve` contract.
- [ ] Add typed intent fields and host conversion; migrate the four
  existing monster effects, decision policy, resolver, and coverage
  validator to plan/resolve in one pass. Delete the old interface.
- [ ] Run the focused monster spell and save tests green.

### Task 3: Implement the actor-neutral beam kernel

**Produces:** focused `policy.combat.monster_beams` modules, whose
public entry point is `beam.plan(ctx, caster, foe, profile)` and
`beam.resolve(ctx, caster, foe, profile, plan)`. Spell-specific hooks
may extend the plan or outcome but do not duplicate trajectory or
defense code.

- [ ] Write Lua tests with production source profiles for LOS, wall
  obstruction, first-hit bolt, penetrating beam, shield block and
  reflection, AC, elemental resistance, and combat credit. Cover the
  Review Focus cases in tests that name the relevant source spell.
- [ ] Run the family tests red before writing the kernel.
- [ ] Implement tracing and target planning first, then defenses and
  damage/status delivery, then saved cloud/terrain placement. Reuse
  existing generic grid and Akara primitives; move player-only formulas
  into actor-neutral Lua helpers only when the source rule is shared.
- [ ] Run the focused Lua family tests green.

### Task 4: Complete every concrete beam effect

**Produces:** one discoverable `monster_spells/<spell>.lua` per spec ID,
using the committed profile and named special behavior for explosions,
clouds, digging, pulling, sleep, poison, corrosion, sticky flame, and
other source-specific cases. The effect registry has no central list.

- [ ] Add a test that loads each of the 44 production effects and checks
  its plan/resolve functions, source profile, and required special hook.
  A bare generic damage profile fails this test for special-effect IDs.
- [ ] Run that coverage test red for the missing modules.
- [ ] Implement all 44 modules and their specific helpers. Keep a
  source-traced behavior matrix in the test fixture, not in a runtime
  spell-ID switch.
- [ ] Run the full monster-beam Lua suite green; ensure the roster
  preflight reports no missing effect for these spells.

### Task 5: Verify play and integrate one category commit

- [ ] Add integrated Go cases for a multi-slot beam caster, a block or
  reflection, one cloud or status result, a sparse mod override, and
  deterministic save/restore continuation. Observe intended red failures
  before completing the effect modules.
- [ ] Run focused Go tests, the full Lua suite, `go build ./...`,
  `go vet ./...`, `sh scripts/check-go-style.sh`, and `git diff --check`.
  Run the broad game suite once with a suitable timeout; report the
  exhaustive character-start test separately if it exceeds the limit.
- [ ] Review the whole branch against the 44-ID spec appendix and source
  behavior matrix. Fix material findings, make one family commit, then
  fast-forward local `main` after verification.
