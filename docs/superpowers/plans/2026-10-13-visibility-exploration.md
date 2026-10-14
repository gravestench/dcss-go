# Visibility and Exploration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Go Dungeon reveal source-faithful normal sight and preserve remembered terrain across turns, floors, and saves.

**Architecture:** A pure `visibility` package computes a dense mask from terrain. `game.Level` owns remembered terrain, `game.Game` owns only current derived sight, `game.View` exposes player knowledge, and the terminal renders that view. Akara continues to own dynamic entities.

**Tech Stack:** Go, Akara ECS, Bubble Tea, Lip Gloss, JSON save format.

**Spec:** `docs/superpowers/specs/2026-10-13-visibility-exploration-design.md`

## Global Constraints

- Pinned DCSS source: `/Users/dylanknuth/src/crawl/crawl-ref/source` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f` (tag-34).
- Normal Human sight radius is 7 Chebyshev cells; maximum supported radius is 8.
- No Go build, test, save, or runtime may require the C++ checkout. Commit a normalized copy of the 15 `suite-los.des` maps with SHA-256 provenance.
- Preserve the user's untracked `dcrawl-save.json` and the paused C++ checkout. Version-4 Go saves reject cleanly; version 5 stores remembered terrain.
- One commit per contiguous category. The pure sight package is one category; game state, saves, scenario, and rendering form one integrated category committed only after the full build and tests pass.

## Review Focus

- Empty, ragged, or unknown-glyph terrain must fail before visibility indexing; Task 1 tests this.
- Out-of-bounds or opaque player origins and radius outside 1–8 must fail clearly; Task 1 tests this.
- A blocking wall at the edge is visible while the cell behind it is hidden; Task 1 goldens and Task 2 view tests cover this.
- A view copied or held across movement must not alias live map knowledge; Task 2 tests this.
- A truncated, oversized, or invalid remembered row must fail restore without replacing the live game; Task 3 tests this.

---

### Task 1: Source sight geometry

**Files:** Create `internal/visibility/visibility.go`, `internal/visibility/visibility_test.go`, and `internal/visibility/testdata/dcss-los-tag34.json`.

**Interfaces:** Produce `func Compute(rows []string, originX, originY, radius int) ([]bool, error)`, with a row-major `y*width+x` result. `#` is opaque; `.`, `<`, `>` are clear. The blocking cell is visible; later cells require a surviving source-style ray. No package globals with mutable state.

- [ ] First normalize the 15 pinned source maps into committed JSON testdata; then write `TestSourceGoldenSightMaps`: decode all 15 maps (`@` player, `x/c` wall, `./w` floor; `@`, `x`, `.` visible), assert every 10×10 cell, and repeat under reflections and a translated origin. Write `TestVisibilityInputValidation` for empty/ragged/unknown rows, blocked/out-of-bounds origin, and radius 0 or 9. Write a range-edge assertion for `(±7,±7)` visible on open terrain and `(±8,0)` hidden at radius 7.
- [ ] Run `go test ./internal/visibility -count=1`; confirm red before implementation.
- [ ] Port the opaque-terrain ray-footprint/minimal-cellray semantics from `crawl-ref/source/los.cc` into the pure package, preserving the source's corner-gap behavior. Keep precomputed geometry immutable and local to the package or initialized without mutable cross-run state. Keep the testdata source revision and hash validated by the test.
- [ ] Run `go test ./internal/visibility -count=1`; confirm all goldens and invalid-input tests pass. Commit as `feat: port DCSS opaque-terrain sight rules`.

### Task 2: Level knowledge and filtered game view

**Files:** Modify `internal/game/level.go`, `game.go`, `scenario.go`, `commands.go`, and `view.go`; create `internal/game/visibility.go` and `visibility_test.go`; update `items_test.go` view-copy assertion.

**Interfaces:** `Level` stores row-major `remembered []byte` (zero means unknown) and exposes `KnownRows() []string`, `LoadKnownRows([]string) error`, and `Remember([]bool) error`. `Game.refreshVisibility() error` recomputes `visible []bool` and `visibleLevelID`. `View` replaces `Terrain` with `Width`, `Height`, and row-major `Cells []CellView`; `CellView{Glyph rune, State CellState}` uses `Unknown`, `Explored`, `Visible`.

