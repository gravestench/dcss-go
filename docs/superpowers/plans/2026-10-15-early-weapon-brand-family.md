# Early Weapon Brand Family Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve every positive-weight brand on the five generated early weapons through Lua with source-shaped effects.

**Architecture:** Lua effect modules own brand behavior and the scheduler reads equipped state through the generic ECS context. New persistent effects are Akara components. Go supplies only reusable entity, grid, and save operations.

**Tech Stack:** Go, Akara, gopher-lua, committed embedded Lua.

**Spec:** `docs/superpowers/specs/2026-10-15-early-weapon-brand-family-design.md`

## Global constraints

- No inline Lua in Go, brand ID switch in Go, or compatibility combat path.
- Preserve source roll order and deterministic save continuation.
- Keep Lua modules focused and lines at or below 120 characters.
- Keep the branch temporarily broken; make one integrated category commit.

## Review focus

- A legal generated brand must resolve or fail during content boot, never in the middle of combat.
- Zero-damage and lethal hits must apply only source-permitted effects.
- A saved drain or banishment must resume faithfully. Monster spectral is
  source-inert; a player spectral ally belongs to the player-attack slice.
- Speed brand must change monster melee time and leave thrown missiles at
  their ordinary cost. Current early slings cannot legally roll speed.
- An overlay of one effect module must change behavior and ruleset identity.

### Task 1: Identify and dispatch the generated family

**Files:** `internal/modfs/builtin/policy/combat/brands.lua`, new files under `policy/combat/brands/`, `policy/population/gear.lua`.

- [x] Add a catalog check that enumerates positive-weight brands of the five early weapon kinds.
- [x] Move existing brand effects into focused Lua modules and dispatch by brand ID.
- [x] Validate every generated brand at Lua boot without silently rerolling it.

### Task 2: Passive and resource brands

**Files:** `policy/monster_energy.lua`, `policy/combat/brands/*.lua`, `internal/game/turn.go`, whole-turn tests.

- [x] Implement speed timing in the Lua scheduler using the attacking entity.
- [x] Implement holy, vampiric, pain, drain, and antimagic rules with source rolls and ECS state.
- [x] Test damage, resistance, lethal hits, timing, and save continuation.

### Task 3: Spatial brands

**Files:** `policy/combat/brands/*.lua`, `policy/generation`, `systems`, Lua schemas, world tests.

- [x] Implement distortion damage, blink, and Abyss banishment as actual transitions.
- [x] Preserve source-inert monster spectral behavior in its own Lua module.
- [x] Test level occupancy, return travel, and deterministic continuation.

### Task 4: Integrated gate

**Files:** changed source and `docs/port-inventory.md`.

- [x] Exercise the generated brand family in complete attack flows, including an overlay.
- [x] Run `go test ./... -count=1`, `go vet ./...`, `go build ./...`, style, catalog, and diff checks.
- [x] Review the complete diff, fix findings, commit once, and fast-forward local `main`.
