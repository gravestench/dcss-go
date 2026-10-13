# DCSS Console Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Go port's launch, Human/Fighter creation, play HUD, menus, prompts, and keys match the pinned DCSS console for implemented gameplay, with an expanding full-terminal dungeon viewport and explicit stubs for unported actions.

**Architecture:** A single Bubble Tea `AppModel` owns screen state and routes keys. A source-traced presentation catalog supplies menu data; a cell canvas and geometry calculator render each screen from read-only game views. The existing `StartModel`, `Model`, and `Render` are replaced directly, without a compatibility layer.

**Tech Stack:** Go 1.25, Akara ECS, Bubble Tea v2, Lip Gloss v2, existing JSON content and save packages.

**Spec:** `docs/superpowers/specs/2026-10-13-dcss-console-parity-design.md`

## Global Constraints

- Source of truth: `/Users/dylanknuth/src/crawl/crawl-ref/source` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, tag major 34; the checked-in C++ binary is a visual cross-check only.
- The only playable start remains Human/Fighter on the fixed two-floor Dungeon. Unsupported source-visible options explain unavailability and spend zero aut.
- Terminal minimum: 79×24. At that size the dungeon is 33×17, gutter 4 columns, HUD 42×13, nearby list 42×4, and messages 79×7. At 120×40 the corresponding regions are dungeon 74×33, gutter 4, HUD 42×13, nearby list 42×20, messages 120×7.
- Above the minimum, expand the dungeon viewport to `width-46` by `height-7`; the HUD remains 42 columns and messages remain at the bottom. A smaller terminal preserves state and shows a resize warning.
- Keep the Go save format at version 4; the new player name is optional in old snapshots, displayed as `Adventurer` when absent. New names obey source allowed characters and a 30-display-column limit.
- Every source-derived menu grouping and description is in a committed generated artifact. Importers run only for intentional refreshes; normal builds, tests, and gameplay do not read the C++ checkout.
- Use source `cmd-keys.h` bindings. `q` quaffs, `L` runs right, `m` opens skills, `S` confirms save and exit, Ctrl-S saves and exits immediately, and Ctrl-Q confirms abandonment. Unported actions remain free and explain themselves.
- Run focused tests after each contiguous category; run `go test ./... -count=1`, `go vet ./...`, and a PTY playthrough after integration. Preserve the untracked `dcrawl-save.json`.

## Review Focus

1. Malformed presentation data with a missing description, duplicate menu ID, or unknown catalog ID must fail catalog loading with context; Task 1 tests these cases.
2. A wide Unicode player name crossing 30 display columns must be rejected without corrupting the UI or save; Task 2 tests it.
3. Styled lines at 79×24 and 120×40 must occupy exactly the logical screen dimensions even with ANSI color and wide runes; Task 3 tests both.
4. Resizing below minimum while a modal is open must preserve focus, run, and aut when the screen recovers; Task 7 tests it.
5. Failed save writes and corrupt startup loads must leave the live run or startup state intact and must not quit; Tasks 5 and 6 test both.

## File map

- `internal/content/presentation.go`, `default.go`, `catalog.go`, and `generated/presentation.json`: immutable, source-traced menu groups and descriptions, loaded with the existing catalog.
- `internal/content/presentationimport/` and `cmd/importpresentation/main.go`: intentional pinned-source refresh tool for menu groups and English description records.
- `internal/character/name.go`, `internal/ecs/components.go`, `internal/game/{scenario,save,view}.go`: validated player name owned by the ECS player and carried through views and version-4 saves.
- `internal/terminal/{canvas,layout,palette}.go`: fixed-cell drawing, 16-color styles, and full-terminal geometry.
- `internal/terminal/{play_render,app,pregame,play_input,modals,keys}.go`: source-like play drawing, one screen controller, creation flow, source key routing, and modal pages. Replace the existing `model.go`, `render.go`, and `start.go` rather than retaining old flows.
- `cmd/dcrawl/main.go`, `docs/port-inventory.md`: launch the new controller and document the shipped boundary.

---

### Task 1: Commit source-traced presentation content

