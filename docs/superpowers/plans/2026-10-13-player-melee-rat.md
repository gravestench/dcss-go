# Human Fighter Melee Against Rat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the fixed player bump damage with the pinned ordinary Human/Fighter primary melee rules against the fixed rat.

**Architecture:** `combat` resolves a value-only attack with a scripted or named-stream roller. `game` projects ECS state and committed catalog fields into that input, applies HP/death effects, and owns messages. `character` exposes scaled stored starting skills so the game need not duplicate skill-point arithmetic.

**Tech Stack:** Go, Akara ECS, committed item and monster catalogs, named SplitMix64 melee stream, JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-13-player-melee-rat-design.md`

## Global Constraints

- Only ordinary, awake Human/Fighter primary melee against the fixed `MONS_RAT` is supported.
- Keep current 10-aut action cost; weapon-specific attack delay is a separate scheduler slice.
- Normal Go build/test/play reads committed catalogs, never the C++ checkout.
- Preserve Go save version 6 and named RNG continuation; no new mutable combat state is required.
- C++ source revision is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

## Review Focus

- An unarmed start has no weapon entity: build the attack input from its unarmed skill and normal-form base damage.
- A different starting weapon changes hit, damage, and strength/dexterity choice through catalog properties and stored skill points.
- A miss or AC-absorbed hit spends one bump turn but does not reduce rat HP; a lethal hit removes occupancy.
- The 5% automatic hit/miss and no-shield contest consume draws in C++ order, including when the accuracy comparison would already decide the hit.
- A malformed equipped weapon or unsupported actor is rejected on restore and before a bump can change game state.

---

### Task 1: Stored skill scaling and pure player attack

**Files:** Modify `internal/character/start_profile.go` and tests; create `internal/combat/player.go` and `player_test.go`.

**Interfaces:** Export `character.ScaledSkill(skill Skill, scale int) int` from the existing skill-point calculation, preserving `startingHP` output. Add `combat.PlayerAttackInput` with `Strength`, `Dexterity`, `FightingSkill100`, `WeaponSkill100`, `UnarmedSkill256`, `WeaponSkillID`, `WeaponDamage`, `WeaponHit`, `WeaponPlus`, `Unarmed`, `DefenderEV`, `DefenderAC`. Add `combat.PlayerMelee(Roller, PlayerAttackInput) (Outcome, error)` using `Miss` and `Hit` plus post-AC damage.

- [ ] Write tests for scaled level-3 Fighting and level-2 weapon skill at scales 100 and 256, with existing HP unchanged; write scripted pure attack tests for weapon miss, automatic miss/hit, 0-damage AC hit, positive hit, and unarmed base damage. Assert every RNG bound/order, including the rat no-shield bypass draw.
- [ ] Run `GOCACHE=/private/tmp/dcrawl-go-player-melee-cache go test ./internal/character ./internal/combat` and observe the missing API failures.
- [ ] Export the existing scaling helper and implement ordinary accuracy and damage from `attack.cc:160-310,1111-1235`, `fight.cc:1270-1310`, `actor.cc:115-119,336-382`, `random.cc:235-253,313-321`. Use the normal-form unarmed base 3, weapon damage/hit from the catalog, skill values at scales 100/256, fixed rat EV/AC inputs, and a no-shield contest draw before miss resolution.
- [ ] Run focused tests, then commit this pure-rule category.

### Task 2: ECS projection, HP/events, and load validation

**Files:** Modify `internal/game/combat.go`, `save.go`, focused tests, and `docs/port-inventory.md`; delete obsolete `internal/rules/melee.go` and its test only after all consumers are removed.

**Interfaces:** `game` assembles `combat.PlayerAttackInput` from live player attributes/skills, equipped weapon (or no weapon for `WPN_UNARMED`), and the rat catalog row; `combatSystem` calls `combat.PlayerMelee`, applies damage, and leaves death cleanup to `deathSystem`.

- [ ] Write game tests for every current Fighter weapon, unarmed with no weapon entity, source property changes, miss/absorption/death, 10-aut bump, and save/RNG continuation. Write restore and live-bump rejection tests for a mismatched or malformed equipped weapon, checking live state is unchanged.
- [ ] Run `GOCACHE=/private/tmp/dcrawl-go-player-melee-cache go test ./internal/game` and observe failure.
- [ ] Replace the fixture branch in `combatSystem`, prevalidate the player attack input before a bump action, and validate it after restore completes component loading. Use current catalog monster EV/AC rather than literal damage fixtures. Remove dead fixture rule code.
- [ ] Update port inventory with exact supported player path and deferred timing/auxiliary mechanics. Run focused tests and commit this game integration category.

### Task 3: Integrated verification and review

**Files:** Any bug-fix test/source revealed by integrated verification.

- [ ] Run `go test ./...`, `go vet ./...`, and `go build ./...` with `GOCACHE=/private/tmp/dcrawl-go-player-melee-cache`.
- [ ] Smoke-test an unarmed and weapon start at 79×24, bump the rat, and save/load a run.
- [ ] Request one fresh read-only whole-branch review; fix Critical/Important findings with failing tests followed by a green full suite. Record deferred minors and rulings. Then fast-forward merge into local Go `main`.
