# Fedhas Projectile Protection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Fedhas's shoot-through passive protect aligned plants across live rays and cloud effects.

**Architecture:** A focused Lua predicate reads existing worship, allegiance, and monster catalog state. Existing attack owners call that predicate before contact rolls or cloud effects. No Go content dispatch is added.

**Tech Stack:** Embedded Lua rules, Akara ECS state, Go integration tests.

**Spec:** `docs/superpowers/specs/2026-10-24-fedhas-projectile-protection-design.md`

## Global Constraints

- Keep production Lua in files under `internal/modfs/builtin`.
- Comment each new Lua function with why and how, not only what.
- Prefer 80-character lines and never exceed 120 characters.
- Commit this category once, after the integrated paths are verified.

## Review Focus

- A hostile Oklob remains attackable even while a friendly plant is bypassed.
- A plant under the shooting player is not inserted into the outgoing ray.
- A nonpenetrating projectile continues past a protected plant.
- Penance immediately removes protection without rewriting monster state.
- A player-side cloud keeps protection after its source actor vanishes.

---

### Task 1: Source-backed protection decision

**Files:** Create `policy/religion/fedhas/protection.lua`; add a Lua `_test.lua`.

**Interfaces:** `protection.ignores(ctx, attacker, target)` returns a boolean.

- [ ] Write tests for allied plant, hostile plant, nonplant, penance, and allied attacker.
- [ ] Run the focused Lua test and observe the missing behavior fail.
- [ ] Implement the catalog and live-allegiance decision.
- [ ] Run the focused Lua test green.

### Task 2: Ray and area resolution

**Files:** Modify player projectiles, player zap projectile, monster beam resolution/contact, and blast owners; add Lua and game integration tests.

**Interfaces:** Every relevant contact resolver calls `protection.ignores` before rolling an effect. A skipped contact lets the ray continue.

- [ ] Write tests for a player shot through an allied plant and hostile contact, plus a beam/area contact.
- [ ] Run focused tests red.
- [ ] Implement the ray and area call sites without duplicating the decision.
- [ ] Run focused tests green.

### Task 3: Cloud placement and exposure

**Files:** Modify `policy/clouds/placement.lua` and `policy/clouds/exposure.lua`; add Lua tests.

**Interfaces:** The placement owner refuses a harmful cloud atop a protected plant unless it is already immune to that kind; exposure reads the saved player-side kill category even after its source actor vanishes.

- [ ] Write tests for protected placement/exposure and saved attribution after source death.
- [ ] Run the focused Lua test red.
- [ ] Implement both call sites.
- [ ] Run focused tests green.

### Task 4: Documentation and verification

**Files:** Update `docs/port-inventory.md` and `docs/modding.md`.

- [ ] Explain the policy and modder-facing catalog traits.
- [ ] Run focused Lua and Go tests, build `cmd/crawl`, check formatting and style.
- [ ] Review the complete diff, commit, and push `main` per the user's standing request.
