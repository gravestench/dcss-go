# Lua-Authoritative Runtime Content Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Remove the parallel Go content catalog from normal game startup, menus, and saves so effective Lua files are the only runtime definitions.

**Architecture:** Generic Lua registration retains immutable definition tables. Lua validates DCSS fields and assembles the character menu; Go decodes only screen data. The game and save constructors take a ruleset and IDs directly. Import JSON stays solely in developer tooling.

**Tech Stack:** Go, Akara, gopher-lua, embedded `.lua` modules, Bubble Tea.

**Spec:** `docs/superpowers/specs/2026-10-14-lua-authoritative-runtime-content-design.md`

## Global constraints

- Do not add compatibility overloads or a second Go catalog path.
- Keep Lua source only in `.lua` files; no inline Lua in Go tests.
- Preserve effective-file hashing, deterministic actions, and save continuation.
- Keep handwritten Go and Lua under 120 characters and multi-field literals expanded.
- Let the branch be temporarily broken and commit the integrated category once.

## Review focus

- A same-path species or job override changes both the menu and gameplay.
- A mod-added selectable species appears in the menu without Go code changes.
- Unknown extra fields survive registration and remain accessible to Lua.
- Duplicate IDs, missing required fields, and invalid recommendations fail with module context.
- A save with different effective Lua bytes still requires explicit mismatch permission.

### Task 1: Replace typed Go registration with Lua-owned definitions

**Files:** `internal/script/runtime.go`, `internal/script/definitions.go`, `internal/script/definition_schema.go`, `internal/modfs/builtin/content/validation.lua`, `internal/modfs/builtin/init.lua`.

- [x] Add Lua fixture tests for mod fields, duplicate IDs, invalid shape, and cross-references.
- [x] Store immutable copied tables in the generic registry; remove typed Go species/job mirrors.
- [x] Validate DCSS required fields and references during Lua boot.
- [x] Remove Go definition projection and schema code made obsolete by Lua validation.

### Task 2: Serve the complete pregame catalog from Lua

**Files:** `internal/modfs/builtin/policy/presentation/pregame.lua`, `internal/script/character_catalog.go`, `internal/terminal/app.go`, `internal/terminal/pregame.go`, `internal/terminal/pregame_render.go`.

- [x] Add an integration test where an added selectable species reaches the visible menu.
- [x] Return ordered menu groups, names, descriptions, restrictions, and support from Lua policy.
- [x] Decode only the screen model in Go; remove `content.Catalog` from terminal state.
- [x] Delete the Go `WithCharacterDefinitions` runtime projection path.

### Task 3: Remove the Go catalog from new game and restore

**Files:** `internal/game/scenario.go`, `internal/game/game.go`, `internal/game/save.go`, `internal/save/snapshot.go`, `cmd/dcrawl/main.go`, game and terminal tests.

- [x] Change constructors to accept IDs and effective rules without a Go catalog.
- [x] Remove startup JSON loading and the `Game.catalog` field.
- [x] Drop `SourceRevision` from save headers, bump the save version, and preserve ruleset manifest checks.
- [x] Update all game and terminal callers directly; do not retain compatibility wrappers.
- [x] Test new game, save/restore, malformed save, ruleset mismatch, and RNG continuation.

### Task 4: Integrated category gate

**Files:** `docs/port-inventory.md` and changed source.

- [x] Verify no normal launch path reads `internal/content/generated/*.json`.
- [x] Run `go test ./... -count=1`, `go vet ./...`, `go build ./...`, style, catalog check, and diff check.
- [x] Run whole-branch review, fix findings, commit this category, and fast-forward local `main`.
