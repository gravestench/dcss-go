# Chance-based Monster Artefacts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give all nine source chance-based monster artefact owners their named item or ordinary fallback.

**Architecture:** Lua gear handlers own each monster's choice and use one
shared chance/history helper. The existing factory and item generator own
physical items and saved claims. Shared monster equipment validation handles
magical staves and Gastronok's hat.

**Tech Stack:** Lua policy/content, Go test host, Akara ECS.

**Spec:** `docs/superpowers/specs/2026-10-24-chance-monster-artefacts-design.md`

## Global Constraints

- Keep gameplay choices in Lua files under the embedded mod; no inline Lua in Go.
- Use imported catalog IDs and source-backed definitions.
- Comment every new Lua function with its reason and operation.
- Keep lines at most 120 characters and split multi-field declarations.
- Commit this contiguous category to Go `main` and push it.

## Review Focus

- An already claimed Wyrmbane must remain ordinary on the second owner.
- Chance failure must not claim unique history.
- Forced fallback brands and plusses must survive the ordinary gear path.
- Arachne's staff must survive melee inspection and save validation.
- Gastronok's ordinary and named hats must occupy its body slot.
- Failed placement must leave both the gear stream and unique history untouched.

---

### Task 1: Pin the factory behavior

**Files:** `internal/script/testdata/lua/tests/monster_chance_artefacts_test.lua`; shared fixture if useful.

**Interfaces:** `factory.spawn(ctx, monster_id, level_id, x, y)` creates a
real actor. Carrier, artefact, equipment, and player history components
expose the outcome.

- [x] Write Lua tests for all nine success and miss cases, their claims,
      shared Wyrmbane status, staff/hat validators, and death drops.
- [x] Run the focused `TestLuaRules/monster_chance_artefacts_test.lua` test and confirm it fails before implementation.

### Task 2: Add source choices and equipment handling

**Files:** `internal/modfs/builtin/policy/population/gear.lua` and its
per-monster handlers; `internal/modfs/builtin/policy/population/factory.lua`;
`internal/modfs/builtin/policy/combat/equipment.lua`;
`internal/modfs/builtin/policy/combat/monster_armour.lua`;
`internal/modfs/builtin/policy/save/monster_inventory.lua`.

**Interfaces:** `gear.chance_unique(ctx, unique_id, odds)` draws before
checking `history.status`; handlers return a `primary` or `body` entry
with optional `plus`; factory preserves that plus on unique generation.

- [x] Implement shared chance/history and the nine readable monster handlers.
- [x] Admit magical staves through `staves.weapon` and Gastronok hats
      through `monster_armour.wears_body`.
- [x] Pass all chance and existing guaranteed gear Lua tests.

### Task 3: Verify and integrate the category

**Files:** `docs/port-inventory.md`.

- [x] Update the port inventory with covered chance grants and remaining gear work.
- [x] Run focused Lua and Go regression tests, `git diff --check`, and line-length checks.
- [x] Review the complete category, commit it to `main`, and push the commit.