**Files:** Create `internal/content/presentation.go`, `internal/content/presentation_test.go`, `internal/content/presentationimport/import.go`, `internal/content/presentationimport/import_test.go`, `cmd/importpresentation/main.go`, `internal/content/generated/presentation.json`; modify `internal/content/default.go`, `internal/content/catalog.go`, relevant default/fixture tests.

**Interfaces:** Produces `type PresentationArtifact` with schema/revision/source hashes, ordered `SpeciesGroups` and `JobGroups` of `{Label string; IDs []string}`, and `SpeciesDescriptions`/`JobDescriptions` keyed by ID. `func (c Catalog) Presentation() PresentationArtifact` returns defensive copies. `func presentationimport.Generate(sourceDir string) (content.PresentationArtifact, error)` and `Write(sourceDir, out string, check bool) error` mirror existing importers.

- [ ] **Step 1: Write failing tests** for 27 source-visible species in three groups, 25 backgrounds in five groups, Human/Fighter descriptions, stable menu order, defensive copies, and rejection of missing/duplicate/unknown records. Assert the committed artifact's revision and hashes match the pinned files.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/content ./internal/content/presentationimport -count=1`; expect missing types/functions or failing assertions.
- [ ] **Step 3: Implement** parsing `species-groups.h`, the `jobs_order` block in `newgame.cc`, and `%%%%` records in `dat/descript/{species,backgrounds}.txt`. Resolve IDs against existing catalog definitions, hash every source file, sort provenance, embed the generated JSON in `LoadDefault`, validate the same source revision/tag, and return deep copies. Add the importer CLI and generate the artifact once from the pinned source.
- [ ] **Step 4: Run** the focused tests and `go run ./cmd/importpresentation -source /Users/dylanknuth/src/crawl/crawl-ref/source -out internal/content/generated/presentation.json -check`; expect pass and no artifact diff.
- [ ] **Step 5: Commit** the importer, generated artifact, catalog integration, and tests as one content category.

### Task 2: Persist source-valid player names

**Files:** Create `internal/character/name.go`, `internal/character/name_test.go`, `internal/game/name_save_test.go`; modify `internal/ecs/components.go`, `internal/game/{scenario,save,view}.go`, existing `NewScenario` callers/tests, and `go.mod`/`go.sum` if `go-runewidth` becomes a direct dependency.

**Interfaces:** Produces `func character.ValidateName(name string) error`, `func game.NewScenario(seed uint64, catalog content.Catalog, weaponID, name string) (*Game, error)`, and `game.View.PlayerName string`, `PlayerX int`, `PlayerY int`, `PlayerDead bool`. `ecs.PlayerControlled.Name` is optional only when restoring an old version-4 snapshot; the display fallback is `Adventurer`.

- [ ] **Step 1: Write failing tests**: a valid name survives scenario, view, snapshot, and restore; old version-4 JSON without `Name` restores with `Adventurer`; invalid punctuation, blank new-run names, and a 31-column/wide-Unicode name fail with context while 30 display columns pass.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/character ./internal/game ./internal/save -count=1`; expect failures before name plumbing exists.
- [ ] **Step 3: Implement** source name rules from `ng-input.cc`, using terminal display width; change the `NewScenario` signature and all internal callers in one pass. Store name on the player component, validate nonempty names on new runs and nonempty saved names on restore, expose the view fields, and keep snapshot version 4.
- [ ] **Step 4: Run** the focused packages; expect all name and existing scenario/save tests to pass.
- [ ] **Step 5: Commit** the name and save category.

### Task 3: Draw a bounded 16-color canvas and full-terminal layout

**Files:** Create `internal/terminal/canvas.go`, `canvas_test.go`, `layout.go`, `layout_test.go`, `palette.go`.

**Interfaces:** Produces `type Region struct{ X, Y, W, H int }`, `type Layout struct{ Dungeon, Gutter, HUD, Monsters, Messages Region }`, `func ComputeLayout(width, height int) (Layout, bool)`, `func NewCanvas(width, height int) *Canvas`, `func (c *Canvas) Put(x, y int, glyph rune, fg, bg Color)`, `Write(x, y int, text string, fg, bg Color)`, `PlainRows() []string`, and `Styled() string`. `Color` names the source's 16 console colors.

- [ ] **Step 1: Write failing tests** for exact 79×24 and 120×40 regions, 78×23 rejection, offscreen writes, Unicode cell width, and `lipgloss.Width` equal to the requested width on every styled row.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/terminal -run 'TestCanvas|TestLayout' -count=1`; expect failures.
- [ ] **Step 3: Implement** the row-major cell grid, clipped writing, continuation cells for wide runes, source palette, and deterministic layout; group same-style adjacent cells when rendering through Lip Gloss. Full rows are rendered even when their visible content is blank.
- [ ] **Step 4: Run** the canvas/layout focused tests; expect pass.
- [ ] **Step 5: Commit** canvas and geometry as one category.

