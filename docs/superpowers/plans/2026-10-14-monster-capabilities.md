# Monster Capability Dispatch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Resolve every currently playable monster ranged and spell action from Lua capabilities instead of monster-ID branches.

**Architecture:** Equipment and spellbook definitions provide capabilities. A Lua intent policy selects an eligible action; one Lua resolver per action family reads the item or spell effect module. Go remains a generic ECS/grid/scheduler host.

**Tech Stack:** Go, Akara ECS, embedded Lua, Bubble Tea/Lip Gloss terminal.

**Spec:** `docs/superpowers/specs/2026-10-14-monster-capabilities-design.md`

## Global constraints

- Keep all rules in `.lua` files, with no inline Lua in Go.
- Preserve pinned source behavior and named RNG order for current monsters.
- No compatibility adapter or second behavior path.
- Keep Lua and Go lines at most 120 characters and multi-field tables expanded.
- Commit this contiguous category once after integrated verification.

## Review focus

- A held adjacent monster must not acquire an invalid ranged or spell intent.
- A launcher shot and a thrown missile must report the same messages and effects as before.
- A poisoned dart must preserve its poison source across save/restore.
- An unsupported spellbook or item combination must fail explicitly.
- Modded equipment on an otherwise ordinary actor must work through the same path.

### Task 1: Select capabilities from catalog and equipment

**Files:** `policy/ai/ranged.lua`, `policy/ai/spell.lua`, `policy/combat/monster_spells/*.lua`.

- [x] Read the existing AI tests and pinned source references for selection odds and range.
- [x] Add a failing test using supported equipment on a different actor kind.
- [x] Replace actor-ID tests with item and spellbook eligibility, preserving RNG order.
- [x] Keep Freeze and Slug Dart targeting rules in their spell effect modules.

### Task 2: Resolve one ranged and one spell intent path

**Files:** `policy/combat/ranged_actions.lua`, `systems/attack_combat.lua`, `systems/attack_spell.lua`.

- [x] Replace goblin/kobold resolver branches with an equipment-derived action.
- [x] Replace endoplasm/dart-slug branches with spell effect dispatch.
- [x] Preserve physical, poison, brand, shield, and message outcomes.
- [x] Delete the superseded functions in the same edit.

### Task 3: Integrated category gate

**Files:** behavior tests and `docs/port-inventory.md`.

- [x] Run focused current-roster and new capability tests.
- [x] Run `go test ./... -count=1`, `go vet ./...`, `go build ./...`, style, catalog, and diff checks.
- [x] Review the whole branch and fix findings.
- [x] Make one category commit and fast-forward local Go `main`, preserving the user's untracked save.
