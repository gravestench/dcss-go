# Species Experience Threshold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing player progression threshold path use the selected species' XP aptitude while keeping skill-cost thresholds species-independent.

**Architecture:** Pure `character` functions take an explicit aptitude. The Akara player component provides the species ID; the catalog provides its immutable aptitude. Advancement, view projection, and save validation use the same functions.

**Tech Stack:** Go, Akara ECS, committed DCSS species catalog.

**Spec:** `docs/superpowers/specs/2026-10-14-species-experience-threshold-design.md`

## Global Constraints

- Use the pinned C++ source at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Keep handwritten Go at or below 120 columns, prefer 80, and separate distinct steps.
- Do not read C++ source during normal Go builds or play.
- Commit this contiguous category once, then fast-forward local Go `main`.

## Review Focus

- Float32 factor and multiplication must match the C++ truncation near thresholds.
- XL1 and XL27 need special handling, including negative or excessive XP.
- Pending manual stat choices may hold the applied level below earned level.
- Skill training's cost level must remain based on aptitude `1` for all species.
- Corrupt or absent player species must not silently fall back to Human.

---

### Task 1: Pure source threshold rule

**Files:** `internal/character/advancement.go`, `internal/character/advancement_test.go`, `internal/character/experience_test.go`

**Interfaces:** `ExperienceNeeded(level, xpApt int) (int, error)`, `LevelForExperience(totalXP, xpApt int) (int, error)`, `LevelProgress(totalXP, level, xpApt int) (int, error)`.

- [ ] Add failing Human table and non-Human C++ oracle tests, boundary tests, and invalid-input tests.
- [ ] Implement the historical curve and `float32` aptitude factor, then run focused character tests.
- [ ] Update existing character tests to the new signatures; remove the Human-specific threshold functions.

### Task 2: Integrate the player's aptitude

**Files:** `internal/game/advancement.go`, `internal/game/view.go`, `internal/game/save_player.go`, `internal/game/skill_training_batch.go`, `internal/character/skill_training.go`, relevant tests.

**Interfaces:** The advancement system loads the player component's species through `content.Catalog`; the view and validator use that same species aptitude. Skill-cost callers pass the fixed aptitude `1`.

- [ ] Add failing tests for source aptitude selection, view projection, and fixed skill-cost thresholds.
- [ ] Replace Human threshold calls throughout production code and keep Human/Fighter runtime behavior identical.
- [ ] Run focused game tests and validate save/restore continuation.

### Task 3: Boundary verification and integration

**Files:** `docs/port-inventory.md`, `docs/ecs-architecture-roadmap.md`

- [ ] Update inventory and ownership status without claiming other species playable.
- [ ] Run `go test ./...`, `go vet ./...`, `go build ./...`, `sh scripts/check-go-style.sh`, and `git diff --check`.
- [ ] Obtain read-only review, fix Important/Critical findings, and commit one category.
- [ ] Fast-forward local Go `main`, leaving the untracked `dcrawl-save.json` untouched.
