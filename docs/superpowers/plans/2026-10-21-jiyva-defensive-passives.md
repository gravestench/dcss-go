# Jiyva Defensive Passives Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans natively. The
> requested integration unit is the whole defensive-passive category: one
> commit after the focused owner and integrated tests pass.

**Goal:** Port Jiyva's zero-, one-, and two-star defensive passives.

**Architecture:** Lua queries the saved worship state at each use, then
the existing regeneration and resistance owners consume those queries.
A Lua terrain-hazard owner runs at actor action timing for all actors.

**Tech Stack:** Go host, Akara ECS, embedded Lua, source-format DES, Go
save/restore.

**Spec:** `docs/superpowers/specs/2026-10-21-jiyva-defensive-passives-design.md`

## Global constraints

- Keep source-facing policy in Lua; no Jiyva or slimy-wall switch in Go.
- Use the existing saved worship and grid state. Add no duplicate rank flag.
- Use named constants, readable functions, and why/how comments throughout.
- Make one contiguous category commit and push `main` after verification.

## Review focus

- A penitent or former Jiyva worshipper loses each benefit immediately.
- Natural-regeneration blocks suppress only the natural HP part while
  Jiyva's bonus remains.
- An acid-immune actor or slime-genus monster takes no wall damage.
- A wall may hurt a player or monster only once per completed action.
- Save/restore must preserve changed HP without rerolling wall exposure.

---

### Task 1: Rank and recovery

**Files:** `policy/religion/jiyva/defenses.lua`,
`policy/character/regeneration.lua`,
`systems/player_status.lua`, and
`tests/religion_jiyva_defenses_test.lua`.

**Interfaces:** `defenses.active(ctx, player, rank)` reads saved worship;
`defenses.hp_bonus` and `defenses.mp_bonus` return source integer rates.

- [x] Test each threshold, penance, abandonment, and natural-regeneration
      block with production schemas.
- [x] Add the defensive owner. Make the status system keep the god's HP
      bonus when the natural HP gate is closed, without admitting the
      ordinary natural rate through that gate.
- [x] Run the focused Lua case.

### Task 2: Acid and corrosion

**Files:** `policy/magic/damage.lua`,
`policy/combat/player_corrosion.lua`, and the same Lua test.

**Interfaces:** Player acid resistance gains one rank-two level through
the existing resistance calculation; corrosion keeps its current rCorr
chance.

- [x] Test acid reduction and prevention with rank, penance, and existing
      equipment resistance.
- [x] Integrate the Jiyva query without duplicating the corrosion rule.
- [x] Run the focused Lua case.

### Task 3: Slimy-wall exposure

**Files:** `policy/world/slime_walls.lua`,
`systems/world_slime_wall_damage.lua`, and the same Lua test.

**Interfaces:** `slime_walls.expose(ctx, actor, elapsed_aut)` applies one
source action's adjacent-wall acid effect to player or monster.

- [x] Test eight-neighbor count, source dice, resistance, slime genus,
      Jiyva immunity, and one exposure per action.
- [x] Implement the policy and actor-time system using existing health
      owners and the saved terrain grid.
- [x] Run the focused Lua and production-level Go integration cases.

### Task 4: Documentation and category integration

**Files:** `docs/modding.md`, `docs/port-inventory.md`,
`internal/game/religion_jiyva_defenses_test.go`.

- [x] Document rank queries, modded slime immunity, and slimy-wall rules.
- [x] Run focused tests, all-package build, changed-file style checks,
      and `git diff --check`.
- [ ] Commit the category once and push `main`.
