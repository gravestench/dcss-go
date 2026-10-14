# Early Dungeon Plain-Bite Monsters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add source-backed giant cockroach and worm actors to live D:1–2 play, including regeneration, corpse decay, XP, and saved continuation.

**Architecture:** Extend the existing Akara ordinary-animal factory and combat path rather than adding parallel monster execution. Keep source definitions in the committed catalog and mutable health in ECS. Add one ordered regeneration system and pass catalog skeleton eligibility to the corpse-aging rule.

**Tech Stack:** Go, Akara `v0.1.4`, committed DCSS content, Go tests.

**Spec:** `docs/superpowers/specs/2026-10-14-early-dungeon-plain-bite-design.md`

## Global Constraints

- Pinned DCSS source revision: `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- No C++ source reads during a normal Go build or game launch.
- Handwritten Go lines at most 120 columns; prefer 80, with expanded structs and control-flow spacing.
- One coherent feature-category commit after verification.

## Review Focus

- A worm's fast regeneration happens before its action and consumes no random draw.
- Existing injured HD-1 animals draw natural regeneration only on their own turns.
- A cockroach or worm body disappears without a skeleton appearance draw.
- Restore rejects impossible HP and skeleton states for the newly supported kinds.
- Population selection remains weighted by the committed D:1–2 table.

---

### Task 1: Source-backed actor and XP eligibility

**Files:** `internal/character/experience.go`, `internal/character/experience_test.go`, `internal/game/ordinary_animal.go`, `internal/game/populate.go`, related game tests.

**Interfaces:** Extend `OrdinaryBiteProfile` with hit dice, fast regeneration, and skeleton eligibility. Keep `OrdinaryAnimalExperience(content.MonsterDef, int) (int, error)` and `ordinaryMonsterFactory.Spawn` as callers. Preserve the fixture's three actor IDs while admitting cockroach and worm to population scenarios.

- [x] Write tests for cockroach HP 3–7, worm HP 12–24, catalog stats, and source XP (worm at 18 HP grants 5).
- [x] Run focused tests and confirm feature-specific failure.
- [x] Add the two profiles and validate all behavior-affecting source fields before spawn or XP.
- [x] Run focused tests and confirm success.

### Task 2: Regeneration on active and inactive floors

**Files:** `internal/game/monster_regeneration.go`, tests, `internal/game/scenario.go`, `internal/monster/offlevel.go`, tests, `internal/game/monster_catchup.go`.

**Interfaces:** An ordered Akara system processes only the acting monster before AI. `monster.OffLevelRecovery(roller, turns, rate)` accepts source hundredths of HP per turn; rate is 10 for supported HD-1 animals and 100 for the worm.

- [x] Write failing tests for damaged worm pre-action healing without a draw, HD-1 1-in-25 roll, and off-level rates.
- [x] Run focused tests and confirm feature-specific failure.
- [x] Implement the system and rate-aware pure rule; register the system before monster AI.
- [x] Run focused tests and confirm success.

### Task 3: No-skeleton corpse lifecycle and saved continuation

**Files:** `internal/monster/corpse.go`, tests, `internal/game/corpse.go`, `internal/game/save.go`, `internal/game/save_restore_rules.go`, integration tests.

**Interfaces:** `monster.AgeCorpse` receives skeleton eligibility. The corpse-aging system receives immutable catalog access. Save validation rejects a skeleton for a kind with `M_NO_SKELETON`.

- [x] Write failing tests for no-skeleton decay without an appearance draw and a populated cockroach/worm save round trip.
- [x] Run focused tests and confirm feature-specific failure.
- [x] Implement catalog-driven eligibility through corpse aging and restore validation.
- [x] Run focused tests and confirm success.

### Task 4: Integration and documentation

**Files:** `docs/port-inventory.md`, `docs/ecs-architecture-roadmap.md`, relevant gameplay tests.

- [x] Verify both kinds appear in source-weighted D:1–2 pools and remain valid through melee, XP, corpse, and restore flows.
- [x] Update coverage and remaining gaps, especially jackal bands and other unsupported monsters.
- [x] Run `sh scripts/check-go-style.sh`, `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./...`, `go vet ./...`, `go build ./...`, and `git diff --check`.
- [x] Request one fresh whole-branch code review, address important findings, and commit this category.
