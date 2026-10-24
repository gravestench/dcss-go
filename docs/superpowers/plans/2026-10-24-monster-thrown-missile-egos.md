# Monster Thrown Missile Egos Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve every committed monster-thrown missile ego through Lua after contact, including returned shots and fragment explosions.

**Architecture:** The monster ranged action retains contact, base damage, and reflection. One Lua missile ego dispatcher validates a saved ego and invokes small effect modules after a landed hit. Chaos chooses an ego and enters that same dispatcher; exploding ammunition invokes a separate impact blast at its contact cell.

**Tech Stack:** Embedded Lua policies and `_test.lua` rules, Akara ECS status owners, Go game integration tests.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-thrown-missile-egos-design.md`

## Global Constraints

- Keep all gameplay policy in embedded Lua files; no inline Lua in Go.
- Use source `ranged-attack.cc` and `throw.cc` ordering and source dice.
- Name imported ego IDs; keep handwritten code within 120 columns.
- Commit this whole monster-thrown ego category together and push `main`.

## Review Focus

- An unknown ego must fail during intent planning, before RNG and a spent turn.
- A miss or block must not poison, move, confuse, or frenzy the player.
- A dead target must not receive a surviving-target status effect.
- A reflected hit must apply the ego to the shooter, with the return impact used for a blast.
- A blast must reach legal neighboring cells but not pass through walls.

---

### Task 1: Canonical ego IDs and legal shot validation

**Files:** Modify `internal/modfs/builtin/constants/missile_egos.lua`, remove the duplicate `constants/missile_brands.lua`, and update its 11 production/test importers. Modify `policy/combat/monster_projectiles/{dart,stone,thrown}.lua` and `policy/ai/ranged.lua`. Add `internal/script/testdata/lua/tests/monster_thrown_egos_test.lua`.

**Interfaces:** `policy.combat.monster_missile_egos.validate(kind_id, item)` checks known egos and catalog missile compatibility without consuming RNG. Existing projectile resolvers retain their contact signatures.

- [x] Add failing Lua cases for generated dart, javelin, and boomerang brands, and an unknown saved ego.
- [x] Run the focused Lua test and confirm the current validator rejects supported egos.
- [x] Consolidate constants and move validation to the shared dispatcher.
- [x] Rerun the focused test and confirm every covered legal case passes while unknown IDs fail.

### Task 2: Player-facing post-hit effects

**Files:** Create `policy/combat/monster_missile_egos.lua` and `policy/combat/monster_missile_egos/{elemental,poison,silver,mind,dispersal,chaos}.lua`. Move the behavior from `policy/combat/chaos_missile_player.lua` into those owners and remove that old file. Modify `policy/combat/ranged_actions.lua`. Extend `monster_thrown_egos_test.lua` and existing `xom_chaos_missile_test.lua`.

**Interfaces:** `monster_missile_egos.apply_player(ctx, attacker, definition, kind, ego, damage)` runs after a surviving hit and returns the selected ego (the input ego unless Chaos chose another). Each focused effect module applies its own status or HP change through the existing owners.

- [x] Add failing outcome tests for each ego, resistance, stasis, zero damage, and target death. Prove non-poisoned darts consume no poison roll.
- [x] Implement named effect functions using existing health, brand, condition, and movement owners; retain source RNG order and dart contact-only damage.
- [x] Run the focused rules and existing Chaos rules; compare each roll and status against source.

### Task 3: Returned missiles and exploding impact

**Files:** Modify `policy/combat/ranged_actions.lua`, `policy/combat/projectile_effects.lua`, and `policy/combat/monster_projectiles/thrown.lua`. Create `policy/combat/monster_missile_egos/exploding.lua`. Extend `monster_thrown_egos_test.lua` and `ranged_reflection_test.lua`.

**Interfaces:** `exploding.impact(ctx, attacker, level_id, x, y)` uses `policy.combat.explosion.cells` with radius 1 and 2d5 fragment dice. The ranged action supplies the impact position for normal and returned shots.

- [x] Add failing reflection tests for status and extra damage, and blast tests for radius, wall shielding, and shooter overlap.
- [x] Reuse monster-facing projectile effects on return; implement the fragment blast through existing combat owners.
- [x] Run focused tests and confirm the behavior is the same on ordinary and Chaos-selected egos.

### Task 4: Game integration and category verification

**Files:** Extend `internal/game/zot_vault_family_test.go` or add a focused monster-missile integration test. Update `docs/port-inventory.md`.

- [x] Add an integration case that saves and restores after a monster throws branded ammo, including the Zot route that exposed Dispersal.
- [x] Run affected Lua tests, game integration, `go build ./...`, `gofmt`, `sh scripts/check-go-style.sh`, and `git diff --check`; classify any unrelated baseline failures.
- [x] Review the entire category for unused adapters, magic IDs, comment clarity, and save ownership.
- [x] Commit one contiguous monster-thrown ego category and push `origin main`.
