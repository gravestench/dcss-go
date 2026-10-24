# Unique Pacification Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL:
> superpowers:executing-plans. Complete this monster-effects category
> and commit it once.

**Goal:** Port every source-specific pacification consequence for Pikel,
Kirke, the elven twins, and Vault Warden's terrain seals.

**Architecture:** The pacification owner calls existing Pikel and Kirke
owners; a small twin lookup and shared conversion operation handle Dowan
and Duvessa. The temporary-terrain owner releases markers for any
pacified or killed source.

**Tech Stack:** Lua rules, Akara ECS, dense Go grid, Go save.

**Spec:** `docs/superpowers/specs/2026-10-24-unique-pacification-effects-design.md`

## Global constraints

- Work on the user-authorized Go `main` branch.
- One commit for this contiguous category; push `origin/main`.
- No inline Lua in Go or god-specific Go dispatch.
- Explain how and why in every Lua function; <=120 columns.
- Tests import production IDs and use production component schemas.

## Review focus

- A Pikel band member disappears on pacification, leaving smoke.
- Kirke's marked hogs restore both original species and neutral side.
- A pacified twin converts its living counterpart once without extra RNG.
- A polymorphed twin still finds its counterpart by original class.
- A Warden seal disappears immediately, while unrelated terrain stays.

### Task 1: Source-owned terrain cleanup

**Files:** `policy/world/temporary_terrain.lua`,
`systems/world_temporary_terrain.lua`, `systems/actor_death.lua`,
`policy/religion/elyvilon/pacification.lua`, matching `_test.lua`.

**Interface:** `temporary.release_source(ctx, actor)` restores and
deletes the actor's temporary terrain markers. The ordinary timer uses
the same `temporary.restore(ctx, marker, state)` operation.

- [x] Write and run failing seal-release and unrelated-marker tests.
- [x] Implement the shared terrain owner and death/pacification calls.
- [x] Run the focused Lua tests.

### Task 2: Pikel and Kirke

**Files:** `policy/religion/elyvilon/pacification.lua`,
`policy/combat/monster_tactical/pikel.lua`,
`policy/combat/monster_tactical/porkalator.lua`, matching `_test.lua`.

- [x] Write and run failing marked-band and hog-restoration tests.
- [x] Invoke the existing owners at pacification without death effects.
- [x] Run the focused Lua tests.

### Task 3: Elven twins and integration

**Files:** `policy/monsters/elven_twins.lua`,
`policy/religion/elyvilon/pacification.lua`, Go game test,
`docs/port-inventory.md`, `docs/modding.md`.

- [x] Write and run failing twin-conversion and save/restore tests.
- [x] Add original-class lookup and once-only partner conversion.
- [x] Run focused Lua and game tests, build, format, and diff checks.
- [x] Review, commit the category, and push `main`.
