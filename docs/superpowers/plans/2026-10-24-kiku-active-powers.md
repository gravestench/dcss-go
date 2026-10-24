# Kikubaaqudgha Active Powers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make both ordinary Kiku active powers faithful and usable.

**Architecture:** Lua ability policies own the source costs and invocation.
A separate Lua wretch policy owns local population choice and creation, while
an ECS component and system own lifetime. Existing death and Torment owners
apply the effects shared with other game rules.

**Tech Stack:** Go runtime, embedded Lua mod, Akara ECS.

**Spec:** `docs/superpowers/specs/2026-10-24-kiku-active-powers-design.md`

## Global Constraints

- Production rules stay in Lua files; no Lua source literals in Go.
- IDs live in shared modules and are imported at use sites.
- Each Lua function explains why and how; systems include a theory of operation.
- Prefer 80-character lines and keep every line at or below 120 characters.
- Commit this contiguous category once on `main` and push after verification.

## Review Focus

- No open cell: still consume successful cost and show the no-space message.
- A killed wretch: leaves a corpse and grants no XP.
- Expiry after save/restore: dies through death processing and leaves a corpse.
- Branch populations with no corpse bodies: use a valid fallback without a crash.
- Torment resistance: invocation source applies Kiku's partial self shield.

---

### Task 1: Ability menu and Torment

**Files:** `internal/modfs/builtin/ids/abilities.lua`,
`internal/modfs/builtin/policy/abilities/kikubaaqudgha/torment.lua`,
`internal/script/testdata/lua/tests/religion_kiku_active_powers_test.lua`.

**Interfaces:** Register `KIKU_TORMENT` with rank five, MP four, piety eight,
failure 60/5/20; invoke `area.apply(ctx, player, channel, nil,
torment_sources.KIKU_INVOKED)`.

- [x] Add Lua tests for rank, MP, cost tuple, and Torment source routing.
- [x] Add ability ID and policy with documented functions.
- [x] Run focused Lua rules and game bridge tests successfully.

### Task 2: Wretch selection and lifecycle

**Files:** `internal/modfs/builtin/policy/abilities/kikubaaqudgha/unearth_wretches.lua`,
`internal/modfs/builtin/policy/religion/kikubaaqudgha/wretches.lua`,
`internal/modfs/builtin/schemas/religion_kiku_wretch.lua`,
`internal/modfs/builtin/systems/religion_kiku_wretch.lua`,
`internal/modfs/builtin/constants/component.lua`,
`internal/modfs/builtin/constants/late_zombie_branches.lua`, plus death and
save owners. Player melee's contact-report name collision must be fixed to
exercise a player kill of the new actor.

**Interfaces:** `wretches.invoke(ctx, player)` picks from effective branch
population, places actors, and marks each with a saved expiry component.
`wretches.tick(ctx, entity, elapsed_aut)` makes surviving actors die via
ordinary death processing. Death policy reads the marker for guaranteed
corpse/no XP; regeneration skips it.

- [x] Add Lua and game tests for count, fallback, no-space cost, placement,
  death, guaranteed corpse, no XP, and timer behavior.
- [x] Implement actor component, branch selection, placement, and timer system.
- [x] Connect death, regeneration, and restore validation to the marker.
- [x] Re-run the focused tests and observe success.

### Task 3: Integration and delivery

**Files:** Go game integration test, README/modding guide if the new component
needs documentation, and this plan's checkboxes.

- [x] Verify both powers through the live command bridge and restore wretches.
- [x] Run final focused Go and Lua tests, build, and changed-file style checks.
- [x] Review the whole category for source fidelity and mod extension behavior.
- [ ] Commit once and push `main`.
