# Monster Direct Summons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every pinned-source direct-creature monster summon a faithful Lua effect using one Akara summon owner.

**Architecture:** Existing spellbook choice and typed intent invoke one
discoverable effect module per spell. An actor-neutral Lua summon creator
owns Akara creation, placement, expiry, and caps. Focused picker modules
and per-spell methods own source decisions. Saved attitude represents the
full source allegiance, including neutral variants.

**Tech Stack:** Go, embedded Lua, Akara ECS, layered mod VFS, JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-18-monster-direct-summons-design.md`

## Global Constraints

- Pin source behavior to `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Keep game rules and all test Lua in `.lua` files; Go supplies generic services.
- Use committed content, path discovery, imported IDs, and named saved RNG streams.
- Keep Lua and handwritten Go lines at most 120 columns, with 80 preferred.
- Make one implementation commit for this contiguous summon category;
  test the integrated family at its boundary.
- Do not add a content-ID switch or a second compatibility path.

## Review Focus

1. A hostile caster's new summon must fight for that caster, not the
   player: Task 1 allegiance test and Task 6 live test.
2. A neutral or good-neutral caster must preserve that side through
   save/restore: Task 1 schema test and Task 6 restore test.
3. A blocked or invalid spawn cell must spend the source cast without an
   orphan Akara entity: Task 2 failure test.
4. A foe-centered cast must not relocate its saved target after movement or death: Task 4 intent test.
5. A mod-added spell file must work without changing bundled registries: Task 6 sparse overlay test.

---

### Task 1: Source attitude and saved summon ownership

**Files:** Modify `internal/modfs/builtin/schemas/magic_summon.lua`,
`internal/modfs/builtin/policy/ai/targets.lua`,
`internal/modfs/builtin/policy/character/allies.lua`,
`internal/modfs/builtin/policy/save/summons.lua`, and every current reader
of `SUMMON.hostile` in cloud, gateway, and tentacle Lua policies; update
`internal/game/player_mutation_no_love_test.go`,
`internal/game/scroll_read_test.go`, and affected summon save tests. Create
`internal/modfs/builtin/constants/attitude.lua`, replace imports of
`constants.vault_attitude`, and remove that old module.
Test in `internal/script/testdata/lua/tests/monster_summon_attitude_test.lua`
and affected existing Lua tests.

**Interfaces:** `targets.real_attitude(ctx, entity)` returns a named source
attitude; `targets.attitude(ctx, entity)` includes temporary charm.
`SUMMON.attitude` replaces the boolean `hostile` in schema version 4.
The actor-neutral creator in Task 2 uses these methods.

- [ ] Add RED Lua tests for hostile, friendly, neutral, good-neutral,
  charmed, and player No Love ownership, including a detached save-shaped
  summon record with the new field.
- [ ] Run `go test ./internal/script -run monster_summon_attitude -count=1`
  and record the failure.
- [ ] Implement named attitude and update every Lua consumer in one pass;
  keep player No Love behavior while inheriting a monster caster's current
  source attitude at creation.
- [ ] Run the focused test and existing ally, cloud, gateway, tentacle,
  and save Lua cases; inspect failures before moving on.

### Task 2: Actor-neutral creation and placement

**Files:** Modify
`internal/modfs/builtin/policy/magic/effects/summons/common.lua` and
`internal/modfs/builtin/policy/population/hit_points.lua` if source-shaped
creation needs a generic HP or placement capability. Test in
`internal/script/testdata/lua/tests/monster_summon_creation_test.lua`.

**Interfaces:** `summons.spawn(ctx, owner, source_id, kind_id, degree,
cap, options)` preserves its entry point. `options.anchor`, `exact`,
`attitude`, `hd`, and `heads` are explicit; `cap = nil`
means no per-spell eviction. `summons.expire(ctx, entity)` remains the one
destruction path.

- [ ] Write RED tests for caster-relative spawn, blocked cells, no partial
  entity on failure, optional cap, source HP owner, and expiry cleanup.
- [ ] Run the focused Lua test to record failure.
- [ ] Refactor the creator in one pass so both player and monster calls use
  the same placement, Akara components, attitude, and expiry logic.
- [ ] Run the focused test and player-summon Lua tests; repair regressions.

