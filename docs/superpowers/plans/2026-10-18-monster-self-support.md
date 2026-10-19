# Monster self-support spell implementation plan

**Goal:** Port all 13 committed-book monster self-support spells as live Lua
rules with source eligibility, Akara state, consumer effects, and save
continuation in one contiguous category commit.

**Spec:** `docs/superpowers/specs/2026-10-18-monster-self-support-design.md`

**Source:** DCSS `e60ba3568b0c26447ad36ec5c7b963eb04b2778f` in
`/Users/dylanknuth/src/crawl/crawl-ref/source`, especially `mon-cast.cc`,
`mon-ench.cc`, `monster.cc`, and `beam.cc`.

**Project rules:** Lua owns game policy and the spell modules; Go owns only
generic Akara, grid, save, RNG, and terminal services. Commit content Lua,
not an importer. Keep every function documented, every system's theory of
operation clear, and lines at or below 120 columns. Import shared IDs at
use sites. Test the category as a whole and commit it once.

## File map and interfaces

- `policy/combat/monster_spells/{might,invisibility,haste,minor_healing,
  major_healing,repel_missiles,berserker_rage,sprint,trogs_hand,
  injury_mirror,woodweal,still_winds,aura_of_brilliance}.lua`: one spell
  module each, all exposing `plan(ctx, caster, foe, slot)` and
  `resolve(ctx, caster, foe, slot, plan)`.
- `policy/combat/monster_support/`: focused eligibility, duration, boon,
  healing, defense, mirror, wind, and brilliance owners. Each receives
  explicit actor/context arguments; no mutable module global.
- `schemas/monster_support_*.lua` and `systems/monster_support_*.lua`:
  versioned Akara state and named expiry or aura systems.
- Existing `policy/combat/monster_enchant.lua`,
  `policy/combat/player_brands/chaos_{effects,status}.lua`,
  `policy/monster_energy.lua`, `policy/combat/melee_actions.lua`,
  `policy/character/senses.lua`, ranged/beam defense, cloud exposure,
  save validation, and their schemas/systems: consume shared status.
- `internal/script/testdata/lua/tests/monster_support_*_test.lua`:
  production imports and common harness. `internal/game` gets whole-turn
  and save tests only where the Lua harness cannot prove integration.
- `docs/port-inventory.md` and `docs/ecs-architecture-roadmap.md`:
  exact playable coverage and remaining dependencies.

## Task 1: Pin the source contract and live spell coverage

- [ ] Add a Lua coverage test listing exactly the 13 spell IDs through
  `ids.spells`, asserting each committed-book effect has `plan` and
  `resolve`. Observe the missing-module failures before writing effects.
- [ ] Add source-backed fixture cases for eligibility: active enchant,
  friendly no-foe, half-HP heal, adjacent wood or Mangrove, Sprint already
  active, Injury Mirror recast, Still Winds already level active, and
  Brilliance without an eligible ally. Distinguish source `bad` from
  `impossible` where ordinary AI filters both but forced casts may differ.
- [ ] Trace source RNG, duration, and action timing into a compact comment
  near each production calculation. Do not put C++ provenance fields in
  content records or add regeneration tools.

## Task 2: Consolidate persisted monster support state

- [ ] Add failing `_test.lua` cases that grant Haste or Might by both a
  spell and Chaos, advance time, dispel, and restore; assert the same speed
  and damage projections. Add tests for Invisibility using its existing
  `magic.monster_enchant` owner.
- [ ] Add a generic boon component and policy with named apply, active,
  projection, and tick methods. Move Chaos Haste and Might writes and
  consumers into it in one pass. Retain Chaos-specific agility and
  shifter state in the Chaos owner, removing its duplicate Haste/Might
  fields and code. Update schema/save versions deliberately.
- [ ] Wire Haste into `policy/monster_energy.lua`, Might into both melee
  damage paths, and Invisibility into visibility/targeting and expiry.
  Use the source duration modifier and avoid altering base `core.actor`
  speed. Preserve status through travel, death, and save/restore.

## Task 3: Healing, movement, and divine protection

- [ ] Add failing Lua tests for Minor Healing's `3 + 2d(spell_hd / 2)`, Major
  Healing's source average roll, and Woodweal's tree/Mangrove eligibility
  and `35 + random2(spell_hd * 3)` heal. Check max-HP clamping and exact
  named-stream draw counts. Build one healing owner and three focused
  spell modules that use the existing health component.
- [ ] Add failing tests for Sprint movement-only energy reduction,
  Berserker Rage restrictions and fatigue, and Trog's Hand's shared
  regeneration/strong-will duration. Implement focused modules and saved
  status/expiry consumers. Reuse existing frenzy and regeneration rules;
  change their owner if needed rather than adding a second behavior path.
- [ ] Check the real monster turn path selects a spell only when source
  eligibility permits it, records the correct book slot, spends the cast,
  and leaves ordinary attack and move timing intact.

## Task 4: Defenses and level/ally auras

- [ ] Add failing Lua tests for Repel Missiles in incoming player and
  monster missile paths, Injury Mirror's duration/recast and one-way
  reflected damage, and dispel/expiry. Implement saved protection state
  and connect both contact consumers. Include the existing beam/bolt
  repulsion distinction where source uses different accuracy handling.
- [ ] Add failing tests for Still Winds eligibility, deletion of existing
  level clouds, and level-wide suppression of later placements, including
  two casters, caster death, expiry, travel, and restore. Derive whether a
  level is suppressed from active caster state; never resurrect cleared
  clouds when the aura ends.
- [ ] Add failing tests for Brilliance Aura eligibility, allied caster
  spell-power or cast-chance projection, radius/line-of-sight, and expiry.
  Implement the aura owner and integrate it in selection and resolution;
  avoid a decorative status that has no gameplay consumer.

## Task 5: Integration, review, and one category commit

- [ ] Add real-game book-caster tests for one self buff, one heal, and one
  aura/protection spell. Verify selected slot, cast timing, visible result,
  save/restore status, and continued RNG equality after another turn.
  Add a sparse overlay that replaces one effect module and uses the same
  discovery and coverage path.
- [ ] Run `go test ./internal/script -run TestLuaRules -count=1`, focused
  `internal/game` tests, `go build ./...`, `go vet ./...`,
  `sh scripts/check-go-style.sh`, and `git diff --check`. Attempt the full
  suite once at the category boundary and report a timeout honestly.
- [ ] Review all 13 effects against the pinned source, especially status
  consumption and AI usefulness. Update coverage docs, commit the whole
  self-support family once, and fast-forward local `main` after successful
  integrated checks.

## Review focus

1. A status is not complete unless movement, combat, visibility, or aura
   policy actually consumes it and expiry removes it.
2. A rejected plan neither spends the cast nor consumes effect RNG.
3. Stationary and stasis monsters do not gain an invalid Haste or Might.
4. A mirror reflection cannot recursively reflect reflected damage.
5. Saved timers, cooldowns, clouds, and RNG produce the same next turn.
