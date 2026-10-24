# Launcher Weapon Brands Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every source-legal launcher brand playable for player and
monster ranged attacks, including passive effects and reflection.

**Architecture:** A Lua launcher owner validates the source legal set.
After contact, player and monster ranged actions call the existing
monster-target and player-target weapon-brand owners. Existing Akara
status, resistance, delay, defense, and projectile-path owners retain
their rules.

**Tech Stack:** Embedded Lua policies and `_test.lua` rules, Akara ECS,
Go game integration tests.

**Spec:** `docs/superpowers/specs/2026-10-24-launcher-weapon-brands-design.md`

## Global Constraints

- No inline Lua in Go; imported content remains committed Lua.
- Name shared brand IDs through `constants.weapon_brands`.
- Comment every new Lua function with its rationale and source behavior.
- Keep handwritten lines within 120 columns and prefer 80.
- Commit the full launcher-brand category once, then push `origin main`.

## Review Focus

- A melee-only or unknown launcher brand fails before spending a turn.
- Physical branded ammunition and its six launcher conflicts belong to
  the later physical-ammunition slice.
- Electrocution and Venom honor resistance; Holy Wrath honors holiness.
- Speed changes delay, Protection refreshes a saved aura after a hit,
  and Penetration changes projectile contact without bonus damage.
- Reflection reuses the source brand and credits the actual attacker.

---

### Task 1: Source legal brands and shot validation

**Files:** Modify `policy/combat/launcher_brands.lua`,
`policy/combat/monster_projectiles/sling_bullet.lua`,
`policy/combat/monster_projectiles/launched.lua`,
`policy/combat/player_projectiles.lua`, and
`policy/combat/ranged_actions.lua`. Extend
`internal/script/testdata/lua/tests/launcher_brands_test.lua` and
`monster_launcher_projectiles_test.lua`.

**Interface:** `launcher_brands.check(id)` rejects brands outside the source
ranged legal set.

- [x] Add tests for every legal brand and forbidden melee brands before
  a turn or RNG draw.
- [x] Implement one named legality table.
- [x] Replace the sling-only allowlist and validate both player and monster
  launchers before contact; run focused rules.

### Task 2: All active brand effects

**Files:** Modify `policy/combat/player_projectiles.lua` and
`policy/combat/ranged_actions.lua` to call the existing
`policy/combat/monster_target_brands.lua` and
`policy/combat/brands.lua` owners after base damage. Correct
player-facing Holy Wrath, Electrocution, and Venom resistance. Extend
`launcher_brands_test.lua`, `monster_launcher_projectiles_test.lua`, and
`ranged_reflection_test.lua`.

- [x] Cover source-dice and target gates in focused brand rules, then add
  real fired-shot Acid checks for player and monster paths.
- [x] Route active brands through the existing health, poison, corrosion,
  and resistance owners; keep damage and status timing after contact.
- [x] Check returned shots and Chaos against source.

### Task 3: Passive brand routing

**Files:** Reuse the existing Speed and monster Protection equipment owners.
Modify the player defense and timed status owners, projectile actions, and
monster ranged contact where needed. Extend focused projectile and defense
rules.

- [x] Prove Speed changes launcher delay and Protection grants a timed,
  saved +7 AC aura only after a qualifying player hit.
- [x] Prove Penetration bypasses shields and reaches multiple legal cells;
  route its brand into the existing trajectory and contact owners.
- [x] Exercise player, monster, and reflected shot paths.

### Task 4: Integrated category verification

**Files:** Add a branded launcher save/restore game case and update
`docs/port-inventory.md`.

- [x] Run focused Lua rules and game integration, `go build ./...`, `gofmt`,
  `sh scripts/check-go-style.sh`, and `git diff --check` for the category.
  The style script reports existing repository findings; it reports none
  in the changed Go files.
- [x] Review source roll order, attack ownership, unsupported adapters, and
  comment clarity. Resolve material findings.
- [x] Commit the whole category and push `origin main`.
