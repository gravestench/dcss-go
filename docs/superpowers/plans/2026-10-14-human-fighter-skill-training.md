# Human/Fighter Skill Training Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Keep this contiguous gameplay category in one final commit, per the user's standing instruction.

**Goal:** Earned XP trains the playable Human/Fighter's skills with source-shaped costs, practice weighting, menu controls, and save continuation.

**Architecture:** Pure `character` rules calculate thresholds and costs. Akara owns skill points and training state on the player. An ordered training system consumes practice and tenfold kill XP after death resolution, before character advancement; the terminal only submits no-time training choices and renders the view.

**Tech Stack:** Go, Akara ECS, Bubble Tea/Lip Gloss, committed content catalogs, Go JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-14-human-fighter-skill-training-design.md`

## Global constraints

- Keep the pinned source at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f` authoritative for arithmetic and event order.
- Keep all mutable player training state in Akara; do not add a second `Game` copy.
- Use a separate saved `skill` RNG stream, with deterministic continuation.
- Handwritten Go: 120 characters maximum, 80 preferred, multiline populated struct literals, and blank lines between distinct steps.
- One commit for the entire skill-training category. Run the broad test/vet/build/style checks at the category boundary.

## Review focus

- XP awarded by two deaths in one turn must enter the skill pool once each and spend before advancement.
- A zero-point skill cannot acquire an impossible level when newly practiced.
- Disabled training must retain unspent XP across save/restore until enabled.
- A skill reaching level 27 must stop spending without trapping the training loop.
- A malformed save must not claim more spent and unspent skill XP than ten times earned XP.

---

### Task 1: Source skill mathematics

**Files:** `internal/character/skill_training.go`, `internal/character/skill_training_test.go`

**Interfaces:** `HumanSkillPointsNeeded(level int) (int, error)`, `HumanSkillLevel(points int) (int, error)`, `SkillCostLevel(spentXP int) (int, error)`, and `SkillPointCost(level int) (int, error)`.

- [x] Add table tests for levels 0, 1, 2, 3, 9, 10, 18, 19, 26, and 27; cost transitions at 117 and the next source boundary; invalid inputs.
- [x] Run the focused test red, implement the source formulas and full 27-entry cost table, then run it green.
- [x] Reuse the point helper in starting-skill calculation without changing its 301/151 output.

### Task 2: Player-owned training state and save schema

**Files:** `internal/ecs/components.go`, `internal/ecs/stores.go`, `internal/game/scenario.go`, `internal/game/save.go`, `internal/game/save_restore_components.go`, `internal/game/save_restore_rules.go`, `internal/game/save_restore_validation.go`, `internal/game/view.go`, `internal/save/snapshot.go`, focused tests.

**Interfaces:** `ecs.SkillTraining` stores available/spent skill XP, cost level, auto/manual mode, per-skill training settings, and both 100-entry queues. Its store lives in `ecs.Stores`; `save.EntityRecord.SkillTraining` persists it.

- [x] Add failing start-state, snapshot isolation, restore, and corrupt-save tests.
- [x] Register and initialize the component for the player, bump the Go schema once, and deep-copy queue/settings slices.
- [x] Replace exact starting-skill equality validation with point/level and starting-minimum checks; validate the training XP conservation rule and ownership.
- [x] Run focused ECS/game/save tests.

### Task 3: Ordered XP spending

**Files:** `internal/game/skill_training.go`, `internal/game/death.go`, `internal/game/scenario.go`, `internal/game/turn.go`, `internal/game/experience_test.go`, `internal/game/skill_training_test.go`.

**Interfaces:** `skillTrainingSystem.Update` reads Akara player Skills/Training, current `TurnContext` practice, and the named RNG stream. Death credits ten skill XP per earned XP. The system runs between death and advancement.

- [x] Add tests for a kill's skill gain and ordering before XL/HP recalculation, no-time actions, disabled training, cost-boundary crossing, level-27 stop, and saved RNG continuation.
- [x] Implement source queue seeding, automatic/manual weights, bounded point spending, source cost-level changes, and level messages.
- [x] Reuse one path for live and restored play; run focused tests.

### Task 4: Practice and terminal control

**Files:** `internal/game/combat.go`, `internal/game/skill_practice.go`, `internal/terminal/modals.go`, `internal/terminal/app.go`, `internal/terminal/play_input.go`, focused tests.

**Interfaces:** Current melee, incoming attack, armour, and shield events append practice to `TurnContext`; `Game.SetSkillTraining` changes one skill's setting or mode without spending aut. `View` exposes copied training state.

- [x] Add source-event practice tests and no-time skills-menu tests.
- [x] Wire current combat events, `/` auto/manual, `|` toggle/focus action, and skill-letter selection; show actual training state.
- [x] Keep unrelated target/view controls visibly unavailable; run focused tests.

### Task 5: Integration and review

**Files:** `docs/port-inventory.md`, `docs/ecs-architecture-roadmap.md`, this plan.

- [x] Update inventory and ownership notes with exact implemented limits.
- [x] Run `go test ./...`, `go vet ./...`, `go build ./...`, `sh scripts/check-go-style.sh`, and `git diff --check` once after the category is integrated.
- [x] Obtain read-only code review, fix Important findings, commit one category, and fast-forward local Go `main` while preserving the user's untracked save.
