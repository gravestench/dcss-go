# Monster Equipment Resistance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task by task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make monster resistance reflect live, source-eligible equipment
across elemental damage, poison, and negative energy.

**Architecture:** `policy.combat.monster_resistance` owns monster-specific
aggregation. The existing damage policy keeps only the pure damage formula;
combat and spell callers pass live actor IDs for resistance decisions.

**Tech Stack:** Embedded Lua, ECS item/equipment components, `_test.lua`
production-policy tests, Go build.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-equipment-resistance-design.md`

## Global Constraints

- Keep every gameplay rule in Lua files; no inline Lua in Go.
- Import shared item, status, and resistance IDs at their use sites.
- Comment every new function with why and how; keep lines at most 120 columns.
- Test a coherent category, commit once directly to `main`, and push.

## Review Focus

- Gear has no effect below `MONUSE_STARTING_EQUIPMENT`.
- Body and shield flags and egos combine without counting artefacts twice.
- Intrinsic poison immunity survives equipment and temporary vulnerability.
- Poison from equipment is capped at one pip; intrinsic positive levels stay intact.
- Changing or removing a live ECS item immediately changes spell damage.
- Nonliving negative energy immunity survives a low-resistance artefact.

---

### Task 1: Shared live monster resistance

**Files:** Create `internal/modfs/builtin/policy/combat/monster_resistance.lua`;
modify shared constants as needed; create
`internal/script/testdata/lua/tests/monster_equipment_resistance_test.lua`.

**Interface:** `resistance.level(ctx, monster, definition, resistance_id)`
returns the source-adjusted integer resistance.

- [x] Write failing ECS item cases for intrinsic levels, armour flags/egos,
  jewellery, staves, artefacts, item-use eligibility, removal, poison
  cap, and nonliving immunity.
- [x] Run the one Lua test to confirm the missing owner fails.
- [x] Implement source-ordered aggregation and rerun the Lua test.

### Task 2: Route all actor-based consumers

**Files:** `policy/magic/damage.lua`, `policy/combat/monster_poison.lua`,
`policy/combat/monster_drain.lua`, and the direct elemental spell callers
under `policy/magic/effects` and `policy/combat/summon_melee.lua`.

**Interface:** All actor-aware callers use `resistance.level` or
`damage.monster_elemental(ctx, monster, raw, resistance_id)`.

- [x] Write failing consumer tests for a shielded monster taking less fire,
  a poison-resistant shield preventing poison, and cold spell damage
  changing when armour is removed.
- [x] Replace duplicate resistance scans and definition-only damage calls
  that have an ECS target; preserve direct pure scaling where no actor exists.
- [x] Run focused poison, drain, elemental, and spell tests.

### Task 3: Category gate

**Files:** `docs/port-inventory.md` and this plan.

- [x] Run focused Lua tests, `go build ./...`, the Go style check, Lua
  line-width check, and `git diff --check`. No Go files changed, so
  `gofmt` was unnecessary. The style script still reports 229 existing
  Go findings outside this category.
- [x] Review source parity and the complete diff once.
- [x] Commit the category once, push `origin main`, and verify clean HEAD.