- [ ] Write `TestNewRunSightAndOcclusion`, `TestMovementRemembersTerrainButHidesEntities`, `TestFailedMoveDoesNotChangeKnowledge`, `TestViewIsCopied`, and a boundary-wall assertion. Use a short interior wall in the current fixed map for occlusion; preserve player `(1,1)`, rat `(4,1)`, and potion `(4,2)` until Task 3 expands the floors.
- [ ] Run `go test ./internal/game -run 'TestNewRunSight|TestMovementRemembers|TestFailedMove|TestViewIsCopied' -count=1`; confirm red.
- [ ] Implement remembered terrain and player-sight refresh after scenario creation and after completed player actions, before returning `StepResult.View`; add the interior wall fixture without moving the current actors, item, or stairs. Filter positioned entities by current sight; keep inventory and player data unchanged. `View` must copy all slices and must never expose a live glyph for unknown cells.
- [ ] Run the focused game tests; confirm green before continuing. Keep these edits uncommitted until Task 4 completes the integrated category.

### Task 3: Two-floor travel and save version 5

**Files:** Modify `internal/game/scenario.go`, `movement.go`, `save.go`, `level_test.go`, `save_test.go`, `internal/save/snapshot.go`, and `internal/save/codec_test.go`; add travel/knowledge tests in `internal/game/visibility_test.go`.

**Interfaces:** `save.LevelRecord` gains `Known []string \`json:"known"\``; unknown cells serialize as spaces, known cells as supported terrain glyphs. `save.Version` becomes 5. `Level.FindUniqueTerrain(glyph byte) (x, y int, ok bool)` supplies destination stairs in this fixed scenario; duplicate/missing stair terrain is invalid. Restore loads each level's remembered rows and then calls `refreshVisibility()` before returning the replacement game.

- [ ] Write `TestStairTravelPreservesPerFloorKnowledge`, `TestKnowledgeSaveRoundTrip`, `TestRestoreRejectsInvalidKnowledge`, and a codec test rejecting version 4. Cover missing/short/long rows, unsupported glyphs, and a failed restore leaving the live snapshot unchanged. Update the existing version assertion from 4 to 5.
- [ ] Run `go test ./internal/game ./internal/save -run 'TestStairTravel|TestKnowledge|TestRestoreRejectsInvalidKnowledge|TestScenarioAttributesAndView' -count=1`; confirm red.
- [ ] Expand both fixed maps to at least 17×9 with interior occlusion and reachable stairs; replace hard-coded destination coordinates with unique stair lookup. Save and validate remembered rows; recompute current sight on restore. Preserve actor/item interactions and deterministic save continuation.
- [ ] Run `go test ./internal/game ./internal/save -count=1`; confirm green before continuing. Keep these edits uncommitted until Task 4 completes the integrated category.

### Task 4: Terminal fog and integrated acceptance

**Files:** Modify `internal/terminal/play_render.go` and `play_render_test.go`; update `docs/port-inventory.md`.

**Interfaces:** `drawDungeon` consumes `View.Cells`; unknown draws blank, explored draws the remembered glyph dimly, visible draws the normal glyph colors. The nearby-monster pane receives already-filtered `View.Entities`.

- [ ] Write `TestDrawPlayFogAndRememberedTerrain` at 79×24 and 120×40, including a monster hidden behind a wall, and update centered-map expectations for the expanded scenario.
- [ ] Run `go test ./internal/terminal -run 'TestDrawPlay' -count=1`; confirm red.
- [ ] Render the three cell states, preserve the existing HUD/menu layout, and update `docs/port-inventory.md` to distinguish implemented sight behavior from remaining map-knowledge gaps.
- [ ] Run `go test ./...`, `go vet ./...`, and `go build ./...` with `GOCACHE=/private/tmp/dcrawl-go-build-cache`; run a PTY start/move/save/load flow using a temporary save path, inspect both terminal sizes, and verify `dcrawl-save.json` remains untouched. Commit Tasks 2–4 together as `feat: add visible and remembered dungeon map`.
