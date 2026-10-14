# Monster Action Energy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task by task.

**Goal:** Replace approximate monster deadlines with the pinned DCSS action-energy turn loop for the seven live animals.

**Architecture:** Player and monsters own distinct timing components in Akara. Pure monster rules calculate energy gains and action costs; a game coordinator grants energy, chooses ready actors, runs ordered systems, and spends their catalog costs. Version-12 saves persist only the new authoritative state.

**Tech Stack:** Go, Akara ECS, committed DCSS monster catalog, named SplitMix64 streams.

**Spec:** `docs/superpowers/specs/2026-10-14-monster-action-energy-design.md`

## Global Constraints

- Work from local Go `main` in the existing isolated worktree.
- No duplicate old/new timing paths or save compatibility layer.
- Use one coherent timing-category commit after tests and review.
- Keep Go lines at or below 120 columns, prefer 80, and avoid cuddled code.
- Do not read C++ source in normal Go builds or gameplay.

## Review Focus

- A 9-aut attack must not grant a rat a turn before it reaches 80 energy.
- A 12-aut attack gives a rat one action, not two deadline-driven actions.
- An inactive floor keeps its stored energy across travel and restore.
- A pending stat prompt grants no monster energy until the choice resumes.
- Invalid or missing timing components in a version-12 save are rejected.

---

### Task 1: Pure monster energy rules

**Files:** Create `internal/monster/energy.go`, `internal/monster/energy_test.go`.

**Interfaces:** `GainActionEnergy(roller Roller, speed, playerAut int) (int, error)` returns one source-rounded grant. `ActionEnergyCost(usage content.MonsterEnergy, intent ecs.IntentKind) (int, error)` returns move, attack, or no-move cost for supported monster intents. `ActionEnergyThreshold` is 80 and `InitialActionEnergy` is 70.

- [ ] Write tests for exact and fractional gain, no draw on exact division, and invalid inputs.
- [ ] Run focused tests and confirm the new tests fail.
- [ ] Implement source rounding using the `monster_energy` stream and catalog costs.
- [ ] Run focused tests and confirm they pass.

### Task 2: Replace the live scheduling path

**Files:** Modify `internal/ecs/components.go`, `stores.go`; `internal/game/turn.go`, `commands.go`, `game.go`, `scenario.go`, `ordinary_animal.go`, `level_activation.go`, `advancement.go`; update affected game tests.

**Interfaces:** `ecs.PlayerTurn{NextAut int64}` and `ecs.MonsterEnergy{Points int}` are authoritative. `TurnScheduler.Grant(levelID int, elapsed Aut) error`, `NextReady(levelID int) (akara.Entity, bool)`, and `Spend(entity akara.Entity, intent ecs.IntentKind) error` replace deadline selection. `runAction` records the final intent kind before removing transient `Intent`.

- [ ] Add failing tests for rat/worm/jackal cadence, action order, long and hasted player actions, and pending stat resumption.
- [ ] Run focused tests and confirm the intended failures.
- [ ] Replace monster deadlines and the old scheduler. Grant energy once, select highest energy until none is ready, and spend actual intent cost after each action.
- [ ] Run focused game tests, update assertions that encoded the old timing model, and resolve failures without compatibility paths.

### Task 3: Save and restore the new timing state

**Files:** Modify `internal/save/snapshot.go`; `internal/game/save.go`, `save_restore_components.go`, `save_restore_rules.go`, `save_restore_validation.go`; update save and active-floor tests.

**Interfaces:** Version 12 has `player_turn` and `monster_energy` entity fields. The player has only the former; each monster has only the latter. `Actor.NextAut` is removed.

- [ ] Add failing tests for roundtrip energy/RNG, malformed energy, absent role components, and frozen off-floor energy.
- [ ] Run focused tests and confirm the intended failures.
- [ ] Write and validate version-12 timing components; remove deadline rebasing and old save validation.
- [ ] Run focused tests and confirm deterministic continuation.

### Task 4: Integration and documentation

**Files:** Modify `docs/port-inventory.md`, `docs/ecs-architecture-roadmap.md` and remaining timing assertions.

- [ ] Run full `go test ./...`, `go vet ./...`, `go build ./...`, `sh scripts/check-go-style.sh`, and `git diff --check` once after the category.
- [ ] Review source behavior and diff, obtain read-only code review, and fix material findings.
- [ ] Commit one timing-category commit and fast-forward into local Go `main` as previously chosen.
- [ ] Repeat full tests and style check on merged `main`.