### Task 4: Render the source-shaped play screen from a read-only view

**Files:** Create `internal/terminal/play_render.go`, `play_render_test.go`; modify `internal/game/view.go` and its tests. Keep the existing renderer until Task 5 switches the application to `DrawPlay`.

**Interfaces:** Extends `game.EntityView` with `KindID`, `Name`, and actor/item role; extends `game.ItemView` with `Class`. Produces `func DrawPlay(canvas *Canvas, layout Layout, view game.View, notice string)`; callers supply the read-only view and a UI-only notice.

- [ ] **Step 1: Write failing tests** asserting the 79×24 HUD title and label positions, HP/MP bars, equipped rapier, Dungeon depth, message rows, player-centered glyph, item/rat labels, and honest `--` placeholders for unported combat/XP fields. At 120×40 assert the extra viewport is used and the HUD sits beside it.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/game ./internal/terminal -run 'TestViewPresentation|TestDrawPlay' -count=1`; expect failures.
- [ ] **Step 3: Implement** catalog-derived entity/item presentation fields and `DrawPlay` with source `viewgeom.cc`/`output.cc` coordinates. Keep render deterministic and free of `game.Step` or ECS access. The old renderer remains in use by the old model until Task 5 replaces that model; do not add a bridge between renderers.
- [ ] **Step 4: Run** the focused game/terminal tests; expect pass.
- [ ] **Step 5: Commit** play presentation as one category.

### Task 5: Replace pregame flow with source menus

**Files:** Create `internal/terminal/app.go`, `pregame.go`, `pregame_test.go`; modify `cmd/dcrawl/main.go`; remove the superseded `internal/terminal/{start,model,render}.go` and their tests once `AppModel` owns all routes.

**Interfaces:** Produces `type ScreenID` and `func NewAppModel(catalog content.Catalog, seed uint64, savePath string) (*AppModel, error)`. `AppModel` implements `tea.Model`, has one `game *game.Game`, owns current screen/focus/name/species/job/weapon/notice, and renders through `Canvas`. Task 6 extends its play key handler; Task 7 supplies modal drawing.

- [ ] **Step 1: Write failing tests** for startup banner/modes/name input, saved-run entry, species and background group letters/descriptions, species-first and background-first routes, Human/Fighter `a`–`f` weapons, post-weapon name prompt, six starts at aut zero, and unavailable selections staying in menu. Test a corrupt startup load leaves `game == nil` and a resize during a menu preserves focus/state/aut.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/terminal -run 'TestPregame|TestStartupLoad|TestMenuResize' -count=1`; expect failures.
- [ ] **Step 3: Implement** the single state controller and source menu layout/key flow. Render missing-size warning through `Canvas`. Load the configured Go save only from startup; create the scenario only after supported choices and a valid name. Draw play through Task 4's `DrawPlay`; until Task 6, play keys other than menu navigation are inert. Delete the old numeric weapon menu, Go-only startup load key, split models, and renderer with their superseded tests. Update `cmd/dcrawl` to launch `AppModel`.
- [ ] **Step 4: Run** the focused terminal tests; expect pass, including restoration of an old version-4 save.
- [ ] **Step 5: Commit** startup and character creation as one flow category.

### Task 6: Route play commands, confirmations, save exit, and death

**Files:** Create `internal/terminal/play_input.go`, `play_input_test.go`; modify `internal/terminal/keys.go`, `app.go`, and their tests. Task 5 leaves the play input handler inactive until this task supplies it.

