# Trog Active Abilities Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task by task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all three source Trog powers playable and saved.

**Architecture:** Three registered Lua abilities own their source
decisions. A focused Lua Hand component owns its timer; shared player
rage, resistance, regeneration, and monster summon owners carry the
generic effects.

**Tech Stack:** Go, Akara ECS, embedded Lua, Bubble Tea terminal client.

**Spec:** `docs/superpowers/specs/2026-10-24-trog-active-abilities-design.md`

## Global Constraints

- Work on Go `main`, one contiguous category commit, and push to origin.
- Production rules and content live in real embedded Lua files.
- Every Lua function explains why and how; keep lines at most 120 columns.
- Import stable IDs where used and keep table declarations readable.
- Reuse ECS state and generic owners without a second Trog state model.

## Review Focus

- A rage-ineligible player sees no Berserk action and loses no time.
- An ability failure spends its turn but neither piety nor MP.
- A Hand timer at the cap remains valid after refresh and restore.
- A Brother whose landing is blocked still costs piety after success.
- Departure or penance removes temporary Trog gifts, not permanent ones.

---

### Task 1: Register all three powers and share their costs

**Files:** `ids/abilities.lua`, `policy/abilities/trog/*.lua`, and
`internal/script/testdata/lua/tests/religion_trog_abilities_test.lua`.

- [ ] Write production-schema tests for rank, penance, source failure
  arithmetic, successful piety costs, and no MP or Invocations use.
- [ ] Run the new tests red; register the three abilities using the
  existing `god_costs` and ability registry interfaces.
- [ ] Make Berserk call the shared `rage.can_begin` and `rage.begin`
  owner. Test both legal rage and each existing refusal gate.

### Task 2: Trog's Hand

**Files:** `schemas/religion_trog_hand.lua`,
`policy/religion/trog/hand.lua`, `systems/religion_trog_hand.lua`,
`policy/character/regeneration.lua`,
`policy/combat/player_resistance.lua`, and the Trog ability module.

- [ ] Test duration formula, cap, refresh, messages, expiry,
  regeneration through inhibition, and two willpower pips.
- [ ] Run red; add the saved component, focused tick owner, and shared
  consumer reads. Keep the existing player status schema unchanged.
- [ ] Test save/restore and cleanup on conversion and penance.

### Task 3: Brothers in Arms

**Files:** `policy/abilities/trog/brothers.lua`, the existing summon
and allegiance owners only where a generic operation is missing,
`internal/script/testdata/lua/tests/religion_trog_brothers_test.lua`,
and a focused Game restore test.

- [ ] Test jitter, source species bands and weights, friendly attitude,
  god source, immediate Berserk, expiry, and blocked placement.
- [ ] Run red; spawn one real ECS monster with an extended berserk and
  matching summon lifetime. Preserve normal monster gear and source.
- [ ] Test departure or penance dismisses only temporary Trog gifts.

### Task 4: Integrated verification

**Files:** `docs/modding.md` and `docs/port-inventory.md`.

- [ ] Verify ability menus, save continuation, focused Lua and Game
  tests, `go build ./...`, `git diff --check`, and 120-column limits.
- [ ] Explain the Trog ability and Hand component contracts for modders.
- [ ] Commit this complete category once and push `origin/main`.
