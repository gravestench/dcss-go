# Human Fighter Attack Timing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make primary Human/Fighter melee bumps use source-derived aut costs and schedule the rat accordingly.

**Architecture:** `combat` resolves timing from value inputs and a roller. `game` assembles timing inputs from live ECS skills and committed item properties, draws before hit/damage, and passes that cost through the existing action scheduler. Save schema stays at version 6.

**Tech Stack:** Go, Akara ECS, committed item catalog, named SplitMix64 melee stream.

**Spec:** `docs/superpowers/specs/2026-10-13-human-fighter-attack-timing-design.md`

## Global Constraints

- Only ordinary Human/Fighter primary melee against the fixed rat is supported.
- Other player actions and monster actions remain at 10 aut.
- Source revision is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`; ordinary Go builds do not read it.
- Keep save version 6; the named melee stream must continue deterministically.

## Review Focus

- Attack delay draws occur before accuracy and damage on the same named stream.
- The 10-aut assumption in `Step`, its result, and the scheduler all change together for bumps.
- Unarmed has no weapon entity and uses its separate 54-denominator rule.
- Shield penalty draws even when weapon skill reduction is exact; randomized rounding follows source integer order.
- Restored saves with malformed timing inputs fail before a live game is replaced or an action is spent.

---

### Task 1: Pure ordinary attack delay

**Files:** Create `internal/combat/delay.go`, `delay_test.go`.

**Interfaces:** `type AttackDelayInput struct { Unarmed bool; WeaponSkillID string; WeaponSpeed, WeaponSkill10, ShieldEV, ShieldsSkill10 int }`; `func PlayerAttackDelay(Roller, AttackDelayInput) (int, error)`.

- [ ] Write scripted tests for rapier at skill 2 and buckler Shields 3 producing 11 or 12 aut depending on the shield draw; unarmed producing 9/10/11 aut; every Fighter starter weapon's speed; and invalid inputs. Assert draw bounds and order.
- [ ] Run `GOCACHE=/private/tmp/dcrawl-go-attack-delay-cache go test ./internal/combat` and observe missing API failures.
- [ ] Implement the ordinary source path from `player-act.cc:246-331`, `fight.cc:912-956`, `player.cc:5649-5661`, `random.cc:313-321`; share the existing bounded `Roller` and skip RNG draws for exact divisions.
- [ ] Run focused tests and commit the pure timing category.

### Task 2: ECS projection and variable player scheduling

**Files:** Modify `internal/game/{commands,player_attack,save}.go`, focused tests, and `docs/port-inventory.md`.

**Interfaces:** `Game.playerAttackDelayInput()` projects stored skill at scale 10, weapon `Speed` and `SkillID`, and shield EV. `Game.Step` rolls `PlayerAttackDelay` only for a valid occupied melee bump and uses that cost for `runAction`, `StepResult.Spent`, and scheduler continuation.

- [ ] Write game tests for all six starting choices, non-10-aut bump, rat action count/order when attack is shorter or longer, and save/RNG continuation. Update old bump tests to assert source timing rather than fixed 10 aut. Write restore and bump rejection tests for missing or malformed timing inputs.
- [ ] Run `GOCACHE=/private/tmp/dcrawl-go-attack-delay-cache go test ./internal/game` and observe failures.
- [ ] Project the source inputs and roll timing before the world update; keep other actions at 10 aut. Validate restored timing inputs after ECS component loading. Update docs.
- [ ] Run focused tests and commit integration.

### Task 3: Verify and integrate

**Files:** Any bug-fix tests and source from integrated checks.

- [ ] Run `go test ./...`, `go vet ./...`, and `go build ./...` with the writable attack-delay cache.
- [ ] Smoke-test a 79×24 rapier or unarmed attack with non-10-aut time, then save and load.
- [ ] Obtain one read-only whole-branch review, fix Important/Critical findings with RED→GREEN and a green suite, and fast-forward merge into local Go `main`.