**Interfaces:** Produces `func (m *AppModel) handlePlayKey(key string) tea.Cmd` and `handleConfirmKey(key string) tea.Cmd`. Supported movement/pickup/wait/stairs call `game.Step` once; UI and stub keys do not call it. `S` and Ctrl-S exit only after a successful atomic `save.Write`; Ctrl-Q confirmation and player death enter terminal states.

- [ ] **Step 1: Write failing tests** for eight-way movement and `s` wait, `g`/`,` pickup, `<`/`>` stairs, `q` quaff notice, `L` run-right notice, `m` skills, `S` confirmation/cancel/success, Ctrl-S immediate save, Ctrl-Q confirmation/cancel, failed save write preserving the live run, and a player death transition. Assert aut changes only for supported game actions.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/terminal -run 'TestPlayKeys|TestSaveExit|TestQuit|TestDeath' -count=1`; expect failures.
- [ ] **Step 3: Implement** source key mapping from `cmd-keys.h`, confirmation state and prompts from `main.cc`, free unavailable notices, and death flow. Remove `q` quit, `L` load, and `c` skills behavior. Keep failed saves on the play screen with an error.
- [ ] **Step 4: Run** focused terminal tests; expect pass.
- [ ] **Step 5: Commit** play interaction as one category.

### Task 7: Add source-shaped inventory, skills, and help pages

**Files:** Create `internal/terminal/modals.go`, `modals_test.go`; modify `internal/terminal/app.go`.

**Interfaces:** Produces `func DrawInventory(*Canvas, game.View)`, `DrawSkills(*Canvas, game.View, content.Catalog)`, and `DrawHelp(*Canvas)`. `AppModel` opens them from `i`, `m`, and `?`, closes with `Esc`, and keeps turn time unchanged; unported controls show a modal notice.

- [ ] **Step 1: Write failing tests** for source inventory categories/letter order/equipped labels; Human/Fighter skill levels and aptitudes in source columns; help showing source keys and unavailable domains; modal controls and `Esc` spending zero aut. Test a 78×23 resize while inventory is open, then recovery to 79×24 with the same modal focus, game, and aut.
- [ ] **Step 2: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./internal/terminal -run 'TestInventoryPage|TestSkillsPage|TestHelpPage|TestModal' -count=1`; expect failures.
- [ ] **Step 3: Implement** full-screen pages on the shared canvas using the read-only view and committed catalog. Keep training controls as visible unavailable stubs and remove the old rounded inventory/character boxes.
- [ ] **Step 4: Run** focused terminal tests; expect pass.
- [ ] **Step 5: Commit** informational pages as one category.

### Task 8: Integrate, inspect real terminal behavior, and record scope

**Files:** Modify `docs/port-inventory.md` and any focused implementation files exposed by integration failures; add an integration test only for a behavioral risk the focused tests miss.

**Interfaces:** Consumes Tasks 1–7; produces a launchable Go ASCII client with the approved UI boundary.

- [ ] **Step 1: Run** `GOCACHE=/tmp/dcrawl-go-cache go test ./... -count=1`, `go vet ./...`, importer `-check`, and `git diff --check`; fix concrete failures in the owning file/category.
- [ ] **Step 2: Build** `go build ./cmd/dcrawl` in a clean Go-only copy without the C++ checkout, then launch in a PTY at 79×24 and 120×40. Inspect startup → Human → Fighter → weapon → name → play → inventory/skills → save/exit → startup load; inspect a smaller-than-minimum resize and recovery.
- [ ] **Step 3: Compare** the 79×24 character/menu/HUD cell snapshots with pinned-source coordinates and the captured console reference; document every remaining difference caused by an explicitly unported rule rather than silently claiming complete DCSS gameplay.
- [ ] **Step 4: Update** `docs/port-inventory.md` with the UI status, the committed presentation-content policy, source keys, current runnable flow, and the remaining gameplay domains. Verify the user's `dcrawl-save.json` is untouched.
- [ ] **Step 5: Commit** integration fixes and documentation for this coherent slice, then prepare one fresh whole-branch review before local integration into Go `main`.
