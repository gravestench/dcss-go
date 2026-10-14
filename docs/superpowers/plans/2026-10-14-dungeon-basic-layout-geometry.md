# Dungeon `layout_basic` Geometry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate source-shaped D:1–2 `layout_basic` terrain and six stair positions in Go.

**Architecture:** A temporary `internal/levelgen` builder owns a byte grid and consumes a caller-owned deterministic draw function. It returns terrain and stair coordinates without creating ECS entities or changing the live scenario.

**Tech Stack:** Go 1.25 standard library; pinned DCSS tag-34 source for rules.

**Spec:** `docs/superpowers/specs/2026-10-14-dungeon-basic-layout-geometry-design.md`

## Global Constraints

- Do not read the C++ tree at build or runtime.
- Keep dense terrain outside ECS and dynamic entities in Akara.
- Keep handwritten Go lines at or below 120 columns, prefer 80, and pass `scripts/check-go-style.sh`.
- Preserve the existing live scenario and save schema in this geometry category.
- Commit this contiguous geometry category once after verification and review.

## Review Focus

- Invalid depth or nil RNG: return an error before drawing.
- Corridor budget at its rare high value: terminate within the source attempt cap.
- An unsuccessful stair trail: retry the same source-shaped builder up to 16 times, then error.
- A degenerate random source: fail after 16 rejected bounded draws instead of hanging.
- Many seeds: stairs remain distinct, reachable, and inside the rock border.
- Closed doors: appear only on formerly narrow room entrances and count as traversable for connectivity.

---

### Task 1: Grid, random draws, and source trail rules

**Files:**
- Create: `internal/levelgen/basic.go`
- Create: `internal/levelgen/trail.go`
- Create: `internal/levelgen/basic_test.go`

**Interfaces:**
- `func BasicDungeon(depth int, next func() uint64) (Layout, error)`
- `type Layout struct { Rows []string; Stairs [3]StairPair }`
- `type StairPair struct { Up Point; Down Point }`

- [ ] Write tests for invalid inputs, fixed dimensions, deterministic output, and border rock; run them red.
- [ ] Implement a byte-grid builder with source `random2` semantics (`n <= 1` yields zero), unbiased bounded draws, source trail start rectangles, direction bias, run length, intersection rule, and attempt limits.
- [ ] Write a test that inspects the three distinct up/down stair pairs and connected floor; run it red before adding stair placement and orthogonal connections.
- [ ] Implement stair placement and shortest orthogonal connection of the three down-stair starts; run focused tests green.

### Task 2: Source room acceptance and doors

**Files:**
- Modify: `internal/levelgen/basic.go`
- Create: `internal/levelgen/rooms.go`
- Modify: `internal/levelgen/basic_test.go`

**Interfaces:**
- Consume Task 1's builder grid and draw function.
- Return `+` only for source-shaped closed-door locations.

- [ ] Add failing tests for room carving, bounded failure retries, door placement, and invariants across a deterministic seed set.
- [ ] Implement weighted room count, both room passes, perimeter connection checks, rock carving, and door probability from `dgn-layouts.cc:108-124,867-996`.

### Task 3: Record integration boundary

**Files:**
- Modify: `docs/port-inventory.md`
- Modify: `docs/ecs-architecture-roadmap.md`

- [ ] Record that `layout_basic` D:1–2 geometry is available but live play still uses the fixed map.
- [ ] List door state, stair linking, source population count, and save validation as the next integration work; do not claim full level-generation parity.
- [ ] Run focused tests, then full `go test ./...`, `go vet ./...`, `go build ./...`, and `sh scripts/check-go-style.sh` once for the category.
- [ ] Obtain read-only review, fix material findings, and commit the geometry category.
