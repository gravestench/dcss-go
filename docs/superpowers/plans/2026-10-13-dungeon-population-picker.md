# Dungeon Population Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a source-shaped deterministic weighted picker over the committed Dungeon population.

**Architecture:** `content.Catalog` constructs an immutable pool from its validated rows; the caller owns any RNG and passes a bounded roll. The pool preserves row order and duplicates.

**Tech Stack:** Go, standard library, committed content catalog.

**Spec:** `docs/superpowers/specs/2026-10-13-dungeon-population-picker-design.md`

## Global Constraints

- Normal builds and play use only committed Go content.
- Keep the existing fixed scenario and save format unchanged.
- Commit the category once after broad verification and whole-branch review.

## Review Focus

- Depth outside all rows: return an empty pool and empty pick without RNG.
- A vetoed duplicate ID: exclude every matching row.
- Boundary roll equal to total: reject it.
- Row order: map a boundary roll to the next source row, not a grouped ID.
- Catalog isolation: mutating returned data cannot alter future pools.

---

### Task 1: Pure weighted Dungeon pool

**Files:**
- Create: `internal/content/population_picker.go`
- Test: `internal/content/population_picker_test.go`
- Modify: `docs/port-inventory.md`

**Interfaces:**
- `func (c Catalog) DungeonMonsterPool(depth int, veto func(string) bool) DungeonMonsterPool`
- `func (p DungeonMonsterPool) TotalWeight() int`
- `func (p DungeonMonsterPool) Pick(roll int) (string, error)`

- [ ] Write failing tests for D:1 source ordering, depth curves, duplicate rows, veto, empty pool, and roll bounds.
- [ ] Run the focused test to confirm the missing API fails.
- [ ] Implement the immutable pool with one weighted entry per qualifying source row.
- [ ] Run focused tests, then full `go test ./...`, `go vet ./...`, `go build ./...`, and formatting checks.
- [ ] Obtain whole-branch read-only review, fix findings, commit, and fast-forward local Go `main`.
