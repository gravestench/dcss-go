# XP Evokers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all eight source XP evokers obtainable, usable, rechargeable, visible, and persistent in the Go/Lua game.

**Architecture:** A player Lua ECS component holds subtype debt. A registry maps item IDs to separate Lua effect modules. Go passes a generic evoke command and input state into Lua; Lua owns all effects and recharge rules.

**Tech Stack:** Go, embedded Lua, Akara ECS, Bubble Tea terminal, existing Lua test harness.

**Spec:** `docs/superpowers/specs/2026-10-24-xp-evokers-design.md`

## Global Constraints

* Keep all gameplay rules and effect registrations in actual Lua files under the embedded mod.
* Dynamic actors use ECS; terrain remains a level grid.
* Explain why and how in comments on every Lua function. Keep lines at or under 120 characters; prefer 80.
* Use named IDs, split multi-field declarations, and keep each effect in its own file.
* Per user instruction, make one coherent XP-evoker commit on `main` and push it after verification.

## Review Focus

* Two copies of one subtype must share debt; test by evoking one then inspecting both.
* Failed target selection must leave time and debt unchanged; test each targeted effect.
* A monster kill without a carried subtype must not recharge it; test inventory loss and reacquisition.
* Zero charges and silence must reject before action time; test in Lua and terminal flow.
* Save restore must reject forged debt keys and negative debt; test round trip and tampering.

---

### Task 1: Charge owner and XP clock

**Files:** Create `schemas/character_xp_evokers.lua`, `policy/inventory/evokers.lua`, and `internal/script/testdata/lua/tests/xp_evokers_test.lua`; modify `constants/component.lua`, `systems/actor_death.lua`, `policy/save/player.lua` or a focused save validator, and `internal/game/save_restore_components.go` only if the existing validation hook needs one.

**Interfaces:** `evokers.definition(kind_id)`, `evokers.charges(ctx, player, kind_id)`, `evokers.expend(ctx, player, kind_id)`, and `evokers.award_xp(ctx, player, xp)`; all debt stays on the player keyed by `ids.items` subtype IDs.

- [ ] Write Lua tests for eight source debt/max pairs, shared subtype charges, carried-only recharge, stochastic remainder, and invalid saved debt.
- [ ] Run `go test ./internal/script -run TestLuaRules/xp_evokers -count=1` and confirm the intended failures.
- [ ] Implement the schema and charge policy; hook credited kill XP and restore validation.
- [ ] Re-run focused tests and inspect source-level recharge bounds.

### Task 2: Generic evoke path and display

**Files:** Modify Go command/intent/input/presentation bridge, Lua `constants/command_kind.lua`, `constants/intent.lua`, `policy/input/*`, `policy/commands/entries_items.lua`, `policy/presentation/modals.lua`; create `systems/item_evoker.lua`. Add focused Go/Lua input tests.

**Interfaces:** `evokers.prepare(ctx, player, item_id, dx, dy)` returns a timed `EVOKE_ITEM` intent or a free refusal; `evokers.resolve(ctx, player, intent, aut)` dispatches by ID. Terminal `v` selects an evoker; `V` keeps wand selection.

- [ ] Write failing tests for menu selection, aim/cancel, spent turn, empty charges, and inventory charge labels.
- [ ] Add only generic Go routing and Lua command registration; keep effect policy in Lua.
- [ ] Run focused terminal, game, and Lua tests.

### Task 3: Aimed evokers

**Files:** Create one Lua effect file each for phial, lightning rod, and phantom mirror under `policy/inventory/evokers/`; add focused `*_test.lua` tests and use the saved Thunderbolt arc schema.

**Interfaces:** Each effect registers `{ prepare, resolve }` for its `ids.items` ID. `resolve` reports source outcome `success`, `abort`, or `fail` plus whether it spends a charge and how much practice it awards.

- [ ] Test target rejection, water/knockback, rod arc continuity, mirror clone/duration/drain, and turn/charge outcomes.
- [ ] Implement by composing current primal wave, thunderbolt, summon, and willpower helpers; add focused helpers only for source gaps.
- [ ] Run effect tests and source formula spot checks.

### Task 4: Immediate and automatic evokers

**Files:** Create separate Lua effect files for horn, box, tin, condenser vane, and Xom's chessboard, with one `*_test.lua` file per behavior group. Add Geryon's carried Horn through a monster gear handler; the existing death drop then yields it.

**Interfaces:** Same effect registration as Task 3; automatic effects choose from current eligible visible monsters and source RNG streams.

- [ ] Test all five effects, spawn/cell failure, no-target prompts, correct charge spending, and Horn obtainability.
- [ ] Implement source weighted tables and placement with named constants and no central case switch.
- [ ] Run focused tests and inspect sample floor and combat output.

### Task 5: Integration and verification

**Files:** Add Go save/restore and terminal integration tests; update modding guide with how to add an XP evoker effect and source semantics.

- [ ] Test duplicate subtype debt across save/restore, forged debt rejection, aimed cancellation, all eight visible charge counts, and an end-to-end Horn acquisition/use.
- [ ] Run focused Lua, game, and terminal suites, then `go test ./...`; resolve relevant failures.
- [ ] Inspect the diff for unreadable switches, oversized inline declarations, missing function comments, and line limits.
- [ ] Commit the coherent XP-evoker domain on `main` and push `origin main`.
