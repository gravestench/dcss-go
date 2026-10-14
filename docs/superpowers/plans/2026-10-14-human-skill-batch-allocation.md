# Human Skill Batch Allocation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Spend Human/Fighter skill XP through DCSS's batch allocation and
weighted remainder phases.

**Architecture:** Keep player skill state in Akara. A focused allocation
helper converts source-shaped training weights into batch shares; the
ordered skill system owns mutations, level messages, and the saved RNG.

**Tech Stack:** Go, Akara ECS, existing `skill` RNG stream.

**Spec:** `docs/superpowers/specs/2026-10-14-human-skill-batch-allocation-design.md`

## Global Constraints

- Pinned source revision: `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Human/Fighter only; no manuals, targets, cross-training, magic, or new save fields.
- Keep `AGENTS.md` spacing and 120-character maximum line length.
- One gameplay category commit after integrated verification.

## Review Focus

- A small weighted share must skip the whole first phase and remain eligible in the random phase.
- A skill reaching level 27 must not consume more XP or trap the spending loop.
- Cost increases during a batch must affect later chunks without overdrawing XP.
- Disabled training must retain XP, including after save/restore.
- The same saved `skill` RNG state must produce the same continuation.

---

### Task 1: Source-shaped batch weights

**Files:**
- Modify: `internal/game/skill_training_weights.go`
- Test: `internal/game/skill_training_test.go`

**Interfaces:** `scaledTrainingWeights(skills []character.Skill,
training *ecs.SkillTraining) []int` returns the source 100-point array in
current stable skill order.

- [ ] Add failing tests for manual truncation, automatic exact total,
  focused floor, and disabled/maxed skills.
- [ ] Run focused tests and confirm those cases fail.
- [ ] Implement scaling from existing `trainingWeights`; preserve stable
  source order when assigning automatic remainders.
- [ ] Run focused tests until the weight contract passes.

### Task 2: Batch spending and remainder selection

**Files:**
- Modify: `internal/game/skill_training_system.go`
- Create: `internal/game/skill_training_batch.go`
- Test: `internal/game/skill_training_test.go`

**Interfaces:** `(*skillTrainingSystem).spend` remains the system entry.
The batch helper calculates the current cost-level limit, shuffles first
phase order using `skill`, and spends source-sized chunks through one
mutation function that updates points, XP pools, cost level, and events.

- [ ] Add failing tests for equal multi-skill shares, too-small shares,
  a 2650-XP chunk, cost-level crossing, maxed skills, and no-progress exit.
- [ ] Confirm the new tests fail under per-point weighted spending.
- [ ] Replace the per-point loop with source batch and remainder phases.
- [ ] Run focused tests and refine source arithmetic and termination.

### Task 3: Integrated continuation and documentation

**Files:**
- Modify: `internal/game/skill_training_test.go`
- Modify: `docs/port-inventory.md`
- Modify: `docs/ecs-architecture-roadmap.md`

**Interfaces:** Save schema and `SkillTraining` fields remain unchanged.

- [ ] Add a save/restore test with a pending multi-skill XP batch and
  compare later snapshots, including RNG state.
- [ ] Update the inventory and roadmap to describe batch allocation and
  the remaining non-Human training gaps.
- [ ] Run `go test ./...`, `go vet ./...`, `go build ./...`,
  `sh scripts/check-go-style.sh`, and `git diff --check` with writable Go cache.
- [ ] Request read-only code review, resolve important findings, and commit
  one category before fast-forwarding local `main`.
