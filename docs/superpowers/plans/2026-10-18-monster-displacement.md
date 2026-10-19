# Monster Blink and Recall Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make all eight missing monster blink variants and Word of Recall playable through Lua and durable Akara state.

**Architecture:** Discoverable per-spell effects own eligibility and source
choices. Focused Lua helpers own landing, weighting, relocation, and allies.
A Lua component and system own recall timing. Go remains the generic kernel.

**Tech Stack:** Go 1.26, Akara ECS, GopherLua, committed Lua content, JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-18-monster-displacement-design.md`

## Global Constraints

- Pinned DCSS source: `/Users/dylanknuth/src/crawl/crawl-ref/source` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Implement gameplay in real embedded Lua files; no inline Lua, Go spell
  switch, compatibility adapter, or runtime C++ import.
- Import shared IDs where used. Comment every new function's why and how;
  explain each system's theory of operation.
- Keep lines at most 120 columns and multi-field tables vertically formatted.
- Commit the implementation as one contiguous monster-displacement category after integrated verification.

## Review Focus

- A monster with Dimension Anchor or no-tele flags never moves, and planning refuses impossible self blinks.
- An occupied, unsafe, or out-of-sight candidate never receives a moved actor.
- A moved or dead foe cannot silently retarget a prepared ally-encirclement cast.
- A failed ally placement does not consume the spell's successful-move count or alter that ally's AI energy.
- Recall interruption and save/restore preserve chant and breath timing without rerunning the spell.

---

### Task 1: Shared monster relocation policy

**Files:**
- Create: `internal/modfs/builtin/policy/combat/monster_displacement/landing.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_displacement/relocate.lua`
- Test: `internal/script/testdata/lua/tests/monster_displacement_test.lua`

**Interfaces:**
- `landing.ordinary(ctx, mover) -> x, y | nil, nil` samples source nearby offsets.
- `landing.weighted(ctx, mover, focus, close, keep_los) -> x, y | nil, nil` chooses source weighted cells.
- `landing.near(ctx, mover, anchor, radius) -> x, y | nil, nil` finds group and recall cells.
- `relocate.can_move(ctx, mover) -> boolean` shares anchor, flag, and constriction checks.
- `relocate.move(ctx, mover, x, y, source) -> boolean` releases nets, moves the actor, and creates the origin cloud.

- [ ] Add Lua tests for draw bounds, adjacent exclusion, habitat, occupancy,
  sight, anchor, and cloud placement with production schemas.
- [ ] Run the focused `monster_displacement_test.lua` subtest red.
- [ ] Implement both helpers with the monster-spell RNG, existing habitat
  and no-tele rules, `ctx:move_actor`, and the cloud placement policy.
- [ ] Rerun the focused Lua test until it passes.

### Task 2: Self and foe blink effects

**Files:**
- Create: `internal/modfs/builtin/policy/combat/monster_spells/blink.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_spells/blink_range.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_spells/blink_away.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_spells/blink_close.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_spells/blink_other.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_spells/blink_other_close.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_displacement/foe.lua`
- Extend: `internal/script/testdata/lua/tests/monster_displacement_test.lua`

**Interfaces:** Each spell exposes `plan(ctx, caster, foe, slot)` and
`resolve(ctx, caster, foe, slot, plan)`. `foe.plan` preserves target identity;
`foe.resolve` traces contact, tests resistance, and relocates the target.

- [ ] Test every resolver, eligibility, preserved target, player and monster
  resistance, and close/far weighting.
- [ ] Run the focused Lua test red.
- [ ] Implement each effect around shared landing and relocation. Reuse beam
  trace and hex resistance for Other; do not add a monster-ID dispatcher.
- [ ] Run the focused Lua test green.

### Task 3: Group ally blink effects

**Files:**
- Create: `internal/modfs/builtin/policy/combat/monster_spells/blink_allies_away.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_spells/blink_allies_encircle.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_displacement/allies.lua`
- Extend: `internal/script/testdata/lua/tests/monster_displacement_test.lua`

**Interfaces:** `allies.candidates(ctx, caster, foe, mode) -> array` returns
aligned, visible, eligible actors. `allies.move(ctx, caster, plan, mode) -> count`
shuffles them and counts only successful moves up to the source HD limit.

- [ ] Test ally filtering, attitude, a moved planned foe, count, failed
  placement, Encircle AI/energy, and Away distance.
- [ ] Run focused Lua test red, implement the two effects and candidate helper, then run it green.

### Task 4: Saved Word of Recall

**Files:**
- Create: `internal/modfs/builtin/schemas/magic_monster_recall.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_spells/word_of_recall.lua`
- Create: `internal/modfs/builtin/policy/combat/monster_displacement/recall.lua`
- Create: `internal/modfs/builtin/systems/magic_monster_recall.lua`
- Modify: `internal/modfs/builtin/constants/component.lua`
- Modify: `internal/modfs/builtin/policy/save/monsters.lua`
- Test: `internal/script/testdata/lua/tests/monster_recall_test.lua`

**Interfaces:** `recall.eligible(ctx, caster, candidate) -> boolean`,
`recall.start(ctx, caster)`, and `recall.tick(ctx, caster, delta)` own the chant
and followers. Component fields `chant_aut` and `breath_aut` are int64.

- [ ] Test eligibility, 30-aut chant, interruption, follower choice,
  3–7 successful moves, breath cooldown, and invalid saved state.
- [ ] Run `go test ./internal/script -run '^TestLuaRules/monster_recall_test.lua$' -count=1` red.
- [ ] Implement the schema, policy, effect, update system, and save validation without module-global timing state.
- [ ] Rerun the focused test green.

### Task 5: Live game, documentation, and integration

**Files:**
- Create: `internal/game/testdata/monster-displacement/content/monster_spellbooks/mst_endoplasm.lua`
- Create: `internal/game/monster_displacement_test.go`
- Modify: `docs/port-inventory.md`
- Modify: `docs/ecs-architecture-roadmap.md`
- Extend: `internal/script/testdata/lua/tests/monster_spell_coverage_test.lua`

**Interfaces:** The overlay gives a real caster a blink spell. The game test
observes an Akara move and identical restore/next-turn state.

- [ ] Add the live monster cast and save test plus spellbook coverage assertions for all nine IDs.
- [ ] Run focused tests red, finish integration, and update inventory.
- [ ] Run full Lua rules and affected monster/vault game tests.
- [ ] Run build, vet, Go style, Lua width, and diff checks.
- [ ] Review source fidelity and registration. Commit once as
  `feat: port monster blink and recall family to Lua`.
- [ ] Fast-forward local `main` after verification, then rerun the affected tests on the merged tree.