### Task 3: Source picker and strength primitives

**Files:** Create focused modules under
`internal/modfs/builtin/policy/combat/monster_summons/` for effective spell
HD, weighted choices, and source pools: demons, undead, drakes, holy,
eyeballs, vermin, branch populations. Test in
`internal/script/testdata/lua/tests/monster_summon_pickers_test.lua`.

**Interfaces:** `strength.spell_hd(ctx, caster)` reads effective monster HD;
`strength.power(ctx, caster, spell_id)` applies the source factor;
`choice.weighted(ctx, entries)` returns an imported monster ID using the
monster-spell stream. Pool modules expose named picker methods accepting
`ctx`, never an ID-dispatch table.

- [ ] Write RED table-driven tests for every source pool boundary, spell
  HD with drain and Brilliance, and fixed random draws.
- [ ] Run the focused Lua test to record failure.
- [ ] Implement source tables and calculations with local comments giving
  their reason and `mon-cast.cc` origin.
- [ ] Run the focused test; inspect named-stream continuation.

### Task 4: All direct-creature spell effect files

**Files:** Create one module per ID in the spec under
`internal/modfs/builtin/policy/combat/monster_spells/`. Use small helpers
from Tasks 2 and 3; put target selection under
`internal/modfs/builtin/policy/combat/monster_summons/target.lua`.
Test in `internal/script/testdata/lua/tests/monster_direct_summons_test.lua`.

**Interfaces:** Each module returns a local object with
`effect.plan(ctx, caster, foe, slot)` and
`effect.resolve(ctx, caster, foe, slot, plan)`. The plan uses the existing
typed spell intent, and resolve calls `summons.spawn` for every source
attempt. No module relies on file discovery order or mutable module state.

- [ ] Write RED coverage tests for every listed ID, then source-shaped
  count, duration, species, target, and post-spawn tests in behavior groups.
- [ ] Run the focused Lua test to record missing modules.
- [ ] Implement fixed and weighted-pool, source-population, foe-centered,
  Brother in Arms, and elemental effects as one contiguous category.
  Forceful Invitation's branch choice uses a saved caster component.
- [ ] Run the focused Lua tests and refine all failed source cases.

### Task 5: Save and source semantics

**Files:** Modify `internal/modfs/builtin/policy/save/summons.lua` and
relevant save tests; create a focused schema for Forceful Invitation's
persistent branch choice; update `internal/modfs/builtin/policy/ai/spell.lua`
only if source tactical eligibility cannot live in each effect's `plan`.

**Interfaces:** Saved summon records name a live owner, source, attitude,
position, and expiry. Restore reads Akara state and never recasts Lua.

- [ ] Write RED tests for summon owner, attitude, expiry, source ID, and
  saved invitation branch choice across restore.
- [ ] Run focused Lua and Go save tests to record failures.
- [ ] Implement validation and state ownership without a parallel format.
- [ ] Run focused tests; confirm deterministic next action and RNG state.

### Task 6: Live integration, overlays, docs, review, and one commit

**Files:** Create `internal/game/monster_direct_summons_test.go` with Lua
fixture files under `internal/game/testdata/monster-direct-summons/` and a
sparse effect override; update `docs/port-inventory.md`,
`docs/ecs-architecture-roadmap.md`, and `docs/modding.md` for the new
modder-facing summon contract.

**Interfaces:** The game test exercises a real spellbook cast, ECS spawn,
save/restore, and next action. Coverage rejects any newly admitted caster
whose other spells remain unported.

- [ ] Write a RED game test for hostile and friendly casts, neutral save,
  monster target choice, and one mod-added spell file.
- [ ] Run the focused Go test to record failure; complete the integration
  and resolve any cross-owner regressions.
- [ ] Run `go test ./internal/script -count=1`, affected
  `go test ./internal/game -run TestMonsterDirectSummons -count=1`,
  `go build ./...`, `go vet ./internal/script ./internal/game`, and
  `sh scripts/check-go-style.sh`. Run `git diff --check` and check changed
  Lua lines for the 120-column limit.
- [ ] Review the branch against the spec and pinned source. Commit the
  direct-summon implementation as one category, then fast-forward local
  `main` after the merged checkout is verified.
